"""Genera el corpus documental de Áurea y las cincuenta preguntas anotadas.

    uv run python generar_corpus.py --salida corpus --semilla 20260913

Mismo criterio que los generadores del camino base: **semilla fija**, salida
reproducible byte a byte, y cero datos clínicos. Lo que produce son contratos, anexos
tarifarios y circulares de aseguradoras ficticias, con la estructura de cláusulas que
espera `ingest.split_by_clause` de ia05.

Por qué se genera y no se descarga: el curso tiene que poder tomarse entero sin acceso a
nada que no sea este repositorio (guía §11, regla 4), y un corpus real de contratos de
aseguradoras no se puede publicar.

⚠️ Las preguntas anotadas traen su etiqueta —lexica, semantica, mixta— asignada **por
construcción**: cada plantilla de pregunta sabe qué clase de consulta es. Eso es
legítimo aquí y NO lo es al anotar un corpus real, donde etiquetar después de ver los
resultados fabrica la conclusión (ia04 §6).
"""

from __future__ import annotations

import argparse
import json
import random
from dataclasses import dataclass
from datetime import date
from pathlib import Path

# --- El dominio -------------------------------------------------------------------

INSURERS = [
    ("Seguros Andina", "830003564"),
    ("Prepagada Altamira", "800251440"),
    ("Salud Meridiano", "890903937"),
    ("Coberturas del Llano", "860002964"),
]

# Códigos del manual tarifario. Son los que la búsqueda léxica encuentra y la vectorial
# no: para un modelo de embeddings, "992102" es una cadena de dígitos cualquiera.
PROCEDURES = [
    ("992102", "retiro de aparatología ortodóncica fija", "el retiro de aparatología"),
    ("992101", "instalación de aparatología ortodóncica fija", "la instalación de brackets"),
    ("992310", "control mensual de ortodoncia", "el control mensual de ortodoncia"),
    ("237101", "carilla en resina compuesta", "una carilla en resina"),
    ("237204", "corona libre de metal", "una corona libre de metal"),
    ("992401", "retenedor termoformado", "un retenedor termoformado"),
    ("881210", "radiografía panorámica", "una radiografía panorámica"),
    ("233101", "profilaxis y control de placa", "una profilaxis"),
]

# Cada plan viaja con su artículo. Sin esto sale "el póliza de salud oral", y un corpus
# con errores de concordancia ensucia los embeddings y delata al generador.
PLANS = [
    ("el plan básico", "plan básico"),
    ("el plan complementario", "plan complementario"),
    ("el plan integral", "plan integral"),
    ("la póliza de salud oral", "póliza de salud oral"),
]

# Texto de relleno con registro jurídico. No es adorno: los fragmentos tienen que pasar
# el mínimo de caracteres de `ingest.MIN_USEFUL_CHARS` para entrar al índice.
BOILERPLATE = [
    "Las condiciones aquí pactadas aplican a los afiliados activos al momento de la "
    "prestación del servicio y se entienden incorporadas al contrato principal.",
    "El prestador deberá conservar el soporte de la atención por el término que fije la "
    "normatividad vigente y ponerlo a disposición ante requerimiento de la aseguradora.",
    "Cualquier modificación a lo dispuesto en esta cláusula deberá constar por escrito y "
    "ser comunicada con una antelación no inferior a treinta (30) días calendario.",
    "La aseguradora se reserva la facultad de auditar la pertinencia de los "
    "procedimientos facturados conforme al manual tarifario vigente.",
]


@dataclass(frozen=True, slots=True)
class GeneratedClause:
    """Una cláusula con lo que hace falta para preguntar por ella después."""

    number: str
    title: str
    body: str
    procedure_code: str
    covered: bool
    copayment: int | None
    requires_authorization: bool


def _applies_to(plan_with_article: str) -> str:
    """Contrae "a el" en "al". Es el último error de concordancia que quedaba.

    Lo escribe a mano quien genera texto en español y se le olvida: "Aplica a el plan
    básico" es lo que sale de concatenar la preposición con el artículo, y no lo detecta
    ninguna prueba de tipos.
    """
    if plan_with_article.startswith("el "):
        return "al " + plan_with_article[3:]
    return "a " + plan_with_article


def _clause_text(clause: GeneratedClause) -> str:
    """El texto tal como aparece en el documento, con su encabezado.

    El formato del encabezado es el que reconoce `CLAUSE_HEADING` de ia05. Si se cambia
    uno hay que cambiar el otro, y por eso esta función vive al lado de una prueba.
    """
    return f"CLÁUSULA {clause.number} {clause.title}\n{clause.body}\n"


