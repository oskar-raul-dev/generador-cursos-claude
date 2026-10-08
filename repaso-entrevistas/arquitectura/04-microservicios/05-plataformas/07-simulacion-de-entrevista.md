# 07 — Simulación de entrevista

> El examen del bloque: preguntas que cruzan las cuatro plataformas y escenarios donde hay que elegir
> y defender. Asume leídos [`01`](01-que-cambia-entre-plataformas.md) a
> [`06`](06-la-matriz-de-decision.md). Las respuestas de los escenarios están en
> [`08`](08-respuestas.md).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 Cómo se usa esto

Este bloque se examina distinto, porque las preguntas de plataforma son trampas educadas:

```text
1. Nunca respondas con una plataforma sin decir qué la decide en ESE caso.
2. Reconoce siempre lo que la otra opción hace mejor. Quien no concede nada,
   parece que no conoce la alternativa.
3. Si citas un número —memoria, arranque, rendimiento—, di de dónde sale.
4. Dos minutos por pregunta, en voz alta. Los escenarios, quince minutos y papel.
```

La trampa característica: defender la plataforma que dominas como si fuera universalmente mejor. La
respuesta que puntúa es la que dice **en qué caso elegiría otra**.

---

## 2. 🧠 Preguntas transversales

### Los ejes

1. **S1.** Nombra cuatro ejes que diferencian plataformas de verdad. 🟢
2. **S2.** ¿Qué dos ejes casi nunca importan y por qué? 🟡
3. **S3.** ¿Por qué el arranque es una propiedad económica? 🟡
4. **S4.** ¿Qué mecanismo de propagación de contexto tiene cada plataforma? 🟢
5. **S5.** ¿Qué tumba a cada una de las cuatro? 🟢

### Java

6. **S6.** ¿Cuál es la diferencia de fondo entre Spring Boot y Quarkus? 🟡
7. **S7.** ¿Qué cambió con los hilos virtuales en el argumento sobre reactivo? 🟡
8. **S8.** ¿Por qué una anotación puede no aplicarse? 🟠
9. **S9.** ¿Qué compra y qué rompe la compilación nativa? 🟡

### Node/TS

10. **S10.** ¿Qué tumba a un servicio de Node, y por qué congela en vez de degradar? 🟡
11. **S11.** ¿Qué comprueban los tipos de TypeScript y qué no? 🟢
12. **S12.** ¿Por qué el BFF de la web encaja tan bien en esta plataforma? 🟡
13. **S13.** ¿Por qué es débil en los patrones de datos? 🟡

### Go

14. **S14.** ¿Qué lleva un `context.Context` y qué se rompe si se olvida? 🟡
15. **S15.** ¿Qué es una fuga de goroutines y cómo se reconoce? 🟢
16. **S16.** ¿Por qué la ausencia de marcos es una decisión? 🟡
17. **S17.** ¿Dónde gana Go de verdad, y dónde cuesta defenderlo? 🟠

### Python

18. **S18.** ¿Qué impide y qué no impide el bloqueo global del intérprete? 🟡
19. **S19.** ¿Cuál es el fallo característico de un servicio asíncrono en Python? 🟡
20. **S20.** ¿Qué aporta la validación por esquemas frente a los tipos de TypeScript? 🟢
21. **S21.** ¿Por qué el empaquetado es su punto débil menos discutido? 🟡

### La decisión

22. **S22.** ¿Cuáles son los criterios de elección, en orden? 🟢
23. **S23.** ¿Qué patrón separa más a Java del resto en la matriz? 🟡
24. **S24.** Nombra los tres casos de poliglotismo preaprobados y su argumento. 🟢
25. **S25.** Enumera lo que cuesta añadir una plataforma. 🟢
26. **S26.** ¿Por qué "¿ya existe en la casa?" cambia tantos resultados? 🟠
27. **S27.** ¿Qué diferencia hay entre poliglotismo y deuda de plataformas? 🟠
28. **S28.** ¿Por qué en banca la respuesta tiende a una plataforma principal? 🟡

