package mux

import (
	"net/http"

	"connectrpc.com/grpchealth"
	"connectrpc.com/grpcreflect"
	g "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
)

var Services = []string{
	g.GreeterName,
}

func New(gs *service.GreeterService) *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle(g.NewGreeterHandler(gs))

	// health
	checker := grpchealth.NewStaticChecker(Services...)
	mux.Handle(grpchealth.NewHandler(checker))

	// reflect
	reflector := grpcreflect.NewStaticReflector(Services...)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return mux
}
