# 03 — Saga

> Cómo se mantiene consistente un flujo que cruza varios servicios cuando ya no hay transacción:
> coreografía, orquestación, compensaciones, y las anomalías que hay que diseñar a mano. Asume leídos
> [`01`](01-base-de-datos-por-servicio.md) y
> [`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md). El razonamiento de por qué no
> hay transacción distribuida está en
> [`arquitectura/01-bases/02-eventos/05`](../../01-bases/02-eventos/05-saga.md);
> aquí se implementa.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

La saga canónica del corpus, que ya no cabe en un `@Transactional`:

```text
orders registra  →  inventory reserva  →  payments cobra
                                             │
                                        402 rechazado
                                             ▼
                       hay que LIBERAR lo que inventory ya reservó
```

Tres servicios, tres bases de datos, tres transacciones locales. No hay ninguna que abarque las tres,
y la pregunta del entrevistador es inevitable: *"¿y si falla el cobro después de reservar?"*.

La respuesta tiene tres partes, y las tres se desarrollan en este capítulo:

1. **No se deshace, se compensa.** No hay rollback: hay una operación nueva que anula el efecto de la
   anterior, y esa operación es visible.
2. **Hay estados intermedios que el negocio tiene que aceptar.** Durante unos segundos existe un
   pedido con stock reservado y sin cobrar. Eso no es un fallo: es el diseño.
3. **Hay anomalías que ninguna base de datos te va a evitar**, porque no hay aislamiento.

---

## 2. 🪦 Por qué no se usa 2PC

**Qué es.** El compromiso en dos fases —un coordinador pregunta a todos si pueden, y luego les dice
que confirmen— es la transacción distribuida clásica, y sigue existiendo.

**Por qué no se usa entre microservicios.** Tres razones concretas, y conviene darlas así en vez de
decir "no se lleva":

- **Bloquea recursos durante toda la transacción.** Los participantes mantienen bloqueos hasta la
  segunda fase; si el coordinador tarda, el sistema entero se frena.
- **El coordinador es un punto único de fallo con estado.** Si cae entre las dos fases, los
  participantes se quedan "en duda" y necesitan intervención.
- **Casi nada lo soporta.** Bases de datos modernas, brokers y APIs de terceros no participan en 2PC,
  así que en cuanto hay un paso fuera del mundo transaccional, deja de ser aplicable.

**Cuándo sí sigue teniendo sentido.** Dentro de una frontera controlada: un gestor de transacciones
clásico entre una base relacional y una cola del mismo proveedor, en sistemas heredados de banca. Ahí
funciona y lleva décadas funcionando.

> **Veredicto:** 2PC no está prohibido, está fuera de alcance. Con servicios autónomos, bases
> distintas y terceros por medio, la única opción disponible es la saga — y por eso la saga no es una
> elección de diseño, es una consecuencia.

---

## 3. 🧱 Coreografía

**Qué es.** No hay coordinador: cada servicio reacciona a los eventos de los demás y publica los
suyos.

```text
orders ──OrderPlaced──► inventory ──InventoryReserved──► payments
                            ▲                                │
                            │                         PaymentRejected
                            └────────────────────────────────┘
                                  (inventory libera)
```

**Cómo va.** Cada servicio conoce solo sus entradas y sus salidas. Añadir un paso —avisar a `shipping`—
es suscribir un consumidor más, sin tocar a nadie.

**Cuánto.** Cuesta lo que más se subestima: **nadie sabe el estado global**. Para responder "¿por qué
este pedido lleva veinte minutos sin cobrar?" hay que reconstruir mentalmente qué reaccionó a qué. Y
el riesgo de ciclos es real: un evento dispara otro que dispara al primero.

**Cuándo sí.** Flujos de dos o tres pasos, lineales, donde cada servicio reacciona a un hecho evidente
de su dominio.

**Cuándo no.** A partir de cuatro pasos, con ramas condicionales, o cuando hay que consultar el
estado del flujo. La regla práctica: **si no puedes dibujar el flujo completo en una pizarra sin
mirar el código, la coreografía ya no te sirve**.

> **Veredicto:** la coreografía es elegante mientras el flujo cabe en tu cabeza. Su precio no es
> técnico, es de diagnóstico: el día del incidente, no hay un sitio donde mirar.

---

## 4. 🧱 Orquestación

**Qué es.** Un coordinador explícito —el orquestador— que mantiene el estado del flujo y manda
comandos a cada participante.

```text
        ┌──────────────────── orquestador de pedido ─────────────────────┐
        │  estado: PENDING → CONFIRMED → PAID                            │
        └───┬────────────────────┬────────────────────┬──────────────────┘
     ReserveInventory     AuthorizePayment     ConfirmShipment
            ▼                    ▼                    ▼
        inventory             payments             shipping
```

**Cómo va.** El orquestador es una **máquina de estados persistida**: cada respuesta lo hace avanzar o
disparar compensaciones. Y como el estado está guardado, se puede consultar: "este pedido está en
`CONFIRMED` (stock reservado) desde hace veinte minutos esperando a `payments`".

**Cuánto.** Cuesta un componente más y el riesgo de que acumule reglas de negocio ajenas. La línea:
el orquestador decide **el orden y las compensaciones**; las reglas de cada paso viven en su servicio.
Si el orquestador empieza a saber cuándo un cliente puede comprar, se ha convertido en el monolito
del capítulo [`01-fundamentos-y-descomposicion/04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md).

