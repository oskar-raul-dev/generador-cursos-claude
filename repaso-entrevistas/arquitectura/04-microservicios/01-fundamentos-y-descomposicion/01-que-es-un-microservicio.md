# 01 — Qué es un microservicio

> Qué es un microservicio, qué no lo es, qué cuesta y qué se gana de verdad. Es el capítulo que fija
> el vocabulario del corpus entero: autonomía, frontera, precio. Asume tomada la decisión de ir a
> microservicios —el razonamiento vive en
> [`arquitectura/01-bases/01-bases/02`](../../01-bases/01-bases/02-estilos-de-despliegue.md)—
> y no la repite.
>
> **Este capítulo no lleva sección de plataformas** (§6, punto 6 de la guía): aquí no hay nada que
> implementar todavía. La primera comparativa de las cuatro plataformas está en
> [`05`](05-el-servicio-por-dentro.md), cuando
> hablemos de lo que hay dentro de un servicio.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Te preguntan "¿qué es un microservicio?" y contestas lo que contesta todo el mundo: *"un servicio
pequeño, independiente, que hace una sola cosa"*. El entrevistador asiente y pregunta lo siguiente:

> —¿Y cuánto es pequeño? ¿Mil líneas? ¿Diez endpoints?

Ahí se acaba la respuesta ensayada, porque no hay número que contestar. Y si dices uno, la siguiente
pregunta es peor: *"entonces si parto mi monolito en veinte servicios de mil líneas que comparten la
base de datos, ¿ya tengo microservicios?"*.

El problema de la definición por tamaño es que **no predice nada**. Dos sistemas con servicios del
mismo tamaño se comportan de formas opuestas según una sola propiedad que el tamaño no captura: si
puedes desplegar uno sin desplegar los demás. Esa es la propiedad que decide si el lunes despliegas
tranquilo o coordinas una ventana con tres equipos.

Así que la definición útil no habla de líneas. Habla de **autonomía**.

---

## 2. 🧱 La definición por autonomía

**Qué es.** Un microservicio es un servicio **desplegable de forma independiente**, dueño exclusivo
de sus datos, modelado alrededor de una frontera de negocio.

Las tres piezas no son una lista de deseos: son una sola idea mirada desde tres ángulos. No puedes
desplegar solo si otro servicio lee tu base de datos —la migración os ata—. Y no puedes ser dueño de
tus datos mucho tiempo si tu frontera no coincide con una frontera de negocio, porque cada cambio de
reglas te obliga a tocar dos servicios a la vez.

**Cómo va.** La prueba práctica cabe en tres preguntas, y es la que conviene decir en voz alta
porque demuestra criterio en lugar de memoria:

```text
¿Puedes desplegar este servicio un martes sin avisar a nadie?
¿Puedes cambiar su esquema de base de datos sin avisar a nadie?
¿Puedes probarlo sin levantar otros tres?

Tres síes  → es un microservicio.
Un no      → es un módulo con latencia de red.
```

**Cuánto.** La autonomía no es gratis y este capítulo entero es el recibo: se paga en latencia,
consistencia, operación, dinero y esfuerzo de implementación (§4). No se menciona la autonomía sin
mencionar el precio, ni en un documento ni en una entrevista.

**Cuándo sí.** Cuando esa autonomía te compra algo concreto que hoy te falta: desplegar sin
coordinar, escalar una parte sin escalar el resto, aislar un fallo, o dejar que dos equipos avancen
sin pisarse.

**Cuándo no.** Cuando el sistema lo mantiene un equipo que despliega junto de todos modos. Ahí la
autonomía no compra nada y el precio se paga igual.

> **Veredicto:** un microservicio se define por lo que puedes hacer con él sin pedir permiso, no por
> lo que pesa. Si tu respuesta a "¿qué es un microservicio?" no contiene la palabra *desplegar*,
> todavía no has contestado.

---

## 3. 🧱 Dueño de sus datos: la propiedad que casi nadie defiende

**Qué es.** Nadie más lee ni escribe el almacén de un servicio. Si otro necesita esos datos, los
pide por la API o los recibe por un evento; nunca los consulta por su cuenta.

**Cómo va.** En el sistema de ejemplo del corpus, `orders` no hace `SELECT` sobre las tablas de
`inventory`. Le pregunta, o escucha `InventoryReserved`. Y la consecuencia incómoda llega enseguida:
el `JOIN` que antes era una línea de SQL ahora es una llamada de red que puede fallar, o una copia
local de datos ajenos que puede estar vieja. Eso no es un efecto secundario del diseño: **es el
diseño**, y lo desarrollamos en [`03-datos-y-consistencia`](../03-datos-y-consistencia/).

