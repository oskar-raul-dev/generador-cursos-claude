# 05 — Configuración, observabilidad y resiliencia

Este capítulo enseña a rodear `AuthorizePayment` de configuración, señales operativas y controles de fallos sin convertir al dominio en lector de variables de entorno ni en cliente de telemetría.

## 1. 🎯 El problema

El caso de uso lee `PAYMENT_TIMEOUT_MS`, escribe logs con el token del proveedor y reintenta un cobro cuando ve cualquier excepción. Un despliegue cambia la variable sin validarla y una caída del proveedor desencadena cobros repetidos. No basta mover el logger a infraestructura: la aplicación debe nombrar qué resultado merece observación y qué reintento conserva la política.

## 2. 🧭 Dos decisiones distintas

```text
config / secretos ─► composition root ─► adapters (clientes, DB, broker)
                                            │
HTTP ─► AuthorizePayment ─► PaymentGateway ─► timeout / retry / circuit breaker
              │                     │
     resultado de negocio     trazas, logs y métricas
```

El [composition root](04-composition-root-e-inyeccion-de-dependencias.md) valida configuración tipada y entrega valores al adaptador. El núcleo conoce estados como `PaymentPending`, no el nombre de una variable, trace ID o SDK. La aplicación sí define los puntos semánticos: intento, rechazo, confirmación, duplicado; infraestructura los registra. El [adaptador remoto](02-clientes-http-grpc-y-servicios-externos.md) aplica timeout, retry y circuit breaker según ese contrato.

## 3. 🔄 Configuración y secretos

Falla al iniciar si falta una URI, el timeout es negativo o el modo de pagos no es coherente. Secretos vienen de un mecanismo protegido, se rotan y no se imprimen en logs ni respuestas. Un valor de negocio, como límite máximo de pedido, puede ser política configurada; pásalo como parámetro explícito con dueño y versión. Un timeout de red es detalle del cliente. Mezclar ambos en un mapa de strings dentro del dominio dificulta pruebas y cambios seguros.

Correlación une request, comando y salida remota con un ID estable y sin datos sensibles. Un trace permite localizar latencia entre saltos; una métrica resume tasas y duración; un log describe un evento concreto. Etiquetas de métrica deben ser de cardinalidad acotada, como `result=rejected`, nunca `orderId` o correo. La identidad de operación puede aparecer en un log protegido, pero se evita registrar payload de pago o tokens. Si el proceso pasa de HTTP a mensajería, el adaptador de entrada establece contexto de trazas y el caso de uso sigue recibiendo datos propios.

## 4. 🧩 Resiliencia con presupuesto

Un timeout limita una llamada; un retry intenta de nuevo una falla transitoria; un circuit breaker deja de llamar por un tiempo cuando el destino falla. Los tres se coordinan: `3 × 3 s` de llamadas más backoff no caben en un request con deadline de `5 s`. El retry de pagos requiere clave idempotente y semántica de resultado incierto. El breaker abierto produce `Unavailable` o estado pendiente, no `Authorized`. Los límites se prueban con un servidor lento y métricas, no solo leyendo configuración.

En Java, el adaptador remoto recibe opciones validadas, y el caso de uso recibe el puerto:

```java
record PaymentConfig(URI baseUrl, Duration timeout, int maxAttempts) {
    PaymentConfig {
        if (timeout.isZero() || timeout.isNegative() || maxAttempts < 1)
            throw new IllegalArgumentException("Invalid payment configuration");
    }
}

// Composition root: new HttpPaymentGateway(sharedClient, paymentConfig)
//                  → new AuthorizePayment(paymentGateway)
```

En Go, el borde limita la operación de red y registra un resultado de adapter sin pasar logger al agregado:

```go
func (a HTTPPaymentGateway) Authorize(ctx context.Context, id string, amount Money) (PaymentResult, error) {
    ctx, cancel := context.WithTimeout(ctx, a.Timeout)
    defer cancel()
    result, err := a.send(ctx, id, amount)
    a.Log.Info("authorize_payment", "result", classify(result, err))
    return result, err
}
// main construye HTTPPaymentGateway con cliente, timeout y logger validados.
```

