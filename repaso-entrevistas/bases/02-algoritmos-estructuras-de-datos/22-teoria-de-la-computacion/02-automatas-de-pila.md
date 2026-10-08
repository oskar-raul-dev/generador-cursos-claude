# 02 — Autómatas de pila

> **Opcional.** Ningún capítulo del hilo principal depende de este. La máquina de los lenguajes libres de
> contexto: un autómata finito con una pila, por qué el no determinismo le da poder (a diferencia del
> autómata finito), el teorema que la iguala a las gramáticas, y el algoritmo que decide en tiempo
> polinomial si una cadena sale de una gramática cualquiera: CYK, sobre la forma normal de Chomsky.
>
> **Niveles:** autómatas de pila [B] · equivalencia con las gramáticas y forma normal de Chomsky [B] · CYK [B].
>
> **📚 Lectura troncal:** Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y
> computación*, 3.ª ed. (Pearson, 2007), caps. 6 y 7.
>
> **Asume leído:** [`22/01` — Lenguajes y gramáticas](01-lenguajes-y-gramaticas.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--autómatas-de-pila) · [4](#4--equivalencia-con-las-gramáticas-y-forma-normal-de-chomsky) · [5](#5--cyk) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Tienes la gramática de un pequeño lenguaje de configuración y un archivo de mil caracteres. ¿Lo genera la
gramática? Probar derivaciones a ciegas no termina: una gramática con `S → S S` tiene infinitas, y nada dice
cuándo rendirse. Lo que hace falta es un procedimiento que **siempre** responda, y en un tiempo que se pueda
acotar.

Hay dos caminos, y este capítulo recorre los dos. El primero es la **máquina**: el autómata de pila, que es
a las gramáticas libres de contexto lo que el DFA es a las expresiones regulares. El segundo es el
**algoritmo**: pasar la gramática a una forma normal donde cada producción parte la cadena en dos, y
rellenar con programación dinámica qué variable genera cada subcadena. Es CYK, `O(n³ · |G|)`, y responde
para **cualquier** gramática libre de contexto, ambigua o no.

> 🧠 **Modelo mental.** Un autómata finito recuerda en qué estado está; uno de pila, además, apila lo que
> todavía tiene pendiente. Cada `(` abierto es una promesa en la pila, y cada `)` cumple la de arriba.

Los ejemplos usan los paréntesis equilibrados de [`22/01`](01-lenguajes-y-gramaticas.md) y `aⁿbⁿ`.

---

## 2. 📐 La teoría

**Autómata de pila (PDA).** Un autómata finito con una pila sin límite. Una transición depende del estado,
del símbolo de entrada (o de ninguno: transición ε) y del símbolo de la cima, y hace tres cosas: cambia de
estado, consume el símbolo y **sustituye la cima por una cadena** (vacía para desapilar, la misma para no
tocarla, otra más larga para apilar). Una **configuración** es el triple `(estado, entrada que queda, pila)`.

**Dos formas de aceptar.** Por **estado final** (al acabar la entrada, en un estado final) o por **pila
vacía**. Para los PDA no deterministas son equivalentes: cada uno se convierte en el otro.

**Teorema (equivalencia).** Un lenguaje es libre de contexto si y solo si lo acepta algún autómata de pila
**no determinista**. De gramática a PDA: el autómata apila el cuerpo de una producción cuando ve una variable
en la cima, y compara cuando ve un terminal; adivinar qué producción usar es el no determinismo. De PDA a
gramática: una variable `[p X q]` por cada «paso de `p` a `q` desapilando `X`».

**El no determinismo sí da poder aquí.** A diferencia de los autómatas finitos ([`16/07`](../16-cadenas/07-automatas-y-expresiones-regulares.md)), los PDA
deterministas (DPDA) reconocen **estrictamente menos**. `{w c wᴿ}` (un palíndromo con marca central) es
determinista: se apila hasta la `c` y se compara después. `{w wᴿ}`, sin marca, no lo es: el autómata tiene
que adivinar dónde está la mitad. Los lenguajes de los DPDA, los **libres de contexto deterministas**, son
los que los analizadores LL y LR procesan en tiempo lineal, y todos tienen una gramática no ambigua.

**Forma normal de Chomsky (FNC).** Toda producción es `A → B C` (dos variables) o `A → a` (un terminal),
más, como mucho, `S → ε` si el lenguaje contiene la vacía. **Teorema:** todo lenguaje libre de contexto sin
`ε` tiene una gramática en FNC. En FNC, una cadena de longitud `n` se deriva en exactamente `2n − 1` pasos y
su árbol es binario: por eso cabe la programación dinámica sobre intervalos.

---

## 3. 🧱 Autómatas de pila

**Qué es.** Un PDA para `aⁿbⁿ` (`n ≥ 1`), aceptando por estado final:

```text
estado p (leyendo aes):    a, cima Z o A  → apila A, sigue en p
                           b, cima A      → desapila, pasa a q
estado q (leyendo bes):    b, cima A      → desapila, sigue en q
                           ε, cima Z      → pasa a f (final)
Z es el fondo de la pila; cualquier otra combinación no tiene transición: rechaza
```

**Por qué es correcto** (el enunciado y una frase): el invariante es «en `p`, la pila tiene una `A` por cada
`a` leída; en `q`, una por cada `a` aún sin emparejar», y solo se llega a `f` con la pila en el fondo.

**Cómo va**, sobre `aabb` y `aab`:

```text
(p, aabb, Z) → (p, abb, AZ) → (p, bb, AAZ) → (q, b, AZ) → (q, ε, Z) → (f, ε, Z)   acepta
(p, aab, Z)  → (p, ab, AZ)  → (p, b, AAZ)  → (q, ε, AZ)                         sin transición: rechaza
```

**Cuánto.** Un DPDA procesa la entrada en `Θ(n)`, con la pila de hasta `n` símbolos. Un PDA no determinista
no se simula probando caminos (pueden ser exponenciales, e incluso infinitos con transiciones ε): se usa CYK o
uno de los algoritmos generales (Earley, `O(n³)`).

**La plantilla.** No hay una general: un PDA determinista es un bucle con una pila explícita, y se escribe a
medida del lenguaje. El esqueleto, en Java, para `aⁿbⁿ`:

```java
import java.util.ArrayDeque;

// DPDA de aⁿbⁿ (n ≥ 1) con la pila explícita. Θ(n).
static boolean anbn(String w) {
    ArrayDeque<Character> stack = new ArrayDeque<>();
    int i = 0;
    while (i < w.length() && w.charAt(i) == 'a') { stack.push('A'); i++; }      // estado p
    if (stack.isEmpty()) return false;
    while (i < w.length() && w.charAt(i) == 'b' && !stack.isEmpty()) { stack.pop(); i++; }   // estado q
    return i == w.length() && stack.isEmpty();                                 // fondo de pila y sin entrada
}
```

- **Cada `while` es un estado** del autómata, y la condición de salida es su tabla de transiciones.
- **Con un solo tipo de símbolo apilado**, la pila es un contador: así lo hacen los ejercicios de paréntesis de
  [`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md). Con varios tipos (`()`, `[]`, `{}`) hace
  falta la pila de verdad.

**Cuándo sí:** como modelo para saber que un lenguaje es libre de contexto, y para escribir a mano el
reconocedor de un lenguaje determinista sencillo. **Cuándo no:** para lenguajes que exigen no determinismo, o
para una gramática que ya tienes: ahí, CYK o un analizador.

> **Veredicto:** un autómata de pila es un DFA con una pila, y la pila es lo que le permite contar sin límite.
> Su versión no determinista es exactamente tan potente como las gramáticas libres de contexto; la
> determinista, menos.

---

## 4. 🧱 Equivalencia con las gramáticas y forma normal de Chomsky

**Qué es.** La conversión de una gramática cualquiera a FNC, que es la entrada que exige CYK. Cinco pasos, en
este orden:

```text
1. INICIO   nueva variable inicial S₀ → S, para que S no aparezca en ningún cuerpo
2. BIN      cuerpos de más de dos símbolos se parten: A → X Y Z  ⇒  A → X A₁,  A₁ → Y Z
3. DEL      se quitan las producciones ε: por cada cuerpo con anulables, se añaden las versiones sin ellos
4. UNIT     se quitan las unitarias A → B: A hereda los cuerpos de todo lo que alcanza por unitarias
5. TERM     los terminales dentro de cuerpos de dos símbolos pasan a variables: A → a B ⇒ A → T_a B, T_a → a
y antes de todo, o al final: quitar las variables no generadoras y las no alcanzables
```

**Por qué es correcto** (el enunciado y una frase): cada paso conserva el lenguaje (salvo `ε`, que se trata
aparte con `S₀ → ε`), y cada uno se demuestra mostrando que toda derivación de la gramática vieja tiene una
equivalente en la nueva y viceversa. Las anulables, generadoras y alcanzables se calculan con el punto fijo
de [`22/01`](01-lenguajes-y-gramaticas.md).

**Cómo va**, con los paréntesis equilibrados no vacíos, `S → S S | ( S ) | ( )`:

```text
TERM:  L → (    R → )
BIN:   ( S ) ⇒ L X,  X → S R
FNC:   S → S S | L X | L R      X → S R      L → (      R → )
```

**Cuánto.** El tamaño de la gramática crece: BIN es lineal, UNIT puede ser cuadrático. **El orden importa**:
si DEL va antes que BIN, un cuerpo de `k` anulables genera `2ᵏ` versiones; con BIN antes, cada cuerpo tiene
dos símbolos y como mucho tres versiones.

**La plantilla.** No hay: la conversión se hace a mano una vez por gramática, y en un problema la gramática
casi siempre viene ya en FNC o es pequeña.

**Cuándo sí:** antes de CYK, y en las pruebas (la FNC es la que hace funcionar el lema de bombeo de los
libres de contexto). **Cuándo no:** para escribir un analizador de un lenguaje de programación: la FNC destruye
la estructura que el programador escribió, y se usa descenso recursivo sobre la gramática original (`22/06`).

> **Veredicto:** la FNC es una normalización para algoritmos y pruebas, no para leer: árboles binarios, `2n − 1`
> pasos por derivación, y eso es lo que hace posible CYK.

---

## 5. 🧱 CYK

**Qué es.** El algoritmo de Cocke, Younger y Kasami: decide si una gramática en FNC genera `w`, para cualquier
gramática libre de contexto. `T[i][j]` es el conjunto de variables que generan la subcadena `w[i..j]`.

**Por qué es correcto** (el enunciado y una frase): en FNC, `A ⇒* w[i..j]` con `i < j` si y solo si hay una
producción `A → B C` y un corte `k` con `B ⇒* w[i..k]` y `C ⇒* w[k+1..j]`; es una DP de intervalos
([`12/05`](../12-dp-clasica/05-rejillas-e-intervalos.md)) que se rellena por longitudes crecientes.

**Cómo va**, con la gramática de §4 y `w = (()())`, posiciones 0 a 5. Cada fila es una longitud; cada
columna, el inicio `i`:

```text
longitud 1:   L    L    R    L    R    R        w[i] = ( → L,  ) → R
longitud 2:   -    S    -    S    -              «()» en 1 y en 3: S → L R
longitud 3:   -    -    -    X                   «())» desde 3: X → S R
longitud 4:   -    S    -                        «()()» desde 1: S → S S
longitud 5:   -    X                             «()())» desde 1: X → S R
longitud 6:   S                                  «(()())»: S → L X   → la genera
```

**Cuánto.** `O(n³ · |R|)` tiempo, con `|R|` las producciones binarias: `n²/2` celdas, `n` cortes por celda y
`|R|` producciones por corte. `O(n² · |V|)` memoria; con las variables como bits de un entero, cada celda es
un `uint64` y la prueba «`B` en la izquierda y `C` en la derecha» es un `&`.

**La plantilla**, con hasta 64 variables numeradas desde 0 y la inicial en el 0:

```cpp
#include <array>
#include <cstdint>
#include <string>
#include <vector>