**Cuándo sí.** Cuatro pasos o más, ramas condicionales, necesidad de consultar el estado, o requisito
de auditoría sobre el flujo — que en banca es casi siempre.

**Cuándo no.** Flujos de dos pasos: ahí el orquestador es ceremonia.

> **💡 Truco:** la objeción "el orquestador centraliza, es un antipatrón" tiene respuesta corta:
> *centraliza la coordinación, no el dominio*. Lo que sería antipatrón es que decidiera reglas de
> negocio de los participantes, y eso se evita con una frontera explícita, no evitando el
> orquestador.

---

## 5. ⚖️ Coreografía contra orquestación

| | Coreografía | Orquestación |
|---|---|---|
| **Estado del flujo** | Repartido: nadie lo tiene | Explícito y consultable |
| **Añadir un paso** | Suscribir un consumidor | Tocar el orquestador |
| **Diagnóstico** | Reconstruir la cadena a mano | Consultar el estado |
| **Acoplamiento** | Bajo, pero implícito | Concentrado y visible |
| **Riesgo** | Ciclos y efectos inesperados | Que acumule dominio ajeno |
| **Auditoría** | Difícil: hay que unir eventos | Natural: el estado y sus transiciones |
| **Encaja con** | 2–3 pasos lineales | 4+ pasos, ramas, o auditoría |

Y la respuesta que conviene dar cuando preguntan cuál prefieres:

> "Coreografía para flujos cortos y lineales; orquestación en cuanto hay ramas, más de tres o cuatro
> pasos, o necesidad de saber en qué punto está cada caso. En banca casi siempre orquestación,
> porque el flujo hay que poder auditarlo y explicarlo."

---

## 6. 🧱 Compensaciones, que no son rollback

**Qué es.** Una operación de negocio nueva que anula el efecto de otra anterior. No borra: añade.

```text
Reserva     RESERVED   →  RELEASED   (queda registro de ambas)
Cobro       CHARGED    →  REFUNDED   (la devolución es un movimiento más)
Correo      SENT       →  ¿?         (no se puede: solo cabe enviar otro)
```

**Cómo va.** El diseño de una saga es, en buena medida, **ordenar los pasos** según su tipo:

| Tipo de paso | Qué significa | Dónde va |
|---|---|---|
| **Compensable** | Se puede anular con otra operación | Al principio |
| **Pivote** | El punto de no retorno: a partir de aquí no se compensa | En medio, y se marca |
| **Reintentable** | Tiene que acabar saliendo; solo se reintenta | Después del pivote |

Poner el cobro como pivote y dejar el envío de correos y la actualización de proyecciones como
reintentables después es lo que hace que la saga sea diseñable. Si hay dos pasos irreversibles en
medio, el flujo no tiene solución limpia y hay que renegociar el proceso con el negocio.

**Cuánto.** Cuesta que cada operación tenga su inversa implementada, probada y **visible para el
usuario**: una devolución aparece en el extracto. Y cuesta decidir qué se hace cuando la compensación
falla, que es el caso que nadie diseña.

