# 08 — Respuestas: Modularidad y límites internos

> Solucionario completo de los capítulos `01`–`06` y de la simulación. Cada enunciado se conserva literalmente y cada respuesta usa tres capas.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#-01--módulos-alrededor-de-capacidades-de-negocio) · [02](#-02--api-pública-del-módulo-y-encapsulación-interna) · [03](#-03--dirección-de-dependencias-y-ciclos-entre-módulos) · [04](#-04--propiedad-de-datos-en-una-base-compartida) · [05](#-05--comunicación-interna-llamadas-comandos-y-eventos) · [06](#-06--código-compartido-shared-kernel-y-controles-arquitectónicos) · [Simulación](#-respuestas-de-la-simulación)

## 📖 01 — Módulos alrededor de capacidades de negocio

### 1. 🟢 ¿Qué diferencia hay entre una capa técnica y una capacidad de negocio?

⏱️ **30 segundos:** La capa agrupa código por rol técnico —controlador, servicio, repositorio—; la capacidad agrupa por algo que el negocio sabe hacer, con sus reglas y sus datos.

🗣️ **2 minutos:** `controllers/` o `repositories/` separan responsabilidades técnicas que toda capacidad necesita. `inventory`, en cambio, reúne el lenguaje, las invariantes y los datos de disponibilidad y reserva. Un cambio de negocio suele quedar dentro de una capacidad y atravesar todas las capas, por eso la capacidad es mejor unidad principal de organización.

🔬 **El detalle:** Las capas pueden seguir existiendo dentro de cada módulo; no compiten con las capacidades, se anidan en ellas.

### 2. 🟢 ¿Qué es un subdominio?

⏱️ **30 segundos:** Una parte del espacio del problema del negocio que contiene conocimiento relacionado.

🗣️ **2 minutos:** Sirve para analizar dónde cambian el lenguaje, las reglas y el valor: gestión de pedidos, inventario, cobros. Es una herramienta de descubrimiento, no una prescripción: un subdominio no se convierte automáticamente en un paquete ni en un servicio. Ayuda a decidir dónde invertir modelado y dónde bastan soluciones simples.

🔬 **El detalle:** El diseño selecciona qué partes modelar y cómo materializarlas; el subdominio describe el problema, no la solución.

### 3. 🟢 ¿Qué es un contexto acotado?

⏱️ **30 segundos:** El límite dentro del cual un modelo y su lenguaje mantienen un significado consistente.

🗣️ **2 minutos:** Fuera del contexto, el mismo término puede significar otra cosa: «reserva» puede ser un bloqueo de stock para `inventory` y una cita para otro equipo. Dentro, cada palabra tiene un solo sentido y las reglas son coherentes. Donde dos contextos se tocan, hace falta una traducción explícita.

🔬 **El detalle:** Un contexto acotado es un límite de modelo, no de despliegue: puede vivir dentro de un monolito.

### 4. 🟢 ¿Qué es un módulo en un monolito modular?

⏱️ **30 segundos:** Un mecanismo de software que protege una responsabilidad de negocio dentro del despliegue, con API, dueño de datos y límites verificables.

🗣️ **2 minutos:** Es la unidad de cambio del monolito modular: `inventory` expone `ReserveInventory`, oculta su stock y es el único que escribe sus tablas. Se reconoce porque los cambios de su responsabilidad quedan dentro y porque una regla automatizada falla si alguien cruza su límite. Una carpeta sin eso no es un módulo.

🔬 **El detalle:** El módulo no es necesariamente un módulo del build; puede ser un paquete con visibilidad y una prueba arquitectónica.

### 5. 🟢 ¿Por qué capacidad, contexto y módulo no son equivalentes uno a uno?

⏱️ **30 segundos:** Porque responden a preguntas distintas —qué hace el negocio, dónde vale un modelo, cómo se organiza el código— y sus tamaños no coinciden.

🗣️ **2 minutos:** Un contexto grande puede necesitar varios módulos técnicos, y una capacidad pequeña puede convivir con otra en un mismo módulo mientras el equipo aprende. Forzar una correspondencia uno a uno produce módulos artificiales o contextos partidos. DDD aporta lenguaje para descubrir fronteras, no una fórmula.

🔬 **El detalle:** Lo importante es que el límite de código no parta un modelo que debe ser coherente.

### 6. 🟢 ¿Qué significa organizar por vertical slices?

⏱️ **30 segundos:** Agrupar el código por caso de uso o petición, de la entrada al acceso a datos, compartiendo lo mínimo entre slices.

🗣️ **2 minutos:** Cada slice —crear pedido, cancelar pedido— contiene lo que necesita y elige su técnica interna. Organiza el interior de una capacidad y evita capas de servicios compartidas que crecen con cada funcionalidad. No sustituye la frontera entre capacidades: un slice de `orders` puede seguir escribiendo tablas de `inventory` si nadie lo impide.

🔬 **El detalle:** La lógica común a varios slices tiene que vivir en algún sitio, normalmente un modelo de dominio del módulo, o se duplica.

### 7. 🟢 ¿Qué decisiones pertenecen a `inventory` en el sistema de ejemplo?

⏱️ **30 segundos:** La disponibilidad, las reservas, su vencimiento y su liberación, junto con el stock que las sustenta.

🗣️ **2 minutos:** `inventory` decide si hay unidades para reservar y cuánto dura una reserva; posee el stock y las reservas; publica reservar, liberar y consultar. `orders` pide una reserva y recibe un resultado, sin saber cómo se calcula. Si una política de reservas obligara a cambiar `orders`, el límite estaría mal.

🔬 **El detalle:** El catálogo de productos puede estar en otro módulo: stock y descripción cambian por razones distintas.

### 8. 🟡 ¿Por qué `controllers/services/repositories` no expresa ownership de negocio?

⏱️ **30 segundos:** Porque agrupa por rol técnico y reparte cada capacidad entre todas las capas, sin decir quién decide ni quién posee cada dato.

🗣️ **2 minutos:** En esa estructura, `CreateOrder` atraviesa tres carpetas y comparte modelos con reserva, pago y correo; añadir una política de expiración obliga a navegar por todas las capas. Nada impide que `OrderService` use `InventoryRepository`. La estructura no expresa ninguna frontera de negocio.

🔬 **El detalle:** Funciona bien mientras el dominio es pequeño; el problema aparece cuando los cambios empiezan a cruzar capacidades.

### 9. 🟡 ¿Qué evidencia usarías para proponer una frontera entre `orders` e `inventory`?

⏱️ **30 segundos:** Cambios reales, lenguaje distinto, invariantes propias y quién decide y escribe cada estado.

🗣️ **2 minutos:** Tomo cambios e incidentes recientes y veo qué reglas cambian juntas: las de disponibilidad y reserva frente a las del ciclo del pedido. Si el vocabulario difiere y cada lado tiene sus invariantes, la frontera es plausible. La confirmo diseñando una API mínima y comprobando que un cambio siguiente quede contenido.

🔬 **El detalle:** Un taller de notas adhesivas da hipótesis; los cambios reales las confirman o las descartan.

### 10. 🟡 ¿Cómo ayuda un cambio de significado en el lenguaje a descubrir límites?

⏱️ **30 segundos:** Cuando un término significa cosas distintas en dos conversaciones, suele haber dos modelos y una frontera posible entre ellos.

🗣️ **2 minutos:** «Precio» como valor de catálogo y «precio» como importe pactado en un pedido tienen reglas distintas: uno cambia con el catálogo, el otro queda fijado al comprar. Detectar ese cambio de significado sugiere dos modelos que no deben compartir un tipo. La inferencia se confirma con invariantes y con quién decide cada uno.

🔬 **El detalle:** Forzar un único modelo para los dos significados produce un tipo lleno de campos opcionales y reglas condicionales.

### 11. 🟡 ¿Qué indica que dos módulos candidatos deberían fusionarse?

⏱️ **30 segundos:** Que cada operación cruza ambos, el contrato repite el modelo entero y nadie puede explicar una decisión independiente de uno de ellos.

🗣️ **2 minutos:** Si `orders` e `inventory` se llaman en cada operación en ambos sentidos y comparten casi todos los datos, la frontera cuesta coordinación sin separar responsabilidades. Fusionarlos pierde una separación nominal y recupera cohesión real. Lo compruebo con varios cambios, no con uno.

🔬 **El detalle:** Un ciclo persistente entre dos módulos es una de las señales más claras de que deberían ser uno.

### 12. 🟡 ¿Qué indica que un módulo debería dividirse?

⏱️ **30 segundos:** Que dos políticas dentro de él evolucionan por motivos distintos, tienen dueños distintos o una parte necesita controles propios.

🗣️ **2 minutos:** Si la reposición de stock adquiere reglas, proveedores y cadencia propias, distinta de la reserva, puede merecer su propio módulo. La división se justifica con evidencia de cambio y de ownership. El tamaño en líneas no es un motivo: un módulo grande con una sola razón de cambio está bien así.

🔬 **El detalle:** Dividir crea un contrato más y coordinación; se paga cuando compra contención de cambios.

### 13. 🟡 ¿Por qué conviene empezar con límites relativamente gruesos?

⏱️ **30 segundos:** Porque todavía no se conocen bien las razones de cambio, y un límite grueso es más barato de corregir que muchos límites finos equivocados.

🗣️ **2 minutos:** Empezar con `inventory` incluyendo disponibilidad y reservas permite aprender dónde están las fronteras reales. Si después la reposición se diferencia, se divide con evidencia. Empezar con veinte módulos pequeños obliga a mantener muchos contratos que quizá estén mal puestos.

🔬 **El detalle:** Dentro de un monolito, dividir un módulo más tarde es un refactor; unir módulos que se separaron mal también, pero con más ruido.

### 14. 🟡 ¿Qué coste introduce una granularidad excesiva?

⏱️ **30 segundos:** Más navegación, más contratos internos y más coordinación para cambios que cruzan varios módulos.

🗣️ **2 minutos:** Con módulos demasiado finos, una regla de negocio se reparte entre varios y cada cambio toca varias APIs. El resultado se parece a un sistema distribuido sin red: mucha ceremonia y cambios que siempre cruzan fronteras. La fragmentación también acopla.

🔬 **El detalle:** El equilibrio se busca con los cambios: si casi todo cambio cruza dos módulos, probablemente sobran fronteras.

### 15. 🟡 ¿Cómo compruebas que un módulo contiene cambios en la práctica?

⏱️ **30 segundos:** Siguiendo cambios reales después de crearlo y viendo si quedan dentro del módulo o cruzan su límite.

🗣️ **2 minutos:** Tomo los siguientes cambios de su responsabilidad y cuento qué archivos, tablas y equipos tocan. Si una política de reservas se implementa entera dentro de `inventory`, el módulo contiene cambios. Si cada cambio obliga a tocar `orders` también, el límite no está sirviendo.

🔬 **El detalle:** Es la única prueba que importa; la estructura de carpetas y las reglas de imports son medios, no el objetivo.

### 16. 🟡 ¿Por qué una clase Java `public` o un `index.ts` no constituyen una API diseñada?

⏱️ **30 segundos:** Porque solo indican qué es accesible, no qué conversación se diseñó entre módulos.

🗣️ **2 minutos:** Una clase `public` en Java o un `index.ts` que reexporta todo hacen visible cualquier cosa a cualquier consumidor. Una API diseñada elige comandos, resultados y consultas mínimos para que el otro módulo decida sin conocer el interior. La visibilidad es el mecanismo; el diseño es la decisión de qué publicar.

🔬 **El detalle:** En TypeScript, lo que se exporta para un archivo vecino queda visible para todo el programa.

### 17. 🟡 ¿Qué preserva un corte vertical dentro de un único despliegue?

⏱️ **30 segundos:** Las garantías locales —llamadas en proceso y transacción compartida— con cambios contenidos por capacidad.

🗣️ **2 minutos:** El corte vertical organiza el código por responsabilidad sin introducir red: `orders` sigue llamando a `inventory` localmente y pedido y reserva pueden confirmarse en un `COMMIT` cuando la invariante lo pide. Se gana contención de cambios y propiedad clara sin pagar contratos remotos.

🔬 **El detalle:** También prepara, sin prometerla, una extracción futura: la API y el dueño de datos ya existen.

### 18. 🟠 Un cambio de promociones toca `orders`, `payments` y `notifications`. ¿Qué investigarías antes de crear un módulo `promotions`?

⏱️ **30 segundos:** Si la regla de promociones es realmente una responsabilidad propia o si se repartió entre módulos que deberían conservarla.

🗣️ **2 minutos:** Analizo qué cambió en cada módulo: si los tres implementan partes de la misma regla, falta un dueño; si cada uno adaptó algo propio por la promoción, puede ser una colaboración legítima. Reviso también la frecuencia: un caso aislado no justifica un módulo nuevo; un patrón sí.

🔬 **El detalle:** Crear `promotions` sin sacar de verdad la regla de los otros módulos añade un cuarto lugar que tocar.

### 19. 🟠 Dos equipos usan «reserva» con significados distintos. ¿Qué experimento de diseño propondrías?

⏱️ **30 segundos:** Un experimento que modele los dos significados por separado y compruebe si los cambios de cada uno quedan contenidos.

🗣️ **2 minutos:** Con los dos equipos, escribo ejemplos concretos de cada «reserva» y sus reglas. Si son conceptos distintos, les doy nombres distintos y los ubico en modelos separados, con una traducción donde se tocan. Pruebo el resultado con el siguiente cambio de cada equipo.

🔬 **El detalle:** Resolver una ambigüedad de lenguaje suele revelar una frontera mejor que cualquier diagrama.

### 20. 🟠 Cada operación de dos módulos cruza sus APIs y tablas. ¿Qué hipótesis formularías sobre el límite?

⏱️ **30 segundos:** Que el límite está mal puesto: los dos módulos protegen una sola responsabilidad o comparten una invariante que no admite separación.

🗣️ **2 minutos:** Si cada operación cruza sus APIs y tablas, la separación no contiene nada y solo cuesta coordinación. Formulo dos hipótesis: fusionarlos o mover la regla compartida a uno de ellos. Las pruebo con los cambios recientes para ver cuál los habría contenido mejor.

🔬 **El detalle:** Reducir el contrato sin cambiar la responsabilidad suele producir interfaces que copian el modelo entero.

### 21. 🟠 El equipo quiere un módulo por entidad de base de datos. ¿Cómo reorientarías la decisión?

⏱️ **30 segundos:** Hacia capacidades: un módulo debe reunir comportamiento e invariantes, no solo una tabla.

