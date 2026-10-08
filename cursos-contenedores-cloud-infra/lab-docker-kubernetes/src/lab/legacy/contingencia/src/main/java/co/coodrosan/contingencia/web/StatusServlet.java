package co.coodrosan.contingencia.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;

// La regla de encendido de 2016: Contingencia se prende cuando el Siga NO CONTESTA.
// Que conteste tarde no cuenta: con eso basta para que no se prenda nunca en una noche lenta.
@WebServlet("/status")
public class StatusServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String central = System.getenv("SIGA_CENTRAL_URL");
        String mode = (central == null || central.isEmpty() || !connects(central)) ? "ACTIVE" : "STANDBY";
        resp.setContentType("application/json");
        resp.getWriter().write("{\"mode\":\"" + mode + "\",\"rule\":\"el central no contesta\"}");
    }

    // Solo prueba que el puerto acepte la conexión. Un central lento, pero vivo, la acepta.
    private static boolean connects(String url) {
        URI uri = URI.create(url);
        int port = uri.getPort() > 0 ? uri.getPort() : 80;
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(uri.getHost(), port), 5_000);
            return true;
        } catch (IOException e) {
            return false;
        }
    }
}
