# ar08 — Vídeo

Código de la sección [`op154-ar08-video.md`](../../op154-ar08-video.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `video.py` | Vídeo: el binario de ffmpeg contra PyAV y MoviePy en el mismo trabajo, y el corte que no cae donde se pidió |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
apt-get install ffmpeg          # FFmpeg 7.1.5 de Debian en el contenedor
pip install av moviepy
python3 video.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