// CYK. unit = {A, a} por cada A → a; bin = {A, B, C} por cada A → B C. O(n³ · |bin|).
bool cyk(const std::vector<std::pair<int, char>>& unit, const std::vector<std::array<int, 3>>& bin,
         const std::string& w) {
    int n = w.size();
    if (n == 0) return false;                       // la vacía se trata aparte (S₀ → ε)
    std::vector<std::vector<uint64_t>> t(n, std::vector<uint64_t>(n, 0));
    for (int i = 0; i < n; i++)
        for (auto [a, c] : unit) if (c == w[i]) t[i][i] |= 1ULL << a;
    for (int len = 2; len <= n; len++)
        for (int i = 0; i + len - 1 < n; i++) {
            int j = i + len - 1;
            for (int k = i; k < j; k++)
                for (const auto& r : bin)
                    if ((t[i][k] >> r[1] & 1) && (t[k + 1][j] >> r[2] & 1)) t[i][j] |= 1ULL << r[0];
        }
    return t[0][n - 1] & 1;                         // ¿la variable inicial genera w entera?
}
```

```java
// CYK. unit[r] = {A, símbolo}; bin[r] = {A, B, C}. Variables 0..63, la inicial es la 0.
static boolean cyk(int[][] unit, int[][] bin, String w) {
    int n = w.length();
    if (n == 0) return false;
    long[][] t = new long[n][n];
    for (int i = 0; i < n; i++)
        for (int[] u : unit) if (u[1] == w.charAt(i)) t[i][i] |= 1L << u[0];
    for (int len = 2; len <= n; len++)
        for (int i = 0; i + len - 1 < n; i++) {
            int j = i + len - 1;
            for (int k = i; k < j; k++)
                for (int[] r : bin)
                    if ((t[i][k] >> r[1] & 1) != 0 && (t[k + 1][j] >> r[2] & 1) != 0) t[i][j] |= 1L << r[0];
        }
    return (t[0][n - 1] & 1) != 0;
}
```

```python
def cyk(unit, binr, w):
    """CYK. unit = [(A, a)]; binr = [(A, B, C)]; variables numeradas desde 0, la inicial es la 0."""
    n = len(w)
    if n == 0:
        return False
    t = [[0] * n for _ in range(n)]
    for i, c in enumerate(w):
        for a, s in unit:
            if s == c:
                t[i][i] |= 1 << a
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            for k in range(i, j):
                left, right = t[i][k], t[k + 1][j]
                for a, b, c in binr:
                    if left >> b & 1 and right >> c & 1:
                        t[i][j] |= 1 << a
    return bool(t[0][n - 1] & 1)
