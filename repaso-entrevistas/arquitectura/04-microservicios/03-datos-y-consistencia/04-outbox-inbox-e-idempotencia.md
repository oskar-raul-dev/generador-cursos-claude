# 04 — Outbox, inbox e idempotencia

> El problema de la doble escritura y sus tres soluciones: outbox, captura de cambios e inbox. Más la
> idempotencia de verdad, que es lo que hace posible todo lo demás. Asume leídos
> [`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) y [`03`](03-saga.md), que lo
> usan en cada paso.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Dos líneas de código, y entre ellas la ventana donde se pierden los sistemas distribuidos:

```java
orders.save(order);                             // ①  transacción confirmada
broker.publish(new OrderPlaced(order));         // ②  y aquí el proceso muere
```

El pedido existe y nadie se enteró: `inventory` no reserva, `payments` no cobra, y **no hay ningún
error en ningún log**. El pedido simplemente se queda quieto.

Invertir el orden no ayuda, cambia el fallo de sitio: publicas primero y, si la base falla, has
anunciado un pedido que no existe. Y meter la publicación dentro de la transacción tampoco: el broker
no participa en ella, así que un `rollback` de la base no deshace un mensaje ya enviado.

**No hay forma de escribir en dos sistemas atómicamente.** Lo que hay son patrones para que el
desajuste sea detectable y recuperable, y son tres: outbox, captura de cambios e inbox.

---

## 2. 🧱 Transactional outbox

**Qué es.** Se escribe el mensaje **en la misma base y en la misma transacción** que el cambio de
negocio, en una tabla propia. Un proceso aparte lee esa tabla y publica.

```text
┌──── una sola transacción ────┐
│  INSERT INTO orders …        │
│  INSERT INTO outbox_events … │
└──────────────────────────────┘
              │
     publicador (sondeo o CDC)
              ▼
           el broker
```

**Cómo va.** La tabla, con el porqué de cada columna:

| Columna | Para qué |
|---|---|
| `id` | Identidad del mensaje: es la clave de deduplicación del consumidor |
| `aggregate_type`, `aggregate_id` | Enrutado y clave de particionado (`ORD-00042`) |
| `type` | `OrderPlaced`: el consumidor decide por aquí |
| `payload` | El evento serializado |
| `created_at` | Orden y diagnóstico |
| `published_at` | Marca del publicador; nulo = pendiente |

**Con qué.** El publicador tiene dos formas: **sondeo** —leer periódicamente lo pendiente, publicar,
marcar— o **captura de cambios** —leer el log de la base, §3—. El sondeo es sencillo y suficiente casi
siempre; su precio es la latencia del intervalo y la carga de consultar una tabla constantemente.

**Cuánto.** Cuesta una tabla, un índice sobre lo pendiente, un proceso más, y latencia de publicación
de cientos de milisegundos. Y cuesta limpiar: sin borrado periódico, la tabla crece sin límite.

**Cuándo sí.** Siempre que perder el mensaje tenga consecuencias: sagas, integraciones, proyecciones
que alimentan pantallas.

**Cuándo no.** Cuando el mensaje es prescindible de verdad —telemetría, una métrica— y publicar
directamente es aceptable.

> **⚠️ Advertencia:** el outbox no evita duplicados, los **garantiza** en el caso límite: si el
> publicador muere entre publicar y marcar, volverá a publicar. Por eso el consumidor idempotente no
> es opcional; es la otra mitad del patrón.

---

## 3. 🧱 Captura de cambios (CDC)

**Qué es.** Leer el log de transacciones de la base de datos y convertir cada cambio en un evento,
sin que la aplicación publique nada.

**Cómo va.** Hay dos usos muy distintos, y conviene no mezclarlos:

- **CDC como publicador del outbox.** Lee la tabla `outbox_events` del log y publica. Es el mejor de
  los dos mundos: la aplicación solo escribe en su base, y la latencia baja a milisegundos.
- **CDC sobre las tablas de negocio.** Publica cada `INSERT`/`UPDATE` de tus tablas como evento. Es
  lo que hay que mirar con cuidado: el contrato pasa a ser **tu esquema físico**, así que cualquier
  cambio de columna rompe a los consumidores.

**Cuánto.** Cuesta un componente más de infraestructura —un conector que operar, vigilar y
actualizar— y una dependencia del motor de base de datos y de su configuración de log. A cambio
elimina el sondeo y no toca el código de escritura.

**Cuándo sí.** Como publicador del outbox, siempre que ya tengas esa infraestructura o el volumen la
justifique. Sobre tablas de negocio, para replicar a un almacén analítico **dentro de tu frontera**.

**Cuándo no.** Publicar tus tablas como contrato entre servicios. Es la base de datos compartida con
un paso intermedio: los consumidores acaban conociendo tu esquema igual.

> **Veredicto:** CDC es una excelente forma de publicar el outbox y una forma peligrosa de publicar
> el dominio. La diferencia está en qué tabla lee, y esa distinción es exactamente lo que se pregunta
> en una entrevista.

---

## 4. 🧱 Inbox y deduplicación

**Qué es.** La simétrica del outbox, en el consumidor: una tabla de mensajes ya procesados que se
escribe **en la misma transacción que el efecto**.

```text
┌──────── una sola transacción ────────┐
│  INSERT INTO processed_messages (id) │   ← falla si ya existe
│  UPDATE inventory …                  │
└──────────────────────────────────────┘
```

**Cómo va.** La clave de deduplicación puede ser de dos tipos, y la elección importa:

| Clave | Qué protege | Qué no |
|---|---|---|
| **Identificador del mensaje** | Reentregas del broker y del outbox | Un reenvío manual con identificador nuevo se procesa otra vez |
| **Clave de negocio** (`order_id` + tipo) | Cualquier duplicado semántico, venga de donde venga | Es más restrictiva: hay que estar seguro de que no puede repetirse legítimamente |

**Cuánto.** Cuesta una tabla, un índice único y una política de retención —los registros no se guardan
para siempre; se borran pasada la ventana en la que un duplicado es plausible, normalmente días—.

**Cuándo sí.** En todo consumidor. No hay excepción.

**Cuándo no.** Cuando el efecto ya es naturalmente idempotente —poner un estado a un valor fijo— y se
puede demostrar. Incluso ahí, la tabla suele compensar por diagnóstico.

> **💡 Truco:** cuando el efecto no es transaccional —una llamada a un tercero—, la marca y el efecto
> no pueden ir juntos. La salida es registrar la **intención** antes de llamar y el resultado
> después; al reintentar, se consulta al tercero por esa referencia en vez de repetir a ciegas.

---

## 5. 🧱 Idempotencia, en serio

**Qué es.** Que repetir la operación produzca el mismo resultado que ejecutarla una vez. No es
"tolerar duplicados"; es una propiedad que se diseña.

Cuatro formas, de mejor a peor:

| Forma | Ejemplo | Comentario |
|---|---|---|
| **Operación idempotente por naturaleza** | `status = PAID` | La mejor: no hace falta nada más |
| **Clave natural única** | `INSERT reservation (order_id, line)` con índice único | La base de datos hace el trabajo |
| **Clave de idempotencia del cliente** | `Idempotency-Key` en el `POST` | Para APIs; el servidor guarda clave, resultado y estado |
| **Registro de procesados** | La tabla de §4 | El caso general, y el que más disciplina exige |

**Cómo va.** La clave de idempotencia en HTTP tiene tres detalles que casi nadie implementa bien:

- **La genera el cliente, una por intención** —no por intento—, y la repite en todos los reintentos.
- **Se registra antes de empezar**, no al terminar: si llega un reintento mientras la primera
  ejecución está en curso, la respuesta correcta es "en progreso", no ejecutar en paralelo.
- **La misma clave con cuerpo distinto es un error**, no una operación nueva. Si no se comprueba, una
  clave reutilizada por error devuelve el resultado de otra operación.

**Cuánto.** Cuesta almacenamiento, una política de retención y pensar la clave. Es de lo más barato
que se puede construir comparado con lo que evita.

> **🧠 Modelo mental:** **al-menos-una-vez + idempotencia = exactamente-una-vez, funcionalmente.** Esa
> ecuación es la respuesta a la pregunta de entrevista sobre exactly-once, y es mucho mejor
> respuesta que discutir si existe.

---

## 6. ⚖️ Outbox contra CDC

Compiten por el mismo trabajo —sacar el evento sin perderlo— y se eligen por operación, no por
elegancia.

| | Outbox con publicador propio | CDC sobre la tabla de outbox | CDC sobre tablas de negocio |
|---|---|---|---|
| **Qué publica** | Lo que tú decides escribir en la tabla | Lo mismo: el evento que tú escribiste | Cada cambio de tus tablas |
| **Contrato** | Tuyo, explícito y versionable | Tuyo, explícito y versionable | **Tu esquema físico**, sin querer |
| **Infraestructura extra** | Ninguna: un proceso tuyo | Un conector que operar y vigilar | El mismo conector |
| **Latencia de publicación** | La del sondeo: cientos de ms a segundos | Milisegundos | Milisegundos |
| **Coste de escritura** | Una inserción más en la misma transacción | Igual | Ninguno: no tocas el código |
| **Riesgo principal** | El sondeo cargando la base si se afina mal | Dependencia del motor y de su log | Acoplar a todos a tus columnas |

**El veredicto es de camino, no de bando.** Se empieza con outbox y publicador propio, que no añade
infraestructura y resuelve el problema entero; cuando la latencia de publicación estorba o el volumen
hace caro el sondeo, se sustituye el publicador por CDC **leyendo la misma tabla de outbox**, y el
contrato no cambia porque sigue siendo el evento que tú escribes. CDC sobre tablas de negocio solo
dentro de tu frontera —replicar a analítica—, nunca como contrato entre servicios.

> **Veredicto:** outbox decide *qué* se publica y CDC decide *cómo de rápido sale*. Son capas, no
> rivales; el error es usar CDC para saltarse la decisión de qué publicar.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Módulos del ecosistema que implementan outbox y publicación de eventos ligados a la transacción; conectores de CDC maduros | Elegir entre el módulo y hacerlo a mano; y la limpieza de la tabla, que nunca viene incluida |
| **Node/TS** | Poco hecho: el outbox se escribe a mano sobre el cliente de base de datos; colas con reintentos para el publicador | Toda la mecánica: transacción, sondeo, marcado, limpieza. Es simple, pero es tuyo |
| **Go** | Componentes de enrutado de mensajes que incluyen outbox y reintentos; el resto, explícito | El cableado. A cambio se ve entero y se prueba sin magia |
| **Python** | Colas de tareas rodadas para el publicador; el outbox, a mano sobre el ORM | Que la tarea de publicación no se solape consigo misma y publique dos veces |

El outbox en Java, con lo que de verdad importa —la misma transacción—:

```java
@Transactional                               // pedido y evento, o ninguno de los dos
public void place(OrderId id) {
    var order = orders.byId(id).orElseThrow();
    order.place();                            // ① cambio de negocio
    outbox.save(new OutboxEvent(              // ② mismo commit: no hay ventana
        UUID.randomUUID(),                    // id: será la clave de deduplicación del consumidor
        "Order", id.value(),                  // agregado: clave de particionado
        "OrderPlaced",
        serialize(OrderPlaced.of(order))));
}
```

- No hay llamada al broker en ningún sitio: **el servicio no depende del broker para completar la
  petición**. Esa es la otra ventaja del outbox, y es la que hace que el broker salga del readiness
  ([`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)).
