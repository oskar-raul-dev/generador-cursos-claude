# Curso de RAG en 10 semanas — versión comprimida

> Complemento práctico de un curso de IA existente.
> Derivado del documento maestro de 65 guías (38–43 semanas).

---

## 1. Ficha del curso

| Parámetro | Valor |
|---|---|
| Duración | 10 semanas |
| Dedicación semanal | 5–6 h |
| Carga total | ~55 h |
| Stack | Python + Ollama + ChromaDB |
| Referencia de infraestructura | Java 21 + Spring AI + pgvector (semana 10, solo lectura) |
| Proyecto | Asistente documental con citas y abstención |
| Hito crítico | Semana 5 (RAG funcional end-to-end) |
| Prerrequisitos | Programación en cualquier lenguaje, terminal, conocimiento básico de LLM |

---

## 2. Objetivo del curso

Tienes un sistema RAG **funcionando, inspeccionable y medible**, y el criterio para justificar cada parámetro. No es un chatbot. Es un pipeline que:

```
documento → fragmentación → embeddings → búsqueda → 
recuperación de evidencia → generación con citas → abstención si procede
```

Cuando termines vas a poder explicar sin notas por qué cada decisión de chunking, top-K o modo de recuperación es la que es, porque la mediste.

---

## 3. Decisiones de compresión

El documento maestro estima 206–248 h. Acá tenemos 55 h. La compresión no fue uniforme: cortamos de forma selectiva.

### 3.1 Dónde estaba el peso real

Contraintuitivamente, el volumen no está en los conceptos de RAG sino en **la infraestructura Java**. Spring Boot, Flyway, Testcontainers, Docker Compose y API REST suman ~40 h de trabajo que te enseña Spring, no RAG. 

Cuando movemos el proyecto a Python, los mismos conceptos se aprenden con una fracción del andamiaje. La ecuación cambia: gastas 10 h menos en infraestructura y ganas 10 h de claridad conceptual.

### 3.2 Cómo se recortó cada bloque

Los fundamentos teóricos (12 guías) se conservan pero fusionan en 5 sesiones que aún cubren todo lo conceptual. El proyecto (20 guías) se implementa en Python tal cual, solo que sin Spring. La recuperación avanzada se reduce a lo que señala ganancia medible: hybrid search, RRF y reranking sí; parent-child retrieval, compresión de contexto y multi-query no.

Producción y seguridad pasan de implementación a panorámica: vas a conocer el criterio (por qué existe seguridad documental, qué es prompt injection) pero no vas a escribir código de eso en 10 semanas. Evaluación sobrevive, pero en versión mínima: dataset + Hit Rate + Precision@K + abstención correcta. Es lo indispensable para no especular.

### 3.3 Qué cambió de pedagogía

El documento original pide que implementes cada pieza desde cero. Con 55 h es imposible sin perder cobertura conceptual. Aquí el criterio es distinto.

Implementas lo que genera criterio: fragmentación configurable, cálculo manual de similitud, construcción del prompt, lógica de citas, regla de abstención, fusión de rankings, cálculo de métricas. Son las piezas donde el "por qué" importa.

Recibes listo el andamiaje que solo come tiempo: lectura de archivos, CLI, argumentos, formateo de salida, parseo de PDF. No te enseña nada nuevo de RAG; solo te ralentiza.

### 3.5 Qué no cabe (y dónde aparece igual)

Fuera de alcance: Java y Spring AI como stack de implementación (semana 10 es lectura), PostgreSQL y pgvector con todas sus migraciones, API REST y contenedorización, ingestión asíncrona y reintentos, seguridad documental implementada, multitenancy, parent-child retrieval, multi-query, pruebas de regresión.

Estos temas los mencionas en la semana 10 como panorámica (vas a conocer el criterio y los trade-offs), pero no los implementas. Es deuda explícita: el curso es "para pasar de cero a funcionando"; la producción es el siguiente paso.

---

## 4. Estructura de cada semana

Tres sesiones: teoría (1.5 h) → laboratorio (1.5 h) → proyecto (2.5 h), que suman 5.5 h.

La sesión 1 te presenta el concepto, el mecanismo, los trade-offs. La sesión 2 te propone un experimento pequeño donde ves la idea funcionando en aislamiento, sin todo el peso del proyecto. La sesión 3 es la integración al sistema que vas construyendo semana a semana.

Si una semana se estrecha por tiempo, se recorta el laboratorio, nunca el proyecto. Sin la sesión 2 pierdes claridad; sin la sesión 3 no avanzas.

---

## 5. Stack

### Stack de trabajo (semanas 1–9)

Python 3.11+, Ollama, ChromaDB. Eso es todo. `embeddinggemma` es tu modelo de embeddings local; `gemma3:4b` es el generador de texto.

