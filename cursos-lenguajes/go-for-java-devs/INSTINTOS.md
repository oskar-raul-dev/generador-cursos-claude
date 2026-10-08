# ☕ INSTINTOS

> El catálogo de reflejos de Java que hay que recalibrar al escribir Go.
> Go para desarrolladores Java senior · la plataforma Meridian

Este es **el documento del curso**. Todo lo demás es el camino para escribirlo.

Un reflejo ☕ no es un error de principiante: es una respuesta **correcta en Java**
aplicada a un modelo distinto. Por eso cada entrada dice **por qué el reflejo es
razonable**, qué cuesta aplicarlo aquí —con números cuando los hay— y qué pensar en
su lugar.

**Se alimenta al cerrar cada fase, nunca al final.** Y la sección más valiosa es la
última: los reflejos ordenados por cuánto cuesta desaprenderlos.

---

## 🧭 Cómo usar este documento

- **En una revisión de código**, como lista de comprobación. Los `grep` de la Fase
  17 §6.4 automatizan buena parte.
- **Al escribir**, cuando algo te salga "natural" y estés en las primeras semanas.
  La pregunta recurrente del curso:

> ☕ **¿Esta abstracción existe porque el dominio la necesita, o porque así la
> escribiríamos en Spring?**

- **Y para añadirle los tuyos.** El catálogo no está cerrado.

---

## 🏗️ Diseño y estructura

### ☕ "Interfaz primero, implementación después"

**Por qué es razonable.** En Java la interfaz vive **con la implementación** y es
su contrato público. `UserService` + `UserServiceImpl`, `@Service`, `@Autowired`, y
el contenedor une las puntas. Lleva quince años funcionando.

**Qué cuesta aquí.** Medido en la autopsia de la Fase 02, sobre el mismo caso de
uso:

| | Con interfaz primero | Struct concreto |
|---|---|---|
| Archivos | 8 | 3 |
| Métodos de interfaz del servicio | 9 | 0 |
| Tipos intermedios (DTO, mapper, factory) | 4 | 0 |
| Saltos para leer `Create` de punta a punta | 5 | 2 |

**Qué pensar en su lugar.** **La interfaz se declara donde se consume**, con el
tamaño mínimo que el consumidor necesita. El paquete exporta structs concretos; las
interfaces aparecen en quien llama. Si una interfaz tiene más de tres o cuatro
métodos, pregúntate quién la consume y para qué.

**Fase 02** · *"The bigger the interface, the weaker the abstraction."*

---

### ☕ `IThing`, `ThingImpl`, `ThingFactory`, `ThingManager`

En Go no significan nada. `report.Generator`, no `report.ReportGenerator`
(tartamudeo). Sin prefijo `I`, sin sufijo `Impl`. Una fábrica de un struct con tres
campos es una función `New`.

**Fase 02** · detectable con
`grep -rnE '\bImpl\b|^type I[A-Z]|Factory|Manager' services/`

---

### ☕ "Devolver la interfaz desde el constructor"

`func New(...) Store` impide al llamador usar cualquier método que no esté en ella
y obliga a aserciones de tipo para salir del paso. **Acepta interfaces, devuelve
structs.**

**Fase 02**

---

### ☕ "Embedding es `extends`"

**Por qué es razonable.** Se parece muchísimo: incrustas un tipo y sus métodos
quedan disponibles.

**Qué cuesta.** El embedding es **delegación**, no herencia. Un método plantilla en
el tipo incrustado llama al método del tipo incrustado, **no al tuyo**:

```go
func (r ReportJob) Name() string { return "report-" + r.id }  // "sobrescrito"
r.Banner()  // ">>> job-42 <<<"  ← usa Job.Name, no ReportJob.Name
```

No hay `super`, no hay `@Override`, no hay *dispatch* dinámico hacia arriba. El
programa compila, los tests de la "clase base" pasan, y el comportamiento
polimórfico que dabas por hecho no ocurre.

**Qué pensar en su lugar.** Pasa la pieza variable como **interfaz o función**, no
la incrustes.

**Fase 02**

---

### ☕ "Un paquete `utils` / `common` / `helpers`"

Es la señal de que un tipo todavía no encontró su sitio. Si no sabes cómo llamar al
paquete, el paquete todavía no existe.

**Fases 02 y 03**

---

### ☕ "Primero el layout de directorios"

Crear `pkg/`, `api/`, `configs/`, `deployments/` vacíos por parecerse a un estándar
que no existe. **En Go la estructura es un resultado, no un punto de partida.**

**Fase 00**

---

### ☕ "Ahora extraemos las piezas comunes a `commons`"

**Por qué es razonable.** Es el módulo compartido de toda organización Java.

