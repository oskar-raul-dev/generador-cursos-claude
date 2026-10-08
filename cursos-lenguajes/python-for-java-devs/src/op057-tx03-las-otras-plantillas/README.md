# tx03 — Las otras plantillas

Código de la sección [`op057-tx03-las-otras-plantillas.md`](../../op057-tx03-las-otras-plantillas.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `seis.py` | El mismo recordatorio en seis motores: qué escapa cada uno por defecto, y cuánto tarda |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add jinja2 django mako chameleon chevron

python3 seis.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
