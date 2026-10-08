"""Geometría, proyección y topología con las diez sedes de Áurea: tres maneras de medir y dos de equivocarse."""

import math

from pyproj import CRS, Geod, Transformer
from shapely import Point, Polygon, make_valid
from shapely.ops import transform
from shapely.validation import explain_validity

# Centro aproximado del barrio de cada sede (lat, lon): no son direcciones, son puntos de referencia
SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Kennedy": (4.6280, -74.1530), "Usaquén": (4.6950, -74.0310), "Engativá": (4.7070, -74.1100),
    "Fontibón": (4.6780, -74.1410), "Restrepo": (4.5880, -74.1030), "Soacha": (4.5790, -74.2170),
    "Zipaquirá": (5.0220, -73.9950),
}
WGS84, CTM12, BOGOTA_ZONE = 4326, 9377, 3116   # geográficas · Origen Nacional (2020) · zona Bogotá (la vieja)
geod = Geod(ellps="WGS84")
to_ctm12 = Transformer.from_crs(WGS84, CTM12, always_xy=True)  # always_xy: (lon, lat) entra, (x, y) sale


def naive_km(a, b):
    """Pitágoras sobre grados, multiplicado por 111,32: el cálculo que aparece en la hoja de cálculo."""
    return math.hypot(a[0] - b[0], a[1] - b[1]) * 111.32


def geodesic_km(a, b):
    """La distancia sobre el elipsoide: la de referencia."""
    _, _, metres = geod.inv(a[1], a[0], b[1], b[0])   # Geod pide (lon, lat)
    return metres / 1000


def projected_km(a, b):
    """Pitágoras en metros, después de proyectar al plano de Colombia."""
    (xa, ya), (xb, yb) = to_ctm12.transform(a[1], a[0]), to_ctm12.transform(b[1], b[0])
    return math.hypot(xa - xb, ya - yb) / 1000


print("Centro → sede        ingenua   geodésica   proyectada")
for name in ("Chapinero", "Soacha", "Zipaquirá"):
    a, b = SEDES["Centro"], SEDES[name]
    print(f"Centro → {name:<10} {naive_km(a, b):8.3f} km {geodesic_km(a, b):8.3f} km {projected_km(a, b):8.3f} km")

# El atajo funciona en Bogotá porque está cerca del ecuador: el mismo medio grado de longitud en otras latitudes
for where, lat0 in (("Bogotá", 4.6), ("Madrid", 40.4), ("Oslo", 59.9)):
    a, b = (lat0, 0.0), (lat0, 0.5)
    print(f"0,5° de longitud en {where:<7} ingenua {naive_km(a, b):6.2f} km · geodésica {geodesic_km(a, b):6.2f} km")

# Trampa 1: el orden de los ejes. EPSG:4326 se define como (lat, lon); sin always_xy, pyproj lo respeta
strict = Transformer.from_crs(WGS84, CTM12)
lat, lon = SEDES["Centro"]
print("\n(lat, lon) sin always_xy:", [round(v) for v in strict.transform(lat, lon)])
print("(lon, lat) sin always_xy:", [round(v) for v in strict.transform(lon, lat)])
print("(lon, lat) con always_xy:", [round(v) for v in to_ctm12.transform(lon, lat)])

# Trampa 2: el SRID que no coincide. Un archivo llega en la zona Bogotá (3116) y se lee como CTM12 (9377)
x_old, y_old = Transformer.from_crs(WGS84, BOGOTA_ZONE, always_xy=True).transform(lon, lat)
lon_bad, lat_bad = Transformer.from_crs(CTM12, WGS84, always_xy=True).transform(x_old, y_old)
print(f"\nCentro en 3116: ({x_old:.0f}, {y_old:.0f})")
print(f"leído como 9377 cae en ({lat_bad:.4f}, {lon_bad:.4f}), a {geodesic_km((lat, lon), (lat_bad, lon_bad)):.1f} km")
print("unidades de 3116:", CRS(BOGOTA_ZONE).axis_info[0].unit_name, "· de 4326:", CRS(WGS84).axis_info[0].unit_name)

# Topología: un polígono que se cruza a sí mismo es inválido, y su área miente
bowtie = Polygon([(0, 0), (2, 2), (2, 0), (0, 2)])
print(f"\nmoño: válido={bowtie.is_valid} · {explain_validity(bowtie)} · área={bowtie.area}")
fixed = make_valid(bowtie)
print(f"make_valid: {fixed.geom_type} · área={fixed.area}")

# El radio de 5 km dibujado en grados: buffer(0.045) en geográficas, proyectado para medirlo
centro = Point(lon, lat)
in_degrees = transform(to_ctm12.transform, centro.buffer(5 / 111.32))
in_metres = transform(to_ctm12.transform, centro).buffer(5000)
print(f"buffer de '5 km' en grados: {in_degrees.area / 1e6:.2f} km² · en metros: {in_metres.area / 1e6:.2f} km²")
