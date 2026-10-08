# Tradeoffs entre el curso largo y el curso corto

> Qué se recortó al pasar de 65 guías y 38–43 semanas a 10 semanas,
> por qué se recortó eso y no otra cosa, y qué te vas a encontrar faltando.

Documentos hermanos: `Curso-rag-largo.md` y `Curso-rag-corto.md`.

---

## 1. La aritmética, primero

| | Largo | Corto |
|---|---:|---:|
| Duración | 38–43 semanas | 10 semanas |
| Dedicación | 6 h/semana | 5,5 h/semana |
| Carga total | 218–266 h | ~55 h |
| Unidades | 65 guías | 30 sesiones |
| Stack de implementación | Java 21 + Spring AI + pgvector | Python + Ollama + ChromaDB |
| Primer sistema funcional | Semana 18 (P20) | Semana 5 |

La compresión es de aproximadamente **4 a 1**. Contra el "curso base" del documento largo (T01–T12 más P01–P20, unas 90–105 h) sigue siendo de casi **2 a 1**.

Un recorte de ese tamaño no se hace quitando párrafos. Se hace decidiendo qué capacidades no vas a tener, y el propósito de este documento es que esas decisiones estén escritas y no te sorprendan en el mes tres.

---

## 2. El criterio que ordenó el recorte

El instinto sería recortar proporcionalmente: 25 % de cada parte. Habría sido el peor resultado posible — un curso que toca todo superficialmente y no te deja capaz de nada.

El recorte fue asimétrico y siguió una observación concreta sobre dónde estaban realmente las horas:

> El volumen del curso largo no está en los conceptos de RAG. Está en la infraestructura Java.

P03, P04, P11, P18, P19 y P20 —entorno, proyecto Spring, migraciones con Flyway, API REST, Testcontainers, Docker Compose— suman del orden de 40 horas. Son guías buenas. Pero lo que enseñan es **Spring Boot aplicado a un dominio nuevo**, no RAG. Si ya sabes backend, lo que aprendes ahí es la más chica del capítulo.

Al mover el proyecto a Python, esas 40 horas desaparecen casi enteras sin que se pierda un solo concepto de recuperación. Ese fue el hallazgo que hizo viable el curso de 10 semanas. Todo lo demás son consecuencias.

Dos criterios secundarios completaron el ajuste. **Prioridad al criterio sobre la cobertura**: entre explicar tres técnicas a fondo y nombrar diez, se eligió lo primero. Y **el sistema funcional se adelanta**: en el curso largo el MVP cierra en la semana 18; en el corto, en la semana 5. Eso cambia el perfil de riesgo del curso entero, porque un abandono en la semana 12 del curso corto todavía te deja con un sistema que anda.

---

## 3. Lo que se conserva completo

Conviene empezar por acá, porque es más de lo que la relación 4 a 1 sugiere.

**Todos los fundamentos conceptuales.** Las 12 guías teóricas (T01–T12) están íntegras, fusionadas en cinco sesiones. Conocimiento paramétrico, alucinación, los dos pipelines, tokens y ventana, chunking, embeddings, similitud, sparse contra dense, grounding, citas, abstención y los siete modos de fallo. Nada de eso se sacrificó, porque es exactamente lo que no se puede recuperar leyendo documentación después.

**El pipeline completo de punta a punta.** Ingestión, fragmentación, embeddings, vector store, recuperación, construcción de prompt, generación, citas y abstención. El sistema del curso corto hace lo mismo que el MVP del largo; lo hace en Python y sin API REST.

**La abstención como criterio de calidad.** Es la característica que más se recorta en cursos comprimidos y la que más distingue un sistema serio. Sobrevive, con su prueba de regresión (la política de licencia de maternidad ausente) vigente desde la semana 5.

**La inspección por etapas.** El equivalente de P14 aparece en la semana 4 del curso corto, antes de que haya generación. Sin eso, todo diagnóstico posterior es adivinanza.

**Búsqueda híbrida y RRF.** Se conservan porque son la mejora con mejor relación entre esfuerzo y ganancia medible de toda la Parte III.

