# 06 — Testing por anillos y contratos

Este capítulo enseña a elegir pruebas según el fallo que deben detectar: una regla de `Order`, la coordinación de `CreateOrder` o la traducción de un adaptador. Probar cada clase con un mock no demuestra que las fronteras funcionen.

## 1. 🎯 El problema

Cien pruebas unitarias pasan con `Orders` simulado, pero el adaptador JPA pierde la versión del agregado y el controller expone un campo interno. El equipo afirma que la arquitectura está probada porque todos los mocks recibieron llamadas. En realidad se verificó la coreografía esperada de los tests, no el contrato de la base ni la API.

## 2. 🧭 Qué detecta cada anillo

```text
Order puro             ─► invariantes y transiciones
CreateOrder + dobles    ─► coordinación, errores e idempotencia
adapter + recurso real  ─► SQL, JSON, broker, HTTP y mapeo
composition root        ─► grafo y configuración de arranque
reglas de arquitectura  ─► imports prohibidos y dirección
```

La prueba de dominio no necesita framework. La del caso de uso usa un doble de `Orders` con comportamiento mínimo y comprueba el resultado y el estado, no solo `verify(save)`. La del [adaptador de persistencia](01-persistencia-repositorios-y-mapeo.md) necesita una base compatible para detectar constraints, transacciones y N+1. La del [adaptador remoto](02-clientes-http-grpc-y-servicios-externos.md) necesita un servidor controlado o contrato de proveedor para comprobar timeout, payload y errores. Un test de [outbox](03-publicacion-de-eventos-y-outbox.md) debe provocar caída y duplicado.

## 3. 🔄 Contratos y fronteras reales

Un test de contrato de puerto ejecuta las mismas expectativas sobre un doble y el adaptador real: guardar y leer preserva ID, estado y versión; buscar ausente tiene resultado definido. No obliga a que ambos usen la misma implementación interna. El contrato externo de HTTP o eventos verifica esquema, campos, versión y compatibilidad con consumidores. Los tests arquitectónicos revisan imports del núcleo y dependencias de módulos; detectan dirección, pero no prueban que una transacción confirma pedido y outbox juntos.

Testcontainers puede levantar PostgreSQL o broker real en CI cuando la fidelidad importa. Su coste es tiempo, recursos y mantenimiento de fixtures; por eso se usa en fronteras donde un doble sería una mentira, no para cada función pura. Una base en memoria distinta puede ocultar SQL, locks o constraints. La prueba más útil para persistencia crea un pedido, cierra sesión, lo recarga y ejecuta una invariante, además de medir queries de una lista.

## 4. 🧩 Implementación mínima

Una prueba pura del dominio muestra la regla sin mocks:

```java
@Test
void doesNotConfirmOrderWithoutLines() {
    var order = Order.create("order-1", "customer-1");
    assertThrows(EmptyOrder.class, order::confirm);
    assertEquals(Status.DRAFT, order.status());
}
```

La prueba del caso de uso sustituye solo el puerto necesario y mira un efecto observable:

```java
@Test
void createOrderSavesConfirmedState() {
    var orders = new InMemoryOrders();
    var useCase = new CreateOrder(orders, new FixedClock());
    var result = useCase.execute(new CreateOrderCommand("customer-1", 2));
    assertEquals(Status.CONFIRMED,
        orders.find(result.orderId()).orElseThrow().status());
}
```

El composition root de tests construye `JpaOrders` con una base de la misma familia que producción y ejecuta el contrato de `Orders`; otro test arranca el grafo real. Los nombres de clases son del sistema de ejemplo, no un framework de pruebas adicional. La aserción importante es el estado reconstruido, no cuántas veces se llamó `save`.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | JUnit ejecuta tests; Testcontainers provee recursos; ArchUnit verifica reglas | seleccionar contratos y fixtures | mockear JPA y creer que SQL funciona |
| Node/TS | `node:test` ejecuta pruebas; servidor de prueba valida HTTP | compilar TS, aislar datos y controlar reloj | probar solo llamadas a mocks |
| Go | `go test` integra pruebas y fuzzing | elegir interfaces pequeñas y DB real donde importa | usar un fake que no respeta errores SQL |
| Python | pytest facilita fixtures y asserts | gestionar sesión, transacción y recursos | fixture compartida que oculta contaminación |

## 6. ⚖️ Matriz de decisión

