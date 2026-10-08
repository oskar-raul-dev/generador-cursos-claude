# Caracterización del legado · 06 — cancelación y notificaciones.

POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
{ "email": "ops@mono.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-002", "quantity": 4 } ] }
HTTP 200
[Captures]
order_id: jsonpath "$.id"

# cancelar un pedido confirmado: el estado cambia en el servicio, el stock lo devuelve el trigger
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 96

# cancelar otra vez: devuelve el pedido sin cambios y el stock no vuelve a subir
POST {{base_url}}/api/v1/orders/{{order_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"

GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 96

# un pedido pagado no se cancela: la regla vive en el controlador
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 200
[Captures]
paid_id: jsonpath "$.id"

POST {{base_url}}/api/v1/orders/{{paid_id}}/payment
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.orderStatus" == "PAID"

POST {{base_url}}/api/v1/orders/{{paid_id}}/cancel
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Paid orders can not be cancelled"

# notificaciones: solo el operador; la cancelación dejó una
GET {{base_url}}/api/v1/notifications?orderId={{order_id}}
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].type" == "ORDER_CANCELLED"
jsonpath "$[0].recipient" == "ana@mono.local"

GET {{base_url}}/api/v1/notifications
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Only operators can do this"
