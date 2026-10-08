// Package payment: el proveedor de pagos de las partes 1–3, la regla determinista de §11.
package payment

import (
	"context"

	"hexorders/internal/domain"
)

type Deterministic struct{}

func (Deterministic) Authorize(_ context.Context, operationID string, amount domain.Money) (domain.Payment, error) {
	if amount.GreaterThan(domain.MustUSD("1000.00")) {
		return domain.Payment{Status: domain.PaymentRejected, OperationID: operationID}, nil
	}
	if amount.HasAmount("666.00") {
		return domain.Payment{Status: domain.PaymentPending, OperationID: operationID}, nil // el proveedor "no respondió"
	}
	return domain.Payment{Status: domain.PaymentAuthorized, OperationID: operationID, Reference: "gw-" + operationID}, nil
}
