# 07 — Simulación

> El examen del bloque `09`: preguntas que cruzan *sparse table*, Fenwick, segment tree (con y sin
> propagación perezosa), sus variantes avanzadas, la raíz cuadrada y Mo; cuatro problemas propios
> cronometrados que no dicen de qué capítulo son, y seis problemas externos que no aparecen antes en el
> bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para cada uno de los dos primeros problemas
  y 20 para los otros dos.
- **En voz alta.** Antes de cada problema, contesta tres preguntas: ¿hay actualizaciones?, ¿la operación es
  invertible, idempotente o solo asociativa?, ¿se pueden reordenar las consultas? Con eso queda elegida la
  estructura.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Estructuras estáticas

**S1.** ¿Por qué la *sparse table* responde el mínimo en `O(1)` y no sirve para la suma? 🟡

**S2.** ¿Qué usas para sumas de tramos sin actualizaciones? 🟢

### Fenwick

**S3.** ¿Qué tramo guarda `tree[i]` en un Fenwick? 🟢

**S4.** ¿Cómo sumas `v` a un tramo y consultas un punto con un Fenwick? 🟡

**S5.** ¿Por qué Fenwick empieza en el índice 1? 🟢

### Segment tree

**S6.** ¿Qué necesita una operación para poder usarse en un segment tree? 🟢

**S7.** ¿Qué es `push` en la propagación perezosa y cuándo se llama? 🟡

**S8.** ¿Cómo se componen «asignar» y «sumar» en una etiqueta *lazy*? 🟡

### Avanzado y raíz

**S9.** ¿Cuántos nodos crea una actualización en un segment tree persistente? 🟡

**S10.** ¿Qué exige Mo y cuánto cuesta? 🟡

### Las que descolocan

**S11.** Tu Fenwick entra en un bucle infinito con la primera actualización. ¿Qué miras? 🟠

**S12.** Te piden el mínimo de un tramo con actualizaciones y escribes un Fenwick. ¿Qué falla? 🟠

**S13.** Tu segment tree con *lazy* pasa las actualizaciones y falla en las consultas que tocan nodos ya etiquetados. ¿Dónde está el error? 🟠

**S14.** «Mo es lento porque es `√n`.» ¿Qué respondes? 🟠

**S15.** Te dan un arreglo que no cambia y `10⁶` consultas de suma de tramo. Un compañero propone un segment tree. ¿Qué le dices? 🟠

**S16.** Demuestra que una consulta de tramo en un segment tree visita `O(log n)` nodos. 🔴

**S17.** Demuestra que Mo hace `O((n + q)√n)` movimientos de puntero. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Pintar la valla

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** una actualización de tramo que no es una suma.

Una valla de `n` tablas empieza con todas en color 0 (cada color tiene un número). Llegan órdenes: `= l r c`
(pinta las tablas `l` a `r`, 0-indexadas e inclusivas, del color `c`) y `? l r` (imprime la suma de los
números de color de las tablas `l` a `r`).

- **Entrada.** Una línea con `n` y `q`. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `0 ≤ c ≤ 10⁹`.

```text
Entrada            Salida
6 4                32
= 0 3 2            9
= 2 5 7
? 0 5
? 1 2

Entrada            Salida
3 4                3000000000
= 0 2 1000000000   2000000000
? 0 2
= 1 1 0
? 0 2
```

**Pista 1:** si pintas un tramo encima de otro, ¿qué queda de la pintura anterior en esas tablas?

### Valores que se repiten dos veces

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que las consultas se pueden reordenar.

Para cada consulta `l r` (0-indexada, inclusiva), imprime cuántos valores distintos aparecen **exactamente**
dos veces en `a[l..r]`. Todas las consultas están en la entrada.

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` valores. Después, `q` líneas con `l r`.
- **Salida.** `q` enteros, en el orden de entrada.
- **Restricciones.** `1 ≤ n, q ≤ 10⁵`; valores entre 1 y `10⁹`.

```text
Entrada            Salida
6 3                1
1 2 1 1 3 2        0
0 5                2
0 3
1 5

