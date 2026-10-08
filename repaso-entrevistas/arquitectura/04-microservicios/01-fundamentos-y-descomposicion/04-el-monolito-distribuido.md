# 04 — El monolito distribuido

> El catálogo de formas en que una arquitectura "de microservicios" no lo es, cómo se reconoce cada
> una en menos de dos minutos, y qué la produjo. Asume leído
> [`01`](01-que-es-un-microservicio.md) —la definición por autonomía— y
> [`02`](02-descomposicion-y-fronteras.md) —los cortes que no son criterio—. Los mecanismos de
> resiliencia que aquí solo se nombran son de
> [`04-operacion-y-resiliencia/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).
> El diagnóstico a fondo —evidencia, cadenas síncronas, base compartida, cómo se desmonta— tiene bloque
> propio en [`arquitectura/02-monolito/04`](../../02-monolito/04-monolito-distribuido/); aquí va lo que se
> reconoce y se dice en una entrevista.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Llevas dos años partiendo el monolito. Hay quince servicios, cada uno con su repositorio, su imagen y
su despliegue. Y sin embargo:

```text
Un cambio pequeño            →  tres pull requests en tres repositorios
El despliegue                →  los quince, en orden, un jueves por la noche
Un servicio caído            →  la pantalla principal deja de cargar
Probar el servicio de pedidos →  levantar otros cuatro, o nada
```

Eso es un **monolito distribuido**: tienes todos los costes de la separación —red, sagas, trazas,
quince pipelines— y ninguno de sus beneficios. Es peor que el monolito del que venías, y esa frase
hay que poder decirla sin adornos, porque es exactamente lo que el entrevistador quiere oír cuando te
pregunta por los riesgos.

Lo importante: casi nunca se llega aquí por una mala decisión grande. Se llega por cinco decisiones
pequeñas y razonables, tomadas un jueves por la tarde, cada una con su justificación. Este capítulo
es el catálogo de esas cinco.

---

## 2. 🩺 Cómo se reconoce en dos minutos

Cuatro preguntas. Cada "no" es un síntoma, y con dos "no" ya no hay discusión.

| Pregunta | Si la respuesta es "no"… |
|---|---|
| ¿Puedes desplegar un servicio solo? | El acoplamiento es de contrato, de datos o de artefacto |
| ¿Puedes probar uno solo? | Sus dependencias están en caliente, no simuladas |
| ¿Un cambio de negocio toca un repositorio? | La frontera no coincide con la razón de cambio |
| ¿Puedes apagar un servicio secundario sin tumbar la pantalla? | Falta aislamiento: ni timeouts ni degradación |

Y la prueba definitiva, que además es una buena pregunta para hacerle tú al entrevistador cuando te
describan su sistema:

> **🧠 Modelo mental:** ¿cuántos despliegues hacen falta para poner en producción el cambio más
> pequeño posible? Si la respuesta es "más de uno", tienes un monolito distribuido, independientemente
> de cuántos servicios haya.

---

## 3. 🪦 La base de datos compartida

**Qué es.** Dos o más servicios leen o escriben el mismo almacén. Es el antipatrón número uno porque
es el más cómodo: la tabla ya está ahí, la consulta ya funciona, y añadirla cuesta cinco minutos.

**Cómo se ve.**

```text
orders ───┐
          ├──► misma base de datos ◄── reports (solo lectura, "no molesta")
inventory─┘
```

Y su consecuencia, que llega meses después: `orders` quiere renombrar una columna. Ahora es una
negociación con dos equipos, tres despliegues coordinados y una ventana. A partir del segundo
episodio, nadie renombra nada y el esquema se congela.

**Por qué parece correcta.** Porque "solo lectura" suena inocuo, y porque duplicar datos parece peor
que compartirlos. El error está en confundir el dato con **su forma física**: el lector no depende de
la información, depende de tus tablas.

**La corrección.** Una API, un evento o —si de verdad hace falta acceso directo— una réplica con un
contrato explícito: una vista estable con nombre propio, versionada, que tú puedas mantener aunque
cambien las tablas de debajo. Y con fecha de revisión.

> **Veredicto:** dos servicios que comparten tablas son un servicio con dos procesos y más latencia.
> La variante "solo lectura" no es una excepción: es la misma dependencia, con menos ruido.

---

## 4. 🪦 La librería común de dominio

**Qué es.** Un artefacto compartido —`common`, `core`, `shared`— con los modelos y las reglas que
usan todos. Empieza con dos clases y acaba siendo el sitio donde vive el dominio entero.

**Cómo se ve.** El síntoma es de despliegue: subes la versión de la librería y **todos** los
servicios tienen que recompilar y desplegar para no quedarse atrás. Lo que era una dependencia de
código se convirtió en una dependencia de calendario.

**Por qué parece correcta.** Porque repetir la clase `Customer` en cuatro servicios parece una
duplicación evidente y fea, y todo el mundo aprende que la duplicación es mala.

**Dónde está la línea.** No toda librería compartida es veneno. La línea es **qué contiene**:

| Compartir esto | Veredicto |
|---|---|
| Utilidades técnicas: logging, métricas, cliente HTTP configurado | ✅ Bien, es el chassis ([`05`](05-el-servicio-por-dentro.md)) |
| Cliente generado a partir del contrato de otro servicio | ✅ Bien, si lo publica el dueño del contrato y está versionado |
| Modelos de dominio y sus reglas | ❌ Ahí empieza el acoplamiento de despliegue |
| Acceso a datos compartido: entidades, repositorios | ❌ Es la base de datos compartida con otra cara |

**La corrección.** Cada servicio tiene su propio modelo del concepto, aunque las clases se parezcan
las primeras semanas. Se parecen hoy; dejarán de parecerse en cuanto cada contexto evolucione, y ese
es justamente el motivo por el que están separados.

> **Veredicto:** si subir una versión de la librería obliga a desplegar a todos, la librería es el
> monolito y los servicios son su decoración.

---

## 5. 🪦 La cadena síncrona larga

**Qué es.** Una petición del usuario que atraviesa cuatro o cinco servicios en cascada, cada uno
esperando al siguiente.

**Cómo se ve, con números.** Es el antipatrón que mejor se argumenta con aritmética, y por eso vale
la pena tener los números en la cabeza:

```text
Cadena de 5 servicios, cada uno con 99,9 % de disponibilidad y 50 ms de latencia

Disponibilidad compuesta   0,999^5  ≈  99,5 %   → de 43 min de caída al mes a 3,6 h
Latencia acumulada         5 × 50 ms =  250 ms  → y eso en el camino feliz
Un timeout de 2 s en cada salto  →  hasta 10 s antes de responder al usuario
```

La segunda fila es la que sorprende: la latencia se suma, no se solapa, porque cada salto espera al
anterior. Y la tercera es la que produce incidentes: los timeouts encadenados sin presupuesto total
hacen que el usuario espere lo que suman todos.

**Por qué parece correcta.** Porque cada llamada individual tiene sentido: `orders` necesita el
cliente, `customers` necesita el segmento, `segments` necesita el histórico. Nadie diseñó la cadena;
creció.

**La corrección.** Tres salidas, de menor a mayor esfuerzo: **presupuesto de latencia** repartido
explícitamente por la cadena; **composición en paralelo** cuando las llamadas no dependen entre sí;
y **asincronía** —el efecto se publica como evento y la respuesta al usuario no espera—, que es la
única que rompe el acoplamiento de disponibilidad de verdad.

> **Veredicto:** cada salto síncrono multiplica probabilidades de fallo y suma latencia. Tres saltos
> ya son muchos; cinco es un incidente esperando fecha.

---

## 6. 🪦 Servicios anémicos y nano-servicios

**Qué es.** Servicios que solo hacen CRUD sobre una entidad —el corte por entidad de
[`02`](02-descomposicion-y-fronteras.md)— y servicios tan pequeños que el coste fijo de operarlos
supera lo que hacen.

**Cómo se ve.** El servicio anémico se reconoce porque **no toma ninguna decisión**: recibe, valida
el formato, guarda. Toda la regla de negocio está en quien lo llama, que acaba siendo un orquestador
gigante — el monolito, otra vez, pero ahora con red en medio y sin transacciones.

El nano-servicio se reconoce por la cuenta de §5 del capítulo [`01`](01-que-es-un-microservicio.md):
pipeline, tablero, alertas, guardia y actualizaciones de seguridad, todo eso para doscientas líneas.

**Por qué parece correcta.** Porque "responsabilidad única" se traduce mal: se lee como "hace una
cosa pequeña" en vez de "tiene una sola razón de cambio".

**La corrección.** Mover la regla al dueño del dato. Si `orders` decide cuándo un pedido es válido,
esa regla vive en `orders`, no en quien lo llama. Y fusionar lo que no se sostiene solo: juntar dos
servicios es barato y nadie se entera.

> **Veredicto:** un servicio que no toma decisiones no es un servicio, es una tabla con HTTP delante.

---

## 7. 🪦 El ESB rebautizado

**Qué es.** Lógica de negocio en el gateway: transformaciones que conocen el dominio, reglas de
enrutado por contenido, orquestación de flujos completos. El bus de servicios de 2008, con nombre
nuevo.

**Cómo se ve.** El síntoma es organizativo antes que técnico: para cambiar una regla de negocio hay
que pedírselo al equipo de plataforma, que tiene su propia cola de trabajo. El cuello de botella deja
de ser el código y pasa a ser una agenda.

**Por qué parece correcta.** Porque el gateway ya está en el camino de todas las peticiones, y poner
ahí la validación común "evita repetirla". Suena a no repetirse; es centralizar el dominio.

**La corrección.** En el borde solo lo que es del borde: TLS, autenticación, límite de tasa,
enrutado por ruta, observabilidad. Todo lo que necesite conocer el significado del mensaje va en el
servicio dueño ([`04/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)).

