# 05 — Comunicación interna: llamadas, comandos y eventos

Aprenderás a elegir el mecanismo más simple que conserve la semántica del caso de uso. Una llamada,
un comando y un evento no son niveles de madurez: responden de manera distinta a la necesidad de
respuesta, el fan-out, el orden, los errores y la transacción.

## 1. 🎯 Empieza por la promesa

`CreateOrder` necesita saber si hay stock antes de confirmar. `NotifyCustomer` puede ocurrir
después del commit y tolerar demora. Usar el mismo mecanismo para ambos flujos oculta una diferencia
de negocio.

```text
respuesta necesaria ahora
orders ──ReserveInventory──► inventory
orders ◄──ReservationCreated | InsufficientInventory

hecho ya consumado
orders ──OrderCreated──► [notifications, analytics, ...]
```

La llamada conserva respuesta y error directos. El evento permite fan-out y separa al productor de
consumidores, pero necesita semántica de fallo. Ninguno es universalmente más desacoplado.

## 2. 🧰 Opciones en proceso

| Mecanismo | Úsalo cuando | Conserva | Coste o riesgo |
|---|---|---|---|
| Llamada directa | un módulo conoce una capacidad estable | respuesta y stack simples | dependencia explícita |
| Interfaz | quieres invertir el conocimiento de código | contrato del consumidor | abstracción y wiring |
| Mediador/comando | quieres separar emisor de handler | una intención y un resultado | indirección y registro |
| Evento interno | publicas un hecho a cero o más consumidores | fan-out y desconocimiento de consumidores | orden, errores y observación |

Un comando tiene un responsable lógico y puede devolver resultado. Un evento nombra algo que ya
ocurrió; sus consumidores no cambian el pasado del productor. Si `InventoryReservationRequested`
requiere exactamente un handler y una respuesta para continuar, probablemente es un comando con
nombre de evento.

## 3. ✅ Flujo síncrono con resultado

```typescript
type Reservation =
  | { kind: "created"; reservationId: string }
  | { kind: "out_of_stock"; products: string[] };

interface InventoryApi {
  reserve(command: ReserveInventory): Promise<Reservation>;
}
```

Que TypeScript use `Promise` no implica red ni ejecución paralela. El llamador espera un resultado y
debe manejar rechazo o cancelación. Si la implementación accede a la base en la misma unidad de
trabajo, la frontera transaccional debe ser explícita en composición, no escondida en el tipo.

## 4. 📣 Evento interno y errores

```python
@dataclass(frozen=True)
class OrderCreated:
    order_id: str
    customer_id: str

def confirm_order(cmd: ConfirmOrder) -> Order:
    order = orders.confirm(cmd)
    events.append(OrderCreated(order.id, order.customer_id))
    return order
```

La lista de eventos solo registra intención de publicación. Decide cuándo se despacha:

- **antes del commit:** un fallo de handler puede abortar; hay acoplamiento transaccional;
- **después del commit en memoria:** la respuesta ya confirmó, pero una caída puede perder el efecto;
- **persistido con el estado:** permite reintento, a costa de job/cola y deduplicación.

Este capítulo elige semántica; el [procesamiento durable](../03-datos-ejecucion-y-operacion/03-eventos-internos-jobs-y-procesamiento-asincrono.md) desarrolla la persistencia y recuperación del trabajo. No llames
«eventual» a un handler síncrono ejecutado en la misma pila.

## 5. 🔢 Orden, fan-out y contexto

Con varios handlers, define si el orden importa. Depender del orden de registro es un contrato oculto.
Si `notifications` solo debe actuar después de que `payments` haga algo, quizá existe una secuencia de
comandos o falta un hecho posterior.

El contexto de correlación, actor y transacción debe propagarse deliberadamente. Node ofrece
`AsyncLocalStorage` a través de callbacks y promesas; Python ofrece `contextvars`, integrado con
`asyncio`. Ambos facilitan contexto técnico, pero no deben esconder parámetros de negocio ni crear
estado global mutable.

## 6. ⚠️ Fallos y reversibilidad

Para cada mecanismo pregunta:

1. ¿Quién observa el error?
2. ¿El productor ya confirmó su estado?
3. ¿Puede repetirse el handler y con qué idempotencia?
4. ¿Qué orden se promete?
5. ¿Cómo se ve trabajo pendiente o perdido?
6. ¿Cómo vuelvo a una llamada directa si la indirección no aporta?

