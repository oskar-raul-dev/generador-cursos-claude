package banco;

// Cada tipo sabe su política: el switch por tipo desaparece.
public enum TipoCuenta {
    AHORROS(new ComisionFija("0", "0")),
    CORRIENTE(new ComisionFija("1500", "1000")),
    NOMINA(new ComisionNomina());

    private final PoliticaComision comision;

    TipoCuenta(PoliticaComision comision) {
        this.comision = comision;
    }

    public PoliticaComision comision() {
        return comision;
    }
}
