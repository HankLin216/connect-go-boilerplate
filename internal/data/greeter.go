package data

import (
	"context"

	"github.com/HankLin216/connect-go-boilerplate/internal/biz"

	"go.uber.org/zap"
)

type greeterRepo struct {
	data *Data
	log  *zap.Logger
}

// NewGreeterRepo .
func NewGreeterRepo(data *Data, logger *zap.Logger) biz.GreeterRepo {
	return &greeterRepo{
		data: data,
		log:  logger,
	}
}

func (r *greeterRepo) Save(ctx context.Context, g *biz.Greeter) (*biz.Greeter, error) {
	return g, nil
}

func (r *greeterRepo) Update(ctx context.Context, g *biz.Greeter) (*biz.Greeter, error) {
	return g, nil
}

func (r *greeterRepo) FindByID(context.Context, int64) (*biz.Greeter, error) {
	return nil, nil
}

func (r *greeterRepo) ListByHello(context.Context, string) ([]*biz.Greeter, error) {
	return nil, nil
}

func (r *greeterRepo) ListAll(context.Context) ([]*biz.Greeter, error) {
	return nil, nil
}
