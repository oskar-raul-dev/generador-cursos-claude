# 01 — Cadenas en los tres lenguajes y patrones básicos

> Lo que cuesta de verdad manipular cadenas en C++, Java y Python —inmutabilidad, concatenación en bucle,
> bytes frente a caracteres— y los tres patrones que resuelven la mayoría de los problemas de cadenas de
> entrevista: contar frecuencias con un arreglo de 26, comparar multiconjuntos de letras (anagramas) y
> recorrer con dos punteros desde los extremos (palíndromos).
>
> **Niveles:** inmutabilidad y concatenación [A] · frecuencias y anagramas [A] · palíndromos con dos
> punteros [A].
>
> **📚 Lectura troncal:** Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), introducción al
> cap. 5; la documentación de [`std::basic_string`](https://en.cppreference.com/cpp/string/basic_string),
> [`StringBuilder`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/StringBuilder.html)
> y [`str`](https://docs.python.org/3/builtins/stdtypes.html#text-sequence-type-str).
>
> **Asume leído:** [`06/04` — *Hashing* de secuencias](../06-lineales-y-hashing/04-hashing-de-secuencias.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--inmutabilidad-y-concatenación) · [4](#4--frecuencias-y-anagramas) · [5](#5--palíndromos-con-dos-punteros) · [6](#6-️-la-tabla-de-costes) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un programa en Java construye un informe de `10⁵` caracteres añadiendo uno a uno con `s += c`. En local, con
mil caracteres, tarda nada; en el juez, con `10⁵`, da TLE. No hay ningún bucle anidado a la vista: el bucle
anidado está **dentro** de `+=`, que copia la cadena entera cada vez porque `String` es inmutable. Son
`n²/2 = 5·10⁹` copias de caracteres.

Las cadenas parecen el tipo más simple y esconden tres trampas: el coste de las operaciones que «parecen
`O(1)`», la diferencia entre bytes y caracteres, y la tentación de comparar con fuerza bruta lo que se
resuelve contando. Este capítulo fija las tres, con los patrones que se apoyan en ellas.

> 🧠 **Modelo mental.** Una cadena inmutable es una hoja impresa: para añadir una letra hay que imprimir la
> hoja entera otra vez. Un `StringBuilder` es un cuaderno con hojas de sobra: se escribe al final y se
> imprime una sola vez.

Los ejemplos usan la cadena de juguete `"abracadabra"`: frecuencias `a 5, b 2, r 2, c 1, d 1`.

---

## 2. 📐 La teoría

**Inmutabilidad.** En Java (`String`) y Python (`str`), una cadena no se modifica: `s + t` crea una nueva de
longitud `|s| + |t|` y copia las dos. En C++, `std::string` es mutable: `s += c` y `push_back` añaden al
final con coste amortizado `O(1)`, como un `vector` ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

**El coste de concatenar en bucle.** Añadir `n` caracteres uno a uno a una cadena inmutable copia
`1 + 2 + … + n = n(n + 1)/2` caracteres: `Θ(n²)`. Con un búfer que duplica su capacidad (`StringBuilder`,
`std::string`, una lista de trozos en Python) el total de copias es `Θ(n)` por el argumento amortizado de
los arreglos dinámicos.

**Bytes y caracteres.** C++ `std::string` es una secuencia de **bytes**; con UTF-8, `"ñ"` ocupa 2 y
`s.size()` cuenta bytes. Java `String` guarda unidades UTF-16: `charAt` devuelve una unidad, y un emoji
ocupa dos (`codePointAt` da el carácter). Python `str` es una secuencia de **puntos de código**: `len("ñ")`
es 1. En los jueces, las cadenas casi siempre son ASCII y la diferencia no aparece; en producción, sí.

**Frecuencias.** Con un alfabeto conocido y pequeño (26 minúsculas), un arreglo de 26 contadores es `O(1)`
por actualización, sin *hashing*; un mapa sirve para alfabetos grandes o desconocidos. Dos cadenas son
**anagramas** si y solo si tienen el mismo vector de frecuencias.

**Palíndromos y dos punteros.** `s` es palíndromo si `s[i] = s[n − 1 − i]` para todo `i < n/2`. Dos
punteros desde los extremos comprueban cada par una vez: `Θ(n)` sin crear la cadena invertida.

---

## 3. 🧱 Inmutabilidad y concatenación

**Qué es.** Construir una cadena por partes con un búfer mutable y convertirla una sola vez al final.

**Por qué es correcto.** El búfer amplía su capacidad duplicándola: el coste total de las copias por
ampliación es una serie geométrica acotada por `2n`, y cada carácter se escribe una vez.

**Cómo va.** Escribir `"abracadabra"` carácter a carácter:

```text
s += c (inmutable):     copia 1, 2, 3, …, 11 caracteres → 66 copias; con n = 10⁵, ≈ 5·10⁹
StringBuilder:          escribe 11; amplía la capacidad 2–3 veces (copias 16 + …) → Θ(n)
```

**Cuánto.** `Θ(n)` con búfer; `Θ(n²)` con concatenación inmutable en bucle.

**La plantilla**, construir la salida de un problema por partes:

```cpp
#include <string>
#include <vector>

// En C++ std::string es mutable: += y push_back son O(1) amortizado. reserve evita las ampliaciones.
std::string joinWords(const std::vector<std::string>& words, char sep) {
    std::string out;
    std::size_t total = 0;
    for (const auto& w : words) total += w.size() + 1;
    out.reserve(total);
    for (std::size_t i = 0; i < words.size(); i++) {
        if (i) out += sep;
        out += words[i];
    }
    return out;
}
```

```java
// En Java: StringBuilder, y toString() una sola vez al final.
static String joinWords(String[] words, char sep) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < words.length; i++) {
        if (i > 0) sb.append(sep);
        sb.append(words[i]);
    }
    return sb.toString();
}
// Para la salida de un programa, todo en un StringBuilder (o un PrintWriter con búfer) y un solo print.
```

```python
def join_words(words, sep):
    """En Python: una lista de trozos y un solo join al final."""
    parts = []
    for i, w in enumerate(words):
        if i:
            parts.append(sep)
        parts.append(w)
    return ''.join(parts)                                # o directamente sep.join(words)
```

- **En Java**, `String.join`, `String.valueOf(char[])` y `new String(char[])` también son lineales; lo
  cuadrático es `+=` dentro de un bucle (el compilador solo optimiza `+` dentro de una expresión).
- **En Python**, CPython optimiza a veces `s += c` cuando nadie más referencia `s`, pero no está
  garantizado (PyPy no lo hace): la lista y `join` son la forma segura.
- **Modificar caracteres**: `char[]` en Java (`s.toCharArray()`), `list(s)` en Python, y de vuelta al final.
- **Subcadenas**: `substr` en C++ y `s[i:j]` en Python **copian** (`O(j − i)`); `substring` en Java copia
  desde Java 7. En bucles, mejor índices que subcadenas.

### De la versión ingenua a la buena

**El problema.** Escapar un texto para CSV: duplicar cada comilla doble. `di "hola"` pasa a `di ""hola""`.
Con `n = 10⁶` caracteres.

**La versión ingenua:**

```java
// Correcta: concatenación en bucle. Θ(n²) copias por la inmutabilidad de String.
static String escapeNaive(String s) {
    String out = "";
    for (int i = 0; i < s.length(); i++) {
        char c = s.charAt(i);
        out += c;
        if (c == '"') out += '"';
    }
    return out;
}
```

> «Cada `+=` copia todo lo anterior: con un millón de caracteres son del orden de `5·10¹¹` copias. Un
> `StringBuilder` con capacidad `n` escribe cada carácter una vez.»

**El camino a la buena.** `StringBuilder sb = new StringBuilder(s.length() + 16)` y `append` en el bucle:
`Θ(n)`.

**Cuándo sí:** siempre que una cadena se construya por partes en un bucle. **Cuándo no:** una concatenación
fija de pocas partes (`a + b + c` fuera de un bucle) ya es lineal.

> **Veredicto:** en Java y Python las cadenas no se modifican: se construyen en un búfer (`StringBuilder`,
> lista y `join`) y se convierten una vez. En C++, `+=` ya es el búfer.

---

## 4. 🧱 Frecuencias y anagramas

**Qué es.** Contar cuántas veces aparece cada carácter en un arreglo indexado por `c − 'a'`, y comparar
cadenas por su vector de frecuencias o por una firma canónica (la cadena ordenada o el vector como clave).

**Por qué es correcto.** Dos cadenas son permutación una de la otra si y solo si cada carácter aparece el
mismo número de veces en las dos: el vector de frecuencias identifica el multiconjunto.

**Cómo va**, en `"abracadabra"`: `a 5, b 2, c 1, d 1, r 2`, el resto 0. Su firma ordenada es
`aaaaabbcdrr`; cualquier anagrama tiene la misma.

**Cuánto.** `Θ(n)` contar; comparar dos vectores, `Θ(σ)` con `σ = 26`. La firma ordenada cuesta
`Θ(L log L)` por palabra; la firma por conteo, `Θ(L + σ)`.

**La plantilla:**

```cpp
#include <array>
#include <string>

// Frecuencias de minúsculas y comprobación de anagrama.
std::array<int, 26> freq(const std::string& s) {
    std::array<int, 26> f{};
    for (char c : s) f[c - 'a']++;
    return f;
}
bool isAnagram(const std::string& a, const std::string& b) {
    return a.size() == b.size() && freq(a) == freq(b);   // std::array se compara elemento a elemento
}
```

```java
static int[] freq(String s) {
    int[] f = new int[26];
    for (int i = 0; i < s.length(); i++) f[s.charAt(i) - 'a']++;
    return f;
}

static boolean isAnagram(String a, String b) {
    return a.length() == b.length() && java.util.Arrays.equals(freq(a), freq(b));
}

// Firma para agrupar en un HashMap: la cadena ordenada (o Arrays.toString(freq(s))).
static String signature(String s) {
    char[] c = s.toCharArray();
    java.util.Arrays.sort(c);
    return new String(c);
}
```

```python
from collections import Counter

def freq(s):
    f = [0] * 26
    for ch in s:
        f[ord(ch) - 97] += 1
    return f

def is_anagram(a, b):
    return len(a) == len(b) and freq(a) == freq(b)       # o Counter(a) == Counter(b)

def signature(s):
    return ''.join(sorted(s))                            # o tuple(freq(s)) como clave de dict
```

- **Arreglo de 26 frente a mapa**: el arreglo es más rápido y no tiene colisiones; el mapa, para Unicode o
  alfabetos desconocidos.
- **`Counter`** en Python es cómodo, pero para cadenas largas el arreglo con `ord` es más rápido.
- **Firma como clave**: en Java, `Arrays.toString(freq)` o la cadena ordenada; en Python, una `tuple` (las
  listas no son *hashables*); en C++, el `std::array` dentro de un `map` (o la cadena ordenada en un
  `unordered_map`).
- **Ventanas**: las frecuencias se actualizan al mover una ventana con un `+1` y un `−1`
  ([`04/02`](../04-secuencias/02-dos-punteros-y-ventana.md)).

### De la versión ingenua a la buena

**El problema.** En una lista de `n = 10⁵` palabras, ¿cuántos **pares** son anagramas entre sí? En
`abra, cada, bara, raba, daca, abra`, las firmas son `aabr` (cuatro veces) y `aacd` (dos): `6 + 1 = 7` pares.

**La versión ingenua:** comparar las frecuencias de cada par. Correcta, `Θ(n² · L)`: `5·10⁹` comparaciones
de pares.

> «Dos palabras son anagramas si tienen la misma firma. En lugar de comparar pares, cuento cuántas palabras
> tiene cada firma en un mapa; un grupo de `k` aporta `k(k − 1)/2` pares.»

**El camino a la buena.** Firma por palabra y un mapa de conteos: `Θ(n · L log L)` con la firma ordenada.

**Cuándo sí:** anagramas, «¿se puede formar `t` con las letras de `s`?», letras repetidas, la letra más
frecuente, ventanas con condiciones de frecuencia. **Cuándo no:** si el orden importa (subsecuencias,
patrones): eso es KMP, Z o *hashing* ([`16/02`](02-kmp.md)–[`16/04`](04-hashing-de-cadenas.md)).

> **Veredicto:** con letras, se cuenta: un arreglo de 26 y la firma como clave sustituyen a comparar pares.

---

## 5. 🧱 Palíndromos con dos punteros

**Qué es.** Comparar `s[i]` con `s[j]` avanzando `i` desde el principio y `j` desde el final hasta que se
crucen. Variantes: saltar caracteres que no cuentan, contar los pares distintos, expandir desde un centro.

**Por qué es correcto.** Es la definición de palíndromo recorrida una vez; cada par `(i, n − 1 − i)` se
compara exactamente una vez.

**Cómo va**, en `"abracadabra"`:

```text
(0,10) a=a ✓   (1,9) b≠r ✗   (2,8) r≠b ✗   (3,7) a=a ✓   (4,6) c≠d ✗   centro 5
3 pares distintos: no es palíndromo, y hacen falta 3 cambios para que lo sea
```

**Cuánto.** `Θ(n)` tiempo y `Θ(1)` memoria extra.

**La plantilla**, comprobar y contar los pares distintos en `s[l..r]`:

```cpp
#include <string>

// Número de pares (i, j) simétricos distintos en s[l..r]; 0 si es palíndromo.
int mismatches(const std::string& s, int l, int r) {
    int count = 0;
    while (l < r) { if (s[l] != s[r]) count++; l++; r--; }
    return count;
}
```

```java
static int mismatches(String s, int l, int r) {
    int count = 0;
    while (l < r) { if (s.charAt(l) != s.charAt(r)) count++; l++; r--; }
    return count;
}
```

```python
def mismatches(s, l, r):
    """Pares simétricos distintos en s[l..r]."""
    count = 0
    while l < r:
        if s[l] != s[r]:
            count += 1
        l += 1
        r -= 1
    return count
```

- **Sin crear la invertida**: `s == s[::-1]` en Python es `Θ(n)` y cómodo, pero crea una copia; los
  punteros no.
- **Saltar lo que no cuenta** (espacios, signos): dentro del bucle, avanzar `l` o retroceder `r` mientras
  `!isalnum`, y comparar en minúsculas.
- **Expandir desde el centro** da todos los palíndromos en `Θ(n²)`: `2n − 1` centros (letras y huecos);
  Manacher lo baja a `Θ(n)` ([`16/03`](03-funcion-z-y-manacher.md)).

### De la versión ingenua a la buena

**El problema.** ¿Se puede convertir `s` en palíndromo **cambiando como mucho una letra**? `abca` sí (la `c`
por `b`); `abracadabra` no (necesita 3).

**La versión ingenua:** probar cada posición con cada una de las 26 letras y comprobar si queda palíndromo.
Correcta, `Θ(26 · n²)`.

> «Un cambio arregla exactamente un par simétrico distinto. Así que basta contar los pares distintos con
> dos punteros: si hay como mucho uno, sí.»

**El camino a la buena.** `mismatches(s, 0, n − 1) ≤ 1`: `Θ(n)`.

**Cuándo sí:** palíndromos, comparar desde los extremos, invertir en el sitio, «¿cuántos cambios faltan?».
**Cuándo no:** «el palíndromo más largo» o «contar todos los palíndromos» con `n` grande (Manacher,
`16/03`); palíndromos como subsecuencia (DP, `12/04`).

> **Veredicto:** palíndromo es simetría: dos punteros desde los extremos, `Θ(n)` y sin copias; cada par
> distinto es un cambio.

---

## 6. ⏱️ La tabla de costes

| Operación | C++ `std::string` | Java `String` / `StringBuilder` | Python `str` | Lo que la tabla no dice |
|---|---|---|---|---|
| Añadir un carácter | `O(1)` amortizado | `String`: `O(n)`; `StringBuilder`: `O(1)` amortizado | `O(n)` (lista: `O(1)`) | En bucle, `+=` inmutable es cuadrático |
| Leer `s[i]` | `O(1)` (byte) | `O(1)` (unidad UTF-16) | `O(1)` (punto de código) | No siempre es «un carácter» |
| Subcadena | `O(k)` copia | `O(k)` copia | `O(k)` copia | En bucles, índices |
| Comparar iguales | `O(n)` | `O(n)` (`equals`, no `==`) | `O(n)` | En Java, `==` compara referencias |
| Frecuencias | `O(n)` | `O(n)` | `O(n)` | Arreglo de 26 mejor que mapa |

---

## 7. 🧭 Cómo se elige

```text
¿Construyes una cadena por partes? → búfer: StringBuilder, lista + join, std::string con +=
¿La pregunta es sobre qué letras y cuántas (no su orden)? → frecuencias (arreglo de 26) o firma
¿La pregunta es de simetría? → dos punteros desde los extremos
¿Importa el orden: buscar un patrón, comparar subcadenas? → 16/02 (KMP), 16/03 (Z), 16/04 (hash)
```

> **Regla de entrevista:** en Java, di «`StringBuilder`» antes de escribir el primer `+=` dentro de un
> bucle. Es una de las primeras cosas que mira un entrevistador.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Construye la cadena», salida de `10⁵` líneas | Búfer y un solo `print` | La concatenación y la E/S son cuadráticas o lentas |
| «Anagrama», «reordenando las letras» | Frecuencias o firma | El orden no importa |
| «Solo minúsculas» | Arreglo de 26 | Alfabeto pequeño y conocido |
| «Palíndromo», «se lee igual al revés» | Dos punteros | Simetría |
| «Cuántos cambios / borrados para…» con letras | Contar diferencias de frecuencias o pares | Cada cambio arregla uno |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`s += c` en un bucle es `O(n)`» | En Java y Python es `Θ(n²)`: cada `+=` copia la cadena entera |
| «En Java, `s1 == s2` compara cadenas» | Compara referencias; `equals` compara el contenido |
| «`s.length()` cuenta caracteres» | En Java cuenta unidades UTF-16 y en C++ bytes; un emoji o una `ñ` en UTF-8 lo rompen |
| «Para anagramas hay que ordenar» | Contar es `Θ(n)`; ordenar, `Θ(n log n)` |
| «`s == s[::-1]` no cuesta nada» | Crea una copia de `n` caracteres |
| «Un mapa es siempre mejor que un arreglo para contar» | Con 26 letras, el arreglo es más rápido y más simple |

---

## 📚 Para profundizar

- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), introducción al cap. 5: el
  coste de las operaciones de cadenas en Java. *Lectura troncal.*
- **Documentación** — cppreference, [`std::basic_string`](https://en.cppreference.com/cpp/string/basic_string).
  *Lectura troncal.*
- **Documentación** — Java SE 21, [`StringBuilder`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/StringBuilder.html).
  *Lectura troncal.*
- **Documentación** — Python, [*Text Sequence Type — str*](https://docs.python.org/3/builtins/stdtypes.html#text-sequence-type-str).
  *Lectura troncal.*
- **Documentación** — Python, [`str.join`](https://docs.python.org/3/builtins/stdtypes.html#str.join).

---

## 🧠 Preguntas

1. ¿Por qué `s += c` en un bucle es cuadrático en Java y en Python, y no en C++? 🟢
2. ¿Cómo construyes una cadena por partes en cada uno de los tres lenguajes? 🟢
3. ¿Cuándo son dos cadenas anagramas? 🟢
4. ¿Cómo compruebas que una cadena es palíndromo sin crear su inversa? 🟢
5. ¿Qué devuelve `length()` en Java para una cadena con un emoji, y `len()` en Python? 🟡
6. ¿Por qué en Java no se comparan cadenas con `==`? 🟡
7. ¿Arreglo de 26 o mapa para contar letras? ¿Cuándo cada uno? 🟡
8. ¿Qué firma usas como clave para agrupar anagramas en cada lenguaje? 🟡
9. Demuestra que construir con un búfer que duplica su capacidad cuesta `Θ(n)`. 🟠
10. ¿Cuántos cambios de letra necesitas como mínimo para que una cadena sea palíndromo, y por qué? 🟠
11. ¿Cuánto cuesta obtener una subcadena en cada lenguaje, y cómo lo evitas en un bucle? 🟠
12. Cuenta los pares de palabras que son anagramas en una lista de `10⁵` palabras. ¿Coste? 🔴
13. ¿Qué subcadena más larga tiene todas sus letras un número par de veces, y cómo la encuentras en `Θ(n)`? 🔴

---

## 🧩 Problemas propios

### La letra que más se repite

**Nivel:** 🟢 · **Formato:** programa completo.

Imprime la letra minúscula que más veces aparece en `s` (la menor alfabéticamente si hay empate) y cuántas
veces aparece.

- **Entrada.** Una línea con `s`.
- **Salida.** La letra y el número, separados por un espacio.
- **Restricciones.** `1 ≤ |s| ≤ 10⁶`; solo minúsculas.

```text
Entrada         Salida
abracadabra     a 5

Entrada         Salida
zyx             x 1
```

**Pista 1:** ¿cuántos contadores necesitas, y en qué orden los recorres para el desempate?

### ¿Palíndromo reordenando?

**Nivel:** 🟡 · **Formato:** programa completo.

Para cada una de `q` consultas `l r`, imprime `YES` si las letras de `s[l..r]` (desde 1) se pueden
**reordenar** para formar un palíndromo, y `NO` si no.

- **Entrada.** Una línea con `s`. Una línea con `q`. Después, `q` líneas con `l r`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ |s|, q ≤ 2·10⁵`; solo minúsculas.

```text
Entrada         Salida
abracadabra     YES
4               NO
4 6             YES
1 4             NO
6 8
1 11

Entrada         Salida
ab              YES
2               NO
1 1
1 2
```

**Pista 1:** ¿cuántas letras pueden aparecer un número impar de veces en un palíndromo?

### Todo en pares

**Nivel:** 🔴 · **Formato:** programa completo.

Imprime la longitud de la subcadena más larga de `s` en la que **cada** letra aparece un número par de veces
(0 cuenta como par; la subcadena vacía vale 0).

- **Entrada.** Una línea con `s`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ |s| ≤ 10⁶`; solo minúsculas.

```text
Entrada         Salida
abcabcxx        8

Entrada         Salida
abc             0
```

**Pista 1:** si solo te importa la paridad de cada letra, ¿cuántos bits describen un prefijo?

🔥 **Para el geek — en Go:** una `string` es una secuencia de bytes y `s[i]` es un `byte`, no un carácter;
`for _, r := range s` recorre `rune` (puntos de código). Con texto UTF-8, contar con `s[i] - 'a'` rompe en
cuanto aparece una `ñ`.

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con un problema de cadenas que da TLE, busca un `+=` o una subcadena
> dentro de un bucle. Si una IA te ayuda, que sea a encontrar esa línea, no a reescribir el algoritmo
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Alternating Characters](https://www.hackerrank.com/challenges/alternating-characters/problem) | HackerRank | 🟢 | Recorrido lineal | ¿Qué pares de vecinos obligan a borrar? |
| [ ] | [Making Anagrams](https://www.hackerrank.com/challenges/making-anagrams/problem) | HackerRank | 🟢 | Diferencia de frecuencias | Para cada letra, ¿cuántas sobran en una de las dos? |
| [ ] | [Valid Palindrome II](https://leetcode.com/problems/valid-palindrome-ii/) | LeetCode | 🟢 | Dos punteros con un borrado | Al primer par distinto, ¿qué dos opciones tienes? |
| [ ] | [Longest Palindrome](https://leetcode.com/problems/longest-palindrome/) | LeetCode | 🟢 | Frecuencias y paridad | ¿Cuántas letras impares puede tener un palíndromo? |
| [ ] | [Palindrome Index](https://www.hackerrank.com/challenges/palindrome-index/problem) | HackerRank | 🟡 | Dos punteros con un borrado | ¿Qué índice devuelves al primer par distinto? |
| [ ] | [Reverse Words in a String](https://leetcode.com/problems/reverse-words-in-a-string/) | LeetCode | 🟡 | Construir con búfer | ¿Cómo separas las palabras si hay varios espacios seguidos? |
| [ ] | [Determine if Two Strings Are Close](https://leetcode.com/problems/determine-if-two-strings-are-close/) | LeetCode | 🟡 | Frecuencias como multiconjunto | ¿Qué se conserva al intercambiar los papeles de dos letras? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Sherlock and the Valid String](https://www.hackerrank.com/challenges/sherlock-and-valid-string/problem) | HackerRank | 🟡 | Frecuencias de frecuencias | ¿Cuántas frecuencias distintas puede haber para que quitar una letra baste? |
| [ ] | [String Compression](https://leetcode.com/problems/string-compression/) | LeetCode | 🟡 | Escribir en el sitio | ¿Puedes escribir por detrás del puntero de lectura sin pisarlo? |
| [ ] | [Minimum Number of Steps to Make Two Strings Anagram](https://leetcode.com/problems/minimum-number-of-steps-to-make-two-strings-anagram/) | LeetCode | 🟡 | Diferencia de frecuencias | ¿Cuántas letras de `t` no tienen pareja en `s`? |
| [ ] | [Longest Palindrome by Concatenating Two Letter Words](https://leetcode.com/problems/longest-palindrome-by-concatenating-two-letter-words/) | LeetCode | 🟡 | Frecuencias de pares | ¿Qué pareja necesita `ab`, y qué hace especial a `aa`? |

---

## ✅ Criterio de dominio

- Construir cadenas en un búfer en los tres lenguajes sin pensarlo, y explicar el coste de `+=`.
- Contar frecuencias con un arreglo de 26 y agrupar por firma.
- Recorrer con dos punteros y contar los cambios que faltan para un palíndromo.
- Resolver Determine if Two Strings Are Close y Palindrome Index sin pista 2.

---

**Anterior:** — · **Siguiente:** [`16/02` — KMP y la función de prefijo](02-kmp.md) · **Relacionado:**
[`06/04` — *Hashing* de secuencias](../06-lineales-y-hashing/04-hashing-de-secuencias.md); [`12/04` — DP sobre cadenas](../12-dp-clasica/04-dp-sobre-cadenas.md).
