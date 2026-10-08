# 07 — Testing de microservicios

> Cómo se consigue confianza sin un entorno de integración completo: pirámide deformada, pruebas de
> componente, contratos de consumidor, contenedores efímeros y pruebas en producción. Asume leído
> [`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md), que es donde se define el
> pacto; aquí se sitúa dentro de la estrategia.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

En el monolito, la estrategia era clara: muchas pruebas unitarias, algunas de integración, unas pocas
de extremo a extremo. Con microservicios, esa última capa se rompe:

```text
Para una prueba de extremo a extremo necesitas:
  · los cinco servicios desplegados y en versiones compatibles
  · sus cinco bases con datos coherentes entre sí
  · el broker, con sus topics
  · y que nadie más esté usando ese entorno en ese momento
```

El resultado conocido: un entorno de integración que casi nunca está sano, pruebas que fallan por
motivos ajenos al cambio, y un equipo que reintenta el pipeline sin mirar el error. Eso es peor que
no tener pruebas, porque **enseña a ignorar los fallos**.

La salida no es probar menos: es **sustituir el entorno completo** por otras formas de confianza. Y
la pieza que lo hace posible es el contrato verificado.

---

## 2. ⚖️ La pirámide, deformada

**Qué es.** La pirámide clásica sigue valiendo en su idea central —más pruebas cuanto más baratas y
rápidas— pero cambia de forma: el peso se desplaza de las pruebas de extremo a extremo hacia las de
componente y las de contrato.

```text
        clásica                     en microservicios
      ▲  e2e                      ▲  e2e (muy pocas, solo flujos críticos)
     ███ integración             ███ contrato (rápidas, por servicio)
    █████ unidad                ██████ componente (el servicio entero, aislado)
                               ████████ unidad
```

| Tipo | Qué prueba | Qué necesita | Velocidad |
|---|---|---|---|
| **Unidad** | Lógica de dominio, casos borde | Nada | Milisegundos |
| **Componente** | El servicio entero por su API | Dependencias simuladas o en contenedor | Segundos |
| **Contrato** | Que no rompes a tus consumidores | Solo el pacto publicado | Segundos |
| **Integración** | Que hablas bien con una dependencia real | Esa dependencia, en contenedor | Segundos a minutos |
| **Extremo a extremo** | Un flujo completo de negocio | Todo | Minutos, y frágil |

**Lo que hay que poder decir en voz alta:** las pruebas de contrato son las que permiten reducir las
de extremo a extremo sin perder confianza, porque cubren exactamente lo que aquellas verificaban: que
los servicios encajan.

---

## 3. 🧱 Pruebas de componente

**Qué es.** Probar el servicio **entero**, por su API pública, con sus dependencias externas
sustituidas.

**Cómo va.** Se levanta la aplicación real —con su enrutado, su serialización, su validación y su
manejo de errores— y se sustituyen las dependencias:

| Dependencia | Cómo se sustituye |
|---|---|
| Base de datos | Contenedor efímero con la **misma** tecnología y versión |
| Otro servicio HTTP | Simulador de servidor con respuestas preparadas |
| Broker | Contenedor efímero, o un doble en memoria si basta |

**Con qué.** La familia de contenedores efímeros para pruebas existe en las cuatro plataformas, y es
el nivelador: permite usar la base real en lugar de una en memoria que se comporta distinto.

**Cuánto.** Cuesta segundos por prueba y algo de infraestructura local. A cambio cubre la mayor parte
de lo que cubrían las pruebas de extremo a extremo, sin depender de nadie.

**Cuándo sí.** Es la capa que más rinde en microservicios y donde conviene invertir primero.

**Cuándo no.** Para lógica de dominio pura: eso es más barato y más rápido en pruebas unitarias.

> **💡 Truco:** usar la base de datos real en contenedor en vez de una en memoria elimina una clase
> entera de sorpresas —dialecto de SQL, tipos, transacciones, bloqueos— que aparecen en producción
> justo cuando la prueba decía que todo estaba bien.

---

## 4. 🧱 Contratos de consumidor en la estrategia

**Qué es.** Ya se definió en [`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md):
el consumidor declara lo que espera y el proveedor lo verifica en su pipeline.

