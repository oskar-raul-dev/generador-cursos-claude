# or07 — Migraciones fuera de Alembic

Código de la sección [`op109-or07-migraciones.md`](../../op109-or07-migraciones.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `0001_planes.sql` | depends: |
| `0001_planes.rollback.sql` | Script SQL del ejemplo |
| `0002_fases.sql` | depends: 0001_planes |
| `0002_fases.rollback.sql` | Script SQL del ejemplo |
| `migrar.py` | Aplicar, revertir y volver a aplicar con yoyo, y lo que pasa al editar una migración ya aplicada |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add yoyo-migrations

python3 migrar.py
yoyo list --database sqlite:///aurea.db migraciones
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
