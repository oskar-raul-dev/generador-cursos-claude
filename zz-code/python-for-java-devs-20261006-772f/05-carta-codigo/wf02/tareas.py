"""La tarea: generar el PDF de la liquidación de una sede. Idempotente por diseño."""

import time
from pathlib import Path

OUT = Path("liquidaciones")
ATTEMPTS = Path("intentos.log")


def build_settlement_pdf(franchise: str, quarter: str) -> str:
    target = OUT / f"liquidacion-{franchise.lower()}-{quarter}.pdf"
    with ATTEMPTS.open("a") as log:
        log.write(f"{franchise}\n")
    if target.exists():
        return f"ya existía {target.name}"        # idempotente: repetir no duplica ni pisa
    # Simulación de un fallo transitorio: la primera vez, el servicio de firma no responde.
    if franchise == "Suba" and ATTEMPTS.read_text().count("Suba") == 1:
        raise ConnectionError("el servicio de firma no responde")
    time.sleep(0.5)                                 # el PDF de verdad se genera aquí
    OUT.mkdir(exist_ok=True)
    tmp = target.with_suffix(".tmp")
    tmp.write_bytes(b"%PDF-1.7\n")
    tmp.replace(target)                             # aparece completo o no aparece
    return f"generado {target.name}"
