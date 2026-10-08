# 🏛️ Arquitectura — repaso para entrevistas

> Corpus de repaso para entrevistas de **Backend Senior / Tech Lead / Arquitecto** en el
> ecosistema Java, con contraste políglota. Cuatro módulos escritos —la teoría troncal, el
> monolito, la arquitectura hexagonal y los microservicios—, tres en preparación —la arquitectura
> orientada a eventos, la serverless y CQRS con event sourcing— y tres carpetas reservadas para los
> estilos que faltan. Cada módulo tiene su propia guía editorial y se puede estudiar solo.
>
> **Vigencia:** 2026-10-05.
>
> 📦 **En este demo** solo vienen los módulos `01`–`04`; los `05`–`10` se citan por nombre, sin enlace.

---

## Los módulos

| Módulo | Pregunta que responde | Contenido | Estado |
|---|---|---|---|
| [`01-bases/`](01-bases/README.md) | ¿Qué decisión de sistema es y a qué precio? | 5 bloques: bases, eventos, datos, seguridad, banca. 40 capítulos + 5 simulaciones + 5 solucionarios | ✅ completo · sin laboratorio |
| [`02-monolito/`](02-monolito/README.md) | ¿Qué debe seguir unido y cuándo compensa distribuir? | 5 bloques, 33 capítulos, 794 preguntas de capítulo + 5 simulaciones | ✅ completo · talleres opcionales (10) |
| [`03-hexagonal/`](03-hexagonal/README.md) | ¿Qué no debe conocer el núcleo y cuánto cuesta la frontera? | 5 bloques, 30 capítulos, 720 preguntas de capítulo + 5 simulaciones | ✅ completo · talleres opcionales (11) |
| [`04-microservicios/`](04-microservicios/README.md) | ¿Con qué se implementa cada patrón y qué cambia entre plataformas? | 5 bloques, 30 capítulos, 745 preguntas de capítulo + 5 simulaciones | ✅ completo · talleres opcionales (11) |
| `05-event-driven/` | ¿Qué garantiza cada tramo cuando el contrato es el evento? | Guía, contrato de contenido y plan de producción; sin capítulos todavía | 🛠️ en preparación |
| `06-serverless/` | ¿Cuándo compensa pagar por invocación, y qué se entrega a cambio? | Guía, contrato de contenido y plan de producción; sin capítulos todavía | 🛠️ en preparación |
| `07-cqrs-event-sourcing/` | ¿Qué cuesta guardar los hechos en vez del estado, y durante cuántos años? | Alcance, guía, contrato de contenido, verificación previa y plan de producción; sin capítulos todavía | 🛠️ en preparación |
| `08-soa-integracion/` · `09-reactiva/` · `10-cell-multi-region/` | — | Carpetas reservadas, sin guía ni contenido | ⏳ [sin redactar](#-módulos-reservados) |

**Empieza por [`01-bases/`](01-bases/README.md).** Es el troncal: fija el vocabulario y el hábito
de cerrar cada concepto con un veredicto, y los otros tres lo dan por leído.

---

## 🧭 Orden de lectura

```text
01-bases           → cómo se razona una decisión y qué hay que saber de todo
    │
02-monolito        → la topología por defecto, bien hecha: módulos, límites, datos
    │
03-hexagonal       → cómo se organiza por dentro cada unidad (monolito o servicio)
    │
04-microservicios  → qué pasa cuando la unidad se parte y la red entra en juego
```

El orden sigue el de una conversación de arquitectura real: primero se decide, después se
protege lo que queda unido, y solo al final se distribuye. Los módulos 02–04 no dependen entre
sí para leerse, pero cada uno remite a los otros cuando un tema cambia de altitud.

**Recorridos cortos, según la entrevista:**

| Si la entrevista es de… | Ruta mínima |
|---|---|
| Backend Java en banca | [`01-bases/01-bases`](01-bases/01-bases/README.md) → [`01-bases/05-banca`](01-bases/05-banca/README.md) → [`01-bases/02-eventos`](01-bases/02-eventos/README.md) → simulaciones de [`02-monolito/05`](02-monolito/05-decision-evolucion-y-practica/README.md) y [`04-microservicios/03`](04-microservicios/03-datos-y-consistencia/README.md) |
| Arquitecto / system design | [`01-bases/01-bases`](01-bases/01-bases/README.md) → [`02-monolito/05`](02-monolito/05-decision-evolucion-y-practica/README.md) → [`04-microservicios/05`](04-microservicios/05-plataformas/README.md) (la matriz de decisión) |
| Microservicios, esta misma semana | Los tres capítulos que marca el [README de microservicios](04-microservicios/README.md): HTTP contra gRPC, saga y resiliencia |
| Diseño de código y testing | [`03-hexagonal`](03-hexagonal/README.md), bloques 01, 02 y 04 |

---

## 🔭 Un tema, varias altitudes

Los módulos se reparten por **altitud, no por tema**: el mismo concepto aparece en varios sin
duplicarse, porque cada uno lo mira desde una pregunta distinta.

| Tema | Decidir si lo quieres | Dentro de un despliegue | Implementado entre servicios |
|---|---|---|---|
| Monolito distribuido | [`01-bases/01-bases/02`](01-bases/01-bases/02-estilos-de-despliegue.md) | [`02-monolito/04`](02-monolito/04-monolito-distribuido/README.md) (bloque entero) | [`04-microservicios/01/04`](04-microservicios/01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md) |
| Capas, hexagonal, clean | [`01-bases/01-bases/03`](01-bases/01-bases/03-arquitecturas-de-aplicacion.md) | [`02-monolito/01/06`](02-monolito/01-fundamentos-y-modelo-mental/06-estilos-de-estructura-interna.md) · [`03-hexagonal`](03-hexagonal/README.md) | [`04-microservicios/01/05`](04-microservicios/01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md) |
| Transacciones y consistencia | [`01-bases/03-datos/02`](01-bases/03-datos/02-transacciones-y-bloqueo.md) | [`02-monolito/03/01`](02-monolito/03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md) · [`03-hexagonal/02/05`](03-hexagonal/02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md) | [`04-microservicios/03/03`](04-microservicios/03-datos-y-consistencia/03-saga.md) (saga) |
| Outbox e idempotencia | [`01-bases/02-eventos/06`](01-bases/02-eventos/06-outbox-y-cdc.md) | [`03-hexagonal/04/03`](03-hexagonal/04-adaptadores-de-salida-y-operacion/03-publicacion-de-eventos-y-outbox.md) | [`04-microservicios/03/04`](04-microservicios/03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) |
| Resiliencia | [`01-bases/01-bases/09`](01-bases/01-bases/09-resiliencia.md) | [`02-monolito/03/06`](02-monolito/03-datos-ejecucion-y-operacion/06-observabilidad-y-resiliencia-del-monolito.md) | [`04-microservicios/04/03`](04-microservicios/04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md) |
| Extraer un servicio | [`01-bases/01-bases/02`](01-bases/01-bases/02-estilos-de-despliegue.md) | [`02-monolito/05/04`](02-monolito/05-decision-evolucion-y-practica/04-extraer-un-modulo-a-servicio.md) · [`03-hexagonal/04/07`](03-hexagonal/04-adaptadores-de-salida-y-operacion/07-evolucion-y-migracion-desde-un-monolito.md) | [`04-microservicios/01/03`](04-microservicios/01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md) |

---

## 📐 Qué comparten y en qué difieren

Los cuatro módulos comparten la forma de estudiar:

```text
NN-tema.md         capítulo: el problema → el concepto con su veredicto → errores
                   frecuentes → referencias → preguntas SIN respuesta
NN-simulacion.md   preguntas transversales + escenarios de diseño
NN-respuestas.md   solucionario del bloque, con el enunciado copiado literal
README.md          índice, orden de lectura y qué NO está en el bloque
```

y las tres capas de cada respuesta: **⏱️ 30 segundos** (lo que dices primero), **🗣️ 2 minutos**
(lo que añades cuando piden más) y **🔬 el detalle** (para estudiar, no para recitar).

Lo que cambia entre módulos lo fija la guía de cada uno, que es normativa y manda sobre este
índice:

| Módulo | Guía | Eje de plataformas | Laboratorio |
|---|---|---|---|
| `01-bases` | [guía](01-bases/prompts/guia-de-estilo-y-convenciones.md), compartida por sus cinco bloques | Java y Spring como ancla | No hay |
| `02-monolito` | [guía](02-monolito/prompts/guia-de-estilo-y-convenciones.md) | Java · Node/TS · Go · Python donde el mecanismo cambia la decisión | [`06-talleres`](02-monolito/06-talleres/README.md): recuperar un monolito heredado |
| `03-hexagonal` | [guía](03-hexagonal/prompts/guia-de-estilo-y-convenciones.md) | Java · Node/TS · Go · Python | [`06-talleres`](03-hexagonal/06-talleres/README.md): cinco sabores + cuatro integraciones |
| `04-microservicios` | [guía](04-microservicios/prompts/guia-de-estilo-y-convenciones.md) | Java · Node/TS · Go · Python, siempre las cuatro filas | [`06-talleres`](04-microservicios/06-talleres/README.md): de monolito a servicios |

**Los talleres son opcionales en los tres módulos que los tienen.** Corren en local con Docker, sin
nube, y ningún capítulo ni simulación depende de ellos. Los tres comparten el caso de estudio
—pedidos, inventario, pagos y notificaciones—, así que se leen bien en secuencia: heredar y
modularizar un monolito en `02`, proteger el núcleo con puertos en `03` y partirlo en servicios en
`04`.

---

## ⏳ Módulos reservados

Las carpetas `08`–`10` existen para fijar la numeración, pero **no tienen guía, alcance acordado
ni contenido**; `05`, `06` y `07` ya tienen su guía y su plan, pero todavía no capítulos. Cada una lleva un README
que declara su estado y dice dónde se estudia hoy su tema dentro de los módulos ya escritos:

| Carpeta | Dónde se estudia hoy |
|---|---|
| `05-event-driven/` | [`01-bases/02-eventos`](01-bases/02-eventos/README.md) · [`04-microservicios/02/06`](04-microservicios/02-comunicacion/06-mensajeria-y-eventos.md) |
| `06-serverless/` | [`01-bases/01-bases/02`](01-bases/01-bases/02-estilos-de-despliegue.md) · cursos de [AWS](../cloud/01-aws/) y [GCP](../cloud/02-gcp/) |
| `07-cqrs-event-sourcing/` | [`01-bases/03-datos/06`](01-bases/03-datos/06-cqrs.md) · [`01-bases/02-eventos/07`](01-bases/02-eventos/07-event-sourcing.md) |
| `08-soa-integracion/` | [`01-bases/01-bases/02`](01-bases/01-bases/02-estilos-de-despliegue.md) · [`01-bases/05-banca/02`](01-bases/05-banca/02-mq-e-integracion.md) |
| `09-reactiva/` | [`frameworks/01-spring-boot/11`](../frameworks/01-spring-boot/11-webflux-y-reactor.md) y [`12`](../frameworks/01-spring-boot/12-reactivo-bloqueante-y-virtual-threads.md) |
| `10-cell-multi-region/` | [`01-bases/01-bases/10`](01-bases/01-bases/10-alta-disponibilidad-y-escalado.md) · [`01-bases/03-datos/05`](01-bases/03-datos/05-replicas-y-lag.md) |

---

## 🔗 Relación con el resto del repositorio

```text
arquitectura        → ¿qué decisión de sistema implica, y a qué precio?
apis y protocolos   → ¿qué obliga el protocolo, y dónde lo dice el RFC?
bases de datos      → ¿qué hace el motor por dentro?
frameworks          → ¿cómo se escribe con este framework?
cloud               → ¿cómo se despliega y cuánto cuesta por hora?
```

- [`bases/04-apis-protocolos`](../bases/04-apis-protocolos/) — la semántica de HTTP y lo que
  obliga cada RFC. Aquí se decide el estilo de comunicación; allí se cita la norma.
- [`bases/05-bases-datos`](../bases/05-bases-datos/) — el motor por dentro. Aquí se decide dónde
  vive el dato y qué garantía se conserva.
- [`frameworks/01-spring-boot`](../frameworks/01-spring-boot/) — Spring por dentro. Los módulos
  de arquitectura lo usan como plataforma, no lo enseñan.
- [`cloud/01-aws`](../cloud/01-aws/) · [`cloud/02-gcp`](../cloud/02-gcp/) ·
  [`cloud/03-azure`](../cloud/03-azure/) — la nube, con laboratorio. Los talleres de arquitectura
  no la usan, a propósito.
- [`preguntas-entrevista/`](../../preguntas-entrevista/) — bancos de ~100 preguntas con respuesta
  inline. Allí se repasa rápido; aquí se estudia con veredicto.
- `Entrevistas/` — material personal de búsqueda de empleo. **No se cita desde aquí**: este
  corpus está pensado para publicarse.
