package co.coodrosan.contingencia.soap;

import jakarta.xml.ws.handler.MessageContext;
import jakarta.xml.ws.handler.soap.SOAPHandler;
import jakarta.xml.ws.handler.soap.SOAPMessageContext;
import jakarta.xml.soap.SOAPException;
import jakarta.xml.soap.SOAPFactory;
import jakarta.xml.ws.soap.SOAPFaultException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.xml.namespace.QName;

// HTTP Basic para los servicios SOAP, contra SOAP_USER y SOAP_PASSWORD. Sin credenciales: fault "No autorizado".
public class BasicAuthHandler implements SOAPHandler<SOAPMessageContext> {

    @Override
    public boolean handleMessage(SOAPMessageContext ctx) {
        if (Boolean.TRUE.equals(ctx.get(MessageContext.MESSAGE_OUTBOUND_PROPERTY))) {
            return true;
        }
        @SuppressWarnings("unchecked")
        Map<String, List<String>> headers = (Map<String, List<String>>) ctx.get(MessageContext.HTTP_REQUEST_HEADERS);
        String expected = "Basic " + Base64.getEncoder().encodeToString(
            (System.getenv("SOAP_USER") + ":" + System.getenv("SOAP_PASSWORD")).getBytes(StandardCharsets.UTF_8));
        List<String> auth = headers == null ? null : headers.entrySet().stream()
            .filter(e -> "authorization".equalsIgnoreCase(e.getKey())).map(Map.Entry::getValue).findFirst().orElse(null);
        if (auth == null || !auth.contains(expected)) {
            // Un fault SOAP, como cualquier otro error del servicio: así lo esperan las cajas desde 2008.
            try {
                throw new SOAPFaultException(SOAPFactory.newInstance().createFault(
                    "No autorizado", new QName("http://schemas.xmlsoap.org/soap/envelope/", "Client")));
            } catch (SOAPException e) {
                throw new IllegalStateException(e);
            }
        }
        return true;
    }

    @Override
    public boolean handleFault(SOAPMessageContext ctx) { return true; }

    @Override
    public void close(MessageContext ctx) { }

    @Override
    public Set<QName> getHeaders() { return Set.of(); }
}
