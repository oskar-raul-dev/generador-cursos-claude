# 10 — Simulación de entrevista

> El examen del bloque `06-comportamiento`: preguntas transversales que cruzan los nueve capítulos y cinco
> ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-strategy.md) a
> [`09`](09-memento-e-interpreter.md). Las respuestas, en
> [`11` — Respuestas](11-respuestas.md#10--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Preguntando quién decide.** En este bloque, casi todas las distinciones —Strategy contra State, Chain contra
  Observer, Observer contra Mediator— se resuelven preguntando quién elige, quién cambia y quién se entera.
- **Diciendo qué absorbió el lenguaje.** Lambdas, tipos sellados, `switch` exhaustivo, iteradores: el entrevistador
  quiere oír qué parte del patrón ya no se escribe.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Algoritmos que varían

**S1.** ¿Qué diferencia hay entre Strategy, State y Template Method? 🟡

**S2.** ¿Por qué una lambda puede ser una estrategia? 🟢

**S3.** ¿Por qué `JdbcTemplate` no es un Template Method en sentido estricto? 🟠

**S4.** ¿Cuándo un `switch` es mejor que un Strategy? 🟠

**S5.** ¿Qué es el idioma NVI de C++? 🟢

### Bloque B — Notificar, pedir y encadenar

**S6.** ¿Qué diferencia hay entre Observer y publicar/suscribir con un *broker*? 🟡

**S7.** ¿Por qué un observador olvidado provoca una fuga de memoria? 🟠

**S8.** ¿Los eventos de Spring son síncronos o asíncronos, y qué implica? 🟡

**S9.** ¿Por qué `Runnable` es un Command incompleto? 🟢

**S10.** ¿Por qué deshacer una transferencia no es borrarla? 🟠

**S11.** ¿Qué diferencia hay entre la cadena que se corta y la que acumula? 🟡

**S12.** ¿Qué diferencia hay entre Chain of Responsibility, Observer y Mediator? 🟡

### Bloque C — Estados y tipos

**S13.** ¿Por qué dos *flags* booleanos son peores que un estado? 🟠

**S14.** ¿Cuándo usarías una interfaz sellada con records en lugar de un `enum` para los estados? 🟠

**S15.** ¿Qué es el *double dispatch*, y por qué existe Visitor? 🟢

**S16.** ¿Cuándo Visitor todavía gana a los tipos sellados? 🟠

**S17.** ¿Qué pierde un `switch` sobre un tipo sellado si tiene `default`? 🟠

### Bloque D — Lo que el lenguaje absorbió

**S18.** ¿Por qué casi nunca se escribe un Iterator a mano? 🟠

**S19.** ¿Qué reemplazó a Memento? 🟠

**S20.** ¿Qué queda vivo de Interpreter? 🟡

**S21.** Nombra tres patrones de este bloque que una lambda reduce a una línea, y uno que no. 🟡

### Bloque E — Los lenguajes

**S22.** ¿Qué diferencia hay entre `std::function` y un parámetro de plantilla como estrategia? 🟡

**S23.** ¿Qué diferencia hay entre el Visitor clásico en C++ y `std::variant` con `std::visit`? 🟡

**S24.** ¿Cómo evita C++ moderno el observador colgante? 🟠

**S25.** ¿Qué aportan los `event` de C# al Observer, y qué no resuelven? 🟡

### Bloque F — Las que descolocan

**S26.** "Strategy y State son el mismo patrón con otro nombre." ¿Qué respondes? 🔴

**S27.** "En mi equipo prohibimos los `switch`: todo se resuelve con polimorfismo." ¿Estás de acuerdo? 🔴

**S28.** El entrevistador te pide implementar Visitor en Java 21. ¿Qué haces? 🔴

**S29.** "Los eventos de Spring desacoplan, así que todo debería comunicarse por eventos." ¿Qué le dices? 🔴

**S30.** "¿Para qué Command si existe `Runnable`?" 🔴

**S31.** Te piden "el patrón de comportamiento que más usas". ¿Qué respondes, y cómo lo defiendes? 🔴

**S32.** "Template Method es herencia, y la herencia es mala: nunca lo usaría." ¿Qué matizas? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Tres enunciados, tres patrones (elegir)

**Fuerza:** distinguir Strategy, State y Template Method por quién decide y qué varía.

1. El cálculo del interés mensual depende del producto contratado (ahorro básico, ahorro programado, CDT), y el
   negocio añade productos dos veces al año.
2. Un trámite de apertura pasa por `SOLICITADO`, `EN_REVISION`, `APROBADO` y `RECHAZADO`, y en cada estado solo se
   permiten algunas acciones.
3. Las exportaciones a CSV, JSON y XML siempre abren el destino, escriben una cabecera, escriben las filas y cierran;
   cambia el formato de la cabecera y de las filas.

Di qué patrón usarías en cada uno, por qué, y qué precio pagas.

### E2 — El Visitor de los movimientos (refactorizar)

**Fuerza:** reemplazar un patrón por la característica del lenguaje que lo absorbió, sin perder la garantía.

El código tiene un `VisitanteMovimiento<R>` con cinco métodos, cinco records con su `aceptar`, y cuatro visitantes
(extracto, CSV, efecto en saldo, informe del regulador). El proyecto pasó a Java 21. Propón la refactorización y di qué
se conserva y qué se gana.

### E3 — Los avisos de vencimiento sin fugas (diseñar)

**Fuerza:** diseñar un Observer con su ciclo de vida, y decidir síncrono contra asíncrono.

Cuando un documento está por vencer hay que avisar al titular (y a su tutora si es menor), marcarlo en el panel de
operaciones —cuyas pantallas abren y cierran los operadores— y registrarlo en auditoría. El correo no debe enviarse si
la revisión nocturna falla a mitad. Diseña la solución y escribe lo esencial.

### E4 — El texto del estado (elegir, sin patrón)

**Fuerza:** reconocer que un `switch` exhaustivo sobre un `enum` cerrado es la respuesta.

La pantalla de cuentas muestra el estado con un texto y un color: `ABIERTA` en verde, `BLOQUEADA` en ámbar y `CERRADA`
en gris. Un compañero propone una interfaz `PresentacionEstado` con tres implementaciones y un mapa para elegirlas.
Diseña la solución.

### E5 — La aprobación que nadie atiende (revisar)

**Fuerza:** encontrar en una cadena los defectos de orden y de final.

```java
var cadena = List.<Aprobador>of(
        hastaMonto(Dinero.cop("5000000.00"),  t -> Aprobacion.automatica()),
        new FiltroListasRestrictivas(listas),
        hastaMonto(Dinero.cop("50000000.00"), supervisores::pedir));

public Aprobacion aprobar(Transferencia t) {
    for (Aprobador a : cadena) {
        Optional<Aprobacion> r = a.aprobar(t);
        if (r.isPresent()) return r.get();
    }
    return null;
}
```

Nombra los defectos por gravedad y escribe la versión corregida.

---

## 4. 🧭 Las frases que hay que tener listas

> "Strategy lo elige alguien de fuera; State lo cambian las propias operaciones del objeto; Template Method fija el
> esqueleto y deja variar un paso por herencia."

> "Visitor existe porque el lenguaje solo despacha por el receptor. En Java 21 lo reemplazo con un tipo sellado y un
> `switch` exhaustivo, que me da la misma garantía con un tercio del código."

> "Un Observer necesita una suscripción que se cierre; el observador que nadie desuscribe es la fuga clásica."

---

**Anterior:** [`09` — Memento e Interpreter](09-memento-e-interpreter.md) ·
**Siguiente:** [`11` — Respuestas](11-respuestas.md) ·
**Relacionado:** [`01` — Strategy](01-strategy.md)
