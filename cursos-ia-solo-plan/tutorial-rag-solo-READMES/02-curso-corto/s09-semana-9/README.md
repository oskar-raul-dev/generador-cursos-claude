# Semana 9 — Evaluación

**5.5 h totales · Objetivo: números reales, decisiones basadas en datos**

## Resumen

Sin dataset, toda mejora es superstición. Necesitás preguntas reales, respuestas esperadas, fragmentos relevantes. Métricas: Hit Rate (¿apareció el fragmento?), Precision@K (¿cuánto que recuperaste servía?).

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Dataset de evaluación: preguntas, respuestas esperadas, documentos relevantes. Al menos 20 % de los casos exige abstención.

Métricas de recuperación: Hit Rate, Precision@K, Recall@K, MRR.

Métricas de respuesta: ¿es correcta? ¿Cita bien? ¿Se abstiene cuando debe?

### Sesión 2 — Laboratorio (1.5 h)

Construís dataset de 20–25 preguntas, incluidas 5–6 que piden abstención. Implementás Hit Rate y Precision@3.

### Sesión 3 — Proyecto (2.5 h)

Ejecutás dataset contra todas tus configuraciones: dense vs. híbrido, diferentes chunk sizes, con y sin reranking.

Produces tabla de números reales. Si una mejora no sale reflejada en las métricas, la reviertes.

## Criterio de finalización

Existen números verificables. Al menos una decisión cambió por ellos (dejaste de usar una técnica o cambiaste un parámetro).

## Contenidos de cada carpeta

```
s09-semana-9/
├── sesion-01-teoria/
│   └── README.md           # Dataset, Hit Rate, Precision@K
├── sesion-02-laboratorio/
│   └── README.md           # Construir dataset, implementar métricas
└── sesion-03-proyecto/
    └── README.md           # Comparar configuraciones, producir tabla de resultados
```

## Siguiente paso

Avanzás a Semana 10 con números en mano. Ahora documentas y compareás con Java.
