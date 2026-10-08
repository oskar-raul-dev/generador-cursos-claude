package dev.mono.legacy.inventory.internal;

import jakarta.persistence.*;

import java.math.BigDecimal;

// El catálogo. Hasta el taller 09 también llevaba el stock en la misma fila ("total, un producto
// tiene stock"); desde el 09 el stock vive en la tabla inventory (StockStore).
@Entity
@Table(name = "products")
public class Product {
    @Id
    private String sku;
    private String name;
    @Column(precision = 12, scale = 2)          // taller 05: decimal con dos cifras, nunca double
    private BigDecimal price;

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
}
