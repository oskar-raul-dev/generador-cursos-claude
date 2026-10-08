# so03 — OR-Tools y CP-SAT

Código de la sección [`op098-so03-or-tools.md`](../../op098-so03-or-tools.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `turnos.py` | Los turnos de recepción de una semana con CP-SAT: reglas duras, preferencias y equidad |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add ortools

python3 turnos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
