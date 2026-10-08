# co05 — Transferencia de archivos

Código de la sección [`op019-co05-transferencia-de-archivos.md`](../../op019-co05-transferencia-de-archivos.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `descargar_pagos.py` | Baja las relaciones de pago del SFTP de la aseguradora, solo las completas y solo una vez |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add paramiko

python3 descargar_pagos.py 127.0.0.1 2222
python3 descargar_pagos.py 127.0.0.1 2222   # la segunda vez no baja nada
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
