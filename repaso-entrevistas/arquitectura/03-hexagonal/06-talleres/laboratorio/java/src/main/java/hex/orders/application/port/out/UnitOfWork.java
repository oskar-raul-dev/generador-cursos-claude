package hex.orders.application.port.out;

import java.util.function.Supplier;

// El límite transaccional como capacidad: "ejecuta esto y confirma todo o nada". Así el caso de
// uso delimita la consistencia sin importar @Transactional ni saber que existe un proxy.
public interface UnitOfWork {

    <T> T run(Supplier<T> work);

    default void run(Runnable work) {
        run(() -> {
            work.run();
            return null;
        });
    }
}
