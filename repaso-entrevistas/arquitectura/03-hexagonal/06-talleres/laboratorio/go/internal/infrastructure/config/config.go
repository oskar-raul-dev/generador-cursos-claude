// Package config lee y valida la configuración al arrancar. Valores por defecto: §11 de la guía.
package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port        int
	Catalog     string // postgres | mongo
	DatabaseURL string
	MongoURL    string
	RedisURL    string
	JWTSecret   string
	JWTTTL      time.Duration
	OutboxPoll  time.Duration
	CORSOrigin  string
}

func Load() (Config, error) {
	c := Config{
		Port:        intEnv("PORT", 8083),
		Catalog:     env("HEX_CATALOG", "postgres"),
		DatabaseURL: env("DATABASE_URL", "postgres://hex:hex-lab-pass@localhost:15432/hex_orders"),
		MongoURL:    env("MONGO_URL", "mongodb://localhost:17017/hex_catalog"),
		RedisURL:    env("REDIS_URL", "redis://localhost:16379"),
		JWTSecret:   env("JWT_SECRET", "hex-lab-dev-secret-change-me-0123456789"),
		JWTTTL:      time.Duration(intEnv("JWT_TTL_SECONDS", 900)) * time.Second,
		OutboxPoll:  time.Duration(intEnv("OUTBOX_POLL_MS", 500)) * time.Millisecond,
		CORSOrigin:  env("CORS_ORIGIN", "http://localhost:5173"),
	}
	if c.Catalog != "postgres" && c.Catalog != "mongo" {
		return Config{}, fmt.Errorf("HEX_CATALOG must be postgres or mongo, was %q", c.Catalog)
	}
	if len(c.JWTSecret) < 32 {
		return Config{}, fmt.Errorf("JWT_SECRET must be at least 32 bytes for HS256")
	}
	return c, nil
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func intEnv(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}
