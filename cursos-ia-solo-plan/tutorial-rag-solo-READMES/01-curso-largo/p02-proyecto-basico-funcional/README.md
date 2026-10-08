# Parte II — Proyecto básico funcional

**20 guías · 65–75 h · semanas 6–18**

Acá aparece el sistema completo. Es la parte más larga en horas y la que más se siente como desarrollo normal: Spring Boot, migraciones, tests, Docker. Lo específico de RAG es una fracción del trabajo.

## Estructura y fases del proyecto

El proyecto crece progresivamente a lo largo de 20 guías. El orden no es flexible: cada guía presupone el estado del repositorio que dejó la anterior.

### Fase 1: Setup y corpus (P01–P05)

Definís el alcance funcional, tomás decisiones técnicas, levantás el entorno local y preparás el corpus de prueba.

### Fase 2: Ingestión (P06–P12)

Construís el pipeline completo: modelo documental, lectura de archivos, normalización, chunking, generación de embeddings y almacenamiento en pgvector.

### Fase 3: Consulta (P13–P17)

Implementás búsqueda vectorial, endpoint de diagnóstico (P14, crucial), construcción de prompts, generación de respuestas, citas y manejo de la abstención.

### Fase 4: Exposición y operación (P18–P20)

Envolvés todo en una API REST con OpenAPI, escribís tests de integración y contenedorizás con Docker Compose.

## Orden de las guías

| Guía | Qué construyes | Criterio de salida |
|---|---|---|
| P01 | Definición funcional y alcance | El alcance está escrito |
| P02 | Arquitectura y ADR | Cada decisión tiene su alternativa descartada |
| P03 | Entorno local: Java, Docker, PostgreSQL, Ollama | `docker compose up` lo levanta todo |
| P04 | Proyecto Spring Boot | La aplicación arranca |
| P05 | Corpus y preguntas de prueba | Existen las preguntas que van a guiar el desarrollo |
| P06 | Modelo documental | El modelo soporta trazabilidad sin cambios posteriores |
| P07 | Lectura de TXT y Markdown | Un archivo corrupto no tumba la ingestión |
| P08 | Normalización sin destruir estructura | La jerarquía de encabezados sobrevive |
| P09 | Chunking configurable | Cambias parámetros sin recompilar |
| P10 | Generación de embeddings por lotes | Indexas el corpus completo |
| P11 | PostgreSQL + pgvector + Flyway | El esquema se recrea desde cero |
| P12 | Pipeline de ingestión completo | Un documento nuevo es consultable automáticamente |
| P13 | Búsqueda vectorial básica | Recuperás fragmentos relevantes |
| P14 | Endpoint de diagnóstico | Ves qué recuperó **antes** del modelo |
| P15 | Generación de respuestas | El sistema responde con evidencia |
| P16 | Citas y trazabilidad | Cada afirmación tiene su fuente |
| P17 | Abstención verificable | La pregunta sobre licencia de maternidad produce abstención |
| P18 | API REST con OpenAPI | Un cliente externo usa el sistema |
| P19 | Pruebas de integración | La suite corre limpia |
| P20 | Contenedorización | Alguien más clona y levanta el proyecto |

## Puntos críticos

**P14 no es prescindible.** Es la guía más fácil de considerar innecesaria y la más cara de omitir. Sin un endpoint que muestre qué se recuperó, cada fallo posterior es indistinguible de cualquier otro.

**P17 requiere verificación.** Un modelo pequeño a veces se abstiene porque no encontró qué decir, no porque el prompt se lo exija. Parecen el mismo comportamiento. Verificá forzando el caso contrario: evidencia presente pero prompt sin grounding.

**No optimicés antes de tiempo.** La tentación de meter búsqueda híbrida porque ya leíste T10 es fuerte. Sin MVP cerrado, no tenés línea base contra la cual comparar.

## Hito de la Parte II

Este es el **punto de parada del curso**. Al cerrar P20 tenés un sistema que:

- Carga documentos
- Los indexa
- Busca semánticamente
- Responde con citas
- Se abstiene sin evidencia
- Está expuesto por API
- Tiene pruebas
- Levanta con un comando

Es un sistema real y una parada completa. Las Partes III y IV son mejora sobre algo que ya funciona.

## Después de esta parte

Pasás a la Parte III (Recuperación avanzada) con un MVP funcionando. Ahora las mejoras que implementés se pueden medir contra una línea base.
