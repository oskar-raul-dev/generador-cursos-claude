"""El mismo recordatorio de cita, de cuatro formas, con datos que rompen el HTML."""

import html

from htpy import p, strong
from jinja2 import Environment, select_autoescape

name = "María José D'Alessandro"
note = "traer <b>radiografía</b> & orden"

# 1. Concatenar: nadie escapa.
concatenated = "<p>Hola <strong>" + name + "</strong>. Nota: " + note + "</p>"

# 2. Formatear: escapa quien se acuerde.
formatted = f"<p>Hola <strong>{html.escape(name)}</strong>. Nota: {html.escape(note)}</p>"

# 3. Plantilla con autoescape: escapa la plantilla.
env = Environment(autoescape=select_autoescape(default_for_string=True))
template = env.from_string("<p>Hola <strong>{{ name }}</strong>. Nota: {{ note }}</p>")
templated = template.render(name=name, note=note)

# 4. Árbol: el dato nunca toca la sintaxis.
tree = str(p["Hola ", strong[name], ". Nota: ", note])

for label, out in [("concatenar", concatenated), ("formatear", formatted),
                   ("plantilla", templated), ("árbol", tree)]:
    print(f"{label:<11} {'❌' if '<b>' in out else '✅'} {out}")

# La trampa del doble escape: escapar a mano y además con la plantilla.
twice = template.render(name=html.escape(name), note=note)
print("doble      ", twice.split("<strong>")[1].split("</strong>")[0])
