"""Pacientes sintéticos contra las diez sedes con geopandas: la sede más cercana, el radio de 5 km y el CRS que viaja o no."""

import warnings

import geopandas as gpd
import numpy as np
import pandas as pd

SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Kennedy": (4.6280, -74.1530), "Usaquén": (4.6950, -74.0310), "Engativá": (4.7070, -74.1100),
    "Fontibón": (4.6780, -74.1410), "Restrepo": (4.5880, -74.1030), "Soacha": (4.5790, -74.2170),
    "Zipaquirá": (5.0220, -73.9950),
}
sedes = gpd.GeoDataFrame(
    {"sede": list(SEDES)},
    geometry=gpd.points_from_xy([lon for _, lon in SEDES.values()], [lat for lat, _ in SEDES.values()]),
    crs=4326,
)

# 2.000 domicilios sintéticos: nube alrededor de Bogotá, sin relación con ningún paciente real
rng = np.random.default_rng(7)
homes = gpd.GeoDataFrame(
    {"patient": [f"p{i:04d}" for i in range(2000)]},
    geometry=gpd.points_from_xy(rng.normal(-74.09, 0.05, 2000), rng.normal(4.66, 0.07, 2000)),
    crs=4326,
)

# 1. La sede más cercana, en metros: se proyecta primero
sedes_m, homes_m = sedes.to_crs(9377), homes.to_crs(9377)
nearest = gpd.sjoin_nearest(homes_m, sedes_m, distance_col="metres")
summary = nearest.groupby("sede")["metres"].agg(pacientes="size", mediana_km=lambda m: round(m.median() / 1000, 2))
print(summary.sort_values("pacientes", ascending=False).head(5).to_string())
print("pacientes asignados:", len(nearest), "· de", len(homes))

# 2. La misma operación en grados: geopandas avisa, y la "distancia" queda en grados
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    nearest_deg = gpd.sjoin_nearest(homes, sedes, distance_col="degrees")
print("\naviso:", caught[0].message.args[0].split(".")[0])
changed = (nearest_deg.set_index("patient")["sede"] != nearest.set_index("patient")["sede"]).sum()
print(f"asignaciones distintas entre grados y metros: {changed} · distancia máxima en 'grados': {nearest_deg['degrees'].max():.4f}")

# 3. Dos CRS distintos en un mismo join
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    mixed = gpd.sjoin(homes, sedes_m.set_geometry(sedes_m.buffer(5000)), predicate="within")
print("\nmezcla 4326 con 9377:", len(mixed), "coincidencias ·", caught[0].message.args[0].split(".")[0])

# 4. "Pacientes a menos de 5 km de una sede": los radios se solapan y el conteo ingenuo suma de más
rings = sedes_m.set_geometry(sedes_m.buffer(5000))
inside = gpd.sjoin(homes_m, rings, predicate="within")
print(f"\nfilas del join: {len(inside)} · pacientes distintos: {inside['patient'].nunique()}")
union = rings.dissolve()
print(f"área de los diez radios: {rings.area.sum() / 1e6:.1f} km² · de su unión: {union.area.iloc[0] / 1e6:.1f} km²")

# 5. El CRS viaja en GeoPackage y se pierde en CSV
nearest[["patient", "sede", "metres", "geometry"]].to_file("asignacion.gpkg", layer="asignacion")
back = gpd.read_file("asignacion.gpkg")
print("\nGeoPackage leído:", back.crs.to_epsg(), "·", len(back), "filas")
pd.DataFrame(nearest.drop(columns="geometry").assign(wkt=nearest.geometry.to_wkt())).to_csv("asignacion.csv", index=False)
print("CSV leído con pandas: tipo de la geometría:", type(pd.read_csv("asignacion.csv")["wkt"].iloc[0]).__name__, "· CRS: ninguno")
