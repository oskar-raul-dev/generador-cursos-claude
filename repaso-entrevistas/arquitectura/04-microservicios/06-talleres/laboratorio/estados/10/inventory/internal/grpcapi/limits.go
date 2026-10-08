package grpcapi

import (
	"context"
	"log"
	"sync/atomic"

	"golang.org/x/time/rate"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Limits es la resiliencia de QUIEN RECIBE (taller 05): un límite de tasa (token bucket) y un límite
// de peticiones en vuelo (bulkhead con semáforo). Lo que no cabe se rechaza AL INSTANTE con
// RESOURCE_EXHAUSTED, antes de tocar la base: rechazar pronto es barato, aceptar y colapsar no.
// Go no trae nada de esto hecho; son veinte líneas con golang.org/x/time/rate y un canal.
type Limits struct {
	limiter  *rate.Limiter
	inflight chan struct{}
	rejected atomic.Int64
}

// NewLimits: rps <= 0 desactiva el límite de tasa; maxInflight <= 0 desactiva el de concurrencia.
func NewLimits(rps float64, burst, maxInflight int) *Limits {
	l := &Limits{}
	if rps > 0 {
		l.limiter = rate.NewLimiter(rate.Limit(rps), burst)
	}
	if maxInflight > 0 {
		l.inflight = make(chan struct{}, maxInflight)
	}
	return l
}

func (l *Limits) Unary() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, next grpc.UnaryHandler) (any, error) {
		if l.limiter != nil && !l.limiter.Allow() { // sin esperar: Allow, no Wait
			l.reject(info.FullMethod, "rate")
			return nil, status.Error(codes.ResourceExhausted, "rate limit exceeded")
		}
		if l.inflight != nil {
			select {
			case l.inflight <- struct{}{}:
				defer func() { <-l.inflight }()
			default: // lleno: no se encola
				l.reject(info.FullMethod, "inflight")
				return nil, status.Error(codes.ResourceExhausted, "too many requests in flight")
			}
		}
		return next(ctx, req)
	}
}

func (l *Limits) reject(method, why string) {
	if n := l.rejected.Add(1); n == 1 || n%50 == 0 {
		log.Printf("limits: rejected %d so far (last: %s, %s)", n, method, why)
	}
}
