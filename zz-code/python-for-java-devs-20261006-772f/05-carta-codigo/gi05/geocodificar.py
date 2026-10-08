"""Geocodificar con Nominatim respetando su política: un agente propio, una petición por segundo y caché."""

import functools

from geopy.distance import geodesic
from geopy.extra.rate_limiter import RateLimiter
from geopy.geocoders import Nominatim

geolocator = Nominatim(user_agent="curso-python-java-devs-gi05", timeout=10)
geocode = functools.cache(RateLimiter(geolocator.geocode, min_delay_seconds=1))   # nunca dos veces la misma dirección

reference = None
QUERIES = (
    "Universidad Jorge Tadeo Lozano, Bogotá",
    "Carrera 4 # 22-61, Bogotá",                     # la dirección publicada de la universidad
    "Cra 4 22 61 Bogota",                            # la misma, como la escribe un formulario
    "Calle 4 # 22-61, Bogotá",                       # la misma, con calle y carrera trocadas
)
for query in QUERIES:
    place = geocode(query, country_codes="co")
    if place is None:
        print(f"{query:<40} → sin resultado")
    else:
        point = (place.latitude, place.longitude)
        reference = reference or point                # la primera respuesta: la universidad
        print(f"{query:<40} → ({point[0]:.4f}, {point[1]:.4f}) · {place.raw['addresstype']:<7} · "
              f"a {geodesic(reference, point).km:5.2f} km de la universidad")
