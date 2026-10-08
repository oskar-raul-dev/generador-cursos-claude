"""¿REST o una de las tres excepciones? El veredicto como función, aplicado a las integraciones de Áurea."""

from dataclasses import dataclass


@dataclass
class Integration:
    name: str
    other_side_speaks: str = "nada todavía"        # "grpc", "rest", "cola"…
    server_pushes: bool = False                    # ¿el servidor avisa sin que le pregunten?
    to_browser: bool = False
    shapes_needed: int = 1                         # cuántas formas distintas de los mismos datos


def decide(i: Integration) -> str:
    if i.other_side_speaks not in ("nada todavía", "rest"):
        return f"{i.other_side_speaks} (excepción 1: el otro lado ya lo habla)"
    if i.server_pushes:
        return "SSE (excepción 2)" if i.to_browser else "eventos en una cola con contrato (excepción 2)"
    if i.shapes_needed >= 5:
        return "GraphQL (excepción 3), con DataLoader y límites"
    return "REST + JSON + OpenAPI"


INTEGRATIONS = [
    Integration("API de cartera para el portal", to_browser=True),
    Integration("Agenda del operador", other_side_speaks="grpc"),
    Integration("Pantalla de agenda en recepción", server_pushes=True, to_browser=True),
    Integration("Cita confirmada para tres procesos", server_pushes=True),
    Integration("Portal de franquiciados (12 pantallas)", to_browser=True, shapes_needed=12),
    Integration("Autorizaciones de la aseguradora", other_side_speaks="archivos en carpeta"),
    Integration("Liquidación de regalías (servicio Java)", other_side_speaks="rest"),
]
for i in INTEGRATIONS:
    print(f"{i.name:<42} → {decide(i)}")
