# 03 — El camino desde el monolito

> Cómo se sale de un monolito por fases, sin parar el negocio: strangler fig, branch by abstraction,
> capa anticorrupción, y el orden en que se extraen las cosas. Asume leído
> [`02`](02-descomposicion-y-fronteras.md), porque antes de extraer hay que saber por dónde cortar.
> La mecánica fina de las migraciones de esquema es de
> [`03-datos-y-consistencia/05`](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md); aquí va la estrategia.
> Si la pregunta es si extraer o modularizar dentro, está en
> [`arquitectura/02-monolito/05/04` — Extraer un módulo a servicio](../../02-monolito/05-decision-evolucion-y-practica/04-extraer-un-modulo-a-servicio.md),
> que mide qué autonomía compra la extracción; aquí se asume decidida.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

El monolito funciona, factura y tiene diez años. Nadie te va a autorizar a pararlo tres meses, y la
reescritura completa —la que empieza con "esta vez lo hacemos bien"— tiene un historial público de
fracasos: mientras reescribes, el sistema viejo sigue cambiando, y llega un momento en que el nuevo
persigue a un blanco móvil que nunca alcanza.

Así que la pregunta real no es "¿monolito o microservicios?", es:

```text
¿Cómo llego de aquí a allá, en trozos, con el negocio funcionando cada día,
 y pudiendo parar en cualquier momento sin que el sistema quede a medias?
```

Esa última parte es la que define una buena estrategia de migración: **cada paso tiene que dejar el
sistema entero y desplegable**. Si tu plan tiene una fase de "y aquí cambiamos todo a la vez", no es
un plan de migración, es una reescritura con pasos intermedios.

---

## 2. 🧱 Strangler fig

**Qué es.** Poner una fachada delante del monolito y desviar, ruta a ruta, el tráfico hacia servicios
nuevos. El monolito va quedando vacío por dentro hasta que se apaga. El nombre viene de la higuera
estranguladora, que crece alrededor de su árbol y acaba sosteniéndose sola cuando el original muere.

**Cómo va.** Tres piezas y tres fases:

```text
Fase 1        cliente ──► fachada ──► monolito (todo)
Fase 2        cliente ──► fachada ──┬─► servicio-nuevo   (/orders/*)
                                    └─► monolito         (el resto)
Fase 3        cliente ──► fachada ──► servicios          (el monolito se apaga)
```

- La **fachada** puede ser el API gateway, un proxy inverso o una capa dentro del propio monolito.
  Lo importante es que el cliente no se entera de nada: la URL no cambia.
- El **desvío** se hace por ruta, y a veces por porcentaje de tráfico dentro de la ruta, que permite
  probar el servicio nuevo con un 1 % antes de darle todo.
- La **vuelta atrás** es cambiar el desvío. Eso es lo que hace que el paso sea seguro y por eso es la
  propiedad más valiosa de todo el patrón.

