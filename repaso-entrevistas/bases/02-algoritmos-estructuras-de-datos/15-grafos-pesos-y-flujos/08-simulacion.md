# 08 — Simulación

> El examen del bloque `15`: preguntas que cruzan Dijkstra, Bellman-Ford y Floyd, A\*, el árbol de expansión
> mínima, los flujos y los emparejamientos; cuatro problemas propios cronometrados que no dicen de qué
> capítulo son —uno tiene pesos y no necesita Dijkstra—, y cinco problemas externos que no aparecen antes en
> el bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](09-respuestas.md#08--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di qué algoritmo y por qué: los pesos (¿negativos?, ¿iguales?),
  el número de orígenes y destinos, y las cotas.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de la arista obligatoria
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Caminos mínimos

**S1.** ¿Qué condición exige Dijkstra y qué pasa si no se cumple? 🟢

**S2.** ¿Para qué sirve la ronda número `n` de Bellman-Ford? 🟢

**S3.** ¿Por qué el bucle de `k` va por fuera en Floyd-Warshall? 🟡

**S4.** ¿Cuándo eliges Dijkstra sin montículo? 🟡

**S5.** ¿Qué tiene que cumplir la heurística de A\* para que el camino sea óptimo sin reabrir vértices? 🟡

### Árboles, flujos y parejas

**S6.** ¿Qué dice la propiedad del corte del árbol de expansión mínima? 🟢

**S7.** ¿En qué se diferencian Prim y Dijkstra? 🟢

**S8.** Enuncia el teorema de flujo máximo y corte mínimo. 🟢

**S9.** ¿Cómo se modela un emparejamiento bipartito como flujo? 🟡

**S10.** ¿Qué dice el teorema de König y para qué sirve? 🟡

### Las que descolocan

**S11.** Todas las aristas pesan 7 y alguien escribe Dijkstra. ¿Qué dices? 🟠

**S12.** Tu Dijkstra da WA solo en los casos con algún peso negativo, aunque no hay ciclos negativos. ¿Qué
propones? 🟠

**S13.** Te piden el árbol de expansión mínima que **contenga** una arista concreta. ¿Cómo lo adaptas? 🟠

**S14.** Tu Dijkstra pasa todo salvo un caso con un vértice de grado `10⁵`, que da TLE. ¿Qué miras? 🟠

**S15.** «El flujo máximo es lo que sale de la fuente.» ¿Qué respondes con un ejemplo? 🟠

**S16.** Tu emparejamiento da menos parejas que la respuesta. Usas un voraz «al primero libre». ¿Qué pasa? 🟠

**S17.** Te piden el camino más barato con un número **par** de tramos. ¿Cuál es el estado? 🟠

**S18.** «A\* siempre explora menos que Dijkstra.» ¿Cuándo es falso? 🟠

**S19.** Demuestra la propiedad del corte por intercambio. 🔴

**S20.** Diseña cómo decidir si un grafo dirigido tiene un ciclo negativo en **cualquier** parte, no solo
alcanzable desde un vértice dado, y di el coste. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Tramos pares

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** meter la paridad en el estado de un camino mínimo con pesos.

Un tren nocturno solo puede llegar a destino tras un número **par** de tramos. ¿Cuánto cuesta, como mínimo,
ir de la estación 1 a la `n` con un número par de tramos (se pueden repetir estaciones y vías)? Imprime `-1`
si no se puede.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con `u v w` (vías de doble sentido).
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 10⁵`; `0 ≤ m ≤ 2·10⁵`; `1 ≤ w ≤ 10⁹`.

```text
Entrada     Salida
4 4         6
1 2 1
2 3 1
1 3 5
3 4 1

Entrada     Salida
6 7         -1
1 2 2
1 3 4
2 4 3
2 5 1
3 5 7
4 6 2
5 6 5
```

**Pista 1:** si llegas a una estación con un número impar de tramos, ¿tienes el mismo futuro que si llegas
con uno par?

### ¿Dinero infinito?

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** detectar un ciclo negativo sin un origen dado.

En un grafo dirigido con pesos (que pueden ser negativos), ¿hay algún ciclo de peso total negativo?

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con `u v w`.
- **Salida.** `YES` o `NO`.
- **Restricciones.** `1 ≤ n ≤ 2 500`; `0 ≤ m ≤ 5 000`; `|w| ≤ 10⁹`.

```text
Entrada     Salida
4 3         YES
1 2 3
3 4 -2
4 3 1

Entrada     Salida
3 2         NO
1 2 -5
2 3 -5
```

**Pista 1:** ¿desde dónde lanzas Bellman-Ford si el ciclo puede estar en una parte que no alcanza ningún
vértice concreto?

### Con esta arista dentro

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** adaptar Kruskal a una restricción sin rehacerlo.

Imprime el peso mínimo de un árbol de expansión de un grafo no dirigido que **contenga** la arista número
`k` (numeradas desde 1 en el orden de la entrada), o `-1` si el grafo no es conexo.

- **Entrada.** Una línea con `n`, `m` y `k`. Después, `m` líneas con `u v w`.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 10⁵`; `1 ≤ k ≤ m ≤ 2·10⁵`; `1 ≤ w ≤ 10⁹`.

```text
Entrada     Salida
6 7 5       15
1 2 2
1 3 4
2 4 3
2 5 1
3 5 7
4 6 2
5 6 5

Entrada     Salida
3 1 1       -1
1 2 5
```

Con el mismo grafo y `k = 4`, la salida es 12.

**Pista 1:** si la arista obligatoria ya está puesta antes de empezar, ¿qué le pasa a la componente de sus
extremos?

### Peaje único

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar Dijkstra cuando todos los pesos son iguales.

En una red de carreteras, **todas** cuestan `c` de peaje. ¿Cuánto cuesta como mínimo ir de la ciudad 1 a la
`n`? Imprime `-1` si no se puede.

- **Entrada.** Una línea con `n`, `m` y `c`. Después, `m` líneas con `u v`.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 2·10⁵`; `0 ≤ m ≤ 2·10⁵`; `1 ≤ c ≤ 10⁹`.

```text
Entrada     Salida
6 7 7       21
1 2
1 3
2 4
2 5
3 5
4 6
5 6

Entrada     Salida
3 1 5       -1
1 2
```

**Pista 1:** si todas las aristas cuestan lo mismo, ¿qué minimizas en realidad?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Number of Restricted Paths From First to Last Node](https://leetcode.com/problems/number-of-restricted-paths-from-first-to-last-node/) | LeetCode | 🟡 | La condición compara distancias a `n`: ¿qué calculas primero? |
| [ ] | [The Two Routes](https://codeforces.com/problemset/problem/601/A) | Codeforces | 🟡 | ¿Hay una vía directa entre 1 y `n`? Entonces, ¿quién va directo? |
| [ ] | [Edge Deletion](https://codeforces.com/problemset/problem/1076/D) | Codeforces | 🟠 | ¿Qué aristas mantienen las distancias mínimas de todos los vértices que conservas? |
| [ ] | [Reachable Nodes In Subdivided Graph](https://leetcode.com/problems/reachable-nodes-in-subdivided-graph/) | LeetCode | 🔴 | ¿Cuánto movimiento te sobra al llegar a cada nodo original? |
| [ ] | [Minimum Weighted Subgraph With the Required Paths](https://leetcode.com/problems/minimum-weighted-subgraph-with-the-required-paths/) | LeetCode | 🔴 | Los dos caminos se juntan en algún vértice: ¿qué distancias necesitas desde y hacia él? |

---

## ✅ Las frases que hay que tener listas

> «Antes del algoritmo, los pesos: iguales, BFS; 0 y 1, cola doble; no negativos, Dijkstra; negativos,
> Bellman-Ford; todos los pares con `n ≤ 500`, Floyd.»

> «Conectar todo al menor coste es un árbol de expansión mínima, por la propiedad del corte; Prim no es
> Dijkstra: prioriza la arista, no la distancia.»

> «El flujo máximo es el corte mínimo; el emparejamiento bipartito es un flujo unitario, y en bipartitos
> la cobertura mínima es el emparejamiento máximo.»

---

**Anterior:** [`15/07` — Grafos de nivel experto](07-grafos-de-nivel-experto.md) · **Siguiente:** [`15/09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`15/01` — Dijkstra](01-dijkstra.md).
