# 🧪 qa09 — Pruebas e2e con Playwright

> Python para desarrolladores Java senior · **Carta** · Track `qa` — Calidad, pruebas y
> mantenimiento · sección 9 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta. Si leíste [`au03`](op010-au03-playwright.md),
> ya conoces Playwright desde el lado de automatizar sistemas ajenos; aquí prueba el propio.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La historia de Áurea pide pruebas de punta a punta del **sitio de reservas**: la página donde un paciente
elige sede, ve los espacios libres y reserva. Es la parte del sistema que más gente toca y la que nadie del
equipo usa a diario, así que un error ahí se descubre por las quejas, no por las pruebas.

Las pruebas e2e son las más caras de la pirámide —lentas, frágiles, con un navegador de por medio— y por
eso el mapa de riesgo de `qa01` las reserva para pocos caminos y muy importantes. **Reservar una cita es uno
de esos caminos.** Esta sección escribe esa prueba con **`pytest-playwright`** (0.9.0), el *plugin* que
integra Playwright con `pytest`: una fixture `page` por prueba, un navegador que se reutiliza, y rastros
guardados cuando algo falla.

---

## 🧠 2. El modelo

`pytest-playwright` agrega a `pytest` lo que una prueba de navegador necesita sin escribirlo:

| Fixture u opción | Qué da | Por qué importa |
|---|---|---|
| `page` | Una pestaña nueva y limpia para cada prueba | Aislamiento: ninguna prueba ve las cookies de otra |
| `--base-url` | La URL del sitio, una vez | `page.goto("/reservar")` funciona contra local, staging o producción |
| `--browser` | Chromium, Firefox o WebKit | El mismo código, otro motor |
| `--tracing retain-on-failure` | Guarda el rastro solo de las que fallan | El rastro es lo único que explica un fallo del CI |

Y las dos reglas de Playwright que hacen que una prueba e2e no sea frágil, las mismas que en `au03`:
**localizadores por rol y etiqueta** —lo que ve el paciente— y **ninguna espera escrita a mano**:
`expect(...)` espera y verifica a la vez.

La diferencia con `au03` es de propósito. Allá, si el portal cambia, el robot se adapta. Aquí, si el sitio
cambia y la prueba falla, **la prueba tiene razón** hasta que alguien decida lo contrario: es la
especificación de lo que el paciente puede hacer.

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo de Selenium en Java es escribir una prueba e2e por cada historia de usuario, con su `PageObject`
y sus esperas, hasta tener cientos. Esas suites tardan una hora y fallan por razones de tiempo un 5% de las
veces, y el equipo aprende a ignorarlas. Para un equipo de uno, **tres o cuatro caminos críticos**, rápidos y
estables, valen más que cien que nadie mira.

---

## 💻 3. El ejemplo que corre

```bash
uv add fastapi uvicorn python-multipart
uv add --dev pytest pytest-playwright
uv run playwright install chromium
```

`python-multipart` no es opcional: sin él, el primer formulario que recibe FastAPI falla con
`RuntimeError: Form data requires "python-multipart" to be installed.` FastAPI no lo instala solo,
porque no todas las API reciben formularios.

`sitio.py`, el sitio de reservas reducido a lo esencial:

```python
"""El sitio de reservas, mínimo: elegir sede, ver espacios y reservar."""

from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse

app = FastAPI()
FREE = {"Centro": ["08:00", "15:40"], "Suba": ["09:20"]}


@app.get("/reservar", response_class=HTMLResponse)
def form() -> str:
    options = "".join(f"<option>{s}</option>" for s in FREE)
    return f"""<!doctype html><html lang="es"><body>
      <h1>Reservar una cita</h1>
      <form method="post" action="/reservar">
        <label>Sede <select name="sede">{options}</select></label>
        <label>Documento <input name="documento" required></label>
        <button type="submit">Ver espacios</button>
      </form></body></html>"""


@app.post("/reservar", response_class=HTMLResponse)
def slots(sede: str = Form(), documento: str = Form()) -> str:
    buttons = "".join(f'<button name="hora" value="{h}">{h}</button>' for h in FREE[sede])
    return f"""<!doctype html><html lang="es"><body>
      <h1>Espacios en {sede}</h1>
      <form method="post" action="/confirmar">
        <input type="hidden" name="sede" value="{sede}">{buttons}
      </form></body></html>"""


@app.post("/confirmar", response_class=HTMLResponse)
def confirm(sede: str = Form(), hora: str = Form()) -> str:
    return f'<!doctype html><html lang="es"><body><p role="status">Cita confirmada: {sede}, {hora}</p></body></html>'
```

