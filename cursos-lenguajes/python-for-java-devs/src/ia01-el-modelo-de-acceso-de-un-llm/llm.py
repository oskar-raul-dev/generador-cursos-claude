"""Cliente del modelo para las herramientas de Áurea.

Es la única puerta por la que el código del track habla con la API. Todo lo que
importe —modelo, presupuesto de tiempo, reintentos, registro— se decide aquí.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal

import anthropic

from pricing import CATALOG, ModelPricing

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "claude-opus-5"

# El timeout es alto a propósito. Un modelo que razona puede tardar minutos en una
# pregunta difícil, y cortarlo antes no ahorra dinero: la generación siguió del otro
# lado y se cobró igual. Lo que se acota con timeout bajo es la experiencia de usuario,
# y eso se resuelve transmitiendo en flujo, no cancelando.
DEFAULT_TIMEOUT_SECONDS = 120.0

# Reintentos del SDK: cubre 408, 409, 429, 5xx y errores de conexión, con backoff
# exponencial. No se escribe un bucle encima; ver la sección 4 de la lección.
DEFAULT_MAX_RETRIES = 3


@dataclass(frozen=True, slots=True)
class Answer:
    """Lo que devuelve una consulta al modelo, con su factura pegada.

    El costo viaja con la respuesta y no en un contador global: una respuesta que no
    sabe lo que costó es una respuesta que nadie va a poder auditar en el cierre de mes.
    """

    text: str
    model: str
    input_tokens: int
    output_tokens: int
    cached_input_tokens: int
    cost: Decimal
    stop_reason: str
    request_id: str | None


class ModelRefusedError(RuntimeError):
    """El modelo declinó contestar. No es un error de red y no se reintenta igual."""


def build_client(
    *,
    timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS,
    max_retries: int = DEFAULT_MAX_RETRIES,
) -> anthropic.Anthropic:
    """Construye el cliente.

    Sin argumento de clave: las credenciales se resuelven por entorno. Pasar la clave
    por parámetro invita a que alguien la escriba en una llamada, y esa llamada termina
    en el historial de git.
    """
    return anthropic.Anthropic(timeout=timeout_seconds, max_retries=max_retries)


def ask(
    client: anthropic.Anthropic,
    question: str,
    *,
    system: str | None = None,
    model: str = DEFAULT_MODEL,
    max_tokens: int = 4096,
) -> Answer:
    """Hace una pregunta y devuelve la respuesta con su costo.

    Lanza las excepciones del SDK sin envolverlas: quien llama necesita distinguir un
    429 de un 400, y una jerarquía propia encima solo borraría esa distinción.
    """
    pricing: ModelPricing = CATALOG[model]

    # El sistema se arma aparte en vez de pasar None: el SDK distingue "no lo mandes"
    # de "mándalo vacío", y un system vacío cuenta tokens y cambia el prefijo de caché.
    extra: dict[str, str] = {"system": system} if system is not None else {}

    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": question}],
        **extra,
    )

    # Primero el motivo de parada, antes de tocar el contenido. Una negativa devuelve
    # 200 con contenido vacío: si lees el texto sin mirar esto, procesas un vacío como
    # si fuera una respuesta buena, y ese es el fallo silencioso de la sección.
    if response.stop_reason == "refusal":
        detail = response.stop_details
        category = detail.category if detail is not None else "sin categoría"
        raise ModelRefusedError(f"El modelo declinó la petición ({category}).")

    if response.stop_reason == "max_tokens":
        # No es un error: es una respuesta cortada a mitad de frase. Se avisa, porque
        # el código de arriba puede estar a punto de guardarla como si estuviera completa.
        logger.warning(
            "Respuesta truncada por max_tokens (%d). El texto está incompleto.",
            max_tokens,
        )

    text = "".join(block.text for block in response.content if block.type == "text")

    usage = response.usage
    # Los tokens leídos de caché se cobran a una fracción del precio. En esta sección
    # siempre van a ser cero porque todavía no cacheamos nada; se registran desde ahora
    # para que la medición de ia08 tenga con qué comparar.
    cached = usage.cache_read_input_tokens or 0
    cost = pricing.cost_of(usage.input_tokens + cached, usage.output_tokens)

    logger.info(
        "modelo=%s entrada=%d salida=%d costo=%s parada=%s peticion=%s",
        model,
        usage.input_tokens,
        usage.output_tokens,
        cost,
        response.stop_reason,
        response._request_id,
    )

    return Answer(
        text=text,
        model=response.model,
        input_tokens=usage.input_tokens,
        output_tokens=usage.output_tokens,
        cached_input_tokens=cached,
        cost=cost,
        stop_reason=response.stop_reason or "end_turn",
        request_id=response._request_id,
    )
