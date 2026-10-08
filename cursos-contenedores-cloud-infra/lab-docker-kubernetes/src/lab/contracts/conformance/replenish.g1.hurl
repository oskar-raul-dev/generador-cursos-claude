# Suite de conformidad · replenish · paso G1 (Fase 09)
# Una orden no se edita: se cancela con su código y se crea otra que la reemplaza. Cada corrida crea las suyas.

GET {{replenish}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

# Un préstamo de Girón (DRO-003) a Chapinero (DRO-007), con la cantidad equivocada.
POST {{replenish}}/replenishment-orders
{"sku": "SKU-0003", "destinationStore": "DRO-007", "originStore": "DRO-003", "quantity": 20}
HTTP 201
[Captures]
wrong: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "PENDING"
jsonpath "$.originStore" == "DRO-003"

GET {{replenish}}/replenishment-orders/{{wrong}}
HTTP 200

# Reemplazar una orden que no está cancelada no se acepta.
POST {{replenish}}/replenishment-orders
{"sku": "SKU-0003", "destinationStore": "DRO-007", "originStore": "DRO-003", "quantity": 2, "replacesOrderId": "{{wrong}}"}
HTTP 422

# Cancelar exige un código que exista.
POST {{replenish}}/replenishment-orders/{{wrong}}/cancel
{"reasonCode": "NO_EXISTE"}
HTTP 422

POST {{replenish}}/replenishment-orders/{{wrong}}/cancel
{"reasonCode": "WRONG_QUANTITY", "note": "eran 2, no 20"}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"
jsonpath "$.cancelReasonCode" == "WRONG_QUANTITY"

# Lo que no está en PENDING no se cancela.
POST {{replenish}}/replenishment-orders/{{wrong}}/cancel
{"reasonCode": "WRONG_QUANTITY"}
HTTP 409

# La orden correcta, que reemplaza a la cancelada.
POST {{replenish}}/replenishment-orders
{"sku": "SKU-0003", "destinationStore": "DRO-007", "originStore": "DRO-003", "quantity": 2, "replacesOrderId": "{{wrong}}"}
HTTP 201
[Asserts]
jsonpath "$.replacesOrderId" == "{{wrong}}"

GET {{replenish}}/replenishment-orders
HTTP 200
[Asserts]
jsonpath "$[*].id" contains "{{wrong}}"

GET {{replenish}}/replenishment-orders/RO-9999
HTTP 404

GET {{replenish}}/reason-codes
HTTP 200
[Asserts]
jsonpath "$" count == 4

# Lo que todavía no existe: las métricas (G6).
GET {{replenish}}/metrics
HTTP 404
