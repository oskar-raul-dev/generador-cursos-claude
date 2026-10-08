# Tutorial RAG

Tres documentos maestros que cubren el espectro completo de cursos sobre Retrieval-Augmented Generation, desde la versión comprimida que puedes hacer en diez semanas hasta la implementación de producción en Java que toma casi un año.

---

## Documentos

### 📘 01-Curso-rag-largo.md — La versión completa

**65 guías, 38–43 semanas, 6 h por semana.**

Construyes un asistente documental empresarial completo: Java 21, Spring Boot, Spring AI, PostgreSQL con pgvector y Ollama local. El criterio que ordena todo el curso es uno: primero el mecanismo, después la abstracción.

Empieza en la teoría pura (conceptos sin código), pasa por un MVP funcional en Java, sigue con técnicas avanzadas de recuperación y termina en operación real: seguridad, observabilidad, evaluación sistemática.

**Qué vas a poder hacer:** reconstruir el sistema desde cero sin el documento delante, y justificar cada decisión con una medición. Conocimiento paramétrico, alucinación, dos pipelines, embeddings, similitud coseno, búsqueda vectorial, sparse, dense, híbrida, grounding, citas, abstención, reranking, evaluación de calidad. Al terminar, no solo tienes un sistema que anda: sabes exactamente por qué cada parámetro vale lo que vale.

**Stack:** Java 21, Spring Boot, Spring AI, PostgreSQL + pgvector, Flyway, Testcontainers, Docker Compose, Ollama. Modelos locales: `embeddinggemma` para embeddings, `gemma3:4b` para generación.

**Para quién:** backend engineers con experiencia en sistemas, sin experiencia previa en IA. El curso presupone comodidad con API, transacciones, índices y tests de integración.

**Punto de parada a mitad de camino:** después de la guía P20 (semana 18) tienes un RAG funcional completamente operativo en Java. Es un hito legítimo y un sistema coherente por sí solo.

---

### ⚡ 02-Curso-rag-corto.md — La versión comprimida

**10 semanas, ~55 h totales, 5,5 h semanales.**

El mismo criterio conceptual que el largo, comprimido en 10 semanas con Python + Ollama + ChromaDB. La infraestructura Java no desaparece; se mueve a lectura: entiendes qué es `ChatClient`, qué hace pgvector, cómo se vería la migración. Pero el proyecto vive en Python porque permite la misma profundidad conceptual con una fracción del andamiaje administrativo.

Conserva todos los fundamentos (conocimiento paramétrico, alucinación, dos pipelines, embeddings, similitud, recuperación, grounding, citas, abstención, búsqueda híbrida, RRF, reranking, evaluación) y sacrifica selectivamente: no hay API REST ni Docker en las semanas 1–9, no hay seguridad documental implementada ni observabilidad instrumentada, no hay Flyway ni migraciones de esquema.

Tienes un RAG funcional completo en la semana 5. Si por cualquier razón abandonas ahí, te quedas con un sistema que anda.

**Qué vas a poder hacer:** explicar el pipeline entero, modificar cualquiera de sus piezas, tomar decisiones sobre chunking y recuperación basadas en datos reales. No vas a poder reconstruirlo desde cero tan fluidamente como alguien del curso largo, pero sí vas a poder diagnosticar un fallo sin adivinar.

**Para quién:** si quieres capacidad de decisión sobre RAG sin volverte especialista, si es complemento de un curso más amplio, si necesitas evaluar si RAG resuelve un problema específico antes de invertir meses, o si tu ventana real de atención es un trimestre.

**Ruta recomendada:** haz el corto completo (10 semanas), después entra al largo saltando la Parte I, directo a P01. Pierdes poco por duplicación y llegas a la Parte II con el pipeline ya entendido.

---

### ⚖️ 03-Tradeoffs-curso-rag.md — Comparación y decisión

Un documento que responde una pregunta específica: qué se recortó al pasar de 65 guías a 10 semanas, por qué se recortó eso y no otra cosa, y qué te vas a encontrar faltando.

