# 03 — Máquinas de Turing y decidibilidad

> **Opcional.** Ningún capítulo del hilo principal depende de este. El modelo que define qué es un algoritmo,
> por qué todos los lenguajes de programación calculan exactamente lo mismo, y el primer problema que ningún
> programa puede resolver: decidir si otro programa termina. Y lo que eso **no** significa: con memoria
> finita, la parada sí se decide.
>
> **Niveles:** la máquina de Turing y su simulación [A] · la tesis de Church-Turing [B] · el problema de la
> parada y las reducciones [A] · el teorema de Rice [C].
>
> **📚 Lectura troncal:** Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y
> computación*, 3.ª ed. (Pearson, 2007), caps. 8 y 9.
>
> **Asume leído:** [`22/01` — Lenguajes y gramáticas](01-lenguajes-y-gramaticas.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--la-máquina-de-turing-y-su-simulación) · [4](#4--la-tesis-de-church-turing) · [5](#5--el-problema-de-la-parada-y-las-reducciones) · [6](#6--el-teorema-de-rice) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [9](#9--dónde-aparece-de-verdad) · [🧠](#-preguntas)

---

## 1. 🎯 El problema

El equipo de plataforma quiere una regla en el *pipeline*: «rechazar cualquier cambio que introduzca un bucle
infinito». Alguien propone un analizador que lea el código y lo decida. No existe, y no por falta de
tiempo: **Turing demostró en 1936 que ningún programa puede decidir, para todo programa y toda entrada, si
termina**. Lo que existe son aproximaciones —un límite de tiempo, un analizador que avisa de los casos
evidentes y calla en el resto— y saber eso evita prometer lo imposible en una reunión de diseño.

La segunda mitad de la historia es igual de útil: el teorema habla de máquinas con **memoria sin límite**. Un
programa con memoria acotada tiene un número finito de configuraciones, y para él la parada sí se decide, con
el principio del palomar. «Indecidible» es una afirmación sobre todas las entradas posibles, no un «es
difícil».

> 🧠 **Modelo mental.** Una máquina de Turing es el programa más simple que se puede imaginar con memoria
> infinita: una cinta, una cabeza y una tabla. Todo lo que tu ordenador calcula, ella lo calcula; lo que ella
> no puede, tu ordenador tampoco.

---

## 2. 📐 La teoría

**Máquina de Turing (MT).** Un conjunto finito de estados, un alfabeto de cinta con un símbolo **blanco**,
una cinta infinita en las dos direcciones y una cabeza. La función de transición `δ(q, X) = (p, Y, D)` dice:
en el estado `q`, leyendo `X`, escribe `Y`, pasa a `p` y mueve la cabeza a la izquierda o a la derecha. La
máquina **para** al llegar a un estado de parada (o a un par `(q, X)` sin transición). Una **configuración**
es el triple (estado, contenido de la cinta, posición de la cabeza).

**Decidible y semidecidible.** Un lenguaje es **decidible** (recursivo) si alguna MT lo acepta y **para
siempre**, diga sí o no. Es **semidecidible** (recursivamente enumerable) si alguna MT para y acepta en las
cadenas del lenguaje, aunque en las otras pueda no parar nunca. Todo decidible es semidecidible; lo contrario
no.

**Teorema (Turing, 1936).** El problema de la parada, `HALT = {(M, x) : M para con la entrada x}`, es
semidecidible y **no es decidible**.

**Teorema.** Un lenguaje es decidible si y solo si él y su complemento son semidecidibles. Por eso el
complemento de `HALT` («`M` no para con `x`») ni siquiera es semidecidible.

**Reducción de computabilidad.** `A` se reduce a `B` si una función computable transforma cada entrada de
`A` en una de `B` con la misma respuesta. Si `A` es indecidible y `A` se reduce a `B`, `B` es indecidible. Es
la misma idea que las reducciones polinomiales de [`22/04`](04-p-np-y-reducciones.md), sin límite de tiempo.

---

## 3. 🧱 La máquina de Turing y su simulación

**Qué es.** La tabla de transiciones y una cinta. Una máquina que suma 1 a un número binario: en el estado
`r` va a la derecha hasta el primer blanco; en `c` vuelve sumando con acarreo.

```text
δ(r, 0) = (r, 0, →)    δ(r, 1) = (r, 1, →)    δ(r, _) = (c, _, ←)
δ(c, 1) = (c, 0, ←)    δ(c, 0) = (H, 1, ←)    δ(c, _) = (H, 1, ←)       H = parada
```

**Por qué es correcto.** Por el invariante del estado `c`: todo lo que está a la derecha de la cabeza ya es
la parte baja del resultado (ceros), y el número de la izquierda más el 1 pendiente vale lo mismo que la
entrada más uno. Al encontrar un `0` (o un blanco), escribir `1` cierra la suma.

**Cómo va**, con `1011` (once), en 8 pasos:

```text
r  [1]011        r  1[0]11        r  10[1]1        r  101[1]
r  1011[_]       c  101[1]_       c  10[1]0_       c  1[0]00_
H  1100 (doce)
```

**Cuánto.** La simulación cuesta `O(1)` por paso si la cinta es una buena estructura de datos, y `O(T)` en
total para `T` pasos. La máquina misma suele ser lenta en términos de pasos (una MT de una cinta necesita
`Θ(n²)` pasos para reconocer palíndromos), pero eso es cosa del modelo, no de la simulación.

**La plantilla**, un simulador de una cinta con la cinta como **dos pilas** (lo que hay a la izquierda de la
cabeza y lo que hay a la derecha), estado inicial 0 y un límite de pasos:

```cpp
#include <map>
#include <string>
#include <utility>
#include <vector>

struct Rule { char write; int move; int next; };          // move: −1 izquierda, +1 derecha

// Simula una MT de una cinta desde el estado 0. Devuelve el estado final, o −1 si agotó 'limit'.
// Deja en 'steps' los pasos dados y en 'tape' la cinta final (si agotó el límite, 'tape' no se toca).
int runTm(const std::map<std::pair<int, char>, Rule>& delta, int halt, std::string& tape,
          char blank, long long limit, long long& steps) {
    std::vector<char> left, right(tape.rbegin(), tape.rend());   // la cima de cada pila toca la cabeza
    char cur = blank;
    if (!right.empty()) { cur = right.back(); right.pop_back(); }
    int q = 0;
    for (steps = 0; q != halt; steps++) {
        if (steps == limit) return -1;
        auto it = delta.find({q, cur});
        if (it == delta.end()) break;                           // sin transición: se detiene
        const Rule& r = it->second;
        std::vector<char>& from = r.move > 0 ? right : left;    // de dónde sale la celda nueva
        std::vector<char>& to = r.move > 0 ? left : right;      // dónde queda la que se escribió
        to.push_back(r.write);
        if (from.empty()) cur = blank; else { cur = from.back(); from.pop_back(); }
        q = r.next;
    }
    tape.assign(left.begin(), left.end());
    tape.push_back(cur);
    tape.append(right.rbegin(), right.rend());
    return q;
}
```

```java
import java.util.Map;

// Misma simulación. delta: clave = estado * 256 + símbolo; valor = {escribe, mueve (−1 o +1), siguiente}.
static long steps;

static int runTm(Map<Integer, int[]> delta, int halt, StringBuilder tape, char blank, long limit) {
    StringBuilder left = new StringBuilder(), right = new StringBuilder(tape).reverse();
    char cur = blank;
    if (right.length() > 0) { cur = right.charAt(right.length() - 1); right.setLength(right.length() - 1); }
    int q = 0;
    for (steps = 0; q != halt; steps++) {
        if (steps == limit) return -1;
        int[] r = delta.get(q * 256 + cur);
        if (r == null) break;                                    // sin transición: se detiene
        StringBuilder from = r[1] > 0 ? right : left, to = r[1] > 0 ? left : right;
        to.append((char) r[0]);
        if (from.length() == 0) cur = blank;
        else { cur = from.charAt(from.length() - 1); from.setLength(from.length() - 1); }
        q = r[2];
    }
    tape.setLength(0);
    tape.append(left).append(cur).append(right.reverse());
    return q;
}
```

```python
def run_tm(delta, halt, tape, blank, limit):
    """Simula una MT desde el estado 0. delta[(q, símbolo)] = (escribe, mueve ±1, siguiente).
    Devuelve (estado final o -1 si agotó el límite, pasos, cinta)."""
    left, right = [], list(reversed(tape))
    cur = right.pop() if right else blank
    q, steps = 0, 0
    while q != halt:
        if steps == limit:
            return -1, steps, None
        rule = delta.get((q, cur))
        if rule is None:                     # sin transición: se detiene
            break
        write, move, q = rule
        src, dst = (right, left) if move > 0 else (left, right)
        dst.append(write)
        cur = src.pop() if src else blank
        steps += 1
    return q, steps, ''.join(left) + cur + ''.join(reversed(right))
```

- **Las dos pilas** son la idea entera: moverse a la derecha es pasar la celda actual a la pila izquierda y
  sacar la nueva de la derecha, y viceversa. Una pila vacía es cinta en blanco, así que la cinta crece sola en
  las dos direcciones.
- **El límite de pasos** es obligatorio: sin él, el simulador hereda el problema de la parada (§5).
- **En Java**, `StringBuilder` hace de pila de `char` sin *boxing*; un `ArrayDeque<Character>` funcionaría con
  un objeto por celda. **En Python**, dos listas con `append` y `pop`, `O(1)` amortizado.
- **Con la plantilla se comprueban los castores atareados** de dos estados (para tras 6 pasos con 4 unos) y de
  cuatro (107 pasos, 13 unos), que son los récords de su tamaño.

### De la versión ingenua a la buena

**El problema.** Simular `T` pasos de una MT cuya cabeza puede ir arbitrariamente a la izquierda de donde
empezó: por ejemplo, una que escribe `1` y se mueve a la izquierda `T` veces.

**La versión ingenua**, la cinta como una cadena con un índice para la cabeza:

```java
// Ingenua: cinta en un StringBuilder; ir a la izquierda del borde inserta un blanco al principio. O(T²).
static int runNaive(Map<Integer, int[]> delta, int halt, StringBuilder tape, char blank, long limit) {
    if (tape.length() == 0) tape.append(blank);
    int head = 0, q = 0;
    for (long s = 0; q != halt && s < limit; s++) {
        int[] r = delta.get(q * 256 + tape.charAt(head));
        if (r == null) break;
        tape.setCharAt(head, (char) r[0]);
        head += r[1];
        if (head < 0) { tape.insert(0, blank); head = 0; }          // corre toda la cinta: O(longitud)
        if (head == tape.length()) tape.append(blank);
        q = r[2];
    }
    return q;
}
```

> «Es correcta, pero cada vez que la cabeza sale por la izquierda, `insert(0, …)` mueve la cinta entera. Una
> máquina que avanza a la izquierda `T` veces hace `1 + 2 + … + T` copias: cuadrático. El problema es que la
> cadena solo crece barato por un extremo, y la cinta crece por los dos.»

**El camino a la buena.** Partir la cinta en dos por la cabeza: lo de la izquierda en una pila con la cima en
la cabeza, lo de la derecha en otra. Cada movimiento es un `push` y un `pop`, `O(1)`. Es la plantilla de
arriba; lo que cambió es solo la estructura de la cinta. Un `ArrayDeque` o un arreglo circular que crece por
los dos lados ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)) también sirven.

