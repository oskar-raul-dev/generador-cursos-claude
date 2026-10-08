# or02 — SQLAlchemy a fondo

Código de la sección [`op104-or02-sqlalchemy-a-fondo.md`](../../op104-or02-sqlalchemy-a-fondo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `a_fondo.py` | SQLAlchemy 2.1: estrategias de carga contadas, hybrid_property en Python y en SQL, y un tipo Pesos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add sqlalchemy

python3 a_fondo.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
