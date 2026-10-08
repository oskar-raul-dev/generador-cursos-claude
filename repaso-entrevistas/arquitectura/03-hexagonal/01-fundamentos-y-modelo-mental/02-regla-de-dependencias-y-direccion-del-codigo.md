# 02 — Regla de dependencias y dirección del código

La decisión central de este capítulo es reconocer cuándo una dependencia apunta desde la política hacia un detalle y cómo invertirla sin esconder el problema detrás de un contenedor de DI.

## 1. 🎯 El problema

Un caso de uso necesita guardar un pedido. Si importa `JpaRepository`, `EntityManager` o una clase de SDK, el núcleo ya conoce la tecnología que debía poder cambiar. Aunque el controller esté delgado, la dependencia sigue apuntando hacia afuera.

```text
                dependencia incorrecta
Dominio ─────────────────────────────► JPA / HTTP / SDK

                dependencia deseada
Detalle ─► puerto definido por el núcleo
```

No basta con mover la clase a otra carpeta. El compilador debe impedir que el núcleo nombre tipos del detalle.

## 2. 🧱 La regla

Las dependencias de código apuntan hacia la política. El núcleo puede declarar `Orders` porque expresa una necesidad del caso de uso. El adapter de persistencia implementa ese contrato y depende del núcleo.

```text
interface Orders {
    void save(Order order);
}

final class CreateOrder {
    private final Orders orders;
}

final class JpaOrders implements Orders {
    // aquí viven JPA, SQL y el mapeo
}
```

La inversión no es que el framework “inyecte” un objeto. Es que la política define el contrato y el detalle se adapta a él. El [adaptador de persistencia](../04-adaptadores-de-salida-y-operacion/01-persistencia-repositorios-y-mapeo.md) y el [composition root](../04-adaptadores-de-salida-y-operacion/04-composition-root-e-inyeccion-de-dependencias.md) concretan ambos lados.

## 3. 🧭 Tres dependencias distintas

- **Compilación:** un `import` del dominio hacia un paquete de infraestructura.
- **Runtime:** el grafo construido en el arranque debe conectar adapters con puertos sin que el núcleo construya detalles.
- **Datos:** una entidad o formato externo no debe convertirse accidentalmente en el modelo de política.

Una anotación también es una dependencia. Si una entidad de dominio necesita una anotación de ORM, el dominio puede quedar acoplado aunque no llame al ORM directamente.

## 4. 🧰 Composición mínima

El código Java muestra el punto importante: el caso de uso recibe el puerto y el `main` o módulo de aplicación construye el detalle.

```java
var orders = new JpaOrders(dataSource);
var createOrder = new CreateOrder(orders, clock);
var controller = new OrderController(createOrder);
```

En Go, el contrato suele ser pequeño y puede vivir junto al consumidor:

```go
type Orders interface {
    Save(ctx context.Context, order Order) error
}

func NewCreateOrder(orders Orders, clock Clock) *CreateOrder {
    return &CreateOrder{orders: orders, clock: clock}
}
```

El detalle de composición cambia; la regla no.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | DI madura y verificación por módulos | delimitar paquetes y contratos | confundir anotación con inversión |
| Node/TS | módulos, tipos y DI opcional | evitar importar ORM desde casos de uso | llamar “hexagonal” a un módulo Nest |
| Go | interfaces pequeñas y wiring explícito | ciclo de vida y composición | poner interfaces en un paquete común sin consumidor |
| Python | imports simples y contenedores opcionales | disciplina de dependencias y tests | asumir que un import dinámico eliminó el acoplamiento |

La plataforma puede reducir el trabajo mecánico. No puede decidir dónde está la política.

## 6. ⚖️ Decisión

Primero identifica quién debe permanecer estable. Declara sus contratos cerca del consumidor y deja que el borde implemente esos contratos. Si el contrato solo repite el API del proveedor, la inversión es aparente: el proveedor sigue mandando.

## ⚠️ Errores frecuentes

- “Si hay DI, ya invertí la dependencia.” DI puede conectar dos módulos mal orientados.
- “El dominio no importa nada.” La meta es no depender de detalles volátiles, no vivir sin tipos útiles.
- “Un paquete `common` resuelve la arquitectura.” Puede esconder el acoplamiento.
- “La anotación de ORM es solo metadata.” También es una dependencia de compilación y modelo.

## 7. ✅ Veredicto

Revisa imports, tipos, datos y composición: el núcleo define la conversación y el detalle se adapta. Un contenedor puede conectar el grafo, pero no corrige un contrato que apunta hacia afuera.

## 📚 Referencias

- [The Clean Architecture — Dependency Rule](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Dependency Inversion Principle, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2016/01/04/ALittleArchitecture.html)

## 🧠 Preguntas

1. 🟢 ¿Cuál es la regla de dependencias?
2. 🟢 ¿Qué diferencia hay entre una dependencia de compilación y una de runtime?
3. 🟢 ¿Por qué un `import` de JPA en el dominio es una señal?
4. 🟢 ¿Dónde debería vivir un puerto de salida?
5. 🟢 ¿Quién implementa un puerto de salida?
6. 🟢 ¿Qué es el composition root?
7. 🟢 ¿Por qué mover una clase de carpeta no basta?
8. 🟡 ¿DI y dependency inversion son lo mismo?
9. 🟡 ¿Qué dependencia de datos puede filtrarse aunque no haya imports?
10. 🟡 ¿Cómo detectarías un contrato que repite a un proveedor?
11. 🟡 ¿Por qué una anotación es una dependencia?
12. 🟡 ¿Qué diferencia hay entre conocer una abstracción y conocer un detalle?
13. 🟡 ¿Cuándo un módulo compartido aumenta el acoplamiento?
14. 🟡 ¿Qué debe impedir una regla arquitectónica automatizada?
15. 🟡 ¿Qué cambia entre interfaces de Java y Go para esta decisión?
16. 🟡 ¿Cómo revisarías un PR que añade un SDK al caso de uso?
17. 🟠 El equipo dice que el contenedor “oculta” la dependencia. ¿Qué evidencia pides?
18. 🟠 El ORM exige constructores y anotaciones. ¿Qué alternativas compararías?
19. 🟠 El puerto devuelve el DTO del proveedor. ¿Está realmente invertido?
20. 🟠 Dos casos de uso comparten un contrato enorme. ¿Qué sospechas?
21. 🟠 El equipo quiere verificar dependencias por convención de nombres. ¿Qué propones?
22. 🟠 Una dependencia es estable y ampliamente usada. ¿Aun así la aislarías?
23. 🟠 ¿Cómo separarías la dependencia de datos de la dependencia de código?
24. 🟠 ¿Cómo explicarías la dirección de dependencias en una pizarra?

**Siguiente:** [Puertos y adaptadores](03-puertos-y-adaptadores.md).
