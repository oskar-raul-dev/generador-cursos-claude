# 04 — Matroides y cómo romper un voraz

> La estructura que garantiza que un voraz es óptimo para cualquier función de pesos —la matroide, con el
> teorema de Rado-Edmonds— y el oficio contrario: fabricar contraejemplos a un voraz con método, porque no
> encontrar uno no prueba nada.
>
> **Niveles:** matroides [C] · contraejemplos [A].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §16.4; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 6.
>
> **Asume leído:** [`11/01` — Cuándo funciona un voraz](01-cuando-funciona-un-voraz.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--matroides) · [4](#4--contraejemplos) · [5](#5--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un voraz para el máximo de reuniones disjuntas que parece razonable: **elegir la reunión que choca con
menos otras**, quitar las que chocan con ella y repetir. Deja libres muchas reuniones a la vez, y en los
ejemplos que uno prueba a mano funciona. Es incorrecto. El contraejemplo más pequeño que encontró una
búsqueda aleatoria de este capítulo tiene **diez intervalos**, y hicieron falta miles de intentos para
dar con él:

```text
[0,2) [1,2) [1,3) [1,4) [2,5) [4,6) [5,8) [6,9) [7,10) [8,9)
«el que menos choca» (desempatando por final) → 3 reuniones · por final → 4
```

Ningún ejemplo de enunciado, y casi ningún caso a mano, tiene ese tamaño y esa forma. Por eso «no encontré
contraejemplo» no significa nada si se buscó a mano. Este capítulo trae las dos caras: la estructura que
**garantiza** que un voraz funciona —la matroide— y el método que **encuentra** el contraejemplo cuando no
funciona.

> 🧠 **Modelo mental.** Ante un voraz, la carga de la prueba es tuya. O lo demuestras (intercambio, «se
> adelanta», matroide), o lo atacas con una fuerza bruta y miles de casos pequeños. Probar tres ejemplos
> a mano no es ninguna de las dos.

---

## 2. 📐 La teoría

**Matroide.** Un par `(S, I)` con `S` un conjunto finito e `I` una familia de subconjuntos de `S` (los
**independientes**) que cumple:

```text
1. Hereditaria:  si B ∈ I y A ⊆ B, entonces A ∈ I        (∅ es independiente)
2. Intercambio:  si A, B ∈ I y |A| < |B|, existe x ∈ B \ A con A ∪ {x} ∈ I
```

La segunda propiedad dice que todo independiente se puede ampliar con algo de uno mayor; de ella sale
que todos los independientes maximales (las **bases**) tienen el mismo tamaño.

**Teorema (Rado-Edmonds).** Sea `(S, I)` hereditario. El voraz que recorre `S` por peso decreciente y
añade cada elemento si el conjunto sigue siendo independiente da un independiente de **peso máximo para
toda función de pesos no negativos** si y solo si `(S, I)` es una matroide.

La ida es la que se usa: si el problema es una matroide, el voraz es correcto sin más prueba. La vuelta es
la que explica los fracasos: si el voraz es correcto para cualquier peso, hay una matroide detrás; si no la
hay, existe algún peso que lo rompe.

**Las matroides que más aparecen:**

| Matroide | Independientes | Voraz que la usa |
|---|---|---|
| Gráfica | Conjuntos de aristas sin ciclos (bosques) | Kruskal ([`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)), con Union-Find (`08/04`) |
| De planificación | Conjuntos de tareas unitarias que caben antes de sus plazos | Plazos de [`11/03`](03-plazos-huffman-y-monedas.md) |
| Uniforme | Conjuntos de tamaño `≤ k` | «Los `k` mayores» |
| Lineal | Vectores linealmente independientes | Base de peso máximo (base XOR, [`17/07`](../17-matematica/07-matrices-y-gauss.md)) |

**Lo que no es matroide**, y por eso el voraz falla: los conjuntos de intervalos disjuntos (la propiedad de
intercambio falla), los subconjuntos que caben en una mochila 0/1, los emparejamientos de un grafo (que son
intersección de dos matroides y piden otra técnica, [`15/06`](../15-grafos-pesos-y-flujos/06-emparejamientos.md)).

---

## 3. 🧱 Matroides

### La matroide y el voraz genérico

**Qué resuelve.** Decide de una vez si un voraz «por peso decreciente, si sigue siendo independiente» es
correcto: lo es exactamente cuando los conjuntos factibles forman una matroide.

**Qué garantiza.** El teorema de Rado-Edmonds de §2: con una matroide, el voraz da el independiente de peso
máximo para cualquier peso; sin matroide, hay pesos que lo rompen.

**Cuánto.** Ordenar, `Θ(n log n)`, más `n` consultas de independencia. El coste real está en esa consulta:
en la matroide gráfica, Union-Find (`O(α(n))`); en la de planificación, el montículo de `11/03`; en la
lineal, una eliminación gaussiana incremental (`O(bits)` por vector en la base XOR).

**Cómo reconocerlo.** El enunciado pide «el subconjunto de peso máximo» con una restricción de
«independencia» que es hereditaria (quitar elementos nunca la rompe) y en la que **todos los conjuntos
maximales tienen el mismo tamaño**. Si dos soluciones maximales pueden tener tamaños distintos, no es una
matroide y el voraz por peso es sospechoso.

**Si no te la sabes.** Demuestra el voraz concreto con intercambio (`11/01`); la matroide es la versión
abstracta de esa misma prueba.

**Dónde está entera.** CLRS, §16.4 (matroides y el teorema) y §16.5 (la matroide de planificación); Kruskal
como voraz sobre la matroide gráfica en CLRS, cap. 23.

---

## 4. 🧱 Contraejemplos

**Qué es.** Un método para refutar un voraz antes de demostrarlo: escribir una fuerza bruta correcta,
generar muchas entradas **muy pequeñas** al azar y comparar, y cuando aparece una diferencia,
**minimizarla** a mano.

**Por qué es correcto.** Un voraz es correcto si coincide con el óptimo en **todas** las entradas; una sola
diferencia lo refuta. La fuerza bruta es el oráculo (`01/05`), y las entradas pequeñas son las más
probables de contener el patrón que lo rompe, porque hay muchas menos combinaciones que explorar y el caso
encontrado se puede leer.

```text
1. Escribe el voraz y una fuerza bruta (exhaustiva) sobre n ≤ 8.
2. Genera entradas con n entre 1 y 8 y valores entre 0 y 5. Muchas: 10⁴–10⁶.
3. Para la primera diferencia, quita elementos y baja valores mientras siga fallando.
4. Lee el caso mínimo: dice qué hipótesis faltaba.
5. Si en 10⁶ casos no aparece nada, ahora sí: busca la prueba.
```

**Cómo va**, la mochila 0/1 con el voraz por razón valor/peso:

```text
caso aleatorio que falla:    W = 10, objetos (5,10) (2,3) (9,14) (1,2) (5,8) (6,9) → voraz 15, óptimo 18
quitando objetos:            W = 10, (6,9) (5,7) (5,7)                           → voraz 9,  óptimo 14
qué dice el caso mínimo:     el objeto de mejor razón deja un hueco que no se aprovecha;
                             con objetos enteros, la razón no basta
```

**Cuánto.** El arnés corre en segundos para `n ≤ 8`. Si el voraz es incorrecto, los contraejemplos suelen
salir en los primeros miles de casos; el del capítulo, con diez intervalos, es la excepción que justifica
generar muchos y con `n` algo mayor.

**La plantilla.** No hay plantilla nueva, como fija la ficha: el arnés es el *stress test* de
[`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md) con el voraz en el papel de «solución rápida» y la fuerza bruta de oráculo.

### De la versión ingenua a la buena

**El problema.** Decidir si el voraz «la reunión que menos choca primero» da el máximo de reuniones
disjuntas.

**La versión ingenua**: probar a mano unos cuantos ejemplos y, si todos salen bien, darlo por bueno.

```java
// La «comprobación» de siempre: tres ejemplos a mano del voraz fewestConflicts. Todos pasan. No prueba nada.
static void manualCheck() {
    assert fewestConflicts(new int[][]{{1,4},{3,5},{5,7}}) == 2;
    assert fewestConflicts(new int[][]{{0,10},{1,2},{3,4}}) == 2;
    assert fewestConflicts(new int[][]{{0,5},{4,6},{5,10}}) == 2;
}
```

> «Tres ejemplos que pasan no prueban nada: este voraz tiene un contraejemplo, pero necesita diez
> intervalos con una forma concreta. Escribo la selección por final, que sé que es óptima, como oráculo; genero
> miles de conjuntos aleatorios pequeños y comparo. Si aparece una diferencia, el voraz está muerto.»

**El camino a la buena.** El arnés de `01/05` con `fewestConflicts` contra `maxDisjoint` de
[`11/02`](02-intervalos.md), con `n` entre 3 y 12, inicios entre 0 y 8 y duraciones entre 1 y 3. Encuentra el
caso de §1.

**Cuándo sí**: siempre, antes de demostrar un voraz nuevo; y como diagnóstico ante un WA de un voraz.
**Cuándo no**: si la fuerza bruta no se puede escribir (no hay oráculo), o si el voraz ya es una instancia de
un resultado conocido (Kruskal, Huffman, selección por final).

> **Veredicto:** no encontrar contraejemplo a mano no es evidencia. Con un oráculo y un generador, diez
> minutos de búsqueda valen más que una hora de intuición.

---

## 5. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Subconjunto de peso máximo» sin ciclos, independiente, que cabe en plazos | Voraz sobre una matroide | Rado-Edmonds |
| Las soluciones maximales pueden tener tamaños distintos | Sospecha del voraz | No es matroide |
| Te encuentras dudando entre dos reglas voraces | Arnés de contraejemplos | Que decida la fuerza bruta |
| `n ≤ 20` en un problema que «parece» voraz | Probablemente no lo es | El autor espera exhaustiva o DP |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si no encuentro contraejemplo, el voraz es correcto» | Si no lo encuentro **con una búsqueda sistemática**, toca buscar la prueba; a mano no cuenta |
| «Todo voraz correcto es una matroide» | Rado-Edmonds habla del voraz por pesos sobre independientes; la selección por final es correcta sin matroide |
| «Los intervalos disjuntos son una matroide» | No: falla el intercambio; por eso el voraz **por peso** falla con intervalos con pesos |
| «Kruskal funciona por intuición» | Funciona porque los bosques son una matroide |
| «Para buscar contraejemplos, entradas grandes» | Pequeñas: hay más probabilidad por caso y se pueden leer |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §16.4 y §16.5: matroides, el teorema y la planificación como matroide. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 6: los voraces
  sobre grafos y la planificación. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), cap. 4: los voraces falsos de
  la selección de intervalos, con sus contraejemplos dibujados.
- **Libro** — Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 5: andamiaje y pruebas
  contra un oráculo.

---

## 🧠 Preguntas

1. ¿Qué dos propiedades definen una matroide? 🟢
2. ¿Qué dice el teorema de Rado-Edmonds? 🟢
3. ¿Qué pasos tiene el método para buscar un contraejemplo a un voraz? 🟢
4. ¿Por qué Kruskal es un voraz sobre una matroide, y cuál? 🟡
5. ¿Por qué los conjuntos de intervalos disjuntos no son una matroide? Da los dos conjuntos que rompen el intercambio. 🟡
6. ¿Por qué conviene generar entradas pequeñas y no grandes para buscar contraejemplos? 🟡
7. Compara cómo escribirías el generador aleatorio del arnés en C++, Java y Python para que sea reproducible. 🟡
8. ¿Por qué la selección por final es correcta si los intervalos disjuntos no forman una matroide? 🟠
9. ¿Qué dice la propiedad de intercambio sobre el tamaño de las bases, y por qué importa para reconocer una matroide? 🟠
10. Encuentra el contraejemplo mínimo del voraz por razón para la mochila 0/1 y explica qué hipótesis rompe. 🟠
11. ¿Qué técnica usas cuando el problema es la intersección de dos matroides, como el emparejamiento bipartito? 🟠
12. Demuestra que los bosques de un grafo cumplen la propiedad de intercambio. 🔴
13. Tu arnés no encuentra contraejemplo en un millón de casos con `n ≤ 6`, y el voraz da WA en el juez. ¿Qué cambias en la búsqueda? 🔴

---

## 🧩 Problemas propios

### ¿Voraz o no?

**Nivel:** 🟢 · **Formato:** programa completo.

Dada una mochila de capacidad `W` y `n` objetos enteros con peso y valor, imprime el valor del voraz (por
razón valor/peso decreciente, desempatando por el orden de entrada, metiendo cada objeto si cabe), el
valor óptimo, y `IGUAL` o `DISTINTO`.

- **Entrada.** Una línea con `n` y `W`. Después, `n` líneas con `peso valor`.
- **Salida.** Una línea con los dos valores y la palabra.
- **Restricciones.** `1 ≤ n ≤ 15`; `0 ≤ W ≤ 10⁹`; `1 ≤ peso, valor ≤ 10⁹`.

```text
Entrada         Salida
3 10            9 14 DISTINTO
6 9
5 7
5 7

Entrada         Salida
1 3             0 0 IGUAL
4 5
```

**Pista 1:** con `n ≤ 15`, ¿cuántos subconjuntos hay que mirar para el óptimo?

### Monedas contadas

**Nivel:** 🟡 · **Formato:** programa completo.

Tienes `k` tipos de monedas, cada uno con su valor y el número de monedas disponibles. Imprime el menor
número de monedas para pagar exactamente `x`, o `-1` si no se puede.

- **Entrada.** Una línea con `k` y `x`. Después, `k` líneas con `valor cantidad`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ 10`; `1 ≤ valor ≤ 10⁴`; `1 ≤ cantidad ≤ 10`; `1 ≤ x ≤ 10⁴`.

```text
Entrada         Salida
3 6             2
4 1
3 2
1 5

Entrada         Salida
2 7             -1
5 1
3 1
```

**Pista 1:** si usas la moneda más grande mientras quepa, con `6 = 4 + 1 + 1`, ¿es lo mejor?

### Bosque más pesado

**Nivel:** 🟠 · **Formato:** programa completo.

Un grafo no dirigido tiene `n` vértices y `m` aristas con peso (que puede ser negativo). Elige un conjunto
de aristas **sin ciclos** de peso total máximo e imprime ese peso.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con `a b peso`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `0 ≤ m ≤ 2·10⁵`; `|peso| ≤ 10⁹`.

```text
Entrada         Salida
4 5             15
1 2 5
2 3 2
1 3 9
3 4 1
2 4 -3

Entrada         Salida
3 1             0
1 2 -1
```

**Pista 1:** ¿qué estructura tienen los conjuntos de aristas sin ciclos, y qué hace el voraz con las
aristas de peso negativo?

---

## 🧩 Práctica externa

La ficha de este capítulo pide sobre todo problemas propios. La práctica externa es corta y mezcla
problemas donde el voraz tentador **falla** con otros donde **funciona**: el ejercicio es decidir cuál es
cuál antes de escribir, con el arnés si hace falta.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Best Time to Buy and Sell Stock II](https://leetcode.com/problems/best-time-to-buy-and-sell-stock-ii/) | LeetCode | 🟡 | El voraz funciona | ¿Qué ganas sumando cada subida de un día al siguiente? |
| [ ] | [Jump Game](https://leetcode.com/problems/jump-game/) | LeetCode | 🟡 | El voraz funciona | ¿Cuál es el índice más lejano alcanzable hasta ahora? |
| [ ] | [Coin Change](https://leetcode.com/problems/coin-change/) | LeetCode | 🟡 | El voraz falla | ¿Es canónico un sistema de monedas cualquiera? |
| [ ] | [Minimum Cost For Tickets](https://leetcode.com/problems/minimum-cost-for-tickets/) | LeetCode | 🟡 | El voraz falla | ¿Siempre conviene el pase más barato por día? |
| [ ] | [NumberSolitaire](https://app.codility.com/programmers/lessons/17-dynamic_programming/number_solitaire/) | Codility | 🟡 | El voraz falla | ¿Saltar siempre a la mejor casilla de las seis siguientes da el máximo? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [House Robber](https://leetcode.com/problems/house-robber/) | LeetCode | 🟡 | El voraz falla | Si robas la casa más rica, ¿qué pierdes a cada lado? |
| [ ] | [Minimum Number of Refueling Stops](https://leetcode.com/problems/minimum-number-of-refueling-stops/) | LeetCode | 🟠 | El voraz funciona, con arrepentimiento | Si te quedas sin combustible, ¿en cuál de las gasolineras ya pasadas te habría convenido parar? |
| [ ] | [Maximum Profit in Job Scheduling](https://leetcode.com/problems/maximum-profit-in-job-scheduling/) | LeetCode | 🟠 | Intervalos con peso: el voraz falla | Un trabajo largo y valioso, ¿puede valer más que dos cortos? |

---

## ✅ Criterio de dominio

- Enunciar las dos propiedades de una matroide y el teorema de Rado-Edmonds, y nombrar tres matroides con
  su voraz.
- Montar en diez minutos un arnés voraz contra fuerza bruta y minimizar el primer contraejemplo.
- Decidir, antes de escribir, si el voraz de cada problema del núcleo funciona, y defenderlo.
- Resolver Minimum Cost For Tickets sin pista 2, sabiendo por qué el voraz no sirve.

---

**Anterior:** [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas](03-plazos-huffman-y-monedas.md) · **Siguiente:**
[`11/05` — Simulación](05-simulacion.md) · **Relacionado:** [`15/04` — Árbol de expansión mínima](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md); [`08/04` — Union-Find](../08-heaps-y-union-find/04-union-find.md).
