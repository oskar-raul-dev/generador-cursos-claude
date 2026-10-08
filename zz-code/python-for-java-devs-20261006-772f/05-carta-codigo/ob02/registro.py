"""logging configurado de verdad: todo en JSON, con el request_id, también lo de las bibliotecas."""

import logging
import logging.config
import uuid

import httpx
import structlog

# La cadena compartida: la usan los registros propios y los de logging por igual.
SHARED = [
    structlog.contextvars.merge_contextvars,          # el contexto de la petición, en todas las líneas
    structlog.stdlib.add_logger_name,
    structlog.stdlib.add_log_level,
    structlog.processors.TimeStamper(fmt="iso", utc=True),
]


def configure(level: str = "INFO") -> None:
    logging.config.dictConfig({
        "version": 1,
        "disable_existing_loggers": False,            # no apagar los loggers que las bibliotecas ya crearon
        "formatters": {
            "json": {
                "()": structlog.stdlib.ProcessorFormatter,
                "foreign_pre_chain": SHARED,          # lo que viene de logging pasa por la misma cadena
                "processors": [
                    structlog.stdlib.ProcessorFormatter.remove_processors_meta,
                    structlog.processors.JSONRenderer(ensure_ascii=False),
                ],
            },
        },
        "handlers": {"console": {"class": "logging.StreamHandler", "formatter": "json"}},
        "root": {"handlers": ["console"], "level": level},
        "loggers": {
            "httpx": {"level": "INFO"},
            "httpcore": {"level": "WARNING"},         # el detalle de las conexiones, solo si algo falla
        },
    })
    structlog.configure(
        processors=[*SHARED, structlog.stdlib.ProcessorFormatter.wrap_for_formatter],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )


def handle_request(client: httpx.Client) -> None:
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(request_id=uuid.uuid4().hex[:8], branch="Suba")
    log = structlog.get_logger("cartera.radicacion")
    log.info("radicación iniciada", invoices=12)
    client.get("https://api.prepagada.example/v2/glosas")        # httpx registra la petición
    logging.getLogger("cartera.legacy").warning("código viejo que usa logging directo")


if __name__ == "__main__":
    configure()
    transport = httpx.MockTransport(lambda request: httpx.Response(200, json=[]))
    with httpx.Client(transport=transport) as client:
        handle_request(client)
