# 01 — Qué problema resuelve la arquitectura hexagonal

La arquitectura hexagonal protege el núcleo de una aplicación de cambios en sus detalles: framework, transporte, base de datos y proveedores externos. No es una receta de carpetas ni una promesa de que el dominio quedará bien diseñado por sí solo.

## 1. 🎯 El problema

Imagina `CreateOrder` dentro de un controller. El método valida, crea el pedido, llama a un ORM,
[publica un evento](../02-nucleo-aplicacion-y-dominio/07-eventos-de-dominio-y-efectos-secundarios.md)
y devuelve JSON. La primera versión parece rápida. Después llega una segunda entrada —un consumidor de
mensajes—, una base distinta para pruebas y una regla de negocio que debe ejecutarse sin HTTP. Cada
cambio toca el mismo método y la prueba necesita levantar demasiadas cosas.

```text
HTTP ─► controller ─► ORM ─► PostgreSQL
          │             └──► broker
          └── reglas de negocio mezcladas con detalles
```

El problema no es tener un controller o usar un ORM. El problema es que una decisión de negocio depende de ellos. Si cambia el detalle, cambia la política.

## 2. 🧱 El modelo mental

La arquitectura hexagonal —*Ports and Adapters*— pone la aplicación en el centro. El núcleo contiene políticas: qué significa crear un pedido, cuándo una reserva es válida y qué resultado debe producirse. Los puertos describen conversaciones con ese núcleo; los adapters (adaptadores) traducen HTTP, mensajería, SQL o un proveedor de pagos a esas conversaciones.

```text
                 REST
                   │
                 adapter
                   │
        ┌──────────▼──────────┐
        │   puerto de entrada  │
        │      aplicación      │
        │       dominio         │
        │   puerto de salida    │
        └──────────┬──────────┘
                 adapter
                   │
              base de datos
```

La regla decisiva es la dirección de la dependencia: el código que expresa política no conoce el código que expresa detalle. El adapter sí conoce el puerto; el núcleo no conoce al adapter.

## 3. 🧭 Qué protege y qué no

Protege la estabilidad del núcleo ante cambios de entrada y salida. Facilita probar `CreateOrder` con un repositorio en memoria, reutilizarlo desde HTTP o una cola y sustituir un proveedor sin reescribir la regla.

No arregla una frontera de negocio equivocada, una
[transacción distribuida](../02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md)
ni una base compartida. Tampoco obliga a extraer microservicios. Puede ser perfectamente una
arquitectura interna de un monolito.

| Decisión | La arquitectura ayuda a | La arquitectura no decide |
|---|---|---|
| Política | aislarla de detalles | si la política está bien modelada |
| Entrada | cambiar HTTP por cola o batch | qué protocolo conviene |
| Salida | sustituir persistencia o proveedor | si la base tiene buen diseño |
| Pruebas | ejecutar el núcleo aislado | qué casos de negocio faltan |

## 4. 💰 El precio

- **Complejidad cognitiva:** hay que distinguir núcleo, puertos, adapters y composición.
- **Código de traducción:** request, command, entidad y respuesta no siempre son el mismo objeto.
- **Pruebas:** aparecen dobles y pruebas de integración de cada adapter.
- **Evolución:** los cambios de infraestructura son más baratos; cambiar el contrato del núcleo puede afectar varios adapters.
- **Operación:** la separación no elimina timeouts, transacciones ni observabilidad; solo evita que se filtren al dominio.

Para un CRUD interno, estable y pequeño, esa ceremonia puede costar más que el cambio que pretende proteger. La decisión correcta puede ser un monolito modular sencillo con una frontera explícita, no un hexágono completo.

## 5. 🧰 Mecanismos de composición

Este capítulo es conceptual; no prescribe una librería. La composición puede hacerse con constructor injection, un contenedor de DI o wiring explícito. La elección cambia el cableado y el ciclo de vida, no la dirección de las dependencias.

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | constructores y contenedores como Spring | definir módulos, contratos y lifecycle | confundir beans con inversión |
| Node/TS | módulos, factories y contenedores como NestJS | validar runtime y elegir scopes | usar el contenedor como service locator |
| Go | constructores, interfaces implícitas y `main` | cablear el grafo de forma explícita | crear una interfaz por struct |
| Python | factories, parámetros y contenedores opcionales | declarar contratos y recursos | resolver dependencias con globals |

