# 11 — Respuestas del bloque 06 · Talleres

Solucionario único de los diez talleres. Cada enunciado está copiado **literalmente** de su taller y
cada respuesta lleva las tres capas de §8 de la guía: **⏱️ 30 segundos** (lo que dirías primero),
**🗣️ 2 minutos** (lo que añades cuando te dicen «cuéntame más») y **🔬 El detalle** (para estudiar).
Los ejercicios llevan una guía de solución, no el código completo: el código está en `laboratorio/`
y las salidas, en cada taller.

> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--heredar-el-legado) · [02](#-02--los-errores-escondidos) · [03](#-03--caracterización) · [04](#-04--el-contrato) · [05](#-05--sqlite-miente) · [06](#-06--modularizar) · [07](#-07--transacciones-y-concurrencia) · [08](#-08--eventos-jobs-y-dos-instancias) · [09](#-09--migraciones-de-esquema) · [10](#-10--el-monolito-distribuido-provocado)

---

## 📖 01 — Heredar el legado

### Preguntas

**01 → 1.** ¿Qué tres fuentes usaste para reconstruir las rutas del legado y qué aporta cada una? 🟢

⏱️ **30 segundos** — El código, el tráfico y la base. El código dice qué rutas existen; el tráfico, qué responden de verdad; la base, qué dejaron escrito.

🗣️ **2 minutos** — Las anotaciones `@GetMapping` y `@PostMapping` dan catorce operaciones, pero todas devuelven `Object`, así que no dicen la forma de la respuesta. `lab.py api` la muestra, incluidos los `200` con error. Y la base revela lo que ninguna de las dos ve: un pedido rechazado que no dejó filas y un *trigger* que devuelve stock. El mapa solo vale cuando las tres coinciden.

🔬 **El detalle** — El log sería una cuarta fuente, y en este legado es pobre: no registra peticiones, solo el arranque, el cierre diario y los timeouts del banco. Saber qué no está en el log también es arqueología.

**01 → 2.** ¿Por qué `lab.py seed` exige que el legado haya arrancado antes? 🟢

⏱️ **30 segundos** — Porque las tablas no las crea ningún script: las crea Hibernate al arrancar, con `ddl-auto: update`.

🗣️ **2 minutos** — La semilla hace `TRUNCATE` e `INSERT` sobre tablas que tienen que existir. Hasta que el legado arranca una vez contra la base, no existen. `lab.py seed` lo comprueba con `to_regclass` y, si faltan, lo dice y se detiene en lugar de fallar con un error de SQL.

🔬 **El detalle** — Es el primer síntoma del pecado del taller 09: el esquema no está versionado, está implícito en las entidades. Nadie puede crear la base sin arrancar la aplicación.

**01 → 3.** ¿Dónde vive la regla «más de 1000 se rechaza» y por qué es un problema aunque funcione? 🟢

⏱️ **30 segundos** — En un `if` de `PaymentService.pay`, en `laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy/service/PaymentService.java:46`. Funciona, pero duplica una regla del banco sin nombre ni prueba.

🗣️ **2 minutos** — El banco rechaza lo que pasa de 1000.00, y el legado decidió no llamarlo en ese caso. Si mañana el banco sube su límite, el legado seguirá rechazando por su cuenta y nadie sabrá por qué. Tampoco hay una prueba que diga que esa regla existe: solo se descubre leyendo el servicio.

🔬 **El detalle** — Una regla de negocio duplicada en dos sistemas diverge con el tiempo. La corrección no es borrar el `if`, sino decidir quién es dueño de la regla y dejar al otro consultarla.

**01 → 4.** ¿Qué hace el *trigger* `orders_restore_stock` y por qué no aparece en el código Java? 🟢

⏱️ **30 segundos** — Devuelve a `products` el stock de las líneas de un pedido cuando su estado pasa a `CANCELLED`. No está en Java porque lo crea `SchemaFixer` ejecutando `db/triggers.sql` al arrancar.

🗣️ **2 minutos** — La cancelación está repartida en tres sitios: el controlador impide cancelar un pedido pagado, el servicio cambia el estado y escribe la notificación, y la base devuelve el stock. Un `grep` en el código no encuentra quién restaura el inventario; hay que preguntar al catálogo de la base, `pg_trigger`.

🔬 **El detalle** — En las pruebas con SQLite el *trigger* no existe (`SchemaFixer` lo salta si la URL no es de PostgreSQL), así que una prueba de cancelación ahí pasa sin comprobar el stock. Es material del taller 05.

**01 → 5.** El pedido con `SKU-004` respondió `200`. ¿Qué pasó en la base y por qué el cliente no lo sabe? 🟡

⏱️ **30 segundos** — No se creó nada: la transacción hizo rollback. El cliente no lo sabe porque recibió `200` y el error viaja en un campo `error` del cuerpo.

🗣️ **2 minutos** — `InventoryService.take` lanzó `LegacyException` al ver stock 0 en `SKU-004`; como es una `RuntimeException` dentro de `@Transactional`, la transacción se revirtió. El controlador la atrapó y respondió `200 {"error": ...}`. Un cliente que mira el código de estado cree que compró; uno que busca el campo `error` sabe que no.

🔬 **El detalle** — El acoplamiento es sutil: cada cliente tiene que conocer la convención privada de este servidor. El taller 02 lo muestra rompiendo un frontend; el taller 04 lo corrige con códigos reales.

**01 → 6.** ¿Por qué el `SKU-001` de ese mismo pedido conservó su stock? 🟡

⏱️ **30 segundos** — Porque la reserva de `SKU-001` ocurrió dentro de la misma transacción que la de `SKU-004`, y el rollback la deshizo.

🗣️ **2 minutos** — `OrderService.create` está anotado con `@Transactional` y recorre las líneas en orden: primero resta stock de `SKU-001`, después falla en `SKU-004`. La excepción no se atrapa dentro del método, así que Spring revierte todo. Es la garantía correcta —todo o nada— dentro de un contrato que no la comunica.

🔬 **El detalle** — Si alguien moviera el `try/catch` al servicio para «devolver el error antes», la transacción se confirmaría con la primera reserva hecha. Por eso la frontera transaccional se prueba con un fallo a mitad, no leyendo anotaciones.

**01 → 7.** ¿Qué te dice `allow-circular-references: true` sobre el diseño antes de abrir un solo servicio? 🟡

⏱️ **30 segundos** — Que hay servicios que se necesitan mutuamente, y que alguien prefirió permitir el ciclo antes que romperlo.

🗣️ **2 minutos** — Spring Boot prohíbe los ciclos de beans por defecto desde la versión 2.6; activar la propiedad es una decisión consciente de convivir con él. En este legado, `OrderService` e `InventoryService` se llaman en ambos sentidos, y solo arrancan con inyección por campo. Es un mapa de dependencias escrito en la configuración.

🔬 **El detalle** — El ciclo no es un problema de arranque, es de diseño: ninguno de los dos módulos se puede cambiar, probar o extraer sin el otro. El taller 06 lo rompe con una dirección de dependencias.

**01 → 8.** ¿Qué diferencia hay entre «quién llama a `save`» y «quién escribe la tabla» en este legado? 🟡

⏱️ **30 segundos** — `save` es una escritura explícita; «quién escribe la tabla» incluye además el *dirty checking* de Hibernate, los *triggers* y las tareas programadas.

🗣️ **2 minutos** — `PaymentService` cambia el estado del pedido con `o.setStatus(...)` y nunca llama a `save` sobre él: Hibernate lo escribe al confirmar la transacción. El *trigger* escribe `products` al cancelar. Y `DailyCloseJob` escribe `batch_runs` sin que ninguna ruta lo pida. Un `grep` de `save` ve solo una parte.

🔬 **El detalle** — Para un mapa completo de escritores hacen falta tres miradas: el código, el catálogo de la base y, si se puede, los permisos o el registro de sentencias de la base mientras corre el tráfico.

**01 → 9.** Los secretos están en `application.yaml`. ¿Por qué el taller los señala y no los arregla? 🟡

⏱️ **30 segundos** — Porque arreglarlos es trabajo de plataforma —un gestor de secretos, rotación, despliegue— y mezclarlo con la arqueología cambiaría dos cosas a la vez.

🗣️ **2 minutos** — El taller se limita a registrarlos: la contraseña de la base y el secreto del JWT están en claro en el repositorio. Moverlos exige saber dónde se despliega el legado y con qué herramientas, algo que este curso no cubre. Lo que sí es responsabilidad de quien hereda el sistema es dejarlo anotado y avisar.

🔬 **El detalle** — Si el secreto del JWT está en el repositorio, cualquiera con acceso al código puede firmar tokens de operador. Señalarlo el primer día es parte de orientarse, aunque la corrección la haga otro equipo.

**01 → 10.** Tienes una hora para orientarte en este código. ¿En qué orden lo recorres y por qué ese orden? 🟠

⏱️ **30 segundos** — De fuera hacia dentro y siguiendo los datos: entradas, transacciones, escrituras y configuración, contrastando cada paso con tráfico y con la base.

🗣️ **2 minutos** — Primero los controladores y las tareas programadas, porque dicen qué puede pasar. Después, dónde se abren las transacciones y qué llaman dentro. Luego, quién escribe cada tabla, incluidos *triggers* y *dirty checking*. Por último, la configuración que cambia comportamiento. Con eso se entienden un flujo completo y sus riesgos en una hora.

🔬 **El detalle** — Leer entidades y repositorios al principio es tentador porque son fáciles, pero no dicen qué ocurre. El orden importa porque en una hora no se lee todo: se elige qué no leer.

**01 → 11.** El login distingue «User not found» de «Wrong password». ¿Qué riesgo introduce y qué debería responder? 🟠

⏱️ **30 segundos** — Revela qué correos existen, lo que facilita ataques de fuerza bruta o *credential stuffing*. Debería responder lo mismo en los dos casos, con un código que no distinga.

🗣️ **2 minutos** — Con `User not found` y `Wrong password`, un atacante puede probar una lista de correos y quedarse con los que existen. La respuesta correcta es un único error de credenciales inválidas, con el mismo cuerpo y un tiempo de respuesta parecido. El contrato del taller 04 lo fija como `401` con `INVALID_CREDENTIALS`.

🔬 **El detalle** — El tiempo también filtra: si el correo no existe, el legado responde sin calcular bcrypt y tarda menos (21 ms frente a 95 ms en este taller). Igualar el mensaje sin igualar el trabajo deja el canal abierto.

**01 → 12.** ¿Qué pecados del legado se detectan leyendo solo `application.yaml`? 🟠

⏱️ **30 segundos** — Esquema sin migraciones (`ddl-auto: update`), ciclo de beans (`allow-circular-references`), trazas en las respuestas (`include-stacktrace: always`), secretos en claro y el proveedor de pago con un timeout de 2 s.

🗣️ **2 minutos** — Cada línea es un pecado con dueño: el esquema implícito es del taller 09; el ciclo, del 06; las trazas, del 02 y el 04; el timeout corto frente a un banco que tarda 3 s con 666.00 produce el resultado incierto que trata el 07. Un archivo de configuración es un inventario de decisiones que alguien tomó con prisa.

🔬 **El detalle** — También dice lo que falta: no hay configuración de pool más allá del tamaño, ni de reintentos, ni de caché. La ausencia es información: esas cosas o no existen, o viven escondidas en el código.

**01 → 13.** Tu jefe pide «documentar el legado» en una semana. ¿Qué entregarías y qué evidencia de que es correcto? 🔴

⏱️ **30 segundos** — Un mapa verificable, no un README: rutas con su respuesta real y sus errores, tablas con sus escritores, reglas de negocio con su ubicación, y una suite que reproduzca ese comportamiento.

🗣️ **2 minutos** — La evidencia de que es correcto es que se puede ejecutar: el mapa de rutas se contrasta con peticiones reales, el de escritores con el catálogo y el registro de la base, y el comportamiento se congela en una suite de caracterización que pasa contra el legado. Eso es lo que hace el taller 03. Un documento que nadie puede comprobar describe lo que su autor cree.

🔬 **El detalle** — Conviene entregar también lo que no se sabe: rutas sin tráfico observado, reglas sin prueba, datos sin dueño. Una lista de dudas explícita es más útil que una documentación que aparenta estar completa.

### Ejercicios

**01 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se abre la transacción que envuelve la llamada al banco, y en qué línea se hace la llamada? Responde con rutas de `laboratorio/estados/01/`.

⏱️ **30 segundos** — La transacción se abre en `laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy/service/PaymentService.java:33` (`@Transactional` sobre `pay`), y la llamada al banco está en la línea 52.

🗣️ **2 minutos** — Se encuentra buscando `@Transactional` y `psp.post` en el servicio de pago. Entre las dos líneas hay una lectura del pedido y una comprobación de estado; la llamada ocurre con la transacción abierta, así que la conexión a la base queda retenida mientras el banco responde.

🔬 **El detalle** — La transacción no es visible en la llamada: la abre un proxy de Spring alrededor del método. Por eso la búsqueda empieza en la anotación, no en el código que usa la conexión.

**01 → E2.** 🟢 Crea un pedido de un `SKU-001`, págalo y cancélalo con `lab.py api`. Pega las tres respuestas y el stock de `SKU-001` antes y después con `lab.py sql`.

⏱️ **30 segundos** — Pedido `CONFIRMED`, pago `PAID` con referencia del banco, y cancelación rechazada con `200 {"error":"Paid orders can not be cancelled"}`. El stock de `SKU-001` baja de 20 a 19 y no vuelve.

🗣️ **2 minutos** — La secuencia es `POST /api/v1/orders`, `POST /api/v1/orders/{id}/payment` y `POST /api/v1/orders/{id}/cancel`, las tres con `lab.py api`, y `lab.py sql` para el stock antes y después. El stock no vuelve porque el pedido pagado no se cancela; con un pedido sin pagar, el *trigger* lo devolvería.

🔬 **El detalle** — La regla que impide cancelar está en el controlador, así que la cancelación de un pedido pagado nunca llega al servicio ni a la base: la respuesta es un `200` con error y ningún cambio.

**01 → E3.** 🟡 Con una consulta al catálogo de PostgreSQL, lista las funciones que no creó Hibernate. Pega la salida y di qué archivo del legado las crea.

⏱️ **30 segundos** — La función `restore_stock_on_cancel`, creada por `config/SchemaFixer.java` al leer `db/triggers.sql`.

🗣️ **2 minutos** — Una consulta como `select proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'` lista las funciones del esquema de la aplicación. Hibernate no crea funciones, así que todo lo que aparezca ahí lo creó otra cosa; en este legado, `SchemaFixer`.

🔬 **El detalle** — El mismo método sirve para *triggers*, vistas y secuencias: el catálogo de la base es la fuente de verdad de lo que existe, sea quien sea que lo creó.

**01 → E4.** 🟡 **Orientación en código ajeno.** ¿Qué archivo y línea deciden que un pedido pagado no se puede cancelar? ¿Por qué esa regla está ahí y no en `OrderService.cancel`, y qué riesgo tiene?

⏱️ **30 segundos** — En `laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy/controller/OrderController.java`, en el método `cancel` (el `if` sobre `"PAID"`). El riesgo es que cualquier otro camino que llame a `OrderService.cancel` se salta la regla.

🗣️ **2 minutos** — La regla vive en el controlador porque alguien la añadió donde le llegó el error de un usuario. `OrderService.cancel` no la comprueba: un job, otro controlador o una prueba pueden cancelar un pedido pagado y el *trigger* devolverá stock de algo ya cobrado. Una regla de negocio en la capa de entrada solo protege una de las entradas.

🔬 **El detalle** — Es un ejemplo de la lógica repartida entre controlador, servicio y base que el taller 06 recoge en el módulo dueño.

**01 → E5.** 🟡 Da de alta `SKU-006` como `ops` con `POST /api/v1/products` y repite el `POST` con otro precio. Pega las dos respuestas y explica qué pasó con el primer precio.

⏱️ **30 segundos** — Las dos respuestas son `200` con la entidad guardada; el segundo `POST` pisa el primer precio sin avisar.

🗣️ **2 minutos** — `ProductService.save` llama a `products.save(p)` con el SKU como clave; si ya existe, JPA hace un `merge` y sobrescribe nombre, precio y stock. No hay comprobación de duplicado ni error. El contrato del taller 04 lo convierte en `409` con `PRODUCT_ALREADY_EXISTS`.

🔬 **El detalle** — El stock también se pisa: un alta repetida puede reponer inventario sin que nadie lo decida. En un sistema real, eso aparece como diferencias de inventario inexplicables semanas después.

**01 → E6.** 🟠 Paga un pedido de tres `SKU-003` (666.00) y compara la respuesta del legado con `GET http://localhost:38085/payments`. ¿Se cobró? ¿Qué sabe el legado y qué no?

⏱️ **30 segundos** — Sí se cobró: el banco registra el cargo de 666.00. El legado solo sabe que el banco no respondió a tiempo y deja el pedido `PAYMENT_PENDING` sin referencia.

🗣️ **2 minutos** — El legado espera 2 s y el banco tarda 3 s con ese importe. El legado guarda un pago `PENDING` con `reference` nula; `GET http://localhost:38085/payments` muestra el cobro con su referencia. Para reconciliar, el legado necesitaría preguntar al banco por la operación, y no puede: no envió ninguna clave de idempotencia.

🔬 **El detalle** — Es el escenario de resultado incierto del capítulo de fallos parciales, reproducido en un solo proceso. El taller 07 añade la clave que permite reconciliar.

**01 → E7.** 🟠 Construye la tabla «tabla → escritores» del legado incluyendo el *dirty checking*, el *trigger* y el cierre diario, cada escritor con su ruta y línea.

⏱️ **30 segundos** — `products`: `InventoryService.take` y `ProductService.save` más el *trigger*; `orders`: `OrderService.create` y el *dirty checking* de `PaymentService.pay` y `OrderService.cancel`; `order_lines`: la cascada de `Order`; `payments`: `PaymentService`; `notifications`: `OrderService.cancel`; `batch_runs`: `DailyCloseJob`.

🗣️ **2 minutos** — Las líneas salen del `grep` de la sección 8 y de las de `setStatus` en `PaymentService` (`:49`, `:59`, `:63`). El *trigger* y el cierre diario se añaden desde el catálogo de la base y desde las anotaciones `@Scheduled`. La tabla muestra que `products` y `orders` tienen varios escritores sin un dueño claro.

🔬 **El detalle** — Esta tabla es la matriz de lectores y escritores del capítulo de base compartida, aplicada dentro de un monolito: el primer paso para dar dueño a cada tabla.

**01 → E8.** 🔥 Para el `psp-simulator` y paga un pedido barato. Pega la respuesta y la línea de log del legado, y explica por qué el estado resultante es indistinguible del caso 666.00 aunque no haya cobro.

⏱️ **30 segundos** — La respuesta es `200` con el pedido `PAYMENT_PENDING` y el log del legado dice «PSP timeout», aunque el banco no cobró nada.

🗣️ **2 minutos** — Con el simulador parado, Toxiproxy sigue aceptando la conexión en `:38185` y la cierra al no poder llegar al banco. El cliente HTTP del legado lo recibe como error al leer la respuesta, una `RestClientException`, y el `catch` lo trata como pendiente. El estado y el log son idénticos al caso 666.00, en el que sí hubo cobro.

🔬 **El detalle** — Dos situaciones opuestas —cobrado sin respuesta y no cobrado— terminan en el mismo estado y con el mismo mensaje. Sin distinguirlas, nadie puede reconciliar con seguridad: es el argumento para el estado incierto explícito y la consulta por clave del taller 07.

---
## 📖 02 — Los errores escondidos

### Preguntas

**02 → 1.** ¿Por qué un `200` con `{"error"}` obliga al cliente a conocer detalles del servidor? 🟢

⏱️ **30 segundos** — Porque el cliente tiene que saber que existe un campo `error`, qué textos puede traer y en qué respuestas buscarlo: conocimiento que no está en HTTP ni en ningún documento.

🗣️ **2 minutos** — HTTP ya tiene una forma estándar de decir que algo falló: el código de estado. Si el servidor responde `200` también a los fallos, cada cliente tiene que inspeccionar cada cuerpo y reconocer mensajes en texto libre. Cuando el servidor cambia un mensaje, los clientes que lo comparaban dejan de reconocer el error sin que nada falle en la compilación ni en los logs.

🔬 **El detalle** — También se pierde la ayuda de la infraestructura: proxies, balanceadores, métricas de errores y reintentos automáticos miran el código de estado. Con `200` para todo, los paneles dicen que no hay errores.

**02 → 2.** ¿Qué información entrega la traza del `500` y a quién le sirve? 🟢

⏱️ **30 segundos** — La estructura de paquetes y clases, los números de línea, la versión del JDK y la cadena de filtros de seguridad. Le sirve a quien depura el servidor, y se la entrega a todos los clientes, incluidos los atacantes.

🗣️ **2 minutos** — La traza es información de diagnóstico interno. En el cuerpo de la respuesta, un cliente legítimo no puede hacer nada con ella y un atacante obtiene el mapa de la aplicación y de sus dependencias. El diagnóstico sigue siendo necesario, pero su lugar es el log, correlacionado con un identificador que la respuesta pueda devolver.

🔬 **El detalle** — Boot 4 lo controla con `spring.web.error.include-stacktrace`; el valor por defecto es `never`. El legado lo puso en `always` a propósito, «para depurar en producción», que es como suele llegar ahí.

**02 → 3.** ¿Qué campos de la respuesta de un pedido no deberían salir nunca, y por qué salen? 🟢

⏱️ **30 segundos** — `customer.passwordHash`, los `id` internos de las líneas y, en general, cualquier detalle del modelo de persistencia. Salen porque el controlador devuelve la entidad JPA y Jackson serializa todos sus *getters*.

🗣️ **2 minutos** — No hay una decisión de qué publicar: la forma de la respuesta es la forma de la clase. El hash de bcrypt no es la contraseña, pero permite ataques de diccionario fuera de línea, y no tiene ninguna razón para salir. Los `id` de las líneas atan al cliente a claves que la base podría cambiar.

🔬 **El detalle** — La corrección no es añadir `@JsonIgnore` campo a campo, que obliga a recordar cada columna nueva, sino devolver un DTO que diga qué se publica. Es lo que hace el taller 04.

**02 → 4.** ¿Qué es *open-in-view* y qué papel juega en que el `GET` funcione antes del cierre diario? 🟢

⏱️ **30 segundos** — Es mantener abierta la sesión de Hibernate durante toda la petición HTTP, incluida la serialización de la respuesta. Gracias a eso, las relaciones perezosas se cargan cuando Jackson las toca.

🗣️ **2 minutos** — Spring Boot lo activa por defecto y avisa al arrancar. Cuando el `GET` carga el pedido de la base dentro de la petición, `customer` es un proxy perezoso, pero la sesión sigue abierta al serializar y Jackson lo inicializa sin error. Por eso el mismo código funciona o falla según de dónde venga la entidad.

🔬 **El detalle** — Es cómodo y esconde consultas: cada relación perezosa tocada durante la serialización es un `SELECT` extra que nadie escribió. Por eso suele desactivarse en código nuevo, y por eso su presencia en un legado es un dato a registrar.

**02 → 5.** ¿Por qué el mismo `GET /api/v1/orders/{id}` responde `200` o `500` según la hora? 🟡

⏱️ **30 segundos** — Porque después del cierre diario el pedido sale de una caché llenada fuera de cualquier petición, y su `customer` es un proxy sin sesión que Jackson no puede inicializar.

🗣️ **2 minutos** — `DailyCloseJob` carga los pedidos del día, los guarda en `OrderCache` y termina; su sesión se cierra. `OrderService.findEntity` consulta la caché antes que la base. Si el pedido está en la caché, se serializa una entidad desconectada con una relación sin cargar y la respuesta es `500`; si no, sale de la base con sesión y responde `200`.

🔬 **El detalle** — El error depende de un estado invisible para el cliente —si el job corrió desde que se creó el pedido—, y por eso parece intermitente. Una caché de entidades JPA es casi siempre una fuente de este tipo de fallo.

**02 → 6.** ¿Por qué el frontend muestra «Pedido creado: undefined» y no un error? 🟡

⏱️ **30 segundos** — Porque el legado respondió `200` y el cliente, al ver `res.ok`, trató el cuerpo como un pedido; `order.id` no existe y se muestra `undefined`.

🗣️ **2 minutos** — El cliente hace lo correcto según HTTP: si el estado es de éxito, el cuerpo es el recurso pedido. El legado rompe esa suposición metiendo el error en un `200`. `created(order)` interpola `order.id` y `order.status`, que no existen en `{"error": ...}`, y el usuario lee que su pedido se creó.

🔬 **El detalle** — TypeScript no ayuda: el tipo `Order` es una promesa del programador sobre la respuesta, no una comprobación en ejecución. Sin validación en runtime, la mentira del servidor llega intacta a la interfaz.

**02 → 7.** ¿Por qué ver un pedido inexistente deja la pantalla en blanco? 🟡

⏱️ **30 segundos** — Porque el legado responde `200 {"error":"Order not found"}`, la interfaz lo guarda como pedido, y al pintar sus líneas `order.lines.map` falla; un error de renderizado no capturado hace que React desmonte todo el árbol.

🗣️ **2 minutos** — React 19 elimina la interfaz cuando un componente lanza durante el renderizado y ningún *error boundary* lo captura. La captura en Chrome lo muestra: `#root` sin hijos y el `TypeError` en la consola. Un usuario ve una página en blanco sin ninguna explicación.

🔬 **El detalle** — Un *error boundary* evitaría la pantalla en blanco, pero no el problema: seguiría mostrando un pedido que no existe como si fuera un fallo de la interfaz. La causa está en el contrato.

**02 → 8.** ¿Qué dicen `@JsonIgnore` en `OrderLine.order` y `@JsonIgnoreProperties` en `User` sobre la historia del código? 🟡

⏱️ **30 segundos** — Que alguien serializó entidades, se topó con una recursión infinita y con un proxy de Hibernate que Jackson no sabía serializar, y los tapó uno a uno en lugar de cambiar la decisión de fondo.

🗣️ **2 minutos** — `@JsonIgnore` en `OrderLine.order` corta el ciclo pedido → línea → pedido; `@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})` en `User` evita el error de serializar el proxy de Hibernate. Cada anotación es la marca de un incidente, y juntas cuentan que la API se construyó serializando el modelo de persistencia.

🔬 **El detalle** — Las anotaciones de serialización dentro de las entidades mezclan dos contratos —el de la base y el de la API— en una clase. Cuando aparecen, conviene buscar qué otros parches esconden la misma decisión.

**02 → 9.** ¿Por qué el orden alfabético de los campos del JSON es también parte del contrato accidental? 🟡

⏱️ **30 segundos** — Porque ningún cliente lo pidió ni nadie lo decidió: es el comportamiento por defecto de Jackson 3 en Spring Boot 4, y un cliente que dependa de ese orden se rompe si cambia la librería o su configuración.

🗣️ **2 minutos** — JSON no garantiza orden de campos, pero los clientes a veces dependen de él sin saberlo: comparaciones de texto, instantáneas en pruebas, *parsers* manuales. En este legado, el orden alfabético apareció al actualizar el framework, no por una decisión de diseño. Todo lo que sale por la API sin decidirlo es contrato accidental.

🔬 **El detalle** — Por eso las pruebas de contrato comparan campos por nombre y valor, no el texto completo de la respuesta; la caracterización del taller 03 sigue esa regla.

**02 → 10.** Un compañero propone `FetchType.EAGER` en `Order.customer` para quitar la excepción. ¿Qué arregla y qué no? 🟠

⏱️ **30 segundos** — Quita la excepción, porque `customer` se carga siempre, pero añade una consulta o un *join* en cada carga de pedido y deja intacto el defecto real: servir entidades desde una caché sin sesión.

🗣️ **2 minutos** — Con `EAGER`, la entidad de la caché ya trae el cliente y Jackson no necesita sesión. Pero cada lectura de pedidos, incluidas las del informe y los listados, carga también el usuario, y la respuesta sigue publicando el hash de la contraseña. El siguiente campo perezoso que se toque volverá a fallar.

🔬 **El detalle** — Las correcciones de fondo son dos: no cachear entidades JPA sino vistas ya construidas, y no serializar entidades sino DTO. Las dos llegan en los talleres 04 y 08.

**02 → 11.** ¿Qué ocurrirá con este frontend cuando el taller 04 devuelva códigos de estado reales? 🟠

⏱️ **30 segundos** — Dejará de mostrar errores como éxitos, pero fallará en los caminos que dependían de la forma vieja: la lista de productos cambia a `items`, el dinero pasa a objeto y los errores llegan con otro formato.

🗣️ **2 minutos** — Con `problem+json` y códigos reales, `res.ok` será falso ante un error y el cliente mostrará `message`, que en `problem+json` no existe: tendrá que leer `detail` o `title`. Además, las formas de éxito cambian con los DTO del contrato. El frontend que aprendió la API sucia se rompe al limpiarla, y el taller 04 lo migra.

🔬 **El detalle** — Es la lección de la sección: corregir un contrato accidental rompe a sus clientes. Por eso el taller 04 nombra la versión y discute migrar clientes de uno en uno.

**02 → 12.** ¿Por qué el `500` de un SKU inexistente y el `200` de un SKU sin stock son un problema de contrato y no solo de código? 🟠

⏱️ **30 segundos** — Porque son dos respuestas distintas para dos variantes del mismo error de entrada, y el cliente solo puede distinguirlas conociendo cómo está escrito el servidor por dentro.

🗣️ **2 minutos** — Para el cliente, «el SKU no existe» y «el SKU no tiene stock» son errores del pedido que conviene explicar al usuario. El legado los separa por accidente: uno lo previó y lo convirtió en `LegacyException`, el otro no y llegó como `NullPointerException`. Un contrato explícito los definiría como `404` y `409` con códigos estables.

🔬 **El detalle** — Un cambio interno —validar el SKU antes— alteraría el código de estado de una respuesta pública. Sin contrato, cualquier refactor puede ser un cambio de API.

**02 → 13.** Diseña la migración de los clientes del legado a un contrato con errores reales sin romperlos a todos el mismo día. 🔴

⏱️ **30 segundos** — Publicando la versión nueva como contrato nombrado, manteniendo la vieja mientras haya clientes, y migrándolos de uno en uno con medición del uso de cada versión.

🗣️ **2 minutos** — El legado era un «v0» sin nombre. La API corregida nace como `v1` con su `openapi.yaml`. Durante la transición, el servidor sirve la forma vieja a quien no la pida explícitamente, por ejemplo con una cabecera o una *feature flag* por cliente, y registra qué cliente usa qué. Cuando un cliente está migrado y probado, se corta su camino viejo; cuando no queda ninguno, se retira.

🔬 **El detalle** — El taller 04 toma una decisión más simple y la hace visible: corregir en un único manejador global y romper al frontend a sabiendas. La alternativa gradual es la que se usa cuando los clientes no están bajo el control del mismo equipo.

### Ejercicios

**02 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un usuario sin token recibe `200 {"error":"Not logged in"}`? Responde con rutas de `laboratorio/estados/02/`.

⏱️ **30 segundos** — En `laboratorio/estados/02/legacy/src/main/java/dev/mono/legacy/config/SecurityConfig.java:65`, dentro del *entry point* de autenticación de la cadena de seguridad.

🗣️ **2 minutos** — La búsqueda de `Not logged in` en el código lleva directo a la línea. El *entry point* se registra dos veces, en `oauth2ResourceServer` y en `exceptionHandling`, y en las dos pone el estado en `200` antes de escribir el cuerpo. Es la única respuesta de error del legado que no pasa por un controlador.

🔬 **El detalle** — Las respuestas de seguridad no pasan por los `@RestControllerAdvice`: se escriben en los filtros. Cuando el taller 04 corrija los errores, tendrá que corregir también este punto aparte.

**02 → E2.** 🟢 Provoca un `400` enviando un cuerpo que no es JSON a `POST /api/v1/orders` con `curl`. Pega la respuesta y di qué campos revelan la implementación.

⏱️ **30 segundos** — `400` con `timestamp`, `status`, `error`, `trace`, `message` y `path`; `trace` y `message` revelan que el legado usa Spring MVC con Jackson (`HttpMessageNotReadableException`, «Unrecognized token»).

🗣️ **2 minutos** — Con `curl -X POST` y `-d 'esto no es json'` sobre `/api/v1/orders`, con un token válido, el error lo produce el framework antes de llegar al controlador. Es el único error de cliente del legado que sale con un código `4xx` real, porque no lo escribió nadie: lo generó Spring.

🔬 **El detalle** — El mensaje del parser cita el token recibido: en APIs que reciben datos sensibles, eso puede devolver al cliente fragmentos de su propia entrada en los logs de proxies intermedios.

**02 → E3.** 🟡 Arranca el legado con `lab.py legacy --daily-close-ms 5000` y repite `lab.py lazy`. ¿Cuánto tarda ahora en aparecer el `500` y qué dice eso de un error «intermitente»?

⏱️ **30 segundos** — Tarda como mucho unos 5 s: el `500` aparece en cuanto el cierre diario vuelve a correr después de crear el pedido.

🗣️ **2 minutos** — El «error intermitente» es determinista: depende de si el job corrió entre la creación del pedido y su lectura. Al acortar el intervalo, la probabilidad de verlo se acerca a uno. Un error que parece aleatorio suele ser un estado que no se está mirando.

🔬 **El detalle** — Para diagnosticar un fallo intermitente conviene buscar qué cambia con el tiempo en el proceso —cachés, jobs, *pools*— y hacerlo más frecuente, como aquí, para convertirlo en reproducible.

**02 → E4.** 🟡 **Orientación en código ajeno.** ¿Qué línea de `OrderService` consulta la caché antes que la base, y qué línea de `DailyCloseJob` la llena? Explica por qué la entidad de la caché no tiene sesión.

⏱️ **30 segundos** — `OrderService.findEntity` consulta la caché en `laboratorio/estados/02/legacy/src/main/java/dev/mono/legacy/service/OrderService.java:71`; `DailyCloseJob` la vacía y la llena en `service/DailyCloseJob.java:40` y la línea siguiente.

🗣️ **2 minutos** — El job carga los pedidos con `orders.findByCreatedAtAfter(...)` fuera de cualquier petición y sin `@Transactional`: la sesión de Hibernate dura lo que dura esa consulta. Al terminar, las entidades quedan desconectadas y sus relaciones perezosas, sin cargar. La caché guarda esas entidades y las sirve más tarde a peticiones que ya no pueden inicializarlas.

🔬 **El detalle** — Las rutas y líneas de un taller citan el estado congelado para que no se muevan cuando el código cambie en talleres posteriores.

**02 → E5.** 🟡 Añade a `frontend/src/view.ts` una comprobación que muestre «❌ No se pudo crear el pedido» si la respuesta trae `error`. Corre `front-smoke` y explica por qué el arreglo acopla más el cliente al servidor.

⏱️ **30 segundos** — `front-smoke` pasa a mostrar «❌ No se pudo crear el pedido» para `SKU-004`; el arreglo funciona, y acopla el cliente a la convención privada del legado.

🗣️ **2 minutos** — La comprobación mira si el cuerpo tiene `error`, algo que solo tiene sentido para este servidor. Cuando el taller 04 cambie a `problem+json`, esa rama no se ejecutará nunca y quedará como código muerto, o peor, se usará para decidir algo equivocado. El cliente ha aprendido un accidente más.

🔬 **El detalle** — Es el acoplamiento del capítulo de contratos en su forma más pequeña: el cliente codifica un detalle del proveedor, y el proveedor ya no puede cambiarlo sin coordinar.

**02 → E6.** 🟠 Añade un *error boundary* a `App.tsx` y comprueba que ver un pedido inexistente ya no deja la pantalla en blanco. ¿Qué problema resuelve y cuál sigue ahí?

⏱️ **30 segundos** — El *error boundary* sustituye la pantalla en blanco por un mensaje de fallo, pero la interfaz sigue creyendo que recibió un pedido: el problema de fondo, el `200` con error, sigue ahí.

🗣️ **2 minutos** — Un componente de clase con `getDerivedStateFromError` o `componentDidCatch` alrededor del detalle captura el `TypeError` y muestra una alternativa. Eso protege al resto de la aplicación, que es su propósito. Pero el mensaje dirá «algo salió mal en la interfaz» cuando lo que pasó es que el pedido no existe.

🔬 **El detalle** — Los *error boundaries* son una defensa general que vale la pena tener; no son un sustituto de un contrato que diga la verdad sobre el resultado.

**02 → E7.** 🟠 Lista todos los mensajes de error distintos que puede devolver el legado buscando en el código, y agrupa los que un cliente debería distinguir. Es el borrador de los `code` del taller 04.

⏱️ **30 segundos** — Una lista del orden de quince mensajes: los de `LegacyException`, los `Only operators…`, `Not logged in`, `Order not found`, `Product … does not exist`, más los errores del framework. Agrupados: credenciales, no autenticado, prohibido, no encontrado, sin stock, estado no válido y validación.

🗣️ **2 minutos** — Se obtiene buscando `LegacyException(`, `Json.error(` y los textos entre comillas en los controladores y servicios. Al agruparlos por lo que el cliente necesita decidir, aparecen los `code` del contrato: `INVALID_CREDENTIALS`, `UNAUTHENTICATED`, `FORBIDDEN`, `ORDER_NOT_FOUND`, `PRODUCT_NOT_FOUND`, `INSUFFICIENT_INVENTORY`, `ORDER_NOT_PAYABLE`, `ORDER_NOT_CANCELLABLE`, `VALIDATION_FAILED`.

🔬 **El detalle** — Los errores del framework —el `400` de JSON mal formado, el de un UUID inválido— no aparecen en la búsqueda del código, y son los que más a menudo se olvidan al diseñar el contrato.

**02 → E8.** 🔥 Cambia `spring.web.error.include-stacktrace` a `never`, reinicia y repite `lab.py trace` y `front-smoke`. ¿Qué mejora, qué sigue viéndose y por qué no es la corrección del taller 04?

⏱️ **30 segundos** — Desaparece la traza del cuerpo, pero siguen el `500` para un SKU inexistente, el `message` con el texto de la `NullPointerException` y todos los `200` con error.

🗣️ **2 minutos** — Con `never`, Boot deja de añadir `trace`, y `front-smoke` sigue mostrando el mismo `❌ Error 500: Cannot invoke …` porque el `message` sigue incluido. Se cierra una fuga, no el problema de contrato: el cliente sigue sin códigos estables ni una forma común de error.

🔬 **El detalle** — Es un buen primer paso de higiene, que puede hacerse el primer día en producción; no sustituye al manejador de errores del taller 04, que decide qué se publica en cada caso.

---
## 📖 03 — Caracterización

### Preguntas

**03 → 1.** ¿Qué afirma una prueba de caracterización y qué no afirma? 🟢

⏱️ **30 segundos** — Afirma que el sistema sigue haciendo lo mismo que cuando se escribió la prueba. No afirma que eso sea correcto.

🗣️ **2 minutos** — Es una fotografía del comportamiento observable, útil precisamente cuando no hay especificación: cualquier cambio queda en rojo y alguien tiene que decidir si era buscado. Por eso congela también los defectos. Lo correcto se define aparte, con un contrato, y se llega a él cambiando la suite a propósito.

🔬 **El detalle** — El término es de Michael Feathers, en *Working Effectively with Legacy Code*: la prueba caracteriza el comportamiento real para poder cambiar el código con red.

**03 → 2.** ¿Por qué la suite congela el `200` con error y el hash de la contraseña si son defectos? 🟢

⏱️ **30 segundos** — Porque hoy los clientes dependen de ellos, y cambiarlos es un cambio de contrato que tiene que decidirse, no ocurrir como efecto lateral de un refactor.

🗣️ **2 minutos** — Si la suite solo congelara lo correcto, un cambio que arreglara por accidente el `200` con error pasaría en verde y rompería al frontend del taller 02 sin aviso. Congelado y marcado con un comentario, el defecto se cambia en el taller 04 conscientemente, con la suite en rojo en el lugar esperado y el cliente migrado.

🔬 **El detalle** — El comentario «defecto congelado» es lo que distingue una caracterización de una especificación equivocada: dice a quien lea que la aserción describe lo que hay, no lo que se quiere.

**03 → 3.** ¿Por qué `lab.py suite` siembra antes de correr y usa `--jobs 1`? 🟢

⏱️ **30 segundos** — Porque los archivos comparten estado: crean pedidos y consumen stock. Sembrar da un punto de partida conocido y correr en orden evita que dos archivos se pisen.

🗣️ **2 minutos** — Las aserciones usan valores absolutos —stock 18, stock 96, siete pedidos— que solo tienen sentido si se sabe de dónde se parte y qué ocurrió antes. `hurl` no resta: la suite razona la aritmética y fija el orden. Con varios archivos en paralelo, los valores dependerían de qué terminó primero.

🔬 **El detalle** — Es un compromiso: la suite es más lenta y sus archivos no son independientes. El ejercicio 4 muestra el precio: un cambio en la semilla falla en cascada.

**03 → 4.** ¿Por qué se afirma campo por campo en lugar de comparar el cuerpo completo? 🟢

⏱️ **30 segundos** — Porque así la suite sobrevive a cambios que no le importan a un cliente —orden de campos, campos nuevos, espacios— y falla solo por lo que sí importa.

🗣️ **2 minutos** — Comparar el cuerpo completo congelaría el orden alfabético de Jackson, la fecha de creación y los identificadores generados, que cambian en cada corrida. Una suite así falla siempre o se «arregla» regenerando la salida, que es lo mismo que no tener suite.

🔬 **El detalle** — Lo que no se puede fijar por valor se fija por forma: `exists`, `startsWith`, `count`, o se captura para usarlo después.

**03 → 5.** ¿Qué dice la suite en rojo tras cambiar el mensaje de stock, y qué no dice? 🟡

⏱️ **30 segundos** — Dice que un cliente ve un cambio: el mensaje de error de stock es distinto. No dice si el cambio es bueno ni si algún cliente concreto se rompe.

🗣️ **2 minutos** — Para este legado, el texto del error es la única forma que tiene un cliente de reconocer el fallo; el taller 02 lo mostró. La suite en rojo obliga a decidir: si el mensaje nuevo es mejor, se actualiza la aserción y se avisa a los clientes; si nadie sabía que se estaba cambiando, se revierte.

🔬 **El detalle** — Que un cambio de texto rompa la suite no es fragilidad de la suite: es la medida exacta del acoplamiento que tiene la API sin códigos estables.

**03 → 6.** ¿Por qué el valor 18 de `SKU-001` se razona desde la semilla y no se copia de la salida? 🟡

⏱️ **30 segundos** — Porque un valor copiado de la salida congela también cualquier error del sistema o de quien escribe la suite; un valor razonado tiene una explicación que se puede revisar.

🗣️ **2 minutos** — 20 unidades en la semilla menos 2 del primer pedido son 18. Si el legado respondiera 17 por un defecto, una suite que copiara la salida lo daría por bueno. El taller vivió el caso inverso: un 9 escrito de memoria donde tocaba 7, detectado al razonar sobre la semilla.

🔬 **El detalle** — Razonar los valores cuesta más que copiarlos, y es lo que hace que la caracterización sirva también para encontrar defectos, no solo para detectar cambios.

**03 → 7.** ¿Por qué el `500` intermitente del taller 02 no entra en la suite? 🟡

⏱️ **30 segundos** — Porque depende de si el cierre diario corrió entre la creación y la lectura del pedido, y eso no se controla con peticiones HTTP.

🗣️ **2 minutos** — Una aserción que a veces pasa y a veces falla enseña a ignorar el rojo. Para congelar ese comportamiento hace falta controlar el tiempo —el intervalo del job— o forzar el escenario, como propone el ejercicio 6. Mientras tanto, la suite declara la precondición: el legado arranca con el cierre diario lejos.

🔬 **El detalle** — Dejar algo fuera de la caracterización es una decisión que se escribe; el riesgo es olvidar que existe. Aquí queda registrado en el taller 02 y en la sección 9.

**03 → 8.** ¿Qué hace `contains "java.lang.NullPointerException"` que no haría comparar la traza entera? 🟡

⏱️ **30 segundos** — Comprueba que la traza está y qué excepción es, sin fijar números de línea ni marcos que cambian con cualquier edición del código o del framework.

🗣️ **2 minutos** — La traza tiene más de cien líneas con números de línea de clases propias y de Spring. Compararla entera haría que cualquier cambio —añadir una línea en `OrderService`, actualizar Spring— rompiera la suite sin que el cliente notara nada distinto. `contains` fija lo que el cliente sí ve: que hay un `500` con una traza de una `NullPointerException`.

🔬 **El detalle** — Elegir la granularidad de cada aserción es decidir qué cambios se consideran del contrato. Aquí, la presencia de la traza sí; su contenido exacto, no.

**03 → 9.** La suite falla dos de cada tres veces con el cierre diario a 50 ms. ¿Es un problema de la suite o del legado? 🟡

⏱️ **30 segundos** — Del legado: su respuesta depende del tiempo transcurrido desde el último job. La suite solo lo hizo visible.

🗣️ **2 minutos** — Con 50 ms, el job llena la caché con frecuencia y el `GET` del pedido recién creado sale sin sesión: `500`. Con 30 s pasaría casi siempre y fallaría de vez en cuando en CI, que es la peor manera de descubrirlo. La suite hace bien en fallar; lo que corresponde es controlar la precondición y registrar el defecto.

🔬 **El detalle** — Cuando una suite de caracterización es inestable, lo primero es preguntar qué estado oculto del sistema cambia entre corridas, antes de tocar la suite.

**03 → 10.** ¿Qué relación tendrá esta suite con `hurl/v1` del taller 04? 🟠

⏱️ **30 segundos** — `hurl/v1` será el contrato corregido; `hurl/legacy` es la foto de lo que hay. El taller 04 pasará de una a otra, y `hurl/legacy` dejará de pasar en los puntos donde el contrato cambie a propósito.

🗣️ **2 minutos** — Donde el comportamiento se mantiene —el pedido válido, el stock, el pago autorizado—, `v1` afirmará lo mismo con la forma nueva. Donde cambia —errores, formas de dinero, entidades—, la diferencia entre las dos suites es la lista exacta de lo que se rompe a los clientes. Esa lista es el plan de migración.

🔬 **El detalle** — Por eso `hurl/legacy` no se borra al crear `v1`: se conserva mientras haya clientes del comportamiento viejo, y documenta qué cambió.

**03 → 11.** Un cambio del legado rompe 12 aserciones de la suite. ¿Cómo decides cuáles son regresiones y cuáles cambios deseados? 🟠

⏱️ **30 segundos** — Mirando cada fallo contra una lista de cambios buscados: lo que coincide con un cambio decidido se actualiza; lo que no, es una regresión hasta que alguien demuestre lo contrario.

🗣️ **2 minutos** — Primero se agrupan los fallos por causa: a menudo doce aserciones rotas son dos cambios, porque un fallo temprano arrastra a los siguientes archivos. Después, cada causa se contrasta con lo que el cambio pretendía. La suite no decide; obliga a que alguien lo haga explícitamente y deje rastro en el historial de la suite.

🔬 **El detalle** — El ejercicio 4 muestra el efecto cascada: un cambio de precio en la semilla falla en cinco archivos, con una sola causa.

**03 → 12.** ¿Qué parte del comportamiento del legado no puede caracterizar una suite HTTP? 🟠

⏱️ **30 segundos** — Todo lo que no se ve por HTTP o no es determinista: escrituras que el cliente no consulta, efectos en otros sistemas, rendimiento, concurrencia y comportamiento que depende del tiempo.

🗣️ **2 minutos** — La suite no sabe si el legado escribió una notificación de más que nadie lista, ni cuántas conexiones usa, ni qué pasa con dos pedidos simultáneos. Para eso hacen falta consultas a la base, pruebas de concurrencia o pruebas de carga. La caracterización HTTP cubre el contrato observable; los riesgos internos necesitan otras pruebas.

🔬 **El detalle** — Es la tabla de riesgos del capítulo de estrategia de pruebas aplicada al legado: cada riesgo, la prueba más cercana que puede fallar por él.

**03 → 13.** Tienes que caracterizar un legado con 300 rutas y una semana. ¿Cómo eliges qué congelar primero? 🔴

⏱️ **30 segundos** — Por uso y por riesgo del cambio que viene: primero las rutas que más usan los clientes y las que se van a tocar pronto, y solo después el resto.

🗣️ **2 minutos** — Con tráfico real o logs de acceso se ordenan las rutas por volumen; con el plan de trabajo se marcan las que se van a modificar. Se caracterizan primero las que están en las dos listas, con sus caminos de error. Las 300 rutas no se congelan en una semana, y no hace falta: se congela lo que protege el siguiente cambio.

🔬 **El detalle** — Se puede acelerar grabando tráfico real y convirtiéndolo en pruebas, con cuidado de anonimizar datos y de razonar los valores esperados en lugar de copiarlos sin mirar.

### Ejercicios

**03 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea de la suite se congela que un login incorrecto responde distinto según exista o no el correo? Responde con rutas de `laboratorio/estados/03/`.

⏱️ **30 segundos** — En `laboratorio/estados/03/contrato/hurl/legacy/02-auth.hurl:20` («Wrong password») y `:27` («User not found»).

🗣️ **2 minutos** — Las dos peticiones usan credenciales incorrectas, una con un correo existente y otra con uno inexistente, y afirman mensajes distintos. El comentario que las precede las marca como defecto congelado: el contrato del taller 04 las unifica.

🔬 **El detalle** — Encontrarlo exige buscar por el texto del mensaje, no por la ruta: las dos peticiones van a `/api/v1/auth/login`.

**03 → E2.** 🟢 Aplica el arreglo inocente de la sección 8, corre la suite, pega la salida y reviértelo.

⏱️ **30 segundos** — La suite falla en `04-orders.hurl:44` con «Insufficient stock for SKU-004» frente a «Not enough stock for SKU-004»; tras el `sed` inverso vuelve a verde.

🗣️ **2 minutos** — Es la salida de la sección 8. Hay que reiniciar el legado tras cada cambio para que el JAR recompilado esté en marcha, y con la precondición del cierre diario lejano. Solo falla `04-orders.hurl`: es el único archivo que provoca ese error.

🔬 **El detalle** — El diff contra el estado congelado confirma que el cambio fue de una sola línea; la suite confirma que esa línea es visible para un cliente.

**03 → E3.** 🟡 Añade a `04-orders.hurl` una aserción que congele que la respuesta de un pedido trae `payments` como lista vacía y que `lines[0].id` es un número. Córrela y explica qué defecto congela cada una.

⏱️ **30 segundos** — `jsonpath "$.payments" count == 0` congela que la entidad trae la relación de pagos; `jsonpath "$.lines[0].id" isInteger` congela que se publica la clave interna de la línea.

🗣️ **2 minutos** — Las dos aserciones describen campos que existen solo porque se serializa la entidad JPA. El taller 04, con DTO, los quitará; la suite de caracterización fallará ahí y esa diferencia documentará el cambio de forma.

🔬 **El detalle** — Congelar un campo que se piensa eliminar parece contradictorio, pero es lo que hace visible su eliminación: sin la aserción, el cambio pasaría en silencio.

**03 → E4.** 🟡 Cambia el precio de `SKU-001` en `seed.sql` a 50.00 y corre la suite. ¿Cuántas aserciones fallan y qué te dice eso sobre la dependencia de la suite con la semilla?

⏱️ **30 segundos** — Fallan cinco de los siete archivos: el precio de `SKU-001` aparece en el catálogo, en el total del primer pedido y en el importe del pago, y cada archivo que se detiene en su primer fallo deja el estado distinto para los siguientes.

🗣️ **2 minutos** — El primer fallo es `03-products.hurl:22` (50.0 en lugar de 49.9); `04-orders.hurl` falla en el total (109.9) y en el precio de línea; `05-payment.hurl`, en el importe; `06-cancel.hurl` y `07-reports.hurl` fallan en cascada porque los archivos anteriores no crearon los pedidos que esperaban. Un solo cambio en la semilla, cinco archivos en rojo.

🔬 **El detalle** — Es el coste de una suite con estado compartido: sus fallos no son independientes. Por eso, ante muchos rojos, lo primero es buscar el primero.

**03 → E5.** 🟡 **Orientación en código ajeno.** Encuentra en la suite la aserción que depende del *trigger* de PostgreSQL. ¿Qué pasaría con ella si el legado corriera contra SQLite?

⏱️ **30 segundos** — La aserción `jsonpath "$.stock" == 96` después de la cancelación en `06-cancel.hurl`: depende del *trigger* `orders_restore_stock`. Contra SQLite, el *trigger* no existe y el stock no volvería.

🗣️ **2 minutos** — En Java nadie devuelve el stock al cancelar; lo hace la base. `SchemaFixer` solo crea el *trigger* si la URL es de PostgreSQL. Con SQLite, la suite fallaría en esa aserción con 92, y la prueba del legado contra SQLite no lo detecta porque no prueba la cancelación con stock.

🔬 **El detalle** — Es el puente al taller 05: una prueba que corre contra otra base no prueba lo que la base hace por su cuenta.

**03 → E6.** 🟠 Escribe un escenario que congele también el `500` de la caché, de forma reproducible: con el legado a 50 ms, crea un pedido, espera a que `batch_runs` tenga una fila nueva y pídelo. ¿Dónde pondrías ese escenario y cómo evitarías que haga inestable al resto?

⏱️ **30 segundos** — En un archivo aparte, fuera de `hurl/legacy`, que arranca el legado con su propio intervalo y espera explícitamente a una fila nueva de `batch_runs` antes del `GET`.

🗣️ **2 minutos** — Mezclado con el resto, haría inestable toda la suite o exigiría intervalos distintos para distintos archivos. Separado, se corre a propósito: legado a 50 ms, crear pedido, esperar el job consultando la base y pedir el pedido, afirmando el `500`. Es exactamente lo que hace `lab.py lazy` del taller 02, convertido en prueba.

🔬 **El detalle** — Esperar a una condición observable —una fila nueva— en lugar de dormir un tiempo fijo es lo que hace reproducible una prueba que depende de un proceso en segundo plano.

**03 → E7.** 🟠 Añade `08-edge.hurl` con tres comportamientos del legado que la suite todavía no congela. Justifica por qué cada uno le importa a un cliente.

⏱️ **30 segundos** — Tres candidatos: un pedido de otro cliente responde «Order not found»; una cantidad negativa se rechaza con «Invalid quantity»; y el listado de pedidos del operador incluye los de todos los clientes.

🗣️ **2 minutos** — Cada uno es comportamiento del que un cliente depende: la privacidad de los pedidos, la validación de entrada y lo que ve un operador. Se escriben con el mismo patrón —login, petición, aserciones por campo— y valores razonados desde la semilla y los archivos anteriores.

🔬 **El detalle** — Un buen criterio para elegir qué caracterizar es preguntar qué comportamiento, si cambiara sin aviso, generaría una queja de un cliente.

**03 → E8.** 🔥 Escribe la misma caracterización de `04-orders.hurl` como pruebas JUnit con `RestClient` contra el legado vivo. Compara legibilidad, mantenimiento y lo que cada una deja fuera.

⏱️ **30 segundos** — Las pruebas JUnit son más verbosas y necesitan compilar y conocer el proyecto; `hurl` se lee como peticiones HTTP y no depende del lenguaje del legado. JUnit permite lógica y esperas más ricas; `hurl` deja fuera lo que no sea HTTP.

🗣️ **2 minutos** — Con `RestClient`, cada petición es código con su manejo de JSON y sus aserciones; la ventaja es poder reutilizar utilidades, consultar la base desde la misma prueba o esperar a condiciones complejas. La desventaja es que la caracterización queda atada al proyecto Java y a su build. La suite `hurl` sirve igual si el legado se reescribe en otra plataforma.

🔬 **El detalle** — Para una caracterización previa a una migración, la independencia del lenguaje es decisiva; para pruebas que necesitan inspeccionar el estado interno, las pruebas en el mismo lenguaje ganan.

---

## 📖 04 — El contrato

### Preguntas

**04 → 1.** ¿Qué diferencia hay entre `hurl/legacy` y `hurl/v1`, y cuál es la invariante desde este taller? 🟢

⏱️ **30 segundos** — `hurl/legacy` congela lo que el legado hacía, defectos incluidos; `hurl/v1` afirma lo que promete el contrato. Desde este taller la invariante es `hurl/v1`.

🗣️ **2 minutos** — La caracterización del taller 03 servía para no cambiar nada sin verlo. Este taller cambia la API a propósito, así que `hurl/legacy` cae —seis de siete archivos— y eso es el resultado esperado. `hurl/v1` nace en verde y tiene que seguir así después de cada taller, de 05 a 10: es lo que permite reorganizar el interior sin tocar a los clientes.

🔬 **El detalle** — `hurl/legacy` no se borra. Sigue siendo el registro de la API vieja: sirve para medir qué rompería un cliente que no migró y para escribir el plan de retirada.

**04 → 2.** ¿Qué campos de un `problem+json` vienen de RFC 9457 y para qué sirve `code`? 🟢

⏱️ **30 segundos** — De RFC 9457 vienen `type`, `title`, `status`, `detail` e `instance`. `code` es una extensión propia: un identificador estable con el que el cliente decide.

🗣️ **2 minutos** — `title` y `detail` son texto para humanos y pueden cambiar sin romper nada; `status` agrupa demasiado —hay varios `409` distintos—. `code` enumera los casos que un cliente tiene que distinguir: `INSUFFICIENT_INVENTORY` frente a `ORDER_NOT_PAYABLE`, `UNAUTHENTICATED` frente a `TOKEN_REVOKED`. Está cerrado en una enumeración del contrato, así que un código nuevo es un cambio de contrato.

🔬 **El detalle** — `type` ausente equivale a `about:blank`, y Spring lo omite en ese caso. Usar URIs propias en `type` es la alternativa de la norma; `code` es más cómodo de comparar y es la convención de los tres laboratorios.

**04 → 3.** ¿Por qué `401` y `403` no los produce `ApiErrorHandler`? 🟢

⏱️ **30 segundos** — Porque no llegan a los controladores. Los decide el filtro de seguridad antes de que Spring MVC elija un método, y `@RestControllerAdvice` solo ve excepciones de los controladores.

🗣️ **2 minutos** — La autenticación del token la hace el `BearerTokenAuthenticationFilter` y la autorización, el `AuthorizationFilter`; si fallan, llaman al `AuthenticationEntryPoint` o al `AccessDeniedHandler`. Por eso `SecurityConfig` escribe su propio `problem+json`, con el mismo formato. Hay una excepción: el `403` por rol que el legado todavía comprueba en los controladores sí pasa por `ApiErrorHandler`, porque es una `LegacyException`.

🔬 **El detalle** — Tener dos sitios es el precio de la separación entre filtros y controladores. Se mitiga con el mismo formato en los dos y con la suite, que afirma `code` en los dos casos.

**04 → 4.** ¿Qué publica un DTO que no publicaba la entidad, y qué deja de publicar? 🟢

⏱️ **30 segundos** — Publica lo que el contrato dice y solo eso: `customerId` en lugar del cliente, el dinero como texto y el último pago. Deja de publicar el `passwordHash`, el proxy de Hibernate y las colecciones perezosas.

🗣️ **2 minutos** — Serializar la entidad convertía cada columna y cada relación en API: el hash de la contraseña en el login, `lines[].id` como número interno, `payments` como lista entera. El DTO es un `record` que enumera los campos; si mañana la entidad gana una columna, la API no cambia.

🔬 **El detalle** — El DTO también desacopla el cliente del ciclo de vida de JPA: un campo perezoso sin sesión ya no se descubre al serializar, sino al construir el DTO, dentro del código. Sigue fallando —la caché del taller 08—, pero como `500` sin traza.

**04 → 5.** ¿Por qué el login responde igual a un correo inexistente que a una contraseña equivocada? 🟡

⏱️ **30 segundos** — Para no revelar qué correos existen. Si «usuario no encontrado» y «contraseña incorrecta» se distinguen, cualquiera puede enumerar cuentas.

🗣️ **2 minutos** — El legado devolvía dos mensajes distintos, y la caracterización los congelaba. El contrato los une en `401` `INVALID_CREDENTIALS`, y `AuthService.login` comprueba las dos condiciones en un mismo `if`. La suite lo afirma con dos peticiones: un correo inexistente y una contraseña equivocada.

🔬 **El detalle** — El mensaje es solo una parte: el tiempo de respuesta también puede revelarlo, porque comprobar un hash bcrypt tarda y no comprobarlo es instantáneo. El legado no lo iguala; es un buen ejercicio para un contrato de seguridad más estricto.

**04 → 6.** El contrato muestra `"29.70"` y el legado sigue calculando en `double`. ¿Qué arregló el taller y qué no? 🟡

⏱️ **30 segundos** — Arregló la representación: el dinero sale como `"29.70"`. No arregló el cálculo, que sigue en `double` dentro del legado.

🗣️ **2 minutos** — `Money.of` formatea con `BigDecimal.valueOf(value).setScale(2, HALF_UP)` al salir. Mientras el error acumulado sea menor que medio centavo, el cliente ve el valor correcto; pero las comparaciones internas —`total > 1000`— y las sumas del informe siguen operando con flotantes. El taller 05 cambia el tipo a decimal, y el contrato no tendrá que cambiar.

🔬 **El detalle** — Es un patrón útil: el contrato protege al cliente de la implementación incluso antes de que la implementación sea correcta. También es un riesgo: una API limpia puede ocultar que el dinero se calcula mal por dentro.

**04 → 7.** ¿Qué encontró Prism que `hurl/v1` en verde no encontraba? 🟡

⏱️ **30 segundos** — Que el contrato no declaraba el `400` de `GET /orders/not-a-uuid`. La suite lo afirmaba y pasaba; el documento no lo decía.

🗣️ **2 minutos** — `hurl/v1` prueba comportamiento: cada aserción compara lo que el legado responde con lo que la suite espera. Prism compara cada respuesta con `openapi.yaml`. Como la suite y el contrato se escribieron desde el mismo hermano, heredaron la misma contradicción, y solo la validación contra el documento la mostró.

🔬 **El detalle** — Por eso `lab.py contract` cuenta solo las violaciones de respuesta: las de petición son a propósito, porque la suite manda cuerpos inválidos para comprobar el `400`.

**04 → 8.** ¿Por qué se sustituyó el dominio de los correos al copiar las suites en lugar de añadir usuarios a la semilla? 🟡

⏱️ **30 segundos** — Porque la suite afirma el `customerId` `11111111-…`, y dos usuarios no pueden tener el mismo `id`. Un `ana@hex.local` añadido sería otro cliente con otro identificador.

🗣️ **2 minutos** — Sustituir el dominio al copiar conserva todo lo demás: las rutas, los cuerpos, las aserciones y los identificadores. La sustitución está en la cabecera de cada archivo copiado, junto con el origen y la fecha, para que nadie la confunda con una edición a mano.

🔬 **El detalle** — La alternativa sería parametrizar el correo con una variable de `hurl`. Es más limpia, pero exige tocar las suites originales de otros cursos, y los cursos son independientes.

**04 → 9.** ¿Qué significa `x-enforced-from: "06/07"` y qué riesgo acepta el equipo al escribirlo? 🟡

⏱️ **30 segundos** — Que el contrato declara la cabecera obligatoria, pero el legado solo la hace cumplir desde el taller 07. Hasta entonces la acepta y la ignora.

🗣️ **2 minutos** — El riesgo es que un cliente que lea el contrato crea que repetir un `POST /orders` con la misma clave es seguro, y durante tres talleres no lo es: crea otro pedido. Se acepta porque está escrito en el contrato, en la suite y en el taller, y porque arreglarlo antes rompería la regla de que cada pecado se corrige en su taller dueño.

🔬 **El detalle** — En un sistema real, esa diferencia entre lo declarado y lo cumplido tendría que llegar a los consumidores, no solo al documento: una nota en el cambio de versión, o no publicar la operación hasta que se cumpla.

**04 → 10.** ¿Por qué un `SKU-999` pasa de `500` a `404` y no a `400`? 🟡

⏱️ **30 segundos** — Porque la petición está bien formada: el SKU cumple el patrón `SKU-nnn`. Lo que falla es que ese producto no existe, y eso es un `404`.

🗣️ **2 minutos** — La distinción es entre forma y existencia. `lines: []` o `quantity: 0` son forma: `400` `VALIDATION_FAILED`, sin consultar la base. `SKU-999` pasa la validación y falla al buscarlo: `404` `PRODUCT_NOT_FOUND`. El legado daba `500` porque `InventoryService.take` hacía `findById(...).orElse(null)` y después `p.getStock()`.

🔬 **El detalle** — Algunos contratos usan `422` para «bien formado pero no procesable». El contrato hermano eligió `404` porque el recurso referenciado no existe, y el monolito lo sigue.

**04 → 11.** El frontend dejó de mostrar errores con el contrato nuevo. ¿Es una regresión? 🟠

⏱️ **30 segundos** — No es una regresión: es la rotura anunciada del cambio de contrato. Lo sería si nadie la hubiera medido ni migrado el cliente.

🗣️ **2 minutos** — El frontend buscaba `message` y una lista de productos; el contrato devuelve `detail` y una página. `smoke.ts` lo mostró antes de migrar —el catálogo no se pinta y los errores llegan sin texto— y el mismo cambio migró `api.ts` y `view.ts`. La diferencia con una regresión es que se sabía, se midió y llegó con su corrección.

🔬 **El detalle** — Con un cliente externo no se podría migrar en el mismo cambio. Entonces el plan sería versionar, mantener la API vieja con fecha de retirada y medir quién la sigue usando.

**04 → 12.** Los contratos hexagonal y de microservicios se contradicen en el pedido rechazado. ¿Cómo decidiste y qué harías si un cliente real dependiera de la otra regla? 🟠

⏱️ **30 segundos** — Elegí el hexagonal porque la guía lo declara superconjunto, y dejé comentados en la copia de microservicios los dos bloques que lo contradicen, con la marca `NO CABE`.

🗣️ **2 minutos** — Las dos reglas no pueden convivir: si el rechazo libera el stock, cancelar después ese pedido lo liberaría dos veces, y el hexagonal permite volver a pagar el rechazado. Con un cliente real que dependiera de la otra regla, la decisión no sería mía: habría que preguntarle al negocio qué significa un pago rechazado para la reserva.

🔬 **El detalle** — Técnicamente se podría servir la regla de microservicios en otra versión de la API, pero la reserva es estado compartido: dos reglas sobre el mismo stock según quién llame es una fuente de inconsistencias, no una solución.

**04 → 13.** Un cliente externo que no puedes migrar lee `{"error"}` en un `200`. ¿Cómo publicas este contrato sin romperlo? 🟠

⏱️ **30 segundos** — Sin romperlo, publicando la API nueva al lado de la vieja y dándole una fecha de retirada: la vieja sigue respondiendo `200` con `{"error"}` hasta que el cliente migre.

🗣️ **2 minutos** — Hay varias formas: una ruta nueva (`/api/v2`), un media type negociado o una cabecera que el cliente envía para optar al nuevo formato. La vieja se marca con `Deprecation` y `Sunset`, se mide su uso por cliente y se avisa. El día del corte, si alguien la sigue usando, se decide con datos.

🔬 **El detalle** — Mantener dos contratos cuesta: dos formatos de error, dos suites y lógica de traducción. Por eso la retirada necesita fecha y métrica; sin ellas, la API vieja se queda para siempre.

**04 → 14.** ¿Qué parte del contrato cambiarías si mañana los pedidos se extrajeran a otro proceso, y qué parte no debería cambiar? 🔴

⏱️ **30 segundos** — Cambiaría lo que describe el despliegue —servidores, quizá la autenticación entre procesos—, no las rutas, los cuerpos ni los códigos. Si la extracción obliga a cambiar el contrato público, la extracción está mal planteada.

🗣️ **2 minutos** — El contrato describe capacidades: crear un pedido, pagarlo, cancelarlo. Dónde vive cada una es implementación. Un gateway puede mantener las rutas aunque los pedidos se atiendan en otro proceso, y la suite `v1` sigue siendo la prueba de que nada cambió para el cliente.

🔬 **El detalle** — Lo que sí aparece son nuevos modos de fallo: un pedido que se crea pero cuya reserva tarda, un `503` si el proceso de inventario no responde. El contrato tendrá que declararlos, y ahí se ve el coste de distribuir. Es lo que mide el taller 10.

### Ejercicios

**04 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un token revocado responde `TOKEN_REVOKED` y no `UNAUTHENTICATED`? Responde con rutas de `laboratorio/estados/04/`.

⏱️ **30 segundos** — En `laboratorio/estados/04/legacy/src/main/java/dev/mono/legacy/config/SecurityConfig.java:94`, el método `isRevoked`, que usa `SecurityConfig.java:66` al construir el `401`.

🗣️ **2 minutos** — El validador del decodificador JWT (`SecurityConfig.java:51`–`54`) marca el fallo con el código `token_revoked` (constante en la línea 33). El proveedor JWT de Spring envuelve ese fallo en una `InvalidBearerTokenException` genérica, así que `isRevoked` recorre la cadena de causas hasta la `JwtValidationException` y mira su código.

🔬 **El detalle** — Depender de la cadena de causas es frágil: si Spring cambia cómo envuelve la excepción, se pierde la distinción. La suite lo protege con `jsonpath "$.code" == "TOKEN_REVOKED"` en `02-auth.hurl`.

**04 → E2.** 🟢 Corre `lab.py suite --dir legacy` y cuenta cuántas aserciones de `hurl/legacy` dependían de un defecto marcado como «defecto congelado». ¿Cuántas cayeron por un cambio no anunciado?

⏱️ **30 segundos** — Todas las que caen apuntan a un defecto congelado o a un cambio decidido en la sección 5; ninguna a un cambio no anunciado.

🗣️ **2 minutos** — La corrida se detiene en el primer fallo de cada archivo, así que hay que usar `--all-errors` para contarlas todas. Las primeras en caer son las marcadas como «defecto congelado»: el `user` con su hash, la lista en lugar de página, el `200` con error, el `500` con traza. El resto son consecuencia: un stock distinto porque un pedido que antes fallaba con `200` ahora no se crea.

🔬 **El detalle** — El ejercicio mide la calidad de la caracterización del taller 03: si marcó bien sus defectos, cada rojo tiene una explicación en la tabla de decisiones; un rojo sin explicación sería una regresión real.

**04 → E3.** 🟡 Quita `400` de `getOrder` en `openapi.yaml`, corre `lab.py contract` y pega la violación. Devuélvelo y explica por qué la suite no lo detecta sola.

⏱️ **30 segundos** — Aparece `Violation: response Unable to match the returned status code with those defined in the document: 200,401,404` para `/api/v1/orders/not-a-uuid`.

🗣️ **2 minutos** — La suite no lo detecta porque compara la respuesta con su propia expectativa, `HTTP 400`, y el legado responde `400`. Que el documento lo declare o no le es indiferente. Prism es quien compara la respuesta con el documento.

🔬 **El detalle** — Son dos pruebas de cosas distintas: la suite, que el sistema se comporta como se espera; la validación, que el contrato describe lo que el sistema hace. Hace falta alguna de las dos para cada dirección.

**04 → E4.** 🟡 **Orientación en código ajeno.** Encuentra dónde se construye `errors[].field` para el stock insuficiente. ¿Por qué ese dato no lo puede producir `InventoryService`?

⏱️ **30 segundos** — En `OrderService.create`, `laboratorio/estados/04/legacy/src/main/java/dev/mono/legacy/service/OrderService.java:61`, que atrapa la excepción de `InventoryService.take` y añade `lines[i].quantity`.

🗣️ **2 minutos** — `InventoryService.take` recibe un SKU y una cantidad; no sabe que existe un pedido ni en qué posición está la línea. El índice lo conoce el bucle que recorre las líneas, en `OrderService`. Por eso el enriquecimiento ocurre ahí: cada capa añade lo que sabe.

🔬 **El detalle** — Es un ejemplo pequeño de lo que el taller 06 hará con límites de módulo: `inventory` expone un error en sus términos y `orders` lo traduce a los términos del pedido.

**04 → E5.** 🟡 Haz que `ApiErrorHandler` devuelva la traza en `detail` cuando el perfil activo sea `dev`. Argumenta por qué es peor idea de lo que parece.

⏱️ **30 segundos** — Con `@Profile("dev")` o leyendo el perfil activo en el manejador; técnicamente son pocas líneas.

🗣️ **2 minutos** — Es peor idea de lo que parece por tres razones: los perfiles se filtran a entornos que no son de desarrollo, un cliente empieza a depender del texto de la traza y la traza expone clases, rutas y a veces SQL con datos. El taller 02 mostró las tres cosas con `include-stacktrace: always`, que también se puso «para depurar».

🔬 **El detalle** — La alternativa segura es un identificador de correlación en la respuesta que permita encontrar la traza en el log. Da la misma capacidad de depurar sin publicar la implementación.

**04 → E6.** 🟠 Añade `Deprecation` y `Sunset` a las respuestas de una ruta y escribe el plan de retirada de la API vieja para un cliente externo que lee `{"error"}`: fechas, métricas y qué haces el día del corte.

⏱️ **30 segundos** — `Deprecation` con la fecha desde la que la ruta está obsoleta, `Sunset` con la fecha de retirada y `Link` con `rel="successor-version"` hacia la nueva.

🗣️ **2 minutos** — El plan: publicar la nueva API y la fecha; medir las peticiones a la vieja por cliente (una métrica o un log con el identificador del token); avisar a quien la siga usando a mitad de plazo; el día del corte, si queda tráfico, decidir con el dueño del cliente entre prorrogar con fecha o cortar. Nunca cortar sin mirar el tráfico del día anterior.

🔬 **El detalle** — Las fechas no son el plan: el plan es la métrica. Sin saber quién usa la API vieja, la fecha de retirada es un deseo.

**04 → E7.** 🟠 Lleva a `hurl/v1` un escenario de paginación de pedidos: tres pedidos, `limit=2`, y comprueba que la segunda página empieza en el tercero. ¿Qué pasa con un cursor por desplazamiento si entre las dos lecturas llega un pedido nuevo?

⏱️ **30 segundos** — Se crean tres pedidos, se pide `?limit=2`, se captura `nextCursor` y se pide la segunda página, afirmando que su primer elemento es el pedido más antiguo de los tres.

🗣️ **2 minutos** — Con un cursor por desplazamiento, un pedido nuevo entre las dos lecturas desplaza la lista una posición: la segunda página repite el último elemento de la primera. El orden es del más reciente al más antiguo, así que lo nuevo entra por delante y empuja.

🔬 **El detalle** — La corrección es paginar por clave —`createdAt` e `id` del último elemento— en lugar de por posición. Como el cursor es opaco, el cambio no rompe el contrato: es exactamente para eso que se declaró opaco.

**04 → E8.** 🔥 Genera un cliente TypeScript desde `openapi.yaml` y sustituye `api.ts`. Compara lo que ganas en tipos con lo que pierdes en control del manejo de errores.

⏱️ **30 segundos** — Con un generador como `openapi-typescript` se obtienen los tipos de peticiones y respuestas; con uno que genere también el cliente, las funciones de llamada.

🗣️ **2 minutos** — Se gana que los tipos no se desincronizan del contrato: `unitPrice` como `Money` o `nextCursor` como `string | null` salen del documento. Se pierde control del manejo de errores si el cliente generado lanza excepciones genéricas y hay que envolverlo para leer `code` y `detail`.

🔬 **El detalle** — Un punto medio habitual es generar solo los tipos y mantener a mano la función `call`, que es donde vive la política de errores del cliente.

---

## 📖 05 — SQLite miente

### Preguntas

**05 → 1.** ¿Qué hace `@ServiceConnection` y qué evita configurar a mano? 🟢

⏱️ **30 segundos** — Construye el `DataSource` de las pruebas con la URL, el usuario y la contraseña del contenedor. Evita fijar puertos y copiar propiedades a mano.

🗣️ **2 minutos** — Testcontainers arranca PostgreSQL en un puerto aleatorio y con credenciales propias. Sin `@ServiceConnection` habría que leerlas del contenedor y escribirlas en `spring.datasource.*` con `@DynamicPropertySource`. Con la anotación, Spring Boot reconoce el tipo de contenedor y crea los detalles de conexión.

🔬 **El detalle** — Por eso `SchemaFixer`, que lee `spring.datasource.url` de `application.yaml`, sigue viendo la URL de desarrollo aunque la conexión real vaya al contenedor. Funciona porque solo mira si contiene «postgresql»; es un ejemplo de configuración que miente sobre lo que corre.

**05 → 2.** ¿Por qué `3 × 9.90` no da `29.70` con `double`, y por qué no es un problema de la base? 🟢

⏱️ **30 segundos** — Porque `9.90` no tiene representación exacta en binario: el `double` guarda el valor más cercano, y al multiplicar por tres aparece el error, `29.700000000000003`. Es aritmética de coma flotante, no de la base.

🗣️ **2 minutos** — Cualquier base que guarde un `double` guarda ese mismo error. Por eso `totalIsExact` falló en SQLite y en PostgreSQL con el mismo mensaje. La corrección es el tipo: `BigDecimal` en Java y `numeric` en la base, con escala declarada.

🔬 **El detalle** — Formatear al mostrar, como hacía el contrato del taller 04, esconde el error sin quitarlo: el total guardado y cobrado seguía siendo el valor con error, y una suma de muchos pedidos puede acabar desviándose un centavo.

**05 → 3.** ¿Por qué la prueba de sobreventa pasaba contra SQLite? 🟢

⏱️ **30 segundos** — Porque SQLite admite un solo escritor a la vez y el pool de las pruebas tenía una conexión. Los veinte hilos pasaban en fila y cada uno veía el stock que había dejado el anterior.

🗣️ **2 minutos** — No es que el legado controlara la concurrencia: es que la base de prueba no la permitía. Contra PostgreSQL, con cinco conexiones, los hilos entran en tandas de cinco que leen el mismo stock, restan uno y escriben: cada tanda de cinco pedidos cuesta una unidad y se confirman los 20. La prueba verde no demostraba nada sobre el código.

🔬 **El detalle** — Es la definición de evidencia falsa: una prueba que no puede fallar por el defecto que dice comprobar. Para que valga, la prueba tiene que correr donde el defecto es posible.

**05 → 4.** ¿Qué significan `precision = 12` y `scale = 2`? 🟢

⏱️ **30 segundos** — `precision` es el número total de cifras significativas; `scale`, cuántas van después del punto. `numeric(12,2)` admite hasta diez cifras enteras y dos decimales.

🗣️ **2 minutos** — Con `@Column(precision = 12, scale = 2)` Hibernate genera `numeric(12,2)` en PostgreSQL. Un valor con más decimales se redondea al guardar; uno con más de diez cifras enteras falla. La escala también llega a Java: PostgreSQL devuelve `29.70` con escala 2, no `29.7`.

🔬 **El detalle** — La elección de doce cifras es del dominio, no de la herramienta: alcanza para importes hasta diez mil millones. Un sistema con otras monedas o con más decimales necesitaría otra precisión o guardar unidades menores como enteros.

**05 → 5.** ¿Por qué se compara con el límite del banco con `compareTo` y no con `equals`? 🟡

⏱️ **30 segundos** — Porque `BigDecimal.equals` compara valor **y** escala: `1000.0` no es `equals` a `1000.00`. `compareTo` compara solo el valor.

🗣️ **2 minutos** — Un total leído de la base con escala 2 y un límite escrito como `new BigDecimal("1000")` darían `equals` falso siendo el mismo importe. Con `compareTo(BANK_LIMIT) > 0` la regla es «mayor que mil», sin depender de cómo se escribió cada número.

🔬 **El detalle** — En las pruebas pasa lo contrario: `assertEquals(new BigDecimal("29.70"), total)` usa `equals`, y es a propósito. Así la prueba exige también la escala, que es lo que falló en SQLite.

**05 → 6.** `totalIsExact` pasó a verde en PostgreSQL y a rojo en SQLite con el mismo cambio. ¿Qué dice eso de SQLite? 🟡

⏱️ **30 segundos** — Que SQLite no tiene tipo decimal. Guarda `29.70` como un número real y lo devuelve con otra escala, `29.7`, así que no puede representar el dominio.

🗣️ **2 minutos** — El mismo cambio —dinero en `BigDecimal` con escala 2— arregló la prueba en PostgreSQL y la rompió en SQLite. En SQLite, la afinidad `NUMERIC` convierte el valor a entero o real al guardarlo. Incluso `createOrderTakesStock` cayó, porque el precio `49.90` vuelve como `49.9`.

🔬 **El detalle** — Con esa evidencia la discusión deja de ser de gustos: la base de prueba no puede guardar el dato que el negocio exige exacto. Una base que no representa el dominio no sirve como base de prueba de ese dominio.

**05 → 7.** ¿Por qué `concurrentOrdersNeverOversell` queda `@Disabled` en lugar de borrada o arreglada? 🟡

⏱️ **30 segundos** — Porque el defecto es real y su dueño es el taller 07. Borrarla pierde la evidencia; arreglar el stock aquí rompe la regla de corregir cada pecado en su taller.

🗣️ **2 minutos** — `@Disabled` con el motivo en la anotación deja la prueba compilando, visible en cada corrida como `Skipped: 1` y con el taller que la activará. El taller 07 solo tiene que quitar la anotación y verla pasar de rojo a verde.

🔬 **El detalle** — Una prueba desactivada sin motivo es deuda escondida; con motivo y dueño, es deuda con fecha. En un equipo real, el motivo llevaría el ticket.

**05 → 8.** ¿Por qué `cancelReturnsStock` no se podía escribir antes de este taller? 🟡

⏱️ **30 segundos** — Porque el stock del pedido cancelado lo devuelve un *trigger* de PostgreSQL, y `SchemaFixer` no lo creaba si la base no era PostgreSQL. Con SQLite la prueba habría fallado siempre.

🗣️ **2 minutos** — La cancelación está repartida: el controlador comprueba el estado, el servicio lo cambia y la base devuelve el stock. Una prueba de servicio contra SQLite solo podía ver las dos primeras partes. Contra PostgreSQL, el *trigger* existe y la prueba comprueba el comportamiento completo.

🔬 **El detalle** — La prueba es la red para el taller 06, que moverá esa lógica del *trigger* a Java: si la mudanza pierde el stock, `cancelReturnsStock` lo dice antes que `hurl/v1`.

**05 → 9.** El contrato del taller 04 ya mostraba `"29.70"`. ¿Qué arregla este taller que el contrato no arreglaba? 🟡

⏱️ **30 segundos** — El dato. El contrato formateaba al salir; la base guardaba `29.700000000000003` y el cálculo seguía en flotante. Este taller cambia el tipo en Java y en la columna.

🗣️ **2 minutos** — La sección 9 lo muestra: con el legado del estado 04, la API respondía `"29.70"` y `SELECT total` devolvía `29.700000000000003`. Las comparaciones internas —el límite de mil, la suma del informe— operaban sobre el valor con error.

🔬 **El detalle** — Es la diferencia entre representación y modelo. El contrato protege al cliente de la representación; el modelo tiene que ser correcto por dentro, porque también lo leen informes, conciliaciones y otros procesos que no pasan por la API.

**05 → 10.** ¿Qué hizo Hibernate al arrancar sobre una base con columnas `double precision`, y qué riesgo tiene? 🟠

⏱️ **30 segundos** — Emitió `ALTER COLUMN ... SET DATA TYPE numeric(12,2)` en las cuatro columnas y PostgreSQL convirtió los datos redondeando. Nadie lo revisó, no se puede deshacer y en una tabla grande bloquea la tabla mientras la reescribe.

🗣️ **2 minutos** — La conversión cambió `29.700000000000003` por `29.70`: inocuo aquí, pero es una migración de datos que corrió sola al arrancar la aplicación. Si un valor no cupiera en `numeric(12,2)`, el `ALTER` fallaría y la aplicación no arrancaría. Y con dos instancias de versiones distintas, la vieja seguiría escribiendo `double` en una columna que ya no lo es.

🔬 **El detalle** — Es el pecado de `ddl-auto: update` que desarma el taller 09: el esquema tiene que cambiar con migraciones versionadas, revisadas y probadas, no como efecto secundario del arranque.

**05 → 11.** Tu equipo dice que Testcontainers hace las pruebas lentas y quiere volver a H2 «en modo PostgreSQL». ¿Qué respondes? 🟠

⏱️ **30 segundos** — Que H2 en modo PostgreSQL imita la sintaxis, no el motor: ni los *triggers* en PL/pgSQL, ni el bloqueo por filas, ni los tipos se comportan igual. Es SQLite con mejor disfraz.

🗣️ **2 minutos** — La pregunta útil es qué pruebas necesitan la base real. Las de dominio puro no necesitan ninguna: se prueban en memoria sin JPA. Las que prueban consultas, transacciones, concurrencia o el esquema necesitan PostgreSQL. Si la lentitud es el arranque, se reutiliza un contenedor por ejecución; si es el volumen, se separan las pruebas lentas.

🔬 **El detalle** — El coste de Testcontainers son segundos por ejecución; el de una prueba que no prueba es un incidente en producción. Este taller tiene la medida: veinte pedidos con cinco unidades.

**05 → 12.** Una prueba de integración pasa en tu máquina y falla en CI con la misma imagen. ¿Qué sospechas y cómo lo investigas? 🟠

⏱️ **30 segundos** — Diferencias de entorno fuera de la imagen: recursos, zona horaria, *locale*, orden de ejecución de las pruebas, datos que deja una prueba para otra o concurrencia distinta por el número de CPU.

🗣️ **2 minutos** — Lo investigaría haciendo reproducible la diferencia: la misma semilla, el mismo orden (o aleatorio con semilla fija), la zona horaria explícita en la JVM y en la base, y los registros de SQL en las dos corridas. Una prueba que depende de otra, o del reloj, falla según el orden y el momento.

🔬 **El detalle** — La prueba de concurrencia de este taller es un buen ejemplo: con pocos núcleos los hilos se intercalan menos, y el número de pedidos vendidos de más cambia entre máquinas.

**05 → 13.** ¿Qué otras diferencias entre la base de prueba y la de producción pueden quedar aunque sea la misma imagen? 🔴

⏱️ **30 segundos** — La configuración del servidor (`postgresql.conf`), la versión menor, las extensiones, el volumen de datos, las estadísticas del planificador y el esquema, si el de producción no se creó igual que el de la prueba.

🗣️ **2 minutos** — Con `ddl-auto: create-drop`, la prueba crea el esquema desde las entidades; producción tiene el que dejaron años de `update`, *triggers* añadidos a mano y columnas que nadie usa. La misma imagen con otro esquema es otra base. También cambian el nivel de aislamiento por defecto, los tiempos de espera de bloqueo y el tamaño del pool.

🔬 **El detalle** — La forma de cerrar la distancia es que el esquema de la prueba salga del mismo sitio que el de producción: migraciones versionadas. Es exactamente lo que el taller 09 introduce con Flyway.

### Ejercicios

**05 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide la URL de la base de las pruebas, y por qué no es la de `application.yaml`? Responde con rutas de `laboratorio/estados/05/`.

⏱️ **30 segundos** — En `laboratorio/estados/05/legacy/src/test/java/dev/mono/legacy/PostgresTestConfig.java:12`, la anotación `@ServiceConnection` sobre el bean del contenedor (línea 14).

🗣️ **2 minutos** — `application.yaml` apunta a `localhost:35432`, la base del compose. `@ServiceConnection` registra unos detalles de conexión que tienen prioridad sobre `spring.datasource.*`, así que el `DataSource` usa el contenedor. `OrderServiceTest.java:37` importa esa configuración.

🔬 **El detalle** — Esto tiene una consecuencia: la propiedad `spring.datasource.url` sigue diciendo la URL de desarrollo aunque nadie la use. Quien la lea para decidir algo, como `SchemaFixer`, está leyendo un valor que no es el real.

**05 → E2.** 🟢 Quita el `@Disabled` de `concurrentOrdersNeverOversell`, corre `lab.py test` tres veces y anota cuántos pedidos se confirman en cada corrida. ¿Es siempre 20? ¿Por qué?

⏱️ **30 segundos** — Sí: en las tres corridas del 2026-09-29, 20 pedidos confirmados de 20. Para correrla sin quitar la anotación: `mvn test -Dtest='OrderServiceTest#concurrentOrdersNeverOversell' '-Djunit.jupiter.conditions.deactivate=org.junit.*DisabledCondition'`.

🗣️ **2 minutos** — Es determinista por el pool: el legado tiene cinco conexiones, así que los hilos entran en tandas de cinco. Cada tanda lee el mismo stock, comprueba que queda y escribe «stock − 1»: cinco pedidos cuestan una unidad. Cuatro tandas llevan el stock de 5 a 1, y nadie ve nunca el cero. La corrida exploratoria lo mostró: `sold=20 stock=1`.

🔬 **El detalle** — Con otro tamaño de pool, otra máquina u otra latencia de la base, el número cambiaría. Que sea estable aquí no lo hace menos grave: es el *lost update* en su forma más limpia, y el taller 07 lo corrige.

**05 → E3.** 🟡 Escribe `productPriceKeepsScale`: crea un producto a `35.00` por la API y compruébalo en la base con `lab.py sql`. Explica qué habría devuelto SQLite.

⏱️ **30 segundos** — La prueba crea el producto con `unitPrice.amount` `"35.00"` y `lab.py sql "SELECT price, price::text FROM products WHERE sku = 'SKU-006'"` devuelve `35.00`, con escala 2.

🗣️ **2 minutos** — En PostgreSQL, `numeric(12,2)` guarda y devuelve la escala. En SQLite, la afinidad `NUMERIC` guardaría `35` como entero y lo devolvería como `35`, sin decimales; `Money.of` lo normalizaría a `35.00` al salir, y el valor interno tendría otra escala que el de otros productos.

🔬 **El detalle** — Es el mismo fenómeno que rompió `createOrderTakesStock`: el problema aparece en cuanto el valor leído participa en una cuenta o en una comparación con `equals`.

**05 → E4.** 🟡 Escribe los cinco experimentos de la sección 11 como pruebas de una clase abstracta con dos subclases, una por base. ¿Cuáles pasan en SQLite y fallan en PostgreSQL, y cuáles al revés?

⏱️ **30 segundos** — Pasan en SQLite y fallan en PostgreSQL: el pedido con un cliente inexistente (clave foránea) y el nombre de 300 caracteres (longitud). Al revés: la precisión de las fechas. Diferente sin fallar: `LIKE` con mayúsculas.

🗣️ **2 minutos** — La estructura es la de la sección 6: una clase abstracta con las pruebas y dos subclases con `@ActiveProfiles` distintos, una con `@Import(PostgresTestConfig.class)`. Cada experimento se escribe afirmando lo que haría una base estricta, para que el color diga quién es laxo.

🔬 **El detalle** — La lista de diferencias no es el objetivo; el objetivo es ver que ninguna aparecía en las pruebas del legado porque nadie las buscó. Una base de prueba distinta esconde justo lo que no se piensa probar.

**05 → E5.** 🟡 **Orientación en código ajeno.** Encuentra todos los sitios donde el legado convierte dinero a texto. ¿Por qué `PaymentService` usa `setScale(2)` sin modo de redondeo y `Money` usa `RoundingMode.UNNECESSARY`?

⏱️ **30 segundos** — En `dto/Money.java:10` al serializar y en `PaymentService.java:57` al llamar al banco. `PaymentService` usa `setScale(2)` sin modo porque el total ya tiene escala 2; `Money` usa `UNNECESSARY` para que un valor con más decimales sea un error visible.

🗣️ **2 minutos** — Los dos métodos lanzan `ArithmeticException` si hubiera que redondear: `setScale(2)` sin modo equivale a `UNNECESSARY`. Escribirlo explícito en `Money` documenta la intención: aquí no se redondea, se normaliza.

🔬 **El detalle** — La alternativa, redondear con `HALF_UP` en la salida, fue lo que hizo el taller 04 con el `double`, y escondió el error. Con decimales exactos, un redondeo al salir sería la señal de un cálculo que no respetó la escala.

**05 → E6.** 🟠 Provoca un `ALTER` que falle: con el legado del estado 04, crea un producto con un precio de `12345678901.50` y arranca el de este taller. ¿Qué pasa con el arranque y qué harías en producción?

⏱️ **30 segundos** — El `ALTER` falla porque `12345678901.50` tiene once cifras enteras y `numeric(12,2)` admite diez; Hibernate registra el error y, según la configuración, la aplicación arranca con la columna sin cambiar o no arranca.

🗣️ **2 minutos** — En producción no se dejaría a `ddl-auto`: se escribe una migración que primero comprueba los datos (`SELECT max(price)`), decide qué hacer con los que no caben y después cambia el tipo, probada contra una copia de producción. Es la parte *expand/contract* del taller 09.

🔬 **El detalle** — El experimento muestra por qué una migración de tipo es una decisión de negocio además de técnica: alguien tiene que decidir qué pasa con el dato que no cabe.

**05 → E7.** 🟠 Haz que las pruebas reutilicen un único contenedor para todas las clases de prueba y mide la diferencia de tiempo. ¿Qué aislamiento pierdes y cómo lo compensas?

⏱️ **30 segundos** — Con un contenedor estático compartido (un campo `static` con `@Container`, o la reutilización de contexto de Spring con la misma configuración) se arranca PostgreSQL una sola vez por ejecución.

🗣️ **2 minutos** — Se pierde el aislamiento entre clases: el esquema y los datos persisten de una clase a otra. Se compensa limpiando en `@BeforeEach`, como ya hace `OrderServiceTest` con sus `DELETE`, o envolviendo cada prueba en una transacción que se revierte, sabiendo que eso no sirve para pruebas de concurrencia.

🔬 **El detalle** — La medida hay que hacerla: con una sola clase de prueba la ganancia es nula, porque ya se usa un contenedor. Aparece con muchas clases que cargan contextos distintos.

**05 → E8.** 🔥 Activa `PRAGMA foreign_keys = ON` en SQLite y repite la corrida exploratoria. ¿Cuántas diferencias quedan, y alcanzan para defender SQLite como base de prueba?

⏱️ **30 segundos** — Con `foreign_keys` activo desaparece la diferencia del pedido huérfano, pero siguen la longitud, las fechas, `LIKE`, el tipo decimal y, sobre todo, la concurrencia.

🗣️ **2 minutos** — El `PRAGMA` se activa por conexión, por ejemplo en la URL de `sqlite-jdbc` (`?foreign_keys=on`). Arregla una diferencia de integridad; no convierte SQLite en PostgreSQL. La sobreventa y el decimal, que son los dos hallazgos del taller, no cambian.

🔬 **El detalle** — No alcanza para defenderlo como base de prueba de este legado: las diferencias que quedan son exactamente las que importan en un sistema de pedidos y pagos.

---

## 📖 06 — Modularizar

### Preguntas

**06 → 1.** ¿Qué considera Spring Modulith un módulo, su API y su interior? 🟢

⏱️ **30 segundos** — Cada subpaquete directo del paquete de la aplicación es un módulo; los tipos públicos de su raíz son su API, y sus subpaquetes, su interior.

🗣️ **2 minutos** — En `mono-legacy`, `dev.mono.legacy.orders` es el módulo `orders`; `OrderService`, `OrderSnapshot` y `PaymentLookup`, en la raíz, son su API; `orders.internal` y `orders.web` son internos. Otro módulo puede usar la API y no puede tocar el interior. `@ApplicationModule` en `package-info.java` añade qué módulos puede usar.

🔬 **El detalle** — La convención es de Modulith y se puede cambiar —con `@NamedInterface` se exponen subpaquetes concretos—, pero conviene no hacerlo sin motivo: la convención es lo que permite leer el límite sin abrir la configuración.

**06 → 2.** ¿Por qué `ModularityTest` pasaba en verde sobre los paquetes por capa? 🟢

⏱️ **30 segundos** — Porque sus «módulos» eran las capas: `controller`, `service`, `repository`, `entity`... y entre capas no había ciclos ni accesos prohibidos. El ciclo real estaba dentro de `service`.

🗣️ **2 minutos** — Modulith verifica las fronteras que le das. Con paquetes por capa, verifica que un controlador no sea llamado por un repositorio, que es cierto y no interesa. `OrderService` e `InventoryService` estaban en el mismo paquete, así que su ciclo era interno a un módulo y ninguna regla entre módulos podía verlo.

🔬 **El detalle** — Es la advertencia de `02/06`: una herramienta de verificación en verde no es evidencia de modularidad si los módulos no representan capacidades. Primero se eligen bien las fronteras; después se hacen cumplir.

**06 → 3.** ¿Qué causaba el ciclo `OrderService` ↔ `InventoryService` y cómo se rompió? 🟢

⏱️ **30 segundos** — Un método `InventoryService.isReserved(orderId)` que usaba `OrderService` y que nadie llamaba. Se borró, y con él el ciclo; `allow-circular-references` salió de la configuración.

🗣️ **2 minutos** — `OrderService` necesitaba a `InventoryService` para reservar stock, e `InventoryService` a `OrderService` para `isReserved`. Spring no puede construir dos beans que se necesitan por constructor, así que el legado los inyectaba por campo y activaba `allow-circular-references`. Al buscar quién usaba `isReserved`, la respuesta fue nadie.

🔬 **El detalle** — No todos los ciclos son código muerto. Cuando la dependencia es real, las salidas son fusionar, invertir con un puerto (como `PaymentLookup`) o mover la responsabilidad al módulo que corresponde. Buscar primero el código muerto es barato y a menudo suficiente.

**06 → 4.** ¿Qué vigila ArchUnit en este taller que Modulith no vigila? 🟢

⏱️ **30 segundos** — La forma dentro de cada módulo: que ningún controlador use un repositorio y que ninguna entidad salga de un paquete `internal`. Modulith solo mira las dependencias entre módulos.

🗣️ **2 minutos** — Los dos controladores que leían tablas —notificaciones y lotes— estaban en su propio módulo, así que para Modulith todo era correcto. ArchUnit encontró siete referencias y obligó a pasar por un servicio del módulo. La regla de entidades evita que una `@Entity` quede en la raíz de un módulo, donde sería API.

🔬 **El detalle** — Las dos herramientas se complementan: Modulith conoce el concepto de módulo y sus convenciones; ArchUnit es un lenguaje general de reglas sobre el *bytecode*, útil para lo que la convención no cubre.

**06 → 5.** ¿Por qué `Order.customer` pasó de `@ManyToOne User` a `UUID customerId`? 🟡

⏱️ **30 segundos** — Para que una entidad de `orders` no navegue hasta la tabla de `auth`. `orders` guarda el identificador y pregunta a `auth.Customers` lo que necesita: el correo.

🗣️ **2 minutos** — Con `@ManyToOne User`, `orders` dependía de la entidad `User`, un tipo interno de otro módulo, y cualquier código de pedidos podía leer el hash de la contraseña del cliente. La columna `customer_id` es la misma, así que no hay cambio de esquema. El efecto secundario es que `ReportService` ya no hace una consulta por pedido para leer el cliente.

🔬 **El detalle** — El coste real está en la sección 11: sin asociación, Hibernate deja de crear la clave foránea en una base nueva. La integridad referencial entre módulos pasa a ser una decisión explícita, que aquí queda pendiente para el taller 09.

**06 → 6.** ¿Cómo muestra `GET /orders/{id}` el último pago sin que `orders` dependa de `payments`? 🟡

⏱️ **30 segundos** — Por un puerto: `orders` declara la interfaz `PaymentLookup` y `payments` la implementa en `PaymentLookupAdapter`. El controlador de pedidos recibe la interfaz y Spring inyecta la implementación.

🗣️ **2 minutos** — Es inversión de dependencia. El código de `orders` solo conoce su propia interfaz; el de `payments` conoce la interfaz de `orders`. La flecha en el grafo va de `payments` a `orders`, y el ciclo que había en las entidades —`Order.payments` y `Payment.order`— desaparece.

🔬 **El detalle** — El precio es una indirección más y un contrato que mantener. La alternativa sería guardar el estado del pago en el propio pedido, que exige cambiar el esquema; es una opción legítima para el taller 09.

**06 → 7.** ¿Por qué `POST /orders/{id}/payment` cambió de controlador sin cambiar de ruta? 🟡

⏱️ **30 segundos** — Porque la ruta es del contrato y el controlador es del módulo. `POST /orders/{id}/payment` sigue igual para el cliente, pero lo atiende `payments`, que es quien paga.

🗣️ **2 minutos** — Si el pago siguiera en `OrderController`, `orders` tendría que llamar a `PaymentService` y dependería de `payments`, que a su vez depende de `orders`: un ciclo. Que la URL empiece por `/orders` no obliga a que el código sea de pedidos; la URL describe el recurso, el módulo describe quién tiene la responsabilidad.

🔬 **El detalle** — `hurl/v1` es la prueba de que el cambio fue invisible: la suite no cambió ni una línea.

**06 → 8.** ¿Qué diferencia hay entre violar `allowedDependencies` y usar un tipo interno de otro módulo? 🟡

⏱️ **30 segundos** — Usar un tipo interno rompe la encapsulación de otro módulo; violar `allowedDependencies` es usar su API sin haberlo declarado. La primera casi siempre es un error; la segunda puede ser una dependencia legítima que hay que decidir.

🗣️ **2 minutos** — `payments` usando `orders.internal.OrderRepository` escribe en la tabla de pedidos saltándose sus reglas. `reports` usando `inventory.InventoryService` usa una API pública; lo que falla es que nadie aprobó esa dependencia. Para aceptarla basta cambiar `allowedDependencies`, en un cambio que alguien revisa.

🔬 **El detalle** — Por eso conviene declarar `allowedDependencies` aunque no haga falta para evitar ciclos: convierte cada dependencia nueva en una línea visible en una revisión.

**06 → 9.** ¿Por qué la primera mudanza del *trigger* no puso `cancelReturnsStock` en rojo? 🟡

⏱️ **30 segundos** — Porque `release` hacía leer-sumar-escribir y Hibernate escribió un valor absoluto que pisó la suma del *trigger*. La duplicación existía, y otro defecto la tapaba.

🗣️ **2 minutos** — El orden de las sentencias fue: `update orders` (dispara el *trigger*, stock 18 → 20) y luego `update products set stock=?` con el 20 que Java había calculado desde el 18 leído antes. El resultado final era correcto por accidente. Al cambiar `release` a un incremento en la base, la prueba dio 22.

🔬 **El detalle** — La lección es general: dos defectos que se compensan no hacen un sistema correcto, y arreglar uno destapa el otro. El mismo leer-restar-escribir sigue en `reserve`, y es la sobreventa del taller 07.

**06 → 10.** ¿Qué garantía se perdió al quitar las asociaciones JPA entre módulos, y quién tomó esa decisión? 🟠

⏱️ **30 segundos** — La integridad referencial entre módulos: que un pedido no pueda apuntar a un cliente inexistente ni un pago a un pedido inexistente. No la tomó nadie: la tomó el ORM al dejar de ver asociaciones, y distinta en cada base.

🗣️ **2 minutos** — La base de desarrollo conserva tres claves foráneas porque las creó antes; una base nueva solo tiene la de `order_lines`, que sigue siendo una asociación dentro de `orders`. Dos entornos con esquemas distintos es exactamente la deriva que hace que algo funcione en uno y falle en otro.

🔬 **El detalle** — Quitar claves foráneas entre módulos puede ser correcto si cada módulo es dueño de sus datos y la integridad se garantiza por la aplicación. Mantenerlas también puede serlo en un monolito con una sola base. Lo que no es correcto es que la decisión sea implícita; el taller 09 la escribe como migración.

**06 → 11.** Un compañero propone `allowedDependencies = {}` vacío para todos los módulos «para que nadie dependa de nadie». ¿Qué pasa? 🟠

⏱️ **30 segundos** — Que la verificación falla en cuanto un módulo usa a otro, y todos lo hacen: `orders` necesita a `inventory` para reservar. Sin dependencias no hay sistema, solo módulos aislados que no hacen nada juntos.

🗣️ **2 minutos** — `allowedDependencies` no es para eliminar dependencias, sino para hacerlas explícitas y dirigidas. Lo que se quiere evitar son ciclos, accesos a internos y dependencias que nadie aprobó; no que `orders` use la API de `inventory`.

🔬 **El detalle** — Incluso `shared` con `{}` es una decisión que tiene sentido solo porque es el núcleo: el módulo del que todos dependen tiene que ser el que no depende de nadie.

**06 → 12.** `shared` crece cada semana. ¿Qué señales te dicen que está dejando de ser un núcleo compartido? 🟠

⏱️ **30 segundos** — Cuando entra lógica de negocio, cuando cambia por razones de un solo módulo o cuando obliga a coordinar cambios entre equipos que no comparten dominio.

🗣️ **2 minutos** — Hoy `shared` tiene errores del contrato, dinero y paginación: conceptos estables que usan todos. Si mañana aparece `OrderStatusRules` o un `ProductHelper`, `shared` se convierte en el sitio donde se esconde el acoplamiento que los módulos no quieren declarar. Cada cambio en `shared` recompila y puede romper a todos.

🔬 **El detalle** — La regla de `02/06` es que el núcleo compartido crece por decisión explícita. Una forma práctica es exigir revisión de todos los dueños para tocarlo; si eso duele, es la señal de que algo que está ahí debería vivir en un módulo.

**06 → 13.** Con este grafo, ¿qué módulo sacarías primero a otro proceso, cuál nunca, y qué evidencia te falta para decidirlo? 🔴

⏱️ **30 segundos** — Con este grafo, `notifications` o `inventory` son candidatos (no dependen de nadie más que `shared`); `orders` sería el último, porque es el centro. Falta la evidencia de runtime y de equipos: quién cambia qué, con qué frecuencia y qué necesita estar disponible para crear un pedido.

🗣️ **2 minutos** — `notifications` es una hoja con una sola operación y podría ser asíncrona; sacarla aislaría fallos de entrega. `inventory` es una hoja, pero `orders` la llama dentro de la transacción de crear un pedido: extraerla convierte una transacción local en una llamada remota, que es exactamente lo que el taller 10 provoca. `payments` depende de `orders` y ya habla con un proveedor externo.

🔬 **El detalle** — El grafo de dependencias de código es una de las cinco monedas. Para decidir hay que añadir la de datos (quién escribe qué tabla), la de runtime (qué llamada es síncrona dentro de qué transacción) y la de equipos. Sin eso, la decisión se toma por forma del diagrama.

### Ejercicios

**06 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que la devolución del stock ya no es del *trigger*? Responde con rutas de `laboratorio/estados/06/`.

⏱️ **30 segundos** — En `laboratorio/estados/06/legacy/src/main/resources/db/drop-legacy-trigger.sql:3`, que ejecuta `SchemaFixer` al arrancar, y en `orders/OrderService.java:130`, que llama a `inventory/InventoryService.java:36`.

🗣️ **2 minutos** — Son dos partes de la misma decisión: la regla pasa a `release` y la copia anterior se retira de la base. `SchemaFixer` (en `inventory/internal/SchemaFixer.java`) antes creaba el *trigger* y ahora lo borra, con `IF EXISTS` para que una base nueva no falle.

🔬 **El detalle** — Un recorrido que solo mirara Java encontraría `release` y creería que la mudanza está completa. La prueba de que no lo estaba es la sección 9: con el *trigger* en la base, el stock volvía dos veces.

**06 → E2.** 🟢 Aplica el atajo de la sección 7 (el `OrderRepository` en `PaymentService`), corre `lab.py test` y pega la violación. Revierte.

⏱️ **30 segundos** — `Module 'payments' depends on non-exposed type dev.mono.legacy.orders.internal.OrderRepository within module 'orders'!`, tres veces, y `ModularityTest` en error.

🗣️ **2 minutos** — El código compila y la aplicación arrancaría: el límite solo existe en la prueba. Revertir es quitar el campo, el parámetro y el `import`; `lab.py test` vuelve a verde.

🔬 **El detalle** — Por eso la prueba tiene que correr en cada construcción, no a mano. Un límite que se comprueba de vez en cuando se erosiona entre comprobaciones.

**06 → E3.** 🟡 Haz que `orders` llame a `payments` —por ejemplo, un `PaymentService` inyectado en `OrderController`— y lee lo que dice `verify()`. ¿Es la misma violación que la del ejercicio 2?

⏱️ **30 segundos** — Dos violaciones: `Cycle detected: Slice orders -> ...` y `Module 'orders' depends on module 'payments' via dev.mono.legacy.orders.web.OrderController -> dev.mono.legacy.payments.internal.PaymentService. Allowed targets: inventory, auth, notifications, shared.` No es la misma que la del ejercicio 2.

🗣️ **2 minutos** — El ejercicio 2 era un acceso a un tipo interno en una dependencia permitida (`payments` → `orders`). Aquí la dependencia misma está prohibida —`orders` no declara `payments`— y además cierra un ciclo con la que ya existe en sentido contrario. Modulith informa primero del ciclo y del destino no permitido.

🔬 **El detalle** — Es la razón por la que el pago se mudó de controlador en la sección 6: la ruta `/orders/{id}/payment` en `OrderController` obligaba exactamente a esta dependencia.

**06 → E4.** 🟡 **Orientación en código ajeno.** Sigue una cancelación desde `OrderController` hasta la base y lista cada módulo que toca, en orden, con archivo y línea. ¿Cuántas transacciones abre?

⏱️ **30 segundos** — `orders/web/OrderController.java` (`cancel`) → `orders/OrderService.java` (`findVisible`, luego `cancel`, que comprueba la regla en la línea 124) → `inventory/InventoryService.java:36` (`release`, un `update` por línea) → `auth/Customers.java` (`emailOf`) → `notifications/Notifications.java` (`orderCancelled`). Una transacción: la de `OrderService.cancel`.

🗣️ **2 minutos** — `release`, `emailOf` y `orderCancelled` no declaran `@Transactional` propio, o usan la propagación por defecto, así que se unen a la de `cancel`. Todo se confirma o se revierte junto: el estado, el stock y la notificación. `findVisible` corre antes, fuera de esa transacción, leyendo la caché o la base.

🔬 **El detalle** — Que la notificación esté en la misma transacción es el pecado que desarma el taller 08: es atómico, pero acopla la cancelación a que la escritura de notificaciones funcione.

**06 → E5.** 🟡 Añade a `ArchitectureTest` una regla: ninguna clase fuera de `..web..` depende de clases de `..web..`. ¿Pasa? Si no, ¿qué dependencia encontró y es un error?

⏱️ **30 segundos** — Escrita como `noClasses().that().resideOutsideOfPackage("..web..").should().dependOnClassesThat().resideInAPackage("..web..")`, falla con 43 violaciones, y 35 son falsos positivos: `org.springframework.web` y `org.springframework.security.config.annotation.web` también se llaman `web`. Acotada a `dev.mono.legacy..web..`, quedan tres dependencias reales: `AuthService` → `auth.web.TokenResponse`, `OrderService` → `orders.web.CreateOrderRequest.Line` y `ReportService` → `reports.web.SummaryView`.

🗣️ **2 minutos** — Las tres son el mismo error de forma: el interior o la API de un módulo usa tipos de su capa web. Se corrigen moviendo esos tipos a la raíz del módulo o definiendo en la API un tipo propio al que el controlador traduce.

🔬 **El detalle** — Dos lecciones: las reglas se descubren escribiéndolas (el grafo entre módulos estaba limpio y dentro quedaban dependencias hacia fuera), y un patrón de paquete demasiado general atrapa el código del framework. Una regla con 35 falsos positivos se desactiva al día siguiente.

**06 → E6.** 🟠 Genera con `Documenter` de Spring Modulith el diagrama de módulos y compáralo con el de la sección 1. ¿Qué muestra que el dibujo a mano no mostraba?

⏱️ **30 segundos** — `new Documenter(ApplicationModules.of(LegacyApplication.class)).writeModulesAsPlantUml()` escribe diagramas en `target/spring-modulith-docs`: uno global y uno por módulo.

🗣️ **2 minutos** — El generado muestra lo que el dibujo a mano omite: el tipo de cada dependencia (uso de API, implementación de un puerto) y las dependencias de `shared`, que el diagrama de la sección 1 resume en una línea. Y es verdad por construcción: se genera desde el código en cada ejecución.

🔬 **El detalle** — Un diagrama generado no sustituye al dibujado para explicar una decisión, pero sirve para comprobar que el dibujado no miente.

**06 → E7.** 🟠 Separa `products` (catálogo) de `inventory` (stock) como dos módulos sin cambiar la tabla. ¿Qué API necesita cada uno y qué te impide hacerlo del todo sin el taller 09?

⏱️ **30 segundos** — `products` expone el catálogo (nombre y precio: `ProductView`, `CreateProduct`) e `inventory` el stock (`reserve`, `release`). Lo que lo impide del todo es la tabla: las dos capacidades escriben la misma fila de `products`.

🗣️ **2 minutos** — Se pueden separar los paquetes y las API, pero la entidad `Product` tendría que estar en uno de los dos y el otro dependería de él, o existir dos entidades mapeadas a la misma tabla, cada una con sus columnas. La segunda opción funciona y es la antesala de separar las tablas.

🔬 **El detalle** — Separar la tabla en `products` e `inventory` sin parar la aplicación es exactamente el *expand/contract* del taller 09. La modularidad de código llega primero; la de datos necesita migraciones.

**06 → E8.** 🔥 Escribe una prueba con `@ApplicationModuleTest` que arranque solo `inventory` y compruebe `reserve` y `release`. ¿Qué dependencias tuviste que simular y qué te dice eso de su API?

⏱️ **30 segundos** — Con `@ApplicationModuleTest` en el paquete de `inventory`, Modulith arranca por defecto (modo `STANDALONE`) solo los beans de ese módulo; `DIRECT_DEPENDENCIES` añadiría los de los módulos que usa.

🗣️ **2 minutos** — `inventory` no necesita simular nada más: su API no depende de otros módulos. Si hubiera que simular `orders` para probar `inventory`, la API estaría mal orientada. Para `orders` habría que simular `inventory`, `auth` y `notifications` (con `@MockitoBean`), o arrancar en `DIRECT_DEPENDENCIES`.

🔬 **El detalle** — Lo que cuesta simular al probar un módulo aislado es una medida directa de su acoplamiento. Es una métrica mejor que contar `import`.

---

## 📖 07 — Transacciones y concurrencia

### Preguntas

**07 → 1.** ¿Por qué cinco pagos lentos dejan sin servicio al catálogo, que no toca pagos? 🟢

⏱️ **30 segundos** — Porque comparten el pool: cinco conexiones para toda la aplicación. Si cinco pagos las retienen mientras esperan al banco, el catálogo espera una conexión y, a los 2 s, falla.

🗣️ **2 minutos** — El pool no sabe de módulos ni de rutas. Cada petición que toca la base necesita una conexión, y Hikari da como máximo cinco; la sexta espera hasta `connection-timeout` y recibe una excepción. La lectura del catálogo tarda milisegundos, pero no puede empezar. La tormenta lo mostró: una lectura del catálogo en `500` después de 2028 ms.

🔬 **El detalle** — Es acoplamiento de runtime dentro de un proceso: una dependencia lenta de una capacidad degrada a todas las demás a través de un recurso compartido. Se corrige acortando lo que retiene el recurso, no dándole más recurso.

**07 → 2.** ¿Qué es *Open Session in View* y por qué retuvo la conexión con el proveedor ya fuera de la transacción? 🟢

⏱️ **30 segundos** — Es el patrón por el que Spring mantiene abierta la sesión de JPA durante toda la petición HTTP, para que el controlador pueda leer relaciones perezosas. La sesión conservaba la conexión de la primera consulta hasta el final de la petición, incluida la espera al banco.

🗣️ **2 minutos** — `PaymentService` ya no tenía transacción durante la llamada, pero la sesión de OSIV seguía viva con su conexión. Con el pago en tres pasos, la conexión se tomaba en el paso 1 y no volvía al pool hasta que el controlador terminaba de responder. Arrancar el mismo código con `open-in-view=false` resolvió la tormenta: 20 pagos en 1,7 s y el catálogo a 29 ms.

🔬 **El detalle** — Spring Boot avisa en el arranque (`spring.jpa.open-in-view is enabled by default`) y el legado lo ignoraba. Es un buen ejemplo de valor por defecto cómodo que se paga en producción.

**07 → 3.** ¿Qué hace `PESSIMISTIC_WRITE` y qué sentencia generó Hibernate? 🟢

⏱️ **30 segundos** — Bloquea la fila leída hasta el final de la transacción: otra transacción que quiera bloquearla espera. Hibernate generó `select ... from products p1_0 where p1_0.sku=? for no key update of p1_0`.

🗣️ **2 minutos** — En PostgreSQL, `FOR NO KEY UPDATE` es un bloqueo de fila para escribir que no impide a otras transacciones comprobar claves foráneas contra esa fila (eso lo haría `FOR UPDATE`). Para serializar a los compradores del mismo producto es suficiente: el segundo espera, lee el stock que dejó el primero y decide con el valor actual.

🔬 **El detalle** — El bloqueo dura lo que dure la transacción. Por eso importa que la transacción de crear un pedido sea corta y no llame a nada externo: el bloqueo de una fila popular es un cuello de botella si se retiene.

**07 → 4.** ¿Qué distingue una repetición con la misma clave de una clave reutilizada con otro cuerpo? 🟢

⏱️ **30 segundos** — Una repetición es la misma clave con la misma petición: devuelve la respuesta guardada, con `200` e `Idempotent-Replay: true`. Una reutilización es la misma clave con otro cuerpo o para otra operación: `422 IDEMPOTENCY_KEY_REUSED`.

🗣️ **2 minutos** — El legado guarda con cada clave una huella (`fingerprint`): método, ruta y cuerpo. Si la huella coincide, es el mismo intento reintentado. Si no, el cliente usó una clave vieja para una operación nueva, y ejecutarla o devolver la respuesta anterior serían los dos incorrectos.

🔬 **El detalle** — El `422` protege al cliente de su propio error: sin él, una clave reutilizada por un fallo del cliente devolvería en silencio el pedido anterior como si fuera el nuevo.

**07 → 5.** ¿Por qué `startPayment` deja el pedido en `PAYMENT_PENDING` antes de llamar al banco? 🟡

⏱️ **30 segundos** — Para cerrar la ventana que abre sacar al banco de la transacción. Con el pedido en `PAYMENT_PENDING` y la fila bloqueada mientras se cambia, un segundo intento no puede ver `CONFIRMED` y llamar también al banco.

🗣️ **2 minutos** — Antes, la validación y el cobro estaban en la misma transacción, pero sin bloqueo: dos pagos simultáneos leían `CONFIRMED` y cobraban los dos (dos cargos en la tormenta de la sección 10). Al separar los pasos, el estado intermedio es el que dice «hay un pago en curso». La transacción 1 lo escribe y confirma antes de llamar al banco.

🔬 **El detalle** — El precio es que un proceso que muera entre la transacción 1 y la 2 deja el pedido en `PAYMENT_PENDING` para siempre. Por eso un estado intermedio necesita un proceso que lo resuelva: el ejercicio 7.

**07 → 6.** ¿Por qué se reservan las líneas en orden de SKU y no en el del pedido? 🟡

⏱️ **30 segundos** — Para que dos pedidos con las mismas líneas bloqueen las filas en el mismo orden. Si uno bloquea `SKU-001` y luego `SKU-002`, y el otro al revés, cada uno puede quedarse esperando la fila que tiene el otro: un interbloqueo.

🗣️ **2 minutos** — PostgreSQL detecta el interbloqueo y aborta una de las dos transacciones, así que no se cuelga para siempre, pero un cliente recibe un error por algo que no hizo mal. Ordenar los recursos antes de bloquearlos es la técnica clásica para que el ciclo de espera no pueda formarse.

🔬 **El detalle** — Las líneas del pedido se siguen guardando en el orden en que llegaron: solo el orden de reserva cambia. El índice de la línea que falla (`lines[1].quantity`) también se conserva.

**07 → 7.** ¿Qué cierra el `INSERT ... ON CONFLICT DO NOTHING` que no cerraría un `SELECT` seguido de un `INSERT`? 🟡

⏱️ **30 segundos** — La ventana entre comprobar y escribir. Con `SELECT` y luego `INSERT`, dos peticiones con la misma clave pueden comprobar las dos que no existe y ejecutar las dos el comando.

🗣️ **2 minutos** — `INSERT ... ON CONFLICT DO NOTHING` es una sola operación sobre el índice único. Si otra transacción insertó la misma clave y no ha confirmado, PostgreSQL hace esperar a esta hasta que aquella termine; después, inserta (si la otra deshizo) o no (si confirmó). Devuelve cuántas filas insertó, y ese 1 o 0 decide si el comando se ejecuta.

🔬 **El detalle** — La alternativa sería capturar la violación de clave única de un `INSERT` normal, pero en PostgreSQL esa excepción aborta la transacción entera; con `ON CONFLICT` la transacción sigue viva y puede leer la respuesta guardada.

**07 → 8.** ¿Por qué `666.00` termina en `PAYMENT_PENDING` y no en `PAYMENT_REJECTED`? 🟡

⏱️ **30 segundos** — Porque el legado no sabe qué pasó: el banco no respondió dentro del timeout. Rechazar sería afirmar algo falso, y de hecho el banco cobró.

🗣️ **2 minutos** — El simulador registra el cobro de `666.00` y responde a los 3 s; el legado espera 2 s. Ese intervalo es exactamente el resultado incierto de `04/05`: la operación pudo ocurrir. `PAYMENT_PENDING` lo dice, bloquea nuevos intentos a ciegas (`409`) y permite resolverlo después preguntando al banco con la misma clave.

🔬 **El detalle** — Tratarlo como rechazo es peor que no hacer nada: el cliente lo vería rechazado, pagaría otra vez y tendría dos cargos. El estado incierto es incómodo, pero es verdad.

**07 → 9.** ¿Cuándo preferirías una versión optimista (`@Version`) al bloqueo pesimista para el stock? 🟡

⏱️ **30 segundos** — Cuando los conflictos son raros. Con `@Version`, nadie espera: cada transacción lee sin bloquear y, al escribir, falla si otra cambió la fila; se reintenta.

🗣️ **2 minutos** — Para el stock de un catálogo grande con compras dispersas, la versión optimista evita esperas y bloqueos. Para la última unidad de un producto popular, casi todas las transacciones chocan y se reintentan: más trabajo y más latencia que esperar un bloqueo corto. Aquí la tormenta era justamente de choques.

🔬 **El detalle** — Una tercera opción es la actualización condicional (`stock = stock - q where stock >= q`), que no lee antes de escribir: es el ejercicio 8, y suele ser la mejor para contadores simples.

**07 → 10.** Apagar OSIV rompió cuatro archivos de la suite. ¿Por qué eso es una buena noticia? 🟠

⏱️ **30 segundos** — Porque mostró un defecto que ya estaba: el controlador leía relaciones perezosas fuera de cualquier transacción, y OSIV lo tapaba reteniendo conexiones.

🗣️ **2 minutos** — Con OSIV, `OrderView.from` funcionaba porque la sesión seguía abierta en el controlador. Sin él, la lectura de `lines` falló en cuatro archivos de la suite. La corrección —`@EntityGraph` en las consultas que alimentan la vista— hace explícito qué carga cada caso de uso, dentro de su transacción.

🔬 **El detalle** — Una suite que se rompe al quitar una muleta es una suite que cubre lo que la muleta sostenía. Sin `hurl/v1`, apagar OSIV habría llegado a producción como `500` en el detalle de un pedido.

**07 → 11.** El doble clic con la misma clave dio `200` y `409`, no `200` y `200`. ¿Es correcto? ¿Qué harías para que el segundo esperara la respuesta? 🟠

⏱️ **30 segundos** — Es correcto y coincide con lo que propone el borrador del IETF: si se repite una petición mientras la original sigue en curso, el servidor debería responder con un conflicto. El segundo recibió `409` porque la clave estaba reclamada y el banco aún no había contestado.

🗣️ **2 minutos** — Para que el segundo recibiera la misma respuesta habría que hacerlo esperar: sondear la tabla hasta que haya respuesta o bloquear hasta que la transacción 2 termine, con un límite de tiempo. Es posible, pero retiene una petición y quizá una conexión durante la llamada al banco, que es lo que el taller acaba de eliminar.

🔬 **El detalle** — La práctica habitual es el `409` con un `Retry-After`: el cliente reintenta con la misma clave un poco después y recibe la respuesta guardada. Lo importante es que no haya un segundo cobro, y no lo hay.

**07 → 12.** El banco cobró el pedido de `666.00` y el legado dice `PENDING`. ¿Cómo lo resolverías y quién debería hacerlo? 🟠

⏱️ **30 segundos** — Con un proceso de reconciliación que pregunte al banco por los pagos `PENDING` usando la misma clave, y actualice el pedido con la respuesta. Lo debería hacer `payments`, que es el dueño de la relación con el banco.

🗣️ **2 minutos** — El `psp-simulator` guarda la respuesta por clave: repetir la petición con `uncertain-pay-0001` devolvería `AUTHORIZED` con `Idempotent-Replay` y sin un segundo cobro. Una tarea periódica recorre los pagos pendientes con cierta antigüedad, repite la llamada con su `operationId` y registra el resultado. Si el banco tiene una consulta por clave, mejor que repetir el cobro.

🔬 **El detalle** — La reconciliación también necesita un límite: si el banco sigue sin responder tras horas, el caso pasa a una persona. Un estado incierto sin nadie que lo resuelva es un problema escondido.

**07 → 13.** ¿Qué parte de todo esto cambiaría si `payments` estuviera en otro proceso? 🔴

⏱️ **30 segundos** — La transacción que hoy une «bloquear el pedido» y «registrar el intento» dejaría de existir: serían dos procesos con dos bases. `startPayment` sería una llamada remota, con su propio fallo parcial, y el estado del pedido y el del pago ya no se confirmarían juntos.

🗣️ **2 minutos** — Se necesitaría una saga o un protocolo de estados: `payments` pide a `orders` que reserve el pedido para pago, cobra y luego informa el resultado, con idempotencia en cada llamada y compensación si algo falla a medias. La tormenta de pagos seguiría cuidando el pool de cada proceso, pero aparecerían los timeouts y reintentos de red de `04/05`.

🔬 **El detalle** — Lo que no cambiaría es el valor de la clave: la misma `Idempotency-Key` de extremo a extremo es lo que permite reintentar cada tramo sin duplicar efectos. Es la parte del diseño que ya está lista para distribuirse.

### Ejercicios

**07 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se llama al banco, y cuántas transacciones hay abiertas en ese momento? Responde con rutas de `laboratorio/estados/07/`.

⏱️ **30 segundos** — En `laboratorio/estados/07/legacy/src/main/java/dev/mono/legacy/payments/internal/PaymentService.java:91`, dentro de `authorize`, que se llama en la línea 69. En ese momento no hay ninguna transacción abierta.

🗣️ **2 minutos** — La transacción 1 empieza y termina en el bloque de la línea 48; la 2 empieza en la línea 71. Entre las dos, la llamada al banco corre sin transacción y, con `open-in-view: false`, sin sesión de JPA ni conexión del pool.

🔬 **El detalle** — Para comprobarlo en vivo, `lab.py legacy --sql` y una petición de pago: las sentencias de la transacción 1 aparecen, luego un silencio de la duración de la llamada, y después las de la transacción 2.

**07 → E2.** 🟢 Repite la tormenta de pagos de la sección 5 con `--n 10`, `--n 15` y `--n 20` contra el estado 06. Explica con la aritmética del pool dónde empieza a fallar.

⏱️ **30 segundos** — Con el estado 06, cinco conexiones y 1,5 s por pago: `--n 10` pasa (dos tandas, la segunda espera unos 1,5 s, por debajo de los 2 s de `connection-timeout`); `--n 15` y `--n 20` fallan a partir de la tercera tanda, que esperaría unos 3 s.

🗣️ **2 minutos** — La corrida del 2026-09-29 midió los extremos: con 10, diez `PAID` y el catálogo en 1526 ms; con 20, diez `PAID`, diez `500` y el catálogo en `500`. El valor de 15 es la predicción de la aritmética: diez `PAID` y cinco `500`, y es lo que hay que comprobar.

🔬 **El detalle** — El ejercicio enseña a no buscar el umbral a ciegas: con el tamaño del pool, el tiempo de retención y el timeout de espera, se calcula cuándo empieza a fallar, y la tormenta lo confirma.

**07 → E3.** 🟡 Cambia el bloqueo pesimista por `@Version` en `Product` y reintenta el conflicto. Corre la tormenta de pedidos y compara resultados y tiempos.

⏱️ **30 segundos** — Se añade `@Version private long version;` a `Product`, `reserve` vuelve a `findById` sin bloqueo y el conflicto (`ObjectOptimisticLockingFailureException`) se reintenta unas pocas veces. El resultado correcto es el mismo: cinco confirmados.

🗣️ **2 minutos** — La diferencia está en el camino: con bloqueo, los compradores esperan en fila; con versión, casi todos chocan en la escritura, deshacen y reintentan. Con veinte compradores sobre la misma fila, los reintentos se multiplican y la latencia de cola crece. Hay que medirlo con la misma tormenta.

🔬 **El detalle** — Además, la columna `version` es un cambio de esquema: con `ddl-auto: update` aparecería sola al arrancar, que es exactamente lo que el taller 09 deja de permitir.

**07 → E4.** 🟡 **Orientación en código ajeno.** Sigue un pago desde `PaymentController` hasta la base y lista cada sentencia SQL con `lab.py legacy --sql`. ¿Cuántas conexiones usa y durante cuánto tiempo?

⏱️ **30 segundos** — `PaymentController` → `PaymentService.pay`: transacción 1 (`INSERT ... ON CONFLICT` en `idempotency_keys`, `SELECT ... FOR NO KEY UPDATE` del pedido, `UPDATE` a `PAYMENT_PENDING`, `INSERT` del pago); llamada al banco sin conexión; transacción 2 (`SELECT` del pago, `UPDATE` del pago, `UPDATE` del pedido, `UPDATE` de la clave con la respuesta).

🗣️ **2 minutos** — Usa una conexión por transacción, dos en total y no simultáneas, cada una durante unos milisegundos. Entre medias, ninguna. Con OSIV encendido habría sido una sola conexión durante toda la petición, espera al banco incluida.

🔬 **El detalle** — El registro de `--sql` muestra el orden exacto; el tiempo que la conexión está fuera del pool se ve mejor con las métricas de Hikari (`hikaricp.connections.usage`), que el legado todavía no expone.

**07 → E5.** 🟡 Provoca un interbloqueo: quita el orden por SKU y lanza a la vez pedidos `[SKU-001, SKU-002]` y `[SKU-002, SKU-001]`. Pega lo que dice PostgreSQL y el legado.

⏱️ **30 segundos** — PostgreSQL detecta el ciclo de espera y aborta una de las dos transacciones con `ERROR: deadlock detected`; el legado lo recibe como una excepción no prevista y responde `500 INTERNAL_ERROR`.

🗣️ **2 minutos** — Sin el orden por SKU, el pedido `[SKU-001, SKU-002]` bloquea `SKU-001` y espera `SKU-002`, y el otro al revés. El detector de interbloqueos de PostgreSQL corre tras `deadlock_timeout` (1 s por defecto), elige una víctima y la aborta; la otra continúa.

🔬 **El detalle** — Hay que lanzar muchos pares para verlo: el interbloqueo necesita que las dos transacciones se crucen justo entre el primer y el segundo bloqueo. Es un buen ejemplo de fallo raro en pruebas y frecuente con carga.

**07 → E6.** 🟠 Haz que las claves de idempotencia caduquen a las 24 h, como en los contratos hermanos. ¿Qué pasa con una repetición que llega a las 25 h, y es aceptable?

⏱️ **30 segundos** — Una tarea borra las filas con `created_at` anterior a 24 h, o `claim` las trata como inexistentes. Una repetición a las 25 h se ejecuta como una operación nueva: un pedido nuevo o, en un pago, un nuevo intento.

🗣️ **2 minutos** — Para pedidos puede ser aceptable si el cliente no reintenta tan tarde; para pagos, el propio estado del pedido protege: si ya está `PAID`, el nuevo intento recibe `409`, no un segundo cobro. La caducidad es un compromiso entre el tamaño de la tabla y la ventana en la que un cliente puede reintentar.

🔬 **El detalle** — Lo que no es aceptable es que la caducidad sea implícita. El contrato debe decir cuánto dura una clave, como hacen los contratos hermanos, para que los clientes diseñen sus reintentos dentro de esa ventana.

**07 → E7.** 🟠 Escribe una tarea que resuelva los pagos `PENDING`: pregunta al banco con la misma clave y actualiza el pedido. ¿Qué garantiza que no cobra dos veces?

⏱️ **30 segundos** — Una tarea programada lee los pagos `PENDING` con cierta antigüedad, vuelve a llamar al banco con su `operationId` como `Idempotency-Key` y registra el resultado en el pago y en el pedido, en una transacción corta por pago.

🗣️ **2 minutos** — No cobra dos veces porque el banco es idempotente por clave: la segunda petición con `uncertain-pay-0001` devuelve la respuesta guardada con `Idempotent-Replay` y no registra otro cargo (`lab.py psp-charges` sigue mostrando uno). Del lado del legado, actualizar solo si el pago sigue `PENDING` evita pisar un resultado que otra ejecución ya registró.

🔬 **El detalle** — Con dos instancias del legado, la tarea correría dos veces a la vez; es el problema del taller 08, y se resuelve con un *lease* en la base.

**07 → E8.** 🔥 Sustituye el bloqueo por una actualización condicional (`update ... set stock = stock - :q where sku = :sku and stock >= :q`). ¿Qué ganas y qué dato pierdes para el mensaje de error?

⏱️ **30 segundos** — Se gana que no hay lectura previa ni bloqueo explícito: una sentencia atómica que resta solo si queda stock, y el número de filas afectadas dice si se reservó. Se pierde el dato para el mensaje: sin leer, no se sabe cuánto stock había.

🗣️ **2 minutos** — El contrato pide `detail: "SKU-004: requested 1, available 0"`. Con la actualización condicional, si afecta 0 filas hay que hacer otra consulta para saber si el producto no existe (`404`) o no hay stock suficiente (`409`) y cuánto queda, y esa consulta ya puede ver un valor distinto.

🔬 **El detalle** — Para contadores sin mensajes detallados es la mejor opción; aquí el contrato exige el detalle, y el bloqueo lo da gratis porque la fila ya está leída.

---

## 📖 08 — Eventos, jobs y dos instancias

### Preguntas

**08 → 1.** ¿Qué garantizaba escribir la notificación en la misma transacción que la cancelación, y qué costaba? 🟢

⏱️ **30 segundos** — Garantizaba atomicidad: nunca una cancelación sin notificación ni una notificación sin cancelación. Costaba que un fallo al escribir la notificación impidiera cancelar.

🗣️ **2 minutos** — Con la restricción inyectada en `notifications`, la cancelación respondió `500` y el pedido siguió `CONFIRMED`. La capacidad principal —cancelar, liberar stock— dependía de que una secundaria funcionara en ese mismo instante. Es acoplamiento temporal dentro del proceso.

🔬 **El detalle** — La atomicidad es valiosa y la *outbox* la conserva: el hecho de notificar se guarda atómicamente con la cancelación. Lo que cambia es que la entrega deja de estar en el camino crítico.

**08 → 2.** ¿Por qué el oyente `@Async @EventListener` produjo una notificación de un pedido no cancelado? 🟢

⏱️ **30 segundos** — Porque se ejecutó en cuanto se publicó el evento, en otro hilo y con su propia transacción, antes de que la cancelación confirmara. Cuando el `COMMIT` falló, la notificación ya estaba confirmada.

🗣️ **2 minutos** — `@EventListener` es síncrono respecto de la publicación, y `@Async` lo manda a otro hilo que no sabe nada de la transacción que lo originó. El *trigger* diferido rechazó el `COMMIT` de la cancelación; el oyente ya había escrito y confirmado la suya. Resultado: un pedido `CONFIRMED` con una notificación de cancelado.

🔬 **El detalle** — Es el error más común al «desacoplar con eventos»: el código queda desacoplado y los efectos no. Un efecto que sale de la transacción antes del `COMMIT` puede describir algo que nunca ocurrió.

**08 → 3.** ¿Qué hace `SKIP LOCKED` y qué pasaría con dos despachadores sin él? 🟢

⏱️ **30 segundos** — Hace que una consulta con `FOR UPDATE` salte las filas que otra transacción tiene bloqueadas, en lugar de esperar. Dos despachadores toman eventos distintos.

🗣️ **2 minutos** — Sin `SKIP LOCKED`, el segundo despachador esperaría el bloqueo del primero sobre el mismo evento; al liberarse, vería el evento ya entregado (si relee) o lo entregaría otra vez (si no). Con `SKIP LOCKED` cada uno avanza con lo que queda libre. En la corrida con dos instancias: 20 eventos, 19 entregados por una y 1 por la otra, ninguno dos veces.

🔬 **El detalle** — Sin bloqueo alguno sería peor: los dos leerían el mismo evento pendiente y lo entregarían los dos. Es el mismo *lost update* de la sobreventa del taller 07, aplicado a una cola.

**08 → 4.** ¿Por qué con dos instancias el mismo `GET` respondía `500` en una y `200` en la otra? 🟢

⏱️ **30 segundos** — Porque solo una instancia tenía la caché llena, y los pedidos de la caché no traían sus líneas cargadas: fuera de sesión, leerlas lanzaba `LazyInitializationException`. La otra leía de la base.

🗣️ **2 minutos** — La instancia `:38081` corría el cierre diario, que llena la caché con entidades sin sesión; `:38083` no. La misma petición dependía de a qué instancia llegara. Detrás de un balanceador, el cliente vería un `500` intermitente sin relación con lo que hizo.

🔬 **El detalle** — Es el defecto del taller 02 (la excepción a ratos) visto desde otro ángulo: con una instancia dependía del tiempo; con dos, también del enrutamiento.

**08 → 5.** ¿Por qué `AFTER_COMMIT` evita el fantasma pero pierde la notificación? 🟡

⏱️ **30 segundos** — Porque entrega después de que la cancelación confirme —si se deshace, no hay entrega—, pero entre el `COMMIT` y el oyente no queda nada guardado. Si el oyente falla, o el proceso muere, el hecho se pierde.

🗣️ **2 minutos** — Spring ejecuta los oyentes `AFTER_COMMIT` como una sincronización de la transacción ya confirmada. Una excepción del oyente se registra (`TransactionSynchronization.afterCompletion threw exception`) y no llega al cliente, que recibió `200`. Nadie reintenta porque el evento solo existía en memoria.

🔬 **El detalle** — La propiedad que falta es durabilidad del hecho. La *outbox* la da guardándolo en la misma transacción que lo produce.

**08 → 6.** ¿Por qué la *outbox* guarda el evento en la tabla de `orders` y no en la de `notifications`? 🟡

⏱️ **30 segundos** — Porque tiene que escribirse en la misma transacción que la cancelación, y esa transacción es de `orders`. La *outbox* es del productor del hecho, no del consumidor.

🗣️ **2 minutos** — Si la escribiera `notifications`, `orders` tendría que llamar a `notifications` dentro de su transacción, y volveríamos al acoplamiento de la sección 5. Con la tabla en `orders`, `orders` no sabe quién escucha; el despachador publica y cada interesado se suscribe. Por eso el grafo muestra `notifications → orders`.

🔬 **El detalle** — Con más consumidores (un informe, un correo, otro sistema), la misma fila de la *outbox* sirve a todos. Es el contrato de eventos de `orders`, igual que `OrderSnapshot` es su contrato de consulta.

**08 → 7.** ¿Qué papel cumple el `eventId` como id de la notificación? 🟡

⏱️ **30 segundos** — Hace idempotente al consumidor: si el mismo evento llega dos veces, la segunda no crea otra notificación, porque el `id` ya existe.

🗣️ **2 minutos** — La *outbox* garantiza entrega *al menos una vez*: un evento puede entregarse de nuevo si algo falla después de entregar y antes de marcarlo. Aquí la entrega y la marca van en la misma transacción, así que no ocurre; pero si el oyente escribiera en otro sistema, sí. Usar el `eventId` como clave convierte «al menos una vez» en «efectivamente una vez».

🔬 **El detalle** — Es la misma idea que la `Idempotency-Key` del taller 07, del lado del consumidor: una identidad estable para la operación, elegida por quien la origina.

**08 → 8.** ¿Por qué hizo falta un *constraint trigger* diferido para provocar el fallo al confirmar? 🟡

⏱️ **30 segundos** — Porque la restricción `CHECK` se comprobaba en el primer `flush`, y ese `flush` lo disparaba `release` antes de publicar el evento. La cancelación fallaba antes de publicar, y no había fantasma que ver.

🗣️ **2 minutos** — Un *constraint trigger* `DEFERRABLE INITIALLY DEFERRED` se ejecuta en el `COMMIT`, después de todo el código de la transacción. Así el fallo ocurre donde ocurren los fallos reales de confirmación: conflictos de serialización, restricciones diferidas, una conexión que se corta. Todo lo anterior —incluida la publicación del evento— ya pasó.

🔬 **El detalle** — La lección es sobre provocaciones: un fallo inyectado tiene que ocurrir en el momento que se quiere estudiar. Si no, la prueba demuestra algo distinto de lo que parece.

**08 → 9.** Arreglar la `LazyInitializationException` de la caché destapó otro defecto. ¿Cuál, y por qué era peor? 🟡

⏱️ **30 segundos** — Destapó la lectura obsoleta: con las líneas cargadas, `:38081` respondía `200` con `CONFIRMED` un pedido que `:38083` ya había cancelado. Era peor porque un `500` se ve y un dato viejo con `200` no.

🗣️ **2 minutos** — Mientras la caché lanzaba `LazyInitializationException`, el defecto era ruidoso: un error que alguien investiga. Al arreglar el síntoma, la caché empezó a responder rápido y mal, y un cliente habría actuado sobre un estado que ya no existía (intentar pagar un pedido cancelado, mostrarlo como activo).

🔬 **El detalle** — Por eso la corrección fue borrar la caché y no invalidarla: con dos instancias, invalidar exige coordinar, y un pedido por clave primaria ya se lee en milisegundos.

**08 → 10.** ¿Qué pasa con el cierre diario si la instancia que tiene el *lease* se cuelga sin morir? 🟠

⏱️ **30 segundos** — Mientras siga renovando el *lease*, nadie más lo toma, aunque no esté haciendo trabajo útil. Un proceso colgado que renueva es peor que uno muerto.

🗣️ **2 minutos** — El *lease* se renueva al empezar cada ejecución; si la instancia se cuelga dentro del job, no renueva, el *lease* vence y la otra lo toma. Si se cuelga de forma que el *scheduler* sigue disparando y renovando pero el trabajo no termina, el *lease* nunca vence. `batch_runs` lo delataría: dejarían de aparecer filas nuevas aunque el *lease* siguiera renovándose.

🔬 **El detalle** — La mitigación es renovar solo al terminar con éxito, o registrar un latido desde el propio trabajo, y vigilar con una alerta la antigüedad del último cierre completado. Un *lease* resuelve la exclusión; la salud del trabajo hay que medirla aparte.

**08 → 11.** Consultar `revoked_tokens` en cada petición cuesta una consulta. ¿Cómo lo abaratarías sin volver al problema de dos instancias? 🟠

⏱️ **30 segundos** — Cacheando en cada instancia solo lo que nunca deja de ser cierto —que un `jti` está revocado— y preguntando a la base por los demás; o aceptando, por contrato, unos segundos de retraso en ver revocaciones nuevas.

🗣️ **2 minutos** — Primero, medir: el token vence a los 15 minutos, la tabla es pequeña y la consulta es por clave primaria. Si hiciera falta abaratarla, un `jti` revocado sigue revocado para siempre, así que guardarlo en memoria no puede quedar obsoleto; lo que no se puede cachear es «no está revocado», porque eso sí cambia con un logout en otra instancia. Un TTL corto sobre esa respuesta negativa es una concesión explícita, no un detalle técnico.

🔬 **El detalle** — La otra palanca es acortar la vida del token: con tokens de pocos minutos y *refresh tokens*, la revocación solo tiene que cubrir una ventana corta, y lo que se revoca es el *refresh*.

**08 → 12.** Un compañero propone Redis para la caché, los tokens y los *leases*. ¿Qué ganas, qué pagas y qué harías primero? 🟠

⏱️ **30 segundos** — Ganas latencia y una estructura pensada para TTL y *leases*; pagas otro sistema que operar, otro punto de fallo y consistencia entre dos almacenes. Primero haría lo de este taller: llevar el estado a la base que ya compartes y medir.

🗣️ **2 minutos** — La caché se eliminó porque no aportaba; los tokens y los *leases* caben en tablas pequeñas. Redis tendría sentido si la medición muestra que la base es el cuello de botella para esas lecturas, o si hacen falta estructuras que PostgreSQL resuelve mal. Introducirlo antes es añadir una dependencia de runtime para un problema que no está demostrado.

🔬 **El detalle** — Además, Redis no arregla el diseño: una caché en Redis sigue pudiendo servir datos viejos, y un *lease* en Redis sigue necesitando vencimiento y relevo. Cambia dónde vive el estado, no las reglas.

**08 → 13.** Si `notifications` pasara a ser otro proceso, ¿qué parte de la *outbox* cambiaría y cuál no? 🔴

⏱️ **30 segundos** — Cambiaría la entrega: el despachador ya no escribiría en la misma base del consumidor, sino que enviaría a otro proceso (por HTTP o un *broker*), y la marca de entregado no podría confirmarse junto con la escritura del consumidor. No cambiaría la escritura del hecho en la transacción de `orders`.

🗣️ **2 minutos** — Sin transacción compartida, un evento puede enviarse y no marcarse (si el despachador muere en medio): se reenviará. El consumidor tendría que ser idempotente de verdad, con el `eventId`, que ya lo es. Aparecerían además reintentos con espera, una cola de eventos que no se pueden entregar y observabilidad de la cola.

🔬 **El detalle** — Es el paso que da el laboratorio de microservicios con un *broker*; la parte que este taller construyó —el hecho durable en la transacción del productor y el consumidor idempotente— es exactamente la que sobrevive a la distribución.

### Ejercicios

**08 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un evento de la *outbox* está entregado, y en qué transacción? Responde con rutas de `laboratorio/estados/08/`.

⏱️ **30 segundos** — En `laboratorio/estados/08/legacy/src/main/java/dev/mono/legacy/orders/internal/OutboxDispatcher.java:53` (`setPublishedAt`), dentro de la transacción que abre `tx.execute` en `dispatchOne`, la misma en la que se bloqueó el evento (`:46`) y se publicó a los oyentes (`:52`).

🗣️ **2 minutos** — Todo lo que ocurre entre esas líneas es una transacción: bloquear la fila con `SKIP LOCKED`, que el oyente de `notifications` escriba la notificación y marcar el evento. Si cualquier paso falla, se deshace todo y el evento sigue pendiente.

🔬 **El detalle** — La marca de entregado es lo que convierte la tabla en una cola; su posición dentro de la transacción es lo que la hace exacta.

**08 → E2.** 🟢 Repite la provocación de la sección 6 con el oyente asíncrono y cuenta cuántas notificaciones fantasma hay tras cinco cancelaciones fallidas.

⏱️ **30 segundos** — Cinco notificaciones fantasma: una por cada cancelación deshecha, porque el oyente asíncrono corre antes del `COMMIT` en todos los casos.

🗣️ **2 minutos** — La corrida del taller con una cancelación dio `pedido CONFIRMED, notificaciones 1`. Con cinco, el patrón se repite: cada publicación dispara el oyente en otro hilo, que confirma su propia transacción, y el *trigger* diferido rechaza después la cancelación. El número de fantasmas es el número de fallos al confirmar.

🔬 **El detalle** — Contarlos es útil para dimensionar el daño: en producción serían tantos como fallos de confirmación, un dato que casi nunca se mide.

**08 → E3.** 🟡 Con las notificaciones caídas, cancela tres pedidos y mira `attempts` en `outbox_events` cada segundo. ¿Qué pasa con los eventos que vienen detrás del primero, y cómo lo evitarías?

⏱️ **30 segundos** — Los eventos que vienen detrás del primero esperan: el despachador procesa por antigüedad y, cuando uno falla, termina la pasada. Si el primero no se puede entregar nunca (un evento venenoso), bloquea a todos los demás.

🗣️ **2 minutos** — Mientras las notificaciones están caídas, todos fallarían igual y no hay diferencia. Pero si solo un evento falla —un destinatario inválido, un dato corrupto—, se vuelve un bloqueo de cabeza de fila. Las salidas habituales son saltarlo tras N intentos (moverlo a un estado de «muerto» para revisión manual), o seguir con los siguientes en la misma pasada.

🔬 **El detalle** — El campo `attempts` ya permite la primera: `WHERE published_at IS NULL AND attempts < 10` en la consulta del despachador, y una alerta sobre los que superen el límite.

**08 → E4.** 🟡 **Orientación en código ajeno.** Encuentra todas las tablas que el legado crea sin entidad ni migración. ¿Qué pasaría con cada una en una base nueva?

⏱️ **30 segundos** — `job_leases` (la crea `LeaseSchema` con `CREATE TABLE IF NOT EXISTS`), y además el efecto de `drop-legacy-trigger.sql` que ejecuta `SchemaFixer`. Las demás las crea Hibernate con `ddl-auto: update` desde las entidades, que tampoco es una migración.

🗣️ **2 minutos** — En una base nueva, `job_leases` aparecería al arrancar el legado y el *trigger* no existiría nunca (el `DROP ... IF EXISTS` no hace nada). Funciona, pero el esquema real es la suma de lo que dejaron las entidades, dos componentes que ejecutan SQL al arrancar y lo que cada versión anterior dejó atrás, como las claves foráneas del taller 06.

🔬 **El detalle** — Es la lista de trabajo del taller 09: todo eso pasa a migraciones versionadas, y el esquema deja de depender de qué versión arrancó primero contra qué base.

**08 → E5.** 🟡 Mata con `kill -9` la instancia que tiene el *lease* justo después de que empiece el cierre diario. ¿Cuánto tarda la otra en tomarlo y qué queda en `batch_runs`?

⏱️ **30 segundos** — La otra instancia lo toma en cuanto vence, como mucho un periodo después (3 s con `--daily-close-ms 3000`). En `batch_runs` no queda rastro de la ejecución interrumpida: el legado guarda la fila al final, con `COMPLETED`.

🗣️ **2 minutos** — En la corrida del taller, con una parada ordinaria, `:38081` escribió su última fila a las 22:09:03.519 y `:38083` la siguiente a las 22:09:07.546: el relevo tardó un periodo. Con `kill -9` en medio del job, la ejecución a medias desaparece sin registro; si el job guardara la fila `STARTED` al empezar, se vería una ejecución sin final, que es mejor para diagnosticar.

🔬 **El detalle** — La consecuencia de diseño es que un job con *lease* tiene que ser seguro de reejecutar: la instancia que lo toma no sabe cuánto hizo la anterior. Para un recuento, trivial; para un job que cobra o envía ficheros, exige idempotencia.

**08 → E6.** 🟠 Borra las filas de `revoked_tokens` vencidas con un job que use el mismo *lease*. ¿Qué pasa si el borrado corre en las dos instancias?

⏱️ **30 segundos** — Un job `@Scheduled` que llame a `tryAcquire("revokedTokensCleanup", ...)` y borre `WHERE expires_at < now()`. Sin el *lease*, correría en las dos instancias.

🗣️ **2 minutos** — En este caso concreto, correr dos veces no hace daño: el segundo `DELETE` no encuentra nada que borrar, porque la operación es idempotente. El *lease* ahorra trabajo, no corrige errores. Es una distinción útil: un job idempotente tolera la duplicación; uno que no lo es la necesita evitar.

🔬 **El detalle** — Para decidir si hace falta el *lease*, la pregunta es qué pasa si corre dos veces a la vez. Si la respuesta es «nada», el *lease* es una optimización; si es «cobra dos veces», es obligatorio.

**08 → E7.** 🟠 Sustituye la *outbox* escrita a mano por el *Event Publication Registry* de Spring Modulith. Compara las tablas, los reintentos y lo que pierdes de control.

⏱️ **30 segundos** — Con `spring-modulith-starter-jpa` y los oyentes anotados con `@ApplicationModuleListener`, Modulith guarda cada publicación en su tabla `event_publication` en la transacción del productor y la marca completa cuando el oyente termina; las incompletas se pueden reenviar.

🗣️ **2 minutos** — Se gana no mantener código propio de *outbox* y una integración con las herramientas de Modulith (observabilidad de publicaciones, pruebas de eventos). Se pierde control fino: el formato de la tabla, la política de reintentos y la estrategia de concurrencia entre instancias son las del framework y hay que leerlas y configurarlas.

🔬 **El detalle** — Escribirla a mano en este taller sirvió para ver cada pieza; en un proyecto real, usar el registro de Modulith es la opción razonable salvo requisitos que no cubra.

**08 → E8.** 🔥 Mide la latencia de `GET /api/v1/orders/{id}` con y sin la caché, con `lab.py` y cien lecturas. ¿Justificaba la caché su existencia? Di de dónde sale la cifra y qué no mide.

⏱️ **30 segundos** — Hay que medir con el mismo cliente cien lecturas de un pedido con la caché (estado 07, tras el cierre diario) y sin ella (estado 08), y comparar medianas y percentiles, declarando que es una reproducción local, un solo nodo y sin red real.

🗣️ **2 minutos** — Lo esperable es que ambas estén en milisegundos: una lectura por clave primaria con un `JOIN` a las líneas es de las consultas más baratas que hay. La caché ahorraría una ida a la base en local, que es poco, y a cambio daba `500` o datos viejos. La cifra no mide carga concurrente, ni una base remota, ni el coste de invalidación que habría hecho falta.

🔬 **El detalle** — La conclusión no depende de la cifra exacta: una caché que devuelve datos incorrectos no se justifica por velocidad. Si la medición mostrara una diferencia relevante, la alternativa sería una caché con invalidación por evento o un TTL corto aceptado en el contrato.

---

## 📖 09 — Migraciones de esquema

### Preguntas

**09 → 1.** ¿Qué hace `baseline-on-migrate` y qué no comprueba? 🟢

⏱️ **30 segundos** — Crea la tabla de historia de Flyway en una base que ya tiene tablas y anota la versión de línea base como aplicada, sin ejecutarla. No comprueba que la base sea de verdad igual que esa versión.

🗣️ **2 minutos** — Sin la opción, Flyway se niega a arrancar sobre un esquema con tablas y sin historia (`Found non-empty schema(s) "public" but no schema history table`). Con ella, la base queda en V1 y se aplican V2 en adelante. Es una afirmación del equipo: «esta base ya es V1».

🔬 **El detalle** — Si la afirmación es falsa —porque a la base le faltan tablas o tiene restricciones que V1 no tiene—, nada lo detecta en ese momento. Por eso V2 hace converger lo que se sabe que difiere, y la validación de Hibernate y la suite son las redes que quedan.

**09 → 2.** ¿Por qué `ddl-auto` pasa a `validate` y no se quita sin más? 🟢

⏱️ **30 segundos** — Porque Flyway es el único autor del esquema y Hibernate pasa a comprobar que las entidades coinciden con él. Quitarlo del todo perdería esa comprobación.

🗣️ **2 minutos** — Con `update`, cualquier cambio en una entidad cambiaba la base al arrancar, sin revisión (el `ALTER` del taller 05). Con `validate`, un desajuste entre entidad y tabla detiene el arranque con un mensaje claro, en lugar de aparecer como error en la primera consulta.

🔬 **El detalle** — La validación no lo cubre todo: no mira índices ni restricciones, y una columna que la entidad ya no mapea (como `products.stock` en `contract`) no le importa. Es una red gruesa, útil y barata.

**09 → 3.** ¿Qué hace cada una de las tres fases de *expand/contract* en este taller? 🟢

⏱️ **30 segundos** — *Expand* añade `inventory` y la rellena sin quitar nada; *switch* empieza a leer de `inventory` y sigue escribiendo en las dos; *contract* deja de escribir `products.stock` y, cuando nadie la usa, V5 la borra.

🗣️ **2 minutos** — Cada fase es una versión de la aplicación que convive con la anterior. `expand` convive con el estado 08 porque este solo conoce `products.stock` y nadie lo lee de otro sitio. `switch` convive con `expand` porque las dos escriben las dos tablas. `contract` convive con `switch` porque `switch` ya no lee `products.stock`.

🔬 **El detalle** — La regla general: cada paso tiene que ser compatible con el anterior y con el siguiente, en código y en esquema. Si un paso rompe esa condición, hay que partirlo en dos.

**09 → 4.** ¿Por qué V5 vive en otra carpeta y no en `db/migration`? 🟢

⏱️ **30 segundos** — Para que no llegue con una versión que todavía convive con otra que usa la columna. Solo la versión `done`, que se despliega cuando todas las instancias están en `contract`, incluye la carpeta `db/contract`.

🗣️ **2 minutos** — Flyway aplica todo lo que encuentra en sus carpetas al arrancar. Si V5 estuviera en `db/migration`, la primera instancia con la versión nueva borraría la columna mientras otras la leen: la provocación de la sección 5. Separarla por carpeta convierte el orden de despliegue en algo que la herramienta respeta.

🔬 **El detalle** — Otras formas de lograr lo mismo son ejecutar la migración de contracción como un paso manual del pipeline o con una bandera explícita. Lo importante es que no dependa de que nadie se equivoque de orden.

**09 → 5.** ¿Por qué falló la versión del estado 08 cuando la nueva aplicó todas sus migraciones? 🟡

⏱️ **30 segundos** — Porque V5 borró `products.stock` mientras esa versión seguía leyendo la columna en cada consulta de productos: `column p1_0.stock does not exist`.

🗣️ **2 minutos** — La versión nueva aplicó V2 a V5 al arrancar, todas correctas para ella. La vieja no sabía nada del cambio: sus consultas seguían incluyendo la columna. Ocho de nueve archivos de la suite fallaron en la instancia vieja y ninguno en la nueva.

🔬 **El detalle** — Es el fallo típico de un despliegue gradual: durante minutos u horas conviven versiones, y el esquema es uno solo. Una migración solo es segura si funciona con todas las versiones que pueden estar vivas mientras se aplica.

**09 → 6.** ¿Por qué hay que retirar en una migración las claves foráneas que una base nueva ya no tiene? 🟡

⏱️ **30 segundos** — Porque la línea base solo anota V1: una base vieja seguiría teniendo esas claves y una nueva no. Dos esquemas distintos con la misma versión es la deriva que Flyway debía eliminar.

🗣️ **2 minutos** — V2 usa `DROP CONSTRAINT IF EXISTS`: en una base vieja las retira; en una nueva no hace nada. Después, las dos bases tienen las mismas restricciones. Además, la migración deja por escrito la decisión que el ORM había tomado sin nadie: las claves entre módulos se retiran porque cada módulo es dueño de sus tablas.

🔬 **El detalle** — La decisión contraria —conservarlas— también se podría escribir en V2, añadiéndolas a las bases nuevas. Lo que no vale es que cada base tenga lo que le tocó según su historia.

**09 → 7.** ¿Qué es la deriva del paso 1 y por qué V4 se aplica justo con `switch`? 🟡

⏱️ **30 segundos** — Son las diferencias entre `products.stock` e `inventory.stock` que aparecen mientras vive la versión del estado 08, que solo escribe la columna vieja. V4 va con `switch` porque es la primera versión que lee `inventory`, y solo se despliega cuando no queda ninguna instancia del estado 08.

🗣️ **2 minutos** — Tras una corrida contra la versión vieja había dos productos sin fila en `inventory` y cuatro con stock distinto. `expand` no lo sufre porque lee de `products`. Si V4 corriera antes, la versión vieja volvería a desalinear las tablas después.

🔬 **El detalle** — El patrón general es *backfill* al final de la ventana mixta: primero se deja de producir deriva (retirar la versión que no escribe las dos) y después se corrige una vez. Corregirlo antes es trabajo que se deshace solo.

**09 → 8.** ¿Qué garantiza que se pueda volver de `switch` a `expand` sin tocar el esquema? 🟡

⏱️ **30 segundos** — Que `expand` escribe las dos tablas y el esquema en V4 es compatible con ella: tiene `products.stock` y tiene `inventory`. Volver es desplegar el jar anterior.

🗣️ **2 minutos** — Flyway arranca aunque el esquema tenga una migración que esa versión no conoce: la trata como futura y avisa. Hibernate valida porque ninguna entidad cambió entre `expand` y `switch`. Las dos suites siguieron en verde tras el *rollback*.

🔬 **El detalle** — Lo que haría imposible volver es que la versión nueva hubiera escrito algo que la vieja no conoce o no lee. `switch` escribe lo mismo que `expand`, solo lee de otro sitio; por eso es reversible.

**09 → 9.** ¿Por qué la variante que bloqueaba solo la tabla que leía se interbloqueaba? 🟡

⏱️ **30 segundos** — Porque cada versión bloqueaba primero la tabla que leía y después escribía la otra: `expand` iba de `products` a `inventory` y `switch` de `inventory` a `products`. Dos transacciones con los recursos en orden opuesto se esperan mutuamente.

🗣️ **2 minutos** — PostgreSQL detectó 64 interbloqueos en tres tormentas y abortó una transacción en cada uno; mientras esperaba al detector (un segundo por defecto), las conexiones retenidas agotaron el pool. El resultado fue casi todo en `500`, no una venta de más. La corrección fue que las dos versiones bloqueen las dos filas y en el mismo orden.

🔬 **El detalle** — Es la regla del taller 07 —ordenar los recursos antes de bloquearlos— aplicada a dos versiones del mismo código. Una prueba con una sola instancia no lo habría visto nunca.

**09 → 10.** Flyway avisa pero arranca con un esquema más nuevo. ¿Es un defecto o una ventaja? 🟠

⏱️ **30 segundos** — Las dos cosas. Es la condición para el *rollback* de aplicación y, a la vez, deja arrancar una versión incompatible con el esquema.

🗣️ **2 minutos** — Si Flyway se negara a arrancar ante migraciones desconocidas, volver de `switch` a `expand` exigiría deshacer V4, que es justo lo que se quiere evitar. Pero la misma tolerancia dejó arrancar `switch` después de V5, y falló en el primer pedido.

🔬 **El detalle** — La compatibilidad entre versión y esquema no la puede decidir Flyway, porque depende de qué columnas usa cada versión. Se garantiza con el orden de los pasos y se comprueba con la suite contra cada versión viva; Flyway puede ser más estricto (`ignoreMigrationPatterns`) si el equipo prefiere fallar al arrancar.

**09 → 11.** Te piden hacer este cambio «en un solo despliegue, que es solo una columna». ¿Qué respondes y qué evidencia muestras? 🟠

⏱️ **30 segundos** — Que un despliegue único rompe a las instancias viejas mientras dura, y que el taller lo midió: ocho de nueve archivos en rojo en la instancia vieja. Propondría los pasos, con el coste explícito.

🗣️ **2 minutos** — La evidencia es la sección 5 frente a la 8: aplicar todo de golpe con la versión anterior viva frente a siete pasos con las dos suites en verde en cada uno. Si el equipo puede parar el servicio (una ventana de mantenimiento con todas las instancias apagadas), el despliegue único es válido y más barato; es una decisión de negocio, no técnica.

🔬 **El detalle** — Lo que no es aceptable es no decidirlo: «es solo una columna» describe el tamaño del cambio, no su compatibilidad con la versión que está sirviendo tráfico.

**09 → 12.** Después de V5 descubres un error en `contract` y necesitas volver a `switch`. ¿Qué haces? 🟠

⏱️ **30 segundos** — Una migración hacia delante que recrea `products.stock` y la rellena desde `inventory`, y después desplegar `switch`. No un `DOWN` que la recree vacía.

🗣️ **2 minutos** — La columna recreada sin datos haría que `switch` escribiera sobre ceros y que cualquier lector de `products.stock` viera stock falso. Rellenarla desde `inventory`, que es la verdad en ese momento, deja el esquema como estaba en V4. Mientras tanto, las instancias en `contract` siguen funcionando porque no usan la columna.

🔬 **El detalle** — La lección es que el paso sin retorno es sin retorno *barato*: volver es posible, pero es otro cambio planificado, con su propia migración y su propia prueba. Por eso V5 va sola y al final.

**09 → 13.** ¿Qué cambiaría si `inventory` estuviera en otra base, de otro proceso? 🔴

⏱️ **30 segundos** — Cambiaría todo lo que hoy es una transacción: el bloqueo de las dos filas, la escritura doble y V4 dejarían de ser atómicos. Serían dos bases, dos procesos y una sincronización con fallos parciales.

🗣️ **2 minutos** — La escritura doble pasaría a ser un evento o una llamada remota, con la posibilidad de escribir en una base y no en la otra; la re-sincronización sería una reconciliación entre sistemas; y no habría forma de bloquear las dos filas juntas. El *expand/contract* seguiría siendo la forma de cambiar, pero cada paso sería más largo y más frágil.

🔬 **El detalle** — Es exactamente lo que el taller 10 provoca al sacar `inventory` a otro proceso con la base compartida, y lo que muestra por qué separar datos dentro del monolito primero —como aquí— es el paso barato.

### Ejercicios

**09 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea decide una versión si lee el stock de `products` o de `inventory`? Responde con rutas de `laboratorio/estados/09/`.

⏱️ **30 segundos** — En `laboratorio/estados/09/legacy/src/main/java/dev/mono/legacy/inventory/internal/StockStore.java`: el paso se lee en la línea 25 y la decisión de lectura está en `lockAndRead` (líneas 37–40) y en `read`.

🗣️ **2 minutos** — `readsLegacyColumn()` es verdadero solo en `expand`; `writesLegacyColumn()`, en todos los pasos salvo `contract`. El valor viene de `legacy.inventory.step` (`application.yaml:42`), que `lab.py legacy --inventory-step` sobrescribe.

🔬 **El detalle** — Tener la decisión en una sola clase es lo que permite que cada paso sea una línea de configuración y no un conjunto de cambios repartidos por el módulo.

**09 → E2.** 🟢 Arranca la versión nueva sobre una base del estado 08 sin línea base y pega el error. Después, con línea base, pega `flyway_schema_history`.

⏱️ **30 segundos** — Sin línea base: `Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.`, y la aplicación no arranca. Con línea base, `flyway_schema_history` muestra V1 como `BASELINE` y V2 y V3 como `SQL`.

🗣️ **2 minutos** — La fila de tipo `BASELINE` no tiene suma de verificación: no corresponde a un script ejecutado. Las siguientes sí, y Flyway comprobará en cada arranque que esos scripts no cambiaron.

🔬 **El detalle** — Esa comprobación es la razón por la que una migración aplicada no se edita: se escribe otra.

**09 → E3.** 🟡 Repite la provocación de la sección 5 y mide cuánto tiempo pasa entre el arranque de B y el primer `500` de A. ¿Qué te dice eso de un despliegue gradual con diez instancias?

⏱️ **30 segundos** — Unos segundos: lo que tarda B en arrancar y aplicar las migraciones (unas decenas de milisegundos las cuatro). La primera consulta de productos de A después de V5 falla.

🗣️ **2 minutos** — Con diez instancias y un despliegue gradual, la primera instancia nueva rompe a las nueve viejas en cuanto aplica V5, y siguen rotas hasta que cada una se reemplaza. Cuanto más lento el despliegue, más tiempo en error.

🔬 **El detalle** — El tiempo que importa no es el de la migración sino el de la ventana en la que conviven versiones. Por eso la compatibilidad se diseña para esa ventana.

**09 → E4.** 🟡 **Orientación en código ajeno.** Encuentra todo el código que sabe que existe `products.stock` en el estado 09. ¿Qué habría que borrar después de V5?

⏱️ **30 segundos** — `StockStore` (las ramas de `expand` y `switch`), `V1`, `V3` y `V4` (que la usan o la rellenan) y la semilla (que la escribe si existe). Tras V5, las ramas de `StockStore` que la usan son código muerto.

🗣️ **2 minutos** — Después de V5 se puede simplificar `StockStore` a una sola tabla y retirar `legacy.inventory.step`. Las migraciones no se tocan: son historia, y una base nueva las necesita para llegar a V5.

🔬 **El detalle** — Limpiar el código de transición es el último paso del *contract*, y suele olvidarse. Una bandera de migración que sobrevive años es deuda con nombre.

**09 → E5.** 🟡 Añade una columna `reserved` a `inventory` con *expand/contract*, sin parar las dos instancias. Escribe las migraciones y la tabla de pasos.

⏱️ **30 segundos** — V6 en `db/migration` añade `reserved integer NOT NULL DEFAULT 0` a `inventory` (compatible con todas las versiones); una versión que la escribe y no la lee; otra que la lee; y, si `reserved` sustituye a otro dato, una migración de contracción al final.

🗣️ **2 minutos** — La tabla de pasos: 1) V6 + versión que ignora la columna; 2) versión que escribe `reserved`; 3) *backfill* si hace falta; 4) versión que lee `reserved`. Añadir una columna con valor por defecto es el caso fácil: es *expand* puro y casi siempre compatible.

