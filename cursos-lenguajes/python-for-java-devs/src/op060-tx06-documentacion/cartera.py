"""Cálculos de cartera de la red Áurea.

Los montos son enteros en pesos: la plata nunca va en float.

>>> mora = interes_de_mora(1_250_000, dias=45)
>>> formato_pesos(mora)
'$28.125'
"""


def formato_pesos(valor: int) -> str:
    """Formatea un monto en pesos con punto de miles.

    >>> formato_pesos(1234567)
    '$1.234.567'
    >>> formato_pesos(0)
    '$0'
    """
    return "$" + f"{valor:,}".replace(",", ".")


def interes_de_mora(saldo: int, dias: int, tasa_mensual_pct: int = 15) -> int:
    """Interés de mora simple sobre un saldo, por días, redondeado al peso.

    La tasa es mensual y en décimas de punto porcentual (15 = 1,5 %), para no usar float.

    >>> interes_de_mora(1_000_000, dias=30)
    15000
    >>> interes_de_mora(1_000_000, dias=0)
    0
    """
    return round(saldo * tasa_mensual_pct * dias / (1000 * 30))
