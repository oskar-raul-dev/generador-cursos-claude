# ⚖️ tx09 — Veredicto: plantilla o lenguaje mal hecho

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 9 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las ocho anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el eje de generar texto ([`tx01`](op055-tx01-el-eje.md)), Jinja2
([`tx02`](op056-tx02-jinja2-a-fondo.md)), los otros motores ([`tx03`](op057-tx03-las-otras-plantillas.md)), el código
como dato ([`tx04`](op058-tx04-codigo-como-dato.md)), Markdown ([`tx05`](op059-tx05-markdown.md)), la documentación
([`tx06`](op060-tx06-documentacion.md)), la generación de código ([`tx07`](op061-tx07-generacion-de-codigo.md)) y el
texto difícil ([`tx08`](op062-tx08-texto-dificil.md)).

La pregunta que queda es la del título. Toda plantilla empieza como texto con huecos, y todo motor de plantillas
termina permitiendo condiciones, bucles, variables y llamadas. Cada `{% set %}` es razonable por separado. Un año
después, el reporte de cartera es un programa de trescientas líneas escrito en un lenguaje sin depurador, sin pruebas
unitarias y sin tipos, que solo una persona entiende. **Una plantilla es la respuesta mientras sea texto con huecos;
cuando es un programa, es un lenguaje de programación mal hecho**, y el código debería volver a Python.

Esta sección cierra con una forma de medir de qué lado está cada plantilla, y con el veredicto de qué usar para cada
texto que genera Áurea.

---

## 🧠 2. El modelo

| Lo que genera Áurea | La respuesta | Por qué |
|---|---|---|
| Correo de recordatorio | Plantilla de Jinja2 con *autoescape* (`tx02`) | Mucho texto fijo, pocos datos, lo lee y lo cambia una persona |
| Reporte mensual de cartera | Plantilla **más** cálculos en Python antes de renderizar | La plantilla decide cómo se ve, no qué se calcula |
| HTML con mucha lógica de presentación | Árbol (`htpy`, `tx01`) | La lógica es Python, con pruebas y tipos |
| XML de factura electrónica | Chameleon o un árbol (`lxml`) (`tx03`) | Tiene esquema: el resultado debe ser un documento válido |
| SQL con filtros del usuario | Parámetros, nunca plantilla | El dato no se mezcla con la sintaxis |
| Clases de Python desde la base | `ast` + `ruff format` (`tx07`) | Lo generado compila siempre |
| Procedimientos de las sedes | Markdown con `markdown-it-py` (`tx05`) | Lo escriben personas que no programan |
| Plantilla que edita una sede | Marcadores fijos, o *sandbox* (`se07`) | El texto es de un usuario: es ejecución de código |

Y la señal concreta de que una plantilla cruzó la línea: **tiene `{% set %}` con aritmética, condiciones anidadas, o más
etiquetas de lógica que líneas de texto**. Eso se puede contar.

---

## 💻 3. El ejemplo que corre

`densidad.py` usa el analizador léxico del propio Jinja2 para contar, en cada plantilla, cuánto es texto y cuánto es
programa.

```bash
uv add jinja2
```

`densidad.py`:

