# Suite de conformidad · catalog · paso G1 (Fase 09)
# Los datos maestros se editan; descontinuar exige un código. Idempotente.

GET {{catalog}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

# Crear un producto: 201 la primera vez, 409 si ya existía.
POST {{catalog}}/products
{"sku": "SKU-0101", "name": "Suero oral 500 ml", "category": "venta libre"}
HTTP *
[Asserts]
status toString matches "^(201|409)$"

POST {{catalog}}/products
{"sku": "SKU-0101", "name": "Suero oral 500 ml", "category": "venta libre"}
HTTP 409

GET {{catalog}}/products/SKU-0101
HTTP 200
[Asserts]
jsonpath "$.name" == "Suero oral 500 ml"

# Descontinuar sin código no se acepta; con código, sale de la lista por defecto.
PATCH {{catalog}}/products/SKU-0101
Content-Type: application/merge-patch+json
{"status": "DISCONTINUED"}
HTTP 422

PATCH {{catalog}}/products/SKU-0101
Content-Type: application/merge-patch+json
{"status": "DISCONTINUED", "reasonCode": "SANITARY_RECALL"}
HTTP 200
[Asserts]
jsonpath "$.status" == "DISCONTINUED"
jsonpath "$.statusReasonCode" == "SANITARY_RECALL"

GET {{catalog}}/products
HTTP 200
[Asserts]
jsonpath "$[*].sku" not contains "SKU-0101"

GET {{catalog}}/products?status=all
HTTP 200
[Asserts]
jsonpath "$[*].sku" contains "SKU-0101"

# Reactivar no exige código, y lo borra.
PATCH {{catalog}}/products/SKU-0101
Content-Type: application/merge-patch+json
{"status": "ACTIVE"}
HTTP 200
[Asserts]
jsonpath "$.statusReasonCode" == null

GET {{catalog}}/products/SKU-9999
HTTP 404

GET {{catalog}}/categories
HTTP 200
[Asserts]
jsonpath "$" contains "venta libre"

GET {{catalog}}/reason-codes
HTTP 200
[Asserts]
jsonpath "$[*].code" contains "SANITARY_RECALL"

# Lo que todavía no existe: las métricas (G6).
GET {{catalog}}/metrics
HTTP 404
