"""El conjunto de evaluación: un activo versionado, no un archivo de pruebas.

Lo escribe una persona que sabe de coberturas. Cuesta más que el código que prueba y
dura más: el sistema se va a reescribir dos veces y el conjunto va a seguir sirviendo.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

# Desarrollo: contra este se itera. Retención: se toca lo mínimo posible, y es el que
# dice la verdad. Si iteras contra el de retención, en veinte vueltas tu sistema estará
# ajustado a cincuenta preguntas y no al problema de Patricia.
Split = Literal["desarrollo", "retencion"]


@dataclass(frozen=True, slots=True)
class EvalCase:
    """Un caso: la pregunta, lo que debería contestar, y por qué está en el conjunto."""

    case_id: str
    question: str
    # Escrita por una persona. Una respuesta de referencia generada por otro modelo
    # convierte la evaluación en un espejo: mide el parecido con ese modelo.
    reference_answer: str
    # Fragmento que debería recuperarse. Permite reusar las métricas de ia04 sobre el
    # mismo conjunto y separar el fallo de recuperación del de generación.
    expected_chunk_id: int | None
    # Qué se está probando con este caso. Sin esto, en seis meses nadie sabe por qué
    # está aquí ni si se puede borrar.
    rationale: str
    split: Split
    # True cuando lo correcto es NO contestar. Son los casos más valiosos del conjunto
    # y los que casi nadie incluye.
    should_abstain: bool = False


@dataclass(frozen=True, slots=True)
class EvalSet:
    """El conjunto completo, con su huella."""

    cases: list[EvalCase]
    fingerprint: str

    def split(self, which: Split) -> list[EvalCase]:
        return [case for case in self.cases if case.split == which]

    def abstention_cases(self, which: Split | None = None) -> list[EvalCase]:
        """Los casos donde lo correcto es no contestar.

        Se reportan aparte (criterio 6 del miniproyecto): un sistema que mejora
        contestando más y absteniéndose menos puede estar empeorando, y el agregado
        lo esconde.
        """
        cases = self.cases if which is None else self.split(which)
        return [case for case in cases if case.should_abstain]


def load(path: Path) -> EvalSet:
    """Carga el conjunto y calcula su huella.

    La huella entra en todos los informes: dos números producidos con conjuntos
    distintos no son comparables, y sin la huella nadie se da cuenta de que lo son.
    """
    raw = path.read_bytes()
    fingerprint = hashlib.sha256(raw).hexdigest()[:12]

    cases = [
        EvalCase(
            case_id=record["id"],
            question=record["pregunta"],
            reference_answer=record["respuesta_referencia"],
            expected_chunk_id=record.get("fragmento_esperado"),
            rationale=record["por_que"],
            split=record["particion"],
            should_abstain=record.get("debe_abstenerse", False),
        )
        for record in (
            json.loads(line) for line in raw.decode("utf-8").splitlines() if line.strip()
        )
    ]

    return EvalSet(cases=cases, fingerprint=fingerprint)
