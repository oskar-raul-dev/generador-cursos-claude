# Suite v2 · 01 — la rama feliz de la saga: 202 + PENDING, y el pedido llega solo a PAID (taller 08).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# crear: 202, PENDING, Location. "Lo he apuntado", no "está hecho": aún no hay reserva ni pago.
POST {{base_url}}/api/v2/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-happy-0001
{ "lines": [ { "sku": "SKU-002", "quantity": 2 } ] }
HTTP 202
[Captures]
order_id: jsonpath "$.id"
[Asserts]
header "Location" == "/api/v2/orders/{{order_id}}"
jsonpath "$.status" == "PENDING"
jsonpath "$.total.amount" == "19.80"
jsonpath "$.payment" == null

# misma clave, mismo cuerpo → otra vez 202 con el mismo pedido, sin crear otro
POST {{base_url}}/api/v2/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-happy-0001
{ "lines": [ { "sku": "SKU-002", "quantity": 2 } ] }
HTTP 202
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.id" == "{{order_id}}"

# el cliente consulta hasta el estado final: hasta 10 s, cada 200 ms
GET {{base_url}}/api/v2/orders/{{order_id}}
Authorization: Bearer {{token}}
[Options]
retry: 50
retry-interval: 200ms
HTTP 200
[Asserts]
jsonpath "$.status" == "PAID"
jsonpath "$.payment.status" == "AUTHORIZED"
jsonpath "$.payment.operationId" == "saga-{{order_id}}"

# el stock bajó: 100 - 2
GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 98
