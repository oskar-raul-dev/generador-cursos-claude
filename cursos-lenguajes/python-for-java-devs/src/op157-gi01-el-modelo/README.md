# gi01 — El modelo: geometría, proyección, topología

Código de la sección [`op157-gi01-el-modelo.md`](../../op157-gi01-el-modelo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `modelo.py` | Geometría, proyección y topología con las diez sedes de Áurea: tres maneras de medir y dos de equivocarse |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add shapely==2.1.2 pyproj==3.8.0

uv run modelo.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
