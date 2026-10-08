# 07 — Programar en vivo

> Resolver delante de alguien que te mira teclear: preguntar antes de escribir, la versión ingenua
> completa, el coste dicho en voz alta, la mejora nombrada con precisión y la prueba a mano. Con la
> rúbrica de seis puntos con la que se califica y un ejemplo trabajado entero, narrado.
>
> **Niveles:** el método en vivo [A] · la rúbrica [A].
>
> **📚 Lectura troncal:** McDowell, *Cracking the Coding Interview*, 6.ª ed. (CareerCup, 2015),
> secciones I («The Interview Process») y VII («Technical Questions»); Aziz, Lee y Prakash, *Elements
> of Programming Interviews in Java* (2015), cap. 1.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [1](#1--el-problema) · [2](#2--antes-de-teclear) · [3](#3--la-versión-ingenua-primero) · [4](#4--el-coste-en-voz-alta-y-la-mejora-con-nombre) · [5](#5--probar-a-mano) · [6](#6--la-rúbrica) · [7](#7--el-ejemplo-entero-narrado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

En una entrevista en vivo te dan un problema y te miran. Lees el enunciado, reconoces algo, y te
callas ocho minutos pensando la solución óptima. Empiezas a teclearla, a la mitad te das cuenta de que
un caso no encaja, borras, vuelves a pensar en silencio. A los 35 minutos tienes media solución
óptima que no compila y el entrevistador no sabe nada de lo que pensaste.

Para quien te evalúa, esa media hora fue **silencio y un código incompleto**. No puede puntuar un
razonamiento que no oyó, ni una corrección que no ve. Y lo frustrante es que probablemente sabías
escribir en diez minutos una versión sencilla que funcionaba.

Una entrevista en vivo **no evalúa lo mismo que un juez**. El juez quiere AC; la persona quiere ver
cómo piensas: si entiendes el problema antes de resolverlo, si tienes una solución correcta, si sabes
lo que cuesta y si sabes mejorarla. Este capítulo da el método para mostrar eso, la rúbrica con la que
se mide y un ejemplo entero narrado. Es también el capítulo que da sentido a la sección «De la versión
ingenua a la buena» que llevan todas las técnicas del corpus.

> 🧠 **Modelo mental.** Recordatorio, si llegas directo aquí: `O(n²)` significa que el trabajo crece
> con el cuadrado del tamaño de la entrada; con `n = 10⁵` son `10¹⁰` pasos, y en un segundo caben del
> orden de `10⁸`. Con esa cuenta se decide, en voz alta, si una versión «cabe» o no.

---

## 2. 🧱 Antes de teclear

**Qué es.** Los primeros tres a cinco minutos, en los que **no se escribe código**: se entiende el
problema en voz alta y se pregunta lo que el enunciado no dice. Un problema de entrevista suele estar
**incompleto a propósito**, para ver si preguntas.

**Cómo va.** Repites el problema con tus palabras, resuelves un ejemplo a mano delante de la persona y
haces las preguntas que cambian la solución:

| Pregunta | Por qué cambia la solución |
|---|---|
| ¿Cuánto puede valer `n`? | Decide la complejidad que cabe ([`01/02`](02-leer-las-restricciones.md)) |
| ¿Puede haber negativos, ceros, duplicados? | Rompe o permite técnicas (la ventana, el máximo en cero) |
| ¿Puede estar vacía la entrada? | Decide el primer borde que pruebas |
| ¿Puedo modificar la entrada? | Permite ordenar en el sitio o marcar visitados sin memoria extra |
| ¿Qué devuelvo si no hay respuesta? | `−1`, `null`, una lista vacía: es parte de la firma |
| ¿Importa el orden de la salida? | Ordenar la salida cuesta `n log n` y a veces no hace falta |

**Cuánto cuesta.** Tres a cinco minutos que parecen lentos y ahorran los diez que cuesta descubrir a
mitad del código que había duplicados. **Cuándo sí**: siempre. **Cuándo no** alargarlo: cuando el
enunciado ya responde todo; entonces se dice «el enunciado acota `n` a 10⁵ y permite negativos; asumo
que la entrada no es vacía» y se sigue.

> **Veredicto:** el entrevistador puntúa las preguntas. Un candidato que pregunta por los duplicados
> antes de que se los mencionen ya sumó puntos.

---

## 3. 🧱 La versión ingenua primero

**Qué es.** Escribir **primero** la solución más directa —un doble bucle, una búsqueda exhaustiva, una
recursión sin memoria—, **completa y correcta**, aunque su coste no sea el bueno.

**Por qué aprueba donde un óptimo a medias no.** Porque demuestra cuatro cosas que la rúbrica mide:
que entendiste el problema, que sabes escribir código correcto, que sabes cuánto cuesta y que tienes
algo concreto que mejorar. Un óptimo a medias no demuestra ninguna: no se sabe si es correcto, no
compila, y no hay nada que probar. Y en la práctica, **la versión ingenua escrita en voz alta suele
hacer aparecer la mejora**, porque al teclearla se ve qué trabajo se repite.

**Cómo va.** Se anuncia: «voy a empezar por una versión directa, que es cuadrática, y después la
mejoro». Se escribe limpia, con nombres buenos, y se prueba con el ejemplo antes de seguir.

**Cuánto cuesta.** Cinco a diez minutos. **Cuándo sí**: casi siempre. **Cuándo no**: cuando la versión
buena es igual de corta y obvia (un recorrido con un máximo); entonces se dice que la ingenua sería
cuadrática y por qué no hace falta.

> **Veredicto:** una versión ingenua correcta, completa y probada vale más que un óptimo a medias. Es
> el punto de partida que la rúbrica premia y el atajo hacia la mejora.

---

## 4. 🧱 El coste en voz alta y la mejora con nombre

**Qué es.** Dos frases que se dicen en voz alta después de la versión ingenua: **cuánto cuesta y por
qué**, y **qué técnica lo mejora y a qué coste**. La segunda se dice **con precisión**: el nombre de
la técnica y el coste resultante, no una vaguedad.

| Frase vaga | Frase precisa |
|---|---|
| «Se puede optimizar» | «Con un mapa de la última posición de cada valor baja a `O(n)` esperado» |
| «Usaría programación dinámica» | «Con memoización sobre `(i, restante)` cada estado se calcula una vez: `O(n·k)`» |
| «Es lento» | «Es `O(n²)`; con `n = 10⁵` son `10¹⁰` pasos, no cabe» |
| «Hay que recorrer el grafo» | «Esto va con un BFS por niveles, `O(V + E)`, porque las aristas no tienen peso» |

**Cómo va.** El orden es fijo: coste de la ingenua, qué se repite, la técnica que lo evita, el coste
nuevo. Y **solo si queda tiempo**, se escribe la mejora. Muchas entrevistas puntúan alto a quien
nombra bien la mejora y no llega a escribirla, y bajo a quien la escribe sin haber explicado nada.

**Mientras piensas, hablas.** Lo que más penaliza en vivo no es equivocarse, es el silencio. Decir
«estoy pensando si ordenar me ayuda: si ordeno, los iguales quedan juntos, pero pierdo los índices»
convierte un minuto de silencio en un minuto de razonamiento puntuable, y le da a la persona la
ocasión de darte una pista.

**Cuándo sí**: siempre, incluso si la mejora no se escribe. **Cuándo no**: nunca se omite.

> **Veredicto:** el coste se dice con la cuenta, y la mejora con el nombre de la técnica y su coste.
> Escribirla es opcional; nombrarla, no.

---

## 5. 🧱 Probar a mano

**Qué es.** Recorrer el código **línea a línea** con un ejemplo, en voz alta, anotando cómo cambian las
variables, **antes** de decir que está terminado. Y después, con un caso borde.

**Cómo va.** Se elige un ejemplo pequeño, se escribe la tabla de variables y se avanza por el código
como lo haría la máquina, no como uno cree que funciona. Después se elige un borde de la lista de
[`01/05`](05-probar-sin-ide-y-stress-test.md) —un solo elemento, todos iguales, la respuesta en el último— y se repite.

**Cuando te quedas en blanco**, que pasa, hay cuatro salidas que se dicen en voz alta:

- **Volver al ejemplo**: resolverlo a mano y observar qué haces tú. Lo que haces a mano suele ser el
  algoritmo.
- **Simplificar**: «¿y si los valores fueran distintos?», «¿y si `n` fuera 3?». Resolver la versión
  fácil da pie a la difícil.
- **Pensar en la estructura**: «¿qué estructura haría trivial la operación que repito?».
- **Pedir una pista**: hacerlo con una hipótesis («estoy entre ordenar y usar un mapa; ¿alguna te
  parece mejor encaminada?») vale más que un «no sé».

**Cuánto cuesta.** Tres a cinco minutos. **Cuándo sí**: siempre antes de decir «ya está». **Cuándo
no**: nunca se salta; es uno de los seis puntos de la rúbrica.

> **Veredicto:** decir «creo que funciona» no puntúa; recorrerlo con un caso borde delante de la
> persona, sí.

---

## 6. 🧱 La rúbrica

**Qué es.** La rúbrica con la que el corpus califica una sesión en vivo, y con la que se califican
los simulacros en vivo del [bloque `21`](../21-simulacros/README.md). Seis puntos de 0 a 2. **No se califica el verde del juez.**

| Punto | 0 | 1 | 2 |
|---|---|---|---|
| **Entender y preguntar** | Empieza a teclear sin preguntar | Pregunta algo, tarde | Repite el problema, resuelve un ejemplo y pregunta lo que cambia la solución antes de teclear |
| **Versión ingenua correcta** | No hay versión completa | Completa con un error | Completa, correcta y probada con el ejemplo |
| **Su coste en voz alta** | No lo dice | Lo dice sin justificar | Lo dice con la cuenta y con las restricciones |
| **La mejora nombrada** | No la nombra | La nombra vagamente | Nombra la técnica y el coste nuevo con precisión |
| **Código legible** | Nombres de una letra, sin estructura | Legible con esfuerzo | Nombres que dicen qué guardan, funciones cortas |
| **Prueba a mano con un borde** | No prueba | Prueba solo el ejemplo | Recorre el código con un borde y lo dice |

**Cómo se usa.** Grabándote o con otra persona que hace de entrevistador, con un problema de 45
minutos. Al terminar, cada punto se califica con la tabla y se anota cuál fue el más bajo: es el que
se practica en la siguiente sesión. **12 de 12 no exige haber escrito la versión óptima.**

**Cómo se usan las secciones «De la versión ingenua a la buena»** de cada técnica del corpus: son
ejemplos de la rúbrica en 2 en los puntos 2, 3 y 4. Para practicar, se lee solo el problema, se
intenta la versión ingenua y la frase en voz alta, y después se compara con el capítulo.

> **Veredicto:** la rúbrica mide cómo piensas en voz alta, no si llegas al óptimo. Practica el punto
> más bajo, no el que ya tienes.

---

## 7. 🧱 El ejemplo entero, narrado

**Qué es.** Una sesión completa de unos 25 minutos, con lo que se dice y lo que se escribe, para un
problema típico. Es la sección «De la versión ingenua a la buena» del capítulo, extendida con la
conversación.

### De la versión ingenua a la buena

**El problema.** «Dado un arreglo de enteros y un número `k`, devuelve `true` si hay dos posiciones
distintas `i` y `j` con el mismo valor y `|i − j| ≤ k`.»

**Entender y preguntar** (minutos 0–4). En voz alta:

> «Repito: busco dos posiciones distintas con el mismo valor, a distancia como mucho `k`. Con
> `[5, 2, 9, 1, 5, 6]` y `k = 3`, los dos 5 están en 0 y en 4, a distancia 4: `false`. Con `k = 4`,
> `true`. ¿Cuánto puede valer `n`? ¿Y `k`, puede ser 0 o mayor que `n`? ¿Los valores pueden ser
> negativos o muy grandes?»

Respuesta de la persona: `n` hasta `10⁵`, `k` entre 0 y `10⁵`, valores cualesquiera de `int`.

**La versión ingenua** (minutos 4–10):

> «Empiezo por lo directo: para cada `i`, miro las siguientes `k` posiciones.»

```java
// Versión directa: para cada i, las k posiciones siguientes. Correcta, O(n·k).
static boolean nearbyDuplicate(int[] a, int k) {
    for (int i = 0; i < a.length; i++) {
        int last = Math.min(a.length - 1, i + k);     // no salirse del arreglo
        for (int j = i + 1; j <= last; j++)
            if (a[i] == a[j]) return true;
    }
    return false;
}
```

> «Lo pruebo con el ejemplo y `k = 3`: desde `i = 0` miro las posiciones 1 a 3, valores 2, 9 y 1;
> ningún 5. Desde `i = 1`, posiciones 2 a 4… sigo, y ningún par coincide: `false`. Con `k = 4`, desde
> `i = 0` llego a la posición 4, que vale 5: `true`. Bien.»

**El coste y la mejora** (minutos 10–13):

> «Esto es `O(n·k)`. Con `n` y `k` hasta `10⁵` son `10¹⁰` pasos: no cabe. Lo que repito es, para cada
> posición, buscar hacia atrás un valor igual. Me basta con saber **dónde vi por última vez** cada
> valor: si la última aparición está a distancia `≤ k`, ya está. Con un mapa de valor a última
> posición, cada paso es `O(1)` esperado y el total baja a `O(n)` esperado, con `O(n)` de memoria.»

**La versión buena** (minutos 13–20):

```java
import java.util.HashMap;
import java.util.Map;

// Un recorrido con la última posición de cada valor. O(n) esperado, O(n) memoria.
static boolean nearbyDuplicate(int[] a, int k) {
    Map<Integer, Integer> lastSeen = new HashMap<>();
    for (int j = 0; j < a.length; j++) {
        Integer i = lastSeen.get(a[j]);              // última posición anterior con el mismo valor
        if (i != null && j - i <= k) return true;
        lastSeen.put(a[j], j);                       // j es ahora la última aparición
    }
    return false;
}
```

- **El invariante**: al empezar la vuelta `j`, `lastSeen` guarda, para cada valor visto, su **última**
  posición en `[0, j−1]`. Si hay un par válido que termina en `j`, el más cercano es la última
  aparición, así que basta con mirar esa.
- **`Integer i` y `!= null`**: `get` devuelve `null` si el valor no está; comparar con `==` dos
  `Integer` sería un error clásico de Java, pero aquí `j - i` desempaqueta a `int`.
- **`put` después de comprobar**, para no comparar la posición `j` consigo misma.

**Probar a mano con un borde** (minutos 20–24):

> «Pruebo con `k = 0`: ningún par puede estar a distancia 0 con posiciones distintas, así que debería
> dar `false`. Con `[7, 7]` y `k = 0`: en `j = 0` no hay nada y guardo `7 → 0`; en `j = 1` encuentro
> `i = 0`, y `1 − 0 = 1 > 0`, no devuelve; guardo `7 → 1`; termina: `false`. Correcto. Y con un solo
> elemento, el bucle da una vuelta y devuelve `false`.»

**El cierre** (minuto 25):

> «Queda `O(n)` en tiempo esperado y `O(n)` en memoria. Si la memoria importara, podría mantener solo
> los últimos `k` valores en un conjunto, que es una ventana deslizante: memoria `O(k)`.»

**Cuándo sí** se narra así: en cualquier entrevista en vivo. **Cuándo no**: en una prueba de juez sin
nadie mirando, donde la narración se hace mental.

> **Veredicto:** el ejemplo puntúa 2 en los seis puntos sin nada brillante: preguntas, versión directa
> probada, coste con la cuenta, mejora con nombre, código legible y un borde recorrido en voz alta.

---

## 8. 🔭 Dónde aparece de verdad

- **La revisión de código en pareja.** Explicar en voz alta qué hace un cambio, por qué es correcto y
  qué cuesta es la misma habilidad que la entrevista, sin el reloj.
- **El diseño en una pizarra.** Proponer primero lo simple que funciona, nombrar su límite («esto
  aguanta hasta 10⁴ peticiones por segundo») y después la mejora, es el patrón de §3 y §4 aplicado a
  un sistema.
- **Explicar un incidente.** Contar qué pasó, qué se probó y por qué la corrección es correcta, a
  alguien que no estaba, se parece mucho a narrar una solución en vivo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Hay que llegar al óptimo o no cuenta» | La rúbrica puntúa la ingenua correcta, el coste y la mejora nombrada; 12 de 12 no exige escribir el óptimo |
| «Mientras pienso, me callo» | El silencio no se puede puntuar; pensar en voz alta sí, y abre la puerta a una pista |
| «Preguntar parece que no sé» | Preguntar lo que cambia la solución es un punto de la rúbrica |
| «La versión ingenua es una pérdida de tiempo» | Es correcta, se prueba, muestra lo que se repite y suele llevar a la mejora |
| «Se puede optimizar» | Sin técnica y sin coste no es una mejora, es una promesa |
| «Creo que funciona» | Recorrer el código con un borde en voz alta es lo que lo demuestra |

---

## 📚 Para profundizar

- **Libro** — McDowell, *Cracking the Coding Interview*, 6.ª ed. (CareerCup, 2015), secciones I
  («The Interview Process») y VII («Technical Questions»): el proceso de una entrevista y el método
  para resolver delante de alguien. *Lectura troncal.*
- **Libro** — Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2015), cap. 1: la
  estrategia para la entrevista y cómo comunicar la solución. *Lectura troncal.*
