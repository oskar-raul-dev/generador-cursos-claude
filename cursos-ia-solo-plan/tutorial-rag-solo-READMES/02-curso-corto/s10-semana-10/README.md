# Semana 10 — Producción, Spring AI y cierre

**5.5 h totales · Objetivo: documentación y transición a Java**

## Resumen

Panorámica de producción sin implementación. Lectura comparativa: tu pipeline en Python vs. su equivalente en Java + Spring AI + pgvector.

Documentás el sistema y lo entregas.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Criterios de producción que debes conocer aunque no los implementes:

- **Seguridad documental:** el filtro de permisos va en el retrieval, nunca pegado en el prompt
- **Prompt injection:** los documentos son datos no confiables
- **Información sensible:** clasificación, minimización, retención
- **Observabilidad:** qué necesitás registrar para debuggear después
- **Rendimiento:** dónde cachear, qué procesar por lotes
- **Portabilidad:** no acoplar el dominio al proveedor

### Sesión 2 — Laboratorio (1.5 h)

Lectura comparativa: tu código Python vs. equivalente en Java.

```
Python: `split_text()`
Java:   `ContentProcessor.splitText()` en Spring AI

Python: `ollama.embed()`
Java:   `EmbeddingModel` de Spring AI

Python: ChromaDB
Java:   PostgreSQL + pgvector
```

Experimento de prompt injection: agregás instrucción maliciosa en documento. ¿El sistema la ejecuta o el grounding la bloquea?

### Sesión 3 — Proyecto (2.5 h)

**Entregas:**
- `README.md` con arquitectura e instrucciones para reproducir
- `DECISIONS.md` breve sobre cada parámetro y por qué
- Reporte de métricas de Semana 9
- Demo funcionando sobre las cuatro preguntas de prueba
- Lista honesta de limitaciones

## Criterio de finalización

Un tercero puede clonar, ejecutar y entender por qué cada parámetro tiene su valor. No porque adivine: porque está documentado.

## Contenidos de cada carpeta

```
s10-semana-10/
├── sesion-01-teoria/
│   └── README.md           # Panorámica de producción
├── sesion-02-laboratorio/
│   └── README.md           # Comparación Python vs Java, prompt injection
└── sesion-03-proyecto/
    └── README.md           # Documentación, entrega, demo
```

## Después del curso

**Ruta recomendada:** termina este curso (10 semanas), después entra al curso largo saltando Parte I. Llegas a P01 con el pipeline ya entendido.

**Si solo querías foundational:** Semana 5 es parada legítima.

**Si necesitás producción:** curso largo, Partes II–V (30 semanas más).

## Resumen de lo que aprendiste

| Semana | Habilidad |
|---|---|
| 1 | Por qué RAG resuelve el problema |
| 2 | Fragmentar documentos eficientemente |
| 3 | Embeddings y similitud vectorial |
| 4 | Recuperación por vector store |
| 5 | RAG funcional con citas y abstención |
| 6 | Diagnosticar fallos por etapa |
| 7 | Búsqueda híbrida |
| 8 | Reranking y conversación |
| 9 | Medición y evaluación |
| 10 | Producción y siguiente paso |
