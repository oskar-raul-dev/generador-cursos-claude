# Suite de conformidad · catalog · paso G7 (Fase 18)
# G7 no cambia ninguna respuesta: cambia el log. Esta suite hace una petición con un X-Request-Id
# conocido, y scripts/conformance/logs.py busca su línea JSON en el log del servicio.

GET {{catalog}}/products
X-Request-Id: g7-conformance-catalog
HTTP 200
