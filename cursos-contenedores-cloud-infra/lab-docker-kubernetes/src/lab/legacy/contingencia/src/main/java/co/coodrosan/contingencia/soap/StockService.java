package co.coodrosan.contingencia.soap;

import co.coodrosan.contingencia.model.Dispatch;
import co.coodrosan.contingencia.model.StockLevel;
import co.coodrosan.contingencia.model.StockMovement;
import jakarta.ejb.Stateless;
import jakarta.jws.HandlerChain;
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.xml.ws.WebServiceException;

// Existencias: vender, descontar y prestar. Es todo lo que Contingencia sabe hacer.
@Stateless
@WebService(serviceName = "StockService")
@HandlerChain(file = "handlers.xml")
public class StockService {

    @PersistenceContext(unitName = "contingencia")
    private EntityManager em;

    @WebMethod
    public int getStock(@WebParam(name = "sku") String sku, @WebParam(name = "storeId") String storeId) {
        return level(sku, storeId, LockModeType.NONE).getQuantity();
    }

    // Si la venta trae dirección, es un domicilio y queda esperando moto.
    @WebMethod
    public long registerSale(@WebParam(name = "sku") String sku, @WebParam(name = "storeId") String storeId,
                             @WebParam(name = "quantity") int quantity,
                             @WebParam(name = "deliveryAddress") String deliveryAddress) {
        StockLevel level = level(sku, storeId, LockModeType.PESSIMISTIC_WRITE);
        if (level.getQuantity() < quantity) {
            throw new WebServiceException("No hay " + quantity + " unidades de " + sku + " en " + storeId);
        }
        level.setQuantity(level.getQuantity() - quantity);
        em.persist(new StockMovement(storeId, sku, "SALE", quantity));
        // Ojo: en Oracle una dirección vacía era NULL; aquí no, y por eso se revisan las dos cosas.
        if (deliveryAddress == null || deliveryAddress.isEmpty()) {
            return 0;
        }
        Dispatch dispatch = new Dispatch(storeId, deliveryAddress);
        em.persist(dispatch);
        em.flush();
        return dispatch.getId();
    }

    // El préstamo vive en la base, en register_loan, como en el central.
    @WebMethod
    public long requestLoan(@WebParam(name = "sku") String sku, @WebParam(name = "originStore") String originStore,
                            @WebParam(name = "destinationStore") String destinationStore,
                            @WebParam(name = "quantity") int quantity) {
        Object id = em.createNativeQuery("SELECT register_loan(?1, ?2, ?3, ?4)")
            .setParameter(1, sku).setParameter(2, originStore)
            .setParameter(3, destinationStore).setParameter(4, quantity)
            .getSingleResult();
        return ((Number) id).longValue();
    }

    private StockLevel level(String sku, String storeId, LockModeType lock) {
        StockLevel level = em.find(StockLevel.class, StockLevel.Key.of(storeId, sku), lock);
        if (level == null) {
            throw new WebServiceException("Sin existencias registradas de " + sku + " en " + storeId);
        }
        return level;
    }
}
