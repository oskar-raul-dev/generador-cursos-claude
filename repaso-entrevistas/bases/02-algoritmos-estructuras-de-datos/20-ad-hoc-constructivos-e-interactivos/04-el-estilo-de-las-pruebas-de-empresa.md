# 04 — El estilo de las pruebas de empresa

> Los problemas típicos de una prueba técnica de empresa no son difíciles por el algoritmo sino por todo lo
> demás: un enunciado largo con una regla escondida, una entrada que hay que trocear, fechas y horas que
> cruzan la medianoche, un formato de salida que se compara carácter a carácter y una nota que se reparte por
> casos. Qué hacer con cada cosa, con ejemplos en Java.
>
> **Niveles:** el formato de empresa [A].
>
> **📚 Lectura troncal:** McDowell, *Cracking the Coding Interview*, 6.ª ed. (CareerCup, 2015); Aziz, Lee y
> Prakash, *Elements of Programming Interviews in Java* (2015).
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--leer-el-enunciado-dos-veces) · [3](#3--trocear-la-entrada) · [4](#4--fechas-y-horas) · [5](#5--la-salida-exacta) · [6](#6--asegurar-la-puntuación-parcial) · [7](#7--codility-y-coderbyte-como-formatos) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

La prueba dice: «Dado un registro de fichajes con líneas `AAAA-MM-DD HH:MM nombre ENTRADA|SALIDA`, calcula las
horas trabajadas por cada empleado en la semana, redondeadas a dos decimales, ordenadas por nombre». No hay
ninguna técnica del corpus que aplicar: es un mapa y una suma. Y sin embargo es donde más candidatos
pierden puntos: el turno que cruza la medianoche, el empleado sin salida, el redondeo de `7,125` horas, la
línea en blanco al final del fichero, el espacio de más en la salida.

Este capítulo trata de **eso**: el oficio de leer, trocear, calcular con fechas y escribir exactamente lo
que se pide, y de asegurar la nota cuando no da tiempo a todo. La parte de cómo puntúan las plataformas está
en [`01/01`](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md); aquí va lo que se
hace con el teclado.

> 🧠 **Modelo mental.** En una prueba de empresa, el enunciado es un contrato: cada palabra es una regla y
> cada ejemplo, un caso de prueba. El programa se escribe para el contrato, no para los ejemplos.

---

## 2. 🧱 Leer el enunciado dos veces

**Qué es.** Leer el enunciado entero una vez para entender el problema y otra, despacio, para **listar las
reglas**: formatos, unidades, casos especiales, orden de la salida, qué hacer con las entradas inválidas.

**Cómo va**, con el registro de fichajes:

```text
1. ¿Qué entra?           líneas con fecha, hora, nombre y tipo; ¿pueden venir desordenadas?
2. ¿Qué sale?            nombre y horas, ¿con qué separador?, ¿orden por nombre: mayúsculas antes?
3. ¿Unidades?            horas con dos decimales: ¿redondeo o truncado?, ¿half-up?
4. ¿Casos especiales?    turno que cruza la medianoche, ENTRADA sin SALIDA, dos ENTRADAS seguidas
5. ¿Límites?             cuántas líneas: ¿cabe todo en memoria?, ¿hace falta algo más que un mapa?
```

**Cuánto cuesta.** Cinco minutos de una prueba de noventa. Una regla que se descubre al final cuesta un
rediseño.

**Cuándo sí:** siempre; y si el enunciado es ambiguo y hay a quién preguntar, se pregunta. **Cuándo no:**
nunca se salta; si no hay a quién preguntar, se elige una interpretación y se escribe en un comentario.

> **Veredicto:** la segunda lectura convierte el texto en una lista de reglas. Es la que evita el «no había
> visto que…» a diez minutos del final.

---

## 3. 🧱 Trocear la entrada

**Qué es.** Leer líneas y campos de forma robusta: espacios de más, líneas en blanco, separadores mixtos,
números con signo o con decimales.

**Cómo va.** En Java, leer línea a línea con `BufferedReader`, recortar, saltar las vacías y partir por
espacios (uno o varios):

```java
// Lee todas las líneas no vacías de la entrada, recortadas.
static java.util.List<String> readLines(java.io.BufferedReader in) throws java.io.IOException {
    java.util.List<String> lines = new java.util.ArrayList<>();
    for (String line = in.readLine(); line != null; line = in.readLine()) {
        line = line.strip();
        if (!line.isEmpty()) lines.add(line);
    }
    return lines;
}

// "2026-10-04 08:30 Ana ENTRADA" → sus cuatro campos; split("\\s+") tolera varios espacios.
static String[] fields(String line) { return line.split("\\s+"); }
```

- **`strip()`** (Java 11+) quita espacios Unicode además de los ASCII; `trim()` solo los de código `≤ 32`.
- **`split("\\s+")`** sobre una línea recortada no deja campos vacíos; `split(" ")` sí, con dos espacios
  seguidos.
- **`Integer.parseInt`** lanza excepción con `"+5"` en versiones antiguas y siempre con `" 5"`: se recorta antes.
  Para importes, `new BigDecimal(campo)`, nunca `Double.parseDouble` si luego hay que redondear.

**Cuánto cuesta.** Lineal en el tamaño de la entrada; con millones de líneas, `BufferedReader` y no `Scanner`
([`01/03`](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md)).

**Cuándo sí:** en todas las pruebas con entrada en texto. **Cuándo no:** en las que dan la entrada ya como
parámetros de una función (LeetCode, Codility): ahí el trabajo es validar, no trocear.

> **Veredicto:** recorta, salta vacías, parte por `\s+`, convierte con el tipo correcto. Cuatro líneas que
> evitan la mitad de los fallos de lectura.

---

## 4. 🧱 Fechas y horas

**Qué es.** Calcular con fechas y horas sin errores: diferencias, días de la semana, años bisiestos, turnos que
cruzan la medianoche.

**Cómo va.** Dos reglas: las horas del día se pasan a **minutos desde la medianoche**, y las fechas se dejan a
`java.time`, que es parte de la librería estándar desde Java 8:

```text
"08:30" → 8·60 + 30 = 510          "22:00"–"02:00": fin ≤ inicio → fin + 1 440 → dura 240 minutos
LocalDate.parse("2026-02-27") → 2026-03-02: ChronoUnit.DAYS.between = 3   (febrero de 2026 tiene 28 días)
LocalDate.parse("2026-10-04").getDayOfWeek() = SUNDAY
```

```java
static int minutesOfDay(String hhmm) {                         // "08:30" → 510
    return Integer.parseInt(hhmm.substring(0, 2)) * 60 + Integer.parseInt(hhmm.substring(3, 5));
}

// Duración de un turno en minutos; si termina antes o a la misma hora que empieza, cruza la medianoche.
static int shiftMinutes(String start, String end) {
    int a = minutesOfDay(start), b = minutesOfDay(end);
    return b > a ? b - a : b + 1440 - a;
}

static long daysBetween(String from, String to) {              // "2026-02-27", "2026-03-02" → 3
    return java.time.temporal.ChronoUnit.DAYS.between(
        java.time.LocalDate.parse(from), java.time.LocalDate.parse(to));
}
```

- **`java.time`** sabe de bisiestos (2024-02-28 más un día es 2024-02-29) y de días de la semana. `Date` y
  `Calendar` son las clases antiguas: no se usan.
- **Zonas horarias**: si el enunciado no las menciona, `LocalDate` y `LocalTime`. Con zonas y cambios de hora,
  `ZonedDateTime`, y aun así una hora puede no existir o existir dos veces.
- **En C++**, `<chrono>` trae calendario desde C++20 (`year_month_day`); en Python, `datetime`. Sin librería,
  el algoritmo de los «días desde una época» (Hinnant) convierte una fecha en un entero en `O(1)`.

### De la versión ingenua a la buena

**El problema.** El número de días entre dos fechas `AAAA-MM-DD` de entre los años 1900 y 2100.

**La versión ingenua**, contando día a día:

```java
// Correcta: avanza de un día en un día con las reglas del calendario. O(días): hasta 73 000 vueltas.
static long daysBetweenNaive(int y1, int m1, int d1, int y2, int m2, int d2) {
    int[] len = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    long count = 0;
    while (y1 != y2 || m1 != m2 || d1 != d2) {
        boolean leap = (y1 % 4 == 0 && y1 % 100 != 0) || y1 % 400 == 0;
        int days = (m1 == 2 && leap) ? 29 : len[m1 - 1];
        if (++d1 > days) { d1 = 1; if (++m1 > 12) { m1 = 1; y1++; } }
        count++;
    }
    return count;
}
```

> «Esto funciona y para una consulta es rápido, pero con `10⁵` consultas son `7·10⁹` pasos, y además he
> reescrito la regla del bisiesto, que es donde se equivoca todo el mundo. `java.time` ya la tiene: convierte
> cada fecha en un número de día y resta.»

**El camino a la buena.** `ChronoUnit.DAYS.between` (o `toEpochDay()` de cada fecha y restar): `O(1)` por
consulta, con el calendario de la librería.

**Cuándo sí:** siempre que haya fechas: la librería estándar de cada lenguaje. **Cuándo no:** si el enunciado
define su propio calendario (meses de 30 días, años de 360), se programa esa regla y no la real.

> **Veredicto:** horas a minutos, fechas a `java.time`, y el cruce de medianoche como caso explícito. La regla
> del bisiesto no se reescribe en una prueba.

---

## 5. 🧱 La salida exacta

**Qué es.** Escribir exactamente el formato pedido: separadores, mayúsculas, número de decimales, redondeo,
orden, línea final. La mayoría de los jueces de empresa comparan la salida **carácter a carácter** (a veces
ignorando espacios al final).

**Cómo va.** El caso que más falla es el redondeo de importes. Con un IVA del 21 % sobre 0,50 €, el impuesto es
exactamente 0,105 €, y redondeado *half-up* son 0,11 €. Con `double`, `0.5 * 0.21` es un número un poco menor
que 0,105, y cada lenguaje lo imprime a su manera:

```text
Python:   f"{0.5 * 0.21:.2f}"            → 0.10   (redondea el valor binario exacto)
Java:     String.format("%.2f", 0.5*0.21) → 0.11   (redondea la representación decimal más corta)
centavos: (50 · 21 + 50) / 100 = 11      → 0.11   (exacto en enteros, en cualquier lenguaje)
```

```java
// Importe en céntimos → "12.34". Para no negativos.
static String money(long cents) {
    return (cents / 100) + "." + String.format("%02d", cents % 100);
}

// Porcentaje con redondeo half-up en enteros: (cents · pct + 50) / 100.
static long percentHalfUp(long cents, long pct) { return (cents * pct + 50) / 100; }
```

- **Dinero en céntimos (enteros)** o en `BigDecimal` con `setScale(2, RoundingMode.HALF_UP)`; nunca en
  `double`.
- **El mismo `double` se imprime distinto en Java y en Python**: Java redondea la representación decimal más
  corta (`2.675` → `2.68`), Python y C el valor binario (`2.67`). Si el resultado depende de eso, el cálculo
  está mal planteado.
- **Separadores y locale**: `String.format` usa el *locale* por defecto; en un sistema en español escribe `0,11`.
  `String.format(Locale.ROOT, …)` fija el punto.
- **Orden**: «ordenado por nombre» con `String.compareTo` pone las mayúsculas antes que las minúsculas; si el
  enunciado no lo aclara, se pregunta.

**Cuándo sí:** siempre: cada salida se compara con el formato del ejemplo, carácter a carácter. **Cuándo no:**
en las pruebas que piden devolver un valor desde una función, el formato lo pone la plataforma.

> **Veredicto:** la salida es parte del contrato. Céntimos en enteros, el *locale* fijado y el formato
> comparado con el ejemplo antes de enviar.

---

## 6. 🧱 Asegurar la puntuación parcial

**Qué es.** Organizar el tiempo para que la nota no dependa de terminarlo todo: en una prueba con casos
puntuados por separado, cada caso que pasa suma.

**Cómo va.** Primero, una versión que pase los casos pequeños (fuerza bruta, [`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)),
con los casos borde del enunciado cubiertos: entrada vacía, un solo elemento, valores en el límite. Se envía.
Después, la versión eficiente, conservando la fuerza bruta para comparar. Si el tiempo se acaba a medio
camino, la nota es la de la versión enviada.

**Cuánto cuesta.** Unos minutos de más por problema; a cambio, la nota mínima ya está asegurada.

**Cuándo sí:** HackerRank y Codility puntúan por casos; Codility separa además corrección y rendimiento. **Cuándo
no:** en las plataformas que solo dan «todo o nada», la fuerza bruta sirve solo para comprobar.

> **Veredicto:** envía pronto una versión correcta y lenta; mejora después. Una prueba de empresa premia la
> nota final, no la elegancia de la primera versión.

---

## 7. 🧱 Codility y Coderbyte como formatos

**Qué es.** Dos formatos de prueba frecuentes. **Codility**: una función a completar, unos pocos ejemplos
visibles y una batería oculta que puntúa **corrección** y **rendimiento** por separado (con casos grandes).
**Coderbyte**: problemas cortos, a veces con la entrada y la salida como cadenas dentro de una función, y
pruebas ocultas.

**Cómo va.** En los dos, el enunciado da los rangos: leerlos para saber qué complejidad pide el rendimiento
([`01/02`](../01-oficio-del-competidor/02-leer-las-restricciones.md)); y en los dos, los casos visibles son
pocos: los casos borde los pones tú.

**Cuánto cuesta.** Lo mismo que cualquier prueba; lo distinto es que no ves los casos que fallan.

**Cuándo sí:** cuando la empresa anuncia la plataforma: practicar en ella su formato (las *Lessons* de
Codility). **Cuándo no:** no hace falta aprender trucos de la plataforma; lo que se evalúa es lo mismo.

> **Veredicto:** en Codility y Coderbyte no ves los fallos: escribe tus propios casos borde y vigila el
> rendimiento con los rangos máximos.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Los problemas de empresa son fáciles» | El algoritmo suele serlo; los puntos se pierden en reglas, fechas, formato y casos borde |
| «Con leer el enunciado una vez basta» | La segunda lectura lista las reglas; la primera solo da la idea |
| «El dinero se calcula con `double` y se redondea al final» | Con `double`, `0.5 * 0.21` se imprime `0.10` en Python y `0.11` en Java: céntimos en enteros o `BigDecimal` |
| «Un turno de 22:00 a 02:00 dura −20 horas» | Si el fin no es posterior al inicio, cruza la medianoche: se suman 1 440 minutos |
| «La regla del bisiesto es cada cuatro años» | Cada cuatro, salvo los múltiplos de 100 que no lo son de 400 |
| «Si pasa los ejemplos, pasa la prueba» | Los ejemplos son el mínimo; los casos ocultos son los bordes y los grandes |

---

## 📚 Para profundizar

- **Libro** — McDowell, *Cracking the Coding Interview*, 6.ª ed. (CareerCup, 2015), secciones I–VI: el proceso
  de las entrevistas y qué evalúan. *Lectura troncal.*
- **Libro** — Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2015), cap. 1 (la estrategia
  en la entrevista) y los capítulos de cadenas. *Lectura troncal.*
- **Referencia** — documentación de Java, [`java.time`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/package-summary.html):
  fechas, horas y duraciones.

---

## 🧠 Preguntas

1. ¿Qué buscas en la segunda lectura de un enunciado de empresa? 🟢
2. ¿Por qué se pasan las horas a minutos desde la medianoche? 🟢
3. ¿Cuál es la regla completa de los años bisiestos? 🟢
4. ¿Qué diferencia hay entre `split(" ")` y `split("\\s+")` sobre una línea con dos espacios seguidos? 🟡
5. ¿Qué diferencia hay entre redondear el valor binario de un `double` y redondear su representación decimal más
   corta? 🟡
6. ¿Cómo calculas la duración de un turno que cruza la medianoche? 🟡
7. ¿Qué cambia entre Java, Python y C++ al imprimir `0.5 * 0.21` con dos decimales? 🟠
8. ¿Por qué el *locale* puede cambiar la salida de `String.format`, y cómo lo evitas? 🟠
9. ¿Cómo aseguras la puntuación parcial en una prueba de 90 minutos con tres problemas? 🟠
10. ¿Qué casos borde añadirías siempre a una prueba de Codility, si no ves los ocultos? 🟠
11. Diseña el cálculo de horas trabajadas por empleado a partir de un registro de fichajes desordenado, con
    turnos que cruzan la medianoche y salidas que faltan, y di qué preguntarías antes. 🔴
12. Demuestra que `(c · p + 50) / 100` en división entera redondea *half-up* el `p %` de `c` céntimos, para
    `c, p ≥ 0`. 🔴

---

## 🧩 Problemas propios

### Turnos que se pisan

**Nivel:** 🟡 · **Formato:** programa completo.

Cada turno es `HH:MM-HH:MM`. Si el fin es igual o anterior al inicio, el turno termina al día siguiente. Los
turnos se repiten cada día. ¿Cuántos pares de turnos se solapan durante un tiempo positivo? Tocarse en un
instante no cuenta.

- **Entrada.** Una línea con `n`. Después, `n` líneas con un turno.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2 000`; ningún turno dura más de 23 horas.

```text
Entrada         Salida
5               2
08:00-12:00
11:30-14:00
22:00-02:00
01:00-03:00
14:00-15:00

Entrada         Salida
2               0
00:00-23:00
23:00-00:00
```

**Pista 1:** si un turno que cruza la medianoche se escribe como un intervalo que pasa de 1 440 minutos, ¿con qué
«copias» de los otros turnos tienes que compararlo?

### El ticket

**Nivel:** 🟡 · **Formato:** programa completo.

Una caja suma artículos (cantidad y precio unitario con dos decimales), calcula un IVA del 21 % sobre la suma,
redondeado *half-up* al céntimo, y escribe `TOTAL: ` seguido del total con dos decimales y punto.

- **Entrada.** Una línea con `n`. Después, `n` líneas con la cantidad y el precio (`12.30`).
- **Salida.** Una línea `TOTAL: X.YY`.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `1 ≤` cantidad `≤ 1 000`; precio entre `0.01` y `9999.99`.

```text
Entrada         Salida
2               TOTAL: 6.84
3 1.10
1 2.35

Entrada         Salida
1               TOTAL: 0.61
1 0.50
```

**Pista 1:** ¿en qué unidad puedes hacer todas las cuentas sin un solo número decimal, y cómo redondeas en esa
unidad?

### Códigos de producto

**Nivel:** 🟢 · **Formato:** programa completo.

Un código válido tiene tres mayúsculas, un guion, cuatro dígitos, un guion y una mayúscula de control: la letra
número `s mod 26` del alfabeto inglés (`A` es la 0), con `s` la suma de los cuatro dígitos. Puede haber espacios
antes o después, que no cuentan. Imprime `VALIDO` o `INVALIDO` para cada línea.

- **Entrada.** Una línea con `n`. Después, `n` líneas con un código.
- **Salida.** `n` líneas.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; cada línea tiene como mucho 50 caracteres.

```text
Entrada           Salida
4                 VALIDO
ABC-1234-K        INVALIDO
abc-1234-K        VALIDO
 XYZ-0000-A       INVALIDO
XY-12345-B

Entrada           Salida
2                 VALIDO
  ZZZ-9999-K      INVALIDO
ZZZ-9999-k
```

**Pista 1:** ¿qué compruebas antes, la forma o la letra de control, y qué haces con los espacios del borde?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de enviar, compara tu salida con la del ejemplo carácter a carácter (con `diff`, no a
> ojo). Si una IA te ayuda, que sea a listar casos borde del enunciado
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). Coderbyte no se enlaza: responde
> `403` a `curl` y no se ha verificado con navegador.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Day of the Programmer](https://www.hackerrank.com/challenges/day-of-the-programmer/problem) | HackerRank | 🟢 | Calendario con reglas propias | ¿Qué calendario rige cada rango de años, y qué tiene de especial 1918? |
| [ ] | [Reformat Date](https://leetcode.com/problems/reformat-date/) | LeetCode | 🟢 | Trocear y formatear | ¿Cómo quitas el sufijo del día (`st`, `nd`…) y conviertes el mes a número? |
| [ ] | [Day of the Year](https://leetcode.com/problems/day-of-the-year/) | LeetCode | 🟢 | Bisiestos | ¿Cuántos días suman los meses anteriores, y cuándo febrero tiene 29? |
| [ ] | [Number of Days Between Two Dates](https://leetcode.com/problems/number-of-days-between-two-dates/) | LeetCode | 🟢 | Días desde una época | Si conviertes cada fecha en «días desde el 1 de enero de 1971», ¿qué queda? |
| [ ] | [Reformat Phone Number](https://leetcode.com/problems/reformat-phone-number/) | LeetCode | 🟢 | Formato de salida | ¿Qué haces con los últimos 4 dígitos para no dejar un bloque de uno? |
| [ ] | [Count Days Spent Together](https://leetcode.com/problems/count-days-spent-together/) | LeetCode | 🟢 | Intersección de fechas | Si cada fecha es un número de día del año, ¿cuánto mide la intersección de dos intervalos? |
| [ ] | [Minimum Time Difference](https://leetcode.com/problems/minimum-time-difference/) | LeetCode | 🟡 | Minutos y medianoche | Tras ordenar los minutos, ¿qué par se te olvida comparar? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Integer to English Words](https://leetcode.com/problems/integer-to-english-words/) | LeetCode | 🔴 | Reglas y bloques de tres | ¿Qué parte del número se escribe igual en cada bloque de tres cifras, y qué cambia entre bloques? |
| [ ] | [Text Justification](https://leetcode.com/problems/text-justification/) | LeetCode | 🔴 | Salida exacta | En una línea con `k` palabras y `s` espacios que repartir, ¿qué huecos reciben uno de más? |

---

## ✅ Criterio de dominio

- Listar las reglas de un enunciado largo antes de escribir, en cinco minutos.
- Calcular duraciones con cruce de medianoche y diferencias de fechas con `java.time` sin mirar.
- Escribir importes en céntimos con redondeo *half-up* y explicar por qué no con `double`.
- Resolver Minimum Time Difference, Number of Days Between Two Dates y Reformat Phone Number sin pista 2.

---

**Anterior:** [`20/03` — Interactivos](03-interactivos.md) · **Siguiente:** [`20/05` — Heurísticos y aproximados](05-heuristicos-y-aproximados.md) ·
**Relacionado:** [`01/01` — El juez, los veredictos y las plataformas](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md).
