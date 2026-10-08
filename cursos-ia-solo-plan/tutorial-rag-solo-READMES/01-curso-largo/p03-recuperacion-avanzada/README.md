# Parte III — Recuperación avanzada

**12 guías · 42–50 h · semanas 19–27**

El MVP funciona con tu corpus de prueba. Con documentos reales empieza a fallar de maneras específicas: no encuentra un código de norma, trae el fragmento correcto en la posición nueve, o devuelve cinco versiones del mismo párrafo.

Cada guía de esta parte ataca uno de esos fallos concretos. Y **cada una se justifica con una medición**: si no mejora las métricas, se revierte. Esta es la parte donde más fácil es acumular complejidad que no sirve.

## Estructura

Las técnicas están ordenadas por dependencia y por impacto medible. Evaluación del chunking viene primero porque informa todas las decisiones posteriores. Búsqueda híbrida y RRF forman un bloque coherente. Reranking viene después, cuando ya tenés criterio sobre qué se recupera.

| Guía | Qué resuelves | Criterio de salida |
|---|---|---|
| P21 | Evaluación del chunking comparando tamaños y overlaps | Elegís configuración con datos, no con intuición |
| P22 | Chunking estructural por títulos y secciones | Una sección lógica no se parte a mitad de regla |
| P23 | Metadatos y filtros por departamento, versión, idioma | Restringís búsqueda sin reindexar |
| P24 | Parent-child retrieval | Recuperación precisa con contexto amplio |
| P25 | Búsqueda textual con PostgreSQL Full-Text Search | Encontrás códigos y números que el vector diluye |
| P26 | Búsqueda híbrida | Muestrás una consulta donde híbrido gana |
| P27 | Reciprocal Rank Fusion | Fusionás rankings sin normalizar puntajes |
| P28 | Transformación de consultas | Una pregunta coloquial recupera lo mismo que su versión precisa |
| P29 | Multi-query retrieval | Aumentás cobertura con varias formulaciones |
| P30 | Reranking | Reordenás candidatos y cuantificás ganancia y latencia |
| P31 | Compresión del contexto | Eliminás contenido irrelevante antes del prompt |
| P32 | Diversidad de resultados | Evitás cinco fragmentos que dicen lo mismo |

## Dónde se tuerce esta parte

**Reranking sobre topK pequeño.** Si el retriever ya perdió el fragmento correcto, ningún reranker lo recupera. Necesitás un candidato amplio arriba (20, no 5).

**Asumir que híbrido siempre gana.** A veces empeora. Un corpus puramente narrativo rara vez se beneficia de sparse y sí paga su latencia.

**Acumular técnicas sin medir.** Al terminar deberías poder decir con números cuánto aportó cada una. Si no podés, agregaste complejidad, no calidad.

## Criterio central

Una regla que ordena esta parte: **los resultados negativos se documentan igual que los positivos**. Si el reranking no mejora tus métricas, eso se escribe, se analiza y se conserva. Es información real sobre tu corpus.

## Punto de control

Al terminar P32 tenés recuperación de calidad profesional: híbrida, con filtros, diversidad y reranking. Un corpus real es consultable con criterio, no al azar.

## Después de esta parte

Pasás a la Parte IV (Conversación, seguridad y operación) con un retriever sofisticado. Ahora el trabajo es sobre lo que pasa con esa evidencia: cómo se integra en conversaciones, cómo se securiza, cómo se opera.
