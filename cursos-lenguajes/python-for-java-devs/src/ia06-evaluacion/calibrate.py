"""Pago de la deuda 💸 de ia04: el umbral de distancia sale de los datos.

En ia04 el umbral era 0.35 «por intuición», y estaba declarado como deuda. Aquí se
deriva: se corre la recuperación sobre el conjunto anotado, se miran las distancias de
los aciertos y las de los fallos, y se elige el corte que mejor los separa.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class ThresholdReport:
    """El umbral elegido, y lo que cuesta elegirlo así."""

    threshold: float
    recall_kept: float  # aciertos que sobreviven al corte
    noise_removed: float  # fallos que el corte elimina
    considered: int


def choose_threshold(
    hit_distances: list[float],
    miss_distances: list[float],
    *,
    min_recall: float = 0.95,
) -> ThresholdReport:
    """Elige el corte más estricto que conserve `min_recall` de los aciertos.

    El criterio no es "el que maximiza la exactitud": es asimétrico a propósito, porque
    los dos errores cuestan distinto. Perder un fragmento correcto hace que NormaRAG se
    abstenga de algo que sabía —Patricia deja de usarlo—; dejar pasar uno irrelevante lo
    filtra después la verificación de citas de ia05. Se prioriza no perder aciertos.
    """
    if not hit_distances:
        raise ValueError("Sin aciertos anotados no se puede calibrar nada.")

    candidates = sorted(set(hit_distances + miss_distances))
    best = ThresholdReport(
        threshold=max(candidates),
        recall_kept=1.0,
        noise_removed=0.0,
        considered=len(candidates),
    )

    for threshold in candidates:
        kept = sum(1 for distance in hit_distances if distance <= threshold) / len(hit_distances)
        if kept < min_recall:
            continue

        removed = (
            sum(1 for distance in miss_distances if distance > threshold) / len(miss_distances)
            if miss_distances
            else 0.0
        )
        if removed > best.noise_removed or (
            removed == best.noise_removed and threshold < best.threshold
        ):
            best = ThresholdReport(
                threshold=threshold,
                recall_kept=kept,
                noise_removed=removed,
                considered=len(candidates),
            )

    return best
