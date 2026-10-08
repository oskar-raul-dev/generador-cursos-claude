# Suite de conformidad · storefront · paso G1 (Fase 09)
# El storefront no tiene OpenAPI. Lo que se comprueba aquí: que sirve la página y su salud. Que liste
# el catálogo se ve en el navegador, y solo desde la Fase 10, cuando el API tiene puerta de entrada.

GET {{storefront}}/
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
body contains "<div id=\"root\">"

GET {{storefront}}/health/live
HTTP 200

GET {{storefront}}/health/ready
HTTP 200
