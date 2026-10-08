"""Parte 3: el catálogo en MongoDB detrás del mismo puerto Products, con pymongo."""

from __future__ import annotations

import base64

from pymongo import ASCENDING, MongoClient

from hexorders.application.page import Page, PageRequest
from hexorders.domain.money import Money
from hexorders.domain.product import Product


class MongoProducts:
    def __init__(self, url: str) -> None:
        self.client: MongoClient = MongoClient(url)
        self.collection = self.client.get_default_database().get_collection("products")

    def close(self) -> None:
        self.client.close()

    def find(self, sku: str) -> Product | None:
        doc = self.collection.find_one({"_id": sku})
        return None if doc is None else _to_product(doc)

    def exists(self, sku: str) -> bool:
        return self.collection.count_documents({"_id": sku}, limit=1) > 0

    def list(self, page: PageRequest) -> Page[Product]:
        query = {}
        if page.cursor:
            try:
                query["sku"] = {"$gt": base64.urlsafe_b64decode(page.cursor + "=" * (-len(page.cursor) % 4)).decode()}
            except Exception:
                pass
        docs = list(self.collection.find(query).sort("sku", ASCENDING).limit(page.limit + 1))
        more = len(docs) > page.limit
        docs = docs[: page.limit]
        next_cursor = base64.urlsafe_b64encode(docs[-1]["sku"].encode()).decode().rstrip("=") if more else None
        return Page([_to_product(d) for d in docs], next_cursor)

    def save(self, product: Product) -> None:
        self.collection.update_one(
            {"_id": product.sku},
            {"$set": {"sku": product.sku, "name": product.name,
                      "unitPrice": {"amount": product.unit_price.text(), "currency": product.unit_price.currency}}},
            upsert=True)


def _to_product(doc: dict) -> Product:
    return Product(doc["sku"], doc["name"], Money.parse(doc["unitPrice"]["amount"], doc["unitPrice"]["currency"]))