- **Libro** — Pólya, *Cómo plantear y resolver problemas* (Trillas): las preguntas para cuando te
  quedas en blanco (¿conoces un problema relacionado?, ¿puedes resolver una parte?).
- **Libro** — Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 4: escribir
  programas correctos razonando sobre su invariante, con la búsqueda binaria como ejemplo.

---

## 🧠 Preguntas

1. ¿Qué seis puntos tiene la rúbrica en vivo, y qué no se califica? 🟢
2. ¿Qué preguntas haces antes de teclear, y por qué cada una puede cambiar la solución? 🟢
3. ¿Qué cuatro salidas tienes cuando te quedas en blanco? 🟢
4. ¿Qué diferencia hay entre una mejora nombrada vagamente y una nombrada con precisión? Da un ejemplo de cada una. 🟡
5. ¿Qué diferencia hay entre lo que evalúa un juez y lo que evalúa una persona en una entrevista en vivo? 🟡
6. ¿Qué diferencia hay entre probar con el ejemplo y probar a mano con un borde? 🟡
7. ¿Por qué una versión ingenua correcta puntúa más que un óptimo a medias? 🟠
8. Llevas 30 minutos de 45, tienes la ingenua probada y sabes la mejora. ¿La escribes o no, y qué dices? 🟠
9. En el ejemplo de §7, ¿por qué el `put` va después de la comprobación y no antes? 🟠
10. En el ejemplo de §7, ¿qué devuelve `lastSeen.get(a[j])` cuando el valor no se vio nunca, y qué pasaría si lo guardaras directamente en un `int`? 🟠
11. Narra, en cinco o seis frases, la versión ingenua y la mejora para «¿hay dos números del arreglo que sumen `K`?», con su coste. 🔴
12. Califica con la rúbrica esta sesión: el candidato no preguntó nada, escribió directamente la versión óptima, correcta, con variables `a`, `b`, `c`, dijo «es lineal» sin más, y no probó. Justifica cada punto. 🔴
13. Para el ejemplo de §7, propón una variante que use memoria `O(k)` en vez de `O(n)`, di su invariante y su coste. 🔴

