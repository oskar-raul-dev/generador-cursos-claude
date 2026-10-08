# Suite v1 · 04 — crear pedidos reserva stock en el mismo acto (contrato síncrono heredado).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# crear: 201, CONFIRMED (stock reservado, sin pagar), Location y total calculado
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"
[Asserts]
header "Location" == "/api/v1/orders/{{order_id}}"
jsonpath "$.status" == "CONFIRMED"
jsonpath "$.customerId" == "11111111-1111-4111-8111-111111111111"
jsonpath "$.lines" count == 2
jsonpath "$.lines[0].name" == "Mechanical keyboard"
jsonpath "$.lines[0].lineTotal.amount" == "99.80"
jsonpath "$.total.amount" == "109.70"
jsonpath "$.payment" == null

# el stock ya bajó: 20 - 2
GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# misma clave, mismo cuerpo → 200 con el pedido original, sin crear otro
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.id" == "{{order_id}}"

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# misma clave, otro cuerpo → 422
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 3 } ] }
HTTP 422
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REUSED"

# sin clave → 400
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
HTTP 400
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"

# sin stock → 409 y no se crea nada
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0002
{ "lines": [ { "sku": "SKU-001", "quantity": 1 }, { "sku": "SKU-004", "quantity": 1 } ] }
HTTP 409
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "INSUFFICIENT_INVENTORY"
jsonpath "$.errors[0].field" == "lines[1].quantity"

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# producto inexistente → 404
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0003
{ "lines": [ { "sku": "SKU-999", "quantity": 1 } ] }
HTTP 404
[Asserts]
jsonpath "$.code" == "PRODUCT_NOT_FOUND"

# cuerpo inválido → 400
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-order-0004
{ "lines": [] }
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"

# leer el pedido y la lista propia
GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{order_id}}"
jsonpath "$.status" == "CONFIRMED"

GET {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.items[0].id" == "{{order_id}}"

# otro cliente no ve el pedido: 404, no 403. El operador sí.
POST {{base_url}}/api/v1/auth/login
{ "email": "ops@ms.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.customerId" == "11111111-1111-4111-8111-111111111111"

GET {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000
Authorization: Bearer {{token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "ORDER_NOT_FOUND"