**La evaluación, en versión mínima.** Dataset propio, Hit Rate, Precision@K y evaluación de abstención. Se discutió recortarla y se decidió que no: sin métricas, las decisiones de chunking y topK se vuelven superstición, y el curso perdería su tesis central.

---

## 4. Lo que se degradó

Degradado significa: lo vas a conocer como criterio, no como algo que implementaste.

**Java, Spring AI y pgvector.** En el largo son el stack completo. En el corto son una sesión de lectura en la semana 10 donde comparas cada pieza de tu pipeline Python con su equivalente. Sabes que `ChatClient` existe y qué hace; no lo usaste.

**Toda la Parte IV.** Seguridad documental, prompt injection, información sensible, observabilidad, rendimiento, manejo de fallos y portabilidad pasan de doce guías con código a una sesión de panorámica. Vas a saber que el filtro de permisos va en el retrieval y no en el prompt, y por qué. No vas a haberlo implementado.

**Reranking y transformación de consultas.** En el largo son cuatro guías (P28, P29, P30, P31) con experimentación. En el corto son una sesión que las combina y usa el propio LLM como reranker, que es la versión más simple y más lenta.

**Chunking estructural.** De guía propia (P22) a una parte de la semana 6.

**Métricas de respuesta.** Recall@K, MRR, fidelidad y completitud se explican; se implementan solo Hit Rate y Precision@K.

---

## 5. Lo que se eliminó

Estas capacidades no van a estar. Están listadas con el número de guía del curso largo para que sepas exactamente adónde ir cuando las necesites.

| Capacidad ausente | Guías del largo | Cuándo se vuelve un problema |
|---|---|---|
| API REST y contrato OpenAPI | P18 | Cuando alguien más tenga que consumir el sistema |
| Contenedorización y despliegue | P20, P44 | Cuando salga de tu máquina |
| Pruebas automatizadas del flujo | P19, P50 | Cuando un cambio rompa algo en silencio |
| Migraciones y esquema versionado | P11 | Cuando el modelo de datos cambie con datos ya cargados |
| Indexación incremental | P35 | Cuando el corpus se actualice a diario |
| Procesamiento asíncrono y colas | P36 | Cuando alguien suba cien documentos de una vez |
| Seguridad documental por permisos | P37 | Cuando haya más de un tipo de usuario |
| Mitigación de prompt injection | P38 | Cuando los documentos no los controles tú |
| Observabilidad instrumentada | P40 | Cuando tengas que explicar una respuesta de hace tres días |
| Caching y capacidad | P41 | Cuando haya concurrencia real |
| Degradación controlada ante fallos | P42 | Cuando Ollama se caiga a mitad de una consulta |
| Parent-child retrieval | P24 | Con documentos largos y muy estructurados |
| Compresión de contexto | P31 | Cuando el costo por consulta importe |
| Multi-query retrieval | P29 | Con preguntas ambiguas o de cobertura amplia |
| Diversidad de resultados | P32 | Cuando el topK traiga cinco versiones del mismo párrafo |
| Memoria conversacional resumida | P34 | En conversaciones largas |
| Multitenancy | P37, P53 | Con más de un cliente sobre el mismo sistema |
| Pruebas de regresión de calidad | P50 | Cuando cambies configuración con frecuencia |

Hay un patrón que vale la pena nombrar: **casi todo lo eliminado es lo que separa un proyecto de un servicio**. El curso corto te lleva hasta "funciona y sé por qué". El largo sigue hasta "otra gente lo usa y sigue funcionando". Son dos objetivos distintos, y el corto es honesto sobre cuál persigue.

---

## 6. El cambio de método, que es el recorte menos visible

Este es el tradeoff que no aparece en ninguna tabla y probablemente el más importante.

El curso largo aplica una regla: **el estudiante implementa cada pieza**. Concepto, ejemplo manual, laboratorio, abstracción, integración. Es lo que produce la capacidad de reconstruir el sistema desde cero sin el documento delante.

El curso corto no puede sostener eso en 55 horas, así que divide:

