# 🗂️ tx03 — Las otras plantillas

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 3 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Jinja2 es el motor por defecto, pero no el único que este perfil va a encontrar. El sistema heredado de una
franquicia está en Django y sus plantillas son de Django. Una herramienta interna vieja usa Mako. Un integrador de
facturación electrónica genera XML con Chameleon. Y un script de dos líneas usa `string.Template`, de la
biblioteca estándar, porque no quería dependencias.

Cada motor tiene una filosofía distinta, y la diferencia que importa no es la sintaxis —`{{ x }}`, `${x}`, `$x`—
sino **qué hace por defecto con un dato peligroso**. Esta sección los pone a los seis sobre el mismo recordatorio de
cita, con los mismos datos que rompen el HTML de `tx01`, y mide lo que cuesta cada uno.

---

## 🧠 2. El modelo

| Motor | Filosofía | ¿Escapa por defecto? | Para qué se elige |
|---|---|---|---|
| `string.Template` (biblioteca estándar) | Sustitución, sin lógica | **No** (no sabe de HTML) | Texto plano, configuración, cero dependencias |
| Jinja2 3.1.6 | Lenguaje propio, con lógica limitada | **No**, salvo que se active | El defecto para casi todo |
| Django templates 6.1.1 | Lógica mínima a propósito | **Sí** | Proyectos Django |
| Mako 1.4.3 | Python dentro de la plantilla | **No** (`default_filters=["h"]`) | Rendimiento y poder total; código heredado |
| Chameleon 4.6.0 | La plantilla es XML válido (TAL) | **Sí** | XML y HTML que se valida como documento |
| `chevron` 0.14.0 💤 (Mustache) | Sin lógica: solo variables y secciones | **Sí** | Plantillas compartidas con otros lenguajes |

La línea entre ellos es cuánta lógica dejan meter. Mustache no deja casi nada —ni un `if` con comparación— y por
eso la misma plantilla sirve en JavaScript, Java y Python. Mako deja todo, y por eso una plantilla de Mako puede
ser un programa entero.

### Esto sí funciona igual

Mustache es Mustache en todos los lenguajes: la plantilla que usa el frontend de JavaScript o un servicio Java con
`mustache.java` la renderiza `chevron` sin cambios. Si este perfil ya tiene plantillas Mustache, se traen tal cual.

---

## 💻 3. El ejemplo que corre

```bash
uv add jinja2 django mako chameleon chevron
```

`seis.py`:

```python
"""El mismo recordatorio en seis motores: qué escapa cada uno por defecto, y cuánto tarda."""

import string
import timeit

import chevron
from chameleon import PageTemplate
from django.conf import settings
from django.template import Context, Engine
from jinja2 import Environment
from mako.template import Template as MakoTemplate

settings.configure()                                  # Django sin proyecto: lo mínimo para usar su motor

data = {"name": "María José D'Alessandro", "note": "traer <b>radiografía</b> & orden"}

std = string.Template("<p>Hola <strong>$name</strong>. Nota: $note</p>")
jinja = Environment().from_string("<p>Hola <strong>{{ name }}</strong>. Nota: {{ note }}</p>")
django = Engine().from_string("<p>Hola <strong>{{ name }}</strong>. Nota: {{ note }}</p>")
mako = MakoTemplate("<p>Hola <strong>${name}</strong>. Nota: ${note}</p>")
mako_h = MakoTemplate("<p>Hola <strong>${name}</strong>. Nota: ${note}</p>", default_filters=["h"])
chameleon = PageTemplate("<p>Hola <strong>${name}</strong>. Nota: ${note}</p>")
mustache = "<p>Hola <strong>{{name}}</strong>. Nota: {{note}}</p>"

engines = {
    "string.Template": lambda: std.substitute(data),
    "Jinja2 (por defecto)": lambda: jinja.render(data),
    "Django": lambda: django.render(Context(data)),
    "Mako (por defecto)": lambda: mako.render(**data),
    "Mako con h": lambda: mako_h.render(**data),
    "Chameleon": lambda: chameleon(**data),
    "chevron": lambda: chevron.render(mustache, data),
}

for label, render in engines.items():
    out = render()
    ms = timeit.timeit(render, number=10_000) * 1000
    print(f"{label:<21} {'❌' if '<b>' in out else '✅'} {ms:7.0f} ms/10k  {out}")
```

