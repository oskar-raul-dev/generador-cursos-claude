# Parte 2: cancelación con máquina de estados y liberación de la reserva.
# El archivo es autocontenido: crea su propio producto para no depender del stock que dejaron los
# archivos de v1.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@hex.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ops@hex.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

# Producto propio de este archivo, con 7 unidades.
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
Content-Type: application/json
{ "sku": "SKU-101", "name": "Cancel test item", "unitPrice": { "amount": "10.00", "currency": "USD" }, "stock": 7 }
HTTP 201

# Reservar 2: quedan 5.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-order-cancel
Content-Type: application/json
{ "lines": [ { "sku": "SKU-101", "quantity": 2 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"

GET {{base_url}}/api/v1/products/SKU-101
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 5

# Cancelar: CONFIRMED → CANCELLED y la reserva se libera en la misma transacción.
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{order_id}}"
jsonpath "$.status" == "CANCELLED"

GET {{base_url}}/api/v1/products/SKU-101
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 7

# Cancelar dos veces es idempotente: 200, sin liberar nada dos veces.
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

GET {{base_url}}/api/v1/products/SKU-101
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 7

# Un pedido cancelado no se paga.
POST {{base_url}}/api/v1/orders/{{order_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-pay-cancelled
HTTP 409
[Asserts]
jsonpath "$.code" == "ORDER_NOT_PAYABLE"

# Un pedido pagado no se cancela: la invariante vive en el agregado.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-order-paid
Content-Type: application/json
{ "lines": [ { "sku": "SKU-101", "quantity": 1 } ] }
HTTP 201
[Captures]
paid_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-pay-paid
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"

POST {{base_url}}/api/v1/orders/{{paid_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 409
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "ORDER_NOT_CANCELLABLE"

# El stock del pedido pagado sigue reservado: 7 - 1 = 6.
GET {{base_url}}/api/v1/products/SKU-101
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 6

# Un pedido con pago rechazado sí se cancela.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-order-rejected
Content-Type: application/json
{ "lines": [ { "sku": "SKU-005", "quantity": 1 } ] }
HTTP 201
[Captures]
rejected_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{rejected_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-06-pay-rejected
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_REJECTED"

POST {{base_url}}/api/v1/orders/{{rejected_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

# Cancelar un pedido inexistente.
POST {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000/cancel
Authorization: Bearer {{ana_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "ORDER_NOT_FOUND"

# Sin token, nada.
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
HTTP 401
