# ob02 — Bitácoras

Código de la sección [`op041-ob02-bitacoras.md`](../../op041-ob02-bitacoras.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `registro.py` | logging configurado de verdad: todo en JSON, con el request_id, también lo de las bibliotecas |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add structlog httpx

python3 registro.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
