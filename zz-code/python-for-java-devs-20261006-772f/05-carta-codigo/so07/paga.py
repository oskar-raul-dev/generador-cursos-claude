"""¿Paga el modelo? Valor anual de la mejora medida en el track contra el costo de construirlo y mantenerlo."""

from dataclasses import dataclass

HOUR_COST = 120_000                 # costo de una hora del ingeniero, en pesos (supuesto)


@dataclass
class Case:
    name: str
    yearly_value: int               # lo que vale la mejora medida, en pesos por año (supuesto, a partir del track)
    build_hours: int
    upkeep_hours_per_year: int
    has_owner: bool = True


def verdict(c: Case) -> str:
    cost_first_year = (c.build_hours + c.upkeep_hours_per_year) * HOUR_COST
    if not c.has_owner:
        return "no: nadie lo mantendría"
    ratio = c.yearly_value / cost_first_year
    return f"{'sí' if ratio >= 3 else 'dudoso' if ratio >= 1 else 'no, la hoja basta'} (vale {ratio:.1f} veces su costo)"


CASES = [
    Case("so01 reparto del sábado (10 % de desplazamiento)", 2_600_000, 16, 8),
    Case("so02 ¿una silla más? (decisión de una vez)", 0, 24, 0),
    Case("so03 turnos de recepción (4 h de Patricia al mes)", 5_760_000, 40, 16),
    Case("so04 ruta del mensajero (3 000 km al año)", 3_000_000, 12, 4),
    Case("so05 recepcionista en vez de silla (evita una compra)", 60_000_000, 30, 0),
    Case("so06 recordatorios (ausentismo a la mitad)", 180_000_000, 60, 20, has_owner=False),
]
for c in CASES:
    print(f"{c.name:<54} → {verdict(c)}")
