"""Distancia recta contra distancia por la red: un barrio sintético con un río, un solo puente y dos calles de un sentido."""

import networkx as nx
import osmnx as ox
from pyproj import Geod, Transformer

# Un barrio de 6×6 cuadras al lado de Suba, escrito como un archivo OSM: así osmnx lo carga sin internet
LAT0, LON0, STEP = 4.7300, -74.0900, 0.002           # unos 220 m por cuadra
RIVER_BETWEEN = (2, 3)                                # el río corre entre las columnas 2 y 3
nodes = {(r, c): 1000 + r * 10 + c for r in range(6) for c in range(6)}
ways, way_id = [], 1


def way(refs, highway, **tags):
    global way_id
    ways.append((way_id, refs, {"highway": highway, **tags}))
    way_id += 1


for r in range(6):                                    # calles este-oeste: solo la fila 0 cruza el río (el puente)
    if r == 0:
        way([nodes[(0, c)] for c in range(6)], "primary", maxspeed="50", name="Avenida del Puente")
    else:
        way([nodes[(r, c)] for c in range(3)], "residential", maxspeed="30")
        way([nodes[(r, c)] for c in range(3, 6)], "residential", maxspeed="30")
for c in range(6):                                    # carreras norte-sur; la 3 y la 4 van solo hacia el norte
    tags = {"oneway": "yes"} if c in (3, 4) else {}
    way([nodes[(r, c)] for r in range(6)], "residential", maxspeed="30", **tags)

xml = ['<?xml version="1.0" encoding="UTF-8"?>', '<osm version="0.6" generator="curso">']
xml += [f'  <node id="{nid}" lat="{LAT0 + r * STEP:.6f}" lon="{LON0 + c * STEP:.6f}"/>' for (r, c), nid in nodes.items()]
for wid, refs, tags in ways:
    xml.append(f'  <way id="{wid}">' + "".join(f'<nd ref="{n}"/>' for n in refs)
               + "".join(f'<tag k="{k}" v="{v}"/>' for k, v in tags.items()) + "</way>")
xml.append("</osm>")
with open("barrio.osm", "w", encoding="utf-8") as f:
    f.write("\n".join(xml))

G = ox.graph_from_xml("barrio.osm", simplify=False)
G = ox.add_edge_speeds(G)                             # usa maxspeed; si falta, imputa por tipo de vía
G = ox.add_edge_travel_times(G)
print(f"red: {G.number_of_nodes()} nodos · {G.number_of_edges()} aristas dirigidas")

# Dos domicilios a cada lado del río, en coordenadas que no caen justo en una esquina
home_a = (LAT0 + 5 * STEP + 0.0003, LON0 + 1 * STEP + 0.0002)   # (lat, lon)
home_b = (LAT0 + 5 * STEP - 0.0002, LON0 + 4 * STEP - 0.0003)
Gp = ox.project_graph(G, to_crs="EPSG:9377")          # proyectada: nearest_nodes usa metros y no pide scikit-learn
to_m = Transformer.from_crs(4326, 9377, always_xy=True)
(xa, ya), (xb, yb) = to_m.transform(home_a[1], home_a[0]), to_m.transform(home_b[1], home_b[0])
na, nb = ox.distance.nearest_nodes(Gp, [xa, xb], [ya, yb])

straight = Geod(ellps="WGS84").inv(home_a[1], home_a[0], home_b[1], home_b[0])[2]
for label, src, dst in (("A → B", na, nb), ("B → A", nb, na)):
    path = nx.shortest_path(G, src, dst, weight="length")
    metres = nx.path_weight(G, path, weight="length")
    fastest = nx.shortest_path(G, src, dst, weight="travel_time")
    seconds = nx.path_weight(G, fastest, weight="travel_time")
    print(f"{label}: recta {straight:5.0f} m · por la red {metres:5.0f} m (×{metres / straight:.1f}) · "
          f"{len(path) - 1} tramos · más rápida {seconds / 60:4.1f} min por {nx.path_weight(G, fastest, weight='length'):5.0f} m")

# Un segundo puente en la fila 3 cambia la respuesta: la red manda, no la geometría
G2 = G.copy()
for u, v in ((nodes[(3, 2)], nodes[(3, 3)]), (nodes[(3, 3)], nodes[(3, 2)])):
    G2.add_edge(u, v, length=STEP * 111_000, travel_time=STEP * 111_000 / (30 / 3.6))
metres2 = nx.shortest_path_length(G2, na, nb, weight="length")
print(f"con un puente en la fila 3: {metres2:5.0f} m (×{metres2 / straight:.1f})")

# El grafo sin dirección pierde el sentido único: la ruta B → A sale más corta de lo que es
undirected = nx.shortest_path_length(G.to_undirected(), nb, na, weight="length")
print(f"B → A sobre el grafo sin dirección: {undirected:5.0f} m")
