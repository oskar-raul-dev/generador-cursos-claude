# 🎧 ar09 — Audio

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 9 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El audio llega como notas de voz, grabaciones de llamadas, música de espera o pódcasts, y hay que hacer cosas parecidas a las del vídeo (`ar08`): convertir formatos,
normalizar el volumen, cortar, etiquetar y, a veces, analizar. Python tiene una biblioteca por tarea: **soundfile** lee y escribe audio sin pérdida como arreglos de NumPy;
**librosa** analiza (tono, ritmo, espectro); **pedalboard**, de Spotify, aplica efectos en C++; **mutagen** lee y escribe etiquetas de cualquier formato; y **pydub**,
la más citada en tutoriales, hace edición simple.

La sección pasa un tono de prueba de diez segundos por las cinco, con FFmpeg para los formatos con pérdida. Y empieza con lo que el inventario marcaba como dormido:
pydub no publica una versión desde 2021, y en Python 3.14 **ya no importa** sin ayuda.

---

## 🧠 2. El modelo

| Biblioteca | Para qué | Por debajo | Estado |
|---|---|---|---|
| **soundfile** | Leer y escribir WAV, FLAC, OGG como `ndarray` | `libsndfile` (C) | Activa |
| **librosa** | Análisis: tono (`pyin`), ritmo, espectrogramas | NumPy, SciPy, **numba** | Activa (1.0 en 2026) |
| **pedalboard** | Efectos: compresor, ganancia, reverberación, filtros | C++ (JUCE) | Activa |
| **mutagen** | Etiquetas de MP3, FLAC, MP4, Ogg con una sola interfaz | Python puro | Activa |
| **pydub** | Edición simple: cortar, unir, normalizar | `audioop` y FFmpeg | **Dormida desde 2021** |
| **FFmpeg** (binario) | Codificar MP3, Opus, AAC | C | La ruta que no se rompe (`ar08`) |

### Esto sí funciona igual

El audio es un arreglo de muestras con una frecuencia de muestreo, como en `javax.sound.sampled` con su `AudioFormat`. Lo que cambia es que en Python ese arreglo es de
NumPy, y todo el ecosistema científico lo procesa sin copiarlo.

---

## 💻 3. El ejemplo que corre

`audio.py`:

```python
"""Audio: escribir y comprimir, medir el tono con librosa, procesar con pedalboard y pydub, y etiquetar con mutagen."""

import os
import subprocess
import time

import librosa
import mutagen
import numpy as np
import soundfile as sf
from pedalboard import Compressor, Gain, Pedalboard, Reverb
from pydub import AudioSegment, effects

RATE, SECONDS = 44_100, 10
t = np.arange(RATE * SECONDS) / RATE
tone = 0.1 * np.sin(2 * np.pi * 440 * t) + 0.01 * np.random.default_rng(1).standard_normal(t.size)   # La 440 con ruido
stereo = np.column_stack([tone, tone]).astype(np.float32)

# 1) Formatos: el mismo audio sin comprimir, sin pérdida y con pérdida
sf.write("muestra.wav", stereo, RATE, subtype="PCM_16")
sf.write("muestra.flac", stereo, RATE)
for codec, out in (("libmp3lame", "muestra.mp3"), ("libopus", "muestra.opus")):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", "muestra.wav", "-c:a", codec, "-b:a", "128k", out], check=True)
print(" · ".join(f"{f.split('.')[1]} {os.path.getsize(f) / 1024:,.0f} KB" for f in
                 ("muestra.wav", "muestra.flac", "muestra.mp3", "muestra.opus")))

# 2) librosa: qué nota es
y, sr = librosa.load("muestra.flac", sr=None, mono=True)
f0, voiced, _ = librosa.pyin(y[: sr * 2], fmin=100, fmax=1000, sr=sr)
print(f"librosa: frecuencia mediana {np.nanmedian(f0):.1f} Hz → {librosa.hz_to_note(np.nanmedian(f0))}")

# 3) Procesar: pedalboard (C++, sobre arreglos) contra pydub (Python, sobre muestras)
board = Pedalboard([Compressor(threshold_db=-25, ratio=4), Gain(gain_db=6), Reverb(room_size=0.3)])
start = time.perf_counter()
processed = board(stereo.T, RATE)
ms_pb = (time.perf_counter() - start) * 1000
segment = AudioSegment.from_wav("muestra.wav")
start = time.perf_counter()
normalized = effects.normalize(segment)
ms_pd = (time.perf_counter() - start) * 1000
print(f"pedalboard, compresor + ganancia + reverb: {ms_pb:5.1f} ms para {SECONDS} s de audio ({SECONDS * 1000 / ms_pb:,.0f}× tiempo real)")
print(f"pydub, normalizar: {ms_pd:5.1f} ms · pico antes {segment.max_dBFS:.1f} dBFS, después {normalized.max_dBFS:.1f} dBFS")

# 4) mutagen: etiquetas en FLAC y en MP3 con la misma interfaz
for path in ("muestra.flac", "muestra.mp3"):
    audio = mutagen.File(path, easy=True)
    audio["title"] = "Tono de prueba"; audio["artist"] = "Laboratorio de la carta"
    audio.save()
    again = mutagen.File(path, easy=True)
    print(f"{path}: {type(again).__name__} · {again['title'][0]} · {again.info.length:.2f} s · {again.info.sample_rate} Hz")
```