**Con qué.** El desvío vive en el borde y no en el lenguaje: se configura en el gateway o en el proxy
—las opciones concretas están en [`04/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)—. La fachada dentro de la
aplicación existe en las cuatro plataformas como un filtro o middleware, y se usa cuando todavía no
hay gateway.

**Cuánto.** Cuesta mantener dos caminos vivos durante meses: doble despliegue, doble monitorización,
y la disciplina de no añadir funcionalidad nueva al lado viejo. Y cuesta más tiempo del que se
promete: las migraciones de este tipo se miden en trimestres.

**Cuándo sí.** Casi siempre que la funcionalidad se pueda separar por ruta o por punto de entrada:
API, pantallas, procesos por lotes.

**Cuándo no.** Cuando lo que quieres migrar no tiene punto de entrada propio —está en medio de una
transacción, lo llama otro módulo por dentro—. Para eso está §3.

> **Veredicto:** el strangler fig es el patrón por defecto porque cada paso es reversible cambiando
> una ruta. Si tu migración no se puede deshacer en un minuto, no estás haciendo strangler fig.

---

## 3. 🧱 Branch by abstraction

**Qué es.** Cuando no hay ruta que desviar porque la funcionalidad está enterrada, se crea primero una
**abstracción** dentro del monolito, se hace pasar a todo el mundo por ella, y luego se cambia la
implementación que hay detrás.

**Cómo va.** Cuatro pasos, y el tercero es el que da la seguridad:

```text
1. Crear la abstracción:  interfaz CalculadoraDeImpuestos
2. Hacer que todos la usen: implementación vieja detrás, sin cambiar comportamiento
3. Implementación nueva en paralelo: llama al servicio nuevo, detrás de un flag
4. Cambiar el flag, medir, y borrar la vieja cuando lleve semanas estable
```

El paso 3 admite una variante muy útil en banca: **ejecutar las dos y comparar** —la vieja manda, la
nueva solo registra diferencias—. Así descubres los casos borde con tráfico real y sin riesgo, que es
la única forma honesta de saber si la implementación nueva hace lo mismo que diez años de parches.

**Con qué.** La abstracción es una interfaz en Java, un tipo en TypeScript, una interfaz en Go o un
protocolo en Python; el interruptor es un feature flag, que en las cuatro plataformas empieza siendo
una propiedad de configuración y solo después una herramienta dedicada
([`04/06`](../04-operacion-y-resiliencia/06-despliegue-y-entrega.md)).

**Cuánto.** Cuesta una capa de indirección que sobrevive al cambio si nadie la borra, y la disciplina
de mantener dos implementaciones a la vez. La comparación en paralelo, además, dobla el coste de
ejecución de esa operación mientras dure.

**Cuándo sí.** Cuando la funcionalidad está en medio del código y no tiene entrada propia, y cuando
necesitas comparar comportamiento antes de confiar.

**Cuándo no.** Para algo que ya tiene su ruta: ahí el strangler fig es más simple y más reversible.

> **Veredicto:** branch by abstraction es el strangler fig de lo que no tiene puerta. Su verdadero
> producto no es la extracción: es poder comparar lo nuevo contra lo viejo con tráfico real.

---

## 4. 🧱 La capa anticorrupción

**Qué es.** Una capa de traducción entre tu servicio nuevo y el sistema viejo, para que el modelo del
legado no se filtre al modelo nuevo. Todo lo que cruza se traduce: nombres, formatos, códigos de
estado, errores.

**Cómo va.** Sin ella, el modelo nuevo acaba con campos llamados `IND_EST_PED` porque así se llaman
en el core, y con reglas que solo se entienden leyendo un copybook de 1998. Con ella, esa fealdad
queda encerrada en un sitio:

```text
servicio nuevo  ──►  ACL  ──►  core bancario
  Order                         estructura fija de 512 bytes, campos COBOL
  OrderId                       número de cuenta + sufijo
  CONFIRMED                     IND_EST = '3'
```

La regla práctica: **la traducción va en un solo sitio y se prueba sola**. Si aparece una tabla de
mapeo repetida en dos servicios, la capa ha fallado.

**Con qué.** Es un adaptador ordinario en cualquiera de las cuatro plataformas, y no necesita
librería; lo que sí necesita es su propia batería de pruebas de traducción. En banca suele tener
delante un cliente de MQ o un servicio SOAP, y su detalle vive en
[`arquitectura/01-bases/05-banca/04`](../../01-bases/05-banca/04-capa-anticorrupcion.md),
que es el dueño del tema.

**Cuánto.** Cuesta mapeo, que es código aburrido y que hay que mantener; y cuesta una latencia extra
pequeña. A cambio evita el coste mayor: que el modelo viejo colonice el nuevo y la migración pierda
su sentido.

**Cuándo sí.** Siempre que el sistema del otro lado tenga un modelo que no quieres heredar — legado,
proveedor externo, core que no se toca.

**Cuándo no.** Entre dos servicios nuevos que compartan lenguaje de dominio: ahí la capa es ceremonia
y basta con el contrato.

> **Veredicto:** la capa anticorrupción es el precio de no heredar el pasado. Si te la saltas "por
> ahora", el modelo del legado llega a tu dominio en la primera semana y ya no se va.

---

## 5. 🧭 Qué se extrae primero

La intuición dice "empieza por lo que más duele". Es mala consejera: lo que más duele suele ser lo
más acoplado, y fracasar en el primer intento mata la iniciativa entera.

El orden que funciona:

```text
1. Algo con frontera clara y datos propios, aunque sea poco importante.
   Objetivo real: construir el camino —pipeline, despliegue, observabilidad, fachada—.

2. Algo con perfil de carga distinto.
   Ahora sí se cobra un beneficio visible: escalar solo esa parte.

3. Algo con requisitos propios de cumplimiento o de disponibilidad.
   El beneficio es de alcance: aislar lo que tiene reglas caras.

4. Lo doloroso y acoplado.
   Al final, con el camino ya construido y con el equipo con práctica.
```

El primero es una inversión en infraestructura disfrazada de extracción: cuando termine, tendrás
plantilla de servicio, pipeline, tablero y rutina de despliegue. El segundo es el que enseñas a
negocio para justificar los siguientes.

> **💡 Truco:** cuando en una entrevista te pidan el plan de migración, di explícitamente que el
> primer servicio se elige **por lo fácil que es, no por lo importante que sea**, y explica que su
> objetivo es construir el camino. Es la respuesta de alguien que ha hecho una migración y no solo
> ha leído sobre ellas.

---

## 6. 🧱 Los datos, que son la parte difícil

**Qué es.** Extraer el código es la mitad visible; la que decide el resultado es separar el esquema.
Mientras el servicio nuevo lea las tablas del monolito, no es un servicio: es un proceso más
conectado a la misma base.

**Cómo va.** El orden recomendado es **separar los datos dentro del monolito antes de sacar el
proceso fuera**:

```text
1. Mismo desplegable, tablas separadas por módulo. Se prohíben los JOIN entre módulos
   y se sustituyen por llamadas a la API interna. Aquí duele, y duele barato.
2. Mismo desplegable, esquemas o bases separadas.
3. Ahora sí: proceso aparte con su base de datos.
```

Hacerlo al revés —sacar el proceso y dejar los datos compartidos "por ahora"— es cómo nacen los
monolitos distribuidos de [`04`](04-el-monolito-distribuido.md). El "por ahora" dura años porque, una
vez separado el proceso, separar los datos exige coordinar dos despliegues y nadie encuentra el
momento.

**Con qué.** El movimiento de datos tiene tres formas habituales y las tres son agnósticas de
plataforma: copia con corte de servicio en una ventana, doble escritura temporal con verificación, o
réplica por captura de cambios. La mecánica de cada una y el expand/contract están en
[`03/05`](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md).

**Cuánto.** La fase 1 cuesta rendimiento: donde había un `JOIN` hay dos consultas. Es incómodo y es
deliberado, porque te enseña el coste real de la frontera **antes** de que ese coste sea una llamada
de red que no puedes deshacer.

**Cuándo sí.** Siempre que puedas permitirte el orden completo.

**Cuándo no.** Cuando la ventana de negocio obliga a mover proceso y datos a la vez. Entonces se
acepta, se escribe el riesgo y se prepara la vuelta atrás con datos, que es la parte que casi nadie
ensaya.

> **Veredicto:** si separas el proceso antes que los datos, tendrás un servicio que no puede
> desplegarse solo y una deuda con fecha indefinida. Los datos primero, aunque duela más al
> principio.

---

## 7. 🧰 En las cuatro plataformas

Esta es la tabla más corta del corpus, y su brevedad es el contenido: **la migración casi no depende
de la plataforma**. Lo único que cambia es dónde vive la fachada mientras todavía no hay gateway, y
cómo se implementa el interruptor de branch by abstraction.

| Plataforma | La fachada dentro de la aplicación | El interruptor |
|---|---|---|
| **Java** | Un filtro de servlet o un controlador que reenvía; con Spring, además, el desvío declarativo del gateway cuando ya existe | Propiedad de configuración recargable, y después una herramienta de flags |
| **Node/TS** | Un middleware de Express o Fastify; en NestJS, un interceptor o un guard | Variable de entorno o flag, con recarga sin reinicio si el proveedor lo permite |
| **Go** | Un `http.Handler` que envuelve al viejo; el proxy inverso está en la librería estándar | Una variable comprobada en el handler; sin magia, y se ve en el código |
| **Python** | Middleware ASGI o WSGI según el marco | Configuración leída por petición, cuidando no cachearla en el proceso |

- **Lo que te deja a ti en las cuatro:** decidir qué pasa con las peticiones en vuelo cuando cambias
  el desvío, y asegurarte de que el flag se lee **por petición** y no una vez al arrancar — si se lee
  al arrancar, la vuelta atrás exige un despliegue, que es justo lo que el patrón intentaba evitar.
- Cuando existe gateway, el desvío se va allí en las cuatro por igual y esta tabla deja de importar:
  es el caso normal a partir del tercer servicio ([`04/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)).

