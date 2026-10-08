# 05 — DTO, mapeo y presentación de errores

Este capítulo enseña a decidir cuándo un DTO protege un contrato externo y cuándo solo copia campos. También muestra cómo presentar errores estables sin serializar entidades o excepciones internas.

## 1. 🎯 El problema

Un controller devuelve `OrderEntity` porque ya se serializa a JSON. La entidad gana una relación lazy, una columna interna y un campo de pago; la respuesta pública cambia o dispara consultas inesperadas. El modelo de persistencia acaba definiendo una API sin una decisión explícita.

## 2. 🧭 Tres formas, tres dueños

```text
JSON v1 ─► Request DTO ─► CreateOrderCommand ─► caso de uso
                                               │
JSON v1 ◄─ Response DTO ◄─ OrderCreated ◄───────┘
```

El request DTO pertenece al contrato HTTP: nombres, formato, campos opcionales y versión. El comando pertenece a la aplicación: intención y datos suficientes para ejecutarla. El response DTO pertenece a la representación pública: qué mostrar y cómo serializar. El adaptador depende del contrato de aplicación; el núcleo no depende del DTO, del ORM ni del serializador. La [validación de negocio](../02-nucleo-aplicacion-y-dominio/06-validacion-errores-y-resultados.md) sigue en su capa aunque el DTO valide forma.

No todo salto requiere una clase: un mapper manual puede construir el comando directamente. Para un CRUD interno estable, duplicar un objeto idéntico sin proteger ninguna evolución puede ser una ceremonia que se revisa cuando aparece un segundo consumidor o una API pública. Nunca se justifica exponer una entidad de persistencia solo porque el serializador pueda leerla.

## 3. 🔄 Mapeo y versión

Un mapeo de entrada transforma `customer_id` de v1 o `customerId` de v2 al mismo `customerId` del comando. Aplica defaults de contrato en el borde, registra conversiones potencialmente ambiguas y rechaza datos que no puede interpretar. El caso de uso no contiene `if (apiVersion == 2)`. Un mapeo de salida elige campos públicos, unidades, zona horaria y tratamiento de nulos; la serialización del framework no decide por accidente la política de exposición.

Cuando un proveedor o cliente externo usa conceptos distintos, el mapeo funciona como una pequeña *anti-corruption layer* (capa de traducción que impide que su modelo se vuelva el nuestro), como en el [adaptador de servicios externos](../04-adaptadores-de-salida-y-operacion/02-clientes-http-grpc-y-servicios-externos.md). El precio es código repetitivo y pruebas de compatibilidad. Un generador de mappers reduce asignaciones mecánicas, pero conversiones con sentido de negocio, pérdida de datos o defaults necesitan decisiones explícitas y pruebas. La compatibilidad de una respuesta versionada se verifica con ejemplos o contratos, no solo compilando.

## 4. 🧩 Errores como representación

El núcleo puede devolver `InsufficientInventory` o lanzar un error tipado propio. El adaptador decide el status, un código estable para máquinas, texto seguro y correlación. RFC 9457 define `type`, `title`, `status`, `detail` e `instance` para respuestas de problema; no obliga a exponer mensajes de excepciones ni información de SQL. Una tabla de traducción evita respuestas divergentes:

| Error propio | HTTP | Cuerpo público |
|---|---|---|
| `InvalidRequest` | 400 | código y campos corregibles |
| `AccessDenied` | 403 o respuesta que no revele existencia | mensaje genérico y correlación |
| `InsufficientInventory` | 409, según contrato | código estable y acción posible |
| fallo técnico inesperado | 500 | mensaje genérico y correlación |

Los status son decisiones del contrato, no propiedades del dominio. Un error de entrada que se traduce a 400 no debería provocar un reintento de mensajería; cada adaptador expresa su propia reacción sobre el mismo error propio.

## 5. 🧩 Implementación mínima

```java
record CreateOrderRequestV2(String customerId, int units) {}
record CreateOrderCommand(String customerId, int units) {}
record OrderCreated(String orderId, String status) {}
record OrderResponseV2(String id, String status) {}

final class OrderHttpMapper {
    CreateOrderCommand toCommand(CreateOrderRequestV2 r) {
        return new CreateOrderCommand(r.customerId(), r.units());
    }
    OrderResponseV2 toResponse(OrderCreated r) {
        return new OrderResponseV2(r.orderId(), r.status());
    }
}
```

El controller inyecta `CreateOrder` y usa `OrderHttpMapper` antes y después de ejecutarlo; un `@ControllerAdvice` traduce errores. El composition root ensambla esas piezas. Este recorte muestra asignación, no validación runtime ni un serializador seguro por sí mismo.

