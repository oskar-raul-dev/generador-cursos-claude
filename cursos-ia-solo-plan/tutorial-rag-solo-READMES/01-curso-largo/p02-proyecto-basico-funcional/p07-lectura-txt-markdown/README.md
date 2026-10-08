# P07 — Lectura de TXT y Markdown

**Guía de proyecto · ~2 h**

## Qué construyes

Parser que lee archivos TXT y Markdown, extrae texto, preserva estructura. Un archivo corrupto no tumba la ingestión completa.

## Contenidos

- DocumentReader interface
- TxtDocumentReader: lectura simple
- MarkdownDocumentReader: preserva encabezados como metadatos
- Manejo de excepciones: archivo corrupto no detiene el flujo
- Tests de lectura

## Criterio de finalización

Un archivo corrupto produce un log de error pero la ingestión continúa. Los archivos válidos en la carpeta se procesan.

## Después de esta guía

Pasás a P08 con texto extraído. Ahora lo normalizás.
