# 07 — Trucos de nivel alto

> Dos técnicas de concurso para reconocer, no para escribir de memoria: el ***Aliens trick*** (relajación
> lagrangiana), que quita de una DP la restricción «exactamente `k`» cuando la respuesta es cóncava en `k`,
> y el ***slope trick***, que representa una función convexa a trozos por sus puntos de cambio de
> pendiente. Son de concurso, no de entrevista.
>
> **Niveles:** *Aliens trick* [C] · *slope trick* [C].
>
> **📚 Lectura troncal:** ningún libro del canon los trata (excepción declarada en la guía, §11.2). La guía
> fija cp-algorithms, pero cp-algorithms **no tiene** página de ninguno de los dos (comprobado el
> 2026-10-04); las referencias troncales son USACO Guide, [*Lagrangian Relaxation*](https://usaco.guide/adv/lagrange)
> y [*Slope Trick*](https://usaco.guide/adv/slope-trick), y los artículos de Codeforces «The Trick From
> Aliens» y «Slope trick explained», por título.
>
> **Asume leído:** [`13/05` — Optimizaciones de DP](05-optimizaciones.md).
>
> **Vigencia:** 2026-10-04.

---

## 1. 🎯 El problema

Elegir **exactamente `k`** subarreglos disjuntos de suma máxima en un arreglo de `n = 2·10⁵` elementos. La
DP natural lleva `k` en el estado —`dp[i][j][dentro]`, «con `j` subarreglos usados»— y cuesta `Θ(n · k)`,
`4·10¹⁰` con `k = n`. Sin la restricción de `k` (todos los que se quiera), la DP es lineal.

Y hacer que un arreglo sea no decreciente cambiando sus valores con coste `Σ |aᵢ − bᵢ|` mínimo: la DP
natural es `dp[i][v]` = el coste con `bᵢ = v`, y `v` puede ir hasta `10⁹`.

Las dos DP son correctas y demasiado grandes. Los dos trucos de este capítulo las reducen explotando la
**convexidad**: de la respuesta en función de `k` (*Aliens*), o de `dp[i][·]` en función de `v` (*slope
trick*).

> 🧠 **Modelo mental.** Ninguno de los dos es una técnica de entrevista. Se estudian para **reconocer**
> cuándo un problema de concurso los pide: «exactamente `k`» con `n · k` enorme, o una DP sobre valores que
> es convexa.

---

## 2. 📐 La teoría

**Relajación lagrangiana.** Sea `f(k)` el óptimo con exactamente `k` elementos elegidos. Si `f` es
**cóncava** en `k` (los beneficios marginales decrecen), entonces para cada penalización `λ` el problema sin
restricción que maximiza `f(k) − λ · k` tiene como óptimo algún `k(λ)`, y `k(λ)` es no creciente en `λ`. Con
una **búsqueda binaria sobre `λ`** se encuentra el `λ` cuyo óptimo usa exactamente `k`, y entonces
`f(k) = g(λ) + λ · k`, donde `g(λ)` es el valor del problema penalizado, que se resuelve con la DP sin `k`.

**Funciones convexas a trozos.** Una función convexa y lineal a trozos con pendientes enteras queda
determinada por su valor en un punto y por el **multiconjunto de puntos donde la pendiente aumenta en 1**.
Sumarle `|x − a|` es añadir `a` dos veces a ese multiconjunto (la pendiente sube 2 en `a`); tomar el mínimo
prefijo (`min_{y ≤ x} f(y)`) es borrar los puntos de pendiente positiva. Con un montículo, cada operación es
`O(log n)`.

---

## 3. 🧱 *Aliens trick*

### Relajación lagrangiana

- **Qué resuelve.** DP con una restricción «exactamente (o como mucho) `k` elementos» cuando la respuesta
  `f(k)` es cóncava (o convexa, para minimizar): baja de `Θ(n · k)` a `Θ(n log V)`, con `V` el rango de la
  penalización.
- **Qué garantiza.** Con `f` cóncava, para cada `k` existe un `λ` tal que el óptimo penalizado usa `k`
  elementos, y `f(k) = g(λ) + λ · k`. Los empates (varios `k` con el mismo óptimo penalizado) se resuelven
  eligiendo siempre el menor (o el mayor) número de elementos en la DP penalizada.
- **Cuánto.** `O(log V)` veces la DP sin restricción.
- **Cómo reconocerlo.** «Exactamente `k`» con `n` y `k` hasta `10⁵`; la versión sin `k` es fácil; la
  respuesta parece tener rendimientos decrecientes en `k` (añadir un subarreglo más aporta cada vez menos).
- **Si no te la sabes.** La DP con `k` en el estado, `Θ(n · k)`, que con `n · k ≤ 10⁸` cabe; o la
  optimización por divide y vencerás de [`13/05`](05-optimizaciones.md) si `opt` es monótono.
- **Dónde está entera.** USACO Guide, [*Lagrangian Relaxation*](https://usaco.guide/adv/lagrange); el
  artículo de Codeforces «The Trick From Aliens», por título; el nombre viene del problema *Aliens* de la IOI
  2016.

---

## 4. 🧱 *Slope trick*

### Funciones convexas por sus puntos de quiebre

- **Qué resuelve.** DP de la forma `dp[i][x] = mín_{y ≤ x} dp[i−1][y] + |aᵢ − x|` (o variantes con `max`,
  desplazamientos y costes lineales a trozos) sin recorrer los valores de `x`: se guarda la función
  `dp[i][·]` por sus puntos de cambio de pendiente en un montículo.
- **Qué garantiza.** Si cada paso suma funciones convexas lineales a trozos y aplica mínimos prefijos o
  sufijos, la función sigue siendo convexa, y cada operación es `O(log n)`. El caso clásico —hacer un arreglo
  no decreciente con coste `Σ |aᵢ − bᵢ|`— se reduce a: meter `aᵢ` en un montículo de máximos; si el máximo
  supera a `aᵢ`, sumar la diferencia al coste y sustituir el máximo por `aᵢ`.
- **Cuánto.** `O(n log n)`.
- **Cómo reconocerlo.** DP sobre **valores** (no índices) con costes `|x − a|`, «hacer monótono el arreglo
  con el mínimo de cambios», o transiciones que son mínimos prefijos de funciones convexas.
- **Si no te la sabes.** La DP sobre los valores comprimidos (un óptimo siempre usa valores de la entrada):
  `Θ(n²)`, que con `n ≤ 3 000` cabe.
- **Dónde está entera.** USACO Guide, [*Slope Trick*](https://usaco.guide/adv/slope-trick); el artículo de
  Codeforces «Slope trick explained», por título.

---

## 5. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Exactamente `k`» con `n · k` fuera de alcance y la versión sin `k` lineal | *Aliens trick* | Se penaliza cada elemento y se busca `λ` |
| «Como mucho `k`» con rendimientos decrecientes | *Aliens trick* | Misma concavidad |
| «Hacer el arreglo no decreciente / creciente con el mínimo coste total» | *Slope trick* | DP sobre valores convexa |
| DP con costes `\|x − a\|` sobre valores hasta `10⁹` | *Slope trick* | Puntos de quiebre en un montículo |
| `n ≤ 3 000` | Ninguno | La DP directa cabe |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La DP con `k` restricciones siempre es `O(n · k)`» | Con `f(k)` cóncava, el *Aliens trick* la deja en `O(n log V)` |
| «El *Aliens trick* sirve con cualquier `f`» | Exige concavidad; sin ella, la binaria sobre `λ` salta valores de `k` |
| «En el *Aliens*, cualquier óptimo penalizado vale» | Con empates hay que elegir de forma consistente el menor o el mayor `k` |
| «El *slope trick* guarda la función entera» | Guarda solo los puntos de cambio de pendiente |
| «Son técnicas de entrevista» | Son de concurso: en una entrevista basta la DP con `k` y decir la idea |

---

## 📚 Para profundizar

- **Referencia** — USACO Guide, [*Lagrangian Relaxation*](https://usaco.guide/adv/lagrange). *Lectura troncal.*
- **Referencia** — USACO Guide, [*Slope Trick*](https://usaco.guide/adv/slope-trick). *Lectura troncal.*
- **Artículo** — Codeforces, «The Trick From Aliens» y «Slope trick explained» (blogs de la comunidad), por
  título.
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), cap. 11: la relajación como
  herramienta de aproximación, la idea de fondo de la penalización.

---

## 🧠 Preguntas

1. ¿Qué restricción quita el *Aliens trick* y qué exige de la respuesta? 🟢
2. ¿Qué guarda el *slope trick* en lugar de la función entera? 🟢
3. ¿Qué se busca con la búsqueda binaria del *Aliens trick*? 🟢
4. ¿Por qué la concavidad de `f(k)` hace que el `k` óptimo penalizado sea monótono en `λ`? 🟡
5. ¿Qué operación del *slope trick* corresponde a sumar `|x − a|`, y cuál al mínimo prefijo? 🟡
6. ¿Qué pasa con los empates en el *Aliens trick*, y cómo se tratan? 🟡
7. Compara cómo implementarías el montículo de máximos del *slope trick* en C++, Java y Python. 🟡
8. ¿Por qué hacer un arreglo no decreciente se resuelve metiendo cada valor en un montículo de máximos? 🟠
9. ¿Cuándo no hace falta ningún truco y basta la DP directa? 🟠
10. ¿Cómo reconocerías en un enunciado que la respuesta es cóncava en `k`? 🟠
11. ¿Cómo pasas de «estrictamente creciente» a «no decreciente» en el *slope trick*? 🔴
12. Explica cómo recuperas `f(k)` a partir del valor penalizado `g(λ)`. 🔴

---

## 🧩 Problemas propios

### Arreglo no decreciente

**Nivel:** 🟠 · **Formato:** programa completo.

Cambia los valores de un arreglo para que quede no decreciente, con el menor coste total `Σ |aᵢ − bᵢ|`.
Imprime ese coste.

- **Entrada.** Una línea con `n`. Una línea con los valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `|aᵢ| ≤ 10⁹`.

```text
Entrada            Salida
6                  11
5 2 9 1 5 6

Entrada            Salida
3                  2
3 2 1
```

**Pista 1:** con `n ≤ 3 000`, ¿qué valores puede tomar como mucho cada `bᵢ` en una solución óptima?

### Exactamente k tramos

**Nivel:** 🔴 · **Formato:** programa completo.

Elige exactamente `k` subarreglos no vacíos y disjuntos (no pueden solaparse, pero sí tocarse) con suma
total máxima. Imprime esa suma.

- **Entrada.** Una línea con `n` y `k`. Una línea con los valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ n ≤ 2·10⁵`; `|aᵢ| ≤ 10⁹`.

```text
Entrada            Salida
6 2                18
5 -2 9 -1 5 -6

Entrada            Salida
6 3                19
5 -2 9 -1 5 -6

Entrada            Salida
3 1                -1
-1 -2 -3
```

**Pista 1:** si cada tramo costara una «entrada» de `λ`, ¿cuántos tramos elegirías sin límite, y qué pasa al
subir `λ`?

---

## 🧩 Práctica externa

Ficha C: no hay núcleo, porque estas técnicas no salen en entrevistas ni en las tres bases. La práctica es
toda de curiosidad, en Codeforces.

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Sonya and Problem Wihtout a Legend](https://codeforces.com/problemset/problem/713/C) | Codeforces | 🔴 | *Slope trick* | Si restas `i` a cada `aᵢ`, ¿qué pasa con «estrictamente creciente»? |
| [ ] | 💀 [Buy Low Sell High](https://codeforces.com/problemset/problem/865/D) | Codeforces | 🔴 | Montículo con arrepentimiento (*slope trick*) | Si vendes hoy algo comprado antes, ¿puedes «deshacer» la venta mañana? |

---

## ✅ Criterio de dominio

- Explicar en dos frases cada truco y la condición que exige (concavidad, convexidad).
- Reconocer en un enunciado «exactamente `k`» con `n · k` enorme y nombrar la técnica.
- Resolver «Arreglo no decreciente» con la DP sobre valores comprimidos y, después, con el montículo.

---

**Anterior:** [`13/06` — Recurrencias lineales y exponenciación de matrices](06-recurrencias-lineales-y-matrices.md) · **Siguiente:** [`13/08` — Simulación](08-simulacion.md) ·
**Relacionado:** [`13/05` — Optimizaciones de DP](05-optimizaciones.md); [`08/02` — Patrones con *heap*](../08-heaps-y-union-find/02-patrones-con-heap.md).
