# Suite v2 · 04 — v1 sigue funcionando y anuncia su retirada en cada respuesta (taller 08).
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@ms.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"

# Deprecation (RFC 9745): obsoleto desde 2026-09-29, como fecha de Structured Fields (@segundos).
# Sunset (RFC 8594): deja de responder el 2027-03-31, como HTTP-date. Link: quién lo sustituye.
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
Idempotency-Key: suite-v2-v1-0001
{ "lines": [ { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Asserts]
header "Deprecation" == "@1790640000"
header "Sunset" == "Wed, 31 Mar 2027 00:00:00 GMT"
header "Link" contains "rel=\"successor-version\""
jsonpath "$.status" == "CONFIRMED"

# lo que no tiene sustituto en v2 no se anuncia como obsoleto
GET {{base_url}}/api/v1/products/SKU-002
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
header "Deprecation" not exists
