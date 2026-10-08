# Bloque 23 — Cuaderno de competencia

> **Opcional.** Las plantillas del corpus, sin explicación, un documento por lenguaje: lo que se lleva impreso o
> abierto en otra pestaña a un concurso, o lo que se repasa la víspera de una prueba. Las de C++, Java y Python
> se generan de los capítulos; las de Go y JavaScript se escribieron aquí, porque son las únicas versiones
> completas en esos dos lenguajes. Cada plantilla enlaza la sección del capítulo de donde sale, que es donde
> están su invariante, su coste y la razón de cada línea.
>
> **Vigencia:** 2026-10-04.

---

## 🧭 Índice

| Cuaderno | Qué trae | Plantillas |
|---|---|---|
| [`01` — C++](01-cuaderno-cpp.md) | Niveles A y B | 116 A y 117 B |
| [`02` — Java](02-cuaderno-java.md) | Niveles A y B | 119 A y 108 B |
| [`03` — Python](03-cuaderno-python.md) | Nivel A, y las B que tienen versión en Python | 117 A y 8 B |
| [`04` — Go](04-cuaderno-go.md) | Nivel A, todas | 123 A |
| [`05` — JavaScript](05-cuaderno-javascript.md) | Nivel A, todas | 123 A |

Una «plantilla» es una sección de técnica de un capítulo (§6.2 de la guía): una sección puede traer varias
funciones. Las de nivel C no llevan plantilla y no están aquí.

**Lo que falta en cada lenguaje, y por qué.** Los capítulos de análisis (`02/03`, `02/04`, `02/06`) y `20/01`
escriben sus plantillas solo en Java, que es el lenguaje de la entrevista; en `14/02` y `14/03`, algunas
plantillas en Java o en C++ se describen como «la de la sección anterior con cambios» para no pasar de la longitud
del capítulo, y esas no se duplican aquí. Las A que no tienen versión en un lenguaje son:

```text
C++          02/03 §3 · 02/04 §3 y §5 · 02/06 §3 · 14/03 §6 · 20/01 §3 y §4
Java         14/02 §5 y §6 · 14/03 §5 y §6
Python       02/03 §3 · 02/04 §3 y §5 · 02/06 §3 · 20/01 §3 y §4
Go y JS      ninguna: las 123 están
```

---

## 🧭 Cómo se usa

- **Para concursar**, el cuaderno del lenguaje en el que compites, con la plantilla de entrada y salida de `01/03`
  como base: las demás son funciones que se pegan dentro.
- **Para una prueba de empresa**, las plantillas de la ruta corta: prefijos, ventana, binaria, pila monótona,
  BFS, Dijkstra, Union-Find, las DP de `12/01`–`12/03`. Escríbelas una vez de memoria antes de mirarlas.
- **Para cambiar de lenguaje** (la ruta «Cambio de lenguaje»), el cuaderno del lenguaje nuevo junto al del viejo:
  la misma técnica en los dos, línea a línea.
- **No para aprender una técnica**: sin el capítulo, una plantilla es código que se copia sin saber cuándo falla.

---

## 🧪 Cómo se generó y qué está comprobado

- **C++, Java y Python** se extraen de los capítulos con un guion que recorre cada sección de técnica y copia los
  bloques de código de su «La plantilla». El nivel sale de la propia sección: A si trae el ejemplo trabajado «De
  la versión ingenua a la buena», B si no. **No se editan a mano**: si una plantilla cambia en su capítulo, el
  cuaderno se regenera en la misma edición, como manda §7.7 de la guía. Su estado de verificación es el de los
  capítulos de origen.
- **Go y JavaScript** se escribieron en esta tanda, cada plantilla en un archivo con su prueba. Todas se
  compilaron (`go vet` con Go 1.27.1; `node` 24.21) y se probaron en el momento con entradas aleatorias contra
  fuerza bruta o una referencia simple, y con los ejemplos del corpus (Dijkstra en G, el castor de cuatro estados,
  `3¹³ mod 1000 = 323`); las de aritmética modular, además, contra `math/big` y `BigInt`.
  Usan solo lo que existe en Go 1.26 y Node 20, las versiones de HackerRank. Los arneses de prueba no se
  publican. **La pasada de verificación** del 2026-10-04 las volvió a correr, con el resto del código del
  corpus (ver el [README del corpus](../README.md#-la-pasada-de-verificación)).

---

## 🧭 Qué NO está aquí

- **La explicación de cada plantilla**: en su capítulo, enlazado en cada entrada.
- **Las plantillas de nivel C**: las fichas no llevan código; se reconocen y se buscan.
- **Los problemas y las pistas**: en cada capítulo y en el solucionario de su bloque.
- **Go y JavaScript como lenguajes**: qué les falta y cómo suplirlo, en
  [`03/06` — Competir sin arsenal: Go y JavaScript](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md).

---

**Anterior:** [Bloque 22 — Teoría de la computación](../22-teoria-de-la-computacion/README.md) ·
**Inicio:** [README del corpus](../README.md)
