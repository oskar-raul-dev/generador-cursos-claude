# wf07 — Idempotencia, reanudación y *backfill*

Código de la sección [`op028-wf07-lo-transversal.md`](../../op028-wf07-lo-transversal.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `ejecuciones.py` | Ejecuciones con clave, arrendamiento y efectos idempotentes, sobre SQLite |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 ejecuciones.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
