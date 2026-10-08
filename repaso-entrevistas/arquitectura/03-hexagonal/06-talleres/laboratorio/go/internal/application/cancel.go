package application

import (
	"context"

	"hexorders/internal/domain"
)

// CancelOrder (parte 2): el agregado decide si puede; aplicación coordina liberar la reserva y
// dejar el hecho en la outbox, todo en la misma transacción. La entrega ocurre después del commit.
type CancelOrder struct {
	Orders     Orders
	Inventory  Inventory
	Pending    PendingPublications
	IDs        IDGenerator
	Clock      Clock
	UnitOfWork UnitOfWork
}

func (uc CancelOrder) Execute(ctx context.Context, actor Actor, orderID string) (*domain.Order, error) {
	var order *domain.Order
	err := uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		o, err := loadVisible(ctx, uc.Orders, actor, orderID)
		if err != nil {
			return err
		}
		changed, err := o.Cancel(uc.Clock.Now(), uc.IDs.Next())
		if err != nil {
			return err
		}
		if changed {
			if err := uc.Inventory.Release(ctx, o.ID()); err != nil {
				return err
			}
			if err := uc.Orders.Save(ctx, o); err != nil {
				return err
			}
			for _, e := range o.PullEvents() {
				if err := uc.Pending.Add(ctx, e); err != nil {
					return err
				}
			}
		}
		order = o
		return nil
	})
	return order, err
}