| Riesgo a detectar | Prueba más directa | Coste principal |
|---|---|---|
| Invariante de pedido | dominio puro | diseñar estados claros |
| Orden de coordinación | caso de uso con dobles | mantener dobles fieles al puerto |
| Mapeo, SQL y constraints | adapter con DB real | arranque y datos de prueba |
| Status, JSON y errores | adaptador HTTP integrado | servidor y contrato público |
| Import prohibido | regla arquitectónica | mantener límites de módulos |

No conviertas esta matriz en una pirámide rígida de porcentajes. Invierte en la prueba que falla cuando falla la frontera. Si cambia una regla, la prueba pura debe fallar; si cambia el esquema, una prueba de adapter debe fallar; si alguien importa JPA en dominio, falla la regla de arquitectura.

## ⚠️ Errores frecuentes

- “Si mockeo todo, ya probé hexagonal.” Los mocks no ejecutan SQL, serialización ni broker.
- “Una prueba unitaria prueba arquitectura.” Puede confirmar una regla sin revisar imports.
- “Todo debe ser end to end.” Los tests lentos dificultan diagnosticar una invariante pequeña.
- “Verificar una llamada equivale a verificar un resultado.” Puede guardar el estado equivocado.
- “Testcontainers reemplaza contratos.” Provee infraestructura; las expectativas las define el equipo.

## 7. ✅ Veredicto

Prueba reglas con la menor infraestructura, y adaptadores con la suficiente para revelar sus fallos reales. Usa contratos para que dobles y implementaciones compartan semántica, y reglas de imports para proteger la dirección. El precio es mantener varias clases de prueba; la ganancia es saber cuál frontera se rompió.

## 📚 Referencias

- [JUnit 5: User Guide](https://docs.junit.org/5.14.2/_exports/junit-user-guide-5.14.2.html)
- [Testcontainers: PostgreSQL en pruebas de integración](https://testcontainers.com/guides/getting-started-with-testcontainers-for-java/)
- [ArchUnit: User Guide](https://www.archunit.org/userguide/html/000_Index.html)
- [Node.js: test runner](https://nodejs.org/api/test.html)
- [Go: add a test](https://go.dev/doc/tutorial/add-a-test)
- [pytest: get started](https://docs.pytest.org/en/stable/getting-started.html)

## 🧠 Preguntas

1. 🟢 ¿Qué prueba una prueba pura de dominio?
2. 🟢 ¿Qué prueba una prueba de caso de uso con dobles?
3. 🟢 ¿Qué prueba una integración del adaptador JPA?
4. 🟢 ¿Qué es un test de contrato de puerto?
5. 🟢 ¿Qué detecta una regla arquitectónica de imports?
6. 🟢 ¿Para qué sirve Testcontainers aquí?
7. 🟡 ¿Qué significa observar el estado y no solo una llamada?
8. 🟡 ¿Cuándo usarías una base real en vez de un fake?
9. 🟡 ¿Qué riesgo tiene una base en memoria distinta a producción?
10. 🟡 ¿Cómo compruebas que un mapper reconstruye invariantes?
11. 🟡 ¿Qué test detectaría N+1?
12. 🟡 ¿Cómo pruebas un cliente de pagos sin cobrar de verdad?
13. 🟡 ¿Qué cubre un contrato de evento externo?
14. 🟡 ¿Qué aporta ArchUnit y qué no cubre?
15. 🟡 ¿Qué ofrece `go test` sin librería extra?
16. 🟡 ¿Cómo evitas fixtures Python que contaminan pruebas?
17. 🟠 Todos los mocks pasan y JPA pierde `version`. ¿Qué prueba agregas?
18. 🟠 El controller filtra un campo sensible. ¿Qué prueba faltó?
19. 🟠 La outbox publica dos veces tras una caída. ¿Qué verificas?
20. 🟠 El caso de uso guarda antes de validar una invariante. ¿Qué aserción haces?
21. 🟠 Un test end to end tarda minutos y falla por una regla simple. ¿Cómo lo redistribuyes?
22. 🟠 Un fake de `Orders` permite duplicados que la base rechaza. ¿Cómo corriges el contrato?
23. 🟠 Un build pasa aunque dominio importe JPA. ¿Qué control añades?
24. 🟠 ¿Cuándo evitarías levantar Testcontainers para una prueba?

**Siguiente:** [Evolución y migración desde un monolito](07-evolucion-y-migracion-desde-un-monolito.md).