def _build_clause(
    rng: random.Random, number: str, code: str, name: str, plan_with_article: str
) -> GeneratedClause:
    covered = rng.random() < 0.55
    copayment = rng.choice([15000, 24000, 38000, 45000, 62000]) if covered else None
    requires_authorization = covered and rng.random() < 0.4

    if covered:
        opening = (
            f"{plan_with_article.capitalize()} cubre el procedimiento {code} — {name} — "
            f"con un copago a cargo "
            f"del afiliado de ${copayment:,} pesos por sesión."
        ).replace(",", ".")
        if requires_authorization:
            opening += (
                " Este procedimiento requiere autorización previa de la aseguradora, "
                "la cual deberá solicitarse con mínimo cinco (5) días hábiles de antelación."
            )
    else:
        opening = (
            f"El procedimiento {code} — {name} — no está cubierto por {plan_with_article} y su "
            f"valor será asumido en su totalidad por el afiliado."
        )

    body = opening + " " + rng.choice(BOILERPLATE) + " " + rng.choice(BOILERPLATE)
    title = "Coberturas y exclusiones" if covered else "Exclusiones expresas"
    return GeneratedClause(number, title, body, code, covered, copayment, requires_authorization)


def _build_document(
    rng: random.Random,
    *,
    insurer: str,
    nit: str,
    plan_with_article: str,
    plan: str,
    version: str,
    valid_from: date,
    valid_to: date | None,
) -> tuple[str, list[GeneratedClause]]:
    """Un anexo tarifario completo: encabezado, cláusulas numeradas y cierre."""
    codes = rng.sample(PROCEDURES, k=rng.randint(4, 6))
    # Todas las cláusulas cuelgan del capítulo 4, como en los anexos reales.
    clauses = [
        _build_clause(rng, f"4.{position}", code, name, plan_with_article)
        for position, (code, name, _) in enumerate(codes, start=1)
    ]

    header = (
        f"ANEXO TARIFARIO {version}\n"
        f"{insurer.upper()} — NIT {nit}\n"
        f"Aplica {_applies_to(plan_with_article)}. Vigencia desde el {valid_from.isoformat()}"
        + (f" hasta el {valid_to.isoformat()}" if valid_to else " hasta nueva comunicación")
        + ".\n\n"
    )
    return header + "\n".join(_clause_text(clause) for clause in clauses), clauses


# --- Las preguntas ------------------------------------------------------------------