**Su papel aquí.** Es lo que **sustituye al entorno de integración completo**. La pregunta que
respondían las pruebas de extremo a extremo —"¿siguen encajando estos servicios?"— la responde el
pacto, y lo hace en segundos, sin desplegar nada y con un significado inequívoco cuando falla.

```text
Entorno completo                  Contratos
─────────────────────────────     ──────────────────────────────
lento, frágil, compartido         rápido, aislado, por servicio
falla por motivos ajenos          falla solo si rompes a alguien
responde "algo no va"             responde "rompes a este consumidor"
```

**Lo que no cubre.** Que el flujo de negocio completo funcione: el pacto verifica la forma y el
comportamiento de una interacción, no que la saga acabe bien. Para eso quedan unas pocas pruebas de
extremo a extremo.

> **Veredicto:** si tu estrategia de pruebas depende de un entorno donde todo está desplegado a la
> vez, estás pagando fragilidad por una confianza que un contrato verificado te da más barata y más
> precisa.

---

## 5. 🧱 Extremo a extremo, y pruebas en producción

**Extremo a extremo: cuáles sobreviven.** Solo los flujos críticos de negocio, contados con los dedos
de una mano:

- confirmar un pedido de principio a fin;
- un flujo de compensación —el cobro falla y se libera la reserva—;
- y poco más.

Cada una cuesta mantenimiento constante y falla por motivos ajenos. La regla: **si una prueba de
extremo a extremo falla y nadie investiga, hay que borrarla**, porque ya no aporta señal y sí ruido.

**Pruebas en producción.** No es una herejía, es reconocer que el único entorno realista es
producción:

| Técnica | Qué es | Riesgo |
|---|---|---|
| **Despliegue oscuro** | La versión nueva recibe copia del tráfico, sin efectos | Hay que garantizar que no escribe ni llama a terceros |
| **Canary con métricas** | Ya visto en [`06`](06-despliegue-y-entrega.md) | Exposición parcial y controlada |
| **Verificación sintética** | Un flujo de negocio ejecutado periódicamente contra producción | Genera datos de prueba que hay que aislar |

La verificación sintética es la que más rinde y la que menos se usa: un pedido de prueba cada cinco
minutos detecta fallos que ninguna métrica técnica ve, porque comprueba el flujo como lo vive el
usuario.

**Chaos engineering**, a la escala de un equipo normal: no hace falta herramienta cara. Matar una
instancia a mano, cortar una dependencia con una regla de red, o forzar un retraso en un cliente son
experimentos válidos si se hacen con hipótesis previa y en horario controlado.

---

## 6. 🧱 Lo que casi nadie prueba

Cuatro cosas que fallan en producción y que rara vez tienen prueba:

```text
La idempotencia del consumidor   procesar el mismo mensaje dos veces y comprobar
                                 que el efecto se aplicó una sola vez
El apagado ordenado              desplegar con tráfico y comprobar que no hay 5xx
Las migraciones                  aplicar sobre un volumen realista y medir bloqueos
La compensación de la saga       forzar el fallo del paso 3 y verificar el estado final
```

Las cuatro son baratas de escribir y cubren fallos caros. La primera en particular es de las pruebas
con mejor relación entre esfuerzo y valor de todo el corpus: procesar dos veces el mismo mensaje en
una prueba de componente con base real, y comprobar que solo hay una reserva.

> **⚠️ Advertencia:** una saga sin prueba de su camino de compensación se descubre rota el día que
> falla un cobro. Y ese día, el camino que nunca se ejecutó es precisamente el que tiene que
> funcionar.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | El ecosistema más completo: arranque del contexto en pruebas, contenedores efímeros integrados, simuladores de servidor HTTP maduros, verificación de pactos | Que las pruebas de componente no se conviertan en pruebas lentas de todo: hay que acotar qué se levanta |
| **Node/TS** | Ejecutores rápidos, simuladores de HTTP a nivel de red, implementación de pactos, contenedores efímeros | Aislar bien el estado entre pruebas cuando se comparte proceso; y no confundir tipos con validación |
| **Go** | Pruebas en la librería estándar, servidor HTTP de prueba incluido, contenedores efímeros | Escribir los dobles a mano: no hay marco de simulación dominante, y suele ser una ventaja |
| **Python** | Ejecutor muy expresivo con accesorios reutilizables, contenedores efímeros, simuladores de HTTP | Que los accesorios no se conviertan en un sistema paralelo difícil de entender |

