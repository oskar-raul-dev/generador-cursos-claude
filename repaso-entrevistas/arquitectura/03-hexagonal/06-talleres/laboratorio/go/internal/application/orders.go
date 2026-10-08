package application

import (
	"context"
	"errors"

	"hexorders/internal/domain"
)

type LineRequest struct {
	SKU      string
	Quantity int
}

type CreateOrderCommand struct {
	Actor          Actor
	IdempotencyKey string
	RequestHash    string
	Lines          []LineRequest
}

type CreateOrderResult struct {
	Order    *domain.Order
	Replayed bool
}

// CreateOrder crea un pedido reservando el inventario de todas sus líneas, o nada. Una
// transacción rodea idempotencia, catálogo, pedido, reserva y clave: si algo falla después de
// descontar una línea, el descuento se revierte con el resto.
type CreateOrder struct {
	Products    Products
	Inventory   Inventory
	Orders      Orders
	Idempotency IdempotencyStore
	IDs         IDGenerator
	Clock       Clock
	UnitOfWork  UnitOfWork
}

func (uc CreateOrder) Execute(ctx context.Context, cmd CreateOrderCommand) (CreateOrderResult, error) {
	var result CreateOrderResult
	err := uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		actorID := cmd.Actor.ID
		stored, err := uc.Idempotency.Find(ctx, actorID, cmd.IdempotencyKey)
		if err != nil {
			return err
		}
		if stored != nil {
			if stored.RequestHash != cmd.RequestHash {
				return ErrIdempotencyKeyReused
			}
			previous, err := uc.Orders.Find(ctx, stored.Body)
			if err != nil {
				return err
			}
			if previous == nil {
				return errors.New("idempotency key points to a missing order " + stored.Body)
			}
			result = CreateOrderResult{Order: previous, Replayed: true}
			return nil
		}

		// Catálogo primero (404), inventario después (409): un SKU inexistente no deja reservas.
		lines := make([]domain.OrderLine, 0, len(cmd.Lines))
		for _, l := range cmd.Lines {
			p, err := uc.Products.Find(ctx, l.SKU)
			if err != nil {
				return err
			}
			if p == nil {
				return NotFound{Kind: "PRODUCT", ID: l.SKU}
			}
			lines = append(lines, domain.OrderLine{SKU: p.SKU, Name: p.Name, Quantity: l.Quantity, UnitPrice: p.UnitPrice})
		}

		order, err := domain.PlaceOrder(uc.IDs.Next(), actorID, lines, uc.Clock.Now())
		if err != nil {
			return err
		}
		if err := uc.Orders.Save(ctx, order); err != nil { // primero el pedido: las reservas lo referencian
			return err
		}
		if err := uc.Inventory.Reserve(ctx, order.ID(), lines); err != nil { // InsufficientInventory → rollback de todo
			return err
		}
		if err := uc.Idempotency.Save(ctx, actorID, cmd.IdempotencyKey, cmd.RequestHash, 201, order.ID()); err != nil {
			return err
		}
		result = CreateOrderResult{Order: order}
		return nil
	})
	return result, err
}

// GetOrder: un customer solo ve lo suyo; lo ajeno responde "no existe".
type GetOrder struct{ Orders Orders }

func (uc GetOrder) Execute(ctx context.Context, actor Actor, orderID string) (*domain.Order, error) {
	return loadVisible(ctx, uc.Orders, actor, orderID)
}

type ListOrders struct{ Orders Orders }

func (uc ListOrders) Execute(ctx context.Context, actor Actor, page PageRequest) (Page[*domain.Order], error) {
	customerID := actor.ID
	if actor.IsOperator() {
		customerID = "" // operator: todos
	}
	return uc.Orders.List(ctx, customerID, page)
}

func loadVisible(ctx context.Context, orders Orders, actor Actor, orderID string) (*domain.Order, error) {
	o, err := orders.Find(ctx, orderID)
	if err != nil {
		return nil, err
	}
	if o == nil || !actor.CanSee(o) {
		return nil, NotFound{Kind: "ORDER", ID: orderID}
	}
	return o, nil
}
