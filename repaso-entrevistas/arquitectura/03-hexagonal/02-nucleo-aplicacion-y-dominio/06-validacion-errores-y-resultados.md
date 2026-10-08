# 06 — Validación, errores y resultados

Este capítulo enseña a repartir la validación sin convertir al controller en dueño de las invariantes ni al dominio en parser de HTTP. Cada frontera valida lo que puede conocer y traduce el error una sola vez.

## 1. 🎯 El problema

Un request puede traer un JSON mal formado, un usuario sin permiso o un pedido que supera el límite de crédito. Son fallos distintos. Si todos terminan como `400`, `500` o una excepción genérica, el sistema pierde semántica y el cliente no sabe si corregir datos, autenticarse o reintentar.

## 2. 🧭 Tres lugares de validación

```text
transporte ─► forma y tipos ─► aplicación: autorización y coordinación
                                      │
                                      └─ dominio: invariantes de negocio
```

El borde comprueba sintaxis, tamaño, formato y campos obligatorios. La aplicación valida permisos contextuales, existencia de recursos y reglas que dependen de varios puertos. El dominio protege invariantes que deben ser ciertas sin importar quién lo invoque: HTTP, un job o un consumidor.

Validar dos veces no siempre es un problema: el borde puede rechazar pronto y el dominio debe defenderse de todos modos. Lo que sobra es duplicar mensajes, códigos y reglas en cada adapter.

## 3. 🧩 Errores contra resultados

Un error de negocio esperado puede modelarse como un resultado tipado o como una excepción traducida en el borde. La elección depende del lenguaje y del flujo, pero la semántica debe ser explícita:

```text
CreateOrder.execute(command)
  ├─ OrderCreated
  ├─ CustomerNotFound
  ├─ InsufficientInventory
  └─ Error técnico: se registra y se traduce sin filtrar secretos
```

Los errores de negocio no son necesariamente fallos del sistema. `InsufficientInventory` puede producir una respuesta conocida; un timeout de base puede reintentarse o convertirse en un error temporal. El adaptador de entrada transforma el contrato interno a HTTP, mensajería o CLI; el núcleo no construye `ResponseEntity`, `HTTPException` ni códigos del broker. La [presentación HTTP de errores](../03-adaptadores-de-entrada/05-dto-mapeo-y-presentacion-de-errores.md) y la [clasificación en mensajería](../03-adaptadores-de-entrada/02-mensajeria-consumidores-y-comandos.md) usan esa misma semántica.

## 4. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | excepciones, sealed types y validadores de framework | jerarquía de errores y traducción | capturar `Exception` y devolver 400 |
| Node/TS | tipos estáticos y librerías de validación runtime | validar datos externos y modelar `Result` | creer que TypeScript valida JSON |
| Go | errores como valores y `errors.Is/As` | taxonomía, wrapping y mapping | comparar strings de error |
| Python | excepciones, `dataclasses` y validadores disponibles | límites runtime y mensajes seguros | lanzar `ValueError` para todo |

La plataforma ayuda a transportar un fallo; no decide si es una regla de negocio. En TypeScript, la forma del tipo desaparece en runtime. En Go, envolver preserva contexto si se usa una causa reconocible. En Python y Java, una excepción de proveedor debe traducirse en el adapter antes de cruzar el puerto.

## 5. ⚖️ Mensajes y seguridad

El cliente recibe un código estable, un mensaje útil y un identificador de correlación. No recibe SQL, stack trace, tokens, nombres internos de tablas ni detalles del proveedor. Los logs internos deben conservar la causa técnica y el contexto suficiente para investigar, con redacción de datos sensibles.

Un resultado rico sirve cuando el flujo espera muchos estados de negocio y el compilador puede ayudar. Una excepción sirve para abortar una operación excepcional o atravesar capas hasta un traductor central. Mezclarlos sin convención crea doble manejo y respuestas inconsistentes.

## 6. ⚖️ Decisión y coste

Valida la forma en el borde, el contexto en aplicación y las invariantes en dominio. Modela errores con nombres de negocio, tradúcelos en el adaptador y conserva la causa técnica solo donde sea segura. La separación compensa cuando evita que cada transporte invente su propia política.

## ⚠️ Errores frecuentes

- “Toda validación va en el controller.” Las invariantes deben sobrevivir a cualquier entrada.
- “TypeScript ya validó el request.” El JSON llega en runtime y necesita comprobación.
- “Todo error es una excepción técnica.” Un rechazo de negocio no implica que el sistema esté roto.
- “El mensaje interno puede devolverse al cliente.” Puede revelar infraestructura o datos sensibles.
- “Un `catch` global arregla el diseño.” Centraliza la traducción, no la semántica que falta.

## 7. ✅ Veredicto

Valida forma en el borde, autorización contextual en aplicación e invariantes en dominio. Conserva errores propios hasta que cada adaptador los presente de forma segura.

## 📚 Referencias

- [TypeScript: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
- [Go: working with errors](https://go.dev/blog/go1.13-errors)
- [Java: sealed classes](https://docs.oracle.com/en/java/javase/21/language/sealed-classes-and-interfaces.html)
- [Python: errors and exceptions](https://docs.python.org/3/tutorial/errors.html)
- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)

## 🧠 Preguntas

1. 🟢 ¿Qué valida el adaptador de entrada?
2. 🟢 ¿Qué es una invariante?
3. 🟢 ¿Qué valida la aplicación?
4. 🟢 ¿Por qué el dominio no debe conocer HTTP?
5. 🟢 ¿Qué diferencia hay entre error de negocio y error técnico?
6. 🟢 ¿Qué significa traducir un error?
7. 🟢 ¿Qué información no debe exponerse en un error?
8. 🟡 ¿Por qué validar una regla en más de una capa puede ser correcto?
9. 🟡 ¿Cuándo usarías un resultado tipado?
10. 🟡 ¿Cuándo usarías una excepción?
11. 🟡 ¿Cómo diferencias un error reintentable?
12. 🟡 ¿Quién convierte un error de negocio en respuesta HTTP?
13. 🟡 ¿Qué riesgo tiene un `catch` de `Exception` en Java?
14. 🟡 ¿Por qué TypeScript necesita validación runtime?
15. 🟡 ¿Cómo conservas la causa técnica sin filtrarla?
16. 🟡 ¿Qué contrato debe compartir un error entre HTTP y mensajería?
17. 🟠 Un controller valida el límite de crédito y un job no. ¿Qué cambias?
18. 🟠 El dominio lanza `HTTPException`. ¿Cómo lo desacoplas?
19. 🟠 El proveedor devuelve 40 errores y el negocio conoce 4. ¿Dónde traduces?
20. 🟠 Un cliente ve “database timeout”. ¿Qué problema de frontera detectas?
21. 🟠 Una operación devuelve cinco rechazos esperados. ¿Preferirías `Result` o excepciones?
22. 🟠 Un mensaje inválido llega al consumidor. ¿Lo reintentas?
23. 🟠 Dos adapters mapean el mismo error con códigos distintos. ¿Cómo corriges la inconsistencia?
24. 🟠 ¿Cómo diseñarías un error seguro para “pedido no encontrado” sin filtrar existencia sensible?

**Siguiente:** [Eventos de dominio y efectos secundarios](07-eventos-de-dominio-y-efectos-secundarios.md).
