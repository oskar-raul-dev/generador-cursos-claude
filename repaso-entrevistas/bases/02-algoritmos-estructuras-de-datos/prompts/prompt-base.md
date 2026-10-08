# Prompt base: temario de algoritmos y estructuras de datos

Este documento es el **contrato de contenido** de `02-algoritmos-estructuras-de-datos/`: qué cubre cada
archivo, con qué profundidad, qué teoría lo sostiene, qué código se escribe, qué confusiones tiene que
desmontar y de dónde salen sus problemas. La forma —tono, plantilla, niveles, callouts, cantidad de
preguntas y problemas— la manda [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md),
que es normativa y gana sobre este documento en todo lo que declare. El orden de producción lo manda
`plan-de-produccion.md`.

**Audiencia:** alguien que ya programa con soltura, estudió algoritmos alguna vez y quiere
**refrescarlos a fondo**: entender por qué funcionan, cuánto cuestan y cómo se escriben, y usar la
programación competitiva como medio de práctica y como formato de entrevista. No se explica qué es un
bucle ni un arreglo; sí se explica todo lo que pasa cuando un bucle mantiene un invariante y un arreglo
se ordena, se parte o se consulta por rangos. **No se asume leído ningún otro curso** (§1.2 de la
guía).

**La aportación propia de este corpus**, y lo que hay que proteger en cada documento:

- **la teoría de los libros base**, enunciada y esbozada, antes que la plantilla;
- **cada técnica en C++, Java y Python**, contrastada contra un juez real;
- **la versión ingenua y el camino a la buena**, para la entrevista en vivo;
- **los problemas sin solución**, con pistas escalonadas y la IA como tutor;
- **las rutas**, para que nadie tenga que leer todo.

**Versiones:** C++20, Java 21 y Python 3.12 como techo del lenguaje; Go 1.26 y Node 20 para los
ejercicios «Para el geek» (§5.3 de la guía, comprobado el 2026-10-03).

> **Vigencia:** 2026-10-04. **Estado:** escritura cerrada (T0–T38) y pasada de verificación hecha (TV, 2026-10-04); falta el cierre (TC).

