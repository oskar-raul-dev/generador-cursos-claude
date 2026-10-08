# Suite de conformidad · replenish · paso G0 (Fase 02)

GET {{replenish}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{replenish}}/health/ready
HTTP 200
[Asserts]
jsonpath "$.status" == "ready"

GET {{replenish}}/replenishment-orders
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$" count >= 1
jsonpath "$[0].id" isString
jsonpath "$[0].sku" matches "^SKU-[0-9]{4}$"
jsonpath "$[0].destinationStore" matches "^DRO-[0-9]{3}$"
jsonpath "$[0].status" == "PENDING"

# Lo que todavía no existe: una orden por id (G1) y las métricas (G6).
GET {{replenish}}/replenishment-orders/RO-0001
HTTP 404

GET {{replenish}}/metrics
HTTP 404
