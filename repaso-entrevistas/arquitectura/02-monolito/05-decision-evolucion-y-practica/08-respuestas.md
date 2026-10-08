# 08 — Respuestas: Decisión, evolución y práctica

> Solucionario completo de los capítulos y de la simulación. Cada enunciado se conserva literalmente y cada respuesta usa tres capas.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--monolito-monolito-modular-o-servicios-matriz-de-decisión) · [02](#-02--diseñar-un-monolito-modular-desde-cero) · [03](#-03--recuperar-modularidad-en-un-monolito-legado) · [04](#-04--extraer-un-módulo-a-servicio) · [05](#-05--equipos-ownership-y-gobernanza-evolutiva) · [06](#-06--caso-completo-de-system-design-y-estrategia-evolutiva) · [Simulación](#-respuestas-de-la-simulación)

## 📖 01 — Monolito, monolito modular o servicios: matriz de decisión

### 1. 🟢 ¿Para qué sirve una matriz de decisión y por qué no suma puntos?

⏱️ **30 segundos:** Para comparar topologías bajo restricciones explícitas: primero descarta las que incumplen una restricción dura y después ordena por coste las que quedan.

🗣️ **2 minutos:** Sumar puntos permitiría que muchas ventajas menores compensaran una invariante incumplida, y eso no es aceptable: un sistema escalable que confirma pedidos sin reserva está mal. Por eso la matriz filtra y ordena en dos pasos, y deja por escrito qué supuesto sostiene cada fila.

🔬 **El detalle:** Su valor principal es hacer visibles los supuestos para discutirlos; el resultado es consecuencia de ellos, no de una fórmula.

### 2. 🟢 ¿Qué distingue una restricción de una preferencia?

⏱️ **30 segundos:** Una restricción invalida la solución que no la cumple; una preferencia solo la hace más o menos atractiva.

🗣️ **2 minutos:** «Pedido y reserva se confirman juntos» o «el auditor exige un control sobre los datos de pago» son restricciones, siempre que su dueño las confirme. «Queremos microservicios» o «preferimos este lenguaje» son preferencias. Tratar una preferencia como restricción cierra opciones sin motivo; tratar una restricción como preferencia produce un sistema incorrecto.

🔬 **El detalle:** Una restricción no confirmada es una hipótesis; se verifica con quien responde por ella antes de que decida el diseño.

### 3. 🟢 ¿Qué dato de carga pedirías primero, en lugar de usuarios registrados?

⏱️ **30 segundos:** El pico de operaciones por segundo de los flujos críticos y su distribución, además del recurso que se satura en ese pico.

🗣️ **2 minutos:** Un millón de usuarios registrados puede significar 40 compras por segundo o 4 000; lo que dimensiona es la operación concurrente, no el registro. También importa la forma: un SKU caliente en campaña o un pico de lecturas cambian la solución más que la media. Y la carga sola no decide topología: hay que ver qué recurso limita.

🔬 **El detalle:** Con el pico medido y el recurso limitante se puede estimar si bastan réplicas de un artefacto antes de hablar de servicios.

### 4. 🟢 ¿Qué aporta un monolito modular a la decisión frente a un monolito simple?

⏱️ **30 segundos:** Límites internos verificables dentro de una sola unidad de despliegue: se contienen los cambios sin pagar red, contratos remotos ni datos repartidos.

🗣️ **2 minutos:** Frente al monolito simple, añade módulos por capacidad con API interna, dueño de datos y controles en CI. Eso permite que dos equipos trabajen sin pisarse y deja preparada una frontera por si algún día hay que extraer. Cuesta disciplina y controles, que un equipo pequeño con un dominio incierto quizá aún no necesita.

🔬 **El detalle:** No es un paso obligatorio hacia servicios: puede ser el estado final si ninguna restricción pide más.

### 5. 🟢 ¿Qué es una *fitness function* en este contexto?

⏱️ **30 segundos:** Una comprobación repetible y automatizada de una propiedad arquitectónica que se quiere conservar, como que ningún módulo escriba tablas ajenas.

🗣️ **2 minutos:** Convierte parte de la decisión en algo vigilado: una regla de dependencias en CI, un test que falla si aparece un ciclo, una alerta si la cola supera un umbral. Así, la decisión no se erosiona en silencio con cada cambio. Pero cada función cubre una propiedad; no certifica que la arquitectura entera sea correcta.

🔬 **El detalle:** Conviene elegir pocas, ligadas a las garantías de la decisión; muchas funciones sin dueño terminan desactivadas.

### 6. 🟡 ¿Por qué una media de carga resulta insuficiente para decidir?

⏱️ **30 segundos:** Porque la topología se decide por el pico y por la forma de la carga, que la media esconde.

🗣️ **2 minutos:** Una media de 5 compras por segundo puede incluir una campaña de 40 y un SKU que concentra la mitad de las reservas. Ese SKU serializa escrituras sobre una fila aunque la CPU esté libre, y ningún número medio lo muestra. Se piden percentiles, picos por flujo y distribución por clave caliente.

🔬 **El detalle:** La pregunta útil es qué pasa en el peor minuto del año, no en un día normal.

### 7. 🟡 ¿Cuándo mantendrías una invariante dentro de una transacción local aunque haya presión por separar?

⏱️ **30 segundos:** Cuando el negocio confirma que la invariante debe cumplirse siempre y los datos viven en la misma base: la transacción local es la forma más barata de garantizarla.

🗣️ **2 minutos:** Separar pedido y reserva obliga a gestionar el estado intermedio con compensaciones, reconciliación y soporte. Si la presión por separar no viene de una restricción —cadencia, escala, aislamiento—, esa complejidad no compra nada. Mantengo la invariante local y registro qué requisito haría cambiar la decisión.

🔬 **El detalle:** Si negocio acepta cambiar la promesa, por ejemplo aceptar el pedido y confirmar el stock en segundos, la frontera puede moverse; es una decisión de negocio, no técnica.

### 8. 🟡 ¿Cómo cambia la decisión si dos equipos necesitan cadencias realmente distintas?

⏱️ **30 segundos:** Primero separo por módulos para que no se pisen en el código; solo si el release común bloquea de forma medida, les doy despliegues propios.

🗣️ **2 minutos:** Dos equipos con ritmos distintos no necesitan servicios de inmediato: módulos con dueños claros y un pipeline rápido suelen bastar. Si aun así el equipo de `payments` espera días por el release común, esa espera medida es una razón para otra unidad de despliegue, y entonces se paga compatibilidad y guardia propia.

🔬 **El detalle:** La cadencia hay que verificarla: a veces el bloqueo es un proceso de aprobación, no la topología.

### 9. 🟡 ¿Qué evidencia demostraría una necesidad real de aislamiento para `payments`?

⏱️ **30 segundos:** El control concreto que exige el auditor o el contrato, confirmado por escrito, y comprobar que la opción local no puede cumplirlo.

🗣️ **2 minutos:** «Separar los datos de pago» puede satisfacerse con permisos, cifrado, un esquema aparte o un entorno aislado con credenciales y despliegue propios. Solo el último obliga a otra unidad. Pido el texto del control, quién lo valida y cómo se audita; si el proceso compartido no lo cumple, el aislamiento pasa a ser restricción dura.

🔬 **El detalle:** También cuenta el aislamiento de fallos medido: si un incidente de otro módulo ha tumbado pagos con impacto grave, es evidencia de otro tipo.

### 10. 🟡 ¿Por qué no recomendarías servicios por la cifra de un millón de usuarios?

⏱️ **30 segundos:** Porque es una cifra de registro, no de carga, y no dice qué recurso se agota ni qué frontera lo resolvería.

🗣️ **2 minutos:** Pregunto por el pico de compras por segundo, la distribución y el recurso limitante. Con 40 compras por segundo medidas, varias réplicas de un artefacto sobran; si el cuello fuera la base, servicios no lo arreglarían. La cifra de usuarios sirve para planificar capacidad futura, no para elegir la topología de hoy.

🔬 **El detalle:** Si la dirección insiste, propongo una revisión con fecha y umbral: si la carga medida cruza un valor, se reabre la decisión.

### 11. 🟡 ¿Qué movimientos son reversibles y cuáles no, al cambiar de topología?

⏱️ **30 segundos:** Son reversibles una fachada, un worker del mismo artefacto o una regla en CI; son poco reversibles copiar datos a otra autoridad, publicar un contrato externo o asumir una guardia permanente.

🗣️ **2 minutos:** Priorizo los movimientos que se deshacen con un despliegue y aplazo los que crean compromisos con terceros o con datos. Una extracción comprometida con clientes externos o con una base nueva cuesta meses revertirla. Por eso las primeras acciones de una evolución suelen ser internas.

🔬 **El detalle:** La reversibilidad se prueba ensayando la vuelta atrás, no se supone por tener un botón de rollback.

### 12. 🟡 ¿Cuándo extraerías `notifications` a un servicio, y cuándo basta con un worker?

⏱️ **30 segundos:** Cuando la medición muestra que un worker del mismo artefacto no basta y el servicio aporta algo más: equipo propio, cadencia o aislamiento que el proceso compartido no da.

🗣️ **2 minutos:** El cuello de CPU en campaña se resuelve primero con `notifications` como worker con recursos propios, alimentado por una tabla de trabajo. Si eso contiene el problema, no hay nada más que comprar. Si además `notifications` tiene otro equipo, otro ritmo o proveedores con requisitos de aislamiento, extraerla puede compensar su coste.

🔬 **El detalle:** Si el cuello real está en una consulta compartida, mover CPU a otro proceso no cambia nada; por eso se mide antes.

### 13. 🟡 ¿Cómo afecta la frescura de datos permitida a la topología?

⏱️ **30 segundos:** Cuanto más atraso tolera el negocio, más fácil es separar con proyecciones o colas; si exige el dato exacto, conviene mantener el recurso junto.

🗣️ **2 minutos:** Un catálogo que puede mostrar stock con segundos de retraso admite una proyección en otro componente. Una reserva que no puede vender lo que no hay necesita leer y escribir el stock en el mismo sitio. La frescura permitida es, por tanto, una restricción de topología, y la decide negocio.

🔬 **El detalle:** La frescura se escribe en el contrato de la proyección, junto con cómo se detecta y repara una divergencia.

### 14. 🟡 ¿Qué debe incluir el registro de una decisión para que se pueda revisar?

⏱️ **30 segundos:** La hipótesis, la elección, la evidencia que falta, el experimento que la aportará, una fecha o umbral de revisión con responsable y la señal que obliga a reabrirla.

🗣️ **2 minutos:** Sin fecha ni señal, la decisión se reabre por cansancio o por moda. Con ellas, la conversación futura empieza por datos: se midió la cadencia de `payments`, se conoce el control de auditoría, el pico cambió o no. El registro también protege a quien decidió, porque deja claro qué sabía en su momento.

🔬 **El detalle:** Un registro de decisión que nadie consulta es papel; conviene revisarlo en la fecha acordada aunque no haya pasado nada.

### 15. 🟡 ¿Qué diferencia hay entre un worker separado y un servicio autónomo?

⏱️ **30 segundos:** Un worker comparte artefacto, versión, reglas y datos con el resto; un servicio autónomo tiene su propio despliegue, sus datos y su contrato.

🗣️ **2 minutos:** Un worker de `notifications` escala aparte y aísla CPU, pero sale en el mismo release y usa el mismo esquema: no crea contratos remotos ni datos repartidos. Un servicio tiene cadencia propia y autoridad sobre sus datos, y paga por ello compatibilidad, red y guardia. El worker es el paso barato cuando lo que falta es aislamiento de recursos.

🔬 **El detalle:** Varios procesos no son varios servicios: se cuentan unidades de despliegue y de autoridad, no procesos.

### 16. 🟡 ¿Qué alternativa considerarías antes de separar una base caliente?

⏱️ **30 segundos:** Optimizar la consulta, añadir índices o un read model, repartir la carga con réplicas de lectura o aislar el workload que la satura.

🗣️ **2 minutos:** Una base caliente suele tener una causa concreta: una consulta sin índice, reportes compitiendo con checkout, conexiones retenidas. Cada una se resuelve con un cambio local, reversible y medible. Separar la base mueve datos, rompe transacciones y crea sincronización; solo compensa si la causa es que dos capacidades con cargas incompatibles comparten el recurso.

🔬 **El detalle:** Si separar la base es la respuesta, primero se asignan dueños de escritura; sin eso, dos bases heredan el problema.

### 17. 🟠 ¿Aceptarías más latencia para ganar aislamiento? ¿Bajo qué condiciones?

⏱️ **30 segundos:** Sí, si el aislamiento es una restricción confirmada y la latencia añadida cabe en el presupuesto del flujo.

🗣️ **2 minutos:** Aislar `payments` en su propio proceso añade una llamada de red a checkout. Si el auditor lo exige o un incidente ajeno ya ha tumbado los pagos con coste grave, esa latencia compra algo real. Mido que el flujo siga dentro de su SLO; si no cabe, busco otra forma de aislamiento, como un entorno separado sin estar en el camino síncrono.

🔬 **El detalle:** Sacar la llamada del camino síncrono, con pago pendiente, puede recuperar la latencia a cambio de un estado intermedio visible.

### 18. 🟠 Dos requisitos confirmados son incompatibles entre sí. ¿Qué haces?

⏱️ **30 segundos:** Lo hago visible y llevo la decisión a quienes responden por cada requisito: la arquitectura no puede cumplir dos restricciones que se contradicen.

🗣️ **2 minutos:** Por ejemplo, «confirmación inmediata del pago» y «ningún pedido sin pago autorizado» con un proveedor lento no caben juntos sin degradar disponibilidad. Presento las opciones con su coste —latencia, pendiente visible, riesgo— y pido que negocio elija qué requisito cede y en qué medida. Registro la decisión.

🔬 **El detalle:** Muchas incompatibilidades desaparecen al precisar el requisito: «inmediato» suele admitir un pendiente de segundos.

### 19. 🟠 ¿Cómo defenderías mantener el monolito ante una dirección que quiere «modernizar»?

⏱️ **30 segundos:** Con la matriz: muestro qué restricción exigiría cambiar y que ninguna confirmada lo hace, y propongo una fecha y una señal para revisarlo.

🗣️ **2 minutos:** «Modernizar» no es una restricción; lo convierto en preguntas: qué problema de cambio, carga o aislamiento tenemos hoy y qué medida lo demuestra. Si no aparece, recomiendo el monolito modular con los cuellos acotados resueltos y dejo registrado qué dato reabriría la decisión. Así no es inmovilismo: es una decisión revisable.

🔬 **El detalle:** Ofrecer mejoras concretas —límites en CI, worker, pipeline más rápido— responde a la parte legítima de la presión por modernizar.

### 20. 🟠 ¿Qué invalidaría la matriz que construiste con supuestos?

⏱️ **30 segundos:** Que un supuesto resulte falso: la carga medida, el control regulatorio real, la cadencia de un equipo o la invariante confirmada por negocio.

🗣️ **2 minutos:** La matriz es tan buena como sus supuestos. Si la próxima campaña triplica el pico, si el auditor exige un entorno aislado o si negocio relaja la invariante, las filas cambian y la recomendación también. Por eso cada supuesto se escribe con su fuente, y la revisión empieza por comprobarlos.

🔬 **El detalle:** También la invalida un coste subestimado: si operar el monolito modular exige más de lo previsto, se revisa igual.

### 21. 🟠 La opción más barata incumple el SLO de disponibilidad. ¿Qué haces?

⏱️ **30 segundos:** Queda descartada: una restricción de SLO filtra antes de comparar costes, y busco la opción más barata que sí lo cumpla.

🗣️ **2 minutos:** Primero confirmo que el SLO es un requisito y no un deseo, y dónde falla la opción barata: puede ser un único punto de fallo que se resuelve con réplicas, o un recurso compartido que se aísla con cupos. Si ninguna variante local lo cumple, la siguiente opción en coste pasa a ser la recomendada.

🔬 **El detalle:** A veces la opción barata lo cumple con un cambio pequeño; descartarla sin analizar dónde falla es otra forma de sobrediseñar.

### 22. 🟠 Tienes que recomendar con una fecha de entrega cercana y sin mediciones. ¿Cómo decides?

⏱️ **30 segundos:** Elijo la opción más reversible que cumpla las restricciones conocidas, declaro lo que no sé y fijo una revisión cercana con datos que recoger.

🗣️ **2 minutos:** Sin mediciones, lo prudente es no comprometerse con lo irreversible: un monolito modular con límites claros deja abiertas las opciones y se entrega antes. Registro los supuestos y qué medir desde el primer día —pico, coordinación, recursos— para que la revisión tenga evidencia. La fecha de entrega no justifica inventar cifras.

🔬 **El detalle:** Si una restricción dura aparece más tarde, la frontera interna ya existe y la extracción parte de un lugar mejor.

### 23. 🟠 ¿Qué te haría cancelar una extracción que ya se había explorado?

⏱️ **30 segundos:** Que la alternativa local satisfaga el objetivo, que no haya capacidad para operar el nuevo límite o que el coste medido supere al beneficio esperado.

🗣️ **2 minutos:** Una exploración puede demostrar que un worker o un índice resolvían el problema, o que el equipo no puede sostener la guardia del servicio nuevo. En esos casos cancelar es la decisión correcta y no un fracaso: lo aprendido —límites internos, pruebas— se conserva. Los criterios de cancelación se acuerdan antes de empezar.

🔬 **El detalle:** Cancelar tarde es más caro; por eso la extracción avanza por cohortes con puntos de decisión explícitos.

### 24. 🟠 ¿Cuándo dejarías de comparar topologías y darías la decisión por buena?

⏱️ **30 segundos:** Cuando la opción elegida cumple las restricciones, el experimento confirmó los supuestos y ninguna señal de revisión se ha disparado.

🗣️ **2 minutos:** Comparar topologías indefinidamente también cuesta: bloquea al equipo y posterga mejoras. Una vez tomada y registrada la decisión, se trabaja sobre ella y se vuelve a comparar solo en la fecha acordada o cuando aparezca una señal. La estabilidad de la decisión es parte de su valor.

🔬 **El detalle:** El criterio de «suficiente» es el mismo que el de cualquier evolución: el beneficio marginal de seguir analizando ya no compensa su coste.

## 📖 02 — Diseñar un monolito modular desde cero

### 1. 🟢 ¿Qué responsabilidad inicial das a `orders` y qué no le das?

⏱️ **30 segundos:** El pedido y su estado comercial, y la orquestación de `CreateOrder`. No le doy el stock, los intentos de pago ni las entregas de avisos.

🗣️ **2 minutos:** `orders` decide cuándo un pedido pasa de pendiente a confirmado y coordina a los demás a través de sus APIs. Pero no escribe reservas, no guarda referencias del proveedor ni decide canales de aviso: eso pertenece a sus dueños. Si `orders` empieza a acumular esas decisiones, se convierte en el módulo que lo sabe todo y el límite desaparece.

🔬 **El detalle:** Orquestar no es poseer: `orders` puede pedir una reserva sin conocer cómo se calcula la disponibilidad.

### 2. 🟢 ¿Qué pertenece a `inventory`?

⏱️ **30 segundos:** El stock, las reservas y sus invariantes: disponibilidad, vencimiento y liberación.

🗣️ **2 minutos:** `inventory` decide si hay unidades para reservar, cuánto dura una reserva y cuándo se libera. Es el único que escribe esas tablas y expone `ReserveInventory` con un resultado cerrado. La primera política nueva previsible, la expiración de reservas, debería quedar entera dentro de `inventory`; si no, el corte está mal.

🔬 **El detalle:** El catálogo de productos puede estar en otro módulo; el stock no tiene por qué vivir junto a la descripción del producto.

### 3. 🟢 ¿Qué es la raíz de composición?

⏱️ **30 segundos:** El único lugar del ejecutable donde se crean las implementaciones de cada módulo y se conectan entre sí.

🗣️ **2 minutos:** Allí se decide que `orders` recibe la implementación de `ReserveInventory` de `inventory`, sin que `orders` importe clases internas. Mantenerla en un solo sitio hace visible el grafo de dependencias y permite sustituir una implementación —por ejemplo, un doble en pruebas— sin tocar a los consumidores. Puede ser código explícito o la configuración del contenedor de dependencias.

🔬 **El detalle:** Si cada módulo construye sus propias dependencias ajenas, el acoplamiento se esconde en constructores repartidos por todo el código.

### 4. 🟢 ¿Qué garantiza el esqueleto de la API y qué no garantiza?

⏱️ **30 segundos:** Garantiza la frontera: qué puede pedir `orders` y qué respuestas recibe. No garantiza el stock, la concurrencia ni la transacción.

🗣️ **2 minutos:** El `record` valida la forma de la petición y el resultado cerrado evita que `orders` dependa de excepciones internas. Pero que dos réplicas no vendan la última unidad depende de la implementación SQL y de la transacción, y eso se demuestra con pruebas contra la base real. Confundir el esqueleto con la garantía es el error del capítulo.

🔬 **El detalle:** La API decide qué no puede saber el consumidor; la implementación decide qué es verdad.

### 5. 🟢 ¿Qué primera regla arquitectónica añadirías?

⏱️ **30 segundos:** Que `orders` no pueda importar nada de `inventory` salvo su API pública, comprobado en CI con una violación provocada a propósito.

🗣️ **2 minutos:** Es la regla que protege la decisión más cara de recuperar: que un módulo no toque los internos ni las tablas de otro. Se prueba metiendo un import prohibido y viendo que el build falla; si no falla, el control no existe. Después se añaden reglas para ciclos y para el acceso a datos.

🔬 **El detalle:** En Java la regla necesita ArchUnit, Spring Modulith o JPMS; en Go, `internal/` ya la hace cumplir el compilador.

### 6. 🟡 ¿Por qué no devolverías la entidad ORM de stock a `orders`?

⏱️ **30 segundos:** Porque `orders` podría modificarla y saltarse las reglas de reserva, y cualquier cambio de persistencia de `inventory` rompería a `orders`.

🗣️ **2 minutos:** Una entidad ORM mutable expone campos, relaciones perezosas y ciclo de vida que `inventory` debe poder cambiar. Si `orders` la recibe, puede restar stock sin pasar por la regla y queda atada al esquema ajeno. Un resultado pequeño —reservado o sin stock— le da lo que necesita para decidir y nada más.

🔬 **El detalle:** El coste es un mapeo y un tipo más; es el precio de que el esquema de `inventory` siga siendo suyo.

### 7. 🟡 ¿Cuándo participan pedido y reserva en el mismo commit?

⏱️ **30 segundos:** Cuando los dos datos están en la misma base y negocio exige que un pedido confirmado tenga siempre su reserva.

🗣️ **2 minutos:** Con una base compartida y la invariante confirmada, el commit conjunto es la forma más barata de cumplirla: `orders` llama a la API de `inventory` con la misma conexión y un coordinador explícito confirma o revierte todo. Si algún día las bases se separan, la invariante pasa a necesitar compensación o reconciliación.

🔬 **El detalle:** Que sea posible una transacción amplia no obliga a meter más cosas en ella; el pago y el aviso quedan fuera a propósito.

### 8. 🟡 ¿Qué dejas fuera de ese commit y cómo lo recuperas?

⏱️ **30 segundos:** Fuera quedan la autorización del proveedor de pagos y el aviso: se registran como trabajo durable en el commit y se ejecutan después.

🗣️ **2 minutos:** La autorización ocurre en otro sistema y la base no puede deshacerla; esperarla dentro del commit además retiene la conexión. Por eso se guarda la intención con su clave y un worker llama al proveedor, con estado pendiente y reconciliación si el resultado es incierto. El aviso se programa cuando el pedido ya está confirmado.

🔬 **El detalle:** Registrar el trabajo en el mismo commit es lo que garantiza que no se pierde si el proceso cae justo después.

### 9. 🟡 ¿Cuándo emite `orders` el aviso de confirmación?

⏱️ **30 segundos:** Cuando `orders` confirma su estado, no antes: el aviso sigue al hecho de negocio.

🗣️ **2 minutos:** Si el aviso saliera al crear el pedido pendiente, el cliente recibiría «confirmado» de compras que después se rechazan por el pago o por el stock. Por eso el trabajo de `notifications` se registra en la transacción que confirma el pedido, y su fallo retrasa el aviso sin volver falsa la compra.

🔬 **El detalle:** Un aviso de «estamos procesando tu pago» es otro evento distinto, ligado al estado pendiente.

### 10. 🟡 ¿Por qué no introducir REST interno entre módulos del mismo proceso?

⏱️ **30 segundos:** Porque añade serialización, timeouts y semántica de red dentro de un proceso que no gana despliegue independiente a cambio.

🗣️ **2 minutos:** Una llamada local conserva el error directo, la transacción y la latencia de una función. HTTP interno obliga a manejar fallos parciales que no existen y rompe la transacción compartida. Si algún día un módulo se extrae, su contrato remoto se diseñará con los requisitos de ese momento, no se simula hoy.

🔬 **El detalle:** «Así ya está listo para microservicios» es el argumento habitual; lo que prepara una extracción es la API y el dueño de datos, no el protocolo.

### 11. 🟡 La primera política nueva toca los cuatro módulos. ¿Qué harías?

⏱️ **30 segundos:** Reviso el mapa antes de multiplicar interfaces: si una política toca los cuatro módulos, el corte puede estar mal o la política es transversal.

🗣️ **2 minutos:** Analizo la política: si es una regla de un dominio que se repartió entre módulos, muevo la regla a su dueño; si de verdad es transversal, como una promoción que afecta precio, stock y avisos, quizá falta un módulo o un orquestador explícito. Lo que no hago es añadir cuatro interfaces nuevas para que el cambio «pase» por todos.

🔬 **El detalle:** Un caso aislado no prueba nada; si se repite con cada política nueva, es evidencia de un límite equivocado.

### 12. 🟡 ¿Qué aplazarías explícitamente y qué no aplazarías nunca?

⏱️ **30 segundos:** Aplazo broker, bases separadas y despliegues por módulo; no aplazo nunca la identidad de las operaciones, la recuperación del pago ni la autoridad de escritura.

🗣️ **2 minutos:** Lo aplazado se añade cuando una restricción lo pide y no requiere migrar datos de clientes. Lo no aplazable es barato ahora y carísimo después: introducir claves de idempotencia o dueños de tablas con años de datos y escritores repartidos es una migración entera. Cada aplazamiento lleva escrito su criterio de revisión.

🔬 **El detalle:** La lista de aplazamientos es parte del diseño: dice al siguiente equipo qué no se hizo por decisión y no por olvido.

### 13. 🟡 ¿Cómo construirías la primera prueba de rollback conjunto de pedido y reserva?

⏱️ **30 segundos:** Contra la base real: provoco un fallo después de la reserva y compruebo, desde otra conexión, que ni el pedido ni la reserva quedaron.

🗣️ **2 minutos:** La prueba crea un pedido cuya segunda escritura falla a propósito —por ejemplo, una restricción violada—, y después consulta la base con otra conexión. Si queda el pedido o la reserva, la transacción no abarca lo que se creía. Un mock no sirve: el comportamiento que se prueba es el de la base.

🔬 **El detalle:** Es la misma prueba que detecta las trampas de plataforma: auto-invocación en Java, cliente global en Node o `db` en lugar de `tx` en Go.

### 14. 🟡 ¿Qué diferencia hay entre un módulo del build y una capacidad?

⏱️ **30 segundos:** Un módulo del build es una unidad de compilación; una capacidad es algo que el negocio sabe hacer, con sus reglas y sus datos.

🗣️ **2 minutos:** Pueden coincidir, pero no tienen por qué: una capacidad puede ocupar varios módulos del build y un módulo del build puede contener utilidades sin negocio. Separar el build no concede propiedad de datos ni contiene cambios si el corte no sigue las capacidades. Por eso primero se decide la capacidad y después el mecanismo que la protege.

🔬 **El detalle:** Partir el build antes de conocer las razones de cambio solidifica una conjetura y hace más caro corregirla.

### 15. 🟡 ¿Cuándo compartirías un tipo entre módulos?

⏱️ **30 segundos:** Cuando el tipo tiene un significado realmente común, cambia poco y una divergencia rompería una invariante, como el dinero y su redondeo.

🗣️ **2 minutos:** `Money` compartido entre `orders` y `payments` evita que un importe se calcule distinto en cada lado. En cambio, la dirección del cliente para envío y para avisos puede duplicarse, porque cada módulo la necesita con reglas distintas. Compartir crea un dueño y consumidores coordinados; duplicar permite evolución local.

🔬 **El detalle:** Un tipo compartido grande es un `common` disfrazado; cuanto más pequeño, menos coordinación impone.

### 16. 🟡 ¿Cómo preparas opciones futuras sin sobrediseñar?

⏱️ **30 segundos:** Con límites internos claros y la lista de aplazamientos escrita, sin construir hoy la infraestructura de un futuro que quizá no llegue.

🗣️ **2 minutos:** Una API por módulo, dueño de datos y regla en CI dejan preparada una extracción sin pagarla. Añadir ahora broker, bases o HTTP interno es pagar un coste seguro por un beneficio hipotético. Las opciones futuras se preservan manteniendo reversibles las decisiones, no anticipándolas.

🔬 **El detalle:** Sobrediseñar también cierra opciones: un contrato remoto prematuro fija un límite que el dominio todavía no ha confirmado.

### 17. 🟡 ¿En qué se parecen y en qué se diferencian el `record` de Java y el `Readonly` de TypeScript como frontera?

⏱️ **30 segundos:** Los dos describen la petición que cruza la frontera; el `record` puede además validarla al construirse, y `Readonly` solo impide modificarla en compilación.

🗣️ **2 minutos:** En Java, el constructor compacto rechaza una reserva de cero unidades en tiempo de ejecución, así que la validación viaja con el tipo. En TypeScript, `Readonly` desaparece al compilar y no comprueba nada en runtime: si la petición llega de la red, hace falta validarla en la frontera. Dentro del mismo proceso, los dos delimitan igual.

🔬 **El detalle:** La unión de literales de TypeScript y el `enum` de Java cumplen el mismo papel para el resultado: el consumidor solo puede recibir los valores previstos.

### 18. 🟠 ¿Cómo expresarías el mismo límite en Go y en Python, y qué cambia en cómo se hace cumplir?

⏱️ **30 segundos:** En Go, con un paquete por capacidad e `internal/`, que el compilador hace cumplir; en Python, con la API publicada en el paquete y contratos de importación en CI.

🗣️ **2 minutos:** En Go, `orders` no puede importar `inventory/internal/...`: el build falla sin herramienta adicional, aunque los subpaquetes de `inventory` sí pueden. En Python la privacidad es convención, así que hace falta import-linter o similar para que una importación prohibida rompa la CI. El diseño es el mismo; cambia quién aplica la regla.

🔬 **El detalle:** En ninguno de los dos el lenguaje controla el acceso a tablas: eso requiere permisos de base o revisión del acceso a datos.

### 19. 🟠 ¿Qué ocurre si dos réplicas reservan a la vez el último stock con este diseño?

⏱️ **30 segundos:** Depende de la implementación: con un `UPDATE` condicional o un bloqueo de fila, una reserva gana y la otra recibe `OUT_OF_STOCK`; con leer y escribir en la aplicación, se vende de más.

🗣️ **2 minutos:** El diseño modular no protege contra la carrera; la protege la base. La implementación de `inventory` debe comprobar y restar en la misma sentencia o bloquear la fila, y una prueba con concurrencia real debe demostrarlo. Un mutex en memoria no sirve, porque cada réplica tiene el suyo.

🔬 **El detalle:** Es un buen ejemplo de por qué el esqueleto de API no garantiza nada por sí mismo.

### 20. 🟠 ¿Cómo revertirías un límite que resultó incorrecto después de unos meses?

⏱️ **30 segundos:** Moviendo la regla o fusionando los módulos detrás de la misma API, con los consumidores migrados uno a uno y la regla de CI ajustada.

🗣️ **2 minutos:** Dentro de un monolito, corregir un límite es barato comparado con uno remoto: se puede cambiar productor y consumidor en el mismo commit. Primero se decide dónde debe vivir la regla, después se mueve su código y sus tablas con una migración compatible, y al final se actualiza la regla arquitectónica. Las pruebas de integración confirman que el comportamiento no cambió.

🔬 **El detalle:** Esta facilidad es uno de los argumentos para empezar modular dentro de un despliegue: los primeros errores de corte salen baratos.

### 21. 🟠 La CI detecta un acceso a los internos de `inventory` que parece necesario. ¿Qué haces?

⏱️ **30 segundos:** No desactivo la regla: averiguo qué necesita el consumidor y lo añado a la API de `inventory`, o registro una excepción con dueño y fecha si la migración no puede esperar.

🗣️ **2 minutos:** Un acceso a internos que parece necesario suele indicar que a la API le falta una operación o una consulta. La solución es ampliarla de forma deliberada. Si hay urgencia, una excepción estrecha, visible y con caducidad permite avanzar sin normalizar el atajo. Desactivar la regla entera destruye el control para todos.

🔬 **El detalle:** Si las excepciones se repiten para el mismo par de módulos, el límite puede estar mal y conviene revisarlo.

### 22. 🟠 La tabla de trabajo de `notifications` empieza a acumular filas. ¿Qué pasa y qué haces?

⏱️ **30 segundos:** Los avisos se retrasan; miro la edad del trabajo más antiguo y la causa —proveedor caído, worker lento, errores repetidos— antes de escalar nada.

🗣️ **2 minutos:** Si el proveedor de correo falla, el worker debe reintentar con espera creciente y alertar por edad, sin afectar a checkout. Si el worker no da abasto, se ajusta su concurrencia; si un trabajo falla siempre, va a un estado de error tras un máximo de intentos. La compra sigue funcionando porque el aviso está fuera del camino síncrono.

🔬 **El detalle:** Una cola que crece sin límite acaba agotando almacenamiento; conviene un umbral que avise mucho antes.

### 23. 🟠 Un compañero quiere una interfaz para cada clase «por si acaso». ¿Cómo respondes?

⏱️ **30 segundos:** Que una interfaz debe representar una conversación entre módulos o una sustitución concreta; una por clase añade archivos sin proteger nada.

🗣️ **2 minutos:** Las interfaces útiles están en las fronteras: `ReserveInventory` entre `orders` e `inventory`, o el puerto del proveedor de pagos para poder usar un simulador. Dentro de un módulo, una interfaz por clase duplica firmas y dificulta la navegación sin aislar ningún cambio. Se añade cuando aparece la segunda implementación o el límite.

🔬 **El detalle:** Añadirla después es barato dentro del mismo proceso: los IDE lo hacen en segundos.

### 24. 🟠 ¿Cuándo consideras suficiente el diseño inicial?

⏱️ **30 segundos:** Cuando protege las garantías de los flujos críticos, los módulos tienen API, dueño y regla verificada, y los primeros cambios reales quedan contenidos.

🗣️ **2 minutos:** No hace falta que el mapa sea perfecto: basta con que los límites existan, se hagan cumplir y se puedan corregir. Si la expiración de reservas se implementa dentro de `inventory` sin tocar a los demás y la prueba de rollback pasa, el diseño inicial ha cumplido. El resto se decide con los cambios siguientes.

🔬 **El detalle:** Seguir diseñando sin cambios reales que lo guíen es especular; el diseño mejora con evidencia, no con más horas de pizarra.

## 📖 03 — Recuperar modularidad en un monolito legado

### 1. 🟢 ¿Qué es un *hotspot* útil para empezar una recuperación?

⏱️ **30 segundos:** Una zona que combina mucha frecuencia de cambio con muchos defectos o mucha dificultad, confirmada con más de una fuente.

🗣️ **2 minutos:** La liberación de reservas lo es: cambia a menudo, concentra regresiones de cancelación y está repartida en once archivos. Un archivo enorme que nadie toca no es prioridad, por feo que sea. Se cruza el historial de cambios con defectos, accesos SQL y trazas para no confundir un reformateo con acoplamiento de negocio.

🔬 **El detalle:** El *hotspot* orienta dónde empezar; la decisión final también pesa el riesgo y la posibilidad de caracterizar el comportamiento.

### 2. 🟢 ¿Qué caracteriza a una costura vertical?

⏱️ **30 segundos:** Que abarca una capacidad de punta a punta —entrada, reglas y escrituras— detrás de un punto donde se puede cambiar la implementación sin tocar a los llamadores.

🗣️ **2 minutos:** En lugar de reorganizar una capa entera, se toma la liberación de reservas completa: quién la pide, qué reglas aplica y qué tablas escribe. La fachada `ReleaseReservation` es el punto de corte. Así la mejora es utilizable desde el primer paso y se puede medir en cambios reales de esa capacidad.

🔬 **El detalle:** Una costura horizontal —toda la capa de repositorios, por ejemplo— mueve mucho código sin contener ningún cambio de negocio.

### 3. 🟢 ¿Qué registra una prueba de caracterización y qué no afirma?

⏱️ **30 segundos:** Registra lo que el sistema hace hoy, defectos incluidos, para detectar cualquier cambio de comportamiento. No afirma que ese comportamiento sea correcto.

🗣️ **2 minutos:** Antes de mover la liberación, se fijan sus resultados con cancelación repetida, reserva vencida y pedido inexistente. Si después del refactor un resultado cambia, la prueba se pone en rojo y alguien decide si el cambio era querido. Es la red que permite mover un legado sin especificación.

🔬 **El detalle:** Cada comportamiento dudoso se marca como tal, para que nadie confunda la caracterización con un requisito.

### 4. 🟢 ¿Qué aporta *branch by abstraction*?

⏱️ **30 segundos:** Permite sustituir una implementación por otra detrás de una abstracción, en la línea principal de desarrollo y sin ramas largas.

🗣️ **2 minutos:** Se introduce la fachada, se pasan los consumidores por ella con la implementación vieja detrás, y después se cambia el interior por la nueva. Cada paso se integra y se despliega por separado. Así el sistema nunca queda a medias en una rama que diverge durante semanas.

🔬 **El detalle:** La abstracción es temporal en su forma: cuando la implementación vieja desaparece, la fachada queda como API normal del módulo.

### 5. 🟢 ¿Qué debe ocultar la fachada `ReleaseReservation`?

⏱️ **30 segundos:** Las tablas antiguas y la forma en que hoy se escriben: expone identidad de pedido y resultado, no filas ni columnas.

🗣️ **2 minutos:** Si la fachada devolviera la entidad de reserva o aceptara actualizaciones de columnas, los consumidores seguirían atados al esquema viejo y no se podría cambiar el interior. Publicando solo «libera la reserva de este pedido» y un resultado cerrado, `inventory` puede reescribir cómo lo hace sin que nadie lo note.

🔬 **El detalle:** La fachada tampoco debe contener lógica nueva: es el borde del módulo, no un lugar para acumular reglas.

### 6. 🟡 ¿Por qué no mover todas las clases a carpetas por dominio en un sprint?

⏱️ **30 segundos:** Porque cambiar la ubicación de las clases no cambia sus dependencias ni quién escribe cada tabla.

🗣️ **2 minutos:** Tras mover los archivos, `orders` sigue llamando al repositorio de reservas y el job de reembolsos sigue con su `UPDATE`. El árbol parece modular y el acoplamiento es idéntico. Además, la reorganización masiva es cara, difícil de revertir y mezcla miles de líneas en un solo cambio que nadie puede revisar.

🔬 **El detalle:** La reorganización puede venir al final, cuando los límites ya existen y el movimiento solo refleja lo que el código hace.

### 7. 🟡 ¿Cómo distinguirías un cambio conjunto accidental de una cohesión real en el historial?

⏱️ **30 segundos:** Cruzando el historial con el motivo de los cambios: si comparten razón de negocio de forma recurrente, es cohesión; si coinciden por reformateos, migraciones o dependencias, es accidente.

🗣️ **2 minutos:** Reviso una muestra de los commits: los que tocan reservas y pedidos por una misma política apuntan a una regla repartida; los que coinciden por una actualización de librería no dicen nada. También miro accesos SQL y trazas, que muestran dependencias reales en ejecución. Un solo commit nunca prueba causalidad.

🔬 **El detalle:** Las herramientas de acoplamiento temporal del historial son útiles para priorizar, pero su salida es una hipótesis, no un diagnóstico.

### 8. 🟡 ¿Qué harías con un bug que descubres al caracterizar la cancelación?

⏱️ **30 segundos:** Lo registro y lo decido con negocio: o se preserva como comportamiento esperado, o se corrige en un cambio separado del refactor.

🗣️ **2 minutos:** Si la cancelación repetida devuelve stock dos veces, es un bug que la caracterización deja visible. Corregirlo dentro del refactor mezclaría dos cambios y haría imposible saber cuál rompió algo. Lo congelo marcado como defecto, corrijo en su propio cambio con su propia prueba y después sigo moviendo.

🔬 **El detalle:** Algunos bugs tienen clientes que dependen de ellos; por eso la decisión es de negocio, no solo técnica.

### 9. 🟡 ¿En qué orden migras a los consumidores hacia la fachada?

⏱️ **30 segundos:** Empezando por las hojas del grafo Mikado: primero los cambios pequeños que no rompen nada, y cada consumidor por separado.

🗣️ **2 minutos:** Cada consumidor —el servicio de cancelación, el job de reembolsos, el controlador de administración— pasa por la fachada en su propio cambio, con la implementación vieja detrás. Las caracterizaciones confirman que el comportamiento no cambió. Cuando todos pasan por ella, la fachada es el único punto de entrada y ya se puede cambiar el interior.

🔬 **El detalle:** Una regla en CI que prohíba nuevos accesos directos a la tabla evita que, mientras se migra, aparezcan consumidores nuevos por el camino viejo.

### 10. 🟡 ¿Qué significa una cohorte estable en esta transición?

⏱️ **30 segundos:** Que cada pedido va siempre por la misma ruta, vieja o nueva, en todos sus pasos: liberación, reintentos, consultas y cancelaciones.

🗣️ **2 minutos:** Si la reserva de un pedido la gestionó la ruta vieja y su liberación va por la nueva, la nueva puede no encontrar lo que tiene que liberar. La cohorte se asigna por identificador de pedido para que un solo escritor gestione toda su vida. Se amplía gradualmente mientras las métricas acompañan.

🔬 **El detalle:** Asignar por petición aleatoria rompe la propiedad en cuanto una operación tiene varios pasos.

### 11. 🟡 ¿Qué puedes comparar en sombra y qué no?

⏱️ **30 segundos:** Lecturas o cálculos sin efectos sobre entradas equivalentes: qué liberaría cada implementación. Nunca la liberación real.

🗣️ **2 minutos:** La ruta que no está a cargo calcula su resultado y se compara con el de la ruta activa; las diferencias se clasifican como bug nuevo, bug viejo preservado o diferencia aceptada. Así se gana confianza antes de dar el control a la implementación nueva, sin duplicar efectos sobre el stock.

🔬 **El detalle:** Si comparar exige ejecutar el efecto, no se compara en sombra: se usa una cohorte pequeña con la ruta nueva a cargo.

### 12. 🟡 ¿Por qué no liberar reservas en las dos rutas a la vez?

⏱️ **30 segundos:** Porque devolvería stock dos veces o dejaría dos verdades distintas sobre la misma reserva.

🗣️ **2 minutos:** Ejecutar las dos implementaciones con efecto es un dual write: si una confirma y la otra falla, el estado queda inconsistente y nadie sabe cuál es la autoridad. Por eso en cada momento hay un solo escritor por pedido, y la otra ruta solo compara en sombra.

🔬 **El detalle:** La tentación aparece cuando se quiere «validar con tráfico real»; la forma segura es una cohorte pequeña, no una doble escritura.

### 13. 🟡 ¿Cómo controlas las violaciones históricas de imports sin bloquear al equipo?

⏱️ **30 segundos:** Con un baseline: la regla bloquea violaciones nuevas y el inventario de las existentes se reduce con dueño y fecha.

🗣️ **2 minutos:** Aplicar la regla a todo el legado de golpe produce cientos de fallos y el equipo termina desactivándola. Congelando las violaciones conocidas y prohibiendo solo las nuevas, la regla protege la costura desde el primer día. Cada excepción restante lleva motivo, responsable y fecha de retirada.

🔬 **El detalle:** Medir el tamaño del baseline a lo largo del tiempo muestra si la recuperación avanza o solo se contiene.

### 14. 🟡 ¿Qué métricas comparas antes y después de la costura interna?

⏱️ **30 segundos:** Componentes tocados, defectos, tiempo de entrega y esperas de revisión en cambios de reservas semejantes, antes y después.

🗣️ **2 minutos:** Si los cambios de liberación pasan de once archivos a uno o dos dentro de `inventory`, las regresiones bajan y la revisión ya no requiere a tres equipos, la costura funciona. Comparo cambios de complejidad parecida para no atribuirle una mejora que viene de un trimestre con menos trabajo.

🔬 **El detalle:** Es la misma lógica de línea base que se usa al desmontar un monolito distribuido: sin foto previa, no hay comparación.

### 15. 🟡 ¿Cuándo retiras la implementación anterior?

⏱️ **30 segundos:** Cuando no le queda ningún consumidor, la ruta nueva lleva un tiempo acordado sin divergencias y terminó la ventana de recuperación.

🗣️ **2 minutos:** Un contador de uso por ruta dice cuándo la implementación vieja ya no recibe tráfico. Se espera la ventana acordada por si hubiera que volver, se retira el código viejo y su camino en la fachada, y se ajusta la regla de CI para que nadie lo reintroduzca.

🔬 **El detalle:** Retirar pronto quita la vuelta atrás; retirar tarde prolonga el doble mantenimiento. La fecha se fija al empezar.

### 16. 🟡 ¿Qué coste tiene mantener dos implementaciones durante la transición?

⏱️ **30 segundos:** Doble mantenimiento, adaptadores transitorios y la atención del equipo repartida entre dos caminos.

🗣️ **2 minutos:** Cada corrección urgente puede tener que hacerse en las dos implementaciones, y la fachada añade un punto que entender. Ese coste se acepta si está acotado en tiempo y alcance. Una transición sin fecha convierte el andamio en arquitectura permanente con el doble de código.

🔬 **El detalle:** Por eso se migra una capacidad a la vez: el coste de convivencia se paga en un solo sitio.

### 17. 🟡 ¿En qué se diferencian la compilación de Java y los contratos de importación de Python como red de esta migración?

⏱️ **30 segundos:** La compilación de Java detecta consumidores que ya no encuentran lo que usaban; los contratos de importación de Python hacen de red donde el lenguaje no controla la privacidad.

🗣️ **2 minutos:** En Java, cambiar la fachada o hacer package-private una clase interna hace que los consumidores rotos fallen al compilar, una red fuerte y temprana. En Python, las importaciones no se comprueban hasta ejecutar, así que la red son los contratos de importación en CI y las pruebas de caracterización que ejercitan los flujos. En ninguno la red cubre el SQL.

🔬 **El detalle:** En Python, renombrar un paquete sin ejercitar los flujos es la trampa típica: todo parece bien hasta que se ejecuta la ruta olvidada.

### 18. 🟠 ¿Qué riesgo comparten los imports de TypeScript y los paquetes de Go al refactorizar, y qué no ven ninguno de los dos?

⏱️ **30 segundos:** Los dos confirman que el código importa lo correcto, y ninguno ve accesos a datos, consultas nativas ni imports dinámicos.

🗣️ **2 minutos:** En TypeScript y en Go se puede reemplazar cada import directo por la fachada y dejar el build en verde, mientras un script o un job sigue escribiendo la tabla con SQL. El riesgo es declarar la recuperación terminada porque los imports están limpios. La autoridad se comprueba con permisos de base y con la caracterización.

🔬 **El detalle:** En TypeScript, además, un import dinámico con ruta construida escapa a las reglas estáticas.

### 19. 🟠 ¿Cómo abortas la transición si las dos rutas usan la misma tabla?

⏱️ **30 segundos:** Devolviendo las cohortes a la ruta vieja: con la misma tabla y la misma política de escritura, no hay datos que mover.

🗣️ **2 minutos:** Mientras las dos implementaciones comparten tabla y restricciones, cambiar la ruta es suficiente. Antes compruebo que la implementación nueva no dejó estados que la vieja no entienda, como un valor nuevo en una columna. Si todo es compatible, abortar es barato, y por eso ese tramo se alarga hasta tener confianza.

🔬 **El detalle:** Esa compatibilidad hay que diseñarla desde el principio; si la implementación nueva escribe formatos nuevos, el aborto deja de ser trivial.

### 20. 🟠 ¿Cómo abortas si ya cambiaste el almacenamiento de las reservas?

⏱️ **30 segundos:** Llevando al origen las reservas escritas en el almacenamiento nuevo o, si eso no se ensayó, declarando recuperación hacia adelante con una pausa segura.

🗣️ **2 minutos:** Una vez que las reservas viven en otro sitio, volver a la ruta vieja sin traerlas perdería operaciones. Hay que copiar o reconciliar lo escrito desde el corte, verificar y solo entonces cambiar la ruta. Si ese camino no está probado, no se llama rollback: se corrige hacia adelante con el problema acotado.

🔬 **El detalle:** Por eso cambiar el almacenamiento es el paso más tardío de la recuperación, y se hace por cohortes pequeñas.

### 21. 🟠 Tras la costura, las esperas de revisión aumentan en lugar de bajar. ¿Qué haces?

⏱️ **30 segundos:** Investigo por qué: puede ser una fachada que obliga a coordinar con otro equipo o una regla de CI mal configurada, y lo corrijo antes de ampliar.

🗣️ **2 minutos:** La costura debería reducir esperas; si las aumenta, algo del diseño las causa. Quizá la fachada quedó sin dueño claro y cada cambio necesita aprobación de dos equipos, o la regla produce falsos positivos que bloquean. Detengo la expansión, corrijo la causa y vuelvo a medir.

🔬 **El detalle:** Si la causa es que el límite está mal puesto, la conclusión honesta es mover la costura, no insistir en ella.

### 22. 🟠 Llega una entrega urgente que toca reservas a mitad de la migración. ¿Cómo actúas?

⏱️ **30 segundos:** Hago la entrega por la fachada si ya existe para ese camino; si no, en el camino viejo con una prueba de caracterización, y la anoto en el grafo Mikado.

🗣️ **2 minutos:** La migración no puede bloquear el negocio. Si el cambio urgente cae en un consumidor ya migrado, va por la fachada; si cae en uno pendiente, se hace donde está hoy, con su prueba, y se registra como hoja nueva del grafo. Lo que evito es mezclar la urgencia con un paso de la migración en el mismo cambio.

🔬 **El detalle:** Las entregas urgentes son una buena prueba del plan: si cada una rompe la migración, los pasos son demasiado grandes.

### 23. 🟠 ¿Qué evidencia exigirías antes de ampliar la recuperación a otra capacidad?

⏱️ **30 segundos:** Que la primera costura mejoró de forma medida cambios, defectos y esperas, y que otra capacidad muestra el mismo patrón de coste.

🗣️ **2 minutos:** Ampliar sin haber demostrado la primera es repetir una apuesta sin datos. Si la liberación de reservas ahora cambia en un módulo, con menos regresiones y sin esperas entre equipos, y la gestión de pagos presenta el mismo *hotspot*, la siguiente costura está justificada. Cada ampliación repite caracterización, fachada y medición.

🔬 **El detalle:** La evidencia también puede decir que no hace falta más: un legado estable con una reparación puntual puede quedarse así.

### 24. 🟠 ¿Cuándo pararías la recuperación del legado?

⏱️ **30 segundos:** Cuando los cambios relevantes quedan contenidos y el beneficio de otra costura ya no compensa su coste de convivencia.

🗣️ **2 minutos:** La recuperación no persigue un árbol perfecto, sino que las capacidades que más cambian lo hagan bajo un dueño y con pruebas. Si las zonas que quedan apenas cambian y no generan defectos, recuperarlas cuesta más de lo que aporta. Se detiene y se deja registrado qué señal justificaría retomarla.

🔬 **El detalle:** Parar es una decisión, no un abandono: se documenta el estado alcanzado y las excepciones que quedan.

### 25. 🟠 Al intentar que `ReleaseReservation` sea el único escritor, el build y las pruebas fallan en cinco lugares. ¿Cómo usarías el método Mikado para ordenar el trabajo?

⏱️ **30 segundos:** Revierto el intento, anoto los cinco fallos como prerrequisitos del objetivo en un grafo, y empiezo por las hojas que no rompen nada.

🗣️ **2 minutos:** Cada fallo se convierte en un nodo: por ejemplo, «el job de reembolsos debe usar la fachada», que a su vez requiere «caracterizar el reembolso parcial». Se intenta cada nodo, se anotan sus propios prerrequisitos si falla y se revierte otra vez. Cuando las hojas están hechas e integradas, el objetivo se intenta de nuevo y ya no rompe.

🔬 **El detalle:** El grafo sirve también para repartir trabajo y explicar el avance: muestra qué falta y por qué, no solo cuánto.

## 📖 04 — Extraer un módulo a servicio

### 1. 🟢 ¿Qué debe comprar una extracción para que merezca la pena?

⏱️ **30 segundos:** Algo que el módulo no puede tener dentro del proceso común: cadencia propia, un aislamiento que se exige o se ha medido necesario, o una escala independiente.

🗣️ **2 minutos:** En el caso de `payments`, la espera de cuatro días por el release, el entorno separado que pide el auditor y el incidente de reportes que tumbó los cobros son esas razones. Si ninguna existiera, la extracción solo añadiría red, contratos y guardia. La compra se escribe antes de empezar y se comprueba al terminar.

🔬 **El detalle:** Tamaño del código o elegancia no son razones: un módulo grande y estable puede quedarse dentro sin problema.

### 2. 🟢 ¿Qué permanece en `orders` al extraer `payments`?

⏱️ **30 segundos:** El estado del pedido y las referencias al pago, junto con la decisión de confirmar o rechazar el pedido según el resultado.

🗣️ **2 minutos:** `orders` sigue siendo dueño del ciclo del pedido; lo que pierde es el acceso a intentos, claves y autorizaciones, que pasan a `payments`. Guarda la referencia del pago para consultarlo y traduce el resultado remoto a su propio `PaymentResult`. La reserva de `inventory` sigue en el monolito con su transacción local.

🔬 **El detalle:** Si `orders` necesitara leer muchas veces datos de pago, se valora una proyección local con frescura declarada, no volver a leer las tablas ajenas.

### 3. 🟢 ¿Qué añade un contrato remoto a una API local?

⏱️ **30 segundos:** Semántica de red: latencia, timeouts, resultados inciertos, versiones que conviven y un proveedor que puede no estar disponible.

🗣️ **2 minutos:** Una API local devuelve o falla dentro del mismo proceso y la misma transacción. El contrato remoto tiene que declarar plazos, errores, identidad de operación, consulta por clave y versiones soportadas. `orders` debe manejar el pendiente y la reconciliación que antes no existían entre módulos.

🔬 **El detalle:** La API interna previa ayuda porque ya delimita la conversación; no convierte gratis la llamada local en remota.

### 4. 🟢 ¿Qué significa tener un solo escritor durante la migración?

⏱️ **30 segundos:** Que en cada momento solo un lugar —el monolito o el servicio— puede crear o cambiar un intento o una autorización.

🗣️ **2 minutos:** Durante la copia el monolito sigue siendo la autoridad y el servicio solo recibe cambios capturados; en el corte se detiene el viejo, se drena y se activa el nuevo. Nunca escriben los dos a la vez sobre la misma operación, porque cualquier fallo entre ambos dejaría dos verdades y ninguna reconciliable.

🔬 **El detalle:** Con cohortes, «un solo escritor» se aplica por operación: cada pago tiene su dueño durante toda su vida.

### 5. 🟢 ¿Qué tráfico admite la prueba en sombra?

⏱️ **30 segundos:** Consultas o cálculos sin efectos: se replica la petición al servicio para comparar su respuesta, nunca un cobro real.

🗣️ **2 minutos:** La sombra sirve para contrastar que el servicio calcula lo mismo que el monolito con entradas equivalentes: estados, importes, reglas de rechazo. Las diferencias se clasifican antes del corte. Replicar una autorización real duplicaría el cobro en el proveedor, que es exactamente lo que la migración debe evitar.

🔬 **El detalle:** Para los efectos, la confianza se gana con una cohorte pequeña donde el servicio ya es el escritor, no duplicando.

### 6. 🟡 ¿Por qué copiar las filas no basta para migrar los datos?

⏱️ **30 segundos:** Porque mientras se copia el monolito sigue escribiendo, y sin capturar esos cambios la copia queda desfasada o incoherente.

🗣️ **2 minutos:** La copia inicial es una foto; entre la foto y el corte llegan pagos nuevos y cambios de estado. La captura de cambios desde un punto consistente con la copia, con identificadores y orden por entidad, es lo que permite converger sin huecos ni duplicados. Después se verifica que ambos lados coinciden.

🔬 **El detalle:** Copiar también exige traducir: si el esquema legado tiene códigos con varios significados, la ACL de `payments` interviene aquí.

### 7. 🟡 ¿Cómo eliges entre captura continua de cambios y una pausa de escritura?

⏱️ **30 segundos:** Por la capacidad de probar la captura sin huecos y por la tolerancia del negocio a una pausa: si no puedo demostrar la captura, una pausa acordada es más segura.

🗣️ **2 minutos:** La captura continua evita interrumpir el servicio, pero exige un punto de inicio consistente, orden por entidad y verificación. Si el volumen es manejable y el negocio acepta unos minutos sin escribir pagos, pausar, copiar y verificar elimina el riesgo de huecos. La decisión se toma con el coste de un error monetario en la mano.

🔬 **El detalle:** Una pausa también necesita ensayo: hay que saber cuánto dura realmente la copia antes de prometer una ventana.

### 8. 🟡 ¿Qué falla si la migración usa dos escrituras independientes?

⏱️ **30 segundos:** Que una puede confirmar y la otra fallar, y queda el mismo pago con dos estados distintos y ninguna autoridad para decidir.

🗣️ **2 minutos:** Si el monolito y el servicio escriben cada uno lo suyo para «mantenerlos sincronizados», un timeout entre ambos deja un pago autorizado en uno y pendiente en el otro. Sin fuente de verdad, reconciliar es adivinar. Por eso la migración usa una autoridad y un registro durable de cambios hacia el otro lado.

🔬 **El detalle:** El dual write parece más simple que la captura de cambios y es mucho más caro en incidentes.

### 9. 🟡 ¿Qué verificas además del número de filas?

⏱️ **30 segundos:** Claves, importes, monedas y estados de cada operación, además de la ausencia de duplicados y de huecos por entidad.

🗣️ **2 minutos:** Dos tablas con el mismo número de filas pueden tener importes distintos o estados traducidos mal. Se comparan campo por campo los datos que importan al negocio, se buscan claves repetidas y se revisa que cada pago tenga su historial completo. Una sola divergencia monetaria sin explicar detiene el corte.

🔬 **El detalle:** La verificación se automatiza y se repite; hacerla una vez a mano antes del corte no detecta lo que llegue después.

### 10. 🟡 ¿Cómo se corta el escritor anterior sin perder operaciones?

⏱️ **30 segundos:** Bloqueando comandos nuevos en el viejo, drenando los ya admitidos, aplicando el último tramo de cambios y verificando antes de habilitar el nuevo.

🗣️ **2 minutos:** El orden evita que una operación quede a medias entre los dos: nada nuevo entra al viejo, lo que estaba en curso termina, el servicio recibe los últimos cambios y se confirma que está al día. Solo entonces se cambia la ruta. El viejo queda de solo lectura para consultas y como referencia.

🔬 **El detalle:** El corte se ensaya en un entorno con datos parecidos; el primer ensayo suele descubrir operaciones que nadie había inventariado.

### 11. 🟡 ¿Qué haces con un reintento tardío que llega al origen después del corte?

⏱️ **30 segundos:** Lo rechazo en el origen y lo dirijo al servicio nuevo con la misma clave, para que el reintento no cree otra operación.

🗣️ **2 minutos:** Un cliente o un job que reintenta contra el monolito después del corte no debe escribir allí, porque el viejo ya no es autoridad. El origen responde con una redirección o un error que obliga a ir al destino, y la clave de idempotencia garantiza que el servicio reconozca la operación si ya la tenía.

🔬 **El detalle:** Por eso el viejo queda de solo lectura: aceptar escrituras tardías reabre el dual write que el corte cerró.

### 12. 🟡 ¿Cómo cambia el rollback antes y después del corte?

⏱️ **30 segundos:** Antes del corte, volver es desactivar el destino; después, exige llevar al origen las operaciones escritas en el servicio.

🗣️ **2 minutos:** Mientras el monolito es la autoridad, el servicio es un candidato y abortar no pierde nada. Tras el corte, el servicio tiene pagos que el monolito desconoce; cambiar el router los perdería. Hay que devolver esos datos, verificar compatibilidad y transferir otra vez. Si no está ensayado, se declara recuperación hacia adelante con una pausa segura.

🔬 **El detalle:** Llamar rollback a lo que no se ha probado da una falsa sensación de seguridad justo cuando se necesita decidir rápido.

### 13. 🟡 ¿Qué medirías en el canary del servicio nuevo?

⏱️ **30 segundos:** Errores, latencia, divergencias con el monolito y con el proveedor, y operaciones pendientes, separados por cohorte.

🗣️ **2 minutos:** El canary compara la cohorte del servicio con la del monolito en las mismas métricas: tasa de autorización, p95 del flujo de compra, pendientes y su edad, y divergencias de importe. Una mejora de latencia no compensa una divergencia monetaria. Los umbrales de parada se fijan antes de empezar.

🔬 **El detalle:** Una cohorte demasiado pequeña no muestra problemas de carga; se amplía por pasos con la misma vigilancia.

### 14. 🟡 ¿Qué te haría cancelar la extracción antes del corte?

⏱️ **30 segundos:** Que la alternativa local resuelva el objetivo, que aparezcan divergencias sin explicar o que el equipo no pueda operar el nuevo límite.

🗣️ **2 minutos:** Si un pipeline propio dentro del monolito elimina la espera de cuatro días, o los cupos de recursos contienen el incidente de memoria, parte de la compra desaparece; si además el auditor aceptara otro control, la extracción ya no se justifica. También se cancela si la guardia no puede reconciliar sola. Lo aprendido —contrato, traducción— se conserva.

🔬 **El detalle:** Cancelar antes del corte es barato; por eso los criterios se acuerdan al principio y se revisan en cada paso.

### 15. 🟡 ¿Qué revela un servicio con base propia en el que otros equipos siguen escribiendo?

⏱️ **30 segundos:** Que el servicio tiene almacenamiento propio pero no autoridad: el acoplamiento de datos sigue, ahora repartido entre bases o credenciales.

🗣️ **2 minutos:** Si otros equipos conservan permisos de escritura o deben aprobar cada cambio de esquema, la base nueva solo cambió de sitio el problema. La autonomía exige que `payments` sea el único escritor y decida su esquema, y que los demás usen su contrato. Se revocan permisos ajenos como parte del corte.

🔬 **El detalle:** Es el mismo diagnóstico de base compartida con propiedad difusa, aplicado a una base que parecía propia.

### 16. 🟡 ¿Cuándo declararías terminada la extracción?

⏱️ **30 segundos:** Cuando `payments` cambia, despliega y se recupera bajo su dueño sin coordinar con el monolito, y el SLO de compra sigue estable.

🗣️ **2 minutos:** No basta con que el servicio esté en producción: la ruta vieja retirada, los permisos ajenos revocados, la guardia reconciliando sin ayuda y varios cambios del proveedor desplegados sin esperar al release común. Esos cambios reales son la prueba de que la extracción compró lo que prometía.

🔬 **El detalle:** Si tras la extracción `payments` sigue saliendo con el monolito, la extracción no terminó, o no hacía falta.

### 17. 🟡 ¿Qué riesgo comparten reutilizar DTO en Java y compartir tipos en TypeScript entre el monolito y el servicio?

⏱️ **30 segundos:** Los dos mantienen el acoplamiento de código entre el monolito y el servicio: un cambio en el tipo compartido obliga a desplegar a ambos.

🗣️ **2 minutos:** Si el servicio reutiliza las entidades o DTO del monolito en Java, o un paquete de tipos compartido en TypeScript, cualquier cambio en esos tipos arrastra a los dos ejecutables. La extracción parece hecha y el lockstep sigue por el build. Cada lado debe tener su modelo y el contrato remoto, validado en runtime.

🔬 **El detalle:** En TypeScript el riesgo es mayor porque los tipos no validan nada en runtime: el payload real puede no coincidir con el tipo compartido.

### 18. 🟠 ¿En qué se diferencian un deadline en Go y un worker de reconciliación en Python ante un resultado incierto?

⏱️ **30 segundos:** El deadline acota cuánto espera el llamador; el worker resuelve después lo que quedó incierto. Uno limita la espera, el otro garantiza la resolución.

🗣️ **2 minutos:** En Go, el `context` con deadline hace que `orders` deje de esperar a tiempo, pero no dice si el cobro se hizo ni lo deshace. En Python, un worker persistente consulta por la clave hasta resolver el pendiente o mandarlo a revisión. Se necesitan los dos: sin deadline se agota el presupuesto, sin reconciliación el pendiente no termina.

🔬 **El detalle:** La trampa común es reintentar con una clave nueva al vencer el deadline; la clave se reutiliza siempre.

### 19. 🟠 El servicio nuevo cobra correctamente, pero no consigue notificar a `orders`. ¿Qué haces?

⏱️ **30 segundos:** El pago queda autorizado y el pedido pendiente: reintento la notificación con la misma identidad y, si no llega, `orders` la obtiene consultando el pago por su referencia.

🗣️ **2 minutos:** El resultado debe publicarse desde una outbox del servicio para que no se pierda; si aun así `orders` no lo recibe, su reconciliador consulta el estado del pago y confirma el pedido. Mientras tanto el cliente ve «pago en proceso». Lo que no se hace es volver a cobrar ni confirmar sin saber el resultado.

🔬 **El detalle:** Este caso es la razón de que la consulta por referencia forme parte del contrato remoto desde el primer día.

### 20. 🟠 Durante la copia aparece una divergencia monetaria. ¿Cómo la recuperas?

⏱️ **30 segundos:** Detengo el avance, localizo las operaciones divergentes, determino cuál lado tiene razón con el historial y el proveedor, y corrijo la causa antes de seguir.

🗣️ **2 minutos:** La divergencia puede venir de un cambio capturado dos veces, de una traducción de estados errónea o de una reparación manual en el monolito que no pasó por la captura. Se corrigen los registros afectados con una operación auditada y se añade una verificación que detecte ese tipo de error. El corte no se reanuda con divergencias sin explicar.

🔬 **El detalle:** El proveedor es la tercera fuente: su registro de autorizaciones desempata cuando monolito y servicio discrepan.

### 21. 🟠 ¿Puedes volver al origen si el esquema del destino ya cambió?

⏱️ **30 segundos:** Solo si el cambio de esquema es compatible con lo que el origen entiende o si el camino de vuelta traduce los datos; si no, la vuelta no es un rollback sino otra migración.

🗣️ **2 minutos:** Si el destino añadió columnas o cambió formatos, devolver las operaciones al monolito exige traducirlas al esquema viejo. Por eso, mientras exista ventana de vuelta, el destino evoluciona de forma compatible —expandir sin contraer— y el camino de retorno se prueba. Tras cerrar la ventana, se acepta que solo se corrige hacia adelante.

🔬 **El detalle:** Es la misma regla de expand-contract aplicada entre dos sistemas: la contracción se retrasa hasta que ya no hace falta volver.

### 22. 🟠 Descubres que los dos escritores estuvieron activos por error durante una hora. ¿Qué haces?

⏱️ **30 segundos:** Detengo las escrituras en uno de los dos, identifico las operaciones de esa hora y las reconcilio contra el proveedor antes de reanudar.

🗣️ **2 minutos:** Primero se corta el dual write para que no crezca; después se listan los pagos creados o cambiados en esa ventana en ambos lados, se comparan con el proveedor y se corrigen duplicados, estados y avisos al cliente. Por último se busca por qué el bloqueo del escritor viejo falló y se añade una comprobación que lo impida.

🔬 **El detalle:** Una alerta que detecte escrituras en el escritor retirado habría acortado esa hora a minutos.

### 23. 🟠 ¿Cómo decides si el equipo puede sostener la guardia del servicio nuevo?

⏱️ **30 segundos:** Ensayando: si el equipo puede detectar, reconciliar y recuperar incidentes del servicio sin depender de otro equipo, en un ejercicio realista.

🗣️ **2 minutos:** Reviso que haya runbooks para pendientes, divergencias y caída del proveedor, alertas por edad de pendientes y personas suficientes para una rotación sostenible. Hago un ensayo de incidente. Si la guardia depende de alguien del monolito para cada problema, el límite no es operable todavía y la extracción se pospone o se acota.

🔬 **El detalle:** La carga de guardia se mide después también: si crece más de lo previsto, es una señal para revisar la decisión.

### 24. 🟠 ¿Por qué no extraer enseguida los otros módulos, si esta extracción salió bien?

⏱️ **30 segundos:** Porque cada extracción necesita sus propias razones; que esta haya salido bien no dice que los otros módulos ganen algo al salir.

🗣️ **2 minutos:** `payments` tenía cadencia, aislamiento regulatorio y de fallos. `inventory` comparte la invariante con `orders` y el mismo equipo; extraerlo rompería la transacción local sin compra. Cada módulo pasa por la matriz con su evidencia. La experiencia de esta extracción abarata las siguientes, pero no las justifica.

🔬 **El detalle:** Encadenar extracciones por inercia es una de las formas en que se fabrica un monolito distribuido.

### 25. 🟠 Tras la extracción, `payments` quiere cambiar sus estados al vocabulario de su proveedor. ¿Dónde pondrías la traducción para que `orders` no cambie, y qué te costaría?

⏱️ **30 segundos:** En una capa anticorrupción del lado de `orders`, que traduce los estados del proveedor a `PaymentResult`. Cuesta un mapeo, pruebas de traducción y dos modelos del mismo concepto.

🗣️ **2 minutos:** Si `payments` adopta «requiere captura» o «completado», la ACL de `orders` convierte eso a `AUTHORIZED`, `REJECTED` o `PENDING`, que es lo que entienden las reglas de pedido. El cambio de vocabulario toca el traductor y sus pruebas, no las reglas. Sin ACL, cada cambio del proveedor se propagaría hasta el monolito.

🔬 **El detalle:** Si `payments` publicara un contrato estable pensado para sus consumidores, la ACL de `orders` sería fina; si publica el vocabulario del proveedor tal cual, la ACL hace el trabajo pesado.

## 📖 05 — Equipos, ownership y gobernanza evolutiva

### 1. 🟢 ¿Qué significa ownership efectivo de una capacidad?

⏱️ **30 segundos:** Que el mismo equipo puede decidir, cambiar y recuperar la capacidad sin esperar a otros de forma rutinaria.

🗣️ **2 minutos:** `payments` tiene ownership efectivo si decide sus cambios compatibles, despliega cuando le toca y atiende sus incidentes con su propio runbook. Si un comité aprueba cada cambio, otro equipo escribe en sus tablas o la guardia es de todos, el ownership es nominal aunque el servicio tenga repositorio y pipeline propios.

🔬 **El detalle:** Consultar a otros equipos no resta ownership; necesitar su permiso para lo rutinario sí.

### 2. 🟢 ¿Qué es la carga cognitiva de un equipo en este contexto?

⏱️ **30 segundos:** El esfuerzo que un equipo necesita para entender el dominio, las herramientas y la operación de lo que entrega.

🗣️ **2 minutos:** No se mide contando servicios: `orders` con diez reglas volátiles puede exigir más que varios workers sencillos. Si la carga supera lo que el equipo puede sostener, aparecen errores, esperas y guardias mal atendidas. Asignar capacidades a equipos es, en parte, repartir esa carga para que cada uno pueda operar lo suyo.

🔬 **El detalle:** Una plataforma interna reduce carga cuando quita trabajo repetido —pipelines, telemetría—, no cuando añade otra herramienta que aprender.

### 3. 🟢 ¿Qué debe ofrecer un equipo de plataforma y qué no debe hacer?

⏱️ **30 segundos:** Capacidades comunes en autoservicio —pipeline, telemetría, entornos— que reduzcan la carga de los equipos. No debe aprobar reglas de negocio ni ser un paso obligatorio de cada cambio.

🗣️ **2 minutos:** La plataforma funciona como un proveedor interno: ofrece productos que los equipos eligen usar porque les ahorran trabajo. Si se convierte en aprobador de cada despliegue o cada cambio de dominio, reintroduce la espera que la autonomía quería quitar. Se evalúa por adopción y por el tiempo que ahorra.

🔬 **El detalle:** Una plataforma obligatoria y lenta produce equipos que la esquivan con soluciones propias, que es peor para todos.

### 4. 🟢 ¿Qué datos mínimos exige una excepción arquitectónica?

⏱️ **30 segundos:** Motivo, alcance del acceso, consumidores, dueño, fecha de revisión y, si es de escritura, cómo se protegen las invariantes y cómo se devuelve la autoridad.

🗣️ **2 minutos:** Una excepción sin esos datos es invisible y se vuelve permanente, como la escritura del informe financiero renovada ocho veces. Con ellos, cada revisión puede decidir si el motivo sigue, si ya hay una alternativa y cuánto cuesta mantenerla. La fecha no se renueva sola: vencer obliga a decidir.

🔬 **El detalle:** Un registro de excepciones con su antigüedad es una métrica útil: si crece, la arquitectura real se está apartando de la declarada.

### 5. 🟢 ¿Qué distingue una consulta de una aprobación obligatoria?

⏱️ **30 segundos:** La consulta aporta información a quien decide; la aprobación obligatoria traslada la decisión a otro.

🗣️ **2 minutos:** Consultar a los consumidores antes de un cambio semántico mejora la decisión y es barato. Exigir la firma del comité para un cambio compatible de reintentos convierte al comité en dueño de hecho y añade once días de espera. La regla práctica: se consulta lo que se afecta, se aprueba solo lo que un control o un requisito exige.

🔬 **El detalle:** Una consulta sin respuesta en un plazo razonable no debe bloquear; si bloquea, es una aprobación disfrazada.

### 6. 🟡 ¿Por qué un equipo por servicio puede no tener autonomía?

⏱️ **30 segundos:** Porque la autonomía depende de quién decide, cambia y recupera, no de cuántos repositorios hay: otros pueden seguir controlando sus datos, contratos o releases.

🗣️ **2 minutos:** Un equipo con su servicio puede necesitar aprobación de arquitectura para cada cambio, depender de que otro equipo modifique un esquema compartido o no tener capacidad para la guardia. En esos casos la topología sugiere independencia y la operación diaria la desmiente. Se diagnostica con cambios reales y esperas medidas.

🔬 **El detalle:** También falla si el equipo es demasiado pequeño para sostener la operación de lo que se le asignó.

### 7. 🟡 ¿Cómo aplicas la ley de Conway sin copiar el organigrama en el código?

⏱️ **30 segundos:** Como restricción: diseño teniendo en cuenta que las fronteras de comunicación empujan las del sistema, pero sin crear un equipo por tabla ni por servicio.

🗣️ **2 minutos:** Si dos equipos tienen que coordinar cada cambio de una capacidad, el sistema tenderá a partirse por ahí. Antes de crear otro servicio, evalúo mover la autoridad, una colaboración temporal o fusionar responsabilidades. Y si se busca un corte por capacidad, los equipos se alinean con él, porque la organización empujará de vuelta a su forma anterior.

🔬 **El detalle:** La maniobra inversa de Conway tiene coste humano y tiempo; no es un cambio de diagrama.

### 8. 🟡 ¿Qué responsabilidad mantiene plataforma sobre la operación de `payments`?

⏱️ **30 segundos:** Las capacidades comunes que usa `payments` —pipeline, telemetría, entornos— y su disponibilidad; no la reconciliación ni las reglas de pago.

🗣️ **2 minutos:** Si el pipeline de despliegue falla, es un incidente de plataforma; si hay pagos pendientes, es de `payments`. Esa separación evita que la plataforma se convierta en guardia de todo y que `payments` dependa de otro equipo para operar su dominio. La plataforma sí debe dar herramientas para que `payments` observe y recupere lo suyo.

🔬 **El detalle:** La frontera se escribe en la matriz de autoridad; sin ella, cada incidente empieza con una discusión sobre de quién es.

### 9. 🟡 ¿Cómo revisarías un cambio de API interna sin convertirlo en una aprobación global?

⏱️ **30 segundos:** Con el dueño de la API decidiendo, los consumidores afectados consultados con ejemplos de compatibilidad, y la CI verificando el contrato.

🗣️ **2 minutos:** Para un cambio compatible basta con que las pruebas de consumidor pasen; el dueño lo despliega. Para uno semántico, se muestran ejemplos a los consumidores y se acuerda la migración y la retirada. Nadie ajeno a la capacidad y sus consumidores tiene que firmar. La decisión queda registrada para revisarla con evidencia.

🔬 **El detalle:** Un comité puede seguir siendo útil para decisiones transversales raras; lo que no debe es estar en el camino de cada cambio.

### 10. 🟡 ¿Qué diferencia una excepción de lectura de una de escritura?

⏱️ **30 segundos:** La de lectura no puede romper invariantes y solo acopla al esquema publicado; la de escritura puede corromper datos del dueño y exige protección y plan de retorno.

🗣️ **2 minutos:** Un informe que lee una vista de `inventory` con frescura declarada es una concesión razonable y barata. Uno que escribe en sus tablas salta las reglas de reserva y convierte a `inventory` en corresponsable de un código que no controla. Por eso la de escritura requiere más justificación, controles y una fecha para devolver la autoridad.

🔬 **El detalle:** Muchas escrituras ajenas se resuelven con un comando pequeño del dueño; suele ser más barato que mantener la excepción.

### 11. 🟡 ¿Qué métricas de entrega usarías para saber si la gobernanza ayuda o estorba?

⏱️ **30 segundos:** Tiempo de espera frente a tiempo de trabajo por cambio, releases coordinados por obligación, fallos de cambio, tiempo de recuperación y carga de guardia.

🗣️ **2 minutos:** Si un cambio tarda once días y diez son de espera por aprobaciones, la gobernanza estorba. Si al quitar aprobaciones suben los fallos de cambio, faltaba un control automatizado. Las métricas se miran por capacidad y a lo largo del tiempo, y se relacionan con impacto de negocio y calidad, no con la productividad de personas concretas.

🔬 **El detalle:** Usar estas métricas para clasificar individuos incentiva ocultar colaboración y trocear cambios artificialmente.

### 12. 🟡 ¿Cómo atiendes una capacidad que no tiene una guardia sostenible?

⏱️ **30 segundos:** Reduzco su alcance, asigno soporte temporal de otro equipo con un plan de transferencia, o reconsidero la topología si el límite no se puede operar.

🗣️ **2 minutos:** Una guardia rotando entre cinco equipos no conoce el reconciliador; la solución no es añadir otra rota, sino que el equipo de pagos la asuma con runbooks y alertas. Si ese equipo es demasiado pequeño, se simplifica lo que opera, se le da apoyo temporal con fecha, o se acepta que esa capacidad no debía ser un servicio aparte todavía.

🔬 **El detalle:** Una guardia insostenible es un riesgo de negocio aunque el código sea impecable; se trata como tal.

### 13. 🟡 ¿Cuándo aceptarías ownership compartido de una capacidad?

⏱️ **30 segundos:** Temporalmente y con reglas explícitas: durante una migración, un aprendizaje o cuando la capacidad es pequeña y dos equipos la tocan poco.

🗣️ **2 minutos:** El ownership compartido sin reglas deriva en que nadie decide y nadie responde. Si se acepta, se escribe quién decide qué, quién hace la guardia y cuándo se revisa. Si la coordinación se vuelve continua, es señal de que la autoridad debe ir a un solo equipo o de que ambos deberían fusionarse para esa capacidad.

🔬 **El detalle:** Compartir código de plataforma estable es distinto de compartir decisiones de dominio; lo primero suele funcionar bien.

### 14. 🟡 ¿Cómo retiras una aprobación que no aporta ninguna garantía?

⏱️ **30 segundos:** Sustituyéndola por un control automatizado si protege algo verificable, o eliminándola si no protege ninguna garantía, y midiendo el efecto.

🗣️ **2 minutos:** Pregunto qué fallo evita cada aprobación. Si es una incompatibilidad de contrato, la CI con pruebas de consumidor lo detecta mejor y más rápido. Si nadie sabe qué evita, se retira de forma experimental durante un periodo, se vigilan fallos de cambio y se confirma. Así se quita espera sin perder seguridad.

🔬 **El detalle:** Las aprobaciones exigidas por un requisito legal no se retiran: se automatiza su evidencia para que no sean espera.

### 15. 🟡 ¿Qué evidencia pedirías antes de reorganizar equipos?

⏱️ **30 segundos:** Cambios reales que cruzan equipos, esperas medidas, incidentes con dueño difuso y la carga de cada equipo.

🗣️ **2 minutos:** Reorganizar cuesta meses de adaptación y conocimiento perdido; hay que saber qué problema resuelve. Si la mayoría de los cambios de una capacidad cruzan dos equipos y esperan días, la evidencia apunta a alinear equipos con capacidades. Si el problema es un proceso de aprobación, cambiar el organigrama no lo arregla.

🔬 **El detalle:** Un piloto con un equipo alineado a una capacidad es más barato que reorganizar todo, y aporta la evidencia que falta.

### 16. 🟡 ¿Cómo evalúas si la plataforma interna está funcionando?

⏱️ **30 segundos:** Por uso voluntario y por la espera y el trabajo que ahorra a los equipos.

🗣️ **2 minutos:** Mido cuántos equipos adoptan cada capacidad sin obligación, cuánto tardan en tener un pipeline o un entorno nuevo y cuánto tiempo de recuperación ganan con la telemetría común. Si los equipos la esquivan o se quejan de colas, la plataforma se ha vuelto un cuello. Se trata como un producto: con usuarios, métricas y hoja de ruta.

🔬 **El detalle:** Una plataforma obligatoria puede mostrar el 100 % de uso y aun así estar fallando; la adopción voluntaria es la métrica honesta.

### 17. 🟠 Dos equipos reclaman la misma tabla. ¿Qué haces?

⏱️ **30 segundos:** Decido quién es dueño de la invariante con negocio, asigno la escritura a ese equipo y ofrezco al otro un comando o una vista.

🗣️ **2 minutos:** Primero miro qué escribe cada uno y por qué; a veces la tabla mezcla dos conceptos y hay que separarla. Si es un solo concepto, el dueño es quien responde por su regla de negocio. El otro equipo pasa a usar su API y se revocan sus permisos de escritura. Si los equipos no acuerdan, escala a quien responde por el negocio.

🔬 **El detalle:** La arquitectura hace cumplir la decisión con permisos y contratos; la decisión en sí es organizativa.

### 18. 🟠 La excepción del informe financiero venció y sigue escribiendo en producción. ¿Cómo la gestionas?

⏱️ **30 segundos:** No la renuevo automáticamente: reviso motivo y riesgo con su dueño, y la convierto en un comando de `inventory` o en una excepción nueva con plan y fecha.

🗣️ **2 minutos:** Una escritura directa de dos años es ya arquitectura real. Se analiza qué escribe el informe y por qué; normalmente basta un comando del dueño o una tabla propia del informe. Mientras se migra, se registra una excepción nueva con fecha cercana y alerta de uso. Cortar el acceso de golpe rompería un proceso financiero.

🔬 **El detalle:** El caso también revela un fallo del proceso: si las excepciones pueden renovarse solas, habrá más como esta.

### 19. 🟠 Tras dar autonomía a `payments`, mejora la entrega pero empeora la guardia. ¿Qué haces?

⏱️ **30 segundos:** Miro por qué empeora la guardia —incidentes nuevos, pocas personas, runbooks pobres— y la refuerzo antes de dar marcha atrás en la autonomía.

🗣️ **2 minutos:** La autonomía trae la operación consigo. Si la guardia empeora por falta de personas, se amplía la rota o se da apoyo temporal; si por alertas ruidosas, se ajustan; si por incidentes nuevos, se corrige su causa. Solo si el coste de operar el límite supera de forma sostenida la mejora en entrega, se reconsidera la frontera.

🔬 **El detalle:** La comparación se hace con la línea base: mejor entrega con guardia peor puede ser un buen trato o no, según el negocio.

### 20. 🟠 ¿Cómo responderías a quien exige que cada equipo tenga su propio servicio?

⏱️ **30 segundos:** Que un servicio por equipo no es un objetivo: los servicios se justifican por restricciones de la capacidad, y un equipo puede poseer módulos dentro de un monolito.

🗣️ **2 minutos:** Pregunto qué problema resolvería cada servicio nuevo. Muchos equipos trabajan con autonomía sobre módulos con dueño, API y reglas en CI dentro de un despliegue común. Crear servicios para dar a cada equipo el suyo fabrica fronteras sin compra y multiplica guardias. El ownership se da con autoridad y operación, no con repositorios.

🔬 **El detalle:** Si el release común sí bloquea a un equipo de forma medida, esa espera es la razón, y se discute con ella.

### 21. 🟠 ¿Qué control conserva la autonomía de `payments` sin eliminar toda revisión?

⏱️ **30 segundos:** Pruebas de consumidor en la CI de `payments` para los cambios compatibles, y revisión con consumidores solo para los cambios semánticos.

🗣️ **2 minutos:** Con ese control, `payments` despliega cambios compatibles sin esperar a nadie: si rompe a un consumidor, la CI lo detiene antes. Los cambios que alteran significado —un estado nuevo, una unidad distinta— pasan por una revisión con quienes los consumen. Así se conserva la seguridad sin volver al comité.

🔬 **El detalle:** Añadir permisos de base y alertas de pendientes completa el cuadro: autonomía para cambiar, controles para no romper.

### 22. 🟠 Una urgencia de producción cruza el ownership de dos equipos. ¿Cómo la resuelves?

⏱️ **30 segundos:** Resuelvo el incidente con quien pueda actuar más rápido, siguiendo la matriz de autoridad, y después reviso por qué cruzaba ownership.

🗣️ **2 minutos:** En la urgencia importa restaurar el servicio: el equipo dueño de la capacidad afectada lidera y el otro ayuda. Después, en la revisión, analizo si el cruce era accidental o indica que una decisión estaba mal asignada. Si se repite, redefino la autoridad o fusiono la responsabilidad.

🔬 **El detalle:** Tener un canal y un runbook de incidentes compartidos evita que la urgencia empiece con una discusión sobre de quién es.

### 23. 🟠 ¿Cuándo fusionarías la responsabilidad de dos equipos?

⏱️ **30 segundos:** Cuando una capacidad requiere coordinación continua entre los dos y no hay una frontera natural que la divida.

🗣️ **2 minutos:** Si casi todos los cambios de `orders` e `inventory` los hacen juntos dos equipos distintos, la coordinación cuesta más que lo que aporta la separación. Fusionar la responsabilidad —un equipo para las dos capacidades— reduce esperas y aclara la guardia. Es la versión organizativa de fusionar dos servicios que cambian siempre juntos.

🔬 **El detalle:** Antes de fusionar, se comprueba que la carga cognitiva resultante sea sostenible para un equipo.

### 24. 🟠 ¿Qué demuestra que la gobernanza es suficiente y no hay que añadir más controles?

⏱️ **30 segundos:** Que las garantías se protegen, los cambios no esperan por aprobaciones que no aportan y cada incidente tiene dueño, medido sobre cambios reales.

🗣️ **2 minutos:** Si los fallos de cambio no suben, la espera por coordinación baja y las excepciones caducan de verdad, la gobernanza está en su punto. Añadir más controles sin un fallo que prevenir solo añadiría espera. Se revisa periódicamente con las mismas métricas.

🔬 **El detalle:** La gobernanza suficiente es la mínima que sostiene las garantías; su éxito se nota en lo que no pasa.

## 📖 06 — Caso completo de system design y estrategia evolutiva

### 1. 🟢 ¿Qué aclaras antes de dibujar el sistema?

⏱️ **30 segundos:** Qué significa confirmar una compra, si se permite esperar el pago, cuánto dura una reserva, qué picos hay, qué pérdida es aceptable y quién opera el sistema.

🗣️ **2 minutos:** Cada respuesta cambia el diseño: si no se admite pago pendiente, el proveedor entra en el camino síncrono; si la reserva dura minutos, hay que decidir qué pasa con pagos tardíos; si opera un solo equipo, varios servicios son una carga. Pregunto también por cifras de pico y distribución, y confirmo las premisas en voz alta antes de dibujar.

🔬 **El detalle:** Preguntar no es perder tiempo: es lo que el entrevistador evalúa en los primeros minutos.

### 2. 🟢 ¿Qué diferencia hay entre aceptación y completitud en el SLO?

⏱️ **30 segundos:** La aceptación mide si la petición recibe rápido una identidad durable o un rechazo; la completitud mide si el pedido llega a un estado terminal en un plazo.

🗣️ **2 minutos:** Un sistema puede aceptar el 99,9 % en un segundo y dejar la mitad de los pedidos en pendiente durante horas. Por eso hay dos objetivos: uno para la respuesta y otro para la completitud, por ejemplo el 99 % terminal en cinco minutos con el proveedor normal. Y se vigila la antigüedad de los pendientes que quedan fuera.

🔬 **El detalle:** Medir solo aceptación premia respuestas rápidas que no terminan nada; medir solo completitud esconde latencia de cara al cliente.

### 3. 🟢 ¿Qué representa la cifra de 100 compras por segundo y qué no dice?

⏱️ **30 segundos:** El pico de operaciones de creación que el diseño debe soportar; no dice su distribución por producto ni qué recurso se satura.

🗣️ **2 minutos:** 100 compras por segundo con 10 lecturas cada una son unas 1.000 lecturas por segundo: un orden de magnitud que cabe en pocas réplicas. Pero si la mitad de las compras van al mismo SKU en una campaña, el cuello es la fila de ese SKU, no la CPU. La cifra sirve para dimensionar; la distribución, para encontrar el cuello.

🔬 **El detalle:** Es un supuesto del ejercicio; en una entrevista conviene preguntar de dónde sale y si es media o pico.

### 4. 🟢 ¿Qué confirma la transacción local de `CreateOrder`?

⏱️ **30 segundos:** El pedido pendiente, la reserva de cada línea y el trabajo durable para `payments`, todos juntos o ninguno.

🗣️ **2 minutos:** Esa transacción garantiza que no exista un pedido sin reserva ni un pago que nadie vaya a procesar. Sin stock, no se confirma nada parcial. La autorización del proveedor queda fuera, porque es un efecto externo que la base no puede deshacer, y se resuelve después desde la fila de trabajo.

🔬 **El detalle:** El pedido no pasa a confirmado en esa transacción: se confirma cuando llega la autorización, en otra transacción local.

### 5. 🟢 ¿Qué papel tiene `notifications` en el flujo y qué no puede decidir?

⏱️ **30 segundos:** Comunica al cliente los cambios de estado que `orders` ya confirmó; no decide si hay stock ni si el pago se hizo.

🗣️ **2 minutos:** El aviso se persiste como trabajo cuando `orders` confirma el pedido, y un worker lo entrega. Si el canal de correo falla, el aviso se retrasa y se reintenta, pero la compra sigue confirmada. `notifications` nunca deduce éxito de haber enviado la solicitud de pago.

🔬 **El detalle:** Sacar el aviso del camino síncrono es lo que evita que un proveedor de correo lento tumbe checkout.

### 6. 🟡 ¿Cómo respondes a una respuesta perdida después del commit?

⏱️ **30 segundos:** El cliente reintenta con la misma identidad de intención y recibe el mismo pedido, sin crear otro.

🗣️ **2 minutos:** Si el commit ocurrió pero la respuesta no llegó, el cliente no sabe si compró. Con una clave de intención persistida, el reintento encuentra la operación y devuelve su estado; sin ella, crearía un segundo pedido y una segunda reserva. Por eso el paso 3 devuelve una identidad consultable y el cliente la reutiliza.

🔬 **El detalle:** La misma clave con otro contenido se rechaza como conflicto, no se trata como la misma intención.

### 7. 🟡 ¿Por qué no confirmar el pedido en cuanto el proveedor autoriza?

⏱️ **30 segundos:** Porque la reserva puede haber vencido y la confirmación es una transición de `orders` que exige reserva válida y autorización suficiente a la vez.

🗣️ **2 minutos:** El worker registra la autorización; después `orders` comprueba que la reserva sigue viva y confirma en una transacción local. Si la reserva venció, la renueva bajo las reglas de `inventory` o compensa el pago. Confirmar en cuanto el proveedor responde podría dejar un pedido pagado sin stock.

🔬 **El detalle:** Separar «pago autorizado» de «pedido confirmado» es lo que permite manejar el caso límite sin estados ambiguos.

### 8. 🟡 ¿Qué cambia al replicar el artefacto, y qué deja de poder vivir en memoria?

⏱️ **30 segundos:** Aumenta la capacidad de cómputo y las conexiones a la base; deja de poder vivir en memoria la sesión exclusiva, los jobs sin coordinación y las cachés que deciden reservas.

🗣️ **2 minutos:** Con varias réplicas, cualquier estado local se vuelve distinto en cada una: una sesión en memoria se pierde al cambiar de réplica y un job programado se ejecuta tantas veces como réplicas haya. Por eso la sesión va a un almacén compartido, los jobs usan lease en la base y el stock se decide siempre en la base.

🔬 **El detalle:** Más réplicas también significan más pools de conexiones contra la misma base; el total se dimensiona contra su límite.

### 9. 🟡 ¿Qué te sugiere la ley de Little con 100 compras/s y 0,1 s, y qué no te dice?

⏱️ **30 segundos:** Unas diez creaciones simultáneas en régimen estable; no dice cuántas conexiones hacen falta, ni el p99, ni cómo se reparte la carga.

🗣️ **2 minutos:** La ley de Little relaciona concurrencia, throughput y tiempo: 100 por segundo por 0,1 s dan diez en curso de media. Es útil para ver que el orden de magnitud es pequeño. Pero los picos, la cola de espera y un SKU caliente pueden multiplicar la concurrencia real; eso se ensaya con carga, no se deduce de la media.

🔬 **El detalle:** Si el tramo local se alarga, por ejemplo por esperas de lock, la concurrencia crece en proporción aunque el tráfico no cambie.

### 10. 🟡 ¿Qué cuello puede ocultar una CPU baja en este diseño?

⏱️ **30 segundos:** La espera en recursos compartidos: locks sobre un SKU caliente, el pool de conexiones o una consulta lenta.

🗣️ **2 minutos:** Si checkout va lento con la CPU al 30 %, el tiempo se va esperando, no calculando. Una traza por etapa muestra dónde: esperando conexión, esperando el lock de una fila o en una consulta sin índice. Añadir réplicas no ayuda, y puede empeorar si cada una abre más conexiones contra la misma base.

🔬 **El detalle:** Por eso el orden es traza primero y perfil de CPU después, solo si la traza apunta al proceso.

### 11. 🟡 ¿Dónde usarías caché sin comprometer el stock?

⏱️ **30 segundos:** En el catálogo y en las lecturas que toleran unos segundos de retraso; nunca en la decisión de reservar.

🗣️ **2 minutos:** Las 1.000 lecturas por segundo son sobre todo catálogo y consultas de pedidos, que admiten caché con frescura acordada e invalidación. La disponibilidad que se muestra puede venir de caché; la que decide la reserva se lee y se resta en la base del propietario, en la misma sentencia. Cachear el stock para reservar rompería la invariante.

🔬 **El detalle:** Una caché necesita dueño, clave, TTL o invalidación y comportamiento ante fallo; sin eso sirve datos viejos sin avisar.

### 12. 🟡 ¿Qué observas en un pago pendiente para saber si el sistema va bien?

⏱️ **30 segundos:** La antigüedad del pendiente más antiguo, cuántos hay por estado y las divergencias con el proveedor.

🗣️ **2 minutos:** Un volumen estable de pendientes puede esconder casos que llevan horas atascados; la edad lo revela. Las divergencias —autorizaciones que el proveedor tiene y nosotros no— dicen si la reconciliación es correcta. Y el número de casos que llegan a revisión indica cuánto trabajo manual genera el diseño.

🔬 **El detalle:** Una alerta por edad del pendiente más antiguo es más útil que una por tamaño de cola.

### 13. 🟡 ¿Qué prueba priorizas para dos workers que reciben el mismo trabajo?

⏱️ **30 segundos:** Una prueba concurrente contra la base real que lance los dos workers sobre el mismo trabajo y compruebe que el efecto ocurre una sola vez.

🗣️ **2 minutos:** La prueba demuestra que el reclamo con lease o `SKIP LOCKED` evita que los dos tomen el trabajo a la vez, y que, si igualmente coinciden, la clave de la operación deduplica el efecto. Se repite varias veces, porque una carrera es probabilística. Un mock no sirve: el comportamiento está en la base.

🔬 **El detalle:** Si el efecto es externo, la deduplicación depende de que el proveedor respete la clave; esa parte se prueba con un simulador.

### 14. 🟡 ¿Cómo despliegas una nueva representación del estado del pedido sin romper réplicas viejas?

⏱️ **30 segundos:** Con expand-contract: añado la representación nueva sin quitar la vieja, cambio escritores y lectores, y retiro la vieja en otro release.

🗣️ **2 minutos:** Durante el despliegue conviven réplicas viejas y nuevas sobre el mismo esquema, así que todo estado intermedio debe servir a las dos. Primero se añade la columna o el valor nuevo, las réplicas nuevas escriben ambos, un backfill completa los datos, se cambian los lectores y, cerrada la ventana de rollback, se contrae. La migración es un paso propio, no un efecto del arranque.

🔬 **El detalle:** El rollback del código solo es seguro mientras la versión vieja entienda los datos nuevos; por eso la contracción va al final.

### 15. 🟡 ¿Qué constituye una alternativa distribuida defendible en este caso?

⏱️ **30 segundos:** Extraer una sola capacidad cuando una restricción lo pide —aislamiento o cadencia— con migración de datos, contrato y criterios de cancelación.

🗣️ **2 minutos:** Por ejemplo, `payments` como servicio si el regulador exige aislar sus datos o si su equipo necesita desplegar a otro ritmo. La alternativa se defiende con lo que compra y lo que cuesta: contratos remotos, estado incierto entre procesos y una guardia más. Extraer los cuatro módulos a la vez no es defendible sin razones para cada uno.

🔬 **El detalle:** Presentar la alternativa demuestra criterio: el entrevistador quiere ver que sabes cuándo cambiarías de opinión.

### 16. 🟡 ¿Qué dejas explícitamente fuera del diseño inicial y por qué?

⏱️ **30 segundos:** Múltiples regiones, un event store global, un broker y una plataforma interna general, porque ningún requisito del ejercicio los pide.

🗣️ **2 minutos:** Cada uno añade operación y coste sin una restricción que los compre. Los dejo fuera explícitamente y digo qué los traería de vuelta: un requisito de disponibilidad regional, otros consumidores de los eventos o varios equipos que necesiten una plataforma común. Nombrar lo que se pospone es tan importante como lo que se construye.

🔬 **El detalle:** Lo que no se pospone es la identidad de las operaciones, la recuperación del pago y la propiedad de los datos.

### 17. 🟠 ¿Cómo ajustas el roadmap si falla la prueba de concurrencia del stock en la semana 1?

⏱️ **30 segundos:** Detengo el avance: la invariante de stock es la base del resto, y la semana 2 no empieza hasta que la prueba pase.

🗣️ **2 minutos:** Analizo la causa —una lectura y escritura en la aplicación en lugar de un `UPDATE` condicional, un bloqueo mal ordenado— y la corrijo con su prueba. El roadmap se desplaza, no se salta: construir el pago encima de una reserva que sobrevende multiplicaría el problema. Informo del retraso con su motivo.

🔬 **El detalle:** La condición para continuar de cada semana existe precisamente para este caso: evita avanzar sobre una garantía rota.

### 18. 🟠 ¿Qué harías ante una cola de avisos que crece durante una campaña?

⏱️ **30 segundos:** Proteger la compra, que no depende de los avisos, y averiguar por qué crece: proveedor de correo lento, worker insuficiente o trabajos que fallan siempre.

🗣️ **2 minutos:** Como el aviso está fuera del camino síncrono, checkout sigue funcionando. Miro la edad del aviso más antiguo y la tasa de fallos; ajusto la concurrencia del worker si el canal lo soporta, aplico espera creciente si el canal está saturado y aparto los trabajos venenosos tras un máximo de intentos. No descarto avisos en silencio para mejorar la métrica.

🔬 **El detalle:** Si la cola compite por recursos con checkout, un cupo propio para el worker evita que el problema cruce al flujo principal.

### 19. 🟠 ¿Cómo tratarías un proveedor de pagos caído durante horas?

⏱️ **30 segundos:** Los pedidos se aceptan en pendiente, el worker reintenta con espera creciente y alerta por edad; al volver el proveedor, se reconcilia sin tormenta.

🗣️ **2 minutos:** Durante la caída, los clientes ven su pedido registrado y en proceso de pago; las reservas pueden necesitar renovación según su plazo. Al recuperarse el proveedor, el worker procesa los pendientes a un ritmo limitado para no tumbarlo de nuevo, y consulta por clave los que quedaron inciertos. Los que superan el plazo pasan a revisión.

🔬 **El detalle:** Hay que decidir con negocio qué pasa con las reservas de pedidos cuyo pago tarda horas; es una política, no un detalle técnico.

### 20. 🟠 ¿Qué harías si el negocio prohíbe el estado pendiente de pago?

⏱️ **30 segundos:** El proveedor entra en el camino síncrono con un presupuesto de tiempo, y el resultado incierto sigue existiendo: se decide qué ve el cliente cuando el plazo vence.

🗣️ **2 minutos:** Sin pendiente, el pedido solo se confirma si la autorización llega a tiempo; si no llega, se rechaza de cara al cliente, pero el cobro pudo hacerse y hay que anularlo o conciliarlo. Eso empeora disponibilidad y conversión ante un proveedor lento. Presento ese coste a negocio y pregunto si un pendiente de segundos es aceptable.

🔬 **El detalle:** Prohibir el pendiente no elimina la incertidumbre del proveedor; solo la esconde en un rechazo que puede ser falso.

### 21. 🟠 ¿Cómo verificas que puedes recuperar el sistema desde un backup?

⏱️ **30 segundos:** Restaurando de verdad, en un entorno aparte, y comprobando datos, tiempo de recuperación y la reconciliación con el proveedor.

🗣️ **2 minutos:** Un backup que nunca se restauró es una hipótesis. El ensayo mide cuánto se tarda, qué datos se pierden entre el backup y el fallo, y cómo se reconcilian pagos que el proveedor tiene y la base restaurada no. Se repite periódicamente, porque los esquemas y volúmenes cambian.

🔬 **El detalle:** Restaurar la base no deshace efectos externos: las autorizaciones del proveedor siguen ahí y hay que casarlas con la base restaurada.

### 22. 🟠 A mitad de la entrevista aparecen tres equipos con cadencias distintas. ¿Qué cambias?

⏱️ **30 segundos:** Reabro la matriz en voz alta: con cadencias distintas medidas, una capacidad puede justificar su propio despliegue.

🗣️ **2 minutos:** Pregunto qué capacidades tiene cada equipo y cuánto les bloquea el release común. Si el equipo de pagos necesita desplegar a diario y el resto no, propongo mantener el monolito modular y extraer `payments` con su migración y su contrato. Si los tres comparten la invariante de pedido y reserva, los mantengo juntos aunque haya más equipos.

🔬 **El detalle:** El cambio de requisito es una prueba de flexibilidad: el entrevistador quiere ver que el diseño se ajusta con argumentos, no que se defiende.

### 23. 🟠 ¿Cómo cierras la entrevista si faltan cifras?

⏱️ **30 segundos:** Declaro los supuestos, propongo lo más reversible que cumple las garantías y nombro la medición que confirmaría o refutaría la propuesta.

🗣️ **2 minutos:** Por ejemplo: «supuse un pico de 100 compras por segundo; si el real fuera diez veces mayor, revisaría la contención del stock antes que la topología». Cierro con qué construiría primero, qué pospongo y qué dato me haría cambiar de idea. Eso muestra criterio aunque falten números.

🔬 **El detalle:** Inventar cifras para parecer preciso es peor que declarar un supuesto; el entrevistador suele detectarlo.

### 24. 🟠 ¿Cuándo consideras terminado el roadmap propuesto?

⏱️ **30 segundos:** Cuando las tres semanas cumplieron sus condiciones, el SLO y la recuperación están demostrados y ninguna evidencia pide otra inversión.

🗣️ **2 minutos:** La revisión de la semana 4 decide con datos: si no aparece un cuello ni una coordinación real, la evolución propuesta termina y el sistema se opera tal cual. Si aparece, se abre una nueva decisión con la matriz. Terminar el roadmap no significa congelar el sistema, sino no invertir sin evidencia.

🔬 **El detalle:** Un roadmap sin criterio de fin tiende a llenarse de trabajo que nadie pidió.

## 🎤 Respuestas de la simulación

### S1. 🟢 ¿Qué debe encabezar una recomendación de arquitectura?

⏱️ **30 segundos:** La restricción o el problema que la justifica, dicho con evidencia: qué garantía hay que conservar y qué dato sostiene la necesidad de cambiar.

🗣️ **2 minutos:** Empezar por la topología —«propongo microservicios»— invita a discutir gustos. Empezar por «pedido y reserva deben confirmarse juntos y el pico medido es de 40 compras por segundo» lleva la conversación a lo verificable. Después vienen la opción, su coste, la evidencia que falta y la señal de revisión.

🔬 **El detalle:** Si no hay un problema que resolver, la recomendación honesta puede ser no cambiar la arquitectura, con una fecha para revisarlo.

### S2. 🟢 ¿Qué primera mejora harías ante un dominio todavía cambiante?

⏱️ **30 segundos:** Límites internos baratos de mover —un monolito, simple o modular— y registrar qué cambios reales cruzan esos límites.

🗣️ **2 minutos:** Con un dominio que cambia cada semana, un contrato remoto fijaría fronteras que todavía no se conocen y haría caro corregirlas. Dentro de un despliegue, mover una regla de un módulo a otro es un commit. La mejora útil es hacer visibles los límites y medir dónde se concentran los cambios para ajustarlos con evidencia.

🔬 **El detalle:** Lo que sí conviene fijar desde el principio es la propiedad de los datos y la identidad de las operaciones críticas.

### S3. 🟢 ¿Qué hace útil un roadmap evolutivo?

⏱️ **30 segundos:** Que cada paso tiene entrega, responsable, condición para continuar y un punto de revisión donde se decide con evidencia.

🗣️ **2 minutos:** Un roadmap que solo lista fases es una promesa; uno útil dice qué debe ser verdad para seguir —invariantes verificadas, SLO demostrado— y qué pasa si no lo es. También dice cuándo termina: si los supuestos se sostienen, la evolución se detiene en lugar de seguir añadiendo piezas.

🔬 **El detalle:** Las fechas de un roadmap de entrevista son supuestos; lo que se evalúa es la lógica de las condiciones, no el calendario.

### S4. 🟢 ¿Qué conserva una decisión reversible?

⏱️ **30 segundos:** La posibilidad de volver atrás a un coste acotado si la hipótesis resulta falsa.

🗣️ **2 minutos:** Una fachada, un worker del mismo artefacto o una regla en CI se deshacen con un despliegue. Copiar datos a una nueva autoridad, publicar un contrato a terceros o asumir una guardia permanente no. Una decisión reversible permite aprender en producción sin comprometerse; por eso las primeras acciones de una evolución suelen serlo.

🔬 **El detalle:** La reversibilidad hay que ensayarla: un camino de vuelta que nunca se probó no es reversible en la práctica.

### S5. 🟡 ¿Cómo decides entre optimizar y extraer?

⏱️ **30 segundos:** Mido el recurso limitante: si una optimización local lo resuelve, no extraigo; extraigo solo si separar el recurso es lo que da capacidad.

🗣️ **2 minutos:** Si checkout va lento por una consulta sin índice, un índice lo resuelve en horas y extraer `inventory` no cambiaría nada, porque seguiría usando la misma consulta y la misma base. Si una capacidad tiene una carga distinta que compite con el resto, aislarla —primero como worker, después como servicio si hace falta— sí compra algo.

🔬 **El detalle:** El experimento se conserva solo si mejora el SLO bajo la misma carga y no empeora corrección ni coste por operación.

### S6. 🟡 ¿Qué preguntas a quien promete releases independientes?

⏱️ **30 segundos:** Qué cambios concretos esperan hoy por el release común, cuánto esperan y qué otras dependencias —datos, aprobaciones, guardia— seguirían atándolos.

🗣️ **2 minutos:** Un servicio propio no da releases independientes si sigue compartiendo esquema, si su contrato obliga a desplegar consumidores o si cada cambio necesita aprobación de otro equipo. Pido ver cambios recientes y dónde esperaron. Si la espera viene de aprobaciones, se resuelve sin extraer.

🔬 **El detalle:** La promesa se verifica después: si tras separar el componente sigue saliendo con los demás, la independencia era nominal.

### S7. 🟡 ¿Cómo eliges una costura del legado?

⏱️ **30 segundos:** Por frecuencia de cambio y defectos, que tenga una salida observable, un dueño y un alcance de datos identificable.

🗣️ **2 minutos:** La liberación de reservas, con regresiones frecuentes y escritores repartidos, es una buena candidata: duele, cambia a menudo y su comportamiento se puede caracterizar. Un módulo grande y estable no lo es, por feo que sea. La costura se pone donde se decide la regla, detrás de una fachada.

🔬 **El detalle:** El historial de cambios orienta, pero se confirma con accesos SQL y trazas para no confundir reformateos con acoplamiento.

### S8. 🟡 ¿Qué protege una matriz sin puntuación?

⏱️ **30 segundos:** Que una restricción no negociable quede compensada por muchas ventajas menores.

🗣️ **2 minutos:** Si la opción distribuida suma puntos en escalabilidad y autonomía pero rompe el commit conjunto de pedido y reserva, una puntuación podría hacerla ganar. La matriz sin puntuación filtra primero por restricciones y solo después ordena por coste, así que esa opción queda fuera. Protege las garantías de ser promediadas.

🔬 **El detalle:** También evita la falsa precisión: dos opciones con 7,3 y 7,1 puntos no son distinguibles con datos de este tipo.

### S9. 🟡 ¿Qué coste organizativo incluyes al extraer?

⏱️ **30 segundos:** La guardia nueva, la carga cognitiva del equipo que se queda el servicio y la coordinación de contratos entre equipos.

🗣️ **2 minutos:** Extraer `payments` significa que alguien atiende sus incidentes de noche, entiende su reconciliación y mantiene su contrato con los consumidores. Si ese equipo ya está al límite, la extracción traslada el problema en lugar de resolverlo. Se evalúa la capacidad antes y se mide la carga de guardia después.

🔬 **El detalle:** El coste organizativo suele subestimarse porque no aparece en el diagrama; aparece en las rotaciones de guardia.

### S10. 🟡 ¿Qué debe probar un ensayo de rollback?

⏱️ **30 segundos:** Que se puede volver al estado anterior sin perder datos ni operaciones, en un tiempo conocido, con el procedimiento que se usaría de verdad.

🗣️ **2 minutos:** Para un cambio de código, basta con desplegar la versión anterior y comprobar que entiende los datos. Para una migración con cambio de autoridad, el ensayo incluye devolver al origen lo escrito en el destino y verificar que coincide. Se mide cuánto tarda y qué se pierde, y se ensaya antes de necesitarlo.

🔬 **El detalle:** Si el ensayo revela que la vuelta no es posible, se declara recuperación hacia adelante y se diseña una pausa segura; es mejor saberlo antes.

### S11. 🟡 ¿Cómo evitas una reescritura paralela interminable?

⏱️ **30 segundos:** Recuperando una costura vertical a la vez, en la línea principal, con cada paso integrado y medido.

🗣️ **2 minutos:** En lugar de construir el sistema nuevo al lado, se pone una fachada delante de una capacidad del legado, se pasan los consumidores por ella y se cambia el interior. Cada paso entrega valor y se puede revertir. Si una costura no mejora la evidencia, se detiene la expansión sin haber gastado meses en un sistema paralelo.

🔬 **El detalle:** El método Mikado ayuda cuando el orden de los pasos no se conoce: se intenta, se anotan los prerrequisitos, se revierte y se empieza por las hojas.

### S12. 🟡 ¿Qué señal permite detener modularización?

⏱️ **30 segundos:** Que los cambios relevantes ya quedan contenidos y el beneficio de otra costura no compensa su coste.

🗣️ **2 minutos:** La modularización no persigue un árbol perfecto. Si las capacidades que más cambian lo hacen dentro de un módulo, con menos regresiones y sin esperas entre equipos, y lo que queda apenas cambia, seguir cuesta más de lo que aporta. Se detiene y se registra qué señal haría retomarla.

🔬 **El detalle:** Detenerse no es abandonar: las reglas en CI mantienen lo conseguido sin seguir invirtiendo.

### S13. 🟡 ¿Qué dices si el entrevistador pide elegir sin cifras?

⏱️ **30 segundos:** Declaro supuestos explícitos, elijo la opción más reversible que cumpla las garantías y digo qué dato me haría cambiar.

🗣️ **2 minutos:** «Sin cifras, supongo una carga moderada y un equipo; propongo un monolito modular porque es barato de ajustar, y lo revisaría si el pico supera cierto umbral o aparece un requisito de aislamiento.» Así la decisión es defendible y el entrevistador ve cómo razono bajo incertidumbre, sin inventar números.

🔬 **El detalle:** Preguntar por las cifras primero sigue siendo lo correcto; esto es para cuando el entrevistador decide no darlas.

### S14. 🟡 ¿Qué indica una mejora de lead time con más incidentes?

⏱️ **30 segundos:** Que se gana velocidad a costa de estabilidad, o que los cambios ahora rompen cosas que antes coordinaba alguien.

🗣️ **2 minutos:** Si tras dar autonomía a un equipo el tiempo de entrega baja pero los incidentes suben, puede faltar un control que antes hacía una aprobación manual, como las pruebas de consumidor. Analizo la causa de los incidentes antes de decidir. Lo normal es añadir el control automatizado que faltaba, no volver a la aprobación.

🔬 **El detalle:** Se comparan ambas métricas con la línea base; una mejora en una y una regresión en otra se deciden con el impacto en el negocio.

### S15. 🟡 ¿Cómo traduces una exigencia de aislamiento a diseño?

⏱️ **30 segundos:** Preguntando qué control concreto se exige y quién lo valida, y eligiendo el mecanismo más barato que lo cumpla.

🗣️ **2 minutos:** «Aislar los datos de pago» puede ser un permiso de base, cifrado, un esquema aparte o un entorno separado con credenciales y despliegue propios. Solo el último obliga a otra unidad de despliegue. Pido el texto del requisito y cómo se auditará, y diseño para ese control, no para la palabra «aislamiento».

🔬 **El detalle:** Si el control exige un entorno separado, se convierte en restricción dura y la extracción deja de ser opcional.

### S16. 🟡 ¿Qué debe medir el dueño de `payments`?

⏱️ **30 segundos:** Pendientes y su edad, divergencias con el proveedor, tasa de autorización, tiempo de sus releases y carga de guardia.

🗣️ **2 minutos:** Las primeras métricas dicen si la reconciliación funciona y si el dinero cuadra; el tiempo de release dice si la autonomía es real; la guardia dice si el equipo puede sostener el límite. Todas se relacionan con el SLO de compra, porque un `payments` rápido que deja pedidos sin confirmar no cumple su propósito.

🔬 **El detalle:** El dueño mide lo que puede cambiar; si una métrica depende de otro equipo, la frontera de responsabilidad está mal puesta.

### S17. 🟡 ¿Cómo cambia el diseño al pasar a otro lenguaje?

⏱️ **30 segundos:** Cambia la implementación de los mecanismos —transacciones, concurrencia, build—, no las garantías ni la topología.

🗣️ **2 minutos:** En Java la transacción puede ser declarativa, en Go es un `sql.Tx` explícito; la concurrencia del worker se limita con un pool, con goroutines contadas o con un semáforo. Pero la invariante de pedido y reserva, el pago incierto y los dueños de datos son los mismos. En una entrevista se explica dónde vive cada garantía en el lenguaje elegido.

🔬 **El detalle:** Cada plataforma tiene su trampa típica —auto-invocación, cliente global, `db` en lugar de `tx`—; conocerla es parte de la respuesta.

### S18. 🟡 ¿Qué aporta un experimento de cohorte?

⏱️ **30 segundos:** Aprender con tráfico real y un riesgo acotado: solo una parte de las operaciones va por la ruta nueva, y se puede volver atrás.

🗣️ **2 minutos:** Una cohorte estable manda siempre la misma operación por la misma ruta, así que la comparación es limpia y cada operación tiene un solo escritor. Si las métricas de la cohorte empeoran, se devuelve a la ruta vieja; si mejoran, se amplía. Es la forma de validar una migración sin apostar todo a un corte.

🔬 **El detalle:** La cohorte se asigna por entidad —pedido, pago—, no por petición, para que todos los pasos de una operación vayan por el mismo camino.

### S19. 🟡 ¿Cómo gestionas una dependencia compartida inevitable?

⏱️ **30 segundos:** Con un dueño explícito, un contrato pequeño y versionado, y una política de compatibilidad que permita a cada consumidor actualizar a su ritmo.

🗣️ **2 minutos:** Si la dependencia no se puede eliminar —una librería de autenticación, un esquema de eventos—, se reduce a lo estable, se le da un responsable que acepta cambios y se prueban los consumidores afectados. Lo que se evita es que contenga dominio que cambia con el negocio, porque entonces obliga a desplegar a todos juntos.

🔬 **El detalle:** Si la dependencia compartida cambia a menudo por razones de negocio, probablemente no debería estar compartida.

### S20. 🟡 ¿Qué aporta la fecha de revisión a un ADR?

⏱️ **30 segundos:** Obliga a volver a mirar la decisión con evidencia en un momento acordado, en lugar de cuando alguien se canse o cambie la moda.

🗣️ **2 minutos:** Un ADR con fecha de revisión deja claro que la decisión era una hipótesis con supuestos. En la fecha se comprueban: si se sostienen, la decisión se confirma; si no, se reabre con los datos nuevos. Además protege a quien decidió, porque registra qué sabía en su momento.

🔬 **El detalle:** La revisión también puede dispararse antes por una señal acordada, como un pico que supera un umbral.

### S21. 🟠 ¿Cambiar de topología puede empeorar calidad interna?

⏱️ **30 segundos:** Sí: distribuir sin límites internos claros puede repartir el desorden entre procesos y añadir red a un código que ya estaba acoplado.

🗣️ **2 minutos:** Si se extraen servicios de una bola de barro sin antes definir dueños de datos y contratos, cada servicio hereda dependencias ocultas y la calidad interna empeora: más difícil de probar, más difícil de cambiar. Por eso la modularización interna suele preceder a la distribución, y a veces la hace innecesaria.

🔬 **El detalle:** El camino inverso también ocurre: fusionar sin conservar módulos convierte un monolito distribuido en una bola de barro local.

### S22. 🟠 ¿Cancelar una extracción desperdicia todo el trabajo?

⏱️ **30 segundos:** No: los límites internos, el contrato y lo aprendido sobre los datos se conservan y mejoran el monolito.

🗣️ **2 minutos:** Para llegar a extraer hace falta una API clara, dueño de tablas y comprensión del flujo; todo eso sigue siendo valioso si se cancela. Cancelar porque la alternativa local resolvía el problema es una decisión correcta, no un fracaso. Lo que sí se pierde es el trabajo específico de la infraestructura del servicio nuevo.

🔬 **El detalle:** Acordar los criterios de cancelación antes de empezar hace que cancelar sea una decisión técnica y no una discusión política.

### S23. 🟠 ¿Puedes garantizar rollback después de cualquier migración?

⏱️ **30 segundos:** No: después de una transformación destructiva o de transferir la autoridad de los datos, volver atrás exige mover datos y puede no ser posible.

🗣️ **2 minutos:** Revertir código es sencillo mientras la versión anterior entienda los datos actuales. Borrar una columna, convertir valores o transferir escrituras a otro sistema rompe esa condición. Por eso se retrasa la contracción, se ensaya la vuelta y, cuando no es posible, se declara recuperación hacia adelante.

🔬 **El detalle:** Prometer rollback universal es un error de entrevista habitual; lo senior es decir exactamente hasta qué punto se puede volver.

### S24. 🟠 ¿La arquitectura puede resolver una disputa de autoridad por sí sola?

⏱️ **30 segundos:** No: la arquitectura hace cumplir una decisión de autoridad, pero la decisión la toman negocio y los equipos.

🗣️ **2 minutos:** Si dos equipos reclaman la misma tabla, los permisos o un contrato pueden garantizar un solo escritor, pero antes alguien tiene que decidir cuál. Esa decisión depende de quién responde por la invariante de negocio. Si no hay acuerdo, se escala a quien responde por el negocio; después, la arquitectura lo materializa.

🔬 **El detalle:** Presentar una disputa organizativa como problema técnico lleva a soluciones técnicas que no la resuelven.

### S25. 🟠 ¿El diseño final debe ser completamente conocido al empezar?

⏱️ **30 segundos:** No: se empieza con una hipótesis revisable y se deja que los cambios reales la ajusten.

🗣️ **2 minutos:** Diseñar el final completo al principio exige saber cosas que solo se aprenden operando: dónde se concentran los cambios, qué recurso se satura, cómo evoluciona el equipo. Lo que se necesita al empezar son garantías claras, límites baratos de mover y criterios de revisión. El diseño final emerge de decisiones sucesivas con evidencia.

🔬 **El detalle:** Sí conviene conocer las restricciones duras desde el principio; son lo que no cambia con el aprendizaje.

### S26. 🟠 En E1, ¿cómo ordenarías la extracción y cuándo la cancelarías?

⏱️ **30 segundos:** Fachada, contrato remoto, copia más captura de cambios, verificación, corte con drenaje y retirada; la cancelo si aparecen divergencias sin explicar, si la alternativa local basta o si no hay guardia capaz.

🗣️ **2 minutos:** Primero inventario escritores ocultos y pruebo la captura sin huecos; después pongo la fachada con prueba en sombra, sin cobros duplicados. En el corte bloqueo el escritor viejo, dreno, aplico lo último y verifico antes de activar el nuevo. Antes del corte, volver es desactivar el destino; después, exige devolver los datos. Los criterios de cancelación se fijan al empezar.

🔬 **El detalle:** La garantía que no se negocia es una autoridad única y ninguna operación confirmada perdida; cualquier paso que la ponga en duda detiene el avance.

### S27. 🟠 En E2, ¿qué restricción gobierna la decisión pese a los puntos de la matriz?

⏱️ **30 segundos:** La confirmación conjunta de pedido y reserva: si negocio la confirma como no negociable, descarta la opción distribuida por muchos puntos que tenga.

🗣️ **2 minutos:** Primero verifico el requisito con su dueño: ¿admite espera de segundos o compensación? Si no la admite y los datos viven en la misma base, la opción que rompe el commit conjunto queda fuera antes de comparar costes. Propongo un ensayo local que demuestre la transacción y registro qué cambio del requisito reabriría la decisión.

🔬 **El detalle:** Una garantía incumplida no se promedia con ventajas; es un filtro, no una puntuación.

### S28. 🟠 En E3, ¿qué entregarías durante la primera semana?

⏱️ **30 segundos:** Una caracterización de la cancelación, la mejora comercial entregada por un camino seguro y una fachada pequeña sobre la liberación de reservas.

🗣️ **2 minutos:** El primer día caracterizo la cancelación —repetida, vencida, inexistente— para tener red. La mejora urgente se entrega donde está hoy, con su prueba, sin mezclarla con la reestructuración. Después introduzco la fachada con la implementación vieja detrás y paso un consumidor. Al final de la semana hay entrega comercial y un primer paso medible.

🔬 **El detalle:** Reestructurarlo todo antes de la entrega pondría en riesgo ambas cosas; el adaptador transitorio es el precio aceptable.

### S29. 🟠 En E4, ¿cómo probarías autonomía sin aumentar carga de guardia?

⏱️ **30 segundos:** Con un ensayo acotado de un release autónomo y de una recuperación, midiendo la carga de guardia antes y después, y reduciendo primero las alertas no accionables.

🗣️ **2 minutos:** Antes de dar más autonomía, averiguo por qué espera a plataforma y qué alertas no sirven. Reduzco el ruido, ofrezco autoservicio para el release y apoyo temporal, y ensayo un despliegue y una recuperación sin ayuda. Si el ensayo sale bien sin aumentar la carga, amplío; si no, no asigno otra frontera a un equipo sobrecargado.

🔬 **El detalle:** La garantía es una recuperación sostenible con dueño; una autonomía que agota al equipo no la cumple.

### S30. 🟠 En E5, ¿cómo cerrarías tu propuesta con la información disponible?

⏱️ **30 segundos:** Resumiendo supuestos, lo que construiría primero, lo que pospongo y el primer experimento que confirmaría o refutaría la propuesta.

🗣️ **2 minutos:** «Supuse un pico moderado, pago con estado pendiente y un equipo: propongo un monolito modular con trabajo durable para pago y avisos. Lo primero, el flujo de pedido y reserva con prueba de concurrencia; pospongo broker y bases separadas. Si el pico real fuera mucho mayor o apareciera un requisito de aislamiento, revisaría la topología.» Así el cierre es trazable sin inventar certeza.

🔬 **El detalle:** El flujo trazable con garantías explícitas es lo que se evalúa; la topología concreta importa menos que su justificación.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [07 — Simulación de entrevista: Decisión, evolución y práctica](07-simulacion-de-entrevista.md).