🔬 **El detalle** — El caso difícil es cambiar el significado de algo que ya existe. Añadir es barato; renombrar, cambiar tipos o mover datos es lo que exige los pasos completos.

**09 → E6.** 🟠 Escribe la migración hacia delante que recuperaría `products.stock` después de V5 (sección 9) y pruébala con una versión `switch`.

⏱️ **30 segundos** — Una V6 en `db/migration` que hace `ALTER TABLE products ADD COLUMN stock integer NOT NULL DEFAULT 0` y la rellena con `UPDATE products p SET stock = i.stock FROM inventory i WHERE i.sku = p.sku`, y después desplegar `switch`.

🗣️ **2 minutos** — Con la columna rellena, `switch` vuelve a funcionar: lee `inventory` y escribe las dos. Mientras se aplica, las instancias en `contract` no se enteran. Hay que probarlo con la suite contra una instancia `switch` y otra `contract`, igual que los pasos originales.

🔬 **El detalle** — Es la misma técnica que hacia delante, en sentido contrario. Lo que no existe es el atajo: no hay forma de «deshacer» V5 sin un paso de datos.

**09 → E7.** 🟠 Sustituye la escritura doble en la aplicación por un *trigger* temporal de sincronización. ¿Qué ganas en los pasos mixtos y qué pierdes frente al taller 06, que sacó la lógica de los *triggers*?