**Qué cuesta.** Cuatro servicios que se despliegan juntos; una librería que acumula
lo que no encaja en ningún sitio; y abstracciones que **impiden la divergencia
legítima** —AtlasSync necesita una política de errores distinta a la de EventRelay,
y `commons` les impone la misma—.

**Qué pensar en su lugar.** *"Un poco de copia es mejor que un poco de
dependencia."* Se comparte lo que tiene **una sola respuesta correcta** y **ninguna
política de negocio dentro**: el reloj, la redacción de secretos, el dialer seguro,
el contrato entre servicios. Lo demás se repite.

**Fase 17**

---

## 🔢 Modelo de valores

### ☕ "Un slice es un `ArrayList`"

**El reflejo fundacional del curso.**

```go
movements := []string{"SALE", "REFUND", "VOID", "DEPOSIT"}
firstTwo := movements[:2]
firstTwo = append(firstTwo, "PATCHED")
fmt.Println(movements)  // [SALE REFUND PATCHED DEPOSIT]  ← ¿perdón?
```

**Qué cuesta.** Corrupción silenciosa de datos que pasa los tests y la revisión de
código. Y lo que lo hace peligroso: **a veces no pasa**, porque depende de la
capacidad, que normalmente no miras.

**Qué pensar en su lugar.** *"Un slice es una **vista** sobre un arreglo, y dos
vistas pueden solaparse."* Si devuelves un slice de tu estado interno, o lo copias
o documentas que es de solo lectura.

**Fase 01**

---

### ☕ "`substring` me da una cadena independiente"

Cierto en Java desde la 7; falso para subslices en Go. Un subslice de treinta bytes
puede retener un arreglo de diez megas. **Coste: tres órdenes de magnitud en
memoria retenida.**

**Fase 01**

---

### ☕ "Getters y setters para cada campo"

El campo exportado ya es accesible. Escribir `GetPriority()` sobre un campo público
es ceremonia sin destinatario, y un paquete llamado `WorkItemUtils` es la señal de
alarma.

**Fase 01**

---

### ☕ "El reloj se lee donde se necesita"

`time.Now()` dentro de la lógica de negocio hace la función imposible de probar. El
reloj es un **parámetro** y después una **dependencia inyectada** — ocho líneas de
`FakeClock` convierten "esperar cuatro días" en un test de microsegundos.

**Fases 01, 02 y 04** · `grep -rn 'time.Now()' services/*/internal/ | grep -v _test`

---

## 🧯 Errores

### ☕ "La interfaz nula que no es nula"

**El bug más elegante de Go.**

```go
func (w WorkItem) Validate() *ValidationError { ... return nil }
// y arriba:
if err := validateItem(item); err != nil {   // ← SIEMPRE entra
```

Una interfaz son **dos palabras**: tipo y valor. Un `*ValidationError` nulo dentro
de un `error` tiene tipo, así que `err != nil` es verdadero.

**Coste:** todos los caminos felices se convierten en errores. Una línea para
arreglarlo; horas para encontrarlo si no conoces el patrón.

**Qué pensar en su lugar.** **Devuelve siempre `error`, y `nil` literal.**

**Fase 03**

---

### ☕ "`panic`/`recover` como `try`/`catch`"

Se parecen y no lo son: `recover` solo funciona en un `defer` de la **misma
goroutine**, pierdes la identidad del error —`errors.Is` deja de servir— y nadie
más en el ecosistema escribe así.

`panic` tiene un lugar estrecho: invariantes rotos en el arranque, y `recover` en
el borde de un worker o un handler para que un bug no tumbe el proceso.

**Fase 03**

---

### ☕ "Comparar errores con `==` o con `strings.Contains`"

Se rompe con el primer envoltorio `%w`, y la segunda forma además se rompe cuando
alguien traduce un mensaje. **`errors.Is` / `errors.As`**, y el linter `errorlint`
lo detecta.

**Fase 03**

---

### ☕ "Envolver todo con `%w` por reflejo"

En el momento en que envuelves, los llamadores pueden depender de lo que hay
dentro, y cambiarlo es un cambio incompatible. **Envolver es parte de la API
pública.** `%v` cuando el detalle solo va al log.

**Fase 03**

---

### ☕ "Una jerarquía de siete tipos de error"

El reflejo de `extends Exception`. Casi siempre son **tres centinelas y un tipo con
datos**. La regla: si el llamador solo necesita saber *qué* pasó, centinela; si
necesita saber *sobre qué*, tipo de error.

**Fase 03**

---

### ☕ "`defer` dentro del bucle"

El alcance de `defer` es la **función**, no el bloque. `try-with-resources` cierra
en cada iteración; `defer f.Close()` en un bucle de diez mil archivos los mantiene
todos abiertos. **Coste: `too many open files` en producción, con carga alta y no
en desarrollo.**

