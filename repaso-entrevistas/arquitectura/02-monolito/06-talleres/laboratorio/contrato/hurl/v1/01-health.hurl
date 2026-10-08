# Suite v1 de mono-legacy (taller 04). El proceso responde; sin autenticación.
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