```bash
apt-get install ffmpeg
pip install pydub && python3 -c "import pydub" 2>&1 | tail -1      # en Python 3.14, sin más
pip install librosa mutagen soundfile pedalboard audioop-lts
python3 audio.py
python3 -c "import time; s=time.perf_counter(); import librosa, numpy as np; librosa.pyin(np.zeros(44100), fmin=100, fmax=1000, sr=44100); print(round(time.perf_counter()-s,2), 's hasta el primer pyin')"
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ModuleNotFoundError: No module named 'pyaudioop'
wav 1,723 KB · flac 585 KB · mp3 157 KB · opus 123 KB
librosa: frecuencia mediana 441.3 Hz → A4
pedalboard, compresor + ganancia + reverb:  17.8 ms para 10 s de audio (561× tiempo real)
pydub, normalizar:   1.2 ms · pico antes -16.5 dBFS, después -0.1 dBFS
muestra.flac: FLAC · Tono de prueba · 10.00 s · 44100 Hz
muestra.mp3: EasyMP3 · Tono de prueba · 10.03 s · 44100 Hz
4.5 s hasta el primer pyin
```

pydub **no importa** en Python 3.14: depende de `audioop`, que la biblioteca estándar quitó en 3.13 (PEP 594), y busca un reemplazo que no existe. El paquete
`audioop-lts`, mantenido por la comunidad, lo devuelve; con él, pydub normaliza en 1,2 ms. Los formatos: FLAC ocupa un tercio del WAV sin perder nada; MP3 y Opus a
128 kb/s, la décima parte. librosa reconoce el La 440 (441,3 Hz, A4). pedalboard procesa diez segundos con tres efectos en 17,8 ms, 561 veces más rápido que el
tiempo real. mutagen escribe y lee las etiquetas de FLAC y MP3 con la misma interfaz; el MP3 dura 10,03 s y no 10: el codificador agrega relleno al principio y al
final. Y la última línea: librosa tarda **4,5 segundos** en la primera llamada a `pyin`, aunque `import librosa` cueste milisegundos.

**Detalles con intención**

- **`import librosa`** es perezoso: no carga sus submódulos hasta que se usan. La primera llamada a `pyin` carga SciPy y **compila con numba** sus funciones internas
  (`ff04`): ese es el costo de 4,5 s.
- **`subtype="PCM_16"`** escribe el WAV en 16 bits, el formato de un CD; sin él, `soundfile` escribiría en el tipo del arreglo (32 bits flotantes), el doble de grande.
- **`board(stereo.T, RATE)`**: pedalboard espera los canales en la primera dimensión (`canales × muestras`); soundfile entrega `muestras × canales`. La traspuesta
  es la frontera entre las dos convenciones.
- **`mutagen.File(path, easy=True)`** usa nombres de etiqueta comunes (`title`, `artist`) para todos los formatos; sin `easy`, cada formato tiene los suyos (ID3 usa
  `TIT2`, `TPE1`).

---

## ⚠️ 4. Lo que se rompe