> **Veredicto:** si para cambiar una regla de negocio hay que tocar el gateway, el gateway es tu
> monolito y tiene un equipo entero de cuello de botella.

---

## 8. 🧰 Las señales de alarma, por ecosistema

El mismo antipatrón se disfraza distinto según la plataforma. Esta tabla es para reconocerlo en un
repositorio ajeno en los primeros diez minutos.

| Plataforma | La señal que delata acoplamiento | Lo que hay que mirar |
|---|---|---|
| **Java** | Un `pom`/`build` padre compartido y un módulo `common` con entidades JPA dentro | ¿Ese módulo tiene anotaciones de persistencia o reglas de negocio? Si sí, es base de datos compartida en forma de artefacto |
| **Node/TS** | Un paquete `@empresa/common` en el registro privado, o un `packages/shared` en el monorepo | ¿Exporta tipos e interfaces, o también lógica y acceso a datos? Los tipos generados del contrato son sanos; la lógica no |
| **Go** | Un módulo interno importado por todos, o un `internal/` compartido entre servicios | Aquí el riesgo es menor por cultura —se prefiere copiar—, pero cuando aparece suele traer también el cliente de base de datos |
| **Python** | Un paquete privado con los modelos de SQLAlchemy o los esquemas de Pydantic de todos | Modelos de datos compartidos son la base de datos compartida; esquemas de validación generados del contrato, no |

