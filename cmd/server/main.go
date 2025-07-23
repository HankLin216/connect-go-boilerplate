package main

import (
	"flag"
	"os"
	"time"

	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	app "github.com/HankLin216/connect-go-boilerplate/pkg/app"
	connectTransport "github.com/HankLin216/connect-go-boilerplate/pkg/transport/connect"
	"github.com/HankLin216/go-utils/config"
	"github.com/HankLin216/go-utils/config/file"
	"github.com/HankLin216/go-utils/log"
	"go.elastic.co/ecszap"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	Name           = "connect-go-boilerplate"
	Version        = "v1.0.0"
	Env            = "Development"
	ConfFolderPath = "../../configs"
	BuildTime      = time.Now().Format(time.RFC3339)

	id, _ = os.Hostname()
)

func init() {
	flag.StringVar(&Version, "Version", Version, "input the service version")
	flag.StringVar(&Env, "Env", Env, "input the environment")
	flag.StringVar(&ConfFolderPath, "ConfFolderPath", ConfFolderPath, "input the config path")
}

func newApp(cs *connectTransport.Server, logger *zap.Logger) *app.App {
	return app.New(
		app.ID(id),
		app.Name(Name),
		app.Version(Version),
		app.Metadata(map[string]string{}),
		app.Logger(logger),
		app.Server(
			cs, // Connect server
		),
	)
}

func main() {
	// flag
	flag.Parse()

	// logger
	logLevel := zapcore.DebugLevel
	if Env == "Production" {
		logLevel = zapcore.InfoLevel
	}
	logger := zap.New(
		ecszap.NewCore(ecszap.NewDefaultEncoderConfig(), os.Stdout, logLevel),
		zap.AddCaller(),
	)
	defer logger.Sync()
	logger.Info("Server infos",
		zap.String("Name", Name),
		zap.String("Version", Version),
		zap.String("Env", Env),
		zap.String("ConfigFolderPath", ConfFolderPath),
		zap.String("BuildTime", BuildTime),
	)

	// update global logger
	log.SetLogger(logger)

	// config
	c := config.New(
		config.WithSource(
			file.NewSource(ConfFolderPath),
		),
	)
	defer c.Close()

	if err := c.Load(); err != nil {
		panic(err)
	}

	var bc conf.Bootstrap
	if err := c.Scan(&bc); err != nil {
		panic(err)
	}

	app, cleanup, err := wireApp(bc.Server, bc.Data, logger)
	if err != nil {
		panic(err)
	}
	defer cleanup()

	// start and wait for stop signal
	if err := app.Run(); err != nil {
		panic(err)
	}
}
