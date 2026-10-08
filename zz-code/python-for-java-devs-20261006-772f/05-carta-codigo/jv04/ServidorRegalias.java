import com.sun.net.httpserver.HttpServer;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

public class ServidorRegalias {
    static BigDecimal regalia(BigDecimal ventas, BigDecimal tasa) {
        return ventas.multiply(tasa).setScale(0, RoundingMode.HALF_EVEN);
    }

    static void reply(com.sun.net.httpserver.HttpExchange ex, String text) throws java.io.IOException {
        byte[] body = text.getBytes(StandardCharsets.UTF_8);
        ex.sendResponseHeaders(200, body.length);
        try (var out = ex.getResponseBody()) { out.write(body); }
    }

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8090), 0);
        server.createContext("/regalia", ex -> {             // GET ?ventas=…&tasa=…  → una regalía
            var q = ex.getRequestURI().getQuery().split("[=&]");
            reply(ex, regalia(new BigDecimal(q[1]), new BigDecimal(q[3])).toPlainString());
        });
        server.createContext("/regalias", ex -> {            // POST ?tasa=…, una venta por línea → una regalía por línea
            var tasa = new BigDecimal(ex.getRequestURI().getQuery().split("=")[1]);
            var body = new String(ex.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            reply(ex, body.lines().map(v -> regalia(new BigDecimal(v), tasa).toPlainString())
                          .collect(Collectors.joining("\n")));
        });
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        server.start();
        System.out.println("servicio Java en :8090");
    }
}
