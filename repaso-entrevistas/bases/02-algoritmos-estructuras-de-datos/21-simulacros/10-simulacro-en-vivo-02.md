# 10 — Simulacro en vivo 2: El hueco para la reunión

> Formato en vivo: un problema, 45 minutos, con otra persona que hace de entrevistadora (o grabándose y
> haciendo de las dos cosas). Se califica con la rúbrica de seis puntos de
> [`01/07`](../01-oficio-del-competidor/07-programar-en-vivo.md), **no** con el verde de un juez. Quien hace de
> candidato lee solo hasta «El problema»; quien entrevista lee también el guion. Las pistas 2 y 3 están en
> [`17-pistas.md`](17-pistas.md#10--simulacro-en-vivo-2-el-hueco-para-la-reunión).
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

### El hueco para la reunión

**Nivel:** 🟡 · **Tiempo:** 45 minutos · **Formato:** programa completo, en vivo.

Dos personas tienen sus agendas del día como listas de intervalos ocupados, ordenados y sin solapes dentro de
cada lista. La jornada va de `09:00` a `17:00`. Imprime la hora más temprana a la que pueden empezar una
reunión de `d` minutos sin pisar ningún intervalo ocupado de ninguna de las dos, o `NO` si no hay hueco.

- **Entrada.** Una línea con `d`. Una línea con `a` y después `a` líneas `HH:MM-HH:MM` de la primera persona;
  una línea con `b` y después `b` líneas de la segunda.
- **Salida.** Una hora `HH:MM`, o `NO`.
- **Restricciones.** `1 ≤ d ≤ 480`; `0 ≤ a, b ≤ 10⁵`; todos los intervalos dentro de la jornada.

```text
Entrada         Salida
30              11:00
3
09:00-10:30
12:00-13:00
16:00-17:00
2
10:00-11:00
12:30-14:00
```

```text
Entrada         Salida
90              14:00
3
09:00-10:30
12:00-13:00
16:00-17:00
2
10:00-11:00
12:30-14:00
```

---

## 🧭 Guion del entrevistador

**Antes de empezar.** Lee el enunciado en voz alta y no añadas nada. Si el candidato no pregunta nada en los
primeros cinco minutos, anótalo en el primer punto de la rúbrica. Preguntas que **debería** hacer (responde a
las que haga; no las sugieras):

- «¿Un intervalo que termina a las 10:00 y una reunión que empieza a las 10:00 se pisan?»
- «¿Las listas vienen ordenadas?»
- «¿Hay que devolver la primera hora posible o cualquiera?»

**Las pistas, solo si se atasca**:

- **Hacia el minuto 12**, si no hay una versión que funcione: «Si juntaras las dos agendas en una sola, ¿qué
  tendrías que hacer con los intervalos que se pisan?»
- **Hacia el minuto 25**, si no hay idea de mejora: «Piensa en esto: mezclar las dos listas ordenadas y
  fusionar los intervalos solapados; los huecos entre ellos son los tiempos libres comunes.»
- **Hacia el minuto 35**, si la idea está pero no el código: «Todo en minutos; recorre los intervalos
  fusionados con el «último final» empezando en `09:00`; el primer hueco de al menos `d` minutos (incluido el
  último, hasta `17:00`) es la respuesta; dos punteros, `O(a + b)`.»

Cada pista que des se anota y baja un punto en «la mejora nombrada con precisión».

**Si termina antes de tiempo**, una ampliación para hablar, sin código:

- ¿Y con `k` personas?
- ¿Y si la jornada de cada persona es distinta?

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
| La idea de la versión buena | [`11/02` — Intervalos](../11-voraces/02-intervalos.md) · [`04/02` — Dos punteros y ventana deslizante](../04-secuencias/02-dos-punteros-y-ventana.md) |
| Preguntar, el coste en voz alta o la prueba a mano | [`01/07` — Programar en vivo](../01-oficio-del-competidor/07-programar-en-vivo.md) |
| El formato de la entrada o de la salida | [`20/04` — El estilo de las pruebas de empresa](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md) |

---

**Anterior:** [`21/09` — Simulacro en vivo 1: Ventas por hora](09-simulacro-en-vivo-01.md) · **Siguiente:** [`21/11` — Simulacro en vivo 3: Orden de compilación](11-simulacro-en-vivo-03.md) ·
**Relacionado:** [`21/17` — Pistas](17-pistas.md#10--simulacro-en-vivo-2-el-hueco-para-la-reunión).
