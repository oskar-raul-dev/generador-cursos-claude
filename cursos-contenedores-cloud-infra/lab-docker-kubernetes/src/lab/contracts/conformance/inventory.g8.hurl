# Suite de conformidad · inventory y pricing · paso G8 (Fase 19)
# Con global.mtls.enabled, inventory le pide el precio a pricing por TLS mutuo (https://pricing…:8443).
# La venta pasa solo si el saludo TLS pasa: inventory presentó su certificado y confió en el de pricing.
# Lo que la suite no puede ver (que sin certificado se corta) lo prueba la Fase 19 a mano.

PUT {{pricing}}/prices/SKU-0002
{"store": "DRO-021", "price": 15000}
HTTP 200

POST {{inventory}}/stock/DRO-021/SKU-0002/movements
{"type": "COUNT", "quantity": 10, "reference": "conteo-suite-g8"}
HTTP 201

POST {{inventory}}/sales
X-Request-Id: g8-conformance-venta
{"store": "DRO-021", "sku": "SKU-0002", "quantity": 1}
HTTP 201
[Asserts]
jsonpath "$.unitPrice" == 15000
