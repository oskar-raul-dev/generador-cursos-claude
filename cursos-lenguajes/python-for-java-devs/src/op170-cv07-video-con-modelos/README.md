# cv07 — Vídeo con modelos

Código de la sección [`op170-cv07-video-con-modelos.md`](../../op170-cv07-video-con-modelos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `video.py` | Vídeo con modelos: detectar en cada cuadro, detectar cada N y seguir, y estabilizar; todo contra una verdad conocida |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opencv-contrib-python-headless==5.0.0.93 scikit-image==0.26.0 numpy==2.5.3

uv run video.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
