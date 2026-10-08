package dev.mono.legacy.inventory.internal;

import jakarta.persistence.*;

import java.math.BigDecimal;

// catálogo e inventario en la misma fila: "total, un producto tiene stock"
@Entity
@Table(name = "products")
public class Product {
    @Id
    private String sku;
    private String name;
    @Column(precision = 12, scale = 2)          // taller 05: decimal con dos cifras, nunca double
    private BigDecimal price;
    private int stock;

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public int getStock() { return stock; }
    public void setStock(int stock) { this.stock = stock; }
}
