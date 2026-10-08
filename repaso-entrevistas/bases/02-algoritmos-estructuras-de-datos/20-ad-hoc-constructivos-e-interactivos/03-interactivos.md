# 03 — Interactivos

> Problemas en los que el juez no da toda la entrada al principio: responde a las preguntas del programa, una
> a una, y el programa tiene que acertar con un número limitado de preguntas. El protocolo, el `flush` que
> hace falta en los tres lenguajes y el veredicto *Idleness Limit Exceeded* cuando falta; la búsqueda binaria
> interactiva; y la cota de teoría de la información que dice cuántas preguntas hacen falta como mínimo.
>
> **Niveles:** el protocolo y el *flush* [B] · binaria interactiva [B].
>
> **📚 Lectura troncal:** la guía de Codeforces *Interactive Problems: Guide for Participants*, citada por
> título (su web responde `403` a `curl`); Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer,
> 2024), cap. 15.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--el-protocolo-y-el-flush) · [4](#4--binaria-interactiva) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

El juez esconde un número entre 1 y `10⁹`. El programa puede preguntar «¿es mayor que `x`?» y el juez
contesta. Con 30 preguntas hay que adivinarlo. La lógica es una búsqueda binaria de
[`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md); lo nuevo es el **diálogo**: el programa escribe una
pregunta, **la envía** y espera la respuesta antes de seguir.

El error clásico no está en la binaria: está en «la envía». La salida de un programa se guarda en un búfer y
se manda al otro lado cuando el búfer se llena o el programa termina. Si el programa pregunta sin vaciar el
búfer, la pregunta no llega; el juez espera la pregunta, el programa espera la respuesta, y nadie se mueve
hasta que salta el veredicto *Idleness Limit Exceeded*.

> 🧠 **Modelo mental.** Un problema interactivo es una conversación por una tubería: cada vez que hablas,
> tienes que **colgar** (*flush*) para que el otro oiga. Y cada respuesta que recibes es información: con
> respuestas de sí o no, cada pregunta como mucho parte las posibilidades por la mitad.

---

## 2. 📐 La teoría

**El protocolo.** El enunciado fija el formato de las preguntas (por ejemplo, `? x`), el de las respuestas,
cómo se da la respuesta final (`! x`) y el máximo de preguntas. Si el programa pregunta de más, o con un
formato inválido, el juez puede responder `-1`: hay que terminar en ese momento, o el veredicto será
confuso.

**Los búferes.** Con la salida conectada a una tubería, la librería estándar de C y C++ usa búfer completo
(no por líneas): la pregunta se queda en memoria hasta un `flush`. En Java, `PrintWriter` y
`BufferedWriter` también guardan hasta `flush()`. En Python, `print` a una tubería también tiene búfer.

**Cota de teoría de la información.** Si hay `N` respuestas posibles y cada pregunta tiene `b` respuestas
distintas, `q` preguntas distinguen como mucho `bᵠ` casos: hacen falta al menos `⌈log_b N⌉` preguntas. Con sí
o no y `N = 10⁹`, al menos 30. Con una balanza (tres resultados) y una moneda falsa más pesada entre `N`, al
menos `⌈log₃ N⌉` pesadas.

**El juez adaptativo.** Algunos jueces no fijan el secreto de antemano: responden de la forma que más
posibilidades deja abiertas, siempre de manera consistente. Contra uno así, la cota de la información es
exactamente lo que hay que cumplir en el peor caso: no hay suerte que valga.

---

## 3. 🧱 El protocolo y el *flush*

**Qué es.** La forma de hablar con el juez: escribir la pregunta, vaciar el búfer, leer la respuesta.

**Por qué es correcto.** El *flush* fuerza que lo escrito salga por la tubería en ese momento; sin él, la
pregunta puede quedarse en el búfer indefinidamente mientras el programa se bloquea leyendo.

**Cómo va**, con un secreto de 37 entre 1 y 100 y la pregunta «¿es mayor que `x`?»:

```text
programa → ? 50     juez → NO        el secreto está en [1, 50]
programa → ? 25     juez → YES       [26, 50]
programa → ? 38     juez → NO        [26, 38]
programa → ? 32     juez → YES       [33, 38]
programa → ? 35     juez → YES       [36, 38]
programa → ? 37     juez → NO        [36, 37]
programa → ? 36     juez → YES       [37, 37]
programa → ! 37
```

**Cuánto.** Lo que cueste la lógica; el *flush* es una llamada al sistema por pregunta, despreciable con unos
cientos o miles de preguntas.

**La plantilla:**

```cpp
#include <iostream>
#include <string>

// Pregunta «? x» y devuelve la respuesta. std::endl escribe el salto de línea y vacía el búfer.
std::string ask(long long x) {
    std::cout << "? " << x << std::endl;
    std::string reply;
    std::cin >> reply;
    if (reply == "-1") std::exit(0);                      // pregunta inválida o de más: terminar ya
    return reply;
}

void answer(long long x) { std::cout << "! " << x << std::endl; }
```

```java
static final java.io.BufferedReader IN =
    new java.io.BufferedReader(new java.io.InputStreamReader(System.in));
static final java.io.PrintWriter OUT = new java.io.PrintWriter(System.out);

static String ask(long x) throws java.io.IOException {
    OUT.println("? " + x);
    OUT.flush();                                           // sin esto, el juez no ve la pregunta
    String reply = IN.readLine().trim();
    if (reply.equals("-1")) System.exit(0);
    return reply;
}

static void answer(long x) { OUT.println("! " + x); OUT.flush(); }
```

- **`std::endl`** vacía; `'\n'` no. Con `std::ios::sync_with_stdio(false)` sigue haciendo falta el *flush*. Con
  `printf`, `fflush(stdout)`.
- **En Java**, `PrintWriter` sin `autoFlush` guarda hasta `flush()`; `System.out.println` vacía al escribir el
  salto de línea, pero es lento si las preguntas son muchas.
- **En Python**, `print(f"? {x}", flush=True)` y `input()`; `sys.stdout.flush()` si se usa `sys.stdout.write`.
- **Probar en local**: un interactor propio (un programa que hace de juez) conectado con tuberías, por ejemplo
  con dos procesos y `mkfifo`, o un *script* que lanza los dos. Probar a mano escribiendo las respuestas en la
  terminal también sirve para ver el diálogo.

**Cuándo sí:** siempre que el enunciado diga *interactive*. **Cuándo no:** en un problema normal, vaciar en
cada línea es un `flush` por línea y puede dar TLE con salidas grandes.

> **Veredicto:** en un interactivo, la mitad de los fallos son de protocolo: una pregunta sin *flush*, una
> respuesta `-1` que no se mira, un formato distinto del pedido. Escribe `ask` y `answer` primero, con el
> *flush* dentro.

---

## 4. 🧱 Binaria interactiva

**Qué es.** La búsqueda binaria de [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md) cuando cada
comparación es una pregunta al juez.

**Por qué es correcto.** El mismo invariante de la binaria: el secreto está siempre en `[lo, hi]`, y cada
respuesta descarta la mitad. Con `⌈log₂ N⌉` preguntas, el intervalo queda en un punto; y por la cota de §2,
no se puede hacer con menos en el peor caso.

**Cómo va.** La traza de §3: 7 preguntas para `N = 100`, que es `⌈log₂ 100⌉ = 7`.

**Cuánto.** `⌈log₂ N⌉` preguntas: 30 para `10⁹`, 60 para `10¹⁸`.

**La plantilla**, sobre `ask` de §3, con la pregunta «¿es el secreto mayor que `x`?»:

```cpp
// Secreto en [1, n]; ask(x) responde "YES" si el secreto es mayor que x.
long long findSecret(long long n) {
    long long lo = 1, hi = n;
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;
        if (ask(mid) == "YES") lo = mid + 1;              // el secreto está a la derecha de mid
        else hi = mid;                                     // el secreto es ≤ mid
    }
    return lo;
}
```

```java
static long findSecret(long n) throws java.io.IOException {
    long lo = 1, hi = n;
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (ask(mid).equals("YES")) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}
```

- **La forma de la pregunta decide el invariante**: «¿mayor que `x`?» con `lo = mid + 1` / `hi = mid`. Con
  «¿mayor o igual?», cambia.
- **No se pregunta cuando `lo == hi`**: esa pregunta gastaría una del límite sin información.
- **Con tres respuestas** (`<`, `=`, `>`), terminar en cuanto llegue `=` ahorra preguntas en promedio, no en el
  peor caso.

**Cuándo sí:** el juez responde a comparaciones; adivinar un número, un umbral, la primera posición que cumple
algo. **Cuándo no:** si las preguntas devuelven más información (una suma, una distancia), la binaria
desperdicia: se diseña una estrategia que use toda la respuesta.

> **Veredicto:** la binaria interactiva es la de siempre con `ask` en lugar de `a[mid]`. Lo que cambia es que
> el límite de preguntas es la cota de la información, sin margen.

---

## 5. ⏱️ La tabla de costes

| Situación | Preguntas mínimas | Lo que la tabla no dice |
|---|---|---|
| Adivinar uno de `N` con sí/no | `⌈log₂ N⌉` | 30 para `10⁹`; el juez puede ser adaptativo |
| Con una balanza (3 resultados) | `⌈log₃ N⌉` | Hay que usar los tres resultados en cada pesada |
| Ordenar `n` elementos por comparaciones | `⌈log₂ n!⌉ ≈ n log₂ n` | La mezcla se acerca a la cota |
| Una pregunta que devuelve un número | `⌈log_{rango} N⌉` | Se diseña la pregunta para aprovechar la respuesta |

---

## 6. 🧭 Cómo se elige

```text
1. Escribe ask y answer con el flush dentro, y el caso −1
2. Calcula la cota: ⌈log_b N⌉ con b respuestas posibles por pregunta. ¿Coincide con el límite?
3. Si coincide, cada pregunta tiene que partir las posibilidades en b partes casi iguales
4. Prueba con un interactor local, también con un juez adaptativo
```

> **Regla de entrevista:** si te dan un límite de preguntas, compáralo con `log₂` del número de posibilidades:
> te dice cuánta información tiene que sacar cada pregunta y si basta una binaria.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «This is an interactive problem» | Protocolo con *flush* | El juez responde a cada pregunta |
| «Como mucho 30 preguntas», `n = 10⁹` | Binaria | `⌈log₂ 10⁹⌉ = 30` |
| «Como mucho `⌈log₃ n⌉` pesadas» | Partir en tres | La balanza tiene tres resultados |
| «El juez puede cambiar el secreto si es consistente» | Peor caso estricto | Juez adaptativo |
| «Ordena con como mucho `n log n` comparaciones» | Mezcla con `ask` | Cota de ordenación |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La salida se vacía sola» | Con la salida en una tubería, no: sin *flush*, la pregunta no llega y salta *Idleness Limit Exceeded* |
| «`'\n'` y `std::endl` son lo mismo» | `std::endl` además vacía el búfer; en un interactivo es lo que hace falta |
| «Si el juez responde `-1`, sigo» | Hay que terminar: el siguiente veredicto sería confuso (WA en vez de la causa) |
| «Con suerte basta con menos preguntas» | Con un juez adaptativo, el peor caso es el que ocurre |
| «En local funciona, en el juez da ILE» | En local la salida es una terminal (búfer por líneas); en el juez, una tubería |
| «Preguntar cuando ya sé la respuesta no cuesta nada» | Gasta una pregunta del límite |

---

## 📚 Para profundizar

- **Referencia** — la guía de Codeforces *Interactive Problems: Guide for Participants*, por título: el
  protocolo, el *flush* en cada lenguaje y el veredicto *Idleness Limit Exceeded*. *Lectura troncal.*
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 15. *Lectura
  troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009), §8.1:
  la cota del árbol de decisión, que es la misma cuenta de información.

---

## 🧠 Preguntas

1. ¿Qué es un problema interactivo? 🟢
2. ¿Qué es el veredicto *Idleness Limit Exceeded* y qué lo causa casi siempre? 🟢
3. ¿Cuántas preguntas de sí o no hacen falta para adivinar un número entre 1 y `10⁹`? 🟢
4. ¿Qué diferencia hay entre `'\n'` y `std::endl` en un interactivo? 🟡
5. ¿Qué es un juez adaptativo y qué cambia para tu estrategia? 🟡
6. ¿Por qué un programa que funciona en la terminal da ILE en el juez? 🟡
7. ¿Cómo se vacía la salida en C++, Java y Python? 🟠
8. ¿Qué haces si el juez responde `-1`, y por qué? 🟠
9. ¿Cuántas pesadas hacen falta para encontrar la moneda más pesada entre 27, y cómo se reparten? 🟠
10. ¿Cómo pruebas un interactivo en local? 🟠
11. Demuestra que `⌈log_b N⌉` preguntas con `b` respuestas posibles son necesarias en el peor caso. 🔴
12. Con dos huevos y un edificio de 100 pisos, ¿cuántos lanzamientos hacen falta en el peor caso para saber el
    piso más alto desde el que no se rompen, y con qué estrategia? 🔴

---

## 🧩 Problemas propios

### La moneda pesada

**Nivel:** 🟠 · **Formato:** programa interactivo.

Hay `n` monedas numeradas del 1 al `n`; una pesa más que las demás. Cada pesada compara dos grupos del mismo
tamaño: escribe `? k a₁ … aₖ b₁ … bₖ` y el juez responde `<` (pesa más el segundo grupo), `>` (pesa más el
primero) o `=`. Cuando la sepas, escribe `! i`. Tienes como mucho `⌈log₃ n⌉` pesadas.

- **Entrada inicial.** Una línea con `n`.
- **Restricciones.** `1 ≤ n ≤ 10⁵`. Las monedas de un grupo son distintas y los dos grupos no se solapan. El
  juez es adaptativo.

```text
juez         programa
3
             ? 1 1 2
=
             ! 3
```

**Pista 1:** con tres resultados posibles por pesada, ¿en cuántos grupos tienes que partir las candidatas para
que cualquier resultado deje como mucho un tercio?

### Dos huevos

**Nivel:** 🔴 · **Formato:** programa interactivo.

Un edificio tiene `n` pisos. Un huevo se rompe si se lanza desde el piso `f + 1` o más alto, y no se rompe
desde el `f` o más bajo (`0 ≤ f ≤ n`). Tienes **dos** huevos. Escribe `? p` para lanzar uno desde el piso `p`;
el juez responde `ROTO` o `ENTERO`, y un huevo roto no se puede volver a usar. Cuando lo sepas, escribe
`! f`. Tienes como mucho `q` lanzamientos, el menor entero con `q(q + 1)/2 ≥ n`.

- **Entrada inicial.** Una línea con `n` y `q`.
- **Restricciones.** `1 ≤ n ≤ 10⁶`. Lanzar con los dos huevos rotos, o pasarse de `q`, es respuesta incorrecta.

```text
juez         programa
10 4
             ? 4
ENTERO
             ? 7
ROTO
             ? 5
ENTERO
             ? 6
ENTERO
             ! 6
```

**Pista 1:** si el primer huevo se rompe en el lanzamiento `i`, al segundo le quedan `q − i` lanzamientos y
tiene que ir piso a piso. ¿Desde qué piso conviene lanzar el primero cada vez?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de enviar un interactivo, pruébalo contra un interactor tuyo que cuente las preguntas y
> se comporte de forma adaptativa. Si una IA te ayuda, que sea a escribir ese interactor
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Hidden Integer](https://cses.fi/problemset/task/3112) | CSES | 🟢 | Binaria | ¿Cuántas preguntas permite el enunciado, y qué cota da `log₂` del rango? |
| [ ] | [Interview](https://codeforces.com/problemset/problem/1807/E) | Codeforces | 🟡 | Binaria sobre montones | Si preguntas por la suma de una mitad de los montones, ¿cómo sabes si el más pesado está ahí? |
| [ ] | [Bear and Prime 100](https://codeforces.com/problemset/problem/679/A) | Codeforces | 🟡 | Divisores | ¿Qué divisores tiene un compuesto menor que 100, y cuántos primos pequeños hay que probar? |
| [ ] | [Lost Numbers](https://codeforces.com/problemset/problem/1167/B) | Codeforces | 🟡 | Productos distintos | Con 4 preguntas de productos, ¿qué productos de los 6 números especiales son únicos? |
| [ ] | [Hidden Permutation](https://cses.fi/problemset/task/3139) | CSES | 🟠 | Ordenar por comparaciones | ¿Qué algoritmo de ordenación usa pocas comparaciones en el peor caso? |
| [ ] | [Guess the K-th Zero (Easy version)](https://codeforces.com/problemset/problem/1520/F1) | Codeforces | 🟠 | Binaria con sumas | Si preguntas la suma de un prefijo, ¿cuántos ceros sabes que hay en él? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Fixed Point Guessing](https://codeforces.com/problemset/problem/1698/D) | Codeforces | 🟠 | Binaria por paridad | Si preguntas por un tramo, ¿cuántos de sus elementos ordenados siguen en el tramo, y qué dice la paridad? |
| [ ] | [Colored Chairs](https://cses.fi/problemset/task/3273) | CSES | 🟠 | Binaria sobre un tramo | Si un tramo tiene un número impar de sillas y sus extremos son de colores distintos, ¿por qué contiene dos vecinas del mismo color, y cómo lo partes sin perder eso? |
| [ ] | [Permuted Binary Strings](https://cses.fi/problemset/task/3228) | CSES | 🟠 | Codificar posiciones en bits | Si preguntas por la cadena del bit `j` de cada índice, ¿qué aprendes de cada posición? |
| [ ] | [K-th Highest Score](https://cses.fi/problemset/task/3305) | CSES | 🔴 | Binaria en dos arreglos | Comparando el elemento `i` de uno con el `k − i` del otro, ¿qué mitad descartas? |

---

## ✅ Criterio de dominio

- Escribir `ask` y `answer` con *flush* y el caso `-1` en C++ y Java sin mirar.
- Calcular la cota de preguntas de un problema con `log_b N`.
- Explicar por qué un programa sin *flush* funciona en la terminal y da ILE en el juez.
- Resolver Hidden Integer, Interview y Bear and Prime 100 sin pista 2.

---

**Anterior:** [`20/02` — Constructivos](02-constructivos.md) · **Siguiente:** [`20/04` — El estilo de las pruebas de empresa](04-el-estilo-de-las-pruebas-de-empresa.md) ·
**Relacionado:** [`05/04` — Búsqueda binaria](../05-orden-y-busqueda/04-busqueda-binaria.md).
