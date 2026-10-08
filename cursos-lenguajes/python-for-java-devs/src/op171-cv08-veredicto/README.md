# cv08 — Veredicto ético y legal

Código de la sección [`op171-cv08-veredicto.md`](../../op171-cv08-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `salida_segura.py` | Un control de salida: nada se publica con un rostro reconocible ni con coordenadas GPS. Y desde qué pixelado deja de reconocerse |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opencv-python-headless==5.0.0.93 scikit-image==0.26.0 numpy==2.5.3 Pillow==12.3.0

uv run salida_segura.py; echo "código de salida: $?"
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
