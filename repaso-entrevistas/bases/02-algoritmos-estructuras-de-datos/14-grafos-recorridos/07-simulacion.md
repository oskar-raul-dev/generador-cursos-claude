# 07 — Simulación

> El examen del bloque `14`: preguntas que cruzan representaciones, BFS, DFS, orden topológico, componentes
> fuertes, puentes y Euler; cuatro problemas propios cronometrados que no dicen de qué capítulo son —uno
> parece de caminos mínimos y no lo es—, y cinco problemas externos que no aparecen antes en el bloque. Las
> respuestas y las pistas 2 y 3 están en el [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di qué es un vértice, qué es una arista y qué algoritmo recorre
  ese grafo, con su coste para las cotas del enunciado.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de la rejilla con guardias
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Representar y recorrer

**S1.** ¿Qué representación eliges para un grafo de `2·10⁵` vértices y `2·10⁵` aristas, y cuánta memoria
usa? 🟢

**S2.** ¿Por qué BFS da distancias mínimas sin pesos y DFS no? 🟢

**S3.** ¿Cuándo usas 0-1 BFS en lugar de Dijkstra? 🟡

**S4.** ¿Cuál es el estado de un BFS en una rejilla donde puedes romper como mucho `k` paredes? 🟡

### Estructura con DFS

**S5.** ¿Qué distingue, en un DFS de un dirigido, una arista que cierra un ciclo de una que no? 🟢

**S6.** ¿Cómo compruebas que un grafo es bipartito, y qué evidencia devuelves si no lo es? 🟡

**S7.** ¿Qué dos algoritmos dan un orden topológico y qué ventaja tiene cada uno? 🟢

**S8.** ¿Qué es el grafo condensado y por qué es un DAG? 🟡

**S9.** ¿Qué condición sobre `low` hace de una arista un puente? 🟢

**S10.** ¿Cuándo tiene un no dirigido un camino de Euler? 🟢

### Las que descolocan

**S11.** Te piden la distancia entre dos nodos de un **árbol** con pesos y alguien propone Dijkstra. ¿Qué
dices? 🟠

**S12.** Tu detector de ciclos en un grafo de dependencias dice «ciclo» en todos los casos con caminos que
confluyen. ¿Qué miras? 🟠

**S13.** Tu BFS en rejilla da la respuesta correcta en los ejemplos y TLE en el caso grande. Marcas al
sacar. ¿Qué pasa? 🟠

**S14.** «Pasar por todas las ciudades una vez» y «pasar por todas las carreteras una vez»: ¿cuál es
lineal? 🟠

**S15.** Tu código de puentes declara puente una de dos aristas paralelas. ¿Qué miras? 🟠

**S16.** Tu 2-SAT dice «satisfacible» y la asignación que imprime viola cláusulas. ¿Qué miras? 🟠

**S17.** Kahn y el DFS te dan órdenes topológicos distintos para el mismo grafo. ¿Hay un error? 🟠

**S18.** Un DFS recursivo en Java pasa todos los casos menos uno, que es una cadena de `2·10⁵` nodos. ¿Qué
haces sin reescribir el algoritmo? 🟠

**S19.** Demuestra que un grafo dirigido tiene orden topológico si y solo si no tiene ciclos. 🔴

**S20.** Diseña cómo contar, en un grafo no dirigido de `10⁵` vértices, cuántos vértices quedan aislados del
vértice 1 si se corta cada arista por separado, y di el coste. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Los guardias

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** meter el tiempo en el estado sin que el estado explote.

Una rejilla tiene casillas libres `.`, paredes `#`, la salida `S`, la meta `T` y casillas vigiladas con un
dígito `d` de 0 a 3: la casilla `d` está ocupada por un guardia en los instantes `t` con `t mod 4 = d`, y
en esos instantes no puedes estar en ella. Partes de `S` en el instante 0; en cada instante te mueves a una
casilla vecina o te quedas quieto. ¿En qué instante llegas a `T`, como pronto? Imprime `-1` si no se puede.

- **Entrada.** Una línea con `R` y `C`. Después, `R` líneas con la rejilla.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ R, C ≤ 1 000`; exactamente una `S` y una `T`.

```text
Entrada     Salida
1 4         4
S12T

Entrada     Salida
1 3         -1
S#T
```

**Pista 1:** ¿necesitas saber el instante exacto, o te basta algo más pequeño?

### Paquetes bloqueados

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** detectar el ciclo sin buscarlo.

Hay `n` paquetes y `m` dependencias «`u` depende de `v`» (`v` se instala antes que `u`). Un paquete se puede
instalar si todas sus dependencias se pueden instalar. ¿Cuántos paquetes **no** se pueden instalar nunca?

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con un par `u v`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `0 ≤ m ≤ 2·10⁵`.

```text
Entrada     Salida
6 6         3
2 1
3 2
4 3
2 4
5 1
6 5

Entrada     Salida
3 2         0
2 1
3 2
```

**Pista 1:** ¿qué paquetes deja sin sacar el algoritmo que instala los que ya tienen todo resuelto?

### Dos salas

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** combinar una bipartición por componentes con una decisión global.

`n` estudiantes y `m` pares de rivales que no pueden estar en la misma sala. Hay dos salas. Reparte a todos
de modo que la diferencia entre el número de estudiantes de cada sala sea mínima, e imprime esa diferencia;
`-1` si no se puede repartir.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con un par `u v`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2 000`; `0 ≤ m ≤ 2·10⁵`.

```text
Entrada     Salida
7 5         1
1 2
1 3
4 5
4 6
4 7

Entrada     Salida
3 3         -1
1 2
2 3
1 3
```

**Pista 1:** en cada grupo de rivales conectados, ¿cuántas formas de repartirlo hay, y qué cambia entre ellas?

### Túneles

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar Dijkstra donde hay un solo camino.

Una red de túneles une `n` cámaras sin formar ciclos: es un árbol, con la cámara 1 en la entrada. Cada
túnel tiene una longitud. ¿Cuál es la cámara más alejada de la entrada, medida por la suma de longitudes?
Imprime esa distancia.

- **Entrada.** Una línea con `n`. Después, `n − 1` líneas: la `i`-ésima con el padre de la cámara `i + 1` y
  la longitud del túnel que los une.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ longitud ≤ 10⁹`.

```text
Entrada     Salida
6           14
1 5
1 2
2 9
2 1
3 5

Entrada     Salida
1           0
```

**Pista 1:** ¿cuántos caminos hay entre la entrada y una cámara?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Number of Closed Islands](https://leetcode.com/problems/number-of-closed-islands/) | LeetCode | 🟡 | ¿Qué islas no cuentan, y cómo las quitas primero? |
| [ ] | [Shortest Bridge](https://leetcode.com/problems/shortest-bridge/) | LeetCode | 🟡 | Si conocieras todas las casillas de una isla, ¿desde dónde empezarías a medir? |
| [ ] | [Graph Girth](https://cses.fi/problemset/task/1707) | CSES | 🟠 | Con `n ≤ 2 500`, ¿cuántas búsquedas te puedes permitir? |
| [ ] | [Directing Edges](https://codeforces.com/problemset/problem/1385/E) | Codeforces | 🟠 | Si las aristas dirigidas ya tienen un orden válido, ¿cómo orientas las demás para respetarlo? |
| [ ] | [Bus Routes](https://leetcode.com/problems/bus-routes/) | LeetCode | 🔴 | ¿Qué cuentas, paradas o autobuses? Entonces, ¿qué es un vértice? |

---

## ✅ Las frases que hay que tener listas

> «Antes del algoritmo, el grafo: qué es un vértice, qué es una arista y cuántos hay. En rejillas con
> condiciones, el estado es (posición, lo mínimo que hay que recordar).»

> «Distancias sin pesos, BFS; con 0 y 1, cola doble; en un árbol, cualquier recorrido, porque hay un solo
> camino. Ciclos en un dirigido, tres colores; si hay que ordenar, Kahn y comparar con `n`.»

> «Con ciclos en un dirigido, colapso las SCC y el resto es un DAG. Cada arista una vez es Euler y es
> lineal; cada vértice una vez es Hamilton y no lo es.»

---

**Anterior:** [`14/06` — Puentes, puntos de articulación y Euler](06-puentes-articulacion-y-euler.md) ·
**Siguiente:** [`14/08` — Respuestas](08-respuestas.md) · **Relacionado:** [`14/02` — BFS](02-bfs.md).
