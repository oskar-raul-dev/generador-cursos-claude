# Caracterización del legado · 05 — pago.

POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

# pago autorizado por el banco
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
HTTP 200
[Captures]
paid_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"
jsonpath "$.payment.status" == "AUTHORIZED"
jsonpath "$.payment.reference" startsWith "psp-"
jsonpath "$.payment.amount" == 49.9

# pagar otra vez: 200 con error
POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Order can not be paid"

# más de 1000: rechazado por el if del legado, sin llamar al banco
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-005", "quantity": 1 } ] }
HTTP 200
[Captures]
rejected_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{rejected_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_REJECTED"
jsonpath "$.payment.status" == "REJECTED"
jsonpath "$.payment.reference" == null

# 666.00: el banco tarda 3 s, el legado espera 2 s y deja el pedido pendiente
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-003", "quantity": 3 } ] }
HTTP 200
[Captures]
pending_id: jsonpath "$.id"
[Asserts]
jsonpath "$.total" == 666.0

POST {{base_url}}/api/v1/orders/{{pending_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAYMENT_PENDING"
jsonpath "$.payment.status" == "PENDING"
duration >= 1900

# pedido inexistente
POST {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Order not found"
