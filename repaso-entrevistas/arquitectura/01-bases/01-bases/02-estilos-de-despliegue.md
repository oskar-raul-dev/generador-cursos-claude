# 02 — Estilos de despliegue

> El catálogo de formas de repartir un sistema en unidades desplegables: monolito,
> monolito modular, service-based, microservicios, SOA, serverless, space-based,
> microkernel y pipeline. Con el criterio para elegir y el precio de cada uno.
> Asume leído [`01` — Fundamentos](01-fundamentos-del-arquitecto.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

*"¿Microservicios o monolito?"* es la pregunta más frecuente y la peor respondida de las
entrevistas de arquitectura. La respuesta mala es "microservicios, porque escalan". La
respuesta mala número dos es "depende", dicho y nada más.

La buena empieza reconociendo qué se está comprando de verdad:

```text
Separar un servicio NO compra rendimiento.
Compra despliegue independiente y autonomía de equipo.
Y lo paga con latencia, consistencia, operación y dinero.
```

Todo este capítulo es ese cálculo, aplicado a nueve estilos.

> ⚠️ **Advertencia.** Una llamada a un método pasa de nanosegundos a milisegundos cuando
> se convierte en una llamada de red: **cinco órdenes de magnitud**. Quien dice que los
> microservicios son más rápidos no ha medido.

---

## 2. 🧱 Monolito

**Qué es.** Una sola unidad desplegable: un `.jar`, una base de datos, un pipeline. Las
llamadas entre módulos son llamadas a métodos y la consistencia es una transacción ACID.

**Cuándo sí.** Producto nuevo con dominio aún no entendido; equipo de menos de ~15
personas; cuando la consistencia transaccional fuerte es un requisito de negocio. Es el
punto de partida por defecto, y Fowler lo defiende explícitamente con *MonolithFirst*.

**Cuándo no.** Cuando el pipeline tarda 40 minutos, cuando un cambio en facturación
obliga a desplegar el motor de riesgos, o cuando cinco equipos se bloquean entre sí.

> 💰 **Costo.** Es el estilo más barato en operación y el más caro en coordinación. El
> cruce llega antes por el número de equipos que por el número de usuarios.

> **Veredicto:** el monolito no es deuda técnica. Es la decisión correcta hasta que las
> fronteras del dominio se conocen, y muchas veces después también.

---

## 3. 🧩 Monolito modular

**Qué es.** Un solo despliegue, pero con fronteras internas reales: módulos con API
pública explícita, sin acceso a las clases internas del vecino, cada uno dueño de sus
tablas. Nadie hace `JOIN` contra las tablas de otro módulo.

**Cuándo sí.** Casi siempre que alguien propone microservicios "para el futuro". Te da
el 80 % del beneficio —fronteras, propiedad, testabilidad— sin la red de por medio, y
deja el corte hecho para separar después el módulo que realmente lo necesite.

**Cuándo no.** Cuando dos módulos necesitan ciclos de despliegue o perfiles de escalado
genuinamente distintos, o cuando el número de equipos ya rompe el pipeline compartido.

**Cómo se hace cumplir**, porque sin mecanismo es una intención:

- **Spring Modulith** verifica las fronteras en test y genera la documentación.
- **ArchUnit**: "ninguna clase de `billing.internal` es importada fuera de `billing`".
- **Módulos de Java (JPMS)** o módulos de build (Maven/Gradle) para hacerlo estructural.

> 🧠 **Modelo mental.** Microservicios sin red. Si no puedes mantener fronteras dentro
> de un proceso, donde el compilador te ayuda, no las vas a mantener a través de HTTP,
> donde nadie te ayuda.

> **Veredicto:** es la respuesta correcta más veces de las que se admite, y decirlo en
> entrevista te separa del candidato que recita el catálogo.

---

## 4. 🧰 Service-based architecture

**Qué es.** El punto medio que casi nadie nombra: **de 4 a 12 servicios gruesos** por
dominio, desplegados por separado, pero **compartiendo una base de datos monolítica**.
Es una categoría propia en la taxonomía de Richards y Ford.

**Cuándo sí.** Cuando quieres despliegue independiente pero no puedes pagar el precio de
la consistencia distribuida —banca, seguros, cualquier dominio con reporting transversal
y transacciones que cruzan entidades—.

**Cuándo no.** Cuando el esquema compartido se convierte en el punto de acoplamiento que
bloquea a todos los equipos, que es exactamente su modo de fallo.

> **Veredicto:** nombrarlo demuestra que sabes que entre "monolito" y "microservicios"
> hay un espectro, no un interruptor. Vale un punto casi gratis.

---

## 5. 🔬 Microservicios

**Qué es.** Servicios pequeños, desplegables por separado, **cada uno dueño de sus
datos**, alineados con un contexto acotado y operados por un equipo.

**Qué lo define de verdad**, más allá del tamaño:

- **Base de datos por servicio.** Sin esto no son microservicios, son un monolito
  distribuido — el peor de los dos mundos: el acoplamiento del monolito más la latencia
  de la red.
- **Despliegue independiente.** Si hay que desplegar tres juntos, es uno solo mal
  cortado.
- **Fallo aislado.** Si la caída de uno tumba a los demás, no hay aislamiento.

**Cuándo sí.** Múltiples equipos que se bloquean entre sí; partes del sistema con
perfiles de escalado radicalmente distintos; necesidad de aislar fallos por dominio.

**Cuándo no.** Equipo pequeño, dominio poco entendido, o sin madurez operativa. La
factura mínima de entrada, que conviene enumerar en voz alta:

```text
Observabilidad: trazas distribuidas, correlation IDs, logs agregados
Resiliencia:    timeouts, reintentos, circuit breakers, DLQ
Datos:          saga u outbox — ya no hay transacción que cruce servicios
Operación:      CI/CD por servicio, service discovery, config externalizada
Contratos:      versionado y compatibilidad hacia atrás
```

> 💰 **Costo.** El primer microservicio no cuesta un servicio: cuesta toda esa
> plataforma. Por eso el segundo es barato y el primero no.

> **Veredicto:** microservicios resuelven un problema **organizativo** con una solución
> técnica. Si no tienes el problema organizativo, estás pagando la factura sin recibir
> la mercancía.

---

## 6. 🚌 SOA y el ESB

**Qué es.** El precursor: servicios grandes, orientados a reutilización empresarial,
comunicados a través de un **ESB** (Enterprise Service Bus) que centraliza
enrutamiento, transformación de formatos y orquestación.

**La diferencia real con microservicios**, que es lo que se pregunta:

| | SOA / ESB | Microservicios |
|---|---|---|
| Inteligencia | En el bus | En los extremos |
| Datos | Compartidos, esquema canónico | Por servicio |
| Granularidad | Gruesa, por capacidad empresarial | Fina, por contexto acotado |
| Gobierno | Centralizado | Descentralizado por equipo |
| Protocolo | SOAP, WS-*, XML | HTTP/JSON, gRPC, eventos |

> **Regla de entrevista:** *"smart endpoints, dumb pipes"* es la frase que resume la
> ruptura. En SOA el bus es listo; en microservicios el bus es tonto a propósito.

**Cuándo sí.** No se elige hoy para un sistema nuevo. **Pero en banca se hereda**, y ahí
la pregunta cambia: no es "¿SOA o micro?", es "¿cómo convives con el ESB mientras
migras?" — lo que lleva a Strangler Fig y a capa anticorrupción.

> **Veredicto:** el ESB murió como elección y sobrevive como restricción. Saber operar
> dentro de uno vale más, en banca y en cualquier empresa con legado, que saber criticarlo.

---

## 7. ☁️ Serverless / FaaS

**Qué es.** Funciones que se ejecutan bajo demanda sin servidor que gestionar —Lambda,
Cloud Functions—, facturadas por invocación y duración, escaladas a cero.

**Cuándo sí.** Carga esporádica o muy variable; procesamiento dirigido por eventos;
tareas programadas; *glue code* entre servicios gestionados.

**Cuándo no.** Latencia estricta y constante (**cold start**); procesos largos (hay
límite de duración); cargas sostenidas y predecibles, donde sale más caro que un
contenedor encendido; dependencia fuerte de conexiones a base de datos relacional, que
el modelo de concurrencia agota.

> 📝 **Contexto.** El cold start de Java era el argumento clásico para descartar Lambda
> en el mundo Spring. Sigue existiendo, pero hoy se acota con SnapStart, con imágenes
> nativas de GraalVM y con la concurrencia provisionada. Si citas el cold start como
> problema, cita también la mitigación: es la pregunta de seguimiento garantizada.

> **Veredicto:** serverless es una decisión de **modelo de costo y de operación** antes
> que de arquitectura. Se justifica con la curva de carga, no con la moda.

---

## 8. 🧮 Space-based architecture

**Qué es.** El estilo que ataca el cuello de botella que ninguno de los anteriores
resuelve: **la base de datos central**. Las instancias trabajan sobre una **rejilla de
datos en memoria** replicada entre nodos, y la persistencia ocurre de forma asíncrona
detrás. Escalar es añadir nodos a la rejilla.

**Cuándo sí.** Picos extremos e impredecibles con estado compartido: venta de entradas,
subastas, trading, reservas. En banca aparece con Hazelcast, Coherence o Gemfire.

**Cuándo no.** Carga moderada o predecible. Es complejo, caro y el modelo de
consistencia en memoria es difícil de razonar.

> **Veredicto:** es el estilo que más gente ha oído nombrar y menos gente sabe cuándo se
> usa. Basta con saber qué problema ataca —el cuello de botella de la BD— para
> contestarlo bien.

---

## 9. 🔌 Microkernel (plug-in)

**Qué es.** Un núcleo mínimo con la lógica estable, más plug-ins que aportan lo
variable. El núcleo no conoce a los plug-ins: los descubre por un registro y los invoca
por una interfaz.

**Cuándo sí.** Motores de reglas, sistemas de productos financieros configurables,
procesadores de formatos, IDEs. En Java lo tienes en `ServiceLoader` y en el sistema de
plug-ins de Eclipse.

**Cuándo no.** Cuando la variabilidad es menor de lo que crees: un `switch` de tres
casos no necesita arquitectura de plug-ins.

> **Veredicto:** es Strategy elevado a estilo arquitectónico. Si sabes explicar esa
> frase, sabes el patrón.

---

## 10. 🔗 Pipeline (pipes and filters)

**Qué es.** Una cadena de filtros independientes, cada uno con una transformación, unidos
por tuberías. Cada filtro solo conoce su entrada y su salida.

**Cuándo sí.** ETL, procesamiento de transacciones por lotes, cadenas de validación y
enriquecimiento, compiladores. En Java lo tienes en los `Filter` de servlets, en los
interceptores de Spring y en cualquier `Stream` encadenado.

**Cuándo no.** Cuando la lógica necesita ver el conjunto entero, o cuando el flujo tiene
ramas y ciclos: un pipeline con condicionales deja de serlo.

> **Veredicto:** es el estilo natural del batch bancario, y por eso conviene tenerlo
> nombrado antes de llegar a [`05-banca`](../05-banca/).

---

## 11. 🧭 Cómo se elige, en voz alta

La secuencia que conviene recitar cuando la pregunta es "¿qué arquitectura usarías?":

```text
1. ¿Cuántos equipos y se bloquean entre sí?      → si no, monolito modular
2. ¿El dominio está entendido?                   → si no, monolito primero
3. ¿Hay partes con escalado radicalmente distinto?→ si sí, candidato a separar ESA parte
4. ¿Puedo pagar consistencia eventual?           → si no, service-based antes que micro
5. ¿Tengo la plataforma operativa ya montada?    → si no, el primer servicio cuesta 10x
```

> **Regla de entrevista:** no se separa un sistema. **Se separa un módulo**, el que
> duele, y se mide. Proponer "cortamos en doce servicios" de entrada es la señal más
> clara de que no lo has hecho nunca.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Microservicios escalan mejor" | Escalan **independientemente**; el throughput total suele bajar |
| "Cada servicio en su repo" | Ortogonal al estilo; un monorepo con microservicios es válido |
| "Microservicios = contenedores" | Un monolito también va en un contenedor |
| "SOA es microservicios con otro nombre" | Difieren en datos, granularidad, gobierno y dónde vive la inteligencia |
| "Serverless no tiene servidores" | Los tiene; no los gestionas tú, y pagas por invocación |
| "Empezamos con micro para no migrar después" | Sin conocer el dominio, cortas mal y migrar entre servicios es peor |
| "Monolito = código espagueti" | Son ejes distintos: hay monolitos modulares y microservicios espagueti |

---

## 📚 Para profundizar

- **Libro** — Mark Richards y Neal Ford, *Fundamentals of Software Architecture*, 2ª ed.
  (O'Reilly, 2025). Parte II completa: un capítulo por estilo, con puntuación por
  atributo de calidad. Es la taxonomía que usa este capítulo.
- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulos
  1–3: qué son, cuándo no usarlos, y cómo modelar la frontera.
- **Libro** — Sam Newman, *Monolith to Microservices* (O'Reilly, 2019). Capítulo 3:
  los patrones de descomposición, incluido Strangler Fig.
- Martin Fowler — [MonolithFirst](https://martinfowler.com/bliki/MonolithFirst.html):
  el argumento de empezar por el monolito, del propio autor.
- [microservices.io — Pattern: Monolithic Architecture](https://microservices.io/patterns/monolithic.html)
  y [Microservice Architecture](https://microservices.io/patterns/microservices.html):
  fichas con beneficios y contras enfrentados.
- [Spring Modulith — Reference documentation](https://docs.spring.io/spring-modulith/reference/index.html):
  cómo se verifican fronteras en un monolito modular de Spring Boot.
- **Tutorial** — Baeldung, «Microservices in Java»:
  el aterrizaje en código de todo lo anterior.
- **Video** — GOTO Conferences, charlas de Sam Newman sobre *Monolith to
  Microservices*; y *DeveloperToArchitect*, lecciones sobre space-based y
  service-based. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué compra de verdad separar un sistema en microservicios? 🟢
2. ¿Qué es un monolito modular y en qué se diferencia de un monolito a secas? 🟢
3. ¿Qué caracteriza a la service-based architecture? 🟢
4. ¿Qué problema concreto ataca la arquitectura basada en espacio? 🟢
5. ¿En qué se parece un pipeline a la cadena de filtros de un servlet? 🟢
6. ¿Qué es un monolito distribuido y por qué es el peor resultado posible? 🟡
7. Nombra tres diferencias entre SOA con ESB y microservicios. 🟡
8. ¿Qué es el cold start y cómo se acota hoy en Java? 🟡
9. Cita tres cosas de la factura operativa mínima de microservicios. 🟡
10. ¿Qué significa "smart endpoints, dumb pipes"? 🟡
11. ¿Cuándo elegirías microkernel y qué patrón GoF lo sustenta? 🟡
12. ¿Por qué "base de datos por servicio" es el criterio que define microservicios? 🟠
13. ¿Por qué el primer microservicio cuesta mucho más que el segundo? 🟠
14. Un equipo de 5 personas quiere empezar con 12 microservicios. ¿Qué les dices? 🟠
15. ¿Qué tres preguntas haces antes de responder "monolito o microservicios"? 🟠
16. ¿Cómo se hace cumplir la frontera de un módulo en un monolito modular? 🟠
17. ¿Cuándo serverless sale más caro que un contenedor encendido? 🟠
18. Un servicio no se puede desplegar sin desplegar otros dos. ¿Qué pasó? 🟠
19. En banca heredas un ESB con 40 servicios SOAP. ¿Cómo lo modernizas sin
    detener el negocio? 🔴
20. El pipeline tarda 50 minutos y bloquea a 6 equipos. ¿Separas? Argumenta con
    números y di qué separas primero. 🔴
21. Te piden justificar ante el CTO por qué NO vas a microservicios. ¿Qué dices? 🔴
22. Diseña el corte de un e-commerce monolítico: ¿qué módulo separas primero y
    cómo mides si acertaste? 🔴

---

**Anterior:** [`01` — Fundamentos](01-fundamentos-del-arquitecto.md) ·
**Siguiente:** [`03` — Arquitecturas de aplicación](03-arquitecturas-de-aplicacion.md) ·
**Relacionado:** [`06` — DDD estratégico](06-ddd-estrategico.md)
