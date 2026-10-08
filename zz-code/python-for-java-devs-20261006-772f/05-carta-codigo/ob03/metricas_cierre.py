"""Métricas de un proceso por lotes: histograma, contador por motivo y la hora del último éxito."""

import random
import time

from prometheus_client import CollectorRegistry, Counter, Gauge, Histogram, write_to_textfile

registry = CollectorRegistry()      # un registro propio: no se mezcla con las métricas del proceso

DURATION = Histogram(
    "cierre_sede_duration_seconds", "Duración del cierre de cada sede",
    buckets=(30, 60, 120, 300, 600, 1200, 1800), registry=registry,
)
REJECTED = Counter(
    "cierre_filas_rechazadas_total", "Filas rechazadas en el cierre",
    ["motivo"], registry=registry,                   # la etiqueta es el motivo, nunca el paciente
)
LAST_SUCCESS = Gauge(
    "cierre_ultimo_exito_timestamp_seconds", "Hora del último cierre completo",
    registry=registry,
)


def close_night(durations: dict[str, float], rejected: dict[str, int]) -> None:
    for branch, seconds in durations.items():
        DURATION.observe(seconds)
    for reason, count in rejected.items():
        REJECTED.labels(motivo=reason).inc(count)
    LAST_SUCCESS.set(time.time())                     # solo si llegó hasta aquí


def percentile_from_buckets(histogram: Histogram, q: float) -> float:
    """Lo que hace histogram_quantile de PromQL: interpolar dentro del bucket."""
    buckets = [(float(s.labels["le"]), s.value) for s in histogram.collect()[0].samples
               if s.name.endswith("_bucket")]
    total = buckets[-1][1]
    target, prev_bound, prev_count = q * total, 0.0, 0.0
    for bound, count in buckets:
        if count >= target:
            if bound == float("inf"):
                return prev_bound
            return prev_bound + (bound - prev_bound) * (target - prev_count) / (count - prev_count)
        prev_bound, prev_count = bound, count
    return prev_bound


if __name__ == "__main__":
    random.seed(7)
    sedes = {f"sede-{i}": random.uniform(90, 150) for i in range(9)} | {"Kennedy": 1700.0}
    close_night(sedes, {"sin_codigo": 35, "fecha_futura": 5})
    average = sum(sedes.values()) / len(sedes)
    print(f"promedio: {average:.0f} s · p50 ≈ {percentile_from_buckets(DURATION, 0.5):.0f} s"
          f" · p95 ≈ {percentile_from_buckets(DURATION, 0.95):.0f} s · máximo real: {max(sedes.values()):.0f} s")
    write_to_textfile("cierre.prom", registry)       # en producción: /var/lib/node_exporter/textfile/
    print(open("cierre.prom").read())
