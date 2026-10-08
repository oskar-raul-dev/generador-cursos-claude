# El proceso responde. Sin autenticación: es lo único público además del login.
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
