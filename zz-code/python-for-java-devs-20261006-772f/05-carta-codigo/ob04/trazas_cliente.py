"""Trazas del cierre: tramos a mano, httpx instrumentado y el traceparent que viaja en la petición."""

import time

import httpx
from opentelemetry import trace
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter

exporter = InMemorySpanExporter()           # en producción: OTLPSpanExporter hacia un colector
provider = TracerProvider(resource=Resource.create({"service.name": "cartera-cierre"}))
provider.add_span_processor(SimpleSpanProcessor(exporter))
trace.set_tracer_provider(provider)
# (global desactivado para la prueba)
tracer = trace.get_tracer("cartera.cierre")

seen_headers: list[str] = []


def agenda_api(request: httpx.Request) -> httpx.Response:
    seen_headers.append(request.headers.get("traceparent", "—"))   # lo que recibe el otro servicio
    time.sleep(0.05)
    return httpx.Response(200, json={"citas": 812})


def close_branch(branch: str, client: httpx.Client) -> None:
    with tracer.start_as_current_span("cierre_sede", attributes={"sede": branch}) as root:
        with tracer.start_as_current_span("leer_export") as span:
            time.sleep(0.02)
            span.set_attribute("filas", 4210)
        with tracer.start_as_current_span("consultar_agenda"):
            appointments = client.get("https://agenda.aurea.example/citas").json()["citas"]
        with tracer.start_as_current_span("conciliar"):
            time.sleep(0.01)
        root.set_attribute("citas", appointments)


if __name__ == "__main__":
    with httpx.Client(transport=httpx.MockTransport(agenda_api)) as client:
        HTTPXClientInstrumentor.instrument_client(client)
        close_branch("Kennedy", client)
    spans = exporter.get_finished_spans()
    by_id = {s.context.span_id: s for s in spans}
    for span in sorted(spans, key=lambda s: s.start_time):
        depth, parent = 0, span.parent
        while parent is not None:
            depth, parent = depth + 1, by_id[parent.span_id].parent
        ms = (span.end_time - span.start_time) / 1e6
        print(f"{'  ' * depth}{span.name:<22} {ms:6.1f} ms  {dict(span.attributes)}")
    print("traceparent recibido por AgendaAPI:", seen_headers[0])
    print("trace_id del cierre:              ", f"{spans[-1].context.trace_id:032x}")
