# Caracterización del legado · 01 — salud del proceso.
# Esta suite congela lo que mono-legacy HACE, defectos incluidos: es un golden master, no un contrato.

GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
