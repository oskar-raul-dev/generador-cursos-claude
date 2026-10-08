package postgres

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"

	"hexorders/internal/application"
)

// IdempotencyStore: la clave vive en PostgreSQL, en la misma transacción que el efecto.
// response_body es jsonb: se escribe y se lee con encoding/json, nunca por posición.
type IdempotencyStore struct{ DB *DB }

type storedRef struct {
	Ref string `json:"ref"`
}

func (s IdempotencyStore) Find(ctx context.Context, actorID, key string) (*application.StoredResponse, error) {
	var hash, body string
	var status int
	err := s.DB.Q(ctx).QueryRow(ctx,
		"SELECT request_hash, response_status, response_body::text FROM idempotency_keys WHERE key = $1 AND actor_id = $2::uuid", key, actorID).
		Scan(&hash, &status, &body)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var ref storedRef
	if err := json.Unmarshal([]byte(body), &ref); err != nil {
		return nil, err
	}
	return &application.StoredResponse{RequestHash: hash, Status: status, Body: ref.Ref}, nil
}

func (s IdempotencyStore) Save(ctx context.Context, actorID, key, requestHash string, status int, body string) error {
	payload, _ := json.Marshal(storedRef{Ref: body})
	_, err := s.DB.Q(ctx).Exec(ctx,
		"INSERT INTO idempotency_keys (key, actor_id, request_hash, response_status, response_body) VALUES ($1, $2::uuid, $3, $4, $5::jsonb)",
		key, actorID, requestHash, status, string(payload))
	return err
}
