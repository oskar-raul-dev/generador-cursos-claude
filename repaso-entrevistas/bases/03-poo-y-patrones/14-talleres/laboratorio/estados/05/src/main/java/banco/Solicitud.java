package banco;

// Lo que una regla necesita saber de la operación. En un retiro, destino es null.
public record Solicitud(Cuenta origen, Cuenta destino, Dinero importe) {

    public static Solicitud deRetiro(Cuenta origen, Dinero importe) {
        return new Solicitud(origen, null, importe);
    }
}
