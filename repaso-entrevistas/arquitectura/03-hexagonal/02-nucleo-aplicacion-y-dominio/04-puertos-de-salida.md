# 04 — Puertos de salida

Un puerto de salida expresa una capacidad que el núcleo necesita. Su diseño empieza con la pregunta “¿qué decisión debe tomar el caso de uso?” y no con “¿qué API ofrece la base o el proveedor?”.

## 1. 🎯 El problema

El caso de uso necesita guardar un pedido, consultar el reloj y autorizar un pago. Si recibe `JpaRepository`, `StripeClient` y `Instant.now()` directamente, tres detalles controlan la política y son difíciles de sustituir en pruebas.

## 2. 🧱 Contratos mínimos

```java
interface Orders {
    Optional<Order> find(OrderId id);
    void save(Order order);
}

interface PaymentGateway {
    PaymentResult authorize(Payment payment);
}
```

El repositorio expresa lectura y escritura que el caso de uso necesita. El gateway expresa autorización, no endpoints del proveedor. Un `Clock` permite controlar el tiempo sin convertirlo en una dependencia global.

## 3. 🧭 Diseño orientado a necesidad

Un port de lectura puede devolver una proyección propia si el caso de uso solo necesita tres campos. Un port de escritura puede aceptar un agregado o un comando propio. No existe una única interfaz `Repository<T>` que sirva para todo sin perder semántica.

```text
caso de uso ─► Orders          ─► adapter SQL
            ─► PaymentGateway  ─► adapter proveedor
            ─► Clock           ─► reloj del sistema
```

Los dobles de prueba deben respetar el contrato: un fake que permite guardar un pedido inválido prueba poco.

## 4. 🧰 Go y cuatro plataformas

```go
type PaymentGateway interface {
    Authorize(ctx context.Context, payment Payment) (PaymentResult, error)
}

type CreateOrder struct {
    payments PaymentGateway
}
```

En Go la interfaz puede vivir junto al consumidor y el adapter satisface el contrato sin declararlo. En Java la interfaz explícita facilita leer el límite, pero también invita a generar ports sin necesidad.

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | interfaces, genéricos y DI | semántica del port | `JpaRepositoryPort` |
| Node/TS | tipos y módulos | contratos async y errores | exportar SDK al núcleo |
| Go | interfaces implícitas | contexto y errores | `Repository` universal |
| Python | duck typing y Protocols | contratos y dobles fieles | mock que acepta cualquier cosa |

## 5. ⚖️ Decisión y coste

Un port de salida debe poder explicarse sin mencionar la tecnología. Si el nombre, los tipos y los errores vienen del proveedor, el borde no está protegiendo al núcleo.

## ⚠️ Errores frecuentes

- “El port se llama como la tecnología.” El proveedor es un detalle.
- “Un repositorio genérico sirve para todo.” Puede borrar semántica y límites.
- “Mockear es diseñar el port.” El contrato nace de la necesidad de negocio.
- “El reloj no es una dependencia.” El tiempo afecta decisiones y pruebas.

## 6. ✅ Veredicto

Expresa capacidades mínimas desde quien las consume y traduce proveedor, protocolo y errores en el adaptador. No diseñes el puerto como catálogo de la tecnología.

## 📚 Referencias

- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es un puerto de salida?
2. 🟢 ¿Quién debe definirlo?
3. 🟢 ¿Qué diferencia hay entre port y adapter de salida?
4. 🟢 ¿Por qué aislar el reloj?
5. 🟢 ¿Qué expresa un `PaymentGateway`?
6. 🟢 ¿Qué es un repositorio desde el punto de vista del núcleo?
7. 🟢 ¿Qué no debería devolver el port?
8. 🟡 ¿Cómo diseñas un port desde la necesidad?
9. 🟡 ¿Separarías lectura y escritura?
10. 🟡 ¿Qué es una proyección propia?
11. 🟡 ¿Qué debe garantizar un fake?
12. 🟡 ¿Por qué evitar un repository genérico?
13. 🟡 ¿Dónde vive una interfaz en Go?
14. 🟡 ¿Qué errores cruza el port?
15. 🟡 ¿Cómo pruebas un caso de uso con un port de salida?
16. 🟡 ¿Cuándo compartirías un port entre casos de uso?
17. 🟠 El proveedor devuelve diez estados y el negocio usa tres. ¿Dónde traduces?
18. 🟠 Un repositorio tiene veinte métodos. ¿Qué haces?
19. 🟠 El caso de uso necesita tiempo y zona horaria. ¿Qué port diseñas?
20. 🟠 El fake se comporta distinto de PostgreSQL. ¿Qué prueba falta?
21. 🟠 El SDK usa excepciones propias. ¿Cómo las traduces?
22. 🟠 Dos proveedores requieren contratos distintos. ¿Compartes port?
23. 🟠 ¿Qué indica que el port es un espejo del ORM?
24. 🟠 ¿Cómo defenderías un port pequeño ante una futura implementación?

**Siguiente:** [Transacciones y límites de consistencia](05-transacciones-y-limites-de-consistencia.md).
