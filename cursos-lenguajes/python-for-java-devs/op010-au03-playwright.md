# 🤖 au03 — Playwright y los portales sin API

> Python para desarrolladores Java senior · **Carta** · Track `au` — Automatización externa ·
> sección 3 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Lo dice la historia de Áurea sin inventar nada: **los portales de las aseguradoras no tienen API**.
Radicar una factura es entrar a un sitio web, escribir usuario y contraseña, ir a "Radicación",
subir el PDF y el XML, esperar el número de radicado y anotarlo. Descargar las glosas de la semana
es entrar otra vez, ir a "Consultas", filtrar por fechas y hacer clic en "Exportar". Con diez sedes
y cinco aseguradoras, alguien pasa medio día a la semana haciendo clic.

Ese es el caso para el que existe la automatización de navegador: no hay otra interfaz, el sitio
**es** la interfaz, y lo que hace falta es un programa que haga los mismos clics que una persona.
**Playwright** (1.63.0, del 2026-09-15) es la herramienta de este oficio hoy: maneja Chromium,
Firefox y WebKit reales, espera solo a que los elementos estén listos, y trae un grabador que
escribe el primer borrador del script mientras tú navegas.

---

## 🧠 2. El modelo

Playwright controla un navegador real a través de un protocolo, y expone tres niveles:

- **El navegador** (`browser`), un proceso de Chromium, Firefox o WebKit.
- **El contexto** (`context`), una sesión aislada: sus propias cookies, su almacenamiento, sus
  descargas. Es lo que hace que dos aseguradoras no compartan sesión dentro del mismo navegador.
- **La página** (`page`), una pestaña.

Lo que lo separa de las herramientas anteriores son dos ideas:

**Los localizadores se anclan en lo que ve una persona.** `page.get_by_label("Usuario")`,
`page.get_by_role("button", name="Radicar")`. Un portal cambia sus `id` y sus clases en cada
despliegue; la etiqueta "Usuario" y el botón "Radicar" cambian mucho menos, porque son para humanos.

**La espera es automática.** Cada acción espera a que el elemento exista, sea visible, esté
habilitado y deje de moverse, hasta un tiempo límite. El `sleep(3)` "para que cargue", que es la
causa número uno de automatizaciones frágiles, desaparece.

### Tu instinto de Java dice… y esta vez se equivoca

Si automatizaste navegadores en Java, fue con Selenium y `WebDriverWait`, con selectores XPath
copiados de las herramientas del navegador. El reflejo es traer ese estilo: XPath largos y esperas
explícitas en cada paso. Playwright existe también para Java, con la misma API, y el estilo correcto
es el contrario en los dos lenguajes: **localizadores por rol y etiqueta, y ninguna espera escrita a
mano** salvo la de un evento concreto (una descarga, una navegación).

### Esto sí funciona igual

El modelo de página es el mismo de cualquier prueba de interfaz: el patrón *Page Object* —una clase
por pantalla con métodos que dicen lo que hace la persona— se traslada sin cambios, y es lo que
mantiene legible una automatización de cinco portales.

---

## 💻 3. El ejemplo que corre

```bash
uv add playwright
uv run playwright install chromium
```

El segundo comando descarga el navegador (unos cientos de MB) a una caché del usuario; no instala
nada en el sistema. En Linux, `playwright install --with-deps chromium` agrega además las
bibliotecas del sistema que el navegador necesita.

### El portal falso

`portal/index.html` imita lo esencial de un portal de radicación —formulario de ingreso, un panel,
una carga de archivos y una descarga— para que el ejemplo corra sin una aseguradora real:

```html
<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Portal de prestadores</title></head>
<body>
  <form id="login">
    <label>Usuario <input name="user"></label>
    <label>Contraseña <input name="password" type="password"></label>
    <button type="submit">Ingresar</button>
  </form>
  <main id="panel" hidden>
    <h1>Radicación de facturas</h1>
    <label>Factura (PDF) <input type="file" name="factura"></label>
    <button id="radicar">Radicar</button>
    <p id="resultado" role="status"></p>
    <a href="glosas.csv" download>Exportar glosas</a>
  </main>
  <script>
    document.getElementById("login").addEventListener("submit", (e) => {
      e.preventDefault();
      // El portal real tarda en responder; aquí también, para que la espera automática se note.
      setTimeout(() => { e.target.hidden = true; document.getElementById("panel").hidden = false; }, 800);
    });
    document.getElementById("radicar").addEventListener("click", () => {
      const f = document.querySelector("input[name=factura]").files[0];
      const out = document.getElementById("resultado");
      out.textContent = f ? `Radicado RAD-2026-004512 para ${f.name}` : "Debe adjuntar la factura";
    });
  </script>
</body></html>
```

`portal/glosas.csv`:

```text
factura;codigo;valor
FE-000123;1102;185000
```

### El robot

`radicar.py`:

