// G10 (Fase 23): pricing atiende el precio también por gRPC, en el 9090, con el mismo mTLS del 8443 (los mismos
// certificados, que se releen solos). Es la llamada que inventory hace en cada venta, ahora en binario y por
// HTTP/2. Cada llamada se cuenta y se loguea como las HTTP, para que la Fase 23 pueda ver a qué réplica llegó.
package main

import (
	"context"
	"crypto/tls"
	"database/sql"
	"errors"
	"log/slog"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"lab/pricing/pricingv1"
)

// grpcRequests cuenta las llamadas gRPC por método y por código: con una réplica por línea en Prometheus, es la
// evidencia de B-23 (a qué réplica llega cada llamada).
var grpcRequests = promauto.NewCounterVec(prometheus.CounterOpts{
	Name: "grpc_server_requests_total",
	Help: "Llamadas gRPC atendidas, por método y por código.",
}, []string{"method", "code"})

type pricingGRPC struct {
	pricingv1.UnimplementedPricingServer
	s *server
}

func (g *pricingGRPC) GetPrice(ctx context.Context, req *pricingv1.GetPriceRequest) (*pricingv1.Price, error) {
	if !skuPattern.MatchString(req.GetSku()) || !storePattern.MatchString(req.GetStore()) {
		return nil, status.Error(codes.InvalidArgument, "se esperan sku (SKU-0000) y store (DRO-000)")
	}
	var stored int
	err := g.s.db.QueryRowContext(ctx, `SELECT price FROM prices WHERE sku = $1 AND store = $2`,
		req.GetSku(), req.GetStore()).Scan(&stored)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, status.Error(codes.NotFound, "sin precio para "+req.GetSku()+" en "+req.GetStore())
	}
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	p := g.s.view(req.GetSku(), req.GetStore(), stored)
	out := &pricingv1.Price{Sku: p.Sku, Store: p.Store, Price: int64(p.Price), Currency: p.Currency, Capped: p.Capped}
	if p.RegulatedCap != nil {
		v := int64(*p.RegulatedCap)
		out.RegulatedCap = &v
	}
	return out, nil
}

// observe es el interceptor de cada llamada: la cuenta, y la misma línea "request" de G7, con el x-request-id
// que inventory manda en los metadatos.
func observe(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	start := time.Now()
	resp, err := handler(ctx, req)
	code := status.Code(err)
	grpcRequests.WithLabelValues(info.FullMethod, code.String()).Inc()
	requestID := ""
	if md, ok := metadata.FromIncomingContext(ctx); ok && len(md.Get("x-request-id")) > 0 {
		requestID = md.Get("x-request-id")[0]
	}
	slog.Info("request", "method", "GRPC", "uri", info.FullMethod, "path", info.FullMethod, "status", code.String(),
		"duration_ms", float64(time.Since(start).Microseconds())/1000, "request_id", requestID, "trace_id", traceID(ctx))
	return resp, err
}

// grpcServer arma el servidor del 9090 con el mismo tls.Config del 8443 (tls.go). Sin certificados, no hay gRPC.
func grpcServer(s *server, tlsConfig *tls.Config) *grpc.Server {
	if tlsConfig == nil {
		return nil
	}
	opts := []grpc.ServerOption{grpc.Creds(credentials.NewTLS(tlsConfig)), grpc.UnaryInterceptor(observe),
		grpc.StatsHandler(otelgrpc.NewServerHandler())} // G10: un span por llamada, con el traceparent de los metadatos
	// GRPC_MAX_CONNECTION_AGE (p. ej. "10s") cierra cada conexión al cumplir esa edad, con GOAWAY: el cliente se
	// reconecta, y el Service normal elige otra réplica. Es la alternativa del lado del servidor que mide B-23.
	if age, err := time.ParseDuration(os.Getenv("GRPC_MAX_CONNECTION_AGE")); err == nil && age > 0 {
		opts = append(opts, grpc.KeepaliveParams(keepalive.ServerParameters{MaxConnectionAge: age, MaxConnectionAgeGrace: 5 * time.Second}))
	}
	srv := grpc.NewServer(opts...)
	pricingv1.RegisterPricingServer(srv, &pricingGRPC{s: s})
	return srv
}

func grpcPort() string {
	if port := os.Getenv("GRPC_PORT"); port != "" {
		return port
	}
	return "9090" // el contrato fija 9090 para gRPC
}
