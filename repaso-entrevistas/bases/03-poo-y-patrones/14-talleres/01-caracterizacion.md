# 01 — Caracterización

> Antes de tocar una línea del legado, congelas lo que hace hoy —**defectos incluidos**— en una suite de pruebas que corre en
> segundos. Terminas con `laboratorio/estados/01/`: el legado sin cambios y veinte pruebas en verde, seis de ellas sobre defectos
> marcados como tales. Parte de `laboratorio/legado/`. Ejercita [`13/03` — Refactorizar hacia patrones](../13-patrones-en-la-practica/03-refactorizar-hacia-patrones.md)
> y [`12/05` — Antipatrones de código y de proceso](../12-antipatrones/05-antipatrones-de-codigo-y-de-proceso.md). Este taller es
> **opcional**, como todo el bloque; sus reglas están en §13.2 de la guía del corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--la-base-limpia-en-cada-prueba) · [5](#5--paso-2--lo-que-el-legado-hace-bien) · [6](#6--paso-3--los-defectos-congelados-y-marcados) · [7](#7--paso-4--lo-que-no-se-congela) · [8](#8--paso-5--el-arreglo-inocente) · [9](#9--evidencia) · [10](#10-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

Heredas `GestorCuentas`: casi cuatrocientas líneas que abren cuentas, mueven dinero, bloquean, cierran, auditan y mandan
correos. No hay una sola prueba. El primer ticket que te asignan dice: *"Los pagos por PSE a veces se acreditan dos veces"*.
Buscas y encuentras esto:

```java
Movimiento m = new Movimiento(numero, "DEPOSITO", monto, 0, referencia, LocalDateTime.now());
if (referencia != null && recientes.contains(m)) {
    return;   // ya se aplicó: la pasarela reintentó
}
recientes.add(m);
```

- `recientes` es un `HashSet<Movimiento>`, y `Movimiento` define `equals` pero no `hashCode`. Ya sabes por qué falla: lo
  explica [`01/02`](../01-modelo-de-objetos/02-igualdad-identidad-y-hash.md).
- El arreglo parece de una línea. La pregunta es otra: **¿qué más cambia si lo arreglas?** ¿Hay algún proceso que
  dependa del doble abono? ¿Alguna prueba de otro equipo? No lo sabes, porque nadie escribió lo que el módulo hace.

La tentación es arreglar primero y probar después. El orden correcto es el inverso: **primero se fija el comportamiento
actual, y después se cambia a propósito**. Una prueba que fija el comportamiento sin juzgarlo es una **prueba de
caracterización** (*characterization test*): no afirma que el sistema haga lo correcto, afirma que **sigue haciendo lo
mismo**.

---

## 2. 🧰 Punto de partida

El legado es un proyecto Maven con cinco clases y ninguna prueba:

```text
14-talleres/laboratorio/
├── legado/                      el punto de partida: no se toca
│   ├── pom.xml                  Java 21, H2 2.5.252, JUnit 6.1.3
│   └── src/main/java/banco/
│       ├── BaseDatos.java       la H2 en memoria y el esquema
│       ├── Cuenta.java          datos con getters y setters
│       ├── Movimiento.java      equals sin hashCode
│       ├── Notificador.java     "manda" correos a una lista
│       └── GestorCuentas.java   el God Object: 393 líneas
└── estados/01/                  el legado + src/test/java/banco/CaracterizacionTest.java
```

Cópialo a una carpeta de trabajo, fuera del corpus, y córrelo:

```bash
cp -R 14-talleres/laboratorio/legado ~/kata-cuentas
cd ~/kata-cuentas
docker run --rm -v "$PWD":/trabajo -w /trabajo -v "$HOME/.m2":/root/.m2 \
  maven:3.10.0-eclipse-temurin-21 mvn -B test
```

- `cp -R` copia la carpeta entera; trabajas sobre la copia para poder comparar con el original y con cada estado.
- `docker run --rm` arranca un contenedor y lo borra al terminar: no instalas ni Java ni Maven en tu máquina.
- `-v "$PWD":/trabajo -w /trabajo` monta la carpeta actual dentro del contenedor y la usa como directorio de trabajo. La
  carpeta `target/` que crea Maven queda en tu copia, no en el corpus.
- `-v "$HOME/.m2":/root/.m2` comparte la caché de dependencias de Maven: la primera corrida descarga H2 y JUnit; las demás,
  no.
- `maven:3.10.0-eclipse-temurin-21` es la imagen exacta del taller: Maven 3.10.0 sobre el JDK 21 de Eclipse Temurin.
- `mvn -B test` compila y corre las pruebas; `-B` (*batch mode*) quita los colores y las barras de progreso, para que la
  salida se pueda leer y comparar.

La salida del legado, recortada a lo que importa:

```text
[INFO] Building cuentas 1.0
[INFO] Compiling 5 source files with javac [debug release 21] to target/classes
[INFO] BUILD SUCCESS
```

`BUILD SUCCESS` sin una línea `Tests run`: compila, y nada comprueba lo que hace. Ese es el estado real de muchos módulos
que se heredan.

---

## 3. 🩺 El defecto, reproducido

En este taller, "reproducir el defecto" tiene un giro: **la prueba pasa**. Se escribe para que afirme lo que el legado hace
hoy, aunque esté mal, y se marca para que nadie la confunda con una especificación:

```java
@Test
void depositar_elMismoPagoDosVecesLoAplicaDosVeces() {
    // DEFECTO CONGELADO: Movimiento tiene equals sin hashCode, y el HashSet de recientes no lo encuentra
    gestor.depositar("CTA-0001", 80_000, "PSE-7781");
    gestor.depositar("CTA-0001", 80_000, "PSE-7781");
    assertEquals(1_660_000.0, gestor.consultarSaldo("CTA-0001"));
}
```

- Ana parte de 1 500 000,00. Si el segundo depósito se ignorara, quedaría en 1 580 000; queda en **1 660 000**. La prueba
  afirma el número que el legado da, no el que debería dar.
- El comentario `DEFECTO CONGELADO` es el contrato con el lector de la prueba: "esto está mal, lo sé, y cuando lo arregles
  esta prueba se pondrá en rojo; cámbiala en el mismo paso".
- El nombre describe el comportamiento, no el deseo: `loAplicaDosVeces`, no `noDeberiaAplicarlo`.

El legado tiene seis defectos que el bloque irá corrigiendo. Este taller los congela todos:

| Defecto congelado | Prueba | Lo corrige |
|---|---|---|
| El depósito duplicado se aplica dos veces | `depositar_elMismoPagoDosVecesLoAplicaDosVeces` | `14/02` |
| La comisión de nómina deja fracciones de centavo | `retirar_deNominaGrandeDejaFraccionesDeCentavo` | `14/02` |
| El extracto en caché se queda viejo | `extracto_quedaViejoSiElSaldoVuelveAlValorQueTenia` | `14/02` |
| Se transfiere a una cuenta cerrada | `transferir_aUnaCuentaCerradaSeAcepta` | `14/04` |
| Una cuenta queda cerrada y bloqueada a la vez | `bloquear_unaCuentaCerradaLaDejaCerradaYBloqueada` | `14/04` |
| Un menor transfiere más de lo que puede retirar | `transferir_unMenorPasaElTopeQueNoPuedeRetirar` | `14/05` |

---

## 4. 💻 Paso 1 — La base limpia en cada prueba

La primera decisión de una suite de caracterización no es qué afirmar, sino **desde qué estado parte cada prueba**. El
legado usa una H2 en memoria que vive mientras viva la JVM, y Maven corre todas las pruebas de la clase en la misma JVM:

```java
@BeforeEach
void baseLimpia() {
    BaseDatos.crearEsquema();
    Notificador.ENVIADOS.clear();
    gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.abrirCuenta("CTA-0002", "Carmen Díaz Ortega", "carmen.diaz@example.com", "CORRIENTE", "USD", 2_300.00, false);
    gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
    Notificador.ENVIADOS.clear();
}
```

- `crearEsquema()` hace `DROP ALL OBJECTS` y crea las tablas: cada prueba arranca con la base vacía.
- `Notificador.ENVIADOS` es una lista **estática**: si no se vacía, los correos de una prueba aparecen en la siguiente. Se
  vacía otra vez después de las aperturas, para que cada prueba vea solo sus propios correos.
- `new GestorCuentas()` en cada prueba, porque el gestor guarda estado en memoria (la caché de extractos y los depósitos
  recientes).
- Las tres cuentas son las de §5.6 de la guía: la de Ana, la de Carmen en dólares y la de Luis, menor, con el correo de su
  tutora. Las cuentas `CTA-0004` (nómina de Ana) y `CTA-0005` (de Carmen, en pesos) las abre cada prueba que las necesita.

La provocación: mueve el `crearEsquema()` a un bloque `static`, que corre **una sola vez** para toda la clase.

```java
static { BaseDatos.crearEsquema(); }     // una sola vez para toda la clase
```

```text
[ERROR] Tests run: 20, Failures: 0, Errors: 19, Skipped: 0
[ERROR] banco.CaracterizacionTest.transferir_elEjemploDelCorpus <<< ERROR!
org.h2.jdbc.JdbcSQLIntegrityConstraintViolationException: Unique index or primary key violation:
"PUBLIC.CONSTRAINT_7 INDEX PUBLIC.PRIMARY_KEY_7 ON PUBLIC.CUENTA(NUMERO) VALUES ( /* 1 */ 'CTA-0001' )"
```

- Diecinueve errores, no fallos: la primera prueba abre `CTA-0001` y las demás intentan abrirla otra vez.
- Aquí el síntoma es ruidoso. El caso peligroso es el silencioso: si las aperturas no chocaran, las pruebas pasarían o
  fallarían **según el orden** en que JUnit las corra. Por defecto, JUnit usa un orden determinista pero, según su guía, "a
  propósito no evidente": nadie debería depender de él.

---

## 5. 💻 Paso 2 — Lo que el legado hace bien

La mayoría de las pruebas congelan comportamiento correcto. Son las que más protegen, porque es lo que los usuarios usan
todos los días. La transferencia de ejemplo del corpus:

```java
@Test
void transferir_elEjemploDelCorpus() {
    gestor.transferir("CTA-0001", "CTA-0003", 250_000);
    assertEquals(1_250_000.0, gestor.consultarSaldo("CTA-0001"));
    assertEquals(250_000.0, gestor.consultarSaldo("CTA-0003"));
    assertEquals(List.of("ana.rojas@example.com: Recibiste 250000.0 COP de Ana Rojas Medina"), Notificador.ENVIADOS);
}
```

- Se afirma el **efecto observable**: los saldos que devuelve la fachada y el correo que salió. No se mira la tabla
  `movimiento` ni los campos privados del gestor: si los talleres siguientes cambian cómo se guarda, la prueba sigue
  valiendo.
- El texto del correo se copia **tal como sale**, con su `250000.0`. Que se vea feo es un dato: cuando `14/02` cambie el
  dinero a `BigDecimal`, esta línea cambiará, y habrá que decidir si eso es un cambio querido.

Las validaciones se congelan con su mensaje, porque el mensaje es parte del contrato que ve quien llama:

```java
@Test
void transferir_rechazaLoQueValida() {
    assertMensaje("origen y destino son la misma cuenta", () -> gestor.transferir("CTA-0001", "CTA-0001", 1));
    assertMensaje("las cuentas tienen monedas distintas", () -> gestor.transferir("CTA-0001", "CTA-0002", 1));
    gestor.bloquear("CTA-0003", "revisión");
    assertMensaje("la cuenta destino CTA-0003 está bloqueada", () -> gestor.transferir("CTA-0001", "CTA-0003", 1));
}

private static void assertMensaje(String esperado, Runnable operacion) {
    RuntimeException e = assertThrows(RuntimeException.class, operacion::run);
    assertEquals(esperado, e.getMessage());
}
```

- `assertThrows` de JUnit devuelve la excepción lanzada; la ayuda `assertMensaje` compara su mensaje. Se pide
  `RuntimeException` y no el tipo exacto, porque el legado mezcla `IllegalArgumentException` e `IllegalStateException` sin
  criterio claro, y unificar eso es un cambio que se decide después, no algo que la caracterización deba impedir.
- Hay una prueba que congela una **diferencia que parece un error y no lo es**: el retiro de una corriente en pesos cobra
  1 500 y la transferencia, 1 000. Se congela con un comentario que dice "no es un defecto conocido". Si alguien unifica
  los dos `switch` en `14/04` y la prueba se pone en rojo, tendrá que preguntar antes de cambiarla.

---

## 6. 💻 Paso 3 — Los defectos, congelados y marcados

El defecto más sutil es el del extracto. La caché guarda los movimientos con la `Cuenta` como clave, y el `hashCode` de
`Cuenta` incluye el saldo. La prueba necesita una secuencia precisa para que se vea:

```java
@Test
void extracto_quedaViejoSiElSaldoVuelveAlValorQueTenia() {
    // DEFECTO CONGELADO: la caché usa la Cuenta como clave, y su hashCode incluye el saldo
    gestor.extracto("CTA-0001");                         // guarda la clave con saldo 1500000
    gestor.depositar("CTA-0001", 100_000, null);
    gestor.retirar("CTA-0001", 100_000);                 // el saldo vuelve a 1500000
    assertEquals(0, gestor.extracto("CTA-0001").size()); // en la base hay dos movimientos
}
```

La traza de lo que pasa en la caché:

```text
extracto()   lee Ana con saldo 1500000 → no hay entrada → carga []        → put(Ana@1500000, [])
depositar()  lee Ana@1500000, le suma  → Ana@1600000 → remove(Ana@1600000) → no encuentra nada
retirar()    lee Ana@1600000           → remove(Ana@1600000) → nada; resta → Ana@1500000
extracto()   lee Ana@1500000           → get(Ana@1500000) → la entrada vieja: []
```

- `depositar` invalida la caché **después** de cambiar el saldo, y `retirar`, **antes**. Ninguno de los dos borra la
  entrada vieja, porque ninguno la busca con el saldo con que se guardó.
- Si el saldo no volviera a 1 500 000, el `get` fallaría y el extracto se recargaría bien. El defecto solo se ve cuando el
  saldo **regresa** a un valor anterior: por eso pasa meses sin que nadie lo note.
- Es la clave mutable de [`01/02`](../01-modelo-de-objetos/02-igualdad-identidad-y-hash.md), en código de producción.

La comisión de la nómina congela un número que nadie querría ver en un extracto:

```java
@Test
void retirar_deNominaGrandeDejaFraccionesDeCentavo() {
    // DEFECTO CONGELADO: el dinero es double y nadie redondea la comisión del 0,4 %
    gestor.abrirCuenta("CTA-0004", "Ana Rojas Medina", "ana.rojas@example.com", "NOMINA", "COP", 5_000_000, false);
    gestor.retirar("CTA-0004", 2_500_000.10);
    assertEquals(10_000.0004, gestor.extracto("CTA-0004").get(0).getComision(), 1e-9);
    assertEquals(2_489_999.8996, gestor.consultarSaldo("CTA-0004"), 1e-6);
}
```

- El tercer argumento de `assertEquals` es la tolerancia: comparar `double` por igualdad exacta congelaría también el ruido
  de la representación binaria, que no es parte del comportamiento.
- `10 000,0004` pesos de comisión: cuatro decimales sobre una moneda que tiene dos. El saldo queda con fracción de centavo.

---

## 7. 💻 Paso 4 — Lo que no se congela

Un *golden master* es tan estable como lo que congela. Hay tres cosas del legado que la suite **no** afirma, a propósito:

- **Las fechas.** Cada movimiento lleva `LocalDateTime.now()`. Afirmarlas obligaría a controlar el reloj, y el legado no lo
  permite: el `now()` está metido en el código. Por eso `Movimiento.toString()` no las imprime y ninguna prueba las mira.
- **El texto de la auditoría.** Se cuenta cuántas filas deja cada operación, no qué dicen:

  ```java
  @Test
  void cadaOperacionDejaUnaFilaDeAuditoria() throws SQLException {
      int antes = filas("auditoria");                     // las tres aperturas
      gestor.depositar("CTA-0001", 80_000, null);
      gestor.retirar("CTA-0001", 30_000);
      gestor.transferir("CTA-0001", "CTA-0003", 10_000);
      gestor.bloquear("CTA-0001", "embargo");
      gestor.desbloquear("CTA-0001");
      assertEquals(3, antes);
      assertEquals(8, filas("auditoria"));
  }
  ```

  Que **toda** operación audite es un requisito que `14/05` debe respetar al sacar la auditoría a un decorador. El formato
  del detalle es una decisión interna que nadie consume.
- **La salida de consola.** Las líneas `[AUDITORIA]` y `[CORREO]` que imprime el legado no se capturan. Lo que importa del
  correo está en `Notificador.ENVIADOS`.

> 💡 La regla para decidir: se congela lo que **otro** observa —el saldo, el mensaje de error, el correo que le llega a
> Ana, la existencia de la fila de auditoría—, y no lo que solo observa el propio módulo.

---

## 8. 💻 Paso 5 — El arreglo inocente

La suite está en verde. Ahora haz lo que el ticket pedía, sin pensar en las pruebas: añade a `Movimiento` el `hashCode`
que le falta.

```java
@Override
public int hashCode() {
    return Objects.hash(numeroCuenta, tipo, monto, referencia);
}
```

```text
[ERROR] Tests run: 20, Failures: 1, Errors: 0, Skipped: 0
[ERROR] banco.CaracterizacionTest.depositar_elMismoPagoDosVecesLoAplicaDosVeces -- Time elapsed: 0.043 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <1660000.0> but was: <1580000.0>
```

- Una sola prueba en rojo, y es la que tenía el comentario `DEFECTO CONGELADO`: el arreglo hizo exactamente lo que se
  quería y **nada más**. Esa es la información que la suite compra.
- Si hubiera caído otra prueba —el extracto, la auditoría—, sabrías que el arreglo tocaba algo más antes de subirlo.
- La prueba no se borra: se **cambia** para que afirme el comportamiento nuevo, en el mismo paso, y se le quita el
  comentario. Es lo que hace [`14/02`](02-igualdad-hash-e-inmutabilidad.md). En `estados/01` el arreglo **no** está: este
  taller solo congela.

---

## 9. 🧪 Evidencia

La corrida de `estados/01`:

```text
[INFO] Compiling 5 source files with javac [debug release 21] to target/classes
[INFO] Compiling 1 source file with javac [debug release 21] to target/test-classes
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.217 s -- in banco.CaracterizacionTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

| | Legado | `estados/01` |
|---|---|---|
| Código de producción | 561 líneas, 5 clases | Igual, sin un cambio |
| Pruebas | 0 | 20, en una clase de 224 líneas |
| Defectos congelados y marcados | — | 6 |
| Tiempo de la suite | — | 1,2 s |

---

## 10. 🏷️ Lo que costó, y cuándo no

**Lo que costó**, en las cuatro monedas:

- **Líneas:** 224 de prueba para 561 de producción, sin mejorar nada del módulo. Es el costo más difícil de defender ante
  quien pidió "arregla el doble abono".
- **Indirección:** ninguna; las pruebas llaman a la fachada pública tal como está.
- **Lectura:** quien lee la suite tiene que distinguir lo que es correcto de lo que está congelado. Por eso cada defecto
  lleva su comentario y su nombre describe lo que hace.
- **Rigidez:** la suite congela también lo que nadie decidió, como los textos con `250000.0`. Cada cambio de comportamiento,
  querido o no, pone una prueba en rojo, y alguien tiene que decidir. Ese es el punto, y es también el costo.

**Cuándo no:** cuando el código ya tiene pruebas de comportamiento que cubren lo que vas a tocar, y cuando lo vas a
**reemplazar entero** detrás de una interfaz que ya está probada. Tampoco se caracteriza todo de una vez: se empieza por
lo que el cambio toca y por lo que más se usa. Esta suite cubre el módulo entero porque es pequeño y porque los cinco
talleres siguientes lo van a tocar de punta a punta.

> **Veredicto:** antes de cambiar código sin pruebas, congela lo que hace; arreglar primero es apostar a que nadie dependía
> del defecto, y la caracterización convierte esa apuesta en una prueba en rojo que te obliga a decidir.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La prueba de caracterización afirma lo correcto" | Afirma lo que el código hace **hoy**; lo correcto se decide después, y la prueba se cambia a propósito |
| "Si un defecto está congelado, la suite lo protege" | Lo **detecta**: cuando se arregle, la prueba se pone en rojo para que el cambio sea deliberado |
| "Primero arreglo y después le escribo pruebas" | Sin la red, no sabes qué más cambió con tu arreglo; en el taller, el arreglo inocente tumba justo una prueba |
| "Una base compartida entre pruebas es más rápida" | Y hace que el resultado dependa del orden de ejecución; aquí, diecinueve errores |
| "Hay que afirmar todo, incluidas las fechas" | Se afirma lo que otro observa; lo que depende del reloj o es interno vuelve frágil la suite |
| "La caracterización se escribe sobre las clases internas" | Se escribe sobre la fachada que usan los demás, para que sobreviva a la refactorización de dentro |

---

## 📚 Para profundizar

- **Libro** — Feathers, *Working Effectively with Legacy Code* (Prentice Hall, 2004), cap. 13, "I Need to Make a Change,
  but I Don't Know What Tests to Write": las pruebas de caracterización y la heurística para escribirlas. **El que
  destaca.**
- **Libro** — Fowler, *Refactoring*, 2.ª ed. (Addison-Wesley, 2018), cap. 4, "Building Tests".
- [Michael Feathers — *Characterization Testing*](https://michaelfeathers.silvrback.com/characterization-testing): el autor,
  en su blog, sobre qué es y para qué sirve.
- [JUnit 6 — *Test Instance Lifecycle*](https://docs.junit.org/6.1.3/writing-tests/test-instance-lifecycle.html): por qué
  cada prueba recibe una instancia nueva de la clase.
- [JUnit 6 — *Assertions*](https://docs.junit.org/6.1.3/writing-tests/assertions.html): `assertThrows` y la tolerancia de
  `assertEquals` con `double`.
- [H2 — *Features*](https://www.h2database.com/html/features.html): la base en memoria y `DB_CLOSE_DELAY`.

---

## 🧠 Preguntas

1. ¿Qué afirma una prueba de caracterización, y qué no afirma? 🟢
2. ¿Por qué el legado da `BUILD SUCCESS` aunque no tenga ninguna prueba? 🟢
3. ¿Qué diferencia hay entre un fallo y un error en el resumen de JUnit, y cuál dio la base compartida? 🟡
4. ¿Por qué se marca un defecto congelado con un comentario y no se deja la prueba sin escribir? 🟡
5. ¿Por qué las pruebas llaman a `GestorCuentas` y no a sus métodos privados ni a las tablas? 🟡
6. ¿Por qué hay que vaciar `Notificador.ENVIADOS` dos veces en el `@BeforeEach`? 🟠
7. ¿Por qué el extracto viejo solo aparece cuando el saldo vuelve a un valor que ya tuvo? 🟠
8. ¿Por qué no se congelan las fechas de los movimientos, y qué haría falta para poder hacerlo? 🟠
9. El arreglo inocente puso una sola prueba en rojo. ¿Qué te dice eso, y qué haces con esa prueba? 🟠
10. Tu jefe ve 224 líneas de prueba y ningún defecto arreglado. Defiende el día de trabajo en dos frases. 🔴

---

## 🧪 Ejercicios

Sobre `estados/01`. Escribe cada prueba en una clase nueva, con el mismo `@BeforeEach`, y córrela con la suite.

**E1.** Congela qué pasa al desbloquear una cuenta que no estaba bloqueada: el estado que queda y los correos que salen. 🟢

**E2.** Congela qué pasa al abrir una cuenta con un número que ya existe: qué excepción llega a quien llama, qué causa
envuelve, y si el saldo de la cuenta original o los correos cambian. 🟡

**E3.** Escribe las pruebas de borde de la comisión de nómina: un retiro de exactamente 2 000 000 y otro de 2 000 001.
Congela las dos comisiones. 🟠

**E4.** ¿Se reproduce el extracto viejo si el saldo de Ana vuelve a su valor con dos transferencias, de ida y vuelta, en
lugar de un depósito y un retiro? Escribe la prueba que lo demuestra y explica la diferencia con la traza del §6. 🔴

---

**Anterior:** [`README` del bloque](README.md) · **Siguiente:** [`02` — Igualdad, hash e inmutabilidad](02-igualdad-hash-e-inmutabilidad.md) ·
**Relacionado:** [`13/03` — Refactorizar hacia patrones](../13-patrones-en-la-practica/03-refactorizar-hacia-patrones.md)
