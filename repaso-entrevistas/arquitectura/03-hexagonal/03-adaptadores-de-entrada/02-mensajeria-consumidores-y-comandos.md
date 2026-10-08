# 02 — Mensajería, consumidores y comandos

Este capítulo enseña a ubicar un consumidor como adaptador de entrada y a decidir cuándo confirmar, reintentar o apartar un mensaje sin convertir el handler del broker en el caso de uso.

## 1. 🎯 El problema

Llega `OrderRequested` dos veces. El handler deserializa, reserva inventario y guarda el pedido antes de confirmar el mensaje. La primera ejecución confirmó la base, pero el proceso cayó antes del ACK. Si se considera que el broker garantiza ejecución única, la segunda crea otro pedido o cobra dos veces.

## 2. 🧭 Frontera y dirección

```text
broker ─► consumer adapter ─► CreateOrderCommand ─► CreateOrder
            │       ▲                                  │
            │       └──── resultado/error propio ──────┘
            └─ esquema, headers, offset/ACK, reintentos y DLQ
```

El consumer conoce el cliente, la versión del esquema y el contexto de entrega. El núcleo recibe una intención, no un `ConsumerRecord`, un delivery tag ni un topic. El [puerto de entrada](../02-nucleo-aplicacion-y-dominio/03-puertos-de-entrada.md) puede servir también a HTTP, mientras [transacciones](../02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md) explican por qué el commit de base y el ACK son dos hechos distintos. Un evento de integración externo requiere un contrato propio; un [evento de dominio](../02-nucleo-aplicacion-y-dominio/07-eventos-de-dominio-y-efectos-secundarios.md) no es automáticamente ese mensaje.

## 3. 🔄 Procesamiento defendible

1. Limita tamaño, deserializa y valida versión, campos y firma si el origen lo exige. Un fallo permanente de forma no mejora por reintentarlo sin límite.
2. Extrae identidad de operación estable del productor; no uses el offset o delivery tag como identidad de negocio. Construye `CreateOrderCommand` y propaga correlación por un contexto propio.
3. En una transacción local, el caso de uso verifica si la operación ya se aplicó, ejecuta la decisión y registra el resultado de deduplicación. Una restricción única ayuda cuando dos entregas compiten.
4. Después del commit local, el adaptador confirma la entrega. Si cae entre ambos pasos, habrá redelivery, y la deduplicación devolverá el resultado anterior.
5. Clasifica el fallo: un rechazo de negocio conocido puede confirmarse y registrarse; un timeout transitorio admite reintento con límite y espera; un mensaje ilegible va a cuarentena o DLQ con datos saneados. La estrategia depende del broker y del contrato con el productor.

No prometas “exactly once” de extremo a extremo por una configuración del cliente. Un offset confirmado tampoco demuestra que los efectos en otra base hayan ocurrido. La idempotencia tiene coste: almacenamiento de claves, retención, respuesta repetible, concurrencia y observabilidad. La duración de retención debe cubrir la ventana real de redelivery.

## 4. 🧩 Implementación mínima

```text
onMessage(envelope):
  try:
      message = parseAndValidate(envelope.payload, envelope.version)
      command = CreateOrderCommand(
          customerId=message.customerId,
          units=message.units,
          operationId=message.operationId)
      result = createOrder.execute(command)
      recordMetric("order_processed", result)
      acknowledge(envelope)  # solo después del commit del caso de uso
  catch BusinessRejection:
      recordSafeRejection(envelope.id)
      acknowledge(envelope)
  catch TransientFailure:
      retryWithLimit(envelope)
  catch InvalidSchema:
      quarantineAndAcknowledge(envelope)
```

El pseudocódigo no abre la transacción ni define una política universal para toda cola. `CreateOrder` se compone con repositorios y deduplicación en el composition root; el listener recibe solo el puerto. En Kafka, confirmar un offset y en RabbitMQ, enviar ACK tienen mecánicas diferentes; la decisión de confirmar tras el efecto local es la misma. Los efectos externos posteriores necesitan coordinación durable, como la [publicación con outbox](../04-adaptadores-de-salida-y-operacion/03-publicacion-de-eventos-y-outbox.md).

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring Kafka ofrece listeners y modos de ACK | configurar commit, reintento y error handler | creer que `@KafkaListener` define la política |
| Node/TS | NestJS ofrece patrones de mensajes y contexto del transportador | validar payload y conocer ACK real del transporte | usar `@EventPattern()` como caso de uso |
| Go | clientes de broker exponen contexto y confirmación | controlar cancelación, concurrencia y commit | confirmar antes de persistir |
| Python | clientes ofrecen callbacks o iteradores async | aislar conexión, parseo y política de reintento | capturar toda excepción y reencolar para siempre |

