# 01 — Estilos de comunicación

> El mapa completo: los dos ejes que clasifican cualquier integración, dónde cae cada tecnología, y
> por qué la decisión de fondo no es el protocolo sino el acoplamiento temporal. Es el capítulo que
> los seis siguientes dan por leído. Asume
> [`01-fundamentos-y-descomposicion/01`](../01-fundamentos-y-descomposicion/01-que-es-un-microservicio.md)
> y no repite el razonamiento de
> [`arquitectura/01-bases/01-bases/08`](../../01-bases/01-bases/08-comunicacion-e-integracion.md),
> que es su dueño.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

`orders` tiene que decirle a `inventory` que reserve existencias. Tienes cuatro formas de hacerlo y
las cuatro funcionan el día que las pruebas:

```text
A. llamada HTTP y espero la respuesta
B. llamada gRPC y espero la respuesta
C. publico un evento y sigo
D. encolo un comando y alguien lo procesa
```

La diferencia no aparece el día bueno. Aparece el martes que `inventory` tarda ocho segundos: en A y
B, `orders` se queda esperando y acaba cayéndose también; en C y D, `orders` no se entera y el
trabajo se hace cuando el otro vuelva — a cambio de que el usuario ya no sabe si su reserva salió.

Esa es la decisión real, y no es de protocolo: es **de quién depende de quién para estar vivo**. El
protocolo viene después.

---

## 2. 🧱 Los dos ejes

**Qué es.** Toda integración se clasifica con dos preguntas, y con eso se sitúa cualquier tecnología.

```text
                    │ uno-a-uno                  │ uno-a-muchos
────────────────────┼────────────────────────────┼──────────────────────────────
síncrono            │ request-response           │ (no existe en la práctica:
(espero respuesta)  │ HTTP, gRPC unario          │  nadie espera a N receptores)
────────────────────┼────────────────────────────┼──────────────────────────────
asíncrono           │ comando por cola           │ publicación-suscripción
(no espero)         │ notificación unidireccional│ eventos en un topic
                    │ request-async-response     │ streaming
```

**Cómo va.** Fíjate en la casilla vacía: **no existe el síncrono uno-a-muchos** porque esperar a
varios receptores multiplica el fallo y la latencia por el número de receptores. Cuando alguien
"llama a tres servicios y espera a los tres", eso son tres request-response en paralelo, no un
uno-a-muchos.

**Cuánto.** Cada casilla tiene su precio, y conviene tenerlo en una tabla mental:

| Estilo | Qué cuesta | Qué se gana |
|---|---|---|
| Request-response | Acoplamiento temporal, latencia acumulada, fallo propagado | Respuesta inmediata, error inmediato, flujo fácil de leer |
| Comando por cola | Respuesta diferida, orden que gestionar, idempotencia obligatoria | El receptor puede estar caído |
| Publicación-suscripción | Consistencia eventual, nadie sabe el estado global | Añadir un consumidor no toca al emisor |

**Cuándo sí y cuándo no.** La regla de entrada, que sirve para el 80 % de los casos: **síncrono para
consultas que el usuario está esperando; asíncrono para efectos que pueden ocurrir un segundo
después**.

> **Veredicto:** el eje que decide es el temporal, no el protocolo. Pregúntate primero si el que
> llama necesita al otro vivo **ahora**; el resto —HTTP o gRPC, cola o topic— es una decisión de
> segundo orden.

---

## 3. 🧱 Acoplamiento temporal, que es la decisión de fondo

**Qué es.** Dos servicios están acoplados en el tiempo cuando uno necesita que el otro esté
disponible **en ese instante** para poder completar su trabajo.

**Cómo va.** Y aquí está el matiz que separa una buena respuesta de una mala: pasar a una cola no
elimina el acoplamiento temporal, **lo traslada**.

```text
Síncrono   → orders depende de que INVENTORY esté vivo ahora
Asíncrono  → orders depende de que el BROKER esté vivo ahora
```

Lo que compras no es independencia absoluta: es cambiar una dependencia de tu servicio de negocio,
que despliegas cada semana y que tiene tanta lógica como para fallar, por una dependencia de una
pieza de infraestructura que se diseña para estar disponible y que no cambia casi nunca. La
diferencia es enorme en la práctica, y por eso el patrón vale — pero decirlo así, con el matiz, es lo
que demuestra que lo entiendes.