**Fase 03**

---

## ⚙️ Concurrencia

### ☕ "Un pool es un `for` con `go` dentro"

**Por qué es razonable.** `ExecutorService` te daba tres cosas —límite, resultado y
apagado— y ninguna viene con `go`.

**Qué cuesta.** Medido en la autopsia de la Fase 06, con dos millones de filas:

| | `go` por fila | Worker pool |
|---|---|---|
| Goroutines creadas | **2.000.000** | 8 |
| Memoria mínima solo por pilas | **~4 GB** | ~16 KB |
| ¿Se puede aplicar contrapresión? | **no** | sí |

**Y el matiz que casi nadie ve:** un semáforo limita **la ejecución**, no **la
creación**. El canal acotado es lo que frena al productor.

**Qué pensar en su lugar.** **Cero concurrencia sin límite.** Toda goroutine tiene
un dueño que sabe cuándo termina, y todo conjunto tiene un tope. Si arrancas una
goroutine y no puedes decir quién la espera, está mal.

**Fase 06**

---

### ☕ "Los canales son la respuesta a todo"

Para proteger un contador, un canal es uno o dos órdenes de magnitud más lento que
un mutex (B-08). El proverbio completo es: **canales para transferir propiedad,
mutex para proteger estado compartido.**

**Fase 06**

---

### ☕ "`sync.Map` es el `ConcurrentHashMap` de Go"

No lo es. Está optimizada para dos patrones concretos —claves escritas una vez y
leídas muchas, o goroutines con conjuntos de claves disjuntos—. Fuera de ellos,
`map` + `RWMutex` gana **y además es tipado**.

**Fase 06**

---

### ☕ "`synchronized` es reentrante, esto también"

`sync.Mutex` **no** es reentrante. Un método con el lock tomado que llama a otro
método con el lock: deadlock inmediato. La convención de la stdlib: el método
exportado toma el lock y llama a un privado `xxxLocked`.

**Fase 06**

---

### ☕ "`recover` en el borde HTTP me cubre"

`net/http` recupera los panics de **su** handler. Un panic en una goroutine que el
handler lanzó **mata el proceso entero**. Toda goroutine de larga duración lleva su
`recover`.

**Fase 06**

---

### ☕ "Un test de concurrencia que pasa demuestra que no hay carrera"

`-race` es un detector **dinámico**: solo ve los accesos que ocurren. Un test que
serializa sin querer —con un `sleep`, o porque la máquina va sobrada— no detecta
nada. **Contención real, `-count=20` y `-cpu=1,2,4,8`.**

**Fase 06**

---

## ⏱️ Contexto y ciclo de vida

### ☕ "El `context` es un `ThreadLocal`"

**Por qué es razonable.** `SecurityContextHolder`, el `MDC`, `RequestContextHolder`
— es la solución estándar de Java y funciona.

**Deriva en dos ☕ distintos:**

**(a) Guardarlo en el struct.** El servicio vive todo el proceso; el contexto
pertenece a una petición. Resultado: **todas las peticiones fallan a partir de la
segunda** con `context canceled`. Y es **indetectable en un test secuencial**.

**(b) Usarlo como bolsa de parámetros.** La firma miente, el compilador no verifica
nada, y la aserción de tipo entra en panic en producción.

**Qué pensar en su lugar.** **Un contexto pertenece a una llamada, no a un
objeto.** Lleva cancelación, plazos y valores de ámbito de petición que atraviesan
capas sin pertenecer a ninguna. La prueba: **si quitar el valor del contexto rompe
la lógica de negocio, ese valor tenía que ser un parámetro.**

**Fase 07**

---

### ☕ "Pasar `r.Context()` al trabajo de fondo"

El trabajo muere cuando la respuesta HTTP termina de escribirse, de forma
intermitente y desconcertante. **¿Este trabajo tiene que morir cuando muera la
petición?** Para una consulta, sí. Para un job encolado, no.

🕰️ `context.WithoutCancel` (Go 1.21) conserva los valores sin heredar la
cancelación.

**Fase 07**

---

### ☕ "Reutilizar el contexto vencido para la limpieza"

Una entrega que agota su plazo **no puede ni registrar que lo agotó**, porque el
contexto ya está vencido y el `UPDATE` falla también. **El sistema deja de poder
anotar por qué está fallando, justo cuando falla.**

**Fase 07**

---

### ☕ "El apagado ordenado lo hace el `main`"

Lo hace **cada función que mira su contexto**. Con un runner que no lo mira, el
`SIGTERM` es decorativo: **45 segundos y `SIGKILL` frente a 100 milisegundos**. La
granularidad del fragmento define la latencia del apagado.

**Fase 07**

