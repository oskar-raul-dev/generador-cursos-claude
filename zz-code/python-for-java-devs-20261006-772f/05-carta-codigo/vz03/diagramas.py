"""El diagrama del cierre generado desde los mismos datos que lo definen (DOT y Mermaid), y un semáforo en SVG."""

import drawsvg
import graphviz

# La definición del cierre: la misma que usaría el orquestador para correr los pasos.
STEPS = {
    "extraer_odontovia": [],
    "extraer_pasarela": [],
    "conciliar_abonos": ["extraer_odontovia", "extraer_pasarela"],
    "calcular_mora": ["conciliar_abonos"],
    "liquidar_regalias": ["conciliar_abonos"],
    "generar_reportes": ["calcular_mora", "liquidar_regalias"],
    "enviar_correos": ["generar_reportes"],
}

dot = graphviz.Digraph("cierre", graph_attr={"rankdir": "LR"}, node_attr={"shape": "box", "style": "rounded"})
for step, deps in STEPS.items():
    dot.node(step, step.replace("_", " "))
    for dep in deps:
        dot.edge(dep, step)
svg_path = dot.render("cierre", format="svg", cleanup=True)
print("Graphviz:", svg_path, "·", dot.source.count("->"), "flechas")

mermaid = ["flowchart LR"] + [f'    {d} --> {s}' for s, deps in STEPS.items() for d in deps]
print("Mermaid:\n" + "\n".join(mermaid[:4]) + "\n    …")

MORA = {"Centro": 0.02, "Suba": 0.07, "Kennedy": 0.12}             # mora de más de 90 días sobre la cartera


def light(rate: float) -> str:
    return "#2E7D32" if rate < 0.05 else "#F9A825" if rate < 0.10 else "#C62828"


canvas = drawsvg.Drawing(360, 80)
for i, (sede, rate) in enumerate(MORA.items()):
    x = 20 + i * 120
    canvas.append(drawsvg.Circle(x + 15, 30, 14, fill=light(rate)))
    canvas.append(drawsvg.Text(f"{sede} {rate:.0%}", 14, x, 70, font_family="DejaVu Sans"))
canvas.save_svg("semaforo.svg")
print("drawsvg: semaforo.svg ·", sorted({light(r) for r in MORA.values()}))
