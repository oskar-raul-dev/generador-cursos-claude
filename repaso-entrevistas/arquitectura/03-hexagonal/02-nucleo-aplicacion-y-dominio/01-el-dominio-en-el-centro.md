# 01 — El dominio en el centro

El dominio no es la carpeta `model`. Es el conjunto de decisiones que hacen que un pedido sea válido, un pago pueda autorizarse y una reserva no se confirme dos veces.

## 1. 🎯 El problema

Si un controller decide que un pedido vacío es inválido, un job aplica otra regla y un ORM permite cambiar el estado sin restricciones, la política queda repartida. El sistema funciona mientras todos recuerdan dónde está cada regla.

```text
HTTP ─► controller ─► servicio ─► entidad anémica ─► ORM
cola ─► handler    ─► otra regla ─► misma entidad
```

El dominio debe ser el lugar donde una decisión de negocio pueda leerse, probarse y protegerse sin conocer el transporte.

## 2. 🧱 Modelo rico, sin ceremonia

Una entidad tiene identidad y protege transiciones. Un *value object* representa un concepto definido por sus valores —por ejemplo `Money` o `Email`— y puede ser inmutable. Un servicio de dominio expresa una regla que no pertenece naturalmente a una sola entidad.

```java
final class Order {
    private Status status = Status.DRAFT;

    void confirm() {
        if (items.isEmpty()) throw new EmptyOrder();
        if (status != Status.DRAFT) throw new InvalidState();
        status = Status.CONFIRMED;
    }
}
```

El método no sabe si la petición vino por HTTP ni cómo se guardará. Recibe datos suficientes para decidir, pero no un `HttpServletRequest`, una entidad JPA o un contexto de framework.

## 3. 🧭 Qué entra y qué queda fuera

Entra información necesaria para la regla: identidad de negocio, cantidades, moneda, actor o una capacidad expresada por un port. Quedan fuera status codes, JSON, SQL, headers, retries y detalles del proveedor.

La aplicación puede coordinar: cargar pedido, invocar `confirm`, guardar y publicar un resultado. El dominio decide si la transición es válida.

## 4. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | encapsulación, records y tipos fuertes | invariantes y ciclo de vida | entidad pública con setters |
| Node/TS | tipos, módulos y `readonly` | validar en runtime y controlar mutación | creer que TypeScript valida JSON |
| Go | structs simples y métodos | invariantes por constructores y errores | exportar campos mutables |
| Python | objetos flexibles y `dataclass` | disciplina de invariantes y tipos | usar diccionarios como dominio |

Java y TypeScript pueden expresar bien un value object, pero ningún lenguaje impide que alguien exponga una mutación indebida. La frontera debe estar en la API del objeto.

## 5. ⚖️ Decisión

Empieza con invariantes que ya existan. No introduzcas agregados, eventos internos ni objetos inmutables por prestigio. Si una regla importa, ponla junto al estado que protege. Si solo estás transportando datos, no inventes comportamiento para que el modelo parezca “rico”.

## ⚠️ Errores frecuentes

- “Dominio es la carpeta `model`.” Es política, no ubicación.
- “Toda validación vive en el dominio.” Forma y autorización pueden pertenecer a otros bordes.
- “Un modelo rico significa DDD ceremonial.” Puede ser una entidad con una transición bien protegida.
- “El dominio no recibe ningún servicio.” Puede recibir una capacidad propia, nunca un detalle accidental.

## 6. ✅ Veredicto

Lleva al dominio las invariantes que deben sobrevivir a cualquier entrada y deja coordinación y detalles fuera. Un modelo simple sigue siendo válido cuando no dispersa reglas valiosas.

## 📚 Referencias

- [Domain Model, Martin Fowler](https://martinfowler.com/eaaCatalog/domainModel.html)
- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)

## 🧠 Preguntas

1. 🟢 ¿Qué significa poner el dominio en el centro?
2. 🟢 ¿Qué diferencia hay entre entidad y value object?
3. 🟢 ¿Qué es una invariante?
4. 🟢 ¿Qué responsabilidad tiene un servicio de dominio?
5. 🟢 ¿Qué no debería conocer el dominio?
6. 🟢 ¿Qué diferencia hay entre dominio y carpeta `model`?
7. 🟢 ¿Por qué una entidad no debería exponer todos sus setters?
8. 🟡 ¿Qué validación pertenece al dominio?
9. 🟡 ¿Qué información puede recibir una regla de negocio?
10. 🟡 ¿Cuándo usarías un value object?
11. 🟡 ¿Cuándo una regla pertenece a un servicio de dominio?
12. 🟡 ¿Por qué un DTO HTTP no debe ser el modelo de dominio?
13. 🟡 ¿Qué coste tiene encapsular invariantes?
14. 🟡 ¿Cómo probarías una entidad sin framework?
15. 🟡 ¿Qué cambia entre una entidad mutable y una inmutable?
16. 🟡 ¿TypeScript garantiza las invariantes de un JSON recibido?
17. 🟠 Un ORM exige setters públicos. ¿Cómo proteges el dominio?
18. 🟠 La regla necesita consultar una tasa externa. ¿Dónde colocas la coordinación?
19. 🟠 Dos entidades comparten una regla. ¿Creas un servicio de dominio?
20. 🟠 Un equipo quiere convertir cada string en value object. ¿Qué preguntas harías?
21. 🟠 El dominio recibe un `UserContext` del framework. ¿Qué cambiarías?
22. 🟠 ¿Cómo detectas un modelo anémico sin imponer DDD?
23. 🟠 ¿Qué parte del dominio merece más protección en un sistema de pagos?
24. 🟠 ¿Cuándo aceptarías un modelo de datos simple?

**Siguiente:** [Casos de uso y servicios de aplicación](02-casos-de-uso-y-servicios-de-aplicacion.md).
