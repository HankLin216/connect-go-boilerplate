//go:build wireinject
// +build wireinject

// The build tag makes sure the stub is not built in the final build.

package main

import (
	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	"github.com/HankLin216/connect-go-boilerplate/internal/data"
	"github.com/HankLin216/connect-go-boilerplate/internal/server"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
	"github.com/HankLin216/connect-go-boilerplate/pkg/app"

	"github.com/google/wire"
	"go.uber.org/zap"
)

// wireApp init application.
func wireApp(*conf.Server, *conf.Data, *zap.Logger) (*app.App, func(), error) {
	panic(wire.Build(server.ProviderSet, data.ProviderSet, biz.ProviderSet, service.ProviderSet, newApp))
}
