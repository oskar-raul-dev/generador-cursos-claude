# 🎬 ar08 — Vídeo

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 8 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Casi todo el vídeo del mundo pasa por **FFmpeg**, una colección de bibliotecas en C y un binario con una línea de comandos enorme. Desde Python hay tres formas de usarlo:
**llamar al binario** con `subprocess` (lo que el camino base enseñó en la Fase 05), **PyAV**, un enlace real a las bibliotecas de FFmpeg que entrega cuadro por cuadro,
y **MoviePy**, una capa declarativa para editar ("corta de 5 a 10, pon un título encima") que por debajo también usa FFmpeg.

Esta sección se escribe alrededor de una decisión, no de una biblioteca: **envolver el binario o llamarlo**. Mide las tres rutas con dos trabajos de todos los días
—sacar un cuadro por segundo y cortar un tramo— sobre un vídeo de prueba generado por FFmpeg, y muestra lo que hace un corte "sin recodificar" que nadie mira.

---

## 🧠 2. El modelo

| Ruta | Qué es | Cuándo gana |
|---|---|---|
| **`ffmpeg` por `subprocess`** | El binario, con sus opciones | Todo lo que la línea de comandos ya hace: convertir, cortar, extraer, escalar |
| **PyAV** (`av`) | Enlace a `libavformat` y `libavcodec` | Cuando hay que tocar **cada cuadro** en Python: analizar, filtrar con NumPy, decidir |
| **MoviePy** | Edición declarativa sobre FFmpeg | Montajes: concatenar, superponer texto, transiciones |

| Corte | Qué hace | Costo |
|---|---|---|
| `-c copy` | Copia los paquetes comprimidos, sin decodificar | Rapidísimo; solo puede empezar en un *keyframe* |
| Recodificar | Decodifica y vuelve a comprimir | Lento; empieza exactamente donde se pidió |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de Java es buscar la biblioteca: JavaCV, Xuggler, JCodec. Para vídeo, la biblioteca que envuelve FFmpeg siempre va atrás de FFmpeg, y su superficie es
una fracción de la del binario. Xuggler no publica una versión desde hace más de diez años. En Python pasa igual: los envoltorios que no tienen financiamiento se quedan atrás, y la ruta que
no se rompe es llamar al binario. La biblioteca se justifica solo cuando hay que entrar al cuadro.

---

## 💻 3. El ejemplo que corre

`video.py`:

```python
"""Vídeo: el binario de ffmpeg contra PyAV y MoviePy en el mismo trabajo, y el corte que no cae donde se pidió."""

import json
import subprocess
import time

import av
from moviepy import VideoFileClip


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


def duration(path):
    probe = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", path],
                                      capture_output=True, text=True).stdout)
    return float(probe["format"]["duration"])


def timed(fn):
    start = time.perf_counter(); fn(); return (time.perf_counter() - start) * 1000


# Un vídeo de muestra: 20 s de patrón de prueba, 1280×720 a 25 cuadros, un keyframe cada 4 s
ffmpeg("-f", "lavfi", "-i", "testsrc2=size=1280x720:rate=25:duration=20", "-c:v", "libx264", "-g", "100",
       "-pix_fmt", "yuv420p", "muestra.mp4")

# 1) Un cuadro por segundo como JPEG: el binario contra PyAV
ms_bin = timed(lambda: ffmpeg("-i", "muestra.mp4", "-vf", "fps=1", "cuadro_%02d.jpg"))


def frames_with_pyav():
    with av.open("muestra.mp4") as container:
        stream = container.streams.video[0]
        next_second = 0.0
        for frame in container.decode(stream):
            if frame.time >= next_second:
                frame.to_image().save(f"pyav_{int(next_second):02d}.jpg")
                next_second += 1


ms_av = timed(frames_with_pyav)
print(f"20 cuadros a JPEG · ffmpeg {ms_bin:5.0f} ms · PyAV {ms_av:5.0f} ms")

# 2) Cortar de 5 s a 10 s: copiar sin recodificar contra recodificar
ms_copy = timed(lambda: ffmpeg("-ss", "5", "-i", "muestra.mp4", "-t", "5", "-c", "copy", "corte_copia.mp4"))
ms_enc = timed(lambda: ffmpeg("-ss", "5", "-i", "muestra.mp4", "-t", "5", "-c:v", "libx264", "corte_recodificado.mp4"))
for name, path, ms in (("copia", "corte_copia.mp4", ms_copy), ("recodificado", "corte_recodificado.mp4", ms_enc)):
    with av.open(path) as c:
        stream = c.streams.video[0]
        packets = [p for p in c.demux(stream) if p.pts is not None]
        hidden = sum(p.pts * stream.time_base < 0 for p in packets)
        print(f"corte {name:<12} {ms:5.0f} ms · duración {duration(path):5.2f} s · cuadros guardados {len(packets)}"
              f" · antes de t=0, escondidos: {hidden}")

# 3) MoviePy: el mismo corte, declarativo
clip = VideoFileClip("muestra.mp4")
ms_mp = timed(lambda: clip.subclipped(5, 10).write_videofile("corte_moviepy.mp4", codec="libx264", logger=None))
clip.close()
print(f"corte con MoviePy   {ms_mp:5.0f} ms · duración {duration('corte_moviepy.mp4'):5.2f} s")
```

