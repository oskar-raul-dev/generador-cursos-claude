# so06 — Cuando no hay modelo

Código de la sección [`op101-so06-cuando-no-hay-modelo.md`](../../op101-so06-cuando-no-hay-modelo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `recordatorios.py` | ¿Cuándo mandar los dos recordatorios? Caja negra con ruido: rejilla, SciPy y Optuna, contando evaluaciones |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add scipy optuna numpy

python3 recordatorios.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
