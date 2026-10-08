# Caracterización del legado · 07 — informe y lotes (consultas síncronas disfrazadas de lote).

POST {{base_url}}/api/v1/auth/login
{ "email": "ops@mono.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

# el resumen se calcula en cada petición recorriendo todos los pedidos de la semilla y de la suite
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
jsonpath "$.items[0].customerId" == "11111111-1111-4111-8111-111111111111"
jsonpath "$.items[0].ordersCreated" == 7
jsonpath "$.items[0].ordersCancelled" == 1

GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Only operators can do this"

GET {{base_url}}/api/v1/batches/999999
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Batch not found"
