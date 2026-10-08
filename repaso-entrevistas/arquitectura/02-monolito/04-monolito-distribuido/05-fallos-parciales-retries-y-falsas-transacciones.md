# 05 — Fallos parciales, retries y falsas transacciones

Aprenderás a representar un resultado remoto incierto como un estado de negocio, a recuperarlo sin
duplicar el efecto y a reconocer cuándo el código llama «transacción» a algo que la base no puede
garantizar.

## 1. 🎯 Síntoma y decisión

`orders` guarda el pedido y, dentro del mismo método marcado como transaccional, llama a `payments`
para autorizar el cobro. Un martes, el proveedor de pagos responde lento; `payments` agota su timeout
de dos segundos y `orders` hace rollback del pedido y responde error al cliente. Pero el proveedor sí
había autorizado. El cliente reintenta, el nuevo intento genera otra clave y el proveedor autoriza
otra vez. Al final del día hay 41 clientes con dos autorizaciones y ningún pedido, y soporte las
anula a mano una por una.

El código trató el timeout como un rechazo y el rollback local como si deshiciera el cobro remoto. La
decisión de este capítulo es cómo representar el resultado que nadie conoce todavía, quién lo resuelve
y cómo se evita el segundo efecto.

## 2. 🧠 Modelo mental

Un timeout pierde la **respuesta**, no necesariamente la **ejecución**. Entre dos autoridades —la base
de `orders` y el proveedor— hay una ventana de incertidumbre que ninguna transacción local cierra. Se
modela como un estado más, con identidad estable y un camino hacia una resolución.

```text
orders confirma intención local + trabajo durable        ← transacción local: hasta aquí
   → payments registra la operación con una clave estable
   → AuthorizePayment(key, amount, currency)
       ├─ confirmación          → AUTHORIZED → orders decide confirmar
       ├─ rechazo definitivo    → REJECTED   → liberar la reserva
       └─ sin certeza (timeout) → PENDING    → consultar por la misma clave
                                                  └─ sin resolución en plazo → REVIEW
```

`notifications` comunica el estado que confirmó `orders`; no deduce el éxito de haber enviado la
solicitud. `inventory` conserva una reserva con vencimiento: si vence mientras el pago está
pendiente, el pedido no se confirma sin recuperar stock o anular la autorización.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 41 clientes con dos autorizaciones del proveedor y ningún pedido; en el log de `payments`, timeouts de 2 s seguidos de respuestas `AUTHORIZED` del proveedor que nadie leyó; cada reintento del cliente generó una clave nueva; el método de `orders` que guarda y cobra lleva la anotación transaccional |
| Inferencia | el timeout se interpretó como rechazo, el rollback local se tomó por deshacer el cobro y la clave de idempotencia se generaba por intento, no por intención |
| Diagnóstico | falsa transacción entre `orders` y el proveedor, sin estado para el resultado incierto y sin identidad estable de la operación |
| Recomendación | intención y trabajo durable en la transacción local, clave estable por intención, estado `PENDING` consultable, reconciliación por clave con plazo y revisión, y reintentos acotados en una sola capa |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si las autorizaciones dobles
vinieran de dos pedidos distintos del mismo cliente, serían dos intenciones legítimas y la clave no
debería fusionarlas. Y un resultado incierto, por sí solo, no prueba un
[monolito distribuido](01-anatomia-y-evidencia-del-monolito-distribuido.md): es el precio de cualquier
dependencia remota, incluida la de un monolito con un proveedor externo.

## 4. 🛠️ Persistencia, idempotencia y recuperación

**Antes de salir a red** se persiste la operación, su clave, una huella de la solicitud y el estado
`PENDING`, en la misma [transacción local](../03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md)
que la intención de pago. Una restricción única por ámbito de negocio impide carreras; la misma clave
con otro importe es un conflicto, no un nuevo cobro. La clave se reutiliza en reintentos y consultas:
nunca se genera una por intento. Su retención cubre la ventana del proveedor y la de la recuperación
local.