La prueba de idempotencia en Java, que es la que hay que saber escribir:

```java
@Test
void same_event_twice_reserves_once() {
    var event = new OrderPlaced("ORD-00042", List.of(new OrderLine("SKU-017", 2)));

    consumer.on(event, "msg-1");
    consumer.on(event, "msg-1");             // mismo identificador: reentrega

    assertThat(reservations.byOrder("ORD-00042")).hasSize(1);   // el efecto, una vez
}
```

- Se ejecuta contra la **base real en contenedor**: la deduplicación depende de un índice único, y con
  una base en memoria puede comportarse distinto.
- El caso difícil merece su propia prueba: fallo **después** de aplicar el efecto y antes de
  confirmar, que es lo que provoca la reentrega real.

Y en Node/TS, la verificación de contrato desde el lado del consumidor:

```ts
// El pacto describe lo que ESTE consumidor necesita, no todo lo que el proveedor devuelve.
await provider
  .given('order ORD-00042 exists')             // estado que el proveedor debe preparar
  .uponReceiving('a request for an order')
  .withRequest({ method: 'GET', path: '/orders/ORD-00042' })
  .willRespondWith({
    status: 200,
    body: like({ id: 'ORD-00042', status: 'CONFIRMED' }),   // forma, no valores exactos
  });
```

- `like` declara la **forma** esperada, no el valor: acoplarse a valores concretos produce pactos que
  se rompen por datos de prueba y no por cambios reales.
- El pacto declara solo los campos que el consumidor usa. Si declara todo lo que recibe, cualquier
  campo nuevo lo rompe y el mecanismo pierde su valor.

> **🧰 Plataforma:** el nivelador de las cuatro es la familia de contenedores efímeros: permite que la
> prueba de componente use la base, el broker y hasta el índice de búsqueda reales. Es la herramienta
> que más ha cambiado el testing de microservicios en la última década, y conviene nombrarla.

---

## 8. 🧭 Cómo se elige qué escribir

```text
¿Qué quieres comprobar?
│
├─ una regla de negocio ──────────────► unidad
├─ que el servicio hace lo que promete ► componente (API propia, dependencias simuladas)
├─ que hablas bien con tu base ───────► integración con contenedor efímero
├─ que no rompes a un consumidor ─────► contrato
├─ que un flujo de negocio funciona ──► una e2e, y solo si es crítico
└─ que funciona de verdad ────────────► verificación sintética en producción
```

Y la frase que responde a "¿cómo pruebas microservicios?":

> "Muchas de componente con dependencias en contenedor, contratos de consumidor para no romper a
> nadie, y muy pocas de extremo a extremo —solo los flujos críticos—. El entorno donde todo está
> desplegado a la vez lo sustituyo por contratos, porque falla solo cuando de verdad hay un
> problema."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Tenemos un entorno de integración donde probamos todo junto" | Es lento, frágil y compartido; falla por motivos ajenos y enseña al equipo a ignorar los fallos |
| "Los contract tests son tests de integración" | No levantan el otro servicio: verifican una expectativa publicada, en segundos y aisladamente |
| "Cubrimos con end-to-end lo que no cubren los unitarios" | Ese hueco lo cubren las de componente y las de contrato, que son estables y rápidas |
| "No se puede probar un consumidor de eventos" | Se prueba igual: se le entrega un mensaje y se comprueba el efecto, incluida la reentrega |
| "Usamos una base en memoria, es más rápida" | Y se comporta distinto: dialecto, tipos, transacciones, bloqueos. El contenedor efímero es la diferencia entre probar y creer que pruebas |
| "Probar en producción es una temeridad" | Despliegue oscuro, canary y verificación sintética son formas controladas de comprobar lo único que es real |
| "El pacto declara toda la respuesta del proveedor" | Solo lo que el consumidor usa. Si declara de más, se rompe con cambios compatibles |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 9, "Testing":
   la pirámide deformada, los contratos y las pruebas en producción. **El capítulo de referencia.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulos 9 y 10, con la
   estrategia completa y ejemplos de cada nivel.
