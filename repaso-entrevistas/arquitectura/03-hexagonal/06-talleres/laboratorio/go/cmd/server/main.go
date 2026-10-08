// Composition root del sabor Go. main abre los recursos, construye los adaptadores, los enchufa
// a los casos de uso y arranca el servidor y el dispatcher. Es el único lugar que conoce a la vez
// los casos de uso y las implementaciones, y el dueño del cierre: lo que aquí se abre, aquí se cierra.
package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"hexorders/internal/application"
	"hexorders/internal/infrastructure/config"
	"hexorders/internal/infrastructure/inbound/httpin"
	"hexorders/internal/infrastructure/outbound/mongocatalog"
	"hexorders/internal/infrastructure/outbound/notification"
	"hexorders/internal/infrastructure/outbound/payment"
	"hexorders/internal/infrastructure/outbound/postgres"
	"hexorders/internal/infrastructure/outbound/redisstore"
	"hexorders/internal/infrastructure/outbound/security"
)

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now() }

type randomIDs struct{}

// UUID v4 con crypto/rand: sin dependencia externa para un identificador.
func (randomIDs) Next() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	h := hex.EncodeToString(b)
	return h[0:8] + "-" + h[8:12] + "-" + h[12:16] + "-" + h[16:20] + "-" + h[20:32]
}

func main() {
	if err := run(); err != nil {
		slog.Error("fatal", "err", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// ---------------------------------------------------------------- recursos
	db, err := postgres.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()
	revocations, err := redisstore.Open(ctx, cfg.RedisURL)
	if err != nil {
		return err
	}
	defer revocations.Close()

	// ---------------------------------------------------------------- el catálogo: parte 3
	// Un solo valor Products; qué implementación depende de HEX_CATALOG. El resto del grafo no se entera.
	var products application.Products = postgres.Products{DB: db}
	if cfg.Catalog == "mongo" {
		mongoProducts, err := mongocatalog.Open(ctx, cfg.MongoURL)
		if err != nil {
			return err
		}
		defer mongoProducts.Close(context.Background())
		products = mongoProducts
	}

	// ---------------------------------------------------------------- adaptadores y casos de uso
	clock := systemClock{}
	ids := randomIDs{}
	jwt := security.NewJWT(cfg.JWTSecret, cfg.JWTTTL, clock)
	inventory := postgres.Inventory{DB: db}
	orders := postgres.Orders{DB: db}
	idempotency := postgres.IdempotencyStore{DB: db}
	pending := postgres.PendingPublications{DB: db}
	users := postgres.Users{DB: db}

	deliver := application.DeliverPendingPublications{Pending: pending, Notifier: postgres.TableNotifier{DB: db}, Users: users, UnitOfWork: db}
	handler := httpin.NewHandler(httpin.Deps{
		Login:             application.Login{Users: users, Hasher: security.Bcrypt{}, Tokens: jwt},
		Logout:            application.Logout{Revocations: revocations, Clock: clock},
		ListProducts:      application.ListProducts{Products: products, Inventory: inventory},
		GetProduct:        application.GetProduct{Products: products, Inventory: inventory},
		CreateProduct:     application.CreateProduct{Products: products, Inventory: inventory, UnitOfWork: db},
		CreateOrder:       application.CreateOrder{Products: products, Inventory: inventory, Orders: orders, Idempotency: idempotency, IDs: ids, Clock: clock, UnitOfWork: db},
		GetOrder:          application.GetOrder{Orders: orders},
		ListOrders:        application.ListOrders{Orders: orders},
		AuthorizePayment:  application.AuthorizePayment{Orders: orders, Payments: postgres.Payments{DB: db}, Gateway: payment.Deterministic{}, Idempotency: idempotency, UnitOfWork: db},
		CancelOrder:       application.CancelOrder{Orders: orders, Inventory: inventory, Pending: pending, IDs: ids, Clock: clock, UnitOfWork: db},
		ListNotifications: application.ListNotifications{Notifications: postgres.Notifications{DB: db}},
		Verifier:          jwt,
		Revocations:       revocations,
		CORSOrigin:        cfg.CORSOrigin,
	})

	// ---------------------------------------------------------------- arranque y cierre ordenado
	go notification.Dispatcher{Deliver: deliver, Interval: cfg.OutboxPoll}.Run(ctx)

	server := &http.Server{Addr: ":" + strconv.Itoa(cfg.Port), Handler: handler, ReadHeaderTimeout: 5 * time.Second}
	errs := make(chan error, 1)
	go func() { errs <- server.ListenAndServe() }()
	slog.Info("hex-orders-go listening", "port", cfg.Port, "catalog", cfg.Catalog)

	select {
	case err := <-errs:
		return err
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil && !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	}
}