🗣️ **2 minutos:** Un módulo por entidad deja las reglas en quien llama: `stock` expone leer y escribir, y la regla de reserva termina en `orders`. Propongo agrupar por decisión —`inventory` decide reservas y posee stock y reservas— y mostrar con un cambio real cómo queda contenido. Las entidades son datos; las capacidades, decisiones.

🔬 **El detalle:** El corte por entidad es una de las causas típicas de monolito distribuido cuando además se distribuye.

### 22. 🟠 Un módulo crece, pero todos sus cambios siguen una misma política. ¿Lo dividirías?

⏱️ **30 segundos:** No por tamaño: si todos sus cambios siguen una misma política, el módulo es cohesivo y dividirlo añadiría contratos sin contener nada.

🗣️ **2 minutos:** El tamaño no es el criterio; la razón de cambio sí. Si el módulo crece porque la política se enriquece, puede organizarse por dentro con slices o subpaquetes sin crear una frontera nueva. Dividiría si aparecieran políticas con motivos o dueños distintos.

🔬 **El detalle:** Un módulo grande y cohesivo es más barato que dos pequeños que siempre cambian juntos.

### 23. 🟠 ¿Qué primera costura crearías en un monolito por capas sin mover todos los archivos?

⏱️ **30 segundos:** Una API para una sola capacidad —por ejemplo la reserva— delante de su código actual, con una regla que impida nuevos accesos directos.

🗣️ **2 minutos:** No hace falta mover todos los archivos: se crea la interfaz de `inventory`, se pasa un consumidor por ella y se prohíbe en CI que aparezcan nuevos accesos al repositorio de stock desde fuera. Después se migran los demás consumidores. Es reversible y demuestra el límite con un cambio real.

🔬 **El detalle:** Mover carpetas puede venir al final, cuando el límite ya existe en el código.

### 24. 🟠 ¿Qué criterio de parada usarías al reorganizar por capacidades?

⏱️ **30 segundos:** Que los cambios relevantes queden contenidos y el siguiente movimiento cueste más de lo que aporta.

🗣️ **2 minutos:** La reorganización no persigue un árbol perfecto. Si las capacidades que más cambian lo hacen dentro de su módulo y las regresiones bajan, seguir moviendo código añade riesgo sin beneficio. Me detengo, dejo las reglas en CI para conservar lo logrado y registro qué señal justificaría seguir.

🔬 **El detalle:** Fijar el criterio de parada antes de empezar evita que la reorganización se convierta en un proyecto permanente.

## 📖 02 — API pública del módulo y encapsulación interna

### 1. 🟢 ¿Qué es la API pública de un módulo?

⏱️ **30 segundos:** La superficie deliberada que otros módulos pueden usar: comandos, consultas publicadas, resultados y eventos, ocultando lo demás.

🗣️ **2 minutos:** No es todo lo que el lenguaje deja ver, sino lo que el módulo decide publicar para que otros colaboren con él sin conocer su interior. `InventoryApi.reserve` con resultados cerrados es una API; que `InventoryRepository` sea `public` no lo es. No necesita red: es un contrato dentro del mismo proceso.

🔬 **El detalle:** Una buena API interna protege invariantes y deja al módulo libre para cambiar su persistencia.

### 2. 🟢 ¿Qué diferencia hay entre accesibilidad y contrato diseñado?

⏱️ **30 segundos:** La accesibilidad dice qué puede usar el compilador; el contrato diseñado dice qué debería usar otro módulo y con qué garantías.

🗣️ **2 minutos:** Una clase pública es accesible, pero eso no la convierte en parte del contrato. Un contrato diseñado nombra intenciones, devuelve resultados útiles y oculta entidades y pasos internos. Confundirlos hace que cualquier clase visible se vuelva dependencia de otro módulo y el interior deje de poder cambiar.

🔬 **El detalle:** Por eso se complementa la visibilidad del lenguaje con reglas que prohíben usar lo accesible pero no publicado.

### 3. 🟢 ¿Qué expresa un comando interno?

⏱️ **30 segundos:** Una intención de otro módulo sobre la capacidad: «reserva estas unidades para este pedido».

🗣️ **2 minutos:** `ReserveInventory` dice qué se quiere, no cómo hacerlo: no expone el stock ni permite restarlo directamente. Así la regla de reserva se aplica siempre en `inventory`. Un CRUD genérico —«actualiza la fila de stock»— permitiría combinaciones inválidas que el comando impide.

🔬 **El detalle:** El comando puede devolver un resultado; que sea local permite que ese resultado sea inmediato.

### 4. 🟢 ¿Qué expresa una consulta publicada?

⏱️ **30 segundos:** Una vista de datos que el dueño decide exponer, con un significado y una forma que se compromete a mantener.

🗣️ **2 minutos:** `ProductAvailability` publica lo que otros necesitan saber del stock sin exponer tablas ni entidades. El dueño puede cambiar su almacenamiento mientras mantenga esa vista. Es preferible a que otros módulos lean las tablas directamente, que convierte el esquema en contrato accidental.

🔬 **El detalle:** La consulta publicada también fija su frescura y su coste; una vista cara usada en cada petición puede ser un problema.

### 5. 🟢 ¿Por qué conviene devolver un resultado explícito?

⏱️ **30 segundos:** Porque permite al consumidor decidir qué hacer sin interpretar excepciones internas ni estados ambiguos.

🗣️ **2 minutos:** Un resultado cerrado —reserva creada, stock insuficiente, conflicto— hace que `orders` trate cada caso explícitamente. Con un `sealed` en Java, si `inventory` añade un resultado, `orders` deja de compilar y el cambio de contrato se ve. Las excepciones internas, en cambio, filtran detalles y se olvidan de manejar.

🔬 **El detalle:** Los errores técnicos inesperados siguen siendo excepciones; los resultados de negocio van en el tipo.

### 6. 🟢 ¿Qué debería permanecer detrás del límite de `inventory`?

⏱️ **30 segundos:** La entidad de stock, el ORM, el repositorio, las tablas y la secuencia interna de validación.

🗣️ **2 minutos:** Todo eso puede cambiar sin que `orders` deba enterarse: cómo se guarda el stock, cómo se calcula la disponibilidad, qué índices hay. Si algo de eso sale del límite, `orders` depende de ello y el cambio interno se convierte en cambio de contrato. Solo cruzan comandos, resultados y vistas publicadas.

🔬 **El detalle:** En Java, ponerlo en el paquete raíz con visibilidad de paquete o protegerlo con JPMS o una regla arquitectónica.

### 7. 🟢 ¿Qué protege el directorio `internal` de Go?

⏱️ **30 segundos:** Que otros paquetes importen lo que está bajo `internal/` desde fuera del árbol de su padre; el compilador lo rechaza.

🗣️ **2 minutos:** Si el libro de stock vive en `inventory/internal/ledger`, `orders` no puede importarlo: el build falla con «use of internal package not allowed». Es un límite que aplica la herramienta, no una convención. Su alcance es el árbol: cualquier subpaquete de `inventory` sí puede importarlo.

🔬 **El detalle:** No protege contra SQL directo a las tablas ni contra reflexión; es un límite de código.

### 8. 🟡 ¿Por qué exponer un repository rompe la encapsulación del módulo?

⏱️ **30 segundos:** Porque permite a otro módulo leer y escribir el estado sin pasar por las reglas del dueño.

🗣️ **2 minutos:** Si `orders` usa `InventoryRepository`, puede cargar una fila y cambiar `reserved` saltándose la invariante de stock. Además, cualquier cambio en la persistencia de `inventory` afecta a `orders`. La encapsulación del módulo queda anulada aunque las carpetas parezcan separadas.

🔬 **El detalle:** Es de los atajos más frecuentes porque compila, es rápido y evita escribir una fachada.

### 9. 🟡 ¿Qué problema crea devolver una entidad ORM a otro módulo?

⏱️ **30 segundos:** Filtra el modelo de persistencia —campos, relaciones perezosas, ciclo de vida— y convierte cada detalle en dependencia del consumidor.

🗣️ **2 minutos:** Una entidad ORM mutable deja que el consumidor la modifique y la persista, aprende campos que el dueño querría cambiar y puede disparar cargas perezosas fuera de la sesión. Un resultado o una vista pequeña le dan lo que necesita decidir. El precio es un mapeo; el beneficio, que el esquema siga siendo del dueño.

🔬 **El detalle:** Los errores de serialización de entidades perezosas son un síntoma típico de ese filtrado.

### 10. 🟡 ¿Cuándo un tipo merece formar parte de la API?

⏱️ **30 segundos:** Cuando tiene semántica compartida estable y el consumidor necesita decidir con él.

🗣️ **2 minutos:** Un `ReservationResult` o un `OrderId` merecen estar en la API: expresan el resultado de la conversación. Un tipo que refleja el ORM o una regla interna no, porque cambiaría con la implementación. La pregunta es si el tipo describe la conversación o el interior.

🔬 **El detalle:** Cada tipo publicado es un compromiso; se publican pocos y se cuidan.

### 11. 🟡 ¿Por qué un CRUD genérico puede debilitar invariantes?

⏱️ **30 segundos:** Porque permite combinaciones de campos que ninguna regla del dueño validaría, como restar stock sin reserva.

🗣️ **2 minutos:** Una operación «actualiza stock» deja al consumidor decidir el nuevo valor y salta la lógica de reserva. Los comandos con intención —reservar, liberar— garantizan que cada cambio pase por la regla. El CRUD traslada la responsabilidad de la invariante a quien llama.

🔬 **El detalle:** Para consultas, un CRUD de lectura puede ser razonable; el riesgo está en las escrituras genéricas.

### 12. 🟡 ¿Qué ventaja tiene poder cambiar productor y consumidor en un mismo commit?

⏱️ **30 segundos:** Que los refactors del contrato son atómicos: cambias productor y consumidores en un commit, sin versiones mixtas.

🗣️ **2 minutos:** Dentro de un monolito, renombrar un resultado o dividir un comando no exige mantener dos versiones ni coordinar despliegues. Es una ventaja fuerte frente a una API remota, que obliga a expand-contract entre releases. Permite corregir errores de diseño de la API con poco coste.

🔬 **El detalle:** La ventaja desaparece si el módulo se consume desde fuera del artefacto o se retienen mensajes con el formato viejo.

### 13. 🟡 ¿Por qué aun así importa mantener una superficie estable?

⏱️ **30 segundos:** Porque una superficie pequeña reduce el radio de cambio, la carga cognitiva y los lugares donde puede romperse una invariante.

🗣️ **2 minutos:** Poder cambiar todo en un commit no significa que convenga hacerlo a menudo: cada cambio de API obliga a tocar a todos los consumidores y revisar sus casos. Una API pequeña y estable permite probar consumidores sin conocer el interior y muestra claramente quién escribe el estado.

🔬 **El detalle:** También prepara la convivencia de versiones si algún día hace falta, sin pagarla hoy.

### 14. 🟡 ¿Cuándo usarías una deprecación temporal dentro del monolito?

⏱️ **30 segundos:** Cuando una migración grande no puede ser atómica: se mantiene la ruta vieja un tiempo, marcada como obsoleta y con fecha de retirada.

🗣️ **2 minutos:** Si un cambio de contrato afecta a muchos consumidores y no cabe en un commit revisable, se publica la versión nueva, se migra consumidor a consumidor y se retira la vieja en la fecha fijada. Así se evita un cambio gigante sin acumular versiones indefinidamente.

🔬 **El detalle:** Una deprecación sin fecha ni seguimiento de uso se convierte en una segunda API permanente.

### 15. 🟡 ¿Qué diferencia práctica hay entre package-private de Java y un nombre no exportado de Go?

⏱️ **30 segundos:** Package-private en Java oculta a todo lo que no esté en el mismo paquete exacto; un nombre no exportado en Go oculta fuera del paquete, y `internal/` añade un nivel por árbol de directorios.

🗣️ **2 minutos:** En Java, un subpaquete no hereda la privacidad: para usar una clase desde `inventory.internal` hay que hacerla pública y queda visible para todos. En Go, la minúscula oculta dentro del paquete y `internal/` permite compartir entre subpaquetes del mismo árbol sin exponer fuera. Go da dos niveles; Java necesita JPMS o una regla arquitectónica para el segundo.

🔬 **El detalle:** En ambos, que algo sea accesible no significa que forme parte de un contrato bien diseñado.

### 16. 🟡 ¿Qué no resuelven por sí solos JPMS o `internal`?

⏱️ **30 segundos:** El diseño de la API, la propiedad de datos, la reflexión y el acceso SQL directo.

🗣️ **2 minutos:** JPMS puede exportar solo el paquete de API e `internal/` puede impedir imports, pero no deciden qué debe estar en la API ni impiden que otro módulo escriba las tablas por SQL. Un framework que instancia clases por reflexión también puede saltarse la visibilidad. Se complementan con permisos de base y pruebas arquitectónicas.

🔬 **El detalle:** Son mecanismos que protegen un límite ya decidido; no lo diseñan.

### 17. 🟡 ¿Por qué REST interno añade coste sin garantizar autonomía?

⏱️ **30 segundos:** Porque añade serialización, timeouts y semántica remota sin comprar despliegue independiente, y rompe la transacción local.

🗣️ **2 minutos:** Entre módulos del mismo proceso, una llamada local conserva error directo, transacción y latencia de función. REST interno obliga a manejar fallos parciales que no existían y a versionar contratos que se despliegan juntos. La red no crea encapsulación: la crea el diseño de la API.

🔬 **El detalle:** Si un módulo se extrae algún día, su contrato remoto se diseñará con los requisitos de ese momento.

### 18. 🟠 `orders` necesita mostrar disponibilidad de cien productos. ¿Diseñarías comando, consulta o acceso a tabla?

⏱️ **30 segundos:** Una consulta publicada de disponibilidad por lote, no un comando ni acceso a tablas.

🗣️ **2 minutos:** Mostrar disponibilidad es leer, no reservar, así que no es un comando. Cien consultas individuales serían ineficientes; una consulta que reciba cien SKU y devuelva su disponibilidad resuelve el caso y mantiene el límite. Acceder a la tabla directamente convertiría el esquema de `inventory` en contrato de `orders`.

🔬 **El detalle:** Si la frescura permitida es de segundos y la carga alta, una proyección de lectura puede ser mejor todavía.

### 19. 🟠 Un consumidor depende de quince campos de `InventoryReservation`. ¿Cómo reducirías el contrato sin ocultar información necesaria?

⏱️ **30 segundos:** Averiguo qué decide el consumidor con esos quince campos y le doy una vista o un resultado con exactamente eso.

