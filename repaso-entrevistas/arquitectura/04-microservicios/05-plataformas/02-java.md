# 02 — Java

> Qué te da el ecosistema de Java para cada patrón del corpus, qué cuesta, y cómo se defiende una
> elección dentro de él sin recitar folletos. Asume leído [`01`](01-que-cambia-entre-plataformas.md),
> que fija la baseline y la tabla maestra. **Aquí no se explica ningún patrón**: se dice qué te da la
> plataforma y se enlaza. El detalle de Spring por dentro es de
> [`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Java es el perfil base de este corpus, y eso trae una pregunta inevitable:

> —¿Por qué Spring Boot y no Quarkus? ¿O Micronaut?

La respuesta mala es comparar funciones, porque las tres hacen lo mismo. La buena distingue entre lo
que cambia de verdad —**cuándo se resuelve la configuración**, arranque, memoria— y lo que decide en
la práctica: **el ecosistema y la gente**.

Y hay una segunda pregunta que en 2026 aparece sola: si el equipo viene de la línea 3.x de Spring
Boot y la actual es la 4.x, ¿qué implica eso? Eso también es este capítulo.

---

## 2. 🧱 El ecosistema: quién es quién

| | Spring Boot | Quarkus | Micronaut |
|---|---|---|---|
| **Cuándo resuelve** | Sobre todo en arranque, con autoconfiguración | En **compilación**: procesa anotaciones y genera | En **compilación**, igual |
| **Arranque** | Segundos; mejora mucho con compilación nativa | Rápido; muy rápido en nativo | Rápido |
| **Memoria** | La mayor de las tres | Menor | Menor |
| **Ecosistema** | **El más grande, con diferencia** | Amplio y creciente | Más pequeño |
| **Contratación** | Cualquiera lo conoce | Menos gente | Menos gente |
| **Encaja con** | El caso por defecto, y casi todo | Arranque rápido, memoria contada, nativo | Lo mismo, con otra filosofía |

**La respuesta honesta a "¿por qué Spring Boot?"**: por el ecosistema y por la contratación, no por
razones técnicas. Todo lo que este corpus necesita tiene una implementación madura en Spring, y
cualquiera que entre al equipo lo conoce. Eso vale más que unos cientos de milisegundos de arranque en
la mayoría de los sistemas.

**Cuándo mirar a los otros dos**: cuando el arranque y la memoria son requisitos reales —muchas
instancias pequeñas, escalado a cero, funciones efímeras— o cuando la compilación nativa está en el
plan desde el principio.

> **⚠️ Advertencia:** "Quarkus es Spring pero rápido" es un resumen que no sobrevive a la primera
> repregunta. La diferencia de fondo es **cuándo** se resuelve la configuración —en compilación en vez
> de en arranque—, y de ahí salen tanto las ventajas como las restricciones, especialmente con
> reflexión y con carga dinámica.

---

## 3. 🧰 Qué te da Java para cada patrón

La fila de Java de la tabla maestra de [`01`](01-que-cambia-entre-plataformas.md), desarrollada.

| Patrón | Qué te da | Lo que te deja a ti |
|---|---|---|
| [Cliente HTTP](../02-comunicacion/02-http-entre-servicios.md) | Clientes del framework, declarativos incluidos; integración con métricas y resiliencia | **Poner los plazos**: varias combinaciones esperan indefinidamente |
| [gRPC](../02-comunicacion/03-grpc.md) | Generación integrada en la construcción; arranque por convención | Elegir tipo de stub y fijar deadlines por llamada |
| [Mensajería](../02-comunicacion/06-mensajeria-y-eventos.md) | Escucha declarativa, control de concurrencia, reintentos y DLQ configurables | La idempotencia, y entender cuándo confirma el marco |
| [Contratos](../02-comunicacion/07-contratos-y-versionado.md) | Generación desde OpenAPI y `.proto`; verificación de pactos | Elegir contrato primero, que no es el valor por defecto |
| [Outbox](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) | Módulos que lo implementan atado a la transacción | La limpieza de la tabla, que nunca viene incluida |
| [Saga](../03-datos-y-consistencia/03-saga.md) | **El ecosistema más rico**: abstracciones de proceso, motores BPM muy usados en banca | Que el motor no se convierta en el sitio donde vive el negocio |
| [Resiliencia](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md) | Librería completa y declarativa, con métricas | Los umbrales, y la trampa del proxy (§5) |
| [Observabilidad](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md) | Agente que instrumenta sin tocar código | Propagar el contexto a pools y a código asíncrono |
| [Testing](../04-operacion-y-resiliencia/07-testing-de-microservicios.md) | El ecosistema más completo de las cuatro | Que la prueba de componente no levante medio sistema |

**La lectura agregada**: Java es la plataforma donde más cosas vienen hechas. Ese es su valor y
también su riesgo, porque lo hecho esconde comportamiento —y cuando falla hay que entenderlo igual—.

---

## 4. 🧱 El modelo de ejecución, hoy

**Qué es.** Tres formas de atender concurrencia, y la tercera cambió la recomendación de las otras
dos.

| Modelo | Cómo va | Cuándo |
|---|---|---|
| **Hilo por petición** | Un hilo de plataforma bloqueado mientras espera | El modelo clásico; simple de leer y de depurar |
| **Reactivo** | Pocos hilos, flujos no bloqueantes con contrapresión | Concurrencia muy alta o composición de flujos |
| 📝 **Hilos virtuales** | Se escribe bloqueante; el runtime multiplexa sobre pocos hilos reales | El valor por defecto hoy para servicios de espera |

**Cómo va el cambio.** El argumento clásico a favor de reactivo era que bloquear un hilo es caro y el
pool se agota. Con hilos virtuales, bloquear deja de ser caro y se puede sostener mucha concurrencia
de espera **sin cambiar el estilo de programación**. Eso reduce mucho los casos donde reactivo
compensa.

**Dónde sigue compensando reactivo**: cuando hace falta contrapresión real en flujos, o cuando ya
existe una base reactiva coherente. Mezclar ambos modelos a medias sigue siendo el peor resultado
posible, y una llamada bloqueante en medio de una cadena reactiva anula el beneficio entero.

**Lo que no cambia con los hilos virtuales**: el recurso escaso se mueve, no desaparece. Ahora se
agotan antes las conexiones del pool de base de datos o la capacidad del servicio destino, así que el
**límite de concurrencia por destino** pasa a ser más importante, no menos
([`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md)).

