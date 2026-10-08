"""La liquidación Java llamada desde Python: JPype (en proceso) y Py4J (por socket), medidas."""

import time
from decimal import Decimal

import jpype
import jpype.imports
from py4j.java_gateway import JavaGateway


def per_call_us(fn, n: int) -> float:
    start = time.perf_counter()
    for _ in range(n):
        fn()
    return (time.perf_counter() - start) / n * 1e6


# ------------------------------------------------- JPype: la JVM dentro de Python
jpype.startJVM(classpath=["regalias.jar"])
from co.aurea import Regalias           # noqa: E402  — solo existe después de arrancar la JVM
from java.math import BigDecimal        # noqa: E402

result = Regalias.regalia(BigDecimal("142900000"), BigDecimal("0.045"))
print("JPype regalia:", result, type(result).__name__, "→", repr(Decimal(str(result))))
print("JPype franquicias:", list(Regalias.franquicias()), "·", type(Regalias.franquicias()).__name__)
jp = per_call_us(lambda: Regalias.regaliaPesos(142_900_000, 450), 100_000)

# ------------------------------------------------- Py4J: la JVM en otro proceso
gateway = JavaGateway.launch_gateway(classpath="regalias.jar", die_on_exit=True)
JRegalias = gateway.jvm.co.aurea.Regalias
big = gateway.jvm.java.math.BigDecimal
print("Py4J regalia:", JRegalias.regalia(big("142900000"), big("0.045")))
py4 = per_call_us(lambda: JRegalias.regaliaPesos(142_900_000, 450), 5_000)
gateway.shutdown()

# ------------------------------------------------- la misma cuenta en Python, como referencia
sales, bps = 142_900_000, 450                 # en variables: con constantes, Python precalcula la cuenta
py = per_call_us(lambda: (sales * bps + 5_000) // 10_000, 100_000)
print(f"por llamada: Python {py:.2f} µs · JPype {jp:.2f} µs · Py4J {py4:.0f} µs")
