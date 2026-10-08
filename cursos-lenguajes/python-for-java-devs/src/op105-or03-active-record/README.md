# or03 — Active Record: Django ORM, Peewee, Piccolo

Código de la sección [`op105-or03-active-record.md`](../../op105-or03-active-record.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `perdida.py` | Dos objetos del mismo plan, dos cambios distintos: Peewee y Django pierden uno; SQLAlchemy no |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add peewee django sqlalchemy

python3 perdida.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
