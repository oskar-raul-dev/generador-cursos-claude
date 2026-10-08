# ff02 — ctypes y cffi

Código de la sección [`op140-ff02-ctypes-y-cffi.md`](../../op140-ff02-ctypes-y-cffi.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `suavizado.c` | Suavizado exponencial: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1] |
| `frontera_c.py` | La misma función en Python y en C, llamada con ctypes y con cffi, y el primer segfault |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
pip install cffi                # y gcc: viene en la imagen python:3.14.7, no en la -slim
python3 frontera_c.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
