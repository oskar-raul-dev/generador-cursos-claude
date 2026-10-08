# Pagos: autorizado, rechazado y resultado incierto, decididos por el PaymentGateway determinista.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@hex.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

# Un pedido barato: 1 × 9.90.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-order-cheap
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
cheap_id: jsonpath "$.id"

# Pagar sin clave: no.
POST {{base_url}}/api/v1/orders/{{cheap_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 400
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"

# Pagar: 9.90 ≤ 1000.00 → autorizado y el pedido pasa a PAID.
POST {{base_url}}/api/v1/orders/{{cheap_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-cheap
HTTP 200
[Asserts]
jsonpath "$.orderId" == "{{cheap_id}}"
jsonpath "$.orderStatus" == "PAID"
jsonpath "$.payment.status" == "AUTHORIZED"
jsonpath "$.payment.operationId" == "suite-05-pay-cheap"

# El pedido lo refleja.
GET {{base_url}}/api/v1/orders/{{cheap_id}}
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "PAID"
jsonpath "$.payment.status" == "AUTHORIZED"

# Repetir el mismo intento (misma clave) devuelve el mismo resultado, no un segundo cobro.
POST {{base_url}}/api/v1/orders/{{cheap_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-cheap
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.payment.status" == "AUTHORIZED"

# Un intento nuevo (otra clave) sobre un pedido ya pagado es un conflicto de estado.
POST {{base_url}}/api/v1/orders/{{cheap_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-cheap-again
HTTP 409
[Asserts]
jsonpath "$.code" == "ORDER_NOT_PAYABLE"

# Un pedido caro: 1 × 1499.00 > 1000.00 → rechazado.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-order-expensive
Content-Type: application/json
{ "lines": [ { "sku": "SKU-005", "quantity": 1 } ] }
HTTP 201
[Captures]
expensive_id: jsonpath "$.id"
[Asserts]
jsonpath "$.total.amount" == "1499.00"

POST {{base_url}}/api/v1/orders/{{expensive_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-expensive
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_REJECTED"
jsonpath "$.payment.status" == "REJECTED"

# Un rechazo deja el pedido pagable otra vez: se puede reintentar con otra clave.
POST {{base_url}}/api/v1/orders/{{expensive_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-expensive-retry
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_REJECTED"

# El importe incierto: 3 × 222.00 = 666.00 → el proveedor "no respondió"; pendiente, nunca rechazado.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-order-uncertain
Content-Type: application/json
{ "lines": [ { "sku": "SKU-003", "quantity": 3 } ] }
HTTP 201
[Captures]
uncertain_id: jsonpath "$.id"
[Asserts]
jsonpath "$.total.amount" == "666.00"

POST {{base_url}}/api/v1/orders/{{uncertain_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-uncertain
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_PENDING"
jsonpath "$.payment.status" == "PENDING"

# Un pedido pendiente no acepta otro intento a ciegas: primero habría que consultar al proveedor.
POST {{base_url}}/api/v1/orders/{{uncertain_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-uncertain-again
HTTP 409
[Asserts]
jsonpath "$.code" == "ORDER_NOT_PAYABLE"

# Pagar un pedido inexistente.
POST {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-05-pay-ghost
HTTP 404
[Asserts]
jsonpath "$.code" == "ORDER_NOT_FOUND"
