# Parte V — Evaluación y cierre

**9 guías · 30–38 h · semanas 37–43**

Sin dataset, toda mejora es una creencia. Esta parte convierte el "creo que mejoró" en un número reproducible, y es la que recalibra el instinto de ingeniería que viene de otras disciplinas.

Va al final porque necesita un sistema completo que medir. Pero el hábito arranca antes: desde P13 mantenés preguntas de prueba, y desde P21 comparás configuraciones. Acá eso se formaliza.

## Estructura

La parte está ordenada en tres bloques: construcción del dataset, implementación de métricas, y síntesis de decisiones.

| Guía | Qué construyes | Criterio de salida |
|---|---|---|
| P45 | Dataset de evaluación | Al menos un 20 % de los casos exige abstención |
| P46 | Métricas de recuperación | Hit Rate, Precision@K, Recall@K, MRR |
| P47 | Métricas de respuesta | Corrección, relevancia, fidelidad, completitud, citas |
| P48 | Evaluación de abstención | Medís los dos errores: falsa abstención y alucinación |
| P49 | Experimentos comparativos | Existe una tabla y al menos una decisión cambió |
| P50 | Pruebas de regresión | Un cambio de configuración que degrada se detecta solo |
| P51 | Revisión arquitectónica final | Repasás mantenibilidad, seguridad, rendimiento, trazabilidad |
| P52 | Entrega y documentación | Un tercero clona, ejecuta y entiende cada parámetro |
| P53 | Evoluciones posteriores | Sabés qué sigue y por qué no estaba acá |

## Reglas de oro

**Los resultados negativos se documentan.** Si el reranking de P30 no mejora tus métricas, eso se escribe. Es información real, no un fracaso que esconder.

**Las métricas son medibles por vos.** Precisión, recall, latencia, costo, tiempo de reindexación. Nada de "porcentajes de mejora" sin la medición que los respalde.

**El dataset contiene fallos.** Uno construido con preguntas que ya respondés bien no mide nada; solo tranquiliza.

## Cambio de enfoque

Hasta acá el desarrollo fue en ciclos cortos: una guía, un commit. Esta parte exige una vista telescópica: mirar todo el sistema de una sola vez, ver dónde está el cuello de botella, decidir qué se cambia y qué se deja.

## Punto de control

Al terminar P52 tenés documentación completa: README con arquitectura, ADR sobre cada decisión, reporte de métricas, dataset con preguntas reales, demo funcionando. Un tercero puede clonar y entender por qué cada parámetro vale lo que vale.

## Después de esta parte

No hay parte VI. Pero hay evoluciones anotadas en P53: multitenancy, multimodal RAG, Graph RAG, agentic RAG, tool calling. Son el paso siguiente natural cuando el sistema actual sea sólido y medido.

## El ritmo de 43 semanas

| Semanas | Etapa |
|---:|---|
| 1–5 | Fundamentos teóricos |
| 6–18 | MVP con Java, Spring AI, Ollama y pgvector |
| 19–27 | Recuperación avanzada |
| 28–36 | Conversación, seguridad y operación |
| 37–40 | Evaluación |
| 41–43 | Proyecto final, documentación y margen |

El margen de las últimas semanas no es relleno: es la reserva para los bloqueos reales.
