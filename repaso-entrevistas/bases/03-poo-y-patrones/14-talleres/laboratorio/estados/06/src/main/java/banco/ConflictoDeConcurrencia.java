package banco;

// Alguien guardó la cuenta entre que la leíste y la quisiste guardar.
public class ConflictoDeConcurrencia extends RuntimeException {

    public ConflictoDeConcurrencia(String numero) {
        super("la cuenta " + numero + " cambió mientras se operaba");
    }
}
