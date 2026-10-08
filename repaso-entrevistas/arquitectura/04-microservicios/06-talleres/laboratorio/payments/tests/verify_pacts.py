"""Verifica los pactos en los que payments es PROVEEDOR, contra payments en marcha (taller 10).

    uv run --python 3.14 --group dev python tests/verify_pacts.py [--url http://localhost:28084]

Pact reproduce cada interacción que un consumidor dejó escrita en contrato/pacts y compara la
respuesta real con lo que el consumidor declaró que lee. Antes de cada una, prepara el estado que el
consumidor pidió ("given …") escribiendo directamente en la base de payments.
"""
import argparse
import json
import os
import sys
import uuid
from pathlib import Path

import psycopg
from pact import Verifier

DB_URL = os.environ.get("PAYMENTS_DB_URL", "postgresql://ms_payments:ms-lab-pass@localhost:25432/ms_payments")
PACTS = Path(__file__).resolve().parents[2] / "contrato" / "pacts"
ORDER = "5f1c2a4e-0000-4000-8000-000000000001"


def psp_authorizes(parameters=None):
    # la clave del pacto no puede existir ya: payments contestaría la repetición guardada (200), no un 201
    with psycopg.connect(DB_URL) as conn:
        conn.execute("DELETE FROM payments WHERE operation_id = 'pact-authorize-0001'")


def payment_in_progress(parameters=None):
    # el primer intento sigue en vuelo: una fila IN_PROGRESS con la misma clave
    with psycopg.connect(DB_URL) as conn:
        conn.execute("DELETE FROM payments WHERE operation_id = 'pact-in-progress-0001'")
        conn.execute("INSERT INTO payments (id, order_id, operation_id, amount, status) "
                     "VALUES (%s, %s, 'pact-in-progress-0001', 19.80, 'IN_PROGRESS')", (uuid.uuid4(), ORDER))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default="http://localhost:28084")
    args = parser.parse_args()

    verifier = Verifier("payments").add_transport(url=args.url)
    mine = [p for p in sorted(PACTS.glob("*.json")) if json.loads(p.read_text())["provider"]["name"] == "payments"]
    for pact in mine:
        print(f"pacto: {pact.name}")
        verifier.add_source(pact)
    verifier.state_handler({
        "the PSP authorizes payments": psp_authorizes,
        "a payment with key pact-in-progress-0001 is in progress": payment_in_progress,
    })
    try:
        verifier.verify()
    except RuntimeError as e:        # la verificación fallida: el resumen ya está en la salida
        print(f"\nVERIFICATION FAILED: {e}", file=sys.stderr)
        sys.exit(1)
    print("\nOK: payments cumple los pactos de sus consumidores")


if __name__ == "__main__":
    main()
