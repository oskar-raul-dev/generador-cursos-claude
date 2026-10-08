# Pedidos: reserva atómica y visibilidad por actor. Las peticiones llevan Idempotency-Key porque el
# contrato la exige; las aserciones de idempotencia (400 sin clave, repetición, 422) entran en el taller 07.

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

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# El dinero sale como decimal con dos cifras: 3 × 9.90 es 29.70, aunque por dentro siga siendo un
# double hasta el taller 05 (en hurl/legacy salía 29.700000000000003).
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-order-cables
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 3 } ] }
HTTP 201
[Captures]
cables_id: jsonpath "$.id"
[Asserts]
jsonpath "$.total.amount" == "29.70"
jsonpath "$.lines[0].lineTotal.amount" == "29.70"

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

# Listado, del más reciente al más antiguo: la dueña ve primero el último que creó.
GET {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count >= 2
jsonpath "$.items[0].id" == "{{cables_id}}"
jsonpath "$.items[1].id" == "{{order_id}}"

# Y el operator, también.
GET {{base_url}}/api/v1/orders?limit=1
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