**Cuánto.** Se paga en consistencia eventual visible para el usuario, en un broker que operar, y en
que **todo consumidor tiene que ser idempotente**, porque la entrega es al-menos-una-vez
([`06`](06-mensajeria-y-eventos.md)).

**Cuándo sí.** Cuando el efecto puede ocurrir un poco después y el usuario no necesita confirmación
inmediata: reservar, notificar, actualizar una proyección, integrar con un tercero lento.

**Cuándo no.** Cuando el usuario necesita una respuesta que depende del otro: "¿tengo saldo?", "¿hay
stock?". Aquí la asincronía no simplifica, complica — porque acabas inventando un mecanismo de espera
sobre algo que no fue diseñado para esperar.

> **Veredicto:** asíncrono no significa "sin dependencias", significa "dependo del broker en vez de
> del otro servicio". Es un cambio de dependiente, y es un buen cambio, pero no es magia.

---

## 4. ⚖️ Dónde cae cada tecnología

La tabla que sitúa todo lo que verás en una entrevista. Cada una se desarrolla en su capítulo.

| Tecnología | Eje | Se usa para | Capítulo |
|---|---|---|---|
| **HTTP/REST** | Síncrono 1:1 | Consultas y comandos entre servicios, y todo lo que sale al exterior | [`02`](02-http-entre-servicios.md) |
| **gRPC unario** | Síncrono 1:1 | Lo mismo, con contrato compilado y deadlines que se propagan | [`03`](03-grpc.md) |
| **gRPC streaming** | Asíncrono 1:1 con conexión | Flujos largos entre servicios, telemetría, sincronización | [`03`](03-grpc.md) |
| **WebSocket** | Bidireccional con estado | Empuje al navegador cuando hace falta ida y vuelta | [`05`](05-tiempo-real-websockets-y-sse.md) |
| **SSE** | Empuje 1:1 sobre HTTP | Notificar al navegador sin necesidad de ida y vuelta | [`05`](05-tiempo-real-websockets-y-sse.md) |
| **Webhook** | Asíncrono 1:1 entre sistemas | Que un tercero te avise, o avisar a un tercero | [`05`](05-tiempo-real-websockets-y-sse.md) |
| **Cola** | Asíncrono 1:1 | Comandos: hay un destinatario y se espera un efecto | [`06`](06-mensajeria-y-eventos.md) |
| **Topic** | Asíncrono 1:N | Eventos: se publica un hecho y quien quiera reacciona | [`06`](06-mensajeria-y-eventos.md) |

Y la distinción que más rinde en una entrevista, porque ordena todo lo demás:

```text
Comando  → "haz esto"       destinatario conocido, se espera un efecto
Evento   → "esto ha pasado" sin destinatario, el emisor no sabe quién escucha
```

Si `orders` publica `ReserveInventory` en un topic, está mandando un comando disfrazado de evento: sabe
perfectamente quién debe reaccionar y qué debe hacer. Eso acopla igual que una llamada, pero con
menos garantías y peor diagnóstico. El nombre delata la intención: **los eventos se nombran en
pasado**.

---

## 5. 🧰 Qué significa "asíncrono" en cada plataforma

Hay dos "asíncronos" que se confunden constantemente, y la confusión cuesta puntos:

```text
Asíncrono de INTEGRACIÓN   → el que llama no espera la respuesta del otro servicio
Asíncrono de EJECUCIÓN     → el hilo no se bloquea mientras espera (no bloqueante)
```

Son independientes: puedes hacer una llamada HTTP síncrona de integración con un cliente no
bloqueante, y puedes consumir de una cola —integración asíncrona— con código perfectamente
bloqueante. Lo primero es diseño de sistema; lo segundo es uso de recursos dentro de un proceso.

| Plataforma | Qué te da hecho para no bloquear | Lo que te deja a ti |
|---|---|---|
| **Java** | Hilo por petición, con virtual threads el bloqueo deja de ser caro; y un modelo reactivo completo si se quiere | Elegir entre ambos y no mezclarlos a medias. Y saber que el pool sigue siendo finito |
| **Node/TS** | Bucle de eventos: nada bloquea salvo que tú lo bloquees | Que ninguna operación de CPU se cuele en el hilo principal, porque tumba el servicio entero |
| **Go** | Goroutines baratas: se escribe bloqueante y el planificador lo resuelve | Cancelar con `context`, o las goroutines se acumulan y se fugan |
| **Python** | `asyncio` con ASGI; también el modelo clásico por procesos | Que ninguna llamada bloqueante entre en un manejador asíncrono: congela el bucle entero |

