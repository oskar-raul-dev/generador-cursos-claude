"""El bucle de juego como modelo: mover por cuadro, por segundo, o con paso fijo; la misma partida a 30, 60 y 144 cuadros/s."""

SECONDS = 2.0


def per_frame(fps):
    """5 píxeles por cuadro: el error clásico. Más cuadros, más rápido."""
    x = 0.0
    for _ in range(int(SECONDS * fps)):
        x += 5
    return x


def per_second(fps):
    """300 px/s por dt: la misma distancia a cualquier tasa, mientras la física sea lineal."""
    x, dt = 0.0, 1 / fps
    for _ in range(int(SECONDS * fps)):
        x += 300 * dt
    return x


def falling(fps, fixed=None):
    """Una caída con gravedad (no lineal): con dt variable, el resultado depende de la tasa; con paso fijo, no."""
    y = v = 0.0
    if fixed is None:
        dt = 1 / fps
        for _ in range(int(SECONDS * fps)):
            y += v * dt                               # Euler explícito: primero la posición, después la velocidad
            v += 980 * dt
        return y
    accumulator, steps = 0.0, 0
    for _ in range(int(SECONDS * fps)):               # el bucle de "Fix Your Timestep": la física corre a su propio ritmo
        accumulator += 1 / fps
        while accumulator >= fixed - 1e-12:
            y += v * fixed
            v += 980 * fixed
            accumulator -= fixed
            steps += 1
    return y


print(f"{'cuadros/s':>10} {'por cuadro':>11} {'por segundo':>12} {'caída, dt variable':>19} {'caída, paso fijo 1/120':>23}")
for fps in (30, 60, 144):
    print(f"{fps:>10} {per_frame(fps):>9.0f} px {per_second(fps):>10.1f} px {falling(fps):>17.1f} px {falling(fps, 1 / 120):>21.1f} px")
print(f"caída exacta en {SECONDS:.0f} s: {0.5 * 980 * SECONDS ** 2:.1f} px")
