// El publicador del outbox de inventory (G13, Fase 26). Corre como sidecar en el pod de inventory, con la misma
// imagen: lee los eventos que la venta dejó en la tabla outbox, en la misma transacción que la venta, y los publica
// en NATS JetStream. Si muere a la mitad, el evento sigue en la tabla y se publica otra vez; la cabecera
// Nats-Msg-Id (el eventId) hace que JetStream descarte la copia, y replenish, que procesa cada eventId una vez,
// tampoco la duplicaría.
package main

import (
	"context"
	"encoding/json"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

// Una línea JSON por evento, con los campos de G7.
func logLine(level, msg string, fields map[string]any) {
	line := map[string]any{"time": time.Now().UTC().Format(time.RFC3339Nano), "level": level,
		"service": "inventory", "component": "outbox-relay", "msg": msg}
	for k, v := range fields {
		line[k] = v
	}
	out, _ := json.Marshal(line)
	os.Stdout.Write(append(out, '\n'))
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	interval := 500 * time.Millisecond
	if ms, err := strconv.Atoi(os.Getenv("RELAY_INTERVAL_MS")); err == nil {
		interval = time.Duration(ms) * time.Millisecond
	}

	db, err := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		logLine("ERROR", "sin base de datos", map[string]any{"error": err.Error()})
		os.Exit(1)
	}
	defer db.Close()

	// Reconecta solo, también si NATS no está al arrancar.
	nc, err := nats.Connect(os.Getenv("NATS_URL"), nats.Name("inventory-outbox-relay"),
		nats.MaxReconnects(-1), nats.RetryOnFailedConnect(true))
	if err != nil {
		logLine("ERROR", "sin NATS", map[string]any{"error": err.Error()})
		os.Exit(1)
	}
	defer nc.Drain()
	js, _ := jetstream.New(nc)

	// El stream se asegura una vez, al arrancar, con la misma configuración que usa replenish.
	for {
		_, err = js.CreateOrUpdateStream(ctx, jetstream.StreamConfig{Name: "LAB_EVENTS", Subjects: []string{"lab.>"},
			Storage: jetstream.FileStorage, MaxAge: 24 * time.Hour})
		if err == nil {
			break
		}
		logLine("WARN", "stream LAB_EVENTS sin asegurar; se reintenta", map[string]any{"error": err.Error()})
		select {
		case <-ctx.Done():
			return
		case <-time.After(2 * time.Second):
		}
	}
	logLine("INFO", "publicando el outbox en LAB_EVENTS", map[string]any{"interval_ms": interval.Milliseconds()})

	for ctx.Err() == nil {
		n, err := relay(ctx, db, js)
		if err != nil {
			logLine("WARN", "lote sin terminar; se reintenta", map[string]any{"error": err.Error()})
		}
		if n == 0 || err != nil {
			select {
			case <-ctx.Done():
			case <-time.After(interval):
			}
		}
	}
	logLine("INFO", "apagado limpio", nil)
}

// Un lote: hasta 100 eventos sin publicar, bloqueados para que otra réplica no tome los mismos (SKIP LOCKED), y
// marcados como publicados en la misma transacción. Si NATS falla a la mitad, se confirma lo que salió.
func relay(ctx context.Context, db *pgxpool.Pool, js jetstream.JetStream) (int, error) {
	tx, err := db.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)
	rows, err := tx.Query(ctx, `SELECT id, subject, payload FROM outbox WHERE published_at IS NULL
		ORDER BY created_at LIMIT 100 FOR UPDATE SKIP LOCKED`)
	if err != nil {
		return 0, err
	}
	type event struct{ id, subject, payload string }
	var batch []event
	for rows.Next() {
		var e event
		if err := rows.Scan(&e.id, &e.subject, &e.payload); err != nil {
			return 0, err
		}
		batch = append(batch, e)
	}
	rows.Close()

	published := 0
	var failure error
	for _, e := range batch {
		msg := &nats.Msg{Subject: e.subject, Data: []byte(e.payload), Header: nats.Header{}}
		// La clave de deduplicación de JetStream: el mismo eventId publicado dos veces se guarda una.
		msg.Header.Set(jetstream.MsgIDHeader, e.id)
		ack, err := js.PublishMsg(ctx, msg)
		if err != nil {
			failure = err
			break
		}
		if ack.Duplicate {
			logLine("INFO", "evento ya publicado; JetStream descartó la copia", map[string]any{"eventId": e.id})
		}
		if _, err := tx.Exec(ctx, "UPDATE outbox SET published_at = $1 WHERE id = $2",
			time.Now().UTC().Format(time.RFC3339Nano), e.id); err != nil {
			failure = err
			break
		}
		published++
	}
	if published > 0 {
		if err := tx.Commit(ctx); err != nil {
			return 0, err
		}
		logLine("INFO", "eventos publicados", map[string]any{"count": published})
	}
	return published, failure
}
