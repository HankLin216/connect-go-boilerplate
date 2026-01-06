package mux

import (
	"net/http"

	"connectrpc.com/connect"
	h "connectrpc.com/grpchealth"
	"connectrpc.com/grpcreflect"
	"connectrpc.com/otelconnect"
	g "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
)

var Services = []string{
	g.GreeterName,
	h.HealthV1ServiceName,
}

func New(gs *service.GreeterService) *http.ServeMux {
	// otel interceptor
	otelInterceptor, err := otelconnect.NewInterceptor()
	if err != nil {
		// Log error or panic? For now, we panic as it's initialization.
		panic(err)
	}

	mux := http.NewServeMux()
	mux.Handle(g.NewGreeterHandler(gs,
		connect.WithInterceptors(otelInterceptor),
	))

	// health
	checker := h.NewStaticChecker(Services...)
	mux.Handle(h.NewHandler(checker))

	// reflect
	reflector := grpcreflect.NewStaticReflector(Services...)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return mux
}
