# 06 — Acoplamiento asíncrono: el monolito distribuido con broker

Aprenderás a reconocer cuándo un broker cambia el **momento** del acoplamiento sin reducirlo, y a
decidir qué evento, qué esquema o qué dueño del flujo devuelve autonomía real. Cambiar HTTP por
mensajes es una decisión de transporte; desacoplar es una decisión de contrato y de promesa.

## 1. 🎯 Problema y evidencia

Tras el diagnóstico de la [cadena síncrona](02-cadenas-sincronas-y-acoplamiento-temporal.md), el
equipo reemplaza las llamadas HTTP por mensajes en un broker. Seis meses después, el cuadro es este:

- `orders` publica `ReserveInventoryRequested` y espera hasta dos segundos la respuesta de
  `inventory` en otro tópico antes de contestar a checkout. Si `inventory` va atrasado consumiendo,
  checkout falla igual que antes.
- `orders` publica `OrderUpdated` con la entidad completa del pedido: 43 campos. Cuatro consumidores
  leen campos distintos. Un renombrado en el modelo interno de `orders` rompió `notifications` días
  después, al reprocesar mensajes retenidos.
- Todos los componentes dependen de una librería `commerce-events` con las clases de todos los
  eventos; actualizarla obliga a desplegar a la vez.
- La compra avanza por reacciones encadenadas —`orders`, `inventory`, `payments`, `notifications`—
  y nadie sabe decir en qué paso está un pedido concreto. Cuando el consumidor de `payments` acumula
  veinte minutos de retraso, hay pedidos en `PENDING` y soporte no sabe dónde buscar.

La observación es que el broker está en todas partes; la inferencia, que el acoplamiento sigue ahí
con otra forma. El [diagnóstico de monolito distribuido](01-anatomia-y-evidencia-del-monolito-distribuido.md)
se sostiene si esas señales se repiten en los cambios: releases conjuntos por la librería, datos
repartidos por la entidad publicada y un flujo que necesita a todos para completarse.

## 2. 🧠 Qué cambia y qué no cuando entra un broker

| Moneda | Cadena HTTP | Broker mal usado | Broker con hechos y dueño |
|---|---|---|---|
| Runtime | todos disponibles ahora | todos responden antes del timeout, o el flujo espera en backlog | el productor responde sin esperar; el consumidor alcanza después |
| Datos | se pide el dato al dueño | el evento es la entidad: base compartida diferida | el evento es un hecho mínimo; cada consumidor mantiene lo que necesita |
| Código | API del proveedor | esquema = modelo interno del productor | esquema versionado que el productor controla |
| Despliegue | lockstep por la API | lockstep por la librería de eventos | el productor evoluciona de forma aditiva |
| Equipos | quien responde decide | nadie es dueño del proceso | un dueño explícito del flujo y de su estado |

Cinco formas de acoplamiento sobreviven al cambio de transporte:

1. **Comando disfrazado de evento.** `ReserveInventoryRequested` no informa de algo que ocurrió: pide
   algo y espera respuesta. Con una espera sobre otro tópico, es una llamada remota con más piezas.
2. **Entidad publicada como evento.** Mandar el modelo interno completo convierte cada campo en
   contrato. Es una base compartida diferida: los consumidores leen la estructura del productor, solo
   que días después y sin permisos que lo limiten.
3. **Coreografía sin dueño.** Cada componente reacciona al anterior y el proceso completo no existe
   en ningún sitio. Nadie puede responder «¿en qué estado está este pedido?» sin reconstruirlo.
4. **Acoplamiento temporal diferido.** El productor ya no se cae si el consumidor se cae, pero el
   resultado de negocio sigue necesitando a todos: el retraso del consumidor es ahora latencia del
   flujo, y el orden y el reprocesamiento son requisitos nuevos.
5. **Esquema compartido como librería.** Una clase por evento en un paquete común obliga a todos a
   actualizar y desplegar a la vez: el lockstep vuelve por el build.

## 3. 🛠️ Hecho frente a modelo interno, en código

Los dos contratos de `orders`, y el comando disfrazado, en TypeScript:

```typescript
// Evento que expone el modelo interno de orders: cada consumidor se ata a su forma
export interface OrderUpdated {
  type: "OrderUpdated";
  order: {
    id: string;
    status: "DRAFT" | "PENDING" | "CONFIRMED" | "CANCELLED";
    customer: { id: string; email: string; tier: string };
    lines: { sku: string; quantity: number; unitPrice: number; reservationStatus: string }[];
    internalNotes: string;
    version: number;
  };
}

// Hecho con dueño y versión: dice qué ocurrió y lo mínimo para reaccionar
export interface OrderConfirmedV1 {
  eventId: string;
  type: "OrderConfirmed";
  version: 1;
  occurredAt: string;
  orderId: string;
  lines: ReadonlyArray<Line>;
}

// Comando disfrazado: publica y espera la respuesta antes de contestar al cliente
export async function reserveViaQueue(
  broker: Broker, orderId: string, lines: Line[],
): Promise<"RESERVED" | "OUT_OF_STOCK"> {
  const correlationId = newId();
  await broker.publish("inventory.commands",
    { type: "ReserveInventoryRequested", correlationId, orderId, lines });
  // si inventory no consume a tiempo, checkout falla igual que con HTTP
  const reply = await broker.waitFor("inventory.replies",
    (m) => m.correlationId === correlationId, 2000);
  return reply.result === "RESERVED" ? "RESERVED" : "OUT_OF_STOCK";
}
```