Entrada            Salida
3 2                0
5 5 5              1
0 2
0 1
```

**Pista 1:** al añadir o quitar una aparición de `x`, ¿cuándo cambia la respuesta?

### Caja registradora

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** elegir la estructura más simple que admite cambios.

Hay `n` cajas con su recaudación. Llegan órdenes: `+ p v` (la caja `p` recauda `v` más) y `? l r` (imprime la
recaudación total de las cajas `l` a `r`, 0-indexadas e inclusivas).

- **Entrada.** Una línea con `n` y `q`. Una línea con las recaudaciones. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; valores hasta `10⁹`.

```text
Entrada            Salida
6 4                17
5 2 9 1 5 6        21
? 0 3              11
+ 1 4
? 0 3
? 4 5

Entrada            Salida
1 2                2000000000
1000000000
+ 0 1000000000
? 0 0
```

**Pista 1:** la operación es una suma: ¿qué estructura de tramos con cambios es la más corta?

### Ventas acumuladas

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar ninguna estructura de este bloque.

Hay `n` ventas diarias, que no cambian, y `q` consultas `l r`: ¿cuánto se vendió del día `l` al `r`
(0-indexados, inclusivos)?

- **Entrada.** Una línea con `n` y `q`. Una línea con las ventas. Después, `q` líneas con `l r`.
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ n, q ≤ 10⁶`; ventas hasta `10⁹`.

```text
Entrada                           Salida
6 3                               28
5 2 9 1 5 6                       10
0 5                               2
2 3
1 1

Entrada                           Salida
3 1                               3000000000
1000000000 1000000000 1000000000
0 2
```

**Pista 1:** si el arreglo no cambia nunca, ¿qué se puede precalcular una sola vez?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Static Range Sum](https://judge.yosupo.jp/problem/static_range_sum) | Library Checker | 🟢 | ¿Hace falta alguna estructura si no hay cambios? |
| [ ] | [Count Number of Teams](https://leetcode.com/problems/count-number-of-teams/) | LeetCode | 🟡 | Fijado el soldado del medio, ¿cuántos equipos lo tienen en el centro? |
| [ ] | [Point Set Range Composite](https://judge.yosupo.jp/problem/point_set_range_composite) | Library Checker | 🟠 | ¿Es conmutativa la composición de funciones? ¿Qué cambia eso en la consulta? |
| [ ] | [Subarray Sum Queries](https://cses.fi/problemset/task/1190) | CSES | 🟠 | ¿Qué tiene que saber cada nodo para combinar el mejor tramo de sus dos hijos? |
| [ ] | [Number of Pairs Satisfying Inequality](https://leetcode.com/problems/number-of-pairs-satisfying-inequality/) | LeetCode | 🔴 | Si reescribes la desigualdad con `nums1[i] − nums2[i]`, ¿qué cuentas? |
| [ ] | [Prefix Sum Queries](https://cses.fi/problemset/task/2166) | CSES | 🔴 | El mayor prefijo de un tramo, ¿cómo se combina desde dos mitades? |

---

## ✅ Las frases que hay que tener listas

> «Sin cambios, prefijos o *sparse table*; con cambios y una operación invertible, Fenwick; con cualquier
> otra asociativa, segment tree; con actualizaciones de tramo, *lazy*.»

> «La *sparse table* solapa dos bloques: solo sirve con operaciones idempotentes como el mínimo.»

> «Si me dan todas las consultas y no dependen entre sí, puedo reordenarlas: *offline* por un extremo o Mo.»

---

**Anterior:** [`09/06` — Árbol cartesiano y *wavelet tree*](06-arbol-cartesiano-y-wavelet.md) ·
**Siguiente:** [`09/08` — Respuestas](08-respuestas.md) · **Relacionado:** [`09/03` — Segment tree](03-segment-tree.md).
