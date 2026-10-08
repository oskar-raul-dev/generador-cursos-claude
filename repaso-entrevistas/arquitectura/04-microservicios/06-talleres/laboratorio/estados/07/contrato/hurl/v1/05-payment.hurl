# Suite v1 · 05 — pagar: autorizado, rechazado e incierto, según la regla del psp-simulator.
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# autorizado → PAID
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-order-0001
{ "lines": [ { "sku": "SKU-002", "quantity": 2 } ] }
HTTP 201
[Captures]
paid_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-0001
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"
jsonpath "$.payment.status" == "AUTHORIZED"
jsonpath "$.payment.operationId" == "suite-v1-pay-0001"
jsonpath "$.payment.reference" isString

# repetir el mismo intento → la misma respuesta, sin cobrar otra vez
POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-0001
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.orderStatus" == "PAID"

# un intento nuevo sobre un pedido pagado → 409
POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-0002
HTTP 409
[Asserts]
jsonpath "$.code" == "ORDER_NOT_PAYABLE"

# total > 1000.00 → PAYMENT_REJECTED, y el stock vuelve
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-order-0002
{ "lines": [ { "sku": "SKU-005", "quantity": 1 } ] }
HTTP 201
[Captures]
rejected_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{rejected_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-0003
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_REJECTED"
jsonpath "$.payment.status" == "REJECTED"

GET {{base_url}}/api/v1/products/SKU-005
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 3

# total == 666.00 → el proveedor tarda más que el timeout: PAYMENT_PENDING, nunca rechazo
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-order-0003
{ "lines": [ { "sku": "SKU-003", "quantity": 3 } ] }
HTTP 201
[Captures]
pending_id: jsonpath "$.id"
[Asserts]
jsonpath "$.total.amount" == "666.00"

POST {{base_url}}/api/v1/orders/{{pending_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-pay-0004
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_PENDING"
jsonpath "$.payment.status" == "PENDING"
jsonpath "$.payment.reference" == null

# la reserva se queda: el cobro pudo ocurrir
GET {{base_url}}/api/v1/products/SKU-003
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 2

# sin clave → 400
POST {{base_url}}/api/v1/orders/{{pending_id}}/payment
Authorization: Bearer {{token}}
HTTP 400
[Asserts]
jsonpath "$.code" == "IDEMPOTENCY_KEY_REQUIRED"
