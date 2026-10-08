# 02 — Clientes HTTP, gRPC y servicios externos

Este capítulo enseña a integrar un proveedor de pagos detrás de una capacidad propia y a decidir qué fallos externos puede entender `AuthorizePayment` sin importar un SDK o protocolo.

## 1. 🎯 El problema

`AuthorizePayment` recibe un cliente HTTP del proveedor, construye su JSON y captura sus códigos. El proveedor cambia `approved` por `authorized`, y una decisión de negocio se rompe. Un timeout después de enviar la solicitud abre una duda peor: no se sabe si el cargo ocurrió y reintentar sin identidad puede cobrar dos veces.

## 2. 🧭 Frontera y dirección

```text
AuthorizePayment ─► PaymentGateway (puerto del núcleo) ◄─ Adaptador proveedor ─► HTTP/gRPC
      │                                            │
  Authorized / Rejected              SDK, credencial, DTO, timeout
```

`PaymentGateway.authorize(operationId, amount)` nombra una capacidad requerida por el caso de uso; el adaptador traduce a URL, método, protobuf o SDK. La *anti-corruption layer* (capa que protege el lenguaje propio del modelo ajeno) convierte respuestas y errores externos a un conjunto pequeño y estable: `Authorized`, `Rejected`, `UnknownResult`, `Unavailable`. El núcleo no necesita conocer `HTTP 429`, `UNAVAILABLE` de gRPC ni la clase de excepción del cliente. [Puertos de salida](../02-nucleo-aplicacion-y-dominio/04-puertos-de-salida.md) es dueño del contrato; [errores y resultados](../02-nucleo-aplicacion-y-dominio/06-validacion-errores-y-resultados.md) define cómo se expresan fallos propios.

## 3. 🔄 Tiempo, reintentos y semántica

El adaptador fija tiempo de conexión y tiempo total o deadline; registra correlación y redacción de datos. Un error de red antes de enviar puede permitir reintento. Una desconexión después de enviar deja resultado incierto: se consulta el estado por `operationId` o se reintenta solo si el proveedor garantiza idempotencia con esa clave. La clave debe persistir con la operación; regenerarla en cada intento elimina la protección.

El reintento tiene presupuesto, espera y límite global. No repitas un rechazo definitivo ni hagas que un `timeout` local amplíe el deadline de la petición. Un circuit breaker evita mantener presión sobre una dependencia fallando; no decide si el pago debe quedar pendiente o rechazado. Un fallback solo es válido si preserva una promesa de negocio: no conviertas “no sé si autorizó” en “pago rechazado”.

El contrato externo se versiona y se verifica en integración. Las transformaciones de moneda, precisión, estado y códigos no deben esconder pérdidas. Para un proveedor de pagos, `decimal` o unidades menores enteras deben acordarse explícitamente; usar `double` sin contrato crea errores de dinero. La operación remota no participa en el commit de la base local; la estrategia de consistencia debe documentar estado pendiente, consulta y compensación.

## 4. 🧩 Implementación mínima

```java
// Contrato propio: sin HTTP ni SDK.
interface PaymentGateway {
    PaymentResult authorize(String operationId, Money amount);
}
sealed interface PaymentResult
    permits Authorized, Rejected, UnknownResult, Unavailable {}

// Adaptador: cliente reutilizable, URI y timeout configurados en composición.
final class HttpPaymentGateway implements PaymentGateway {
    private final HttpClient client;
    private final URI endpoint;
    HttpPaymentGateway(HttpClient client, URI endpoint) {
        this.client = client; this.endpoint = endpoint;
    }
    public PaymentResult authorize(String id, Money amount) {
        var request = HttpRequest.newBuilder(endpoint.resolve("/authorizations"))
            .timeout(Duration.ofSeconds(3))
            .header("Idempotency-Key", id)
            .POST(HttpRequest.BodyPublishers.ofString(PaymentDto.json(amount)))
            .build();
        try {
            var r = client.send(request, HttpResponse.BodyHandlers.ofString());
            return PaymentDto.toResult(r.statusCode(), r.body());
        } catch (HttpTimeoutException e) {
            return new UnknownResult(id);
        } catch (IOException e) {
            return new UnknownResult(id);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return new UnknownResult(id);
        }
    }
}
// Composition root: new HttpPaymentGateway(HttpClient.newHttpClient(), URI.create(baseUrl)).
```

El ejemplo ilustra el punto de traducción; `PaymentDto.toResult` debe distinguir cuidadosamente respuesta definitiva, rechazo y estado incierto, y el cliente de producción añade credenciales sin registrarlas. En Python, el mismo puerto puede componerse con un cliente de biblioteca estándar sin exportar `HTTPError` al caso de uso:

```python
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

class HttpPaymentGateway:
    def __init__(self, base_url: str): self.base_url = base_url

    def authorize(self, operation_id: str, payload: bytes):
        req = Request(self.base_url + "/authorizations", data=payload,
                      headers={"Idempotency-Key": operation_id}, method="POST")
        try:
            with urlopen(req, timeout=3) as response:
                return translate_response(response.status, response.read())
        except HTTPError as exc:
            return translate_response(exc.code, exc.read())
        except URLError:
            return UnknownResult(operation_id)
```