No se prescribe una librería de Go o Python: el puerto no debería variar al elegir cliente. Lo importante al comparar clientes es quién controla el ACK, cómo informa redelivery y cómo limita mensajes simultáneos.

## 6. ⚖️ Decisión y coste

Para un consumidor pequeño con una sola acción, el handler puede ser corto; aun así, la regla vive en `CreateOrder`. Introducir una capa de deduplicación solo compensa si la operación puede repetirse con daño o el origen puede redeliverar. Documenta la tabla de errores, la ventana de reintento y qué se inspecciona en DLQ. Prueba con dos entregas de la misma identidad, caída después del commit y mensaje inválido: un mock que solo verifica `execute()` no cubre la frontera.

## ⚠️ Errores frecuentes

- “El handler del broker es el caso de uso.” Su ciclo de vida, ACK y esquema son detalles de entrada.
- “ACK antes de ejecutar mejora throughput sin coste.” Puede perder trabajo si el proceso cae.
- “Todo fallo merece reintento.” Un esquema inválido puede bloquear una partición o llenar la cola.
- “Deduplicar por offset basta.” Una republicación puede tener otro offset para la misma operación.
- “DLQ es solución final.” Requiere inspección, corrección y política de reproceso.

## 7. ✅ Veredicto

El consumidor traduce y administra la entrega; el caso de uso decide la acción. Diseña para redelivery, ordena commit y confirmación, y deja observable cada resultado. Esa separación cuesta código de deduplicación y operaciones, pero evita duplicar política en el broker.

## 📚 Referencias

- [RabbitMQ: consumer acknowledgements](https://www.rabbitmq.com/docs/confirms)
- [Spring Kafka: listener containers y ACK](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/message-listener-container.html)
- [NestJS: microservices y patrones de mensajes](https://docs.nestjs.com/microservices/basics)
- [RabbitMQ: reliability guide](https://www.rabbitmq.com/docs/reliability)

## 🧠 Preguntas

1. 🟢 ¿Por qué un consumidor es un adaptador de entrada?
2. 🟢 ¿Qué traduce el consumer antes de llamar a `CreateOrder`?
3. 🟢 ¿Qué es un ACK del consumidor?
4. 🟢 ¿Qué datos del broker no deben entrar al núcleo?
5. 🟢 ¿Qué significa redelivery?
6. 🟢 ¿Qué diferencia hay entre mensaje y comando?
7. 🟢 ¿Qué es una DLQ o cola de cuarentena?
8. 🟡 ¿Por qué confirmas después del commit local?
9. 🟡 ¿Cómo distingues error permanente de transitorio?
10. 🟡 ¿Qué identidad usarías para deduplicar?
11. 🟡 ¿Por qué un offset no es una clave de negocio suficiente?
12. 🟡 ¿Cómo evitas dos ejecuciones simultáneas del mismo comando?
13. 🟡 ¿Qué debe conservar una respuesta idempotente?
14. 🟡 ¿Qué diferencia hay entre un ACK de RabbitMQ y un commit de offset de Kafka?
15. 🟡 ¿Qué riesgo tiene reintentar sin límite un mensaje inválido?
16. 🟡 ¿Cómo pruebas el adaptador más allá de un mock del puerto?
17. 🟠 El commit se completó y el proceso cayó antes del ACK. ¿Qué ocurrirá?
18. 🟠 Un productor republica la misma operación con otro ID de mensaje. ¿Qué revisas?
19. 🟠 El broker entrega fuera de orden dos cambios de pedido. ¿Qué protege el estado?
20. 🟠 Un error de negocio conocido se reintenta para siempre. ¿Qué cambias?
21. 🟠 Un `@KafkaListener` contiene SQL y reglas. ¿Cómo repartes responsabilidades?
22. 🟠 Un handler de NestJS asume que `@EventPattern()` da entrega exactamente una vez. ¿Qué corriges?
23. 🟠 La DLQ crece y nadie la revisa. ¿Qué capacidad operativa falta?
24. 🟠 El mismo comando llega por HTTP y mensajería. ¿Dónde haces idempotencia?

**Siguiente:** [Jobs, CLI y procesos batch](03-jobs-cli-y-procesos-batch.md).
