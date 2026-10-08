# 04 — Operación y resiliencia

> Lo que hay alrededor del servicio y sin lo cual no sobrevive a producción: descubrimiento, borde,
> resiliencia, observabilidad, mesh, entrega y pruebas. Es el bloque que más se parece a una
> entrevista de guardia.
>
> **Vigencia:** 2026-09-29.

---

## Orden de lectura

| Documento | Qué fija |
|---|---|
| [`01` — Descubrimiento y enrutamiento](01-descubrimiento-y-enrutamiento.md) | Nombres estables, DNS y balanceo por llamada |
| [`02` — API gateway y BFF](02-api-gateway-y-bff.md) | Qué va en el borde y quién posee cada pieza |
| [`03` — Resiliencia en la práctica](03-resiliencia-en-la-practica.md) | **Timeouts, reintentos, circuit breaker, bulkhead** |
| [`04` — Observabilidad y trazas](04-observabilidad-y-trazas.md) | Los tres pilares y dónde se pierde el contexto |
| [`05` — Service mesh y sidecar](05-service-mesh-y-sidecar.md) | Qué mueve fuera del código y qué no |
| [`06` — Despliegue y entrega](06-despliegue-y-entrega.md) | Estrategias, flags y el pipeline por servicio |
| [`07` — Testing de microservicios](07-testing-de-microservicios.md) | La pirámide deformada y los contratos |
| [`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) | 35 preguntas transversales y 5 escenarios |
| [`09` — Respuestas](09-respuestas.md) | El solucionario del bloque, en tres capas |

**175 preguntas de capítulo** más las transversales, todas con respuesta en `09`.

**Talleres, opcionales,** que ejercitan este bloque en local: `01` → [`06/05`](../06-talleres/05-resiliencia-en-tres-plataformas.md) · `02` → [`06/02`](../06-talleres/02-strangler-fig-con-envoy.md) · `03` → [`06/03`](../06-talleres/03-http-entre-servicios.md), [`06/05`](../06-talleres/05-resiliencia-en-tres-plataformas.md) · `04` → [`06/07`](../06-talleres/07-observabilidad-de-extremo-a-extremo.md) · `07` → [`06/10`](../06-talleres/10-contratos-y-testing.md).

---

## El mapa mental

```text
el camino de una petición
  cliente → gateway/BFF (02) → descubrimiento (01) → servicio
                                        │
                        y en cada salto: timeout · reintento · circuit breaker (03)
                                        │
            todo ello visible en trazas, métricas y logs correlacionados (04)
                                        │
        lo transversal puede moverse al sidecar… con su precio (05)
                                        │
        y todo se entrega por un pipeline (06) con pruebas que no dependen
        de un entorno completo (07)
```

---

## Qué NO está aquí

- **Kubernetes, VPC, IAM y balanceadores concretos**: de
  [`cloud/01-aws`](../../../cloud/01-aws/) y
  [`cloud/02-gcp`](../../../cloud/02-gcp/). Aquí entran solo hasta donde implementan
  un patrón.
- **OAuth2, OIDC, JWT, mTLS como modelo y zero-trust**: del bloque
  [`04-seguridad`](../../01-bases/04-seguridad/) del corpus de arquitectura.
- **El razonamiento de la resiliencia**: de
  [`01-bases/09`](../../01-bases/01-bases/09-resiliencia.md). Aquí se
  implementa.
- **Qué librería usa cada plataforma para todo esto**: bloque
  [`05-plataformas`](../05-plataformas/).

---

**Anterior:** [`03-datos-y-consistencia`](../03-datos-y-consistencia/) · **Siguiente:**
[`05-plataformas`](../05-plataformas/) · **Índice:** [`README.md`](../README.md)
