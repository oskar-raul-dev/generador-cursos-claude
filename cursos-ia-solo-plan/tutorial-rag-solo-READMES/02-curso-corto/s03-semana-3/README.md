# Semana 3 — Embeddings y similitud

**5.5 h totales · Objetivo: similitud coseno calculada a mano**

## Resumen

Un embedding es texto convertido a vector. "Solicitar vacaciones" → [0.12, -0.38, 0.05, ...]. El milagro es que textos con significados próximos ocupan regiones cercanas.

Calculás similitud coseno a mano para entender el mecanismo puro.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Embeddings: representación vectorial del significado. Modelos de embeddings y generativos son piezas distintas. El embedding convierte texto en vector para búsqueda; el generativo produce respuesta.

Medidas de proximidad: similitud coseno, dot product, distancia euclidiana. Todas responden: ¿qué tan cerca están dos vectores?

### Sesión 2 — Laboratorio (1.5 h)

Generás embeddings localmente (`ollama.embed`). Calculás similitud coseno a mano con numpy, sin vector store. Ves el mecanismo puro.

Frases de prueba:
```
"solicitar vacaciones"
"pedir días libres"
"proceso de reembolso de gastos"
"factura electrónica"
"política de trabajo remoto"
```

Armás matriz de similitud. Verificás: las dos primeras están cerca pese a no compartir palabras. Buscás un contraejemplo.

### Sesión 3 — Proyecto (2.5 h)

Generás embeddings en lote para todos los fragmentos. Guardás embedding + metadatos. Medís tiempo de indexación.

## Criterio de finalización

Calculás similitud coseno sin librerías (solo numpy). Explicás por qué "pedir días libres" está próximo a "solicitar vacaciones" aunque no compartan palabras.

## Contenidos de cada carpeta

```
s03-semana-3/
├── sesion-01-teoria/
│   └── README.md           # Embeddings, vectores, medidas de proximidad
├── sesion-02-laboratorio/
│   └── README.md           # Generar embeddings, similitud coseno a mano
└── sesion-03-proyecto/
    └── README.md           # Indexación en lote, medición de tiempo
```

## Siguiente paso

Avanzás a Semana 4 con embeddings generados. Ahora los guardás en un vector store.
