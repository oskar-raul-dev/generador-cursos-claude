# Copia de arquitectura/03-hexagonal/06-talleres/laboratorio/contrato/hurl/v1/04-orders.hurl, tomada el 2026-09-29
# (taller 04 del monolito). Única sustitución: @hex.local → @mono.local. No se edita a mano.
#
# Pedidos: reserva atómica, idempotencia por clave, visibilidad por actor.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ops@mono.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

# Sin Idempotency-Key no se crea nada: la clave es parte del contrato de un comando que cuesta dinero.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
HTTP 400
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"

# Forma inválida: un pedido sin líneas.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-empty-0001
Content-Type: application/json
{ "lines": [] }
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"

# Cantidad cero: también forma.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-zero-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 0 } ] }
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"

# SKU inexistente.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-unknown-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-999", "quantity": 1 } ] }
HTTP 404
[Asserts]
jsonpath "$.code" == "PRODUCT_NOT_FOUND"

# Inventario insuficiente en una línea: no se crea nada, ni siquiera la línea que sí tenía stock.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-nostock-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 1 }, { "sku": "SKU-004", "quantity": 1 } ] }
HTTP 409
[Asserts]
jsonpath "$.code" == "INSUFFICIENT_INVENTORY"
jsonpath "$.detail" contains "SKU-004"

# El stock de SKU-001 sigue intacto tras el fallo: 20 de la semilla.
GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 20

# Pedido válido: 2 × 49.90 + 1 × 9.90 = 109.70.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"
[Asserts]
header "Location" matches "/api/v1/orders/[0-9a-f-]{36}$"
jsonpath "$.status" == "CONFIRMED"
jsonpath "$.customerId" == "11111111-1111-4111-8111-111111111111"
jsonpath "$.lines" count == 2
jsonpath "$.lines[0].sku" == "SKU-001"
jsonpath "$.lines[0].name" == "Mechanical keyboard"
jsonpath "$.lines[0].quantity" == 2
jsonpath "$.lines[0].unitPrice.amount" == "49.90"
jsonpath "$.lines[0].lineTotal.amount" == "99.80"
jsonpath "$.total.amount" == "109.70"
jsonpath "$.total.currency" == "USD"
jsonpath "$.payment" == null

# La reserva descontó el stock.
GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# Misma clave, mismo cuerpo: la misma respuesta, marcada como repetición, sin reservar otra vez.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.id" == "{{order_id}}"
jsonpath "$.total.amount" == "109.70"

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# Misma clave, otro cuerpo: el cliente se equivocó y hay que decírselo.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 3 } ] }
HTTP 422
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REUSED"

# La dueña ve su pedido.
GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{order_id}}"
jsonpath "$.status" == "CONFIRMED"
jsonpath "$.createdAt" isString

# Sin token, nada.
GET {{base_url}}/api/v1/orders/{{order_id}}
HTTP 401

# Un operator ve cualquier pedido.
GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{ops_token}}
HTTP 200

# Un pedido que no existe.
GET {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000
Authorization: Bearer {{ana_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "ORDER_NOT_FOUND"

# Un id que ni siquiera es UUID es forma, no existencia.
GET {{base_url}}/api/v1/orders/not-a-uuid
Authorization: Bearer {{ana_token}}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"

# Listado, del más reciente al más antiguo: la dueña ve primero el que acaba de crear.
GET {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count >= 1
jsonpath "$.items[0].id" == "{{order_id}}"

# Y el operator, también.
GET {{base_url}}/api/v1/orders?limit=1
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
