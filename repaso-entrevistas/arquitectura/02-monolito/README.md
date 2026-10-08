# Arquitectura monolítica y monolito distribuido

Repaso en español para entrevistas de Backend Senior, Tech Lead y Arquitecto. Aprenderás a decidir qué debe permanecer unido, qué límite conviene proteger y cuándo distribuir compra autonomía suficiente para pagar red, datos repartidos y operación adicional.

El hilo conductor es una plataforma de comercio con `orders`, `inventory`, `payments` y `notifications`. La topología final no está predeterminada: puede conservar un despliegue o varias capacidades independientes según garantías y evidencia.

> **Vigencia:** 2026-09-29. · **Índice de arquitectura:** [`../README.md`](../README.md)
>
> Inventario completo, revisado y aceptado el 2026-09-29: **33 capítulos, 794 preguntas de capítulo, 5 simulaciones con 160 preguntas y 25 escenarios, y 5 solucionarios**. Son 51 documentos Markdown contando índices y los dos documentos de `prompts/`. Aparte, un bloque **opcional** de diez talleres con laboratorio (bloque 06).

## 🧭 Lectura lineal

| Bloque | Decisión principal | Capítulos |
|---|---|---:|
| [01 — Fundamentos y modelo mental](01-fundamentos-y-modelo-mental/README.md) | Distinguir unidad de despliegue, estructura interna y calidad | 6 |
| [02 — Modularidad y límites internos](02-modularidad-y-limites-internos/README.md) | Diseñar una API de módulo | 6 |
| [03 — Datos, ejecución y operación](03-datos-ejecucion-y-operacion/README.md) | Delimitar un commit | 7 |
| [04 — Monolito distribuido](04-monolito-distribuido/README.md) | Sostener un diagnóstico con evidencia combinada | 8 |
| [05 — Decisión, evolución y práctica](05-decision-evolucion-y-practica/README.md) | Comparar topologías por restricciones | 6 |

Lee capítulos, intenta sus preguntas y consulta después el solucionario. Los pies enlazan anterior, siguiente e índices; al terminar cada bloque puedes practicar su simulación antes de pasar al siguiente.

## 🔎 Consulta por decisión

| Necesitas decidir… | Empieza por… |
|---|---|
| Qué significa estar unido | [02 — Unidades de código, despliegue, ejecución y datos](01-fundamentos-y-modelo-mental/02-unidades-de-codigo-despliegue-ejecucion-y-datos.md) |
| Cómo organizar el código dentro de un módulo | [06 — Estilos de estructura interna: capas, clean, onion y vertical slice](01-fundamentos-y-modelo-mental/06-estilos-de-estructura-interna.md) |
| Dónde poner un límite interno | [01 — Módulos alrededor de capacidades de negocio](02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md) |
| Quién puede escribir un dato | [04 — Propiedad de datos en una base compartida](02-modularidad-y-limites-internos/04-propiedad-de-datos-en-una-base-compartida.md) |
| Qué confirmar atómicamente | [01 — Transacciones locales y límites de consistencia](03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md) |
| Cómo crecer sin partir por intuición | [04 — Rendimiento, caché y escalado](03-datos-ejecucion-y-operacion/04-rendimiento-cache-y-escalado.md) |
| Cómo cambiar el esquema y recuperar | [05 — Despliegues, migraciones de esquema y rollback](03-datos-ejecucion-y-operacion/05-despliegues-migraciones-de-esquema-y-rollback.md) |
| Si hay un monolito distribuido | [01 — Anatomía y evidencia del monolito distribuido](04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md) |
| Cómo liberar sin lockstep | [04 — Contratos frágiles y despliegues coordinados](04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md) |
| Qué hacer con un pago incierto | [05 — Fallos parciales, retries y falsas transacciones](04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md) |
| Si los eventos desacoplan de verdad | [06 — Acoplamiento asíncrono: el monolito distribuido con broker](04-monolito-distribuido/06-acoplamiento-asincrono-el-monolito-distribuido-con-broker.md) |
| Qué cortes fabrican un monolito distribuido | [07 — Cómo se llega: granularidad, entidades y plataforma compartida](04-monolito-distribuido/07-como-se-llega-granularidad-entidades-y-plataforma-compartida.md) |
| Cuándo fusionar procesos | [08 — Desmontar un monolito distribuido](04-monolito-distribuido/08-desmontar-un-monolito-distribuido.md) |
| Qué topología recomendar | [01 — Monolito, monolito modular o servicios: matriz de decisión](05-decision-evolucion-y-practica/01-monolito-monolito-modular-o-servicios-matriz-de-decision.md) |
| Cómo recuperar una costura del legado | [03 — Recuperar modularidad en un monolito legado](05-decision-evolucion-y-practica/03-recuperar-modularidad-en-un-monolito-legado.md) |
| Cómo extraer o cancelar una extracción | [04 — Extraer un módulo a servicio](05-decision-evolucion-y-practica/04-extraer-un-modulo-a-servicio.md) |
| Quién decide y opera | [05 — Equipos, ownership y gobernanza evolutiva](05-decision-evolucion-y-practica/05-equipos-ownership-y-gobernanza-evolutiva.md) |
| Cómo conducir una entrevista completa | [06 — Caso completo de system design y estrategia evolutiva](05-decision-evolucion-y-practica/06-caso-completo-de-system-design-y-estrategia-evolutiva.md) |

## 🎤 Simulador de entrevistas

Cada simulación contiene entre 30 y 35 preguntas: entre 20 y 25 transversales, 5 que descolocan y 5 asociadas a escenarios. Para una sesión de 45 minutos selecciona seis, dos y dos respectivamente; rota la selección para cubrir el banco. Declara supuestos y razona antes de abrir las respuestas.

