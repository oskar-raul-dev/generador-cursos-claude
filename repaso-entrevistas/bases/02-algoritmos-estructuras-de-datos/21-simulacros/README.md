# Bloque 21 — Simulacros

> Dieciséis simulacros en los cuatro formatos en los que se evalúa a alguien que programa: la prueba de
> empresa en HackerRank o LeetCode, la prueba con reglas de Codility, la entrevista en vivo y el concurso. Sin
> teoría y sin preguntas: problemas que no aparecen en ningún otro sitio del corpus, con cronómetro, un
> registro de lo que falló y, al final de cada uno, qué capítulos repasar. Las pistas 2 y 3 de todos están en
> [`17-pistas.md`](17-pistas.md).
>
> **Vigencia:** 2026-10-04.

---

## 🧭 Los cuatro formatos

| Formato | Simulacros | Cómo | Qué se mide |
|---|---|---|---|
| Empresa en HackerRank o LeetCode | [`01`](01-simulacro-empresa-01.md)–[`05`](05-simulacro-empresa-05.md) | Tres problemas, 90 minutos, puntuación parcial por casos | Repartir el tiempo, asegurar puntos, el formato exacto |
| Empresa con reglas de Codility | [`06`](06-simulacro-empresa-codility-01.md)–[`08`](08-simulacro-empresa-codility-03.md) | Tres problemas cortos, 60 minutos; corrección y rendimiento por separado; sin ver los casos | Los casos borde propios y el rendimiento con los rangos máximos |
| En vivo | [`09`](09-simulacro-en-vivo-01.md)–[`12`](12-simulacro-en-vivo-04.md) | Un problema, 45 minutos, con otra persona o grabándose | La rúbrica: preguntar, versión ingenua, coste, mejora, código, prueba |
| Concurso | [`13`](13-simulacro-concurso-01.md)–[`16`](16-simulacro-concurso-04.md) | Participación virtual en un AtCoder Beginner Contest, 100 minutos, y *upsolving* | Ritmo, penalizaciones y lo que se aprende después |

**Codility y Coderbyte.** Las lecciones de Codility que no se usan en otros capítulos del corpus son tres
(Brackets, MaxNonoverlappingSegments y Flags): cada simulacro `06`–`08` lleva una, y los otros dos problemas son
de LeetCode y HackerRank, hechos con las reglas de Codility. Coderbyte no se enlaza: responde `403` a `curl` y
sus problemas solo se pueden verificar con navegador.

**Los concursos.** Se usan cuatro AtCoder Beginner Contest, cuyos enunciados se pueden leer y comprobar sin
navegador. Un concurso virtual de Codeforces Div. 2 o el semanal de LeetCode sirven igual: lo que cambia es la
duración (dos horas) y la penalización.

---

## 🧭 La rúbrica en vivo

Seis puntos, de 0 a 2 cada uno; **no se califica el verde del juez**. Es la de
[`01/07` — Programar en vivo](../01-oficio-del-competidor/07-programar-en-vivo.md), que la explica entera.

| Punto | Qué se mira |
|---|---|
| Entender y preguntar antes de teclear | Los bordes y el formato, confirmados con un ejemplo |
| Versión ingenua correcta | Una solución que funciona, escrita pronto |
| Su coste dicho en voz alta | Tiempo y memoria, comparados con las restricciones |
| La mejora nombrada con precisión | La técnica por su nombre y su coste, sin pistas |
| Código legible | Nombres claros y funciones cortas |
| Prueba a mano con un caso borde | Un caso que no es el del enunciado, trazado en voz alta |

Con 9 puntos o más de 12, el formato está dominado; con menos de 6, se repite `01/07` antes del siguiente.

---

## 🧭 Cómo se usa

- **Cuándo.** Los de empresa, cuando ya se han hecho los bloques de la ruta elegida (las rutas cortas los
  piden: dos simulacros de empresa en «Prueba técnica esta semana», los cuatro en vivo en «Repaso»). Los
  concursos, en la ruta Competidor, uno cada una o dos semanas.
