# ui02 — Gradio

Código de la sección [`op065-ui02-gradio.md`](../../op065-ui02-gradio.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `mora_app.py` | La calculadora de mora de Patricia, en Gradio: la pantalla y su API, que son lo mismo |
| `cliente.py` | La misma aplicación, usada desde un script: Gradio publica la API sin que nadie lo pida |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add gradio

python3 mora_app.py      # abre http://127.0.0.1:7860

python3 cliente.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
