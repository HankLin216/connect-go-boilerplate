// Code generated by Wire. DO NOT EDIT.

//go:generate go run -mod=mod github.com/google/wire/cmd/wire
//go:build !wireinject
// +build !wireinject

package main

import (
	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	"github.com/HankLin216/connect-go-boilerplate/internal/data"
	"github.com/HankLin216/connect-go-boilerplate/internal/server"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
	"github.com/HankLin216/connect-go-boilerplate/pkg/app"
	"go.uber.org/zap"
)

// Injectors from wire.go:

// wireApp init application.
func wireApp(confServer *conf.Server, confData *conf.Data, logger *zap.Logger) (*app.App, func(), error) {
	dataData, cleanup, err := data.NewData(confData, logger)
	if err != nil {
		return nil, nil, err
	}
	greeterRepo := data.NewGreeterRepo(dataData, logger)
	greeterUsecase := biz.NewGreeterUsecase(greeterRepo, logger)
	greeterService := service.NewGreeterService(greeterUsecase, logger)
	connectServer := server.NewConnectServer(confServer, greeterService, logger)
	appApp := newApp(connectServer, logger)
	return appApp, func() {
		cleanup()
	}, nil
}
