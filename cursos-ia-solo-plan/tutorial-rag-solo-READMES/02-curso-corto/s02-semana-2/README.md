# Semana 2 — Chunking

**5.5 h totales · Objetivo: fragmentador configurable**

## Resumen

Un documento completo es demasiado grande para recuperación. Necesitás fragmentarlo. Pero fragmentar bien es un arte: demasiado pequeño y los fragmentos pierden contexto; demasiado grande y mezclas conceptos.

Esta semana implementás chunking con tamaño configurable y overlap.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Estrategias de chunking: tamaño fijo en palabras, tokens, párrafos, encabezados, estructura semántica. Este curso elige tamaño fijo con overlap: conservás un porcentaje del fragmento anterior al siguiente.

Metadatos importan: fuente, sección, posición. Son trazabilidad para citas posteriores.

### Sesión 2 — Laboratorio (1.5 h)

Implementás `split_text(text, chunk_size, overlap)` en Python puro. 20 líneas.

Probás con tres configuraciones:
- 30 palabras, 0 overlap → Reglas cortadas
- 80 palabras, 20 overlap → Base razonable
- 300 palabras, 50 overlap → Fragmentos que mezclan temas

Analiza: ¿en cuál se mantiene la lógica completa?

### Sesión 3 — Proyecto (2.5 h)

Leés archivos `.txt` y `.md` desde disco. Cada fragmento: texto, fuente, posición, hash estable como ID. Volcás a JSON.

## Criterio de finalización

Tenés fragmentador configurable. Podés justificar tu elección (chunk_size=80, overlap=20) con un ejemplo que muestra por qué funciona.

## Contenidos de cada carpeta

```
s02-semana-2/
├── sesion-01-teoria/
│   └── README.md           # Estrategias, tamaño, overlap, metadatos
├── sesion-02-laboratorio/
│   └── README.md           # Implementar split_text, experimentar parámetros
└── sesion-03-proyecto/
    └── README.md           # Lectura de archivos, fragmentación, persistencia
```

## Siguiente paso

Avanzás a Semana 3 con fragmentos listos. Ahora los convertís en vectores.
