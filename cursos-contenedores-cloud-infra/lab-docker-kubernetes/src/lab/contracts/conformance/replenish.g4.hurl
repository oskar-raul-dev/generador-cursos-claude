# Suite de conformidad · replenish · paso G4 (Fase 15)
# Lo que G4 promete: con su base contestando, la readiness dice ready; la liveness sigue sin consultar
# nada. El 503 con la base caída no se prueba aquí: la Fase 15 lo provoca a mano. La suite de G1 sigue
# valiendo para el resto del contrato.

GET {{replenish}}/health/live
HTTP 200
[Asserts]
jsonpath "$.status" == "live"

GET {{replenish}}/health/ready
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.status" == "ready"

# Lo que todavía no existe: las métricas (G6).
GET {{replenish}}/metrics
HTTP 404