```bash
apt-get install ffmpeg          # FFmpeg 7.1.5 de Debian en el contenedor
pip install av moviepy
python3 video.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
20 cuadros a JPEG · ffmpeg   333 ms · PyAV  1353 ms
corte copia           62 ms · duración  5.08 s · cuadros guardados 152 · antes de t=0, escondidos: 25
corte recodificado   659 ms · duración  5.00 s · cuadros guardados 125 · antes de t=0, escondidos: 0
corte con MoviePy    1068 ms · duración  5.00 s
```

Sacar un cuadro por segundo cuesta **333 ms con el binario y 1.353 con PyAV**: el bucle de PyAV decodifica los 500 cuadros, convierte a imagen de Pillow y guarda,
pasando por Python en cada uno; el filtro `fps=1` de FFmpeg hace todo en C. Cortar copiando tarda **62 ms**, diez veces menos que recodificando, y dura 5,08 s; pero
guarda **152 cuadros, 25 de ellos escondidos antes de t=0**: el corte tuvo que empezar en el *keyframe* de los 4 segundos, y FFmpeg marcó el segundo sobrante para que
el reproductor no lo muestre. El archivo lo lleva. Recodificar da 125 cuadros exactos. MoviePy hace el mismo corte en 1.068 ms, con una línea.

**Detalles con intención**

- **`-g 100`** pone un *keyframe* cada 100 cuadros (4 s a 25 cuadros por segundo): es lo que hace visible el problema. Las cámaras y los teléfonos usan intervalos de
  uno a diez segundos.
- **`-ss` antes de `-i`** busca en la entrada (rápido, al *keyframe* anterior); después de `-i`, decodifica desde el principio hasta el punto pedido.
- **Los 25 cuadros escondidos** tienen marcas de tiempo negativas y una lista de edición que dice "empezar en 0". Un reproductor que la respeta no los muestra; una
  herramienta que no la respeta, o un editor que concatena archivos, sí.
- **`check=True`** y `-loglevel error`: FFmpeg escribe mucho en `stderr` aunque todo salga bien; así solo aparecen los errores, y un código de salida distinto de cero
  se vuelve una excepción.

---

## ⚠️ 4. Lo que se rompe

**El corte con `-c copy` que trae lo que no se pidió.** Para un recorte que va a publicarse o a concatenarse, se recodifica, o al menos se recodifica el tramo hasta el
primer *keyframe* (*smart cut*).