- **Lo que te deja a ti en las cuatro:** que la elección de modelo de ejecución **no cambia el estilo
  de integración**. Pasar de bloqueante a no bloqueante no desacopla nada en el tiempo: sigues
  necesitando al otro vivo.
- La fila de Python y la de Node describen el mismo fallo con distinto nombre, y es el más caro de
  los cuatro: una operación pesada dentro del bucle deja de atender **todo**, no solo esa petición.

> **🧰 Plataforma:** cuando en una entrevista te pregunten "¿usarías reactivo?", la respuesta empieza
> distinguiendo estos dos asíncronos. Casi siempre lo que quieren saber es cómo aguantas
> concurrencia, y eso hoy tiene más de una respuesta según la plataforma y la versión.

---

## 6. 🧭 Cómo se elige, en voz alta

```text
¿El que llama necesita la respuesta para continuar?
│
├─ sí ─► ¿la necesita el usuario, en esta petición?
│        ├─ sí ─► síncrono. HTTP o gRPC según 04.
│        └─ no ─► ¿puedes calcularlo antes? proyección o caché, y quitas la llamada
│
└─ no ─► ¿hay un destinatario concreto que debe hacer algo?
         ├─ sí ─► comando por cola
         └─ no ─► evento en un topic: publicas el hecho y te olvidas
```

Y las dos frases que conviene tener listas:

> "Síncrono cuando el usuario está esperando la respuesta; asíncrono cuando lo que hay es un efecto
> que puede ocurrir un segundo después."

> "Si sé quién tiene que reaccionar y qué tiene que hacer, es un comando, aunque lo publique en un
> topic. Si solo estoy contando un hecho, es un evento."

---

## 7. 🔭 Dónde aparece de verdad

Tres situaciones donde estos ejes dejan de ser teoría:

- **La pantalla que no carga porque un servicio secundario está lento.** El origen es una llamada
  síncrona que no debería serlo: el dato era decorativo. Se arregla sacándolo de la ruta o dándole un
  valor por defecto, no añadiendo réplicas del servicio lento.
- **El pico de ventas que tumba el cobro.** El tráfico entra por HTTP y llega tal cual al servicio
  más lento de la cadena. Una cola delante convierte el pico en una fila: se tarda más, pero no se
  cae nada. Es el argumento de **absorber picos**, que es de los pocos que justifican por sí solos
  pasar a asíncrono.
- **La integración con el tercero que se cae los viernes.** Cualquier llamada síncrona a un sistema
  que no controlas convierte su disponibilidad en la tuya. Ahí la cola no es una optimización, es la
  única forma de que su viernes no sea el tuyo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Asíncrono es más rápido" | Es más **lento** de extremo a extremo. Lo que mejora es la disponibilidad y la absorción de picos |
| "Usamos eventos para desacoplar" | ¿De qué? Desacopla en el tiempo, no en el contrato: el esquema del evento sigue siendo un contrato que romper |
| "Asíncrono y no bloqueante son lo mismo" | Uno es diseño de integración, el otro es uso de hilos. Se pueden combinar en las cuatro formas |
| "Con una cola ya no hay dependencias" | Ahora dependes del broker. Es mejor dependiente, no es ninguno |
| "Publicamos un comando en el topic" | Si sabes quién debe reaccionar y qué debe hacer, es un comando: nómbralo así y mándalo a una cola |
| "REST es síncrono por definición" | HTTP admite patrones asíncronos —202 con recurso de estado, webhooks—. Lo síncrono es cómo lo usas |
| "Llamamos a los tres servicios a la vez, es uno-a-muchos" | Son tres request-response en paralelo. Uno-a-muchos síncrono no existe: nadie espera a N receptores |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4,
   "Microservice Communication Styles". **Es la mejor exposición de los dos ejes, y de ahí sale el
   vocabulario de este capítulo.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3,
   "Interprocess communication in a microservice architecture", con las variantes de cada estilo.
