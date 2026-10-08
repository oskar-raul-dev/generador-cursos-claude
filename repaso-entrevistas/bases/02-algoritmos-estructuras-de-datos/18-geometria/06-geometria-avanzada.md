# 06 — Geometría avanzada

> Tres temas que se reconocen y se nombran: la intersección de semiplanos, que da la región que cumple `n`
> restricciones lineales a la vez; la triangulación de Delaunay y su dual, el diagrama de Voronoi, que
> responden «quién está más cerca de quién»; y la geometría en tres dimensiones, donde el producto cruz pasa a
> ser un vector y la orientación un determinante de `3 × 3`. Para cada uno, qué resuelve, qué garantiza,
> cuánto cuesta, cómo se reconoce y qué escribir si no se sabe.
>
> **Niveles:** semiplanos [C] · Delaunay y Voronoi [C] · 3D [C].
>
> **📚 Lectura troncal:** de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed.
> (Springer, 2008), caps. 4, 7 y 9; cp-algorithms, [*Half-plane intersection*](https://cp-algorithms.com/geometry/halfplane-intersection.html)
> y [*Delaunay triangulation and Voronoi diagram*](https://cp-algorithms.com/geometry/delaunay.html).
>
> **Asume leído:** [`18/04` — Envolvente convexa](04-envolvente-convexa.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--semiplanos) · [4](#4--delaunay-y-voronoi) · [5](#5--3d) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Tres preguntas que los capítulos anteriores no cierran. Un vigilante quiere saber desde qué zona de una sala
de forma irregular se ven todas las paredes: es la región que queda a la izquierda de cada pared a la vez,
una **intersección de semiplanos**. Una ciudad con `10⁵` hospitales quiere asignar a cada casa el hospital más
cercano: es el **diagrama de Voronoi**. Un dron mide puntos en el espacio y hay que saber si cuatro de ellos
están en el mismo plano: es la **orientación en 3D**.

Los tres tienen algoritmos en `O(n log n)` largos y delicados, que aparecen en concursos de nivel alto y en
software real (sistemas de información geográfica, mallas para simulación, robótica). En una entrevista, lo
que se espera es saber que existen, qué garantizan y cuándo una alternativa corta basta.

> 🧠 **Modelo mental.** Semiplanos es la envolvente convexa vista desde dentro: en lugar de los puntos que
> rodean, las rectas que recortan. Voronoi reparte el plano entre los puntos; Delaunay une a los vecinos de ese
> reparto.

---

## 2. 📐 La teoría

**Intersección de semiplanos.** Cada restricción `a·x + b·y ≤ c` es un semiplano. La intersección de `n` de
ellos es un **polígono convexo** (quizá vacío o no acotado) con como mucho `n` lados.

**Diagrama de Voronoi.** Para `n` puntos («sitios»), la celda de cada uno es la región del plano más cercana a
él que a cualquier otro. Cada celda es convexa (intersección de los semiplanos de las mediatrices). El
diagrama tiene como mucho `2n − 5` vértices y `3n − 6` aristas: es lineal.

**Triangulación de Delaunay.** El **dual** de Voronoi: une dos sitios si sus celdas comparten una arista.
Caracterización: es la única triangulación (con puntos en posición general) en la que el **círculo
circunscrito** de cada triángulo no contiene ningún otro punto. Entre todas las triangulaciones, maximiza el
menor ángulo: evita triángulos muy finos.

**Lo que contiene Delaunay.** El árbol de expansión mínima euclídeo y el grafo de vecinos más cercanos son
subgrafos de Delaunay, que tiene `O(n)` aristas: el árbol mínimo de `n` puntos sale en `O(n log n)` en lugar
de sobre los `n²/2` pares.

**3D.** El producto cruz de dos vectores de `ℝ³` es un vector perpendicular a ambos; el **producto mixto**
`(b − a) · ((c − a) × (d − a))` es el determinante `3 × 3`, seis veces el volumen con signo del tetraedro
`abcd`: su signo dice a qué lado del plano `abc` está `d`, y si es 0, los cuatro son coplanares.

---

## 3. 🧱 Semiplanos

**Qué resuelve.** La región común a `n` restricciones lineales en el plano: el núcleo de un polígono (desde
dónde se ve todo), la zona factible de un programa lineal de dos variables, la intersección de polígonos
convexos.

**Qué garantiza.** El algoritmo de ordenar las rectas por ángulo y mantener una *deque* con las útiles da el
polígono en `O(n log n)`. La programación lineal en dos variables tiene además un algoritmo aleatorizado de
tiempo esperado `O(n)` (de Berg, cap. 4).

**Cuánto.** `O(n log n)`.

**Cómo reconocerlo.** «Todas las restricciones a la vez», «desde dónde se ven todas las paredes», «el área
común de varios polígonos convexos», «el punto más profundo».

**Si no te la sabes.** Empezar con una caja muy grande y **recortarla** por cada semiplano: cada recorte es
`O(k)` sobre el polígono actual, `O(n²)` en total. Con `n ≤ 3 000`, entra. Los cortes se calculan con el punto
de intersección de [`18/02`](02-rectas-y-segmentos.md).

**Dónde está entera.** de Berg y otros, cap. 4; cp-algorithms, *Half-plane intersection*.

---

## 4. 🧱 Delaunay y Voronoi

**Qué resuelve.** Vecino más cercano de cada punto, árbol de expansión mínima euclídeo, el punto más alejado
de todos los sitios (el centro del mayor círculo vacío está en un vértice de Voronoi), mallas de triángulos
bien formados, interpolación espacial.

**Qué garantiza.** Delaunay en `O(n log n)` (divide y vencerás, o incremental aleatorizado en tiempo
esperado); Voronoi en `O(n log n)` con el barrido de Fortune; cada uno se obtiene del otro en lineal. Con
puntos cocirculares, la triangulación no es única.

**Cuánto.** `O(n log n)`, con constantes altas y mucha sensibilidad a la precisión: el test del círculo es un
determinante `4 × 4` con términos de grado 4 en las coordenadas (`10⁹` → `10³⁶`, fuera de 64 bits).

**Cómo reconocerlo.** «Para cada punto, el más cercano» con `10⁵`; «conectar todas las antenas con cable mínimo»
con coordenadas en el plano; «el lugar más lejos de todas las fábricas».

**Si no te la sabes.** Para el vecino más cercano, una rejilla o un *k-d tree*; para el árbol mínimo con
`n ≤ 5 000`, Prim sobre el grafo completo en `O(n²)`
([`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)), sin construir las aristas.

**Dónde está entera.** de Berg y otros, cap. 7 (Voronoi) y cap. 9 (Delaunay); cp-algorithms, *Delaunay
triangulation and Voronoi diagram*.

---

## 5. 🧱 3D

**Qué resuelve.** Orientación respecto a un plano, coplanaridad, volumen de un tetraedro o de un poliedro,
envolvente convexa en el espacio, distancias en una esfera.

**Qué garantiza.** El producto mixto en enteros es exacto: con coordenadas de `10⁶`, los términos son de
`10¹⁸`, en el límite de 64 bits; con `10⁹`, hace falta `__int128`. La envolvente convexa 3D tiene `O(n)`
caras y se construye en `O(n log n)` (incremental aleatorizado, esperado) o en `O(n²)` con el incremental
simple.

**Cuánto.** `O(1)` el producto mixto; `O(n log n)` o `O(n²)` la envolvente.

**Cómo reconocerlo.** Coordenadas con tres números; «¿están en el mismo plano?»; «volumen»; «la menor esfera
o el menor cilindro que contiene los puntos»; distancias sobre la superficie de la Tierra (ortodrómica).

**Si no te la sabes.** Para la envolvente 3D con `n ≤ 100`: para cada trío de puntos, comprobar si todos los
demás quedan del mismo lado de su plano (`O(n⁴) = 10⁸`). Para la esfera, la distancia ortodrómica es
`R · arccos(u · v)` con `u` y `v` unitarios.

**Dónde está entera.** de Berg y otros, cap. 11 (envolvente 3D); O'Rourke, cap. 4.

---

## 6. 🧭 Cómo se elige

```text
¿Región que cumple todas las restricciones lineales? → semiplanos · n ≤ 3 000: recortar una caja
¿Quién está más cerca de quién, con 10⁵ puntos? → Delaunay / Voronoi · si no: rejilla o k-d tree
¿Árbol mínimo de puntos del plano? → n ≤ 5 000: Prim O(n²) · si no: Delaunay + Kruskal
¿Tres coordenadas? → producto mixto en enteros · envolvente 3D: n ≤ 100 por tríos
```

> **Regla de entrevista:** si aparecen, nómbralos con su garantía («Delaunay tiene `O(n)` aristas y contiene
> el árbol mínimo euclídeo», «semiplanos en `n log n`») y ofrece la alternativa que sí escribirías.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Zona desde la que se ve todo el polígono» | Semiplanos (núcleo) | Izquierda de cada lado |
| «Cada casa al hospital más cercano», `10⁵` | Voronoi | Celdas de cercanía |
| «Cable mínimo entre antenas del plano», `10⁵` | Delaunay + Kruskal | El árbol mínimo está en Delaunay |
| «Punto lo más lejos posible de todas las fábricas» | Vértices de Voronoi | Centro del mayor círculo vacío |
| Coordenadas `(x, y, z)` y «mismo plano» | Producto mixto | Determinante `3 × 3` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Voronoi es solo para mapas» | Es la estructura de «quién está más cerca»: vecinos, árbol mínimo, círculo vacío, mallas |
| «Delaunay tiene `Θ(n²)` aristas, como el grafo completo» | Es planar: `O(n)` aristas |
| «La intersección de semiplanos puede ser cualquier polígono» | Es siempre convexa (o vacía, o no acotada) |
| «El test del círculo cabe en 64 bits como el producto cruz» | Tiene términos de grado 4: con coordenadas de `10⁹`, `10³⁶` |
| «En 3D la orientación se hace con el producto cruz» | Con el producto mixto: un determinante `3 × 3` |
| «La envolvente 3D es tan simple como la 2D» | Tiene caras, no una cadena; el incremental correcto es largo |

---

## 📚 Para profundizar

- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), caps. 4 (semiplanos y programación lineal), 7 (Voronoi), 9 (Delaunay) y 11 (envolvente 3D).
  *Lectura troncal.*
- **Libro** — O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), caps. 4 y 5: envolvente
  3D y Voronoi, con código.
- **Referencia** — cp-algorithms, [*Half-plane intersection*](https://cp-algorithms.com/geometry/halfplane-intersection.html).
  *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Delaunay triangulation and Voronoi diagram*](https://cp-algorithms.com/geometry/delaunay.html).
  *Lectura troncal.*

---

## 🧠 Preguntas

1. ¿Qué forma tiene la intersección de `n` semiplanos? 🟢
2. ¿Qué es el diagrama de Voronoi de un conjunto de puntos? 🟢
3. ¿Qué relación hay entre la triangulación de Delaunay y el diagrama de Voronoi? 🟢
4. ¿Cuánto cuestan la intersección de semiplanos y la triangulación de Delaunay? 🟡
5. ¿Qué propiedad del círculo circunscrito caracteriza a Delaunay? 🟡
6. ¿Qué calcula el producto mixto de tres vectores de `ℝ³` y qué dice su signo? 🟡
7. ¿Por qué el árbol de expansión mínima euclídeo cabe en Delaunay, y qué se gana con eso? 🟠
8. ¿Qué escribirías para la intersección de semiplanos con `n ≤ 3 000`, y cuánto cuesta? 🟠
9. ¿Cuántos vértices y aristas tiene, como mucho, el diagrama de Voronoi de `n` puntos? 🟠
10. «Voronoi es solo para mapas.» ¿Qué respondes? 🟠
11. Demuestra que el vecino más cercano de cada punto es adyacente a él en la triangulación de Delaunay. 🔴
12. Diseña cómo decidir si un punto está dentro de un poliedro convexo dado por sus caras, y di el coste. 🔴

---

## 🧩 Problemas propios

### La zona segura

**Nivel:** 🟠 · **Formato:** programa completo.

Una zona del plano está definida por `n` restricciones. Cada una es una recta dirigida, dada por dos puntos
`a` y `b`, y la zona tiene que quedar a la **izquierda** de la recta (o sobre ella), mirando de `a` a `b`.
Imprime el área de la zona con 6 decimales, o `0.000000` si es vacía.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `xa ya xb yb`, con `a ≠ b`. Se garantiza que la zona
  está acotada o vacía.
- **Salida.** Un real. Se aceptan errores de hasta `10⁻⁶`.
- **Restricciones.** `3 ≤ n ≤ 300`; coordenadas enteras con `|·| ≤ 10⁴`.

```text
Entrada         Salida
5               10.000000
0 0 4 0
4 0 4 3
4 3 0 3
0 3 0 0
5 0 0 5

Entrada         Salida
4               3.000000
0 0 4 0
0 3 0 0
4 3 0 3
1 0 1 5
```

**Pista 1:** si empiezas con un cuadrado enorme que seguro contiene la zona, ¿qué le hace cada restricción, y
cuánto cuesta aplicarla?

### Volumen del tetraedro

**Nivel:** 🟢 · **Formato:** programa completo.

Para cada consulta de cuatro puntos del espacio, imprime **seis veces** el volumen del tetraedro que forman
(un entero), o `0` si son coplanares.

- **Entrada.** Una línea con `q`. Después, `q` líneas con doce enteros: las coordenadas de los cuatro puntos.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ q ≤ 10⁵`; coordenadas con `|·| ≤ 10⁵`.

```text
Entrada                                 Salida
3                                       1
0 0 0 1 0 0 0 1 0 0 0 1                 60
0 0 0 4 0 0 4 3 0 0 3 5                 0
0 0 0 1 1 1 2 2 2 3 0 1

Entrada                                 Salida
1                                       1000000000000000
0 0 0 0 100000 0 100000 0 0 0 0 100000
```

**Pista 1:** en el plano, el doble del área de un triángulo es un determinante `2 × 2` de dos lados. ¿Qué
determinante da, en el espacio, seis veces el volumen?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de lanzarte a una de estas estructuras, comprueba si la alternativa cuadrática (recortar
> una caja, Prim sobre todos los pares, tríos en 3D) entra en el tiempo. Una IA puede ayudarte a hacer esa
> cuenta; pídele eso, no la estructura ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).
> SPOJ no se enlaza (`403`).

Las bases no tienen problemas de estas técnicas; todo es 💀, por curiosidad.

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Airline Hub](https://open.kattis.com/problems/airlinehub) | Kattis | 🟠 | Distancias en la esfera | ¿Cómo pasas de latitud y longitud a un vector de `ℝ³`, y qué te da el producto punto de dos de ellos? |
| [ ] | 💀 [Asteroids](https://open.kattis.com/problems/asteroids) | Kattis | 🔴 | Intersección de convexos | El área común de dos polígonos convexos es una intersección de semiplanos: ¿cómo depende del instante? |
| [ ] | 💀 [Euclidean MST](https://judge.yosupo.jp/problem/euclidean_mst) | Library Checker | 🔴 | Delaunay + Kruskal | Con `2·10⁵` puntos no puedes generar todos los pares: ¿qué grafo de `O(n)` aristas contiene el árbol? |
| [ ] | 💀 [Stars in a Can](https://open.kattis.com/problems/starsinacan) | Kattis | 🔴 | Envolvente 3D | ¿Sobre qué caras de la envolvente puede apoyarse la base del cilindro mínimo? |

---

## ✅ Criterio de dominio

- Explicar qué es la intersección de semiplanos y escribir de palabra la alternativa de recortar una caja.
- Explicar Voronoi, Delaunay, su dualidad y qué contiene Delaunay.
- Calcular un producto mixto a mano y decir qué significa su signo.
- Resolver La zona segura y Volumen del tetraedro con las alternativas que sí se escriben.

---

**Anterior:** [`18/05` — Barrido geométrico](05-barrido-geometrico.md) · **Siguiente:** [`18/07` — Simulación](07-simulacion.md) ·
**Relacionado:** [`15/04` — Árbol de expansión mínima](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md).
