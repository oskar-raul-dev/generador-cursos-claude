"""Servidor de pruebas que falla a propósito, para la Fase 13.

Imita a los tres socios de Áurea que reciben los webhooks de disponibilidad.
No es código a imitar: es un sistema ajeno, con los fallos que tienen los
sistemas ajenos de verdad.

Uso:
    python socio_falible.py [--puerto 8099] [--semilla 2026]

Comportamiento por ruta:
  /lento          responde bien, pero tarda entre 2 y 6 segundos
  /intermitente   uno de cada tres intentos devuelve 500
  /truncado       responde 200 con el cuerpo cortado: JSON inválido
  /mentiroso      responde 200 SIEMPRE y no procesa nada (el peor de todos)
  /firmado        exige la cabecera X-Firma correcta; si no, 401
  /idempotente    respeta la cabecera Idempotency-Key y no duplica

Todas las rutas registran lo que recibieron en memoria, y GET /_recibidos
devuelve el registro para poder auditar qué llegó de verdad.
"""

import argparse
import hashlib
import hmac
import json
import random
import threading
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SECRET = b"el-secreto-que-comparten-aurea-y-el-socio"
received: dict[str, list[dict]] = defaultdict(list)
processed_keys: dict[str, str] = {}
attempts: dict[str, int] = defaultdict(int)
lock = threading.Lock()


class SocioHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        """Silencio: el ruido del servidor estorba en la medición."""

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    def _respond(self, code: int, payload: dict, truncate: bool = False) -> None:
        body = json.dumps(payload).encode()
        if truncate:
            # Cuerpo cortado a la mitad, con su Content-Length correcto: el
            # cliente recibe un 200 con un JSON que no se puede parsear.
            # (Una truncadura de verdad, donde el Content-Length miente, se
            # manifiesta como un timeout de lectura en vez de como JSON
            # inválido. Las dos existen; esta es la que se puede provocar de
            # forma determinista.)
            body = body[: len(body) // 2]
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/_recibidos":
            with lock:
                payload = {k: len(v) for k, v in received.items()}
                payload["_claves_procesadas"] = len(processed_keys)
            self._respond(200, payload)
        elif self.path == "/_reiniciar":
            with lock:
                received.clear()
                processed_keys.clear()
                attempts.clear()
            self._respond(200, {"ok": True})
        else:
            self._respond(404, {"error": "no existe"})

    def do_POST(self):
        body = self._read_body()
        route = self.path.split("?")[0]

        with lock:
            attempts[route] += 1
            attempt = attempts[route]

        if route == "/lento":
            time.sleep(random.uniform(2.0, 6.0))
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/intermitente":
            if attempt % 3 == 0:
                self._respond(500, {"error": "error interno del socio"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/truncado":
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True, "detalle": "x" * 400}, truncate=True)

        elif route == "/mentiroso":
            # Responde 200 y NO guarda nada. Es el fallo más difícil de detectar.
            self._respond(200, {"ok": True})

        elif route == "/firmado":
            expected = hmac.new(SECRET, body, hashlib.sha256).hexdigest()
            if not hmac.compare_digest(self.headers.get("X-Firma", ""), expected):
                self._respond(401, {"error": "firma inválida"})
                return
            with lock:
                received[route].append(json.loads(body or b"{}"))
            self._respond(200, {"ok": True})

        elif route == "/idempotente":
            key = self.headers.get("Idempotency-Key", "")
            with lock:
                if key and key in processed_keys:
                    self._respond(200, {"ok": True, "repetido": True})
                    return
                received[route].append(json.loads(body or b"{}"))
                if key:
                    processed_keys[key] = "ok"
            # Falla una de cada tres DESPUÉS de haber procesado: el caso que
            # obliga a que el emisor reintente sobre algo ya hecho.
            if attempt % 3 == 0:
                self._respond(500, {"error": "falló al responder, pero ya procesé"})
                return
            self._respond(200, {"ok": True})

        else:
            self._respond(404, {"error": "no existe"})


def main() -> None:
    parser = argparse.ArgumentParser(description="Socio que falla a propósito.")
    parser.add_argument("--puerto", type=int, default=8099)
    parser.add_argument("--semilla", type=int, default=2026)
    args = parser.parse_args()

    random.seed(args.semilla)
    server = ThreadingHTTPServer(("127.0.0.1", args.puerto), SocioHandler)
    print(f"socio falible escuchando en http://127.0.0.1:{args.puerto}")
    server.serve_forever()


if __name__ == "__main__":
    main()