```python
"""¿Plantilla o programa? Cuenta la lógica de cada plantilla con el analizador léxico de Jinja2."""

from collections import Counter

from jinja2 import Environment

TEMPLATES = {
    "recordatorio.html": """\
<p>Hola {{ nombre }},</p>
<p>Te esperamos el {{ fecha }} a las {{ hora }} en la sede {{ sede }}.</p>
<p>Si no puedes asistir, responde este correo.</p>""",
    "cartera.html": """\
{% set total = namespace(v=0) %}
{% for f in facturas %}{% set total.v = total.v + f.saldo %}{% endfor %}
{% set pct = (recaudado / facturado * 100) | round(1) %}
<h1>Cartera {{ sede }}</h1>
{% if pct < 80 %}{% if total.v > 10000000 %}<p class="rojo">{% else %}<p class="ambar">{% endif %}
{% else %}<p>{% endif %}Recaudo {{ pct }} %, saldo {{ total.v }}</p>
{% for f in facturas | sort(attribute="dias", reverse=True) %}
{% if f.dias > 90 %}<tr class="mora">{% elif f.dias > 30 %}<tr class="aviso">{% else %}<tr>{% endif %}
<td>{{ f.paciente }}</td><td>{{ f.saldo }}</td></tr>
{% endfor %}""",
}
LOGIC = {"if", "elif", "else", "for", "set", "macro", "call"}
ARITHMETIC = {"+", "-", "*", "/", "//", "%", "**"}


def density(source: str, env: Environment) -> dict:
    stats, after_block_begin = Counter(), False
    for _, kind, value in env.lex(source):          # tokens crudos: (línea, tipo, valor)
        if kind == "whitespace":
            continue
        if kind == "data":
            stats["texto"] += len(value.strip())
        elif kind == "block_begin":
            after_block_begin = True
            continue
        elif kind == "name" and after_block_begin and value in LOGIC:
            stats["lógica"] += 1
            stats["set"] += value == "set"
        elif kind == "operator" and value in ARITHMETIC:
            stats["aritmética"] += 1
        after_block_begin = False
    return stats


env = Environment()
for name, source in TEMPLATES.items():
    s = density(source, env)
    program = s["aritmética"] > 0 or s["lógica"] * 40 > s["texto"]
    verdict = "programa: mover la lógica a Python" if program else "plantilla"
    print(f"{name:<18} texto={s['texto']:>3}  lógica={s['lógica']:>2}  set={s['set']}  "
          f"aritmética={s['aritmética']}  → {verdict}")
```

```bash
python3 densidad.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
recordatorio.html  texto=102  lógica= 0  set=0  aritmética=0  → plantilla
cartera.html       texto=133  lógica=12  set=3  aritmética=3  → programa: mover la lógica a Python
```

El recordatorio es texto con cuatro huecos. El reporte de cartera suma saldos con un `namespace` —el truco que hace falta
porque Jinja2 no deja reasignar variables dentro de un bucle—, calcula un porcentaje, ordena, y decide colores con
condiciones anidadas. Todo eso funciona, y nada de eso tiene una prueba. La versión correcta calcula `total`, `pct`, el
color y el orden en Python, donde `pytest` los prueba, y la plantilla queda en una decena de huecos.

**Detalles con intención**

- **`env.lex`** devuelve los mismos *tokens* que Jinja2 usa para compilar: la medición no adivina con expresiones
  regulares (`tx04`). Son los *tokens* **crudos**: los espacios dentro de `{% %}` llegan como `whitespace` y los
  operadores como `operator` con su símbolo. La primera versión de este ejemplo esperaba los nombres ya procesados
  (`add`, `sub`) y declaró "plantilla" a las dos.
- **El umbral (una etiqueta de lógica por cada 40 caracteres de texto) es arbitrario** y está a la vista. Lo que importa
  es que exista uno, que corra en el CI y que una plantilla que lo cruza tenga que justificarse en la revisión.
- **Cualquier aritmética cuenta como programa**: sumar en una plantilla es la señal más clara de que un cálculo de
  negocio vive donde no se puede probar.

---

## ⚠️ 4. Lo que se rompe

**Mover la lógica a Python… dentro de un filtro gigante.** Un filtro `{{ facturas | resumen_cartera }}` que hace todo es la
misma lógica escondida en otro lugar. Los cálculos se hacen antes de renderizar, y la plantilla recibe un objeto con los
campos ya listos.

**La medición como castigo.** Un umbral que se usa para rechazar sin conversación produce plantillas partidas en diez
`include` para pasar la medición. Es una señal para la revisión, no una regla.

