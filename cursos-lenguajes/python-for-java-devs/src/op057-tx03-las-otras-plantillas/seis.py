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