`classify` produce una etiqueta de baja cardinalidad; el logger no ve tokens ni montos. El ejemplo no implementa retry: aplicarlo requiere la clasificación de idempotencia y el presupuesto total descritos arriba.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring Boot Actuator/Micrometer instrumenta; Resilience4j ofrece circuit breaker | elegir señales, scopes y presupuestos | anotar retries sin conocer semántica del pago |
| Node/TS | `AsyncLocalStorage` propaga contexto; NestJS configura providers | validar ambiente y evitar pérdida de correlación | usar contexto implícito como autorización |
| Go | `context` y `log/slog` soportan deadline y logs estructurados | pasar cancelación y limitar etiquetas | usar ID de pedido como label de métrica |
| Python | `logging` y variables de entorno están disponibles | tipar config y preservar correlación async | registrar secretos al depurar |

## 6. ⚖️ Decisión y coste

Instrumenta un flujo completo antes de multiplicar métricas: tasa de pedidos creados, rechazos de negocio, errores técnicos, latencia del proveedor y edad de outbox. Cada señal tiene almacenamiento, cardinalidad y atención humana. Un circuit breaker sin umbral y observación claros puede ocultar una recuperación; una métrica sin dueño no ayuda. El núcleo no tiene que importar telemetría para que su semántica sea observable.

## ⚠️ Errores frecuentes

- “Observabilidad es responsabilidad exclusiva de infraestructura.” Solo la aplicación sabe qué significa `OrderConfirmed`.
- “Más retries siempre mejoran resiliencia.” Pueden amplificar la caída y duplicar efectos.
- “El trace ID es identidad de negocio.” Sirve para diagnóstico, no para idempotencia.
- “Un log de request completo ayuda.” Puede incluir tokens y datos de pago.
- “El circuit breaker corrige la política.” Solo controla llamadas; la aplicación decide qué hacer sin proveedor.

## 7. ✅ Veredicto

Valida configuración al arrancar, pasa dependencias tipadas y observa resultados con etiquetas acotadas. Timeout, retry y breaker pertenecen al borde remoto, bajo un presupuesto compatible con la semántica del caso de uso. El coste es operación y pruebas de falla, no cambios al modelo de dominio.

## 📚 Referencias

- [OpenTelemetry: señales](https://opentelemetry.io/docs/concepts/signals/)
- [OpenTelemetry: cardinalidad de métricas](https://opentelemetry.io/docs/concepts/signals/metrics/)
- [Spring Boot: observabilidad](https://docs.spring.io/spring-boot/reference/actuator/observability.html)
- [Resilience4j: circuit breaker](https://resilience4j.readme.io/docs/circuitbreaker)
- [Go: log/slog](https://pkg.go.dev/log/slog)
- [Node.js: AsyncLocalStorage](https://nodejs.org/api/async_context.html)

## 🧠 Preguntas

1. 🟢 ¿Dónde se validan las opciones de despliegue?
2. 🟢 ¿Qué configuración pertenece al adaptador remoto?
3. 🟢 ¿Qué dato puede ser política configurable del núcleo?
4. 🟢 ¿Qué diferencia hay entre log, métrica y traza?
5. 🟢 ¿Qué es un identificador de correlación?
6. 🟢 ¿Qué limita un timeout?
7. 🟢 ¿Qué hace un circuit breaker?
8. 🟡 ¿Por qué no lees variables de entorno desde `Order`?
9. 🟡 ¿Cómo observas `OrderConfirmed` sin importar un SDK en el dominio?
10. 🟡 ¿Por qué `orderId` es mala etiqueta de métrica?
11. 🟡 ¿Qué debe ocurrir si falta un secreto obligatorio?
12. 🟡 ¿Cómo calculas presupuesto de retry y deadline?
13. 🟡 ¿Cuándo reintentas un cobro remoto?
14. 🟡 ¿Para qué sirve `AsyncLocalStorage` en Node?
15. 🟡 ¿Qué aporta `log/slog` de Go y qué no decide?
16. 🟡 ¿Qué métrica muestra atasco de outbox?
17. 🟠 Un retry de tres intentos supera el deadline HTTP. ¿Qué ajustas?
18. 🟠 Un log contiene tokens del proveedor. ¿Qué corriges?
19. 🟠 El breaker abre y el caso de uso devuelve pago aprobado. ¿Qué falla?
20. 🟠 Una métrica etiqueta cada `customerId`. ¿Qué riesgo causa?
21. 🟠 Un worker pierde la correlación al procesar un mensaje. ¿Dónde la restableces?
22. 🟠 Una variable de timeout vale `-1` y se descubre en producción. ¿Qué prueba falta?
23. 🟠 El equipo quiere meter `traceId` en la entidad `Order`. ¿Qué respondes?
24. 🟠 ¿Cuándo no introducirías circuit breaker en una integración?

**Siguiente:** [Testing por anillos y contratos](06-testing-por-anillos-y-contratos.md).