- **Con cronómetro y sin ayuda.** La pista 1 de cada problema está en el simulacro y cuesta puntos; las pistas
  2 y 3, al terminar.
- **Con registro.** Cada simulacro trae una plantilla de registro; lo que falló decide qué capítulos repasar,
  según la tabla del final de cada uno.
- **En vivo, con otra persona.** Quien entrevista lee el guion; quien es entrevistado no. Grabándose también
  sirve: se ve la grabación con la rúbrica delante.

---

## 🧭 Índice

| Simulacro | Formato | Problemas |
|---|---|---|
| [`01` — Simulacro de empresa 1](01-simulacro-empresa-01.md) | Empresa | Jumping on the Clouds · Repeated String · Non-overlapping Intervals |
| [`02` — Simulacro de empresa 2](02-simulacro-empresa-02.md) | Empresa | New Year Chaos · Simplify Path · Fraudulent Activity Notifications |
| [`03` — Simulacro de empresa 3](03-simulacro-empresa-03.md) | Empresa | Hand of Straights · Minimum Swaps 2 · LRU Cache |
| [`04` — Simulacro de empresa 4](04-simulacro-empresa-04.md) | Empresa | Climbing the Leaderboard · Basic Calculator II · Special String Again |
| [`05` — Simulacro de empresa 5](05-simulacro-empresa-05.md) | Empresa | Palindromic Substrings · Max Array Sum · Split Array Largest Sum |
| [`06` — Simulacro de empresa en Codility 1](06-simulacro-empresa-codility-01.md) | Codility | Brackets · Two Strings · Valid Parenthesis String |
| [`07` — Simulacro de empresa en Codility 2](07-simulacro-empresa-codility-02.md) | Codility | MaxNonoverlappingSegments · Hash Tables: Ransom Note · Multiply Strings |
| [`08` — Simulacro de empresa en Codility 3](08-simulacro-empresa-codility-03.md) | Codility | Flags · Minimum Absolute Difference in an Array · Search in Rotated Sorted Array II |
| [`09` — Simulacro en vivo 1](09-simulacro-en-vivo-01.md) | En vivo | Ventas por hora |
| [`10` — Simulacro en vivo 2](10-simulacro-en-vivo-02.md) | En vivo | El hueco para la reunión |
| [`11` — Simulacro en vivo 3](11-simulacro-en-vivo-03.md) | En vivo | Orden de compilación |
| [`12` — Simulacro en vivo 4](12-simulacro-en-vivo-04.md) | En vivo | El tope de las ayudas |
| [`13` — Simulacro de concurso 1](13-simulacro-concurso-01.md) | Concurso | AtCoder Beginner Contest 300 |
| [`14` — Simulacro de concurso 2](14-simulacro-concurso-02.md) | Concurso | AtCoder Beginner Contest 320 |
| [`15` — Simulacro de concurso 3](15-simulacro-concurso-03.md) | Concurso | AtCoder Beginner Contest 340 |
| [`16` — Simulacro de concurso 4](16-simulacro-concurso-04.md) | Concurso | AtCoder Beginner Contest 360 |
| [`17` — Pistas](17-pistas.md) | — | Las pistas 2 y 3 de todos los problemas |

---

## 🧭 Qué NO está aquí

- **La teoría de cada técnica**: en los bloques `04`–`20`; cada simulacro dice cuáles repasar.
- **Cómo se trabaja un problema** (la ficha, la fuerza bruta primero, las pistas, la IA como tutor): en
  [`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md).
- **Los veredictos y las plataformas**: en [`01/01`](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md).
- **El estilo de las pruebas de empresa** (fechas, formato, puntuación parcial): en
  [`20/04`](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md).
- **Las simulaciones de cada bloque**, que examinan un bloque concreto: al final de cada bloque.

---

**Anterior:** [Bloque 20 — Ad hoc, constructivos e interactivos](../20-ad-hoc-constructivos-e-interactivos/README.md) ·
**Siguiente:** [Bloque 22 — Teoría de la computación](../22-teoria-de-la-computacion/README.md) ·
**Inicio:** [README del corpus](../README.md)
