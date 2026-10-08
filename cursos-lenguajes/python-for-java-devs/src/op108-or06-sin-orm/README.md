# or06 — Sin ORM

Código de la sección [`op108-or06-sin-orm.md`](../../op108-or06-sin-orm.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `cartera.sql` | name: crear_tablas# |
| `reporte.py` | El reporte desde SQL en archivos (aiosql) y el mismo SQL analizado y traducido (sqlglot) |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add aiosql sqlglot

python3 reporte.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
