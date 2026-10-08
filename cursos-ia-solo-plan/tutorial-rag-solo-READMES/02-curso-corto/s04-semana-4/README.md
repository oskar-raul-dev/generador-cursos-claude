# Semana 4 — Vector store y recuperación

**5.5 h totales · Objetivo: búsqueda inspeccionable**

## Resumen

ChromaDB almacena embeddings con fragmentos, metadatos e IDs. Cuando preguntás, el sistema convierte tu pregunta en embedding, busca vecinos cercanos y devuelve fragmentos.

Top-K es crucial: no hay valor mágico. K pequeño omite evidencia; K grande introduce ruido.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Vector store: almacén de embeddings con metadatos. Top-K: número de resultados. Umbrales de distancia: no recuperar lo demasiado lejano aunque sea el tercero.

ChromaDB: opción sin configuración. Alternativas profesionales: pgvector, Qdrant, Milvus, FAISS.

### Sesión 2 — Laboratorio (1.5 h)

Indexás corpus en ChromaDB. Hacés consultas variando K: 1, 3, 5, 10. Para cada una, registrás qué recuperaste, de cuál documento, con qué distancia.

Analiza: ¿a partir de cuál K empiezan fragmentos irrelevantes? ¿Qué distancia tienen?

### Sesión 3 — Proyecto (2.5 h)

Pipeline completo: documentos → fragmentación → embeddings → ChromaDB.

Escribís comando de inspección: toma pregunta, imprime qué recuperó con distancias, **sin que intervenga ningún LLM todavía**. Este comando es crucial para las semanas siguientes.

## Criterio de finalización

Existe comando `query("¿cuántos días de vacaciones tengo?")` que imprime qué recuperó, de dónde, con qué distancia. Sin LLM.

## Contenidos de cada carpeta

```
s04-semana-4/
├── sesion-01-teoria/
│   └── README.md           # Vector store, top-K, umbrales
├── sesion-02-laboratorio/
│   └── README.md           # Consultas variando K, análisis de distancias
└── sesion-03-proyecto/
    └── README.md           # Pipeline de indexación, comando de inspección
```

## Siguiente paso

Avanzás a Semana 5 con búsqueda funcionando. Ahora le agregás generación.
