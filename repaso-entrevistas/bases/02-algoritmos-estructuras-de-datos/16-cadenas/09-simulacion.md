# 09 — Simulación

> El examen del bloque `16`: preguntas que cruzan el coste de las cadenas en cada lenguaje, KMP, Z, Manacher,
> *hashing*, Aho-Corasick, sufijos y autómatas; cuatro problemas propios cronometrados que no dicen de qué
> capítulo son —uno se resuelve con `indexOf` porque las cadenas son cortas—, y cinco problemas externos que
> no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](10-respuestas.md#09--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di qué estructura de cadenas usas y por qué la más simple no
  basta (o sí basta) con las cotas del enunciado.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el del palíndromo más largo
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Lo básico y un patrón

**S1.** ¿Por qué `s += c` en un bucle es cuadrático en Java y Python? 🟢

**S2.** ¿Qué guarda la función de prefijo y cuánto cuesta calcularla? 🟢

**S3.** ¿Cómo obtienes el periodo más corto de una cadena? 🟢

**S4.** ¿Qué diferencia hay entre la función Z y la de prefijo? 🟡

**S5.** ¿Por qué Manacher intercala un separador entre las letras? 🟡

### Muchos patrones, sufijos y autómatas

**S6.** ¿Qué es un enlace de fallo en Aho-Corasick? 🟢

**S7.** ¿Cuántas subcadenas distintas tiene una cadena, en términos del *suffix array*? 🟡

**S8.** ¿Qué controla la probabilidad de colisión del *hashing* de cadenas? 🟡

**S9.** ¿Por qué simular un NFA nunca es exponencial? 🟡

**S10.** ¿Cuántos palíndromos distintos puede tener una cadena de longitud `n`? 🟢

### Las que descolocan

**S11.** «`indexOf` es `O(n)`.» ¿Qué respondes, y cuándo da igual? 🟠

**S12.** Tu KMP pierde apariciones solapadas. ¿Qué línea miras? 🟠

**S13.** Te dan `10⁴` patrones y un texto de `10⁶`, y alguien propone `10⁴` KMP. ¿Qué dices? 🟠

**S14.** «Con *hash* no hace falta KMP.» ¿Qué respondes? 🟠

**S15.** Una expresión regular cuelga un servidor con una entrada de 40 caracteres. ¿Qué ha pasado? 🟠

**S16.** Tu *hashing* da WA solo en un caso y AC al cambiar la base. ¿Qué era? 🟠

**S17.** Ordenas los sufijos con `sort` y da TLE con `aaaa…`. ¿Por qué? 🟠

**S18.** «El palíndromo más largo es cuadrático.» ¿Cuándo es verdad en la práctica y cuándo no? 🟠

**S19.** Demuestra que la función de prefijo se calcula en tiempo lineal. 🔴

**S20.** Diseña cómo contar cadenas de longitud `n` sobre `{a, b}` que no contengan ninguna de `k` palabras
prohibidas, y di el coste. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### El trozo que se repite

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** sacar un periodo de un borde.

Imprime la longitud de la cadena más corta `t` tal que `s` es prefijo de `ttt…` (`t` repetida las veces que
haga falta).

- **Entrada.** Una línea con `s`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ |s| ≤ 10⁶`; minúsculas.

```text
Entrada         Salida
abcabcab        3

Entrada         Salida
abracadabra     7
```

**Pista 1:** si `s` es prefijo de `ttt…` con `|t| = p`, ¿qué relación hay entre `s[i]` y `s[i + p]`?

### El espejo más largo

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** pasar de los centros a lineal.

Imprime la subcadena palindrómica más larga de `s` (la que empieza antes, si hay varias).

- **Entrada.** Una línea con `s`.
- **Salida.** La subcadena.
- **Restricciones.** `1 ≤ |s| ≤ 10⁶`; minúsculas.

```text
Entrada         Salida
abracadabra     aca

Entrada         Salida
xabbay          abba
```

**Pista 1:** con `10⁶` caracteres, ¿cuánto cuesta expandir desde cada centro en una cadena de una sola
letra?

### Cuáles aparecen

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** una sola pasada para muchos patrones.

¿Cuántas de las `k` palabras aparecen al menos una vez en el texto?

- **Entrada.** Una línea con el texto. Una línea con `k`. Después, `k` líneas con una palabra.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ |texto| ≤ 10⁶`; `1 ≤ k ≤ 10⁵`; la suma de longitudes de las palabras es `≤ 10⁶`;
  minúsculas.

```text
Entrada         Salida
abracadabra     2
4
a
cab
bra
xyz

Entrada         Salida
abc             2
3
abc
abcd
c
```

**Pista 1:** si recorres el texto con un autómata de todas las palabras, ¿qué nodos hay que marcar como
«visto», y qué otros nodos quedan vistos con ellos?

### Dentro de otra

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no construir un autómata cuando la biblioteca basta.

Hay `n` palabras. ¿Cuántos pares ordenados `(i, j)` con `i ≠ j` cumplen que la palabra `i` es subcadena de la
palabra `j`?

- **Entrada.** Una línea con `n`. Después, `n` líneas con una palabra.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 100`; cada palabra de 1 a 50 minúsculas.

```text
Entrada         Salida
5               4
ab
abra
cad
abracadabra
x

Entrada         Salida
2               2
aa
aa
```

**Pista 1:** ¿cuántas búsquedas haces, y cuánto cuesta cada una con cadenas de 50 caracteres?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Remove All Occurrences of a Substring](https://leetcode.com/problems/remove-all-occurrences-of-a-substring/) | LeetCode | 🟡 | Al borrar una aparición, ¿qué parte del texto hay que volver a mirar? |
| [ ] | [String Functions](https://cses.fi/problemset/task/2107) | CSES | 🟡 | ¿Qué dos arreglos te piden, y los conoces de este bloque? |
| [ ] | [Find Substring With Given Hash Value](https://leetcode.com/problems/find-substring-with-given-hash-value/) | LeetCode | 🟠 | El *hash* pondera más a la derecha: ¿en qué sentido es fácil deslizar la ventana? |
| [ ] | [Maximum Deletions on a String](https://leetcode.com/problems/maximum-deletions-on-a-string/) | LeetCode | 🔴 | ¿Qué tabla te dice en `O(1)` si los dos trozos siguientes son iguales? |
| [ ] | [Prefix Function Queries](https://codeforces.com/problemset/problem/1721/E) | Codeforces | 🔴 | Si `s` no cambia, ¿qué puedes precalcular para no recorrer otra vez sus bordes? |

---

## ✅ Las frases que hay que tener listas

> «Antes de buscar, el coste: `indexOf` es `n · m` en el peor caso; con un patrón, KMP o Z; con muchos,
> Aho-Corasick; para comparar subcadenas arbitrarias, *hash* con `2⁶¹ − 1` y base aleatoria.»

> «Bordes y periodos salen de la función de prefijo; palíndromos de subcadenas, de Manacher; subcadenas
> distintas y repetidas, del *suffix array* con LCP.»

> «Una expresión regular es un autómata; simular el NFA es `n · m`. Los motores con vuelta atrás pueden ser
> exponenciales: con entradas externas, se acota o se usa un motor de autómatas.»

---

**Anterior:** [`16/08` — Árbol de palíndromos y árbol de sufijos](08-eertree-y-ukkonen.md) · **Siguiente:** [`16/10` — Respuestas](10-respuestas.md) ·
**Relacionado:** [`16/02` — KMP y la función de prefijo](02-kmp.md).