`conftest.py` arranca el sitio una vez por sesión:

```python
"""Levanta el sitio en un hilo para la sesión de pruebas."""

import threading
import time

import pytest
import uvicorn

from sitio import app


@pytest.fixture(scope="session", autouse=True)
def site():
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=8765, log_level="warning"))
    thread = threading.Thread(target=server.run, daemon=True)
    thread.start()
    while not server.started:
        time.sleep(0.05)
    yield
    server.should_exit = True
    thread.join()
```

`test_reserva_e2e.py`, el camino crítico:

```python
"""El camino que no puede romperse: un paciente reserva en el Centro a las 15:40."""

import re

from playwright.sync_api import Page, expect


def test_patient_books_an_appointment(page: Page):
    page.goto("/reservar")
    page.get_by_label("Sede").select_option("Centro")
    page.get_by_label("Documento").fill("1023456789")
    page.get_by_role("button", name="Ver espacios").click()

    expect(page.get_by_role("heading", name=re.compile("Espacios en Centro"))).to_be_visible()
    page.get_by_role("button", name="15:40").click()

    expect(page.get_by_role("status")).to_have_text("Cita confirmada: Centro, 15:40")


def test_document_is_required(page: Page):
    page.goto("/reservar")
    page.get_by_role("button", name="Ver espacios").click()
    # El navegador no envía el formulario: seguimos en la misma página.
    expect(page.get_by_role("heading", name="Reservar una cita")).to_be_visible()
```

```bash
pytest -q --base-url http://127.0.0.1:8765 --tracing retain-on-failure test_reserva_e2e.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
..                                                                       [100%]
2 passed in 0.93s
```

Si una de las dos falla, `test-results/` guarda su rastro, y `playwright show-trace` lo abre con una
captura por paso.

**Detalles con intención**

- **La prueba describe lo que hace el paciente**, en el orden en que lo hace, con lo que ve: la etiqueta
  "Sede", el botón "Ver espacios", la hora "15:40". Se lee como el caso de uso.
- **`--base-url`** separa la prueba del entorno: la misma prueba corre contra la máquina local, contra un
  entorno de pruebas o, con cuidado, contra producción.
- **`role="status"`** en la confirmación hace que la prueba la encuentre por su función, y de paso hace el
  sitio más accesible para un lector de pantalla. Las pruebas por rol empujan en esa dirección.
- **La segunda prueba verifica una regla del navegador** (`required`): es barata y atrapa el día en que
  alguien quite el atributo.

---

## ⚠️ 4. Lo que se rompe

**Los datos compartidos entre pruebas e2e.** Si la prueba reserva el espacio de las 15:40 de verdad, la
siguiente corrida no lo encuentra libre. Las pruebas e2e necesitan datos propios —una base que se reinicia,
un paciente de prueba, un espacio que se libera al final— o se vuelven dependientes del orden.

**Las pruebas que pasan en local y fallan en el CI.** El CI corre sin pantalla, con menos CPU y a veces con
otra zona horaria o configuración regional. Las esperas automáticas de Playwright cubren la mayor parte; lo
que queda suele ser una fecha formateada distinto o un servicio que tarda más en arrancar.

**Probar lo que no es del navegador.** Una prueba e2e que verifica el cálculo de un precio repite lo que una
unitaria hace en milisegundos. La e2e verifica que el **camino** funciona; los números se prueban abajo.

