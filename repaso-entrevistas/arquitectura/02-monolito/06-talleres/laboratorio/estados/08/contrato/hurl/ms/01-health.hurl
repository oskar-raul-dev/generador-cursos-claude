# Copia de arquitectura/04-microservicios/06-talleres/laboratorio/contrato/hurl/v1/01-health.hurl, tomada el
# 2026-09-29 (taller 04 del monolito). Sustitución: @ms.local → @mono.local. Los bloques marcados
# «NO CABE» contradicen al contrato hexagonal y se comentan, no se borran (06/04 §7).
#
# Suite v1 · 01 — el proceso responde. Sin token.
GET {{base_url}}/health
HTTP 200
[Asserts]
jsonpath "$.status" == "UP"
