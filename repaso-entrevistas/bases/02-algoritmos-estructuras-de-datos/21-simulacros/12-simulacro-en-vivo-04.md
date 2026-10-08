# 12 — Simulacro en vivo 4: El tope de las ayudas

> Formato en vivo: un problema, 45 minutos, con otra persona que hace de entrevistadora (o grabándose y
> haciendo de las dos cosas). Se califica con la rúbrica de seis puntos de
> [`01/07`](../01-oficio-del-competidor/07-programar-en-vivo.md), **no** con el verde de un juez. Quien hace de
> candidato lee solo hasta «El problema»; quien entrevista lee también el guion. Las pistas 2 y 3 están en
> [`17-pistas.md`](17-pistas.md#12--simulacro-en-vivo-4-el-tope-de-las-ayudas).
>
> **Vigencia:** 2026-10-04.

---

## 🧭 Reglas

- **45 minutos**: unos 5 para entender y preguntar, 10 para la versión ingenua y su coste, 20 para la buena y
  10 para probarla a mano.
- **En voz alta todo el tiempo**: qué entiendes, qué propones, cuánto cuesta, qué caso pruebas.
- **En un editor sin autocompletar** (o en papel), en el lenguaje de la entrevista.
- **Sin ayuda**; las pistas las da quien entrevista, según el guion.

---

## 🧩 El problema

### El tope de las ayudas

**Nivel:** 🟠 · **Tiempo:** 45 minutos · **Formato:** programa completo, en vivo.

Una fundación reparte un presupuesto `B` entre `n` proyectos que piden `r₁, …, rₙ`. Fija un tope `C`: cada
proyecto recibe `min(rᵢ, C)`. Imprime el mayor tope entero `C` con el que el total no pasa de `B`. Si el
presupuesto alcanza para todo lo pedido, imprime la mayor petición.

- **Entrada.** Una línea con `n` y `B`. Una línea con los `n` valores `rᵢ`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ rᵢ ≤ 10⁹`; `0 ≤ B ≤ 10¹⁸`.

```text
Entrada         Salida
4 100           35
20 50 10 40
```

```text
Entrada         Salida
4 200           50
20 50 10 40
```

---

## 🧭 Guion del entrevistador

**Antes de empezar.** Lee el enunciado en voz alta y no añadas nada. Si el candidato no pregunta nada en los
primeros cinco minutos, anótalo en el primer punto de la rúbrica. Preguntas que **debería** hacer (responde a
las que haga; no las sugieras):

- «¿Puede el tope ser 0?»
- «¿Las peticiones caben en 32 bits y el total?»
- «¿Hay que repartir el sobrante?»

**Las pistas, solo si se atasca**:

- **Hacia el minuto 12**, si no hay una versión que funcione: «¿Qué le pasa al total cuando subes el tope, y
  qué te dice eso de cómo buscarlo?»
- **Hacia el minuto 25**, si no hay idea de mejora: «Piensa en esto: búsqueda binaria sobre el tope: el total
  es creciente en `C`.»
- **Hacia el minuto 35**, si la idea está pero no el código: «Rango `[0, max(r)]`; el total con el tope es `Σ
  min(rᵢ, C)` en 64 bits; o, ordenando y con prefijos, el tope exacto en `O(n log n)` sin binaria.»

Cada pista que des se anota y baja un punto en «la mejora nombrada con precisión».

**Si termina antes de tiempo**, una ampliación para hablar, sin código:

- ¿Y si el tope puede ser un número con decimales?
- ¿Y si llegan peticiones nuevas y hay que recalcular rápido?

---

## ✅ Después del simulacro

### La rúbrica

Cada punto, de 0 a 2. **No se califica el verde del juez.**

| Punto | 0 | 1 | 2 |
|---|---|---|---|
| Entender y preguntar antes de teclear | Empieza a escribir sin preguntar | Pregunta algo, tarde | Pregunta los bordes y confirma con un ejemplo |
| Versión ingenua correcta | No llega | Llega con errores | Correcta y rápida de escribir |
| Su coste dicho en voz alta | No lo dice | Lo dice mal o a medias | Tiempo y memoria, con la cota del enunciado |
| La mejora nombrada con precisión | No la encuentra | Con pistas | Sin pistas, con su nombre y su coste |
| Código legible | Ilegible | Funciona, con nombres pobres | Nombres claros, funciones cortas |
| Prueba a mano con un caso borde | No prueba | Prueba el ejemplo | Prueba un borde y lo traza |

Con 9 puntos o más de 12, el formato está dominado; con menos de 6, repite el capítulo `01/07` antes del
siguiente simulacro en vivo.

### Qué repasar

| Si falló… | Repasa |
|---|---|
| La idea de la versión buena | [`05/04` — Búsqueda binaria](../05-orden-y-busqueda/04-busqueda-binaria.md) · [`01/02` — Leer las restricciones: de `n` a la complejidad](../01-oficio-del-competidor/02-leer-las-restricciones.md) |
| Preguntar, el coste en voz alta o la prueba a mano | [`01/07` — Programar en vivo](../01-oficio-del-competidor/07-programar-en-vivo.md) |
| El formato de la entrada o de la salida | [`20/04` — El estilo de las pruebas de empresa](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md) |

---

**Anterior:** [`21/11` — Simulacro en vivo 3: Orden de compilación](11-simulacro-en-vivo-03.md) · **Siguiente:** [`21/13` — Simulacro de concurso 1](13-simulacro-concurso-01.md) ·
**Relacionado:** [`21/17` — Pistas](17-pistas.md#12--simulacro-en-vivo-4-el-tope-de-las-ayudas).
