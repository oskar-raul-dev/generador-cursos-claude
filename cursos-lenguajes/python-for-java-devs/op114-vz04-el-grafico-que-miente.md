# ⚖️ vz04 — Veredicto: el gráfico que miente

> Python para desarrolladores Java senior · **Carta** · Track `vz` — Visualización y gráficos ·
> sección 4 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las tres anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track produjo imágenes como entregable: con Matplotlib ([`vz01`](op111-vz01-el-modelo-y-matplotlib.md)), con la gramática
([`vz02`](op112-vz02-la-gramatica.md)) y sin datos ([`vz03`](op113-vz03-graficos-que-no-son-datos.md)). El veredicto del track no es
sobre bibliotecas, sino sobre lo que las bibliotecas permiten: **un gráfico generado por código puede mentir sin que nadie lo haya
decidido**. El eje que empieza donde Matplotlib quiso, el mapa de color que vino por defecto en un tutorial viejo, el semáforo rojo y
verde que uno de cada doce hombres no distingue.

En un reporte que va a diez franquiciados y que justifica una liquidación, una mentira visual es un problema de negocio: Édgar Rojas
compara la barra de Suba con la del Centro y saca una conclusión. Esta sección **mide** tres de las mentiras más comunes con un número
para cada una, para que la regla no sea una opinión de diseño sino una prueba que corre con el reporte.

---

## 🧠 2. El modelo

| La mentira | Cómo se mide | La regla |
|---|---|---|
| **Eje truncado** en un gráfico de barras | **Factor de mentira** (Tufte): diferencia que se ve ÷ diferencia real | Las barras empiezan en cero; si no, se usa otra marca (puntos, líneas) |
| **Doble eje Y** | — (dos escalas elegidas a gusto) | Dos gráficos, o un índice común |
| **Mapa de color no uniforme** (`jet`, `rainbow`) | La luminosidad (L\* de CIELAB) no crece de forma monótona | Mapas perceptualmente uniformes: `viridis`, `cividis` |
| **Paleta que un daltónico no distingue** | Diferencia de color (ΔE) entre los colores **simulados** para deuteranopía | ΔE alto también simulado; forma o texto además del color |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien programa es que el gráfico es una consecuencia de los datos: si los datos son correctos, el gráfico también. No es así: el
eje, la escala y el color son decisiones, y cuando el código no las toma explícitamente, las toma la biblioteca con sus valores por defecto. Un
gráfico de barras con datos correctos y el eje desde 45 millones dice algo falso.

---

## 💻 3. El ejemplo que corre

```bash
uv add numpy matplotlib
```

`mentiras.py`:

```python
"""Tres mentiras visuales, medidas: el factor de mentira, la luminosidad de jet y el semáforo para un daltónico."""

import matplotlib
import numpy as np


# ------------------------------------------------- 1. el eje truncado
def lie_factor(a: float, b: float, axis_from: float) -> float:
    shown = (b - axis_from) / (a - axis_from)
    real = b / a
    return (shown - 1) / (real - 1)


suba, centro = 48_000_000, 52_000_000
for axis_from in (0, 40_000_000, 45_000_000):
    print(f"eje desde ${axis_from / 1e6:>4.0f} M: la barra del Centro se ve {(centro - axis_from) / (suba - axis_from):4.2f}"
          f" veces la de Suba (real {centro / suba:.2f}) · factor de mentira {lie_factor(suba, centro, axis_from):4.1f}")


# ------------------------------------------------- utilidades de color: sRGB → CIELAB
def to_linear(rgb: np.ndarray) -> np.ndarray:
    return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)


def linear_to_lab(lin: np.ndarray) -> np.ndarray:
    xyz = lin @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz = xyz / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > (6 / 29) ** 3, np.cbrt(xyz), xyz / (3 * (6 / 29) ** 2) + 4 / 29)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


# ------------------------------------------------- 2. la luminosidad de los mapas de color
for name in ("jet", "viridis"):
    rgb = matplotlib.colormaps[name](np.linspace(0, 1, 256))[:, :3]
    lightness = linear_to_lab(to_linear(rgb))[:, 0]
    reversals = int(np.sum(np.diff(np.sign(np.diff(lightness))) != 0))
    print(f"{name:<8} L* de {lightness[0]:5.1f} a {lightness[-1]:5.1f}, máximo {lightness.max():5.1f} · cambios de dirección: {reversals}")

# ------------------------------------------------- 3. el semáforo de vz03 visto con deuteranopía (Machado et al., 2009)
DEUTERANOPIA = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
SEMAFORO = {"verde": "#2E7D32", "amarillo": "#F9A825", "rojo": "#C62828"}
rgb = np.array([[int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)] for h in SEMAFORO.values()])
normal = linear_to_lab(to_linear(rgb))
simulated = linear_to_lab(np.clip(to_linear(rgb) @ DEUTERANOPIA.T, 0, 1))
green, red = 0, 2
print(f"verde contra rojo: ΔE {np.linalg.norm(normal[green] - normal[red]):5.1f} con visión típica ·"
      f" {np.linalg.norm(simulated[green] - simulated[red]):5.1f} con deuteranopía")
```