**Cuándo sí:** comprobar una máquina diseñada a mano, explorar castores atareados, simular cualquier modelo
de cinta (autómatas celulares de una dimensión, intérpretes de lenguajes esotéricos). **Cuándo no:** para
calcular algo de verdad, una MT es un modelo teórico, no una herramienta; se programa en el lenguaje.

> **Veredicto:** una máquina de Turing es una tabla y una cinta, y su simulación es un bucle con dos pilas.
> Lo difícil no es simularla: es saber cuándo parar de simularla.

---

## 4. 🧱 La tesis de Church-Turing

**Qué es.** La afirmación de que **todo lo que es calculable por un procedimiento efectivo lo calcula una
máquina de Turing**. No es un teorema: «procedimiento efectivo» es una noción intuitiva, y la tesis dice que
la MT la captura entera.

**Por qué es correcto** (el enunciado y una frase): no se demuestra, pero todos los modelos propuestos
—cálculo λ, funciones recursivas, máquinas de varias cintas, máquinas RAM, cualquier lenguaje de programación
con memoria sin límite— resultaron equivalentes, y cada equivalencia sí es un teorema con su simulación.

**Cómo va.** Las simulaciones que la sostienen, y su coste:

```text
MT de k cintas         → MT de una cinta           O(T²) pasos para T pasos
máquina RAM            → MT                        polinomial en T
MT                     → programa en Java/Python   O(T): la plantilla de §3
programa en Java       → MT universal              un intérprete: lee la tabla de M y la ejecuta
```

