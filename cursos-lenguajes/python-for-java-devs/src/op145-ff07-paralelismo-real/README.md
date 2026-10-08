# ff07 — Paralelismo real: subintérpretes y sin GIL

Código de la sección [`op145-ff07-paralelismo-real.md`](../../op145-ff07-paralelismo-real.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `paralelo.py` | Cuatro tareas de Python puro: secuencial, hilos, procesos y subintérpretes, con y sin GIL |
| `rompe.py` | Lo que se rompe: una extensión que no declara soporte sin GIL, y NumPy dentro de un subintérprete |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install uv
python3 paralelo.py                                            # el CPython de siempre, con GIL
uv python install 3.14.7t
uv run -p 3.14.7t --no-project python paralelo.py              # la compilación sin GIL
uv venv -p 3.14.7t /tmp/ft && uv pip install -p /tmp/ft/bin/python cython setuptools numpy
/tmp/ft/bin/python rompe.py                                    # con ema_v3.pyx en la carpeta
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
