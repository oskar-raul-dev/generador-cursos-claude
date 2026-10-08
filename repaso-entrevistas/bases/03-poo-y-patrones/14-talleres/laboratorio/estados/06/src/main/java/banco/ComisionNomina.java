package banco;

// La nómina no cobra hasta 2 000 000; desde el peso siguiente, el 0,4 % del monto entero.
public final class ComisionNomina implements PoliticaComision {

    private static final Dinero TOPE_SIN_COMISION = Dinero.de("2000000", Moneda.COP);

    @Override
    public Dinero deRetiro(Dinero importe) {
        return importe.esMayorQue(TOPE_SIN_COMISION) ? importe.por("0.004") : Dinero.cero(importe.moneda());
    }

    @Override
    public Dinero deTransferencia(Dinero importe) {
        return deRetiro(importe);
    }
}
