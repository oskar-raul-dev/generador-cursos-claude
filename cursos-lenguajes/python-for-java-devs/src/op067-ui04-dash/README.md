# ui04 — Dash y los callbacks

Código de la sección [`op067-ui04-dash.md`](../../op067-ui04-dash.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `tablero.py` | El tablero de cartera en Dash: un callback declarado, y el servidor sin estado |
| `prueba_tablero.py` | El callback es una función, y la interacción es un POST sin sesión |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add dash

python3 tablero.py      # http://127.0.0.1:8050

python3 prueba_tablero.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