**Outbox e inbox.** Una outbox guarda el cambio de estado y el mensaje en la misma transacción; el
publicador puede caer después de entregar y antes de marcar enviado, así que habrá repeticiones. Una
inbox o tabla de deduplicación registra el mensaje y el efecto local en otra transacción, en el
consumidor. Ninguna protege un efecto externo: el proveedor necesita respetar la clave o permitir
consultar por ella.

**Saga y compensación.** Una saga coordina pasos locales y compensaciones. Anular una autorización es
una operación nueva que puede fallar; no borra el historial como un rollback SQL. **2PC** exige
participantes y coordinador compatibles, retiene recursos durante los fallos y el proveedor externo
casi nunca participa; se considera solo con un requisito y soporte demostrados.

## 5. 💻 Estado mínimo en Java

Política pura, compatible con Java 17 o posterior; no implementa transporte ni durabilidad. El worker
consulta al proveedor por la clave persistida y aplica la transición con control de versión. Las
restricciones que la hacen segura están en [idempotencia local](../03-datos-ejecucion-y-operacion/02-concurrencia-locking-e-idempotencia.md).

```java
final class PaymentReconciliation {
    enum State { PENDING, AUTHORIZED, REJECTED, REVIEW }
    enum Lookup { AUTHORIZED, REJECTED, UNKNOWN }
    static State next(State current, Lookup lookup, boolean deadlinePassed) {
        if (current != State.PENDING) return current;
        if (lookup == Lookup.AUTHORIZED) return State.AUTHORIZED;
        if (lookup == Lookup.REJECTED) return State.REJECTED;
        return deadlinePassed ? State.REVIEW : State.PENDING;
    }
}
```

- Solo `PENDING` avanza: un estado ya resuelto no lo cambia un worker atrasado.
- `UNKNOWN` incluye la consulta fallida o la ausencia todavía no concluyente; nunca equivale a
  rechazo.
- Pasado el plazo, el estado va a `REVIEW` en lugar de seguir reintentando para siempre; una persona
  lo resuelve con una transición auditada distinta.
- La escritura del nuevo estado usa actualización condicional: si otro reconciliador ganó la carrera,
  se vuelve a leer en lugar de sobrescribir.

**Validación.** El 2026-09-29 la política se compiló con `javac 25.0.4 -Xlint:all` y se recorrieron sus
24 combinaciones de estado, consulta y plazo: ningún estado resuelto cambia y `UNKNOWN` nunca produce
`REJECTED` desde `PENDING`.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | transacción local y actualización condicional del estado | atomicidad con el proveedor | incluir la llamada HTTP dentro de una transacción larga |
| Node/TypeScript | cliente transaccional y worker durable | la durabilidad de una `Promise` | confundir `await` con un commit remoto |
| Go | transacción explícita y `context` con deadline | deshacer un efecto remoto al cancelar | generar otra clave tras cancelar el contexto |
| Python | transacción local y consumidor persistente | recuperar una tarea que solo vivía en memoria | suponer que una excepción implica rechazo |

Las cuatro trampas son la misma confusión en cuatro sintaxis: tratar el final de la espera local
—un `await` que vuelve, un contexto cancelado, una excepción— como si dijera algo del resultado
remoto. En todas las plataformas, el *ack* de un mensaje se envía después de confirmar el efecto y la
inbox locales, y la clave de la operación sobrevive a cualquier cancelación.

## 7. ⚖️ Decisión y coste

Conservas trazabilidad y evitas duplicar una autorización cuando el proveedor respeta la clave. Pagas
estados pendientes visibles, almacenamiento de claves, un reconciliador y atención operativa para
`REVIEW`. Ensaya caída antes y después de publicar, respuesta perdida, mensajes duplicados y
reconciliadores concurrentes; mide la edad del pendiente más antiguo y las divergencias con el
proveedor, no solo el tamaño de la cola. Reintenta fallos transitorios con límite, backoff y jitter
dentro de un presupuesto global; un rechazo de negocio no se arregla reintentando. Si la invariante
debe ser local y los dos componentes son propios, considera mantenerlos unidos.