---

## 🧩 Problemas propios

Estos tres se practican **en voz alta**, con reloj de 45 minutos, grabándote o con otra persona, y se
califican con la rúbrica de §6. El juez no importa.

### Rotación de una palabra

**Nivel:** 🟢 · **Formato:** función `boolean isRotation(String s, String t)`.

Devuelve `true` si `t` se obtiene rotando `s`: moviendo algunos caracteres del principio al final. Toda
palabra es rotación de sí misma.

- **Restricciones.** `0 ≤ |s|, |t| ≤ 10⁵`; letras minúsculas.

```text
s = "abracadabra", t = "cadabraabra"   →  true
s = "abra",        t = "brab"          →  false
s = "",            t = ""              →  true
```

**Pista 1:** si escribes `s` dos veces seguidas, ¿qué palabras aparecen dentro?

### Compresión por rachas

**Nivel:** 🟡 · **Formato:** función `String compress(String s)`.

Sustituye cada tramo de caracteres iguales consecutivos por el carácter seguido de la longitud del
tramo, solo si la longitud es mayor que 1. Devuelve la cadena original si la comprimida no es más
corta.

- **Restricciones.** `0 ≤ |s| ≤ 10⁵`; letras minúsculas.

```text
"aaabccdddd"  →  "a3bc2d4"
"abc"         →  "abc"
"aab"         →  "aab"      (la comprimida, "a2b", no es más corta)
""            →  ""
```