⏱️ **30 segundos** — Un *trigger* en `products` que copie cada cambio de `stock` a `inventory` haría que el estado 08 no produjera deriva y que V4 no hiciera falta. Se pierde lo que el taller 06 ganó: la lógica vuelve a estar en la base, invisible para quien lee el código.

🗣️ **2 minutos** — La diferencia con el *trigger* del legado es la intención: este es temporal, tiene fecha de retirada y vive en una migración. Si se retira en el paso *contract*, es un andamio razonable; si se queda, es el mismo pecado.

🔬 **El detalle** — En equipos donde el código de la aplicación no se puede cambiar deprisa, el *trigger* de sincronización es la opción habitual. Aquí la escritura doble en la aplicación era posible y deja la lógica a la vista.

**09 → E8.** 🔥 Mide cuánto tarda V3 con un millón de productos y decide si la copia debe ir en la migración o en un proceso aparte por lotes.

⏱️ **30 segundos** — Con un millón de filas, V3 copia la tabla en una sola transacción y crea la clave primaria y la foránea; el tiempo depende de la máquina y hay que medirlo en una copia con datos de producción.

🗣️ **2 minutos** — Si la copia tarda más de lo que el despliegue puede esperar, se saca de la migración: V3 solo crea la tabla, y un proceso por lotes rellena por rangos de SKU fuera de la transacción de arranque, con la escritura doble ya activa. V4 (la re-sincronización) cubre lo que cambie durante la copia.

