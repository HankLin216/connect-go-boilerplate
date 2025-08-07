package mux

import (
	"net/http"

	h "connectrpc.com/grpchealth"
	"connectrpc.com/grpcreflect"
	g "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
)

var Services = []string{
	g.GreeterName,
	h.HealthV1ServiceName,
}

func New(gs *service.GreeterService) *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle(g.NewGreeterHandler(gs))

	// health
	checker := h.NewStaticChecker(Services...)
	mux.Handle(h.NewHandler(checker))

	// reflect
	reflector := grpcreflect.NewStaticReflector(Services...)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return mux
}
