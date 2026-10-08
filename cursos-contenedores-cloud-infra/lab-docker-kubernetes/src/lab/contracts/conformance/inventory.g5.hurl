# Suite de conformidad · inventory · paso G5 (Fase 16)
# La venta completa: catalog valida el producto, pricing pone el precio, la existencia se descuenta, y
# bajo el umbral se avisa a replenish sin esperar. Usa la droguería DRO-021, que nadie más toca, y es
# idempotente: el conteo fija el punto de partida.

# El precio de la venta, en pricing.
PUT {{pricing}}/prices/SKU-0002
{"store": "DRO-021", "price": 15000}
HTTP 200

# Diez unidades y umbral de cinco.
POST {{inventory}}/stock/DRO-021/SKU-0002/movements
{"type": "COUNT", "quantity": 10, "reference": "conteo-suite-g5"}
HTTP 201

PATCH {{inventory}}/stock/DRO-021/SKU-0002
Content-Type: application/merge-patch+json
{"reorderThreshold": 5}
HTTP 200

# Una venta que deja la existencia en el umbral o por encima: sin aviso.
POST {{inventory}}/sales
{"store": "DRO-021", "sku": "SKU-0002", "quantity": 3}
HTTP 201
[Asserts]
jsonpath "$.id" isString
jsonpath "$.unitPrice" == 15000
jsonpath "$.total" == 45000
jsonpath "$.replenishmentRequested" == false

# La que la deja por debajo: aviso a replenish.
POST {{inventory}}/sales
{"store": "DRO-021", "sku": "SKU-0002", "quantity": 3}
HTTP 201
[Asserts]
jsonpath "$.replenishmentRequested" == true

GET {{inventory}}/stock/DRO-021/SKU-0002
HTTP 200
[Asserts]
jsonpath "$.quantity" == 4

# No hay cinco: la venta no se registra.
POST {{inventory}}/sales
{"store": "DRO-021", "sku": "SKU-0002", "quantity": 5}
HTTP 409

# Un producto que catalog no conoce.
POST {{inventory}}/sales
{"store": "DRO-021", "sku": "SKU-9999", "quantity": 1}
HTTP 422

# El aviso llegó a replenish (sin que la venta lo esperara: se reintenta un momento).
GET {{replenish}}/replenishment-orders
[Options]
retry: 10
retry-interval: 500
HTTP 200
[Asserts]
jsonpath "$[?(@.destinationStore == 'DRO-021')].sku" contains "SKU-0002"
