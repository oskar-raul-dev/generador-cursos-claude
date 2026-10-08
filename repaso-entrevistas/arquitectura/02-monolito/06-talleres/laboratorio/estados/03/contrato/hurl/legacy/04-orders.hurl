# Caracterización del legado · 04 — pedidos.

POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

# compra válida: la entidad Order, con el cliente embebido y el dinero como double
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 200
[Captures]
order_id: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "CONFIRMED"
jsonpath "$.total" == 109.7
jsonpath "$.lines" count == 2
jsonpath "$.lines[0].unitPrice" == 49.9
jsonpath "$.customer.passwordHash" exists
jsonpath "$.payments" count == 0

# el double se ve: tres cables de 9.90 no suman 29.70 (defecto congelado)
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-002", "quantity": 3 } ] }
HTTP 200
[Asserts]
jsonpath "$.total" == 29.700000000000003

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# sin stock: 200 con error y nada cambia (la primera línea también se deshace)
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 1 }, { "sku": "SKU-004", "quantity": 1 } ] }
HTTP 200
[Asserts]
jsonpath "$.error" == "Not enough stock for SKU-004"

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18

# SKU inexistente: 500 con la traza de Java en el cuerpo (defecto congelado)
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-999", "quantity": 1 } ] }
HTTP 500
[Asserts]
jsonpath "$.trace" contains "java.lang.NullPointerException"
jsonpath "$.path" == "/api/v1/orders"

# sin líneas y con cantidad cero: 200 con error
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [] }
HTTP 200
[Asserts]
jsonpath "$.error" == "No lines"

POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 0 } ] }
HTTP 200
[Asserts]
jsonpath "$.error" == "Invalid quantity"

# leer un pedido propio, y uno que no existe
GET {{base_url}}/api/v1/orders/{{order_id}}
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.id" == "{{order_id}}"
jsonpath "$.status" == "CONFIRMED"

GET {{base_url}}/api/v1/orders/00000000-0000-4000-8000-000000000000
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Order not found"

# un id que no es UUID: 400 generado por el framework, también con traza
GET {{base_url}}/api/v1/orders/not-a-uuid
Authorization: Bearer {{ana_token}}
HTTP 400
[Asserts]
jsonpath "$.trace" contains "MethodArgumentTypeMismatchException"

# la lista de ana: los dos pedidos creados, el más reciente primero
GET {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[1].id" == "{{order_id}}"
