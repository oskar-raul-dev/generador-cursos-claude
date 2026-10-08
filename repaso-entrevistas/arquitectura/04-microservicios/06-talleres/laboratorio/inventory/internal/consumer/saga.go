package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/twmb/franz-go/pkg/kgo"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"

	"ms.dev/inventory/internal/store"
)

// Los topics de la saga coreografiada (taller 08). inventory lee los dos primeros y publica en el tercero.
const (
	TopicPlaced       = "orders.placed"          // OrderPlaced (contrato v2)
	TopicPayments     = "payments.results"       // PaymentAuthorized · PaymentRejected
	TopicReservations = "inventory.reservations" // InventoryReserved · InventoryReservationFailed · InventoryReleased
)

// sagaStep es la parte de inventory en la saga. Nadie se lo pide: reacciona a un hecho y publica otro.
// Inbox, efecto y hecho nuevo van en UNA transacción (store.SagaStep); el hecho sale por el outbox.
func sagaStep(ctx context.Context, cl *kgo.Client, st *store.Store, r *kgo.Record, ev event) string {
	tc := traceparent(ctx)
	var verdict string
	var err error
	for attempt := 1; attempt <= 3; attempt++ { // transitorio (la base): reintentar; tras 3, a la DLQ
		var applied bool
		applied, err = st.SagaStep(ctx, Group, ev.EventID, func(tx pgx.Tx) ([]store.Event, error) {
			return react(ctx, tx, ev, tc, &verdict)
		})
		if err == nil {
			if !applied {
				verdict = "already applied, skipped"
			}
			return verdict
		}
		log.Printf("p%d o%d %s attempt %d failed: %v", r.Partition, r.Offset, ev.Type, attempt, err)
		time.Sleep(time.Duration(200*attempt) * time.Millisecond)
	}
	toDLQ(ctx, cl, r, err.Error())
	return "→ DLQ (max attempts)"
}

// react decide qué hace inventory con cada hecho: la lógica de la saga, repartida (la otra mitad
// vive en payments y en orders). Ningún archivo del sistema contiene la saga entera.
func react(ctx context.Context, tx pgx.Tx, ev event, tc string, verdict *string) ([]store.Event, error) {
	switch ev.Type {
	case "OrderPlaced":
		_, short, err := store.HoldTx(ctx, tx, ev.OrderID, items(ev))
		if err != nil {
			return nil, err
		}
		if len(short) > 0 {
			*verdict = "InventoryReservationFailed"
			return []store.Event{fact(ev, "InventoryReservationFailed", tc, map[string]any{"shortages": short})}, nil
		}
		*verdict = "InventoryReserved"
		// el importe NO es de inventory: viaja porque payments lo necesita y no quiere preguntar a orders
		return []store.Event{fact(ev, "InventoryReserved", tc, map[string]any{"lines": ev.Lines, "total": ev.Total})}, nil
	case "PaymentRejected":
		back, err := store.ReleaseTx(ctx, tx, ev.OrderID)
		if err != nil {
			return nil, err
		}
		*verdict = fmt.Sprintf("InventoryReleased (%d lines)", len(back))
		return []store.Event{fact(ev, "InventoryReleased", tc, map[string]any{"released": back})}, nil
	case "PaymentAuthorized":
		n, err := store.CommitTx(ctx, tx, ev.OrderID)
		*verdict = fmt.Sprintf("committed %d lines", n)
		return nil, err
	}
	*verdict = "ignored"
	return nil, nil
}

func items(ev event) []store.Item {
	out := make([]store.Item, 0, len(ev.Lines))
	for _, l := range ev.Lines {
		out = append(out, store.Item{SKU: l.SKU, Qty: l.Quantity})
	}
	return out
}

// fact construye un hecho de inventory. causationId apunta al hecho que lo provocó: sin él, nadie
// puede reconstruir la cadena, y un ciclo es invisible (06/08 §8).
func fact(cause event, typ, tc string, fields map[string]any) store.Event {
	id := store.NewEventID()
	body := map[string]any{"eventId": id, "type": typ, "version": 1,
		"occurredAt": time.Now().UTC().Format(time.RFC3339Nano), "orderId": cause.OrderID, "causationId": cause.EventID}
	for k, v := range fields {
		body[k] = v
	}
	payload, _ := json.Marshal(body)
	return store.Event{ID: id, OrderID: cause.OrderID, Topic: TopicReservations, Type: typ, Payload: payload, TraceContext: tc}
}

// traceparent del span en curso, para guardarlo en la fila del outbox (06/07).
func traceparent(ctx context.Context) string {
	c := propagation.MapCarrier{}
	otel.GetTextMapPropagator().Inject(ctx, c)
	return c.Get("traceparent")
}

func toDLQ(ctx context.Context, cl *kgo.Client, r *kgo.Record, reason string) {
	dlq := &kgo.Record{Topic: r.Topic + ".dlq", Key: r.Key, Value: r.Value, Headers: []kgo.RecordHeader{
		{Key: "error", Value: []byte(reason)}, {Key: "consumer", Value: []byte(Group)}}}
	if err := cl.ProduceSync(ctx, dlq).FirstErr(); err != nil {
		log.Printf("p%d o%d: DLQ produce failed: %v", r.Partition, r.Offset, err)
	}
}
