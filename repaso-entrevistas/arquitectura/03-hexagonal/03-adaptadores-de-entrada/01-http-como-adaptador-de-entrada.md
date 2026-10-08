# 01 — HTTP como adaptador de entrada

Este capítulo enseña a decidir qué debe traducir un controller para que `CreateOrder` siga siendo una capacidad de aplicación y no una implementación de `POST /orders`.

## 1. 🎯 El problema

Un controller recibe JSON, consulta el repositorio, reserva inventario y devuelve una entidad JPA. Parece corto, hasta que un consumidor también debe crear pedidos: copia reglas, inventa otro mapeo de errores y descubre que el caso de uso dependía de HTTP. El síntoma es una política duplicada por transporte.

## 2. 🧭 Frontera y dirección

```text
cliente HTTP ─► router/controller ─► CreateOrderCommand ─► CreateOrder
                 │     ▲                                │
                 │     └──── resultado o error propio ──┘
                 └─ DTO, identidad, status, headers y JSON
```

El adaptador de entrada depende del puerto de entrada; el núcleo no importa `Request`, `ResponseEntity`, decoradores ni códigos HTTP. El borde autentica la petición y comprueba forma, tamaño y tipos. La aplicación autoriza en contexto y el dominio conserva las invariantes, como explican [puertos de entrada](../02-nucleo-aplicacion-y-dominio/03-puertos-de-entrada.md) y [validación y errores](../02-nucleo-aplicacion-y-dominio/06-validacion-errores-y-resultados.md).

## 3. 🔄 Diseño y flujo

1. El router identifica versión, método y ruta; el framework deserializa con límites de tamaño.
2. El controller valida formato y crea `CreateOrderCommand` con `customerId`, líneas y una clave de operación. Esa clave es un dato estable de aplicación; no pasa el objeto `HttpRequest`.
3. `CreateOrder` ejecuta autorización contextual, reglas y persistencia mediante sus puertos.
4. El controller proyecta `OrderCreated` a un response DTO y decide `201`, `Location` y serialización. Un traductor central convierte errores propios en una respuesta segura.

La paginación de consultas también se traduce: `limit` se acota en el borde y se transforma en una petición de lectura; el núcleo puede usar una noción propia de página o cursor sin conocer query strings. Un cursor opaco público se codifica y decodifica en el adaptador. La clave de idempotencia de HTTP se valida en el borde, pero la protección debe persistir donde se confirma el efecto, porque un mensaje o job también puede repetir el comando. El coste es mantener DTO y mappers; se justifica cuando protege varias entradas o versiones.

## 4. 🧩 Implementación mínima

Las piezas siguientes ilustran el contrato, la traducción y la composición. `CreateOrder` recibe un comando propio; una configuración externa le inyecta su implementación.

```java
// Núcleo: sin imports de Spring.
record CreateOrderCommand(String customerId, int units, String operationId) {}
record OrderCreated(String orderId) {}
interface CreateOrder { OrderCreated execute(CreateOrderCommand command); }

// Adaptador HTTP.
record CreateOrderRequest(String customerId, int units) {}
record OrderResponse(String id) {}

@RestController
class OrderController {
    private final CreateOrder createOrder;
    OrderController(CreateOrder createOrder) { this.createOrder = createOrder; }

    @PostMapping("/orders")
    ResponseEntity<OrderResponse> create(@RequestBody CreateOrderRequest body,
                                          @RequestHeader("Idempotency-Key") String key) {
        var created = createOrder.execute(
            new CreateOrderCommand(body.customerId(), body.units(), key));
        return ResponseEntity.created(URI.create("/orders/" + created.orderId()))
            .body(new OrderResponse(created.orderId()));
    }
}
```

La validación de `body` y `key`, autenticación, mapeo de errores y registro del bean se configuran alrededor de este recorte; omitirlos en producción cambiaría el comportamiento. El mismo contrato puede expresarse en NestJS sin pasar un DTO decorado al núcleo:

```typescript
import { BadRequestException, Body, Controller, Headers, Inject, Post } from '@nestjs/common';

type CreateOrderDto = { customerId: string; units: number };
function parseOrder(body: unknown): CreateOrderDto {
  if (typeof body !== 'object' || body === null) throw new BadRequestException();
  const value = body as Record<string, unknown>;
  if (typeof value.customerId !== 'string' ||
      typeof value.units !== 'number' || !Number.isInteger(value.units)) {
    throw new BadRequestException();
  }
  return { customerId: value.customerId, units: value.units };
}

interface CreateOrder {
  execute(command: { customerId: string; units: number; operationId: string }):
    Promise<{ orderId: string }>;
}
const CREATE_ORDER = Symbol('CREATE_ORDER');

@Controller('orders')
class OrderController {
  constructor(@Inject(CREATE_ORDER) private readonly createOrder: CreateOrder) {}

  @Post()
  async create(@Body() body: unknown, @Headers('idempotency-key') key: string) {
    const order = parseOrder(body);
    if (!key) throw new BadRequestException();
    const created = await this.createOrder.execute({
      customerId: order.customerId, units: order.units, operationId: key,
    });
    return { id: created.orderId };
  }
}
```

