package dev.mono.legacy.entity;

import jakarta.persistence.*;

// catálogo e inventario en la misma fila: "total, un producto tiene stock"
@Entity
@Table(name = "products")
public class Product {
    @Id
    private String sku;
    private String name;
    private double price;
    private int stock;

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    public int getStock() { return stock; }
    public void setStock(int stock) { this.stock = stock; }
}
