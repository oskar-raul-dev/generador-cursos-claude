package banco;

// Chain of Responsibility: cada eslabón comprueba lo suyo y pasa al siguiente; el que lanza, corta la cadena.
public abstract class Regla {

    private Regla siguiente;

    public static Regla cadena(Regla primera, Regla... resto) {
        Regla actual = primera;
        for (Regla r : resto) {
            actual.siguiente = r;
            actual = r;
        }
        return primera;
    }

    public final void verificar(Solicitud s) {
        comprobar(s);
        if (siguiente != null) {
            siguiente.verificar(s);
        }
    }

    protected abstract void comprobar(Solicitud s);
}
