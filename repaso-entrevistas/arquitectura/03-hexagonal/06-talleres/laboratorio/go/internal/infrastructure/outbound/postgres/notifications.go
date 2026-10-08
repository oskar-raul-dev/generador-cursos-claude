package postgres

import (
	"context"
	"encoding/json"
	"time"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

type Notifications struct{ DB *DB }

func (n Notifications) List(ctx context.Context, orderID string, page application.PageRequest) (application.Page[application.Notification], error) {
	sql := "SELECT id::text, order_id::text, type, recipient, created_at FROM notifications WHERE true"
	args := []any{}
	if orderID != "" {
		args = append(args, orderID)
		sql += " AND order_id = $" + itoa(len(args)) + "::uuid"
	}
	if ts, id, ok := decodeTimeCursor(page.Cursor); ok {
		args = append(args, ts, id)
		sql += " AND (created_at, id) < ($" + itoa(len(args)-1) + ", $" + itoa(len(args)) + "::uuid)"
	}
	args = append(args, page.Limit+1)
	sql += " ORDER BY created_at DESC, id DESC LIMIT $" + itoa(len(args))

	rows, err := n.DB.Q(ctx).Query(ctx, sql, args...)
	if err != nil {
		return application.Page[application.Notification]{}, err
	}
	defer rows.Close()
	var items []application.Notification
	for rows.Next() {
		var it application.Notification
		if err := rows.Scan(&it.ID, &it.OrderID, &it.Type, &it.Recipient, &it.CreatedAt); err != nil {
			return application.Page[application.Notification]{}, err
		}
		items = append(items, it)
	}
	var next *string
	if len(items) > page.Limit {
		items = items[:page.Limit]
		last := items[len(items)-1]
		next = encodeTimeCursor(last.CreatedAt, last.ID)
	}
	return application.Page[application.Notification]{Items: items, NextCursor: next}, rows.Err()
}

// TableNotifier "entrega" escribiendo una fila; el id es el del evento, y ON CONFLICT DO NOTHING
// hace que una segunda entrega del mismo hecho no cree una segunda fila.
type TableNotifier struct{ DB *DB }

func (t TableNotifier) Notify(ctx context.Context, e domain.Event, recipient string) error {
	payload, _ := json.Marshal(map[string]string{"eventId": e.EventID(), "occurredAt": e.OccurredAt().UTC().Format(time.RFC3339Nano)})
	_, err := t.DB.Q(ctx).Exec(ctx,
		"INSERT INTO notifications (id, order_id, type, recipient, payload) VALUES ($1::uuid, $2::uuid, $3, $4, $5::jsonb) ON CONFLICT (id) DO NOTHING",
		e.EventID(), e.OrderID(), e.Type(), recipient, string(payload))
	return err
}