---

## 8. 🩺 Cómo sabes que la fase funcionó

Una fase no termina cuando el código está desplegado, sino cuando puedes demostrar tres cosas.
Conviene tenerlas medidas antes de empezar la siguiente:

| Qué mides | Cómo | Qué significa si va mal |
|---|---|---|
| **Independencia** | ¿Desplegaste el servicio sin desplegar el monolito? | Si no, la extracción no terminó |
| **Paridad funcional** | Errores y resultados comparados contra el camino viejo | Hay casos borde sin migrar |
| **Latencia y errores** | p99 y tasa de error antes y después, en la misma ruta | La frontera está en mal sitio o falta ajustar timeouts |

Y la cuarta, la que nadie escribe: **¿sigue existiendo el camino viejo?** Mientras exista, no has
terminado, estás manteniendo dos sistemas. Retirar el código muerto es parte de la fase, y conviene
ponerle fecha en el mismo momento en que se desvía el tráfico.

La vuelta atrás merece su propia frase. Se puede deshacer un desvío de tráfico en un minuto; no se
puede deshacer un mes de escrituras que solo existen en la base nueva. **El punto de no retorno es
cuando el dato nuevo deja de llegar al sistema viejo**, y ese momento se decide explícitamente, se
anuncia y se anota.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Primero partimos la base de datos" | Primero se separan las tablas **dentro** del monolito. Partir la base sin haber separado el acceso es cómo nacen los datos compartidos entre procesos |
| "Reescribimos en paralelo y cambiamos de golpe" | El monolito sigue cambiando mientras reescribes. Sin fases reversibles, persigues un blanco móvil |
| "Empezamos por el módulo más problemático" | El más problemático es el más acoplado. Se empieza por uno fácil, para construir el camino |
| "El strangler fig termina en seis meses" | Se mide en trimestres y a veces en años. Prometer seis meses es cómo se cancelan estas migraciones |
| "Sacamos el servicio y luego separamos los datos" | Ese "luego" no llega: una vez fuera, separar datos exige coordinar dos despliegues |
| "La capa anticorrupción la añadimos si hace falta" | Cuando haga falta, el modelo del legado ya estará dentro de tu dominio |
| "Con el código migrado, la fase terminó" | Termina cuando el camino viejo está retirado y has medido independencia, paridad y latencia |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Monolith to Microservices*, O'Reilly, 2019. Capítulos 3 y 4: los patrones
   de migración de código y de datos, con sus contraindicaciones. **Si solo lees uno para este
   capítulo, es este.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 3, "Splitting
   the Monolith".
