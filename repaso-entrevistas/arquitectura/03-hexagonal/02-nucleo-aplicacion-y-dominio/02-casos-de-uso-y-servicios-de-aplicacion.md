# 02 — Casos de uso y servicios de aplicación

Un caso de uso coordina una intención completa de la aplicación. No es un controller sin HTTP ni un contenedor donde se tira toda la lógica.

## 1. 🎯 El problema

“Crear pedido” puede exigir validar entrada, cargar cliente, pedir una reserva, invocar una entidad, guardar y devolver un resultado. Si el controller hace todo, el transporte controla la aplicación. Si el servicio de aplicación decide todas las invariantes, el dominio se vuelve un DTO.

## 2. 🧱 Tres responsabilidades

El caso de uso recibe una intención, coordina ports y traduce el resultado. El dominio decide reglas locales. El adapter traduce protocolo.

```text
HTTP adapter ─► CreateOrder(command)
                    │
                    ├─ cargar cliente
                    ├─ order.confirm()
                    ├─ guardar pedido
                    └─ devolver result
```

Un comando expresa datos de entrada; una consulta lee sin cambiar estado. La autorización contextual —por ejemplo, “este actor puede cancelar este pedido”— puede coordinarse en aplicación, mientras la entidad protege la invariante que siempre debe cumplirse.

## 3. 🧰 Implementación mínima

El caso de uso no recibe un request ni un repository del framework:

```java
final class CreateOrder {
    private final Orders orders;

    OrderResult execute(CreateOrderCommand command) {
        var order = Order.create(command.customerId(), command.items());
        order.confirm();
        orders.save(order);
        return OrderResult.from(order);
    }
}
```

En Go, la coordinación puede ser una estructura pequeña; en Python, una clase o función. El criterio es el límite, no la cantidad de ceremonias.

## 4. 🧭 Tamaño y transacción

Un caso de uso debe representar una acción reconocible, no una operación de base de datos genérica. Si coordina cinco dominios, quizá se trate de un proceso de aplicación legítimo o de un god use case; mira sus razones de cambio.

La frontera transaccional suele rodear la coordinación, pero el detalle de cómo se abre y confirma
se desarrolla en [transacciones y límites de consistencia](05-transacciones-y-limites-de-consistencia.md).
El caso de uso no debe importar la anotación para expresar su política.

## 5. 🧰 Plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | clases, records y DI | separar coordinación e invariantes | `@Service` con toda la lógica |
| Node/TS | async/await y tipos | errores, validación runtime y composición | usar controller como caso de uso |
| Go | funciones y structs simples | ciclo de vida y contexto explícito | función que accede directo a SQL |
| Python | funciones, clases y typing | disciplina de dependencias | mezclar FastAPI y dominio |

## 6. ⚖️ Decisión y coste

Un caso de uso debe poder invocarse desde más de un adapter y contar una acción de negocio en una frase. Si solo renombra una consulta SQL, quizá sea una abstracción demasiado pequeña; si coordina todo el sistema, probablemente sea demasiado grande.

## ⚠️ Errores frecuentes

- “El caso de uso contiene toda la lógica.” Coordina; las invariantes viven donde está el estado.
- “Un controller delgado ya es un caso de uso.” Sigue atado al transporte.
- “Cada método de repository es un caso de uso.” Persistencia no equivale a intención.
- “El caso de uso debe conocer la transacción del ORM.” La transacción es un detalle de composición.

## 7. ✅ Veredicto

Haz que cada caso de uso exprese una intención, coordine sus puertos y delimite consistencia. No lo conviertas en controller sin HTTP ni en dueño de todas las invariantes.

## 📚 Referencias

- [Application Controller, Martin Fowler](https://martinfowler.com/eaaCatalog/applicationController.html)
- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)

## 🧠 Preguntas

1. 🟢 ¿Qué es un caso de uso?
2. 🟢 ¿Qué diferencia hay entre caso de uso y controller?
3. 🟢 ¿Qué diferencia hay entre caso de uso y servicio de dominio?
4. 🟢 ¿Qué es un comando?
5. 🟢 ¿Qué es una consulta?
6. 🟢 ¿Qué significa coordinar?
7. 🟢 ¿Dónde se decide una invariante?
8. 🟡 ¿Qué debe devolver un caso de uso?
9. 🟡 ¿Cuándo una autorización pertenece a aplicación?
10. 🟡 ¿Qué tamaño debería tener un caso de uso?
11. 🟡 ¿Por qué no debe recibir un request HTTP?
12. 🟡 ¿Por qué no debe llamar directamente al ORM?
13. 🟡 ¿Qué hace que un caso de uso sea reutilizable?
14. 🟡 ¿Cómo probarías su coordinación?
15. 🟡 ¿Qué diferencia hay entre una consulta y un comando?
16. 🟡 ¿Cuándo un caso de uso es demasiado grande?
17. 🟠 El controller valida, guarda y publica. ¿Cómo lo repartirías?
18. 🟠 El caso de uso tiene veinte dependencias. ¿Qué investigas?
19. 🟠 Dos casos de uso repiten una regla. ¿Dónde la colocas?
20. 🟠 El caso de uso necesita una transacción. ¿Quién la abre?
21. 🟠 Una consulta necesita un DTO optimizado. ¿Dónde lo defines?
22. 🟠 ¿Cómo reutilizas un caso de uso desde un consumidor?
23. 🟠 El equipo llama “service” a todo. ¿Cómo introduces precisión?
24. 🟠 ¿Cuándo aceptarías una función en lugar de una clase?

**Siguiente:** [Puertos de entrada](03-puertos-de-entrada.md).