La configuración de Nest enlaza el token del puerto con el caso de uso. La validación runtime explícita impide confiar en el tipo TypeScript; el adaptador todavía debe fijar la respuesta pública, incluida `Location` si el contrato la exige.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring MVC enlaza rutas, cuerpos y respuestas | DTO, validación, traducción e inyección del puerto | devolver la entidad JPA |
| Node/TS | NestJS aporta controllers, pipes y filtros | validar en runtime y registrar el token del puerto | pasar `Request` al caso de uso |
| Go | `net/http` aporta `Handler`, request y response | decodificar con límites y componer dependencias | meter SQL en `ServeHTTP` |
| Python | FastAPI aporta parsing, modelos de entrada y handlers | separar modelos externos de comandos y errores | lanzar `HTTPException` desde dominio |

## 6. ⚖️ Decisión y coste

Un controller puede ser pequeño sin ser vacío: traduce protocolo, identidad, validación de forma y representación. Para un CRUD estable con una sola entrada, duplicar cada campo en tres clases puede ser ceremonia; aun así, mantiene las reglas fuera de HTTP. Si llegan otra entrada o versiones públicas, el coste del mapper suele pagar la separación. La prueba útil verifica que la petición real se convierte en el comando esperado y que cada error produce el contrato HTTP correcto; una prueba unitaria del caso de uso cubre otra frontera.

## ⚠️ Errores frecuentes

- “El controller llama al repositorio porque es simple.” Así la decisión de negocio queda atada al transporte.
- “El DTO del framework es el comando.” Sus decoradores, defaults y semántica de versión pueden cambiar sin que cambie la intención.
- “El header resuelve la idempotencia.” La protección tiene que sobrevivir a reintentos y caídas en el límite de persistencia.
- “Un `catch` global convierte todo en 400.” Confunde rechazos de negocio con fallos técnicos.

## 7. ✅ Veredicto

Haz que HTTP entregue una intención y reciba un resultado propio. El adaptador conoce el protocolo; la política no. Conserva explícitos el coste del mapeo y la responsabilidad de probar la traducción.

## 📚 Referencias

- [Spring Framework: controllers anotados](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller.html)
- [NestJS: controllers](https://docs.nestjs.com/controllers)
- [Go: paquete net/http](https://pkg.go.dev/net/http)
- [FastAPI: manejo de errores](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [RFC 9457: Problem Details](https://www.rfc-editor.org/rfc/rfc9457.html)

## 🧠 Preguntas

1. 🟢 ¿Qué hace un adaptador HTTP de entrada?
2. 🟢 ¿Qué información pertenece al controller y no al dominio?
3. 🟢 ¿Qué diferencia hay entre request DTO y comando?
4. 🟢 ¿Quién decide el status HTTP de `OrderCreated`?
5. 🟢 ¿Dónde se valida que un JSON tenga la forma correcta?
6. 🟢 ¿Por qué `CreateOrder` no debe recibir `HttpRequest`?
7. 🟢 ¿Qué devuelve el puerto de entrada al controller?
8. 🟡 ¿Qué hace delgado a un controller sin volverlo inútil?
9. 🟡 ¿Cómo traduces `InsufficientInventory` a HTTP?
10. 🟡 ¿Dónde acotas `limit` en una consulta paginada?
11. 🟡 ¿Qué parte de una clave de idempotencia cruza al caso de uso?
12. 🟡 ¿Por qué no basta comprobar la clave en memoria del controller?
13. 🟡 ¿Qué probarías en el adaptador HTTP además del caso de uso?
14. 🟡 ¿Por qué TypeScript necesita validación runtime de `@Body()`?
15. 🟡 ¿Qué ventaja tiene un traductor central de errores de Spring?
16. 🟡 ¿Cuándo el mapper de DTO puede ser ceremonia innecesaria?
17. 🟠 Un controller llama directamente a JPA para crear un pedido. ¿Qué extraes primero?
18. 🟠 Una nueva versión HTTP cambia nombres de campos. ¿Debe cambiar `CreateOrder`?
19. 🟠 El mismo comando llega por HTTP y por cola. ¿Dónde deduplicas?
20. 🟠 Un cliente ve el mensaje de una excepción SQL. ¿Qué frontera falló?
21. 🟠 En Go, `ServeHTTP` ejecuta reglas e inserta SQL. ¿Cómo lo refactorizas?
22. 🟠 En FastAPI, el dominio lanza `HTTPException`. ¿Qué contrato introduces?
23. 🟠 Una consulta acepta `limit=1000000`. ¿Cómo proteges el sistema sin contaminar el dominio?
24. 🟠 ¿Qué evidencia demuestra que el controller contiene política de negocio?

**Siguiente:** [Mensajería, consumidores y comandos](02-mensajeria-consumidores-y-comandos.md).
