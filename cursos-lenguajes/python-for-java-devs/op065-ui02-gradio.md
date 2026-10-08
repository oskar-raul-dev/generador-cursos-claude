# 🎛️ ui02 — Gradio

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 2 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Patricia pregunta varias veces por semana lo mismo: "si un paciente debe tanto desde hace tantos días, ¿cuánto es la
mora?". El cálculo existe en Python —una función de tres líneas— y Patricia lo hace a mano en una hoja porque no tiene
cómo correr la función. Lo que necesita es una caja donde escribir el saldo y los días, y un botón.

Gradio es la biblioteca que convierte una función de Python en esa pantalla con el menor código posible. Nació para
mostrar modelos de aprendizaje automático —es lo que hay detrás de casi todas las demostraciones de Hugging Face— y
su promesa es literal: una función, sus entradas, sus salidas, y la aplicación está. Esa es su virtud y su límite: es
perfecta para "una función con una pantalla", y se resiste en cuanto la pantalla quiere ser otra cosa.

Hay un detalle que esta sección pone en primer plano porque casi nadie lo nota: **toda aplicación de Gradio es también
una API**. La pantalla de Patricia es, a la vez, un *endpoint* que cualquiera con acceso puede llamar desde un script.

---

## 🧠 2. El modelo

| Pieza | Qué es | Para qué |
|---|---|---|
| `gr.Interface(fn, inputs, outputs)` | La función con su pantalla, en una línea | El caso de la sección |
| `gr.Blocks()` | Disposición libre: filas, columnas, pestañas, eventos | Cuando `Interface` no alcanza |
| Componentes (`gr.Number`, `gr.Dropdown`, `gr.Dataframe`…) | Las entradas y salidas tipadas | Validar y mostrar |
| La API automática | Cada función expuesta se puede llamar por HTTP o con `gradio_client` | Integración… y superficie de ataque |
| `launch(auth=…)` | Usuario y contraseña simples | Lo mínimo para una red interna |
| `launch(share=True)` | **Un túnel público** a través de los servidores de Gradio | Mostrar una demo; **nunca** con datos reales |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, una pantalla y una API son dos cosas que se construyen aparte, y la API se expone a propósito. En Gradio son la
misma cosa: al publicar la pantalla se publica la API, documentada en el pie de la página ("Use via API"). El instinto de
que "es solo una pantallita interna" deja abierto un *endpoint* que nadie inventarió.

---

## 💻 3. El ejemplo que corre

```bash
uv add gradio
```

`mora_app.py`:

```python
"""La calculadora de mora de Patricia, en Gradio: la pantalla y su API, que son lo mismo."""

import gradio as gr


def mora(saldo: float, dias: float) -> str:
    """Interés de mora simple al 1,5 % mensual, redondeado al peso."""
    valor = round(int(saldo) * 15 * int(dias) / (1000 * 30))
    return "$" + f"{valor:,}".replace(",", ".")


demo = gr.Interface(
    fn=mora,
    inputs=[gr.Number(label="Saldo en pesos", precision=0), gr.Number(label="Días de mora", precision=0)],
    outputs=gr.Textbox(label="Mora"),
    title="Mora de un paciente",
    flagging_mode="never",
)

if __name__ == "__main__":
    demo.launch()
```

```bash
python3 mora_app.py      # abre http://127.0.0.1:7860
```

Eso es todo: veinte líneas y Patricia tiene su caja. Ahora la otra cara. Con la aplicación corriendo, este script —que
no ve ninguna pantalla— la usa como API:

`cliente.py`:

```python
"""La misma aplicación, usada desde un script: Gradio publica la API sin que nadie lo pida."""

import sys

from gradio_client import Client

client = Client(sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:7860/", verbose=False)
print(client.view_api(print_info=False, return_format="dict")["named_endpoints"].keys())
for saldo, dias in [(1_250_000, 45), (3_400_000, 120)]:
    print(f"saldo {saldo:>9,} · {dias:>3} días → {client.predict(saldo, dias, api_name='/mora')}")
```

```bash
python3 cliente.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
dict_keys(['/mora'])
saldo 1,250,000 ·  45 días → $28.125
saldo 3,400,000 · 120 días → $204.000
```

La aplicación publica un *endpoint* `/mora` —el nombre de la función— que nadie declaró, con el *docstring* como
descripción, y un script lo llama sin abrir el navegador. Para una
calculadora de mora es inofensivo, y hasta útil. Para una aplicación de Gradio que busca pacientes por cédula, es una
forma de descargar la base entera con un bucle.

**Detalles con intención**

- **`precision=0`** hace que `gr.Number` entregue enteros, y la API los anuncia como `integer`. El `int()` de la función
  sigue ahí porque la API se puede llamar con cualquier cosa: la plata no viaja en `float` más allá de la frontera.
- **`flagging_mode="never"`** apaga el botón de "marcar" que Gradio pone por defecto para recolectar ejemplos —útil en
  aprendizaje automático, y un archivo CSV con las entradas de Patricia que nadie pidió—.
- **`api_name='/mora'`** sale del nombre de la función, y el *docstring* se publica como su documentación: lo que se
  escribe para el desarrollador lo lee cualquiera que abra "Use via API". En `Blocks`, cada evento se nombra con
  `api_name=`, y `api_name=False` lo saca de la API. (Versiones anteriores de Gradio llamaban `/predict` a la función de
  `Interface`; muchos tutoriales todavía lo usan, y fallan con `Cannot find a function with api_name`.)