### Las que descolocan

29. **S29.** Un candidato afirma que Go es siempre mejor para microservicios. Responde. 🔴
30. **S30.** El entrevistador defiende una plataforma que no dominas. ¿Cómo lo gestionas? 🔴
31. **S31.** ¿Qué plataforma **no** dominas y cómo te pondrías al día? 🔴
32. **S32.** Si entras a un equipo con cinco plataformas y un servicio cada una, ¿qué haces? 🔴
33. **S33.** ¿Qué responderías a "el lenguaje da igual, lo importante es la arquitectura"? 🟠
34. **S34.** Te piden elegir plataforma sin conocer el sistema. Responde en dos minutos. 🔴

---

## 3. 🎭 Escenarios de diseño

### E1 — Tres servicios nuevos, tres perfiles

**Fuerza:** la elección con criterio. Obliga a justificar cada una y a reconocer la más difícil.

Un sistema necesita: un servicio de suscripciones con sagas y facturación periódica; un agente de
métricas con una réplica por nodo; y un servicio de recomendaciones basado en modelos. La casa es de
Java.

Elige plataforma para cada uno, justifica y di cuál te costaría más defender.

### E2 — La reescritura por rendimiento

**Fuerza:** decir que no con datos. La respuesta correcta es no reescribir.

Un equipo propone reescribir tres servicios de Java en Go porque "Go es más rápido". Los servicios
consultan bases de datos y llaman a otros servicios; el p99 es de 400 ms y la dirección pregunta por
el coste de infraestructura.

Diseña tu respuesta: qué mides, qué concedes, qué alternativas ofreces.

### E3 — La política de plataformas

**Fuerza:** la decisión organizativa. Obliga a pensar más allá de la tecnología.

Una organización con 25 servicios y tres equipos ha acumulado cuatro plataformas sin política: una de
ellas tiene un solo servicio y un solo mantenedor, que se va el mes que viene.

Escribe la política y el plan de consolidación, con su proceso de excepciones.

### E4 — El mismo patrón en cuatro plataformas

**Fuerza:** el conocimiento comparado. Obliga a explicar diferencias sin repetir folletos.

Te piden explicar cómo implementarías **outbox más consumidor idempotente** en las cuatro
plataformas, y qué cambia de una a otra.

Hazlo en cinco minutos, diciendo qué viene hecho y qué se escribe.

### E5 — El servicio que no encaja en la plataforma principal

**Fuerza:** la excepción justificada. Obliga a defender una excepción sin abrir la puerta a todas.

El equipo de frontend pide escribir el BFF en Node/TS. La casa es de Java y no hay ningún servicio de
Node en producción.

Prepara la propuesta: argumento, requisitos, coste y qué pasa si el equipo no puede operarlo.

---

## 4. 🗣️ Las frases que hay que tener listas

> "La velocidad del lenguaje casi nunca decide: en un servicio con base de datos, el 95 % del tiempo
> es espera. Lo que sí decide es quién lo mantiene y qué le da la plataforma para sus patrones."

> "Cada plataforma nueva no es un lenguaje más: es un chassis, unos paneles, una imagen base y una
> guardia más. Por eso las excepciones tienen que ganarse."

> "Prefiero dos plataformas bien sostenidas que cinco a medias. Y si solo una persona sabe operar
> una, eso no es poliglotismo: es un punto único de fallo con nombre y apellidos."

---

**Anterior:** [`06` — La matriz de decisión](06-la-matriz-de-decision.md) · **Siguiente:**
[`08` — Respuestas](08-respuestas.md) · **Relacionado:**
[`04-operacion-y-resiliencia/05`](../04-operacion-y-resiliencia/05-service-mesh-y-sidecar.md) ·
[`01-fundamentos-y-descomposicion`](../01-fundamentos-y-descomposicion/)
