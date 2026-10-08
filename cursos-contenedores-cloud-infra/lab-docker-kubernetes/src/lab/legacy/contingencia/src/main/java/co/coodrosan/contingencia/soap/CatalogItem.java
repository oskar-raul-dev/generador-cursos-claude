package co.coodrosan.contingencia.soap;

// Lo que el portal trae cada noche. Bean clásico para que JAXB lo serialice sin anotaciones.
public class CatalogItem {
    private String sku;
    private String name;
    private String category;
    private int referencePrice;

    public CatalogItem() { }

    public CatalogItem(String sku, String name, String category, int referencePrice) {
        this.sku = sku;
        this.name = name;
        this.category = category;
        this.referencePrice = referencePrice;
    }

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public int getReferencePrice() { return referencePrice; }
    public void setReferencePrice(int referencePrice) { this.referencePrice = referencePrice; }
}
