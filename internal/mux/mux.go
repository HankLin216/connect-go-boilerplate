package mux

import (
	"net/http"

	"connectrpc.com/connect"
	h "connectrpc.com/grpchealth"
	"connectrpc.com/grpcreflect"
	"connectrpc.com/otelconnect"
	g "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	"github.com/HankLin216/connect-go-boilerplate/internal/service"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/prometheus"
	"go.opentelemetry.io/otel/sdk/metric"
)

var Services = []string{
	g.GreeterName,
	h.HealthV1ServiceName,
}

func New(gs *service.GreeterService) *http.ServeMux {
	// prometheus exporter (registers as global MeterProvider)
	promExporter, err := prometheus.New()
	if err != nil {
		panic(err)
	}
	meterProvider := metric.NewMeterProvider(metric.WithReader(promExporter))

	// otel interceptor (traces → Jaeger, metrics → Prometheus)
	otelInterceptor, err := otelconnect.NewInterceptor(
		otelconnect.WithTracerProvider(otel.GetTracerProvider()),
		otelconnect.WithMeterProvider(meterProvider),
	)
	if err != nil {
		panic(err)
	}

	mux := http.NewServeMux()
	mux.Handle(g.NewGreeterHandler(gs,
		connect.WithInterceptors(otelInterceptor),
	))

	// metrics
	mux.Handle("/metrics", promhttp.Handler())

	// health
	checker := h.NewStaticChecker(Services...)
	mux.Handle(h.NewHandler(checker))

	// reflect
	reflector := grpcreflect.NewStaticReflector(Services...)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return mux
}