```bash
python3 mentiras.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
eje desde $   0 M: la barra del Centro se ve 1.08 veces la de Suba (real 1.08) · factor de mentira  1.0
eje desde $  40 M: la barra del Centro se ve 1.50 veces la de Suba (real 1.08) · factor de mentira  6.0
eje desde $  45 M: la barra del Centro se ve 2.33 veces la de Suba (real 1.08) · factor de mentira 16.0
jet      L* de  12.9 a  25.4, máximo  95.9 · cambios de dirección: 5
viridis  L* de  14.9 a  90.9, máximo  90.9 · cambios de dirección: 0
verde contra rojo: ΔE 100.8 con visión típica ·  15.8 con deuteranopía
```

Tres números, tres mentiras. Con el eje desde 45 millones, el Centro parece recaudar más del doble que Suba cuando recauda 8 % más: un factor de
mentira de 16. El mapa `jet` sube de luminosidad hasta 95,9 en el medio y vuelve a bajar a 25,4, con cinco cambios de dirección: el ojo ve el
amarillo del centro como "lo más alto" aunque el valor más alto sea el rojo oscuro del final; `viridis` sube siempre. Y el verde y el rojo del
semáforo de `vz03`, a una distancia de 100,8 para la visión típica, quedan a 15,8 para alguien con deuteranopía: dos tonos de un mismo café.

**Detalles con intención**

- **El factor de mentira** compara el efecto visible con el real: 1,0 es honesto; Tufte considera engañoso cualquier valor fuera de 0,95–1,05. Con
  el eje desde 45 millones, una diferencia de 8 % se ve como de 133 %.
- **L\* de CIELAB** es la luminosidad que percibe el ojo. En un mapa de color para una magnitud (mora de 0 % a 20 %), tiene que crecer siempre en
  la misma dirección; si sube y baja, el ojo ve bordes y picos que no están en los datos.
- **La simulación de deuteranopía** usa la matriz de Machado y colaboradores (2009) sobre RGB lineal; es una aproximación estándar, la misma que usan
  las herramientas de accesibilidad. ΔE (distancia en CIELAB) por debajo de 10 a 20 empieza a ser difícil de distinguir de un vistazo.
- **Todo es `numpy`**: la regla se puede volver una prueba que corre con el reporte (ejercicio 7).

---

## ⚠️ 4. Lo que se rompe

**El eje automático.** Matplotlib, en un gráfico de líneas, ajusta el eje a los datos, y está bien; en uno de barras con `set_ylim` "para que se vean
las diferencias", miente. Las barras codifican el valor con la **longitud**, y la longitud solo es honesta desde cero.

