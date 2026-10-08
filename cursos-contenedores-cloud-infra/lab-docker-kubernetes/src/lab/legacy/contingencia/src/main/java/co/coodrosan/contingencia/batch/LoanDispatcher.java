package co.coodrosan.contingencia.batch;

import co.coodrosan.contingencia.model.ReplenishmentOrder;
import jakarta.ejb.Stateless;
import jakarta.ejb.TransactionAttribute;
import jakarta.ejb.TransactionAttributeType;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

// Pasa los préstamos pendientes a despachados en su propia transacción, y la confirma al volver.
@Stateless
public class LoanDispatcher {

    private static final DateTimeFormatter WHEN = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @PersistenceContext(unitName = "contingencia")
    private EntityManager em;

    @TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
    public List<String> dispatchPending() {
        List<String> lines = new ArrayList<>();
        List<ReplenishmentOrder> pending = em.createQuery(
                "SELECT o FROM ReplenishmentOrder o WHERE o.status = 'PENDING' ORDER BY o.id", ReplenishmentOrder.class)
            .getResultList();
        for (ReplenishmentOrder o : pending) {
            o.setStatus("DISPATCHED");
            // id|sku|origen|destino|cantidad|fecha, como lo acordaron con la Braqui en 2020.
            lines.add(o.getId() + "|" + o.getSku() + "|" + o.getOriginStoreId() + "|" + o.getDestinationStoreId()
                + "|" + o.getQuantity() + "|" + o.getCreatedAt().format(WHEN));
        }
        return lines;
    }
}
