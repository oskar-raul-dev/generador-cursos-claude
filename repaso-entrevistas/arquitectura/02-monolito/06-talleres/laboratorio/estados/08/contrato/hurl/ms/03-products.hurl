# Copia de arquitectura/04-microservicios/06-talleres/laboratorio/contrato/hurl/v1/03-products.hurl, tomada el
# 2026-09-29 (taller 04 del monolito). Sustitución: @ms.local → @mono.local. Los bloques marcados
# «NO CABE» contradicen al contrato hexagonal y se comentan, no se borran (06/04 §7).
#
# Suite v1 · 03 — catálogo con stock. Exige `lab.py seed` antes (valores de §14 de la guía).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
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
