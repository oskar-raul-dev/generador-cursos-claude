package dev.ms.orders.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.math.BigDecimal;

// Foto del catálogo en el momento de la venta: si mañana cambia el precio, el pedido no.
@Embeddable
public class OrderLine {
    private String sku;
    @Column(name = "product_name")
    private String productName;
    private int quantity;
    @Column(name = "unit_price")
    private BigDecimal unitPrice;

    protected OrderLine() {}

    public OrderLine(String sku, String productName, int quantity, BigDecimal unitPrice) {
        this.sku = sku;
        this.productName = productName;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
    }

    public String getSku() { return sku; }
    public String getProductName() { return productName; }
    public int getQuantity() { return quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public BigDecimal lineTotal() { return unitPrice.multiply(BigDecimal.valueOf(quantity)); }
}
