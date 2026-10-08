# Suite v2 · 05 — "mis pedidos" por las dos fuentes y el seguimiento por SSE (taller 11).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

POST {{base_url}}/api/v2/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-overview-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
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
jsonpath "$.status" == "PAID"

# composición: el estado del pago lo dice payments, en el momento
GET {{base_url}}/api/v2/orders/overview?source=composition
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
header "Server-Timing" startsWith "composition;dur="
jsonpath "$.degraded" == false
jsonpath "$.items[?(@.orderId == '{{order_id}}')].paymentStatus" == "AUTHORIZED"

# proyección: la misma respuesta, cuando el proyector haya leído el hecho (consistencia eventual)
GET {{base_url}}/api/v2/orders/overview?source=projection
Authorization: Bearer {{token}}
[Options]
retry: 50
retry-interval: 200ms
HTTP 200
[Asserts]
jsonpath "$.items[?(@.orderId == '{{order_id}}')].status" == "PAID"

# SSE de una saga ya terminada: repite su historia y cierra con `end`
GET {{base_url}}/api/v2/orders/{{order_id}}/events
Authorization: Bearer {{token}}
Accept: text/event-stream
HTTP 200
[Asserts]
header "Content-Type" contains "text/event-stream"
body contains "event:step"
body contains "event:end"
