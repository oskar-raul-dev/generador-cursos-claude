# ⚖️ ar10 — Veredicto: el pegamento contra el binario

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 10 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las nueve anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el binario de verdad ([`ar01`](op147-ar01-binario-de-verdad.md)), Pillow ([`ar02`](op148-ar02-pillow.md)), OpenCV y SVG
([`ar03`](op149-ar03-opencv-y-svg.md)), PDF ([`ar04`](op150-ar04-pdf.md)), Office ([`ar05`](op151-ar05-office.md)), pandoc
([`ar06`](op152-ar06-markdown-html-y-pandoc.md)), LaTeX y Typst ([`ar07`](op153-ar07-latex-y-typst.md)), vídeo ([`ar08`](op154-ar08-video.md)) y audio
([`ar09`](op155-ar09-audio.md)). En casi todas apareció la misma pregunta: **¿una biblioteca dentro del proceso de Python, o un binario llamado con `subprocess`?**

El veredicto es que **el binario gana cuando hace la tarea completa y se llama pocas veces**: FFmpeg sacó los cuadros cuatro veces más rápido que PyAV, pandoc
convierte entre formatos como nadie, y ninguno se rompe cuando un envoltorio deja de mantenerse. **La biblioteca gana en dos casos**: cuando hay que tocar cada
cuadro, muestra o celda con código propio, y cuando la tarea se repite tanto que el arranque del binario pesa: 17 ms de pandoc contra 0,17 de `markdown-it-py`, 656 ms
de LaTeX contra 18 de Typst.

---

## 🧠 2. El modelo

| Comparación del track | Binario | En el proceso | Quién ganó y por qué |
|---|---|---|---|
| Un cuadro por segundo a JPEG (`ar08`) | FFmpeg: 333 ms | PyAV: 1.353 ms | **Binario**: el filtro corre entero en C |
| Markdown a HTML (`ar06`) | pandoc: 17,1 ms | `markdown-it-py`: 0,17 ms | **Proceso**: el arranque del binario |
| Informe en PDF (`ar07`) | `pdflatex`: 656 ms | Typst: 18 ms | **Proceso**, y sin escapar texto |
| Cortar 5 s de vídeo (`ar08`) | FFmpeg: 62 ms (copia) / 659 (exacto) | MoviePy: 1.068 ms | **Binario**; MoviePy por comodidad |
| Comprimir 19 MB (`ar01`) | — | `zipfile` con zstd: 69 ms | La biblioteca estándar, sin binario |
| Editar audio (`ar09`) | FFmpeg | pydub: **no importa en 3.14** | **Binario**: la biblioteca está dormida |

Y lo que no está en la columna del tiempo: las licencias (PyMuPDF es AGPL, `ar04`), las versiones de los binarios (Debian trae pandoc 3.1.11 y FFmpeg 7.1.5, otras
bibliotecas traen el suyo) y las opciones por defecto que no protegen (`<script>` en pandoc, `valid` en pyHanko, el segundo escondido de `-c copy`).

---

## 💻 3. El ejemplo que corre

Sin dependencias. `pegamento.py` es la regla del track como función:

```python
"""¿Biblioteca en el proceso o binario por subprocess? El veredicto del track como función, aplicado a siete tareas."""

from dataclasses import dataclass


@dataclass
class Task:
    name: str
    binary_does_it_whole: bool          # ¿el binario hace la tarea completa con sus opciones?
    touches_each_item: bool = False     # ¿hay que mirar o decidir sobre cada cuadro, muestra o celda?
    calls_per_second: float = 0.01      # ¿cuántas veces se ejecuta?
    library_alive: bool = True          # ¿la biblioteca publica versiones?


def decide(t: Task) -> str:
    if t.touches_each_item:
        return "biblioteca en el proceso" + ("" if t.library_alive else " (y buscar reemplazo: está dormida)")
    if t.binary_does_it_whole and t.calls_per_second < 10:
        return "binario por subprocess, con versión fija"
    if t.library_alive:
        return "biblioteca en el proceso: el arranque del binario pesa"
    return "binario por subprocess: la biblioteca está dormida"


TASKS = [
    Task("Convertir un informe de Markdown a Word", binary_does_it_whole=True),
    Task("Renderizar Markdown de cada comentario", binary_does_it_whole=True, calls_per_second=200),
    Task("Sacar un cuadro por segundo de un vídeo", binary_does_it_whole=True),
    Task("Brillo medio de cada cuadro", binary_does_it_whole=False, touches_each_item=True),
    Task("Certificados en PDF, miles por hora", binary_does_it_whole=True, calls_per_second=20),
    Task("Cortar y unir notas de voz", binary_does_it_whole=True, library_alive=False),
    Task("Leer la tabla de un PDF", binary_does_it_whole=False, touches_each_item=True),
]
for t in TASKS:
    print(f"{t.name:<42} → {decide(t)}")
```

