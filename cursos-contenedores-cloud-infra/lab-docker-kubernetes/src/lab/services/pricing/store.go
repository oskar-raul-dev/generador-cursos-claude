package main

import (
	"database/sql"
	"os"
	"path/filepath"

	_ "github.com/jackc/pgx/v5/stdlib" // Postgres en Go puro (G3): sin cgo, el binario sigue siendo estático
	_ "modernc.org/sqlite"             // SQLite en Go puro (G1): el almacén cuando no hay DATABASE_URL
)

// migrations es el esquema, en orden. Cada una es idempotente: correr el Job dos veces no rompe nada.
// El SQL es el subconjunto que entienden los dos motores (y los parámetros van como $1, $2…).
var migrations = []string{
	`CREATE TABLE IF NOT EXISTS prices (
		sku   TEXT    NOT NULL,
		store TEXT    NOT NULL,
		price INTEGER NOT NULL CHECK (price >= 0),
		PRIMARY KEY (sku, store))`,
}

// openStore abre Postgres si hay DATABASE_URL (G3); si no, el SQLite de DATA_DIR (G1), que sigue
// siendo el de compose. Devuelve también el nombre del motor, para el log.
func openStore() (*sql.DB, string, error) {
	if url := os.Getenv("DATABASE_URL"); url != "" {
		db, err := sql.Open("pgx", url)
		return db, "postgres", err
	}
	dir := os.Getenv("DATA_DIR")
	if dir == "" {
		dir = "/var/lib/pricing"
	}
	db, err := sql.Open("sqlite", filepath.Join(dir, "pricing.db")+"?_pragma=busy_timeout(5000)")
	if err != nil {
		return nil, "", err
	}
	db.SetMaxOpenConns(1) // SQLite escribe de a uno
	return db, "sqlite", nil
}

// migrate aplica las migraciones en orden.
func migrate(db *sql.DB) error {
	for _, m := range migrations {
		if _, err := db.Exec(m); err != nil {
			return err
		}
	}
	return nil
}