La tabla no genera preguntas específicas de plataforma: aquí solo evidencia que distintos mecanismos pueden respetar o violar la misma regla conceptual. [Composition root e inyección de dependencias](../04-adaptadores-de-salida-y-operacion/04-composition-root-e-inyeccion-de-dependencias.md) muestra el ensamblaje, y [persistencia y mapeo](../04-adaptadores-de-salida-y-operacion/01-persistencia-repositorios-y-mapeo.md) muestra la frontera de salida.

## 6. ⚖️ Decisión y coste

Usa hexagonal cuando esperas más de una entrada o salida, reglas de negocio duraderas, pruebas aisladas valiosas o sustitución real de tecnología. Simplifica cuando el sistema es pequeño y el cambio que quieres proteger no existe todavía. La forma del dibujo es secundaria; la frontera de dependencias es la arquitectura.

## ⚠️ Errores frecuentes

- “Hexagonal es solo para microservicios.” También funciona dentro de un monolito.
- “Es una estructura de carpetas.” Las carpetas ayudan; la dirección de dependencias manda.
- “El dominio no puede usar ninguna librería.” La regla protege de detalles volátiles; no exige purismo sin beneficio.
- “Más puertos siempre es mejor.” Un puerto que no expresa una conversación útil solo añade ceremonia.

## 7. ✅ Veredicto

Usa la separación cuando una regla, una entrada o una salida tenga una razón de cambio que merezca protección. Si esa evidencia no existe, conserva módulos claros y una dirección explícita sin fabricar puertos.

## 📚 Referencias

- [Hexagonal Architecture, Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture)
- [The Clean Architecture, Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🧠 Preguntas

1. 🟢 ¿Qué problema concreto intenta resolver la arquitectura hexagonal?
2. 🟢 ¿Qué diferencia hay entre política y detalle?
3. 🟢 ¿Qué es un port en este modelo?
4. 🟢 ¿Qué es un adapter?
5. 🟢 ¿Por qué el hexágono no tiene que tener literalmente seis lados?
6. 🟢 ¿Puede existir arquitectura hexagonal dentro de un monolito?
7. 🟢 ¿Qué significa que el núcleo sea independiente de HTTP?
8. 🟡 ¿Qué cambio de negocio queda protegido y cuál no?
9. 🟡 ¿Por qué un repositorio en memoria es una evidencia útil y no solo un mock?
10. 🟡 ¿Qué precio introduce separar request, command y respuesta?
11. 🟡 ¿Cuándo un CRUD pequeño no justifica la ceremonia?
12. 🟡 ¿Qué diferencia hay entre aislar una dependencia y eliminarla?
13. 🟡 ¿Por qué la arquitectura no arregla una frontera de negocio mala?
14. 🟡 ¿Cómo explicarías el beneficio sin prometer “futuro-proofing”?
15. 🟡 ¿Qué parte del sistema puede conocer al framework?
16. 🟡 ¿Qué parte del sistema puede conocer la política de negocio?
17. 🟠 Tienes HTTP y Kafka como entradas. ¿Qué compartirías y qué separarías?
18. 🟠 El equipo quiere crear una interfaz por cada clase. ¿Cómo responderías?
19. 🟠 Una migración de base es improbable, pero las reglas cambian cada semana. ¿Qué frontera priorizas?
20. 🟠 Una aplicación solo tiene un endpoint y una tabla. ¿Qué diseño propones?
21. 🟠 ¿Cómo defenderías hexagonal ante alguien que la llama “sobreingeniería”?
22. 🟠 ¿Qué señal te haría retirar una abstracción?
23. 🟠 ¿Qué prueba demostraría que la política está aislada?
24. 🟠 ¿Qué parte de tu respuesta cambiaría si el sistema fuera regulado?

**Siguiente:** [Regla de dependencias y dirección del código](02-regla-de-dependencias-y-direccion-del-codigo.md).