```bash
python3 pegamento.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Convertir un informe de Markdown a Word    → binario por subprocess, con versión fija
Renderizar Markdown de cada comentario     → biblioteca en el proceso: el arranque del binario pesa
Sacar un cuadro por segundo de un vídeo    → binario por subprocess, con versión fija
Brillo medio de cada cuadro                → biblioteca en el proceso
Certificados en PDF, miles por hora        → biblioteca en el proceso: el arranque del binario pesa
Cortar y unir notas de voz                 → binario por subprocess, con versión fija
Leer la tabla de un PDF                    → biblioteca en el proceso
```

**Detalles con intención**

- **Tocar cada elemento se evalúa primero**: si el código tiene que decidir sobre cada cuadro o cada celda, el binario no sirve, por rápido que sea.
- **El umbral de 10 llamadas por segundo** es una suposición a la vista: con 17 ms de arranque, diez llamadas por segundo ya se comen un sexto de un núcleo.
- **"Con versión fija"** acompaña siempre al binario: el que se instala "de la distribución" cambia con la imagen base (`ar06`, `ar08`).
- **Las notas de voz van al binario** porque la biblioteca del caso (pydub) está dormida; con una biblioteca viva, la regla podría decir otra cosa.

---

## ⚠️ 4. Lo que se rompe

**Envolver por reflejo.** Buscar "el paquete de Python para X" cuando X es un binario maduro lleva a envoltorios dormidos (`ffmpeg-python`, pydub) que fallan el día que
cambia Python o el binario.

**Llamar al binario en el bucle caliente.** Cada llamada arranca un proceso; mil llamadas son mil arranques.

**Confiar en los valores por defecto.** Tres secciones del track encontraron un valor por defecto que no protege: el HTML crudo de pandoc, el `valid` de pyHanko y la copia
de FFmpeg que guarda lo que no se pidió.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si la biblioteca y el binario son lo mismo.** `pypandoc` llama a pandoc; elegir entre ellos es elegir cómo se arma la línea de comandos, no el motor.

**En un entorno sin binarios.** Funciones en la nube o un contenedor mínimo sin `apt`: ahí la rueda que trae todo adentro (Typst, `imageio-ffmpeg`) gana aunque sea más
lenta.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres tareas de archivos de tu trabajo. **Criterio:** la salida, y si estás de acuerdo.
2. Cambia el umbral de llamadas a 1 por segundo. **Criterio:** qué tarea cambia y si mejora la decisión.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "hay binario en el entorno de ejecución". **Criterio:** un caso que pase de binario a biblioteca.
4. Escribe las pruebas de `decide` con un caso por regla. **Criterio:** cuatro casos, todos pasan.

**🟠 Difícil (5–6)**

5. Mide el arranque de cada binario del track (`ffmpeg -version`, `pandoc --version`, `pdflatex --version`) en tu máquina. **Criterio:** la tabla, y cuántas llamadas por segundo
   aguantaría un núcleo con cada uno.
6. Escribe una función de frontera para FFmpeg (argumentos como lista, nombres validados, `check=True`, `timeout`). **Criterio:** sus pruebas, incluida una con un nombre
   que empieza con `-`.

**🔴 Muy difícil (7–8)**

7. Escribe la política de dependencias de archivos de un proyecto. **Criterio:** una página. *Rúbrica:* (a) cuándo binario y cuándo biblioteca; (b) cómo se fijan las
   versiones de los binarios; (c) cómo se detecta una dependencia dormida; (d) las licencias que se revisan.
8. Audita las dependencias de archivos de un proyecto real. **Criterio:** una tabla. *Rúbrica:* (a) cada tarea con su herramienta actual; (b) la decisión de la tabla; (c) las
   dependencias dormidas; (d) el costo de cambiar las que deberían.

---

## 📚 7. Referencias

- La documentación de `subprocess`, la frontera de todo binario: https://docs.python.org/3/library/subprocess.html

**Orden de lectura sugerido:** las secciones de seguridad y de `timeout` de `subprocess`; el resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

El binario gana cuando hace la tarea completa y se llama pocas veces: es más rápido, más completo y no se queda dormido. La biblioteca gana cuando hay que tocar cada
elemento o cuando el arranque del binario se repite demasiado. En los dos casos, con la versión fija y los valores por defecto revisados.

**La señal de que quedó bien:** *"Cada tarea de archivos del proyecto dice si usa un binario o una biblioteca, con su versión fija y la razón al lado."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-10 -m "op ar10 cerrada: el binario para la tarea completa, la biblioteca para cada elemento"
> ```
>
> Los commits llevan su prefijo (`op ar10: …`) y los de ejercicio su número
> (`op ar10 ej07: …`).