---

## 🌐 HTTP

### ☕ "Elegir framework web antes de escribir un handler"

En Go los frameworks web son enrutadores con azúcar sobre `net/http`. **`net/http`
es el framework.** Coste de saltárselo: no entiendes qué hace el tuyo porque nunca
escribiste lo que él hace.

**Fase 05**

---

### ☕ "El controlador orquesta"

**Coste medido** (Fase 05): 38 líneas frente a 22, cinco responsabilidades frente a
dos, validación duplicada **que diverge**, y —lo peor— un bug de escalada de
privilegios al construir la entidad a mano en el handler.

**Un handler hace tres cosas: decodifica, llama, codifica.**

**Fase 05**

---

### ☕ "Cada handler decide su código de estado"

El mismo error responde 404 en un endpoint y 500 en otro. **Una sola función
`classify`.**

**Fase 05**

---

### ☕ "`http.Server{}` está bien así"

No trae **ningún** timeout por defecto, y eso es explotable: Slowloris consume una
goroutine y un descriptor por conexión **indefinidamente**. No se nota nunca en
desarrollo.

**Fase 05**

---

### ☕ "`http.Get` es la forma de llamar a una API"

`http.DefaultClient` **no tiene tiempo límite**. Si el servidor acepta la conexión
y no responde, esa llamada espera para siempre — con su goroutine, su conexión de
base de datos y su worker.

**Fase 10**

---

### ☕ "Un `http.Client` por llamada"

Tira el pool de conexiones en cada uso: handshake TLS completo cada vez y
agotamiento de puertos efímeros. **Es crear un `DataSource` por consulta.**

**Fase 10**

---

### ☕ "Cerrar el cuerpo basta"

Sin **drenar** antes de cerrar, la conexión keep-alive no vuelve al pool. Y en el
**servidor** es al revés: `net/http` lo cierra por ti y añadir `defer
r.Body.Close()` es ruido que confunde sobre la regla real.

**Fases 05 y 10**

---

## 🔁 Resiliencia

### ☕ "`@Retryable` y ya reintenta"

**El más caro del curso.** Medido en la autopsia de la Fase 10, con un incidente
real reconstruido:

```text
14:32:00  el socio devuelve 503. 8.000 entregas pendientes.
14:32:02  8.000 reintentos SIMULTÁNEOS (retroceso fijo, sin jitter)
14:32:08  → 40.000 peticiones en 8 segundos
14:32:41  el socio se recupera y vuelve a caerse POR SOBRECARGA
14:51:00  se recupera de verdad
```

**Una caída de 40 segundos convertida en una de 19 minutos, causada por el
reintento.**

**Qué pensar en su lugar.** El reintento tiene **tres decisiones y cada una es una
función**: qué reintentar (clasificación, pura y probada con tabla), cuánto esperar
(retroceso exponencial con *full jitter*, respetando `Retry-After`), y cuándo parar
del todo (cortacircuitos **por destino**).

**Fase 10**

---

### ☕ "Un reintento siempre ayuda"

Reintentar un 4xx produce el mismo fallo N veces y puede activar un bloqueo del
socio. **Ante la duda, permanente**: el coste de los dos errores no es simétrico.

**Fase 10**

---

### ☕ "Un bloqueo distribuido garantiza exclusión mutua"

**No lo hace, y no es arreglable con un algoritmo mejor.** Una pausa de recolección
o de red mayor que el TTL permite que dos procesos estén dentro a la vez.

**Los bloqueos distribuidos sirven para EFICIENCIA, nunca para CORRECCIÓN.** La
corrección se resuelve donde están los datos: restricción única, `UPDATE`
condicional, transacción.

**Fase 12**

---

### ☕ "Exactamente una vez"

No existe entre dos sistemas sin transacción distribuida. **Al menos una vez, con
deduplicación en el consumidor.** Cualquier diseño que prometa lo contrario está
mintiendo o escondiendo la deduplicación.

**Fase 13**

---

### ☕ "`@TransactionalEventListener(AFTER_COMMIT)` resuelve el outbox"

**No son equivalentes.** La anotación publica en memoria **después** del commit: si
el proceso muere entre las dos cosas, el evento se pierde. El outbox escribe el
evento **en la misma transacción**.

**Fase 13**

---

## 🗄️ Datos

### ☕ "Reimplementar `@Transactional`"

**Por qué es razonable.** La propagación declarativa resuelve problemas reales y
lleva quince años de infraestructura detrás.

**Qué cuesta** (autopsia de la Fase 09): el alcance transaccional deja de verse en
la firma; un olvido de envolver escribe **fuera de transacción en silencio**; y un
`*sql.Tx` puede acabar compartido con una goroutine sin que nadie lo vea —y no es
seguro para uso concurrente—.

