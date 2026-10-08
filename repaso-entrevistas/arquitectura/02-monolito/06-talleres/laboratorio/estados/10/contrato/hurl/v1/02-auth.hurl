# Autenticación: login, credenciales inválidas, validación de forma, logout con revocación.
# En hurl/legacy todo esto respondía 200 con {"error"} y el login devolvía el usuario con su hash.

# Login correcto: devuelve un bearer de 15 minutos.
POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"
[Asserts]
jsonpath "$.tokenType" == "Bearer"
jsonpath "$.expiresIn" == 900
jsonpath "$.accessToken" matches "^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$"
# el defecto del legado que el contrato elimina: el objeto user con passwordHash
jsonpath "$.user" not exists

# Contraseña incorrecta: 401 con el mismo cuerpo que un correo inexistente.
POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@mono.local", "password": "wrong-password" }
HTTP 401
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "INVALID_CREDENTIALS"
jsonpath "$.status" == 401

# Correo inexistente: idéntico al anterior; no se revela si el usuario existe.
POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "nobody@mono.local", "password": "ana-12345" }
HTTP 401
[Asserts]
jsonpath "$.code" == "INVALID_CREDENTIALS"

# Cuerpo sin la forma esperada: es validación de borde, no de credenciales.
POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "not-an-email" }
HTTP 400
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "VALIDATION_FAILED"

# Sin token no hay catálogo.
GET {{base_url}}/api/v1/products
HTTP 401
[Asserts]
jsonpath "$.code" == "UNAUTHENTICATED"

# Con token sí.
GET {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
HTTP 200

# Logout revoca el token presentado.
POST {{base_url}}/api/v1/auth/logout
Authorization: Bearer {{ana_token}}
HTTP 204

# El mismo token, ya revocado, recibe un código distinto del de "sin token".
GET {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
HTTP 401
[Asserts]
jsonpath "$.code" == "TOKEN_REVOKED"

# Logout con un token ya revocado también es 401: no hay sesión que cerrar.
POST {{base_url}}/api/v1/auth/logout
Authorization: Bearer {{ana_token}}
HTTP 401