La **máquina universal** es la última fila: una MT que recibe la descripción de otra, `⟨M⟩`, y una entrada, y
hace lo que `M` haría. Es la idea del ordenador de programa almacenado y de cualquier intérprete.

**Cuánto.** Las simulaciones entre modelos razonables cuestan un **polinomio**. Por eso la clase P de
[`22/04`](04-p-np-y-reducciones.md) no depende del modelo: lo que es polinomial en Java lo es en una MT. La
excepción conocida son los ordenadores cuánticos, que (se cree) calculan lo mismo pero algunas cosas más
rápido.

**La plantilla.** No hay: es una tesis.

**Cuándo sí:** para pasar de «no hay una MT que lo decida» a «no hay ningún programa que lo decida», que es la
frase que importa. **Cuándo no:** para hablar de eficiencia más allá de lo polinomial: las simulaciones
cambian el exponente.

> **Veredicto:** la tesis de Church-Turing es la razón por la que un resultado sobre máquinas de Turing es un
> resultado sobre tu lenguaje de programación. No se demuestra; se apoya en que ningún modelo la ha roto.

---

## 5. 🧱 El problema de la parada y las reducciones

**Qué es.** El problema de decidir, dados un programa `P` y una entrada `x`, si `P` termina con `x`.

**Por qué es correcto** que no se puede decidir, por **contradicción** y **diagonalización**. Supón que
existe `halts(P, x)`, que siempre termina y responde bien. Construye con ella este programa:

