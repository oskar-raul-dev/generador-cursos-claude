# 🔬 Repaso de microservicios para entrevistas

> Corpus de repaso para entrevistas de **Backend Senior / Tech Lead / Arquitecto**. Cinco bloques con
> capítulos breves, bloques extensos de preguntas y un solucionario aparte — para que estudiar no sea
> leer la respuesta al lado de la pregunta —, y un sexto bloque, opcional, de talleres que se corren.
>
> **Vigencia:** 2026-09-29. · **Índice de arquitectura:** [`../README.md`](../README.md)

---

## Qué es esto, y qué no

```text
Un curso de microservicios  → te enseña el catálogo de patrones.
arquitectura/01-bases       → te enseña a decidir si los quieres.
Este repaso                 → te enseña a escribirlos, con qué librería,
                              y qué te cuesta en cada plataforma.
```

Es material de **repaso para entrevista**, no un curso. Por eso cada patrón cierra con un
**veredicto**, cada beneficio se nombra con su precio en las cinco monedas —latencia, consistencia,
operación, dinero y esfuerzo de implementación—, y cada capítulo trae la sección que casi ninguna
comparativa tiene: **qué te da hecho tu plataforma y qué te deja a ti**.

**Lo que queda fuera, declarado:** la decisión *monolito contra microservicios* y la teoría de
arquitectura ([`arquitectura/01-bases`](../01-bases/)); el monolito bien hecho —modular, con límites
internos— y el monolito distribuido visto desde dentro ([`arquitectura/02-monolito`](../02-monolito/));
la estructura interna de un servicio con puertos y adaptadores
([`arquitectura/03-hexagonal`](../03-hexagonal/)); la semántica
de HTTP y lo que obliga el RFC
([`bases/04-apis-protocolos`](../../bases/04-apis-protocolos/)); Spring por
dentro ([`frameworks/01-spring-boot`](../../frameworks/01-spring-boot/)); y Kubernetes y la nube
([`cloud/01-aws`](../../cloud/01-aws/) ·
[`cloud/02-gcp`](../../cloud/02-gcp/) · [`cloud/03-azure`](../../cloud/03-azure/)). Los cinco primeros bloques son teoría y evaluación; el
**laboratorio existe y es opcional**: el bloque [`06-talleres/`](06-talleres/) lleva el sistema de
ejemplo de un monolito a servicios en local y provoca los fallos que los capítulos describen.

---

## Los seis bloques

| Bloque | Qué cubre | Estado |
|---|---|---|
| [`01-fundamentos-y-descomposicion/`](01-fundamentos-y-descomposicion/) | Qué es un microservicio y cuándo no, descomposición y fronteras, el camino desde el monolito, el monolito distribuido, el servicio por dentro | ✅ **completo** — 8 documentos (con su README) |
| [`02-comunicacion/`](02-comunicacion/) | Estilos, HTTP entre servicios, gRPC, **HTTP contra gRPC**, WebSockets y SSE, mensajería y eventos, contratos y versionado | ✅ **completo** — 10 documentos (con su README) |
| [`03-datos-y-consistencia/`](03-datos-y-consistencia/) | Base de datos por servicio, consultas entre servicios, **saga**, **outbox e idempotencia**, evolución de esquema | ✅ **completo** — 8 documentos (con su README) |
| [`04-operacion-y-resiliencia/`](04-operacion-y-resiliencia/) | Descubrimiento, gateway y BFF, **resiliencia**, observabilidad y trazas, service mesh, despliegue, testing | ✅ **completo** — 10 documentos (con su README) |
| [`05-plataformas/`](05-plataformas/) | Qué cambia entre plataformas, Java, Node/TS, Go, Python, **la matriz de decisión** | ✅ **completo** — 9 documentos (con su README) |
| [`06-talleres/`](06-talleres/) · *opcional* | El sistema de ejemplo de monolito a servicios, en local: strangler fig, HTTP y gRPC, resiliencia, Kafka, trazas, **las dos sagas**, contratos, read models y SSE, con los fallos provocados | ✅ **completo** — 13 documentos (con su README) y el laboratorio en Java, Go y Python |

**Empieza por [`01-fundamentos-y-descomposicion/`](01-fundamentos-y-descomposicion/).** Fija el
vocabulario y el sistema de ejemplo que los otros cuatro dan por sabidos. Los talleres van **después** de
los cinco bloques, o en paralelo a partir de `02`: cada uno dice qué capítulos ejercita.

**Si tienes la entrevista esta semana**, ve directo a
[`02-comunicacion/04` — HTTP contra gRPC](02-comunicacion/04-http-contra-grpc.md),
[`03-datos-y-consistencia/03` — Saga](03-datos-y-consistencia/03-saga.md) y
[`04-operacion-y-resiliencia/03` — Resiliencia](04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).
Son los tres capítulos que más se preguntan.

---

## La aportación propia: cuatro plataformas

Casi todas las preguntas de este corpus tienen **cuatro respuestas**, y saber cuál da cada plataforma
es lo que se pregunta en una entrevista políglota. El eje es fijo y en este orden: **Java · Node/TS ·
Go · Python**.

| Plataforma | Papel en el corpus |
|---|---|
| **Java** | La plataforma del perfil base, y la que más te **da hecho** |
| **Node/TS** | El contraste de **runtime**: un hilo, bucle de eventos, contexto asíncrono |
| **Go** | El contraste de **filosofía**: casi nada viene hecho, y el patrón se ve desnudo |
| **Python** | El contraste de **modelo de ejecución**: asíncrono frente a procesos, y el GIL |

