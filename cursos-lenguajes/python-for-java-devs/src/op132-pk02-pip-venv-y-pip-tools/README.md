# pk02 — pip, venv y pip-tools

Código de la sección [`op132-pk02-pip-venv-y-pip-tools.md`](../../op132-pk02-pip-venv-y-pip-tools.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `fijar.sh` | — |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
python3 -m venv .venv && .venv/bin/pip install pip-tools

bash fijar.sh
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