**Cuánto.** Cuesta consultas que ya no existen, datos duplicados que hay que mantener al día, y
consistencia eventual visible para el usuario. A cambio compra lo único que hace independiente al
despliegue: que tu migración de esquema no sea el problema de nadie más.

**Cuándo sí.** Siempre que quieras llamar microservicio a lo que estás construyendo. Aquí no hay
gradación.

**Cuándo no.** Durante una migración, con fecha de caducidad escrita y visible, y para casos
acotados —una réplica de solo lectura para informes— que `03/01` desarrolla con sus condiciones.

> **Veredicto:** compartir la base de datos convierte a dos servicios en uno con más latencia. Es la
> línea que separa una arquitectura de microservicios de un monolito distribuido, y es exactamente
> la que se cruza por comodidad un jueves por la tarde.

---

## 4. 🪦 Lo que no define un microservicio

Cuatro criterios que circulan como definición y no lo son. Los nombramos aquí porque son las cuatro
respuestas que un entrevistador espera poder desmontar:

- **El tamaño en líneas de código.** No existe el número. Un servicio de tres mil líneas con una
  frontera clara es mejor microservicio que uno de trescientas que necesita a otros dos para
  arrancar.
- **"Hace una sola cosa".** Suena a Unix y confunde: la unidad no es la función, es la **capacidad de
  negocio**. `orders` hace muchas cosas —crear, confirmar, cancelar, consultar— y está bien que las
  haga: todas comparten las mismas reglas y los mismos datos.
- **Un repositorio por servicio.** Es una decisión de organización del código, no de arquitectura, y
  se discute en [`04/06`](../04-operacion-y-resiliencia/06-despliegue-y-entrega.md). Hay sistemas de microservicios en un
  monorepo y monolitos distribuidos repartidos en cuarenta repositorios.
- **Usar contenedores, Kubernetes o la nube.** Son el envase. Un monolito en un contenedor sigue
  siendo un monolito, y está perfectamente bien que lo sea.

> **⚠️ Advertencia:** la respuesta "un microservicio tiene entre X e Y líneas" no solo es imprecisa,
> es la señal que el entrevistador usa para clasificarte. Quien da un número está recitando un blog;
> quien habla de despliegue y datos ha mantenido uno.

---

## 5. 💰 El precio de entrada

Cuatro cosas que antes eran gratis y ahora se pagan. No son "complejidad añadida" en abstracto: son
estas cuatro, con nombre, y conviene poder enumerarlas de memoria.

| Antes, en el monolito | Después, entre servicios | Lo que cuesta |
|---|---|---|
| Llamada a un método | Llamada de red | Latencia, fallo parcial, timeouts que cuadrar |
| `@Transactional` | Saga con compensaciones | Consistencia eventual y estados intermedios visibles |
| Stack trace en un log | Traza distribuida | Instrumentación, propagación de contexto y su coste |
| Un despliegue | N despliegues versionados | Pipeline por servicio, compatibilidad entre versiones |

La fila que más duele en una entrevista es la segunda. Cuando alguien propone separar `orders` y
`payments`, la pregunta que sigue es *"¿y cómo garantizas que no se cobra un pedido que no se reservó?"*
— y la respuesta honesta empieza por reconocer que **ya no hay transacción**, sigue por la saga de
[`03/03`](../03-datos-y-consistencia/03-saga.md) y termina admitiendo que existen estados intermedios que el
negocio tiene que aceptar.

Hay además un coste fijo por servicio que nadie presupuesta: su pipeline, su tablero, sus alertas,
su rotación de guardia, su imagen que actualizar cuando salga la siguiente vulnerabilidad de la
librería de turno. Multiplícalo por el número de servicios antes de proponer veinte.

> **💰 Costo:** la cuenta rápida para una entrevista es "cada servicio nuevo cuesta un pipeline, un
> tablero, una alerta y un turno de guardia, aunque tenga cien líneas". Es el argumento que mata los
> nano-servicios sin necesidad de discutir de arquitectura.

---

## 6. ⚖️ Qué se gana de verdad

Cinco beneficios reales, cada uno con el asterisco que casi siempre se omite. El asterisco es la
parte que demuestra que los has cobrado alguna vez.

