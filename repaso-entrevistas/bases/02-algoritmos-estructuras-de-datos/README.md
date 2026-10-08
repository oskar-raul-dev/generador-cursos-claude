# Algoritmos y estructuras de datos — refrescamiento a fondo

> Un repaso de algoritmos y estructuras de datos para quien ya programa con soltura y quiere
> **entender por qué un algoritmo es correcto y cuánto cuesta**, reconocer el problema que lo pide y
> escribirlo sin bug en C++, Java y Python, con la programación competitiva como medio de práctica.
>
> **Estado:** escrito entero, el hilo principal (bloques `01`–`21`) y los dos opcionales (`22` y `23`). Falta
> la **pasada de verificación**, que corre todo el código y comprueba todos los enlaces al final, de una vez
> ([abajo](#-la-pasada-de-verificación)): hasta entonces, toda salida que muestra un capítulo lleva la marca «salida esperada, sin
> correr».
>
> **Vigencia:** 2026-10-05.

**Salto rápido:** [Tesis](#-la-tesis) · [Mapa](#️-el-mapa) · [Capítulo](#-cómo-está-hecho-un-capítulo) · [Rutas](#️-las-rutas) · [Problemas](#-los-problemas-y-las-plataformas) · [IA](#-la-ia-como-tutor-no-como-solucionario) · [Versiones](#-lenguajes-y-versiones) · [Verificación](#-la-pasada-de-verificación) · [Libros](#-los-libros) · [Cómo se estudia](#-cómo-se-estudia)

---

## 🧭 La tesis

Un algoritmo está aprendido cuando puedes decir su invariante, argumentar por qué es correcto,
derivar su coste y nombrar el teorema o la cota que lo limita; **y solo entonces** escribirlo de
memoria. La competitiva aporta encima el reconocimiento, la plantilla y la estimación por
restricciones, pero va después de la teoría, nunca en su lugar.

```text
Un libro de algoritmos  → te enseña la técnica, su prueba y su cota.
Un juez en línea        → te dice si tu código pasa, pero no por qué.
Este repaso             → la teoría del libro —definición, teorema, corrección, coste—,
                          contrastada contra un juez y contada para la entrevista.
```

**Qué es:** veintiún bloques del hilo principal y dos opcionales. Cada capítulo de técnica abre con
el problema, enuncia la teoría con su prueba esbozada, da la plantilla en C++ · Java · Python, muestra
el camino de la versión ingenua a la buena y cierra con preguntas, problemas propios y práctica
externa en HackerRank, LeetCode y Codility.

**Qué no es:** ni un curso de demostraciones formales completas (se esbozan y se cita dónde están
enteras), ni un manual de trucos de concurso, ni un solucionario. **Ningún problema lleva solución
publicada**: cada uno trae tres pistas escalonadas, y las preguntas de cada capítulo tienen sus
respuestas en el solucionario del bloque.

---

## 🗺️ El mapa

| Bloque | Tema | Contenido | Estado |
|---|---|---|---|
| `01` | [Oficio del competidor](01-oficio-del-competidor/README.md) | 7 capítulos + simulación | escrito |
| `02` | [Análisis](02-analisis/README.md) | 6 + simulación | escrito |
| `03` | [Biblioteca estándar](03-biblioteca-estandar/README.md) | 6 + simulación | escrito |
| `04` | [Secuencias](04-secuencias/README.md) | 5 + simulación | escrito |
| `05` | [Orden y búsqueda](05-orden-y-busqueda/README.md) | 5 + simulación | escrito |
| `06` | [Lineales y hashing](06-lineales-y-hashing/README.md) | 4 + simulación | escrito |
| `07` | [Árboles](07-arboles/README.md) | 7 + simulación | escrito |
| `08` | [Heaps y Union-Find](08-heaps-y-union-find/README.md) | 4 + simulación | escrito |
| `09` | [Consultas sobre rangos](09-consultas-sobre-rangos/README.md) | 6 + simulación | escrito |
| `10` | [Búsqueda completa y divide y vencerás](10-busqueda-completa-y-divide-y-venceras/README.md) | 6 + simulación | escrito |
| `11` | [Voraces](11-voraces/README.md) | 4 + simulación | escrito |
| `12` | [DP clásica](12-dp-clasica/README.md) | 6 + simulación | escrito |
| `13` | [DP avanzada](13-dp-avanzada/README.md) | 7 + simulación | escrito |
| `14` | [Grafos: recorridos](14-grafos-recorridos/README.md) | 6 + simulación | escrito |
| `15` | [Grafos con pesos y flujos](15-grafos-pesos-y-flujos/README.md) | 7 + simulación | escrito |
| `16` | [Cadenas](16-cadenas/README.md) | 8 + simulación | escrito |
| `17` | [Matemática](17-matematica/README.md) | 11 + simulación | escrito |
| `18` | [Geometría](18-geometria/README.md) | 6 + simulación | escrito |
| `19` | [Aleatorizados y probabilísticos](19-aleatorizados-y-probabilisticos/README.md) | 6 + simulación | escrito |
| `20` | [Ad hoc, constructivos e interactivos](20-ad-hoc-constructivos-e-interactivos/README.md) | 5 + simulación | escrito |
| `21` | [Simulacros](21-simulacros/README.md) | 16 simulacros y sus pistas | escrito |
| `22` | [Teoría de la computación](22-teoria-de-la-computacion/README.md) (opcional) | 6 capítulos | escrito |
| `23` | [Cuaderno de competencia](23-cuaderno-de-competencia/README.md) (opcional) | 5 cuadernos | generado |

**El código `NN/MM`** nombra un capítulo por bloque y número: `12/03` es el tercer capítulo del
bloque `12`. Cada bloque técnico cierra con una simulación y un solucionario, y cada README de bloque trae su
índice, su orden de lectura, su mapa de señales («si el enunciado dice esto, piensa en aquello») y lo que no
está en él.

**En números:** 122 capítulos del hilo principal, 20 simulaciones, 20 solucionarios, 16 simulacros con su
documento de pistas y un README por bloque; en los opcionales, 6 capítulos con su solucionario y 5 cuadernos.

---

## 📖 Cómo está hecho un capítulo

```text
1. 🎯 El problema               el dolor, con números, antes de nombrar la técnica
2. 📐 La teoría                 definiciones y teoremas enunciados, con la prueba esbozada
3. 🧱 Una sección por técnica   con su nivel: A de memoria, B con la plantilla delante, C ficha
      Qué es · Por qué es correcto · Cómo va (traza) · Cuánto · La plantilla (C++ · Java · Python)
      De la versión ingenua a la buena (el ejemplo trabajado, solo en A) · Cuándo sí / no · Veredicto
4. ⏱️ La tabla de costes · 🧭 Cómo se elige · 🔎 Señales del enunciado · 🔭 Dónde aparece de verdad
5. ⚠️ Errores frecuentes        «se dice» frente a «lo preciso»
6. 📚 Para profundizar          el libro y el capítulo primero; documentación oficial después
7. 🧠 Preguntas                 10 a 15, graduadas 🟢 🟡 🟠 🔴; respuestas en el solucionario del bloque
8. 🧩 Problemas                 2 a 4 propios y la práctica externa, sin solución, con tres pistas
9. ✅ Criterio de dominio       lo que tienes que poder hacer para pasar al siguiente
```

Los datos de los ejemplos son siempre los mismos —el arreglo `[5, 2, 9, 1, 5, 6]`, la cadena
`abracadabra`, el grafo G, el árbol T, la red R, los puntos P—, para que una traza se lea contra algo ya visto.

---

## 🛤️ Las rutas

El corpus es grande a propósito, y nadie tiene que leerlo entero. **A fondo** cuenta 5 horas por
capítulo; **repaso**, 2,5; **solo teoría**, 2; las simulaciones y los simulacros, entre dos y tres horas cada
uno. Son el recuento de capítulos por el ritmo: el tiempo real del primer recorrido es el que las ajusta. Las tres
rutas cortas —Entrevistas, Prueba técnica esta semana y Programar en vivo— usan capítulos escritos para leerse
solos.

### Ruta Entrevistas

Repaso · ~70 h · **ruta corta.** `01/02`, `01/03`, `01/06`, `01/07` · `03/01`, `03/03` o `03/04` (el
lenguaje propio) · `04/01`, `04/02`, `04/03` · `05/04` · `06/01`, `06/02`, `06/03` · `07/01`, `07/04` ·
`08/02` · `10/02`, `10/03` · `11/02` · `12/01`, `12/02`, `12/03` · `14/02`, `14/03`, `14/04` · `20/04` ·
tres simulacros de empresa del bloque `21`.

### Ruta Algoritmos básicos

A fondo · ~155 h. `02/01`, `02/02`, `02/04` · `04/01`, `04/02` · `05/01`, `05/02`, `05/03`, `05/04` ·
`06/01`, `06/02`, `06/03` · `07/01`, `07/02` · `08/01`, `08/04` · `10/01`, `10/02`, `10/03`, `10/05` ·
`11/01`, `11/02` · `12/01`, `12/02`, `12/03` · `14/01`, `14/02`, `14/03`, `14/04` · `15/01`, `15/04`.

### Ruta Grafos y árboles

A fondo · ~125 h. `07/01`–`07/07` · `08/01`, `08/04` · `09/02`, `09/03` · `13/03` · `14/01`–`14/06` ·
`15/01`–`15/07`.

### Ruta Programar en vivo

Repaso · ~45 h · **ruta corta.** `01/06`, `01/07` · `02/01`, `02/04` · `04/02` · `05/04` · `06/01` ·
`10/01`, `10/03` · `12/01`, `12/02` · `14/02`, `14/03` · `20/04` · en el resto de capítulos de nivel A,
solo la sección «De la versión ingenua a la buena» · los cuatro simulacros en vivo del bloque `21`.

### Ruta Completa

A fondo · ~710 h. Bloques `01` a `21`.

### Ruta Prueba técnica esta semana

Repaso · ~45 h · **ruta corta.** `01/02`, `01/03`, `01/06` · `03/01`, `03/03` o `03/04` (el lenguaje
propio) · `04/01`, `04/02`, `04/03` · `05/04` · `06/01`, `06/03` · `11/02` · `12/01`, `12/02`, `12/03` ·
`14/02` · `20/04` · dos simulacros de empresa del bloque `21`.

### Ruta Refrescamiento teórico

Solo teoría y preguntas · ~50 h. `02/01`–`02/06` · `05/01`, `05/02` · `07/01`, `07/02` · `08/01`,
`08/03` · `10/05` · `11/01`, `11/04` · `12/01` · `14/01`–`14/04` · `15/01`, `15/02`, `15/04` · `19/01`.
Con el bloque opcional `22` como continuación natural.

### Ruta Competidor

A fondo · ~640 h. La ruta Completa menos el bloque `19` y el capítulo «El estilo de las pruebas de
empresa» del bloque `20`, con los concursos virtuales del bloque `21` y el cuaderno del bloque `23`.

### Ruta DP a fondo

A fondo · ~80 h. `10/01`, `10/02` · `12/01`–`12/06` · `13/01`–`13/07` · `17/05`.

### Ruta Cadenas

A fondo · ~50 h. `06/04` · `07/04` · `16/01`–`16/08`.

### Ruta Matemática para competir

A fondo · ~65 h. `17/01`–`17/11` · `13/06` · `18/01`.

### Ruta Estructuras para el arquitecto

Repaso · ~35 h. `06/02`, `06/03` · `07/02`, `07/03` · `08/01`, `08/04` · `09/02` · `19/01`–`19/06`.

### Ruta Cambio de lenguaje

Repaso · ~25 h. `01/03` · `03/01`–`03/06` · las plantillas A del lenguaje nuevo en el bloque `23`.

### Ruta Desde cero

A fondo · ~105 h. `01/01`–`01/07` · `02/01` · `04/01`–`04/05` · `05/01`, `05/04` · `06/01`, `06/02` ·
`10/01`, `10/02` · `12/01`, `12/02`. Con los jueces en español (Acepta el reto, omegaUp, Jutge) como
fuente opcional de práctica.

**La geometría (bloque `18`) no está en ninguna ruta básica**; entra en Completa, Competidor y
Matemática para competir. **Los bloques `22` y `23` son opcionales**: ninguna ruta los exige, salvo el cuaderno
en Competidor y en Cambio de lenguaje.

---

## 🧩 Los problemas y las plataformas

**Dos tipos, y ninguno con solución publicada.** Los **propios** (de dos a cuatro por capítulo) traen el
enunciado completo, las restricciones y los casos de ejemplo; los **externos** se enlazan sin copiar el
enunciado. Todos llevan tres pistas: la 1 junto al problema, sin nombrar la técnica; la 2 (qué técnica y por
qué) y la 3 (el estado, la recurrencia o el invariante, sin código) en el solucionario del bloque. No hay pista 4:
la solución la escribe quien estudia. Lo único resuelto en el corpus son los ejemplos trabajados «De la versión
ingenua a la buena», y ninguno resuelve un problema de las listas.

**Las tres plataformas base**, en todos los bloques: **HackerRank**, **LeetCode** (solo problemas gratuitos) y
**Codility** (hasta donde llegan sus lecciones). **Las específicas**, donde las bases no llegan: CSES,
Codeforces, AtCoder, Kattis, Library Checker, CodinGame, Project Euler y, para la ruta «Desde cero», jueces en
español. Cada enlace se comprobó al escribirlo con el método de su plataforma (una API, un `404` real o el
repositorio del juez); SPOJ, que solo responde a un navegador, no se enlaza.

**La práctica externa** de cada capítulo tiene un **núcleo** (obligatorio, de las bases), una **ampliación** y, a
veces, un problema 💀 por curiosidad, fuera del conteo. Una línea 🔥 «Para el geek» sugiere resolverlo en Go o
en JavaScript cuando el razonamiento cambia en ese lenguaje, no solo la sintaxis.

---

## 🤖 La IA como tutor, no como solucionario

1. No le pidas que resuelva el problema.
2. Empieza tú, con una solución ingenua en tus palabras y su coste.
3. Intenta el código, aunque sea incompleto o lento.
4. Pide *feedback*, no código: «¿mi invariante es correcto?», «¿qué caso borde falla?».
5. Si sigues atascado, pide **la pista siguiente**, no la solución.
6. Cierra sin ella: explica en voz alta el invariante y el coste de tu versión final.

El lineamiento entero vive en [`01/06` — El protocolo de resolución, la repetición y el concurso](01-oficio-del-competidor/06-protocolo-de-resolucion.md).

---

## 💻 Lenguajes y versiones

**C++20 · Java 21 · Python 3.12**, la intersección de lo que ofrecen las tres plataformas base, comprobada el
2026-10-03. Lo posterior (C++23, Java 22–25, Python 3.13 y 3.14) solo aparece en un recuadro 📝 donde cambia la
respuesta.

| Plataforma | C++ | Java | Python |
|---|---|---|---|
| HackerRank | G++ 14.2 con la opción «C++23». **Su opción «C++20» es G++ 8.3**, que casi no implementa C++20 | OpenJDK 21.0.4 | 3.14.2 |
| LeetCode | Clang 19, C++23, libstdc++ 14 | OpenJDK 25 | 3.14 |
| Codility | G++ 10.3 (C++20) o G++ 13.3 (C++23) | 21 | 3.12 |

**Go y JavaScript** entran como casos de estudio ([`03/06`](03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)),
en las líneas 🔥 y con sus plantillas A completas en el cuaderno opcional del bloque `23`, en las versiones de
HackerRank: Go 1.26 y Node 20.

---

## 🧪 La pasada de verificación

**Hecha el 2026-10-04**, sobre el corpus entero, con estas herramientas en un Mac con Apple Silicon (macOS 26.7):

| Lenguaje | Herramienta | Cómo |
|---|---|---|
| C++ | GCC 16.2.0 (`g++-16`) | `-std=c++20 -O2 -Wall -Wextra`, y `-fsanitize=undefined` en las pruebas |
| Java | OpenJDK 21.0.12 (Zulu) | `javac` y `java` |
| Python | CPython 3.13.4 | además, la gramática de 3.12 en todos los bloques |
| Go | Go 1.27.1 | `go vet` y las pruebas de cada plantilla |
| JavaScript | Node 24.21.0 | las pruebas de cada plantilla |

**Qué se corrió:**

- **Todas las plantillas de nivel A y B** (239 secciones, en cada lenguaje en que existen): compiladas y corridas
  contra un *stress test*, con una fuerza bruta o un verificador como oráculo y un generador aleatorio; unos
  200 000 casos en total. Las aleatorizadas, además, con pruebas de uniformidad; las interactivas, contra un
  juez por tuberías.
- **Todos los ejemplos trabajados y las trazas**: las dos versiones de cada «De la versión ingenua a la buena»
  contra la misma referencia, y unas 330 trazas y cifras del texto recalculadas, incluidas las medidas (la
  precisión de la FFT, el recocido simulado, la caché).
- **Todos los problemas propios** de los bloques `01`–`20` y `22` y de los simulacros en vivo: sus casos de
  ejemplo, contra una solución de referencia que no se publica; los de construcción e interactivos, con un
  verificador.
- **Todos los enlaces** (1 509), con el método de su plataforma.

**Qué cambió.** Las marcas «salida esperada, sin correr» han desaparecido: todas esas salidas eran correctas.
Ninguna plantilla daba un resultado equivocado dentro de su precondición, pero la pasada corrigió:

- tres versiones ingenuas que fallaban, una de ellas con una excepción en casi cualquier entrada;
- una precondición que faltaba (`k ≥ 1` en los `k` mayores) y un comentario que contradecía al texto;
- dependencias e `import` sin declarar en diez plantillas Java, dos `#include` que faltaban y los alias de tipo
  que la guía no admite en seis plantillas C++;
- dos trazas con un valor equivocado y dos cifras medidas que no se sostenían (la precisión de la FFT);
- los nombres de los problemas de AtCoder y dos enlaces de documentación que habían cambiado de ruta.

Los cuadernos del bloque `23` se regeneraron con todo ello.

**En el cierre (2026-10-05)** se añadió un segundo caso de ejemplo, de borde, a los 132 problemas propios que
traían uno solo, con su salida calculada por la misma solución de referencia; se corrigieron 19 enunciados del
solucionario que no eran copia literal del capítulo, y 111 enlaces a encabezados con `⏱️` o con superíndices
que GitHub no resolvía.

**Lo que no se pudo ejecutar, y por qué:**

- **Las versiones exactas de los jueces.** Se corrió con las herramientas de la tabla, no con G++ 14, Clang 19,
  OpenJDK 21.0.4, Python 3.12, Go 1.26 ni Node 20; el código solo usa lo que esas versiones tienen, y en Python
  se comprobó la gramática de 3.12.
- **El `ordered_set` de PBDS en el Clang de LeetCode** (`03/02`): compila y funciona con GCC 16, pero confirmarlo
  allí exige un envío a la plataforma.
- **Los problemas externos de los simulacros** (bloque `21`): sus enlaces y nombres están comprobados, pero no se
  resolvieron uno a uno para confirmar las pistas 2 y 3.
- **Los tiempos dependen de la máquina**: las cifras de tiempo del texto son relativas («varias veces») o se dan
  como orientación.

---

## 📚 Los libros

La teoría de cada capítulo sale de un libro concreto, citado con su capítulo en el encabezado («lectura
troncal») y como primera entrada de «Para profundizar». El texto base es **Brassard y Bratley, *Fundamentos de
algoritmia*** (Prentice Hall, 1997), con **Cormen, Leiserson, Rivest y Stein**, *Introduction to Algorithms*,
3.ª ed., para las pruebas; **Kleinberg y Tardos**, *Algorithm Design*, para voraces, flujos y NP; **Sedgewick y
Wayne**, *Algorithms*, 4.ª ed., para grafos y cadenas en Java; y **Laaksonen**, *Guide to Competitive
Programming*, 3.ª ed., y **Halim, Halim y Effendy**, *Competitive Programming 4*, para el medio. Los temas
especiales tienen su libro (Warren para los bits, Gusfield para las cadenas, de Berg y otros para la geometría,
Mitzenmacher y Upfal para lo aleatorizado, Hopcroft, Motwani y Ullman para los autómatas), y los pocos sin
tratamiento en ningún libro del canon lo declaran en su encabezado.

---

## 🧭 Cómo se estudia

1. **Elige una ruta** (o el bloque que necesitas) y lee su README de bloque: el orden y el mapa de señales.
2. **Lee el capítulo con papel**: traza a mano los ejemplos antes de mirar la traza del texto.
3. **Escribe la plantilla** del nivel A sin mirar, en tu lenguaje, y compárala.
4. **Responde las preguntas** en voz alta, con la capa de 30 segundos primero; solo después, el solucionario.
5. **Resuelve los problemas**: los propios y el núcleo de la práctica externa, con la pista 1 como mucho al
   principio. La IA, como tutor (arriba).
6. **Comprueba el criterio de dominio** del capítulo antes de pasar al siguiente.
7. **Cierra el bloque con su simulación**, cronometrada; lo que falle dice qué capítulo repetir.
8. **Al final de la ruta, los simulacros** del bloque `21` en el formato de tu prueba real.
