package banco;

// Un valor fijo en pesos por operación; en dólares, siempre 2,50.
public final class ComisionFija implements PoliticaComision {

    private static final Dinero EN_DOLARES = Dinero.de("2.50", Moneda.USD);

    private final Dinero retiro;
    private final Dinero transferencia;

    public ComisionFija(String retiroEnPesos, String transferenciaEnPesos) {
        this.retiro = Dinero.de(retiroEnPesos, Moneda.COP);
        this.transferencia = Dinero.de(transferenciaEnPesos, Moneda.COP);
    }

    @Override
    public Dinero deRetiro(Dinero importe) {
        return importe.moneda() == Moneda.USD ? EN_DOLARES : retiro;
    }

    @Override
    public Dinero deTransferencia(Dinero importe) {
        return importe.moneda() == Moneda.USD ? EN_DOLARES : transferencia;
    }
}
