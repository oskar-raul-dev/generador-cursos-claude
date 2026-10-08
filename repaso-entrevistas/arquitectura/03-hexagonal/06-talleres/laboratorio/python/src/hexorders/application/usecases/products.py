from __future__ import annotations

from dataclasses import dataclass

from hexorders.domain.money import Money
from hexorders.domain.product import Product

from ..actor import Actor
from ..errors import NotFound, ProductAlreadyExists
from ..page import Page, PageRequest
from ..ports import Inventory, Products, UnitOfWork


@dataclass(frozen=True, slots=True)
class ProductWithStock:
    product: Product
    stock: int


@dataclass(frozen=True, slots=True)
class ListProducts:
    """Catálogo + stock: dos puertos, dos unidades de consistencia (y desde la parte 3, dos bases).
    La composición ocurre aquí, no con un JOIN."""

    products: Products
    inventory: Inventory

    def execute(self, page: PageRequest) -> Page[ProductWithStock]:
        catalog = self.products.list(page)
        stock = self.inventory.available_for([p.sku for p in catalog.items])
        return catalog.map(lambda p: ProductWithStock(p, stock.get(p.sku, 0)))


@dataclass(frozen=True, slots=True)
class GetProduct:
    products: Products
    inventory: Inventory

    def execute(self, sku: str) -> ProductWithStock:
        product = self.products.find(sku)
        if product is None:
            raise NotFound("PRODUCT", sku)
        return ProductWithStock(product, self.inventory.available_for([sku]).get(sku, 0))


@dataclass(frozen=True, slots=True)
class CreateProduct:
    """Alta de catálogo e inventario inicial, solo para operator."""

    products: Products
    inventory: Inventory
    unit_of_work: UnitOfWork

    def execute(self, actor: Actor, sku: str, name: str, unit_price: Money, stock: int) -> ProductWithStock:
        actor.require_operator()
        product = Product(sku, name, unit_price)

        def work() -> ProductWithStock:
            if self.products.exists(product.sku):
                raise ProductAlreadyExists(product.sku)
            self.products.save(product)
            self.inventory.initialize(product.sku, stock)
            return ProductWithStock(product, stock)

        return self.unit_of_work.run(work)
