# 03 — Publicación de eventos y outbox

Este capítulo enseña a decidir cómo publicar un hecho de integración cuando `ConfirmOrder` guarda estado local y debe avisar a otros procesos sin una doble escritura ingenua.

## 1. 🎯 El problema

El método guarda `OrderConfirmed` en la base y luego publica a un broker. Si el proceso cae entre ambos pasos, el pedido existe pero el mensaje se pierde. Si publica primero y luego revierte la base, otros sistemas observan un pedido inexistente. Poner ambas llamadas en el mismo método no las vuelve atómicas.

## 2. 🧭 Tres contratos y una frontera

```text
Order.confirm() ─► evento de dominio
       │
       ▼
ConfirmOrder ─► pedido + registro outbox ─► COMMIT local
                                          │
                               dispatcher ─► evento de integración ─► broker
```

El [evento de dominio](../02-nucleo-aplicacion-y-dominio/07-eventos-de-dominio-y-efectos-secundarios.md) nombra un hecho interno. El evento de integración es un contrato externo, versionado y con datos mínimos para consumidores. La fila outbox es la intención durable de publicar, guardada en la misma transacción física que el pedido. El dispatcher es infraestructura: lee pendientes, entrega, observa resultado y marca estado. El núcleo puede pedir “registrar publicación pendiente” como capacidad de aplicación, pero no conoce tabla, topic ni ACK.

## 3. 🔄 Del commit a la entrega

1. El caso de uso confirma el pedido y recoge `OrderConfirmed`.
2. Una unidad de trabajo persiste pedido y una traducción a `OrderConfirmedV1` en outbox dentro del mismo commit. Si revierte, ninguno existe.
3. Un dispatcher toma filas pendientes con lease o bloqueo acotado, publica con ID estable y espera confirmación del broker según su cliente.
4. Solo entonces marca la fila como enviada. Si cae después de publicar y antes de marcar, enviará otra vez. La entrega es al menos una vez; el [consumidor](../03-adaptadores-de-entrada/02-mensajeria-consumidores-y-comandos.md) deduplica por ID de evento u operación.
5. Reintentos acotados, backoff, edad de pendientes, intentos y DLQ hacen visible la falla. Una fila envenenada no debe bloquear indefinidamente toda la cola.

La outbox cierra la ventana entre commit de base e intención de publicación; no convierte base y broker en una sola transacción ni asegura que el consumidor haya aplicado el efecto. Para preservar orden por pedido, incluye `orderId` y secuencia o versión; particiona por esa clave y evita que varios dispatchers publiquen versiones del mismo agregado fuera de orden. El orden global suele ser innecesario y caro. La retención y limpieza de outbox también son parte del diseño.

## 4. 🧩 Implementación mínima

```java
record OrderConfirmedV1(String eventId, String orderId, long version) {}
interface PendingPublications {
    void add(OrderConfirmedV1 event);
}

final class ConfirmOrder {
    private final Orders orders;
    private final PendingPublications pending;
    ConfirmOrder(Orders orders, PendingPublications pending) {
        this.orders = orders; this.pending = pending;
    }
    void execute(String id) {
        var order = orders.find(id).orElseThrow();
        order.confirm();
        orders.save(order);
        pending.add(new OrderConfirmedV1(
            order.eventId(), order.id(), order.version()));
    }
}

// Composition root: una transacción envuelve execute(); ambos adapters usan
// el mismo recurso local. El dispatcher se construye aparte con outbox y broker.
```

La identidad del evento se asigna una vez y se persiste; no se genera un UUID nuevo por intento. En una implementación real, el adapter de outbox serializa y versiona el evento, y el dispatcher usa un mecanismo de reclamación de filas que soporte concurrencia. Una alternativa es capturar cambios del log de transacciones en vez de hacer polling; ambas requieren contratos y observabilidad. La elección depende de la base, volumen y operación disponibles.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring coordina transacción local y ofrece tareas; clientes de broker publican | compartir transaction manager y aislar dispatcher | publicar directamente desde un listener transaccional suponiendo entrega durable |
| Node/TS | driver u ORM y timers permiten guardar y sondear | pasar la misma transacción y controlar promesas | lanzar un `publish()` sin esperarlo |
| Go | `sql.Tx` agrupa escrituras; goroutines permiten workers | leasing, cancelación y cierre correcto | usar `db` para outbox mientras pedido usa `tx` |
| Python | sesión transaccional y workers disponibles | commit único, serialización y reproceso | confiar en un callback en memoria como outbox |

