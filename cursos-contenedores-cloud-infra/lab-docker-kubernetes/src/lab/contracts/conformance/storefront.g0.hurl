# Suite de conformidad · storefront · paso G0 (Fase 02)
# El frontend no tiene OpenAPI: su contrato es servir la página y contestar la salud.

GET {{storefront}}/
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
body contains "Droguerías La Vecina"

GET {{storefront}}/health/live
HTTP 200
