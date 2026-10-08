// Package outbox: el publicador del outbox de inventory (taller 08). Es el mismo algoritmo que el
// OutboxPublisher de orders (06/06), en Go: leer lo pendiente con FOR UPDATE SKIP LOCKED, enviarlo
// esperando la confirmación del broker, marcarlo. Al menos una vez.
package outbox

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/twmb/franz-go/pkg/kgo"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"

	"ms.dev/inventory/internal/telemetry"
)

var tracer = otel.Tracer("ms.dev/inventory/outbox")

type pending struct {
	id, orderID, topic, typ, payload, traceContext string
}

// Run publica cada `every` hasta que ctx se cancela.
func Run(ctx context.Context, pool *pgxpool.Pool, brokers []string, every time.Duration) error {
	cl, err := kgo.NewClient(kgo.SeedBrokers(brokers...)) // productor idempotente y acks=all por defecto en franz-go
	if err != nil {
		return err
	}
	defer cl.Close()
	log.Printf("outbox publisher every %s", every)
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-t.C:
			if err := publishPending(ctx, pool, cl); err != nil && ctx.Err() == nil {
				log.Printf("outbox: not published yet: %v", err) // se reintenta en la siguiente ronda, en orden
			}
		}
	}
}

func publishPending(ctx context.Context, pool *pgxpool.Pool, cl *kgo.Client) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT id::text, aggregate_id::text, topic, type, payload, coalesce(trace_context, '')
			FROM outbox_events WHERE published_at IS NULL ORDER BY occurred_at LIMIT 100 FOR UPDATE SKIP LOCKED`)
		if err != nil {
			return err
		}
		var batch []pending
		for rows.Next() {
			var p pending
			if err := rows.Scan(&p.id, &p.orderID, &p.topic, &p.typ, &p.payload, &p.traceContext); err != nil {
				return err
			}
			batch = append(batch, p)
		}
		if err := rows.Err(); err != nil {
			return err
		}
		for _, p := range batch {
			if err := send(ctx, cl, p); err != nil {
				return err // rollback: nada de este lote queda marcado si falla uno
			}
			if _, err := tx.Exec(ctx, `UPDATE outbox_events SET published_at = clock_timestamp() WHERE id = $1`, p.id); err != nil {
				return err
			}
		}
		return nil
	})
}

// send envía un hecho DENTRO de la traza que lo provocó (el traceparent guardado en la fila): lo que
// en Java hace el agente con makeCurrent(), aquí se escribe (06/07).
func send(ctx context.Context, cl *kgo.Client, p pending) error {
	if p.traceContext != "" {
		ctx = otel.GetTextMapPropagator().Extract(ctx, propagation.MapCarrier{"traceparent": p.traceContext})
	}
	ctx, span := tracer.Start(ctx, p.topic+" publish", trace.WithSpanKind(trace.SpanKindProducer),
		trace.WithAttributes(attribute.String("messaging.system", "kafka"), attribute.String("ms.event.type", p.typ)))
	defer span.End()
	rec := &kgo.Record{Topic: p.topic, Key: []byte(p.orderID), Value: []byte(p.payload)}
	otel.GetTextMapPropagator().Inject(ctx, telemetry.Headers{R: rec})
	return cl.ProduceSync(ctx, rec).FirstErr()
}