**Qué pensar en su lugar.** **La transacción viaja por parámetro.** Un parámetro
más por firma a cambio de que nunca te preguntes si esta llamada está dentro de una
transacción.

**Fase 09**

---

### ☕ "`sql.Open` abre una conexión"

No conecta, no valida credenciales, no falla si la base está caída. Sin `Ping`, el
servicio arranca con la contraseña mal escrita, el orquestador lo marca sano, y
falla en la primera petición de un usuario.

**Fase 09**

---

### ☕ "El pool se configura solo"

`MaxIdleConns` por defecto es **2**. Con `MaxOpenConns=25`, el pool abre 25
conexiones bajo carga y cierra 23 al bajar, para volver a abrirlas en el siguiente
pico. Latencia irregular sin causa aparente.

**Fase 09**

---

### ☕ "H2 en memoria para los tests"

Un motor distinto en test que en producción esconde divergencias. **Contenedor
real** con `testcontainers-go`.

**Fase 09**

---

### ☕ "El día siguiente es `Add(24*time.Hour)`"

En el día del cambio de horario, el día tiene 23 o 25 horas. **`AddDate(0,0,1)`
sobre una hora en la zona local.** Es el bug más caro que ClearingHouse puede
tener, y falla exactamente dos noches al año.

**Fase 09**

---

### ☕ "Esquemaless significa que no tengo que pensar el esquema"

A los seis meses, `population` es entero en unos documentos y cadena en otros, y el
código se llena de `switch` sobre tipos.

**El esquema existe siempre; la pregunta es dónde vive.** En Mongo vive en **tu
código** —el struct con sus etiquetas— y lo impone tu decodificador. Cambiarlo
sigue siendo una migración; lo que cambia es que **nadie te obliga a hacerla**.

**Fase 11**

---

### ☕ "Ya tenemos Mongo levantado"

Elegir el almacén por disponibilidad y no por la forma del dato. **La causa raíz de
la autopsia de la Fase 11**: un modelo relacional en un motor sin integridad
referencial, sin atomicidad multi-entidad y sin optimizador de uniones. **La peor
de las dos opciones.**

**Fase 11**

---

### ☕ "`save()` guarda el objeto"

`ReplaceOne` **borra los campos que tu versión del struct no conoce**, en silencio.
Con dos versiones desplegadas a la vez, es un bucle de pérdida de datos. Se
actualiza con `$set`.

**Fase 11**

---

### ☕ "Cargo, proceso y guardo"

Con un millón de filas: **2,7 GB y el proceso muere**. Con `GOMEMLIMIT`, no muere:
se vuelve inútil, que es peor de diagnosticar.

**El número de elementos en memoria es una constante de configuración, nunca una
función del volumen de entrada.**

**Fase 13**

---

### ☕ "El lote terminó, luego fue bien"

**La autopsia de la Fase 13.** Un lote que cuenta **leídos** en vez de
**conciliados** perdió catorce mil movimientos en un mes sin decir nada.

**La ecuación tiene que cuadrar y se comprueba en el código:**
`leídos = conciliados + omitidos + fallidos`.

**Fase 13**

---

### ☕ "Adelanto el punto de control para no reprocesar"

Convierte **repetición** (tolerable, con idempotencia) en **pérdida silenciosa**
(mortal). El punto de control va **dentro de la misma transacción** que el trabajo.

**Fase 13**

---

## ⚡ Caché

### ☕ "`@Cacheable` y ya está cacheado"

Esconde **cuatro decisiones**: la clave —¿sabes cuál genera el `KeyGenerator` por
defecto?—, la serialización —nativa de Java, que acopla la caché a la versión de
tus clases—, el TTL —no lo tiene— y **qué pasa si el backend falla** —por defecto
propaga la excepción y tu petición falla—.

**Fase 12**

---

### ☕ "El TTL de una hora está bien"

Sin *jitter*, 250 claves cacheadas en el mismo segundo expiran en el mismo segundo.
**250 fallos simultáneos frente a unos 30 repartidos**, y la tasa de acierto media
es idéntica — así que un panel no lo distingue.

**Fase 12**

---

### ☕ "La caché puede quedarse sin TTL, total el dato no cambia"

**La autopsia de la Fase 12**, en cinco pasos razonables: subir el TTL, quitarlo,
escribir en la caché al ingerir, dejar de leer del origen... y un martes Valkey se
reinició. **16 minutos de caída total.**

**Tres reglas:** toda clave de caché tiene TTL; la caché tiene que poder apagarse
con una bandera y el servicio seguir funcionando —**y se prueba**—; y un fallo de
caché degrada, nunca rompe.

**Fase 12**

---

### ☕ "Poner caché siempre mejora"

