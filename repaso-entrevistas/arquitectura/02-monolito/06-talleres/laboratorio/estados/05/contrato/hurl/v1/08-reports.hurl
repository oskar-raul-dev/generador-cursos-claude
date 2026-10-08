# Informe y lotes: consultas síncronas disfrazadas de lote (prompt-base §9). Solo operator.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ops@mono.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

# Un customer no ve el informe.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ana_token}}
HTTP 403
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "FORBIDDEN"

# El operator sí: una fila por cliente, con el importe abierto como dinero.
GET {{base_url}}/api/v1/reports/orders-summary
Authorization: Bearer {{ops_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 1
jsonpath "$.items[0].customerId" == "11111111-1111-4111-8111-111111111111"
jsonpath "$.items[0].ordersCreated" isInteger
jsonpath "$.items[0].openAmount.amount" matches "^[0-9]+\\.[0-9]{2}$"
jsonpath "$.items[0].openAmount.currency" == "USD"

# Un lote que no existe.
GET {{base_url}}/api/v1/batches/999999
Authorization: Bearer {{ops_token}}
HTTP 404
[Asserts]
jsonpath "$.code" == "BATCH_NOT_FOUND"
