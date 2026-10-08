# Copia de arquitectura/03-hexagonal/06-talleres/laboratorio/contrato/hurl/v1.1/07-notifications.hurl, tomada el 2026-09-29
# (taller 04 del monolito). Única sustitución: @hex.local → @mono.local. No se edita a mano.
#
# Parte 2: la cancelación deja OrderCancelled en la outbox; el Notifier lo entrega después del
# commit. La entrega es asíncrona, así que la lectura se reintenta hasta que aparezca.

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

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-07-order-notify
Content-Type: application/json
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"

# Antes de cancelar no hay notificación de este pedido.
GET {{base_url}}/api/v1/notifications?orderId={{order_id}}
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 0

POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200

# Después sí: se reintenta hasta 20 veces cada 500 ms, porque el dispatcher corre aparte.
GET {{base_url}}/api/v1/notifications?orderId={{order_id}}
Authorization: Bearer {{ops_token}}
[Options]
retry: 20
retry-interval: 500ms
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
jsonpath "$.items[0].orderId" == "{{order_id}}"
jsonpath "$.items[0].type" == "ORDER_CANCELLED"
jsonpath "$.items[0].recipient" == "ana@mono.local"

# Cancelar otra vez no produce una segunda notificación: la cancelación repetida no emite el hecho.
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200

GET {{base_url}}/api/v1/notifications?orderId={{order_id}}
Authorization: Bearer {{ops_token}}
[Options]
delay: 1500ms
HTTP 200
[Asserts]
jsonpath "$.items" count == 1

# Un customer no lee notificaciones.
GET {{base_url}}/api/v1/notifications
Authorization: Bearer {{ana_token}}
HTTP 403
[Asserts]
jsonpath "$.code" == "FORBIDDEN"