B-17 puede decir que un mapa en memoria ya lo resolvía y que Valkey solo añadió un
servicio que mantener. **Las cuatro preguntas:** ¿cabe en memoria? ¿cuántas
instancias? ¿cuánto cuesta llenarla? ¿importa la coherencia entre instancias?

**Fase 12**

---

## 👁️ Observabilidad

### ☕ "El `traceId` va en el MDC"

No hay MDC ni estado por goroutine, **y es deliberado**. La correlación se resuelve
en un `slog.Handler` que lee el `context`; meter el logger en el `context` es el ☕
de la Fase 07 con otro nombre.

**Fase 14**

---

### ☕ "Registro la petición completa para poder depurar"

El secreto acaba en cinco sitios: la salida del contenedor, el agregador indexado y
retenido noventa días, sus copias de seguridad, posiblemente la traza, y —si el
agregador es gestionado— **fuera de tu infraestructura**. Rotarlo exige coordinarse
con el socio.

**Tres capas de defensa:** el tipo `Secret` que no se puede imprimir,
`ReplaceAttr` por nombre de clave, y la detección por patrón.

**Fase 14**

---

### ☕ "La ruta en la etiqueta de la métrica"

Un solo endpoint con un millón de ids crea **un millón de series temporales** y un
`/metrics` de 7,3 MB que Prometheus descarga cada quince segundos. **Y no se
arregla arreglando el código**: las series viejas viven horas.

**La etiqueta es el PATRÓN de ruta.** Con el `ServeMux` de 1.22, `r.Pattern`.

**Fase 14**

---

### ☕ "Tenemos observabilidad: el panel está verde"

**La autopsia de la Fase 14.** Nueve días sin entregar a tres socios, con las
métricas RED en verde: el servicio **atendía** peticiones bien; lo que fallaba era
saliente y **no se medía**.

**Las métricas técnicas dicen si el servicio está vivo; las de negocio, si está
haciendo su trabajo.** La pregunta: *"¿qué métrica se movería si este servicio
dejara de hacer aquello para lo que existe?"*

**Fase 14**

---

### ☕ "`/health` comprueba que todo funciona"

Si consulta la base de datos, una caída de la base **reinicia todos los
contenedores en bucle**, convirtiendo una degradación en una caída total.
`/health` es "¿está vivo el proceso?"; `/ready` es "¿puede atender ahora?".

**Fase 14**

---

### ☕ "Valido la URL antes de llamarla"

No para **DNS rebinding**: la comprobación y la conexión son dos resoluciones
distintas. **La defensa va en el `DialContext`**, sobre la IP a la que se va a
conectar de verdad. Y `::ffff:169.254.169.254` es la evasión que se olvida.

**Fase 14** · deuda declarada en la Fase 02: **doce fases**

---

### ☕ "Comparo las firmas con `==`"

La comparación de cadenas sale en el primer byte distinto, y eso permite deducir la
firma byte a byte con suficientes intentos. **`hmac.Equal` cuesta lo mismo y
elimina la categoría entera.**

**Fase 14**

---

## 📈 Rendimiento

### ☕ "Esto asigna mucho, hay que hacer un pool"

**Por qué es razonable.** En Java, la presión sobre la generación joven es real y
los pools fueron una optimización estándar.

**Qué cuesta.** En Go: el asignador es muy bueno con objetos pequeños, **el escape
analysis ya evitó la mayoría de las asignaciones** —lo que no escapa va a la pila y
es gratis—, y `sync.Pool` **se vacía en cada recolección**.

**Qué pensar en su lugar.** Mide. Y las tres opciones son `new`, `pool` y
**`reused`** — la tercera suele ganar cuando el ámbito lo permite.

**Fase 15**

---

### ☕ "El benchmark dice que es 37 veces más rápido"

**La autopsia de la Fase 15.** Un benchmark con **una** goroutine, **una** clave y
la caché **caliente**. En producción, el p99 subió de 48 ms a 340 ms por contención
de un `RWMutex` con un 8% de escrituras.

**`b.RunParallel` y `-cpu=1,4,8,16` no son opcionales cuando hay estado
compartido.** Un benchmark que empeora al añadir procesadores es la firma de la
contención.

**Fase 15**

---

### ☕ "El perfil de CPU no muestra nada raro"

**Esperar un mutex no consume CPU.** Los perfiles `mutex` y `block` están
desactivados por defecto y casi nadie sabe que existen — y son justo los que
responden "el servicio está lento con la CPU ociosa".

**Fase 15**

---

### ☕ "Una corrida basta"

Sin `-count=10` y `benchstat`, una mejora del 8% con variabilidad del 12% es
imaginaria. Y `~` en la columna de `benchstat` significa **"sin diferencia
detectable"**, no "mejora pequeña".

