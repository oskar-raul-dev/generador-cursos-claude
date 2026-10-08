// Package postgres implementa los puertos de persistencia con pgx sobre el esquema compartido.
package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Querier es lo que tienen en común *pgxpool.Pool y pgx.Tx: ejecutar, consultar y consultar una fila.
type Querier interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

type txKey struct{}

// DB es el pool y, a la vez, el adaptador del puerto UnitOfWork. La transacción viaja en el
// context: Run la abre y la guarda; Q la devuelve si existe y el pool si no. Cada adaptador
// llama a Q(ctx) y no sabe si está dentro de una transacción. Es "usar tx, no db" del capítulo
// 05/04, con la elección centralizada en un solo sitio.
type DB struct{ Pool *pgxpool.Pool }

func Open(ctx context.Context, url string) (*DB, error) {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, err
	}
	return &DB{Pool: pool}, nil
}

func (d *DB) Q(ctx context.Context) Querier {
	if tx, ok := ctx.Value(txKey{}).(pgx.Tx); ok {
		return tx
	}
	return d.Pool
}

// Run ejecuta fn dentro de una transacción; si ya hay una en el contexto, la reutiliza.
// Cualquier error de fn revierte; el error de Commit no se oculta tras el Rollback diferido.
func (d *DB) Run(ctx context.Context, fn func(ctx context.Context) error) error {
	if _, ok := ctx.Value(txKey{}).(pgx.Tx); ok {
		return fn(ctx)
	}
	tx, err := d.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() {
		if rbErr := tx.Rollback(ctx); rbErr != nil && !errors.Is(rbErr, pgx.ErrTxClosed) {
			_ = rbErr // ya confirmada: el rollback tardío no es un error
		}
	}()
	if err := fn(context.WithValue(ctx, txKey{}, tx)); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func (d *DB) Close() { d.Pool.Close() }
