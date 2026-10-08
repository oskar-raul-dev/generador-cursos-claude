// Package notification contiene el disparador de la outbox.
package notification

import (
	"context"
	"log/slog"
	"time"

	"hexorders/internal/application"
)

// Dispatcher es una goroutine con dueño: main la arranca con un contexto y la para cancelándolo.
// Sin cancelación, una goroutine con ticker vive hasta que muere el proceso; con ella, el cierre
// es ordenado y no queda ninguna ronda a medias sin registro.
type Dispatcher struct {
	Deliver  application.DeliverPendingPublications
	Interval time.Duration
}

func (d Dispatcher) Run(ctx context.Context) {
	ticker := time.NewTicker(d.Interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			delivered, err := d.Deliver.Execute(ctx, 50)
			if err != nil {
				slog.Warn("outbox: delivery round failed", "err", err) // la siguiente ronda reintenta
				continue
			}
			if delivered > 0 {
				slog.Info("outbox: delivered events", "count", delivered)
			}
		}
	}
}
