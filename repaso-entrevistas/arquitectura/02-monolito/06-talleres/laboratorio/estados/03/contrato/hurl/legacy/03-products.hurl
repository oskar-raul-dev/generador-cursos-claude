# Caracterización del legado · 03 — catálogo.

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

# lista: un array de entidades Product, ordenado por SKU, precio como número (double)
GET {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$" count == 5
jsonpath "$[0].sku" == "SKU-001"
jsonpath "$[0].price" == 49.9
jsonpath "$[0].stock" == 20
jsonpath "$[3].sku" == "SKU-004"
jsonpath "$[3].stock" == 0

GET {{base_url}}/api/v1/products/SKU-003
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.name" == "27\" monitor"
jsonpath "$.price" == 222.0
jsonpath "$.stock" == 5

# producto inexistente: 200 con error
GET {{base_url}}/api/v1/products/SKU-999
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Product SKU-999 does not exist"

# alta por un cliente: 200 con error
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
{ "sku": "SKU-006", "name": "Laptop stand", "price": 35.0, "stock": 10 }
HTTP 200
[Asserts]
jsonpath "$.error" == "Only operators can do this"

# alta por el operador, y un segundo alta con el mismo SKU que PISA el primero (defecto congelado)
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
{ "sku": "SKU-006", "name": "Laptop stand", "price": 35.0, "stock": 10 }
HTTP 200
[Asserts]
jsonpath "$.sku" == "SKU-006"
jsonpath "$.price" == 35.0

POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
{ "sku": "SKU-006", "name": "Laptop stand", "price": 39.0, "stock": 10 }
HTTP 200
[Asserts]
jsonpath "$.price" == 39.0