- El identificador se genera aquí y viaja con el mensaje: es lo que permite al consumidor deduplicar.

Y el consumidor idempotente en Python, con el orden que decide si pierdes o duplicas:

```python
def on_message(message):
    try:
        with transaction():                        # marca y efecto, atómicos
            processed.insert(message.id)           # índice único: lanza si ya existe
            inventory.reserve(message.order_id, message.lines)
    except DuplicateError:
        pass                                       # ya aplicado: NO es un error
    message.ack()                                  # confirmar siempre DESPUÉS del commit
```

- El `INSERT` con índice único hace el trabajo de comprobación y bloqueo a la vez: comprobar primero
  y luego insertar deja una carrera entre dos consumidores procesando el mismo mensaje.
- El `except` vacío es correcto y deliberado: un duplicado es el comportamiento esperado. Lo que sí
  conviene es contarlo en una métrica.

> **🧰 Plataforma:** ninguna de las cuatro te da la limpieza de las tablas de outbox e inbox, y las
> dos crecen sin parar. Es el detalle operativo que más veces aparece meses después como "la base de
> datos se ha llenado", y conviene mencionarlo en una entrevista porque delata experiencia real.

---

## 8. 🩺 Diagnóstico: "el evento nunca llegó"

El orden de comprobación, que resuelve el caso en minutos si hay paneles:

