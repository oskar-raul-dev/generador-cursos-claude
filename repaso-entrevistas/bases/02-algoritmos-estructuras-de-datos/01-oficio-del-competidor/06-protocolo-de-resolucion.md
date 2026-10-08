# 06 — El protocolo de resolución, la repetición y el concurso

> Trabajar cada problema con el mismo método, pedir ayuda —a las pistas o a una IA— sin dejar de
> aprender, y convertir lo resuelto en algo que no se olvida. Presenta también el mapa de señales del
> corpus, al que cada capítulo de técnica le añade filas.
>
> **Niveles:** el protocolo [A] · las pistas y la IA como tutor [A] · repetición y concurso [B].
>
> **📚 Lectura troncal:** Pólya, *Cómo plantear y resolver problemas* (Trillas; traducción de *How to
> Solve It*); Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 1.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-ficha) · [3](#3--los-30-minutos) · [4](#4--la-fuerza-bruta-primero) · [5](#5--las-tres-pistas) · [6](#6--la-ia-como-tutor) · [7](#7--repetición-y-concurso) · [8](#8--el-mapa-de-señales) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Hay dos formas habituales de estudiar con problemas, y las dos fallan.

La primera: lees el enunciado, empiezas a teclear en el minuto dos, y a los cuarenta minutos tienes
un código a medias, una idea que ya no recuerdas por qué elegiste y un WA. La segunda: lees el
enunciado, piensas diez minutos, no sale, miras la solución, la entiendes, te parece obvia, y la
semana siguiente un problema casi igual te bloquea exactamente igual.

La primera falla porque **no hay método**: se diseña tecleando, y el código es el peor sitio para
pensar. La segunda falla porque **entender una solución no es saber producirla**: leerla activa el
reconocimiento, no la memoria que necesitas en la prueba. Y ahora hay una tercera, más tentadora: pedirle
la solución a una IA, que es la segunda forma con menos fricción.

Este capítulo fija **el protocolo** con el que se trabaja cada problema del corpus: una ficha antes y
después, un reparto del tiempo, la fuerza bruta primero, las pistas escalonadas, la IA como tutor y la
repetición. Es lo que convierte cien problemas resueltos en cien problemas aprendidos.

---

## 2. 🧱 La ficha

**Qué es.** Una hoja con preguntas fijas que se responde **antes de escribir código** y se completa
**después de tener AC**. Es la versión de bolsillo de los cuatro pasos de Pólya: comprender el
problema, concebir un plan, ejecutarlo y examinar la solución obtenida.

```text
ANTES DE PROGRAMAR
  Entrada y salida        qué entra, qué sale, en mis palabras
  Restricciones           n, valores, tiempo, memoria
  Complejidad máxima      la que cabe con esas cotas (01/02)
  Casos borde             los de la lista fija que aplican (01/05)
  Fuerza bruta            qué haría, y cuánto cuesta
  Qué se repite           el trabajo que la fuerza bruta hace muchas veces
  Idea optimizada         la técnica que evita repetirlo, y su invariante

DESPUÉS DEL AC
  Patrón                  el nombre de la técnica, como aparece en el mapa de señales (§8)
  Error                   qué falló por el camino, si algo falló
  Pista que hizo falta    ninguna, la 1, la 2 o la 3
  Variante                el mismo problema con una restricción cambiada: ¿qué cambia?
```

**Cómo va.** La parte de antes ocupa cinco a ocho minutos y casi siempre decide el problema: si
«qué se repite» tiene respuesta, la «idea optimizada» suele salir de ahí. La parte de después ocupa
dos minutos y es la que hace que el problema se recuerde: **nombrar el patrón y el error** es lo que
convierte un problema en una regla reutilizable.

**Cuánto cuesta.** Unos diez minutos por problema, que parecen muchos hasta que comparas con los
cuarenta de teclear sin plan. **Cuándo sí**: en todo problema de práctica. **Cuándo no** entera: en un
concurso o una prueba con reloj, donde se hace mental y abreviada (§3).

> **Veredicto:** la ficha de antes evita diseñar tecleando, y la de después evita olvidar. Sin la
> segunda, resolver muchos no es aprender muchos.

---

## 3. 🧱 Los 30 minutos

**Qué es.** El reparto del tiempo de un problema de dificultad media, que es lo que dura en una prueba
de empresa. Se aplica igual a un problema de práctica, con el reloj puesto.

| Minutos | Fase | Qué produces |
|---|---|---|
| 0–5 | **Entender** | El enunciado en tus palabras y los ejemplos resueltos a mano |
| 5–8 | **Estimar** | La complejidad máxima y los tipos, desde las restricciones |
| 8–15 | **Diseñar** | La fuerza bruta, lo que se repite, la idea y su invariante, en papel |
| 15–25 | **Implementar** | El código, sobre la plantilla ([`01/03`](03-entrada-salida-y-plantilla.md)) |
| 25–30 | **Probar** | Los bordes a mano y, si hay duda, el *stress test* (`01/05`) |

**Cómo va.** Las fases tienen salida, no solo duración: no se pasa a implementar sin una idea con
invariante, ni se envía sin probar los bordes. Si a los 15 minutos no hay idea, **se implementa la
fuerza bruta** y se sigue pensando con algo que ya funciona.

**Cuándo sí** se respeta el reparto: con problemas que están a tu nivel. **Cuándo no**: con problemas
muy por encima, donde entender lleva más de cinco minutos; ahí el reparto se estira, pero las fases
siguen en el mismo orden.

> **Veredicto:** el tiempo de diseño en papel no es tiempo perdido: es el que ahorra la mitad del de
> implementación y casi todo el de depuración.

---

## 4. 🧱 La fuerza bruta primero

**Qué es.** Escribir primero la solución más directa y obviamente correcta, aunque no quepa en el
tiempo, y solo después la optimizada.

**Por qué funciona.** Por tres razones independientes:

- **Da puntos.** En una prueba de empresa la puntuación es parcial ([`01/01`](01-el-juez-los-veredictos-y-las-plataformas.md)): la fuerza bruta pasa los
  casos pequeños, que pueden ser la mitad de la nota.
- **Es el oráculo.** Con ella se prueba la versión rápida en un *stress test* (`01/05`).
- **Muestra la estructura.** Escribirla obliga a ver qué se repite, que es exactamente lo que la
  técnica buena elimina.

### De la versión ingenua a la buena

**El problema.** Dado un arreglo de precios por día, la mayor subida: el máximo de `a[j] − a[i]` con
`i < j`, o `0` si los precios solo bajan. Con `[5, 2, 9, 1, 5, 6]`, la mayor subida es `9 − 2 = 7`.

**La ficha, antes:**

```text
Entrada y salida     n precios → la mayor diferencia a[j] − a[i] con i < j, o 0
Restricciones        n ≤ 2·10⁵, precios ≤ 10⁹
Complejidad máxima   n log n o n (01/02)
Casos borde          n = 1 (respuesta 0), precios que solo bajan, todos iguales
Fuerza bruta         todas las parejas i < j: O(n²) = 2·10¹⁰, no cabe
Qué se repite        para cada j, busco el mínimo de a[0..j−1] recorriéndolo entero
Idea optimizada      llevar ese mínimo acumulado mientras avanzo: O(n)
```

**La versión ingenua:**

```java
// Fuerza bruta: todas las parejas i < j. Correcta y O(n²).
static long bestRise(int[] a) {
    long best = 0;
    for (int i = 0; i < a.length; i++)
        for (int j = i + 1; j < a.length; j++)
            best = Math.max(best, (long) a[j] - a[i]);
    return best;
}
```

> «Esto es cuadrático: para cada día de venta recorro todos los anteriores buscando el más barato. Pero
> el más barato de los anteriores solo cambia cuando aparece uno menor, así que lo puedo llevar
> acumulado y el recorrido queda lineal.»

**El camino a la buena.** Mantener el mínimo de los precios vistos hasta ahora; en cada día, la mejor
subida que termina en ese día es el precio actual menos ese mínimo.

```java
// Un recorrido con el mínimo acumulado. O(n) tiempo, O(1) memoria.
static long bestRise(int[] a) {
    long best = 0, minSoFar = a[0];
    for (int j = 1; j < a.length; j++) {
        best = Math.max(best, a[j] - minSoFar);   // mejor subida que termina en j
        minSoFar = Math.min(minSoFar, a[j]);      // ahora a[j] también es «anterior»
    }
    return best;
}
```

- **El invariante**: al empezar la vuelta `j`, `minSoFar` es el mínimo de `a[0..j−1]` y `best` es la
  mayor subida con los dos días en `[0, j−1]`. El orden de las dos líneas importa: primero se usa el
  mínimo de los anteriores, después se actualiza.
- **`best` empieza en 0**, porque el enunciado dice que si solo bajan la respuesta es 0.

**La ficha, después:** patrón «mínimo acumulado» (un caso particular de los prefijos, [`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)); error
típico, actualizar el mínimo antes de usarlo, lo que permite `i = j`; variante: si se pudiera comprar
y vender varias veces, cambia todo.

**Cuándo sí** se empieza por la fuerza bruta: siempre que no tengas la idea buena en la cabeza al
terminar de leer. **Cuándo no**: cuando la idea buena es evidente y la fuerza bruta cuesta lo mismo de
escribir; aun así, se dice en voz alta (`01/07`).

> **Veredicto:** la fuerza bruta es puntos, oráculo y mapa. Escribirla no es rendirse: es el primer
> paso de la buena.

---

## 5. 🧱 Las tres pistas

**Qué es.** Cada problema del corpus, propio o externo, tiene **tres pistas escalonadas**. La primera
está junto al problema; la segunda y la tercera, en el solucionario del bloque.

```text
Pista 1 — mínima     una pregunta que reorienta sin nombrar la técnica    → junto al problema
Pista 2 — de patrón  qué técnica es, y por qué esa                        → en el solucionario
Pista 3 — de diseño  el estado, la transición o el invariante, sin código → en el solucionario
```

**Cómo se usan.** Con el reloj:

```text
20 minutos sin idea            → pista 1
10 minutos más sin idea        → pista 2
10 minutos más sin diseño      → pista 3
con la pista 3 y sin código    → escribe; no hay pista 4
```

**Por qué no hay pista 4.** La solución la escribe el lector. **Ningún problema del corpus lleva
solución publicada**: lo único resuelto son los ejemplos trabajados de cada técnica, como el de §4.
Una solución leída no se aprende; una solución escrita después de la pista 3 sí, porque el trabajo de
convertir el diseño en código es justo lo que la prueba va a pedirte.

**La regla de la pista 1** es que nunca nombra la técnica: *«¿qué cambia en la suma si mueves el
extremo izquierdo?»* es una pista 1; *«usa ventana deslizante»* es una pista 2. Y anotar en la ficha
qué pista hizo falta es el dato que decide qué repasar (§7).

> **Veredicto:** las pistas se piden con reloj, de una en una, y se anotan. Pedir la 3 no es fracasar;
> no anotarla, sí.

---

## 6. 🧱 La IA como tutor

**Qué es.** El lineamiento del corpus para estudiar con un asistente de IA a mano. Parte de un hecho
incómodo: una IA resuelve casi todos los problemas de este corpus en segundos, y **lo que te devuelva
no lo habrás aprendido**. La memoria que necesitas en una prueba se construye recuperando y
produciendo, no reconociendo; por eso la IA sirve como tutor y no como solucionario.

**El lineamiento**, entero:

1. **No le pidas que resuelva el problema.** Lo que te devuelva no lo habrás aprendido.
2. **Empieza tú, con una solución ingenua en tus palabras**: qué haría la fuerza bruta y cuánto
   cuesta.
3. **Intenta el código**, aunque sea incompleto o lento.
4. **Pide *feedback*, no código**: «¿mi invariante es correcto?», «¿qué caso borde falla?», «¿qué
   complejidad tiene esto?».
5. **Refina y repite.** Si sigues atascado, pídele **la pista siguiente**, con los mismos tres niveles
   de §5, no la solución.
6. **Cierra sin ella**: explica en voz alta el invariante y el coste de tu versión final, y anota qué
   pista necesitaste.

**Cómo va**, con frases concretas:

| No le pidas | Pídele |
|---|---|
| «Resuelve este problema» | «Esta es mi fuerza bruta y su coste; ¿es correcta?» |
| «Dame el código optimizado» | «¿Qué trabajo repite mi solución?» |
| «¿Qué técnica es?» (antes de intentarlo) | «Dame una pista que no nombre la técnica» |
| «Arregla mi código» | «Mi código da WA; ¿qué caso borde no estoy considerando?» |
| «Explícame la solución» | «Este es mi invariante; ¿se mantiene en cada vuelta?» |

> 💡 **Truco.** Pídele que haga de entrevistador: que te dé un problema, que no te diga la técnica, que
> te pregunte el coste de tu versión ingenua y que puntúe tu explicación con la rúbrica de `01/07`.
> Es el uso que más se parece a la prueba real.

**Cuánto cuesta.** Más tiempo que pedir la solución, y ese tiempo es exactamente el aprendizaje.
**Cuándo sí** se usa: para revisar, para pedir la pista siguiente, para que te haga preguntas de
entrevista sobre tu solución. **Cuándo no**: antes de haber escrito tu fuerza bruta, y nunca para que
escriba el código que vas a enviar mientras practicas.

> **Veredicto:** la IA es un tutor excelente y un solucionario desastroso. Si sale de la conversación
> con el código y tú sin el invariante, la sesión no sirvió.

---

## 7. 🧱 Repetición y concurso

**Qué es.** Dos prácticas de nivel B que convierten los problemas resueltos en memoria duradera y en
velocidad.

**La repetición espaciada.** Un problema que costó se repite **sin mirar tu solución** al día
siguiente, a los 3 días y a los 7. Solo los que costaron: los que salieron limpios no necesitan
repaso. «Costó» significa que necesitaste la pista 2 o la 3, o que tuviste más de un WA. La ficha de
después dice cuáles son.

**El concurso virtual.** Codeforces, AtCoder y LeetCode permiten participar en un concurso pasado como
si fuera en vivo: mismo tiempo, mismo marcador, otros participantes de entonces. Es el formato más
honesto para medir velocidad. El bloque `21` del corpus organiza cuatro.

**El *upsolving*.** Después de un concurso, resolver los problemas que no salieron durante el tiempo
oficial, con las pistas o el editorial, **y escribirlos tú**. Es donde está el aprendizaje del concurso;
el marcador solo mide.

**El *rating* como termómetro.** El *rating* de Codeforces o AtCoder sube y baja con cada concurso.
Sirve para ver la tendencia de meses, no como objetivo: perseguirlo empuja a los trucos de concurso que
este corpus no enseña.

**Cuánto cuesta.** Unos minutos al día de repaso y dos horas por concurso. **Cuándo sí**: cuando ya
tienes un bloque estudiado. **Cuándo no**: al empezar, cuando lo que falta es teoría y no velocidad.

> **Veredicto:** repite solo lo que costó, en los días 1, 3 y 7; y en los concursos, lo que vale es el
> *upsolving*, no la posición.

---

## 8. 🧱 El mapa de señales

**Qué es.** La tabla que traduce una frase del enunciado a la técnica que suele pedir. Se presenta
aquí con sus filas iniciales; **cada capítulo de técnica le añade las suyas** en su sección «Señales
del enunciado», y el README de cada bloque las reúne.

| Señal en el enunciado | Técnica candidata | Dónde |
|---|---|---|
| `n ≤ 20`, «elige un subconjunto» | Enumerar subconjuntos, máscara de bits | Bloque `10`, [`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md) |
| «Subarreglo contiguo» con suma o condición | Prefijos, ventana deslizante, dos punteros | Bloque `04` |
| «El mínimo valor tal que se cumple…», condición monótona | Búsqueda binaria sobre la respuesta | [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md) |
| «Paréntesis», «el próximo mayor a la derecha» | Pila, pila monótona | [`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md) |
| «El k-ésimo», «los k mayores», «el más urgente de los que llegan» | Montículo | Bloque `08` |
| «¿Están conectados?» con uniones que crecen | Union-Find | [`08/04`](../08-heaps-y-union-find/04-union-find.md) |
| Sumas o mínimos sobre rangos con actualizaciones | Fenwick, árbol de segmentos | Bloque `09` |
| «Elige intervalos sin solapar», «el mínimo de salas» | Ordenar por extremo, voraz | Bloque `11` |
| «Número de formas», «módulo 10⁹+7» | Programación dinámica, combinatoria | Bloques `12` y `17` |
| «Camino más corto» sin pesos | BFS | Bloque `14` |
| «Camino más corto» con pesos no negativos | Dijkstra | Bloque `15` |
| «Antes de A tiene que ir B» | Orden topológico | Bloque `14` |
| «Encuentra el patrón en el texto» | KMP, función Z, *hashing* de cadenas | Bloque `16` |

**Cómo se usa.** En la ficha de antes, la fila «idea optimizada» empieza mirando la tabla: las
señales sugieren candidatas, y las restricciones ([`01/02`](02-leer-las-restricciones.md)) descartan las que no caben. **Una señal no
es una prueba**: «subarreglo contiguo» con valores negativos rompe la ventana deslizante, y el
capítulo de cada técnica dice cuándo la señal engaña.

> **Veredicto:** el mapa acorta la búsqueda de la idea, pero no la sustituye. Cada técnica se elige
> por su señal y se confirma por su invariante.

---

## 9. 🔭 Dónde aparece de verdad

- **El análisis de un incidente.** La ficha de después —qué falló, qué hizo falta, qué variante
  rompería lo mismo— es la estructura de un *postmortem* sin culpables. Se escribe por el mismo
  motivo: que el error no se repita.
- **Diseñar antes de programar.** Las fases de §3 son, en pequeño, un documento de diseño: el
  problema, las restricciones, las alternativas con su coste y la elegida. Saltárselas en un sistema
  real sale igual de caro que en un problema.
- **Las tarjetas de repaso.** Las aplicaciones de repetición espaciada programan los repasos con el
  mismo principio que §7: más tarde cuanto mejor lo recordabas.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si no me sale en 10 minutos, miro la solución» | A los 20 minutos, la pista 1; la solución no existe en el corpus, y leerla no enseña a producirla |
| «La IA me lo explica y ya lo aprendí» | Lo reconoces; producirlo es otra memoria, la que se construye escribiéndolo tú |
| «Resolver muchos es aprender muchos» | Sin la ficha de después y la repetición de lo que costó, se olvidan a la semana |
| «Pensar en papel es perder tiempo» | Es el tiempo que ahorra la mitad de la implementación y casi toda la depuración |
| «La fuerza bruta es para quien no sabe la buena» | Es puntos parciales, oráculo del *stress test* y el mapa de lo que se repite |
| «El *rating* mide lo que sé» | Mide velocidad en un formato concreto; es un termómetro de tendencia, no un objetivo |
| «Si el enunciado dice "subarreglo", es ventana» | Es una candidata; con negativos o sin monotonía, la ventana falla |

---

## 📚 Para profundizar

- **Libro** — Pólya, *Cómo plantear y resolver problemas* (Trillas; traducción de *How to Solve It*):
  los cuatro pasos y la lista de preguntas que inspiran la ficha. *Lectura troncal.*
- **Libro** — Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 1: modelar el
  problema antes de resolverlo, y por qué los ejemplos no prueban nada. *Lectura troncal.*
- **Libro** — Engel, *Problem-Solving Strategies* (Springer, 1998), cap. 1: las estrategias generales
  de resolución con ejemplos de olimpiada.
- **Libro** — Halim, Halim y Effendy, *Competitive Programming 4*, libro 1 (2020), cap. 1: consejos
  para concursar, concursos virtuales y *upsolving*.
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 1: cómo
  practicar y cómo usar los concursos.

---

## 🧠 Preguntas

1. ¿Qué preguntas tiene la ficha de antes de programar y cuáles la de después? 🟢
2. ¿En qué fases se reparten los 30 minutos de un problema, y qué produce cada una? 🟢
3. ¿Qué diferencia hay entre la pista 1, la 2 y la 3, y por qué no hay pista 4? 🟢
4. ¿Qué diferencia hay entre entender una solución leída y saber producirla? 🟡
5. ¿Qué diferencia hay entre un concurso virtual y el *upsolving*, y dónde está el aprendizaje? 🟡
6. ¿Por qué la ficha de después es la que hace que un problema se recuerde? 🟡
7. ¿Qué problemas entran en la repetición espaciada y cuáles no, y con qué criterio? 🟡
8. Llevas 15 minutos sin idea en una prueba de empresa de 90 minutos con dos problemas. ¿Qué haces, y por qué? 🟠
9. ¿Por qué el lineamiento de la IA pide escribir la fuerza bruta antes de preguntarle nada? 🟠
10. Para la mayor subida de §4, ¿por qué importa el orden entre usar `minSoFar` y actualizarlo? 🟠
11. Rellena la ficha de antes para «contar los pares `i < j` con `a[i] = a[j]`, `n ≤ 2·10⁵`». 🔴
12. Una señal del mapa sugiere ventana deslizante para «el subarreglo más corto con suma ≥ S», pero los valores pueden ser negativos. Explica por qué la señal engaña aquí y qué propiedad le falta. 🔴

---

## 🧩 Problemas propios

Resuelve cada uno **con la ficha completa**, antes y después, y anota el tiempo de cada fase.

### Días récord

**Nivel:** 🟢 · **Formato:** programa completo.

Un día es *récord* si sus ventas son estrictamente mayores que las de todos los días anteriores. El
primer día siempre es récord. Cuenta los días récord.

- **Entrada.** Una línea con `n`. Una segunda línea con `n` enteros, las ventas.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `0 ≤ ventas ≤ 10⁹`.

```text
Entrada            Salida
6                  2
5 2 9 1 5 6

Entrada            Salida
3                  1
7 7 7
```

**Pista 1:** para decidir si el día `j` es récord, ¿necesitas todos los días anteriores o solo un
número?

### Los dos más cercanos

**Nivel:** 🟡 · **Formato:** programa completo.

Dados `n` valores, imprime la menor diferencia absoluta entre dos de ellos (en posiciones distintas).

- **Entrada.** Una línea con `n`. Una segunda línea con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 2·10⁵`; `|a[i]| ≤ 10⁹`.

```text
Entrada            Salida
6                  0
5 2 9 1 5 6

Entrada            Salida
2                  2000000000
-1000000000 1000000000
```

**Pista 1:** si los valores estuvieran en orden, ¿entre qué parejas podría estar la menor diferencia?

### La mejor semana con un día libre

**Nivel:** 🟠 · **Formato:** programa completo, con **subtareas**.

Una tienda elige `k` días consecutivos para una campaña y puede descontar el peor día de esos `k` (el de
menos ventas). La ganancia de la campaña es la suma de los `k` días menos el mínimo de ellos. Imprime la
mayor ganancia posible.

- **Entrada.** Una línea con `n` y `k`. Una segunda línea con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ k ≤ n ≤ 2·10⁵`; `0 ≤ ventas ≤ 10⁹`.
- **Subtareas.** 50 puntos: `n ≤ 1000`. 50 puntos: sin restricciones adicionales.

```text
Entrada            Salida
6 3                14
5 2 9 1 5 6

Entrada            Salida
2 2                4
4 4
```

**Pista 1:** con `n ≤ 1000`, ¿cuánto cuesta calcular cada ventana desde cero, y cuántos puntos te da
eso?

🔥 **Para el geek — en JavaScript:** la suma de una ventana llega a `2·10¹⁴`, que todavía cabe exacta
en un `Number`; pero si mantienes el mínimo con una estructura auxiliar, `shift()` sobre un arreglo es
`O(n)` y convierte la solución lineal en cuadrática.

---

## 🧩 Práctica externa

Aquí el algoritmo es secundario: el ejercicio es **la ficha completa**, con el tiempo de cada fase
anotado.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Valid Anagram](https://leetcode.com/problems/valid-anagram/) | LeetCode | 🟢 | Conteo | ¿Qué tienen en común dos palabras que son anagramas, además de la longitud? |
| [ ] | [Move Zeroes](https://leetcode.com/problems/move-zeroes/) | LeetCode | 🟢 | Compactar en el sitio | ¿Dónde tiene que ir el próximo elemento distinto de cero? |
| [ ] | [Majority Element](https://leetcode.com/problems/majority-element/) | LeetCode | 🟢 | Conteo o voto | ¿Qué pasa si emparejas y descartas dos elementos distintos? |
| [ ] | [Sales by Match](https://www.hackerrank.com/challenges/sock-merchant/problem) | HackerRank | 🟢 | Conteo | ¿Cuántos pares salen de cada color? |
| [ ] | [Counting Valleys](https://www.hackerrank.com/challenges/counting-valleys/problem) | HackerRank | 🟢 | Simulación con estado | ¿En qué paso exacto termina un valle? |
| [ ] | [FrogRiverOne](https://app.codility.com/programmers/lessons/4-counting_elements/frog_river_one/) | Codility | 🟢 | Conteo de cobertura | ¿Cómo sabes, en cada segundo, cuántas posiciones faltan? |
| [ ] | [MaxCounters](https://app.codility.com/programmers/lessons/4-counting_elements/max_counters/) | Codility | 🟡 | Actualización perezosa | ¿Hace falta tocar todos los contadores cada vez que se igualan al máximo? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Ferris Wheel](https://cses.fi/problemset/task/1090) | CSES | 🟡 | Emparejar extremos | ¿Con quién conviene emparejar al niño más pesado? |
| [ ] | [Apartments](https://cses.fi/problemset/task/1084) | CSES | 🟡 | Emparejar ordenados | Si ordenas solicitantes y apartamentos, ¿qué decisión tomas con el primero de cada lista? |
| [ ] | [Restaurant Customers](https://cses.fi/problemset/task/1619) | CSES | 🟡 | Eventos | ¿Qué pasa con el número de clientes cada vez que alguien entra o sale? |

---

## ✅ Criterio de dominio

- Rellenar la ficha de antes en menos de ocho minutos para un problema del núcleo, con la fuerza bruta
  y su coste.
- Recitar el lineamiento de la IA en seis puntos y dar un ejemplo de pregunta que pide *feedback* y no
  código.
- Resolver dos problemas del núcleo con la ficha completa sin pasar de la pista 1.
- Tener en marcha la repetición de los problemas que necesitaron pista 2 o 3.

---

**Anterior:** [`01/05` — Probar sin IDE y *stress test*](05-probar-sin-ide-y-stress-test.md) ·
**Siguiente:** [`01/07` — Programar en vivo](07-programar-en-vivo.md) ·
**Relacionado:** [`02/04` — Corrección: invariantes, inducción e intercambio](../02-analisis/04-correccion-invariantes-induccion-intercambio.md).