```java
// no compila: halts no puede existir, y eso es lo que se demuestra
static void diagonal(String p) {
    if (halts(p, p)) while (true) { }      // si P para consigo mismo, D se cuelga
    // si no, D termina
}
```

y pregunta qué hace `diagonal` con su propio código `d`. Si `halts(d, d)` dice que para, `diagonal(d)` entra
en el bucle y no para; si dice que no para, `diagonal(d)` termina. En los dos casos `halts` se equivoca con
`(d, d)`: no puede existir. Es el argumento de Cantor de que los reales no se pueden numerar: `diagonal`
difiere de cada programa `P` en su comportamiento con la entrada `P`.

**Cómo va**, la cadena de reducciones que extiende el resultado:

```text
HALT                         → ¿P imprime «hola» con x?      (P' = ejecuta P(x) y después imprime «hola»)
¿P imprime «hola»?           → ¿P y Q hacen lo mismo?       (Q = el programa que imprime «hola» y para)
HALT                         → ¿P para con alguna entrada?  (P' ignora su entrada y ejecuta P(x))
correspondencia de Post      → ¿es ambigua esta gramática?   (22/01: indecidible)
```

Cada flecha dice «si supiera decidir lo de la derecha, decidiría lo de la izquierda», y la izquierda ya es
indecidible.

**Semidecidible sí.** Simular `P(x)` y decir «sí» si termina responde bien en todos los casos «sí»; en los
«no», la simulación no acaba. Es la plantilla de §3 sin límite de pasos.

**Cuánto.** No hay algoritmo, así que no hay coste. Lo que sí hay es un coste de las **aproximaciones**: un
límite de pasos responde siempre pero se equivoca con los programas lentos; un analizador estático responde
siempre pero se equivoca, o calla, con los difíciles.

**La plantilla.** No hay para el teorema. Lo que se escribe es la decisión en el caso que sí es decidible:
memoria finita, en el ejemplo trabajado.

