# qa09 — Pruebas e2e con Playwright

Código de la sección [`op038-qa09-e2e-con-playwright.md`](../../op038-qa09-e2e-con-playwright.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `sitio.py` | El sitio de reservas, mínimo: elegir sede, ver espacios y reservar |
| `conftest.py` | Levanta el sitio en un hilo para la sesión de pruebas |
| `test_reserva_e2e.py` | El camino que no puede romperse: un paciente reserva en el Centro a las 15:40 |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add fastapi uvicorn python-multipart
uv add --dev pytest pytest-playwright
uv run playwright install chromium

pytest -q --base-url http://127.0.0.1:8765 --tracing retain-on-failure test_reserva_e2e.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
