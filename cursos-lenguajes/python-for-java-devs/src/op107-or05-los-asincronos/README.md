# or05 — Los ORM asíncronos

Código de la sección [`op107-or05-los-asincronos.md`](../../op107-or05-los-asincronos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `asincronos.py` | La relación que en síncrono se toca y en asíncrono se espera: SQLAlchemy AsyncSession y Tortoise ORM |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add "sqlalchemy[asyncio]" aiosqlite tortoise-orm

python3 asincronos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
