# au03 — Playwright y los portales sin API

Código de la sección [`op010-au03-playwright.md`](../../op010-au03-playwright.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `portal/index.html` | La página del ejemplo |
| `radicar.py` | Radica una factura y descarga las glosas en el portal de una aseguradora, con Playwright |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add playwright
uv run playwright install chromium

python3 -m http.server 8000 --directory portal --bind 127.0.0.1 &
PORTAL_USER=aurea PORTAL_PASSWORD=prueba python3 radicar.py

uv run playwright codegen https://www.portal-de-la-aseguradora.example/
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
