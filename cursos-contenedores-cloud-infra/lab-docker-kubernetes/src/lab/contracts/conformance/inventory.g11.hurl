# Suite de conformidad · inventory · paso G11 (Fase 24)
# El préstamo entre droguerías como saga orquestada: reservar en el origen, despachar con replenish y
# cobrar en el destino; y si algo falla, deshacer lo hecho. Usa DRO-022 (origen), DRO-023 y DRO-024
# (destinos), que nadie más toca, y es idempotente: los conteos fijan el punto de partida.

# Los códigos de razón de las dos compensaciones.
GET {{inventory}}/reason-codes
HTTP 200
[Asserts]
jsonpath "$[*].code" contains "LOAN_RELEASED"

GET {{replenish}}/reason-codes
HTTP 200
[Asserts]
jsonpath "$[*].code" contains "SAGA_COMPENSATION"

# El precio del destino, para el cobro. DRO-024 no tiene precio a propósito.
PUT {{pricing}}/prices/SKU-0002
{"store": "DRO-023", "price": 15000}
HTTP 200

# Diez unidades en el origen; cero en el destino.
POST {{inventory}}/stock/DRO-022/SKU-0002/movements
{"type": "COUNT", "quantity": 10, "reference": "conteo-suite-g11"}
HTTP 201

POST {{inventory}}/stock/DRO-023/SKU-0002/movements
{"type": "COUNT", "quantity": 0, "reference": "conteo-suite-g11"}
HTTP 201

# Un préstamo que sale bien: 202 de inmediato, y los pasos después.
POST {{inventory}}/loans
{"sku": "SKU-0002", "originStore": "DRO-022", "destinationStore": "DRO-023", "quantity": 2}
HTTP 202
[Captures]
loan: jsonpath "$.id"
[Asserts]
jsonpath "$.id" matches "^LOAN-[0-9]{6}$"
jsonpath "$.status" == "STARTED"

GET {{inventory}}/loans/{{loan}}
[Options]
retry: 20
retry-interval: 500
HTTP 200
[Captures]
order: jsonpath "$.replenishmentOrderId"
[Asserts]
jsonpath "$.status" == "COMPLETED"
jsonpath "$.saleId" isString
jsonpath "$.steps[*].step" contains "RESERVE"
jsonpath "$.steps[*].step" contains "DISPATCH"
jsonpath "$.steps[*].step" contains "CHARGE"
jsonpath "$.steps[*].step" contains "RECEIVE"
jsonpath "$.steps[*].action" not contains "UNDO"

GET {{inventory}}/stock/DRO-022/SKU-0002
HTTP 200
[Asserts]
jsonpath "$.quantity" == 8

GET {{inventory}}/stock/DRO-023/SKU-0002
HTTP 200
[Asserts]
jsonpath "$.quantity" == 2

# La moto: una orden de replenish con la vecina como origen.
GET {{replenish}}/replenishment-orders/{{order}}
HTTP 200
[Asserts]
jsonpath "$.originStore" == "DRO-022"
jsonpath "$.destinationStore" == "DRO-023"
jsonpath "$.quantity" == 2

# La vecina no tiene mil: el pendiente. Nada que compensar, y la existencia no se mueve.
POST {{inventory}}/loans
{"sku": "SKU-0002", "originStore": "DRO-022", "destinationStore": "DRO-023", "quantity": 1000}
HTTP 202
[Captures]
backorder: jsonpath "$.id"

GET {{inventory}}/loans/{{backorder}}
[Options]
retry: 20
retry-interval: 500
HTTP 200
[Asserts]
jsonpath "$.status" == "BACKORDERED"
jsonpath "$.failure" isString
jsonpath "$.steps[*].action" not contains "UNDO"

# Sin precio en el destino, el cobro falla después del despacho: se cancela la moto y se libera la
# reserva, en ese orden, y la existencia vuelve a 8.
POST {{inventory}}/loans
{"sku": "SKU-0002", "originStore": "DRO-022", "destinationStore": "DRO-024", "quantity": 3}
HTTP 202
[Captures]
compensated: jsonpath "$.id"

GET {{inventory}}/loans/{{compensated}}
[Options]
retry: 20
retry-interval: 500
HTTP 200
[Captures]
cancelled: jsonpath "$.replenishmentOrderId"
[Asserts]
jsonpath "$.status" == "COMPENSATED"
jsonpath "$.failure" isString
jsonpath "$.saleId" == null
jsonpath "$.steps[?(@.action == 'UNDO')].step" contains "DISPATCH"
jsonpath "$.steps[?(@.action == 'UNDO')].step" contains "RESERVE"

GET {{replenish}}/replenishment-orders/{{cancelled}}
HTTP 200
[Asserts]
jsonpath "$.status" == "CANCELLED"
jsonpath "$.cancelReasonCode" == "SAGA_COMPENSATION"

GET {{inventory}}/stock/DRO-022/SKU-0002
HTTP 200
[Asserts]
jsonpath "$.quantity" == 8

# El mismo origen y destino no es un préstamo.
POST {{inventory}}/loans
{"sku": "SKU-0002", "originStore": "DRO-022", "destinationStore": "DRO-022", "quantity": 1}
HTTP 422

GET {{inventory}}/loans/LOAN-999999
HTTP 404
