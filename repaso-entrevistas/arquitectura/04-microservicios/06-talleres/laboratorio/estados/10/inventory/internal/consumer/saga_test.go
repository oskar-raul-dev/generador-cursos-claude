package consumer

import (
	"encoding/json"
	"testing"
)

// Pruebas unitarias (taller 10): lógica pura, sin base ni Kafka. Milisegundos.

func TestFactPointsToItsCause(t *testing.T) {
	cause := event{EventID: "11111111-1111-4111-8111-111111111111", Type: "OrderPlaced", OrderID: "22222222-2222-4222-8222-222222222222"}
	f := fact(cause, "InventoryReserved", "00-abc-def-01", map[string]any{"total": json.RawMessage(`{"amount":"9.90","currency":"USD"}`)})
	var body map[string]any
	if err := json.Unmarshal(f.Payload, &body); err != nil {
		t.Fatal(err)
	}
	if body["causationId"] != cause.EventID || body["orderId"] != cause.OrderID || f.Topic != TopicReservations {
		t.Fatalf("fact %+v body %v", f, body)
	}
	if f.ID == cause.EventID {
		t.Fatal("a new fact needs its own eventId")
	}
}

func TestItemsKeepsEveryLine(t *testing.T) {
	var ev event
	_ = json.Unmarshal([]byte(`{"lines":[{"sku":"SKU-001","quantity":1},{"sku":"SKU-002","quantity":3}]}`), &ev)
	got := items(ev)
	if len(got) != 2 || got[1].SKU != "SKU-002" || got[1].Qty != 3 {
		t.Fatalf("items = %+v", got)
	}
}