## 6. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | records, Jackson y herramientas de mapeo | contrato público y revisión de campos | serializar una entidad JPA |
| Node/TS | tipos y transformadores disponibles | validación runtime y mapeo de versión | creer que `interface` filtra campos al responder |
| Go | structs y tags JSON | separar DTO externos de modelo interno | reutilizar un struct con tags para dominio y DB |
| Python | modelos de entrada/salida y serialización | elegir campos y errores públicos | devolver un objeto ORM con relaciones cargables |

Un mapper generado ayuda cuando las asignaciones son muchas y triviales; uno manual suele ser más claro cuando la traducción incluye reglas de compatibilidad. Ninguno reemplaza pruebas de contrato.

## 7. ⚖️ Decisión y coste

Introduce DTO separados cuando la API es pública, versionada, contiene campos sensibles, difiere del modelo o cambia a otro ritmo. Simplifica la duplicación si una frontera no aporta protección real, pero conserva la dirección de dependencias. Verifica que una respuesta no incluya campos internos, que los defaults de v1 y v2 conduzcan al mismo comando y que los errores sean seguros y estables.

## ⚠️ Errores frecuentes

- “Puedo devolver la entidad JPA porque tiene JSON.” El contrato queda a merced de mappings, lazy loading y campos nuevos.
- “Cada clase merece un DTO gemelo.” La traducción solo compensa cuando protege una diferencia real.
- “El mapper generado decide la compatibilidad.” Puede copiar campos; no conoce intención ni consecuencias.
- “Problem Details es un stack trace bonito.” Su fin es un problema público legible por máquinas, sin filtrar implementación.
- “Versionar la ruta obliga a versionar el caso de uso.” Dos adaptadores pueden traducir al mismo comando.

## 8. ✅ Veredicto

Diseña los DTO como contratos del borde y usa mappers donde haya una diferencia que proteger. Traduce errores una vez por transporte y mantén el núcleo fuera de la serialización. Paga código de mapeo a cambio de evolución controlada, no por simetría estética.

## 📚 Referencias

- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [Spring Framework: error responses](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-rest-exceptions.html)
- [FastAPI: response model](https://fastapi.tiangolo.com/tutorial/response-model/)
- [Go: encoding/json](https://pkg.go.dev/encoding/json)
- [TypeScript: type erasure in JavaScript output](https://www.typescriptlang.org/docs/handbook/2/basic-types.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un request DTO?
2. 🟢 ¿Qué diferencia hay entre comando y request DTO?
3. 🟢 ¿Qué es un response DTO?
4. 🟢 ¿Quién decide los campos públicos de un pedido?
5. 🟢 ¿Qué problema causa serializar una entidad JPA?
6. 🟢 ¿Qué expresa un código de error estable?
7. 🟢 ¿Qué es Problem Details según RFC 9457?
8. 🟡 ¿Cuándo compensa separar DTO y comando?
9. 🟡 ¿Cuándo un mapper manual es preferible a uno generado?
10. 🟡 ¿Qué no puede decidir un mapper generado?
11. 🟡 ¿Cómo conviven dos versiones HTTP con un caso de uso?
12. 🟡 ¿Qué diferencias puede ocultar una capa anticorrupción?
13. 🟡 ¿Por qué TypeScript `interface` no protege una respuesta en runtime?
14. 🟡 ¿Qué pruebas necesita un error público?
15. 🟡 ¿Por qué `InsufficientInventory` no lleva status HTTP?
16. 🟡 ¿Qué riesgo tienen relaciones lazy al serializar ORM?
17. 🟠 Aparece un campo interno nuevo en `OrderEntity`. ¿Cómo evitas exponerlo?
18. 🟠 V2 renombra `customer_id` a `customerId`. ¿Qué cambia en el núcleo?
19. 🟠 Un cliente depende de un campo que quieres eliminar. ¿Cómo evolucionas el contrato?
20. 🟠 Un mapper copia `null` y rompe una invariante. ¿Dónde validas?
21. 🟠 Un error técnico muestra una consulta SQL en `detail`. ¿Qué corriges?
22. 🟠 El equipo propone un DTO gemelo por cada clase. ¿Qué criterio aplicas?
23. 🟠 FastAPI o Spring serializa más campos de los previstos. ¿Qué prueba escribes?
24. 🟠 HTTP y mensajería presentan distinto un mismo rechazo. ¿Es necesariamente un defecto?

**Siguiente:** [Simulación de entrevista](06-simulacion-de-entrevista.md).
