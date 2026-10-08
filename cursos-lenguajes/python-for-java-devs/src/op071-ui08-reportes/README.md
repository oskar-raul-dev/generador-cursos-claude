# ui08 — Reportes: HTML, PDF y Excel

Código de la sección [`op071-ui08-reportes.md`](../../op071-ui08-reportes.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `reporte_mensual.py` | El reporte mensual de cartera en PDF (WeasyPrint) y en Excel que suma (XlsxWriter) |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
sudo apt-get install -y libpango-1.0-0 libpangoft2-1.0-0
uv add weasyprint xlsxwriter jinja2 openpyxl

python3 reporte_mensual.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
