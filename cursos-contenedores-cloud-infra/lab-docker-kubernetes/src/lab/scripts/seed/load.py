"""Carga en los servicios lo que genera generate.py (Fase 12): lee el JSON de la entrada estándar y lo
envía por la API de cada servicio, nunca a sus tablas. Es idempotente: un producto que ya existe (409)
cuenta como cargado, y un precio se vuelve a poner igual. Solo biblioteca estándar.

    python generate.py --stores 20 | python load.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

CATALOG = os.environ.get("CATALOG_URL", "http://catalog:8080")
PRICING = os.environ.get("PRICING_URL", "http://pricing:8080")


def send(method: str, url: str, body: dict) -> int:
    request = urllib.request.Request(url, data=json.dumps(body).encode(), method=method,
                                     headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def main() -> int:
    data = json.load(sys.stdin)
    products = prices = 0
    for product in data["products"]:
        status = send("POST", f"{CATALOG}/products",
                      {"sku": product["sku"], "name": product["name"], "category": "venta libre"})
        if status not in (201, 409):
            print(f"catalog rechazó {product['sku']}: {status}", file=sys.stderr)
            return 1
        products += 1
        for store in data["stores"]:
            status = send("PUT", f"{PRICING}/prices/{product['sku']}", {"store": store["id"], "price": product["price"]})
            if status != 200:
                print(f"pricing rechazó {product['sku']} en {store['id']}: {status}", file=sys.stderr)
                return 1
            prices += 1
    print(f"sembrado: {products} productos en catalog, {prices} precios en pricing ({len(data['stores'])} droguerías)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