**El "lenguaje de plantillas propio".** El paso siguiente de una plantilla que es un programa es inventar un mini-lenguaje
para que "los usuarios configuren sus reportes". Es un intérprete sin especificación, y casi siempre la respuesta correcta
era un formulario con opciones.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Plantillas de configuración de infraestructura.** Ansible, Helm o Salt usan plantillas con lógica porque su modelo lo
exige; el criterio de este track no aplica igual, y los ecosistemas tienen sus propias guías.

**Un generador de sitios estáticos.** Los temas de MkDocs o de Sphinx tienen plantillas con mucha lógica de presentación,
mantenidas por sus autores, que no se modifican: se usan. Medirlas no cambia nada.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre `densidad.py` sobre las plantillas de un proyecto tuyo. **Criterio:** la tabla, y cuál está más cerca de ser un
   programa.
2. Llena la tabla de §2 para los textos que genera un sistema tuyo. **Criterio:** al menos una fila donde la respuesta
   actual no es la de la tabla, con su razón.

**🟡 Intermedio (3–4)**

3. Reescribe `cartera.html`: los cálculos en Python y la plantilla con huecos. **Criterio:** `densidad.py` la clasifica como
   plantilla y la salida HTML es la misma.
4. Escribe las pruebas de los cálculos que sacaste de la plantilla. **Criterio:** cubren el tramo de mora de más de 90 días
   y el color rojo.

**🟠 Difícil (5–6)**

5. Agrega a `densidad.py` la profundidad de anidación de condiciones. **Criterio:** `cartera.html` reporta profundidad 2.
6. Convierte `densidad.py` en un paso de CI que falle con una plantilla nueva que cruza el umbral, salvo que lleve un
   comentario `{# densidad: justificada porque … #}`. **Criterio:** las dos rutas, con una prueba.

**🔴 Muy difícil (7–8)**

7. Escribe la política de generación de texto de Áurea. **Criterio:** una página. *Rúbrica:* (a) qué herramienta para cada
   tipo de texto; (b) qué se calcula antes de renderizar y quién lo prueba; (c) cómo se detecta una plantilla que se
   volvió programa; (d) qué pasa cuando una sede pide personalizar un texto.
8. Elige una plantilla grande real (tuya o de un proyecto abierto) y estima el costo de migrarla a "Python + huecos".
   **Criterio:** horas estimadas y medidas en una parte. *Rúbrica:* (a) qué lógica sale; (b) qué pruebas aparecen; (c)
   cuánto baja la densidad; (d) si vale la pena, con tu razón.

---

## 📚 7. Referencias

- Jinja2, la API de bajo nivel (`lex`, `parse`): https://jinja.palletsprojects.com/en/stable/api/#low-level-api
- Terence Parr, *Enforcing Strict Model-View Separation in Template Engines* (2004), el ensayo que argumenta por plantillas
  sin lógica: https://www.cs.usfca.edu/~parrt/papers/mvc.templates.pdf

**Orden de lectura sugerido:** el ensayo de Parr —el autor de ANTLR y StringTemplate—, que es el argumento extremo; después
decide cuánto de él aplicar.

---

## 🚀 8. Cierre

Una plantilla es la respuesta mientras sea texto con huecos. Cuando suma, ordena y decide colores con condiciones
anidadas, es un programa sin pruebas, y la lógica vuelve a Python. Cada texto tiene su forma —plantilla, árbol,
parámetros, `ast`, Markdown—, y la densidad de lógica se mide en vez de discutirse.

**La señal de que quedó bien:** *"El reporte de cartera es una plantilla de quince líneas, y el cálculo del recaudo tiene
sus pruebas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-09 -m "op tx09 cerrada: plantilla mientras sea texto con huecos, y la densidad medida"
> ```
>
> Los commits llevan su prefijo (`op tx09: …`) y los de ejercicio su número
> (`op tx09 ej07: …`).
