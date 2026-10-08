# Catálogo: lectura para cualquier actor, alta solo para operator, paginación por cursor.

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ana@hex.local", "password": "ana-12345" }
HTTP 200
[Captures]
ana_token: jsonpath "$.accessToken"

POST {{base_url}}/api/v1/auth/login
Content-Type: application/json
{ "email": "ops@hex.local", "password": "ops-12345" }
HTTP 200
[Captures]
ops_token: jsonpath "$.accessToken"

# La semilla tiene cinco productos; puede haber más si otro archivo de la suite ya dio de alta alguno.
GET {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count >= 5
jsonpath "$.items[0].sku" == "SKU-001"
jsonpath "$.items[0].unitPrice.amount" == "49.90"
jsonpath "$.items[0].unitPrice.currency" == "USD"
jsonpath "$.items[0].stock" isInteger

# Página de dos: llega cursor para la siguiente.
GET {{base_url}}/api/v1/products?limit=2
Authorization: Bearer {{ana_token}}
HTTP 200
[Captures]
next_cursor: jsonpath "$.nextCursor"
[Asserts]
jsonpath "$.items" count == 2
jsonpath "$.nextCursor" isString

# La página siguiente empieza donde terminó la anterior.
GET {{base_url}}/api/v1/products?limit=2&cursor={{next_cursor}}
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.items" count == 2
jsonpath "$.items[0].sku" == "SKU-003"

# Un producto concreto, con su stock de la semilla.
GET {{base_url}}/api/v1/products/SKU-004
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.name" == "Webcam"
jsonpath "$.unitPrice.amount" == "59.00"
jsonpath "$.stock" == 0

# Uno que no existe.
GET {{base_url}}/api/v1/products/SKU-999
Authorization: Bearer {{ana_token}}
HTTP 404
[Asserts]
header "Content-Type" contains "application/problem+json"
jsonpath "$.code" == "PRODUCT_NOT_FOUND"

# Un customer no da de alta productos: la autorización gruesa vive en el borde.
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ana_token}}
Content-Type: application/json
{ "sku": "SKU-006", "name": "Laptop stand", "unitPrice": { "amount": "35.00", "currency": "USD" }, "stock": 10 }
HTTP 403
[Asserts]
jsonpath "$.code" == "FORBIDDEN"

# Un operator sí.
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
Content-Type: application/json
{ "sku": "SKU-006", "name": "Laptop stand", "unitPrice": { "amount": "35.00", "currency": "USD" }, "stock": 10 }
HTTP 201
[Asserts]
header "Location" endsWith "/api/v1/products/SKU-006"
jsonpath "$.sku" == "SKU-006"
jsonpath "$.stock" == 10

# El mismo SKU dos veces es un conflicto, no un error de validación.
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
Content-Type: application/json
{ "sku": "SKU-006", "name": "Laptop stand", "unitPrice": { "amount": "35.00", "currency": "USD" }, "stock": 10 }
HTTP 409
[Asserts]
jsonpath "$.code" == "PRODUCT_ALREADY_EXISTS"

# Dinero mal formado: "35" no es un decimal con dos cifras.
POST {{base_url}}/api/v1/products
Authorization: Bearer {{ops_token}}
Content-Type: application/json
{ "sku": "SKU-007", "name": "Mouse", "unitPrice": { "amount": "35", "currency": "USD" }, "stock": 1 }
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_FAILED"
jsonpath "$.errors[0].field" exists

# El producto recién creado se lee con su stock inicial.
GET {{base_url}}/api/v1/products/SKU-006
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.name" == "Laptop stand"
jsonpath "$.stock" == 10
