# 05 — Estructuras espaciales

> Estructuras para preguntar por la posición: qué puntos caen en un rectángulo y cuál es el más cercano a uno
> dado. El árbol k-d parte el espacio alternando ejes y responde rangos en `O(√n + k)` en el plano; la búsqueda
> del vecino más cercano poda las ramas que no pueden mejorar. Y el límite de todo esto: en muchas dimensiones,
> la poda deja de funcionar. El R-tree, el de las bases de datos, como ficha.
>
> **Niveles:** árbol k-d [C] · vecino más cercano [C].
>
> **📚 Lectura troncal:** de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed.
> (Springer, 2008), cap. 5; La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), cap. 9;
> Kubica, *Data Structures the Fun Way* (No Starch, 2022), cap. 9.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--árbol-k-d) · [4](#4--vecino-más-cercano) · [5](#5--r-tree) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Una aplicación de transporte tiene un millón de conductores en el mapa. Cuando alguien pide un coche, hay que
encontrar el conductor más cercano; cuando alguien mueve el mapa, hay que dibujar todos los restaurantes del
rectángulo visible. Recorrer el millón de puntos en cada consulta funciona, y no escala con miles de
consultas por segundo.

En una dimensión el problema está resuelto: ordenar y búsqueda binaria. En dos, ordenar por `x` no dice nada
de `y`. Las estructuras espaciales parten el plano en regiones, de forma que una consulta solo visita las
regiones que tocan lo que pregunta.

> 🧠 **Modelo mental.** Un árbol k-d es una búsqueda binaria que alterna de eje en cada nivel: primero parte por
> `x`, después cada mitad por `y`, después por `x`… Cada nodo es un rectángulo del plano, y una consulta
> desciende solo por los rectángulos que le importan.

---

## 2. 📐 La teoría

**Árbol k-d.** En `d` dimensiones, cada nodo parte su región por la mediana de una coordenada, que cambia de
nivel en nivel (`x`, `y`, `x`, …). Con `n` puntos, la altura es `⌈log₂ n⌉` y se construye en `O(n log n)`.

**Consulta de rango ortogonal.** Contar o listar los puntos de un rectángulo alineado: `O(√n + k)` en el plano,
con `k` el tamaño de la respuesta. *Por qué √n:* una recta vertical corta como mucho `O(√n)` regiones del
árbol, porque cada dos niveles hay que bajar por dos de los cuatro nietos: `Q(n) = 2Q(n/4) + O(1) = O(√n)`. En
`d` dimensiones, `O(n^{1 − 1/d} + k)`.

**Árbol de rangos.** La alternativa con mejor consulta: `O(log² n + k)` en el plano (o `O(log n + k)` con
*fractional cascading*), a cambio de `O(n log n)` memoria. Es un BST por `x` cuyos nodos guardan, cada uno, su
subconjunto ordenado por `y`.

**Vecino más cercano.** Se baja hasta la hoja que contendría el punto, y al volver se visita la otra rama solo
si la distancia del punto a su región es menor que la mejor encontrada. Con puntos bien repartidos en pocas
dimensiones, `O(log n)` esperado; en el peor caso, `O(n)`.

**La maldición de la dimensión.** En muchas dimensiones, las distancias entre puntos al azar se concentran:
casi todas parecen iguales, y la región de búsqueda corta casi todas las regiones. La poda deja de servir
cuando `n` no es mucho mayor que `2^d`: con `d = 20`, haría falta bastante más de un millón de puntos para que
el árbol gane a recorrerlos todos.

---

## 3. 🧱 Árbol k-d

**Qué resuelve.** Consultas de rango ortogonal (los puntos dentro de un rectángulo o una caja) y de vecino más
cercano sobre puntos estáticos en pocas dimensiones.

**Qué garantiza.** Construcción `O(n log n)`, memoria `O(n)`, rango `O(n^{1 − 1/d} + k)`: `O(√n + k)` en el
plano. Con los puntos de juguete `(0,0) (4,0) (4,3) (0,3) (2,1)`, la raíz parte por la mediana de `x` (2), cada
mitad por `y`, y el rectángulo `[1, 4] × [0, 3]` devuelve `(2,1)`, `(4,0)` y `(4,3)`.

**Cuánto.** Lo de arriba. Insertar y borrar desequilibran el árbol; se reconstruye de vez en cuando.

**Cómo reconocerlo.** «Puntos dentro de un rectángulo» con muchas consultas en línea; «el más cercano» con
puntos fijos y consultas que llegan; coordenadas en 2 o 3 dimensiones.

**Si no te la sabes.** Si las consultas se conocen de antemano, **fuera de línea**: barrido por `x` y un
Fenwick sobre `y` cuenta los puntos de cada rectángulo en `O((n + q) log n)`
([`18/05`](../18-geometria/05-barrido-geometrico.md), [`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)).
En línea, una rejilla de celdas si los puntos están repartidos.

**Dónde está entera.** de Berg y otros, cap. 5; La Rocca, cap. 9; Kubica, cap. 9.

---

## 4. 🧱 Vecino más cercano

**Qué resuelve.** Dado un conjunto fijo de puntos, responder para cada consulta cuál está más cerca (o los `k`
más cercanos).

**Qué garantiza.** Con un árbol k-d en pocas dimensiones y puntos bien repartidos, `O(log n)` esperado por
consulta; en el peor caso, `O(n)`. En el plano hay garantías de peor caso con el diagrama de Voronoi y
localización de puntos (`O(log n)`, [`18/06`](../18-geometria/06-geometria-avanzada.md)). En dimensiones
altas, solo los métodos **aproximados** (LSH, grafos de proximidad) escalan.

**Cuánto.** Construcción `O(n log n)`; consulta según lo de arriba.

**Cómo reconocerlo.** «El conductor más cercano», «el cajero más cercano a cada cliente», «los `k` productos
más parecidos» (en un espacio de características, donde entra la maldición de la dimensión).

**Si no te la sabes.** Una rejilla de celdas del tamaño típico de la respuesta (como en el par más cercano de
`18/05`); con pocas consultas, recorrer todos los puntos.

**Dónde está entera.** La Rocca, caps. 8 y 9; de Berg y otros, cap. 5 (notas).

---

## 5. 🧱 R-tree

**Qué resuelve.** Índices espaciales en disco para rectángulos y objetos con extensión (parcelas, carreteras,
polígonos), con inserciones y borrados.

**Qué garantiza.** Un árbol equilibrado, como un árbol B: cada nodo guarda hasta `M` cajas que contienen a sus
hijos, y el árbol se mantiene con divisiones al insertar. Las cajas de hermanos pueden solaparse, así que una
consulta puede bajar por varias ramas: sin cota de peor caso buena, muy rápido en la práctica.

**Cuánto.** `O(log_M n)` niveles; las consultas dependen del solapamiento entre cajas.

**Cómo reconocerlo.** «Índice espacial de una base de datos», «qué parcelas toca este polígono», datos que no
caben en memoria.

**Si no te la sabes.** Una rejilla de celdas con listas de objetos por celda (lo que hacen muchos motores de
juegos), o un árbol k-d si los objetos son puntos y caben en memoria.

**Dónde está entera.** La Rocca, cap. 10; Guttman, «R-trees: a dynamic index structure for spatial searching»,
*SIGMOD* (1984).

---

## 6. 🧭 Cómo se elige

```text
¿Consultas conocidas de antemano? → fuera de línea: barrido + Fenwick (rango) o Voronoi (vecino)
¿En línea, pocas dimensiones, puntos estáticos? → árbol k-d (o árbol de rangos si la consulta manda)
¿Objetos con extensión, en disco, con inserciones? → R-tree
¿Muchas dimensiones (d ≳ 10–20)? → vecino aproximado (LSH, grafos), no k-d
```

> **Regla de entrevista:** si te preguntan por «el más cercano» en un servicio, nombra el árbol k-d (o el
> índice espacial de la base de datos) y la maldición de la dimensión en la misma frase.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Puntos dentro de un rectángulo», muchas consultas en línea | Árbol k-d o de rangos | `O(√n + k)` o `O(log² n + k)` |
| Las mismas consultas, conocidas de antemano | Barrido + Fenwick | `O((n + q) log n)` |
| «El más cercano» con puntos fijos | Árbol k-d | Poda por distancia a la región |
| Vectores de 100 o más dimensiones | Vecino aproximado | El k-d degenera |
| «Índice espacial de una base de datos» | R-tree | En disco, con inserciones |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El árbol k-d escala a cualquier dimensión» | En dimensiones altas la poda no sirve: hace falta `n ≫ 2^d` |
| «Una consulta de rango en un k-d es `O(log n + k)`» | Es `O(√n + k)` en el plano; `O(log n)` es la altura, no la consulta |
| «El vecino más cercano en un k-d es siempre `O(log n)`» | Esperado con puntos bien repartidos; el peor caso es `O(n)` |
| «El R-tree garantiza consultas logarítmicas» | Sus cajas se solapan: la consulta puede bajar por varias ramas |
| «Para el rectángulo basta ordenar por `x`» | Ordenar por `x` no dice nada de `y`: hace falta partir los dos ejes |
| «Más dimensiones solo cambian la constante» | Cambian el exponente: `O(n^{1 − 1/d})` se acerca a `O(n)` |

---

## 📚 Para profundizar

- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), cap. 5: árboles k-d y de rangos, con las cotas. *Lectura troncal.*
- **Libro** — La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), caps. 8–10: vecino más
  cercano, árboles k-d, R-trees y SS-trees. *Lectura troncal.*
- **Libro** — Kubica, *Data Structures the Fun Way* (No Starch, 2022), cap. 9: árboles espaciales.
  *Lectura troncal.*
- **Artículo** — Bentley, «Multidimensional binary search trees used for associative searching»,
  *Communications of the ACM* 18(9), 1975.

---

## 🧠 Preguntas

1. ¿Cómo se construye un árbol k-d? 🟢
2. ¿Cuánto cuesta una consulta de rango ortogonal en un árbol k-d del plano? 🟢
3. ¿Qué es un R-tree y dónde se usa? 🟢
4. ¿Qué diferencia hay entre un árbol k-d y un árbol de rangos? 🟡
5. ¿Cómo poda la búsqueda del vecino más cercano en un árbol k-d? 🟡
6. ¿Qué es la maldición de la dimensión? 🟡
7. ¿Por qué una consulta de rango en el plano visita `O(√n)` regiones? 🟠
8. ¿Qué harías si las consultas de rango se conocen todas de antemano? 🟠
9. ¿Por qué el R-tree no tiene una buena cota de peor caso? 🟠
10. ¿Qué usarías para el vecino más cercano en vectores de 512 dimensiones, y qué pierdes? 🟠
11. Deduce la recurrencia `Q(n) = 2Q(n/4) + O(1)` del árbol k-d y resuélvela. 🔴
12. Diseña el servicio que encuentra el conductor más cercano entre un millón que se mueven cada pocos
    segundos. 🔴

---

## 🧩 Problemas propios

### La antena más cercana

**Nivel:** 🟠 · **Formato:** programa completo.

Hay `n` antenas y `q` casas. Para cada casa, imprime el cuadrado de la distancia a la antena más cercana.

- **Entrada.** Una línea con `n` y `q`. Después, `n` líneas con las antenas y `q` líneas con las casas.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 10⁵`; coordenadas enteras entre `0` y `10⁶`, generadas al azar de forma
  uniforme.

```text
Entrada          Salida
5 4              5
0 0              2
4 0              1
4 3              1
0 3
2 1
5 5
1 2
3 0
2 2

Entrada          Salida
1 2              0
0 0              2000000000000
0 0
1000000 1000000
```

**Pista 1:** con los puntos repartidos al azar, ¿cuántas antenas hay, en promedio, en un cuadrado del tamaño de
la distancia típica a la más cercana?

### Restaurantes en la pantalla

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` restaurantes en el mapa. Para cada rectángulo de pantalla `[x₁, x₂] × [y₁, y₂]` (bordes incluidos),
imprime cuántos restaurantes se ven.

- **Entrada.** Una línea con `n` y `q`. Después, `n` líneas con los restaurantes y `q` líneas con
  `x₁ y₁ x₂ y₂`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; coordenadas enteras con `|·| ≤ 10⁹`.

```text
Entrada                                        Salida
5 3                                            2
0 0                                            3
4 0                                            0
4 3
0 3
2 1
0 0 2 1
1 0 4 3
5 5 6 6

Entrada                                        Salida
2 1                                            2
-1000000000 1000000000
-1000000000 1000000000
-1000000000 1000000000 -1000000000 1000000000
```

**Pista 1:** si conoces todas las pantallas antes de responder, ¿puedes escribir la cuenta de un rectángulo como
combinación de cuentas de «esquinas» del tipo `x ≤ X, y ≤ Y`?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de escribir un árbol k-d en un juez, mira si las consultas se pueden responder fuera de
> línea o con una rejilla: casi siempre sí. Si una IA te ayuda, que sea a comparar esas alternativas, no a
> escribir el árbol ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

Las bases no tienen problemas de estas estructuras; lo que sale en concursos se resuelve casi siempre fuera de
línea. Todo es 💀, por curiosidad.

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Cell Towers](https://open.kattis.com/problems/celltowers) | Kattis | 🟠 | Vecino más cercano en cada marca | ¿Cuántas marcas y cuántas torres hay, y te alcanza con comparar cada marca con todas? |

---

## ✅ Criterio de dominio

- Explicar cómo se construye un árbol k-d y por qué una consulta de rango cuesta `O(√n + k)`.
- Explicar la poda del vecino más cercano y la maldición de la dimensión.
- Decir cuándo un R-tree, cuándo un k-d, y cuándo fuera de línea.
- Resolver La antena más cercana y Restaurantes en la pantalla.

---

**Anterior:** [`19/04` — Muestreo y cadenas de Markov](04-muestreo-y-markov.md) · **Siguiente:** [`19/06` — Datos masivos](06-datos-masivos.md) ·
**Relacionado:** [`18/05` — Barrido geométrico](../18-geometria/05-barrido-geometrico.md).
