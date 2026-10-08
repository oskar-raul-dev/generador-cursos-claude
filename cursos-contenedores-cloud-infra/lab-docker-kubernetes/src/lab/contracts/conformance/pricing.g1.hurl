# Suite de conformidad · pricing · paso G1 (Fase 09)
# El almacén propio: guardar y leer precios. Idempotente: se puede correr dos veces seguidas.

GET {{pricing}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{pricing}}/health/ready
HTTP 200

# Fijar un precio y leerlo.
PUT {{pricing}}/prices/SKU-0003
{"store": "DRO-007", "price": 12900}
HTTP 200
[Asserts]
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.store" == "DRO-007"
jsonpath "$.price" == 12900
jsonpath "$.currency" == "COP"

GET {{pricing}}/prices/SKU-0003?store=DRO-007
HTTP 200
[Asserts]
jsonpath "$.price" == 12900

# La lista de precios de una droguería lo incluye.
GET {{pricing}}/prices?store=DRO-007
HTTP 200
[Asserts]
jsonpath "$[*].sku" contains "SKU-0003"

# Sin droguería, la lista no tiene sentido.
GET {{pricing}}/prices
HTTP 400

# Un precio que no existe, y uno inválido.
GET {{pricing}}/prices/SKU-9999?store=DRO-007
HTTP 404
[Asserts]
jsonpath "$.error" == "not_found"

PUT {{pricing}}/prices/SKU-0003
{"store": "DRO-007", "price": -1}
HTTP 400

# Lo que todavía no existe: las métricas (G6).
GET {{pricing}}/metrics
HTTP 404
