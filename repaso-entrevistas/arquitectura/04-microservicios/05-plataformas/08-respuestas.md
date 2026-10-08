# 08 — Respuestas: Plataformas

> Solucionario del bloque `05-plataformas`. Cada respuesta va en tres capas:
> **⏱️ 30 segundos** lo que dices primero, **🗣️ 2 minutos** lo que añades cuando dicen "cuéntame
> más", y **🔬 El detalle** lo que estudias pero no dices en voz alta. El enunciado está copiado
> literalmente del capítulo: si no cuadra, manda el capítulo y este archivo está desactualizado.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--qué-cambia-entre-plataformas) · [02](#02--java) · [03](#03--node-y-typescript) · [04](#04--go) · [05](#05--python) · [06](#06--la-matriz-de-decisión) · [07](#07--simulación-de-entrevista)

---

# 01 — Qué cambia entre plataformas

**01 → 1. Nombra cuatro de los siete ejes que diferencian plataformas de verdad. 🟢**

⏱️ **30 segundos** — Modelo de concurrencia, propagación de contexto, arranque y memoria, y madurez
del ecosistema para cada patrón.

🗣️ **2 minutos** — A esos se suman el empaquetado, el tipado y su efecto sobre el contrato, y la
contratación y rotación de personas. Los siete tienen en común que se notan en operación o en
mantenimiento, no en una demostración.

🔬 **El detalle** — El de contratación es el que más pesa a dos años y el que menos aparece en las
comparativas técnicas: una plataforma para la que no encuentras gente acaba siendo mantenida por dos
personas que no pueden irse de vacaciones a la vez.

**01 → 2. ¿Qué dos ejes casi nunca importan, y por qué? 🟢**

⏱️ **30 segundos** — La velocidad bruta del lenguaje y la sintaxis: el 95 % del tiempo de un servicio
es espera, y la sintaxis no predice nada.

🗣️ **2 minutos** — En un servicio que consulta bases y llama a otros servicios, la diferencia de
rendimiento del lenguaje se diluye entre la red y el trabajo del otro lado. Solo aparece en cargas con
CPU real: codificación, compresión, cálculo. La sintaxis se discute mucho y no decide nada operativo.

🔬 **El detalle** — Donde el lenguaje sí se nota es en consumo de memoria y en arranque, que son ejes
distintos del de velocidad y que sí tienen traducción económica directa en capacidad de reserva y en
coste de instancias.

**01 → 3. ¿Cuál es la baseline de versiones del corpus? 🟢**

⏱️ **30 segundos** — Java 25 LTS, Spring Boot 4.1, Node 24 LTS, Go 1.27 y Python 3.14, a septiembre de
2026.

🗣️ **2 minutos** — Se declara en un solo sitio para que ningún capítulo fije versiones por su cuenta.
El dato con más consecuencias es el de Spring Boot: la línea 3.5 salió del soporte gratuito a mediados
de 2026, y mucho código en producción sigue ahí.

🔬 **El detalle** — Las fechas de soporte conviene comprobarlas y no recordarlas: cambian, y citar una
versión fuera de soporte como actual es un error caro en una entrevista. Un único sitio de consulta
resuelve las cinco.

**01 → 4. ¿Qué mecanismo de propagación de contexto tiene cada plataforma? 🟢**

⏱️ **30 segundos** — Java lo ata al hilo; Node usa `AsyncLocalStorage`; Go lo pasa por la firma con
`context.Context`; Python usa `contextvars`.

🗣️ **2 minutos** — De ahí salen los fallos característicos: en Java se pierde al cruzar a un pool; en
Node y Python, al salir del modelo asíncrono soportado; en Go, cuando una función no recibe o no pasa
el contexto. Es el eje que más afecta a la calidad de las trazas.

🔬 **El detalle** — La diferencia de fondo es visibilidad: en Go el contexto es explícito y se ve
cuándo falta; en las demás es implícito y se pierde en silencio. Eso hace que los fallos de Go sean
más fáciles de detectar en revisión de código.

**01 → 5. ¿Qué tumba a cada una de las cuatro, en términos de concurrencia? 🟢**

⏱️ **30 segundos** — A Java, agotar el pool; a Node, bloquear el único hilo; a Go, fugas de goroutines
sin cancelar; a Python, bloquear el bucle de eventos.

🗣️ **2 minutos** — Los modos de fallo son distintos y hay que conocerlos: Java degrada y luego cae;
Node se congela de golpe e incluso deja de responder a las peticiones ya listas; Go muere despacio por
memoria; Python se comporta como Node si se mezcla código bloqueante en asíncrono.

🔬 **El detalle** — Con hilos virtuales, el fallo de Java cambia de sitio: ya no se agotan los hilos
sino los recursos de abajo —conexiones, capacidad del destino—. El límite de concurrencia por destino
pasa a ser más importante que el tamaño del pool.

**01 → 6. ¿Por qué el arranque es una propiedad económica? 🟢**

⏱️ **30 segundos** — Porque si una instancia tarda en levantar, el escalado automático no llega a
tiempo al pico y hay que mantener capacidad de reserva.

🗣️ **2 minutos** — También alarga los reemplazos —cada instancia está fuera más tiempo— y obliga a dar
más margen a la sonda de arranque. El coste de la reserva suele ser mayor que la diferencia de consumo
entre plataformas, y casi nunca se calcula.

🔬 **El detalle** — El caso donde más se nota es el de cargas muy variables o efímeras: funciones que
arrancan por petición, o servicios que escalan a cero. Ahí el arranque pasa de ser un detalle a ser el
criterio principal.

**01 → 7. ¿Por qué el 95 % del tiempo de un servicio típico hace irrelevante la velocidad del lenguaje? 🟡**

⏱️ **30 segundos** — Porque ese tiempo se va en esperar: red, base de datos, otros servicios. El
lenguaje solo compite por el 5 % restante.

🗣️ **2 minutos** — Mejorar un 30 % la parte de cómputo cuando es el 5 % del total cambia la latencia
un 1,5 %. Por eso las optimizaciones que rinden son otras: un índice, una llamada menos, un lote en
vez de un `N+1`. Y por eso los benchmarks de servidores vacíos exageran tanto.

🔬 **El detalle** — La excepción son los servicios con trabajo real de CPU: procesamiento de imágenes,
compresión, criptografía intensiva, cálculo numérico. Ahí el perfil cambia por completo y la elección
de plataforma sí se decide por rendimiento.

**01 → 8. ¿Por qué "hecho" no es siempre mejor que "a mano"? 🟡**

⏱️ **30 segundos** — Porque lo hecho esconde comportamiento, y cuando falla hay que entenderlo
igualmente.

🗣️ **2 minutos** — Una anotación que aplica un circuit breaker no funciona si la llamada es interna al
objeto; un consumidor que confirma automáticamente puede perder mensajes según su configuración.
Cablearlo a mano cuesta más líneas pero no sorprende, y en Go esa es la cultura por una razón
deliberada.

🔬 **El detalle** — El equilibrio depende del equipo: lo hecho rinde cuando el equipo conoce sus
mecanismos y es un riesgo cuando se adopta como caja negra. Por eso la misma librería puede ser un
acierto en un equipo y una fuente de incidentes en otro.

**01 → 9. ¿Qué cambió con los hilos virtuales en el argumento sobre programación reactiva? 🟡**

⏱️ **30 segundos** — Que bloquear dejó de ser caro, así que buena parte de la ventaja del modelo
reactivo se obtiene sin cambiar de estilo de programación.

🗣️ **2 minutos** — El argumento clásico era que con hilos de plataforma no se podía sostener mucha
concurrencia de espera, y que el modelo reactivo lo resolvía a costa de legibilidad y de diagnóstico.
Con hilos ligeros se puede escribir bloqueante y sostener esa concurrencia, lo que reduce mucho el
número de casos donde el modelo reactivo compensa.

🔬 **El detalle** — Dónde sigue compensando: cuando de verdad se necesita composición de flujos con
contrapresión, o cuando ya existe una base de código reactiva coherente. Mezclar los dos modelos a
medias es el peor resultado posible y sigue siéndolo.

**01 → 10. ¿Por qué el outbox es la fila que más separa a las plataformas? 🟡**

⏱️ **30 segundos** — Porque en Java hay módulos que lo implementan y en las demás suele escribirse a
mano.

🗣️ **2 minutos** — El patrón exige integrarse con la transacción local, publicar de forma fiable y
limpiar la tabla, que son tres piezas. El ecosistema de Java las tiene resueltas; en Node y Python se
escriben sobre el cliente de base de datos; en Go hay componentes que lo incluyen. La diferencia son
días de trabajo por servicio.

🔬 **El detalle** — El matiz importante: escribirlo a mano no es difícil, son unas pocas decenas de
líneas. Lo que cuesta es hacerlo bien en todos los servicios y mantenerlo —concurrencia del
publicador, limpieza, métricas—, que es donde el chassis se vuelve imprescindible.

**01 → 11. ¿Por qué un `interface` de TypeScript no da seguridad en ejecución? 🟡**

⏱️ **30 segundos** — Porque los tipos desaparecen al compilar: no hay ninguna comprobación cuando
llegan los datos.

🗣️ **2 minutos** — Si el servicio del otro lado devuelve algo distinto de lo declarado, el programa
sigue con datos que no encajan y el error aparece más tarde en un sitio sin relación aparente. Hace
falta validación real en el borde, con un esquema que exista en ejecución, generado del contrato o
declarado explícitamente.

🔬 **El detalle** — Es una confusión frecuente y cara: muchos equipos creen tener validación de
contrato y lo que tienen es autocompletado. La comprobación rápida es enviar un campo con el tipo
equivocado y ver si alguien se queja.

**01 → 12. ¿Qué preguntas harías ante un benchmark que compara dos plataformas? 🟡**

⏱️ **30 segundos** — Qué hacía el servicio medido, qué perfil de carga se usó, qué no se midió, y con
qué configuración.

🗣️ **2 minutos** — Un servidor que devuelve una respuesta fija mide el serializador, no un sistema
real. Sin base de datos ni red, el resultado no se traslada. Y la configuración —memoria asignada,
versión, modo de ejecución— puede cambiar el resultado más que la plataforma.

🔬 **El detalle** — La pregunta que suele zanjar la discusión: ¿cuánto de la latencia medida era
espera? Si la respuesta es "casi nada", el benchmark está midiendo un caso que no se parece al tuyo, y
la conversación se puede reconducir sin desautorizar a nadie.

**01 → 13. ¿Cómo explicarías la tabla maestra a alguien que solo ha trabajado en una plataforma? 🟡**

⏱️ **30 segundos** — Como el precio de cada patrón: qué te viene hecho y qué tienes que escribir tú en
cada ecosistema.

🗣️ **2 minutos** — Conviene usar un patrón que conozca bien —el circuit breaker, por ejemplo— y enseñar
cómo se ve en las cuatro: una anotación, una función envuelta, una struct, un decorador. La misma
idea, con cantidades de trabajo y de magia distintas. A partir de ahí, el resto de la tabla se lee
sola.

🔬 **El detalle** — El objetivo de la tabla no es elegir ganador sino saber qué vas a tener que
construir. Alguien que llega de Java a un equipo de Go se sorprende no por el lenguaje sino por la
cantidad de cosas que esperaba encontrar hechas.

**01 → 14. Te piden elegir plataforma para un servicio de alta concurrencia y poca CPU. ¿Qué preguntas antes de responder? 🟠**

⏱️ **30 segundos** — Quién lo va a mantener, qué plataformas ya hay en la casa, y qué patrones concretos
necesita el servicio.

🗣️ **2 minutos** — Alta concurrencia y poca CPU encaja bien con las cuatro, así que el criterio
técnico no desempata: casi todo es espera. Lo que desempata es el equipo, el ecosistema para los
patrones que necesita —mensajería, gRPC, tiempo real— y si añadir una plataforma nueva tiene coste. Y
el perfil: si escala a cero o tiene picos bruscos, el arranque pesa.

🔬 **El detalle** — Conviene preguntar también por las conexiones persistentes: si el servicio va a
mantener muchas conexiones abiertas, el coste por conexión ociosa entra en juego y ahí Node y Go
tienen ventaja clara sobre el modelo clásico de hilos.

**01 → 15. ¿Cómo compararías dos plataformas para tu caso, con honestidad? 🟠**

⏱️ **30 segundos** — Mismo caso real con base de datos y red, mismo perfil de carga, diciendo qué no se
midió y con qué configuración.

🗣️ **2 minutos** — Lo práctico es implementar un servicio representativo —no un "hola mundo"— en las
dos, con la misma lógica y la misma base, y medir latencia, memoria, arranque y tamaño de imagen. Y
añadir el dato que nadie mide: cuánto tardó el equipo en escribirlo y cuántas dependencias necesitó.

🔬 **El detalle** — Ese último dato suele ser el más decisivo y el más ignorado. Si una plataforma
tarda el doble en implementar el mismo patrón, esa diferencia se paga en cada servicio y en cada
cambio, mientras que la de latencia probablemente no se note nunca.

**01 → 16. ¿Qué implica para el escalado que una plataforma arranque en segundos? 🟠**

⏱️ **30 segundos** — Que el escalado automático llega tarde al pico y hay que mantener capacidad de
reserva.

🗣️ **2 minutos** — Si el pico dura dos minutos y las instancias tardan uno en estar listas, la
respuesta llega cuando el pico ya pasó. La compensación es mantener instancias de más, que cuestan
dinero de forma continua. También alarga los reemplazos en cada despliegue y obliga a dar más margen a
la sonda de arranque.

🔬 **El detalle** — La compilación nativa cambia esta ecuación en Java, a costa de un tiempo de
construcción mucho mayor y de limitaciones con reflexión y con carga dinámica. Es un intercambio real,
no una mejora gratuita, y conviene plantearlo así.

**01 → 17. ¿Qué eje elegirías como decisivo para un servicio de datos con mucho cálculo? 🟠**

⏱️ **30 segundos** — El modelo de ejecución y el rendimiento real de cómputo: aquí sí importa, al
contrario que en el servicio típico.

🗣️ **2 minutos** — Con trabajo de CPU sostenido, el bucle de eventos de Node es una mala base salvo que
se saque a hilos de trabajo, y el bloqueo global de Python obliga a repartir en procesos. Java y Go
encajan mejor, y a veces la respuesta correcta es Python **precisamente** porque las librerías de
cálculo liberan ese bloqueo y están escritas en C.

🔬 **El detalle** — Ese matiz es importante en entrevistas de sistemas de datos: el argumento contra
Python por su bloqueo global no aplica a las librerías numéricas, que liberan el bloqueo durante el
cálculo. Conocer la excepción evita descartar la opción correcta por un tópico.

**01 → 18. Tu equipo quiere migrar un servicio a otra plataforma por rendimiento. ¿Qué mides antes? 🟠**

⏱️ **30 segundos** — Dónde se va el tiempo hoy: reparto entre espera de red, base de datos y cómputo
propio.

🗣️ **2 minutos** — Si el cómputo propio es una fracción pequeña, migrar no va a cambiar la latencia y
hay que buscar el problema en otro sitio: consultas, llamadas de más, falta de caché. Si el cómputo sí
domina, entonces la migración es una hipótesis razonable y se puede validar con un prototipo del tramo
caro.

🔬 **El detalle** — Hay una alternativa intermedia que casi nunca se considera: mover solo el
componente caro a otra plataforma y dejar el resto. Es más barato que reescribir el servicio y suele
capturar la mayor parte del beneficio.

**01 → 19. ¿Qué dirías de Spring Boot 3.5 en una entrevista en 2026? 🟠**

⏱️ **30 segundos** — Que salió del soporte gratuito a mediados de 2026 y que la línea actual es la
4.x, aunque mucho código sigue en 3.x.

🗣️ **2 minutos** — Lo interesante no es recitarlo sino lo que implica: quien esté en 3.5 tiene una
decisión pendiente —migrar o pagar soporte extendido— y eso condiciona su planificación. Preguntar en
qué línea están y por qué dice más sobre su madurez operativa que cualquier pregunta técnica.

🔬 **El detalle** — En banca es habitual estar en líneas con soporte comercial y migrar despacio, y eso
es una decisión razonable, no un descuido. Reconocerlo evita el error de juzgar como atraso lo que es
gestión de riesgo.

**01 → 20. ¿Qué eje suele decidir de verdad a dos años vista, y por qué? 🟠**

⏱️ **30 segundos** — El equipo: quién lo mantiene, cuánta gente hay y cuánto tarda alguien nuevo en
producir.

🗣️ **2 minutos** — Todas las ventajas técnicas se erosionan si el servicio lo mantienen dos personas
que no pueden ayudarse entre servicios. La rotación es real, las vacaciones también, y un sistema
donde nadie puede cubrir a nadie acaba teniendo servicios intocables. Eso pesa más que cualquier
diferencia de latencia.

🔬 **El detalle** — Es también el argumento más difícil de defender en una discusión técnica, porque
suena a excusa organizativa. Ayuda convertirlo en algo medible: cuántas personas pueden desplegar y
diagnosticar cada servicio hoy.

**01 → 21. Diseña la comparativa que presentarías para decidir la plataforma de un servicio nuevo, con los criterios ponderados y los datos que pedirías. 🟠**

⏱️ **30 segundos** — Criterios ponderados por lo que decide de verdad: equipo, ecosistema para los
patrones necesarios, operación, y muy al final rendimiento bruto.

🗣️ **2 minutos** — La comparativa:

```text
Criterio                        Peso   Dato que pido
──────────────────────────────  ─────  ─────────────────────────────────────
Equipo que lo mantendrá         alto   cuántas personas lo dominan hoy
Ecosistema para SUS patrones    alto   la fila de la tabla maestra que aplique
Operación (despliegue, diagnóstico) alto  ¿sabemos diagnosticarlo de madrugada?
Perfil de carga (arranque,      medio  ¿escala a cero? ¿picos bruscos?
 conexiones, memoria)                  ¿muchas conexiones abiertas?
Contratación y rotación         medio  ¿podemos contratar? ¿cubrimos vacaciones?
Rendimiento bruto               bajo   solo si hay CPU real de por medio
Coste de plataforma adicional   alto   ¿es una plataforma que YA tenemos?
```

Y la conclusión que suele salir: si el servicio no tiene un perfil especial, la respuesta correcta es
la plataforma que ya usa el equipo.

🔬 **El detalle** — El criterio del coste de plataforma adicional es el que cambia el resultado más a
menudo: un servicio que en aislamiento estaría mejor en Go puede no compensar si es el único de Go en
una casa de Java, porque arrastra chassis, observabilidad y guardias.

**01 → 22. Toma tres patrones del corpus y explica cómo cambia su implementación en las cuatro plataformas, sin repetir lo que dicen sus capítulos. 🔴**

⏱️ **30 segundos** — Circuit breaker, outbox y propagación de contexto: los tres muestran tres tipos de
diferencia distintos.

🗣️ **2 minutos** — La comparación:

```text
Patrón            Tipo de diferencia            Lectura
────────────────  ────────────────────────────  ─────────────────────────────
circuit breaker    de FORMA: anotación / función  el resultado es equivalente;
                  envuelta / struct / decorador  cambia cuánta magia hay
outbox            de MADUREZ: hecho vs a mano    cambia cuánto código escribes
                                                 y cuánto hay que mantener
propagación de    de MODELO: implícita vs        cambia dónde se pierde y si
contexto          explícita                      se detecta en revisión
```

Lo que enseña el conjunto: las diferencias entre plataformas no son de una sola clase. Unas son de
ergonomía, otras de trabajo, y otras de visibilidad de los errores.

🔬 **El detalle** — La tercera es la más interesante para un Tech Lead, porque no se resuelve con
librerías: es una propiedad del lenguaje. En un equipo que rota, una plataforma donde los errores son
visibles en revisión vale más que una donde todo funciona hasta que no.

**01 → 23. Escribe la respuesta de dos minutos a "¿qué plataforma elegirías para nuestro sistema?" cuando no conoces el sistema. 🔴**

⏱️ **30 segundos** — "Depende de tres cosas: quién lo mantiene, qué patrones necesita, y qué
plataformas ya tenéis. Por defecto, la que ya usa el equipo."

🗣️ **2 minutos** — La respuesta desarrollada:

```text
1. Lo que NO decide   la velocidad del lenguaje: en un servicio con base de datos,
                      casi todo el tiempo es espera
2. Lo que sí decide   · el equipo que lo va a mantener y cubrir
                      · qué te da hecho el ecosistema para los patrones que necesitas
                        (mensajería, gRPC, tiempo real, outbox)
                      · el perfil de carga: arranque, conexiones, memoria
                      · si añadir una plataforma nueva tiene coste en vuestra casa
3. Mi recomendación   la plataforma que ya usáis, salvo que el servicio tenga un
   por defecto        perfil especial que la haga mala elección
4. Cuándo me desvío   servicio de datos → Python; sidecar o agente → Go;
                      BFF de la web → Node/TS con el equipo de frontend
```

🔬 **El detalle** — Terminar con los casos donde sí me desviaría es lo que evita que la respuesta suene
conservadora: demuestra que hay criterio detrás de la recomendación por defecto, y no simple
aversión al cambio.

**01 → 24. Un candidato afirma que Go es siempre mejor para microservicios. Responde con lo que concedes y lo que rechazas. 🔴**

⏱️ **30 segundos** — Concedo arranque, memoria, imagen y gRPC; rechazo el "siempre", porque ignora el
equipo y la madurez del ecosistema para ciertos patrones.

🗣️ **2 minutos** — La respuesta:

```text
Se concede    · arranque casi inmediato y memoria baja → mejor escalado y menos reserva
              · binario único → imágenes pequeñas y despliegue simple
              · gRPC y context con deadlines: es su terreno
              · ideal para sidecars, agentes y servicios de infraestructura
Se rechaza    · "siempre": en una casa de Java, un servicio de Go arrastra chassis,
                observabilidad y guardias propias
              · para servicios con mucha lógica de negocio, el ecosistema de Java
                da más hecho (outbox, saga, testing, BPM)
              · para un BFF, Node/TS suele encajar mejor por equipo y tipos
              · para datos y modelos, Python tiene el ecosistema
Conclusión    Go es una excelente elección para una clase de servicios,
              no la respuesta por defecto para todos
```

🔬 **El detalle** — Conviene cerrar preguntando por el contexto en vez de con una sentencia: en un
sistema donde ya todo es Go, su afirmación es prácticamente correcta. La discusión técnica casi
siempre mejora cuando se devuelve al caso concreto.

---

# 02 — Java

**02 → 1. ¿Cuál es la diferencia de fondo entre Spring Boot y Quarkus? 🟢**

⏱️ **30 segundos** — Cuándo se resuelve la configuración: Spring lo hace sobre todo en arranque y
Quarkus en compilación.

🗣️ **2 minutos** — Procesar las anotaciones y generar en tiempo de compilación es lo que da arranque
rápido y menos memoria, porque en ejecución ya no hay que descubrir nada. De ahí salen también las
restricciones: lo que dependa de reflexión o de carga dinámica hay que declararlo, y algunas librerías
antiguas no encajan.

🔬 **El detalle** — Decirlo así evita la comparación de funciones, que no lleva a ningún sitio porque
las tres hacen lo mismo. La diferencia técnica real es de momento de resolución; la diferencia
práctica es de tamaño de ecosistema.

**02 → 2. ¿Por qué Spring Boot es la opción por defecto, dicho con honestidad? 🟢**

⏱️ **30 segundos** — Por ecosistema y por contratación, no por razones técnicas.

🗣️ **2 minutos** — Todo lo que necesita este corpus tiene implementación madura en Spring, y
cualquiera que entre al equipo lo conoce. Eso vale más que unos cientos de milisegundos de arranque en
la mayoría de los sistemas. Reconocerlo en una entrevista puntúa más que defenderlo con argumentos
técnicos débiles.

🔬 **El detalle** — El argumento se invierte cuando el arranque y la memoria son requisito real:
funciones efímeras, escalado a cero o cientos de instancias pequeñas. Ahí el ecosistema pesa menos que
el perfil operativo.

**02 → 3. Enumera tres patrones donde el ecosistema de Java te da mucho hecho. 🟢**

⏱️ **30 segundos** — Saga —incluidos motores BPM—, outbox con módulos que lo implementan, y
resiliencia declarativa con métricas.

🗣️ **2 minutos** — A eso se suman el testing, que es el ecosistema más completo de las cuatro, y la
observabilidad con agente automático. El patrón donde la ventaja es mayor es el outbox: en las demás
plataformas suele escribirse a mano.

🔬 **El detalle** — La contrapartida de tenerlo todo hecho es que esconde comportamiento: el proxy de
una anotación, la confirmación automática de un consumidor. Sigue siendo necesario entender el
mecanismo para diagnosticar cuando falla.

**02 → 4. ¿Cuáles son los tres modelos de ejecución y cuándo se usa cada uno? 🟢**

⏱️ **30 segundos** — Hilo por petición, reactivo, e hilos virtuales. Hoy, virtuales por defecto para
servicios de espera.

🗣️ **2 minutos** — El hilo por petición es simple de leer y de depurar. El reactivo da mucha
concurrencia y contrapresión a costa de legibilidad. Los hilos virtuales permiten escribir bloqueante
y sostener alta concurrencia, lo que reduce los casos donde el reactivo compensa.

🔬 **El detalle** — Reactivo sigue teniendo sitio donde hace falta contrapresión real en flujos o donde
ya existe una base reactiva coherente. Lo que nunca funciona es mezclarlos a medias: una llamada
bloqueante en una cadena reactiva anula el beneficio completo.

**02 → 5. Nombra las tres trampas de lo declarativo. 🟢**

⏱️ **30 segundos** — El proxy —las llamadas internas no lo atraviesan—, el orden de las anotaciones, y
lo que el marco decide implícitamente.

🗣️ **2 minutos** — La del proxy es la que más tiempo hace perder porque el síntoma es la ausencia de
comportamiento, sin error. El orden importa cuando hay varias anotaciones sobre el mismo método. Y lo
implícito —confirmaciones, transacciones, conexiones— decide bien hasta que el caso es raro.

🔬 **El detalle** — La comprobación rápida para la primera: mirar si esa llamada aparece en las
métricas del mecanismo. Si el circuit breaker no registra llamadas, no se está aplicando aunque la
anotación esté ahí.

**02 → 6. ¿Qué compra y qué cuesta la compilación nativa? 🟡**

⏱️ **30 segundos** — Compra arranque muy rápido y memoria mucho menor; cuesta tiempo de construcción,
restricciones con reflexión y rendimiento sostenido.

🗣️ **2 minutos** — Acerca el perfil operativo de Java al de Go, que es justo donde Java pierde. A
cambio, el pipeline se ralentiza, hay que declarar lo que usa reflexión, algunas librerías no encajan,
y se pierde la optimización progresiva de la máquina virtual en servicios de larga vida.

🔬 **El detalle** — Por eso encaja en funciones efímeras y en escalado a cero, y encaja mal en
servicios de tráfico constante: ahí el arranque se paga una vez al día y el rendimiento sostenido pesa
más.

**02 → 7. ¿Por qué los hilos virtuales cambian el argumento sobre reactivo? 🟡**

⏱️ **30 segundos** — Porque el argumento era que bloquear es caro, y con hilos virtuales deja de
serlo.

🗣️ **2 minutos** — Antes, sostener miles de peticiones en espera exigía no bloquear, y eso obligaba al
modelo reactivo con su coste de legibilidad y de diagnóstico. Ahora se puede escribir código
bloqueante y sencillo manteniendo esa concurrencia. Lo que queda del argumento reactivo es la
contrapresión, que es un problema distinto.

🔬 **El detalle** — En una entrevista conviene decir explícitamente que esto cambió hace poco: mucha
gente aprendió la recomendación anterior y la sigue repitiendo. Situar el cambio en el tiempo demuestra
que se mantiene al día sin sonar a moda.

**02 → 8. ¿Qué recurso pasa a ser escaso cuando los hilos dejan de serlo? 🟡**

⏱️ **30 segundos** — Las conexiones del pool de base de datos y la capacidad del servicio destino.

🗣️ **2 minutos** — Si es barato tener diez mil tareas concurrentes, diez mil pueden pedir conexión a la
vez o golpear al mismo servicio. El cuello se mueve hacia abajo. Por eso el límite de concurrencia por
destino y el bulkhead siguen siendo necesarios, con otro argumento: ya no protegen hilos, protegen a
los de abajo.

🔬 **El detalle** — Es un cambio de mentalidad sutil: el pool de hilos actuaba como limitador
implícito de todo lo demás. Al quitarlo, hay que poner límites explícitos donde antes no hacían falta,
y eso sorprende a equipos que migran sin pensarlo.

**02 → 9. ¿Por qué una anotación puede no aplicarse, y cómo se detecta? 🟡**

⏱️ **30 segundos** — Porque la llamada es interna al mismo objeto y no pasa por el proxy. Se detecta
mirando las métricas del mecanismo.

🗣️ **2 minutos** — El marco envuelve el objeto para aplicar el comportamiento; una llamada de un método
a otro del mismo objeto va directa y se salta la envoltura. No hay error: simplemente no hay
transacción, ni reintento, ni circuit breaker. Las salidas son separar el método a otro componente o
usar la forma programática.

🔬 **El detalle** — El mismo mecanismo explica por qué a veces "la transacción no se aplica" en el
método privado que alguien extrajo para ordenar el código. Es el mismo fallo con otro síntoma, y
conviene reconocer el patrón.

**02 → 10. ¿Por qué el orden de dos anotaciones de resiliencia cambia el comportamiento? 🟡**

⏱️ **30 segundos** — Porque una envuelve a la otra: si el reintento está fuera, cada intento cuenta
para el circuit breaker; si está dentro, el circuito ve una sola llamada.

🗣️ **2 minutos** — Con el reintento fuera, tres intentos fallidos suman tres fallos y el circuito abre
antes. Con el reintento dentro, el circuito ve un único fallo tras agotar los intentos. Ninguna es
universalmente correcta: la primera reacciona antes, la segunda es menos sensible a fallos
transitorios.

🔬 **El detalle** — Lo que sí es un error es no saber cuál se está aplicando. Es una de esas
configuraciones que conviene fijar en el chassis y documentar, porque depende del orden por defecto del
marco y cambia entre versiones.

**02 → 11. ¿Por qué la compilación nativa complica las librerías que usan reflexión? 🟡**

⏱️ **30 segundos** — Porque el compilador necesita saber en construcción qué se va a usar, y la
reflexión decide en ejecución.

🗣️ **2 minutos** — Lo que no se puede descubrir estáticamente hay que declararlo en configuración para
que se incluya en el ejecutable. Las librerías modernas suelen traer esa declaración; las antiguas o
las que generan clases dinámicamente pueden no funcionar. Es la causa principal de que una migración a
nativo se atasque.

🔬 **El detalle** — El fallo típico aparece tarde y en producción: una ruta poco usada que deserializa
una clase no declarada falla en ejecución aunque todo compile. Por eso la migración exige pruebas que
recorran de verdad todos los caminos.

**02 → 12. ¿En qué caso cuesta más defender Java frente a Go? 🟡**

⏱️ **30 segundos** — En servicios muy pequeños y muy numerosos, donde la memoria y el arranque se
multiplican por el número de instancias.

🗣️ **2 minutos** — Un sidecar, un agente o un servicio de infraestructura con decenas de réplicas es el
caso donde el perfil de Go gana claramente. También en escalado a cero y en funciones efímeras, salvo
que se vaya a nativo. En servicios con lógica de negocio rica, el argumento se invierte.

🔬 **El detalle** — Es un buen sitio para demostrar criterio en una entrevista: reconocer dónde tu
plataforma principal no es la mejor opción da más credibilidad que defenderla en todos los casos.

**02 → 13. ¿Qué revisarías en la configuración por defecto de un servicio Java antes de ponerlo en producción? 🟡**

⏱️ **30 segundos** — Timeouts de los clientes, apagado ordenado, memoria asignada, pools y caché de
resolución de nombres.

🗣️ **2 minutos** — Los timeouts porque varias combinaciones esperan indefinidamente; el apagado
ordenado porque no viene activado en todos los casos y produce errores en cada despliegue; la memoria
porque el valor por defecto depende del entorno; y los pools —de hilos y de conexiones— porque suelen
estar dimensionados para otro perfil.

🔬 **El detalle** — La caché de resolución de nombres de la JVM es la que menos gente revisa y la que
produce fallos más desconcertantes tras un despliegue de una dependencia. Merece estar en la lista de
"listo para producción" del chassis.

**02 → 14. Te preguntan "¿por qué Spring y no Quarkus?" en una entrevista. Responde en un minuto. 🟠**

⏱️ **30 segundos** — "Por ecosistema y por gente. La diferencia técnica es cuándo se resuelve la
configuración, y solo me compensa si el arranque y la memoria son requisito real."

🗣️ **2 minutos** — La respuesta completa reconoce lo que Quarkus hace mejor —arranque, memoria, nativo
más cómodo— y explica por qué no suele decidir: en un servicio de tráfico constante, el arranque se
paga una vez al día. Y termina con la condición que me haría cambiar: escalado a cero, funciones
efímeras o muchas instancias pequeñas.

🔬 **El detalle** — Conviene evitar el tópico de "Quarkus es Spring pero rápido": no sobrevive a la
repregunta y sugiere que no se conoce el modelo. Hablar del momento de resolución sí demuestra que se
entiende la diferencia.

**02 → 15. Un equipo quiere migrar a reactivo para aguantar más carga. ¿Qué preguntas antes? 🟠**

⏱️ **30 segundos** — Si ya están en hilos virtuales, dónde está el cuello hoy, y si toda la cadena
puede ser no bloqueante.

🗣️ **2 minutos** — Si el cuello es esperar a dependencias, los hilos virtuales dan casi lo mismo sin
reescribir. Si el cuello es la base de datos o un servicio lento, reactivo no lo arregla: solo cambia
cómo esperas. Y si alguna parte de la cadena es bloqueante —un cliente antiguo, una librería—, el
beneficio se anula y queda toda la complejidad.

🔬 **El detalle** — La pregunta decisiva suele ser la del equipo: reactivo cambia cómo se depura, cómo
se leen las trazas de pila y cómo se razonan los errores. Si no todo el equipo lo domina, el coste real
no es de rendimiento sino de mantenimiento.

**02 → 16. ¿Cuándo propondrías compilación nativa, y qué condiciones pondrías? 🟠**

⏱️ **30 segundos** — Cuando el arranque o la memoria sean requisito, y con el pipeline y las librerías
comprobadas desde el principio.

🗣️ **2 minutos** — Las condiciones: que las librerías del servicio la soporten, que el tiempo de
construcción sea asumible para el ritmo de despliegue del equipo, y que haya pruebas que recorran todos
los caminos —porque los fallos de reflexión aparecen en ejecución—. Y la decisión debe tomarse al
empezar el servicio, no a mitad.

🔬 **El detalle** — Conviene medir el beneficio esperado antes: si el servicio arranca en tres segundos
y despliega dos veces al día, el ahorro es irrelevante. El caso que lo justifica es el escalado
frecuente, no el despliegue.

**02 → 17. Tu servicio tiene un circuit breaker que no actúa. Da la causa más probable y cómo la confirmas. 🟠**

⏱️ **30 segundos** — Llamada interna al mismo objeto, que no pasa por el proxy. Se confirma mirando si
el mecanismo registra esa llamada en sus métricas.

🗣️ **2 minutos** — Si las métricas del circuit breaker no muestran llamadas para ese nombre, no se está
aplicando. Otras causas posibles: nombre de configuración distinto del de la anotación, o la excepción
lanzada no está en la lista de fallos contabilizados. Las tres se descartan en minutos mirando
configuración y métricas.

🔬 **El detalle** — La tercera es sutil y frecuente: por defecto, algunas excepciones —como las de
negocio— pueden estar excluidas del recuento, con lo que el circuito nunca abre aunque todo falle.
Conviene revisar qué cuenta como fallo al configurarlo.

**02 → 18. El equipo está en Spring Boot 3.5 en 2026. ¿Qué recomiendas? 🟠**

⏱️ **30 segundos** — Planificar la migración a la línea 4.x, o contratar soporte extendido de forma
consciente; lo que no vale es no decidir.

🗣️ **2 minutos** — La 3.5 salió del soporte gratuito a mediados de 2026, así que las correcciones de
seguridad dejan de llegar por el canal habitual. Las opciones son migrar —con el coste de revisar
cambios de la línea mayor— o pagar soporte comercial mientras se planifica. En banca, lo segundo es
frecuente y razonable.

🔬 **El detalle** — La recomendación práctica es empezar por un servicio pequeño y poco crítico para
medir el coste real de la migración, y con ese dato planificar el resto. Estimar la migración de
quince servicios sin haber hecho uno es adivinar.

**02 → 19. ¿Qué dejarías fuera de Java en un sistema políglota, y por qué? 🟠**

⏱️ **30 segundos** — Los sidecars y agentes, el BFF de la web, y los servicios de datos o de modelos.

🗣️ **2 minutos** — Los agentes y sidecars, por perfil operativo: binario pequeño y memoria baja, que es
Go. El BFF de la web, por propiedad: lo mantiene el equipo de frontend y comparte lenguaje y tipos con
el cliente. Y los servicios de datos, porque el ecosistema está en Python. El resto —dominio, sagas,
lotes— se queda en Java.

🔬 **El detalle** — Cada una de esas excepciones tiene que justificar su coste: chassis, observabilidad
y guardias en esa plataforma. Por eso conviene que sean pocas y con un criterio escrito, que es el tema
del capítulo `06`.

**02 → 20. ¿Cómo justificarías el consumo de memoria de Java ante una dirección que mira el coste? 🟠**

⏱️ **30 segundos** — Comparando el coste total: infraestructura frente a tiempo de desarrollo y de
incidentes, no memoria contra memoria.

🗣️ **2 minutos** — La memoria de más tiene un coste calculable y normalmente modesto frente al salario
del equipo. Lo que hay que poner en el otro lado es lo que el ecosistema ahorra: patrones resueltos,
herramientas maduras, gente disponible. Y si el coste de infraestructura sí es determinante —muchas
instancias—, entonces la conversación correcta es sobre ajuste de memoria y compilación nativa.

🔬 **El detalle** — Conviene llevar números concretos del propio sistema: coste mensual de las
instancias frente a coste de una persona. En la mayoría de los sistemas medianos, la diferencia de
memoria entre plataformas equivale a una fracción pequeña de un sueldo, y eso zanja la discusión.

**02 → 21. Diseña la plantilla de servicio Java del equipo: qué trae resuelto, qué deja abierto y qué prohíbe. 🔴**

⏱️ **30 segundos** — Trae chassis completo y valores seguros; deja abierto el dominio y los plazos por
dependencia; prohíbe dominio compartido y configuración implícita.

🗣️ **2 minutos** — La plantilla:

```text
Trae resuelto     estructura de paquetes; logs estructurados con traza;
                  métricas y exportador de OpenTelemetry; health checks
                  (liveness sin dependencias); apagado ordenado activado;
                  cliente HTTP con pool y SIN reintento por defecto;
                  pruebas de componente con contenedores efímeros
Deja abierto      los plazos por dependencia (obligatorio declararlos: falla al
                  arrancar si faltan); política de reintento por operación;
                  el modelo de dominio
Prohíbe           dependencias hacia un módulo de dominio compartido;
                  acceso a esquemas ajenos; migraciones en el arranque;
                  reintentos activados por defecto
```

🔬 **El detalle** — La decisión de que falle al arrancar si faltan los plazos es la que más rinde:
convierte un olvido silencioso —esperar indefinidamente— en un despliegue fallido, que es infinitamente
más barato de detectar.

**02 → 22. Compara Spring Boot, Quarkus y Micronaut para tres servicios con perfiles distintos, y decide para cada uno. 🔴**

⏱️ **30 segundos** — Servicio de dominio con sagas: Spring Boot. Función efímera de alto volumen:
Quarkus o Micronaut con nativo. Servicio interno pequeño de tráfico constante: Spring Boot.

🗣️ **2 minutos** — La comparación:

```text
Servicio                        Elección          Por qué
──────────────────────────────  ────────────────  ──────────────────────────────
Dominio con sagas y lotes       Spring Boot       ecosistema: saga, batch, testing;
                                                  el arranque no es requisito
Procesamiento efímero, muchas   Quarkus/Micronaut arranque y memoria son EL requisito;
instancias, escala a cero       + nativo          nativo desde el primer día
Servicio interno pequeño,       Spring Boot       ninguna ventaja de los otros aplica;
tráfico constante                                 gana la uniformidad del equipo
```

La regla que sale de la tabla: solo se cambia de marco cuando el perfil operativo lo exige, porque la
uniformidad tiene valor propio.

🔬 **El detalle** — Y una advertencia sobre el segundo caso: elegir Quarkus por el arranque y no ir a
nativo deja el beneficio a medias y el coste de ecosistema entero. Si la compilación nativa no está en
el plan, el argumento se debilita mucho.

**02 → 23. Un servicio Java arranca en 40 segundos y el escalado no llega a tiempo. Da el diagnóstico y tres líneas de acción ordenadas. 🔴**

⏱️ **30 segundos** — Primero averiguar en qué se van esos 40 segundos; después reducir; y mientras
tanto, capacidad de reserva y escalado predictivo.

🗣️ **2 minutos** — El plan:

```text
1. Medir el arranque por fases: contexto, conexiones, cargas iniciales,
   calentamiento. Cuarenta segundos casi nunca es "la JVM": suele haber
   una carga de datos o una conexión lenta dentro.
2. Reducir lo evidente: inicialización perezosa de lo que no hace falta al
   arrancar, precarga en segundo plano, y revisar sondas de arranque
   para que no maten instancias que van bien.
3. Mientras tanto: reserva de capacidad y escalado por métricas adelantadas
   (cola, no CPU), para que la decisión de escalar llegue antes.
4. Si el perfil lo justifica: evaluar compilación nativa, con el coste de
   pipeline y de librerías declarado.
```

🔬 **El detalle** — El paso 1 es el que casi nadie hace y el que más sorprende: en la mayoría de los
casos de arranque muy lento hay una llamada síncrona a otro sistema o una carga de caché completa
escondida en la inicialización. Se arregla en horas y no requiere cambiar de plataforma.

**02 → 24. Escribe el plan de migración de la línea 3.x a la 4.x para un sistema con quince servicios, con el orden y los riesgos. 🔴**

⏱️ **30 segundos** — Uno pequeño primero para medir, después por oleadas, con las dependencias
compartidas actualizadas antes.

🗣️ **2 minutos** — El plan:

```text
Fase 0  Inventario: versión actual por servicio, dependencias compartidas
        (chassis, clientes generados), y qué librerías de terceros tienen
        versión compatible con la línea nueva. Es donde aparecen los bloqueos.
Fase 1  Un servicio pequeño y poco crítico. Se mide el coste real:
        cuántos cambios, cuántas sorpresas, cuánto tarda.
Fase 2  Chassis y librerías internas: tienen que soportar ambas líneas
        durante la transición, o bloquearán a todos.
Fase 3  Oleadas de tres o cuatro servicios, empezando por los menos críticos.
Fase 4  Los críticos, con ventana y plan de vuelta atrás probado.
Riesgos  librerías de terceros sin versión compatible; cambios de comportamiento
        por defecto que no dan error; y el chassis como cuello de botella.
```

🔬 **El detalle** — El riesgo que más retrasa estas migraciones no son los cambios de API —que dan
error de compilación y se arreglan— sino los cambios de comportamiento por defecto, que compilan y
fallan distinto en producción. Por eso la fase 1 tiene que incluir tiempo con tráfico real antes de
declarar el coste.

---

# 03 — Node y TypeScript

**03 → 1. ¿Cómo atiende Node la concurrencia? 🟢**

⏱️ **30 segundos** — Con un solo hilo y un bucle de eventos: las operaciones de espera no bloquean y
el hilo sigue atendiendo mientras tanto.

🗣️ **2 minutos** — Eso lo hace excelente para trabajo de espera —red, base de datos, otros
servicios— con muchas conexiones y poca memoria por conexión. Y lo hace frágil ante trabajo de CPU,
porque no hay otro hilo que siga atendiendo mientras uno calcula.

🔬 **El detalle** — Escalar se hace con varios procesos, no con hilos: cada uno con su bucle. Eso
significa que el estado en memoria —cachés, circuit breaker— se multiplica por proceso, igual que en el
modelo de procesos de Python.

**03 → 2. ¿Qué tumba a un servicio de Node? 🟢**

⏱️ **30 segundos** — Cualquier trabajo de CPU en el hilo principal: mientras dura, no avanza nada.

🗣️ **2 minutos** — Ordenar una lista enorme, serializar un objeto muy grande, comprimir, criptografía
intensiva. El efecto no es degradación sino congelación: también dejan de entregarse respuestas ya
listas y dejan de fluir los latidos de las conexiones abiertas.

🔬 **El detalle** — Las salidas, en orden de preferencia: sacar el cómputo a otro servicio, moverlo a
hilos de trabajo, o partirlo para ceder el control. La primera suele ser la correcta cuando el trabajo
es realmente pesado, porque además permite escalarlo por separado.

**03 → 3. ¿Qué comprueban los tipos de TypeScript y qué no? 🟢**

⏱️ **30 segundos** — Comprueban en compilación; no comprueban nada en ejecución, porque desaparecen.

🗣️ **2 minutos** — Ayudan enormemente a escribir y a refactorizar dentro del servicio, y permiten
compartir tipos con el frontend. Lo que no hacen es verificar que los datos que llegan por la red
coincidan con lo declarado: para eso hace falta validación con un esquema que exista en ejecución.

🔬 **El detalle** — El síntoma del error es característico: el programa falla lejos del punto de
entrada, cuando alguien usa un campo que no era lo que decía el tipo. Validar en el borde convierte
ese fallo difuso en un error claro en el sitio correcto.

**03 → 4. Diferencia entre NestJS y Fastify. 🟢**

⏱️ **30 segundos** — NestJS impone estructura, módulos e inyección; Fastify es un servidor rápido y sin
opinión.

🗣️ **2 minutos** — NestJS ahorra discusiones de organización y se parece a Spring a propósito, lo que
ayuda a equipos de backend. Fastify encaja en servicios pequeños —BFF, agregadores— donde la
estructura la pone el equipo. La elección es de estructura y de equipo, no de rendimiento.

🔬 **El detalle** — El parecido de NestJS con Spring tiene un riesgo: se importan costumbres de Java
que no encajan con un runtime de un hilo, como asumir que el trabajo pesado se puede hacer en línea
porque "hay un pool".

**03 → 5. ¿Dónde se pierde el contexto de traza en esta plataforma? 🟢**

⏱️ **30 segundos** — En hilos de trabajo, en colas o planificadores propios, al publicar en un broker,
y con callbacks antiguos.

🗣️ **2 minutos** — El mecanismo de contexto asíncrono lo mantiene a través de `await`, que cubre la
mayor parte del código moderno. Los cuatro casos restantes son saltos donde ese encadenamiento se
rompe, y hay que propagarlo explícitamente: inyectando en los encabezados del mensaje o pasando el
contexto a mano.

🔬 **El detalle** — El del broker es el más dañino porque corta la traza justo en la parte asíncrona,
que es donde están los problemas difíciles. Conviene que la inyección y la extracción vivan en el
chassis y no en cada productor.

**03 → 6. Nombra tres casos donde esta plataforma gana de verdad. 🟢**

⏱️ **30 segundos** — El BFF de la web, la agregación de llamadas, y el tiempo real con muchas
conexiones.

🗣️ **2 minutos** — El BFF gana por equipo y por tipos compartidos con el frontend. La agregación,
porque lanzar llamadas en paralelo y juntar es idiomático y barato. Y el tiempo real, porque decenas
de miles de conexiones ociosas cuestan muy poca memoria.

🔬 **El detalle** — Los tres tienen algo en común: son cargas de espera, no de cómputo. Esa es la
regla que resume dónde encaja la plataforma, y sirve también para saber cuándo no proponerla.

**03 → 7. ¿Por qué `async/await` no hace concurrente el cómputo? 🟢**

⏱️ **30 segundos** — Porque solo permite ceder el control mientras se **espera**; el cálculo sigue
ocupando el hilo.

🗣️ **2 minutos** — `await` sobre una operación de red libera el hilo hasta que llega la respuesta. Un
bucle que recorre un millón de elementos no espera nada: ocupa el hilo de principio a fin, haya
`async` o no. Marcar una función como asíncrona no la hace paralela.

🔬 **El detalle** — Es una confusión muy frecuente y con consecuencias: gente que convierte funciones
en asíncronas esperando ganar concurrencia y solo añade sobrecarga. La pregunta correcta es si la
función **espera** algo; si no, `async` no aporta.

**03 → 8. ¿Por qué un bloqueo congela en vez de degradar? 🟡**

⏱️ **30 segundos** — Porque hay un solo hilo ejecutando: mientras calcula, nada más avanza.

🗣️ **2 minutos** — En una plataforma con pool, una tarea pesada ocupa un hilo y los demás siguen
atendiendo: la latencia sube gradualmente. Aquí no hay gradualidad: durante el cómputo, todas las
peticiones esperan, incluidas las que ya tenían la respuesta lista. Por eso el síntoma es un pico
brusco en todas las rutas a la vez.

🔬 **El detalle** — Esa forma del síntoma es útil para diagnosticar: si la latencia sube en todas las
rutas simultáneamente y la CPU está alta en un solo proceso, es casi seguro un bloqueo del bucle y no
una dependencia lenta.

**03 → 9. ¿Por qué un bloqueo es peor si hay conexiones persistentes abiertas? 🟡**

⏱️ **30 segundos** — Porque dejan de fluir los latidos y los clientes pueden dar la conexión por
muerta y reconectar todos a la vez.

🗣️ **2 minutos** — Al bloqueo original se le suma un pico de reconexiones justo cuando el proceso ya
va mal, y esas reconexiones cuestan autenticación y recuperación de estado. Es un efecto en cascada
generado por un problema interno, sin que ninguna dependencia haya fallado.

🔬 **El detalle** — Se mitiga separando el proceso que mantiene conexiones del que hace trabajo
pesado, que es el argumento de la capa de conexiones dedicada. También ayuda que los clientes
reconecten con espera aleatoria.

**03 → 10. ¿Por qué la diferencia de rendimiento entre marcos suele ser irrelevante? 🟡**

⏱️ **30 segundos** — Porque el tiempo real se va en la base de datos y en las llamadas a otros
servicios, no en el enrutado.

🗣️ **2 minutos** — Los micro-benchmarks miden peticiones por segundo devolviendo una respuesta fija, y
ahí un marco ligero gana claramente. En un servicio real que consulta datos, esa ventaja queda
enterrada bajo decenas de milisegundos de espera. Elegir por ese número es optimizar un porcentaje
mínimo del total.

🔬 **El detalle** — Hay un caso donde sí importa: servicios de muy alto volumen que hacen poco —un
proxy, un validador de tokens, un agregador de caché—. Ahí el marco puede representar una fracción
apreciable del trabajo y la elección tiene sentido medirla.

**03 → 11. ¿Por qué el BFF de la web encaja tan bien aquí? 🟡**

⏱️ **30 segundos** — Porque comparte lenguaje, tipos y herramientas con el frontend, y lo mantiene el
mismo equipo.

🗣️ **2 minutos** — El BFF existe para que el contrato de una experiencia cambie al ritmo de esa
experiencia, y eso solo ocurre si lo posee su equipo. Si ese equipo ya escribe TypeScript, la fricción
desaparece: mismos tipos, mismo pipeline, misma forma de probar. Además la carga del BFF es
agregación, que es justo lo que esta plataforma hace bien.

🔬 **El detalle** — Es el argumento de poliglotismo más sólido de todo el corpus precisamente porque no
es técnico: es de propiedad. Y por eso sobrevive a la discusión de "podríamos hacerlo en Java": se
podría, y lo mantendría el equipo equivocado.

**03 → 12. ¿Por qué esta plataforma es débil en los patrones de datos? 🟡**

⏱️ **30 segundos** — Porque no hay casi nada hecho para outbox y saga: se escriben a mano.

🗣️ **2 minutos** — El ecosistema es fuerte en el borde —HTTP, tiempo real, agregación— y más pobre en
la mecánica transaccional: no hay módulos de outbox integrados con la transacción, ni abstracciones de
saga maduras. Se puede hacer todo, y hay que escribirlo y mantenerlo.

🔬 **El detalle** — Eso no descalifica la plataforma: significa que un servicio con mucha mecánica
transaccional tiene un coste mayor aquí. Es exactamente el tipo de dato que la tabla maestra pretende
hacer explícito antes de decidir.

**03 → 13. ¿Qué revisarías antes de poner en producción un servicio de Node con muchas conexiones? 🟡**

⏱️ **30 segundos** — Que nada bloquee el bucle, latidos y timeouts de las conexiones, memoria por
conexión, y apagado ordenado con aviso.

🗣️ **2 minutos** — Concretamente: perfilado bajo carga para detectar bloqueos; latidos configurados
para que los intermediarios no corten; límite de conexiones y de memoria; y el cierre avisando a los
clientes para que reconecten contra otra instancia en vez de detectar una caída.

🔬 **El detalle** — Añadiría una prueba de carga con el número de conexiones objetivo, no solo con
peticiones por segundo. Son dos dimensiones distintas y un servicio puede ir perfecto con mil
peticiones por segundo y caerse con cinco mil conexiones abiertas.

**03 → 14. Tu servicio se congela unos segundos cada pocos minutos. Da tres hipótesis ordenadas. 🟠**

⏱️ **30 segundos** — Cómputo pesado en el hilo principal, recolección de basura por un pico de memoria,
o una operación síncrona de disco o de criptografía.

🗣️ **2 minutos** — Las tres, con cómo se distinguen:

```text
1. Cómputo en el bucle      CPU al 100 % en el proceso durante la congelación;
                            coincide con cierto tipo de petición (informe, lote)
2. Recolección de basura    picos de memoria previos; la pausa coincide con
                            caídas bruscas de memoria usada
3. Operación síncrona       lectura de fichero síncrona, criptografía o
                            compresión en línea; se ve en el perfilado
```

El perfilado del proceso durante una congelación resuelve el caso casi siempre, porque muestra
exactamente qué estaba ejecutándose.

🔬 **El detalle** — Un origen frecuente y poco sospechado: serializar respuestas muy grandes. Convertir
a JSON un objeto de decenas de megas bloquea el hilo, y el síntoma —congelación al servir ciertas
peticiones— encaja perfectamente con la primera hipótesis.

**03 → 15. ¿Cómo garantizarías que el contrato se valida de verdad en un servicio de TypeScript? 🟠**

⏱️ **30 segundos** — Con un esquema en ejecución en el borde, generado del contrato, que rechace lo que
no encaje con un error claro.

🗣️ **2 minutos** — El esquema se declara una vez y se usa para validar entradas y, en desarrollo,
también respuestas de dependencias. Idealmente se genera del contrato publicado —OpenAPI o `.proto`—
para que no haya dos fuentes de verdad. Y el tipo de TypeScript se deriva del esquema, no al revés.

🔬 **El detalle** — La derivación del tipo desde el esquema es la parte elegante: se escribe una vez y
se obtienen las dos cosas, validación en ejecución y tipos en compilación, sin riesgo de que
divergan.

**03 → 16. Tienes que serializar respuestas grandes. ¿Qué opciones tienes y cuál eliges? 🟠**

⏱️ **30 segundos** — Paginar o reducir la respuesta, serializar en flujo, o mover el trabajo a otro
proceso. Prefiero reducir la respuesta.

🗣️ **2 minutos** — La mejor solución suele ser de diseño: si la respuesta es de decenas de megas,
probablemente el consumidor no las necesita todas y hay que paginar o filtrar. Si de verdad hacen
falta, serializar en flujo evita construir todo en memoria. Y como último recurso, hilos de trabajo,
con su coste de comunicación.

🔬 **El detalle** — Serializar en flujo tiene una ventaja adicional en esta plataforma: cede el control
entre fragmentos, así que el bucle sigue atendiendo. Convierte un bloqueo largo en muchas pausas
cortas, que es exactamente lo que se quiere.

**03 → 17. ¿Cuándo elegirías NestJS y cuándo Fastify, con un caso de cada uno? 🟠**

⏱️ **30 segundos** — NestJS para un servicio de dominio que va a crecer con un equipo de backend;
Fastify para un BFF o un agregador pequeño.

🗣️ **2 minutos** — Un servicio de pedidos con varios casos de uso, mensajería y pruebas se beneficia de
la estructura y de la inyección: evita que cada desarrollador organice a su manera. Un BFF que compone
cuatro llamadas y adapta la respuesta no necesita ese aparato y se lee mejor sin él.

🔬 **El detalle** — El criterio de fondo no es el tamaño actual sino el crecimiento esperado y la
rotación del equipo: cuanta más gente distinta vaya a tocarlo, más valen las convenciones impuestas
por el marco.

**03 → 18. ¿Cómo implementarías el outbox aquí, sabiendo que no hay nada hecho? 🟠**

⏱️ **30 segundos** — Tabla de outbox escrita en la misma transacción que el cambio, y un publicador
propio con reclamación exclusiva de filas.

🗣️ **2 minutos** — La transacción la da el cliente de base de datos; la tabla es igual que en cualquier
plataforma. El publicador se escribe como un proceso que consulta pendientes, publica y marca, con
bloqueo que permita varias instancias. Y hay que añadir métricas y limpieza, que es lo que se olvida.

🔬 **El detalle** — Conviene llevarlo al chassis desde el primer servicio que lo necesite, porque es
código que se va a repetir. Escrito tres veces por tres personas distintas, acaba con tres
comportamientos distintos ante el mismo fallo.

**03 → 19. Un equipo de Java va a escribir su primer servicio en NestJS. ¿Qué costumbres les advertirías? 🟠**

⏱️ **30 segundos** — Que no hay pool que los salve: cualquier cómputo en línea congela; y que los tipos
no validan nada en ejecución.

🗣️ **2 minutos** — Las costumbres importadas más peligrosas: hacer trabajo pesado dentro de la
petición asumiendo que hay hilos; confiar en las interfaces como si fueran validación; y esperar que
el marco resuelva transacciones y consumidores con la misma profundidad que en Java. También conviene
advertir que el estado en memoria se multiplica por proceso.

🔬 **El detalle** — Y una advertencia positiva: NestJS se parece lo suficiente a Spring como para que
se orienten en una tarde, lo que hace fácil subestimar las diferencias del runtime. La familiaridad
ayuda al principio y engaña después.

**03 → 20. ¿Cómo escalarías un servicio de Node que recibe picos de tráfico? 🟠**

⏱️ **30 segundos** — Horizontalmente, con más instancias; y verificando antes que nada bloquea el
bucle.

🗣️ **2 minutos** — Como el proceso es de un hilo, escalar significa más procesos o más instancias, lo
que la plataforma hace bien porque arrancan rápido. Antes conviene comprobar que el problema no es un
bloqueo: si lo es, añadir instancias reparte el problema sin resolverlo. Y hay que recordar que el
estado en memoria no se comparte entre instancias.

🔬 **El detalle** — El arranque rápido es aquí una ventaja real frente a Java: el escalado automático
llega a tiempo a picos cortos, lo que reduce la capacidad de reserva necesaria. Es uno de los pocos
sitios donde el eje de arranque cambia la decisión.

**03 → 21. Diseña el chassis de Node/TS del equipo: qué trae, qué obliga a declarar y qué prohíbe. 🔴**

⏱️ **30 segundos** — Trae logging, trazas, cliente HTTP y validación; obliga a declarar plazos y
esquemas; prohíbe cómputo pesado en línea y tipos sin validación.

🗣️ **2 minutos** — El chassis:

```text
Trae            logging estructurado con identificador de traza;
                OpenTelemetry con propagación, incluida inyección en el broker;
                cliente HTTP con pool, plazos y sin reintento por defecto;
                validación de entrada por esquema; health checks; apagado ordenado
Obliga a        declarar plazo por dependencia (falla al arrancar si falta);
                declarar esquema de entrada de cada endpoint
Prohíbe         cómputo pesado en el manejador (revisión y perfilado en CI);
                usar interfaces como validación de datos externos;
                estado compartido entre peticiones en variables de módulo
```

🔬 **El detalle** — La prohibición del estado en variables de módulo merece explicarse: en un runtime
de un hilo es tentador guardar cosas ahí, y funciona hasta que hay varias instancias o hasta que dos
peticiones concurrentes lo pisan. Es el equivalente local al problema del estado por proceso.

**03 → 22. Diseña un BFF para la web: estructura, composición, degradación, validación y observabilidad. 🔴**

⏱️ **30 segundos** — Composición en paralelo con degradación declarada, validación en ambos bordes, y
trazas que enlacen con los servicios de detrás.

🗣️ **2 minutos** — El diseño:

```text
Estructura      un módulo por pantalla o por área; sin capa de dominio
                (el dominio vive en los servicios)
Composición     llamadas en paralelo con recogida de resultados parciales;
                plazos cortos por dependencia, más corto aún en las opcionales
Degradación     tabla explícita: qué es imprescindible y qué se omite marcado;
                la respuesta indica qué falta
Validación      esquema de entrada desde el cliente; y validación de las
                respuestas de las dependencias en desarrollo
Observabilidad  traza que continúa la del borde y se propaga a los servicios;
                métricas por pantalla, no solo por endpoint
Contrato        propiedad del equipo de frontend; versionado propio, distinto
                del contrato interno de los servicios
```

🔬 **El detalle** — Las métricas por pantalla son la parte menos habitual y la más útil: permiten decir
"la pantalla de detalle de pedido está degradada" en vez de "el endpoint X tiene latencia alta", que
es el lenguaje que entiende producto.

**03 → 23. Diagnostica: el servicio va bien con 1 000 conexiones y se desploma con 5 000, sin que suba la CPU. Da tres hipótesis. 🔴**

⏱️ **30 segundos** — Límite de descriptores o de memoria por conexión, límites del sistema, o un
recurso por conexión que no se libera.

🗣️ **2 minutos** — Las tres:

```text
1. Memoria por conexión    cada conexión retiene búferes y estado propio;
                           con 5 000 se agota la memoria del proceso.
                           Se ve en memoria usada por conexión
2. Límites del sistema     descriptores de fichero o puertos efímeros agotados;
                           el síntoma son errores de aceptación de conexión,
                           no lentitud
3. Fuga por conexión       un temporizador o un suscriptor que no se limpia al
                           cerrar; crece con el número acumulado, no con el activo
```

La tercera se distingue porque el problema no desaparece al bajar el número de conexiones activas: la
memoria no vuelve.

🔬 **El detalle** — La causa 3 es muy frecuente en servicios de tiempo real y tiene una firma clara:
memoria que sube en escalones y nunca baja. El origen suele ser un temporizador de latido o una
suscripción al backplane que no se cancela al cerrar la conexión.

**03 → 24. Un equipo quiere escribir el servicio de pedidos —con saga y outbox— en Node/TS. Responde con lo que concedes y lo que adviertes. 🔴**

⏱️ **30 segundos** — Se puede, y hay que escribir a mano lo que en Java viene hecho: outbox,
publicador, máquina de estados y vencimientos.

🗣️ **2 minutos** — La respuesta:

```text
Se concede      · la plataforma no es el problema: la mecánica es la misma
                · si el equipo es de Node, la familiaridad vale mucho
                · para la parte de API y composición, encaja bien
Se advierte     · outbox y publicador: a mano, y hay que mantenerlos
                · saga: sin abstracciones maduras; máquina de estados propia
                  o motor de workflow externo
                · idempotencia y vencimientos: todo explícito
                · esas piezas deben ir al chassis desde el primer día, o
                  divergirán entre servicios
Condición       que el equipo acepte escribir y mantener esa mecánica, y que
                se escriba una vez, no una por servicio
```

🔬 **El detalle** — Vale la pena poner el coste en horas y no en adjetivos: outbox con publicador,
métricas y limpieza son del orden de días de trabajo, y la saga con vencimientos otros tantos. Con el
número delante, la decisión deja de ser una discusión de preferencias.

---

# 04 — Go

**04 → 1. ¿Qué lleva un `context.Context` y para qué sirve cada cosa? 🟢**

⏱️ **30 segundos** — Plazo, cancelación y valores: el deadline se propaga, la cancelación abandona el
trabajo inútil, y los valores llevan el contexto de traza.

🗣️ **2 minutos** — Es lo que hace que en Go funcione gratis lo que en otras plataformas hay que
construir: el presupuesto de latencia se compone solo porque cada llamada hereda lo que queda, y la
traza viaja sin mecanismos implícitos. A cambio hay que pasarlo por toda la cadena.

🔬 **El detalle** — El precio tiene una ventaja oculta: una función sin `context` se ve en la revisión
de código. En plataformas donde el contexto es implícito, perderlo no deja ningún rastro visible hasta
que faltan trazas.

**04 → 2. ¿Qué es una fuga de goroutines y cómo se reconoce? 🟢**

⏱️ **30 segundos** — Goroutines que nunca terminan porque esperan algo que no llega. Se reconoce por
memoria que sube en escalones y nunca baja.

🗣️ **2 minutos** — Ocurre cuando una goroutine espera en un canal sin escritor, o no comprueba la
cancelación del contexto. No hay error ni excepción: el proceso muere despacio, típicamente tras días.
La defensa es que toda goroutine tenga un camino de salida claro y vigilar su número como métrica.

🔬 **El detalle** — Cada goroutine bloqueada retiene además lo que su contexto referencie, así que la
fuga de memoria suele ser mucho mayor que el tamaño de la goroutine. Por eso el efecto se nota antes
de lo que cabría esperar por el número.

**04 → 3. ¿Cómo se manejan los errores en Go y qué implica? 🟢**

⏱️ **30 segundos** — Como valores devueltos que hay que comprobar: no hay excepciones ni manejador
global.

🗣️ **2 minutos** — Implica que el camino de fallo está junto a la llamada, que la clasificación del
error —conexión, timeout, negocio— se hace explícitamente, y que no hay una red de seguridad que
capture lo que se escapó. Es más verboso y más visible.

🔬 **El detalle** — Para la resiliencia esto es una ventaja: distinguir un fallo de conexión —seguro de
reintentar— de un timeout —que pudo ejecutarse— se hace comprobando el error, no atrapando tipos, y
queda escrito en el punto donde se decide.

**04 → 4. ¿Qué te da Go para gRPC? 🟢**

⏱️ **30 segundos** — Es su terreno: código generado idiomático y deadlines gratis a través del
`context`.

🗣️ **2 minutos** — gRPC nació en este ecosistema, así que el código generado se parece al que
escribirías a mano, la propagación de plazos sale del modelo del lenguaje y los interceptores encajan
de forma natural. Es la plataforma donde adoptar gRPC cuesta menos.

🔬 **El detalle** — Ese encaje es también un argumento de diseño: si el sistema es mayoritariamente Go
y los contratos son estables, la decisión de gRPC se inclina sola, mientras que en un sistema con
cuatro plataformas hay que mantener cuatro cadenas de generación.

**04 → 5. ¿Qué *no* trae por defecto el cliente HTTP de Go? 🟢**

⏱️ **30 segundos** — Timeout: un cliente sin configurar espera indefinidamente.

🗣️ **2 minutos** — Es el mismo fallo que en otras plataformas, con la diferencia de que aquí es
explícito y visible: no hay valor por defecto oculto, simplemente no hay nada. La forma idiomática es
poner el plazo en el `context` de cada llamada, lo que además lo propaga hacia abajo.

🔬 **El detalle** — También conviene configurar el `Transport`: tamaño del pool, conexiones ociosas y
tiempo de vida máximo, que es lo que gobierna el reequilibrio tras un escalado
([`04/01`](../04-operacion-y-resiliencia/01-descubrimiento-y-enrutamiento.md)).

**04 → 6. Nombra tres casos donde Go gana de verdad. 🟢**

⏱️ **30 segundos** — Servicios de infraestructura y agentes, alto volumen con poca lógica, y gRPC
entre servicios.

🗣️ **2 minutos** — El binario único con memoria baja y arranque inmediato hace que un sidecar o un
recolector cuesten una fracción de lo que costarían en otra plataforma. En servicios de alto volumen y
poca lógica, el trabajo del proceso sí es parte apreciable del total. Y el escalado agresivo se
beneficia del arranque.

🔬 **El detalle** — Donde peor encaja es en servicios con mucha mecánica transaccional —sagas largas,
outbox, lotes con reinicio— porque ahí el ecosistema de Java ahorra semanas. Reconocerlo es parte de
la respuesta completa.

**04 → 7. ¿Por qué olvidar el `context` rompe tres cosas a la vez? 🟡**

⏱️ **30 segundos** — Porque lleva plazo, cancelación y traza: sin él se pierden las tres.

🗣️ **2 minutos** — La llamada deja de tener límite de tiempo, deja de abandonarse cuando el cliente se
rinde, y su trabajo desaparece de la traza. Lo peor es que no hay error: todo funciona aparentemente,
y los síntomas —timeouts que no cortan, trazas incompletas, trabajo inútil— aparecen en sitios
distintos y no parecen relacionados.

🔬 **El detalle** — Por eso conviene tratar "toda función que haga E/S recibe `context` como primer
parámetro" como regla de revisión, no como convención. Es de las pocas reglas de estilo con
consecuencias operativas directas.

**04 → 8. ¿Cuál es la diferencia entre el `ctx` original y el que devuelve crear un span? 🟡**

⏱️ **30 segundos** — El nuevo contiene el span activo; si propagas el viejo, los hijos cuelgan del
lugar equivocado.

🗣️ **2 minutos** — Al iniciar un span se obtiene un contexto derivado que lo referencia. Si las
llamadas siguientes reciben el contexto anterior, sus spans se crean como hermanos en vez de hijos, y
la traza pierde la estructura. Es un error fácil de cometer y difícil de ver salvo mirando la forma
del árbol.

🔬 **El detalle** — El síntoma en la herramienta de trazas es característico: muchos spans colgando
directamente de la raíz, sin anidamiento, aunque el código sí llame en cascada. Cuando se ve eso, la
causa casi siempre es esta.

**04 → 9. ¿Por qué el trabajo en segundo plano no debe heredar el `context` de la petición tal cual? 🟡**

⏱️ **30 segundos** — Porque al responder la petición, su contexto se cancela y el trabajo en segundo
plano muere a medias.

🗣️ **2 minutos** — Lo que se quiere conservar es la traza, no la cancelación. La solución es derivar un
contexto que mantenga los valores pero tenga su propio plazo y su propia cancelación. Si no se hace,
aparecen fallos intermitentes: a veces el trabajo termina y a veces no, según quién gane la carrera.

🔬 **El detalle** — Es un fallo especialmente traicionero porque en desarrollo suele funcionar: con
poca carga, el trabajo en segundo plano termina antes de que se responda la petición. Solo falla bajo
carga real.

**04 → 10. ¿Por qué la ausencia de marcos es una decisión y no una carencia? 🟡**

⏱️ **30 segundos** — Porque el ecosistema prefiere librería estándar fuerte, dependencias contadas y
código explícito sobre magia.

🗣️ **2 minutos** — Hay servidor y cliente HTTP en la librería estándar, y librerías pequeñas para lo
demás. La consecuencia es más código de cableado y menos comportamiento implícito que depurar. Para
equipos que vienen de marcos con opinión, el cambio se vive como falta; para quien lleva tiempo, como
la razón de estar ahí.

🔬 **El detalle** — El coste real de esa decisión aparece en equipos grandes: sin convenciones
impuestas por un marco, cada servicio puede organizarse distinto. Por eso el chassis y la plantilla
son más importantes en Go que en otras plataformas, no menos.

**04 → 11. ¿Por qué escribir el SQL a mano se describe como una ventaja disfrazada? 🟡**

⏱️ **30 segundos** — Porque te obliga a ver exactamente qué consulta se ejecuta, que es donde están los
problemas de rendimiento.

🗣️ **2 minutos** — Los mapeadores generan consultas que a veces sorprenden: cargas perezosas, `N+1`,
combinaciones inesperadas. Con SQL explícito, lo que se ejecuta es lo que está escrito, y optimizar es
editar una consulta. A cambio hay que escribir más y mantener el mapeo a mano, aunque hay generación
de código tipado que ayuda.

🔬 **El detalle** — La generación de código a partir de las consultas es un punto intermedio muy
cómodo: escribes SQL y obtienes funciones tipadas, con lo que se conserva el control y se evita el
mapeo manual propenso a errores.

**04 → 12. ¿En qué se parecen las goroutines a los hilos virtuales de Java, y en qué no? 🟡**

⏱️ **30 segundos** — Se parecen en el modelo —escribir bloqueante y multiplexar sobre pocos hilos
reales—; se diferencian en que Go lo tiene desde el principio y todo el ecosistema lo asume.

🗣️ **2 minutos** — En ambos casos se puede tener un número enorme de tareas en espera con poco coste.
La diferencia práctica es de ecosistema: en Go todas las librerías están escritas con ese modelo en
mente, mientras que en Java conviven librerías pensadas para hilos de plataforma, con casos donde el
comportamiento no es el esperado.

🔬 **El detalle** — Y comparten el mismo efecto secundario: al dejar de ser escasos los hilos, el
recurso escaso pasa a ser lo de abajo —conexiones, capacidad del destino—. En ambas plataformas, el
límite de concurrencia por destino gana importancia.

**04 → 13. ¿Cuándo usarías una librería de inyección de dependencias en Go? 🟡**

⏱️ **30 segundos** — Cuando el grafo de dependencias en `main` se vuelve grande y repetitivo; casi
nunca antes.

🗣️ **2 minutos** — En la mayoría de los servicios, construir las dependencias a mano en el arranque es
explícito y suficiente. Cuando hay decenas de componentes y varias formas de montarlos —producción,
pruebas, herramientas—, una librería ahorra repetición. Pero introduce algo de la magia que el
ecosistema evita, y esa es la contrapartida.

🔬 **El detalle** — Un punto intermedio frecuente: funciones constructoras organizadas por paquete que
se componen en `main`. Mantiene todo explícito y elimina la mayor parte de la repetición, sin añadir
dependencias.

**04 → 14. Un equipo de Java empieza en Go. ¿Qué tres cosas les costarán más? 🟡**

⏱️ **30 segundos** — La ausencia de marco y de inyección, el manejo explícito de errores, y la
disciplina del `context`.

🗣️ **2 minutos** — Echarán de menos las anotaciones que configuran y el arranque automático; les
parecerá repetitivo comprobar cada error; y olvidarán pasar el `context`, con la consecuencia de
perder plazos y trazas. También les sorprenderá que no haya agente de instrumentación automática.

🔬 **El detalle** — La cuarta, menos técnica: la cultura de dependencias. En Go se prefiere copiar
veinte líneas antes que añadir una dependencia, lo que a un equipo acostumbrado a un ecosistema
enorme le parece regresivo hasta que ve el coste de mantener actualizadas cien dependencias
transitivas.

**04 → 15. Tu servicio en Go consume memoria creciente sin picos de tráfico. Diagnostica. 🟠**

⏱️ **30 segundos** — Fuga de goroutines o de recursos por petición: memoria que sube en escalones y no
baja.

🗣️ **2 minutos** — Se confirma mirando el número de goroutines: si crece de forma sostenida, hay
goroutines que no terminan. Las causas típicas son trabajo en segundo plano sin cancelación, canales
sin consumidor, o cuerpos de respuesta HTTP que no se cierran. El perfilado del proceso muestra
exactamente dónde están bloqueadas.

🔬 **El detalle** — El cuerpo de respuesta sin cerrar es de los fallos más comunes y menos evidentes:
mantiene la conexión ocupada y retiene memoria. Conviene que la revisión de código lo mire
explícitamente, porque el compilador no ayuda.

**04 → 16. ¿Cómo implementarías resiliencia completa en un cliente de Go? 🟠**

⏱️ **30 segundos** — Plazo por `context`, circuit breaker envolviendo la llamada, reintento con jitter
solo para lo seguro, y límite de concurrencia por destino.

🗣️ **2 minutos** — El plazo va en cada llamada y se propaga; el circuit breaker es una struct compartida
por destino; el reintento se escribe con espera exponencial y aleatoriedad, comprobando el tipo de
error; y el límite de concurrencia se consigue con un semáforo. Y todo ello con métricas, que también
hay que añadir.

🔬 **El detalle** — Conviene envolverlo una vez en el chassis y exponerlo como un cliente ya
configurado: escrito servicio a servicio, cada equipo elige umbrales distintos y las métricas dejan de
ser comparables entre servicios.

**04 → 17. ¿Qué pondrías en el chassis de Go del equipo? 🟠**

⏱️ **30 segundos** — Cliente HTTP configurado, logging estructurado con traza, instrumentación,
health checks, apagado ordenado y el esqueleto de arranque.

🗣️ **2 minutos** — En Go el chassis importa más que en otras plataformas precisamente porque el marco
no impone nada: sin él, cada servicio inventa su estructura, su formato de log y sus plazos. Conviene
que sea una librería pequeña más una plantilla de repositorio, y que la plantilla incluya el `main`
completo de ejemplo.

🔬 **El detalle** — La tentación a evitar es que el chassis crezca hasta ser un marco propio, que es
justo lo que el ecosistema evita. La regla: si empieza a imponer cómo se escribe la lógica de negocio
y no solo lo transversal, se ha pasado.

**04 → 18. ¿Cómo instrumentarías un servicio de Go, sabiendo que no hay agente automático? 🟠**

⏱️ **30 segundos** — Con el SDK y middlewares en el servidor y en los clientes, y spans explícitos en
las operaciones propias caras.

🗣️ **2 minutos** — Los middlewares cubren entrada y salida HTTP y gRPC con poco trabajo. Lo que hay
que añadir a mano son los spans de operaciones internas relevantes —consultas, cálculos, publicaciones
a colas— y la inyección del contexto en los mensajes. Todo eso va al chassis para que no dependa de
cada servicio.

🔬 **El detalle** — La instrumentación explícita tiene una ventaja que compensa el trabajo: como
decides qué instrumentar, hay menos ruido y los spans significan algo. Las trazas automáticas suelen
llenar el árbol de tramos irrelevantes que esconden el que importa.

**04 → 19. ¿Qué servicios de tu sistema pasarías a Go y cuáles no? 🟠**

⏱️ **30 segundos** — Pasaría agentes, sidecars y servicios de alto volumen con poca lógica; no pasaría
los de dominio con sagas y lotes.

🗣️ **2 minutos** — El criterio es el perfil: donde manda el arranque, la memoria y el tamaño del
binario, Go gana claramente; donde manda la mecánica transaccional y el ecosistema, pierde. Y hay que
sumar el coste de introducir una plataforma más si no existe ya en la casa.

🔬 **El detalle** — Un caso intermedio interesante: los servicios de borde muy sencillos —validadores,
proxies, agregadores de caché— donde el volumen es alto y la lógica mínima. Suelen ser los mejores
candidatos para introducir Go en una casa de Java, porque el riesgo es bajo y el beneficio visible.

**04 → 20. ¿Cómo evitas que cada servicio de Go acabe con su propia forma de hacer lo mismo? 🟠**

⏱️ **30 segundos** — Con plantilla de repositorio y un chassis pequeño, y con revisión que los use como
referencia.

🗣️ **2 minutos** — Como el marco no impone estructura, la convención tiene que venir del equipo: una
plantilla con el `main`, la estructura de paquetes y las pruebas base; y una librería con lo
transversal. Sin eso, tres servicios escritos por tres personas tienen tres formas de configurar,
registrar y apagar.

🔬 **El detalle** — Ayuda mucho tener un servicio de referencia mantenido de verdad, no solo una
plantilla: cuando alguien duda, mira cómo está hecho allí. Una plantilla se copia una vez y diverge;
un servicio vivo se actualiza y sirve de ejemplo real.

**04 → 21. Diseña el esqueleto de un servicio de Go: estructura, arranque, apagado, dependencias y pruebas. 🔴**

⏱️ **30 segundos** — Paquetes por responsabilidad, `main` que monta todo explícitamente, apagado por
señal con `context`, y pruebas con servidor de prueba y contenedores efímeros.

🗣️ **2 minutos** — El esqueleto:

```text
cmd/servicio/main.go     monta dependencias, arranca servidor, gestiona señales
internal/dominio         entidades y reglas; sin dependencias externas
internal/app             casos de uso; recibe interfaces
internal/adaptadores     http, grpc, base de datos, broker
internal/plataforma      chassis: logging, trazas, cliente HTTP, health

Arranque   construir dependencias → arrancar servidor en goroutine →
           esperar señal → apagado ordenado con context y plazo
Apagado    readiness=false → margen → Shutdown del servidor →
           cerrar consumidor, pool y exportador
Pruebas    unitarias del dominio; de componente con contenedores efímeros;
           servidor de prueba de la librería estándar para los adaptadores HTTP
```

🔬 **El detalle** — Que `internal/dominio` no importe nada externo es la regla que más valor aporta y
la más fácil de verificar automáticamente: basta con comprobar los imports de ese paquete en el
pipeline.

**04 → 22. Diseña la implementación de outbox en Go: tabla, publicador, concurrencia, métricas y limpieza. 🔴**

⏱️ **30 segundos** — Tabla escrita en la misma transacción, publicador con reclamación exclusiva de
filas, métricas de pendientes y limpieza periódica.

🗣️ **2 minutos** — El diseño:

```text
Escritura     en la misma transacción que el cambio de negocio, con el cliente
              de base de datos; nada de publicar al broker aquí
Publicador    goroutine con ticker: consulta pendientes con bloqueo que salta
              las filas ya reclamadas, publica, marca publicado en la misma
              transacción de lectura
Concurrencia  varias instancias posibles gracias al bloqueo con salto;
              orden preservado por agregado
Cancelación   el bucle escucha el context del apagado y termina limpio
Métricas      pendientes, antigüedad del más viejo, publicados por segundo, fallos
Limpieza      segunda goroutine con ticker lento: borra publicados antiguos por lotes
```

🔬 **El detalle** — En Go conviene que ambas goroutines —publicador y limpieza— se lancen desde el
`main` con un `context` propio y se esperen al apagar. Lanzarlas y olvidarlas es exactamente el patrón
que produce la fuga de la autopsia del capítulo.

**04 → 23. Diagnostica: un servicio de Go responde bien pero su latencia p99 tiene picos periódicos. Da tres hipótesis. 🔴**

⏱️ **30 segundos** — Pausas del recolector de basura, contención por un bloqueo compartido, o
reconexiones periódicas por caducidad de conexiones.

🗣️ **2 minutos** — Las tres:

```text
1. Recolector de basura   picos regulares que coinciden con ciclos de memoria;
                          típico con muchas asignaciones por petición.
                          Se ve en las métricas de tiempo de pausa
2. Contención             un mutex compartido —caché, mapa global— serializa
                          peticiones; el p99 sube con la concurrencia
                          aunque la CPU no esté al máximo
3. Reconexiones           caducidad de conexiones sin jitter: todas caducan a la
                          vez y pagan conexión y TLS simultáneamente
```

El perfilado del proceso distingue las tres en minutos: pausas, bloqueos y tiempo en red aparecen por
separado.

🔬 **El detalle** — La tercera es la más fácil de arreglar y la que más se repite en sistemas que
configuraron bien la caducidad pero sin aleatoriedad. Añadir jitter convierte un pico periódico en
ruido de fondo.

**04 → 24. Un equipo propone reescribir en Go un servicio de dominio con sagas que hoy está en Java. Responde. 🔴**

⏱️ **30 segundos** — Es el peor caso para Go: la mecánica transaccional habría que escribirla entera, y
el beneficio operativo es pequeño en un servicio así.

🗣️ **2 minutos** — La respuesta:

```text
Se concede      · Go reduciría memoria, arranque y tamaño de imagen
                · si el equipo es de Go, la familiaridad cuenta
Se advierte     · outbox, máquina de estados, vencimientos y reintentos:
                  todo a mano, semanas de trabajo que hoy están resueltas
                · el ecosistema de lotes y de BPM no tiene equivalente
                · un servicio de dominio tiene tráfico moderado: el ahorro
                  operativo es marginal frente al coste de reescritura
Alternativa     si el problema es el consumo, ajustar memoria o evaluar
                compilación nativa antes de reescribir
Cuándo sí       si ese servicio fuera de alto volumen y poca lógica,
                el cálculo cambiaría por completo
```

🔬 **El detalle** — Conviene preguntar qué problema se quiere resolver antes de discutir la plataforma:
si es coste de infraestructura, hay opciones más baratas; si es que el equipo no quiere mantener Java,
esa es una conversación legítima pero distinta, y conviene tenerla explícitamente.

---

# 05 — Python

**05 → 1. ¿Qué diferencia hay entre WSGI y ASGI? 🟢**

⏱️ **30 segundos** — WSGI es síncrono: cada petición ocupa un trabajador mientras dura. ASGI es
asíncrono: un bucle de eventos por proceso.

🗣️ **2 minutos** — Con WSGI, la concurrencia se consigue con más procesos o hilos, y cada petición en
espera retiene un trabajador. Con ASGI, una petición en espera cuesta casi nada, como en Node. La
consecuencia es que ASGI aguanta muchísima más concurrencia de espera con los mismos recursos.

🔬 **El detalle** — Los dos modelos conviven en el ecosistema, y esa convivencia es la fuente del fallo
principal de la plataforma: llamar a una librería síncrona desde un manejador asíncrono, que congela el
bucle entero.

**05 → 2. ¿Qué impide y qué no impide el bloqueo global del intérprete? 🟢**

⏱️ **30 segundos** — Impide que dos hilos ejecuten código Python a la vez; no impide la concurrencia de
espera ni el paralelismo entre procesos.

🗣️ **2 minutos** — Durante una espera de red o de base de datos, el bloqueo se libera, así que la
concurrencia de entrada y salida funciona bien. Donde sí pega es en cómputo puro en Python: los hilos
no dan paralelismo real y hay que repartir en procesos. Y las librerías nativas suelen liberarlo
durante el cálculo.

🔬 **El detalle** — Por eso el tópico "el GIL impide la concurrencia" es impreciso: impide el
paralelismo de CPU en hilos, que es otra cosa. En un servicio donde el 95 % del tiempo es espera, casi
no aparece.

**05 → 3. ¿Cuál es el fallo característico de un servicio asíncrono en Python? 🟢**

⏱️ **30 segundos** — Llamar a algo bloqueante dentro de un manejador asíncrono: congela el bucle y con
él todas las peticiones del proceso.

🗣️ **2 minutos** — Un cliente HTTP síncrono, un controlador de base de datos no asíncrono, una lectura
de fichero. El código funciona y responde bien con poca carga; con concurrencia se desploma sin
errores. Es exactamente el fallo de Node, y aquí es más fácil colarlo porque casi todas las librerías
tienen versión síncrona.

🔬 **El detalle** — La salida es usar clientes asíncronos de punta a punta o ejecutar explícitamente lo
bloqueante en un hilo aparte. Los marcos modernos ofrecen esa segunda opción, y conviene conocerla
porque a veces no hay versión asíncrona de la librería que necesitas.

**05 → 4. ¿Qué aporta la validación por esquemas frente a los tipos de TypeScript? 🟢**

⏱️ **30 segundos** — Que valida **en ejecución**: comprueba de verdad los datos que llegan, no solo lo
que el compilador cree.

🗣️ **2 minutos** — El mismo modelo sirve para validar la entrada, documentar el contrato y dar ayuda en
el editor. Eso cubre de serie lo que en TypeScript hay que añadir aparte, y es de lo mejor que tiene
esta plataforma para microservicios.

🔬 **El detalle** — El riesgo es el inverso: que el modelo del código se convierta en la fuente de
verdad del contrato y se publique lo que haya, incluidos campos internos. El contrato debería
escribirse y el modelo derivarse de él, no al revés.

**05 → 5. ¿Para qué tipo de servicio es FastAPI el caso por defecto? 🟢**

⏱️ **30 segundos** — Para APIs y microservicios: es ASGI, valida por esquemas y genera la
documentación del propio código.

🗣️ **2 minutos** — Django encaja mejor en productos completos con panel de administración y mucho
CRUD; Flask sobrevive sobre todo donde ya está. Para un servicio que expone una API y habla con otros
servicios, FastAPI cubre el borde con menos piezas.

🔬 **El detalle** — El punto a vigilar es que el ecosistema asíncrono sigue siendo desigual: hay
librerías sin versión asíncrona madura, y ahí toca decidir entre esperar, envolver en hilos o cambiar
de librería. Conviene comprobarlo al elegir dependencias, no después.

**05 → 6. Nombra dos casos donde Python gana de verdad. 🟢**

⏱️ **30 segundos** — Servicios de datos y de modelos, y trabajo en segundo plano o planificado.

🗣️ **2 minutos** — En datos, todo el ecosistema está aquí y reescribirlo en otra plataforma significa
perderlo; es el argumento de poliglotismo más claro después del BFF. En trabajo en segundo plano, las
colas de tareas llevan más de una década resolviendo reintentos, planificación y resultados.

🔬 **El detalle** — Un tercer caso menos glamuroso y muy real: servicios que ya están en Python y
funcionan. El coste de migrar rara vez se paga, y proponerlo sin un motivo concreto suele ser una
mala señal en una entrevista de Tech Lead.

**05 → 7. ¿Por qué hay que revisar siempre las migraciones generadas? 🟢**

⏱️ **30 segundos** — Porque la generación automática de diferencias no distingue un renombrado de un
borrado más una creación.

🗣️ **2 minutos** — La herramienta compara el modelo con la base y ve una columna que desapareció y otra
nueva. Aplicar eso borra los datos. También puede proponer cambios de tipo o restricciones que
bloqueen tablas grandes. La generación ahorra escribir; no ahorra pensar.

🔬 **El detalle** — Es exactamente el mismo problema que en el ecosistema de Node con sus herramientas
declarativas, y la solución también: leer el SQL generado antes de aprobarlo, y escribir a mano los
renombrados en varios pasos.

**05 → 8. ¿Por qué el bloqueo global casi no afecta a un servicio de espera? 🟡**

⏱️ **30 segundos** — Porque se libera mientras se espera a la red o a la base de datos.

🗣️ **2 minutos** — Durante una operación de entrada y salida, el intérprete suelta el bloqueo y otros
hilos —o el bucle asíncrono— pueden avanzar. Como en un servicio típico eso es el 95 % del tiempo, el
efecto práctico es pequeño. El problema aparece con cómputo puro sostenido, que es otro perfil.

🔬 **El detalle** — Por eso el modelo de despliegue habitual —varios procesos trabajadores— funciona
bien: da paralelismo real para el poco cómputo que haya y multiplica la capacidad de espera. La
contrapartida es que el estado en memoria se multiplica por proceso.

**05 → 9. ¿Por qué las librerías numéricas escapan al bloqueo global? 🟡**

⏱️ **30 segundos** — Porque el cálculo ocurre en código nativo que libera el bloqueo mientras se
ejecuta.

🗣️ **2 minutos** — La operación entra en código compilado, suelta el bloqueo, calcula y lo recupera al
volver. Eso permite paralelismo real en el trabajo pesado, que es justo lo que hace viable a Python en
ciencia de datos. Es la excepción que desmonta el argumento simplista contra la plataforma.

🔬 **El detalle** — Conocer esta excepción evita descartar la opción correcta por un tópico: para un
servicio de cálculo numérico, Python con librerías nativas puede rendir mejor que una implementación
ingenua en otra plataforma.

**05 → 10. ¿Por qué mezclar código bloqueante en un manejador asíncrono es tan difícil de detectar? 🟡**

⏱️ **30 segundos** — Porque no da error y funciona bien con poca carga: solo se manifiesta con
concurrencia.

🗣️ **2 minutos** — En desarrollo y en pruebas, con una petición cada vez, el bloqueo es invisible. En
producción, con concurrencia, la latencia se dispara en todas las rutas a la vez sin que ninguna
dependencia falle. Y como el código parece correcto, la investigación suele empezar por el sitio
equivocado.

🔬 **El detalle** — Ayuda mucho una prueba de carga mínima antes de producción y una comprobación
automática que detecte llamadas bloqueantes conocidas dentro de manejadores asíncronos. Algunas
herramientas de análisis lo marcan, y merece la pena activarlas.

**05 → 11. ¿Por qué el estado de un circuit breaker se multiplica en esta plataforma? 🟡**

⏱️ **30 segundos** — Porque el despliegue típico son varios procesos trabajadores por instancia, y cada
proceso tiene su propio estado.

🗣️ **2 minutos** — Con cuatro procesos por instancia y tres instancias hay doce circuit breakers
independientes, cada uno decidiendo con el tráfico que ve. El comportamiento agregado es más gradual,
lo que no es malo, pero hace el diagnóstico confuso: el mismo servicio falla rápido por unos
trabajadores y no por otros.

🔬 **El detalle** — Lo mismo ocurre con cualquier caché en memoria: la tasa de aciertos se reparte y el
comportamiento es peor de lo que sugeriría un cálculo con un solo proceso. Conviene tenerlo en cuenta
al dimensionar.

**05 → 12. ¿Por qué el empaquetado es el punto débil menos discutido? 🟡**

⏱️ **30 segundos** — Porque las dependencias nativas obligan a compilar, engordan la imagen y
complican la reproducibilidad.

🗣️ **2 minutos** — Una imagen de Python puede pasar de rápida a lenta de construir según la base
elegida y las dependencias: si hay que compilar extensiones, el pipeline se alarga mucho. Y
reproducir exactamente el mismo entorno exige disciplina con el bloqueo de versiones, incluidas las
transitivas.

🔬 **El detalle** — La construcción en varias etapas resuelve buena parte: compilar en una imagen con
herramientas y copiar solo el resultado a una base ligera. Es una decisión que conviene tomar al
empezar el servicio, porque rehacerla después es más incómodo de lo que parece.

**05 → 13. Te dicen que Python no sirve para un servicio con mucho tráfico. Responde. 🟡**

⏱️ **30 segundos** — Depende del perfil: para tráfico de espera funciona bien con ASGI y varios
procesos; para cómputo puro, hay que repartir o cambiar de plataforma.

🗣️ **2 minutos** — El argumento completo: el 95 % del tiempo de un servicio típico es espera, y ahí el
modelo asíncrono rinde. Hay sistemas de mucho tráfico en producción con esta plataforma. Lo que sí hay
que aceptar es más consumo por petición que Go y un empaquetado más delicado, y decidir si eso importa
en el caso concreto.

🔬 **El detalle** — Conviene devolver la pregunta al caso: ¿cuánto de ese tráfico es cómputo? Si la
respuesta es "casi nada", la objeción se disuelve sola; si es "mucho", entonces tienen razón y la
conversación cambia de tema.

**05 → 14. Tu servicio responde bien con poca carga y se desploma con concurrencia, sin errores. Diagnostica. 🟠**

⏱️ **30 segundos** — Casi seguro, código bloqueante dentro del modelo asíncrono.

🗣️ **2 minutos** — Se confirma mirando si la latencia sube en todas las rutas a la vez y si la CPU de
un proceso está alta mientras las peticiones se acumulan. Después se busca la llamada bloqueante:
cliente HTTP síncrono, controlador de base de datos no asíncrono, lectura de fichero o criptografía.
La corrección es usar la versión asíncrona o ejecutarla en un hilo aparte.

🔬 **El detalle** — Si no aparece ninguna llamada obviamente bloqueante, conviene mirar el número de
procesos trabajadores: un despliegue con un solo trabajador tiene el mismo síntoma por saturación
simple, y la corrección es otra.

**05 → 15. ¿Cómo ejecutarías una operación bloqueante inevitable dentro de un servicio asíncrono? 🟠**

⏱️ **30 segundos** — Delegándola a un hilo aparte con el mecanismo del marco, para no retener el bucle.

🗣️ **2 minutos** — Los marcos modernos ofrecen una forma explícita de ejecutar funciones bloqueantes en
un pool de hilos, de modo que el bucle sigue atendiendo. Hay que dimensionar ese pool y ser consciente
de que el bloqueo global limitará el paralelismo si la operación es de CPU pura; si lo es, la salida
correcta es otro proceso o incluso otro servicio.

🔬 **El detalle** — Conviene medir el tiempo de esas operaciones: si tardan decenas de milisegundos,
delegarlas basta; si tardan segundos, el pool se satura y el problema vuelve con otra cara. La
frontera entre "delegar" y "sacar fuera" es de duración, no de estilo.

**05 → 16. ¿Cómo implementarías el outbox aquí y qué vigilarías? 🟠**

⏱️ **30 segundos** — Tabla escrita en la misma transacción del ORM y un publicador como tarea
periódica, vigilando que no se solape consigo mismo.

🗣️ **2 minutos** — La escritura es directa con el ORM. El publicador suele implementarse como tarea
programada de la cola de tareas, y ahí está el riesgo: si una ejecución tarda más que el intervalo, se
solapan y publican lo mismo dos veces. Se resuelve con reclamación exclusiva de filas o con bloqueo de
ejecución única.

🔬 **El detalle** — Como el consumidor es idempotente, un duplicado no rompe nada, pero sí ensucia
métricas y multiplica trabajo. Y hay que añadir la limpieza de la tabla, que en ninguna plataforma
viene incluida.

**05 → 17. ¿Cuándo elegirías Django para un servicio, y cuándo sería un error? 🟠**

⏱️ **30 segundos** — Para un producto con panel de administración, usuarios y mucho CRUD; sería un
error para un microservicio pequeño que solo expone una API.

🗣️ **2 minutos** — Django trae ORM, migraciones, autenticación y panel, y eso ahorra semanas en un
producto. En un servicio pequeño, la mayor parte de eso sobra y se paga en peso y en un modelo
síncrono de origen. La pregunta que decide es cuánto de lo que trae vas a usar.

🔬 **El detalle** — Hay un caso intermedio legítimo: un servicio interno de administración que
acompaña a un sistema de microservicios. Ahí el panel de Django es exactamente lo que se necesita y
nadie tiene que escribirlo.

**05 → 18. ¿Qué revisarías en el empaquetado de un servicio de Python antes de producción? 🟠**

⏱️ **30 segundos** — Fichero de bloqueo con versiones exactas, construcción en varias etapas, imagen
base adecuada y ausencia de herramientas de compilación en la imagen final.

🗣️ **2 minutos** — El bloqueo de versiones incluye las transitivas, o la reproducibilidad es ilusoria.
La construcción en varias etapas evita arrastrar compiladores. Y la imagen base condiciona si las
dependencias vienen precompiladas o hay que compilarlas, que es la diferencia entre dos minutos y
quince de pipeline.

🔬 **El detalle** — Conviene además fijar la versión del intérprete de forma explícita: un cambio de
versión menor de la imagen base puede cambiar el comportamiento de dependencias nativas, y es un fallo
que aparece sin que nadie haya tocado el código.

**05 → 19. ¿Cómo garantizarías que el contrato es la fuente de verdad y no el modelo del código? 🟠**

⏱️ **30 segundos** — Escribiendo el contrato primero y generando o validando el modelo contra él en el
pipeline.

🗣️ **2 minutos** — La comodidad de generar la documentación desde el modelo lleva a publicar lo que
haya, incluidos campos internos, y a que un refactor cambie el contrato sin que nadie lo decida. La
alternativa es mantener el contrato como artefacto y comprobar en CI que el modelo sigue siendo
compatible con él.

🔬 **El detalle** — El punto intermedio práctico: seguir generando el esquema del código, pero
compararlo en CI con la versión publicada y fallar si hay cambios incompatibles. Conserva la comodidad
y elimina el riesgo de la ruptura accidental.

**05 → 20. ¿Qué servicios de tu sistema dejarías en Python y cuáles no? 🟠**

⏱️ **30 segundos** — Dejaría los de datos y modelos y el trabajo en segundo plano; no pondría los de
dominio con mucha mecánica transaccional.

🗣️ **2 minutos** — El criterio es dónde está el ecosistema: para datos y modelos, aquí; para sagas,
outbox y lotes con reinicio, el ecosistema de Java ahorra más. Y hay que contar el coste de mantener
la plataforma: si Python ya está en la casa por los servicios de datos, añadir uno más es barato.

🔬 **El detalle** — Conviene evitar el error simétrico: reescribir en Java un servicio de datos que
funciona, perdiendo el ecosistema que lo justificaba. La uniformidad tiene valor, pero no cuando
destruye la razón por la que ese servicio estaba donde estaba.

**05 → 21. Diseña el chassis de Python del equipo: qué trae, qué obliga y qué prohíbe. 🔴**

⏱️ **30 segundos** — Trae logging, trazas, cliente asíncrono con plazos y validación; obliga a declarar
plazos y esquemas; prohíbe llamadas bloqueantes en manejadores asíncronos.

🗣️ **2 minutos** — El chassis:

```text
Trae            configuración tipada con validación al arrancar;
                logging estructurado con identificador de traza;
                OpenTelemetry con propagación, incluida la inyección en el broker;
                cliente HTTP asíncrono con plazos y sin reintento por defecto;
                health checks y ciclo de vida de arranque y apagado
Obliga a        declarar plazo por dependencia (falla al arrancar si falta);
                declarar el esquema de entrada de cada endpoint;
                fijar versiones exactas en el fichero de bloqueo
Prohíbe         clientes bloqueantes dentro de manejadores asíncronos
                (comprobación automática en CI);
                publicar el esquema del modelo como contrato sin revisión;
                migraciones generadas sin revisar
```

🔬 **El detalle** — La comprobación automática de llamadas bloqueantes es la pieza que más incidentes
evita en esta plataforma, y es fácil de montar con las herramientas de análisis habituales. Sin ella,
la prohibición depende de que alguien se acuerde en la revisión.

**05 → 22. Diseña un servicio de datos que expone API y ejecuta trabajo pesado en segundo plano, con su modelo de ejecución y su despliegue. 🔴**

⏱️ **30 segundos** — API asíncrona ligera, trabajo pesado en trabajadores de cola separados, y
despliegue independiente de ambos.

🗣️ **2 minutos** — El diseño:

```text
API (ASGI)       recibe, valida con esquema, encola el trabajo y responde 202
                 con un recurso de estado consultable
Cola de tareas   trabajadores separados, con su propia escala y sus reintentos;
                 el trabajo pesado NUNCA en el proceso de la API
Trabajadores     procesos independientes; número dimensionado por CPU real,
                 porque aquí sí hay cómputo
Estado           en base de datos, no en memoria: los trabajadores son efímeros
Despliegue       API y trabajadores se despliegan por separado: perfiles de
                 recursos distintos y escalado independiente
Observabilidad   contexto de traza propagado en el mensaje de la tarea,
                 para que el trabajo aparezca en la traza de la petición
```

🔬 **El detalle** — Separar el despliegue de API y trabajadores es lo que hace que este diseño funcione
de verdad: tienen perfiles de recursos opuestos —la API necesita concurrencia, los trabajadores
CPU— y mezclarlos en el mismo proceso obliga a dimensionar para el peor de los dos.

**05 → 23. Diagnostica: un servicio con cuatro procesos trabajadores muestra comportamiento inconsistente de su circuit breaker y de su caché. Explica y corrige. 🔴**

⏱️ **30 segundos** — Cada proceso tiene su propio estado en memoria: cuatro circuit breakers y cuatro
cachés independientes.

🗣️ **2 minutos** — El análisis y las opciones:

```text
Causa      el estado en memoria no se comparte entre procesos;
           cada trabajador decide con el tráfico que él ve
Síntomas   el circuito abre en unos trabajadores y no en otros;
           la tasa de aciertos de caché es menor de lo esperado;
           dos peticiones idénticas dan comportamientos distintos
Opciones   1. aceptar y documentar: el efecto agregado es gradual y
              suele ser aceptable; ajustar umbrales contando con ello
           2. estado compartido en un almacén externo para la caché,
              a costa de una dependencia en el camino
           3. reducir el número de procesos y compensar con instancias,
              si el reparto lo permite
Recomendación  aceptar para el circuit breaker, compartir para la caché
               si la tasa de aciertos importa
```

🔬 **El detalle** — El mismo fenómeno existe en las otras plataformas entre instancias; lo específico
de Python es que también ocurre **dentro** de la misma instancia. Saberlo evita diagnósticos erróneos
del tipo "el circuit breaker está mal configurado".

**05 → 24. Un equipo quiere escribir el servicio de pedidos en Python porque es lo que domina. Responde con lo que concedes y lo que adviertes. 🔴**

⏱️ **30 segundos** — El equipo que lo domina es un argumento de peso; lo que hay que advertir es qué
mecánica tendrán que escribir y mantener.

🗣️ **2 minutos** — La respuesta:

```text
Se concede    · el equipo que lo mantiene es el criterio que más pesa
              · la validación por esquemas cubre muy bien el borde
              · la cola de tareas resuelve el trabajo en segundo plano
Se advierte   · outbox y publicador: a mano, con el riesgo del solapamiento
              · saga: máquina de estados propia o motor externo
              · el modelo de ejecución: nada bloqueante en los manejadores,
                verificado automáticamente
              · estado por proceso trabajador: afecta a circuit breaker y cachés
              · empaquetado: bloqueo de versiones y construcción en varias etapas
Condición     que esa mecánica se escriba una vez en el chassis, no por servicio
```

🔬 **El detalle** — Conviene poner el coste en tiempo y no en adjetivos: outbox con publicador y
limpieza, más una saga con vencimientos, son del orden de días de trabajo. Con el número delante, el
equipo puede decidir con información en vez de defender una preferencia.

---

# 06 — La matriz de decisión

**06 → 1. ¿Cuáles son los criterios de decisión, en orden? 🟢**

⏱️ **30 segundos** — Quién lo mantiene; qué le da la plataforma para sus patrones; si sabemos
operarlo; el perfil de carga; contratación; si ya existe en la casa; y al final, rendimiento.

🗣️ **2 minutos** — El orden importa más que la lista, porque lo que decide está arriba. El criterio de
"¿ya existe en la casa?" es el que más resultados cambia: un servicio que en aislamiento estaría mejor
en otra plataforma puede no compensar si sería el único de esa plataforma.

🔬 **El detalle** — El rendimiento bruto está al final a propósito, no por desprecio: en un servicio
donde el 95 % del tiempo es espera, no discrimina. Sube de puesto solo cuando hay cómputo real de por
medio.

**06 → 2. Nombra los tres casos de poliglotismo preaprobados y su argumento. 🟢**

⏱️ **30 segundos** — BFF en Node/TS por propiedad; servicios de datos en Python por ecosistema;
sidecars y agentes en Go por perfil.

🗣️ **2 minutos** — Los tres argumentos son de distinta naturaleza y por eso funcionan: el BFF lo
mantiene el equipo de la experiencia; el servicio de datos perdería su ecosistema si se reescribiera;
y el agente se beneficia de binario pequeño y arranque inmediato. Si un argumento no cae en una de
esas tres categorías, probablemente es preferencia.

🔬 **El detalle** — Tenerlos preaprobados por escrito evita rediscutirlos en cada servicio y, sobre
todo, evita que se usen como precedente para excepciones que no se parecen. "Como el BFF está en
Node, mi servicio de dominio también" es exactamente lo que la política previene.

**06 → 3. Enumera lo que cuesta añadir una plataforma. 🟢**

⏱️ **30 segundos** — Chassis, plantilla y pipeline, imagen base con su escaneo y actualizaciones,
paneles y alertas, conocimiento operativo, y capacidad de rotación.

🗣️ **2 minutos** — Es un coste fijo y recurrente, no una inversión inicial: las imágenes base se
actualizan, las vulnerabilidades aparecen, los paneles hay que mantenerlos equivalentes, y alguien
tiene que poder diagnosticar de madrugada. Por eso el coste se subestima siempre: se piensa en
aprender el lenguaje y no en sostener la plataforma.

🔬 **El detalle** — El coste que más duele a medio plazo es el de rotación: si solo una persona puede
tocar esos servicios, cualquier ausencia los convierte en intocables, y la deuda se paga en velocidad
de todo el equipo.

**06 → 4. ¿Cuáles son las cuatro partes de la política de plataformas? 🟢**

⏱️ **30 segundos** — Lista de plataformas soportadas con dueño, requisito de entrada, excepciones
preaprobadas y criterio de salida.

🗣️ **2 minutos** — La lista corta con dueño del chassis evita el "cada uno lo suyo". El requisito de
entrada —chassis, plantilla, pipeline, paneles y dos personas— hace la decisión objetiva. Las
excepciones preaprobadas evitan rediscutir los tres casos claros. Y el criterio de salida es el que
casi nadie escribe y el que evita acumular plataformas muertas.

🔬 **El detalle** — Lo que hace útil a una política no es su contenido sino que elimine decisiones: si
cada caso sigue requiriendo una discusión larga, la política no está haciendo su trabajo y conviene
concretarla más.

**06 → 5. ¿Por qué se exige que dos personas sepan operar una plataforma? 🟢**

⏱️ **30 segundos** — Porque con una sola, el servicio es intocable en cuanto esa persona no está.

🗣️ **2 minutos** — Es la prueba más barata de sostenibilidad: vacaciones, bajas y cambios de equipo son
normales, y un servicio que solo una persona puede desplegar y diagnosticar acaba siendo un punto
único de fallo con nombre y apellidos. Y es un requisito verificable, no una opinión.

🔬 **El detalle** — Conviene medirlo de verdad de vez en cuando: preguntar quién ha desplegado y quién
ha diagnosticado un incidente en cada servicio durante el último trimestre. La respuesta suele ser más
concentrada de lo que la gente cree.

**06 → 6. ¿Qué patrón separa más a Java del resto, según la matriz? 🟡**

⏱️ **30 segundos** — La mecánica transaccional: outbox y saga, donde Java tiene módulos y las demás lo
escriben a mano.

🗣️ **2 minutos** — Es la simetría más clara de la tabla: Java gana en lo que hay que construir —outbox,
saga, resiliencia, testing— y pierde en empaquetado y arranque, que es justo donde gana Go. Node y
Python se parecen entre sí: fuertes en el borde, más débiles en datos.

🔬 **El detalle** — Esa simetría es útil para decidir: si el servicio tiene mucha mecánica
transaccional, Java ahorra semanas; si tiene mucho perfil operativo —muchas réplicas, escalado
agresivo—, Go las ahorra en infraestructura.

**06 → 7. ¿Por qué el criterio "¿ya existe en la casa?" cambia tantos resultados? 🟡**

⏱️ **30 segundos** — Porque añade un coste fijo grande que la comparación técnica del servicio aislado
no ve.

🗣️ **2 minutos** — En aislamiento, un servicio puede encajar mejor en otra plataforma por su perfil.
Pero si sería el único, hay que sumarle chassis, paneles, imágenes, actualizaciones y guardias, y esa
suma suele superar el beneficio. Cuando la plataforma ya existe, ese coste es cero y la decisión
cambia por completo.

🔬 **El detalle** — De ahí una consecuencia útil: el mismo servicio puede tener respuestas distintas en
dos organizaciones, y ambas ser correctas. Conviene decirlo así en una entrevista, porque demuestra
que la decisión depende del contexto y no de una tabla.

**06 → 8. ¿Por qué ningún ❌ de la matriz es prohibitivo? 🟡**

⏱️ **30 segundos** — Porque son días de trabajo que se escriben **una vez** en el chassis, no una vez
por servicio.

🗣️ **2 minutos** — Un outbox en Node son unas decenas de líneas más su publicador, sus métricas y su
limpieza: días, no meses. El problema no es escribirlo, es escribirlo tres veces de tres formas
distintas. Por eso la pregunta correcta no es "¿se puede?" sino "¿quién lo mantiene y dónde vive?".

🔬 **El detalle** — Esa distinción es la que convierte la matriz en una herramienta de decisión y no en
un ranking: la casilla roja se compensa con chassis, y por tanto solo cuesta de verdad si vas a tener
pocos servicios en esa plataforma.

**06 → 9. ¿Por qué en banca la respuesta tiende a una plataforma principal? 🟡**

⏱️ **30 segundos** — Porque cada plataforma añade superficie que auditar, certificar y actualizar, y
eso tiene un coste que alguien firma.

🗣️ **2 minutos** — Hay imágenes base certificadas, políticas de parcheo, requisitos de soporte
comercial y auditorías periódicas. Multiplicar eso por cuatro plataformas es caro y lento. A eso se
suma que el ecosistema de Java cubre bien lo que el sector necesita —lotes, BPM, soporte comercial— y
que la bolsa de profesionales es grande.

🔬 **El detalle** — Las excepciones existen igual: un servicio de modelos en Python o un agente en Go
se justifican con los mismos argumentos que en cualquier otro sector. Lo que no encaja es "cada equipo
elige", porque el coste no lo paga el equipo que elige.

**06 → 10. ¿Por qué "cada equipo elige" no es lo mismo que autonomía? 🟡**

⏱️ **30 segundos** — Porque la autonomía se ejerce dentro de un conjunto soportado; elegir sin límite
traslada el coste a los demás.

🗣️ **2 minutos** — El equipo que elige paga el beneficio y no paga la factura completa: la plataforma
nueva la tienen que operar, parchear y cubrir todos, incluidos quienes hagan guardia el año que viene.
La autonomía útil es decidir el diseño, el ritmo y las prioridades del servicio, no ampliar el conjunto
de tecnologías que la organización sostiene.

🔬 **El detalle** — La formulación que suele funcionar en la conversación: "elegid con libertad dentro
de estas tres; si queréis una cuarta, traed el chassis y las dos personas". Convierte una negativa en
un requisito alcanzable.

**06 → 11. ¿Qué diferencia hay entre poliglotismo y deuda de plataformas? 🟠**

⏱️ **30 segundos** — El poliglotismo tiene argumento, chassis y dos personas; la deuda tiene
curiosidad, chassis a medias y un mantenedor.

🗣️ **2 minutos** — La señal más clara es la uniformidad operativa: si los paneles de ese servicio no se
parecen a los de los demás, si sus métricas se llaman distinto y si su despliegue es especial, la
plataforma no está sostenida. Eso no se arregla con formación puntual: se arregla consolidando o
invirtiendo de verdad.

🔬 **El detalle** — Un indicador práctico y barato: ¿cuánto tarda alguien del equipo que no escribió
ese servicio en desplegar un cambio trivial en él? Si la respuesta es "no sabría", la plataforma es
deuda aunque el servicio funcione perfectamente.

**06 → 12. ¿Por qué reescribir un servicio de datos por uniformidad suele ser un error? 🟠**

⏱️ **30 segundos** — Porque se pierde el ecosistema que lo justificaba, que era la razón de la
excepción.

🗣️ **2 minutos** — Las librerías de datos y de modelos están en Python; reescribir en otra plataforma
significa reimplementar o encontrar equivalentes peores, con más código propio y más riesgo. La
uniformidad tiene valor real —rotación, herramientas, operación— pero no cuando destruye el motivo de
la excepción.

🔬 **El detalle** — Hay un caso donde sí tiene sentido: cuando ese servicio ya casi no hace trabajo de
datos y se ha convertido en un servicio de dominio normal. Entonces la excepción ha dejado de aplicar
y consolidarlo es correcto; conviene revisarlo periódicamente.

**06 → 13. Un equipo quiere escribir su servicio en una plataforma nueva. ¿Qué le pides? 🟠**

⏱️ **30 segundos** — El argumento —propiedad, ecosistema o perfil— y el requisito de entrada: chassis,
plantilla, pipeline, paneles y dos personas que sepan operarla.

🗣️ **2 minutos** — Primero la conversación sobre el argumento: si no cae en una de las tres categorías
preaprobadas, hay que justificarlo por escrito. Y después el requisito, que es lo que convierte la
decisión en objetiva: no se trata de si la plataforma gusta, sino de si va a estar sostenida cuando
quien la propuso cambie de equipo.

🔬 **El detalle** — Conviene ofrecer ayuda concreta en vez de solo poner condiciones: si el argumento
es bueno, el equipo de plataforma puede colaborar en el chassis inicial. Una política que solo
prohíbe genera excepciones clandestinas.

**06 → 14. Tienes cinco plataformas con un servicio cada una. ¿Qué haces? 🟠**

⏱️ **30 segundos** — Consolidar: elegir dos o tres sostenibles y llevar el resto a soporte mínimo o
reescritura planificada.

🗣️ **2 minutos** — El criterio para elegir cuáles se quedan: cuántas personas las dominan, qué
argumento las justificaba y cuánto trabajo hay ya invertido en su chassis. Los servicios que se
quedan fuera no se reescriben todos de golpe: se declaran en soporte mínimo —sin funcionalidad
nueva— y se migran cuando toque tocarlos.

🔬 **El detalle** — Conviene ser explícito sobre el coste de no hacer nada: cinco plataformas con un
servicio cada una significan cinco chassis a medias y cinco puntos únicos de fallo humanos. Poner ese
coste por escrito es lo que suele desbloquear la decisión.

**06 → 15. ¿Cómo justificarías ante dirección que el BFF esté en otra plataforma? 🟠**

⏱️ **30 segundos** — Por propiedad y por velocidad: lo mantiene el equipo de frontend, con sus tipos y
su ritmo, sin depender de otra cola.

🗣️ **2 minutos** — El argumento en su lenguaje: cada cambio de pantalla dejaría de depender de otro
equipo, lo que se traduce en entregar antes. Y el coste está acotado: es una plataforma que ese equipo
ya domina, así que no hay que formar a nadie. Lo que sí hay que dar es chassis y capacidad de operar,
y eso se presupuesta.

🔬 **El detalle** — Ayuda llevar el dato de cuántos cambios de pantalla han esperado a otro equipo en
el último trimestre. Convierte un argumento arquitectónico en una cifra de retraso, que es el lenguaje
en el que se decide.

**06 → 16. Un servicio de Go lo mantiene una sola persona y se va del equipo. ¿Qué haces? 🟠**

⏱️ **30 segundos** — Decidir ya: o se forma a alguien más de verdad, o se consolida el servicio en la
plataforma principal.

🗣️ **2 minutos** — Lo que no vale es dejarlo como está y confiar. Si el servicio es pequeño y su
argumento era débil, reescribirlo puede costar menos que sostener la plataforma. Si es importante y el
argumento sigue siendo válido —es un agente, un sidecar—, entonces hay que invertir: traspaso real,
documentación, y que otra persona despliegue y diagnostique con acompañamiento.

🔬 **El detalle** — El momento de la salida es la mejor oportunidad para el traspaso, y casi siempre se
desaprovecha: se dedica a "documentar" en vez de a que otra persona haga el trabajo con la primera
mirando. Lo segundo funciona mucho mejor.

**06 → 17. ¿Qué preguntas antes de aprobar una excepción a la plataforma principal? 🟠**

⏱️ **30 segundos** — Cuál es el argumento, quién la va a mantener, si ya existe en la casa, y qué pasa
cuando esa persona no esté.

🗣️ **2 minutos** — A eso añadiría: ¿qué patrones de la matriz necesita este servicio y cuántos están en
rojo en esa plataforma? ¿existe chassis o hay que escribirlo? ¿quién lo mantendrá? Y una pregunta de
cierre: ¿aceptaríamos el mismo argumento de otro equipo dentro de seis meses? Si la respuesta es no,
el argumento no es tan bueno.

🔬 **El detalle** — Esa última pregunta es la que más criba: convierte la decisión puntual en una
regla, que es lo que evita el goteo de excepciones. Si la excepción no es generalizable, conviene
escribir por qué es específica.

**06 → 18. ¿Cómo decides si consolidar una plataforma o mantenerla en soporte mínimo? 🟠**

⏱️ **30 segundos** — Por cuánto hay invertido, cuánta gente la domina y si el servicio va a seguir
cambiando.

🗣️ **2 minutos** — Si el servicio es estable y casi no se toca, mantenerlo en soporte mínimo es más
barato que reescribirlo: se actualiza su imagen, se parchea y se deja. Si va a seguir evolucionando,
cada cambio paga el coste de la plataforma y la consolidación se amortiza. La decisión es económica,
no estética.

🔬 **El detalle** — El soporte mínimo necesita definirse para no ser abandono: quién parchea, con qué
frecuencia, y qué ocurre si aparece una vulnerabilidad grave. Sin eso, "soporte mínimo" acaba siendo
"nadie", que es la peor de las opciones.

**06 → 19. ¿Qué responderías a "el lenguaje da igual, lo importante es la arquitectura"? 🟠**

⏱️ **30 segundos** — Que da igual para la latencia y no da igual para cuánto código escribes ni para
el perfil operativo.

🗣️ **2 minutos** — La arquitectura decide las fronteras y los contratos, y eso pesa más, cierto. Pero
la plataforma decide cuánta mecánica tienes que construir —outbox, saga, resiliencia—, cuánto consume
cada instancia y cuánto tarda en arrancar. Eso se traduce en tiempo de equipo y en coste de
infraestructura, que son consecuencias reales.

🔬 **El detalle** — Conviene conceder la parte cierta antes de matizar: quien dice eso suele estar
reaccionando a discusiones estériles de lenguajes, y tiene razón en el fondo. La conversación mejora
si se reconoce y se reconduce a los ejes que sí importan.

**06 → 20. ¿Cómo mantendrías la política viva y no como un documento olvidado? 🟠**

⏱️ **30 segundos** — Ligándola a algo que ocurre: la plantilla de servicio nuevo, la revisión de
arquitectura y una revisión periódica corta.

🗣️ **2 minutos** — Si crear un servicio empieza por una plantilla que solo existe para las plataformas
soportadas, la política se aplica sola. Una revisión trimestral de quince minutos —qué plataformas
hay, cuántos servicios, cuántas personas por plataforma— basta para detectar la deriva. Y cada
excepción aprobada se anota con su argumento, para poder revisarla.

🔬 **El detalle** — Las políticas mueren cuando solo viven en un documento. Las que sobreviven están
incrustadas en herramientas: plantillas, pipelines y comprobaciones automáticas. Diseñarla pensando
en dónde se va a aplicar es más importante que redactarla bien.

**06 → 21. Escribe la política de plataformas de una organización con 25 servicios y tres equipos, con sus excepciones y su proceso. 🔴**

⏱️ **30 segundos** — Una plataforma principal, dos excepciones preaprobadas con dueño, requisito de
entrada objetivo y revisión trimestral.

🗣️ **2 minutos** — La política:

```text
Soportadas       Java (principal, dueño: equipo de plataforma)
                 Node/TS (BFF, dueño: equipo de frontend)
                 Python (servicios de datos, dueño: equipo de datos)
Excepciones      preaprobadas: BFF por experiencia · servicios de datos y modelos
preaprobadas     · agentes y sidecars (Go, si aparece la necesidad)
Requisito de     chassis equivalente · plantilla y pipeline · imagen base con
entrada          escaneo · paneles con las mismas métricas · DOS personas que
                 la operen · dueño nominal
Proceso          propuesta escrita con el argumento → revisión con plataforma →
                 decisión registrada con fecha y motivo
Salida           plataforma con un solo servicio y un solo mantenedor:
                 se consolida o pasa a soporte mínimo definido
Revisión         trimestral, 15 minutos: plataformas, servicios y personas por
                 plataforma
```

🔬 **El detalle** — El punto que hace que funcione es el dueño nominal por plataforma: sin alguien
responsable del chassis y de las actualizaciones, la plataforma se degrada aunque cumpla el requisito
de entrada el primer día.

**06 → 22. Diseña la decisión de plataforma para cuatro servicios nuevos con perfiles distintos, justificando cada una y diciendo cuál te costaría más defender. 🔴**

⏱️ **30 segundos** — Dominio en Java, BFF en Node/TS, agente de métricas en Go, y servicio de
recomendaciones en Python.

🗣️ **2 minutos** — Las cuatro decisiones:

```text
Servicio                    Plataforma   Argumento
──────────────────────────  ───────────  ────────────────────────────────────
Gestión de suscripciones    Java         mecánica transaccional: saga, outbox,
(dominio, sagas)                         lotes; plataforma principal
BFF de la web               Node/TS      propiedad: lo mantiene frontend,
                                         tipos compartidos
Agente de métricas          Go           perfil: binario pequeño, memoria baja,
(una réplica por nodo)                   arranque inmediato
Recomendaciones (modelos)   Python       ecosistema: reescribirlo lo perdería
```

La más difícil de defender es la tercera: si Go no existe todavía en la casa, hay que sumar chassis,
paneles y guardias para un solo componente. La alternativa sería escribirlo en la plataforma principal
y aceptar peor perfil, o buscar un agente ya existente en vez de escribirlo.

🔬 **El detalle** — Ese análisis —"¿de verdad hay que escribirlo?"— es el que más veces evita una
plataforma nueva. Muchos agentes y recolectores ya existen como producto, y adoptarlos deja el
argumento de perfil satisfecho sin ampliar el conjunto soportado.

**06 → 23. Un equipo propone reescribir tres servicios en otra plataforma por rendimiento. Diseña la respuesta: qué mides, qué concedes y qué alternativa ofreces. 🔴**

⏱️ **30 segundos** — Primero medir dónde se va el tiempo; conceder el problema si es real; y ofrecer
alternativas más baratas antes de reescribir.

🗣️ **2 minutos** — La respuesta:

```text
Qué mido        reparto del tiempo: espera de red, base de datos, cómputo propio
                consumo de memoria y arranque por instancia
                coste real de infraestructura de esos tres servicios
Qué concedo     si el cómputo propio domina → su argumento es válido
                si el coste de infraestructura es alto y se debe a memoria/arranque
                → también, y ahí entra compilación nativa o cambio de plataforma
Alternativas    optimizar lo evidente primero (consultas, N+1, caché, lotes)
                ajustar memoria y arranque antes de reescribir
                mover SOLO el componente caro, no el servicio entero
Prueba          un servicio, medido antes y después, antes de comprometer los tres
```

🔬 **El detalle** — La alternativa de mover solo el componente caro es la que casi nunca se considera y
la que más veces resuelve: conserva el servicio donde está, captura el beneficio donde importa, y no
añade una plataforma para todo el sistema.

**06 → 24. Escribe la respuesta completa de dos minutos a "¿cuántas plataformas debería tener nuestro sistema?". 🔴**

⏱️ **30 segundos** — "Las menos posibles que cubran los tres casos donde la diversidad se paga sola:
normalmente dos o tres."

🗣️ **2 minutos** — La respuesta desarrollada:

```text
1. El planteamiento   no es una cuestión de lenguajes: cada plataforma es un
                      chassis, unos paneles, una imagen base y una guardia
2. El criterio        una principal, y excepciones con argumento de propiedad,
                      ecosistema o perfil: BFF con el equipo de frontend,
                      datos en Python, agentes en Go
3. El requisito       para que una plataforma cuente como soportada: chassis,
                      plantilla, pipeline, paneles y dos personas que la operen
4. La señal de alarma una plataforma con un servicio y un mantenedor no es
                      poliglotismo: es un punto único de fallo
5. La conclusión      prefiero dos plataformas bien sostenidas que cinco a medias,
                      y cada excepción tiene que ganarse
```

🔬 **El detalle** — Si el entrevistador presiona hacia "pero la libertad de stack es una ventaja de los
microservicios", conviene conceder que es una **posibilidad** y devolver la pregunta al coste: quién
mantiene el chassis, quién hace la guardia y quién cubre las vacaciones. La conversación se ordena
sola en cuanto aparece esa lista.

---

# 07 — Simulación de entrevista

**Sobre las preguntas `S#`.** Están cubiertas por las preguntas de los seis capítulos del bloque:
`S1`–`S5` por [`01`](01-que-cambia-entre-plataformas.md), `S6`–`S9` por [`02`](02-java.md),
`S10`–`S13` por [`03`](03-node-y-typescript.md), `S14`–`S17` por [`04`](04-go.md), `S18`–`S21` por
[`05`](05-python.md) y `S22`–`S28` por [`06`](06-la-matriz-de-decision.md). Las de "las que
descolocan" —`S29` a `S34`— se practican en voz alta.

**05/07 → E1. Tres servicios nuevos, tres perfiles, casa de Java.**

⏱️ **30 segundos** — Suscripciones en Java, recomendaciones en Python, y el agente en Go — que es el
que más me costaría defender.

🗣️ **2 minutos** — Las tres decisiones:

```text
Servicio                 Plataforma  Argumento
───────────────────────  ──────────  ──────────────────────────────────────────
Suscripciones            Java        mecánica transaccional: saga, outbox,
(sagas, facturación)                 facturación periódica por lotes.
                                     Es la plataforma principal y su punto fuerte
Recomendaciones          Python      ecosistema: reescribirlo en otra plataforma
(modelos)                            significa perder las librerías que lo justifican
Agente de métricas       Go          perfil: binario pequeño, memoria baja,
(una réplica por nodo)               arranque inmediato, multiplicado por N nodos
```

La más difícil de defender es la tercera: si no hay Go en la casa, hay que sumar chassis, paneles,
imagen base y guardias para un solo componente.

🔬 **El detalle** — Antes de aprobar el agente conviene preguntar si hay que escribirlo: muchos
recolectores y agentes existen ya como producto, y adoptarlos satisface el argumento de perfil sin
ampliar el conjunto de plataformas soportadas. Si de verdad hay que escribirlo, el requisito de
entrada —chassis, plantilla, paneles y **dos** personas que sepan operarlo— es lo que convierte la
excepción en sostenible.

**05/07 → E2. La reescritura por rendimiento.**

⏱️ **30 segundos** — Primero medir dónde se va el p99 de 400 ms. Si casi todo es espera, la
reescritura no lo cambia y hay que buscar en otro sitio.

🗣️ **2 minutos** — La respuesta:

```text
Qué mido        reparto del p99: red · base de datos · cómputo propio
                memoria y arranque por instancia; coste mensual de esos servicios
Qué espero      que el cómputo propio sea una fracción pequeña → la reescritura
                cambiaría poco la latencia
Qué concedo     si el coste de infraestructura es alto y se debe a memoria o
                arranque, su preocupación es legítima: ahí Go ayuda de verdad
Alternativas    1. optimizar lo evidente: consultas, N+1, caché, endpoints por lote
                2. ajustar memoria y arranque; evaluar compilación nativa
                3. mover SOLO el componente caro, si lo hay, en vez del servicio
Prueba          un servicio, medido antes y después, antes de comprometer los tres
Coste omitido   tres reescrituras = meses sin funcionalidad nueva + riesgo de
                reintroducir errores ya resueltos
```

🔬 **El detalle** — La alternativa 3 es la que casi nunca se considera y la que más veces resuelve:
conserva el servicio donde está, captura el beneficio donde importa y no añade una plataforma para
todo el sistema. Y conviene cerrar preguntando qué problema quieren resolver: si en realidad es que el
equipo no quiere mantener Java, esa es una conversación legítima pero distinta, y merece tenerse
explícitamente.

**05/07 → E3. La política de plataformas y el plan de consolidación.**

⏱️ **30 segundos** — Tres soportadas con dueño, requisito de entrada objetivo, tres excepciones
preaprobadas, y la cuarta plataforma a consolidar aprovechando la salida del mantenedor.

🗣️ **2 minutos** — La política y el plan:

```text
Política
  Soportadas       Java (principal) · Node/TS (BFF) · Python (datos), con dueño
                   nominal del chassis en cada una
  Entrada          chassis equivalente · plantilla y pipeline · imagen base con
                   escaneo · paneles con las mismas métricas · DOS personas
  Excepciones      preaprobadas: BFF por experiencia · datos y modelos ·
                   agentes y sidecars. Cualquier otra, por escrito
  Salida           una plataforma con un servicio y un mantenedor se consolida
                   o pasa a soporte mínimo DEFINIDO (quién parchea y con qué ritmo)
  Revisión         trimestral, 15 minutos: plataformas, servicios, personas

Plan para la cuarta plataforma
  1. Aprovechar la salida como fecha límite: es la mejor oportunidad de traspaso
  2. Decidir ya: ¿el argumento sigue siendo válido? ¿el servicio va a cambiar?
  3. Si es estable y poco tocado → soporte mínimo con parcheo definido
  4. Si va a evolucionar → reescribir en la plataforma principal, planificado
  5. Traspaso real antes de la salida: que otra persona despliegue y diagnostique
     con la primera mirando, no "documentar"
```

🔬 **El detalle** — El punto 5 es el que más se desaprovecha: el periodo de preaviso se dedica a
escribir documentación que nadie leerá, cuando lo que funciona es que otra persona haga el trabajo
acompañada. Y conviene poner por escrito el coste de no decidir: un servicio sin nadie que pueda
desplegarlo es un incidente esperando fecha.

**05/07 → E4. El mismo patrón en cuatro plataformas: outbox más consumidor idempotente.**

⏱️ **30 segundos** — La mecánica es idéntica en las cuatro; lo que cambia es cuánto viene hecho: Java
tiene módulos, Go tiene componentes, y Node y Python se escriben a mano.

🗣️ **2 minutos** — La comparación:

```text
Pieza            Java              Node/TS           Go                Python
───────────────  ────────────────  ────────────────  ────────────────  ───────────────
Escritura en     módulos que lo    a mano sobre el   a mano, o          a mano sobre
la transacción   integran          cliente de BD     componente de      el ORM
                                                     mensajería
Publicador       incluido o        propio, con       propio o del       tarea periódica;
                 sencillo          cuidado del       componente         ojo al solapamiento
                                   apagado
Deduplicación    índice único +    igual             igual              igual
                 misma transacción
Confirmación     el marco decide:  explícita         explícita          según la librería
                 hay que saber                                          de cola
                 cuándo confirma
Limpieza         NO viene en ninguna de las cuatro: siempre se escribe
```

Lo que cambia de verdad son días de trabajo por servicio, no la dificultad conceptual.

🔬 **El detalle** — Dos matices que suben la respuesta. El primero: en Java lo que hay que conocer es
**cuándo confirma el marco**, porque de eso depende si pierdes o duplicas, y viene decidido por
defecto. El segundo: en las cuatro, esto debe escribirse **una vez en el chassis** y no una por
servicio — la diferencia entre plataformas deja de importar mucho si el patrón está resuelto una sola
vez y bien.

**05/07 → E5. El BFF en Node/TS en una casa de Java.**

⏱️ **30 segundos** — Es una de las tres excepciones preaprobadas, por propiedad. La propuesta tiene que
traer el requisito de entrada, y si el equipo no puede operarlo, no se monta.

🗣️ **2 minutos** — La propuesta:

```text
Argumento        propiedad: lo mantiene el equipo de frontend, con sus tipos,
                 su ritmo y su pipeline. Cada cambio de pantalla deja de depender
                 de otra cola de trabajo
Dato que lo      cuántos cambios de pantalla esperaron a otro equipo el último
sostiene         trimestre → convierte el argumento en una cifra de retraso
Requisitos       chassis equivalente (logs, trazas, cliente HTTP con plazos,
                 health, apagado) · plantilla y pipeline · paneles con las mismas
                 métricas · DOS personas del equipo capaces de operar
Coste            una plataforma más en el conjunto soportado, con sus imágenes,
                 escaneos y actualizaciones
Si no pueden     opciones, en orden: (1) darles apoyo real —chassis listo y
operarlo         acompañamiento en las primeras guardias—; (2) que plataforma
                 lo opere y frontend sea dueño del contenido, peor pero viable;
                 (3) no montar el BFF y resolver con endpoints a medida
Límite           la excepción es para el BFF, no un precedente para servicios
                 de dominio en Node
```

🔬 **El detalle** — La última línea es la que evita el efecto dominó: sin ella, la aprobación del BFF
se usa seis meses después como argumento para escribir un servicio de dominio en la misma plataforma.
Conviene dejar escrito por qué esta excepción es específica —propiedad de la experiencia, no
preferencia de lenguaje— en el mismo documento donde se aprueba.

---

**Anterior:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
