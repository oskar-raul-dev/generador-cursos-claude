# Semana 8 — Query rewriting, reranking y conversación

**5.5 h totales · Objetivo: pipeline refinado**

## Resumen

La pregunta del usuario es coloquial y ambigua. Query rewriting la normaliza. Reranking ordena candidatos con precisión. Conversación resuelve referencias ("¿y si es desde otro país?") usando el turno anterior.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Query rewriting: "¿cómo puedo pedir un día libre extra?" → "solicitar día feriado" o "política de vacaciones". Recuperación más precisa.

Reranking: recuperás 20 candidatos rápidamente; modelo más preciso ordena los mejores 5.

RAG conversacional: usa pregunta anterior para desambiguar la nueva.

### Sesión 2 — Laboratorio (1.5 h)

Reescribís cinco preguntas coloquiales. Comprobás qué recupera cada versión. Experimentás con reranking: 15 candidatos, LLM ordena por relevancia, comparás con orden original.

### Sesión 3 — Proyecto (2.5 h)

Integrás reescritura y reranking. Añadís resolución de preguntas de seguimiento: el sistema recuerda pregunta anterior.

Medís latencia: ¿cuánto agrega cada mejora?

## Criterio de finalización

Una pregunta de seguimiento ambigua se resuelve correctamente. Tenés números: qué mejora ganó Hit Rate, cuánta latencia costó.

## Contenidos de cada carpeta

```
s08-semana-8/
├── sesion-01-teoria/
│   └── README.md           # Query rewriting, reranking, conversación
├── sesion-02-laboratorio/
│   └── README.md           # Reescrituras, reranking con LLM
└── sesion-03-proyecto/
    └── README.md           # Integración, seguimiento, medición de latencia
```

## Siguiente paso

Avanzás a Semana 9 con pipeline refinado. Ahora medir todo.
