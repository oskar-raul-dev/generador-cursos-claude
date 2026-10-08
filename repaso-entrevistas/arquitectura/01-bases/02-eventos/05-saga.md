# 05 — Saga

> Cómo se mantiene la consistencia entre servicios cuando ya no hay transacción que los
> cruce. Coreografía contra orquestación, compensación contra rollback, y los tres
> problemas que nadie menciona: la lectura sucia, la actualización perdida y el paso que no
> se puede deshacer.
> Asume leído [`03` — Garantías, orden e idempotencia](03-garantias-orden-e-idempotencia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Reservar un vuelo toca tres servicios con tres bases de datos: asiento, equipaje y cobro.
En un monolito esto era una línea:

```java
@Transactional
void reservar(Reserva r) {
    asientos.reservar(r);  equipajes.reservar(r);  pagos.cobrar(r);
}  // si algo falla, rollback de todo. Gratis.
```

Separados, esa garantía desaparece. Y la salida obvia —una transacción distribuida con
dos fases— no sirve, por tres razones que conviene tener listas:

- **Bloquea recursos durante toda la operación.** Si el cobro tarda cuatro segundos, el
  asiento está bloqueado cuatro segundos, y con volumen eso es contención masiva.
- **El coordinador es un punto único de fallo.** Si muere entre la fase de preparación y la
  de commit, los participantes quedan bloqueados esperando.
- **La mitad de tus dependencias no lo soportan.** Kafka no, las APIs de terceros tampoco,
  ninguna base de datos NoSQL moderna.

> **Regla:** en distribuido no hay rollback, hay **compensación**. No deshaces lo que
> pasó: haces algo nuevo que lo contrarresta, y eso queda registrado.

---

## 2. 🔗 Qué es una saga

**Qué es.** Una secuencia de transacciones locales, cada una en un servicio y cada una con
commit propio. Si un paso falla, se ejecutan las **compensaciones** de los pasos ya
completados, en orden inverso.

```text
T1 asiento → T2 equipaje → T3 cobro → T4 confirmar
                  ↓ falla
            C2 liberar equipaje → C1 liberar asiento
```

- **Cada `Tn` commitea de verdad.** No hay "preparado pendiente de confirmar": el asiento
  queda reservado y visible para todos.
- **Cada `Cn` es una operación de negocio con nombre propio**, no un `UPDATE` inverso.
  Compensar un cobro es **reembolsar**, y el reembolso aparece en el extracto.
- La saga no es atómica: es **eventualmente consistente**, y durante la ventana el sistema
  está en un estado intermedio observable.

**Cuándo sí.** Cuando una operación de negocio cruza servicios con datos propios y necesitas
que acabe consistente.

**Cuándo no.** Cuando puedes evitarla. Y se evita más de lo que parece: si dos pasos
siempre van juntos y siempre fallan juntos, **quizá pertenecían al mismo agregado o al
mismo servicio**. La saga más barata es la que no existe.

> **Veredicto:** la saga es el precio de "base de datos por servicio". Antes de diseñar una,
> pregúntate si la frontera estaba bien puesta — porque una saga de seis pasos suele ser el
> síntoma de un corte equivocado.

---

## 3. 💃 Coreografía

**Qué es.** No hay director. Cada servicio escucha eventos y publica los suyos; el flujo
emerge de la suma.

```text
Pedidos ─PedidoCreado→ Inventario ─StockReservado→ Pagos ─PagoConfirmado→ Pedidos
                            ↑                         │
                            └──StockLiberado←─────────┘ (si el pago falla)
```

- Acoplamiento bajo: cada servicio solo conoce los eventos que consume y los que publica.
- Añadir un participante no toca a los demás: escucha y ya.

**El problema, y es grande.** **El flujo no existe en ningún sitio.** No hay archivo,
clase ni diagrama generado que lo describa: está repartido en seis `@KafkaListener`. Para
saber por qué una reserva quedó a medias hay que reconstruir mentalmente la cadena. Y con
más de tres o cuatro pasos, nadie la tiene entera en la cabeza.

Además aparece el **acoplamiento cíclico**: `Pedidos` publica, `Inventario` reacciona,
`Pedidos` vuelve a reaccionar. Los ciclos son difíciles de razonar y peores de depurar.

**Cuándo sí.** Dos o tres pasos, sin compensaciones complejas, participantes que ya
existen y son autónomos.

**Cuándo no.** Cuando hay que compensar, cuando alguien va a preguntar "¿en qué punto está
mi reserva?", o cuando el flujo pasa de cuatro pasos.

> **Veredicto:** la coreografía es más elegante sobre el papel y más cara en producción.
> Su coste no es técnico, es cognitivo, y lo pagas cada vez que hay un incidente.

---

## 4. 🎼 Orquestación

**Qué es.** Un componente —el orquestador— conoce el flujo completo, envía **comandos** a
los participantes y reacciona a sus respuestas. El flujo vive en un sitio y se puede leer.

```text
                 ┌──────────────────┐
                 │  SagaDeReserva   │  ← el flujo está AQUÍ, en una máquina de estados
                 └──────────────────┘
   reservarAsiento│  reservarEquipaje│  cobrar│
                  ▼                  ▼        ▼
              Asientos           Equipajes   Pagos
```

- **El orquestador es un agregado con estado**, no un servicio sin memoria: persiste en qué
  paso va cada saga, para sobrevivir a su propio reinicio.
- Envía **comandos** (`ReservarAsiento`), no eventos. Es acoplamiento estructural
  deliberado: el orquestador sabe a quién llama, y por eso puede compensar.
- El estado de una saga es **consultable**: *"tu reserva está en 'cobrando'"* es una
  respuesta que la coreografía no puede dar.

**El precio:** un componente más que mantener, y un punto que concentra conocimiento del
negocio. Si el orquestador acumula reglas que pertenecen a los participantes, se convierte
en el ESB de [`01-bases/02`](../01-bases/02-estilos-de-despliegue.md#6--soa-y-el-esb) con
otro nombre.

**Cuándo sí.** Más de tres pasos, compensaciones, dinero de por medio, o necesidad de
consultar el estado. En banca es casi siempre la respuesta.

**Cuándo no.** Flujos de dos pasos sin compensación: ahí el orquestador es ceremonia.

> ⚠️ **Advertencia.** El orquestador coordina; **no decide reglas de negocio ajenas**. Si
> empieza a validar cosas que sabe el participante, has centralizado la inteligencia y roto
> *smart endpoints, dumb pipes*.

> **Veredicto:** orquestación por defecto en cuanto hay dinero o compensaciones. La
> coreografía se gana el sitio en flujos cortos, no al revés.

---

## 5. ⚖️ La comparación que se pregunta

| | Coreografía | Orquestación |
|---|---|---|
| Dónde está el flujo | En ningún sitio: repartido | En el orquestador, legible |
| Acoplamiento | Bajo (eventos) | Mayor (comandos dirigidos) |
| Consultar estado | ❌ Difícil | ✅ Es un campo |
| Compensar | Difícil: ¿quién ordena? | Natural: el orquestador sabe qué pasó |
| Añadir un paso | Toca dos servicios | Toca el orquestador |
| Depurar un incidente | Arqueología entre logs | Leer el estado de la saga |
| Punto único de fallo | No | El orquestador (mitigable con persistencia) |
| Escala bien hasta | 3–4 pasos | Los que haga falta |

---

## 6. ↩️ Compensación: lo que de verdad cuesta

**Qué es.** La operación de negocio que contrarresta a otra. Y tiene cuatro propiedades que
la separan de un rollback, todas preguntables:

**1. No es simétrica.** Compensar "cobrar 100" no es "borrar el cobro": es "reembolsar
100", que genera su propio movimiento, su propia comisión y su propia entrada en el
extracto. El cliente ve las dos.

**2. Puede fallar.** ¿Y si el reembolso falla? Necesitas reintento con idempotencia y, si
se agota, **intervención humana**. Una saga que asume compensaciones infalibles está mal
diseñada.

**3. Hay pasos que no se pueden compensar.** Un correo enviado no se desenvía. Una llamada
a un tercero que ya ejecutó, tampoco. De ahí la regla de ordenación más útil del capítulo:

```text
Ordena los pasos así:
  1. Los compensables       (reservar, bloquear, apuntar)
  2. El pivote              (el que decide: el cobro. Antes se puede volver, después no)
  3. Los no compensables    (enviar correo, notificar a terceros, imprimir)
```

- Todo lo irreversible va **después** del pivote, cuando ya sabes que la saga va a salir.
- Si un paso irreversible tiene que ir antes, conviértelo en compensable: en vez de enviar
  el correo, **encólalo** y confírmalo después.

**4. La ventana es visible.** Entre `T1` y la compensación, el asiento **está reservado
para todos**. Eso no es un detalle de implementación: es lo que ve el usuario.

> **Veredicto:** el diseño de una saga es el diseño de sus compensaciones y de su orden.
> Los pasos felices se escriben solos; lo que se evalúa en entrevista es lo otro.

---

## 7. 🕳️ Los tres problemas de aislamiento

**Qué es.** Una saga no tiene la *I* de ACID. Los pasos intermedios son visibles, y de ahí
salen tres anomalías con nombre propio que casi nadie menciona — y que son la mejor
pregunta de seguimiento que te pueden hacer.

**Lectura sucia.** Otro proceso lee un dato de un paso que luego se compensa: ve una
reserva que dejará de existir, o un saldo descontado que se devolverá.

**Actualización perdida.** Otra saga modifica el mismo dato mientras la primera está a
medias, y la compensación pisa ese cambio.

**Lectura no repetible.** La saga lee el mismo dato dos veces y obtiene valores distintos,
porque alguien lo cambió entre medias.

**Las contramedidas**, que es lo que hay que saber nombrar:

```text
Semántica de bloqueo → marcar el registro como "en trámite" y que nadie más lo toque
Registro conmutativo → usar operaciones que dan igual en cualquier orden (sumar, no fijar)
Fichero pesimista    → reordenar los pasos para que el más peligroso vaya al final
Relectura            → releer y verificar que no cambió antes de actuar
Valor por versión    → guardar la versión y rechazar si no coincide
Por valor            → usar transacción real para los pocos casos que no admiten nada de esto
```

- La primera es la más usada: un estado `RESERVADO` que caduca solo, con TTL.
- **El TTL es la red de seguridad de toda saga**: si el orquestador muere y nunca compensa,
  la reserva expira sola. Sin él, un fallo del orquestador deja recursos bloqueados para
  siempre.

> 🧠 **Modelo mental.** Una saga cambia la *I* de ACID por trabajo tuyo. Todo lo que la base
> de datos hacía gratis con bloqueos, ahora lo modelas explícitamente en el dominio.

> **Veredicto:** nombrar la lectura sucia y el TTL de las reservas es lo que separa a quien
> ha diseñado una saga de quien leyó el patrón.

---

## 8. 🧭 Cómo se elige

```text
¿Puedo evitar la saga?
    ¿Los pasos siempre van juntos y fallan juntos?  → quizá era UN servicio. Revisa la frontera.
    ¿El segundo paso puede ser eventual y nadie espera? → evento simple, sin saga.

Si la necesito:
    ¿Más de 3 pasos, hay compensaciones o hay dinero?  → ORQUESTACIÓN
    ¿2–3 pasos, sin compensar, participantes autónomos? → coreografía
    ¿Alguien va a preguntar "¿en qué punto está lo mío?"? → orquestación, sin dudarlo

Y en cualquier caso, lo que no es negociable:
    Cada paso, idempotente             (la entrega es at-least-once)
    Cada reserva, con TTL              (por si el orquestador muere)
    Los pasos irreversibles, DESPUÉS del pivote
    El estado, persistido              (para sobrevivir al reinicio)
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La saga hace rollback" | No: compensa con una operación nueva, que queda registrada |
| "Compensar un cobro es borrarlo" | Es reembolsar: genera movimiento, comisión y entrada en el extracto |
| "La coreografía es mejor, acopla menos" | Acopla menos y cuesta más: el flujo no existe en ningún sitio |
| "Uso 2PC entre microservicios" | Bloquea, tiene punto único de fallo y la mitad de tus dependencias no lo soportan |
| "Si el orquestador muere, compensamos al volver" | Solo si el estado está persistido **y** las reservas tienen TTL |
| "Las compensaciones no fallan" | Fallan; necesitan reintento idempotente y, al agotarse, un humano |
| "La saga es atómica" | Es eventualmente consistente, y el estado intermedio es visible |

---

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 4
  completo: sagas, coreografía contra orquestación y los tres problemas de aislamiento con
  sus contramedidas. **Es el libro de este capítulo.**
- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulo 6:
  transacciones distribuidas y por qué 2PC no es la respuesta.
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulo 13: flujos de trabajo dirigidos por eventos.
- [microservices.io — Pattern: Saga](https://microservices.io/patterns/data/saga.html): la
  ficha canónica, con el ejemplo de coreografía y el de orquestación enfrentados.
- [microservices.io — Database per service](https://microservices.io/patterns/data/database-per-service.html):
  el patrón que **causa** la necesidad de saga, con sus fuerzas.
- [Camunda — Workflow patterns](https://docs.camunda.io/docs/components/concepts/workflow-patterns/):
  cómo se ve una orquestación cuando la hace un motor en vez de tu código; se amplía en
  [`05-banca`](../05-banca/).
- **Video** — GOTO Conferences, charlas de Chris Richardson sobre sagas y gestión de datos
  distribuidos. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es una saga? 🟢
2. ¿Qué diferencia hay entre coreografía y orquestación? 🟢
3. ¿Qué es una compensación? 🟢
4. Nombra los tres problemas de aislamiento de una saga. 🟢
5. ¿Por qué no se usa 2PC entre microservicios? 🟡
6. ¿Por qué una compensación no es un rollback? 🟡
7. ¿Qué es el pivote de una saga? 🟡
8. ¿Por qué el orquestador tiene que persistir su estado? 🟡
9. ¿Qué envía un orquestador: comandos o eventos? ¿Y por qué importa? 🟡
10. ¿Qué es la semántica de bloqueo como contramedida? 🟡
11. ¿Por qué toda reserva de una saga necesita TTL? 🟠
12. ¿Cuál es el coste real de la coreografía y por qué no es técnico? 🟠
13. ¿Cómo ordenas los pasos de una saga y por qué ese orden? 🟠
14. ¿Qué haces con un paso que no se puede compensar? 🟠
15. ¿Qué pasa si una compensación falla? 🟠
16. ¿Cuándo una saga es el síntoma de una frontera mal puesta? 🟠
17. ¿Por qué la coreografía no puede responder "¿en qué punto va mi pedido?"? 🟠
18. ¿Cuándo un orquestador se convierte en un ESB? 🟠
19. ¿Qué ve el usuario durante la ventana entre un paso y su compensación? 🟠
20. Diseña la saga de reserva de vuelo —asiento, equipaje, cobro—: pasos,
    compensaciones, pivote, y qué pasa en cada punto de fallo. 🔴
21. El orquestador murió con 200 sagas a medias. Describe qué pasa al
    reiniciarlo y qué tuvo que estar diseñado de antemano. 🔴
22. Dos sagas concurrentes tocan la misma cuenta y una compensación pisa el
    cambio de la otra. Diagnostica y propón dos contramedidas. 🔴
23. Te piden convertir una saga coreografiada de 6 pasos a orquestada sin
    detener el negocio. ¿Cómo lo haces? 🔴

---

**Anterior:** [`04` — Colas, DLQ y reintentos](04-colas-dlq-y-reintentos.md) ·
**Siguiente:** [`06` — Outbox y CDC](06-outbox-y-cdc.md) ·
**Relacionado:** [`01-bases/07` — DDD táctico](../01-bases/07-ddd-tactico.md)
