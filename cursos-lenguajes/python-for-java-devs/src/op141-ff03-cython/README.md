# ff03 — Cython

Código de la sección [`op141-ff03-cython.md`](../../op141-ff03-cython.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `ema_v0.pyx` | Paso 0: el mismo código de Python, sin una sola anotación |
| `ema_v1.pyx` | Paso 1: tipos de C para los escalares |
| `ema_v2.pyx` | Paso 2: memoryviews tipadas; el bucle ya no toca objetos de Python |
| `ema_v3.pyx` | Paso 3: sin revisión de límites ni índices negativos |
| `medir.py` | El suavizado en Python y en cuatro pasos de Cython: tiempo, exactitud y cuánto Python queda en el cálculo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install cython setuptools   # setuptools: cythonize -i lo necesita desde que Python 3.12 quitó distutils
python3 medir.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
