# 01 — Persistencia, repositorios y mapeo

Este capítulo enseña a diseñar un adaptador de persistencia que satisfaga una necesidad de `CreateOrder` sin convertir el modelo de dominio en una proyección del ORM.

## 1. 🎯 El problema

`Order` lleva anotaciones JPA y devuelve una colección lazy de líneas. Una prueba de la regla de confirmación necesita una sesión abierta; al serializar una respuesta aparecen consultas imprevistas. Cambiar el esquema obliga a tocar invariantes que no cambiaron. El problema no es usar JPA: es dejar que su modelo y ciclo de vida sean el contrato del núcleo.

## 2. 🧭 Modelo mental y dirección

```text
CreateOrder ─► Orders (puerto del núcleo) ◄─ Adaptador JPA ─► tablas SQL
       │                                            │
     Order                                  OrderRecord / mapper
```

El núcleo define operaciones según su necesidad: `find`, `save` y quizá una lectura especializada; no extiende `JpaRepository` ni conoce `EntityManager`, sesión o relaciones lazy. El adaptador implementa ese puerto y traduce entre `Order` y un registro de persistencia. [Puertos de salida](../02-nucleo-aplicacion-y-dominio/04-puertos-de-salida.md) define quién posee el contrato; [transacciones](../02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md) define el límite del commit. El repository no inicia una transacción independiente por cada método si el caso de uso necesita atomicidad conjunta.

## 3. 🔄 Flujo, identidad y consultas

`CreateOrder` crea un agregado con identidad estable, llama `orders.save(order)` y recibe el ID o conserva el que generó previamente mediante un puerto de identidad. El adaptador asigna columnas, versionado optimista y relaciones. Al leer, carga los datos requeridos para reconstruir un agregado válido antes de devolverlo; no entrega un proxy que más tarde intente ir a la base desde el dominio.

Una consulta para listar pedidos puede usar una proyección de lectura sin hidratar agregados completos. Si el caso de uso necesita la política del agregado, sí reconstruye el estado necesario. Ni `SELECT *` para todo ni un mapper por cada propiedad son reglas universales: se elige según invariantes, volumen y evolución. `N+1` se detecta contando consultas reales sobre una lista; se corrige con una estrategia de carga o query explícita, no ocultándolo bajo una sesión abierta en el controller.

## 4. 🧩 Implementación mínima

El recorte muestra el puerto, un registro JPA separado y el punto de ensamblaje. `Order.reconstitute` valida que los datos cargados formen un agregado utilizable.

```java
// Núcleo
interface Orders {
    Optional<Order> find(String id);
    void save(Order order);
}

// Infraestructura
@Entity
class OrderRecord {
    @Id String id;
    String customerId;
    String status;
    @Version long version;
}

final class JpaOrders implements Orders {
    private final SpringDataOrders data;
    JpaOrders(SpringDataOrders data) { this.data = data; }
    public Optional<Order> find(String id) {
        return data.findById(id).map(r ->
            Order.reconstitute(r.id, r.customerId, r.status, r.version));
    }
    public void save(Order order) {
        data.save(OrderMapper.toRecord(order));
    }
}

// Composition root: @Bean Orders orders(SpringDataOrders data)
//                    { return new JpaOrders(data); }
```

El ejemplo omite líneas y concurrencia real para enfocar la frontera: el mapper de producción conserva todas las invariantes y la versión del agregado. En Go, la interfaz puede vivir junto al caso de uso y el adapter usar `database/sql` o código generado por sqlc:

```go
type Orders interface {
    Find(ctx context.Context, id string) (Order, error)
    Save(ctx context.Context, order Order) error
}
type OrdersSQL struct { DB *sql.DB }
func (a OrdersSQL) Find(ctx context.Context, id string) (Order, error) {
    var customer, status string
    err := a.DB.QueryRowContext(ctx,
        "SELECT customer_id, status FROM orders WHERE id = ?", id).Scan(&customer, &status)
    if err != nil { return Order{}, translateError(err) }
    return ReconstituteOrder(id, customer, status), nil
}
// El composition root entrega OrdersSQL al caso de uso; la escritura usa la misma unidad de trabajo.
```

La sintaxis del marcador SQL cambia por driver. Si una operación usa `sql.Tx`, todas sus queries deben ejecutarse con ese `Tx`; el puerto no tiene que exponerlo al dominio.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | JPA/Hibernate mapea entidades y carga relaciones | separar registro y agregado cuando compensa | devolver proxies lazy al núcleo |
| Node/TS | Prisma genera cliente tipado y permite `select`/`include` | elegir proyección y mapear errores | usar el modelo Prisma como dominio |
| Go | `database/sql` gestiona conexiones; sqlc genera código desde SQL | mapear filas y unidad de trabajo | ejecutar `db` fuera del `tx` |
| Python | SQLAlchemy gestiona sesión y estrategias de carga | aislar sesión y reconstruir invariantes | acceder a una relación lazy fuera de sesión |

