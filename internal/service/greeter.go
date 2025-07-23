package service

import (
	"context"

	"connectrpc.com/connect"
	v1 "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1"
	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
	"go.uber.org/zap"
)

// GreeterService is a greeter service.
type GreeterService struct {
	log *zap.Logger
	uc  *biz.GreeterUsecase
}

// NewGreeterService new a greeter service.
func NewGreeterService(uc *biz.GreeterUsecase, logger *zap.Logger) *GreeterService {
	return &GreeterService{log: logger, uc: uc}
}

// SayHello implements Connect-Go GreeterHandler interface
func (s *GreeterService) SayHello(ctx context.Context, req *connect.Request[v1.HelloRequest]) (*connect.Response[v1.HelloResponse], error) {
	g, err := s.uc.CreateGreeter(ctx, &biz.Greeter{Name: req.Msg.Name})
	if err != nil {
		return nil, err
	}
	resp := &v1.HelloResponse{Message: "Hello " + g.Name}
	return connect.NewResponse(resp), nil
}
