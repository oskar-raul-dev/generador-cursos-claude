# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "orjson"]
# ///
import sys

import orjson

ventas = orjson.loads(sys.argv[1] if len(sys.argv) > 1 else '{"Suba": 142900000, "Zipaquirá": 61750000}')
print(orjson.dumps({sede: round(v * 0.045) for sede, v in ventas.items()}).decode())
