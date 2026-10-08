"""OpenCV contra scikit-image con el mismo trabajo, el BGR de OpenCV, y una insignia en SVG y en cairo."""

import os
import time

import cairo
import cv2
import drawsvg
import numpy as np
from PIL import Image
from skimage import feature, filters

# Una imagen de muestra: figuras con ruido, 2000×2000 en grises
rng = np.random.default_rng(42)
img = np.zeros((2000, 2000), dtype=np.uint8)
cv2.rectangle(img, (300, 300), (900, 1100), 200, -1)
cv2.circle(img, (1400, 1200), 400, 140, -1)
img = cv2.add(img, rng.integers(0, 40, img.shape, dtype=np.uint8))


def best(fn, n=3):
    times = []
    for _ in range(n):
        start = time.perf_counter(); result = fn(); times.append(time.perf_counter() - start)
    return result, min(times) * 1000


edges_cv, ms_cv = best(lambda: cv2.Canny(cv2.GaussianBlur(img, (0, 0), 2), 50, 150))
edges_sk, ms_sk = best(lambda: feature.canny(filters.gaussian(img, sigma=2), low_threshold=0.05, high_threshold=0.15))
print(f"OpenCV      {ms_cv:6.1f} ms · salida {edges_cv.dtype}, valores {np.unique(edges_cv).tolist()}, bordes {int((edges_cv > 0).sum()):,}")
print(f"scikit-image {ms_sk:5.1f} ms · salida {edges_sk.dtype}, valores {np.unique(edges_sk).tolist()}, bordes {int(edges_sk.sum()):,}")
print(f"filters.gaussian devuelve {filters.gaussian(img, sigma=2).dtype} en [0, 1], no uint8")

# El BGR de OpenCV: un rojo en RGB, escrito con cv2.imwrite y leído con Pillow
red_rgb = np.zeros((10, 10, 3), dtype=np.uint8); red_rgb[..., 0] = 255
cv2.imwrite("rojo.png", red_rgb)
print("rojo RGB escrito con OpenCV, leído con Pillow:", Image.open("rojo.png").getpixel((0, 0)))

# La misma insignia como vector (drawsvg) y como mapa de bits (cairo)
svg = drawsvg.Drawing(320, 80)
svg.append(drawsvg.Rectangle(0, 0, 320, 80, rx=12, fill="#1f4e79"))
svg.append(drawsvg.Text("Sede Kennedy", 32, 24, 50, fill="white", font_family="sans-serif"))
svg.save_svg("insignia.svg")

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 320, 80)
ctx = cairo.Context(surface)
ctx.set_source_rgb(0x1F / 255, 0x4E / 255, 0x79 / 255)
ctx.new_sub_path()
for x, y, a in ((308, 12, -np.pi / 2), (308, 68, 0), (12, 68, np.pi / 2), (12, 12, np.pi)):
    ctx.arc(x, y, 12, a, a + np.pi / 2)
ctx.close_path(); ctx.fill()
ctx.set_source_rgb(1, 1, 1); ctx.select_font_face("sans-serif"); ctx.set_font_size(32)
ctx.move_to(24, 50); ctx.show_text("Sede Kennedy")
surface.write_to_png("insignia.png")
print(f"insignia.svg {os.path.getsize('insignia.svg')} bytes (texto, escala sin perder) · insignia.png {os.path.getsize('insignia.png')} bytes (320×80 fijos)")