**Salto rápido:** [1](#1--inventario-de-archivos) · [2](#2--cómo-se-lee-la-ficha) · [3](#3--los-temas-de-la-biblioteca) · [B01](#4--bloque-01--oficio-del-competidor) · [B02](#5--bloque-02--análisis) · [B03](#6--bloque-03--biblioteca-estándar) · [B04](#7--bloque-04--secuencias) · [B05](#8--bloque-05--orden-y-búsqueda) · [B06](#9--bloque-06--lineales-y-hashing) · [B07](#10--bloque-07--árboles) · [B08](#11-️-bloque-08--heaps-y-union-find) · [B09](#12--bloque-09--consultas-sobre-rangos) · [B10](#13--bloque-10--búsqueda-completa-y-divide-y-vencerás) · [B11](#14--bloque-11--voraces) · [B12](#15--bloque-12--dp-clásica) · [B13](#16--bloque-13--dp-avanzada) · [B14](#17-️-bloque-14--grafos-recorridos) · [B15](#18-️-bloque-15--grafos-con-pesos-y-flujos) · [B16](#19--bloque-16--cadenas) · [B17](#20--bloque-17--matemática) · [B18](#21--bloque-18--geometría) · [B19](#22--bloque-19--aleatorizados-y-probabilísticos) · [B20](#23--bloque-20--ad-hoc-constructivos-e-interactivos) · [B21](#24--bloque-21--simulacros) · [B22](#25--bloque-22--teoría-de-la-computación-opcional) · [B23](#26--bloque-23--cuaderno-de-competencia-opcional) · [README](#27-️-el-readmemd-del-corpus-y-las-rutas) · [Fuera](#28--qué-queda-fuera-y-por-qué)

---

# 1. 📦 Inventario de archivos

```text
02-algoritmos-estructuras-de-datos/
├── README.md                                    qué es, tesis, rutas, versiones, IA como tutor
├── prompts/
│   ├── guia-de-estilo-y-convenciones.md         normativa editorial
│   ├── prompt-base.md                           este documento
│   ├── plan-de-produccion.md                    tandas, estado, bitácora y checklist (se conserva al cerrar)
│   └── verificar-corpus.py                      enlaces, anclas, conteos, rutas (P6)
├── 01-oficio-del-competidor/                    7 capítulos + simulación + respuestas + README
├── 02-analisis/                                 6 + 2 + README
├── 03-biblioteca-estandar/                      6 + 2 + README
├── 04-secuencias/                               5 + 2 + README
├── 05-orden-y-busqueda/                         5 + 2 + README
├── 06-lineales-y-hashing/                       4 + 2 + README
├── 07-arboles/                                  7 + 2 + README
├── 08-heaps-y-union-find/                       4 + 2 + README
├── 09-consultas-sobre-rangos/                   6 + 2 + README
├── 10-busqueda-completa-y-divide-y-venceras/    6 + 2 + README
├── 11-voraces/                                  4 + 2 + README
├── 12-dp-clasica/                               6 + 2 + README
├── 13-dp-avanzada/                              7 + 2 + README
├── 14-grafos-recorridos/                        6 + 2 + README
├── 15-grafos-pesos-y-flujos/                    7 + 2 + README
├── 16-cadenas/                                  8 + 2 + README
├── 17-matematica/                               11 + 2 + README
├── 18-geometria/                                6 + 2 + README
├── 19-aleatorizados-y-probabilisticos/          6 + 2 + README
├── 20-ad-hoc-constructivos-e-interactivos/      5 + 2 + README
├── 21-simulacros/                               16 simulacros + pistas + README
├── 22-teoria-de-la-computacion/                 opcional: 6 capítulos + respuestas + README
└── 23-cuaderno-de-competencia/                  opcional: 5 cuadernos + README
```

**En cada bloque técnico**, los capítulos van numerados desde `01`, y les siguen
`NN-simulacion.md` y `NN-respuestas.md` con los dos números siguientes: en un bloque de siete
capítulos, `08-simulacion.md` y `09-respuestas.md`. **El código `NN/MM`** nombra un documento por
bloque y número: `12/03` es el tercer capítulo del bloque `12`.

**El corpus en números:** 122 capítulos del hilo principal, 20 simulaciones, 20 solucionarios, 16
simulacros con su documento de pistas, 23 README de bloque y el del corpus; más 6 capítulos, 1
solucionario y 5 cuadernos opcionales.

---

# 2. 🧭 Cómo se lee la ficha

Cada capítulo de las secciones 4 a 23 tiene este molde:

- **Archivo** — el nombre exacto del `.md`.
- **Objetivo** — lo que el lector debe poder hacer después: casi siempre enunciar, probar, costear y
  escribir.
- **Niveles** — cada técnica con su nivel A, B o C (§6.2 de la guía). El capítulo no lo cambia sin
  cambiar la ficha.
- **📚 Lectura troncal** — el libro base y el capítulo. Los capítulos son los de la edición fijada en el canon
  (§11.1 de la guía), **comprobados en P7** (2026-10-03).
- **Teoría** — los teoremas, propiedades y pruebas que el capítulo enuncia y esboza.
- **Cubre** — el contenido mínimo. Es el piso, no el índice.
- **Código** — qué plantillas se escriben y en qué lenguajes; el resto lo fija el nivel.
- **Desmonta** — las sobregeneralizaciones que tiene que atacar. **Al menos una.**
- **Problemas** — de qué plataformas sale la práctica externa: las tres bases (HackerRank, LeetCode,
  Codility) y la específica, si la hay. **No se fijan problemas concretos**: la tanda los elige y los
  verifica con el método de §9.4 de la guía. Cuando Codility tiene lección del tema, se nombra.
- **🔥** — si Go o JavaScript cambian el razonamiento, en qué (§9.7 de la guía).
- **Se toca con** — enlaces internos obligatorios.
- **Ruta corta: sí** — solo en los capítulos de las rutas «Entrevistas», «Prueba técnica esta semana»
  y «Programar en vivo», que se escriben autocontenidos (§13 de la guía).

Lo que **no** está en la ficha puede entrar si se justifica; lo que **sí** está no se omite sin
declararlo en el propio documento.

**Las simulaciones** de cada bloque siguen §7.2 de la guía; su ficha dice qué decisiones fuerzan sus
tres problemas propios. **Los solucionarios** siguen §7.3 y no tienen ficha propia.

---

# 3. 📚 Los temas de la biblioteca

Es la columna vertebral del corpus, heredada de la biblioteca evaluada por Oskar: **ningún tema de esta
tabla puede quedar fuera** de un capítulo del hilo principal o del bloque opcional `22`.

| Tema | Libro base | Dónde queda |
|---|---|---|
| Conceptos básicos, recursividad, notación asintótica | Brassard y Bratley, caps. 1–4 | `02/01`, `02/02`, `10/01` |
| Tipos abstractos de datos: contrato, implementación y coste por operación | Brassard y Bratley, cap. 5; Goodrich, Tamassia y Goldwasser | `02/06` |
| Listas, pilas, colas | Brassard y Bratley (teoría); Farrier (C++ moderno) | `06/01`, `06/02` |
| Colas de prioridad y montículos | Brassard y Bratley, cap. 5 | `08/01`, `08/02` |
| Grafos básicos: representación, BFS, DFS | Brassard y Bratley, cap. 9 | `14/01`–`14/03` |
| Árboles balanceados (AVL, rojo-negro, (2,4)) y árboles B | Goodrich, Tamassia y Goldwasser; CLRS; Aho, Hopcroft y Ullman | `07/02` |
| Voraces, Dijkstra, Kruskal | Brassard y Bratley, cap. 6; CLRS | bloque `11`, `15/01`, `15/04` |
| Divide y vencerás | Brassard y Bratley, cap. 7 | `10/05` |
| Programación dinámica | Brassard y Bratley, cap. 8 | bloques `12` y `13` |
| Exploración de grafos, *backtracking*, ramificación y poda | Brassard y Bratley, cap. 9; Knuth, Vol. 4A y 4B | `10/03`, `10/04` |
| Flujo en redes | CLRS; Kleinberg y Tardos | `15/05`, `15/06` |
| Algoritmos probabilísticos y lo justo de cadenas de Markov | Brassard y Bratley, cap. 10 | `19/01`, `19/04` |
| Complejidad computacional: P, NP, reducciones | Brassard y Bratley, cap. 12; Kleinberg y Tardos | `10/05` (reconocer), bloque `22` |
| Heurísticos y A\* | Brassard y Bratley, cap. 13; Russell y Norvig | `15/03`, `20/05` |
| Lenguajes formales y autómatas finitos | Hopcroft, Motwani y Ullman, caps. 2–4 | `16/07` |
| Autómatas de pila y máquinas de Turing | Hopcroft, Motwani y Ullman, caps. 6–9 | bloque `22` |
| Preliminares de compiladores, sin LL(1) ni LALR(1) | Aho, Lam, Sethi y Ullman, caps. 2–3 | bloque `22` |
| Estructuras espaciales y probabilísticas | La Rocca; Kubica | `19/03`, `19/05` |
| Datos masivos: MapReduce, flujo de datos, memoria externa | La Rocca; Medjedovic, Tahirovic y Dedovic | `19/06` |
| Matrices dispersas por dentro | Brassard y Bratley | `04/05` |
| La complejidad real de las estructuras de Python | Miller y Ranum; Ramalho | `03/04` |
| Caso promedio, recurrencias, funciones generadoras | Sedgewick y Flajolet | `02/02`, `02/03` (electivo), `17/11` |
| Gestión de memoria dinámica: el *buddy system* | Knuth, Vol. 1, §2.5 | `02/05` (ficha C) |

---

# 4. 🏁 Bloque `01` — Oficio del competidor

**Qué hace el bloque:** instala el medio de práctica. Qué es un juez, cómo se leen sus restricciones,
cómo se escribe la entrada y la salida, cómo se prueba sin IDE y cómo se trabaja un problema, solo o
delante de alguien. Sin teoría algorítmica: plantilla de oficio (§6.1 de la guía). Es el único bloque
con programas completos con `main`.

## `01/01` — El juez, los veredictos y las plataformas

- **Archivo:** `01-el-juez-los-veredictos-y-las-plataformas.md`
- **Objetivo:** saber qué significa cada veredicto, qué se puntúa en una prueba de empresa y en un
  concurso, y elegir bien el lenguaje y la versión en cada plataforma.
- **Niveles:** veredictos [A] · formato de empresa y de concurso [A] · plataformas [B].
- **📚 Lectura troncal:** Laaksonen, *Guide to Competitive Programming*, cap. 1; Halim y otros,
  *Competitive Programming 4*, cap. 1.
- **Cubre:**
  - AC, WA, TLE, MLE, RE, *Presentation Error*; casos ocultos y por qué los últimos son los grandes.
  - Prueba de empresa (2–3 problemas en 60–120 minutos, puntuación parcial por casos, completar una
    firma) frente a concurso (todo o nada, penalización por envío fallido, escribir el `main`).
  - Las tres bases —HackerRank, LeetCode, Codility— y las específicas, con lo que cada una enseña
    (§9.4 de la guía). CodeSignal como formato de prueba de empresa, sin enlaces.
  - **La versión importa**: la tabla de §5.3 de la guía; en HackerRank, elegir «C++23» y no «C++20»
    (G++ 8.3); en Codility, Python 3.12.
  - LeetCode solo gratis: qué es `isPaidOnly`.
- **Código:** ninguno.
- **Desmonta:** «si pasa los ejemplos, está bien» · «el lenguaje da igual» · «C++20 en HackerRank es
  C++20».
- **Problemas:** uno de cada base, triviales, para probar el envío.
- **Se toca con:** `01/02`, `01/03`, `21` (README).
- **Ruta corta:** no.

## `01/02` — Leer las restricciones: de `n` a la complejidad

- **Archivo:** `02-leer-las-restricciones.md`
- **Objetivo:** mirar las cotas del enunciado y decir qué complejidad cabe y qué técnicas la dan,
  antes de escribir una línea.
- **Niveles:** la tabla `n` → complejidad [A] · estimación de memoria [A].
- **📚 Lectura troncal:** Laaksonen, cap. 3; Skiena, *The Algorithm Design Manual*, cap. 2.
- **Cubre:**
  - La regla de bolsillo de 10⁸ operaciones simples por segundo, y por qué es orientativa.
  - La tabla `n ≤ 12` → `n!` … `n ~ 10¹⁸` → `log n` (§10.1 de la guía), con las técnicas típicas.
  - Lo que cambia en Java (arranque, *boxing*) y en Python (factor 30–50).
  - Memoria: 256 MB son 64 millones de `int`; un arreglo `long long` de 10⁸ no cabe.
  - El valor frente al tamaño: `n ≤ 10⁵` y valores `≤ 10⁹` piden cosas distintas.
- **Código:** ninguno; tablas y ejemplos de cotas.
- **Desmonta:** «O grande es el tiempo» · «si es `O(n log n)` entra seguro» · «la memoria no se mira».
- **Problemas:** de las bases, donde la fuerza bruta da TLE y la solución está en leer la cota.
- **Se toca con:** `02/01`, `01/05`.
- **Ruta corta:** sí.

## `01/03` — Entrada, salida y la plantilla en C++, Java y Python

- **Archivo:** `03-entrada-salida-y-plantilla.md`
- **Objetivo:** leer y escribir rápido en los tres lenguajes, en los dos formatos de plataforma.
- **Niveles:** E/S rápida [A] · los dos formatos [A].
- **📚 Lectura troncal:** Halim y otros, cap. 1; documentación de `<iostream>`, `java.io` y `sys`.
- **Cubre:**
  - C++: `ios::sync_with_stdio(false)`, `cin.tie(nullptr)`, `'\n'` frente a `endl`.
  - Java: `BufferedReader` + `StringTokenizer` o `StreamTokenizer`; `PrintWriter` frente a
    `System.out.println` en bucle; por qué `Scanner` es lento.
  - Python: `sys.stdin.readline`, `sys.stdin.buffer.read().split()`, `print` en bloque con `join`.
  - Completar una firma (HackerRank moderno, LeetCode, Codility) frente a escribir el `main`
    (HackerRank clásico, Codeforces, CSES).
  - `<bits/stdc++.h>` y `using namespace std`: qué son, por qué los usa un competidor y por qué el
    corpus no (§5.7 de la guía).
- **Código:** la plantilla de programa completa en los tres lenguajes, la única con `main` del corpus.
- **Desmonta:** «`Scanner` vale» · «`endl` es un salto de línea» · «la entrada no cuenta en el tiempo».
- **Problemas:** de entrada grande, donde la E/S lenta da TLE.
- **🔥** Go (`bufio.Reader` y `bufio.Writer` con `Flush`) y JavaScript (leer todo `stdin` de golpe en
  Node): la forma de leer cambia el diseño del programa.
- **Se toca con:** `01/01`, `03/03`, `03/04`.
- **Ruta corta:** sí.

## `01/04` — Tipos, desbordamiento y el primer contacto con el módulo

- **Archivo:** `04-tipos-desbordamiento-y-modulo.md`
- **Objetivo:** saber cuándo un tipo deja de bastar y por qué tantos enunciados piden la respuesta
  módulo 10⁹+7.
- **Niveles:** desbordamiento [A] · aritmética modular básica [A] · `double` y épsilon [A].
- **📚 Lectura troncal:** Halim y otros, cap. 1; Warren, *Hacker's Delight*, cap. 2.
- **Cubre:**
  - Rangos de `int`, `long long`/`long`, `__int128` (solo C++ con GCC), y Python sin límite.
  - Dónde desborda: la suma de 10⁵ valores de 10⁹; el producto de dos valores cerca de 10⁹; `mid`.
  - Desbordamiento con signo en C++ es comportamiento indefinido; en Java envuelve en silencio.
  - Módulo: suma, resta (el `+ MOD` antes del `%`), producto con `long long`; por qué 10⁹+7 (primo,
    cabe en `int`, el producto cabe en 64 bits). La teoría de números es de `17/03`.
  - `double`: épsilon, comparación con tolerancia, cuándo se evita del todo.
- **Código:** ejemplos mínimos en los tres lenguajes; una autopsia de un bug con un `int` que
  desborda.
- **Desmonta:** «`long` basta para todo» · «el `%` de un negativo es positivo» · «Python no desborda,
  así que no hay que pensar».
- **Problemas:** de las bases, con sumas y productos al límite.
- **🔥** JavaScript: los enteros son exactos solo hasta 2⁵³; el producto modular necesita `BigInt` o
  partirse.
- **Se toca con:** `01/02`, `17/03`.
- **Ruta corta:** no.

## `01/05` — Probar sin IDE: casos borde, depuración y *stress test*

- **Archivo:** `05-probar-sin-ide-y-stress-test.md`
- **Objetivo:** encontrar el bug antes que el juez: casos borde, salida de error y un *stress test*
  contra una fuerza bruta.
- **Niveles:** casos borde [A] · *stress test* [A] · depuración por `stderr` [A].
- **📚 Lectura troncal:** Laaksonen, cap. 1 (*testing*); Skiena y Revilla, *Programming Challenges*,
  cap. 1.
- **Cubre:**
  - La lista fija de casos borde: vacío, uno, todos iguales, negativos, ceros, el máximo de las
    restricciones, la respuesta al principio y al final, duplicados.
  - Depurar por `cerr`, `System.err` y `sys.stderr`, que el juez no cuenta como salida.
  - El *stress test*: fuerza bruta como oráculo, generador aleatorio con semilla, bucle que compara y
    se detiene en la primera diferencia, y reducir el caso que falla.
  - Por qué es el arnés de la pasada de verificación del corpus (§14 de la guía).
- **Código:** el arnés de *stress test* en un lenguaje (el script de shell o Python que orquesta), y
  el generador en los tres.
- **Desmonta:** «probé con el ejemplo» · «el juez me dirá qué falla».
- **Problemas:** propios, con un bug sembrado que solo aparece en un caso borde.
- **Se toca con:** `01/06`, `02/04`.
- **Ruta corta:** no.

## `01/06` — El protocolo de resolución, la repetición y el concurso

- **Archivo:** `06-protocolo-de-resolucion.md`
- **Objetivo:** trabajar cada problema con el mismo método, saber pedir ayuda —también a una IA— sin
  dejar de aprender, y convertir lo resuelto en algo que no se olvida.
- **Niveles:** el protocolo [A] · las pistas y la IA como tutor [A] · repetición y concurso [B].
- **📚 Lectura troncal:** Pólya, *Cómo plantear y resolver problemas* (Trillas; traducción de *How to Solve It*);
  Skiena, cap. 1.
- **Cubre:**
  - La ficha antes de programar (entrada, salida, restricciones, complejidad máxima, casos borde,
    fuerza bruta, qué se repite, idea optimizada) y después (patrón, error, pista que hizo falta,
    variante).
  - Los 30 minutos por fases: entender, estimar, diseñar con invariante, implementar y probar.
  - La fuerza bruta primero, y por qué vale puntos.
  - **Las tres pistas** (§9.2 de la guía) y **el lineamiento de la IA como tutor** (§9.6), escrito
    entero aquí.
  - Repetición espaciada (al día siguiente, a los 3 y a los 7 días, solo lo que costó); concursos
    virtuales, *upsolving*, el rating como termómetro.
  - **El mapa de señales del corpus**: se presenta aquí, y cada capítulo de técnica le añade filas.
- **Código:** ninguno.
- **Desmonta:** «si no me sale en 10 minutos, miro la solución» · «la IA me lo explica y ya lo
  aprendí» · «resolver muchos es aprender muchos».
- **Problemas:** de las bases, para aplicar el protocolo completo con la ficha.
- **Se toca con:** `01/05`, `01/07`, `02/04`.
- **Ruta corta:** sí.

## `01/07` — Programar en vivo

- **Archivo:** `07-programar-en-vivo.md`
- **Objetivo:** resolver delante de alguien: preguntar, escribir la versión ingenua, decir su coste,
  nombrar la mejora y probar a mano.
- **Niveles:** el método en vivo [A] · la rúbrica [A].
- **📚 Lectura troncal:** McDowell, *Cracking the Coding Interview*, secciones I («The Interview Process») y VII («Technical Questions»); Aziz, Lee y Prakash, cap. 1.
- **Cubre:**
  - Entender y preguntar antes de teclear: restricciones, formato, casos raros.
  - La versión ingenua completa y correcta, y por qué aprueba donde un óptimo a medias no.
  - Decir el coste en voz alta y **nombrar la mejora con precisión** («esto va con un BFS por
    niveles», «con memoización baja a `O(n·k)`»), y escribirla solo si queda tiempo.
  - Probar a mano con un caso borde; qué hacer cuando te quedas en blanco.
  - La rúbrica de seis puntos de §7.5 de la guía, y cómo se usa la sección «De la versión ingenua a la
    buena» de cada capítulo.
- **Código:** un ejemplo trabajado completo en Java, narrado.
- **Desmonta:** «hay que llegar al óptimo o no cuenta» · «mientras pienso, me callo».
- **Problemas:** propios, para practicar en voz alta con la rúbrica.
- **Se toca con:** `01/06`, `21` (los simulacros en vivo).
- **Ruta corta:** sí.

## `01/08` — Simulación

Sigue §7.2 de la guía. **Problemas propios:** uno de E/S grande con TLE por `Scanner`; uno de
desbordamiento que pasa los ejemplos; uno que se resuelve por fuerza bruta porque `n ≤ 15`.

---

# 5. 📐 Bloque `02` — Análisis

**Qué hace el bloque:** fija las herramientas de la teoría que el resto del corpus usa: notación,
recurrencias, amortizado, corrección y TDA. Es el bloque más «de libro»; sus capítulos son dueños de
conceptos que nadie más redefine (§12.1 de la guía).

## `02/01` — Notación asintótica y casos

- **Archivo:** `01-notacion-asintotica.md`
- **Objetivo:** usar O, Ω y Θ con precisión y decir de qué caso se habla.
- **Niveles:** O, Ω, Θ [A] · peor, promedio, amortizado, esperado [A].
- **📚 Lectura troncal:** Brassard y Bratley, caps. 2–3; CLRS, cap. 3.
- **Teoría:** las definiciones formales con constantes y `n₀`; reglas de la suma y del producto; la
  jerarquía de funciones; por qué `O` es una cota y no una estimación.
- **Cubre:** caso peor, caso promedio (sobre qué distribución), esperado (sobre el azar del
  algoritmo) y amortizado (sobre una secuencia), con un ejemplo de cada uno; contar operaciones en
  bucles anidados y dependientes; `o` y `ω` como ficha.
- **Código:** bucles en Java para contar; ninguna plantilla.
- **Desmonta:** «O grande es el tiempo que tarda» · «quicksort es O(n log n)» · «O(2n) es peor que
  O(n)».
- **Problemas:** propios de análisis (¿qué complejidad tiene este fragmento?); externos de las bases
  donde la diferencia entre `n²` y `n log n` decide. Codility: lección 3 (*Time Complexity*).
- **Se toca con:** `01/02`, `02/02`, `02/03`.
- **Ruta corta:** sí.

## `02/02` — Recurrencias y teorema maestro

- **Archivo:** `02-recurrencias-y-teorema-maestro.md`
- **Objetivo:** escribir la recurrencia de un algoritmo recursivo y resolverla.
- **Niveles:** sustitución y árbol de recursión [A] · teorema maestro [A] · Akra-Bazzi [C] ·
  funciones generadoras [C, electivo].
- **📚 Lectura troncal:** CLRS, cap. 4; Brassard y Bratley, cap. 4; electivo: Sedgewick y Flajolet,
  caps. 2–3.
- **Teoría:** **Teorema maestro**, enunciado con sus tres casos y la condición de regularidad; esbozo
  por el árbol de recursión; por qué no cubre `T(n) = 2T(n/2) + n/log n`.
- **Cubre:** merge sort, búsqueda binaria, Karatsuba y Strassen como ejemplos; recurrencias lineales
  homogéneas (adelanto de `13/06`).
- **Código:** ninguno; árboles de recursión en `text`.
- **Desmonta:** «el teorema maestro resuelve cualquier recurrencia» · «`T(n) = T(n-1) + n` es
  `O(n log n)`».
- **Problemas:** propios de resolver recurrencias.
- **Se toca con:** `02/01`, `10/05`, `13/06`.
- **Ruta corta:** no.

## `02/03` — Análisis amortizado

- **Archivo:** `03-analisis-amortizado.md`
- **Objetivo:** demostrar que una operación cara de vez en cuando cuesta poco en promedio sobre la
  secuencia.
- **Niveles:** agregado [A] · contable [B] · potencial [B].
- **📚 Lectura troncal:** CLRS, cap. 17; Brassard y Bratley, cap. 4.
- **Teoría:** los tres métodos aplicados a los mismos tres ejemplos: arreglo dinámico que duplica,
  pila con *multipop*, contador binario. Por qué duplicar y no sumar una constante.
- **Cubre:** `std::vector`, `ArrayList` y `list` por dentro; el factor de crecimiento de cada uno, comprobado en la fuente de cada librería al escribir; adelanto de Union-Find (`08/04`) y *splay* (`07/03`).
- **Código:** un arreglo dinámico mínimo en Java.
- **Desmonta:** «amortizado es lo mismo que promedio» · «el `add` de `ArrayList` es O(1) siempre».
- **Problemas:** propios de análisis.
- **Se toca con:** `02/01`, `08/04`, `07/03`.
- **Ruta corta:** no.

## `02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio

- **Archivo:** `04-correccion-invariantes-induccion-intercambio.md`
- **Objetivo:** argumentar por qué un algoritmo es correcto con la herramienta que le toca.
- **Niveles:** invariante de bucle [A] · inducción [A] · argumento de intercambio [A] · contradicción
  [B].
- **📚 Lectura troncal:** CLRS, cap. 2 (invariantes); Kleinberg y Tardos, cap. 4 (intercambio).
- **Teoría:** inicialización, mantenimiento y terminación; inducción fuerte para la recursión; el
  esquema del argumento de intercambio («toma una solución óptima que difiera de la voraz en el primer
  punto…»).
- **Cubre:** búsqueda binaria, ordenación por inserción y merge con sus invariantes; inducción sobre
  la recursión; el intercambio en la selección de actividades; cuándo un invariante mal enunciado
  produce un bug.
- **Código:** la búsqueda binaria anotada con su invariante en Java.
- **Desmonta:** «si funciona en los ejemplos, es correcto» · «el voraz es obvio».
- **Problemas:** propios: encontrar el invariante, o el contraejemplo.
- **Se toca con:** `05/04`, `11/01`, `12/01`.
- **Ruta corta:** sí.

## `02/05` — El coste real

- **Archivo:** `05-el-coste-real.md`
- **Objetivo:** explicar por qué dos algoritmos con la misma cota tardan distinto, y qué hay debajo de
  una asignación de memoria.
- **Niveles:** caché y localidad [B] · constantes y *boxing* [B] · el asignador y el *buddy system*
  [C].
- **📚 Lectura troncal:** Bryant y O'Hallaron, *Computer Systems: A Programmer's Perspective*, 3.ª ed. (Pearson, 2016), cap. 6; Knuth, Vol. 1, §2.5.
- **Cubre:** jerarquía de memoria y números de latencia orientativos; recorrer una matriz por filas o
  por columnas; arreglo frente a lista enlazada; *boxing* en Java (`Integer` frente a `int`); el
  factor de Python; el *buddy system* como ficha C.
- **Código:** el recorrido por filas y por columnas en C++; `int[]` frente a `List<Integer>` en Java.
- **Desmonta:** «la lista enlazada es más rápida para insertar» · «O(1) es O(1)».
- **Problemas:** propios de comparar; externos donde `List<Integer>` da TLE y `int[]` no.
- **Se toca con:** `02/01`, `03/03`, `06/02`.
- **Ruta corta:** no.

## `02/06` — Tipos abstractos de datos

- **Archivo:** `06-tipos-abstractos-de-datos.md`
- **Objetivo:** separar el contrato de una estructura de su implementación y su coste.
- **Niveles:** TDA, contrato e invariante de representación [A] · TDA en orientación a objetos [B].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 5; Goodrich, Tamassia y Goldwasser, caps. 2 y 6–7.
- **Teoría:** especificación de un TDA (operaciones, precondiciones, postcondiciones); invariante de
  representación; el mismo TDA con implementaciones de coste distinto.
- **Cubre:** pila, cola, diccionario, conjunto y cola de prioridad como TDA; interfaz e
  implementación en Java (`Deque`/`ArrayDeque`, `Map`/`HashMap`/`TreeMap`); el mapa de qué
  estructura del corpus implementa cada TDA.
- **Código:** una interfaz y dos implementaciones en Java.
- **Desmonta:** «el TDA es la clase» · «`List` y `ArrayList` son lo mismo».
- **Problemas:** propios: elegir implementación por las operaciones.
- **Se toca con:** `06/01`, `08/01`, `03/05`.
- **Ruta corta:** no.

## `02/07` — Simulación

**Problemas propios:** dar la complejidad de un fragmento con bucles dependientes; resolver la
recurrencia de un divide y vencerás desequilibrado; encontrar el invariante de un bucle que lo
necesita, y el contraejemplo de un voraz que falla.

---

# 6. 🧰 Bloque `03` — Biblioteca estándar

**Qué hace el bloque:** el arsenal de cada lenguaje, con su coste y sus trampas. Plantilla de
lenguaje (§6.1 de la guía): sin teoría ni señales.

## `03/01` — C++: contenedores de la STL y su coste

- **Archivo:** `01-cpp-contenedores.md`
- **Objetivo:** elegir el contenedor de la STL por sus operaciones y su coste.
- **Niveles:** `vector`, `deque`, `set`/`multiset`, `map`, `unordered_map`, `priority_queue` [A] ·
  `bitset`, `list` [B].
- **📚 Lectura troncal:** Farrier, *Data Structures and Algorithms with the C++ STL*, caps. 1–9; cppreference.
- **Cubre:** coste por operación; invalidación de iteradores; `multiset::erase(valor)` borra todos;
  `priority_queue` es *max-heap*; `unordered_map` atacable (adelanto de `06/03`).
- **Código:** fragmentos de uso en C++.
- **Desmonta:** «`map` es una tabla hash» · «`erase(x)` en un `multiset` borra uno».
- **Problemas:** de las bases, resueltos eligiendo bien el contenedor.
- **Se toca con:** `03/02`, `03/05`, `06/03`.
- **Ruta corta:** sí (si el lenguaje propio es C++).

## `03/02` — C++: algoritmos, *ranges* y `ordered_set`

- **Archivo:** `02-cpp-algoritmos-ranges-y-pbds.md`
- **Objetivo:** usar `<algorithm>` y `<numeric>` en vez de reescribirlos, y saber qué da PBDS.
- **Niveles:** `sort`, `lower_bound`, `next_permutation`, `nth_element`, `accumulate`,
  `partial_sum` [A] · `std::ranges` [B] · `ordered_set` de PBDS [B].
- **📚 Lectura troncal:** Farrier, caps. 11–15; cppreference; la documentación de GCC sobre
  PBDS.
- **Cubre:** el comparador como orden estricto débil; `ordered_set` con `find_by_order` y
  `order_of_key`; que PBDS es solo de GCC (LeetCode usa Clang con libstdc++: si compila allí se comprueba en `TV` con un envío de prueba).
- **Código:** fragmentos en C++.
- **Desmonta:** «un comparador con `<=` vale» · «`nth_element` ordena».
- **Problemas:** de las bases.
- **Se toca con:** `03/01`, `05/01`, `05/03`.
- **Ruta corta:** no.

## `03/03` — Java: las colecciones para competir y sus trampas

- **Archivo:** `03-java-colecciones.md`
- **Objetivo:** usar las colecciones de Java con su coste real y sin caer en sus trampas.
- **Niveles:** `ArrayList`, `ArrayDeque`, `HashMap`, `TreeMap`, `PriorityQueue` [A] · `BitSet`,
  `Arrays`, `Collections` [B].
- **📚 Lectura troncal:** la documentación de la API de Java 21 (`java.util`); Sedgewick y Wayne,
  cap. 1.
- **Cubre:** `TreeMap.floorKey`, `ceilingKey`, `subMap`; el *multiset* que no existe (`TreeMap` de
  conteos); `Arrays.sort` en primitivos (*dual-pivot quicksort*: atacable hasta Java 13, con respaldo de
  *heapsort* desde Java 14, comprobado en la fuente de OpenJDK en T5) frente a objetos (TimSort); *boxing* y `Integer` con `==`; `HashMap` atacable y su árbol desde Java 8; recursión y
  `Thread` con pila grande.
- **Código:** fragmentos en Java.
- **Desmonta:** «`Arrays.sort` es siempre n log n» · «`Integer == Integer` compara valores» ·
  «`Stack` es la pila de Java».
- **Problemas:** de las bases.
- **Se toca con:** `03/05`, `05/01`, `06/03`.
- **Ruta corta:** sí (si el lenguaje propio es Java).

## `03/04` — Python: `collections`, `heapq`, `bisect`, `itertools`, recursión y PyPy

- **Archivo:** `04-python-para-competir.md`
- **Objetivo:** saber qué viene hecho en Python, cuánto cuesta y dónde se queda corto.
- **Niveles:** `list`, `dict`, `set`, `deque`, `Counter`, `defaultdict`, `heapq`, `bisect` [A] ·
  `itertools`, `functools.cache`, `sys.setrecursionlimit` [A] · PyPy [B].
- **📚 Lectura troncal:** Miller y Ranum, cap. 2; Ramalho, *Fluent Python*, caps. 2–3; documentación
  de Python.
- **Cubre:** `list` como arreglo dinámico (`pop(0)` es O(n)); `heapq` solo *min-heap*; que no hay mapa
  ordenado (y `sortedcontainers` no está en los jueces); el límite de recursión y la pila del hilo; el
  factor 30–50 y cuándo PyPy lo arregla.
- **Código:** fragmentos en Python.
- **Desmonta:** «`list.pop(0)` es O(1)» · «subir el límite de recursión basta».
- **Problemas:** de las bases.
- **Se toca con:** `03/05`, `10/01`.
- **Ruta corta:** sí (si el lenguaje propio es Python).

## `03/05` — La tabla de equivalencias

- **Archivo:** `05-equivalencias-entre-lenguajes.md`
- **Objetivo:** traducir una estructura de un lenguaje a otro y saber qué falta en cada uno.
- **Niveles:** la tabla [A].
- **📚 Lectura troncal:** cppreference, la API de Java 21 y la documentación de Python.
- **Cubre:** la tabla TDA → C++ · Java · Python (§5.5 de la guía) para pila, cola, deque, diccionario,
  diccionario ordenado, conjunto, *multiset*, cola de prioridad, *bitset*; lo que falta en cada uno y
  su sustituto.
- **Código:** ninguno nuevo; la tabla.
- **Desmonta:** «todos los lenguajes tienen lo mismo».
- **Problemas:** uno resuelto en los tres lenguajes, propio.
- **Se toca con:** `03/01`–`03/04`, `02/06`.
- **Ruta corta:** no.

## `03/06` — Competir sin arsenal: Go y JavaScript

- **Archivo:** `06-sin-arsenal-go-y-javascript.md`
- **Objetivo:** escribir en Go y en JavaScript lo que en C++, Java o Python viene hecho.
- **Niveles:** Go [B] · JavaScript [B].
- **📚 Lectura troncal:** Bodner, *Learning Go*; MDN.
- **Cubre:** Go: `container/heap` y su interfaz, `sort.Slice` y `slices`, el deque con *slice*,
  `bufio`, semántica de valor; JavaScript: el número `double` y `BigInt`, `sort` con comparador,
  `shift()` O(n), el heap y el deque a mano, leer `stdin` en Node.
- **Código:** heap y deque en Go y en JavaScript.
- **Desmonta:** «Go es C sin el más más» · «`[10, 9, 1].sort()` ordena números».
- **Problemas:** de las bases, a resolver en Go o JavaScript.
- **🔥** Todo el capítulo es «para el geek».
- **Se toca con:** `03/05`, `01/04`, `08/01`.
- **Ruta corta:** no.

## `03/07` — Simulación

**Problemas propios:** traducir una solución de Java a C++ cambiando `TreeMap` por `multiset`; uno con
TLE en Python por `pop(0)`; uno con `Integer ==` que falla solo con valores grandes.

---

# 7. 📏 Bloque `04` — Secuencias

**Qué hace el bloque:** las técnicas sobre arreglos que más salen en entrevistas. Primera aparición de
la plantilla completa de técnica (§6 de la guía).

## `04/01` — Sumas de prefijos y arreglos de diferencias

- **Archivo:** `01-prefijos-y-diferencias.md`
- **Objetivo:** responder consultas de suma por rango en O(1) y aplicar actualizaciones por rango en
  O(1), en 1D y 2D.
- **Niveles:** prefijos 1D [A] · diferencias 1D [A] · prefijos y diferencias 2D [A].
- **📚 Lectura troncal:** Laaksonen, cap. 9; Halim y otros, cap. 3.
- **Teoría:** la suma telescópica `prefix[r+1] − prefix[l]`; las diferencias como la inversa del
  prefijo; inclusión-exclusión en 2D.
- **Cubre:** el desplazamiento de índice (`prefix[0] = 0`); contar subarreglos con suma `k` usando
  prefijos y hash (adelanto de `04/03`); cuándo pasar a Fenwick (`09/02`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «para cada consulta, sumo el rango» · «los prefijos sirven con actualizaciones».
- **Problemas:** bases; Codility: lección 5 (*Prefix Sums*).
- **Se toca con:** `04/03`, `09/02`.
- **Ruta corta:** sí.

## `04/02` — Dos punteros y ventana deslizante

- **Archivo:** `02-dos-punteros-y-ventana.md`
- **Objetivo:** resolver en O(n) los problemas de pares sobre arreglos ordenados y de subarreglos
  contiguos con una condición monótona.
- **Niveles:** dos punteros [A] · ventana variable [A] · ventana fija [A].
- **📚 Lectura troncal:** Laaksonen, cap. 8; Halim y otros, cap. 3.
- **Teoría:** por qué cada índice entra y sale una vez (análisis agregado); la **monotonía** que
  justifica no retroceder y el invariante de la ventana.
- **Cubre:** par con suma objetivo en arreglo ordenado; la ventana más larga y la más corta; por qué
  falla con negativos y qué se usa entonces (prefijos con hash o deque).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «ventana deslizante sirve para cualquier subarreglo» · «dos bucles anidados son
  siempre O(n²)».
- **Problemas:** bases; Codility: lección 15 (*Caterpillar method*).
- **Se toca con:** `04/01`, `04/03`, `06/01` (cola monótona).
- **Ruta corta:** sí.

## `04/03` — Kadane y subarreglos

- **Archivo:** `03-kadane-y-subarreglos.md`
- **Objetivo:** encontrar el subarreglo de suma máxima y contar subarreglos con una suma dada.
- **Niveles:** Kadane [A] · variante circular [A] · conteo con prefijos y hash [A] · voto de mayoría de
  Boyer-Moore [B].
- **📚 Lectura troncal:** Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 8; CLRS, cap. 4
  (subarreglo máximo por divide y vencerás).
- **Teoría:** Kadane como DP (`mejor que termina en i`), con su invariante; el subarreglo máximo
  circular como total menos el mínimo; el voto de mayoría y por qué la pareja de anulaciones lo prueba.
- **Cubre:** todos negativos; reconstruir el subarreglo; la versión de divide y vencerás como contraste
  de coste. Es el dueño de Kadane; `12/02` lo cita.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «Kadane falla con todos negativos» · «para contar subarreglos hay que enumerarlos».
- **Problemas:** bases; Codility: lecciones 8 (*Leader*) y 9 (*Maximum slice problem*).
- **Se toca con:** `04/01`, `12/02`, `10/05`.
- **Ruta corta:** sí.

## `04/04` — Compresión de coordenadas y barrido de eventos

- **Archivo:** `04-compresion-y-barrido.md`
- **Objetivo:** reducir valores enormes a índices y procesar intervalos como eventos ordenados.
- **Niveles:** compresión de coordenadas [A] · barrido de eventos [A] · unión de intervalos [A].
- **📚 Lectura troncal:** Laaksonen, cap. 13; de Berg y otros, cap. 2 (el barrido como
  paradigma).
- **Teoría:** el orden de eventos con empates (¿cierra antes de abrir?) como parte de la corrección.
- **Cubre:** máximo de intervalos solapados; longitud de la unión; compresión para un Fenwick (`09/02`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «los empates no importan» · «con valores hasta 10⁹ necesito un arreglo de 10⁹».
- **Problemas:** bases.
- **Se toca con:** `11/02`, `09/02`, `18/05`.
- **Ruta corta:** no.

## `04/05` — Matrices

- **Archivo:** `05-matrices.md`
- **Objetivo:** recorrer, rotar y buscar en matrices sin errores de índice, y saber representarlas
  dispersas.
- **Niveles:** recorridos, rotación y espiral [A] · búsqueda en matriz ordenada [A] · representación
  dispersa [B].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 5 (matrices dispersas); Sedgewick y Wayne, cap. 1.
- **Teoría:** el invariante de la búsqueda en escalera (desde la esquina superior derecha) y por qué
  es O(n + m).
- **Cubre:** rotar 90° en el lugar; espiral; vecinos en rejilla con arreglos de direcciones; matriz
  dispersa como mapa de coordenadas, CSR y listas múltiples.
- **Código:** plantillas en los tres lenguajes; la dispersa en C++.
- **Desmonta:** «buscar en matriz ordenada es binaria por filas» · «la matriz dispersa es una matriz
  con ceros».
- **Problemas:** bases; Codility: lección 2 (*Arrays*).
- **Se toca con:** `14/02`, `17/07`.
- **Ruta corta:** no.

## `04/06` — Simulación

**Problemas propios:** uno de prefijos 2D; uno de ventana que con negativos deja de funcionar; uno de
barrido con empates; uno que se resuelve por fuerza bruta porque `n ≤ 300`.

---

# 8. 🔢 Bloque `05` — Orden y búsqueda

**Qué hace el bloque:** la ordenación con su cota inferior, la selección y la búsqueda binaria en
todas sus formas.

## `05/01` — Ordenación por comparación

- **Archivo:** `01-ordenacion-por-comparacion.md`
- **Objetivo:** explicar merge sort, quicksort y heapsort con su invariante y su coste, y demostrar la
  cota inferior.
- **Niveles:** merge sort [A] · quicksort [A] · heapsort [B] · inserción [A] · estabilidad [A].
- **📚 Lectura troncal:** CLRS, caps. 2, 6–8; Brassard y Bratley, caps. 7 y 12 (cota inferior);
  Sedgewick y Wayne, cap. 2.
- **Teoría:** **la cota Ω(n log n)** por árboles de decisión; el caso promedio de quicksort; por qué
  heapsort no es estable; TimSort e introsort como ficha.
- **Cubre:** qué usa cada librería (`std::sort` introsort, `std::stable_sort`, `Arrays.sort` en
  primitivos y en objetos, `sorted` TimSort); comparadores y orden estricto débil.
- **Código:** merge sort y quicksort (partición de Lomuto y de Hoare) en los tres lenguajes.
- **Desmonta:** «quicksort es O(n log n)» · «ordenar con comparador es estable» · «ningún algoritmo
  baja de n log n».
- **Problemas:** bases; Codility: lección 6 (*Sorting*).
- **🔥** JavaScript: `sort()` sin comparador ordena como texto.
- **Se toca con:** `05/02`, `05/03`, `02/02`.
- **Ruta corta:** no.

## `05/02` — Ordenación lineal

- **Archivo:** `02-ordenacion-lineal.md`
- **Objetivo:** ordenar en O(n + k) cuando las claves lo permiten, y saber por qué no contradice la
  cota.
- **Niveles:** *counting sort* [B] · *radix sort* [B] · *bucket sort* [C].
- **📚 Lectura troncal:** CLRS, cap. 8.
- **Teoría:** por qué no son ordenaciones por comparación; la estabilidad del *counting* como
  condición del *radix*.
- **Cubre:** cuándo `k` hace que no valga la pena.
- **Código:** *counting* y *radix* en C++ y Java.
- **Desmonta:** «*radix* es siempre más rápido».
- **Problemas:** bases.
- **Se toca con:** `05/01`.
- **Ruta corta:** no.

## `05/03` — Inversiones, selección y mediana

- **Archivo:** `03-inversiones-y-seleccion.md`
- **Objetivo:** contar inversiones en O(n log n) y encontrar el k-ésimo en O(n) esperado.
- **Niveles:** inversiones con merge sort [A] · *quickselect* [A] · mediana de medianas [C].
- **📚 Lectura troncal:** CLRS, cap. 9; Brassard y Bratley, cap. 7; Kleinberg y Tardos, cap. 5
  (inversiones).
- **Teoría:** el conteo en la mezcla; el análisis esperado de *quickselect*; la garantía lineal de la
  mediana de medianas.
- **Cubre:** `nth_element`; inversiones con Fenwick como alternativa (`09/02`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «para el k-ésimo hay que ordenar» · «*quickselect* es O(n) en el caso peor».
- **Problemas:** bases.
- **Se toca con:** `05/01`, `09/02`, `19/01`.
- **Ruta corta:** no.

## `05/04` — Búsqueda binaria

- **Archivo:** `04-busqueda-binaria.md`
- **Objetivo:** escribir sin *off-by-one* la binaria sobre índices, *lower* y *upper bound*, sobre la
  respuesta y en reales.
- **Niveles:** binaria y *lower/upper bound* [A] · **binaria sobre la respuesta** [A] · en reales [A].
- **📚 Lectura troncal:** Knuth, Vol. 3, §6.2.1; Bentley, *Programming Pearls*, columna 4; CLRS, cap. 2
  (ejercicios).
- **Teoría:** el invariante del intervalo semiabierto; **el predicado monótono** como condición de
  la binaria sobre la respuesta; terminación por iteraciones fijas en reales.
- **Cubre:** `std::lower_bound`, `Arrays.binarySearch`, `bisect`; el bug del `mid` en la JDK; binaria
  sobre la respuesta para «el mínimo x tal que…».
- **Código:** las tres plantillas en los tres lenguajes. Es dueño de la binaria (§12.1 de la guía).
- **Desmonta:** «la binaria solo sirve en arreglos ordenados» · «`(lo + hi) / 2` está bien».
- **Problemas:** bases; Codility: lección 14 (*Binary search algorithm*).
- **Se toca con:** `02/04`, `05/05`, `11/01`.
- **Ruta corta:** sí.

## `05/05` — Búsqueda ternaria, unimodales y exponencial

- **Archivo:** `05-ternaria-y-exponencial.md`
- **Objetivo:** encontrar el extremo de una función unimodal y buscar sin conocer el tamaño.
- **Niveles:** ternaria [B] · exponencial [B].
- **📚 Lectura troncal:** cp-algorithms, *Ternary Search*; Skiena, cap. 5.
- **Teoría:** por qué la ternaria necesita unimodalidad estricta; la binaria sobre la derivada
  discreta como alternativa.
- **Cubre:** mesetas que rompen la ternaria; búsqueda exponencial en flujos.
- **Código:** C++ y Java.
- **Desmonta:** «la ternaria funciona en cualquier función con un mínimo».
- **Problemas:** bases; específica: Codeforces.
- **Se toca con:** `05/04`, `18/01`.
- **Ruta corta:** no.

## `05/06` — Simulación

**Problemas propios:** binaria sobre la respuesta disfrazada; contar inversiones; uno donde ordenar con
un comparador mal escrito rompe; y uno que se resuelve ordenando sin más.

---

# 9. 🧱 Bloque `06` — Lineales y hashing

**Qué hace el bloque:** las estructuras lineales con sus variantes monótonas, las listas enlazadas y
las tablas hash por dentro, incluido cómo se atacan.

## `06/01` — Pila, cola, deque y sus versiones monótonas

- **Archivo:** `01-pilas-colas-y-monotonas.md`
- **Objetivo:** usar pila, cola y deque, y resolver «el siguiente mayor» y «el mínimo de cada ventana»
  en O(n).
- **Niveles:** pila, cola, deque [A] · pila monótona [A] · cola monótona [A].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 5; Sedgewick y Wayne, cap. 1.3; Goodrich, Tamassia
  y Goldwasser, cap. 6.
- **Teoría:** el invariante de la pila monótona (los elementos que quedan nunca serán respuesta de
  nadie más a la izquierda); el análisis agregado que la deja en O(n).
- **Cubre:** paréntesis balanceados; siguiente mayor y anterior menor; el rectángulo más grande en un
  histograma; mínimo en ventana deslizante con deque; `std::stack`/`deque`, `ArrayDeque`,
  `collections.deque`.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «la pila monótona es O(n²) porque tiene un bucle dentro» · «`Stack` de Java es la
  pila».
- **Problemas:** bases; Codility: lección 7 (*Stacks and Queues*).
- **🔥** JavaScript: no hay deque y `shift()` es O(n); hay que escribir la cola con dos índices.
- **Se toca con:** `04/02`, `13/05`, `02/06`.
- **Ruta corta:** sí.

## `06/02` — Listas enlazadas

- **Archivo:** `02-listas-enlazadas.md`
- **Objetivo:** manipular listas enlazadas sin perder punteros, y saber cuándo no usarlas.
- **Niveles:** inversión, mezcla, punteros lento y rápido (Floyd) [A] · LRU con lista y hash [A] ·
  listas múltiples [C].
- **📚 Lectura troncal:** Goodrich, Tamassia y Goldwasser, cap. 3; Brassard y Bratley, cap. 5.
- **Teoría:** por qué Floyd detecta el ciclo y encuentra su inicio (la prueba con las distancias).
- **Cubre:** el nodo centinela; el punto medio; la LRU con `LinkedHashMap` y a mano.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «la lista enlazada inserta en O(1)» · «`LinkedList` es buena cola».
- **Problemas:** bases (LeetCode tiene muchos con su `ListNode`).
- **Se toca con:** `02/05`, `06/03`.
- **Ruta corta:** sí.

## `06/03` — Tablas hash por dentro y los *anti-hash tests*

- **Archivo:** `03-tablas-hash.md`
- **Objetivo:** explicar cómo funciona una tabla hash, cuándo se degrada y cómo se protege contra un
  caso adversario.
- **Niveles:** encadenamiento y direccionamiento abierto [A] · factor de carga y *rehash* [A] ·
  *anti-hash tests* y hash propio [B].
- **📚 Lectura troncal:** CLRS, cap. 11; Sedgewick y Wayne, cap. 3.4.
- **Teoría:** el coste esperado bajo hash uniforme simple (`1 + α`); por qué el caso peor es O(n); el
  *rehash* como amortizado.
- **Cubre:** `unordered_map` con un hash adversario y el hash con `splitmix64`; `HashMap` de Java y su
  árbol desde Java 8; `dict` de Python; conjuntos y contadores; el contrato igualdad-hash. Es el
  dueño de las tablas hash.
- **Código:** plantillas en los tres lenguajes; el hash propio en C++.
- **Desmonta:** «el `HashMap` es O(1)» · «en un concurso nadie va a atacar mi hash».
- **Problemas:** bases; Codility: lección 4 (*Counting Elements*); específica: Codeforces (con
  *hacks*).
- **Se toca con:** `06/04`, `19/02`, `03/03`.
- **Ruta corta:** sí.

## `06/04` — Hashing de secuencias

- **Archivo:** `04-hashing-de-secuencias.md`
- **Objetivo:** comparar subcadenas y subarreglos en O(1) con un hash polinomial, y estimar su
  probabilidad de colisión.
- **Niveles:** hash polinomial [B] · doble módulo [B] · Zobrist y hash de multiconjuntos [B].
- **📚 Lectura troncal:** CLRS, cap. 32 (Rabin-Karp); cp-algorithms, *String Hashing*.
- **Teoría:** la probabilidad de colisión con un módulo primo y una base aleatoria (la cota por el
  número de raíces de un polinomio); por qué la base fija es atacable.
- **Cubre:** prefijos de hash; Rabin-Karp; Zobrist para estados; suma o XOR de valores aleatorios para
  multiconjuntos. Es el dueño del hash polinomial; `16/04` lo aplica.
- **Código:** C++ y Java.
- **Desmonta:** «con módulo 10⁹+7 no hay colisiones» · «si los hashes son iguales, las cadenas son
  iguales».
- **Problemas:** bases; específica: CSES y Codeforces.
- **🔥** JavaScript: el producto modular de 64 bits necesita `BigInt` o partirse.
- **Se toca con:** `06/03`, `16/04`.
- **Ruta corta:** no.

## `06/05` — Simulación

**Problemas propios:** siguiente mayor circular; LRU; uno que da TLE con `unordered_map` por un
hash adversario; uno que se resuelve con un arreglo de 26 contadores y nada más.

---

# 10. 🌳 Bloque `07` — Árboles

**Qué hace el bloque:** los árboles como estructura y como grafo: recorridos, balanceo, tries, LCA y
las técnicas sobre árboles.

## `07/01` — Árboles: representación y recorridos

- **Archivo:** `01-arboles-y-recorridos.md`
- **Objetivo:** representar un árbol, recorrerlo en sus cuatro órdenes y calcular altura y diámetro.
- **Niveles:** representación [A] · preorden, inorden, postorden, por niveles [A] · diámetro [A] ·
  recorrido de Euler [B].
- **📚 Lectura troncal:** Goodrich, Tamassia y Goldwasser, cap. 8; Brassard y Bratley, cap. 5.
- **Teoría:** propiedades básicas (n − 1 aristas, camino único); por qué el diámetro se encuentra con
  dos BFS o DFS (la prueba de que el extremo más lejano de cualquier nodo es extremo de un diámetro).
- **Cubre:** padre/hijos, lista de adyacencia, nodos con punteros; recorridos recursivos e iterativos;
  el árbol T de §5.6 de la guía; tiempos de entrada y salida.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «un árbol es un grafo cualquiera» · «el diámetro pasa por la raíz».
- **Problemas:** bases.
- **Se toca con:** `14/03`, `07/05`, `07/06`.
- **Ruta corta:** sí.

## `07/02` — BST y árboles balanceados

- **Archivo:** `02-bst-y-balanceados.md`
- **Objetivo:** explicar qué garantiza un árbol balanceado, cómo lo mantiene, y por qué los índices de
  una base de datos son árboles B.
- **Niveles:** BST [A] · AVL [B] · rojo-negro [B] · (2,4) [C] · árbol B [B].
- **📚 Lectura troncal:** Goodrich, Tamassia y Goldwasser, caps. 11 y 15; CLRS, caps.
  12, 13 y 18.
- **Teoría:** la altura O(log n) del AVL (por Fibonacci) y del rojo-negro (por la altura negra); la
  equivalencia rojo-negro ↔ (2,4); por qué el árbol B minimiza accesos a disco.
- **Cubre:** rotaciones; `std::map` y `TreeMap` como rojo-negro; el BST degenerado; un BST validado
  con cotas.
- **Código:** BST en los tres lenguajes; rotaciones en C++ y Java.
- **Desmonta:** «un BST es O(log n)» · «el árbol B es un árbol binario».
- **Problemas:** bases.
- **🔥** Go y JavaScript: no hay mapa ordenado; hay que escribirlo o sustituirlo.
- **Se toca con:** `07/03`, `03/05`, `02/06`.
- **Ruta corta:** no.

## `07/03` — Árboles aleatorizados y autoajustables

- **Archivo:** `03-arboles-aleatorizados.md`
- **Objetivo:** usar un *treap* como mapa ordenado y como arreglo con cortes, y reconocer *splay* y
  *skip list*.
- **Niveles:** *treap* [B] · *treap* implícito [B] · *splay* [C] · *skip list* [B].
- **📚 Lectura troncal:** Goodrich, Tamassia y Goldwasser, cap. 11 (*splay*) y cap. 10 (*skip list*); Kubica, *Data Structures the Fun Way*, cap. 14.
- **Teoría:** la altura esperada O(log n) del *treap* y de la *skip list*; la cota amortizada del
  *splay*. Es el dueño de estas tres estructuras; `19/02` las retoma desde el análisis probabilístico.
- **Cubre:** `split` y `merge`; el *treap* implícito para insertar y cortar en medio de una secuencia.
- **Código:** *treap* en C++ y Java.
- **Desmonta:** «aleatorizado es poco fiable».
- **Problemas:** bases; específica: SPOJ y Codeforces.
- **Se toca con:** `07/02`, `19/02`.
- **Ruta corta:** no.

## `07/04` — Tries

- **Archivo:** `04-tries.md`
- **Objetivo:** usar un trie para prefijos y un trie binario para el XOR máximo.
- **Niveles:** trie de palabras [A] · trie binario [A].
- **📚 Lectura troncal:** Sedgewick y Wayne, cap. 5.2.
- **Teoría:** por qué el voraz bit a bit desde el más alto da el XOR máximo.
- **Cubre:** nodos con arreglo de 26 frente a mapa; memoria; autocompletar; trie comprimido como
  ficha.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «un trie siempre ahorra memoria» · «para el XOR máximo hay que probar todos los
  pares».
- **Problemas:** bases.
- **Se toca con:** `16/05`, `17/01`.
- **Ruta corta:** sí.

## `07/05` — LCA

- **Archivo:** `05-lca.md`
- **Objetivo:** responder el ancestro común más bajo y la distancia entre dos nodos en O(log n).
- **Niveles:** *binary lifting* [A] · Euler + RMQ [B].
- **📚 Lectura troncal:** Laaksonen, cap. 10; cp-algorithms, *LCA*.
- **Teoría:** la representación binaria del salto; la reducción LCA → RMQ por el recorrido de Euler.
- **Cubre:** profundidad, igualar alturas, saltar juntos; distancia = `prof(u) + prof(v) − 2·prof(lca)`;
  el árbol T de §5.6.
- **Código:** *binary lifting* en los tres lenguajes; Euler + RMQ en C++ y Java.
- **Desmonta:** «el LCA se saca subiendo de a uno».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `07/01`, `09/01`, `07/06`.
- **Ruta corta:** no.

## `07/06` — Técnicas sobre árboles

- **Archivo:** `06-tecnicas-sobre-arboles.md`
- **Objetivo:** reconocer cuándo un problema de árbol pide *rerooting*, *small-to-large*, centroides o
  HLD.
- **Niveles:** *rerooting* [B] · *small-to-large* [B] · descomposición en centroides [B] · HLD [C].
- **📚 Lectura troncal:** Laaksonen, cap. 10; cp-algorithms.
- **Teoría:** por qué *small-to-large* es O(n log n); por qué la profundidad de centroides es
  O(log n); las cadenas pesadas de HLD.
- **Cubre:** cuándo cada una; cómo se combinan con un segment tree.
- **Código:** *rerooting* y centroides en C++ y Java.
- **Desmonta:** «para cada raíz recorro el árbol».
- **Problemas:** específicas: CSES, Codeforces.
- **Se toca con:** `13/03`, `09/03`.
- **Ruta corta:** no.

## `07/07` — Árboles dinámicos

- **Archivo:** `07-arboles-dinamicos.md`
- **Objetivo:** saber qué resuelven el *link-cut tree* y el *Euler tour tree* y cuándo aparecen.
- **Niveles:** *link-cut tree* [C] · *Euler tour tree* [C].
- **📚 Lectura troncal:** Tarjan, *Data Structures and Network Algorithms* (SIAM, 1983), cap. 5;
  cp-algorithms.
- **Teoría:** las garantías amortizadas O(log n).
- **Cubre:** conectividad dinámica; cuándo basta con Union-Find *offline* (`08/04`).
- **Código:** ninguno.
- **Desmonta:** «si el árbol cambia, hay que reconstruirlo».
- **Problemas:** 💀 específicas: SPOJ, Codeforces.
- **Se toca con:** `07/03`, `08/04`.
- **Ruta corta:** no.

## `07/08` — Simulación

**Problemas propios:** diámetro; XOR máximo con trie; LCA con consultas; uno de BST que se resuelve
con el recorrido en inorden y nada más.

---

# 11. ⛰️ Bloque `08` — Heaps y Union-Find

## `08/01` — Montículo binario

- **Archivo:** `01-monticulo-binario.md`
- **Objetivo:** implementar un montículo y demostrar que `heapify` es O(n).
- **Niveles:** montículo binario [A] · `heapify` [A] · d-ario [C] · cola indexada [B].
- **📚 Lectura troncal:** CLRS, cap. 6; Brassard y Bratley, cap. 5; Sedgewick y Wayne, cap. 2.4.
- **Teoría:** la propiedad de montículo como invariante; la suma `Σ h · n/2^(h+1)` que deja `heapify`
  en O(n).
- **Cubre:** `siftUp`/`siftDown` sobre un arreglo; `priority_queue`, `PriorityQueue`, `heapq`; la falta
  de `decrease-key`. Es el dueño del montículo.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «construir un heap es O(n log n)» · «`PriorityQueue` está ordenada».
- **Problemas:** bases.
- **🔥** Go (`container/heap` y su interfaz) y JavaScript (no hay heap).
- **Se toca con:** `08/02`, `15/01`, `02/06`.
- **Ruta corta:** no.

## `08/02` — Patrones con heap

- **Archivo:** `02-patrones-con-heap.md`
- **Objetivo:** resolver los k mayores, la mezcla de k listas, la mediana móvil y la planificación con
  un heap.
- **Niveles:** k mayores [A] · mezcla de k listas [A] · mediana con dos heaps [A] · borrado perezoso
  [B].
- **📚 Lectura troncal:** Sedgewick y Wayne, cap. 2.4; Skiena, cap. 3.
- **Teoría:** el invariante de los dos heaps de la mediana; por qué un *min-heap* de tamaño k da los k
  mayores en O(n log k).
- **Cubre:** el borrado perezoso cuando no hay `decrease-key` ni borrar; planificar tareas por
  prioridad.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «para los k mayores ordeno todo».
- **Problemas:** bases.
- **Se toca con:** `08/01`, `11/03`.
- **Ruta corta:** sí.

## `08/03` — Montículos fusionables

- **Archivo:** `03-monticulos-fusionables.md`
- **Objetivo:** saber qué ganan los montículos fusionables y por qué Fibonacci mejora Dijkstra en
  teoría y casi nunca en la práctica.
- **Niveles:** *leftist* [C] · binomial [C] · Fibonacci [C] · *pairing* [C].
- **📚 Lectura troncal:** CLRS, cap. 19; Brassard y Bratley, cap. 5 (binomiales).
- **Teoría:** los costes amortizados de Fibonacci y el Dijkstra en O(m + n log n).
- **Cubre:** cuándo fusionar importa; *small-to-large* con heaps como alternativa práctica.
- **Código:** ninguno.
- **Desmonta:** «el heap de Fibonacci hace Dijkstra más rápido».
- **Problemas:** 💀 específica: SPOJ.
- **Se toca con:** `08/01`, `15/01`.
- **Ruta corta:** no.

## `08/04` — Union-Find

- **Archivo:** `04-union-find.md`
- **Objetivo:** implementar Union-Find con compresión y unión por rango, y saber qué garantiza.
- **Niveles:** Union-Find [A] · con pesos o paridad [B] · con *rollback* y *offline* [B].
- **📚 Lectura troncal:** CLRS, cap. 21; Sedgewick y Wayne, cap. 1.5; Brassard y Bratley, cap. 5.
- **Teoría:** el coste amortizado O(α(n)) enunciado (sin prueba completa); por qué la unión por rango
  sola da O(log n).
- **Cubre:** componentes, ciclos en grafo no dirigido, Kruskal (`15/04`); DSU con pesos para
  diferencias; *rollback* sin compresión. Es el dueño de Union-Find.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «Union-Find es O(1)» · «con compresión basta, la unión da igual».
- **Problemas:** bases.
- **Se toca con:** `15/04`, `14/03`, `02/03`.
- **Ruta corta:** no.

## `08/05` — Simulación

**Problemas propios:** mediana móvil; k listas; componentes con uniones y consultas; uno que parece de
heap y se resuelve ordenando una vez.

---

# 12. 📊 Bloque `09` — Consultas sobre rangos

## `09/01` — *Sparse table* y RMQ

- **Archivo:** `01-sparse-table.md`
- **Objetivo:** responder mínimos por rango en O(1) tras O(n log n) de preparación.
- **Niveles:** *sparse table* [B].
- **📚 Lectura troncal:** Laaksonen, cap. 9; cp-algorithms.
- **Teoría:** por qué solo sirve con operaciones idempotentes (los dos bloques se solapan).
- **Cubre:** mínimo, máximo, gcd; por qué no suma.
- **Código:** C++ y Java.
- **Desmonta:** «la *sparse table* sirve para sumas».
- **Problemas:** bases; específica: CSES, Library Checker.
- **Se toca con:** `07/05`, `09/03`.
- **Ruta corta:** no.

## `09/02` — Fenwick

- **Archivo:** `02-fenwick.md`
- **Objetivo:** sumas por prefijo con actualizaciones en O(log n), y sus variantes.
- **Niveles:** puntual/rango [A] · rango/puntual [A] · rango/rango [B] · 2D [B] · búsqueda por bits [B].
- **📚 Lectura troncal:** Fenwick, «A New Data Structure for Cumulative Frequency Tables» *Software: Practice and Experience* 24(3), 1994; Laaksonen, cap. 9.
- **Teoría:** `i & -i` y qué rango cubre cada celda; por qué la operación tiene que ser invertible.
- **Cubre:** índices desde 1; contar inversiones (`05/03`); compresión (`04/04`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «Fenwick sirve para mínimos» · «con índice 0 funciona».
- **Problemas:** bases; específicas: CSES, Library Checker.
- **Se toca con:** `04/01`, `09/03`, `17/01`.
- **Ruta corta:** no.

## `09/03` — Segment tree

- **Archivo:** `03-segment-tree.md`
- **Objetivo:** responder consultas por rango con cualquier operación asociativa, con actualizaciones
  puntuales y por rango.
- **Niveles:** iterativo [B] · recursivo [B] · *lazy propagation* [B].
- **📚 Lectura troncal:** de Berg y otros, cap. 10; Laaksonen, cap. 9; cp-algorithms.
- **Teoría:** por qué una consulta toca O(log n) nodos; la composición de etiquetas *lazy* como
  monoide.
- **Cubre:** el nodo genérico (valor, combinación, neutro); suma y asignación por rango.
- **Código:** C++ y Java; Python solo el iterativo.
- **Desmonta:** «el segment tree es siempre la respuesta» · «la *lazy* es solo para sumas».
- **Problemas:** bases; específicas: CSES, SPOJ, Library Checker.
- **Se toca con:** `09/02`, `09/04`, `07/06`.
- **Ruta corta:** no.

## `09/04` — Segment tree avanzado

- **Archivo:** `04-segment-tree-avanzado.md`
- **Objetivo:** reconocer *merge sort tree*, persistente, sobre valores y Li Chao.
- **Niveles:** *merge sort tree* [C] · persistente [C] · sobre valores (k-ésimo) [C] · Li Chao [C].
- **📚 Lectura troncal:** cp-algorithms; Driscoll y otros, «Making Data Structures Persistent» *Journal of Computer and System Sciences* 38, 1989.
- **Teoría:** O(log n) nodos nuevos por versión.
- **Cubre:** cuándo cada una.
- **Código:** ninguno.
- **Desmonta:** «persistente es copiar el arreglo».
- **Problemas:** 💀 específicas: SPOJ, Codeforces.
- **Se toca con:** `09/03`, `13/05`.
- **Ruta corta:** no.

## `09/05` — Raíz cuadrada y Mo

- **Archivo:** `05-raiz-cuadrada-y-mo.md`
- **Objetivo:** usar descomposición en raíz y el algoritmo de Mo cuando las consultas se pueden
  reordenar.
- **Niveles:** descomposición en raíz [B] · Mo [B] · consultas *offline* [B].
- **📚 Lectura troncal:** Laaksonen, cap. 15; cp-algorithms.
- **Teoría:** el coste O((n + q)√n) de Mo por el orden de bloques.
- **Cubre:** cuándo *offline* es legítimo.
- **Código:** C++ y Java.
- **Desmonta:** «√n es lento».
- **Problemas:** específicas: SPOJ, Codeforces, CSES.
- **Se toca con:** `09/03`.
- **Ruta corta:** no.

## `09/06` — Árbol cartesiano y *wavelet tree*

- **Archivo:** `06-arbol-cartesiano-y-wavelet.md`
- **Objetivo:** reconocer las dos estructuras y lo que resuelven.
- **Niveles:** árbol cartesiano [C] · *wavelet tree* [C].
- **📚 Lectura troncal:** cp-algorithms; Navarro, *Compact Data Structures* (Cambridge, 2016), el capítulo de *wavelet trees*.
- **Teoría:** la construcción en O(n) con pila del cartesiano; RMQ ↔ LCA.
- **Cubre:** k-ésimo en rango con *wavelet*.
- **Código:** ninguno.
- **Desmonta:** «RMQ y LCA son problemas distintos».
- **Problemas:** 💀 específicas: SPOJ, Codeforces.
- **Se toca con:** `07/05`, `06/01`.
- **Ruta corta:** no.

## `09/07` — Simulación

**Problemas propios:** suma por rango con actualizaciones; asignación por rango con *lazy*; uno de Mo;
y uno que se resuelve con prefijos porque no hay actualizaciones.

---

# 13. 🔍 Bloque `10` — Búsqueda completa y divide y vencerás

## `10/01` — Recursión

- **Archivo:** `01-recursion.md`
- **Objetivo:** escribir recursión correcta, saber cuánta pila usa y pasarla a iterativa.
- **Niveles:** recursión y pila de llamadas [A] · paso a iterativo [A].
- **📚 Lectura troncal:** Erickson, *Algorithms*, cap. 1; Brassard y Bratley, cap. 1.
- **Teoría:** la corrección por inducción; la pila como estado implícito.
- **Cubre:** profundidad máxima en cada lenguaje (C++ pila del sistema, Java `-Xss` y `Thread`, Python
  `setrecursionlimit` y su techo); la recursión de cola que ningún juez elimina. Es el dueño de la
  recursión.
- **Código:** plantillas en los tres lenguajes, recursiva e iterativa.
- **Desmonta:** «la recursión es más elegante y ya» · «subo el límite y listo».
- **Problemas:** bases.
- **🔥** Go (pilas que crecen solas) y JavaScript (límite de pila de V8): la profundidad cambia el
  diseño.
- **Se toca con:** `02/04`, `12/01`, `14/03`.
- **Ruta corta:** sí.

## `10/02` — Generar subconjuntos, permutaciones y combinaciones

- **Archivo:** `02-generar-subconjuntos-y-permutaciones.md`
- **Objetivo:** enumerar los 2ⁿ subconjuntos y las n! permutaciones sin repetir ni olvidar.
- **Niveles:** máscaras de bits [A] · permutaciones con `next_permutation` y recursivas [A] ·
  combinaciones [A].
- **📚 Lectura troncal:** Knuth, Vol. 4A, §7.2.1; Skiena, cap. 9.
- **Teoría:** la biyección subconjunto ↔ máscara; el algoritmo de la siguiente permutación y por qué
  la genera en orden.
- **Cubre:** lo mínimo de operaciones de bits que hace falta (el resto es de `17/01`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «2²⁰ es mucho».
- **Problemas:** bases.
- **Se toca con:** `17/01`, `10/03`.
- **Ruta corta:** sí.

## `10/03` — *Backtracking* con poda y ramificación y poda

- **Archivo:** `03-backtracking-y-poda.md`
- **Objetivo:** explorar un espacio de soluciones podando lo que no puede llevar a una mejor.
- **Niveles:** *backtracking* [A] · ramificación y poda [B].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 9; Erickson, cap. 2.
- **Teoría:** el árbol de estados; la cota que justifica la poda; por qué la poda no cambia el caso
  peor.
- **Cubre:** N reinas, suma de subconjuntos, sudoku; deshacer el estado al volver.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el *backtracking* es fuerza bruta».
- **Problemas:** bases.
- **Se toca con:** `10/02`, `10/04`.
- **Ruta corta:** sí.

## `10/04` — *Meet in the middle*, IDDFS y *Dancing Links*

- **Archivo:** `04-meet-in-the-middle-iddfs-y-dancing-links.md`
- **Objetivo:** partir una búsqueda exponencial en dos, buscar en profundidad iterativa, y reconocer el
  problema de cobertura exacta.
- **Niveles:** *meet in the middle* [B] · IDDFS [B] · *Dancing Links* [C].
- **📚 Lectura troncal:** Knuth, Vol. 4B, §7.2.2 (*Dancing Links*); Russell y Norvig, cap. 3 (IDDFS).
- **Teoría:** 2ⁿ → 2·2^(n/2); la optimalidad de IDDFS con coste unitario y su sobrecoste acotado.
- **Cubre:** suma de subconjuntos con n = 40; cobertura exacta.
- **Código:** *meet in the middle* en C++ y Java.
- **Desmonta:** «n = 40 es imposible».
- **Problemas:** bases; específicas: CSES, SPOJ.
- **Se toca con:** `10/03`, `15/03`.
- **Ruta corta:** no.

## `10/05` — Divide y vencerás

- **Archivo:** `05-divide-y-venceras.md`
- **Objetivo:** diseñar un divide y vencerás, escribir su recurrencia y reconocer cuándo un problema es
  NP-difícil.
- **Niveles:** el esquema [A] · par de puntos más cercano [B] · Karatsuba [B] · exponenciación rápida
  [A] · reconocer lo NP-difícil [A].
- **📚 Lectura troncal:** Brassard y Bratley, caps. 7 y 12; Kleinberg y Tardos, caps. 5 y 8.
- **Teoría:** la recurrencia de cada uno (`02/02`); P, NP, NP-completo y la reducción como
  herramienta para reconocer, enunciados sin prueba (la prueba es del bloque `22`).
- **Cubre:** cuándo dividir no ayuda; qué hacer ante un NP-difícil en una entrevista (n pequeño,
  aproximación, heurística).
- **Código:** exponenciación rápida en los tres lenguajes; Karatsuba en C++.
- **Desmonta:** «NP significa no polinomial» · «si es NP-difícil, no se puede resolver».
- **Problemas:** bases.
- **Se toca con:** `02/02`, `17/03`, `18/05`.
- **Ruta corta:** no.

## `10/06` — Juegos y búsqueda adversarial

- **Archivo:** `06-juegos-y-busqueda-adversarial.md`
- **Objetivo:** resolver un juego de dos jugadores con minimax, podarlo con alfa-beta y saber qué
  aporta MCTS.
- **Niveles:** minimax [B] · alfa-beta [B] · MCTS [C].
- **📚 Lectura troncal:** Russell y Norvig, cap. 5; Brassard y Bratley, cap. 9.
- **Teoría:** la corrección de alfa-beta (nunca cambia el valor); su mejor caso O(b^(d/2)); MCTS como
  Monte Carlo (`19/01`).
- **Cubre:** juegos de suma cero; la relación con Sprague-Grundy (`17/08`).
- **Código:** minimax con alfa-beta en C++ y Java.
- **Desmonta:** «alfa-beta da una aproximación».
- **Problemas:** bases; específica: CodinGame (bots).
- **Se toca con:** `17/08`, `19/04`.
- **Ruta corta:** no.

## `10/07` — Simulación

**Problemas propios:** subconjuntos con poda; n = 40 con *meet in the middle*; exponenciación modular;
uno que se resuelve probando todas las permutaciones porque `n ≤ 8`.

---

# 14. 🪙 Bloque `11` — Voraces

## `11/01` — Cuándo funciona un voraz

- **Archivo:** `01-cuando-funciona-un-voraz.md`
- **Objetivo:** demostrar que un voraz es correcto, o encontrar el contraejemplo.
- **Niveles:** elección voraz y subestructura óptima [A] · argumento de intercambio [A] · «el voraz se
  adelanta» [A].
- **📚 Lectura troncal:** Kleinberg y Tardos, cap. 4; Brassard y Bratley, cap. 6; CLRS, cap. 16.
- **Teoría:** las dos propiedades; las dos formas de prueba (intercambio y *greedy stays ahead*), con un
  ejemplo completo de cada una.
- **Cubre:** cómo buscar contraejemplos pequeños con fuerza bruta (`01/05`).
- **Código:** ninguno nuevo; la selección de actividades como ejemplo.
- **Desmonta:** «el voraz funciona porque es intuitivo».
- **Problemas:** bases; Codility: lección 16 (*Greedy algorithms*).
- **Se toca con:** `02/04`, `11/02`, `11/04`.
- **Ruta corta:** no.

## `11/02` — Intervalos

- **Archivo:** `02-intervalos.md`
- **Objetivo:** resolver los cuatro problemas clásicos de intervalos con el orden correcto.
- **Niveles:** selección de actividades [A] · cubrimiento con puntos [A] · mezcla [A] · mínimo de
  salas [A].
- **📚 Lectura troncal:** Kleinberg y Tardos, cap. 4.1; CLRS, cap. 16.1.
- **Teoría:** por qué ordenar por fin (y no por inicio ni por duración), con el argumento.
- **Cubre:** el mínimo de salas con barrido o heap (`04/04`, `08/02`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «ordeno por inicio y listo» · «el intervalo más corto primero».
- **Problemas:** bases.
- **Se toca con:** `11/01`, `04/04`.
- **Ruta corta:** sí.

## `11/03` — Plazos, Huffman, mochila fraccionaria y monedas

- **Archivo:** `03-plazos-huffman-y-monedas.md`
- **Objetivo:** aplicar el voraz a planificación con plazos, a códigos óptimos y a monedas, y saber
  cuándo las monedas dejan de ser voraces.
- **Niveles:** planificación con plazos [A] · Huffman [A] · mochila fraccionaria [A] · monedas
  canónicas [A].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 6; CLRS, cap. 16.3; Kleinberg y Tardos, cap. 4.
- **Teoría:** la optimalidad de Huffman; por qué el voraz de monedas falla con `{1, 3, 4}` y 6.
- **Cubre:** el contraste con la mochila 0/1 (`12/03`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el cambio de monedas es voraz».
- **Problemas:** bases.
- **Se toca con:** `12/03`, `08/02`.
- **Ruta corta:** no.

## `11/04` — Matroides y cómo romper un voraz

- **Archivo:** `04-matroides-y-contraejemplos.md`
- **Objetivo:** saber qué estructura garantiza que el voraz sea óptimo, y fabricar contraejemplos.
- **Niveles:** matroides [C] · contraejemplos [A].
- **📚 Lectura troncal:** CLRS, cap. 16.4; Brassard y Bratley, cap. 6.
- **Teoría:** el teorema de Rado-Edmonds enunciado; Kruskal como voraz sobre la matroide gráfica.
- **Cubre:** el método para buscar un contraejemplo.
- **Código:** ninguno.
- **Desmonta:** «si no encuentro contraejemplo, el voraz es correcto».
- **Problemas:** propios: romper voraces.
- **Se toca con:** `11/01`, `15/04`.
- **Ruta corta:** no.

## `11/05` — Simulación

**Problemas propios:** intervalos con pesos donde el voraz falla (y pide DP); planificación con plazos;
un voraz con prueba de intercambio; y uno que se resuelve por fuerza bruta porque `n ≤ 10`.

---

# 15. 🧮 Bloque `12` — DP clásica

## `12/01` — De la recursión a la tabla

- **Archivo:** `01-de-la-recursion-a-la-tabla.md`
- **Objetivo:** pasar de una recursión exponencial a una DP: estado, transición, orden, memoria y
  reconstrucción.
- **Niveles:** memoización [A] · tabulación [A] · reconstrucción [A].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 8; Erickson, cap. 3; CLRS, cap. 15.
- **Teoría:** subestructura óptima y subproblemas solapados; el principio de optimalidad de Bellman; el
  coste como (estados × transición).
- **Cubre:** Fibonacci como ejemplo trabajado; el orden de cálculo; cuándo memo y cuándo tabla. Es el
  dueño de la DP.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «DP es memorizar» · «la memoización siempre es más lenta».
- **Problemas:** bases; Codility: lección 13 (*Fibonacci numbers*).
- **Se toca con:** `10/01`, `12/02`, `11/01`.
- **Ruta corta:** sí.

## `12/02` — DP lineal y LIS

- **Archivo:** `02-dp-lineal-y-lis.md`
- **Objetivo:** resolver las DP de una dimensión y la LIS en O(n log n).
- **Niveles:** escaleras y robos [A] · LIS O(n²) [A] · LIS O(n log n) [A].
- **📚 Lectura troncal:** CLRS, cap. 15 (problemas); Skiena, cap. 10.
- **Teoría:** el invariante de las «colas» de la LIS y por qué permite la binaria.
- **Cubre:** Kadane como DP (enlaza `04/03`); reconstruir la LIS.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el arreglo de colas es la LIS».
- **Problemas:** bases.
- **Se toca con:** `04/03`, `05/04`.
- **Ruta corta:** sí.

## `12/03` — Mochilas

- **Archivo:** `03-mochilas.md`
- **Objetivo:** resolver la mochila 0/1, la ilimitada y la acotada, y el cambio de monedas en sus dos
  versiones.
- **Niveles:** 0/1 [A] · ilimitada [A] · acotada con división binaria [B] · monedas: contar y mínimo
  [A] · una fila de memoria [A].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 8; Kleinberg y Tardos, cap. 6.4.
- **Teoría:** por qué es pseudopolinomial (y no contradice que sea NP-difícil); el sentido del bucle al
  usar una sola fila.
- **Cubre:** el contraste con la fraccionaria (`11/03`); el orden de los bucles al contar combinaciones
  o permutaciones.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «O(n·W) es polinomial» · «el orden de los bucles da igual».
- **Problemas:** bases; Codility: lección 17 (*Dynamic programming*).
- **Se toca con:** `11/03`, `10/05`.
- **Ruta corta:** sí.

## `12/04` — DP sobre cadenas

- **Archivo:** `04-dp-sobre-cadenas.md`
- **Objetivo:** resolver LCS, distancia de edición y palíndromos con DP en dos dimensiones.
- **Niveles:** LCS [A] · distancia de edición [A] · subsecuencias y palíndromos [A].
- **📚 Lectura troncal:** CLRS, cap. 15.4; Kleinberg y Tardos, cap. 6.6.
- **Teoría:** la recurrencia de cada una y su reconstrucción; Hirschberg como ficha.
- **Cubre:** memoria en dos filas.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «LCS es la subcadena común».
- **Problemas:** bases.
- **Se toca con:** `12/01`, `16/01`.
- **Ruta corta:** no.

## `12/05` — DP en rejillas y de intervalos

- **Archivo:** `05-rejillas-e-intervalos.md`
- **Objetivo:** resolver caminos en rejilla y DP sobre intervalos.
- **Niveles:** rejillas [A] · intervalos: cadena de matrices [B] · *burst balloons* [B].
- **📚 Lectura troncal:** CLRS, cap. 15.2; Brassard y Bratley, cap. 8.
- **Teoría:** el orden por longitud del intervalo; O(n³).
- **Cubre:** obstáculos; árbol binario de búsqueda óptimo como ficha.
- **Código:** C++ y Java; Python en rejillas.
- **Desmonta:** «la DP de intervalos se llena por filas».
- **Problemas:** bases.
- **Se toca con:** `13/05`, `12/01`.
- **Ruta corta:** no.

## `12/06` — Conteo con DP

- **Archivo:** `06-conteo.md`
- **Objetivo:** contar caminos, particiones y combinaciones con DP y módulo.
- **Niveles:** conteo [A] · particiones [B].
- **📚 Lectura troncal:** Graham, Knuth y Patashnik, *Concrete Mathematics*, cap. 7;
  Laaksonen, cap. 6.
- **Teoría:** contar sin repetir (orden de los bucles), y la relación con la combinatoria de `17/05`.
- **Cubre:** módulo en cada paso.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «contar es como optimizar, cambiando `max` por `+`».
- **Problemas:** bases; específica: CSES (*Dynamic Programming*).
- **🔥** JavaScript: el módulo en cada suma y producto con `BigInt` o partido.
- **Se toca con:** `17/05`, `12/03`.
- **Ruta corta:** no.

## `12/07` — Simulación

**Problemas propios:** mochila con reconstrucción; distancia de edición; uno de intervalos; y uno que
parece DP y es voraz con prueba de intercambio.

---

# 16. 🧠 Bloque `13` — DP avanzada

## `13/01` — DP con máscaras de bits

- **Archivo:** `01-mascaras-de-bits.md`
- **Objetivo:** resolver viajante y asignación con DP sobre subconjuntos, y sumas sobre subconjuntos.
- **Niveles:** DP sobre subconjuntos [B] · viajante [B] · SOS DP [B].
- **📚 Lectura troncal:** Laaksonen, cap. 6; cp-algorithms.
- **Teoría:** O(2ⁿ · n²) del viajante frente a O(n!); el orden de SOS.
- **Cubre:** iterar submáscaras en O(3ⁿ).
- **Código:** C++ y Java.
- **Desmonta:** «el viajante solo se resuelve por fuerza bruta».
- **Problemas:** bases; específicas: CSES, AtCoder.
- **Se toca con:** `10/02`, `17/01`.
- **Ruta corta:** no.

## `13/02` — *Digit DP*

- **Archivo:** `02-digit-dp.md`
- **Objetivo:** contar números en un rango que cumplen una propiedad de sus dígitos.
- **Niveles:** *digit DP* [B].
- **📚 Lectura troncal:** USACO Guide, *Digit DP* (cp-algorithms no tiene página; comprobado el 2026-10-04).
- **Teoría:** el estado (posición, «ya es menor», lo que la propiedad necesite).
- **Cubre:** `f(b) − f(a − 1)`.
- **Código:** C++ y Java.
- **Desmonta:** «para 10¹⁸ no hay forma».
- **Problemas:** específicas: CSES, AtCoder, SPOJ.
- **Se toca con:** `12/06`.
- **Ruta corta:** no.

## `13/03` — DP en árboles y en DAG

- **Archivo:** `03-dp-en-arboles-y-dag.md`
- **Objetivo:** resolver DP sobre un árbol (por subárbol) y sobre un DAG (en orden topológico).
- **Niveles:** DP en árboles [A] · DP sobre DAG [A] · *rerooting* como DP [B].
- **📚 Lectura troncal:** Kleinberg y Tardos, cap. 10.2 (conjunto independiente en árboles); Laaksonen, cap. 10.
- **Teoría:** por qué el orden topológico es el orden de la DP; conjunto independiente máximo en árbol.
- **Cubre:** el árbol T y el DAG D de §5.6.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «en un árbol la DP necesita memo».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `07/06`, `14/04`.
- **Ruta corta:** no.

## `13/04` — DP de probabilidad y esperanza

- **Archivo:** `04-probabilidad-y-esperanza.md`
- **Objetivo:** plantear una DP sobre probabilidades y sobre valores esperados.
- **Niveles:** DP de probabilidad [B] · esperanza hacia atrás [B].
- **📚 Lectura troncal:** Mitzenmacher y Upfal, cap. 2; Laaksonen, cap. 11.
- **Teoría:** la linealidad de la esperanza resumida en lo mínimo (su dueño es `17/06`); por qué la
  esperanza se calcula desde el final.
- **Cubre:** módulo e inverso para fracciones (adelanto de `17/03`).
- **Código:** C++ y Java.
- **Desmonta:** «la esperanza de un producto es el producto de esperanzas».
- **Problemas:** específicas: AtCoder, CSES.
- **Se toca con:** `17/06`, `17/03`.
- **Ruta corta:** no.

## `13/05` — Optimizaciones de DP

- **Archivo:** `05-optimizaciones.md`
- **Objetivo:** reconocer cuándo una DP O(n²) baja a O(n log n) o O(n).
- **Niveles:** cola monótona [B] · *convex hull trick* [B] · divide y vencerás [C] · Knuth [C].
- **📚 Lectura troncal:** cp-algorithms; Halim y otros, *Competitive Programming 4*, libro 2.
- **Teoría:** las condiciones (monotonía del óptimo, desigualdad del cuadrilátero) enunciadas.
- **Cubre:** cuándo cada una.
- **Código:** cola monótona y CHT en C++ y Java.
- **Desmonta:** «si la DP es O(n²), no hay nada que hacer».
- **Problemas:** específicas: Codeforces, AtCoder, SPOJ.
- **Se toca con:** `06/01`, `09/04`, `12/05`.
- **Ruta corta:** no.

## `13/06` — Recurrencias lineales y exponenciación de matrices

- **Archivo:** `06-recurrencias-lineales-y-matrices.md`
- **Objetivo:** calcular el término 10¹⁸ de una recurrencia lineal en O(k³ log n).
- **Niveles:** exponenciación de matrices [B].
- **📚 Lectura troncal:** Graham, Knuth y Patashnik, cap. 7; cp-algorithms.
- **Teoría:** la matriz de transición; por qué la potencia rápida es correcta (asociatividad).
- **Cubre:** Fibonacci en O(log n); caminos de longitud k en un grafo.
- **Código:** C++ y Java.
- **Desmonta:** «para n = 10¹⁸ hay que iterar».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `10/05`, `17/07`, `17/11`.
- **Ruta corta:** no.

## `13/07` — Trucos de nivel alto

- **Archivo:** `07-trucos-de-nivel-alto.md`
- **Objetivo:** reconocer *Aliens trick* y *slope trick*.
- **Niveles:** *Aliens trick* [C] · *slope trick* [C].
- **📚 Lectura troncal:** USACO Guide (*Lagrangian Relaxation*, *Slope Trick*; cp-algorithms no los tiene, comprobado el
  2026-10-04); los artículos de referencia de Codeforces, por título y sin URL.
- **Teoría:** la relajación lagrangiana y la convexidad que la permite.
- **Cubre:** cuándo aparecen; que son de concurso, no de entrevista.
- **Código:** ninguno.
- **Desmonta:** «la DP con k restricciones siempre es O(n·k)».
- **Problemas:** 💀 específica: Codeforces.
- **Se toca con:** `13/05`.
- **Ruta corta:** no.

## `13/08` — Simulación

**Problemas propios:** viajante pequeño; *digit DP*; DP en árbol; y uno que parece necesitar una
optimización y entra en O(n²) porque `n ≤ 3000`.

---

# 17. 🕸️ Bloque `14` — Grafos: recorridos

## `14/01` — Representaciones y su coste

- **Archivo:** `01-representaciones.md`
- **Objetivo:** elegir la representación de un grafo por sus operaciones y su tamaño.
- **Niveles:** listas de adyacencia, matriz, lista de aristas, implícito en rejilla [A].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 5; CLRS, cap. 22.1; Sedgewick y Wayne, cap. 4.1.
- **Teoría:** `Σ deg(v) = 2|E|`; grafos densos y dispersos.
- **Cubre:** el grafo G y el DAG D de §5.6; leer un grafo de la entrada. Es el dueño de las
  representaciones.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «la matriz es más simple, así que es mejor».
- **Problemas:** bases.
- **Se toca con:** `14/02`, `04/05`.
- **Ruta corta:** no.

## `14/02` — BFS

- **Archivo:** `02-bfs.md`
- **Objetivo:** encontrar distancias mínimas sin pesos y sus variantes.
- **Niveles:** BFS [A] · multifuente [A] · 0-1 BFS [A] · estados compuestos [A].
- **📚 Lectura troncal:** CLRS, cap. 22.2; Brassard y Bratley, cap. 9.
- **Teoría:** el invariante por niveles que prueba que la primera vez que se visita un nodo es por un
  camino mínimo; por qué 0-1 BFS con deque es correcto.
- **Cubre:** rejillas; estados (posición, llaves); reconstruir el camino.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «DFS también da el camino más corto» · «se marca visitado al sacar».
- **Problemas:** bases.
- **Se toca con:** `14/01`, `15/01`, `06/01`.
- **Ruta corta:** sí.

## `14/03` — DFS

- **Archivo:** `03-dfs.md`
- **Objetivo:** recorrer en profundidad y usar sus tiempos para ciclos, componentes y bipartición.
- **Niveles:** DFS [A] · ciclos [A] · bipartición [A] · componentes [A] · clasificación de aristas [B].
- **📚 Lectura troncal:** CLRS, cap. 22.3; Brassard y Bratley, cap. 9.
- **Teoría:** el teorema del paréntesis; ciclo en dirigido ↔ arista de retroceso.
- **Cubre:** colores blanco, gris, negro; DFS iterativo por la pila (`10/01`).
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «para detectar ciclo en dirigido basta con visitado».
- **Problemas:** bases.
- **Se toca con:** `14/04`, `14/05`, `08/04`.
- **Ruta corta:** sí.

## `14/04` — Orden topológico y DP sobre DAG

- **Archivo:** `04-orden-topologico.md`
- **Objetivo:** ordenar un DAG y detectar que no lo es.
- **Niveles:** Kahn [A] · por DFS [A].
- **📚 Lectura troncal:** CLRS, cap. 22.4; Sedgewick y Wayne, cap. 4.2.
- **Teoría:** existe orden topológico ↔ no hay ciclos; por qué el postorden invertido lo da.
- **Cubre:** el DAG D de §5.6; orden lexicográfico mínimo con heap; camino más largo en DAG.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el orden topológico es único».
- **Problemas:** bases.
- **Se toca con:** `13/03`, `14/03`.
- **Ruta corta:** sí.

## `14/05` — Componentes fuertemente conexas y 2-SAT

- **Archivo:** `05-componentes-fuertes-y-2sat.md`
- **Objetivo:** encontrar las SCC y resolver 2-SAT con ellas.
- **Niveles:** Tarjan [B] · Kosaraju [B] · 2-SAT [B].
- **📚 Lectura troncal:** CLRS, cap. 22.5; Sedgewick y Wayne, cap. 4.2.
- **Teoría:** por qué Kosaraju funciona (el grafo de componentes es un DAG); el grafo de implicaciones y
  la condición de 2-SAT.
- **Cubre:** el grafo condensado.
- **Código:** C++ y Java.
- **Desmonta:** «componentes fuertes es lo mismo que componentes».
- **Problemas:** bases; específicas: CSES, Codeforces.
- **Se toca con:** `14/03`, `22/04`.
- **Ruta corta:** no.

## `14/06` — Puentes, puntos de articulación y Euler

- **Archivo:** `06-puentes-articulacion-y-euler.md`
- **Objetivo:** encontrar aristas y nodos críticos, y caminos que usan cada arista una vez.
- **Niveles:** puentes y articulación [B] · Euler (Hierholzer) [B].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 9; CLRS, cap. 22 (problemas).
- **Teoría:** `low[v]`; el teorema de Euler sobre grados.
- **Cubre:** dirigido y no dirigido.
- **Código:** C++ y Java.
- **Desmonta:** «un camino de Euler es un camino hamiltoniano».
- **Problemas:** específicas: CSES, Codeforces.
- **Se toca con:** `14/03`.
- **Ruta corta:** no.

## `14/07` — Simulación

**Problemas propios:** BFS en rejilla con estado; orden topológico con detección de ciclo; bipartición;
y uno que se resuelve con un DFS simple aunque parezca de caminos mínimos.

---

# 18. 🛣️ Bloque `15` — Grafos con pesos y flujos

## `15/01` — Dijkstra

- **Archivo:** `01-dijkstra.md`
- **Objetivo:** escribir Dijkstra con heap y explicar por qué no admite pesos negativos.
- **Niveles:** Dijkstra con heap y perezoso [A] · sobre estados [A].
- **📚 Lectura troncal:** CLRS, cap. 24.3; Brassard y Bratley, cap. 6; Sedgewick y Wayne, cap. 4.4.
- **Teoría:** el invariante (los nodos extraídos tienen su distancia final) y su prueba; dónde la
  rompe un peso negativo; O((n + m) log n).
- **Cubre:** el grafo G de §5.6 con su traza; descartar entradas viejas del heap (autopsia de un bug);
  reconstruir el camino.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «Dijkstra encuentra el camino más corto» (sin la condición) · «con pesos negativos
  solo es más lento».
- **Problemas:** bases.
- **🔥** Go y JavaScript: el heap a mano cambia la implementación entera.
- **Se toca con:** `08/01`, `14/02`, `15/02`.
- **Ruta corta:** no.

## `15/02` — Bellman-Ford, Floyd-Warshall y Johnson

- **Archivo:** `02-bellman-ford-floyd-y-johnson.md`
- **Objetivo:** caminos mínimos con pesos negativos, entre todos los pares, y detectar ciclos negativos.
- **Niveles:** Bellman-Ford [A] · Floyd-Warshall [A] · Johnson [C] · por qué no SPFA [B].
- **📚 Lectura troncal:** CLRS, caps. 24.1 y 25; Brassard y Bratley, cap. 8 (Floyd).
- **Teoría:** n − 1 rondas bastan (un camino simple tiene a lo sumo n − 1 aristas); Floyd como DP sobre
  el nodo intermedio; la repesada de Johnson.
- **Cubre:** el orden de los bucles en Floyd; SPFA y su caso peor.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el orden de los bucles de Floyd da igual» · «SPFA es Bellman-Ford rápido».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `15/01`, `12/01`.
- **Ruta corta:** no.

## `15/03` — A\* y heurísticas admisibles

- **Archivo:** `03-a-estrella.md`
- **Objetivo:** usar A\* y saber qué heurística lo mantiene óptimo.
- **Niveles:** A\* [B].
- **📚 Lectura troncal:** Russell y Norvig, cap. 3; Brassard y Bratley, cap. 13.
- **Teoría:** admisibilidad y consistencia; por qué A\* con heurística consistente es óptimo; Dijkstra
  como A\* con `h = 0`.
- **Cubre:** Manhattan en rejilla; IDA\* como ficha (`10/04`).
- **Código:** C++ y Java.
- **Desmonta:** «A\* siempre es más rápido que Dijkstra».
- **Problemas:** bases; específica: CodinGame.
- **Se toca con:** `15/01`, `10/04`.
- **Ruta corta:** no.

## `15/04` — Árbol de expansión mínima

- **Archivo:** `04-arbol-de-expansion-minima.md`
- **Objetivo:** construir el árbol de expansión mínima con Kruskal y con Prim, y demostrarlo con la
  propiedad del corte.
- **Niveles:** Kruskal [A] · Prim [A] · Borůvka [C].
- **📚 Lectura troncal:** CLRS, cap. 23; Brassard y Bratley, cap. 6; Kleinberg y Tardos, cap. 4.5.
- **Teoría:** **la propiedad del corte** y la del ciclo, con su prueba por intercambio.
- **Cubre:** el grafo G de §5.6 (peso 12); Kruskal con Union-Find (`08/04`); Prim con heap.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «Prim y Dijkstra son lo mismo».
- **Problemas:** bases.
- **Se toca con:** `08/04`, `11/04`.
- **Ruta corta:** no.

## `15/05` — Flujo máximo y corte mínimo

- **Archivo:** `05-flujo-maximo.md`
- **Objetivo:** calcular el flujo máximo y entender el corte mínimo como su dual.
- **Niveles:** Ford-Fulkerson y Edmonds-Karp [B] · Dinic [B].
- **📚 Lectura troncal:** CLRS, cap. 26; Kleinberg y Tardos, cap. 7.
- **Teoría:** **el teorema de flujo máximo y corte mínimo**, con su prueba; la red residual; la cota
  de Edmonds-Karp.
- **Cubre:** la red R de §5.6; modelar un problema como flujo.
- **Código:** Edmonds-Karp y Dinic en C++ y Java.
- **Desmonta:** «el flujo máximo es la suma de las capacidades que salen de la fuente».
- **Problemas:** bases; específicas: CSES, SPOJ.
- **Se toca con:** `15/06`, `15/07`.
- **Ruta corta:** no.

## `15/06` — Emparejamientos

- **Archivo:** `06-emparejamientos.md`
- **Objetivo:** encontrar el emparejamiento máximo en un bipartito y saber qué resuelve el húngaro.
- **Niveles:** Kuhn [B] · Hopcroft-Karp [B] · König [B] · coste mínimo y húngaro [C].
- **📚 Lectura troncal:** Kleinberg y Tardos, cap. 7.5; CLRS, cap. 26.3.
- **Teoría:** caminos aumentantes (Berge); **el teorema de König**.
- **Cubre:** el emparejamiento como flujo.
- **Código:** Kuhn en C++ y Java.
- **Desmonta:** «el voraz da el emparejamiento máximo».
- **Problemas:** específicas: CSES, SPOJ.
- **Se toca con:** `15/05`.
- **Ruta corta:** no.

## `15/07` — Grafos de nivel experto

- **Archivo:** `07-grafos-de-nivel-experto.md`
- **Objetivo:** reconocer emparejamiento general, árbol de dominadores y flujo con cotas inferiores.
- **Niveles:** Edmonds (*blossom*) [C] · dominadores [C] · cotas inferiores [C].
- **📚 Lectura troncal:** Tarjan, *Data Structures and Network Algorithms* (SIAM, 1983); cp-algorithms (*Flows with
  demands*; no tiene páginas de las flores ni de dominadores: artículos originales).
- **Teoría:** las garantías enunciadas.
- **Cubre:** cuándo aparecen.
- **Código:** ninguno.
- **Desmonta:** «el emparejamiento general es como el bipartito».
- **Problemas:** 💀 específicas: SPOJ, Codeforces.
- **Se toca con:** `15/05`, `15/06`.
- **Ruta corta:** no.

## `15/08` — Simulación

**Problemas propios:** Dijkstra sobre estados; detectar ciclo negativo; árbol de expansión mínima con
una arista obligatoria; y uno donde BFS basta porque todos los pesos son iguales.

---

# 19. 🔤 Bloque `16` — Cadenas

## `16/01` — Cadenas en los tres lenguajes y patrones básicos

- **Archivo:** `01-cadenas-y-patrones-basicos.md`
- **Objetivo:** manipular cadenas sin costes ocultos y resolver frecuencias, anagramas y palíndromos.
- **Niveles:** inmutabilidad y concatenación [A] · frecuencias y anagramas [A] · palíndromos con dos
  punteros [A].
- **📚 Lectura troncal:** Sedgewick y Wayne, cap. 5 (introducción); la documentación de `std::string`,
  `String`/`StringBuilder` y `str`.
- **Teoría:** el coste cuadrático de concatenar en bucle con cadenas inmutables.
- **Cubre:** `StringBuilder`, `''.join`; bytes frente a caracteres; arreglo de 26 frente a mapa.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «`s += c` en un bucle es O(n)».
- **Problemas:** bases.
- **🔥** Go: las cadenas son bytes y los caracteres son `rune`; el índice no es el carácter.
- **Se toca con:** `12/04`, `16/02`.
- **Ruta corta:** no.

## `16/02` — KMP y la función de prefijo

- **Archivo:** `02-kmp.md`
- **Objetivo:** buscar un patrón en O(n + m) y entender la función de prefijo.
- **Niveles:** función de prefijo [A] · KMP [A] · autómata de KMP [B].
- **📚 Lectura troncal:** CLRS, cap. 32.4; Sedgewick y Wayne, cap. 5.3.
- **Teoría:** por qué el cálculo de la función de prefijo es lineal (el potencial del índice); la
  equivalencia con el autómata de `32.3`.
- **Cubre:** la cadena de juguete de §5.6 con su traza; periodo de una cadena.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «`indexOf` es O(n)».
- **Problemas:** bases; específica: CSES (*String Algorithms*).
- **Se toca con:** `16/03`, `16/05`, `16/07`.
- **Ruta corta:** no.

## `16/03` — Función Z y Manacher

- **Archivo:** `03-funcion-z-y-manacher.md`
- **Objetivo:** calcular coincidencias con prefijo y todos los palíndromos en O(n).
- **Niveles:** función Z [B] · Manacher [B].
- **📚 Lectura troncal:** Gusfield, cap. 1 (Z); cp-algorithms (Manacher).
- **Teoría:** la caja `[l, r]` y por qué cada posición se extiende una vez.
- **Cubre:** el truco del separador; relación Z ↔ prefijo.
- **Código:** C++ y Java.
- **Desmonta:** «el palíndromo más largo es O(n²) sí o sí».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `16/02`, `12/04`.
- **Ruta corta:** no.

## `16/04` — Hashing de cadenas aplicado

- **Archivo:** `04-hashing-de-cadenas.md`
- **Objetivo:** aplicar el hash polinomial a comparar subcadenas y a la binaria + hash.
- **Niveles:** comparar subcadenas [B] · binaria + hash [B].
- **📚 Lectura troncal:** CLRS, cap. 32.2; el capítulo `06/04` del corpus, que es el dueño.
- **Teoría:** la probabilidad de colisión acumulada en muchas comparaciones.
- **Cubre:** la subcadena repetida más larga; palíndromos con hash.
- **Código:** C++ y Java.
- **Desmonta:** «con hash no hace falta KMP».
- **Problemas:** específicas: CSES, Codeforces.
- **Se toca con:** `06/04`, `05/04`.
- **Ruta corta:** no.

## `16/05` — Aho-Corasick

- **Archivo:** `05-aho-corasick.md`
- **Objetivo:** buscar muchos patrones a la vez.
- **Niveles:** Aho-Corasick [B].
- **📚 Lectura troncal:** Aho y Corasick, «Efficient String Matching: An Aid to Bibliographic Search», *Communications of the ACM* 18(6), 1975;
  cp-algorithms.
- **Teoría:** los enlaces de fallo como función de prefijo sobre un trie.
- **Cubre:** contar apariciones; filtrado de palabras.
- **Código:** C++ y Java.
- **Desmonta:** «para k patrones, k veces KMP».
- **Problemas:** específicas: CSES, SPOJ.
- **Se toca con:** `07/04`, `16/02`.
- **Ruta corta:** no.

## `16/06` — *Suffix array*, LCP y *suffix automaton*

- **Archivo:** `06-suffix-array-y-automaton.md`
- **Objetivo:** construir un *suffix array* con LCP y saber qué da el *suffix automaton*.
- **Niveles:** *suffix array* O(n log n) [B] · LCP de Kasai [B] · *suffix automaton* [C].
- **📚 Lectura troncal:** Sedgewick y Wayne, cap. 6; Gusfield, cap. 7; cp-algorithms.
- **Teoría:** el duplicado de prefijos; la prueba de Kasai (el LCP baja como mucho uno).
- **Cubre:** subcadenas distintas; la subcadena repetida más larga.
- **Código:** C++ y Java.
- **Desmonta:** «ordenar los sufijos es O(n² log n)».
- **Problemas:** específicas: CSES, SPOJ, Library Checker.
- **Se toca con:** `16/04`, `16/08`.
- **Ruta corta:** no.

## `16/07` — Autómatas y expresiones regulares

- **Archivo:** `07-automatas-y-expresiones-regulares.md`
- **Objetivo:** pasar de una expresión regular a un autómata y explicar por qué un motor con
  *backtracking* puede explotar.
- **Niveles:** DFA y NFA [B] · Thompson [B] · subconjuntos [B] · *backtracking* y ReDoS [B].
- **📚 Lectura troncal:** Hopcroft, Motwani y Ullman, caps. 2–4; Sedgewick y Wayne, cap. 5.4.
- **Teoría:** equivalencia DFA ↔ NFA ↔ expresión regular (Kleene) enunciada; la explosión de estados;
  por qué la simulación del NFA es O(n·m). Es el dueño de los autómatas finitos.
- **Cubre:** `std::regex`, `java.util.regex`, `re`: todos con *backtracking*.
- **Código:** simulación de NFA en C++ y Java.
- **Desmonta:** «las expresiones regulares son lineales».
- **Problemas:** bases (LeetCode tiene *regex matching*).
- **Se toca con:** `16/02`, `22/01`.
- **Ruta corta:** no.

## `16/08` — Árbol de palíndromos y árbol de sufijos

- **Archivo:** `08-eertree-y-ukkonen.md`
- **Objetivo:** reconocer *eertree* y Ukkonen.
- **Niveles:** *eertree* [C] · Ukkonen [C].
- **📚 Lectura troncal:** Gusfield, cap. 6 (Ukkonen); cp-algorithms (Ukkonen; no tiene *eertree*: Rubinchik y Shur, 2018).
- **Teoría:** a lo sumo n + 2 palíndromos distintos; Ukkonen en O(n).
- **Cubre:** cuándo aparecen.
- **Código:** ninguno.
- **Desmonta:** «el árbol de sufijos es el *suffix array*».
- **Problemas:** 💀 específicas: SPOJ, Codeforces.
- **Se toca con:** `16/06`.
- **Ruta corta:** no.

## `16/09` — Simulación

**Problemas propios:** periodo mínimo con función de prefijo; palíndromo más largo; varios patrones; y
uno que se resuelve con `indexOf` porque las cadenas son cortas.

---

# 20. ➗ Bloque `17` — Matemática

## `17/01` — Bits

- **Archivo:** `01-bits.md`
- **Objetivo:** manipular bits con soltura y usar la base XOR.
- **Niveles:** operaciones y trucos [A] · `bitset` como optimización [B] · base XOR [B].
- **📚 Lectura troncal:** Warren, *Hacker's Delight*, caps. 2 y 5.
- **Teoría:** propiedades del XOR; la base XOR como eliminación de Gauss sobre GF(2).
- **Cubre:** `x & -x`, potencia de 2, contar bits (`__builtin_popcount`, `Integer.bitCount`,
  `int.bit_count`); desplazamientos con signo. Es el dueño de las operaciones de bits.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «`>>` divide por 2 siempre».
- **Problemas:** bases; Codility: lección 1 (*Iterations*).
- **🔥** JavaScript: los operadores de bits trabajan sobre 32 bits con signo; `>>>` es otra cosa.
- **Se toca con:** `10/02`, `13/01`, `09/02`.
- **Ruta corta:** no.

## `17/02` — Divisibilidad

- **Archivo:** `02-divisibilidad.md`
- **Objetivo:** calcular gcd, mcm y resolver ecuaciones diofánticas lineales.
- **Niveles:** Euclides [A] · extendido [A] · diofánticas [A].
- **📚 Lectura troncal:** CLRS, cap. 31.2; Graham, Knuth y Patashnik, cap. 4.
- **Teoría:** **la identidad de Bézout**; la cota de Lamé (Fibonacci) para Euclides.
- **Cubre:** mcm sin desbordar; soluciones generales.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «el mcm es a·b/gcd» (sin cuidar el desbordamiento).
- **Problemas:** bases; Codility: lección 12 (*Euclidean algorithm*).
- **Se toca con:** `17/03`.
- **Ruta corta:** no.

## `17/03` — Aritmética modular

- **Archivo:** `03-aritmetica-modular.md`
- **Objetivo:** exponenciar, invertir y combinar congruencias.
- **Niveles:** exponenciación modular [A] · inverso por Fermat y por extendido [A] · teorema chino del
  resto [B].
- **📚 Lectura troncal:** CLRS, caps. 31.3–31.6; Graham, Knuth y Patashnik, cap. 4.
- **Teoría:** **el pequeño teorema de Fermat** y el de Euler; cuándo existe inverso; el TCR.
- **Cubre:** división modular; inversos de 1..n en O(n). Es el dueño de la teoría modular; `01/04` dio
  lo básico.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «dividir módulo p es dividir y aplicar módulo».
- **Problemas:** bases; específica: CSES (*Mathematics*).
- **🔥** JavaScript: el producto de dos residuos de 10⁹ no cabe en un `double` exacto.
- **Se toca con:** `01/04`, `17/02`, `17/05`.
- **Ruta corta:** no.

## `17/04` — Primos

- **Archivo:** `04-primos.md`
- **Objetivo:** generar primos, factorizar y probar primalidad.
- **Niveles:** criba de Eratóstenes [A] · criba lineal y menor factor primo [A] · criba segmentada [B]
  · φ [B] · Miller-Rabin [B] · Pollard rho [C].
- **📚 Lectura troncal:** CLRS, cap. 31.8–31.9; Crandall y Pomerance, *Prime Numbers*, 2.ª ed. (Springer, 2005).
- **Teoría:** la criba en O(n log log n); los testigos deterministas de Miller-Rabin para 64 bits.
- **Cubre:** factorizar con el menor factor primo; divisores.
- **Código:** plantillas en los tres lenguajes; Miller-Rabin en C++ y Java.
- **Desmonta:** «comprobar hasta √n es rápido para 10¹⁸».
- **Problemas:** bases; Codility: lecciones 10 y 11 (*Prime and composite numbers*, *Sieve of
  Eratosthenes*); específica: Project Euler.
- **Se toca con:** `17/03`, `19/01`.
- **Ruta corta:** no.

## `17/05` — Combinatoria

- **Archivo:** `05-combinatoria.md`
- **Objetivo:** contar con fórmulas: coeficientes binomiales módulo p, Catalan, inclusión-exclusión.
- **Niveles:** `nCr` con factoriales [A] · Lucas [B] · Catalan [B] · inclusión-exclusión [B] · estrellas
  y barras [A] · Burnside [C].
- **📚 Lectura troncal:** Graham, Knuth y Patashnik, cap. 5; Laaksonen, cap. 11.
- **Teoría:** las identidades usadas, enunciadas; **el teorema de Lucas**; el principio de
  inclusión-exclusión.
- **Cubre:** precomputar factoriales e inversos; contar caminos en rejilla.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «`nCr` se calcula con la fórmula y luego módulo».
- **Problemas:** bases; específicas: CSES, Project Euler.
- **Se toca con:** `12/06`, `17/03`.
- **Ruta corta:** no.

## `17/06` — Probabilidad y esperanza

- **Archivo:** `06-probabilidad-y-esperanza.md`
- **Objetivo:** calcular esperanzas con la linealidad, sin listar el espacio de resultados.
- **Niveles:** linealidad de la esperanza [B] · indicadoras [B].
- **📚 Lectura troncal:** Mitzenmacher y Upfal, caps. 1–2; Graham, Knuth y Patashnik, cap. 8.
- **Teoría:** **la linealidad de la esperanza**, que vale sin independencia. Es el dueño; `13/04` lo
  resume.
- **Cubre:** el coleccionista de cupones; fracciones módulo p.
- **Código:** C++ y Java.
- **Desmonta:** «para la esperanza hace falta independencia».
- **Problemas:** específicas: AtCoder, CSES.
- **Se toca con:** `13/04`, `19/01`.
- **Ruta corta:** no.

## `17/07` — Matrices y eliminación de Gauss

- **Archivo:** `07-matrices-y-gauss.md`
- **Objetivo:** exponenciar matrices y resolver sistemas lineales, también sobre GF(2).
- **Niveles:** exponenciación [B] · Gauss [B] · sobre GF(2) [B].
- **📚 Lectura troncal:** CLRS, cap. 28; Strang, *Introduction to Linear Algebra*, 6.ª ed. (Wellesley-Cambridge, 2023).
- **Teoría:** O(n³); el pivote para la estabilidad numérica.
- **Cubre:** rango; sistemas sin solución o con infinitas.
- **Código:** C++ y Java.
- **Desmonta:** «Gauss con `double` es exacto».
- **Problemas:** específicas: CSES, Library Checker.
- **Se toca con:** `13/06`, `17/01`.
- **Ruta corta:** no.

## `17/08` — Teoría de juegos

- **Archivo:** `08-teoria-de-juegos.md`
- **Objetivo:** resolver juegos imparciales con Nim y Sprague-Grundy.
- **Niveles:** Nim [B] · Sprague-Grundy [B] · juegos sobre DAG [B].
- **📚 Lectura troncal:** Berlekamp, Conway y Guy, *Winning Ways*, 2.ª ed., vol. 1 (A K Peters, 2001); Laaksonen,
  cap. 11.
- **Teoría:** **el teorema de Bouton** (Nim); **el de Sprague-Grundy**.
- **Cubre:** posiciones ganadoras y perdedoras; el mex.
- **Código:** C++ y Java.
- **Desmonta:** «hay que simular todas las partidas».
- **Problemas:** bases; específica: CSES.
- **Se toca con:** `10/06`, `14/04`.
- **Ruta corta:** no.

## `17/09` — FFT y NTT

- **Archivo:** `09-fft-y-ntt.md`
- **Objetivo:** saber que dos polinomios se multiplican en O(n log n) y cuándo eso resuelve un
  problema.
- **Niveles:** FFT [C] · NTT [C].
- **📚 Lectura troncal:** CLRS, cap. 30.
- **Teoría:** evaluación e interpolación en las raíces de la unidad.
- **Cubre:** convoluciones; cuándo NTT evita los errores de punto flotante.
- **Código:** ninguno.
- **Desmonta:** «multiplicar polinomios es O(n²) sí o sí».
- **Problemas:** 💀 específica: Library Checker.
- **Se toca con:** `10/05`, `17/11`.
- **Ruta corta:** no.

## `17/10` — Teoría de números avanzada

- **Archivo:** `10-teoria-de-numeros-avanzada.md`
- **Objetivo:** reconocer Möbius, Dirichlet, logaritmo discreto y raíces primitivas.
- **Niveles:** Möbius [C] · convolución de Dirichlet [C] · logaritmo discreto (*baby-step giant-step*)
  [C] · raíces primitivas [C].
- **📚 Lectura troncal:** Graham, Knuth y Patashnik, cap. 4; cp-algorithms.
- **Teoría:** la inversión de Möbius enunciada.
- **Cubre:** cuándo aparecen.
- **Código:** ninguno.
- **Desmonta:** «el logaritmo discreto es como el real».
- **Problemas:** 💀 específicas: Project Euler, Library Checker.
- **Se toca con:** `17/03`, `17/04`.
- **Ruta corta:** no.

## `17/11` — Funciones generadoras y Berlekamp-Massey

- **Archivo:** `11-funciones-generadoras.md`
- **Objetivo:** reconocer cuándo una función generadora o Berlekamp-Massey resuelve una recurrencia.
- **Niveles:** funciones generadoras [C] · Berlekamp-Massey [C].
- **📚 Lectura troncal:** Graham, Knuth y Patashnik, cap. 7; Sedgewick y Flajolet, cap. 3.
- **Teoría:** la serie como objeto; encontrar la recurrencia lineal mínima.
- **Cubre:** cuándo aparecen.
- **Código:** ninguno.
- **Desmonta:** «sin la recurrencia no hay nada que hacer».
- **Problemas:** 💀 específica: Library Checker.
- **Se toca con:** `13/06`, `02/02`.
- **Ruta corta:** no.

## `17/12` — Simulación

**Problemas propios:** exponenciación modular con inverso; criba y factorización; un juego de Nim
disfrazado; y uno que se resuelve probando divisores hasta √n porque n ≤ 10⁹ y hay una sola consulta.

---

# 21. 📐 Bloque `18` — Geometría

**Fuera de las rutas básicas** (§13 de la guía). Lo que sí sale en una prueba de empresa se marca en
`18/01` y `18/03` como «lo que sí te pueden preguntar».

## `18/01` — Vectores, productos y orientación

- **Archivo:** `01-vectores-y-orientacion.md`
- **Objetivo:** usar el producto cruz para orientación y área, en enteros siempre que se pueda.
- **Niveles:** vectores, punto y cruz [A] · orientación [A] · enteros frente a épsilon [A].
- **📚 Lectura troncal:** de Berg y otros, cap. 1; CLRS, cap. 33.1.
- **Teoría:** el signo del producto cruz y el área orientada.
- **Cubre:** los puntos P de §5.6; por qué los enteros evitan el épsilon.
- **Código:** plantillas en los tres lenguajes.
- **Desmonta:** «la geometría es con `double`».
- **Problemas:** bases; específicas: CSES (*Geometry*), Kattis.
- **Se toca con:** `18/02`, `01/04`.
- **Ruta corta:** no.

## `18/02` — Rectas y segmentos

- **Archivo:** `02-rectas-y-segmentos.md`
- **Objetivo:** decidir si dos segmentos se cortan y calcular distancias.
- **Niveles:** intersección de segmentos [B] · distancias [B].
- **📚 Lectura troncal:** CLRS, cap. 33.1; O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998).
- **Teoría:** los cuatro productos cruz y los casos colineales.
- **Cubre:** punto en segmento; distancia punto-recta.
- **Código:** C++ y Java.
- **Desmonta:** «si los productos cruz cambian de signo, se cortan» (sin colineales).
- **Problemas:** específicas: CSES, Kattis, SPOJ.
- **Se toca con:** `18/01`, `18/05`.
- **Ruta corta:** no.

## `18/03` — Polígonos

- **Archivo:** `03-poligonos.md`
- **Objetivo:** calcular el área de un polígono y decidir si un punto está dentro.
- **Niveles:** fórmula del cordón [B] · punto en polígono [B] · Pick [B].
- **📚 Lectura troncal:** O'Rourke, cap. 1.
- **Teoría:** la fórmula del cordón como suma de áreas orientadas; **el teorema de Pick**.
- **Cubre:** rayos y número de vueltas; el solapamiento de rectángulos (lo que sí sale en entrevista).
- **Código:** C++ y Java.
- **Desmonta:** «el área de un polígono necesita triangularlo».
- **Problemas:** bases (rectángulos); específicas: CSES, Kattis.
- **Se toca con:** `18/01`, `18/04`.
- **Ruta corta:** no.

## `18/04` — Envolvente convexa

- **Archivo:** `04-envolvente-convexa.md`
- **Objetivo:** construir la envolvente convexa en O(n log n) y saber qué permite.
- **Niveles:** cadena monótona de Andrew [B] · *rotating calipers* [C].
- **📚 Lectura troncal:** de Berg y otros, cap. 1; CLRS, cap. 33.3.
- **Teoría:** la cota Ω(n log n) por reducción desde la ordenación; los puntos colineales.
- **Cubre:** los puntos P de §5.6; diámetro de un conjunto de puntos.
- **Código:** C++ y Java.
- **Desmonta:** «la envolvente se hace con todos los triángulos».
- **Problemas:** específicas: CSES, Kattis, SPOJ.
- **Se toca con:** `18/01`, `13/05`.
- **Ruta corta:** no.

## `18/05` — Barrido geométrico

- **Archivo:** `05-barrido-geometrico.md`
- **Objetivo:** usar el barrido para el par más cercano, la unión de rectángulos y las intersecciones.
- **Niveles:** par más cercano [B] · unión de rectángulos [C] · Bentley-Ottmann [C].
- **📚 Lectura troncal:** de Berg y otros, cap. 2; Kleinberg y Tardos, cap. 5.4.
- **Teoría:** por qué la franja tiene pocos puntos por celda.
- **Cubre:** la relación con `04/04` y con el divide y vencerás de `10/05`.
- **Código:** par más cercano en C++ y Java.
- **Desmonta:** «el par más cercano es O(n²)».
- **Problemas:** específicas: CSES, SPOJ.
- **Se toca con:** `04/04`, `10/05`.
- **Ruta corta:** no.

## `18/06` — Geometría avanzada

- **Archivo:** `06-geometria-avanzada.md`
- **Objetivo:** reconocer intersección de semiplanos, Delaunay, Voronoi y la geometría 3D.
- **Niveles:** semiplanos [C] · Delaunay y Voronoi [C] · 3D [C].
- **📚 Lectura troncal:** de Berg y otros, caps. 4, 7 y 9.
- **Teoría:** las garantías enunciadas.
- **Cubre:** cuándo aparecen.
- **Código:** ninguno.
- **Desmonta:** «Voronoi es solo para mapas».
- **Problemas:** 💀 específicas: Kattis, SPOJ.
- **Se toca con:** `18/04`.
- **Ruta corta:** no.

## `18/07` — Simulación

**Problemas propios:** área de un polígono; envolvente convexa; intersección de segmentos con
colineales; y uno que se resuelve con un doble bucle porque n ≤ 2000.

---

# 22. 🎲 Bloque `19` — Aleatorizados y probabilísticos

**Lo que pide un perfil senior.** Es el bloque menos competitivo y el que más rinde en una entrevista
de arquitectura.

## `19/01` — Las Vegas y Monte Carlo

- **Archivo:** `01-las-vegas-y-monte-carlo.md`
- **Objetivo:** distinguir los dos tipos de algoritmo aleatorizado y acotar su error o su tiempo.
- **Niveles:** Las Vegas [B] · Monte Carlo [B] · *quicksort* aleatorio [B] · Freivalds [B] · Miller-Rabin
  como Monte Carlo [B].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 10; Mitzenmacher y Upfal, cap. 1.
- **Teoría:** amplificar la probabilidad de acierto repitiendo; el tiempo esperado de *quicksort*.
- **Cubre:** semillas aleatorias contra *hacks* (`06/03`).
- **Código:** Freivalds en C++ y Java.
- **Desmonta:** «aleatorizado significa que a veces falla».
- **Problemas:** específicas: Codeforces, CSES.
- **Se toca con:** `05/01`, `17/04`, `06/03`.
- **Ruta corta:** no.

## `19/02` — Hashing universal y análisis esperado

- **Archivo:** `02-hashing-universal-y-analisis-esperado.md`
- **Objetivo:** explicar el hashing universal y analizar en esperanza las estructuras aleatorizadas.
- **Niveles:** hashing universal [B] · análisis esperado de *treap* y *skip list* [B].
- **📚 Lectura troncal:** CLRS, cap. 11.3; Mitzenmacher y Upfal, cap. 15.
- **Teoría:** la cota `1/m` de colisión de una familia universal; la altura esperada. Las estructuras
  son de `07/03`; aquí va el análisis.
- **Cubre:** por qué elegir la función al azar protege contra el adversario.
- **Código:** una familia universal en C++ y Java.
- **Desmonta:** «un buen hash fijo basta».
- **Problemas:** propios.
- **Se toca con:** `06/03`, `07/03`.
- **Ruta corta:** no.

## `19/03` — Estructuras probabilísticas

- **Archivo:** `03-estructuras-probabilisticas.md`
- **Objetivo:** usar Bloom, Count-Min, HyperLogLog y MinHash, y saber qué error aceptan.
- **Niveles:** Bloom [B] · Count-Min [B] · HyperLogLog [C] · MinHash [C].
- **📚 Lectura troncal:** La Rocca, cap. 4; Kubica, cap. 13; Medjedovic y otros.
- **Teoría:** la tasa de falsos positivos de Bloom y su `k` óptimo; las cotas de Count-Min.
- **Cubre:** dónde aparecen: cachés, bases de datos, analítica.
- **Código:** Bloom en C++ y Java.
- **Desmonta:** «un Bloom puede dar falsos negativos».
- **Problemas:** propios.
- **Se toca con:** `19/02`, `19/06`.
- **Ruta corta:** no.

## `19/04` — Muestreo y cadenas de Markov

- **Archivo:** `04-muestreo-y-markov.md`
- **Objetivo:** muestrear de un flujo y barajar sin sesgo, y entender lo justo de cadenas de Markov
  para MCMC y MCTS.
- **Niveles:** *reservoir* [B] · Fisher-Yates [A] · cadenas de Markov [C] · MCMC y MCTS [C].
- **📚 Lectura troncal:** Knuth, Vol. 2, 3.ª ed. (1997), §3.4.2; Brassard y Bratley, cap. 10; Blum,
  Hopcroft y Kannan, cap. 4.
- **Teoría:** la prueba de uniformidad del *reservoir* y de Fisher-Yates; la distribución
  estacionaria enunciada.
- **Cubre:** el barajado sesgado que escribe todo el mundo (autopsia de un bug).
- **Código:** Fisher-Yates y *reservoir* en los tres lenguajes.
- **Desmonta:** «intercambiar con una posición al azar de todo el arreglo baraja bien».
- **Problemas:** bases.
- **Se toca con:** `10/06`, `19/01`.
- **Ruta corta:** no.

## `19/05` — Estructuras espaciales

- **Archivo:** `05-estructuras-espaciales.md`
- **Objetivo:** reconocer el árbol k-d y la búsqueda del vecino más cercano.
- **Niveles:** árbol k-d [C] · vecino más cercano [C].
- **📚 Lectura troncal:** de Berg y otros, cap. 5; La Rocca, cap. 9; Kubica, cap. 9.
- **Teoría:** consultas de rango en O(√n) en 2D; la maldición de la dimensión.
- **Cubre:** cuándo aparecen; R-tree como ficha.
- **Código:** ninguno.
- **Desmonta:** «el k-d tree escala a cualquier dimensión».
- **Problemas:** 💀 específica: Kattis.
- **Se toca con:** `18/05`.
- **Ruta corta:** no.

## `19/06` — Datos masivos

- **Archivo:** `06-datos-masivos.md`
- **Objetivo:** saber qué cambia cuando los datos no caben en memoria o llegan en flujo.
- **Niveles:** MapReduce [C] · algoritmos de flujo de datos [C] · memoria externa [C].
- **📚 Lectura troncal:** La Rocca, cap. 13; Medjedovic, Tahirovic y Dedovic.
- **Teoría:** el modelo de memoria externa y la ordenación externa; el modelo de flujo y su memoria
  sublineal.
- **Cubre:** contar palabras con MapReduce; cuándo usar las estructuras de `19/03`.
- **Código:** ninguno; si hay ejemplo, en Go con *goroutines* (§11.1 de la guía).
- **Desmonta:** «más máquinas es más rápido».
- **Problemas:** propios de diseño.
- **Se toca con:** `19/03`, `07/02`.
- **Ruta corta:** no.

## `19/07` — Simulación

**Problemas propios:** *reservoir* sobre un flujo; diseñar un Bloom para una tasa de error; Freivalds; y
uno donde el determinista simple basta.

---

# 23. 🧩 Bloque `20` — Ad hoc, constructivos e interactivos

## `20/01` — Ad hoc y simulación

- **Archivo:** `01-ad-hoc-y-simulacion.md`
- **Objetivo:** resolver los problemas que no tienen técnica: invariantes, paridad e implementación
  cuidadosa.
- **Niveles:** invariantes y paridad [A] · simulación [A].
- **📚 Lectura troncal:** Halim y otros, cap. 1 (ad hoc); Engel, *Problem-Solving Strategies* (Springer, 1998), cap. 1 (el principio de invariancia).
- **Teoría:** el invariante como prueba de imposibilidad.
- **Cubre:** simular con cuidado; cuándo la simulación cabe en las restricciones.
- **Código:** ejemplos en Java.
- **Desmonta:** «si no hay técnica, no hay método».
- **Problemas:** bases; específica: Advent of Code.
- **Se toca con:** `01/06`, `20/02`.
- **Ruta corta:** no.

## `20/02` — Constructivos

- **Archivo:** `02-constructivos.md`
- **Objetivo:** fabricar una salida que cumpla una condición, y probar que cumple.
- **Niveles:** constructivos [B].
- **📚 Lectura troncal:** Engel, *Problem-Solving Strategies*, caps. 1–2; cp-algorithms.
- **Teoría:** construir por inducción.
- **Cubre:** permutaciones con propiedades; cuándo no existe.
- **Código:** C++ y Java.
- **Desmonta:** «si hay muchas respuestas, es más fácil».
- **Problemas:** específicas: Codeforces, CSES (*Construction Problems*).
- **Se toca con:** `20/01`.
- **Ruta corta:** no.

## `20/03` — Interactivos

- **Archivo:** `03-interactivos.md`
- **Objetivo:** resolver problemas donde el juez responde a tus preguntas.
- **Niveles:** el protocolo y el *flush* [B] · binaria interactiva [B].
- **📚 Lectura troncal:** la guía de Codeforces para problemas interactivos, por título (su web responde `403` a `curl`); Laaksonen, cap. 15.
- **Teoría:** las cotas de preguntas por teoría de la información (log₂ de las respuestas posibles).
- **Cubre:** `flush` en los tres lenguajes; el veredicto *Idleness Limit Exceeded*.
- **Código:** C++ y Java.
- **Desmonta:** «la salida se vacía sola».
- **Problemas:** específicas: Codeforces, CSES (*Interactive Problems*).
- **Se toca con:** `05/04`, `01/03`.
- **Ruta corta:** no.

## `20/04` — El estilo de las pruebas de empresa

- **Archivo:** `04-el-estilo-de-las-pruebas-de-empresa.md`
- **Objetivo:** resolver bien los problemas típicos de una prueba de empresa: *parsing*, cadenas con
  reglas, fechas y salida exacta.
- **Niveles:** el formato de empresa [A].
- **📚 Lectura troncal:** McDowell, *Cracking the Coding Interview*; Aziz, Lee y Prakash.
- **Cubre:** leer el enunciado entero dos veces; formato de salida exacto; fechas y horas sin
  bibliotecas exóticas; puntuación parcial y cómo asegurarla; Coderbyte y Codility como formatos.
- **Código:** ejemplos en Java.
- **Desmonta:** «los problemas de empresa son fáciles».
- **Problemas:** bases; Coderbyte verificado con navegador.
- **Se toca con:** `01/01`, `01/06`, `21` (README).
- **Ruta corta:** sí.

## `20/05` — Heurísticos y aproximados

- **Archivo:** `05-heuristicos-y-aproximados.md`
- **Objetivo:** atacar un problema de optimización sin solución exacta con búsqueda local, recocido
  simulado y *beam search*, y saber qué garantiza una aproximación.
- **Niveles:** búsqueda local [B] · recocido simulado [B] · *beam search* [B] · aproximación con
  garantía [C].
- **📚 Lectura troncal:** Brassard y Bratley, cap. 13; Russell y Norvig, cap. 4; Kleinberg y Tardos,
  caps. 11–12.
- **Teoría:** la 2-aproximación de cobertura de vértices; por qué el recocido escapa de óptimos
  locales.
- **Cubre:** el formato del AtCoder Heuristic Contest y de CodinGame.
- **Código:** recocido simulado en C++.
- **Desmonta:** «si no es óptimo, no sirve».
- **Problemas:** específicas: AtCoder Heuristic Contest, CodinGame.
- **Se toca con:** `10/05`, `10/06`.
- **Ruta corta:** no.

## `20/06` — Simulación

**Problemas propios:** uno de invariante de paridad; uno constructivo; uno de formato de empresa con
fechas; y uno de simulación directa.

---

# 24. 🏁 Bloque `21` — Simulacros

Sin teoría y sin preguntas (§7.5 de la guía). Un documento por simulacro, más un documento de pistas y
el README con los cuatro formatos y la rúbrica en vivo.

| Archivo | Formato | Problemas |
|---|---|---|
| `01`–`05-simulacro-empresa-NN.md` | Empresa en HackerRank o LeetCode | 2–3 externos no vistos, de las bases |
| `06`–`08-simulacro-empresa-codility-NN.md` | Empresa en Codility o Coderbyte | 3 externos cortos |
| `09`–`12-simulacro-en-vivo-NN.md` | En vivo | 1 propio, con su guion para quien hace de entrevistador |
| `13`–`16-simulacro-concurso-NN.md` | Concurso | Un concurso virtual de Codeforces Div. 2, AtCoder Beginner o el semanal de LeetCode, verificado por API o `404` real |
| `17-pistas.md` | — | Las pistas 2 y 3 de todos los problemas del bloque |

- **Cada simulacro dice después qué capítulos repasar** según lo que falló.
- **Los simulacros en vivo** llevan, además del problema, el guion del entrevistador: qué preguntar,
  qué pista dar y cuándo, y la rúbrica de §7.5 de la guía.
- **Ningún problema de un simulacro aparece antes en el corpus.**

---

# 25. 🧪 Bloque `22` — Teoría de la computación (opcional)

**Opcional** (§7.6 de la guía): ningún capítulo del hilo principal depende de él. Lectura troncal:
Hopcroft, Motwani y Ullman, y Aho, Lam, Sethi y Ullman, caps. 2–3.

| Código | Archivo | Cubre | Niveles |
|---|---|---|---|
| `22/01` | `01-lenguajes-y-gramaticas.md` | Lenguajes regulares y libres de contexto; gramáticas; el lema de bombeo | regulares, cierre y equivalencia [A] · libres de contexto [A] · bombeo [B] |
| `22/02` | `02-automatas-de-pila.md` | Autómatas de pila; equivalencia con las gramáticas libres de contexto; CYK | B (las tres secciones) |
| `22/03` | `03-maquinas-de-turing-y-decidibilidad.md` | Máquinas de Turing; la tesis de Church-Turing; el problema de la parada | MT [A] · Church-Turing [B] · parada [A] · Rice [C] |
| `22/04` | `04-p-np-y-reducciones.md` | P, NP, reducciones polinomiales; 2-SAT frente a 3-SAT | P y NP [A] · reducciones [B] · 2-SAT y 3-SAT [B] |
| `22/05` | `05-np-completitud.md` | Cook-Levin enunciado; las reducciones clásicas (3-SAT, clique, cobertura de vértices, ciclo hamiltoniano, suma de subconjuntos) | Cook-Levin [B] · reducciones [B] · suma de subconjuntos [B] · qué hacer con un NP-difícil [A] |
| `22/06` | `06-analisis-lexico-y-gramaticas-simples.md` | Análisis léxico con autómatas; gramáticas simples y descenso recursivo; **sin LL(1) ni LALR(1)** | B (las tres secciones) |
| `22/07` | `07-respuestas.md` | Solucionario del bloque | — |

**Niveles por sección**, fijados al escribir el bloque en T36 (2026-10-04): un capítulo de teoría lleva un ejemplo trabajado por cada sección A, y las secciones que son teoremas sin algoritmo se bajan a B o C. **Problemas**, solo en `22/02` (CYK) y `22/06` (el analizador), que son los capítulos con algoritmo.

**Desmonta, en el bloque:** «NP significa no polinomial» · «indecidible es lo mismo que difícil» · «una
expresión regular reconoce paréntesis balanceados».

---

# 26. 📓 Bloque `23` — Cuaderno de competencia (opcional)

**Se genera de los capítulos** (§7.7 de la guía), en la última tanda.

| Archivo | Contenido |
|---|---|
| `01-cuaderno-cpp.md` | Plantillas A y B en C++ |
| `02-cuaderno-java.md` | Plantillas A y B en Java |
| `03-cuaderno-python.md` | Plantillas A y las B que tengan versión Python |
| `04-cuaderno-go.md` | Plantillas A en Go |
| `05-cuaderno-javascript.md` | Plantillas A en JavaScript |

**Las de Go y JavaScript se escriben aquí**, por decisión de Oskar: son las únicas plantillas completas en esos
lenguajes del corpus, y entran en la pasada de verificación como las demás.

---

# 27. 🗺️ El `README.md` del corpus y las rutas

**El README del corpus lleva:** la tesis de §1 de la guía; el mapa de los 23 bloques con su estado; las
rutas; el lineamiento de la IA como tutor resumido; las tres plataformas base y las específicas; las
versiones de §5.3 de la guía; cómo se estudia; la fecha de la pasada de verificación.

**Las rutas**, con el formato de §13 de la guía. **A fondo** cuenta 5 horas por capítulo; **repaso**,
2,5; **solo teoría**, 2. Recalibradas en T37 (2026-10-04) como el recuento de capítulos por el ritmo, más dos o tres horas por simulación o simulacro; el tiempo real del primer recorrido es el que las ajusta.

### Ruta Entrevistas

Repaso · ~70 h · **ruta corta.** `01/02`, `01/03`, `01/06`, `01/07` · `03/01`, `03/03` o `03/04` (el
lenguaje propio) · `04/01`, `04/02`, `04/03` · `05/04` · `06/01`, `06/02`, `06/03` · `07/01`, `07/04` ·
`08/02` · `10/02`, `10/03` · `11/02` · `12/01`, `12/02`, `12/03` · `14/02`, `14/03`, `14/04` · `20/04` ·
tres simulacros de empresa de `21`.

### Ruta Algoritmos básicos

A fondo · ~155 h. `02/01`, `02/02`, `02/04` · `04/01`, `04/02` · `05/01`, `05/02`, `05/03`, `05/04` ·
`06/01`, `06/02`, `06/03` · `07/01`, `07/02` · `08/01`, `08/04` · `10/01`, `10/02`, `10/03`, `10/05` ·
`11/01`, `11/02` · `12/01`, `12/02`, `12/03` · `14/01`, `14/02`, `14/03`, `14/04` · `15/01`, `15/04`.

### Ruta Grafos y árboles

A fondo · ~125 h. `07/01`–`07/07` · `08/01`, `08/04` · `09/02`, `09/03` · `13/03` · `14/01`–`14/06` ·
`15/01`–`15/07`.

### Ruta Programar en vivo

Repaso · ~45 h · **ruta corta.** `01/06`, `01/07` · `02/01`, `02/04` · `04/02` · `05/04` · `06/01` ·
`10/01`, `10/03` · `12/01`, `12/02` · `14/02`, `14/03` · `20/04` · en el resto de capítulos A, solo «De la
versión ingenua a la buena» · los cuatro simulacros en vivo de `21`.

### Ruta Completa

A fondo · ~710 h. Bloques `01`–`21`.

### Ruta Prueba técnica esta semana

Repaso · ~45 h · **ruta corta.** `01/02`, `01/03`, `01/06` · el `03` del lenguaje propio · `04/01`,
`04/02`, `04/03` · `05/04` · `06/01`, `06/03` · `11/02` · `12/01`, `12/02`, `12/03` · `14/02` · `20/04`
· dos simulacros de empresa de `21`.

### Ruta Refrescamiento teórico

Solo teoría y preguntas · ~50 h. Bloque `02` · `05/01`, `05/02` · `07/01`, `07/02` · `08/01`, `08/03` ·
`10/05` · `11/01`, `11/04` · `12/01` · `14/01`–`14/04` · `15/01`, `15/02`, `15/04` · `19/01`.

### Ruta Competidor

A fondo · ~640 h. Completa menos el bloque `19` y `20/04`, con los concursos virtuales de `21` y el
cuaderno de `23`.

### Ruta DP a fondo

A fondo · ~80 h. `10/01`, `10/02` · `12/01`–`12/06` · `13/01`–`13/07` · `17/05`.

### Ruta Cadenas

A fondo · ~50 h. `06/04` · `07/04` · `16/01`–`16/08`.

### Ruta Matemática para competir

A fondo · ~65 h. `17/01`–`17/11` · `13/06` · `18/01`.

### Ruta Estructuras para el arquitecto

Repaso · ~35 h. `06/02`, `06/03` · `07/02`, `07/03` · `08/01`, `08/04` · `09/02` · `19/01`–`19/06`.

### Ruta Cambio de lenguaje

Repaso · ~25 h. `01/03` · `03/01`–`03/06` · las plantillas A del lenguaje nuevo en `23`.

### Ruta Desde cero

A fondo · ~105 h. `01/01`–`01/07` · `02/01` · `04/01`–`04/05` · `05/01`, `05/04` · `06/01`, `06/02` ·
`10/01`, `10/02` · `12/01`, `12/02`. Con los jueces en español (Acepta el reto, omegaUp, Jutge) como
fuente opcional de práctica.

**La geometría (`18`) no está en ninguna ruta básica**; entra en Completa, Competidor y Matemática para
competir (`18/01`).

---

# 28. 🚫 Qué queda fuera y por qué

| Tema | Por qué |
|---|---|
| Estructuras sucintas, *van Emde Boas*, árboles de fusión | No están en los libros base como tema central ni salen en entrevistas; como mucho una mención en `09/06` |
| Algoritmos paralelos y concurrentes | Brassard y Bratley, cap. 11, queda fuera por decisión de la biblioteca; MapReduce entra como ficha en `19/06` |
| Programación lineal y símplex | CLRS, cap. 29: fuera del hilo; una mención en `15/05` como generalización del flujo |
| Criptografía (RSA y compañía) | Pertenece a otro curso; la aritmética modular que la sostiene está en `17/03` |
| Aprendizaje automático | Pertenece a otro curso; los algoritmos que lo tocan (MCMC, MCTS, k-d) entran como ficha |
| Compiladores más allá del análisis léxico | La biblioteca lo excluye (sin LL(1) ni LALR(1)) |
| Máquinas de Turing a fondo, complejidad más allá de NP | Bloque `22` opcional, con PSPACE como mención |