```python
"""Radica una factura y descarga las glosas en el portal de una aseguradora, con Playwright."""

import os
import re
from pathlib import Path

from playwright.sync_api import Page, expect, sync_playwright

PORTAL_URL = os.environ.get("PORTAL_URL", "http://127.0.0.1:8000/index.html")


class ProviderPortal:
    """Page Object: un método por cosa que hace la persona, sin selectores fuera de aquí."""

    def __init__(self, page: Page):
        self.page = page

    def log_in(self, user: str, password: str) -> None:
        self.page.goto(PORTAL_URL)
        self.page.get_by_label("Usuario").fill(user)
        self.page.get_by_label("Contraseña").fill(password)
        self.page.get_by_role("button", name="Ingresar").click()
        # La única espera explícita: que aparezca el panel. Sin sleep.
        expect(self.page.get_by_role("heading", name="Radicación de facturas")).to_be_visible()

    def file_invoice(self, pdf: Path) -> str:
        self.page.get_by_label("Factura (PDF)").set_input_files(pdf)
        self.page.get_by_role("button", name="Radicar").click()
        status = self.page.get_by_role("status")
        expect(status).to_contain_text("Radicado")
        match = re.search(r"RAD-\d{4}-\d+", status.inner_text())
        if not match:
            raise RuntimeError(f"el portal no devolvió número de radicado: {status.inner_text()!r}")
        return match.group(0)

    def download_objections(self, target_dir: Path) -> Path:
        with self.page.expect_download() as info:
            self.page.get_by_role("link", name="Exportar glosas").click()
        download = info.value
        target = target_dir / download.suggested_filename
        download.save_as(target)
        return target


def main() -> None:
    user, password = os.environ["PORTAL_USER"], os.environ["PORTAL_PASSWORD"]
    invoice = Path("FE-000123.pdf")
    invoice.write_bytes(b"%PDF-1.4\n% factura de prueba\n")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(accept_downloads=True)
        context.tracing.start(screenshots=True, snapshots=True)
        page = context.new_page()
        portal = ProviderPortal(page)
        try:
            portal.log_in(user, password)
            print("radicado:", portal.file_invoice(invoice))
            print("glosas en:", portal.download_objections(Path(".")))
        finally:
            # El rastro se guarda siempre: cuando falla en la madrugada, es lo único que hay.
            context.tracing.stop(path="rastro.zip")
            browser.close()


if __name__ == "__main__":
    main()
```

```bash
python3 -m http.server 8000 --directory portal --bind 127.0.0.1 &
PORTAL_USER=aurea PORTAL_PASSWORD=prueba python3 radicar.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
radicado: RAD-2026-004512
glosas en: glosas.csv
```

Y si algo falla, `playwright show-trace rastro.zip` abre una línea de tiempo con una captura de
pantalla por acción, el DOM de cada momento y la red. Es la herramienta que convierte "el robot
falló anoche" en "falló en el clic de Radicar porque el botón decía Enviar".

**Detalles con intención**

- **Ni un selector CSS ni un XPath.** Todo se localiza por etiqueta, rol y nombre visible, que es lo
  que el portal cambia menos.
- **El `Page Object` es la frontera.** El día que la aseguradora cambie el texto del botón, se
  toca un método, y el resto del proceso no se entera.
- **Las credenciales llegan por entorno**, nunca en el código, y el rastro se guarda fuera del
  repositorio: puede contener capturas con datos.
- **`expect(...)` espera y verifica a la vez.** `to_contain_text("Radicado")` reintenta hasta que
  el texto aparece o vence el tiempo, y en ese caso falla con el texto que sí había.

### Grabar el primer borrador

```bash
uv run playwright codegen https://www.portal-de-la-aseguradora.example/
```

Abre un navegador y escribe el script mientras navegas. El resultado es un **borrador**: se lleva al
`Page Object`, se le quitan los selectores frágiles que el grabador no pudo evitar, y se le agrega
la verificación de cada paso.

---

## ⚠️ 4. Lo que se rompe

**El CAPTCHA y el segundo factor.** Muchos portales los tienen precisamente para impedir esto. Un
CAPTCHA no se resuelve: se le pide a la aseguradora una excepción para el prestador, o se deja ese
paso a una persona. Un segundo factor por correo o SMS se puede automatizar leyendo el buzón, y es
una decisión de seguridad que hay que tomar por escrito.

**La sesión de cada mañana.** Ingresar en cada corrida es lento y, para algunos portales, sospechoso.
`context.storage_state(path="sesion.json")` guarda las cookies y el almacenamiento, y
`browser.new_context(storage_state="sesion.json")` los reutiliza. Ese archivo **es** la sesión: se
trata como una contraseña.

**Los términos de uso.** Automatizar un portal que lo prohíbe expresamente puede costar el acceso del
prestador. Antes de escribir el robot se leen los términos y, si hay duda, se pregunta: muchas
aseguradoras prefieren un robot bien comportado a una persona que exporta lo mismo a mano.

