"""Siembra droguerías y productos sintéticos para el laboratorio."""
import argparse
import json
import random

from faker import Faker

# Ciudades de la historia: Santander, Boyacá y Bogotá.
CITIES = ["Bucaramanga", "Floridablanca", "Girón", "Piedecuesta", "Tunja", "Sogamoso", "Duitama", "Bogotá"]
# Faker no trae medicamentos; una lista corta basta para el laboratorio.
PRODUCTS = ["Acetaminofén 500 mg", "Ibuprofeno 400 mg", "Salbutamol inhalador", "Loratadina 10 mg",
            "Omeprazol 20 mg", "Suero oral", "Alcohol antiséptico", "Vitamina C 500 mg"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stores", type=int, default=20)
    parser.add_argument("--seed", type=int, default=1998)  # semilla fija: mismo resultado en toda máquina
    args = parser.parse_args()

    fake = Faker("es_CO")
    Faker.seed(args.seed)
    random.seed(args.seed)
    stores = [{"id": f"DRO-{i:03d}", "city": random.choice(CITIES), "address": fake.street_address(),
               "manager": fake.name()} for i in range(1, args.stores + 1)]
    products = [{"sku": f"SKU-{i:04d}", "name": name, "price": random.randrange(1500, 45000, 100)}
                for i, name in enumerate(PRODUCTS, start=1)]
    print(json.dumps({"stores": stores, "products": products}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
