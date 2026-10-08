# 03 — Node y TypeScript

> Qué cambia por ser un runtime de un solo hilo con bucle de eventos, cómo se elige entre un marco
> con opinión y uno sin ella, y dónde este ecosistema gana de verdad. Asume leído
> [`01`](01-que-cambia-entre-plataformas.md). **Aquí no se explica ningún patrón**: se dice qué te da
> la plataforma y se enlaza.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Dos ideas circulan sobre esta plataforma y las dos son falsas a medias:

```text
"Node no sirve para cargas serias"       → falso: sirve, y muy bien, para lo que es
                                            (esperar a otros con muchas conexiones)
"Con TypeScript el contrato está seguro" → falso: los tipos desaparecen al compilar
```

Entre esas dos frases está lo que de verdad hay que saber: **el modelo de ejecución es un hilo con
bucle de eventos**, lo que lo hace excelente para trabajo de espera y frágil ante trabajo de CPU; y
**el tipado es de compilación**, lo que ayuda muchísimo a escribir y no comprueba nada en ejecución.

Y una tercera cosa, que es la que decide muchas veces: es la plataforma del equipo de frontend, y eso
tiene consecuencias organizativas que pesan más que las técnicas.

---

## 2. 🧱 El bucle de eventos, y lo que lo tumba

**Qué es.** Un solo hilo atiende todas las peticiones; las operaciones de entrada y salida no
bloquean, y el hilo sigue atendiendo mientras espera.

**Cómo va.** Eso explica sus dos caras:

```text
Espera (red, base de datos, otro servicio)  → escala muy bien, casi sin coste por conexión
Cómputo (ordenar, serializar, comprimir)    → BLOQUEA todo, incluidas respuestas ya listas
```

**La consecuencia operativa** es específica de esta plataforma: un bloqueo no degrada, **congela**. Y
si hay conexiones persistentes abiertas ([`02-comunicacion/05`](../02-comunicacion/05-tiempo-real-websockets-y-sse.md)),
dejan de fluir también los latidos, con lo que los clientes pueden dar la conexión por muerta y
reconectar en masa justo cuando el proceso ya iba mal.

**Las salidas**, en orden: sacar el cómputo a otro servicio; moverlo a hilos de trabajo; o partirlo
para ceder el control periódicamente. Y una regla práctica: **cualquier operación que pueda tardar
más de unos milisegundos de CPU merece mirarse**.

> **⚠️ Advertencia:** el fallo no se parece a los de otras plataformas. En Java se agota el pool y
> degrada; aquí el proceso deja de responder por completo durante el tiempo que dure el cómputo, y
> las métricas de latencia se disparan en todas las rutas a la vez.

---

## 3. ⚖️ NestJS, Fastify y Express

| | NestJS | Fastify | Express |
|---|---|---|---|
| **Qué es** | Marco con opinión: módulos, inyección, decoradores | Servidor HTTP rápido con complementos | El clásico, mínimo y omnipresente |
| **Estructura** | La impone, y se parece a Spring a propósito | La eliges tú | La eliges tú |
| **Encaja con** | Equipos que vienen de backend; servicios que crecen | Servicios pequeños y rápidos; BFF ligeros | Código existente; cosas muy simples |
| **Coste** | Más ceremonia; hay que conocer sus abstracciones | Menos convenciones: cada servicio diverge | Poco ecosistema moderno alrededor |

**Cómo se elige, sin dogma.** Si el equipo viene de backend con marcos con opinión y el servicio va a
crecer, NestJS ahorra discusiones de estructura y trae inyección, módulos e integración con lo
habitual. Si el servicio es un BFF ligero o un agregador, Fastify sobra y va rápido. Express se
mantiene donde ya está.

**El matiz de rendimiento**, que suele usarse mal: la diferencia entre marcos es irrelevante frente a
lo que tarda tu base de datos. Elegir por micro-benchmarks de peticiones por segundo es optimizar el
5 % del tiempo.

> **💡 Truco:** NestJS parece Spring a propósito, y eso es una ventaja real en equipos mixtos: un
> backend de Java se orienta en un servicio de NestJS en una tarde. También es su riesgo: se importan
> costumbres de Java que no encajan con el modelo de un solo hilo.

---

## 4. 🧱 La propagación de contexto y sus límites

**Qué es.** El mecanismo que mantiene vivo el contexto de la petición —identificador de traza,
identidad, tenant— a través de `await`, sin pasarlo por parámetro.

**Cómo va.** Funciona a través de las cadenas de promesas del runtime, y por eso la instrumentación
automática consigue trazas correctas sin que nadie haga nada. **Dónde se pierde**:

| Se pierde en | Por qué |
|---|---|
| Hilos de trabajo | Otro hilo, otro almacenamiento |
| Colas y planificadores propios | Si el trabajo se guarda y se ejecuta después, el contexto no viaja |
| Al publicar en un broker | Hay que inyectarlo en los encabezados del mensaje |
| Código con callbacks antiguos | No siempre se propaga por cadenas no basadas en promesas |

