# 10 — Respuestas: Monolito distribuido

> Solucionario completo de los capítulos y de la simulación. Cada enunciado se conserva literalmente y cada respuesta usa tres capas.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--anatomía-y-evidencia-del-monolito-distribuido) · [02](#-02--cadenas-síncronas-y-acoplamiento-temporal) · [03](#-03--base-compartida-escrituras-cruzadas-y-propiedad-difusa) · [04](#-04--contratos-frágiles-y-despliegues-coordinados) · [05](#-05--fallos-parciales-retries-y-falsas-transacciones) · [06](#-06--acoplamiento-asíncrono-el-monolito-distribuido-con-broker) · [07](#-07--cómo-se-llega-granularidad-entidades-y-plataforma-compartida) · [08](#-08--desmontar-un-monolito-distribuido) · [Simulación](#-respuestas-de-la-simulación)

## 📖 01 — Anatomía y evidencia del monolito distribuido

### 1. 🟢 ¿Qué es un monolito distribuido?

⏱️ **30 segundos:** Un sistema desplegado en varios procesos cuyos componentes siguen cambiando, liberándose y fallando juntos, de modo que paga la red sin obtener autonomía.

🗣️ **2 minutos:** Tiene la topología de servicios y el acoplamiento de un monolito: un cambio pequeño cruza componentes, el esquema es de todos, el release es conjunto y la operación necesita la cadena completa. Suma los costes de ambos mundos y no obtiene el beneficio de ninguno.

🔬 **El detalle:** El término describe un estado, no una intención: casi nadie diseña un monolito distribuido; se llega por cortes que no separaron cambio ni datos.

### 2. 🟢 ¿Qué diferencia hay entre autonomía nominal y autonomía efectiva?

⏱️ **30 segundos:** La nominal es tener repositorio, pipeline y contenedor propios; la efectiva es poder cambiar, desplegar y operar la capacidad sin esperar a otros equipos.

🗣️ **2 minutos:** Los cinco componentes del caso tienen autonomía nominal completa y casi ninguna efectiva: la expiración de reservas esperó a tres equipos y al release train. La nominal es necesaria para la efectiva, pero no la produce.

🔬 **El detalle:** La autonomía efectiva se mide en el historial —cuántos cambios salieron solos— y no en la infraestructura.

### 3. 🟢 ¿Qué evidencia mira cada una de las cinco monedas en este diagnóstico?

⏱️ **30 segundos:** Código: cuántos componentes toca un cambio. Datos: quién escribe cada tabla. Despliegue: si hay que liberar juntos. Runtime: qué debe estar disponible. Equipos: quién tiene que decidir.

🗣️ **2 minutos:** Cada moneda se lee con su fuente: historial de repositorios, consultas y credenciales de la base, calendario de releases, grafo de llamadas por operación y registro de aprobaciones. Juntas describen si un cambio es local o coordinado.

🔬 **El detalle:** Una moneda sola suele tener explicación benigna; el diagnóstico aparece cuando varias apuntan a lo mismo en los mismos cambios.

### 4. 🟢 ¿Por qué se diagnostica siguiendo un cambio real y no revisando la arquitectura dibujada?

⏱️ **30 segundos:** Porque el diagrama muestra la intención y el cambio real muestra el acoplamiento que existe.

🗣️ **2 minutos:** El diagrama tiene cajas separadas y flechas limpias; el cambio de expiración de reservas mostró tres repositorios, un DDL compartido y tres aprobaciones. Solo recorriendo un cambio se ven las dependencias que nadie dibujó: una tabla leída por SQL, una librería común o un despliegue que espera a otro.

🔬 **El detalle:** Conviene elegir varios cambios representativos, no el más doloroso: un caso extremo no describe el patrón.

### 5. 🟢 ¿Qué costes suma un monolito distribuido que no tiene ni un monolito ni un sistema de servicios autónomos?

⏱️ **30 segundos:** La coordinación de cambio y despliegue de un monolito más la latencia, los contratos remotos y los fallos parciales de la distribución.

🗣️ **2 minutos:** Un monolito coordina, pero dentro de un proceso con transacciones locales. Unos servicios autónomos pagan red, pero compran independencia. El monolito distribuido coordina como el primero y paga red como los segundos, sin la transacción local de uno ni la independencia de los otros.

🔬 **El detalle:** Por eso la remediación puede ir en cualquiera de las dos direcciones: recuperar independencia o recuperar la transacción fusionando.

### 6. 🟢 ¿Qué es un release train y por qué es una señal en la moneda de despliegue?

⏱️ **30 segundos:** Un calendario fijo en el que varios componentes se liberan juntos; es señal cuando un componente no puede salir fuera del tren sin romper a otros.

🗣️ **2 minutos:** Si `inventory` solo puede desplegar los martes con `orders` porque sus contratos cambian a la vez, el despliegue independiente es nominal. Un tren elegido por comodidad no es síntoma; uno impuesto por dependencias de contrato o de esquema sí.

🔬 **El detalle:** La pregunta de diagnóstico es: ¿qué pasa si este componente sale solo un jueves? Si la respuesta es «algo se rompe», la señal es real.

### 7. 🟡 ¿Por qué diagnosticar por base compartida solamente es una simplificación peligrosa?

⏱️ **30 segundos:** Porque una base compartida con ownership de escritura claro y permisos por componente puede ser una concesión barata, no un síntoma.

🗣️ **2 minutos:** Compartir el motor abarata joins de lectura y operación. El problema aparece cuando varios componentes escriben las mismas tablas sin dueño, o cuando cualquier DDL necesita a todos. Diagnosticar por la base sola llevaría a separar almacenamiento en sistemas donde el cambio ya es independiente.

🔬 **El detalle:** La pregunta útil no es «¿comparten base?» sino «¿quién puede escribir y cambiar el esquema de cada tabla?».

### 8. 🟡 ¿Cuándo mantendrías la distribución aunque haya coordinación, porque compra aislamiento o escala demostrable?

⏱️ **30 segundos:** Cuando un componente tiene un perfil de escala, un requisito de aislamiento o un ritmo de cambio propio que la separación satisface y que se puede medir.

🗣️ **2 minutos:** Si `payments` necesita aislamiento por cumplimiento normativo, o `notifications` escala diez veces más en campañas, la distribución compra algo real aunque otros cambios sigan coordinados. Entonces la remediación ataca la coordinación sin deshacer la separación que funciona.

🔬 **El detalle:** El beneficio se demuestra con cifras —escalado independiente, auditorías superadas, despliegues propios—, no con la intención original de la división.

### 9. 🟡 ¿Qué parte del cambio de expiración de reservas es evidencia de código, cuál de datos y cuál de despliegue?

⏱️ **30 segundos:** Código: tres repositorios modificados. Datos: el DDL sobre el esquema compartido. Despliegue: el hueco en el release train.

🗣️ **2 minutos:** Las tres evidencias vienen del mismo cambio y se refuerzan: el cambio cruzó componentes porque la regla vivía repartida, el DDL necesitó coordinación porque la tabla no tenía dueño, y el tren fue obligatorio porque los tres cambios tenían que salir juntos. Las tres aprobaciones son la moneda de equipos.

🔬 **El detalle:** Separarlas ayuda a elegir por dónde empezar: si el DDL es la causa del tren, darle dueño a la tabla puede resolver dos monedas a la vez.

### 10. 🟡 ¿Qué proporción de cambios coordinados empezaría a preocuparte y por qué la cifra sola no decide?

⏱️ **30 segundos:** Si la mayoría de los cambios de negocio cruzan componentes, es una señal fuerte; pero la cifra depende de qué cambios se cuentan y de si hubo un proyecto transversal.

🗣️ **2 minutos:** Un 70 % de cambios coordinados durante seis meses de trabajo normal describe un patrón; el mismo 70 % durante una migración de plataforma puede ser coyuntural. Se cuentan cambios de negocio, no refactors ni actualizaciones de librerías, y se mira la tendencia.

🔬 **El detalle:** No hay un umbral universal; lo que importa es si la cifra se mantiene cuando se excluyen los cambios que por naturaleza son transversales.

### 11. 🟡 ¿Cómo distingues un despliegue conjunto deliberado de un release train obligatorio?

⏱️ **30 segundos:** Por lo que pasa si se rompe el tren: si un componente puede salir solo sin romper nada, el conjunto es deliberado; si no puede, es obligatorio.

🗣️ **2 minutos:** Un equipo puede agrupar despliegues por comodidad, comunicación o ventana de cambio, y aun así ser capaz de desplegar solo. El tren obligatorio aparece cuando los contratos o el esquema cambian a la vez y el orden importa. La prueba es un despliegue aislado en un entorno de preproducción.

🔬 **El detalle:** Contar cuántos despliegues fuera del tren hubo en el trimestre es una evidencia barata: si ninguno, conviene preguntar por qué.

### 12. 🟡 ¿Qué dato de runtime mirarías para saber si un componente es obligatorio para checkout?

⏱️ **30 segundos:** El grafo de llamadas de checkout en las trazas y qué pasa con checkout cuando ese componente falla o se retrasa.

🗣️ **2 minutos:** Las trazas muestran si la llamada está en el camino síncrono; el comportamiento ante fallo muestra si checkout degrada o se cae. Si con `notifications` caído checkout falla, es obligatorio aunque su función no lo sea. Un ensayo con el componente detenido lo confirma.

🔬 **El detalle:** Obligatorio en runtime no siempre es un defecto: `inventory` puede serlo por la garantía de stock. Lo que se busca son obligatorios que no aportan una garantía.

### 13. 🟡 ¿Cómo aparece la moneda de equipos en un monolito distribuido?

⏱️ **30 segundos:** Como decisiones rutinarias que requieren a varios equipos: aprobaciones cruzadas, comités de esquema o de contrato, y esperas en calendarios ajenos.

🗣️ **2 minutos:** En el caso, la expiración de reservas necesitó tres aprobaciones porque tres equipos tenían código, datos o contrato afectados. Si cada cambio de un equipo necesita el visto bueno de otros dos, la autonomía de equipo es nominal aunque cada uno tenga su backlog.

🔬 **El detalle:** Suele ser efecto y no causa: los equipos se coordinan porque el código y los datos los obligan. Reorganizar equipos sin mover el acoplamiento no lo arregla.

### 14. 🟡 ¿Qué diferencia hay entre causa, síntoma y consecuencia en este diagnóstico?

⏱️ **30 segundos:** La causa es lo que obliga a coordinar —datos sin dueño, contratos que cambian juntos—; el síntoma es lo observable —release train, tres aprobaciones—; la consecuencia es el coste —cinco semanas para un cambio pequeño—.

🗣️ **2 minutos:** Atacar el síntoma, por ejemplo prohibiendo el release train, no quita la causa: los contratos seguirán rompiéndose al desplegar por separado. Identificar la causa dice qué moneda corregir primero.

🔬 **El detalle:** Confundirlas lleva a remedios de organigrama o de proceso para problemas de datos y de contrato.

### 15. 🟡 ¿Qué beneficio compensatorio buscarías antes de concluir que la distribución no compra nada?

⏱️ **30 segundos:** Escala independiente, aislamiento de fallos o de cumplimiento, y despliegues que sí salen solos para algún componente.

🗣️ **2 minutos:** Reviso si algún componente escala por separado en las campañas, si alguno se aisló por requisito regulatorio, y si alguno despliega fuera del tren con regularidad. Cualquiera de esos beneficios, medido, cambia la conclusión para ese componente.

🔬 **El detalle:** Buscar el beneficio con honestidad evita que el diagnóstico se convierta en un alegato para volver a un monolito que nadie pidió.

### 16. 🟡 ¿Por qué la ausencia de incidentes no descarta el diagnóstico?

⏱️ **30 segundos:** Porque el monolito distribuido cuesta sobre todo en velocidad de cambio y coordinación, no necesariamente en caídas.

🗣️ **2 minutos:** Un sistema puede ser estable porque cambia poco y todo sale junto con mucho cuidado. El coste aparece como semanas por cambio, trenes de despliegue y comités. La disponibilidad compuesta de la cadena es un riesgo latente que se materializa en el primer fallo parcial serio.

🔬 **El detalle:** El historial de cambios es la evidencia principal; los incidentes, cuando los hay, la refuerzan.

### 17. 🟡 ¿Por qué artefactos separados en Java o Go siguen siendo evidencia parcial de autonomía?

⏱️ **30 segundos:** Porque un JAR o un binario separados prueban que el código se construye aparte, no que se pueda cambiar, desplegar y operar aparte.

🗣️ **2 minutos:** Dos binarios Go que comparten un paquete de modelos, o dos JAR que dependen de la misma versión de una librería de dominio, se recompilan y despliegan juntos cuando esa pieza cambia. La separación del artefacto es necesaria; la independencia se demuestra en el historial de cambios y despliegues.

🔬 **El detalle:** Es la diferencia entre topología y autonomía aplicada al build: el build dice cuántas piezas hay, no cuántas decisiones son independientes.

### 18. 🟠 ¿Qué información falta al contar workspaces Node o aplicaciones Python como servicios?

⏱️ **30 segundos:** Quién escribe qué datos, qué se despliega junto, qué llamadas son obligatorias y quién decide cada cambio.

🗣️ **2 minutos:** Un workspace de Node con cinco paquetes o cinco aplicaciones Python en contenedores dan la topología. No dicen si comparten tablas, si el lockfile obliga a actualizar todo a la vez, si una necesita a las otras para responder ni si un equipo puede cambiar la suya solo. Eso sale de la base, el pipeline, las trazas y el historial.

🔬 **El detalle:** Contar piezas es la forma más común de confundir topología con autonomía, y vale igual para cualquier lenguaje.

### 19. 🟠 La dirección pregunta si «tienen microservicios o un monolito distribuido» y quiere la respuesta en una semana. ¿Qué harías?

⏱️ **30 segundos:** Elegir unos pocos cambios de negocio representativos del último semestre, recorrerlos por las cinco monedas y presentar la evidencia con su interpretación y lo que la refutaría.

🗣️ **2 minutos:** En una semana no hay tiempo para auditar todo, pero sí para diez cambios: repositorios tocados, DDL, releases, llamadas obligatorias y aprobaciones. La respuesta dice qué monedas muestran acoplamiento recurrente, qué beneficio existe y qué supuestos faltan. No incluye todavía una propuesta de topología.

🔬 **El detalle:** Presentar la respuesta como evidencia y no como etiqueta evita que la discusión derive en si «monolito distribuido» es un insulto.

### 20. 🟠 Un arquitecto propone dividir los cinco componentes en doce para «desacoplar». ¿Qué evidencia pedirías antes?

⏱️ **30 segundos:** Que muestre qué cambios recientes habrían quedado dentro de un solo componente con el nuevo corte, y qué datos y releases dejarían de compartirse.

🗣️ **2 minutos:** Si la expiración de reservas cruzaba tres componentes porque la regla y la tabla estaban repartidas, dividir más no la concentra: la reparte más. Pido el mapeo de cambios reales al corte propuesto y el plan de datos. Sin eso, la división multiplica la red y la coordinación.

🔬 **El detalle:** La hipótesis contraria —fusionar dos componentes que siempre cambian juntos— se evalúa con el mismo método y a menudo sale mejor.

### 21. 🟠 Solo `payments` se despliega por su cuenta y cumple su SLO; el resto va en el release train. ¿Qué diagnóstico darías?

⏱️ **30 segundos:** Un diagnóstico parcial: `payments` tiene autonomía efectiva y los otros cuatro se comportan como un monolito distribuido entre sí.

🗣️ **2 minutos:** El diagnóstico no es de todo o nada. `payments` demuestra que la separación puede funcionar en este sistema, y su frontera es un modelo para las demás. La remediación se centra en `orders`, `inventory`, `notifications` y la pasarela, y puede incluir fusionar alguno de ellos.

🔬 **El detalle:** Preguntar qué tiene `payments` que los demás no —datos propios, contrato estable, un solo equipo— suele dar la lista de lo que falta.

### 22. 🟠 Tras el diagnóstico decides actuar. ¿Qué primera acción reversible elegirías y cómo medirías su efecto?

⏱️ **30 segundos:** Dar dueño a la tabla o al contrato que más cambios coordinados provoca, y medir si los siguientes cambios de esa área salen sin coordinación.

🗣️ **2 minutos:** Si el DDL compartido de reservas aparece en la mayoría de los cambios cruzados, asigno propietario, restrinjo escrituras ajenas y publico un comando. Es reversible: los permisos se pueden devolver. Mido cuántos cambios de esa área salen en un solo componente y fuera del tren durante los dos meses siguientes.

🔬 **El detalle:** Una sola acción con medición enseña más que un plan de remediación completo aprobado antes de probar nada.

### 23. 🟠 Dos arquitectos discrepan: uno ve un monolito distribuido y otro «microservicios inmaduros». ¿Cómo resolverías la discusión?

⏱️ **30 segundos:** Llevándola de la etiqueta a la evidencia: qué monedas muestran acoplamiento, qué beneficio existe y qué acción propone cada uno.

🗣️ **2 minutos:** Las dos etiquetas pueden describir lo mismo; lo que importa es la remediación. Si «inmaduros» significa «falta darles datos y contratos propios», coincide con una parte del otro diagnóstico. Si significa «dividamos más», la evidencia de cambios dirá si eso los concentra o los reparte.

🔬 **El detalle:** Acordar primero las observaciones y después la interpretación evita discutir nombres mientras el coste sigue corriendo.

### 24. 🟠 ¿Qué evidencia te haría retirar el diagnóstico de monolito distribuido?

⏱️ **30 segundos:** Que la mayoría de los cambios salgan en un solo componente, sin release train obligatorio, con datos de escritura propios y sin aprobaciones cruzadas rutinarias.

🗣️ **2 minutos:** Si al medir resulta que el 70 % era un proyecto transversal y el trabajo normal es local, el diagnóstico no se sostiene. También si la coordinación existe pero la separación compra escala o aislamiento medidos que la compensan. Retirarlo con evidencia es parte del método.

🔬 **El detalle:** Un diagnóstico que no puede refutarse no es un diagnóstico: por eso se escribe junto a lo que lo desmentiría.

## 📖 02 — Cadenas síncronas y acoplamiento temporal

### 1. 🟢 ¿Qué es el acoplamiento temporal?

⏱️ **30 segundos:** La dependencia de que otro componente esté disponible y responda a tiempo en el mismo momento en que tú atiendes una petición.

🗣️ **2 minutos:** Si `orders` necesita la respuesta de `payments` para contestar, la disponibilidad y la latencia de `payments` pasan a ser las de `orders`. Es independiente del acoplamiento de código: dos componentes con contratos impecables siguen acoplados en el tiempo si uno espera al otro.

🔬 **El detalle:** Se reduce quitando la espera —respuesta diferida, datos locales—, no cambiando el protocolo por el que se espera.

### 2. 🟢 ¿Cómo se compone la disponibilidad de una cadena de dependencias obligatorias?

⏱️ **30 segundos:** Como el producto de las disponibilidades de cada componente obligatorio, bajo el supuesto de fallos independientes.

🗣️ **2 minutos:** Cinco componentes al 99,9 % dan como mucho alrededor de 99,5 %: cada componente añade su probabilidad de fallar. Por eso una cadena larga no puede prometer la disponibilidad de su eslabón más fiable. Solo los componentes obligatorios cuentan; uno degradable no resta.

🔬 **El detalle:** El producto es una estimación; con fallos correlacionados —misma base, misma red— deja de ser válido y hay que medir el flujo completo.

### 3. 🟢 ¿Qué es un presupuesto de tiempo que nace en el borde?

⏱️ **30 segundos:** El tiempo total que el cliente está dispuesto a esperar, fijado al entrar y repartido entre los saltos, de modo que cada uno sabe cuánto le queda.

🗣️ **2 minutos:** Si checkout tiene 900 ms, `orders` recibe lo que queda tras la pasarela y reparte entre `inventory` y `payments` con margen para responder. Cuando el presupuesto se agota, la llamada se cancela y el flujo decide qué responder, en lugar de esperar un timeout fijo de cinco segundos en cada salto.

🔬 **El detalle:** Propagarlo exige que el deadline viaje con la petición —cabecera, `context`, señal de cancelación— y que cada cliente lo respete.

### 4. 🟢 ¿Qué es una API *chatty* y por qué alarga la cadena?

⏱️ **30 segundos:** Una API que obliga a muchas llamadas pequeñas para obtener lo que el consumidor necesita, en lugar de una sola que lo devuelva.

🗣️ **2 minutos:** Si mostrar un carrito exige una llamada a `inventory` por producto, la latencia es la suma de decenas de saltos y la probabilidad de fallo crece con cada uno. Una consulta por lote o una proyección local convierten muchas esperas en una o en ninguna.

🔬 **El detalle:** Las APIs *chatty* suelen nacer al extraer un módulo copiando su interfaz interna, pensada para llamadas en memoria que no cuestan nada.

### 5. 🟢 ¿Qué es una tormenta de reintentos?

⏱️ **30 segundos:** Una amplificación de carga en la que cada capa reintenta ante una dependencia lenta, y la suma de reintentos la satura más.

🗣️ **2 minutos:** Cuando `payments` se degrada, cada llamada que expira se repite; si la pasarela, `orders` y el cliente HTTP reintentan, cada petición original produce varias llamadas. La dependencia recibe más carga justo cuando menos puede, y su recuperación se retrasa.

🔬 **El detalle:** Backoff con jitter reparte los reintentos en el tiempo, pero no reduce su número; eso lo hace reintentar en una sola capa.

### 6. 🟢 ¿Qué criterio decide si una llamada debe ser síncrona?

⏱️ **30 segundos:** Si el cliente necesita su resultado para que la respuesta que recibe sea verdadera.

🗣️ **2 minutos:** La reserva de stock cambia la respuesta —confirmado o sin stock—, así que tiene sentido esperarla. El correo de confirmación no cambia nada de lo que se responde, así que esperarlo solo añade acoplamiento. El pago está en medio: depende de si el negocio acepta «pedido recibido, pago en curso».

🔬 **El detalle:** Es una decisión de negocio expresada en la respuesta, no una preferencia técnica por HTTP o mensajes.

### 7. 🟡 ¿Por qué sustituir toda llamada por mensajes es una simplificación peligrosa?

⏱️ **30 segundos:** Porque si el flujo sigue necesitando la respuesta antes de contestar al cliente, el acoplamiento temporal se mantiene y se añaden cola, correlación y timeouts nuevos.

🗣️ **2 minutos:** Enviar un comando por cola y esperar la respuesta en otra cola es una llamada síncrona con más piezas. El desacoplamiento real llega cuando el negocio acepta una respuesta diferida y el flujo tiene un estado intermedio visible. Sin ese cambio de promesa, el broker solo esconde la espera.

🔬 **El detalle:** Los mensajes sí son la herramienta correcta para lo que puede llegar después; el error es usarlos para lo que no puede.

### 8. 🟡 ¿Cuándo elegirías fusionar dos componentes o duplicar datos de lectura antes que mejorar la resiliencia de la llamada?

⏱️ **30 segundos:** Cuando los dos componentes siempre se llaman para completar una operación y la separación no compra escala ni autonomía, o cuando la llamada solo sirve para leer datos que cambian poco.

🗣️ **2 minutos:** Si `orders` y `inventory` no pueden atender checkout el uno sin el otro, un proceso único recupera la transacción local y elimina un salto. Si `orders` solo consulta nombres de producto, una proyección local con frescura declarada quita la dependencia. Añadir circuit breakers a una llamada innecesaria es resolver el problema equivocado.

🔬 **El detalle:** Ambas opciones cuestan: fusionar comparte despliegue y fallo; duplicar paga frescura y reconciliación.

### 9. 🟡 ¿Qué supuestos esconde la estimación 0,999⁵ ≈ 99,5 % para checkout?

⏱️ **30 segundos:** Que los fallos son independientes, que solo esos cinco componentes son obligatorios y que no hay amplificación por reintentos ni timeouts.

🗣️ **2 minutos:** La base compartida, la red, el balanceador y el DNS también son dependencias obligatorias que el producto ignora. Los fallos correlacionados —un despliegue que afecta a varios, una base saturada— hacen que el producto deje de describir la realidad. La cifra útil es la disponibilidad medida del flujo completo.

🔬 **El detalle:** La estimación sirve para razonar el orden de magnitud y para ver que alargar la cadena siempre resta; no sustituye la medición.

### 10. 🟡 ¿Por qué no se suman los p95 de cada salto para obtener el p95 del flujo?

⏱️ **30 segundos:** Porque los percentiles no son aditivos: los picos de cada salto no coinciden en las mismas peticiones.

🗣️ **2 minutos:** La suma de p95 suele sobreestimar el p95 del flujo cuando los saltos son independientes, y puede subestimarlo si los picos están correlacionados, por ejemplo por una base compartida. La única forma fiable es medir el flujo completo en el borde y usar las trazas para atribuir el tiempo.

🔬 **El detalle:** Para agregar percentiles entre réplicas o saltos hacen falta histogramas, no percentiles ya calculados.

### 11. 🟡 ¿Cuántas llamadas puede recibir `payments` por una sola petición si tres capas hacen hasta cuatro intentos cada una?

⏱️ **30 segundos:** Hasta 4 × 4 × 4 = 64 llamadas por cada petición original del cliente.

🗣️ **2 minutos:** La pasarela intenta hasta cuatro veces llamar a `orders`; cada intento de `orders` intenta hasta cuatro veces llamar a su cliente; y el cliente HTTP intenta hasta cuatro veces llamar a `payments`. En el peor caso, una dependencia lenta recibe 64 veces la carga que el tráfico justifica.

🔬 **El detalle:** La corrección no es bajar a dos intentos por capa, que siguen siendo ocho; es decidir una sola capa que reintente.

### 12. 🟡 ¿Por qué `notifications` no debería estar en el camino síncrono de checkout?

⏱️ **30 segundos:** Porque su resultado no cambia la respuesta al cliente, y estar en la cadena solo añade una dependencia obligatoria más.

🗣️ **2 minutos:** El cliente necesita saber si su pedido está confirmado, no si el correo salió. Con `notifications` en línea, una caída del proveedor de email tumba checkout. Registrado como trabajo durable tras el commit, el aviso llega después y su fallo se reintenta sin afectar a la compra.

🔬 **El detalle:** Es el cambio con mejor relación entre coste y beneficio de este caso: quita un salto sin cambiar ninguna promesa.

### 13. 🟡 ¿Qué garantía justifica que `inventory` sí esté en el camino síncrono?

⏱️ **30 segundos:** Que el pedido no se confirme sin stock: la respuesta al cliente depende de ese resultado.

🗣️ **2 minutos:** Si el negocio promete confirmación inmediata con stock garantizado, `orders` necesita la respuesta de `inventory` antes de contestar. El acoplamiento temporal es el precio de esa promesa. Se puede reducir con una proyección de disponibilidad para mostrar, pero la decisión de reservar sigue necesitando al dueño.

🔬 **El detalle:** Si la promesa cambia a «pedido recibido, stock confirmado en segundos», `inventory` también puede salir del camino síncrono.

### 14. 🟡 ¿Cómo degrada un componente lento a funciones que no dependen de él?

⏱️ **30 segundos:** Agotando recursos compartidos del llamador: hilos, conexiones o memoria que otras funciones también necesitan.

🗣️ **2 minutos:** Mientras los hilos de `orders` esperan a `payments`, no quedan hilos para el historial de pedidos, que no llama a `payments`. La lentitud se propaga por los recursos, no por la lógica. Un pool o un cupo propio para las llamadas a `payments` contiene el daño.

🔬 **El detalle:** Es el mismo mecanismo de bulkhead que dentro de un monolito, aplicado a las llamadas remotas.

### 15. 🟡 ¿Qué aporta un circuit breaker y qué no?

⏱️ **30 segundos:** Aporta dejar de llamar a una dependencia que está fallando para no gastar tiempo ni cargarla más; no aporta la respuesta que esa dependencia debía dar.

🗣️ **2 minutos:** Con el circuito abierto, `orders` falla rápido en lugar de esperar el timeout, y `payments` tiene margen para recuperarse. Pero checkout sigue sin poder confirmar el pago: hace falta una conducta alternativa, como dejar el pedido pendiente. El breaker convierte una espera en una decisión; la decisión hay que diseñarla.

🔬 **El detalle:** La reapertura prueba con poco tráfico; si prueba con todo, reproduce la tormenta que quería evitar.

### 16. 🟡 ¿Qué pasa con el trabajo aguas abajo cuando el cliente abandona y nadie propaga la cancelación?

⏱️ **30 segundos:** Sigue ejecutándose y consumiendo recursos para una respuesta que nadie va a leer.

🗣️ **2 minutos:** Si el usuario cierra la página a los dos segundos y `orders` sigue esperando a `payments` otros tres, esos recursos se gastan en vano, y bajo carga ese desperdicio empeora la saturación. Propagar la cancelación libera la cadena, siempre que cada dependencia la respete.

🔬 **El detalle:** Cancelar una llamada que ya tenía un efecto remoto no deshace el efecto; por eso la cancelación se combina con idempotencia y estados.

### 17. 🟡 ¿Cómo deben representar el mismo deadline un cliente Java y un `context.Context` de Go?

⏱️ **30 segundos:** Como un instante absoluto de expiración que ambos derivan de la petición entrante, no como un timeout fijo propio de cada cliente.

🗣️ **2 minutos:** En Go, el `context` de la petición lleva el deadline y cada llamada lo hereda; basta con no crear un `context.Background()` nuevo. En Java hay que leer el tiempo restante del contexto de la petición y aplicarlo al cliente HTTP o gRPC en cada llamada. Entre procesos, el deadline viaja en una cabecera, como hace gRPC.

🔬 **El detalle:** El error común en ambos es el mismo: un timeout configurado por cliente que ignora cuánto tiempo le queda a la petición.

### 18. 🟠 ¿Qué problema comparten reintentos ocultos en clientes Node/TypeScript y Python?

⏱️ **30 segundos:** Que multiplican las llamadas sin que la capa de arriba lo sepa, y rompen el presupuesto y la cuenta de intentos.

🗣️ **2 minutos:** Un cliente HTTP con reintentos por defecto, o un SDK que reintenta internamente, se suma a los reintentos explícitos de la aplicación. Nadie ve el total hasta que una dependencia lenta recibe el múltiplo. La corrección es inventariar dónde se reintenta y desactivar lo que no sea la capa elegida.

🔬 **El detalle:** Los reintentos ocultos también rompen la idempotencia: la aplicación cree que hizo una llamada y el proveedor recibió tres.

### 19. 🟠 `payments` pasa de 300 ms a 4 s en el p99 y checkout cae por completo. ¿Qué harías en la primera hora?

⏱️ **30 segundos:** Contener: bajar los reintentos a una capa, acortar el timeout de `payments` al presupuesto real y, si el negocio lo acepta, dejar pedidos pendientes de pago en lugar de fallar.

🗣️ **2 minutos:** Lo primero es dejar de amplificar la carga sobre `payments`. Después, proteger al resto de `orders` con un cupo para esas llamadas, para que el historial de pedidos se recupere. Si hay un flag para confirmar con pago pendiente, se activa con la aprobación de negocio. La causa en el proveedor se atiende en paralelo.

🔬 **El detalle:** Todo lo que se active en la primera hora debería existir antes como opción probada; improvisarlo durante el incidente es el riesgo mayor.

### 20. 🟠 Negocio exige confirmación de pago en la misma respuesta de checkout. ¿Cómo lo mantienes síncrono sin que un proveedor lento tumbe todo?

⏱️ **30 segundos:** Con un presupuesto estricto para `payments`, un cupo de recursos propio, un breaker y un estado honesto cuando el tiempo se agota.

🗣️ **2 minutos:** La llamada sigue síncrona, pero con un deadline derivado del presupuesto del cliente y sin reintentos en cadena. Si expira, la respuesta dice «no pudimos confirmar el pago» y el pedido queda en un estado recuperable, con consulta posterior por clave idempotente. El cupo evita que la espera afecte a otros flujos.

🔬 **El detalle:** Vale la pena mostrar a negocio cuántas compras se pierden por timeouts: a veces el dato cambia la exigencia por «pago en curso».

### 21. 🟠 Una página de producto llama a `inventory` 40 veces para mostrar disponibilidad. ¿Qué propondrías?

⏱️ **30 segundos:** Una consulta por lote o una proyección local de disponibilidad, según la frescura que la página necesite.

🗣️ **2 minutos:** La página no decide reservas: muestra una estimación. Una llamada por lote reduce cuarenta esperas a una; una proyección en el componente que sirve la página las reduce a cero, a cambio de unos segundos de retraso. La reserva real sigue yendo a `inventory` en checkout.

🔬 **El detalle:** Documentar la frescura de la proyección evita que alguien la use después para decidir la reserva.

### 22. 🟠 Quieres sacar `notifications` del camino síncrono. ¿Qué pasos reversibles darías?

⏱️ **30 segundos:** Registrar el aviso como trabajo durable además de la llamada actual, con la misma clave, y apagar la llamada síncrona con un flag cuando el trabajo durable demuestre que no pierde avisos.

🗣️ **2 minutos:** Paso uno: la transacción de `orders` escribe el trabajo del aviso y la llamada síncrona sigue. Paso dos: un worker envía desde el trabajo y `notifications` deduplica por clave. Paso tres: el flag quita la llamada síncrona. Si algo falla, el flag la devuelve.

🔬 **El detalle:** Medir checkout antes y después con el proveedor de email degradado a propósito demuestra el beneficio con evidencia.

### 23. 🟠 Un equipo quiere un service mesh con reintentos automáticos y otro quiere recortar la cadena. ¿Cómo decidirías?

⏱️ **30 segundos:** Recortar primero lo que no aporta garantía; el mesh puede ayudar con timeouts y observabilidad, pero sus reintentos se suman a los que ya existen.

🗣️ **2 minutos:** Un mesh no quita saltos: hace más uniforme su gestión. Si `notifications` sigue en la cadena, el mesh solo gestiona mejor una dependencia innecesaria. Recorto la cadena, fijo una sola capa de reintento —que podría ser el mesh— y desactivo los reintentos del resto.

🔬 **El detalle:** El mesh añade también un componente más en el camino de cada llamada; su valor se mide con la misma disponibilidad del flujo completo.

### 24. 🟠 ¿Qué criterio te diría que la cadena ya es proporcional y no hay que recortarla más?

⏱️ **30 segundos:** Que cada salto síncrono aporte una garantía que la respuesta necesita, que el flujo cumpla su SLO medido y que cada fallo de dependencia tenga una conducta definida.

🗣️ **2 minutos:** Si solo quedan `inventory` y, por decisión de negocio, `payments`, con presupuesto propagado, reintentos en una capa y estados para el fallo, recortar más cambiaría la promesa al cliente. Reviso la cadena si cambia esa promesa o si el SLO vuelve a incumplirse.

🔬 **El detalle:** Una cadena corta y justificada no es un monolito distribuido; es acoplamiento temporal elegido y pagado a sabiendas.

## 📖 03 — Base compartida, escrituras cruzadas y propiedad difusa

### 1. 🟢 ¿Qué tres cosas definen al dueño de un conjunto de datos?

⏱️ **30 segundos:** Ser el único que lo escribe, decidir su esquema y responder por sus invariantes.

🗣️ **2 minutos:** En el caso, `payments` debería ser el único que escribe `payments.authorizations`, el que decide renombrar un estado y el que responde si una autorización queda sin anular. Hoy comparte las tres cosas con `orders`, y por eso nadie responde del todo.

🔬 **El detalle:** El dueño puede publicar lecturas para otros; lo que no delega es la escritura ni la decisión sobre el significado.

### 2. 🟢 ¿Qué es una escritura cruzada y por qué es peor que una lectura cruzada?

⏱️ **30 segundos:** Es un componente que escribe directamente en las tablas de otro. Es peor porque salta las reglas del dueño y cambia estado que el dueño cree controlar.

🗣️ **2 minutos:** Una lectura cruzada acopla al esquema: si el dueño lo cambia, el lector se rompe, pero el dato sigue siendo correcto. Una escritura cruzada puede dejar el dato en un estado que el dueño no valida ni entiende, como el `VOIDED` que nadie reconocía tras la migración.

🔬 **El detalle:** Por eso la primera acción de recuperación es cortar escrituras cruzadas; las lecturas pueden esperar a tener su contrato.

### 3. 🟢 ¿Qué es una matriz de lectores y escritores y de dónde sale?

⏱️ **30 segundos:** Una tabla que dice, para cada conjunto de datos, qué componentes lo leen y cuáles lo escriben. Sale de credenciales, logs de consultas y trazas, no solo de entrevistas.

🗣️ **2 minutos:** Las entrevistas dan lo que cada equipo cree; los logs de la base dan lo que ocurre, incluidos el job olvidado y el reporte de finanzas. Con seis credenciales escribiendo las mismas tablas, la matriz real suele sorprender. Es el punto de partida para asignar dueños.

🔬 **El detalle:** Conviene capturar una ventana que incluya cierres de mes y procesos por lotes; los accesos esporádicos son los que más se olvidan.

### 4. 🟢 ¿Qué es una proyección de lectura y qué contrato declara?

⏱️ **30 segundos:** Una copia de los datos de otro dueño, mantenida por el consumidor para sus consultas. Declara versión, frescura máxima y cómo se reconcilia.

🗣️ **2 minutos:** Si `orders` necesita el estado de pago para mostrar sus pedidos, puede mantener una proyección alimentada por eventos de `payments`. No manda sobre el dato: lo refleja con un retraso declarado. Si diverge, se reconstruye desde el dueño.

🔬 **El detalle:** Una proyección nunca se usa para decidir sobre el dato del dueño; para eso se le pregunta al dueño.

### 5. 🟢 ¿Qué es un dual write y qué riesgo introduce?

⏱️ **30 segundos:** Escribir el mismo dato en dos sitios desde la aplicación, sin una transacción que los una. El riesgo es que uno de los dos falle y queden divergentes.

🗣️ **2 minutos:** Si `orders` escribe el pedido en su base y en la de `payments` en dos operaciones, una caída entre ambas deja una sin la otra. Sin fuente de verdad declarada, nadie sabe cuál corregir. Por eso un dual write temporal necesita fuente de verdad, detección de divergencia y fecha de salida.

🔬 **El detalle:** El outbox evita el dual write al convertir la segunda escritura en un trabajo durable que nace en la misma transacción que la primera.

### 6. 🟢 ¿Qué aporta CDC y qué no garantiza?

⏱️ **30 segundos:** Aporta una publicación fiable de los cambios de filas sin tocar el código del dueño; no garantiza que esos cambios signifiquen algo claro para el consumidor.

🗣️ **2 minutos:** Con CDC, cada cambio en `payments.authorizations` puede alimentar una proyección en `orders`. Pero publica filas, no hechos de negocio: si un estado es ambiguo o cambia de nombre, el consumidor recibe la ambigüedad. Además acopla al consumidor al esquema interno del dueño.

🔬 **El detalle:** CDC suele ser un buen puente durante una migración; como contrato permanente, conviene que el dueño publique eventos con significado.

### 7. 🟡 ¿Por qué mover tablas a otra base sin acordar propietario es una simplificación peligrosa?

⏱️ **30 segundos:** Porque la dependencia sigue existiendo y se convierte en llamadas, réplicas o dual writes entre bases, con menos garantías que antes.

🗣️ **2 minutos:** Hoy `orders` anula autorizaciones con un `UPDATE` en la misma base; con dos bases y sin dueño acordado, tendrá que escribir en la otra por red o por sincronización. Se pierde la transacción local y se mantiene el acoplamiento. Con dueño y comando primero, la separación física se vuelve un detalle.

🔬 **El detalle:** La base compartida era el síntoma visible; la causa, la autoridad difusa, viaja intacta a la nueva topología.

### 8. 🟡 ¿Cuándo mantendrías un join de lectura gobernado en lugar de una API o una proyección?

⏱️ **30 segundos:** Cuando es de solo lectura, sobre una vista publicada por el dueño, y su coste es menor que el de mantener una API o una copia.

🗣️ **2 minutos:** Un reporte que cruza pedidos y pagos una vez al día puede leer vistas que ambos dueños publican y versionan. No transfiere autoridad ni obliga a llamadas síncronas. Convertirlo en APIs multiplicaría llamadas; en proyección, añadiría otra copia que mantener.

🔬 **El detalle:** La condición es «gobernado»: vista con dueño y versión, no acceso libre a las tablas internas.

### 9. 🟡 ¿Por qué el renombrado de un estado por `payments` produjo 212 autorizaciones sin anular?

⏱️ **30 segundos:** Porque `orders` seguía escribiendo el valor viejo directamente en la tabla, y el código de `payments` ya no lo reconocía.

🗣️ **2 minutos:** `payments` cambió el significado de su dato creyendo que era suyo; `orders` era un escritor no declarado que nadie avisó ni probó. El job de conciliación de `payments` solo procesaba `CANCELLED`, así que las filas con `VOIDED` quedaron fuera. Es un contrato roto que nadie sabía que existía.

🔬 **El detalle:** Con un comando `VoidPayment` en lugar del `UPDATE`, el renombrado habría sido un cambio interno de `payments` sin consumidores rotos.

### 10. 🟡 ¿Por qué el esquema compartido es un contrato implícito, y qué le falta respecto a uno explícito?

⏱️ **30 segundos:** Porque otros componentes dependen de su forma y sus valores sin que nadie lo haya acordado; le faltan dueño, versión, lista de consumidores y política de compatibilidad.

🗣️ **2 minutos:** Un contrato explícito —una API o un evento versionado— dice quién lo publica, quién lo consume y cómo evoluciona. El esquema compartido tiene consumidores que nadie inventarió y cambia cuando al dueño aparente le conviene. Así, un renombrado inocente es una ruptura.

🔬 **El detalle:** Tratar el esquema como contrato, con expand-contract y consumidores conocidos, es un paso intermedio útil antes de sustituirlo.

### 11. 🟡 ¿En qué orden migrarías las escrituras ajenas y cuándo revocarías permisos?

⏱️ **30 segundos:** Primero el comando del dueño, después cada escritor ajeno pasa a usarlo, y al final se revoca el permiso, cuando el log confirma que nadie escribe ya.

🗣️ **2 minutos:** Revocar primero rompe producción; publicar el comando sin migrar a los escritores no cambia nada. El orden es: `payments` expone `VoidPayment`, `orders` deja el `UPDATE` y lo llama, se observa una ventana sin escrituras de otras credenciales y se retira el grant. Cada paso es reversible salvo el último, que se da con evidencia.

🔬 **El detalle:** Revocar en un entorno de preproducción antes que en producción encuentra al escritor olvidado sin incidente.

### 12. 🟡 ¿Qué lecturas de `orders` sobre `payments` resolverías con API, cuáles con proyección y cuáles con vista?

⏱️ **30 segundos:** API para lo que necesita el valor actual antes de decidir; proyección para lo que se muestra a menudo y tolera retraso; vista para reportes y consultas esporádicas.

🗣️ **2 minutos:** Antes de reembolsar, `orders` pregunta a `payments` el estado actual por API. Para listar pedidos con su estado de pago, una proyección evita una llamada por fila. Para el cierre contable, una vista publicada por `payments` basta. Cada lectura elige según frescura, volumen y disponibilidad.

🔬 **El detalle:** Mezclar las tres es normal; lo que no vale es una sola opción por dogma para todas.

### 13. 🟡 ¿Qué diferencia hay entre la propiedad de datos dentro de un monolito modular y entre servicios que comparten base?

⏱️ **30 segundos:** El concepto es el mismo; lo que cambia es que entre servicios no hay transacción común ni release conjunto que amortigüen un error.

🗣️ **2 minutos:** Dentro del monolito, un cambio de esquema y todos sus lectores salen en el mismo despliegue y se prueban juntos. Entre servicios, el dueño cambia su esquema y los lectores ajenos se rompen en producción días después. Por eso la disciplina de ownership pesa más entre procesos.

🔬 **El detalle:** Es una razón por la que la propiedad de datos se practica mejor antes de distribuir: dentro del monolito sus errores son baratos.

### 14. 🟡 ¿Qué señales te dirían que separar el almacenamiento ya compra autonomía?

⏱️ **30 segundos:** Que el dueño necesite cambiar motor, escala, backups o ventana de mantenimiento de forma independiente, y que ya no queden escrituras ajenas ni joins sin gobierno.

🗣️ **2 minutos:** Si `payments` necesita aislamiento por cumplimiento o un perfil de escala distinto, una base propia lo compra. Si la separación solo cambia dónde están las tablas, sin ninguna de esas necesidades, es coste sin retorno. La separación va al final porque para entonces ya se sabe qué depende de qué.

🔬 **El detalle:** Una base compartida con esquemas y roles por dueño da buena parte del aislamiento lógico sin el coste operativo de otra base.

### 15. 🟡 ¿Qué pasa con las claves foráneas entre tablas de dueños distintos?

⏱️ **30 segundos:** Garantizan integridad referencial, pero acoplan migraciones, orden de borrado y despliegues de los dos dueños.

🗣️ **2 minutos:** Una clave foránea de `payments.authorizations` a `orders.orders` impide autorizaciones huérfanas, y también obliga a `orders` a coordinar con `payments` cualquier cambio de su clave o su borrado. Se mantiene si la garantía compensa; se reemplaza por validación y reconciliación si impide evolucionar a uno de los dos.

🔬 **El detalle:** Retirarla es una decisión con precio —datos huérfanos posibles—, no una limpieza estética.

### 16. 🟡 ¿Cómo detectarías divergencia durante un dual write temporal?

⏱️ **30 segundos:** Comparando periódicamente ambos destinos contra la fuente de verdad declarada, con conteos, sumas de control por lote y muestreo de filas.

🗣️ **2 minutos:** Un job compara, por ejemplo, las autorizaciones de las últimas 24 horas en ambos lados y registra diferencias con su causa probable. Si la divergencia supera un umbral, se detiene el avance de la migración. Sin esa comparación, el dual write falla en silencio.

🔬 **El detalle:** La fuente de verdad se declara antes de empezar: en una divergencia, se corrige la copia, nunca se discute cuál vale.

### 17. 🟡 ¿Cómo complementan los permisos SQL a repositorios Java o interfaces Go sin sustituir ownership?

⏱️ **30 segundos:** Los repositorios o interfaces organizan qué código accede a qué tablas; los permisos hacen que la base rechace a quien no debería escribir. Ninguno decide quién es el dueño.

🗣️ **2 minutos:** Un repositorio de `payments` en Java o una interfaz en Go encapsulan el acceso, pero otro componente puede abrir su propia conexión y escribir. Un rol de base por componente, sin grant de escritura sobre tablas ajenas, cierra esa vía. La decisión de a quién dar el grant es el ownership.

🔬 **El detalle:** Los permisos también son evidencia: un error de permiso en preproducción revela al escritor no declarado.

### 18. 🟠 ¿Por qué clientes globales en Node/TypeScript y modelos ORM compartidos en Python debilitan el mismo límite?

⏱️ **30 segundos:** Porque ambos dan a cualquier módulo o componente acceso de escritura a todas las tablas, saltándose al dueño.

🗣️ **2 minutos:** Un cliente de base global exportado en Node deja que cualquier código ejecute SQL sobre cualquier esquema; un modelo ORM común en Python hace que todos los componentes puedan instanciar y guardar entidades ajenas. Los dos convierten el ownership en una convención que nadie hace cumplir.

🔬 **El detalle:** La corrección es la misma en ambos: un cliente o un modelo por dueño, con credenciales propias, y permisos de base que lo respalden.

### 19. 🟠 Descubres las 212 autorizaciones sin anular un viernes por la tarde. ¿Qué haces primero y qué después?

⏱️ **30 segundos:** Primero, anular esas autorizaciones de forma controlada o avisar para reembolso, y parar la fuente: que `orders` deje de escribir el valor viejo. Después, la corrección estructural.

🗣️ **2 minutos:** Lo urgente son los clientes cobrados: con `payments` como dueño, se listan las filas con `VOIDED`, se ejecuta la anulación por su proceso normal y se verifica con el proveedor. Para cortar el flujo, un parche en `orders` que use el valor nuevo, o mejor, que llame a `payments`. El lunes empieza la matriz de escritores.

🔬 **El detalle:** Las anulaciones se hacen con clave idempotente: un reintento del proceso de corrección no debe anular ni reembolsar dos veces.

### 20. 🟠 Un equipo propone copiar las tablas a dos bases el próximo sprint. ¿Qué preguntas harías antes de aceptar?

⏱️ **30 segundos:** Quién es el dueño de cada tabla, quién escribe hoy cada una, qué pasa con las escrituras cruzadas después de separar y qué compra la separación.

🗣️ **2 minutos:** Si la respuesta a «qué pasa con el `UPDATE` de `orders` sobre `payments`» es «lo haremos por la otra base», el acoplamiento se mantiene con peores garantías. Pido la matriz de escritores y un plan de comandos antes de mover nada. Si todo está resuelto, la copia es un paso técnico; si no, es mover el problema.

🔬 **El detalle:** Preguntar qué compra la separación suele revelar que el objetivo real era dejar de coordinar DDL, algo que el ownership resuelve sin mover tablas.

### 21. 🟠 `orders` y `payments` discrepan sobre quién es dueño del estado de pago del pedido. ¿Cómo lo resolverías?

⏱️ **30 segundos:** Separando los dos datos que se confunden: el resultado del pago es de `payments`; el estado comercial del pedido, que lo usa, es de `orders`.

🗣️ **2 minutos:** `payments` decide si una autorización existe y en qué estado está. `orders` decide si el pedido está confirmado, y para eso consume el resultado de `payments`. Con esa separación, ninguno escribe la tabla del otro: `payments` publica `PaymentAuthorized` y `orders` actualiza su propio estado.

🔬 **El detalle:** Muchas disputas de ownership son dos datos con el mismo nombre; nombrarlos distinto suele terminar la discusión.

### 22. 🟠 Quieres revocar a `orders` la escritura en `payments.authorizations`. ¿Qué pasos reversibles darías?

⏱️ **30 segundos:** Publicar el comando de `payments`, migrar el código de `orders` a usarlo detrás de un flag, observar que el rol de `orders` deja de escribir, y revocar el grant al final.

🗣️ **2 minutos:** Paso uno: `VoidPayment` en `payments`, probado. Paso dos: `orders` lo llama con el flag encendido para una cohorte, y el `UPDATE` sigue disponible como vuelta atrás. Paso tres: todo el tráfico por el comando y una ventana sin escrituras del rol de `orders`, según el log de la base. Paso cuatro: `REVOKE`.

🔬 **El detalle:** Si tras revocar aparece un error de permisos, el grant se devuelve en un minuto; por eso la revocación, aunque sea el último paso, sigue siendo reversible.

### 23. 🟠 Un reporte financiero hace joins entre tablas de cuatro componentes. ¿Lo conviertes en APIs, en proyección o lo dejas?

⏱️ **30 segundos:** Lo dejo como lectura, pero sobre vistas publicadas por cada dueño o sobre una réplica analítica, no sobre sus tablas internas.

🗣️ **2 minutos:** Cuatro APIs para un reporte diario multiplican llamadas y reimplementan joins en código. Una proyección más añade otra copia que mantener. Vistas versionadas por dueño, o una réplica analítica alimentada por los dueños, conservan el join barato sin que el reporte dependa del esquema interno.

🔬 **El detalle:** El reporte es un consumidor legítimo; el error era que leyera tablas internas sin que ningún dueño lo supiera.

### 24. 🟠 ¿Qué criterio te diría que la base compartida puede ser el estado final?

⏱️ **30 segundos:** Que cada tabla tenga un único escritor, cada esquema un dueño que decide sin reuniones, las lecturas ajenas vayan por vistas o APIs, y ninguna necesidad de escala, motor o aislamiento pida separar.

🗣️ **2 minutos:** Con esas condiciones, la base compartida es infraestructura común, como la red: no acopla cambios ni despliegues. Separarla solo añadiría operación. Reviso la decisión si aparece una necesidad concreta —cumplimiento, escala, ventana de mantenimiento propia— que la base común no pueda dar.

🔬 **El detalle:** La base compartida con dueños efectivos es una arquitectura respetable, no una etapa pendiente de completar.

## 📖 04 — Contratos frágiles y despliegues coordinados

### 1. 🟢 ¿Qué significa liberar en *lockstep* y en qué moneda se paga?

⏱️ **30 segundos:** Que varios componentes solo pueden salir juntos porque un cambio en uno rompe a los otros si no se actualizan a la vez. Se paga en la moneda de despliegue, y arrastra a la de equipos.

🗣️ **2 minutos:** El renombrado de `payments` obliga a `orders`, `notifications` y al informe a salir el mismo viernes con cuatro guardias. Cada release conjunto suma espera, riesgo y un rollback que también tiene que ser conjunto. Es la señal de que el contrato no permite versiones mixtas, aunque cada componente tenga su pipeline.

🔬 **El detalle:** Salir juntos a veces, por decisión, no es lockstep; lo es cuando salir por separado rompe algo.

### 2. 🟢 ¿Qué diferencia hay entre compatibilidad hacia atrás y hacia adelante, nombrando lector y escritor?

⏱️ **30 segundos:** Hacia atrás: un lector nuevo entiende lo que escribió la versión vieja. Hacia adelante: un lector viejo entiende lo que escribe la versión nueva.

🗣️ **2 minutos:** Nombrar los roles evita confusiones: en un evento de `payments`, `payments` escribe y `orders` lee. Si `orders` se actualiza antes, necesita compatibilidad hacia atrás con los eventos viejos; si `payments` sale antes, los lectores viejos necesitan compatibilidad hacia adelante con los nuevos. Un cambio desacoplado exige las dos durante la convivencia.

🔬 **El detalle:** Con replay, la compatibilidad hacia atrás dura lo que dura la retención de mensajes, no lo que dura el despliegue.

### 3. 🟢 ¿Quién es el lector y quién el escritor en una respuesta de `payments` y en un evento `PaymentAuthorized`?

⏱️ **30 segundos:** En una respuesta de consulta, `payments` escribe y el consumidor lee; en `PaymentAuthorized`, también escribe `payments` y leen `orders`, `notifications` y el informe.

🗣️ **2 minutos:** En la petición de consulta los papeles se invierten: el consumidor escribe la petición y `payments` la lee. Por eso un parámetro nuevo obligatorio en la petición rompe a los consumidores viejos, mientras que un campo nuevo en la respuesta rompe solo a los lectores estrictos. Nombrar quién lee decide qué lado tiene que tolerar el cambio.

🔬 **El detalle:** En un evento hay muchos lectores y el escritor no los controla; por eso la tolerancia de cada lector importa más que en una llamada con un solo cliente.

### 4. 🟢 ¿Qué es un lector tolerante?

⏱️ **30 segundos:** Un consumidor que ignora campos que no conoce y tiene una política explícita para valores desconocidos, en lugar de rechazar el mensaje.

🗣️ **2 minutos:** El lector tolerante convierte las evoluciones aditivas del proveedor en cambios que no le afectan. Ante un estado nuevo como `PARTIALLY_CAPTURED`, no revienta: deja el pedido en revisión o lo trata como el caso más conservador. Así el proveedor puede añadir sin coordinar, y el consumidor adopta el valor nuevo cuando le importe.

🔬 **El detalle:** Tolerar no es aceptar cualquier cosa: los campos que el consumidor usa se validan con rigor; lo que se ignora es lo que no usa.

### 5. 🟢 ¿Qué demuestra una prueba de consumidor y qué no demuestra?

⏱️ **30 segundos:** Que el proveedor sigue cumpliendo las expectativas mínimas que un consumidor declaró sobre el intercambio. No demuestra disponibilidad, autorización ni rendimiento.

🗣️ **2 minutos:** El consumidor publica qué campos y comportamientos usa; la CI del proveedor los ejecuta. Si `payments` retira `authorizationId` y `orders` aún lo declara, la CI falla antes del despliegue. Pero una prueba verde no dice que el proveedor aguante la carga ni que la autenticación siga funcionando: eso son otras pruebas.

🔬 **El detalle:** Una expectativa que copia la respuesta entera vuelve a acoplar: el proveedor ya no puede cambiar nada sin romperla.

### 6. 🟡 ¿Por qué añadir un campo o un valor de enum puede romper a un consumidor?

⏱️ **30 segundos:** Porque un lector estricto rechaza lo que no conoce: un campo extra o un valor de enum nuevo hacen fallar la deserialización o una decisión.

🗣️ **2 minutos:** Añadir es compatible solo si el lector lo ignora. Muchos deserializadores rechazan campos desconocidos por configuración, y un `switch` sobre el estado sin rama por defecto falla con un valor nuevo. Además, un enum nuevo puede cambiar el significado de una decisión aunque se deserialice bien: un pago parcial no es un pago completo.

🔬 **El detalle:** Por eso la compatibilidad de un campo aditivo depende de los lectores, y se prueba con ellos, no se declara desde el proveedor.

### 7. 🟡 ¿Cómo migrarías `authorizationId` a `reference`?

⏱️ **30 segundos:** Con expand-contract: publicar los dos campos con el mismo valor, migrar lectores, observar el uso y retirar el viejo al cerrar la ventana.

🗣️ **2 minutos:** `payments` añade `reference` sin quitar `authorizationId`; cada consumidor pasa a leer `reference` con el viejo de respaldo y sale cuando quiera; la telemetría dice qué versiones siguen leyendo el campo viejo. Solo con cero uso durante el horizonte acordado —despliegue y retención— se retira. Se paga duplicación temporal a cambio de releases independientes.

🔬 **El detalle:** Si los dos campos llegan distintos, es un error de contrato que se registra y se trata como tal; elegir uno en silencio esconde el fallo.

### 8. 🟡 ¿Por qué `orders` dejó 300 pedidos sin confirmar al reprocesar mensajes, y qué política lo habría evitado?

⏱️ **30 segundos:** Porque su consumidor rechazaba valores de enum desconocidos, y el reprocesamiento trajo eventos con `PARTIALLY_CAPTURED`. Una política para valores desconocidos lo habría evitado.

🗣️ **2 minutos:** El lector estricto convertía cada mensaje con el estado nuevo en un error y el pedido nunca pasaba a confirmado. Si el consumidor hubiera tratado el valor desconocido como «requiere revisión», los pedidos habrían quedado visibles y atendibles, sin bloquear el flujo. Además, el proveedor debió anunciar el valor antes de emitirlo.

🔬 **El detalle:** El fallo apareció en el replay, no en el despliegue: la retención de mensajes forma parte del contrato aunque nadie lo haya escrito.

### 9. 🟡 ¿Por qué probar solo contra las ramas actuales de los consumidores resulta insuficiente?

⏱️ **30 segundos:** Porque lo que se rompe en producción es la versión desplegada del consumidor, que puede ser semanas más vieja que su rama principal.

🗣️ **2 minutos:** Si la CI de `payments` prueba contra la rama actual de `orders`, que ya lee `reference`, retirar `authorizationId` parece seguro; pero la versión de `orders` que corre en producción todavía lo lee. La CI tiene que conocer qué versiones están desplegadas y ejecutar sus expectativas.

🔬 **El detalle:** Esto exige un registro de versiones desplegadas por entorno; sin él, la compatibilidad se supone en lugar de comprobarse.

### 10. 🟡 ¿Cómo afecta la retención de mensajes a la ventana de convivencia?

⏱️ **30 segundos:** La alarga: un lector nuevo tiene que entender los mensajes viejos mientras se puedan reprocesar, aunque el despliegue haya durado minutos.

🗣️ **2 minutos:** Si el broker retiene siete días, durante siete días puede llegar un `PaymentAuthorized` sin `reference`. La ventana de convivencia se calcula con el mayor entre la duración del despliegue y la retención. Retirar antes el soporte del formato viejo rompe el replay justo cuando se necesita, en una recuperación.

🔬 **El detalle:** Por eso conviene conservar muestras anonimizadas de cada versión del evento y probar contra ellas en CI.

### 11. 🟡 ¿Qué resuelve y qué no resuelve publicar una `/v2`?

⏱️ **30 segundos:** Da un nombre a dos contratos y permite servirlos a la vez. No dice cuándo se retira el viejo, quién lo usa ni cómo versionar eventos, que no tienen URL.

🗣️ **2 minutos:** Una `/v2` sin telemetría de uso ni fecha de retirada se convierte en una rama más que mantener indefinidamente, y la `/v3` en otra. Tampoco resuelve el problema de fondo, que es que los lectores no toleran cambios aditivos. Es útil para cambios realmente incompatibles, acompañada de la misma disciplina de expand-contract.

🔬 **El detalle:** Muchos renombrados no necesitan versión nueva: basta con publicar los dos campos durante la ventana.

### 12. 🟡 ¿Qué coste tiene una librería compartida con las clases de los eventos?

⏱️ **30 segundos:** Obliga a todos los consumidores a actualizar la librería a la vez cuando cambia un evento: el lockstep vuelve por el build.

🗣️ **2 minutos:** La librería evita errores de contrato en compilación, pero ata cada consumidor a una versión del modelo del productor. Un cambio en un evento que solo le importa a uno exige recompilar y desplegar a todos. Una librería de transporte —serialización, reintentos— es inocua; una con las clases del dominio es un contrato frágil empaquetado.

🔬 **El detalle:** La alternativa es que cada consumidor tenga su propio modelo de lectura del evento, validado contra el esquema publicado.

### 13. 🟡 ¿Qué métrica distingue autonomía de despliegue de simple frecuencia de releases?

⏱️ **30 segundos:** El porcentaje de releases que requieren obligatoriamente otro release, y la espera por coordinación.

🗣️ **2 minutos:** Que `payments` libere diez veces al mes no dice nada si ocho de esas veces arrastraron a tres consumidores. La autonomía se ve en releases que salen solos sin romper a nadie, en el tiempo que un cambio espera a otro equipo y en los fallos atribuibles a versiones mixtas. Esos números se comparan antes y después de la remediación.

🔬 **El detalle:** La frecuencia de despliegue puede subir sin autonomía si cada salida es un tren más pequeño.

### 14. 🟡 ¿Cuándo aceptarías un release train como decisión razonable?

⏱️ **30 segundos:** Cuando los componentes pertenecen a un único producto y equipo y necesitan siempre el mismo cambio: el despliegue conjunto es más barato que simular autonomía.

🗣️ **2 minutos:** Mantener compatibilidad, pruebas de consumidor y telemetría cuesta. Si el negocio cambia los cuatro componentes a la vez y los opera un solo equipo, esa inversión no compra nada y un release común, honesto, es proporcional. Lo que no es aceptable es pagar el coste de la distribución y además el del lockstep sin haberlo decidido.

🔬 **El detalle:** Ese caso suele ser una señal para reconsiderar la frontera: si todo sale junto siempre, quizá debería ser un solo despliegue.

### 15. 🟡 ¿Cómo probarías la compatibilidad semántica del importe, además de la forma?

⏱️ **30 segundos:** Con fixtures que comparen el significado, no solo la forma: mismo importe en unidades menores, misma moneda y mismo redondeo en productor y consumidor.

🗣️ **2 minutos:** Una prueba de forma aceptaría `12000` aunque el consumidor lo interpretara como 12 000 pesos en lugar de 120,00. Hace falta un caso de contrato que fije la unidad —`amountMinor` con `currency`— y compruebe el valor que el consumidor calcula. Los cambios de unidad son incompatibles aunque el campo no cambie de nombre.

🔬 **El detalle:** Una divergencia monetaria detectada durante la convivencia detiene la migración: no hay versión mixta aceptable con importes distintos.

### 16. 🟡 ¿Qué diferencia hay entre una feature flag y una versión del contrato?

⏱️ **30 segundos:** La flag decide si se activa un comportamiento ya desplegado; la versión del contrato decide qué forma tienen los datos que se intercambian.

🗣️ **2 minutos:** La flag permite desplegar el soporte compatible y activarlo por cohorte sin otro despliegue. Pero apagarla no cambia los eventos ya emitidos ni los datos persistidos con la forma nueva: esos siguen existiendo y los lectores los verán. La versión del contrato es lo que esos lectores tienen que tolerar, con o sin flag.

🔬 **El detalle:** Una flag no sustituye la compatibilidad: si activarla produce datos que un lector viejo no entiende, el problema solo se aplazó.

### 17. 🟡 ¿Qué comparten un DTO de Java y una interfaz de TypeScript como frontera remota, y en qué difieren?

⏱️ **30 segundos:** Los dos describen lo que el código espera, no lo que llega. El DTO de Java se valida al deserializar, según cómo esté configurado; la interfaz de TypeScript desaparece en runtime.

🗣️ **2 minutos:** En Java, el deserializador puede rechazar o ignorar campos desconocidos y fallar ante tipos incorrectos, así que el DTO actúa como frontera si se configura bien. En TypeScript, la interfaz no valida nada: un cast acepta cualquier objeto y el error aparece lejos. Por eso en Node hace falta validar el payload en runtime con un esquema.

🔬 **El detalle:** En ambos casos, exportar la entidad persistente o el tipo interno como DTO convierte el modelo del productor en contrato de todos.

### 18. 🟠 ¿Qué riesgo comparten los valores cero de Go y los diccionarios sin validar de Python al leer un contrato?

⏱️ **30 segundos:** Los dos confunden «no enviado» con un valor válido: Go rellena con cero lo que falta y un diccionario de Python acepta cualquier forma sin quejarse.

🗣️ **2 minutos:** Si `payments` deja de enviar `amountMinor`, un `struct` de Go lo lee como `0` y un consumidor puede registrar un pago de importe cero. En Python, un `dict` sin validar pasa hasta que alguien accede a una clave que no existe. En ambos casos hace falta distinguir ausencia —punteros, tipos opcionales, validación explícita— y probar con payloads viejos.

🔬 **El detalle:** El error es silencioso en Go y tardío en Python; los dos llegan a producción si las fixtures solo contienen el formato actual.

### 19. 🟠 `payments` ya emitió eventos con la forma nueva y aparece un fallo. ¿Puedes revertir el proveedor?

⏱️ **30 segundos:** Puedes revertir el código del proveedor, pero no los eventos que ya emitió: los consumidores tienen que seguir entendiéndolos.

🗣️ **2 minutos:** Revertir `payments` a la versión anterior deja en el broker y en los replays eventos con la forma nueva. Si los consumidores viejos no los toleran, revertir no arregla nada. Por eso la forma nueva solo se emite cuando los lectores vigentes ya la aceptan, y un fallo se corrige hacia adelante sobre ese estado.

🔬 **El detalle:** Si la forma nueva es incompatible y ya se emitió, hay que decidir qué hacer con esos mensajes: reescribirlos, reprocesarlos con un adaptador o descartarlos con registro.

### 20. 🟠 Una prueba contractual verde, ¿te permite retirar la autenticación anterior de una API?

⏱️ **30 segundos:** No: la prueba contractual demuestra el intercambio de datos, no la seguridad ni quién sigue usando la autenticación vieja.

🗣️ **2 minutos:** Retirar un mecanismo de autenticación necesita otra evidencia: telemetría de qué clientes lo usan, pruebas de integración de autorización y un aviso con fecha. Una prueba de consumidor puede estar verde con un token de prueba que nunca pasa por el mecanismo que se quiere retirar.

🔬 **El detalle:** Es el límite general de las pruebas de consumidor: cubren el contrato de datos, y la seguridad, la disponibilidad y el rendimiento necesitan sus propias pruebas.

### 21. 🟠 La telemetría muestra que un consumidor sin dueño conocido sigue leyendo `authorizationId`. ¿Qué haces?

⏱️ **30 segundos:** No retiro el campo: busco al dueño por la telemetría y la identidad del cliente, y hasta encontrarlo el campo sigue.

🗣️ **2 minutos:** La telemetría por versión dice qué credencial o qué servicio lee `authorizationId`. Con eso se localiza el equipo o se asigna uno; mientras tanto, la retirada se pospone con una fecha nueva y se registra la excepción. Retirar a ciegas rompería a un consumidor que nadie podrá arreglar rápido.

🔬 **El detalle:** Un consumidor sin dueño es un riesgo operativo independiente del contrato; conviene escalarlo, no solo esquivarlo.

### 22. 🟠 Apagaste la flag del cambio y siguen apareciendo fallos en `orders`. ¿Qué pasa y qué haces?

⏱️ **30 segundos:** La flag desactivó el comportamiento, pero los eventos con la forma nueva ya emitidos siguen llegando a `orders`. Hay que tratar esos mensajes, no solo la flag.

🗣️ **2 minutos:** Primero confirmo que los fallos vienen de mensajes emitidos antes de apagar la flag, por su fecha y versión. Después contengo: `orders` aplica una política tolerante o manda esos mensajes a revisión en lugar de rechazarlos. Por último corrijo el lector para que entienda la forma nueva, porque volverá a aparecer.

🔬 **El detalle:** Si los fallos vinieran de mensajes posteriores, la flag no gobierna lo que se cree, y ese es otro defecto.

### 23. 🟠 ¿Aceptarías mantener dos contratos indefinidamente?

⏱️ **30 segundos:** No como política: dos contratos indefinidos son dos implementaciones que mantener y probar para siempre. Solo con un motivo, un dueño y un coste aceptados.

🗣️ **2 minutos:** A veces un cliente externo no puede migrar y el negocio decide pagar la convivencia; entonces se registra como excepción, con quién paga el mantenimiento y cuándo se revisa. Lo que no vale es la convivencia por omisión, sin telemetría ni fecha: acumula versiones que nadie se atreve a retirar.

🔬 **El detalle:** Un adaptador en el borde que traduzca el contrato viejo al nuevo reduce el coste: el núcleo solo implementa uno.

### 24. 🟠 ¿Qué evidencia te haría detener la retirada de `authorizationId`?

⏱️ **30 segundos:** Consumidores sin inventario, lecturas del campo viejo en la telemetría o cualquier contradicción monetaria entre `authorizationId` y `reference`.

🗣️ **2 minutos:** Cualquiera de esas señales dice que retirar ahora rompe a alguien o que la convivencia esconde un error. Se detiene la retirada, se corrige la causa y se fija una fecha nueva. Solo con cero uso durante todo el horizonte —despliegues y retención— y sin divergencias, el campo se retira.

🔬 **El detalle:** El criterio de parada se acuerda antes de empezar: decidirlo sobre la marcha, con presión por cerrar, suele terminar en retirar demasiado pronto.

## 📖 05 — Fallos parciales, retries y falsas transacciones

### 1. 🟢 ¿Qué significa que un resultado remoto sea incierto?

⏱️ **30 segundos:** Que la operación pudo ejecutarse o no, y quien la pidió no lo sabe todavía: se perdió la respuesta, no necesariamente el efecto.

🗣️ **2 minutos:** Un timeout de `payments` contra el proveedor es el caso típico: el cobro pudo autorizarse justo después de que venciera la espera. Tratarlo como éxito confirma pedidos sin cobro; tratarlo como fallo invita a cobrar otra vez. Lo correcto es un estado propio, `PENDING`, con la clave que permite preguntar después qué pasó.

🔬 **El detalle:** La incertidumbre no se elimina con un timeout más largo; solo se desplaza. Se gestiona con identidad estable y reconciliación.

### 2. 🟢 ¿Qué protege una outbox y qué no?

⏱️ **30 segundos:** Que el cambio de estado y el mensaje que lo anuncia se confirmen juntos, así que ningún mensaje se pierde ni se publica sin cambio. No evita repeticiones.

🗣️ **2 minutos:** El pedido y la fila de la outbox se escriben en la misma transacción local; un publicador los lee y los envía. Si cae después de entregar y antes de marcar enviado, al volver reenvía: el consumidor verá duplicados. Tampoco protege el efecto remoto del consumidor: eso depende de su propia idempotencia.

🔬 **El detalle:** La garantía honesta de la outbox es *at-least-once*; el «una vez» lo pone la deduplicación del lado que recibe.

### 3. 🟢 ¿Qué protege una inbox transaccional?

⏱️ **30 segundos:** Que un mensaje repetido no aplique su efecto local dos veces: el registro del mensaje y el efecto se confirman en la misma transacción del consumidor.

🗣️ **2 minutos:** Al recibir, el consumidor inserta el identificador del mensaje en su inbox con una restricción única y aplica el efecto en la misma transacción. Si el mensaje ya estaba, no hace nada. Así, las repeticiones de la outbox o de un *ack* perdido son inocuas para el estado local.

🔬 **El detalle:** La inbox no protege llamadas externas que haga el consumidor: si al procesar cobra a un proveedor, ese cobro necesita su propia clave.

### 4. 🟢 ¿Qué diferencia hay entre un rechazo y un estado pendiente?

⏱️ **30 segundos:** Un rechazo es una decisión definitiva del proveedor; un pendiente es la ausencia de una decisión conocida.

🗣️ **2 minutos:** Ante un rechazo se libera la reserva y se informa al cliente; reintentar no cambia nada. Ante un pendiente no se libera ni se confirma: se consulta por la clave hasta obtener respuesta o agotar el plazo. Confundirlos produce los dos errores clásicos: cobrar dos veces o liberar stock de un pedido que sí se pagó.

🔬 **El detalle:** El pendiente necesita un plazo y un destino final, `REVIEW`, o se convierte en un estado del que nada sale.

### 5. 🟢 ¿Qué es una compensación y en qué se diferencia de un rollback?

⏱️ **30 segundos:** Una operación nueva que intenta neutralizar el efecto de una anterior, como anular una autorización. A diferencia del rollback, no borra lo ocurrido y puede fallar.

🗣️ **2 minutos:** El rollback de la base deshace escrituras no confirmadas como si nunca hubieran existido. La compensación actúa sobre algo ya confirmado en otro sistema: queda registro de la autorización y de su anulación, puede llegar tarde y puede ser rechazada. Por eso se diseña con su propia clave, sus reintentos y su camino a revisión.

🔬 **El detalle:** Algunas compensaciones no existen: un correo enviado no se «desenvía», solo se puede mandar otro.

### 6. 🟡 ¿Por qué no se genera una clave nueva al reintentar?

⏱️ **30 segundos:** Porque la clave identifica la intención, no el intento: una clave nueva es, para el proveedor, un cobro nuevo.

🗣️ **2 minutos:** Si cada reintento genera su clave, el proveedor no puede saber que es la misma compra y autoriza de nuevo, que es exactamente lo que produjo las 41 autorizaciones dobles. La clave se crea una vez, se persiste antes de salir a red y se reutiliza en cada reintento y consulta, también desde el cliente cuando repite la petición.

🔬 **El detalle:** La clave debe sobrevivir a reinicios del proceso: si solo vive en memoria, un reinicio entre intentos genera otra.

### 7. 🟡 ¿Qué haces si llega la misma clave con otro importe?

⏱️ **30 segundos:** Lo rechazo como conflicto: misma clave con otro contenido es una clave reutilizada, no la misma intención.

🗣️ **2 minutos:** Devolver el resultado guardado ocultaría el error del cliente; ejecutar el cobro nuevo rompería la garantía de la clave. Por eso se guarda una huella de la solicitud junto a la clave y se compara: igual, se devuelve la respuesta original; distinta, se responde conflicto y se registra.

🔬 **El detalle:** La huella debe cubrir los campos que definen la intención —importe, moneda, pedido—, no metadatos como la hora de envío.

### 8. 🟡 ¿Dónde termina la atomicidad en el método que guarda el pedido y llama a `payments`?

⏱️ **30 segundos:** En el `COMMIT` de la base de `orders`: la llamada HTTP a `payments` ocurre en otro sistema y el rollback no la alcanza.

🗣️ **2 minutos:** La anotación transaccional abarca las escrituras en la base local y nada más. Cuando el timeout provoca el rollback, el pedido desaparece pero la autorización sigue en el proveedor. Además, esperar la red dentro de la transacción retiene conexión y locks. La corrección es confirmar la intención y el trabajo en la transacción, y llamar al proveedor después.

🔬 **El detalle:** El nombre del método no define atomicidad; la define qué recursos participan en la transacción.

### 9. 🟡 ¿Cómo recuperas una caída del publicador después de entregar un mensaje de la outbox?

⏱️ **30 segundos:** Al volver, el publicador reenvía las filas no marcadas; el consumidor recibe un duplicado y lo descarta por su identificador.

🗣️ **2 minutos:** La outbox asume esa ventana: el mensaje salió pero la marca no se escribió. Lo que la hace segura es que cada mensaje lleva un identificador estable y el consumidor deduplica con su inbox. Se vigila la edad de la fila pendiente más antigua para detectar un publicador parado.

🔬 **El detalle:** Marcar como enviado antes de entregar cambiaría duplicados por pérdidas, que es peor.

### 10. 🟡 ¿Cómo resuelves un *ack* perdido después del commit del consumidor?

⏱️ **30 segundos:** El broker vuelve a entregar el mensaje; el consumidor lo encuentra en su inbox y no repite el efecto, y esta vez confirma la recepción.

🗣️ **2 minutos:** El consumidor aplicó el efecto y lo registró en la misma transacción, pero el *ack* no llegó al broker. En la reentrega, la restricción única de la inbox detecta el duplicado y el consumidor solo hace el *ack*. Por eso el *ack* se envía siempre después de confirmar efecto e inbox, nunca antes.

🔬 **El detalle:** Si el *ack* fuera antes del commit, una caída entre ambos perdería el mensaje sin rastro.

### 11. 🟡 ¿Qué debe mostrar `orders` al cliente mientras el pago está en `PENDING`?

⏱️ **30 segundos:** Que el pedido existe y está pendiente de confirmación de pago, con su identificador para consultarlo; nunca un error que invite a comprar otra vez.

🗣️ **2 minutos:** El cliente necesita saber que su intención quedó registrada, que no debe repetirla y cuándo sabrá el resultado. Si recibe un error, reintenta y crea otra intención. Un estado visible y consultable reduce reintentos y tickets de soporte, y el aviso llega cuando `orders` confirme o rechace.

🔬 **El detalle:** El texto del estado es parte del diseño: «procesando tu pago» dice algo distinto a «error» y cambia el comportamiento del usuario.

### 12. 🟡 ¿Qué pasa si vence la reserva de `inventory` antes de conocer el resultado del pago?

⏱️ **30 segundos:** El pedido no se confirma con la reserva vencida: hay que renovarla si `inventory` lo permite o, si el pago llega autorizado sin stock, anular la autorización.

🗣️ **2 minutos:** La reserva tiene vencimiento para no retener stock indefinidamente, y el pago pendiente puede resolverse después. Hay que elegir la política: renovar la reserva mientras el pago esté en `PENDING` dentro de un límite, o aceptar que un pago tardío termine en anulación y aviso al cliente. Lo que no vale es confirmar un pedido sin stock.

🔬 **El detalle:** El plazo de la reserva y el de la reconciliación se deciden juntos; si el segundo es mucho mayor, las anulaciones serán frecuentes.

### 13. 🟡 ¿Cuándo considerarías 2PC, y por qué casi nunca aplica a un proveedor externo?

⏱️ **30 segundos:** Solo si todos los participantes lo soportan y un requisito lo exige; un proveedor externo casi nunca participa en un protocolo de dos fases con tu coordinador.

🗣️ **2 minutos:** 2PC necesita recursos que acepten preparar y confirmar bajo un coordinador, y retiene bloqueos mientras decide; un fallo del coordinador puede dejarlos esperando. Un proveedor de pagos por HTTP no ofrece esa interfaz. Entre bases propias puede tener sentido; con terceros, la herramienta es clave, estado y reconciliación.

🔬 **El detalle:** Si dos componentes propios necesitan 2PC para cada operación, suele ser más barato juntarlos en una base y un proceso.

### 14. 🟡 ¿Qué métrica priorizas para saber si la reconciliación va al día?

⏱️ **30 segundos:** La edad del pendiente más antiguo, y las divergencias entre lo registrado y lo que dice el proveedor.

🗣️ **2 minutos:** El número de pendientes puede ser estable mientras un caso lleva días atascado; la edad lo revela. Las divergencias —autorizaciones que el proveedor tiene y nosotros no, o al revés— miden si la reconciliación es correcta, no solo si avanza. También conviene contar cuántos casos llegan a `REVIEW`.

🔬 **El detalle:** Una cola que no crece no demuestra salud: puede estar vacía porque el publicador dejó de escribir.

### 15. 🟡 ¿Cómo decides el presupuesto de reintentos y en qué capa van?

⏱️ **30 segundos:** Desde el presupuesto de tiempo del flujo y la naturaleza del error, con reintentos en una sola capa, backoff y jitter.

🗣️ **2 minutos:** Primero, solo se reintentan errores transitorios; un rechazo de negocio no. Segundo, la suma de intentos cabe en el presupuesto del usuario o sale del camino síncrono hacia el worker. Tercero, una sola capa reintenta: si reintentan gateway, `orders` y cliente, la carga se multiplica sobre el proveedor que ya va mal.

🔬 **El detalle:** Los reintentos del camino síncrono deben ser pocos; la persistencia del worker es la que da tiempo a esperar al proveedor.

### 16. 🟡 ¿Qué evento dispara el aviso de `notifications`, y por qué no el envío de la solicitud de pago?

⏱️ **30 segundos:** El cambio de estado confirmado por `orders` —pedido confirmado o rechazado—, publicado desde la outbox; no el envío de la solicitud de pago.

🗣️ **2 minutos:** Enviar la solicitud no dice si se cobró. Si `notifications` avisara en ese momento, el cliente recibiría «pedido confirmado» de compras que después quedan en revisión o se rechazan. El aviso sigue al hecho de negocio, y por eso se publica con el cambio de estado en la misma transacción.

🔬 **El detalle:** Para el estado pendiente puede haber otro aviso, «estamos procesando tu pago», que también sale de un estado registrado.

### 17. 🟡 ¿Qué error comparten un `await` en Node y una llamada HTTP de Java dentro de una transacción?

⏱️ **30 segundos:** Los dos suponen que, cuando la espera local termina, el resultado remoto está decidido y ligado a la transacción, y no lo está.

🗣️ **2 minutos:** En Java, la llamada dentro de la transacción retiene conexión y el rollback no deshace el cobro. En Node, el `await` que vuelve con error se lee como fallo del cobro, cuando solo falló la espera. En los dos casos la corrección es la misma: confirmar la intención antes, llamar fuera de la transacción y modelar el resultado desconocido como `PENDING`.

🔬 **El detalle:** En Node además es fácil lanzar la promesa sin esperarla; entonces ni siquiera se registra que hubo un intento.

### 18. 🟠 ¿Qué riesgo comparten cancelar un `context` en Go y capturar una excepción en Python tras llamar al proveedor?

⏱️ **30 segundos:** Los dos convierten el final de la espera en una decisión: cancelar o capturar parece «no se cobró», y se tiende a reintentar con otra clave.

🗣️ **2 minutos:** Cancelar un `context` en Go deja de esperar, pero la petición pudo llegar al proveedor. Una excepción en Python tras la llamada puede ser un timeout de lectura con cobro hecho. En ambos casos la operación queda `PENDING` con su clave, y el reintento o la consulta usan esa misma clave.

🔬 **El detalle:** La cancelación de Go sí libera recursos locales; lo que no hace es propagar un «deshacer» al otro sistema.

### 19. 🟠 ¿Cómo evitas que dos reconciliadores sobrescriban el estado de la misma operación?

⏱️ **30 segundos:** Con actualización condicional sobre el estado o una versión: solo pasa de `PENDING` a otro estado quien encuentra `PENDING`, y el otro vuelve a leer.

🗣️ **2 minutos:** Dos workers pueden consultar la misma operación y obtener resultados en momentos distintos. Si escribieran sin condición, el más lento podría sobrescribir `AUTHORIZED` con un resultado viejo. La política de la sección 5 ya ignora estados resueltos, y la escritura `UPDATE ... WHERE state = 'PENDING'` lo garantiza en la base.

🔬 **El detalle:** Reclamar la operación con un lease evita trabajo duplicado; la actualización condicional evita el daño si igualmente coinciden.

### 20. 🟠 El proveedor no ofrece consulta por clave ni idempotencia. ¿Qué haces?

⏱️ **30 segundos:** Reduzco la automatización: sin clave ni consulta, un reintento puede cobrar dos veces, así que el resultado incierto va a revisión con la evidencia disponible.

🗣️ **2 minutos:** Sin idempotencia, cada reintento es un riesgo; sin consulta, no hay forma automática de resolver el pendiente. Se limita a un intento, se registra todo lo enviado y recibido, y se reconcilia con los informes del proveedor —extractos, conciliación diaria— antes de confirmar o anular. Y se escala la carencia como riesgo del contrato con el proveedor.

🔬 **El detalle:** Una clave propia enviada en un campo de referencia a veces permite conciliar después, aunque el proveedor no la use para deduplicar.

### 21. 🟠 La anulación de una autorización también falla. ¿Cómo reaccionas?

⏱️ **30 segundos:** La anulación es otra operación incierta: se reintenta con su propia clave, se consulta y, si no se resuelve, pasa a revisión con evidencia.

🗣️ **2 minutos:** No se da por hecha ni se reintenta sin límite. Se registra la anulación pendiente, se consulta su resultado y, si el proveedor la rechaza —por ejemplo, porque la autorización ya se capturó—, se abre el camino de devolución y se avisa al cliente. Soporte ve el caso con todo el historial.

🔬 **El detalle:** Por eso las compensaciones también necesitan estado y métricas: son el lugar donde se acumulan los casos que nadie mira.

### 22. 🟠 ¿Qué prueba detectaría la falsa transacción de la sección 1 antes de producción?

⏱️ **30 segundos:** Una prueba que haga responder al proveedor después del timeout y compruebe que no queda cobro sin pedido ni segundo cobro al reintentar.

🗣️ **2 minutos:** Con un simulador o un proxy que añada latencia, se provoca que el proveedor autorice pasados los dos segundos. La prueba verifica que el pedido queda `PENDING` y no desaparece, que el reintento del cliente reutiliza la clave y que la reconciliación termina en un solo `AUTHORIZED`. La versión ingenua falla esta prueba de forma reproducible.

🔬 **El detalle:** Simular el proveedor con un mock que responde al instante nunca encuentra este defecto: hace falta latencia real o inyectada.

### 23. 🟠 ¿Puede borrarse la clave de idempotencia cuando el pedido termina?

⏱️ **30 segundos:** No en cuanto termina el pedido: debe vivir tanto como la ventana en la que un reintento o una consulta del proveedor pueden llegar.

🗣️ **2 minutos:** Si se borra al confirmar, un reintento tardío del cliente o un mensaje duplicado vuelve a encontrar la clave libre y crea otro cobro. La retención se decide con la política del proveedor y la ventana de recuperación local; pasado ese plazo, se archiva o se borra con un proceso explícito.

🔬 **El detalle:** Guardar la respuesta junto a la clave permite devolver exactamente el mismo resultado a un reintento, no solo detectarlo.

### 24. 🟠 Tienes 41 clientes con dos autorizaciones. ¿Qué haces hoy y qué cambias para que no se repita?

⏱️ **30 segundos:** Hoy, anular las autorizaciones duplicadas de forma controlada y avisar a los clientes; después, clave estable, estado `PENDING` y llamada fuera de la transacción.

🗣️ **2 minutos:** Primero se identifican los 41 casos cruzando registros propios con los del proveedor, se anulan con una clave por anulación y se comunica a cada cliente. Después se corrige la causa: intención y clave persistidas antes de llamar, reintentos que reutilizan la clave, reconciliación con plazo y una prueba que provoque el timeout tardío.

🔬 **El detalle:** El arreglo de hoy no debe esperar al estructural, y el estructural no debe quedarse en el arreglo de hoy: son dos tareas con dueños distintos.

## 📖 06 — Acoplamiento asíncrono: el monolito distribuido con broker

### 1. 🟢 ¿Qué diferencia hay entre un evento y un comando enviado por un broker?

⏱️ **30 segundos:** Un evento informa de algo que ya ocurrió y no espera respuesta; un comando pide que otro haga algo y su emisor depende del resultado.

🗣️ **2 minutos:** `OrderConfirmed` dice un hecho: los consumidores reaccionan si quieren y el productor no cambia su pasado según lo que hagan. `ReserveInventoryRequested` es una orden: `orders` necesita saber si se reservó. Enviarlo por un broker no lo convierte en evento; solo cambia el transporte.

🔬 **El detalle:** El nombre ayuda a delatar el contrato: un evento en pasado con un emisor que espera respuesta suele ser un comando disfrazado.

### 2. 🟢 ¿Qué es *event-carried state transfer* y qué riesgo tiene publicar la entidad completa?

⏱️ **30 segundos:** Es publicar en el evento el estado que los consumidores necesitan para no tener que preguntar al productor; con la entidad completa, cada campo interno se vuelve contrato.

🗣️ **2 minutos:** Transferir estado evita llamadas y da autonomía de lectura a los consumidores. Pero si el evento es la entidad —43 campos, notas internas, versión de fila—, cualquier consumidor puede depender de cualquier campo, y el productor ya no puede cambiar su modelo sin romper a alguien. Es una base compartida que llega por mensajes.

🔬 **El detalle:** El punto medio es publicar el estado que corresponde a un hecho de negocio y con un esquema que el productor versiona, no una copia de la fila.

### 3. 🟢 ¿Qué es el patrón *request-reply* sobre mensajería?

⏱️ **30 segundos:** Enviar un mensaje con un identificador de correlación y esperar la respuesta en otro canal, normalmente con un timeout.

🗣️ **2 minutos:** Es un patrón legítimo de Enterprise Integration Patterns: permite pedir algo a otro componente a través del broker. Pero la espera sigue siendo síncrona desde el punto de vista del llamador, que no puede responder hasta recibir la contestación. Añade al acoplamiento temporal el broker y el tópico de respuestas.

🔬 **El detalle:** Tiene sentido cuando el broker aporta algo —enrutamiento, balanceo entre consumidores, cola ante picos—; no como forma de «desacoplar» una llamada que sigue siendo necesaria.

### 4. 🟢 ¿Qué diferencia hay entre coreografía y orquestación?

⏱️ **30 segundos:** En la coreografía cada componente reacciona a los eventos de los demás sin coordinador; en la orquestación, un dueño del proceso decide los pasos y guarda su estado.

🗣️ **2 minutos:** La coreografía reparte el conocimiento del proceso entre los participantes: nadie lo tiene entero. La orquestación lo concentra en un componente que envía comandos, recibe resultados y sabe en qué paso está cada caso. Una difunde hechos; la otra conduce un proceso.

🔬 **El detalle:** El orquestador no tiene que ser un producto aparte: el módulo `orders` con una máquina de estados del pedido ya lo es.

### 5. 🟢 ¿Qué significa que el acoplamiento temporal quede diferido?

⏱️ **30 segundos:** Que el productor ya no depende de que el consumidor esté disponible ahora, pero el resultado de negocio sigue necesitando que el consumidor procese, y su retraso es latencia del flujo.

🗣️ **2 minutos:** Si `payments` va veinte minutos atrasado, `orders` no se cae, pero los pedidos esperan veinte minutos su autorización. El fallo cambió de forma: de error inmediato a retraso acumulado. Por eso el orden, el reprocesamiento y el lag pasan a ser requisitos del flujo.

🔬 **El detalle:** Es mejor que un fallo en cascada, pero no es ausencia de acoplamiento: es acoplamiento pagado en tiempo.

### 6. 🟢 ¿Qué campos mínimos debería llevar un hecho publicado?

⏱️ **30 segundos:** Identidad del evento para deduplicar, tipo, versión del esquema, momento en que ocurrió, identificador de la entidad y lo mínimo que un consumidor necesita para reaccionar.

🗣️ **2 minutos:** `eventId`, `type`, `version`, `occurredAt`, `orderId` y las líneas bastan para que `inventory` o analítica reaccionen. Lo que un consumidor necesita además —el correo del cliente, el precio con impuestos— lo obtiene de su propia proyección o del dueño de ese dato. Cada campo añadido es un compromiso de compatibilidad.

🔬 **El detalle:** El momento de ocurrencia distinto del momento de publicación importa para reprocesar y ordenar correctamente.

### 7. 🟡 ¿Por qué `reserveViaQueue` no desacopla checkout de `inventory`?

⏱️ **30 segundos:** Porque `orders` sigue sin poder responder a checkout hasta recibir la respuesta de `inventory`, así que la disponibilidad de checkout sigue siendo la de `inventory` durante esos dos segundos.

🗣️ **2 minutos:** Si `inventory` va atrasado consumiendo, el timeout expira y checkout falla igual que con HTTP. Además dependen del broker y del tópico de respuestas. Para desacoplar de verdad haría falta cambiar la promesa —pedido aceptado y reserva confirmada después— o reconocer la dependencia y usar una llamada síncrona honesta con presupuesto.

🔬 **El detalle:** La prueba es sencilla: detener el consumidor de `inventory` y ver qué pasa con checkout. Si falla, la cola no desacopló nada.

### 8. 🟡 ¿Por qué publicar `OrderUpdated` con 43 campos se parece a compartir la base?

⏱️ **30 segundos:** Porque los consumidores leen la estructura interna del productor, sin permisos que lo limiten ni un contrato que diga qué campos son públicos.

🗣️ **2 minutos:** Con una base compartida, otro componente lee las tablas de `orders`; con `OrderUpdated` completo, las lee a través del mensaje. En ambos casos, un cambio interno de `orders` rompe a lectores que nadie inventarió. Y como los mensajes se retienen, la rotura puede aparecer días después al reprocesar.

🔬 **El detalle:** La corrección es la misma que para la base: el dueño publica una vista con contrato —aquí, hechos versionados— y retira el acceso a su modelo interno.

### 9. 🟡 ¿Cómo obtendría `notifications` el correo del cliente si `OrderConfirmedV1` no lo incluye?

⏱️ **30 segundos:** Manteniendo su propia proyección de clientes, alimentada por los hechos del dueño del dato de contacto, o preguntando a ese dueño cuando lo necesita.

🗣️ **2 minutos:** El correo es dato de quien gestiona clientes, no del pedido. Si `notifications` lo guarda en una proyección con frescura declarada, puede enviar sin llamar a nadie. Si el dato cambia a menudo y la frescura importa, lo consulta. Lo que evita es depender de que `orders` lo transporte.

🔬 **El detalle:** Meter el correo en `OrderConfirmed` «porque es más cómodo» es exactamente cómo un hecho mínimo crece hasta ser una entidad.

### 10. 🟡 ¿Por qué una librería común de eventos devuelve el lockstep?

⏱️ **30 segundos:** Porque todos los componentes compilan contra las mismas clases de eventos, así que un cambio en la librería obliga a actualizar y desplegar a todos juntos.

🗣️ **2 minutos:** Con `commerce-events`, añadir un campo a un evento cambia una versión que todos consumen; si el cambio no es compatible, nadie puede quedarse en la anterior. El lockstep que se quiso evitar al pasar de HTTP a mensajes vuelve por el build. La alternativa es un esquema publicado y versionado por el productor, y consumidores que generan o escriben su propio lector tolerante.

🔬 **El detalle:** Compartir el esquema como documento versionado desacopla; compartirlo como librería compilada, no.

### 11. 🟡 ¿Cuándo es la coreografía la opción adecuada en el sistema de ejemplo?

⏱️ **30 segundos:** Para difundir hechos a los que otros reaccionan de forma independiente, como avisar al cliente, alimentar analítica o invalidar cachés.

🗣️ **2 minutos:** Cuando `orders` confirma un pedido, `notifications` y analítica reaccionan sin que la compra dependa de ellos. Nadie necesita coordinarlos ni saber si terminaron. Añadir un consumidor nuevo no cambia al productor. Ese es el caso en que la coreografía da autonomía real.

🔬 **El detalle:** Deja de encajar cuando las reacciones forman pasos de un proceso con esperas y compensaciones: ahí hace falta un dueño del estado.

### 12. 🟡 ¿Qué gana la compra si `orders` es dueño explícito del proceso?

⏱️ **30 segundos:** Un lugar donde está el estado de cada compra, qué se pidió, qué se recibió y qué hacer si algo no llega.

🗣️ **2 minutos:** Con `orders` como dueño, la máquina de estados del pedido registra `PENDING_PAYMENT`, reintenta o compensa, y soporte puede ver en qué paso está un pedido. Los plazos y las compensaciones viven en un sitio con dueño. Se paga concentrando lógica del proceso en `orders` y con comandos explícitos hacia los participantes.

🔬 **El detalle:** Orquestar no significa volver a lo síncrono: el orquestador puede enviar comandos por el broker y esperar resultados sin bloquear la respuesta al cliente.

### 13. 🟡 ¿Por qué el retraso de consumo necesita un objetivo propio?

⏱️ **30 segundos:** Porque el retraso del consumidor es tiempo que el cliente espera por el resultado de negocio, y sin objetivo nadie sabe cuándo es un problema.

🗣️ **2 minutos:** Un lag de diez segundos en `notifications` es irrelevante; uno de veinte minutos en `payments` deja pedidos sin confirmar. Cada consumidor que forma parte del flujo necesita un objetivo de retraso y una alerta sobre él, igual que un servicio tiene un objetivo de latencia.

🔬 **El detalle:** El lag se mide en tiempo —edad del mensaje más antiguo sin procesar—, no solo en número de mensajes pendientes.

### 14. 🟡 ¿Qué orden necesita el flujo de pedidos y qué lo rompe en un consumidor?

⏱️ **30 segundos:** Orden por pedido: los eventos de un mismo pedido deben procesarse en secuencia; lo rompen el procesamiento en paralelo de una misma clave y los reintentos que dejan pasar al siguiente.

🗣️ **2 minutos:** Si `OrderCancelled` se procesa antes que `OrderConfirmed`, el consumidor puede dejar un pedido confirmado que ya se canceló. Los brokers suelen garantizar orden por partición o clave; un consumidor que lanza una tarea en paralelo por mensaje, o que reintenta un mensaje mientras avanza el siguiente, rompe esa garantía.

🔬 **El detalle:** Una alternativa robusta es que el consumidor compare versiones o fechas de ocurrencia y descarte eventos más viejos que el estado que ya tiene.

### 15. 🟡 ¿Qué pasa con los mensajes retenidos cuando el productor cambia el esquema?

⏱️ **30 segundos:** Pueden ser ilegibles para el consumidor nuevo o interpretarse mal, porque se escribieron con el esquema anterior.

🗣️ **2 minutos:** Mientras haya mensajes retenidos o reprocesables, el consumidor tiene que entender todas las versiones publicadas en ese horizonte. Un renombrado rompe esa compatibilidad: el reprocesamiento de hace una semana falla o, peor, lee un campo vacío como valor válido. Por eso la evolución es aditiva y la retirada espera a que caduque el horizonte.

🔬 **El detalle:** La compatibilidad de eventos se mide contra el horizonte de retención y reproceso, no contra el tiempo que dura un despliegue.

### 16. 🟡 Compara, en las cinco monedas, la cadena HTTP de `04/02` con el broker mal usado de este capítulo.

⏱️ **30 segundos:** La cadena HTTP acopla en runtime inmediato; el broker mal usado desplaza ese acoplamiento al tiempo, lo añade en datos por la entidad publicada y lo mantiene en despliegue por la librería común.

🗣️ **2 minutos:** Código: API del proveedor frente a esquema igual al modelo interno. Datos: petición al dueño frente a base compartida diferida. Despliegue: lockstep por API frente a lockstep por librería. Runtime: disponibilidad inmediata frente a espera con timeout o backlog. Equipos: en ambos casos, nadie es dueño del flujo completo. El broker mal usado empeora datos y no mejora equipos.

🔬 **El detalle:** La comparación enseña que cambiar de transporte movió el acoplamiento entre monedas en lugar de reducirlo.

### 17. 🟡 ¿Qué error comparten un consumidor Go que confirma antes de procesar y uno Python con auto-confirmación?

⏱️ **30 segundos:** Los dos pueden perder el mensaje: lo dan por procesado antes de aplicar el efecto, y si el proceso cae en medio, nadie lo vuelve a entregar.

🗣️ **2 minutos:** En Go, confirmar el offset y luego procesar deja una ventana en la que una caída pierde el mensaje. En Python, la auto-confirmación hace lo mismo sin que el código lo diga. La corrección es confirmar después de aplicar el efecto, aceptando que una caída tras aplicar provocará una repetición que el efecto debe tolerar.

🔬 **El detalle:** Es la elección entre *at-most-once* —confirmar antes— y *at-least-once* —confirmar después—; para efectos de negocio, casi siempre se elige lo segundo con deduplicación.

### 18. 🟠 ¿Por qué los tipos de TypeScript y una clase Java compartida fallan igual como contrato de eventos?

⏱️ **30 segundos:** Los dos convierten el esquema en código compartido que los consumidores deben adoptar a la vez, y ninguno valida lo que llega en runtime.

🗣️ **2 minutos:** Un paquete de tipos del productor obliga a actualizar el paquete para leer campos nuevos, y los tipos desaparecen al ejecutar: un mensaje malformado pasa sin error. Una clase Java compartida obliga a recompilar y desplegar juntos, y su deserialización puede fallar ante un campo desconocido. En ambos, el contrato real es el esquema publicado y versionado, validado al recibir.

🔬 **El detalle:** Cada consumidor puede generar sus tipos desde el esquema publicado; lo que no conviene es depender del artefacto de código del productor.

### 19. 🟠 El consumidor de `payments` acumula veinte minutos de retraso y hay pedidos en `PENDING`. ¿Qué harías primero?

⏱️ **30 segundos:** Mirar dónde está atascado el consumidor de `payments` —errores, un mensaje venenoso, capacidad o una dependencia lenta— y decir a soporte qué pedidos están afectados.

🗣️ **2 minutos:** Primero, el estado: si un mensaje falla siempre y bloquea la partición, se aparta a una cola de errores; si es capacidad, se escala el consumidor dentro del límite del proveedor; si es el proveedor, se reduce el ritmo. Mientras tanto, una consulta sobre los pedidos en `PENDING` da a soporte la lista afectada. Después, alerta por lag y un dueño del flujo que lo haga visible.

🔬 **El detalle:** Escalar consumidores solo ayuda si hay particiones suficientes y el cuello está en el consumidor; si es el proveedor, más consumidores lo empeoran.

### 20. 🟠 Un renombrado en el modelo de `orders` rompe a `notifications` al reprocesar mensajes de hace una semana. ¿Cómo lo corriges y cómo evitas que se repita?

⏱️ **30 segundos:** Hoy, un lector tolerante en `notifications` que acepte el campo viejo y el nuevo; para que no se repita, eventos versionados con evolución aditiva y pruebas de los consumidores contra mensajes históricos.

🗣️ **2 minutos:** La corrección inmediata hace que el reprocesamiento vuelva a funcionar. La estructural es que `orders` deje de publicar su modelo interno y publique hechos versionados, que solo se amplíen de forma compatible durante el horizonte de retención. Una prueba en CI que haga pasar a cada consumidor muestras reales de versiones anteriores detecta la rotura antes de producción.

🔬 **El detalle:** Conservar muestras anonimizadas de cada versión publicada es el equivalente de las pruebas de caracterización para eventos.

### 21. 🟠 Quieres reemplazar `OrderUpdated` por hechos mínimos sin romper a los cuatro consumidores. ¿Qué pasos reversibles darías?

⏱️ **30 segundos:** Publicar los hechos nuevos junto al evento viejo, migrar los consumidores uno a uno y retirar `OrderUpdated` cuando nadie lo lea.

🗣️ **2 minutos:** Paso uno: `orders` emite `OrderConfirmed` y `OrderCancelled` además de `OrderUpdated`, desde la misma transacción. Paso dos: cada consumidor pasa a los hechos y construye su proyección, con una flag para volver. Paso tres: se mide que nadie consume `OrderUpdated` y se retira tras el horizonte de retención. En todo momento se puede volver al evento viejo.

🔬 **El detalle:** Durante la convivencia, los consumidores deben deduplicar: un mismo cambio llega por dos eventos distintos.

### 22. 🟠 Negocio necesita saber en qué paso está cada compra. ¿Añadirías un orquestador o una traza de eventos?

⏱️ **30 segundos:** Un dueño del proceso con estado, porque responde en qué paso está cada compra y además decide qué hacer si algo no llega; la traza solo lo muestra después.

🗣️ **2 minutos:** Una traza distribuida de eventos ayuda a diagnosticar, pero reconstruir el estado desde trazas es frágil y no aplica plazos ni compensaciones. Si negocio necesita el paso de cada compra como dato, ese dato tiene dueño: el estado del pedido en `orders`. La traza complementa para depurar.

🔬 **El detalle:** Si la necesidad es solo de observación y los pasos son independientes, la traza puede bastar; el criterio es si alguien debe actuar sobre el estado.

### 23. 🟠 Un equipo propone volver a HTTP porque «los eventos complicaron todo» y otro quiere más eventos. ¿Cómo decidirías?

⏱️ **30 segundos:** Por flujo y por promesa: lo que el cliente necesita saber antes de la respuesta, síncrono y honesto; lo que puede llegar después, eventos con hechos mínimos y dueño.

🗣️ **2 minutos:** Volver a HTTP arreglaría los comandos disfrazados pero no la entidad publicada ni la librería común; más eventos agravarían ambos. Clasifico cada interacción: reserva, llamada con presupuesto; aviso y analítica, hechos; proceso de pago, dueño con estado. La discusión deja de ser sobre el transporte.

🔬 **El detalle:** Muchas veces los dos equipos tienen razón para distintas interacciones; el error es aplicar una sola respuesta a todas.

### 24. 🟠 ¿Qué evidencia te diría que el broker ya compra autonomía y no solo cambia el transporte?

⏱️ **30 segundos:** Que el productor pueda desplegar cambios compatibles sin coordinar, que la caída de un consumidor no bloquee la respuesta al cliente y que haya un dueño que sepa el estado de cada proceso.

🗣️ **2 minutos:** Mido despliegues del productor fuera de cualquier tren, ensayo la caída de cada consumidor viendo qué le pasa a checkout y compruebo que el lag tenga objetivo y alerta. Si los tres se cumplen, el broker compra autonomía. Si checkout falla con un consumidor detenido, o un cambio de esquema exige desplegar a todos, solo cambió el transporte.

🔬 **El detalle:** Es la misma prueba de autonomía efectiva de `04/01`, aplicada a las interacciones por mensajes.

## 📖 07 — Cómo se llega: granularidad, entidades y plataforma compartida

### 1. 🟢 ¿Qué es un servicio por entidad y en qué se diferencia de un servicio por capacidad?

⏱️ **30 segundos:** Un servicio por entidad expone operaciones de lectura y escritura sobre una tabla; uno por capacidad reúne el dato con las decisiones que lo cambian.

🗣️ **2 minutos:** `stock-service` con `GET` y `PUT` es dueño de la fila, pero la regla «reservar si hay stock» queda en quien llama. `inventory` como capacidad decide la reserva y protege su invariante. El primero reparte la lógica entre llamadores; el segundo la concentra donde está el dato.

🔬 **El detalle:** El corte por entidad es tentador porque se deriva del modelo de datos existente sin tener que entender el negocio.

### 2. 🟢 ¿Qué son los *nanoservices*?

⏱️ **30 segundos:** Servicios tan pequeños que el coste de su frontera —contrato, red, despliegue, guardia— supera el valor de lo que encapsulan.

🗣️ **2 minutos:** Un servicio que calcula un precio o valida un formato añade una llamada remota y un pipeline a cambio de muy poca lógica. Si casi todo cambio de negocio toca varios de ellos, la granularidad multiplica la coordinación en lugar de reducirla.

🔬 **El detalle:** El problema no es el tamaño en líneas, sino la relación entre lo que la frontera encapsula y lo que cuesta mantenerla.

### 3. 🟢 ¿Qué dice la ley de Conway?

⏱️ **30 segundos:** Que los sistemas que diseña una organización tienden a reproducir su estructura de comunicación.

🗣️ **2 minutos:** Melvin Conway lo formuló en 1968: si tres equipos construyen un compilador, sale un compilador de tres pasadas. Aplicado aquí, equipos por capa técnica producen sistemas cortados por capa, aunque se llamen servicios. La arquitectura y la organización se empujan mutuamente.

🔬 **El detalle:** La ley describe una tendencia, no una condena: se puede contrarrestar alineando equipos con el corte buscado.

### 4. 🟢 ¿Qué distingue una librería de plataforma inocua de una librería `commons` que acopla?

⏱️ **30 segundos:** Que la librería inocua es plataforma estable sin dominio —transporte, logging, autenticación— y la que acopla contiene entidades y reglas de negocio.

🗣️ **2 minutos:** Una librería de logging cambia poco y sus actualizaciones son compatibles; cada servicio la actualiza cuando quiere. Una `commons` con `Order` y sus validadores cambia con el negocio, y cada cambio obliga a todos a adoptarlo. La diferencia está en el contenido y en la política de compatibilidad, no en el hecho de compartir.

🔬 **El detalle:** Una prueba simple: si un cambio de negocio obliga a publicar una versión nueva de la librería, la librería contiene dominio.

### 5. 🟢 ¿Por qué un entorno de integración compartido puede ser una señal de despliegue acoplado?

⏱️ **30 segundos:** Porque si todos deben estar verdes en él para que cualquiera libere, el release de cada equipo depende del estado de los demás.

🗣️ **2 minutos:** Un entorno común con una suite end-to-end de noventa minutos convierte cada fallo ajeno en un bloqueo propio. Los equipos terminan liberando juntos cuando el entorno está verde: un release train de hecho. La señal es contar cuántos despliegues se retrasaron por fallos de otros servicios.

🔬 **El detalle:** Un entorno compartido para pruebas exploratorias no es un problema; lo es cuando se convierte en la única puerta de salida.

### 6. 🟢 ¿Qué problema causa una pasarela con reglas de negocio?

⏱️ **30 segundos:** Que las reglas de negocio quedan fuera de las capacidades que deberían poseerlas, y cambiar una regla obliga a tocar la pasarela y el servicio dueño.

🗣️ **2 minutos:** Si la pasarela calcula descuentos, `orders` no es dueño del total del pedido; un cambio de promoción toca dos componentes, y a veces dos equipos. La pasarela debe componer y adaptar respuestas para su cliente, no decidir reglas de dominio.

🔬 **El detalle:** Un BFF por cliente es útil precisamente porque adapta presentación; cuando empieza a decidir negocio, se vuelve un servicio sin dominio propio.

### 7. 🟡 ¿Por qué un `stock-service` CRUD deja la regla de reserva en quien lo llama?

⏱️ **30 segundos:** Porque el servicio solo expone lectura y escritura de la fila, y la comparación entre stock y cantidad pedida tiene que hacerla alguien: el llamador.

🗣️ **2 minutos:** El llamador lee el stock, decide y escribe el nuevo valor: exactamente el patrón leer-decidir-escribir que produce sobreventa bajo concurrencia, ahora con red en medio. La regla y la invariante quedan lejos del dato. Un `inventory` que exponga «reservar» hace la comparación donde está la fila.

🔬 **El detalle:** Es el mismo defecto de concurrencia del bloque 03, amplificado por el corte: cuanto más lejos está la regla del dato, más difícil es protegerla.

### 8. 🟡 ¿Por qué `order-service` terminó siendo el verdadero monolito del sistema?

⏱️ **30 segundos:** Porque concentró las decisiones que los servicios por entidad no tomaban: orquesta cinco llamadas y contiene la lógica de todas ellas.

🗣️ **2 minutos:** Cada regla que no cabía en un CRUD terminó en `order-service`: precios, disponibilidad, validación de cliente. Cambiar casi cualquier cosa de la compra exige tocarlo, y además llama a todos los demás. Es un monolito de lógica que depende en runtime de cinco servicios de datos.

🔬 **El detalle:** Reconocerlo cambia la propuesta: en lugar de partir `order-service`, conviene devolver cada decisión a la capacidad dueña de su dato.

### 9. 🟡 ¿Qué heurística usarías para saber si un corte es demasiado fino?

⏱️ **30 segundos:** Que la mayoría de los cambios habituales de una capacidad queden dentro de un solo servicio; si casi todos cruzan dos o más, el corte es demasiado fino o está en el eje equivocado.

🗣️ **2 minutos:** Tomo cambios reales de los últimos meses y cuento cuántos servicios tocó cada uno. Si una promoción toca precio, pedido y pasarela, esas fronteras no separan razones de cambio. También miro cuántas llamadas remotas necesita cada caso de uso frecuente.

🔬 **El detalle:** La misma heurística sirve al revés: un servicio que contiene cambios de varias capacidades con ritmos distintos puede ser demasiado grueso.

### 10. 🟡 ¿Cómo empuja una organización por capas técnicas a la arquitectura?

⏱️ **30 segundos:** Haciendo que cada cambio de negocio necesite a varios equipos, con lo que el sistema tiende a cortarse por capa aunque el diseño diga otra cosa.

🗣️ **2 minutos:** Con equipos de frontend, backend y base de datos, un cambio de promoción pasa por tres colas de trabajo. Para reducir esa coordinación, los equipos acuerdan interfaces entre capas, y el sistema se estructura por ellas. Los servicios «por dominio» del diagrama terminan con fronteras técnicas en la práctica.

🔬 **El detalle:** Por eso reorganizar la arquitectura sin revisar equipos suele durar poco: la organización la devuelve a su forma.

### 11. 🟡 ¿Qué es la maniobra inversa de Conway y qué riesgo tiene?

⏱️ **30 segundos:** Diseñar la estructura de equipos para que coincida con la arquitectura buscada, de modo que la ley de Conway empuje a favor; el riesgo es reorganizar personas sobre límites que todavía no se entienden.

🗣️ **2 minutos:** Si se quieren capacidades `orders`, `inventory` y `payments`, se forman equipos alrededor de ellas con las habilidades necesarias. Así cada cambio de capacidad queda en un equipo. Pero si los límites están mal elegidos, la reorganización los fija y cambiarlos luego cuesta otra reorganización.

🔬 **El detalle:** Conviene validar los límites con cambios reales —aunque sea dentro del monolito— antes de mover equipos.

### 12. 🟡 ¿Qué pondrías en una librería compartida y qué dejarías fuera?

⏱️ **30 segundos:** Pondría transporte, autenticación, logging, métricas y utilidades estables sin semántica de negocio; dejaría fuera entidades, reglas y validadores de dominio.

🗣️ **2 minutos:** La plataforma compartida ahorra trabajo repetido sin acoplar decisiones: cambia poco y de forma compatible. Las entidades y reglas cambian con el negocio y cada capacidad debe poder evolucionarlas sola, aunque eso suponga duplicar algún concepto con su propio significado.

🔬 **El detalle:** Tipos de valor muy estables, como `Money` con su moneda, pueden compartirse si tienen dueño y política de compatibilidad; es la excepción, no la regla.

### 13. 🟡 ¿Qué sustituye a una suite end-to-end común como filtro de release?

⏱️ **30 segundos:** Pruebas de contrato por consumidor, pruebas de cada servicio contra sus dependencias simuladas o en contenedor, y despliegues que cada servicio puede hacer y revertir por su cuenta.

🗣️ **2 minutos:** Cada consumidor publica lo que espera del proveedor y el proveedor lo verifica en su pipeline; así un cambio incompatible se detecta sin montar todo el sistema. Unos pocos E2E sobre los flujos críticos siguen existiendo, pero no bloquean cada release. El despliegue progresivo y la reversión rápida cubren lo que las pruebas no ven.

🔬 **El detalle:** Retirar la puerta común sin poner los contratos en su lugar solo traslada los fallos a producción.

### 14. 🟡 ¿Por qué una configuración o una caché compartidas producen fallos correlacionados?

⏱️ **30 segundos:** Porque un cambio en la configuración o una caída de la caché común afecta a todos los servicios a la vez.

🗣️ **2 minutos:** Si todos leen la misma configuración, un valor erróneo desplegado por un equipo degrada a los demás. Si todos usan la misma caché, su caída o su saturación golpea a todos en el mismo momento. Los servicios, separados en proceso, fallan juntos por la dependencia compartida.

🔬 **El detalle:** La disponibilidad compuesta asume fallos independientes; las dependencias compartidas son justamente lo que rompe ese supuesto.

### 15. 🟡 ¿Qué diferencia hay entre esta lista de causas y el diagnóstico de `04/01`?

⏱️ **30 segundos:** `04/01` describe el estado y cómo sostener el diagnóstico con evidencia; este capítulo enumera las decisiones que lo producen.

🗣️ **2 minutos:** El diagnóstico dice que el sistema cambia, se libera y falla junto; las causas explican por qué: corte por entidad, dominio compartido, puerta común, equipos por capa. Saber las causas evita que la remediación las repita, por ejemplo dividiendo más fino con la misma `commons`.

🔬 **El detalle:** Un buen informe de diagnóstico incluye las dos cosas: la evidencia del estado y la hipótesis sobre sus causas.

### 16. 🟡 ¿Por qué el corte por entidad obliga a varias de las otras decisiones de la tabla?

⏱️ **30 segundos:** Porque al quitar las decisiones de los servicios de datos, alguien tiene que tomarlas, y eso crea orquestadores, pasarelas con reglas y modelos compartidos para que todos entiendan lo mismo.

🗣️ **2 minutos:** Con servicios por entidad, `order-service` y la pasarela absorben la lógica; para que todos interpreten igual `Order` y `Customer`, aparece `commons`; y como cada cambio cruza servicios, se necesita el entorno común para probarlos juntos. El corte por entidad arrastra al resto de la tabla.

🔬 **El detalle:** Por eso corregir solo una de las otras decisiones —quitar `commons`, por ejemplo— sin cambiar el corte tiende a no sostenerse.

### 17. 🟡 ¿Cómo acopla una librería interna compartida en Java y en Go, y qué tienen en común?

⏱️ **30 segundos:** En Java, el build de cada aplicación resuelve una sola versión de la librería; en Go, la selección de versiones toma la mayor de las mínimas requeridas. En ambos, una versión nueva con dominio obliga a coordinar a los consumidores.

🗣️ **2 minutos:** Si dos dependencias de un servicio Java piden versiones distintas de `commons`, hay que alinearlas; en Go, que un módulo exija una versión más nueva arrastra a los demás que lo usan. Lo común es que una librería de dominio convierte su evolución en evolución de todos. El mecanismo de resolución cambia; el acoplamiento no.

🔬 **El detalle:** Una política de compatibilidad estricta —solo cambios aditivos en versiones menores— reduce el daño, pero no elimina que el dominio cambie por razones de negocio.

### 18. 🟠 ¿Qué falla igual en un paquete de tipos compartido en TypeScript y en modelos ORM compartidos en Python?

⏱️ **30 segundos:** Los dos comparten el modelo del productor como código, obligan a los consumidores a adoptar sus cambios y no validan lo que realmente llega o se guarda.

🗣️ **2 minutos:** Un paquete de tipos compartido hace que cada consumidor dependa de la forma interna del dominio ajeno; los tipos, además, no existen en runtime. Modelos ORM compartidos en Python dejan a cualquiera escribir entidades ajenas con las reglas que el modelo tenga o no. En ambos, un cambio de un dueño se propaga a todos.

🔬 **El detalle:** La alternativa en los dos casos es un contrato publicado —esquema o API— y modelos propios en cada consumidor.

### 19. 🟠 Te piden dividir los cinco servicios por entidad en diez más finos. ¿Qué harías en su lugar?

⏱️ **30 segundos:** Primero revisaría qué cambios cruzan los servicios actuales y propondría agrupar por capacidad antes que dividir: probablemente fusionar varios servicios por entidad en `inventory` y `orders`.

🗣️ **2 minutos:** Dividir en diez con el mismo criterio de entidad multiplicaría las llamadas y la lógica en los llamadores. Mapeo cambios reales al corte actual y a uno por capacidad, y presento la comparación: servicios tocados por cambio, llamadas por caso de uso. Si el corte por capacidad concentra los cambios, esa es la dirección.

🔬 **El detalle:** La conversación mejora si se presenta como «qué corte contiene los cambios» y no como «menos servicios»; el número es consecuencia.

### 20. 🟠 Una actualización de seguridad de `commons` obliga a desplegar doce servicios el mismo día. ¿Qué harías hoy y qué cambiarías?

⏱️ **30 segundos:** Hoy, desplegar la corrección de seguridad aunque cueste coordinar; después, separar de `commons` lo que es plataforma de lo que es dominio y permitir que cada servicio actualice a su ritmo.

🗣️ **2 minutos:** Una corrección de seguridad no espera, así que se coordina el despliegue con el mínimo cambio posible. Después analizo por qué afectó a doce servicios: si la vulnerabilidad estaba en código de plataforma mezclado con dominio, separar ambas partes permite que la plataforma se actualice sin arrastrar el dominio.

🔬 **El detalle:** Las correcciones de seguridad en plataforma compartida seguirán tocando a todos; lo que se evita es que cada cambio de negocio lo haga también.

### 21. 🟠 La suite end-to-end común está roja por un servicio ajeno y tu equipo tiene una corrección urgente. ¿Qué haces y qué cambias después?

⏱️ **30 segundos:** Pediría una excepción documentada para liberar con las pruebas propias y de contrato en verde y un plan de reversión; después, trabajaría para que la suite común deje de ser la única puerta.

🗣️ **2 minutos:** Si mi cambio no toca al servicio que falla y mis contratos pasan, el riesgo es acotado, y la corrección urgente pesa más. Registro la excepción con quién la aprobó y cómo revertir. Luego propongo contratos por consumidor para todos y E2E que informan en lugar de bloquear.

🔬 **El detalle:** Si la excepción se pide cada semana, ya no es una excepción: es la evidencia de que la puerta común no funciona.

### 22. 🟠 Quieres pasar de servicios por entidad a servicios por capacidad sin una reescritura. ¿Qué pasos reversibles darías?

⏱️ **30 segundos:** Empezar por una capacidad: crear su API de decisión sobre los servicios por entidad existentes, mover los llamadores a ella y, cuando todo pase por ahí, fusionar o absorber los servicios de datos.

🗣️ **2 minutos:** Paso uno: `inventory` expone «reservar» delegando temporalmente en `stock-service`. Paso dos: `order-service` deja de leer y escribir stock y llama a `inventory`, detrás de una flag. Paso tres: cuando nadie usa `stock-service` directamente, su tabla pasa a ser de `inventory` y el servicio se retira. Cada paso se puede revertir.

🔬 **El detalle:** Es un *strangler fig* hacia un corte más grueso; la dirección es la inversa de la habitual, y el mecanismo es el mismo.

### 23. 🟠 Dirección quiere reorganizar equipos por capacidad antes de tocar la arquitectura y los arquitectos quieren lo contrario. ¿Cómo decidirías?

⏱️ **30 segundos:** Haciéndolas en paralelo sobre una capacidad piloto: validar los límites con cambios reales y formar un equipo alrededor de esa capacidad antes de extenderlo.

🗣️ **2 minutos:** Reorganizar equipos primero fija límites que quizá no son los correctos; cambiar la arquitectura primero choca con equipos que la empujan de vuelta. Un piloto —por ejemplo, `inventory` con su equipo— permite ver si los cambios quedan dentro y si el equipo trabaja con autonomía. Con esa evidencia se decide cómo extender.

🔬 **El detalle:** La ley de Conway aconseja moverlas juntas; el piloto reduce el riesgo de hacerlo a ciegas en todo el sistema.

### 24. 🟠 ¿Qué criterio te diría que la granularidad actual ya es la adecuada?

⏱️ **30 segundos:** Que la mayoría de los cambios habituales quede en un solo servicio, que cada caso de uso frecuente necesite pocas colaboraciones remotas y que ningún servicio contenga capacidades con ritmos de cambio muy distintos.

🗣️ **2 minutos:** Si una promoción, una regla de reserva o un cambio de pago tocan cada uno su servicio, y checkout necesita dos o tres colaboraciones con garantía clara, la granularidad funciona. Reviso si aparece un servicio que cambia por razones de varios equipos o un caso de uso que cruza muchas fronteras.

🔬 **El detalle:** El criterio se mide con el historial de cambios y las trazas de los casos de uso, no con el tamaño de los servicios.

## 📖 08 — Desmontar un monolito distribuido

### 1. 🟢 ¿Qué es una línea base de remediación y qué mide en cada una de las cinco monedas?

⏱️ **30 segundos:** La foto del sistema antes de tocarlo, tomada sobre cambios reales: componentes tocados por cambio, escritores por tabla, releases obligatoriamente conjuntos, saltos síncronos e incidentes, y esperas entre equipos.

🗣️ **2 minutos:** Es la misma evidencia del diagnóstico, pero convertida en números comparables. Sin ella, cualquier remediación «parece» funcionar: menos incidentes en un mes tranquilo o menos contenedores no dicen nada. Con ella puedo afirmar que, tras fusionar, los cambios de reservas tocan un componente en lugar de dos y que el release ya no espera a otro equipo.

🔬 **El detalle:** La muestra tiene que ser representativa; si el periodo elegido solo contiene un proyecto transversal, se amplía antes de medir.

### 2. 🟢 ¿Qué es una costura de recuperación en un sistema ya distribuido?

⏱️ **30 segundos:** Un punto del flujo donde se puede cambiar una implementación por otra sin tocar a los llamadores, y observar el efecto de ese cambio aislado.

🗣️ **2 minutos:** En la reserva de `CreateOrder`, la costura es una fachada con ruta seleccionable: detrás puede estar la llamada remota actual o la implementación local. Permite mover una capacidad por cohortes, medir y volver atrás mientras la escritura no se haya transferido. Sin costura, cada cambio es un corte total.

🔬 **El detalle:** La costura debe estar donde se decide la invariante, no donde es más fácil insertar código; una costura en el sitio equivocado mueve tráfico sin mover autoridad.

### 3. 🟢 ¿En qué orden se remedian datos, contrato, cadena y release, y por qué ese orden?

⏱️ **30 segundos:** Datos primero, después contrato, después cadena y al final release: cada paso hace seguro al siguiente.

🗣️ **2 minutos:** Mientras dos componentes escriben la misma tabla, ningún contrato los independiza, porque se pisan en la base. Con un escritor por dato, el contrato puede evolucionar con versiones mixtas. Con contrato compatible, recortar saltos no rompe consumidores. Y solo entonces el release deja de ser obligatoriamente conjunto, porque ya nada obliga a salir juntos.

🔬 **El detalle:** El orden no es dogma: si un incidente de cadena está tumbando checkout hoy, se contiene primero con presupuesto de tiempo, y la remediación estructural sigue después en este orden.

### 4. 🟢 ¿Qué conserva una fusión bien hecha de dos componentes?

⏱️ **30 segundos:** Los módulos, sus APIs internas y la propiedad de cada tabla: se fusiona el despliegue, no el código.

🗣️ **2 minutos:** `orders` e `inventory` vuelven a un proceso, pero `orders` sigue reservando a través de la API de `inventory` y solo `inventory` escribe `reservations`. Lo que se gana es la transacción local y quitar dos saltos de red; lo que se conserva es el límite que permitiría volver a separar si algún día hiciera falta.

🔬 **El detalle:** Una prueba arquitectónica en CI es lo que impide que, a la semana, alguien importe el repositorio de `inventory` desde `orders` por comodidad.

### 5. 🟢 ¿Qué significa aquí *strangler fig* inverso?

⏱️ **30 segundos:** Usar el patrón de estrangulamiento al revés: en lugar de sustituir un legado por servicios, dirigir gradualmente operaciones remotas hacia una implementación local.

🗣️ **2 minutos:** Una fachada enruta por cohorte: una parte de los pedidos reserva en el proceso de `orders`, el resto sigue llamando a `inventory`. Se amplía la cohorte si las métricas acompañan. Es la misma mecánica que se usa para extraer, con la dirección cambiada, y con las mismas reglas: un escritor por operación y comparación en sombra solo de lecturas.

🔬 **El detalle:** No es un producto ni una librería; es una forma de ordenar la transición para que cada paso sea pequeño y reversible hasta transferir la escritura.

### 6. 🟢 ¿Qué es una cohorte estable y por qué la ruta no puede cambiar a mitad de una operación?

⏱️ **30 segundos:** Un criterio de asignación que manda siempre la misma operación por la misma ruta, por ejemplo por identificador de pedido, incluidas sus consultas, reintentos y cancelaciones.

🗣️ **2 minutos:** Si la reserva de un pedido se crea en la ruta local y su cancelación llega por la remota, la cancelación busca una reserva que no existe allí y el stock queda retenido. La cohorte estable garantiza que toda la vida de la operación la gestiona un solo escritor. Por eso se asigna por entidad y no por petición.

🔬 **El detalle:** Asignar por usuario o por porcentaje aleatorio de peticiones rompe esa propiedad en cuanto una operación tiene varios pasos.

### 7. 🟡 ¿Por qué no se elige como primera costura el componente más pequeño o el más fácil?

⏱️ **30 segundos:** Porque la primera costura debe atacar el coste más alto, y el componente más pequeño rara vez es el que obliga a coordinar.

🗣️ **2 minutos:** El valor de la remediación se mide en cambios que dejan de necesitar coordinación. Si el 93 % de los cambios de reservas cruza `orders` e `inventory`, esa frontera es la que conviene tocar primero, aunque sea más difícil que mover `notifications`. Elegir lo fácil produce una victoria visible y ningún efecto en el trabajo diario.

🔬 **El detalle:** El riesgo también cuenta: si la costura de mayor impacto es demasiado arriesgada para empezar, se elige una de impacto alto y riesgo acotado, no la trivial.

### 8. 🟡 ¿Qué evidencia de la sección 3 justifica fusionar `orders` e `inventory` y no el resto?

⏱️ **30 segundos:** Que casi todos los cambios de reservas cruzan los dos componentes, que ambos escriben la misma tabla, que los opera el mismo equipo con el mismo release y que ninguno necesita escalar aparte.

🗣️ **2 minutos:** Esa combinación dice que la frontera cuesta red, coordinación y una falsa transacción sin comprar nada a cambio. El resto de componentes no muestra la misma combinación —`payments` depende de un proveedor externo y `notifications` puede salir del camino síncrono—, así que merece otra remediación, no la misma fusión.

🔬 **El detalle:** Fusionar todo porque una frontera sobraba repetiría el error de dividir todo porque una frontera faltaba.

### 9. 🟡 ¿Por qué meter dos procesos en el mismo contenedor no recupera la transacción?

⏱️ **30 segundos:** Porque la transacción la da una conexión compartida a la base con un único límite transaccional, no la cercanía física de los procesos.

🗣️ **2 minutos:** Dos procesos en el mismo contenedor siguen llamándose por la red local, cada uno con su pool y su transacción; un fallo entre ambos deja pedido sin reserva igual que antes. Para recuperar la atomicidad, la reserva tiene que ejecutarse dentro del proceso de `orders`, con la misma conexión y el mismo `COMMIT`.

🔬 **El detalle:** Además hace falta que ambos datos estén en la misma base; con dos bases, ni siquiera un proceso único da atomicidad sin 2PC.

### 10. 🟡 ¿Por qué no conviene cambiar protocolo, base y organización en el mismo paso?

⏱️ **30 segundos:** Porque si algo empeora, no se sabrá cuál de los tres cambios lo causó, y revertir uno solo puede no bastar.

🗣️ **2 minutos:** Cambiar de HTTP a llamada local, mover tablas y reorganizar equipos a la vez produce tres variables en un experimento. Una regresión de latencia puede venir del nuevo acceso a datos o de la ruta; un aumento de incidentes, del equipo que aún no conoce el código. Un paso por vez permite atribuir y revertir con precisión.

🔬 **El detalle:** Es la misma disciplina que en un experimento de rendimiento: se cambia una variable y se mantiene fijo lo demás.

### 11. 🟡 ¿Qué pierde el sistema al fusionar dos componentes, y cuándo esa pérdida importa?

⏱️ **30 segundos:** Pierde aislamiento de fallos y de recursos, y la posibilidad de desplegar y escalar esas capacidades por separado.

🗣️ **2 minutos:** Un bug de memoria en `inventory` puede tumbar ahora también a `orders`, y un despliegue de uno arrastra al otro. Esa pérdida importa si las capacidades tienen cargas muy distintas, requisitos de aislamiento o equipos con cadencias propias; en el caso de la sección 3 no importa, porque ya se desplegaban juntas y nunca escalaron aparte.

🔬 **El detalle:** Parte del aislamiento se recupera dentro del proceso con cupos de recursos por módulo, sin volver a pagar red.

### 12. 🟡 ¿Cuándo separar de verdad es mejor salida que fusionar?

⏱️ **30 segundos:** Cuando la frontera compra algo medible: un equipo con otra cadencia, una carga que exige escalar aparte o un aislamiento que el proceso compartido no da.

🗣️ **2 minutos:** En ese caso la remediación es hacer real la independencia: un escritor por dato, contrato que tolere versiones mixtas, cadena más corta y estados inciertos modelados. Cuesta compatibilidad temporal, contratos y guardia propia, pero conserva lo que la frontera sí aportaba. Fusionar ahí destruiría un beneficio para ahorrar un coste.

🔬 **El detalle:** La prueba es que, tras la remediación, ese componente se despliegue solo con regularidad; si no ocurre, la ventaja era teórica.

### 13. 🟡 ¿Qué debe hacer la fachada transitoria y qué no debe hacer?

⏱️ **30 segundos:** Ofrecer a los llamadores un contrato estable y decidir por cohorte si la operación va a la ruta vieja o a la nueva; no debe contener reglas de negocio.

🗣️ **2 minutos:** La fachada es andamio: enruta, registra qué ruta sirvió cada operación y permite comparar lecturas. Si empieza a validar, transformar o decidir reservas, se convierte en otro componente con lógica y sin dueño, que es justo el problema que se estaba desmontando. Tiene fecha de retirada desde el principio.

🔬 **El detalle:** Un contador de uso por ruta es parte mínima de la fachada: sin él, no se sabe cuándo la ruta vieja ya no tiene tráfico y puede retirarse.

### 14. 🟡 ¿Cómo mantienes un solo escritor por operación mientras conviven dos rutas?

⏱️ **30 segundos:** Asignando cada operación a una sola ruta por cohorte estable, y comparando en sombra solo lecturas o cálculos sin efectos.

🗣️ **2 minutos:** En cada momento, la reserva de un pedido la escribe la ruta local o la remota, nunca las dos. La ruta que no escribe puede calcular el resultado para compararlo, pero no reserva ni libera. Así, si las implementaciones discrepan, se ve la diferencia sin haber duplicado ni perdido stock.

🔬 **El detalle:** Escribir en las dos rutas «para comparar» es un dual write: cualquier fallo entre ambas deja dos verdades y ninguna autoridad.

### 15. 🟡 ¿Cómo cambia la remediación cuando el acoplamiento viaja por un broker?

⏱️ **30 segundos:** El orden es el mismo; cambian los objetos: comandos disfrazados, entidades publicadas y procesos sin dueño en lugar de llamadas y tablas.

🗣️ **2 minutos:** Un `ReserveInventoryRequested` con espera de respuesta se convierte en una llamada honesta o en un estado pendiente; un `OrderUpdated` con 43 campos se sustituye por hechos mínimos versionados; y la compra recibe un dueño que conoce su estado. La librería común de eventos, si obliga a desplegar juntos, se trata como un contrato frágil más.

🔬 **El detalle:** Volver a HTTP no es la remediación por defecto: lo es solo para lo que el cliente necesita saber antes de la respuesta.

### 16. 🟡 ¿Por qué la propuesta de reescribirlo todo durante dos trimestres es arriesgada aunque el destino sea correcto?

⏱️ **30 segundos:** Porque congela el negocio durante meses, no entrega valor hasta el final y no permite saber qué parte del cambio aportaba.

🗣️ **2 minutos:** Mientras se reescribe, el sistema viejo sigue cambiando o se congela; en ambos casos el destino llega desfasado. Además, reescribir todo junto no distingue qué fronteras sobraban y cuáles compraban algo, así que puede repetir los cortes equivocados. Una costura por vez entrega mejoras medibles y permite corregir el rumbo.

🔬 **El detalle:** La reescritura completa también pierde el comportamiento no documentado del legado, que solo aparece cuando un cliente lo echa en falta.

### 17. 🟡 ¿Cómo comprobarías, en Java y en Go, que la fusión no borró los límites entre módulos?

⏱️ **30 segundos:** En Java, con una prueba arquitectónica que prohíba a `orders` depender de los paquetes internos de `inventory`; en Go, con el directorio `internal/` que el compilador hace cumplir.

🗣️ **2 minutos:** La diferencia es quién aplica la regla. En Java, un subpaquete no hereda privacidad y hace falta ArchUnit, Spring Modulith o JPMS para que el build falle. En Go, un import de `inventory/internal/...` desde `orders` no compila. En los dos casos se provoca a propósito una violación para comprobar que el control la detecta.

🔬 **El detalle:** Ninguno de los dos controla el SQL: las escrituras cruzadas a tablas se vigilan con permisos de base o revisando el acceso a datos.

### 18. 🟠 ¿Qué riesgo comparten reutilizar tipos remotos en Node/TypeScript e imports directos en Python después de fusionar?

⏱️ **30 segundos:** Los dos borran el límite desde dentro: el modelo remoto se vuelve modelo interno y los internos de un módulo se vuelven API de otro.

🗣️ **2 minutos:** Tras fusionar, en TypeScript es tentador seguir usando los tipos generados del contrato HTTP como modelo de `inventory`, y en Python importar directamente sus clases internas porque ya están en el mismo paquete. En ambos casos el siguiente cambio de un módulo rompe al otro, y lo que era un monolito distribuido pasa a ser una bola de barro local.

🔬 **El detalle:** Las dos se evitan igual: un `index.ts` o un `__init__.py` que publique solo la API, y una regla de imports en CI.

### 19. 🟠 ¿Cómo abortas la migración antes de transferir la escritura a la ruta local?

⏱️ **30 segundos:** Cambiando la ruta de vuelta a la implementación remota: mientras la escritura no se transfirió, la ruta vieja sigue siendo la autoridad y no hay datos que devolver.

🗣️ **2 minutos:** Antes de la transferencia, la ruta local solo leía o calculaba en sombra. Abortar es devolver las cohortes a la ruta remota y revisar por qué discrepaban. Es el tramo barato de la migración, y por eso conviene alargarlo hasta tener confianza en la implementación nueva.

🔬 **El detalle:** Conviene ensayar el aborto al menos una vez antes de necesitarlo: un procedimiento que nunca se probó no es un plan de vuelta.

### 20. 🟠 ¿Cómo abortas después de transferir la escritura, cuando la ruta nueva ya tiene datos?

⏱️ **30 segundos:** Devolviendo a la ruta vieja también las operaciones escritas en la nueva, o declarando recuperación hacia adelante si eso no se ensayó.

🗣️ **2 minutos:** Tras transferir la escritura, la ruta local tiene reservas que la remota desconoce. Cambiar solo el router las perdería o las duplicaría. Hay que sincronizar o reconciliar esas reservas, verificar compatibilidad y solo entonces cambiar la ruta. Si ese camino no está ensayado, lo honesto es no llamarlo rollback y corregir hacia adelante con una pausa segura.

🔬 **El detalle:** Por eso la transferencia de escritura se hace por cohortes pequeñas: el volumen a devolver en caso de aborto queda acotado.

### 21. 🟠 Tras la fusión baja la latencia de checkout, pero suben los incidentes que afectan a todo el proceso. ¿Qué haces?

⏱️ **30 segundos:** Contener el radio de fallo dentro del proceso y medir si los incidentes son nuevos o solo más visibles, antes de plantearse deshacer la fusión.

🗣️ **2 minutos:** Primero clasifico los incidentes: si un módulo agota memoria o conexiones y arrastra al otro, pongo cupos por módulo, límites de lote o pools separados. Si los incidentes venían de antes y ahora se atribuyen a un solo proceso, no empeoró nada. Solo si el aislamiento interno no alcanza y el coste supera a la latencia ganada, reconsidero separar.

🔬 **El detalle:** La latencia y los incidentes se comparan con la línea base; una mejora en una métrica y una regresión en otra se deciden con el SLO del flujo, no por preferencia.

### 22. 🟠 El arquitecto insiste en dividir `orders` en tres servicios y el equipo de `inventory` pide fusionar. ¿Cómo resuelves la discusión?

⏱️ **30 segundos:** Con la evidencia de la línea base: qué cambios cruzan qué fronteras y qué compra cada una.

🗣️ **2 minutos:** Pido al arquitecto qué problema resuelven los tres servicios nuevos y en qué cambios reales se vería; y al equipo de `inventory`, los cambios que cruzan la frontera actual. Si 14 de 15 cambios cruzan `orders` e `inventory` y nada escala aparte, la fusión gana; si `orders` contiene tres capacidades con equipos y ritmos distintos, dividirlo puede ser correcto después.

🔬 **El detalle:** Las dos propuestas no son excluyentes: fusionar `inventory` en `orders` y, más adelante, dividir `orders` por capacidades es coherente si la evidencia lo sostiene.

### 23. 🟠 La fachada transitoria se convierte en un cuello de botella y en un componente más que operar. ¿Qué harías?

⏱️ **30 segundos:** Retirarla antes: una fachada que ya es cuello de botella indica que la transición se alargó más de lo previsto.

🗣️ **2 minutos:** Reviso el contador de uso por ruta. Si casi todo el tráfico ya va a la ruta nueva, cierro las últimas cohortes y elimino la fachada; si no, reduzco su responsabilidad a enrutar y la saco del camino crítico de las operaciones que ya migraron. Lo que no hago es invertir en escalar un andamio.

🔬 **El detalle:** Una fachada que crece suele ser síntoma de que alguien le añadió lógica; esa lógica tiene que volver a su módulo dueño antes de retirarla.

### 24. 🟠 ¿Qué resultado, y medido cómo, demuestra que la remediación funcionó y se puede detener?

⏱️ **30 segundos:** Que los cambios de la capacidad dejan de necesitar coordinación, medido sobre cambios reales posteriores y comparado con la línea base, sin empeorar SLO ni incidentes.

🗣️ **2 minutos:** Por ejemplo: los siguientes diez cambios de reservas tocan un componente en lugar de dos, salen sin esperar a otro equipo y checkout mantiene su latencia y disponibilidad. Con eso se detiene la remediación de esa frontera. Otra migración solo empieza si otra frontera muestra el mismo patrón de coste sin beneficio.

🔬 **El detalle:** El número de servicios que quedan no es parte del criterio: una remediación exitosa puede terminar con más, menos o los mismos procesos.

## 🎤 Respuestas de la simulación

### S1. 🟢 ¿Qué evidencia combina un diagnóstico de monolito distribuido?

⏱️ **30 segundos:** Evidencia recurrente en varias monedas —cambios que cruzan componentes, datos sin dueño, releases obligatoriamente conjuntos, cadenas obligatorias y coordinación entre equipos— y ningún beneficio que la compense.

🗣️ **2 minutos:** Ninguna señal basta sola: una base compartida puede tener dueños claros y una cadena síncrona puede ser una garantía necesaria. El diagnóstico se sostiene siguiendo cambios reales y viendo que el patrón se repite, y que ningún componente escala ni se despliega por su cuenta. Sin esa recurrencia, es una concesión puntual.

🔬 **El detalle:** La evidencia se ordena por moneda porque la remediación empieza por la dominante, no por la más visible.

### S2. 🟢 ¿Qué es acoplamiento temporal?

⏱️ **30 segundos:** La dependencia en el tiempo: si el otro componente no está disponible ahora, tú tampoco puedes completar la operación.

🗣️ **2 minutos:** Una llamada síncrona obligatoria es la forma más directa: la disponibilidad del flujo es, como mucho, el producto de la de sus partes. Es un precio correcto cuando la respuesta cambia lo que se promete al cliente, como el stock; es un precio sin compra cuando no, como un aviso por correo en el camino de checkout.

🔬 **El detalle:** Un broker puede diferirlo sin eliminarlo: si el resultado de negocio necesita a todos, el retraso del consumidor se vuelve latencia del flujo.

### S3. 🟢 ¿Qué indica un timeout remoto?

⏱️ **30 segundos:** Que se perdió la respuesta dentro del plazo; no dice si la operación se ejecutó.

🗣️ **2 minutos:** El proveedor pudo autorizar después de que venciera la espera, o no haber recibido nunca la petición. Por eso un timeout sobre una operación con efecto se registra como `PENDING` con su clave y se consulta, en lugar de tratarse como fallo y reintentar con otra identidad.

🔬 **El detalle:** En operaciones de solo lectura el timeout es barato de reintentar; la incertidumbre importa cuando hay un efecto que no se puede repetir.

### S4. 🟢 ¿Qué significa compatibilidad entre releases?

⏱️ **30 segundos:** Que versiones distintas de productor y consumidor pueden convivir en producción sin romperse, en los dos sentidos.

🗣️ **2 minutos:** Durante un despliegue y mientras se retengan mensajes, conviven lectores viejos con escritores nuevos y al revés. La compatibilidad exige cambios aditivos, lectores tolerantes y retirada gobernada de lo viejo. Es lo que permite que cada componente salga cuando le toca en lugar de en un release conjunto.

🔬 **El detalle:** Se demuestra probando combinaciones reales de versiones desplegadas, no afirmando que el cambio «debería» ser compatible.

### S5. 🟡 ¿Cómo aproximas disponibilidad de una cadena?

⏱️ **30 segundos:** Multiplicando la disponibilidad de los componentes obligatorios, bajo el supuesto de fallos independientes: cinco al 99,9 % dan cerca de 99,5 %.

🗣️ **2 minutos:** Es una estimación optimista y útil para mostrar que una cadena larga no puede tener la disponibilidad de su mejor pieza. Con fallos correlacionados —misma base, misma red, mismo despliegue— el producto deja de valer y hay que medir el flujo completo. Sirve para decidir qué saltos quitar del camino obligatorio.

🔬 **El detalle:** Los percentiles de latencia no se combinan igual: no se suman los p95 de cada salto para obtener el del flujo.

### S6. 🟡 ¿Cómo repartes un timeout budget?

⏱️ **30 segundos:** El presupuesto nace en el borde con lo que el usuario puede esperar y cada salto recibe lo que queda, descontando margen para colas y respuesta.

🗣️ **2 minutos:** Si el cliente espera 900 ms, `orders` recibe unos 800, reparte entre `inventory` y `payments` según su papel y deja `notifications` fuera del camino. El deadline se propaga para que cada dependencia sepa cuánto le queda y abandone a tiempo. Timeouts fijos de cinco segundos por cliente destruyen ese presupuesto.

🔬 **El detalle:** Propagar el deadline solo libera trabajo si cada dependencia respeta la cancelación; si no, sigue gastando recursos después de que el cliente se fue.

### S7. 🟡 ¿Qué es una tormenta de retries?

⏱️ **30 segundos:** La multiplicación de intentos cuando varias capas reintentan a la vez sobre una dependencia que ya está degradada.

🗣️ **2 minutos:** Si gateway, `orders` y el cliente HTTP hacen tres reintentos cada uno, una sola petición puede generar hasta 27 llamadas a `payments` justo cuando peor responde. La carga extra impide que se recupere. Se evita reintentando en una sola capa, con backoff, jitter y límite, y cortando con un circuit breaker.

🔬 **El detalle:** La tormenta suele empezar por un fallo pequeño; sin control de reintentos, el sistema la convierte en una caída completa.

### S8. 🟡 ¿Cuándo una API resulta chatty?

⏱️ **30 segundos:** Cuando un caso de uso necesita muchas llamadas pequeñas a otro componente para obtener lo que podría pedir en una.

🗣️ **2 minutos:** Una página de producto que llama 40 veces a `inventory` para mostrar disponibilidad multiplica latencia y puntos de fallo. Se corrige con una consulta agregada, una proyección local de lectura o, si la granularidad es el problema, revisando el corte. Suele ser síntoma de servicios demasiado finos.

🔬 **El detalle:** Una API chatty entre procesos es barata dentro de un monolito y cara en red: el mismo diseño cambia de coste al distribuirlo.

### S9. 🟡 ¿Qué añade una proyección local?

⏱️ **30 segundos:** Disponibilidad y lectura propias para un dato de otro, a cambio de duplicación, retraso y reconciliación.

🗣️ **2 minutos:** En lugar de llamar a `inventory` en cada petición, un consumidor mantiene su copia alimentada por eventos y deja de depender de él en runtime. El contrato declara frescura, versión y cómo se repara una divergencia. No sirve para decisiones que exigen el dato exacto, como reservar el último stock.

🔬 **El detalle:** La proyección convierte acoplamiento temporal en consistencia eventual; esa conversión tiene que aceptarla el negocio, no solo el equipo técnico.

### S10. 🟡 ¿Por qué permisos importan al recuperar ownership?

⏱️ **30 segundos:** Porque convierten el dueño acordado en una regla que la base hace cumplir: sin ellos, cualquier credencial puede seguir escribiendo.

🗣️ **2 minutos:** Declarar que `payments` es dueño de `authorizations` no impide que `orders` siga con su `UPDATE`. Revocar la escritura a las demás credenciales hace visible cualquier camino olvidado —un job, un script— y garantiza un solo escritor. Se revoca después de migrar los consumidores a comandos, nunca antes.

🔬 **El detalle:** Los permisos no descubren al dueño: esa decisión es de negocio y de equipos; los permisos solo la aplican.

### S11. 🟡 ¿Qué protege un contrato de consumidor?

⏱️ **30 segundos:** Que el proveedor sigue entregando lo que un consumidor concreto usa del contrato, ejecutado en la CI del proveedor antes de desplegar.

🗣️ **2 minutos:** El consumidor declara sus expectativas mínimas y el proveedor no puede romperlas sin enterarse. Protege contra cambios de forma y contra retiradas prematuras de campos. No protege disponibilidad, seguridad ni rendimiento, y solo sirve si se prueban las versiones desplegadas del consumidor.

🔬 **El detalle:** Si las expectativas copian la respuesta completa, el contrato se congela y el proveedor pierde la libertad que se buscaba.

### S12. 🟡 ¿Qué riesgo añade un nuevo valor de estado?

⏱️ **30 segundos:** Que los consumidores que no lo conocen lo rechacen o tomen una decisión equivocada con él.

🗣️ **2 minutos:** Un lector estricto falla al deserializar un estado nuevo; uno con un `switch` sin rama por defecto falla al procesarlo; y uno que lo trata como otro valor conocido decide mal, por ejemplo confirmando un pago parcial como completo. Se mitiga con lectores tolerantes, política explícita para desconocidos y anuncio del valor antes de emitirlo.

🔬 **El detalle:** En un replay, el valor nuevo puede llegar a consumidores que nunca se actualizaron; por eso la política de desconocidos es parte del contrato.

### S13. 🟡 ¿Qué conecta outbox e inbox?

⏱️ **30 segundos:** La outbox publica de forma fiable lo que el productor confirmó; la inbox deduplica en el consumidor lo que llega repetido. Juntas dan efecto único local con entrega *at-least-once*.

🗣️ **2 minutos:** La outbox guarda estado y mensaje en la misma transacción y admite reenvíos; la inbox registra cada mensaje con su efecto en la transacción del consumidor y descarta repetidos. Entre las dos cubren caídas del publicador y *acks* perdidos. Lo que no cubren es un efecto externo del consumidor, que necesita su propia clave.

🔬 **El detalle:** Ambas necesitan un identificador de mensaje estable desde el origen; si se genera al publicar, cada reenvío parece un mensaje nuevo.

### S14. 🟡 ¿Qué diferencia saga y rollback local?

⏱️ **30 segundos:** El rollback local deshace escrituras no confirmadas de una base; una saga coordina pasos ya confirmados en varios sistemas y los neutraliza con compensaciones que pueden fallar.

🗣️ **2 minutos:** En una saga, cada paso hace commit en su propio sistema; si un paso posterior falla, se ejecutan operaciones compensatorias, como anular una autorización. Esas compensaciones dejan rastro, llegan tarde y necesitan reintentos y revisión. Por eso una saga requiere estado visible y un dueño del proceso.

🔬 **El detalle:** Llamar rollback a una compensación esconde que puede fallar, que es justo donde se acumulan los incidentes.

### S15. 🟡 ¿Qué métrica demuestra menor lockstep?

⏱️ **30 segundos:** El porcentaje de releases que obligatoriamente requieren otro release, comparado antes y después de la remediación.

🗣️ **2 minutos:** Que haya más despliegues no demuestra menos lockstep si cada uno arrastra a otros. Lo que importa es cuántas salidas ocurren solas sin romper a nadie, cuánto espera un cambio por otro equipo y cuántos fallos vienen de versiones mixtas. Esa métrica se toma sobre cambios reales, no sobre la política declarada.

🔬 **El detalle:** Un release train voluntario puede coexistir con componentes capaces de salir solos; se prueba intentándolo.

### S16. 🟡 ¿Cuándo fusionarías componentes?

⏱️ **30 segundos:** Cuando la frontera no compra nada medible: cambian siempre juntos, los opera el mismo equipo, salen juntos y pagan red y falsas transacciones.

🗣️ **2 minutos:** Si pedido y reserva cruzan la frontera en casi todos los cambios y necesitan una transacción, fusionar su despliegue recupera la atomicidad y quita saltos. Se conservan módulos, APIs internas y dueños de tablas para no perder el límite de código. Se paga radio de fallo común y despliegue compartido.

🔬 **El detalle:** Si uno de los dos necesita escalar aparte o pertenece a otro equipo, la fusión destruye un beneficio real y la salida es separarlos de verdad.

### S17. 🟡 ¿Cómo comparas DTO Java y validación Node en contratos?

⏱️ **30 segundos:** Los dos protegen la frontera si validan lo que llega: el DTO de Java lo hace al deserializar, según su configuración; en Node hay que validar en runtime porque los tipos desaparecen.

🗣️ **2 minutos:** En Java, un DTO con un deserializador bien configurado rechaza tipos incorrectos e ignora campos desconocidos si así se decide. En Node, una interfaz TypeScript no comprueba nada y un cast acepta cualquier objeto; la validación con un esquema al recibir cumple el papel del DTO. En ambos, exportar el modelo interno como contrato es la trampa común.

🔬 **El detalle:** La política ante campos desconocidos es una decisión de compatibilidad, no un detalle de la librería.

### S18. 🟡 ¿Qué comparten Go y Python ante un timeout?

⏱️ **30 segundos:** Que el final de la espera no dice nada del resultado remoto: cancelar un contexto en Go o capturar una excepción en Python no deshace lo que el otro ejecutó.

🗣️ **2 minutos:** En los dos casos, la operación con efecto queda en `PENDING` con su clave y se consulta después. El error típico es reintentar con una clave nueva porque «falló», lo que convierte un timeout en un doble efecto. Go libera recursos locales al cancelar; Python puede haber recibido la respuesta a medias.

🔬 **El detalle:** El timeout debe caber en el presupuesto del flujo; si no, la cancelación llega cuando el cliente ya abandonó.

### S19. 🟡 ¿Qué criterio prioriza una remediación?

⏱️ **30 segundos:** El impacto en cambios y en el cliente, ajustado por riesgo: primero la moneda que más coordinación causa y que puede tocarse con un paso reversible.

🗣️ **2 minutos:** Con la línea base se ve qué frontera cruzan más cambios y qué incidentes duelen más. Se elige esa costura si se puede cambiar por cohortes y revertir; si es demasiado arriesgada, una de impacto alto y riesgo acotado. El componente más pequeño o el más fácil rara vez es el que libera más coordinación.

🔬 **El detalle:** Dentro de la costura elegida, el orden sigue siendo datos, contrato, cadena y release.

### S20. 🟡 ¿Qué debes conservar durante coexistencia de rutas?

⏱️ **30 segundos:** Un solo escritor por operación, un contrato estable para los llamadores y la capacidad de volver atrás mientras no se transfiera la escritura.

🗣️ **2 minutos:** Mientras conviven la ruta vieja y la nueva, cada operación se asigna por cohorte estable a una sola ruta, también para consultas y cancelaciones. La otra ruta solo compara lecturas en sombra. La fachada enruta y cuenta uso, sin reglas de negocio, y tiene fecha de retirada.

🔬 **El detalle:** Escribir en las dos rutas para comparar es un dual write: crea dos verdades en cuanto algo falla entre ambas.

### S21. 🟡 ¿Cómo distinguirías, en una entrevista, un sistema con broker que desacopla de uno que solo cambió el transporte?

⏱️ **30 segundos:** Por lo que pasa cuando un consumidor se detiene y cuando el productor cambia su esquema: si checkout falla o todos tienen que desplegar, solo cambió el transporte.

🗣️ **2 minutos:** Pediría ver un flujo: qué espera el productor antes de responder, qué contiene el evento y quién es dueño del proceso. Un comando con respuesta esperada, una entidad publicada y una librería común de eventos son las tres señales de que el acoplamiento sigue, con otra forma. Hechos versionados, consumidores con proyección propia y un dueño del estado son las de autonomía.

🔬 **El detalle:** La pregunta de control es sencilla: «si detengo este consumidor una hora, ¿qué le pasa al cliente?».

### S22. 🟡 ¿Qué relación hay entre un servicio por entidad y una cadena síncrona larga?

⏱️ **30 segundos:** El servicio por entidad deja las decisiones en quien llama, y quien llama necesita varios servicios de datos para cada caso de uso: la cadena es la consecuencia del corte.

🗣️ **2 minutos:** Crear un pedido necesita cliente, producto, precio y stock; con un servicio por entidad son cuatro llamadas desde `order-service`. Recortar la cadena sin cambiar el corte solo mueve las llamadas a otro lado. Agrupar por capacidad reduce las colaboraciones porque pone la decisión junto a su dato.

🔬 **El detalle:** Por eso el origen del corte aparece en la remediación: tratar la cadena como problema de resiliencia deja intacta su causa.

### S23. 🟡 ¿Qué preguntarías sobre la librería `commons` antes de diagnosticar un monolito distribuido?

⏱️ **30 segundos:** Qué contiene —plataforma o dominio—, cada cuánto cambia por razones de negocio y si sus actualizaciones obligan a desplegar a todos juntos.

🗣️ **2 minutos:** Una librería de transporte y logging estable es plataforma sana. Una con entidades y validadores que cambia con cada regla de negocio es evidencia en las monedas de código y despliegue. Pido el historial de versiones y cuántos servicios se desplegaron por cada una.

🔬 **El detalle:** Es evidencia parcial como cualquier otra: combinada con cambios cruzados y releases conjuntos sostiene el diagnóstico; sola, no.

### S24. 🟡 ¿Cuándo el retraso de un consumidor es un problema de negocio y cuándo no?

⏱️ **30 segundos:** Es un problema cuando el consumidor forma parte del resultado que el cliente espera, como la autorización del pago; no lo es para reacciones prescindibles, como analítica.

🗣️ **2 minutos:** Veinte minutos de retraso en analítica no cambian ninguna promesa; en `payments`, dejan pedidos sin confirmar. Cada consumidor se clasifica por su papel en el flujo y recibe un objetivo de lag acorde, con alerta en los que afectan al cliente.

🔬 **El detalle:** Clasificar consumidores así también dice cuáles deberían tener un dueño del proceso vigilándolos.

### S25. 🟡 ¿Cómo afecta la estructura de equipos a la remediación de un monolito distribuido?

⏱️ **30 segundos:** Si los equipos siguen organizados por capa técnica, cualquier nuevo corte por capacidad tenderá a erosionarse, porque cada cambio seguirá cruzando equipos.

🗣️ **2 minutos:** La remediación incluye revisar quién decide y opera cada capacidad. Un piloto con un equipo alineado a una capacidad muestra si los cambios se quedan dentro. Mover límites de código sin mover responsabilidades deja la coordinación donde estaba.

🔬 **El detalle:** La ley de Conway no obliga a reorganizar todo de golpe, pero sí a incluir a los equipos en el plan.

### S26. 🟠 ¿Los eventos eliminan cualquier cadena temporal?

⏱️ **30 segundos:** No: eliminan la espera inmediata, pero si el resultado de negocio necesita a todos los consumidores, la dependencia temporal sigue, diferida.

🗣️ **2 minutos:** El productor responde sin esperar, pero la compra no termina hasta que `inventory` y `payments` procesan sus mensajes; el retraso de un consumidor es ahora latencia del flujo y pedidos en `PENDING`. Si además el productor espera una respuesta en otro tópico, es una llamada síncrona con más piezas. Lo que desacopla es que el resultado no dependa de quien reacciona.

🔬 **El detalle:** La prueba es detener un consumidor una hora: si el cliente lo nota, la cadena sigue ahí.

### S27. 🟠 ¿Versionar una URL vuelve independiente al proveedor?

⏱️ **30 segundos:** No: da nombre a dos contratos, pero sin retirada gobernada ni lectores tolerantes, el proveedor sigue atado a sus consumidores.

🗣️ **2 minutos:** Con `/v2`, el proveedor mantiene dos implementaciones mientras nadie sepa quién usa la vieja ni cuándo se retira. La independencia viene de cambios aditivos, telemetría de uso por versión y pruebas de consumidor contra lo desplegado. Y los eventos no tienen URL: su evolución necesita la misma disciplina.

🔬 **El detalle:** Versionar la URL es útil para cambios realmente incompatibles; no sustituye la ventana de convivencia ni la retirada.

### S28. 🟠 ¿Dos bases eliminan escrituras cruzadas?

⏱️ **30 segundos:** No: si no hay un dueño acordado, las escrituras cruzadas se convierten en dual writes o en sincronizaciones entre bases.

🗣️ **2 minutos:** Separar las tablas de `orders` y `payments` en dos bases no quita la necesidad de que uno cambie el estado del otro; solo la mueve a la red, sin transacción. Primero se asigna el dueño, se migran las escrituras ajenas a comandos y se revocan permisos. La separación física llega después, si compra algo.

🔬 **El detalle:** Una base compartida con un escritor por tabla puede ser el estado final; dos bases con propiedad difusa no lo son.

### S29. 🟠 ¿2PC resuelve por defecto el pago externo?

⏱️ **30 segundos:** No: un proveedor externo no participa en tu protocolo de dos fases, y 2PC retiene recursos mientras decide.

🗣️ **2 minutos:** Para 2PC hace falta que todos los participantes sepan preparar y confirmar bajo un coordinador común; una API de pagos por HTTP no lo ofrece. La herramienta correcta es persistir la intención con una clave, llamar fuera de la transacción, modelar el pendiente y reconciliar por clave con plazo y revisión.

🔬 **El detalle:** Incluso entre bases propias, 2PC acopla la disponibilidad de todas: si una no responde, las demás esperan.

### S30. 🟠 ¿Menos servicios siempre significa menos acoplamiento?

⏱️ **30 segundos:** No siempre: menos servicios reduce saltos, pero una fusión sin módulos puede crear una bola de barro local igual de acoplada.

🗣️ **2 minutos:** El acoplamiento se mide en cambios, datos, despliegue, runtime y equipos, no en número de procesos. Fusionar dos componentes que cambian juntos lo reduce; fusionar todo sin conservar APIs internas y dueños de tablas lo traslada al código. Y separar puede reducirlo si la frontera compra cadencia o escala.

🔬 **El detalle:** La pregunta útil no es cuántos servicios, sino cuántos cambios cruzan fronteras y qué compra cada una.

### S31. 🟠 En E1, ¿cómo sostienes o rechazas el diagnóstico y eliges el primer cambio?

⏱️ **30 segundos:** Siguiendo cambios reales por las cinco monedas; si el patrón se repite y nada lo compensa, sostengo el diagnóstico y elijo como primer cambio la costura de mayor coordinación, reversible.

🗣️ **2 minutos:** Pediría el inventario de versiones, si el release semanal es obligatorio y qué cambios lo causan, y una traza representativa de checkout. Si casi todo cambio cruza componentes, los datos se comparten sin dueño y la cadena entera es obligatoria, el diagnóstico se sostiene. El primer cambio podría ser sacar `notifications` del camino síncrono o fusionar pedido y reserva, según la evidencia.

🔬 **El detalle:** La garantía que guía todo es que la compra termine completada o pendiente bajo un contrato claro; ningún cambio puede dejarla en un estado ambiguo.

### S32. 🟠 En E2, ¿cómo resolverías el ownership disputado?

⏱️ **30 segundos:** Resolviendo primero quién es dueño de la invariante monetaria, con negocio y los dos equipos, y después migrando escrituras y revocando permisos.

🗣️ **2 minutos:** Construyo la matriz de lectores y escritores con datos reales —credenciales, consultas, scripts—, acuerdo que `payments` valida cada cambio de autorización y ofrezco a `orders` un comando para lo que hoy hace con `UPDATE`. Migro consumidor por consumidor y revoco la escritura al final. No propongo dos bases hasta que haya un solo escritor.

🔬 **El detalle:** Si los equipos no se ponen de acuerdo, la decisión de propiedad escala a quien responde por el negocio; la arquitectura no la resuelve sola.

### S33. 🟠 En E3, ¿qué ve el usuario y cómo evitas otro cobro?

⏱️ **30 segundos:** El usuario ve su pedido en «pago en proceso» con su identificador; el reintento reutiliza la misma clave y se consulta al proveedor por ella en lugar de cobrar de nuevo.

🗣️ **2 minutos:** El pedido queda `PENDING`, no con error, para que el usuario no repita la compra. Si pulsa otra vez, la petición lleva la misma clave de intención y recibe el mismo estado. Un worker consulta al proveedor, confirma el pedido al conocer la autorización y avisa al cliente; si no se resuelve en plazo, pasa a revisión.

🔬 **El detalle:** Hay que alinear la duración de la reserva con el plazo de reconciliación para no confirmar un pago tardío sin stock.

### S34. 🟠 En E4, ¿cómo ejecutarías la fusión sin perder garantías?

⏱️ **30 segundos:** Por una fachada con ruta seleccionable y cohortes estables, conservando módulos y dueños de tablas, y verificando que pedido y reserva comparten conexión y transacción.

🗣️ **2 minutos:** Primero confirmo que los dos datos están en la misma base; si no, la fusión de procesos no da atomicidad. Después muevo la reserva al proceso de `orders` detrás de una fachada, por cohortes, con un solo escritor por operación. Mido latencia, incidentes y cambios; retiro la ruta remota al cerrar la reconciliación.

🔬 **El detalle:** El camino de vuelta hay que ensayarlo antes de transferir la escritura; después, revertir exige devolver también los datos.

### S35. 🟠 En E5, ¿qué harías antes de retirar el campo antiguo?

⏱️ **30 segundos:** Comprobar con telemetría que ningún consumidor desplegado lo lee y probar los lectores contra payloads históricos del horizonte de replay.

🗣️ **2 minutos:** Inventario los consumidores y sus versiones, ejecuto sus expectativas en la CI de `payments` y reproduzco mensajes retenidos contra los lectores nuevos. Verifico además que el significado se conserva: misma autorización, mismo importe. Solo con cero uso durante despliegue y retención, retiro el campo.

🔬 **El detalle:** Un formato válido no garantiza semántica compatible: un JSON que se deserializa bien puede seguir interpretándose mal.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [09 — Simulación de entrevista: Monolito distribuido](09-simulacion-de-entrevista.md).

**Siguiente:** [01 — Monolito, monolito modular o servicios: matriz de decisión](../05-decision-evolucion-y-practica/01-monolito-monolito-modular-o-servicios-matriz-de-decision.md).
