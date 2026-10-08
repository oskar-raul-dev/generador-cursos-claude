# 02 — Java y Spring Boot

Este capítulo enseña a usar Spring Boot para ensamblar, transaccionar y operar un servicio sin permitir que Spring, JPA o HTTP posean el núcleo.

## 1. 🎯 El problema

`Order` lleva `@Entity`, `CreateOrder` es un `@Service` que recibe `JpaRepository` y el controller devuelve la entidad. Las pruebas cargan todo el contexto para verificar una invariante. El servicio funciona, pero cada decisión de negocio depende de proxies, sesión y serialización del framework.

## 2. 🧭 Paquetes por capacidad y dirección

Una estructura útil agrupa la capacidad y separa contratos, no tecnologías globales:

```text
orders/
├── domain/              Order, Money, reglas
├── application/         CreateOrder, AuthorizePayment, Orders, PaymentGateway
└── infrastructure/
    ├── inbound/http/    OrderController, DTO
    ├── outbound/jpa/    OrderRecord, JpaOrders
    └── config/          OrdersConfiguration
```

El módulo o regla de ArchUnit debe impedir que `domain` y `application` importen Spring Data, Servlet o clases del proveedor. Los nombres de paquete ayudan a navegar; la dirección la garantizan imports y contratos.

## 3. 🔄 Composición y transacción

Constructor injection hace visibles las dependencias. Una configuración en infraestructura crea el grafo:

```java
@Configuration
class OrdersConfiguration {
    @Bean
    Orders orders(SpringDataOrders data) {
        return new JpaOrders(data);
    }

    @Bean
    CreateOrder createOrder(Orders orders) {
        return new CreateOrder(orders);
    }

    @Bean
    AuthorizePayment authorizePayment(Orders orders, PaymentGateway paymentGateway) {
        return new AuthorizePayment(orders, paymentGateway);
    }
}
```

El caso de uso puede ser una clase Java sin anotaciones. Si Spring delimita la transacción con `@Transactional`, ubica la anotación en un facade de aplicación o configuración consciente del proxy. Una llamada interna a otro método del mismo objeto puede no atravesar el proxy; además, la transacción local no incluye un cobro remoto ni garantiza publicar en el broker. Para eso se modelan estados inciertos y outbox.

## 4. 🧩 JPA y pruebas por frontera

`SpringDataOrders` es detalle del adaptador. `JpaOrders` traduce `OrderRecord` a `Order`, controla estrategias de carga y convierte excepciones técnicas. Devolver la entidad JPA reintroduce lazy loading, columnas accidentales y ciclo de vida de sesión. Un modelo separado cuesta mapper; úsalo donde protege invariantes o evolución, no como ritual.

Prueba `Order` con JUnit sin Spring, `CreateOrder` con dobles pequeños, `JpaOrders` con PostgreSQL/Testcontainers y el controller con el slice HTTP apropiado. Una prueba de contexto verifica que beans, scopes y configuración arrancan. Cargar `@SpringBootTest` para cada regla hace más lenta la señal y no mejora su precisión.

## 5. 🧰 Contraste de plataforma

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | beans, proxies, JPA, validación y test slices | límites de módulos, mappers y semántica transaccional | poner anotaciones de framework en todo el núcleo |
| Node/TS | módulos y tokens de provider | validación runtime y contexto async | asumir que una interfaz existe en ejecución |
| Go | constructores e interfaces implícitas | wiring y transacción explícitos | crear una interfaz por clase Java traducida |
| Python | factories, protocolos y dependencias de FastAPI | disciplina de scopes e imports | usar modelos ORM como contrato público |

## 6. ⚖️ Decisión y coste

Spring compensa cuando el servicio ya necesita su ecosistema de datos, web, configuración y operación. El coste aparece en proxies, auto-configuración, tiempo de arranque y conocimiento de scopes. Aísla esas ventajas en adaptadores y composición. Para un caso de uso pequeño, una clase Java y dos `@Bean` suelen ser más claras que una jerarquía de estereotipos.

## ⚠️ Errores frecuentes

- “`@Service` convierte una clase en caso de uso.” El contenido y sus dependencias lo hacen.
- “`@Transactional` incluye cualquier efecto.” Solo los recursos coordinados por ese transaction manager.
- “Spring Data repository es el puerto del dominio.” Su API y tipos pertenecen al adaptador.
- “Constructor injection elimina el acoplamiento.” Puedes inyectar directamente un detalle indebido.
- “Todo test necesita contexto Spring.” Las reglas puras no lo necesitan.

## 7. ✅ Veredicto

Usa Spring en el borde: configura beans, transacciones, HTTP, JPA y observabilidad. Mantén `Order` y los contratos de aplicación ejecutables como Java ordinario; prueba cada frontera con la infraestructura mínima que puede revelar su fallo.

## 📚 Referencias

- [Spring Framework: dependency injection](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)
- [Spring Framework: transacciones declarativas](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/tx-decl-explained.html)
- [Spring Data JPA: repository interfaces](https://docs.spring.io/spring-data/jpa/reference/repositories/definition.html)
- [Spring Boot 4.1: requisitos](https://docs.spring.io/spring-boot/system-requirements.html)
- [ArchUnit: User Guide](https://www.archunit.org/userguide/html/000_Index.html)
- [Testcontainers para Java](https://testcontainers.com/guides/getting-started-with-testcontainers-for-java/)

## 🧠 Preguntas

1. 🟢 ¿Dónde debe vivir `JpaOrders`?
2. 🟢 ¿Qué construye `OrdersConfiguration`?
3. 🟢 ¿Por qué `Order` puede ser Java ordinario?
4. 🟢 ¿Qué hace constructor injection?
5. 🟢 ¿Qué papel cumple `SpringDataOrders`?
6. 🟢 ¿Qué prueba una regla de ArchUnit?
7. 🟡 ¿Dónde ubicarías `@Transactional` para `CreateOrder`?
8. 🟡 ¿Por qué una llamada interna puede evitar el proxy transaccional?
9. 🟡 ¿Cuándo separarías `OrderRecord` de `Order`?
10. 🟡 ¿Qué traduce el adaptador JPA además de campos?
11. 🟡 ¿Qué prueba ejecutarías sin Spring?
12. 🟡 ¿Cuándo usarías `@SpringBootTest`?
13. 🟡 ¿Qué diferencia hay entre un bean y un puerto?
14. 🟡 ¿Cómo evitas que el controller serialice una entidad JPA?
15. 🟡 ¿Qué coste introduce la auto-configuración?
16. 🟡 ¿Cómo comprobarías que el grafo real arranca?
17. 🟠 `Order` importa `jakarta.persistence.Entity`. ¿Qué frontera se filtró?
18. 🟠 `@Transactional` guarda el pedido y luego falla el cobro HTTP. ¿Qué revierte realmente?
19. 🟠 Un método transaccional se invoca desde otro método del mismo bean. ¿Qué verificas?
20. 🟠 Un equipo extiende `JpaRepository` desde aplicación. ¿Qué contrato propones?
21. 🟠 Todos los tests usan mocks de JPA y producción falla por lazy loading. ¿Qué prueba falta?
22. 🟠 El contexto tarda minutos porque cada regla usa `@SpringBootTest`. ¿Cómo redistribuyes las pruebas?
23. 🟠 Dos beans implementan `PaymentGateway` y el arranque es ambiguo. ¿Dónde resuelves la selección?
24. 🟠 ¿Cuándo aceptarías anotaciones Spring en la capa de aplicación?

**Siguiente:** [Node y TypeScript](03-node-y-typescript.md).
