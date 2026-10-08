# cv04 — Morphing desde cero

Código de la sección [`op167-cv04-morphing.md`](../../op167-cv04-morphing.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `morph.py` | Morphing desde cero: puntos, triangulación de Delaunay, una transformación afín por triángulo e interpolación |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opencv-python-headless==5.0.0.93 scipy==1.18.1 numpy==2.5.3

uv run morph.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
