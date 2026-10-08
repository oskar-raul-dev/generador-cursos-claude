"""Pruebas de la fusión de rangos. Sin Postgres y sin modelo.

`fuse_ranks` es una función pura precisamente para poder probar aquí la parte del
sistema que más fácil se escribe mal: combinar dos listas cuyos puntajes no son
comparables entre sí.
"""

from __future__ import annotations

from search import RRF_K, Hit, fuse_ranks


def hit(chunk_id: int, score: float = 0.0) -> Hit:
    return Hit(
        chunk_id=chunk_id,
        document_title=f"doc{chunk_id}",
        clause=None,
        content=f"contenido {chunk_id}",
        score=score,
    )


def test_agreement_wins() -> None:
    """Un fragmento que las dos listas ponen arriba gana a uno que solo aparece en una."""
    vectorial = [hit(1), hit(2), hit(3)]
    lexical = [hit(3), hit(1), hit(9)]
    fused = fuse_ranks([vectorial, lexical], k=3)
    assert [h.chunk_id for h in fused[:2]] == [1, 3]


def test_incomparable_scores_do_not_leak() -> None:
    """El puntaje de origen no influye: la léxica devuelve ts_rank ~0.06 y la vectorial ~0.9.

    Es el error que la fusión existe para evitar. Si el resultado cambiara al mover los
    puntajes de entrada, estaríamos sumando escalas distintas.
    """
    a = fuse_ranks([[hit(1, 0.99), hit(2, 0.98)], [hit(2, 0.06), hit(1, 0.05)]], k=2)
    b = fuse_ranks([[hit(1, 0.01), hit(2, 0.00)], [hit(2, 900.0), hit(1, 800.0)]], k=2)
    assert [h.chunk_id for h in a] == [h.chunk_id for h in b]


def test_score_is_the_fused_one() -> None:
    """El Hit que sale lleva el puntaje de la fusión, no el de ninguna de las dos listas."""
    fused = fuse_ranks([[hit(1, 0.9)], [hit(1, 0.06)]], k=1)
    assert fused[0].score == 2 / (RRF_K + 1)


def test_empty_lexical_list_is_not_an_error() -> None:
    """Pasa a diario: la pregunta en prosa no comparte ni una palabra con el corpus."""
    fused = fuse_ranks([[hit(4), hit(5)], []], k=5)
    assert [h.chunk_id for h in fused] == [4, 5]


def test_both_empty_returns_nothing() -> None:
    """El caso que la sección defiende: no encontrar nada es una respuesta legítima."""
    assert fuse_ranks([[], []], k=5) == []


def test_ties_break_deterministically() -> None:
    """Dos fragmentos con el mismo puntaje fusionado no pueden alternar entre corridas.

    Sin el desempate por id, el orden depende del recorrido del diccionario y el
    criterio de idempotencia del miniproyecto de ia02 se cae aquí.
    """
    first = fuse_ranks([[hit(7), hit(8)], [hit(8), hit(7)]], k=2)
    second = fuse_ranks([[hit(8), hit(7)], [hit(7), hit(8)]], k=2)
    assert [h.chunk_id for h in first] == [h.chunk_id for h in second] == [7, 8]