- [07 — Simulación de entrevista: Fundamentos y modelo mental](01-fundamentos-y-modelo-mental/07-simulacion-de-entrevista.md) · [Respuestas](01-fundamentos-y-modelo-mental/08-respuestas.md)
- [07 — Simulación de entrevista: Modularidad y límites internos](02-modularidad-y-limites-internos/07-simulacion-de-entrevista.md) · [Respuestas](02-modularidad-y-limites-internos/08-respuestas.md)
- [08 — Simulación de entrevista: Datos, ejecución y operación](03-datos-ejecucion-y-operacion/08-simulacion-de-entrevista.md) · [Respuestas](03-datos-ejecucion-y-operacion/09-respuestas.md)
- [09 — Simulación de entrevista: Monolito distribuido](04-monolito-distribuido/09-simulacion-de-entrevista.md) · [Respuestas](04-monolito-distribuido/10-respuestas.md)
- [07 — Simulación de entrevista: Decisión, evolución y práctica](05-decision-evolucion-y-practica/07-simulacion-de-entrevista.md) · [Respuestas](05-decision-evolucion-y-practica/08-respuestas.md)

Las preguntas de capítulo usan 🟢 reconocimiento, 🟡 comparación y 🟠 decisión con incertidumbre. En el solucionario se reinicia la numeración por capítulo; la numeración S identifica las preguntas de cada simulación. Las capas ⏱️, 🗣️ y 🔬 son diagnóstico breve, desarrollo y matiz. Expande el desarrollo con el caso: no es un guion cronometrado.

## 🧪 Bloque 06 — Talleres (opcional)

[06 — Talleres](06-talleres/README.md) implementa el sistema de ejemplo como `mono-legacy`, un monolito Spring Boot escrito sin organización, y lo recupera en diez talleres con laboratorio local (Docker, sin nube): heredarlo sin documentación, caracterizarlo, darle contrato, probar contra la base real, modularizarlo, arreglar transacciones y concurrencia, escalarlo a dos instancias, migrar su esquema con *expand/contract* y, por último, distribuirlo para medir el daño y desmontarlo. **Ningún capítulo ni simulación depende de él.** Rutas: una tarde, `01 → 03 → 04`; Tech Lead Java, más `06` y `07`; arquitecto, más `10`. Tiene su solucionario propio, [11 — Respuestas](06-talleres/11-respuestas.md).

## 🛠️ Alcance técnico

Compara Java · Node/TypeScript · Go · Python donde sus mecanismos afectan la decisión. Los fragmentos son ejemplos didácticos; las versiones o límites se declaran donde se introducen. Los capítulos conceptuales explican por qué no necesitan código comparativo. No es un tutorial de framework, un curso completo de DDD ni una defensa de una topología universal.

## 📚 Contrato y verificación

- [Guía editorial](prompts/guia-de-estilo-y-convenciones.md): forma, vocabulario y preguntas.
- [Contrato de contenido](prompts/prompt-base.md): alcance de los 33 capítulos.

Para repetir el control estructural desde la raíz, ejecuta `python3 scripts/verificar_corpus.py`. Comprueba inventario, enlaces locales y anclas, preguntas literales, tres capas y escenarios obligatorios, y en los talleres el número de preguntas y ejercicios y su copia literal en el solucionario. No consulta la red ni revisa el contenido: las URLs externas se comprueban por código de estado y la revisión semántica se hace leyendo, antes de dar por cerrado un cambio.

## 🔗 Relación con el resto del repositorio

La frontera con los módulos hermanos es **de altitud, no de tema**: aquí la pregunta es qué debe
seguir unido y qué garantía se pierde al partir. El único prerrequisito es `01-bases`; el resto
son sugerencias de estudio, y nada de este módulo exige haberlas leído.

- [`arquitectura/01-bases`](../01-bases/README.md) — la teoría troncal. Su capítulo
  [`02` — Estilos de despliegue](../01-bases/01-bases/02-estilos-de-despliegue.md) sitúa el monolito
  entre los demás estilos; este módulo lo estudia entero.
- [`arquitectura/03-hexagonal`](../03-hexagonal/README.md) — cómo se organiza por dentro cada
  módulo. Aquí el estilo interno se elige ([`01/06`](01-fundamentos-y-modelo-mental/06-estilos-de-estructura-interna.md));
  allí se justifica frontera por frontera.
- [`arquitectura/04-microservicios`](../04-microservicios/README.md) — lo que viene después de
  extraer: los patrones entre servicios, implementados. Su capítulo
  [`01/04`](../04-microservicios/01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md)
  resume para la entrevista lo que el bloque 04 de aquí diagnostica desde dentro. Sus talleres
  comparten el caso de estudio con los de este módulo.
- [`bases/05-bases-datos`](../../bases/05-bases-datos/README.md) — el motor por dentro: aislamiento,
  bloqueos y planes que sostienen el bloque 03.
- [`frameworks/01-spring-boot`](../../frameworks/01-spring-boot/README.md) — Spring por dentro. Aquí es una
  de las cuatro plataformas.
- `preguntas-entrevista/` — bancos de ~100 preguntas con respuesta inline, incluidos
  [`01-poo-solid-patrones`](../../../preguntas-entrevista/01-poo-solid-patrones.md) y
  [`05-microservicios`](../../../preguntas-entrevista/05-microservicios.md). Allí se repasa rápido;
  aquí se estudia con veredicto.
- `Entrevistas/` — material personal de búsqueda de empleo. **No se cita desde aquí**: este corpus
  está pensado para publicarse.