🗣️ **2 minutos:** Reviso para qué usa cada campo: muchas veces necesita tres y los otros llegaron por arrastre de la entidad. Diseño una vista publicada con los datos necesarios para su decisión, la migro y retiro la exposición de la entidad. No oculto información que necesita: la expreso con un tipo que el dueño controla.

🔬 **El detalle:** Si el consumidor necesita casi todo el estado de otro módulo, quizá la regla que implementa pertenece a ese otro módulo.

### 20. 🟠 Un framework instancia por reflexión una clase interna. ¿Qué control adicional propones?

⏱️ **30 segundos:** Una regla arquitectónica que falle si alguien depende de la clase interna fuera del framework, y limitar la reflexión a la configuración.

🗣️ **2 minutos:** El framework necesita instanciarla, pero otros módulos no deberían usarla. Mantengo la clase fuera del paquete de API, restrinjo con una prueba arquitectónica qué puede depender de ella y, si el lenguaje lo permite, abro el paquete solo al framework. Así la reflexión técnica no se convierte en una puerta para otros módulos.

🔬 **El detalle:** En Java con JPMS se puede usar `opens` hacia el módulo del framework sin exportar el paquete a todos.

### 21. 🟠 Cambiar un resultado exige modificar seis consumidores. ¿Qué revisarías antes de versionar la API?

⏱️ **30 segundos:** Si los seis consumidores necesitan realmente distinguir ese resultado, o si la API expone demasiado del interior.

🗣️ **2 minutos:** Seis consumidores rotos pueden indicar un resultado demasiado detallado o consumidores que dependen de algo que no deberían. Antes de versionar, dentro del monolito basta con cambiar todo en un commit. Aprovecho para revisar si el contrato debería ser más pequeño y así reducir los cambios futuros.

🔬 **El detalle:** Versionar una API interna que se despliega junta añade deuda sin comprar compatibilidad real.

### 22. 🟠 Un equipo quiere una interfaz para cada repository «por si se extrae». ¿Cómo responderías?

⏱️ **30 segundos:** Que una interfaz debe representar una conversación entre módulos; crear una por repository no protege nada y promete una extracción que quizá no llegue.

🗣️ **2 minutos:** La preparación para extraer es tener una API de capacidad y dueño de datos, no interfaces sobre cada repositorio. Esas interfaces duplican firmas, dificultan la navegación y suelen exponer el modelo de persistencia. Propongo definir la API de `inventory` a nivel de capacidad y dejar los repositorios como detalle interno.

🔬 **El detalle:** Añadir una interfaz cuando aparece una segunda implementación real es barato dentro de un proceso.

### 23. 🟠 ¿Qué prueba demuestra que `orders` no conoce detalles de persistencia de `inventory`?

⏱️ **30 segundos:** Una regla arquitectónica que prohíba a `orders` depender de clases de persistencia de `inventory`, provocada con una violación deliberada.

🗣️ **2 minutos:** La prueba falla si `orders` importa el repositorio, la entidad o el paquete ORM de `inventory`. Se comprueba añadiendo un import prohibido y viendo que el build se pone en rojo. Para cubrir el SQL directo, se complementa con permisos de base o una revisión del acceso a datos.

🔬 **El detalle:** Una prueba de integración de `orders` con un doble de `InventoryApi` también demuestra que no necesita la persistencia ajena.

### 24. 🟠 ¿Qué criterio usarías para retirar una ruta de compatibilidad interna?

⏱️ **30 segundos:** Que ningún consumidor la use, medido, y que haya pasado la fecha acordada de la migración.

🗣️ **2 minutos:** Se instrumenta la ruta vieja para contar llamadas; cuando llega a cero durante el periodo acordado y todos los consumidores migraron, se elimina y se añade una regla que impida reintroducirla. Retirarla antes rompe a alguien; mantenerla indefinidamente convierte la compatibilidad temporal en una API más.

🔬 **El detalle:** La fecha se fija al crear la ruta de compatibilidad, no cuando alguien se acuerda de ella.

## 📖 03 — Dirección de dependencias y ciclos entre módulos

### 1. 🟢 ¿Qué representa una arista en el grafo estático?

⏱️ **30 segundos:** Que un módulo conoce a otro en compilación: un import, un tipo o una dependencia del build.

🗣️ **2 minutos:** La arista estática dice quién debe cambiar o recompilar si cambia el otro. `orders ──► inventory.api` significa que `orders` conoce la API de `inventory`, no que la llame en cada petición. Es el grafo que miden ArchUnit o dependency-cruiser, y el más fácil de hacer cumplir.

🔬 **El detalle:** Un grafo estático limpio no dice nada de datos compartidos ni de dependencias en runtime.

### 2. 🟢 ¿Qué representa una arista en el grafo runtime?

⏱️ **30 segundos:** Que un módulo activa a otro en ejecución: una llamada, un mensaje o un callback.

🗣️ **2 minutos:** La arista runtime dice quién necesita a quién para completar una operación y en qué orden. Puede ir en sentido contrario a la estática: con inversión de dependencias, `inventory` puede llamar a una interfaz que definió y que implementa `orders`. Es el grafo que decide disponibilidad y latencia.

🔬 **El detalle:** Un bus interno puede esconder aristas runtime detrás de suscripciones, lo que las hace más difíciles de ver.

### 3. 🟢 ¿Qué representa una arista en el grafo de datos?

⏱️ **30 segundos:** Que un módulo lee o escribe un estado: quién posee y quién modifica cada dato.

🗣️ **2 minutos:** La arista de datos revela acoplamientos que no aparecen en el código: si `payments` escribe el estado del pedido directamente, hay una dependencia de datos aunque no importe nada de `orders`. Es el grafo que decide quién puede garantizar una invariante y quién debe coordinar una migración.

🔬 **El detalle:** Las escrituras son las aristas importantes; las lecturas por vistas publicadas acoplan mucho menos.

### 4. 🟢 ¿Qué es un ciclo entre módulos?

⏱️ **30 segundos:** Una cadena de dependencias que vuelve al punto de partida: `orders` depende de `inventory`, que depende de `payments`, que depende de `orders`.

🗣️ **2 minutos:** El ciclo impide razonar, probar o cambiar una parte sin las demás: cualquier cambio puede propagarse en círculo. Puede aparecer en el grafo estático, en el runtime o en el de datos, y quitarlo de uno no lo quita de los otros. Es una señal que obliga a preguntar si el límite está bien puesto.

🔬 **El detalle:** Algunos lenguajes, como Go, prohíben los ciclos de import; eso no impide ciclos de datos ni de runtime.

### 5. 🟢 ¿Qué significa invertir una dependencia localmente?

⏱️ **30 segundos:** Que el módulo consumidor define la interfaz que necesita y otro la implementa, de modo que el import apunta hacia el consumidor.

🗣️ **2 minutos:** Si `inventory` necesita notificar algo sin conocer a `orders`, define `ReservationListener` en su propio paquete y `orders` lo implementa; la composición los conecta. Así la dependencia estática va de `orders` a `inventory`. Funciona si la abstracción vive con quien la necesita y expresa lo que necesita, no una copia del proveedor.

🔬 **El detalle:** Invertir el import no cambia la dependencia runtime: la llamada sigue ocurriendo.

### 6. 🟢 ¿Qué función cumple un mediador de aplicación?

⏱️ **30 segundos:** Coordina un caso de uso que necesita varios módulos, conociendo sus APIs sin que estos se conozcan entre sí.

🗣️ **2 minutos:** En lugar de que `orders`, `inventory` y `payments` se llamen en círculo, un coordinador de `CreateOrder` pide la reserva, registra el pago y decide el estado. Rompe ciclos entre pares y concentra el flujo en un sitio. El riesgo es que acumule reglas que pertenecen a los módulos y se vuelva omnisciente.

🔬 **El detalle:** El mediador debe orquestar, no decidir: las reglas de reserva siguen en `inventory`.

### 7. 🟢 ¿Cuándo fusionar módulos puede ser la corrección adecuada?

⏱️ **30 segundos:** Cuando el ciclo revela una única razón de cambio: los dos módulos protegen juntos una invariante o cambian siempre a la vez.

🗣️ **2 minutos:** Si romper el ciclo exige copiar tipos, crear interfaces espejo o eventos que solo existen para devolver la llamada, la frontera probablemente era falsa. Fusionar pierde una separación nominal y recupera cohesión y simplicidad. Lo confirmo con los cambios reales de ambos módulos.

🔬 **El detalle:** Dentro de un monolito, fusionar dos módulos es un refactor barato; conviene no tratarlo como fracaso.

### 8. 🟡 ¿Por qué un resultado de `inventory` no crea necesariamente una dependencia estática inversa?

⏱️ **30 segundos:** Porque devolver un valor no crea un import: `orders` conoce el tipo de resultado de la API de `inventory`, no al revés.

🗣️ **2 minutos:** `orders` llama a `inventory.reserve` y recibe `ReservationResult`, un tipo que vive en la API de `inventory`. El flujo de datos vuelve hacia `orders`, pero la dependencia estática sigue siendo de `orders` hacia `inventory`. Solo aparecería una dependencia inversa si `inventory` importara tipos de `orders`, como la entidad `Order`.

🔬 **El detalle:** Por eso conviene que `inventory` reciba identificadores y líneas, no entidades de otros módulos.

### 9. 🟡 ¿Cómo ayuda el ownership a elegir la dirección de una dependencia?

⏱️ **30 segundos:** La dependencia debe apuntar hacia quien posee la decisión: el que necesita algo depende de quien lo decide.

🗣️ **2 minutos:** `orders` depende de `inventory` porque `inventory` decide la reserva; `inventory` no necesita saber nada de `orders` salvo el identificador. Si `payments` llama a `orders` para cambiar su estado, la dependencia contradice el ownership: el estado del pedido lo decide `orders`, que debería consultar el resultado del pago.

🔬 **El detalle:** Una dirección que contradice el ownership suele producir ciclos y escrituras cruzadas.

### 10. 🟡 ¿Qué diferencia hay entre reducir un contrato y esconder una arista?

⏱️ **30 segundos:** Reducir el contrato quita conocimiento real entre módulos; esconder la arista solo la mueve a un sitio menos visible.

🗣️ **2 minutos:** Sustituir la entidad `Order` por un identificador y unas líneas reduce lo que `inventory` sabe de `orders`: el acoplamiento baja. Poner un bus o una interfaz espejo en medio hace que el grafo estático parezca limpio mientras el conocimiento y la dependencia runtime siguen igual. Lo primero mejora el diseño; lo segundo lo oculta.

🔬 **El detalle:** La prueba es el siguiente cambio: si sigue tocando ambos módulos, la arista solo se escondió.

### 11. 🟡 ¿Cuándo una interfaz logra inversión y cuándo solo renombra el proveedor?

⏱️ **30 segundos:** Logra inversión si la abstracción vive con el consumidor y expresa lo que él necesita; solo renombra si copia todos los métodos del proveedor.

🗣️ **2 minutos:** `inventory` definiendo `OrdersService` con todos los métodos de `orders` es una dependencia disfrazada: cualquier cambio en `orders` exige cambiar la interfaz. Una interfaz pequeña, del tamaño de la necesidad de `inventory`, sí invierte el conocimiento. El dueño de la abstracción decide si la inversión es real.

🔬 **El detalle:** La inyección de dependencias es solo el mecanismo de construcción; no garantiza que la abstracción esté bien puesta.

### 12. 🟡 ¿Qué riesgo tiene un coordinador de aplicación omnisciente?

⏱️ **30 segundos:** Que acumule reglas de los módulos y se convierta en el sitio donde vive todo el negocio.

🗣️ **2 minutos:** Un coordinador que empieza orquestando `CreateOrder` puede ir absorbiendo validaciones de stock, cálculos de pago y políticas de aviso, hasta que los módulos son contenedores de datos y el coordinador es la bola de barro. Hay que vigilar que solo decida el flujo y que cada regla siga en su dueño.

🔬 **El detalle:** Si el coordinador necesita conocer internos de los módulos, es señal de que está decidiendo lo que no le toca.

### 13. 🟡 ¿Cuándo un evento interno es un RPC disfrazado?

⏱️ **30 segundos:** Cuando existe solo para ordenar a un consumidor concreto que haga algo y el productor no puede completar sin su respuesta.

🗣️ **2 minutos:** Si `orders` publica `OrderCreated` y espera a que `inventory` reserve para continuar, eso es un comando con nombre de evento: un RPC con handlers, orden implícito y errores más difíciles de ver. Un evento real anuncia un hecho consumado y tolera que los consumidores reaccionen o no, cuando puedan.

🔬 **El detalle:** La pregunta de control: si nadie escucha el evento, ¿el productor puede terminar? Si no, es un comando.

### 14. 🟡 ¿Qué garantía debes revisar antes de sustituir una llamada por un evento?

⏱️ **30 segundos:** Si el flujo necesita una respuesta inmediata, atomicidad compartida o manejo directo del error.

🗣️ **2 minutos:** La llamada síncrona da resultado y error en el momento y puede compartir transacción. Un evento separa el tiempo: el productor confirma sin saber si el consumidor tuvo éxito. Si la reserva debe decidirse antes de confirmar el pedido, un evento rompe esa garantía. Si el aviso puede llegar después, el evento encaja.

🔬 **El detalle:** También hay que definir qué pasa con el trabajo pendiente o perdido; un evento en memoria se pierde si el proceso cae.

### 15. 🟡 ¿Por qué un grafo acíclico no demuestra autonomía?

⏱️ **30 segundos:** Porque solo cubre el código; el ciclo puede seguir en los datos o en el runtime.

🗣️ **2 minutos:** Dos módulos sin ciclo de imports pueden escribir la misma tabla o llamarse en círculo a través de un bus o de callbacks. La autonomía exige que cambios, datos y ejecución también estén dirigidos. El grafo acíclico es condición útil, no prueba suficiente.

🔬 **El detalle:** Es un error típico dar por modular un sistema porque ArchUnit está en verde.

### 16. 🟡 ¿Qué aporta un baseline de violaciones conocidas?

⏱️ **30 segundos:** Permite introducir una regla en un código con violaciones existentes: se prohíben las nuevas y se reduce la deuda conocida.

🗣️ **2 minutos:** Aplicar la regla a todo de golpe producirá cientos de fallos y el equipo la desactivará. Con un baseline, la regla protege desde el primer día contra nuevas violaciones, y la lista de las existentes se convierte en un inventario de deuda con dueños y fechas. Su tamaño muestra el progreso.

🔬 **El detalle:** Un baseline que no decrece nunca es solo una forma elegante de aceptar la deuda.

### 17. 🟡 ¿Qué detectan ArchUnit y dependency-cruiser y qué dejan fuera?

