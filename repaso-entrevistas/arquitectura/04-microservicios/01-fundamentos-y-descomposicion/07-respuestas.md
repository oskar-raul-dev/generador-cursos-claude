# 07 — Respuestas: Fundamentos y descomposición

> Solucionario del bloque `01-fundamentos-y-descomposicion`. Cada respuesta va en tres capas:
> **⏱️ 30 segundos** lo que dices primero, **🗣️ 2 minutos** lo que añades cuando dicen "cuéntame
> más", y **🔬 El detalle** lo que estudias pero no dices en voz alta. El enunciado está copiado
> literalmente del capítulo: si no cuadra, manda el capítulo y este archivo está desactualizado.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--qué-es-un-microservicio) · [02](#02--descomposición-y-fronteras) · [03](#03--el-camino-desde-el-monolito) · [04](#04--el-monolito-distribuido) · [05](#05--el-servicio-por-dentro) · [06](#06--simulación-de-entrevista)

---

# 01 — Qué es un microservicio

**01 → 1. Define microservicio sin usar la palabra "pequeño". 🟢**

⏱️ **30 segundos** — Un servicio que puedes desplegar solo, que es dueño exclusivo de sus datos y
que está modelado alrededor de una frontera de negocio.

🗣️ **2 minutos** — Las tres piezas son la misma idea vista desde tres lados. Si otro servicio lee tu
base de datos, tu migración es su problema y ya no despliegas solo; y si tu frontera no coincide con
una de negocio, cada cambio de reglas te obliga a tocar dos servicios a la vez. El tamaño no aparece
porque no predice nada: lo que predice el comportamiento del sistema es si puedes desplegar sin
coordinar.

🔬 **El detalle** — La prueba práctica son tres preguntas: ¿puedes desplegarlo un martes sin avisar?
¿cambiar su esquema sin avisar? ¿probarlo sin levantar otros tres? Un "no" y es un módulo con
latencia de red. Fowler y Lewis listan nueve características comunes del estilo, pero ninguna es un
número de líneas.

**01 → 2. ¿Cuáles son las tres propiedades que componen la definición por autonomía? 🟢**

⏱️ **30 segundos** — Despliegue independiente, propiedad exclusiva de sus datos y frontera de
negocio.

🗣️ **2 minutos** — No son tres requisitos sueltos que puedas cumplir a medias: se sostienen entre
sí. Sin datos propios no hay despliegue independiente, porque el esquema os ata. Sin frontera de
negocio, la propiedad de los datos no aguanta: los cambios llegan siempre en pareja.

🔬 **El detalle** — La que más se omite en las respuestas de entrevista es la tercera, y es la que
distingue un microservicio de un servicio técnico. Un "servicio de validación" cumple las dos
primeras y sigue siendo una mala frontera, porque no hay ninguna capacidad de negocio que se llame
validar.

**01 → 3. ¿Qué significa exactamente que un servicio sea "dueño de sus datos"? 🟢**

⏱️ **30 segundos** — Que nadie más lee ni escribe su almacén. Quien necesite esos datos los pide por
la API o los recibe por un evento.

🗣️ **2 minutos** — La consecuencia inmediata es que desaparecen los `JOIN` entre servicios: pasan a
ser una llamada de red que puede fallar o una copia local que puede estar vieja. Eso no es un efecto
secundario, es el diseño, y es lo que compra que tu migración de esquema no sea el problema de
nadie.

🔬 **El detalle** — La excepción honesta es acotada y con fecha: una réplica de solo lectura para
informes, o un esquema compartido durante una migración. Lo que convierte la excepción en deuda
permanente es no escribir cuándo termina.

**01 → 4. Enumera las cuatro cosas que dejan de ser gratis al pasar de monolito a servicios. 🟢**

⏱️ **30 segundos** — La llamada a un método, que se vuelve red; la transacción, que se vuelve saga;
el stack trace, que se vuelve traza distribuida; y el despliegue único, que se vuelve N despliegues
versionados.

🗣️ **2 minutos** — Cada una tiene su precio concreto: latencia y fallo parcial; consistencia
eventual con estados intermedios visibles; instrumentación y propagación de contexto; y
compatibilidad entre versiones que conviven. Poder recitarlas es lo que distingue una respuesta
vivida de una leída.

🔬 **El detalle** — La segunda es la que el entrevistador usa para profundizar: en cuanto propones
separar `orders` y `payments`, pregunta cómo evitas cobrar un pedido que no se reservó. La respuesta
empieza reconociendo que ya no hay transacción.

**01 → 5. ¿Qué coste fijo tiene cada servicio nuevo, independientemente de su tamaño? 🟢**

⏱️ **30 segundos** — Un pipeline, un tablero, sus alertas y un turno de guardia. Más la imagen que
actualizar cada vez que salga una vulnerabilidad.

🗣️ **2 minutos** — Es el argumento que mata los nano-servicios sin necesidad de discutir de
arquitectura: un servicio de cien líneas cuesta casi lo mismo de operar que uno de cinco mil. Antes
de proponer veinte servicios, se multiplica ese coste fijo por veinte y se compara con lo que compra
la autonomía.

🔬 **El detalle** — Hay un coste de segundo orden que casi nadie presupuesta: el tiempo de las
personas al cambiar de contexto entre repositorios y despliegues. No se mide, pero es el que hace
que a partir de cierto número de servicios por persona la velocidad baje en vez de subir.

**01 → 6. Nombra tres criterios que no definen un microservicio. 🟢**

⏱️ **30 segundos** — El tamaño en líneas, "hacer una sola cosa", un repositorio por servicio, y usar
contenedores o Kubernetes.

🗣️ **2 minutos** — El tamaño no predice el comportamiento; "una sola cosa" confunde función con
capacidad de negocio —`orders` hace muchas cosas y está bien—; el repositorio es una decisión de
organización del código; y el contenedor es el envase: un monolito contenerizado sigue siendo un
monolito.

🔬 **El detalle** — Dar un número de líneas es la señal que el entrevistador usa para clasificarte.
Quien da un número está recitando un blog; quien habla de despliegue y de datos ha mantenido uno.

**01 → 7. ¿Qué es el monolito modular y en qué se diferencia de un monolito a secas? 🟢**

⏱️ **30 segundos** — Un solo desplegable con fronteras internas explícitas entre módulos, que se
respetan y se verifican.

🗣️ **2 minutos** — La diferencia no es cosmética: en el monolito modular cada módulo tiene su API
interna y sus datos, y está prohibido que otro entre por debajo. Eso da la mitad del beneficio de los
microservicios —fronteras claras, cambios localizados— sin pagar red, sagas ni despliegues múltiples.
Y deja el sistema en la mejor posición posible para extraer el día que haga falta.

🔬 **El detalle** — La frontera se degrada sola salvo que alguien la verifique. Sin una prueba
automática que falle cuando un módulo importa el interior de otro, el monolito modular vuelve a ser
un monolito en unos meses.

**01 → 8. ¿Por qué un repositorio por servicio no es un criterio de arquitectura? 🟢**

⏱️ **30 segundos** — Porque describe cómo guardas el código, no cómo se despliega ni quién es dueño
de los datos.

🗣️ **2 minutos** — Hay sistemas de microservicios perfectamente autónomos en un monorepo, y
monolitos distribuidos repartidos en cuarenta repositorios que hay que desplegar juntos. Lo que
decide es si puedes desplegar y migrar sin coordinar; el número de repositorios afecta a la
herramienta de CI y al refactor transversal, que son otro debate.

🔬 **El detalle** — El monorepo tiene una trampa concreta: facilita tanto compartir código que la
librería común de dominio aparece sola, y con ella el acoplamiento que obliga a desplegar a todos a
la vez.

**01 → 9. Un servicio no puede probarse sin levantar otros tres. ¿Qué te dice eso, y de qué propiedad concreta carece? 🟡**

⏱️ **30 segundos** — Que no es autónomo: carece de despliegue independiente, y probablemente de
propiedad de sus datos.

🗣️ **2 minutos** — Necesitar a otros tres para probar significa que la lógica que estás probando no
está entera en ningún sitio, y eso se traduce en que tampoco puedes desplegar sin coordinar. Suele
venir de una cadena síncrona larga o de datos ajenos consultados en caliente. La salida es doble:
dobles de prueba y contratos verificados en el pipeline, en vez de un entorno completo.

🔬 **El detalle** — Es el síntoma número uno del monolito distribuido. Antes de rediseñar, conviene
comprobar si el problema es de frontera —el servicio no es dueño de lo que necesita— o solo de
estrategia de pruebas, porque la corrección es muy distinta.

**01 → 10. "Los microservicios escalan mejor": ¿qué parte es cierta y qué parte es falsa? 🟡**

⏱️ **30 segundos** — Cierto que permiten escalar por separado. Falso que mejoren el rendimiento: por
petición van más lentos, porque hay red donde había una llamada a un método.

🗣️ **2 minutos** — Lo que compras es poder darle más instancias a la parte que las necesita, en vez
de replicar el sistema entero. Eso es eficiencia de recursos, no velocidad. Y si el cuello de botella
es una base de datos compartida, no ganas nada: separas el cómputo y sigues chocando en el mismo
sitio.

🔬 **El detalle** — Un monolito también escala horizontalmente si no tiene estado. La pregunta útil
para desmontar la frase es: ¿qué parte concreta necesita escalar distinto del resto, y qué recurso
agota?

**01 → 11. Diferencia entre "aislar un fallo" y "poder aislar un fallo". 🟡**

⏱️ **30 segundos** — La separación crea la posibilidad de aislar; el aislamiento lo construyes tú
con timeouts, circuit breaker y degradación.

🗣️ **2 minutos** — Un servicio que llama a otro con el timeout por defecto está más expuesto que el
monolito equivalente, porque ahora hay una red que puede quedarse colgada sin devolver error nunca.
El fallo se propaga igual, pero con menos señales y más lento de diagnosticar.

🔬 **El detalle** — Es de las frases que más rinden dichas en voz alta, porque contradice el folleto
sin sonar contrarian: "los microservicios no aíslan fallos, hacen posible aislarlos, y eso se paga
aparte".

**01 → 12. Dos servicios comparten una base de datos, pero uno solo lee. ¿Siguen siendo independientes? Justifica desde el despliegue. 🟡**

⏱️ **30 segundos** — No. El que escribe no puede cambiar el esquema sin coordinar con el que lee, así
que su despliegue ya no es independiente.

🗣️ **2 minutos** — "Solo lectura" elimina los conflictos de escritura, no el acoplamiento: el lector
depende de la forma física de las tablas, que es un detalle interno del otro. Renombrar una columna
se convierte en una negociación entre equipos, y a partir de ahí el esquema se congela porque
cambiarlo cuesta demasiado.

🔬 **El detalle** — Hay además acoplamiento de rendimiento: una consulta del lector puede tumbar al
escritor. Si la lectura es imprescindible, la forma acotada es una réplica con un contrato explícito
—una vista estable, no las tablas— y fecha de revisión.

**01 → 13. ¿Por qué separar un servicio empeora la latencia por petición aunque mejore la escalabilidad del sistema? 🟡**

⏱️ **30 segundos** — Porque cambias una llamada en memoria por una de red: serialización,
deserialización, salto, y la posibilidad de que no conteste.

🗣️ **2 minutos** — En el caso bueno hablas de un salto de milisegundos; en el malo, de un timeout de
segundos que antes no existía. A cambio ganas poder replicar solo la parte cara. Por eso la frase
correcta es "compro independencia de escalado, y la pago en latencia", que además es la que deja
buen sabor en una entrevista.

🔬 **El detalle** — El coste real rara vez es el serializador: es el número de saltos encadenados. Una
cadena de cinco servicios síncronos multiplica latencias y probabilidades de fallo, y es el patrón
que produce las caídas que parecen inexplicables.

**01 → 14. ¿Qué preguntarías para decidir si extraer `payments` de `orders`, y en qué orden? 🟡**

⏱️ **30 segundos** — Quién lo mantiene, qué datos son suyos, qué pasa si se cae, y si hoy hay algún
motivo real para desplegarlo o escalarlo por separado.

🗣️ **2 minutos** — El orden importa: primero la frontera de datos —¿hay tablas que solo toca
`payments`?—; luego el acoplamiento de cambio —¿cambian siempre juntos?—; luego la operación —¿el
cumplimiento normativo pide aislarlo?—; y por último el escalado. Si la frontera de datos no está
clara, la extracción se hace en dos fases: separar el esquema dentro del monolito y solo después
sacar el proceso.

🔬 **El detalle** — `payments` tiene una particularidad que lo hace buen candidato: suele tener
requisitos de auditoría y de cumplimiento distintos del resto, y aislar ese alcance es un beneficio
que no aparece en ninguna métrica de rendimiento.

**01 → 15. Tu equipo es de cinco personas y despliega todo junto los jueves. ¿Qué compra la autonomía aquí? 🟠**

⏱️ **30 segundos** — Nada. Si despliegas junto de todos modos, pagas el precio completo de la
separación sin cobrar ninguno de sus beneficios.

🗣️ **2 minutos** — La autonomía se cobra en despliegue independiente, escalado diferencial y
libertad de equipos. Con un solo equipo y una ventana semanal, los tres son cero. La recomendación
es monolito modular con fronteras verificadas, y extraer el día que una frontera necesite desplegarse
o escalar sola.

🔬 **El detalle** — Hay una excepción: un componente con un perfil de recursos muy distinto —un
procesamiento pesado, algo que necesita GPU— puede justificar la extracción de **uno** aunque el
equipo sea pequeño. Uno, no quince.

**01 → 16. El negocio pide "escalar el sistema" y alguien propone separar tres servicios. La base de datos está al 90 % de CPU. ¿Qué respondes? 🟠**

⏱️ **30 segundos** — Que separar servicios no mueve ese 90 %: el cuello está en la base de datos y
la separación no lo toca.

🗣️ **2 minutos** — Primero se identifica qué consume esa CPU: consultas sin índice, `N+1`, informes
en la instancia principal. Las salidas baratas son índices, caché, réplica de lectura o sacar los
informes fuera. Separar servicios sobre la misma base añade conexiones y latencia y deja el problema
donde estaba; si al final hace falta separar, lo que hay que separar son **los datos**, no solo el
cómputo.

🔬 **El detalle** — Es el escenario donde más se nota si alguien ha operado sistemas: la respuesta
correcta empieza por pedir el plan de ejecución de las tres consultas más caras, no por dibujar
cajas.

**01 → 17. ¿Cuándo aceptarías compartir un almacén entre dos servicios, y qué escribirías para que esa excepción no se vuelva permanente? 🟠**

⏱️ **30 segundos** — Durante una migración, y con fecha de fin escrita, dueño asignado y una alerta
que la recuerde.

🗣️ **2 minutos** — El caso legítimo es transitorio: estás extrayendo un servicio y los datos todavía
no se han separado. Se acota por escrito —qué tablas, en qué dirección, hasta cuándo— y se registra
como deuda con responsable. La otra forma acotada es una réplica de solo lectura con un contrato
explícito, que es una vista estable, nunca las tablas internas.

🔬 **El detalle** — Lo que convierte la excepción en permanente no es la técnica, es que nadie es
dueño de cerrarla. Una tarea con fecha en el tablero del equipo dueño del dato funciona mejor que
cualquier documento de arquitectura.

**01 → 18. Defiende "monolito modular primero" ante un entrevistador que lo lee como falta de ambición. 🟠**

⏱️ **30 segundos** — No es evitar microservicios: es no decidir las fronteras antes de conocer el
dominio, porque cortar mal cuesta más que no cortar.

🗣️ **2 minutos** — El argumento tiene tres patas: las fronteras se descubren usando el sistema; un
corte equivocado se paga en llamadas cruzadas y despliegues coordinados durante años; y el monolito
modular deja el sistema listo para extraer el día que una frontera lo pida. Es una decisión de
secuencia, no de destino, y así se dice.

🔬 **El detalle** — Conviene citarlo por su nombre —*monolith first*, de Fowler— y también su
contraargumento honesto: cuando ya conoces bien el dominio, o cuando la organización ya está dividida
en equipos con fronteras claras, empezar separado es defendible.

**01 → 19. Te dan un sistema con veinte servicios y un único pipeline que los despliega juntos. ¿Cuánto cuesta esa arquitectura y qué está comprando? 🟠**

⏱️ **30 segundos** — Cuesta el precio completo de veinte servicios y no compra nada: es un monolito
distribuido.

🗣️ **2 minutos** — Pagas veinte pipelines de construcción, veinte imágenes, red y sagas entre
componentes que antes se llamaban en memoria, y observabilidad distribuida. A cambio no tienes
despliegue independiente —que es el único beneficio que el resto sostiene—. La corrección no es
volver al monolito: es hacer compatibles los contratos y partir el pipeline, empezando por el
servicio con menos dependencias.

🔬 **El detalle** — Antes de rediseñar conviene medir por qué se despliega junto. A veces no es
técnico: es un proceso de aprobación o una ventana de cambio heredada, y entonces la arquitectura no
es el problema.

**01 → 20. Estima el coste anual de operar un servicio más, en las categorías que sepas nombrar. Di qué no puedes estimar. 🟠**

⏱️ **30 segundos** — Infraestructura de ejecución, minutos de CI, almacenamiento de imágenes,
ingesta de logs y trazas, y tiempo de personas en guardia y en actualizaciones.

🗣️ **2 minutos** — Las primeras se estiman con la factura: instancias o contenedores, pipeline,
registro y observabilidad —que en sistemas medianos es de las partidas más caras y casi nadie la
cuenta—. El tiempo de personas se estima por horas al mes de mantenimiento: dependencias,
vulnerabilidades, incidentes.

🔬 **El detalle** — Lo que no se puede estimar es el coste de coordinación: cuántas conversaciones
extra genera un servicio más entre equipos. Decir explícitamente qué no sabes estimar da más
credibilidad que inventar un número, y eso también vale en la entrevista.

**01 → 21. Diseña la prueba de tres preguntas de §2 aplicada a un sistema que conozcas, y di cuál falla. 🟠**

⏱️ **30 segundos** — Las tres son: desplegar sin avisar, migrar el esquema sin avisar, probar sin
levantar a otros. En la mayoría de sistemas reales falla la tercera, y arrastra a la primera.

🗣️ **2 minutos** — La respuesta se estructura así:

```text
Servicio          Desplegar solo   Migrar solo   Probar solo   Veredicto
orders            sí               sí            no            frontera dudosa
inventory         sí               sí            sí            autónomo
reports           no               no            no            lee tablas ajenas
```

Y se cierra diciendo qué harías con la fila peor: para `reports`, cortar la lectura directa y
sustituirla por una vista contractual o por una proyección alimentada por eventos.

🔬 **El detalle** — El entrevistador preguntará por el coste de esa corrección: la proyección añade
consistencia eventual y un proceso que mantener. Reconocerlo antes de que lo pregunte es lo que
distingue la respuesta.

**01 → 22. Un equipo propone veinte microservicios para un producto nuevo sin usuarios. Argumenta en contra en dos minutos, sin decir "es demasiada complejidad". 🔴**

⏱️ **30 segundos** — Sin usuarios no conoces las fronteras, y veinte cortes hechos hoy se convierten
en veinte contratos que renegociar cuando el dominio cambie el mes que viene.

🗣️ **2 minutos** — Tres argumentos concretos, en este orden: **coste fijo** —veinte pipelines,
tableros y guardias antes de la primera petición real—; **coste de cambio** —cada refactor que cruce
una frontera pasa a ser un cambio de contrato con versionado y compatibilidad—; y **coste de
aprendizaje** —el equipo va a depurar trazas distribuidas en vez de producto—. La alternativa es un
monolito modular con fronteras explícitas y extracción del primer servicio cuando algo pida
desplegarse o escalar solo.

🔬 **El detalle** — Si insisten, hay una salida intermedia defendible: dos o tres desplegables,
cortados por las fronteras más obvias y estables, en vez de veinte. Ofrecer el punto medio funciona
mejor que negarse en redondo, y demuestra que estás negociando diseño, no dogma.

**01 → 23. Dibuja el mismo flujo de compra como monolito y como tres servicios, y marca en el segundo los cuatro puntos donde puede fallar algo que en el primero no podía. 🔴**

⏱️ **30 segundos** — Los cuatro son: la llamada de red, el fallo parcial a mitad del flujo, la
respuesta que se pierde tras haber ejecutado el efecto, y la versión incompatible entre servicios.

🗣️ **2 minutos** — El dibujo:

```text
Monolito                          Tres servicios
────────────                      ────────────────────────────────────
placeOrder()                      orders ──(1) red──► inventory
  reserveInventory()                 │
  charge()                           └──(2) red──► payments  (3) respuesta perdida
  todo en una transacción                 (4) contrato v1 contra v2
```

1. La red puede estar lenta o caída y el timeout hay que elegirlo.
2. `inventory` reserva y `payments` falla: no hay rollback, hay compensación.
3. El cobro se ejecutó y la respuesta se perdió: al reintentar, hace falta idempotencia.
4. Se despliega `inventory` con un contrato nuevo y `orders` todavía habla el viejo.

🔬 **El detalle** — El punto tres es el que casi nadie dibuja y el que más se pregunta: el reintento
sin clave de idempotencia es la causa clásica de cobros duplicados. Se resuelve con
`Idempotency-Key` y registro de operaciones ya aplicadas.

**01 → 24. Te piden extraer un servicio de un monolito de diez años sin documentación. Da los tres primeros pasos y di qué medirías para saber que el primero funcionó. 🔴**

⏱️ **30 segundos** — Primero medir quién usa qué; después aislar el módulo dentro del monolito; solo
al final sacarlo a un proceso propio.

🗣️ **2 minutos** — Los tres pasos:

```text
1. Instrumentar: qué tablas toca cada caso de uso y quién llama a quién.
2. Aislar dentro: fachada + módulo con sus propias tablas, mismo desplegable.
3. Extraer: proceso aparte detrás de la misma fachada, con su base de datos.
```

El paso uno se da por bueno cuando puedes decir, con datos y no con suposiciones, qué tablas toca
solo el candidato y cuáles comparte, y cuántas llamadas entrantes tiene cada método público. Sin ese
mapa, el corte es adivinanza.

🔬 **El detalle** — La medida que más rinde del paso dos es la de acoplamiento: número de llamadas
que cruzan la fachada por minuto. Si después de aislar sigue habiendo cientos de cruces, la frontera
está mal elegida y extraer solo convertirá esas llamadas en tráfico de red.

---

# 02 — Descomposición y fronteras

**02 → 1. ¿Qué es cortar por capacidad de negocio, y cómo sabes que una capacidad es real? 🟢**

⏱️ **30 segundos** — Un servicio por cosa que la empresa hace y por la que podría responder una
persona. Es real si existiría aunque el software no existiera.

🗣️ **2 minutos** — Catálogo, pedidos, cobros y reserva de existencias son capacidades; validación,
integración o utilidades no lo son, porque son funciones técnicas. La prueba rápida es leerle el
nombre a alguien de negocio: si entiende de qué hablas, vas bien; si tienes que explicárselo,
cortaste por tecnología.

🔬 **El detalle** — El criterio envejece bien porque las capacidades de una empresa cambian mucho más
despacio que su software. Lo que cuesta es que exige una conversación con negocio: sin ella acabas
inventando capacidades leyendo el esquema de la base de datos.

**02 → 2. Define contexto acotado en una frase. 🟢**

⏱️ **30 segundos** — La frontera dentro de la cual un modelo y su vocabulario significan una sola
cosa.

🗣️ **2 minutos** — Lo importante es la consecuencia: fuera de esa frontera, la misma palabra puede
significar otra cosa, y por eso se traduce al cruzar. "Cliente" es dirección de envío en `orders`,
medio de pago y riesgo en `payments`, e identidad con consentimientos en `customers`.

🔬 **El detalle** — Es un concepto lingüístico antes que técnico: se descubre escuchando cómo habla
la gente, no dibujando cajas. Por eso el mapa de contextos sale de talleres y no del código.

**02 → 3. Enumera las cuatro heurísticas de desempate del capítulo. 🟢**

⏱️ **30 segundos** — Razón de cambio, volatilidad, perfil de carga y dueño del dato.

🗣️ **2 minutos** — Lo que cambia junto va junto; lo volátil se aísla para proteger lo estable; lo que
recibe el grueso del tráfico es candidato a escalar solo; y si un dato tiene dos escritores, la
frontera está mal. Las cuatro se comprueban con datos que ya tienes: historial, métricas y el
esquema.

🔬 **El detalle** — En sectores regulados hay una quinta que manda sobre todas: la frontera de
cumplimiento. Aislar lo que tiene auditoría o retención propias vale aunque ninguna métrica técnica
lo pida.

**02 → 4. Nombra los cuatro cortes que no son criterio y di qué produce cada uno. 🟢**

⏱️ **30 segundos** — Por capa técnica, por entidad, por verbo y por reutilización.

🗣️ **2 minutos** — La capa produce un monolito repartido por la red: cada caso de uso atraviesa los
tres servicios. La entidad produce CRUD anémico y un orquestador con todas las reglas. El verbo
produce funciones que no son dueñas de ningún dato. La reutilización produce dependencias en
estrella: cambia el compartido y despliegan todos.

🔬 **El detalle** — Los cuatro comparten la misma raíz: cortan por cómo está hecho el software, no
por cómo cambia el negocio. Y la frontera se paga en cambios, no en ejecución.

**02 → 5. ¿Cuáles son las tres pruebas del test de la frontera? 🟢**

⏱️ **30 segundos** — ¿Cambian juntos? ¿Hablan mucho? ¿Cada dato tiene un solo escritor?

🗣️ **2 minutos** — Si un cambio de negocio típico toca los dos, son uno solo. Si un caso de uso
cruza la frontera más de dos o tres veces, partiste una operación por la mitad y pusiste una red en
el corte. Y si dos servicios escriben el mismo dato, la frontera es ficción.

🔬 **El detalle** — Las tres se pueden aplicar sobre un diagrama en cinco minutos, y por eso
funcionan tan bien como criterio de aceptación en una entrevista: conviertes tu propuesta en algo
verificable en vez de opinable.

**02 → 6. ¿Qué significa "cada dato, un escritor", y qué indica cuando se incumple? 🟡**

⏱️ **30 segundos** — Que exactamente un servicio es responsable de modificar cada dato; los demás lo
leen por API o lo reciben por evento.

🗣️ **2 minutos** — Cuando dos escriben lo mismo, la pregunta no es cómo se sincronizan, es por qué
están separados. Dos escritores producen conflictos que nadie sabe resolver, reglas duplicadas que se
desincronizan, y discusiones de "quién tiene la verdad" que no tienen respuesta técnica.

🔬 **El detalle** — El matiz: **copias de lectura sí puede haber muchas**, y son legítimas. Lo que no
puede haber es dos sitios donde se decida el valor.

**02 → 7. ¿En qué se diferencia cortar por capacidad de cortar por subdominio, si el resultado se parece tanto? 🟡**

⏱️ **30 segundos** — En lo que descubres por el camino: el subdominio te obliga a nombrar dónde una
palabra cambia de significado.

🗣️ **2 minutos** — El corte por capacidad mira lo que la empresa hace; el de subdominio mira cómo
habla. Suelen coincidir, pero el segundo detecta las ambigüedades —tres "Cliente" distintos— y de ahí
sale una decisión concreta: cada contexto tiene su modelo y traduce en la frontera, en vez de
compartir una clase.

🔬 **El detalle** — En dominios pequeños y sin ambigüedad, el aparato de DDD es ceremonia y el corte
por capacidad basta. Decir eso en una entrevista puntúa más que recitar subdominios nucleares, de
soporte y genéricos.

**02 → 8. ¿Por qué un contexto acotado es una frontera "candidata" y no directamente un servicio? 🟡**

⏱️ **30 segundos** — Porque puede haber varios servicios dentro de un contexto, pero nunca un
servicio a caballo entre dos.

🗣️ **2 minutos** — El contexto marca dónde el modelo es coherente; el servicio es una decisión de
despliegue. Dentro de un contexto grande puede convenir separar por carga o por ritmo de cambio —por
ejemplo, la escritura y una proyección de lectura muy consultada—. Lo que nunca funciona es un
servicio que abarque dos contextos: tendría dos modelos del mismo término dentro.

🔬 **El detalle** — La regla práctica: el contexto es el límite superior. Puedes subdividirlo por
razones operativas, nunca superarlo por razones de comodidad.

**02 → 9. Tres servicios usan una clase `Customer` compartida. ¿Qué problema tienes y cómo se llama? 🟡**

⏱️ **30 segundos** — Modelo canónico compartido: los tres se acoplan a la misma forma y cualquier
cambio obliga a desplegarlos juntos.

🗣️ **2 minutos** — Además del acoplamiento de despliegue, la clase crece hasta ser la unión de las
tres necesidades: campos que solo usa uno, opcionales por todas partes, y reglas que dependen de quién
la use. La corrección es que cada servicio tenga su propio modelo del concepto y traduzca en la
frontera, aunque eso signifique escribir tres clases parecidas.

🔬 **El detalle** — La objeción esperable es "eso es duplicar código". La respuesta es que no es
duplicación: son tres modelos distintos que hoy se parecen y mañana no, y el acoplamiento cuesta más
que las tres clases.

**02 → 10. ¿Por qué cortar por capa técnica impide el despliegue independiente? 🟡**

⏱️ **30 segundos** — Porque cada caso de uso atraviesa todas las capas, así que cada cambio de
negocio toca todos los servicios.

🗣️ **2 minutos** — Un servicio de API, otro de lógica y otro de datos parecen tres piezas
independientes, pero ninguna hace nada sola: añadir un campo obliga a tocar los tres y a desplegarlos
coordinados. Es el monolito en capas con latencia de red, que es el peor de los dos mundos.

🔬 **El detalle** — Se reconoce por una señal clara: los servicios se llaman entre sí siempre en el
mismo orden y en cadena. Si el diagrama de llamadas es una línea recta, cortaste por capa.

**02 → 11. Diferencia entre copiar un dato a propósito y duplicar un dato por accidente. 🟡**

⏱️ **30 segundos** — La copia a propósito es una foto que el negocio quiere congelada; la
duplicación accidental es el mismo dato vivo en dos sitios sin dueño claro.

🗣️ **2 minutos** — La dirección de envío del pedido es una copia deliberada: si el cliente cambia su
domicilio mañana, la factura de ayer no debe cambiar. En cambio, el teléfono del cliente replicado en
tres servicios "para no llamar" es duplicación: los tres creen tenerlo al día y ninguno lo tiene.

🔬 **El detalle** — El criterio para distinguirlas: pregunta qué debe pasar cuando el origen cambie.
Si la respuesta es "nada, quiero el valor de entonces", es copia legítima y además debe ser inmutable.

**02 → 12. ¿Qué te dice el historial de commits sobre dónde están las fronteras? 🟠**

⏱️ **30 segundos** — Que los archivos que cambian juntos una y otra vez pertenecen al mismo servicio,
diga lo que diga el diagrama.

🗣️ **2 minutos** — Es la heurística de razón de cambio hecha con datos que ya tienes. Miras seis
meses de historial, cuentas qué ficheros aparecen en los mismos commits y buscas los grupos. Lo que
sale suele contradecir el diagrama oficial, y esa contradicción es la información valiosa.

🔬 **El detalle** — Ojo con los falsos positivos: cambios de formato masivos, renombrados y
actualizaciones de dependencias ensucian el análisis. Se filtran los commits enormes antes de sacar
conclusiones.

**02 → 13. Un caso de uso cruza cuatro veces la frontera entre dos servicios. ¿Qué concluyes y qué haces? 🟠**

⏱️ **30 segundos** — Que la frontera está en medio de una operación. O se fusionan, o se mueve el
corte.

🗣️ **2 minutos** — Cuatro cruces significan cuatro oportunidades de fallo, cuatro latencias y una
prueba que necesita a los dos servicios vivos. Antes de rediseñar conviene mirar si los cruces son de
datos —entonces a lo mejor basta con copiar lo que falta al lado que decide— o de decisiones —y
entonces la lógica está repartida y hay que moverla entera a un lado—.

🔬 **El detalle** — Existe una salida intermedia legítima: agrupar los cuatro cruces en una sola
llamada de grano grueso. Reduce el daño, pero no arregla la frontera; conviene decir explícitamente
que es un parche y bajo qué condición se rediseña.

**02 → 14. Te proponen un servicio "de notificaciones" que usarán los cinco servicios. Argumenta a favor y en contra. 🟠**

⏱️ **30 segundos** — A favor: enviar correos y mensajes es una capacidad técnica real con
integraciones propias. En contra: si contiene las reglas de cuándo y a quién notificar, se convierte
en dependencia en estrella.

🗣️ **2 minutos** — La línea está en qué guarda. Un servicio que recibe "envía esto a esta persona por
este canal" y gestiona proveedores, reintentos y plantillas es infraestructura y funciona bien. Uno
que decide que "si el pedido lleva dos días sin pagar, avisa al cliente" tiene reglas de `orders`
dentro, y cada cambio de negocio en `orders` obliga a desplegarlo.

🔬 **El detalle** — La prueba: ¿quién despliega cuando cambia una regla de negocio? Si la respuesta
es "notificaciones", la frontera está mal aunque el servicio parezca genérico.

**02 → 15. El organigrama tiene tres departamentos que hacen lo mismo por una fusión antigua. ¿Cortas según el organigrama? Justifica. 🟠**

⏱️ **30 segundos** — No. Cortaría por la capacidad real y nombraría explícitamente que la
organización tendrá que seguir a la arquitectura, o al revés.

🗣️ **2 minutos** — Copiar el organigrama funciona cuando refleja cómo se trabaja; aquí refleja una
fusión de hace diez años, y copiarla congela el accidente en el software para la siguiente década.
Lo honesto es proponer el corte por capacidad, enseñar el conflicto con la estructura actual, y
decir que sin un dueño único de esa capacidad el diseño se va a degradar.

🔬 **El detalle** — El aviso de Conway no es una amenaza teórica: si tres departamentos mantienen un
servicio, acabarán apareciendo tres módulos internos con tres formas de hacer lo mismo. Si no se
puede unificar la organización, a veces la respuesta menos mala es aceptar tres servicios y un
contrato común, y decirlo como lo que es: una concesión.

**02 → 16. ¿Cómo justificarías separar `catalog` de `inventory` si ambos hablan de productos? 🟠**

⏱️ **30 segundos** — Por volatilidad y por carga: el catálogo se lee muchísimo y cambia poco; las
existencias cambian con cada venta.

🗣️ **2 minutos** — Además tienen dueños distintos en el negocio y datos distintos: el catálogo tiene
descripciones, imágenes y precios; inventario tiene existencias y reservas. Hablan del mismo producto
pero no comparten ni el ciclo de vida ni el perfil de acceso, y esa es exactamente la situación donde
separar compra escalado diferencial de verdad.

🔬 **El detalle** — La repregunta típica es "¿y la disponibilidad que se muestra en la ficha?". La
respuesta es una copia publicada por eventos, con la aclaración de que puede estar desfasada segundos
y de que la reserva real la decide `inventory` en el momento de confirmar. Eso es diseño, no fallo.

**02 → 17. Dos servicios escriben el mismo campo. Da dos soluciones distintas y di cuál prefieres y por qué. 🟠**

⏱️ **30 segundos** — O se asigna un único dueño y el otro pide por API, o se fusionan los dos
servicios. Prefiero asignar dueño si las fronteras son buenas por lo demás.

🗣️ **2 minutos** — La primera opción mantiene la separación: uno escribe, el otro solicita el cambio
y reacciona al resultado. Cuesta una llamada más y consistencia eventual. La segunda reconoce que la
frontera estaba mal y elimina el problema de raíz; se elige cuando además los dos cambian siempre
juntos, que suele ir de la mano.

🔬 **El detalle** — La opción que **no** está en la lista es sincronizar los dos sentidos con eventos.
Es la que más se propone y la que crea bucles, conflictos y datos que divergen sin que nadie se
entere hasta la auditoría.

**02 → 18. En banca, ¿qué criterio de corte puede pesar más que la carga y la volatilidad, y por qué? 🟠**

⏱️ **30 segundos** — La frontera de cumplimiento: auditoría, retención de datos, certificación o
aislamiento de datos personales.

🗣️ **2 minutos** — Aislar lo que está sujeto a una norma reduce el alcance de las auditorías y evita
que requisitos caros contaminen todo el sistema. Si el cobro exige trazabilidad completa y retención
de siete años, tenerlo aparte significa que solo ese servicio paga ese coste, en vez de imponérselo
al catálogo.

🔬 **El detalle** — Es un argumento que casi nadie menciona en entrevistas y que en el sector pesa
más que el rendimiento. Va acompañado de una consecuencia técnica concreta: ese servicio suele
necesitar registro de auditoría inmutable y su propia política de copias, que también se dice.

**02 → 19. ¿Cuándo aceptarías un servicio que solo hace CRUD sobre una entidad? 🟠**

⏱️ **30 segundos** — Cuando esa entidad es de verdad una capacidad con reglas propias, o cuando es un
dato de referencia compartido que casi nadie modifica.

🗣️ **2 minutos** — `customers` parece CRUD y no lo es: tiene consentimientos, datos personales con
requisitos legales y reglas de identidad. En cambio, un servicio de "direcciones" sí es CRUD puro y
casi siempre debería vivir dentro de quien es dueño del cliente. El otro caso legítimo son los datos
maestros —países, divisas, tipos de producto—, donde el CRUD es todo lo que hay.

🔬 **El detalle** — La señal de alarma no es que sea CRUD, es **dónde están las reglas**. Si las
reglas que usan esos datos viven en el que llama, tienes un servicio anémico y un orquestador gordo,
y eso se arregla moviendo la regla al dueño del dato.

**02 → 20. Te piden un número de microservicios en la primera reunión. Responde sin dar un número y sin sonar evasivo. 🟠**

⏱️ **30 segundos** — "Empezaría por las fronteras que el negocio ya tiene claras, tres o cuatro, y
dejaría el resto dentro hasta que algo pida salir."

🗣️ **2 minutos** — La respuesta completa añade el criterio: el techo práctico lo marca el número de
equipos que van a mantenerlo; el suelo lo marca qué necesita desplegarse o escalar por separado hoy.
Y se cierra con la asimetría: juntar dos servicios es fácil, separar mal es caro, así que prefiero
equivocarme por tener pocos.

🔬 **El detalle** — Si insisten en un número, conviene dar un rango con condición: "tres o cuatro
para empezar, y revisamos en tres meses con datos de uso". Un rango con fecha de revisión no es
evasivo: es planificación.

**02 → 21. Propón el corte de un sistema de reservas de hotel —búsqueda, reserva, pago, limpieza, facturación— y defiende las dos decisiones más discutibles. 🔴**

⏱️ **30 segundos** — Cuatro servicios: `availability` (búsqueda), `bookings`, `payments` y
`operations` (limpieza y mantenimiento). Facturación va dentro de `payments`.

🗣️ **2 minutos** — El corte y su razón:

```text
availability     lectura masiva, cambia con cada reserva, se cachea    → carga
bookings         el ciclo de vida de la reserva y sus reglas           → capacidad
payments         cobro, devolución y factura; auditoría propia         → cumplimiento
operations       limpieza y mantenimiento; otro equipo, otro ritmo     → organización
```

Las dos decisiones discutibles: **separar `availability` de `bookings`**, porque parecen lo mismo
—se justifica por perfil de carga: buscar es órdenes de magnitud más frecuente que reservar, y la
disponibilidad publicada puede ser eventual mientras la reserva sea transaccional—; y **meter
facturación dentro de `payments`**, porque cambian juntas y comparten el requisito de auditoría.

🔬 **El detalle** — La pregunta que viene después es el overbooking: si `availability` está
desfasada, dos clientes pueden intentar la última habitación. La respuesta es que la verdad la decide
`bookings` al confirmar, con una comprobación transaccional, y que el negocio hotelero convive con
overbooking a propósito — lo que convierte un problema técnico en una decisión de producto.

**02 → 22. Tienes un corte ya hecho por entidades (`customers`, `addresses`, `products`, `prices`). Propón el rediseño y el orden de los pasos para llegar a él sin parar el negocio. 🔴**

⏱️ **30 segundos** — Fusionar hacia dos capacidades: `customers` absorbe `addresses`, y `catalog`
absorbe `products` y `prices`. Y se hace fusionando de dos en dos, no de golpe.

🗣️ **2 minutos** — El orden:

```text
1. Medir: quién llama a qué, y qué reglas viven en los llamadores.
2. Fusionar direcciones dentro de clientes: primero el código tras una fachada,
   luego los datos al mismo esquema, y se retira la API vieja cuando nadie la use.
3. Repetir con productos y precios.
4. Mover al dueño las reglas que estaban en el orquestador.
```

Cada fusión mantiene la API antigua viva durante una fase para no romper a los clientes, y se retira
cuando las métricas de uso muestran cero llamadas.

🔬 **El detalle** — El paso 4 es el que de verdad arregla el sistema y el que casi siempre se olvida.
Fusionar servicios sin mover las reglas deja el orquestador gordo intacto: habrás reducido el número
de despliegues, pero la lógica seguirá en el sitio equivocado.

**02 → 23. Diseña las tres comprobaciones que harías sobre un sistema existente para decidir si sus fronteras están bien, y di qué dato necesitas para cada una. 🔴**

⏱️ **30 segundos** — Acoplamiento de cambio (historial), tráfico entre servicios (trazas) y
escritores por dato (esquema y código).

🗣️ **2 minutos** — Las tres, con su fuente:

```text
Comprobación            Dato que necesitas              Señal de alarma
─────────────────────── ─────────────────────────────── ─────────────────────
Cambian juntos          6 meses de historial por commit dos servicios siempre juntos
Hablan mucho            trazas: llamadas por caso de uso >2-3 cruces por operación
Un solo escritor        quién hace UPDATE en cada tabla  dos servicios escribiendo
```

Y se cierra con el orden de actuación: primero las fronteras que fallan las tres, que son las que se
fusionan; después las que fallan solo la segunda, que suelen arreglarse moviendo una decisión de lado.

🔬 **El detalle** — Si no hay trazas, la segunda comprobación se aproxima con los registros de acceso
del servidor o con las métricas de llamadas salientes por cliente. Decir cómo lo harías sin
herramienta ideal es lo que distingue una respuesta de alguien que lo ha hecho.

**02 → 24. El equipo de frontend pide un endpoint que devuelva pedido, cliente y productos juntos. Da tres respuestas arquitectónicas distintas, con su precio, y elige. 🔴**

⏱️ **30 segundos** — Composición en un BFF, proyección materializada alimentada por eventos, o copia
de los datos que el pedido necesita dentro de `orders`. Elijo BFF para empezar.

🗣️ **2 minutos** — Las tres, con su precio:

```text
BFF que compone        latencia = la llamada más lenta; fallo parcial que decidir; sin datos nuevos
Proyección CQRS        lectura rapidísima; consistencia eventual; una proyección que mantener y reconstruir
Copia dentro de pedidos consulta local; solo sirve para los datos que son foto (dirección, precio pagado)
```

Empiezo por el BFF porque no añade estado nuevo y es reversible; paso a proyección si la latencia o el
fan-out lo justifican con números. La tercera no es alternativa sino complemento: los datos que el
negocio quiere congelados —dirección de envío, precio en el momento de la compra— deben estar dentro
de `orders` en cualquiera de los tres diseños.

🔬 **El detalle** — La pregunta siguiente será qué pasa si `customers` no responde. Con BFF hay que
decidirlo explícitamente: devolver el pedido con el cliente vacío y marcado como no disponible suele
ser mejor que fallar la pantalla entera, y esa decisión es de producto, no de arquitectura.

---

# 03 — El camino desde el monolito

**03 → 1. ¿Qué es el patrón strangler fig y de dónde viene el nombre? 🟢**

⏱️ **30 segundos** — Poner una fachada delante del monolito y desviar tráfico ruta a ruta hacia
servicios nuevos, hasta que el monolito queda vacío y se apaga.

🗣️ **2 minutos** — El nombre viene de la higuera estranguladora, que crece alrededor de su árbol
hasta sostenerse sola cuando el original muere. Lo valioso no es la metáfora: es que la vuelta atrás
consiste en cambiar el desvío, así que cada paso es reversible en un minuto y el sistema queda entero
después de cada fase.

🔬 **El detalle** — La fachada puede ser el gateway, un proxy inverso o una capa dentro del propio
monolito. Lo que no puede cambiar es la URL que ve el cliente: si el cliente se entera, ya no es
transparente y la migración pasa a necesitar coordinación externa.

**03 → 2. ¿Cuáles son los cuatro pasos de branch by abstraction? 🟢**

⏱️ **30 segundos** — Crear la abstracción, hacer que todos pasen por ella, añadir la implementación
nueva detrás de un flag, y cambiar el flag y borrar la vieja.

🗣️ **2 minutos** — El segundo paso no cambia comportamiento: solo introduce la indirección, y por eso
es seguro. El tercero es donde vive la novedad, aislada tras el interruptor. El cuarto tiene dos
tiempos que se confunden: cambiar el flag y, semanas después, borrar la implementación vieja.

🔬 **El detalle** — La variante que más rinde en banca es ejecutar las dos implementaciones y comparar
resultados, mandando la vieja y registrando diferencias. Es la única forma honesta de saber si lo
nuevo replica diez años de parches.

**03 → 3. ¿Para qué sirve una capa anticorrupción? 🟢**

⏱️ **30 segundos** — Para traducir en la frontera con el legado, de modo que su modelo no se filtre
al modelo nuevo.

🗣️ **2 minutos** — Sin ella acabas con campos llamados como en el copybook del core y con reglas que
solo se entienden leyendo documentación de 1998. Con ella, esa fealdad queda encerrada en un
componente que se prueba solo. La regla es que la traducción vive en un único sitio: si aparece una
tabla de mapeo repetida en dos servicios, la capa ha fallado.

🔬 **El detalle** — Entre dos servicios nuevos que comparten lenguaje de dominio la capa es
ceremonia: ahí basta el contrato. El patrón se justifica por la asimetría —uno de los dos modelos no
lo controlas ni lo puedes cambiar—.

**03 → 4. ¿Qué se extrae primero en una migración, y por qué ese criterio? 🟢**

⏱️ **30 segundos** — Algo con frontera clara y datos propios, aunque sea poco importante, porque el
objetivo del primero es construir el camino.

🗣️ **2 minutos** — Cuando termine esa primera extracción tendrás plantilla de servicio, pipeline,
despliegue, observabilidad y fachada, que es infraestructura que sirve para todos los siguientes.
Empezar por lo doloroso —que suele ser lo más acoplado— arriesga un fracaso temprano que mata la
iniciativa entera.

🔬 **El detalle** — El segundo se elige ya por beneficio visible: algo con perfil de carga distinto,
para poder enseñar a negocio que ahora esa parte escala sola. El orden completo es camino → beneficio
visible → alcance de cumplimiento → lo doloroso.

**03 → 5. ¿En qué orden se separan datos y proceso? 🟢**

⏱️ **30 segundos** — Los datos primero, dentro del monolito; el proceso después.

🗣️ **2 minutos** — Primero se separan las tablas por módulo y se prohíben los `JOIN` entre módulos,
sustituyéndolos por llamadas internas. Después se separan esquemas o bases. Y solo entonces se saca
el proceso. Al revés, el "ya separaremos los datos" dura años, porque una vez fuera hay que coordinar
dos despliegues para conseguirlo.

🔬 **El detalle** — La fase de prohibir los `JOIN` duele en rendimiento y es deliberada: te enseña el
coste real de la frontera cuando todavía es barato cambiar de idea, en vez de descubrirlo cuando ya
es tráfico de red.

**03 → 6. Enumera las tres cosas que mides para dar una fase por terminada. 🟢**

⏱️ **30 segundos** — Independencia de despliegue, paridad funcional y latencia con tasa de error
comparadas contra el camino viejo.

🗣️ **2 minutos** — Independencia significa que desplegaste el servicio sin tocar el monolito. Paridad
significa que los resultados coinciden en las rutas migradas, incluidos los errores. Latencia y
errores se comparan en la misma ruta antes y después, porque una frontera mal puesta se nota ahí
primero.

🔬 **El detalle** — Falta la cuarta que nadie escribe: ¿se retiró el camino viejo? Mientras exista,
mantienes dos sistemas y la fase no ha terminado. Conviene ponerle fecha en el mismo momento en que
se desvía el tráfico.

**03 → 7. ¿Cuándo usarías branch by abstraction en vez de strangler fig? 🟡**

⏱️ **30 segundos** — Cuando lo que quiero extraer no tiene punto de entrada propio: está enterrado en
medio del código y lo llaman otros módulos por dentro.

🗣️ **2 minutos** — El strangler fig necesita una puerta que desviar —una ruta, un consumidor de cola,
un proceso por lotes—. Si la funcionalidad es una clase que llaman quince sitios, no hay nada que
desviar en el borde, y entonces la puerta hay que crearla dentro: eso es la abstracción.

🔬 **El detalle** — Los dos se combinan a menudo: la abstracción interna permite extraer el servicio,
y una vez extraído, el tráfico exterior se desvía en la fachada. No son alternativas excluyentes,
sino herramientas para capas distintas.

**03 → 8. ¿Por qué la reescritura completa fracasa aunque el equipo sea bueno? 🟡**

⏱️ **30 segundos** — Porque el sistema viejo sigue cambiando mientras reescribes, así que persigues
un blanco móvil y nunca hay un día en que ambos coincidan.

🗣️ **2 minutos** — Además el negocio no deja de pedir funcionalidad, y cada petición hay que
implementarla dos veces o negarla. Y el riesgo se concentra en un único evento de cambio: si algo
sale mal, no hay vuelta atrás gradual. Las migraciones por fases distribuyen ese riesgo en decenas de
pasos reversibles.

🔬 **El detalle** — Hay un caso donde la reescritura es defendible: sistemas pequeños, con
funcionalidad congelada por escrito y con un plazo corto. Reconocer esa excepción hace más creíble el
argumento general.

**03 → 9. Diferencia entre desviar por ruta y desviar por porcentaje de tráfico. 🟡**

⏱️ **30 segundos** — Por ruta mueves toda una funcionalidad de golpe; por porcentaje mueves una
fracción de las peticiones de esa misma ruta.

🗣️ **2 minutos** — El desvío por porcentaje permite validar con tráfico real antes de comprometerse:
un 1 %, mides errores y latencia, y subes. Cuesta que durante ese tiempo conviven dos caminos con la
misma funcionalidad, y si escriben datos hay que asegurarse de que ambos escriben donde toca.

🔬 **El detalle** — Para operaciones de lectura el porcentaje es casi gratis; para escrituras hay que
pensarlo: si el camino nuevo escribe en otra base, un usuario puede ver su propio cambio o no según
la lotería del reparto. Ahí conviene desviar por usuario, no por petición.

**03 → 10. ¿Por qué prohibir los `JOIN` entre módulos dentro del monolito es un paso de la migración y no una molestia? 🟡**

⏱️ **30 segundos** — Porque es la forma barata de descubrir el coste de la frontera antes de
convertirlo en una llamada de red irreversible.

🗣️ **2 minutos** — Si al prohibir el `JOIN` descubres que una pantalla necesita cinco consultas
encadenadas, acabas de aprender que esa frontera está mal puesta, y estás a tiempo de moverla
gratis. Si lo descubres después de extraer, el arreglo implica mover datos entre bases y coordinar
despliegues.

🔬 **El detalle** — Se puede verificar automáticamente: una prueba de arquitectura que falle cuando
un módulo accede a tablas de otro. Sin esa verificación, la prohibición dura hasta el primer
apurado.

**03 → 11. ¿Qué es el punto de no retorno de una migración y cómo se reconoce? 🟡**

⏱️ **30 segundos** — Cuando el dato nuevo deja de llegar al sistema viejo: a partir de ahí, volver
atrás implica migrar datos hacia atrás.

🗣️ **2 minutos** — Antes de ese punto, la vuelta atrás es cambiar un desvío. Después, el sistema
viejo ya no tiene la historia completa y restaurarlo exige un proceso de migración inversa que casi
nadie ha ensayado. Por eso el momento se decide explícitamente, se anuncia y se anota, en vez de
ocurrir sin que nadie lo note.

🔬 **El detalle** — Mientras convivan, la doble escritura tiene su propio coste y su propio riesgo:
si una de las dos falla, los sistemas divergen en silencio. Conviene una verificación periódica que
compare y alerte, no confiar en que ambas escrituras siempre funcionan.

**03 → 12. ¿Por qué la comparación en paralelo —las dos implementaciones a la vez— vale tanto en banca? 🟡**

⏱️ **30 segundos** — Porque permite descubrir los casos borde con tráfico real sin arriesgar dinero:
manda la implementación vieja y la nueva solo registra diferencias.

🗣️ **2 minutos** — En cálculos con años de parches —intereses, comisiones, impuestos— ninguna
especificación describe el comportamiento real; el comportamiento real está en el código viejo. La
comparación convierte la producción en la mejor batería de pruebas que puedes tener, y la lista de
diferencias es literalmente la lista de lo que falta.

🔬 **El detalle** — Cuesta duplicar el cómputo de esa operación y exige cuidado con los efectos
secundarios: la implementación nueva no puede escribir ni llamar a terceros mientras compara. Si no
se puede aislar de efectos, la comparación en paralelo no es aplicable y hay que decirlo.

**03 → 13. ¿Qué pones en la fachada y qué no pones nunca? 🟡**

⏱️ **30 segundos** — Enrutado, y como mucho traducción de formato. Nunca lógica de negocio.

🗣️ **2 minutos** — La fachada existe para que el cliente no se entere del cambio, así que su trabajo
es decidir a dónde va cada petición y, si acaso, adaptar la forma del mensaje. En cuanto empieza a
decidir reglas —qué descuentos aplican, si el pedido es válido—, se convierte en un tercer sitio
donde vive el dominio, y en el ESB rebautizado del capítulo siguiente.

🔬 **El detalle** — Hay una excepción tolerada y temporal: componer dos respuestas durante una fase
de transición para no romper al cliente. Se acepta con fecha y con dueño, igual que cualquier otra
deuda declarada.

**03 → 14. ¿Dónde vive la fachada del desvío en cada plataforma mientras no hay gateway, y qué te deja a ti en las cuatro? 🟡**

⏱️ **30 segundos** — En las cuatro es un filtro o middleware delante de la aplicación; lo que cambia
es cómo se implementa el interruptor y dónde se lee.

🗣️ **2 minutos** — En Java, un filtro de servlet o un controlador que reenvía; en Node/TS, un
middleware de Express o Fastify, o un interceptor de NestJS; en Go, un `http.Handler` que envuelve al
viejo, con el proxy inverso en la librería estándar; en Python, middleware ASGI o WSGI según el marco.
Lo que te deja a ti en las cuatro es decidir qué pasa con las peticiones en vuelo al cambiar el
desvío, y que el interruptor se lea **por petición** y no una vez al arrancar.

🔬 **El detalle** — Si el flag se lee al arrancar, la vuelta atrás exige un despliegue, que es justo lo
que el strangler fig intentaba evitar. Y en cuanto existe gateway, el desvío se va allí en las cuatro
por igual y esta diferencia deja de importar: suele ser lo normal a partir del tercer servicio.

---
**03 → 15. Tu primer servicio extraído no puede desplegarse sin desplegar el monolito. ¿Qué pasó y cómo lo arreglas? 🟠**

⏱️ **30 segundos** — Comparten algo: o la base de datos, o un contrato que no es compatible hacia
atrás, o una librería común de dominio.

🗣️ **2 minutos** — El diagnóstico es por descarte, en ese orden: ¿el servicio lee tablas del
monolito? ¿el monolito tiene que cambiar cada vez que cambia el contrato? ¿comparten un artefacto
versionado que hay que actualizar a la vez? La corrección del primero es separar los datos; la del
segundo, hacer el contrato compatible hacia atrás y versionarlo; la del tercero, duplicar el modelo.

🔬 **El detalle** — Hay una causa menos técnica y bastante frecuente: el pipeline los despliega juntos
porque nadie lo ha partido. Antes de rediseñar nada, conviene comprobar si el acoplamiento es real o
solo está en la herramienta de entrega.

**03 → 16. El negocio no autoriza ninguna ventana de parada y hay que mover 200 GB de datos. ¿Qué opciones tienes? 🟠**

⏱️ **30 segundos** — Copia inicial en caliente más replicación de cambios, y cambio de lectura cuando
el retraso sea suficientemente pequeño.

🗣️ **2 minutos** — El esquema es: copias el histórico mientras el sistema funciona; capturas los
cambios que ocurren durante la copia y los aplicas; cuando el retraso es de segundos, cambias las
lecturas al destino y, tras verificar, las escrituras. La alternativa es la doble escritura temporal
desde la aplicación, que es más simple de entender y más fácil de desincronizar.

🔬 **El detalle** — En los dos casos hace falta una verificación de igualdad por lotes —recuentos y
sumas por rango— antes de cortar, y un plan de qué hacer con las diferencias que aparezcan. La
migración no termina cuando los datos están: termina cuando alguien ha comprobado que son los mismos.

**03 → 17. ¿Cómo justificas ante negocio empezar por un módulo poco importante? 🟠**

⏱️ **30 segundos** — Porque el primero no se elige por su valor de negocio sino por lo que enseña: su
producto real es el camino de despliegue y operación para todos los siguientes.

🗣️ **2 minutos** — Se plantea con plazos: "en seis semanas tendremos el camino construido y el
segundo servicio saldrá en dos". Y se acompaña de qué se entrega en cada fase, para que negocio vea
avance. Si hace falta algo visible ya, el segundo servicio se elige por beneficio medible —una parte
que escale sola— y se enseña esa métrica.

🔬 **El detalle** — El argumento del riesgo funciona bien con perfiles no técnicos: empezar por lo
crítico significa que el primer error de una tecnología que el equipo aún no domina cae sobre la
parte que más factura.

**03 → 18. Llevas ocho meses de migración y el monolito ha crecido en ese tiempo. ¿Qué falló en el proceso? 🟠**

⏱️ **30 segundos** — Que se siguió añadiendo funcionalidad nueva al lado viejo: sin esa regla, la
migración no converge.

🗣️ **2 minutos** — La regla básica es que lo nuevo se construye fuera, aunque sea más incómodo. Si
eso no se puede sostener —porque la funcionalidad nueva depende de lo que aún no se ha migrado—, la
señal es que el orden de extracción estaba mal: había que haber empezado por ahí. La corrección es
revisar el orden en función de dónde está pidiendo cambios el negocio.

🔬 **El detalle** — Conviene medir la convergencia con un número simple y visible: líneas o endpoints
que quedan en el monolito, mes a mes. Si la curva no baja, la migración es teatro y es mejor saberlo
en el mes tres que en el dieciocho.

**03 → 19. Te piden mantener el camino viejo "por si acaso" durante un año. Argumenta. 🟠**

⏱️ **30 segundos** — Mantener los dos caminos cuesta el doble en cada cambio y garantiza que nadie
confíe del todo en el nuevo.

🗣️ **2 minutos** — La contrapropuesta es concreta: mantenerlo un periodo corto y medido —semanas—,
con criterios explícitos de retirada (cero tráfico, paridad verificada, un ciclo de cierre mensual
pasado). Y con una condición: mientras exista, no se le añade nada. Un año sin criterios significa
que el camino viejo se sigue parcheando y la migración no termina nunca.

🔬 **El detalle** — El coste oculto es cognitivo: con dos caminos vivos, cada incidente empieza con
"¿por cuál pasó esta petición?". Ese coste no aparece en ninguna estimación y es el que más
ralentiza al equipo.

**03 → 20. ¿Cómo mides la paridad funcional entre el camino viejo y el nuevo sin tener pruebas del monolito? 🟠**

⏱️ **30 segundos** — Con tráfico real: ejecutando ambos y comparando salidas, o reproduciendo tráfico
grabado contra el nuevo.

🗣️ **2 minutos** — Si la operación no tiene efectos secundarios, la comparación en paralelo es lo
mejor que hay. Si los tiene, se graba tráfico de producción y se reproduce contra el nuevo en un
entorno aislado, comparando respuestas. En ambos casos se empieza por las rutas más frecuentes, que
son las que cubren la mayor parte del comportamiento real.

🔬 **El detalle** — Las diferencias esperadas hay que catalogarlas antes: formato de fechas,
redondeos, orden de listas. Sin ese catálogo, el equipo se ahoga en falsos positivos y acaba
ignorando el informe entero.

**03 → 21. El servicio nuevo tiene peor p99 que el monolito en la misma ruta. Da tres hipótesis en orden de probabilidad. 🟠**

⏱️ **30 segundos** — Llamadas de red que antes eran locales; arranque en frío o pool mal
dimensionado; y consultas que perdieron su `JOIN` y ahora son varias.

🗣️ **2 minutos** — La primera se confirma con la traza: cuenta los saltos por petición. La segunda se
ve en la distribución —si el p99 es malo pero la mediana es buena, huele a pool, a recolección de
basura o a conexión fría—. La tercera se ve en el número de consultas por petición contra la base de
datos.

🔬 **El detalle** — Hay una cuarta menos obvia: el cliente HTTP con `keep-alive` mal configurado
abriendo conexión nueva en cada llamada, incluido el saludo TLS. Se detecta mirando conexiones
abiertas por segundo, y es un arreglo de una línea que a veces vale cientos de milisegundos.

**03 → 22. Diseña el plan de extracción de `payments` desde un monolito bancario, en fases, con lo que se despliega en cada una y cómo se vuelve atrás. 🔴**

⏱️ **30 segundos** — Cinco fases: aislar dentro, separar datos, extraer en sombra, desviar por
porcentaje, y retirar el camino viejo.

🗣️ **2 minutos** — El plan:

```text
F1  Módulo pagos aislado dentro del monolito, tras una interfaz. Sin JOIN externos.
    Vuelta atrás: revertir el despliegue del monolito.
F2  Tablas de pagos en su propio esquema. Acceso solo por el módulo.
    Vuelta atrás: el esquema anterior sigue existiendo hasta F4.
F3  Servicio pagos desplegado, recibiendo copia del tráfico (sombra, sin efectos).
    Vuelta atrás: apagar la copia; no afecta a producción.
F4  Desvío real por porcentaje, empezando por 1 %. Idempotencia obligatoria.
    Vuelta atrás: bajar el porcentaje a cero.
F5  100 %, verificación de un cierre contable, y retirada del módulo viejo.
    Punto de no retorno: cuando el monolito deje de recibir los movimientos.
```

🔬 **El detalle** — En banca, F5 no se cierra sin pasar al menos un cierre contable completo con el
camino nuevo y sin diferencias de conciliación. Y F4 exige clave de idempotencia desde el primer día:
un reintento durante el desvío es exactamente cómo se cobra dos veces.

**03 → 23. Tienes que extraer un módulo cuya lógica está repartida en quince clases y tres procedimientos almacenados. Da la secuencia completa. 🔴**

⏱️ **30 segundos** — Primero reunir la lógica dentro del monolito tras una interfaz, incluidos los
procedimientos; después separar datos; y solo entonces extraer.

🗣️ **2 minutos** — La secuencia:

```text
1. Inventario: qué hace cada clase y cada procedimiento, y quién los llama.
2. Interfaz única: todo el mundo pasa por ella (branch by abstraction).
3. Los procedimientos almacenados suben a código, uno a uno, con comparación
   en paralelo: es la parte lenta y la que no se puede saltar.
4. Tablas al esquema propio; se prohíben accesos externos.
5. Extracción del servicio detrás de la misma interfaz.
6. Retirada de las clases y procedimientos viejos.
```

🔬 **El detalle** — Los procedimientos almacenados son el riesgo principal: suelen contener reglas que
nadie recuerda y que ninguna documentación describe. Subirlos a código sin comparación en paralelo es
la forma más rápida de introducir un error silencioso en cálculos que el negocio da por ciertos.

**03 → 24. Escribe el criterio de aceptación de una fase de migración: qué se mide, con qué umbral, y qué decisión se toma con cada resultado. 🔴**

⏱️ **30 segundos** — Tres medidas —independencia, paridad y latencia/errores— cada una con umbral y
con una decisión asociada: seguir, corregir o revertir.

🗣️ **2 minutos** — Un criterio utilizable:

```text
Medida            Umbral                         Decisión
────────────────  ─────────────────────────────  ────────────────────────
Despliegue solo   1 despliegue sin tocar otros   no → la fase no terminó
Paridad           0 diferencias no catalogadas   >0 → corregir, no avanzar
p99               ≤ p99 anterior + 20 %          fuera → investigar antes de subir tráfico
Tasa de error     ≤ la anterior                  peor → revertir el desvío
```

Y se añade la condición de retirada: el camino viejo se borra cuando lleva dos semanas con cero
tráfico y ha pasado un ciclo de negocio completo.

🔬 **El detalle** — El umbral de latencia merece explicarse: se acepta un empeoramiento porque la
llamada de red es real e inevitable, pero se acota para que no se cuele una frontera mal puesta bajo
la excusa de "es normal, ahora hay red".

**03 → 25. El equipo propone reescribir el monolito entero en una plataforma nueva y migrar en un fin de semana. Da tu contraargumento y una alternativa concreta con fases. 🔴**

⏱️ **30 segundos** — El contraargumento es el riesgo concentrado: un único evento sin vuelta atrás
gradual, sobre un sistema cuyo comportamiento real nadie tiene documentado.

🗣️ **2 minutos** — Tres objeciones concretas: mientras se reescribe, el monolito sigue cambiando; el
comportamiento real está en el código viejo y no en ninguna especificación; y la vuelta atrás de un
fin de semana es migrar datos hacia atrás bajo presión. La alternativa:

```text
Semanas 1-6    fachada + primer servicio fácil: camino construido
Semanas 7-14   segundo servicio, elegido por carga: beneficio medible
A partir de ahí una extracción por trimestre, con datos primero
En todo momento  lo nuevo se construye fuera; el monolito no crece
```

🔬 **El detalle** — Conviene conceder lo que tiene de razonable la propuesta: si lo que molesta es la
plataforma vieja, los servicios nuevos ya se escriben en la nueva, así que el objetivo se cumple igual
—más despacio y sin jugarse el negocio en un fin de semana—. Ceder el objetivo y discutir solo el
método es lo que hace que el argumento se acepte.

---

# 04 — El monolito distribuido

**04 → 1. ¿Qué es un monolito distribuido? 🟢**

⏱️ **30 segundos** — Un sistema con todos los costes de la separación —red, sagas, trazas, N
pipelines— y ninguno de sus beneficios, porque sigue habiendo que desplegarlo todo junto.

🗣️ **2 minutos** — Es peor que el monolito del que se venía: antes al menos las llamadas eran en
memoria y había transacciones. No se llega por una mala decisión grande, sino por cinco pequeñas y
razonables: una tabla compartida, una librería común, una cadena de llamadas, un servicio anémico y
una regla puesta en el gateway.

🔬 **El detalle** — La medida más limpia es el número de despliegues necesarios para poner en
producción el cambio más pequeño posible. Si es más de uno, hay monolito distribuido, con
independencia de cuántos servicios haya en el diagrama.

**04 → 2. Enumera las cuatro preguntas que lo detectan. 🟢**

⏱️ **30 segundos** — ¿Puedes desplegar uno solo? ¿Probar uno solo? ¿Un cambio de negocio toca un
repositorio? ¿Puedes apagar un servicio secundario sin tumbar la pantalla?

🗣️ **2 minutos** — Cada "no" apunta a una causa distinta: contrato o datos compartidos; dependencias
en caliente en las pruebas; frontera que no coincide con la razón de cambio; y falta de aislamiento
—timeouts, circuit breaker, degradación—.

🔬 **El detalle** — Son también buenas preguntas para hacerle tú al entrevistador cuando describa su
sistema. Preguntar "¿cuántos despliegues hacen falta para un cambio pequeño?" demuestra más criterio
que enumerar patrones.

**04 → 3. ¿Por qué compartir base de datos rompe el despliegue independiente? 🟢**

⏱️ **30 segundos** — Porque el otro depende de la forma física de tus tablas, así que cualquier
cambio de esquema exige coordinar.

🗣️ **2 minutos** — El primer renombrado se convierte en una negociación con dos equipos y una
ventana; a partir del segundo episodio nadie renombra nada y el esquema se congela. Hay además
acoplamiento de rendimiento: una consulta ajena puede tumbar tu servicio sin que tú hayas desplegado
nada.

🔬 **El detalle** — La forma acotada, cuando el acceso directo es imprescindible, es una vista
estable con nombre propio y versionada, que actúa de contrato: puedes cambiar las tablas de debajo
mientras la vista se mantenga.

**04 → 4. ¿Qué diferencia hay entre compartir un cliente generado y compartir un modelo de dominio? 🟢**

⏱️ **30 segundos** — El cliente generado es el contrato publicado por su dueño y versionado; el
modelo de dominio es cómo piensa ese servicio por dentro.

🗣️ **2 minutos** — El primero acopla a una versión del contrato, que es precisamente lo que quieres:
tiene compatibilidad hacia atrás y evolución negociada. El segundo acopla a decisiones internas, y
cualquier refactor del dueño se convierte en un despliegue de todos.

🔬 **El detalle** — La prueba práctica: ¿lo publica el dueño del contrato a partir del contrato, o lo
escribe alguien a mano copiando clases? Lo generado a partir de un `.proto` o de un OpenAPI es sano;
el paquete `common` con las entidades dentro no.

**04 → 5. ¿Qué es un servicio anémico? 🟢**

⏱️ **30 segundos** — Uno que no toma ninguna decisión: recibe, valida el formato y guarda. Toda la
regla vive en quien lo llama.

🗣️ **2 minutos** — Es el resultado del corte por entidad. El problema no es el servicio en sí, es lo
que produce al otro lado: un orquestador con todas las reglas de negocio, que es el monolito otra
vez, pero con red en medio y sin transacciones.

🔬 **El detalle** — La corrección no es fusionar por fusionar, es mover la regla al dueño del dato.
Si `orders` decide cuándo un pedido es válido, esa regla pertenece a `orders` aunque hoy esté en el
que llama.

**04 → 6. ¿Qué va en el gateway y qué no? 🟢**

⏱️ **30 segundos** — Va TLS, autenticación, límite de tasa, enrutado y observabilidad. No va nada que
necesite conocer el significado del mensaje.

🗣️ **2 minutos** — En cuanto el gateway decide reglas de negocio, se convierte en un tercer sitio
donde vive el dominio, y el equipo que lo mantiene pasa a ser cuello de botella de todos los demás.
El síntoma es organizativo antes que técnico: cambiar una regla implica entrar en la cola de otro
equipo.

🔬 **El detalle** — La excepción tolerada es temporal: componer o adaptar respuestas durante una fase
de migración para no romper a un cliente. Se acepta con fecha y con dueño, como cualquier deuda
declarada.

**04 → 7. Un módulo `common` con entidades JPA dentro: ¿qué antipatrón es en realidad? 🟢**

⏱️ **30 segundos** — Base de datos compartida, disfrazada de librería.

🗣️ **2 minutos** — Si las entidades de persistencia son compartidas, todos los servicios conocen el
mismo esquema físico y ninguno puede cambiarlo solo. Añade el acoplamiento de artefacto —subir la
versión obliga a recompilar y desplegar— encima del acoplamiento de datos que ya tenías.

🔬 **El detalle** — La variante equivalente en otras plataformas es el paquete con los modelos de
SQLAlchemy o con el esquema de Prisma compartido. Cambia el nombre, no el efecto: quien comparte el
mapeo, comparte la base.

**04 → 8. Calcula la disponibilidad compuesta de una cadena de cinco servicios al 99,9 % y di qué significa en minutos al mes. 🟡**

⏱️ **30 segundos** — 0,999⁵ ≈ 99,5 %, que pasa de unos 43 minutos de caída al mes a unas 3,6 horas.

🗣️ **2 minutos** — La multiplicación es la clave: cada dependencia síncrona obligatoria reduce la
disponibilidad del conjunto, aunque cada pieza sea excelente. Es el argumento aritmético contra las
cadenas largas, y funciona mejor que cualquier apelación a la elegancia.

🔬 **El detalle** — El cálculo asume independencia entre fallos, que en la práctica no se cumple:
comparten red, plataforma y a veces base de datos, así que los fallos se correlacionan y el número
real suele ser peor. Y una dependencia **opcional** con degradación no entra en la multiplicación,
que es justo por lo que vale hacerla opcional.

**04 → 9. ¿Por qué la latencia de una cadena síncrona se suma en vez de solaparse? 🟡**

⏱️ **30 segundos** — Porque cada salto espera la respuesta del siguiente antes de continuar: no hay
paralelismo que solape nada.

🗣️ **2 minutos** — Cinco saltos de 50 ms son 250 ms en el camino feliz, y eso sin contar reintentos
ni saludos TLS. Si las llamadas no dependen entre sí, se pueden lanzar en paralelo y entonces manda
la más lenta en vez de la suma; esa es la primera optimización que hay que buscar.

🔬 **El detalle** — El caso peor no es la suma de latencias sino la de timeouts: con dos segundos por
salto y sin presupuesto total, el usuario puede esperar diez segundos antes de recibir un error. Por
eso el timeout se reparte de arriba abajo y decrece según se baja.

**04 → 10. "Solo lectura no acopla": desmóntalo en dos frases. 🟡**

⏱️ **30 segundos** — El lector depende de la forma física de las tablas, así que el escritor no puede
migrar sin coordinar. Y una consulta del lector puede degradar al escritor.

🗣️ **2 minutos** — El acoplamiento no viene de escribir, viene de conocer. Además hay un efecto
social: cuando el esquema no se puede cambiar sin negociación, deja de cambiarse, y el diseño se
congela alrededor de decisiones viejas.

🔬 **El detalle** — Si la lectura es imprescindible y no da tiempo a montar una API, la forma menos
mala es una réplica con una vista contractual y fecha de revisión. Lo que la convierte en deuda
eterna no es la técnica, es que nadie sea dueño de cerrarla.

**04 → 11. ¿En qué se parecen el corte por entidad y el servicio anémico? 🟡**

⏱️ **30 segundos** — El primero produce el segundo: si cortas por tabla, el servicio resultante solo
puede hacer CRUD.

🗣️ **2 minutos** — Al cortar por entidad, las reglas —que casi siempre relacionan varias entidades—
no caben dentro de ningún servicio, así que se van al que los llama. El resultado es un orquestador
que concentra el dominio y un conjunto de servicios que solo persisten.

🔬 **El detalle** — La señal de que estás ahí: los nombres de los servicios son sustantivos del modelo
de datos en plural —`customers`, `addresses`, `prices`— en vez de capacidades del negocio. No es
una regla infalible, pero acierta muchas veces.

**04 → 12. ¿Por qué el fallo se propaga hacia arriba en la cadena y no hacia abajo? 🟡**

⏱️ **30 segundos** — Porque lo que se propaga es la espera: el que llama se queda con los recursos
ocupados mientras el de abajo tarda.

🗣️ **2 minutos** — Una dependencia lenta consume hilos, conexiones o memoria del que llama, y cuando
se agotan, ese servicio deja de atender **todo**, incluidas las rutas que no dependían del lento. Por
eso el servicio que se cae no suele ser el que falla, y por eso el diagnóstico empieza siempre por la
traza y no por el que dio el error.

🔬 **El detalle** — De ahí que el bulkhead —pools separados por dependencia— sea tan efectivo:
convierte un agotamiento total en una degradación parcial. Y de ahí que el timeout sea la pieza
número uno: sin él, no hay recurso que se libere.

**04 → 13. ¿Cómo distingues una librería compartida sana de una tóxica, sin abrir el código? 🟡**

⏱️ **30 segundos** — Por quién la publica y por qué pasa cuando cambia: si al subir versión hay que
desplegar a todos, es tóxica.

🗣️ **2 minutos** — La sana es técnica —logging, métricas, cliente HTTP configurado, el chassis— o es
un cliente generado a partir de un contrato versionado, publicado por el dueño de ese contrato. La
tóxica contiene modelo de dominio, reglas o acceso a datos, y suele ser mantenida por "todos", que es
lo mismo que por nadie.

🔬 **El detalle** — Un indicio sin abrir el código: la frecuencia de versiones. Una librería de
chassis cambia poco y por motivos técnicos; una que contiene dominio cambia cada semana y sus notas
de versión hablan de negocio.

**04 → 14. Te dan acceso a un repositorio ajeno y diez minutos. ¿Qué miras para saber si hay monolito distribuido? 🟡**

⏱️ **30 segundos** — El pipeline, las dependencias compartidas y las cadenas de llamadas entre
servicios.

🗣️ **2 minutos** — En orden: ¿hay un pipeline que despliega varios servicios juntos? ¿existe un
paquete `common` y qué contiene —tipos generados o dominio—? ¿cuántas llamadas salientes hace un
servicio típico y a cuántos destinos? ¿las pruebas necesitan levantar otros servicios? Con esas cuatro
respuestas se acierta casi siempre.

🔬 **El detalle** — Si además hay acceso al historial, la comprobación más rápida es contar cuántos
commits tocan más de un servicio. Si es la mayoría, la respuesta ya está y no hace falta abrir un
solo archivo de código.

**04 → 15. ¿Por qué el paquete compartido tóxico aparece con más facilidad en Java y Python que en Go, y qué lo explica en cada caso 🟡**

⏱️ **30 segundos** — Porque en Java y Python la herramienta empuja a compartir el modelo de datos, y en
Go la cultura empuja a copiar. No es virtud del lenguaje: es dónde cae el camino fácil.

🗣️ **2 minutos** — En Java, el módulo `common` con entidades JPA dentro es casi el valor por defecto de
un proyecto multi-módulo, y esas entidades traen el mapeo a tablas consigo: compartirlas es compartir
la base de datos en forma de artefacto. En Python pasa lo mismo con los modelos de SQLAlchemy o los
esquemas de Pydantic publicados en un paquete privado. En Go la comunidad prefiere duplicar una struct
antes que acoplar dos servicios, así que el antipatrón aparece menos; cuando aparece, suele venir con
el cliente de base de datos dentro, que es la versión grave. En Node/TS el caso intermedio: el
`packages/shared` del monorepo es sano si exporta tipos generados del contrato y tóxico si exporta
lógica.

🔬 **El detalle** — La conclusión útil para una entrevista es que el criterio no cambia con el lenguaje,
solo cambia el disfraz: contrato sí, dominio no. Y la prueba es siempre la misma pregunta —*¿quién
despliega cuando esto cambia?*—, que no depende de la plataforma.

---
**04 → 16. Tienes quince servicios y un único pipeline que los despliega en orden. ¿Por dónde empiezas a desacoplar? 🟠**

⏱️ **30 segundos** — Por el servicio con menos dependencias entrantes, y por averiguar si el
acoplamiento es real o solo está en la herramienta.

🗣️ **2 minutos** — Primero se comprueba si el pipeline los despliega juntos por necesidad —contratos
incompatibles, datos compartidos— o por costumbre. Si es costumbre, partir el pipeline es barato y da
una victoria inmediata. Si es necesidad, se ataca en este orden: hacer los contratos compatibles hacia
atrás, separar los datos compartidos, y romper la librería común de dominio.

🔬 **El detalle** — Conviene medirlo con un indicador visible: número de servicios desplegables por
separado, semana a semana. Sin ese número, el trabajo de desacoplar es invisible para quien decide
las prioridades.

**04 → 17. Una pantalla necesita datos de cuatro servicios. Da dos diseños que eviten la cadena síncrona y di qué cuesta cada uno. 🟠**

⏱️ **30 segundos** — Composición en paralelo desde un BFF, o una proyección de lectura mantenida por
eventos.

🗣️ **2 minutos** — El BFF llama a los cuatro a la vez: la latencia pasa de ser la suma a ser la del
más lento, y hay que decidir qué se hace si uno falla —devolver la pantalla con un hueco suele ser
mejor que fallar entera—. La proyección da lectura de un solo salto y latencia mínima, y cuesta
consistencia eventual, un proceso que la mantiene y un plan para reconstruirla.

🔬 **El detalle** — La diferencia real es dónde pones la complejidad: el BFF no añade estado nuevo y
es reversible; la proyección añade un almacén más que puede corromperse. Se empieza por el BFF y se
pasa a proyección cuando los números —latencia, fan-out— lo justifiquen.

**04 → 18. El equipo de plataforma tiene tres meses de cola porque todas las reglas están en el gateway. ¿Qué propones y en qué orden? 🟠**

⏱️ **30 segundos** — Devolver las reglas a los servicios dueños, empezando por las que más cambian.

🗣️ **2 minutos** — El orden se saca de la propia cola: qué reglas generan más peticiones de cambio.
Esas se mueven primero al servicio dueño, dejando en el gateway solo enrutado y borde. Mientras
tanto, se permite a los equipos proponer cambios en el gateway por pull request para descongestionar
la cola sin esperar al rediseño.

🔬 **El detalle** — Hay una parte organizativa que no se arregla con arquitectura: el equipo de
plataforma tiene que aceptar dejar de ser el que decide. Si no hay ese acuerdo, las reglas vuelven al
gateway en tres meses por la puerta de atrás.

**04 → 19. ¿Cuándo fusionarías dos servicios, y cómo lo justificas ante quien los creó? 🟠**

⏱️ **30 segundos** — Cuando cambian siempre juntos, hablan mucho entre ellos o comparten escritor de
datos. Se justifica con los datos, no con opiniones.

🗣️ **2 minutos** — La justificación se apoya en tres números medibles: porcentaje de cambios que
tocan los dos, llamadas cruzadas por caso de uso, y despliegues coordinados en los últimos tres
meses. Con eso, la conversación deja de ser sobre gusto arquitectónico. Y conviene enmarcarla como lo
que es: juntar es barato y reversible, no es admitir un fracaso.

🔬 **El detalle** — Fusionar no significa borrar la frontera: se mantiene como módulo dentro del
servicio resultante, con su paquete y sus pruebas. Así, si mañana vuelve a hacer falta separar, el
corte está preparado.

**04 → 20. Un servicio secundario se cae y tumba la pantalla principal. Da tres correcciones ordenadas por relación entre efecto y esfuerzo. 🟠**

⏱️ **30 segundos** — Timeout explícito y corto; degradación con valor por defecto; y pool separado o
circuit breaker hacia esa dependencia.

🗣️ **2 minutos** — El timeout es una línea de configuración y evita el agotamiento de recursos, así
que va primero. La degradación —mostrar la pantalla sin ese bloque— convierte una caída en una
molestia y es decisión de producto, no solo técnica. El aislamiento por pools o el circuit breaker
evita que esa dependencia consuma la capacidad de las rutas que no la usan.

🔬 **El detalle** — Hay una cuarta que a veces es la correcta: sacar esa llamada de la ruta síncrona.
Si el dato secundario no hace falta para responder, se pide después o se precalcula, y el problema
desaparece en vez de gestionarse.

**04 → 21. ¿Cómo repartirías un presupuesto de latencia de 800 ms entre una cadena de tres saltos? 🟠**

⏱️ **30 segundos** — De arriba abajo y decreciente: el timeout de cada salto menor que el de quien lo
llama, dejando margen para el trabajo propio.

🗣️ **2 minutos** — Un reparto razonable:

```text
Entrada (usuario)        800 ms de presupuesto total
  orders                 consume 100 ms propios → deja 700 para llamar
    customers            timeout 400 ms, incluidos sus propios saltos
      segments           timeout 200 ms
  margen de reintento    lo que sobra, y solo para lo idempotente
```

Lo esencial es que ningún salto tenga un timeout mayor o igual que el de su llamador: si lo tiene, el
de arriba corta antes y el trabajo de abajo se tira a la basura.

🔬 **El detalle** — El presupuesto se propaga mejor si el protocolo lo lleva: los deadlines de gRPC
viajan por la cadena y cada salto sabe cuánto le queda. Con HTTP hay que hacerlo a mano, normalmente
con un encabezado propio y disciplina.

**04 → 22. Diagnostica: p99 de `orders` sube a 8 s, CPU normal, hilos al máximo, y `payments` tiene una consulta lenta. Explica la cadena y di dónde la cortarías. 🔴**

⏱️ **30 segundos** — `payments` responde lento, y los hilos de `orders` se quedan esperando hasta
agotarse; a partir de ahí `orders` deja de atender todo, incluso lo que no usa `payments`.

🗣️ **2 minutos** — La cadena:

```text
usuario ─► orders ─► customers ─► segments ─► payments ─► base de datos lenta
              │ hilos ocupados esperando 8 s
              └─► se agota el pool → 503 en TODAS las rutas
```

Dónde cortar, por orden: timeout explícito en `orders` hacia `customers` —más corto que el
presupuesto de la ruta—, pool separado para esa dependencia, y circuit breaker que abra cuando la tasa
de lentitud supere el umbral. El arreglo de la consulta lenta es necesario, pero es el detonante, no
la causa.

🔬 **El detalle** — El entrevistador preguntará por qué falla también lo que no toca `payments`. La
respuesta es que el recurso agotado es compartido —el pool de hilos del servidor—, y que por eso el
bulkhead es la corrección estructural: convierte un agotamiento total en una degradación parcial.

**04 → 23. Diseña el plan de seis meses para convertir quince servicios que se despliegan juntos en algo que se despliega por separado. 🔴**

⏱️ **30 segundos** — Tres frentes en paralelo: contratos compatibles, datos separados, y pipeline
partido servicio a servicio, empezando por las hojas del grafo de dependencias.

🗣️ **2 minutos** — El plan:

```text
Mes 1      Medir: grafo de dependencias, commits que cruzan servicios, datos compartidos.
Mes 1-2    Contratos: versionado y compatibilidad hacia atrás obligatoria en CI.
Mes 2-4    Datos: eliminar accesos cruzados, empezando por los de solo lectura
           (vista contractual o API), y luego los de escritura.
Mes 3-5    Librería común: partir en chassis técnico + clientes generados; el dominio se duplica.
Mes 4-6    Pipeline: un servicio por semana sale del despliegue conjunto, empezando por las hojas.
Continuo   Indicador visible: servicios desplegables solos / total.
```

🔬 **El detalle** — El orden importa: partir el pipeline antes de arreglar contratos y datos produce
incidentes inmediatos y hace que el equipo vuelva al despliegue conjunto. El pipeline es la
consecuencia, no la palanca.

**04 → 24. Escribe el conjunto de reglas de revisión de código que evitaría los cinco antipatrones del capítulo, y di cuál de ellas es automatizable. 🔴**

⏱️ **30 segundos** — Cinco reglas: sin acceso a datos ajenos, sin dominio en librerías compartidas,
sin cadenas de más de dos saltos, sin servicios sin decisiones, y sin lógica de negocio en el
gateway.

🗣️ **2 minutos** — Con su nivel de automatización:

```text
Regla                                        ¿Automatizable?
──────────────────────────────────────────── ────────────────────────────────
Ningún servicio accede a tablas ajenas       sí: prueba de arquitectura + revisión de credenciales
La librería común no contiene dominio        parcial: prohibir paquetes/anotaciones concretas
Ninguna ruta encadena más de 2 saltos        sí: alerta sobre las trazas, no en revisión
Todo servicio toma alguna decisión           no: es criterio humano
El gateway no conoce el dominio              parcial: prohibir transformaciones por contenido
```

🔬 **El detalle** — Las dos automatizables de verdad valen más que las tres restantes juntas, porque
las reglas que dependen de la disciplina humana se cumplen hasta el primer viernes con prisa. Y la de
las trazas es la más barata de todas: no requiere tocar el código, solo mirar lo que ya se está
midiendo.

**04 → 25. Un equipo defiende su librería `common` con el argumento de no duplicar la clase `Customer`. Responde en dos minutos, concediendo lo que tiene de razón. 🔴**

⏱️ **30 segundos** — Tienen razón en que duplicar código es un coste. La cuestión es que aquí no es
duplicación: son modelos distintos que hoy se parecen.

🗣️ **2 minutos** — El argumento completo: `orders` necesita del cliente su dirección de envío,
`payments` su medio de pago y su riesgo, `customers` su identidad y sus consentimientos. Hoy la clase
compartida es la unión de las tres, con campos opcionales que solo usa uno; mañana, cada cambio de
uno obliga a desplegar a los tres. Lo que sí conviene compartir es el **cliente generado** a partir
del contrato de `customers`, publicado por su equipo y versionado — con eso se elimina el trabajo
repetido de verdad sin el acoplamiento.

🔬 **El detalle** — Conviene ofrecer un camino y no solo una negativa: partir `common` en dos, un
chassis técnico que se queda y un paquete de dominio que se congela y se va vaciando a medida que
cada servicio se queda con su modelo. Así la propuesta es un plan, no una crítica.

---

# 05 — El servicio por dentro

**05 → 1. ¿Cuáles son las cuatro zonas de la estructura interna y cuál es la regla de dependencia? 🟢**

⏱️ **30 segundos** — Transporte, aplicación, dominio y salida. Las dependencias apuntan hacia dentro:
el dominio no conoce a nadie.

🗣️ **2 minutos** — El transporte son controladores, consumidores y handlers; la aplicación son los
casos de uso, que orquestan sin decidir reglas; el dominio tiene las invariantes; y salida son
repositorios, clientes de otros servicios y publicadores. La consecuencia práctica es que el caso de
uso se puede probar sin levantar nada.

🔬 **El detalle** — En un servicio de solo lectura la capa de dominio queda vacía, y entonces la
estructura completa es ceremonia: se admite ir del transporte a la consulta y se declara. Reconocer
esa excepción vale más que aplicar la estructura por defecto.

**05 → 2. ¿Qué es un service chassis y qué contiene? 🟢**

⏱️ **30 segundos** — Las piezas transversales que todo servicio necesita y ninguna es de negocio:
configuración, logs, métricas, tracing, health checks, cliente HTTP con timeouts y apagado ordenado.

🗣️ **2 minutos** — Existe para que el servicio número seis no vuelva a decidir el formato de log ni
el nombre del endpoint de salud. Se reparte entre librería —lo que debe ser idéntico— y plantilla
—lo que cada servicio va a tocar—, y tiene un dueño que decide qué entra.

🔬 **El detalle** — Su única regla dura: ni una línea de dominio dentro. El día que la tiene, subir su
versión obliga a desplegar a todos y el chassis se convierte en el monolito del capítulo `04`.

**05 → 3. Diferencia entre liveness y readiness. 🟢**

⏱️ **30 segundos** — Liveness pregunta si hay que reiniciarte; readiness, si puedes recibir tráfico
ahora.

🗣️ **2 minutos** — Si falla liveness, la plataforma reinicia el proceso. Si falla readiness, te saca
del balanceo pero te deja vivo, para que puedas recuperarte. Por eso liveness no comprueba
dependencias y readiness sí comprueba las imprescindibles.

🔬 **El detalle** — Hay una tercera sonda, la de arranque, que existe para procesos que tardan en
estar listos: evita que liveness los mate mientras todavía están levantando. En plataformas con JVM y
carga inicial de caché es la que evita el bucle de reinicios en el primer despliegue.

**05 → 4. Enumera los cinco pasos de un apagado ordenado. 🟢**

⏱️ **30 segundos** — Marcarse como no listo, esperar a que el balanceador se entere, terminar lo que
está en vuelo, cerrar pools y consumidores, y salir.

🗣️ **2 minutos** — El segundo paso es el que casi nadie modela y el que produce los errores: entre
que la instancia deja de estar lista y el balanceador se entera pasan segundos. Cerrar de inmediato
tira esas peticiones, aunque el resto del apagado esté perfecto.

🔬 **El detalle** — En un consumidor de cola la secuencia es otra: dejar de pedir mensajes, terminar
el actual, confirmar y cerrar. Si cierra sin confirmar, el mensaje se reentrega, y ahí la
idempotencia del consumidor deja de ser teoría.

**05 → 5. ¿Por qué la configuración va fuera del artefacto? 🟢**

⏱️ **30 segundos** — Para que la misma imagen que pasó las pruebas sea exactamente la que corre en
producción.

🗣️ **2 minutos** — Si la configuración viaja dentro, hay que reconstruir por entorno, y entonces lo
que probaste no es lo que despliegas. Además obliga a meter secretos en el artefacto o en el
repositorio, que es el otro problema. La jerarquía habitual va de valores por defecto a variables de
entorno y secretos inyectados.

🔬 **El detalle** — El matiz moderno: no todo se lee al arrancar. Los feature flags y el nivel de log
deben poder cambiar en caliente; el resto, no, porque la recarga dinámica de todo añade estados
imposibles de reproducir.

**05 → 6. ¿Qué debe pasar si falta una variable de configuración obligatoria? 🟢**

⏱️ **30 segundos** — Que el servicio falle al arrancar, con un mensaje que diga qué falta.

🗣️ **2 minutos** — Arrancar sin la URL de una dependencia convierte un error de despliegue —barato,
visible, con vuelta atrás automática— en un incidente que aparece en la primera petición real y que
alguien tiene que diagnosticar. Validar al arrancar cuesta escribir el esquema de configuración una
vez.

🔬 **El detalle** — El matiz: distinguir obligatorio de opcional con valor por defecto sensato. Si
todo es obligatorio, cada despliegue nuevo se convierte en una caza de variables; si nada lo es, los
fallos se posponen hasta producción.

**05 → 7. ¿Por qué el chassis es la única librería compartida legítima entre servicios? 🟡**

⏱️ **30 segundos** — Porque contiene decisiones técnicas que deben ser idénticas y que no cambian
cuando cambia el negocio.

🗣️ **2 minutos** — El acoplamiento que produce una librería compartida se paga cuando cambia a
menudo. El formato de log, los nombres de métricas y la propagación de contexto cambian poco y, si
cambian, conviene que cambien para todos. El dominio es lo contrario: cambia cada semana y solo para
uno.

🔬 **El detalle** — Hay un segundo tipo legítimo: el cliente generado a partir del contrato de otro
servicio, publicado por su dueño y versionado. La diferencia con `common` es quién lo publica y de
dónde sale: lo genera el contrato, no lo escribe alguien copiando clases.

**05 → 8. Chassis contra plantilla: ¿qué resuelve cada uno y qué se le escapa? 🟡**

⏱️ **30 segundos** — La librería garantiza que lo transversal sea idéntico y se pueda actualizar; la
plantilla arranca rápido pero diverge en cuanto se toca.

🗣️ **2 minutos** — Con librería, una mejora llega a todos subiendo versión, y a cambio hay que
gobernarla y evitar que crezca. Con plantilla, cada servicio es libre —lo que en Go se prefiere—,
pero un arreglo hay que replicarlo servicio a servicio. En la práctica se combinan: librería para lo
idéntico, plantilla para lo que cada equipo va a modificar.

🔬 **El detalle** — El punto de decisión es la frecuencia de cambio: si algo va a cambiar cada mes
para todos —el formato de traza, por ejemplo— tiene que estar en librería o nunca estará actualizado
en los quince servicios.

**05 → 9. ¿Por qué comprobar la base de datos en liveness convierte una degradación en una caída total? 🟡**

⏱️ **30 segundos** — Porque si la base se cae, todas las instancias fallan la sonda y la plataforma
las reinicia en bucle mientras el problema sigue ahí.

🗣️ **2 minutos** — El reinicio no arregla nada —la base sigue caída— y además pierdes las peticiones
que podían atenderse desde caché o las rutas que no usan la base. Lo correcto es que la dependencia
esté en readiness, donde saca la instancia del balanceo sin matarla, permitiendo que se recupere sola
cuando la base vuelva.

🔬 **El detalle** — En sistemas grandes, ese bucle de reinicios produce además una tormenta de
conexiones cuando la base vuelve: todas las instancias intentan reconectar a la vez. Es uno de los
casos clásicos de fallo que se agrava con la recuperación.

**05 → 10. ¿Qué diferencia hay entre el apagado de un servicio HTTP y el de un consumidor de cola? 🟡**

⏱️ **30 segundos** — En HTTP dejas de aceptar conexiones y terminas las activas; en una cola dejas de
pedir mensajes, terminas el actual y lo confirmas antes de cerrar.

🗣️ **2 minutos** — La diferencia importante es qué pasa si te equivocas: en HTTP pierdes peticiones y
el cliente ve un error; en una cola el mensaje no se confirma, se reentrega, y el efecto puede
ejecutarse dos veces. Por eso los consumidores necesitan idempotencia aunque el apagado sea
correcto: siempre existe la posibilidad de una caída sin aviso.

🔬 **El detalle** — Un detalle operativo: si el mensaje en curso tarda más que el plazo de gracia de
la plataforma, el proceso muere igual. Conviene que las unidades de trabajo del consumidor sean
cortas, o que el trabajo largo sea reanudable.

**05 → 11. ¿Qué parte de los doce factores envejeció y cuál sigue mandando? 🟡**

⏱️ **30 segundos** — Sigue mandando la configuración por entorno, los procesos sin estado y la
paridad entre entornos. Envejeció el enfoque de los logs como flujo de texto a stdout.

🗣️ **2 minutos** — Escribir a stdout sigue siendo correcto operativamente, pero hoy lo que importa
es que el log sea estructurado y lleve el identificador de correlación: sin eso, centralizar los logs
no sirve de nada en un sistema distribuido. También se quedó corto el tratamiento de los procesos de
apoyo, hoy resueltos por el orquestador.

🔬 **El detalle** — El factor de "paridad de entornos" se cumple hoy con contenedores y con la misma
imagen promovida, que es precisamente lo que hace que la configuración fuera del artefacto no sea
negociable.

**05 → 12. ¿Qué pasa entre que una instancia se marca como no lista y el balanceador deja de mandarle tráfico, y cómo se modela? 🟠**

⏱️ **30 segundos** — Pasan segundos de propagación, y se modela esperando explícitamente antes de
empezar a cerrar.

🗣️ **2 minutos** — El balanceador consulta el estado con cierta periodicidad y necesita varios
intentos fallidos antes de retirar la instancia. Mientras tanto sigue mandando peticiones a un
servicio que ya se cree cerrado. Por eso la práctica es dormir unos segundos tras marcarse como no
listo, aunque parezca contraintuitivo, y solo entonces iniciar el cierre.

🔬 **El detalle** — El número correcto sale de la configuración de la plataforma: periodo de sondeo
por número de fallos tolerados, más un margen. Copiar "cinco segundos" de un blog funciona por
casualidad; calcularlo es de dos minutos.

**05 → 13. Eliges los valores de tiempo del apagado ordenado. ¿Entre qué dos límites tienen que estar y por qué? 🟠**

⏱️ **30 segundos** — Mayor que el tiempo que tarda el balanceador en retirarte, y menor que el plazo
que la plataforma te da antes de matarte.

🗣️ **2 minutos** — Si el total es menor que la propagación del estado, cierras mientras todavía te
llega tráfico y pierdes peticiones. Si es mayor que el plazo de gracia del orquestador, te matan a
mitad del cierre y da igual lo bien escrito que esté. Entre esos dos límites se reparte: espera de
propagación, luego plazo para terminar lo que está en vuelo.

🔬 **El detalle** — Hay un tercer límite implícito: el timeout de las peticiones que estás
atendiendo. No tiene sentido esperar treinta segundos a terminar peticiones si el cliente abandona a
los cinco; ahí el plazo largo solo alarga el despliegue.

**05 → 14. ¿Qué dependencias pondrías en el readiness de `orders`, sabiendo que llama a `inventory` y a `payments`? Justifica cada una. 🟠**

⏱️ **30 segundos** — Su propia base de datos sí; `inventory` y `payments`, no.

🗣️ **2 minutos** — Sin base de datos, `orders` no puede atender nada, así que estar en el balanceo
solo produce errores. Con `inventory` caído todavía puede aceptar consultas y quizá encolar la
confirmación; si lo pusiera en readiness, un fallo ajeno sacaría del balanceo a un servicio que
funciona, propagando la caída.

🔬 **El detalle** — La regla general: en readiness va lo que hace que **todas** tus rutas fallen;
nunca una dependencia de una sola ruta. Y esa decisión es también de producto, porque define qué se
degrada y qué no.

**05 → 15. Un servicio de solo lectura que sirve una proyección: ¿le pones capa de dominio? 🟠**

⏱️ **30 segundos** — No. Sin reglas que proteger, la capa de dominio es mapeo sin comprador.

🗣️ **2 minutos** — En una proyección el trabajo es consultar y serializar, y a veces filtrar por
permisos. Añadir entidades de dominio, repositorios y mapeadores multiplica el código sin comprar
nada. Lo que sí conviene mantener es la frontera del transporte —no devolver directamente la fila de
la base— y la lógica de reconstrucción, que sí merece su sitio.

🔬 **El detalle** — El matiz: si la proyección aplica reglas para decidir qué se muestra a quién,
esas reglas son dominio y necesitan un sitio. La pregunta no es el tamaño del servicio, es si hay
alguna decisión que pueda estar mal tomada.

**05 → 16. Tienes dos servicios y te proponen montar un chassis. ¿Qué respondes? 🟠**

⏱️ **30 segundos** — Que con dos servicios copiar sale más barato que gobernar una librería; a partir
del tercero, cambia.

🗣️ **2 minutos** — El chassis tiene coste de gobierno: dueño, versionado, compatibilidad y la
disciplina de no meterle dominio. Con dos servicios, la duplicación es visible y barata de corregir.
Lo que sí conviene desde el primer día es acordar **las decisiones** —formato de log, nombre del
endpoint de salud, encabezado de correlación—, aunque el código esté duplicado.

🔬 **El detalle** — Un camino intermedio útil: empezar por la plantilla del repositorio, que no acopla
nada, y extraer a librería solo lo que ya se ha copiado tres veces sin cambios. Extraer después de
ver la repetición evita generalizar en falso.

**05 → 17. Alguien quiere meter en el chassis la validación de que el cliente está activo. Argumenta. 🟠**

⏱️ **30 segundos** — Eso es una regla de negocio con dueño —`customers`— y no puede vivir en una
librería que usan todos.

🗣️ **2 minutos** — Si entra, cada cambio en esa regla obliga a subir versión del chassis y a
desplegar todos los servicios; además la regla acabará teniendo variantes por servicio y la librería
crecerá con parámetros para contentarlas. La alternativa es que `customers` exponga la decisión —una
llamada o un evento con el estado— y que cada servicio la use.

🔬 **El detalle** — Si la latencia de preguntar es el problema real, la respuesta no es duplicar la
regla: es publicar el estado del cliente por eventos y que cada servicio mantenga su copia local.
Esa es la forma de compartir un dato sin compartir una regla.

**05 → 18. En Go tienes que escribir el apagado a mano y en Java es una propiedad. ¿Qué implicaciones prácticas tiene eso para un equipo políglota? 🟠**

⏱️ **30 segundos** — Que el mismo comportamiento se garantiza de formas distintas, y hay que
verificarlo por plataforma en vez de asumirlo.

🗣️ **2 minutos** — En Java el riesgo es que nadie sepa que la propiedad existe y quede el valor por
defecto; en Go, que el código de cierre esté incompleto —cierra el servidor pero no el consumidor—.
La consecuencia práctica es que la lista de comprobación de "listo para producción" tiene que ser
común y verificable, aunque la implementación no lo sea.

🔬 **El detalle** — La forma barata de verificarlo es una prueba operativa, no de código: desplegar
con tráfico y comprobar que no hay errores durante el reemplazo. Esa prueba vale igual para las
cuatro plataformas, que es justo lo que necesitas cuando son cuatro.

**05 → 19. Tu tablero muestra un goteo constante de errores 502 que coincide con los despliegues. Da el diagnóstico y la corrección. 🟠**

⏱️ **30 segundos** — Falta apagado ordenado, o el margen de propagación es demasiado corto.

🗣️ **2 minutos** — El diagnóstico se confirma correlacionando los picos con los reemplazos de
instancias. Las dos causas típicas: el proceso cierra en cuanto recibe la señal, o cierra tras marcar
readiness en falso pero sin esperar a que el balanceador se entere. La corrección es la secuencia
completa de §5, con el margen calculado desde la configuración de sondeo.

🔬 **El detalle** — Hay una variante que despista: si el servicio usa conexiones persistentes de
larga duración, el cliente puede tener una conexión abierta a una instancia que ya se está cerrando.
Ahí hace falta además cerrar avisando —`Connection: close` en HTTP/1.1, o el aviso equivalente en
HTTP/2— para que el cliente reconecte contra otra instancia.

**05 → 20. ¿Cómo evitas que el chassis se convierta en el monolito, en términos de gobierno y no de código? 🟠**

⏱️ **30 segundos** — Con un dueño explícito, un criterio escrito de qué entra, y compatibilidad hacia
atrás obligatoria.

🗣️ **2 minutos** — El criterio de admisión es la clave: solo entra lo que es idéntico para todos,
técnico y estable. Toda propuesta de meter algo de negocio se rechaza por defecto, y para que eso no
dependa del humor de nadie conviene tenerlo escrito. Y las versiones tienen que ser compatibles hacia
atrás, para que nadie esté obligado a subir en el mismo sprint.

🔬 **El detalle** — Una señal de alerta medible: la frecuencia de versiones. Si el chassis publica
varias versiones al mes y sus notas hablan de negocio, ya se ha contaminado, y conviene partirlo
antes de que sea imposible.

**05 → 21. Diseña el contenido completo de un chassis para un equipo con servicios en Java y en Go, diciendo qué va en librería, qué en plantilla y qué se duplica a propósito. 🔴**

⏱️ **30 segundos** — Librería por plataforma para logs, métricas y contexto; plantilla para
estructura y pipeline; y las decisiones comunes escritas en un documento que manda sobre ambas.

🗣️ **2 minutos** — El reparto:

```text
Decisiones comunes (documento)  formato de log, nombres de métricas, encabezado de correlación,
                                ruta y forma de los health checks, política de timeouts

Librería (una por plataforma)   logging estructurado, exportador de OpenTelemetry,
                                cliente HTTP con timeouts y reintentos, health checks

Plantilla (una por plataforma)  estructura de carpetas, pipeline, manifiestos, pruebas base

Duplicado a propósito           el modelo de dominio de cada servicio, siempre
```

Lo importante es que las dos librerías implementan **las mismas decisiones**, no el mismo código, y
que hay una forma de verificarlo: un servicio de ejemplo por plataforma que se comprueba contra la
misma lista.

🔬 **El detalle** — El coste de mantener dos chassis equivalentes es el argumento central contra
añadir plataformas a la ligera, y conviene decirlo al proponer el diseño: cada plataforma nueva
multiplica este trabajo, y por eso la decisión de poliglotismo es de organización, no de gusto.

**05 → 22. Escribe la secuencia de apagado de un servicio que sirve HTTP y además consume de una cola, con el orden exacto de cierre y qué pasa si se invierte. 🔴**

⏱️ **30 segundos** — Primero dejar de aceptar trabajo nuevo por ambos lados, después terminar lo que
está en curso, y cerrar recursos compartidos al final.

🗣️ **2 minutos** — La secuencia:

```text
1. readiness = false                    (deja de llegar tráfico nuevo)
2. el consumidor deja de pedir mensajes (sigue procesando el actual)
3. esperar propagación del balanceador  (unos segundos)
4. servidor HTTP: shutdown con plazo    (termina lo que está en vuelo)
5. terminar y confirmar el mensaje en curso
6. cerrar pool de base de datos, cliente del broker, clientes HTTP
7. exportar métricas y trazas pendientes, y salir
```

Si se invierte 6 y 5 —cerrar la base antes de terminar el mensaje—, el mensaje falla, no se confirma
y se reentrega, con el efecto a medio aplicar. Si se invierte 1 y 2, se sigue recibiendo tráfico HTTP
mientras el consumidor ya se apagó, lo que produce respuestas incompletas.

🔬 **El detalle** — El paso 7 se olvida siempre y explica trazas incompletas justo en los despliegues:
el exportador tiene su propio búfer, y si el proceso muere antes de vaciarlo, las últimas trazas —las
más interesantes si algo falló— no llegan nunca.

**05 → 23. Diseña los health checks de `orders` —liveness, readiness y arranque— y di qué decisión de producto hay detrás de cada dependencia incluida o excluida. 🔴**

⏱️ **30 segundos** — Liveness sin dependencias; readiness con su base de datos; arranque con el
tiempo que tarda en cargar; `inventory` y `payments` fuera de ambos.

🗣️ **2 minutos** — El diseño y su porqué:

```text
Sonda       Comprueba                        Decisión de producto detrás
──────────  ───────────────────────────────  ──────────────────────────────────────
liveness    el proceso responde              nunca reiniciar por un fallo ajeno
readiness   base de datos propia             sin ella no hay ninguna ruta útil
readiness   broker (solo si publicar es      si publicar puede diferirse al outbox,
            imprescindible para responder)   entonces NO va
arranque    plazo generoso, sin dependencias evitar el bucle de reinicios al desplegar
excluidas   inventory, payments              se degradan: consultar sigue funcionando
```

🔬 **El detalle** — La fila del broker es la interesante: si el servicio usa outbox
([`03/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md)), publicar deja de ser parte de la petición y el broker sale
de readiness. Es un ejemplo de cómo una decisión de datos cambia la configuración operativa.

**05 → 24. Un equipo nuevo va a crear su primer servicio. Escribe la lista de comprobación de "listo para producción" que le darías, con no más de diez puntos, y justifica el orden. 🔴**

⏱️ **30 segundos** — Ordenada por lo que más incidentes evita: timeouts, apagado ordenado, health
checks, logs correlacionados, configuración validada.

🗣️ **2 minutos** — La lista:

```text
1. Timeouts explícitos en todo cliente saliente          evita el agotamiento de recursos
2. Apagado ordenado verificado con tráfico               evita errores en cada despliegue
3. Liveness sin dependencias, readiness con las propias  evita reinicios en cascada
4. Configuración validada al arrancar, secretos fuera    convierte incidentes en despliegues fallidos
5. Log estructurado con identificador de correlación     sin esto no se diagnostica nada
6. Traza distribuida propagada, incluido el broker       el contexto se pierde justo ahí
7. Métricas RED expuestas                                sin ellas no hay alertas útiles
8. Migraciones compatibles hacia atrás                   permite desplegar sin coordinar
9. Consumidores idempotentes                             la reentrega es un hecho, no un riesgo
10. Plan de vuelta atrás probado una vez                 el día del incidente no se improvisa
```

🔬 **El detalle** — El orden no es arbitrario: los cuatro primeros evitan incidentes causados por el
propio servicio; del cinco al siete permiten diagnosticarlos; y los tres últimos son los que hacen
que el servicio siga siendo independiente cuando el sistema crezca. Si el equipo solo puede hacer
cinco antes de salir, que sean los cinco primeros.

---

# 06 — Simulación de entrevista

**Sobre las preguntas `S#`.** Están cubiertas por las preguntas de los cinco capítulos de este
bloque, así que no se responden otra vez aquí: `S1`–`S5` por [`01`](01-que-es-un-microservicio.md),
`S6`–`S10` por [`02`](02-descomposicion-y-fronteras.md), `S11`–`S15` por
[`03`](03-el-camino-desde-el-monolito.md), `S16`–`S20` por [`04`](04-el-monolito-distribuido.md) y
`S21`–`S25` por [`05`](05-el-servicio-por-dentro.md). Las de "las que descolocan" —`S26` a `S32`— no
tienen respuesta única: se practican en voz alta, y lo que se evalúa es el criterio y la calma, no el
contenido.

Los escenarios **sí** llevan solución desarrollada, porque son ejemplos resueltos y no autochequeo.

**01/06 → E1. Corte de un dominio nuevo: plataforma de reservas de restaurantes, tres equipos.**

⏱️ **30 segundos** — Cuatro servicios: `search`, `bookings`, `payments` y `venues`. Corto por
capacidad de negocio y desempato por volatilidad y por carga.

🗣️ **2 minutos** — El corte y su razón:

```text
Servicio      Qué contiene                        Criterio
────────────  ──────────────────────────────────  ─────────────────────────────
search        catálogo publicado, disponibilidad  carga: lectura masiva,
              aproximada, filtros                  consistencia eventual aceptable
bookings      la reserva y su ciclo de vida,      capacidad de negocio;
              mesas, confirmación                  es el núcleo
payments      señal, devolución, conciliación     cumplimiento: auditoría propia
venues        alta de restaurante, horarios,      otro usuario (el restaurante),
              panel, valoraciones                  otro ritmo de cambio
```

🔬 **El detalle** — Las dos decisiones discutibles, que son lo que el entrevistador va a preguntar:

- **Separar `search` de `bookings`**, aunque hablen de lo mismo. Se justifica por perfil de carga:
  buscar es órdenes de magnitud más frecuente que reservar, y la disponibilidad mostrada puede ser
  eventual mientras la reserva sea transaccional. La repregunta será el caso de dos usuarios
  reservando la última mesa: la verdad la decide `bookings` en su transacción, y el negocio hotelero
  y de restauración convive con ese riesgo a propósito.
- **Meter valoraciones dentro de `venues`** en vez de darle servicio propio. Se justifica porque
  cambia al mismo ritmo y tiene el mismo dueño; si el volumen de valoraciones creciera mucho o
  apareciera moderación con reglas propias, se extraería. Y con tres equipos, cuatro servicios es un
  número sostenible: más servicios que equipos es la señal de alarma de §8 de `02`.

**01/06 → E2. Migración con base de datos compartida: monolito de facturación que no admite parada.**

⏱️ **30 segundos** — Cuatro fases: aislar el módulo dentro, separar sus tablas, extraer el servicio en
sombra, y desviar tráfico por porcentaje. Datos antes que proceso.

🗣️ **2 minutos** — El plan:

```text
F1  Módulo de reglas fiscales aislado dentro del monolito, tras una interfaz.
    Se prohíben los JOIN con sus tablas desde fuera.
    Despliega: solo el monolito.  Vuelta atrás: revertir despliegue.
F2  Sus tablas a un esquema propio, con credencial propia. Sin cambio de proceso.
    Despliega: monolito + migración.  Vuelta atrás: restaurar permisos.
F3  Servicio nuevo desplegado, recibiendo copia del tráfico (sombra, sin efectos).
    Se comparan resultados contra el monolito.
    Vuelta atrás: apagar la copia; producción no se entera.
F4  Desvío real por porcentaje desde la fachada, empezando por 1 %.
    Vuelta atrás: porcentaje a cero.
```

🔬 **El detalle** — Tres cosas que el entrevistador va a buscar: que las reglas fiscales son un
candidato excelente **porque cambian a menudo y el resto no** —criterio de volatilidad—; que F3 con
comparación en paralelo es imprescindible aquí, porque el comportamiento real está en el código viejo
y no en ninguna especificación; y que el punto de no retorno es cuando los movimientos dejen de
escribirse en el monolito, momento que se decide y se anuncia. Además, en facturación conviene no
cerrar la migración sin pasar un cierre contable completo sin diferencias.

**01/06 → E3. La respuesta correcta es no separar: equipo de cuatro, ochenta usuarios.**

⏱️ **30 segundos** — No migro. Propongo monolito modular con fronteras verificadas, y explico qué
compraría la separación aquí: nada.

🗣️ **2 minutos** — La respuesta, en el orden en que se dice:

```text
1. Qué compraría      despliegue independiente (despliegan juntos igual),
                      escalado diferencial (ochenta usuarios),
                      autonomía de equipos (hay un equipo)
                      → los tres beneficios valen cero en este contexto
2. Qué costaría       red donde hay llamadas, sagas donde hay transacciones,
                      trazas distribuidas, y N pipelines para cuatro personas
3. Qué propongo       monolito modular: módulos con fronteras explícitas,
                      prohibición de JOIN entre módulos verificada en CI,
                      y una prueba de arquitectura que lo sostenga
4. Qué concedo        si mañana una parte necesita escalar o desplegarse sola,
                      la extraemos, y para entonces sabremos por dónde cortar
```

🔬 **El detalle** — Lo que se evalúa aquí no es la respuesta técnica sino cómo se dice: hay que evitar
sonar a que se rechaza por comodidad. Ayuda mucho ofrecer el trabajo concreto —fronteras, pruebas de
arquitectura, chassis— porque convierte un "no" en un plan. Y conviene nombrar la condición que
cambiaría la respuesta: si el equipo creciera a tres equipos, o si una parte tuviera un perfil de
carga muy distinto, la conversación sería otra.

**01/06 → E4. Diagnóstico de un monolito distribuido: doce servicios que se despliegan juntos.**

⏱️ **30 segundos** — Miro pipeline, dependencias compartidas, datos y cadenas de llamadas. Y empiezo
por comprobar si el acoplamiento es real o solo está en la herramienta.

🗣️ **2 minutos** — El orden de investigación y el primer trabajo:

```text
Qué miro, en orden
1. El pipeline: ¿los despliega juntos por necesidad o por costumbre?
2. Dependencias compartidas: ¿hay un módulo común con dominio o entidades dentro?
3. Datos: ¿qué credenciales pueden leer qué esquemas?
4. Llamadas: ¿cuántos saltos tiene un caso de uso típico? (trazas o logs)
5. Historial: ¿qué porcentaje de commits toca más de un servicio?

Primer trabajo con impacto
  · si el pipeline los une por costumbre → partirlo: días de trabajo,
    beneficio inmediato y visible
  · si no → contratos compatibles verificados en CI, que es lo que desbloquea
    todo lo demás
Indicador   servicios desplegables por separado / total, semana a semana
```

🔬 **El detalle** — El punto 5 es el que más información da por minuto invertido y casi nadie lo
usa: si la mayoría de los commits tocan varios servicios, el problema es de fronteras y no de
herramientas, y el plan cambia. La trampa a evitar es empezar rediseñando fronteras: es lo más
llamativo y lo más lento, y deja al equipo sin ninguna victoria durante meses.

**01/06 → E5. El primer servicio extraído: `notifications`, el primero del sistema.**

⏱️ **30 segundos** — Estructura mínima, chassis completo desde el día uno, liveness sin dependencias,
readiness con lo imprescindible, apagado ordenado, y métricas de paridad contra el camino viejo.

🗣️ **2 minutos** — El diseño:

```text
Dentro        transporte (API + consumidor de eventos) · aplicación · dominio
              mínimo (plantillas, reglas de envío) · adaptadores (proveedor de
              correo, base propia)
Chassis       configuración validada al arrancar · logs estructurados con traza ·
              OpenTelemetry con propagación (incluida la del broker) · cliente
              HTTP con plazos y sin reintento por defecto · health checks ·
              apagado ordenado
Health        liveness: solo el proceso. readiness: su base de datos.
              El proveedor externo NO va en readiness: si está caído, se encola
Despliegue    imagen construida una vez; migración como paso del pipeline;
              rolling con verificación de errores y latencia
Demostrar     1. se despliega sin desplegar el monolito
              2. paridad: mismos envíos que el camino viejo durante la convivencia
              3. p99 y tasa de error comparados en la misma ruta
              4. el camino viejo retirado, con fecha
```

🔬 **El detalle** — `notifications` es un buen primer candidato precisamente porque es poco crítico y
tiene frontera clara, que es el criterio de §5 de `03`: el objetivo real de esta extracción es
construir el camino —pipeline, chassis, paneles, rutina de despliegue— no el valor de negocio del
servicio. Conviene decirlo explícitamente en la entrevista. Y hay una decisión de diseño que el
entrevistador suele tocar: si `notifications` reacciona a eventos en vez de recibir órdenes, la regla
de "cuándo se notifica" vive aquí, que es lo correcto; si recibe comandos, esa regla se queda en quien
llama y el servicio se vuelve anémico.

---

**Anterior:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