**Por qué no hay JavaScript.** Los frameworks de microservicios de ese ecosistema se escriben y se
documentan en TypeScript, así que una fila de JavaScript diría *"igual que TS"* en los treinta
capítulos. Lo que sí cambia la respuesta —bucle de eventos, un solo hilo, propagación de contexto— es
del **runtime de Node**, no del lenguaje, y entra como propiedad de la plataforma. De ahí la etiqueta
`Node/TS`.

---

## Baseline de versiones

| Plataforma | Baseline | Nota |
|---|---|---|
| Java | **25 LTS** | 21 LTS sigue siendo muy común en producción |
| Spring Boot | **4.1** | La línea 3.5 salió del soporte gratuito a mediados de 2026 |
| Node | **24 LTS** | La 26 pasa a LTS a finales de octubre de 2026 |
| Go | **1.27** | El proyecto mantiene las dos últimas versiones |
| Python | **3.14** | 3.13 sigue soportada y es lo más habitual en producción |

Se declara y se justifica en
[`05-plataformas/01`](05-plataformas/01-que-cambia-entre-plataformas.md), y se comprueba en
[endoflife.date](https://endoflife.date/) antes de citarla.

---

## Cómo está construido cada bloque

```text
NN-tema.md         capítulo: el problema → el patrón → 🧰 las cuatro plataformas
                   → comparativa → cómo se elige → errores frecuentes
                   → referencias → 24–26 preguntas SIN respuesta
NN-simulacion.md   preguntas S# transversales + escenarios de diseño
NN-respuestas.md   solucionario del bloque, con el enunciado copiado literal
README.md          índice, orden de lectura y qué NO está aquí
```

Cada respuesta del solucionario va en tres capas:

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
🔬 El detalle   → para estudiar, no para decir en voz alta
```

Los talleres siguen otra plantilla —recorrido de la base de código, provocaciones con su salida literal,
errores reales al correrlo, 14 o 15 preguntas y 8 ejercicios con la dificultad calibrada por taller— y
la fija §13 de la guía.

**61 documentos en total**: 58 en los seis bloques, el README del corpus y los dos de `prompts/`. **745 preguntas de capítulo con su
solucionario**, más 168 preguntas transversales y 25 escenarios de diseño resueltos en las cinco
simulaciones, y **244 enunciados de taller** (156 preguntas y 88 ejercicios) resueltos en
[`06-talleres/12`](06-talleres/12-respuestas.md).

---

## Reglas del corpus

Están en [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md), que
es normativa. Lo esencial:

- **Cada patrón se muestra implementado, no solo descrito**, y con su librería concreta.
- **Todo beneficio lleva su precio** en las cinco monedas, incluido el esfuerzo de implementación.
- **La tabla de las cuatro plataformas tiene siempre las cuatro filas**, y la columna que rinde es
  *"lo que te deja a ti"*.
- **Ninguna cifra de rendimiento sin decir de dónde sale y qué no mide.**
- **Ninguna librería se nombra sin haber comprobado que existe y se mantiene.**
- **Las respuestas viven en un solo archivo por bloque**, con el enunciado copiado literal.
- **No se inventan URLs**, y las que se escriben se comprueban por código de estado.

El contenido obligatorio de cada documento está en
[`prompts/prompt-base.md`](prompts/prompt-base.md).

---

## Relación con el resto del repositorio

La frontera con los corpus hermanos es **de altitud, no de tema**: los cuatro pueden hablar de
idempotencia sin duplicarse. El único prerrequisito es `arquitectura/01-bases`; el resto son
sugerencias de estudio, y nada de este corpus exige haberlas leído.

```text
arquitectura        → ¿qué decisión de sistema implica, y a qué precio?
apis y protocolos   → ¿qué obliga el protocolo, y dónde lo dice el RFC?
spring              → ¿cómo se escribe con este framework?
microservicios      → ¿qué patrón es, con qué se implementa en cada plataforma,
                      y qué cambia entre ellas?
```

- [`arquitectura/01-bases`](../01-bases/) — la decisión y la teoría.
  Este corpus la **asume tomada**.
- [`arquitectura/02-monolito`](../02-monolito/) — la alternativa que este corpus da por descartada, bien
  hecha: el monolito modular, sus límites internos y cómo se extrae un módulo cuando la extracción se
  paga. Su bloque `04-monolito-distribuido` diagnostica desde dentro lo que
  [`01/04`](01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md) resume para la entrevista.
- [`arquitectura/03-hexagonal`](../03-hexagonal/) — cómo se organiza **por dentro** un servicio. Aquí
  la estructura interna se usa ([`01/05`](01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md));
  allí se justifica, y sus talleres la implementan con el mismo caso de estudio que el bloque 06.
- [`bases/04-apis-protocolos`](../../bases/04-apis-protocolos/) — la semántica
  del protocolo.
- [`frameworks/01-spring-boot`](../../frameworks/01-spring-boot/) — Spring por dentro. Aquí Spring es
  **una de las cuatro plataformas**.
- [`preguntas-entrevista/`](../../../preguntas-entrevista/) — bancos de ~100 preguntas con respuesta
  inline, incluidos [`05-microservicios`](../../../preguntas-entrevista/05-microservicios.md) y
  [`06-patrones-microservicios`](../../../preguntas-entrevista/06-patrones-microservicios.md). Allí se
  repasa rápido; aquí se estudia con veredicto e implementación.
- `Entrevistas/` — material personal de búsqueda de empleo. **No se cita desde aquí**: este corpus
  está pensado para publicarse.
