# cv01 — El modelo: píxeles, características, red

Código de la sección [`op164-cv01-el-modelo.md`](../../op164-cv01-el-modelo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `tres_niveles.py` | El mismo problema en tres niveles: encontrar rostros con una regla de píxeles, con características (Haar) y con una red (YuNet) |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opencv-contrib-python-headless==5.0.0.93 scikit-image==0.26.0 numpy==2.5.3

uv run tres_niveles.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
