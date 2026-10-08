# 05 — Bits y aritmética binaria

> El complemento a dos y por qué `Math.abs(Integer.MIN_VALUE)` es **negativo**, el desbordamiento
> silencioso que ya ha aparecido dos veces en este corpus, los operadores que hay que saber leer, y
> las máscaras de bits, que son la estructura de datos más barata que existe.
> Asume leído [`01` — Complejidad y O grande](01-complejidad-y-o-grande.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tres cosas ya escritas en este corpus son en realidad **el mismo tema**, y hasta ahora se han
explicado por separado:

```text
mid = (lo + hi) / 2                 → desborda con arreglos enormes   (`03-orden-busqueda/03`)
(a, b) -> a.importe() - b.importe() → desborda y rompe el comparador  (`03-orden-busqueda/02`)
índice = hash & (capacidad - 1)     → solo funciona con potencias de 2 (`03-orden-busqueda/04`)
```

Los tres salen de cómo una máquina representa los enteros. Y hay un cuarto que casi nadie conoce y
que es el más incómodo de todos:

```java
Math.abs(Integer.MIN_VALUE)   // → -2147483648.  El valor absoluto de un número es NEGATIVO.
```

No es un bug de la JDK: es aritmética de complemento a dos, y está documentado. Quien no entiende
por qué, tarde o temprano escribe un `hashCode` o un generador de índices que falla una vez cada
cuatro mil millones de veces — que en un sistema con tráfico significa una vez al día.

> **Regla de entrevista:** siempre que veas una resta, una suma o un desplazamiento sobre enteros
> con datos de tamaño desconocido, la pregunta correcta es **"¿puede desbordar?"**. En Java y Go la
> respuesta por defecto es sí, y en silencio.

---

## 2. 🧱 Complemento a dos y el rango asimétrico

**Qué es.** La representación con la que prácticamente todas las máquinas guardan enteros con signo:
el bit más alto vale negativo, y el negativo de un número se obtiene invirtiendo todos los bits y
sumando uno.

```text
int de 32 bits:   rango [-2 147 483 648 , 2 147 483 647]
                          ↑ un valor MÁS en el lado negativo
```

**Por qué el rango es asimétrico.** Hay 2³² combinaciones y el cero ocupa una del lado positivo. El
resultado es que **`MIN_VALUE` no tiene opuesto representable**, y de ahí salen tres hechos
verificados que conviene tener memorizados:

```text
Integer.MIN_VALUE      = -2147483648
Math.abs(MIN_VALUE)    = -2147483648     ← el valor absoluto es negativo
-Integer.MIN_VALUE     = -2147483648     ← negarlo tampoco cambia nada
Integer.MAX_VALUE + 1  = -2147483648     ← y sumar uno al máximo aterriza en el mínimo
```

**Cuánto cuesta ignorarlo.** Nada, hasta que un valor extremo llega por la entrada. Entonces un
`Math.abs(hash) % n` —idioma frecuentísimo para repartir en cubetas— devuelve un índice **negativo**
y lanza `ArrayIndexOutOfBoundsException` en producción con una frecuencia minúscula, que es la peor
clase de bug: el que no se reproduce.

**Cuándo sí** pensarlo: al normalizar un hash, al calcular un índice, al restar tamaños o tiempos.

**Cuándo no:** con valores acotados por el dominio —edades, meses, cantidades de un pedido—, donde
el rango real está a diez órdenes de magnitud del límite.

> **Veredicto:** el rango asimétrico es la consecuencia visible del complemento a dos, y
> `Math.abs(MIN_VALUE)` es la demostración de que no es un detalle académico. La forma segura de
> normalizar un hash no es `Math.abs`, es **enmascarar el bit de signo**: `hash & 0x7fffffff`.

---

## 3. 🧱 El desbordamiento, lenguaje por lenguaje

**Qué es.** Que el resultado de una operación no quepa en el tipo. Lo interesante es que **los cinco
lenguajes hacen cosas distintas**, y esa es la comparación que se pregunta.

| Lenguaje | Qué pasa al desbordar | ¿Avisa? |
|---|---|---|
| **Java** | Da la vuelta en silencio (*wraparound*) | Solo si usas `Math.addExact` y compañía |
| **Python** | **No desborda**: los enteros son de precisión arbitraria | No hace falta |
| **JavaScript** | Todo es un `double`: **pierde precisión** a partir de 2⁵³ | No |
| **TypeScript** | Igual que JavaScript | No |
| **Go** | Da la vuelta en silencio, igual que Java | No hay equivalente a `addExact` en la stdlib |

Los tres hechos verificados que hacen concreta la tabla:

```text
Java:   Integer.MAX_VALUE + 1  → -2147483648        (silencioso)
        Math.addExact(MAX, 1)  → ArithmeticException: integer overflow
Go:     var i int32 = MaxInt32; i+1 → -2147483648   (silencioso)
Python: 2**200 → 1606938044258990275541962092341162602522202993782792835301376
JS:     MAX_SAFE_INTEGER + 1 === MAX_SAFE_INTEGER + 2   → true
```

- **Esa última línea es la más perturbadora**: en JavaScript, dos números distintos son iguales,
  porque a partir de 2⁵³ el `double` ya no puede representar todos los enteros. Es la razón de que
  un identificador de 64 bits que viaje en JSON **se corrompa** al pasar por JavaScript si no va
  como string.
- Python paga su comodidad con rendimiento y memoria: sus enteros son objetos, no palabras de
  máquina. Es un compromiso deliberado.
- Go no trae `addExact`; la comprobación se escribe a mano o se usa `math/big`.

> ⚠️ **Advertencia.** El caso de JavaScript no es teórico: un `id` de base de datos `bigint`
> serializado como número JSON y leído por un front en JS pierde los últimos dígitos **sin ningún
> error**. La solución estándar es transportarlo como `string`, y es una decisión de contrato de API
> que sale de este capítulo.

---

## 4. 🧱 Los operadores, y el que Java tiene de más

Los seis que hay que saber leer:

```text
&    AND bit a bit      1010 & 1100 = 1000
|    OR                 1010 | 1100 = 1110
^    XOR                1010 ^ 1100 = 0110
~    NOT (complemento)   ~0000 = 1111
<<   desplazar a la izquierda    x << 1  ==  x * 2
>>   desplazar a la derecha ARITMÉTICO: conserva el signo
>>>  desplazar a la derecha LÓGICO: rellena con ceros   ← solo Java y JavaScript
```

La diferencia entre `>>` y `>>>` se ve mejor con un negativo, y está verificada:

```text
-8 >> 1   = -4            conserva el signo: es una división entera por 2
-8 >>> 1  = 2147483644    rellena con ceros: el número deja de ser negativo
```

- **`>>>` existe en Java y en JavaScript, y no en Python ni en Go.** En Go, el desplazamiento lógico
  se consigue usando un tipo **sin signo** (`uint32`), que es más explícito y probablemente mejor
  diseño.
- `x << 1` es multiplicar por dos y `x >> 1` dividir por dos **para positivos**. Con negativos, `>>`
  redondea hacia abajo y la división entera redondea hacia cero: `-7 >> 1` es `-4` y `-7 / 2` es
  `-3`. No son equivalentes.
- Escribir `x << 1` en vez de `x * 2` como "optimización" es folclore: el compilador lo hace solo, y
  la versión con multiplicación se lee mejor. La excepción legítima es cuando expresas una
  **potencia de dos** —`1 << 20` para un megabyte— porque ahí el desplazamiento **es** la intención.

---

## 5. 🧱 Máscaras de bits

**El problema.** Guardar un conjunto de opciones —permisos, banderas de configuración, estados
activos— de forma compacta y con operaciones de conjunto baratas.

**Cómo va.** Cada bit es un elemento, y las operaciones de conjunto son operadores:

```text
LECTURA   = 1 << 0   // 0001
ESCRITURA = 1 << 1   // 0010
BORRADO   = 1 << 2   // 0100

permisos = LECTURA | ESCRITURA          // unión:         0011
tiene    = (permisos & ESCRITURA) != 0  // pertenencia:   true
quitar   = permisos & ~ESCRITURA        // diferencia:    0001
alternar = permisos ^ ESCRITURA         // toggle
```

**Cuánto.** Un `long` son 64 elementos en 8 bytes, con unión, intersección y pertenencia en **una
instrucción**. Ningún `HashSet` se acerca.

**Cuándo sí.** Conjuntos pequeños y cerrados de banderas; la DP sobre máscaras de
[`05-dp-y-tecnicas/01`](../05-dp-y-tecnicas/01-programacion-dinamica.md); protocolos binarios y
formatos de archivo, donde el ahorro es del formato y no tuyo.

**Cuándo no.** En código de dominio. Un `int permisos` es ilegible, no tiene seguridad de tipos y
nadie sabe qué significa el bit 5 dos años después.

**La alternativa correcta en Java** es `EnumSet`, que **es una máscara de bits por dentro** —un
`long` cuando el enum tiene 64 valores o menos— con la API de un `Set` y seguridad de tipos:

```java
EnumSet<Permiso> permisos = EnumSet.of(Permiso.LECTURA, Permiso.ESCRITURA);
permisos.contains(Permiso.BORRADO);     // legible, tipado, y tan rápido como la máscara
```

> **Veredicto:** la máscara de bits es imbatible en coste y pésima en legibilidad. Úsala donde el
> formato te obliga, y `EnumSet` donde el formato lo eliges tú: es lo mismo con nombres.

---

## 6. 🧱 Los trucos que sí se preguntan

Tres, y los tres tienen uso real más allá del acertijo.

**XOR para encontrar el elemento sin pareja.** Como `x ^ x == 0` y el XOR es conmutativo, aplicarlo a
toda una secuencia deja solo el que no se repite:

```text
5 ^ 3 ^ 5 = 3
```

- O(n) en tiempo y **O(1) en espacio**, frente al `HashMap` de conteos que sería O(n) de memoria.
- Uso real: detección de corrupción y paridad. El RAID 5 reconstruye un disco perdido con
  exactamente esta propiedad.

**Comprobar si un número es potencia de dos.**

```text
n & (n - 1) == 0        16 & 15 = 0  → sí
                        12 & 11 = 8  → no
```

- Restar uno a una potencia de dos pone a 1 todos los bits por debajo del único bit activo, así que
  el AND se anula.
- Uso real: es la comprobación que hace un `HashMap` al dimensionar su capacidad, y la razón de que
  `hash & (n-1)` pueda sustituir al módulo.

**Contar bits activos.** `Integer.bitCount(255)` es `8`. Se compila a **una sola instrucción**
(`POPCNT`) en los procesadores modernos. Uso real: distancia de Hamming, similitud entre huellas
digitales, cardinalidad de una máscara.

---

## 7. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| `&`, `|`, `^`, `~`, `<<`, `>>` | 1 ciclo | Más barato que cualquier acceso a memoria |
| `bitCount` | 1 instrucción | Solo si el procesador tiene `POPCNT`, que hoy es siempre |
| Máscara como conjunto | O(1) unión, intersección, pertenencia | Limitada a 64 elementos en un `long` |
| `EnumSet` | Igual que la máscara | Misma velocidad, con nombres y tipos |
| `HashSet<Enum>` | O(1) con constante alta | Órdenes de magnitud más memoria para lo mismo |
| Enteros de Python | O(log n) en el tamaño del número | No desbordan, y por eso no son gratis |

---

## 8. ⚖️ Los cinco lenguajes

| Lenguaje | Enteros | ¿`>>>`? | Comprobación de desbordamiento |
|---|---|---|---|
| **Java** | 8/16/32/64 bits con signo; sin `unsigned` | ✅ | `Math.addExact`, `multiplyExact`, `toIntExact` |
| **Python** | **Precisión arbitraria** | ❌ | No hace falta |
| **JavaScript** | `double` de 64 bits; enteros exactos hasta 2⁵³ | ✅ | `Number.isSafeInteger`, o `BigInt` |
| **TypeScript** | Igual que JS | ✅ | El tipo `number` no distingue entero de decimal |
| **Go** | Con y **sin signo**, de 8 a 64 bits | ❌ (usa `uint`) | Nada en la stdlib; `math/big` si hace falta |

Las dos asimetrías que valen como respuesta:

- **Java no tiene enteros sin signo** —salvo `char`— y por eso necesitó inventar `>>>`. Go sí los
  tiene, y por eso no lo necesita: el desplazamiento lógico sale de usar `uint32`. Es la misma
  necesidad resuelta en la sintaxis o en el sistema de tipos.
- **TypeScript no puede ayudar aquí.** Su tipo `number` no distingue un entero de un decimal ni
  acota el rango, así que el desbordamiento silencioso de JavaScript le pasa por debajo sin que el
  compilador diga nada. Es uno de los pocos sitios del corpus donde TypeScript **no** aporta.

---

## 9. 🧭 Cómo se elige

```text
¿Sumas o restas enteros con datos externos?   → piensa en el desbordamiento; usa addExact o long
¿Normalizas un hash a un índice?              → hash & 0x7fffffff, NUNCA Math.abs
¿Conjunto de banderas cerrado y pequeño?      → EnumSet (es la máscara, con nombres)
¿Formato binario o protocolo que lo exige?    → máscara de bits explícita, y documenta cada bit
¿Necesitas desplazamiento lógico?             → >>> en Java/JS; tipo sin signo en Go
¿Identificadores de 64 bits hacia un front?   → transpórtalos como STRING, no como número
¿Estás escribiendo x << 1 para ir más rápido? → no: escribe x * 2, salvo que expreses una potencia
```

> **Regla de entrevista:** nombrar `Math.abs(Integer.MIN_VALUE)` o el `MAX_SAFE_INTEGER` de
> JavaScript en la conversación adecuada es de las cosas que mejor demuestran que has depurado un
> problema de verdad y no solo leído sobre tipos.

---

## 10. 🔭 Dónde aparece de verdad

En el `hash & (capacidad - 1)` de cualquier tabla hash, que exige capacidad potencia de dos; en los
permisos de un sistema de archivos POSIX, que son tres máscaras de tres bits; en las banderas de
apertura de un socket o de un archivo; en los identificadores tipo snowflake, que empaquetan
timestamp, nodo y secuencia en un `long` con desplazamientos; en los filtros de Bloom de
[`03-orden-busqueda/04`](../03-orden-busqueda/04-hashing-y-tablas-hash.md), que son un arreglo de
bits; y en la corrupción silenciosa de identificadores grandes al pasar por JavaScript, que es un
incidente clásico de integración.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`Math.abs` devuelve un positivo" | Con `Integer.MIN_VALUE` devuelve un negativo. Usa `hash & 0x7fffffff` |
| "Si desborda, saltará un error" | En Java y Go da la vuelta **en silencio**. Solo `addExact` avisa |
| "En JavaScript los enteros son enteros" | Son `double`: a partir de 2⁵³ dos números distintos son iguales |
| "`x << 1` es más rápido que `x * 2`" | El compilador ya lo hace. Escribe la intención |
| "`>>` y `>>>` son lo mismo con negativos" | `-8 >> 1` es `-4`; `-8 >>> 1` es 2147483644 |
| "Uso un `int` de banderas, es más eficiente" | Lo es, y es ilegible. `EnumSet` es la máscara con nombres |
| "Las potencias de dos se comprueban con logaritmos" | `n & (n - 1) == 0`, en una instrucción |

---

## 📚 Para profundizar

- **Libro** — Warren, *Hacker's Delight*, 2ª ed. (Addison-Wesley, 2012). **El libro de este tema**,
  y el único que hace falta: manipulación de bits, desbordamiento y trucos aritméticos con su
  demostración. Se consulta por capítulo.
- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítem 36, sobre usar `EnumSet`
  en lugar de campos de bits, con la comparación de rendimiento.
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Sección 1.1, con el
  modelo de tipos primitivos y el desbordamiento en Java.
- [Java 21 API — `Math`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Math.html):
  `addExact`, `multiplyExact`, `toIntExact` y la nota explícita sobre `abs(MIN_VALUE)`.
- [Java 21 API — `Integer`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Integer.html):
  `bitCount`, `highestOneBit`, `numberOfTrailingZeros` y los métodos de tratamiento sin signo.
- [MDN — `Number.MAX_SAFE_INTEGER`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER):
  por qué 2⁵³ es el límite y qué pasa después.
- [The Go Programming Language Specification — Arithmetic operators](https://go.dev/ref/spec):
  el comportamiento definido del desbordamiento en enteros con y sin signo.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Por qué el rango de un `int` es asimétrico? 🟢
2. ¿Qué devuelve `Math.abs(Integer.MIN_VALUE)`? 🟢
3. ¿Qué diferencia hay entre `>>` y `>>>`? 🟢
4. ¿Cómo se comprueba que un número es potencia de dos? 🟢
5. ¿Qué pasa en Java cuando una suma de enteros desborda? 🟢
6. ¿Qué es una máscara de bits y qué operaciones la definen? 🟢
7. ¿Por qué `EnumSet` es preferible a un `int` de banderas? 🟡
8. ¿Por qué en Python no hace falta preocuparse por el desbordamiento? 🟡
9. ¿Por qué Go no tiene `>>>`? 🟡
10. ¿Qué devuelve `5 ^ 3 ^ 5` y por qué? 🟡
11. ¿Por qué `hash & (n - 1)` puede sustituir al módulo, y con qué condición? 🟡
12. ¿Qué hace `Math.addExact` y por qué existe? 🟡
13. ¿Por qué `x >> 1` y `x / 2` no son equivalentes con números negativos? 🟠
14. ¿Por qué `Math.abs(hash) % n` es un bug latente y cómo se escribe bien? 🟠
15. ¿Por qué en JavaScript `MAX_SAFE_INTEGER + 1 === MAX_SAFE_INTEGER + 2` es `true`? 🟠
16. Un `id` de tipo `bigint` llega corrupto al front. Explica el mecanismo y la corrección. 🟠
17. ¿Por qué escribir `x << 1` en vez de `x * 2` no es una optimización? 🟠
18. ¿En qué caso `<<` sí expresa mejor la intención que una multiplicación? 🟠
19. ¿Por qué TypeScript no puede protegerte del desbordamiento de JavaScript? 🟠
20. ¿Cómo empaquetarías timestamp, nodo y secuencia en un `long` de 64 bits? 🔴
21. Te dan un arreglo donde todos los números aparecen dos veces salvo uno. Da dos soluciones y
    compara su espacio. 🔴
22. Un método de reparto en cubetas falla con `ArrayIndexOutOfBoundsException` una vez cada varios
    millones de peticiones. Da tu diagnóstico. 🔴

---

**Anterior:** [`04` — Recursión y backtracking](04-recursion-y-backtracking.md) ·
**Siguiente:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Relacionado:** [`03-orden-busqueda/04` — Hashing](../03-orden-busqueda/04-hashing-y-tablas-hash.md)
