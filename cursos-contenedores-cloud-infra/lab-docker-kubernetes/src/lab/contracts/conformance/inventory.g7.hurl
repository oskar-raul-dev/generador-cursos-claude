# Suite de conformidad · inventory · paso G7 (Fase 18)
# G7 no cambia ninguna respuesta: cambia el log. Una venta con un X-Request-Id conocido, que inventory
# tiene que reenviar a catalog y a pricing: scripts/conformance/logs.py lo busca en el log de los tres.
# Usa la droguería DRO-021, como la suite de G5.

PUT {{pricing}}/prices/SKU-0002
{"store": "DRO-021", "price": 15000}
HTTP 200

POST {{inventory}}/stock/DRO-021/SKU-0002/movements
{"type": "COUNT", "quantity": 10, "reference": "conteo-suite-g7"}
HTTP 201

POST {{inventory}}/sales
X-Request-Id: g7-conformance-venta
{"store": "DRO-021", "sku": "SKU-0002", "quantity": 1}
HTTP 201