🔬 **El detalle** — La cifra de la medición hay que etiquetarla —una máquina, sin carga concurrente— y lo que decide no es el tiempo total, sino cuánto bloquea la tabla que la versión viva está usando.

---

## 📖 10 — El monolito distribuido provocado

### Preguntas

**10 → 1.** ¿Qué garantía perdió el pedido al sacar el inventario a otro proceso, aunque el código de reserva no cambiara? 🟢

⏱️ **30 segundos** — La atomicidad entre el pedido y sus reservas. Antes, todas las reservas estaban en la transacción del pedido; después, cada reserva es una transacción confirmada en otro proceso, y el pedido puede deshacerse sin deshacerlas.

🗣️ **2 minutos** — `hurl/v1` lo midió: el pedido con `SKU-001` y `SKU-004` falla por la segunda línea, el legado deshace su pedido, y `SKU-001` queda en 19 en lugar de 20. El código de reserva era el mismo; lo que cambió es dónde terminaba la transacción.

🔬 **El detalle** — Es la «falsa transacción» de `04/05`: dos operaciones que el código trata como una unidad y que el sistema ya no puede confirmar juntas. Recuperarla exige compensación explícita, que es código nuevo con sus propios fallos.

**10 → 2.** ¿Por qué el catálogo seguía funcionando con `mono-inventory` caído en la extracción ingenua, y por qué no es una buena noticia? 🟢