3. **Libro** — Jez Humble y David Farley, *Continuous Delivery*, Addison-Wesley, 2010. Capítulo 4,
   sobre la estrategia de pruebas dentro de la tubería.
4. **Fuente primaria** — Martin Fowler, «The Practical Test Pyramid», con la discusión de qué es una
   prueba de componente:
   [martinfowler.com/articles/practical-test-pyramid.html](https://martinfowler.com/articles/practical-test-pyramid.html).
5. **Documentación** — Pact, cómo funciona la verificación de pactos en el pipeline del proveedor:
   [docs.pact.io/getting_started/how_pact_works](https://docs.pact.io/getting_started/how_pact_works).
6. **Documentación** — Testcontainers, contenedores efímeros para pruebas, disponible en las cuatro
   plataformas: [testcontainers.com](https://testcontainers.com/).
7. **Documentación** — WireMock, simulación de servidores HTTP para pruebas de componente:
   [wiremock.org/docs](https://wiremock.org/docs/).
8. **Referencia** — «Principles of Chaos Engineering», para el método de los experimentos de §5:
   [principlesofchaos.org](https://principlesofchaos.org/).

---

## 🧠 Preguntas

1. ¿Por qué se deforma la pirámide de pruebas en microservicios? 🟢
2. ¿Qué es una prueba de componente? 🟢
3. ¿Qué papel juegan los contratos en la estrategia de pruebas? 🟢
4. ¿Qué pruebas de extremo a extremo sobreviven? 🟢
5. Nombra tres formas de probar en producción. 🟢
6. Enumera cuatro cosas que casi nadie prueba. 🟢
7. ¿Qué dos herramientas igualan la estrategia de pruebas en las cuatro plataformas? 🟢
8. ¿Por qué un entorno de integración compartido enseña a ignorar los fallos? 🟡
9. ¿Por qué una base en memoria no sustituye a la real en contenedor? 🟡
10. ¿Qué diferencia hay entre una prueba de contrato y una de integración? 🟡
11. ¿Por qué un pacto no debe declarar toda la respuesta del proveedor? 🟡
12. ¿Qué es la verificación sintética y qué detecta que no detectan las métricas? 🟡
13. ¿Qué te da cada plataforma para las pruebas de componente, y cuál es el nivelador común? 🟡
14. ¿Cómo se prueba la idempotencia de un consumidor? 🟠
15. Tu suite de extremo a extremo falla el 30 % de las veces por motivos ajenos. ¿Qué haces? 🟠
16. ¿Cómo probarías el camino de compensación de una saga? 🟠
17. ¿Cómo pruebas que el apagado ordenado funciona? 🟠
18. ¿Qué dependencias simularías y cuáles levantarías de verdad en una prueba de componente? 🟠
19. ¿Cómo evitas que los datos de la verificación sintética ensucien producción? 🟠
20. Un equipo no tiene contratos y quiere quitar el entorno de integración. ¿Por dónde empieza? 🟠
21. ¿Qué experimento de caos harías primero en un sistema sin experiencia previa? 🟠
22. ¿Cómo pruebas una migración antes de producción de forma realista? 🟠
23. Diseña la estrategia de pruebas completa de `orders`: qué se prueba en cada nivel, con qué, y
    qué queda fuera a propósito. 🔴
24. Diseña la prueba de extremo a extremo del flujo de confirmación, decidiendo qué se levanta, qué
    se simula y cómo se mantiene estable. 🔴
25. Un sistema tiene 200 pruebas de extremo a extremo y tardan dos horas. Escribe el plan para
    reducirlas sin perder confianza. 🔴
26. Diseña el conjunto de verificaciones sintéticas del sistema: qué flujos, cada cuánto, qué datos
    y qué alertas. 🔴

---

**Anterior:** [`06` — Despliegue y entrega](06-despliegue-y-entrega.md) · **Siguiente:**
[`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) · **Relacionado:**
[`02-comunicacion/07`](../02-comunicacion/07-contratos-y-versionado.md) ·
[`03-datos-y-consistencia/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md)

**Taller, opcional:** [`06/10` — Contratos entre servicios y testing](../06-talleres/10-contratos-y-testing.md).