Los cuatro casos son los mismos de
[`04-operacion-y-resiliencia/04`](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md), con la
forma concreta de esta plataforma.

---

## 5. 🧱 Tipos: lo que dan y lo que no

**Qué es.** TypeScript comprueba en compilación y desaparece en ejecución. No hay ninguna
verificación de que los datos que llegan coincidan con los tipos declarados.

**La consecuencia práctica**, que es la trampa número uno de esta plataforma:

```text
interface Order { id: string; total: number }    ← no comprueba NADA en ejecución

const order: Order = await response.json();      ← podría ser cualquier cosa
order.total.toFixed(2);                           ← falla aquí, lejos de la causa
```

**Qué hace falta**: validación real en el borde con un esquema que exista en ejecución —generado del
contrato o declarado explícitamente— y que produzca un error claro en el punto de entrada. Eso es
parte del contrato ([`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md)), no un
extra.

**Qué sí aportan los tipos**: ergonomía enorme al escribir, refactor seguro dentro del servicio, y la
posibilidad de compartir tipos con el frontend cuando ambos son del mismo equipo. Eso último es lo
que hace tan cómodo el BFF.

> **⚠️ Advertencia:** muchos equipos creen tener validación de contrato y lo que tienen es
> autocompletado. La comprobación es trivial: manda un campo con el tipo equivocado y mira si alguien
> se queja.

---

## 6. 🧰 Qué te da esta plataforma para cada patrón

| Patrón | Qué te da | Lo que te deja a ti |
|---|---|---|
| [Cliente HTTP](../02-comunicacion/02-http-entre-servicios.md) | Cliente nativo con pool; interceptores en los marcos | Un plazo total propio y cancelación explícita |
| [gRPC](../02-comunicacion/03-grpc.md) | Implementación madura y alternativas con mejor ergonomía de tipos | Vigilar el coste de serialización en el hilo único |
| [Tiempo real](../02-comunicacion/05-tiempo-real-websockets-y-sse.md) | **Su terreno**: muchas conexiones ociosas casi gratis; librerías con reconexión y salas | Que nada bloquee el hilo, porque congela a todos los conectados |
| [Mensajería](../02-comunicacion/06-mensajeria-y-eventos.md) | Clientes maduros de los brokers; colas sobre Redis muy usadas para trabajo en segundo plano | Apagado ordenado del consumidor y la idempotencia |
| [Outbox](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) | **Nada hecho**: se escribe a mano sobre el cliente de base de datos | Toda la mecánica: transacción, sondeo, marcado, limpieza |
| [Resiliencia](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md) | Circuit breaker suelto; reintentos en algunos clientes | Componer las piezas; no hay conjunto integrado |
| [Observabilidad](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md) | Instrumentación automática de los marcos habituales | Los cuatro puntos de pérdida de §4 |
| [Testing](../04-operacion-y-resiliencia/07-testing-de-microservicios.md) | Ejecutores rápidos, simuladores de HTTP, contenedores efímeros | Aislar estado entre pruebas que comparten proceso |

**La lectura agregada**: esta plataforma es fuerte en el borde —tiempo real, composición, BFF— y débil
en los patrones de datos —outbox, saga—, donde hay que escribir más. Eso explica bastante bien dónde
encaja dentro de un sistema.

---

## 7. 🔭 Dónde gana de verdad

Tres casos donde es la elección correcta y conviene saber defenderlos:

- **BFF de la web.** Mismo lenguaje y mismos tipos que el frontend, mismo equipo, mismo pipeline. Es
  el mejor argumento de poliglotismo que tiene este corpus
  ([`04-operacion-y-resiliencia/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)).
- **Agregación y composición.** Llamar a cinco servicios en paralelo y juntar es idiomático y barato.
- **Tiempo real con muchas conexiones.** Decenas de miles de conexiones ociosas con poca memoria es
  exactamente su perfil.

Y el caso donde peor encaja: **trabajo de CPU sostenido**. Ahí compite mal y, peor, falla de la forma
más desagradable de las cuatro plataformas.

---

## 8. 🧭 Cómo se elige dentro del ecosistema

```text
¿El servicio va a crecer y el equipo viene de backend?
├─ sí ──► NestJS: estructura, inyección y convenciones que ahorran discusiones
└─ no
   │
   ├─ ¿Es un BFF o un agregador pequeño? ──► Fastify: menos ceremonia, muy rápido
   │
   └─ ¿Hay código existente en Express? ───► mantenerlo; migrar solo con motivo
```

Y la frase:

