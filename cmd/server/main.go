package main

import (
	"flag"
	"net/http"
	"os"
	"time"

	"github.com/HankLin216/connect-go-boilerplate/internal/conf"
	"github.com/HankLin216/go-utils/config"
	"github.com/HankLin216/go-utils/config/file"
	"github.com/HankLin216/go-utils/log"
	"github.com/HankLin216/go-utils/tracer"
	"github.com/rs/cors"
	"go.elastic.co/ecszap"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"
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

func newApp(mux *http.ServeMux, c *conf.Bootstrap) *http.Server {
	return &http.Server{
		Addr: c.Server.Http.Addr,
		Handler: h2c.NewHandler(
			cors.AllowAll().Handler(mux),
			&http2.Server{},
		),
		ReadHeaderTimeout: time.Second,
		ReadTimeout:       c.Server.Http.Timeout.AsDuration(),
		WriteTimeout:      c.Server.Http.Timeout.AsDuration(),
		MaxHeaderBytes:    8 * 1024, // 8KiB
	}
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

	// init tracer
	// we ignore the returned provider here as it sets the global one, but we keep cleanup
	_, cleanup, err := tracer.NewTracerProvider(toTracerConfig(&bc), &tracer.Info{
		Name:    Name,
		Version: Version,
		Env:     Env,
	})
	if err != nil {
		panic(err)
	}
	defer cleanup()

	// start app
	log.Info("Server infos",
		zap.String("Name", Name),
		zap.String("Version", Version),
		zap.String("Env", Env),
		zap.String("ConfigFolderPath", ConfFolderPath),
		zap.String("BuildTime", BuildTime),
		zap.String("Address", bc.Server.Http.GetAddr()),
	)

	app, cleanup, err := wireApp(bc.Server, &bc)
	if err != nil {
		panic(err)
	}
	defer cleanup()

	// start and wait for stop signal
	if err := app.ListenAndServe(); err != nil {
		panic(err)
	}
}

func toTracerConfig(bc *conf.Bootstrap) *tracer.Config {
	return &tracer.Config{
		Enable:   bc.Server.Trace.Enable,
		Endpoint: bc.Server.Trace.Endpoint,
	}
}
