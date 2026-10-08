package hex.orders.application.port.out;

import java.util.UUID;

// Los identificadores se piden, no se inventan: en pruebas se hacen predecibles.
public interface IdGenerator {

    UUID next();
}
