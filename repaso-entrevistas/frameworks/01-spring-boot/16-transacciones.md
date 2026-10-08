# 16 — Transacciones

> **Objetivo:** predecir si habrá rollback **antes** de ejecutar, saber en qué conexión
> está cada cosa, y reconocer de memoria los seis casos en los que `@Transactional` no
> hace lo que crees y no te avisa.
> **Asume:** [`05`](05-proxies-y-aop.md) —sin él este capítulo no se entiende— y [`15`](15-datos-jdbc-jpa-mongo-y-redis.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: dos escrituras que tienen que ser una

Registras un movimiento de inventario: insertas una fila en `inventory_event` y actualizas
la cantidad en `inventory_item`. Si la segunda falla, la primera **no puede quedarse**, o
tu inventario dice que salieron cien unidades que siguen contadas en el stock.

Eso lo resuelve la base de datos con una transacción. Lo que resuelve Spring es otra cosa,
y conviene separarlas desde el primer párrafo:

```text
la base de datos      → garantiza atomicidad, aislamiento y durabilidad
Spring                → decide CUÁNDO empiezan y terminan, y en QUÉ conexión
```

Spring no implementa transacciones. Implementa **una política declarativa** sobre las
transacciones de tu base, y casi todos los bugs de este capítulo salen de confundir las
dos cosas.

---

## 2. 🧱 El modelo, y quién lo invoca

```text
@Transactional          un metadato en un método
      │
      ▼
proxy (05)              ← lo lee, y si la llamada viene de FUERA del bean…
      │
      ▼
PlatformTransactionManager   pide la conexión, hace begin / commit / rollback
      │
      ▼
TransactionSynchronizationManager   ata esa conexión al hilo en un ThreadLocal (08)
```

- **`PlatformTransactionManager`** es la interfaz; la implementación depende de tu stack:
  `DataSourceTransactionManager` para JDBC, `JpaTransactionManager` para JPA. Boot declara
  el correcto por autoconfiguración ([`06`](06-arranque-y-autoconfiguracion.md)) y con dos `DataSource` tienes que elegir
  explícitamente.
- **La conexión se ata al hilo**, no al objeto ni al método. Por eso todo el código que
  corra en ese hilo comparte la transacción, y por eso **nada que salte a otro hilo la
  hereda** ([`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)).

> **🧠 Modelo mental, y es la frase que hay que poder decir en voz alta.**
> `@Transactional` no abre una transacción: le pide a un proxy que le pida al
> `TransactionManager` que abra una. **Si no hay proxy en medio, la anotación es un
> comentario.**

---

## 3. ⚖ Declarativo y programático

```java
@Transactional
public void record(InventoryEvent event) { … }
```

```java
private final TransactionTemplate tx;   // se construye con el TransactionManager

public void importAll(List<InventoryEvent> events) {
    for (InventoryEvent event : events) {
        // una transacción por evento: un fallo no tumba el lote entero
        tx.executeWithoutResult(status -> repository.save(event));
    }
}
```

- **El declarativo cubre el 95 % de los casos** y es el que se usa por defecto: el límite
  de la transacción coincide con el límite del método.
- **El programático gana cuando el límite no es un método**: un bucle en el que cada
  iteración es su propia transacción, un bloque pequeño dentro de un método largo, o
  cuando necesitas decidir en tiempo de ejecución si hay transacción. Escribir eso con
  anotaciones obliga a partir la clase en trozos artificiales.
- **`status.setRollbackOnly()`** marca la transacción como condenada sin lanzar nada. Es la
  forma de decir "esto no se guarda" cuando no quieres usar una excepción como control de
  flujo.

---

## 4. ⚖ Propagación

Qué pasa cuando un método transaccional llama a otro método transaccional:

| Propagación | Si ya hay transacción | Si no la hay |
|---|---|---|
| **`REQUIRED`** (default) | se une a ella | crea una |
| **`REQUIRES_NEW`** | **la suspende** y crea otra independiente | crea una |
| `SUPPORTS` | se une | corre sin transacción |
| `NOT_SUPPORTED` | la suspende y corre sin transacción | corre sin transacción |
| `MANDATORY` | se une | **falla** |
| `NEVER` | **falla** | corre sin transacción |
| `NESTED` | crea un **savepoint** dentro de la misma | crea una |

De las siete, tres se usan de verdad:

- **`REQUIRED`** es lo que quieres casi siempre: todo el trabajo de una petición en una
  sola unidad atómica.
- **`REQUIRES_NEW`** sirve cuando algo debe persistir **aunque lo de fuera falle** — el
  caso canónico es una auditoría. Y tiene un precio que casi nadie menciona:

> **⏱️ Costo en runtime de `REQUIRES_NEW`.** Suspender la transacción externa no libera su
> conexión: la retiene mientras la interna corre con **otra**. Tu método consume dos
> conexiones del pool a la vez. Con un pool de 10 y 6 peticiones concurrentes entrando por
> ese camino, las 10 conexiones están tomadas y las que esperan una segunda no la obtienen
> jamás: **deadlock por agotamiento de pool**, con el `HikariPool-1 - Connection is not
> available, request timed out` de `15` y sin una sola línea de tu código en el stack trace.

- **`NESTED`** usa savepoints: un fallo dentro revierte hasta el savepoint sin tumbar la
  transacción externa. Necesita soporte del driver y del `TransactionManager` —con JPA
  suele no estar disponible—, así que se comprueba antes de diseñar con él.

> Nunca respondas: ~~"uso `REQUIRES_NEW` porque es más seguro"~~
>
> Mejor: "`REQUIRES_NEW` es para lo que debe sobrevivir al fallo de fuera, y se paga con
> una segunda conexión simultánea; por defecto va `REQUIRED`."

---

## 5. 🧱 Aislamiento

El nivel de aislamiento decide qué puede ver tu transacción de lo que otras están
haciendo. Los tres fenómenos, de menos a más grave de evitar:

```text
dirty read            lees algo que otra transacción aún no confirmó
non-repeatable read   lees dos veces la misma fila y cambió
phantom read          repites una consulta y aparecen filas nuevas
```

| Nivel | dirty | non-repeatable | phantom |
|---|---|---|---|
| `READ_UNCOMMITTED` | ✅ ocurre | ✅ | ✅ |
| `READ_COMMITTED` | ❌ | ✅ | ✅ |
| `REPEATABLE_READ` | ❌ | ❌ | ✅ |
| `SERIALIZABLE` | ❌ | ❌ | ❌ |

- **`Isolation.DEFAULT` significa "el de la base", no uno concreto.** Postgres y Oracle
  usan `READ_COMMITTED`; MySQL con InnoDB usa `REPEATABLE_READ`. El mismo código se
  comporta distinto al cambiar de motor, y eso sorprende en una migración.
- **Esa tabla es la del estándar ANSI, y tu motor no la cumple al pie de la letra.** En
  Postgres —el del lab— hay dos desviaciones que se preguntan: `READ_UNCOMMITTED` **se
  comporta como `READ_COMMITTED`** (el MVCC nunca enseña una versión sin confirmar, así que
  pedir lecturas sucias no te las da), y `REPEATABLE_READ` es **snapshot isolation**, de
  modo que además de las lecturas no repetibles **evita también los phantom reads** que la
  tabla marca como posibles. Lo que aparece a cambio es el
  `could not serialize access due to concurrent update`, que tu código tiene que estar
  dispuesto a reintentar. La frase que gana: *"la tabla es un contrato de mínimos; lo que
  te da de verdad lo dice la documentación de tu motor"*.
- **Subir el nivel no es gratis:** más bloqueos, más contención y más probabilidad de
  deadlock. `SERIALIZABLE` en un sistema con carga es una decisión que se justifica, no un
  default prudente.
- **Para el caso típico de "dos peticiones actualizan la misma fila"** la respuesta
  habitual no es subir el aislamiento: es **optimistic locking** con `@Version` (`15`),
  que falla rápido y no bloquea.

> Nunca respondas: ~~"el nivel de aislamiento lo pone Spring"~~
>
> Mejor: "lo implementa la base; Spring solo se lo comunica al abrir la transacción, y por
> defecto ni eso: usa el del motor."

---

## 6. ⚠️ Rollback: la regla que casi todo el mundo dice mal

**Por defecto, Spring hace rollback solo ante `RuntimeException` y `Error`.** Una excepción
comprobada —cualquier `Exception` que no sea `RuntimeException`— **confirma la
transacción**.

```java
@Transactional                                  // ❌ hace COMMIT si falla el envío
public void record(InventoryEvent event) throws IOException {
    repository.save(event);
    notifier.send(event);                       // lanza IOException, que es checked
}

@Transactional(rollbackFor = Exception.class)   // ✅ ahora sí revierte
public void record(InventoryEvent event) throws IOException { … }
```

- **`rollbackFor`** amplía la regla; **`noRollbackFor`** la reduce, para excepciones que
  usas como control de flujo y no como fallo.
- **Capturar la excepción cancela el rollback**, y este es el fallo más frecuente del
  capítulo: si haces `try { … } catch (Exception e) { log.error(...); }` dentro del método
  transaccional, el proxy nunca ve la excepción, y para él todo salió bien. **Commit.**
- **Y su versión cruel:** si capturas una excepción lanzada *después* de que una
  transacción interna se marcara `rollback-only`, el commit final falla con
  `UnexpectedRollbackException: Transaction silently rolled back because it has been marked
  as rollback-only`. Lo desconcertante es que el mensaje aparece en el método de fuera, que
  no hizo nada malo.
- **`readOnly = true`** le dice a Hibernate que no haga dirty checking —ahorro real en
  consultas grandes— y a la base que puede optimizar. **No es una garantía**: en muchos
  motores no impide escribir, así que no lo uses como medida de seguridad.
- **`timeout`** son segundos, lo administra el `TransactionManager` y **sí llega al
  driver**: `DataSourceUtils.applyTimeout` le pasa a cada `Statement` el tiempo que le
  queda de vida a la transacción con `setQueryTimeout()`. Lo preciso es que se aplica
  **por sentencia**: no cuenta el tiempo entre sentencias, y `setQueryTimeout` pide una
  cancelación —que el motor puede tardar en atender— en vez de cortar el socket. Por eso
  **no sustituye** al `socketTimeout` del driver ni al `statement_timeout` del motor: los
  tres se apilan, y el presupuesto de tiempo se escribe con los tres a la vista.

---

## 7. 🩺 Los seis silencios

Cuándo `@Transactional` no hace lo que crees y no lo dice. **Los cuatro primeros son
consecuencia directa de [`05`](05-proxies-y-aop.md)** —el proxy no interviene y no llega a
haber transacción—; los dos últimos sí la abren, y fallan por otro motivo:

| Caso | Por qué | ¿Avisa? |
|---|---|---|
| Llamada desde la misma clase | el proxy no participa | ❌ |
| Método `private` | no se puede interceptar | ❌ |
| Método `final` o clase `final` | CGLIB no puede sobrescribir | ❌ / error de arranque |
| Llamado desde `@PostConstruct` | corre sobre el objeto, no el proxy | ❌ |
| Excepción capturada dentro | el proxy no la ve | ❌ |
| Import de `jakarta.transaction` | **la transacción sí abre**, pero pierde atributos | ❌ hasta que pides uno |

El último merece su propio aviso porque compila, funciona a medias y nadie lo mira:

> **⚠️ Hay dos `@Transactional`.** El de Spring es
> `org.springframework.transaction.annotation.Transactional`; el de Jakarta es
> `jakarta.transaction.Transactional`. Spring **respeta** el de Jakarta y abre la
> transacción igual —traduce su `TxType` a la propagación equivalente—, así que el código
> funciona; lo que se pierde son atributos: **no hay `readOnly`, ni `isolation`, ni
> `timeout`**, y `rollbackFor`/`noRollbackFor` se llaman `rollbackOn`/`dontRollbackOn`. Te
> enteras cuando el compilador rechaza el atributo que fuiste a añadir, no cuando el dato
> se guarda mal — y si el método nunca necesita uno, no te enteras nunca. El IDE ofrece los
> dos y ordena alfabéticamente, así que el error se comete solo.

> **📝 "`@Transactional` solo funciona en métodos `public`" ya no es exacto.** Es la frase
> que vas a encontrar en cualquier blog anterior a 2022, y desde **Spring Framework 6.0**
> sobra media respuesta: con proxies **CGLIB** —el default de Boot desde 2.0— la anotación
> también se respeta en métodos `protected` y package-private, porque la subclase puede
> sobrescribirlos. Lo que **nunca** funciona es `private`, y con proxies JDK no funciona
> nada que no esté declarado en la interfaz. La versión que gana en una entrevista: *"no es
> cuestión de `public`, es cuestión de si el proxy puede sobrescribir el método y de si la
> llamada entra desde fuera del bean"* ([`05`](05-proxies-y-aop.md)).

**Cómo se diagnostica cualquiera de los seis**, en un comando:

```properties
logging.level.org.springframework.transaction.interceptor=TRACE
```

- Si el interceptor corrió, el log imprime `Getting transaction for [com.invlab...record]`
  antes de tu método y `Completing transaction for` después.
- **Si esas líneas no aparecen, no hubo transacción**, y ya tienes la respuesta sin abrir
  el debugger. Es lo que se practica en `L04`.

---

## 8. 🧱 El límite de la transacción no es el límite de tu método

Dos reglas de diseño que separan a quien ha sufrido esto de quien no:

- **Nada lento dentro de una transacción.** Una llamada HTTP a un proveedor ([`13`](13-clientes-http.md)) dentro
  de un método transaccional retiene una conexión de base de datos durante todo el
  round-trip. Si el proveedor tarda 3 segundos y tienes 10 conexiones, 10 peticiones
  concurrentes agotan el pool mientras la base está ociosa ⏱️.
- **El efecto externo va después del commit**, nunca dentro. Publicar un evento, mandar un
  correo o encolar un mensaje dentro de la transacción produce el peor fallo posible: el
  aviso sale y el dato se revierte. El mecanismo correcto:

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
void onRecorded(InventoryRecorded event) {
    projector.refresh(event.sku());
}
```

- **`AFTER_COMMIT`** ejecuta el listener solo si la transacción confirmó. Las otras fases
  —`AFTER_ROLLBACK`, `AFTER_COMPLETION`, `BEFORE_COMMIT`— existen y se usan menos.
- **El listener corre en el mismo hilo y fuera de la transacción**: si escribe en la base,
  necesita la suya propia (`REQUIRES_NEW`), o no se guardará nada. Y tiene su ⏱️: cuando el
  listener corre, la conexión de la transacción original **todavía no ha vuelto al pool**
  —se suelta un paso después, al limpiar—, así que ahí también hay dos conexiones a la vez
  (§4). Si el efecto puede esperar, un listener `@Async` ([`18`](18-asincronia-scheduling-y-eventos.md)) rompe esa coincidencia.
- **Esto no es entrega garantizada.** Si el proceso muere entre el commit y el listener, el
  evento se pierde. Cuando eso importa —y en banca importa— el patrón es **outbox**, que
  escribe el evento en la misma transacción y lo publica aparte. El diseño completo está en
  el corpus de arquitectura; aquí basta saber que este mecanismo tiene ese límite.

---

## 9. ⚖ Cuando la transacción cruza dos sistemas

Dos bases, o una base y una cola. La respuesta clásica es el commit en dos fases (XA), y la
respuesta moderna es evitarlo:

- **Boot no trae XA activado** y `JtaTransactionManager` exige un coordinador. Añade
  latencia, un punto único de fallo y un estado que hay que recuperar tras una caída.
- **La alternativa que se usa hoy** es aceptar consistencia eventual con compensaciones:
  **outbox** para publicar de forma fiable y **saga** para coordinar pasos de negocio, cada
  uno con su compensación.
- **Y la respuesta de entrevista que gana**: antes de coordinar dos sistemas, pregúntate si
  el límite entre ellos está bien puesto. Muchas transacciones distribuidas son un servicio
  mal partido.

---

## 10. ⚠️ Errores frecuentes

- **"`@Transactional` garantiza el rollback."** Solo ante excepciones no comprobadas, solo
  si hay proxy y solo si no capturaste la excepción.
- **"Pongo `@Transactional` en el controller y cubro todo."** Extiende la transacción a la
  serialización de la respuesta y a cualquier llamada externa del handler. El límite va en
  el servicio.
- **"`readOnly = true` impide escribir."** Es una pista de optimización, no un permiso.
- **"Si el método es `public` ya está."** También tiene que llamarse desde otro bean.
- **"Una transacción por método es siempre lo correcto."** En un bucle de mil elementos,
  una transacción por elemento evita que un fallo tumbe el lote — y es exactamente lo que
  hace Spring Batch con sus chunks ([`22` §3](22-spring-batch.md#3--el-chunk-leer-uno-procesar-uno-escribir-de-a-muchos)).

---

## 🧠 Preguntas rápidas

1. ¿Qué parte del trabajo hace la base de datos y qué parte hace Spring cuando anotas un
   método con `@Transactional`?
2. Explica por qué `@Transactional` puede no hacer absolutamente nada sin que falle nada.
3. ¿A qué se ata la conexión de una transacción, y qué consecuencia tiene eso para un
   método `@Async`?
4. ¿Cuándo eliges `TransactionTemplate` en lugar de la anotación? Da un caso concreto.
5. Diferencia `REQUIRED` de `REQUIRES_NEW` y di cuántas conexiones del pool consume un
   método que usa la segunda dentro de la primera.
6. Un servicio con pool de 10 se queda colgado sin errores en el log de la aplicación,
   acaba lanzando `Connection is not available` y la base no está ejecutando ni una
   consulta. Da dos causas posibles de este capítulo y explica por qué una llamada HTTP
   dentro de la transacción es una de ellas.
7. ¿Qué significa `Isolation.DEFAULT`, y por qué el mismo código se comporta distinto en
   Postgres y en MySQL?
8. Tu método lanza una `IOException` y los datos se guardaron igual. ¿Por qué, y cuáles son
   las dos formas de corregirlo?
9. ¿Por qué un `try/catch` dentro de un método transaccional puede convertir un rollback en
   un commit?
10. Explica el mensaje `Transaction silently rolled back because it has been marked as
    rollback-only`: ¿quién lo marcó y por qué aparece en un método que no falló?
11. ¿Qué hace exactamente `readOnly = true` y qué **no** garantiza?
12. El `timeout` de `@Transactional` expira pero la consulta sigue viva en la base. ¿Por
    qué, y qué otro timeout hacía falta?
13. Nombra los seis silencios de `@Transactional` y di **cuáles de los seis sí abren** la
    transacción.
14. ¿Cómo compruebas en un minuto, sin debugger, si un método corrió dentro de una
    transacción?
15. ¿Para qué sirve `@TransactionalEventListener(AFTER_COMMIT)` y qué garantía **no** te da?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Gestión de transacciones: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction.html
- Spring Framework 6.2 — Estrategias y `PlatformTransactionManager`: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/strategies.html
- Spring Framework 6.2 — Transacciones declarativas: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative.html
- Spring Framework 6.2 — `@Transactional` y sus atributos: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/annotations.html
- Spring Framework 6.2 — Propagación: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/tx-propagation.html
- Spring Framework 6.2 — Rollback declarativo: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/rolling-back.html
- Spring Framework 6.2 — Transacciones programáticas: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/programmatic.html
- Spring Framework 6.2 — Eventos ligados a la transacción: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/event.html
- Spring Boot 3.5 — Datos SQL y transacciones: https://docs.spring.io/spring-boot/3.5/reference/data/sql.html

### Documentación de terceros

- PostgreSQL 17 — Aislamiento de transacciones (las dos desviaciones de §5): https://www.postgresql.org/docs/17/transaction-iso.html
