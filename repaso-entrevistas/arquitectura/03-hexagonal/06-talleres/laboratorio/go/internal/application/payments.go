package application

import (
	"context"

	"hexorders/internal/domain"
)

type AuthorizePaymentResult struct {
	Order    *domain.Order
	Payment  domain.Payment
	Replayed bool
}

// AuthorizePayment: la llamada al proveedor queda FUERA de la transacción: una transacción
// abierta durante una llamada remota bloquea filas mientras espera a un tercero. Dos unidades
// de trabajo, con el proveedor entre ambas.
type AuthorizePayment struct {
	Orders      Orders
	Payments    Payments
	Gateway     PaymentGateway
	Idempotency IdempotencyStore
	UnitOfWork  UnitOfWork
}

func (uc AuthorizePayment) Execute(ctx context.Context, actor Actor, orderID, idempotencyKey string) (AuthorizePaymentResult, error) {
	requestHash := "payment:" + orderID

	// 1. Comprobar: repetición, existencia, visibilidad y estado pagable.
	var order *domain.Order
	replayed := false
	err := uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		stored, err := uc.Idempotency.Find(ctx, actor.ID, idempotencyKey)
		if err != nil {
			return err
		}
		if stored != nil {
			if stored.RequestHash != requestHash {
				return ErrIdempotencyKeyReused
			}
			replayed = true
			return nil
		}
		found, err := loadVisible(ctx, uc.Orders, actor, orderID)
		if err != nil {
			return err
		}
		if !found.IsPayable() {
			return domain.OrderNotPayable{Status: found.Status()}
		}
		order = found
		return nil
	})
	if err != nil {
		return AuthorizePaymentResult{}, err
	}
	if replayed {
		previous, err := loadVisible(ctx, uc.Orders, actor, orderID)
		if err != nil {
			return AuthorizePaymentResult{}, err
		}
		return AuthorizePaymentResult{Order: previous, Payment: *previous.Payment(), Replayed: true}, nil
	}

	// 2. Proveedor, sin transacción abierta. La clave del intento es la del cliente y no se regenera.
	payment, err := uc.Gateway.Authorize(ctx, idempotencyKey, order.Total())
	if err != nil {
		return AuthorizePaymentResult{}, err
	}

	// 3. Aplicar el resultado y guardar la clave con el efecto.
	var result AuthorizePaymentResult
	err = uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		current, err := loadVisible(ctx, uc.Orders, actor, orderID)
		if err != nil {
			return err
		}
		if err := current.ApplyPayment(payment); err != nil {
			return err
		}
		if err := uc.Orders.Save(ctx, current); err != nil {
			return err
		}
		if err := uc.Payments.Record(ctx, current.ID(), payment, current.Total()); err != nil {
			return err
		}
		if err := uc.Idempotency.Save(ctx, actor.ID, idempotencyKey, requestHash, 200, current.ID()); err != nil {
			return err
		}
		result = AuthorizePaymentResult{Order: current, Payment: payment}
		return nil
	})
	return result, err
}
