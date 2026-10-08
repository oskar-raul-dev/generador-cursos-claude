// Package grpcapi expone inventory por gRPC (taller 04), con el mismo store que la API HTTP.
package grpcapi

import (
	"context"
	"fmt"
	"log"

	"google.golang.org/genproto/googleapis/rpc/errdetails"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	inventoryv1 "ms.dev/inventory/gen/ms/inventory/v1"
	"ms.dev/inventory/internal/store"
)

type Server struct {
	inventoryv1.UnimplementedInventoryServiceServer
	store *store.Store
	// detach reproduce el error del taller 04: el trabajo de base de datos se hace con un contexto
	// DESACOPLADO del de la llamada (context.WithoutCancel), así que el deadline del cliente no lo
	// detiene. Es lo que queda cuando alguien "arregla" los errores de cancelación en vez de entenderlos.
	detach bool
}

func New(s *store.Store, detach bool) *Server { return &Server{store: s, detach: detach} }

func (s *Server) work(ctx context.Context) context.Context {
	if s.detach {
		return context.WithoutCancel(ctx)
	}
	return ctx // el deadline que vino en la llamada llega hasta la consulta: pgx la cancela al vencer
}

func (s *Server) GetStock(ctx context.Context, req *inventoryv1.GetStockRequest) (*inventoryv1.GetStockResponse, error) {
	stock, err := s.store.Stock(s.work(ctx), req.GetSkus())
	if err != nil {
		return nil, toStatus(ctx, "GetStock", err)
	}
	res := &inventoryv1.GetStockResponse{}
	for _, sku := range req.GetSkus() {
		if n, ok := stock[sku]; ok {
			res.Levels = append(res.Levels, &inventoryv1.StockLevel{Sku: sku, OnHand: int32(n)})
		}
	}
	return res, nil
}

func (s *Server) Hold(ctx context.Context, req *inventoryv1.HoldRequest) (*inventoryv1.HoldResponse, error) {
	if err := ctx.Err(); err != nil { // el cliente ya se rindió: no gastes la base en esto
		return nil, status.FromContextError(err).Err()
	}
	items := make([]store.Item, 0, len(req.GetItems()))
	for _, it := range req.GetItems() {
		items = append(items, store.Item{SKU: it.GetSku(), Qty: int(it.GetQty())})
	}
	replay, err := s.store.Hold(s.work(ctx), req.GetReference(), items)
	if oos, ok := store.IsOutOfStock(err); ok {
		st := status.New(codes.FailedPrecondition, "out of stock")
		pf := &errdetails.PreconditionFailure{}
		for _, sh := range oos.Shortages {
			pf.Violations = append(pf.Violations, &errdetails.PreconditionFailure_Violation{
				Type: "OUT_OF_STOCK", Subject: sh.SKU,
				Description: fmt.Sprintf("requested %d, on hand %d", sh.Requested, sh.OnHand),
			})
		}
		// el stock en mano de cada SKU, como dato y no como texto: ErrorInfo con metadata por SKU
		info := &errdetails.ErrorInfo{Reason: "OUT_OF_STOCK", Domain: "inventory.ms.dev", Metadata: map[string]string{}}
		for _, sh := range oos.Shortages {
			info.Metadata[sh.SKU] = fmt.Sprintf("%d", sh.OnHand)
		}
		withDetails, derr := st.WithDetails(pf, info)
		if derr != nil {
			return nil, st.Err()
		}
		return nil, withDetails.Err()
	}
	if err != nil {
		return nil, toStatus(ctx, "Hold", err)
	}
	if ctx.Err() != nil { // la retención se hizo, pero el cliente ya no escucha: queda como huérfana
		log.Printf("Hold %s: done AFTER the caller gave up (%v)", req.GetReference(), ctx.Err())
	}
	return &inventoryv1.HoldResponse{Reference: req.GetReference(), Replay: replay}, nil
}

func (s *Server) Release(ctx context.Context, req *inventoryv1.ReleaseRequest) (*inventoryv1.ReleaseResponse, error) {
	n, err := s.store.Release(s.work(ctx), req.GetReference())
	if err != nil {
		return nil, toStatus(ctx, "Release", err)
	}
	return &inventoryv1.ReleaseResponse{Released: int32(n)}, nil
}

func (s *Server) Commit(ctx context.Context, req *inventoryv1.CommitRequest) (*inventoryv1.CommitResponse, error) {
	n, err := s.store.Commit(s.work(ctx), req.GetReference())
	if err != nil {
		return nil, toStatus(ctx, "Commit", err)
	}
	return &inventoryv1.CommitResponse{Committed: int32(n)}, nil
}

// toStatus: si el contexto de la llamada venció o se canceló, ese es el código (DEADLINE_EXCEEDED,
// CANCELLED); cualquier otra cosa es INTERNAL, y se registra.
func toStatus(ctx context.Context, rpc string, err error) error {
	if ctx.Err() != nil {
		log.Printf("%s: %v (caller: %v)", rpc, err, ctx.Err())
		return status.FromContextError(ctx.Err()).Err()
	}
	log.Printf("%s: %v", rpc, err)
	return status.Error(codes.Internal, "internal error")
}