No usamos LangChain ni LlamaIndex. El motivo no es purismo: estos frameworks ocultan exactamente los mecanismos que el curso quiere hacerte visible. Necesitas ver qué se calcula y por qué.

### Stack de referencia (semana 10)

Java 21 + Spring Boot + Spring AI, PostgreSQL + pgvector. Esa semana los estudias como lectura y comparas el pipeline Python con su equivalente en Java. No los implementas.

### Antes de empezar

Instala Python 3.11+, Ollama y las dependencias mínimas:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U chromadb ollama numpy
```

Descarga los modelos (10–15 min):

```bash
ollama pull embeddinggemma
ollama pull gemma3:4b
```

---

## 6. Proyecto conductor

Asistente documental que responde preguntas citando las políticas de una empresa. El corpus inicial son tres documentos ficticios: `vacaciones.md`, `trabajo_remoto.md`, `gastos.md`.

Con una trampa intencional: **no hay política de licencia de maternidad**. La pregunta "¿cuántas semanas de licencia de maternidad tiene la empresa?" debe producir abstención desde la semana 5 hasta el final. Es tu prueba de regresión permanente.

Semana a semana el sistema evoluciona. En la semana 1 es un script que pregunta al LLM sin recuperación (para ver que alucina). En la semana 2 fragmentas documentos. En la semana 3 los conviertes en vectores. En la semana 4 recuperas semánticamente. **En la semana 5 tienes RAG completo**: respuesta + citas + abstención. Las semanas 6–8 lo refinan. En la semana 9 lo mides. En la semana 10 lo entregas con documentación.

---

## 7. Recorrido de las 10 semanas

| Sem | Se aprende | Código |
|---:|---|---|
| 1 | LLM, contexto, por qué RAG resuelve | Script de demostración |
| 2 | Chunking, metadatos, fragmentación configurable | Fragmentador |
| 3 | Embeddings, similitud coseno, vectores | Comparador manual |
| 4 | Vector store, recuperación, top-K | Búsqueda inspeccionable |
| **5** | **Grounding, citas, abstención** | **RAG funcional** |
| 6 | Fallos por etapa, chunking estructural, diagnóstico | Ingestión multiformato |
| 7 | Búsqueda sparse, dense, híbrida, RRF | Retriever híbrido |
| 8 | Query rewriting, reranking, conversación | Pipeline refinado |
| 9 | Dataset, métricas, evaluación | Hit Rate, Precision@K |
| 10 | Producción y equivalentes en Java | Documentación |

---

# 8. Desarrollo semana por semana

---

## Semana 1 — Qué resuelve RAG

### Sesión 1 — Teoría (1.5 h)

Empiezas con un LLM local (`gemma3:4b`). El modelo conoce lo que aprendió durante entrenamiento, pero nada de tu dominio específico. Haces una pregunta sobre una política interna de la empresa: con cuánta anticipación hay que solicitar vacaciones, por ejemplo. El modelo alucina. Inventa una respuesta que suena plausible pero es falsa.

RAG resuelve exactamente eso: en lugar de esperar que el modelo adivine, recuperas de antemano los fragmentos relevantes y se los entregas en el prompt. El modelo ya no alucina porque tiene la evidencia.

Pero hay un detalle crítico. Si pegas **todos** los documentos en el prompt de una sola vez, pasa otra cosa: el costo en tokens sube, la latencia se dispara y la respuesta se diluye entre ruido. RAG no es "meter todo" en el prompt. Es **seleccionar previamente** qué fragmentos caben y qué importan.

Eso requiere dos pipelines distintos. El pipeline de ingestión corre una sola vez cuando cargas documentos: lee, fragmenta, genera embeddings, guarda en una base de datos vectorial. El pipeline de consulta corre en cada pregunta: toma la pregunta, la convierte en embedding, recupera los fragmentos más próximos, construye un prompt y genera respuesta. Los documentos nunca se reindexan; solo se consultan.

### Sesión 2 — Laboratorio (1.5 h)

Tres experimentos sobre el mismo modelo local:

**Experimento 1.** Pregunta al modelo algo que desconoce:  ¿Con cuánta anticipación solicito vacaciones? El modelo inventa.

**Experimento 2.** Repite la pregunta, pero ahora pega el documento de política de vacaciones completo en el prompt. Ahora responde correctamente.

**Experimento 3.** Repite pegando veinte documentos irrelevantes. Observa tres cosas: la latencia sube (más tokens que procesar), la respuesta se vuelve vaga o incorrecta (el modelo se pierde en el ruido), y aumenta el costo (cada token procesado pesa). Eso es la trampa de no seleccionar.

### Sesión 3 — Proyecto (2.5 h)

Inicializas el repositorio. Defines el corpus: tres archivos markdown ficticios (`vacaciones.md`, `trabajo_remoto.md`, `gastos.md`). Escribes un script Python mínimo que pregunta al LLM sin recuperación.

Documentas las tres observaciones del laboratorio en `NOTES.md`.

### Criterio de finalización

Explicas sin notas por qué "meter todo en el prompt" no escala, y tu argumento no es solo "porque alcanzamos la ventana de contexto" sino "porque la dilución de señal es peor que el truncamiento".

---

## Semana 2 — Chunking

### Sesión 1 — Teoría (1.5 h)

Un documento completo es una unidad demasiado grande y demasiado genérica para recuperación. Si tus documentos son manuales de 50 páginas, no tiene sentido devolver el manual completo cada vez que una consulta pide una cifra específica.

Entonces fragmentas. Pero fragmentar bien es un arte. Demasiado pequeño y los fragmentos pierden su contexto: una regla sobre vacaciones separada de las condiciones que la acompañan. Demasiado grande y mezclas conceptos que no tienen relación, cargando de ruido cada recuperación.

Hay varias estrategias: tamaño fijo en palabras, tokens, párrafos, encabezados, o estructura semántica (cuando entiendas que una sección lógica termina). La que elige este curso es tamaño fijo con overlap: conservas un porcentaje del fragmento anterior al siguiente para no cortar ideas a media frase.

Los metadatos importan: fuente, sección, posición dentro del documento. Son la trazabilidad que necesitarás después cuando generes citas.

### Sesión 2 — Laboratorio (1.5 h)

Implementas `split_text(text, chunk_size, overlap)` en Python. Sin librerías; es código de 20 líneas.

Luego pruebas sobre el documento de vacaciones con tres configuraciones:

| Tamaño (palabras) | Overlap | Resultado |
|---:|---:|---|
| 30 | 0 | Reglas cortadas; pierdes la lógica |
| 80 | 20 | Base razonable |
| 300 | 50 | Fragmentos que mezclan varios temas |

Analiza: ¿en cuál configuración el fragmento con "30 días de anticipación" se parte de la frase que explica por qué?

### Sesión 3 — Proyecto (2.5 h)

Lees archivos `.txt` y `.md` desde disco. Cada fragmento tiene una estructura: texto, fuente, número de posición, hash estable como ID. Volcas todo a JSON para inspeccionarlo visualmente.

### Criterio de finalización

Tienes un fragmentador configurable y puedes justificar tu elección (chunk_size=80, overlap=20) con un ejemplo del corpus que muestra por qué funciona.

---

## Semana 3 — Embeddings y similitud

### Sesión 1 — Teoría (1.5 h)

Un embedding es la conversión de texto a un vector de números reales. La frase "solicitar vacaciones" se convierte en algo como `[0.12, -0.38, 0.05, ...]`. Cada número representa un aspecto del significado (aunque no son tan legibles como eso; es una representación estadística).

El milagro es que textos con significados próximos ocupan regiones cercanas del espacio vectorial. La pregunta "¿cómo pido mis días libres?" y la frase "solicitar vacaciones" tendrán vectores cercanos, aunque no compartan palabras. El modelo de embeddings aprendió eso durante entrenamiento.

Hay varias medidas de proximidad en el espacio vectorial: similitud coseno (la más común), dot product, distancia euclidiana. Todas responden lo mismo: qué tan cerca están dos vectores.

Un detalle importante: el modelo de embeddings y el modelo generativo son piezas distintas. El embedding convierte texto en vector para la búsqueda; el generativo toma el texto recuperado y genera la respuesta. No es un solo modelo.

### Sesión 2 — Laboratorio (1.5 h)

Generas embeddings localmente (con `ollama.embed`) para un conjunto pequeño de frases y calculas la similitud coseno a mano con numpy, sin tocar ningún vector store. Esto es importante: ves el mecanismo puro.

Frases de prueba:

```
"solicitar vacaciones"
"pedir días libres"
"proceso de reembolso de gastos"
"factura electrónica"
"política de trabajo remoto"
```

Armas la matriz de similitud y verificas: las dos primeras frases deberían estar cerca pese a no compartir palabras. Las dos últimas deberían estar lejos.

Luego buscas un contraejemplo: dos frases que la intuición te dice que deberían ser similares pero no lo son, o al revés.

### Sesión 3 — Proyecto (2.5 h)

Generas embeddings en lote para todos los fragmentos del corpus. Guardas tanto el embedding como sus metadatos. Mides el tiempo que tarda (es importante saber cuánto cuesta indexar).

### Criterio de finalización

Calculas similitud coseno sin librerías (solo numpy) y explicas por qué "pedir días libres" queda próximo a "solicitar vacaciones" aunque no compartan palabras.

---

## Semana 4 — Vector store y recuperación

### Sesión 1 — Teoría (1.5 h)

Un vector store almacena embeddings con sus fragmentos originales, metadatos y IDs. Cuando preguntas algo, el sistema convierte tu pregunta en un embedding, busca los vecinos más cercanos en el espacio vectorial y devuelve los fragmentos asociados.

Top-K es el número de resultados que recuperas: cuántos fragmentos devuelves antes de pasar al generador. K=3 significa "dame los tres más cercanos". No hay un valor mágico: K pequeño puede omitir evidencia relevante (falta cobertura); K grande introduce ruido (dilución de contexto).

Hay también umbrales de distancia: un fragmento tan lejano que su similitud es dudosa no debería recuperarse, aunque sea el tercero.

ChromaDB es la opción que usamos. Hay alternativas profesionales (pgvector, Qdrant, Milvus, FAISS), pero para aprender el mecanismo ChromaDB tiene la ventaja de cero configuración.

### Sesión 2 — Laboratorio (1.5 h)

Indexas el corpus en ChromaDB y haces consultas variando K: 1, 3, 5, 10. Para cada una registras qué fragmento recuperaste, de cuál documento viene y qué distancia tiene.

Analiza: ¿a partir de cuál K empiezan a aparecer fragmentos que claramente no son relevantes? ¿Qué distancia tienen?

### Sesión 3 — Proyecto (2.5 h)

Pipeline completo: lees documentos → los fragmentas → generas embeddings → los guardas en ChromaDB. Luego escribes un comando de inspección que toma una pregunta y te muestra qué recuperó, con distancias visibles.

Este comando es crucial: lo vas a usar todas las semanas siguientes para diagnosticar dónde se rompen las cosas.

### Criterio de finalización

Existe un comando tipo `query("¿cuántos días de vacaciones tengo?")` que imprime qué recuperó, de dónde viene y con qué distancia, sin que intervenga ningún LLM todavía.

---

## Semana 5 — Grounding, citas y abstención · **PUNTO DE PARADA**

### Sesión 1 — Teoría (1.5 h)

Ahora integras la generación. El pipeline es: recuperas fragmentos → construyes un prompt que incluye esos fragmentos → el LLM ve el prompt y responde.

El prompt tiene tres partes: primero las instrucciones (qué debe y no debe hacer), luego el contexto (los fragmentos recuperados, numerados), luego la pregunta.

Grounding es la instrucción crítica: obligas al modelo a responder solo con lo que ve en los fragmentos. Sin grounding responderá con su conocimiento de entrenamiento (y alucinará).

Citas son trazabilidad: cada afirmación en la respuesta debe poder volver a la fuente. Cuando el LLM responde "30 días de anticipación [Fuente 1]", queda claro de dónde viene.

Abstención es la característica que separa un sistema profesional de una demo. Si la pregunta es "¿cuál es la política de licencia de maternidad?" y el corpus no contiene esa política, la respuesta correcta es "No encuentro esa información" no una alucinación.

### Sesión 2 — Laboratorio (1.5 h)

Haces un experimento: la misma pregunta, tres versiones del prompt.

**Versión 1.** Sin instrucción de grounding. El modelo ve los fragmentos pero ninguna regla sobre usarlos exclusivamente. Responde con su conocimiento.

**Versión 2.** Con grounding explícito. Ahora sí queda restringido.

**Versión 3.** Con grounding + obligación de citar.

Luego el experimento decisivo: preguntas por la licencia de maternidad (que no está en el corpus) con cada variante. ¿Cuál inventa? ¿Cuál se abstiene realmente?

### Sesión 3 — Proyecto (2.5 h)

Integras el generador al sistema. Fragmentos recuperados → prompt formateado → llamada al LLM → respuesta procesada para extraer citas → salida.

Pruebas con cuatro preguntas:

1. "¿Con cuánta anticipación solicito vacaciones?" → Recupera, responde, cita.
2. "¿Cuántos días puedo trabajar remoto?" → Recupera, responde, cita.
3. "¿Necesito factura para 350.000 pesos de gasto?" → Requiere interpretar "mayor a 200.000", igual responde.
4. "¿Cuál es la política de licencia de maternidad?" → **No se abstiene porque sí; se abstiene porque el corpus no contiene esa información y el prompt se lo exige.**

### Criterio de finalización

Las cuatro preguntas funcionan como se espera, incluida la abstención verificable. **Esto es el final de la "versión mínima viable". De aquí en adelante todo es refinamiento.**

No continúes a la semana 6 si esto no funciona. No es un checkpoint: es un punto de parada.

---

## Semana 6 — Corpus real y diagnóstico de fallos

### Sesión 1 — Teoría (1.5 h)

Un sistema RAG puede romperse en siete etapas distintas, y el síntoma es el mismo: respuesta mala. El problema es identificar dónde.

Parsing: sacaste mal el texto del PDF. Chunking: cortaste una regla a mitad de frase. Embedding: usaste un modelo no alineado al idioma. Retrieval: no recuperaste el fragmento correcto. Ranking: recuperaste el correcto pero en posición 9. Prompt: el fragmento está ahí pero mal presentado. Generación: el fragmento es perfecto pero el LLM no lo leyó bien.

Sin inspección en cada etapa te quedas adivinando. Por eso construiste el comando de inspección en la semana 4.

Chunking estructural es un refinamiento: en lugar de trocear por número de palabras, divides por encabezados y secciones del documento. Respeta la estructura lógica.

### Sesión 2 — Laboratorio (1.5 h)

Te doy tres casos de fallo ya preparados. Diagnosticas en qué etapa se rompe cada uno usando el comando de inspección y las herramientas que ya tienes.

### Sesión 3 — Proyecto (2.5 h)

Amplías el corpus a documentos reales (o más cercanos a ello). Implementas lectura de PDF con estructura de encabezados. Chunking estructural: si el PDF tiene una sección de "Vacaciones", esa sección no se parte arbitrariamente a las 80 palabras; termina cuando empieza la siguiente.

Volcas el prompt final a un archivo para poder inspeccionarlo cuando la respuesta es mala.

### Criterio de finalización

Te presento una respuesta incorrecta; identificas la etapa de fallo en menos de cinco minutos sin adivinar.

---

## Semana 7 — Recuperación híbrida

### Sesión 1 — Teoría (1.5 h)

Dense retrieval (embeddings) es excelente para semántica: "pedir días libres" y "solicitar vacaciones" son próximos aunque no compartan palabras. Sparse retrieval (búsqueda textual, índices invertidos) es brutal con exactitud: un código como "ISO-27001" se recupera porque la palabra existe.

Dense falla cuando necesitas un código exacto: el embedding lo diluye. Sparse falla cuando necesitas semántica: "¿cómo obtengo licencia?" no recupera "solicitar vacaciones" porque no hay overlap de palabras.

Híbrido los combina: ejecutas ambas búsquedas y fusionas los resultados. Reciprocal Rank Fusion es una forma sencilla de hacerlo sin necesidad de normalizar puntajes.

### Sesión 2 — Laboratorio (1.5 h)

Diseñas consultas que rompen cada método. "¿cómo solicito mis días libres?" debería fallar con sparse (no comparte palabras). "Política ISO-27001 sección 4.2" debería fallar con dense (el código se disuelve). Ejecutas ambas consultas con denso, con sparse, y observas.

### Sesión 3 — Proyecto (2.5 h)

Implementas búsqueda textual sobre el corpus (PostgreSQL full-text o un índice simple). Implementas RRF para fusionar rankings. El sistema ahora tiene tres modos: `"dense"`, `"sparse"`, `"hybrid"`. Comparas los tres sobre tus consultas de prueba.

### Criterio de finalización

Muestras un caso donde híbrido recupera algo que dense o sparse solos no recuperan.

---

## Semana 8 — Query rewriting, reranking y conversación

### Sesión 1 — Teoría (1.5 h)

La pregunta del usuario "¿cómo puedo pedir un día libre extra?" es coloquial y a veces ambigua. Una búsqueda vectorial directa pierde precisión. Query rewriting la normaliza: "solicitar día feriado" o "política de vacaciones". Eso recupera mejor.

Reranking es una segunda etapa: recuperas 20 candidatos rápidamente, luego un modelo más preciso ordena los mejores 5. El retriever prioriza velocidad; el reranker prioriza exactitud.

RAG conversacional es resolver "¿y si es desde otro país?" usando el turno anterior ("¿puedo trabajar remoto?") para transformarlo en una consulta autónoma.

### Sesión 2 — Laboratorio (1.5 h)

Reescribes cinco preguntas coloquiales y compruebas qué recupera cada versión. Luego experimentas con reranking: tomas 15 candidatos, pides al LLM que los ordene por relevancia, y comparas con el orden original.

### Sesión 3 — Proyecto (2.5 h)

Integras reescritura y reranking al pipeline. Añades resolución de preguntas de seguimiento: el sistema recuerda la pregunta anterior y usa eso para desambiguar la nueva. Mides cuánta latencia añade cada mejora.

### Criterio de finalización

Una pregunta de seguimiento ambigua ("¿y si es desde otro país?") se resuelve correctamente, y tienes números: qué mejora ganó Hit Rate y cuánta latencia costó.

---

## Semana 9 — Evaluación

### Sesión 1 — Teoría (1.5 h)

Sin dataset, toda mejora es superstición. Cuando afirmas que el reranking ayudó, ¿lo mediste o lo asumiste?

Necesitas preguntas reales, respuestas esperadas, y fragmentos que deberían recuperarse. Al menos un 20% de las preguntas deben exigir abstención (la trampa de maternidad y otras).

Métricas de recuperación: Hit Rate (¿apareció el fragmento correcto?), Precision@K (¿cuánto de lo que recuperaste servía?), Recall@K (¿cuánto de lo relevante encontraste?), MRR (¿en qué posición apareció lo correcto?).

Métricas de respuesta: ¿la respuesta es correcta? ¿Cita bien? ¿Se abstiene cuando debe? ¿Inventa cuando no debería?

### Sesión 2 — Laboratorio (1.5 h)

Construyes un dataset de 20–25 preguntas sobre el corpus, incluidas cinco o seis que piden abstención. Implementas Hit Rate y Precision@3.

### Sesión 3 — Proyecto (2.5 h)

Ejecutas el dataset contra todas tus configuraciones acumuladas: dense vs. híbrido, diferentes chunk sizes, con y sin reranking. Produces una tabla de números reales. Si una mejora no sale reflejada en las métricas, la reviertes.

### Criterio de finalización

Existen números verificables, y al menos una decisión cambió por ellos (dejaste de usar una técnica o cambiaste un parámetro porque las métricas lo pedían).

---

## Semana 10 — Producción, Spring AI y cierre

### Sesión 1 — Teoría (1.5 h)

Panorámica de producción sin implementación. Criterios que debes conocer aunque no los implementes.

Seguridad documental: el filtro de permisos va en el retrieval, nunca pegado en el prompt. Prompt injection: los documentos son datos no confiables; un PDF malicioso puede contener instrucciones que cambian el comportamiento. Información sensible: clasificación, minimización, retención. Observabilidad: qué necesitas registrar para debuggear después. Rendimiento: dónde cachear, qué procesar por lotes. Portabilidad: no acoplar el dominio al proveedor.

### Sesión 2 — Laboratorio (1.5 h)

Lectura comparativa: tu pipeline en Python vs. su equivalente en Java + Spring AI. Qué es `split_text()` en Spring, qué es `ollama.embed()` con Spring AI, cómo se vería ChromaDB reemplazado por PostgreSQL + pgvector.

Experimento de prompt injection: añades una instrucción maliciosa dentro de un documento del corpus y observas si el sistema la ejecuta o si el grounding la bloquea.

### Sesión 3 — Proyecto (2.5 h)

Entregas. `README.md` con arquitectura, instrucciones para reproducir, decisiones (chunking, topK, modo de recuperación y por qué). ADR breve sobre cada decisión. Reporte de métricas de la semana 9. Demo funcional sobre las cuatro preguntas de prueba. Lista honesta de limitaciones.

### Criterio de finalización

Un tercero puede clonar, ejecutar, y entender por qué cada parámetro tiene su valor. No porque adivine: porque está documentado.

---

## 9. Puntos de control y paradas

En la semana 5 hay una parada deliberada. Si RAG funcional no está, no continúes. Las semanas 6–10 asumen un sistema completo.

Semana 2: fragmentador. Semana 4: inspección de retrieval. **Semana 5: RAG end-to-end con citas y abstención.** Semana 7: híbrido. Semana 9: números reales. Semana 10: documentado.

---

## 10. Después del curso

Al terminar tienes un sistema RAG completo y entendible. El siguiente paso depende de tu contexto.

Corto plazo (4–6 semanas): migra a Java + Spring AI + pgvector, añade API REST, contenedoriza con Docker.

Medio plazo (6–10 semanas): parent-child retrieval, multi-query, ingestión asíncrona, seguridad documental real.

Largo plazo: multimodal RAG, Graph RAG, agentic RAG, tool calling, multitenancy.

Pero no antes de tener esto funcionando y medido. La tendencia es complicar sin entender qué está roto. Resiste eso.

---

## 11. Prompts para generar cada semana

### Guía completa de una semana

```
Desarrolla la semana [N] del curso comprimido de RAG:

