# 10 — Respuestas

> Solucionario centralizado del bloque `05-banca`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--core-bancario-y-legado) · [02](#02--mq-e-integración-asíncrona-clásica) ·
[03](#03--batch-y-spring-batch) · [04](#04--capa-anticorrupción-sobre-el-legado) ·
[05](#05--iso-20022-iso-8583-y-swift) · [06](#06--psd2-y-open-banking) ·
[07](#07--bpm-y-arquitectura-dirigida-por-workflow) ·
[08](#08--idempotencia-conciliación-y-auditoría) · [09 — escenarios](#09--simulación-escenarios-de-diseño)

---

# 01 — Core bancario y legado

**01 → 1. ¿Qué es un core bancario y qué contiene?**

⏱️ El sistema que mantiene saldos, movimientos y contabilidad. Es la fuente de verdad contable del
banco.
🗣️ Contiene cuentas y saldos, el libro de movimientos, los productos con sus reglas de devengo, la
identidad canónica del cliente y los asientos contables. Todo lo demás —app, banca en línea,
originación— son satélites que consultan y ordenan operaciones contra él.
🔬 Suele ser mainframe con COBOL y CICS en bancos grandes, un paquete comercial configurable en
medianos, o desarrollo propio en entidades nuevas. En los tres casos, el modelo de datos viene dado y
no se negocia.

**01 → 2. ¿Qué es la ventana batch?**

⏱️ El periodo nocturno en que el core deja de atender en línea y ejecuta el cierre de día.
🗣️ En ella se devengan intereses, se liquidan operaciones, se generan ficheros e informes
regulatorios y se concilia. Es el recurso más escaso del banco: todo lo que hay que procesar de noche
compite por ella.
🔬 Si no termina a tiempo, el banco **no abre**, y eso es un incidente con visibilidad de comité de
dirección. Tu sistema tiene que tener un comportamiento definido durante esa ventana: encolar,
degradar con aviso, o rechazar explícitamente.

**01 → 3. ¿Qué diferencia hay entre saldo contable y saldo disponible?**

⏱️ El contable es lo que dice el libro mayor; el disponible es lo que el cliente puede gastar ahora.
🗣️ El disponible es el contable menos retenciones más créditos aplicables. Y hay un tercero, el
saldo en tránsito: operaciones ordenadas y no liquidadas.
🔬 Esta distinción resuelve el conflicto entre exactitud y disponibilidad: el disponible puede
mostrarse con una ventana de consistencia si lleva su marca de tiempo; el contable, que es el que
valida cualquier operación, no.

**01 → 4. Nombra las cuatro formas de integrarse con un core.**

⏱️ Fichero, colas (MQ), transacción CICS y API.
🗣️ El fichero es lo más antiguo y sigue siendo lo más común para volumen masivo. MQ da
transaccionalidad y latencia de segundos. CICS es una llamada síncrona muy rápida y muy acoplada. La
API suele ser una fachada que alguien construyó delante.
🔬 En un banco real coexisten las cuatro. Y la API casi nunca es del core: por debajo acaba en una de
las otras tres, lo que condiciona su latencia y su disponibilidad real.

**01 → 5. ¿Qué es una retención?**

⏱️ Un importe bloqueado del saldo disponible antes de que exista el asiento contable.
🗣️ Al pagar con tarjeta, el importe se retiene de inmediato aunque la liquidación llegue días
después. El disponible baja al instante; el contable, no.
🔬 Es un estado intermedio explícito con caducidad, exactamente la semántica de bloqueo de una saga.
La banca lleva décadas usando el mecanismo que los microservicios redescubrieron para evitar el doble
gasto sin bloquear la contabilidad.

**01 → 6. ¿Qué tres fechas distingue una operación bancaria?**

⏱️ Fecha de operación, fecha contable y fecha valor.
🗣️ La de operación es cuándo se ordenó. La contable, a qué día se imputa en el libro. La de valor,
desde cuándo cuenta para el cálculo de intereses, y puede ser anterior o posterior a las otras dos.
🔬 Una operación de las 23:50 puede tener fecha contable del día siguiente, y un ingreso puede tener
fecha valor de ayer. Modelarlas como un solo campo produce descuadres que aparecen en el primer
cierre.

**01 → 7. ¿Qué es la fecha valor y por qué no basta un solo campo de fecha?**

⏱️ La fecha desde la que el importe cuenta para calcular intereses. No coincide necesariamente con
cuándo se registró.
🗣️ Un ingreso hecho hoy puede tener fecha valor de ayer, y generar intereses desde ayer. Una
operación puede registrarse hoy con fecha contable de mañana. Cada fecha responde a una pregunta
distinta del negocio.
🔬 Es un concepto que no existe fuera de banca y que aparece en cuanto hay intereses. Colapsarlas en
un campo `fecha` funciona hasta el primer cálculo de devengo, y entonces el error es contable y
visible para el cliente.

**01 → 8. ¿Por qué no se toca el core? Da cuatro razones.**

⏱️ Riesgo contable, conocimiento perdido, exigencia de auditoría, y acoplamiento de decenas de
sistemas.
🗣️ Un error en un saldo o en el cálculo de intereses es un incidente regulatorio, no un bug. Las
reglas están en el código y quienes las escribieron se jubilaron. Cambiar el sistema de registro
contable puede requerir certificación. Y cuarenta sistemas dependen de su modelo y de sus ventanas.
🔬 Cualquiera de las cuatro bastaría por separado. Juntas explican por qué la modernización se hace
rodeando el core y no sustituyéndolo, y por qué proponer una reescritura señala falta de experiencia
en el sector.

**01 → 9. ¿Qué pasa si el batch no termina a tiempo?**

⏱️ El banco no abre, o abre con funcionalidad degradada.
🗣️ Los procesos del cierre tienen dependencias en orden —devengo antes que liquidación, liquidación
antes que extracto—, así que un retraso se propaga. Y la apertura no puede ocurrir hasta que el
estado contable sea consistente.
🔬 Por eso la ventana es el recurso más disputado del banco y cualquier proceso nuevo que quiera
entrar en ella tiene que justificar su tiempo. Es también la razón por la que el rendimiento de un
batch bancario no es una optimización: es un requisito con hora límite.

**01 → 10. ¿Por qué el libro mayor es inmutable y cómo se corrige un error?**

⏱️ Porque es la evidencia contable y está auditada. Se corrige con un contra-asiento, no
modificando.
🗣️ Se emite un asiento que anula el erróneo, con referencia al original y motivo, y después el
asiento correcto. Los tres quedan visibles, incluido en el extracto del cliente.
🔬 Es el mismo principio que la compensación de una saga y que la inmutabilidad del event sourcing.
Modificar un movimiento destruiría la evidencia, que es justamente lo que un auditor comprueba.

**01 → 11. ¿Qué es CICS y qué papel juega?**

⏱️ El monitor transaccional del mainframe: ejecuta programas de forma síncrona con latencia muy baja
y alta fiabilidad.
🗣️ Es la vía por la que se hacen las consultas en línea contra el core: llamas a una transacción
CICS y recibes respuesta en milisegundos. Es rápida y muy acoplada, porque el contrato es el programa
concreto y su formato de entrada y salida.
🔬 Décadas de optimización la hacen extraordinariamente eficiente para lo que hace. Su límite es que
es síncrona y punto a punto: no relee, no reparte, y su capacidad suele estar contratada y medida.

**01 → 12. ¿Por qué la API del core suele no ser del core?**

⏱️ Porque es una fachada que alguien construyó delante, y por debajo acaba en fichero, MQ o CICS.
🗣️ Eso importa porque determina su latencia real, su disponibilidad y su comportamiento durante la
ventana: si por debajo hay MQ, la respuesta puede ser diferida; si hay batch, puede no existir hasta
mañana.
🔬 La pregunta que hay que hacer siempre es "¿qué hay debajo?". Suponer que una API REST implica
respuesta inmediata y disponibilidad 24/7 es el error que produce diseños que se rompen durante el
cierre.

**01 → 13. ¿Por qué las lecturas se migran primero?**

⏱️ Porque no tienen riesgo contable y descargan el core, que suele ser el cuello de botella.
🗣️ Una proyección de lectura alimentada por eventos o CDC sirve las consultas sin preguntar al core,
lo que reduce su carga, elimina la dependencia de su disponibilidad y —si cobra por transacción—
ahorra dinero medible.
🔬 Y permite aprender el camino con poco riesgo: el equipo practica el patrón de migración en algo
donde un error se corrige reconstruyendo la vista. Las escrituras van al final, y muchas veces no
migran nunca: el core sigue siendo el sistema de registro.

**01 → 14. ¿Qué cinco cosas preguntas ante una integración con el core?**

⏱️ Si es síncrona o diferida, qué pasa durante la ventana, si es idempotente y con qué clave, cuál es
su SLA real, y cómo se concilia.
🗣️ La primera decide si puedes responder al cliente en el momento. La segunda es la que todo el mundo
olvida. La tercera determina si un reintento duplica un asiento. La cuarta es el medido, no el
declarado. Y la quinta reconoce que va a haber descuadres.
🔬 Las cinco condicionan el diseño más que cualquier decisión tecnológica que tomes después.
Preguntarlas antes de diseñar es lo que separa una propuesta viable de una teórica.

**01 → 15. ¿Por qué consultar el saldo en cada pantalla puede ser un problema presupuestario?**

⏱️ Porque muchos cores comerciales cobran por transacción.
🗣️ Con dos millones de usuarios que abren la app varias veces al día, las consultas de saldo son
decenas de millones de transacciones al mes. A un coste por transacción, eso es una partida
presupuestaria con nombre propio.
🔬 Es el mejor argumento para una proyección de lectura, porque traduce una decisión de arquitectura a
euros. Y es un dato poco conocido fuera del sector, así que mencionarlo en entrevista señala
experiencia real.

**01 → 16. ¿Qué relación tiene el saldo disponible con la semántica de bloqueo de una saga?**

⏱️ Es el mismo mecanismo: un estado intermedio explícito con caducidad que evita el doble gasto sin
bloquear el recurso definitivo.
🗣️ La retención marca el importe como comprometido —igual que un asiento de vuelo en estado
`RESERVADO`— mientras la liquidación no llega. Si la operación se cae, la retención caduca y el
disponible se recupera solo.
🔬 Es un ejemplo de que los patrones de sistemas distribuidos no se inventaron con los
microservicios: la banca modeló el compromiso reversible con caducidad porque la liquidación siempre
fue diferida.

**01 → 17. ¿Cómo resolvió la banca la consistencia eventual antes de que existiera el término?**

⏱️ Separando el dato que se muestra del dato que manda, y reconciliando después.
🗣️ El saldo disponible se calcula y se muestra con su marca de tiempo; el saldo contable, consistente
y auditado, es el que valida cualquier operación. La diferencia entre ambos se resuelve con la
liquidación y se verifica con la conciliación.
🔬 Es exactamente CQRS con consistencia eventual y una red de seguridad. Citarlo en una entrevista de
arquitectura —"la banca llevaba décadas haciendo esto"— es de las mejores respuestas que hay, porque
demuestra que entiendes el patrón y no solo el vocabulario moderno.

**01 → 18. ¿Por qué el fichero sigue siendo un mecanismo vigente?**

⏱️ Porque soporta volumen masivo con recuperación simple: si falla, se reprocesa el fichero.
🗣️ Un fichero de dos millones de registros se transmite, se valida contra su fichero de control y se
procesa. Si algo va mal, se vuelve a procesar entero o desde el punto de corte. No hay estado
distribuido que reconciliar.
🔬 Y tiene una propiedad que se subestima: es **auditable por construcción**. El fichero es la
evidencia de qué se envió, con su conteo y su suma de control, y se puede archivar. Eso es difícil de
igualar con una integración en línea.

**01 → 19. ¿Qué hay que decidir explícitamente sobre el comportamiento durante la ventana?**

⏱️ Si encolas, degradas con aviso, o rechazas explícitamente. Nunca "no lo pensamos".
🗣️ Encolar sirve para órdenes que pueden esperar, y exige decidir qué le dices al usuario mientras
tanto. Degradar sirve para consultas: mostrar el último dato conocido **con su hora**. Rechazar es
correcto cuando la operación no puede esperar y dar un dato viejo sería peor.
🔬 La decisión es de negocio, no técnica, y hay que llevarla a negocio operación por operación. Lo que
no es aceptable es que el comportamiento durante cuatro horas cada noche sea el resultado accidental
de un timeout.

**01 → 20. ¿Cómo se mide el avance de una modernización de core?**

⏱️ Por porcentaje de **tráfico** servido por lo nuevo, no por código migrado.
🗣️ El código migrado no dice nada: se puede reescribir medio sistema y no haber desviado una sola
petición real. El tráfico servido mide valor entregado y riesgo asumido, y obliga a que cada paso
llegue a producción.
🔬 Métricas complementarias: reducción de transacciones facturadas contra el core, número de
capacidades que ya no dependen de su disponibilidad, y despliegues que ya no requieren coordinar con
el equipo del core. Si a los seis meses no se ha movido tráfico real, el enfoque está mal.

**01 → 21. Diseña la consulta de saldo de una app móvil con 2 millones de usuarios, sabiendo que el core cobra por transacción y cierra de 23:00 a 03:00.**

⏱️ Proyección de lectura propia alimentada por eventos o CDC, saldo disponible calculado por mí, y
modo degradado explícito durante la ventana.
🗣️ El diseño:

```text
Proyección de saldos → tabla propia con saldo contable, disponible y marca de tiempo.
                       Alimentada por los movimientos que el core publica, o por CDC.
Consulta de la app   → va SIEMPRE a mi proyección. Nunca al core.
Saldo disponible     → lo calculo yo: contable de la proyección menos retenciones vigentes,
                       que también son mías (las genero al autorizar).
Durante la ventana   → la proyección sigue sirviendo, con la marca de tiempo visible.
                       Las órdenes que requieran el core se encolan y se avisa al usuario.
Consulta al core     → solo cuando se va a operar, para validar contra el saldo contable.
```

🔬 Lo que justifica cada decisión. La **proyección** resuelve los tres problemas a la vez: coste por
transacción, latencia de 800 ms, y disponibilidad durante el cierre. La **marca de tiempo visible**
es lo que hace honesta la consistencia eventual: el usuario ve "actualizado hace 30 segundos" en vez
de un número que podría ser viejo sin avisar. Y la **validación contra el contable al operar** es
innegociable: mostrar admite obsolescencia, comprometer no. Declararía la ventana de la proyección
—medida, con alerta si supera un umbral acordado— y el comportamiento durante el cierre, acordado con
negocio operación por operación.

**01 → 22. Te piden "migrar el core a microservicios en 18 meses". ¿Qué respondes y qué propones?**

⏱️ Que no se sustituye, se rodea. Propongo Strangler Fig empezando por lecturas, con entregas
trimestrales medidas en tráfico.
🗣️ Los argumentos, en sus términos: las reglas de negocio del core no están documentadas y solo
existen en su código, así que reescribirlas exige descubrirlas primero; es el sistema de registro
contable y está auditado, así que un error es un incidente regulatorio; y cuarenta sistemas dependen
de su modelo y sus ventanas, así que el alcance real no es el core, es el ecosistema.
🔬 Lo que propongo en su lugar: una fachada delante que pueda enrutar a lo viejo o a lo nuevo;
migración de **lecturas** primero mediante proyecciones, que descarga el core y reduce su coste sin
riesgo contable; capacidades periféricas después, una por trimestre, cada una con su capa
anticorrupción; y el núcleo transaccional al final, o nunca. **No comprometo una fecha de
finalización**, pero sí una cadencia: cada trimestre, una capacidad con tráfico real. Y mido el
avance en porcentaje de tráfico y en reducción de transacciones facturadas, no en código. Si a los
seis meses no se ha movido tráfico, el enfoque está mal y se replantea, en vez de descubrirlo en el
mes 18.

**01 → 23. Un cliente ve un saldo que no cuadra con sus movimientos. Describe cómo investigas y qué conceptos del capítulo usas.**

⏱️ Primero determino de qué saldo habla —contable, disponible o proyección— y con qué fechas.
Normalmente no hay error: hay tres conceptos distintos.
🗣️ La investigación:

```text
1. ¿Qué saldo ve? Si es la app, es el DISPONIBLE, que descuenta retenciones que
   todavía no son movimientos. Eso explica la mayoría de los casos.
2. ¿Qué movimientos suma él? Probablemente por fecha de operación; el saldo se calcula
   por fecha CONTABLE o por fecha VALOR según el caso.
3. ¿Hay operaciones en tránsito? Autorizaciones de tarjeta sin liquidar.
4. ¿La proyección está al día? Si el lag creció, el saldo mostrado es viejo.
5. Solo si nada de lo anterior explica la diferencia: es un descuadre real,
   y entra en el circuito de conciliación.
```

🔬 Los conceptos que uso son los del capítulo: **los tres saldos**, porque el disponible y el contable
no tienen por qué coincidir y ninguno está mal; **las tres fechas**, porque sumar por fecha de
operación un saldo calculado por fecha valor nunca cuadra; y la **retención**, que es un compromiso
sin asiento. Si tras los cinco pasos hay diferencia real, la corrección no es ajustar el saldo: es
identificar el movimiento que falta o sobra y emitir el asiento correspondiente, con su contra-asiento
si procede. Y lo que declararía como mejora: si este tipo de consulta llega a soporte con frecuencia,
el problema es de **comunicación en la interfaz** —no distinguir disponible de contable— más que de
datos.

---

# 02 — MQ e integración asíncrona clásica

**02 → 1. ¿Qué caracteriza a una cola transaccional?**

⏱️ Persistencia por mensaje, entrega garantizada con reintento, DLQ nativa y participación en
transacciones XA.
🗣️ Cada mensaje se escribe a disco antes de confirmar la puesta, el broker reintenta hasta el acuse
con cuenta de intentos, y la puesta o la toma pueden formar parte de una transacción distribuida con
la base de datos.
🔬 Es un modelo punto a punto: un mensaje, un consumidor. No hay pub/sub natural ni releer el pasado,
que es justo lo que Kafka da y MQ no.

**02 → 2. ¿Qué es el request-reply asíncrono?**

⏱️ Mandar una petición por una cola y recibir la respuesta por otra, sin bloquear.
🗣️ Es el patrón dominante con el core: pones el mensaje, sigues trabajando, y minutos después llega
la respuesta a otra cola, correlacionada por un identificador.
🔬 Obliga a modelar la petición como una **entidad con estado**, no como una llamada. Quien lo trata
como una llamada acaba con estado en memoria y peticiones perdidas al reiniciar.

**02 → 3. ¿Qué es el `correlationId` y para qué sirve?**

⏱️ El identificador que permite casar la respuesta con su petición.
🗣️ Las respuestas llegan desordenadas y puede haber miles en vuelo, así que sin él no hay forma de
saber a qué petición corresponde cada una.
🔬 Es un patrón de *Enterprise Integration Patterns* con nombre propio: *Correlation Identifier*. Y
conviene que sea el mismo identificador de negocio que usas para la idempotencia, para no tener que
correlacionar dos identificadores cuando haya un descuadre.

**02 → 4. ¿Qué son las dos fases de XA?**

⏱️ Preparar y confirmar. El coordinador pregunta si todos pueden, y solo entonces ordena confirmar.
🗣️ En la fase de preparación cada participante reserva los recursos y responde que sí, quedando
**bloqueado**. En la de confirmación, el coordinador ordena aplicar si todos aceptaron, o deshacer si
alguno rechazó.
🔬 El problema está entre ambas: si el coordinador muere ahí, los participantes quedan **en duda**,
han prometido confirmar y no saben si deben. Ese estado requiere intervención manual.

**02 → 5. ¿Qué tres estados tiene una petición en request-reply?**

⏱️ `ENVIADA`, `RESPONDIDA` y `SIN RESPUESTA`.
🗣️ El tercero es el que define el diseño: significa que venció el plazo y **no sabes** si se
ejecutó. No es un fallo, es una ambigüedad.
🔬 Omitirlo es el error clásico: sin ese estado, el sistema o espera para siempre o trata el timeout
como fallo y reintenta, que en banca duplica asientos.

**02 → 6. ¿Qué da MQ que Kafka no da?**

⏱️ Participación en transacciones XA, prioridades y TTL por mensaje, y cola de reintentos con DLQ
nativas.
🗣️ MQ puede ser parte de una transacción distribuida con la base de datos, lo que resolvía el
problema de la doble escritura antes del outbox. Y tiene mecanismos por mensaje —prioridad,
caducidad, retardo— que en Kafka hay que emular rompiendo el orden.
🔬 Por eso sigue vivo en core bancario: no es inercia, es que resolvía un problema que Kafka no
resuelve. Lo que pasa es que hoy ese problema tiene una solución mejor sin coordinador.

**02 → 7. ¿Qué da Kafka que MQ no da?**

⏱️ Releer el histórico, varios consumidores independientes del mismo flujo, y escala de lectura.
🗣️ En Kafka leer no borra: un consumidor nuevo puede procesar seis meses de eventos sin afectar a los
demás, y cada grupo lleva su propio offset. En MQ, lo que un consumidor toma, ya no está.
🔬 Esa diferencia es estructural —log frente a cola— y decide la elección: si necesitas reprocesar o
añadir consumidores sobre el pasado, MQ no lo da y no hay configuración que lo arregle.

**02 → 8. ¿Por qué el estado de la petición no puede vivir en memoria?**

⏱️ Porque la respuesta puede llegar a otra instancia, y porque un reinicio lo perdería.
🗣️ Si la cola de respuesta es compartida entre instancias, la respuesta a una petición enviada por la
instancia A puede llegar a la B, que no sabe nada de ella. Y con respuestas diferidas de minutos, un
despliegue en medio pierde todas las peticiones en vuelo.
🔬 El estado va en la base de datos, con su identificador de correlación y su marca de tiempo. Eso
además es lo que permite el proceso que detecta peticiones vencidas y lo que alimenta la
conciliación.

**02 → 9. ¿Qué significa que una transacción XA quede "en duda"?**

⏱️ Que el participante prometió confirmar en la fase 1 y no recibió la orden de la fase 2.
🗣️ Sus recursos quedan bloqueados y no puede decidir por su cuenta: confirmar podría contradecir al
coordinador, y deshacer podría romper la promesa. Se queda esperando.
🔬 Resolverlo requiere intervención manual, consultando el registro del coordinador si existe. Es el
modo de fallo que hizo impopular a XA y el que las alternativas evitan al no tener coordinador.

**02 → 10. ¿Por qué el formato posicional hace que cambiarlo sea un proyecto?**

⏱️ Porque el contrato son las posiciones exactas y lo comparten dos organizaciones.
🗣️ Añadir un campo desplaza todo lo que viene detrás, así que ambos lados tienen que desplegar de
forma coordinada. No hay compatibilidad hacia atrás natural como en JSON, donde un campo nuevo se
ignora.
🔬 Por eso los formatos posicionales suelen reservar espacios de relleno para crecer, y por eso los
cambios se agrupan en versiones con fecha acordada. Es expand/contract llevado al extremo de dos
organizaciones que despliegan por su cuenta.

**02 → 11. ¿Funciona el outbox con MQ?**

⏱️ Sí, exactamente igual: la tabla es la misma y el relay pone el mensaje en la cola en vez de
publicarlo en un topic.
🗣️ Escribes el cambio de estado y el mensaje en la misma transacción local, y un proceso aparte lee
la tabla y lo pone en MQ. Sin coordinador, sin bloqueo distribuido.
🔬 Y en banca da una ventaja adicional: la tabla de outbox es un registro de qué se ordenó y cuándo,
que es exactamente lo que la conciliación necesita. El outbox no solo garantiza la entrega, deja
evidencia.

**02 → 12. ¿Qué métrica importa en una cola: profundidad o antigüedad?**

⏱️ La antigüedad del mensaje más viejo pendiente.
🗣️ Mil mensajes consumiéndose rápido es tráfico; uno de hace veinte minutos es un incidente. La
profundidad mide carga, la antigüedad mide si el mecanismo funciona.
🔬 Es el mismo criterio que el lag del outbox y el del consumidor de Kafka. Y en banca hay un matiz:
durante la ventana batch la profundidad crece por diseño, así que el umbral de alerta tiene que ser
distinto o el equipo aprenderá a ignorar las alertas.

**02 → 13. ¿Por qué "sin respuesta" no se reintenta a ciegas?**

⏱️ Porque puede haberse ejecutado: el timeout no dice que no pasó, dice que no lo sabes.
🗣️ Reintentar una orden de transferencia que sí se ejecutó produce un segundo asiento. En banca eso
no es un duplicado técnico, es dinero movido dos veces y una reclamación.
🔬 Las opciones, en orden: consultar el estado en el core por la clave de negocio, que es lo correcto
si el core lo permite; dejarlo en estado `SIN RESPUESTA` y que lo resuelva la conciliación; y nunca
reintentar sin haber verificado la idempotencia del receptor.

**02 → 14. ¿Qué costaba XA, en tres puntos?**

⏱️ Bloqueo de recursos durante toda la transacción, coordinador como punto único de fallo, y soporte
inexistente en tecnologías modernas.
🗣️ El bloqueo entre las dos fases hace que el throughput caiga con la contención. Si el coordinador
muere en medio, los participantes quedan en duda y hace falta intervención. Y ni Kafka, ni las APIs
de terceros, ni la mayoría de bases NoSQL participan.
🔬 El tercero es el que lo condenó en la práctica: aunque los dos primeros fueran asumibles, XA solo
funciona si **todos** los participantes lo soportan, y eso dejó de ser cierto.

**02 → 15. ¿Por qué el sector se movió a outbox sin apagar XA?**

⏱️ Porque outbox da garantías equivalentes sin coordinador, pero migrar XA que funciona no aporta
valor y sí riesgo.
🗣️ Lo nuevo se construye con outbox: atomicidad dentro de una sola base de datos e idempotencia en el
consumidor. Lo viejo sigue con XA hasta que ese componente se retire por otra razón.
🔬 Es la doctrina general del legado bancario: no se moderniza lo que funciona, se moderniza lo que
duele o lo que hay que tocar de todos modos. Proponer una migración de XA por pureza arquitectónica
es exactamente el tipo de propuesta que no se aprueba.

**02 → 16. ¿Por qué la alerta de cola necesita un umbral distinto durante la ventana?**

⏱️ Porque durante el cierre el core no consume y la profundidad crece por diseño.
🗣️ Con el mismo umbral de día, cada noche se dispararían alertas por un comportamiento esperado. Eso
produce fatiga y entrena al equipo a ignorarlas, que es peor que no tener alerta.
🔬 La forma correcta: umbrales por franja horaria, o alertar sobre la **tasa de consumo** en vez de la
profundidad, o suprimir la alerta durante la ventana declarada y reactivarla al abrir — con una
alerta específica si a la apertura la cola no empieza a bajar.

**02 → 17. ¿Qué pasa si la cola de respuesta es compartida entre instancias?**

⏱️ Que la respuesta puede llegar a una instancia distinta de la que envió la petición.
🗣️ Eso obliga a que el estado esté en la base de datos y no en memoria, y a que cualquier instancia
pueda procesar cualquier respuesta a partir del `correlationId`.
🔬 La alternativa es una cola de respuesta exclusiva por instancia, que simplifica el código y
complica el despliegue: si la instancia muere, su cola queda huérfana con respuestas que nadie
procesará. Para peticiones diferidas de minutos, la cola compartida con estado persistido es casi
siempre la opción correcta.

**02 → 18. ¿Cómo se hace idempotente un consumidor de MQ?**

⏱️ Con una tabla de inbox indexada por el identificador del mensaje o por la clave de negocio,
escrita en la misma transacción que el efecto.
🗣️ Al recibir, se intenta insertar el identificador; si viola la restricción única, el mensaje ya se
procesó y se descarta. Si no, se inserta y se aplica el efecto, todo en el mismo commit.
🔬 En banca es mejor usar la **clave de negocio** que el identificador del mensaje: el mismo pago
puede llegar por dos canales o reenviarse con otro identificador técnico, y la clave de negocio lo
detecta igual.

**02 → 19. ¿Qué ventaja adicional da el outbox en banca, más allá de la atomicidad?**

⏱️ Deja evidencia en tu base de datos de qué se ordenó y cuándo, que es lo que la conciliación
necesita.
🗣️ La tabla de outbox es un registro consultable de todas las órdenes emitidas, con su marca de
tiempo y su estado de publicación. Ante un descuadre, es el primer sitio donde mirar y responde la
pregunta "¿lo ordené yo?".
🔬 Sin outbox, esa evidencia habría que construirla aparte, y probablemente en otra transacción —con
lo que volvería el problema de la doble escritura aplicado al propio registro—. Es un beneficio que
no se planifica y que acaba siendo decisivo.

**02 → 20. ¿Cuándo NO usarías MQ para algo nuevo?**

⏱️ Entre tus propios servicios, donde Kafka, RabbitMQ o incluso una tabla con un poller resuelven
mejor.
🗣️ MQ es caro de operar, punto a punto, y no relee. Para comunicación interna nueva, si necesitas
varios consumidores o reproceso, Kafka; si necesitas enrutamiento o prioridades, RabbitMQ; y si el
volumen es bajo con un consumidor, una tabla con `FOR UPDATE SKIP LOCKED`.
🔬 La excepción legítima: reutilizar MQ porque ya está operado, el equipo lo conoce y el caso encaja
en punto a punto. Ahí añadir otro broker por pureza es peor que usar el que existe.

**02 → 21. Diseña la ordenación de una transferencia contra un core que solo expone colas MQ, con respuesta diferida de hasta 5 minutos.**

⏱️ La orden es una entidad con máquina de estados, publicada por outbox, con clave de negocio como
idempotencia y un proceso que resuelve las vencidas.
🗣️ El diseño:

```text
Modelo: OrdenTransferencia { id (clave de negocio), estado, correlationId, enviadaEn,
                             respondidaEn, resultado }
        Estados: ACEPTADA → ENVIADA → RESPONDIDA(ok|ko) → SIN_RESPUESTA → RESUELTA

Flujo:
  1. Acepto la orden del cliente y la persisto en estado ACEPTADA. Devuelvo un identificador.
     El cliente NO espera: la operación es asíncrona de cara a él también.
  2. En la misma transacción, escribo el mensaje en la tabla de OUTBOX.
  3. El relay lo pone en la cola de peticiones → estado ENVIADA.
  4. Un consumidor de la cola de respuestas casa por correlationId y actualiza a RESPONDIDA.
  5. Un proceso periódico marca como SIN_RESPUESTA las ENVIADA con más de 5 minutos + margen.
  6. Para las SIN_RESPUESTA: consulta de estado al core por la clave de negocio si es posible;
     si no, entran en el circuito de conciliación. NUNCA se reintentan a ciegas.
```

🔬 Los detalles que el entrevistador buscará. **El estado en base de datos, no en memoria**, porque la
respuesta puede llegar a otra instancia y porque un despliegue en esos cinco minutos perdería todo.
**La clave de idempotencia es de negocio** —el identificador de la orden que yo genero al aceptar— y
viaja en el mensaje, de modo que si el core la recibe dos veces la descarta. **El estado
`SIN_RESPUESTA` no es un error**: es una ambigüedad que necesita resolución, y modelarlo
explícitamente es lo que evita que alguien "arregle" el flujo reintentando. Y **el cliente ve el
estado**: la app consulta por el identificador y muestra "procesando", que es honesto con una
respuesta que puede tardar minutos.

**02 → 22. "El core no responde." Describe cómo investigas y qué te dice cada hallazgo.**

⏱️ Miro primero la profundidad de la cola de peticiones: si crece, el core no consume y mis mensajes
están a salvo.
🗣️ El orden:

```text
1. ¿Crece la cola de PETICIONES?
     SÍ → el core no consume. Tus mensajes no se han perdido. ¿Es la ventana batch?
     NO → el core consume; el problema está después.
2. ¿Llegan mensajes a la cola de RESPUESTAS?
     NO → el core recibe y no responde: problema suyo, o está tardando más del plazo.
     SÍ → llegan pero no las procesas: mira tu consumidor.
3. ¿Tu consumidor está vivo y casando correctamente por correlationId?
4. ¿Hay mensajes en la DLQ? → formato inválido o fallo permanente en tu lado.
5. ¿Cuántas órdenes llevan más de 5 minutos en estado ENVIADA? → esa es la magnitud real.
```

🔬 Qué me dice cada hallazgo. Cola de peticiones creciendo **durante la ventana** es comportamiento
esperado, no incidente — y si la alerta saltó igual, el umbral está mal configurado. Cola creciendo
**fuera** de la ventana significa que el core tiene un problema y hay que escalarlo a su equipo, con
el dato de cuántos mensajes hay esperando. Respuestas llegando y no procesadas apunta a mi
consumidor: puede estar caído, o atascado en un mensaje envenenado. Y el punto 5 es el que traduce el
incidente a lenguaje de negocio: no "el core no responde", sino "hay 340 transferencias en estado
ambiguo", que es lo que hay que comunicar.

**02 → 23. Te piden migrar de XA a outbox en un componente que mueve dinero y lleva 12 años funcionando. ¿Lo haces? Justifica.**

⏱️ No, salvo que haya una razón concreta más allá de la pureza arquitectónica. Migrar XA que funciona
es riesgo sin retorno.
🗣️ El argumento: XA en ese componente está resolviendo el problema correctamente desde hace doce
años, y su modo de fallo —la transacción en duda— ya tiene procedimiento operativo conocido. Migrar
significa reescribir la lógica de publicación, introducir idempotencia en el consumidor si no la
tenía, y aceptar un periodo de convivencia con dos mecanismos en un flujo que mueve dinero. El
beneficio es arquitectónico; el riesgo es contable.
🔬 Cuándo sí lo haría, y son razones concretas: si hay que **añadir un destino que no soporta XA**
—Kafka, una API externa—, porque entonces XA ya no cubre el caso y hay que resolverlo de otro modo; si
el coordinador es un producto que se va a **retirar o dejar de tener soporte**; si las transacciones
en duda se están produciendo con frecuencia y el coste operativo es real y medible; o si ese
componente hay que reescribir de todos modos por otra razón, y entonces se aprovecha. En cualquiera de
esos casos, la migración sería progresiva: outbox para los flujos nuevos primero, convivencia con
idempotencia en el consumidor, y retirada de XA solo cuando el nuevo camino lleve meses estable. Y
declararía explícitamente que durante la convivencia el consumidor **tiene** que ser idempotente,
porque recibirá por los dos caminos.

---

# 03 — Batch y Spring Batch

**03 → 1. ¿Qué son `Job`, `Step` y chunk en Spring Batch?**

⏱️ El `Job` es el trabajo completo, el `Step` una fase, y el chunk el lote de elementos que se
procesan y confirman juntos.
🗣️ Un `Job` como "cierre diario" tiene varios `Step` en orden: leer fichero, calcular intereses,
generar salida. Dentro de cada `Step`, el ciclo es leer N, procesar N, escribir N y confirmar.
🔬 El chunk es lo que da el punto de reanudación: si falla en el lote 5.201, los 5.200 anteriores
están confirmados y el reinicio continúa desde ahí.

**03 → 2. ¿Qué hace el `JobRepository`?**

⏱️ Persiste el estado de cada ejecución: qué `Job`, con qué parámetros, en qué `Step`, cuántos
elementos y dónde falló.
🗣️ Es lo que distingue a Spring Batch de un bucle: sin ese estado no hay reinicio posible, ni
trazabilidad de la ejecución, ni protección contra ejecutar lo mismo dos veces.
🔬 Son seis tablas en la base de datos, y en banca su contenido es materia de auditoría: cuántos
registros leyó, procesó, saltó y escribió cada ejecución, conservado con retención regulatoria.

**03 → 3. ¿Qué diferencia hay entre retry, skip y restart?**

⏱️ Retry reintenta el elemento por un fallo transitorio; skip lo aparta por uno permanente; restart
relanza el `Job` desde el último chunk confirmado.
🗣️ Responden a tres preguntas distintas: ¿se arregla solo?, ¿es este registro?, ¿es la ejecución? Un
deadlock se reintenta; un JSON inválido se salta; una caída del proceso se reinicia.
🔬 Es la misma clasificación transitorio/permanente de los consumidores de eventos, aplicada al
batch. Un diseño que no las separa acaba saltándose errores transitorios y reintentando los
permanentes.

**03 → 4. Nombra las cuatro estrategias de paralelización.**

⏱️ Multi-hilo dentro de un `Step`, `Step`s en paralelo, particionado local, y particionado o chunking
remoto.
🗣️ El multi-hilo reparte los chunks entre hilos. Los `Step`s en paralelo ejecutan fases
independientes a la vez. El particionado divide el conjunto y ejecuta un `Step` por partición. El
remoto reparte entre varias JVM.
🔬 El particionado es la estrategia por defecto porque conserva el reinicio por partición. El
multi-hilo es el más rápido de activar y el que más trampas tiene.

**03 → 5. ¿Qué es el fichero de control?**

⏱️ Un fichero que acompaña al de datos con el número de registros y las sumas de importes.
🗣️ Permite validar antes de procesar que el fichero llegó completo: si el conteo no coincide, hubo
truncamiento y no se procesa nada.
🔬 Procesar el fichero de datos sin validarlo contra el de control es aceptar cualquier truncamiento
en silencio. Y en banca ese truncamiento se traduce en operaciones que nunca se aplicaron y que
aparecen en la conciliación de dos días después.

**03 → 6. ¿Dónde ocurre el commit en el procesamiento por trozos?**

⏱️ Al final de cada chunk, después de escribir los N elementos.
🗣️ No es por elemento ni al final del `Step`: es por lote. Eso da el punto de reanudación y acota
cuánto trabajo se pierde al fallar.
🔬 Y tiene una consecuencia importante: **el trabajo ya confirmado no se deshace**. Si el `Job` falla
a la mitad, la mitad de los intereses están aplicados, así que el proceso tiene que ser reanudable o
idempotente.

**03 → 7. ¿Qué pasa si un `ItemProcessor` devuelve `null`?**

⏱️ El elemento se descarta: no llega al `ItemWriter`.
🗣️ Es el mecanismo de filtrado. Spring Batch lo cuenta aparte como elemento filtrado, distinto de
procesado y de saltado.
🔬 Confundir filtrado con error es un fallo frecuente en los informes de ejecución: un proceso que
filtra el 40 % puede parecer correcto en el conteo de errores y estar descartando registros que
debían procesarse.

**03 → 8. ¿Para qué sirven los `JobParameters`?**

⏱️ Identifican la ejecución: un `Job` con los mismos parámetros no se ejecuta dos veces.
🗣️ Spring Batch lo impide por diseño, que es una protección contra ejecuciones duplicadas. El
parámetro típico en banca es la fecha de proceso, y es también lo que hace posible el reproceso: se
relanza con la fecha del día 3 y el proceso sabe qué periodo cubrir.
🔬 Añadir un `run.id` aleatorio "para poder repetir" anula esa protección. Si hay que repetir una
ejecución, lo correcto es reiniciarla o marcarla como fallida, no inventar un parámetro que la haga
parecer distinta.

**03 → 9. ¿Qué dos fuerzas opuestas determinan el tamaño del trozo?**

⏱️ Rendimiento contra trabajo perdido al fallar.
🗣️ Un chunk grande hace menos commits y va más rápido, y consume más memoria y pierde más trabajo si
falla. Uno pequeño pierde menos y paga más sobrecarga transaccional.
🔬 Valores típicos entre 100 y 1.000, calibrados midiendo. Depende del tamaño del elemento, del coste
de escritura y de cuánto duele reprocesar. No hay un número correcto universal.

**03 → 10. ¿Qué requisito debe cumplir el `ItemReader` para que el reinicio funcione?**

⏱️ Tiene que ser reanudable: saber retomar desde donde iba.
🗣️ Los lectores de fichero y de base de datos que vienen con Spring Batch lo son: guardan su posición
en el `ExecutionContext` y la restauran al reiniciar. Un lector propio mal implementado, no.
🔬 Si no lo es, el reinicio vuelve a leer desde el principio y **reprocesa lo ya aplicado**. En banca
eso significa intereses aplicados dos veces, y es el error más caro asociado al reinicio.

**03 → 11. ¿Por qué hay que registrar los elementos saltados?**

⏱️ Porque si no, se pierden sin rastro y alguien los descubre en la conciliación.
🗣️ Un `SkipListener` que escriba cada elemento saltado a un fichero o a una tabla, con su motivo, es
obligatorio. Es lo que permite reprocesarlos después de corregir la causa y lo que explica un
descuadre.
🔬 Y es materia de auditoría: cuántos registros se descartaron en cada ejecución y por qué es una
pregunta que un auditor hace. Un proceso que salta registros sin registrarlos produce diferencias sin
explicación.

**03 → 12. ¿Qué es un `Step` de cuadre y por qué es obligatorio en banca?**

⏱️ Un `Step` final que compara los totales procesados contra un registro de control y **falla el
`Job`** si no cuadran.
🗣️ Suma los importes y los conteos del proceso y los contrasta con el fichero de control o con el
total esperado. Si no coincide, la ejecución se marca como fallida en vez de terminar "correctamente"
con datos incompletos.
🔬 Sin él, un error silencioso —un truncamiento, registros saltados, un filtro mal puesto— pasa a
producción contable y se descubre días después. El cuadre es lo que convierte un fallo silencioso en
uno visible, que es el principio general de todo el corpus.

**03 → 13. ¿Por qué un proceso batch se diseña asumiendo que se va a caer?**

⏱️ Porque con millones de registros y horas de ejecución, la probabilidad de que algo falle a la
mitad es alta.
🗣️ Un dato inesperado, un deadlock, un despliegue, una caída de red. Y cuando ocurre, las preguntas
son inmediatas: ¿se reanuda o se reprocesa?, ¿lo ya hecho quedó aplicado?, ¿cabe rehacerlo en el
tiempo que queda?
🔬 Un proceso que no responde a esas preguntas no está diseñado, está escrito. Y el rendimiento o el
paralelismo se abordan **después** de haber resuelto la reanudación: de nada sirve que vaya rápido si
al fallar hay que empezar de cero.

**03 → 14. ¿Qué peligro tiene subir el `skipLimit`?**

⏱️ Convierte un fichero corrupto en una ejecución "correcta" que procesó una fracción de los
registros.
🗣️ El límite existe para que el proceso falle cuando debe fallar. Si se sube para "que no dé
problemas", un error sistemático —un cambio de formato, una codificación distinta— se traduce en
miles de saltos y un `Job` que termina en verde.
🔬 La forma correcta ante muchos saltos es investigar la causa, no elevar el umbral. Y si de verdad
hay registros inválidos esperables, se registran, se cuentan y se reportan como parte del resultado,
en vez de esconderse en el límite.

**03 → 15. ¿Por qué usar `now()` en vez del parámetro de fecha rompe el reproceso?**

⏱️ Porque al reprocesar el día 3 desde hoy, calcula todo con la fecha de hoy.
🗣️ Los intereses, los vencimientos, las comisiones y los rangos de selección se calculan con la fecha
de proceso, no con la del reloj. Con `now()`, un reproceso produce resultados distintos a la ejecución
original.
🔬 Funciona perfectamente hasta el primer reproceso, que es lo que lo hace peligroso: el bug está
latente durante meses y se manifiesta justo cuando hay que corregir otra cosa, es decir, en el peor
momento posible.

**03 → 16. ¿Qué trampa tiene paralelizar con multi-hilo?**

⏱️ Que muchos `ItemReader` no son seguros para hilos, y usarlos así salta o duplica registros **sin
error**.
🗣️ El lector mantiene estado interno —la posición actual—, y varios hilos accediendo a la vez lo
corrompen. El resultado no es una excepción: es que algunos registros se procesan dos veces y otros
ninguna.
🔬 Es un fallo silencioso, que es la peor categoría. Se detecta en la conciliación, días después. Por
eso el particionado es preferible: cada partición tiene su propio lector, y el problema no existe.

**03 → 17. ¿Por qué el particionado es la estrategia por defecto?**

⏱️ Porque conserva el reinicio por partición y evita los problemas de concurrencia del lector.
🗣️ Un `Partitioner` divide el trabajo —por rango de identificador, por oficina, por tipo de
producto— y cada partición se ejecuta como un `Step` independiente, con su propio lector y su propio
estado. Si falla una, se reinicia solo esa.
🔬 Y es controlable: puedes decidir cuántas particiones y cómo se reparten, lo que permite equilibrar
si los datos no están distribuidos uniformemente. El multi-hilo simple no da ninguna de las dos
cosas.

**03 → 18. ¿Qué limita normalmente un batch, si no es la CPU?**

⏱️ La base de datos —conexiones, contención de bloqueos— o el sistema de ficheros.
🗣️ En procesos bancarios reales, la mayoría del tiempo suele estar en la escritura o en una consulta
por elemento, que es un N+1 en versión batch. Paralelizar contra una base de datos ya saturada
empeora el tiempo total, porque añade contención.
🔬 Por eso lo primero es **medir dónde se va el tiempo**. Arreglar una consulta por elemento —haciendo
lecturas por lote— suele dar más que cualquier paralelización, y es mucho más barato. Paralelizar es
la última optimización.

**03 → 19. ¿Qué problema crea añadir un `run.id` aleatorio a los parámetros?**

⏱️ Anula la protección de Spring Batch contra ejecutar el mismo `Job` dos veces.
🗣️ Con un parámetro aleatorio, cada lanzamiento es una ejecución distinta a ojos del marco, así que
se puede ejecutar el cierre del día 3 dos veces sin que nada lo impida. Y si el proceso no es
idempotente, duplica.
🔬 Se añade con buena intención —"necesito poder relanzarlo"— y la necesidad real suele ser otra:
reiniciar una ejecución fallida, que se hace con el mecanismo de reinicio, o reprocesar un día, que se
hace cambiando el parámetro de fecha. El `run.id` es el atajo que desactiva la red de seguridad.

**03 → 20. ¿Qué hay que medir antes de paralelizar?**

⏱️ Dónde se va el tiempo: lectura, procesamiento, escritura, o esperas en la base de datos.
🗣️ Si el 80 % está en una consulta por elemento, paralelizar multiplica esa consulta y satura la base
de datos. Si está en la escritura, paralelizar aumenta la contención de bloqueos. Si está en CPU de
procesamiento, entonces sí, paralelizar ayuda.
🔬 Las métricas concretas: tiempo por fase, número de consultas por elemento, tiempo de espera de
conexión del pool, y esperas de bloqueo en la base de datos. Con esos cuatro números, la decisión es
evidente; sin ellos, es una apuesta.

**03 → 21. Diseña el proceso de devengo de intereses de 8 millones de cuentas en una ventana de 4 horas, sabiendo que puede fallar a la mitad.**

⏱️ `Job` con fecha de proceso como parámetro, particionado por rango de cuenta, chunk calibrado,
skip con registro, y `Step` de cuadre final que falla el `Job`.
🗣️ El diseño:

```text
JobParameters: fechaProceso (NUNCA now())

Step 1 — validación   → comprueba el fichero de control o el total esperado de cuentas.
Step 2 — devengo      → particionado por rango de identificador de cuenta (p. ej. 32 particiones)
    reader   paginado por rango, reanudable
    processor cálculo del devengo con fechaProceso; devuelve null si la cuenta no aplica
    writer   escritura por lote de los apuntes
    chunk    500, calibrado midiendo
    skip     excepciones de datos inválidos, con LÍMITE bajo y SkipListener que registra
    retry    deadlocks y timeouts, 3 intentos con backoff
Step 3 — cuadre       → suma de apuntes generados vs total esperado. Si no cuadra, FALLA el Job.
```

🔬 Lo que hace viable el diseño. **El particionado** da reinicio por partición: si falla la partición
17, se reinicia solo esa, no los 8 millones. **La idempotencia del apunte** es obligatoria: cada
apunte lleva clave de negocio `cuentaId + fechaProceso + tipo`, con restricción única, de modo que un
reinicio que reprocese algo ya aplicado no duplique. **El `Step` de cuadre** convierte un fallo
silencioso en uno visible. Y sobre el tiempo: antes de paralelizar mediría dónde se va —en devengo
suele ser la escritura o una consulta de condiciones por cuenta— porque arreglar un N+1 da más que
32 particiones. Declararía también el plan si la ventana se desborda: qué parte del proceso puede
ejecutarse fuera de ella, o qué se puede precalcular durante el día.

**03 → 22. El cierre del día 3 se ejecutó con un bug y hay que rehacer del 3 al 5. Describe el procedimiento y qué tuvo que estar diseñado de antemano.**

⏱️ Deshacer lo aplicado con contra-asientos, corregir el código, y reprocesar los tres días **en
orden** con su fecha de proceso.
🗣️ El procedimiento:

```text
1. PARAR. No ejecutar el cierre del día 6 hasta resolver, o el error se propaga.
2. Cuantificar: qué cuentas y qué importes se vieron afectados los días 3, 4 y 5.
3. Corregir el código y verificarlo contra datos reales de esos días en un entorno aparte.
4. Deshacer: contra-asientos de lo aplicado incorrectamente. NO se modifican los apuntes.
5. Reprocesar el día 3 con fechaProceso=día 3. Cuadrar. Verificar una muestra a mano.
6. Repetir para el 4 y el 5, EN ORDEN, porque el devengo del 4 depende del saldo del 3.
7. Ejecutar el cierre del 6 con normalidad.
8. Registrar todo en la pista de auditoría, con quién autorizó la corrección.
```

🔬 Lo que tuvo que estar diseñado de antemano, y son cuatro cosas: **la fecha de proceso como
parámetro**, sin la cual el paso 5 es imposible; **idempotencia por clave de negocio**, para que el
reproceso no duplique si alguna parte ya estaba bien; **el `Step` de cuadre**, que es lo que permite
verificar cada reproceso antes de pasar al siguiente; y **movimientos inmutables con contra-asiento**,
porque si el diseño permitiera modificar apuntes, alguien lo haría y se perdería la evidencia. Añadiría
dos cosas más: el **orden de dependencia** entre días no es opcional y hay que tenerlo documentado; y
la comunicación a negocio, porque los clientes verán en su extracto el apunte original, su anulación y
el correcto — y eso hay que explicarlo antes de que llamen.

**03 → 23. Un batch que tardaba 2 horas ahora tarda 5 y no cabe en la ventana. Da tres hipótesis en orden y di cómo las confirmas.**

⏱️ Creció el volumen de datos; apareció una consulta por elemento; o hay contención nueva en la base
de datos.
🗣️ Primera y más probable: el conjunto creció y el proceso escala linealmente o peor. Es esperable y
se confirma comparando el número de registros procesados en las ejecuciones antiguas y las actuales —
el `JobRepository` lo guarda, que es una de las razones por las que existe. Segunda: un cambio
introdujo una consulta por elemento —una validación nueva, un enriquecimiento— convirtiendo el proceso
en un N+1; se confirma contando consultas por registro. Tercera: otro proceso entró en la misma
ventana y compite por la base de datos, o un índice se degradó; se confirma mirando esperas de bloqueo
y planes de ejecución.
🔬 Cómo lo abordaría. Con los datos del `JobRepository` puedo calcular el **tiempo por registro** de
cada ejecución histórica: si es constante, el problema es volumen; si subió, el problema es el
proceso. Esa sola métrica separa la primera hipótesis de las otras dos. Después, medir por fase para
localizar dónde se va el tiempo. Y las soluciones en orden de coste: arreglar el N+1 con lectura por
lote, revisar índices, ajustar el tamaño de chunk, y solo entonces paralelizar con particionado. Una
cuarta opción que plantearía a negocio si nada de eso basta: mover parte del cálculo fuera de la
ventana, precalculando durante el día lo que no dependa del cierre.

---

# 04 — Capa anticorrupción sobre el legado

**04 → 1. ¿Qué es una capa anticorrupción?**

⏱️ Un componente que traduce entre el modelo de un sistema externo y el tuyo, protegiendo tu dominio.
🗣️ Habla el idioma del core por un lado y el tuyo por el otro, y concentra **todo** el conocimiento
del modelo ajeno. Cuando el sistema externo cambia, tocas solo la ACL.
🔬 Es un Adapter con intención de arquitectura: lo que la distingue es que traduce **conceptos**, no
solo firmas, y por eso captura las reglas implícitas que nadie documentó.

**04 → 2. ¿Qué cuatro cosas traduce una ACL?**

⏱️ Formato, vocabulario, estructura y semántica.
🗣️ Formato: posicional a objetos, importes sin decimal a `Money`. Vocabulario: `CTA-MAESTRA` a
`Cuenta`, `SITOPER=3` a `EstadoCuenta.ACTIVA`. Estructura: cuatro campos a un único `Iban`.
Semántica: "si `IND1` viene en blanco, admite descubierto" a un booleano con nombre.
🔬 La cuarta es la difícil y la que da valor: esas reglas no están escritas en ningún sitio y son el
conocimiento que la ACL captura y documenta.

**04 → 3. ¿En qué tres piezas se estructura?**

⏱️ Cliente técnico, modelo externo y traductor.
🗣️ El cliente técnico habla el protocolo —MQ, CICS, fichero, SOAP— y no sabe nada de negocio. El
modelo externo son los DTO que reflejan el formato del core tal cual. El traductor es donde vive todo
el conocimiento y el único sitio donde conviven los dos vocabularios.
🔬 Separarlas permite que un cambio de protocolo no toque las reglas y que un cambio de regla no toque
el transporte. Mezclarlas es el error habitual y produce una capa que hay que reescribir entera ante
cualquier cambio.

**04 → 4. ¿Cuáles son las tres capas de prueba de una ACL?**

⏱️ Respuestas reales capturadas, un doble del core, y pruebas de contrato contra el entorno real.
🗣️ Las capturas reales —anonimizadas— prueban el traductor contra lo que el core devuelve de verdad.
El doble permite probar el flujo completo sin depender de su entorno. Las pruebas de contrato
periódicas detectan que el core cambió algo.
🔬 Hacen falta las tres. Probar solo contra el doble produce una ACL que funciona con lo que **tú
creías** que el core devuelve, y la primera respuesta inesperada en producción revela la diferencia.

**04 → 5. ¿Qué es el patrón conformista?**

⏱️ Adoptar el modelo del proveedor tal cual, sin traducir.
🗣️ Es la alternativa barata a la ACL: no pagas mapeo ni mantienes un modelo propio. A cambio, el
modelo del otro es el tuyo, y sus cambios te atraviesan.
🔬 Es la opción correcta cuando el proveedor es limpio y estable y tú no tienes un modelo de dominio
propio que proteger. En banca contra el core casi nunca se da esa condición, pero contra otros
proveedores sí.

**04 → 6. ¿Cuáles son las dos señales de que una ACL funciona?**

⏱️ Que un cambio del core toca solo la ACL, y que ningún término del core aparece en tu dominio.
🗣️ La primera es de mantenimiento: si añadir un campo en el core obliga a tocar cinco servicios, la
traducción no está encapsulada. La segunda es de modelo: si tu `Cuenta` tiene un campo `codSitOper`,
la corrupción ya entró.
🔬 Son comprobaciones objetivas y verificables, no impresiones. La segunda se puede automatizar con
una regla de ArchUnit que prohíba ciertos nombres fuera del paquete de infraestructura.

**04 → 7. ¿Por qué el modelo externo se conserva con sus nombres feos?**

⏱️ Porque intentar mejorarlo a medio camino produce un tercer vocabulario que no es ni el suyo ni el
tuyo.
🗣️ Si el DTO se llama `CuentaMaestraDTO` con campos `situacionOperativa`, ya has traducido a medias:
alguien tendrá que saber que `situacionOperativa` corresponde a `SITOPER`, y la correspondencia queda
implícita.
🔬 Con los nombres originales, la correspondencia con la documentación del core —si existe— y con los
copybooks es directa, y el traductor es el único sitio donde se hace la traducción. Idealmente el
modelo externo se genera del copybook o del WSDL, no se escribe a mano.

**04 → 8. ¿Por qué la traducción de semántica es la parte difícil?**

⏱️ Porque las reglas implícitas no están documentadas en ningún sitio.
🗣️ Qué significa un campo en blanco, qué combinación de códigos implica qué estado, cuándo un importe
viene con signo al final. Eso no está en ningún manual: está en el código del core y en la cabeza de
gente que se va jubilando.
🔬 Por eso el traductor es también documentación: cada regla implícita va con un comentario que diga
de dónde salió y cuándo se confirmó. Ese comentario suele valer más que el código, porque es el único
registro de un conocimiento que se está perdiendo.

**04 → 9. ¿Por qué hay que anonimizar las respuestas capturadas?**

⏱️ Porque contienen datos de clientes reales, y guardarlas en el repositorio sin anonimizar es una
filtración.
🗣️ Una captura de una consulta de cuenta lleva nombre, identificador fiscal, saldo y movimientos. En
el repositorio la ve todo el que clona, queda en el historial y se replica en cada copia.
🔬 La anonimización tiene que conservar la **forma** —longitudes, formatos, casos límite— y sustituir
los valores. Y hay que hacerlo en el momento de capturar, no después: una captura sin anonimizar que
llega al repositorio ya es un incidente, aunque se borre.

**04 → 10. ¿Qué detecta una prueba de contrato periódica contra el entorno real?**

⏱️ Que el core cambió algo sin avisarte.
🗣️ Un campo nuevo, un formato distinto, un código de retorno que antes no existía. El equipo del core
despliega por su cuenta y no siempre comunica, y la primera señal suele ser un error en producción.
🔬 Con un conjunto pequeño de pruebas ejecutándose periódicamente cuando su entorno está vivo, te
enteras antes que tus usuarios. No sustituye a las otras dos capas: detecta la **deriva**, que es un
problema distinto de la corrección de la traducción.

**04 → 11. ¿Por qué la ACL suele acabar teniendo caché?**

⏱️ Porque muchos cores cobran por transacción o tienen capacidad contratada limitada.
🗣️ Cachear las consultas repetidas deja de ser una optimización y pasa a ser un requisito: sin ella,
el coste o el límite de transacciones por segundo se convierten en el techo del sistema.
🔬 Y es un argumento que funciona muy bien con negocio, porque tiene un número en euros. La caché en
la ACL tiene además una ventaja: está en el sitio donde se conoce la volatilidad de cada dato, así
que los TTL se pueden calibrar por tipo de consulta.

**04 → 12. ¿Qué es el modo degradado durante la ventana batch?**

⏱️ El comportamiento definido de tu sistema mientras el core está cerrado.
🗣️ Puede ser encolar las órdenes y avisar al usuario, servir el último dato conocido con su marca de
tiempo, o rechazar explícitamente. La decisión es de negocio y se toma operación por operación.
🔬 Lo que no es aceptable es que el comportamiento durante cuatro horas cada noche sea el resultado
accidental de un timeout. La ACL es el sitio natural para implementarlo, porque es quien sabe si el
core está en ventana.

**04 → 13. ¿Cuándo es mejor conformista que ACL?**

⏱️ Cuando el modelo del proveedor es limpio y estable, y tú no tienes un modelo propio que proteger.
🗣️ La ACL cuesta mapeo en dos sentidos, duplicación de conceptos, latencia y un componente más.
Contra un proveedor bien diseñado que cambia poco, ese coste no compra nada: adoptas su modelo y
listo.
🔬 El criterio no es "es externo, luego ACL". Es: ¿su modelo contaminaría el mío?, ¿cambia con
frecuencia?, ¿tengo poder de negociación? Si las tres respuestas son favorables, conformista es más
barato y más honesto.

**04 → 14. ¿Cuándo una ACL no aporta nada, aunque haya un sistema externo?**

⏱️ Cuando tu servicio es CRUD sobre los datos del core y no tienes modelo de dominio propio.
🗣️ Si tu "dominio" son los mismos conceptos del core con otros nombres, la ACL traduce de un modelo
ajeno a otro ajeno. Es mapeo estéril, exactamente como un DTO entre capas internas que es copia
exacta de la entidad.
🔬 Es el caso más común y el menos reconocido. La comprobación: ¿hay alguna invariante, alguna regla
de negocio propia, algún concepto que no exista en el core? Si no, lo honesto es exponer su modelo y
declararlo, en vez de inventar una capa de traducción que solo renombra.

**04 → 15. ¿Qué pasa si `codSitOper` aparece en tu dominio?**

⏱️ La corrupción ya entró: tu modelo es el del core con otro envoltorio.
🗣️ A partir de ahí, cada cambio del core te atraviesa: si añaden el valor `7` a la situación
operativa, hay que buscar todos los sitios donde se compara. Y tu lenguaje ubicuo desaparece, porque
el negocio no habla de `codSitOper`.
🔬 La corrección no es renombrar el campo: es traducirlo a un concepto propio —`EstadoCuenta` con sus
valores de negocio— en la ACL, y que el dominio solo conozca ese. Y se puede verificar
automáticamente con una regla que prohíba esos nombres fuera de infraestructura.

**04 → 16. ¿Por qué probar solo contra el doble es insuficiente?**

⏱️ Porque el doble responde lo que tú creías que el core devuelve.
🗣️ Lo escribiste a partir de la documentación —que puede estar desactualizada— y de los casos que
conoces. Los casos raros, los formatos inesperados y las respuestas de error con estructura distinta
no están ahí porque no los conocías.
🔬 Por eso hacen falta las respuestas reales capturadas: contienen los casos que nadie te contó. El
doble sirve para probar el flujo completo sin depender del entorno del core, que es otra cosa y
también hace falta.

**04 → 17. ¿Por qué la ACL acaba siendo un componente crítico?**

⏱️ Porque concentra caché, resiliencia, degradación, limitación de tasa, trazabilidad e idempotencia,
además de la traducción.
🗣️ Empieza presupuestada como "un mapeador" y termina siendo el punto por el que pasa toda la
interacción con el core, con su propia observabilidad, su SLA y su guardia.
🔬 Reconocerlo en el diseño evita la sorpresa y permite dimensionar bien: necesita monitorización
propia, pruebas de carga y plan de recuperación. Un equipo que la trata como una clase de mapeo la
subestima por un factor grande.

**04 → 18. ¿Qué información hay que documentar en el traductor y por qué?**

⏱️ Las reglas implícitas del core, con su origen y su fecha de confirmación.
🗣️ *"Si `IND1` viene en blanco, la cuenta admite descubierto — confirmado con el equipo de core,
marzo de 2026"*. Ese comentario es el único registro de un conocimiento que no está en ningún manual.
🔬 Y es información que se pierde cuando la persona que la averiguó cambia de proyecto. En un dominio
donde el conocimiento original se jubiló, el traductor comentado es un activo real, y a veces la
única documentación existente de cómo se comporta el core.

**04 → 19. ¿Por qué separar transporte, modelo externo y traducción?**

⏱️ Para que un cambio de protocolo no toque las reglas y un cambio de regla no toque el transporte.
🗣️ Si el banco migra de MQ a una API REST, solo cambia el cliente técnico: el modelo externo y el
traductor siguen valiendo. Si el core añade un código de situación, solo cambia el traductor.
🔬 Es separación de responsabilidades aplicada a una frontera concreta, y es lo que hace que la ACL
envejezca bien. Mezclarlas produce una capa donde cualquier cambio obliga a revisarlo todo y a
reprobarlo todo.

**04 → 20. ¿Qué argumento económico da la caché en la ACL?**

⏱️ Que muchos cores cobran por transacción, así que cada consulta evitada tiene un precio.
🗣️ Con dos millones de usuarios consultando varias veces al día, el ahorro es una cifra concreta que
se puede poner en una diapositiva. Convierte una decisión técnica en una decisión de negocio
favorable.
🔬 Y hay un segundo argumento del mismo tipo: la capacidad contratada. Muchos contratos fijan un
máximo de transacciones por segundo, y superarlo puede tener penalización. La caché no solo ahorra:
evita un riesgo contractual.

**04 → 21. Diseña la ACL sobre un core que expone consulta de saldo por CICS y ordenación de transferencias por MQ, con ventana de cierre de 4 horas.**

⏱️ Dos clientes técnicos distintos, un modelo externo por operación, un traductor común, y todo lo de
alrededor: caché, resiliencia, modo degradado e idempotencia.
🗣️ El diseño:

```text
DOMINIO          → puertos: ConsultaDeSaldo, OrdenDeTransferencia. Hablan Cuenta, Money, Iban.

INFRAESTRUCTURA
  cliente CICS   → llamada síncrona. Timeout 2 s, circuit breaker, bulkhead propio.
  cliente MQ     → puesta en cola + consumidor de respuestas. Estado en BD, correlationId.
  modelo externo → CuentaMaestraRecord, OrdenRecord: nombres y formatos del core, tal cual.
  traductor      → SITOPER→EstadoCuenta, IMPSAL→Money, CODENT+CODOFI+DC+NUMCTA→Iban.
                   Reglas implícitas documentadas con su origen.
  caché          → saldo con TTL corto (segundos) y marca de tiempo. Argumento: coste por transacción.
  ventana        → el componente sabe el horario de cierre:
                     consulta  → sirve el último dato con su hora (modo degradado)
                     orden     → encola en outbox y avisa al usuario de que se ejecutará al abrir
  idempotencia   → clave de negocio en la orden; el core la descarta si la repite.
```

🔬 Las decisiones que justificaría. **Dos clientes técnicos separados** porque los protocolos y sus
modos de fallo no se parecen: CICS falla rápido, MQ no responde. **El modo degradado explícito por
operación**, acordado con negocio: consultar admite un dato de hace minutos con su hora; ordenar no
admite un resultado inventado, así que se encola. **La caché con TTL corto y marca de tiempo visible**
resuelve el coste sin mentir al usuario. Y **el estado de la orden en base de datos**, con los tres
estados, porque la respuesta de MQ puede tardar y llegar a otra instancia. Declararía que esta ACL es
un componente crítico con su propia observabilidad: antigüedad de órdenes sin respuesta, tasa de
acierto de caché, y disponibilidad del core medida por mí, no la declarada.

**04 → 22. Tu equipo dice tener una ACL, pero cada cambio del core obliga a tocar cinco servicios. Diagnostica y propón el camino de corrección.**

⏱️ La ACL es un nombre de paquete: el modelo del core se filtró al dominio y a los demás servicios.
La primera señal de las dos falló.
🗣️ El diagnóstico se confirma buscando términos del core fuera del paquete de infraestructura:
`codSitOper`, `importeSinDecimal`, tipos generados del copybook usados como parámetros de métodos de
negocio. Si aparecen, la traducción nunca ocurrió realmente: se renombró la clase y se siguió pasando
el mismo modelo.
🔬 El camino de corrección, que es gradual porque no se puede parar: **inventariar** dónde aparecen
esos términos, con una regla de ArchUnit que los detecte y falle —al principio solo informando—.
**Definir el modelo de dominio real**: qué es una `Cuenta` para nosotros, qué estados tiene en
lenguaje de negocio. **Traducir en el borde**, servicio por servicio, empezando por el que más sufre
los cambios. Y **activar la regla en modo estricto** por paquete, a medida que cada uno queda limpio.
Mediría el avance con el número de apariciones de términos del core fuera de infraestructura, que
debe llegar a cero. Y sería honesto sobre el coste: si los cinco servicios son CRUD sobre datos del
core sin modelo propio, quizá la respuesta correcta no es traducir, sino reconocer que son conformistas
y dejar de llamarlo ACL.

**04 → 23. Hay que integrar con un core del que nadie conoce las reglas y cuyo entorno de pruebas está caído la mitad del tiempo. ¿Cómo lo abordas?**

⏱️ Capturo respuestas reales como primera fuente de verdad, construyo un doble a partir de ellas, y
documento cada regla descubierta en el traductor.
🗣️ El plan:

```text
1. CAPTURAR. Antes de escribir código, registrar respuestas reales del core para todos los
   casos que se pueda provocar: cuenta activa, bloqueada, en trámite, con saldo negativo,
   inexistente, y los errores. Anonimizar al capturar.
2. CARACTERIZAR. Escribir pruebas que documenten el comportamiento observado, aunque no se
   entienda por qué. Es la técnica de Feathers: primero fijas qué hace, luego averiguas por qué.
3. PREGUNTAR. Con las capturas delante, hablar con quien quede del equipo de core. Las
   preguntas concretas sobre un caso real obtienen respuesta; las genéricas, no.
4. DOCUMENTAR en el traductor cada regla descubierta, con su origen y su fecha.
5. DOBLE a partir de las capturas, para poder desarrollar sin su entorno.
6. CONTRATO periódico contra el entorno real cuando esté vivo, para detectar deriva.
```

🔬 Lo que hace funcionar esto. La **captura es la fuente de verdad**, no la documentación: en un
sistema de treinta años, el manual y el comportamiento divergieron hace tiempo. Las **pruebas de
caracterización** permiten avanzar sin entenderlo todo, que es la única forma de avanzar aquí. Y el
**traductor comentado** se convierte en la documentación que no existía, lo que tiene valor mucho más
allá del proyecto. Añadiría una precaución práctica: presupuestar tiempo explícito para el
descubrimiento —no como tarea de desarrollo sino como fase— porque el error clásico es estimar la
integración como si las reglas fueran conocidas, y descubrir a mitad que la mitad del trabajo era
averiguarlas.

---

# 05 — ISO 20022, ISO 8583 y SWIFT

**05 → 1. ¿Qué es ISO 20022?**

⏱️ Un estándar de mensajería financiera basado en XML, con datos estructurados y un diccionario común
de conceptos.
🗣️ Es el que está sustituyendo a los mensajes MT en pagos, valores y tesorería. Su nomenclatura
identifica familia y tipo: `pacs.008` es la transferencia entre bancos, `pain.001` la orden del
cliente a su banco, `camt.053` el extracto.
🔬 No es un protocolo de transporte: define el contenido y la estructura. Cómo viaja —SWIFT, la red
local de pagos instantáneos, un fichero, una API— es otra decisión.

**05 → 2. ¿Qué diferencia hay entre `pain` y `pacs`?**

⏱️ `pain` es cliente↔banco; `pacs` es banco↔banco.
🗣️ `pain.001` es la orden que un cliente da a su banco; `pacs.008` es el mensaje con el que ese banco
la transmite al banco del beneficiario. Y `pain.002` informa al cliente del estado, mientras
`pacs.002` lo hace entre bancos.
🔬 Confundirlos es el error de vocabulario más frecuente, y distinguirlos demuestra de inmediato que
has trabajado con esto. La regla mnemotécnica: `pain` = *payments initiation*, la iniciación del
cliente; `pacs` = *payments clearing and settlement*, entre entidades.

**05 → 3. ¿Qué es ISO 8583 y para qué se usa?**

⏱️ El estándar binario de mensajería de tarjetas: autorizaciones, anulaciones y liquidaciones.
🗣️ Es de 1987 y sigue moviendo prácticamente todas las transacciones con tarjeta del mundo. Está
diseñado para latencia mínima, porque una autorización responde con el cliente esperando en el
terminal.
🔬 Su estructura: un MTI que dice el tipo de mensaje —`0100` petición de autorización, `0110`
respuesta— un bitmap que indica qué campos vienen, y campos numerados. El bitmap es lo que lo hace
compacto: no se envía lo que no aplica.

**05 → 4. ¿Qué es SWIFT y qué no es?**

⏱️ Es una red de mensajería entre bancos. **No** mueve dinero: transmite instrucciones.
🗣️ El dinero se mueve en los sistemas de liquidación de cada moneda, normalmente en el banco central.
SWIFT transporta la instrucción de que ese movimiento debe ocurrir.
🔬 La confusión es frecuente y tiene consecuencia práctica: la latencia de un pago internacional no es
la de SWIFT, es la de la cadena de bancos corresponsales y de sus horarios de liquidación. Por eso una
transferencia internacional puede tardar días aunque el mensaje llegue en segundos.

**05 → 5. ¿Qué diferencia hay entre BIC e IBAN?**

⏱️ El BIC identifica una **entidad**; el IBAN, una **cuenta**.
🗣️ El BIC —antes "código SWIFT"— dice a qué banco y a qué oficina va el mensaje. El IBAN identifica la
cuenta concreta del beneficiario, con su país, sus dígitos de control y el número de cuenta nacional.
🔬 En muchos pagos SEPA el BIC ya no es obligatorio porque se deriva del IBAN. Pero en pagos
internacionales sigue haciendo falta, y confundirlos produce errores de enrutamiento que acaban en
devolución.

**05 → 6. ¿Qué es `camt.053`?**

⏱️ El extracto de cuenta: *Bank to Customer Statement*.
🗣️ Es el mensaje con el que un banco entrega a su cliente —normalmente una empresa— el detalle de
movimientos de un periodo, con saldos de apertura y cierre.
🔬 Es el mensaje que más aparece en integraciones de tesorería corporativa, porque es lo que los ERP
consumen para conciliar automáticamente. Su valor frente a un fichero propietario es que la
información de remesa viene estructurada, así que la conciliación con las facturas puede ser
automática.

**05 → 7. ¿Qué aporta ISO 20022 frente a los mensajes MT?**

⏱️ Datos estructurados, más espacio, vocabulario común y extensibilidad.
🗣️ En MT, el ordenante es un bloque de cuatro líneas de texto libre: un sistema no puede saber cuál
es la ciudad, así que la comprobación de sanciones produce falsas alarmas y revisión manual. En ISO
20022, nombre, calle, ciudad y país son campos distintos.
🔬 Y la información de remesa cabe, así que el receptor puede conciliar automáticamente contra su
factura. El valor no es tecnológico: es que **los datos estructurados permiten automatizar lo que
antes requería una persona leyendo**.

**05 → 8. ¿Qué son el MTI y el bitmap en ISO 8583?**

⏱️ El MTI son cuatro dígitos que identifican el tipo de mensaje; el bitmap indica qué campos vienen
presentes.
🗣️ `0100` es petición de autorización, `0110` su respuesta, `0400` una anulación. El bitmap es un mapa
de bits donde cada posición dice si el campo correspondiente está o no en el mensaje.
🔬 El bitmap es lo que hace el formato compacto: no se transmiten los campos que no aplican, y no hay
separadores ni etiquetas. Es una optimización de los años ochenta que sigue teniendo sentido cuando
la latencia importa.

**05 → 9. ¿Qué diferencia hay entre autorización y liquidación de una tarjeta?**

⏱️ La autorización reserva el importe; la liquidación mueve el dinero, horas o días después.
🗣️ Son dos mensajes distintos en dos momentos distintos. La autorización baja el saldo disponible
creando una retención; la liquidación genera el asiento contable y baja el contable.
🔬 Y el importe puede **diferir**: una propina en un restaurante o un ajuste de hotel se liquidan por
un importe distinto al autorizado. Saber esto explica la mitad de las incidencias que reportan los
clientes, y demuestra dominio del negocio y no solo del formato.

**05 → 10. ¿Qué diferencia hay entre compensación y liquidación?**

⏱️ La compensación netea las obligaciones entre bancos; la liquidación es el momento en que el dinero
se mueve de verdad.
🗣️ Si el banco A debe 100 al B y el B debe 80 al A, la compensación determina que A debe 20. La
liquidación es cuando esos 20 se mueven, normalmente en cuentas del banco central.
🔬 Los pagos instantáneos cambian esto: liquidan operación por operación y en segundos, sin
compensación diferida. Eso es lo que obliga a que los sistemas estén disponibles 24/7 y lo que rompe
el modelo de ventana batch.

**05 → 11. ¿Por qué ISO 20022 no es un protocolo de transporte?**

⏱️ Porque define el contenido y la estructura del mensaje, no cómo viaja.
🗣️ El mismo `pacs.008` puede transmitirse por SWIFT, por la red local de pagos instantáneos, en un
fichero o por una API. La elección del canal es independiente y responde a otros criterios: latencia,
coste, disponibilidad.
🔬 Confundirlos lleva a suposiciones equivocadas, como pensar que adoptar ISO 20022 implica un
determinado tiempo de entrega. El estándar no dice nada sobre eso: lo dice el canal y la cadena de
bancos por la que pasa.

**05 → 12. ¿Qué es el truncamiento en la conversión ISO 20022 a MT?**

⏱️ La pérdida irreversible de información al convertir a un formato con campos más cortos.
🗣️ ISO 20022 permite más datos y más estructurados que MT. Al convertir hacia atrás, lo que no cabe
se pierde, y esa pérdida se propaga al resto de la cadena: los bancos siguientes ya no pueden
recuperarla.
🔬 Es un caso real y muy visible del problema de compatibilidad de contratos: la traducción no es
reversible, y durante los años de convivencia hay que acordar explícitamente qué se pierde y qué se
prioriza cuando no cabe todo.

**05 → 13. ¿Por qué la migración a ISO 20022 es tan cara?**

⏱️ Porque no es un cambio de formato: hay que migrar también los sistemas que consumen esos datos.
🗣️ El truncamiento obliga a convivencia con traducción en ambas direcciones durante años. Un pago
pasa por varios bancos, y el eslabón más antiguo marca el mínimo común. Y dentro del banco, el core,
el antiblanqueo, la conciliación y el reporting hablan MT: cambiar el mensaje sin cambiar el resto no
aporta nada.
🔬 Además hay fechas límite fijadas por reguladores y operadores de red, así que el plazo no se
negocia. La combinación de alcance grande, convivencia larga y fecha impuesta es lo que lo convierte
en uno de los proyectos más grandes del sector.

**05 → 14. ¿Cuál es el error estratégico de migrar el formato sin más?**

⏱️ Traducir ISO 20022 al modelo MT interno y tirar los datos estructurados: pagas el coste y no
cobras el retorno.
🗣️ El valor de ISO 20022 está en que los datos estructurados permiten automatizar el cribado de
sanciones, el antiblanqueo y la conciliación. Si al entrar se aplanan al modelo antiguo, todo eso
sigue siendo manual.
🔬 Es el mismo patrón que migrar a microservicios sin cambiar la organización: se paga la
complejidad y no se recibe la autonomía. La migración correcta incluye rediseñar los sistemas que
consumen, y eso es lo que multiplica el alcance y el presupuesto.

**05 → 15. ¿Qué relación tiene la autorización de tarjeta con el saldo disponible?**

⏱️ La autorización crea la retención que baja el disponible; la liquidación crea el asiento que baja
el contable.
🗣️ Entre ambas pueden pasar días, durante los cuales el cliente ve menos disponible sin que haya
ningún movimiento en su extracto. Eso genera consultas a soporte y no es un error.
🔬 Es el ejemplo más claro de por qué existen los tres saldos. Y la retención tiene caducidad: si la
liquidación no llega, expira y el disponible se recupera — que es la semántica de bloqueo con TTL de
una saga, en su versión bancaria de hace décadas.

**05 → 16. ¿Por qué los pagos instantáneos rompen el modelo de ventana batch?**

⏱️ Porque liquidan en segundos y 24/7: no hay horario de cierre que valga.
🗣️ El modelo clásico asume que hay unas horas en las que el sistema puede estar cerrado para procesar
el día. Un esquema instantáneo exige aceptar y liquidar operaciones a las tres de la madrugada, en
plena ventana.
🔬 Es el cambio estructural más relevante del sector y la razón arquitectónica detrás de muchas
modernizaciones actuales: obliga a separar lo que debe estar siempre disponible de lo que puede
cerrar, y normalmente eso significa una capa propia delante del core con su propio registro y
conciliación posterior.

**05 → 17. ¿Qué debe usarse como clave de idempotencia en un pago, y por qué?**

⏱️ El identificador de extremo a extremo que el propio estándar define, no uno inventado.
🗣️ El mensaje ya trae un identificador único acordado entre las partes. Usarlo evita tener que
correlacionar dos identificadores distintos cuando haya un descuadre, y permite que ambos lados hablen
del mismo caso.
🔬 Si inventas uno propio, ante una diferencia con la contraparte tendrás que casar por importe y
fecha —que produce falsos emparejamientos— o mantener una tabla de correspondencias que es un punto de
fallo más. Es un principio general: **cuando el dominio ya te da una clave, úsala**.

**05 → 18. ¿Por qué una devolución no es un rollback?**

⏱️ Porque genera su propio mensaje y su propio asiento: es una operación nueva, visible para todos.
🗣️ Un `pacs.004` de devolución no borra el pago original: lo contrarresta. El cliente ve las dos
operaciones en su extracto, y ambas tienen su fecha, su importe y su motivo.
🔬 Es exactamente la compensación de una saga y el contra-asiento contable. Y tiene la misma
propiedad: **puede fallar**. Una devolución rechazada necesita su propio tratamiento, y asumir que
siempre funciona es el error de diseño clásico.

**05 → 19. ¿Por qué un pago interbancario es una saga?**

⏱️ Porque es una secuencia de pasos locales en organizaciones distintas, con compensaciones
explícitas y estado consultable.
🗣️ Cada banco confirma su parte por su cuenta; no hay transacción que los cruce. Si algo falla, no se
deshace: se emite una devolución. Y hay una ventana de incertidumbre en la que el dinero ha salido de
un sitio y no ha llegado al otro.
🔬 Los elementos coinciden uno a uno: pasos con commit local, compensación como operación nueva, estado
consultable —los mensajes `pacs.002`—, y ventana visible para el usuario. La banca llevaba décadas
haciendo lo que los microservicios redescubrieron, y decirlo así sitúa muy bien la respuesta.

**05 → 20. ¿Cómo debe entrar el formato en tu sistema y hasta dónde debe llegar?**

⏱️ Entra por una capa anticorrupción y **no llega al dominio**.
🗣️ `pacs.008` e ISO 8583 se traducen a `Transferencia` y `Autorizacion` en el borde. Tu dominio no
conoce `DE39` ni `:50K:` ni la estructura XML del estándar.
🔬 Y la validación del esquema es una fase aparte, previa: un mensaje malformado se rechaza con el
código de error que el estándar define, antes de tocar la lógica. Tratarlo como una excepción de
negocio mezcla dos problemas y produce respuestas incorrectas hacia la contraparte.

**05 → 21. Diseña el servicio que recibe `pacs.008`, los procesa y responde con `pacs.002`, con volumen alto y requisito de trazabilidad.**

⏱️ Validación de esquema como fase previa, ACL que traduce a mi dominio, idempotencia por el
identificador de extremo a extremo, máquina de estados, y outbox para la respuesta.
🗣️ El diseño:

```text
1. RECEPCIÓN      → se persiste el mensaje crudo tal cual, con su identificador. Esto es
                    evidencia y es lo primero que se hace.
2. VALIDACIÓN     → esquema del estándar. Si falla, pacs.002 de rechazo con el código
                    correspondiente, sin tocar el dominio.
3. IDEMPOTENCIA   → INSERT del pago con el end-to-end ID como clave única. Si ya existe,
                    se responde el pacs.002 ya emitido. Sin reprocesar.
4. TRADUCCIÓN     → la ACL convierte a Transferencia. El dominio no ve XML.
5. PROCESO        → validaciones de negocio, cribado de sanciones, abono. Estado:
                    RECIBIDO → VALIDADO → ACEPTADO|RECHAZADO → ABONADO
6. RESPUESTA      → el pacs.002 se escribe en el OUTBOX dentro de la misma transacción
                    que el cambio de estado. Un relay lo envía.
7. AUDITORÍA      → cada transición registrada con identidad, marca de tiempo y motivo,
                    en almacén inmutable con retención regulatoria.
```

🔬 Los detalles que importan. **Persistir el mensaje crudo primero** es innegociable: ante una
reclamación o una auditoría, la evidencia es lo que llegó, no tu interpretación. **La idempotencia por
el identificador del estándar** evita el duplicado que la red interbancaria produce con más frecuencia
de la que parece. **El outbox para la respuesta** garantiza que el `pacs.002` sale aunque el
transporte falle: no responder es peor que responder tarde, porque la contraparte reintentará.
**El estado como máquina** permite responder "¿en qué punto está este pago?", que es la pregunta de
soporte. Y el cribado de sanciones puede ser asíncrono con estado `EN_REVISION`, lo que hay que
modelar porque no todos los pagos se resuelven en el momento.

**05 → 22. Un pago llega duplicado por la red interbancaria. Describe cómo lo detectas y qué tuvo que estar diseñado de antemano.**

⏱️ Lo detecta la restricción única sobre el identificador de extremo a extremo: el segundo `INSERT`
falla y se responde el `pacs.002` ya emitido.
🗣️ Si estaba diseñado, el duplicado ni siquiera es un incidente: es el comportamiento esperado. El
sistema reconoce que ya procesó ese identificador, no vuelve a abonar, y devuelve la misma respuesta
que dio la primera vez — que es lo correcto, porque la contraparte está esperando una respuesta, no un
error.
🔬 Lo que tuvo que estar diseñado: **la clave de idempotencia es la del estándar**, no una interna;
**es una restricción única en la base de datos**, no un `if` con consulta previa, que tendría ventana
de carrera con dos mensajes simultáneos; **el resultado del primer proceso se guarda**, para poder
devolver la misma respuesta; y **la comprobación es atómica con el efecto**, en la misma transacción.
Si nada de eso existía, la detección llega días después en la conciliación, y entonces hay que emitir
una devolución y explicar al cliente un abono duplicado y su anulación. La diferencia entre las dos
situaciones es una restricción de base de datos.

**05 → 23. Te piden migrar a ISO 20022 "cambiando el traductor de entrada". Argumenta por qué no basta y qué propones.**

⏱️ Porque si traduces a tu modelo MT interno, tiras los datos estructurados y pagas el coste sin el
retorno. El valor está en lo que hay detrás.
🗣️ El argumento: ISO 20022 aporta que el ordenante, el beneficiario y la remesa vengan en campos
separados. Si el traductor los aplana al modelo antiguo, el cribado de sanciones sigue leyendo texto
libre y produciendo falsas alarmas, el antiblanqueo sigue sin poder automatizar, y la conciliación de
los clientes corporativos sigue siendo manual. Habrás cumplido el requisito regulatorio y no habrás
mejorado nada.
🔬 Lo que propongo: **el modelo de dominio interno se amplía** para acomodar los datos estructurados
—`Ordenante` con nombre, dirección estructurada, identificación— aunque al principio algunos campos
vengan vacíos desde los mensajes MT antiguos. La ACL traduce en las dos direcciones, con reglas
explícitas sobre qué se pierde al ir hacia MT. Y se prioriza qué sistema aprovecha primero: el cribado
de sanciones suele ser el de mayor retorno, porque reduce revisión manual con un ahorro medible. La
migración del formato es la fase uno; la del aprovechamiento es donde está el valor, y hay que
presupuestarla desde el principio o no ocurrirá nunca. Reconocería también la restricción real: hay
una fecha regulatoria, así que la fase uno tiene prioridad — pero el plan tiene que incluir la dos.

---

# 06 — PSD2 y Open Banking

**06 → 1. ¿Qué son ASPSP, TPP y PSU?**

⏱️ El banco que mantiene la cuenta, el tercero autorizado que accede, y el cliente.
🗣️ ASPSP es *Account Servicing Payment Service Provider*: tú, si trabajas en el banco. TPP es *Third
Party Provider*, autorizado por un regulador. PSU es *Payment Service User*: el dueño de la cuenta y
del consentimiento.
🔬 El TPP se subdivide según lo que puede hacer: AISP lee, PISP ordena pagos, CBPII solo consulta si
hay fondos. El alcance del consentimiento y el riesgo son distintos en cada caso.

**06 → 2. ¿Qué diferencia hay entre AISP y PISP?**

⏱️ El AISP solo **lee** saldos y movimientos; el PISP **ordena** pagos en nombre del cliente.
🗣️ Son autorizaciones distintas del regulador y requieren consentimientos distintos del cliente. Un
agregador de finanzas personales es AISP; una pasarela que inicia pagos desde tu cuenta es PISP.
🔬 La distinción importa en el diseño porque el riesgo no es comparable: un AISP comprometido expone
datos; un PISP comprometido mueve dinero. Las comprobaciones, los límites y la auditoría se
dimensionan en consecuencia.

**06 → 3. ¿Qué es SCA?**

⏱️ *Strong Customer Authentication*: autenticación reforzada, obligatoria para acceder a la cuenta y
para ordenar pagos.
🗣️ Es doble factor con dos categorías distintas —algo que sabes, algo que tienes, algo que eres— y
con un requisito añadido por norma: el *dynamic linking*.
🔬 Tiene exenciones definidas: importes pequeños, beneficiarios de confianza, pagos recurrentes y
análisis de riesgo de la transacción. Cada exención aplicada se justifica y se mide, porque el
supervisor puede revisarlas.

**06 → 4. ¿Qué es el consentimiento en PSD2?**

⏱️ La autorización explícita del cliente para que un TPP acceda a sus datos o inicie pagos, con
alcance y caducidad.
🗣️ Define qué cuentas cubre, qué alcance —saldos, movimientos, detalle—, desde cuándo y hasta cuándo,
su estado, y quién lo otorgó y con qué autenticación. Es revocable en cualquier momento.
🔬 Es una **entidad de dominio de pleno derecho**, no un booleano en la cuenta. Tiene ciclo de vida,
auditoría y caducidad, y el supervisor pregunta por ella.

**06 → 5. ¿Qué estándares de implementación existen?**

⏱️ Berlin Group (NextGenPSD2), Open Banking UK y STET, entre otros.
🗣️ PSD2 dice **qué** hay que ofrecer, no **cómo**. Los estándares definen las APIs REST concretas:
recursos de cuentas, consentimientos y pagos, con ISO 20022 dentro para los datos de pago.
🔬 La consecuencia práctica es incómoda: un TPP que opera en varios países se integra con variantes
distintas del mismo concepto, y un banco que opera en varios expone varias. Se absorbe con una capa
anticorrupción por estándar.

**06 → 6. ¿Qué es el *dynamic linking* y qué impide?**

⏱️ Que el código de autenticación esté ligado al importe y al beneficiario concretos de esa
operación.
🗣️ Un código genérico podría reutilizarse para otra operación. Con *dynamic linking*, si el importe o
el destinatario cambian, el código deja de ser válido y hay que autenticar de nuevo.
🔬 Impide el ataque en el que un atacante intercepta una autenticación legítima y la aplica a una
transferencia distinta. Es el equivalente en pagos de atar un token a un contexto concreto, y es un
requisito normativo, no una buena práctica.

**06 → 7. ¿Qué acredita el certificado de un TPP?**

⏱️ Que está autorizado por un regulador nacional y para qué roles.
🗣️ Son certificados del sector —eIDAS: QWAC para el canal y QSEAL para la firma— que llevan la
identificación del TPP y sus roles autorizados. El banco debe verificar no solo la identidad, sino la
**autorización vigente**.
🔬 Y esa verificación no es estática: un TPP puede perder su autorización, así que hay que consultar
el registro correspondiente. Aceptar un certificado válido de un TPP cuya autorización fue revocada es
un incumplimiento.

**06 → 8. ¿Por qué el consentimiento no es un booleano?**

⏱️ Porque tiene alcance, caducidad, estado y auditoría: es una entidad con ciclo de vida.
🗣️ Un booleano no puede responder qué cuentas cubre, qué alcance tiene, cuándo caduca, si fue
revocado, quién lo otorgó ni con qué autenticación. Y todas esas preguntas las hace el supervisor.
🔬 Modelarlo como un campo en la cuenta es el error de diseño más caro de este capítulo: obliga a
reescribir el modelo cuando llega el primer requisito de alcance parcial o de auditoría, que llega
siempre.

**06 → 9. ¿Qué tres comprobaciones hace el banco en cada petición de un TPP?**

⏱️ Certificado, token y consentimiento.
🗣️ El certificado dice qué organización llama y para qué roles está autorizada. El token dice que hay
una sesión válida obtenida con el consentimiento del cliente. El consentimiento delimita qué cuentas y
qué alcance.
🔬 Las tres son necesarias y fallar cualquiera es rechazar. Es el modelo de identidades superpuestas
llevado a su forma más completa: identidad de organización, identidad de sesión, y alcance del
permiso.

**06 → 10. ¿Para qué sirve firmar el cuerpo de la petición?**

⏱️ Para no repudio: que el TPP no pueda negar haber ordenado ese pago.
🗣️ El canal ya va cifrado con mTLS, así que la firma no aporta confidencialidad. Su función es
probatoria: queda evidencia criptográfica de que ese TPP, con su clave, envió exactamente ese
contenido.
🔬 En caso de reclamación —un pago que el cliente dice no haber ordenado— la firma permite determinar
quién lo inició. Es el mismo principio que la pista de auditoría, aplicado a la frontera entre
organizaciones.

**06 → 11. ¿Qué exenciones de SCA existen?**

⏱️ Importes pequeños, beneficiarios de confianza, pagos recurrentes, y análisis de riesgo de la
transacción.
🗣️ Están definidas por norma con sus umbrales y condiciones. Existen para que la experiencia no sea
insufrible: pedir doble factor para pagar un café acabaría con el comercio electrónico.
🔬 Cada exención aplicada hay que **justificarla y medirla**: el supervisor puede revisar la tasa de
fraude asociada, y si supera ciertos umbrales, la entidad pierde el derecho a aplicar la exención de
análisis de riesgo. No es una decisión libre del banco.

**06 → 12. ¿Por qué PSD2 no define la API concreta?**

⏱️ Porque es una directiva: fija obligaciones y resultados, no implementaciones técnicas.
🗣️ Dice que el banco debe permitir el acceso de terceros autorizados con consentimiento del cliente y
con cierta calidad de servicio. Cómo se materializa en endpoints, recursos y formatos lo definen los
estándares de implementación.
🔬 El resultado es la fragmentación: Berlin Group en la Europa continental, Open Banking UK, STET en
Francia. Es un caso de libro de lo que pasa cuando una norma define el qué y deja el cómo al mercado.

**06 → 13. ¿Por qué la disponibilidad de la API es una obligación y no un objetivo interno?**

⏱️ Porque la norma exige disponibilidad y rendimiento comparables a los canales propios, y el banco
publica esas métricas.
🗣️ No es un SLO que se negocia internamente: es un compromiso medido y reportado. Una degradación
sostenida tiene consecuencias regulatorias, no solo comerciales.
🔬 Eso cambia la conversación de diseño: la API de Open Banking no puede ser un canal secundario
servido con lo que sobre. Necesita su propio dimensionamiento, su propia monitorización y su propio
plan de capacidad, al mismo nivel que la app del banco.

**06 → 14. ¿Qué es el mecanismo de contingencia y cuándo aplica?**

⏱️ Una vía alternativa que el banco debe ofrecer si su API dedicada falla de forma sostenida.
🗣️ La norma exige o bien mantener un mecanismo de respaldo, o bien obtener una exención demostrando
que la API dedicada cumple los requisitos de calidad de forma consistente.
🔬 Es un incentivo regulatorio directo: mantener el mecanismo de contingencia es caro, así que los
bancos invierten en que la API principal sea suficientemente buena para obtener la exención. Es un
caso poco común de normativa que empuja a mejorar la calidad técnica.

**06 → 15. ¿Por qué hay límites de consulta impuestos?**

⏱️ Para evitar que los TPP consuman capacidad indefinidamente consultando sin que el cliente esté
presente.
🗣️ Hay un máximo de consultas diarias sin intervención del cliente. Con la sesión activa del cliente
las consultas no cuentan igual; sin ella, están acotadas.
🔬 Condiciona el diseño en ambos lados: el TPP tiene que cachear y planificar cuándo consulta; y el
banco tiene que **contarlas y aplicarlas**, lo que significa llevar un contador por consentimiento y
por día, y devolver el error correspondiente al superarlo.

**06 → 16. ¿Cómo se evita que un TPP degrade la app del banco?**

⏱️ Con cuotas y límites de tasa por TPP, y aislamiento de recursos.
🗣️ Un TPP con un bucle o un despliegue defectuoso puede multiplicar su tráfico. Sin límites por
tercero, esa carga compite con la de los clientes del banco y todos lo notan.
🔬 Es el vecino ruidoso con nombre regulatorio. Las medidas: límite de tasa por TPP, cuotas diarias,
y aislamiento —instancias o grupos de capacidad separados para el tráfico de terceros—. Y medición por
TPP, porque sin ella no se sabe quién está causando el problema.

**06 → 17. ¿Qué relación tiene Open Banking con la propagación de identidad?**

⏱️ Es su caso de estudio más completo: tres capas superpuestas de identidad y alcance.
🗣️ El certificado identifica a la **organización** TPP, como mTLS entre servicios. El token OIDC
identifica la **sesión** autorizada por el cliente. Y el consentimiento delimita el **alcance** de lo
que esa sesión puede ver.
🔬 Es exactamente el modelo de dos identidades más acotamiento por token exchange, materializado en
una normativa. Quien entiende este capítulo entiende el de propagación de identidad, y al revés.

**06 → 18. ¿Cómo se absorbe la variedad de estándares sin multiplicar el sistema?**

⏱️ Con una capa anticorrupción por estándar y un modelo de dominio propio.
🗣️ El dominio tiene `Consentimiento`, `OrdenDePago` y `Cuenta` con su propia semántica. Cada estándar
—Berlin Group, Open Banking UK— entra por su adaptador, que traduce sus recursos y sus formatos a esos
conceptos.
🔬 Sin eso, cada estándar se propaga hacia dentro y el sistema se multiplica por el número de países.
Es la misma decisión que con el core, y el mismo criterio: **el formato externo no llega al dominio**.

**06 → 19. ¿Por qué la revocación del consentimiento no puede esperar a la caducidad del token?**

⏱️ Porque el cliente tiene derecho a revocar en cualquier momento y el efecto debe ser inmediato.
🗣️ Si el token vive una hora y el acceso sigue funcionando durante esa hora tras la revocación, el
banco está permitiendo acceso a datos sin consentimiento vigente. Eso es un incumplimiento, no un
detalle de implementación.
🔬 Por eso la comprobación del consentimiento se hace **en cada petición** contra su estado actual, no
contra lo que diga el token. El token autentica la sesión; el consentimiento autoriza el acceso, y su
estado se consulta.

**06 → 20. ¿Qué hay que registrar de cada acceso de un TPP?**

⏱️ Qué TPP, qué PSU, qué consentimiento, qué datos, cuándo y con qué resultado.
🗣️ Es lo que permite responder ante una reclamación del cliente —"¿quién ha estado viendo mis
movimientos?"— y ante una inspección del supervisor.
🔬 Con retención regulatoria, en almacén separado e inmutable, y sin registrar nunca el token ni los
datos personales completos. Y el acceso a ese registro también se audita, porque es información
sensible sobre la actividad del cliente.

**06 → 21. Diseña el modelo de consentimiento de un banco que expone Berlin Group: entidad, ciclo de vida, y cómo se comprueba en cada petición.**

⏱️ Entidad con alcance, caducidad y estado; máquina de estados explícita; y comprobación en cada
petición contra el estado actual, no contra el token.
🗣️ El diseño:

```text
Consentimiento
  id · tppId · psuId
  cuentas[]        → qué cuentas concretas cubre
  alcance          → SALDOS | MOVIMIENTOS | DETALLE (combinables)
  frecuenciaDiaria → límite de consultas sin cliente presente
  validoDesde / validoHasta
  estado           → RECIBIDO → VALIDO → EXPIRADO | REVOCADO | RECHAZADO
  otorgadoEn · metodoAutenticacion · evidencia SCA

En CADA petición del TPP:
  1. certificado  → ¿TPP autorizado, rol vigente en el registro?
  2. token        → ¿sesión válida, aud correcto, no caducado?
  3. consentimiento → ¿VALIDO ahora? ¿cubre ESTA cuenta? ¿cubre ESTE alcance?
                      ¿queda cuota diaria si el cliente no está presente?
  Cualquier fallo → rechazo con el código del estándar. Y se registra.
```

🔬 Los detalles que importan. **El estado se consulta en cada petición**, porque la revocación debe
ser inmediata y no puede esperar a que caduque el token. **El contador de frecuencia** es por
consentimiento y por día, y hay que distinguir si el cliente está presente en la sesión. **La
evidencia de SCA** —cómo se autenticó el cliente al otorgarlo— se conserva, porque es lo que se
presenta ante una reclamación. **El modelo es propio**: los recursos de Berlin Group entran por un
adaptador y se traducen a esta entidad, de modo que soportar otro estándar es otro adaptador y no otro
modelo. Y todo acceso se registra en el almacén de auditoría, que es donde se responde "¿quién ha
visto mis movimientos?".

**06 → 22. Un TPP está consumiendo el 60 % de la capacidad de tu API y los clientes del banco notan latencia. ¿Qué haces, inmediato y de fondo?**

⏱️ Inmediato: limitar la tasa a ese TPP y aislar el tráfico. De fondo: cuotas por TPP, aislamiento de
recursos y medición por tercero.
🗣️ Lo inmediato, en orden: confirmar con métricas por TPP que es él —si no las tienes, ese es el
primer hallazgo—; aplicarle un límite de tasa que proteja al resto, devolviendo el código de error
correspondiente del estándar, que es una respuesta legítima y no un rechazo arbitrario; y comunicarle
lo que está ocurriendo, porque suele ser un despliegue defectuoso o un bucle del que no se ha
enterado.
🔬 De fondo: **cuotas y límites por TPP** como política permanente, no como reacción; **aislamiento del
tráfico de terceros** respecto del de los clientes del banco, con capacidad separada, para que el
problema de uno no sea el de todos; **medición por TPP** de peticiones, latencia y errores, que es lo
que permite detectarlo en minutos y no cuando los clientes se quejan; y revisar si el patrón de
consulta del TPP indica que **no está usando bien el modelo de consentimiento** —consultando sin
cliente presente por encima de lo razonable—, en cuyo caso el límite de frecuencia normativo es la
herramienta. Declararía además que el aislamiento es un requisito regulatorio implícito: si el tráfico
de terceros degrada los canales propios, el banco tiene un problema de cumplimiento además de uno
técnico.

**06 → 23. Te piden exponer Open Banking sobre un core que cierra 4 horas cada noche. Diseña la solución y declara sus límites.**

⏱️ Proyección de lectura propia que sirve consultas 24/7, y órdenes de pago encoladas con estado
visible durante la ventana. El límite es que algunas operaciones no pueden completarse hasta la
apertura.
🗣️ El diseño:

```text
CONSULTAS (AISP)
  → proyección propia de saldos y movimientos, alimentada por eventos o CDC del core.
    Disponible 24/7, con marca de tiempo del último dato.
    Durante la ventana sigue sirviendo: los datos son de antes del cierre, y se dice.

PAGOS (PISP)
  → la orden se ACEPTA siempre: se persiste, se valida lo que se puede sin el core,
    y se responde con estado y un identificador.
    Durante la ventana: estado PENDIENTE_DE_EJECUCION. Se ejecuta al abrir.
    El estándar permite informar del estado con pacs.002 / el recurso de estado del pago.

COMPROBACIONES DE FONDOS (CBPII)
  → contra la proyección, con su marca de tiempo. Aquí el límite es real: un saldo de
    hace horas puede no reflejar operaciones de la noche.
```

🔬 Los límites que declararía explícitamente, porque ocultarlos sería el error. **La proyección tiene
una ventana de consistencia** y durante el cierre esa ventana crece hasta cuatro horas: hay que
comunicarlo en la marca de tiempo del recurso, que el estándar contempla. **Una comprobación de fondos
durante la ventana es menos fiable**, y eso puede afectar a la decisión del TPP — si el negocio no lo
acepta, la alternativa es mantener una capa de retenciones propia que registre las operaciones de la
noche, lo que es exactamente lo que exigen los pagos instantáneos. **Los pagos aceptados y no
ejecutados** necesitan estado consultable y una comunicación clara, porque el cliente puede pensar que
ya se hizo. Y añadiría el argumento de fondo: si el banco quiere ofrecer pagos instantáneos, el cierre
de cuatro horas deja de ser viable, y esta arquitectura —capa propia delante con registro y
conciliación posterior— es el primer paso hacia esa disponibilidad continua.

---

# 07 — BPM y arquitectura dirigida por workflow

**07 → 1. ¿Qué es BPMN?**

⏱️ Una notación estándar para modelar procesos de negocio, **ejecutable**: el diagrama es el proceso.
🗣️ Un motor —Camunda, Flowable— lo ejecuta directamente. No es documentación que se desincroniza del
código: es el artefacto que corre.
🔬 Sus elementos: tareas de servicio que invocan sistemas, tareas de usuario que esperan a personas,
puertas de decisión, eventos temporales, eventos de mensaje y eventos de compensación.

**07 → 2. ¿Qué es DMN?**

⏱️ El estándar complementario para modelar **decisiones**: tablas de decisión ejecutables.
🗣️ Separa el flujo de la política: el proceso dice "hay que decidir si va a comité"; la tabla DMN dice
con qué criterios. Cambiar un umbral no toca el proceso ni el código.
🔬 Es auditable —la tabla es el registro de qué política estaba vigente— y necesita gobierno: si
cualquiera puede cambiarla, un error aprueba préstamos que no debía. Es código, aunque parezca una
hoja de cálculo.

**07 → 3. Nombra cuatro elementos de un diagrama BPMN ejecutable.**

⏱️ Tarea de servicio, tarea de usuario, puerta de decisión y evento temporal.
🗣️ La de servicio invoca a un sistema. La de usuario espera a una persona, con bandeja y asignación.
La puerta decide el camino: exclusiva, paralela o inclusiva. El evento temporal dispara al cumplirse
un plazo.
🔬 Y dos más que importan en banca: el evento de mensaje, que espera a que llegue algo externo —una
firma, una respuesta—, y el evento de compensación, que es la saga expresada en notación.

**07 → 4. ¿Qué es una tarea de usuario?**

⏱️ Un paso del proceso que espera a que una persona actúe.
🗣️ El motor la pone en una bandeja, permite asignarla, reasignarla y escalarla si nadie la atiende en
un plazo. El proceso se queda esperando, sin consumir recursos, hasta que se completa.
🔬 Es mucho código que no escribes: bandeja, permisos por rol, reasignación, escalado por
vencimiento, y el estado de "quién tiene qué pendiente". Es una de las dos razones principales para
usar un motor.

**07 → 5. ¿Qué aporta un motor de procesos frente a código propio?**

⏱️ Plazos nativos, tareas humanas, estado persistido y consultable, y el proceso visible en un
diagrama.
🗣️ Un evento temporal sustituye a un `@Scheduled` con tabla de vencimientos. Las tareas humanas son
un concepto de primera clase. El estado permite responder "¿cuántas solicitudes llevan cinco días
paradas y en qué paso?". Y negocio puede ver y discutir el proceso sin traducción.
🔬 Lo que **no** aporta es una orquestación técnicamente mejor: para una saga de tres pasos y dos
segundos, el motor es desproporcionado. Su valor aparece con los plazos y las personas.

**07 → 6. ¿Qué diferencia hay entre una saga orquestada y un motor BPM?**

⏱️ La escala de tiempo y la presencia de personas: saga son segundos y es técnica; BPM son semanas y
es de negocio.
🗣️ En la saga el flujo está en el código del orquestador y el estado en una tabla que diseñas. En el
motor, el flujo es un diagrama ejecutable, el estado lo persiste él, los plazos son nativos y las
tareas humanas son un concepto.
🔬 Es el mismo patrón a dos escalas. Confundirlas lleva a usar la herramienta equivocada en las dos
direcciones: un motor para orquestar tres llamadas técnicas, o código ad hoc para un proceso de tres
semanas con comité.

**07 → 7. ¿Qué es un evento temporal y a qué sustituye?**

⏱️ Un disparador que ocurre al cumplirse un plazo. Sustituye a un proceso programado con tabla de
vencimientos.
🗣️ "Si el cliente no responde en 15 días, la oferta caduca" es un elemento del diagrama, no un `cron`
que recorre una tabla buscando vencidos. El motor lo gestiona y lo persiste.
🔬 Es donde aparecen los bugs en las implementaciones propias: el proceso de vencimientos que no se
ejecutó una noche, el que procesó dos veces, el que usó la fecha equivocada. El motor lo resuelve una
vez y para todos los procesos.

**07 → 8. ¿Por qué se dice que el diagrama BPMN "es" el proceso?**

⏱️ Porque el motor lo ejecuta directamente: no hay una traducción a código que pueda desincronizarse.
🗣️ En un diseño convencional, el diagrama documenta lo que el código hace, y a los seis meses ya no
coinciden. Con BPMN ejecutable, cambiar el proceso es cambiar el diagrama, y lo que se ve es lo que
corre.
🔬 Eso es lo que hace posible que negocio participe de verdad: pueden mirar el diagrama en una reunión
y discutirlo sabiendo que es el sistema, no una aproximación. Es el argumento principal del patrón.

**07 → 9. ¿Qué separa DMN del flujo?**

⏱️ La política de decisión: el proceso dice que hay que decidir, la tabla dice cómo.
🗣️ El umbral de importe que manda una solicitud a comité vive en una tabla, no en un `if` del
proceso. Cambiarlo de 10.000 a 15.000 no toca ni el diagrama ni el código.
🔬 Y da auditabilidad: queda registro de qué versión de la política estaba vigente en cada momento,
que en banca es exigible. El riesgo es el gobierno, y por eso la tabla necesita versionado, aprobación
y despliegue controlado.

**07 → 10. ¿Qué es un evento de compensación en BPMN?**

⏱️ Un mecanismo para deshacer un paso ya ejecutado cuando el proceso falla después.
🗣️ Se asocia a una tarea: si el proceso llega a un punto de fallo, el motor ejecuta las
compensaciones de los pasos completados, en orden inverso. Es la saga expresada en notación.
🔬 Y tiene las mismas propiedades: la compensación es una operación nueva, puede fallar, y hay pasos
que no se pueden compensar. El motor da el mecanismo; el diseño de qué compensa cada paso sigue siendo
tuyo.

**07 → 11. ¿Qué pregunta de negocio responde un motor que el código ad hoc no?**

⏱️ "¿Cuántas solicitudes llevan más de cinco días paradas, y en qué paso concreto?"
🗣️ Con código propio, el estado está repartido entre servicios y tablas, y esa pregunta requiere un
proyecto. Con motor, es una consulta sobre el estado que él ya persiste.
🔬 Y derivadas: cuánto tarda cada paso de media, dónde se acumulan las solicitudes, qué porcentaje
caduca por falta de respuesta del cliente. Ese tipo de visibilidad sobre el proceso es lo que negocio
pide y lo que más justifica el motor.

**07 → 12. ¿Qué riesgo introduce que negocio pueda cambiar una tabla DMN?**

⏱️ Que un cambio mal hecho apruebe operaciones que no debía, sin pasar por ningún control.
🗣️ La tabla parece una hoja de cálculo y es código: decide si se concede un préstamo. Un umbral mal
puesto o una fila con una condición solapada produce decisiones incorrectas de inmediato y a escala.
🔬 Por eso necesita el mismo gobierno que el código: versionado, revisión por alguien distinto de
quien la cambia —separación de deberes—, despliegue controlado y posibilidad de volver atrás. Lo que
DMN aporta es que el cambio sea **legible** por negocio, no que sea libre.

**07 → 13. ¿Cuándo un motor de procesos se convierte en un ESB?**

⏱️ Cuando deja de coordinar y empieza a decidir, transformar o calcular.
🗣️ Empieza orquestando. Luego alguien mete una transformación de datos, luego una validación de
negocio, luego una integración directa. A los dos años la lógica está en el motor, los servicios son
CRUD, y cualquier cambio pasa por el equipo que lo mantiene.
🔬 Es exactamente el ESB: inteligencia centralizada, cuello de botella de despliegue y un equipo que
bloquea a todos. La regla que lo evita: **el motor coordina, los servicios deciden**. Una tarea de
servicio invoca una operación de negocio completa, no hace tres llamadas y combina.

**07 → 14. ¿Cuál es la señal de alarma de esa degradación?**

⏱️ Que un cambio de negocio de un dominio concreto obligue a desplegar el motor.
🗣️ Si modificar cómo se calcula el riesgo requiere tocar el diagrama, la lógica de riesgo está en el
sitio equivocado: debería vivir en el servicio de riesgo, que el motor invoca.
🔬 Otras señales: tareas de servicio que hacen varias llamadas y combinan resultados; expresiones
largas en el diagrama; y el equipo del motor convertido en cuello de botella de todos los demás
equipos. Cualquiera de las tres indica que la inteligencia se está desplazando.

**07 → 15. ¿Qué regla evita que el motor absorba la lógica?**

⏱️ El motor coordina, los servicios deciden.
🗣️ Una tarea de servicio invoca **una** operación de negocio completa y recibe un resultado. No hace
tres llamadas, no transforma datos entre ellas, no aplica reglas. Si hace falta lógica entre dos
pasos, esa lógica pertenece a un servicio.
🔬 Es la misma regla que *smart endpoints, dumb pipes* aplicada al motor. Y se puede verificar
objetivamente: mirar el diagrama y comprobar que cada tarea de servicio corresponde a una operación
que el dominio reconocería por su nombre.

**07 → 16. ¿Cuándo NO usarías un motor de procesos?**

⏱️ Procesos cortos, sin tareas humanas, sin plazos, y donde negocio no necesita ver el flujo.
🗣️ Una saga técnica de tres pasos que dura dos segundos no necesita un motor: necesita un orquestador
con una tabla de estado. Añadir el motor introduce un componente crítico, una curva de aprendizaje y
un acoplamiento caro de revertir, sin resolver nada.
🔬 Tampoco lo usaría si el equipo no tiene experiencia y el caso no lo exige claramente, ni si no hay
quien lo opere. Un motor mal operado es un punto de fallo central para todos los procesos que
gestione.

**07 → 17. ¿Qué acoplamiento introduce el motor y por qué es caro de revertir?**

⏱️ El proceso queda expresado en el formato y la semántica de ese motor: migrar a otro es
reescribirlo.
🗣️ Aunque BPMN sea un estándar, las extensiones, los conectores, el modelo de despliegue y la API son
propios de cada producto. Y el estado de los procesos en vuelo vive en su almacén.
🔬 Es una decisión cara de revertir en el sentido clásico: afecta a todos los procesos que gestione,
y migrarlos exige reescribir y además resolver qué pasa con las instancias en curso. Por eso la
elección del motor merece análisis previo, no adopción por inercia.

**07 → 18. ¿Por qué "lo metemos en el motor para no desplegar" es una mala señal?**

⏱️ Porque el problema real es el pipeline, y meter lógica en el motor para esquivarlo la pone en el
sitio equivocado.
🗣️ Si desplegar un servicio es tan lento o tan burocrático que la gente busca alternativas, eso es lo
que hay que arreglar. Mover lógica al motor "porque ahí se cambia rápido" empieza exactamente la
degradación hacia el ESB.
🔬 Y crea un desequilibrio peligroso: la lógica que vive en el motor se cambia sin el control que
tiene el código —revisión, tests, pipeline—, así que acaba siendo la parte menos verificada del
sistema tomando las decisiones más importantes.

**07 → 19. ¿Qué construyes tú si no usas motor y el proceso tiene tareas humanas?**

⏱️ Bandeja, asignación, reasignación, escalado por vencimiento, y el estado de quién tiene qué
pendiente.
🗣️ Más: notificaciones, permisos por rol sobre las tareas, historial de quién hizo qué y cuándo, y
consultas agregadas sobre la carga de trabajo. Es una cantidad de código considerable y es
exactamente lo que el motor trae hecho.
🔬 Y hay que mantenerlo: cada requisito nuevo —delegación durante vacaciones, escalado a un
supervisor, reapertura de una tarea cerrada— se implementa desde cero. Ese es el cálculo real que
decide si el motor compensa.

**07 → 20. ¿Qué gobierno necesita una tabla DMN y por qué?**

⏱️ Versionado, revisión por alguien distinto, despliegue controlado y posibilidad de volver atrás.
🗣️ Porque es código con aspecto de hoja de cálculo: decide si se concede un préstamo o si una
operación va a comité. Un cambio incorrecto tiene efecto inmediato y a escala.
🔬 La separación de deberes aplica: quien propone el cambio no debería ser quien lo aprueba, que en
banca además es exigencia regulatoria. Y hay que conservar qué versión estaba vigente en cada momento,
porque ante una reclamación hay que poder demostrar con qué criterio se decidió entonces.

**07 → 21. Diseña la originación de un préstamo de tres semanas con comité, plazos y caducidad. Decide si usas motor y justifica.**

⏱️ Sí uso motor: hay tareas humanas, plazos, caducidades y negocio quiere ver el proceso. Los cuatro
criterios se cumplen.
🗣️ El diseño:

```text
BPMN
  Solicitud recibida
   → [servicio] validación documental        → si falta algo: tarea de usuario al CLIENTE
                                                 + evento temporal 15 días → CADUCA
   → [servicio] scoring (invoca al servicio de riesgo, que DECIDE)
   → [DMN] ¿va a comité?  (importe, scoring, antigüedad — tabla gobernada)
        no → aprobación automática
        sí → [tarea de usuario] comité, con bandeja y escalado a los 3 días
   → oferta al cliente + evento temporal 7 días → CADUCA
   → [evento de mensaje] firma digital recibida
   → [servicio] formalización → compensación asociada si falla algo posterior

Servicios (deciden): riesgo, documentos, formalización, notificaciones.
Motor (coordina): el flujo, los plazos, las tareas humanas y el estado.
```

🔬 Por qué el motor y no código. Los **plazos** —15 días, 7 días, escalado a 3— serían un proceso
programado con tabla de vencimientos, que es donde aparecen los bugs. Las **tareas humanas** del
comité traen bandeja, asignación y escalado hechos. El **estado consultable** responde "cuántas
solicitudes están esperando al comité y desde cuándo", que es la pregunta que negocio hace. Y el
**diagrama visible** permite discutir el proceso con negocio sin traducción. La regla que aplicaría
desde el primer día: el scoring lo **decide** el servicio de riesgo, el motor solo lo invoca; y el
umbral del comité vive en DMN con gobierno, no en el diagrama. Declararía el acoplamiento al motor
como coste asumido.

**07 → 22. Un motor lleva cuatro años en producción y ahora todo cambio de negocio pasa por el equipo que lo mantiene. Diagnostica y propón el camino.**

⏱️ La lógica migró al motor: se convirtió en un ESB. El equipo del motor es ahora el cuello de
botella de todos los demás.
🗣️ El diagnóstico se confirma mirando los diagramas: tareas de servicio que hacen varias llamadas y
combinan resultados, expresiones largas con reglas de negocio, transformaciones de datos entre pasos.
Y midiendo: qué porcentaje de los cambios de negocio del último año requirió tocar el motor.
🔬 El camino de corrección, que es gradual: **inventariar** qué lógica vive en el motor y a qué
dominio pertenece cada pieza. **Devolverla a los servicios** una por una, empezando por la que más
cambia —que es la que más bloquea—: una tarea de servicio que hacía tres llamadas y combinaba pasa a
invocar una operación nueva del servicio dueño, que la implementa y la prueba. **Verificar con el
mismo criterio**: cada tarea de servicio debe corresponder a una operación que el dominio reconozca
por su nombre. Y **medir el avance** por número de cambios de negocio que ya no requieren tocar el
motor. Sería honesto sobre el plazo: cuatro años de acumulación no se revierten en un trimestre, y lo
importante es detener la tendencia antes que revertir lo acumulado.

**07 → 23. Te piden usar el motor para orquestar una saga de tres pasos técnicos que dura dos segundos. ¿Qué respondes?**

⏱️ Que no: un orquestador con una tabla de estado es más simple, más rápido y más fácil de depurar.
Ninguno de los criterios que justifican un motor se cumple.
🗣️ Repaso los criterios en voz alta: no hay tareas humanas, no hay plazos ni caducidades, no dura días
sino segundos, y negocio no necesita ver ese flujo porque es técnico. Lo que el motor aporta —plazos,
bandejas, visibilidad de negocio— no aplica aquí, y lo que cuesta —latencia por cada transición, un
componente crítico más, acoplamiento a su formato— sí.
🔬 Lo que propongo: una clase orquestadora con una máquina de estados y una tabla, con idempotencia por
identificador de saga y TTL en las reservas. Son unas decenas de líneas, se depura con un `SELECT` y
no añade dependencias. Y reconocería el matiz: si el equipo **ya** tiene el motor operado y en uso
para otros procesos, el argumento cambia algo —el coste marginal es menor— pero seguiría sin
recomendarlo, porque una saga de dos segundos con persistencia de estado en el motor añade latencia
que no compensa. El disparador para reconsiderarlo: si aparecen plazos, reintentos con espera larga, o
intervención humana ante fallo.

---

# 08 — Idempotencia, conciliación y auditoría

**08 → 1. ¿Qué es la partida doble?**

⏱️ Que todo movimiento genera al menos dos asientos —un cargo y un abono— por el mismo importe.
🗣️ La consecuencia es una invariante verificable: la suma de todos los cargos es igual a la suma de
todos los abonos, siempre. Si no cuadra, hay un error y el sistema puede detectarlo solo.
🔬 Lo poderoso es que se comprueba **a posteriori**, sobre el resultado: no depende de que ninguna
transacción concreta fuera correcta. Es una fitness function con seiscientos años de antigüedad.

**08 → 2. ¿Qué es un contra-asiento?**

⏱️ Un asiento que anula a otro, con signo contrario y referencia al original.
🗣️ Es cómo se corrige un error: no se borra ni se modifica el apunte erróneo, se emite el contrario y
después el correcto. Los tres quedan visibles, incluido en el extracto del cliente.
🔬 Es exactamente la compensación de una saga y la corrección en un log inmutable de event sourcing.
El principio común: la evidencia no se edita, se complementa.

**08 → 3. ¿Qué tipos de conciliación existen?**

⏱️ Interna, externa, de posición y temporal.
🗣️ Interna: tu sistema contra el core. Externa: tu banco contra otra entidad, la red de tarjetas o un
proveedor. De posición: el saldo derivado de los movimientos contra el que dice el core. Temporal: el
cierre de hoy contra el de ayer más los movimientos del día.
🔬 Las cuatro responden preguntas distintas y detectan fallos distintos. Un sistema que solo hace la
interna no detecta que su propio saldo derivado se desvió, que es un error de cálculo y no de
integración.

**08 → 4. ¿Qué debe contener una pista de auditoría?**

⏱️ Qué operación, quién la ordenó, a través de qué canal, cuándo, con qué autorización y con qué
resultado.
🗣️ La identidad es la del **usuario** —`sub`—, no la del servicio, con el actor —`act`— para saber por
dónde pasó. Y la autorización incluye qué política permitió la decisión y si hubo un segundo aprobador.
🔬 Lo que **nunca** se registra: el token completo, que es una credencial. Se registra su identificador
(`jti`) y los claims relevantes. Un token en un log es una credencial replicada en el sistema de
observabilidad.

**08 → 5. ¿De dónde sale la clave de idempotencia en un pago interbancario?**

⏱️ Del propio mensaje: el identificador de extremo a extremo que define el estándar.
🗣️ No se inventa una clave interna. Usar la del estándar permite que ambos lados hablen del mismo caso
cuando haya un descuadre, sin tener que correlacionar dos identificadores distintos.
🔬 Es un principio general del bloque: **cuando el dominio ya te da una clave, úsala**. En tarjetas es
el identificador de la transacción, que viaja en la autorización y en la liquidación; en un fichero de
remesas, la remesa más el número de orden.

**08 → 6. ¿Por qué el saldo debe ser derivado y no un contador mutable?**

⏱️ Porque mutarlo pierde la auditoría, la idempotencia y la capacidad de conciliar.
🗣️ Con movimientos inmutables, el saldo se calcula sumándolos o se mantiene actualizado en la misma
transacción que la inserción. Reintentar inserta el mismo identificador, viola la restricción única y
no hace nada.
🔬 Con un contador mutable, reintentar suma otra vez, no hay rastro de cómo se llegó al valor actual, y
ante un descuadre no hay forma de saber qué movimiento falta. Las tres propiedades se pierden juntas.

**08 → 7. ¿Qué invariante permite detectar errores en la partida doble?**

⏱️ Que la suma de cargos es igual a la suma de abonos.
🗣️ Se puede comprobar sobre cualquier conjunto: un día, una cuenta, todo el libro. Si no cuadra, hay
un asiento incompleto o incorrecto, y se sabe sin necesidad de revisar cada operación.
🔬 Es verificable **a posteriori** y de forma automática, que es lo que la hace útil: no previene el
error, lo detecta. Y esa es exactamente la función de la conciliación en un sistema distribuido.

**08 → 8. ¿Por qué se casa por clave de negocio y no por importe y fecha?**

⏱️ Porque importe y fecha producen falsos emparejamientos: dos operaciones idénticas del mismo día se
confunden.
🗣️ Con veinte transferencias de 100 euros el mismo día, casar por importe y fecha empareja
arbitrariamente, y si falta una, el resultado señala la equivocada.
🔬 La clave de negocio es única por operación y la comparten ambos sistemas, así que el
emparejamiento es determinista. Cuando no existe una clave común, construirla es parte del diseño de
la integración, no un problema de la conciliación.

**08 → 9. ¿Qué tres propiedades distinguen la pista de auditoría de un log?**

⏱️ Inmutabilidad, retención regulatoria, y acceso restringido que a su vez se audita.
🗣️ Solo-anexado, sin actualización ni borrado, idealmente con encadenamiento o firma que permita
detectar manipulación. Años de retención, no días. Y quién consultó la pista también queda
registrado.
🔬 Por eso va a un almacén separado: mezclarla con los logs técnicos produce o pérdida de evidencia
con la rotación normal, o el coste absurdo de conservar años de logs de depuración.

**08 → 10. ¿Cómo se implementa la idempotencia: con un `if` o con una restricción?**

⏱️ Con una restricción única en la base de datos, no con una consulta previa.
🗣️ `INSERT` del movimiento con la clave de negocio como índice único. Reintentar viola la restricción y
no hace nada. Sin consulta previa, sin ventana entre comprobar y escribir.
🔬 Un `if` que consulta y luego inserta tiene una condición de carrera: dos mensajes simultáneos
comprueban a la vez, ambos no encuentran nada, y ambos insertan. La restricción lo resuelve porque la
comprobación y la escritura son la misma operación atómica.

**08 → 11. ¿Qué relación tiene la partida doble con el event sourcing?**

⏱️ Es el mismo modelo: hechos inmutables como fuente de verdad y estado derivado.
🗣️ El asiento es el evento; el saldo es la proyección. La corrección es un evento nuevo, no una
edición. Y la historia completa permite responder preguntas retroactivas.
🔬 Por eso la banca es el dominio donde event sourcing **se descubre en vez de imponerse**: el negocio
ya piensa así. Y explica por qué en otros dominios el patrón cuesta tanto: se está imponiendo un
modelo que el negocio no usa.

**08 → 12. ¿Por qué el corte temporal es crítico en una conciliación?**

⏱️ Porque si los dos conjuntos no cubren exactamente el mismo periodo, todas las diferencias son
ruido.
🗣️ Husos horarios distintos, fecha contable frente a fecha de operación, o un sistema que corta a las
23:59 y otro a las 00:00 producen listas de diferencias que no son diferencias.
🔬 Es el origen del 80 % de los falsos positivos. El corte se define **primero**, explícitamente, con
su campo de fecha y su huso, y se documenta. Ajustarlo después para que cuadre es esconder el
descuadre.

**08 → 13. ¿Qué haces ante un timeout sin respuesta del core?**

⏱️ Consultar el estado por la clave de negocio; si no se puede, dejarlo en estado ambiguo y que lo
resuelva la conciliación. Nunca reintentar a ciegas.
🗣️ El timeout no dice que la operación no ocurrió: dice que no lo sabes. Reintentar una orden que sí
se ejecutó produce un segundo asiento, que en banca es dinero movido dos veces.
🔬 Y si el core es idempotente por la clave de negocio, reintentar **sí** es seguro — pero eso hay que
haberlo verificado, no suponerlo. La regla: reintentar solo si has comprobado que el receptor
deduplica; en cualquier otro caso, consultar o conciliar.

**08 → 14. ¿Qué métricas tiene un proceso de conciliación?**

⏱️ Número de descuadres, tiempo hasta detectarlos, porcentaje resuelto automáticamente, y antigüedad
del más viejo sin resolver.
🗣️ Sin ellas no se sabe si el sistema está mejorando o empeorando. Un aumento sostenido de descuadres
indica un problema de integración nuevo; un porcentaje de resolución automática que baja indica que
aparecieron casos que las reglas no cubren.
🔬 Y la antigüedad del más viejo es la que escala: en banca hay plazos regulatorios para resolver
diferencias, así que un descuadre que supera el plazo deja de ser un problema técnico y pasa a ser un
incumplimiento.

**08 → 15. ¿Por qué no se modifica un movimiento erróneo?**

⏱️ Porque el libro es la evidencia contable, y la evidencia no se edita.
🗣️ Modificarlo destruiría el registro de qué se hizo originalmente, que es justo lo que un auditor
comprueba. Y rompería cualquier saldo, informe o conciliación ya calculado sobre él.
🔬 La corrección es un contra-asiento que lo anula, con referencia y motivo, más el asiento correcto.
Los tres quedan visibles, y el cliente los ve en su extracto — lo que es una decisión de comunicación
que hay que tomar, no un efecto colateral.

**08 → 16. ¿Cómo se hace una corrección masiva de 40.000 cuentas?**

⏱️ Como un proceso batch con su propio cuadre, su aprobación y su registro. No con un `UPDATE`.
🗣️ Se identifica el conjunto afectado con un criterio verificable, se calculan los contra-asientos, se
ejecuta como un `Job` con fecha de proceso, y un `Step` de cuadre comprueba que el total corregido
coincide con lo estimado.
🔬 Y con separación de deberes: quien detecta el error no autoriza la corrección. Queda registrado
quién la aprobó, sobre qué conjunto y con qué resultado. Un `UPDATE` ejecutado por soporte no deja
nada de eso y es exactamente lo que un auditor busca.

**08 → 17. ¿Por qué la separación de deberes aplica a las correcciones?**

⏱️ Porque quien puede provocar un error y corregirlo sin control puede ocultar un fraude.
🗣️ Es el mismo principio que impide que una sola persona cree un beneficiario y le transfiera dinero.
Una corrección masiva mueve importes, así que necesita un segundo par de ojos y un registro de quién
aprobó.
🔬 En banca es exigencia regulatoria, no buena práctica, y condiciona el diseño: tiene que existir un
estado de "corrección propuesta, pendiente de aprobación" que no se pueda saltar, y el aprobador tiene
que ser distinto del proponente por construcción, no por convención.

**08 → 18. ¿Por qué "la conciliación es cosa de operaciones" es un error de diseño?**

⏱️ Porque sin ella el sistema no tiene forma de detectar sus propios fallos, y eso es una decisión de
arquitectura.
🗣️ En un sistema distribuido con integraciones heredadas, los descuadres van a ocurrir: timeouts
ambiguos, mensajes perdidos, procesos que se cayeron a la mitad. La conciliación es el mecanismo que
los encuentra, y tiene que estar diseñado, no improvisado por el equipo de operaciones.
🔬 Y condiciona el modelo: para poder conciliar hacen falta claves de negocio comunes, cortes
temporales definidos, y registro de lo ordenado —que es lo que el outbox proporciona—. Si no se diseñó
para conciliar, conciliar después es muy caro o imposible.

**08 → 19. ¿Qué se registra y qué NUNCA se registra en la auditoría?**

⏱️ Se registra identidad, operación, canal, momento, autorización y resultado. Nunca el token ni datos
personales innecesarios.
🗣️ El `sub` del usuario, el `act` del servicio, el identificador del token (`jti`), qué política
permitió la decisión y qué pasó. Con eso se reconstruye todo sin exponer credenciales.
🔬 Un token completo en el registro es una credencial válida replicada en el sistema de auditoría, que
tiene retención de años y acceso más amplio. Y los datos personales se minimizan: la auditoría
demuestra **qué se hizo**, no necesita duplicar el contenido.

**08 → 20. ¿Por qué la conciliación es el equivalente bancario de una fitness function?**

⏱️ Porque es una verificación automática y periódica de una invariante que el sistema debería cumplir
y que nadie puede garantizar por construcción.
🗣️ Igual que una regla de ArchUnit comprueba que el dominio no importa Spring, la conciliación
comprueba que lo que ordené y lo que se aplicó coinciden. Ninguna previene el fallo; ambas lo detectan
pronto y de forma automática.
🔬 Y comparten el principio general del corpus: **cuando el modo de fallo es silencioso, la
verificación tiene que ser automática**. Un descuadre no lanza excepciones, no aparece en las métricas
de error y no se lo reporta ningún usuario. Solo lo encuentra algo que lo busque activamente.

**08 → 21. Diseña la conciliación diaria entre tu sistema de pagos y el core, con 14.000 operaciones al día y plazo regulatorio de resolución.**

⏱️ Proceso batch diario con corte temporal explícito, casado por clave de negocio, clasificación
automática de diferencias, y escalado por antigüedad.
🗣️ El diseño:

```text
CORTE      → definido primero: fecha CONTABLE, huso declarado, de 00:00 a 23:59:59.
             Ambos conjuntos se extraen con el mismo criterio. Documentado.
FUENTES    → mi tabla de órdenes (incluida la de outbox, que dice qué ordené)
             y el extracto del core para ese día.
CASADO     → por el identificador de extremo a extremo. Nunca por importe y fecha.
CLASIFICA  → solo en el mío  → ordené y no se aplicó, o el corte difiere
             solo en el suyo → se aplicó algo que no ordené, o llegó por otro canal
             en ambos, distinto → importe, divisa o fecha valor no coinciden
RESUELVE   → automático donde la regla es clara (p. ej. operación en estado SIN_RESPUESTA
             que aparece en el core → se marca como ejecutada)
             manual donde no, con bandeja y asignación
ESCALA     → antigüedad del descuadre más viejo sin resolver. Alerta antes del plazo
             regulatorio, no al cumplirse.
MÉTRICAS   → descuadres/día, tiempo de detección, % automático, antigüedad máxima.
```

🔬 Lo que hace que funcione. **El corte primero y documentado** elimina el 80 % de los falsos
positivos. **La tabla de outbox como fuente** responde "¿lo ordené yo?", que es la primera pregunta
ante cualquier diferencia. **La clasificación automática** es lo que hace viable revisar a mano solo
lo que de verdad lo necesita: con 14.000 operaciones y una tasa razonable, los casos manuales deben ser
unidades. **El escalado por antigüedad y no por cantidad**, porque el plazo regulatorio es por caso.
Y añadiría una conciliación **de posición** semanal: el saldo derivado de mis movimientos contra el
del core, que detecta errores de cálculo que la conciliación de operaciones no ve.

**08 → 22. Un bug aplicó una comisión dos veces a 40.000 clientes durante tres días. Describe el procedimiento completo de corrección.**

⏱️ Contener, cuantificar, corregir el código, emitir contra-asientos con aprobación, comunicar a los
clientes, y registrar todo.
🗣️ El procedimiento:

```text
1. CONTENER: desactivar el proceso o corregir el bug antes de nada. Si sigue ejecutándose,
   el alcance crece mientras trabajas.
2. CUANTIFICAR: identificar con un criterio verificable las 40.000 cuentas y el importe
   exacto duplicado en cada una. Esta cifra es la que va a dirección y a cumplimiento.
3. DECIDIR con negocio y cumplimiento: se devuelve el importe duplicado, ¿y los intereses
   o gastos que ese cargo haya podido provocar? (un descubierto, una comisión de impago)
4. CORREGIR: proceso batch que emite un CONTRA-ASIENTO por cada comisión duplicada,
   con referencia al original y motivo. Nunca UPDATE sobre el apunte.
5. APROBAR: separación de deberes. Quien detectó no autoriza. Queda registrado.
6. CUADRAR: Step final que verifica que el total corregido coincide con lo estimado en (2).
7. COMUNICAR: los clientes verán el cargo, su anulación y —si procede— la compensación.
   Hay que explicarlo antes de que llamen.
8. REGISTRAR en la pista de auditoría: alcance, decisión, aprobación y resultado.
```

🔬 Los puntos que marcan la diferencia. **El paso 3 no es técnico y es el que más impacto tiene**: un
cargo duplicado puede haber provocado un descubierto con sus propios gastos, y devolver solo la
comisión deja al cliente peor de lo que estaba. **El paso 6** es lo que evita corregir mal: sin cuadre,
una corrección masiva puede dejar la mitad hecha. Y **el paso 7** es lo que convierte un incidente en
una gestión: el cliente que recibe una explicación antes de ver el movimiento raro no llama. Añadiría
un paso previo omitido a menudo: comprobar si el bug afectó a **otros** periodos o a otras comisiones,
porque el alcance declarado suele ser el detectado, no el real.

**08 → 23. Tu sistema ordenó 14.238 transferencias y el core registró 14.237. Describe cómo investigas y qué tuvo que estar diseñado de antemano.**

⏱️ Casar por clave de negocio para identificar **cuál** falta, y verificar primero que el corte
temporal es el mismo. Solo entonces es un descuadre real.
🗣️ La investigación:

```text
1. ¿El corte es idéntico? Misma fecha contable, mismo huso, mismos límites.
   Una operación de las 23:59:58 puede estar en un conjunto y no en el otro.
   Esto explica la mayoría de las diferencias de una unidad.
2. Casar por identificador de extremo a extremo → qué operación concreta falta.
3. Buscar esa operación en MI sistema: ¿en qué estado está?
     ENVIADA sin respuesta → ambigua: se ordenó y no sabemos si se aplicó
     RESPONDIDA ok         → el core dijo que sí y no aparece: descuadre real, grave
     en outbox sin publicar→ nunca salió: el relay falló
4. Consultar el estado en el core por la clave de negocio, si se puede.
5. Según el resultado: reordenar (si no se aplicó, y es idempotente) o marcar como
   resuelta (si sí se aplicó y era un problema de corte o de extracto).
6. Registrar la resolución en auditoría.
```

🔬 Lo que tuvo que estar diseñado de antemano, y son cuatro cosas: **la clave de negocio común**, sin
la cual el paso 2 es imposible y habría que casar por importe y fecha con falsos emparejamientos; **el
corte temporal definido y documentado**, sin el cual el paso 1 no se puede verificar; **el estado
explícito de cada orden**, incluido `SIN_RESPUESTA`, que es lo que distingue "no se aplicó" de "no
sé"; y **la tabla de outbox**, que responde si la orden llegó a salir. Si nada de eso existe, la
investigación es forense y puede no llegar a una conclusión. Y añadiría lo importante: **una
diferencia de una unidad sobre 14.238 no es tranquilizadora** — puede ser un caso de corte, o puede ser
una transferencia que un cliente reclamará. El procedimiento es el mismo en ambos casos.

---

# 09 — Simulación: escenarios de diseño

> Las preguntas `S#` del bloque 2 de [`09`](09-simulacion-de-entrevista.md) se responden con las
> entradas de los capítulos correspondientes, que están arriba. Aquí van los seis escenarios.

## E1 — La app móvil contra un core que cierra

**Respuesta corta:** proyección de saldos propia que sirve el 100 % de las consultas, saldo disponible
calculado por mí, y modo degradado explícito durante la ventana. El core solo se consulta al operar.

El diseño está en [01 → 21](#01--core-bancario-y-legado). Lo que añade este escenario son los números
y la conversación de negocio.

**Los números.** 4.000 consultas por segundo en pico contra un core con p99 de 800 ms es
directamente inviable: la latencia sola arruina la experiencia. Y con coste por transacción, esas
consultas son decenas de millones al mes. Los dos argumentos —experiencia y coste— apuntan a lo mismo.

**Lo que resuelve la proyección**, de una vez: latencia de milisegundos, cero coste por transacción,
disponibilidad durante las cuatro horas de cierre, y desacoplamiento de la disponibilidad del core el
resto del día.

**El saldo disponible lo calculo yo**, y esto es lo que más se olvida: contable de la proyección menos
las retenciones vigentes, que genero yo al autorizar. Eso significa que las operaciones con tarjeta del
propio banco se reflejan al instante aunque el core esté cerrado.

**El modo degradado, acordado con negocio operación por operación:**

```text
Consultar saldo/movimientos → SIRVE, con la marca de tiempo visible. "Actualizado a las 22:58."
Ordenar transferencia       → ACEPTA y encola. Estado "pendiente de ejecución", se ejecuta al abrir.
Operar con tarjeta          → funciona: la autorización no pasa por el core, genera retención.
Contratar un producto       → RECHAZA explícitamente con motivo y hora de reapertura.
```

**Lo que declaro como límite.** La proyección tiene una ventana de consistencia medida y alertada, que
durante el cierre crece hasta cuatro horas. La marca de tiempo visible es lo que hace honesta esa
consistencia: el usuario ve cuándo se actualizó, no un número que podría ser viejo sin avisar. Y
cualquier operación que comprometa dinero se valida contra el **contable**, nunca contra la proyección.

## E2 — La transferencia que no se sabe si se hizo

**Respuesta corta:** el estado `SIN_RESPUESTA` tenía que existir por diseño. Para las 340: consultar el
estado en el core por clave de negocio, y lo que no se pueda, a conciliación. Nunca reintentar.

**El diseño que lo convierte en caso previsto** está en
[02 → 21](#02--mq-e-integración-asíncrona-clásica): orden como entidad con máquina de estados, outbox,
clave de negocio, y un proceso que marca las vencidas. Lo que añade este escenario es la recuperación.

**Cómo resuelvo las 340:**

```text
1. CLASIFICAR por lo que sé de cada una:
     en outbox sin publicar     → nunca salió. Se pueden reenviar con seguridad.
     ENVIADA sin respuesta      → ambiguas. Son las que importan.
     RESPONDIDA                 → no están en el grupo de las 340.
2. CONSULTAR el core por la clave de negocio de cada ambigua.
     Si el core permite consulta de estado: se resuelve una a una, automáticamente.
     Si no: conciliación contra el extracto del día.
3. RESOLVER:
     se aplicó      → marcar RESPONDIDA ok. No hacer nada más.
     no se aplicó   → reordenar. Es seguro porque la clave de negocio es la misma
                      y el core deduplicaría igualmente.
     no determinable→ escalar a revisión manual con toda la evidencia.
4. COMUNICAR a los clientes afectados durante el proceso, no después.
```

**Lo que NO hago:** reintentar las 340 a ciegas. Si el 60 % se ejecutó, eso son 200 transferencias
duplicadas y 200 reclamaciones.

**Lo que habría evitado el incidente como incidente.** Con el estado `SIN_RESPUESTA` modelado y un
proceso que lo detecta, las 340 habrían aparecido en un panel a los cinco minutos con su resolución
en marcha, en vez de descubrirse al día siguiente. El incidente de red seguiría ocurriendo; lo que
cambia es que deja de ser una sorpresa.

## E3 — El cierre que no cabe

**Respuesta corta:** mido antes de tocar nada. Casi seguro el tiempo está en una consulta por elemento
o en la escritura, y arreglarlo da más que paralelizar.

**El orden de actuación:**

```text
1. MEDIR por fase: lectura, procesamiento, escritura, esperas de conexión y de bloqueo.
   El JobRepository da además el tiempo por registro histórico: si es constante, el problema
   es volumen; si subió, el problema es el proceso.
2. Si hay una consulta por elemento → lectura por lote. Suele dar más que cualquier otra medida.
3. Ajustar el tamaño de chunk, midiendo. Ni el grande ni el pequeño son correctos por defecto.
4. PARTICIONAR por rango de cuenta. Conserva el reinicio por partición y evita los problemas
   de concurrencia del lector que tiene el multi-hilo.
5. Si el cuello es la base de datos, paralelizar NO ayuda: añade contención.
   Ahí la salida es reducir el trabajo, no repartirlo.
```

**Lo que propondría a negocio si nada de eso basta**, porque es una conversación que hay que tener:
mover parte del cálculo **fuera de la ventana**. Buena parte del devengo depende de datos que no
cambian durante el día, así que puede precalcularse. Eso reduce lo que tiene que caber en las cuatro
horas sin cambiar el resultado.

**Lo que no negociaría.** El `Step` de cuadre se mantiene aunque cueste tiempo: un cierre rápido y
mal es peor que uno lento. Y el reinicio por partición tampoco: si el proceso tarda tres horas, tiene
que poder reanudarse, o un fallo a las dos horas y media no cabe en la ventana restante.

**Cómo mediría el éxito.** No en "es más rápido", sino en margen sobre la hora límite y en proyección:
con el crecimiento previsto, cuántos meses de margen compra cada medida. Eso convierte la optimización
en una decisión con horizonte, no en un parche.

## E4 — Open Banking sobre un legado

**Respuesta corta:** capa propia delante del core con proyección de lectura, consentimiento como
entidad, cuotas por TPP, y modo degradado declarado. La disponibilidad es una obligación, así que la
proyección no es una optimización.

El diseño de consentimiento y de degradación está en
[06 → 21](#06--psd2-y-open-banking) y [06 → 23](#06--psd2-y-open-banking). Lo que añade este escenario
es juntarlo con las restricciones del core.

**Por qué la proyección es obligatoria aquí y no opcional.** La norma exige disponibilidad y
rendimiento comparables a los canales propios, y esas métricas se publican. Un core con p99 de 800 ms
que cierra cuatro horas no puede sostener esa obligación. La proyección no es una mejora: es lo que
hace viable el cumplimiento.

**El diseño:**

```text
Capa Open Banking (propia, 24/7)
  ├ Consentimientos  → entidad con alcance, caducidad, estado, contador de frecuencia
  ├ Proyección       → saldos y movimientos, alimentada por eventos o CDC del core,
  │                    con marca de tiempo del último dato
  ├ Órdenes de pago  → aceptadas siempre, con estado; ejecutadas contra el core al abrir
  ├ Cuotas por TPP   → límite de tasa, cuota diaria, aislamiento de capacidad
  └ Auditoría        → qué TPP, qué PSU, qué consentimiento, qué datos, cuándo
```

**Las tres comprobaciones en cada petición**, sin excepción: certificado del TPP y su autorización
vigente, token de sesión, y consentimiento válido **consultado ahora** —no lo que diga el token—
para esa cuenta y ese alcance.

**Los límites que declaro.** Durante la ventana, los datos son de antes del cierre y la marca de
tiempo lo dice. Una comprobación de fondos en esa franja es menos fiable, y si el negocio no lo
acepta, hace falta una capa de retenciones propia que registre las operaciones de la noche. Los pagos
aceptados y no ejecutados necesitan estado consultable y comunicación clara.

**El argumento que llevaría a dirección.** Esta arquitectura no solo cumple PSD2: es el primer paso
hacia la disponibilidad continua que los pagos instantáneos van a exigir de todos modos. Se está
pagando una obligación regulatoria y comprando capacidad futura.

## E5 — El descuadre

**Respuesta corta:** primero verifico el corte temporal —la mayoría de los descuadres pequeños son
eso—, luego caso por clave de negocio para identificar cuáles, y solo entonces corrijo con
contra-asientos.

**La investigación:**

```text
1. CORTE. ¿Ambos extractos cubren exactamente el mismo periodo, con el mismo campo de fecha
   y el mismo huso? Una diferencia de 3 a 11 operaciones diarias es compatible con
   operaciones de frontera. Esto se verifica ANTES de tocar nada.
2. CASAR por clave de negocio → qué operaciones concretas difieren cada día.
3. CLASIFICAR cada una: ¿está en mi outbox? ¿en qué estado quedó? ¿aparece en el core?
4. BUSCAR el patrón: ¿todas a la misma hora? ¿del mismo tipo? ¿del mismo canal?
   Tres días seguidos con magnitud similar sugiere causa sistemática, no incidente puntual.
5. CAUSA RAÍZ. Las candidatas: corte mal definido, un relay que falló en una franja,
   un consumidor que saltó mensajes, un reintento que duplicó, o el core rechazando
   silenciosamente un tipo de operación.
```

**Lo más importante y lo que declararía primero:** "nadie sabe desde cuándo pasa" significa que **no
había conciliación automática**. Ese es el hallazgo principal, por encima del descuadre concreto: el
sistema no tenía forma de detectar sus propios fallos.

**La corrección**, una vez identificadas: contra-asientos para lo aplicado indebidamente y asientos
para lo que faltó, como proceso batch con cuadre, con aprobación de alguien distinto de quien lo
detectó, y registrado en auditoría. Nunca `UPDATE`.

**Lo que habría que haber tenido**, que es la parte que de verdad responde la pregunta: conciliación
diaria automática con corte documentado, clave de negocio común, estado explícito de cada orden
incluido `SIN_RESPUESTA`, tabla de outbox como registro de lo ordenado, y métricas con escalado por
antigüedad. Con eso, el descuadre del primer día habría aparecido esa misma mañana, con la operación
concreta identificada, en vez de acumular tres días sin que nadie supiera desde cuándo.

## E6 — El cierre que NO hay que volver tiempo real

**Respuesta corta:** el cierre contable no se elimina, porque no existe por limitación técnica sino
por obligación contable: la contabilidad necesita un **corte temporal** —un instante en que el día
queda cerrado y deja de cambiar— para poder cuadrar, reportar y auditar. Lo que sí atiendo es el
dolor real que hay detrás de la propuesta, que no es el batch: es que nadie ve nada hasta mañana.

**Por qué la propuesta parece correcta.** Y hay que reconocerlo antes de rebatirla, porque lo es a
medias: la ventana nocturna sí es un punto de fragilidad operativa, sí condiciona el diseño de todos
los canales, y el saldo que ve el cliente sí debería moverse al instante. Todo eso es cierto. Lo que
no se sigue es que el cierre contable sea el causante.

**Lo que separo en la pizarra, que es la respuesta de verdad:**

```text
Saldo DISPONIBLE   → ya es tiempo real, o debería serlo. Refleja retenciones y
                     movimientos en curso. Es lo que el cliente mira en la app.
Saldo CONTABLE     → lo fija el cierre. Es lo que se reporta, se cuadra y se audita.
                     Cambia una vez al día, y eso es una propiedad, no un retraso.
```

Esa distinción ya está en [`01`](01-core-bancario-y-legado.md) y es la que desarma la reunión: lo
que el director quiere en tiempo real ya puede estarlo, y no toca el cierre.

**Lo que ofrezco, entonces:**

- **Visibilidad intradía por proyección**, no por contabilidad continua: los movimientos se publican
  como eventos y alimentan una proyección de saldo disponible y de posición intradía. Da el "lo veo
  ahora" sin tocar el asiento contable.
- **Conciliación continua en vez de solo nocturna**: el descuadre se detecta durante el día, que es
  la mitad del valor que la propuesta prometía, y se consigue sin cambiar el modelo contable.
- **Reducir la ventana, no eliminarla**: particionado y precálculo de lo que no depende del corte,
  como está en [`03`](03-batch-y-spring-batch.md). Si la ventana molesta, se acorta.

**Lo que digo sobre el riesgo regulatorio**, que es el argumento que cierra la discusión delante del
área regulatoria: un asiento contable que se calcula en continuo sobre un flujo de eventos es un
asiento **sin instante de corte reproducible**. Si el supervisor pide el balance a cierre de un día
de hace ocho meses, la respuesta tiene que ser un número único y estable, no el resultado de
reprocesar un stream. La contabilidad por partida doble con corte diario tiene trescientos años y
sigue vigente porque resuelve exactamente ese problema.

**Lo que no digo.** Que el batch sea bueno, ni que no se pueda modernizar. Se moderniza —observable,
reiniciable, particionado, con cuadre explícito— y se le quita todo lo que no exige el corte. Lo que
no se hace es confundir el mecanismo con el requisito que lo obliga.

**Cómo mediría que acerté.** Si tras entregar la proyección intradía y la conciliación continua la
petición de "contabilidad en tiempo real" no vuelve, el dolor era visibilidad y estaba bien
diagnosticado. Si vuelve, es que había un requisito regulatorio o de negocio que no escuché, y
entonces la conversación es otra.

---

**Anterior:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
