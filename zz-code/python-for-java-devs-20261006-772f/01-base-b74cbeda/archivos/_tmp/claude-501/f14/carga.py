"""Las dos cargas del dominio de Áurea: una de CPU y una de E/S."""
import hashlib
import time
from decimal import Decimal


def reconcile_chunk(rows: list[tuple[str, str, str]]) -> tuple[int, Decimal]:
    """CPU pura: conciliar ventas contra lo facturado.

    Por cada fila: normaliza el documento, calcula el hash de control que exige
    la aseguradora, y suma en Decimal. Es trabajo real de Áurea y es todo CPU.
    """
    total = Decimal("0")
    matched = 0
    for document, code, amount in rows:
        clean = document.replace(".", "").strip()
        digest = hashlib.sha256(f"{clean}|{code}|{amount}".encode()).hexdigest()
        value = Decimal(amount)
        total += value
        if digest[0] in "0123456789":     # el criterio de control, simulado
            matched += 1
    return matched, total


def io_chunk(n: int) -> int:
    """E/S simulada: esperar a que un sistema ajeno responda.

    time.sleep libera el GIL, igual que lo libera una lectura de red o de disco.
    Es la forma honesta de simular E/S sin depender de un servidor.
    """
    for _ in range(n):
        time.sleep(0.01)
    return n
