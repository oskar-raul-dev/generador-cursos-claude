# 🎨 ar03 — OpenCV, scikit-image y SVG

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 3 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Pillow (`ar02`) redimensiona, rota y convierte. Cuando el trabajo es **analizar** la imagen —encontrar bordes, contar figuras, enderezar un documento
fotografiado—, entran las dos bibliotecas de procesamiento: **OpenCV**, la de C++ con enlaces de Python que usa la industria, y **scikit-image**, la de la comunidad
científica, escrita sobre NumPy y SciPy. Las dos trabajan con arreglos de NumPy, y las dos hacen casi lo mismo; lo que las separa son la velocidad y las
convenciones, y las convenciones son las que muerden.

La otra mitad de la sección va en sentido contrario: **generar** imágenes en vez de leerlas. Un gráfico, una insignia, un diagrama: como vector con SVG
(**drawsvg**) o como mapa de bits con **cairo** (`pycairo`). El ejemplo propio es una imagen de figuras con ruido y una insignia con un nombre de sede.

---

## 🧠 2. El modelo

| | OpenCV (`cv2`) | scikit-image |
|---|---|---|
| Escrita en | C++ con enlaces | Python sobre NumPy, SciPy y Cython |
| Imagen | `ndarray` `uint8`, **BGR** | `ndarray`, **RGB**; muchos filtros devuelven `float64` en [0, 1] |
| Velocidad | La más alta, con varios hilos | Menor; código legible y documentado |
| Instalar en un servidor | **`opencv-python-headless`** | `scikit-image` |
| Lo que la distingue | Video, cámaras, detección | API consistente, algoritmos científicos |

| | SVG (drawsvg) | cairo (`pycairo`) |
|---|---|---|
| Qué produce | Texto XML: vectores | Píxeles (PNG), y también PDF y SVG |
| Escala | Sin perder | Fija al tamaño de la superficie |
| Instalar | Python puro | Necesita la biblioteca de C del sistema |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, una imagen es un `BufferedImage` con su tipo declarado (`TYPE_INT_RGB`), y la biblioteca sabe qué tiene. El instinto espera que un arreglo de imagen
también "sepa" su orden de canales. No sabe: es un `ndarray` de números. OpenCV supone BGR y scikit-image o Pillow suponen RGB, y un arreglo pasado de una a otra
cambia el rojo por el azul sin ningún error.

---

## 💻 3. El ejemplo que corre

`imagenes.py`:

```python
"""OpenCV contra scikit-image con el mismo trabajo, el BGR de OpenCV, y una insignia en SVG y en cairo."""

import os
import time

import cairo
import cv2
import drawsvg
import numpy as np
from PIL import Image
from skimage import feature, filters

# Una imagen de muestra: figuras con ruido, 2000×2000 en grises
rng = np.random.default_rng(42)
img = np.zeros((2000, 2000), dtype=np.uint8)
cv2.rectangle(img, (300, 300), (900, 1100), 200, -1)
cv2.circle(img, (1400, 1200), 400, 140, -1)
img = cv2.add(img, rng.integers(0, 40, img.shape, dtype=np.uint8))


def best(fn, n=3):
    times = []
    for _ in range(n):
        start = time.perf_counter(); result = fn(); times.append(time.perf_counter() - start)
    return result, min(times) * 1000


edges_cv, ms_cv = best(lambda: cv2.Canny(cv2.GaussianBlur(img, (0, 0), 2), 50, 150))
edges_sk, ms_sk = best(lambda: feature.canny(filters.gaussian(img, sigma=2), low_threshold=0.05, high_threshold=0.15))
print(f"OpenCV      {ms_cv:6.1f} ms · salida {edges_cv.dtype}, valores {np.unique(edges_cv).tolist()}, bordes {int((edges_cv > 0).sum()):,}")
print(f"scikit-image {ms_sk:5.1f} ms · salida {edges_sk.dtype}, valores {np.unique(edges_sk).tolist()}, bordes {int(edges_sk.sum()):,}")
print(f"filters.gaussian devuelve {filters.gaussian(img, sigma=2).dtype} en [0, 1], no uint8")

# El BGR de OpenCV: un rojo en RGB, escrito con cv2.imwrite y leído con Pillow
red_rgb = np.zeros((10, 10, 3), dtype=np.uint8); red_rgb[..., 0] = 255
cv2.imwrite("rojo.png", red_rgb)
print("rojo RGB escrito con OpenCV, leído con Pillow:", Image.open("rojo.png").getpixel((0, 0)))

# La misma insignia como vector (drawsvg) y como mapa de bits (cairo)
svg = drawsvg.Drawing(320, 80)
svg.append(drawsvg.Rectangle(0, 0, 320, 80, rx=12, fill="#1f4e79"))
svg.append(drawsvg.Text("Sede Kennedy", 32, 24, 50, fill="white", font_family="sans-serif"))
svg.save_svg("insignia.svg")

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 320, 80)
ctx = cairo.Context(surface)
ctx.set_source_rgb(0x1F / 255, 0x4E / 255, 0x79 / 255)
ctx.new_sub_path()
for x, y, a in ((308, 12, -np.pi / 2), (308, 68, 0), (12, 68, np.pi / 2), (12, 12, np.pi)):
    ctx.arc(x, y, 12, a, a + np.pi / 2)
ctx.close_path(); ctx.fill()
ctx.set_source_rgb(1, 1, 1); ctx.select_font_face("sans-serif"); ctx.set_font_size(32)
ctx.move_to(24, 50); ctx.show_text("Sede Kennedy")
surface.write_to_png("insignia.png")
print(f"insignia.svg {os.path.getsize('insignia.svg')} bytes (texto, escala sin perder) · insignia.png {os.path.getsize('insignia.png')} bytes (320×80 fijos)")
```

