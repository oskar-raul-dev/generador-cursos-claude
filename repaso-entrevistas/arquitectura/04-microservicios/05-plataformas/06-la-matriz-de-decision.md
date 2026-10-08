# 06 — La matriz de decisión

> Cómo se elige plataforma para un servicio nuevo, cuándo el poliglotismo es una ventaja real y
> cuándo es deuda, y cómo se dice todo eso en una entrevista sin sonar dogmático. Cierra el bloque:
> asume leídos [`01`](01-que-cambia-entre-plataformas.md) a [`05`](05-python.md) y **no repite** lo
> que dicen.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Es la pregunta de Tech Lead por excelencia, y tiene dos versiones:

```text
"¿Qué plataforma usarías para este servicio?"        → decisión técnica
"¿Cuántas plataformas debería tener el sistema?"     → decisión de organización
```

La segunda es la difícil, y casi nadie la contesta bien. El argumento habitual —"con microservicios
cada equipo elige la mejor herramienta"— suena bien y es el origen de sistemas donde nadie puede
ayudar en el servicio de al lado, hay cuatro chassis a medio mantener y la observabilidad es desigual.

Pero la respuesta contraria —"una sola plataforma, sin excepciones"— también es mala: deja fuera el
BFF que debería mantener el equipo de frontend y obliga a reescribir el servicio de datos que ya
funciona.

Este capítulo es el criterio para decidir cada caso, y la política que hace que esa decisión sea
repetible.

---

## 2. 🧰 La matriz: esfuerzo de cada patrón por plataforma

Es la tabla maestra de [`01`](01-que-cambia-entre-plataformas.md) leída en clave de **esfuerzo
relativo**: ✅ viene hecho · ⚠️ hay piezas, hay que componerlas · ❌ se escribe y se mantiene.

| Patrón | Java | Node/TS | Go | Python |
|---|---|---|---|---|
| API HTTP | ✅ | ✅ | ⚠️ | ✅ |
| gRPC | ✅ | ⚠️ | ✅ | ⚠️ |
| Tiempo real | ✅ | ✅ | ⚠️ | ✅ |
| Mensajería | ✅ | ⚠️ | ⚠️ | ✅ |
| Outbox | ✅ | ❌ | ⚠️ | ❌ |
| Saga | ✅ | ❌ | ❌ | ⚠️ |
| Resiliencia | ✅ | ⚠️ | ❌ | ⚠️ |
| Observabilidad | ✅ | ✅ | ⚠️ | ✅ |
| Acceso a datos y migraciones | ✅ | ✅ | ⚠️ | ✅ |
| Testing | ✅ | ✅ | ⚠️ | ✅ |
| Empaquetado y arranque | ⚠️ | ✅ | ✅ | ⚠️ |

**Cómo se lee, que es lo que importa:**

- **Java gana en mecánica transaccional** —outbox, saga, resiliencia— y pierde en empaquetado y
  arranque. Es la simetría más clara de la tabla.
- **Go es el inverso**: pierde en lo que hay que cablear y gana en el perfil operativo.
- **Node/TS y Python se parecen más de lo que se dice**: fuertes en el borde y en su especialidad,
  débiles en la mecánica de datos.
- **Ningún ❌ es prohibitivo.** Son días de trabajo que hay que escribir **una vez** en el chassis, no
  una vez por servicio. Esa distinción es la mitad de la decisión de poliglotismo.

---

## 3. 🧭 Los criterios, en orden

Y el orden importa más que la lista: lo que decide está arriba.

```text
1. ¿Quién lo va a mantener, y quién lo cubre cuando esa persona no está?
2. ¿Qué patrones necesita este servicio, y qué le da esta plataforma para ellos?
3. ¿Sabemos operarlo? (desplegar, diagnosticar, actualizar, a las 3 de la mañana)
4. ¿Qué perfil de carga tiene? (arranque, conexiones, memoria, cómputo)
5. ¿Podemos contratar y rotar gente en esta plataforma?
6. ¿Ya existe en la casa? ← este sube al puesto 1 cuando la respuesta es "no"
7. Rendimiento bruto ← casi nunca decide
```

El criterio 6 es el que la gente olvida y el que cambia más resultados: **un servicio que en
aislamiento estaría mejor en otra plataforma puede no compensar si es el único de esa plataforma en la
casa**, porque arrastra chassis, observabilidad, imágenes base, pipeline y guardias.

Y la regla por defecto que sale de todo esto:

> **Veredicto:** por defecto, la plataforma que ya usa el equipo. Cambiar de plataforma exige un
> motivo que supere el coste fijo de mantener una más, y ese coste es mayor de lo que parece.

---

## 4. ⚖️ Poliglotismo: cuándo sí y cuándo es deuda

**Los tres casos donde sí, con su argumento:**

