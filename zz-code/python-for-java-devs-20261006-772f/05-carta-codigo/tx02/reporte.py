"""El reporte mensual de cartera: herencia, macro, filtro propio y StrictUndefined."""

from jinja2 import DictLoader, Environment, StrictUndefined, UndefinedError, select_autoescape

TEMPLATES = {
    "base.html": """\
<html><body>
<h1>Áurea · {% block titulo %}{% endblock %}</h1>
{% block contenido %}{% endblock %}
<footer>Información confidencial de la red Áurea. Ley 1581 de 2012.</footer>
</body></html>""",
    "macros.html": """\
{% macro fila_monto(etiqueta, valor, alerta=False) -%}
<tr{% if alerta %} class="alerta"{% endif %}><td>{{ etiqueta }}</td><td>{{ valor | pesos }}</td></tr>
{%- endmacro %}""",
    "cartera.html": """\
{% extends "base.html" %}
{% import "macros.html" as m %}
{% block titulo %}Cartera de {{ sede.nombre }}, {{ mes }}{% endblock %}
{% block contenido %}
{% if sede.franquicia %}<p>Franquiciado: {{ sede.titular }}</p>{% endif %}
<table>
{{ m.fila_monto("Facturado", cartera.facturado) }}
{{ m.fila_monto("Recaudado", cartera.recaudado) }}
{% for tramo, valor in cartera.mora.items() %}
{{ m.fila_monto("Mora " ~ tramo, valor, alerta=(tramo == "más de 90 días")) }}
{% endfor %}
</table>
{% endblock %}""",
}


def pesos(value: int) -> str:
    """1234567 -> $1.234.567, el formato que leen los franquiciados."""
    return "$" + f"{value:,}".replace(",", ".")


env = Environment(loader=DictLoader(TEMPLATES), autoescape=select_autoescape(["html"]),
                  undefined=StrictUndefined, trim_blocks=True, lstrip_blocks=True)
env.filters["pesos"] = pesos

data = {
    "mes": "septiembre de 2026",
    "sede": {"nombre": "Suba", "franquicia": True, "titular": "Édgar Rojas"},
    "cartera": {"facturado": 187_450_000, "recaudado": 162_300_000,
                "mora": {"1 a 30 días": 14_200_000, "31 a 90 días": 7_850_000,
                         "más de 90 días": 3_100_000}},
}
print(env.get_template("cartera.html").render(**data))

# Un error de tipeo en una plantilla: con StrictUndefined, falla en vez de dejar un hueco.
broken = env.from_string("Cartera de {{ sede.nombr }}")
try:
    broken.render(**data)
except UndefinedError as e:
    print("\nplantilla rota:", e)