```bash
apt-get install libcairo2-dev pkg-config        # pycairo no publica ruedas para Linux: compila contra el cairo del sistema
pip install opencv-python-headless scikit-image drawsvg pycairo Pillow
python3 imagenes.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
OpenCV      7.5 ms · salida uint8, valores [0, 255], bordes 5,703
scikit-image 246.3 ms · salida bool, valores [False, True], bordes 5,650
filters.gaussian devuelve float64 en [0, 1], no uint8
rojo RGB escrito con OpenCV, leído con Pillow: (0, 0, 255)
insignia.svg 355 bytes (texto, escala sin perder) · insignia.png 4518 bytes (320×80 fijos)
```

El mismo trabajo —suavizar y buscar bordes con Canny— tarda **7,5 ms en OpenCV y 246 ms en scikit-image**, 33 veces más, y encuentran casi los mismos bordes
(5.703 contra 5.650 píxeles; los umbrales no son idénticos entre las dos). Pero devuelven tipos distintos: OpenCV un `uint8` con 0 y 255, scikit-image un `bool`; y
`filters.gaussian` convierte a `float64` en [0, 1], de modo que un umbral pensado en 0–255 no encuentra nada. El rojo escrito por OpenCV llega a Pillow como
**azul** (0, 0, 255). Y la insignia: 355 bytes de SVG que escalan a cualquier tamaño, contra 4,5 KB de PNG fijo.

**Detalles con intención**

- **`opencv-python-headless`** y no `opencv-python`: el segundo trae las ventanas de `cv2.imshow` y necesita `libGL`; en un servidor o un contenedor, el `import`
  falla con `ImportError: libGL.so.1: cannot open shared object file`.
- **`cv2.add`** suma con saturación (255 + 10 = 255); `img + ruido` en NumPy da la vuelta (255 + 10 = 9). Es otra convención que cambia entre bibliotecas.
- **`cv2.cvtColor(img, cv2.COLOR_BGR2RGB)`** es la conversión que falta antes de pasarle a Pillow o scikit-image una imagen de OpenCV.
- **La insignia en cairo** dibuja las esquinas redondeadas con cuatro arcos: cairo es una API de dibujo de bajo nivel, como `Graphics2D`.

---

## ⚠️ 4. Lo que se rompe

**`opencv-python` en el servidor.** Funciona en el portátil, falla en el contenedor por `libGL`. Y si alguna dependencia instala `opencv-python` y otra la versión
`-headless`, las dos pisan el mismo módulo `cv2`. Se instala una sola variante.

