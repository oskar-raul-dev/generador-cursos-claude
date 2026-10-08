"""Un servicio gRPC de prueba y su cliente: llamada unaria, streaming del servidor, plazos y su costo."""

import time
from concurrent import futures

import grpc

import agenda_pb2 as pb
import agenda_pb2_grpc as rpc


class Agenda(rpc.AgendaServicer):
    def ConsultarDisponibilidad(self, request, context):
        time.sleep(request.demora_ms / 1000)                       # para simular un servidor lento
        return pb.Disponibilidad(sede=request.sede, horas=["08:00", "08:20", "10:40"])

    def EventosDeSede(self, request, context):
        for i, kind in enumerate(["confirmada", "reprogramada", "cancelada"], start=1):
            yield pb.EventoCita(sede=request.sede, tipo=kind, secuencia=i)


server = grpc.server(futures.ThreadPoolExecutor(max_workers=8))
rpc.add_AgendaServicer_to_server(Agenda(), server)
port = server.add_insecure_port("127.0.0.1:0")
server.start()

with grpc.insecure_channel(f"127.0.0.1:{port}") as channel:
    stub = rpc.AgendaStub(channel)

    answer = stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba"), timeout=1)
    print("unaria:", answer.sede, list(answer.horas))

    print("streaming:", [(e.secuencia, e.tipo) for e in stub.EventosDeSede(pb.SedeRequest(sede="Suba"), timeout=2)])

    try:
        stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba", demora_ms=500), timeout=0.2)
    except grpc.RpcError as e:
        print("plazo de 0,2 s contra un servidor de 0,5 s:", e.code().name)

    start = time.perf_counter()
    for _ in range(500):
        stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba"), timeout=1)
    print(f"500 llamadas unarias: {(time.perf_counter() - start) / 500 * 1000:.2f} ms por llamada")

server.stop(grace=None)