```

- **La máscara por celda** hace que la prueba de cada producción sea una operación de bits; en C++ y Java,
  `uint64_t` y `long` dan 64 variables. Con más, un `bitset` o un `boolean[]` por celda.
- **El orden de los bucles** (longitud por fuera) es lo que garantiza que `t[i][k]` y `t[k+1][j]` ya están
  completos: los dos son más cortos que `[i, j]`.
- **Python** hace unas `n³/6 · |R|` operaciones interpretadas: con `n = 100` y 100 producciones, `1,7·10⁷` por
  cadena, segundos en CPython. Se agrupan las producciones por `(B, C)` y se recorren solo los bits encendidos,
  o se cambia de lenguaje.
- **Para contar árboles** (cuántas lecturas tiene una cadena en una gramática ambigua), la celda guarda un
  contador por variable y el `|=` se cambia por `+= cuenta(B) · cuenta(C)`; para reconstruir un árbol, se
  guarda qué producción y qué corte dieron cada variable.

**Cuándo sí:** cualquier gramática libre de contexto, incluso ambigua, con cadenas de cientos de símbolos;
contar o enumerar lecturas. **Cuándo no:** para un lenguaje de programación, donde las entradas tienen
millones de símbolos: ahí, analizadores lineales sobre gramáticas deterministas (LL, LR) o el descenso
recursivo de `22/06`.

> **Veredicto:** CYK decide la pertenencia para cualquier gramática libre de contexto en `O(n³ · |G|)`, y es
> una DP de intervalos con la gramática en FNC como recurrencia. Es el algoritmo general; los rápidos piden
> gramáticas especiales.

---

## 6. ⏱️ La tabla de costes

| Método | Tiempo | Para qué gramáticas | Lo que la tabla no dice |
|---|---|---|---|
| DPDA a mano | `Θ(n)` | Lenguajes deterministas | Hay que diseñarlo para cada lenguaje |
| CYK | `O(n³ · \|G\|)` | Cualquiera, en FNC | La conversión a FNC puede agrandar la gramática; Valiant baja a la multiplicación de matrices |
| Earley | `O(n³)`; `O(n²)` si no es ambigua; lineal en muchas deterministas | Cualquiera, sin convertir | Más difícil de escribir; es el que usan los analizadores generales |
| LL / LR | `Θ(n)` | Subclases deterministas | Fuera de este bloque, por decisión del corpus |
| Descenso recursivo | `Θ(n)` con gramáticas sin ambigüedad ni recursión por la izquierda | Gramáticas «simples» | `22/06` |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Dada una gramática (en FNC), ¿genera la cadena?» | CYK | `O(n³ · \|G\|)` para cualquier gramática |
| «¿De cuántas formas se puede leer/parentizar…?» con reglas binarias | CYK contando | Suma de productos en lugar de `\|=` |
| «Reglas de combinación de símbolos de dos en dos» (`x` y `y` se fusionan en `z`) | CYK disfrazado | Las reglas son una gramática en FNC |
| «Apilar y emparejar», varios tipos de cierre | Autómata de pila determinista | La pila es la memoria sin límite |
| «Palíndromo sin marca central» con una pasada y pila | No se puede de forma determinista | `wwᴿ` exige adivinar la mitad |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Como con los autómatas finitos, el no determinismo no añade nada» | En los de pila sí: los deterministas reconocen estrictamente menos (`wwᴿ`) |
| «Un PDA no determinista se simula probando caminos» | Puede haber infinitos con transiciones ε; se usa CYK o Earley |
| «CYK funciona con cualquier gramática tal cual» | Exige FNC; la gramática se convierte antes |
| «La conversión a FNC es lineal» | Depende del orden: DEL antes que BIN puede ser exponencial |
| «CYK es lineal si la gramática es pequeña» | Es cúbico en la longitud de la cadena, sea cual sea la gramática |
| «Si CYK dice que sí, la cadena tiene un solo árbol» | Dice que hay al menos uno; contar exige la versión con contadores |

---

## 📚 Para profundizar

- **Libro** — Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y computación*,
  3.ª ed. (Pearson, 2007), cap. 6: autómatas de pila, sus dos aceptaciones, la equivalencia con las
  gramáticas y los deterministas; cap. 7: formas normales, el lema de bombeo de los libres de contexto y CYK.
  *Lectura troncal.*
- **Libro** — Aho, Lam, Sethi y Ullman, *Compiladores: principios, técnicas y herramientas*, 2.ª ed.
  (Pearson, 2008), cap. 2: por qué los compiladores no usan CYK, y qué usan.
- **Video** — Ullman, *Automata Theory* (Stanford Online): autómatas de pila y CYK.

---

## 🧠 Preguntas

1. ¿Qué tres cosas hace una transición de un autómata de pila? 🟢
2. ¿Qué forma tienen las producciones en la forma normal de Chomsky? 🟢
3. ¿Cuánto cuesta CYK en tiempo y en memoria, y de dónde sale cada factor? 🟢
4. ¿Qué diferencia hay entre aceptar por estado final y por pila vacía, y cuándo son equivalentes? 🟡
5. ¿Por qué `{w c wᴿ}` se reconoce con un autómata de pila determinista y `{w wᴿ}` no? 🟡
6. ¿Qué diferencia hay entre CYK y un analizador de descenso recursivo en lo que aceptan y en lo que cuestan? 🟡
7. Compara la plantilla de CYK en C++, Java y Python: ¿qué representa cada celda, y qué cambia en Python cuando la cadena mide 100 símbolos? 🟡
8. ¿Por qué el orden de los bucles de CYK, con la longitud por fuera, es el que garantiza la corrección? 🟠
9. ¿Por qué conviene partir los cuerpos largos (BIN) antes de quitar las producciones ε (DEL)? 🟠
10. Enuncia el teorema que relaciona las gramáticas libres de contexto con los autómatas de pila y esboza la dirección de gramática a autómata. 🟠
11. Rellena la tabla de CYK de `aabb` con `S → A X | A B`, `X → S B`, `A → a`, `B → b`. 🔴
12. Modifica CYK para que cuente cuántos árboles tiene una cadena, y di cuántos tiene `a+a*a` con `E → E + E | E * E | a`. 🔴

---

## 🧩 Problemas propios

### ¿Lo genera?

**Nivel:** 🟡 · **Formato:** programa completo.

Una gramática en forma normal de Chomsky tiene variables que son letras mayúsculas (la inicial es `S`) y
terminales que son letras minúsculas. Para cada cadena, imprime `YES` si la gramática la genera y `NO` si no.

- **Entrada.** Una línea con `r`. Después, `r` líneas con una producción `A BC` (dos variables) o `A b` (un
  terminal). Una línea con `q`, y `q` líneas con una cadena de minúsculas, no vacía.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ r ≤ 100`; `1 ≤ q ≤ 20`; cada cadena de hasta 100 caracteres.

