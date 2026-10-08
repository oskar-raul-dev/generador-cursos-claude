# Suite v1 · 01 — el proceso responde. Sin token.
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
