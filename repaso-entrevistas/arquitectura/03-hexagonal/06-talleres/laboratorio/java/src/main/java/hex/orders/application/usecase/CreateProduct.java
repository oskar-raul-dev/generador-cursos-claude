package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.error.ProductAlreadyExists;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Products;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.Money;
import hex.orders.domain.Product;

// Alta de catálogo e inventario inicial, solo para operator. La capacidad gruesa se comprueba aquí
// aunque el borde también la filtre: un driver distinto de HTTP tiene que cumplirla igual.
public final class CreateProduct {

    public record Command(Actor actor, String sku, String name, Money unitPrice, int stock) {}

    private final Products products;
    private final Inventory inventory;
    private final UnitOfWork unitOfWork;

    public CreateProduct(Products products, Inventory inventory, UnitOfWork unitOfWork) {
        this.products = products;
        this.inventory = inventory;
        this.unitOfWork = unitOfWork;
    }

    public ListProducts.ProductWithStock execute(Command command) {
        command.actor().requireOperator();
        var product = new Product(command.sku(), command.name(), command.unitPrice());
        return unitOfWork.run(() -> {
            if (products.exists(product.sku())) {
                throw new ProductAlreadyExists(product.sku());
            }
            products.save(product);
            inventory.initialize(product.sku(), command.stock());
            return new ListProducts.ProductWithStock(product, command.stock());
        });
    }
}
