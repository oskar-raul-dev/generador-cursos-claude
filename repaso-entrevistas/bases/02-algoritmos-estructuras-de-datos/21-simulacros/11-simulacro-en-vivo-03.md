# 11 — Simulacro en vivo 3: Orden de compilación

> Formato en vivo: un problema, 45 minutos, con otra persona que hace de entrevistadora (o grabándose y
> haciendo de las dos cosas). Se califica con la rúbrica de seis puntos de
> [`01/07`](../01-oficio-del-competidor/07-programar-en-vivo.md), **no** con el verde de un juez. Quien hace de
> candidato lee solo hasta «El problema»; quien entrevista lee también el guion. Las pistas 2 y 3 están en
> [`17-pistas.md`](17-pistas.md#11--simulacro-en-vivo-3-orden-de-compilación).
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

### Orden de compilación

**Nivel:** 🟠 · **Tiempo:** 45 minutos · **Formato:** programa completo, en vivo.

Un proyecto tiene `n` módulos, identificados por su nombre. Algunos dependen de otros: un módulo solo se puede
compilar después de todos aquellos de los que depende. Imprime un orden de compilación que, en cada paso,
elija el módulo disponible de nombre menor (orden alfabético), o `CICLO` si no existe ningún orden.

- **Entrada.** Una línea con `n` y `m`. Una línea con los `n` nombres. Después, `m` líneas `A B`: `A` depende
  de `B`.
- **Salida.** Los `n` nombres en orden de compilación, en una línea, o `CICLO`.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `0 ≤ m ≤ 2·10⁵`; nombres de 1 a 20 letras minúsculas, distintos.

```text
Entrada           Salida
4 4               util core db app
app core db util
app core
app db
db util
core util
```

```text
Entrada         Salida
2 2             CICLO
a b
a b
b a
```

---

## 🧭 Guion del entrevistador

**Antes de empezar.** Lee el enunciado en voz alta y no añadas nada. Si el candidato no pregunta nada en los
primeros cinco minutos, anótalo en el primer punto de la rúbrica. Preguntas que **debería** hacer (responde a
las que haga; no las sugieras):

- «¿Puede haber dependencias repetidas?»
- «¿Un módulo puede depender de sí mismo?»
- «¿Hay que dar un orden cualquiera o uno concreto?»

**Las pistas, solo si se atasca**:

- **Hacia el minuto 12**, si no hay una versión que funcione: «¿Qué módulos se pueden compilar al principio, y
  qué cambia cuando compilas uno?»
- **Hacia el minuto 25**, si no hay idea de mejora: «Piensa en esto: orden topológico de Kahn con una cola de
  prioridad en lugar de una cola normal.»
- **Hacia el minuto 35**, si la idea está pero no el código: «Grado de entrada de cada módulo; empieza con los
  de grado 0 en un *heap* por nombre; al sacar uno, baja el grado de los que dependen de él; si al final no
  salieron todos, hay un ciclo. `O((n + m) log n)`.»

Cada pista que des se anota y baja un punto en «la mejora nombrada con precisión».

**Si termina antes de tiempo**, una ampliación para hablar, sin código:

- ¿Y si hay que compilar en paralelo en el menor número de rondas?
- ¿Cómo dices qué módulos forman el ciclo?

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
| La idea de la versión buena | [`14/04` — Orden topológico y DP sobre DAG](../14-grafos-recorridos/04-orden-topologico.md) · [`08/02` — Patrones con *heap*](../08-heaps-y-union-find/02-patrones-con-heap.md) |
| Preguntar, el coste en voz alta o la prueba a mano | [`01/07` — Programar en vivo](../01-oficio-del-competidor/07-programar-en-vivo.md) |
| El formato de la entrada o de la salida | [`20/04` — El estilo de las pruebas de empresa](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md) |

---

**Anterior:** [`21/10` — Simulacro en vivo 2: El hueco para la reunión](10-simulacro-en-vivo-02.md) · **Siguiente:** [`21/12` — Simulacro en vivo 4: El tope de las ayudas](12-simulacro-en-vivo-04.md) ·
**Relacionado:** [`21/17` — Pistas](17-pistas.md#11--simulacro-en-vivo-3-orden-de-compilación).