**El envoltorio abandonado.** `ffmpeg-python` no publica una versión desde 2019; `decord`, desde 2021. Funcionan hasta que FFmpeg cambia una opción. Se arma la línea de
comandos a mano, en una función con pruebas.

**El binario de otra versión.** El contenedor trae FFmpeg 7.1.5 de Debian; `imageio-ffmpeg` (que usa MoviePy) trae **su propio** binario. Dos versiones distintas en el
mismo proyecto dan resultados distintos.

**Los nombres de archivo que vienen de usuarios.** `subprocess` con lista de argumentos, nunca con `shell=True`; y un nombre que empieza con `-` se interpreta como opción:
se antepone `./` o `file:`.

---

## ⚖️ 5. Cuándo NO usar cada una

**PyAV para lo que el binario ya hace.** Cuatro veces más lento en este trabajo; se usa cuando el cuadro tiene que pasar por código propio.

**MoviePy en un servicio con volumen.** Es para montajes; para convertir mil vídeos, el binario.

**`-c copy` para cortes exactos.** Rápido y casi exacto; "casi" incluye un segundo escondido.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cuatro líneas, y de dónde salen los 25 cuadros escondidos.
2. Genera el vídeo con `-g 25` y repite el corte con copia. **Criterio:** cuántos cuadros escondidos quedan ahora.
3. Haz con `subprocess` una miniatura del cuadro del segundo 7. **Criterio:** un JPEG del cuadro correcto.

**🟡 Intermedio (4–6)**

4. Une dos cortes con copia (`concat`) y mira el resultado en un reproductor. **Criterio:** si aparece el segundo escondido en la unión.
5. Con PyAV, calcula el brillo medio de cada cuadro con NumPy. **Criterio:** la serie de 500 valores, y el tiempo.
6. Convierte el vídeo a 480p en H.265 y en AV1. **Criterio:** tamaño y tiempo de cada uno.

**🟠 Difícil (7–9)**

7. Escribe una función `cut(path, start, end, exact)` que copie si `start` cae en un *keyframe* y recodifique si no. **Criterio:** las pruebas de los dos casos.
8. Haz con MoviePy un video desde 20 imágenes con un título superpuesto. **Criterio:** el vídeo, y la misma tarea con el binario para comparar.
9. Compara la versión de FFmpeg de Debian con la de `imageio-ffmpeg`. **Criterio:** las dos versiones y una opción que se comporte distinto.

**🔴 Muy difícil (10)**

10. Diseña el procesamiento de los vídeos que suben los usuarios de un sistema. **Criterio:** una página. *Rúbrica:* (a) qué se hace con el binario y qué con PyAV, y por
    qué; (b) cómo se fija la versión de FFmpeg; (c) cómo se validan los nombres y formatos de entrada; (d) los tiempos medidos para un vídeo típico.

---

## 📚 7. Referencias

**Documentación oficial**

- FFmpeg: https://ffmpeg.org/ffmpeg.html
- PyAV: https://pyav.basswood-io.com/docs/stable/
- MoviePy: https://zulko.github.io/moviepy/

**Orden de lectura sugerido:** la sección de `-ss` en la documentación de FFmpeg (buscar en la entrada o en la salida); después la introducción de PyAV.

---

## 🚀 8. Cierre

Para vídeo, la ruta que no se rompe es llamar al binario de FFmpeg: hace en 333 ms lo que PyAV en 1.353. PyAV se justifica cuando el cuadro tiene que pasar por código
propio, y MoviePy cuando la tarea es un montaje. Y el corte sin recodificar, diez veces más rápido, guarda un segundo que no se pidió escondido antes de t=0.

**La señal de que quedó bien:** *"FFmpeg está fijado en una versión, se llama con una lista de argumentos, y los cortes que se publican se recodifican."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-08 -m "op ar08 cerrada: el binario contra PyAV y MoviePy, y el segundo escondido"
> ```
>
> Los commits llevan su prefijo (`op ar08: …`) y los de ejercicio su número
> (`op ar08 ej07: …`).