⏱️ **30 segundos:** Detectan dependencias estáticas prohibidas y ciclos en código o bytecode; dejan fuera datos, SQL y dependencias runtime.

🗣️ **2 minutos:** ArchUnit analiza el bytecode de Java y dependency-cruiser los imports de JavaScript o TypeScript; los dos pueden prohibir que `orders` use internos de `inventory` o detectar ciclos. Ninguno ve un `UPDATE` por SQL, una llamada por reflexión o un import dinámico, ni el orden de ejecución.

🔬 **El detalle:** En TypeScript, la resolución dinámica de módulos puede escapar al análisis estático.

### 18. 🟠 Un ciclo desaparece de imports, pero ambos módulos escriben la misma tabla. ¿Qué harías después?

⏱️ **30 segundos:** Asignar un dueño de la tabla, migrar las escrituras del otro a su API y revocar permisos.

🗣️ **2 minutos:** El ciclo se trasladó del código a los datos: ambos módulos siguen dependiendo del mismo estado. Declaro qué módulo posee la tabla, ofrezco al otro un comando, migro sus escrituras y, cuando termina, revoco sus permisos de escritura. Solo entonces el ciclo desaparece de verdad.

🔬 **El detalle:** Si la tabla mezcla dos conceptos, la solución puede ser separarla en dos, cada una con su dueño.

### 19. 🟠 `payments` llama a `orders` para cambiar su estado. ¿Dónde ubicarías la decisión y por qué?

⏱️ **30 segundos:** En `orders`: el estado del pedido lo decide su dueño, que consulta o recibe el resultado del pago.

🗣️ **2 minutos:** `payments` decide si el cobro está autorizado; `orders` decide qué significa eso para el pedido. Si `payments` cambia el estado del pedido, dos módulos deciden sobre el mismo dato y aparece un ciclo. Lo corrijo haciendo que `payments` devuelva un resultado o publique un hecho, y que `orders` actualice su propio estado.

🔬 **El detalle:** Así, un cambio en las reglas de confirmación del pedido queda dentro de `orders`.

### 20. 🟠 Un evento requiere respuesta inmediata para confirmar checkout. ¿Qué mecanismo elegirías?

⏱️ **30 segundos:** Una llamada síncrona o un comando con resultado: si hace falta respuesta inmediata, un evento es el mecanismo equivocado.

🗣️ **2 minutos:** Un evento que requiere respuesta para confirmar checkout es un RPC disfrazado, con más piezas y peor manejo de errores. Una llamada directa a la API de `inventory`, con resultado cerrado y dentro de la transacción si hace falta, expresa exactamente lo que se necesita. Los eventos se reservan para hechos que pueden procesarse después.

🔬 **El detalle:** Si además se quiere desacoplar el código, se puede invertir la dependencia con una interfaz, sin cambiar la semántica.

### 21. 🟠 Romper un ciclo exige copiar veinte tipos en una interfaz. ¿Qué hipótesis revisarías?

⏱️ **30 segundos:** Que los dos módulos no son unidades distintas o que la responsabilidad está en el lugar equivocado.

🗣️ **2 minutos:** Copiar veinte tipos en una interfaz para romper un ciclo significa que un módulo necesita casi todo el modelo del otro. Eso sugiere fusionarlos o mover la regla que los une a uno de ellos. Antes de añadir la interfaz, reviso los cambios recientes: si siempre tocan ambos, la frontera sobra.

🔬 **El detalle:** Una interfaz tan grande no reduce el acoplamiento; lo documenta.

### 22. 🟠 CI encuentra doscientos ciclos existentes. ¿Cómo introducirías el control sin paralizar al equipo?

⏱️ **30 segundos:** Con un baseline: prohibir ciclos nuevos desde hoy y reducir los existentes por orden de impacto.

🗣️ **2 minutos:** Registro los doscientos ciclos como deuda conocida, activo la regla solo para nuevos ciclos y priorizo los existentes según cuánto cambio y cuántos defectos concentran. Cada reducción baja el baseline. Así el equipo sigue entregando y la regla protege desde el primer día.

🔬 **El detalle:** Conviene medir el tiempo que añade la regla al build y sus falsos positivos para que no se desactive.

### 23. 🟠 Una excepción de dependencia es necesaria durante una migración. ¿Qué metadatos y criterio de retirada exigirías?

⏱️ **30 segundos:** Motivo, módulos afectados, responsable, fecha de retirada y la condición que permitirá eliminarla.

🗣️ **2 minutos:** Una excepción temporal durante una migración es legítima si es estrecha —solo esa dependencia— y observable. Exijo que tenga dueño y fecha, que aparezca en el registro de excepciones y que la regla vuelva a aplicarse al terminar la migración. Si la fecha vence, se revisa, no se renueva sola.

🔬 **El detalle:** Las excepciones que caducan de verdad son lo que distingue una regla de una decoración.

### 24. 🟠 ¿Qué prueba y métrica usarías para demostrar que el refactoring redujo el acoplamiento?

⏱️ **30 segundos:** Una prueba del flujo que confirme el mismo comportamiento y una métrica de cambios que quedan contenidos antes y después.

🗣️ **2 minutos:** Primero, una prueba de caracterización del caso de uso asegura que el refactor no cambió el resultado. Después, comparo los siguientes cambios de esa zona: cuántos módulos tocan y cuántas regresiones producen. Si bajan, el acoplamiento se redujo de verdad, no solo en el grafo.

🔬 **El detalle:** Contar aristas del grafo antes y después es un indicio; los cambios reales son la evidencia.

## 📖 04 — Propiedad de datos en una base compartida

### 1. 🟢 ¿Qué significa que un módulo sea propietario de un dato?

⏱️ **30 segundos:** Que es la única autoridad sobre ese estado: lo escribe, valida sus invariantes, decide su esquema y responde por su calidad.

🗣️ **2 minutos:** Si `inventory` posee las reservas, solo `inventory` las crea y cambia, decide cómo migrar sus columnas y responde si algo sale mal. Los demás módulos pueden leer por vistas publicadas o pedir cambios con comandos. Compartir la base física no cambia eso: la propiedad es lógica.

🔬 **El detalle:** Sin dueño, un cambio de columna exige buscar SQL por todo el repositorio y nadie puede garantizar la invariante.

### 2. 🟢 ¿Qué diferencia hay entre compartir motor y compartir ownership?

⏱️ **30 segundos:** Compartir motor es usar la misma instancia de base; compartir ownership es que varios módulos puedan escribir el mismo estado.

🗣️ **2 minutos:** Varios módulos pueden vivir en la misma base conservando transacciones, joins y operación sencilla, con un escritor por tabla. Lo peligroso no es el motor compartido, sino que nadie sepa quién puede escribir y evolucionar cada dato. Separar el motor sin resolver el ownership copia el problema en dos bases.

🔬 **El detalle:** Por eso la recuperación empieza por la autoridad, no por el almacenamiento.

### 3. 🟢 ¿Qué es una escritura cruzada?

⏱️ **30 segundos:** Que un módulo escribe directamente datos cuyo dueño es otro módulo.

🗣️ **2 minutos:** `orders` actualizando `inventory.reservations` o `payments` cambiando el estado del pedido son escrituras cruzadas: saltan las reglas del dueño y hacen que un cambio de esquema rompa a quien escribe desde fuera. Convierten el esquema en una API accidental sin versión. Se corrigen migrando esas escrituras a comandos del dueño.

🔬 **El detalle:** Son peores que las lecturas cruzadas porque pueden romper invariantes, no solo depender de una forma.

### 4. 🟢 ¿Qué función cumple una vista publicada?

⏱️ **30 segundos:** Ofrecer a otros módulos una lectura con un significado y una forma que el dueño se compromete a mantener.

🗣️ **2 minutos:** Una vista como `inventory.published_availability` expone lo que otros necesitan sin exponer tablas internas. El dueño puede cambiar su almacenamiento mientras la vista conserve su contrato. Es una forma barata y proporcional de compartir lectura dentro de una base común.

🔬 **El detalle:** Una vista con `SELECT *` sobre tablas internas no publica nada: filtra el esquema.

### 5. 🟢 ¿Qué puede hacer un rol de base para reforzar el límite?

⏱️ **30 segundos:** Hacer cumplir el límite: revocar escritura en tablas ajenas y conceder solo lectura sobre vistas publicadas.

🗣️ **2 minutos:** Con roles por módulo, `app_orders` puede leer la disponibilidad publicada pero no escribir reservas. Una escritura cruzada olvidada falla con un error de permisos en lugar de corromper datos en silencio. Convierte la convención en un control, siempre que no se use una credencial global con todos los privilegios.

🔬 **El detalle:** Los permisos no diseñan el ownership; lo aplican una vez decidido.

### 6. 🟢 ¿Qué garantía preserva una clave foránea?

⏱️ **30 segundos:** La integridad referencial entre filas: no puede existir una reserva que apunte a un pedido inexistente.

🗣️ **2 minutos:** Es una garantía barata que la base aplica siempre, aunque otro camino de código se equivoque. Tiene un coste: acopla migraciones y orden de borrado entre los dos dueños. Se conserva si esa garantía compensa y ambos aceptan evolucionar coordinados; no se retira solo para parecer más independiente.

🔬 **El detalle:** En una separación física futura, la clave foránea tendrá que reemplazarse por validación y reconciliación.

### 7. 🟢 ¿Qué diferencia hay entre propiedad de escritura y frontera transaccional?

⏱️ **30 segundos:** La propiedad dice quién decide cada escritura; la frontera transaccional dice qué escrituras se confirman juntas.

🗣️ **2 minutos:** Una transacción puede incluir escrituras de `orders` e `inventory`, cada una hecha a través de la API de su dueño, porque protegen juntas una invariante. Eso no autoriza a `orders` a usar el repositorio de `inventory`. Son preguntas distintas y se responden por separado.

🔬 **El detalle:** Confundirlas lleva a creer que compartir transacción justifica escribir tablas ajenas.

### 8. 🟡 ¿Por qué dos schemas no garantizan autonomía?

⏱️ **30 segundos:** Porque si todos usan la misma credencial con privilegios totales, los esquemas son solo nombres.

🗣️ **2 minutos:** Separar esquemas hace visible el límite, pero un módulo puede seguir escribiendo en el esquema de otro si la conexión lo permite. Además, un ORM puede generar accesos cruzados o el equipo puede conceder excepciones permanentes. La autonomía necesita dueños reales, permisos por rol y control de excepciones.

🔬 **El detalle:** Los esquemas separados son un buen primer paso porque hacen visibles las escrituras cruzadas.

### 9. 🟡 ¿Cuándo una lectura directa mediante vista puede ser proporcional?

⏱️ **30 segundos:** Cuando usa una vista publicada con dueño, es de solo lectura y no filtra tablas internas.

🗣️ **2 minutos:** Para un reporte que cruza pedidos y reservas, un join sobre vistas publicadas es más simple que dos llamadas a APIs y una composición en memoria. Mantiene la semántica del dueño y no transfiere escritura. Convertir cada join en una API por dogma añade latencia y código sin proteger nada.

🔬 **El detalle:** Si el reporte es pesado, conviene medir su impacto sobre las consultas operativas o llevarlo a una réplica.

### 10. 🟡 ¿Cuándo conviene una proyección en vez de una consulta publicada?

⏱️ **30 segundos:** Cuando la lectura es frecuente, especializada o no puede depender de la disponibilidad del dueño, y se acepta cierto retraso.

🗣️ **2 minutos:** Una proyección o read model da al consumidor su propia copia optimizada para sus consultas, alimentada por eventos o por CDC. Compra autonomía de lectura a cambio de retraso y reconciliación. Si el consumidor necesita el dato exacto en el momento, la consulta publicada es mejor.

🔬 **El detalle:** La proyección necesita un contrato que declare frescura y cómo se detecta una divergencia.

### 11. 🟡 ¿Qué coste introduce una clave foránea entre módulos?

⏱️ **30 segundos:** Acopla migraciones y orden de borrado: ningún dueño puede cambiar su clave o eliminar filas sin coordinar con el otro.

🗣️ **2 minutos:** Una clave foránea de reservas a pedidos impide reservas huérfanas, pero obliga a `orders` a coordinar con `inventory` cualquier cambio de su clave primaria o de su política de borrado. Es un precio aceptable si la garantía importa y los equipos lo asumen. Si bloquea evoluciones frecuentes, se reemplaza por validación.

🔬 **El detalle:** Es una de las decisiones que conviene tomar de forma explícita, no heredar del ORM.

### 12. 🟡 ¿Por qué una transacción cruzada no autoriza a usar repositories ajenos?

⏱️ **30 segundos:** Porque la transacción decide qué se confirma junto, no quién tiene derecho a escribir cada dato.

🗣️ **2 minutos:** Aunque pedido y reserva se confirmen en el mismo `COMMIT`, la reserva debe crearla `inventory` a través de su API, aplicando sus reglas. Si `orders` usa el repositorio de `inventory` «porque ya está en la transacción», salta la invariante y queda atado al esquema ajeno.

🔬 **El detalle:** La coordinación transaccional se hace con una conexión compartida entre APIs, no con acceso directo a repositorios.

### 13. 🟡 ¿Cómo evaluarías ORM frente a SQL directo desde el ownership?

⏱️ **30 segundos:** Por si la herramienta puede limitar y hacer auditable quién lee, escribe y migra cada tabla.

🗣️ **2 minutos:** Un ORM ayuda a centralizar repositorios por módulo, pero no impide importar entidades ajenas. El SQL directo es explícito y eficiente, pero permite escribir cualquier tabla por comodidad. La elección no es ORM contra SQL, sino qué controles —permisos, reglas, revisión— acompañan a cada uno.

🔬 **El detalle:** Con cualquiera de los dos, los permisos por rol son el control que no depende de la disciplina.

### 14. 🟡 ¿Qué accesos debes inventariar antes de revocar permisos?

⏱️ **30 segundos:** Todos los caminos que escriben: código de la aplicación, SQL directo, ORM, jobs, triggers, scripts de administración y reparaciones manuales.

🗣️ **2 minutos:** Si se revoca `UPDATE` sin inventario, falla un job nocturno que nadie recordaba y el negocio lo sufre. Uso logs de la base, credenciales, trazas y búsquedas en el código para listar escritores reales. Solo con ese inventario completo se revocan permisos sin romper procesos ocultos.

🔬 **El detalle:** Revocar de forma gradual, primero en un entorno o con alertas, reduce el riesgo de lo que se escape al inventario.

### 15. 🟡 ¿Por qué una credencial global debilita el control por schemas?

