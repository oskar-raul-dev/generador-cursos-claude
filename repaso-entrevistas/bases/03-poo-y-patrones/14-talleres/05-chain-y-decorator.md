# 05 — Chain y Decorator

> Conviertes las cadenas de `if` de cada operación en eslabones con nombre que el retiro y la transferencia comparten
> (Chain of Responsibility), y sacas la auditoría de dentro de las operaciones a un objeto que las envuelve (Decorator).
> Corriges así el último defecto que congeló `14/01`: el menor que transfiere más de lo que puede retirar. Terminas con
> `laboratorio/estados/05/`. Parte de `estados/04`. Ejercita [`06/05` — Chain of Responsibility](../06-comportamiento/05-chain-of-responsibility.md),
> [`05/02` — Decorator](../05-estructurales/02-decorator.md) y [`03/02` — SOLID sin catecismo](../03-principios-de-diseno/02-solid-sin-catecismo.md).
> Opcional; reglas en §13.2 de la guía del corpus.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [1](#1--el-problema) · [2](#2--punto-de-partida) · [3](#3--el-defecto-reproducido) · [4](#4--paso-1--el-eslabón) · [5](#5--paso-2--las-dos-cadenas) · [6](#6--paso-3--la-interfaz-de-las-operaciones) · [7](#7--paso-4--la-auditoría-envuelve) · [8](#8--evidencia) · [9](#9-️-lo-que-costó-y-cuándo-no) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 El problema

Después de `14/04`, las validaciones de estado ya no viven en el servicio, pero las demás siguen ahí, escritas a mano en
cada operación:

```java
public void retirar(String numero, double monto) {
    Cuenta c = cuentas.buscar(numero);
    if (monto <= 0) {
        throw new IllegalArgumentException("el monto debe ser positivo");
    }
    c.verificarQuePuedeRetirar();
    Dinero importe = Dinero.de(monto, c.getMoneda());
    if (c.isEsMenor() && importe.esMayorQue(Dinero.de("200000", c.getMoneda()))) {
        throw new IllegalStateException("un menor no puede retirar más de 200000");
    }
    // … la comisión, el débito, el guardado, el movimiento, la caché
    auditoria.registrar("RETIRO", numero + " " + importe + " comisión " + comision);
    // … el correo
}
```

- La regla de los menores está en `retirar` y **no** en `transferir`. Nadie decidió eso: se escribió en un sitio y se
  olvidó en el otro. Luis no puede retirar 250 000, pero puede transferirlos a otra cuenta y retirarlos desde ahí.
- Cada regla es un `if` anónimo en medio de un método. Para saber qué reglas tiene una transferencia hay que leer el
  método entero.
- La auditoría está mezclada con el negocio en las tres operaciones: es una preocupación transversal escrita tres veces,
  y quien prueba un retiro arrastra la tabla de auditoría.

---

## 2. 🧰 Punto de partida

Parte de `estados/04`. Lo que cambia:

```text
estados/05/src/
├── main/java/banco/
│   ├── Solicitud.java              nuevo: lo que una regla necesita saber
│   ├── Regla.java                  nuevo: el eslabón abstracto y cómo se encadena
│   ├── Reglas.java                 nuevo: los seis eslabones, con su mensaje
│   ├── OperacionesCuenta.java      nuevo: la interfaz de las operaciones
│   ├── OperacionesAuditadas.java   nuevo: el decorador de auditoría
│   ├── ServicioMovimientos.java    implementa la interfaz; sin if de reglas, sin auditoría
│   └── GestorCuentas.java          compone servicio y decorador
└── test/java/banco/
    ├── CaracterizacionTest.java    una prueba cambiada
    └── CadenaYDecoradorTest.java   nuevo
```

---

## 3. 🩺 El defecto, reproducido

```java
@Test
void unMenorNoTransfiereMasDelTope() {
    BaseDatos.crearEsquema();
    GestorCuentas gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
    gestor.transferir("CTA-0001", "CTA-0003", 250_000);
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.transferir("CTA-0003", "CTA-0001", 250_000));
    assertEquals("un menor no puede transferir más de 200000", e.getMessage());
}
```

```text
[ERROR] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0 <<< FAILURE! -- in banco.DefectoDelTopeTest
[ERROR] banco.DefectoDelTopeTest.unMenorNoTransfiereMasDelTope <<< FAILURE!
```

- Ana le transfiere 250 000 a Luis —recibir no tiene tope— y Luis intenta transferirlos de vuelta. Contra `estados/04`, la
  segunda transferencia pasa y `assertThrows` falla.
- El mensaje dice "transferir" y no "retirar": la regla es la misma, pero quien la ve tiene que entender qué operación
  se rechazó. El de retiro no cambia, porque está congelado.

---

## 4. 💻 Paso 1 — El eslabón

Cada regla pasa a ser un objeto que comprueba una cosa y, si no lanza, deja pasar la solicitud al siguiente. Es la variante
"acumula, y cualquiera puede cortar" de [`06/05` §6](../06-comportamiento/05-chain-of-responsibility.md#6--variantes), la de
los filtros de *servlet*:

```java
// Chain of Responsibility: cada eslabón comprueba lo suyo y pasa al siguiente; el que lanza, corta la cadena.
public abstract class Regla {

    private Regla siguiente;

    public static Regla cadena(Regla primera, Regla... resto) {
        Regla actual = primera;
        for (Regla r : resto) {
            actual.siguiente = r;
            actual = r;
        }
        return primera;
    }

    public final void verificar(Solicitud s) {
        comprobar(s);
        if (siguiente != null) {
            siguiente.verificar(s);
        }
    }

    protected abstract void comprobar(Solicitud s);
}
```

- `verificar` es `final` y `comprobar` es lo que cada eslabón escribe: un Template Method pequeño que garantiza que ningún
  eslabón olvide pasar al siguiente.
- `cadena` enlaza en el orden de los argumentos. Ese orden decide qué mensaje ve quien llama cuando fallan dos reglas, y
  por eso se escribe una vez, en un sitio visible.
- La solicitud es un `record` con lo que las reglas necesitan: el origen, el destino (nulo en un retiro) y el importe.

Los eslabones, en una clase con un método de fábrica por regla:

```java
// el tope de los menores: una sola regla, para todo lo que sale de su cuenta
public static Regla topeDeMenores(String verbo) {
    return new Regla() {
        @Override protected void comprobar(Solicitud s) {
            Dinero tope = Dinero.de("200000", s.importe().moneda());
            if (s.origen().isEsMenor() && s.importe().esMayorQue(tope)) {
                throw new IllegalStateException("un menor no puede " + verbo + " más de 200000");
            }
        }
    };
}
```

- El verbo es un parámetro para conservar el mensaje del retiro, que está congelado, y dar uno propio a la transferencia.
- `origenPuedeRetirar` y `destinoPuedeRecibir` son eslabones de una línea: le preguntan al estado de `14/04`. La cadena no
  reemplaza al State; lo usa.

---

## 5. 💻 Paso 2 — Las dos cadenas

El servicio declara, una vez y con nombre, qué reglas tiene cada operación:

```java
private final Regla reglasDeRetiro = Regla.cadena(
        Reglas.montoPositivo(), Reglas.origenPuedeRetirar(), Reglas.topeDeMenores("retirar"));
private final Regla reglasDeTransferencia = Regla.cadena(
        Reglas.cuentasDistintas(), Reglas.montoPositivo(), Reglas.origenPuedeRetirar(),
        Reglas.destinoPuedeRecibir(), Reglas.mismaMoneda(), Reglas.topeDeMenores("transferir"));
```

```java
public Movimiento retirar(String numero, double monto) {
    Cuenta c = cuentas.buscar(numero);
    Dinero importe = Dinero.de(monto, c.getMoneda());
    reglasDeRetiro.verificar(Solicitud.deRetiro(c, importe));
    // … la comisión, el débito, el guardado, el movimiento, la caché, el correo
}
```

- El defecto se corrige **añadiendo un eslabón** a la cadena de la transferencia, sin tocar los demás. Es el
  abierto/cerrado de [`03/02`](../03-principios-de-diseno/02-solid-sin-catecismo.md) en su lectura útil: extender por
  composición, no editar lo que funciona.
- El orden de cada cadena es el que tenían los `if`: la caracterización no cambió más que la prueba del defecto. Pero esa
  red **no** cubre todos los órdenes: el ejercicio E2 invierte dos eslabones y ninguna de las veinte pruebas cae.
- El depósito no tiene cadena: tiene una regla (monto positivo) y la del estado, que está en la cuenta. Una cadena de dos
  eslabones para un solo uso sería ceremonia.

---

## 6. 💻 Paso 3 — La interfaz de las operaciones

Para envolver al servicio, el decorador necesita hablar la misma interfaz. Se extrae:

```java
// La interfaz que comparten el servicio y sus decoradores.
public interface OperacionesCuenta {

    boolean depositar(String numero, double monto, String referencia);   // false si era un reintento

    Movimiento retirar(String numero, double monto);

    Movimiento transferir(String numeroOrigen, String numeroDestino, double monto);

    List<Movimiento> extracto(String numero);
}
```

- Las operaciones **devuelven** algo que antes no devolvían. Es la pregunta que obliga a hacer el decorador: ¿qué necesita
  saber para hacer su trabajo desde afuera?
- `depositar` devuelve si se aplicó. Sin eso, el decorador auditaría también los reintentos que el servicio ignora, y la
  auditoría diría que hubo dos depósitos de `PSE-7781`. La caracterización no lo habría detectado: su prueba de auditoría no
  incluye un reintento.
- `retirar` y `transferir` devuelven el movimiento, porque la auditoría quiere la comisión, que solo el servicio calcula.

---

## 7. 💻 Paso 4 — La auditoría envuelve

```java
// Decorator: audita lo que hace otro OperacionesCuenta, sin que este sepa que existe la auditoría.
public final class OperacionesAuditadas implements OperacionesCuenta {

    private final OperacionesCuenta envuelto;
    private final Auditoria auditoria;

    @Override
    public Movimiento retirar(String numero, double monto) {
        Movimiento m = envuelto.retirar(numero, monto);   // si lanza, no se audita: igual que antes
        auditoria.registrar("RETIRO", numero + " " + m.monto() + " comisión " + m.comision());
        return m;
    }

    @Override
    public List<Movimiento> extracto(String numero) {
        return envuelto.extracto(numero);                  // las consultas no se auditan
    }
}
```

- El servicio ya no conoce a `Auditoria`: su constructor perdió ese parámetro. Probar un retiro no toca la tabla de
  auditoría, y probar la auditoría no necesita base de datos (`CadenaYDecoradorTest` usa una auditoría en memoria y un
  servicio falso).
- La auditoría ocurre **después** y solo si la operación terminó bien, que es lo que hacía el legado. Un decorador que
  quisiera auditar también los intentos fallidos usaría `try`/`finally`, y sería otro decorador, con otro nombre.
- La fachada compone las piezas en su raíz de composición:

```java
this.operaciones = new OperacionesAuditadas(new ServicioMovimientos(cuentas, movimientos, notificador), auditoria);
```

La red: la prueba que congelaba el defecto se cambia, y nada más cae.

| Prueba en `14/01` | Prueba en `14/05` |
|---|---|
| `transferir_unMenorPasaElTopeQueNoPuedeRetirar` | `transferir_unMenorNoPasaElTope`, con el mensaje y el saldo de Luis intacto |

```text
[INFO] Compiling 23 source files with javac [debug release 21] to target/classes
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0 -- in banco.DineroTest
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0 -- in banco.EstadoCuentaTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CadenaYDecoradorTest
[INFO] Tests run: 30, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

`cadaOperacionDejaUnaFilaDeAuditoria`, la prueba de `14/01` que contaba filas, siguió en verde sin cambios: el decorador
audita exactamente lo que auditaba el código de dentro.

---

## 8. 🧪 Evidencia

| | `estados/04` | `estados/05` |
|---|---|---|
| Código de producción | 723 líneas, 18 clases | 871 líneas, 23 clases |
| `ServicioMovimientos` | 101 líneas, 6 `throw` | 95 líneas, 1 `throw` (el monto del depósito) |
| `auditoria.registrar` en `ServicioMovimientos` | 3 | 0 |
| Dónde está el tope de los menores | Solo en `retirar` | Un eslabón, en las dos cadenas |
| Defectos congelados que quedan | 1 | 0 |
| Pruebas | 28 | 30; una de caracterización cambiada |

Con este taller, los seis defectos que congeló `14/01` están corregidos, cada uno en su paso y con su prueba nombrada.

---

## 9. 🏷️ Lo que costó, y cuándo no

**Lo que costó:**

- **Líneas:** 148 más y cinco archivos. Los eslabones como clases anónimas son verbosos; en Java no hay forma más corta que
  conserve el `final` de `verificar`.
- **Indirección:** para saber por qué se rechazó una transferencia, hay que ir de la cadena al eslabón. A cambio, la lista
  de reglas de cada operación se lee en tres líneas.
- **Lectura:** el orden de la cadena importa y no es evidente. Cada cadena necesita su prueba de orden, y hoy solo hay
  una (E2).
- **Rigidez:** la interfaz `OperacionesCuenta` cambió las firmas (`boolean`, `Movimiento`) para que el decorador pudiera
  trabajar. Un decorador nuevo que necesite otro dato vuelve a tocar la interfaz.

**Cuándo no:** la cadena, cuando hay dos o tres validaciones que no se comparten entre operaciones: un método privado con
nombre es más claro. El decorador, cuando hay un solo punto de entrada o cuando el marco ya trae la interceptación —en
Spring, un aspecto o un `HandlerInterceptor` hacen el mismo trabajo (`13/01`)—. Aquí se escribe a mano porque el módulo no
tiene marco, y porque escribirlo a mano es lo que se pregunta en la entrevista.

> **Veredicto:** las reglas que se comparten entre operaciones se vuelven eslabones con nombre, y lo transversal se vuelve
> un envoltorio que el negocio no conoce; el precio es un orden que hay que probar y una interfaz que dice lo que el
> decorador necesita saber.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La auditoría es un `if` más en cada método" | Es una preocupación transversal: escrita en cada método, se olvida en uno; como decorador, envuelve a todos |
| "Chain of Responsibility es una lista de validaciones" | La cadena puede cortar, y el orden decide el mensaje; una lista que siempre recorre todo es otra variante |
| "Si la caracterización está en verde, el orden de la cadena está bien" | La caracterización no cubre todas las combinaciones; aquí, invertir dos eslabones no tumbó ninguna |
| "El decorador no cambia la interfaz" | No cambia la del objeto decorado, pero puede obligar a que la interfaz diga más: aquí, `boolean` y `Movimiento` |
| "Para corregir el tope basta copiar el `if` a `transferir`" | Arregla el síntoma y deja dos copias que se pueden volver a separar |
| "Un decorador audita todo, también lo que falla" | Este audita lo que terminó bien, como el legado; auditar intentos es otra decisión y otro decorador |

---

## 📚 Para profundizar

- **Libro** — Kerievsky, *Refactoring to Patterns* (Addison-Wesley, 2004), cap. 7, *Move Embellishment to Decorator*.
  **El que destaca.**
- **Libro** — Gamma, Helm, Johnson y Vlissides, *Design Patterns* (Addison-Wesley, 1994), cap. 4, "Decorator", y cap. 5,
  "Chain of Responsibility".
- **Libro** — Freeman y Robson, *Head First Design Patterns*, 2.ª ed. (O'Reilly, 2021), cap. 3, "The Decorator Pattern".
- [Industrial Logic — *Move Embellishment To Decorator*](https://www.industriallogic.com/refactoring-to-patterns/catalog/embellishmentToDecorator.html)
- [Jakarta Servlet 6.1 — `Filter`](https://jakarta.ee/specifications/servlet/6.1/apidocs/jakarta.servlet/jakarta/servlet/filter):
  la cadena que acumula y puede cortar, en el contenedor.

---

## 🧠 Preguntas

1. ¿Qué variante de Chain of Responsibility usa este taller, y cómo corta? 🟢
2. ¿Qué preocupación saca el decorador del servicio, y por qué se llama transversal? 🟢
3. ¿Por qué `verificar` es `final` y `comprobar` abstracto? 🟡
4. ¿Por qué `depositar` pasó a devolver un `boolean`? 🟡
5. ¿Qué diferencia hay entre corregir el tope copiando el `if` y añadiendo un eslabón? 🟡
6. ¿Por qué el depósito no tiene su propia cadena? 🟠
7. ¿Qué pasaría si `OperacionesAuditadas` auditara antes de llamar al envuelto? 🟠
8. Si invertir dos eslabones no tumba ninguna prueba de caracterización, ¿qué te dice eso de la red? 🟠
9. ¿Cuándo usarías un aspecto de Spring en lugar de este decorador? 🟠
10. El negocio pide que, en la pantalla de transferencias, se muestren todos los motivos de rechazo a la vez. ¿Qué
    cambia en la cadena? 🔴

---

## 🧪 Ejercicios

Sobre `estados/05`.

**E1.** Añade la regla "una transferencia no puede superar 10 000 000" solo a las transferencias, con su prueba, y
comprueba que un retiro de ese monto sigue permitido. 🟢

**E2.** Pon el tope de los menores antes de `origenPuedeRetirar` en la cadena del retiro y corre la suite. Después
escribe la prueba que habría detectado el cambio. 🟡

**E3.** Escribe un segundo decorador que mida cuánto tarda cada operación, apílalo con el de auditoría, y di en qué orden
los compones y por qué. 🟠

**E4.** Añade a `Regla` una forma de recorrer la cadena sin cortar que devuelva todos los mensajes de error, y pruébala
con una transferencia de un menor, bloqueado y en dólares, a una cuenta en pesos. 🔴

---

**Anterior:** [`04` — Strategy y State](04-strategy-y-state.md) · **Siguiente:** [`06` — Eventos y bloqueo optimista](06-eventos-y-bloqueo-optimista.md) ·
**Relacionado:** [`06/05` — Chain of Responsibility](../06-comportamiento/05-chain-of-responsibility.md)
