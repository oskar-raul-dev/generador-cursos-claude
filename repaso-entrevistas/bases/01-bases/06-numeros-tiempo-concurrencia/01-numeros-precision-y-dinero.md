# 01 — Números, precisión y dinero

> Por qué `0.1 + 0.2` no es `0.3`, cuándo `double` es correcto y cuándo es un problema de auditoría,
> `BigDecimal` con su escala y su constructor traicionero, el redondeo bancario, y por qué el `Money`
> que este corpus usa en cincuenta ejemplos nunca es un decimal.
> Asume leído [`01-fundamentos/05` — Bits y aritmética binaria](../01-fundamentos/05-bits-y-aritmetica-binaria.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un sistema de facturación suma 1 000 líneas de 0.1 € cada una y factura **99.99999999999986 €**. El
cliente paga 100. La diferencia es de céntimos y nadie la ve, hasta que el auditor cuadra el libro
mayor y aparecen miles de descuadres de un céntimo repartidos por tres años.

```text
0.1 + 0.2 == 0.3   →   Java: false   Python: false   JavaScript: false
                       0.30000000000000004
```

No es un bug de ningún lenguaje: es que **0.1 no existe en binario**, igual que 1/3 no existe en
decimal. El `double` guarda la fracción binaria más cercana, y la diferencia se acumula.

Este capítulo importa más que la media del corpus por una razón concreta: en banca, seguros o
cualquier dominio con dinero, **elegir mal el tipo numérico no produce un bug, produce un
incidente contable**. Y es una de las primeras cosas que se pregunta a un Tech Lead con perfil
financiero.

> **Regla de entrevista:** la respuesta a "¿cómo representas dinero?" nunca es `double`. Es
> `BigDecimal` con escala y modo de redondeo explícitos, o un entero de la unidad mínima. Y hay que
> saber decir por qué las dos son válidas y cuándo elegir cada una.

---

## 2. 🧱 IEEE 754: por qué `0.1` no existe

**Qué es.** El estándar con el que prácticamente todo el mundo representa números reales: un signo,
un exponente y una mantisa, en base **dos**.

**Cómo va.** Un `double` de 64 bits reparte 1 bit de signo, 11 de exponente y 52 de mantisa. Solo
puede representar exactamente las fracciones cuyo denominador es una potencia de dos:

```text
0.5   = 1/2      → exacto
0.25  = 1/4      → exacto
0.1   = 1/10     → PERIÓDICO en binario, como 1/3 en decimal
```

Verificado, imprimiendo más decimales de los que se suelen ver:

```text
0.1 + 0.2 con 20 decimales  →  0.30000000000000004441
```

**Cuánto cuesta.** Un error relativo de unos 10⁻¹⁶ por operación. Insignificante una vez, y
**acumulativo**: sumar un millón de valores puede desplazar el resultado de forma visible, y el
orden de la suma cambia el resultado —la suma en coma flotante **no es asociativa**—.

**Cuándo sí** usar `double`: magnitudes físicas, medias, porcentajes, coordenadas, métricas,
promedios de latencia. Todo lo que ya viene de una medición con error mayor que 10⁻¹⁶.

**Cuándo no:** dinero, contadores exactos, comparaciones por igualdad, y cualquier valor que deba
cuadrar con otro sistema.

> ⚠️ **Advertencia.** Nunca compares `double` con `==`. Se compara con una tolerancia —
> `Math.abs(a - b) < epsilon`— y aun así hay que recordar que **esa comparación no es transitiva**,
> que es exactamente el comparador roto de
> [`03-orden-busqueda/02`](../03-orden-busqueda/02-comparadores-y-orden-total.md). Los dos problemas
> son el mismo.

---

## 3. 🧱 La sorpresa de Go

De los cinco lenguajes, **Go responde distinto**, y es el hallazgo más instructivo del capítulo:

```go
fmt.Println(0.1 + 0.2 == 0.3)        // true   ← ¿?

a, b, c := 0.1, 0.2, 0.3
fmt.Println(a + b == c)              // false  ← ahora sí, como todo el mundo
```

**Por qué.** Las **constantes sin tipo** de Go se evalúan en tiempo de compilación con precisión
arbitraria —al menos 256 bits—, no como `float64`. La primera comparación la resuelve el compilador
con matemática exacta; la segunda usa aritmética IEEE 754 normal sobre variables.

- Es una decisión de diseño deliberada: las constantes son matemáticas hasta que se asignan a un
  tipo. Evita una clase entera de sorpresas en expresiones constantes.
- **Y es una trampa perfecta**: el mismo código "funciona" con literales y falla con variables, que
  es como llegan los datos reales. Un test escrito con constantes pasa y producción falla.

> 💡 **Truco.** Si te preguntan por `0.1 + 0.2` en una entrevista políglota, la respuesta completa es
> *"falso en los cuatro, y en Go depende de si son constantes o variables, porque las constantes sin
> tipo se evalúan con precisión arbitraria en compilación"*. Es un detalle verificable y muy poca
> gente lo conoce.

---

## 4. 🧱 `BigDecimal`: escala, y el constructor que miente

**Qué es.** Un decimal exacto representado como un entero sin límite —*unscaled value*— más una
**escala**, que dice cuántos dígitos van tras la coma. No usa base dos, así que `0.1` es exacto.

**El constructor traicionero**, verificado:

```java
new BigDecimal(0.1)        // 0.1000000000000000055511151231257827021181583404541015625
BigDecimal.valueOf(0.1)    // 0.1
new BigDecimal("0.1")      // 0.1
```

- `new BigDecimal(double)` recibe un `double` **que ya perdió precisión** y lo representa fielmente,
  basura incluida. Es técnicamente correcto y prácticamente siempre un error.
- **Se construye siempre desde `String` o con `valueOf`.** Es la regla número uno del tipo, y la que
  más se incumple.

**La escala es información**, y de ahí la incoherencia documentada que el corpus ya usó en
[`03-orden-busqueda/02`](../03-orden-busqueda/02-comparadores-y-orden-total.md):

```java
new BigDecimal("1.0").equals(new BigDecimal("1.00"));     // false  ← distinta escala
new BigDecimal("1.0").compareTo(new BigDecimal("1.00"));  // 0      ← mismo valor
```

- `equals` compara valor **y** escala; `compareTo` solo el valor. Por eso un `HashSet` ve dos
  elementos y un `TreeSet` ve uno.
- Para comparar importes **siempre `compareTo`**, nunca `equals`. Y para deduplicar, normalizar la
  escala antes con `setScale`.

**Cuánto cuesta.** Entre 10 y 100 veces más lento que `double`, y mucha más memoria: es un objeto con
un `BigInteger` dentro. **Irrelevante** en lógica de negocio —unas miles de operaciones por
petición— y **prohibitivo** en un bucle numérico de millones de iteraciones.

> **Veredicto:** `BigDecimal` es el tipo correcto para dinero en Java, y su precio es rendimiento que
> en un backend de negocio no vas a notar. Lo que sí hay que hacer siempre es **fijar la escala y el
> modo de redondeo explícitamente**, porque los valores por defecto no existen: una división sin
> ellos lanza `ArithmeticException` si el resultado es periódico.

---

## 5. 🧱 El redondeo bancario

**El problema.** `2.5` redondeado a entero, ¿es 2 o 3? La respuesta "de colegio" —siempre hacia
arriba— **sesga el total al alza** cuando redondeas millones de importes, porque los empates siempre
suben.

**Cómo va.** `HALF_EVEN` —redondeo bancario o *banker's rounding*— desempata hacia el **par más
cercano**, lo que reparte los empates arriba y abajo y hace que el sesgo tienda a cero. Verificado:

```text
valor    HALF_UP    HALF_EVEN
 2.5        3           2        ← baja al par
 3.5        4           4        ← sube al par
-2.5       -3          -2
```

- **`HALF_EVEN` es el modo por defecto de IEEE 754** y el que exigen muchas normativas contables.
  `HALF_UP` es el que la gente espera intuitivamente.
- Cuál usar **no lo decide el programador**: lo decide la norma o el contrato. Preguntarlo es parte
  de la respuesta correcta.

**Dónde redondear** importa tanto como cómo: redondear en cada operación intermedia acumula error de
forma distinta que redondear solo al final. La regla habitual en facturación es **calcular con más
decimales de los que se muestran y redondear una sola vez**, en el momento de emitir el importe. Y
debe quedar documentado, porque otro sistema que redondee en otro punto producirá céntimos de
diferencia.

---

## 6. 🧱 Dinero como entero

**La alternativa a `BigDecimal`:** guardar **céntimos** —o la unidad mínima de la divisa— en un
`long`.

```java
record Money(long centimos, Currency divisa) { }     // 99.50 € → 9950
```

- Exacto, rápido y compacto: un `long` frente a un objeto con `BigInteger` dentro.
- Es lo que hacen Stripe y la mayoría de las pasarelas de pago en sus APIs, precisamente para que no
  haya ambigüedad de coma flotante en la frontera entre sistemas.
- **Es el `Money` que este corpus usa en todos sus ejemplos**, y la razón por la que la respuesta de
  `01-fundamentos/06` dice "un `Money` con enteros y no `double`".

**Cuándo no basta.** Cuando hay divisiones con decimales intermedios —prorrateos, intereses, tipos de
cambio— donde la unidad mínima no da resolución suficiente. Ahí se usa `BigDecimal` con escala alta
y se redondea a la unidad mínima solo al final.

**Las dos trampas** que hay que nombrar:

- **No todas las divisas tienen dos decimales.** El yen japonés tiene cero y el dinar kuwaití tres.
  Un `long` de "céntimos" con un factor fijo de 100 está mal para un sistema multidivisa; el factor
  sale de la divisa (`Currency.getDefaultFractionDigits()`).
- **Nunca sumes importes de divisas distintas.** El tipo tiene que llevar la divisa dentro y la suma
  tiene que fallar si no coinciden. Es la razón de que `Money` sea un tipo y no un número.

---

## 7. ⏱️ La tabla de costes

| Tipo | Exactitud decimal | Velocidad | Rango | Lo que la tabla no dice |
|---|---|---|---|---|
| `double` | ❌ | Máxima | ±1.8·10³⁰⁸ | Enteros exactos solo hasta 2⁵³ |
| `float` | ❌ | Máxima | Menor | 7 dígitos significativos: casi nunca vale la pena |
| `long` (céntimos) | ✅ | Máxima | ±9.2·10¹⁸ | El factor depende de la divisa; desborda en silencio |
| `BigDecimal` | ✅ | 10–100× más lento | Ilimitado | Irrelevante en negocio, prohibitivo en bucles numéricos |
| `BigInteger` | ✅ (enteros) | Lento | Ilimitado | Para criptografía y factores, no para dinero |
| `int`/`long` | ✅ (enteros) | Máxima | Acotado | Desbordamiento silencioso: ver `01-fundamentos/05` |

---

## 8. ⚖️ Los cinco lenguajes

| Lenguaje | Tipo decimal exacto | Enteros | El detalle que muerde |
|---|---|---|---|
| **Java** | `BigDecimal` en la stdlib | 32/64 bits, desbordan | El constructor con `double` guarda la basura: usa `String` o `valueOf` |
| **Python** | **`decimal.Decimal`** en la stdlib | Precisión arbitraria | Contexto global con precisión y redondeo configurables |
| **JavaScript** | **No hay** | `number` es `double`; `BigInt` aparte | Hay que usar una biblioteca (`decimal.js`) o enteros. Propuesta `Decimal` en curso |
| **TypeScript** | No hay | Igual que JS | `number` no distingue entero de decimal: no puede ayudar |
| **Go** | **No hay** en la stdlib | Con y sin signo, desbordan | `shopspring/decimal` es el estándar de facto. Las constantes sin tipo son exactas |

Las tres conclusiones que valen como respuesta:

- **Solo Java y Python traen decimal exacto en la biblioteca estándar.** En JavaScript y Go es una
  dependencia externa, y eso es un dato de arquitectura: si el equipo de front calcula importes, va a
  hacerlo con `double` salvo que alguien lo impida.
- **JavaScript es el más peligroso para dinero** de los cinco: sin decimal, sin enteros de 64 bits y
  con `JSON.parse` convirtiendo todo a `double`. Es la razón de que los importes viajen como enteros
  de la unidad mínima o como string en las APIs serias.
- **Python tiene un contexto global** (`decimal.getcontext()`) con precisión y redondeo, lo que es
  cómodo y es una variable global: en una aplicación grande conviene fijarlo explícitamente por
  operación.

---

## 9. 🧭 Cómo se elige

```text
¿Es dinero?                                  → BigDecimal desde String, o long de unidad mínima
   ¿multidivisa?                             → el factor sale de la divisa, no es 100 fijo
   ¿hay divisiones o prorrateos?             → BigDecimal con escala alta, redondear solo al final
¿Es una magnitud medida (peso, tiempo, %)?   → double está bien
¿Es un contador o un identificador?          → entero, y cuidado con el desbordamiento
¿Vas a compararlo por igualdad?              → nunca double
¿Cruza la frontera hacia JavaScript?         → entero de unidad mínima, o string. Nunca decimal JSON
¿Estás en un bucle numérico de millones?     → double, y asume el error; BigDecimal no cabe ahí
```

> **Regla de entrevista:** "usaría `BigDecimal`" es media respuesta. La completa añade **desde
> `String`**, **con escala y `RoundingMode` explícitos**, **comparando con `compareTo`** y
> **redondeando una sola vez, al final**. Cada una de esas cuatro cierra un bug distinto.

---

## 10. 🔭 Dónde aparece de verdad

En el descuadre de céntimos entre el sistema de facturación y el libro contable, que es el incidente
clásico y casi siempre es redondeo en puntos distintos; en el `DECIMAL(19,4)` de la columna de
importes, que es la misma decisión tomada en el esquema; en los tipos de cambio, donde la resolución
intermedia importa y el redondeo final también; en el identificador `bigint` que se corrompe al pasar
por JavaScript —el caso de
[`01-fundamentos/05`](../01-fundamentos/05-bits-y-aritmetica-binaria.md)—; y en los informes que no
cuadran entre dos sistemas porque uno redondea al sumar y el otro al mostrar.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Uso `double` y redondeo al final" | El error se acumula antes de llegar al final. Para dinero, nunca |
| "`new BigDecimal(0.1)`" | Guarda la basura del `double`. Se construye desde `String` o con `valueOf` |
| "Comparo importes con `equals`" | Compara también la escala: `1.0` y `1.00` no son iguales. Usa `compareTo` |
| "Redondeo siempre hacia arriba" | `HALF_UP` sesga el total al alza. El contable suele ser `HALF_EVEN` |
| "Céntimos son el importe por 100" | No en todas las divisas: el yen tiene 0 decimales y el dinar kuwaití 3 |
| "En Go `0.1+0.2 == 0.3` es true, así que no hay problema" | Solo con **constantes**; con variables `float64` es false como en todos |
| "Mando el importe como número en el JSON" | JavaScript lo lee como `double`. Entero de unidad mínima o string |

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). **Ítem 60: "Avoid float and
  double if exact answers are required"**. Es literalmente este capítulo, con el ejemplo del dinero.
