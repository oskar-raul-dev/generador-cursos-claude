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
