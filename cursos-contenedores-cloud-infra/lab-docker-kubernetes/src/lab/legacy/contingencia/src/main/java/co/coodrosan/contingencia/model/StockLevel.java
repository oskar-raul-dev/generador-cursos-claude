package co.coodrosan.contingencia.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "stock_level")
@IdClass(StockLevel.Key.class)
public class StockLevel {
    @Id
    @Column(name = "store_id")
    private String storeId;
    @Id
    private String sku;
    private int quantity;
    @Column(name = "reorder_threshold")
    private int reorderThreshold;

    public String getStoreId() { return storeId; }
    public String getSku() { return sku; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public int getReorderThreshold() { return reorderThreshold; }

    // Llave compuesta, como en el central.
    public static class Key implements Serializable {
        private String storeId;
        private String sku;

        public Key() { }

        public static Key of(String storeId, String sku) {
            Key k = new Key();
            k.storeId = storeId;
            k.sku = sku;
            return k;
        }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof Key)) return false;
            Key k = (Key) o;
            return Objects.equals(storeId, k.storeId) && Objects.equals(sku, k.sku);
        }

        @Override
        public int hashCode() { return Objects.hash(storeId, sku); }
    }
}
