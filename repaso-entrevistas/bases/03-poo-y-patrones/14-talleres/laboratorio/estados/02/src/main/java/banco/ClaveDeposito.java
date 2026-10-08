package banco;

// Lo que identifica a un depósito que la pasarela puede reintentar.
public record ClaveDeposito(String numeroCuenta, Dinero monto, String referencia) {
}
