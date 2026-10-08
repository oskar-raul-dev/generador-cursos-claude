# tx01 — El eje: concatenar, formatear, plantilla, árbol

Código de la sección [`op055-tx01-el-eje.md`](../../op055-tx01-el-eje.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `eje.py` | El mismo recordatorio de cita, de cuatro formas, con datos que rompen el HTML |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add jinja2 htpy

python3 eje.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
