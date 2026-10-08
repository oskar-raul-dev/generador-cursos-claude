# cv06 — Segmentación y edición

Código de la sección [`op169-cv06-segmentacion-y-edicion.md`](../../op169-cv06-segmentacion-y-edicion.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `edicion.py` | Segmentar, borrar y agrandar: dos recortadores de fondo, dos rellenos y una superresolución, medidos contra la verdad |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opencv-contrib-python-headless==5.0.0.93 mediapipe==1.1.0 rembg==2.0.85 onnxruntime==1.30.0 scikit-image==0.26.0 numpy==2.5.3

uv run edicion.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