- **Libro** — Fowler, *Patterns of Enterprise Application Architecture* (Addison-Wesley, 2002). El
  patrón **Money**: por qué el importe y la divisa son un solo tipo y qué operaciones admite.
- **Libro** — Goldberg, *What Every Computer Scientist Should Know About Floating-Point Arithmetic*
  (ACM Computing Surveys, 1991). El artículo de referencia sobre IEEE 754; se consulta por secciones.
- [Java 21 API — `BigDecimal`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/math/BigDecimal.html):
  la escala, los modos de redondeo y la advertencia explícita sobre el constructor con `double`.
- [Java 21 API — `RoundingMode`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/math/RoundingMode.html):
  los ocho modos con su tabla comparativa, incluido `HALF_EVEN`.
- [Python — `decimal`](https://docs.python.org/3/library/decimal.html): el contexto, la precisión y
  la comparación con `float`, con ejemplos del mismo problema.
- [The Go Programming Language Specification — Constants](https://go.dev/ref/spec): las constantes
  sin tipo y su precisión arbitraria, que explican la sorpresa de §3.
- [MDN — `Number.prototype.toFixed()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/toFixed):
  y por qué no resuelve el problema de fondo en JavaScript.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Por qué `0.1 + 0.2` no es `0.3`? 🟢
2. ¿Qué tipo usarías para representar dinero en Java? 🟢
3. ¿Qué diferencia hay entre `new BigDecimal(0.1)` y `BigDecimal.valueOf(0.1)`? 🟢
4. ¿Qué es el redondeo `HALF_EVEN` y por qué se llama bancario? 🟢
5. ¿Qué lenguajes de los cinco traen un decimal exacto en la stdlib? 🟢
6. ¿Por qué no se comparan dos `double` con `==`? 🟡
7. ¿Por qué `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` es `false`? 🟡
8. ¿Cuándo es correcto usar `double`? 🟡
9. ¿Qué representa la escala de un `BigDecimal`? 🟡
10. ¿Por qué la suma en coma flotante no es asociativa, y qué consecuencia tiene? 🟡
11. ¿Por qué `HALF_UP` sesga un total al alza? 🟡
12. ¿Qué cuesta `BigDecimal` frente a `double` y cuándo importa ese coste? 🟡
13. ¿Por qué en Go `0.1 + 0.2 == 0.3` puede ser `true`? 🟠
14. ¿Por qué el constructor `BigDecimal(double)` es un error casi siempre? 🟠
15. ¿Por qué "céntimos = importe × 100" está mal en un sistema multidivisa? 🟠
16. ¿Dónde se redondea en una factura: en cada línea o al final? Justifica. 🟠
17. ¿Por qué un importe no debería viajar como número en un JSON hacia JavaScript? 🟠
18. ¿Qué relación hay entre comparar `double` con tolerancia y el comparador roto de
    `03-orden-busqueda/02`? 🟠
19. ¿Por qué el tipo `Money` lleva la divisa dentro en vez de ser un número? 🟠
20. Dos sistemas facturan el mismo pedido y difieren en un céntimo. Da tres hipótesis en orden de
    probabilidad. 🔴
21. Diseña el tipo `Money` para un sistema multidivisa con prorrateos, y di qué operaciones permites
    y cuáles prohíbes. 🔴
22. Un proceso suma un millón de importes y el total difiere del esperado en varios euros. Explica
    el mecanismo y da la corrección. 🔴

---

**Siguiente:** [`02` — Tiempo, fechas y relojes](02-tiempo-fechas-y-relojes.md) ·
**Relacionado:** [`01-fundamentos/05` — Bits y aritmética binaria](../01-fundamentos/05-bits-y-aritmetica-binaria.md)