⏱️ **30 segundos** — Porque el catálogo leía la tabla `inventory` directamente, sin pasar por `mono-inventory`. No es buena noticia porque significa que el legado depende del esquema del otro proceso: cuando ese esquema cambió, el catálogo se rompió.

🗣️ **2 minutos** — La disponibilidad aparente del catálogo era un efecto de la base compartida, no de un buen diseño. Cambió un acoplamiento de runtime por uno de esquema, que duele más tarde y en otro sitio: el renombre de la columna dejó el catálogo en `500`.

🔬 **El detalle** — En la salida 2, con el catálogo leyendo por la API, pasó lo contrario: esquema libre y catálogo caído con el proceso. Ninguna de las dos variantes es gratis; lo que se elige es qué acoplamiento se prefiere pagar.

**10 → 3.** ¿Qué es el despliegue en *lockstep* y cómo lo midió el taller? 🟢

⏱️ **30 segundos** — Es la obligación de desplegar dos componentes a la vez porque ninguno funciona con la versión anterior del otro. El taller desplegó el renombre de la columna en los dos órdenes posibles y en los dos obtuvo 4 de 9 archivos en verde; solo con los dos desplegados, 8 de 9.

🗣️ **2 minutos** — Primero `mono-inventory` renombrado con el legado viejo: el legado lee una columna que ya no existe. Primero el legado leyendo `on_hand` con `mono-inventory` viejo: el legado lee una columna que todavía no existe. No hay orden seguro, así que el despliegue tiene que ser simultáneo.