`payload` y `UnknownResult` son tipos del contrato de ejemplo; el adaptador real transforma `Money`, valida respuesta y configura TLS y credenciales. La incertidumbre no debe ocultarse como rechazo.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | `HttpClient` o Spring `RestClient` envían requests | mapear resultados, configurar timeout y reutilizar client | pasar `ResponseEntity` al núcleo |
| Node/TS | `fetch` y `AbortSignal` permiten cancelar | validar JSON, deadline y errores | reintentar un POST incierto sin clave |
| Go | `net/http` y `context` gestionan transporte y cancelación | acotar cliente, cuerpo y propagación | usar el cliente sin timeout |
| Python | `urllib.request` ofrece requests y timeout | traducir `HTTPError`/`URLError` y cerrar respuesta | confundir timeout con rechazo de pago |

La implementación idiomática y sus límites se desarrollan en [Java y Spring Boot](../05-plataformas-y-practica/02-java-y-spring-boot.md), [Node y TypeScript](../05-plataformas-y-practica/03-node-y-typescript.md), [Go](../05-plataformas-y-practica/04-go.md) y [Python](../05-plataformas-y-practica/05-python.md).

## 6. ⚖️ Decisión y coste

El puerto compensa si el proveedor cambia, el error externo necesita traducción o la política debe probarse sin red. Una integración trivial y estable puede usar un wrapper pequeño; interfaces y DTO gemelos sin semántica agregan ruido. En ambos casos, el contrato de `PaymentGateway` debe hacer explícito el resultado incierto. Las pruebas del adaptador usan un servidor simulado o contrato del proveedor para verificar headers, precisión, timeout y mapeo; un doble de `PaymentGateway` prueba el caso de uso.

## ⚠️ Errores frecuentes

- “El caso de uso puede usar el SDK directamente.” Sus tipos, errores y ciclo de vida pasan a dictar la política.
- “Timeout significa que no hubo cobro.” El proveedor pudo procesar antes de perderse la respuesta.
- “Todo 5xx se reintenta.” Primero se comprueba idempotencia y presupuesto.
- “Fallback es devolver aprobado.” Puede violar una promesa financiera.
- “gRPC propaga todos los deadlines por sí solo.” La conducta depende de cliente y configuración; se verifica.

## 7. ✅ Veredicto

Encapsula la integración en una capacidad de negocio, fija límites temporales y conserva la incertidumbre como estado explícito. El precio son mappers, contratos y pruebas de red; evita que una decisión de pagos dependa de un protocolo ajeno.

## 📚 Referencias

- [Java: HttpClient](https://docs.oracle.com/en/java/javase/21/docs/api/java.net.http/java/net/http/HttpClient.html)
- [Spring Framework: REST clients](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html)
- [gRPC: deadlines](https://grpc.io/docs/guides/deadlines/)
- [Node.js: fetch y AbortSignal](https://nodejs.org/api/globals.html)
- [Python: urllib.request](https://docs.python.org/3/library/urllib.request.html)

## 🧠 Preguntas

1. 🟢 ¿Qué expresa el puerto `PaymentGateway`?
2. 🟢 ¿Qué datos pertenecen al adaptador del proveedor?
3. 🟢 ¿Qué es una capa anticorrupción en esta integración?
4. 🟢 ¿Qué significa `UnknownResult`?
5. 🟢 ¿Qué diferencia hay entre timeout y rechazo?
6. 🟢 ¿Para qué sirve un deadline remoto?
7. 🟡 ¿Por qué la clave de operación debe ser estable?
8. 🟡 ¿Cuándo reintentas una autorización de pago?
9. 🟡 ¿Cómo traduces un `429` o `UNAVAILABLE` sin filtrar protocolo?
10. 🟡 ¿Qué resultados propios necesita conocer `AuthorizePayment`?
11. 🟡 ¿Qué debe hacer un circuit breaker y qué no decide?
12. 🟡 ¿Cuándo es válido un fallback?
13. 🟡 ¿Qué compruebas en el contrato externo de dinero?
14. 🟡 ¿Qué diferencia hay entre timeout de conexión y tiempo total?
15. 🟡 ¿Cómo usarías `AbortSignal` en Node sin cambiar el puerto?
16. 🟡 ¿Qué prueba requiere el adaptador además del caso de uso?
17. 🟠 El proveedor cobró y se perdió la respuesta. ¿Qué estado devuelves?
18. 🟠 Un retry usa un ID nuevo tras cada timeout. ¿Qué daño puede causar?
19. 🟠 El SDK cambia nombres de estados. ¿Dónde absorbes el cambio?
20. 🟠 Un fallback aprueba pagos cuando el proveedor cae. ¿Qué objeción haces?
21. 🟠 `HttpClient` se construye por request en Java. ¿Qué coste revisas?
22. 🟠 Python recibe `HTTPError` por un rechazo conocido. ¿Qué traduces?
23. 🟠 gRPC agota el deadline de entrada y comienza otro de 30 segundos. ¿Qué corriges?
24. 🟠 ¿Cuándo no crearías un puerto separado para un servicio externo?

**Siguiente:** [Publicación de eventos y outbox](03-publicacion-de-eventos-y-outbox.md).
