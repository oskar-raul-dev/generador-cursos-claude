# 01 — Fundamentos y descomposición

> El bloque troncal: qué es un microservicio, dónde se corta un sistema, cómo se sale de un monolito,
> cómo se reconoce que la arquitectura no lo es, y qué hay dentro de un servicio bien hecho. Los otros
> cuatro bloques lo dan por leído.
>
> **Vigencia:** 2026-09-29.

---

## Orden de lectura

| Documento | Qué fija |
|---|---|
| [`01` — Qué es un microservicio](01-que-es-un-microservicio.md) | La definición por autonomía y el precio de entrada |
| [`02` — Descomposición y fronteras](02-descomposicion-y-fronteras.md) | Los criterios de corte y los que no lo son |
| [`03` — El camino desde el monolito](03-el-camino-desde-el-monolito.md) | Strangler fig, capa anticorrupción y el orden datos-proceso |
| [`04` — El monolito distribuido](04-el-monolito-distribuido.md) | Los cinco antipatrones y cómo se reconocen |
| [`05` — El servicio por dentro](05-el-servicio-por-dentro.md) | Chassis, configuración, apagado ordenado y health checks |
| [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) | 32 preguntas transversales y 5 escenarios |
| [`07` — Respuestas](07-respuestas.md) | El solucionario del bloque, en tres capas |

**122 preguntas de capítulo** más las transversales, todas con respuesta en `07`.

**Talleres, opcionales,** que ejercitan este bloque en local: `01` → [`06/01`](../06-talleres/01-el-monolito-y-su-contrato.md) · `02` → [`06/02`](../06-talleres/02-strangler-fig-con-envoy.md) · `03` → [`06/02`](../06-talleres/02-strangler-fig-con-envoy.md) · `04` → [`06/02`](../06-talleres/02-strangler-fig-con-envoy.md) · `05` → [`06/01`](../06-talleres/01-el-monolito-y-su-contrato.md), [`06/05`](../06-talleres/05-resiliencia-en-tres-plataformas.md).

---

## El mapa mental

```text
¿Qué es?          autonomía: desplegable solo · dueño de sus datos · frontera de negocio
                                    │
¿Dónde se corta?  capacidad de negocio · subdominio · razón de cambio · volatilidad
                                    │
¿Cómo se llega?   monolito modular → strangler fig → datos primero → proceso después
                                    │
¿Qué evitar?      base compartida · librería de dominio · cadena síncrona · CRUD anémico
                                    │
¿Qué hay dentro?  chassis · configuración fuera · apagado ordenado · health checks
```

---

## Qué NO está aquí

- **La decisión monolito contra microservicios** y los estilos de despliegue: son de
  [`arquitectura/01-bases/01-bases/02`](../../01-bases/01-bases/02-estilos-de-despliegue.md).
  Aquí se asume tomada.
- **DDD estratégico y táctico**: de
  [`arquitectura/01-bases/01-bases/06`](../../01-bases/01-bases/06-ddd-estrategico.md).
  Aquí se usa el vocabulario, no se enseña.
- **Cómo se comunican los servicios**: bloque [`02-comunicacion`](../02-comunicacion/).
- **Cómo se separan los datos**: bloque [`03-datos-y-consistencia`](../03-datos-y-consistencia/).
- **Resiliencia, despliegue y observabilidad**: bloque
  [`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/).

---

**Siguiente bloque:** [`02-comunicacion`](../02-comunicacion/) · **Índice del corpus:**
[`README.md`](../README.md)