**pydub en Python 3.13 o posterior.** El tutorial de pydub falla en la primera línea. `audioop-lts` lo arregla hoy; la decisión de fondo es no apoyarse en un paquete
dormido: para cortar y unir, FFmpeg (`ar08`); para normalizar, pedalboard o NumPy.

**librosa en un CLI corto.** 4,5 s de arranque en cada ejecución. Se calienta una vez en un proceso que vive, o se usa el caché de numba.

**La frecuencia de muestreo que cambia sola.** `librosa.load` **remuestrea a 22.050 Hz** por defecto; sin `sr=None`, el audio de 44.100 Hz se convierte sin avisar.

**El orden de los canales.** `muestras × canales` contra `canales × muestras`: un arreglo al revés se procesa como 441.000 canales de dos muestras, o falla.

---

## ⚖️ 5. Cuándo NO usarlas

**Para convertir formatos.** El binario de FFmpeg; las bibliotecas que codifican MP3 desde Python lo llaman por debajo.

**librosa para un dato simple.** El volumen pico o la duración se calculan con NumPy y soundfile, sin 4,5 s de arranque.

**pydub en un proyecto nuevo.** Funciona con `audioop-lts`, pero es una dependencia dormida en el camino crítico.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las ocho líneas, y por qué pydub falló sin `audioop-lts`.
2. Carga `muestra.flac` con `librosa.load` sin `sr=None`. **Criterio:** la frecuencia de muestreo que devuelve y el nuevo largo del arreglo.
3. Lee las etiquetas del MP3 sin `easy=True`. **Criterio:** los nombres ID3 de título y artista.

**🟡 Intermedio (4–6)**

4. Normaliza el audio con NumPy (pico a −0,1 dBFS) sin pydub. **Criterio:** el mismo pico que pydub, y el tiempo.
5. Corta los segundos 2 a 5 con FFmpeg y con pydub. **Criterio:** la duración de cada uno, exacta al milisegundo.
6. Activa el caché de numba para librosa (`NUMBA_CACHE_DIR`) y repite la primera llamada a `pyin` en un proceso nuevo. **Criterio:** el tiempo de la segunda vez.

**🟠 Difícil (7–9)**

7. Normaliza la sonoridad a −16 LUFS con el filtro `loudnorm` de FFmpeg y con `pyloudnorm`. **Criterio:** las dos mediciones finales.
8. Procesa con pedalboard un archivo de una hora sin cargarlo entero (`AudioFile` en bloques). **Criterio:** la memoria máxima.
9. Detecta los silencios de una grabación de voz con librosa (`librosa.effects.split`). **Criterio:** los tramos con voz, comparados con los que escuchas.

**🔴 Muy difícil (10)**

10. Diseña el procesamiento de las grabaciones de un sistema (notas de voz que llegan en formatos variados). **Criterio:** una página. *Rúbrica:* (a) qué hace el binario y
    qué las bibliotecas; (b) cómo se normaliza el volumen; (c) qué etiquetas se escriben y cuáles se quitan; (d) los tiempos y el arranque medidos.

---

## 📚 7. Referencias

**Documentación oficial**

- librosa: https://librosa.org/doc/latest/
- pedalboard: https://spotify.github.io/pedalboard/
- mutagen: https://mutagen.readthedocs.io/en/latest/
- PEP 594, los módulos que salieron de la biblioteca estándar en 3.13: https://peps.python.org/pep-0594/

**Orden de lectura sugerido:** la PEP 594, para saber qué más se fue (`audioop`, `aifc`, `sunau`…); después la guía de inicio de librosa.

---

## 🚀 8. Cierre

El audio en Python son arreglos de NumPy y una biblioteca por tarea: soundfile para leer, librosa para analizar (con 4,5 s de arranque en la primera llamada), pedalboard para
efectos a 561 veces el tiempo real, mutagen para etiquetas. pydub, la más citada, no importa en 3.14 sin `audioop-lts`. Y los formatos con pérdida los codifica FFmpeg.

**La señal de que quedó bien:** *"Ninguna dependencia de audio está dormida en el camino crítico, y librosa se carga una vez en un proceso que vive."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-09 -m "op ar09 cerrada: audio con cinco bibliotecas, pydub sin audioop y librosa en frío"
> ```
>
> Los commits llevan su prefijo (`op ar09: …`) y los de ejercicio su número
> (`op ar09 ej07: …`).