---

## ⚖️ 5. Cuándo NO usarla

**Para cada pantalla del back-office.** El mapa de riesgo de `qa01` las deja casi sin pruebas
automatizadas: cambian seguido y Patricia avisa.

**Cuando una prueba de la API basta.** Si la lógica de la reserva está en la API, probar la API con `httpx`
cubre el 90% con una fracción del costo. La e2e queda para el camino completo, una vez.

**Como prueba de carga.** Un navegador por usuario simulado es carísimo; la carga se mide con `qa07`.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Cambia el texto del botón "Ver espacios" en el sitio. **Criterio:** la prueba falla, y el mensaje dice
   qué botón buscaba.
2. Corre la suite con `--browser firefox` y `--browser webkit`. **Criterio:** las dos pasan, o explicas la
   diferencia.
3. Haz fallar la confirmación y abre el rastro guardado. **Criterio:** describes qué muestra el rastro en el
   paso que falló.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de `pytest-playwright` cómo se cambia el tamaño de la ventana para probar el
   sitio en un teléfono. **Criterio:** la prueba corre con la vista de un teléfono y pasa.
5. Agrega una prueba para una sede sin espacios libres. **Criterio:** el sitio muestra un mensaje y la
   prueba lo verifica por su rol.
6. Mueve los pasos repetidos a un *Page Object* `ReservationPage`. **Criterio:** las pruebas se leen igual
   y los localizadores viven en un solo lugar.

**🟠 Difícil (7–9)**

7. Haz que el sitio guarde las reservas en SQLite y que la prueba use una base propia que se reinicia por
   prueba. **Criterio:** correr la suite dos veces seguidas pasa las dos veces.
8. Lleva la suite al CI con el navegador en caché entre corridas. **Criterio:** el tiempo de instalación del
   navegador baja en la segunda corrida del CI.
9. Corre cada prueba 50 veces (`pytest-repeat` o un bucle) y cuenta los fallos intermitentes. **Criterio:**
   cero, o encuentras la causa de cada uno y la arreglas sin agregar esperas fijas.

**🔴 Muy difícil (10)**

10. Define los caminos críticos del sitio de reservas y escribe sus pruebas e2e. **Criterio:** no más de
    cinco pruebas. *Rúbrica:* (a) cada camino justifica por qué está y qué cuesta que falle; (b) la suite
    tarda menos de un minuto; (c) cero fallos intermitentes en 50 corridas; (d) dices qué caminos dejaste
    fuera y cómo se cubren de otra forma.

---

## 📚 7. Referencias

**Documentación oficial**

- `pytest-playwright`: https://playwright.dev/python/docs/test-runners
- Aserciones con `expect`: https://playwright.dev/python/docs/test-assertions
- Escribir pruebas: https://playwright.dev/python/docs/writing-tests
- Buenas prácticas (la página está en la documentación general, con ejemplos en JavaScript; las reglas
  valen igual): https://playwright.dev/docs/best-practices

**Orden de lectura sugerido:** la página de buenas prácticas, que resume en una pantalla todo lo que hace a
una prueba e2e estable; después la del *runner* de `pytest`.

---

## 🚀 8. Cierre

Las pruebas e2e son pocas y sobre caminos críticos: se escriben como lo que hace el paciente, con
localizadores por rol y sin esperas a mano, guardan su rastro cuando fallan, y corren contra la URL que les
digas. Si una falla, tiene razón hasta que alguien decida lo contrario.

**La señal de que quedó bien:** *"Alguien quitó el `required` del documento y la prueba de reservas lo
atrapó antes de que los pacientes empezaran a reservar sin identificarse."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-qa-fase-09 -m "op qa09 cerrada: el camino de la reserva con pytest-playwright"
> ```
>
> Los commits llevan su prefijo (`op qa09: …`) y los de ejercicio su número
> (`op qa09 ej07: …`).
