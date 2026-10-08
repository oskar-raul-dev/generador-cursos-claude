# Idempotencia (taller 07): lo que el contrato exigía desde el 04 con x-enforced-from y el legado
# ignoraba. Sin clave no se crea ni se cobra; la misma clave con el mismo cuerpo devuelve la misma
# respuesta sin repetir el efecto; con otro cuerpo, 422.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{ana_token}}
HTTP 200
[Captures]
stock_before: jsonpath "$.stock"

# Sin Idempotency-Key: 400 y nada cambia.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 400
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"

# Una clave demasiado corta es forma, no idempotencia.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: short
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"

GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{ana_token}}
HTTP 200
[Captures]
stock_after_create: jsonpath "$.stock"
[Asserts]
jsonpath "$.stock" < {{stock_before}}

# La repetición: 200, marcada, el mismo pedido y ninguna reserva nueva.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.id" == "{{order_id}}"

# Dos peticiones, una sola reserva: el stock sigue donde lo dejó la primera.
GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == {{stock_after_create}}

# La misma clave con otro cuerpo: el cliente se equivocó de clave.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 2 } ] }
HTTP 422
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REUSED"

# Pagar sin clave: 400.
POST {{base_url}}/api/v1/orders/{{order_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 400
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"

# Pagar: la clave es el operationId y viaja al proveedor.
POST {{base_url}}/api/v1/orders/{{order_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-pay-0001
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"
jsonpath "$.payment.operationId" == "suite-09-pay-0001"
jsonpath "$.payment.reference" startsWith "psp-"

# Repetir el pago con la misma clave: la misma respuesta, sin segundo cobro.
POST {{base_url}}/api/v1/orders/{{order_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-pay-0001
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.orderStatus" == "PAID"

# El pedido muestra el pago con su clave.
GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.payment.operationId" == "suite-09-pay-0001"
