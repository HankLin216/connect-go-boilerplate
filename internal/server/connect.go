package server

import (
	"github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
	"github.com/HankLin216/connect-go-boilerplate/pkg/middleware/recovery"
	connectTransport "github.com/HankLin216/connect-go-boilerplate/pkg/transport/connect"
	"go.uber.org/zap"
)

// NewConnectServer creates a new Connect server.
func NewConnectServer(c *conf.Server, greeter *service.GreeterService, logger *zap.Logger) *connectTransport.Server {
	var opts = []connectTransport.ServerOption{
		connectTransport.Middleware(
			recovery.Recovery(),
		),
		connectTransport.EnableReflection(true), // Enable gRPC reflection
	}

	// Configure server options from HTTP config
	if c.Http.Network != "" {
		opts = append(opts, connectTransport.Network(c.Http.Network))
	}
	if c.Http.Addr != "" {
		opts = append(opts, connectTransport.Address(c.Http.Addr))
	}
	if c.Http.Timeout != nil {
		opts = append(opts, connectTransport.Timeout(c.Http.Timeout.AsDuration()))
	}

	// Create Connect server
	srv := connectTransport.NewServer(opts...)

	// Register Connect service
	path, handler := greeterv1connect.NewGreeterHandler(greeter)
	srv.RegisterHandler(path, handler)

	// Set up reflection services
	services := []string{
		"greeter.v1.Greeter",
	}
	srv.SetReflectionServices(services)

	return srv
}
