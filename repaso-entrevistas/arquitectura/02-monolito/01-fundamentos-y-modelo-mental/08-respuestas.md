# 08 — Respuestas: Fundamentos y modelo mental

> Solucionario de los capítulos `01`–`06` y de la simulación. Cada respuesta conserva el enunciado literal y separa
> una respuesta breve, una defensa de entrevista y el matiz de estudio.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--qué-es-una-arquitectura-monolítica) · [02](#-02--unidades-de-código-despliegue-ejecución-y-datos) · [03](#-03--monolito-tradicional-modular-y-big-ball-of-mud) · [04](#-04--acoplamiento-cohesión-y-razones-de-cambio) · [05](#-05--cuándo-elegir-un-monolito-y-antipatrones) · [06](#-06--estilos-de-estructura-interna-capas-clean-onion-y-vertical-slice) · [Simulación](#-respuestas-de-la-simulación)

## 📖 01 — Qué es una arquitectura monolítica

### 1. 🟢 ¿Qué dimensión define primero a una arquitectura monolítica?

⏱️ **30 segundos:** La unidad lógica de despliegue: la aplicación se construye, se versiona y se libera como un conjunto, aunque corra en muchas réplicas.

🗣️ **2 minutos:** Repositorio, proceso o base pueden variar sin cambiar la clasificación. Lo primero que compruebo es qué artefacto y qué versión se promueven juntos y qué se revierte junto; después evalúo la estructura interna, los datos y los equipos por separado. Si `orders`, `inventory`, `payments` y `notifications` salen siempre en el mismo release, la topología es monolítica.

🔬 **El detalle:** «Monolito» describe topología, no calidad ni edad: un sistema nuevo y bien modularizado puede serlo.

### 2. 🟢 ¿Por qué un monolito puede ejecutar varias réplicas?

⏱️ **30 segundos:** Porque cada réplica ejecuta el mismo artefacto y la misma versión: son copias equivalentes de una unidad, no servicios distintos.

🗣️ **2 minutos:** Un balanceador reparte tráfico entre instancias intercambiables de `commerce-v18`. Se escala la aplicación completa, no capacidades por separado, y cualquier réplica puede atender cualquier petición si el estado no vive en su memoria. Eso es escalado horizontal de un monolito, perfectamente normal.

🔬 **El detalle:** La condición práctica es que sesión, jobs y cachés críticas no dependan de una réplica concreta.

### 3. 🟢 ¿Qué diferencia hay entre aplicación desplegable y proceso?

⏱️ **30 segundos:** La aplicación desplegable es lo que se versiona y libera; el proceso es una ejecución de ese artefacto en una máquina.

🗣️ **2 minutos:** Una misma aplicación puede correr como varios procesos —réplicas, un worker con el mismo binario— y seguir siendo una unidad de despliegue. Y varios artefactos pueden acabar en un solo proceso, como plugins cargados. Confundir las dos cosas lleva a llamar «servicio» a cada proceso o a pensar que un proceso único garantiza modularidad.

🔬 **El detalle:** El proceso sí marca el destino de fallo compartido: si cae, cae todo lo que corre dentro.

### 4. 🟢 ¿Qué ventaja ofrece una llamada local entre `orders` e `inventory`?

⏱️ **30 segundos:** Semántica directa: devuelve, lanza un error o el proceso cae, sin serialización, sin timeouts de red y con la posibilidad de compartir transacción.

🗣️ **2 minutos:** Si `orders` llama a `inventory` en el mismo proceso, no hay fallos parciales de red ni versiones mixtas del contrato durante el despliegue, y la latencia es la de una función. Si los dos escriben en la misma base, el pedido y la reserva pueden confirmarse en un mismo `COMMIT`. Es simplicidad que la distribución obliga a reconstruir con mecanismos.

🔬 **El detalle:** La llamada local no elimina el acoplamiento de código ni de datos; solo quita la red de en medio.

### 5. 🟢 ¿Qué garantía puede conservar una transacción local?

⏱️ **30 segundos:** La atomicidad de escrituras que viven en la misma base: pedido y reserva se confirman juntos o no se confirma ninguno.

🗣️ **2 minutos:** Con `orders` e `inventory` en la misma base, la invariante «un pedido confirmado tiene su reserva» se cumple con un `COMMIT`, sin compensaciones ni estados intermedios visibles. Esa garantía no alcanza a efectos externos: la autorización del proveedor de pagos queda fuera y necesita su propia recuperación.

🔬 **El detalle:** Que la transacción sea posible no obliga a hacerla amplia; se limita a la invariante que protege.

### 6. 🟢 ¿Un monorepo demuestra que el sistema es monolítico?

⏱️ **30 segundos:** No: el monorepo describe dónde vive el código, no cómo se despliega.

🗣️ **2 minutos:** Un monorepo puede producir varios artefactos que se liberan por separado, y varios repositorios pueden ensamblarse en un único artefacto. Para clasificar la topología miro qué pipeline promueve qué artefacto, qué se revierte junto y qué versión corre en producción. El repositorio es evidencia sobre historial y permisos del código, no sobre el despliegue.

🔬 **El detalle:** Es una de las confusiones más frecuentes en entrevista: «tenemos un monolito porque está todo en Git».

### 7. 🟢 ¿Una imagen de contenedor equivale a un servicio autónomo?

⏱️ **30 segundos:** No: una imagen solo empaqueta una ejecución; puede contener el mismo artefacto que otras cien réplicas.

🗣️ **2 minutos:** La autonomía de un servicio exige decisiones, datos y despliegues independientes. Cuatro contenedores con la misma imagen y versión son cuatro réplicas de un monolito. Y cuatro imágenes distintas que siempre se liberan juntas y comparten tablas tampoco son servicios autónomos. El contenedor es un mecanismo de ejecución, no una frontera de negocio.

🔬 **El detalle:** Contar contenedores mide la topología de ejecución, que es justo lo que no decide la arquitectura.

### 8. 🟡 ¿Qué puedes inferir y qué no de un único artefacto desplegable?

⏱️ **30 segundos:** Puedo inferir que un release cambia la unidad completa y que las llamadas internas pueden ser locales; no puedo inferir modularidad, calidad ni ownership.

🗣️ **2 minutos:** Un artefacto único dice cómo se despliega el sistema, no cómo está organizado por dentro. Para saber si es modular o una bola de barro necesito ver cambios reales, imports, escrituras de tablas y equipos. La observación sostiene el diagnóstico de topología monolítica; el resto necesita otra evidencia.

🔬 **El detalle:** Separar observación, inferencia y diagnóstico evita saltar de «un JAR» a «código desordenado».

### 9. 🟡 ¿Por qué topología y calidad interna deben evaluarse por separado?

⏱️ **30 segundos:** Porque responden a preguntas distintas: cómo se despliega el sistema y qué tan contenidos quedan sus cambios.

🗣️ **2 minutos:** Un monolito puede estar muy bien modularizado y un sistema distribuido puede ser una bola de barro repartida por la red. Si se mezclan, se recomienda distribuir para arreglar calidad —lo que suele distribuir el desorden— o se da por buena una arquitectura porque tiene muchos servicios. Evaluarlas por separado permite atacar el problema real.

🔬 **El detalle:** La calidad interna se mide con cambios contenidos, dependencias dirigidas y propiedad de datos, no con la topología.

### 10. 🟡 ¿Qué coste de despliegue asume un monolito ante un cambio pequeño?

⏱️ **30 segundos:** Desplegar la unidad completa: un cambio de una línea en `notifications` obliga a construir, probar y liberar toda la aplicación.

🗣️ **2 minutos:** Eso implica un pipeline que valida el conjunto, un rollback que revierte todo y un riesgo que se comparte entre capacidades. Con buenos tests y despliegues frecuentes, el coste es pequeño; con pipelines lentos o releases mensuales, cada cambio espera a los demás. El coste es real, pero proporcional a cómo se opera, no inevitable.

🔬 **El detalle:** Técnicas como feature flags o despliegues progresivos reducen el riesgo sin cambiar la topología.

### 11. 🟡 ¿Cómo distingues una réplica de un servicio diferente?

⏱️ **30 segundos:** Por el artefacto y la versión: una réplica ejecuta lo mismo que las demás; un servicio distinto tiene su propio artefacto, su ciclo de versiones y sus datos.

🗣️ **2 minutos:** Miro qué imagen y qué versión corre cada proceso, qué pipeline lo produce y si puede desplegarse sin los otros. Veinte procesos con la misma versión son réplicas. Un proceso con otro artefacto, otro release y otras tablas es candidato a servicio, y se confirma viendo si de verdad cambia y se despliega por su cuenta.

🔬 **El detalle:** Un worker del mismo artefacto con otro punto de entrada sigue siendo parte del monolito.

### 12. 🟡 ¿Qué cambia si `notifications` corre como worker pero se libera junto con la aplicación?

⏱️ **30 segundos:** Cambia el destino de fallo y el escalado de ese proceso, pero no la unidad de despliegue: sigue siendo parte del monolito.

🗣️ **2 minutos:** Correr `notifications` como worker aparte permite escalarlo, aislar su CPU y que su caída no tumbe checkout. Pero si se construye del mismo código y se libera en el mismo release, versión y datos siguen unidos. Es aislamiento de runtime sin autonomía de despliegue, que muchas veces es exactamente lo que hace falta.

🔬 **El detalle:** Llamarlo «microservicio» confunde; es un proceso auxiliar del monolito.

### 13. 🟡 ¿Qué evidencia buscarías antes de llamar *big ball of mud* a un monolito?

⏱️ **30 segundos:** Cambios que atraviesan responsabilidades sin una invariante que lo justifique, escrituras cruzadas, ciclos, ownership difuso y pruebas que solo funcionan de extremo a extremo.

🗣️ **2 minutos:** La etiqueta necesita un patrón sostenido, no una impresión. Sigo cambios reales para ver cuántos módulos tocan, busco quién escribe cada tabla, dibujo el grafo de dependencias y pregunto quién puede predecir el impacto de un cambio. Si casi todo cambio se vuelve impredecible, el diagnóstico se sostiene.

🔬 **El detalle:** Un único artefacto o código antiguo no son evidencia de barro por sí solos.

### 14. 🟡 ¿Por qué una base compartida no basta para clasificar toda la arquitectura?

⏱️ **30 segundos:** Porque es una señal sobre datos, no sobre despliegue, código ni equipos.

🗣️ **2 minutos:** Una base puede alojar datos de módulos con dueños claros y permisos separados, o ser compartida por servicios que se despliegan por separado. Clasificar toda la arquitectura por la base ignora las otras monedas. La pregunta útil es quién escribe cada dato y qué se confirma atómicamente.

🔬 **El detalle:** En un sistema distribuido, una base compartida es evidencia parcial de monolito distribuido, nunca prueba suficiente.

### 15. 🟡 ¿Qué significa que el monolito sea una unidad lógica y no necesariamente física?

⏱️ **30 segundos:** Que lo que la define es cómo se versiona y libera, no si corre en un servidor o en muchos.

🗣️ **2 minutos:** Una unidad lógica puede ejecutarse en muchas réplicas, en varias zonas o como varios procesos del mismo artefacto, y seguir siendo un monolito. A la inversa, varios componentes en la misma máquina pueden ser unidades de despliegue distintas. La física de la ejecución es independiente de la unidad de cambio.

🔬 **El detalle:** Por eso «monolito» no significa «un servidor»: esa confusión alimenta el mito de que no escala.

### 16. 🟡 ¿Qué riesgo introduce compartir recursos de proceso?

⏱️ **30 segundos:** Que un consumo excesivo de una capacidad —memoria, CPU, conexiones— degrade a las demás dentro del mismo proceso.

🗣️ **2 minutos:** Si los reportes de fin de mes agotan el pool de conexiones, checkout falla aunque su código esté bien. Es el destino de fallo compartido del proceso. Se mitiga con cupos por workload, pools separados, colas acotadas o sacando el workload pesado a un worker, antes de pensar en servicios.

🔬 **El detalle:** Se detecta con métricas por módulo; sin atribución, el incidente parece un fallo genérico de la aplicación.

### 17. 🟡 ¿Cuándo una transacción amplia deja de ser una ventaja?

⏱️ **30 segundos:** Cuando incluye cosas que no protegen ninguna invariante, especialmente esperas de red: retiene locks y conexiones sin garantizar nada.

🗣️ **2 minutos:** Una transacción que envuelve pedido, reserva y la llamada al proveedor de pagos bloquea la fila del SKU mientras el proveedor tarda, y el rollback ni siquiera deshace el cobro. La transacción conviene alrededor de la invariante mínima; lo externo se registra dentro y se ejecuta después.

🔬 **El detalle:** También deja de ser ventaja cuando mezcla capacidades que podrían confirmarse por separado y solo comparten transacción por comodidad.

### 18. 🟠 Tres réplicas pierden sesiones al balancear tráfico. ¿Es un límite del monolito o del diseño de estado?

⏱️ **30 segundos:** Del diseño de estado: la sesión vive en la memoria de cada réplica; la topología no obliga a eso.

🗣️ **2 minutos:** Con la sesión en memoria local, cada vez que el balanceador cambia de réplica el usuario pierde su estado. Se resuelve moviendo la sesión a un almacén compartido o a un token, sin tocar la topología. La afinidad de sesión lo esconde temporalmente, a costa de balanceo desigual y de perder sesiones cuando cae una réplica.

🔬 **El detalle:** Un sistema de servicios con estado en memoria tendría el mismo problema; no es propio del monolito.

### 19. 🟠 `payments` necesita desplegar diez veces al día y el resto una vez al mes. ¿Qué evidencia falta antes de separarlo?

⏱️ **30 segundos:** Qué cambios concretos esperan por el release común, cuánto esperan y qué otras dependencias —datos, contrato, equipos— seguirían atando a `payments`.

🗣️ **2 minutos:** Una cadencia distinta es una razón posible para otra unidad de despliegue, pero hay que verificar que el bloqueo es el release y no un proceso de aprobación o un pipeline lento. También miro si `payments` escribe tablas ajenas o si su contrato obliga a desplegar a otros. Si se separa sin resolver eso, seguirá saliendo con el resto.

🔬 **El detalle:** A veces basta con un pipeline más rápido y despliegues frecuentes del monolito para que diez releases al día no sean un problema.

### 20. 🟠 Un equipo propone HTTP interno para «estar listo para microservicios». ¿Qué garantía perdería hoy?

⏱️ **30 segundos:** La llamada local con su transacción y su error directo, sin ganar ninguna autonomía de despliegue a cambio.

🗣️ **2 minutos:** HTTP interno introduce serialización, timeouts, reintentos y resultados inciertos entre módulos que siguen liberándose juntos. La transacción entre `orders` e `inventory` se rompe y hay que compensarla. Lo que prepara de verdad una extracción futura es una API interna clara y dueños de datos, no el protocolo.

🔬 **El detalle:** Si algún día se extrae un módulo, su contrato remoto se diseña con la latencia y los fallos de ese momento.

### 21. 🟠 Un fallo de memoria en reportes derriba checkout. ¿Qué opciones evaluarías antes de extraer un servicio?

⏱️ **30 segundos:** Cupos de memoria o conexiones para reportes, límites de lote y streaming, y sacar los reportes a un worker o a una réplica de lectura.

🗣️ **2 minutos:** El problema es que un workload secundario comparte recursos con checkout. Primero lo contengo dentro del proceso —límites de lote, cupos, colas acotadas—; si no alcanza, lo muevo a un worker del mismo artefacto o lo apunto a una réplica de lectura. Extraer un servicio solo tendría sentido si además necesita cadencia o datos propios.

🔬 **El detalle:** Se verifica provocando el mismo cierre de mes y midiendo que checkout conserva su SLO.

### 22. 🟠 La aplicación usa un repositorio por módulo, pero un solo release. ¿Cómo la clasificarías?

⏱️ **30 segundos:** Como un monolito: si hay un solo release, la unidad de despliegue es una aunque el código viva en varios repositorios.

🗣️ **2 minutos:** Los repositorios separan historial y permisos del código, y pueden ayudar a la modularidad si respetan límites. Pero si todo se ensambla y se libera junto, la topología es monolítica y los repositorios añaden coordinación de versiones entre ellos. Lo reviso con la pregunta de siempre: qué se promueve y se revierte junto.

🔬 **El detalle:** Esta combinación suele ser la peor de ambos mundos si los repositorios obligan a coordinar versiones para cada cambio.

### 23. 🟠 ¿Qué condición justificaría pagar serialización, timeouts y observabilidad distribuida?

⏱️ **30 segundos:** Una necesidad sostenida y medida de cadencia, aislamiento o escala independientes que el proceso común no puede dar a un coste razonable.

🗣️ **2 minutos:** La distribución se paga con serialización, timeouts, consistencia eventual y observabilidad distribuida. Compensa cuando una capacidad debe desplegarse a otro ritmo, aislarse por regulación o por fallos, o escalar aparte, y la frontera está entendida. Sin una de esas razones, el coste no compra nada.

🔬 **El detalle:** La condición también incluye capacidad organizativa: alguien tiene que operar y hacer guardia de la nueva frontera.

### 24. 🟠 ¿Cómo responderías a «los monolitos no escalan» sin prometer escalabilidad infinita?

⏱️ **30 segundos:** Diciendo que un monolito escala replicando su unidad y verticalmente, y que el límite real suele estar en la base u otro recurso compartido, igual que con servicios.

🗣️ **2 minutos:** Réplicas equivalentes detrás de un balanceador escalan el cómputo si no guardan estado local. Lo que limita suele ser la base, un pool o una consulta, y eso no se arregla partiendo el código. El monolito deja de escalar como unidad cuando una capacidad necesita recursos que el resto no, y entonces se aísla esa capacidad.

🔬 **El detalle:** No prometo escalabilidad infinita: todo sistema tiene un recurso limitante, y la respuesta senior es cómo encontrarlo.

## 📖 02 — Unidades de código, despliegue, ejecución y datos

### 1. 🟢 ¿Qué pregunta responde un repositorio?

⏱️ **30 segundos:** Qué historial y qué permisos comparte el código.

🗣️ **2 minutos:** El repositorio dice quién puede cambiar qué y cómo se ha versionado el código fuente. No dice qué se construye junto, qué se despliega junto ni qué datos se comparten. Por eso no sirve para clasificar la arquitectura: un monorepo puede alojar servicios independientes y varios repositorios pueden terminar en un solo artefacto.

🔬 **El detalle:** Sí afecta a la coordinación: cambios atómicos entre módulos son más fáciles en un monorepo.

### 2. 🟢 ¿Qué diferencia hay entre build y artefacto?

⏱️ **30 segundos:** El build es lo que se compila y valida junto; el artefacto es el paquete versionado que se entrega.

🗣️ **2 minutos:** Un workspace puede compilar cuatro módulos en un build y producir un solo JAR, o producir cuatro binarios. El build decide qué debe compilar junto; el artefacto decide qué se entrega y versiona. Separar módulos del build no implica artefactos separados, y varios artefactos pueden salir de un solo build.

🔬 **El detalle:** Conviene seguir qué comando produce qué artefacto; ahí suelen aparecer uniones que el diagrama no muestra.

### 3. 🟢 ¿Qué es una unidad de despliegue?

⏱️ **30 segundos:** Lo que se promueve y se revierte junto en producción.

🗣️ **2 minutos:** Puede coincidir con un artefacto, o varios artefactos pueden desplegarse siempre juntos en un release. Lo que importa es si una parte puede salir sin las otras. Si cuatro binarios los libera siempre el mismo pipeline, forman una unidad de despliegue aunque sean cuatro artefactos.

🔬 **El detalle:** La unidad de despliegue se observa en el pipeline y en las versiones que conviven en producción, no en el código.

### 4. 🟢 ¿Qué distingue un proceso de una réplica?

⏱️ **30 segundos:** Un proceso es una ejecución con su memoria y su destino de fallo; una réplica es un proceso equivalente a otros que atienden la misma carga.

🗣️ **2 minutos:** Tres réplicas de `commerce-v18` son tres procesos intercambiables. Un proceso de worker con el mismo artefacto no es una réplica del servidor web, porque atiende otra carga, pero sigue siendo el mismo despliegue. La distinción importa para escalar y para entender qué cae junto.

🔬 **El detalle:** Las réplicas multiplican también los recursos que abren, como conexiones a la base.

### 5. 🟢 ¿Qué pregunta responde una frontera transaccional?

⏱️ **30 segundos:** Qué cambios se confirman o se revierten juntos.

🗣️ **2 minutos:** La frontera transaccional decide qué invariantes se cumplen atómicamente, como pedido y reserva en un `COMMIT`. Es independiente del repositorio, del artefacto y del proceso: dos módulos del mismo proceso pueden no compartir transacción, y un proceso puede abrir varias transacciones. Solo alcanza a recursos que participan en ella.

🔬 **El detalle:** Un efecto externo, como autorizar un pago, nunca está dentro de la frontera de la base local.

### 6. 🟢 ¿Cuáles son las cinco monedas de una decisión arquitectónica?

⏱️ **30 segundos:** Código, datos, despliegue, runtime y equipos.

🗣️ **2 minutos:** Cada una responde una pregunta: qué cambia y compila junto, quién posee el estado y qué se confirma atómicamente, qué se libera junto, qué debe estar disponible para completar la operación, y quién decide y opera. Una decisión arquitectónica paga o ahorra en alguna de ellas, y decir cuál evita frases vagas como «añade complejidad».

🔬 **El detalle:** Rara vez todas apuntan en la misma dirección; la decisión elige qué moneda se paga.

### 7. 🟢 ¿Qué diferencia hay entre esquema lógico y base física?

⏱️ **30 segundos:** El esquema es una organización lógica de los datos dentro de un motor; la base física es la instancia que los almacena.

🗣️ **2 minutos:** Varios esquemas pueden convivir en una sola base física con permisos distintos, y un mismo esquema puede replicarse en varias. Separar esquemas hace visible la propiedad sin separar almacenamiento; separar bases físicas cambia operación, transacciones y disponibilidad.

🔬 **El detalle:** Por eso «una base por servicio» puede significar cosas muy distintas; conviene preguntar si es esquema, credencial o instancia.

### 8. 🟡 ¿Por qué un monorepo puede contener varios servicios autónomos?

⏱️ **30 segundos:** Porque el repositorio no determina el despliegue: cada servicio puede producir su artefacto y liberarse por su propio pipeline.

🗣️ **2 minutos:** En un monorepo, `payments` puede tener su build, su imagen y su release independientes, con datos propios. El monorepo facilita cambios atómicos entre servicios, pero no los obliga a desplegarse juntos. Lo que decide la autonomía es el pipeline y la propiedad de datos, no la carpeta.

🔬 **El detalle:** El riesgo es que la comodidad del monorepo invite a cambios que obligan a desplegar varios servicios a la vez.

### 9. 🟡 ¿Por qué varios repositorios pueden terminar en un monolito?

⏱️ **30 segundos:** Porque pueden ensamblarse en un único artefacto o liberarse siempre juntos.

🗣️ **2 minutos:** Si cuatro repositorios producen librerías que se empaquetan en un JAR, o cuatro servicios salen siempre en el mismo release, la unidad de despliegue es una. Los repositorios separados dan la apariencia de independencia y añaden coordinación de versiones. La clasificación se hace mirando el despliegue real.

🔬 **El detalle:** Es habitual en monolitos distribuidos: repositorios separados con un release train obligatorio.

### 10. 🟡 ¿Qué diferencia hay entre dependencia de código y flujo de ejecución?

⏱️ **30 segundos:** La dependencia de código es conocimiento estático —imports, tipos—; el flujo de ejecución es qué se llama realmente en runtime.

🗣️ **2 minutos:** `orders` puede importar la API de `inventory` y no llamarla en cada petición; y una interfaz puede invertir el import mientras la llamada sigue ocurriendo en el mismo sentido. Por eso se dibujan como grafos distintos: uno dice qué compila junto, el otro qué se ejecuta junto.

🔬 **El detalle:** Un análisis estático limpio no dice nada de qué debe estar disponible en runtime.

### 11. 🟡 ¿Qué diferencia hay entre flujo de ejecución y dependencia operativa?

⏱️ **30 segundos:** El flujo de ejecución dice quién llama a quién; la dependencia operativa dice qué debe estar disponible para completar la operación.

🗣️ **2 minutos:** Checkout puede no llamar directamente al proveedor de pagos y, sin embargo, necesitar que esté disponible, a través de otro componente. A la inversa, una llamada asíncrona está en el flujo pero no es obligatoria para responder. La dependencia operativa es la que define la disponibilidad del flujo.

🔬 **El detalle:** Un evento puede quitar una espera del flujo sin quitar la dependencia operativa si el resultado de negocio lo necesita.

### 12. 🟡 ¿Qué demuestra un import y qué no demuestra?

⏱️ **30 segundos:** Demuestra conocimiento estático entre módulos; no demuestra que la llamada ocurra, ni con qué frecuencia, ni que haga falta el otro disponible.

🗣️ **2 minutos:** Un import dice que un cambio en la API importada puede obligar a recompilar al importador. No dice si esa llamada está en el camino crítico ni si el acoplamiento es de datos o de despliegue. Contar imports es útil para el grafo de código y engañoso como medida de autonomía.

🔬 **El detalle:** Tampoco revela dependencias que no pasan por el código, como tablas compartidas o jobs que escriben datos ajenos.

### 13. 🟡 ¿Cómo puede una interfaz invertir código sin eliminar acoplamiento temporal?

⏱️ **30 segundos:** Porque cambia la dirección del import, pero el llamador sigue necesitando que la implementación responda en ese momento.

🗣️ **2 minutos:** Con inversión de dependencias, `orders` define una interfaz que `inventory` implementa, y el código de `orders` ya no importa a `inventory`. Pero cuando `orders` reserva, `inventory` tiene que estar disponible y responder: el acoplamiento temporal sigue igual. La inversión mejora el grafo de código, no el de runtime.

🔬 **El detalle:** Para quitar el acoplamiento temporal hace falta cambiar la promesa, por ejemplo aceptar un resultado posterior.

### 14. 🟡 ¿Qué evidencia usarías para identificar el despliegue real?

⏱️ **30 segundos:** Qué pipelines promueven qué artefactos, qué versiones conviven en producción y qué se revirtió junto en rollbacks anteriores.

🗣️ **2 minutos:** El despliegue real está en el historial de releases, no en el diagrama. Sigo un cambio desde el commit hasta producción, miro si otros componentes salieron con él y reviso rollbacks pasados. Si nunca se ha desplegado una parte por separado, la independencia es hipotética aunque la arquitectura la permita.

🔬 **El detalle:** Las versiones que conviven en producción durante un despliegue también revelan qué contratos tienen que ser compatibles.

### 15. 🟡 ¿Por qué un módulo de build no concede ownership de datos?

⏱️ **30 segundos:** Porque separa lo que compila junto, no quién puede escribir cada dato.

🗣️ **2 minutos:** Un módulo Maven o un paquete del workspace puede seguir usando un cliente de base global y escribir cualquier tabla. La propiedad de datos se establece con dueños declarados, permisos de base y controles sobre el acceso a datos. El build ayuda a separar código; los datos necesitan su propio mecanismo.

🔬 **El detalle:** Separar el build y dejar los datos compartidos sin dueño da una sensación de modularidad que la base desmiente.

### 16. 🟡 ¿Qué ganas y qué pagas al alinear build, artefacto y despliegue?

⏱️ **30 segundos:** Ganas simplicidad —un build, un artefacto, una release— y pagas liberar todo junto ante cualquier cambio.

🗣️ **2 minutos:** Alinear las tres unidades reduce coordinación técnica: no hay versiones mixtas entre módulos ni contratos remotos. El coste es que un cambio pequeño despliega el conjunto y que el pipeline valida todo. Es un buen trato mientras el pipeline sea rápido y los equipos no necesiten cadencias distintas.

🔬 **El detalle:** La decisión se revisa cuando esa alineación empieza a producir esperas medidas.

### 17. 🟡 ¿Cómo compararías un worker Node con una réplica de un binario Go?

⏱️ **30 segundos:** El worker de Node suele ser otro proceso con otra carga; la réplica de Go es una copia equivalente del mismo binario.

🗣️ **2 minutos:** Un worker de Node puede salir del mismo paquete y del mismo release, así que comparte despliegue aunque sea otro proceso; confundirlo con un servicio es la trampa habitual. Una réplica de un binario de Go atiende la misma carga que las demás. En ambos casos lo que decide es el artefacto y el release, no el runtime.

🔬 **El detalle:** Las dos plataformas pueden producir un solo artefacto con varios puntos de entrada; eso no crea unidades de despliegue nuevas.

### 18. 🟠 CI produce cuatro artefactos pero un pipeline siempre los libera juntos. ¿Qué autonomía existe?

⏱️ **30 segundos:** Poca: si un pipeline siempre los libera juntos, la unidad de despliegue es una aunque haya cuatro artefactos.

🗣️ **2 minutos:** Cuatro artefactos permiten despliegues independientes, pero no los garantizan. Compruebo si alguno ha salido solo alguna vez, si sus contratos toleran versiones mixtas y si comparten datos sin dueño. Si nunca salen por separado, es autonomía nominal: se paga la complejidad de varios artefactos sin obtener cadencia propia.

🔬 **El detalle:** A veces la unión es solo del pipeline y basta con separarlo; otras, el contrato o los datos la hacen necesaria.

### 19. 🟠 Dos equipos poseen carpetas distintas, pero ambos escriben `inventory`. ¿Qué unidad está mal definida?

⏱️ **30 segundos:** La propiedad de datos: las carpetas separan código, pero dos escritores de `inventory` significan que nadie posee ese estado.

🗣️ **2 minutos:** Aunque cada equipo tenga su carpeta, si ambos escriben las mismas tablas, las invariantes de stock no tienen un responsable y un cambio de esquema exige coordinar a los dos. Hay que declarar un dueño de escritura, migrar al otro equipo a su API y reforzarlo con permisos.

🔬 **El detalle:** La unidad de código está bien definida; la de datos y la de equipos, no.

### 20. 🟠 Un cambio de contrato compila sin tocar consumidores, pero obliga a desplegarlos juntos. ¿Qué grafos revisarías?

⏱️ **30 segundos:** El grafo de código y el de despliegue: compila sin tocar consumidores, pero el contrato runtime no tolera versiones mixtas.

🗣️ **2 minutos:** Un cambio de contrato puede ser compatible en compilación —por ejemplo, un campo renombrado en un DTO— y romper en runtime a consumidores que siguen enviando o esperando el formato viejo. Reviso qué versiones conviven durante el despliegue y si los lectores toleran el cambio. El problema es de compatibilidad, no de compilación.

🔬 **El detalle:** Las pruebas de consumidor contra las versiones desplegadas detectan este caso antes de producción.

### 21. 🟠 Un incidente aparece solo cuando conviven versiones durante rolling deployment. ¿Qué unidades relacionarías?

⏱️ **30 segundos:** Despliegue, runtime y datos: durante el rolling conviven versiones que leen y escriben el mismo esquema.

🗣️ **2 minutos:** Si una versión nueva cambia el formato de una columna o un contrato y la vieja sigue atendiendo tráfico, aparecen errores solo en esa ventana. Relaciono qué versiones estaban activas, qué esquema tenían y qué datos escribió cada una. La corrección es hacer compatible cada estado intermedio con todas las versiones vivas.

🔬 **El detalle:** Es el caso típico de expand-contract: el esquema intermedio debe servir a la versión N y a la N+1.

### 22. 🟠 Se propone dividir el repositorio para reducir coordinación. ¿Qué evidencia pedirías primero?

⏱️ **30 segundos:** Qué coordinación cuesta hoy y dónde: cambios que esperan a otros, conflictos de código y quién aprueba qué.

🗣️ **2 minutos:** Dividir el repositorio solo reduce coordinación si la coordinación viene del repositorio. Si viene de datos compartidos, de un release común o de equipos que deben aprobar, dividirlo añade coordinación de versiones sin quitar la otra. Pido ejemplos de cambios recientes y dónde esperaron antes de proponer nada.

🔬 **El detalle:** A veces la mejor respuesta es límites internos y propiedad de código dentro del mismo repositorio.

### 23. 🟠 `payments` está en otro proceso, pero comparte transacción mediante 2PC. ¿Qué independencia obtuvo y qué coste añadió?

⏱️ **30 segundos:** Obtuvo un proceso separado y quizá aislamiento de recursos; añadió un coordinador de transacciones y un acoplamiento de disponibilidad entre ambos.

🗣️ **2 minutos:** Con 2PC, `payments` sigue unido a `orders` en la moneda de datos: una transacción no confirma si el otro no responde, y los recursos quedan retenidos durante los fallos del coordinador. No ganó despliegue independiente real si el protocolo o el esquema los atan. Es la distribución con el acoplamiento de un monolito.

🔬 **El detalle:** Si la operación exige atomicidad entre ambos, suele ser más barato mantenerlos en el mismo proceso y la misma base.

### 24. 🟠 ¿Cómo presentarías un sistema que es independiente en código pero no en datos ni equipos?

⏱️ **30 segundos:** Nombrando la asimetría: independiente en código, unido en datos y equipos, y diciendo qué coste produce cada unión.

🗣️ **2 minutos:** En lugar de una etiqueta, describo cada moneda: el código se compila por separado, pero dos equipos escriben las mismas tablas y aprueban juntos los cambios. Esa asimetría es el hallazgo, y orienta la acción: asignar dueños de datos y autoridad antes de separar más el código.

🔬 **El detalle:** Una etiqueta prematura —«microservicios» o «monolito»— oculta justo la información que permite decidir.

## 📖 03 — Monolito tradicional, modular y *big ball of mud*

### 1. 🟢 ¿Qué dimensión describe la palabra monolito?

⏱️ **30 segundos:** La topología de despliegue y operación: una unidad que se construye y libera como conjunto.

🗣️ **2 minutos:** No describe si el código está bien o mal organizado, ni su edad. «Monolito tradicional», «monolito modular» y *big ball of mud* comparten la topología y difieren en estructura interna y en cómo cambian. Separar las tres preguntas —cómo se despliega, cómo se limita el código, cómo cambia en realidad— evita diagnósticos cruzados.

🔬 **El detalle:** Usar «monolito» como insulto mezcla topología con calidad y lleva a recomendar distribuir para arreglar código.

### 2. 🟢 ¿Qué caracteriza a una organización por capas técnicas?

⏱️ **30 segundos:** Agrupa el código por rol técnico —controllers, services, repositories—, de modo que cada capacidad atraviesa todas las capas.

🗣️ **2 minutos:** `CreateOrder` pasa por las cuatro carpetas y comparte tipos con otras capacidades en cada una. Es fácil de entender en sistemas pequeños y de dominio simple. El problema aparece cuando crecen las capacidades: un cambio de negocio toca todas las capas y nada impide que un servicio use el repositorio de otra capacidad.

🔬 **El detalle:** Las capas pueden seguir existiendo dentro de cada módulo; lo que cambia es la unidad principal de organización.

### 3. 🟢 ¿Qué caracteriza a un monolito modular?

⏱️ **30 segundos:** Una sola unidad de despliegue con límites internos verticales por capacidad, cada uno con API, dueño de datos y controles que hacen cumplir los límites.

🗣️ **2 minutos:** Conserva las ventajas locales —llamadas en proceso, transacciones— y contiene los cambios dentro de módulos. La clave no son las carpetas, sino que haya APIs deliberadas, dependencias dirigidas, propiedad de datos y una regla que falle cuando alguien cruza un límite. Sin eso, las carpetas por capacidad son decoración.

🔬 **El detalle:** Su coste es disciplina: el proceso compartido hace fácil saltarse los límites, y los controles existen para impedirlo.

### 4. 🟢 ¿Qué significa *modulith* en este recorrido?

⏱️ **30 segundos:** Un nombre para la combinación de módulos explícitos y despliegue monolítico; no es un framework ni una certificación.

🗣️ **2 minutos:** Algunas herramientas ayudan a construirlo —verifican dependencias entre módulos o publican eventos internos—, pero el *modulith* es una forma arquitectónica. Se puede tener sin ningún framework, con visibilidad del lenguaje y pruebas arquitectónicas, y se puede no tenerlo aunque se use un framework que lo promete.

🔬 **El detalle:** Lo que lo define se comprueba en los cambios reales: si quedan contenidos, hay modulith; si no, hay nombre.

### 5. 🟢 ¿Qué es una *big ball of mud*?

⏱️ **30 segundos:** Una estructura en la que cualquier parte parece depender de cualquier otra, con límites débiles y conocimiento disperso, según Foote y Yoder.

🗣️ **2 minutos:** Se reconoce en el trabajo diario: cambios pequeños que tocan varios dominios, datos escritos desde lugares sin dueño, ciclos, utilidades globales con reglas de negocio y nadie capaz de predecir el impacto de un cambio sin ejecutar todo. No significa código viejo ni muchas líneas.

🔬 **El detalle:** La etiqueta describe un patrón de cambio, no una causa; las causas pueden ser prisa, límites falsos o incentivos.

### 6. 🟢 ¿Una *big ball of mud* tiene que ser monolítica?

⏱️ **30 segundos:** No: un sistema distribuido también puede serlo, con el desorden repartido entre procesos.

🗣️ **2 minutos:** La red endurece las fronteras físicas, pero no corrige la propiedad difusa, los modelos compartidos ni los release trains. Servicios que escriben las tablas de otros, comparten una librería con todo el dominio y se despliegan juntos son una bola de barro con latencia. Distribuir no ordena; a veces solo encarece el desorden.

🔬 **El detalle:** Es el origen de muchos monolitos distribuidos: se extrajo sin antes definir límites internos.

### 7. 🟢 ¿Qué es una unidad de cambio interna?

⏱️ **30 segundos:** Una parte del sistema que puede cambiar por sus propias razones sin arrastrar a las demás, dentro de la misma unidad de despliegue.

🗣️ **2 minutos:** Un módulo bien definido es una unidad de cambio: una política nueva de reservas se implementa dentro de `inventory` sin tocar `orders`. Se reconoce porque los cambios reales quedan contenidos, no por el nombre de la carpeta. Es lo que un monolito modular añade a un monolito tradicional.

🔬 **El detalle:** La unidad de cambio no coincide necesariamente con una unidad de despliegue; varias pueden convivir en un artefacto.

### 8. 🟡 ¿Por qué una carpeta por capacidad no demuestra modularidad?

⏱️ **30 segundos:** Porque los imports y las escrituras pueden ignorarla: la carpeta muestra una intención, no un límite.

🗣️ **2 minutos:** `orders/` puede importar el repositorio de `inventory/` o escribir sus tablas con SQL, y el árbol seguirá pareciendo modular. La modularidad se comprueba siguiendo cambios reales, dibujando imports y escrituras, identificando la API que consumen los demás y viendo si una regla automatizada detectaría una violación.

🔬 **El detalle:** Una observación aislada —paquetes limpios— permite inferir intención; el diagnóstico exige cambios contenidos.

### 9. 🟡 ¿Qué garantías conserva un monolito modular?

⏱️ **30 segundos:** La colaboración local: llamadas en proceso y, cuando la invariante lo pide, transacciones locales entre módulos.

🗣️ **2 minutos:** Conserva lo que hace barato al monolito —sin serialización, sin fallos parciales de red, un commit para pedido y reserva— y añade contención de cambios. Es la combinación que permite a varios equipos trabajar en un solo despliegue sin pisarse, siempre que los límites se hagan cumplir.

🔬 **El detalle:** También conserva una opción futura: un módulo con API y dueño de datos es mucho más fácil de extraer si algún día hace falta.

### 10. 🟡 ¿Qué disciplina adicional exige un límite dentro del mismo proceso?

⏱️ **30 segundos:** Controles automatizados —compilador, pruebas arquitectónicas, CI— que impidan que la comodidad del proceso compartido erosione los límites.

🗣️ **2 minutos:** En un proceso, cualquier clase puede llamar a cualquier otra si el lenguaje lo permite, y con prisa alguien lo hará. La disciplina no puede depender de la memoria del equipo: necesita visibilidad del lenguaje, reglas que fallen en CI, permisos de base y revisión de las excepciones. Es el coste del monolito modular.

🔬 **El detalle:** Las reglas se introducen con un baseline para no bloquear el trabajo por la deuda que ya existe.

### 11. 🟡 ¿Cómo distingues edad del sistema y deterioro estructural?

⏱️ **30 segundos:** La edad es el tiempo que lleva el sistema; el deterioro es cuánto le cuesta cambiar. Se miden por separado.

🗣️ **2 minutos:** Un sistema de diez años puede entregar cambios de stock predecibles sin incidentes, y uno de seis meses puede ser impredecible. Miro cambios recientes, defectos por cambio, cuántos módulos toca cada cambio y la capacidad de predecir impacto. La antigüedad sola no justifica una modernización.

🔬 **El detalle:** Lo que sí envejece mal son las dependencias sin soporte y el conocimiento que se va con las personas.

### 12. 🟡 ¿Qué evidencia de cambios respalda el diagnóstico de barro?

⏱️ **30 segundos:** Cambios pequeños que tocan muchos dominios de forma recurrente sin una invariante que lo justifique, e impacto que nadie sabe predecir.

🗣️ **2 minutos:** Reviso una muestra de cambios representativos: cuántos archivos, módulos, tablas y equipos toca cada uno, y si había una razón de negocio que obligara a ello. Si la mayoría cruza límites de forma inesperada y las regresiones aparecen lejos del cambio, el diagnóstico de barro se sostiene.

🔬 **El detalle:** Un único cambio transversal puede ser legítimo —una regulación nueva—; lo que cuenta es el patrón.

### 13. 🟡 ¿Por qué los ciclos son evidencia y no un diagnóstico completo?

⏱️ **30 segundos:** Porque un ciclo puede reflejar una invariante real compartida o un límite mal puesto; hay que saber cuál antes de actuar.

🗣️ **2 minutos:** Si `orders` e `inventory` se necesitan mutuamente porque una regla vive repartida, el ciclo indica un límite equivocado; si protegen juntos una invariante, quizá deberían ser un solo módulo. El ciclo es una señal que obliga a preguntar, no una sentencia. La respuesta puede ser mover una regla, reducir un contrato o fusionar.

🔬 **El detalle:** Romper el ciclo con una interfaz sin cambiar la responsabilidad solo lo esconde.

### 14. 🟡 ¿Cuándo un monolito por capas puede ser suficiente?

⏱️ **30 segundos:** Cuando el dominio es pequeño o CRUD, el equipo cabe en una reunión y los cambios siguen siendo predecibles.

🗣️ **2 minutos:** Las capas son la estructura más barata de entender en esos casos, y hacerlas modulares por ceremonia añadiría interfaces sin proteger nada. Se revisa cuando el sistema crece por capacidades y cada cambio empieza a atravesar todas las capas, o cuando dos equipos se pisan en los mismos servicios.

🔬 **El detalle:** Un monolito por capas pequeño y sano no está «a medio camino» de nada: puede ser la opción proporcional.

### 15. 🟡 ¿Por qué distribuir puede endurecer un límite equivocado?

⏱️ **30 segundos:** Porque convierte un límite mal puesto en un contrato remoto, que es mucho más caro de corregir que una frontera interna.

🗣️ **2 minutos:** Dentro de un proceso, mover una regla de módulo es un commit. Entre servicios, exige versionar contratos, migrar datos y coordinar despliegues. Si el límite era equivocado, distribuirlo lo congela y cada cambio que lo cruza paga red y coordinación. Por eso conviene descubrir los límites localmente antes de distribuirlos.

🔬 **El detalle:** La red hace más visible el límite, pero no lo hace más correcto.

### 16. 🟡 ¿Qué demuestra un import rule y qué no demuestra?

⏱️ **30 segundos:** Demuestra la dirección estática del código entre paquetes; no demuestra propiedad de datos, cohesión ni que los cambios queden contenidos.

🗣️ **2 minutos:** Una regla de imports puede impedir que `orders` importe los internos de `inventory`, y es valiosa. Pero un `UPDATE` por SQL a la tabla de otro módulo la pasa sin problema, igual que un evento que ordena algo disfrazado. Se complementa con permisos de base y con métricas de cambio.

🔬 **El detalle:** Una regla verde con excepciones permanentes deja de ser un control y se vuelve decoración.

### 17. 🟡 ¿Qué cambia entre un paquete Java, uno Go y un ES module como mecanismos de límite?

⏱️ **30 segundos:** En Java el paquete da visibilidad package-private pero no jerarquía; en Go el paquete exporta por mayúscula y `internal/` limita imports; un ES module exporta lo que se marque, visible para todo el programa.

🗣️ **2 minutos:** En Java, una clase sin modificador es invisible fuera del paquete, pero un subpaquete no hereda privacidad. En Go, el compilador rechaza imports de `internal/` desde fuera de su padre. En TypeScript, lo exportado para un vecino lo está para todos, y el límite necesita `exports` del paquete o una regla del linter.

🔬 **El detalle:** Los tres protegen un límite ya decidido; ninguno descubre dónde debería estar.

### 18. 🟠 Un cambio de precio toca doce paquetes por dominio. ¿Qué observarías antes de rediseñar?

⏱️ **30 segundos:** Por qué el precio toca doce paquetes: si hay una regla repartida, un modelo compartido o una razón legítima de negocio.

🗣️ **2 minutos:** Sigo el cambio y agrupo lo que tocó: si doce paquetes implementan partes de la misma regla de precios, falta un dueño de esa regla; si todos dependen de un tipo `Price` canónico enorme, el problema es el modelo compartido. Antes de rediseñar, confirmo que el patrón se repite en otros cambios de precio.

🔬 **El detalle:** Tener paquetes «por dominio» no impide que una regla se reparta; es exactamente el caso que muestra que las carpetas no bastan.

### 19. 🟠 El árbol tiene carpetas perfectas, pero todos escriben todas las tablas. ¿Cómo lo diagnosticas?

⏱️ **30 segundos:** Como propiedad difusa de datos: las carpetas separan código, pero las escrituras cruzadas anulan los límites.

🗣️ **2 minutos:** El árbol muestra intención; la base muestra la realidad. Si cualquier módulo escribe cualquier tabla, ninguno puede garantizar sus invariantes ni cambiar su esquema sin coordinar. La recuperación empieza por inventariar escritores, declarar dueños, migrar escrituras a APIs y revocar permisos.

🔬 **El detalle:** Es un buen ejemplo de por qué la modularidad se evalúa en varias monedas a la vez.

### 20. 🟠 Un equipo quiere dividir el build en veinte módulos esta semana. ¿Qué secuencia propones?

⏱️ **30 segundos:** Primero descubrir límites con cambios reales, después reforzar una costura con una regla, y solo al final partir el build donde haya razón.

🗣️ **2 minutos:** Veinte módulos de build en una semana solidifican una conjetura: si el corte está mal, ahora hay que mover código entre veinte builds. Propongo analizar cambios recientes, elegir uno o dos límites claros, protegerlos con reglas en CI y medir si los cambios quedan contenidos. Los módulos de build llegan cuando el límite está confirmado.

🔬 **El detalle:** Partir el build tiene un coste real de tiempo de compilación y navegación; se paga cuando compra algo.

### 21. 🟠 Tras extraer servicios, todos consumen una librería con el modelo canónico completo. ¿Qué mejoró y qué no?

⏱️ **30 segundos:** Mejoró el despliegue independiente nominal; no mejoró el acoplamiento, que ahora viaja en una librería que obliga a actualizar a todos.

🗣️ **2 minutos:** Una librería con el modelo canónico completo hace que cualquier cambio de dominio recompile y redespliegue todos los servicios. Es acoplamiento de código y de despliegue empaquetado. Cada servicio debería tener su modelo local y compartir solo contratos pequeños y estables.

🔬 **El detalle:** Es una de las causas típicas de monolito distribuido: la extracción se hizo, pero el dominio siguió compartido.

### 22. 🟠 Una excepción arquitectónica lleva dos años activa. ¿Qué decisión harías visible?

⏱️ **30 segundos:** Haría visible si la excepción sigue teniendo motivo, cuánto cuesta y quién es su dueño, con una decisión explícita: retirarla o convertirla en diseño.

🗣️ **2 minutos:** Una excepción de dos años ya es arquitectura real, aunque nadie la haya decidido. La llevo a una revisión con su dueño: si el motivo desapareció, se planifica su retirada; si sigue, se documenta como parte del diseño con su coste. Lo que no puede seguir es la renovación silenciosa.

🔬 **El detalle:** Las excepciones sin caducidad son la vía por la que un monolito modular se convierte en barro.

### 23. 🟠 ¿Qué criterio usarías para detener una recuperación de modularidad?

⏱️ **30 segundos:** Que los cambios relevantes ya queden contenidos y el beneficio de otra costura no compense su coste.

🗣️ **2 minutos:** La recuperación no busca un árbol perfecto. Si las capacidades que más cambian lo hacen dentro de sus módulos, con menos regresiones y sin esperas, seguir cuesta más de lo que aporta. Se detiene, se dejan las reglas en CI para conservar lo logrado y se registra qué señal haría retomarla.

🔬 **El detalle:** Fijar ese criterio antes de empezar evita que la recuperación se convierta en un proyecto sin fin.

### 24. 🟠 ¿Cómo defenderías duplicación pequeña frente a un módulo `common` que acopla cuatro capacidades?

⏱️ **30 segundos:** Una duplicación pequeña permite a cada capacidad evolucionar sola; un `common` que acopla cuatro capacidades convierte cada cambio en coordinación.

🗣️ **2 minutos:** Si `orders` y `notifications` necesitan una dirección con reglas distintas, dos representaciones locales cuestan unas líneas de mapeo y eliminan la necesidad de acordar cada cambio. Un `common` con el modelo compartido ahorra esas líneas y cobra en coordinación, versiones y releases conjuntos. DRY evita duplicar conocimiento, no código parecido.

🔬 **El detalle:** Si una divergencia rompería una invariante —por ejemplo, el redondeo del dinero—, compartir sí compensa.

## 📖 04 — Acoplamiento, cohesión y razones de cambio

### 1. 🟢 ¿Qué es acoplamiento de código?

⏱️ **30 segundos:** Que un módulo conoce a otro en tiempo de compilación: imports, tipos o dependencias de build.

🗣️ **2 minutos:** Indica qué debe compilar o cambiar junto, no necesariamente qué se llama en runtime. Si `orders` importa tipos de `inventory`, un cambio en esos tipos puede obligar a modificar `orders`. Es la forma de acoplamiento más visible y la que las herramientas miden mejor, pero no la única.

🔬 **El detalle:** Reducirla con interfaces solo sirve si la dependencia relevante era de código y no de datos o de tiempo.

### 2. 🟢 ¿Qué es acoplamiento de datos?

⏱️ **30 segundos:** Que varias partes dependen del mismo estado: escriben las mismas tablas o comparten un modelo de datos.

🗣️ **2 minutos:** Si `orders` y `payments` escriben la misma tabla de estados, ninguno puede cambiar su significado sin coordinar, aunque no se importen entre sí. Es invisible para el análisis de imports y suele ser el acoplamiento más caro de deshacer, porque implica migrar datos y escritores.

🔬 **El detalle:** Una clave foránea entre tablas de dueños distintos también es acoplamiento de datos, a veces deliberado y valioso.

### 3. 🟢 ¿Qué es acoplamiento de cambio?

⏱️ **30 segundos:** Que ciertas partes cambian juntas de forma recurrente, aunque no se importen entre sí.

🗣️ **2 minutos:** Se observa en el historial: si doce commits del trimestre tocaron `orders` e `inventory` a la vez, comparten una razón de cambio o hay un límite incorrecto. Es la moneda que mejor refleja el coste real de un diseño, porque mide el trabajo que obliga a coordinar.

🔬 **El detalle:** Un solo commit no es causalidad; hay que confirmar el patrón con el motivo de los cambios.

### 4. 🟢 ¿Qué es acoplamiento temporal?

⏱️ **30 segundos:** Que una parte necesita que otra esté disponible ahora para completar su operación.

🗣️ **2 minutos:** Una llamada síncrona obligatoria es el caso típico: si `inventory` no responde, `CreateOrder` no puede terminar. También aparece con órdenes implícitos, como dos jobs que deben correr en secuencia. Es un precio correcto cuando la respuesta cambia la promesa al cliente, y un precio sin compra cuando no.

🔬 **El detalle:** Un evento puede diferirlo sin eliminarlo si el resultado de negocio sigue necesitando al consumidor.

### 5. 🟢 ¿Qué es cohesión funcional?

⏱️ **30 segundos:** Que los elementos agrupados colaboran en una misma responsabilidad y cambian por razones relacionadas.

🗣️ **2 minutos:** `ReserveInventory`, la disponibilidad y los movimientos de stock comparten lenguaje e invariantes: forman un módulo cohesivo. Meter el envío de correos en el mismo módulo porque ocurre después reduce la cohesión, porque tiene otra política, otra disponibilidad y otra cadencia. Cohesión alta significa cambios contenidos.

🔬 **El detalle:** No implica tamaño: un módulo cohesivo puede ser grande si todas sus partes cambian por la misma razón.

### 6. 🟢 ¿Qué significa razón de cambio?

⏱️ **30 segundos:** El motivo de negocio por el que una parte del código tiene que cambiar.

🗣️ **2 minutos:** Una política de reservas cambia por razones de inventario; una plantilla de correo, por razones de comunicación. Agrupar lo que cambia por la misma razón y separar lo que cambia por razones distintas es el criterio para dibujar módulos. Se descubre con historia de cambios, incidentes y conocimiento del dominio.

🔬 **El detalle:** Si dos razones de cambio conviven en un módulo, cada cambio de una arriesga romper la otra.

### 7. 🟢 ¿Qué aporta *connascence* como lente?

⏱️ **30 segundos:** Nombra formas de conocimiento compartido —nombre, tipo, significado, posición, algoritmo, tiempo— y ayuda a ver si el acoplamiento es explícito y cercano o implícito y distante.

🗣️ **2 minutos:** Sirve para hacer preguntas concretas: ¿dos módulos dependen del orden de los campos o de que dos jobs corran al mismo segundo? Esas formas implícitas y lejanas son las peligrosas. Compartir el significado de `COP` y su precisión es necesario, pero conviene expresarlo en un tipo pequeño con dueño.

🔬 **El detalle:** No hace falta recitar la taxonomía en una entrevista; basta con usarla para señalar el acoplamiento que duele.

### 8. 🟡 ¿Por qué contar imports no mide autonomía?

⏱️ **30 segundos:** Porque los imports solo muestran el código; los datos, el tiempo, el despliegue y las decisiones humanas pueden seguir unidos.

🗣️ **2 minutos:** Dos módulos sin imports entre sí pueden escribir la misma tabla, salir en el mismo release y necesitar la aprobación del mismo comité. La autonomía se mide en si un equipo puede cambiar, desplegar y operar su parte sin esperar a otros, y eso se observa en cambios reales, no en el grafo de imports.

🔬 **El detalle:** Menos imports puede incluso esconder acoplamiento si se sustituyeron por SQL directo o eventos implícitos.

### 9. 🟡 ¿Cuándo una llamada local representa acoplamiento razonable?

⏱️ **30 segundos:** Cuando conserva una garantía valiosa —una transacción, una invariante— y el mismo equipo posee los dos lados.

🗣️ **2 minutos:** `orders` llamando a la API de `inventory` en el mismo proceso crea acoplamiento de código y de ejecución, pero es barato si protege la invariante de pedido y reserva y ambos cambian juntos. Romperlo con eventos o HTTP añadiría coste sin comprar autonomía. El acoplamiento se evalúa por lo que compra.

🔬 **El detalle:** Se vuelve irrazonable cuando une capacidades con dueños o ritmos distintos sin una garantía que lo justifique.

### 10. 🟡 ¿Cómo puede HTTP conservar acoplamiento de cambio y despliegue?

⏱️ **30 segundos:** Si los equipos siguen cambiando el contrato y desplegándolo juntos, HTTP añade red sin quitar el acoplamiento de cambio ni de despliegue.

🗣️ **2 minutos:** Separar dos módulos por HTTP no los independiza si cada cambio de negocio modifica el contrato en los dos lados y ambos deben salir juntos. El resultado es el mismo acoplamiento que antes más latencia, timeouts y versiones mixtas. Es la receta de un monolito distribuido.

🔬 **El detalle:** La independencia la dan contratos que toleran versiones mixtas y límites que siguen razones de cambio, no el protocolo.

### 11. 🟡 ¿Qué diferencia hay entre acoplamiento necesario y accidental?

⏱️ **30 segundos:** El necesario expresa una invariante o una colaboración real del dominio; el accidental viene de decisiones históricas que ya no protegen nada.

🗣️ **2 minutos:** Que la reserva conozca el identificador del pedido es necesario. Que `notifications` dependa del orden accidental de columnas de `orders`, o que dos jobs dependan de correr al mismo segundo, es accidental. El primero se hace explícito y se cuida; el segundo se elimina.

🔬 **El detalle:** Distinguirlos requiere conocer el dominio: un acoplamiento que parece accidental puede proteger una regla que nadie documentó.

### 12. 🟡 ¿Cómo usarías el historial de commits sin confundir correlación con causa?

⏱️ **30 segundos:** Como pista para priorizar, confirmando cada patrón con el motivo de los cambios y con otras fuentes.

🗣️ **2 minutos:** Si dos módulos cambian juntos a menudo, reviso por qué: una regla repartida apunta a un límite incorrecto; una migración excepcional o un reformateo no dicen nada. Cruzo el historial con incidentes, accesos a datos y la opinión de quien conoce el dominio antes de concluir.

🔬 **El detalle:** Las herramientas que calculan acoplamiento temporal del historial dan hipótesis; el diagnóstico sigue siendo humano.

### 13. 🟡 ¿Por qué volatilidad y cohesión deben analizarse juntas?

⏱️ **30 segundos:** Porque lo que cambia junto con frecuencia debería estar junto, y la cohesión solo se confirma viendo qué cambia y con qué ritmo.

🗣️ **2 minutos:** Dos partes con la misma razón de cambio y alta volatilidad son candidatas claras a un módulo. Una parte estable puede compartirse sin mucho coste aunque no sea perfectamente cohesiva. Mirar solo la cohesión teórica, sin la volatilidad real, lleva a separar cosas que cambian juntas o a juntar cosas que nunca cambian.

🔬 **El detalle:** La volatilidad se mide en el historial; la cohesión, en el lenguaje y las invariantes del dominio.

### 14. 🟡 ¿Qué coste organizacional puede esconder una API técnicamente limpia?

⏱️ **30 segundos:** Aprobaciones, esperas y coordinación entre equipos para cambios que la API técnica permitiría hacer solos.

🗣️ **2 minutos:** Una API bien diseñada puede exigir, por proceso, que un comité central apruebe cada cambio, o que dos equipos acuerden cada versión. El código está desacoplado y la organización no. Se mide en tiempo de espera por cambio y en cuántos equipos intervienen, no en la calidad del contrato.

🔬 **El detalle:** Es la moneda de equipos, y a menudo la más cara.

### 15. 🟡 ¿Cuándo compartir un tipo pequeño es mejor que duplicarlo?

⏱️ **30 segundos:** Cuando representa un concepto estable y de significado común, como un identificador o una representación del dinero, y divergir rompería algo.

🗣️ **2 minutos:** Compartir un `OrderId` o un `Money` con su redondeo cuesta poco y evita discrepancias. Compartir un `Order` canónico con pago, inventario y avisos cuesta mucho, porque cada cambio en él afecta a todos. La regla práctica es compartir lo pequeño y estable, duplicar lo que cada módulo necesita con reglas propias.

🔬 **El detalle:** El tipo compartido necesita dueño y política de cambios, aunque sea pequeño.

### 16. 🟡 ¿Cuándo duplicar una representación compra autonomía?

⏱️ **30 segundos:** Cuando cada módulo necesita una representación propia, el mapeo es barato y la coordinación central costaría más que una divergencia controlada.

🗣️ **2 minutos:** `notifications` puede guardar su propia copia del nombre y el email del cliente para sus mensajes, sin importar el agregado `Customer`. Si `Customer` cambia, `notifications` no se entera ni se rompe. La duplicación deliberada es el precio de que cada módulo evolucione solo.

🔬 **El detalle:** Conviene vigilar la divergencia si tiene consecuencias de negocio, por ejemplo con una reconciliación periódica.

### 17. 🟡 ¿Qué garantía podría justificar mantener `orders` e `inventory` cerca?

⏱️ **30 segundos:** La invariante de que un pedido confirmado tiene su reserva, que se cumple más barato con una transacción local.

🗣️ **2 minutos:** Si `orders` e `inventory` comparten esa invariante, una base y un equipo, mantenerlos cerca permite confirmar pedido y reserva en un `COMMIT` sin compensaciones. Separarlos obligaría a gestionar estados intermedios y reconciliación. Es acoplamiento que compra una garantía.

🔬 **El detalle:** Si cambiaran a ritmos distintos o con equipos distintos, esa cercanía empezaría a costar más de lo que protege.

### 18. 🟠 Un evento cambia siempre junto con tres consumidores. ¿Qué acoplamiento sigue presente?

⏱️ **30 segundos:** Acoplamiento de contrato y de cambio: productor y consumidores comparten la forma y el significado del evento.

🗣️ **2 minutos:** El evento quitó la llamada directa, pero si cada cambio del evento obliga a cambiar tres consumidores, el acoplamiento de cambio sigue intacto. Quizá el evento expone demasiado del modelo interno, o los consumidores dependen de campos que deberían ser suyos. Se revisa qué contiene y qué usa cada consumidor.

🔬 **El detalle:** «Un evento desacopla» es uno de los mitos más frecuentes; desacopla el tiempo, no necesariamente el contrato.

### 19. 🟠 Dos módulos no se importan, pero escriben la misma tabla. ¿Qué cambiarías primero?

⏱️ **30 segundos:** Declararía un dueño de la tabla y migraría la escritura del otro a la API del dueño.

🗣️ **2 minutos:** Sin imports entre ellos, el acoplamiento es de datos y más difícil de ver. Inventario quién escribe qué, acuerdo el dueño según la invariante, ofrezco un comando al otro módulo y, cuando esté migrado, revoco sus permisos de escritura. Así el esquema vuelve a tener un solo responsable.

🔬 **El detalle:** Si los dos escriben porque la tabla mezcla dos conceptos, puede ser mejor separarla en dos.

### 20. 🟠 Un equipo central aprueba cada cambio de un modelo canónico. ¿Qué alternativas compararías?

⏱️ **30 segundos:** Mantener el modelo canónico con un dueño y contratos pequeños por consumidor, o duplicar representaciones locales con traducción.

🗣️ **2 minutos:** Un comité que aprueba cada cambio convierte el modelo en un cuello de botella. Comparo reducir el modelo compartido a lo estable, dar a cada consumidor su propio modelo con una traducción en el borde, o asignar un equipo dueño con una política de compatibilidad. Elijo según cuántos consumidores hay y cuánto cuesta una divergencia.

🔬 **El detalle:** El criterio de éxito es menos espera por cambio sin aumentar incidentes de discrepancia.

### 21. 🟠 Un ciclo refleja una invariante compartida real. ¿Romperías el ciclo o moverías el límite?

⏱️ **30 segundos:** Primero comprobaría que la invariante es real; si lo es, movería el límite para que quede dentro de un módulo antes que romper el ciclo artificialmente.

🗣️ **2 minutos:** Romper el ciclo con una interfaz o un evento mantiene la invariante repartida y la vuelve más difícil de garantizar. Si `orders` e `inventory` protegen juntos una regla, fusionarlos o mover la regla a uno de ellos respeta el dominio. El grafo acíclico no es un fin; los cambios contenidos sí.

🔬 **El detalle:** Si la invariante resulta ser accidental, entonces sí se rompe el ciclo moviendo la responsabilidad a su dueño.

### 22. 🟠 La duplicación produjo una discrepancia regulatoria. ¿Qué garantía priorizarías ahora?

⏱️ **30 segundos:** La corrección del dato regulado: una fuente única de verdad para ese concepto, con dueño y validación.

🗣️ **2 minutos:** La duplicación compraba autonomía, pero aquí la divergencia tiene coste legal. Corrijo los datos afectados, centralizo ese concepto concreto en un tipo o servicio con dueño y añado una reconciliación que detecte divergencias. El resto de duplicaciones pueden seguir si no tienen consecuencias parecidas.

🔬 **El detalle:** La lección no es «nunca duplicar», sino que la garantía que exige una fuente única decide qué se comparte.

### 23. 🟠 ¿Qué métrica y criterio de parada usarías al reducir coordinación entre equipos?

⏱️ **30 segundos:** Tiempo de espera por coordinación en cambios reales, con un objetivo acordado y un criterio de parada cuando el beneficio marginal cae.

🗣️ **2 minutos:** Mido cuántos equipos intervienen por cambio y cuánto espera cada cambio a otro equipo, antes y después de cada intervención. Si la espera baja y los incidentes no suben, sigo; cuando las siguientes mejoras cuestan más de lo que ahorran, me detengo. El objetivo no es cero coordinación, sino la proporcional.

🔬 **El detalle:** Las métricas se usan para decidir sobre el sistema, nunca para clasificar personas.

### 24. 🟠 ¿Cómo explicarías que una dependencia más explícita puede ser mejor que una aparentemente débil?

⏱️ **30 segundos:** Porque una dependencia explícita se ve, se prueba y tiene dueño, mientras que una débil en apariencia puede esconder conocimiento compartido implícito y lejano.

🗣️ **2 minutos:** Un contrato pequeño y tipado entre `orders` y `payments` sobre el dinero es fácil de revisar y romper en compilación. Depender del orden de campos de un JSON o del horario de un job parece no acoplar, pero rompe en silencio. Hacer explícito lo necesario reduce el riesgo aunque aumente las líneas de dependencia visibles.

🔬 **El detalle:** Esconder el acoplamiento no lo reduce; solo lo aleja de donde alguien pueda verlo.

## 📖 05 — Cuándo elegir un monolito y antipatrones

### 1. 🟢 ¿Qué significa elegir una topología de forma proporcional?

⏱️ **30 segundos:** Pagar solo la complejidad que las restricciones actuales justifican, con supuestos explícitos y una fecha o señal para revisar.

🗣️ **2 minutos:** Una startup de seis personas con dominio incierto no necesita el coste operativo de veinte servicios; una organización con equipos y requisitos de aislamiento distintos quizá sí. Proporcional significa que la topología responde a restricciones medidas, no a la moda ni a un crecimiento imaginado, y que se revisa cuando cambian.

🔬 **El detalle:** La proporcionalidad también se aplica al revés: no mantener un monolito cuando una restricción dura pide separar.

### 2. 🟢 ¿Por qué un dominio incierto favorece límites locales?

⏱️ **30 segundos:** Porque los límites todavía cambian, y moverlos dentro de un proceso es un commit, mientras que entre servicios es una migración.

🗣️ **2 minutos:** Si las reglas cambian cada semana, cualquier frontera que se dibuje hoy probablemente estará mal en unos meses. Con límites locales se corrige barato y se aprende dónde están las razones de cambio reales. Un contrato remoto prematuro convierte ese aprendizaje en versiones, migraciones de datos y coordinación.

🔬 **El detalle:** Lo que sí se fija desde el principio es la propiedad de los datos críticos y la identidad de las operaciones.

### 3. 🟢 ¿Qué es *premature distribution*?

⏱️ **30 segundos:** Distribuir antes de que la autonomía compense: pagar contratos, red, telemetría y consistencia eventual sin necesitarlos todavía.

🗣️ **2 minutos:** Además del coste operativo, endurece límites de dominio que aún cambian, y cada corrección se vuelve una migración entre servicios. El síntoma típico es un equipo pequeño que pasa más tiempo coordinando contratos que entregando funcionalidad. Se evita empezando con límites locales y métricas que digan cuándo separar.

🔬 **El detalle:** No es un dogma de «monolito primero»: con requisitos claros de aislamiento, servicios desde el inicio pueden ser correctos.

### 4. 🟢 ¿Qué garantía local puede favorecer un monolito?

⏱️ **30 segundos:** La transacción local entre capacidades que comparten una invariante, como pedido y reserva.

🗣️ **2 minutos:** Si negocio exige que un pedido confirmado tenga siempre su reserva, un `COMMIT` en la misma base lo garantiza sin compensaciones ni estados intermedios. En un sistema distribuido, la misma garantía exige sagas, reconciliación y soporte. Esa diferencia de coste es uno de los argumentos más fuertes para mantener capacidades juntas.

🔬 **El detalle:** Solo aplica a lo que vive en la misma base; el proveedor de pagos sigue fuera.

### 5. 🟢 ¿Qué es un criterio de salida?

⏱️ **30 segundos:** Una condición medible, acordada de antemano, que obliga a revisar la decisión de topología.

🗣️ **2 minutos:** Por ejemplo: «revisar si `payments` provoca dos incidentes de aislamiento o necesita desplegar cuatro veces más que el resto». Convierte una apuesta en una hipótesis: mientras la condición no se cumpla, la decisión se mantiene; cuando se cumple, se reabre con evidencia. Evita tanto el inmovilismo como las migraciones por impulso.

🔬 **El detalle:** Un criterio vago como «cuando duela» no sirve; tiene que poder comprobarse.

### 6. 🟢 ¿Qué diferencia hay entre señal de revisión y orden de extracción?

⏱️ **30 segundos:** La señal obliga a reevaluar alternativas; la orden de extracción presupone que la respuesta ya es separar.

🗣️ **2 minutos:** Que se dispare una señal —más incidentes, otra cadencia— abre la decisión, y la respuesta puede ser un cupo de recursos, un worker o un pipeline más rápido. Tratar cada señal como orden de extraer lleva a separar sin comparar la opción local, que suele ser más barata.

🔬 **El detalle:** La revisión compara opciones con la misma matriz que se usó al decidir, no parte de una conclusión.

### 7. 🟢 ¿Qué coste de despliegue acepta un monolito?

⏱️ **30 segundos:** Liberar el conjunto ante cualquier cambio y escalar la aplicación completa.

🗣️ **2 minutos:** Un cambio pequeño en `notifications` pasa por el mismo pipeline y el mismo release que todo lo demás, y el escalado se hace replicando la unidad entera. Es un coste aceptable mientras el pipeline sea rápido, las cargas sean parecidas y los equipos no necesiten cadencias distintas.

🔬 **El detalle:** Cuando ese coste empieza a producir esperas o desperdicio medidos, es una señal de revisión, no antes.

### 8. 🟡 ¿Por qué el tamaño del equipo influye sin decidir por sí solo?

⏱️ **30 segundos:** Porque cambia el coste de coordinar, pero no dice nada de carga, invariantes ni aislamiento.

🗣️ **2 minutos:** Un equipo pequeño gana poco con la independencia organizativa que dan los servicios y paga todo su coste operativo. Pero un equipo pequeño con un requisito regulatorio de aislamiento puede necesitar separar igual. El tamaño es una fila de la matriz, no la decisión entera.

🔬 **El detalle:** A medida que crece el número de equipos, la moneda de equipos pesa más; aun así, se decide con cambios reales.

### 9. 🟡 ¿Cómo afecta la madurez operativa a la elección?

⏱️ **30 segundos:** Con plataforma y observabilidad inmaduras, cada frontera distribuida añade fallos difíciles de diagnosticar; conviene menos superficie distribuida.

🗣️ **2 minutos:** Operar servicios exige despliegues automatizados, trazas distribuidas, alertas por servicio y guardias capaces. Si eso no existe, extraer multiplica incidentes sin herramientas para entenderlos. Un monolito modular deja madurar la operación mientras se entregan funcionalidades.

🔬 **El detalle:** La madurez operativa se construye; cuando exista, algunas separaciones se vuelven más baratas.

### 10. 🟡 ¿Por qué una carga alta no implica automáticamente servicios?

⏱️ **30 segundos:** Porque una carga alta suele resolverse con réplicas, caché u optimización, y porque el cuello a menudo está en la base, que los servicios no arreglan.

🗣️ **2 minutos:** Lo primero es medir qué recurso se satura. Si es CPU del proceso, se replica; si es una consulta, se optimiza; si es una capacidad concreta con carga distinta, se aísla. Separar en servicios sin esa medición puede mover el cuello de sitio sin ensancharlo.

🔬 **El detalle:** Una parte caliente y medible sí puede justificar su separación; lo que no la justifica es el volumen total.

### 11. 🟡 ¿Cuándo modularizar es suficiente sin distribuir?

⏱️ **30 segundos:** Cuando el problema es de cambios que se pisan u ownership difuso, y la topología compartida sigue siendo aceptable en despliegue, datos y operación.

🗣️ **2 minutos:** Si `payments` y `orders` se pisan en el código y las pruebas requieren todo el sistema, límites internos con API, dueño de datos y reglas en CI resuelven el problema sin red. Distribuir solo haría falta si además hay cadencia, aislamiento o escala distintos.

🔬 **El detalle:** Modularizar primero también hace más barata una extracción futura, si llega.

### 12. 🟡 ¿Qué autonomía debe comprar una extracción?

⏱️ **30 segundos:** Autonomía efectiva: despliegue, datos, runtime u ownership independientes que antes no existían.

🗣️ **2 minutos:** Si tras extraer `payments` el servicio sigue saliendo en el release común, compartiendo tablas y esperando aprobaciones, la extracción solo añadió red. Debe poder cambiar y recuperarse bajo su dueño, con su cadencia o su aislamiento. Se escribe qué autonomía se busca antes de empezar y se comprueba al terminar.

🔬 **El detalle:** Una extracción que no compra autonomía es el origen más común de un monolito distribuido.

### 13. 🟡 ¿Cómo puede regulación favorecer decisiones opuestas?

⏱️ **30 segundos:** Puede exigir una unidad auditable única o, al contrario, aislamiento de ciertos datos; depende del control concreto.

🗣️ **2 minutos:** Un requisito de trazabilidad puede favorecer un sistema donde todo cambio pase por un pipeline controlado. Un requisito de separación de datos de pago puede obligar a un entorno aparte. Por eso «es regulado» no decide la topología: hay que leer qué control se exige y quién lo valida.

🔬 **El detalle:** A veces el control se cumple con permisos, cifrado o esquemas separados sin cambiar la topología.

### 14. 🟡 ¿Por qué un contrato remoto hace más caro corregir un límite?

⏱️ **30 segundos:** Porque un contrato remoto obliga a versionar, mantener compatibilidad y coordinar despliegues para mover una responsabilidad.

🗣️ **2 minutos:** Dentro de un proceso, mover una regla de `orders` a `inventory` es un refactor en un commit. Entre servicios, hay que publicar una versión nueva, mantener la vieja mientras los consumidores migran, mover datos y coordinar releases. Cuanto antes se fija un límite remoto, más caro es corregirlo si estaba mal.

🔬 **El detalle:** Por eso los límites se descubren localmente y se distribuyen cuando están confirmados.

### 15. 🟡 ¿Qué métricas revisarías antes de separar `payments`?

⏱️ **30 segundos:** Frecuencia de cambios y tiempo de espera por el release común, incidentes de aislamiento, perfil de recursos y coordinación con otros equipos.

🗣️ **2 minutos:** Si `payments` espera días por el release, provoca o sufre incidentes por compartir proceso, o consume un recurso de forma distinta al resto, hay razones para separar. Si ninguna métrica lo muestra, la separación no compra nada. También miro si comparte tablas, porque eso haría la extracción mucho más cara.

🔬 **El detalle:** Las métricas se toman sobre un periodo representativo, no sobre la última semana.

### 16. 🟡 ¿Cómo conserva opciones un monolito modular?

⏱️ **30 segundos:** Manteniendo límites internos claros y decisiones revisables: cualquier módulo con API y dueño puede extraerse después si hace falta.

🗣️ **2 minutos:** Un monolito modular no cierra la puerta a los servicios; la prepara. La frontera ya existe en el código y en los datos, así que una extracción futura es una migración acotada y no una reescritura. Mientras tanto, se conservan las ventajas locales.

🔬 **El detalle:** Lo que cierra opciones es la bola de barro, sea local o distribuida.

### 17. 🟡 ¿Cuándo servicios desde el inicio sí pueden ser razonables?

⏱️ **30 segundos:** Con un equipo experimentado, un dominio conocido y requisitos fuertes de aislamiento o de escalado selectivo desde el principio.

🗣️ **2 minutos:** Si el dominio ya se conoce bien —por ejemplo, una reescritura de un sistema existente— y hay capacidades con requisitos claramente distintos, empezar separado evita una migración posterior. La carga de la prueba recae en la restricción: tiene que existir y estar confirmada, no ser una expectativa de crecimiento.

🔬 **El detalle:** Aun así, conviene no separar más de lo que las restricciones piden.

### 18. 🟠 Una startup de seis personas espera millones de usuarios, pero no tiene tráfico. ¿Qué propones?

⏱️ **30 segundos:** Un monolito modular con límites claros, métricas de carga y cambio desde el primer día, y una revisión con umbral.

🗣️ **2 minutos:** Sin tráfico, la expectativa de millones de usuarios es una hipótesis. Propongo construir lo que valida el negocio rápido, con réplicas y límites internos que permitan escalar y extraer si los datos lo piden. Registro qué carga medida reabriría la decisión y cuándo se revisa.

🔬 **El detalle:** Diseñar para millones sin clientes suele matar antes al producto que la falta de escala.

### 19. 🟠 `inventory` consume 70 % de CPU durante dos campañas al año. ¿Qué medirías antes de extraerlo?

⏱️ **30 segundos:** Qué recurso consume, en qué operaciones, si afecta al SLO de checkout y si una optimización o un aislamiento local lo resolvería.

🗣️ **2 minutos:** Dos campañas al año con CPU alta pueden resolverse con más réplicas temporales, optimizando el cálculo de disponibilidad o limitando su concurrencia. Mido si el consumo degrada otras capacidades y cuánto costaría la alternativa local. Extraer solo compensa si `inventory` necesita escalar aparte de forma sostenida.

🔬 **El detalle:** El 70 % de CPU sin impacto en el SLO no es un problema que resolver.

### 20. 🟠 Una norma exige aislar datos de pago. ¿Qué alternativas compararías además de un servicio?

⏱️ **30 segundos:** Permisos y cifrado sobre los datos de pago, un esquema separado, un entorno aislado o un proveedor que los custodie.

🗣️ **2 minutos:** Leo qué exige la norma exactamente: quién puede acceder, dónde se almacenan y cómo se audita. Muchas veces se cumple sin un servicio: esquema propio con credenciales separadas, cifrado y auditoría. Si exige un entorno con despliegue y acceso separados, el servicio se vuelve necesario, y se diseña para ese control.

🔬 **El detalle:** Tokenizar con un proveedor externo puede sacar los datos sensibles del sistema por completo.

### 21. 🟠 Dos equipos necesitan cadencias distintas, pero comparten una invariante fuerte. ¿Cómo priorizas?

⏱️ **30 segundos:** Priorizo la invariante: mientras sea obligatoria, los mantengo en un despliegue y busco cadencias distintas con módulos y despliegues frecuentes.

🗣️ **2 minutos:** Separar dos capacidades que comparten una invariante fuerte obliga a compensaciones y reconciliación. Antes compruebo si la invariante es realmente obligatoria o si negocio acepta una ventana corta. Si lo es, doy a cada equipo su módulo y un pipeline rápido; si no, puedo separar con un contrato y un estado intermedio acordado.

🔬 **El detalle:** La decisión se escala a negocio cuando el conflicto es entre dos requisitos, no entre dos preferencias técnicas.

### 22. 🟠 El monolito escala con réplicas, pero el pool de base se agota. ¿Qué cambia en tu diagnóstico?

⏱️ **30 segundos:** El cuello no es el cómputo sino la base: más réplicas abren más conexiones contra un límite fijo.

🗣️ **2 minutos:** Cada réplica tiene su pool; con ocho réplicas de veinte conexiones se superan los límites de una base modesta. La solución es reducir el tiempo que cada petición retiene la conexión, dimensionar los pools contra la base y optimizar las consultas, no añadir réplicas ni servicios. Partir la aplicación tampoco ayudaría si todos siguen usando la misma base.

🔬 **El detalle:** Es un buen ejemplo de medir el recurso limitante antes de cambiar la topología.

### 23. 🟠 ¿Qué primera acción reversible propondrías antes de una separación física?

⏱️ **30 segundos:** Reforzar el límite interno del módulo candidato: API, dueño de datos, regla en CI y métricas de su carga y sus cambios.

🗣️ **2 minutos:** Esa acción se deshace fácilmente y mejora el sistema aunque la separación nunca llegue. Además aporta la evidencia que decidirá si separar: si los cambios quedan contenidos y la carga es distinta, la extracción será una migración acotada. Un worker con recursos propios es otra primera acción reversible cuando el problema es de recursos.

🔬 **El detalle:** Lo que no es reversible —copiar datos a otra autoridad, publicar un contrato externo— se deja para después.

### 24. 🟠 ¿Qué evidencia te haría cancelar una extracción ya planeada?

⏱️ **30 segundos:** Que la alternativa local resuelva el objetivo, que el coste medido supere al beneficio o que no haya capacidad para operar el nuevo límite.

🗣️ **2 minutos:** Si un pipeline propio elimina la espera por el release, o un cupo de recursos contiene los incidentes, la extracción ya no compra nada. También si el equipo no puede sostener la guardia del servicio nuevo. Cancelar a tiempo conserva lo aprendido y evita una frontera sin valor.

🔬 **El detalle:** Los criterios de cancelación se acuerdan antes de empezar, cuando nadie tiene todavía inversión emocional en el resultado.

## 📖 06 — Estilos de estructura interna: capas, clean, onion y vertical slice

### 1. 🟢 ¿Qué tres ejes de decisión mezcla la discusión entre capas, clean, onion y vertical slice?

⏱️ **30 segundos:** Cómo se corta el árbol —por capa, por caso de uso o por capacidad—, hacia dónde apuntan las dependencias —hacia la persistencia o hacia el dominio— y dónde vive la lógica —script, registro activo o modelo—.

🗣️ **2 minutos:** Capas responde a los dos primeros ejes a la vez; clean y onion, solo al segundo; vertical slice, al primero; y Transaction Script, Active Record y Domain Model, al tercero. Compararlos como rivales mezcla respuestas a preguntas distintas. Un mismo módulo puede combinar slices, dependencias hacia el dominio y un Domain Model.

🔬 **El detalle:** Ninguno de los tres ejes decide el límite entre capacidades, que es la pregunta del bloque 02.

### 2. 🟢 ¿Cuál es la regla de una arquitectura por capas y qué diferencia hay entre la versión estricta y la relajada?

⏱️ **30 segundos:** Cada capa depende solo de las de abajo: en la versión estricta, solo de la inmediatamente inferior; en la relajada, de cualquiera inferior.

🗣️ **2 minutos:** La estricta obliga a pasar por cada capa aunque no aporte nada, lo que genera servicios que solo delegan. La relajada deja a la presentación usar directamente el acceso a datos cuando no hay lógica en medio, a cambio de más caminos posibles. En ambas, las dependencias terminan en la persistencia.

🔬 **El detalle:** La mayoría de los monolitos por capas son relajados en la práctica, aunque se dibujen estrictos.

### 3. 🟢 ¿Qué es la regla de dependencias que comparten clean y onion?

⏱️ **30 segundos:** Que las dependencias del código fuente apuntan solo hacia dentro: el dominio no conoce la aplicación, y la aplicación no conoce la infraestructura.

🗣️ **2 minutos:** Lo de fuera implementa interfaces definidas dentro. El repositorio JPA implementa un puerto que declara el caso de uso; el dominio no importa nada de Spring ni del driver. Así, el centro se prueba sin infraestructura y un cambio de tecnología queda en el anillo exterior.

🔬 **El detalle:** La regla habla de dependencias de código, no del flujo de ejecución: en runtime, la petición sigue entrando por fuera y llegando al centro.

### 4. 🟢 ¿Qué es una vertical slice y qué contiene?

⏱️ **30 segundos:** Una organización del código por caso de uso, en la que cada slice contiene todo lo que ese caso necesita, desde la entrada hasta el acceso a datos.

🗣️ **2 minutos:** `create_order/` tiene su entrada, su validación, su handler y su SQL; `list_orders/` puede ser una consulta directa. Se minimiza lo compartido entre slices y cada uno elige su técnica interna. Un cambio en un caso de uso queda en su carpeta.

🔬 **El detalle:** El nombre viene de cortar en vertical las capas clásicas: cada slice atraviesa lo que antes eran capas horizontales compartidas.

### 5. 🟢 ¿Qué diferencia hay entre Transaction Script, Active Record y Domain Model?

⏱️ **30 segundos:** Transaction Script es un procedimiento por operación; Active Record, un objeto por fila con su persistencia; Domain Model, objetos con comportamiento independientes de la base.

🗣️ **2 minutos:** El script es lo más simple y duplica reglas cuando crecen. Active Record es cómodo en CRUD y ata el dominio al esquema. Domain Model aísla invariantes complejas a cambio de mapeo y más código. Los tres son patrones de Fowler y pueden convivir en un mismo sistema, cada uno donde encaja.

🔬 **El detalle:** Elegir por operación y no por sistema evita pagar un Domain Model en un listado o un script en una confirmación con reglas.

### 6. 🟢 ¿Qué diferencia hay entre paquete por capa y paquete por capacidad?

⏱️ **30 segundos:** Paquete por capa agrupa por rol técnico —controllers, services—; paquete por capacidad agrupa todo lo de `orders` o de `inventory` en su propio paquete.

🗣️ **2 minutos:** Por capa, un cambio de negocio recorre varios paquetes y cada paquete mezcla capacidades. Por capacidad, el cambio queda en un paquete y la visibilidad del lenguaje puede ocultar lo interno. Dentro de cada paquete de capacidad puede haber, a su vez, capas o slices.

🔬 **El detalle:** Paquete por capacidad es condición para un monolito modular, no prueba: además hacen falta API, propiedad de datos y controles.

### 7. 🟢 ¿Por qué ninguno de estos estilos es una topología?

⏱️ **30 segundos:** Porque describen cómo se organiza el código dentro de una unidad de despliegue, no cuántas unidades hay ni cómo se comunican.

🗣️ **2 minutos:** Una aplicación con clean architecture puede desplegarse como un solo proceso o partirse en varios; un monolito puede estar en capas o en slices. La topología se decide con las cinco monedas; el estilo interno, con el dominio y el equipo de cada módulo.

🔬 **El detalle:** Confundirlos lleva a decir «tenemos hexagonal, así que ya podemos partir en servicios», que no se sigue.

### 8. 🟡 ¿Qué garantiza una arquitectura por capas y qué no garantiza?

⏱️ **30 segundos:** Garantiza separación de responsabilidades técnicas y que la presentación no toca la base; no garantiza límites entre capacidades ni un dominio libre de la persistencia.

🗣️ **2 minutos:** En capas, `OrderService` puede llamar a `InventoryRepository` sin violar ninguna regla, y las entidades del ORM suelen ser el modelo. El resultado es que un cambio de esquema llega a las reglas y un cambio de negocio recorre todas las capas. Para un dominio pequeño, esos costes son aceptables.

🔬 **El detalle:** Capas no es el problema; el problema es esperar de capas una garantía —límites por capacidad— que no ofrece.

### 9. 🟡 ¿En qué se parecen y en qué se diferencian clean y hexagonal?

⏱️ **30 segundos:** Comparten la regla de dependencias hacia el interior; se diferencian en el modelo: clean prescribe capas internas, hexagonal habla de puertos y adaptadores sin anillos.

🗣️ **2 minutos:** Clean distingue entidades de casos de uso y dibuja anillos concéntricos. Hexagonal distingue el interior de la aplicación y sus puertos, con adaptadores que la conducen o son conducidos. Una herramienta que verifica solo la regla, como ArchUnit, puede tratarlas igual; un diseño, no.

🔬 **El detalle:** En entrevista conviene decir en qué coinciden antes de discutir en qué difieren: la regla es lo que da la garantía.

### 10. 🟡 ¿Qué cuesta invertir la dependencia hacia el dominio y cuándo ese coste es ceremonia?

⏱️ **30 segundos:** Cuesta interfaces por cada dependencia externa, mapeo entre modelos y más archivos; es ceremonia cuando no hay reglas que aislar de la infraestructura.

🗣️ **2 minutos:** En un CRUD de catálogo, invertir la dependencia produce un puerto, un adaptador y dos mapeos para guardar lo mismo que llegó. No se protege ninguna invariante. En la confirmación de un pedido, con reglas de stock y pago, el mismo coste compra un dominio probable sin base.

🔬 **El detalle:** La señal de ceremonia son mapeos que copian campo a campo sin ninguna transformación ni regla en medio.

### 11. 🟡 ¿Por qué vertical slice no elimina la necesidad de límites entre capacidades?

⏱️ **30 segundos:** Porque organiza el interior de una capacidad: un slice de `orders` puede escribir las tablas de `inventory` igual que un servicio en capas.

🗣️ **2 minutos:** Los slices minimizan lo compartido dentro de un módulo, pero no dicen dónde termina el módulo ni quién es dueño de cada dato. La frontera entre `orders` e `inventory`, su API y la propiedad de datos siguen haciendo falta, con sus controles.

🔬 **El detalle:** Un sistema entero en slices sin módulos tiende a lo mismo que uno en capas sin módulos: todo puede tocar todo.

### 12. 🟡 ¿Dónde pondrías la lógica común a varios slices de `orders`?

⏱️ **30 segundos:** En un modelo de dominio dentro del módulo `orders`, que los slices usan, y no en una capa de servicios compartida ni copiada en cada slice.

🗣️ **2 minutos:** Si la validación de un pedido vive en `Order` o en un servicio de dominio del módulo, todos los slices la aplican igual. Copiarla en cada slice lleva a reglas que divergen; subirla a una capa de servicios reconstruye lo que los slices querían evitar.

🔬 **El detalle:** Lo común de verdad es la regla de negocio; lo común de infraestructura —acceso a la base, serialización— puede ser una utilidad del módulo.

### 13. 🟡 ¿Por qué usar entidades del ORM como modelo de dominio rompe el anillo interior?

⏱️ **30 segundos:** Porque el modelo del centro queda anotado con detalles de la persistencia y cambia cuando cambia el esquema: la dependencia apunta hacia fuera.

🗣️ **2 minutos:** Una entidad JPA con anotaciones de tabla, columnas y relaciones perezosas es el dominio y es la persistencia a la vez. Un cambio de columna obliga a tocar reglas, y la carga perezosa filtra decisiones de la base al dominio. Clean pediría un modelo propio y un mapeo en el adaptador.

🔬 **El detalle:** Aceptarlo puede ser una concesión razonable en dominios simples; lo que no vale es llamarlo clean architecture.

### 14. 🟡 ¿Cuándo es un Domain Model anémico peor que un Transaction Script honesto?

⏱️ **30 segundos:** Cuando paga todo el coste de la separación —clases, repositorios, mapeos— sin tener comportamiento: objetos con getters y setters y la lógica en otro sitio.

🗣️ **2 minutos:** Un Transaction Script honesto dice lo que es: un procedimiento que lee, decide y escribe. Un modelo anémico aparenta encapsular reglas que en realidad viven en servicios, y añade capas que no protegen nada. Si el dominio no tiene invariantes ricas, el script es más claro y más barato.

🔬 **El detalle:** El término *anemic domain model* lo popularizó Fowler como antipatrón; su crítica es al coste sin beneficio, no a los objetos simples.

### 15. 🟡 ¿Por qué una *clean architecture* puede ser, por capacidades, una bola de barro?

⏱️ **30 segundos:** Porque puede tener un único anillo de dominio con `orders`, `inventory`, `payments` y `notifications` mezclados, sin límites entre ellos.

🗣️ **2 minutos:** La regla de dependencias ordena capas técnicas; no separa capacidades. Si en el anillo de dominio cualquier clase puede usar cualquier otra y todos escriben todas las tablas, el sistema está bien estratificado y enmarañado por capacidades. La modularidad exige además límites verticales.

🔬 **El detalle:** Aplicar clean dentro de cada módulo, y no alrededor de todo el sistema, evita ese resultado.

### 16. 🟡 ¿Puede cada módulo de un monolito modular usar un estilo interno distinto?

⏱️ **30 segundos:** Sí: el estilo interno es una decisión de cada módulo, según su dominio y su equipo.

🗣️ **2 minutos:** `notifications` puede ser capas simples con Transaction Scripts; `orders`, un Domain Model con dependencias hacia el dominio; los listados, slices. Lo que sí debe ser común son las reglas entre módulos: API, propiedad de datos y controles. La uniformidad interna es comodidad, no garantía.

🔬 **El detalle:** Conviene documentar el estilo de cada módulo para que quien llega sepa qué esperar.

### 17. 🟡 ¿Qué cambia en la regla de dependencias entre un proyecto Go, donde el compilador prohíbe ciclos, y uno TypeScript, donde no?

⏱️ **30 segundos:** En Go la dirección se decide antes, porque un ciclo no compila; en TypeScript un ciclo compila y la regla depende de una herramienta como ESLint o dependency-cruiser.

🗣️ **2 minutos:** En Go, si `orders` importa `inventory` e `inventory` importa `orders`, el build falla; el equipo tiene que elegir quién depende de quién. En TypeScript ese ciclo funciona hasta que un import circular produce un valor sin inicializar en runtime. En ambos casos, la regla de hacia dónde deben apuntar las dependencias la tiene que escribir alguien.

🔬 **El detalle:** El compilador de Go prohíbe ciclos, no dependencias en la dirección equivocada; esa sigue necesitando depguard u otra regla.

### 18. 🟡 ¿Qué verifican ArchUnit en Java e import-linter en Python, y qué dejan fuera?

⏱️ **30 segundos:** ArchUnit verifica dependencias entre paquetes Java, incluidas reglas de capas y de onion; import-linter verifica imports entre paquetes Python con contratos de capas o prohibiciones. Los dos dejan fuera lo que no es un import.

🗣️ **2 minutos:** Ninguno ve un acceso por SQL a la tabla de otro módulo, una llamada por reflexión o una dependencia de runtime por configuración. Tampoco dicen si el límite está en el lugar correcto: verifican la regla que se les da. Son necesarios para que el estilo sobreviva, no suficientes para demostrar modularidad.

🔬 **El detalle:** Los dos permiten excepciones explícitas; esas excepciones deberían llevar dueño y fecha.

### 19. 🟠 Añadir la expiración de reservas tocó nueve archivos en cuatro capas. ¿Qué estilo lo arreglaría y qué comprobarías antes?

⏱️ **30 segundos:** Ninguno por sí solo: el cambio cruzó `orders` e `inventory`, así que primero comprobaría si la regla de expiración tiene un dueño claro y si el límite entre capacidades es correcto.

🗣️ **2 minutos:** Si la expiración es una regla de `inventory` y hoy vive repartida en servicios de ambos, el arreglo es darle hogar en `inventory` con una API que `orders` llame. Después, dentro de `inventory`, el estilo interno puede reducir los archivos tocados. Cambiar a clean sin mover la regla dejaría nueve archivos en cuatro anillos.

🔬 **El detalle:** Medir sobre varios cambios, no solo sobre el más doloroso, dice si el problema es el límite o el estilo.

### 20. 🟠 El tech lead propone migrar todo el monolito a *clean architecture* en un trimestre. ¿Qué preguntas harías?

⏱️ **30 segundos:** Qué problema concreto resuelve, en qué módulos hay reglas que aislar de la infraestructura, cuánto cuesta el mapeo en los módulos CRUD y cómo se verificará la regla.

🗣️ **2 minutos:** Una migración total a clean paga interfaces y mapeos también donde no hay nada que aislar, y durante un trimestre convive con la estructura vieja. Propondría empezar por el módulo con más reglas y más cambios, medir si los cambios siguientes se localizan mejor, y decidir el resto con esa evidencia.

🔬 **El detalle:** Si el problema real es el límite entre capacidades, la migración a clean no lo toca; conviene saberlo antes del trimestre.

### 21. 🟠 Un equipo organizó `orders` en slices y ahora cada slice valida el pedido a su manera. ¿Qué harías?

⏱️ **30 segundos:** Mover la validación del pedido a un modelo o servicio de dominio del módulo `orders`, que todos los slices usen.

🗣️ **2 minutos:** La validación del pedido es una regla de `orders`, no de cada caso de uso. Los slices siguen siendo independientes en entrada, orquestación y consultas, y comparten la regla que no debe divergir. Una prueba de módulo sobre la regla evita que vuelva a copiarse.

🔬 **El detalle:** El síntoma es la señal típica de que un módulo en slices necesita un Domain Model para sus invariantes.

### 22. 🟠 Quieres introducir la regla de dependencias en un módulo existente sin frenar al equipo. ¿Cómo lo harías de forma reversible?

⏱️ **30 segundos:** Escribiendo la regla en ArchUnit, import-linter u otra herramienta, congelando las violaciones existentes y haciendo fallar solo las nuevas.

🗣️ **2 minutos:** Primero la regla en modo informe, para ver cuántas violaciones hay. Después, fallo solo para las nuevas y un plan para reducir las existentes cuando se toque el código cercano. Si la regla resulta equivocada, se retira sin haber reorganizado nada.

🔬 **El detalle:** La reversibilidad está en que la regla se activa antes que la reorganización: primero se deja de empeorar, después se mejora.

### 23. 🟠 Dos desarrolladores discuten si `inventory` debe ser capas o hexagonal. ¿Cómo decidirías?

⏱️ **30 segundos:** Por el dominio de `inventory`: si tiene invariantes ricas —reservas, expiración, stock— que conviene probar sin base, dependencias hacia el dominio; si es sobre todo CRUD, capas.

🗣️ **2 minutos:** Pido ejemplos de cambios recientes: ¿cuántos tocaron reglas y cuántos solo datos? ¿Hay dependencias externas que convenga poder sustituir? Si la respuesta es «reglas y adaptadores», hexagonal compra algo; si es «formularios y tablas», capas es más barato. La decisión es del módulo, no del sistema.

🔬 **El detalle:** Ambos pueden coexistir en fases: capas hoy y puertos donde aparezca una dependencia externa que aislar.

### 24. 🟠 ¿Qué criterio te diría que un módulo necesita pasar de Transaction Script a Domain Model?

⏱️ **30 segundos:** Cuando las reglas se duplican entre scripts, las invariantes cruzan varias operaciones y los defectos aparecen por reglas aplicadas en un sitio y olvidadas en otro.

🗣️ **2 minutos:** Si la regla de reserva aparece en cinco scripts con variaciones, un cambio de política exige tocarlos todos y probar que no divergen. Un Domain Model concentra la regla en un lugar. Mientras los scripts sean pocos y las reglas simples, el cambio no compensa.

🔬 **El detalle:** El paso puede ser gradual: extraer primero la regla más duplicada a un objeto de dominio y dejar el resto como scripts.

## 🎤 Respuestas de la simulación

### S1. 🟢 ¿Cómo explicarías un monolito que ejecuta ocho réplicas?

⏱️ **30 segundos:** Como una única unidad de despliegue que se ejecuta en ocho copias equivalentes para repartir la carga.

🗣️ **2 minutos:** Las ocho réplicas ejecutan el mismo artefacto y la misma versión, así que se escala horizontalmente sin cambiar la topología. Lo que hay que comprobar es que no guarden estado propio: sesión, jobs programados o cachés que decidan algo. Con eso resuelto, un monolito escala por réplicas como cualquier otro servicio sin estado.

🔬 **El detalle:** El límite habitual aparece en la base: ocho pools de conexiones contra una misma instancia.

### S2. 🟢 ¿Puede un módulo pertenecer a un monolito y tener dueño propio?

⏱️ **30 segundos:** Sí: el módulo es una unidad de cambio con dueño; el despliegue común no impide que un equipo lo posea.

🗣️ **2 minutos:** `payments` puede tener un equipo que decide sus reglas, cuida sus tablas y responde por sus incidentes, aunque salga en el mismo release que el resto. El ownership se da con autoridad, datos y operación, no con un repositorio o un contenedor propios. Lo que no tiene es cadencia de despliegue independiente.

🔬 **El detalle:** Si esa cadencia llega a ser un problema medido, entonces se discute otra unidad de despliegue.

### S3. 🟢 ¿Qué distingue estructura interna de topología?

⏱️ **30 segundos:** La topología dice cómo se despliega y ejecuta el sistema; la estructura interna, cómo se organiza y limita el código dentro de esa unidad.

🗣️ **2 minutos:** Un monolito puede tener estructura por capas, modular o ser una bola de barro; un sistema distribuido también. Son ejes distintos, y el error típico es proponer un cambio de topología para arreglar un problema de estructura. Se diagnostica cada uno con su evidencia: pipeline y releases para la topología, cambios e imports para la estructura.

🔬 **El detalle:** El estilo interno —capas, clean, vertical slice— es un tercer eje, dentro de cada módulo.

### S4. 🟢 ¿Qué significa unidad de datos en `CreateOrder`?

⏱️ **30 segundos:** Qué datos se confirman juntos y quién es dueño de cada uno: pedido, reserva y trabajo pendiente en un `COMMIT`, cada uno escrito por su módulo.

🗣️ **2 minutos:** En `CreateOrder`, la unidad de datos es lo que la transacción local protege: `orders` escribe el pedido, `inventory` la reserva, y se registra el trabajo de pago. El proveedor externo queda fuera. Nombrar esa unidad dice qué garantía existe y qué necesitará reconciliación.

🔬 **El detalle:** Compartir base no significa compartir propiedad: cada tabla sigue teniendo un único escritor.

### S5. 🟡 ¿Por qué contar repositorios no clasifica la arquitectura?

⏱️ **30 segundos:** Porque el repositorio no determina ni el despliegue, ni los datos, ni los equipos.

🗣️ **2 minutos:** Un monorepo puede contener servicios autónomos y varios repositorios pueden ensamblarse en un monolito. Clasificar exige seguir un cambio real: qué artefactos se produjeron, qué se liberó junto, qué tablas se tocaron y qué equipos intervinieron. El número de repositorios es una pista sobre el historial del código, nada más.

🔬 **El detalle:** Es la versión más frecuente del error de clasificar por una sola señal.

### S6. 🟡 ¿Cómo reconocerías cohesión en `inventory`?

⏱️ **30 segundos:** En que sus elementos comparten lenguaje e invariantes de stock y cambian por las mismas razones.

🗣️ **2 minutos:** Reservar, liberar, calcular disponibilidad y aplicar vencimientos pertenecen a la misma responsabilidad: cambios en la política de reservas se quedan dentro de `inventory`. Si aparecen responsabilidades ajenas —enviar correos, calcular precios—, la cohesión baja y los cambios empiezan a arrastrar código que no tiene que ver.

🔬 **El detalle:** Lo confirma el historial: los cambios de `inventory` rara vez deberían tocar otros módulos.

### S7. 🟡 ¿Qué precio tiene una llamada local?

⏱️ **30 segundos:** Acoplamiento de código y de destino de fallo: quien llama depende del otro módulo y cae con él si el proceso cae.

🗣️ **2 minutos:** La llamada local es rápida, tiene error directo y puede compartir transacción, pero no aísla recursos: un consumo excesivo de un módulo afecta a todos. Además, sin límites claros, es fácil que la comodidad lleve a llamar a internos ajenos. El precio se paga en disciplina y en aislamiento, no en red.

🔬 **El detalle:** Para la mayoría de colaboraciones internas es un precio muy bajo comparado con la alternativa remota.

### S8. 🟡 ¿Qué precio añade una llamada remota?

⏱️ **30 segundos:** Serialización, latencia, timeouts, fallos parciales, versiones mixtas del contrato y pérdida de la transacción local.

🗣️ **2 minutos:** Una llamada remota puede fallar después de haber ejecutado, obliga a modelar resultados inciertos y exige compatibilidad entre versiones durante los despliegues. A cambio puede comprar despliegue y escala independientes. El precio se justifica cuando esa independencia hace falta, no por defecto.

🔬 **El detalle:** También añade observabilidad distribuida: sin trazas, un fallo entre servicios es difícil de atribuir.

### S9. 🟡 ¿Cómo medirías acoplamiento de cambio?

⏱️ **30 segundos:** Con el historial: qué partes cambian juntas de forma recurrente y por qué razones.

🗣️ **2 minutos:** Cuento cambios de una muestra representativa que tocan varios módulos, reviso el motivo de cada uno y separo las razones de negocio compartidas de las coincidencias —reformateos, migraciones—. Un patrón estable de co-cambio con la misma razón indica una responsabilidad repartida o un límite mal puesto.

🔬 **El detalle:** Un único commit transversal no demuestra nada; la frecuencia y la causa sí.

### S10. 🟡 ¿Qué evidencia necesitarías para llamar big ball of mud a un monolito?

⏱️ **30 segundos:** Un patrón sostenido de cambios impredecibles que cruzan dominios, escrituras sin dueño, ciclos y pruebas que solo funcionan de extremo a extremo.

🗣️ **2 minutos:** No basta con que el código sea antiguo o tenga un solo artefacto. Sigo cambios recientes, dibujo imports y escrituras, busco quién puede predecir el impacto de un cambio y reviso las excepciones arquitectónicas. Si todo apunta a lo mismo de forma recurrente, el diagnóstico se sostiene.

🔬 **El detalle:** La etiqueta es útil solo si orienta una acción concreta, como recuperar una costura.

### S11. 🟡 ¿Cuándo una duplicación pequeña puede ser razonable?

⏱️ **30 segundos:** Cuando cada módulo necesita su propia representación, la divergencia no rompe ninguna invariante y compartir obligaría a coordinar.

🗣️ **2 minutos:** `orders` y `notifications` pueden tener cada uno su validador de dirección si uno la usa para entregar paquetes y el otro para contactar. Unificarlos crearía un dueño común y consumidores coordinados para un concepto que en realidad son dos. La duplicación pequeña compra evolución independiente.

🔬 **El detalle:** Si la divergencia tuviera consecuencias de negocio, como importes distintos, compartir sí sería lo correcto.

### S12. 🟡 ¿Qué no compra una base física por capacidad?

⏱️ **30 segundos:** Autonomía de despliegue, de código ni de equipos: solo separa el almacenamiento.

🗣️ **2 minutos:** Una base por capacidad sin dueños de escritura claros hereda el acoplamiento como sincronizaciones o dual writes. Y si los módulos siguen saliendo juntos y compartiendo modelo, la base separada solo añade operación. Primero se asigna la propiedad; la separación física llega si compra algo concreto.

🔬 **El detalle:** Sí puede comprar aislamiento de recursos o de fallos de la base, si eso es lo que se necesita.

### S13. 🟡 ¿Qué preguntarías ante una petición de microservicios?

⏱️ **30 segundos:** Qué problema se quiere resolver, con qué evidencia, qué restricción lo exige y qué coste está dispuesta a pagar la organización.

🗣️ **2 minutos:** Convierto la petición en preguntas verificables: ¿qué cambios esperan hoy?, ¿qué recurso se satura?, ¿hay requisitos de aislamiento?, ¿quién hará la guardia? Con las respuestas comparo opciones, incluida la de no distribuir. Si la petición no tiene un problema detrás, lo digo y propongo una revisión con fecha.

🔬 **El detalle:** La pregunta sobre la guardia suele ser la que más cambia la conversación.

### S14. 🟡 ¿Cómo diferencias autonomía de aislamiento?

⏱️ **30 segundos:** La autonomía es poder decidir, cambiar y desplegar sin esperar a otros; el aislamiento es que un fallo o un consumo de recursos no afecte a los demás.

🗣️ **2 minutos:** Un worker separado aísla la CPU de `notifications` sin darle autonomía de despliegue. Un módulo con equipo propio en un monolito puede tener autonomía de decisión sin aislamiento de fallos. Distinguirlos permite elegir la solución barata: a veces basta con aislar recursos, sin crear un servicio.

🔬 **El detalle:** Los servicios suelen dar ambas cosas, pero a un precio que no siempre hace falta pagar.

### S15. 🟡 ¿Puede un sistema modular fallar por una dependencia externa?

⏱️ **30 segundos:** Sí: la modularidad protege los cambios internos, no la disponibilidad de un proveedor externo.

🗣️ **2 minutos:** Aunque el código esté bien organizado, si `payments` depende de un proveedor que responde lento, checkout puede degradarse. Hace falta tratarlo como dependencia remota: presupuesto de tiempo, estado pendiente, reconciliación y aislamiento de recursos para que no arrastre al resto. La calidad interna y la resiliencia son problemas distintos.

🔬 **El detalle:** Un monolito modular con una dependencia externa mal gestionada sigue teniendo fallos parciales.

### S16. 🟡 ¿Qué deberías conservar al modularizar?

⏱️ **30 segundos:** Las garantías locales —transacciones, llamadas en proceso— y el comportamiento observable del sistema.

🗣️ **2 minutos:** Modularizar no debe romper la invariante de pedido y reserva ni cambiar lo que ven los clientes. Por eso se caracteriza el comportamiento antes de mover código, se mantienen las transacciones que protegen invariantes y se introduce un límite a la vez. Si un paso rompe una garantía, se revierte.

🔬 **El detalle:** También se conserva la capacidad de entregar: la modularización no justifica congelar el negocio.

### S17. 🟡 ¿Cómo cambia tu recomendación con un dominio volátil?

⏱️ **30 segundos:** Hacia límites locales, baratos de mover, y revisiones frecuentes con evidencia de dónde se concentran los cambios.

🗣️ **2 minutos:** Con un dominio volátil evito contratos remotos y modelos compartidos grandes, que fijan fronteras que pronto estarán mal. Prefiero un monolito modular con dueños de datos y métricas de cambio, y registro cuándo revisar. A medida que el dominio se estabiliza, los límites se confirman y, si hace falta, se distribuyen.

🔬 **El detalle:** La volatilidad es una restricción que favorece lo local, igual que una invariante fuerte.

### S18. 🟡 ¿Qué datos organizativos pedirías antes de distribuir?

⏱️ **30 segundos:** Cuántos equipos hay, qué capacidades posee cada uno, cuánto esperan por coordinación y quién podría hacer la guardia de cada servicio.

🗣️ **2 minutos:** Distribuir sin equipos que puedan poseer y operar cada frontera crea servicios huérfanos. Pido ver cambios que cruzan equipos, tiempos de espera y cobertura de guardia actual. Si un solo equipo opera todo, la independencia organizativa que dan los servicios no aporta mucho.

🔬 **El detalle:** La ley de Conway recuerda que la estructura de comunicación terminará reflejándose en el sistema.

### S19. 🟡 ¿Cómo justificas una fecha de revisión?

⏱️ **30 segundos:** Porque convierte la decisión en una hipótesis que se comprueba en un momento acordado, en lugar de dejarla abierta a la presión o al olvido.

🗣️ **2 minutos:** «Revisar en tres meses o si `payments` provoca dos incidentes de aislamiento» da un plazo y una señal concreta. En la revisión se miran los datos recogidos y se decide con ellos. Sin fecha, la decisión se reabre cuando alguien se cansa, y se discute con opiniones.

🔬 **El detalle:** La fecha protege también a quien decidió: deja claro qué se sabía y qué se esperaba aprender.

### S20. 🟡 ¿Qué métrica de escalado puede engañar?

⏱️ **30 segundos:** El número de usuarios registrados, la CPU media o el número de peticiones sin distribución.

🗣️ **2 minutos:** Un millón de usuarios puede ser poca carga concurrente; una CPU media del 30 % puede esconder picos del 100 %; y el total de peticiones no dice qué recurso se satura. Las métricas útiles son el pico por operación, los percentiles de latencia y el recurso limitante en ese pico, por ejemplo el pool de conexiones.

🔬 **El detalle:** Una métrica engañosa suele llevar a escalar lo que no es el cuello.

### S21. 🟡 ¿Por qué elegir entre capas y *clean architecture* no responde dónde termina `orders`?

⏱️ **30 segundos:** Porque capas y clean deciden la dirección de las dependencias dentro del código, no el límite entre capacidades.

🗣️ **2 minutos:** Dónde termina `orders` se decide por lenguaje, invariantes, datos y razones de cambio. Una vez fijado, capas o clean organizan su interior. Un sistema puede ser impecable en clean y tener `orders` e `inventory` mezclados en el mismo anillo.

🔬 **El detalle:** Por eso el orden de decisión es primero el límite por capacidad y después el estilo de cada módulo.

### S22. 🟡 ¿Qué ganarías y qué pagarías con un Domain Model en `inventory` y Transaction Scripts en los listados?

⏱️ **30 segundos:** Ganarías invariantes de reserva concentradas y probables sin base, y listados simples sin ceremonia; pagarías dos estilos que el equipo debe reconocer.

🗣️ **2 minutos:** Las reservas tienen reglas de stock, expiración y concurrencia que merecen un modelo; un listado de pedidos no tiene ninguna. Aplicar a cada uno lo que necesita evita mapeos inútiles en el listado y reglas dispersas en la reserva. El coste es explicar y documentar por qué conviven.

🔬 **El detalle:** Es la aplicación directa de elegir el patrón por operación y no por sistema.

### S23. 🟡 ¿Cómo explicarías que un sistema hexagonal puede desplegarse como un monolito o como varios servicios?

⏱️ **30 segundos:** Hexagonal organiza el interior de una aplicación y sus puertos; cuántos procesos se despliegan es otra decisión, la topología.

🗣️ **2 minutos:** Un monolito puede tener cada módulo con sus puertos y adaptadores y desplegarse como un solo artefacto. Si un día se extrae un módulo, sus puertos facilitan cambiar un adaptador local por uno remoto, pero la extracción sigue pagando red, contratos y datos. Hexagonal no obliga a distribuir ni lo impide.

🔬 **El detalle:** La confusión aparece porque hexagonal se popularizó junto con los microservicios; son decisiones independientes.

### S24. 🟡 ¿Qué evidencia de cambio te diría que el estilo interno de un módulo ya no le sirve?

⏱️ **30 segundos:** Cambios que tocan muchos archivos dentro del módulo para una sola regla, reglas duplicadas que divergen, o capas que solo delegan sin aportar nada.

🗣️ **2 minutos:** Si cada cambio de reserva recorre controller, service, repository y DTO sin lógica en ninguno, el estilo es ceremonia; si la misma regla aparece en varios scripts, falta un modelo. El historial de cambios del módulo lo muestra mejor que una revisión de diagrama.

🔬 **El detalle:** La evidencia se busca dentro del módulo; si los cambios cruzan módulos, el problema es el límite, no el estilo.

### S25. 🟡 ¿Qué regla automatizada pedirías antes de aceptar que un equipo «ya usa clean architecture»?

⏱️ **30 segundos:** Una regla en CI que falle si el dominio o la aplicación importan infraestructura: por ejemplo, un `onionArchitecture()` de ArchUnit o un contrato de capas en import-linter.

🗣️ **2 minutos:** Sin regla, clean es una intención que dura hasta el primer atajo. Con la regla, una entidad de dominio que importa el driver rompe el build. Pido además ver las excepciones registradas: pocas y con fecha indican disciplina; muchas y viejas, un estilo nominal.

🔬 **El detalle:** La regla verifica la dirección de dependencias, no la calidad del modelo; un dominio anémico puede pasarla.

### S26. 🟠 ¿Un monolito con plugins sigue siendo monolito?

⏱️ **30 segundos:** Sí, si se despliega y versiona como una unidad: los plugins cargados en el mismo proceso no son servicios autónomos.

🗣️ **2 minutos:** Los plugins pueden tener repositorios y equipos propios, pero si se ejecutan dentro del proceso principal y comparten su ciclo de vida, la topología sigue siendo monolítica. Lo interesante es que pueden aportar límites internos claros. Si un plugin se despliega y ejecuta aparte con su contrato, ya es otra unidad.

🔬 **El detalle:** Los plugins comparten destino de fallo: uno que agota memoria tumba al anfitrión.

### S27. 🟠 ¿Eliminar todas las dependencias mejoraría el sistema?

⏱️ **30 segundos:** No: un sistema útil coordina capacidades; eliminar todas las dependencias lo dejaría sin comportamiento.

🗣️ **2 minutos:** El objetivo no es la ausencia de acoplamiento, sino acoplamiento explícito, necesario y proporcional. `orders` tiene que depender de alguna promesa de `inventory` para reservar. Lo que se elimina es el acoplamiento accidental y lejano; lo necesario se hace visible y se cuida.

🔬 **El detalle:** Intentar eliminar todas las dependencias suele producir indirecciones que las esconden sin quitarlas.

### S28. 🟠 ¿Puedes recomendar no cambiar la arquitectura?

⏱️ **30 segundos:** Sí, si la evidencia muestra que la arquitectura actual cumple las restricciones y que el cambio costaría más de lo que aporta.

🗣️ **2 minutos:** Una recomendación senior puede ser mantener el sistema, con mejoras puntuales y una revisión con fecha. Lo defiendo con datos: los cambios se entregan sin esperas, la carga cabe, no hay incidentes de aislamiento. Y dejo escrito qué señal haría reabrir la decisión, para que no se lea como inmovilismo.

🔬 **El detalle:** Recomendar no cambiar también requiere coraje en una entrevista; se sostiene con evidencia, no con preferencia.

### S29. 🟠 ¿Una transacción entre módulos demuestra que el límite es malo?

⏱️ **30 segundos:** No: puede reflejar una invariante real que ambos módulos protegen juntos.

🗣️ **2 minutos:** Si pedido y reserva deben confirmarse juntos, una transacción que cruza `orders` e `inventory` es la forma correcta de cumplirlo, mientras cada módulo escriba solo sus tablas a través de su API. Solo es sospechosa si engloba cosas que podrían confirmarse por separado o si un módulo escribe datos del otro directamente.

🔬 **El detalle:** La frontera transaccional y la propiedad de datos son preguntas distintas; se responden por separado.

### S30. 🟠 ¿La arquitectura más fácil de explicar siempre es la mejor?

⏱️ **30 segundos:** No: lo fácil de explicar puede esconder costes o no cumplir restricciones; la mejor es la que cumple las garantías al menor coste total.

🗣️ **2 minutos:** «Un servicio por entidad» es fácil de dibujar y produce cadenas largas y datos repartidos. «Todo en un bloque sin límites» también es fácil y produce barro. La claridad de la explicación es un valor, pero secundario frente a garantías, coste de cambio y operación.

🔬 **El detalle:** Una arquitectura buena debería poder explicarse con claridad, pero la implicación inversa no se cumple.

### S31. 🟠 En E1, ¿qué construirías primero y qué te haría revisar la topología?

⏱️ **30 segundos:** Un monolito modular con `orders`, `inventory`, `payments` y `notifications` como módulos, pedido y reserva en una transacción, y una revisión con umbrales de carga y cambio.

🗣️ **2 minutos:** Construiría primero el flujo de compra con su invariante de stock, un pago con estado pendiente para el proveedor externo y avisos como trabajo durable, sin contratos remotos internos. Revisaría la topología si aparecen equipos con cadencias distintas, un requisito de aislamiento o una carga medida que el despliegue común no absorba. La garantía prioritaria es un pedido trazable con reserva válida.

🔬 **El detalle:** La primera acción reversible es precisamente esa: un flujo acotado que valide el negocio sin fijar fronteras remotas.

### S32. 🟠 En E2, ¿qué unidades nombras antes de juzgar los veinte procesos?

⏱️ **30 segundos:** Artefacto, versión, réplica, proceso, datos, despliegue y equipo: primero qué ejecuta cada proceso y qué se libera junto.

🗣️ **2 minutos:** Si los veinte procesos corren el mismo artefacto y la misma versión, son réplicas de una unidad y la pregunta pasa a ser cómo manejan el estado: sesiones, jobs y cachés. Compruebo con una inspección —imágenes, versiones, configuración— sin tocar la topología. Solo después tiene sentido hablar de dividir, si hay una razón para ello.

🔬 **El detalle:** La garantía que importa es la continuidad del flujo al cambiar de réplica; veinte procesos con sesión en memoria la rompen.

### S33. 🟠 En E3, ¿qué evidencia permitiría mantener el código antiguo?

⏱️ **30 segundos:** Cambios de stock entregados sin incidentes, tiempos de cambio razonables, límites identificables y una operación que se recupera bien.

🗣️ **2 minutos:** Si el sistema antiguo cambia de forma predecible y cumple sus garantías, la antigüedad no es un argumento. Lo contrasto con una caracterización del comportamiento de reserva y con datos de defectos y tiempos de entrega. Registro aparte los riesgos reales de soporte —dependencias sin mantenimiento, conocimiento concentrado— y los trato como tales.

🔬 **El detalle:** Modernizar por la fecha de creación paga un coste seguro por un riesgo que nadie ha demostrado.

### S34. 🟠 En E4, ¿cómo valoras mantener la validación duplicada?

⏱️ **30 segundos:** Primero averiguo si validan el mismo concepto: si una dirección es de entrega física y otra de contacto, la duplicación es correcta.

🗣️ **2 minutos:** `orders` valida dónde entregar un paquete; `notifications`, cómo contactar al cliente. Parecen iguales y cambian por razones distintas. Comparo sus razones de cambio y quién decide cada regla antes de unificar. Si resultan ser la misma invariante, asigno un dueño y comparto un tipo pequeño; si no, mantengo la duplicación.

🔬 **El detalle:** Centralizar por similitud sintáctica crea un dueño común para dos conceptos y coordina cambios que no tenían por qué coordinarse.

### S35. 🟠 En E5, ¿qué concluyes del build compartido?

⏱️ **30 segundos:** Solo que existe coordinación de compilación.

🗣️ **2 minutos:** Pruebo si cada artefacto puede liberarse con versiones ajenas vigentes; luego evalúo cambio y runtime.

🔬 **El detalle:** Un monorepo ni garantiza ni impide autonomía.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [07 — Simulación de entrevista: Fundamentos y modelo mental](07-simulacion-de-entrevista.md).

**Siguiente:** [01 — Módulos alrededor de capacidades de negocio](../02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md).