| Se gana | El asterisco |
|---|---|
| Despliegue independiente | Solo si los contratos son compatibles hacia atrás. Si no, coordinas igual |
| Escalado diferencial | Solo si la parte cara está aislada. Si el cuello es la base de datos compartida, no ganas nada |
| Autonomía de equipo | Solo si la frontera del servicio coincide con la del equipo |
| Aislamiento de fallo | **No es automático**: sin timeout y sin circuit breaker, el fallo se propaga igual, y encima por red |
| Libertad de stack | Real, pero se paga en herramientas duplicadas y gente que no puede ayudar en el servicio de al lado ([`05/06`](../05-plataformas/06-la-matriz-de-decision.md)) |

Fíjate en el cuarto. "Los microservicios aíslan fallos" es media verdad: **la separación crea la
posibilidad de aislar, no el aislamiento**. Un servicio que llama a otro con el timeout por defecto
y sin circuit breaker está más expuesto que el monolito equivalente, porque ahora hay una red en
medio que puede quedarse colgada sin devolver error. Eso es [`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md),
y es el capítulo que convierte esta fila en cierta.

Y el segundo tiene una versión aún más incómoda: **separar un servicio no lo hace más rápido**. Le
añade una llamada de red. Lo que compra es poder darle más instancias a la parte que las necesita,
que es otra cosa y hay que decirla con esas palabras.

> **Veredicto:** los microservicios no compran rendimiento ni resiliencia. Compran **independencia**
> —de despliegue, de escalado, de equipo— y con esa independencia puedes construir resiliencia si la
> pagas aparte.

---

## 7. 🧭 Cómo se elige, en voz alta

El árbol que conviene tener en la cabeza cuando la pregunta es "¿harías microservicios aquí?":

```text
¿Cuántos equipos van a tocar esto?
│
├─ uno ────────────► monolito modular. Punto.
│                    Módulos con fronteras, un despliegue, cero red.
│
└─ dos o más
   │
   ├─ ¿las fronteras del dominio están claras y estables?
   │   ├─ no ──────► monolito modular primero, y extraes cuando se estabilicen.
   │   │             Cortar mal cuesta más que no cortar.
   │   └─ sí
   │       │
   │       ├─ ¿hay algo que necesite desplegarse o escalar por separado?
   │       │   ├─ no ─► monolito modular. La autonomía no compra nada todavía.
   │       │   └─ sí ─► extrae ESE servicio. Uno. Y mide.
```

Fíjate en que ninguna rama termina en "monta quince servicios". Empezar por microservicios exige
acertar las fronteras antes de conocer el dominio, y eso casi nunca sale bien: es el argumento del
*monolith first*, y conviene citarlo por su nombre porque tiene autor y tiene contraargumento.

La frase para decirlo sin sonar conservador:

> "Empezaría con un monolito modular y fronteras explícitas. En cuanto una de esas fronteras
> necesite desplegarse o escalar por su cuenta, la extraigo — y para entonces ya sé por dónde
> cortar, que es lo que hoy no sé."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Los microservicios escalan mejor" | Permiten **escalar por separado**. El rendimiento por petición empeora: hay red donde había una llamada a un método |
| "Un microservicio es un servicio pequeño" | Es un servicio **desplegable solo y dueño de sus datos**. El tamaño es consecuencia, no criterio |
| "Aíslan fallos" | Crean la **posibilidad** de aislarlos. Sin timeouts ni circuit breaker, el fallo se propaga igual y con menos señales |
| "Cada equipo elige su tecnología" | Puede, y casi siempre no debe. La libertad de stack se paga en herramientas, observabilidad y gente que no puede cubrir al de al lado |
| "Compartimos base de datos solo para leer" | Entonces no son dos servicios: tu migración sigue siendo el problema de otro |
| "Si está en Kubernetes, son microservicios" | Kubernetes es el envase. Un monolito contenerizado sigue siendo un monolito |
| "Empezamos con microservicios para no migrar después" | Exige acertar fronteras sin conocer el dominio. Cortar mal es más caro que extraer más tarde |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 1, "What Are
   Microservices?", y capítulo 3, "Splitting the Monolith". **Si solo lees uno de todo el bloque, lee
   este.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 1, "Escaping
   monolithic hell": el planteamiento del precio está mejor argumentado que en ningún otro sitio.
3. **Fuente primaria** — Martin Fowler y James Lewis, «Microservices», sobre las nueve
   características comunes del estilo:
   [martinfowler.com/articles/microservices.html](https://martinfowler.com/articles/microservices.html).
4. **Fuente primaria** — Martin Fowler, «MicroservicePremium», el precio de entrada en una página:
   [martinfowler.com/bliki/MicroservicePremium.html](https://martinfowler.com/bliki/MicroservicePremium.html).
5. **Fuente primaria** — Martin Fowler, «MonolithFirst», el argumento del árbol de §7:
   [martinfowler.com/bliki/MonolithFirst.html](https://martinfowler.com/bliki/MonolithFirst.html).
6. **Fuente primaria** — Chris Richardson, «Pattern: Microservice Architecture», la ficha del patrón
   con sus fuerzas y sus consecuencias:
   [microservices.io/patterns/microservices.html](https://microservices.io/patterns/microservices.html).
7. **Charla** — GOTO Conferences, «Monolith to Microservices» (Sam Newman). Los primeros veinte
   minutos son el mejor resumen hablado del precio.

---

## 🧠 Preguntas

1. Define microservicio sin usar la palabra "pequeño". 🟢
2. ¿Cuáles son las tres propiedades que componen la definición por autonomía? 🟢
3. ¿Qué significa exactamente que un servicio sea "dueño de sus datos"? 🟢
4. Enumera las cuatro cosas que dejan de ser gratis al pasar de monolito a servicios. 🟢
5. ¿Qué coste fijo tiene cada servicio nuevo, independientemente de su tamaño? 🟢
6. Nombra tres criterios que no definen un microservicio. 🟢
7. ¿Qué es el monolito modular y en qué se diferencia de un monolito a secas? 🟢
8. ¿Por qué un repositorio por servicio no es un criterio de arquitectura? 🟢
9. Un servicio no puede probarse sin levantar otros tres. ¿Qué te dice eso, y de qué propiedad
   concreta carece? 🟡
10. "Los microservicios escalan mejor": ¿qué parte es cierta y qué parte es falsa? 🟡
11. Diferencia entre "aislar un fallo" y "poder aislar un fallo". 🟡
12. Dos servicios comparten una base de datos, pero uno solo lee. ¿Siguen siendo independientes?
    Justifica desde el despliegue. 🟡
13. ¿Por qué separar un servicio empeora la latencia por petición aunque mejore la escalabilidad del
    sistema? 🟡
14. ¿Qué preguntarías para decidir si extraer `payments` de `orders`, y en qué orden? 🟡
15. Tu equipo es de cinco personas y despliega todo junto los jueves. ¿Qué compra la autonomía aquí?
    🟠
16. El negocio pide "escalar el sistema" y alguien propone separar tres servicios. La base de datos
    está al 90 % de CPU. ¿Qué respondes? 🟠
17. ¿Cuándo aceptarías compartir un almacén entre dos servicios, y qué escribirías para que esa
    excepción no se vuelva permanente? 🟠
18. Defiende "monolito modular primero" ante un entrevistador que lo lee como falta de ambición. 🟠
19. Te dan un sistema con veinte servicios y un único pipeline que los despliega juntos. ¿Cuánto
    cuesta esa arquitectura y qué está comprando? 🟠
20. Estima el coste anual de operar un servicio más, en las categorías que sepas nombrar. Di qué no
    puedes estimar. 🟠
21. Diseña la prueba de tres preguntas de §2 aplicada a un sistema que conozcas, y di cuál falla. 🟠
22. Un equipo propone veinte microservicios para un producto nuevo sin usuarios. Argumenta en contra
    en dos minutos, sin decir "es demasiada complejidad". 🔴
23. Dibuja el mismo flujo de compra como monolito y como tres servicios, y marca en el segundo los
    cuatro puntos donde puede fallar algo que en el primero no podía. 🔴
24. Te piden extraer un servicio de un monolito de diez años sin documentación. Da los tres primeros
    pasos y di qué medirías para saber que el primero funcionó. 🔴

---

**Anterior:** — · **Siguiente:** [`02` — Descomposición y fronteras](02-descomposicion-y-fronteras.md)
· **Relacionado:** [`04` — El monolito distribuido](04-el-monolito-distribuido.md) ·
[`arquitectura/01-bases/01-bases/02`](../../01-bases/01-bases/02-estilos-de-despliegue.md)

**Taller, opcional:** [`06/01` — El monolito y su contrato](../06-talleres/01-el-monolito-y-su-contrato.md).