- `OrderUpdated` publica estado interno —`internalNotes`, `reservationStatus`, la versión de la
  fila—. Quien lo consume puede depender de cualquiera de esos campos, y `orders` ya no sabe qué puede
  cambiar sin romper a alguien.
- `OrderConfirmedV1` dice un hecho de negocio con lo mínimo para reaccionar. Tiene identidad para
  deduplicar (`eventId`), versión explícita y fecha de ocurrencia. Si `notifications` necesita el
  correo del cliente, lo obtiene de su propia proyección o del dueño del dato, no del pedido.
- `reserveViaQueue` es el patrón *request-reply* sobre mensajería. Es legítimo cuando se necesita, pero
  no desacopla: la disponibilidad de checkout sigue siendo la de `inventory` en esos dos segundos, y
  ahora además la del broker y la del tópico de respuestas.

Los tipos son ilustrativos y dependen de un `Broker`, un `Line` y un `newId()` mínimos declarados
aparte; el 2026-09-29 se comprobó que compilan con `tsc 5.8.3 --strict`. La tipificación en
TypeScript no valida el mensaje en runtime: un consumidor real valida el esquema al recibir.

## 4. 🧭 Orquestación explícita frente a coreografía

```text
coreografía sin dueño                         orquestación con dueño del proceso
OrderPlaced ─► inventory ─► InventoryReserved  orders: máquina de estados del pedido
         └──► payments  ─► PaymentAuthorized     ├─► ReserveInventory   ◄── resultado
         └──► notifications                      ├─► AuthorizePayment   ◄── resultado
¿quién sabe si la compra terminó?                └── estado visible: PENDING_PAYMENT…
```

La **coreografía** encaja para difundir hechos a los que otros reaccionan de forma independiente:
avisar al cliente, alimentar analítica, invalidar una caché. Nadie necesita que esas reacciones
terminen para que la compra sea válida. Para un **proceso** con pasos, esperas y compensaciones, un
dueño del estado —que puede ser el propio módulo `orders` con una máquina de estados— hace el flujo
observable y recuperable: sabe qué pidió, qué recibió y qué hacer si algo no llega. Ninguna de las
dos es más autónoma por definición; la coreografía reparte el conocimiento del proceso, y
repartirlo sin dueño es lo que produce pedidos perdidos entre tópicos.

Los mecanismos de entrega —outbox, *at-least-once*, deduplicación— no se redefinen aquí: son los de
[eventos internos y jobs](../03-datos-ejecucion-y-operacion/03-eventos-internos-jobs-y-procesamiento-asincrono.md)
y [fallos parciales](05-fallos-parciales-retries-y-falsas-transacciones.md). Lo que este capítulo
añade es que un transporte fiable puede llevar un contrato acoplado.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | cliente del broker con confirmación manual; serialización con esquema y registro | un esquema compatible no garantiza significado compatible | serializar entidades JPA tal cual como eventos |
| Node/TypeScript | cliente del broker y validación del mensaje en runtime | los tipos no existen en runtime | publicar el paquete de tipos del productor como contrato compartido |
| Go | consumidor con commit explícito del offset o de la confirmación | una goroutine por mensaje rompe el orden por clave | confirmar antes de procesar y perder el mensaje si el proceso cae |
| Python | consumidor con confirmación explícita y reintentos acotados | reprocesar no es idempotente por sí solo | auto-confirmación con el efecto a medio aplicar |

Las cuatro filas se reparten el mismo trabajo: confirmar la recepción después de aplicar el efecto,
conservar el orden donde el negocio lo necesita y validar el mensaje contra un esquema que el
productor versiona. Ningún cliente de broker decide si el mensaje es un hecho o un comando; eso lo
decide el contrato. Las librerías concretas y sus versiones se eligen y verifican en el momento de
implementar.

## 6. ⚖️ Decisión y coste

Usa eventos para lo que puede ocurrir después y a lo que otros reaccionan por su cuenta: publica
hechos mínimos, versionados y con identidad, y deja que cada consumidor mantenga su propia
proyección. Para lo que el cliente necesita saber antes de la respuesta, una llamada síncrona honesta
con presupuesto es más clara que un *request-reply* sobre colas. Para procesos con pasos, nombra un
dueño del estado. Cada decisión paga algo: hechos mínimos cuestan proyecciones en los consumidores;
un orquestador concentra lógica del proceso; el retraso de consumo necesita su propio SLO y su
alerta.

