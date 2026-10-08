# or01 — El eje: mapeo, constructor, SQL

Código de la sección [`op103-or01-el-eje.md`](../../op103-or01-el-eje.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `eje.py` | La misma consulta en los tres puntos del eje: SQL, constructor (PyPika, SQLAlchemy Core) y ORM |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add sqlalchemy pypika

python3 eje.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
