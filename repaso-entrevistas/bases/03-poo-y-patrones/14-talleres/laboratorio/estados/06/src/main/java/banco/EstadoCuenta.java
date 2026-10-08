package banco;

// State: qué permite cada estado y a cuál pasa. Las transiciones viven aquí y solo aquí.
public enum EstadoCuenta {

    ABIERTA {
        @Override void alDepositar(String numero) { }
        @Override void alRetirar(String numero) { }
        @Override void alRecibir(String numero) { }
        @Override EstadoCuenta alBloquear(String numero) { return BLOQUEADA; }
        @Override EstadoCuenta alDesbloquear(String numero) { return ABIERTA; }
        @Override EstadoCuenta alCerrar(String numero, Dinero saldo) {
            if (!saldo.esCero()) throw new IllegalStateException("para cerrar, el saldo debe ser cero");
            return CERRADA;
        }
    },

    BLOQUEADA {
        @Override void alDepositar(String numero) { }   // una cuenta bloqueada sí recibe depósitos
        @Override void alRetirar(String numero) {
            throw new IllegalStateException("la cuenta " + numero + " está bloqueada");
        }
        @Override void alRecibir(String numero) {
            throw new IllegalStateException("la cuenta destino " + numero + " está bloqueada");
        }
        @Override EstadoCuenta alBloquear(String numero) { return BLOQUEADA; }
        @Override EstadoCuenta alDesbloquear(String numero) { return ABIERTA; }
        @Override EstadoCuenta alCerrar(String numero, Dinero saldo) {
            throw new IllegalStateException("una cuenta bloqueada no se puede cerrar");
        }
    },

    CERRADA {
        @Override void alDepositar(String numero) {
            throw new IllegalStateException("la cuenta " + numero + " está cerrada");
        }
        @Override void alRetirar(String numero) {
            throw new IllegalStateException("la cuenta " + numero + " está cerrada");
        }
        @Override void alRecibir(String numero) {
            throw new IllegalStateException("la cuenta destino " + numero + " está cerrada");
        }
        @Override EstadoCuenta alBloquear(String numero) {
            throw new IllegalStateException("una cuenta cerrada no se puede bloquear");
        }
        @Override EstadoCuenta alDesbloquear(String numero) {
            throw new IllegalStateException("una cuenta cerrada no se puede desbloquear");
        }
        @Override EstadoCuenta alCerrar(String numero, Dinero saldo) { return CERRADA; }
    };

    abstract void alDepositar(String numero);

    abstract void alRetirar(String numero);   // vale también para enviar una transferencia

    abstract void alRecibir(String numero);

    abstract EstadoCuenta alBloquear(String numero);

    abstract EstadoCuenta alDesbloquear(String numero);

    abstract EstadoCuenta alCerrar(String numero, Dinero saldo);
}
