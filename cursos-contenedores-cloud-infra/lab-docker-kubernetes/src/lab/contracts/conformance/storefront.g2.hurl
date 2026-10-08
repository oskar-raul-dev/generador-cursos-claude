# Suite de conformidad · storefront · paso G2 (Fase 11)
# Lo de G1, más la configuración en arranque: /config.json existe, no se guarda en caché y trae lo que
# la página necesita. Que tenga los valores de cada ambiente lo comprueba la fase, no la suite.

GET {{storefront}}/
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
body contains "<div id=\"root\">"

GET {{storefront}}/config.json
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
header "Cache-Control" == "no-store"
jsonpath "$.apiBaseUrl" startsWith "http"
jsonpath "$.brandName" isString

GET {{storefront}}/health/live
HTTP 200

GET {{storefront}}/health/ready
HTTP 200
