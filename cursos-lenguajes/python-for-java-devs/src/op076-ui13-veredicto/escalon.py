"""¿Qué escalón? La tabla del veredicto como función, aplicada a las entregas de Áurea."""

from dataclasses import dataclass


@dataclass
class Need:
    name: str
    external_users: bool = False       # pacientes, público
    concurrent_users: int = 1
    interactive: bool = True           # ¿alguien elige, filtra, escribe?
    consumer_is_program: bool = False
    design_negotiable: bool = True
    needs_local_hardware: bool = False


def rung(n: Need) -> str:
    if n.consumer_is_program:
        return "CLI con --json o API (ui10)"
    if n.external_users:
        return "frontend: fuera del alcance de este track"
    if n.needs_local_hardware:
        return "escritorio o agente local (ui09)"
    if not n.interactive:
        return "archivo: PDF o Excel (ui08)"
    if not n.design_negotiable:
        return "frontend, o negociar el diseño"
    if n.concurrent_users > 30:
        return "Dash, sin estado en el servidor (ui04)"
    return "aplicación de datos: Streamlit o Gradio (ui02, ui03)"


NEEDS = [
    Need("Reporte mensual de cartera", interactive=False),
    Need("Calculadora de mora de Patricia"),
    Need("Tablero de cartera de la red", concurrent_users=12),
    Need("Agendamiento en línea para pacientes", external_users=True, concurrent_users=200),
    Need("Lectura del datáfono de la sede", needs_local_hardware=True),
    Need("Resultado del cierre para el cron", consumer_is_program=True),
    Need("Tablero de Marcela con la marca exacta", design_negotiable=False),
]
for n in NEEDS:
    print(f"{n.name:<40} → {rung(n)}")
