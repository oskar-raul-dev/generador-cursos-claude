# Suite de conformidad · pricing · paso G0
GET {{base_url}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{base_url}}/health/ready
HTTP 200
[Asserts]
jsonpath "$.status" == "ready"

GET {{base_url}}/prices/SKU-0003?store=DRO-014
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.store" == "DRO-014"
jsonpath "$.price" isInteger
jsonpath "$.currency" == "COP"

GET {{base_url}}/metrics
HTTP 404