⏱️ **30 segundos:** Porque permite a cualquier módulo escribir en cualquier esquema, así que la separación queda como convención.

🗣️ **2 minutos:** Con una credencial global, un error o un atajo puede escribir tablas ajenas sin que nada lo detecte. El control por esquemas solo funciona si cada módulo usa un rol con los permisos de su propio esquema y lectura sobre las vistas publicadas de otros. Si no, los esquemas son nombres.

🔬 **El detalle:** Separar credenciales por módulo también mejora la auditoría: el log dice qué módulo hizo cada escritura.

### 16. 🟡 ¿Qué debería contener una concesión temporal de escritura?

⏱️ **30 segundos:** Motivo, tabla y operación concretas, módulo concedido, dueño que lo aprueba, controles de invariantes y fecha de retirada.

🗣️ **2 minutos:** Una concesión temporal de escritura es arriesgada porque salta las reglas del dueño. Debe ser estrecha —una tabla, una operación—, estar registrada, vigilada y tener un plan para devolver la autoridad. Al vencer, se revisa si sigue haciendo falta; no se renueva sola.

🔬 **El detalle:** Si una concesión se renueva varias veces, lo correcto es convertirla en un comando del dueño.

### 17. 🟡 ¿Cómo mantienes reporting sin entregar ownership al módulo de reportes?

⏱️ **30 segundos:** Con vistas de solo lectura, una réplica o un read model, sin dar al módulo de reportes permisos de escritura.

🗣️ **2 minutos:** Los reportes necesitan leer mucho de varios módulos; no necesitan escribir sus tablas. Publico vistas con los datos necesarios o alimento un modelo de reporting en una réplica, con la frescura acordada. Así los reportes no se convierten en un escritor más ni cargan las consultas operativas.

🔬 **El detalle:** Los datos derivados que genere el reporte viven en sus propias tablas, de las que sí es dueño.

### 18. 🟠 `orders` actualiza stock para ahorrar una llamada local. ¿Qué migración propones?

⏱️ **30 segundos:** Declarar a `inventory` dueño del stock, ofrecer un comando de reserva y migrar `orders` a él antes de revocar su escritura.

🗣️ **2 minutos:** La llamada local que `orders` ahorra no compensa saltarse la invariante. Añado a `inventory` la operación que `orders` necesita, cambio `orders` para usarla con una prueba que confirme el mismo comportamiento, observo un tiempo y después revoco el permiso de escritura de `orders` sobre el stock.

🔬 **El detalle:** La llamada local dentro de la misma transacción cuesta prácticamente lo mismo que el `UPDATE` directo.

### 19. 🟠 Un trigger modifica tablas de dos módulos. ¿Cómo decides conservarlo o retirarlo?

⏱️ **30 segundos:** Según si protege una invariante que los dos módulos necesitan y si alguien es su dueño; si esconde reglas de negocio, lo muevo a código del dueño.

🗣️ **2 minutos:** Un trigger que modifica tablas de dos módulos es un escritor invisible: no aparece en el código y nadie lo recuerda al cambiar el esquema. Si implementa una regla de negocio, la muevo a la API del módulo dueño con una prueba que falle sin ella. Si es una garantía técnica simple y documentada, puede quedarse con un dueño claro.

🔬 **El detalle:** Retirarlo sin reemplazo rompe la regla en silencio; primero se escribe la prueba que la hace visible.

### 20. 🟠 Un join crítico usa tablas internas de tres módulos. ¿Qué alternativas compararías?

⏱️ **30 segundos:** Vistas publicadas por cada dueño, un read model para ese join o consultas separadas compuestas en memoria.

🗣️ **2 minutos:** Un join crítico sobre tablas internas acopla la consulta al esquema de tres módulos. Si la consulta es operativa y frecuente, un read model o vistas publicadas mantienen el rendimiento con contratos estables. Si es ocasional, componer desde APIs puede bastar. Elijo según frecuencia, volumen y frescura necesaria.

🔬 **El detalle:** Lo que no hago es dejar el join sobre internos sin dueño: cualquier cambio de esquema lo romperá.

### 21. 🟠 Al revocar `UPDATE`, falla un job nocturno desconocido. ¿Cómo recuperas sin abandonar el límite?

⏱️ **30 segundos:** Restauro el permiso solo para ese job con una excepción temporal, y migro su escritura a un comando del dueño.

🗣️ **2 minutos:** El job desconocido es exactamente el caso que el inventario debía encontrar. Recupero el servicio con una concesión estrecha, registrada y con fecha; averiguo qué escribe y por qué; y lo migro a la API del dueño. Después revoco de nuevo. El límite se mantiene y el negocio no espera.

🔬 **El detalle:** El incidente también dice que el inventario tenía huecos; conviene revisar qué otras fuentes faltaron.

### 22. 🟠 Una migración requiere dual write durante dos semanas. ¿Cómo defines autoridad y reconciliación?

⏱️ **30 segundos:** Una autoridad canónica durante las dos semanas, sincronización reconciliable hacia la otra ruta y detección de divergencias.

🗣️ **2 minutos:** En el dual write, un solo escritor es la fuente de verdad; la otra copia se alimenta de ella y se compara periódicamente. Defino qué pasa si divergen —se corrige desde la canónica— y la salida: fecha y condición para retirar la escritura doble. Sin autoridad definida, no hay forma de saber cuál es la verdad.

🔬 **El detalle:** Dos escrituras independientes sin estrategia no son una migración: son dos fuentes de verdad que divergirán.

### 23. 🟠 Una foreign key bloquea la evolución de `orders`. ¿Qué garantía perderías al retirarla?

⏱️ **30 segundos:** La integridad referencial: podrían existir reservas o pagos que apunten a pedidos que ya no existen.

🗣️ **2 minutos:** Retirar la clave foránea da libertad a `orders` para cambiar su clave o su borrado sin coordinar, pero traslada la garantía al código: validaciones al crear y una reconciliación periódica que detecte huérfanos. Evalúo si esa evolución merece el coste de la nueva validación y qué pasa si falla.

🔬 **El detalle:** A veces el bloqueo se resuelve cambiando la forma de la clave, no eliminando la restricción.

### 24. 🟠 ¿Qué evidencia demostraría que hay ownership real aunque la base siga compartida?

⏱️ **30 segundos:** Un escritor por tabla con permisos que lo hacen cumplir, cambios de esquema decididos por su dueño y cambios de negocio que quedan contenidos.

🗣️ **2 minutos:** Aunque la base sea común, si los permisos impiden escrituras cruzadas, cada migración la decide un solo equipo y los cambios de una capacidad no obligan a tocar otras, el ownership es real. Lo compruebo con logs de escritura por rol, con el historial de migraciones y con cambios recientes.

🔬 **El detalle:** Una base compartida con esas propiedades puede ser el estado final; no es una etapa pendiente de completar.

## 📖 05 — Comunicación interna: llamadas, comandos y eventos

### 1. 🟢 ¿Cuándo es adecuada una llamada directa entre módulos?

⏱️ **30 segundos:** Cuando un módulo necesita una capacidad estable de otro y la respuesta en el momento, dentro del mismo proceso.

🗣️ **2 minutos:** `orders` llamando a `InventoryApi.reserve` conserva resultado, error y transacción directos, con la latencia de una función. Es la opción base: simple de leer, de depurar y de probar. Se añade indirección solo cuando cambia de verdad el conocimiento entre módulos o el tiempo del flujo.

🔬 **El detalle:** Una llamada directa no impide extraer más tarde: lo que pesa en una extracción es la frontera de datos y el contrato.

### 2. 🟢 ¿Qué diferencia hay entre un comando y un evento?

⏱️ **30 segundos:** Un comando expresa una intención dirigida a un responsable y puede devolver resultado; un evento anuncia un hecho ya ocurrido a cero o más consumidores.

🗣️ **2 minutos:** `ReserveInventory` pide algo a `inventory` y espera saber si se hizo. `OrderCreated` dice que algo pasó; sus consumidores no pueden cambiar el pasado del productor ni el productor depende de ellos para terminar. Si un «evento» necesita exactamente un handler y una respuesta, es un comando con otro nombre.

🔬 **El detalle:** El nombre en pasado no convierte un comando en evento; lo hace la semántica.

### 3. 🟢 ¿Qué ventaja ofrece una interfaz entre módulos?

⏱️ **30 segundos:** Invierte el conocimiento de código: el consumidor depende de un contrato, no de la implementación concreta.

🗣️ **2 minutos:** Con una interfaz, `orders` conoce `InventoryApi` y la raíz de composición decide qué implementación usar; en pruebas se puede sustituir por un doble. Conserva la llamada directa y su semántica. Cuesta una abstracción y el cableado, que solo compensan si delimitan conocimiento o permiten una sustitución concreta.

🔬 **El detalle:** Una interfaz por clase, sin esa necesidad, añade archivos sin aislar nada.

### 4. 🟢 ¿Qué función cumple un mediador de comandos?

⏱️ **30 segundos:** Separa a quien emite un comando de quien lo ejecuta: el emisor no conoce al handler concreto.

🗣️ **2 minutos:** Un mediador recibe `ReserveInventory` y lo entrega al handler registrado, que devuelve el resultado. Permite añadir comportamiento transversal —logging, validación— y desacoplar el registro de handlers. El precio es indirección: seguir el flujo exige saber qué handler está registrado para cada comando.

🔬 **El detalle:** Si cada comando tiene un único handler conocido y no hay comportamiento transversal, la llamada directa es más clara.

### 5. 🟢 ¿Qué significa fan-out?

⏱️ **30 segundos:** Que un mismo hecho llega a varios consumidores independientes.

🗣️ **2 minutos:** `OrderCreated` puede interesar a `notifications`, a analítica y a un sistema de fidelización. Con un evento, el productor no necesita conocer a ninguno ni cambiar cuando aparece uno nuevo. Es la ventaja principal de los eventos, y trae consigo preguntas de orden, entrega y errores por cada consumidor.

🔬 **El detalle:** Si solo hay un consumidor y siempre lo habrá, el fan-out no aporta y el evento puede ser una indirección innecesaria.

### 6. 🟢 ¿Una `Promise` de TypeScript implica una llamada remota?

⏱️ **30 segundos:** No: modela una espera, no una llamada remota ni ejecución paralela.

🗣️ **2 minutos:** `reserve(command): Promise<Reservation>` puede resolverse dentro del mismo proceso, leyendo la base en la misma unidad de trabajo. El llamador espera y debe manejar rechazo o cancelación. La frontera transaccional sigue definiéndose en la composición, no en el tipo de retorno.

🔬 **El detalle:** Confundir `async` con distribuido lleva a añadir reintentos y timeouts donde no hay red.

### 7. 🟢 ¿Un bus en memoria garantiza entrega tras una caída?

⏱️ **30 segundos:** No: vive en la memoria del proceso y los eventos no despachados se pierden si cae.

🗣️ **2 minutos:** Un bus en memoria entrega mientras el proceso vive. Si cae entre el commit y el despacho, o durante el procesamiento, el trabajo desaparece sin rastro. Para efectos que no pueden perderse, el trabajo se persiste en la misma transacción que el cambio de negocio y un worker lo procesa.

🔬 **El detalle:** En Node, un evento `error` sin listener puede incluso terminar el proceso.

### 8. 🟡 ¿Por qué `InventoryReservationRequested` puede ser un comando disfrazado?

⏱️ **30 segundos:** Porque pide algo a un único responsable y el flujo no puede continuar sin su respuesta.

🗣️ **2 minutos:** Un nombre como `InventoryReservationRequested` suena a hecho, pero si requiere exactamente un handler que reserve y devuelva el resultado para continuar, es una orden. Tratarla como evento añade handlers, orden implícito y errores más difíciles de manejar. Lo honesto es un comando `ReserveInventory` con resultado.

🔬 **El detalle:** La prueba es sencilla: si nadie lo consumiera, ¿el productor podría completar? Si no, es un comando.

### 9. 🟡 ¿Qué garantía conserva una llamada síncrona con resultado?

⏱️ **30 segundos:** Resultado y error inmediatos, orden explícito y la posibilidad de compartir transacción.

🗣️ **2 minutos:** `orders` sabe en el momento si hay stock y decide confirmar o rechazar dentro de la misma transacción. No hay estados intermedios ni reintentos que gestionar. Es la garantía que se pierde al cambiar a un evento, y por eso la llamada es lo adecuado cuando la respuesta cambia la decisión.

🔬 **El detalle:** El coste es el acoplamiento temporal: si el módulo llamado falla, el llamador también.

### 10. 🟡 ¿Cuándo un evento reduce conocimiento del productor?

⏱️ **30 segundos:** Cuando publica un hecho estable y los consumidores pueden reaccionar sin que el productor necesite saber quiénes son ni qué hacen.

🗣️ **2 minutos:** `orders` publica `OrderCreated` y no sabe si lo usa `notifications`, analítica o nadie; añadir un consumidor no cambia a `orders`. El conocimiento se reduce en esa dirección. Si el productor necesita el resultado del consumidor, el evento no reduce nada: solo esconde una dependencia.

🔬 **El detalle:** Los consumidores sí conocen al productor: dependen de la forma y el significado del evento.

### 11. 🟡 ¿Qué cambia al despachar eventos antes o después del commit?

⏱️ **30 segundos:** Antes del commit, un fallo del handler puede abortar la operación; después en memoria, la operación ya confirmó y un fallo o una caída pierden el efecto.

🗣️ **2 minutos:** Despachar antes acopla transaccionalmente al consumidor: si `notifications` falla, el pedido no se crea. Despachar después en memoria desacopla, pero si el proceso cae entre el commit y el despacho, el aviso se pierde. Persistir el evento con el estado permite reintentar, a costa de un worker y deduplicación.

🔬 **El detalle:** También hay un riesgo en el orden: publicar antes del commit y hacer rollback deja consumidores reaccionando a algo que no existe.

### 12. 🟡 ¿Por qué un handler síncrono no crea consistencia eventual?

⏱️ **30 segundos:** Porque se ejecuta en la misma pila, antes de que el productor termine: no hay retraso ni convergencia posterior.

🗣️ **2 minutos:** Llamar «eventual» a un handler síncrono confunde: su efecto ocurre en el mismo instante y su fallo puede afectar al productor. La consistencia eventual aparece cuando el efecto se procesa después, de forma independiente, y el sistema converge con el tiempo. La semántica la decide cuándo y cómo se despacha, no el nombre.

🔬 **El detalle:** Un bus que ejecuta handlers síncronamente tiene la semántica de una llamada con más indirección.

### 13. 🟡 ¿Qué problema crea depender del orden de registro de handlers?

