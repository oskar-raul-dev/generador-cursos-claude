"""Cálculos de cartera de la red Áurea."""


def mora(saldo: int, dias: int, tasa_mensual_milesimas: int = 15) -> int:
    return round(saldo * tasa_mensual_milesimas * dias / (1000 * 30))