**Fase 15**

---

### ☕ "El compilador no va a borrar mi código"

Sí lo hace. **Mil millones de iteraciones a 0,25 ns** es la firma inconfundible de
un benchmark que mide un bucle vacío. `b.Loop` lo impide por construcción.

**Fase 15**

---

### ☕ "Puntero significa heap"

Falso en Go. El escape analysis mantiene en la pila lo que no escapa, aunque se use
por puntero — y `-gcflags=-m` te dice **por qué** escapa cada cosa, que es algo que
la JVM no te da.

**Fase 15**

---

## 🚚 Migración y decisión

### ☕ "Ya que migramos, arreglamos lo demás"

**Coste medido** (autopsia de la Fase 08): 340 archivos frente a 47, `git bisect`
inutilizado, y la imposibilidad de separar qué rompió la migración de qué rompió el
refactor.

**Una migración buena se lee en el `--stat`.** Y si migrar obliga a cambiar 180
tests, no migraste: reescribiste.

**Fase 08**

---

### ☕ "Los genéricos por fin permiten hacer `Repository<T>`"

**El ☕ más sofisticado que existe**, porque ahora el compilador ayuda a
construirlo. Las consultas reales no son genéricas —`ListPendingBefore`,
`ClaimNextBatch`—, empuja hacia un modelo de persistencia uniforme que no existe, y
rompe la regla de declarar interfaces en el consumidor.

**Escribe la versión concreta primero. Generaliza con el tercer caso delante.**

**Fase 08**

---

### ☕ "Modernizar es sustituir lo viejo por lo nuevo"

El `ValidationError` que **no** se sustituye por `errors.Join` es el ejemplo del
curso: `Join` agrega mejor, nuestro tipo estructura mejor, y el borde HTTP necesita
lo segundo.

**Fase 08**

---

### ☕ "La JVM es lenta"

Es lenta **al principio**. El JIT optimiza con información de ejecución real y
puede superar a la compilación anticipada en régimen estacionario. **La pregunta es
el perfil de ejecución del servicio**, no cuál es más rápido.

**Fase 16**

---

### ☕ "Los benchmarks dicen que migremos"

**La autopsia de la Fase 16.** JVM fría, sin ajustar, `native-image` sin probar, y
un `/health` que no ejercitaba nada. **2.400 días-persona para ahorrar 40.000 euros
al año**, y la migración se abandonó al 60%.

**Un benchmark que no mide el coste de migrar no informa una decisión: la justifica
a posteriori.**

**Fase 16**

---

### ☕ "Nuestro servicio va lento, migremos a Go"

La mayoría de los servicios lentos lo son por la base de datos, por el diseño o por
una llamada de red en un bucle. **Migrar de lenguaje no arregla ninguna de las
tres**, y cuesta dieciocho meses descubrirlo.

**Fase 16**

---

### ☕ "Ahora que sé Go, migremos"

El sesgo del conocimiento nuevo. Es el que produjo la autopsia de la Fase 16, y es
el más difícil de ver porque no se siente como un sesgo: se siente como
competencia.

**Fase 17**

---

## 🧪 Pruebas

### ☕ "Hay que mockear el almacén"

**Coste medido** (Fase 04): 12 líneas de preparación por test frente a 2, un paso
de generación en el build, y **tres de cuatro refactorizaciones sin cambio de
comportamiento rompen el test de mock**.

**Verifica estado cuando lo haya; interacción solo cuando no lo haya.** El
generador entra en la Fase 10, con un caso real: *"reintentó exactamente tres veces
y no cuatro"*.

**Fase 04**

---

### ☕ "La cobertura alta significa que está probado"

Un test que ejecuta todas las ramas y **no afirma nada** da 100%. Cambia
`< MinPriority` por `< 0` y sigue pasando.

**La cobertura mide líneas ejecutadas, no comportamiento verificado.** Sirve para
encontrar lo que NO se probó, no para presumir del número.

**Fase 04**

---

### ☕ "Una clase `ServiceTestSuite` con `setUp` y `tearDown`"

Reintroduce estado compartido entre tests. En Go: tablas, helpers con `t.Helper()`
y `t.Cleanup`.

**Fase 04**

---

### ☕ "Los tests de integración prueban contra el sistema real"

Una suite que depende de internet es intermitente por diseño, y el equipo **aprende
a reintentar el pipeline en vez de a mirar el fallo**. Ese aprendizaje es el
verdadero coste.

**`go test ./...` no toca la red. Nunca.** Y hay un test que lo verifica.

**Fase 10**

---

### ☕ "Cada servicio tiene su suite en verde, luego la plataforma funciona"

