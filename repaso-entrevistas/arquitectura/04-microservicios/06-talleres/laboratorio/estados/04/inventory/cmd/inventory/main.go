// inventory: el primer servicio extraído del monolito (taller 02). Go, biblioteca estándar más pgx.
package main

import (
	"context"
	"errors"
	"flag"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/grpc"

	inventoryv1 "ms.dev/inventory/gen/ms/inventory/v1"
	"ms.dev/inventory/internal/api"
	"ms.dev/inventory/internal/grpcapi"
	"ms.dev/inventory/internal/store"
)

func main() {
	addr := flag.String("addr", ":28083", "dirección HTTP")
	grpcAddr := flag.String("grpc", ":28093", "dirección gRPC (taller 04)")
	detach := flag.Bool("detach-deadline", false, "provocación del taller 04: el trabajo ignora el deadline del cliente")
	dbURL := flag.String("db", os.Getenv("INVENTORY_DB_URL"), "URL de PostgreSQL (o INVENTORY_DB_URL)")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := pgxpool.ParseConfig(*dbURL)
	if err != nil {
		log.Fatalf("db url: %v", err)
	}
	cfg.MaxConns = 10 // pgxpool pone por defecto max(4, núcleos); se fija a mano para que el límite sea una decisión escrita
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("db: %v", err)
	}
	defer pool.Close()
	if err := store.Migrate(ctx, pool); err != nil {
		log.Fatalf("migrate: %v", err)
	}
	log.Printf("schema applied on %s/%s", cfg.ConnConfig.Host, cfg.ConnConfig.Database)

	st := store.New(pool)
	lis, err := net.Listen("tcp", *grpcAddr)
	if err != nil {
		log.Fatalf("grpc listen: %v", err)
	}
	gs := grpc.NewServer()
	inventoryv1.RegisterInventoryServiceServer(gs, grpcapi.New(st, *detach))
	go func() {
		log.Printf("inventory gRPC listening on %s (detach-deadline=%v)", *grpcAddr, *detach)
		if err := gs.Serve(lis); err != nil {
			log.Printf("grpc: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              *addr,
		Handler:           api.New(st),
		ReadHeaderTimeout: 2 * time.Second, // nada de conexiones colgadas en la cabecera
	}
	go func() {
		<-ctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = srv.Shutdown(shutdown) // apagado ordenado: termina lo que está en curso (01/05)
		gs.GracefulStop()
	}()
	log.Printf("inventory listening on %s", *addr)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("http: %v", err)
	}
}
