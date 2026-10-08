# 05 — Transacciones y límites de consistencia

Este capítulo enseña a ubicar el límite transaccional alrededor de una decisión de aplicación. La transacción protege una unidad de consistencia; no convierte al repositorio, al ORM ni a una llamada remota en parte del dominio.

## 1. 🎯 El problema

`CreateOrder` reserva inventario y guarda el pedido. Si cada repositorio abre y cierra su propia transacción, una operación puede confirmar el pedido y fallar al guardar la reserva. El síntoma no es “falta una anotación”: es que el límite de consistencia quedó partido.

## 2. 🧱 Límite y unidad de trabajo

El caso de uso conoce la secuencia de negocio; un detalle de aplicación o infraestructura inicia la transacción alrededor de esa secuencia. El dominio solo cambia su estado y expone eventos o resultados. Una unidad de trabajo permite que varios puertos participen en la misma transacción física sin que el dominio importe un `EntityManager` o una conexión.

```text
entrada ─► transacción ─► CreateOrder
                         ├─ Orders
                         ├─ InventoryReservations
                         └─ UnitOfWork.commit()
                                  │
                           rollback si falla
```

La consistencia local termina cuando la base confirma. Un proveedor de pagos o un broker no se vuelven atómicos por estar dentro del mismo método. Para efectos externos, se necesita una estrategia explícita: autorización reversible, estado pendiente, outbox o compensación.

## 3. 🔄 Commit, rollback y mensajería

El flujo mínimo es: comenzar, ejecutar cambios, confirmar si todo funciona y revertir si una operación falla. Los errores de negocio que impiden completar la operación también deben dejar claro si se revierte o si forman parte de un resultado esperado.

En mensajería, el ACK suele ocurrir después del commit local. Si el proceso cae antes del ACK, el mensaje se entrega de nuevo; por eso el caso de uso debe ser idempotente o contar con deduplicación. La transacción de la base no se extiende mágicamente al broker. El [consumidor como adaptador](../03-adaptadores-de-entrada/02-mensajeria-consumidores-y-comandos.md) administra esa confirmación.

## 4. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring puede aplicar `@Transactional` mediante un interceptor y un transaction manager | escoger el límite, propagación y rollback | anotar un repositorio y partir la operación |
| Node/TS | el driver/ORM suele ofrecer una función transaccional; el runtime ofrece contexto asíncrono | pasar el contexto correcto y no mezclar conexiones | lanzar una promesa fuera de la transacción |
| Go | `database/sql` ofrece `BeginTx`, `Commit` y `Rollback` | pasar `*sql.Tx` o una unidad de trabajo sin contaminar el dominio | ejecutar una query con `db` en vez de `tx` |
| Python | drivers y frameworks ofrecen context managers transaccionales | delimitar `with`, excepciones y sesión | asumir que todo `with` cubre llamadas remotas |

En todos los casos, la plataforma resuelve mecánica; el diseño decide qué debe ser atómico. Spring documenta que su soporte declarativo usa proxies AOP y que las transacciones imperativas se asocian al contexto del hilo. Node mantiene contexto mediante `AsyncLocalStorage`, pero eso no reemplaza pasar una conexión válida. Go exige ejecutar las operaciones transaccionales sobre `sql.Tx`. Python permite expresar commit/rollback con un context manager, siempre que el adapter controle la sesión.

## 5. ⚖️ Decisión: una transacción por caso de uso

Como regla inicial, abre una transacción por comando que modifica una unidad de consistencia. No la mantengas durante HTTP remoto, espera humana, procesamiento de lotes completo ni publicación directa a un broker. Si el caso de uso necesita dos bases, primero pregunta si el límite de negocio está mal dibujado; después evalúa coordinación distribuida o consistencia eventual.

La separación simplifica rollback y pruebas, pero introduce propagación, sesiones, bloqueo, aislamiento y observabilidad. La unidad de trabajo no debe convertirse en un segundo dominio: su responsabilidad es coordinar recursos locales y cerrar correctamente.

## ⚠️ Errores frecuentes

- “La transacción pertenece al repositorio.” El repositorio ejecuta operaciones; el caso de uso define qué operaciones forman una decisión.
- “`@Transactional` hace atómico el pago.” Solo cubre los recursos configurados; un servicio remoto requiere otra estrategia.
- “Un método largo necesita una transacción larga.” Duración y atomicidad son problemas distintos.
- “Un ACK es un commit.” Son confirmaciones de sistemas distintos y deben ordenarse.
- “Pasar `tx` al dominio es una buena inversión.” Expone infraestructura; el dominio debe recibir capacidades de negocio, no conexiones.

## 6. ✅ Veredicto

Coloca la frontera en la aplicación, protege una unidad de consistencia local y deja explícita la estrategia para cada efecto externo. Si no puedes dibujar qué confirma y qué puede repetirse, todavía no tienes un límite transaccional defendible.

## 📚 Referencias

- [Spring Framework: transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)
- [Spring Framework: declarative transaction implementation](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/tx-decl-explained.html)
- [Go: executing transactions](https://go.dev/doc/database/execute-transactions)
- [Node.js: asynchronous context tracking](https://nodejs.org/api/async_context.html)
- [Python: contextlib](https://docs.python.org/3/library/contextlib.html)

## 🧠 Preguntas

1. 🟢 ¿Qué problema resuelve una transacción?
2. 🟢 ¿Qué es un límite transaccional?
3. 🟢 ¿Por qué el caso de uso suele ser una buena frontera?
4. 🟢 ¿Qué diferencia hay entre commit y rollback?
5. 🟢 ¿Qué es una unidad de trabajo?
6. 🟢 ¿El dominio debe conocer una conexión?
7. 🟢 ¿Qué ocurre si falla una operación antes del commit?
8. 🟡 ¿Por qué no abrir una transacción en cada repositorio?
9. 🟡 ¿Qué operaciones deberían participar en la misma transacción?
10. 🟡 ¿Qué cambia cuando hay una llamada a un proveedor de pagos?
11. 🟡 ¿Por qué una transacción no debe cubrir una llamada remota lenta?
12. 🟡 ¿Qué relación hay entre ACK e idempotencia?
13. 🟡 ¿Cómo decides si un error provoca rollback?
14. 🟡 ¿Qué deja explícito Go con `sql.Tx`?
15. 🟡 ¿Qué riesgo introduce una transacción declarativa en Spring?
16. 🟡 ¿Para qué sirve el contexto asíncrono en Node?
17. 🟠 Un repositorio confirma y otro falla. ¿Dónde está el defecto?
18. 🟠 El pago remoto responde tarde y la transacción bloquea filas. ¿Qué rediseñas?
19. 🟠 Un consumidor procesa dos veces el mismo mensaje. ¿Qué proteges?
20. 🟠 El equipo pasa `EntityManager` al dominio “para simplificar”. ¿Qué objeción haces?
21. 🟠 Dos bases deben confirmar juntas. ¿Qué preguntas antes de usar una transacción distribuida?
22. 🟠 El método anotado llama a otro método de la misma clase. ¿Qué verificas en Spring?
23. 🟠 Un adapter usa `db` en vez de `tx` en una operación. ¿Cómo lo detectas?
24. 🟠 ¿Cuándo aceptarías consistencia eventual en `CreateOrder`?

**Siguiente:** [Validación, errores y resultados](06-validacion-errores-y-resultados.md).
