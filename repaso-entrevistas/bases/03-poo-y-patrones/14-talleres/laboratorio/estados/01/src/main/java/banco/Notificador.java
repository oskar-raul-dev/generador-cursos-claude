package banco;

import java.util.ArrayList;
import java.util.List;

// Manda los correos. En este módulo, los imprime y los guarda.
public class Notificador {

    public static final List<String> ENVIADOS = new ArrayList<>();   // para poder mirarlos

    public void enviar(String email, String mensaje) {
        String correo = email + ": " + mensaje;
        ENVIADOS.add(correo);
        System.out.println("[CORREO] " + correo);
    }
}
