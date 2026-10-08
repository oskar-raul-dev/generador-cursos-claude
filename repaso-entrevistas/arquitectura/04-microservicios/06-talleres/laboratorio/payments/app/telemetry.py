"""OpenTelemetry para payments (taller 07).

Python está a medio camino entre Java y Go: no hay agente obligatorio, pero cada biblioteca popular
tiene su "instrumentor", que se activa con una línea. Lo que ninguna activa por ti: el consumidor de
Kafka de este servicio (se escribe en consumer.py) y el trace_id en los logs (el filtro de abajo).
"""
import logging
import os

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.psycopg import PsycopgInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

ENDPOINT = os.environ.get("PAYMENTS_OTLP", "")          # host:puerto del collector; vacío = sin trazas


def setup(service: str) -> bool:
    """Configura el SDK y las instrumentaciones de bibliotecas. Hay que llamarla ANTES de crear el pool
    de psycopg y el cliente httpx: se instrumenta al conectar y al construir, no después."""
    if not ENDPOINT:
        return False
    provider = TracerProvider(resource=Resource.create({"service.name": service}))
    # en lotes y en segundo plano, igual que en Go: exportar no bloquea la petición
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=ENDPOINT, insecure=True)))
    trace.set_tracer_provider(provider)
    HTTPXClientInstrumentor().instrument()               # inyecta traceparent en cada llamada al PSP
    PsycopgInstrumentor().instrument(enable_commenter=False)
    return True


class TraceIdFilter(logging.Filter):
    """Añade trace_id a cada línea de log: el puente entre el log y la traza."""

    def filter(self, record: logging.LogRecord) -> bool:
        ctx = trace.get_current_span().get_span_context()
        record.trace_id = format(ctx.trace_id, "032x")[:8] if ctx.is_valid else "-"
        return True
