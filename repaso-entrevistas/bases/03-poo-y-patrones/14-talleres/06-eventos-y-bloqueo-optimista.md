# 06 — Eventos y bloqueo optimista

> Desacoplas las notificaciones con eventos de dominio que la cuenta anota y el servicio publica después de confirmar
> (Observer), y dejas de perder dinero cuando dos operaciones tocan la misma cuenta a la vez: una transacción por
> operación, una columna `version` y un decorador que reintenta. Terminas con `laboratorio/estados/06/`, el estado final del
> bloque. Parte de `estados/05`. Ejercita [`09/02` — Eventos de dominio](../09-ddd-tactico-y-otros/02-eventos-servicios-y-fabricas.md),
> [`06/03` — Observer](../06-comportamiento/03-observer.md), [`08/03` — Concurrencia offline](../08-fowler-presentacion-distribucion-y-base/03-concurrencia-offline.md),
> [`07/03` — Unit of Work](../07-fowler-dominio-y-datos/03-comportamiento-objeto-relacional.md) y
> [`10/02` — Esperar y coordinar](../10-concurrencia/02-esperar-y-coordinar.md). Opcional; reglas en §13.2 de la guía del
> corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--la-cuenta-anota-lo-que-le-pasa) · [5](#5--paso-2--una-transacción-por-operación) · [6](#6--paso-3--la-versión-de-la-fila) · [7](#7--paso-4--reintentar-como-decorador) · [8](#8--evidencia) · [9](#9-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

Con los seis defectos de `14/01` corregidos, quedan dos problemas que la caracterización nunca vio, porque solo aparecen
cuando el sistema hace más de una cosa a la vez o cuando algo falla a mitad de camino:

```java
// estados/05, ServicioMovimientos.depositar, recortado
Cuenta c = cuentas.buscar(numero);          // lee el saldo
c.depositar(importe);                       // suma en memoria
cuentas.guardar(c);                         // escribe el saldo que calculó, pase lo que haya pasado mientras
movimientos.registrar(new Movimiento(…));
notificador.enviar(c.getEmail(), "Recibiste un depósito de " + importe);
```

- **Leer, calcular y escribir** sin control: si dos depósitos leen el mismo saldo, el segundo en escribir borra al
  primero. Es la actualización perdida (*lost update*) de [`08/03`](../08-fowler-presentacion-distribucion-y-base/03-concurrencia-offline.md).
- **Cada sentencia se confirma sola** (*autocommit*): si la transferencia falla entre el débito y el crédito, el dinero se
  pierde. El ejercicio E4 de `14/03` lo probó con un repositorio que falla al segundo `guardar`.
- **El servicio sabe de correos**: tres llamadas a `notificador.enviar` en `ServicioMovimientos` y tres en
  `ServicioCuentas`, cada una con su texto y su regla (el retiro solo avisa desde un millón). Un canal nuevo —un SMS, una
  notificación móvil— es tocar los dos servicios.

---

## 2. 🧰 Punto de partida

Parte de `estados/05`. Lo que cambia:

```text
estados/06/src/
├── main/java/banco/
│   ├── EventoDeCuenta.java            nuevo: interfaz sellada con seis records en pasado
│   ├── PublicadorDeEventos.java       nuevo: el sujeto del Observer
│   ├── AvisosPorCorreo.java           nuevo: el suscriptor que decide qué evento merece correo
│   ├── ConflictoDeConcurrencia.java   nuevo: alguien guardó antes
│   ├── OperacionesConReintentos.java  nuevo: el decorador que repite ante el conflicto
│   ├── BaseDatos.java                 enTransaccion; columna version
│   ├── RepositorioCuentas.java        trabajan con la conexión de la transacción;
│   ├── RepositorioMovimientos.java      guardar comprueba la versión
│   ├── Cuenta.java                    anota sus eventos; conoce su versión
│   ├── ServicioCuentas.java           una transacción por operación; publica después
│   ├── ServicioMovimientos.java         y no conoce al notificador
│   └── GestorCuentas.java             compone publicador, suscriptor y los dos decoradores
└── test/java/banco/
    ├── ConcurrenciaTest.java          nuevo: cien depósitos desde diez hilos
    └── EventosTest.java               nuevo: qué se publica y cuándo
```

`CaracterizacionTest` no cambia: los correos salen con el mismo texto y a las mismas personas, ahora desde un suscriptor.

---

## 3. 🩺 El defecto, reproducido

Cien depósitos de 1 000 sobre la cuenta de Ana, desde diez hilos a la vez. Deberían sumar 100 000:

```java
@Test
void cienDepositosConcurrentesSumanCienMil() throws Exception {
    BaseDatos.crearEsquema();
    GestorCuentas gestor = new GestorCuentas(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(),
            new NotificadorMudo());
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 0, false);
    ExecutorService hilos = Executors.newFixedThreadPool(10);
    List<Future<?>> tareas = new ArrayList<>();
    for (int i = 0; i < 100; i++) {
        tareas.add(hilos.submit(() -> gestor.depositar("CTA-0001", 1_000, null)));
    }
    for (Future<?> t : tareas) t.get();
    hilos.shutdown();
    assertEquals(Dinero.de("100000", Moneda.COP), gestor.saldo("CTA-0001"));
}
```

- `Executors.newFixedThreadPool(10)` reparte las cien tareas entre diez hilos; `t.get()` espera a cada una y relanza su
  excepción si la tuvo.
- `NotificadorMudo` sobrescribe `enviar` sin hacer nada: la lista estática `ENVIADOS` es un `ArrayList`, y diez hilos
  añadiendo a la vez la corromperían. La prueba aísla lo que quiere ver.
- La cuenta abre con saldo cero, que no es el de §5.6: así el resultado esperado se lee sin restar.

Tres corridas contra `estados/05`:

```text
org.opentest4j.AssertionFailedError: expected: <100000.00 COP> but was: <25000.00 COP>
org.opentest4j.AssertionFailedError: expected: <100000.00 COP> but was: <29000.00 COP>
org.opentest4j.AssertionFailedError: expected: <100000.00 COP> but was: <24000.00 COP>
```

- Se pierden **tres de cada cuatro** depósitos, y un número distinto en cada corrida. Ninguno lanza error: cada hilo cree
  que su depósito entró.
- Las cien filas de `movimiento` sí se escriben. El extracto dice cien depósitos y el saldo, veinticinco: el tipo de
  inconsistencia que un conciliador encuentra semanas después.

---

## 4. 💻 Paso 1 — La cuenta anota lo que le pasa

Antes de tocar la concurrencia, el paso que no cambia nada visible: sacar los correos de los servicios. Lo que le pasa a
una cuenta se dice como un **evento de dominio** en pasado, con lo que un suscriptor necesita para actuar sin volver a la
base:

```java
// Lo que le pasó a una cuenta, dicho en pasado. Lleva lo que un suscriptor necesita, sin volver a la base.
public sealed interface EventoDeCuenta {

    String numero();

    record DepositoRecibido(String numero, String email, Dinero importe) implements EventoDeCuenta { }

    record RetiroHecho(String numero, String email, Dinero importe) implements EventoDeCuenta { }

    record TransferenciaRecibida(String numero, String email, Dinero importe, String titularOrigen)
            implements EventoDeCuenta { }
    // … CuentaAbierta, CuentaBloqueada, CuentaCerrada
}
```

La cuenta los **anota**; no los publica:

```java
public void depositar(Dinero importe) {
    estado.alDepositar(numero);
    saldo = saldo.mas(importe);
    eventos.add(new EventoDeCuenta.DepositoRecibido(numero, email, importe));
}

// entrega los eventos anotados y deja la lista vacía
public List<EventoDeCuenta> eventosNuevos() {
    List<EventoDeCuenta> nuevos = List.copyOf(eventos);
    eventos.clear();
    return nuevos;
}
```

- Es la forma de [`09/02` §2](../09-ddd-tactico-y-otros/02-eventos-servicios-y-fabricas.md#2--domain-event): la entidad
  registra, el servicio publica. La cuenta no conoce al publicador ni a nadie que escuche.
- La interfaz es **sellada**: el suscriptor puede hacer un `switch` exhaustivo, y un evento nuevo no compila hasta que
  alguien decida qué hacer con él.

El correo pasa a ser un suscriptor, con la regla de cada evento dentro:

```java
@Override
public void accept(EventoDeCuenta evento) {
    switch (evento) {
        case EventoDeCuenta.DepositoRecibido e ->
                notificador.enviar(e.email(), "Recibiste un depósito de " + e.importe());
        case EventoDeCuenta.RetiroHecho e -> {
            Dinero umbral = new Dinero(RETIRO_QUE_SE_AVISA.monto(), e.importe().moneda());
            if (!e.importe().esMenorQue(umbral)) {
                notificador.enviar(e.email(), "Retiraste " + e.importe());
            }
        }
        // … un caso por evento, sin default
    }
}
```

- El `switch` de patrones sobre tipos sellados es de Java 21; sin `default`, el compilador exige un caso por cada
  `record`. El `switch` que `14/04` quitó era por un `String`; este es por un tipo cerrado, y es la otra mitad del
  argumento de `06/07`.
- "El retiro solo avisa desde un millón" ya no es un `if` en el servicio: es una regla del aviso, donde la buscaría quien
  quiera cambiarla.

---

## 5. 💻 Paso 2 — Una transacción por operación

Para que el débito y el crédito de una transferencia se confirmen juntos, cada operación corre dentro de **una**
transacción, y los repositorios trabajan con la conexión que les pasan:

```java
// Todo lo que hace el trabajo se confirma junto o no se confirma.
public static <T> T enTransaccion(Trabajo<T> trabajo) {
    try (Connection con = abrir()) {
        con.setAutoCommit(false);
        try {
            T resultado = trabajo.hacer(con);
            con.commit();
            return resultado;
        } catch (SQLException | RuntimeException e) {
            con.rollback();
            if (e instanceof RuntimeException r) throw r;
            throw new RuntimeException(e);
        }
    } catch (SQLException e) {
        throw new RuntimeException(e);
    }
}
```

```java
// en ServicioMovimientos.transferir
Movimiento m = BaseDatos.enTransaccion(con -> {
    Cuenta origen = cuentas.buscar(con, numeroOrigen);
    Cuenta destino = cuentas.buscar(con, numeroDestino);
    // … las reglas, la comisión, el débito y el crédito
    cuentas.guardar(con, origen);
    cuentas.guardar(con, destino);
    movimientos.registrar(con, enviada);
    // …
    eventos.addAll(origen.eventosNuevos());
    eventos.addAll(destino.eventosNuevos());
    return enviada;
});
cacheExtractos.remove(numeroOrigen);
cacheExtractos.remove(numeroDestino);
publicador.publicar(eventos);
```

- `setAutoCommit(false)` abre la transacción; `commit` confirma todo; cualquier excepción hace `rollback`. Es la parte
  "una sola confirmación" del Unit of Work de [`07/03`](../07-fowler-dominio-y-datos/03-comportamiento-objeto-relacional.md#2--unit-of-work),
  sin el registro de objetos sucios.
- **Los eventos se publican después del `commit`**, fuera de la lambda. Si la transacción falla, no sale ningún correo
  por un depósito que no existe. Es lo que hace `@TransactionalEventListener` en Spring, por defecto (`13/01` §5).
- La caché se invalida también después: invalidarla dentro y que la transacción se deshaga solo costaría una recarga,
  pero invalidarla después es lo coherente.

¿Y la concurrencia? La misma prueba, con transacciones pero sin nada más:

```text
org.opentest4j.AssertionFailedError: expected: <100000.00 COP> but was: <8000.00 COP>
org.opentest4j.AssertionFailedError: expected: <100000.00 COP> but was: <19000.00 COP>
```

- **Una transacción no evita la actualización perdida.** Con el aislamiento por defecto de H2 (*read committed*), la
  lectura no bloquea la fila: dos transacciones leen el mismo saldo, y la segunda en confirmar sobrescribe a la primera.
  La transacción hace atómica la operación; no la ordena respecto de las demás.

---

## 6. 💻 Paso 3 — La versión de la fila

El *Optimistic Offline Lock* de [`08/03` §2](../08-fowler-presentacion-distribucion-y-base/03-concurrencia-offline.md#2--optimistic-offline-lock):
cada fila lleva un número de versión, la cuenta recuerda la que leyó, y el `UPDATE` solo escribe si sigue siendo la misma.

```java
// Bloqueo optimista: solo escribe si nadie cambió la fila desde que se leyó.
public void guardar(Connection con, Cuenta c) throws SQLException {
    try (PreparedStatement ps = con.prepareStatement(
            "UPDATE cuenta SET saldo = ?, estado = ?, version = version + 1 WHERE numero = ? AND version = ?")) {
        ps.setBigDecimal(1, c.getSaldo().monto());
        ps.setString(2, c.getEstado().name());
        ps.setString(3, c.getNumero());
        ps.setInt(4, c.getVersion());
        if (ps.executeUpdate() == 0) {
            throw new ConflictoDeConcurrencia(c.getNumero());
        }
    }
}
```

- `executeUpdate` devuelve cuántas filas cambió. Cero significa que la versión ya no era la leída: otro guardó antes.
- `version = version + 1` en el mismo `UPDATE`: la comprobación y el incremento son una sola sentencia, sin carrera entre
  ellas.
- La excepción lanza dentro de la transacción, que hace `rollback`: el movimiento ya insertado de esa operación también se
  deshace.

La prueba de los cien depósitos, ahora:

```text
[ERROR] Tests run: 1, Failures: 0, Errors: 1, Skipped: 0 <<< FAILURE! -- in banco.ConcurrenciaTest
java.util.concurrent.ExecutionException: banco.ConflictoDeConcurrencia: la cuenta CTA-0001 cambió mientras se operaba
```

- Ya no se pierde dinero en silencio: el depósito que llegó tarde **falla**, y quien llamó se entera. Es un avance, pero el
  cliente que depositó ve un error por algo que no hizo.

---

## 7. 💻 Paso 4 — Reintentar, como decorador

Un conflicto de concurrencia es, casi siempre, transitorio: si la operación se repite desde el principio —leyendo otra vez
la cuenta—, lo normal es que entre. Repetirla es una preocupación transversal, y tiene la forma de `14/05`:

```java
// Decorator: si la operación choca con otra, la repite desde el principio, con una espera corta y al azar.
private <T> T conReintentos(Supplier<T> operacion) {
    for (int i = 1; ; i++) {
        try {
            return operacion.get();
        } catch (ConflictoDeConcurrencia e) {
            if (i == intentos) throw e;
            try {
                Thread.sleep(ThreadLocalRandom.current().nextInt(1, 5 * i));
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw e;
            }
        }
    }
}
```

- Solo se reintenta `ConflictoDeConcurrencia`. Un saldo insuficiente o una cuenta cerrada no mejoran al repetir.
- La espera es **al azar** y crece con cada intento: si diez hilos chocan y todos esperan lo mismo, vuelven a chocar juntos.
- Si el hilo se interrumpe durante la espera, se restaura la marca de interrupción y se abandona, como hace el Active
  Object de [`10/04`](../10-concurrencia/04-future-y-active-object.md) al atrapar un `InterruptedException`.

La composición en la fachada, de fuera hacia dentro:

```java
this.operaciones = new OperacionesConReintentos(
        new OperacionesAuditadas(new ServicioMovimientos(cuentas, movimientos, publicador), auditoria), 20);
```

- Los reintentos van **por fuera** de la auditoría: un intento que choca no audita (la auditoría solo registra lo que
  terminó bien), y el que entra audita una vez. Al revés, el resultado sería el mismo con esta auditoría, pero dependería de
  un detalle de ella.

```text
[INFO] Compiling 28 source files with javac [debug release 21] to target/classes
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in banco.EventosTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0 -- in banco.ConcurrenciaTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0 -- in banco.EstadoCuentaTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CadenaYDecoradorTest
[INFO] Tests run: 33, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Una prueba de concurrencia que pasa una vez no prueba mucho. `ConcurrenciaTest` se corrió cinco veces seguidas sobre
`estados/06`, las cinco en verde, entre 0,40 y 0,44 s. Sigue siendo una prueba no determinista: lo que demuestra es que el
defecto, que antes aparecía en todas las corridas, no apareció en ninguna.

---

## 8. 🧪 Evidencia

| | `estados/05` | `estados/06` |
|---|---|---|
| Código de producción | 871 líneas, 23 clases | 1 097 líneas, 28 clases |
| Cien depósitos concurrentes | 24 000 a 29 000 de 100 000 | 100 000, en cinco de cinco corridas |
| Transferencia que falla a mitad | El débito queda y el crédito no | Se deshace entera (ejercicio E2) |
| `notificador.enviar` en los servicios | 6 | 0; todo en `AvisosPorCorreo` |
| Pruebas | 30 | 33; ninguna de caracterización cambiada |

Y el bloque entero, del legado al estado final:

| | `legado` | `estados/06` |
|---|---|---|
| Código de producción | 561 líneas, 5 clases | 1 097 líneas, 28 clases |
| La clase más grande | `GestorCuentas`, 393 líneas | `Cuenta`, 117 líneas |
| Pruebas | 0 | 33 |
| Defectos conocidos | Seis congelados en `14/01`, y dos que nadie había visto | Ninguno de los ocho |

---

## 9. 🏷️ Lo que costó, y cuándo no

**Lo que costó:**

- **Líneas:** 226 más, la mayor parte en los eventos, el publicador y el decorador de reintentos.
- **Indirección:** un correo ya no sale donde pasa la operación. Para saber qué correos manda un depósito hay que ir de la
  cuenta al evento, del evento al publicador y del publicador al suscriptor.
- **Lectura:** las operaciones están envueltas en lambdas de transacción, y los eventos se juntan en una lista que se
  publica al final. Es más difícil de seguir que una secuencia de sentencias.
- **Tiempo de ejecución:** cada conflicto repite la operación entera, con su espera. Con mucha contención sobre una
  cuenta —una cuenta recaudadora que recibe miles de pagos por minuto—, los reintentos se comen el rendimiento, y el
  bloqueo optimista deja de ser la herramienta.

**Cuándo no:** el bloqueo optimista, cuando los conflictos son la norma y no la excepción: ahí un bloqueo pesimista
(`SELECT … FOR UPDATE`) o serializar las operaciones de cada cuenta en una cola es más barato. Los eventos, cuando hay un
solo efecto secundario que nunca va a crecer: una llamada directa es más honesta. Y `synchronized` en el servicio —la
respuesta que se oye primero— solo ordena los hilos de **una** JVM: con dos instancias de la aplicación detrás de un
balanceador, cada una tendría su propio candado, y la base vería las mismas actualizaciones perdidas.

> **Veredicto:** lo que pasa en el dominio se anota como evento y se publica después de confirmar; lo que se lee para
> después escribir, se escribe solo si nadie lo cambió, y el conflicto se reintenta afuera. La transacción hace atómica una
> operación, la versión la protege de las demás, y ninguna de las dos sola alcanza.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con `synchronized` en el servicio basta" | Ordena los hilos de una JVM; dos instancias de la aplicación siguen perdiendo actualizaciones |
| "Con una transacción ya no se pierden actualizaciones" | Con *read committed*, dos transacciones leen lo mismo y la segunda sobrescribe; aquí, 8 000 de 100 000 |
| "El bloqueo optimista evita los conflictos" | Los detecta; evitar que el usuario los vea es el trabajo de los reintentos |
| "Se reintenta cualquier excepción" | Solo la transitoria: un saldo insuficiente fallará igual en el intento veinte |
| "Los eventos se publican donde ocurren" | Se anotan donde ocurren y se publican después del `commit`; si no, sale el correo de un depósito deshecho |
| "La entidad publica sus eventos" | La entidad los registra; publicarlos es del servicio, que sabe cuándo se confirmó la transacción |
| "Una prueba de concurrencia en verde demuestra que no hay carrera" | Demuestra que no apareció; se corre varias veces y se razona el mecanismo |

---

## 📚 Para profundizar

- **Libro** — Fowler, *Patterns of Enterprise Application Architecture* (Addison-Wesley, 2002), cap. 16, *Optimistic
  Offline Lock*. **El que destaca.**
- **Libro** — Kerievsky, *Refactoring to Patterns* (Addison-Wesley, 2004), cap. 8, *Replace Hard-Coded Notifications with
  Observer*.
- **Libro** — Goetz y otros, *Java Concurrency in Practice* (Addison-Wesley, 2006), cap. 2, "Thread Safety": las acciones
  compuestas de leer, modificar y escribir.
- [Industrial Logic — *Replace Hard-Coded Notifications With Observer*](https://www.industriallogic.com/refactoring-to-patterns/catalog/hardCodedNotificationsWithObserver.html)
- [martinfowler.com — *DomainEvent*](https://martinfowler.com/eaaDev/DomainEvent.html)
- [H2 — *Advanced*](https://www.h2database.com/html/advanced.html): el aislamiento de transacciones y el bloqueo de filas.
- [JEP 441 — *Pattern Matching for switch*](https://openjdk.org/jeps/441): el `switch` exhaustivo sobre tipos sellados.

---

## 🧠 Preguntas

1. ¿Qué es una actualización perdida, y cuántos depósitos se perdieron en `estados/05`? 🟢
2. ¿Por qué los eventos se nombran en pasado? 🟢
3. ¿Por qué una transacción sola no evitó la actualización perdida? 🟡
4. ¿Qué devuelve `executeUpdate` cuando la versión cambió, y qué hace el repositorio con eso? 🟡
5. ¿Por qué los eventos se publican después del `commit` y no dentro de la transacción? 🟡
6. ¿Por qué `EventoDeCuenta` es una interfaz sellada? 🟠
7. ¿Por qué la espera entre reintentos es al azar y crece? 🟠
8. ¿Por qué los reintentos van por fuera de la auditoría? 🟠
9. ¿Por qué `synchronized` en el servicio no resolvería el problema en producción? 🟠
10. Una cuenta recaudadora recibe tres mil pagos por minuto, y los reintentos se disparan. ¿Qué cambias? 🔴

---

## 🧪 Ejercicios

Sobre `estados/06`.

**E1.** Escribe un suscriptor que cuente los eventos por tipo, y la prueba de una transferencia de Ana a Luis. 🟢

**E2.** Usa el repositorio del ejercicio E4 de `14/03` —el que falla al segundo `guardar`— y escribe la prueba que demuestra
que la transferencia ya es atómica: saldos intactos, ningún correo, ningún movimiento. 🟡

**E3.** Sube la prueba de concurrencia a cincuenta hilos y quinientos depósitos. ¿Alcanzan los veinte intentos? Mide cuántos
depósitos fallan. 🟠

**E4.** La idempotencia de los depósitos sigue en memoria. Hazla durable: el mismo pago aplicado desde dos instancias del
gestor debe entrar una vez. Prueba también que dos transferencias iguales seguidas siguen funcionando. 🔴

---

**Anterior:** [`05` — Chain y Decorator](05-chain-y-decorator.md) · **Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`08/03` — Concurrencia offline](../08-fowler-presentacion-distribucion-y-base/03-concurrencia-offline.md)