## ⚠️ Errores frecuentes

- «Los eventos desacoplan automáticamente». Una entidad publicada acopla a su forma, y un comando
  disfrazado acopla en el tiempo.
- «Con un broker ya no hay monolito distribuido». Si los releases siguen conjuntos por la librería de
  eventos y la compra necesita a todos para completarse, el diagnóstico sigue en pie.
- «Coreografía siempre es más autónoma que orquestación». Reparte el conocimiento del proceso; sin
  dueño, nadie sabe en qué estado está un pedido.
- «Si el consumidor se cae, no pasa nada». No se cae el productor, pero el resultado de negocio se
  retrasa; el lag es latencia del flujo y necesita objetivo.
- «Una librería común de eventos evita errores de contrato». Los evita en compilación y los cambia
  por despliegues coordinados.

## 7. ✅ Veredicto

Un broker cambia cuándo te afecta el otro componente, no si te afecta. Recupera autonomía publicando
hechos con dueño y versión en lugar de entidades o comandos, dando dueño a los procesos de varios
pasos y tratando el retraso de consumo como parte del SLO. Si el flujo sigue necesitando a todos
para completarse y los contratos obligan a desplegar juntos, el transporte asíncrono no cambió el
diagnóstico.

## 📚 Referencias

- [What do you mean by “Event-Driven”?, Martin Fowler](https://martinfowler.com/articles/201701-event-driven.html)
- [Event Message](https://www.enterpriseintegrationpatterns.com/patterns/messaging/EventMessage.html), [Command Message](https://www.enterpriseintegrationpatterns.com/patterns/messaging/CommandMessage.html) y [Request-Reply](https://www.enterpriseintegrationpatterns.com/patterns/messaging/RequestReply.html), Enterprise Integration Patterns
- [Saga Design Pattern: coreografía y orquestación, Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/saga)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre un evento y un comando enviado por un broker?
2. 🟢 ¿Qué es *event-carried state transfer* y qué riesgo tiene publicar la entidad completa?
3. 🟢 ¿Qué es el patrón *request-reply* sobre mensajería?
4. 🟢 ¿Qué diferencia hay entre coreografía y orquestación?
5. 🟢 ¿Qué significa que el acoplamiento temporal quede diferido?
6. 🟢 ¿Qué campos mínimos debería llevar un hecho publicado?
7. 🟡 ¿Por qué `reserveViaQueue` no desacopla checkout de `inventory`?
8. 🟡 ¿Por qué publicar `OrderUpdated` con 43 campos se parece a compartir la base?
9. 🟡 ¿Cómo obtendría `notifications` el correo del cliente si `OrderConfirmedV1` no lo incluye?
10. 🟡 ¿Por qué una librería común de eventos devuelve el lockstep?
11. 🟡 ¿Cuándo es la coreografía la opción adecuada en el sistema de ejemplo?
12. 🟡 ¿Qué gana la compra si `orders` es dueño explícito del proceso?
13. 🟡 ¿Por qué el retraso de consumo necesita un objetivo propio?
14. 🟡 ¿Qué orden necesita el flujo de pedidos y qué lo rompe en un consumidor?
15. 🟡 ¿Qué pasa con los mensajes retenidos cuando el productor cambia el esquema?
16. 🟡 Compara, en las cinco monedas, la cadena HTTP de `04/02` con el broker mal usado de este capítulo.
17. 🟡 ¿Qué error comparten un consumidor Go que confirma antes de procesar y uno Python con auto-confirmación?
18. 🟠 ¿Por qué los tipos de TypeScript y una clase Java compartida fallan igual como contrato de eventos?
19. 🟠 El consumidor de `payments` acumula veinte minutos de retraso y hay pedidos en `PENDING`. ¿Qué harías primero?
20. 🟠 Un renombrado en el modelo de `orders` rompe a `notifications` al reprocesar mensajes de hace una semana. ¿Cómo lo corriges y cómo evitas que se repita?
21. 🟠 Quieres reemplazar `OrderUpdated` por hechos mínimos sin romper a los cuatro consumidores. ¿Qué pasos reversibles darías?
22. 🟠 Negocio necesita saber en qué paso está cada compra. ¿Añadirías un orquestador o una traza de eventos?
23. 🟠 Un equipo propone volver a HTTP porque «los eventos complicaron todo» y otro quiere más eventos. ¿Cómo decidirías?
24. 🟠 ¿Qué evidencia te diría que el broker ya compra autonomía y no solo cambia el transporte?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [05 — Fallos parciales, retries y falsas transacciones](05-fallos-parciales-retries-y-falsas-transacciones.md).

**Siguiente:** [07 — Cómo se llega: granularidad, entidades y plataforma compartida](07-como-se-llega-granularidad-entidades-y-plataforma-compartida.md).