> **⚠️ Advertencia:** la compensación también puede fallar. Si liberar la reserva da error, no hay
> nivel superior que lo arregle: hace falta reintento con backoff y, al final, **intervención
> manual**. Una saga sin bandeja de casos atascados está incompleta, y decirlo en una entrevista
> demuestra que has operado una.

---

## 7. 🧱 Las anomalías: no hay aislamiento

**Qué es.** La saga da atomicidad —todo o compensado— y durabilidad, pero **no aislamiento**: otros
ven los estados intermedios.

Tres anomalías con nombre, y su contramedida:

| Anomalía | Qué pasa | Contramedida |
|---|---|---|
| **Lectura sucia** | Alguien lee stock reservado por una saga que luego se compensa | Estado explícito: `RESERVED` es visible y distinto de `AVAILABLE` |
| **Actualización perdida** | Dos sagas modifican lo mismo y una pisa a la otra | Bloqueo semántico o control de versión optimista |
| **Lectura no repetible** | La saga lee un valor al principio y otro al final | Releer antes de decidir, o fijar el valor en el primer paso |

**Cómo va.** El **bloqueo semántico** es la contramedida más usada: marcar el registro como "en
proceso" durante la saga, de forma que otras operaciones lo vean y decidan. Es un bloqueo de
negocio, no de base de datos, y por eso hay que darle caducidad: si la saga muere, el bloqueo tiene
que expirar solo.

**Cuánto.** Cuesta modelar estados intermedios en el dominio —lo que a menudo es una mejora, porque
el negocio ya los tenía— y cuesta explicarlos a producto.

> **🧠 Modelo mental:** en una saga, los estados intermedios son **parte del modelo de negocio**, no
> un artefacto técnico. "Pedido con stock reservado pendiente de cobro" es un estado que el negocio
> entiende, y modelarlo explícitamente es lo que hace manejable todo lo demás.

---

## 8. 🧰 En las cuatro plataformas

Tres niveles de implementación, y la elección depende más del equipo que del lenguaje.

| Nivel | Qué es | Cuándo |
|---|---|---|
| **A mano** | Máquina de estados propia + outbox + consumidores | Una o dos sagas, equipo que quiere control total |
| **Con librería del ecosistema** | Abstracciones de saga o de proceso del propio marco | Ya usas ese ecosistema y su modelo encaja |
| **Con motor de workflow** | El flujo se escribe como código y el motor persiste el estado y reintenta | Muchos flujos largos, con esperas, reintentos y auditoría |

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | El ecosistema más rico: abstracciones de proceso, motores BPM maduros y muy usados en banca, y cliente de motores de workflow | Elegir nivel; y evitar que el motor se convierta en el sitio donde vive el negocio |
| **Node/TS** | Colas con reintentos y planificación para el nivel "a mano"; cliente de motor de workflow con buena ergonomía de tipos | La máquina de estados y la persistencia, si no usas motor |
| **Go** | Enrutado de mensajes con reintentos y DLQ; cliente de motor de workflow de primera | Todo el estado explícito. A cambio, se lee entero y se prueba fácil |
| **Python** | Colas de tareas con planificación y reintentos, muy rodadas; cliente de motor de workflow | Que el estado del flujo no acabe implícito en la cola de tareas |

El orquestador a mano en Java, que es el nivel que hay que saber explicar siempre:

```java
// Una fila por saga. El estado ES el flujo: si el proceso muere, se retoma desde aquí.
@Transactional
public void on(InventoryReserved event) {
    var saga = sagas.byOrder(event.orderId());
    saga.advanceTo(CONFIRMED);                   // transición válida, o excepción
    outbox.publish(new AuthorizePayment(event.orderId(), saga.total()));  // el comando sale por outbox
}

@Transactional
public void on(PaymentRejected event) {
    var saga = sagas.byOrder(event.orderId());
    saga.advanceTo(COMPENSATING);
    outbox.publish(new ReleaseInventory(saga.reservationId()));  // compensación explícita
}
```

- El estado de la saga y el mensaje saliente se escriben en la **misma transacción**, vía outbox
  ([`04`](04-outbox-inbox-e-idempotencia.md)). Sin eso, el estado avanza y el comando se pierde.
