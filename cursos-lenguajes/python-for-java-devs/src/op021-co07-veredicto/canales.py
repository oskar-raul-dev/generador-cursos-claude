"""Clasifica los envíos de un mes de Áurea con las cuatro preguntas, y cuenta por canal."""

from collections import Counter
from dataclasses import dataclass


@dataclass(frozen=True)
class Delivery:
    what: str
    to_program: bool
    urgent: bool
    team: bool
    per_month: int


DELIVERIES = [
    Delivery("Liquidación de regalías a cada franquiciado", False, False, False, 2),  # 6 por trimestre
    Delivery("Respuesta a glosas a la aseguradora", False, False, False, 40),
    Delivery("Relación de pagos de la aseguradora", True, False, False, 8),
    Delivery("Lote RIPS para radicar", True, False, False, 10),
    Delivery("Recordatorio de cita a paciente", False, True, False, 3900),
    Delivery("Aviso: el cierre nocturno falló", False, True, True, 2),
    Delivery("Aviso: respaldo de una sede vencido", False, True, True, 3),
    Delivery("Circular nueva de una prepagada", False, False, True, 4),
    Delivery("Informe mensual por sede a los dueños", False, False, False, 10),
    Delivery("Factura del convenio a un aliado", False, False, False, 23),
]


def channel(d: Delivery) -> str:
    if d.to_program:
        return "SFTP / API"
    if d.urgent:
        return "mensajería del equipo" if d.team else "WhatsApp o SMS"
    return "correo"


if __name__ == "__main__":
    by_kind = Counter(channel(d) for d in DELIVERIES)
    by_volume = Counter()
    for d in DELIVERIES:
        by_volume[channel(d)] += d.per_month
    total_kinds, total_volume = len(DELIVERIES), sum(by_volume.values())
    for name in sorted(by_kind, key=by_kind.get, reverse=True):
        print(f"{name:22} {by_kind[name]:2} de {total_kinds} tipos ({by_kind[name] / total_kinds:.0%})"
              f"   {by_volume[name]:5} envíos al mes ({by_volume[name] / total_volume:.1%})")
