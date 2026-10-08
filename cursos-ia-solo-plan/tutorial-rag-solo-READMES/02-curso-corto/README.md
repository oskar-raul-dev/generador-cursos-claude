# Curso de RAG — versión comprimida

**10 semanas, ~55 h totales, 5,5 h semanales**

Construís un asistente documental completo en Python + Ollama + ChromaDB. El mismo criterio conceptual que el curso largo (mecanismo antes que abstracción, medición de todo), comprimido eliminando infraestructura Java y enfocándose en la esencia de RAG.

## Estructura de las 10 semanas

Cada semana consta de tres sesiones de 1.5–2.5 h: teoría, laboratorio y proyecto. El proyecto crece semana a semana hasta formar un sistema completo.

| Semana | Se aprende | Hito |
|---|---|---|
| 1 | LLM, contexto, por qué RAG resuelve | Demostración de alucinación |
| 2 | Chunking, metadatos, fragmentación configurable | Fragmentador funcional |
| 3 | Embeddings, similitud coseno, vectores | Similitud calculada a mano |
| 4 | Vector store, recuperación, top-K | Búsqueda inspeccionable |
| **5** | **Grounding, citas, abstención** | **RAG funcional end-to-end** |
| 6 | Fallos por etapa, diagnóstico, chunking estructural | Ingestión multiformato |
| 7 | Búsqueda sparse, dense, híbrida, RRF | Retriever híbrido |
| 8 | Query rewriting, reranking, conversación | Pipeline refinado |
| 9 | Dataset, métricas, evaluación | Hit Rate, Precision@K |
| 10 | Producción y equivalentes en Java | Documentación y cierre |

## Hito crítico: Semana 5

Al terminar la semana 5 tenés un sistema RAG completo: carga documentos, los indexa, busca, responde con citas y se abstiene cuando falta evidencia. Es un punto de parada legítimo. Las semanas 6–10 lo refinan.

Si algo no funciona en la semana 5, se resuelve acá antes de continuar.

## Stack

**Semanas 1–9:** Python 3.11+, Ollama, ChromaDB. Modelos locales: `embeddinggemma` y `gemma3:4b`.

**Semana 10:** Lectura comparativa de Java + Spring AI + pgvector.

Sin LangChain ni LlamaIndex; ves exactamente qué se calcula y por qué.

## Proyecto conductor

Asistente que responde preguntas sobre políticas de una empresa: vacaciones, trabajo remoto, gastos. Con una trampa intencional: no hay política de licencia de maternidad. Esa pregunta debe producir abstención desde la semana 5 hasta el final.

## Puntos de control

- Semana 2: fragmentador con parámetros configurables
- Semana 4: comando que muestra qué recuperó el sistema antes del LLM
- **Semana 5: RAG funcional con citas y abstención**
- Semana 7: búsqueda híbrida implementada y testeable
- Semana 9: números reales de Hit Rate y Precision@K

## Después del curso

La ruta recomendada es: termina el corto completo (10 semanas), después entra al curso largo saltando la Parte I, directo a P01. Llegas a la Parte II con el pipeline ya entendido.

Alternativas: si solo querés los fundamentos, la semana 5 es parada válida. Si necesitás producción, seguí con el curso largo.