### De la versión ingenua a la buena

**El problema.** Una máquina con un solo registro `r` de 8 bits (empieza en 0 y da la vuelta: `255 + 1 = 0`)
y un programa de `L` instrucciones: `INC`, `DEC`, `JZ t` (salta a `t` si `r = 0`), `JMP t` y `HALT`. ¿Termina?
La configuración es el par `(pc, r)`: hay `256 · L` como mucho.

```text
programa A (L = 7)          programa B (L = 6)          programa C (L = 4)
0 INC                       0 INC                       0 INC
1 INC                       1 INC                       1 JZ 3
2 INC                       2 INC                       2 JMP 0
3 JZ 6                      3 JZ 5                      3 HALT
4 DEC                       4 JMP 1
5 JMP 3                     5 HALT
6 HALT
para en 13 pasos            nunca para: r siempre impar  para en 767 pasos (r da la vuelta)
```

**La versión ingenua**, que guarda cada configuración vista y la busca en una lista:

```java
static final int INC = 0, DEC = 1, JZ = 2, JMP = 3, HALT = 4;

// Ingenua: lista de configuraciones vistas; repetir una es un bucle. Correcta, O(T²) con T ≤ 256·L.
static boolean haltsNaive(int[] op, int[] target) {
    List<int[]> seen = new ArrayList<>();
    int pc = 0, r = 0;
    while (pc < op.length && op[pc] != HALT) {
        for (int[] c : seen) if (c[0] == pc && c[1] == r) return false;   // ya estuvo aquí: no para
        seen.add(new int[]{pc, r});
        switch (op[pc]) {
            case INC -> { r = (r + 1) & 255; pc++; }
            case DEC -> { r = (r + 255) & 255; pc++; }
            case JZ -> pc = r == 0 ? target[pc] : pc + 1;
            default -> pc = target[pc];                                      // JMP
        }
    }
    return true;
}
```

> «Es correcta: la máquina es determinista, así que si repite una configuración, repite todo lo que viene
> después, para siempre. Pero cada paso recorre la lista entera: con `L = 1000`, `T` llega a `2,6·10⁵` y la
> búsqueda a `3·10¹⁰`. Y en realidad no necesito saber **cuál** se repite, solo **que** alguna se repite.»

**El camino a la buena.** El palomar: hay como mucho `256 · L` configuraciones, así que una ejecución de más
de `256 · L` pasos repitió alguna. Basta con contar.

```java
// Por el palomar: más de 256·L pasos sin parar es un bucle. O(256·L) tiempo, O(1) memoria.
static boolean halts(int[] op, int[] target) {
    long limit = 256L * op.length;
    int pc = 0, r = 0;
    for (long step = 0; step <= limit; step++) {
        if (pc >= op.length || op[pc] == HALT) return true;
        switch (op[pc]) {
            case INC -> { r = (r + 1) & 255; pc++; }
            case DEC -> { r = (r + 255) & 255; pc++; }
            case JZ -> pc = r == 0 ? target[pc] : pc + 1;
            default -> pc = target[pc];
        }
    }
    return false;                                     // alguna configuración se repitió
}
```

- **El programa B** repite `(pc = 1, r = 1)` en el paso 513: el bucle mide 512 pasos (128 vueltas de cuatro
  instrucciones). La cota `256 · 6 = 1 536` lo detecta con margen.
- **El programa C** parece un bucle infinito y no lo es: `r` da la vuelta a 0 tras 256 incrementos y el `JZ`
  sale. Un límite de tiempo «razonable» de 500 pasos lo habría declarado colgado.
- **Para encontrar el bucle exacto** (dónde empieza y cuánto mide) con memoria `O(1)`, el algoritmo de Floyd de
  [`06/02`](../06-lineales-y-hashing/02-listas-enlazadas.md) sobre la función «configuración → siguiente».

**Lo que esto no contradice.** El teorema de Turing habla de memoria **sin límite**. Un ordenador real tiene
memoria finita, así que «en teoría» su parada es decidible, con una cota de `2^(bits de memoria)` pasos: un
número sin sentido práctico. Por eso, en la práctica, se razona como si la memoria fuera infinita.