| Caso | Plataforma | Argumento |
|---|---|---|
| **BFF de una experiencia** | Node/TS | Propiedad: lo mantiene el equipo de frontend, con sus tipos y su ritmo ([`04-operacion-y-resiliencia/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)) |
| **Servicio de datos o de modelos** | Python | Ecosistema: reescribirlo en otra plataforma significa perderlo |
| **Sidecar, agente o servicio de infraestructura** | Go | Perfil: binario pequeño, memoria baja, arranque inmediato |

Los tres tienen algo en común: **no son preferencias, son argumentos de propiedad, de ecosistema o de
perfil**. Si el argumento no cae en una de esas tres categorías, probablemente es gusto.

**Lo que cuesta cada plataforma añadida**, y conviene enumerarlo entero porque siempre se subestima:

```text
· chassis equivalente: logs, métricas, trazas, cliente HTTP, health, apagado
· plantilla de servicio y pipeline
· imagen base, escaneo de vulnerabilidades y política de actualización
· paneles y alertas con las mismas métricas
· conocimiento operativo: quién diagnostica esto de madrugada
· rotación: cuánta gente puede cubrir ese servicio
```

**Deuda es cuando** la plataforma se eligió por curiosidad, la mantiene una sola persona, su chassis
está a medias, y sus métricas no se parecen a las de los demás. Eso no se arregla con formación: se
arregla consolidando.

---

## 5. 🧱 La política de plataformas

**Qué es.** Un acuerdo escrito, de organización, que hace la decisión repetible y evita tenerla cada
vez.

**Cómo va.** Tiene cuatro partes y cabe en media página:

```text
1. Plataformas soportadas    la lista, corta. Cada una con dueño del chassis.
2. Requisito de entrada      una plataforma nueva necesita chassis completo,
                             plantilla, pipeline, paneles y DOS personas que la
                             sepan operar. Sin eso, no entra.
3. Excepciones               los tres casos de §4 están preaprobados; cualquier
                             otro se justifica por escrito ante quien decida.
4. Salida                    una plataforma con un solo servicio y un solo
                             mantenedor se consolida o se declara en soporte mínimo.
```

**Por qué el requisito de "dos personas"**: es la prueba más barata de que la plataforma es sostenible.
Si solo una persona sabe operarla, el servicio es intocable en cuanto esa persona no está, y eso
aparece siempre en el peor momento.

> **💡 Truco:** en una entrevista de Tech Lead, describir esta política vale más que cualquier opinión
> sobre lenguajes. Demuestra que entiendes que la decisión es de organización y que has pensado en el
> coste que otros van a pagar.

---

## 6. 🔭 El caso bancario

Conviene tenerlo preparado porque es el contexto de muchas entrevistas del sector, y la respuesta
cambia:

- **Una plataforma principal, y excepciones justificadas.** El coste de la diversidad es mayor cuando
  hay auditoría, certificación de imágenes base, y requisitos de soporte comercial por componente.
- **Java domina por razones que no son técnicas**: soporte comercial disponible, plantilla auditada,
  ecosistema de lotes y de BPM, y una bolsa de profesionales grande. Todo eso pesa en un entorno donde
  el riesgo se gestiona explícitamente.
- **Las excepciones existen igual**: el servicio de datos en Python y los agentes en Go aparecen
  también aquí, y se justifican con los mismos argumentos.
- **Lo que no encaja**: "cada equipo elige". En un entorno regulado, cada plataforma añade superficie
  que auditar y actualizar, y eso tiene un coste que alguien firma.

---

## 7. 🧭 Cómo se responde, en voz alta

La respuesta de dos minutos a "¿qué plataforma elegirías?", con sus tres partes:

```text
1. Lo que NO decide   la velocidad del lenguaje: en un servicio con base de datos,
                      casi todo el tiempo es espera
2. Lo que sí decide   quién lo mantiene · qué le da la plataforma para SUS patrones
                      · si sabemos operarlo · el perfil de carga
                      · y si esa plataforma ya existe en la casa
3. Mi recomendación   por defecto, la que ya usa el equipo.
                      Me desvío en tres casos: BFF con el equipo de frontend,
                      servicios de datos en Python, y agentes o sidecars en Go.
```

Y las dos frases que conviene tener ensayadas:

> "Cada plataforma nueva no es un lenguaje más: es un chassis, unos paneles, una imagen base y una
> guardia más. Por eso las excepciones tienen que ganarse, y por eso tengo tres preaprobadas."

> "Prefiero un sistema con dos plataformas bien sostenidas que uno con cinco a medias. Y si solo una
> persona sabe operar una de ellas, eso no es poliglotismo: es un punto único de fallo con nombre y
> apellidos."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Elegimos el mejor lenguaje para cada problema" | Cada plataforma añade chassis, paneles, imágenes, actualizaciones y guardias. El "mejor lenguaje" tiene que superar ese coste |
| "Poliglota es una ventaja de los microservicios" | Es una **posibilidad**, no un objetivo. Las ventajas reales son tres casos concretos, no la diversidad en sí |
| "Cambiamos de plataforma por rendimiento" | Antes hay que medir dónde se va el tiempo. Casi siempre es espera, y entonces la migración no cambia nada |
| "El lenguaje da igual, lo importante es la arquitectura" | El lenguaje decide cuánto código escribes para el mismo patrón y qué perfil operativo tienes. Da igual para la latencia, no para el coste |
| "Cada equipo es autónomo, que elija" | Autonomía no es ausencia de política. La autonomía se ejerce dentro de un conjunto soportado |
| "Somos políglotas" con un servicio de cada | Eso es una plataforma por persona. Poliglotismo sostenible es cada plataforma con chassis, paneles y dos personas |
| "Reescribimos el servicio de datos en Java por uniformidad" | Se perdería el ecosistema que lo justificaba. La uniformidad no vale cuando destruye la razón de la excepción |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 2, sobre
   libertad de stack, y capítulo 15, sobre organización. **Es la mejor fuente para este capítulo.**
2. **Libro** — Nicole Forsgren, Jez Humble y Gene Kim, *Accelerate*, IT Revolution, 2018. Para el
   argumento de que las prácticas pesan más que la tecnología elegida.
3. **Libro** — Matthew Skelton y Manuel Pais, *Team Topologies*, IT Revolution, 2019. Para la parte de
   propiedad y de carga cognitiva, que es lo que de verdad limita el número de plataformas.
4. **Fuente primaria** — Martin Fowler, «Microservice Trade-Offs», sección de tecnología heterogénea:
   [martinfowler.com/articles/microservice-trade-offs.html](https://martinfowler.com/articles/microservice-trade-offs.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: Service per team», para la relación entre equipos
   y servicios:
   [microservices.io/patterns/decomposition/service-per-team.html](https://microservices.io/patterns/decomposition/service-per-team.html).
6. **Referencia** — endoflife.date, para sostener la política: una plataforma soportada implica
   seguir sus fechas de fin de soporte: [endoflife.date](https://endoflife.date/).
7. **Charla** — GOTO Conferences, «Polyglot Programming: The Good, the Bad and the Ugly». La
   contraparte honesta del entusiasmo por la diversidad.

---

## 🧠 Preguntas

1. ¿Cuáles son los criterios de decisión, en orden? 🟢
2. Nombra los tres casos de poliglotismo preaprobados y su argumento. 🟢
3. Enumera lo que cuesta añadir una plataforma. 🟢
4. ¿Cuáles son las cuatro partes de la política de plataformas? 🟢
5. ¿Por qué se exige que dos personas sepan operar una plataforma? 🟢
6. ¿Qué patrón separa más a Java del resto, según la matriz? 🟡
7. ¿Por qué el criterio "¿ya existe en la casa?" cambia tantos resultados? 🟡
8. ¿Por qué ningún ❌ de la matriz es prohibitivo? 🟡
9. ¿Por qué en banca la respuesta tiende a una plataforma principal? 🟡
10. ¿Por qué "cada equipo elige" no es lo mismo que autonomía? 🟡
11. ¿Qué diferencia hay entre poliglotismo y deuda de plataformas? 🟠
12. ¿Por qué reescribir un servicio de datos por uniformidad suele ser un error? 🟠
13. Un equipo quiere escribir su servicio en una plataforma nueva. ¿Qué le pides? 🟠
14. Tienes cinco plataformas con un servicio cada una. ¿Qué haces? 🟠
15. ¿Cómo justificarías ante dirección que el BFF esté en otra plataforma? 🟠
16. Un servicio de Go lo mantiene una sola persona y se va del equipo. ¿Qué haces? 🟠
17. ¿Qué preguntas antes de aprobar una excepción a la plataforma principal? 🟠
18. ¿Cómo decides si consolidar una plataforma o mantenerla en soporte mínimo? 🟠
19. ¿Qué responderías a "el lenguaje da igual, lo importante es la arquitectura"? 🟠
20. ¿Cómo mantendrías la política viva y no como un documento olvidado? 🟠
21. Escribe la política de plataformas de una organización con 25 servicios y tres equipos, con sus
    excepciones y su proceso. 🔴
22. Diseña la decisión de plataforma para cuatro servicios nuevos con perfiles distintos,
    justificando cada una y diciendo cuál te costaría más defender. 🔴
23. Un equipo propone reescribir tres servicios en otra plataforma por rendimiento. Diseña la
    respuesta: qué mides, qué concedes y qué alternativa ofreces. 🔴
24. Escribe la respuesta completa de dos minutos a "¿cuántas plataformas debería tener nuestro
    sistema?". 🔴

---

**Anterior:** [`05` — Python](05-python.md) · **Siguiente:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) · **Relacionado:** [`01` — Qué cambia entre plataformas](01-que-cambia-entre-plataformas.md)
· [`04-operacion-y-resiliencia/05`](../04-operacion-y-resiliencia/05-service-mesh-y-sidecar.md)
