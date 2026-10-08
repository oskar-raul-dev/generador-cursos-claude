# 04 — Recursión y backtracking

> La pila de llamadas como estructura de datos que no ves, por qué la JVM no elimina la
> recursión de cola aunque la escribas bien, y el patrón elegir–explorar–deshacer que
> resuelve toda la familia de problemas combinatorios con el mismo esqueleto.
> Asume leído [`01` — Complejidad y O grande](01-complejidad-y-o-grande.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Escribes un recorrido recursivo de un árbol de categorías de producto. Funciona en
desarrollo, funciona en pruebas, y en producción revienta con `StackOverflowError` sobre un
catálogo que alguien cargó con una jerarquía de 30 000 niveles porque un proceso de
importación creó un ciclo.

El error no dice "tienes un ciclo". Dice que se acabó la pila, con mil líneas de traza
idénticas. Y el mismo código en Python habría fallado mucho antes, a los mil niveles, con un
mensaje distinto.

La recursión es la única estructura de control que **consume memoria proporcional a la
profundidad sin que tú reserves nada**. Ese es su precio, no se ve en el código, y es lo
primero que pregunta un entrevistador después de que escribas una función recursiva.

> **Regla de entrevista:** después de escribir una recursión, di sin que te lo pidan cuál es
> el caso base, por qué el problema se reduce en cada paso, y cuánta pila consume en el peor
> caso. Las tres cosas, en ese orden.

---

## 2. 🧱 Anatomía de una recursión

**Qué es.** Una función que se resuelve llamándose a sí misma sobre un problema estrictamente
más pequeño, hasta llegar a un caso que se resuelve sin llamarse.

**Cómo va.** Tres piezas, y ninguna es opcional:

```java
long factorial(int n) {
    if (n <= 1) return 1;            // 1. caso base: termina sin llamarse
    return n * factorial(n - 1);     // 2. paso recursivo sobre algo MENOR
}                                    // 3. el salto de fe: asumes que la llamada funciona
```

- El **caso base** es lo que hace que termine. Una recursión sin caso base alcanzable no es
  infinita: es un `StackOverflowError` en unos milisegundos.
- El argumento debe **decrecer hacia el caso base**. `factorial(n - 1)` decrece;
  `factorial(n / 2)` también; `factorial(n)` no, y `factorial(n - 1)` con `n` negativo
  tampoco, que es el bug clásico de esta función.
- El **salto de fe** es lo que hay que aprender a hacer: al escribir el paso recursivo, asume
  que la llamada devuelve lo correcto. Intentar desplegar mentalmente los niveles es lo que
  hace que la recursión parezca difícil.

**Cuánto cuesta.** Tiempo, lo que diga la recurrencia
([`01` §8](01-complejidad-y-o-grande.md#8--recurrencias-y-el-teorema-maestro)). Espacio,
**O(profundidad) siempre**, más lo que cada marco guarde.

**Cuándo sí.** Cuando la estructura del dato es recursiva —árboles, grafos, JSON anidado,
expresiones— o cuando la definición del problema lo es.

**Cuándo no.** Cuando la profundidad puede crecer con los datos sin cota conocida. Un
recorrido recursivo sobre una lista de un millón de elementos es un desbordamiento garantizado
en cualquiera de los cinco lenguajes.

> **Veredicto:** la recursión no es más elegante ni más lenta por decreto. Es la herramienta
> correcta cuando el dato es recursivo y la profundidad está acotada por el logaritmo del
> tamaño. Fuera de ahí, se convierte en iteración con pila explícita.

---

## 3. 🧱 La pila de llamadas

**Qué es.** Cada llamada en curso ocupa un **marco** (frame) con sus parámetros, sus variables
locales y la dirección de retorno. Los marcos se apilan; al retornar, se desapilan. Es el TDA
pila de [`02`](02-tdas-contrato-e-implementacion.md) implementado por la máquina.

```text
factorial(4)  ← marco 4, esperando
  factorial(3)  ← marco 3, esperando
    factorial(2)  ← marco 2, esperando
      factorial(1) → 1   ← se resuelve y empieza el desapilado
```

- La pila de un hilo de la JVM ronda **512 KB a 1 MB** por defecto, lo que da del orden de
  **10 000 a 20 000 marcos** según cuántas locales tenga cada uno. Se ajusta con `-Xss`, y
  subirlo es tratar el síntoma.
- Python es mucho más conservador: **1 000 niveles** por defecto
  (`sys.setrecursionlimit`), y lanza `RecursionError`, no un error de memoria. Es una
  decisión deliberada: prefiere fallar pronto y con un mensaje claro.
- Go es el único de los cinco con **pila que crece**: empieza en unos pocos KB y el runtime la
  reasigna hasta 1 GB. Una recursión profunda en Go funciona donde en Java revienta.

> 🩺 **Diagnóstico.** Ante un `StackOverflowError`, la pregunta no es "¿subo `-Xss`?". Es
> **"¿hay un ciclo en los datos?"**. Una recursión correcta sobre datos correctos rara vez
> pasa de unos cientos de niveles; miles de marcos idénticos en la traza significan casi
> siempre una referencia circular que nadie validó al insertar.

---

## 4. 🧱 Recursión de cola, y por qué en Java no sirve de nada

**Qué es.** Una recursión es *de cola* (tail recursive) cuando la llamada recursiva es **la
última operación** de la función: no queda nada por hacer con su resultado.

```java
// NO es de cola: después de la llamada queda una multiplicación pendiente
long factorial(int n) { return n * factorial(n - 1); }

// SÍ es de cola: la llamada es lo último, el acumulado viaja como parámetro
long factorial(int n, long acumulado) {
    if (n <= 1) return acumulado;
    return factorial(n - 1, n * acumulado);
}
```

- En la primera, el marco tiene que sobrevivir para multiplicar al volver. En la segunda no
  hace falta: el marco podría **reutilizarse**.
- Un compilador con *tail call optimization* convierte la segunda en un bucle y consume O(1)
  de pila. Scala lo hace con `@tailrec`, Kotlin con `tailrec`.
- **La JVM no lo hace.** Ni en Java 21. El motivo declarado es que las trazas de excepción y
  el modelo de seguridad basado en inspección de la pila dependen de que los marcos estén ahí.

**La consecuencia práctica:** escribir la versión de cola en Java **no te ahorra un solo
byte**. Si la profundidad es el problema, la solución es convertirla en iteración, con un
bucle o con una pila explícita (`ArrayDeque`).

> 📝 **Contexto.** Que "la recursión de cola es O(1) en espacio" es cierto en Scala, Kotlin,
> Go (parcialmente) y en cualquier funcional, y **falso en Java, Python y JavaScript**. La
> especificación de ECMAScript 6 incluyó TCO y prácticamente ningún motor la implementó
> —Safari es la excepción—, así que en la práctica JavaScript tampoco la tiene. Saber esa
> asimetría es una respuesta de nivel senior.

---

## 5. 🧱 Divide y vencerás

**Qué es.** Partir el problema en subproblemas **independientes** del mismo tipo, resolverlos
recursivamente y combinar.

```text
1. Dividir    → en a subproblemas de tamaño n/b
2. Vencer     → resolver cada uno recursivamente
3. Combinar   → unir los resultados
```

Los tres que hay que saber nombrar, con su recurrencia:

| Algoritmo | Divide | Combina | Recurrencia |
|---|---|---|---|
| **Búsqueda binaria** | en 2, usa 1 | nada | `T(n) = T(n/2) + O(1)` → O(log n) |
| **Merge sort** | en 2, usa 2 | fusión O(n) | `T(n) = 2T(n/2) + O(n)` → O(n log n) |
| **Quicksort** | partición O(n) | nada | igual en el caso medio; O(n²) si la partición es pésima |

- **Dónde está el trabajo** es lo que los distingue: merge sort trabaja al **combinar**,
  quicksort trabaja al **dividir**. Decir esa frase responde de golpe la pregunta "¿en qué se
  diferencian?".
- La independencia de los subproblemas es lo que separa divide y vencerás de la programación
  dinámica: cuando los subproblemas **se repiten**, divide y vencerás recalcula y la DP
  memoiza. Es el puente al bloque [`05-dp-y-tecnicas`](../05-dp-y-tecnicas/).

**Cuándo no.** Cuando dividir cuesta tanto como resolver, o cuando los subproblemas se
solapan: ahí la recursión pura explota exponencialmente y hay que memoizar.

> **Veredicto:** divide y vencerás es la forma de convertir un O(n²) en un O(n log n) cuando
> el problema se parte limpiamente. Si al partirlo los trozos se pisan, no es este patrón: es
> DP.

---

## 6. 🧱 Memoización

**El problema.** El Fibonacci recursivo ingenuo es O(2ⁿ): `fib(40)` hace más de dos mil
millones de llamadas, y casi todas recalculan algo ya calculado.

**Cómo va.** Guarda el resultado de cada entrada la primera vez que lo calculas:

```java
private final Map<Integer, Long> cache = new HashMap<>();

long fib(int n) {
    if (n <= 1) return n;
    return cache.computeIfAbsent(n, k -> fib(k - 1) + fib(k - 2));  // ver la advertencia
}
```

- Pasa de O(2ⁿ) a **O(n) en tiempo y O(n) en espacio**: cada valor se calcula una vez.
- Es programación dinámica **descendente**. La ascendente —llenar una tabla iterativamente—
  está en [`05-dp-y-tecnicas/01`](../05-dp-y-tecnicas/01-programacion-dinamica.md) y evita la
  pila por completo.

> ⚠️ **Advertencia.** Ese `computeIfAbsent` con recursión dentro **está mal en Java**: modifica
> el mapa mientras `computeIfAbsent` lo tiene bloqueado, y `HashMap` lanza
> `ConcurrentModificationException` desde Java 9. Es un bug real, frecuente y casi siempre
> silencioso en test. La versión correcta consulta y guarda en dos pasos: `Long v =
> cache.get(n); if (v != null) return v; ... cache.put(n, r);`. En Python el equivalente es
> `@functools.cache` y no tiene este problema.

---

## 7. 🧱 Backtracking

**Qué es.** Exploración sistemática de todas las combinaciones, **descartando ramas en cuanto
se sabe que no llevan a nada**. Es recursión con marcha atrás explícita.

**Cómo va.** El esqueleto es siempre el mismo, y memorizarlo vale por diez problemas:

```java
void explorar(Estado estado, List<Solucion> resultado) {
    if (esSolucion(estado)) { resultado.add(copiaDe(estado)); return; }
    for (Opcion opcion : opcionesDe(estado)) {
        if (!esViable(estado, opcion)) continue;   // poda: la mitad del rendimiento
        aplicar(estado, opcion);                   // elegir
        explorar(estado, resultado);               // explorar
        deshacer(estado, opcion);                  // deshacer  ← el paso que todos olvidan
    }
}
```

- **El `deshacer` es el patrón.** Sin él, el estado se contamina entre ramas y las soluciones
  salen mezcladas. Es el bug número uno de este tema.
- **El `copiaDe` también es obligatorio**: si añades el estado mutable al resultado, todas las
  soluciones apuntan al mismo objeto y al final están todas vacías.
- **La poda es donde está el rendimiento.** Sin poda, N reinas con n=8 explora 16 millones de
  tableros; con poda por columna y diagonal, unos 15 000.

**Cuánto.** Exponencial por naturaleza: O(2ⁿ) para subconjuntos, O(n!) para permutaciones. La
poda no cambia la cota, cambia la constante — y la cambia tanto que decide si termina.

**Cuándo sí.** Combinatoria con restricciones y n pequeño: subconjuntos, permutaciones, N
reinas, sudoku, particiones, generación de paréntesis válidos.

**Cuándo no.** Cuando n pasa de unos 25, o cuando los subproblemas se repiten: eso es DP.

> **Veredicto:** el backtracking es un solo esqueleto con distintos `esSolucion`, `opcionesDe`
> y `esViable`. Escribir el esqueleto de memoria y después rellenar los tres huecos es la
> forma correcta de atacar estos problemas en una entrevista.

---

## 8. ⏱️ La tabla de costes

| Patrón | Tiempo | Espacio de pila | Lo que la tabla no dice |
|---|---|---|---|
| Recursión lineal (`n-1`) | O(n) | **O(n)** | Es la que desborda. Casi siempre debería ser un bucle |
| Recursión binaria sobre árbol | O(n) | O(altura) | O(log n) si está equilibrado, O(n) si está degenerado |
| Divide y vencerás (`2T(n/2)+n`) | O(n log n) | O(log n) | La pila es logarítmica: esta sí es segura |
| Fibonacci ingenuo | O(2ⁿ) | O(n) | El espacio es lineal aunque el tiempo sea exponencial |
| Con memoización | O(n) | O(n) + O(n) | Se paga pila **y** mapa: dos veces O(n) |
| Backtracking | O(2ⁿ) o O(n!) | O(profundidad) | La poda no baja la cota, pero decide si termina hoy |

---

## 9. ⚖️ Los cinco lenguajes

| Lenguaje | Límite de profundidad | ¿TCO? | El detalle que muerde |
|---|---|---|---|
| **Java** | ~10 000–20 000 marcos, `-Xss` | **No** | Escribir la versión de cola no ahorra nada. `StackOverflowError` es un `Error`, no una `Exception` |
| **Python** | **1 000** por defecto | No | `sys.setrecursionlimit` lo sube y arriesga un fallo del intérprete. `@functools.cache` da memoización en una línea |
| **JavaScript** | ~10 000, depende del motor | En la especificación, no en los motores | `RangeError: Maximum call stack size exceeded`. Safari es el único con TCO real |
| **TypeScript** | Igual que JS | Igual que JS | Aporta tipos recursivos en compilación, con su propio límite de profundidad de instanciación |
| **Go** | **Pila que crece**, hasta ~1 GB | Parcial | Es el único donde la recursión profunda es viable. `goroutine stack exceeds limit` si se pasa |

> 💡 **Truco.** Si te preguntan "¿cuál es el problema de esta recursión?" y el código está
> bien, la respuesta esperada casi siempre es **la profundidad de pila**, y la respuesta cara
> añade el número concreto del lenguaje: mil en Python, decenas de miles en Java.

---

## 10. 🧭 Cómo se elige

```text
¿El dato es recursivo (árbol, grafo, JSON) y la profundidad es logarítmica? → recursión
¿La profundidad crece con n sin cota?                                      → iteración
   ¿y necesitas el orden de un recorrido en profundidad?                   → pila explícita

¿Los subproblemas son independientes?                                      → divide y vencerás
¿Los subproblemas se repiten?                                              → memoización → DP
¿Hay que generar todas las combinaciones con restricciones?                → backtracking
   ¿y n > 25?                                                              → no hay backtracking
                                                                              que valga: es DP
```

> **Regla mental:** recursión para bajar por una estructura, iteración para recorrer una
> secuencia. Si estás recorriendo una lista recursivamente, lo estás haciendo al revés.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La recursión de cola no consume pila" | Cierto en Scala y Kotlin; **falso en Java, Python y JavaScript** |
| "Esta recursión usa O(1) de espacio" | La pila es espacio: O(profundidad), siempre |
| "Subo `-Xss` y arreglado" | Trata el síntoma. Un desbordamiento con miles de marcos suele ser un ciclo en los datos |
| "Fibonacci recursivo es O(n)" | Es O(2ⁿ). Con memoización pasa a O(n), y son dos algoritmos distintos |
| "El backtracking prueba todo, la poda es un extra" | La poda es lo que hace que termine: de 16 millones a 15 000 en N reinas |
| "Añado el estado a la lista de soluciones" | Hay que añadir una **copia**: si no, todas las soluciones son el mismo objeto |
| "Uso `computeIfAbsent` para memoizar" | Con recursión dentro lanza `ConcurrentModificationException` desde Java 9 |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulo 4, divide y vencerás y el análisis de recurrencias.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Capítulo 9,
  búsqueda combinatoria: **la mejor explicación del backtracking con poda que hay**, con N
  reinas y sudoku completos.
- **Libro** — Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2018).
  Capítulo de recursión: los problemas están calibrados para entrevista y traen la discusión
  de pila.
- [Python — `sys.setrecursionlimit`](https://docs.python.org/3/library/sys.html):
  el límite de mil niveles, y la advertencia de por qué subirlo puede tumbar el intérprete.
- [Python — `functools.cache`](https://docs.python.org/3/library/functools.html):
  memoización en un decorador, con la comparación frente a `lru_cache`.
- [Java 21 API — `ArrayDeque`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/ArrayDeque.html):
  la estructura con la que se convierte una recursión en iteración.
- **Tutorial** — Baeldung, «Recursion In Java»: incluye la comparación con la versión
  iterativa y la discusión del `StackOverflowError`.
- **Video** — Abdul Bari, la serie sobre backtracking (N reinas, suma de subconjuntos):
  el trazado paso a paso del árbol de decisión es lo que hace que el patrón se fije.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Cuáles son las tres piezas obligatorias de una función recursiva? 🟢
2. ¿Qué es un marco de pila y qué guarda? 🟢
3. ¿Qué complejidad en espacio tiene una recursión de profundidad n? 🟢
4. ¿Qué complejidad tiene el Fibonacci recursivo sin memoización? 🟢
5. ¿Cuáles son los tres pasos del esqueleto de backtracking? 🟢
6. ¿Qué significa que una recursión sea "de cola"? 🟡
7. ¿Por qué la JVM no elimina la recursión de cola? 🟡
8. ¿En qué se diferencian divide y vencerás y programación dinámica? 🟡
9. ¿Dónde hace el trabajo merge sort y dónde lo hace quicksort? 🟡
10. ¿Qué diferencia hay entre memoización y tabulación? 🟡
11. ¿Cuántos niveles de recursión permite Python por defecto, y qué lanza al pasarse? 🟡
12. ¿Por qué el `deshacer` del backtracking no es opcional? 🟡
13. ¿Qué complejidad en espacio tiene una recursión sobre un árbol equilibrado? ¿Y sobre uno
    degenerado? 🟡
14. ¿Por qué hay que añadir una **copia** del estado a la lista de soluciones? 🟡
15. ¿Qué efecto tiene la poda sobre la complejidad asintótica del backtracking? 🟠
16. Te dan un `StackOverflowError` en producción con 20 000 líneas idénticas de traza. ¿Cuál
    es tu primera hipótesis y por qué no es subir `-Xss`? 🟠
17. ¿Por qué `computeIfAbsent` con una llamada recursiva dentro falla en Java 9+? 🟠
18. ¿Por qué Go puede recursar mucho más profundo que Java? 🟠
19. Escribir `factorial` en versión de cola en Java, ¿ahorra memoria? Justifica. 🟠
20. ¿Cuándo convertirías una recursión en iteración con pila explícita en vez de en un bucle
    simple? 🟠
21. La memoización cuesta O(n) de espacio en el mapa. ¿Cuánto cuesta en total contando la
    pila, y cómo lo bajas a O(1)? 🟠
22. En JavaScript, ¿existe la optimización de llamada de cola? Responde con matiz. 🟠
23. Escribe el backtracking que genera todos los subconjuntos de un conjunto de n elementos y
    di su complejidad en tiempo y espacio. 🔴
24. Te dan un recorrido recursivo de un árbol de categorías que falla en producción y no en
    test. Da tres hipótesis en orden de probabilidad. 🔴
25. Convierte el recorrido en profundidad recursivo de un árbol binario a iterativo, y di qué
    estructura usas y por qué el orden sale al revés si no tienes cuidado. 🔴

---

**Anterior:** [`03` — Arrays, listas y secuencias](03-arrays-listas-y-secuencias.md) ·
**Siguiente:** [`05` — Bits y aritmética binaria](05-bits-y-aritmetica-binaria.md) ·
**Relacionado:** [`05-dp-y-tecnicas/01` — Programación dinámica](../05-dp-y-tecnicas/01-programacion-dinamica.md)