---

## 5. 🧱 Las tres trampas de lo declarativo

Java te da mucho hecho detrás de anotaciones, y eso tiene tres fallos característicos que conviene
saber nombrar:

```text
1. El proxy         una llamada interna del mismo objeto no pasa por el proxy,
                    así que la anotación NO se aplica. Sin error, sin aviso.
2. El orden         cuando hay varias anotaciones sobre el mismo método
                    —reintento y circuit breaker—, el orden cambia el comportamiento.
3. Lo implícito     confirmaciones de mensajes, transacciones, gestión de conexiones:
                    el marco decide por ti, y decide bien hasta que el caso es raro.
```

La primera es la que más tiempo hace perder, porque el síntoma es la **ausencia** de comportamiento:
todo funciona, nada protege. La comprobación rápida es mirar si la llamada aparece en las métricas del
mecanismo; si no aparece, no se está aplicando.

> **💡 Truco:** en una entrevista, mencionar la trampa del proxy al hablar de resiliencia o de
> transacciones demuestra experiencia real. Es un fallo que solo se conoce habiéndolo sufrido.

---

## 6. 🧱 Compilación nativa: qué compra y qué rompe

**Qué es.** Compilar la aplicación a un ejecutable nativo en vez de ejecutarla sobre la máquina
virtual.

**Qué compra.** Arranque muy rápido y memoria mucho menor, que es exactamente lo que le falta a Java
frente a Go en el eje operativo de [`01`](01-que-cambia-entre-plataformas.md).

**Qué cuesta.**

