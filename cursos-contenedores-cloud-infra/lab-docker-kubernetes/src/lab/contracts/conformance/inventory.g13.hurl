# Suite de conformidad · inventory y replenish · paso G13 (Fase 26)
# La misma operación pedida dos veces con la misma clave se hace una sola vez: la venta, el préstamo y la
# orden de reposición. Cada corrida usa claves nuevas (newUuid), así que la suite se puede repetir. Usa
# DRO-026, que nadie más toca.

PUT {{pricing}}/prices/SKU-0002
[Options]
variable: sale_key={{newUuid}}
variable: loan_key={{newUuid}}
variable: order_key={{newUuid}}
{"store": "DRO-026", "price": 15000}
HTTP 200

POST {{inventory}}/stock/DRO-026/SKU-0002/movements
{"type": "COUNT", "quantity": 10, "reference": "conteo-suite-g13"}
HTTP 201

# La venta, dos veces con la misma clave: una sola venta, una sola unidad menos.
POST {{inventory}}/sales
Idempotency-Key: {{sale_key}}
{"store": "DRO-026", "sku": "SKU-0002", "quantity": 1}
HTTP 201
[Captures]
sale: jsonpath "$.id"

POST {{inventory}}/sales
Idempotency-Key: {{sale_key}}
{"store": "DRO-026", "sku": "SKU-0002", "quantity": 1}
HTTP 201
[Asserts]
jsonpath "$.id" == "{{sale}}"

GET {{inventory}}/stock/DRO-026/SKU-0002
HTTP 200
[Asserts]
jsonpath "$.quantity" == 9

# La misma clave con otro cuerpo no es un reintento: es un error de quien llama.
POST {{inventory}}/sales
Idempotency-Key: {{sale_key}}
{"store": "DRO-026", "sku": "SKU-0002", "quantity": 2}
HTTP 422

# El préstamo, dos veces con la misma clave: un solo préstamo.
POST {{inventory}}/loans
Idempotency-Key: {{loan_key}}
{"sku": "SKU-0002", "originStore": "DRO-026", "destinationStore": "DRO-023", "quantity": 1}
HTTP 202
[Captures]
loan: jsonpath "$.id"

POST {{inventory}}/loans
Idempotency-Key: {{loan_key}}
{"sku": "SKU-0002", "originStore": "DRO-026", "destinationStore": "DRO-023", "quantity": 1}
HTTP 202
[Asserts]
jsonpath "$.id" == "{{loan}}"

# La moto del préstamo, pedida con la clave del préstamo.
GET {{inventory}}/loans/{{loan}}
[Options]
retry: 20
retry-interval: 500
HTTP 200
[Asserts]
jsonpath "$.status" == "COMPLETED"

GET {{replenish}}/replenishment-orders?idempotencyKey={{loan}}
HTTP 200
[Asserts]
jsonpath "$" count == 1

# La orden de reposición, dos veces con la misma clave: una sola orden.
POST {{replenish}}/replenishment-orders
Idempotency-Key: {{order_key}}
{"sku": "SKU-0002", "destinationStore": "DRO-026", "quantity": 5}
HTTP 201
[Captures]
order: jsonpath "$.id"

POST {{replenish}}/replenishment-orders
Idempotency-Key: {{order_key}}
{"sku": "SKU-0002", "destinationStore": "DRO-026", "quantity": 5}
HTTP 201
[Asserts]
jsonpath "$.id" == "{{order}}"

POST {{replenish}}/replenishment-orders
Idempotency-Key: {{order_key}}
{"sku": "SKU-0002", "destinationStore": "DRO-026", "quantity": 6}
HTTP 422

GET {{replenish}}/replenishment-orders?idempotencyKey={{order_key}}
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].id" == "{{order}}"
