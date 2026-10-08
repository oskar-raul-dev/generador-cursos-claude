# 02 — Igualdad, hash e inmutabilidad

> Sacas el dinero del `double` a un `Dinero` inmutable, y arreglas las dos igualdades rotas del legado: la del depósito que
> se aplica dos veces y la de la caché que devuelve un extracto viejo. Terminas con `laboratorio/estados/02/`: tres defectos
> corregidos, cuatro pruebas de caracterización cambiadas a propósito y una clase de pruebas nueva para `Dinero`. Parte de
> `estados/01`. Ejercita [`01/02` — Igualdad, identidad y hash](../01-modelo-de-objetos/02-igualdad-identidad-y-hash.md),
> [`01/03` — Inmutabilidad](../01-modelo-de-objetos/03-inmutabilidad-y-objetos-especiales.md),
> [`02/06` — Entidades, valores y primitivos](../02-modelado-oo/06-entidades-valores-y-primitivos.md) y
> [`08/05` — Patrones base](../08-fowler-presentacion-distribucion-y-base/05-patrones-base.md). Opcional; reglas en §13.2 de la
> guía del corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--dinero) · [5](#5--paso-2--el-dinero-entra-y-las-igualdades-se-arreglan) · [6](#6--paso-3--lo-que-dijo-la-red) · [7](#7--evidencia) · [8](#8-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

Los seis defectos que congeló [`14/01`](01-caracterizacion.md) tienen dueños distintos. Tres son de **igualdad**, y los tres
nacen de la misma pregunta mal respondida: *¿cuándo son iguales dos de estos?*

```java
// Movimiento: equals por cuenta, tipo, monto y referencia… y hashCode heredado de Object
@Override
public boolean equals(Object o) { /* … */ }

// Cuenta: equals y hashCode "generados por el IDE, con todos los campos", saldo incluido
return Objects.hash(numero, titular, email, tipo, moneda, saldo, bloqueada, cerrada, esMenor);

// y el dinero, en double
private double saldo;
```

- `Movimiento` rompe el contrato de `hashCode`: dos movimientos iguales dan hashes distintos, y el `HashSet` que debía
  frenar el doble abono no los encuentra.
- `Cuenta` cumple el contrato, pero con la respuesta equivocada: dice que una cuenta deja de ser la misma cuando cambia su
  saldo. Usada como clave de un mapa, es la clave mutable de la autopsia de `01/02`.
- `double` no es un error de igualdad, pero vive al lado: el 0,4 % de 2 500 000,10 da 10 000,0004, y nadie decide dónde
  redondear.

Las tres preguntas tienen respuesta en el corpus. Lo que este taller añade es **cambiarlas en un código que ya funciona**,
con la caracterización avisando de cada consecuencia.

---

## 2. 🧰 Punto de partida

Parte de tu copia de `estados/01` —o de la tuya, si hiciste el taller 01— y se corre igual:

```bash
docker run --rm -v "$PWD":/trabajo -w /trabajo -v "$HOME/.m2":/root/.m2 \
  maven:3.10.0-eclipse-temurin-21 mvn -B test
```

Lo que cambia al cerrar el taller:

```text
estados/02/src/
├── main/java/banco/
│   ├── Moneda.java          nuevo: COP y USD
│   ├── Dinero.java          nuevo: el Value Object
│   ├── ClaveDeposito.java   nuevo: lo que identifica un depósito reintentado
│   ├── Movimiento.java      ahora un record, con Dinero
│   ├── Cuenta.java          igualdad por número; saldo en Dinero
│   ├── BaseDatos.java       DOUBLE → DECIMAL(19, 2)
│   └── GestorCuentas.java   usa todo lo anterior; el SQL duplicado sigue (es de 14/03)
└── test/java/banco/
    ├── CaracterizacionTest.java   siete pruebas cambiadas, todas nombradas abajo
    └── DineroTest.java            nuevo
```

---

## 3. 🩺 El defecto, reproducido

Antes de tocar el código de producción, escribe lo que el negocio **quiere**, en una clase aparte, y míralo fallar contra
`estados/01`:

```java
@Test
void elMismoPagoDosVecesSeAplicaUnaVez() {
    gestor.depositar("CTA-0001", 80_000, "PSE-7781");
    gestor.depositar("CTA-0001", 80_000, "PSE-7781");
    assertEquals(1_580_000.0, gestor.consultarSaldo("CTA-0001"));
}

@Test
void elExtractoVeLosMovimientosAunqueElSaldoVuelva() {
    gestor.extracto("CTA-0001");
    gestor.depositar("CTA-0001", 100_000, null);
    gestor.retirar("CTA-0001", 100_000);
    assertEquals(2, gestor.extracto("CTA-0001").size());
}

@Test
void laComisionDeNominaSeRedondeaAlCentavo() {
    gestor.abrirCuenta("CTA-0004", "Ana Rojas Medina", "ana.rojas@example.com", "NOMINA", "COP", 5_000_000, false);
    gestor.retirar("CTA-0004", 2_500_000.10);
    assertEquals(2_489_999.90, gestor.consultarSaldo("CTA-0004"));
}
```

```text
[ERROR] Tests run: 3, Failures: 3, Errors: 0, Skipped: 0 <<< FAILURE! -- in banco.DefectosDeIgualdadTest
org.opentest4j.AssertionFailedError: expected: <2489999.9> but was: <2489999.8996>
org.opentest4j.AssertionFailedError: expected: <1580000.0> but was: <1660000.0>
org.opentest4j.AssertionFailedError: expected: <2> but was: <0>
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
```

- Las tres fallan **por el motivo esperado**: el número que se ve es el del defecto congelado en `14/01`. Una prueba que
  falla por otra razón —una excepción, un error de compilación— no demuestra nada.
- Son el espejo de tres pruebas de caracterización. Al terminar el taller las reemplazan: la clase aparte desaparece y la
  suite queda con una sola prueba por comportamiento.

---

## 4. 💻 Paso 1 — `Dinero`

El primer paso no toca el gestor: crea el tipo y lo prueba solo. Es la forma de `02/06` con dos simplificaciones del
laboratorio —un `enum` de dos monedas en lugar de `Currency`, y la escala fija en dos decimales—:

```java
public record Dinero(BigDecimal monto, Moneda moneda) {

    public Dinero {
        Objects.requireNonNull(monto, "monto");
        Objects.requireNonNull(moneda, "moneda");
        monto = monto.setScale(2, RoundingMode.HALF_EVEN);
    }

    public static Dinero de(String monto, Moneda moneda) {
        return new Dinero(new BigDecimal(monto), moneda);
    }

    // la frontera con el código que todavía habla double: valueOf usa la representación decimal corta
    public static Dinero de(double monto, Moneda moneda) {
        return new Dinero(BigDecimal.valueOf(monto), moneda);
    }

    public Dinero mas(Dinero otro) {
        return new Dinero(monto.add(mismaMoneda(otro).monto), moneda);
    }

    // multiplica y redondea al centavo, a la par (HALF_EVEN)
    public Dinero por(String factor) {
        return new Dinero(monto.multiply(new BigDecimal(factor)), moneda);
    }
}
```

- El constructor compacto **normaliza la escala**. Sin eso, el `equals` del `record` —que delega en `BigDecimal.equals`—
  diría que 10,0 y 10,00 son distintos, porque `BigDecimal.equals` compara también la escala (ver `01/02` §8).
- `de(double)` usa `BigDecimal.valueOf`, que parte del `String` corto del `double` (`"0.1"`), y no `new BigDecimal(0.1)`,
  que arrastra el error binario. Existe solo porque la fachada del gestor todavía recibe `double`; adentro no se usa.
- `por(String)` recibe el factor como texto por la misma razón: `0.004` como `double` ya no es 0,004.
- `menos`, `cero`, `esMenorQue`, `esMayorQue`, `esCero` y `toString` completan la clase, con 65 líneas.

Y su prueba, que fija las decisiones que se tomaron:

```java
@Test
void diezYDiezConCeroSonElMismoDinero() {
    Dinero a = Dinero.de("10.0", Moneda.COP);
    Dinero b = Dinero.de("10.00", Moneda.COP);
    assertEquals(a, b);
    assertEquals(1, Set.of(a).size());
    assertEquals(a.hashCode(), b.hashCode());
}

@Test
void elPorcentajeSeRedondeaAlCentavoALaPar() {
    assertEquals(Dinero.de("10000.00", Moneda.COP), Dinero.de("2500000.10", Moneda.COP).por("0.004"));
    assertEquals(Dinero.de("0.02", Moneda.COP), Dinero.de("0.025", Moneda.COP));   // HALF_EVEN: al par
    assertEquals(Dinero.de("0.04", Moneda.COP), Dinero.de("0.035", Moneda.COP));
}
```

- `Set.of(a)` con un elemento parece poca cosa, pero obliga a pasar por `hashCode`: es la prueba que `Movimiento` nunca tuvo.
- `HALF_EVEN` (el redondeo bancario) lleva el 5 al dígito par: 0,025 → 0,02 y 0,035 → 0,04. Con `HALF_UP` las dos subirían, y
  sobre millones de comisiones el sesgo se nota.

```text
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
```

---

## 5. 💻 Paso 2 — El dinero entra, y las igualdades se arreglan

Este paso es **grande**, y conviene decir por qué: cambiar el tipo del dinero toca cada método del gestor a la vez, porque
el God Object no tiene otro sitio donde viva el dinero. Con el gestor ya partido (`14/03`) habría sido un cambio por clase.
Son cuatro cambios que se dan juntos:

**El esquema.** `saldo`, `monto` y `comision` pasan de `DOUBLE` a `DECIMAL(19, 2)`, y el gestor lee y escribe con
`getBigDecimal` y `setBigDecimal`.

**El movimiento, inmutable.** Un `record` trae `equals` y `hashCode` coherentes por construcción, con todos sus componentes:

```java
public record Movimiento(String numeroCuenta, String tipo, Dinero monto, Dinero comision, String referencia,
                         LocalDateTime fecha) { /* toString, igual que antes pero con Dinero */ }
```

**La clave del depósito, separada.** El `record` de `Movimiento` compara también la fecha y la comisión, así que ya no
sirve para detectar el reintento: dos intentos de la pasarela tienen fechas distintas. La identidad del depósito es otra
cosa, y merece su propio tipo:

```java
// Lo que identifica a un depósito que la pasarela puede reintentar.
public record ClaveDeposito(String numeroCuenta, Dinero monto, String referencia) {
}
```

```java
Dinero importe = Dinero.de(monto, c.getMoneda());
ClaveDeposito clave = new ClaveDeposito(numero, importe, referencia);
if (referencia != null && recientes.contains(clave)) {
    return;   // ya se aplicó: la pasarela reintentó
}
recientes.add(clave);
```

- El conjunto pasa a ser `Set<ClaveDeposito>`. Los componentes son los mismos que comparaba el `equals` del legado
  (cuenta, monto, referencia) sin el tipo, que siempre es depósito: el comportamiento querido es el que el legado
  **intentaba** tener.
- Arreglar `Movimiento` con un `hashCode` habría bastado para el defecto, pero habría dejado mezcladas dos preguntas: "¿es
  el mismo registro?" y "¿es el mismo pago?". La segunda es del dominio y tiene nombre.

**La cuenta, igual por su número.** Una cuenta es una entidad: su identidad no cambia cuando cambia su saldo.

```java
// Una cuenta es la misma si tiene el mismo número, cambie lo que cambie su saldo.
@Override
public boolean equals(Object o) {
    return o instanceof Cuenta c && numero.equals(c.numero);
}

@Override
public int hashCode() {
    return numero.hashCode();
}
```

Y la caché, que es el uso que la volvía peligrosa, deja de usar la cuenta como clave:

```java
private final Map<String, List<Movimiento>> cacheExtractos = new HashMap<>();   // por número: no cambia
```

- Con el número como clave, da igual si `depositar` invalida antes o después de cambiar el saldo: `remove(numero)` siempre
  encuentra la entrada. El defecto no se arregla corrigiendo el orden, sino quitando lo que hacía que el orden importara.
- Arreglar la igualdad de `Cuenta` **y** cambiar la clave parece redundante. No lo es: la igualdad por número protege a
  cualquier otro mapa o conjunto de cuentas que alguien escriba mañana; la clave `String` deja la caché independiente de
  cómo se defina la igualdad de la entidad.

---

## 6. 💻 Paso 3 — Lo que dijo la red

La primera corrida no llega a las pruebas:

```text
[ERROR] /trabajo/src/test/java/banco/CaracterizacionTest.java:[96,69] cannot find symbol
  symbol:   method getComision()
```

- `Movimiento` dejó de tener `getComision()`: el `record` tiene `comision()`. Es un cambio de la API que ven los que llaman
  al gestor, y el compilador lo encontró antes que las pruebas. Se anota como tal: cualquier código que lea el extracto
  tiene que adaptarse.

Las tres pruebas que congelaban los defectos se cambian para afirmar el comportamiento nuevo, con nombre nuevo y un
comentario que dice dónde se corrigió:

| Prueba en `14/01` | Prueba en `14/02` | Valor |
|---|---|---|
| `depositar_elMismoPagoDosVecesLoAplicaDosVeces` | `depositar_elMismoPagoDosVecesLoAplicaUnaVez` | 1 660 000 → 1 580 000 |
| `retirar_deNominaGrandeDejaFraccionesDeCentavo` | `retirar_deNominaGrandeRedondeaLaComisionAlCentavo` | comisión 10 000,0004 → 10 000,00 |
| `extracto_quedaViejoSiElSaldoVuelveAlValorQueTenia` | `extracto_veLosMovimientosAunqueElSaldoVuelvaAlValorQueTenia` | 0 → 2 movimientos |

La segunda corrida dice algo que nadie había pedido:

```text
[ERROR] Tests run: 20, Failures: 4, Errors: 0, Skipped: 0 <<< FAILURE! -- in banco.CaracterizacionTest
[ERROR] banco.CaracterizacionTest.transferir_elEjemploDelCorpus <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <[ana.rojas@example.com: Recibiste 250000.0 COP de Ana Rojas Medina]>
 but was: <[ana.rojas@example.com: Recibiste 250000.00 COP de Ana Rojas Medina]>
[ERROR] banco.CaracterizacionTest.retirar_soloAvisaDesdeUnMillon <<< FAILURE!
[ERROR] banco.CaracterizacionTest.extracto_listaLosMovimientosEnOrden <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <[DEPOSITO 80000.0 ref PSE-7781, RETIRO 30000.0]>
 but was: <[DEPOSITO 80000.00 COP ref PSE-7781, RETIRO 30000.00 COP]>
[ERROR] banco.CaracterizacionTest.depositar_sumaElMontoYAvisa <<< FAILURE!
```

- Cuatro pruebas en rojo, y las cuatro por lo mismo: el dinero ahora se escribe con dos decimales y moneda. Es el cambio
  que `14/01` §5 anticipó al congelar el `250000.0` "tal como sale".
- **Aquí hay que decidir**, no corregir a ciegas. Los correos los lee Ana: ¿alguien procesa ese texto? Si un sistema de
  terceros lo parsea, el cambio rompe una integración. En este módulo nadie lo hace, y `250000.00 COP` es lo correcto, así
  que se acepta, y las cuatro pruebas se actualizan con el texto nuevo.

```text
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
[INFO] Tests run: 25, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

---

## 7. 🧪 Evidencia

| | `estados/01` | `estados/02` |
|---|---|---|
| Código de producción | 561 líneas, 5 clases | 606 líneas, 8 clases |
| `GestorCuentas` | 393 líneas | 403 líneas |
| Pruebas | 20 | 25 (20 de caracterización, 5 de `Dinero`) |
| Pruebas de caracterización cambiadas | — | 7: 3 defectos corregidos, 4 por el formato del dinero |
| Defectos congelados que quedan | 6 | 3 (los de `14/04` y `14/05`) |
| `double` en el dinero | Todo | Solo en la firma pública del gestor |

El gestor **creció**: diez líneas más, porque `Dinero.de(...)` y los `setBigDecimal` son más largos que un `double`. El
taller no prometía un gestor más corto; prometía un dinero que no pierde centavos y dos igualdades que dicen la verdad.

---

## 8. 🏷️ Lo que costó, y cuándo no

**Lo que costó:**

- **Líneas:** 45 más en producción y tres clases nuevas. `Dinero` es la mayor parte, y es código que se escribe una vez.
- **Indirección:** cada operación con dinero pasa por un método (`mas`, `menos`, `esMenorQue`) en lugar de un operador. En
  Java no hay sobrecarga de operadores: `saldo.menos(importe).menos(comision)` se lee peor que `saldo - importe - comision`.
- **Lectura:** quien llega tiene que aprender que hay dos igualdades —la del registro y la del pago— y por qué.
- **Rigidez:** la API cambió (`comision()` en lugar de `getComision()`), y los textos de los correos también. Ninguno de los
  dos cambios es gratis si hay alguien del otro lado.
- **Tiempo de ejecución:** `BigDecimal` es más lento que `double` y asigna un objeto por operación. En un módulo que hace
  una consulta SQL por operación, no se mide.

**Cuándo no:** `Dinero` siempre que el número sea dinero de alguien. La igualdad por identidad, en las entidades; en los
objetos de valor, por todos sus campos. Lo que **no** se hace es la clave separada (`ClaveDeposito`) cuando la identidad del
registro y la del concepto coinciden: si un pago se identificara solo por su referencia y el registro también, un tipo
aparte sería ceremonia.

> **Veredicto:** cada tipo responde una sola pregunta de igualdad, y la responde con un `equals` y un `hashCode` del mismo
> contrato: las entidades, por su identidad; los valores, por sus campos normalizados; y lo que el dominio llama "el mismo
> pago", con un tipo que lleve ese nombre.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Para arreglar el doble abono basta añadir `hashCode` a `Movimiento`" | Arregla el síntoma, pero mezcla "el mismo registro" con "el mismo pago"; con un `record` que compara la fecha, ni eso |
| "`BigDecimal` resuelve el dinero" | Sin escala normalizada, `10.0` y `10.00` son distintos para `equals`; y falta la moneda |
| "`new BigDecimal(0.1)` es lo mismo que `BigDecimal.valueOf(0.1)`" | El primero arrastra el error binario del `double`; el segundo parte de `"0.1"` |
| "El defecto del extracto se arregla invalidando la caché en el orden correcto" | Se arregla con una clave que no cambia; el orden deja de importar |
| "Si las pruebas de caracterización fallan, el cambio está mal" | Fallan porque algo cambió; los cuatro textos con centavos son un cambio que se decidió aceptar |
| "Un `record` es inmutable" | Lo es superficialmente: sus componentes no se reasignan, pero si uno es mutable, el `record` también lo es |
| "Cuenta debería tener `equals` con todos los campos, para ser completo" | Es una entidad: su igualdad es su identidad; con el saldo dentro, deja de ser la misma al depositar |

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3.ª ed. (Addison-Wesley, 2018), ítems 10 y 11: el contrato de `equals` y
  "*Always override hashCode when you override equals*". **El que destaca.**
- **Libro** — Fowler, *Patterns of Enterprise Application Architecture* (Addison-Wesley, 2002), cap. 18, *Money* y *Value
  Object*.
- [Java 21 — `BigDecimal`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/math/BigDecimal.html): por qué
  `equals` compara la escala, y `valueOf(double)`.
- [Java 21 — `RoundingMode.HALF_EVEN`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/math/RoundingMode.html#HALF_EVEN):
  el redondeo bancario, con su tabla de ejemplos.
- [Java 21 — `Object.hashCode`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Object.html#hashCode()):
  el contrato, en tres reglas.
- [JEP 395 — *Records*](https://openjdk.org/jeps/395): qué genera un `record` y qué no.

---

## 🧠 Preguntas

1. ¿Qué regla del contrato de `hashCode` rompe el `Movimiento` del legado? 🟢
2. ¿Por qué `Dinero` normaliza la escala en el constructor compacto? 🟢
3. ¿Qué diferencia hay entre `new BigDecimal(0.1)` y `BigDecimal.valueOf(0.1)`? 🟡
4. ¿Por qué `Cuenta` y `Dinero` tienen igualdades de tipos distintos? 🟡
5. ¿Por qué el `record` `Movimiento` no sirve para detectar el depósito reintentado? 🟡
6. ¿Qué arregla el defecto del extracto: la igualdad de `Cuenta` o la clave `String`? ¿Por qué se hicieron las dos? 🟠
7. Cuatro pruebas fallaron por el formato del dinero. ¿Qué preguntas haces antes de aceptarlo? 🟠
8. ¿Por qué `HALF_EVEN` y no `HALF_UP` para las comisiones? 🟠
9. ¿Por qué el paso 2 no se pudo partir en pasos más pequeños, y qué lo habría permitido? 🟠
10. Un compañero propone resolver el doble abono con un `UNIQUE (numero, referencia)` en la tabla `movimiento`, sin tocar
    las clases. Evalúa la propuesta. 🔴

---

## 🧪 Ejercicios

Sobre `estados/02`, en una clase de prueba nueva.

**E1.** Escribe la prueba que demuestra que `Dinero` es inmutable: después de `mas`, el original no cambió. 🟢

**E2.** Quita la normalización de escala del constructor compacto de `Dinero`, corre `DineroTest` y explica qué pruebas
caen y por qué. Después, devuélvela. 🟡

**E3.** La pasarela reintenta un depósito con la misma referencia pero otro monto (un error de su lado). Congela qué
hace hoy `estados/02` y di si es lo que el negocio debería querer. 🟠

**E4.** Escribe `Dinero.repartir(int partes)`, que reparta un monto en partes iguales sin perder ni crear un centavo: 100,00
COP entre tres da 33,34, 33,33 y 33,33. Con su prueba. 🔴

---

**Anterior:** [`01` — Caracterización](01-caracterizacion.md) · **Siguiente:** [`03` — Partir el God Object](03-partir-el-god-object.md) ·
**Relacionado:** [`01/02` — Igualdad, identidad y hash](../01-modelo-de-objetos/02-igualdad-identidad-y-hash.md)