**Implementas lo que genera criterio.** Fragmentación con overlap, similitud coseno a mano con numpy, construcción del prompt, lógica de citas, regla de abstención, fusión RRF, cálculo de métricas. Son las piezas donde el "por qué" importa y donde escribirlas cambia lo que entiendes.

**Recibes hecho lo que solo consume tiempo.** Lectura de archivos, CLI, argumentos, formateo de salida, parseo de PDF. Nada de eso te enseña RAG.

La consecuencia honesta: al terminar el curso corto vas a poder **explicar** el sistema completo y **modificar** cualquiera de sus piezas, pero reconstruirlo entero desde una hoja en blanco te va a costar más que a alguien que hizo el largo. Es un nivel de fluidez distinto, no solo menos horas.

---

## 7. Los tres riesgos de la versión corta

Los digo explícitamente porque son predecibles.

**El primero: creer que sabes más de lo que sabes.** Terminar en 10 semanas con un sistema que anda produce una confianza que el alcance real no respalda. Un RAG de tres políticas ficticias en Python no es un RAG en producción, y la distancia entre ambos es casi toda la Parte IV. El antídoto es la sección 5 de este documento.

**El segundo: el estancamiento en la semana 5.** El curso corto concentra el riesgo en un punto. Si el hito de la semana 5 no se cumple, las cinco semanas restantes no tienen sobre qué apoyarse. Por eso está marcado como punto de parada y no como checkpoint: si no funciona, se resuelve ahí, no se sigue.

**El tercero: evaluación demasiado tarde.** En la semana 2 eliges chunk size y en la semana 4 eliges topK, pero solo en la semana 9 tienes con qué saber si acertaste. Son siete semanas de decisiones a ciegas.

Es el defecto más claro del diseño y tiene un arreglo conocido: adelantar Hit Rate a la semana 4, con un dataset mínimo de diez preguntas, y dejar en la semana 9 solo las métricas de respuesta y abstención. Cuesta unos 40 minutos extra en la semana 4. Si prefieres esa versión, es un ajuste razonable y está sin aplicar únicamente porque no estaba pedido.

---

## 8. Cómo elegir

**El curso corto sirve si** quieres capacidad de decisión sobre RAG sin volverte especialista, si es complemento de un curso de IA más amplio, si necesitas evaluar si RAG resuelve un problema concreto antes de invertir meses, o si tu ventana real de atención es un trimestre y no un año. Es también la mejor puerta de entrada al largo: cinco semanas de curso corto te dan más contexto para decidir que cinco de fundamentos teóricos.

**El curso largo sirve si** vas a construir y operar esto en producción, si necesitas la fluidez de poder reconstruirlo sin notas, si el stack de tu organización es Java y Spring, o si tienes un horizonte real de nueve o diez meses.

**Ruta combinada, que es la que recomendaría:** haz el corto completo y después entra al largo saltando la Parte I —ya la cubriste— directo a P01. Pierdes poco por duplicación y llegas a la Parte II con el pipeline ya entendido, que es exactamente el estado mental que el curso largo asume al empezar el proyecto.

---

## 9. Resumen en una tabla

| Dimensión | Largo | Corto |
|---|---|---|
| Fundamentos conceptuales | Completos | Completos |
| Pipeline RAG de punta a punta | Sí | Sí |
| Citas y abstención | Sí | Sí |
| Búsqueda híbrida y RRF | Sí, con experimentación | Sí, versión directa |
| Reranking | Cuatro guías | Una sesión |
| Evaluación | Nueve guías, cinco métricas | Una semana, dos métricas |
| Stack de producción | Implementado | Panorámica |
| Seguridad y observabilidad | Implementadas | Criterio, sin código |
| API, tests, despliegue | Sí | No |
| Reconstruir desde cero sin notas | Objetivo declarado | Fuera de alcance |
| Riesgo de abandono | Alto (10 meses) | Bajo (10 semanas) |
| Sistema funcional al abandonar | Solo después de la semana 18 | Después de la semana 5 |

La última fila es, en la práctica, el argumento más fuerte a favor de la versión corta — y la razón por la que la ruta combinada tiene sentido.
