# Suite v2 · 02 — sin stock: la saga termina en CANCELLED y no se reserva nada (taller 08).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# en v1 esto era un 409 inmediato; en v2 el alta se acepta y el "no" llega después
POST {{base_url}}/api/v2/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-nostock-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 1 }, { "sku": "SKU-004", "quantity": 1 } ] }
HTTP 202
[Captures]
order_id: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "PENDING"

GET {{base_url}}/api/v2/orders/{{order_id}}
Authorization: Bearer {{token}}
[Options]
retry: 50
retry-interval: 200ms
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"
jsonpath "$.payment" == null

# todo o nada: tampoco se retuvo la línea que sí cabía
GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 20
