# 06 — Outbox y CDC

> El problema de la doble escritura: cómo garantizar que el cambio en la base de datos y el
> evento publicado ocurren los dos o ninguno, sin transacción distribuida. Es el patrón más
> útil de todo el bloque y el que más veces resuelve una entrevista.
> Asume leído [`05` — Saga](05-saga.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Este código está mal, lo ha escrito todo el mundo, y parece correcto:

```java
@Transactional
public void confirmar(PedidoId id) {
    Pedido pedido = repositorio.porId(id).orElseThrow();
    pedido.confirmar();                                   // 1. cambio en la BD
    kafka.send("pedidos", new PedidoConfirmado(id));      // 2. publicación al broker
}
```

- La línea 1 está dentro de la transacción; **la línea 2 no**, porque Kafka no participa en
  ella. Son dos sistemas y dos commits.
- Si el broker está caído, el `send` lanza y la transacción hace rollback: el pedido no se
  confirma. Es el caso **menos malo**, y aun así significa que la caída de Kafka te impide
  operar.
- Si el `send` tiene éxito y el commit falla después, **publicaste un evento de algo que no
  pasó**. Facturación emite una factura de un pedido inexistente.
- Y si inviertes el orden, el problema se invierte: commit y luego `send`; si el proceso
  muere entre medias, **el pedido está confirmado y nadie se enteró**.

```text
BD ✅ + broker ❌ → el mundo no se entera. Silencioso y frecuente.
BD ❌ + broker ✅ → el mundo cree algo falso. Raro y peor.
```

> **Regla importante:** no hay orden de las dos líneas que sea correcto. **El problema no
> es el orden: es que son dos sistemas.** Cualquier solución pasa por reducirlos a uno.

---

## 2. 📮 El patrón outbox

**Qué es.** En vez de publicar, **escribes el evento en una tabla de tu propia base de
datos, dentro de la misma transacción**. Un proceso aparte lee esa tabla y publica.

```text
┌─ transacción única ─────────────────┐
│  UPDATE pedidos SET estado='CONF'   │   un solo sistema → atómico de verdad
│  INSERT INTO outbox (evento, ...)   │
└─────────────────────────────────────┘
                 │
          relay (proceso aparte)
                 │
                 ▼
              broker  ──► consumidores
```

- **La atomicidad es real y gratis**: dos escrituras en la misma base de datos, un solo
  commit. No hay coordinador, no hay XA.
- **El evento no se pierde nunca**: si el relay está caído, la fila espera en la tabla.
- **El relay puede publicar dos veces** —si muere después de publicar y antes de marcar la
  fila—, así que la entrega sigue siendo at-least-once y **los consumidores siguen
  necesitando ser idempotentes**. El outbox resuelve la pérdida, no el duplicado.

La tabla mínima, y cada columna está por una razón:

```sql
CREATE TABLE outbox (
  id            UUID PRIMARY KEY,      -- es el id del mensaje: sirve de clave de dedupe
  agregado_tipo VARCHAR(64),           -- 'Pedido'
  agregado_id   VARCHAR(64),           -- clave de partición: garantiza orden por entidad
  tipo          VARCHAR(64),           -- 'PedidoConfirmado'
  payload       JSONB,                 -- el evento de integración ya serializado
  creado_en     TIMESTAMPTZ,           -- para ordenar y para medir el retardo del relay
  publicado_en  TIMESTAMPTZ            -- NULL = pendiente
);
```

- `agregado_id` como clave de partición es lo que conserva el **orden por entidad** en
  Kafka. Sin esa columna, el orden se pierde.
- `creado_en` es lo que permite medir el **lag del relay**, que es la métrica de salud del
  patrón.
- `publicado_en` en vez de borrar la fila deja rastro para auditar. Con volumen alto se
  borra o se particiona, y se declara.

**Cuándo sí.** Siempre que un cambio de estado tenga que producir un evento que otros
consumen. Es el valor por defecto.

**Cuándo no.** Cuando el evento es prescindible —telemetría, métricas— y no vale la tabla
extra. Y cuando no tienes base de datos transaccional en ese servicio.

> **Veredicto:** el outbox es el patrón con mejor relación valor/complejidad de todo el
> bloque. Cuesta una tabla y un proceso, y elimina la clase entera de bugs de "el evento no
> salió".

---

## 3. 🚚 Las dos formas de mover la tabla al broker

**Qué es.** El relay se puede implementar de dos maneras, y elegir entre ellas es la
segunda decisión del patrón.

**1. Polling publisher.** Un proceso consulta la tabla cada N milisegundos, publica y marca.

```sql
SELECT * FROM outbox WHERE publicado_en IS NULL
ORDER BY creado_en LIMIT 100
FOR UPDATE SKIP LOCKED;     -- varias instancias sin pisarse
```

- `FOR UPDATE SKIP LOCKED` es lo que hace esto seguro con varias instancias: cada una toma
  filas distintas sin bloquearse entre sí. Sin él, o duplicas o serializas.
- Simple, sin dependencias nuevas, depurable con un `SELECT`.
- Precio: latencia igual al intervalo de sondeo, y carga constante sobre la base de datos
  aunque no haya nada que publicar.

**2. Change Data Capture (CDC).** Un componente —Debezium es el estándar— lee el **log de
transacciones** de la base de datos (el WAL de Postgres, el binlog de MySQL) y publica los
cambios.

- Latencia de milisegundos, cero carga de consulta sobre la base de datos.
- Captura **lo que realmente se commiteó**, en orden de commit: es la fuente de verdad más
  fiable que existe.
- Precio: un sistema distribuido más que operar (Debezium sobre Kafka Connect), permisos de
  replicación en la base de datos, y una dependencia fuerte del motor concreto.

| | Polling | CDC |
|---|---|---|
| Latencia | El intervalo (100 ms – 5 s) | Milisegundos |
| Carga en la BD | Consulta constante | Lectura del log, mínima |
| Operación | Ninguna: es tu código | Debezium + Kafka Connect |
| Depuración | Un `SELECT` | Herramientas propias |
| Acoplamiento al motor | Bajo | Alto |

**Cuándo sí polling.** La mayoría de los casos. Si un segundo de retardo es tolerable —y
casi siempre lo es—, no añadas Debezium.

**Cuándo sí CDC.** Volumen alto, latencia estricta, o **cuando ya tienes Debezium** para
otra cosa. También es la vía para capturar cambios de un sistema legado que no puedes
modificar, que es su caso estrella en banca.

> **Veredicto:** empieza por polling. Es aburrido, funciona y lo depura cualquiera. CDC se
> gana el sitio cuando el polling deja de dar la latencia o cuando el legado no te deja
> escribir una tabla de outbox.

---

## 4. 🪞 CDC sin outbox: el antipatrón cómodo

**Qué es.** Usar CDC directamente sobre las **tablas de negocio**, sin tabla de outbox, y
publicar los cambios de fila como eventos.

**Por qué tienta.** Cero código: Debezium ya emite `pedidos.UPDATE` con el antes y el
después. Parece que te ahorras la tabla.

**Por qué está mal**, y esto es lo que hay que saber decir:

- **Publicas tu esquema, no tus eventos.** Los consumidores acaban dependiendo de tus
  nombres de columna. Renombrar `estado` a `situacion` rompe a tres equipos. Es el error de
  [`01` §3](01-fundamentos-eda.md#3--evento-de-dominio-y-evento-de-integración) en su
  versión más severa.
- **Pierdes la intención.** Un `UPDATE` que cambia `estado` de `PAGADO` a `ENVIADO` no
  dice si fue un envío normal, una corrección manual o una migración. El evento
  `PedidoEnviado` sí lo dice.
- **No puedes emitir lo que no es una fila.** `LimiteDeCreditoSuperado` no corresponde a
  ningún cambio de columna.

**Cuándo sí.** Para **replicar datos** —alimentar un almacén analítico, sincronizar una
réplica de lectura, migrar—, no para integrar dominios. Ahí es la herramienta correcta.

**Cuándo no.** Como sustituto de eventos de integración entre contextos.

> **Veredicto:** CDC sobre tablas de negocio es excelente para mover datos y pésimo para
> comunicar significado. La combinación buena es **CDC sobre la tabla de outbox**: la
> latencia del CDC con el contrato explícito del outbox.

---

## 5. 📥 El inbox: el espejo del outbox

**Qué es.** El mismo patrón en el lado del consumidor. Al recibir un mensaje, escribes su
identificador en una tabla `inbox` **en la misma transacción** que el efecto.

```java
@Transactional
public void alRecibir(PedidoConfirmado evento, String idMensaje) {
    if (inbox.yaProcesado(idMensaje)) return;    // duplicado: no hace nada
    inbox.registrar(idMensaje);                  // ambas escrituras,
    facturas.emitir(evento);                     // la misma transacción
}
```

- Es la implementación concreta de la regla de
  [`03` §5](03-garantias-orden-e-idempotencia.md#5-️-la-deduplicación-debe-ser-atómica-con-el-efecto):
  la marca y el efecto comparten commit.
- El `id` del mensaje puede ser el `id` de la fila del outbox del emisor: viaja en una
  cabecera y cierra el circuito de extremo a extremo.
- Necesita **limpieza**: una tabla `inbox` que crece sin parar acaba siendo el problema. Se
  purga por antigüedad, con un margen mayor que la retención del broker.

**Cuándo sí.** Cuando el efecto es una escritura en tu base de datos y no puedes hacerlo
idempotente por otra vía.

**Cuándo no.** Cuando la operación ya es naturalmente idempotente —fijar un valor,
insertar con clave única de negocio—: ahí el inbox es una tabla que no compra nada.

> **Veredicto:** outbox e inbox juntos dan *effectively-once* de extremo a extremo sin
> transacción distribuida. Es lo que sustituyó a XA, y saber decirlo con esas palabras
> cierra la pregunta.

---

## 6. 🩺 Operar el patrón

**Qué es.** Lo que hay que medir, porque un outbox mal vigilado falla en silencio.

| Métrica | Qué significa | Cuándo alerta |
|---|---|---|
| Filas pendientes | Tamaño de la cola interna | Crece sin bajar |
| Antigüedad de la más vieja | El lag real del relay | Supera el objetivo (p. ej. 10 s) |
| Tasa de publicación | Salud del relay | Cae a cero con filas pendientes |
| Errores del relay | Broker caído o payload inválido | Cualquier ráfaga |

- **La métrica que importa es la antigüedad de la fila más vieja**, no el número de filas.
  Mil filas publicándose rápido está bien; una fila de hace diez minutos es un incidente.
- Si el relay muere y nadie mira, **el sistema sigue aceptando escrituras con normalidad**
  y los eventos se acumulan invisibles. Es el modo de fallo característico del patrón.

> 🩺 **Diagnóstico.** "Facturación no recibe eventos": mira primero la tabla de outbox. Si
> hay filas pendientes, el problema es el relay y el evento está a salvo. Si está vacía,
> el evento nunca se escribió y el problema está en el productor.

> **Veredicto:** el outbox convierte un fallo silencioso e irrecuperable —evento perdido—
> en uno visible y recuperable —fila pendiente—. Esa conversión **es** el valor del patrón.

---

## 7. 🧭 Cómo se elige

```text
¿Un cambio de estado tiene que producir un evento que otros consumen?
    → Outbox. Por defecto, sin discusión.

¿Cómo lo muevo al broker?
    ¿Tolero 1 segundo de retardo?            → polling con FOR UPDATE SKIP LOCKED
    ¿Necesito milisegundos, o ya tengo CDC?  → Debezium sobre la tabla de outbox
    ¿Es un legado donde no puedo escribir?   → CDC sobre las tablas, y traduzco a eventos
                                               de integración en un adaptador aparte

¿El consumidor escribe en su base de datos al procesar?
    → Inbox, en la misma transacción que el efecto.
    ¿La operación ya es idempotente por naturaleza? → sin inbox, no compra nada.

¿Qué mido?
    → La antigüedad de la fila pendiente más vieja. Todo lo demás es secundario.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Publico dentro de `@Transactional` y ya" | El broker no participa en la transacción: son dos sistemas |
| "Commiteo y luego publico" | Si el proceso muere entre medias, el evento se pierde en silencio |
| "El outbox da exactly-once" | Elimina la **pérdida**; el duplicado sigue, y el consumidor debe ser idempotente |
| "Uso CDC sobre mis tablas como eventos" | Publicas tu esquema y pierdes la intención; sirve para replicar, no para integrar |
| "El relay con varias instancias duplica" | No, si usas `FOR UPDATE SKIP LOCKED` |
| "Alerto cuando hay muchas filas pendientes" | Alerta por **antigüedad** de la más vieja, no por cantidad |
| "Con outbox ya no necesito el inbox" | Son los dos extremos: uno evita perder, el otro evita duplicar |

---

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 3,
  sección sobre publicación fiable de eventos: outbox, polling publisher y tailing del log
  de transacciones. **Es el libro de este capítulo.**
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulo 4: producción de eventos desde el estado, con outbox y CDC comparados.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11, sección "Change Data Capture": por qué el log de transacciones es la fuente
  de verdad más fiable de un sistema.
- [microservices.io — Transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html):
  la ficha canónica del patrón, con sus dos variantes de relay.
- [Debezium — Architecture](https://debezium.io/documentation/reference/stable/architecture.html):
  cómo funciona CDC por dentro y qué exige de la base de datos.
- [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html):
  el contexto que hace correcto el `SELECT ... FOR UPDATE SKIP LOCKED` del relay.
- **Video** — Devoxx y GOTO Conferences, charlas de Gunnar Morling sobre Debezium y el
  patrón outbox. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es el problema de la doble escritura? 🟢
2. ¿Qué es el patrón outbox? 🟢
3. ¿Qué es CDC? 🟢
4. ¿Qué es el patrón inbox? 🟢
5. ¿Por qué publicar dentro de `@Transactional` no es atómico? 🟡
6. ¿Por qué no hay un orden correcto entre commitear y publicar? 🟡
7. ¿Qué garantiza el outbox y qué **no** garantiza? 🟡
8. ¿Para qué sirve la columna `agregado_id` en la tabla de outbox? 🟡
9. ¿Qué hace `FOR UPDATE SKIP LOCKED` en el relay? 🟡
10. ¿Qué diferencias hay entre polling y CDC como relay? 🟡
11. ¿Por qué el inbox debe escribirse en la misma transacción que el efecto? 🟡
12. ¿Por qué CDC sobre tablas de negocio es un antipatrón para integrar? 🟠
13. ¿Para qué **sí** sirve CDC sobre tablas de negocio? 🟠
14. ¿Qué métrica es la que de verdad indica la salud de un outbox? 🟠
15. ¿Cuál es el modo de fallo silencioso característico del outbox? 🟠
16. ¿Cuándo el inbox no compra nada? 🟠
17. ¿Cómo se conserva el orden por entidad con un outbox? 🟠
18. ¿Por qué el outbox sustituyó a las transacciones XA? 🟠
19. ¿Qué haces si el legado no te deja escribir una tabla de outbox? 🟠
20. "Facturación no recibe eventos." Describe el orden en que investigas y qué
    te dice cada hallazgo. 🔴
21. Diseña el outbox completo para `PedidoConfirmado`: tabla, transacción,
    relay, métricas y qué pasa en cada punto de fallo. 🔴
22. Tras un incidente del broker hay 80.000 filas pendientes en el outbox.
    ¿Qué pasa al recuperarse y qué habría que haber previsto? 🔴
23. Te piden CDC directo sobre las tablas "porque es más rápido de implementar".
    Argumenta en contra y propón la alternativa. 🔴

---

**Anterior:** [`05` — Saga](05-saga.md) ·
**Siguiente:** [`07` — Event sourcing](07-event-sourcing.md) ·
**Relacionado:** [`03` — Garantías](03-garantias-orden-e-idempotencia.md)
