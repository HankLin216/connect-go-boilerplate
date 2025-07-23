package connect

import (
	"context"
	"crypto/tls"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"connectrpc.com/grpcreflect"
	"github.com/HankLin216/connect-go-boilerplate/pkg/matcher"
	"github.com/HankLin216/connect-go-boilerplate/pkg/middleware"
	"github.com/HankLin216/go-utils/log"
	"go.uber.org/zap"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
)

// ServerOption is Connect server option.
type ServerOption func(o *Server)

// Network with server network.
func Network(network string) ServerOption {
	return func(s *Server) {
		s.network = network
	}
}

// Address with server address.
func Address(addr string) ServerOption {
	return func(s *Server) {
		s.address = addr
	}
}

// Middleware with server middleware.
func Middleware(m ...middleware.Middleware) ServerOption {
	return func(s *Server) {
		s.middleware.Use(m...)
	}
}

// Timeout with server timeout.
func Timeout(timeout time.Duration) ServerOption {
	return func(s *Server) {
		s.timeout = timeout
	}
}

// TLSConfig with TLS config.
func TLSConfig(c *tls.Config) ServerOption {
	return func(s *Server) {
		s.tlsConf = c
	}
}

// EnableReflection enables gRPC reflection.
func EnableReflection(enable bool) ServerOption {
	return func(s *Server) {
		s.enableReflection = enable
	}
}

// Server is a Connect server wrapper.
type Server struct {
	*http.Server

	baseCtx    context.Context
	tlsConf    *tls.Config
	lis        net.Listener
	err        error
	network    string
	address    string
	endpoint   *url.URL
	timeout    time.Duration
	middleware matcher.Matcher

	mux              *http.ServeMux
	handlers         map[string]http.Handler
	reflector        *grpcreflect.Reflector
	enableReflection bool
}

// NewServer creates a Connect server by options.
func NewServer(opts ...ServerOption) *Server {
	srv := &Server{
		baseCtx:          context.Background(),
		network:          "tcp",
		address:          ":0",
		timeout:          30 * time.Second,
		middleware:       matcher.New(),
		mux:              http.NewServeMux(),
		handlers:         make(map[string]http.Handler),
		enableReflection: false,
	}

	for _, o := range opts {
		o(srv)
	}

	// Create HTTP server with Connect support
	srv.Server = &http.Server{
		Handler: srv.createHandler(),
	}

	return srv
}

// createHandler creates the main HTTP handler with middleware support
func (s *Server) createHandler() http.Handler {
	// Wrap with h2c for HTTP/2 without TLS support (Connect-Go requirement)
	handler := h2c.NewHandler(s.mux, &http2.Server{})

	// Wrap with Connect middleware
	return s.wrapWithMiddleware(handler)
}

// wrapWithMiddleware wraps the handler with Connect middleware integration
func (s *Server) wrapWithMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Create transport context
		tr := &Transport{
			operation:   s.getOperationFromPath(r.URL.Path),
			reqHeader:   headerCarrier(r.Header),
			replyHeader: headerCarrier(w.Header()),
		}
		if s.endpoint != nil {
			tr.endpoint = s.endpoint.String()
		}

		// Set transport in context
		ctx := s.baseCtx
		if s.timeout > 0 {
			var cancel context.CancelFunc
			ctx, cancel = context.WithTimeout(ctx, s.timeout)
			defer cancel()
		}

		// Update request with new context
		r = r.WithContext(ctx)

		// Apply middleware if matched
		if middlewares := s.middleware.Match(tr.operation); len(middlewares) > 0 {
			// Convert HTTP handler to middleware handler
			h := func(ctx context.Context, req interface{}) (interface{}, error) {
				next.ServeHTTP(w, r)
				return nil, nil
			}

			// Apply middleware chain
			middlewareHandler := middleware.Chain(middlewares...)(h)
			_, _ = middlewareHandler(ctx, r)
		} else {
			next.ServeHTTP(w, r)
		}
	})
}

// getOperationFromPath extracts the operation name from the URL path
// Connect paths follow the pattern: /package.Service/Method
func (s *Server) getOperationFromPath(path string) string {
	// Connect-Go paths are like: /grpc.examples.echo.v1.EchoService/Echo
	// We want to return: /grpc.examples.echo.v1.EchoService/Echo
	if strings.HasPrefix(path, "/") {
		return path
	}
	return "/" + path
}

// RegisterHandler registers a Connect handler
func (s *Server) RegisterHandler(pattern string, handler http.Handler) {
	s.mux.Handle(pattern, handler)
	s.handlers[pattern] = handler
}

// SetReflectionServices sets the services for gRPC reflection
func (s *Server) SetReflectionServices(services []string) {
	if s.enableReflection {
		s.reflector = grpcreflect.NewStaticReflector(services...)
		reflectPath, reflectHandler := grpcreflect.NewHandlerV1(s.reflector)
		s.mux.Handle(reflectPath, reflectHandler)
		reflectPathAlpha, reflectHandlerAlpha := grpcreflect.NewHandlerV1Alpha(s.reflector)
		s.mux.Handle(reflectPathAlpha, reflectHandlerAlpha)
	}
}

// Use uses a service middleware with selector.
func (s *Server) Use(selector string, m ...middleware.Middleware) {
	s.middleware.Add(selector, m...)
}

// Endpoint returns the server endpoint.
func (s *Server) Endpoint() (*url.URL, error) {
	if err := s.listenAndEndpoint(); err != nil {
		return nil, err
	}
	return s.endpoint, nil
}

// Start starts the Connect server.
func (s *Server) Start(ctx context.Context) error {
	if err := s.listenAndEndpoint(); err != nil {
		return err
	}

	s.baseCtx = ctx
	s.Server.Handler = s.createHandler()

	log.Info("[Connect] server start listening", zap.String("addr", s.lis.Addr().String()))

	if s.tlsConf != nil {
		s.Server.TLSConfig = s.tlsConf
		return s.Server.ServeTLS(s.lis, "", "")
	}

	return s.Server.Serve(s.lis)
}

// Stop stops the Connect server.
func (s *Server) Stop(ctx context.Context) error {
	log.Info("[Connect] server stopping", zap.String("addr", s.lis.Addr().String()))
	return s.Server.Shutdown(ctx)
}

// listenAndEndpoint sets up listener and endpoint
func (s *Server) listenAndEndpoint() error {
	if s.lis == nil {
		lis, err := net.Listen(s.network, s.address)
		if err != nil {
			s.err = err
			return err
		}
		s.lis = lis
	}

	if s.endpoint == nil {
		addr, err := extractAddr(s.address, s.lis)
		if err != nil {
			s.err = err
			return err
		}

		scheme := "http"
		if s.tlsConf != nil {
			scheme = "https"
		}

		s.endpoint = &url.URL{
			Scheme: scheme,
			Host:   addr,
		}
	}

	return s.err
}

// extractAddr extracts the address from listener
func extractAddr(hostPort string, lis net.Listener) (string, error) {
	addr, port, err := net.SplitHostPort(hostPort)
	if err != nil && lis == nil {
		return "", err
	}

	if lis != nil {
		if tcpAddr, ok := lis.Addr().(*net.TCPAddr); ok {
			port = strconv.Itoa(tcpAddr.Port)
		}
	}

	if len(addr) > 0 && (addr != "0.0.0.0" && addr != "[::]" && addr != "::") {
		return net.JoinHostPort(addr, port), nil
	}

	// Use localhost for local development
	return net.JoinHostPort("127.0.0.1", port), nil
}
