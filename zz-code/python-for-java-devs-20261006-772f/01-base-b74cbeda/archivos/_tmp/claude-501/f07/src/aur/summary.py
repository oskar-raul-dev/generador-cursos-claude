"""Resumen del mes."""
from decimal import Decimal

def summarize(rows):
    total, patients, by_code = Decimal("0"), set(), {}
    n = 0
    for row in rows:
        n += 1
        amount = Decimal(row["valor"])
        total += amount
        patients.add(row["documento"])
        by_code[row["codigo"]] = by_code.get(row["codigo"], Decimal("0")) + amount
    return {"procedimientos": n, "pacientes": len(patients), "total": total, "por_codigo": by_code}
