package domain

import (
	"errors"
	"testing"
	"time"
)

// Pruebas del agregado sin frameworks ni dobles: la máquina de estados del contrato.
var now = time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC)

const ana = "11111111-1111-4111-8111-111111111111"

func order(t *testing.T, amount string) *Order {
	t.Helper()
	o, err := PlaceOrder("o-1", ana, []OrderLine{{SKU: "SKU-001", Name: "Mechanical keyboard", Quantity: 1, UnitPrice: MustUSD(amount)}}, now)
	if err != nil {
		t.Fatal(err)
	}
	return o
}

func TestPlaceOrderRejectsEmpty(t *testing.T) {
	if _, err := PlaceOrder("o-1", ana, nil, now); !errors.Is(err, ErrEmptyOrder) {
		t.Fatalf("want ErrEmptyOrder, got %v", err)
	}
}

func TestPlaceOrderTotalsWithoutFloats(t *testing.T) {
	o, err := PlaceOrder("o-1", ana, []OrderLine{
		{SKU: "SKU-001", Name: "Mechanical keyboard", Quantity: 2, UnitPrice: MustUSD("49.90")},
		{SKU: "SKU-002", Name: "USB-C cable", Quantity: 1, UnitPrice: MustUSD("9.90")},
	}, now)
	if err != nil {
		t.Fatal(err)
	}
	if o.Status() != StatusConfirmed || o.Total().Text() != "109.70" {
		t.Fatalf("got %s %s", o.Status(), o.Total().Text())
	}
}

func TestPaidIsNeitherPayableNorCancellable(t *testing.T) {
	o := order(t, "9.90")
	if err := o.ApplyPayment(Payment{Status: PaymentAuthorized, OperationID: "op-1", Reference: "gw"}); err != nil {
		t.Fatal(err)
	}
	if o.Status() != StatusPaid {
		t.Fatalf("got %s", o.Status())
	}
	var notPayable OrderNotPayable
	if err := o.ApplyPayment(Payment{Status: PaymentAuthorized, OperationID: "op-2"}); !errors.As(err, &notPayable) {
		t.Fatalf("want OrderNotPayable, got %v", err)
	}
	var notCancellable OrderNotCancellable
	if _, err := o.Cancel(now, "e-1"); !errors.As(err, &notCancellable) {
		t.Fatalf("want OrderNotCancellable, got %v", err)
	}
}

func TestRejectedStaysPayablePendingDoesNot(t *testing.T) {
	rejected := order(t, "1499.00")
	_ = rejected.ApplyPayment(Payment{Status: PaymentRejected, OperationID: "op-1"})
	if !rejected.IsPayable() {
		t.Fatal("rejected must stay payable")
	}
	pending := order(t, "666.00")
	_ = pending.ApplyPayment(Payment{Status: PaymentPending, OperationID: "op-2"})
	if pending.IsPayable() || !pending.IsCancellable() {
		t.Fatal("pending must not be payable but must be cancellable")
	}
}

func TestCancelIsIdempotentAndEmitsOnce(t *testing.T) {
	o := order(t, "9.90")
	if changed, _ := o.Cancel(now, "e-1"); !changed || len(o.PullEvents()) != 1 {
		t.Fatal("first cancel must change and emit once")
	}
	if changed, _ := o.Cancel(now, "e-2"); changed || len(o.PullEvents()) != 0 {
		t.Fatal("second cancel must be a no-op")
	}
}
