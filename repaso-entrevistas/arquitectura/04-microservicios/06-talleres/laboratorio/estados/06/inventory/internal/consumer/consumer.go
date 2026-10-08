// Package consumer: inventory escucha los hechos de orders (taller 06).
package consumer

import (
	"context"
	"encoding/json"
	"log"
	"os"

	"github.com/twmb/franz-go/pkg/kgo"

	"ms.dev/inventory/internal/store"
)

const (
	Group = "inventory"
	Topic = "orders.events"
	DLQ   = "orders.events.dlq"
)

type Options struct {
	Brokers []string
	Inbox   bool   // deduplicar por eventId en processed_messages (la corrección)
	Chaos   string // crash-after-effect: morir después del efecto y ANTES de confirmar el offset
}

type event struct {
	EventID string `json:"eventId"`
	Type    string `json:"type"`
	Lines   []struct {
		SKU      string `json:"sku"`
		Quantity int    `json:"quantity"`
	} `json:"lines"`
}

// Run consume hasta que ctx se cancela. El offset se confirma a mano, DESPUÉS del efecto: si el proceso
// muere entre los dos, el mensaje se vuelve a entregar. Al menos una vez; el inbox pone el "una sola".
func Run(ctx context.Context, st *store.Store, opt Options) error {
	cl, err := kgo.NewClient(
		kgo.SeedBrokers(opt.Brokers...),
		kgo.ConsumerGroup(Group),
		kgo.ConsumeTopics(Topic),
		kgo.ConsumeResetOffset(kgo.NewOffset().AtStart()), // grupo nuevo: desde el principio del log
		kgo.DisableAutoCommit(),                           // el offset lo decide el código, no un temporizador
	)
	if err != nil {
		return err
	}
	defer cl.Close()
	log.Printf("consumer %s on %s (inbox=%v chaos=%s)", Group, Topic, opt.Inbox, opt.Chaos)
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
	var ev event
	if err := json.Unmarshal(r.Value, &ev); err != nil || ev.EventID == "" {
		// venenoso: no se puede leer y reintentarlo no lo arreglará. A la DLQ, con el motivo, y se sigue.
		dlq := &kgo.Record{Topic: DLQ, Key: r.Key, Value: r.Value, Headers: []kgo.RecordHeader{
			{Key: "error", Value: []byte("unreadable event")}, {Key: "consumer", Value: []byte(Group)}}}
		if err := cl.ProduceSync(ctx, dlq).FirstErr(); err != nil {
			log.Printf("p%d o%d: DLQ produce failed: %v", r.Partition, r.Offset, err)
		}
		log.Printf("p%d o%d key=%s → DLQ (unreadable)", r.Partition, r.Offset, r.Key)
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
	log.Printf("p%d o%d %s %s → %s", r.Partition, r.Offset, ev.Type, ev.EventID[:8], verdict)
	if applied && opt.Chaos == "crash-after-effect" {
		log.Printf("CHAOS crash-after-effect: sale applied, exiting BEFORE committing offset %d", r.Offset)
		os.Exit(137)
	}
}
