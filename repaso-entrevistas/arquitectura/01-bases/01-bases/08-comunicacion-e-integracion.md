# 08 — Comunicación e integración

> Síncrono contra asíncrono como decisión de **acoplamiento temporal**. REST, gRPC y
> eventos con el criterio para elegir. Contratos, versionado, idempotencia y garantías de
> entrega — incluida la mentira de *exactly-once*.
> Asume leído [`07` — DDD táctico](07-ddd-tactico.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Separaste el sistema en servicios. Ahora una llamada a un método es una llamada de red, y
con eso heredas cuatro cosas que antes no existían:

```text
1. El destino puede estar caído          → antes era imposible
2. Puede responder tarde                 → antes era instantáneo
3. Puede responder y perderse la respuesta → no sabes si se ejecutó
4. El contrato ya no lo verifica el compilador → lo verifica producción
```

Las **falacias de la computación distribuida** (Deutsch, 1994) son la forma canónica de
decirlo: la red no es fiable, la latencia no es cero, el ancho de banda no es infinito, la
topología cambia. Citarlas es barato y sitúa bien la respuesta.

> **Regla:** en un monolito, integrar es importar una clase. En distribuido, integrar es
> un problema de diseño con su propio capítulo. Este.

---

## 2. ⏱️ Acoplamiento temporal: la decisión de fondo

**Qué es.** Si A necesita que B esté **vivo ahora mismo** para funcionar, están acoplados
en el tiempo. Es lo que realmente eliges cuando eliges síncrono o asíncrono, y casi nadie
lo nombra así.

```text
Síncrono   →  A espera a B.  Si B cae, A falla.        Acoplado en el tiempo.
Asíncrono  →  A publica.     Si B cae, se procesa luego. Desacoplado en el tiempo.
```

**La cadena que hay que saber dibujar**, porque es la pregunta de seguimiento:

> Si A llama síncrono a B, que llama síncrono a C, la disponibilidad de A es el
> **producto** de las tres: tres servicios al 99,9 % dan 99,7 %. La cadena síncrona
> multiplica el riesgo; cada eslabón lo empeora.

**Cuándo síncrono.** Cuando necesitas la respuesta para continuar: consultar saldo,
validar antes de aceptar, cualquier cosa que el usuario espera mirando la pantalla.

**Cuándo asíncrono.** Cuando puedes responder "recibido" y terminar después: notificar,
proyectar, propagar un cambio, cualquier efecto secundario.

> 🧠 **Modelo mental.** La pregunta no es "¿REST o Kafka?". Es **"¿el que llama necesita
> el resultado para responder a su usuario?"**. Todo lo demás se deriva de ahí.

> **Veredicto:** la elección entre síncrono y asíncrono no es de tecnología, es de disponibilidad. Quien
> la formula como *"¿REST o Kafka?"* ya se saltó la decisión.

---
## 3. 🌐 REST

**Qué es.** El estándar de facto: HTTP, recursos, JSON, verbos con semántica.

**Cuándo sí.** Comunicación con clientes externos, APIs públicas, cualquier integración
donde la legibilidad y las herramientas importen más que la latencia. Es el valor por
defecto y hay que justificarlo poco.

**Cuándo no.** Comunicación interna de muy alta frecuencia —el overhead de JSON y HTTP/1.1
se nota—, o cuando necesitas *streaming* bidireccional.

**Lo que se pregunta de verdad**, más allá de la definición:

- **Idempotencia de los verbos:** `GET`, `PUT` y `DELETE` son idempotentes por
  definición; `POST` no. Por eso reintentar un `POST` puede duplicar y reintentar un
  `PUT` no.
- **Códigos de estado con criterio:** `409` para conflicto de estado, `422` para entidad
  no procesable, `429` para límite de tasa, `503` con `Retry-After` cuando estás caído a
  propósito.
- **HATEOAS y el modelo de madurez de Richardson** existen y casi nadie llega al nivel 3.
  Saber que existe y decir que rara vez se paga es la respuesta honesta.

> **Veredicto:** REST es el valor por defecto y necesita poca justificación. Lo que sí la necesita es
> **no** usarlo.

---
## 4. ⚡ gRPC

**Qué es.** RPC sobre HTTP/2 con Protocol Buffers: contrato en un archivo `.proto`,
serialización binaria, código generado para cliente y servidor.

**Cuándo sí.** Comunicación interna entre servicios con volumen alto; necesidad de
*streaming*; equipos políglotas que quieren un contrato verificable. Es más rápido y
mucho más compacto que JSON.

**Cuándo no.** APIs públicas o clientes de navegador (necesitan gRPC-Web y un proxy);
equipos sin tooling; cuando la depurabilidad con `curl` importa más que los milisegundos.

| | REST/JSON | gRPC |
|---|---|---|
| Contrato | OpenAPI, opcional | `.proto`, obligatorio |
| Formato | Texto, legible | Binario, compacto |
| Streaming | Limitado (SSE, WebSocket) | Nativo, bidireccional |
| Navegador | Directo | Necesita gRPC-Web |
| Depuración | `curl` | Herramientas específicas |

> **Veredicto:** gRPC hacia dentro, REST hacia fuera. Es la regla que resume el 90 % de
> las decisiones reales.

---

## 5. 📜 Contratos y versionado

**El problema.** Sin compilador que verifique, el contrato se rompe en producción y lo
descubre el consumidor.

**Compatibilidad, con la distinción que se pregunta:**

```text
Hacia atrás (backward)  → el consumidor nuevo lee datos viejos
Hacia adelante (forward)→ el consumidor viejo lee datos nuevos  ← la que importa en eventos
```

**Cambios seguros y cambios que rompen:**

| ✅ Seguro | ❌ Rompe |
|---|---|
| Añadir un campo **opcional** | Añadir un campo obligatorio |
| Añadir un endpoint | Quitar o renombrar un campo |
| Ampliar un rango de valores | Cambiar el tipo de un campo |
| Marcar como *deprecated* | Cambiar la semántica sin cambiar el nombre |

**El último es el peor**: cambiar qué significa `estado = 3` sin tocar el esquema pasa
todas las validaciones y rompe la lógica del consumidor.

**Estrategias de versionado**, con su veredicto:

- **En la ruta** (`/v1/pedidos`): explícito, fácil de enrutar, el más usado. Duplica
  código si se abusa.
- **En la cabecera** (`Accept: application/vnd.api.v2+json`): más purista, más difícil de
  probar y de cachear.
- **Sin versión, solo evolución compatible**: el ideal, y lo que hacen los contratos de
  eventos bien diseñados. Exige disciplina.

> 💡 **Truco.** La respuesta fuerte es **contract testing**: Pact o Spring Cloud Contract
> hacen que el consumidor publique lo que espera y el pipeline del proveedor falle si lo
> rompe. Convierte la compatibilidad en algo verificable, no en una promesa.

> **Veredicto:** versionar es lo que haces cuando la evolución compatible ya falló. El trabajo de
> arquitectura está antes: en que el cambio no rompa, y en tener cómo comprobarlo.

---
## 6. 📬 Garantías de entrega

Las tres, con lo que significan de verdad:

```text
at-most-once   → puede perderse. No reintentas. Solo para datos desechables (métricas).
at-least-once  → puede duplicarse. Reintentas. Es lo que usas en el 99 % de los casos.
exactly-once   → no existe de extremo a extremo. Se simula.
```

**Por qué *exactly-once* no existe.** El emisor no puede distinguir "el mensaje no llegó"
de "llegó y se perdió el acuse". Ante esa duda solo hay dos opciones: no reintentar
(pierdes) o reintentar (duplicas). No hay tercera.

**Lo que sí existe** es *effectively-once*: **at-least-once más un consumidor
idempotente**. Kafka ofrece "exactly-once semantics" y es cierto **dentro de Kafka**
—productor transaccional, consumir-procesar-producir en la misma transacción—, pero en
cuanto el efecto sale del broker (escribir en tu BD, llamar a un tercero, mandar un
correo) vuelves a at-least-once.

> ⚠️ **Advertencia.** Decir "uso exactly-once" sin el matiz es una de las respuestas que
> más rápido te descalifican en una entrevista de arquitectura. Di **"at-least-once más
> idempotencia en el consumidor"** y habrás dado la respuesta completa.

> **Veredicto:** hay una sola garantía que puedes elegir de verdad —at-least-once— y una sola forma de
> hacerla útil: idempotencia en el consumidor. Lo demás es marketing del broker.

---
## 7. 🔑 Idempotencia

**Qué es.** Que ejecutar la operación N veces tenga el mismo efecto que ejecutarla una.
Es **el requisito que hace viable todo lo anterior**: sin ella no puedes reintentar, y sin
reintentar no tienes resiliencia.

**Cómo se implementa**, en orden de robustez:

```text
1. Clave de idempotencia   → el cliente manda un id único; guardas resultado por clave
2. Deduplicación por id     → tabla de ids procesados con TTL
3. Operación naturalmente idempotente → "poner saldo en X" en vez de "sumar X"
4. Comprobación de estado   → "si ya está ENVIADO, no hagas nada"
```

- La opción 3 es la más elegante y la más olvidada: **reformular la operación** elimina
  el problema en vez de gestionarlo.
- La opción 1 es el estándar de la industria para APIs de pago, y se llama así
  literalmente: cabecera `Idempotency-Key`.

**El detalle que casi nadie dice:** la deduplicación debe ser **atómica con el efecto**.
Si marcas el id como procesado en una transacción y escribes el resultado en otra, un
fallo entre medias deja la operación sin hacer y marcada como hecha. Es el mismo problema
que resuelve el outbox de [`02-eventos/06`](../02-eventos/), en espejo.

> **Veredicto:** la idempotencia no es una técnica de mensajería: es el **permiso para reintentar**. Sin
> ella, todo [`09` — Resiliencia](09-resiliencia.md) es inaplicable.

---
## 8. 🔢 Orden y particionado

**El hecho incómodo.** El orden global no existe en un sistema distribuido con múltiples
particiones. Lo que existe es **orden por clave**.

- Kafka garantiza orden **dentro de una partición**. Si envías todos los eventos de un
  mismo `pedidoId` a la misma partición —usándolo como clave—, ese pedido tiene orden.
- La contrapartida: una clave con mucho tráfico (un cliente que concentra el 30 % de los
  eventos) crea una **partición caliente** y limita el paralelismo.

> **Regla:** el paralelismo máximo de un grupo de consumidores es el número de
> particiones. Más consumidores que particiones significa consumidores ociosos.

**La alternativa cuando el orden no se puede garantizar:** diseñar consumidores que no lo
necesiten. Un evento con número de versión o con marca de tiempo permite **descartar lo
viejo** en vez de exigir que llegue ordenado.

> **Veredicto:** el orden global no se compra, se evita. Diseñar consumidores que no lo necesiten
> escala mejor que cualquier truco de particionado.

---
## 9. 🧭 Cómo se elige, en voz alta

```text
¿El que llama necesita el resultado para responder?     → síncrono
   ¿Hacia fuera o cliente de navegador?                 → REST
   ¿Interno, alto volumen o streaming?                  → gRPC
¿Es un efecto secundario o una propagación de estado?   → asíncrono, evento
   ¿Un solo consumidor conocido, trabajo a repartir?    → cola
   ¿Varios consumidores, o desconocidos a futuro?       → pub/sub
Y en cualquier caso:                                     → el consumidor, idempotente
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Uso exactly-once" | No existe de extremo a extremo; es at-least-once + idempotencia |
| "Async es más rápido" | Es más **resiliente** y desacopla en el tiempo; la latencia extremo a extremo suele subir |
| "Kafka garantiza el orden" | Dentro de una partición, no globalmente |
| "Añadir un campo no rompe nada" | Si es obligatorio, rompe al consumidor viejo |
| "Versiono con `/v2` y ya" | El versionado es la salida cuando falló la evolución compatible |
| "El `POST` se puede reintentar" | No es idempotente: reintentarlo duplica salvo clave de idempotencia |
| "Tres servicios al 99,9 % dan 99,9 %" | En cadena síncrona se multiplican: 99,7 % |

---

## 📚 Para profundizar

- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulos
  4 y 5: estilos de comunicación, contratos y versionado.
- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*
  (Addison-Wesley, 2003). **El catálogo canónico** de mensajería: capítulos 4–7. Los
  nombres que usa la industria salen de aquí.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 4 (codificación y evolución de esquemas) y capítulo 8 (los problemas de los
  sistemas distribuidos, incluida la imposibilidad del exactly-once).
- [microservices.io — Communication patterns](https://microservices.io/patterns/index.html#communication-style):
  el índice con RPI, mensajería y sus variantes enfrentadas.
- [gRPC — Introduction to gRPC](https://grpc.io/docs/what-is-grpc/introduction/):
  el modelo, los cuatro tipos de llamada y el `.proto`.
- [Spring Cloud Contract — Reference](https://docs.spring.io/spring-cloud-contract/reference/):
  cómo se convierte un contrato en un test que rompe el pipeline.
- **Tutorial** — Baeldung, «REST API Versioning»:
  las cuatro estrategias comparadas en Spring.
- **Video** — GOTO Conferences, charlas de Gregor Hohpe sobre integración y de
  Martin Kleppmann sobre garantías de entrega. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué es el acoplamiento temporal? 🟢
2. Nombra tres falacias de la computación distribuida. 🟢
3. ¿Qué garantías de entrega existen y cuál usas en la práctica? 🟢
4. ¿Qué verbos HTTP son idempotentes y cuál no? 🟢
5. ¿Por qué reintentar un `POST` es peligroso? 🟡
6. ¿Qué es una clave de idempotencia y quién la genera? 🟡
7. ¿Qué diferencia hay entre compatibilidad hacia atrás y hacia adelante? 🟡
8. Da dos cambios de contrato seguros y dos que rompen. 🟡
9. ¿En qué unidad garantiza Kafka el orden? 🟡
10. ¿Por qué *exactly-once* no existe de extremo a extremo? 🟡
11. ¿Qué es *effectively-once* y cómo se consigue? 🟠
12. ¿Cuál es el cambio que rompe y pasa todas las validaciones? 🟠
13. ¿Cuándo eliges gRPC sobre REST y cuándo al revés? 🟠
14. ¿Qué limita el paralelismo de un grupo de consumidores? 🟠
15. ¿Qué es una partición caliente y qué la causa? 🟠
16. Tres servicios al 99,9 % en cadena síncrona: ¿qué disponibilidad da? 🟠
17. ¿Cómo diseñas un consumidor que no necesite orden garantizado? 🟠
18. ¿Qué es contract testing y qué problema resuelve que el versionado no? 🟠
19. ¿Por qué la deduplicación debe ser atómica con el efecto? 🔴
20. Reformula "sumar 100 al saldo" para que sea naturalmente idempotente, y di
    qué pierdes al hacerlo. 🔴
21. Diseña la integración entre "pedidos" y "facturación": elige estilo,
    justifica y di qué falla si el otro se cae. 🔴
22. Tu API pública tiene 40 consumidores y necesitas renombrar un campo. ¿Cómo
    lo haces sin romper a nadie? 🔴

---

**Anterior:** [`07` — DDD táctico](07-ddd-tactico.md) ·
**Siguiente:** [`09` — Resiliencia](09-resiliencia.md) ·
**Relacionado:** [`02-eventos`](../02-eventos/)
