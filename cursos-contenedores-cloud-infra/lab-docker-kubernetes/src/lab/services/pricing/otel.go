// G10 (Fase 23): las trazas. Si hay OTEL_EXPORTER_OTLP_ENDPOINT, cada petición HTTP y cada llamada gRPC abre un
// span, sigue el traceparent que trae (W3C Trace Context) y lo manda a Tempo por OTLP/HTTP. Sin la variable, no se
// traza nada y no cuesta nada: el proveedor por defecto de OpenTelemetry no hace nada.
package main

import (
	"context"
	"log/slog"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

// setupTracing devuelve la función que vacía los spans pendientes al apagar.
func setupTracing() func() {
	// El propagador se pone siempre: aunque pricing no exporte, pasa el traceparent que recibe.
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	if os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT") == "" {
		return func() {}
	}
	// El exportador lee OTEL_EXPORTER_OTLP_ENDPOINT y las demás OTEL_* estándar.
	exporter, err := otlptracehttp.New(context.Background())
	if err != nil {
		slog.Warn("sin trazas: no se pudo armar el exportador", "error", err.Error())
		return func() {}
	}
	provider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resource.NewSchemaless(semconv.ServiceName("pricing"))),
	)
	otel.SetTracerProvider(provider)
	slog.Info("trazas encendidas", "endpoint", os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT"))
	return func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = provider.Shutdown(ctx)
	}
}
