package banco;

// Strategy: cuánto cobra un tipo de cuenta por cada operación.
public interface PoliticaComision {

    Dinero deRetiro(Dinero importe);

    Dinero deTransferencia(Dinero importe);
}
