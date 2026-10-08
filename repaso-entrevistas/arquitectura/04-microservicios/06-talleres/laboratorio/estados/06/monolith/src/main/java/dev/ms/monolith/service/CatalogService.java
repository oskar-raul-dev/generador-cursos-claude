package dev.ms.monolith.service;

import dev.ms.monolith.entity.Product;
import dev.ms.monolith.inventory.Inventory;
import dev.ms.monolith.repository.ProductRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

// Sin @Transactional a nivel de clase: si el stock viene de un servicio remoto, la llamada no debe
// retener una conexión de la base mientras espera (lección del taller 01).
@Service
public class CatalogService {
    private final ProductRepository products;
    private final Inventory inventory;

    public CatalogService(ProductRepository products, Inventory inventory) {
        this.products = products; this.inventory = inventory;
    }

    public List<Views.ProductView> list() {
        var all = products.findAll(Sort.by("sku"));
        var stock = inventory.stockOf(all.stream().map(Product::getSku).toList());
        return all.stream().map(p -> view(p, stock.getOrDefault(p.getSku(), 0))).toList();
    }

    public Views.ProductView get(String sku) {
        var product = products.findById(sku).orElseThrow(() -> new Errors.ProductNotFound(sku));
        return view(product, inventory.stockOf(List.of(sku)).getOrDefault(sku, 0));
    }

    private static Views.ProductView view(Product p, int stock) {
        return new Views.ProductView(p.getSku(), p.getName(), Views.Money.of(p.getUnitPrice(), p.getCurrency().trim()), stock);
    }
}
