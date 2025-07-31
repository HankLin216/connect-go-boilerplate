//go:build wireinject
// +build wireinject

// The build tag makes sure the stub is not built in the final build.

package main

import (
	"net/http"

	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	"github.com/HankLin216/connect-go-boilerplate/internal/data"
	"github.com/HankLin216/connect-go-boilerplate/internal/mux"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"

	"github.com/google/wire"
)

// wireApp init application.
func wireApp(*conf.Server, *conf.Bootstrap) (*http.Server, func(), error) {
	panic(wire.Build(mux.ProviderSet, data.ProviderSet, biz.ProviderSet, service.ProviderSet, newApp))
}
