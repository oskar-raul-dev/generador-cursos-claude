# ff04 — numba

Código de la sección [`op142-ff04-numba.md`](../../op142-ff04-numba.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `jit.py` | numba sobre el suavizado: el costo de compilar, el caché en disco, prange y lo que no compila |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install numba
python3 -X importtime -c "import numba" 2>&1 | tail -1
python3 jit.py                                   # la primera vez: compila
python3 jit.py | head -1                         # la segunda: lee el caché de __pycache__
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
