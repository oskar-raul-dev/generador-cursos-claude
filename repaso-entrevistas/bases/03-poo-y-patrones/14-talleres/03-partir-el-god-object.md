# 03 — Partir el God Object

> Repartes las responsabilidades de `GestorCuentas` en piezas con un solo motivo para cambiar —dos repositorios, la
> auditoría, dos servicios—, devuelves a `Cuenta` las reglas que solo dependen de ella, y dejas a `GestorCuentas` como la
> fachada que ya usaban todos. Sin cambiar un solo comportamiento: las veinticinco pruebas de `estados/02` pasan sin tocar
> una línea. Terminas con `laboratorio/estados/03/`. Ejercita [`12/03` — Antipatrones de diseño OO](../12-antipatrones/03-antipatrones-de-diseno-oo.md),
> [`12/02` — *Code smells* entre clases](../12-antipatrones/02-code-smells-entre-clases.md),
> [`03/03` — GRASP](../03-principios-de-diseno/03-grasp.md), [`05/04` — Facade](../05-estructurales/04-facade.md) y
> [`07/02` — Fuentes de datos](../07-fowler-dominio-y-datos/02-fuentes-de-datos.md). Opcional; reglas en §13.2 de la guía del
> corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--el-sql-una-sola-vez) · [5](#5--paso-2--las-reglas-vuelven-a-la-cuenta) · [6](#6--paso-3--dos-servicios-por-motivo-de-cambio) · [7](#7--paso-4--la-fachada-y-el-único-new) · [8](#8--evidencia) · [9](#9-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

El taller anterior tuvo que dar un paso grande: cambiar el tipo del dinero tocó cada método del gestor a la vez, porque
el dinero no vivía en ningún sitio propio. Ese es el costo diario de un God Object, y no solo el de una refactorización:

```java
public void retirar(String numero, double monto) {
    try (Connection con = BaseDatos.abrir()) {
        PreparedStatement ps = con.prepareStatement(
                "SELECT numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor FROM cuenta WHERE numero = ?");
        // … nueve líneas de mapeo, idénticas a las de depositar, transferir (dos veces) y consultarCuenta
        // … validaciones, el switch de comisiones, el UPDATE, el INSERT del movimiento
        auditar(con, "RETIRO", numero + " " + importe + " comisión " + comision);
        if (!importe.esMenorQue(Dinero.de("1000000", c.getMoneda()))) {
            new Notificador().enviar(c.getEmail(), "Retiraste " + importe);
        }
    }
}
```

- Un método de 71 líneas hace siete cosas: abrir la conexión, leer la cuenta, validar, calcular la comisión, escribir,
  auditar y avisar. Cualquiera de esas siete puede cambiar por una razón distinta.
- `GestorCuentas` es el God Object de [`12/03` §2](../12-antipatrones/03-antipatrones-de-diseno-oo.md#2-️-god-object): sabe
  de SQL, de reglas, de correos y de auditoría, y todo el que cambia algo del módulo cambia esta clase.
- `Cuenta` es lo contrario: datos con *getters* y *setters*, un modelo anémico. Las reglas que solo dependen de ella —"una
  cuenta cerrada no recibe depósitos", "no se debita más que el saldo"— viven fuera, en el gestor.

---

## 2. 🧰 Punto de partida

Parte de `estados/02` y se corre igual que siempre. Al terminar, el paquete `banco` tiene cinco clases nuevas y dos
transformadas:

```text
estados/03/src/main/java/banco/
├── RepositorioCuentas.java       nuevo: el SQL y el mapeo de cuenta, una sola vez
├── RepositorioMovimientos.java   nuevo: el INSERT y el SELECT de movimientos
├── Auditoria.java                nuevo: lo que era el método privado auditar
├── ServicioCuentas.java          nuevo: abrir, bloquear, desbloquear, cerrar
├── ServicioMovimientos.java      nuevo: depositar, retirar, transferir, extracto
├── Cuenta.java                   con comportamiento; sin setters
└── GestorCuentas.java            Facade: 50 líneas que delegan
```

`src/test` **no cambia**. Es la regla del taller: si una prueba de caracterización hay que tocarla, el paso cambió
comportamiento y no era una refactorización.

---

## 3. 🩺 El defecto, reproducido

El defecto de este taller no se ve en una prueba: se ve en **cuántos sitios hay que tocar para un cambio**. Es el *smell*
*Shotgun Surgery* de [`12/02`](../12-antipatrones/02-code-smells-entre-clases.md): un cambio pequeño que obliga a muchas
ediciones pequeñas. Medido sobre `estados/02` con `grep`:

```bash
grep -rF 'SELECT numero, titular' estados/02/src/main/java | wc -l
grep -rF 'new Notificador()' estados/02/src/main/java | wc -l
```

- `grep -r` busca en todo el árbol; `-F` toma el patrón como texto literal, sin interpretarlo como expresión regular (los
  paréntesis de `new Notificador()` lo romperían).
- `wc -l` cuenta las líneas encontradas: una por aparición.

| Qué se busca | Apariciones en `estados/02` | Qué significa |
|---|---|---|
| `SELECT numero, titular` | 5 | Una columna nueva en `cuenta` son cinco consultas y cinco mapeos que editar |
| `getBoolean("es_menor")` | 5 | El mapeo, copiado entero cinco veces |
| `new Notificador()` | 6 | Cambiar cómo se avisa —o probarlo— es tocar seis sitios |
| `BaseDatos.abrir()` en el gestor | 10 | Cada método gestiona su conexión a mano |
| `LocalDateTime.now()` | 5 | El reloj, imposible de fijar desde una prueba |

La prueba de que el costo es real ya ocurrió: en `14/02`, `getDouble("saldo")` hubo que cambiarlo en cinco sitios, y el
paso no pudo ser pequeño.

---

## 4. 💻 Paso 1 — El SQL una sola vez

El primer movimiento es el más mecánico y el que más líneas quita: *Extract Class* del acceso a datos de la cuenta. Las
cinco copias del `SELECT` y del mapeo se vuelven un método:

```java
// El único sitio que sabe cómo se guarda una cuenta.
public class RepositorioCuentas {

    private static final String COLUMNAS = "numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, es_menor";

    public Cuenta buscar(String numero) {
        try (Connection con = BaseDatos.abrir();
             PreparedStatement ps = con.prepareStatement("SELECT " + COLUMNAS + " FROM cuenta WHERE numero = ?")) {
            ps.setString(1, numero);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new IllegalArgumentException("no existe la cuenta " + numero);
            Moneda moneda = Moneda.valueOf(rs.getString("moneda"));
            return new Cuenta(rs.getString("numero"), rs.getString("titular"), rs.getString("email"),
                    rs.getString("tipo"), moneda, new Dinero(rs.getBigDecimal("saldo"), moneda),
                    rs.getBoolean("bloqueada"), rs.getBoolean("cerrada"), rs.getBoolean("es_menor"));
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public void insertar(Cuenta c) { /* el INSERT, con las mismas COLUMNAS */ }

    public void guardar(Cuenta c) { /* un UPDATE de saldo, bloqueada y cerrada */ }
}
```

- Es un **Repository** en su forma más simple, o un *Table Data Gateway* con objetos de dominio a la salida: la discusión de
  nombres está en [`07/02`](../07-fowler-dominio-y-datos/02-fuentes-de-datos.md). Lo que importa aquí es que el SQL de la
  cuenta vive en un sitio.
- `guardar` reemplaza a dos sentencias del legado: el `UPDATE` del saldo, repetido en tres métodos, y el `UPDATE` de los
  *flags* de `guardarFlags`. Escribir siempre las tres columnas es más simple y, con una fila por cuenta, igual de barato.
- El mensaje `"no existe la cuenta " + numero` es el mismo de antes, carácter por carácter: lo congela
  `CaracterizacionTest` a través de `consultarCuenta`.
- `RepositorioMovimientos` y `Auditoria` salen igual: el `INSERT` del movimiento estaba copiado cuatro veces, y el de
  auditoría ya era un método privado que solo había que mover.

---

## 5. 💻 Paso 2 — Las reglas vuelven a la cuenta

Con el mapeo en el repositorio, `Cuenta` ya no necesita *setters*: se construye entera. Y puede recibir las reglas que
solo dependen de su propio estado. Es *Move Function* hacia la clase que tiene los datos —*Information Expert*, en el
vocabulario de GRASP de [`03/03`](../03-principios-de-diseno/03-grasp.md)—, o *tell, don't ask*: en lugar de preguntarle
a la cuenta su saldo para decidir afuera, se le pide que debite.

```java
public void depositar(Dinero importe) {
    if (cerrada) {
        throw new IllegalStateException("la cuenta " + numero + " está cerrada");
    }
    saldo = saldo.mas(importe);
}

// DEFECTO CONGELADO hasta 14/04: a diferencia de depositar, no mira si la cuenta está cerrada
public void recibirTransferencia(Dinero importe) {
    saldo = saldo.mas(importe);
}

public void debitar(Dinero importe, Dinero comision) {
    if (saldo.esMenorQue(importe.mas(comision))) {
        throw new IllegalStateException("saldo insuficiente en " + numero);
    }
    saldo = saldo.menos(importe).menos(comision);
}
```

- **`recibirTransferencia` existe para no arreglar nada.** Lo natural sería que la transferencia usara `depositar`, que ya
  rechaza la cuenta cerrada. Pero eso corregiría el defecto que `14/01` congeló en
  `transferir_aUnaCuentaCerradaSeAcepta`, y este taller promete no cambiar comportamiento. El método lleva el comentario que
  dice cuándo se va.
- `cerrar()` se mueve igual, con sus dos validaciones en el mismo orden: primero bloqueada, después saldo distinto de cero.
  El orden importa, porque decide qué mensaje ve quien llama cuando fallan las dos.
- Lo que **no** se mueve todavía: la validación de bloqueada y cerrada en el retiro, el tope de los menores y las
  comisiones. Dependen de reglas que `14/04` y `14/05` van a rehacer, y moverlas ahora sería moverlas dos veces.

---

## 6. 💻 Paso 3 — Dos servicios, por motivo de cambio

Lo que queda del gestor se parte por **quién pide los cambios**. El ciclo de vida de la cuenta —abrir, bloquear, cerrar—
cambia cuando cambia la regulación de apertura o los procesos de embargo; los movimientos de dinero cambian cuando cambian
las tarifas o los productos. Dos servicios:

```java
public class ServicioMovimientos {

    private final RepositorioCuentas cuentas;
    private final RepositorioMovimientos movimientos;
    private final Auditoria auditoria;
    private final Notificador notificador;
    // … la caché de extractos y los depósitos recientes, que son de este servicio

    public void retirar(String numero, double monto) {
        Cuenta c = cuentas.buscar(numero);
        // … las validaciones de siempre, en el mismo orden
        Dinero comision = comisionDeRetiro(c, importe);
        c.debitar(importe, comision);
        cuentas.guardar(c);
        movimientos.registrar(new Movimiento(numero, "RETIRO", importe, comision, null, LocalDateTime.now()));
        cacheExtractos.remove(numero);
        auditoria.registrar("RETIRO", numero + " " + importe + " comisión " + comision);
        if (!importe.esMenorQue(Dinero.de("1000000", c.getMoneda()))) {
            notificador.enviar(c.getEmail(), "Retiraste " + importe);
        }
    }
}
```

- El método bajó de 71 a 23 líneas sin perder un paso. Lo que se fue a otro sitio fue la conexión, el SQL y el mapeo.
- Las dependencias llegan **por constructor**: el servicio no hace `new` de nada. Es la inyección de dependencias de
  [`04/06`](../04-creacionales/06-inyeccion-de-dependencias-e-ioc.md), sin contenedor.
- Los dos `switch` de comisiones se extrajeron a `comisionDeRetiro` y `comisionDeTransferencia` (*Extract Function*), y se
  quedaron como estaban. Son el punto de partida de `14/04`: ahora están a la vista, uno debajo del otro.
- La caché y `recientes` se mueven con el servicio que los usa. Siguen siendo estado en memoria, con los límites que la
  pregunta 10 de `14/02` descubrió.

---

## 7. 💻 Paso 4 — La fachada, y el único `new`

`GestorCuentas` no desaparece: lo usan las pruebas y, en un sistema real, todos los que llamaban al módulo. Se queda como
**Facade** ([`05/04`](../05-estructurales/04-facade.md)), con la misma API y nada de lógica:

```java
// Facade: la misma API de siempre, para los que ya la llaman. Por dentro, delega.
public class GestorCuentas {

    private final ServicioCuentas servicioCuentas;
    private final ServicioMovimientos servicioMovimientos;

    // el único sitio donde se crean las piezas
    public GestorCuentas() {
        this(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(), new Notificador());
    }

    public GestorCuentas(RepositorioCuentas cuentas, RepositorioMovimientos movimientos, Auditoria auditoria,
                         Notificador notificador) {
        this.servicioCuentas = new ServicioCuentas(cuentas, auditoria, notificador);
        this.servicioMovimientos = new ServicioMovimientos(cuentas, movimientos, auditoria, notificador);
    }

    public void retirar(String numero, double monto) { servicioMovimientos.retirar(numero, monto); }
    // … un método por operación, todos de una línea
}
```

- El constructor sin argumentos es la **raíz de composición**: el único sitio con `new` de las piezas. Las pruebas siguen
  llamando a `new GestorCuentas()` y no se enteran del cambio.
- El segundo constructor abre la puerta a probar con piezas falsas —un notificador que no imprime, una auditoría en
  memoria— sin tocar el código. Ninguna prueba lo usa todavía; `14/05` sí.
- La fachada es también el plan de salida: los llamadores nuevos pueden usar los servicios directamente, y cuando ninguno
  use la fachada, se borra. Hasta entonces, cuesta 50 líneas que no hacen nada.

La corrida, sin una línea de prueba cambiada:

```text
[INFO] Compiling 13 source files with javac [debug release 21] to target/classes
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
[INFO] Tests run: 25, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

---

## 8. 🧪 Evidencia

| | `estados/02` | `estados/03` |
|---|---|---|
| Código de producción | 606 líneas, 8 clases | 617 líneas, 13 clases |
| La clase más grande | `GestorCuentas`, 403 líneas | `ServicioMovimientos`, 133 líneas |
| Copias del `SELECT` y del mapeo de cuenta | 5 | 1 |
| `new Notificador()` | 6 | 1, en la raíz de composición |
| Conexiones abiertas a mano en la lógica | 10 | 0 (6, todas en los repositorios y la auditoría) |
| Pruebas cambiadas | — | 0 de 25 |

El total de líneas apenas se movió: lo que se quitó de duplicación se fue en cinco clases nuevas, sus constructores y la
fachada. Partir un God Object **no** lo hace más corto; lo hace **localizable**: una columna nueva en
`cuenta` es ahora un cambio en `RepositorioCuentas` y en el constructor de `Cuenta`.

---

## 9. 🏷️ Lo que costó, y cuándo no

**Lo que costó:**

- **Líneas:** once más en total, y cinco archivos nuevos que hay que conocer.
- **Indirección:** una llamada a `retirar` atraviesa ahora la fachada, el servicio, el repositorio y la cuenta. Para
  entender una operación hay que abrir cuatro archivos en lugar de uno.
- **Lectura:** el que llega busca "dónde se retira" y encuentra un método de una línea en la fachada. Los nombres de los
  servicios tienen que bastar para orientarse.
- **Rigidez:** la fachada congela la API vieja, con su `double`. Quitarla exige migrar a todos los llamadores.
- **Tiempo de ejecución:** ninguno medible; las mismas consultas, las mismas conexiones.

**Cuándo no:** cuando la clase grande es grande pero **cohesiva** —un parser, una máquina de estados con muchos estados—:
el tamaño no es el *smell*, lo son los motivos de cambio mezclados. Tampoco se parte un módulo que se va a reemplazar
entero, y no se parte sin la red: con `estados/02` sin pruebas, este taller habría sido una reescritura.

> **Veredicto:** un God Object se parte por motivos de cambio, en pasos que no tocan las pruebas: primero el acceso a
> datos, después las reglas que vuelven a su dueño, después los servicios, y al final una fachada que conserva la API
> mientras alguien la use.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un God Object se parte reescribiéndolo" | Se parte en pasos que no cambian comportamiento, con la caracterización en verde en cada uno |
| "Si la clase tiene más de N líneas, hay que partirla" | Se parte por motivos de cambio mezclados, no por tamaño |
| "Partir la clase reduce el código" | Lo redistribuye: aquí, 606 líneas pasaron a 617; lo que baja es lo que hay que tocar por cambio |
| "Al partirla, aprovecho y corrijo lo que veo" | Mezcla refactorización con cambio de comportamiento; aquí `recibirTransferencia` conserva un defecto a propósito |
| "La fachada sobra: que todos usen los servicios" | Es lo que permite partir sin romper a los llamadores; se borra cuando ya no la usa nadie |
| "Pasar las dependencias por constructor es para usar Spring" | Es para que se vean y se puedan reemplazar; aquí no hay contenedor |
| "El modelo anémico se arregla moviendo todas las reglas a la entidad" | Se mueven las que dependen solo de ella; las que cruzan cuentas o servicios se quedan fuera |

---

## 📚 Para profundizar

- **Libro** — Fowler, *Refactoring*, 2.ª ed. (Addison-Wesley, 2018), cap. 7, *Extract Class*, y cap. 8, *Move Function*.
  **El que destaca.**
- **Libro** — Feathers, *Working Effectively with Legacy Code* (Prentice Hall, 2004), cap. 20, "This Class Is Too Big and
  I Don't Want It to Get Any Bigger".
- **Libro** — Larman, *Applying UML and Patterns*, 3.ª ed. (Prentice Hall, 2004), cap. 17, GRASP: *Information Expert*.
- [refactoring.com — *Extract Class*](https://refactoring.com/catalog/extractClass.html)
- [refactoring.com — *Move Function*](https://refactoring.com/catalog/moveFunction.html)
- [martinfowler.com — *AnemicDomainModel*](https://martinfowler.com/bliki/AnemicDomainModel.html)

---

## 🧠 Preguntas

1. ¿Qué es *Shotgun Surgery*, y cómo se midió en `estados/02`? 🟢
2. ¿Qué es una raíz de composición, y dónde está en `estados/03`? 🟢
3. ¿Por qué el taller exige que ninguna prueba cambie? 🟡
4. ¿Qué diferencia hay entre partir una clase por tamaño y partirla por motivos de cambio? 🟡
5. ¿Por qué `Cuenta` tiene `recibirTransferencia` en lugar de usar `depositar` en la transferencia? 🟡
6. ¿Por qué el orden de las validaciones de `cerrar()` se conservó igual? 🟠
7. ¿Por qué no se movieron a `Cuenta` la validación de bloqueada y el tope de los menores? 🟠
8. El total de líneas casi no cambió. ¿Qué se ganó, medido? 🟠
9. ¿Cuándo se borra la fachada `GestorCuentas`, y qué hay que hacer antes? 🟠
10. Un compañero propone partir el gestor en una clase por operación: `Depositar`, `Retirar`, `Transferir`. Compárala con
    los dos servicios del taller. 🔴

---

## 🧪 Ejercicios

Sobre `estados/03`.

**E1.** Añade la columna `sucursal` a la tabla `cuenta` (con un valor por defecto) y a `Cuenta`. Cuenta cuántos archivos
tocaste y compáralo con los que habría que tocar en `estados/02`. 🟢

**E2.** Escribe una prueba que use el segundo constructor de `GestorCuentas` con un `Notificador` propio que solo cuente los
correos, sin la lista estática. 🟡

**E3.** Inyecta un `java.time.Clock` en `ServicioMovimientos` y escribe la prueba que fija la fecha de un depósito. 🟠

**E4.** Al partir el gestor, `transferir` dejó de usar una sola conexión para los dos `UPDATE` y pasó a abrir una por
operación. ¿Cambió el comportamiento? Escribe la prueba que lo responda, o explica por qué no se puede escribir. 🔴

---

**Anterior:** [`02` — Igualdad, hash e inmutabilidad](02-igualdad-hash-e-inmutabilidad.md) · **Siguiente:** [`04` — Strategy y State](04-strategy-y-state.md) ·
**Relacionado:** [`12/03` — Antipatrones de diseño OO](../12-antipatrones/03-antipatrones-de-diseno-oo.md)
