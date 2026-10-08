# 08 — Simulación

> El examen del bloque `13`: preguntas que cruzan las máscaras, la *digit DP*, los árboles y los DAG, la
> probabilidad, las optimizaciones, las matrices y los trucos de concurso; cuatro problemas propios
> cronometrados que no dicen de qué capítulo son —uno parece pedir una optimización y no la necesita—, y
> cinco problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](09-respuestas.md#08--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el que no necesita
  optimización).
- **En voz alta.** Antes de cada problema, di el estado, el orden y el coste con las cotas del enunciado; y
  solo si no cabe, busca la optimización.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de la *digit DP*
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Máscaras y dígitos

**S1.** ¿Qué estado usa Held-Karp y cuánto cuesta? 🟢

**S2.** ¿Por qué recorrer todas las submáscaras de todas las máscaras cuesta `3ⁿ`? 🟡

**S3.** ¿Qué significa `tight` en una *digit DP* y por qué solo se memoizan los estados libres? 🟡

### Árboles, DAG y probabilidad

**S4.** ¿En qué orden se calcula una DP de árbol sin recursión? 🟢

**S5.** ¿Por qué el camino más largo es lineal en un DAG y NP-difícil en general? 🟡

**S6.** ¿Por qué las esperanzas se calculan hacia atrás? 🟢

**S7.** ¿Cómo se resuelve un autolazo en una DP de esperanza? 🟡

### Optimizaciones y matrices

**S8.** ¿Qué forma tiene que tener la transición para usar el *convex hull trick*? 🟡

**S9.** ¿Qué condiciones exige el CHT con deque? 🟢

**S10.** ¿Cómo se calcula el término `10¹⁸` de una recurrencia lineal? 🟢

**S11.** ¿Qué cambia para el camino más barato con exactamente `k` aristas? 🟡

### Las que descolocan

**S12.** El enunciado dice `n ≤ 3 000` y la DP es `Θ(n²)`. Alguien propone el CHT. ¿Qué dices? 🟠

**S13.** «El viajante solo se resuelve por fuerza bruta.» ¿Qué respondes con números? 🟠

**S14.** Tu *digit DP* da uno más en todos los casos. ¿Qué miras? 🟠

**S15.** «La esperanza de un producto es el producto de esperanzas.» ¿Cuándo es verdad? 🟠

**S16.** Tu CHT pasa con `n` pequeño y falla con `n = 2·10⁵`. ¿Qué sospechas? 🟠

**S17.** Te piden «exactamente `k` grupos» con `n = k = 10⁵`. ¿Qué técnica nombrarías, y qué tendrías que comprobar antes? 🟠

**S18.** Tu potencia de matrices da basura con `n = 10¹⁸`. ¿Qué miras? 🟠

**S19.** Demuestra que en SOS el bucle de bits tiene que ir por fuera. 🔴

**S20.** Diseña la DP que cuenta los conjuntos independientes de un árbol y explica por qué no cuenta de más. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Ronda de inspección

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** cambiar `n!` por `2ⁿ · n²`.

Un inspector sale de la oficina 0, visita una vez cada una de las otras `n − 1` oficinas y vuelve. `d[i][j]`
es el tiempo de ir de `i` a `j` (no necesariamente igual a `d[j][i]`). Imprime el tiempo mínimo.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 16`; `0 ≤ d[i][j] ≤ 10⁶`; `d[i][i] = 0`.

```text
Entrada            Salida
4                  21
0 2 9 10
1 0 6 4
15 7 0 8
6 3 12 0

Entrada            Salida
2                  8
0 5
3 0
```

**Pista 1:** para seguir, ¿necesitas el orden de las visitas o solo cuáles hiciste y dónde estás?

### Suma de cifras prima

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** contar en un rango de hasta `10¹⁸` sin recorrerlo.

¿Cuántos números de `[a, b]` tienen la suma de sus cifras igual a un número primo?

- **Entrada.** Una línea con `a` y `b`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ a ≤ b ≤ 10¹⁸`.

```text
Entrada     Salida
1 100       37

Entrada     Salida
10 20       5
```

**Pista 1:** ¿cuánto puede valer como mucho la suma de las cifras de un número de 18 cifras?

### La rama más valiosa

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** una DP de árbol con un máximo con 0.

Los nodos de un árbol tienen valores (positivos o negativos). Elige un conjunto **conexo** y no vacío de
nodos con suma máxima. Imprime esa suma.

- **Entrada.** Una línea con `n`. Una línea con los valores. Una línea con los padres de los nodos 2 a `n`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `|valor| ≤ 10⁹`.

```text
Entrada               Salida
7                     21
5 -2 9 -1 5 -6 4
1 1 2 2 3 5

Entrada               Salida
3                     -1
-5 -1 -3
1 1
```

**Pista 1:** si el conjunto tiene un nodo más alto, ¿cuánto le conviene aportar a cada hijo?

### Grupos de valores parecidos

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no optimizar lo que ya cabe.

Parte un arreglo en grupos de elementos consecutivos. Cada grupo cuesta `(máximo − mínimo)² + C`. Imprime
el coste total mínimo.

- **Entrada.** Una línea con `n` y `C`. Una línea con los valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 3 000`; `0 ≤ C ≤ 10⁹`; `|valor| ≤ 10⁶`.

```text
Entrada            Salida
6 10               50
5 2 9 1 5 6

Entrada            Salida
2 50               100
1 10
```

**Pista 1:** con `n = 3 000`, ¿cuántas parejas `(inicio, fin)` de grupo hay?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Independent Set](https://atcoder.jp/contests/dp/tasks/dp_p) | AtCoder | 🟡 | Si un nodo es negro, ¿de qué color tienen que ser sus hijos? |
| [ ] | [Candies](https://atcoder.jp/contests/dp/tasks/dp_m) | AtCoder | 🟡 | La transición suma un tramo de la fila anterior: ¿cómo la haces en `O(1)`? |
| [ ] | [Grouping](https://atcoder.jp/contests/dp/tasks/dp_u) | AtCoder | 🟠 | ¿Qué grupo forma el elemento de menor índice que aún no tiene grupo? |
| [ ] | [Walk](https://atcoder.jp/contests/dp/tasks/dp_r) | AtCoder | 🟠 | Con `K` hasta `10¹⁸`, ¿qué entradas de qué matriz suman la respuesta? |
| [ ] | [Subtree](https://atcoder.jp/contests/dp/tasks/dp_v) | AtCoder | 🔴 | Si conoces la respuesta con raíz en el padre, ¿qué te falta para la del hijo? |

---

## ✅ Las frases que hay que tener listas

> «Antes de optimizar, el estado y el coste con las cotas del enunciado: con `n ≤ 3 000`, `Θ(n²)` cabe y la
> optimización es ceremonia.»

> «Con `n ≤ 20`, el conjunto es el estado: `2ⁿ · n²` en lugar de `n!`. Con `10¹⁸`, cifra a cifra con `tight`,
> o la potencia de una matriz.»

> «En árboles y DAG, el orden lo da la forma: hijos antes que padres, predecesores antes que sucesores. Y las
> esperanzas, desde el final.»

---

**Anterior:** [`13/07` — Trucos de nivel alto](07-trucos-de-nivel-alto.md) · **Siguiente:** [`13/09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`13/01` — DP con máscaras de bits](01-mascaras-de-bits.md).
