# 07 — Eventos de dominio y efectos secundarios

Este capítulo enseña a expresar que algo importante ocurrió sin hacer que una entidad llame un broker, un correo o un SDK. Un evento de dominio describe un hecho de la política; publicar un mensaje de integración es una decisión posterior y más costosa.

## 1. 🎯 El problema

Después de crear un pedido hay que reservar inventario, notificar al cliente y actualizar un informe. Si `Order` publica directamente en Kafka o manda un correo, el núcleo queda atado a infraestructura y una prueba de una regla necesita levantar medio sistema.

## 2. 🧱 Evento como hecho del dominio

Un agregado puede recoger eventos durante una mutación:

```java
final class Order {
    private final List<DomainEvent> events = new ArrayList<>();

    void confirm() {
        // protege invariantes y cambia el estado
        events.add(new OrderConfirmed(id, customerId));
    }
}
```

`OrderConfirmed` es un hecho interno: tiene identidad, tiempo de negocio y datos necesarios para reaccionar. No lleva headers de Kafka, un topic ni un DTO de HTTP. El caso de uso recoge los eventos y un dispatcher local puede ejecutar handlers después de la mutación.

Python puede expresar la misma separación sin un bus dentro de la entidad:

```python
from dataclasses import dataclass, field


@dataclass(frozen=True)
class OrderConfirmed:
    order_id: str
    customer_id: str


class EmptyOrder(Exception):
    pass


@dataclass
class Order:
    id: str
    customer_id: str
    items: list[str]
    status: str = "DRAFT"
    _events: list[OrderConfirmed] = field(default_factory=list)

    def confirm(self) -> None:
        if not self.items:
            raise EmptyOrder()
        self.status = "CONFIRMED"
        self._events.append(OrderConfirmed(self.id, self.customer_id))

    def pull_events(self) -> tuple[OrderConfirmed, ...]:
        events, self._events = tuple(self._events), []
        return events
```

La entidad registra el hecho y nada más. Aplicación decide cuándo extraerlo; un adaptador puede
persistir su traducción en una outbox dentro de la misma transacción.

## 3. 🔄 Consistencia y publicación

Si el handler manda un correo antes del commit y luego la base revierte, el mundo externo observa algo que nunca ocurrió. Si publica después del commit y el proceso cae, el pedido existe pero nadie recibió el evento. Para cruzar la frontera de integración se usa una [outbox con dispatcher](../04-adaptadores-de-salida-y-operacion/03-publicacion-de-eventos-y-outbox.md) u otro mecanismo durable.

```text
dominio ─► evento de dominio ─► transacción local ─► outbox
                                                   │
                                          dispatcher/reintento
                                                   ▼
                                  evento de integración / email
```

Un handler local puede ser síncrono si forma parte de la misma consistencia y no llama sistemas remotos. Un efecto externo normalmente debe ser asíncrono, idempotente y observable. “Después” significa después del commit, no simplemente después de otra línea de código.

## 4. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | clases, records y mecanismos de eventos del framework | contrato del evento y momento de despacho | confundir evento de Spring con evento de dominio |
| Node/TS | módulos, `EventEmitter` y promesas | ciclo de vida, errores y durabilidad | usar un emitter en memoria como bus confiable |
| Go | structs, interfaces y goroutines | dispatcher, cancelación y persistencia | lanzar una goroutine y perder el error |
| Python | dataclasses, callbacks y async | registro de handlers y aislamiento | usar señales globales como integración durable |

El mecanismo local no garantiza entrega. Un evento en memoria desaparece al reiniciar y puede ejecutarse dos veces si el dispatcher reintenta. La semántica —qué significa el hecho, cuándo se almacena y cómo se deduplica— sigue siendo responsabilidad del diseño.

## 5. ⚖️ Evento de dominio contra evento de integración