```text
1. ¿Está la fila en outbox_events?      no → el fallo es del código de negocio
                                             (¿la transacción se revirtió?)
2. ¿Tiene published_at?                 no → el publicador está parado o atascado
3. ¿Está el mensaje en el topic?        no → el publicador falló al publicar; mirar su log
4. ¿Cuál es el lag del consumidor?      alto → es capacidad, no pérdida
5. ¿Está en processed_messages?         sí → se descartó por duplicado: mirar si un
                                             intento anterior falló DESPUÉS de marcar
6. ¿Está en la DLQ?                     sí → falló al procesar; mirar el motivo
```

El paso 5 es el más sutil y el que justifica toda la insistencia en la transacción única: una marca
escrita sin que el efecto se aplicara hace que el mensaje se descarte para siempre, en silencio.

> **🩺 Diagnóstico:** los pasos 1 y 2 se responden con una consulta a la tabla de outbox. Si un equipo
> no puede contestarlos en un minuto, el problema no es el patrón: es que nadie ha mirado esa tabla
> desde que se escribió.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Publicamos después del commit, es suficiente" | Entre el commit y la publicación cabe una caída, y el evento se pierde sin dejar ningún error |
| "El broker garantiza que el mensaje llega una vez" | Garantiza al-menos-una-vez. El outbox además **garantiza** duplicados en su caso límite |
| "Idempotente significa que no falla si lo repites" | Significa que el **resultado** es el mismo. Que no lance excepción no basta: dos reservas no son una |
| "Con CDC ya no necesitas outbox" | CDC sobre el outbox es la mejor combinación. CDC sobre tus tablas publica tu esquema como contrato |
| "Comprobamos si existe y luego insertamos" | Entre las dos operaciones hay una carrera. El índice único lo resuelve en un solo paso |
| "La clave de idempotencia la genera el servidor" | La genera el cliente, una por intención, y la repite en todos los reintentos |
| "Las tablas de outbox e inbox no molestan" | Crecen sin límite. Sin limpieza periódica, son la causa más común de "se llenó el disco" |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3, sección de
   publicación de eventos, y capítulo 5. **La explicación canónica del outbox.**
