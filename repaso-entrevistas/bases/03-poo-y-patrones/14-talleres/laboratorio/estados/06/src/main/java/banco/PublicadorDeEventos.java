package banco;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.Consumer;

// Observer: los suscriptores se enteran de lo que pasó, y el que publica no sabe quiénes son.
public class PublicadorDeEventos {

    private final List<Consumer<EventoDeCuenta>> suscriptores = new CopyOnWriteArrayList<>();

    public void suscribir(Consumer<EventoDeCuenta> suscriptor) {
        suscriptores.add(suscriptor);
    }

    public void publicar(List<EventoDeCuenta> eventos) {
        for (EventoDeCuenta e : eventos) {
            for (Consumer<EventoDeCuenta> s : suscriptores) {
                s.accept(e);
            }
        }
    }
}
