package application

import (
	"context"

	"hexorders/internal/domain"
)

// ListNotifications (parte 2): solo operator, una ventana operativa a lo que entregó el Notifier.
type ListNotifications struct{ Notifications Notifications }

func (uc ListNotifications) Execute(ctx context.Context, actor Actor, orderID string, page PageRequest) (Page[Notification], error) {
	if err := actor.RequireOperator(); err != nil {
		return Page[Notification]{}, err
	}
	return uc.Notifications.List(ctx, orderID, page)
}

// DeliverPendingPublications (parte 2): la política de entrega. Quién lo dispara (un ticker,
// una CLI) es infraestructura. Al menos una vez: si el proceso cae entre Notify y MarkPublished,
// la siguiente ronda repite la entrega y el Notifier debe tolerarlo.
type DeliverPendingPublications struct {
	Pending    PendingPublications
	Notifier   Notifier
	Users      Users
	UnitOfWork UnitOfWork
}

func (uc DeliverPendingPublications) Execute(ctx context.Context, batchSize int) (int, error) {
	delivered := 0
	err := uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		batch, err := uc.Pending.NextBatch(ctx, batchSize)
		if err != nil {
			return err
		}
		for _, e := range batch {
			recipient := "unknown"
			if cancelled, ok := e.(domain.OrderCancelled); ok {
				if user, err := uc.Users.FindByID(ctx, cancelled.Customer); err != nil {
					return err
				} else if user != nil {
					recipient = user.Email
				}
			}
			if err := uc.Notifier.Notify(ctx, e, recipient); err != nil {
				return err
			}
			if err := uc.Pending.MarkPublished(ctx, e.EventID()); err != nil {
				return err
			}
			delivered++
		}
		return nil
	})
	return delivered, err
}