- **Lo que te deja a ti en las cuatro:** distinguir **contrato** de **dominio**. Compartir el cliente
  generado del contrato de otro servicio es sano: lo publica su dueño y está versionado. Compartir
  las clases con las que ese servicio piensa, no.
- La regla que funciona en las cuatro: *¿quién despliega cuando esto cambia?* Si la respuesta es
  "todos", da igual el lenguaje, tienes un monolito distribuido.

---

## 9. 🩺 Autopsia: la cadena que se cayó un martes

**El síntoma.** A las 10:14 la pantalla de pedidos empieza a tardar. A las 10:19 devuelve errores. El
tablero de `orders` muestra CPU normal, memoria normal, y el número de hilos ocupados al máximo.
`payments`, tres saltos más allá, tiene una consulta lenta por un índice que se perdió en un despliegue.

**La cadena.**

```text
 usuario ──► orders ──► customers ──► segments ──► payments ──► (base de datos lenta)
                │           │             │            │
           hilos ocupados   │             │       responde a 8 s
           esperando ───────┴─────────────┴────────────┘
```

Cada servicio tenía su timeout por defecto —ninguno pensado, todos heredados del cliente HTTP—, así
que nadie cortó. Los hilos de `orders` se quedaron esperando una respuesta que llegaba a los ocho
segundos, se agotó el pool, y a partir de ahí `orders` dejó de atender **todo**, incluidas las rutas
que no tocaban `payments`.

