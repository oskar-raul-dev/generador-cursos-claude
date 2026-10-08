# ob06 — Errores como producto

Código de la sección [`op045-ob06-errores-como-producto.md`](../../op045-ob06-errores-como-producto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `errores.py` | Captura de errores con sentry-sdk: agrupación, versión y la frontera de datos en before_send |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add sentry-sdk

python3 errores.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
