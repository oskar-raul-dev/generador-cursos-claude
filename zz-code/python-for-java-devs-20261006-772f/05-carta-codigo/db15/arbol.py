"""¿Postgres o un especializado? El árbol del veredicto, aplicado a las necesidades de Áurea."""

from dataclasses import dataclass


@dataclass
class Need:
    name: str
    kind: str                       # "relacional", "archivos", "cache", "texto", "vectores", "serie", "eventos", "grafo", "documento"
    rows_per_year: int = 0
    readers: int = 1                # procesos distintos que leen lo mismo
    inherited: bool = False         # existe y no es nuestro


THRESHOLDS = {                      # a partir de cuánto el especializado se paga, para un equipo de uno
    "texto": 10_000_000, "vectores": 20_000_000, "serie": 1_000_000_000, "documento": 50_000_000,
}


def decide(n: Need) -> str:
    if n.inherited:
        return "leerlo como está, con sus trampas (db02, db03)"
    if n.kind == "archivos":
        return "almacén de objetos S3 (db13)"
    if n.kind == "cache":
        return "Valkey (db06), si una tabla con vencimiento no alcanza"
    if n.kind == "eventos":
        return "NATS JetStream (db14)" if n.readers > 2 else "tabla de eventos en Postgres"
    if n.kind in THRESHOLDS and n.rows_per_year > THRESHOLDS[n.kind]:
        return f"especializado para {n.kind}"
    extension = {"serie": " + TimescaleDB", "vectores": " + pgvector", "texto": " (tsvector, pg_trgm)",
                 "grafo": " (WITH RECURSIVE)", "documento": " (jsonb)"}.get(n.kind, "")
    return "Postgres" + extension


NEEDS = [
    Need("Agenda, abonos, cartera", "relacional", 2_000_000),
    Need("Odontovía de cada sede", "relacional", inherited=True),
    Need("Exportes nocturnos y reportes PDF", "archivos"),
    Need("Totales del tablero", "cache"),
    Need("Respuestas de WhatsApp por palabra", "texto", 200),
    Need("Respuestas de WhatsApp por similitud", "vectores", 200),
    Need("Minutos de espera por sede", "serie", 5_256_000),
    Need("Derivaciones entre sedes", "grafo", 20_000),
    Need("Cita confirmada para tres procesos", "eventos", 500_000, readers=3),
]
for n in NEEDS:
    print(f"{n.name:<38} → {decide(n)}")