3. **Fuente primaria** — Martin Fowler, «StranglerFigApplication»:
   [martinfowler.com/bliki/StranglerFigApplication.html](https://martinfowler.com/bliki/StranglerFigApplication.html).
4. **Fuente primaria** — Martin Fowler, «BranchByAbstraction», con los cuatro pasos y el flag:
   [martinfowler.com/bliki/BranchByAbstraction.html](https://martinfowler.com/bliki/BranchByAbstraction.html).
5. **Fuente primaria** — Martin Fowler, «ParallelChange» (expand/contract), la base de la migración
   de datos de §6:
   [martinfowler.com/bliki/ParallelChange.html](https://martinfowler.com/bliki/ParallelChange.html).
6. **Fuente primaria** — Chris Richardson, «Strangler application»:
   [microservices.io/patterns/refactoring/strangler-application.html](https://microservices.io/patterns/refactoring/strangler-application.html).
7. **Material de referencia** — Martin Fowler, «How to break a Monolith into Microservices», con el
   orden de extracción:
   [martinfowler.com/articles/break-monolith-into-microservices.html](https://martinfowler.com/articles/break-monolith-into-microservices.html).
8. **Charla** — GOTO Conferences, «Monolith to Microservices» (Sam Newman). La parte de datos es la
   que más rinde.

---

## 🧠 Preguntas

1. ¿Qué es el patrón strangler fig y de dónde viene el nombre? 🟢
2. ¿Cuáles son los cuatro pasos de branch by abstraction? 🟢
3. ¿Para qué sirve una capa anticorrupción? 🟢
4. ¿Qué se extrae primero en una migración, y por qué ese criterio? 🟢
5. ¿En qué orden se separan datos y proceso? 🟢
6. Enumera las tres cosas que mides para dar una fase por terminada. 🟢
7. ¿Cuándo usarías branch by abstraction en vez de strangler fig? 🟡
8. ¿Por qué la reescritura completa fracasa aunque el equipo sea bueno? 🟡
9. Diferencia entre desviar por ruta y desviar por porcentaje de tráfico. 🟡
10. ¿Por qué prohibir los `JOIN` entre módulos dentro del monolito es un paso de la migración y no
    una molestia? 🟡
11. ¿Qué es el punto de no retorno de una migración y cómo se reconoce? 🟡
12. ¿Por qué la comparación en paralelo —las dos implementaciones a la vez— vale tanto en banca? 🟡
13. ¿Qué pones en la fachada y qué no pones nunca? 🟡
14. ¿Dónde vive la fachada del desvío en cada plataforma mientras no hay gateway, y qué te deja a ti
    en las cuatro? 🟡
15. Tu primer servicio extraído no puede desplegarse sin desplegar el monolito. ¿Qué pasó y cómo lo
    arreglas? 🟠
16. El negocio no autoriza ninguna ventana de parada y hay que mover 200 GB de datos. ¿Qué opciones
    tienes? 🟠
17. ¿Cómo justificas ante negocio empezar por un módulo poco importante? 🟠
18. Llevas ocho meses de migración y el monolito ha crecido en ese tiempo. ¿Qué falló en el proceso?
    🟠
19. Te piden mantener el camino viejo "por si acaso" durante un año. Argumenta. 🟠
20. ¿Cómo mides la paridad funcional entre el camino viejo y el nuevo sin tener pruebas del
    monolito? 🟠
21. El servicio nuevo tiene peor p99 que el monolito en la misma ruta. Da tres hipótesis en orden de
    probabilidad. 🟠
22. Diseña el plan de extracción de `payments` desde un monolito bancario, en fases, con lo que se
    despliega en cada una y cómo se vuelve atrás. 🔴
23. Tienes que extraer un módulo cuya lógica está repartida en quince clases y tres procedimientos
    almacenados. Da la secuencia completa. 🔴
24. Escribe el criterio de aceptación de una fase de migración: qué se mide, con qué umbral, y qué
    decisión se toma con cada resultado. 🔴
25. El equipo propone reescribir el monolito entero en una plataforma nueva y migrar en un fin de
    semana. Da tu contraargumento y una alternativa concreta con fases. 🔴

---

**Anterior:** [`02` — Descomposición y fronteras](02-descomposicion-y-fronteras.md) ·
**Siguiente:** [`04` — El monolito distribuido](04-el-monolito-distribuido.md) · **Relacionado:**
[`03-datos-y-consistencia`](../03-datos-y-consistencia/) ·
[`arquitectura/01-bases/05-banca/04`](../../01-bases/05-banca/04-capa-anticorrupcion.md)

**Taller, opcional:** [`06/02` — Strangler fig con Envoy](../06-talleres/02-strangler-fig-con-envoy.md).
