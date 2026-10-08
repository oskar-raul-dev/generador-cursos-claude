"""La misma reserva por HTTP y por gRPC, contra el mismo servicio y la misma base (taller 04).

Reproducción local, un solo nodo, sin red real, un cliente secuencial: mide el coste de protocolo y
serialización de ESTE servicio en ESTA máquina. No mide concurrencia, red de centro de datos, TLS ni
tamaños de mensaje grandes, y no se extrapola a "gRPC es N veces más rápido" (02/04 §3).

Los stubs de Python se generan al vuelo del mismo .proto que usan Go y Java (contrato/proto).
"""
import argparse
import statistics
import sys
import time
import uuid
from pathlib import Path

import grpc
import httpx
from grpc_tools import protoc

HERE = Path(__file__).resolve().parent
PROTO = HERE.parent.parent / "contrato" / "proto"
GEN = HERE / "gen"


def stubs():
    GEN.mkdir(exist_ok=True)
    target = GEN / "ms" / "inventory" / "v1" / "inventory_pb2.py"
    if not target.exists():
        rc = protoc.main(["protoc", f"-I{PROTO}", f"--python_out={GEN}", f"--grpc_python_out={GEN}",
                          str(PROTO / "ms" / "inventory" / "v1" / "inventory.proto")])
        if rc != 0:
            sys.exit("protoc falló")
    sys.path.insert(0, str(GEN))
    from ms.inventory.v1 import inventory_pb2, inventory_pb2_grpc
    return inventory_pb2, inventory_pb2_grpc


def measure(label, fn, n, warmup):
    for _ in range(warmup):
        fn()
    samples = []
    for _ in range(n):
        t0 = time.perf_counter()
        fn()
        samples.append((time.perf_counter() - t0) * 1000)
    samples.sort()
    q = lambda p: samples[min(len(samples) - 1, int(p * len(samples)))]
    print(f"{label:6} n={n}  p50 {q(0.50):6.2f} ms   p90 {q(0.90):6.2f} ms   p99 {q(0.99):6.2f} ms   media {statistics.fmean(samples):6.2f} ms")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--n", type=int, default=300)
    ap.add_argument("--warmup", type=int, default=30)
    ap.add_argument("--http", default="http://localhost:28083")
    ap.add_argument("--grpc", default="localhost:28093")
    args = ap.parse_args()
    pb2, pb2_grpc = stubs()

    http = httpx.Client(base_url=args.http, timeout=2.0)            # conexión reutilizada (keep-alive)
    def via_http():
        ref = str(uuid.uuid4())
        http.post("/holds", json={"reference": ref, "items": [{"sku": "SKU-002", "qty": 1}]}).raise_for_status()
        http.post(f"/holds/{ref}/release").raise_for_status()

    channel = grpc.insecure_channel(args.grpc)                       # un canal HTTP/2, reutilizado
    stub = pb2_grpc.InventoryServiceStub(channel)
    def via_grpc():
        ref = str(uuid.uuid4())
        stub.Hold(pb2.HoldRequest(reference=ref, items=[pb2.HoldItem(sku="SKU-002", qty=1)]), timeout=2.0)
        stub.Release(pb2.ReleaseRequest(reference=ref), timeout=2.0)

    print("retener y liberar 1 × SKU-002, secuencial; cada muestra = 2 llamadas")
    measure("HTTP", via_http, args.n, args.warmup)
    measure("gRPC", via_grpc, args.n, args.warmup)


if __name__ == "__main__":
    main()