**Cuándo sí:** decir con precisión qué no se puede automatizar (detectar bucles infinitos, decidir si dos
programas son equivalentes) y qué sí (con memoria acotada y pequeña, o con un límite de pasos que se acepta
como aproximación). **Cuándo no:** para concluir que un problema concreto es imposible en la práctica: muchos
casos particulares de un problema indecidible se resuelven bien.

> **Veredicto:** la parada es semidecidible y no decidible, y la prueba cabe en cuatro líneas de diagonal. Con
> memoria acotada, el palomar la convierte en decidible: indecidible es «sin algoritmo para todas las
> entradas», no «difícil».

---

## 6. 🧱 El teorema de Rice

**Qué resuelve.** Generaliza la parada a cualquier pregunta sobre lo que **hace** un programa: ¿devuelve
siempre un número positivo?, ¿acepta un lenguaje regular?, ¿calcula la misma función que este otro?

**Qué garantiza.** Toda propiedad **no trivial** (la cumplen algunos programas y otros no) y **semántica**
(depende solo de la función que calcula el programa, no de cómo está escrito) es indecidible.

**Cuánto.** No hay algoritmo. Las propiedades **sintácticas** («¿tiene más de diez líneas?», «¿usa la
variable `x`?») sí son decidibles, y por eso un *linter* puede comprobarlas.

**Cómo reconocerlo.** La pregunta es sobre el comportamiento de un programa arbitrario, para todas las
entradas, y la respuesta no cambia si se reescribe el programa sin cambiar lo que calcula.

**Si no te la sabes.** Reduce desde la parada a mano: construye un programa que primero simula `P(x)` y
después hace algo que cumple la propiedad.

**Dónde está entera.** Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y
computación*, 3.ª ed. (Pearson, 2007), §9.3.

---

## 7. 🧭 Cómo se elige

```text
¿Te piden decidir algo sobre lo que HACE un programa arbitrario?
    → indecidible (Rice); ofrece una aproximación y di qué error comete
¿La memoria o el estado del sistema son finitos y pequeños?
    → decidible por el palomar: contar configuraciones, o Floyd
¿Basta con responder «sí» cuando la respuesta es sí?
    → semidecidible: simular, con o sin límite
¿La pregunta es sobre el texto del programa, no sobre su comportamiento?
    → decidible: es un análisis sintáctico
¿Es decidible pero lento?
    → eso es complejidad, no computabilidad: 22/04
```

> **Regla de entrevista:** si te piden «detectar bucles infinitos en el código», di **problema de la parada**,
> ofrece dos aproximaciones (límite de tiempo, análisis estático conservador) y di qué falla en cada una.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Detectar si un programa termina / se cuelga» | Indecidible: aproximar | Problema de la parada |
| «¿Hacen lo mismo estos dos programas?» | Indecidible en general | Rice |
| «Máquina con estado finito: ¿llega a parar? ¿entra en bucle?» | Palomar o Floyd | Configuraciones finitas |
| «Simular un autómata con cinta / memoria que crece por los dos lados» | Dos pilas o deque | `O(1)` por paso |
| «Un intérprete de un lenguaje mínimo» | Simulación con límite de pasos | La MT universal, con freno |

---

## 9. 🔭 Dónde aparece de verdad

- **Los analizadores estáticos** (los avisos del compilador, los detectores de errores) son aproximaciones
  por Rice: o avisan de más (falsos positivos) o se callan casos reales. Cada herramienta elige su lado.
- **Los límites de tiempo** de los jueces en línea, de los *pipelines* de integración continua y de las
  funciones *serverless* son la respuesta práctica a la parada: no se decide, se corta.
- **Los antivirus** no pueden decidir si un programa es malicioso (es una propiedad semántica); trabajan con
  firmas (sintácticas) y con heurísticas.
- **El castor atareado** de cinco estados: en 2024 un proyecto colaborativo demostró, con una prueba
  verificada por ordenador, que el récord es 47 176 870 pasos. El de seis estados es inalcanzable con lo que
  se sabe hoy: la función crece más rápido que cualquier función computable.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Indecidible es lo mismo que muy difícil» | Indecidible es que no hay algoritmo para todas las entradas; un NP-difícil tiene algoritmo, quizá lento |