```bash
python3 seis.py
```

Salida (Python 3.14.7, 05/10/2026) (los tiempos son de la máquina que corre; estos, de un contenedor en un portátil):

```text
string.Template       ❌       9 ms/10k  <p>Hola <strong>María José D'Alessandro</strong>. Nota: traer <b>radiografía</b> & orden</p>
Jinja2 (por defecto)  ❌      44 ms/10k  <p>Hola <strong>María José D'Alessandro</strong>. Nota: traer <b>radiografía</b> & orden</p>
Django                ✅      55 ms/10k  <p>Hola <strong>María José D&#x27;Alessandro</strong>. Nota: traer &lt;b&gt;radiografía&lt;/b&gt; &amp; orden</p>
Mako (por defecto)    ❌      44 ms/10k  <p>Hola <strong>María José D'Alessandro</strong>. Nota: traer <b>radiografía</b> & orden</p>
Mako con h            ✅      51 ms/10k  <p>Hola <strong>María José D&#39;Alessandro</strong>. Nota: traer &lt;b&gt;radiografía&lt;/b&gt; &amp; orden</p>
Chameleon             ✅      35 ms/10k  <p>Hola <strong>María José D'Alessandro</strong>. Nota: traer &lt;b&gt;radiografía&lt;/b&gt; &amp; orden</p>
chevron               ✅      51 ms/10k  <p>Hola <strong>María José D'Alessandro</strong>. Nota: traer &lt;b&gt;radiografía&lt;/b&gt; &amp; orden</p>
```

Tres de los siete no escapan por defecto, y dos de esos tres son los motores más usados de la lista. La regla
práctica que sale de la tabla: **al adoptar un motor, lo primero es saber su valor por defecto**, y fijarlo
explícitamente en la configuración aunque coincida con lo que quieres.

Y los tiempos dicen lo contrario de lo que suele repetirse: diez mil renderizados cuestan entre 35 y 55 ms en
cualquiera de los motores de verdad, es decir, unos 5 microsegundos por correo. Para los pocos miles de
recordatorios diarios de Áurea, **la velocidad no decide el motor**; deciden el escape por defecto y cuánta lógica
deja meter.

**Detalles con intención**

- **`settings.configure()`** es lo que permite usar el motor de Django sin un proyecto Django. Es útil para
  migrar plantillas de a poco, no para adoptar Django como motor de plantillas suelto.
- **Mako compila la plantilla a un módulo de Python**, y tiene fama de ser el más rápido. En esta medición empata con
  Jinja2 (que también compila a Python) y pierde con Chameleon: la fama viene de comparaciones de hace quince años.
  Lo que sí es cierto es su riesgo: `<% import os %>` dentro de una plantilla de Mako es Python normal.
- **`chevron` vuelve a analizar la plantilla en cada llamada**, porque recibe la cadena y no un objeto compilado; aun
  así queda en el mismo rango.
- **Chameleon no escapa el apóstrofo** fuera de los atributos, y tiene razón: dentro del cuerpo de un elemento, `'`
  no significa nada para el HTML. Los motores que lo escapan lo hacen por si el valor termina dentro de un atributo
  con comillas simples.
- **`chevron` lleva cinco años sin versiones** (💤). Funciona, y Mustache es una especificación estable que casi no
  cambia; pero si un error aparece, nadie lo va a corregir. `pystache`, el anterior, está igual o peor.

---

## ⚠️ 4. Lo que se rompe

**Migrar de Django a Jinja2 sin activar el *autoescape*.** Las plantillas de Django escapaban sin que nadie lo
pidiera; trasladadas a Jinja2 con `Environment()` por defecto, dejan de hacerlo, y nadie lo nota porque los datos de
prueba no tienen `<`. Es el error de migración más común entre motores.

**Chameleon y el HTML que no es XML.** `<br>` sin cerrar, atributos sin comillas o un `&` suelto en el texto fijo
hacen fallar la plantilla al compilar. Es la garantía que da (el resultado es un documento válido), y es el costo
para quien trae HTML escrito a mano.

