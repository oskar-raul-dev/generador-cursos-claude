# Parte I — Fundamentos teóricos

**12 guías · 24–30 h · semanas 1–5**

Esta es la parte que da más ansiedad porque no produce código de proyecto. Vale la pena aguantar la incomodidad: cada decisión de las Partes III y IV se apoya en algo que se explica acá. Sin ella, cuando el reranking no mejore nada no vas a tener con qué diagnosticarlo, y la única salida va a ser cambiar parámetros a ciegas.

## Estructura

Cada tema cubre un concepto fundamental de RAG. El orden es deliberado: partis con la arquitectura completa, después bajás a piezas individuales, y cerrás con los modos en que todo puede fallar.

| Tema | Concepto | Criterio de salida |
|---|---|---|
| T01 | Presentación del problema y arquitectura objetivo | Dibujás la arquitectura completa de memoria |
| T02 | Conocimiento paramétrico y alucinación | Explicás por qué el modelo inventa con confianza |
| T03 | RAG frente a fine-tuning y búsqueda tradicional | Argumentás cuándo conviene cada uno |
| T04 | Arquitectura de dos pipelines: ingestión y consulta | Explicás por qué reindexar en cada consulta es un error |
| T05 | Tokens, ventana de contexto y presupuesto | Calculás cuánta evidencia cabe en una ventana dada |
| T06 | Documentos, fragmentos y metadatos | Diseñás el modelo documental antes de código |
| T07 | Estrategias de chunking | Elegís una estrategia y sostenés el porqué |
| T08 | Embeddings y representación vectorial | Explicás por qué frases sin palabras comunes quedan próximas |
| T09 | Similitud y búsqueda vectorial | Calculás similitud coseno a mano |
| T10 | Recuperación sparse, dense e híbrida | Construís una consulta que rompe cada método |
| T11 | Generación fundamentada y citas | Escribís un prompt que produce abstención reproducible |
| T12 | Calidad y modos de fallo | Enumerás dónde puede romperse el sistema |

## Dónde se tuerce esta parte

El error clásico es leerla como teoría pura sin hacer los laboratorios. T08 y T09 sin laboratorio se convierten en dos horas de asentir frente a una definición. La diferencia entre saber que existe la similitud coseno y haberla calculado a mano es toda la diferencia del curso.

El segundo error es querer resolver el chunking en T07 sin retrieval implementado. No se puede: sin métricas no tenés con qué comparar. Acá elegís una base razonable y seguís; la respuesta llega en P21 y se confirma en P49.

## Hito

Explicás el pipeline completo en una pizarra, con las dos rutas separadas y los siete puntos de fallo marcados, sin mirar el documento.

## Después de esta parte

Pasás a la Parte II (Proyecto básico funcional) con la arquitectura clara. El MVP que construís en Java debe tener cada pieza de estas guías traducida a código.
