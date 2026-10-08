# 04 — Strategy y State

> Sacas las comisiones de los dos `switch` por tipo de cuenta a una política por tipo (Strategy), y el ciclo de vida de la
> cuenta de dos *flags* a un `EstadoCuenta` con sus transiciones (State). Corriges así los dos defectos de estado que congeló
> `14/01`: la transferencia que acredita una cuenta cerrada y la cuenta cerrada y bloqueada a la vez. Terminas con
> `laboratorio/estados/04/`. Parte de `estados/03`. Ejercita [`06/01` — Strategy](../06-comportamiento/01-strategy.md),
> [`06/06` — State](../06-comportamiento/06-state.md), [`09/03` — Type Object](../09-ddd-tactico-y-otros/03-specification-null-object-y-type-object.md)
> y [`13/03` — Refactorizar hacia patrones](../13-patrones-en-la-practica/03-refactorizar-hacia-patrones.md). Opcional; reglas en
> §13.2 de la guía del corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--una-política-por-tipo) · [5](#5--paso-2--el-tipo-deja-de-ser-un-string) · [6](#6--paso-3--un-estado-en-lugar-de-dos-flags) · [7](#7--paso-4--la-cuenta-le-pregunta-a-su-estado) · [8](#8--evidencia) · [9](#9-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

Partir el God Object dejó a la vista lo que antes se perdía entre cuatrocientas líneas. En `ServicioMovimientos` hay dos
métodos uno debajo del otro:

```java
private Dinero comisionDeRetiro(Cuenta c, Dinero importe) {
    switch (c.getTipo()) {
        case "AHORROS":
            return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.cero(c.getMoneda());
        case "CORRIENTE":
            return c.getMoneda() == Moneda.USD ? Dinero.de("2.50", Moneda.USD) : Dinero.de("1500", Moneda.COP);
        case "NOMINA":
            return importe.esMayorQue(Dinero.de("2000000", Moneda.COP)) ? importe.por("0.004") : Dinero.cero(Moneda.COP);
        default:
            throw new IllegalStateException("tipo desconocido " + c.getTipo());
    }
}
// comisionDeTransferencia: el mismo switch, con 1000 en lugar de 1500
```

Y en la cuenta, dos *flags* que cada operación consulta a su manera:

```java
private boolean bloqueada;
private boolean cerrada;
```

- Un tipo de cuenta nuevo son **dos** `switch` que editar y un `default` que solo avisa al ejecutar. Es *Repeated
  Switches*, el *smell* de [`12/01`](../12-antipatrones/01-code-smells-dentro-de-una-clase.md).
- Dos *flags* admiten cuatro combinaciones, y el negocio tiene tres estados. La cuarta —cerrada **y** bloqueada— existe
  porque nada la impide, y `14/01` la congeló.
- Cada operación decide sola qué *flag* mirar: el retiro mira las dos, el depósito solo `cerrada`, la transferencia mira
  las dos del origen y solo `bloqueada` del destino. De ahí sale el defecto de la cuenta cerrada que recibe dinero.

---

## 2. 🧰 Punto de partida

Parte de `estados/03`. Lo que cambia al terminar:

```text
estados/04/src/
├── main/java/banco/
│   ├── PoliticaComision.java   nuevo: la interfaz Strategy
│   ├── ComisionFija.java       nuevo: un valor por operación en pesos; 2,50 en dólares
│   ├── ComisionNomina.java     nuevo: el 0,4 % desde el peso siguiente a 2 000 000
│   ├── TipoCuenta.java         nuevo: el enum que sabe su política
│   ├── EstadoCuenta.java       nuevo: el enum State, con las transiciones
│   ├── Cuenta.java             tipo y estado tipados; pregunta a su estado
│   ├── RepositorioCuentas.java una columna estado en lugar de dos booleanas
│   ├── BaseDatos.java          el esquema, con estado VARCHAR(10)
│   └── ServicioMovimientos.java sin switch y sin flags
└── test/java/banco/
    ├── CaracterizacionTest.java   dos pruebas cambiadas, nombradas abajo
    └── EstadoCuentaTest.java      nuevo: transiciones y políticas, sin base de datos
```

---

## 3. 🩺 El defecto, reproducido

Lo que el negocio quiere, escrito en una clase aparte y corrido contra `estados/03`:

```java
@Test
void unaCuentaCerradaNoRecibeTransferencias() {
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.transferir("CTA-0001", "CTA-0005", 10_000));
    assertEquals("la cuenta destino CTA-0005 está cerrada", e.getMessage());
}

@Test
void unaCuentaCerradaNoSeBloquea() {
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.bloquear("CTA-0005", "revisión"));
    assertEquals("una cuenta cerrada no se puede bloquear", e.getMessage());
}
```

```text
[ERROR] Tests run: 2, Failures: 2, Errors: 0, Skipped: 0 <<< FAILURE! -- in banco.DefectosDeEstadoTest
[ERROR] banco.DefectosDeEstadoTest.unaCuentaCerradaNoSeBloquea <<< FAILURE!
org.opentest4j.AssertionFailedError: Expected java.lang.RuntimeException to be thrown, but nothing was thrown.
[ERROR] banco.DefectosDeEstadoTest.unaCuentaCerradaNoRecibeTransferencias <<< FAILURE!
org.opentest4j.AssertionFailedError: Expected java.lang.RuntimeException to be thrown, but nothing was thrown.
```

- `CTA-0005` es una cuenta de Carmen en pesos, abierta con saldo cero y cerrada en el `@BeforeEach`.
- Los mensajes se eligen **antes** de escribir el código, siguiendo la forma de los que ya existen ("la cuenta destino …
  está bloqueada"). Son parte de la API, y elegirlos en la prueba obliga a pensarlos.

---

## 4. 💻 Paso 1 — Una política por tipo

El destino es el de [`13/03` §3](../13-patrones-en-la-practica/03-refactorizar-hacia-patrones.md#3--hacia-strategy): una
interfaz con el cálculo y una implementación por variante. Con una diferencia que la caracterización obligó a ver: el
retiro y la transferencia de una corriente en pesos **no** cobran lo mismo, y `14/01` lo congeló con el comentario "no es
un defecto conocido". La política tiene, por eso, dos métodos:

```java
// Strategy: cuánto cobra un tipo de cuenta por cada operación.
public interface PoliticaComision {

    Dinero deRetiro(Dinero importe);

    Dinero deTransferencia(Dinero importe);
}
```

```java
// Un valor fijo en pesos por operación; en dólares, siempre 2,50.
public final class ComisionFija implements PoliticaComision {

    private static final Dinero EN_DOLARES = Dinero.de("2.50", Moneda.USD);

    private final Dinero retiro;
    private final Dinero transferencia;

    public ComisionFija(String retiroEnPesos, String transferenciaEnPesos) {
        this.retiro = Dinero.de(retiroEnPesos, Moneda.COP);
        this.transferencia = Dinero.de(transferenciaEnPesos, Moneda.COP);
    }

    @Override
    public Dinero deRetiro(Dinero importe) {
        return importe.moneda() == Moneda.USD ? EN_DOLARES : retiro;
    }

    @Override
    public Dinero deTransferencia(Dinero importe) {
        return importe.moneda() == Moneda.USD ? EN_DOLARES : transferencia;
    }
}
```

- Ahorros y corriente compartían la forma —un valor por operación en pesos, 2,50 en dólares— y cambiaban solo los
  números. Una clase parametrizada las cubre a las dos; dos clases serían duplicación con otro nombre.
- `ComisionNomina` es la otra forma, la del porcentaje con tope, y su `deTransferencia` delega en `deRetiro`: en la
  nómina, las dos cobran igual.
- La política recibe solo el importe, no la cuenta. Es lo que necesita hoy; si mañana una comisión dependiera del saldo,
  la firma cambiaría, y ese cambio se haría cuando llegue.

---

## 5. 💻 Paso 2 — El tipo deja de ser un `String`

¿Quién elige la política? El tipo de la cuenta. Un `enum` que sabe la suya es el *Type Object* mínimo de
[`09/03`](../09-ddd-tactico-y-otros/03-specification-null-object-y-type-object.md#4--type-object), y la forma de `13/03`:

```java
// Cada tipo sabe su política: el switch por tipo desaparece.
public enum TipoCuenta {
    AHORROS(new ComisionFija("0", "0")),
    CORRIENTE(new ComisionFija("1500", "1000")),
    NOMINA(new ComisionNomina());

    private final PoliticaComision comision;

    TipoCuenta(PoliticaComision comision) {
        this.comision = comision;
    }

    public PoliticaComision comision() {
        return comision;
    }
}
```

```java
// en Cuenta
public Dinero comisionDeRetiro(Dinero importe) { return tipo.comision().deRetiro(importe); }

// en ServicioMovimientos.retirar
Dinero comision = c.comisionDeRetiro(importe);
```

- El `default` que lanzaba "tipo desconocido" desapareció: un `TipoCuenta` siempre tiene política, y el compilador no
  deja crear uno sin ella.
- `Cuenta` guarda `TipoCuenta` en lugar de `String`. El repositorio convierte en la frontera con `TipoCuenta.valueOf` y
  `name()`; la columna de la base sigue siendo `VARCHAR`, y ninguna fila cambia.
- La validación de la apertura conserva el mensaje exacto ("tipo de cuenta desconocido: CDT") recorriendo
  `TipoCuenta.values()`, porque `valueOf` lanzaría otro mensaje, y ese mensaje está congelado.

---

## 6. 💻 Paso 3 — Un estado en lugar de dos *flags*

El ciclo de vida tiene tres estados, y cada uno sabe qué permite y a cuál pasa. Es el `enum` con comportamiento por
constante de [`06/06` §5](../06-comportamiento/06-state.md#5--java):

```java
// State: qué permite cada estado y a cuál pasa. Las transiciones viven aquí y solo aquí.
public enum EstadoCuenta {

    ABIERTA {
        @Override void alDepositar(String numero) { }
        @Override void alRetirar(String numero) { }
        @Override void alRecibir(String numero) { }
        @Override EstadoCuenta alBloquear(String numero) { return BLOQUEADA; }
        @Override EstadoCuenta alDesbloquear(String numero) { return ABIERTA; }
        @Override EstadoCuenta alCerrar(String numero, Dinero saldo) {
            if (!saldo.esCero()) throw new IllegalStateException("para cerrar, el saldo debe ser cero");
            return CERRADA;
        }
    },

    BLOQUEADA { /* deposita sí; retira, recibe y cierra, no; desbloquear vuelve a ABIERTA */ },

    CERRADA {
        @Override void alRecibir(String numero) {
            throw new IllegalStateException("la cuenta destino " + numero + " está cerrada");
        }
        @Override EstadoCuenta alBloquear(String numero) {
            throw new IllegalStateException("una cuenta cerrada no se puede bloquear");
        }
        // … y lo mismo para depositar, retirar, desbloquear
    };

    abstract void alDepositar(String numero);
    abstract void alRetirar(String numero);   // vale también para enviar una transferencia
    abstract void alRecibir(String numero);
    abstract EstadoCuenta alBloquear(String numero);
    abstract EstadoCuenta alDesbloquear(String numero);
    abstract EstadoCuenta alCerrar(String numero, Dinero saldo);
}
```

- Los métodos son **abstractos**: cada estado tiene que responder a cada operación, y el compilador lo exige. En `06/06`
  el `enum` usa comportamiento por defecto en la clase y sobrescribe solo lo que cambia; aquí se prefirió que nadie pueda
  olvidar una decisión, al precio de algunas líneas vacías.
- **El estado decide la transición** (`ABIERTA.alBloquear` devuelve `BLOQUEADA`): la variante de la tabla de
  [`06/06` §6](../06-comportamiento/06-state.md#6--variantes-quién-decide-la-transición) que conviene cuando las transiciones
  dependen del estado actual.
- Las reglas del módulo se conservan aunque difieran del capítulo: aquí una cuenta bloqueada **no** se cierra, y sí recibe
  depósitos. El patrón no decide reglas; las ordena.
- Lo que **cambia** a propósito: `CERRADA.alRecibir` y `CERRADA.alBloquear` lanzan, que son los dos defectos. Y una
  decisión nueva, sin prueba de caracterización que la cubriera: desbloquear una cuenta cerrada también se rechaza.

La base acompaña: dos columnas `BOOLEAN` pasan a una `estado VARCHAR(10)`. En un sistema con datos, eso es una migración
con una decisión dentro —qué estado recibe la fila cerrada **y** bloqueada—, que es el ejercicio E3.

---

## 7. 💻 Paso 4 — La cuenta le pregunta a su estado

`Cuenta` cambia sus dos *flags* por un `EstadoCuenta` y delega:

```java
public void depositar(Dinero importe) {
    estado.alDepositar(numero);
    saldo = saldo.mas(importe);
}

public void recibirTransferencia(Dinero importe) {
    estado.alRecibir(numero);
    saldo = saldo.mas(importe);
}

public void bloquear() { estado = estado.alBloquear(numero); }
```

- `recibirTransferencia` deja de ser la excepción que `14/03` conservó a propósito: ahora pregunta al estado, y el
  comentario `DEFECTO CONGELADO` se va con el defecto.
- `isBloqueada()` e `isCerrada()` siguen existiendo, derivados del estado, porque los usa la caracterización. La lógica ya
  no los consulta.

Y el servicio deja de decidir qué *flag* mirar:

```java
// en ServicioMovimientos.transferir
origen.verificarQuePuedeRetirar();
destino.verificarQuePuedeRecibir();
if (origen.getMoneda() != destino.getMoneda()) {
    throw new IllegalArgumentException("las cuentas tienen monedas distintas");
}
```

- El orden de las comprobaciones se conserva: primero el origen, después el destino, después las monedas. Una
  transferencia de una cuenta bloqueada a una cerrada sigue dando el mensaje del origen.

La red, al cerrar el paso: las dos pruebas que congelaban los defectos se cambian, y nada más cae.

| Prueba en `14/01` | Prueba en `14/04` |
|---|---|
| `transferir_aUnaCuentaCerradaSeAcepta` | `transferir_aUnaCuentaCerradaSeRechaza`, con el mensaje y el saldo en cero |
| `bloquear_unaCuentaCerradaLaDejaCerradaYBloqueada` | `bloquear_unaCuentaCerradaSeRechaza`, con el estado `CERRADA` |

```text
[INFO] Compiling 18 source files with javac [debug release 21] to target/classes
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0 -- in banco.EstadoCuentaTest
[INFO] Tests run: 28, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

`EstadoCuentaTest` prueba las transiciones y las políticas **sin base de datos**: `EstadoCuenta.ABIERTA.alBloquear(…)` es
una llamada a un `enum`. Es la ventaja de que la regla viva en un objeto y no en un `if` dentro de un método con SQL.

---

## 8. 🧪 Evidencia

| | `estados/03` | `estados/04` |
|---|---|---|
| Código de producción | 617 líneas, 13 clases | 723 líneas, 18 clases |
| `switch` por tipo | 2 | 0 |
| Literales `"AHORROS"`, `"CORRIENTE"`, `"NOMINA"` en el código | 13, seis de ellos en los `switch` | 1: la regla de la nómina en pesos, en la apertura |
| Consultas a `isBloqueada`/`isCerrada` en los servicios | 5 | 0 |
| Combinaciones de estado posibles | 4 (dos *flags*) | 3 |
| Pruebas | 25 | 28; dos de caracterización cambiadas |
| Defectos congelados que quedan | 3 | 1 (el de `14/05`) |

Crecer 106 líneas por quitar dos `switch` y dos *flags* parece mal negocio. Lo que compran se ve en los ejercicios: un tipo
de cuenta nuevo es **una línea** del `enum` y, si su forma es nueva, una clase; un estado nuevo obliga al compilador a
preguntar, en cada estado, qué pasa con cada operación.

---

## 9. 🏷️ Lo que costó, y cuándo no

**Lo que costó:**

- **Líneas:** 106 más, y cinco archivos nuevos. `EstadoCuenta`, con sus métodos vacíos, es el más largo.
- **Indirección:** para saber cuánto cobra un retiro de nómina hay que ir de `ServicioMovimientos` a `Cuenta`, a
  `TipoCuenta`, a `ComisionNomina`. Antes estaba en un `case`.
- **Lectura:** la tabla completa de "qué permite cada estado" ya no se ve de un vistazo en un método: está repartida en
  tres constantes. Un comentario o una tabla en el `README` del módulo ayudan.
- **Rigidez:** la política recibe solo el importe. Una comisión que dependa del saldo o de la fecha obliga a cambiar la
  interfaz y sus tres implementaciones.

**Cuándo no:** Strategy, cuando hay un solo cálculo que no varía o dos ramas que nunca crecen: un `if` es más honesto.
State, cuando el ciclo de vida tiene dos estados y una transición, o cuando las transiciones son tantas y cambian tan a
menudo que conviene una máquina de estados declarada en una tabla o en configuración (`06/06` §6). Aquí son tres estados,
seis operaciones y dos defectos reales producidos por los *flags*: el patrón se paga.

> **Veredicto:** el `switch` repetido por tipo se vuelve una política que el tipo conoce, y los *flags* que admiten
> combinaciones imposibles se vuelven un estado que decide sus transiciones; los dos patrones se ganaron con defectos
> reales, no con el gusto por el catálogo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un `enum` con un `switch` ya es State" | Es un `enum` con un `switch` afuera; State es que cada constante tenga su comportamiento |
| "Los dos `switch` son duplicados y se unifican en uno" | Diferían en la corriente en pesos (1 500 y 1 000), y la caracterización avisó; la política tiene dos métodos |
| "Una clase por tipo de cuenta, siempre" | Ahorros y corriente comparten la forma; una clase parametrizada evita duplicación con otro nombre |
| "Al pasar a State se corrigen las reglas del capítulo" | Se conservan las del módulo: aquí, la bloqueada no se cierra y sí recibe depósitos |
| "Con dos *flags* basta validar bien en cada operación" | Cada operación validaba a su manera; de ahí salió el defecto. El estado centraliza la decisión |
| "Migrar los *flags* a una columna es mecánico" | Hay que decidir qué estado recibe la combinación imposible, y esa decisión es del negocio |

---

## 📚 Para profundizar

- **Libro** — Kerievsky, *Refactoring to Patterns* (Addison-Wesley, 2004), cap. 7: *Replace Conditional Logic with
  Strategy* y *Replace State-Altering Conditionals with State*. **El que destaca.**
- **Libro** — Gamma, Helm, Johnson y Vlissides, *Design Patterns* (Addison-Wesley, 1994), cap. 5, "Behavioral Patterns",
  secciones "State" y "Strategy".
- **Libro** — Fowler, *Refactoring*, 2.ª ed. (Addison-Wesley, 2018), cap. 10, *Replace Conditional with Polymorphism*.
- [Industrial Logic — *Replace State-Altering Conditionals With State*](https://www.industriallogic.com/refactoring-to-patterns/catalog/alteringConditionalsWithState.html)
- [Industrial Logic — *Replace Conditional Logic With Strategy*](https://www.industriallogic.com/refactoring-to-patterns/catalog/conditionalWithStrategy.html)
- [Java 21 — `Enum`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Enum.html): las constantes con
  cuerpo de clase y `valueOf`.

---

## 🧠 Preguntas

1. ¿Qué *smell* son los dos `switch` de comisiones, y qué refactorización lo quita? 🟢
2. ¿Por qué dos *flags* admiten un estado que el negocio no tiene? 🟢
3. ¿Por qué `PoliticaComision` tiene dos métodos y no uno? 🟡
4. ¿Qué diferencia hay entre `TipoCuenta` con su política y un `enum` con un `switch` afuera? 🟡
5. ¿Por qué los métodos de `EstadoCuenta` son abstractos y no tienen comportamiento por defecto? 🟡
6. ¿Por qué la apertura no usa `TipoCuenta.valueOf` para validar el tipo? 🟠
7. ¿Quién decide la transición en este `EstadoCuenta`, y cuándo convendría que la decidiera la cuenta? 🟠
8. Desbloquear una cuenta cerrada ahora se rechaza, y ninguna prueba cambió por eso. ¿Es un problema? 🟠
9. ¿Qué ganaste al poder probar `EstadoCuenta` sin base de datos? 🟠
10. El negocio pide que la comisión de la corriente baje a 1 200 en el retiro solo para clientes con más de cinco años.
    ¿Dónde entra en este diseño, y qué se rompe? 🔴

---

## 🧪 Ejercicios

Sobre `estados/04`.

**E1.** Añade a `EstadoCuentaTest` la prueba de que una cuenta cerrada no admite depósitos, retiros ni transferencias
entrantes, con el mensaje de esta última. 🟢

**E2.** Añade el tipo `PREMIUM`, que no cobra comisión en ninguna moneda, y la prueba de un retiro en dólares. Di cuántos
archivos tocaste y por qué `ComisionFija` no sirve. 🟡

**E3.** Escribe la migración SQL que pasa una tabla con `bloqueada` y `cerrada` a una sola columna `estado`, y pruébala en H2
con las cuatro combinaciones. Justifica qué estado recibe la fila cerrada y bloqueada. 🟠

**E4.** Llega un requisito: el embargo judicial bloquea también los depósitos, y un desbloqueo normal no lo levanta.
Añade el estado `EMBARGADA` y su prueba. Explica qué hizo el compilador cuando añadiste la operación nueva. 🔴

---

**Anterior:** [`03` — Partir el God Object](03-partir-el-god-object.md) · **Siguiente:** [`05` — Chain y Decorator](05-chain-y-decorator.md) ·
**Relacionado:** [`06/06` — State](../06-comportamiento/06-state.md)
