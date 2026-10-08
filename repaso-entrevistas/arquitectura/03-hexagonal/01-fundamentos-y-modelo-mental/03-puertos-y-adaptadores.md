# 03 — Puertos y adaptadores

Un port no es una interfaz decorativa y un adapter no es un wrapper genérico. Son fronteras con una conversación útil: el núcleo ofrece una capacidad o declara una necesidad, y el borde traduce el mundo exterior.

## 1. 🎯 El problema

`CreateOrder` puede ser llamado por HTTP, una cola o un test. Si el caso de uso recibe `HttpServletRequest`, conoce la forma de un mensaje Kafka o devuelve `ResponseEntity`, cada entrada impone su vocabulario al núcleo.

```text
HTTP ─► adapter ─► puerto de entrada ─► CreateOrder
cola ─► adapter ─► puerto de entrada ─► CreateOrder
test ─► adapter ─► puerto de entrada ─► CreateOrder
```

Para guardar, el caso de uso necesita capacidad de negocio, no “un cliente de PostgreSQL”.

## 2. 🧱 Dos direcciones

Un **puerto de entrada** expresa lo que la aplicación permite hacer: `CreateOrder`, `CancelOrder`. El adapter de entrada traduce una petición a ese contrato.

Un **puerto de salida** expresa lo que el núcleo necesita: `Orders`, `PaymentGateway`, `Clock`. El adapter de salida traduce ese contrato a JPA, REST o un SDK.

```text
OrderController ─► CreateOrderPort ─► CreateOrder ─► Orders ─► JpaOrders
```

El nombre del puerto debe venir del lenguaje del negocio o de la necesidad del núcleo. `StripePort` hace que el proveedor dicte el diseño; `PaymentGateway` deja abierta la implementación.

## 3. 🧰 Flujo completo

El contrato de entrada debe ser estable y pequeño:

```java
record CreateOrderCommand(String customerId, List<ItemCommand> items) {}
interface CreateOrderPort {
    OrderResult execute(CreateOrderCommand command);
}
```

El caso de uso usa salidas que necesita, y el adapter traduce después:

```text
JSON ─► CreateOrderRequest ─► CreateOrderCommand
       ─► caso de uso ─► Order
       ─► OrderResponse ◄─ JSON
```

No todo objeto requiere una interfaz. Crea un port cuando haya una frontera que quieras proteger, una segunda implementación, una prueba aislada o una conversación de negocio que deba quedar explícita.

## 4. 🧰 Plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | interfaces, records y DI | contratos y mapeos | interfaces por cada clase |
| Node/TS | tipos, módulos y decorators opcionales | separar DTO, command y dominio | exportar tipos HTTP al núcleo |
| Go | interfaces implícitas y composición simple | decidir dónde vive el contrato | adapter que devuelve structs de SQL |
| Python | flexibilidad y protocolos opcionales | hacer visibles los contratos | usar diccionarios como API interna |

El código comparativo importa solo en el contrato: Java y TypeScript pueden hacer explícito el lenguaje de la conversación; Go y Python permiten menos ceremonia, pero exigen más disciplina.

## 5. ⚖️ Granularidad

Un port demasiado grande se vuelve una fachada de infraestructura. Uno demasiado pequeño produce ceremonia y acopla el caso de uso a decisiones artificiales. Empieza por una capacidad que el núcleo pueda explicar en una frase y separa cuando cambie la razón de cambio.

## ⚠️ Errores frecuentes

- “Cada clase necesita interfaz.” La interfaz debe proteger una frontera, no satisfacer una cuota.
- “El adapter es un wrapper genérico.” Debe traducir semántica, errores y datos.
- “El puerto debe llamarse como la tecnología.” El proveedor es una decisión del borde.
- “Entrada y salida son lo mismo.” Se distinguen por quién inicia la conversación.

## 6. ✅ Veredicto

Crea un puerto cuando nombre una capacidad y proteja una razón de cambio. El adaptador traduce el exterior a ese contrato; si solo renombra llamadas, simplifica.

## 📚 Referencias

- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un puerto de entrada?
2. 🟢 ¿Qué es un puerto de salida?
3. 🟢 ¿Qué responsabilidad tiene un adapter?
4. 🟢 ¿Quién define el contrato de salida?
5. 🟢 ¿Por qué `StripePort` es un nombre sospechoso?
6. 🟢 ¿Qué diferencia hay entre request y command?
7. 🟢 ¿Qué significa que una conversación sea de negocio?
8. 🟡 ¿Cuándo crearías una interfaz?
9. 🟡 ¿Cómo elegirías la granularidad de un port?
10. 🟡 ¿Qué datos no deberían cruzar desde HTTP al núcleo?
11. 🟡 ¿Por qué un adapter también traduce errores?
12. 🟡 ¿Qué hace que un adapter sea más que un wrapper?
13. 🟡 ¿Cómo probarías un puerto de entrada?
14. 🟡 ¿Cómo probarías un adapter de salida?
15. 🟡 ¿Qué diferencia hay entre un port y un DTO?
16. 🟡 ¿Cuándo un port es una abstracción falsa?
17. 🟠 Tienes una interfaz `ExternalClient` con veinte métodos. ¿Qué revisarías?
18. 🟠 HTTP y un consumidor de eventos comparten cinco campos, pero cambian sus errores. ¿Qué compartes?
19. 🟠 Un proveedor ofrece una operación que el negocio no necesita. ¿Dónde la ocultas?
20. 🟠 El port de salida devuelve una entidad ORM. ¿Qué frontera se rompió?
21. 🟠 Un test llama directamente al caso de uso. ¿Es un adapter?
22. 🟠 ¿Cómo diseñarías un port para una segunda implementación futura sin especular?
23. 🟠 ¿Qué harías si dos adapters necesitan reglas de traducción distintas?
24. 🟠 ¿Cómo defenderías pocos ports en un sistema grande?

**Siguiente:** [Hexagonal, Clean, Onion y capas](04-hexagonal-clean-onion-y-capas.md).
