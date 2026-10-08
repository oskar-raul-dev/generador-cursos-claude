# Caracterización del legado · 02 — autenticación.

# login correcto: token, y la entidad User entera (defecto congelado: sale el hash de la contraseña)
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "ana-12345" }
HTTP 200
[Captures]
token: jsonpath "$.accessToken"
[Asserts]
jsonpath "$.tokenType" == "Bearer"
jsonpath "$.expiresIn" == 900
jsonpath "$.user.email" == "ana@mono.local"
jsonpath "$.user.passwordHash" exists

# contraseña equivocada: 200 con error, y distinto de un correo inexistente (defecto congelado)
POST {{base_url}}/api/v1/auth/login
{ "email": "ana@mono.local", "password": "wrong-password" }
HTTP 200
[Asserts]
jsonpath "$.error" == "Wrong password"
jsonpath "$.accessToken" not exists

POST {{base_url}}/api/v1/auth/login
{ "email": "nobody@mono.local", "password": "whatever-123" }
HTTP 200
[Asserts]
jsonpath "$.error" == "User not found"

# sin token: 200 con error, escrito por la cadena de seguridad
GET {{base_url}}/api/v1/orders
HTTP 200
[Asserts]
jsonpath "$.error" == "Not logged in"

# logout: el token queda revocado (en memoria del proceso)
POST {{base_url}}/api/v1/auth/logout
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.ok" == true

GET {{base_url}}/api/v1/orders
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.error" == "Not logged in"
