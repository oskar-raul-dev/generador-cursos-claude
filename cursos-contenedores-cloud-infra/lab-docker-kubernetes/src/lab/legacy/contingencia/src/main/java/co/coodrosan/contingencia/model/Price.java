package co.coodrosan.contingencia.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;

@Entity
@Table(name = "price")
@IdClass(Price.Key.class)
public class Price {
    @Id
    private String sku;
    @Id
    @Column(name = "store_id")
    private String storeId;
    private int amount;

    public String getSku() { return sku; }
    public String getStoreId() { return storeId; }
    public int getAmount() { return amount; }

    // Llave compuesta, como en el central.
    public static class Key implements Serializable {
        private String sku;
        private String storeId;

        public Key() { }

        @Override
        public boolean equals(Object o) {
            if (!(o instanceof Key)) return false;
            Key k = (Key) o;
            return Objects.equals(sku, k.sku) && Objects.equals(storeId, k.storeId);
        }

        @Override
        public int hashCode() { return Objects.hash(sku, storeId); }
    }
}
