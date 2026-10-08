"""El costo de una frontera HTTP con un servicio Java: llamada por llamada, en lote, y la equivalencia."""

import os
import random
import time
from decimal import ROUND_HALF_EVEN, Decimal

import httpx

BASE = os.environ.get("AUREA_JAVA", "http://127.0.0.1:8090")
RATE = "0.045"
random.seed(17)
sales = [Decimal(random.randrange(10_000_000, 500_000_000)) / 100 for _ in range(100_000)]

with httpx.Client(base_url=BASE) as client:                 # conexión reutilizada (keep-alive)
    for _ in range(50):
        try:
            client.get("/regalia", params={"ventas": "1", "tasa": RATE})
            break
        except httpx.ConnectError:
            time.sleep(0.2)

    n = 2_000
    start = time.perf_counter()
    single = [Decimal(client.get("/regalia", params={"ventas": str(s), "tasa": RATE}).text) for s in sales[:n]]
    per_call = (time.perf_counter() - start) / n * 1e6

    start = time.perf_counter()
    response = client.post("/regalias", params={"tasa": RATE}, content="\n".join(str(s) for s in sales))
    batch = [Decimal(line) for line in response.text.splitlines()]
    per_item = (time.perf_counter() - start) / len(sales) * 1e6

python_side = [(s * Decimal(RATE)).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN) for s in sales]
print(f"HTTP, una llamada por regalía: {per_call:7.1f} µs por regalía ({n} llamadas)")
print(f"HTTP, en lote:                 {per_item:7.1f} µs por regalía ({len(sales)} en una llamada)")
print("diferencias Java contra Python:", sum(a != b for a, b in zip(batch, python_side)), "de", len(sales),
      "· sueltas contra lote:", sum(a != b for a, b in zip(single, batch)))