🔬 **El detalle** — Dos procesos que solo se despliegan juntos son un despliegue con más piezas: todo el coste de coordinar sin la autonomía que justificaría separarlos. La salida 2 lo eliminó: el renombre pasó con el legado intacto, 9 de 9.

**10 → 4.** ¿Por qué un timeout de la reserva fuga stock en `remote-naive` y no en `remote`? 🟡

⏱️ **30 segundos** — Porque en `remote-naive` el legado no sabe si la reserva se aplicó y no tiene con qué deshacerla; en `remote` la reserva tiene un id, y la compensación libera ese id aunque no sepa si llegó a reservarse.

🗣️ **2 minutos** — Con la respuesta retrasada 2,5 s y un timeout de 2 s, `mono-inventory` reservó y confirmó; el legado vio un error y deshizo su pedido. Sin id, liberar a ciegas podría devolver stock que nunca se reservó. Con id, `mono-inventory` libera si la reserva existe y deja una lápida si no: stock 100 y la reserva `RELEASED`.

🔬 **El detalle** — La idempotencia por identificador es lo que convierte un resultado incierto en una operación que se puede repetir sin miedo. Es la misma idea que la `Idempotency-Key` del taller 07, ahora entre dos procesos propios.

**10 → 5.** ¿Qué hace la lápida `RELEASED` y qué carrera evita? 🟡