**El rojo que sale azul.** Cualquier imagen que cruza entre OpenCV y el resto pasa por `cvtColor`. Se escribe una función de frontera y se usa siempre.

**El umbral en la escala equivocada.** Un `float64` en [0, 1] comparado con 128 da todo falso. Se convierte con `skimage.util.img_as_ubyte` o se piensa el umbral en la
escala del tipo.

**pycairo que no instala.** Sin `libcairo2-dev` y `pkg-config`, `pip install pycairo` falla al compilar en Linux. En contenedores, el paquete del sistema va en el
`Dockerfile`.

---

## ⚖️ 5. Cuándo NO usarlas

**Para redimensionar y convertir.** Pillow (`ar02`) alcanza y pesa mucho menos que OpenCV.

**scikit-image en un bucle de video en tiempo real.** 33 veces más lenta que OpenCV en este trabajo; para prototipar y para ciencia, sí.

**cairo para un gráfico de datos.** Matplotlib o Altair (`vz`) ya dibujan ejes y leyendas; cairo es para dibujos propios.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cinco líneas, y por qué el rojo sale azul.
2. Corrige el rojo con `cv2.cvtColor`. **Criterio:** Pillow lee (255, 0, 0).
3. Abre `insignia.svg` en el navegador y amplíalo al 800%. **Criterio:** los bordes siguen nítidos; con el PNG, no.

**🟡 Intermedio (4–6)**

4. Umbraliza la imagen y cuenta las figuras con `cv2.findContours` y con `skimage.measure.label`. **Criterio:** las dos dan 2, sin contar el ruido.
5. Repite la medición de Canny con `cv2.setNumThreads(1)`. **Criterio:** cuánto de la ventaja de OpenCV venía de los hilos.
6. Genera con drawsvg un gráfico de barras de cinco valores con sus etiquetas. **Criterio:** un SVG válido de menos de 2 KB.

**🟠 Difícil (7–9)**

7. Endereza la foto de un documento (detecta sus cuatro esquinas y aplica `cv2.warpPerspective`). **Criterio:** el documento queda rectangular.
8. Haz que cairo escriba la insignia en PDF en vez de PNG (`cairo.PDFSurface`). **Criterio:** un PDF vectorial con el texto seleccionable.
9. Mide la memoria de un *pipeline* de 100 imágenes en OpenCV y en scikit-image. **Criterio:** la memoria máxima de cada uno y por qué difieren.

**🔴 Muy difícil (10)**

10. Decide la biblioteca de un servicio que procesa fotos de documentos. **Criterio:** una página. *Rúbrica:* (a) las operaciones que necesita; (b) los tiempos medidos
    de las dos; (c) cómo se maneja el orden de canales en la frontera; (d) qué se instala en el contenedor y cuánto pesa.

---

## 📚 7. Referencias

**Documentación oficial**

- `opencv-python`, sus cuatro variantes y cuál instalar en un servidor: https://github.com/opencv/opencv-python
- scikit-image: https://scikit-image.org/docs/stable/
- drawsvg: https://github.com/cduck/drawsvg
- pycairo: https://pycairo.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la guía de usuario de scikit-image sobre tipos de datos (la escala de cada `dtype`); después el README de `opencv-python`, sobre
las variantes del paquete.

---

## 🚀 8. Cierre

OpenCV y scikit-image hacen el mismo trabajo sobre los mismos arreglos de NumPy, una 33 veces más rápido que la otra en este ejemplo, y con convenciones distintas
que no avisan: BGR contra RGB, `uint8` contra `float64` en [0, 1]. Para generar, SVG escala sin perder y cairo dibuja píxeles con la biblioteca de C del sistema.

**La señal de que quedó bien:** *"Toda imagen que cruza entre OpenCV y el resto pasa por una sola función de conversión, y el contenedor instala la variante
`-headless`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-03 -m "op ar03 cerrada: OpenCV y scikit-image medidas, sus convenciones, SVG y cairo"
> ```
>
> Los commits llevan su prefijo (`op ar03: …`) y los de ejercicio su número
> (`op ar03 ej07: …`).