**La causa.** No fue la consulta lenta: eso fue el detonante. La causa fue que **una dependencia
lenta de tercer nivel podía consumir todos los hilos del primero**, y que ninguna ruta tenía
aislamiento.

**La corrección.** Por orden de efecto y esfuerzo: timeouts explícitos y menores según se baja en la
cadena; pools separados por dependencia; circuit breaker en `orders` hacia sus dependencias; y, a
medio plazo, sacar de la ruta síncrona lo que no necesita respuesta inmediata. Todo eso es
[`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).

**La generalización.** Es el fallo por agotamiento de recursos: lo que se propaga no es el error, es
**la lentitud**. Y se propaga hacia arriba, no hacia abajo — por eso el que se cae no es el que
falla.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Compartimos la base de datos solo para lecturas" | El lector depende de la forma física de tus tablas. Tu migración sigue siendo su problema |
| "Tenemos una librería común para no repetir código" | Si subir su versión obliga a desplegar a todos, la librería es el monolito |
| "Los servicios se llaman entre sí, es normal" | Normal es que hablen poco. Cinco saltos síncronos multiplican el fallo y suman la latencia |
| "Cada uno tiene su repositorio, luego son independientes" | La independencia es de despliegue y de datos. El repositorio no la da ni la quita |
| "Es responsabilidad única: un servicio por entidad" | Responsabilidad única es una **razón de cambio**, no una tabla. Eso produce CRUD anémico y un orquestador gordo |
| "Ponemos la validación común en el gateway" | Si necesita conocer el dominio, no es del borde. Acabas con un equipo de plataforma como cuello de botella |
| "El servicio caído era secundario, no debería haber afectado" | Sin timeout ni aislamiento, un dependiente lento agota los hilos del que llama y tumba también lo que no dependía de él |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4,
   "Microservice Communication Styles", y el tratamiento del acoplamiento de implementación y de
   despliegue. **El vocabulario de este capítulo sale de ahí.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 2, sobre los
   obstáculos de la descomposición, y capítulo 3, sobre comunicación.
3. **Fuente primaria** — Chris Richardson, «Pattern: Shared database», con sus fuerzas y sus
   consecuencias declaradas:
   [microservices.io/patterns/data/shared-database.html](https://microservices.io/patterns/data/shared-database.html).
4. **Fuente primaria** — Martin Fowler, «Microservice Trade-Offs», que es el catálogo honesto de lo
   que se paga:
   [martinfowler.com/articles/microservice-trade-offs.html](https://martinfowler.com/articles/microservice-trade-offs.html).
5. **Fuente primaria** — Martin Fowler, «MicroservicePrerequisites», lo que hay que tener antes de
   separar:
   [martinfowler.com/bliki/MicroservicePrerequisites.html](https://martinfowler.com/bliki/MicroservicePrerequisites.html).
6. **Material de referencia** — Amazon Builders' Library, «Timeouts, retries, and backoff with
   jitter», la base aritmética de §5 y §9:
   [builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter](https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter).
7. **Charla** — GOTO Conferences, «Don't Build a Distributed Monolith». El título lo dice todo y los
   ejemplos son reconocibles.

---

## 🧠 Preguntas

1. ¿Qué es un monolito distribuido? 🟢
2. Enumera las cuatro preguntas que lo detectan. 🟢
3. ¿Por qué compartir base de datos rompe el despliegue independiente? 🟢
4. ¿Qué diferencia hay entre compartir un cliente generado y compartir un modelo de dominio? 🟢
5. ¿Qué es un servicio anémico? 🟢
6. ¿Qué va en el gateway y qué no? 🟢
7. Un módulo `common` con entidades JPA dentro: ¿qué antipatrón es en realidad? 🟢
8. Calcula la disponibilidad compuesta de una cadena de cinco servicios al 99,9 % y di qué significa
   en minutos al mes. 🟡
9. ¿Por qué la latencia de una cadena síncrona se suma en vez de solaparse? 🟡
10. "Solo lectura no acopla": desmóntalo en dos frases. 🟡
11. ¿En qué se parecen el corte por entidad y el servicio anémico? 🟡
12. ¿Por qué el fallo se propaga hacia arriba en la cadena y no hacia abajo? 🟡
13. ¿Cómo distingues una librería compartida sana de una tóxica, sin abrir el código? 🟡
14. Te dan acceso a un repositorio ajeno y diez minutos. ¿Qué miras para saber si hay monolito
    distribuido? 🟡
15. ¿Por qué el paquete compartido tóxico aparece con más facilidad en Java y Python que en Go, y
    qué lo explica en cada caso 🟡
16. Tienes quince servicios y un único pipeline que los despliega en orden. ¿Por dónde empiezas a
    desacoplar? 🟠
17. Una pantalla necesita datos de cuatro servicios. Da dos diseños que eviten la cadena síncrona y
    di qué cuesta cada uno. 🟠
18. El equipo de plataforma tiene tres meses de cola porque todas las reglas están en el gateway.
    ¿Qué propones y en qué orden? 🟠
19. ¿Cuándo fusionarías dos servicios, y cómo lo justificas ante quien los creó? 🟠
20. Un servicio secundario se cae y tumba la pantalla principal. Da tres correcciones ordenadas por
    relación entre efecto y esfuerzo. 🟠
21. ¿Cómo repartirías un presupuesto de latencia de 800 ms entre una cadena de tres saltos? 🟠
22. Diagnostica: p99 de `orders` sube a 8 s, CPU normal, hilos al máximo, y `payments` tiene una
    consulta lenta. Explica la cadena y di dónde la cortarías. 🔴
23. Diseña el plan de seis meses para convertir quince servicios que se despliegan juntos en algo
    que se despliega por separado. 🔴
24. Escribe el conjunto de reglas de revisión de código que evitaría los cinco antipatrones del
    capítulo, y di cuál de ellas es automatizable. 🔴
25. Un equipo defiende su librería `common` con el argumento de no duplicar la clase `Customer`.
    Responde en dos minutos, concediendo lo que tiene de razón. 🔴

---

**Anterior:** [`03` — El camino desde el monolito](03-el-camino-desde-el-monolito.md) ·
**Siguiente:** [`05` — El servicio por dentro](05-el-servicio-por-dentro.md) · **Relacionado:**
[`02` — Descomposición y fronteras](02-descomposicion-y-fronteras.md) ·
[`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/)

**Taller, opcional:** [`06/02` — Strangler fig con Envoy](../06-talleres/02-strangler-fig-con-envoy.md).
