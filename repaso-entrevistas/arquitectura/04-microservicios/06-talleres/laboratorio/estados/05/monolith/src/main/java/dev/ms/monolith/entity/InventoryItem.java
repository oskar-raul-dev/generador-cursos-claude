package dev.ms.monolith.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "inventory")
public class InventoryItem {
    @Id
    private String sku;
    private int available;

    protected InventoryItem() {}

    public String getSku() { return sku; }
    public int getAvailable() { return available; }
    public void take(int quantity) { this.available -= quantity; }
    public void giveBack(int quantity) { this.available += quantity; }
}
