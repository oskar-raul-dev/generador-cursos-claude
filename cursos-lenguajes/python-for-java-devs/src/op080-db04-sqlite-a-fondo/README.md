# db04 — SQLite a fondo

Código de la sección [`op080-db04-sqlite-a-fondo.md`](../../op080-db04-sqlite-a-fondo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `sqlite_trampas.py` | Las tres trampas de SQLite por defecto, y la línea que corrige cada una |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 sqlite_trampas.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