Está estructurado así: primero la aritmética (cuántas horas, cuántas semanas), el criterio que ordenó el recorte (la infraestructura Java era el 40 % del volumen), qué se conserva completo (fundamentos teóricos, pipeline de punta a punta, abstención, evaluación básica), qué se degradó a criterio sin implementación (Parte IV entera: seguridad, observabilidad, portabilidad), y qué se eliminó directamente (API REST, tests, despliegue, migraciones versionadas, caching, multitenancy).

Después una tabla honesta de los tres riesgos predecibles del curso corto y una guía para elegir entre uno y otro según tu contexto.

**Léelo si:** ya leíste los otros dos documentos y necesitas una comparación directa, o necesitas decidir cuál versión tiene sentido para tu restricción de tiempo.

---

## Cómo usar estos documentos

**Si tienes 10 semanas y quieres un sistema RAG funcionando ahora:** empieza por `02-Curso-rag-corto.md`. Lee la ficha del curso y la estructura de las 10 semanas. Sigue semana por semana. En la semana 5 tienes RAG funcional; las semanas 6–10 lo refinan y lo evalúan.

**Si tienes 9–10 meses y quieres profundidad de producción:** empieza por `01-Curso-rag-largo.md`. Comienza con los 12 fundamentos teóricos (Parte I), sigue con el MVP en Java (Parte II), después mejora la recuperación (Parte III), operacionaliza el sistema (Parte IV), y termina con evaluación y cierre (Parte V).

**Si no sabes cuánto tiempo tienes y quieres una panorámica:** lee `03-Tradeoffs-curso-rag.md` primero. Te va a tomar unos 20 minutos y va a aclarar qué cabe en tu ventana y qué no. Después elige uno de los otros dos.

**Si vienes del curso corto y quieres continuar:** salta la Parte I del curso largo (ya la cubriste), entra directo a P01. El pipeline Python que terminaste en 10 semanas es exactamente el estado de conocimiento que el curso largo presupone al empezar a escribir Java.

---

## Características en común

Los tres documentos comparten:

- Criterio antes que cobertura: es mejor entender tres técnicas a fondo que nombrar diez superficialmente.
- Medición: ninguna decisión es "intuición" o "porque lo dice la documentación". Si algo funciona mejor, se mide.
- Abstención como característica central: un sistema RAG que no se abstiene cuando falta evidencia no es un sistema RAG serio.
- Inspiración pedagógica: "el mecanismo antes que la abstracción". Ves cómo funciona una similitud coseno antes de usar un vector store.
- Idioma neutral latinoamericano: prosa antes que listas, tuteo sin "vos" ni "vosotros", español de senior engineer a senior engineer.

---

## Stack disponible

**Curso corto (Python):** Python 3.11+, Ollama, ChromaDB. Modelos locales `embeddinggemma` y `gemma3:4b`.

**Curso largo (Java):** Java 21, Spring Boot, Spring AI, PostgreSQL + pgvector, Ollama. Mismos modelos locales.

Ambos corren completamente locales. No necesitas cuenta en ningún proveedor ni presupuesto de tokens.

---

## Puntos de parada legítimos

No es necesario terminar todo para que el curso haya valido.

- **Semana 5 del curso corto:** RAG funcional con citas y abstención, Python + ChromaDB.
- **Semana 18 del curso largo (P20):** asistente documental completo en Java, API REST, tests, containerizado.
- **Semana 27 del curso largo (P32):** recuperación de calidad profesional con búsqueda híbrida, filtros y reranking.
- **Semana 36 del curso largo (P44):** algo operable en producción.
- **Semana 43 (P53):** sistema completo con evaluación y documentación.

Cada una de esas paradas deja un sistema coherente que funciona. Lo que no funciona es abandonar a mitad de una parte: P25 sin P26 y P27 te deja con dos búsquedas que no hablan entre sí.

---

## Siguiente paso recomendado

Lee el documento que coincida con tu horizonte de tiempo. Si el de 10 semanas encaja en tu vida, empieza ahí. Si tiene un año por delante, el de 65 guías es más recompensador a largo plazo. Si no está claro, lee el de tradeoffs primero: te va a tomar 20 minutos y va a clarificar qué es posible en tu ventana.

Y si al terminar cualquiera de los dos necesitas pasar al siguiente nivel —de demostración a producción, de Python a Java, de 55 horas a 250—, eso está documentado en cada capítulo de cierre.
