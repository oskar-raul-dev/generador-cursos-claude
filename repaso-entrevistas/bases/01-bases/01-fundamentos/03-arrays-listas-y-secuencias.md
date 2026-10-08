# 03 — Arrays, listas y secuencias

> Por qué el arreglo gana casi siempre aunque la tabla de complejidades diga que no, y las
> cuatro técnicas que resuelven la mayoría de los problemas sobre secuencias: dos punteros,
> ventana deslizante, sumas de prefijos y pila monótona. Reconocerlas es más rentable que
> saberse un algoritmo más.
> Asume leídos [`01` — Complejidad](01-complejidad-y-o-grande.md) y
> [`02` — TDAs](02-tdas-contrato-e-implementacion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Dos programas recorren un millón de enteros y los suman. Uno usa `int[]`, el otro
`LinkedList<Integer>`. Ambos son O(n). El primero tarda **unos 5 ms**, el segundo puede
tardar **más de 50 ms**, y en un montón fragmentado bastante más.

La tabla de complejidades no explica esa diferencia porque **la tabla no modela la memoria**.
Asume que acceder a cualquier posición cuesta lo mismo, y en un procesador de verdad eso es
falso por dos órdenes de magnitud.

Este capítulo trata las dos mitades de ese hecho: **por qué pasa** (secciones 2 a 4) y **qué
técnicas lo aprovechan** (secciones 5 a 8). Las cuatro técnicas de la segunda mitad comparten
una virtud: convierten un algoritmo cuadrático obvio en uno lineal, y las cuatro se reconocen
por la forma del enunciado.

> **Regla de entrevista:** si el enunciado dice "subarreglo contiguo", "par que suma", "el
> siguiente mayor" o "sobre un arreglo ordenado", no estás ante un algoritmo: estás ante una
> de estas cuatro técnicas.

---

## 2. 🧱 El arreglo y la caché

**Qué es.** Un arreglo es un bloque **contiguo** de memoria: el elemento `i` está en
`base + i × tamaño`. De ahí el acceso en O(1), y de ahí todo lo demás.

**Cómo va.** El procesador no lee bytes sueltos: lee **líneas de caché** de 64 bytes. Cuando
pides `datos[0]`, el hardware trae también los 15 enteros siguientes, gratis.

```text
Arreglo:         [5][2][9][1][5][6]        una línea de caché → 16 ints de una vez
Lista enlazada:  [5]→ ... [2]→ ... [9]→    cada nodo, en cualquier parte del montón
```

- En el arreglo, 15 de cada 16 accesos **no tocan la memoria principal**. Eso es el factor 10.
- En la lista, cada `next` es un salto impredecible: el prefetcher no puede adivinarlo y la
  CPU espera.
- En Java hay un agravante: `LinkedList<Integer>` guarda **punteros a objetos `Integer`**, no
  enteros. Son dos saltos por elemento y tres objetos de cabecera por valor.

**Cuánto cuesta.** Nada en complejidad —sigue siendo O(n)— y entre 5 y 10× en tiempo real.
Es el ejemplo canónico de que la constante decide.

**Cuándo sí** usar arreglo: recorrido, acceso por índice, tamaño conocido, rendimiento.

**Cuándo no:** cuando insertas y borras en medio con mucha frecuencia y ya tienes la
referencia al punto, o cuando el elemento es enorme y copiarlo domina.

> 🧠 **Modelo mental.** La complejidad te dice cuántas operaciones. La localidad te dice
> cuánto cuesta cada una. Solo con las dos se predice el tiempo real, y es la respuesta que
> separa a quien ha perfilado código de quien ha leído sobre él.

---

## 3. 🧱 El arreglo dinámico

**Qué es.** La estructura detrás de `ArrayList`, `list` de Python, `Array` de JavaScript y
`slice` de Go: un arreglo con capacidad de sobra y un contador de tamaño.

**Cómo va.** Cuando se llena, reserva uno más grande y copia. El factor de crecimiento importa
más de lo que parece:

```text
Java (ArrayList):  capacidad × 1.5 + ajuste
Python (list):     ~ capacidad × 1.125 (crecimiento suave, ajustado por tamaño)
Go (slice):        × 2 hasta 256 elementos, después menos agresivo
```

- Todos crecen **multiplicando**, no sumando, y por eso el `add` es O(1) amortizado
  ([`01` §6](01-complejidad-y-o-grande.md#6--coste-amortizado)).
- El coste real que se olvida: **durante la copia existen los dos arreglos a la vez**. Con una
  lista de 8 GB, el redimensionado necesita 20 GB de pico.
- Si sabes el tamaño final, `new ArrayList<>(capacidadEsperada)` elimina todos los
  redimensionados. Es de las micro-optimizaciones que sí valen la pena en un bucle de carga.

**Cuándo no.** Cuando insertas al principio: `add(0, x)` desplaza n elementos, y hacerlo en un
bucle es cuadrático. Ese es el trabajo de un deque.

> **Veredicto:** el arreglo dinámico es la estructura por defecto correcta en los cinco
> lenguajes. Lo único que hay que recordar es que insertar al principio no es su trabajo.

---

## 4. 🧱 La lista enlazada, y el único caso en que gana

**Qué es.** Nodos con un valor y una referencia al siguiente (o al anterior, si es doble).

**Cuánto.** Inserción y borrado en O(1) **teniendo el nodo**; acceso por posición en O(n);
memoria extra de uno o dos punteros por elemento más la cabecera de objeto.

**Cuándo sí.** Uno solo, y hay que saber nombrarlo: cuando **ya tienes la referencia al nodo**
y haces muchas inserciones o borrados en medio. Ese "ya tienes el nodo" se da en muy pocos
sitios reales, y casi todos son estructuras internas:

- La lista de una **caché LRU**, donde el mapa te da el nodo directamente.
- El **encadenamiento de un bucket** de una tabla hash, antes de que se convierta en árbol.
- La lista de **bloques libres** de un asignador de memoria.

**Cuándo no.** En código de aplicación, prácticamente siempre. Si recorres para llegar al
punto de inserción, ya pagaste O(n) y perdiste el único beneficio.

> ⚠️ **Advertencia.** *"La lista enlazada inserta en O(1)"* es la media verdad que más se
> repite en entrevistas. La respuesta completa es **"en O(1) si ya tengo el nodo; llegar a él
> es O(n), y en la práctica el arreglo gana por localidad de caché"**. Decir eso entero
> cambia la nota de la pregunta.

---

## 5. 🧱 Dos punteros

**El problema.** Dado el arreglo ordenado `[1, 2, 5, 5, 6, 9]`, encuentra dos elementos que
sumen 11. La solución obvia son dos bucles anidados: O(n²).

**Cómo va.** Un puntero en cada extremo, y se mueven hacia dentro según la comparación:

```java
int izq = 0, der = datos.length - 1;
while (izq < der) {
    int suma = datos[izq] + datos[der];
    if (suma == objetivo) return new int[]{izq, der};
    if (suma < objetivo) izq++;   // necesito más: subo el menor
    else der--;                   // me paso: bajo el mayor
}
```

- El invariante que lo justifica: **si la suma es menor, ningún par con `izq` sirve**, porque
  `der` ya es el mayor disponible. Descartas toda una fila de la matriz de pares en un paso.
- Cada iteración mueve un puntero y ninguno retrocede: son como mucho n iteraciones. **Parece
  anidado y es lineal**, que es la trampa de conteo de [`01` §4](01-complejidad-y-o-grande.md#4--cómo-se-calcula-sin-demostrar-nada).
- Requiere que esté **ordenado**. Si no lo está, ordenar cuesta O(n log n) y entonces conviene
  más un `HashSet` en una pasada, que es O(n).

**Cuándo sí.** Arreglo ordenado, pares o tripletas, palíndromos, mezclar dos secuencias
ordenadas, eliminar duplicados in-place.

**Cuándo no.** Cuando no hay orden y no puedes ordenar porque necesitas los índices
originales: ahí la respuesta es un mapa.

> **Veredicto:** "arreglo ordenado" en el enunciado es la señal. Y la variante lento/rápido
> del mismo patrón —un puntero que avanza de uno y otro de dos— detecta ciclos en una lista
> enlazada con O(1) de memoria.

---

## 6. 🧱 Ventana deslizante

**El problema.** El subarreglo contiguo de longitud 3 con la suma máxima en `[5, 2, 9, 1, 5,
6]`. Recalcular la suma de cada ventana es O(n·k).

**Cómo va.** No recalcules: **actualiza**. Al avanzar la ventana, resta el que sale y suma el
que entra.

```text
[5, 2, 9, 1, 5, 6]   ventana de 3
 └──16──┘             suma = 16
    └──12──┘          16 - 5 + 1 = 12
       └──15──┘       12 - 2 + 5 = 15
          └──12──┘    15 - 9 + 6 = 12      máximo: 16
```

- Cada elemento entra una vez y sale una vez: **O(n) total**, independientemente de k.
- La variante difícil es la **ventana de tamaño variable**: el extremo derecho avanza siempre
  y el izquierdo avanza solo mientras se viole la condición ("sin caracteres repetidos", "suma
  ≤ límite"). Sigue siendo O(n) por el mismo argumento.

**Cuándo sí.** Subarreglo o subcadena **contiguo**, con una condición que se puede mantener
incrementalmente.

**Cuándo no.** Cuando la condición no es incremental —"el subarreglo cuya mediana sea X"— o
cuando el subconjunto no necesita ser contiguo, que es otro problema entero.

> 💡 **Truco.** La palabra "contiguo" en el enunciado vale por media solución. Si no dice
> contiguo, la ventana deslizante no aplica y casi siempre es ordenación o DP.

---

## 7. 🧱 Sumas de prefijos

**El problema.** Te piden la suma de muchos rangos distintos del mismo arreglo. Cada consulta
recorriendo es O(n), y con q consultas es O(n·q).

**Cómo va.** Precalcula una sola vez el acumulado, y después cada consulta es una resta:

```text
datos:    [5,  2,  9,  1,  5,  6]
prefijo: [0, 5,  7, 16, 17, 22, 28]    prefijo[i] = suma de los i primeros

suma(2..4) = prefijo[5] - prefijo[2] = 22 - 7 = 15
```

- El arreglo de prefijos tiene **n+1 posiciones** y empieza en 0. Ese cero de más es lo que
  evita el `if (i == 0)` y es el detalle que casi todo el mundo se salta.
- Precálculo O(n) una vez, consulta O(1) siempre: **la técnica más rentable del capítulo**
  cuando hay muchas consultas.
- Se generaliza a dos dimensiones (suma de un rectángulo con cuatro lecturas) y a otras
  operaciones asociativas e invertibles: producto, XOR. Con máximo **no funciona**, porque el
  máximo no se puede "restar"; para eso hace falta un segment tree, que está fuera del alcance
  de este corpus.

**Cuándo sí.** Muchas consultas de rango sobre datos que no cambian.

**Cuándo no.** Si los datos cambian entre consultas, cada cambio invalida el prefijo desde ese
punto: mantenerlo cuesta O(n) por actualización y pierdes todo lo ganado.

> **Veredicto:** es la técnica de "precalcula una vez, responde infinitas". Su límite es la
> mutabilidad, y decir dónde está ese límite es lo que demuestra que la entiendes.

---

## 8. 🧱 Pila monótona

**El problema.** Para cada elemento, encuentra el **siguiente mayor** a su derecha. La
solución obvia es O(n²).

**Cómo va.** Una pila que mantiene sus elementos en orden decreciente. Cuando llega uno mayor,
resuelve y desapila todo lo que sea menor:

```text
[5, 2, 9, 1, 5, 6]

llega 5 → pila [5]
llega 2 → pila [5,2]
llega 9 → 9>2: resuelve 2→9, desapila; 9>5: resuelve 5→9, desapila; pila [9]
llega 1 → pila [9,1]
llega 5 → 5>1: resuelve 1→5; pila [9,5]
llega 6 → 6>5: resuelve 5→6; pila [9,6]
fin     → 9 y 6 no tienen siguiente mayor
```

- **Cada elemento entra una vez y sale como mucho una vez**: O(n) total, aunque el bucle
  interno parezca anidado. Es la misma trampa de conteo que en dos punteros.
- En la pila se guardan **índices**, no valores, porque casi siempre necesitas la distancia.
- Cambiando el sentido de la comparación resuelves las cuatro variantes: siguiente mayor,
  siguiente menor, anterior mayor, anterior menor.

**Cuándo sí.** "El siguiente mayor", "cuántos días hasta que suba la temperatura", "el
rectángulo más grande en un histograma", "el área de lluvia atrapada".

**Cuándo no.** Cuando la relación no es de vecindad ordenada sino global: "el k-ésimo mayor"
es un heap, no una pila.

> **Veredicto:** es la técnica menos conocida de las cuatro y la que más problemas
> aparentemente distintos resuelve. Si reconoces el patrón "para cada elemento, el siguiente
> que cumpla X", ya la tienes.

---

## 9. ⏱️ La tabla de costes

| Técnica | Tiempo | Espacio | Requisito | Lo que la tabla no dice |
|---|---|---|---|---|
| Fuerza bruta anidada | O(n²) | O(1) | Ninguno | Con n ≤ 5 000 es perfectamente aceptable y más claro |
| Dos punteros | O(n) | O(1) | **Ordenado** | Si hay que ordenar primero, el total es O(n log n) |
| Ventana deslizante | O(n) | O(1) o O(k) | **Contiguo** | El O(k) aparece si hay que contar frecuencias dentro |
| Sumas de prefijos | O(n) + O(1)/consulta | O(n) | **Inmutable** | Una actualización invalida todo lo que hay a la derecha |
| Pila monótona | O(n) | O(n) | Relación de vecindad | La pila puede llegar a tener los n elementos |

---

## 10. ⚖️ Los cinco lenguajes

| Lenguaje | Arreglo dinámico | Deque real | El detalle que muerde |
|---|---|---|---|
| **Java** | `ArrayList`, y `int[]` para primitivos | `ArrayDeque` | `List<Integer>` hace boxing: tres veces la memoria y un salto de puntero por elemento |
| **Python** | `list` | `collections.deque` | `list.pop(0)` e `insert(0, x)` son O(n). `deque` los hace O(1) |
| **JavaScript** | `Array` | **No hay** | `shift()` y `unshift()` son O(n): reindexan. Una cola grande con `push`/`shift` es cuadrática |
| **TypeScript** | Igual que JS | Igual que JS | `readonly T[]` impide mutar **en compilación**; en runtime el arreglo sigue siendo mutable |
| **Go** | `slice` | **No hay** | Un slice es una vista (puntero, longitud, capacidad): `append` puede o no compartir el arreglo de respaldo, y ahí nacen los bugs de aliasing |

Dos trampas que se preguntan y valen la respuesta:

- **El `slice` de Go comparte respaldo.** `b := a[1:3]` no copia: escribir en `b[0]` cambia
  `a[1]`. Y `append` puede reasignar o no según haya capacidad, así que el mismo código a
  veces comparte y a veces no. La solución explícita es `slices.Clone`.
- **`int[]` contra `List<Integer>` en Java.** Un millón de `int` son 4 MB contiguos; un millón
  de `Integer` en una lista son unos 20 MB en objetos dispersos. En un bucle caliente, la
  diferencia es de un orden de magnitud y es la razón por la que las bibliotecas de alto
  rendimiento evitan las colecciones genéricas.

---

## 11. 🧭 Cómo se elige

```text
¿El enunciado dice "ordenado"?                     → dos punteros
¿Dice "contiguo" o "subcadena"?                    → ventana deslizante
¿Dice "muchas consultas de rango" y no cambia?     → sumas de prefijos
¿Dice "el siguiente/anterior que cumpla X"?        → pila monótona
¿No dice ninguna de esas y n es pequeño?           → fuerza bruta, y dilo a propósito

¿Estructura para el día a día?                     → ArrayList / list / slice
¿Metes y sacas por el principio?                   → ArrayDeque / deque
¿Necesitas insertar en medio con el nodo en mano?  → lista enlazada (raro, y se justifica)
```

> **Regla de entrevista:** antes de elegir la técnica, di en voz alta cuál es la solución de
> fuerza bruta y su complejidad. Es gratis, demuestra que entendiste el problema, y te da la
> referencia contra la que comparar la optimización.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`LinkedList` inserta en O(1)" | Con el nodo en la mano. Llegar a él es O(n), y la caché hunde el resto |
| "Ambos son O(n), da igual cuál use" | La localidad de caché los separa por 5–10× en tiempo real |
| "Dos punteros es un bucle anidado" | Ninguno retrocede: son O(n) iteraciones en total |
| "La ventana deslizante sirve para cualquier subconjunto" | Solo para **contiguos** y condiciones incrementales |
| "Las sumas de prefijos sirven para el máximo de un rango" | No: el máximo no es invertible. Eso pide un segment tree |
| "En JS uso `shift()` para desencolar" | Es O(n). Usa un índice de cabeza, o una lista enlazada |
| "`b := a[1:3]` me da una copia en Go" | Comparte el arreglo de respaldo. Para copiar, `slices.Clone` |

---

## 📚 Para profundizar

- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Secciones 1.3 y
  1.4: arreglos redimensionables, listas enlazadas y el análisis del crecimiento por
  duplicación, con el código en Java.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Capítulo 3, en
  particular la discusión sobre por qué las estructuras contiguas ganan a las enlazadas en
  hardware real.
- **Libro** — McDowell, *Cracking the Coding Interview*, 6ª ed. (CareerCup, 2015). Capítulo 1
  ("Arrays and Strings") es donde estas cuatro técnicas aparecen disfrazadas de problemas.
- [Java 21 API — `ArrayList`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/ArrayList.html):
  el contrato de capacidad y el coste amortizado, en el primer párrafo.
- [Python — `collections.deque`](https://docs.python.org/3/library/collections.html):
  la nota explícita de que `list.pop(0)` es O(n) y `deque.popleft()` es O(1).
- [The Go Blog — Go Slices: usage and internals](https://go.dev/blog/slices-intro):
  el modelo puntero/longitud/capacidad y por qué `append` a veces comparte respaldo.
- [MDN — `Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array):
  para confirmar la semántica de `shift`, `unshift` y `splice`.
- **Video** — NeetCode, las listas de reproducción de *Two Pointers* y *Sliding Window*, que
  agrupan los problemas por técnica y no por dificultad.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Por qué el acceso por índice en un arreglo es O(1)? 🟢
2. ¿Qué es una línea de caché y cuántos `int` caben en una? 🟢
3. ¿Qué complejidad tiene `add(0, x)` en un `ArrayList`? 🟢
4. ¿Cuál es el requisito imprescindible de la técnica de dos punteros? 🟢
5. ¿Qué palabra en un enunciado delata una ventana deslizante? 🟢
6. ¿Por qué el arreglo de sumas de prefijos tiene n+1 posiciones? 🟢
7. ¿Por qué un `ArrayList` crece multiplicando y no sumando? 🟡
8. ¿En qué se diferencia `int[]` de `List<Integer>` en memoria? 🟡
9. ¿Por qué dos punteros es O(n) si tiene un bucle con dos variables? 🟡
10. ¿Qué diferencia hay entre ventana de tamaño fijo y de tamaño variable? 🟡
11. ¿Por qué las sumas de prefijos no sirven para consultas de máximo? 🟡
12. ¿Qué se guarda en una pila monótona: valores o índices? ¿Por qué? 🟡
13. ¿Cuál es el único caso en que una lista enlazada gana de verdad? 🟡
14. ¿Qué pico de memoria tiene el redimensionado de un `ArrayList` de 8 GB? 🟡
15. ¿Por qué `list.pop(0)` en Python es O(n) y `deque.popleft()` es O(1)? 🟡
16. ¿Por qué la pila monótona es O(n) si tiene un `while` dentro de un `for`? 🟠
17. ¿Por qué `LinkedList` pierde contra `ArrayList` incluso donde la tabla dice que gana? 🟠
18. En Go, `b := a[1:3]` y luego `b[0] = 99`. ¿Qué le pasa a `a` y por qué? 🟠
19. ¿Por qué una cola implementada con `push`/`shift` en JavaScript es cuadrática? 🟠
20. Tienes un millón de consultas de suma de rango sobre un arreglo que cambia cada mil
    consultas. ¿Sigue conviniendo el prefijo? Justifica. 🟠
21. ¿Cómo detectas un ciclo en una lista enlazada con O(1) de memoria? 🟠
22. `readonly T[]` en TypeScript, ¿congela el arreglo en runtime? ¿Qué garantiza entonces? 🟠
23. Escribe la ventana deslizante de tamaño variable para "la subcadena más larga sin
    caracteres repetidos" y di su complejidad en tiempo y espacio. 🔴
24. Te dan un bucle que hace `lista.remove(0)` n veces sobre un `ArrayList`. Explica la
    complejidad real y da dos arreglos con distinto coste. 🔴
25. Diseña la solución para "cuántos días faltan hasta que la temperatura suba" sobre un año
    de datos, y traza tu algoritmo sobre `[5, 2, 9, 1, 5, 6]`. 🔴

---

**Anterior:** [`02` — TDAs: contrato e implementación](02-tdas-contrato-e-implementacion.md) ·
**Siguiente:** [`04` — Recursión y backtracking](04-recursion-y-backtracking.md) ·
**Relacionado:** [`03-orden-busqueda/03` — Búsqueda](../03-orden-busqueda/03-busqueda.md)
