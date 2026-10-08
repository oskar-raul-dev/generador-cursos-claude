"""Simulador del binario firmador del proveedor tecnológico de Áurea.

Esto NO es código de ejemplo a imitar: imita a un programa ajeno, con sus
rarezas reales, para que el miniproyecto de la Fase 05 se pueda hacer sin
tener el binario del proveedor.

Uso:
    python firmador_simulado.py --entrada <archivo.xml> --salida <archivo.xml>
    python firmador_simulado.py --lote <archivo1.xml> <archivo2.xml> ...

Rarezas que imita, todas tomadas de programas de firma reales:
  · escribe parte de sus mensajes en stdout y parte en stderr, sin criterio
  · un "éxito con advertencias" que devuelve código 3, no 0
  · se cuelga con los NIT que terminan en 7 (simula el timeout del servicio)
  · devuelve código 2 para el certificado vencido y 9 para el XML mal formado
  · tarda entre 40 y 120 ms por factura, como el de verdad
"""

import random
import sys
import time
from pathlib import Path


def sign_one(source: Path, target: Path) -> int:
    """Firma un archivo. Devuelve el código de salida del proveedor."""
    if not source.exists():
        print(f"ERR-404 archivo no encontrado: {source}", file=sys.stderr)
        return 9

    content = source.read_text(encoding="utf-8", errors="replace")
    nit = "".join(ch for ch in content if ch.isdigit())[:9] or "000000000"

    # Se cuelga con los NIT terminados en 7. El de verdad se colgaba cuando el
    # servicio de sellado del proveedor no respondía, que era imposible de predecir.
    if nit.endswith("7"):
        print("conectando con el servicio de sellado...", flush=True)
        time.sleep(3600)

    # Certificado vencido: código 2, y el mensaje va a stdout (no a stderr).
    if nit.endswith("3"):
        print(f"ERR-CERT certificado del emisor vencido (NIT {nit})")
        return 2

    # El tiempo depende de la factura y no del proceso: así el resultado es el
    # mismo se invoque una vez por factura o una vez por lote, que es lo que
    # hace que la medición de la fase compare lo que dice comparar.
    random.seed(int(nit))
    time.sleep(random.uniform(0.04, 0.12))
    target.write_text(f"<!-- firmado {nit} -->\n{content}", encoding="utf-8")

    # Éxito con advertencia: código 3. Está firmado, y el que no mire el
    # código de retorno con cuidado va a creer que falló.
    if nit.endswith("5"):
        print(f"WARN-011 firmado con certificado próximo a vencer (NIT {nit})",
              file=sys.stderr)
        return 3

    print(f"OK firmado {target.name}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) >= 5 and argv[1] == "--entrada" and argv[3] == "--salida":
        return sign_one(Path(argv[2]), Path(argv[4]))

    if len(argv) >= 3 and argv[1] == "--lote":
        worst = 0
        for raw in argv[2:]:
            source = Path(raw)
            code = sign_one(source, source.with_suffix(".firmado.xml"))
            worst = max(worst, code)
        return worst

    print("uso: firmador --entrada <xml> --salida <xml>", file=sys.stderr)
    print("     firmador --lote <xml> [<xml> ...]", file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