**`jet` en un tutorial viejo.** Fue el mapa por defecto de Matplotlib hasta la versión 2.0; muchos ejemplos de internet lo siguen usando. Se fija
`viridis` o `cividis` explícitamente.

**El rojo y verde como única señal.** Uno de cada doce hombres tiene alguna deficiencia en la percepción de rojo y verde. El semáforo de `vz03`
necesita, además del color, el texto o una forma distinta (un ícono por estado).

**El doble eje.** Dos escalas en el mismo gráfico permiten hacer coincidir cualquier par de curvas eligiendo los rangos. No se mide porque no hay
versión honesta: se separan los gráficos.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**En un gráfico de exploración que nadie más va a ver.** Para buscar un patrón, el eje ajustado a los datos ayuda a ver variaciones pequeñas. La
regla es para el entregable.

**En gráficos de líneas.** El eje de un gráfico de líneas no tiene por qué empezar en cero: la línea codifica la posición, no la longitud.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre el ejemplo. **Criterio:** explicas los tres factores de mentira y qué tan lejos está `jet` de ser monótono.
2. Mide `cividis` y `turbo`. **Criterio:** cuál sirve para una magnitud y cuál no.

**🟡 Intermedio (3–4)**

3. Simula protanopía (busca la matriz de Machado para protanopía). **Criterio:** el ΔE del semáforo en ese caso.
4. Elige una paleta de tres colores para el semáforo con ΔE simulado mayor que 20 en los tres pares. **Criterio:** los colores y sus distancias.

**🟠 Difícil (5–6)**

5. Escribe una función que reciba una figura de Matplotlib de barras y falle si el eje Y no empieza en cero. **Criterio:** una prueba que la usa.
6. Rehaz el reporte de recaudo de `vz01` con la paleta del ejercicio 4 y texto en cada barra. **Criterio:** se entiende en escala de grises.

**🔴 Muy difícil (7–8)**

7. Convierte las tres reglas en pruebas que corren con el reporte del cierre. **Criterio:** el código. *Rúbrica:* (a) eje en cero para barras; (b)
   mapas de color permitidos; (c) ΔE mínimo simulado para las paletas; (d) qué pasa en el CI cuando una regla falla.
8. Audita los gráficos de un reporte real (tuyo o público). **Criterio:** una página. *Rúbrica:* (a) cada gráfico con su factor de mentira si es de
   barras; (b) los mapas de color y su luminosidad; (c) las paletas simuladas; (d) la versión corregida de los dos peores.

---

## 📚 7. Referencias

**Libros y artículos**

- Edward Tufte, *The Visual Display of Quantitative Information*, 2.ª ed. (Graphics Press, 2001). El factor de mentira y el resto del vocabulario.
- Gustavo M. Machado, Manuel M. Oliveira y Leandro A. F. Fernandes, *A Physiologically-based Model for Simulation of Color Vision Deficiency* (IEEE
  TVCG, 2009): https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html

**Documentación oficial**

- Matplotlib, elegir mapas de color: https://matplotlib.org/stable/users/explain/colors/colormaps.html

**Orden de lectura sugerido:** la página de mapas de color de Matplotlib (explica la luminosidad con gráficos); después el capítulo de Tufte sobre la
integridad gráfica.

---

## 🚀 8. Cierre

Un gráfico generado por código miente cuando el código no decide el eje, la escala y el color, y deja que decida la biblioteca. Las tres mentiras más
comunes se miden: el factor de mentira de un eje truncado, la luminosidad de un mapa de color, y la distancia de una paleta vista por un daltónico.
Medidas, se vuelven pruebas que corren con el reporte.

**La señal de que quedó bien:** *"Édgar comparó la barra de Suba con la del Centro y vio la diferencia que había: ocho por ciento, no ciento treinta."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-vz-fase-04 -m "op vz04 cerrada: tres mentiras visuales medidas y convertidas en reglas"
> ```
>
> Los commits llevan su prefijo (`op vz04: …`) y los de ejercicio su número
> (`op vz04 ej07: …`).