**La lógica de Mako.** Una plantilla de Mako con consultas a la base y cálculos adentro es código de negocio sin
pruebas. Pasa también con Jinja2, pero Mako no pone ningún freno.

**Mustache y la lógica que no cabe.** "Mostrar en rojo si la mora pasa de 90 días" no se puede escribir en
Mustache; se resuelve calculando `alerta: true` en los datos. Es exactamente lo que Mustache quiere obligar, y
resulta incómodo para quien espera un `if` con comparación.

---

## ⚖️ 5. Cuándo NO usarlos

**Mako, en un proyecto nuevo.** Salvo una razón concreta de rendimiento medida, Jinja2 da lo mismo con más
ecosistema y con un *sandbox* que Mako no tiene.

**Chameleon, para correos.** Los correos HTML son HTML de 1999 por razones de compatibilidad con los clientes de
correo, y no siempre son XML válido. Chameleon brilla generando XML (facturación electrónica, `ar`), no ahí.

**`string.Template`, para HTML.** No sabe de HTML. Para texto plano y configuración es perfecto: no tiene lógica, y
`safe_substitute` deja intactas las variables que faltan.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `seis.py` en tu máquina. **Criterio:** la tabla con tus tiempos, y el orden de los motores del más rápido al
   más lento.
2. Usa `{{{note}}}` en la plantilla de `chevron`. **Criterio:** muestras que no escapa y explicas para qué existe.
3. Escribe `<br>` sin cerrar en la plantilla de Chameleon. **Criterio:** el error exacto, y en qué momento sale
   (al crear la plantilla o al renderizar).

**🟡 Intermedio (4–6)**

4. Activa el escape en Jinja2 y repite la medición. **Criterio:** reportas cuánto cuesta el escape en tiempo.
5. Escribe en Mako una plantilla que importe `os` y liste el directorio. **Criterio:** funciona, y escribes en una
   oración qué significa para plantillas que no escribiste tú.
6. Haz la plantilla del reporte de cartera de `tx02` en Mustache. **Criterio:** la alerta de mora sale de un campo
   calculado, no de la plantilla.

**🟠 Difícil (7–9)**

7. Migra una plantilla de Django con `{% url %}` y filtros propios a Jinja2. **Criterio:** la misma salida, con
   *autoescape* activado, y la lista de lo que tuviste que reemplazar.
8. Genera con Chameleon el XML de una factura electrónica mínima. **Criterio:** el XML valida contra su esquema con
   `lxml`.
9. Repite la medición con una plantilla de 200 líneas con bucles. **Criterio:** si el orden de los motores cambia
   respecto del ejemplo, y por qué.

**🔴 Muy difícil (10)**

10. Decide el motor de plantillas de Áurea para correos, reportes y XML. **Criterio:** una página. *Rúbrica:* (a) uno
    o varios motores, con su razón; (b) cómo se garantiza el escape en cada uno; (c) qué pasa con las plantillas de
    Django de la franquicia; (d) los números de tu medición que apoyan la decisión.

---

## 📚 7. Referencias

**Documentación oficial**

- `string.Template`: https://docs.python.org/3/library/string.html#template-strings
- Django, el lenguaje de plantillas: https://docs.djangoproject.com/en/stable/ref/templates/language/
- Mako: https://docs.makotemplates.org/en/latest/
- Chameleon: https://chameleon.readthedocs.io/en/latest/
- Mustache, la especificación: https://mustache.github.io/mustache.5.html

**Orden de lectura sugerido:** la página de Mustache (es corta y explica por qué "sin lógica" es una decisión);
después la del motor que vayas a heredar.

---

## 🚀 8. Cierre

Los motores se distinguen por cuánta lógica dejan meter y por lo que hacen por defecto con un dato peligroso. Tres de
los siete no escapan sin que se les pida, y uno de ellos es Jinja2. Al adoptar o heredar un motor, el escape se fija
explícitamente en la configuración, y la lógica se queda en Python.

**La señal de que quedó bien:** *"Migramos las plantillas de Django de la franquicia y el `autoescape` estaba
encendido desde el primer commit."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-03 -m "op tx03 cerrada: seis motores, sus valores por defecto y sus tiempos"
> ```
>
> Los commits llevan su prefijo (`op tx03: …`) y los de ejercicio su número
> (`op tx03 ej07: …`).
