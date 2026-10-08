# Semana 1 — Qué resuelve RAG

**5.5 h totales · Objetivo: entender el problema y la solución**

## Resumen

Empezás observando un LLM local que alucina cuando preguntás algo fuera de su entrenamiento. Luego ves cómo RAG resuelve exactamente eso: recuperar evidencia previamente y entregarla en el prompt. El sistema no es "meter todo"; es **seleccionar previamente** qué cabe.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

El LLM conoce lo que aprendió durante entrenamiento, pero nada de tu dominio. Preguntás sobre una política de la empresa y alucina. Después, pegás el documento en el prompt y ahora responde correctamente.

Pero si pegas **todos** los documentos de una sola vez, pasa lo contrario: costo en tokens, latencia alta, respuesta diluida. RAG no es "meter todo". Es **recuperar previamente** qué importa.

Eso requiere dos pipelines distintos con ciclos de vida separados. Ingestión: lee, fragmenta, genera embeddings, guarda. Consulta: toma pregunta, la convierte en embedding, recupera fragmentos, construye prompt.

### Sesión 2 — Laboratorio (1.5 h)

Tres experimentos sobre el mismo modelo:
1. Preguntá algo que no sabe. Alucina.
2. Pegá el documento en el prompt. Responde correctamente.
3. Pegá veinte documentos irrelevantes. Observá: latencia sube, respuesta se vuelve vaga, costo aumenta.

### Sesión 3 — Proyecto (2.5 h)

Inicializás repositorio. Definís corpus (tres archivos markdown ficticios). Escribís script Python que pregunta al LLM sin recuperación. Documentás observaciones.

## Criterio de finalización

Explicás sin notas por qué "meter todo en el prompt" no escala. Tu argumento no es solo "alcanzamos ventana de contexto" sino "la dilución de señal es peor que el truncamiento".

## Contenidos de cada carpeta

```
s01-semana-1/
├── sesion-01-teoria/
│   └── README.md           # Conceptos clave: dos pipelines, alucinación, RAG
├── sesion-02-laboratorio/
│   └── README.md           # Experimentos con LLM local
└── sesion-03-proyecto/
    └── README.md           # Setup del repositorio y script inicial
```

## Siguiente paso

Avanzás a Semana 2 con el setup listo y la necesidad de fragmentar clara.
