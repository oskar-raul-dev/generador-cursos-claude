// Package redisstore guarda la revocación de tokens por jti con TTL.
package redisstore

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

const prefix = "hex:revoked:"

type TokenRevocationStore struct{ client *redis.Client }

func Open(ctx context.Context, url string) (*TokenRevocationStore, error) {
	opt, err := redis.ParseURL(url)
	if err != nil {
		return nil, err
	}
	client := redis.NewClient(opt)
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, err
	}
	return &TokenRevocationStore{client: client}, nil
}

func (s *TokenRevocationStore) Close() error { return s.client.Close() }

func (s *TokenRevocationStore) Revoke(ctx context.Context, tokenID string, ttl time.Duration) error {
	return s.client.Set(ctx, prefix+tokenID, "1", ttl).Err()
}

func (s *TokenRevocationStore) IsRevoked(ctx context.Context, tokenID string) (bool, error) {
	n, err := s.client.Exists(ctx, prefix+tokenID).Result()
	return n == 1, err
}
