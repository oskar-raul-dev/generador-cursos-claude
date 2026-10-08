# Suite de conformidad · pricing · paso G6 (Fase 17)
# Lo que G6 promete: /metrics en el formato de Prometheus, con el histograma común de los cuatro
# backends, y la petición de recién contada con su ruta.

GET {{pricing}}/prices?store=DRO-007
HTTP 200

GET {{pricing}}/metrics
HTTP 200
[Asserts]
header "Content-Type" contains "text/plain"
body contains "# TYPE http_server_requests_seconds histogram"
body matches /http_server_requests_seconds_count\{[^}]*uri="\/prices"/
body matches /http_server_requests_seconds_bucket\{[^}]*le="/