⏱️ **30 segundos:** Un contrato oculto: el comportamiento depende del orden de registro, que nadie documentó y cualquiera puede cambiar.

🗣️ **2 minutos:** Si `notifications` debe ejecutarse después de `payments` y funciona solo porque se registró después, un refactor que cambie el orden rompe el flujo sin avisar. Si el orden importa, no es fan-out: es una secuencia de comandos o falta un hecho posterior al que reaccionar.

🔬 **El detalle:** Los buses rara vez garantizan orden entre handlers; depender de él es depender de un detalle de implementación.

### 14. 🟡 ¿Qué deben propagar `AsyncLocalStorage` y `contextvars` y qué no deberían ocultar?

⏱️ **30 segundos:** Deben propagar contexto técnico —correlación, actor, transacción—; no deberían ocultar parámetros de negocio ni crear estado global mutable.

🗣️ **2 minutos:** `AsyncLocalStorage` en Node y `contextvars` en Python mantienen el contexto a través de callbacks, promesas o tareas `asyncio`, útil para logs y trazas. Si se usan para pasar el `orderId` o una regla de negocio de forma implícita, las funciones pierden su contrato explícito y se vuelven difíciles de probar.

🔬 **El detalle:** Lo que afecta a la decisión va en los parámetros; lo que sirve para observar puede ir en el contexto.

### 15. 🟡 ¿Qué diferencia hay entre asincronía y durabilidad?

⏱️ **30 segundos:** La asincronía decide cuándo se ejecuta el trabajo; la durabilidad decide si sobrevive a una caída.

🗣️ **2 minutos:** Una tarea en un executor, una promesa o una `asyncio.Queue` son asíncronas pero viven en memoria: si el proceso cae, se pierden. La durabilidad exige guardar el trabajo en un almacenamiento que comparta commit con el cambio de negocio. Se pueden combinar: una tabla de trabajo procesada por un worker asíncrono.

🔬 **El detalle:** Llamar «confiable» a un mecanismo asíncrono sin durabilidad es uno de los errores más comunes.

### 16. 🟡 ¿Qué debes definir antes de permitir reintentos de un handler?

⏱️ **30 segundos:** Que el efecto sea idempotente o se deduplique por una identidad estable, y cuántas veces y con qué espera se reintenta.

🗣️ **2 minutos:** Un reintento repite el handler; si su efecto no es idempotente, se duplica, por ejemplo un correo enviado dos veces. Defino una clave del efecto, un límite de intentos con espera creciente y qué pasa con el trabajo que falla siempre. Sin eso, los reintentos convierten un fallo transitorio en efectos duplicados.

🔬 **El detalle:** También hay que definir qué se reintenta: un error de negocio no se arregla repitiendo.

### 17. 🟡 ¿Por qué una llamada local no bloquea por sí sola una extracción futura?

⏱️ **30 segundos:** Porque lo que decide una extracción es la frontera de datos y el contrato, no el mecanismo de llamada.

🗣️ **2 minutos:** Si `orders` llama a una API bien definida de `inventory` y `inventory` posee sus datos, cambiar esa llamada por una remota es acotado. Lo que bloquea extracciones son escrituras cruzadas, modelos compartidos y transacciones que cruzan módulos sin necesidad. Una llamada local limpia es buena preparación.

🔬 **El detalle:** Simular hoy la red entre módulos para «estar listos» paga el coste antes de saber si hará falta.

### 18. 🟠 `notifications` falla después de confirmar el pedido. ¿Qué semánticas compararías?

⏱️ **30 segundos:** Abortar el pedido si falla el aviso, confirmar y arriesgar perder el aviso, o confirmar y persistir el aviso como trabajo durable.

🗣️ **2 minutos:** Si el aviso se despacha antes del commit y falla, el pedido no se crea por un problema de correo, lo que es desproporcionado. Si se despacha después en memoria, una caída lo pierde. Lo proporcional es persistir el trabajo con el pedido y que un worker lo entregue con reintentos y deduplicación. El pedido confirmado no depende del correo.

🔬 **El detalle:** El cliente puede ver el pedido confirmado aunque el aviso aún esté pendiente; conviene que la interfaz no dependa del correo.

### 19. 🟠 Dos handlers deben ejecutarse en orden estricto. ¿Mantendrías un evento genérico?

⏱️ **30 segundos:** No: si el orden importa, hay una secuencia que debe ser explícita, con comandos o con un hecho posterior.

🗣️ **2 minutos:** Un evento genérico con dos handlers que dependen del orden esconde un flujo. Lo hago explícito: un coordinador ejecuta los dos pasos en orden, o el segundo reacciona a un hecho que emite el primero al terminar. Así el orden está en el diseño y no en el registro de handlers.

🔬 **El detalle:** Si el segundo paso necesita el resultado del primero, es claramente una secuencia de comandos.

### 20. 🟠 Un listener async de Node rechaza su promesa. ¿Qué debe hacer el diseño?

⏱️ **30 segundos:** Definir qué pasa con ese rechazo: registrarlo, decidir si aborta, reintenta o deja el trabajo pendiente, y nunca dejarlo sin manejar.

🗣️ **2 minutos:** En Node, un listener `async` que rechaza puede producir un rechazo no manejado que nadie observa o que termina el proceso, según la configuración. El diseño debe capturar el error, registrarlo con contexto y aplicar una política. Si el efecto importa, el trabajo debería estar persistido para reintentarlo.

🔬 **El detalle:** `EventEmitter` no espera las promesas de sus listeners; el productor no se entera del fallo si no se diseña para ello.

### 21. 🟠 Una cola `asyncio` acumula trabajo y el proceso se reinicia. ¿Qué garantía faltaba?

⏱️ **30 segundos:** La durabilidad: el trabajo vivía solo en memoria y el reinicio lo borró.

🗣️ **2 minutos:** Una `asyncio.Queue` distribuye trabajo entre tareas del mismo proceso, pero no lo guarda. Todo lo acumulado se pierde al reiniciar. Si ese trabajo era obligatorio, debía escribirse en una tabla en la misma transacción que el cambio de negocio y procesarse desde ahí.

🔬 **El detalle:** Además, una cola en memoria sin límite puede agotar la memoria del proceso en un pico, que es otra forma de perder el trabajo.

### 22. 🟠 El bus interno tiene exactamente un consumidor y devuelve una respuesta. ¿Qué simplificación evaluarías?

⏱️ **30 segundos:** Sustituir el bus por una llamada directa o un comando explícito con resultado.

🗣️ **2 minutos:** Un bus con un único consumidor que devuelve una respuesta tiene la semántica de una llamada, con más indirección y peor trazabilidad. Reemplazarlo por una llamada a la API del módulo simplifica el código, hace visible la dependencia y mantiene el mismo comportamiento. El bus tiene sentido cuando hay fan-out real.

🔬 **El detalle:** La retirada se hace con una prueba de caracterización del flujo para confirmar que nada cambia.

### 23. 🟠 ¿Cómo migrarías de un evento en memoria a procesamiento durable sin duplicar efectos?

⏱️ **30 segundos:** Escribiendo el trabajo en una tabla durable con una clave de efecto y migrando consumidor por consumidor, con deduplicación durante la convivencia.

🗣️ **2 minutos:** Primero el productor escribe el trabajo en la misma transacción que el cambio de negocio, además de seguir despachando en memoria. Un worker procesa la tabla con la misma clave que usa el handler viejo, de modo que un efecto no se aplica dos veces. Comparo resultados y, cuando el worker está verificado, retiro el handler en memoria.

🔬 **El detalle:** La métrica de pendientes y su edad dice si el worker va al día antes de retirar el camino viejo.

### 24. 🟠 ¿Qué criterio usarías para retirar un mediador que solo añade indirección?

⏱️ **30 segundos:** Que no aporte fan-out, comportamiento transversal ni desacoplamiento real, y que la llamada directa sea más clara con el mismo resultado.

🗣️ **2 minutos:** Reviso qué hace el mediador por cada comando: si solo reenvía a un handler único sin validación ni registro común, es indirección pura. Lo retiro de forma gradual, reemplazando cada comando por una llamada directa con su prueba. Si aparece la necesidad más adelante, reintroducirlo es barato dentro del proceso.

🔬 **El detalle:** El coste de la indirección se paga en cada lectura del código; por eso se retira aunque funcione.

## 📖 06 — Código compartido, *shared kernel* y controles arquitectónicos

### 1. 🟢 ¿Qué es un *shared kernel*?

⏱️ **30 segundos:** Un subconjunto explícito del modelo que varios contextos acuerdan compartir y evolucionar juntos.

🗣️ **2 minutos:** Por ejemplo, un `Money` con su moneda y redondeo compartido por `orders` y `payments`: los equipos coordinan sus cambios y prueban contra ambos consumidores. Es pequeño a propósito: cuanto más crece, menos independientes son quienes lo usan. No es el nombre elegante de `common`.

🔬 **El detalle:** Lo definió Eric Evans en Domain-Driven Design como una relación deliberada entre contextos, con coste asumido.

### 2. 🟢 ¿Qué diferencia hay entre *shared kernel* y utilidad técnica?

⏱️ **30 segundos:** El shared kernel comparte modelo de negocio con dueños conjuntos; una utilidad técnica comparte mecanismo sin reglas de negocio.

🗣️ **2 minutos:** Un reloj, un generador de identificadores o un tipo de resultado genérico son utilidades: estables y ajenas al dominio. `Money` con sus reglas de redondeo es modelo compartido y exige coordinar cada cambio entre los equipos que lo usan. Distinguirlos decide qué gobierno necesita cada pieza.

🔬 **El detalle:** Una utilidad que empieza a contener reglas de negocio deja de serlo y debería moverse a su dueño.

### 3. 🟢 ¿Qué problema suele crear un módulo `common` sin ownership?

⏱️ **30 segundos:** Una dependencia central con muchas razones de cambio que nadie puede modificar sin revisar a todos sus consumidores.

🗣️ **2 minutos:** `common` empieza con `Money` y `Clock` y acaba conteniendo `Order`, validadores, helpers de ORM y reglas de promociones. Cada cambio afecta a los cuatro módulos y ningún equipo puede decidirlo solo. Se eliminó duplicación textual a cambio de coordinación permanente.

🔬 **El detalle:** El síntoma típico es que una actualización de `common` obliga a cambiar y desplegar todo a la vez.

### 4. 🟢 ¿Qué significa duplicación consciente?

⏱️ **30 segundos:** Aceptar deliberadamente dos representaciones de algo parecido para que cada módulo evolucione solo, vigilando la divergencia.

🗣️ **2 minutos:** `notifications` puede tener su propio DTO de dirección con nombre y email sin importar el agregado `Customer`. Si `Customer` cambia, `notifications` no se entera. Es una decisión consciente, con un coste de mapeo y una revisión de que la divergencia no tenga consecuencias de negocio.

🔬 **El detalle:** La diferencia con la duplicación accidental es que alguien la decidió y sabe por qué.

### 5. 🟢 ¿Qué debe declarar todo código compartido?

⏱️ **30 segundos:** Consumidores permitidos, propósito, dueños con autoridad, política de compatibilidad, pruebas contra consumidores, criterio para dividir o duplicar y fecha de revisión si nació como excepción.

🗣️ **2 minutos:** Con esos datos, lo compartido deja de ser un cajón y pasa a ser una decisión gobernada: se sabe quién puede cambiarlo, cómo se prueban los efectos y cuándo conviene dejar de compartirlo. Sin ellos, crece por comodidad hasta convertirse en `common`.

🔬 **El detalle:** El criterio para dejar de compartir es tan importante como el de empezar.

### 6. 🟢 ¿Qué es un baseline de violaciones?

⏱️ **30 segundos:** La lista de violaciones conocidas de una regla, registrada para prohibir las nuevas mientras se reduce la deuda existente.

🗣️ **2 minutos:** Permite introducir una regla arquitectónica en un código que ya la incumple sin bloquear el trabajo. Las violaciones del baseline no rompen el build; las nuevas sí. Cada una lleva dueño y se va eliminando, y el tamaño del baseline mide el progreso.

🔬 **El detalle:** Un baseline que no decrece es una forma elegante de aceptar la deuda para siempre.

### 7. 🟢 ¿Qué debe incluir una excepción arquitectónica temporal?

⏱️ **30 segundos:** Motivo, alcance estrecho, dueño, fecha de caducidad y forma de observarla.

🗣️ **2 minutos:** Por ejemplo: `reports ─► inventory/internal/sql` hasta una fecha, con dueño Data. La excepción debe ser lo más estrecha posible, aparecer en un registro y caducar: al vencer se revisa si sigue haciendo falta. Un comodín permanente convierte la regla en decoración.

🔬 **El detalle:** Las excepciones se revisan igual que la deuda técnica: con prioridad y responsable.

### 8. 🟡 ¿Por qué DRY no obliga a compartir dos tipos parecidos?

⏱️ **30 segundos:** Porque DRY evita repetir conocimiento, no código que solo se parece.

🗣️ **2 minutos:** Dos tipos con los mismos campos pueden representar conceptos distintos que cambiarán por razones distintas. Unificarlos crea un dueño común y obliga a coordinar cambios que no tenían por qué coordinarse. Si el conocimiento es realmente el mismo y su divergencia rompería algo, entonces sí se comparte.

🔬 **El detalle:** La pregunta útil es si cambiar uno debería obligar a cambiar el otro.

### 9. 🟡 ¿Cuándo `Money` puede pertenecer a un *shared kernel*?

⏱️ **30 segundos:** Cuando su significado —moneda, precisión, redondeo— debe ser idéntico entre módulos y una divergencia produciría cobros incorrectos.

🗣️ **2 minutos:** Si `orders` calcula el total con un redondeo y `payments` cobra con otro, aparecen diferencias de céntimos que se convierten en incidencias contables. Un `Money` compartido, pequeño y estable, evita esa divergencia. Se gobierna como shared kernel: cambios coordinados y pruebas contra ambos consumidores.

🔬 **El detalle:** Si solo se comparte la representación y cada módulo aplica reglas distintas, no hace falta compartirlo.

### 10. 🟡 ¿Cuándo un DTO local es preferible a importar un modelo canónico?

⏱️ **30 segundos:** Cuando el consumidor usa solo parte de los datos, con sus propias reglas, y un modelo canónico lo ataría a cambios que no le importan.

🗣️ **2 minutos:** Un DTO local de `notifications` con los tres campos que necesita es más barato que depender de un `Order` canónico con pago, inventario y avisos. El mapeo cuesta unas líneas; la dependencia del canónico cuesta coordinación en cada cambio del modelo. El DTO local compra autonomía.

