# qa04 — Integración de verdad con `testcontainers`

Código de la sección [`op033-qa04-integracion-de-verdad.md`](../../op033-qa04-integracion-de-verdad.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `esquema.sql` | Script SQL del ejemplo |
| `conftest.py` | Un PostgreSQL de verdad por sesión, el esquema de producción, y una transacción por prueba |
| `test_liquidaciones_db.py` | Lo que SQLite deja pasar y PostgreSQL no: la prueba tiene que correr contra el motor real |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add sqlalchemy "psycopg[binary]"
uv add --dev pytest "testcontainers[postgres]"

pytest -q test_liquidaciones_db.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
