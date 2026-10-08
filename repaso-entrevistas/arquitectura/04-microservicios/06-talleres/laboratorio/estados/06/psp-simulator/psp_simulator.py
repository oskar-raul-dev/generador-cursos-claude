#!/usr/bin/env python3
"""psp-simulator: el proveedor de pago externo del bloque 06 (el "mundo exterior").

No es un servicio del dominio: es el tercero lento con el que habla quien cobre. Solo biblioteca
estándar, para que arranque en cualquier sistema con Python 3.11+.

Regla determinista (§14 de la guía):
  total > 1000.00  → REJECTED
  total == 666.00  → AUTHORIZED, pero responde tarde (3 s): quien espere menos no sabe qué pasó,
                     y el cobro SÍ ocurrió. Es el "resultado incierto".
  resto            → AUTHORIZED

Idempotencia: si la petición trae `Idempotency-Key` y esa clave ya se vio, devuelve la respuesta
guardada con `Idempotent-Replay: true` y NO registra un cobro nuevo. Sin clave, cada petición es un
cobro distinto: es lo que permite ver el doble cobro del taller 03.

Rutas:
  POST /payments        {"orderId": "...", "amount": "49.90", "currency": "USD"}
  GET  /payments        los cobros registrados, en orden (la evidencia de "un solo cobro")
  POST /admin/reset     vacía el registro (lo llama `lab.py seed`)
  GET  /health
"""
import argparse
import json
import threading
import time
import uuid
from decimal import Decimal, InvalidOperation
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOCK = threading.Lock()
CHARGES = []          # cobros registrados: lo que el banco del cliente vería en su extracto
BY_KEY = {}           # Idempotency-Key → (status, body) ya respondido
SLOW_SECONDS = 3.0    # retraso del importe 666.00


class Handler(BaseHTTPRequestHandler):
    server_version = "psp-simulator/1.0"

    def _send(self, status, body, extra=None):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):  # una línea por petición, con la clave: es la evidencia
        key = self.headers.get("Idempotency-Key", "-")
        print(f"{time.strftime('%H:%M:%S')} {self.command} {self.path} key={key} → {args[1] if len(args) > 1 else ''}",
              flush=True)

    def do_GET(self):
        if self.path == "/health":
            return self._send(200, {"status": "UP"})
        if self.path == "/payments":
            with LOCK:
                return self._send(200, {"items": list(CHARGES)})
        self._send(404, {"error": "not found"})

    def _body(self):
        # HTTP/1.1 admite dos formas de delimitar el cuerpo: Content-Length o Transfer-Encoding:
        # chunked. El RestClient del monolito (cliente HTTP del JDK) usa la segunda; un servidor que
        # solo mira Content-Length lee un cuerpo vacío (06/01 §8).
        if "chunked" in (self.headers.get("Transfer-Encoding") or "").lower():
            raw = b""
            while True:
                size = int(self.rfile.readline().split(b";")[0].strip(), 16)
                if size == 0:
                    self.rfile.readline()          # CRLF final tras el trozo vacío
                    return raw
                raw += self.rfile.read(size)
                self.rfile.readline()              # CRLF que cierra cada trozo
        length = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(length) if length else b"{}"

    def do_POST(self):
        raw = self._body()
        if self.path == "/admin/reset":
            with LOCK:
                CHARGES.clear()
                BY_KEY.clear()
            return self._send(200, {"reset": True})
        if self.path != "/payments":
            return self._send(404, {"error": "not found"})
        try:
            req = json.loads(raw)
            amount = Decimal(str(req["amount"]))
            order_id = str(req["orderId"])
        except (ValueError, KeyError, InvalidOperation):
            return self._send(400, {"error": "orderId and amount (decimal string) are required"})

        key = self.headers.get("Idempotency-Key")
        if key:
            with LOCK:
                seen = BY_KEY.get(key)
            if seen:
                return self._send(seen[0], seen[1], {"Idempotent-Replay": "true"})

        status = "REJECTED" if amount > Decimal("1000.00") else "AUTHORIZED"
        body = {"status": status, "reference": f"psp-{uuid.uuid4().hex[:8]}",
                "orderId": order_id, "amount": f"{amount:.2f}"}
        with LOCK:
            if status == "AUTHORIZED":
                CHARGES.append({"reference": body["reference"], "orderId": order_id,
                                "amount": body["amount"], "idempotencyKey": key})
            if key:
                BY_KEY[key] = (201, body)
        if amount == Decimal("666.00"):
            time.sleep(SLOW_SECONDS)   # el cobro ya está registrado: responder tarde no lo deshace
        self._send(201, body)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=28085)
    args = parser.parse_args()
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print(f"psp-simulator escuchando en :{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