# Cada plantilla declara qué clase de consulta produce. La léxica gira sobre un
# identificador; la semántica no menciona ni el código ni las palabras del documento.
# Las plantillas usan `plan_art` —el plan con su artículo— y evitan la contracción
# "de el": se escribe "que tiene el plan básico con X" en vez de "del plan básico de X".
# Un generador que produce español torcido delata que el corpus es sintético y, peor,
# mete ruido en los embeddings.
QUESTION_TEMPLATES: list[tuple[str, str]] = [
    ("lexica", "¿El código {code} está cubierto en {plan_art} de {insurer}?"),
    ("lexica", "{code} en {insurer}: ¿cuánto es el copago?"),
    ("lexica", "¿{insurer} pide autorización previa para el {code}?"),
    ("mixta", "¿{insurer} cubre {phrase} en {plan_art}?"),
    ("mixta", "Un paciente que tiene {plan_art} con {insurer} necesita {phrase}. "
              "¿Qué le cobramos?"),
    ("semantica", "Si a un paciente de {insurer} le vamos a quitar los brackets, "
                  "¿eso lo paga él o la prepagada?"),
    ("semantica", "¿Hay que pedirle permiso a {insurer} antes de empezar un tratamiento "
                  "o se puede facturar directo?"),
    ("semantica", "¿Qué pasa si el paciente de {insurer} cambia de plan a mitad del "
                  "tratamiento?"),
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=Path("corpus"))
    parser.add_argument("--semilla", type=int, default=20260913)
    parser.add_argument("--documentos", type=int, default=24)
    parser.add_argument("--preguntas", type=int, default=50)
    parser.add_argument(
        "--preguntas-salida",
        type=Path,
        default=Path("preguntas_anotadas.jsonl"),
        help="Dónde escribir las preguntas anotadas. Lo consumen ia04, ia05 e ia06.",
    )
    args = parser.parse_args()

    rng = random.Random(args.semilla)
    args.salida.mkdir(parents=True, exist_ok=True)

    manifest: list[dict[str, object]] = []
    annotated: list[dict[str, object]] = []
    chunk_id = 0

    for index in range(args.documentos):
        insurer, nit = INSURERS[index % len(INSURERS)]
        # El desfase con un primo evita que aseguradora y plan avancen al mismo ritmo:
        # con index % 4 en los dos, las combinaciones se repetían cada cuatro documentos
        # y los archivos se sobrescribían entre sí. El manifiesto decía 129 fragmentos y
        # en disco había 47. Un generador cuyo manifiesto miente es peor que no tenerlo.
        plan_with_article, plan = PLANS[(index * 3) % len(PLANS)]

        # Un tercio de los documentos son versiones derogadas del mismo anexo. Es el
        # caso del miniproyecto de ia05: casi idénticos, y solo los metadatos los
        # distinguen.
        superseded = index % 3 == 0
        version = "2025" if superseded else "2026"
        valid_from = date(2025, 1, 1) if superseded else date(2026, 3, 1)
        valid_to = date(2026, 2, 28) if superseded else None

        text, clauses = _build_document(
            rng,
            insurer=insurer,
            nit=nit,
            plan_with_article=plan_with_article,
            plan=plan,
            version=version,
            valid_from=valid_from,
            valid_to=valid_to,
        )

        slug = f"{insurer.lower().replace(' ', '-')}-{plan.replace(' ', '-')}"
        # El índice va en el nombre: dos anexos de la misma aseguradora, el mismo plan y
        # el mismo año existen de verdad —se renuevan a mitad de año— y tienen que poder
        # coexistir en disco.
        name = f"{index:02d}-{slug}-{version}.txt"
        (args.salida / name).write_text(text, encoding="utf-8")

        for clause in clauses:
            chunk_id += 1
            manifest.append(
                {
                    "fragmento": chunk_id,
                    "documento": name,
                    "titulo": f"Anexo {insurer} — {plan} v.{version}",
                    "aseguradora": insurer,
                    "plan": plan,
                    "plan_articulo": plan_with_article,
                    "clausula": f"Cláusula {clause.number}",
                    "nit": nit,
                    "vigente_desde": valid_from.isoformat(),
                    "vigente_hasta": valid_to.isoformat() if valid_to else None,
                    "codigo": clause.procedure_code,
                    "cubierto": clause.covered,
                    "copago": clause.copayment,
                    "autorizacion_previa": clause.requires_authorization,
                }
            )

    # Las preguntas se construyen SOBRE fragmentos vigentes: preguntar por uno derogado
    # sin decir la fecha no tiene respuesta correcta única, y eso no es un caso de
    # recuperación sino del miniproyecto de ia05.
    current = [row for row in manifest if row["vigente_hasta"] is None]

    for position in range(args.preguntas):
        row = current[position % len(current)]
        kind, template = QUESTION_TEMPLATES[position % len(QUESTION_TEMPLATES)]
        # Los campos salen del manifiesto, no de trocear el título con índices: un
        # `titulo.split(" ")[3:-1]` funciona hasta que una aseguradora tiene tres
        # palabras, y entonces falla en silencio produciendo preguntas absurdas.
        name, phrase = next(
            (n, ph) for c, n, ph in PROCEDURES if c == row["codigo"]
        )

        annotated.append(
            {
                "id": f"p{position + 1:03d}",
                "texto": template.format(
                    code=row["codigo"],
                    name=name,
                    phrase=phrase,
                    plan=row["plan"],
                    plan_art=row["plan_articulo"],
                    insurer=row["aseguradora"],
                ),
                "fragmento_correcto": row["fragmento"],
                "tipo": kind,
            }
        )

    (args.salida / "manifiesto.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    args.preguntas_salida.write_text(
        "\n".join(json.dumps(row, ensure_ascii=False) for row in annotated) + "\n",
        encoding="utf-8",
    )

    kinds = {kind for kind, _ in QUESTION_TEMPLATES}
    print(f"{args.documentos} documentos y {len(manifest)} fragmentos en {args.salida}/")
    print(f"{len(annotated)} preguntas anotadas ({', '.join(sorted(kinds))}) "
          f"en {args.preguntas_salida}")
    derogados = sum(1 for r in manifest if r["vigente_hasta"])
    print(f"Derogados: {derogados} fragmentos de {len(manifest)}")


if __name__ == "__main__":
    main()
