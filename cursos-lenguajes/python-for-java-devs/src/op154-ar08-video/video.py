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
