"""El sábado de Chapinero en SimPy: dónde se forma la cola, y qué la arregla."""

import random
import statistics

import simpy

OPEN_MINUTES = 8 * 60
ARRIVAL_MEAN = 6.5          # un paciente cada 6,5 minutos en promedio
CHECKIN_MEAN = 6.0          # registro, abono y la pregunta de WhatsApp que interrumpe


def patient(env, front_desk, chairs, waits):
    arrived = env.now
    with front_desk.request() as turn:
        yield turn
        waits["recepción"].append(env.now - arrived)
        yield env.timeout(random.expovariate(1 / CHECKIN_MEAN))
    ready = env.now
    with chairs.request() as chair:
        yield chair
        waits["silla"].append(env.now - ready)
        yield env.timeout(random.lognormvariate(2.3, 0.4))      # atención en la silla: media ≈ 10,8 min


def arrivals(env, front_desk, chairs, waits):
    while env.now < OPEN_MINUTES:
        yield env.timeout(random.expovariate(1 / ARRIVAL_MEAN))
        env.process(patient(env, front_desk, chairs, waits))


def saturday(receptionists: int, n_chairs: int, seed: int) -> dict[str, list[float]]:
    random.seed(seed)
    env = simpy.Environment()
    front_desk, chairs = simpy.Resource(env, receptionists), simpy.Resource(env, n_chairs)
    waits = {"recepción": [], "silla": []}
    env.process(arrivals(env, front_desk, chairs, waits))
    env.run()
    return waits


def p90(values: list[float]) -> float:
    return statistics.quantiles(values, n=10)[-1]


for receptionists, n_chairs in [(1, 2), (1, 3), (2, 2)]:
    runs = [saturday(receptionists, n_chairs, seed) for seed in range(500)]
    desk = [w for r in runs for w in r["recepción"]]
    chair = [w for r in runs for w in r["silla"]]
    print(f"{receptionists} recepción, {n_chairs} sillas · espera en recepción: media {statistics.mean(desk):5.1f} min,"
          f" p90 {p90(desk):5.1f} · espera por silla: media {statistics.mean(chair):5.1f}, p90 {p90(chair):5.1f}")
