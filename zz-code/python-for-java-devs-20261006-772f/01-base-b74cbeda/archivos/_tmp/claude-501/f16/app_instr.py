"""La misma API, con instrumentación completa."""
import logging, sys
import structlog
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SpanExporter, SpanExportResult
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from app import app

class NullExporter(SpanExporter):
    """Exportador que descarta: mide el costo de INSTRUMENTAR, no el de la red."""
    def export(self, spans): return SpanExportResult.SUCCESS
    def shutdown(self): pass

provider = TracerProvider()
provider.add_span_processor(BatchSpanProcessor(NullExporter()))
trace.set_tracer_provider(provider)

f = open("api.log", "w")
structlog.configure(
    processors=[structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()

@app.middleware("http")
async def registrar(request, call_next):
    response = await call_next(request)
    log.info("peticion", ruta=request.url.path, metodo=request.method,
             estado=response.status_code)
    return response

FastAPIInstrumentor.instrument_app(app)
