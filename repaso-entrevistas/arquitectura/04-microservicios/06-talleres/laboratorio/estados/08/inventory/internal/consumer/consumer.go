// Package consumer: inventory escucha los hechos de orders (taller 06) y participa en la saga (taller 08).
package consumer

import (
	"context"
	"encoding/json"
	"log"
	"os"

	"github.com/twmb/franz-go/pkg/kgo"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"

	"ms.dev/inventory/internal/store"
	"ms.dev/inventory/internal/telemetry"
)

const (
	Group = "inventory"
	Topic = "orders.events"
)

type Options struct {
	Brokers []string
	Inbox   bool   // deduplicar por eventId en processed_messages (la corrección)
	Chaos   string // crash-after-effect: morir después del efecto y ANTES de confirmar el offset
	// TraceKafka: leer el traceparent de los encabezados y continuar esa traza (taller 07). Sin esto,
	// cada mensaje abre una traza nueva y la del pedido se corta en el topic.
	TraceKafka bool
}

var tracer = otel.Tracer("ms.dev/inventory/consumer")

type event struct {
	EventID string `json:"eventId"`
	Type    string `json:"type"`
	OrderID string `json:"orderId"`
	Lines   []struct {
		SKU      string `json:"sku"`
		Quantity int    `json:"quantity"`
	} `json:"lines"`
	Total json.RawMessage `json:"total,omitempty"` // taller 08: se copia tal cual en InventoryReserved
}

// Run consume hasta que ctx se cancela. El offset se confirma a mano, DESPUÉS del efecto: si el proceso
// muere entre los dos, el mensaje se vuelve a entregar. Al menos una vez; el inbox pone el "una sola".
func Run(ctx context.Context, st *store.Store, opt Options) error {
	cl, err := kgo.NewClient(
		kgo.SeedBrokers(opt.Brokers...),
		kgo.ConsumerGroup(Group),
		kgo.ConsumeTopics(Topic, TopicPlaced, TopicPayments), // taller 08: + los dos de la saga
		kgo.ConsumeResetOffset(kgo.NewOffset().AtStart()), // grupo nuevo: desde el principio del log
		kgo.DisableAutoCommit(),                           // el offset lo decide el código, no un temporizador
	)
	if err != nil {
		return err
	}
	defer cl.Close()
	log.Printf("consumer %s on %s, %s, %s (inbox=%v chaos=%s)", Group, Topic, TopicPlaced, TopicPayments, opt.Inbox, opt.Chaos)
	for {
		fetches := cl.PollFetches(ctx)
		if ctx.Err() != nil {
			return nil
		}
		fetches.EachError(func(t string, p int32, err error) { log.Printf("fetch %s/%d: %v", t, p, err) })
		for _, r := range fetches.Records() {
			handle(ctx, cl, st, opt, r)
			if err := cl.CommitRecords(ctx, r); err != nil {
				log.Printf("commit p%d o%d: %v", r.Partition, r.Offset, err)
			}
		}
	}
}

func handle(ctx context.Context, cl *kgo.Client, st *store.Store, opt Options, r *kgo.Record) {
	if opt.TraceKafka {
		ctx = otel.GetTextMapPropagator().Extract(ctx, telemetry.Headers{R: r})
	}
	// span de consumidor: hijo del productor si el contexto venía en el mensaje; raíz si no
	ctx, span := tracer.Start(ctx, r.Topic+" process", trace.WithSpanKind(trace.SpanKindConsumer),
		trace.WithAttributes(attribute.String("messaging.system", "kafka"),
			attribute.String("messaging.consumer.group.name", Group),
			attribute.Int("messaging.destination.partition.id", int(r.Partition)),
			attribute.Int64("messaging.kafka.offset", r.Offset)))
	defer span.End()
	tid := span.SpanContext().TraceID().String()[:8]
	var ev event
	if err := json.Unmarshal(r.Value, &ev); err != nil || ev.EventID == "" {
		// venenoso: no se puede leer y reintentarlo no lo arreglará. A la DLQ, con el motivo, y se sigue.
		toDLQ(ctx, cl, r, "unreadable event") // a la DLQ de SU topic (orders.events.dlq, orders.placed.dlq…)
		log.Printf("p%d o%d key=%s → DLQ (unreadable)", r.Partition, r.Offset, r.Key)
		return
	}
	span.SetAttributes(attribute.String("ms.event.type", ev.Type))
	if r.Topic != Topic { // taller 08: la saga
		if len(ev.OrderID) < 8 { // un hecho de la saga sin pedido tampoco mejora reintentando
			toDLQ(ctx, cl, r, "saga event without orderId")
			return
		}
		verdict := sagaStep(ctx, cl, st, r, ev)
		span.SetAttributes(attribute.String("ms.event.verdict", verdict))
		log.Printf("p%d o%d %s %s order=%s → %s [trace=%s]", r.Partition, r.Offset, ev.Type, ev.EventID[:8], ev.OrderID[:8], verdict, tid)
		return
	}
	if ev.Type != "OrderPaid" {
		return // a inventory solo le interesa lo pagado; lo demás se confirma y se sigue
	}
	items := make([]store.Item, 0, len(ev.Lines))
	for _, l := range ev.Lines {
		items = append(items, store.Item{SKU: l.SKU, Qty: l.Quantity})
	}
	applied, err := st.ApplySale(ctx, Group, ev.EventID, items, opt.Inbox)
	if err != nil {
		log.Printf("p%d o%d %s %s: %v", r.Partition, r.Offset, ev.Type, ev.EventID, err)
		return
	}
	verdict := "applied"
	if !applied {
		verdict = "already applied, skipped"
	}
	span.SetAttributes(attribute.String("ms.event.verdict", verdict))
	log.Printf("p%d o%d %s %s → %s [trace=%s]", r.Partition, r.Offset, ev.Type, ev.EventID[:8], verdict, tid)
	if applied && opt.Chaos == "crash-after-effect" {
		log.Printf("CHAOS crash-after-effect: sale applied, exiting BEFORE committing offset %d", r.Offset)
		os.Exit(137)
	}
}