**El robot que confirma lo que no pasó.** Si el portal muestra "Radicado" pero el número no aparece,
el robot no debe darlo por radicado. Por eso `file_invoice` exige el número con su formato, y si no
está, falla.

---

## ⚖️ 5. Cuándo NO usarla

**Cuando hay una API, aunque sea fea.** Un navegador consume cientos de MB de memoria y es diez o cien
veces más lento que la petición equivalente. Si el portal habla con su propio servidor por una API
interna, a veces se puede llamar directamente (`au02` explica cómo encontrarla) —con el mismo
cuidado con los términos—.

**Cuando la pantalla cambia cada semana.** Un robot sobre un portal inestable cuesta más en
mantenimiento que la media jornada que ahorra. La cuenta se hace con números: horas de clics ahorradas
al mes contra horas de arreglos.

**Para hacer pruebas de tu propio sitio.** Es la misma herramienta y otro oficio, con otras reglas:
está en el track `qa`.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el robot sin adjuntar el PDF (comenta `set_input_files`). **Criterio:** falla con un
   mensaje que dice qué texto tenía el estado, no con un tiempo agotado mudo.
2. Abre `rastro.zip` con `playwright show-trace` y localiza la captura del clic en "Radicar".
   **Criterio:** describes en una línea qué muestra la línea de tiempo en ese paso.
3. Cambia `headless=True` por `False` y `slow_mo=500`. **Criterio:** ves el navegador hacer cada
   paso, y explicas para qué sirve `slow_mo` al depurar.

**🟡 Intermedio (4–6)**

4. Guarda la sesión con `storage_state` y haz que la segunda corrida no pase por el formulario de
   ingreso. **Criterio:** la segunda corrida no llama a `log_in` y radica igual.
5. Busca en la documentación de Playwright la diferencia entre `get_by_role`, `get_by_label`,
   `get_by_text` y `locator`. **Criterio:** una tabla con cuándo usar cada uno en un portal.
6. Cambia en el portal el texto del botón "Radicar" por "Enviar". **Criterio:** tocas una sola
   línea del robot y vuelve a funcionar; explicas por qué no hizo falta más.

**🟠 Difícil (7–9)**

7. Radica un lote de diez facturas en la misma sesión, y si una falla, sigue con las demás y deja
   un informe. **Criterio:** con una factura sin PDF, el informe dice nueve radicadas con su número
   y una fallida con su razón.
8. Haz que el robot detecte que ya radicó una factura (por número de factura) y no la vuelva a
   radicar si se relanza a la mitad. **Criterio:** relanzar después de cinco facturas radica solo
   las cinco restantes.
9. Agrega al portal falso un retraso aleatorio de hasta cinco segundos en el panel y corre el robot
   veinte veces. **Criterio:** las veinte pasan sin ningún `sleep` agregado; si alguna falla,
   explicas por qué y lo arreglas con un `expect`, no con una espera fija.

**🔴 Muy difícil (10)**

10. Diseña el robot de radicación de las cinco aseguradoras de Áurea como un solo proceso nocturno.
    **Criterio:** un documento de una página y un prototipo con dos portales falsos distintos.
    *Rúbrica:* (a) un `Page Object` por portal y un solo orquestador; (b) un portal caído no detiene
    a los demás; (c) cada fallo deja su rastro y avisa a una persona con el número de factura; (d)
    calculas las horas al mes que ahorra contra las que estimas de mantenimiento, y dices con qué
    resultado lo apagarías.

---

## 📚 7. Referencias

**Documentación oficial**

- Playwright para Python: https://playwright.dev/python/docs/intro
- Localizadores: https://playwright.dev/python/docs/locators
- El visor de rastros: https://playwright.dev/python/docs/trace-viewer
- El grabador (`codegen`): https://playwright.dev/python/docs/codegen

**Orden de lectura sugerido:** la página de localizadores primero —cambia cómo escribes todo lo
demás—; después el visor de rastros, que es lo que vas a usar cuando falle; y `codegen` para el
primer borrador de cada portal.

---

## 🚀 8. Cierre

Un portal sin API se automatiza con un navegador real, localizadores que leen lo que lee una persona,
ninguna espera escrita a mano y un rastro guardado de cada corrida. Lo que no se automatiza —el
CAPTCHA, los términos que lo prohíben— se pregunta antes de escribir la primera línea.

**La señal de que quedó bien:** *"La aseguradora cambió el texto de un botón, el robot falló esa
noche con la captura del botón nuevo, y se arregló cambiando una línea."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-au-fase-03 -m "op au03 cerrada: robot de radicación con Playwright y Page Object"
> ```
>
> Los commits llevan su prefijo (`op au03: …`) y los de ejercicio su número
> (`op au03 ej07: …`).
