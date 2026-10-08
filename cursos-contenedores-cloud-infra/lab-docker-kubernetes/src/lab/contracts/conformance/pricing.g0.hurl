# Suite de conformidad · pricing · paso G0 (Fase 02)
# Lo que G0 promete: salud trivial, un precio con la forma del contrato, y nada de lo que llega después.

GET {{pricing}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{pricing}}/health/ready
HTTP 200
[Asserts]
jsonpath "$.status" == "ready"

GET {{pricing}}/prices/SKU-0003?store=DRO-007
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.store" == "DRO-007"
jsonpath "$.price" isInteger
jsonpath "$.price" >= 0
jsonpath "$.currency" == "COP"

# Sin droguería, el contrato dice DRO-001.
GET {{pricing}}/prices/SKU-0001
HTTP 200
[Asserts]
jsonpath "$.store" == "DRO-001"

# Lo que todavía no existe: la lista de precios (G1) y las métricas (G6).
GET {{pricing}}/prices?store=DRO-007
HTTP 404

GET {{pricing}}/metrics
HTTP 404
