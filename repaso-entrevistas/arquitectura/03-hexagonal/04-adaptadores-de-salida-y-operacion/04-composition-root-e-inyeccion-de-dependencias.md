# 04 — Composition root e inyección de dependencias

Este capítulo enseña a construir el grafo de objetos en un borde visible para que `CreateOrder` reciba capacidades propias y el framework quede en la composición.

## 1. 🎯 El problema

El caso de uso se instancia dentro del controller con `new JpaOrders(...)`, o busca un bean global cuando necesita guardar. En ambos casos, la política sabe cómo se crea infraestructura. En otro equipo se usan anotaciones de inyección en todas las clases y se declara “hexagonal”, aunque el dominio todavía importa JPA. La inyección resuelve construcción; la arquitectura exige además dirección de dependencias.

## 2. 🧭 Grafo y dirección

```text
                 composition root
        ┌──────────────┼────────────────┐
   HTTP adapter     CreateOrder      JpaOrders ─► DB
                        │                ▲
                        └─► Orders ──────┘
```

El [núcleo define puertos](../02-nucleo-aplicacion-y-dominio/04-puertos-de-salida.md) y recibe dependencias por constructor o parámetros. El composition root (lugar de ensamblaje) conoce implementaciones concretas, config, cliente y ciclo de vida. Puede ser un módulo Spring, un módulo NestJS, `main` en Go o una función de arranque Python. Es el borde que sí importa hacia ambos lados para conectarlos; esa excepción no se traslada al dominio.

## 3. 🔄 Ciclo de vida y configuración

El grafo se construye al iniciar: se valida configuración, se abre un pool compartido, se crea el adapter de persistencia, se inyecta en `CreateOrder`, y HTTP y consumer reciben el mismo puerto de entrada cuando procede. El cierre libera clientes, pools y workers en orden. Un cliente HTTP creado por request desperdicia conexiones; un objeto con estado de request usado como singleton puede filtrar identidad entre llamadas.

La configuración entra como valores tipados en adapters: URI, timeout y credenciales se validan en el arranque. El caso de uso recibe límites de negocio solo si forman parte de su política; no pide variables de entorno ni consulta un service locator. En tests, el composition root puede reemplazar `JpaOrders` por un doble para probar `CreateOrder`, y una prueba de arranque comprueba que el grafo real se resuelve. El coste es wiring y decisiones de scope; la ganancia es una dependencia visible y sustituible.

## 4. 🧩 Composición mínima en cuatro plataformas

En Java, un módulo de configuración construye el caso de uso con el puerto; `JpaOrders` queda en infraestructura:

```java
@Configuration
class OrdersWiring {
    @Bean Orders orders(SpringDataOrders data) {
        return new JpaOrders(data);
    }
    @Bean CreateOrder createOrder(Orders orders, Clock clock) {
        return new CreateOrder(orders, clock);
    }
}
```

En Node/TS, una interfaz se borra en runtime: NestJS necesita un token concreto para enlazar el puerto.

```typescript
const ORDERS = Symbol('ORDERS');
@Module({
  providers: [
    { provide: ORDERS, useClass: PrismaOrders },
    { provide: CreateOrder, useFactory: (orders: Orders) => new CreateOrder(orders),
      inject: [ORDERS] },
  ],
})
class OrdersModule {}
```

En Go, el ensamblaje puede ser una función explícita sin contenedor:

```go
func buildApplication(db *sql.DB) (*Server, error) {
    repository := OrdersSQL{DB: db}
    create := CreateOrder{Orders: repository}
    return &Server{CreateOrder: create}, nil
}
```

En Python, la función de arranque separa la creación de infraestructura de la regla:

```python
def build_application(config, connection):
    orders = SqlOrders(connection)
    create_order = CreateOrder(orders)
    return OrdersApi(create_order)
```

Son recortes del mismo flujo: cada `CreateOrder` usa `Orders`, y el adaptador de entrada lo invoca. El pool se crea antes y se cierra al detener la aplicación; no se devuelve una conexión cruda al dominio.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring resuelve beans, scopes y ciclo de vida | ubicar configuración y evitar imports del framework en núcleo | creer que `@Autowired` invierte dependencias |
| Node/TS | NestJS registra providers y tokens | elegir tokens runtime y scope | inyectar una `interface` sin token |
| Go | constructores y interfaces permiten wiring explícito | ordenar creación y cierre de recursos | esconder dependencias en variables globales |
| Python | funciones y objetos facilitan fábricas sencillas | validar config y controlar lifecycle | importar una sesión global desde el caso de uso |

