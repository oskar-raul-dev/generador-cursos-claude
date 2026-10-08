# Copia de arquitectura/03-hexagonal/06-talleres/laboratorio/contrato/hurl/v1/01-health.hurl, tomada el 2026-09-29
# (taller 04 del monolito). Única sustitución: @hex.local → @mono.local. No se edita a mano.
#
# El proceso responde. Sin autenticación: es lo único público además del login.
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
