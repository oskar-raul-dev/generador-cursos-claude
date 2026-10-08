# Copia de arquitectura/04-microservicios/06-talleres/laboratorio/contrato/hurl/v1/06-cancel.hurl, tomada el
# 2026-09-29 (taller 04 del monolito). Sustitución: @ms.local → @mono.local. Los bloques marcados
# «NO CABE» contradicen al contrato hexagonal y se comentan, no se borran (06/04 §7).
#
# Suite v1 · 06 — cancelar libera la reserva y deja una notificación.
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-cancel-order-0001
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

# cancelar otra vez → 200 sin efecto
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

# NO CABE (06/04 §7): aquí un customer lee sus notificaciones; en el contrato hexagonal un customer
# recibe 403 en /notifications. El monolito sigue al hexagonal.
# GET {{base_url}}/api/v1/notifications
# Authorization: Bearer {{token}}
# HTTP 200
# [Asserts]
# jsonpath "$.items" count == 1
# jsonpath "$.items[0].orderId" == "{{order_id}}"
# jsonpath "$.items[0].type" == "ORDER_CANCELLED"
# jsonpath "$.items[0].recipient" == "ana@mono.local"

# un pedido pagado no se cancela
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-cancel-order-0002
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
paid_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{token}}
Idempotency-Key: suite-v1-cancel-pay-0001
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"

POST {{base_url}}/api/v1/orders/{{paid_id}}/cancel
Authorization: Bearer {{token}}
HTTP 409
[Asserts]
jsonpath "$.code" == "ORDER_NOT_CANCELLABLE"
