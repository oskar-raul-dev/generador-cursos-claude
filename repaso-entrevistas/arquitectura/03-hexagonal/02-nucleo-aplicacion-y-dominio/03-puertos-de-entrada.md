# 03 — Puertos de entrada

Un puerto de entrada es la API que el núcleo ofrece a sus drivers. Su objetivo es que HTTP, una cola, un job y una prueba activen la misma intención sin compartir el vocabulario de transporte.

## 1. 🎯 El problema

Si el port se diseña copiando un endpoint, el cambio de transporte cambia la aplicación. `POST /orders` y un mensaje `OrderRequested` pueden activar el mismo caso de uso, pero no tienen los mismos headers, ACK, status codes o reintentos. Esa traducción se concreta en [HTTP como adaptador](../03-adaptadores-de-entrada/01-http-como-adaptador-de-entrada.md) y en [consumidores de mensajes](../03-adaptadores-de-entrada/02-mensajeria-consumidores-y-comandos.md).

## 2. 🧱 Contrato de intención

```text
HTTP request ─► adapter ─► CreateOrderCommand ─► CreateOrderPort
mensaje      ─► adapter ─► CreateOrderCommand ─► CreateOrderPort
test         ─► adapter ─► CreateOrderCommand ─► CreateOrderPort
```

El port puede ser una interfaz, una función o un módulo. Debe expresar intención, tener entrada y salida propias y no filtrar `Request`, `Response`, headers ni metadatos del broker.

## 3. 🧭 Comandos, queries e idempotencia

Un comando pide un cambio; una query obtiene información. La idempotencia es parte del contrato cuando el driver puede repetir: puede expresarse con una clave de operación propia, no con el objeto HTTP.

```typescript
type CreateOrderCommand = {
  customerId: string;
  items: readonly ItemCommand[];
  operationId: string;
};

interface CreateOrderPort {
  execute(command: CreateOrderCommand): Promise<OrderResult>;
}
```

La validación de forma puede vivir en el adapter. La validación de negocio debe repetirse en el núcleo porque otros drivers también pueden invocarlo.

## 4. 🧰 Comparación

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | interfaces, records y validadores | contrato independiente del web layer | recibir `HttpServletRequest` |
| Node/TS | tipos estáticos y async | validación runtime y errores | creer que `type` valida entrada |
| Go | funciones e interfaces pequeñas | errores y contexto explícitos | pasar `*http.Request` al núcleo |
| Python | funciones y Protocols opcionales | forma runtime y disciplina | usar `dict` sin contrato |

## 5. ⚖️ Decisión y coste

Diseña el port desde el caso de uso hacia afuera. Si un endpoint necesita campos que el negocio no usa, el adapter los descarta. Si dos drivers tienen intenciones distintas, crea dos comandos aunque compartan parte de sus datos.

## ⚠️ Errores frecuentes

- “El port de entrada debe reflejar el endpoint.” Debe reflejar una capacidad.
- “TypeScript valida el JSON.” Los tipos desaparecen en runtime.
- “La idempotencia es solo HTTP.” También importa en mensajes y jobs.
- “El port solo necesita parámetros primitivos.” Usa tipos propios cuando protejan semántica.

## 6. ✅ Veredicto

Define el puerto desde la intención estable de aplicación y deja método, ruta, ACK y serialización en sus drivers. Usa la forma más simple que mantenga ese contrato visible.

## 📚 Referencias

- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un puerto de entrada?
2. 🟢 ¿Por qué no debe reflejar un endpoint?
3. 🟢 ¿Qué diferencia hay entre comando y query?
4. 🟢 ¿Qué es una intención de negocio?
5. 🟢 ¿Qué datos pertenecen al transporte?
6. 🟢 ¿Qué significa que un port sea estable?
7. 🟢 ¿Dónde se valida la forma del request?
8. 🟡 ¿Dónde se valida una invariante?
9. 🟡 ¿Cómo expresas idempotencia?
10. 🟡 ¿Qué devuelve un port de entrada?
11. 🟡 ¿Cuándo compartirías un command?
12. 🟡 ¿Cuándo separarías dos commands?
13. 🟡 ¿Qué coste tiene mapear request a command?
14. 🟡 ¿Cómo pruebas el contrato de entrada?
15. 🟡 ¿Qué diferencia hay entre tipo estático y validación runtime?
16. 🟡 ¿Por qué un `dict` puede ser un contrato débil?
17. 🟠 HTTP y mensajería usan campos distintos. ¿Cómo los unes?
18. 🟠 Un mensaje se redelivera. ¿Quién protege la idempotencia?
19. 🟠 El port recibe headers de autenticación. ¿Qué cambias?
20. 🟠 Una query necesita paginación. ¿Qué parte es transporte?
21. 🟠 ¿Qué haces si un driver necesita una operación que otro no?
22. 🟠 ¿Cómo versionas un port de entrada?
23. 🟠 ¿Qué evidencia muestra que el port está acoplado a HTTP?
24. 🟠 ¿Cuándo un port de entrada puede ser una función?

**Siguiente:** [Puertos de salida](04-puertos-de-salida.md).
