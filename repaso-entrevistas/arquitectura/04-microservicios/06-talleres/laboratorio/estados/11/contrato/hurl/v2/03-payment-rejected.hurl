# Suite v2 · 03 — pago rechazado: PAYMENT_REJECTED y el stock vuelve (la compensación) (taller 08).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# SKU-005 cuesta 1499.00: el proveedor rechaza por encima de 1000.00
POST {{base_url}}/api/v2/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-rejected-0001
{ "lines": [ { "sku": "SKU-005", "quantity": 1 } ] }
HTTP 202
[Captures]
order_id: jsonpath "$.id"

GET {{base_url}}/api/v2/orders/{{order_id}}
Authorization: Bearer {{token}}
[Options]
retry: 50
retry-interval: 200ms
HTTP 200
[Asserts]
jsonpath "$.status" == "PAYMENT_REJECTED"
jsonpath "$.payment.status" == "REJECTED"

# la liberación es OTRO paso de la saga, posterior al rechazo: también se espera
GET {{base_url}}/api/v1/products/SKU-005
Authorization: Bearer {{token}}
[Options]
retry: 50
retry-interval: 200ms
HTTP 200
[Asserts]
jsonpath "$.stock" == 3