```text
Entrada     Salida
5           YES
S AX        NO
S AB        YES
X SB
A a
B b
3
aabb
abab
ab

Entrada     Salida
2           NO
S AA
A a
1
a
```

**Pista 1:** ¿qué tendría que pasar con las dos mitades de la cadena para que `S → A X` la genere, y en
cuántos sitios puede estar el corte?

### Cuántas lecturas

**Nivel:** 🟠 · **Formato:** programa completo.

Con el mismo formato de gramática, para cada cadena imprime **cuántos árboles de derivación distintos** tiene
desde `S`, módulo `10⁹ + 7`. En el ejemplo, `p` y `t` hacen de `+` y `*` en una gramática de expresiones sin
precedencia.

- **Entrada.** Como en «¿Lo genera?».
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ r ≤ 100`; `1 ≤ q ≤ 20`; cada cadena de hasta 100 caracteres.

```text
Entrada     Salida
7           2
S SP        5
S SM        1
S a         0
P OS
O p
M TS
T t
4
apata
apatapa
a
ap

Entrada     Salida
1           1
S a         0
2
a
aa
```

**Pista 1:** si sabes de cuántas formas genera cada variable cada subcadena más corta, ¿cómo combinas dos
mitades y un corte?

---

## ✅ Criterio de dominio

- Escribir el PDA de `aⁿbⁿ` y trazarlo, y explicar por qué `wwᴿ` necesita no determinismo.
- Convertir una gramática pequeña a FNC en el orden correcto.
- Escribir CYK con la plantilla delante y rellenar su tabla a mano para una cadena de seis símbolos.
- Resolver «¿Lo genera?» y «Cuántas lecturas» sin pista 2.

---

**Anterior:** [`22/01` — Lenguajes y gramáticas](01-lenguajes-y-gramaticas.md) ·
**Siguiente:** [`22/03` — Máquinas de Turing y decidibilidad](03-maquinas-de-turing-y-decidibilidad.md) ·
**Relacionado:** [`12/05` — DP en rejillas y de intervalos](../12-dp-clasica/05-rejillas-e-intervalos.md);
[`22/06` — Análisis léxico y gramáticas simples](06-analisis-lexico-y-gramaticas-simples.md).