| Dimensión | Evento de dominio | Evento de integración |
|---|---|---|
| Audiencia | núcleo y handlers cercanos | otros procesos o equipos |
| Forma | modelo interno estable para la política | contrato versionado y documentado |
| Entrega | puede ser memoria o local | requiere durabilidad, reintento y observabilidad |
| Evolución | cambia con el modelo | necesita compatibilidad y ownership |

No todo cambio merece un evento. Si solo hay que ejecutar una línea local, una llamada directa puede ser más clara. Si varios consumidores necesitan reaccionar a un hecho y el acoplamiento temporal importa, un evento puede compensar su complejidad.

## 6. ⚖️ Decisión y coste

El dominio registra hechos; la aplicación coordina cuándo se despachan; infraestructura garantiza durabilidad y traducción al protocolo externo. El evento no es una excusa para ocultar dependencias ni una garantía de entrega por sí mismo.

## ⚠️ Errores frecuentes

- “Un evento de dominio es un mensaje de Kafka.” El primero expresa política; el segundo es un contrato de integración.
- “Publicar después de `save` es suficiente.” Un crash puede dejar estado guardado y evento perdido.
- “Un bus en memoria es confiable.” No sobrevive reinicios ni garantiza entrega.
- “Cada método debe emitir eventos.” Los eventos deben representar hechos relevantes, no trazas de implementación.
- “Los handlers son gratis.” Añaden orden, reintentos, duplicados, observabilidad y ownership.

## 7. ✅ Veredicto

Usa eventos para hechos con reacciones o evolución independientes y publica integración después de un commit durable. Para un único efecto local, una llamada directa suele ser más clara.

## 📚 Referencias

- [Martin Fowler: Domain Event](https://martinfowler.com/eaaDev/DomainEvent.html)
- [Microservices.io: Transactional Outbox](https://microservices.io/patterns/data/transactional-outbox.html)
- [Spring Framework: transaction-bound events](https://docs.spring.io/spring-framework/reference/data-access/transaction/event.html)
- [Python: dataclasses](https://docs.python.org/3/library/dataclasses.html)
- [Node.js: EventEmitter](https://nodejs.org/api/events.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un evento de dominio?
2. 🟢 ¿Qué hecho representa `OrderConfirmed`?
3. 🟢 ¿Dónde se registra un evento?
4. 🟢 ¿Qué diferencia hay entre evento de dominio y de integración?
5. 🟢 ¿Por qué el dominio no debe conocer Kafka?
6. 🟢 ¿Qué es un handler?
7. 🟢 ¿Qué significa publicar después del commit?
8. 🟡 ¿Cuándo usarías un evento y cuándo una llamada directa?
9. 🟡 ¿Cómo recogerías eventos dentro de un agregado en Java o Python?
10. 🟡 ¿Qué datos debe contener un evento?
11. 🟡 ¿Qué problema resuelve una outbox?
12. 🟡 ¿Por qué un evento puede procesarse dos veces?
13. 🟡 ¿Qué hace idempotente a un handler?
14. 🟡 ¿Qué coste introduce un bus en memoria como `EventEmitter` de Node?
15. 🟡 ¿Cómo versionas un evento de integración?
16. 🟡 ¿Qué observabilidad necesita un dispatcher?
17. 🟠 El email se envía y luego falla el commit. ¿Qué rediseñas?
18. 🟠 El commit funciona y el proceso cae antes de publicar. ¿Qué mecanismo falta?
19. 🟠 Un handler cambia el agregado que acaba de emitir el evento. ¿Qué riesgo analizas?
20. 🟠 Un equipo quiere exponer el evento interno como API pública. ¿Qué preguntas haces?
21. 🟠 El mismo evento llega tres veces. ¿Dónde deduplicas?
22. 🟠 Un handler remoto tarda 20 segundos. ¿Lo ejecutas dentro del caso de uso?
23. 🟠 Dos consumidores necesitan formas incompatibles del hecho. ¿Compartes el evento?
24. 🟠 ¿Cómo defenderías no usar eventos en un CRUD pequeño?

**Siguiente:** [Simulación de entrevista](08-simulacion-de-entrevista.md).
