# 01 — Qué es una arquitectura monolítica

Aprenderás a reconocer un monolito por su unidad de despliegue y operación, sin usar la palabra
como sinónimo de código desordenado. Esa distinción permite conservar las ventajas de lo local y
discutir sus límites con evidencia.

## 1. 🎯 La decisión que importa

`orders`, `inventory`, `payments` y `notifications` pueden compilarse y liberarse como una sola
aplicación. `CreateOrder` llama código del mismo proceso, y una versión nueva sustituye la unidad
completa. Eso describe una topología monolítica; todavía no dice si el código está bien dividido.

```text
clientes ──► balanceador ──┬─► aplicación v18 ──► base de datos
                           ├─► aplicación v18 ──► base de datos
                           └─► aplicación v18 ──► base de datos
                                un mismo artefacto y contrato operativo
```

Las tres instancias son réplicas equivalentes del mismo monolito. Monolito significa aquí una
unidad lógica desplegable, no un único servidor ni una única copia en ejecución.

## 2. 🧱 Qué permanece unido

La definición útil empieza por la unidad de despliegue, pero conviene mirar las cinco monedas:

| Moneda | En este monolito | Consecuencia |
|---|---|---|
| Código | las cuatro capacidades forman una aplicación | un build valida el conjunto |
| Datos | una base puede soportar transacciones locales | no implica datos sin propietario |
| Despliegue | se libera una versión del conjunto | un cambio pequeño despliega todo |
| Runtime | una llamada local no necesita red interna | un fallo de proceso afecta al conjunto |
| Equipos | puede haber uno o varios equipos | la topología no concede ownership |

Una aplicación puede vivir en un monorepo o en varios repositorios y seguir siendo un monolito si
termina desplegándose como una unidad. También puede usar workers auxiliares o procesos del sistema
sin que cada proceso pase a ser un servicio autónomo. La pregunta es qué se versiona, cambia y opera
como conjunto.

## 3. ⚡ Las garantías de lo local

En el camino feliz de `CreateOrder`, una llamada de función tiene semántica directa: devuelve,
lanza un error o el proceso deja de existir. No hay serialización, compatibilidad de protocolo ni
timeout de red entre `orders` e `inventory`. Si ambos estados viven en la misma base, una
transacción puede confirmar pedido y reserva atómicamente.

```text
CreateOrder
   ├─► ReserveInventory()      llamada local
   ├─► RecordPaymentIntent()   escritura local
   └─► COMMIT                  una frontera transaccional posible
```

La intención de pago se registra localmente; la autorización de un proveedor externo queda fuera
de este commit y requiere recuperación propia. Que la API de `payments` sea local no vuelve atómico
su efecto remoto.

La garantía conservada es una coordinación local sencilla. El coste es compartir despliegue,
recursos del proceso y, si no hay límites internos, un radio de cambio creciente. Que sea posible
una transacción amplia no obliga a meter todo en ella.

## 4. 🔍 Evidencia, inferencia y diagnóstico

- **Observación:** existe un artefacto desplegable y todas sus réplicas ejecutan la misma versión.
- **Inferencia:** un release cambia la unidad completa y las llamadas internas pueden ser locales.
- **Diagnóstico:** la topología es monolítica. Su modularidad, mantenibilidad y adecuación requieren
  evidencia adicional.

No diagnostiques una *big ball of mud* porque haya un solo artefacto. Busca cambios que atraviesan
responsabilidades, escrituras cruzadas, ciclos, ownership difuso y pruebas que solo funcionan de
extremo a extremo. Tampoco concluyas que hay servicios autónomos porque veas varios contenedores.

## 5. 🧰 Empaquetado sin casarse con un framework

Este capítulo es conceptual y no necesita código. Las plataformas cambian el formato, no la
definición:

| Plataforma | Empaquetado frecuente | Qué no demuestra | Trampa frecuente |
|---|---|---|---|
| Java | JAR ejecutable o imagen | modularidad interna | contar módulos Maven como servicios |
| Node/TypeScript | paquete y salida JS en una imagen | ownership de capacidades | contar procesos del cluster como servicios |
| Go | binario ejecutable | límites de datos | equiparar paquete con despliegue |
| Python | paquete, wheel o imagen con la app | aislamiento operativo | llamar servicio a cada worker |

Una imagen de contenedor puede contener el mismo artefacto que otras cien réplicas. El contenedor es
un mecanismo de ejecución; la autonomía exige además decisiones, datos y despliegues independientes.

