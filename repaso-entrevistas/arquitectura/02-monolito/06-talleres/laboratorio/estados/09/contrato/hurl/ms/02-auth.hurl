# Copia de arquitectura/04-microservicios/06-talleres/laboratorio/contrato/hurl/v1/02-auth.hurl, tomada el
# 2026-09-29 (taller 04 del monolito). Sustitución: @ms.local → @mono.local. Los bloques marcados
# «NO CABE» contradicen al contrato hexagonal y se comentan, no se borran (06/04 §7).
#
# Suite v1 · 02 — login y rechazo sin token.

# credenciales válidas → token Bearer
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Asserts]
jsonpath "$.tokenType" == "Bearer"
jsonpath "$.expiresIn" == 900
jsonpath "$.accessToken" isString

# contraseña equivocada → 401 con el mismo cuerpo que un correo inexistente
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "wrong-password" }
HTTP 401
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "INVALID_CREDENTIALS"

POST {{base_url}}/api/v1/auth/login
{ "email": "nobody@mono.local", "password": "whatever-123" }
HTTP 401
[Asserts]
jsonpath "$.code" == "INVALID_CREDENTIALS"

# sin token → 401
GET {{base_url}}/api/v1/orders
HTTP 401
[Asserts]
jsonpath "$.code" == "UNAUTHENTICATED"

# token manipulado → 401
GET {{base_url}}/api/v1/orders
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4In0.invalid
HTTP 401
[Asserts]
jsonpath "$.code" == "UNAUTHENTICATED"
