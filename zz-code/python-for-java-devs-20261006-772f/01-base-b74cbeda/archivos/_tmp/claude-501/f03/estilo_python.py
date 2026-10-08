"""El motor de comisiones sin ceremonia: una tabla de datos y tres excepciones."""

from decimal import Decimal

# Los veinte aliados ordinarios no son código: son datos. Agregar el aliado 24
# es una línea en este diccionario —o una fila en el archivo del que salga—.
PARTNER_RATES: dict[str, Decimal] = {
    "P001": Decimal("0.15"),
    "P002": Decimal("0.12"),
    "P003": Decimal("0.20"),
    "P004": Decimal("0.10"),
    "P005": Decimal("0.18"),
    "P006": Decimal("0.10"),
}

# Y las tres excepciones son tres funciones, registradas con un decorador.
SPECIAL_RULES: dict[str, callable] = {}


def rule_for(partner_id: str):
    """Registra la regla especial de un aliado. Agregar una no toca nada existente."""
    def register(function):
        SPECIAL_RULES[partner_id] = function
        return function
    return register


@rule_for("P004")
def minimum_per_case(value, specialty, month_to_date, rate):
    """Neira cobra un mínimo por caso, por barato que salga el tratamiento."""
    return max(value * rate, Decimal("150000"))


@rule_for("P005")
def monthly_cap(value, specialty, month_to_date, rate):
    """Buitrago negoció un tope mensual: pasado ese punto, no se causa más."""
    return min(value * rate, max(Decimal("2000000") - month_to_date, Decimal("0")))


@rule_for("P006")
def by_specialty(value, specialty, month_to_date, rate):
    """Cárdenas cobra distinto según la especialidad del procedimiento."""
    rates = {"implantologia": Decimal("0.20"), "endodoncia": Decimal("0.12")}
    return value * rates.get(specialty, rate)


def referral_fee(partner_id, value, specialty="", month_to_date=Decimal("0")):
    """La comisión de un caso. Una función, y es toda la interfaz pública."""
    rate = PARTNER_RATES[partner_id]
    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate
