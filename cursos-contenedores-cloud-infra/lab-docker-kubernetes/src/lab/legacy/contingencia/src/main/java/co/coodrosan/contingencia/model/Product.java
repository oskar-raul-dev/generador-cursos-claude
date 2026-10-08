package co.coodrosan.contingencia.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "product")
public class Product {
    @Id
    private String sku;
    private String name;
    private String category;

    public String getSku() { return sku; }
    public String getName() { return name; }
    public String getCategory() { return category; }
}
