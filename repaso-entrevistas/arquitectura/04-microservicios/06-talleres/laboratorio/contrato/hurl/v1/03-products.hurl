# Suite v1 · 03 — catálogo con stock. Exige `lab.py seed` antes (valores de §14 de la guía).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

GET {{base_url}}/api/v1/products
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 5
jsonpath "$.items[0].sku" == "SKU-001"
jsonpath "$.items[0].unitPrice.amount" == "49.90"
jsonpath "$.items[0].unitPrice.currency" == "USD"
jsonpath "$.items[3].sku" == "SKU-004"
jsonpath "$.items[3].stock" == 0

GET {{base_url}}/api/v1/products/SKU-003
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.name" == "27\" monitor"
jsonpath "$.unitPrice.amount" == "222.00"
jsonpath "$.stock" == 5

GET {{base_url}}/api/v1/products/SKU-999
Authorization: Bearer {{token}}
HTTP 404
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "PRODUCT_NOT_FOUND"