**Pista 1:** ¿qué pasa con el último tramo de la cadena cuando terminas de recorrerla?

🔥 **Para el geek — en Go:** concatenar cadenas con `+` dentro de un bucle copia la cadena entera cada
vez; con `strings.Builder` cambia el coste de la construcción, y en Java pasa lo mismo con `String`
frente a `StringBuilder`.

### Reuniones que se pisan

**Nivel:** 🟠 · **Formato:** función que recibe una lista de intervalos `[inicio, fin)` y devuelve la
lista de intervalos fusionados.

Fusiona las reuniones que se solapan: dos intervalos se fusionan si comparten algún instante. Como
son semiabiertos, `[1, 3)` y `[3, 5)` **no** se solapan. Devuelve los fusionados ordenados por inicio.

- **Restricciones.** `0 ≤ n ≤ 10⁵`; `0 ≤ inicio < fin ≤ 10⁹`.

```text
[[1,3), [2,6), [8,10), [9,12)]   →  [[1,6), [8,12)]
[[1,3), [3,5)]                    →  [[1,3), [3,5)]
[]                                →  []
```

**Pista 1:** si las reuniones estuvieran en orden de inicio, ¿con cuál podría solaparse la siguiente?

---

## 🧩 Práctica externa

Hazlos en voz alta, grabándote: primero las preguntas, después la versión ingenua con su coste, la
mejora nombrada y la prueba con un borde. Califícate con la rúbrica antes de mirar si el juez da AC.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/) | LeetCode | 🟢 | Mezcla de dos ordenados | ¿Qué comparas en cada paso, y qué haces cuando una lista se acaba? |
| [ ] | [Longest Common Prefix](https://leetcode.com/problems/longest-common-prefix/) | LeetCode | 🟢 | Recorrido por columnas | ¿Hasta qué posición coinciden todas las palabras? |
| [ ] | [Roman to Integer](https://leetcode.com/problems/roman-to-integer/) | LeetCode | 🟢 | Recorrido con el vecino | ¿Cuándo un símbolo resta en vez de sumar? |
| [ ] | [Is Subsequence](https://leetcode.com/problems/is-subsequence/) | LeetCode | 🟢 | Dos índices | ¿Qué avanza cuando dos caracteres coinciden, y qué cuando no? |
| [ ] | [Group Anagrams](https://leetcode.com/problems/group-anagrams/) | LeetCode | 🟡 | Clave canónica | ¿Qué tienen en común dos anagramas que puedas usar como clave? |
| [ ] | [Balanced Brackets](https://www.hackerrank.com/challenges/balanced-brackets/problem) | HackerRank | 🟡 | Apertura y cierre | Al ver un cierre, ¿con qué apertura tiene que emparejar? |
| [ ] | [MaxProductOfThree](https://app.codility.com/programmers/lessons/6-sorting/max_product_of_three/) | Codility | 🟢 | Ordenar y mirar extremos | ¿Puede el mejor producto usar números negativos? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Product of Array Except Self](https://leetcode.com/problems/product-of-array-except-self/) | LeetCode | 🟡 | Prefijos y sufijos | ¿Qué productos parciales a la izquierda y a la derecha de cada posición necesitas? |
| [ ] | [Top K Frequent Elements](https://leetcode.com/problems/top-k-frequent-elements/) | LeetCode | 🟡 | Conteo y selección | Después de contar, ¿necesitas ordenar todo para quedarte con `k`? |
| [ ] | [Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/) | LeetCode | 🟡 | Extremos que avanzan | Cuando aparece un carácter repetido, ¿hasta dónde tiene que avanzar el inicio? |

---

## ✅ Criterio de dominio

- Narrar el ejemplo de §7 de memoria, con las preguntas, las dos versiones, el coste y el borde, en
  menos de 25 minutos.
- Hacer tres sesiones grabadas con los problemas propios y sacar al menos 10 de 12 en la rúbrica.
- Decir para cualquier problema del núcleo la frase precisa de la mejora: técnica y coste.
- Recitar las cuatro salidas para cuando te quedas en blanco.

---

**Anterior:** [`01/06` — El protocolo de resolución](06-protocolo-de-resolucion.md) ·
**Siguiente:** [`01/08` — Simulación](08-simulacion.md) ·
**Relacionado:** [el bloque `21` — Simulacros](../21-simulacros/README.md), simulacros en vivo.
