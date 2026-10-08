# ar09 — Audio

Código de la sección [`op155-ar09-audio.md`](../../op155-ar09-audio.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `audio.py` | Audio: escribir y comprimir, medir el tono con librosa, procesar con pedalboard y pydub, y etiquetar con mutagen |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install ffmpeg
pip install pydub && python3 -c "import pydub" 2>&1 | tail -1      # en Python 3.14, sin más
pip install librosa mutagen soundfile pedalboard audioop-lts
python3 audio.py
python3 -c "import time; s=time.perf_counter(); import librosa, numpy as np; librosa.pyin(np.zeros(44100), fmin=100, fmax=1000, sr=44100); print(round(time.perf_counter()-s,2), 's hasta el primer pyin')"
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
