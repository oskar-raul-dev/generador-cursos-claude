"""El mapa como entregable: agregar en hexágonos H3, suprimir las celdas chicas y entregar un HTML con folium."""

import os

import folium
import h3
import numpy as np

SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Kennedy": (4.6280, -74.1530), "Usaquén": (4.6950, -74.0310), "Engativá": (4.7070, -74.1100),
    "Fontibón": (4.6780, -74.1410), "Restrepo": (4.5880, -74.1030), "Soacha": (4.5790, -74.2170),
}
rng = np.random.default_rng(7)                       # 2.000 domicilios sintéticos, la misma nube de gi02
lats, lons = rng.normal(4.66, 0.07, 2000), rng.normal(-74.09, 0.05, 2000)

# 1. La resolución decide el tamaño de la celda, y con él cuánto se ve y cuánto se esconde
K = 10                                               # una celda con menos de K domicilios no se publica
print("res   área media   celdas   máx/celda   celdas < K   domicilios escondidos")
for res in (6, 7, 8, 9):
    cells = [h3.latlng_to_cell(lat, lon, res) for lat, lon in zip(lats, lons)]
    ids, counts = np.unique(cells, return_counts=True)
    small = counts < K
    print(f"{res:>3} {h3.average_hexagon_area(res, unit='km^2'):9.3f} km² {len(ids):>8} {counts.max():>11} "
          f"{small.sum():>12} {counts[small].sum():>22}")

# 2. Resolución 7: celdas de unos 5 km² y la supresión aplicada
RES = 7
cells = [h3.latlng_to_cell(lat, lon, RES) for lat, lon in zip(lats, lons)]
ids, counts = np.unique(cells, return_counts=True)
published = {cell: int(n) for cell, n in zip(ids, counts) if n >= K}

# 3. Cobertura: celdas a uno o dos anillos de la celda de cada sede
covered = set()
for lat, lon in SEDES.values():
    covered |= set(h3.grid_disk(h3.latlng_to_cell(lat, lon, RES), 1))
in_reach = sum(n for cell, n in published.items() if cell in covered)
print(f"\nresolución {RES}: {len(published)} celdas publicadas · {in_reach} domicilios en celdas a un anillo de una sede")
print("vecinas de una celda:", len(h3.grid_disk(ids[0], 1)) - 1, "· siempre a la misma distancia del centro")


def hexagons(data):
    features = []
    for cell, n in data.items():
        ring = [(lon, lat) for lat, lon in h3.cell_to_boundary(cell)]   # GeoJSON quiere (lon, lat)
        features.append({"type": "Feature", "properties": {"pacientes": n},
                         "geometry": {"type": "Polygon", "coordinates": [ring + ring[:1]]}})
    return {"type": "FeatureCollection", "features": features}


top = max(published.values())
hex_map = folium.Map(location=(4.66, -74.09), zoom_start=11)   # teselas de OSM, sin clave
folium.GeoJson(
    hexagons(published),
    style_function=lambda f: {"fillColor": "#2b6cb0", "color": "#2b6cb0", "weight": 0.5,
                              "fillOpacity": 0.1 + 0.7 * f["properties"]["pacientes"] / top},
    tooltip=folium.GeoJsonTooltip(["pacientes"]),
).add_to(hex_map)
for name, (lat, lon) in SEDES.items():
    folium.Marker((lat, lon), tooltip=name).add_to(hex_map)
hex_map.save("cobertura_h3.html")

# 4. El mismo mapa con un punto por domicilio: lo que NO se entrega
dot_map = folium.Map(location=(4.66, -74.09), zoom_start=11)   # teselas de OSM, sin clave
for lat, lon in zip(lats, lons):
    folium.CircleMarker((lat, lon), radius=2).add_to(dot_map)
dot_map.save("puntos.html")

for name in ("cobertura_h3.html", "puntos.html"):
    html = open(name, encoding="utf-8").read()
    print(f"{name:<18} {os.path.getsize(name) / 1024:7.1f} KB · coordenadas de domicilio adentro: "
          f"{f'{lats[0]:.6f}'[:7] in html}")
