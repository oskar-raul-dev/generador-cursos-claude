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