🔬 **El detalle:** El canónico tiende a crecer con los campos que cada consumidor pide, y cada campo es un compromiso con todos.

### 11. 🟡 ¿Cómo afecta el tamaño del *shared kernel* a la autonomía?

⏱️ **30 segundos:** Cuanto más grande, menos autonomía: cada cambio en él obliga a coordinar a todos sus consumidores.

🗣️ **2 minutos:** Un shared kernel pequeño y estable cambia poco y su coordinación es barata. Si crece con reglas de negocio, cada cambio de una de ellas arrastra a todos los módulos que lo usan, aunque no les afecte. La autonomía de los consumidores es inversamente proporcional al tamaño y la volatilidad de lo compartido.

🔬 **El detalle:** Por eso se revisa periódicamente qué contiene y se saca lo que ya no es común.

### 12. 🟡 ¿Por qué versionar una librería no elimina el acoplamiento?

⏱️ **30 segundos:** Porque el acoplamiento sigue: versionar solo hace explícito cuándo y cómo se coordina.

🗣️ **2 minutos:** Con una librería versionada, los consumidores pueden quedarse en una versión vieja un tiempo, pero tarde o temprano deben actualizar, y mientras tanto coexisten versiones con reglas distintas. Hace visible la compatibilidad y permite planificarla, pero no elimina la dependencia de un modelo común.

🔬 **El detalle:** Varias versiones en uso a la vez también son un coste de mantenimiento para el dueño de la librería.

### 13. 🟡 ¿Cuándo no necesitas versionado semántico interno?

⏱️ **30 segundos:** Cuando todos los consumidores están en el mismo artefacto y se pueden cambiar en un solo commit.

🗣️ **2 minutos:** Dentro de un monolito, un cambio en el código compartido se aplica y se migra a todos los consumidores a la vez, con las pruebas del conjunto. Versionarlo añadiría la complejidad de mantener versiones sin comprar compatibilidad real. El versionado aparece cuando consumen la librería artefactos que se despliegan por separado.

🔬 **El detalle:** Aun sin versiones, conviene que el cambio sea revisable: un commit que toca cien consumidores es difícil de revisar.

### 14. 🟡 ¿Qué ventaja tiene empezar el control con violaciones nuevas?

⏱️ **30 segundos:** Que protege el límite desde hoy sin exigir resolver antes toda la deuda existente.

🗣️ **2 minutos:** Aplicar la regla solo a violaciones nuevas evita que el equipo la desactive por el ruido de las existentes. Con un baseline, las viejas se reducen con un plan y las nuevas no pueden entrar. Es la forma práctica de introducir controles en un legado.

🔬 **El detalle:** La combinación de baseline y excepciones con caducidad es lo que hace sostenible un control en el tiempo.

### 15. 🟡 ¿Qué evidencia complementa una prueba arquitectónica?

⏱️ **30 segundos:** Pruebas de módulo, permisos de datos y métricas de cambios contenidos.

🗣️ **2 minutos:** Una prueba arquitectónica demuestra que el grafo de dependencias cumple una regla. No ve escrituras cruzadas por SQL, eventos incompatibles ni equipos que coordinan cada cambio. Los permisos por rol cubren los datos, las pruebas de módulo el comportamiento y el historial de cambios la contención real.

🔬 **El detalle:** Un build verde con cambios que siguen tocando cinco módulos es la señal de que falta alguna de esas evidencias.

### 16. 🟡 ¿Qué diferencias de enforcement existen entre Java, TypeScript, Go y Python?

⏱️ **30 segundos:** Java y TypeScript necesitan herramientas de análisis además del lenguaje; Go hace cumplir `internal/` y prohíbe ciclos en el compilador; Python depende de convenciones y de contratos de importación.

🗣️ **2 minutos:** En Java, ArchUnit o JPMS completan una visibilidad que no protege subpaquetes. En TypeScript, `export` no distingue vecinos de ajenos y hace falta dependency-cruiser, *project references* o `exports` del paquete. En Go, el compilador ya rechaza ciclos e imports de `internal/`. En Python, import-linter es el control, porque el guion bajo es solo convención.

🔬 **El detalle:** En las cuatro, los imports dinámicos o la reflexión pueden escapar al control estático.

### 17. 🟡 ¿Cómo distingues una regla molesta de una regla equivocada?

⏱️ **30 segundos:** Si molesta porque protege un límite real que alguien quiere saltarse, o porque el límite está mal puesto o la herramienta mal configurada.

🗣️ **2 minutos:** Cuando una regla falla repetidamente, reviso los casos: si son atajos por prisa, la regla hace su trabajo; si todos apuntan a que dos módulos necesitan colaborar de una forma que la regla prohíbe, quizá la frontera está mal; si son falsos positivos, se ajusta la configuración. La conversación es parte del control.

🔬 **El detalle:** Desactivar la regla a ciegas pierde la información que el fallo estaba dando.

### 18. 🟠 Cuatro módulos importan un `Order` canónico y solo usan campos distintos. ¿Qué rediseño evaluarías?

⏱️ **30 segundos:** Sustituir el `Order` canónico por modelos locales en cada consumidor con solo los campos que usa, alimentados por la API o por eventos del dueño.

🗣️ **2 minutos:** Si cada uno usa campos distintos, el canónico los obliga a coordinar cambios que no les afectan. Doy a cada consumidor un modelo propio y mantengo el contrato con `orders` pequeño. Migro un consumidor a la vez y retiro el canónico cuando ya nadie lo usa. Si queda un núcleo realmente común, puede ser un shared kernel pequeño.

🔬 **El detalle:** El criterio de éxito es que un cambio en `orders` deje de obligar a tocar los otros tres.

### 19. 🟠 Dos equipos necesitan cambiar `Money` con calendarios incompatibles. ¿Qué alternativas compararías?

⏱️ **30 segundos:** Duplicar `Money` con traducción en el borde, dividirlo en una parte común mínima, o gobernarlo con versiones y fechas acordadas.

🗣️ **2 minutos:** Si los calendarios son incompatibles, el shared kernel está impidiendo que cada equipo avance. Evalúo qué parte de `Money` es realmente común —representación y redondeo— y cuál es regla propia de cada uno. Lo común se queda compartido y estable; lo específico se mueve a cada módulo.

🔬 **El detalle:** Si la divergencia en el redondeo tiene consecuencias contables, esa parte debe seguir siendo una sola, aunque cueste coordinar.

### 20. 🟠 CI bloquea una dependencia necesaria para una migración. ¿Cómo autorizas la excepción sin normalizarla?

⏱️ **30 segundos:** Con una excepción estrecha, registrada, con dueño y fecha, que la regla vuelva a aplicar al terminar la migración.

🗣️ **2 minutos:** La migración necesita la dependencia temporalmente; la regla no se desactiva. Añado una excepción solo para ese par de módulos y esa dependencia, visible en el registro, con la fecha de fin de la migración. Al vencer, se elimina y el build vuelve a prohibirla. Así se autoriza sin normalizar.

🔬 **El detalle:** Si la excepción se renueva varias veces, la migración no está avanzando y conviene revisarla.

### 21. 🟠 Un paquete de logging empieza a contener reglas de auditoría de negocio. ¿Dónde ubicarías cada responsabilidad?

⏱️ **30 segundos:** Logging se queda como plataforma técnica; las reglas de auditoría de negocio van a los módulos dueños de esas operaciones.

🗣️ **2 minutos:** El paquete de logging debe ofrecer mecanismos: formato, correlación, envío. Qué operación se audita y con qué datos es una decisión de negocio que pertenece a `payments` u `orders`. Si esas reglas viven en logging, cualquier cambio de auditoría obliga a tocar la plataforma y a coordinar a todos.

🔬 **El detalle:** La plataforma puede ofrecer una API de auditoría genérica que cada módulo llama con sus propios datos.

### 22. 🟠 ArchUnit está verde, pero un cambio sigue tocando cinco módulos. ¿Qué investigarías?

⏱️ **30 segundos:** Qué acoplamiento no ve la regla: datos compartidos, un modelo común, eventos o una responsabilidad repartida.

🗣️ **2 minutos:** ArchUnit verde solo dice que los imports cumplen la regla. Sigo el cambio y miro qué tocó en cada módulo: si modificó tablas compartidas, un tipo de `common` o eventos que consumen todos, el acoplamiento está ahí. La corrección depende de cuál sea: dueño de datos, modelos locales o mover la regla.

🔬 **El detalle:** Es la situación típica que muestra que una prueba arquitectónica es necesaria pero no suficiente.

### 23. 🟠 ¿Qué criterio usarías para eliminar o dividir un *shared kernel* creciente?

⏱️ **30 segundos:** Que cambie por razones que no son comunes a todos sus consumidores, o que su crecimiento obligue a coordinar cambios frecuentes.

🗣️ **2 minutos:** Reviso el historial del shared kernel: si la mayoría de sus cambios interesan solo a un consumidor, esa parte debería vivir en ese módulo. Si crece con cada funcionalidad nueva, está absorbiendo modelo que no es compartido. Lo divido en una parte común mínima y devuelvo el resto a sus dueños.

🔬 **El detalle:** El tamaño de lo compartido debería tender a mantenerse o bajar; si sube continuamente, algo se está centralizando de más.

### 24. 🟠 ¿Cómo demostrarías que una duplicación compró autonomía sin crear divergencia peligrosa?

⏱️ **30 segundos:** Midiendo que los cambios de cada lado dejaron de requerir coordinación y que una reconciliación no encuentra divergencias con consecuencias.

🗣️ **2 minutos:** Comparo cambios antes y después: si `notifications` cambia su DTO sin tocar `orders` y viceversa, la duplicación compró autonomía. Para vigilar la divergencia, una comprobación periódica de los datos críticos detecta diferencias que importen. Si aparecen, se decide si ese concepto debe volver a compartirse.

🔬 **El detalle:** Duplicar sin medir es tan arriesgado como compartir sin medir; las dos decisiones se sostienen con evidencia.

## 🎤 Respuestas de la simulación

### S1. 🟢 ¿Qué diferencia una capacidad de una capa técnica?

⏱️ **30 segundos:** La capa agrupa por rol técnico; la capacidad, por algo que el negocio sabe hacer, con sus reglas y sus datos.

🗣️ **2 minutos:** Controladores, servicios y repositorios existen en toda capacidad; organizarlos como carpetas principales reparte cada cambio de negocio por todas ellas. Una capacidad como `inventory` agrupa lo que cambia junto y tiene un dueño. Las capas pueden seguir existiendo dentro de ella.

🔬 **El detalle:** El criterio es dónde queda un cambio típico: en una capacidad, o repartido en todas las capas.

### S2. 🟢 ¿Qué hace pública una API de módulo?

⏱️ **30 segundos:** La decisión deliberada de publicar esos comandos, consultas y resultados para otros módulos, no la visibilidad del lenguaje.

🗣️ **2 minutos:** Una clase `public` es accesible; una API pública es un contrato diseñado para que otro módulo decida sin conocer el interior. `InventoryApi` con `reserve` y resultados cerrados lo es; el repositorio de stock, aunque sea visible, no. Se complementa con reglas que prohíben usar lo accesible pero no publicado.

🔬 **El detalle:** Menos superficie publicada significa menos compromisos y más libertad para cambiar el interior.

### S3. 🟢 ¿Qué significa poseer una tabla?

⏱️ **30 segundos:** Ser su único escritor y responder por su esquema, sus invariantes y la calidad de sus datos.

🗣️ **2 minutos:** Si `inventory` posee las reservas, nadie más las escribe, y cualquier cambio de columnas lo decide `inventory`. Otros leen por vistas publicadas o piden cambios con comandos. Se puede compartir la base física sin compartir la propiedad; los permisos por rol lo hacen cumplir.

🔬 **El detalle:** Poseer una tabla también implica responder por sus reparaciones y reconciliaciones.

### S4. 🟢 ¿Qué sería un shared kernel pequeño?

⏱️ **30 segundos:** Un conjunto mínimo y estable de conceptos que varios módulos acuerdan compartir, como `Money` con su moneda y redondeo.

🗣️ **2 minutos:** Pequeño significa que cambia poco y que solo contiene lo que debe ser idéntico entre módulos para no romper una invariante. Tiene dueños conjuntos y pruebas contra sus consumidores. Si empieza a acumular entidades y reglas de un módulo, deja de ser pequeño y se vuelve `common`.

🔬 **El detalle:** Un buen indicador es que su historial de cambios sea corto y sus cambios interesen a todos sus consumidores.

### S5. 🟡 ¿Cómo rompes un ciclo `orders`–`inventory`?

⏱️ **30 segundos:** Según el ownership: moviendo la regla a su dueño, reduciendo el contrato a identificadores o, si protegen juntos una invariante, fusionándolos.

🗣️ **2 minutos:** Primero dibujo los tres grafos para saber si el ciclo es de código, de runtime o de datos. Si `inventory` importa `Order` solo para leer el identificador, basta con pasar un valor. Si la regla está repartida, la muevo a quien la posee. Si cada operación cruza ambos, quizá deberían ser un módulo.

🔬 **El detalle:** Esconder el ciclo tras un bus o una interfaz espejo no lo rompe.

### S6. 🟡 ¿Cuándo una llamada directa es suficiente?

⏱️ **30 segundos:** Cuando un módulo necesita una capacidad estable de otro y su respuesta inmediata, dentro del mismo proceso.

🗣️ **2 minutos:** La llamada directa conserva resultado, error y transacción, y es la opción más fácil de leer y depurar. Solo se añade una interfaz, un mediador o un evento cuando cambia de verdad el conocimiento entre módulos o el tiempo del flujo. Por defecto, la llamada es suficiente.

🔬 **El detalle:** Una llamada local no impide extraer más tarde si la API y los datos están bien delimitados.

### S7. 🟡 ¿Qué diferencia comando de evento?

⏱️ **30 segundos:** El comando pide algo a un responsable y puede devolver resultado; el evento anuncia un hecho ya ocurrido a quien quiera escucharlo.

🗣️ **2 minutos:** `ReserveInventory` espera que `inventory` actúe y responda; `OrderCreated` informa y no depende de sus consumidores para que el productor termine. Si un evento necesita exactamente un handler y una respuesta, es un comando mal nombrado, con más indirección y peor manejo de errores.

🔬 **El detalle:** El nombre en pasado no decide; decide si el productor puede completar sin el consumidor.

### S8. 🟡 ¿Cómo evitar que una fachada crezca sin límite?

⏱️ **30 segundos:** Manteniendo una API pequeña, con operaciones de la capacidad y no de cada consumidor, y revisando lo que se añade.