3. **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*, Addison-Wesley, 2003.
   Capítulo 4, sobre canales de mensajes: el vocabulario de comando y evento viene de aquí.
4. **Fuente primaria** — Chris Richardson, «Pattern: Remote Procedure Invocation», con sus fuerzas y
   consecuencias:
   [microservices.io/patterns/communication-style/rpi.html](https://microservices.io/patterns/communication-style/rpi.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: Messaging»:
   [microservices.io/patterns/communication-style/messaging.html](https://microservices.io/patterns/communication-style/messaging.html).
6. **Fuente primaria** — Martin Fowler, «Microservice Trade-Offs», para el coste del acoplamiento de
   disponibilidad:
   [martinfowler.com/articles/microservice-trade-offs.html](https://martinfowler.com/articles/microservice-trade-offs.html).
7. **Charla** — GOTO Conferences, «The Many Meanings of Event-Driven Architecture» (Martin Fowler).
   Es la charla que ordena el vocabulario de eventos, comandos y notificaciones.

---

## 🧠 Preguntas

1. ¿Cuáles son los dos ejes que clasifican una integración? 🟢
2. Define acoplamiento temporal. 🟢
3. ¿Qué diferencia hay entre un comando y un evento? 🟢
4. ¿Cómo se nombran los eventos y por qué? 🟢
5. ¿Qué casilla de la matriz de §2 está vacía y por qué? 🟢
6. Enumera el precio de request-response, comando por cola y publicación-suscripción. 🟢
7. ¿En qué sentido un evento sigue siendo un contrato? 🟢
8. ¿Por qué pasar a una cola no elimina el acoplamiento temporal? 🟡
9. Diferencia entre asíncrono de integración y no bloqueante. Da un ejemplo de cada combinación. 🟡
10. "Asíncrono es más rápido": ¿qué parte es falsa y qué querían decir? 🟡
11. ¿Por qué publicar `ReserveInventory` en un topic es un error de diseño? 🟡
12. ¿Por qué una operación de CPU en el hilo principal de Node afecta a peticiones que no tienen
    nada que ver? 🟡
13. Te preguntan "¿usarías programación reactiva?". Estructura la respuesta. 🟡
14. ¿Qué le pides al broker antes de apoyar tu diseño en él? Nombra tres propiedades. 🟡
15. ¿Qué cambia entre las cuatro plataformas al hablar de "asíncrono", y qué NO cambia? 🟡
16. `orders` necesita saber si hay stock antes de confirmar. ¿Síncrono o asíncrono? Justifica. 🟠
17. El cobro se satura en los picos de venta. ¿Qué cambio de estilo propones y qué empeora? 🟠
18. Integras con un proveedor externo que se cae a menudo. ¿Cómo evitas que su disponibilidad sea la
    tuya? 🟠
19. ¿Cuándo convertirías una llamada síncrona existente en un evento, y qué tienes que añadir al
    hacerlo? 🟠
20. Un dato decorativo de la pantalla viene de un servicio lento. Da tres soluciones ordenadas por
    esfuerzo. 🟠
21. ¿Cómo explicarías a negocio que una confirmación pasa a ser eventual? 🟠
22. Toma el flujo de confirmación de pedido —reservar, cobrar, notificar— y asigna un estilo de
    comunicación a cada paso, justificando cada elección y diciendo qué pasa si falla. 🟠
23. Diseña la integración entre `orders` y un sistema legado que solo acepta ficheros por lotes
    cada hora, sin que el usuario perciba que es por lotes. 🔴
24. Un equipo propone pasar todas las llamadas del sistema a eventos "para desacoplar". Da tu
    respuesta en dos minutos, con lo que concedes y lo que rechazas. 🔴
25. Dibuja la misma operación en los cuatro estilos de §1 y di, para cada una, qué ve el usuario
    cuando `inventory` tarda ocho segundos. 🔴

---

**Anterior:** — · **Siguiente:** [`02` — HTTP entre servicios](02-http-entre-servicios.md) ·
**Relacionado:** [`06` — Mensajería y eventos](06-mensajeria-y-eventos.md) ·
[`arquitectura/01-bases/01-bases/08`](../../01-bases/01-bases/08-comunicacion-e-integracion.md)

**Taller, opcional:** [`06/03` — HTTP entre servicios](../06-talleres/03-http-entre-servicios.md).
