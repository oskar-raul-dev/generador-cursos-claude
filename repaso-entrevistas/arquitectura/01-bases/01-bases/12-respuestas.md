# 12 — Respuestas

> Solucionario centralizado del bloque `01-bases`. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para recitar).
> Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--fundamentos-del-arquitecto) · [02](#02--estilos-de-despliegue) ·
[03](#03--arquitecturas-de-aplicación) · [04](#04--patrones-gof) ·
[05](#05--fowler-poeaa) · [06](#06--ddd-estratégico) · [07](#07--ddd-táctico) ·
[08](#08--comunicación-e-integración) · [09](#09--resiliencia) ·
[10](#10--alta-disponibilidad-y-escalado) · [11 — escenarios](#11--simulación-escenarios-de-diseño)

---

# 01 — Fundamentos del arquitecto

**01 → 1. Nombra cinco atributos de calidad y di contra qué pelea cada uno.**

⏱️ Disponibilidad contra consistencia, rendimiento contra consistencia, escalabilidad
contra simplicidad, mantenibilidad contra rendimiento, seguridad contra usabilidad.
🗣️ El punto es que no se suman: cada uno se compra con otro. Por eso la pregunta útil al
abrir un diseño es cuál de los dos en tensión importa más en ese problema concreto.
🔬 Otros: testabilidad contra velocidad inicial, observabilidad contra costo. La lista
completa está en la ISO 25010, pero recitarla no aporta; identificar la tensión sí.

**01 → 2. ¿Cuáles son los cuatro niveles del modelo C4 y cuál casi nunca se dibuja?**

⏱️ Contexto, Contenedor, Componente y Código. El de Código casi nunca se dibuja.
🗣️ Contexto sitúa tu sistema entre usuarios y sistemas externos; Contenedor muestra las
unidades desplegables y sus protocolos; Componente abre un contenedor. El de Código
queda obsoleto en días y el IDE lo genera mejor.
🔬 En entrevista el nivel que importa es Contenedor: es donde se ven servicios, bases de
datos y el acoplamiento temporal de cada flecha.

**01 → 3. ¿Qué secciones tiene un ADR en el formato de Nygard?**

⏱️ Título, Estado con fecha, Contexto, Decisión y Consecuencias. Muchos añaden
Alternativas consideradas.
🗣️ El Estado evoluciona: propuesto, aceptado, obsoleto, sustituido por ADR-N. Las
Consecuencias llevan signo: lo bueno y lo malo que acarrea.
🔬 El formato de Nygard aparece en *Release It!* y en su blog de 2011. Existen variantes
(MADR, Y-statements) pero en entrevista basta con el original.

**01 → 4. ¿Qué diferencia una decisión de arquitectura de una decisión de diseño?**

⏱️ El costo de revertirla. Arquitectura es lo caro de cambiar; diseño es lo que se
refactoriza en una tarde.
🗣️ Una decisión de arquitectura afecta a múltiples componentes, condiciona decisiones
posteriores y su reversión implica migración de datos, de contratos o de equipos. Elegir
Kafka es arquitectura; elegir si un método devuelve `Optional` es diseño.
🔬 Fowler lo formula como "las decisiones importantes, donde importante se mide por el
costo del cambio". La frontera se mueve con el tiempo: algo caro de revertir hoy puede
ser barato con mejores herramientas.

**01 → 5. ¿Por qué un ADR no se edita cuando la decisión cambia?**

⏱️ Porque es un registro histórico, no documentación viva. Se escribe uno nuevo que
marca al anterior como sustituido.
🗣️ El valor está en poder reconstruir por qué se decidió algo **con la información de
entonces**. Si lo editas, pierdes el contexto de la decisión original y la nueva parece
que siempre fue obvia.
🔬 Es la misma lógica que un log de eventos frente a un estado mutable: la secuencia de
decisiones tiene información que el estado final no conserva.

**01 → 6. ¿Qué es una fitness function y en qué se diferencia de un test unitario?**

⏱️ Una prueba automatizada que verifica un atributo de arquitectura, no una
funcionalidad.
🗣️ Un test unitario comprueba que un método hace lo que debe; una fitness function
comprueba que la estructura sigue siendo la que decidiste: que el dominio no importa
Spring, que no hay ciclos entre módulos, que el p99 no supera el presupuesto.
🔬 Vienen de *Building Evolutionary Architectures*. En Java se implementan con ArchUnit
para las estructurales y con pruebas de carga en el pipeline para las de rendimiento.

**01 → 7. Enuncia la ley de Conway y explica qué es la maniobra inversa.**

⏱️ Las organizaciones producen sistemas que copian su estructura de comunicación. La
maniobra inversa es reorganizar los equipos para obtener la arquitectura que quieres.
🗣️ No es una observación curiosa: es una restricción. Cuatro equipos producirán cuatro
módulos con interfaces en las fronteras del organigrama. Si quieres tres servicios,
necesitas tres equipos que los posean.
🔬 Conway, 1967. La consecuencia práctica: un monolito mantenido por seis equipos no se
parte con un refactor, se parte reasignando la propiedad del código.

**01 → 8. Un ADR sin sección de consecuencias negativas: ¿qué problema tiene?**

⏱️ Que no es una decisión, es una justificación. Toda decisión de arquitectura tiene un
precio; si no lo escribiste, no lo identificaste.
🗣️ Además pierde su función principal: cuando dentro de un año alguien sufra la
consecuencia, el ADR debería decirle que se conocía y se aceptó, no hacerle pensar que
fue un descuido.
🔬 Es el mismo vicio que una respuesta de entrevista sin trade-off.

**01 → 9. ¿En qué nivel de C4 aparecen las bases de datos y por qué no antes?**

⏱️ En el nivel 2, Contenedor. Antes no, porque el nivel 1 trata tu sistema como una sola
caja.
🗣️ Una base de datos es una unidad desplegable con la que tu aplicación habla por un
protocolo, así que es un contenedor. Meterla en el diagrama de contexto mezcla niveles de
abstracción y es el error más común al dibujar C4.
🔬 En el nivel de contexto solo aparecen personas y sistemas externos: cosas fuera de tu
frontera de propiedad.

**01 → 10. ¿Cuándo una decisión NO merece un ADR?**

⏱️ Cuando es barata de revertir y solo afecta a un componente. Si cabe en un comentario
del código, va en el código.
🗣️ El riesgo de documentar todo es que nadie lea nada. Un repositorio con doscientos ADR
tiene el mismo valor informativo que uno con cero.
🔬 El filtro práctico: ¿alguien va a preguntar "por qué hicimos esto" dentro de seis
meses, cuando quien lo decidió ya no esté? Si sí, ADR.

**01 → 11. ¿Qué significa que una decisión sea "reversible" y por qué cambia cómo la tomas?**

⏱️ Que puedes deshacerla barato. Si es reversible, decides rápido y aprendes; si no,
inviertes en analizarla.
🗣️ Es el marco de "puertas de una vía y de dos vías": las de dos vías se atraviesan
rápido porque puedes volver. El error frecuente es tratar todas las decisiones como
irreversibles y paralizar al equipo.
🔬 Qué hace irreversible a una decisión: migración de datos, contratos públicos con
consumidores externos, y estructura de equipos.

**01 → 12. ¿Por qué etiquetar las flechas de un diagrama con protocolo y sincronía?**

⏱️ Porque la flecha sin etiqueta esconde la decisión más importante: si hay acoplamiento
temporal.
🗣️ "REST síncrono" y "evento asíncrono" entre las mismas dos cajas son arquitecturas
distintas, con disponibilidad, consistencia y modos de fallo distintos. Sin la etiqueta,
el diagrama no dice nada verificable.
🔬 Es también un truco conversacional: etiquetar la flecha abre sola la conversación
sobre qué pasa cuando el destino no responde, que es terreno donde quieres estar.

**01 → 13. Te piden "alta disponibilidad y consistencia fuerte" a la vez. ¿Qué respondes?**

⏱️ Pregunto qué prefieren cuando haya una partición de red, porque ahí hay que elegir.
🗣️ Es el teorema CAP: bajo partición, o respondes con datos posiblemente desactualizados
o no respondes. Fuera de particiones puedes tener ambas, así que la pregunta útil es qué
datos concretos necesitan consistencia fuerte: casi nunca son todos.
🔬 PACELC lo completa: incluso sin partición, eliges entre latencia y consistencia. En
banca, el saldo disponible suele requerir consistencia fuerte y el historial de
movimientos no.

**01 → 14. ¿Qué tres fitness functions pondrías en un proyecto Spring Boot hexagonal?**

⏱️ Que el paquete de dominio no importe Spring ni JPA, que no haya ciclos entre módulos,
y un presupuesto de latencia en el endpoint crítico.
🗣️ Las dos primeras con ArchUnit en el pipeline de test, la tercera como prueba de carga
que falla el build. Añadiría una cuarta: que ninguna entidad JPA aparezca en la firma de
un controller.
🔬 El criterio para elegirlas: automatiza la regla que ya has visto romperse en revisión
de código más de una vez.

**01 → 15. ¿Por qué los atributos de calidad no se pueden añadir tarde en el proyecto?**

⏱️ Porque determinan la estructura. Añadirlos después no es configurar, es rediseñar.
🗣️ Hacer un sistema sin estado después de haber metido sesión en memoria por todas
partes, o hacerlo testeable después de acoplar dominio e infraestructura, cuesta más que
haberlo hecho al principio. La funcionalidad se añade; la estructura se sustituye.
🔬 Es el argumento de por qué la arquitectura se decide pronto aunque se decida poco: se
eligen las restricciones que dejan las opciones abiertas.

**01 → 16. ¿Qué responde un arquitecto que un desarrollador senior no responde?**

⏱️ El precio. El senior elige la mejor opción; el arquitecto dice qué pierde al
elegirla y cómo lo acota.
🗣️ Y añade dos cosas más: qué información le falta para decidir mejor, y cuánto cuesta
deshacer la decisión si se equivoca.
🔬 Es la diferencia entre optimizar dentro de un marco dado y elegir el marco.

**01 → 17. Un equipo viola la arquitectura en cada PR. ¿Qué haces, más allá de revisar?**

⏱️ Lo automatizo: si la regla importa, va al pipeline. Y antes averiguo por qué la
violan.
🗣️ Dos causas posibles y respuestas distintas. Si la regla no se entiende, el problema es
de comunicación y hace falta documentarla con el porqué, no solo con el qué. Si se
entiende y estorba, puede que la regla esté mal y haya que revisarla.
🔬 La revisión de código no escala como mecanismo de gobierno: depende de que el revisor
esté atento y no esté cansado. Una fitness function no se cansa.

**01 → 18. ¿Por qué "escalabilidad" es una respuesta incompleta sin "sin estado"?**

⏱️ Porque añadir instancias solo funciona si cualquier instancia puede atender cualquier
petición, y eso exige que el estado esté fuera.
🗣️ Si la sesión vive en memoria, escalar rompe la sesión; si hay ficheros en disco local,
escalar los pierde; si hay un `@Scheduled`, escalar lo ejecuta N veces.
🔬 Ver [`10` §3](10-alta-disponibilidad-y-escalado.md#3-️-estado-el-verdadero-obstáculo).

**01 → 19. Tienes 45 minutos y te dicen "diseña un acortador de URLs". ¿Cuáles son tus primeros tres movimientos, en orden?**

⏱️ Acotar requisitos con números, dibujar el nivel 1 de C4, y estimar la carga.
🗣️ Primero: cuántas URLs al día, ratio lectura/escritura, ¿los enlaces caducan?,
¿necesitan analítica?, ¿enlaces personalizados? Segundo: dibujo la caja y quién habla con
ella, para tener terreno común. Tercero: hago la cuenta —cien millones de lecturas al día
son ~1.200 por segundo, con picos de 5.000— porque el número decide todo lo demás.
🔬 Con esos números aparece solo el diseño: lectura masiva sobre escritura escasa lleva a
caché agresiva y CDN; el id corto lleva a la conversación de base 62 contra hash con
colisiones.

**01 → 20. Heredas un sistema sin documentación y sin nadie que lo conociera. ¿Cómo reconstruyes su arquitectura y en qué orden?**

⏱️ Desde fuera hacia dentro: primero las fronteras reales, luego el flujo de datos, y al
final el código.
🗣️ El orden que uso: configuración de despliegue y red para saber qué se despliega y qué
habla con qué; esquema de base de datos, que es la verdad más duradera; logs y trazas en
producción para ver los flujos que de verdad ocurren; y solo entonces el código, empezando
por los puntos de entrada. En paralelo, hablo con soporte y con negocio: saben qué se rompe.
🔬 El producto es un C4 de niveles 1 y 2 y una lista de riesgos. Documentar todo el código
es la trampa: nunca terminas y no sirve.

**01 → 21. ¿Cómo mides "mantenibilidad" de forma que entre en un pipeline?**

⏱️ Con métricas de acoplamiento y de cambio: ciclos entre módulos, número de archivos
tocados por cambio medio, y tiempo de ciclo de un PR.
🗣️ Las estructurales son directas: ArchUnit falla si hay ciclos; un límite de complejidad
ciclomática; cobertura en el dominio, no global. Las de proceso son mejores indicadores
pero no fallan un build: lead time y frecuencia de despliegue.
🔬 Las cuatro métricas DORA —frecuencia de despliegue, lead time, tasa de fallo del
cambio y tiempo de restauración— son la respuesta fuerte, porque miden el efecto de la
mantenibilidad en vez de una aproximación estática.

**01 → 22. Tu propuesta es técnicamente mejor pero el equipo la rechaza. ¿Qué haces?**

⏱️ Asumo que me falta información, no que ellos se equivocan. Pregunto qué problema ven
que yo no.
🗣️ Casi siempre hay una restricción real que no conocía: experiencia previa mala, una
dependencia con otro equipo, un plazo. Si tras entenderlo sigo pensando que tengo razón,
propongo una prueba acotada con criterio de éxito: un módulo, dos semanas, y una métrica
que decida. Si pierdo, la adopto sin resistencia.
🔬 Una arquitectura que el equipo no entiende ni quiere **no funciona**, aunque sea
correcta en el papel: la van a rodear. La adopción es parte del diseño.

**01 → 23. ¿Cómo justificas ante negocio una inversión que no añade funcionalidad?**

⏱️ Traduciéndola a dinero, riesgo o velocidad. Negocio no compra "deuda técnica", compra
"esto tarda tres semanas y podría tardar tres días".
🗣️ Uso lo que ya miden: incidentes del último trimestre y su costo, tiempo de salida al
mercado, horas de guardia. Y propongo el trabajo por trozos con resultado visible, no como
un proyecto de seis meses sin entregas.
🔬 El error clásico es pedir "un sprint de refactor". Lo que funciona es vincular la mejora
a una funcionalidad concreta que la necesita: se paga el refactor como parte del entregable.

---

# 02 — Estilos de despliegue

**02 → 1. ¿Qué compra de verdad separar un sistema en microservicios?**

⏱️ Despliegue independiente y autonomía de equipos. No rendimiento.
🗣️ Cada equipo despliega su servicio sin coordinarse, elige su ritmo y aísla sus fallos.
Lo paga con latencia de red, consistencia eventual, complejidad operativa y coste de
infraestructura.
🔬 Una llamada a método pasa de nanosegundos a milisegundos al convertirse en llamada de
red: cinco órdenes de magnitud. El throughput total normalmente baja.

**02 → 2. ¿Qué es un monolito modular y en qué se diferencia de un monolito a secas?**

⏱️ Un solo despliegue con fronteras internas reales: módulos con API pública explícita y
datos propios.
🗣️ En un monolito cualquiera cualquier clase llama a cualquier otra y cualquier consulta
hace `JOIN` con cualquier tabla. En uno modular, el módulo expone una API, oculta sus
clases internas y es dueño de sus tablas. Es microservicios sin la red.
🔬 Se hace cumplir con Spring Modulith, ArchUnit o módulos de build. Sin mecanismo, la
modularidad dura hasta el primer sprint con prisa.

**02 → 3. ¿Qué caracteriza a la service-based architecture?**

⏱️ Pocos servicios gruesos —de 4 a 12— desplegados por separado pero **compartiendo base
de datos**.
🗣️ Es el punto medio: consigues despliegue independiente sin pagar consistencia
distribuida, sagas ni outbox, porque la transacción sigue siendo una transacción de base
de datos.
🔬 Su modo de fallo es el esquema compartido como punto de acoplamiento: cambiar una tabla
requiere coordinar a todos los equipos.

**02 → 4. ¿Qué problema concreto ataca la arquitectura basada en espacio?**

⏱️ El cuello de botella de la base de datos central.
🗣️ En vez de que todas las instancias peguen contra una BD, trabajan sobre una rejilla de
datos en memoria replicada entre nodos, y la persistencia ocurre asíncrona detrás.
Escalar es añadir nodos.
🔬 Se usa en picos extremos e impredecibles con estado compartido: entradas, subastas,
trading. En Java: Hazelcast, Coherence, Gemfire.

**02 → 5. ¿En qué se parece un pipeline a la cadena de filtros de un servlet?**

⏱️ En que cada filtro hace una transformación y solo conoce su entrada y su salida.
🗣️ Un `Filter` recibe la petición, la modifica o la valida, y la pasa al siguiente sin
saber quién es. Puedes reordenar, añadir o quitar filtros sin tocar los demás: es
exactamente la propiedad del estilo pipeline.
🔬 Lo mismo en los interceptores de Spring, en los `Step` de Spring Batch y en un `Stream`
encadenado.

**02 → 6. ¿Qué es un monolito distribuido y por qué es el peor resultado posible?**

⏱️ Servicios separados físicamente pero acoplados: comparten base de datos o hay que
desplegarlos juntos.
🗣️ Tiene el acoplamiento del monolito más la latencia, el fallo parcial y la complejidad
operativa de lo distribuido. Pagas los dos precios y no cobras ninguno de los dos
beneficios.
🔬 Señales para reconocerlo: un cambio obliga a desplegar tres servicios a la vez; los
servicios comparten esquema; hay una librería común que contiene el modelo de dominio de
todos.

**02 → 7. Nombra tres diferencias entre SOA con ESB y microservicios.**

⏱️ Dónde vive la inteligencia, la propiedad de los datos y el gobierno.
🗣️ En SOA el bus es listo —enruta, transforma, orquesta— y los servicios tontos; en
microservicios es al revés: *smart endpoints, dumb pipes*. En SOA los datos son
compartidos con esquema canónico; en microservicios, por servicio. En SOA el gobierno es
centralizado; en microservicios, por equipo.
🔬 También la granularidad: SOA agrupa por capacidad empresarial y produce servicios
grandes; microservicios por contexto acotado y produce servicios pequeños.

**02 → 8. ¿Qué es el cold start y cómo se acota hoy en Java?**

⏱️ El tiempo extra de la primera invocación de una función tras un periodo inactivo,
porque hay que arrancar el runtime.
🗣️ En Java pesa más que en otros lenguajes por el arranque de la JVM y de Spring. Se acota
con SnapStart (restaura una instantánea ya inicializada), con imágenes nativas de GraalVM,
y con concurrencia provisionada, que es pagar por mantener instancias calientes.
🔬 Si citas el cold start como problema sin citar la mitigación, la pregunta de
seguimiento te alcanza. Y la concurrencia provisionada elimina buena parte de la ventaja
económica del serverless.

**02 → 9. Cita tres cosas de la factura operativa mínima de microservicios.**

⏱️ Trazas distribuidas con correlation ID, resiliencia (timeouts y circuit breakers) y
CI/CD por servicio.
🗣️ Y al menos dos más: gestión de datos distribuidos con saga u outbox, y contratos
versionados con compatibilidad verificada. Sin esto, separar produce un sistema menos
fiable que el monolito.
🔬 Por eso el primer microservicio cuesta la plataforma entera y el segundo es barato.

**02 → 10. ¿Qué significa "smart endpoints, dumb pipes"?**

⏱️ Que la lógica vive en los servicios y el canal solo transporta.
🗣️ Es la ruptura con SOA, donde el ESB enrutaba, transformaba y orquestaba. La razón:
concentrar lógica en el bus lo convierte en un punto único de fallo, en un cuello de
botella de despliegue y en propiedad de un equipo que bloquea a todos.
🔬 De Lewis y Fowler, en el artículo *Microservices* de 2014.

**02 → 11. ¿Cuándo elegirías microkernel y qué patrón GoF lo sustenta?**

⏱️ Cuando hay un núcleo estable y una variabilidad que crece sin parar. Lo sustenta
Strategy, más un registro de plug-ins.
🗣️ Motores de reglas, productos financieros configurables, procesadores de formatos. El
criterio: si añadir una variante nueva obliga a tocar y recompilar el núcleo, el
microkernel se paga; si la variabilidad son tres casos, no.
🔬 En Java lo tienes en `ServiceLoader` y en el sistema de plug-ins de Eclipse. Es
Strategy elevado a estilo arquitectónico.

**02 → 12. ¿Por qué "base de datos por servicio" es el criterio que define microservicios?**

⏱️ Porque sin él no hay independencia: si comparten esquema, comparten ciclo de cambio.
🗣️ Un servicio que no es dueño de sus datos no puede evolucionar su modelo ni desplegarse
sin coordinar. Todo lo demás —repositorio propio, pipeline propio, contenedor propio— es
cosmético si el esquema es compartido.
🔬 Es también lo que obliga a todo lo caro: saga, outbox, consistencia eventual. Por eso
es el criterio que decide si estás preparado para microservicios.

**02 → 13. ¿Por qué el primer microservicio cuesta mucho más que el segundo?**

⏱️ Porque el primero paga toda la plataforma: observabilidad, despliegue, resiliencia,
descubrimiento, contratos.
🗣️ El coste de separar no es lineal, es un escalón seguido de una pendiente suave. Eso
cambia la conversación: si vas a separar, la pregunta no es "¿este servicio lo justifica?"
sino "¿vamos a separar lo suficiente como para amortizar la plataforma?".
🔬 Es también el argumento honesto contra separar un solo módulo "para probar": el
experimento cuesta lo que cuesta la plataforma.

**02 → 14. Un equipo de 5 personas quiere empezar con 12 microservicios. ¿Qué les dices?**

⏱️ Que tendrán más servicios que desarrolladores y pagarán la factura operativa sin
recibir el beneficio, que es desbloquear equipos que no tienen.
🗣️ Con cinco personas nadie se bloquea: no hay problema organizativo que resolver. Y el
dominio todavía no se conoce, así que cortarán mal y tendrán que mover código entre
servicios, que es mucho más caro que moverlo entre paquetes. Propongo monolito modular con
las fronteras marcadas, y separar el primero cuando duela de verdad.
🔬 Si insisten, el compromiso razonable es dejar los módulos preparados —API explícita,
datos propios, sin `JOIN` cruzado— para que separar sea extraer, no rediseñar.

**02 → 15. ¿Qué tres preguntas haces antes de responder "monolito o microservicios"?**

⏱️ Cuántos equipos y si se bloquean, si el dominio está entendido, y si existe ya la
plataforma operativa.
🗣️ Añadiría una cuarta: si hay partes con perfiles de escalado radicalmente distintos. Y
una quinta que suele decidir: si el negocio puede tolerar consistencia eventual en los
flujos que cruzarían la frontera.
🔬 Ninguna de las cinco es técnica de implementación: son de organización, de dominio y de
negocio. Eso ya es la respuesta.

**02 → 16. ¿Cómo se hace cumplir la frontera de un módulo en un monolito modular?**

⏱️ Con verificación automática: Spring Modulith o ArchUnit en el pipeline.
🗣️ Spring Modulith define módulos por paquete, verifica en test que nadie accede a las
clases internas de otro y genera documentación. ArchUnit permite reglas a medida. La
opción estructural es separar módulos de build, de forma que el compilador lo impida.
🔬 Sin mecanismo automático la modularidad se degrada: basta una tarde con prisa y un
`import` que el revisor no vio.

**02 → 17. ¿Cuándo serverless sale más caro que un contenedor encendido?**

⏱️ Con carga sostenida y predecible. Pagar por invocación solo gana si hay valles.
🗣️ El punto de cruce depende del perfil: con tráfico constante durante muchas horas al
día, un contenedor pequeño siempre encendido sale más barato, y además evita el cold start
y el límite de conexiones a base de datos.
🔬 Y si acabas usando concurrencia provisionada para quitar el cold start, estás pagando
por instancias calientes: el modelo económico ya se parece al del contenedor.

**02 → 18. Un servicio no se puede desplegar sin desplegar otros dos. ¿Qué pasó?**

⏱️ Que la frontera está mal cortada: esos tres son un solo servicio repartido en tres
despliegues.
🗣️ Las causas habituales: comparten base de datos o esquema; comparten una librería con el
modelo de dominio y cualquier cambio la sincroniza; o los contratos entre ellos no son
compatibles hacia atrás, así que hay que subir todo a la vez.
🔬 La tercera tiene arreglo sin rediseño: compatibilidad de contrato y contract testing. Las
dos primeras son de diseño y llevan a fusionar o a redibujar la frontera.

**02 → 19. En banca heredas un ESB con 40 servicios SOAP. ¿Cómo lo modernizas sin detener el negocio?**

⏱️ Strangler Fig: una fachada delante, y voy moviendo capacidades una a una, midiendo,
sin tocar el ESB hasta el final.
🗣️ El orden: primero pongo un punto de entrada que pueda enrutar a lo viejo o a lo nuevo.
Luego elijo la primera capacidad por dos criterios —valor de negocio y bajo acoplamiento—
y la reimplemento detrás de una capa anticorrupción que traduce el modelo del ESB al mío.
Enruto un porcentaje del tráfico, comparo resultados en paralelo, y cuando cuadra, corto.
El ESB se apaga cuando no queda nadie detrás, no antes.
🔬 Lo que no hago: un "big bang", ni una reescritura en paralelo de dos años. Y mido el
avance con algo verificable: porcentaje de tráfico servido por lo nuevo, no porcentaje de
código migrado.

**02 → 20. El pipeline tarda 50 minutos y bloquea a 6 equipos. ¿Separas? Argumenta con números y di qué separas primero.**

⏱️ Primero intento arreglar el pipeline; separar por esa razón es la solución más cara
posible.
🗣️ Cincuenta minutos casi siempre se atacan antes con paralelización de tests, cacheo de
dependencias y tests de integración solo en lo que cambió. Si tras eso sigue bloqueando,
la métrica que uso es el tiempo de espera agregado: seis equipos, cuatro despliegues al día,
50 minutos de bloqueo son 20 horas-persona al día. Con ese número la separación se justifica
sola. Separo primero el módulo con más despliegues y menos acoplamiento con el resto.
🔬 Ojo con la trampa: si el pipeline es lento por tests de integración contra una BD
compartida, separar servicios no lo arregla, lo multiplica.

**02 → 21. Te piden justificar ante el CTO por qué NO vas a microservicios. ¿Qué dices?**

⏱️ Que el problema que resuelven es organizativo y no lo tenemos, y que la factura sí la
pagaríamos.
🗣️ Lo presento en sus términos: coste de la plataforma, tiempo hasta la primera entrega
retrasado por infraestructura, y riesgo de cortar mal un dominio que aún no entendemos. Y
ofrezco el camino: monolito modular con fronteras verificadas, que deja la separación
preparada. Fijamos el disparador por adelantado: cuando X equipos se bloqueen o Y módulo
necesite escalar distinto, separamos ese módulo.
🔬 Lo importante es no sonar conservador: no estoy diciendo "nunca", estoy diciendo "no
ahora, y este es el criterio objetivo por el que cambiaré de opinión".

**02 → 22. Diseña el corte de un e-commerce monolítico: ¿qué módulo separas primero y cómo mides si acertaste?**

⏱️ Separo el que tenga escalado distinto y poco acoplamiento: normalmente catálogo o
búsqueda. Y mido tiempo de despliegue, incidentes y latencia, antes y después.
🗣️ El criterio de elección es triple: perfil de carga distinto al resto (catálogo se lee
mucho y se escribe poco), frontera de dominio limpia, y un equipo que pueda poseerlo. No
empiezo por pagos ni por pedidos, que son el núcleo transaccional y donde la consistencia
duele. Antes de cortar, hago la frontera dentro del monolito: paquete propio, sin `JOIN`
cruzado, API explícita. Solo cuando eso funciona durante unas semanas, lo extraigo.
🔬 Las métricas: frecuencia de despliegue del módulo separado, tiempo de ciclo del equipo
que lo posee, latencia p99 del flujo que ahora cruza la red, y número de despliegues
coordinados con otros servicios. Si esta última no baja a cero, el corte estaba mal.

---

# 03 — Arquitecturas de aplicación

**03 → 1. Enuncia la regla de dependencia.**

⏱️ El código fuente solo apunta hacia adentro: las capas externas conocen a las internas,
nunca al revés.
🗣️ En la práctica significa que el dominio no importa nada de infraestructura ni del
framework. Cuando el dominio necesita algo de fuera, define una interfaz y la
infraestructura la implementa.
🔬 Es el enunciado de Clean Architecture, pero el mecanismo es el principio de inversión de
dependencias de SOLID aplicado a la frontera de un módulo.

**03 → 2. ¿Qué es un puerto y qué es un adaptador?**

⏱️ El puerto es la interfaz que define el dominio; el adaptador es la implementación que
la conecta con una tecnología concreta.
🗣️ `RepositorioDePedidos` es un puerto y vive en el dominio; `RepositorioDePedidosJpa` es
un adaptador y vive en infraestructura. Cambiar de JPA a MongoDB sustituye el adaptador y
no toca el dominio.
🔬 El adaptador es literalmente el patrón Adapter de GoF; la novedad de hexagonal es
sistematizarlo en todos los bordes y hacer que la interfaz la posea el dominio.

**03 → 3. ¿Quién propuso hexagonal, cebolla y limpia, y en qué orden cronológico?**

⏱️ Cockburn con hexagonal en 2005, Palermo con cebolla en 2008, Martin con limpia en 2012.
🗣️ Las tres descienden de la misma idea y cada una añade un matiz: Cockburn el mecanismo
de puertos y adaptadores, Palermo que las interfaces de repositorio pertenecen al dominio,
Martin la jerarquía interna y el nombre "regla de dependencia".
🔬 Saber el orden evita el error frecuente de presentar Clean como la original.

**03 → 4. ¿Qué diferencia hay entre puerto primario y secundario?**

⏱️ El primario lo llaman desde fuera; el secundario lo llama el dominio hacia fuera.
🗣️ Primario (driving): el caso de uso que el dominio ofrece, invocado por un controller,
un test o un consumidor de mensajes. Secundario (driven): lo que el dominio necesita —
persistencia, notificación, un tercero— y que la infraestructura implementa.
🔬 La asimetría importa: el puerto primario lo define el dominio por lo que sabe hacer; el
secundario lo define por lo que necesita, expresado en su propio lenguaje, no en el de la
tecnología.

**03 → 5. ¿Dónde vive la interfaz del repositorio en hexagonal y por qué ahí?**

⏱️ En el dominio. Porque es el dominio quien declara lo que necesita, no la
infraestructura quien ofrece lo que tiene.
🗣️ Si la interfaz vive junto a la implementación, el dominio depende del paquete de
infraestructura y la flecha apunta hacia fuera: has dibujado hexagonal y sigues en capas.
🔬 Es la diferencia entre "interfaz por conveniencia" e inversión de dependencias real. Lo
enunció primero Palermo en Onion Architecture.

**03 → 6. ¿Qué es el sinkhole antipattern en arquitectura en capas?**

⏱️ Capas que solo pasan la llamada hacia abajo sin añadir nada.
🗣️ Un `@Service` que solo llama al repositorio y devuelve el resultado es una capa que
cuesta mantenimiento y no aporta comportamiento. Si es el caso mayoritario, la capa sobra
o la lógica se fue a otro sitio.
🔬 Richards da una regla de dedo: si más del 80 % de las peticiones atraviesan capas sin
transformación, la arquitectura en capas no está aportando.

**03 → 7. ¿Qué es vertical slice architecture y contra qué argumenta?**

⏱️ Organizar por caso de uso completo en vez de por capa técnica. Argumenta contra la
abstracción compartida obligatoria.
🗣️ Cada rebanada —"crear pedido", "cancelar pedido"— contiene su request, su lógica y su
acceso a datos, y elige su propio nivel de abstracción: una consulta puede ir con SQL
directo mientras una escritura usa el modelo de dominio completo.
🔬 El principio de fondo es acoplar lo que cambia junto. Acepta duplicación entre
rebanadas a propósito, y ahí está su límite: cuando las reglas se repiten, deja de ser
barato.

**03 → 8. En capas, ¿qué problema causa que la entidad JPA llegue al controller?**

⏱️ Que el contrato público de la API queda atado al esquema de la base de datos.
🗣️ Renombrar una columna rompe a los clientes; campos internos se filtran al JSON; las
relaciones perezosas explotan al serializar fuera de la transacción. Y en sentido
contrario, la forma del JSON empieza a condicionar el modelo de datos.
🔬 Por eso el DTO en el borde remoto no es ceremonia: es la frontera que desacopla dos
ritmos de cambio distintos.

**03 → 9. ¿Qué aporta Clean Architecture que hexagonal no dice?**

⏱️ La subdivisión del interior: distingue entidades (reglas de empresa) de casos de uso
(reglas de aplicación).
🗣️ Hexagonal trata el dominio como una sola cosa y se concentra en los bordes; Clean pone
orden jerárquico dentro y aporta el vocabulario de caso de uso y el cruce de fronteras con
DTOs de entrada y salida.
🔬 Esa separación rinde cuando varias aplicaciones comparten las mismas reglas de empresa.
En un sistema único suele ser una capa que no paga.

**03 → 10. ¿Cuál es el precio concreto de hexagonal, en código?**

⏱️ Dos modelos y el mapeo entre ellos: el del dominio y el de persistencia.
🗣️ Además: más interfaces, más paquetes, más archivos por caso de uso, y una curva de
entrada para quien llega nuevo. En un CRUD, el mapeo es prácticamente todo el trabajo del
módulo.
🔬 La alternativa de usar la entidad JPA como entidad de dominio elimina el mapeo y mete
el ORM en el dominio. Es una decisión legítima si se toma a conciencia.

**03 → 11. ¿Por qué "cambiar de base de datos fácilmente" es un mal argumento para hexagonal?**

⏱️ Porque casi nunca ocurre, y cuando ocurre el puerto no es lo que más cuesta.
🗣️ Migrar de relacional a documental cambia el modelo de consulta, la consistencia y las
transacciones: el adaptador es la parte fácil. El beneficio real y cotidiano de hexagonal
es otro: poder testear el dominio sin levantar nada.
🔬 Decir esto en entrevista demuestra que has usado el patrón y no solo leído su folleto.

**03 → 12. ¿Puede el dominio llevar anotaciones? ¿Cuáles sí y cuáles no?**

⏱️ Las de Java estándar sí; las del framework y las del ORM, no.
🗣️ `@Override`, `@FunctionalInterface` o anotaciones propias son inocuas. `@Entity`,
`@Column`, `@Component` o `@Autowired` acoplan el dominio a JPA y a Spring, que es
exactamente lo que se quería evitar. Las de Bean Validation están en el límite: son
estándar, pero suelen expresar reglas que el objeto de valor debería garantizar en su
constructor.
🔬 La verificación automática es una fitness function de ArchUnit: "ninguna clase de
`domain` importa `org.springframework` ni `jakarta.persistence`".

**03 → 13. ¿Cuándo hexagonal es "carpeta ceremonial"?**

⏱️ Cuando el dominio no tiene invariantes: si la lógica es leer, validar formato y
guardar, el puerto solo añade mapeo.
🗣️ La prueba práctica: ¿hay alguna regla de negocio que quieras testear sin base de datos?
Si no la encuentras, hexagonal no está comprando nada.
🔬 El criterio de DDD ayuda: en un subdominio núcleo se paga sola; en uno de soporte, capas
con un buen servicio es más honesto.

**03 → 14. ¿Cómo verificas que nadie rompió la frontera del dominio?**

⏱️ Con ArchUnit en el pipeline: una regla que prohíbe importar infraestructura desde el
dominio.
🗣️ Se complementa con reglas de ciclos entre paquetes y con una que prohíba entidades JPA
en firmas de controllers. Lo importante es que falle el build, no el revisor.
🔬 Spring Modulith cubre el caso de módulos; ArchUnit es más general y permite reglas a
medida.

**03 → 15. ¿Qué gana y qué pierde vertical slice frente a hexagonal?**

⏱️ Gana localidad —un cambio toca un directorio— y pierde reutilización: duplica entre
rebanadas.
🗣️ También gana la posibilidad de que cada caso de uso elija su abstracción, lo que evita
el mínimo común denominador de un repositorio que sirve a todos mal. Pierde la garantía de
que una regla de negocio esté en un solo sitio.
🔬 Se combinan: rebanadas por fuera, con el núcleo del dominio compartido donde de verdad
hay invariantes. No son excluyentes.

**03 → 16. ¿Por qué vertical slice encaja bien con CQRS?**

⏱️ Porque CQRS ya separa lecturas de escrituras, y las rebanadas permiten que cada lado
use su propio modelo.
🗣️ Una consulta puede proyectar directamente a un DTO con SQL sin pasar por el agregado,
mientras el comando usa el modelo de dominio completo. En una arquitectura en capas eso
parece incoherente; en rebanadas es exactamente el objetivo.
🔬 Es también por qué las implementaciones típicas de CQRS acaban pareciéndose a vertical
slice aunque no lo declaren.

**03 → 17. Tu `@Service` solo delega al repositorio. ¿Qué haces con esa capa?**

⏱️ Depende de si hay lógica en alguna parte: o la capa sobra, o la lógica está en el sitio
equivocado.
🗣️ Si el módulo es un CRUD honesto, quitar la capa y llamar al repositorio desde el
controller es defendible. Si hay reglas de negocio pero viven en el controller o en la
entidad anémica, el problema no es la capa vacía sino dónde acabó la lógica.
🔬 Lo que no haría es mantenerla "por consistencia arquitectónica": una capa sin
responsabilidad es coste de mantenimiento permanente.

**03 → 18. En hexagonal, ¿dónde pones la transacción y por qué ahí?**

⏱️ En el servicio de aplicación, que es el borde del caso de uso. Ni en el dominio ni en
el adaptador.
🗣️ El dominio no debe conocer transacciones: es un concepto de infraestructura. El
adaptador de persistencia es demasiado abajo, porque un caso de uso puede tocar varios
puertos y todos deben estar en la misma transacción. El servicio de aplicación es el único
punto que conoce el caso de uso completo.
🔬 En Spring, eso significa `@Transactional` en el servicio de aplicación, no en el
repositorio. Y con ello heredas el problema del proxy: la autoinvocación no abre
transacción.

**03 → 19. Tienes un monolito en capas de 300k líneas. ¿Cómo introduces hexagonal sin reescribir?**

⏱️ Módulo a módulo, empezando por el que tenga más reglas de negocio y más dolor de
testing.
🗣️ El camino que sigo: elijo un módulo con invariantes reales; extraigo primero los
objetos de valor, que son baratos y no rompen nada; defino el puerto de repositorio en el
dominio e implemento el adaptador delegando en el `JpaRepository` que ya existe; muevo las
reglas de los servicios a las entidades; y solo al final separo el modelo de dominio de la
entidad JPA, si hace falta. Cada paso deja el sistema funcionando.
🔬 La fitness function se añade **cuando el módulo ya cumple**, no antes, y se restringe a
ese paquete. Una regla global desde el día uno solo produce un build rojo permanente que
el equipo aprende a ignorar.

**03 → 20. Un compañero dice "hexagonal siempre, es la buena práctica". Rebátelo sin quedar como el que no quiere calidad.**

⏱️ Le doy la razón en el objetivo y discuto el coste: la pregunta no es si hexagonal es
buena, es en qué módulos se paga.
🗣️ Planteo el criterio en vez de la opinión: ¿qué regla de negocio de este módulo quieres
testear sin base de datos? Si hay respuesta, hexagonal se justifica y lo apoyo. Si el
módulo es un CRUD, el mapeo será todo el trabajo y el equipo pagará ceremonia sin recibir
testabilidad. Propongo aplicarlo donde haya invariantes y medirlo.
🔬 La forma importa tanto como el fondo: no es "no", es "¿dónde?". Y acepto por adelantado
que si aparece la regla que justifica el patrón, cambio de opinión.

**03 → 21. Diseña la estructura de paquetes de un módulo de pagos en hexagonal, y di qué clase es pública y cuál no.**

⏱️ Tres paquetes: `domain`, `application`, `infrastructure`. Público solo el puerto
primario y los tipos que aparecen en su firma.
🗣️ La estructura que uso:

```text
pagos/
  domain/         Pago, Money, EstadoPago, PagoRechazado, PuertoDeCobro (interfaz)
  application/    RegistrarPago (caso de uso, @Transactional), PagoService
  infrastructure/ PagoController, PagoJpaAdapter, PasarelaHttpAdapter, PagoEntity
```

Público: el caso de uso `RegistrarPago` y los tipos de su firma (`PagoId`, `Money`, los
comandos y los resultados). Todo lo demás con visibilidad de paquete: los adaptadores,
`PagoEntity` y las implementaciones. Si otro módulo puede nombrar `PagoJpaAdapter`, la
frontera no existe.
🔬 `domain` no importa nada de `infrastructure` ni de Spring; `infrastructure` importa
`domain` libremente. El controller está en infraestructura porque HTTP es una tecnología
de borde, igual que JPA. Y la verificación va en ArchUnit, no en la revisión de código.

---

# 04 — Patrones GoF

**04 → 1. ¿Por qué las clases `JdbcTemplate` y `RestTemplate` se llaman así?**

⏱️ Porque implementan Template Method: la clase pone el esqueleto y tú pones el trozo
variable.
🗣️ `JdbcTemplate` abre la conexión, gestiona la excepción, cierra el recurso; tú aportas
el SQL y el `RowMapper`. Ese reparto es exactamente el patrón, y el sufijo lo anuncia.
🔬 Lo mismo en `TransactionTemplate`, `RabbitTemplate`, `RedisTemplate`. Es una convención
de nombres deliberada del framework.

**04 → 2. ¿Qué diferencia a Decorator de Proxy?**

⏱️ La intención. Decorator añade funcionalidad; Proxy controla el acceso.
🗣️ El mecanismo es idéntico: ambos implementan la misma interfaz y envuelven una
instancia. Pero los decoradores se apilan y son opcionales (caché, compresión, logging);
el proxy suele ser uno solo y decide si la llamada llega o no, o cuándo.
🔬 Consecuencia práctica: un decorador siempre delega; un proxy puede no hacerlo —carga
perezosa, control de permisos, circuito abierto—.

**04 → 3. ¿Qué diferencia a Factory Method de Abstract Factory?**

⏱️ Factory Method crea un producto y varía por herencia; Abstract Factory crea una familia
de productos y varía por composición.
🗣️ Abstract Factory garantiza que los objetos que produce combinan entre sí: todos los
componentes del mismo tema visual, todos los objetos del mismo motor de base de datos.
🔬 Señal para distinguirlas: si la interfaz tiene un método de creación es Factory Method;
si tiene varios que deben ser coherentes entre sí, es Abstract Factory.

**04 → 4. ¿Qué patrón implementa `@Transactional` y qué consecuencia tiene?**

⏱️ Proxy. La consecuencia: solo funciona cuando la llamada entra desde fuera del objeto.
🗣️ Spring envuelve el bean en un proxy que abre transacción antes y hace commit o rollback
después. Como la lógica vive en el envoltorio, cualquier llamada que no pase por él no la
activa.
🔬 De ahí tres reglas: no funciona en llamadas internas, no funciona en métodos `private`,
y con proxies CGLIB tampoco en `final`. Y a nivel de patrón de Fowler, además es Unit of
Work.

**04 → 5. ¿Por qué Singleton se considera hoy un antipatrón?**

⏱️ Por el estado global y por la dependencia estática: no se puede sustituir en un test.
🗣️ Añade acoplamiento invisible (nada en la firma dice que usas el singleton), complica la
concurrencia y hace que el orden de inicialización importe. En Spring el scope singleton
da la misma instancia única sin ninguno de esos defectos, porque se inyecta.
🔬 El matiz honesto: un singleton sin estado y sin dependencias —una utilidad pura— es
inofensivo. El problema es el singleton mutable.

**04 → 6. ¿Cómo inyecta Spring todas las implementaciones de una Strategy?**

⏱️ Inyectando `List<T>` o `Map<String, T>`, donde la clave es el nombre del bean.
🗣️ Con el `Map` puedes seleccionar por clave de negocio nombrando los beans
adecuadamente. Añadir una estrategia nueva es añadir un bean: el consumidor no se toca.
🔬 Para ordenarlas, `@Order` o `Ordered`. Un patrón habitual: cada estrategia expone un
método `soporta(tipo)` y el selector recorre la lista, lo que evita depender del nombre
del bean.

**04 → 7. ¿Los eventos de Spring son síncronos o asíncronos? ¿Y durables?**

⏱️ Síncronos por defecto y no durables: viven en memoria, en el mismo proceso.
🗣️ Se pueden hacer asíncronos con `@Async`, pero siguen sin durabilidad: si el proceso cae,
el evento se pierde. No hay reintento, ni orden garantizado, ni cola de mensajes muertos.
🔬 Por eso son excelentes para desacoplar dentro de un módulo y malos como sustituto de un
broker. El puente entre ambos mundos es el outbox.

**04 → 8. ¿Qué patrón sostiene el lado derecho de una arquitectura hexagonal?**

⏱️ Adapter.
🗣️ Cada adaptador secundario implementa un puerto definido por el dominio y traduce entre
el lenguaje del dominio y el de la tecnología. Es Adapter aplicado sistemáticamente a
todos los bordes.
🔬 Y a escala de contextos acotados, el mismo patrón con más ambición se llama capa
anticorrupción: no solo adapta la firma, traduce el modelo.

**04 → 9. ¿Qué patrón GoF hace posible CQRS y las colas de trabajo?**

⏱️ Command: convertir una petición en un objeto.
🗣️ Al ser un objeto, la operación se puede serializar, encolar, registrar, reintentar,
auditar y deshacer. Eso es exactamente lo que hace un mensaje en un broker o un comando en
CQRS.
🔬 En Java: `Runnable` y `Callable` son Command; los `Step` de Spring Batch también.

**04 → 10. ¿Por qué `@Transactional` no funciona en una llamada interna?**

⏱️ Porque `this.metodo()` no pasa por el proxy: llama directo a la instancia real.
🗣️ El proxy envuelve el bean que Spring inyecta a otros. Dentro de la clase, `this` es el
objeto sin envolver, así que ninguna anotación interceptada por AOP se aplica.
🔬 Salidas: mover el método a otro bean (lo habitual y lo correcto), inyectarse a sí mismo
con `@Lazy`, o usar `AopContext.currentProxy()`. Las dos últimas funcionan y huelen mal.

**04 → 11. ¿Qué característica de Java 21 deja obsoleto a Visitor?**

⏱️ Las clases `sealed` con pattern matching en `switch`.
🗣️ Visitor existía para simular double dispatch y para que el compilador te obligara a
tratar todos los casos. Con una jerarquía `sealed`, el `switch` con patrones verifica la
exhaustividad en compilación y el código queda en un método en vez de en una interfaz con
N métodos.
🔬 Lo que se pierde: Visitor permitía añadir operaciones sin tocar la jerarquía. Con
`sealed` la jerarquía es cerrada a propósito, que suele ser lo que quieres en un dominio.

**04 → 12. ¿Qué diferencia hay entre `@EventListener` y `@TransactionalEventListener`?**

⏱️ El segundo se engancha a una fase de la transacción; el primero se ejecuta al publicar.
🗣️ Con `@EventListener` el listener corre dentro de la transacción del emisor: si esta
hace rollback, el efecto secundario ya ocurrió. Con
`@TransactionalEventListener(phase = AFTER_COMMIT)` solo se ejecuta si el commit tuvo
éxito, que es casi siempre lo que quieres para notificar o publicar.
🔬 Detalle: en `AFTER_COMMIT` ya no hay transacción activa, así que escribir en base de
datos ahí requiere `REQUIRES_NEW`. Y si el proceso muere entre el commit y el listener, el
efecto se pierde: para eso está el outbox.

**04 → 13. ¿Cuál es el valor real de Builder más allá de la legibilidad?**

⏱️ Garantizar que no existe un objeto a medio construir o inválido.
🗣️ El `build()` es el único punto donde puedes validar el objeto completo: comprobar que
los campos obligatorios están, que las combinaciones son coherentes, y lanzar si no. Con
setters, el objeto existe inválido entre llamada y llamada.
🔬 Eso lo conecta con los objetos de valor y con las fábricas de agregados de DDD: los tres
persiguen lo mismo, que el tipo garantice su propia validez.

**04 → 14. ¿Por qué Flyweight casi no se implementa a mano hoy en Java?**

⏱️ Porque el runtime ya comparte lo que se comparte: interning de `String`, caché de
`Integer`, objetos inmutables.
🗣️ Además, el coste de memoria que Flyweight ahorraba es menos crítico hoy, y la
indirección que añade puede salir más cara que el ahorro por el efecto en la caché de CPU.
🔬 Donde sigue vivo: caches de objetos costosos de crear, y estructuras de datos
especializadas. Pero eso ya se llama caché, no Flyweight.

**04 → 15. Nombra tres patrones que NO usarías y justifica cada uno.**

⏱️ Singleton, por estado global e intestable; Visitor, porque `sealed` más pattern matching
lo hace mejor; Flyweight, porque el runtime ya lo resuelve.
🗣️ Añadiría Prototype: `clone()` está desaconsejado desde Bloch y un `record` con copia por
constructor es más claro. E Interpreter, salvo que estés escribiendo un motor de reglas,
porque hay librerías mejores.
🔬 Esta pregunta mide criterio, no memoria: el catálogo se escribió en 1994 contra C++ y
varios patrones son rodeos alrededor de limitaciones del lenguaje, no verdades eternas.

**04 → 16. ¿Cuándo una Strategy no merece una interfaz propia?**

⏱️ Cuando tiene un solo método y no tiene estado ni dependencias: ahí basta una lambda o
un `enum`.
🗣️ Un `enum` con método abstracto es especialmente bueno cuando las variantes son un
conjunto cerrado y conocido: te da exhaustividad, nombre y serialización gratis.
🔬 El criterio para pasar a interfaz e implementaciones: cuando cada estrategia necesita
dependencias inyectadas, o cuando el conjunto debe poder ampliarse sin tocar el código
existente.

**04 → 17. Te dicen "los patrones de diseño están obsoletos". ¿Qué respondes?**

⏱️ Que algunos sí y por una razón concreta: eran rodeos alrededor de limitaciones del
lenguaje. Otros son vocabulario y siguen vigentes.
🗣️ Doy ejemplos de las dos mitades. Obsoletos: Visitor contra `sealed`, Flyweight contra el
runtime, Singleton contra inyección de dependencias. Vigentes: Strategy, Adapter, Decorator
y Proxy, que son la estructura de Spring entero. Y añado que el valor principal del
catálogo hoy es el vocabulario compartido: decir "esto es un Adapter" ahorra un párrafo.
🔬 La respuesta pobre es defenderlos todos o rechazarlos todos. La buena es tener la lista
de cada lado con su motivo.

**04 → 18. Tienes un `switch` de 12 casos que crece cada sprint. ¿Cómo lo atacas y qué pierdes al hacerlo?**

⏱️ Strategy con selección por bean, o un `enum` con método abstracto si el conjunto es
cerrado.
🗣️ Con Strategy inyectada en `Map` o en `List`, añadir un caso es añadir una clase y no
tocar el consumidor: cumple abierto/cerrado. Si el conjunto es fijo y pequeño, prefiero
`enum` con método abstracto, que mantiene todo a la vista y da exhaustividad. Y si los
doce casos son de un dominio que evoluciona sin parar, la conversación real es microkernel
con registro de plug-ins.
🔬 Lo que pierdo: la localidad. Con el `switch` ves los doce casos en una pantalla; con
doce clases tienes que navegar. Esa pérdida es real y hay quien la subestima: si los casos
son triviales y cambian poco, el `switch` es más legible y no lo tocaría. El disparador
para refactorizar es que los casos tengan lógica propia, no que sean muchos.

**04 → 19. `@Cacheable` no cachea y el método sí se ejecuta. Da tres hipótesis en orden de probabilidad.**

⏱️ Autoinvocación, falta de `@EnableCaching`, o clave de caché distinta en cada llamada.
🗣️ Primera y más frecuente: el método se llama desde dentro de la misma clase, así que no
pasa por el proxy — exactamente el mismo fallo que con `@Transactional`. Segunda: no hay
`@EnableCaching` o no hay un `CacheManager` configurado, y la anotación se ignora en
silencio. Tercera: la clave incluye un argumento que cambia siempre (una fecha, un objeto
sin `equals`), así que cada llamada es un fallo de caché legítimo.
🔬 Cómo lo confirmo, en ese orden: miro quién llama al método; compruebo la configuración
y si el bean está realmente proxiado; y registro la clave generada con un `KeyGenerator`
propio o activando el log de la caché. Una cuarta hipótesis menos común: el método es
`final` o `private`, o la clase no es un bean de Spring.

**04 → 20. Diseña el punto de extensión para que un banco añada un tipo de producto nuevo sin recompilar el core. ¿Qué patrones combinas?**

⏱️ Microkernel como estilo, con Strategy para el comportamiento, Abstract Factory para
crear la familia de objetos del producto, y un registro con `ServiceLoader`.
🗣️ El núcleo define la interfaz del producto —cálculo de intereses, comisiones, reglas de
elegibilidad, formato del extracto— y no conoce ninguna implementación. Cada producto es
un artefacto aparte que la declara en `META-INF/services` y el núcleo la descubre al
arrancar con `ServiceLoader`. Como un producto no es un comportamiento sino una familia
coherente (calculadora, validador, formateador), Abstract Factory garantiza que no se
mezclen piezas de productos distintos. La configuración de cada producto llega como datos,
no como código.
🔬 Lo que hay que resolver además del patrón: versionado de la interfaz del plug-in, que es
ahora un contrato público; aislamiento de fallos, porque un plug-in que lanza no debe
tumbar el core; y el ciclo de vida, si se quiere cargar en caliente. En banca suele haber
una restricción adicional: los plug-ins deben ser auditables y firmados, así que la carga
dinámica en caliente rara vez se aprueba y se despliega con el núcleo.

---

# 05 — Fowler PoEAA

**05 → 1. ¿Qué patrón de Fowler implementa `@Transactional`?**

⏱️ Unit of Work.
🗣️ Rastrea los objetos que cambiaron durante la operación y escribe todo junto al final,
en una sola transacción. El `EntityManager` es quien mantiene ese registro.
🔬 A nivel de GoF, además, se implementa con Proxy. Son dos respuestas correctas a dos
preguntas distintas y conviene tener las dos.

**05 → 2. ¿Qué es el dirty checking y qué permite no escribir?**

⏱️ La comparación que hace el `EntityManager` entre el estado actual de una entidad
gestionada y el que tenía al cargarla. Permite no llamar a `save()`.
🗣️ Al hacer flush, Hibernate emite `UPDATE` solo para lo que cambió. Por eso modificar una
entidad cargada dentro de una transacción persiste sin más.
🔬 Tiene coste: mantener la copia y compararla. Con muchas entidades gestionadas se nota, y
ahí ayudan las consultas de solo lectura o las proyecciones.

**05 → 3. ¿Qué patrón es el contexto de persistencia de JPA?**

⏱️ Identity Map.
🗣️ Garantiza que dentro de una transacción la misma fila devuelve siempre la misma
instancia en memoria. Es también el caché de primer nivel de Hibernate.
🔬 Consecuencia práctica: dos `findById` iguales hacen una sola consulta, y comparar con
`==` funciona dentro de la transacción — aunque seguir dependiendo de eso es frágil.

**05 → 4. ¿Por qué dos `findById` iguales en la misma transacción hacen un solo SQL?**

⏱️ Porque el segundo lo sirve el contexto de persistencia, que ya tiene la entidad.
🗣️ Es el Identity Map en acción: la primera consulta va a la base de datos y deja la
entidad gestionada; la segunda la encuentra ahí.
🔬 No aplica a las consultas JPQL con criterios, que sí van a la base de datos aunque luego
resuelvan las entidades contra el contexto.

**05 → 5. ¿Qué diferencia a Data Mapper de Active Record?**

⏱️ En Data Mapper el objeto no sabe que se persiste; en Active Record el objeto sabe
guardarse.
🗣️ Data Mapper permite que el modelo de dominio y el de tablas diverjan, al precio de una
capa de mapeo. Active Record ata la clase a la tabla y es mucho más rápido de escribir para
un CRUD.
🔬 JPA es Data Mapper por diseño, pero el uso habitual —entidad JPA como modelo de dominio
y como DTO— lo degrada a Active Record pagando el precio de Data Mapper.

**05 → 6. ¿Cómo detectas en una revisión que un modelo es anémico?**

⏱️ Si puedes dejar el objeto en estado inválido llamando a un setter, es anémico.
🗣️ Otras señales: las entidades solo tienen getters y setters; los servicios tienen cientos
de líneas de `if` sobre campos de la entidad; la misma validación aparece en varios
servicios.
🔬 La prueba definitiva: busca dónde vive la regla "un pedido no puede enviarse sin pagar".
Si está en un servicio y no en `Pedido`, el modelo es anémico.

**05 → 7. ¿Cuándo aparece `LazyInitializationException` y por qué?**

⏱️ Al acceder a una relación perezosa cuando la entidad ya está detached y la sesión
cerrada.
🗣️ Ocurre típicamente al serializar en el controller o al usar la entidad en un test fuera
de transacción. El proxy perezoso necesita la sesión para cargar y ya no la tiene.
🔬 Las soluciones buenas son traer el dato con `JOIN FETCH` o no devolver la entidad.
Mantener la sesión abierta es tratar el síntoma.

**05 → 8. ¿Qué opinaba Fowler del DTO y por qué?**

⏱️ Que era un mal necesario de las fronteras remotas, no una capa obligatoria.
🗣️ Su razón: el DTO existe para agrupar datos y evitar múltiples llamadas remotas caras. Si
no hay frontera remota, el coste del mapeo no compra nada.
🔬 Por eso lo catalogó bajo patrones de distribución. Hoy sigue justificado en el borde de
la API pública por una razón distinta: desacoplar el contrato del esquema.

**05 → 9. ¿Qué es Transaction Script y cuándo es la respuesta correcta?**

⏱️ Un procedimiento por operación de negocio, con los datos como estructuras sin
comportamiento. Es correcto cuando la lógica es fina.
🗣️ Escala mal con la complejidad porque duplica reglas entre scripts, pero para CRUD,
informes y flujos lineales es más simple, más rápido de escribir y más fácil de entender
para un equipo con rotación.
🔬 El error no es elegirlo: es elegirlo sin saberlo y descubrir a los dos años que la
misma regla está en once servicios distintos.

**05 → 10. ¿Por qué el modelo anémico se considera antipatrón, y cuál es el matiz?**

⏱️ Porque paga el coste del Domain Model —entidades, mapeo, ORM— sin obtener su beneficio.
El matiz: si eliges Transaction Script a propósito, es coherente.
🗣️ El problema real es el híbrido: entidades JPA llenas de anotaciones y vacías de
comportamiento, con servicios de 900 líneas. Ahí tienes la ceremonia de las dos opciones y
las ventajas de ninguna.
🔬 Fowler lo bautizó en 2003 precisamente por eso, y aclaró que su crítica es al
desperdicio, no a que exista lógica en servicios.

**05 → 11. ¿Qué es el problema N+1 y cómo lo diagnosticas?**

⏱️ Una consulta para la lista y una más por cada elemento al acceder a su relación
perezosa. Se diagnostica contando consultas.
🗣️ Activo `show-sql` o las estadísticas de Hibernate, ejecuto el caso de uso con diez
registros y luego con veinte. Si el número de consultas crece con los registros, es N+1.
🔬 En producción se ve como latencia que escala con el tamaño del resultado, y suele
aparecer al serializar en el controller, fuera del servicio donde se cargó.

**05 → 12. Enumera cuatro formas de atacar un N+1, de mejor a peor.**

⏱️ `JOIN FETCH` o `@EntityGraph`; proyección a DTO; ampliar la transacción; dejar OSIV.
🗣️ Las dos primeras atacan la causa: traes lo que necesitas en una consulta, o directamente
no traes la entidad. Las dos últimas solo mantienen la sesión abierta más tiempo, así que
las N+1 consultas siguen ejecutándose y el problema queda oculto.
🔬 `JOIN FETCH` con varias colecciones produce producto cartesiano; ahí se usan varias
consultas con `@BatchSize` o `subselect`.

**05 → 13. ¿Qué es OSIV, viene activo en Spring Boot, y qué harías con él?**

⏱️ Open Session In View mantiene la sesión de Hibernate abierta hasta que se renderiza la
respuesta. Viene activo por defecto y lo desactivaría.
🗣️ Su efecto es que nunca ves `LazyInitializationException`, lo que suena bien y es el
problema: las consultas perezosas se disparan durante la serialización, fuera de la capa
de servicio, ocultando N+1 y alargando la ocupación de conexiones.
🔬 `spring.jpa.open-in-view=false`, y arreglar lo que salte con `JOIN FETCH` o
proyecciones. Spring Boot ya avisa en el log de que está activo. Hacerlo en un sistema
grande de golpe es arriesgado: se hace módulo a módulo.

**05 → 14. ¿Por qué `JpaRepository` no es un buen puerto de dominio?**

⏱️ Porque filtra la tecnología hacia arriba: `Page`, `Pageable`, `flush()`,
`getReferenceById()`.
🗣️ Si el dominio depende de esa interfaz, depende de Spring Data y del modelo de
persistencia, que es justo lo que el puerto debía evitar. Además expone decenas de métodos
que el dominio no necesita.
🔬 La salida: interfaz propia en el dominio con métodos del lenguaje del negocio, e
implementación en infraestructura que delega en `JpaRepository`.

**05 → 15. ¿Cuándo un DTO entre capas internas no aporta nada?**

⏱️ Cuando es una copia campo a campo de la entidad y ambas cambian siempre juntas.
🗣️ Ahí el DTO añade una clase, un mapeo y un punto donde olvidar un campo, sin desacoplar
nada real. El criterio es si los dos lados tienen ritmos de cambio distintos.
🔬 El caso en que sí aporta dentro del proceso: cuando el DTO de salida de un caso de uso
es parte del contrato del módulo en un monolito modular.

**05 → 16. ¿Qué responsabilidad NO debería tener una Service Layer?**

⏱️ Decidir reglas de negocio. Coordina; no decide.
🗣️ Su trabajo es delimitar el caso de uso, abrir la transacción, orquestar dominio y
puertos, y traducir en el borde. Los `if` sobre invariantes del negocio pertenecen a la
entidad que las posee.
🔬 Tampoco debería conocer detalles de HTTP ni de persistencia concreta: eso es del
controller y del adaptador.

**05 → 17. Un `@Service` tiene 900 líneas de `if` de negocio. ¿Qué diagnosticas?**

⏱️ Modelo anémico: la lógica que debería estar en las entidades se acumuló en el servicio.
🗣️ Suele venir acompañado de entidades con solo getters y setters, de la misma validación
repetida en varios servicios, y de imposibilidad de testear una regla sin mocks. El
refactor típico: identificar las invariantes, moverlas a la entidad, sustituir setters por
operaciones de negocio.
🔬 Antes de refactorizar conviene preguntarse si el módulo es núcleo. Si es soporte, quizá
lo correcto no es un Domain Model sino partir el script en varios más pequeños y honestos.

**05 → 18. Cambias una entidad dentro de `@Transactional` y no se guarda. Tres hipótesis en orden.**

⏱️ La entidad está detached, la transacción no se abrió, o hubo rollback silencioso.
🗣️ Primera: la entidad no viene de este contexto de persistencia —llegó de una llamada
anterior, de una caché o de una deserialización—, así que el dirty checking no la vigila; la
solución es recargarla o usar `merge`. Segunda: la anotación no se aplicó, casi siempre por
autoinvocación o porque el método no es público. Tercera: alguien capturó una excepción y
la transacción quedó marcada para rollback, así que el commit nunca ocurrió.
🔬 Cómo las descarto en ese orden: compruebo de dónde viene la entidad;
registro `TransactionSynchronizationManager.isActualTransactionActive()` dentro del método;
y miro si hay `catch` que se traguen excepciones o llamadas a otro bean con
`REQUIRES_NEW`. Una cuarta posibilidad: el campo modificado no está mapeado, o tiene
`insertable/updatable = false`.

**05 → 19. Diseña la capa de persistencia de un módulo hexagonal: qué interfaces, dónde viven, y cómo se relaciona con `JpaRepository`.**

⏱️ Puerto en el dominio con lenguaje de negocio, adaptador en infraestructura que delega en
un `JpaRepository` interno, y mapeo entre entidad de dominio y entidad JPA.
🗣️ Concretamente, tres piezas. En `domain`: `RepositorioDePedidos` con
`porId(PedidoId)`, `guardar(Pedido)`, `pendientesDe(ClienteId)` — métodos que un experto de
negocio entendería. En `infrastructure`: `PedidoJpaAdapter` implementa ese puerto, tiene
visibilidad de paquete, y usa dentro un `PedidoJpaRepository extends JpaRepository`, que
también es interno. Y un mapeador entre `Pedido` y `PedidoEntity`, escrito a mano o con
MapStruct.
🔬 Detalles que se preguntan: la transacción va en el servicio de aplicación, no aquí, para
que un caso de uso que toca dos puertos sea atómico. La paginación no se expone con
`Pageable` de Spring sino con un tipo propio, o se acepta la fuga y se declara. Y si el
mapeo resulta ser el 90 % del módulo, esa es la señal de que el módulo no necesitaba
hexagonal.

**05 → 20. El equipo quiere exponer entidades JPA directamente en la API "para ir más rápido". Argumenta en contra con tres consecuencias concretas.**

⏱️ Atas el contrato público al esquema, filtras datos que no deben salir, y las relaciones
perezosas explotan al serializar.
🗣️ Las tres con ejemplo. Una: renombrar una columna es ahora un cambio que rompe a todos
los consumidores, así que la base de datos deja de poder evolucionar. Dos: cualquier campo
que añadas aparece en el JSON por omisión — hashes, flags internos, identificadores de
sistemas ajenos—, y es un incidente de seguridad esperando. Tres: al serializar fuera de la
transacción, o revientas con `LazyInitializationException`, o si OSIV está activo disparas
N+1 durante la serialización. Y añado una cuarta que suele cerrar la discusión: las
referencias bidireccionales producen recursión infinita y acabarás salpicando el modelo de
`@JsonIgnore`, es decir, metiendo decisiones de la API dentro de la entidad.
🔬 La contrapropuesta, porque oponerse sin alternativa no funciona: `record` como DTO más
proyección de Spring Data, de modo que la consulta construye el DTO directamente y la
entidad ni se carga. Eso es **más rápido** que el camino que proponen, no más lento, y ese
es el argumento que de verdad los convence.

---

# 06 — DDD estratégico

**06 → 1. ¿Qué es un contexto acotado?**

⏱️ La frontera dentro de la cual un modelo y su lenguaje son consistentes.
🗣️ Fuera de esa frontera los mismos términos significan otra cosa y hace falta traducción
explícita. Es la unidad de decisión de dónde cortar: un contexto, un modelo, un equipo, y
el candidato natural a servicio.
🔬 No es lo mismo que un subdominio: el subdominio es una parte del problema, el contexto
acotado es una parte de la solución. Idealmente coinciden; en sistemas heredados casi
nunca.

**06 → 2. ¿Qué es el lenguaje ubicuo y dónde tiene que vivir?**

⏱️ El vocabulario compartido entre negocio y desarrollo, y tiene que vivir en el código.
🗣️ Si el negocio dice "póliza en suspensión", la clase se llama `Poliza` y tiene el estado
`SUSPENDIDA`. Un glosario en Confluence que no se refleja en los nombres del código no es
lenguaje ubicuo.
🔬 Su función real no es documentar: es detectar malentendidos. Cuando traducir de lo que
dice negocio a lo que dice el código cuesta, esa fricción señala un concepto mal entendido
que saldrá como bug.

**06 → 3. Nombra los tres tipos de subdominio y qué haces con cada uno.**

⏱️ Núcleo, se construye a medida con tu mejor gente; soporte, se construye simple;
genérico, se compra.
🗣️ El núcleo es por lo que el negocio gana dinero y donde la ceremonia de DDD se paga
sola. El soporte es necesario y específico pero no diferencial. El genérico ya está
resuelto por el mercado: autenticación, facturación, notificaciones.
🔬 La pregunta "¿es esto núcleo?" decide si el sobre-diseño está justificado, y es la
mejor herramienta de priorización de esfuerzo que da DDD.

**06 → 4. ¿Es lo mismo un contexto acotado que un microservicio?**

⏱️ No. Es un candidato a serlo, pero la frontera es lógica antes que física.
🗣️ Un contexto puede ser un módulo dentro de un monolito modular. Lo que sí se cumple en
sentido contrario: un servicio que abarca dos contextos tiene dos modelos peleando dentro,
y dos servicios dentro de un contexto comparten modelo y por tanto ciclo de cambio.
🔬 Regla práctica: un microservicio nunca debería ser mayor que un contexto acotado, pero
puede ser menor si hay una razón operativa —escalado o aislamiento— que lo justifique.

**06 → 5. ¿Qué es una capa anticorrupción y contra qué protege?**

⏱️ Una capa de traducción que protege tu modelo del modelo de un sistema externo.
🗣️ No solo adapta firmas: traduce conceptos. Tu `Cuenta` limpia frente a la `CTA-MAESTRA`
con ochenta campos y códigos numéricos del core bancario. Cuando el sistema externo cambia,
tocas solo la ACL.
🔬 Es Adapter con intención de arquitectura. Su precio es mapeo, duplicación de conceptos y
una capa más; se paga sola cuando el sistema de arriba es inestable o su modelo es hostil.

**06 → 6. Cita cuatro patrones de relación del mapa de contextos.**

⏱️ Cliente-proveedor, conformista, capa anticorrupción y núcleo compartido.
🗣️ Y otros tres: socio, cuando dos equipos triunfan o fracasan juntos; caminos separados,
cuando integrar cuesta más que duplicar; y servicio de acceso público, cuando el proveedor
publica un protocolo estable para muchos consumidores.
🔬 Lo que hace útil al mapa no son las cajas sino las flechas: dicen quién se adapta a
quién, que es una relación de poder entre equipos, no una decisión técnica.

**06 → 7. ¿Qué diferencia hay entre DDD estratégico y táctico?**

⏱️ El estratégico decide dónde van las fronteras; el táctico, cómo se modela dentro de
una.
🗣️ Estratégico: contexto acotado, lenguaje ubicuo, subdominios, mapa de contextos.
Táctico: agregado, entidad, objeto de valor, repositorio, servicio de dominio, evento.
🔬 En entrevista se pregunta más el estratégico y se estudia más el táctico. Y el táctico
sin el estratégico es lo que produce "DDD" que solo son carpetas con nombres bonitos.

**06 → 8. ¿Qué diferencia a "conformista" de "capa anticorrupción"?**

⏱️ El conformista adopta el modelo ajeno tal cual; la ACL lo traduce al propio.
🗣️ Conformista es más barato y correcto cuando el modelo de arriba es razonable y estable:
no pagas mapeo. ACL cuesta más y se justifica cuando el modelo ajeno contaminaría el tuyo o
cambia con frecuencia.
🔬 Ambos suponen que no tienes poder de negociación sobre el proveedor. Si lo tienes, la
relación correcta es cliente-proveedor.

**06 → 9. ¿Por qué el núcleo compartido se usa poco?**

⏱️ Porque acopla los ciclos de cambio de dos equipos: cambiar lo compartido requiere
coordinar a ambos.
🗣️ Empieza siendo eficiente —evita duplicar— y acaba siendo el cuello de botella: nadie
puede cambiarlo sin negociar, así que crece por acumulación y nadie lo limpia.
🔬 Cuando se usa, debe ser pequeño, estable, y con propiedad explícita y tests compartidos.
La alternativa casi siempre mejor es duplicar y aceptar que los dos modelos diverjan.

**06 → 10. ¿Qué problema tiene un modelo canónico para toda la empresa?**

⏱️ Que no pertenece a nadie: acumula los campos de todos y no sirve bien a ninguno.
🗣️ Produce una clase con ochenta campos donde cuarenta son `null` según quién la use, nadie
puede razonarla entera, y cualquier cambio requiere coordinar a todas las áreas. Es el
punto de máximo acoplamiento organizativo.
🔬 La alternativa de DDD es la contraria: no unifiques el modelo, delimita dónde vale cada
uno y traduce en las fronteras.

**06 → 11. ¿Por qué el lenguaje ubicuo no es global sino por contexto?**

⏱️ Porque el mismo término significa cosas distintas en áreas distintas, y eso es correcto.
🗣️ "Cuenta" en originación es una solicitud con documentos; en core es un saldo con
movimientos; en cobranzas es una deuda con antigüedad. Forzar una definición única obliga a
todos a usar un término que no encaja con su realidad.
🔬 Por eso el lenguaje ubicuo es local y la frontera del contexto es precisamente donde
cambia el significado. Detectar ese cambio es el método práctico para encontrar contextos.

**06 → 12. ¿Cuál es el error caro al clasificar un subdominio genérico?**

⏱️ Construirlo a medida. Es gastar presupuesto del núcleo en algo que el mercado ya
resolvió mejor.
🗣️ El caso típico es un equipo escribiendo su propio servicio de autenticación o de
notificaciones. No solo cuesta construirlo: cuesta mantenerlo, parchearlo y auditarlo para
siempre.
🔬 El error inverso también existe y es menos frecuente pero peor: comprar o externalizar el
núcleo, que es renunciar a la ventaja competitiva.

**06 → 13. ¿Cuándo "caminos separados" es la decisión correcta?**

⏱️ Cuando integrar cuesta más que duplicar y los dos contextos apenas se necesitan.
🗣️ Si la integración sería un acoplamiento permanente para un beneficio marginal —dos áreas
que usan un dato parecido pero lo interpretan distinto— duplicar es más barato y deja a
ambos equipos libres.
🔬 Es la opción que más cuesta defender políticamente, porque "duplicar" suena mal. El
argumento es el coste total, incluida la coordinación futura.

**06 → 14. ¿Cómo se relaciona el contexto acotado con la ley de Conway?**

⏱️ El contexto dice por dónde deberías cortar; Conway dice por dónde vas a cortar de todos
modos.
🗣️ Si el corte de dominio y el de equipos no coinciden, gana el de equipos: la estructura
de comunicación acabará imponiéndose. Por eso un buen diseño de fronteras incluye la
propuesta de quién posee cada una.
🔬 De ahí la maniobra de Conway inversa: reorganizar equipos para obtener la arquitectura
deseada, en vez de esperar que la arquitectura sobreviva a un organigrama que la contradice.

**06 → 15. ¿Qué señal te dice que una capa anticorrupción está funcionando?**

⏱️ Que cuando el sistema externo cambia, solo tocas la ACL.
🗣️ La señal contraria —tener que tocar entidades de dominio, servicios y controllers porque
el proveedor añadió un campo— significa que la traducción no está encapsulada y la ACL es
solo un nombre de paquete.
🔬 Otra señal positiva: en tu dominio no aparece ningún término del vocabulario del sistema
externo. Si tu `Pedido` tiene un campo `codSitOper`, la corrupción ya entró.

**06 → 16. ¿Qué pasa cuando un servicio abarca dos contextos acotados?**

⏱️ Que tiene dos modelos peleando dentro y acabará partiéndose.
🗣️ Los síntomas: entidades con campos que solo usa la mitad del servicio; el mismo término
con dos significados en clases distintas; dos equipos tocando el mismo repositorio; y
cambios en un flujo que rompen el otro sin relación aparente.
🔬 La salida gradual: separar primero por paquetes con datos propios dentro del mismo
despliegue, verificar que la frontera aguanta, y solo entonces extraer.

**06 → 17. En un banco, "cuenta" significa cosas distintas en cuatro áreas. ¿Cómo lo modelas sin un canónico?**

⏱️ Cuatro modelos, uno por contexto, y traducción explícita en las fronteras. Lo único
compartido es el identificador.
🗣️ En originación, `Solicitud` con documentos y estado del expediente. En core,
`CuentaContable` con saldo y movimientos. En cobranzas, `Deuda` con antigüedad y gestión.
En marketing, `PerfilDeCliente` con segmento. Cada uno usa su propio lenguaje y su propio
modelo; ninguno intenta contener a los demás. Lo que viaja entre ellos es un identificador
estable —el número de cuenta— y eventos con el mínimo de datos necesario.
🔬 La pieza clave es qué se comparte: un identificador y un contrato de eventos, no un
modelo. Si un área necesita datos de otra, los pide por API o los proyecta localmente desde
eventos, y los guarda **en su propio lenguaje**. Contra el argumento de "pero es la misma
cuenta": sí en el mundo real, y no en el modelo, porque cada área necesita responder
preguntas distintas sobre ella.

**06 → 18. Diseña el mapa de contextos de un e-commerce y marca las relaciones.**

⏱️ Catálogo, Carrito, Pedidos, Pagos, Inventario, Envíos y Clientes, con Pedidos como
núcleo y relaciones mayoritariamente cliente-proveedor por eventos.
🗣️ La forma que propondría:

```text
Catálogo   → (OHS, publica) → Carrito, Pedidos     productos y precios
Carrito    → (cliente-proveedor) → Pedidos          al confirmar
Pedidos    → (socio) → Inventario                   reserva y confirmación, ambos dependen
Pedidos    → (ACL) → Pagos externos                 pasarela de terceros
Pedidos    → (evento) → Envíos                      PedidoConfirmado
Clientes   → (OHS) → todos                          identidad, genérico
```

Pedidos es el núcleo: es donde vive la regla de negocio que da dinero. Catálogo es de
lectura masiva y publica un servicio de acceso público. Pagos va detrás de una ACL porque
el modelo de una pasarela externa es hostil y cambia sin avisar. Clientes es genérico y
candidato a comprarse.
🔬 Las decisiones discutibles, que es lo que el entrevistador querrá explorar: Carrito
podría vivir dentro de Pedidos, y separarlo se justifica solo por el perfil de carga —mucha
escritura efímera— no por dominio. Pedidos e Inventario como socios es una señal de alarma:
si siempre cambian juntos, quizá son un solo contexto, y la alternativa es que Inventario
sea proveedor con reserva por evento y consistencia eventual, aceptando sobreventa
controlada.

**06 → 19. Te piden integrar con un core bancario cuyo modelo es hostil y no cambiará. ¿Qué patrón aplicas y qué te cuesta?**

⏱️ Capa anticorrupción. Cuesta mapeo, una capa más de mantenimiento y latencia añadida.
🗣️ La ACL se lleva todo el conocimiento del modelo ajeno: los códigos numéricos, los campos
de ochenta posiciones, las reglas implícitas de "si el campo 47 viene en blanco significa
X". Mi dominio habla solo su lenguaje. La implemento como un adaptador con su propio
modelo de entrada y salida, con tests que usan respuestas reales capturadas del core.
🔬 Tres cosas que suelo añadir en banca. Primera: caché en la ACL, porque el core suele
cobrar por consulta o tener ventanas de indisponibilidad. Segunda: un modo degradado
explícito para las ventanas de cierre, decidido con negocio. Tercera: contract tests contra
un doble del core, porque no vas a poder probar contra producción y el entorno de
integración del banco estará caído la mitad del tiempo. El coste real no es el mapeo: es
que la ACL se convierte en un componente crítico que necesita su propia observabilidad.

**06 → 20. ¿Cómo decides cuál de seis contextos separas primero? Da el criterio y aplícalo.**

⏱️ El que más duela y menos acople: máximo dolor de despliegue o escalado, mínimo número de
llamadas cruzadas.
🗣️ Uso cuatro criterios ponderados. Dolor actual: ¿bloquea despliegues, tiene un perfil de
carga distinto, sufre incidentes propios? Acoplamiento: ¿cuántas llamadas y transacciones
cruzan su frontera hoy? Propiedad: ¿hay un equipo que pueda poseerlo entero? Y riesgo: ¿es
núcleo transaccional? — si lo es, no va primero, porque ahí la consistencia eventual duele
más. Aplicado al e-commerce de antes: separaría Catálogo. Lectura masiva con perfil de carga
propio, frontera limpia, pocas transacciones cruzadas y ningún dato que deba ser
inmediatamente consistente.
🔬 Lo que no uso como criterio: "el más fácil" ni "el más pequeño". Separar algo sin dolor
no demuestra nada y consume la plataforma sin retorno. Y mido antes y después: frecuencia
de despliegue, latencia del flujo que ahora cruza la red, y número de despliegues que aún
hay que coordinar — si esta última no baja a cero, el corte fue malo.

**06 → 21. Negocio quiere reutilizar el modelo de "cliente" entre cuatro equipos. Argumenta a favor y en contra, y decide.**

⏱️ A favor: una sola fuente de verdad para la identidad. En contra: cuatro equipos
acoplados a un modelo que ninguno controla. Decido compartir el identificador, no el
modelo.
🗣️ El argumento a favor es real y hay que reconocerlo: sin nada compartido acabas con
cuatro definiciones de quién es el cliente, datos que no cuadran entre áreas y problemas de
cumplimiento normativo cuando alguien ejerce su derecho de supresión. El argumento en contra
es el núcleo compartido: cualquier cambio requiere coordinar cuatro equipos, el modelo crece
por acumulación y se convierte en el cuello de botella de todos.
🔬 Mi decisión y cómo la presento: un contexto de Clientes que es el dueño de la identidad y
de los datos maestros, y que publica un servicio de acceso público y eventos de cambio. Los
otros tres consumen y **proyectan localmente lo que necesitan, en su propio lenguaje**:
riesgo guarda su perfil de riesgo, cobranzas su historial de gestión, marketing su segmento.
Lo compartido es el `ClienteId` y un contrato de eventos versionado, no una clase. Así hay
una sola fuente de verdad para la identidad —que es lo que negocio realmente pide— sin que
cuatro equipos compartan un modelo. Y el coste que declaro: consistencia eventual en las
proyecciones, del orden de segundos, que en este caso el negocio puede absorber.

---

# 07 — DDD táctico

**07 → 1. ¿Qué diferencia a una entidad de un objeto de valor?**

⏱️ La identidad. La entidad la tiene y persiste aunque cambien sus atributos; el objeto de
valor se define solo por sus atributos.
🗣️ La prueba: ¿dos instancias con los mismos datos son intercambiables? Dos billetes de 10
euros sí, así que `Money` es objeto de valor. Dos clientes con el mismo nombre no, así que
`Cliente` es entidad.
🔬 Consecuencias de diseño: el objeto de valor es inmutable y se compara por valor; la
entidad es mutable y se compara por identificador. En Java, `record` para el primero, clase
con `equals` sobre el id para la segunda.

**07 → 2. Enuncia la regla de oro del agregado.**

⏱️ Una transacción, un agregado. Dentro, consistencia inmediata; entre agregados,
consistencia eventual.
🗣️ Significa que una operación de negocio modifica un solo agregado y lo deja consistente
al terminar. Lo que deba cambiar en otros agregados se propaga con eventos de dominio, en
otra transacción.
🔬 Es también la regla que hace escalable el modelo: agregados pequeños significan
transacciones cortas y poca contención de bloqueos.

**07 → 3. ¿Qué es una raíz de agregado y qué garantiza?**

⏱️ El único punto de entrada al agregado. Garantiza que las invariantes se cumplen siempre.
🗣️ Nada de fuera referencia a los objetos internos: se accede a ellos a través de la raíz, y
la raíz expone operaciones de negocio en vez de setters, de modo que no existe camino hasta
un estado inválido.
🔬 Por eso también hay un solo repositorio por agregado: cargar o guardar una entidad
interna por separado saltaría la raíz y con ella la invariante.

**07 → 4. ¿Qué es un evento de dominio y cómo se nombra?**

⏱️ Algo que ya ocurrió y le importa al negocio. Se nombra en pasado y en lenguaje ubicuo:
`PedidoEnviado`, `PagoRechazado`.
🗣️ Su función es permitir que otros agregados o contextos reaccionen sin que el emisor los
conozca, manteniendo la regla de una transacción por agregado.
🔬 El nombre en pasado no es cosmético: obliga a modelar hechos consumados en vez de
órdenes. `EnviarPedido` sería un comando, que puede rechazarse; `PedidoEnviado` ya pasó.

**07 → 5. ¿Cómo referencia un agregado a otro y por qué?**

⏱️ Por identidad, no por objeto: `ClienteId`, no `Cliente`.
🗣️ Referenciar el objeto arrastra el otro agregado a tu transacción, difumina la frontera
transaccional y hace que cargar un pedido cargue medio grafo. Con el id, cada agregado se
carga y se guarda por separado.
🔬 En JPA esto choca con `@ManyToOne`, que es el idioma natural del ORM. Se resuelve
mapeando la columna como valor simple, o usando Spring Data JDBC, que lo modela así de
forma nativa.

**07 → 6. ¿En qué se diferencia un servicio de dominio de un `@Service` de Spring?**

⏱️ El de dominio es lógica pura sin dependencias técnicas; el `@Service` es Service Layer y
coordina transacción e infraestructura.
🗣️ El servicio de dominio existe para la operación que no pertenece naturalmente a ninguna
entidad, típicamente porque cruza varias: una transferencia entre dos cuentas. No conoce
Spring, ni transacciones, ni repositorios concretos.
🔬 Señal de alarma: si todos tus servicios de dominio están llenos y tus entidades vacías,
has vuelto al modelo anémico con otro nombre.

**07 → 7. ¿Cuántos repositorios tiene un agregado con tres entidades internas?**

⏱️ Uno, el de la raíz.
🗣️ Las entidades internas no se cargan ni se guardan por separado: viven y mueren con el
agregado. Si necesitas un repositorio para una de ellas, no es interna y el agregado está
mal dimensionado.
🔬 La excepción aparente son las consultas de lectura que devuelven datos internos: eso no
va por el repositorio del agregado, va por una proyección de lectura, que es otra cosa y
conecta con CQRS.

**07 → 8. ¿Por qué un `record` es la forma natural del objeto de valor en Java?**

⏱️ Porque es inmutable, tiene `equals` y `hashCode` por valor, y permite validar en el
constructor compacto.
🗣️ Eso son exactamente las tres propiedades que define un objeto de valor, sin escribir
código repetitivo. Antes de los `record` había que escribir a mano lo mismo y por eso casi
nadie lo hacía.
🔬 Límite: un `record` no puede extender ni tener campos mutables, que es justo lo que
quieres. Si necesitas lógica de validación compleja, va en el constructor compacto o en una
fábrica estática.

**07 → 9. ¿Dónde va la validación de un objeto de valor y qué garantiza después?**

⏱️ En el constructor. Garantiza que no existe una instancia inválida en ninguna parte del
sistema.
🗣️ A partir de ahí, cualquier método que reciba un `Iban` sabe que es un IBAN válido sin
volver a comprobarlo. Eso elimina las validaciones defensivas repetidas y las ramas de error
que nunca se ejecutan.
🔬 Es el mismo principio que el `build()` de Builder y que la fábrica de un agregado: hacer
que el tipo garantice su propia validez, en vez de validar en cada uso.

**07 → 10. ¿Cómo decides el tamaño de un agregado?**

⏱️ Preguntando qué tiene que ser consistente en el mismo instante. Todo lo demás va fuera.
🗣️ No es "qué va junto conceptualmente" ni "qué se consulta junto". Es qué invariante debe
cumplirse siempre: si la regla es "las líneas no pueden sumar más que el límite del pedido",
las líneas están dentro. Si la regla es "un cliente puede tener muchos pedidos", no hay
invariante y son agregados distintos.
🔬 Las reglas de Vernon: agregados pequeños, referenciar por identidad, consistencia
eventual fuera de la frontera, y actualizar un solo agregado por transacción.

**07 → 11. ¿Por qué un agregado grande produce contención de bloqueos?**

⏱️ Porque cargarlo y guardarlo bloquea todo su contenido, aunque cambies un solo campo.
🗣️ Un agregado `Cliente` que contiene todos sus pedidos significa que modificar un teléfono
carga y bloquea miles de filas, y dos operaciones sobre pedidos distintos del mismo cliente
compiten entre sí. Con bloqueo optimista, además, se traduce en conflictos de versión
constantes.
🔬 El síntoma en producción: excepciones de bloqueo optimista o esperas de bloqueo que
aumentan con la actividad de un solo cliente grande.

**07 → 12. ¿En qué se diferencia un evento de dominio de uno de integración?**

⏱️ El de dominio es interno y habla tu lenguaje; el de integración es un contrato público
con otros contextos.
🗣️ El de dominio puede cambiar libremente porque solo lo consume tu propio módulo. El de
integración, en cuanto lo publicas, te ata: cambiarlo rompe a consumidores que no controlas
y necesita versionado y compatibilidad.
🔬 Por eso publicar los eventos de dominio tal cual al broker es un error caro: convierte tu
modelo interno en API pública y ya no puedes refactorizarlo. Lo correcto es traducir en la
frontera, con un evento de integración más estable y con menos detalle.

**07 → 13. Nombra tres puntos donde el agregado de DDD choca con JPA.**

⏱️ Las referencias por id contra `@ManyToOne`, el lazy loading contra cargar el agregado
entero, y las colecciones encapsuladas contra los getters que el ORM necesita.
🗣️ Un cuarto: JPA requiere constructor sin argumentos y setters o acceso a campos, lo que
empuja hacia objetos mutables cuando el agregado querría ser lo más inmutable posible. Y un
quinto: las cascadas arrastran medio grafo y rompen "una transacción, un agregado".
🔬 Las tres salidas: usar la entidad JPA como agregado y aceptar la contaminación; mantener
dominio puro con mapeo a entidades JPA aparte; o usar Spring Data JDBC, diseñado con el
agregado como unidad.

**07 → 14. ¿Por qué Spring Data JDBC modela agregados mejor que JPA?**

⏱️ Porque no tiene lazy loading ni contexto de persistencia: carga y guarda el agregado
completo, que es justo lo que el patrón pide.
🗣️ Fue diseñado con el agregado de DDD como unidad. Guardar la raíz guarda su contenido;
borrar la raíz borra su contenido; las referencias a otros agregados son ids, no objetos. No
hay dirty checking mágico ni sesión que mantener abierta.
🔬 El precio: menos funcionalidad que JPA, consultas más manuales, y peor encaje si tu
modelo relacional es heredado y complejo. Es una opción excelente para un servicio nuevo con
dominio rico, y mala para mapear 1.200 tablas existentes.

**07 → 15. Si expones la colección interna del agregado, ¿qué rompes?**

⏱️ La invariante: cualquiera puede añadir o quitar elementos sin pasar por la raíz.
🗣️ `pedido.getLineas().add(nueva)` salta la comprobación de límite, de estado y de
duplicados. La raíz deja de ser el único punto de entrada y el agregado deja de garantizar
nada.
🔬 La solución: devolver una vista inmutable (`List.copyOf` o
`Collections.unmodifiableList`) y exponer operaciones (`pedido.agregarLinea(...)`) que
validen. En JPA hay que cuidar que el ORM siga pudiendo acceder al campo real.

**07 → 16. ¿Qué señal indica que volviste al modelo anémico usando servicios de dominio?**

⏱️ Que los servicios de dominio están llenos de reglas y las entidades solo tienen getters y
setters.
🗣️ El servicio de dominio es legítimo para la operación que cruza varios agregados. Si se
convierte en el sitio por defecto donde poner cualquier regla, es el mismo antipatrón con
un nombre de DDD encima.
🔬 La comprobación: coge tres reglas de negocio importantes y busca dónde viven. Si ninguna
está en una entidad, el modelo es anémico independientemente de cómo se llamen los paquetes.

**07 → 17. ¿Qué bloque de DDD táctico es rentable incluso en un dominio sin invariantes, y por qué?**

⏱️ Los objetos de valor. Cuestan un `record` y eliminan una clase entera de errores.
🗣️ Sustituir `String` por `Iban`, `BigDecimal` por `Money` y dos `LocalDate` por
`RangoDeFechas` hace que el compilador impida pasar un argumento donde no toca, centraliza
la validación y da nombre a conceptos del negocio. Nada de eso requiere invariantes
complejas ni arquitectura.
🔬 Los demás bloques —agregado, servicio de dominio, fábrica— sí requieren que haya
invariantes que proteger. Sin ellas, son ceremonia.

**07 → 18. ¿Cuándo el DDD táctico completo NO se justifica?**

⏱️ Cuando el dominio no tiene invariantes: si las reglas son validación de formato y CRUD,
la ceremonia no compra nada.
🗣️ El criterio que uso es el del subdominio: completo en el núcleo, objetos de valor y
entidades simples en el de soporte, y nada en el genérico porque no lo construyes. Aplicar
el catálogo entero a un módulo de mantenimiento de catálogos es coste puro.
🔬 Decir esto en voz alta es lo que distingue el criterio de la memoria. El error frecuente
en entrevista es defender DDD como universalmente bueno.

**07 → 19. Tienes `Cliente` con 5.000 pedidos dentro del agregado. Diagnostica y rediseña.**

⏱️ Agregado mal dimensionado: no hay invariante que exija que cliente y pedidos sean
consistentes en el mismo instante. Son dos agregados.
🗣️ El diagnóstico se confirma con los síntomas: cargar un cliente trae miles de filas,
cambiar un teléfono bloquea todos sus pedidos, y hay conflictos de bloqueo optimista entre
operaciones que no tienen nada que ver. La pregunta que lo cierra: ¿existe alguna regla que
deba comprobarse mirando cliente y todos sus pedidos a la vez? Casi siempre la respuesta es
no. El rediseño: `Cliente` y `Pedido` como agregados separados, y `Pedido` referencia a
`ClienteId`.
🔬 El caso interesante es cuando sí hay una regla, del tipo "un cliente no puede tener más
de tres pedidos abiertos". Eso no obliga a meter los pedidos dentro: se resuelve con una
comprobación al crear el pedido, aceptando una ventana de carrera, o con una restricción en
base de datos si la regla debe ser absoluta. Meter 5.000 pedidos en el agregado para
proteger una regla que se comprueba sobre un contador es desproporcionado. Y si la
consulta "cliente con sus últimos pedidos" es frecuente, eso es una necesidad de lectura, y
se resuelve con una proyección, no con la forma del agregado.

**07 → 20. Diseña el agregado de una transferencia bancaria: qué contiene, qué queda fuera y cómo mantienes la consistencia con lo de fuera.**

⏱️ La `Transferencia` es el agregado, con su estado y sus importes. Las dos cuentas quedan
fuera, referenciadas por id, y se ajustan por eventos.
🗣️ La tentación es hacer un agregado que contenga las dos cuentas para garantizar
atómicamente que una baja y la otra sube. No lo hago: bloquearía ambas cuentas y en un banco
eso es contención masiva, además de imposible si están en contextos o sistemas distintos. En
su lugar, `Transferencia` es una entidad de pleno derecho con estado propio: `SOLICITADA`,
`DEBITADA`, `ACREDITADA`, `COMPLETADA`, `REVERTIDA`. Contiene `cuentaOrigenId`,
`cuentaDestinoId`, `Money`, motivo y marcas de tiempo. Las invariantes que protege: el
importe es positivo, origen y destino son distintos, y las transiciones de estado son
válidas.
🔬 La consistencia con las cuentas se mantiene con una saga: `TransferenciaSolicitada`
dispara el débito en origen; si tiene éxito, `FondosDebitados` dispara el crédito en
destino; si el crédito falla, se compensa con un abono en origen y la transferencia queda
`REVERTIDA`. Tres detalles que se preguntan. Idempotencia: cada paso lleva el id de la
transferencia como clave, así que reintentar no duplica. Compensación, no rollback: en
contabilidad no se borra, se emite el asiento contrario, lo que además es lo que exige la
auditoría. Y la ventana de inconsistencia es visible para el usuario, así que el saldo
disponible debe descontar el importe en tránsito desde el primer paso — que es exactamente
como funciona un banco real.

**07 → 21. Tu dominio es puro pero persistes con JPA. Describe las dos opciones de mapeo y elige una justificando el precio.**

⏱️ Entidad JPA separada con mapeo explícito, o la entidad JPA como agregado. Elijo la
primera si el dominio es núcleo, la segunda si no.
🗣️ Opción A, dos modelos: `Pedido` en el dominio, sin anotaciones, con colecciones
encapsuladas y constructores que validan; `PedidoEntity` en infraestructura, con `@Entity` y
setters; y un mapeador en el adaptador. Precio: dos clases por concepto, el mapeo en ambos
sentidos, y el problema de reconstruir el agregado sin pasar por sus validaciones, que
obliga a un constructor de reconstitución. Opción B, un modelo: la entidad JPA es el
agregado. Precio: anotaciones de persistencia en el dominio, constructor sin argumentos,
setters que el ORM necesita, y el riesgo de que decisiones de mapeo condicionen el modelo.
🔬 Mi elección depende del subdominio, y lo digo así en entrevista. En el núcleo, opción A:
el dominio es lo que da dinero, tiene invariantes reales y quiero testearlo sin
infraestructura; el mapeo es un coste aceptable. Fuera del núcleo, opción B, sin
complejos. Y menciono la tercera vía: Spring Data JDBC permite dominio casi puro sin el
mapeo doble, porque modela agregados de forma nativa. Si el servicio es nuevo y el esquema
lo controlo yo, esa es la mejor relación coste-beneficio de las tres.

**07 → 22. Una regla de negocio cruza tres agregados. ¿Dónde la pones?**

⏱️ Primero compruebo si de verdad los cruza. Si los cruza, en un servicio de dominio; si
además debe ser atómica, replanteo las fronteras.
🗣️ Tres casos distintos con tres respuestas. Si la regla solo **lee** de dos agregados y
decide sobre un tercero, va en un servicio de dominio que recibe los datos ya cargados: es
lógica pura y se testea sin infraestructura. Si la regla debe cumplirse **eventualmente**,
va en un proceso dirigido por eventos: cada agregado reacciona y compensa si no puede. Si la
regla debe cumplirse **atómicamente** sobre los tres, eso es una invariante que atraviesa la
frontera, y la frontera está mal: o son un solo agregado, o la regla no es tan absoluta como
dice el negocio.
🔬 El tercer caso merece conversación con negocio, no solución técnica. La pregunta útil es
qué pasa en el mundo real si la regla se viola durante unos segundos: normalmente hay un
proceso de corrección —una revisión, un ajuste, una alerta— que ya existe fuera del sistema,
y modelarlo es más barato y más honesto que forzar una transacción distribuida. En banca
esto es especialmente cierto: la consistencia la garantiza la conciliación, no el bloqueo.

---

# 08 — Comunicación e integración

**08 → 1. ¿Qué es el acoplamiento temporal?**

⏱️ Que A necesita que B esté vivo en ese instante para poder funcionar.
🗣️ Es lo que realmente eliges al decidir síncrono o asíncrono. Con síncrono, si B está
caído, A falla. Con asíncrono, A publica y sigue; B procesa cuando pueda.
🔬 La consecuencia medible: en una cadena síncrona las disponibilidades se multiplican.
Tres servicios al 99,9 % dan 99,7 %.

**08 → 2. Nombra tres falacias de la computación distribuida.**

⏱️ La red es fiable, la latencia es cero, el ancho de banda es infinito.
🗣️ Las otras cinco: la red es segura, la topología no cambia, hay un solo administrador, el
coste de transporte es cero, la red es homogénea. Son de Peter Deutsch y James Gosling.
🔬 Su utilidad práctica: cada falacia es un fallo que tu diseño debe contemplar
explícitamente. "La red es fiable" lleva a timeouts y reintentos; "la latencia es cero"
lleva a no hacer llamadas remotas en bucle.

**08 → 3. ¿Qué garantías de entrega existen y cuál usas en la práctica?**

⏱️ At-most-once, at-least-once y exactly-once. En la práctica, at-least-once.
🗣️ At-most-once pierde mensajes y solo sirve para datos desechables como métricas.
At-least-once puede duplicar y es lo que usas casi siempre, combinado con consumidores
idempotentes. Exactly-once no existe de extremo a extremo.
🔬 La combinación correcta se llama *effectively-once*: at-least-once más deduplicación o
idempotencia en el consumidor.

**08 → 4. ¿Qué verbos HTTP son idempotentes y cuál no?**

⏱️ `GET`, `PUT`, `DELETE` y `HEAD` son idempotentes; `POST` no. `PATCH` depende de cómo lo
definas.
🗣️ Idempotente significa que N llamadas idénticas dejan el mismo estado que una. `DELETE`
lo es aunque la segunda devuelva 404: el estado final es el mismo.
🔬 `GET` además es seguro, que es más fuerte: no modifica estado en absoluto. Idempotente y
seguro no son sinónimos.

**08 → 5. ¿Por qué reintentar un `POST` es peligroso?**

⏱️ Porque no es idempotente: cada intento crea un recurso nuevo.
🗣️ Y el caso peor es el ambiguo: el servidor procesó la petición pero la respuesta se
perdió. El cliente reintenta de buena fe y el cobro se duplica.
🔬 La solución estándar es la cabecera `Idempotency-Key`: el cliente genera un
identificador único por intención, el servidor guarda el resultado asociado a esa clave, y
un reintento con la misma clave devuelve el resultado original sin ejecutar de nuevo.

**08 → 6. ¿Qué es una clave de idempotencia y quién la genera?**

⏱️ Un identificador único por intención de operación, y lo genera el cliente.
🗣️ Que lo genere el cliente es lo esencial: solo él sabe si "cobrar 100 euros" es un intento
nuevo o un reintento del anterior. Si lo generara el servidor, cada petición tendría clave
distinta y no serviría de nada.
🔬 El servidor guarda clave → resultado, con un TTL razonable. Ante una clave repetida
devuelve el resultado almacenado. Hay que decidir qué hacer si llega la misma clave con
cuerpo distinto: lo correcto es rechazar con un 422.

**08 → 7. ¿Qué diferencia hay entre compatibilidad hacia atrás y hacia adelante?**

⏱️ Hacia atrás: el consumidor nuevo lee datos viejos. Hacia adelante: el consumidor viejo
lee datos nuevos.
🗣️ En APIs síncronas suele bastar la primera, porque controlas el orden de despliegue. En
eventos importa la segunda: los mensajes viejos siguen en el topic y los consumidores viejos
siguen vivos mientras despliegas.
🔬 Compatibilidad total es ambas a la vez, y es lo que exige un despliegue rodante, donde
conviven las dos versiones durante minutos u horas.

**08 → 8. Da dos cambios de contrato seguros y dos que rompen.**

⏱️ Seguros: añadir un campo opcional, añadir un endpoint. Rompen: quitar o renombrar un
campo, cambiar el tipo de un campo.
🗣️ También seguro: ampliar el rango de valores aceptados, y marcar algo como obsoleto sin
quitarlo. También rompe: añadir un campo obligatorio, y estrechar una validación que antes
aceptaba más.
🔬 El que más engaña: añadir un valor nuevo a un `enum`. Es seguro para el productor y rompe
al consumidor que hace `switch` exhaustivo o que deserializa estrictamente.

**08 → 9. ¿En qué unidad garantiza Kafka el orden?**

⏱️ Dentro de una partición. No hay orden global entre particiones.
🗣️ Si quieres orden por entidad, usas su identificador como clave del mensaje: todos los
eventos de ese `pedidoId` van a la misma partición y se consumen en orden.
🔬 El precio: una clave con mucho tráfico crea una partición caliente y limita el
paralelismo. Y cambiar el número de particiones rompe la asignación clave→partición para los
mensajes futuros.

**08 → 10. ¿Por qué *exactly-once* no existe de extremo a extremo?**

⏱️ Porque el emisor no puede distinguir "no llegó" de "llegó y se perdió el acuse".
🗣️ Ante esa ambigüedad solo hay dos opciones: no reintentar, y entonces puedes perder; o
reintentar, y entonces puedes duplicar. No hay tercera, y ningún protocolo la inventa
porque es un límite de la información disponible, no de la implementación.
🔬 Kafka ofrece "exactly-once semantics" y es cierto **dentro** de Kafka: productor
transaccional y consumir-procesar-producir atómico. En cuanto el efecto sale del broker —tu
base de datos, un tercero, un correo— vuelves a at-least-once.

**08 → 11. ¿Qué es *effectively-once* y cómo se consigue?**

⏱️ El efecto observable ocurre una vez, aunque el mensaje llegue varias. Se consigue con
at-least-once más idempotencia.
🗣️ Cuatro formas de conseguir la idempotencia: clave de idempotencia provista por el
cliente, deduplicación por id de mensaje, reformular la operación para que sea
naturalmente idempotente, o comprobar el estado antes de actuar.
🔬 El detalle crítico: la marca de "ya procesado" debe escribirse **atómicamente con el
efecto**. Si van en transacciones distintas, un fallo entre medias deja la operación sin
hacer y marcada como hecha.

**08 → 12. ¿Cuál es el cambio que rompe y pasa todas las validaciones?**

⏱️ Cambiar la semántica sin cambiar la estructura.
🗣️ Si `estado = 3` significaba "aprobado" y ahora significa "aprobado con reservas", el
esquema es idéntico, los tests de contrato pasan y la lógica del consumidor toma decisiones
equivocadas en silencio. Es el peor porque no falla: acierta mal.
🔬 Por eso los contratos deberían expresar significado, no solo forma: `enum` con nombres en
vez de códigos numéricos, y campos nuevos en vez de reinterpretar los existentes.

**08 → 13. ¿Cuándo eliges gRPC sobre REST y cuándo al revés?**

⏱️ gRPC hacia dentro, REST hacia fuera.
🗣️ gRPC cuando es comunicación interna de alto volumen, cuando necesitas streaming, o
cuando quieres un contrato verificable entre equipos políglotas. REST cuando hay clientes de
navegador, consumidores externos, o cuando la depurabilidad con herramientas comunes importa
más que los milisegundos.
🔬 Los costes de gRPC que hay que nombrar: necesita gRPC-Web y un proxy para el navegador, el
tooling es menos ubicuo, y depurar un payload binario en producción es más incómodo.

**08 → 14. ¿Qué limita el paralelismo de un grupo de consumidores?**

⏱️ El número de particiones. Más consumidores que particiones significa consumidores
ociosos.
🗣️ Cada partición se asigna a un solo consumidor del grupo, para garantizar el orden. Por eso
el número de particiones se decide pensando en el paralelismo máximo futuro, no solo en el
actual.
🔬 Se puede aumentar el número de particiones pero no reducirlo, y aumentarlo cambia el
reparto por clave. Por eso se sobredimensiona un poco desde el principio.

**08 → 15. ¿Qué es una partición caliente y qué la causa?**

⏱️ Una partición que recibe mucho más tráfico que las demás. La causa es una clave con
distribución desigual.
🗣️ Un cliente que concentra el 30 % de los eventos, o una clave de baja cardinalidad como el
país. El consumidor de esa partición se convierte en el cuello de botella y el lag crece
solo ahí.
🔬 Soluciones: componer la clave con algo que reparta (`clienteId + tipo`), usar una clave de
mayor cardinalidad si el orden lo permite, o aceptar el desorden para esa entidad y diseñar
el consumidor para no necesitarlo.

**08 → 16. Tres servicios al 99,9 % en cadena síncrona: ¿qué disponibilidad da?**

⏱️ 99,9 % elevado al cubo, aproximadamente 99,7 %.
🗣️ Son unas 26 horas de caída al año en vez de 8,8. Cada dependencia síncrona añadida
multiplica el riesgo, y es el argumento numérico contra las cadenas largas de llamadas.
🔬 Se mitiga de tres formas: quitando el acoplamiento temporal donde se pueda (eventos),
haciendo la dependencia opcional con degradación, o cacheando su respuesta. Añadir
reintentos no cambia esta cuenta si la caída es prolongada.

**08 → 17. ¿Cómo diseñas un consumidor que no necesite orden garantizado?**

⏱️ Con versión o marca de tiempo en el evento: descartas lo que sea más viejo que lo que ya
aplicaste.
🗣️ En vez de exigir que los mensajes lleguen ordenados, el consumidor guarda la versión del
último estado aplicado por entidad y descarta los eventos con versión menor. Es idempotente
y tolerante al desorden a la vez.
🔬 La alternativa es diseñar eventos conmutativos —que dan el mismo resultado en cualquier
orden—, como incrementos en vez de asignaciones. Funciona en contadores y poco más.

**08 → 18. ¿Qué es contract testing y qué problema resuelve que el versionado no?**

⏱️ Pruebas donde el consumidor declara lo que espera y el pipeline del proveedor falla si lo
rompe. Resuelve el problema de saberlo antes de producción.
🗣️ El versionado te permite convivir con cambios incompatibles, pero no te dice si un cambio
rompe a alguien. Con contract testing, cada consumidor publica su contrato y el proveedor lo
verifica en su build: el acoplamiento se vuelve visible y verificable.
🔬 Pact y Spring Cloud Contract son las herramientas. Su valor real es organizativo: convierte
"avisa antes de cambiar" en un mecanismo automático que no depende de que alguien recuerde.

**08 → 19. ¿Por qué la deduplicación debe ser atómica con el efecto?**

⏱️ Porque si se separan, un fallo entre ambas deja la operación sin hacer y marcada como
hecha, o hecha dos veces.
🗣️ El caso concreto: marcas el id como procesado, y antes de escribir el resultado el
proceso muere. Al reintentar, el consumidor ve el id como procesado y descarta el mensaje.
El efecto nunca ocurrió y nadie lo sabe.
🔬 La solución es escribir la marca y el efecto en la misma transacción de base de datos. Si
el efecto es externo —una llamada a un tercero— no hay transacción posible, y entonces la
salida es el patrón inverso: registrar la intención antes, llamar, y registrar el resultado,
con reconciliación para los casos ambiguos.

**08 → 20. Reformula "sumar 100 al saldo" para que sea naturalmente idempotente, y di qué pierdes al hacerlo.**

⏱️ "Fijar el saldo en X" en vez de "sumar 100". Pierdes la capacidad de operar con
concurrencia y desorden.
🗣️ La asignación absoluta es idempotente: aplicarla diez veces deja el mismo resultado. Pero
requiere que el emisor conozca el saldo resultante, lo que obliga a leer antes de escribir e
introduce una condición de carrera: dos operaciones concurrentes que leen el mismo saldo y
asignan se pisan, y una se pierde silenciosamente. El incremento, en cambio, es conmutativo y
soporta concurrencia sin coordinación.
🔬 Por eso en la práctica no se reformula el saldo: se mantiene el incremento y se hace
idempotente por identidad de la operación. Cada movimiento tiene su id, se registra en una
tabla de movimientos con restricción única, y el saldo es la suma —o un campo derivado
actualizado en la misma transacción—. Reintentar inserta el mismo id, viola la restricción y
no hace nada. En banca esto no es una técnica, es cómo funciona la contabilidad: el asiento es
el hecho, el saldo es el resultado.

**08 → 21. Diseña la integración entre "pedidos" y "facturación": elige estilo, justifica y di qué falla si el otro se cae.**

⏱️ Asíncrono por eventos: pedidos publica `PedidoConfirmado` y facturación consume. El
usuario no espera la factura para que su pedido se confirme.
🗣️ La justificación es el acoplamiento temporal: facturar no es requisito para confirmar. Si
lo hiciera síncrono, una caída de facturación tumbaría la toma de pedidos, que es donde entra
el dinero. Con eventos, facturación puede estar caída una hora y luego ponerse al día. La
publicación va con outbox transaccional, para que el evento se escriba en la misma
transacción que el pedido y no se pierda si el broker no responde. Facturación consume con
idempotencia por `pedidoId`, porque la entrega es at-least-once.
🔬 Qué falla y qué no. Si facturación cae: los pedidos siguen entrando, el lag del consumidor
crece, y la única consecuencia visible es que las facturas tardan; hay que alertar sobre el
lag, no sobre el error. Si pedidos cae: no hay eventos nuevos, facturación queda ociosa, sin
daño. El caso difícil es el tercero: facturación procesa y **rechaza** un pedido —datos
fiscales inválidos—; eso no es un fallo técnico sino un resultado de negocio, y necesita su
propio evento de vuelta (`FacturacionRechazada`) y un flujo que lo gestione, no una cola de
mensajes muertos. Confundir esos dos casos es el error más común en este diseño.

**08 → 22. Tu API pública tiene 40 consumidores y necesitas renombrar un campo. ¿Cómo lo haces sin romper a nadie?**

⏱️ Expand/contract: añado el nombre nuevo, mantengo ambos, migro consumidores, y elimino el
viejo solo cuando nadie lo use.
🗣️ Las fases. Expandir: la respuesta incluye los dos campos con el mismo valor, y la petición
acepta cualquiera de los dos, con precedencia declarada si llegan ambos. Comunicar: anuncio
con fecha, marco el viejo como obsoleto en la documentación y en la cabecera `Deprecation` o
`Sunset`. Migrar: instrumento el uso del campo viejo por consumidor —con la clave de API o el
identificador de cliente— para saber exactamente quién sigue usándolo. Contraer: cuando el
contador llegue a cero y pase el plazo, lo elimino.
🔬 Tres detalles que marcan la diferencia. Primero: sin telemetría por consumidor, la fase de
contraer es una apuesta; medir quién usa qué es lo que convierte esto en un proceso y no en un
rezo. Segundo: con 40 consumidores habrá alguno que nunca migre, así que hace falta una
política de obsolescencia acordada de antemano —cuánto tiempo se mantiene— o el campo viejo
será eterno. Tercero: si el cambio fuera realmente incompatible y no cosmético, la respuesta
sería otra: `/v2` conviviendo con `/v1`, con fecha de fin de soporte. Renombrar un campo no
justifica una versión nueva; cambiar su significado, sí.

---

# 09 — Resiliencia

**09 → 1. ¿Cuáles son los tres estados de un circuit breaker?**

⏱️ Cerrado, abierto y semiabierto.
🗣️ Cerrado deja pasar todo y cuenta fallos. Al superar el umbral pasa a abierto y falla
inmediato sin llamar. Tras un tiempo pasa a semiabierto, deja pasar unas pocas peticiones de
prueba y decide: si van bien, cierra; si fallan, vuelve a abrir.
🔬 El umbral moderno es un porcentaje de fallos sobre una ventana deslizante, por conteo o
por tiempo, no "N fallos seguidos".

**09 → 2. ¿Qué es el bulkhead y de dónde viene el nombre?**

⏱️ Aislar recursos por dependencia. Viene de los mamparos estancos de un barco.
🗣️ En la práctica: un pool de hilos o un semáforo por dependencia. Si el catálogo agota sus
10 hilos, quedan los 40 del resto y el servicio sigue atendiendo lo demás.
🔬 El mismo principio a otras escalas: instancias separadas para tráfico crítico y no
crítico, o celdas de clientes aisladas entre sí.

**09 → 3. ¿Qué diferencia hay entre connect timeout y read timeout?**

⏱️ El primero limita establecer la conexión; el segundo, esperar la respuesta.
🗣️ El connect timeout debe ser bajo, uno o dos segundos: establecer una conexión es rápido o
no va a pasar. El read timeout depende del caso de uso y se calcula desde el p99 del servicio
llamado.
🔬 Hay un tercero que se olvida: el tiempo de espera para obtener una conexión del pool. Con
el pool agotado, las peticiones se quedan encoladas indefinidamente aunque los otros dos
timeouts estén bien puestos.

**09 → 4. ¿Por qué un servicio lento es peor que uno caído?**

⏱️ Porque consume tus recursos mientras esperas. Uno caído falla rápido y lo gestionas.
🗣️ Un servicio que tarda 30 segundos retiene tus hilos 30 segundos. Con suficiente tráfico,
el pool se agota y dejas de responder a todo, no solo a lo que dependía de él. El fallo se
propaga a peticiones que no tenían nada que ver.
🔬 Por eso el timeout es la primera línea de defensa: convierte lentitud en fallo rápido,
que es algo que sí sabes manejar.

**09 → 5. ¿Para qué sirve el estado semiabierto?**

⏱️ Para probar si el servicio se recuperó sin mandarle toda la carga de golpe.
🗣️ Sin él, el breaker no tendría forma de saber cuándo volver, o volvería abriendo la
compuerta entera contra un servicio que apenas se está levantando y lo tumbaría otra vez.
🔬 Es un mecanismo de sondeo controlado: número limitado de llamadas de prueba, y decisión
basada en su resultado.

**09 → 6. ¿Qué es el thundering herd?**

⏱️ Una masa de clientes golpeando a la vez el mismo recurso tras un evento común.
🗣️ Ocurre tras una caída con reintentos sincronizados, al expirar una entrada de caché muy
consultada, o al arrancar muchas instancias a la vez. El recurso, que estaba recuperándose,
vuelve a caer.
🔬 Mitigaciones según el caso: jitter en los reintentos, TTL de caché con variación
aleatoria, bloqueo o *request coalescing* para que solo uno recalcule y los demás esperen su
resultado.

**09 → 7. ¿Qué requisito debe cumplir una operación para poder reintentarse?**

⏱️ Ser idempotente.
🗣️ Si no lo es, reintentar duplica el efecto: dos cobros, dos pedidos, dos correos. Y el
caso ambiguo —se ejecutó pero se perdió la respuesta— es indistinguible del fallo real.
🔬 Si la operación no es idempotente por naturaleza, se hace idempotente con una clave de
idempotencia antes de habilitar reintentos. El orden importa: primero la clave, después el
reintento.

**09 → 8. ¿Qué diferencia hay entre rate limiting y backpressure?**

⏱️ Rate limiting rechaza lo que sobra; backpressure pide que no lo manden.
🗣️ El primero es protección hacia fuera: tú decides cuántas peticiones aceptas y devuelves
429 al resto. El segundo es una señal hacia atrás en la tubería: el consumidor indica su
capacidad y el productor reduce el ritmo.
🔬 Backpressure requiere que el productor coopere, así que solo funciona en protocolos que lo
soportan: Reactive Streams, TCP, el modelo de *pull* de un consumidor de Kafka. Con HTTP
clásico no hay backpressure, solo rate limiting.

**09 → 9. ¿Qué diferencia hay entre token bucket y leaky bucket?**

⏱️ Token bucket permite ráfagas hasta el tamaño del cubo; leaky bucket alisa la salida a
tasa constante.
🗣️ Token bucket acumula permisos mientras no hay tráfico, así que tolera picos cortos: suele
ser lo que quieres en una API. Leaky bucket procesa a ritmo fijo y encola o descarta el
exceso: sirve cuando lo que proteges no tolera ráfagas.
🔬 Hay dos más que conviene conocer: ventana fija, simple pero con el problema del borde —dos
ráfagas a ambos lados del corte duplican el límite efectivo—, y ventana deslizante, que lo
corrige.

**09 → 10. ¿Por qué el jitter no es opcional en un reintento?**

⏱️ Porque sin él todos los clientes reintentan en el mismo instante y creas picos
sincronizados.
🗣️ Mil clientes que fallan a la vez y reintentan a 1, 2 y 4 segundos producen tres oleadas
de mil peticiones contra un servicio que se estaba recuperando. El reintento empeora la
caída en vez de mitigarla.
🔬 La variante recomendada es *full jitter*: esperar un valor aleatorio entre cero y el
backoff calculado. Reparte mejor que sumar un pequeño ruido al valor fijo.

**09 → 11. ¿A quién protege un circuit breaker?**

⏱️ Al llamante, de agotar sus recursos esperando a una dependencia que falla.
🗣️ Es el malentendido más común: no está para "no molestar" al servicio caído, aunque ese
sea un efecto lateral útil. Está para que tú dejes de gastar hilos, conexiones y tiempo en
llamadas que sabes que van a fallar.
🔬 Si lo que quieres es proteger al de abajo de sobrecarga, la herramienta es rate limiting
en el lado del llamado, no un breaker en el del llamante.

**09 → 12. ¿Cómo se calcula el valor de un timeout?**

⏱️ Desde el p99 del servicio llamado, con algo de margen. No a ojo.
🗣️ Si el p99 es 200 ms, un timeout de un segundo deja margen para anomalías y corta lo
patológico. Un timeout de 30 segundos significa aceptar un hilo bloqueado medio minuto, que
es lo que agota el pool.
🔬 Y debe encajar en el presupuesto de la cadena: si tu cliente espera 2 segundos y tienes
dos dependencias en serie, sus timeouts sumados más tu procesamiento tienen que caber en ese
presupuesto.

**09 → 13. ¿Por qué tu timeout debe ser menor que el de quien te llama?**

⏱️ Porque si no, cuando respondas ya nadie estará escuchando.
🗣️ El cliente habrá abandonado y quizá reintentado, mientras tú sigues ocupando un hilo y
una conexión para producir una respuesta que se descarta. Gastas recursos en trabajo inútil
justo cuando más falta te hacen.
🔬 La forma sistemática de resolverlo es propagar el presupuesto de tiempo: cada salto pasa
cuánto tiempo queda, y quien recibe ajusta su timeout a ese resto. gRPC lo tiene nativo con
*deadlines*.

**09 → 14. Reintentar en tres capas con tres intentos: ¿cuántas peticiones salen?**

⏱️ Veintisiete.
🗣️ Tres por tres por tres. Una petición del usuario se convierte en 27 contra el servicio del
fondo, que ya estaba mal. Es el efecto multiplicador del reintento, y convierte un problema
menor en una caída.
🔬 La regla: se reintenta en un solo nivel, normalmente el más cercano al fallo, y los demás
fallan rápido. Se acompaña de un presupuesto de reintentos global —un porcentaje máximo del
tráfico— para que no se dispare bajo fallo masivo.

**09 → 15. ¿Cuándo NO debe degradar un servicio?**

⏱️ Cuando el dato degradado puede tomarse por bueno y causar daño. En banca, cifras
financieras.
🗣️ Mostrar un saldo desactualizado sin avisar es peor que mostrar un error: el usuario toma
decisiones con él. Lo mismo con un resultado de riesgo, un límite de crédito o una posición
de inversión. Ahí se falla explícito, o se muestra el dato con su marca de tiempo y un aviso
claro.
🔬 La decisión de qué degrada es de negocio, no técnica. El trabajo del arquitecto es
presentar la lista de candidatos y volver con la decisión firmada.

**09 → 16. ¿Qué problema tiene un fallback que devuelve lista vacía?**

⏱️ Que convierte un incidente visible en datos incorrectos silenciosos.
🗣️ El usuario ve "no hay resultados" y concluye que no existen, cuando lo cierto es que el
sistema no pudo consultarlos. Y para el equipo no hay error en las métricas, así que el
incidente pasa desapercibido hasta que alguien se queja.
🔬 Si degradas, el fallback se registra con su propia métrica y se alerta sobre su tasa. Y la
interfaz debe distinguir "no hay datos" de "no pudimos consultarlos".

**09 → 17. ¿Qué debe y qué no debe comprobar un health check?**

⏱️ El readiness debe comprobar las dependencias críticas; el liveness solo que el proceso
está sano.
🗣️ Si el liveness comprueba la base de datos y esta cae, el orquestador reinicia todos los
pods en bucle por un problema que no está en ellos. Y si el readiness no comprueba nada, el
balanceador manda tráfico a instancias que no pueden atenderlo.
🔬 Regla adicional: el readiness no debe comprobar dependencias **no** críticas ni de
terceros. Si lo hace, la caída de un proveedor secundario saca de servicio toda tu flota.

**09 → 18. ¿Cuándo un circuit breaker no aporta nada?**

⏱️ Cuando la dependencia es imprescindible y no hay alternativa ni degradación posible.
🗣️ Abrir el circuito contra tu única base de datos solo convierte una caída en otra caída
más rápida: no hay nada que hacer con el fallo salvo devolverlo. Ahí lo que aporta es
timeout, pool dimensionado y bulkhead.
🔬 Tampoco aporta con muy poco tráfico: no hay suficientes muestras para que el umbral sea
estadísticamente significativo, y el breaker oscila.

**09 → 19. Narra la cadena completa por la que un servicio secundario lento tumba una plataforma, y di dónde la cortarías.**

⏱️ Catálogo se pone lento, los hilos de pedidos se bloquean esperando, el pool se agota,
pedidos deja de responder a todo, el balanceador lo saca, la carga va al resto y cae en
cascada. Lo corto en el paso dos, con timeout y bulkhead.
🗣️ El detalle de cada eslabón. Catálogo no falla: tarda 30 segundos, que es peor. Cada
petición de pedidos que lo consulta retiene un hilo esos 30 segundos; con 50 peticiones por
segundo y un pool de 200, el pool se agota en cuatro segundos. A partir de ahí pedidos no
responde ni a los endpoints que no tocan catálogo, porque el recurso agotado es compartido.
El health check falla, el balanceador saca la instancia, y su carga se reparte entre las
demás, que se agotan más rápido. En quince minutos no queda ninguna.
🔬 Dónde cortarla, en orden de eficacia. Primero bulkhead: un pool de 10 hilos dedicado a
catálogo hace que el daño quede acotado a 10 hilos y el resto del servicio siga vivo — esto
solo ya rompe la cadena en el paso tres. Segundo, timeout de un segundo: convierte 30
segundos de bloqueo en un fallo rápido y liberas el hilo. Tercero, circuit breaker: tras
detectar la tasa de fallo, deja de llamar y no gastas ni ese segundo. Cuarto, degradación:
catálogo no es crítico para mostrar un pedido, así que la respuesta sin datos de catálogo es
aceptable si se marca como tal. Y quinto, revisar el health check para que no saque la
instancia por una dependencia secundaria.

**09 → 20. Tras cada incidente el sistema se recupera y vuelve a caer en ciclos. ¿Qué diagnosticas?**

⏱️ Reintentos sin jitter o breaker mal calibrado: la carga acumulada golpea de golpe al
recuperarse.
🗣️ El patrón es característico. Mientras el servicio está caído, los clientes acumulan
reintentos y trabajo pendiente. En cuanto responde, recibe toda esa carga acumulada más el
tráfico normal, se satura otra vez y vuelve a caer. Si además el breaker pasa de abierto a
cerrado de golpe, la compuerta se abre entera contra un servicio que apenas arranca.
🔬 Qué mirar para confirmarlo: el gráfico de peticiones por segundo debe mostrar picos
sincronizados justo tras cada recuperación, muy por encima del tráfico base. Las correcciones:
full jitter en los reintentos, presupuesto de reintentos que los limite a un porcentaje del
tráfico, semiabierto con pocas llamadas de prueba y vuelta gradual, y del lado del servicio
que se recupera, rate limiting propio para no aceptar más de lo que puede. Una causa vecina
que hay que descartar: caída de caché, donde al reiniciar todo va a la base de datos hasta
que la caché se repuebla.

**09 → 21. Diseña la resiliencia de una llamada a un scoring externo poco fiable: timeout, reintento, breaker, fallback, con valores concretos.**

⏱️ Timeout de 5 s (p99 de 4 s más margen), un solo reintento con full jitter, breaker al 50 %
sobre ventana de 20 llamadas, y fallback a regla conservadora local con cola de revisión.
🗣️ Los valores y su porqué. Connect timeout 2 s, read timeout 5 s: el p99 declarado es 4 s,
así que menos cortaría respuestas legítimas y más retendría hilos sin motivo. Un solo
reintento, no tres: con un p99 de 4 segundos, tres intentos son 15 segundos de espera y el
usuario ya no está; además su SLA es del 99 %, así que los fallos son frecuentes y
reintentar mucho multiplica la carga. Full jitter entre 0 y 2 s. Breaker: umbral del 50 % de
fallos sobre una ventana deslizante de 20 llamadas, 30 s en abierto, 5 llamadas de prueba en
semiabierto. Bulkhead de 20 hilos dedicados, para que su lentitud no toque el resto.
🔬 El fallback es la parte de negocio y es la que de verdad decide el diseño. Siete horas de
caída al mes es mucho, así que no puede ser un error: acuerdo con riesgo una regla
conservadora local —límite reducido, o aprobación condicionada— que se aplica cuando el
scoring no responde, y **la solicitud se marca** como decidida sin scoring y entra en una cola
de revisión para reevaluar cuando el proveedor vuelva. Tres detalles más: caché de las
respuestas por documento durante unas horas, porque el scoring de una persona no cambia en un
día y eso absorbe buena parte de la indisponibilidad; una capa anticorrupción para que su
modelo no entre en mi dominio; y métricas separadas de "rechazado por riesgo" frente a
"decidido sin scoring", porque confundirlas hace invisible el problema.

**09 → 22. Tras un incidente aparecen cobros duplicados. Reconstruye qué pasó y qué faltaba.**

⏱️ Se reintentó una operación no idempotente. Faltaba clave de idempotencia y deduplicación
atómica en el receptor.
🗣️ La reconstrucción más probable: el servicio de pagos se puso lento y superó el timeout del
llamante, pero **sí procesó** la petición. El llamante interpretó el timeout como fallo y
reintentó. Como el `POST` de cobro no llevaba clave de idempotencia, el segundo intento creó
un cobro nuevo. Si además había reintentos en varias capas, el mismo cobro pudo repetirse
más de dos veces. Lo confirmo buscando cobros del mismo importe, mismo cliente y marcas de
tiempo separadas por el intervalo de reintento.
🔬 Qué faltaba, en tres niveles. En el contrato: cabecera `Idempotency-Key` generada por el
llamante, con el servidor guardando clave → resultado y devolviendo el original ante una
repetición. En la implementación: esa marca debe escribirse en la misma transacción que el
cobro, o vuelves a tener la ventana. Y en la política de reintentos: no se reintenta una
operación no idempotente, punto; si el timeout deja la operación en estado ambiguo, la salida
correcta es consultar el estado antes de reintentar, o dejarlo a un proceso de conciliación.
La lección general que diría en voz alta: un timeout no significa que la operación no
ocurrió, significa que **no sabes** si ocurrió, y esas dos cosas se tratan distinto.

---

# 10 — Alta disponibilidad y escalado

**10 → 1. ¿Qué diferencia hay entre escalar vertical y horizontal?**

⏱️ Vertical es una máquina más grande; horizontal es más máquinas.
🗣️ Vertical no requiere cambios en la aplicación pero tiene techo y coste superlineal.
Horizontal es prácticamente ilimitado y de coste lineal, pero exige que el servicio no tenga
estado y añade balanceo y coherencia.
🔬 La diferencia que más se olvida: solo el horizontal mejora la disponibilidad. Una máquina
grande sigue siendo un punto único de fallo.

**10 → 2. ¿Qué es RTO y qué es RPO?**

⏱️ RTO es cuánto tiempo puedes estar caído; RPO es cuántos datos puedes permitirte perder.
🗣️ Son objetivos de negocio, no técnicos: los fija quien asume el coste de la caída y el de
la pérdida. La arquitectura se deriva de ellos, no al revés.
🔬 RPO cero exige replicación síncrona, que cuesta latencia en cada escritura. Un backup
nocturno significa RPO de 24 horas, y decirlo en voz alta suele bastar para que negocio
reconsidere.

**10 → 3. ¿Cuánta caída al mes permite un 99,99 %?**

⏱️ Unos 4,3 minutos al mes; algo menos de 53 minutos al año.
🗣️ El dato importante no es la cifra sino su consecuencia: cuatro minutos es menos de lo que
tarda una persona en recibir la alerta y conectarse. A ese nivel la recuperación tiene que
ser automática, y eso cambia la arquitectura entera.
🔬 Referencias: 99,9 % son 43 minutos al mes; 99 %, unas 7,2 horas; 99,999 %, 26 segundos.

**10 → 4. ¿Por qué "escalo horizontalmente" es una respuesta incompleta?**

⏱️ Porque solo funciona si cualquier instancia puede atender cualquier petición, y eso exige
que el estado esté fuera.
🗣️ La respuesta completa es: escalo horizontalmente, y puedo porque el servicio no tiene
estado; y no lo tiene porque la sesión está en Redis, los ficheros en almacenamiento de
objetos y las tareas programadas coordinadas.
🔬 Es la pregunta de seguimiento garantizada, y quien no la anticipa deja ver que no lo ha
hecho.

**10 → 5. ¿Qué diferencia hay entre liveness y readiness?**

⏱️ Liveness pregunta si el proceso está sano —si falla, se reinicia—. Readiness pregunta si
puede atender ahora —si falla, se saca del balanceo—.
🗣️ La consecuencia de confundirlos es concreta: si el liveness comprueba la base de datos y
esta cae, el orquestador reinicia toda la flota por un problema externo, y el reinicio no
arregla nada.
🔬 Hay un tercero en Kubernetes, el startup probe, que evita que el liveness mate a una
aplicación que simplemente tarda en arrancar — caso frecuente en Spring Boot.

**10 → 6. Nombra cuatro sitios donde se esconde el estado que impide escalar.**

⏱️ La sesión HTTP en memoria, ficheros en disco local, caché local de la aplicación y las
tareas programadas.
🗣️ Sus salidas: Redis con Spring Session o tokens sin estado; almacenamiento de objetos;
caché distribuida o aceptar la incoherencia midiéndola; y ShedLock o elección de líder para
que la tarea se ejecute una sola vez.
🔬 El de las tareas es el que más sorprende: escalas a tres instancias y el proceso nocturno
se ejecuta tres veces. Hay un quinto sitio menos obvio: los contadores y secuencias en
memoria.

**10 → 7. ¿Por qué escalar vertical no da alta disponibilidad?**

⏱️ Porque sigue habiendo una sola máquina: si cae, cae todo.
🗣️ Alta disponibilidad requiere redundancia, y una máquina más grande no es redundante. El
mantenimiento del anfitrión, un fallo de hardware o un reinicio del sistema operativo siguen
siendo caídas totales.
🔬 Lo que sí aporta el vertical: más capacidad sin tocar la aplicación, y es reversible en
minutos. Para bases de datos relacionales sigue siendo la primera respuesta correcta hasta
un punto bastante alto.

**10 → 8. ¿Qué pregunta desmonta la mayoría de los planes de recuperación?**

⏱️ ¿Cuándo fue la última vez que restauraron un backup?
🗣️ Casi siempre la respuesta es "nunca" o "hace años". Un backup que nunca se ha restaurado
no está verificado: puede estar corrupto, incompleto, cifrado con una clave perdida, o tardar
mucho más de lo que el RTO permite.
🔬 La siguiente pregunta es igual de buena: ¿cuánto tardó? Porque el RTO no se cumple con la
existencia del backup sino con el tiempo total de restauración, que incluye localizarlo,
traerlo y validarlo.

**10 → 9. ¿Qué pasa con un `@Scheduled` cuando escalas a tres instancias?**

⏱️ Se ejecuta tres veces, una por instancia.
🗣️ Según lo que haga, eso significa tres correos al cliente, tres ficheros generados o tres
cargos duplicados. Es uno de los fallos más comunes al escalar por primera vez, y no da
error: simplemente duplica.
🔬 Soluciones: ShedLock, que usa un bloqueo en base de datos o Redis para que solo una
instancia ejecute; un planificador externo que dispare por HTTP a una sola instancia; o
Quartz en modo clúster. Y en cualquier caso, la tarea debería ser idempotente.

**10 → 10. ¿Por qué CPU es una mala métrica de autoescalado?**

⏱️ Porque un servicio bloqueado en entrada/salida está saturado con la CPU baja.
🗣️ La mayoría de los servicios de negocio pasan el tiempo esperando a la base de datos o a
otro servicio. Cuando el pool de hilos está agotado y los usuarios ven timeouts, la CPU
puede estar al 15 % y el autoescalado no reacciona.
🔬 Mejores métricas, de más a menos útil: longitud de cola o lag del consumidor, peticiones
por segundo por instancia, latencia p99, y utilización del pool de conexiones o de hilos.

**10 → 11. ¿Qué métrica de autoescalado es la mejor y por qué?**

⏱️ La longitud de cola o el lag del consumidor, porque mide directamente el trabajo
pendiente.
🗣️ Es una medida de demanda insatisfecha, no una aproximación indirecta como la CPU. Si el
lag crece, faltan consumidores; si baja, sobran. La relación con la acción es directa.
🔬 En servicios HTTP sin cola explícita, el equivalente es peticiones por segundo por
instancia, calibrado con una prueba de carga para saber cuántas aguanta una.

**10 → 12. ¿Qué son las sticky sessions y qué precio tienen?**

⏱️ Que el balanceador manda siempre al mismo usuario a la misma instancia. El precio es
reparto desigual y pérdida de sesión al caer el nodo.
🗣️ Permiten escalar sin sacar la sesión del proceso, y por eso se usan como parche. Pero
impiden el reparto uniforme de carga, complican los despliegues rodantes —cada instancia
retirada pierde sus sesiones— y no resuelven el problema de fondo.
🔬 Es una muleta, no una solución. La solución es sesión externa o sin estado. Aun así, hay un
caso legítimo: afinidad para aprovechar una caché local caliente, donde perderla degrada pero
no rompe.

**10 → 13. ¿Qué pasa si pones la comprobación de BD en el liveness?**

⏱️ Que cuando la base de datos caiga, el orquestador reiniciará todos los pods en bucle.
🗣️ Y el reinicio no arregla nada, porque el problema está fuera. Peor aún: al volver la base
de datos, se encuentra con toda la flota arrancando a la vez y abriendo conexiones de golpe,
lo que puede tumbarla otra vez.
🔬 Lo correcto: liveness comprueba solo que el proceso responde y no está en un estado
irrecuperable; readiness comprueba las dependencias críticas para decidir si recibe tráfico.

**10 → 14. ¿Qué es el presupuesto de error y para qué sirve?**

⏱️ La cantidad de caída que tu objetivo de disponibilidad te permite gastar en un periodo.
🗣️ Con un objetivo de 99,9 %, tienes 43 minutos al mes. Mientras quede presupuesto se
despliega y se experimenta; cuando se agota, se congelan las funcionalidades nuevas y el
esfuerzo va a fiabilidad.
🔬 Su valor es que convierte una discusión de opiniones —"hay que ir más rápido" contra "hay
que ser más estables"— en una regla acordada de antemano con un número. Viene del libro de
SRE de Google.

**10 → 15. ¿Qué límite real suele encontrar el escalado antes que la CPU?**

⏱️ El pool de conexiones a la base de datos.
🗣️ Escalar la capa de aplicación a 50 instancias con 20 conexiones cada una son 1.000
conexiones contra una base de datos que admite 200. El escalado se convierte en una
denegación de servicio a tu propia base de datos.
🔬 Salidas: un *pooler* intermedio como PgBouncer, reducir el pool por instancia, mover
lecturas a réplicas, o cachear. Otros límites frecuentes: límites de tasa de terceros,
número de particiones de un topic, y cuotas de la nube.

**10 → 16. ¿Qué exige un RPO de cero y qué cuesta?**

⏱️ Replicación síncrona, y cuesta latencia en cada escritura.
🗣️ Cada commit debe confirmarse en al menos otra ubicación antes de responder. Dentro de una
misma región, con zonas a un milisegundo, es asumible. Entre regiones separadas por miles de
kilómetros, la latencia de ida y vuelta se suma a **todas** las escrituras.
🔬 Por eso lo habitual es RPO cero entre zonas y RPO de segundos entre regiones con
replicación asíncrona. Y conviene preguntar qué datos necesitan RPO cero: casi nunca son
todos.

**10 → 17. ¿Cuál es el problema real de una arquitectura activo-activo?**

⏱️ El dato, no la infraestructura: si ambas regiones aceptan escrituras sobre el mismo
registro, hay conflictos.
🗣️ Resolver conflictos exige una política —gana la última escritura, gana la mayor, se marca
para revisión manual— y esa política es una decisión de negocio con consecuencias visibles
para el usuario. En dominios donde no se puede perder una escritura, no hay política
aceptable.
🔬 La salida habitual, y la que propondría en banca: particionar por cliente o por región, de
modo que cada registro tenga una sola región dueña que acepta sus escrituras. Es
activo-activo a nivel de plataforma y activo-pasivo a nivel de registro, y elimina el
conflicto por diseño.

**10 → 18. ¿Por qué azul-verde no resuelve los cambios de esquema?**

⏱️ Porque los dos entornos comparten la misma base de datos.
🗣️ Azul-verde duplica la capa de aplicación, no los datos. Durante el cambio, y hasta que
descartas el entorno viejo, ambas versiones del código leen y escriben el mismo esquema. Si
la nueva versión renombró una columna, la vieja se rompe.
🔬 Duplicar también los datos significaría replicarlos y sincronizarlos en ambos sentidos, que
es un problema mucho mayor que el que intentabas resolver. Por eso el esquema debe ser
compatible con las dos versiones, igual que en un despliegue rodante.

**10 → 19. ¿Qué es el patrón expand/contract en migraciones de esquema?**

⏱️ Expandir el esquema, migrar en varios despliegues y contraerlo al final, para que nunca
haya un momento incompatible.
🗣️ La secuencia para renombrar una columna: añadir la nueva; desplegar código que escribe en
ambas y lee de la nueva con respaldo en la vieja; migrar los datos existentes; desplegar
código que solo usa la nueva; y por último borrar la vieja. Son cuatro o cinco despliegues
donde la intuición pedía uno.
🔬 Regla que se deriva: nunca se despliega un cambio destructivo de esquema en el mismo
release que el código que lo necesita. Y la fase de contraer requiere verificar que nadie
usa lo viejo, no suponerlo.

**10 → 20. Te piden 99,999 %. ¿Qué respondes y qué preguntas antes?**

⏱️ Pregunto qué cuesta un minuto de caída y si el objetivo aplica a todo el sistema o a un
flujo concreto. Casi siempre es lo segundo.
🗣️ Cinco nueves son 26 segundos de caída al mes: ningún humano interviene en ese tiempo, así
que toda la detección y recuperación debe ser automática, y hace falta multi-región activo.
También hay que contar las dependencias: si dependes de un proveedor con SLA del 99,9 %, tu
techo es ese, hagas lo que hagas. Y el mantenimiento planificado cuenta como caída salvo que
sea sin interrupción, lo que obliga a despliegues sin caída y migraciones expand/contract.
🔬 Mi respuesta completa: propongo separar por flujo. Que la consulta de saldo sea 99,99 % y
la generación de informes 99,5 % es más barato y más honesto que un número único para todo. Y
llevo la cuenta del coste: pasar de 99,9 a 99,99 suele multiplicar el gasto de
infraestructura y de guardia, y ese número, puesto al lado del coste de la caída, hace que
negocio decida bien. Muchas veces "cinco nueves" significa "no quiero incidentes visibles",
que es un problema distinto y a menudo más barato de resolver.

**10 → 21. Escalas a 50 instancias y el sistema empeora. Da tres hipótesis ordenadas.**

⏱️ Agotamiento del pool de conexiones a la base de datos, contención en un recurso
compartido, o un cuello de botella aguas abajo.
🗣️ Primera y más probable: 50 instancias multiplicadas por su pool superan el máximo de
conexiones de la base de datos; las instancias esperan conexión, los timeouts se disparan, y
la base de datos gasta recursos gestionando conexiones en vez de consultas. Segunda:
contención sobre una fila o tabla caliente —un contador, una secuencia, un bloqueo
pesimista—; más instancias significan más competidores por el mismo bloqueo y el throughput
baja. Tercera: el cuello está fuera, en un tercero con límite de tasa o en un servicio que
ahora recibe 50 veces más llamadas y se degrada, devolviéndote latencia.
🔬 Cómo las distingo, en ese orden: miro conexiones activas y en espera en la base de datos y
el tiempo de adquisición del pool; luego esperas de bloqueo y conflictos de versión; luego
latencia y tasa de error por dependencia. Hay una cuarta hipótesis que conviene tener: si hay
caché local por instancia, 50 instancias significan 50 cachés frías y una tasa de acierto
mucho peor, así que toda la carga va al origen. Y una quinta, organizativa: puede que el
escalado fuera automático por CPU y que la CPU alta fuera síntoma, no causa.

**10 → 22. Diseña el despliegue sin caída de un cambio que renombra una columna usada por tres servicios.**

⏱️ Expand/contract coordinado: añadir la columna nueva, escribir en ambas, migrar datos,
mover lecturas servicio a servicio, y borrar la vieja al final.
🗣️ La secuencia concreta. Paso 1: migración que añade la columna nueva, nullable, sin tocar
la vieja; es compatible con todo el código actual. Paso 2: despliegue en los tres servicios
—o en el dueño de la escritura, si solo uno escribe— de código que **escribe en ambas** y
sigue leyendo la vieja. Paso 3: migración de datos de la columna vieja a la nueva para los
registros históricos, por lotes para no bloquear. Paso 4: despliegue que **lee de la nueva**,
servicio a servicio, verificando entre uno y otro. Paso 5: despliegue que deja de escribir en
la vieja. Paso 6: tras un periodo de observación, migración que borra la columna vieja.
🔬 Los detalles que hacen que funcione. El orden entre servicios importa: primero el que
escribe, después los que leen; si varios escriben, todos deben estar en el paso 2 antes de
que ninguno pase al 4. Entre el paso 3 y el 4 hay que verificar que ambas columnas coinciden
—una consulta de conteo de discrepancias, ejecutada periódicamente—, porque escrituras
concurrentes durante la migración pueden dejar huecos. El paso 6 no se hace hasta comprobar
por telemetría que nadie la usa, no por suposición. Y si algo sale mal en cualquier paso, la
vuelta atrás es desplegar la versión anterior, que sigue siendo compatible: esa es toda la
gracia del patrón.

**10 → 23. Un banco pide activo-activo entre dos regiones para cuentas. ¿Qué problemas planteas y qué alternativa propones?**

⏱️ El problema es la escritura concurrente sobre la misma cuenta en dos regiones. Propongo
particionar por cuenta: cada cuenta tiene una región dueña.
🗣️ Los problemas que planteo, en orden. Uno: si ambas regiones aceptan movimientos sobre la
misma cuenta, dos débitos concurrentes pueden dejar el saldo en negativo, y ninguna política
de resolución de conflictos es aceptable cuando hablamos de dinero — "gana la última
escritura" significa perder un movimiento. Dos: la replicación síncrona entre regiones añade
la latencia de ida y vuelta a cada escritura, que para un core transaccional es prohibitivo.
Tres: hay requisitos regulatorios de residencia y de trazabilidad que complican tener el
mismo dato escribible en dos jurisdicciones.
🔬 Mi alternativa: activo-activo a nivel de plataforma, activo-pasivo a nivel de registro.
Cada cuenta se asigna a una región dueña —por rango de identificador o por sucursal— y esa
región acepta sus escrituras; la otra tiene una réplica de solo lectura y puede servir
consultas, que son la mayoría del tráfico. Ambas regiones están activas, procesan trabajo real
y se usan de verdad, lo que resuelve el problema clásico del pasivo que nunca se ha probado.
Ante la caída de una región, se promueve la otra como dueña de esas cuentas con un
procedimiento explícito y ensayado. El RPO no es cero: es el retraso de la replicación, del
orden de segundos, y eso se declara y se acepta, o se compra replicación síncrona solo para
las cuentas que lo justifiquen. Y declaro lo que esto cuesta: el enrutamiento por cuenta
añade complejidad en el borde, y hay que resolver qué pasa con las transferencias entre
cuentas de regiones distintas — que vuelve a ser una saga.

---

# 11 — Simulación: escenarios de diseño

> Las preguntas `S#` del bloque 2 de [`11`](11-simulacion-de-entrevista.md) se responden
> con las entradas de los capítulos correspondientes, que están arriba. Aquí van los seis
> escenarios, que sí llevan solución desarrollada.

## E1 — El que NO debe separarse

**Respuesta corta:** no separo. Propongo modularizar dentro del monolito y fijar por
adelantado el disparador objetivo que me haría cambiar de opinión.

**Los números que uso.** 200 pólizas al día son unas 25 por hora en horario laboral: no hay
problema de escala. Doce desarrolladores caben en dos o tres equipos que pueden coordinarse
sin bloquearse. Un despliegue quincenal sin incidencias indica que el pipeline no es un
cuello de botella. Y cotización, suscripción, emisión y cobro en una transacción es
precisamente el tipo de consistencia que separar destruiría: con microservicios, esa
transacción se convierte en una saga con compensaciones, y una póliza emitida sin cobrar es
un problema contable real.

**Lo que propongo en su lugar.** Modularizar: cada capacidad como módulo con API explícita y
tablas propias, verificado con Spring Modulith o ArchUnit. Eso da fronteras, propiedad clara
y prepara la extracción futura, sin pagar latencia, consistencia eventual ni plataforma.

**El disparador acordado.** Digo en qué condiciones separaría: si algún módulo necesita un
perfil de escalado distinto, si los equipos empiezan a bloquearse en el pipeline, o si una
capacidad necesita un ciclo de despliegue propio por regulación. Y separaría **ese** módulo,
no el sistema.

**Cómo lo digo al CTO.** No "no", sino "todavía no, y este es el criterio objetivo". El
argumento que suele funcionar: la factura operativa de microservicios se paga completa desde
el primer servicio, y con 200 pólizas al día no hay ingreso que la amortice.

## E2 — Consistencia distribuida inevitable

**Respuesta corta:** saga orquestada, con `Reserva` como agregado propio, compensaciones
explícitas y estado visible para el usuario.

**El flujo feliz.** Un orquestador —un servicio de `Reservas`— dirige: reservar asiento →
reservar equipaje → cobrar → confirmar. Cada paso es un comando con el `reservaId` como clave
de idempotencia, y cada servicio responde con un evento.

**Los fallos parciales y sus compensaciones.**

```text
Falla asiento      → nada que compensar. Se rechaza y se avisa.
Falla equipaje     → compensar: liberar asiento.
Falla cobro        → compensar: liberar equipaje y asiento.
Falla confirmación → reintentar; el cobro ya está hecho y NO se revierte a ciegas.
```

**Por qué orquestada y no coreografiada.** Con cuatro pasos, compensaciones y un estado que
el usuario consulta, la coreografía dispersa la lógica en cuatro servicios y nadie sabe en
qué punto está una reserva. La orquestación centraliza el flujo en un sitio, que es lo que
quieres cuando hay dinero y compensaciones. La coreografía gana cuando los pasos son
independientes y no hay que deshacerlos.

**Lo que hay que decir sí o sí.** Primero: las reservas de asiento y equipaje son
**temporales con TTL**, no definitivas; si la saga muere sin compensar, expiran solas. Eso es
lo que salva el diseño cuando el orquestador se cae en medio. Segundo: el cobro no se
compensa con un borrado sino con un reembolso, que es otra operación con su propio
identificador. Tercero: el usuario ve estado —"procesando"— y no una pantalla bloqueada; la
confirmación llega por notificación. Y cuarto: cada paso es idempotente, porque la entrega es
at-least-once y el orquestador reintenta.

**El caso que descoloca.** Si el cobro tiene éxito y la confirmación falla repetidamente, no
se revierte automáticamente: se marca para intervención y se alerta. Revertir un cobro
correcto por un fallo de infraestructura es peor que dejarlo pendiente unos minutos.

## E3 — Lectura masiva

**Respuesta corta:** el problema no es la base de datos, es que 40.000 lecturas por segundo
de datos que cambian dos veces al día no deberían llegar a ninguna base de datos.

**Los números primero.** 5.000 productos, dos cambios al día, 40.000 lecturas por segundo en
pico, 50 ms p99. El conjunto de datos completo cabe holgadamente en memoria: 5.000 productos
a unos pocos kilobytes son decenas de megabytes. La relación lectura/escritura es de millones
a uno. Eso decide todo el diseño.

**El diseño en capas de caché.**

```text
CDN / borde        → respuestas cacheadas con TTL corto y validación por ETag
Caché en proceso   → el catálogo entero en memoria de cada instancia
Caché distribuida  → Redis, como respaldo al arrancar y para no golpear la BD
Base de datos      → fuente de verdad, consultada solo al refrescar
```

**La invalidación, que es la parte difícil.** Como los cambios son dos al día y conocidos, no
hace falta invalidación fina: al publicar un cambio se emite un evento
`CatalogoActualizado` y cada instancia recarga. Si hay que ser más quirúrgico, el evento
lleva los identificadores afectados. El TTL existe solo como red de seguridad por si un
evento se pierde.

**Por qué caché en proceso y no solo Redis.** A 40.000 por segundo, incluso Redis añade una
ida y vuelta de red por petición y se convierte en un punto de contención. Con el catálogo en
memoria local, la lectura es un acceso a un mapa: microsegundos, y el p99 de 50 ms deja de ser
un reto.

**El precio que declaro.** Incoherencia temporal entre instancias durante la recarga, de
segundos. Con un catálogo que cambia dos veces al día, es aceptable y lo digo explícitamente.
Y memoria por instancia, que limita cuántos productos caben: si el catálogo creciera a
millones, este diseño no sirve y habría que volver a Redis más CDN.

**Lo que menciono sin desarrollar.** Si además hubiera búsqueda facetada, eso es un índice
invertido (Elasticsearch o similar) alimentado por eventos, y ahí sí aparece CQRS con una
proyección de lectura propia.

## E4 — Escritura con picos

**Respuesta corta:** encolar en vez de escalar. El pico es 40 veces la media y dura 20
minutos: dimensionar para él es pagar 40 veces de más todo el año.

**Los números.** 200 por segundo de media, 8.000 en el pico, 20 minutos. El pico total son
unos 9,6 millones de transacciones. Si el sistema procesa 1.000 por segundo de forma
sostenida, el pico se absorbe en unas dos horas y media de retraso máximo — y la pregunta de
negocio es si eso es aceptable.

**El diseño.** La API acepta, valida lo mínimo, escribe en una cola durable y responde
`202 Accepted` con un identificador de seguimiento. Los consumidores procesan a su ritmo, con
un número de particiones dimensionado para el paralelismo objetivo. La durabilidad la da el
broker, con replicación y acuse del productor configurado para no perder.

**Lo que decide si esto es válido.** Que negocio acepte que la transacción se **acepte** ahora
y se **liquide** después. En nóminas normalmente sí: nadie espera el resultado en pantalla. Si
no lo aceptara —si hiciera falta respuesta inmediata con saldo actualizado— el diseño cambia
por completo y habría que escalar de verdad.

**Los límites reales.** El pool de conexiones a la base de datos es el techo, no la CPU: los
consumidores se dimensionan contra las conexiones disponibles, no contra el tráfico de
entrada. Y se necesita backpressure natural: los consumidores tiran del broker, así que nunca
reciben más de lo que pueden.

**Lo que no puede faltar.** Idempotencia por identificador de transacción, porque la entrega
es at-least-once. Cola de mensajes muertos con un proceso de revisión, no un vertedero.
Métricas de lag como métrica principal de salud, y de autoescalado. Y visibilidad para el
usuario: un endpoint para consultar el estado de su transacción por el identificador que se
le devolvió.

## E5 — Integración con un tercero poco fiable

**Respuesta corta:** capa anticorrupción con caché, timeout ajustado, un solo reintento,
circuit breaker y un fallback de negocio acordado con riesgo — no técnico.

Los valores concretos de timeout, reintento y breaker están en la respuesta
[09 → 21](#09--resiliencia), y no los repito. Lo que añade este escenario es lo de alrededor.

**La caché es la mitad de la solución.** Un scoring crediticio no cambia de un día para otro.
Cachear por documento durante 24 horas absorbe buena parte de las siete horas de caída
mensual, porque muchos de los que consultas ya se consultaron. Es la medida con mejor relación
coste-beneficio y casi nadie la propone primero.

**El fallback es una decisión de negocio.** Con un SLA del 99 %, el proveedor estará caído
siete horas al mes: no puede ser un error para el usuario. Acuerdo con riesgo una regla
conservadora local —límite reducido o aprobación condicionada— que se aplica cuando no hay
scoring. La solicitud se **marca** como decidida sin scoring y entra en una cola de revisión
para reevaluarla cuando el proveedor vuelva.

**La capa anticorrupción.** Su modelo no entra en mi dominio: traduzco su respuesta a mi
concepto de riesgo, y toda la fealdad —códigos numéricos, campos condicionales, semántica
implícita— queda encerrada ahí. Se prueba con respuestas reales capturadas, porque el entorno
de integración del proveedor estará caído la mitad del tiempo.

**Las métricas que separo.** "Rechazado por riesgo" y "decidido sin scoring" son dos cosas
distintas. Confundirlas hace invisible el problema y contamina los indicadores de negocio.

## E6 — Migración de un monolito existente

**Respuesta corta:** Strangler Fig, empezando por lectura y por el borde, con la lógica de
los procedimientos almacenados como el riesgo principal y la conciliación como red de
seguridad.

**Lo primero, que no es técnico.** Antes de mover nada: entender qué hace el sistema. Con 800k
líneas y 1.200 tablas, nadie lo sabe entero. Dedico las primeras semanas a levantar el mapa
—qué se despliega, qué tablas se tocan, qué flujos ocurren de verdad según los logs— y a
hablar con soporte, que sabe qué se rompe. El producto es un mapa de contextos real y una
lista priorizada, no un plan de 18 meses en Gantt.

**La fachada primero.** Un punto de entrada delante del monolito que pueda enrutar a lo viejo
o a lo nuevo por operación y por porcentaje. Sin esto no hay migración incremental posible,
y es lo primero que construyo.

**El orden de corte.** Primero capacidades de **lectura** —consultas, informes, extractos—
porque no tienen riesgo de consistencia y permiten al equipo aprender el camino con poco
peligro. Después capacidades de escritura periféricas, con poco acoplamiento. El núcleo
transaccional —movimientos, saldos— va al final o no va: si funciona y está bien acotado,
quizá lo correcto es dejarlo y rodearlo.

**El problema específico de este caso: la lógica en procedimientos almacenados.** Es el mayor
riesgo, porque no está versionada como código, no tiene tests y nadie sabe qué reglas contiene.
No la reescribo a ciegas: por cada procedimiento que migro, ejecuto **en paralelo** el viejo y
el nuevo con el mismo input durante semanas, comparo salidas y solo corto cuando no hay
discrepancias. Esa comparación en producción es la única forma honesta de descubrir las reglas
que nadie documentó.

**Los datos.** Expand/contract para todo cambio de esquema, sin excepción. Mientras conviven,
la fuente de verdad es una sola —normalmente Oracle— y lo nuevo lee de ahí o de una réplica;
la doble escritura se evita mientras se pueda, y cuando sea inevitable, va con conciliación
automática que detecte divergencias. Cero tolerancia a pérdida significa que toda migración de
datos tiene verificación de conteos y sumas de control, y un camino de vuelta.

**Cómo mido el avance.** Porcentaje de **tráfico** servido por lo nuevo, no porcentaje de
código migrado. Y número de despliegues que aún requieren la ventana de cuatro horas: si eso
no baja, la migración no está entregando valor aunque haya mucho código nuevo.

**Lo que digo sobre los 18 meses.** Que no comprometo una fecha de finalización para una
reescritura, pero sí una cadencia de entregas: cada trimestre, una capacidad concreta
funcionando en producción con su tráfico real. Si a los seis meses no se ha movido nada al
tráfico real, el enfoque está mal y hay que replantearlo, no esperar al mes 18 para
descubrirlo.

---

**Anterior:** [`11` — Simulación de entrevista](11-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
