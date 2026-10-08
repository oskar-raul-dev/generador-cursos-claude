package consumer

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// El contrato de inventory como CONSUMIDOR de OrderPaid (taller 10). Dos cosas en un test:
//  1. el ejemplo pasa por el MISMO camino que un mensaje real (event + items) y da lo esperado;
//  2. se escribe contrato/pacts/inventory-orders.json con lo que inventory LEE, y solo eso, para que
//     orders lo verifique en su pipeline.
//
// pact-go haría el paso 2 con su DSL, pero necesita una biblioteca nativa instalada en el sistema; el
// formato del pacto (Pact v3, mensajes) es JSON y se escribe a mano sin perder nada.
const orderPaidExample = `{
  "eventId": "8c1f4a52-2d0e-4c55-9d3a-6a0f3f0b9e11",
  "type": "OrderPaid",
  "orderId": "5f1c2a4e-0000-4000-8000-000000000001",
  "lines": [ { "sku": "SKU-002", "quantity": 2 } ]
}`

const uuidRegex = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

func TestOrderPaidContract(t *testing.T) {
	var ev event
	if err := json.Unmarshal([]byte(orderPaidExample), &ev); err != nil {
		t.Fatalf("inventory cannot read its own example: %v", err)
	}
	got := items(ev)
	if ev.Type != "OrderPaid" || len(got) != 1 || got[0].SKU != "SKU-002" || got[0].Qty != 2 {
		t.Fatalf("decoded %+v → %+v", ev, got)
	}

	var contents map[string]any
	_ = json.Unmarshal([]byte(orderPaidExample), &contents)
	match := func(rule map[string]any) map[string]any { return map[string]any{"matchers": []any{rule}} }
	pact := map[string]any{
		"consumer": map[string]any{"name": "inventory"},
		"provider": map[string]any{"name": "orders"},
		"messages": []any{map[string]any{
			"description":    "an OrderPaid event",
			"providerStates": []any{map[string]any{"name": "an order has been paid"}},
			"contents":       contents,
			"metaData":       map[string]any{"contentType": "application/json"},
			// la forma de lo que inventory lee: tipos y patrones, no los valores del ejemplo
			"matchingRules": map[string]any{"body": map[string]any{
				"$.eventId":           match(map[string]any{"match": "regex", "regex": uuidRegex}),
				"$.type":              match(map[string]any{"match": "regex", "regex": "^OrderPaid$"}),
				"$.orderId":           match(map[string]any{"match": "regex", "regex": uuidRegex}),
				"$.lines":             match(map[string]any{"match": "type", "min": 1}),
				"$.lines[*].sku":      match(map[string]any{"match": "type"}),
				"$.lines[*].quantity": match(map[string]any{"match": "integer"}),
			}},
		}},
		"metadata": map[string]any{"pactSpecification": map[string]any{"version": "3.0.0"}},
	}
	out, _ := json.MarshalIndent(pact, "", "  ")
	dir := filepath.Join("..", "..", "..", "contrato", "pacts")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "inventory-orders.json"), append(out, '\n'), 0o644); err != nil {
		t.Fatal(err)
	}
}