| Coste | Detalle |
|---|---|
| Tiempo de construcción | De minutos: cambia el ritmo del pipeline |
| Reflexión y carga dinámica | Hay que declarar lo que se usa; librerías viejas pueden no funcionar |
| Rendimiento sostenido | La máquina virtual optimiza con el tiempo; el nativo no tiene ese margen |
| Diagnóstico | Herramientas distintas de las habituales |

**Cuándo sí.** Funciones efímeras, escalado a cero, muchas instancias pequeñas, o costes de memoria
que pesan de verdad.

**Cuándo no.** Servicios de tráfico constante y larga vida, donde el arranque se paga una vez al día
y el rendimiento sostenido importa más.

> **Veredicto:** la compilación nativa cambia el perfil operativo de Java y lo acerca al de Go, a
> cambio de construcción lenta y de restricciones reales. No es una casilla que se marca: es una
> decisión que condiciona librerías y pipeline.

---

## 7. 🔭 Dónde brilla Java de verdad

Tres casos donde la respuesta correcta es Java y conviene saber argumentarlos:

- **Dominios con reglas de negocio ricas.** Donde hay muchas invariantes, sagas largas y auditoría,
  el ecosistema —incluidos los motores BPM— ahorra meses. Es el caso de banca y seguros.
- **Procesamiento por lotes.** Es territorio maduro y muy poco discutido: reinicio, reintento,
  fragmentación, saltos. Su detalle es de
  [`arquitectura/01-bases/05-banca/03`](../../01-bases/05-banca/03-batch-y-spring-batch.md).
- **Equipos grandes y con rotación.** Convenciones conocidas, herramientas maduras y gente
  disponible. Es el argumento menos técnico y el que más pesa a dos años.

Y el caso donde más cuesta defenderlo: servicios muy pequeños y muy numerosos, donde la memoria por
instancia y el arranque se multiplican por el número de servicios.

---

## 8. 🧭 Cómo se elige dentro del ecosistema

```text
¿El arranque y la memoria son un requisito REAL?
│   (escalado a cero, funciones efímeras, cientos de instancias pequeñas)
│
├─ no ──► Spring Boot. Ecosistema, contratación y todo lo de §3 resuelto.
│
└─ sí
   │
   ├─ ¿Vais a ir a compilación nativa desde el principio? ──► Quarkus o Micronaut,
   │                                                           con el pipeline preparado
   │
   └─ ¿Solo queréis mejorar arranque y memoria sin cambiar de marco?
      └─► Spring Boot afinado: recorte de la imagen, ajuste de memoria,
          y nativo solo si el perfil lo justifica
```

Y la frase que conviene tener lista, porque la pregunta cae a menudo:

> "Spring Boot por defecto, por ecosistema y por gente. Me movería a Quarkus o Micronaut si el
> arranque y la memoria fueran requisito de verdad y la compilación nativa estuviera en el plan desde
> el principio, porque ahí la diferencia no es de funciones: es de cuándo se resuelve la
> configuración."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Spring Boot es pesado" | Consume más memoria y arranca más lento. A cambio trae resuelto casi todo lo de la tabla de §3, y eso también es rendimiento del equipo |
| "Reactivo escala mejor" | Escalaba mejor cuando bloquear era caro. Con hilos virtuales, buena parte de esa ventaja se obtiene sin cambiar de estilo |
| "Con native image arrancas en milisegundos y no pierdes nada" | Pierdes tiempo de construcción, flexibilidad con reflexión y rendimiento sostenido |
| "Quarkus es Spring pero rápido" | La diferencia es **cuándo** se resuelve la configuración; de ahí salen las ventajas y las restricciones |
| "La anotación siempre se aplica" | No si la llamada es interna al mismo objeto: el proxy no interviene y el mecanismo no actúa |
| "Con hilos virtuales ya no hace falta limitar la concurrencia" | Al revés: como es barato lanzar muchas llamadas, el límite por destino importa más |
| "Java no sirve para microservicios pequeños" | Sirve; lo que hay que evaluar es la memoria por instancia multiplicada por el número de servicios |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 2, sobre
   libertad de stack, para situar la elección dentro de un sistema.
