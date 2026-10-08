"""Captura de errores con sentry-sdk: agrupación, versión y la frontera de datos en before_send."""

import re

import sentry_sdk
from sentry_sdk.transport import Transport

SENT: list[dict] = []
DOCUMENT = re.compile(r"\b\d{6,10}\b")          # cédulas: 6 a 10 dígitos


class CaptureTransport(Transport):
    """Transporte de prueba: guarda lo que se mandaría, en vez de mandarlo."""

    def capture_envelope(self, envelope):
        for item in envelope.items:
            if item.headers.get("type") == "event":
                SENT.append(item.payload.json)


def scrub(value):
    if isinstance(value, str):
        return DOCUMENT.sub("[documento]", value)
    if isinstance(value, dict):
        return {k: scrub(v) for k, v in value.items()}
    if isinstance(value, list):
        return [scrub(v) for v in value]
    return value


def before_send(event, hint):
    # La frontera de la historia clínica: nada de variables locales, y ningún documento en ningún texto.
    for exception in event.get("exception", {}).get("values", []):
        for frame in exception.get("stacktrace", {}).get("frames", []):
            frame.pop("vars", None)
    event.pop("request", None)
    return scrub(event)


sentry_sdk.init(
    dsn="https://clave-publica@sentry.aurea.example/3",
    transport=CaptureTransport,
    release="agenda-api@2026.10.05",     # cuándo empezó cada problema
    environment="produccion",
    send_default_pii=False,
    include_local_variables=True,        # útil para depurar… y por eso before_send las quita
    before_send=before_send,
)


def book(patient_document: str, branch: str | None) -> None:
    if branch is None:
        raise ValueError(f"la cita del paciente {patient_document} no tiene sede")


if __name__ == "__main__":
    for document in ("1023456789", "52987654"):
        try:
            book(document, None)
        except ValueError as error:
            sentry_sdk.capture_exception(error)
    sentry_sdk.flush()

    for event in SENT:
        exception = event["exception"]["values"][0]
        frames = exception["stacktrace"]["frames"]
        print(exception["type"], "·", exception["value"], "·", event["release"],
              "· variables locales:", any("vars" in f for f in frames))