🗣️ **2 minutos:** Una fachada crece cuando cada consumidor pide su método a medida o cuando expone entidades completas. La mantengo orientada a la capacidad —reservar, liberar, consultar disponibilidad— y, ante una petición nueva, pregunto si es una operación del dominio o una necesidad que el consumidor debería resolver. Una regla en CI impide saltarse la fachada.

🔬 **El detalle:** Una fachada que acumula lógica de otros módulos es síntoma de un límite mal puesto.

### S9. 🟡 ¿Qué riesgo tiene exportar el cliente SQL común?

⏱️ **30 segundos:** Que cualquier módulo pueda leer y escribir cualquier tabla, anulando la propiedad de datos.

🗣️ **2 minutos:** Si el cliente SQL es un objeto global que todos importan, nada impide que `orders` actualice el stock. Las escrituras cruzadas aparecen por comodidad y el esquema se vuelve contrato accidental. Cada módulo debería tener su acceso a datos y, en la base, su rol con permisos sobre su propio esquema.

🔬 **El detalle:** En Go, pasar el mismo `*sql.DB` a todos los paquetes produce el mismo efecto.

### S10. 🟡 ¿Cuándo aceptarías un join de lectura?

⏱️ **30 segundos:** Cuando es de solo lectura, usa vistas publicadas con dueño y es más simple que componer varias llamadas.

🗣️ **2 minutos:** Un reporte que cruza pedidos y reservas puede hacerse con un join sobre vistas publicadas sin transferir escritura. Es más eficiente que pedir datos a varias APIs y juntarlos en memoria. Lo evito si toca tablas internas, si su carga afecta a las consultas operativas o si necesita datos que el dueño no quiere exponer.

🔬 **El detalle:** Para cargas pesadas, una réplica de lectura o un read model evita competir con checkout.

### S11. 🟡 ¿Cómo probarías un límite interno?

⏱️ **30 segundos:** Con una regla arquitectónica que falle ante una violación provocada, pruebas del módulo por su API y permisos que impidan escrituras ajenas.

🗣️ **2 minutos:** La regla en CI se prueba añadiendo un import prohibido y viendo que el build falla. Las pruebas del módulo se escriben contra su API, sin tocar sus internos. Los permisos de base cubren lo que el código no ve. Y el historial de cambios dice si el límite contiene lo que debería.

🔬 **El detalle:** Un límite que nunca se ha probado con una violación deliberada no se sabe si existe.

### S12. 🟡 ¿Qué problema causa common sin dueño?

⏱️ **30 segundos:** Una dependencia central con muchas razones de cambio que nadie puede modificar sin coordinar a todos.

🗣️ **2 minutos:** `common` acumula tipos, helpers y reglas de varios módulos; cada cambio afecta a todos sus consumidores y ningún equipo puede decidir solo. Se ahorró duplicación a costa de coordinación permanente. La salida es clasificar su contenido: plataforma estable, shared kernel mínimo con dueños, y el resto de vuelta a sus módulos.

🔬 **El detalle:** Sin dueño, además, nadie se atreve a retirar lo que ya no se usa y el cajón solo crece.

### S13. 🟡 ¿Cómo se conectan APIs sin un contenedor DI?

⏱️ **30 segundos:** Con una raíz de composición explícita que construye las implementaciones y las pasa a los consumidores.

🗣️ **2 minutos:** En el punto de arranque se crean `inventory`, `payments` y `orders`, y a `orders` se le pasa la implementación de `InventoryApi` por constructor o como argumento. No hace falta un contenedor de dependencias: basta con código que ensambla. Tiene la ventaja de que el grafo es visible y verificable al leerlo.

🔬 **El detalle:** Es lo habitual en Go, donde el cableado manual es idiomático.

### S14. 🟡 ¿Qué criterio usa una excepción de importación?

⏱️ **30 segundos:** Que sea estrecha, tenga motivo, dueño, fecha de caducidad y quede registrada y observable.

🗣️ **2 minutos:** Una excepción de importación permite una dependencia prohibida durante una migración. Se limita a ese par de módulos y esa dependencia, con una fecha en la que la regla vuelve a aplicarse. Si vence y sigue haciendo falta, se revisa el motivo; no se renueva sola.

🔬 **El detalle:** Un comodín amplio o sin fecha convierte la regla en decoración.

### S15. 🟡 ¿Qué cambia si el evento interno corre síncronamente?

⏱️ **30 segundos:** Pasa a ejecutarse en la misma pila del productor: su fallo puede afectarle y no hay consistencia eventual.

🗣️ **2 minutos:** Un evento interno despachado de forma síncrona es, en la práctica, una llamada con indirección: el handler corre antes de que el productor termine y, según cómo se maneje, un error puede abortarlo. Llamarlo asíncrono o eventual es engañoso. Hay que decidir si eso es lo que se quiere o si el trabajo debe persistirse y procesarse después.

🔬 **El detalle:** La semántica la decide cuándo y cómo se despacha, no que se llame «evento».

### S16. 🟡 ¿Qué pasa con un evento emitido solo en memoria antes de una caída?

⏱️ **30 segundos:** Se pierde: el trabajo vivía solo en memoria y la caída lo borró sin rastro.

🗣️ **2 minutos:** Si el evento se registró en una lista en memoria y el proceso cae antes de despacharlo, o durante su procesamiento, el efecto nunca ocurre y nadie lo sabe. Para efectos obligatorios, el evento se escribe en la misma transacción que el cambio de negocio y un worker lo procesa con reintentos.

🔬 **El detalle:** Si además se despachó antes del commit y hubo rollback, el efecto ocurre para algo que no existe.

### S17. 🟡 ¿Cómo comparas visibilidad Java e internal de Go?

⏱️ **30 segundos:** Java oculta a nivel de paquete exacto; Go oculta por mayúscula y añade `internal/` por árbol de directorios, que el compilador hace cumplir.

🗣️ **2 minutos:** En Java, un subpaquete no hereda privacidad y hace falta JPMS o una prueba arquitectónica para proteger un paquete interno. En Go, `inventory/internal/...` solo se puede importar desde `inventory/`, y el build falla si otro lo intenta. Los dos protegen código, no datos: el SQL cruzado se controla con permisos.

🔬 **El detalle:** Go es más estricto por defecto; Java es más flexible y necesita más herramientas para el mismo resultado.

### S18. 🟡 ¿Cómo comparas tipos TypeScript y anotaciones Python como límite?

⏱️ **30 segundos:** Ninguno de los dos hace cumplir un límite en runtime: son ayudas del editor y del análisis estático.

🗣️ **2 minutos:** Los tipos de TypeScript desaparecen al compilar y `export` no distingue vecinos de ajenos; las anotaciones de Python no se comprueban en ejecución y la privacidad es convención. En ambos, el límite se hace cumplir con reglas de imports en CI —dependency-cruiser, import-linter— y con validación explícita donde entran datos.

🔬 **El detalle:** Tratar los tipos como frontera es la trampa común: lo que llega en runtime puede no coincidir con ellos.

### S19. 🟡 ¿Qué debe devolver `ReserveInventory`?

⏱️ **30 segundos:** Un resultado cerrado que permita a `orders` decidir: reserva creada, stock insuficiente o conflicto.

🗣️ **2 minutos:** `orders` necesita saber si puede confirmar el pedido y, si no, por qué. Un resultado explícito lo expresa sin exponer el stock ni las excepciones internas. Con un tipo cerrado, si `inventory` añade un resultado, el compilador obliga a `orders` a tratarlo.

🔬 **El detalle:** Devolver la entidad de reserva o un booleano sin motivo obliga al consumidor a adivinar.

### S20. 🟡 ¿Cómo revisas si una frontera sigue siendo útil?

⏱️ **30 segundos:** Midiendo si los cambios reales siguen quedando contenidos y si la coordinación que impone compensa lo que protege.

🗣️ **2 minutos:** Reviso los últimos cambios de esa zona: si casi todos cruzan la frontera, sobra o está mal puesta; si quedan dentro, cumple su función. También miro las excepciones acumuladas y los ciclos. Una frontera útil reduce trabajo; una inútil lo multiplica.

🔬 **El detalle:** La revisión se programa, no se deja para cuando moleste.

### S21. 🟠 ¿Un módulo necesita su propia base para ser real?

⏱️ **30 segundos:** No: un módulo es real si tiene dueño de escritura, API y controles, aunque comparta la base con otros.

🗣️ **2 minutos:** La propiedad de datos es lógica: `inventory` puede ser el único escritor de sus tablas en una base común, con permisos que lo hacen cumplir. Una base propia sin dueño claro no resuelve nada. Separar el almacenamiento se justifica por aislamiento, escala u operación, no por la definición de módulo.

🔬 **El detalle:** Compartir base conserva transacciones y joins, que suelen ser una ventaja.

### S22. 🟠 ¿Todo ciclo debe eliminarse añadiendo un mediador?

⏱️ **30 segundos:** No: a veces el ciclo revela que dos módulos deberían ser uno, o que una regla está en el sitio equivocado.

🗣️ **2 minutos:** Un mediador rompe el ciclo entre pares concentrando el flujo, pero si la causa es una responsabilidad repartida, solo la mueve a otro lugar. Antes elijo según el ownership: reducir el contrato, mover la regla, invertir la dependencia, mediar o fusionar. Cada opción tiene su coste.

🔬 **El detalle:** Un mediador que absorbe reglas de todos acaba siendo el módulo omnisciente del sistema.

### S23. 🟠 ¿Duplicar un DTO siempre viola DRY?

⏱️ **30 segundos:** No: DRY evita repetir conocimiento; dos DTO parecidos con motivos de cambio distintos no son el mismo conocimiento.

🗣️ **2 minutos:** Si `orders` y `notifications` necesitan una dirección con reglas distintas, cada uno puede tener su DTO y evolucionar solo. Unificarlos crearía un dueño común para dos conceptos. Solo comparto cuando la divergencia rompería una invariante, como el redondeo del dinero.

🔬 **El detalle:** La duplicación deliberada se vigila; la accidental se elimina.

### S24. 🟠 ¿Un test arquitectónico verde certifica módulos correctos?

⏱️ **30 segundos:** No: certifica que el grafo de imports cumple una regla, no que los módulos estén bien diseñados.

🗣️ **2 minutos:** El test no ve escrituras cruzadas por SQL, eventos que ordenan cosas, ni cambios que siguen tocando varios módulos. Tampoco dice si el límite está en el lugar correcto. Es una evidencia necesaria que se combina con permisos, pruebas de módulo e historial de cambios.

🔬 **El detalle:** Un test verde con excepciones permanentes certifica aún menos.

### S25. 🟠 ¿Puedes conservar una dependencia bidireccional temporal?

⏱️ **30 segundos:** Sí, durante una migración, como excepción registrada con dueño, fecha y plan para eliminarla.

🗣️ **2 minutos:** Mientras se mueve una responsabilidad, puede hacer falta que dos módulos se llamen en ambos sentidos. Se acepta si está acotada, observada y tiene una fecha de retirada. Lo que no se acepta es que se quede indefinidamente, porque entonces la frontera deja de significar nada.

🔬 **El detalle:** Si la dependencia bidireccional sigue tras la migración, es señal de que los módulos deberían fusionarse.

### S26. 🟠 En E1, ¿qué cambio harías antes de reorganizar todos los paquetes?

⏱️ **30 segundos:** Una costura para una sola operación: una API en `inventory` que la regla use, con una prueba del comportamiento de reserva.

🗣️ **2 minutos:** Antes de reorganizar todos los paquetes, averiguo el motivo de cada edición y si se repite. Luego creo una API para esa operación, paso el cambio por ella y verifico con una prueba que la reserva se comporta igual. Así distingo las capas legítimas de la propagación accidental y tengo una mejora medible.

🔬 **El detalle:** Reorganizar todo sin esa evidencia mueve carpetas sin garantizar que el siguiente cambio sea más local.

### S27. 🟠 En E2, ¿cómo recuperas autoridad sin mover las tablas?

⏱️ **30 segundos:** Declarando dueños, ofreciendo comandos para lo que hoy se hace con escrituras directas y revocando permisos al terminar la migración.

🗣️ **2 minutos:** Inventario los escritores, incluidos jobs y scripts ocultos. `inventory` pasa a ser el único que cambia stock y `orders` el único que cambia el estado del pedido; `notifications` y `orders` usan los comandos del dueño. Migro consumidor a consumidor manteniendo el servicio y revoco los permisos cuando no quedan escrituras ajenas. Las tablas no se mueven.

🔬 **El detalle:** Recuperar la autoridad primero hace que una separación física futura, si llega, sea mucho más sencilla.

### S28. 🟠 En E3, ¿cómo decides si conservar la biblioteca común?

⏱️ **30 segundos:** Clasificando su contenido: lo que tiene significado común y estable se queda con dueño; el resto vuelve a cada módulo o se duplica.

🗣️ **2 minutos:** Reviso qué tipos cambian poco y son idénticos para todos —importes, identidades— y cuáles contienen reglas con motivos distintos. Los primeros forman un shared kernel pequeño; los segundos se devuelven a sus dueños. Empiezo sustituyendo la dependencia de un único consumidor y mido si deja de tener que cambiar con cada actualización.

🔬 **El detalle:** La semántica de importes e identidades es lo que no puede divergir; eso decide qué se conserva compartido.

### S29. 🟠 En E4, ¿cómo localizarías el ciclo que aún aparece en producción?

⏱️ **30 segundos:** Con una traza o una prueba de secuencia que muestre el callback en ejecución, antes de cambiar ningún mecanismo.

🗣️ **2 minutos:** Las reglas de imports pasan porque el ciclo es de runtime: `inventory` espera un callback de `orders` a través del bus. Una traza del flujo de reserva muestra el orden real de llamadas, los errores y si todo ocurre en la misma transacción. Con eso decido quién debe tener la autoridad de la reserva y hago explícito el flujo.

🔬 **El detalle:** Es el caso típico de confundir desacoplamiento estático con temporal: el grafo de código limpio no dice nada del runtime.

### S30. 🟠 En E5, ¿qué acceso de reporting permitirías?

⏱️ **30 segundos:** Una lectura publicada con frescura y capacidad acordadas.

🗣️ **2 minutos:** Evalúo vista o réplica antes de una API remota por cada join; conservo autoridad exclusiva de escritura.

🔬 **El detalle:** La excepción incluye revisión del schema y coste de consultas.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [07 — Simulación de entrevista: Modularidad y límites internos](07-simulacion-de-entrevista.md).

**Siguiente:** [01 — Transacciones locales y límites de consistencia](../03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md).