[TEMA]

Contexto: Python + Ollama + ChromaDB, 10 semanas, 5.5 h semanales.
Proyecto: asistente documental con citas y abstención.
Estudiante: experiencia en programación, no en IA.

Estado actual: [LO QUE EXISTE HASTA SEMANA N-1]

Estructura:
1. Sesión 1 — Teoría (1.5 h): problema, concepto, intuición, mecanismo.
2. Sesión 2 — Laboratorio (1.5 h): experimento aislado, código ejecutable,
   qué observar, preguntas de análisis.
3. Sesión 3 — Proyecto (2.5 h): código real, cambios al repositorio,
   criterio de finalización.

Usa prosa, no listas. Tuteo, español latinoamericano.
Incluye diagramas ASCII cuando aporten.
No adelantes conceptos de semanas futuras.
El criterio de salida debe ser verificable.
```

---

## 12. Resumen ejecutivo

| Aspecto | Maestro | Comprimido |
|---|---:|---:|
| Duración | 38–43 semanas | 10 semanas |
| Horas totales | 206–248 h | ~55 h |
| Stack principal | Java + Spring AI | Python |
| RAG funcional | Semana 18 | **Semana 5** |
| Cobertura conceptual | 100 % | ~60 % |

Se conserva el criterio (por qué cada decisión, cómo medir). Se sacrifica ingeniería de producción (seguridad, observabilidad, escalabilidad implementada), que es un siguiente paso.


---

## 13. Referencias

Advertencia previa, y va en serio: **URLs, títulos, ediciones y contenidos de video cambian**. Todo lo de abajo estaba vigente a la fecha de consulta (agosto de 2026) pero conviene verificarlo antes de comprar nada o de citarlo en un trabajo. No cito números de página ni minutajes porque no puedo garantizarlos; cito capítulo o sección, que es lo que sí se sostiene entre ediciones.

Las herramientas del stack (Ollama, ChromaDB, Spring AI) cambian rápido. Para ellas la regla es una sola: **documentación oficial, nunca tutoriales viejos**.

### 13.1 Bibliografía

**Fuente principal para recuperación.** Manning, Raghavan y Schütze, *Introduction to Information Retrieval* (Cambridge University Press). Está completo y gratis en `nlp.stanford.edu/IR-book`. Es de 2008 y no menciona embeddings densos, lo que parece descalificarlo — no lo hace: los capítulos de indexación, modelo vectorial, evaluación (precision, recall, MRR) y ranking son exactamente la base conceptual que las semanas 4, 7 y 9 dan por sabida. Es el libro que explica *por qué* Precision@K significa algo. **[GRATIS]**

**Para la parte de lenguaje.** Jurafsky y Martin, *Speech and Language Processing*, 3ª edición, borrador público en `web.stanford.edu/~jurafsky/slp3`. Los capítulos de semántica vectorial y de question answering cubren el puente entre representación distribuida y recuperación. Se actualiza periódicamente, así que la numeración de capítulos baila entre versiones; guíate por el título, no por el número. **[GRATIS]**

**Complemento aplicado.** Alammar y Grootendorst, *Hands-On Large Language Models* (O'Reilly, 2024). Es el libro más cercano a lo que hace este curso: embeddings, búsqueda semántica y RAG explicados con figuras y código. Si solo vas a comprar uno, es este. **[PAGO]**

**Complemento sobre transformers.** Tunstall, von Werra y Wolf, *Natural Language Processing with Transformers* (O'Reilly). Útil si quieres entender qué hay dentro del modelo de embeddings en lugar de tratarlo como caja negra. No es necesario para completar las 10 semanas. **[PAGO]**

**Si sigues a Java.** Documentación de referencia de Spring AI y *Spring in Action* de Craig Walls para la parte de Spring Boot. Solo relevante después de la semana 10. **[PAGO]** el libro, **[GRATIS]** la documentación.

### 13.2 Cursos, tutoriales y video

**DeepLearning.AI, cursos cortos.** Hay varios directamente aplicables: uno sobre recuperación avanzada con Chroma, uno sobre construir y evaluar RAG avanzado, y uno sobre preprocesamiento de datos no estructurados. Duran una o dos horas cada uno y encajan bien como sesión 2 alternativa de las semanas 7 a 9. **[GRATIS]**

**3Blue1Brown, serie de álgebra lineal y serie sobre transformers y attention (YouTube).** Si la semana 3 te deja con la sensación de que "el vector es magia", esto es el antídoto. La intuición geométrica de qué es un espacio vectorial y qué significa que dos vectores estén cerca. **[GRATIS]**

**Andrej Karpathy (YouTube).** Su charla larga sobre cómo funcionan los LLM es el mejor material que existe para entender qué es conocimiento paramétrico y por qué el modelo alucina — que es exactamente el problema que abre la semana 1. **[GRATIS]**

**Jay Alammar, *The Illustrated Transformer* y sus otros posts ilustrados.** Referencia visual clásica. **[GRATIS]**

**Stanford CS224N, *NLP with Deep Learning* (lecciones en YouTube).** Las lecciones sobre word vectors y sobre question answering son las relevantes. Es un curso universitario completo: no lo hagas entero durante estas 10 semanas, úsalo como consulta. **[GRATIS]**

**Blogs de proveedores de bases vectoriales** (Pinecone, Weaviate, Qdrant). Tienen las mejores explicaciones prácticas de búsqueda híbrida, HNSW y reranking que hay en abierto. Sesgo obvio: cada uno concluye que su producto es la respuesta. Lee el mecanismo, ignora la conclusión. **[GRATIS]**

**Anthropic, *Contextual Retrieval*.** Post técnico sobre una mejora concreta de chunking: adjuntar contexto del documento a cada fragmento antes de embeberlo. Es el complemento natural de la semana 6 y viene con números de la evaluación que hicieron. **[GRATIS]**

### 13.3 Documentación oficial

Ollama (`ollama.com/docs`), ChromaDB (`docs.trychroma.com`), pgvector (repositorio en GitHub) y Spring AI. Anota la fecha en que consultaste cada una: la API de ChromaDB cambió de forma incompatible más de una vez, y buena parte de los tutoriales que vas a encontrar en la web están escritos contra versiones que ya no corren.

### 13.4 Artículos y papers

No necesitas leer papers para completar el curso. Los pongo porque a partir de la semana 7 vas a tomar decisiones (híbrido sí o no, reranking sí o no) que estos textos ya discutieron con datos, y porque leer el original de una técnica que estás implementando es la forma más rápida de entender qué problema resolvía de verdad.

**El fundacional.** Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (2020). El paper que nombró la técnica. Ojo: el RAG del paper entrena el retriever junto con el generador, que no es lo que hace ningún sistema de los que vas a construir. Léelo para el planteamiento del problema, no como especificación.

**Recuperación densa.** Karpukhin et al., *Dense Passage Retrieval for Open-Domain Question Answering* (2020). Por qué los embeddings superan a la búsqueda por palabras en preguntas en lenguaje natural. Es el sustento de la semana 3.

**Embeddings de oraciones.** Reimers y Gurevych, *Sentence-BERT* (2019). Explica por qué un modelo de embeddings de oraciones no es lo mismo que promediar embeddings de palabras — la razón por la que existe `embeddinggemma` como pieza separada.

**Fusión de rankings.** Cormack, Clarke y Buettcher, *Reciprocal Rank Fusion Outperforms Condorcet and Individual Rank Learning Methods* (SIGIR, 2009). Es la fórmula que implementas en la semana 7, y el paper es corto. El hallazgo incómodo: una fusión ingenua de posiciones le gana a métodos bastante más sofisticados.

**Reranking.** Nogueira y Cho, *Passage Re-ranking with BERT* (2019). La arquitectura de dos etapas de la semana 8, en su versión original.

**El límite del contexto largo.** Liu et al., *Lost in the Middle: How Language Models Use Long Contexts* (2023). Los modelos atienden peor a lo que está en la mitad del prompt que a lo que está al principio o al final. Es la justificación empírica de que ordenar los fragmentos importa, y de que un top-K grande no es gratis. Es el paper que más directamente contradice el impulso de "meterle más contexto".

**Evaluación.** Es et al., *RAGAS: Automated Evaluation of Retrieval Augmented Generation* (2023). El marco de métricas del que salen los conceptos de fidelidad y relevancia de la semana 9.

**Panorama general.** Gao et al., *Retrieval-Augmented Generation for Large Language Models: A Survey* (2023, con actualizaciones posteriores). Mapa de casi todas las variantes. Úsalo como índice para decidir qué leer, no como lectura de corrido.

**Seguridad.** Greshake et al., *Not What You've Signed Up For: Compromising Real-World LLM-Integrated Applications with Indirect Prompt Injection* (2023). Es el paper detrás del experimento de la semana 10: un documento del corpus puede contener instrucciones.

**Si quieres seguir después.** Gao et al. sobre HyDE (consultas hipotéticas), Asai et al. sobre Self-RAG (el modelo decide cuándo recuperar), Sarthi et al. sobre RAPTOR (resúmenes jerárquicos) y Edge et al. sobre GraphRAG (recuperación sobre grafos de entidades). Ninguno cabe en 10 semanas; todos son el paso siguiente natural.

### 13.5 Orden de lectura sugerido

Antes de la semana 1, la charla de Karpathy sobre LLM. Durante la semana 3, la serie de álgebra lineal de 3Blue1Brown si la intuición vectorial no aparece sola. Entre las semanas 4 y 5, los capítulos de modelo vectorial y evaluación de Manning. Al llegar a la semana 7, el paper de RRF (es corto y lo vas a implementar esa misma semana). Antes de la semana 9, *Lost in the Middle* y el paper de RAGAS. El survey de Gao, al final, para decidir hacia dónde seguir.

Lo demás es consulta, no lectura obligatoria. Con 5,5 horas semanales, un capítulo de libro por semana ya es un compromiso serio: no planifiques cuatro.
