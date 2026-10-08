# tx02 — Jinja2 a fondo

Código de la sección [`op056-tx02-jinja2-a-fondo.md`](../../op056-tx02-jinja2-a-fondo.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `reporte.py` | El reporte mensual de cartera: herencia, macro, filtro propio y StrictUndefined |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add jinja2

python3 reporte.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
