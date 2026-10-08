# Suite de conformidad · catalog · paso G0 (Fase 02)

GET {{catalog}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{catalog}}/health/ready
HTTP 200
[Asserts]
jsonpath "$.status" == "ready"

GET {{catalog}}/products
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$" count >= 1
jsonpath "$[0].sku" matches "^SKU-[0-9]{4}$"
jsonpath "$[0].name" isString
jsonpath "$[*].category" contains "venta libre"

# Lo que todavía no existe: las categorías (G1) y las métricas (G6).
GET {{catalog}}/categories
HTTP 404

GET {{catalog}}/metrics
HTTP 404
