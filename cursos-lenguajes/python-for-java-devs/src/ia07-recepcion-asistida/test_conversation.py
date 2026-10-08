"""Pruebas del estado del hilo y de la revisión de salida. Sin red y sin modelo."""

from __future__ import annotations

import pytest

from conversation import Conversation, EscalatedThread, State
from outbound import check_outbound


def test_a_new_thread_can_be_handled() -> None:
    assert Conversation(thread_id="t1").can_be_handled_by_agent()


def test_escalated_thread_never_comes_back() -> None:
    """Criterio 3 del miniproyecto: ni con tres mensajes inocentes después."""
    conversation = Conversation(thread_id="t1")
    conversation.escalate("sintoma")

    for _ in range(3):
        assert not conversation.can_be_handled_by_agent()
        assert conversation.state is State.ESCALATED


def test_agent_cannot_write_in_an_escalated_thread() -> None:
    conversation = Conversation(thread_id="t1")
    conversation.escalate("imagen")

    with pytest.raises(EscalatedThread) as error:
        conversation.record("agent", "Te propongo el jueves a las 3:40")
    assert "con una persona" in str(error.value)


def test_a_person_can_still_write_in_an_escalated_thread() -> None:
    """Yuli sí escribe: la barrera es para el agente, no para el hilo."""
    conversation = Conversation(thread_id="t1")
    conversation.escalate("consejo")
    conversation.record("human", "Hola, soy Yuli del Centro, cuéntame qué pasó")
    assert conversation.turns[-1][0] == "human"


def test_there_is_no_de_escalate() -> None:
    """Explícito: la ausencia es la decisión de diseño, y una prueba la fija."""
    assert not hasattr(Conversation(thread_id="t1"), "de_escalate")


@pytest.mark.parametrize(
    "reply, category",
    [
        ("Tómate un ibuprofeno y nos vemos el lunes", "indicación clínica"),
        ("Eso es normal después de una calza", "indicación clínica"),
        ("Ponte hielo en la zona mientras tanto", "indicación clínica"),
        ("Va a quedar perfecto, te lo garantizo", "promesa de resultado"),
        ("Tranquila que no te va a doler", "promesa de resultado"),
        ("Listo, tu cita queda confirmada para el jueves", "compromiso que no puede hacer"),
    ],
)
def test_forbidden_replies_are_blocked(reply: str, category: str) -> None:
    result = check_outbound(reply)
    assert result is not None, f"no bloqueó: {reply!r}"
    assert result[0] == category


@pytest.mark.parametrize(
    "reply",
    [
        "Te propongo el jueves a las 3:40 en Suba. Una auxiliar te confirma en un momento.",
        "El control mensual en el Centro está en $180.000 de lista.",
        "Aparté provisionalmente las 4:20 del viernes; falta que lo confirme el equipo.",
        "En Zipaquirá no tenemos agenda digital, hay que llamar a la sede.",
    ],
)
def test_ordinary_replies_pass(reply: str) -> None:
    assert check_outbound(reply) is None


def test_patterns_are_written_without_accents() -> None:
    """El error silencioso del archivo: un patrón con tilde compila y no coincide nunca.

    `check_outbound` normaliza antes de buscar, así que los patrones tienen que estar
    escritos sin tildes. Esta prueba falla si alguien "corrige" la ortografía de un
    patrón, que es exactamente lo que alguien va a querer hacer.
    """
    assert check_outbound("Tómate algo para el dolor") is not None
