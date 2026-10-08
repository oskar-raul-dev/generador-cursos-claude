"""Pruebas del guardrail. Sin red, sin modelo, en milisegundos.

Es la pieza de la que depende que el proyecto sea defendible, así que es la que más
pruebas tiene. La asimetría de costos se refleja en las pruebas: hay más casos de
"esto tiene que escalar" que de "esto no", y el que más vale es
`test_ordinary_messages_do_not_escalate`, porque es el que atrapó el bug de la lista.
"""

from __future__ import annotations

import pytest

from guardrails import SYMPTOM_WORDS, has_clinical_image, mentions_symptom, normalize


@pytest.mark.parametrize(
    "message",
    [
        "se me soltó un bracket y me duele",
        "Buenas tardes, se me partió el retenedor",
        "me está doliendo mucho desde ayer",
        "tengo la encía sangrando",
        "se me ve hinchado el lado derecho",
        "no puedo masticar bien",
        "no aguanto el dolor",
        "creo que tengo una infección",
        "me duelé mucho",  # con el acento que pone el teclado del celular
        "SE ME CAYÓ LA CORONA",
    ],
)
def test_symptoms_escalate(message: str) -> None:
    decision = mentions_symptom(message)
    assert decision.escalate
    assert decision.reason == "sintoma"


@pytest.mark.parametrize(
    "message",
    [
        "Buenas, es normal que sangre al cepillarme?",  # síntoma + consejo: escala igual
        "¿qué me tomo para la molestia?",
        "será grave doctor?",
        "me preocupa lo que veo",
    ],
)
def test_advice_requests_escalate(message: str) -> None:
    assert mentions_symptom(message).escalate


@pytest.mark.parametrize(
    "message",
    [
        "Buenas, necesito cambiar mi control del jueves",
        "hola, me puedes correr la cita de mañana para la otra semana?",
        "no tienen algo el viernes por la tarde?",
        "Buenas, no voy a poder ir mañana, toca cancelar",
        "cuanto me sale ponerme una carilla?",
        "¿puedo hacer el control en Suba? me mudé",
        "Buenas! no me llegó el recordatorio, sigue en pie la cita?",
        "quiero saber si puedo pagar en cuotas",
    ],
)
def test_ordinary_messages_do_not_escalate(message: str) -> None:
    """La prueba que atrapó el bug de la lista.

    La primera versión escribía palabras y frases en una sola colección, como un literal
    de varias líneas al que se le aplicaba .split(). Ese split parte "no puedo comer" en
    tres términos sueltos, así que "no" quedaba como término de síntoma y SEIS de estos
    ocho mensajes escalaban. Un guardrail que escala todo es indistinguible de no tener
    agente.
    """
    decision = mentions_symptom(message)
    assert not decision.escalate, f"escaló por {decision.matched!r}"


def test_no_is_not_a_symptom_term() -> None:
    """Explícita, porque es el bug concreto y las regresiones de este tipo son silenciosas."""
    assert "no" not in SYMPTOM_WORDS
    assert "puedo" not in SYMPTOM_WORDS


def test_phrase_wins_over_word_because_it_is_more_informative() -> None:
    """Yuli lee el motivo en la bandeja: "no puedo masticar" le dice más que "dolor"."""
    decision = mentions_symptom("me duele y no puedo masticar")
    assert decision.matched == "no puedo masticar"


@pytest.mark.parametrize(
    "attachments, expected",
    [
        (["foto_boca.jpg"], True),
        (["comprobante_pago.PNG"], True),  # no se mira: mirarla ya sería procesarla
        (["IMG_4471.heic"], True),
        (["consentimiento.pdf"], False),
        ([], False),
    ],
)
def test_any_image_escalates(attachments: list[str], expected: bool) -> None:
    assert has_clinical_image(attachments).escalate is expected


def test_normalization_strips_accents_and_punctuation() -> None:
    assert normalize("¡Me DUELE mucho!") == "me duele mucho"
    assert normalize("se  me\nsoltó") == "se me solto"


def test_word_boundaries_do_not_match_inside_other_words() -> None:
    """"sal" no puede coincidir dentro de "salida", y "solto" no dentro de "soltura"."""
    assert not mentions_symptom("nos vemos a la salida").escalate
    assert not mentions_symptom("con mucha soltura").escalate


# --- El número que hace concreta la deuda 💸 -----------------------------------------

CONJUGACIONES = [
    "se me rompió la placa",
    "se me inflamó todo el cachete",
    "se me quebró un pedacito",
    "se me partió el retenedor",
]


@pytest.mark.parametrize("message", CONJUGACIONES)
def test_conjugations_are_covered(message: str) -> None:
    """Una lista de palabras necesita las conjugaciones, y se olvidan solas.

    Las dos primeras NO escalaban en la primera versión: la lista tenía "roto"/"rota"
    pero no "rompió", e "inflamado" pero no "inflamó". Las encontró el generador de
    `sintomas.jsonl` al medir, no la revisión a ojo — que es el argumento de por qué el
    conjunto de medición se escribe antes y no después.
    """
    assert mentions_symptom(message).escalate


SIN_VOCABULARIO = [
    "llevo dos días raro con la muela de arriba",
    "amanecí con la cara diferente del lado izquierdo",
    "siento como si el diente se fuera a salir",
    "algo no está bien desde que me pusieron el aparato",
]


@pytest.mark.parametrize("message", SIN_VOCABULARIO)
def test_the_lexical_guardrail_lets_these_through(message: str) -> None:
    """El límite del guardrail léxico, fijado como prueba en vez de como advertencia.

    Estos cuatro **tienen que escalar** y hoy no escalan. La prueba afirma el
    comportamiento actual a propósito: si alguien paga la deuda 💸 del clasificador
    (ejercicio 14) y estos empiezan a escalar, esta prueba falla y hay que venir a
    borrarla. Un límite conocido que rompe una prueba al desaparecer es mejor
    documentación que un comentario.

    Sobre los cuarenta mensajes de `generar_sintomas.py`, el guardrail léxico deja pasar
    los veinte que no usan su vocabulario: la mitad exacta.
    """
    assert not mentions_symptom(message).escalate


def test_the_polite_formula_escalates_and_that_is_the_right_call() -> None:
    """"Disculpe la molestia" escala, y se deja así a propósito.

    Es el único falso positivo del guardrail sobre las treinta solicitudes de ia03: en
    español colombiano "molestia" es a la vez un síntoma y una fórmula de cortesía. La
    tentación es quitar la palabra de la lista, y sería el error: "tengo una molestia al
    morder" dejaría de escalar, y con la asimetría de costos de esta sección eso cuesta
    dos órdenes de magnitud más que los treinta segundos que Yuli pierde leyendo un
    mensaje cortés.

    La refinación legítima —excluir las fórmulas exactas "disculpe/perdone la molestia"
    conservando la palabra suelta— es el ejercicio 3. Mientras no esté, el
    comportamiento correcto es este, y la prueba lo fija para que nadie lo "arregle".
    """
    decision = mentions_symptom(
        "Buenas tardes, disculpe la molestia, tengo el control el jueves y no puedo ir"
    )
    assert decision.escalate
    assert decision.matched == "molestia"