| «Un ordenador real no puede tener el problema de la parada porque su memoria es finita» | Es decidible en teoría, con una cota de `2^bits` pasos que no sirve de nada; en la práctica se razona como con memoria infinita |
| «Con un límite de tiempo se decide la parada» | Se aproxima: un programa lento que sí termina se declara colgado |
| «Church-Turing es un teorema» | Es una tesis; lo que se demuestra son las equivalencias entre modelos concretos |
| «La parada es indecidible, así que un simulador nunca sabe si termina» | Sabe cuando termina: es semidecidible. Lo que no puede es saber siempre que no termina |
| «Rice prohíbe cualquier análisis de programas» | Prohíbe decidir propiedades semánticas exactas; las sintácticas y las aproximaciones son legítimas |
| «Una MT es lenta, así que lo que calcula un ordenador es más» | Calcula lo mismo; el coste cambia en un polinomio |

---

## 📚 Para profundizar

- **Libro** — Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y computación*,
  3.ª ed. (Pearson, 2007), cap. 8: máquinas de Turing, extensiones y equivalencias; cap. 9: indecidibilidad,
  la máquina universal, reducciones, Rice y la correspondencia de Post. *Lectura troncal.*
- **Libro** — Hopcroft, Motwani y Ullman, *misma obra*, §8.6: la simulación de un ordenador real por una MT y
  su coste.
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 12: dónde queda la
  computabilidad respecto de la complejidad.
- **Video** — Ullman, *Automata Theory* (Stanford Online): máquinas de Turing e indecidibilidad.

---

## 🧠 Preguntas

1. ¿Qué es una configuración de una máquina de Turing? 🟢
2. ¿Qué diferencia hay entre un lenguaje decidible y uno semidecidible? 🟢
3. ¿Qué dice la tesis de Church-Turing, y por qué no es un teorema? 🟡
4. ¿Qué diferencia hay entre «indecidible» y «NP-difícil»? 🟡
5. ¿Por qué la cinta de un simulador se implementa con dos pilas, y qué cuesta hacerlo con una cadena? 🟡
6. Compara cómo representa la cinta la plantilla en C++, en Java y en Python. ¿Qué evita el `StringBuilder` de Java? 🟡
7. ¿Por qué el complemento del problema de la parada no es ni siquiera semidecidible? 🟠
8. ¿Por qué la parada de una máquina con un registro de 8 bits y `L` instrucciones es decidible, y en cuántos pasos? 🟠
9. Reduce el problema de la parada a «¿imprime este programa la palabra `hola`?». 🟠
10. ¿Qué dice el teorema de Rice? Da una propiedad de programas que es decidible y otra que no. 🟠
11. Escribe la prueba de que el problema de la parada es indecidible, con el programa diagonal. 🔴
12. Diseña una máquina de Turing que reconozca `{aⁿbⁿ : n ≥ 0}` y di cuántos pasos da con `aⁿbⁿ`, en orden de magnitud. 🔴
13. Un compañero propone rechazar en el *pipeline* todo cambio con un bucle infinito. ¿Qué le respondes, qué ofreces en su lugar y qué error comete cada alternativa? 🔴

---

## ✅ Criterio de dominio

- Escribir el simulador de dos pilas sin mirar y comprobar con él el castor atareado de dos estados.
- Escribir la prueba diagonal de la parada en cinco minutos, en voz alta.
- Hacer dos reducciones desde la parada (imprimir `hola`, equivalencia de programas).
- Explicar con el palomar por qué la parada con memoria finita es decidible, y por qué eso no contradice a
  Turing.

---

**Anterior:** [`22/02` — Autómatas de pila](02-automatas-de-pila.md) ·
**Siguiente:** [`22/04` — P, NP y reducciones](04-p-np-y-reducciones.md) ·
**Relacionado:** [`06/02` — Listas enlazadas](../06-lineales-y-hashing/02-listas-enlazadas.md) (Floyd);
[`22/01` — Lenguajes y gramáticas](01-lenguajes-y-gramaticas.md).