⏱️ **30 segundos** — Marca como liberado un id de reserva que nunca llegó a reservarse, para que si esa reserva llega después —retrasada por la red— no se aplique. Evita que la compensación llegue antes que lo que compensa.

🗣️ **2 minutos** — Sin lápida, la secuencia «la reserva se retrasa, el legado agota el timeout y libera, la liberación no encuentra nada, la reserva llega» dejaría la unidad reservada para siempre. Con la lápida, la reserva tardía encuentra el id en `RELEASED` y responde `409 RESERVATION_RELEASED`.

🔬 **El detalle** — Es el patrón general de las operaciones compensables: la compensación tiene que ser válida en cualquier orden respecto de la operación, porque en una red no hay garantía de orden.

**10 → 6.** ¿Por qué la compensación se registra antes de llamar a `mono-inventory` y no después? 🟡

⏱️ **30 segundos** — Porque si la llamada falla por la red, la reserva pudo aplicarse, y la compensación tiene que existir ya. Si se registrara al recibir la respuesta, un timeout la dejaría sin registrar.

🗣️ **2 minutos** — `InventoryService` registra una sincronización de transacción con el id y después llama. Si la transacción del pedido no confirma por cualquier motivo —el timeout de esta misma llamada, otra línea sin stock, un fallo al confirmar—, `afterCompletion` libera ese id. Liberar un id que nunca se reservó solo deja una lápida.

