"""Tres mentiras visuales, medidas: el factor de mentira, la luminosidad de jet y el semáforo para un daltónico."""

import matplotlib
import numpy as np


# ------------------------------------------------- 1. el eje truncado
def lie_factor(a: float, b: float, axis_from: float) -> float:
    shown = (b - axis_from) / (a - axis_from)
    real = b / a
    return (shown - 1) / (real - 1)


suba, centro = 48_000_000, 52_000_000
for axis_from in (0, 40_000_000, 45_000_000):
    print(f"eje desde ${axis_from / 1e6:>4.0f} M: la barra del Centro se ve {(centro - axis_from) / (suba - axis_from):4.2f}"
          f" veces la de Suba (real {centro / suba:.2f}) · factor de mentira {lie_factor(suba, centro, axis_from):4.1f}")


# ------------------------------------------------- utilidades de color: sRGB → CIELAB
def to_linear(rgb: np.ndarray) -> np.ndarray:
    return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)


def linear_to_lab(lin: np.ndarray) -> np.ndarray:
    xyz = lin @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz = xyz / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > (6 / 29) ** 3, np.cbrt(xyz), xyz / (3 * (6 / 29) ** 2) + 4 / 29)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


# ------------------------------------------------- 2. la luminosidad de los mapas de color
for name in ("jet", "viridis"):
    rgb = matplotlib.colormaps[name](np.linspace(0, 1, 256))[:, :3]
    lightness = linear_to_lab(to_linear(rgb))[:, 0]
    reversals = int(np.sum(np.diff(np.sign(np.diff(lightness))) != 0))
    print(f"{name:<8} L* de {lightness[0]:5.1f} a {lightness[-1]:5.1f}, máximo {lightness.max():5.1f} · cambios de dirección: {reversals}")

# ------------------------------------------------- 3. el semáforo de vz03 visto con deuteranopía (Machado et al., 2009)
DEUTERANOPIA = np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]])
SEMAFORO = {"verde": "#2E7D32", "amarillo": "#F9A825", "rojo": "#C62828"}
rgb = np.array([[int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)] for h in SEMAFORO.values()])
normal = linear_to_lab(to_linear(rgb))
simulated = linear_to_lab(np.clip(to_linear(rgb) @ DEUTERANOPIA.T, 0, 1))
green, red = 0, 2
print(f"verde contra rojo: ΔE {np.linalg.norm(normal[green] - normal[red]):5.1f} con visión típica ·"
      f" {np.linalg.norm(simulated[green] - simulated[red]):5.1f} con deuteranopía")
