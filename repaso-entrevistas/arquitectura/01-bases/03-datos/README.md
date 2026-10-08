# 03 — Datos

> Tercer bloque de [`arquitectura/01-bases`](../README.md). Dónde vive el dato, qué garantiza, cómo
> escala y cómo se lee rápido: CAP y consistencia, transacciones, NoSQL y **DynamoDB**, sharding,
> réplicas, CQRS, caché y multi-tenancy.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto

El bloque que responde a la mitad de las preguntas de una entrevista de arquitectura, porque casi
todo problema de escala acaba siendo un problema de datos.

Asume leído [`01-bases`](../01-bases/) y se apoya en
[`02-eventos`](../02-eventos/) para todo lo que sea propagación: aquí se decide **dónde vive el
dato**, allí **cómo viaja**.

**DynamoDB tiene capítulo propio con detalle** porque es la base NoSQL que más se pregunta en
backend Java sobre AWS, y porque su modelo de diseño invierte lo que enseña SQL.

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [CAP, PACELC y consistencia](01-cap-y-consistencia.md) | Lo que CAP dice y lo que se le hace decir; garantías de sesión; quórums |
| `02` | [Transacciones y bloqueo](02-transacciones-y-bloqueo.md) | ACID, niveles de aislamiento, optimista contra pesimista, propagación |
| `03` | [Relacional, NoSQL y DynamoDB](03-relacional-nosql-y-dynamodb.md) | **El más preguntado.** Familias NoSQL, claves, índices, particiones calientes |
| `04` | [Sharding y particionado](04-sharding-y-particionado.md) | Qué agotar antes, estrategias de reparto, rebalanceo, lo que se rompe |
| `05` | [Réplicas y lag](05-replicas-y-lag.md) | Síncrona contra asíncrona, enrutamiento de lecturas, conmutación por error |
| `06` | [CQRS](06-cqrs.md) | Los tres niveles, y por qué es independiente de event sourcing |
| `07` | [Caché](07-cache.md) | Patrones, invalidación, estampida, dónde ponerla, qué pasa si cae |
| `08` | [Políglota y multi-tenant](08-poliglota-y-multi-tenant.md) | Cuándo varios motores, y las tres formas de aislar clientes |
| `09` | [Simulación de entrevista](09-simulacion-de-entrevista.md) | 36 preguntas `S#` + 5 escenarios de diseño |
| `10` | [Respuestas](10-respuestas.md) | Solucionario completo, en tres capas |

**Si el calendario aprieta**, el orden de prioridad es: `03`, `01`, `07`, `02`. Esos cuatro
cubren lo que más se pregunta.

---

## Mapa mental del bloque

```text
              ¿Qué garantiza?          → 01 (CAP/PACELC) · 02 (ACID y aislamiento)
                     │
              ¿Dónde vive?             → 03 (relacional vs NoSQL) · 08 (políglota, tenants)
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
   ¿Y si no cabe?            ¿Y si es lento leer?
   04 sharding               05 réplicas · 06 CQRS · 07 caché
```

---

## Qué NO está aquí

- **Saga, outbox, event sourcing y proyecciones** → [`02-eventos`](../02-eventos/). Aquí se usan
  como consecuencia; allí se estudian como patrón.
- **RTO, RPO, multi-región y despliegues sin caída** →
  [`01-bases/10`](../01-bases/10-alta-disponibilidad-y-escalado.md).
- **Cifrado, secretos y control de acceso a datos** → [`04-seguridad`](../04-seguridad/).
- **Conciliación bancaria y cierre de día** → [`05-banca`](../05-banca/).
- **El motor por dentro: índices, planes, MVCC, niveles de aislamiento** →
  [`bases/05-bases-datos`](../../../bases/05-bases-datos/). Aquí se decide; allí se ve cómo lo
  cumple el motor.
- **Base de datos por servicio y consultas entre servicios** →
  [`arquitectura/04-microservicios/03-datos-y-consistencia`](../../04-microservicios/03-datos-y-consistencia/README.md).
- **Laboratorio.** Este corpus es teoría y evaluación; no hay labs.