- `advanceTo` valida la transición: una máquina de estados que acepta cualquier salto acaba con sagas
  en estados imposibles y nadie sabe cómo llegaron ahí.
- No hay `try/catch` que deshaga nada: la compensación es un mensaje más, no un `rollback`.

Y en Go, el mismo flujo con el estado explícito y el plazo que lo vigila:

```go
// La saga avanza con transiciones validadas; el vencimiento la rescata si se queda parada.
func (s *Saga) On(ctx context.Context, ev Event) error {
    next, ok := transitions[s.Status][ev.Type]
    if !ok {
        return fmt.Errorf("invalid transition: %s on %s", s.Status, ev.Type) // no se ignora
    }
    s.Status = next
    s.ExpiresAt = time.Now().Add(30 * time.Minute) // sin esto, una saga parada no se detecta
    return s.saveAndPublish(ctx, commandFor(next))
}
```

- La tabla de transiciones explícita es el diseño: se lee, se prueba y se dibuja. Es la ventaja del
  nivel "a mano" frente al motor.
- `ExpiresAt` es la pieza que casi nadie implementa: un proceso periódico busca sagas vencidas y las
  compensa o las manda a revisión. **Una saga sin vencimiento se queda colgada para siempre**, y con
  ella el stock reservado.

> **🧰 Plataforma:** el motor de workflow cambia la ecuación en las cuatro por igual —el flujo se
> escribe como código y el motor persiste, reintenta y da visibilidad—, y su precio también es el
> mismo: una pieza de infraestructura más, con su propio modelo mental y su propia operación. La
> pregunta no es qué lenguaje usas, es cuántos flujos largos tienes.

---

## 9. 🩺 Autopsia: la saga que dejó el stock bloqueado

**El síntoma.** Producto agotado en la web; en la base de datos hay existencias. El stock está
reservado por sagas que nunca terminaron.

**La cadena.**

```text
orders registra → inventory reserva → payments no responde (timeout)
                                              │
                          el orquestador NO recibe respuesta
                          y no tiene vencimiento configurado
                                              ▼
                     la saga se queda en CONFIRMED para siempre
                     (y el stock, reservado con ella)
```

**La causa.** No fue el timeout de `payments`: fue que la saga **no tenía plazo propio**. El diseño
contemplaba el camino feliz y el fallo explícito, pero no el silencio.

**La corrección.** Por orden: vencimiento por saga con compensación automática; caducidad también en
la reserva —de forma que `inventory` libere por su cuenta lo que nadie confirmó—; y una bandeja de
sagas vencidas con alerta. Defensa en dos capas, porque cada una cubre un fallo distinto.

**La generalización.** Todo estado intermedio necesita una salida por tiempo. En un flujo
distribuido, **la ausencia de respuesta es el caso más probable**, y es el que menos se diseña.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La saga es una transacción distribuida" | Da atomicidad y durabilidad, no aislamiento. Los estados intermedios son visibles y hay que modelarlos |
| "Compensar es hacer rollback" | Es una operación de negocio nueva y visible: una devolución aparece en el extracto |
| "Con coreografía no hay acoplamiento" | El acoplamiento existe y es implícito: está repartido en quién reacciona a qué, y por eso es peor de diagnosticar |
| "El orquestador es un antipatrón porque centraliza" | Centraliza la coordinación, no el dominio. El antipatrón es que decida reglas de los participantes |
| "Si falla la compensación, se reintenta y ya" | Hasta un límite. Después hace falta bandeja de casos atascados e intervención manual |
| "El flujo termina cuando falla, y se compensa todo" | Solo hasta el pivote. Después del punto de no retorno solo caben pasos reintentables |
| "Con un motor de workflow no hace falta pensar el diseño" | El motor persiste y reintenta; el orden de los pasos, las compensaciones y los vencimientos los diseñas igual |

---

## 📚 Para profundizar

1. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 4, "Managing
   transactions with sagas": coreografía, orquestación y las contramedidas de aislamiento. **El
   capítulo imprescindible de este tema.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 6, con el
   tratamiento de sagas y su comparación con las transacciones distribuidas.
3. **Artículo fundacional** — Hector Garcia-Molina y Kenneth Salem, «Sagas», ACM SIGMOD, 1987. De ahí
   vienen los términos y la idea de compensación; se cita por su ficha.
