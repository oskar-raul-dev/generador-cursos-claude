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
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"google.golang.org/grpc"

	inventoryv1 "ms.dev/inventory/gen/ms/inventory/v1"
	"ms.dev/inventory/internal/api"
	"ms.dev/inventory/internal/consumer"
	"ms.dev/inventory/internal/grpcapi"
	"ms.dev/inventory/internal/outbox"
	"ms.dev/inventory/internal/store"
	"ms.dev/inventory/internal/telemetry"
)

func main() {
	addr := flag.String("addr", ":28083", "dirección HTTP")
	grpcAddr := flag.String("grpc", ":28093", "dirección gRPC (taller 04)")
	detach := flag.Bool("detach-deadline", false, "provocación del taller 04: el trabajo ignora el deadline del cliente")
	rps := flag.Float64("rps", 0, "taller 05: límite de tasa del servidor gRPC, peticiones/s (0 = sin límite)")
	burst := flag.Int("burst", 20, "taller 05: ráfaga permitida por encima de la tasa")
	maxInflight := flag.Int("max-inflight", 0, "taller 05: peticiones gRPC en curso a la vez (0 = sin límite)")
	brokers := flag.String("kafka", "", "taller 06: brokers de Kafka (vacío = sin consumidor)")
	inbox := flag.Bool("inbox", true, "taller 06: deduplicar eventos en processed_messages")
	chaos := flag.String("chaos", "none", "taller 06: crash-after-effect")
	otlp := flag.String("otlp", "", "taller 07: collector OTLP/gRPC, host:puerto (vacío = sin trazas)")
	traceKafka := flag.Bool("trace-kafka", true, "taller 07: continuar la traza que llega en los encabezados del mensaje")
	dbURL := flag.String("db", os.Getenv("INVENTORY_DB_URL"), "URL de PostgreSQL (o INVENTORY_DB_URL)")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	shutdownTracing, err := telemetry.Setup(ctx, "inventory", *otlp)
	if err != nil {
		log.Fatalf("otel: %v", err)
	}
	defer shutdownTracing(context.Background())

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
	if *brokers != "" {
		go func() {
			if err := consumer.Run(ctx, st, consumer.Options{Brokers: strings.Split(*brokers, ","), Inbox: *inbox, Chaos: *chaos, TraceKafka: *traceKafka}); err != nil {
				log.Printf("consumer: %v", err)
			}
		}()
		go func() { // taller 08: inventory también publica (sus hechos de la saga), por su outbox
			if err := outbox.Run(ctx, pool, strings.Split(*brokers, ","), 200*time.Millisecond); err != nil {
				log.Printf("outbox: %v", err)
			}
		}()
	}
	lis, err := net.Listen("tcp", *grpcAddr)
	if err != nil {
		log.Fatalf("grpc listen: %v", err)
	}
	gs := grpc.NewServer(
		grpc.StatsHandler(otelgrpc.NewServerHandler()), // taller 07: un span por llamada, hijo del grpc-trace del cliente
		grpc.UnaryInterceptor(grpcapi.NewLimits(*rps, *burst, *maxInflight).Unary()),
	)
	inventoryv1.RegisterInventoryServiceServer(gs, grpcapi.New(st, *detach))
	go func() {
		log.Printf("inventory gRPC listening on %s (detach-deadline=%v rps=%v max-inflight=%d)", *grpcAddr, *detach, *rps, *maxInflight)
		if err := gs.Serve(lis); err != nil {
			log.Printf("grpc: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              *addr,
		Handler:           otelhttp.NewHandler(api.New(st), "inventory-http"), // taller 07
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