- **El cliente no necesita saber nada de la pantalla**: `view_api` lista los *endpoints* con sus tipos. Es la misma
  información que muestra el enlace "Use via API" al pie de la página.

---

## ⚠️ 4. Lo que se rompe

**`share=True` con datos reales.** Crea una URL pública de `gradio.live` que atraviesa los servidores de Gradio y dura
una semana. Es la forma más rápida de mostrar una demo, y es publicar en internet una aplicación con datos de Áurea, sin
autenticación. Para una red interna, se sirve detrás del proxy de la casa con su autenticación.

**`auth=` como seguridad.** Un usuario y una contraseña en el código, iguales para todos. Sirve para que no entre
cualquiera de la red; no es control de acceso por persona, ni por sede. Para eso, la aplicación va detrás de un proxy con
inicio de sesión (`se04`).

**Pasar de `Interface` a `Blocks` "porque falta una cosa".** `Blocks` permite casi todo, y el código de una aplicación de
`Blocks` con estado, pestañas y eventos encadenados se vuelve un frontend escrito en Python con menos herramientas que
uno de verdad. Si la pantalla dejó de ser "una función", es la señal de cambiar de biblioteca (`ui04`, `ui05`).

**Las versiones mayores.** Gradio cambia rápido: de la 4 a la 5 y de la 5 a la 6 hubo cambios incompatibles en nombres de
parámetros y en el cliente. Se fija la versión y se lee la guía de migración antes de subirla.

---

## ⚖️ 5. Cuándo NO usarlo

**Para una pantalla con varios pasos y estado.** Un flujo de "elige la sede, luego el paciente, luego el plan" es una
aplicación, no una función. Streamlit (`ui03`) o NiceGUI (`ui05`) lo modelan mejor.

**Para datos personales sin un proxy delante.** Por la API automática y por lo fácil que es el `share=True`.

**Si Patricia solo necesita el resultado una vez al mes.** Un reporte (`ui01`, `ui08`) es más barato que un servidor
corriendo todo el mes para una consulta mensual.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre la aplicación y abre el enlace "Use via API" del pie. **Criterio:** describes lo que muestra y quién podría
   usarlo.
2. Cambia la tasa a un `gr.Slider` de 1,0 % a 2,5 %. **Criterio:** la mora cambia al mover el control.
3. Agrega ejemplos (`examples=`) con tres casos típicos. **Criterio:** un clic en un ejemplo llena las cajas.

**🟡 Intermedio (4–6)**

4. Saca la función de la API con `Blocks` y `api_name=False`. **Criterio:** `cliente.py` ya no la encuentra, y la pantalla
   sigue funcionando.
5. Valida las entradas: saldo positivo y días entre 0 y 3 650, con un error legible (`gr.Error`). **Criterio:** Patricia ve
   un mensaje en español, no un *traceback*.
6. Agrega `auth=` con dos usuarios y prueba el cliente sin credenciales. **Criterio:** el cliente falla, y explicas qué
   protege y qué no.

**🟠 Difícil (7–9)**

7. Pon la aplicación detrás de Caddy con autenticación básica en un contenedor (sin puertos por defecto). **Criterio:** sin
   credenciales, ni la pantalla ni la API responden.
8. Monta la aplicación de Gradio dentro de una aplicación FastAPI (`gr.mount_gradio_app`). **Criterio:** la calculadora en
   `/mora` y una ruta propia en `/salud`.
9. Escribe una prueba automática que levante la aplicación y la llame con `gradio_client`. **Criterio:** corre en el CI y
   verifica los dos casos del ejemplo.

**🔴 Muy difícil (10)**

10. Inventaría las aplicaciones de Gradio que existen en un equipo (tuyo o imaginario de Áurea). **Criterio:** una tabla.
    *Rúbrica:* (a) cada una con su dueño y sus usuarios; (b) qué *endpoints* expone su API; (c) quién puede llegar a ella
    y con qué autenticación; (d) cuáles deberían ser un reporte en vez de una aplicación.

---

## 📚 7. Referencias

**Documentación oficial**

- Gradio, inicio rápido: https://www.gradio.app/guides/quickstart
- Gradio, cómo funciona la API: https://www.gradio.app/guides/getting-started-with-the-python-client
- Gradio, compartir la aplicación (y sus riesgos): https://www.gradio.app/guides/sharing-your-app

**Orden de lectura sugerido:** la guía de compartir la aplicación, en especial lo que dice de `share=True` y de la
autenticación; después la del cliente de Python.

---

## 🚀 8. Cierre

Gradio convierte una función en una pantalla en veinte líneas, y es la herramienta correcta mientras la pantalla sea "una
función". Toda aplicación de Gradio es también una API, se publique o no a propósito; `share=True` es internet, y `auth=`
es una cerradura de baño. Delante de datos reales va el proxy de la casa.

**La señal de que quedó bien:** *"Patricia calcula la mora en la caja, y la API que expone está en el inventario, detrás
del inicio de sesión."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-02 -m "op ui02 cerrada: la calculadora de mora en Gradio y la API que publica"
> ```
>
> Los commits llevan su prefijo (`op ui02: …`) y los de ejercicio su número
> (`op ui02 ej07: …`).