> "NestJS cuando el servicio va a crecer o el equipo viene de backend, porque impone estructura;
> Fastify para BFF y agregadores. Y la elección de marco casi nunca decide el rendimiento: lo decide
> lo que hay detrás."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Node no sirve para cargas serias" | Sirve, y muy bien, para cargas de espera con muchas conexiones. Falla con trabajo de CPU sostenido |
| "Con TypeScript el contrato está garantizado" | Los tipos desaparecen al compilar. Hace falta validación real en el borde |
| "NestJS es más lento que Express y por eso no lo usamos" | La diferencia entre marcos es ruido frente a la base de datos. Se elige por estructura y equipo |
| "async/await hace que el código sea concurrente" | Permite no bloquear mientras se espera. El cómputo sigue ocupando el único hilo |
| "Un `worker_thread` resuelve cualquier problema de CPU" | Ayuda, y añade coste de comunicación y de memoria. A veces lo correcto es otro servicio |
| "El contexto de traza se propaga solo" | A través de promesas, sí. No a hilos de trabajo, ni a colas propias, ni al broker |
| "Node es monohilo, así que no escala" | Escala con varios procesos y con el reparto de la plataforma. Lo que no escala es un bloqueo dentro del bucle |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4, para situar
   el BFF, que es donde esta plataforma más encaja.
2. **Documentación** — Node, `AsyncLocalStorage` y el contexto asíncrono, base de §4:
   [nodejs.org/api/async_context.html](https://nodejs.org/api/async_context.html).
3. **Documentación** — Node, hilos de trabajo, la salida al problema de CPU de §2:
   [nodejs.org/api/worker_threads.html](https://nodejs.org/api/worker_threads.html).
4. **Documentación** — NestJS, estructura, módulos y ciclo de vida:
   [docs.nestjs.com](https://docs.nestjs.com/).
5. **Documentación** — Fastify, para la alternativa sin opinión:
   [fastify.dev/docs/latest/](https://fastify.dev/docs/latest/).
6. **Documentación** — Zod, validación con esquemas que existen en ejecución, que es lo que falta en
   §5: [zod.dev](https://zod.dev/).
7. **Documentación** — tRPC, para el caso concreto de extremos en TypeScript del mismo repositorio:
   [trpc.io/docs/concepts](https://trpc.io/docs/concepts).
8. **Charla** — GOTO Conferences, «Node.js Event Loop, Demystified». Sigue siendo la mejor
   explicación visual de por qué un bloqueo congela todo.

---

## 🧠 Preguntas

1. ¿Cómo atiende Node la concurrencia? 🟢
2. ¿Qué tumba a un servicio de Node? 🟢
3. ¿Qué comprueban los tipos de TypeScript y qué no? 🟢
4. Diferencia entre NestJS y Fastify. 🟢
5. ¿Dónde se pierde el contexto de traza en esta plataforma? 🟢
6. Nombra tres casos donde esta plataforma gana de verdad. 🟢
7. ¿Por qué `async/await` no hace concurrente el cómputo? 🟢
8. ¿Por qué un bloqueo congela en vez de degradar? 🟡
9. ¿Por qué un bloqueo es peor si hay conexiones persistentes abiertas? 🟡
10. ¿Por qué la diferencia de rendimiento entre marcos suele ser irrelevante? 🟡
11. ¿Por qué el BFF de la web encaja tan bien aquí? 🟡
12. ¿Por qué esta plataforma es débil en los patrones de datos? 🟡
13. ¿Qué revisarías antes de poner en producción un servicio de Node con muchas conexiones? 🟡
14. Tu servicio se congela unos segundos cada pocos minutos. Da tres hipótesis ordenadas. 🟠
15. ¿Cómo garantizarías que el contrato se valida de verdad en un servicio de TypeScript? 🟠
16. Tienes que serializar respuestas grandes. ¿Qué opciones tienes y cuál eliges? 🟠
17. ¿Cuándo elegirías NestJS y cuándo Fastify, con un caso de cada uno? 🟠
18. ¿Cómo implementarías el outbox aquí, sabiendo que no hay nada hecho? 🟠
19. Un equipo de Java va a escribir su primer servicio en NestJS. ¿Qué costumbres les advertirías? 🟠
20. ¿Cómo escalarías un servicio de Node que recibe picos de tráfico? 🟠
21. Diseña el chassis de Node/TS del equipo: qué trae, qué obliga a declarar y qué prohíbe. 🔴
22. Diseña un BFF para la web: estructura, composición, degradación, validación y observabilidad. 🔴
23. Diagnostica: el servicio va bien con 1 000 conexiones y se desploma con 5 000, sin que suba la
    CPU. Da tres hipótesis. 🔴
24. Un equipo quiere escribir el servicio de pedidos —con saga y outbox— en Node/TS. Responde con lo
    que concedes y lo que adviertes. 🔴

---

**Anterior:** [`02` — Java](02-java.md) · **Siguiente:** [`04` — Go](04-go.md) · **Relacionado:**
[`04-operacion-y-resiliencia/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md) ·
[`02-comunicacion/05`](../02-comunicacion/05-tiempo-real-websockets-y-sse.md)
