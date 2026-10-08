// Package telemetry: OpenTelemetry para inventory (taller 07). En Go no hay agente que se enganche al
// arrancar: el SDK, el exportador y el propagador se configuran aquí, y cada biblioteca se instrumenta
// a mano (otelhttp, otelgrpc) o no se instrumenta (pgx, franz-go en este laboratorio).
package telemetry

import (
	"context"

	"github.com/twmb/franz-go/pkg/kgo"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

// Setup envía las trazas por OTLP/gRPC al collector. Con endpoint vacío no configura nada: la API
// global de otel queda en no-op y el servicio funciona igual, sin trazas.
func Setup(ctx context.Context, service, endpoint string) (func(context.Context) error, error) {
	if endpoint == "" {
		return func(context.Context) error { return nil }, nil
	}
	exp, err := otlptracegrpc.New(ctx, otlptracegrpc.WithEndpoint(endpoint), otlptracegrpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	res, err := resource.Merge(resource.Default(),
		resource.NewSchemaless(attribute.String("service.name", service)))
	if err != nil {
		return nil, err
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp), // en lotes, en segundo plano: exportar no bloquea la petición
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)
	// W3C Trace Context: el mismo formato (traceparent) que escriben el agente de Java y Python
	otel.SetTextMapPropagator(propagation.TraceContext{})
	return tp.Shutdown, nil // vacía el lote pendiente al apagar; un os.Exit lo pierde
}

// Headers adapta los encabezados de un registro de Kafka a lo que el propagador sabe leer y escribir.
// Es lo que en HTTP hace http.Header y en gRPC los metadatos: aquí hay que escribirlo.
type Headers struct{ R *kgo.Record }

func (h Headers) Get(key string) string {
	for _, x := range h.R.Headers {
		if x.Key == key {
			return string(x.Value)
		}
	}
	return ""
}

func (h Headers) Set(key, value string) {
	h.R.Headers = append(h.R.Headers, kgo.RecordHeader{Key: key, Value: []byte(value)})
}

func (h Headers) Keys() []string {
	keys := make([]string, 0, len(h.R.Headers))
	for _, x := range h.R.Headers {
		keys = append(keys, x.Key)
	}
	return keys
}