Un bus en memoria no es una cola durable. En Node, `EventEmitter` ejecuta listeners sincrónicamente
por defecto y un evento `error` sin listener puede terminar el proceso. En Python, una
`asyncio.Queue` distribuye trabajo entre tasks, pero el proceso sigue siendo su frontera de
durabilidad.

## 7. ⚖️ Decisión y coste

Elige llamada o comando cuando necesitas respuesta, orden y error inmediato. Elige evento cuando
publicas un hecho estable y los consumidores pueden reaccionar sin controlar la transacción del
productor. Añade asincronía solo si separar tiempo aporta latencia, aislamiento o capacidad, y define
recuperación antes de llamarla confiable.

## ⚠️ Errores frecuentes

- «Los eventos siempre desacoplan». Mantienen esquema, orden y entrega.
- «Una llamada local impide extraer». La frontera de datos y contrato pesa más.
- «`Promise` o `async` significa ejecución distribuida». Solo modela espera.
- «Un bus garantiza entrega». Uno en memoria pierde eventos al caer el proceso.
- «Un evento puede ordenar al consumidor». Eso suele ser un comando disfrazado.

## 8. ✅ Veredicto

Diseña primero la promesa: respuesta, atomicidad, orden y tolerancia al tiempo. Usa una llamada
explícita como opción base; añade mediación o eventos cuando cambien de verdad el conocimiento o el
tiempo del flujo. Todo mecanismo asíncrono debe exponer errores, repetición y trabajo pendiente.

## 📚 Referencias

- [Events, Node.js](https://nodejs.org/api/events.html)
- [Asynchronous context tracking, Node.js](https://nodejs.org/api/async_context.html)
- [contextvars — Context Variables, Python](https://docs.python.org/3/library/contextvars.html)
- [Queues, Python asyncio](https://docs.python.org/3/library/asyncio-queue.html)

## 🧠 Preguntas

1. 🟢 ¿Cuándo es adecuada una llamada directa entre módulos?
2. 🟢 ¿Qué diferencia hay entre un comando y un evento?
3. 🟢 ¿Qué ventaja ofrece una interfaz entre módulos?
4. 🟢 ¿Qué función cumple un mediador de comandos?
5. 🟢 ¿Qué significa fan-out?
6. 🟢 ¿Una `Promise` de TypeScript implica una llamada remota?
7. 🟢 ¿Un bus en memoria garantiza entrega tras una caída?
8. 🟡 ¿Por qué `InventoryReservationRequested` puede ser un comando disfrazado?
9. 🟡 ¿Qué garantía conserva una llamada síncrona con resultado?
10. 🟡 ¿Cuándo un evento reduce conocimiento del productor?
11. 🟡 ¿Qué cambia al despachar eventos antes o después del commit?
12. 🟡 ¿Por qué un handler síncrono no crea consistencia eventual?
13. 🟡 ¿Qué problema crea depender del orden de registro de handlers?
14. 🟡 ¿Qué deben propagar `AsyncLocalStorage` y `contextvars` y qué no deberían ocultar?
15. 🟡 ¿Qué diferencia hay entre asincronía y durabilidad?
16. 🟡 ¿Qué debes definir antes de permitir reintentos de un handler?
17. 🟡 ¿Por qué una llamada local no bloquea por sí sola una extracción futura?
18. 🟠 `notifications` falla después de confirmar el pedido. ¿Qué semánticas compararías?
19. 🟠 Dos handlers deben ejecutarse en orden estricto. ¿Mantendrías un evento genérico?
20. 🟠 Un listener async de Node rechaza su promesa. ¿Qué debe hacer el diseño?
21. 🟠 Una cola `asyncio` acumula trabajo y el proceso se reinicia. ¿Qué garantía faltaba?
22. 🟠 El bus interno tiene exactamente un consumidor y devuelve una respuesta. ¿Qué simplificación evaluarías?
23. 🟠 ¿Cómo migrarías de un evento en memoria a procesamiento durable sin duplicar efectos?
24. 🟠 ¿Qué criterio usarías para retirar un mediador que solo añade indirección?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [04 — Propiedad de datos en una base compartida](04-propiedad-de-datos-en-una-base-compartida.md).

**Siguiente:** [06 — Código compartido, *shared kernel* y controles arquitectónicos](06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md).
