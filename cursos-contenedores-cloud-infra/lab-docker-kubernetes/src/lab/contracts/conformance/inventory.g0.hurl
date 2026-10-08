# Suite de conformidad · inventory · paso G0 (Fase 02)

GET {{inventory}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{inventory}}/health/ready
HTTP 200
[Asserts]
jsonpath "$.status" == "ready"

GET {{inventory}}/stock/DRO-007/SKU-0003
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.store" == "DRO-007"
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.quantity" isInteger
jsonpath "$.reorderThreshold" isInteger

# Lo que todavía no existe: el préstamo (G11) y las métricas (G6).
GET {{inventory}}/loans/1
HTTP 404

GET {{inventory}}/metrics
HTTP 404