La implementación idiomática y sus límites se desarrollan en [Java y Spring Boot](../05-plataformas-y-practica/02-java-y-spring-boot.md), [Node y TypeScript](../05-plataformas-y-practica/03-node-y-typescript.md), [Go](../05-plataformas-y-practica/04-go.md) y [Python](../05-plataformas-y-practica/05-python.md).

## 6. ⚖️ Decisión y coste

Separa modelos cuando hay invariantes relevantes, API pública, relaciones complejas o cambio de esquema independiente. Para un CRUD interno estable, un mapper casi idéntico puede costar más que el acoplamiento que evita; documenta la excepción y revísala si aparece una segunda entrada o una regla rica. La separación paga en código de traducción y pruebas de adapter, pero permite probar política sin base y detectar consultas reales en integración.

## ⚠️ Errores frecuentes

- “Repository es una interfaz del framework.” El puerto del núcleo expresa capacidades; la interfaz del ORM queda en el adaptador.
- “El ORM está en infraestructura, así que devolver sus entidades es inocuo.” Proxies, estados y anotaciones cruzan igual la frontera.
- “Una prueba unitaria detecta N+1.” Hace falta ejecutar la query real y medir consultas.
- “Un método repository debe abrir su propia transacción.” Puede partir la unidad de consistencia del caso de uso.
- “Siempre hace falta doble modelo.” El coste se justifica por el cambio que protege.

## 7. ✅ Veredicto

Haz que `Orders` hable el lenguaje necesario para `CreateOrder`; traduce ORM y SQL en el adaptador. Verifica reconstrucción, concurrencia y consultas sobre la base real. Simplifica el mapper cuando la frontera no compra independencia útil.

## 📚 Referencias

- [Hibernate ORM: User Guide](https://docs.hibernate.org/orm/current/userguide/html_single/)
- [Prisma: selección de campos](https://www.prisma.io/docs/orm/v7/prisma-client/queries/select-fields)
- [sqlc: generación desde SQL](https://docs.sqlc.dev/en/latest/howto/generate.html)
- [SQLAlchemy: carga de relaciones](https://docs.sqlalchemy.org/en/20/orm/relationship_api.html)
- [Go: ejecución de transacciones](https://go.dev/doc/database/execute-transactions)

## 🧠 Preguntas

1. 🟢 ¿Qué necesidad expresa el puerto `Orders`?
2. 🟢 ¿Quién implementa el puerto de persistencia?
3. 🟢 ¿Qué diferencia hay entre `Order` y `OrderRecord`?
4. 🟢 ¿Qué es una carga lazy?
5. 🟢 ¿Qué es N+1 en una lista de pedidos?
6. 🟢 ¿Dónde se decide la transacción de `CreateOrder`?
7. 🟢 ¿Por qué el dominio no recibe `EntityManager`?
8. 🟡 ¿Cuándo reconstruyes un agregado completo y cuándo usas una proyección?
9. 🟡 ¿Qué debe garantizar el mapper al reconstruir `Order`?
10. 🟡 ¿Cómo conservas identidad y versión optimista?
11. 🟡 ¿Qué coste añade separar modelo de dominio y ORM?
12. 🟡 ¿Cómo detectarías N+1 de forma confiable?
13. 🟡 ¿Qué aporta `select` de Prisma a una consulta de lectura?
14. 🟡 ¿Qué genera sqlc y qué decisión sigue siendo tuya?
15. 🟡 ¿Por qué una sesión SQLAlchemy no debe escapar del adaptador?
16. 🟡 ¿Cuándo aceptarías un mapeo mínimo en un CRUD pequeño?
17. 🟠 `save` confirma antes de reservar inventario. ¿Qué límite está mal?
18. 🟠 Una entidad JPA se devuelve por HTTP y filtra una columna nueva. ¿Qué cambias?
19. 🟠 El dominio accede a una relación lazy fuera de sesión. ¿Cómo rediseñas la lectura?
20. 🟠 Un adapter Go consulta con `db` durante una transacción `tx`. ¿Qué riesgo hay?
21. 🟠 Dos workers actualizan el mismo pedido. ¿Cómo detectas la carrera?
22. 🟠 El equipo quiere extender `JpaRepository` desde el núcleo. ¿Qué propones?
23. 🟠 Un listado tarda más al crecer de 10 a 100 pedidos. ¿Qué medirías primero?
24. 🟠 ¿Cuándo eliminarías el modelo de persistencia separado?

**Siguiente:** [Clientes HTTP, gRPC y servicios externos](02-clientes-http-grpc-y-servicios-externos.md).
