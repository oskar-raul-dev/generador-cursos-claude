"""La segunda pregunta de plata: cuánto vale de verdad la red de aliados.

    from partners import partner_value, network_summary

Marcela ya dejó de mandarle casos a dos aliados por intuición. Esto es el número que la
sostiene o la desmiente: **ingreso por comisiones contra pacientes que no volvieron**, por
aliado, por especialidad y por zona.

🧭 **La comisión no se compara contra cero, se compara contra el costo de adquirir a ese
paciente por otro canal.** Un aliado que cobra 1,2 millones por paciente que se queda no es
caro ni barato en abstracto: es caro o barato **al lado de los 1,55 millones que cuesta
Google** en el mismo período. Ese es el marco, y es lo que convierte una tabla en una
decisión.
"""

from __future__ import annotations

import csv
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

# Por debajo de esta cantidad de remisiones, la tasa de retorno de un aliado es ruido: con
# veinte casos, dos pacientes de diferencia mueven el número diez puntos. Los aliados con
# menos aparecen en el informe **agrupados**, no ordenados uno por uno en un ranking que
# nadie puede defender.
MINIMUM_REFERRALS = 30


@dataclass(frozen=True, slots=True)
class PartnerValue:
    partner_id: str
    specialty: str
    zone: str
    referrals: int
    returned: int
    fees_cop: int

    @property
    def return_rate(self) -> float:
        return self.returned / self.referrals

    @property
    def cost_per_returned(self) -> float:
        """Lo que costó cada paciente que se quedó. `inf` si no se quedó ninguno.

        Se devuelve el infinito en vez de un cero o un `None` porque **es la respuesta
        correcta**: un aliado al que le pagaste comisiones y no te dejó un solo paciente
        tiene un costo por paciente retenido que no es un número, y esconderlo detrás de un
        cero lo pondría primero en el ranking.
        """
        return self.fees_cop / self.returned if self.returned else float("inf")


def load_partner_values(data: Path) -> list[PartnerValue]:
    with (data / "aliados.csv").open(encoding="utf-8", newline="") as file:
        partners = {row["aliado_id"]: row for row in csv.DictReader(file)}

    tally: defaultdict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    with (data / "remisiones.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            counters = tally[row["aliado_id"]]
            counters[0] += 1
            counters[1] += int(row["volvio"])
            counters[2] += int(row["comision_cop"])

    return [PartnerValue(partner_id, partners[partner_id]["especialidad"],
                         partners[partner_id]["zona"], *counters)
            for partner_id, counters in sorted(tally.items())]


def ranked(values: list[PartnerValue],
           minimum: int = MINIMUM_REFERRALS) -> list[PartnerValue]:
    """Los aliados con volumen suficiente, del más barato al más caro por paciente retenido."""
    return sorted((value for value in values if value.referrals >= minimum),
                  key=lambda value: value.cost_per_returned)


def by_dimension(values: list[PartnerValue], dimension: str) -> dict[str, float]:
    """Costo por paciente retenido, agrupado por especialidad o por zona.

    Agrupar es lo que permite decir algo cuando un aliado solo no tiene volumen. Y es donde
    aparece la pregunta que Marcela no se había hecho: si una especialidad entera retiene
    peor, el problema no son los aliados — es qué casos se están remitiendo.
    """
    fees: defaultdict[str, int] = defaultdict(int)
    returned: defaultdict[str, int] = defaultdict(int)
    for value in values:
        key = getattr(value, dimension)
        fees[key] += value.fees_cop
        returned[key] += value.returned
    return {key: fees[key] / returned[key] if returned[key] else float("inf")
            for key in sorted(fees)}


def network_summary(values: list[PartnerValue]) -> dict[str, float]:
    """La red entera en cuatro cifras, que es lo que cabe en un correo."""
    referrals = sum(value.referrals for value in values)
    returned = sum(value.returned for value in values)
    fees = sum(value.fees_cop for value in values)
    return {
        "aliados": len(values),
        "remisiones": referrals,
        "volvieron": returned,
        "tasa_retorno": returned / referrals if referrals else 0.0,
        "comisiones_cop": fees,
        "costo_por_retenido": fees / returned if returned else float("inf"),
    }
