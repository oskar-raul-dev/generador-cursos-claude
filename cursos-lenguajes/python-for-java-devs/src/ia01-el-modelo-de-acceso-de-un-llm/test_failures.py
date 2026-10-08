"""Los cuatro fallos que vas a ver en producción, provocados a propósito.

Se marcan como pruebas de red: no corren en el ciclo normal. Existen para que la
primera vez que veas cada uno no sea a las dos de la mañana.

    uv run pytest test_failures.py -m network
"""

import anthropic
import pytest

from llm import ask, build_client

pytestmark = pytest.mark.network


def test_context_too_large_fails_fast() -> None:
    """Pasarse del contexto es un 400: no se reintenta y hay que detectarlo antes."""
    client = build_client(max_retries=0)
    huge_question = "hola " * 400_000

    with pytest.raises(anthropic.BadRequestError):
        ask(client, huge_question)


def test_timeout_does_not_cancel_the_generation() -> None:
    """El timeout es del cliente. Del otro lado la respuesta se generó y se cobró."""
    client = anthropic.Anthropic(timeout=0.5, max_retries=0)

    with pytest.raises(anthropic.APITimeoutError):
        ask(client, "Escribe un resumen de 2.000 palabras sobre ortodoncia.")

    # 🧨 Rompe a propósito: mira la consola de uso después de correr esto. Los tokens
    # de esa respuesta que nunca viste están facturados. Ese es el punto de la prueba.


# Los otros dos no se provocan con una prueba automática, y el porqué está en la
# sección 5.5 de la lección:
#
#   429      — forzarlo consume la cuota de toda la organización y perjudica a lo demás
#              que esté corriendo. El SDK ya lo reintenta respetando `retry-after`.
#   refusal  — depende de pedirle al modelo algo que no debería hacer, que no es
#              material de curso. En `llm.ask` está la rama que lo detecta; en ia07 esa
#              rama escala a una persona, que es la respuesta correcta.