No hace falta nombrar un broker concreto en el puerto. Su confirmación de publicación sí importa en el dispatcher y debe probarse contra el cliente elegido.
La implementación idiomática y sus límites se desarrollan en [Java y Spring Boot](../05-plataformas-y-practica/02-java-y-spring-boot.md), [Node y TypeScript](../05-plataformas-y-practica/03-node-y-typescript.md), [Go](../05-plataformas-y-practica/04-go.md) y [Python](../05-plataformas-y-practica/05-python.md).

## 6. ⚖️ Decisión y coste

Usa outbox cuando perder la publicación es inaceptable y no hay una transacción común entre base y broker. En una notificación prescindible, un mecanismo más simple puede bastar si se declara la pérdida posible. La outbox añade tabla, dispatcher, reintentos, limpieza y atención operativa; a cambio permite recuperar la intención de publicación tras una caída. La prueba crítica provoca una caída después de publicar y antes de marcar, y verifica que el consumidor soporta el duplicado.

## ⚠️ Errores frecuentes

- “Guardar y publicar son atómicos porque están en el mismo método.” Son recursos con commits distintos.
- “La outbox garantiza exactly once.” El dispatcher puede publicar dos veces.
- “Evento de dominio es el JSON público.” El contrato externo necesita versión y datos adecuados a sus consumidores.
- “Publicar después del commit basta.” El proceso puede caer antes del envío.
- “La DLQ evita operar el sistema.” Requiere responsable, inspección y reproceso.

## 7. ✅ Veredicto

Persiste estado e intención de publicación en un commit local; entrega luego de forma recuperable, observable e idempotente. Distingue hecho de dominio, contrato externo y mecánica de broker. Ese coste se justifica por la consecuencia de perder el mensaje.

## 📚 Referencias

- [Transactional Outbox](https://microservices.io/patterns/data/transactional-outbox.html)
- [Polling publisher](https://microservices.io/patterns/data/polling-publisher.html)
- [Go: transacciones con sql.Tx](https://go.dev/doc/database/execute-transactions)
- [RabbitMQ: publisher confirms y ACK](https://www.rabbitmq.com/docs/confirms)
- [Spring Framework: eventos ligados a transacciones](https://docs.spring.io/spring-framework/reference/data-access/transaction/event.html)

## 🧠 Preguntas

1. 🟢 ¿Qué problema de doble escritura resuelve la outbox?
2. 🟢 ¿Qué se guarda en el mismo commit que el pedido?
3. 🟢 ¿Qué hace el dispatcher?
4. 🟢 ¿Qué diferencia hay entre evento de dominio e integración?
5. 🟢 ¿Por qué el núcleo no conoce el topic?
6. 🟢 ¿Qué es una confirmación del publisher?
7. 🟢 ¿Qué significa entrega al menos una vez?
8. 🟡 ¿Por qué la outbox no garantiza exactly once?
9. 🟡 ¿Cuándo marcas una fila como enviada?
10. 🟡 ¿Qué identidad usas para deduplicar la publicación?
11. 🟡 ¿Cómo preservas orden por pedido?
12. 🟡 ¿Qué observas en la operación del dispatcher?
13. 🟡 ¿Qué diferencia hay entre polling y leer el log de transacciones?
14. 🟡 ¿Qué aporta `sql.Tx` de Go al guardar pedido y outbox?
15. 🟡 ¿Qué error introduce una promesa `publish()` no esperada en Node?
16. 🟠 ¿Cuándo aceptarías una publicación sin outbox?
17. 🟠 El commit funciona y el proceso cae antes de publicar. ¿Qué recupera el mensaje?
18. 🟠 El broker confirma y el dispatcher cae antes de marcar. ¿Qué pasará?
19. 🟠 La outbox se guarda en otra base. ¿Qué garantía se perdió?
20. 🟠 Dos workers publican versiones 2 y 3 fuera de orden. ¿Qué rediseñas?
21. 🟠 Un evento externo copia el objeto `Order` completo. ¿Qué riesgo ves?
22. 🟠 La tabla outbox crece sin límite. ¿Qué política falta?
23. 🟠 Spring despacha un evento después del commit sin registro durable. ¿Qué ventana queda?
24. 🟠 ¿Cómo pruebas la frontera entre outbox y consumidor?

**Siguiente:** [Composition root e inyección de dependencias](04-composition-root-e-inyeccion-de-dependencias.md).