2. **Documentación** — Spring Boot, referencia de la línea actual:
   [docs.spring.io/spring-boot](https://docs.spring.io/spring-boot/index.html). **El punto de partida
   para todo lo de §3.**
3. **Documentación** — Quarkus, qué es y en qué se diferencia:
   [quarkus.io/about/](https://quarkus.io/about/).
4. **Documentación** — Micronaut, para completar la comparación de §2:
   [micronaut.io](https://micronaut.io/).
5. **Fuente primaria** — OpenJDK, JEP de hilos virtuales, que es la base del cambio de §4:
   [openjdk.org/jeps/444](https://openjdk.org/jeps/444).
6. **Documentación** — GraalVM, compilación nativa y sus restricciones:
   [graalvm.org/latest/reference-manual/native-image/](https://www.graalvm.org/latest/reference-manual/native-image/).
7. **Documentación** — Resilience4j, la librería de resiliencia de referencia del ecosistema:
   [resilience4j.readme.io/docs/circuitbreaker](https://resilience4j.readme.io/docs/circuitbreaker).
8. **Charla** — Spring I/O / Devoxx, «Virtual Threads in Practice». El cambio de §4 explicado con
   casos reales y con sus límites.

---

## 🧠 Preguntas

1. ¿Cuál es la diferencia de fondo entre Spring Boot y Quarkus? 🟢
2. ¿Por qué Spring Boot es la opción por defecto, dicho con honestidad? 🟢
3. Enumera tres patrones donde el ecosistema de Java te da mucho hecho. 🟢
4. ¿Cuáles son los tres modelos de ejecución y cuándo se usa cada uno? 🟢
5. Nombra las tres trampas de lo declarativo. 🟢
6. ¿Qué compra y qué cuesta la compilación nativa? 🟡
7. ¿Por qué los hilos virtuales cambian el argumento sobre reactivo? 🟡
8. ¿Qué recurso pasa a ser escaso cuando los hilos dejan de serlo? 🟡
9. ¿Por qué una anotación puede no aplicarse, y cómo se detecta? 🟡
10. ¿Por qué el orden de dos anotaciones de resiliencia cambia el comportamiento? 🟡
11. ¿Por qué la compilación nativa complica las librerías que usan reflexión? 🟡
12. ¿En qué caso cuesta más defender Java frente a Go? 🟡
13. ¿Qué revisarías en la configuración por defecto de un servicio Java antes de ponerlo en
    producción? 🟡
14. Te preguntan "¿por qué Spring y no Quarkus?" en una entrevista. Responde en un minuto. 🟠
15. Un equipo quiere migrar a reactivo para aguantar más carga. ¿Qué preguntas antes? 🟠
16. ¿Cuándo propondrías compilación nativa, y qué condiciones pondrías? 🟠
17. Tu servicio tiene un circuit breaker que no actúa. Da la causa más probable y cómo la confirmas.
    🟠
18. El equipo está en Spring Boot 3.5 en 2026. ¿Qué recomiendas? 🟠
19. ¿Qué dejarías fuera de Java en un sistema políglota, y por qué? 🟠
20. ¿Cómo justificarías el consumo de memoria de Java ante una dirección que mira el coste? 🟠
21. Diseña la plantilla de servicio Java del equipo: qué trae resuelto, qué deja abierto y qué
    prohíbe. 🔴
22. Compara Spring Boot, Quarkus y Micronaut para tres servicios con perfiles distintos, y decide
    para cada uno. 🔴
23. Un servicio Java arranca en 40 segundos y el escalado no llega a tiempo. Da el diagnóstico y
    tres líneas de acción ordenadas. 🔴
24. Escribe el plan de migración de la línea 3.x a la 4.x para un sistema con quince servicios, con
    el orden y los riesgos. 🔴

---

**Anterior:** [`01` — Qué cambia entre plataformas](01-que-cambia-entre-plataformas.md) ·
**Siguiente:** [`03` — Node y TypeScript](03-node-y-typescript.md) · **Relacionado:**
[`06` — La matriz de decisión](06-la-matriz-de-decision.md) ·
[`frameworks/01-spring-boot`](../../../frameworks/01-spring-boot/)