2. **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017. Capítulos 11
   y 12: por qué los duplicados son inevitables y qué significa la idempotencia de extremo a extremo.
3. **Fuente primaria** — Chris Richardson, «Pattern: Transactional outbox»:
   [microservices.io/patterns/data/transactional-outbox.html](https://microservices.io/patterns/data/transactional-outbox.html).
4. **Fuente primaria** — Chris Richardson, «Pattern: Polling publisher», la variante de sondeo con sus
   costes:
   [microservices.io/patterns/data/polling-publisher.html](https://microservices.io/patterns/data/polling-publisher.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: Idempotent Consumer»:
   [microservices.io/patterns/communication-style/idempotent-consumer.html](https://microservices.io/patterns/communication-style/idempotent-consumer.html).
6. **Documentación** — Debezium, el enrutador de eventos de outbox, que implementa exactamente el
   patrón de §3:
   [debezium.io/documentation/reference/transformations/outbox-event-router.html](https://debezium.io/documentation/reference/transformations/outbox-event-router.html).
7. **Documentación** — Stripe, peticiones idempotentes: el ejemplo de referencia de cómo se diseña una
   clave de idempotencia en una API real:
   [stripe.com/docs/api/idempotent_requests](https://stripe.com/docs/api/idempotent_requests).
8. **Charla** — GOTO Conferences, «Change Data Capture and the Outbox Pattern». Útil por la
   comparación entre sondeo y CDC con datos.

---

## 🧠 Preguntas

1. ¿Qué es el problema de la doble escritura? 🟢
2. ¿Qué es el patrón outbox y qué garantiza? 🟢
3. Enumera las columnas de la tabla de outbox y para qué sirve cada una. 🟢
4. ¿Qué es el inbox y en qué transacción se escribe? 🟢
5. Nombra las cuatro formas de conseguir idempotencia. 🟢
6. ¿Quién genera la clave de idempotencia y con qué criterio? 🟢
7. ¿Por qué invertir el orden —publicar antes de guardar— no resuelve nada? 🟡
8. ¿Por qué el outbox garantiza duplicados en vez de evitarlos? 🟡
9. Diferencia entre CDC sobre el outbox y CDC sobre las tablas de negocio. 🟡
10. ¿Por qué "comprobar si existe y luego insertar" tiene una carrera? 🟡
11. ¿Qué ventaja operativa da el outbox respecto a la dependencia del broker? 🟡
12. ¿Por qué la clave de idempotencia debe registrarse antes de ejecutar y no después? 🟡
13. ¿Qué te da cada plataforma para el outbox, y qué te deja a ti en las cuatro? 🟡
14. ¿Cuándo aceptarías publicar directamente al broker sin outbox? 🟡
15. Tu tabla de outbox tiene 40 millones de filas. ¿Qué pasó y qué haces? 🟠
16. El publicador de outbox se ejecuta en tres instancias. ¿Qué problema tienes y cómo lo resuelves?
    🟠
17. ¿Qué clave de deduplicación elegirías para el consumidor de `inventory`? Justifica. 🟠
18. El efecto del consumidor es llamar a un tercero no idempotente. ¿Cómo lo haces seguro? 🟠
19. Diseña la política de retención de las tablas de outbox e inbox. 🟠
20. ¿Cómo comprobarías que la idempotencia de un consumidor funciona de verdad? 🟠
21. Un equipo propone CDC sobre sus tablas para publicar eventos a otros servicios. Responde. 🟠
22. ¿Qué riesgo específico tiene el publicador de outbox según cómo lo lance cada plataforma? 🟠
23. Diseña el publicador de outbox completo: consulta, orden, concurrencia, marcado, reintentos,
    métricas y limpieza. 🔴
24. Diagnostica: el pedido está confirmado, el evento está en `outbox_events` sin publicar desde
    hace dos horas, y el publicador no registra errores. Da tres hipótesis. 🔴
25. Diseña el soporte de `Idempotency-Key` en `POST /payments`: qué guardas, en qué transacción, qué
    devuelves en cada caso y cuánto lo retienes. 🔴
26. Un consumidor debe actualizar su base y llamar a un tercero. Diseña el flujo garantizando que no
    se duplica el efecto en el tercero. 🔴

---

**Anterior:** [`03` — Saga](03-saga.md) · **Siguiente:**
[`05` — Evolución de esquema y migraciones](05-evolucion-de-esquema-y-migraciones.md) ·
**Relacionado:** [`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) ·
[`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)

**Taller, opcional:** [`06/06` — Kafka: outbox, inbox, idempotencia y DLQ](../06-talleres/06-kafka-outbox-inbox-y-dlq.md).
