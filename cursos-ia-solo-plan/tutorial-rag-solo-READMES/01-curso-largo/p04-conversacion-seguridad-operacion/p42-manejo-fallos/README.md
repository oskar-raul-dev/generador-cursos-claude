# P42 — Manejo de fallos

**Guía de proyecto · ~2.5 h**

## Qué construyes

El sistema degrada de forma controlada. Ollama se cae. PostgreSQL no responde. El usuario no ve un 500.

## Contenidos

- Circuit breaker: Ollama caído → respuesta cached o degradada
- Timeout: no esperés indefinidamente
- Fallback: si embedding falla, búsqueda textual
- Graceful degradation: alguna respuesta es mejor que ninguna

## Criterio de finalización

Ollama se apaga. Usuario ve mensaje claro. Sistema sigue respondiendo con degradación visible, no crash silencioso.

## Después de esta guía

Pasás a P43. Ahora portabilidad de modelos.
