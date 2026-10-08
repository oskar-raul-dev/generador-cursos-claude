"""Ráster con rasterio y rioxarray: un modelo de elevación sintético, la altura de cada sede, el NDVI y la reproyección."""

import os
import time

import numpy as np
import rasterio
import rioxarray
from pyproj import Transformer
from rasterio.enums import Resampling
from rasterio.merge import merge
from rasterio.transform import from_origin
from rasterio.windows import Window

SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Usaquén": (4.6950, -74.0310), "Soacha": (4.5790, -74.2170), "Zipaquirá": (5.0220, -73.9950),
}
CRS, PIXEL = "EPSG:9377", 30.0                       # metros por píxel, como un modelo de elevación global
to_ctm12 = Transformer.from_crs(4326, 9377, always_xy=True)
x0, y1 = to_ctm12.transform(-74.30, 5.10)            # esquina noroeste del área
width, height = 2400, 2000                           # 72 × 60 km
transform = from_origin(x0, y1, PIXEL, PIXEL)

# Elevación sintética: la sabana sube suave hacia el norte y los cerros orientales se levantan al este de Bogotá
rows, cols = np.mgrid[0:height, 0:width]
east = np.clip((cols - 1010) / 60, 0, None)
rng = np.random.default_rng(3)
dem = (2540 + 0.06 * (height - rows) + 900 * np.tanh(east) * (rows > 600) + rng.normal(0, 3, (height, width))).astype("float32")

profile = dict(driver="GTiff", width=width, height=height, count=1, dtype="float32", crs=CRS, transform=transform)
with rasterio.open("dem_plano.tif", "w", **profile) as dst:
    dst.write(dem, 1)
with rasterio.open("dem.tif", "w", **profile, compress="deflate", predictor=3, tiled=True, blockxsize=512, blockysize=512) as dst:
    dst.write(dem, 1)
    dst.build_overviews([2, 4, 8, 16], Resampling.average)   # pirámide: lo que hace rápido el zoom alejado
for name in ("dem_plano.tif", "dem.tif"):
    print(f"{name:<14} {os.path.getsize(name) / 1e6:6.1f} MB")

with rasterio.open("dem.tif") as src:
    print(f"\nCRS {src.crs} · píxel {src.res} · límites {[round(v) for v in src.bounds]}")
    # 1. La altura de cada sede: los puntos van al CRS del ráster antes de muestrear
    points = [to_ctm12.transform(lon, lat) for lat, lon in SEDES.values()]
    for name, value in zip(SEDES, src.sample(points)):
        print(f"  {name:<10} {value[0]:7.0f} m")
    wrong = next(src.sample([(SEDES['Centro'][1], SEDES['Centro'][0])]))[0]
    print(f"  (lon, lat) sin reproyectar: {wrong} — fuera del ráster, sin error")

    # 2. Leer una ventana de 512×512 contra el ráster entero
    start = time.perf_counter(); full = src.read(1); t_full = time.perf_counter() - start
    start = time.perf_counter(); part = src.read(1, window=Window(1000, 800, 512, 512)); t_part = time.perf_counter() - start
    print(f"\nentero {full.nbytes / 1e6:.1f} MB en {t_full * 1000:.0f} ms · ventana {part.nbytes / 1e6:.1f} MB en {t_part * 1000:.1f} ms")
    small = src.read(1, out_shape=(height // 16, width // 16))   # usa la pirámide: lee la vista 1:16
    print(f"vista 1:16 {small.shape} · media {small.mean():.0f} m contra {full.mean():.0f} m del ráster entero")

# 3. NDVI con bandas uint16: la resta sin convertir da la vuelta
red = rng.integers(500, 3000, (500, 500), dtype="uint16")
nir = rng.integers(400, 5000, (500, 500), dtype="uint16")
naive = (nir - red) / (nir + red)
safe = (nir.astype("float32") - red) / (nir.astype("float32") + red)
print(f"\nNDVI ingenuo: rango [{naive.min():.2f}, {naive.max():.2f}] · correcto: [{safe.min():.2f}, {safe.max():.2f}]")
print(f"píxeles con NDVI imposible (> 1): {(naive > 1).sum()} de {naive.size}")

# 4. Mosaico de dos teselas y reproyección a geográficas con rioxarray
with rasterio.open("dem.tif") as src:
    for i, col in enumerate((0, 1200)):
        win = Window(col, 0, 1200, 2000)
        tile_profile = profile | dict(width=1200, transform=src.window_transform(win))
        with rasterio.open(f"tesela_{i}.tif", "w", **tile_profile) as dst:
            dst.write(src.read(1, window=win), 1)
mosaic, _ = merge(["tesela_0.tif", "tesela_1.tif"])
print(f"\nmosaico {mosaic.shape[1:]} · igual al original: {np.array_equal(mosaic[0], dem)}")

with rioxarray.open_rasterio("dem.tif") as opened:   # sin with, Python 3.14 escupe un error vacío al salir
    da = opened.squeeze()
    for method in (Resampling.nearest, Resampling.bilinear):
        geo = da.rio.reproject("EPSG:4326", resampling=method)
        print(f"a 4326 con {method.name:<8} {geo.shape} · píxel {abs(geo.rio.resolution()[0]):.6f}° · máx {float(geo.max()):.1f} m")
    clip = da.rio.clip_box(*to_ctm12.transform(-74.12, 4.55), *to_ctm12.transform(-74.00, 4.75))
    print(f"recorte de Bogotá: {clip.shape} · media {float(clip.mean()):.0f} m")
