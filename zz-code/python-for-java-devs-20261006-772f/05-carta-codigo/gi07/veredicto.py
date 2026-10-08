"""La misma pregunta en cuatro pilas: la sede más cercana y su distancia para 200.000 domicilios sintéticos."""

import math
import time

import duckdb
import geopandas as gpd
import numpy as np
import pandas as pd
from pyproj import Geod

SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Kennedy": (4.6280, -74.1530), "Usaquén": (4.6950, -74.0310), "Engativá": (4.7070, -74.1100),
    "Fontibón": (4.6780, -74.1410), "Restrepo": (4.5880, -74.1030), "Soacha": (4.5790, -74.2170),
    "Zipaquirá": (5.0220, -73.9950),
}
N = 200_000
rng = np.random.default_rng(7)
lats, lons = rng.normal(4.66, 0.07, N), rng.normal(-74.09, 0.05, N)
s_lat = np.array([lat for lat, _ in SEDES.values()])
s_lon = np.array([lon for _, lon in SEDES.values()])
R = 6_371_008.8                                       # radio medio de la Tierra, en metros
results = {}


def timed(name):
    def wrap(fn):
        start = time.perf_counter()
        idx, metres = fn()
        results[name] = (np.asarray(idx), np.asarray(metres, dtype=float), time.perf_counter() - start)
    return wrap


@timed("1 Python puro (haversine)")
def pure():
    idx, out = [], []
    sedes = list(zip(s_lat.tolist(), s_lon.tolist()))
    for lat, lon in zip(lats.tolist(), lons.tolist()):
        best, best_i = math.inf, -1
        for i, (la, lo) in enumerate(sedes):
            p1, p2 = math.radians(lat), math.radians(la)
            h = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lo - lon) / 2) ** 2
            d = 2 * R * math.asin(math.sqrt(h))
            if d < best:
                best, best_i = d, i
        idx.append(best_i); out.append(best)
    return idx, out


@timed("2 NumPy (haversine)")
def vectorised():
    p1, p2 = np.radians(lats)[:, None], np.radians(s_lat)[None, :]
    h = np.sin((p2 - p1) / 2) ** 2 + np.cos(p1) * np.cos(p2) * np.sin(np.radians(s_lon[None, :] - lons[:, None]) / 2) ** 2
    d = 2 * R * np.arcsin(np.sqrt(h))
    return d.argmin(axis=1), d.min(axis=1)


@timed("3 geopandas en EPSG:9377")
def with_geopandas():
    homes = gpd.GeoDataFrame(geometry=gpd.points_from_xy(lons, lats), crs=4326).to_crs(9377)
    sedes = gpd.GeoDataFrame({"i": range(10)}, geometry=gpd.points_from_xy(s_lon, s_lat), crs=4326).to_crs(9377)
    joined = gpd.sjoin_nearest(homes, sedes, distance_col="d")
    joined = joined[~joined.index.duplicated()].sort_index()
    return joined["i"].to_numpy(), joined["d"].to_numpy()


con = duckdb.connect()
con.execute("INSTALL spatial; LOAD spatial")          # la primera vez baja la extensión: fuera de la medición
con.register("homes", pd.DataFrame({"id": range(N), "lat": lats, "lon": lons}))
con.register("sedes", pd.DataFrame({"i": range(10), "lat": s_lat, "lon": s_lon}))


def duckdb_sphere(lat_first):
    a, b = ("lat", "lon") if lat_first else ("lon", "lat")
    rows = con.execute(f"""
        SELECT id, arg_min(s.i, d), min(d) FROM (
            SELECT h.id, s.i, ST_Distance_Sphere(ST_Point(h.{a}, h.{b}), ST_Point(s.{a}, s.{b})) AS d
            FROM homes h CROSS JOIN sedes s) s
        GROUP BY id ORDER BY id""").fetchnumpy()
    return list(rows.values())[1], list(rows.values())[2]


timed("4 DuckDB spatial, ST_Point(lon, lat)")(lambda: duckdb_sphere(lat_first=False))
timed("5 DuckDB spatial, ST_Point(lat, lon)")(lambda: duckdb_sphere(lat_first=True))

# La referencia: la geodésica sobre el elipsoide, para la sede que eligió NumPy
ref_idx = results["2 NumPy (haversine)"][0]
_, _, ref = Geod(ellps="WGS84").inv(lons, lats, s_lon[ref_idx], s_lat[ref_idx])

print(f"{'pila':<38} {'tiempo':>8} {'misma sede':>11} {'error máx':>10} {'error mediano':>14}")
for name, (idx, metres, seconds) in results.items():
    same = (idx == ref_idx).mean() * 100
    err = np.abs(metres - ref)
    print(f"{name:<38} {seconds:7.2f}s {same:10.2f}% {err.max():9.1f}m {np.median(err):13.1f}m")
