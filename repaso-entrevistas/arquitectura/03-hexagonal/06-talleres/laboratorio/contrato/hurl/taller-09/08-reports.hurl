# Taller 09: la proyección orders_summary se alimenta del tópico orders.events. Crear y cancelar un
# pedido se refleja en /reports/orders-summary después de que los consumidores procesen los eventos,
# así que las lecturas se reintentan. Solo el sabor Java, con `lab.py java --events kafka`, y
# DESPUÉS de `lab.py seed` (la proyección arranca vacía: los valores son absolutos).
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

# Un customer no lee informes.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ana_token}}
HTTP 403

# Punto de partida: la semilla no trae pedidos, así que la proyección está vacía.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 0

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-created-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"

# OrderCreated llega a la proyección: ana aparece con un pedido creado y 49.90 abierto.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ops_token}}
[Options]
retry: 20
retry-interval: 500ms
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
jsonpath "$.items[0].customerId" == "11111111-1111-4111-8111-111111111111"
jsonpath "$.items[0].ordersCreated" == 1
jsonpath "$.items[0].ordersCancelled" == 0
jsonpath "$.items[0].openAmount.amount" == "49.90"

POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200

# OrderCancelled: cancelados sube a uno, creados no cambia y el importe abierto vuelve a cero.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ops_token}}
[Options]
retry: 20
retry-interval: 500ms
HTTP 200
[Asserts]
jsonpath "$.items[0].ordersCreated" == 1
jsonpath "$.items[0].ordersCancelled" == 1
jsonpath "$.items[0].openAmount.amount" == "0.00"

# La notificación de la cancelación sigue llegando, ahora por Kafka (grupo hex-notifications).
GET {{base_url}}/api/v1/notifications?orderId={{order_id}}
Authorization: Bearer {{ops_token}}
[Options]
retry: 20
retry-interval: 500ms
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
jsonpath "$.items[0].type" == "ORDER_CANCELLED"