🔬 **El detalle** — La regla: la compensación se prepara antes del efecto incierto, no después. Es la misma lógica que la *outbox* del taller 08, que guarda el hecho antes de que se pueda perder.

**10 → 7.** La salida 2 hizo que el catálogo dependa de `mono-inventory` en runtime. ¿Es un error del diseño o un precio? 🟡

⏱️ **30 segundos** — Es un precio de la decisión, no un error: al dar la tabla a un solo dueño, el legado tiene que preguntarle, y preguntar exige que esté vivo. Se cambió acoplamiento de esquema por acoplamiento temporal.

🗣️ **2 minutos** — Hay formas de bajarlo: una copia local del stock para lectura, alimentada por eventos de `mono-inventory`, con consistencia eventual; o degradar el catálogo mostrando el stock como «desconocido» cuando no responde. Las dos son más código y una garantía distinta (el stock mostrado puede estar atrasado).

🔬 **El detalle** — Lo importante es que la decisión sea consciente: la salida 2 no es «mejor» en todas las monedas. La matriz de la sección 11 lo muestra en la fila de runtime.

**10 → 8.** ¿Qué evidencia de la matriz sostiene el diagnóstico de monolito distribuido, y cuál falta? 🟡

⏱️ **30 segundos** — La sostienen cuatro monedas con evidencia medida: código (el renombre exige cambiar los dos procesos), datos (dos escritores y una clave foránea entre procesos), despliegue (*lockstep*, 4 de 9 en cualquier orden) y runtime (sin `mono-inventory` no hay pedidos). Falta la de equipos, que en un laboratorio de una persona no se puede medir.

🗣️ **2 minutos** — El diagnóstico de `04/01` exige evidencia recurrente y ausencia de beneficio compensatorio. El beneficio también se buscó: ningún despliegue independiente real, ninguna escala distinta, ningún equipo distinto. Sin él, las cuatro monedas en contra bastan.

🔬 **El detalle** — La fila de equipos es la que podría cambiar la conclusión: si hubiera un equipo de inventario con su propio ritmo, la salida 2 compraría algo que la organización necesita. Esa evidencia no la da el código.

**10 → 9.** ¿Por qué la semilla se rompió con el renombre, y qué dice eso de las bases compartidas? 🟡

⏱️ **30 segundos** — Porque la semilla escribía `inventory(sku, stock)` y la columna ya se llamaba `on_hand`. La semilla era un cliente de la tabla que nadie había contado.

🗣️ **2 minutos** — En una base compartida, los usuarios de una tabla no son solo los procesos del diagrama: son *scripts*, informes, herramientas de soporte, semillas de prueba y consultas manuales. Cada uno es un consumidor del esquema sin contrato. Un cambio seguro para los procesos conocidos rompe a los desconocidos.

🔬 **El detalle** — La propiedad de datos no los elimina, pero los hace visibles: si solo `mono-inventory` puede tocar la tabla (con permisos de la base, no por convención), los demás tienen que pasar por su API o fallar al instante, no semanas después.

**10 → 10.** El equipo quiere mantener `mono-inventory` «para escalar el inventario en el futuro». ¿Qué le pides antes de aceptarlo? 🟠

⏱️ **30 segundos** — Evidencia de que esa escala es necesaria y de que no se puede lograr dentro del monolito: carga medida, cuello de botella localizado en el inventario, y el coste de escalar el monolito entero frente al de mantener dos procesos.

🗣️ **2 minutos** — Un monolito escala horizontalmente —el taller 08 lo puso en dos instancias—, y el cuello de botella del inventario es una fila bloqueada, que no se arregla con más procesos. Mantener la distribución «por si acaso» es pagar hoy red, compensaciones, *lockstep* o acoplamiento temporal por una necesidad hipotética.

🔬 **El detalle** — La respuesta proporcional: fusionar ahora, mantener el módulo con su API (ya existe desde el taller 06) y extraerlo cuando la evidencia aparezca. La modularidad interna es lo que hace barata esa extracción futura.

**10 → 11.** Con la salida 2, ¿cómo harías que el catálogo sobreviviera a la caída de `mono-inventory` y qué consistencia aceptarías? 🟠

⏱️ **30 segundos** — Con una copia local del stock para lectura en el legado, alimentada por eventos de `mono-inventory` (reservas y liberaciones), y aceptando que el stock mostrado pueda ir unos segundos por detrás. Las reservas seguirían siendo síncronas.

🗣️ **2 minutos** — El catálogo leería su copia; si `mono-inventory` cae, el catálogo sigue con el último stock conocido, marcado quizá como aproximado. Los pedidos seguirían necesitando al dueño, porque la reserva es la operación que no se puede aproximar. Para alimentar la copia hacen falta una *outbox* en `mono-inventory` y un consumidor idempotente en el legado: el taller 08 en los dos lados.

🔬 **El detalle** — La consistencia aceptada tiene que estar en el contrato: «el stock del catálogo es orientativo; la reserva decide». Es una decisión de producto, no solo técnica.

**10 → 12.** Un entrevistador dice que fusionar es un paso atrás. ¿Cómo lo defiendes con los datos de este taller? 🟠

⏱️ **30 segundos** — Con la matriz: fusionar recuperó la transacción, eliminó las tres provocaciones y dejó la latencia en 13 ms frente a 17; la distribución no compraba ni despliegue independiente real ni escala. No es un paso atrás, es quitar un coste que no pagaba nada.

🗣️ **2 minutos** — «Paso atrás» supone que los servicios son una etapa superior, que es el error que el curso desmonta (§4.2 de la guía). La pregunta correcta es qué autonomía compra cada topología. Aquí la respuesta medida era «ninguna», y lo que queda del esfuerzo —el módulo con API, la tabla con un dueño— se conserva dentro del monolito.

🔬 **El detalle** — Si el entrevistador insiste, la respuesta madura es decir qué evidencia cambiaría la decisión: un equipo independiente, una escala distinta, un despliegue que realmente necesite ser independiente. Con ella, la salida 2 estaría preparada.

**10 → 13.** Diseña la extracción de `inventory` desde cero con lo aprendido: qué harías antes de separar el proceso y en qué orden. 🔴

⏱️ **30 segundos** — Primero, dentro del monolito: módulo con API y dueño (taller 06), tabla propia (09), reservas con identificador y compensación diseñadas mientras todavía hay una transacción que las cubra. Después, el proceso: con su contrato y sus migraciones desde el primer día, y la base separada en cuanto el proceso esté estable.

🗣️ **2 minutos** — El orden importa porque cada paso dentro del monolito se prueba y se revierte barato. Aquí se extrajo sobre la tabla compartida y sin contrato, y cada problema apareció en producción (en el laboratorio): la falsa transacción, la fuga por timeout, el *lockstep*. Con los pasos previos hechos, la extracción es mover una implementación detrás de una interfaz que ya existe.

🔬 **El detalle** — Y antes de todo, la pregunta de `05/04`: qué autonomía se quiere comprar y quién la va a usar. Si nadie la usa, el mejor diseño de extracción es no extraer.

### Ejercicios

**10 → E1.** 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea decide el legado liberar una reserva remota porque el pedido no se confirmó? Responde con rutas de `laboratorio/estados/10/`.

⏱️ **30 segundos** — En `laboratorio/estados/10/legacy/src/main/java/dev/mono/legacy/inventory/InventoryService.java:96` (`afterCompletion`), registrado en la línea 56 antes de llamar a `mono-inventory`.

🗣️ **2 minutos** — `afterCompletion` recibe el estado final de la transacción; si no es `STATUS_COMMITTED`, llama a `RemoteInventory.release` con el mismo `reservationId`. Un error en esa llamada se registra como «compensación pendiente» y no se reintenta.

🔬 **El detalle** — Es el punto débil que señala la sección 12: la compensación depende de una llamada que puede fallar, y en el laboratorio solo queda en el log.

**10 → E2.** 🟢 Repite la falsa transacción de la sección 6 y encuentra en la base la unidad reservada para nadie. ¿Qué consulta la delata?

⏱️ **30 segundos** — Tras el pedido fallido, `SELECT sku, stock FROM inventory WHERE sku = 'SKU-001'` devuelve 19 y no hay ningún pedido con líneas de `SKU-001` que la justifique.

🗣️ **2 minutos** — La consulta que lo delata compara el stock con lo reservado por pedidos vivos: `20 - coalesce(sum(quantity), 0)` de `order_lines` unidas a pedidos no cancelados, frente a `inventory.stock`. Si difieren, hay unidades reservadas para nadie.

🔬 **El detalle** — Es la conciliación que un sistema distribuido necesita de forma periódica: sin transacción común, alguien tiene que comprobar que las dos contabilidades cuadran.

**10 → E3.** 🟡 Con `remote-naive`, lanza `lab.py storm orders --n 20`. ¿Se vende de más? Explica quién bloquea qué fila.

⏱️ **30 segundos** — No: en la corrida del 2026-09-29, `HTTP 201 × 5, HTTP 409 × 15` y stock 0. `mono-inventory` bloquea la fila de `inventory` con `FOR NO KEY UPDATE` en su transacción, así que las veinte reservas se serializan en su proceso.

🗣️ **2 minutos** — La exclusión mutua se movió de la transacción del legado a la de `mono-inventory`. Lo que sí cambia es la latencia (cada reserva es una ida y vuelta) y el comportamiento ante fallos: una reserva que agote el timeout fuga stock en `remote-naive`.

🔬 **El detalle** — El ejercicio muestra que la distribución no rompe todas las garantías: rompe las que dependían de la transacción que se partió, y conserva las que el nuevo dueño implementa en la suya.

**10 → E4.** 🟡 **Orientación en código ajeno.** Lista todas las sentencias SQL del legado que tocan `inventory` en cada modo. ¿Cuántas quedan en `remote`?

⏱️ **30 segundos** — En `local`: el bloqueo, la resta, la suma y el alta en `StockStore`, más la lectura del catálogo. En `remote-naive`: la lectura del catálogo y el alta de productos (`StockStore.read` e `initialize`) siguen tocando la tabla. En `remote`: ninguna.

🗣️ **2 minutos** — Esa lista es la medida del acoplamiento de datos: cada sentencia es un sitio que se rompe si el dueño cambia el esquema. La sección 8 lo confirmó con el renombre: el legado falló justo en esas sentencias, incluidas las de escritura que el primer intento de *lockstep* olvidó.

🔬 **El detalle** — Buscar las sentencias en el código no basta: los *scripts* y las semillas también cuentan, como mostró la sección 12.

**10 → E5.** 🟡 Mide la latencia de `lab.py bench` con `lab.py proxy inventory --latency 50` en `remote` y en `local`. ¿Qué parte del tiempo de un pedido se va en la red?

⏱️ **30 segundos** — Con 50 ms añadidos por respuesta, cada pedido en `remote` paga al menos esos 50 ms por línea; en `local`, nada. Hay que medirlo con `lab.py bench` en los dos modos, con la misma etiqueta de reproducción local.

🗣️ **2 minutos** — Sin tóxicos, la diferencia medida fue de 13 a 17 ms de mediana: la red local es casi gratis. Con una red real, la latencia de cada llamada entre procesos se suma a cada pedido y a cada lectura del catálogo, y en el percentil 95 más todavía.

🔬 **El detalle** — El número exacto depende de la red; lo estructural es que cada frontera de proceso en el camino crítico añade su latencia y su probabilidad de fallo a la de la operación.

**10 → E6.** 🟠 Escribe la migración de `mono-legacy` que retira las tablas huérfanas tras la fusión. ¿Qué comprobarías antes de aplicarla?

⏱️ **30 segundos** — Una V6 en `mono-legacy` que hace `DROP TABLE IF EXISTS inventory_reservations` y `DROP TABLE IF EXISTS flyway_inventory_history`, y, si se quiere, vuelve a crear la clave `inventory → products`.

🗣️ **2 minutos** — Antes de aplicarla: comprobar que ningún proceso ni *script* usa esas tablas (que `mono-inventory` esté retirado de todos los entornos) y que no quedan reservas `RESERVED` sin conciliar, porque representan stock descontado. Si quedan, se concilian primero.

🔬 **El detalle** — Es el *contract* de la fusión: la salida 1 también tiene su paso sin retorno, y por eso va al final y con comprobaciones.

**10 → E7.** 🟠 Haz que la compensación fallida se reintente con la *outbox* del taller 08. ¿Qué garantiza y qué ventana queda?

⏱️ **30 segundos** — La liberación pendiente no puede escribirse en la transacción del pedido, porque esa es la que se deshizo. Se registra antes, en una transacción propia: al intentar la reserva, una fila «reserva X intentada» en una tabla local; un despachador, como el de la *outbox* del taller 08, libera por id las que no tengan pedido confirmado pasado un tiempo, y reintenta hasta que `mono-inventory` responda.

🗣️ **2 minutos** — Garantiza que ninguna reserva huérfana sobreviva indefinidamente, porque la liberación es idempotente y se reintenta hasta confirmarse. Deja una ventana: mientras el despachador no pasa, el stock está retenido de más.

🔬 **El detalle** — Es la diferencia entre compensación inmediata y conciliación periódica: la primera es rápida y falible, la segunda es lenta y segura. Los sistemas reales suelen necesitar las dos.

**10 → E8.** 🔥 Da al catálogo una copia local del stock alimentada por eventos de `mono-inventory`. Mide qué pasa con `GET /products` con el proceso caído y con qué retraso refleja una reserva.

⏱️ **30 segundos** — El catálogo lee de una tabla local (en el legado) que un consumidor actualiza con eventos de reserva y liberación publicados por `mono-inventory` desde su *outbox*. Con el proceso caído, `GET /products` responde con el último stock conocido.

🗣️ **2 minutos** — El retraso en reflejar una reserva es el del despachador de la *outbox* más el del consumidor: con los 500 ms del taller 08, del orden de un segundo en local. Hay que medirlo y declararlo en el contrato del catálogo.

🔬 **El detalle** — El coste: otra tabla, otro despachador, otro consumidor idempotente y un stock mostrado que puede estar atrasado. Es exactamente la clase de maquinaria que un monolito no necesita, y por eso solo se justifica si la separación compra algo.

---