La implementación idiomática y sus límites se desarrollan en [Java y Spring Boot](../05-plataformas-y-practica/02-java-y-spring-boot.md), [Node y TypeScript](../05-plataformas-y-practica/03-node-y-typescript.md), [Go](../05-plataformas-y-practica/04-go.md) y [Python](../05-plataformas-y-practica/05-python.md).

## 6. ⚖️ DI automática o explícita

Usa DI automática cuando el grafo y scopes justifican un contenedor ya presente. Usa composición explícita cuando el grafo cabe en pocas líneas; facilita revisar qué depende de qué. En ambos casos, dibuja el grafo, detecta ciclos y controla ownership de recursos. La prueba de arquitectura inspecciona imports; la prueba de arranque confirma que las implementaciones satisfacen puertos. Ninguna de las dos se sustituye por el hecho de que un objeto se haya inyectado.

## ⚠️ Errores frecuentes

- “Inyectar una dependencia hace hexagonal al código.” Puede inyectarse directamente un SDK en el dominio.
- “El núcleo puede consultar el contenedor.” Eso oculta sus entradas y acopla el caso de uso al framework.
- “Todo debe ser singleton.” Algunos objetos transportan estado de request o transacción.
- “Cada clase necesita interfaz para DI.” Solo los cambios y límites reales justifican un puerto.
- “La configuración se lee dentro del dominio.” Mezcla política con despliegue y dificulta pruebas.

## 7. ✅ Veredicto

Ensambla en un borde, entrega puertos al núcleo y haz explícitos scopes, recursos y configuración. El contenedor es una herramienta de construcción; la dirección de imports y los contratos son la regla que se defiende.

## 📚 Referencias

- [Spring Framework: inyección de dependencias](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)
- [NestJS: custom providers y tokens](https://docs.nestjs.com/fundamentals/custom-providers)
- [Go: gestión de conexiones](https://go.dev/doc/database/manage-connections)
- [Python: contextlib y ciclo de vida](https://docs.python.org/3/library/contextlib.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un composition root?
2. 🟢 ¿Quién conoce las implementaciones concretas de los puertos?
3. 🟢 ¿Qué resuelve la inyección de dependencias?
4. 🟢 ¿Qué no garantiza la inyección por sí sola?
5. 🟢 ¿Dónde se crea `JpaOrders`?
6. 🟢 ¿Qué es el ciclo de vida de un recurso?
7. 🟡 ¿Por qué `CreateOrder` no consulta el contenedor?
8. 🟡 ¿Cuándo prefieres wiring explícito sobre DI automática?
9. 🟡 ¿Cómo pruebas que el grafo real puede arrancar?
10. 🟡 ¿Qué diferencia hay entre prueba del caso de uso y de composición?
11. 🟡 ¿Por qué un cliente HTTP reutilizable suele vivir más que un request?
12. 🟡 ¿Qué riesgo tiene un singleton con estado de actor?
13. 🟡 ¿Por qué NestJS necesita un token para una interfaz TypeScript?
14. 🟡 ¿Qué decide `main` en una aplicación Go?
15. 🟡 ¿Cómo introduces configuración sin leer ambiente en el dominio?
16. 🟡 ¿Cómo cierras recursos creados por el composition root?
17. 🟠 El controller construye `JpaOrders` en cada petición. ¿Qué cambias?
18. 🟠 El dominio importa `ApplicationContext`. ¿Qué dependencia inviertes?
19. 🟠 Un bean se inyecta, pero su tipo es un SDK de pagos. ¿Es suficiente?
20. 🟠 Un scope de request se guarda en singleton. ¿Qué fallo esperas?
21. 🟠 Un módulo NestJS intenta inyectar solo una `interface`. ¿Cómo lo corriges?
22. 🟠 Un proyecto Go usa variables globales para DB y reloj. ¿Cómo expones sus dependencias?
23. 🟠 La aplicación arranca en tests con doble, pero falla en producción. ¿Qué prueba faltó?
24. 🟠 ¿Cuándo quitarías una interfaz introducida solo para composición?

**Siguiente:** [Configuración, observabilidad y resiliencia](05-configuracion-observabilidad-y-resiliencia.md).
