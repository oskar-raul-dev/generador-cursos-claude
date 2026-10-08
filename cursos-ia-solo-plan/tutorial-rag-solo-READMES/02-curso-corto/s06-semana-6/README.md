# Semana 6 — Corpus real y diagnóstico de fallos

**5.5 h totales · Objetivo: identificar etapa de fallo**

## Resumen

Un RAG puede romperse en siete etapas: parsing, chunking, embedding, retrieval, ranking, prompt, generación. El síntoma es el mismo: respuesta mala. Sin inspección en cada etapa, quedás adivinando.

Usás el comando de inspección de la semana 4 para diagnosticar.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Los siete puntos de fallo. Chunking estructural: en lugar de trocear por número de palabras, dividís por encabezados y secciones. Respeta estructura lógica.

### Sesión 2 — Laboratorio (1.5 h)

Se te doy tres casos de fallo ya preparados. Diagnosticás en qué etapa se rompe cada uno usando el comando de inspección.

### Sesión 3 — Proyecto (2.5 h)

Amplías corpus a documentos más reales. Implementás lectura de PDF con estructura. Chunking estructural: si el PDF tiene sección "Vacaciones", esa sección no se parte arbitrariamente.

Volcás prompt final a archivo para inspeccionarlo cuando la respuesta es mala.

## Criterio de finalización

Te presento una respuesta incorrecta; identificás la etapa de fallo en menos de cinco minutos sin adivinar.

## Contenidos de cada carpeta

```
s06-semana-6/
├── sesion-01-teoria/
│   └── README.md           # Los siete puntos de fallo, diagnóstico
├── sesion-02-laboratorio/
│   └── README.md           # Casos de fallo preparados para diagnosticar
└── sesion-03-proyecto/
    └── README.md           # Corpus real, PDF, chunking estructural, inspección
```

## Siguiente paso

Avanzás a Semana 7 con corpus real. Ahora le agregás búsqueda híbrida.
