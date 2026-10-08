# 02 — Transacciones, aislamiento y bloqueo

> ACID con precisión, los cuatro niveles de aislamiento y las anomalías que cada uno permite,
> bloqueo optimista contra pesimista, y los siete niveles de propagación de `@Transactional`
> que nadie recuerda y todos usan.
> Asume leído [`01` — CAP, PACELC y consistencia](01-cap-y-consistencia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Dos usuarios compran la última unidad a la vez. Este código está mal y lo ha escrito todo el
mundo:

```java
@Transactional
public void comprar(ProductoId id) {
    Producto p = repositorio.porId(id).orElseThrow();
    if (p.stock() > 0) {              // los dos leen stock = 1
        p.descontarStock();           // los dos descuentan
        repositorio.guardar(p);       // stock queda en 0, pero vendiste 2
    }
}
```

- `@Transactional` **no evita esto**. Abrir una transacción no serializa nada: con el nivel de
  aislamiento por defecto, ambas leen el mismo valor y ambas escriben.
- El problema tiene nombre —**actualización perdida**— y el nivel de aislamiento por defecto de
  Postgres y Oracle lo permite.

> **Regla importante:** `@Transactional` da atomicidad, no exclusión mutua. Si dos hilos pueden
> tocar el mismo dato, necesitas además un mecanismo de concurrencia explícito.

---

## 2. 🧪 ACID, con precisión

**Qué es.** Las cuatro propiedades de una transacción, y conviene decirlas bien porque tres de
las cuatro se explican mal.

```text
A  Atomicidad    → todo o nada. Si falla algo, nada quedó escrito.
C  Consistencia  → las restricciones de integridad se cumplen al terminar.
                   Es la propiedad más discutida: la garantiza TU modelo, no el motor.
I  Aislamiento   → las transacciones concurrentes no se ven a medias.
                   En la práctica es un DIAL, no un sí/no. Todo el capítulo va de esto.
D  Durabilidad   → lo confirmado sobrevive a una caída.
                   Con replicación asíncrona, "confirmado" puede perderse si cae el primario.
```

- **La C es la letra rara.** Kleppmann argumenta que no es una propiedad del sistema sino de la
  aplicación: la base de datos aplica las restricciones que tú declaraste. Decirlo demuestra
  lectura.
- **La I es el dial.** El aislamiento perfecto —serializable— existe y casi nadie lo usa por su
  coste. Todo lo demás es un compromiso con anomalías conocidas.
- **La D tiene letra pequeña.** Con réplica asíncrona, un commit confirmado en el primario puede
  perderse si este cae antes de replicar. Es el enlace con
  [`05` — Réplicas y lag](05-replicas-y-lag.md).

> **Veredicto:** ACID no significa "seguro". Significa "seguro dentro de estos límites", y los
> límites los fija el nivel de aislamiento que casi nadie mira.

---

## 3. 🎚️ Los niveles de aislamiento

**Qué es.** El estándar SQL define cuatro niveles, cada uno permitiendo unas anomalías. Esta
tabla es de las pocas que vale la pena memorizar:

| Nivel | Lectura sucia | Lectura no repetible | Lectura fantasma |
|---|---|---|---|
| **Read Uncommitted** | ✅ permite | ✅ permite | ✅ permite |
| **Read Committed** | ❌ evita | ✅ permite | ✅ permite |
| **Repeatable Read** | ❌ evita | ❌ evita | ✅ permite* |
| **Serializable** | ❌ evita | ❌ evita | ❌ evita |

Las anomalías, con un ejemplo cada una:

```text
Lectura sucia        → lees un valor que otra transacción escribió y luego deshizo.
Lectura no repetible → lees el mismo registro dos veces y ha cambiado en medio.
Lectura fantasma     → repites la misma CONSULTA y aparecen filas nuevas.
Actualización perdida→ dos leen, dos escriben, una sobrescribe a la otra sin verla.
```

**Lo que hay que saber de los motores reales**, porque el estándar y la práctica difieren:

- **Postgres por defecto: Read Committed.** Su Repeatable Read es en realidad *snapshot
  isolation* y **sí evita los fantasmas**, de ahí el asterisco. Y detecta la actualización
  perdida abortando una de las transacciones.
- **MySQL/InnoDB por defecto: Repeatable Read**, con bloqueos de rango que evitan fantasmas.
- **Oracle**: Read Committed y Serializable; no tiene Repeatable Read.
- **La actualización perdida no está en la tabla del estándar** y es la anomalía que más daño
  hace en aplicaciones reales. Es la del ejemplo de §1.

> ⚠️ **Advertencia.** "Usamos transacciones" no responde nada. La pregunta real es **en qué nivel
> de aislamiento**, y la respuesta por defecto —Read Committed— permite lectura no repetible,
> fantasmas y actualización perdida.

> **Veredicto:** subir a Serializable resuelve todo y cuesta throughput y reintentos por
> conflicto. Casi siempre sale mejor quedarse en el nivel por defecto y resolver la concurrencia
> del caso concreto con bloqueo explícito.

---

## 4. 🔒 Bloqueo pesimista

**Qué es.** Bloquear la fila al leerla, de modo que nadie más pueda tocarla hasta que termines.
En SQL es `SELECT ... FOR UPDATE`; en JPA, `LockModeType.PESSIMISTIC_WRITE`.

```java
// Nadie más puede leer-para-actualizar esta fila hasta que la transacción termine
Producto p = em.find(Producto.class, id, LockModeType.PESSIMISTIC_WRITE);
```

- Resuelve la actualización perdida del §1 de forma directa: el segundo hilo espera.
- **Cuesta espera**: bajo contención, los hilos se encolan y el throughput cae con el número de
  competidores.
- **Puede producir interbloqueos** si dos transacciones bloquean las mismas filas en orden
  distinto. Se mitiga bloqueando siempre en el mismo orden.

**Cuándo sí.** Contención alta y esperada sobre el mismo dato: el último asiento, el stock de un
producto en oferta, un contador muy disputado. Cuando reintentar sería peor que esperar.

**Cuándo no.** Contención baja: estás pagando bloqueos que casi nunca colisionan. Y nunca sobre
transacciones largas o que llaman a servicios externos: mantener un bloqueo mientras esperas una
API de terceros es la receta de una caída.

> **Veredicto:** el bloqueo pesimista es correcto cuando el conflicto es la norma. Si es la
> excepción, estás serializando para nada.

---

## 5. 🔁 Bloqueo optimista

**Qué es.** No bloquear nada: leer con una versión, y al escribir comprobar que la versión no
cambió. Si cambió, alguien te ganó y tu operación se rechaza.

```java
@Entity
public class Producto {
    @Version private long version;   // JPA lo gestiona solo
}
// UPDATE producto SET stock=?, version=version+1 WHERE id=? AND version=?
// 0 filas afectadas → OptimisticLockException
```

- El `UPDATE` con `WHERE version = ?` es todo el mecanismo: si otro escribió, la condición falla
  y afecta a cero filas.
- **No hay espera**: el throughput no cae con la contención, pero la tasa de fallos sube.
- **Obliga a decidir qué hacer con el conflicto**, y esa decisión es de negocio: reintentar,
  fusionar, o mostrar al usuario "alguien modificó esto".

**Cuándo sí.** Contención baja o media, que es la mayoría de los casos. Y es obligatorio en
cualquier flujo donde el usuario piense entre leer y escribir —un formulario— porque ahí un
bloqueo pesimista duraría minutos.

**Cuándo no.** Contención muy alta: la tasa de reintentos se dispara y acabas haciendo el trabajo
tres veces. Ahí, pesimista.

> 💡 **Truco.** El bloqueo optimista es también la contramedida de la **actualización perdida**
> en sagas, de [`02-eventos/05`](../02-eventos/05-saga.md). El mismo mecanismo resuelve el
> problema dentro de una base de datos y entre servicios.

> **Veredicto:** optimista por defecto, pesimista cuando midas que el conflicto es frecuente. Y
> la pregunta que el entrevistador hará después: *"¿y qué le dices al usuario cuando falla?"*.

---

## 6. 🔄 Propagación de `@Transactional`

**Qué es.** Qué hace Spring cuando un método transaccional llama a otro. Son siete niveles, de
los que en la práctica se usan tres:

| Propagación | Si ya hay transacción | Si no la hay |
|---|---|---|
| **REQUIRED** (por defecto) | Se une a ella | Crea una |
| **REQUIRES_NEW** | **Suspende** la actual y crea otra | Crea una |
| **MANDATORY** | Se une | **Lanza excepción** |
| **SUPPORTS** | Se une | Sigue sin transacción |
| **NOT_SUPPORTED** | Suspende y sigue sin ella | Sigue sin ella |
| **NEVER** | **Lanza excepción** | Sigue sin ella |
| **NESTED** | Punto de guardado dentro de la actual | Crea una |

Los tres casos que se preguntan:

- **`REQUIRED`** es el 95 % de los usos y el correcto por defecto.
- **`REQUIRES_NEW`** para lo que debe persistir aunque la principal falle: auditoría, registro de
  intentos. **Ojo**: la transacción externa sigue bloqueando sus filas mientras la interna corre,
  así que dos transacciones del mismo hilo compitiendo por la misma fila se interbloquean solas.
- **`MANDATORY`** para forzar que un método solo se llame dentro de una transacción ajena. Es una
  aserción de diseño y se usa poco.

> ⚠️ **Advertencia.** Nada de esto funciona si la llamada es **interna**: `this.metodo()` no pasa
> por el proxy y la anotación se ignora. Es la causa número uno de "`@Transactional` no
> funciona", y está en [`01-bases/04` §10](../01-bases/04-patrones-gof.md).

> **Veredicto:** saber que `REQUIRES_NEW` suspende y no anida —y que por eso puede
> interbloquearse consigo misma— es el detalle que distingue a quien lo ha depurado.

---

## 7. 🧭 Cómo se elige

```text
¿Dos operaciones pueden tocar el mismo dato a la vez?
    No  → @Transactional por defecto basta.
    Sí  → hace falta un mecanismo de concurrencia. Elige:

        ¿El conflicto es frecuente? (último asiento, stock en oferta)
            → PESIMISTA. Esperar es mejor que reintentar tres veces.
        ¿El conflicto es raro?
            → OPTIMISTA con @Version. Y decide qué le dices al usuario al fallar.
        ¿Hay un humano pensando entre leer y escribir?
            → OPTIMISTA, obligatorio. Un bloqueo no puede durar lo que dura un formulario.

¿Puedo evitar el conflicto en vez de gestionarlo?
    → A menudo sí: UPDATE stock = stock - 1 WHERE id = ? AND stock > 0
      Una sola sentencia atómica, sin leer antes. Cero filas = no había stock.
      ES LA MEJOR OPCIÓN y casi nadie la propone primero.

¿Necesito subir el nivel de aislamiento?
    → Casi nunca. Resuelve el caso concreto con bloqueo antes de serializar todo el sistema.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`@Transactional` evita la condición de carrera" | Da atomicidad, no exclusión mutua |
| "Usamos transacciones" | ¿En qué nivel de aislamiento? El defecto permite actualización perdida |
| "Repeatable Read evita fantasmas" | En el estándar no; en Postgres sí, porque es snapshot isolation |
| "La C de ACID la garantiza la base de datos" | Aplica las restricciones que tú declaraste; la consistencia del dominio es tuya |
| "Durabilidad significa que no se pierde" | Con réplica asíncrona, un commit puede perderse si cae el primario |
| "`REQUIRES_NEW` anida la transacción" | La **suspende** y abre otra independiente; `NESTED` es lo que anida |
| "Subo a Serializable y me olvido" | Cuesta throughput y genera reintentos por conflicto de serialización |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 7 completo: es la mejor explicación publicada de los niveles de aislamiento y de por
  qué el estándar SQL se queda corto. **El de este capítulo.**
- **Libro** — Vlad Mihalcea, *High-Performance Java Persistence*. Parte sobre concurrencia:
  bloqueo optimista y pesimista en JPA, con los casos reales y las trampas.
- **Libro** — Alex Petrov, *Database Internals* (O'Reilly, 2019). Capítulo 5: control de
  concurrencia por dentro, MVCC y bloqueos.
- [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html):
  la tabla de anomalías real del motor, incluidas las diferencias con el estándar.
- [Spring Framework — Declarative transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative.html):
  los siete niveles de propagación y qué hace el proxy.
- [Spring Data JPA — Locking](https://docs.spring.io/spring-data/jpa/reference/jpa/locking.html):
  cómo se declara el bloqueo optimista y el pesimista.
- **Tutorial** — Baeldung, «Transaction Propagation and Isolation in Spring»: los siete niveles
  con ejemplos ejecutables.
- **Video** — Devoxx y Spring I/O, charlas de Vlad Mihalcea sobre concurrencia en JPA. Búscalas
  por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué significan las cuatro letras de ACID? 🟢
2. Nombra los cuatro niveles de aislamiento del estándar SQL. 🟢
3. ¿Qué es una lectura fantasma? 🟢
4. ¿Qué es el bloqueo optimista y cómo se implementa? 🟢
5. ¿Cuál es el nivel de aislamiento por defecto de Postgres? 🟢
6. ¿Qué diferencia hay entre lectura sucia y lectura no repetible? 🟡
7. ¿Qué es la actualización perdida y por qué no está en la tabla del estándar? 🟡
8. ¿Por qué `@Transactional` no evita una condición de carrera? 🟡
9. ¿Qué hace exactamente `REQUIRES_NEW`? 🟡
10. ¿Qué diferencia hay entre `REQUIRES_NEW` y `NESTED`? 🟡
11. ¿Por qué la C de ACID es "la letra rara"? 🟡
12. ¿Qué letra pequeña tiene la D de ACID? 🟡
13. ¿Cuándo eliges bloqueo pesimista sobre optimista? 🟠
14. ¿Por qué un bloqueo pesimista no sirve si hay un humano pensando? 🟠
15. ¿Qué coste tiene subir a Serializable? 🟠
16. ¿Por qué el Repeatable Read de Postgres evita fantasmas y el del estándar no? 🟠
17. ¿Cómo evitas el conflicto en vez de gestionarlo, con una sola sentencia? 🟠
18. ¿Por qué `REQUIRES_NEW` puede interbloquearse consigo misma? 🟠
19. ¿Qué le dices al usuario cuando falla un bloqueo optimista? 🟠
20. ¿Por qué nunca se mantiene un bloqueo mientras llamas a un servicio externo? 🟠
21. Corrige el código de la sección 1 de tres formas distintas y compáralas. 🔴
22. Diseña la concurrencia de "comprar la última entrada" con 10.000 usuarios
    simultáneos. Justifica el mecanismo. 🔴
23. Tras un despliegue aparecen `OptimisticLockException` masivas. Da tres
    hipótesis en orden y di cómo las confirmas. 🔴

---

**Anterior:** [`01` — CAP, PACELC y consistencia](01-cap-y-consistencia.md) ·
**Siguiente:** [`03` — Relacional, NoSQL y DynamoDB](03-relacional-nosql-y-dynamodb.md) ·
**Relacionado:** [`01-bases/05` — Fowler PoEAA](../01-bases/05-fowler-poeaa.md)