## ⚠️ Errores frecuentes

- «Guardar y cobrar en el mismo método transaccional es atómico». El rollback deshace filas locales;
  la autorización remota ya ocurrió.
- «Un timeout es un pago rechazado». Es una respuesta perdida; el cobro pudo hacerse y hay que
  consultarlo por la clave.
- «Cada reintento lleva su propia clave de idempotencia». Entonces cada reintento es una intención
  nueva, y el proveedor cobra otra vez.
- «La outbox garantiza que el mensaje llega una vez». Garantiza que no se pierde; habrá repeticiones y
  el consumidor debe deduplicar.
- «La compensación es un rollback remoto». Es otra operación, con su propio fallo, que deja rastro.

## 8. ✅ Veredicto

La operación incierta es un estado de negocio y de operación, no un error que se reintenta hasta que
desaparece. Persiste la intención y su clave antes de salir a red, reutiliza la clave en cada intento y
consulta, resuelve `PENDING` por reconciliación con plazo y deja lo irresoluble en revisión con
evidencia. Y no llames transacción a lo que cruza una frontera que tu base no controla.

## 📚 Referencias

- [Making retries safe with idempotent APIs, Amazon Builders' Library](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)
- [Transactional outbox pattern, AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
- [Pattern: Saga, microservices.io](https://microservices.io/patterns/data/saga.html)

## 🧠 Preguntas

1. 🟢 ¿Qué significa que un resultado remoto sea incierto?
2. 🟢 ¿Qué protege una outbox y qué no?
3. 🟢 ¿Qué protege una inbox transaccional?
4. 🟢 ¿Qué diferencia hay entre un rechazo y un estado pendiente?
5. 🟢 ¿Qué es una compensación y en qué se diferencia de un rollback?
6. 🟡 ¿Por qué no se genera una clave nueva al reintentar?
7. 🟡 ¿Qué haces si llega la misma clave con otro importe?
8. 🟡 ¿Dónde termina la atomicidad en el método que guarda el pedido y llama a `payments`?
9. 🟡 ¿Cómo recuperas una caída del publicador después de entregar un mensaje de la outbox?
10. 🟡 ¿Cómo resuelves un *ack* perdido después del commit del consumidor?
11. 🟡 ¿Qué debe mostrar `orders` al cliente mientras el pago está en `PENDING`?
12. 🟡 ¿Qué pasa si vence la reserva de `inventory` antes de conocer el resultado del pago?
13. 🟡 ¿Cuándo considerarías 2PC, y por qué casi nunca aplica a un proveedor externo?
14. 🟡 ¿Qué métrica priorizas para saber si la reconciliación va al día?
15. 🟡 ¿Cómo decides el presupuesto de reintentos y en qué capa van?
16. 🟡 ¿Qué evento dispara el aviso de `notifications`, y por qué no el envío de la solicitud de pago?
17. 🟡 ¿Qué error comparten un `await` en Node y una llamada HTTP de Java dentro de una transacción?
18. 🟠 ¿Qué riesgo comparten cancelar un `context` en Go y capturar una excepción en Python tras llamar al proveedor?
19. 🟠 ¿Cómo evitas que dos reconciliadores sobrescriban el estado de la misma operación?
20. 🟠 El proveedor no ofrece consulta por clave ni idempotencia. ¿Qué haces?
21. 🟠 La anulación de una autorización también falla. ¿Cómo reaccionas?
22. 🟠 ¿Qué prueba detectaría la falsa transacción de la sección 1 antes de producción?
23. 🟠 ¿Puede borrarse la clave de idempotencia cuando el pedido termina?
24. 🟠 Tienes 41 clientes con dos autorizaciones. ¿Qué haces hoy y qué cambias para que no se repita?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [04 — Contratos frágiles y despliegues coordinados](04-contratos-fragiles-y-despliegues-coordinados.md).

**Siguiente:** [06 — Acoplamiento asíncrono: el monolito distribuido con broker](06-acoplamiento-asincrono-el-monolito-distribuido-con-broker.md).