**La autopsia de la Fase 17.** Cuatro fallos triviales —un nombre de campo, un
separador, un propagador, una zona horaria— y ninguno detectado, porque cada
servicio probaba contra **su idea** del contrato.

**Un test que usa tus propias fixtures prueba que eres coherente contigo mismo.**

**Fase 17**

---

## 🪜 El recorrido final: ordenados por cuánto cuestan

### Nivel 1 — Se desaprenden en un día (el compilador te obliga)

| Reflejo | Fase |
|---|---|
| Imports sin usar toleradas | 00 |
| Getters y setters sobre campos públicos | 02 |
| Prefijo `I`, sufijo `Impl`, tartamudeo | 02 |
| `utils`, `common`, `helpers` | 03 |

### Nivel 2 — Se desaprenden en una semana (muerden pronto y visiblemente)

| Reflejo | Fase | Coste |
|---|---|---|
| "Un slice es un `ArrayList`" | 01 | corrupción silenciosa |
| "Primero el layout" | 00 | directorios muertos |
| "`sql.Open` abre una conexión" | 09 | arranque con credenciales malas |
| "Cerrar el cuerpo basta" | 10 | keep-alive roto |
| "`Ticker` de 24 h es un cron" | 13 | el cierre corre al desplegar |

### Nivel 3 — Se desaprenden en un mes (funcionan hasta que no)

| Reflejo | Fase | Coste medido |
|---|---|---|
| "Interfaz primero" | 02 | 5 archivos y 3 saltos extra |
| "Hay que mockear el almacén" | 04 | 12 líneas frente a 2 |
| "El controlador orquesta" | 05 | validación que diverge |
| "Un pool es un `for` con `go`" | 06 | 2M de goroutines, ~4 GB |
| "`@Retryable` y ya reintenta" | 10 | 40 s → 19 minutos de caída |
| "`@Cacheable` y ya está" | 12 | cuatro decisiones por omisión |
| "El benchmark dice 37×" | 15 | p99 de 48 ms → 340 ms |

### Nivel 4 — Cuestan meses (son modelos mentales, no hábitos)

| Reflejo | Fase | Por qué cuesta |
|---|---|---|
| "El `context` es un `ThreadLocal`" | 07 | el modelo de propagación es otro |
| "Reimplementar `@Transactional`" | 09 | quince años de infraestructura detrás |
| "Modelar en Mongo como en SQL" | 11 | el modelo de datos es otro |
| "Esquemaless = sin esquema" | 11 | ídem |
| "Cargo, proceso y guardo" | 13 | es cómo se escribe el 95% del código |
| "El panel está verde" | 14 | la instrumentación parece completa |
| "La JVM es lenta" | 16 | es cierto a medias, y esa mitad confunde |

### Nivel 5 — El que no se desaprende nunca del todo

> ## ☕ **"Ya que estamos, lo arreglamos."**

No es un reflejo de Java: **es un reflejo humano**. Aparece en cada migración, en
cada refactor y en cada revisión de código. La única defensa es un proceso: un
commit por cosa, y anotar lo demás.

**Está el último a propósito. Si te llevas uno solo de los cuarenta, que sea
este.**

---

## 🩻 Y la otra mitad: lo que sí se traslada

Quince fases señalando diferencias pueden dejar una impresión falsa. **La mayor
parte de lo que sabes se trasladó intacto:**

- Todo tu criterio de diseño de sistemas: responsabilidades, fronteras, diseñar
  para el fallo y para la operación.
- Todo tu conocimiento de SQL, índices, transacciones y modelado. La Fase 09 no te
  enseñó SQL: te enseñó otra API para el mismo SQL.
- La pirámide de pruebas y el criterio de qué probar.
- REST, códigos de estado, diseño de API, versionado.
- Los patrones de resiliencia: reintento, cortacircuitos, contrapresión,
  idempotencia. Son de sistemas distribuidos, no de un lenguaje.
- La observabilidad: los tres pilares, RED, la cardinalidad, los percentiles.
- El procesamiento por lotes: *chunk*, punto de control, reanudación.
- Separar dominio de infraestructura, inyectar dependencias, probar contra
  interfaces, versionar migraciones.
- Y la disciplina profesional: medir antes de optimizar, documentar decisiones, y
  escribir para quien lo herede.

**Lo que cambió fue el modelo de valores, el manejo de errores, el modelo de
concurrencia y la ausencia de contenedor.** Cuatro cosas. Importantes, y cuatro.

> 🧭 **Go no te quita herramientas: te quita intermediarios.** Todo lo que en
> Spring resuelve una anotación, aquí lo resuelve código que tú escribes y puedes
> leer. Se paga en líneas y se cobra en que no hay magia que depurar a las dos de
> la mañana. **Este catálogo es la factura detallada de ese intercambio.**
