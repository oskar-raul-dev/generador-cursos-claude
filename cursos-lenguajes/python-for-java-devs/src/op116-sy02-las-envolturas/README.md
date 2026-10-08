# sy02 — Las envolturas: plumbum, sh, invoke

Código de la sección [`op116-sy02-las-envolturas.md`](../../op116-sy02-las-envolturas.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `envolturas.py` | La misma tubería en subprocess, plumbum y sh; qué hace cada una ante un error; y cuánto cuesta el azúcar |
| `tasks.py` | — |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add plumbum sh invoke

python3 envolturas.py
invoke --list
invoke respaldo
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