4. **Fuente primaria** — Chris Richardson, «Pattern: Saga», con las contramedidas de aislamiento
   enumeradas:
   [microservices.io/patterns/data/saga.html](https://microservices.io/patterns/data/saga.html).
5. **Documentación** — Temporal, casos de uso y patrones de diseño, para el nivel "motor de
   workflow":
   [docs.temporal.io/evaluate/use-cases-design-patterns](https://docs.temporal.io/evaluate/use-cases-design-patterns).
6. **Documentación** — Camunda, eventos de compensación en BPMN, para el enfoque BPM que predomina
   en banca:
   [docs.camunda.io/docs/components/modeler/bpmn/compensation-events/](https://docs.camunda.io/docs/components/modeler/bpmn/compensation-events/).
7. **Charla** — GOTO Conferences, «Saga Patterns» / «Long-Running Processes». Útil por los ejemplos
   de compensaciones que no se pueden compensar.

---

## 🧠 Preguntas

1. ¿Qué es una saga y qué garantía da que no da una transacción? 🟢
2. ¿Qué garantía *no* da una saga? 🟢
3. Diferencia entre coreografía y orquestación. 🟢
4. ¿Qué es una compensación y en qué se diferencia de un rollback? 🟢
5. Enumera los tres tipos de paso de una saga y dónde va cada uno. 🟢
6. Nombra dos razones por las que 2PC no se usa entre microservicios. 🟢
7. ¿Por qué la coreografía se vuelve inmanejable a partir de cuatro pasos? 🟡
8. ¿Qué es el paso pivote y por qué su posición es una decisión de diseño? 🟡
9. ¿Qué es el bloqueo semántico y por qué necesita caducidad? 🟡
10. ¿Por qué el estado de la saga y el comando saliente tienen que ir en la misma transacción? 🟡
11. ¿Qué significa que "no hay aislamiento" en términos de lo que ve otro servicio? 🟡
12. ¿Qué tres niveles de implementación de saga hay, y cómo se reparten entre las cuatro
    plataformas? 🟡
13. ¿Cómo cambia la comparación entre plataformas cuando se usa un motor de workflow? 🟡
14. ¿Por qué una operación irreversible en medio del flujo obliga a renegociar el proceso? 🟠
15. Tu saga se queda parada porque `payments` no responde ni bien ni mal. ¿Qué falta en el diseño? 🟠
16. ¿Dónde pondrías el paso pivote en la saga del capítulo y por qué? 🟠
17. La compensación falla tres veces. ¿Qué haces? 🟠
18. ¿Cómo evitas que el orquestador acumule reglas de negocio de los participantes? 🟠
19. ¿Cuándo usarías un motor de workflow en vez de una máquina de estados propia? 🟠
20. Diseña la contramedida para dos sagas que intentan reservar el mismo último producto. 🟠
21. ¿Cómo explicarías a producto que existe un estado "reservado pero no pagado"? 🟠
22. ¿Qué monitorizarías de una saga para enterarte antes que el cliente? 🟠
23. Diseña la saga completa del pedido: pasos, tipos, compensaciones, estados, vencimientos y qué se
    audita. 🔴
24. Rediseña la misma saga en coreografía y di qué pierdes y qué ganas respecto a la orquestada. 🔴
25. Diagnostica: hay stock reservado que no corresponde a ningún pedido activo. Da tres hipótesis y
    el plan de corrección. 🔴
26. Un flujo tiene dos pasos irreversibles: cobrar y enviar un correo al cliente. Diseña el flujo de
    forma que siga siendo manejable. 🔴

---

**Anterior:** [`02` — Consultas entre servicios](02-consultas-entre-servicios.md) · **Siguiente:**
[`04` — Outbox, inbox e idempotencia](04-outbox-inbox-e-idempotencia.md) · **Relacionado:**
[`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) ·
[`arquitectura/01-bases/02-eventos/05`](../../01-bases/02-eventos/05-saga.md)

**Talleres, opcionales:** [`06/08` — Saga coreografiada](../06-talleres/08-saga-coreografiada.md) · [`06/09` — Saga orquestada, comparación y autopsia](../06-talleres/09-saga-orquestada.md).
