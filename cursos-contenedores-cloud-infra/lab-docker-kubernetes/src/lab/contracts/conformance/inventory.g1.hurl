# Suite de conformidad · inventory · paso G1 (Fase 09)
# La existencia solo cambia por movimientos (D33). Idempotente: el conteo fija el punto de partida.

GET {{inventory}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

# Un conteo fija la existencia en lo contado, y crea el registro si no existía.
POST {{inventory}}/stock/DRO-007/SKU-0003/movements
{"type": "COUNT", "quantity": 20, "reference": "conteo-suite-g1"}
HTTP 201
[Asserts]
jsonpath "$.type" == "COUNT"
jsonpath "$.store" == "DRO-007"

GET {{inventory}}/stock/DRO-007/SKU-0003
HTTP 200
[Asserts]
jsonpath "$.quantity" == 20

# Una entrada suma.
POST {{inventory}}/stock/DRO-007/SKU-0003/movements
{"type": "RESTOCK", "quantity": 4, "reference": "RO-0001"}
HTTP 201
[Asserts]
jsonpath "$.quantity" == 4

GET {{inventory}}/stock/DRO-007/SKU-0003
HTTP 200
[Asserts]
jsonpath "$.quantity" == 24

# Un ajuste sin código de razón no se acepta; con código, sí.
POST {{inventory}}/stock/DRO-007/SKU-0003/movements
{"type": "ADJUSTMENT", "quantity": -1}
HTTP 422

POST {{inventory}}/stock/DRO-007/SKU-0003/movements
{"type": "ADJUSTMENT", "quantity": -1, "reasonCode": "DAMAGED"}
HTTP 201
[Asserts]
jsonpath "$.reasonCode" == "DAMAGED"
jsonpath "$.quantity" == -1

# Un ajuste que deja la existencia en negativo es un conflicto.
POST {{inventory}}/stock/DRO-007/SKU-0003/movements
{"type": "ADJUSTMENT", "quantity": -100, "reasonCode": "THEFT"}
HTTP 409

# El umbral se edita con PATCH; la cantidad, no.
PATCH {{inventory}}/stock/DRO-007/SKU-0003
Content-Type: application/merge-patch+json
{"reorderThreshold": 8}
HTTP 200
[Asserts]
jsonpath "$.reorderThreshold" == 8
jsonpath "$.quantity" == 23

PATCH {{inventory}}/stock/DRO-007/SKU-0003
Content-Type: application/merge-patch+json
{"quantity": 50}
HTTP 422

# Un producto sin existencias registradas.
GET {{inventory}}/stock/DRO-007/SKU-9999
HTTP 404

# La tabla de códigos de razón, sembrada.
GET {{inventory}}/reason-codes
HTTP 200
[Asserts]
jsonpath "$[*].code" contains "TRANSFER_LOST"

# Lo que todavía no existe: el préstamo (G11) y las métricas (G6).
GET {{inventory}}/loans/1
HTTP 404

GET {{inventory}}/metrics
HTTP 404
