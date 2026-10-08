package co.coodrosan.contingencia.infra;

import jakarta.transaction.TransactionManager;
import jakarta.transaction.UserTransaction;
import org.hibernate.engine.transaction.jta.platform.internal.AbstractJtaPlatform;

// Hibernate 7 ya no trae el adaptador para GlassFish que el Siga usaba desde 2016; este hace lo mismo:
// busca el gestor de transacciones del servidor por JNDI.
public class GlassFishJtaPlatform extends AbstractJtaPlatform {

    @Override
    protected TransactionManager locateTransactionManager() {
        return (TransactionManager) jndiService().locate("java:appserver/TransactionManager");
    }

    @Override
    protected UserTransaction locateUserTransaction() {
        return (UserTransaction) jndiService().locate("java:comp/UserTransaction");
    }
}
