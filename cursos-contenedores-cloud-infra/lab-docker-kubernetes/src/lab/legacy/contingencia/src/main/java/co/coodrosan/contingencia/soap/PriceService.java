package co.coodrosan.contingencia.soap;

import co.coodrosan.contingencia.model.Price;
import co.coodrosan.contingencia.model.Product;
import jakarta.ejb.Stateless;
import jakarta.jws.HandlerChain;
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.xml.ws.WebServiceException;
import java.util.ArrayList;
import java.util.List;

// Precios: Contingencia no calcula nada, solo responde el precio que le llegó del central.
@Stateless
@WebService(serviceName = "PriceService")
@HandlerChain(file = "handlers.xml")
public class PriceService {

    // Droguería de referencia para el catálogo del portal.
    private static final String REFERENCE_STORE = "DRO-001";

    @PersistenceContext(unitName = "contingencia")
    private EntityManager em;

    @WebMethod
    public int getPrice(@WebParam(name = "sku") String sku, @WebParam(name = "storeId") String storeId) {
        List<Price> found = em.createQuery(
                "SELECT p FROM Price p WHERE p.sku = :sku AND p.storeId = :store", Price.class)
            .setParameter("sku", sku).setParameter("store", storeId).getResultList();
        if (found.isEmpty()) {
            throw new WebServiceException("Sin precio para " + sku + " en " + storeId);
        }
        return found.get(0).getAmount();
    }

    @WebMethod
    public List<CatalogItem> listCatalog() {
        List<CatalogItem> items = new ArrayList<>();
        for (Product p : em.createQuery("SELECT p FROM Product p ORDER BY p.sku", Product.class).getResultList()) {
            items.add(new CatalogItem(p.getSku(), p.getName(), p.getCategory(), getPrice(p.getSku(), REFERENCE_STORE)));
        }
        return items;
    }
}