## 6. ⚖️ Ventajas, límites y coste

Un monolito reduce saltos de red internos, simplifica el debug de un flujo y permite despliegue y
transacciones locales. A cambio, escala y libera el artefacto completo; un consumo excesivo de
memoria, CPU o conexiones puede competir con otras capacidades; y la disciplina interna no viene
incluida.

El límite decisivo aparece cuando una parte necesita una cadencia, aislamiento o escalado realmente
independiente y el beneficio supera el precio de la distribución. Hasta entonces, modularizar dentro
del proceso suele conservar más opciones con menos mecanismos.

## ⚠️ Errores frecuentes

- «Monolito significa legado». La edad y la topología son dimensiones distintas.
- «Solo puede haber una instancia». Réplicas equivalentes pueden escalar horizontalmente.
- «Una base compartida define el monolito». Una base es una señal sobre datos, no la topología entera.
- «Un despliegue único elimina los fallos parciales». Las dependencias externas y recursos internos
  todavía pueden fallar de manera selectiva.
- «Como la llamada es local, el módulo está desacoplado». La ausencia de red no elimina dependencias
  de código, datos o cambio.

## 7. ✅ Veredicto

Llama monolito a una aplicación que se construye y despliega como una unidad lógica, aunque tenga
muchas réplicas. Después evalúa por separado estructura interna, ownership y operación. La topología
compra simplicidad local; solo es un problema cuando las restricciones observadas exigen autonomía
que esa unidad ya no puede ofrecer a un coste razonable.

## 📚 Referencias

- [Microservices, Martin Fowler y James Lewis](https://martinfowler.com/articles/microservices.html)
- [JAR File Specification, Oracle](https://docs.oracle.com/en/java/javase/25/docs/specs/jar/jar.html)
- [Design to scale out, Microsoft Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/guide/design-principles/scale-out)

## 🧠 Preguntas

1. 🟢 ¿Qué dimensión define primero a una arquitectura monolítica?
2. 🟢 ¿Por qué un monolito puede ejecutar varias réplicas?
3. 🟢 ¿Qué diferencia hay entre aplicación desplegable y proceso?
4. 🟢 ¿Qué ventaja ofrece una llamada local entre `orders` e `inventory`?
5. 🟢 ¿Qué garantía puede conservar una transacción local?
6. 🟢 ¿Un monorepo demuestra que el sistema es monolítico?
7. 🟢 ¿Una imagen de contenedor equivale a un servicio autónomo?
8. 🟡 ¿Qué puedes inferir y qué no de un único artefacto desplegable?
9. 🟡 ¿Por qué topología y calidad interna deben evaluarse por separado?
10. 🟡 ¿Qué coste de despliegue asume un monolito ante un cambio pequeño?
11. 🟡 ¿Cómo distingues una réplica de un servicio diferente?
12. 🟡 ¿Qué cambia si `notifications` corre como worker pero se libera junto con la aplicación?
13. 🟡 ¿Qué evidencia buscarías antes de llamar *big ball of mud* a un monolito?
14. 🟡 ¿Por qué una base compartida no basta para clasificar toda la arquitectura?
15. 🟡 ¿Qué significa que el monolito sea una unidad lógica y no necesariamente física?
16. 🟡 ¿Qué riesgo introduce compartir recursos de proceso?
17. 🟡 ¿Cuándo una transacción amplia deja de ser una ventaja?
18. 🟠 Tres réplicas pierden sesiones al balancear tráfico. ¿Es un límite del monolito o del diseño de estado?
19. 🟠 `payments` necesita desplegar diez veces al día y el resto una vez al mes. ¿Qué evidencia falta antes de separarlo?
20. 🟠 Un equipo propone HTTP interno para «estar listo para microservicios». ¿Qué garantía perdería hoy?
21. 🟠 Un fallo de memoria en reportes derriba checkout. ¿Qué opciones evaluarías antes de extraer un servicio?
22. 🟠 La aplicación usa un repositorio por módulo, pero un solo release. ¿Cómo la clasificarías?
23. 🟠 ¿Qué condición justificaría pagar serialización, timeouts y observabilidad distribuida?
24. 🟠 ¿Cómo responderías a «los monolitos no escalan» sin prometer escalabilidad infinita?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Siguiente:** [02 — Unidades de código, despliegue, ejecución y datos](02-unidades-de-codigo-despliegue-ejecucion-y-datos.md).
