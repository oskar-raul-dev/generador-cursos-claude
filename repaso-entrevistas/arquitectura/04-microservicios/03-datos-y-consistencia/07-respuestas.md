# 07 — Respuestas: Datos y consistencia

> Solucionario del bloque `03-datos-y-consistencia`. Cada respuesta va en tres capas:
> **⏱️ 30 segundos** lo que dices primero, **🗣️ 2 minutos** lo que añades cuando dicen "cuéntame
> más", y **🔬 El detalle** lo que estudias pero no dices en voz alta. El enunciado está copiado
> literalmente del capítulo: si no cuadra, manda el capítulo y este archivo está desactualizado.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--base-de-datos-por-servicio) · [02](#02--consultas-entre-servicios) · [03](#03--saga) · [04](#04--outbox-inbox-e-idempotencia) · [05](#05--evolución-de-esquema-y-migraciones) · [06](#06--simulación-de-entrevista)

---

# 01 — Base de datos por servicio

**01 → 1. Enuncia la regla de base de datos por servicio. 🟢**

⏱️ **30 segundos** — Cada servicio es dueño exclusivo de su almacén: nadie más lee ni escribe en él, y
quien necesite esos datos los pide por API o los recibe por evento.

🗣️ **2 minutos** — Es la regla que hace real todo lo demás: sin ella puedes tener repositorio,
pipeline y contenedor propios y seguir sin poder desplegar solo, porque el esquema está compartido.
La consecuencia es que el esquema pasa a ser un detalle interno y el contrato público es la API o el
evento.

🔬 **El detalle** — Lo que la sostiene en la práctica no es el documento de arquitectura sino los
permisos: una credencial por servicio, sin acceso al esquema de los demás. Si dos servicios pueden
leer las mismas tablas, la regla es una recomendación.

**01 → 2. ¿Qué es público y qué es interno en un servicio, hablando de datos? 🟢**

⏱️ **30 segundos** — Público es la API y los eventos; interno son las tablas, sus columnas, sus
índices y su motor.

🗣️ **2 minutos** — Esa frontera es la que permite cambiar el esquema sin avisar a nadie, que es
exactamente la libertad que se compra al separar. En cuanto alguien lee tus tablas, tu esquema se
convierte en contrato público y pierdes esa libertad sin haberla negociado.

🔬 **El detalle** — El caso límite es la réplica de lectura: si el consumidor lee las tablas
replicadas, el esquema sigue siendo público. Por eso el contrato debe ser una vista con nombre propio
y estable, que puedas mantener mientras cambias lo de debajo.

**01 → 3. Nombra los cuatro acoplamientos que produce compartir una base. 🟢**

⏱️ **30 segundos** — De esquema, de despliegue, de rendimiento y de fallo.

🗣️ **2 minutos** — El de esquema impide migrar sin coordinar; el de despliegue es su consecuencia
directa; el de rendimiento hace que una consulta ajena te degrade; y el de fallo significa que la
saturación o el mantenimiento de la base os tumba a los dos. Cada uno se arregla de forma distinta y
solo el último exige separación real.

🔬 **El detalle** — El de rendimiento es el más desconcertante en producción: tu servicio va lento y
no has desplegado nada. Si ante ese síntoma nadie sabe decir quién más toca esa base, el problema ya
es estructural.

**01 → 4. ¿Cuáles son las tres excepciones honestas y qué condición tiene cada una? 🟢**

⏱️ **30 segundos** — Migración en curso, con fecha; réplica de lectura para informes, con vista
contractual; y datos de referencia, con un dueño que los publica.

🗣️ **2 minutos** — La primera es transitoria por definición y necesita fecha, dueño y tarea en el
tablero. La segunda quita el acoplamiento de rendimiento pero no el de esquema, salvo que el contrato
sea una vista. La tercera es para catálogos casi inmutables, donde replicar es más barato que
consultar.

🔬 **El detalle** — "Solo lectura" y "solo durante la migración" son las dos frases que más deuda
permanente han generado. Las dos son legítimas; ninguna sobrevive sin fecha y sin dueño de cerrarla.

**01 → 5. Enumera los cuatro escalones de separación. 🟢**

⏱️ **30 segundos** — Mismo esquema con acceso por módulo; esquemas separados en la misma instancia;
instancias separadas; y motores distintos si el acceso lo justifica.

🗣️ **2 minutos** — El primero es gratis y enseña el coste real de la frontera; el segundo da control
de permisos y de migraciones; el tercero es el que de verdad aísla rendimiento y fallo; el cuarto solo
se justifica por patrón de acceso. Se sube escalón a escalón y con un motivo.

🔬 **El detalle** — Cada escalón cuesta operación: copias de seguridad, monitorización, ventanas de
mantenimiento y dinero. Por eso la pregunta correcta no es "¿hasta dónde puedo llegar?" sino "¿qué
aislamiento necesito y cuánto estoy dispuesto a pagar por él?".

**01 → 6. ¿Qué sustituye a una clave foránea entre servicios? 🟢**

⏱️ **30 segundos** — La validación en el servicio dueño al crear el dato, y una decisión de negocio
sobre qué pasa si el referente desaparece.

🗣️ **2 minutos** — `orders` valida contra `customers` cuando crea el pedido; después, si el cliente se
borra, el pedido queda con una referencia que ya no resuelve. Eso no es corrupción: es una situación
que el negocio tiene que definir, y casi siempre la respuesta es no borrar, sino desactivar.

🔬 **El detalle** — Hay un matiz de rendimiento: validar en cada creación añade una llamada síncrona.
Si el volumen lo hace caro, se replica localmente el conjunto de identificadores válidos por eventos y
se valida contra la copia, aceptando una ventana de inconsistencia.

**01 → 7. ¿Qué mecanismo sostiene de verdad la regla: el documento de arquitectura o los permisos? 🟢**

⏱️ **30 segundos** — Los permisos. Una credencial por servicio sin acceso a los esquemas ajenos.

🗣️ **2 minutos** — Los acuerdos se erosionan con la primera urgencia: alguien necesita un dato, la
tabla está ahí, y la consulta funciona. Si la credencial no tiene permiso, la conversación cambia y se
busca la solución correcta. Es control técnico en vez de disciplina, y por eso funciona.

🔬 **El detalle** — Conviene además revisar periódicamente quién tiene permisos sobre qué: en sistemas
con años, las credenciales se acumulan y aparecen accesos concedidos para una migración que terminó
hace tiempo.

**01 → 8. ¿Por qué una réplica de lectura no elimina el acoplamiento de esquema? 🟡**

⏱️ **30 segundos** — Porque el consumidor sigue leyendo tus tablas, aunque estén en otra instancia.

🗣️ **2 minutos** — La réplica separa recursos —CPU, memoria, conexiones—, así que elimina el
acoplamiento de rendimiento y parte del de fallo. Pero si renombras una columna, la réplica la
renombra también y el consumidor se rompe igual. Solo una vista con nombre propio y estable convierte
eso en un contrato mantenible.

🔬 **El detalle** — La vista tiene además una ventaja de gobierno: es un artefacto visible que alguien
puede revisar, versionar y retirar. Las tablas leídas por otros no aparecen en ningún sitio hasta que
rompes algo.

**01 → 9. ¿Por qué prohibir los `JOIN` cruzados dentro del monolito es un paso valioso? 🟡**

⏱️ **30 segundos** — Porque te enseña el coste real de la frontera cuando todavía es gratis cambiarla
de sitio.

🗣️ **2 minutos** — Si al prohibirlo descubres que una pantalla necesita cinco consultas encadenadas,
acabas de aprender que la frontera está mal puesta, y moverla solo cuesta refactorizar código. Si lo
descubres después de extraer el servicio, el arreglo implica mover datos entre bases y coordinar
despliegues.

🔬 **El detalle** — Conviene verificarlo automáticamente con una prueba de arquitectura que falle
cuando un módulo accede a tablas de otro. Sin esa verificación, la prohibición dura hasta el primer
viernes con prisa.

**01 → 10. ¿Qué acoplamiento explica que tu servicio se degrade sin haber desplegado nada? 🟡**

⏱️ **30 segundos** — El de rendimiento: alguien más está usando la misma base y se llevó tus
recursos.

🗣️ **2 minutos** — Suele ser un informe, una migración ajena o una consulta sin índice recién
desplegada por otro equipo. El síntoma es característico: latencia alta, tu código intacto, y métricas
de base de datos con espera de bloqueos o CPU alta. La solución a corto plazo es mover ese consumo a
una réplica; a largo, separar instancias.

🔬 **El detalle** — Es también el argumento más convincente para subir del escalón 2 al 3, porque es
el único acoplamiento que la gente sufre en carne propia. Los otros tres se discuten; este se padece.

**01 → 11. ¿Por qué el borrado suele sustituirse por desactivación? 🟡**

⏱️ **30 segundos** — Porque otros servicios tienen referencias a ese dato y el negocio casi nunca
quiere que desaparezcan sus registros históricos.

🗣️ **2 minutos** — Un pedido de hace dos años debe seguir existiendo aunque el cliente se dé de baja:
lo exige la contabilidad y a menudo la ley. Desactivar mantiene la referencia resoluble y convierte el
problema en una regla de negocio explícita: qué se puede hacer con un cliente inactivo.

🔬 **El detalle** — Cuando sí hay obligación de borrar —derecho al olvido—, la respuesta no es borrar
en cascada, es anonimizar: se conservan los registros con los datos personales sustituidos. Esa
distinción es importante en banca y suele preguntarse.

**01 → 12. Diferencia entre duplicar datos por accidente y copiarlos a propósito. 🟡**

⏱️ **30 segundos** — La copia a propósito es una foto que el negocio quiere congelada; la duplicación
accidental es el mismo dato vivo en dos sitios sin dueño claro.

🗣️ **2 minutos** — El precio pagado y la dirección de envío se copian dentro del pedido porque deben
reflejar el momento de la compra: si el catálogo sube el precio mañana, la factura de ayer no cambia.
En cambio, el teléfono del cliente replicado en tres servicios "para no llamar" es duplicación sin
dueño: los tres creen tenerlo al día.

🔬 **El detalle** — El criterio para distinguirlas: pregunta qué debe pasar cuando cambie el origen.
Si la respuesta es "nada, quiero el valor de entonces", es copia legítima, y además debería ser
inmutable.

**01 → 13. ¿Qué cambia entre plataformas en quién versiona el esquema y cuándo corre la migración? 🟡**

⏱️ **30 segundos** — Lo que cambia no es el ORM: es **quién versiona el esquema y cuándo corre la
migración**, porque de eso depende si el servicio puede desplegarse solo.

🗣️ **2 minutos** — Java integra migraciones versionadas en el arranque de la aplicación, que es cómodo
y acopla despliegue y esquema; Node/TS y Python generan la migración a partir del modelo declarado, y
ahí hay que revisar siempre lo generado —los renombrados salen como borrar y crear—; en Go la
herramienta suele ser un binario independiente, lo que empuja de forma natural a ejecutarla como paso
del pipeline, que es lo correcto.

🔬 **El detalle** — En las cuatro, la decisión importante es la misma y no la toma la librería: al
arrancar es cómodo hasta que varias instancias arrancan a la vez y un fallo se convierte en un bucle
de reinicios. Como paso explícito del pipeline, el fallo es visible y el servicio en ejecución no se
entera.

---
**01 → 14. ¿Qué plataforma te ayuda más a cumplir la regla de propiedad de los datos, y por qué la pregunta está mal planteada? 🟡**

⏱️ **30 segundos** — Ninguna: los permisos se configuran en la base de datos, no en el código, y eso
es igual en las cuatro. Lo que cambia es el ORM, que no es lo que sostiene la regla.

🗣️ **2 minutos** — Es una de las poquísimas decisiones del corpus que no depende de la plataforma:
una credencial por servicio, sin permisos sobre esquemas ajenos. La elección de mapeo —maduro en Java
y Python, cliente tipado en Node/TS, SQL explícito en Go— afecta a cómo escribes las consultas, no a
quién puede leer qué.

🔬 **El detalle** — Y por eso la comprobación de si la regla se cumple se hace listando usuarios y
permisos, no revisando código. En sistemas con años suele aparecer una credencial compartida heredada
del monolito, que es la misma en las cuatro plataformas.

---
**01 → 15. Te piden acceso de solo lectura a tus tablas para un informe. ¿Qué ofreces? 🟠**

⏱️ **30 segundos** — Una vista estable sobre una réplica, con nombre propio y contrato explícito; o
un volcado periódico al almacén analítico.

🗣️ **2 minutos** — La vista separa el contrato del esquema físico y la réplica protege el rendimiento
del servicio principal. Si lo que quieren es análisis histórico, lo correcto casi siempre es publicar
los datos al almacén analítico —por eventos o por captura de cambios— y que consulten allí, sin tocar
la base operativa.

🔬 **El detalle** — Conviene acordar también la frecuencia y la latencia aceptable: si el informe
tolera datos de ayer, el volcado nocturno elimina todo el problema. Muchas peticiones de acceso
directo desaparecen cuando se pregunta cuánta frescura necesitan de verdad.

**01 → 16. ¿Cuándo subirías de esquemas separados a instancias separadas? 🟠**

⏱️ **30 segundos** — Cuando el acoplamiento de rendimiento o de fallo ya te ha costado un incidente,
o cuando los perfiles de carga son muy distintos.

🗣️ **2 minutos** — Señales concretas: un servicio degrada al otro con sus consultas; la ventana de
mantenimiento de la instancia afecta a servicios con criticidad distinta; o uno necesita escalar y el
otro no. Antes de eso, esquemas separados con permisos dan la mayor parte del beneficio a mucho menos
coste.

🔬 **El detalle** — Hay un motivo no técnico que a veces manda: el cumplimiento normativo. Si un
servicio maneja datos con requisitos de cifrado, retención o auditoría distintos, separar instancias
reduce el alcance de la auditoría y suele compensar por sí solo.

**01 → 17. `customers` quiere borrar un cliente que tiene pedidos. ¿Qué diseñas? 🟠**

⏱️ **30 segundos** — Desactivación en `customers` y publicación del hecho; `orders` decide qué hace
con sus datos, y nadie borra en cascada.

🗣️ **2 minutos** — `customers` marca al cliente como inactivo y publica `CustomerDeactivated`. `orders`
reacciona según su propia regla: normalmente no borra nada, porque los pedidos son historia contable.
Si hay obligación legal de eliminar datos personales, el evento es `CustomerAnonymized` y cada
servicio sustituye los datos personales que guarde, conservando el registro.

🔬 **El detalle** — El caso difícil es el de los datos personales copiados dentro de un pedido —nombre
y dirección de envío—. Ahí la anonimización choca con la necesidad contable de conservar la factura, y
la resolución es jurídica antes que técnica: conviene plantearlo así en vez de improvisar una regla.

**01 → 18. ¿Dónde harías correr las migraciones y por qué? 🟠**

⏱️ **30 segundos** — Como paso explícito del pipeline, antes de desplegar el código nuevo, y siempre
compatible hacia atrás.

🗣️ **2 minutos** — Al arrancar la aplicación es cómodo pero acopla esquema y despliegue: con varias
instancias hay que garantizar que solo una migre, y un fallo de migración se convierte en un bucle de
reinicios. Como paso del pipeline, el fallo es visible, se puede reintentar y no afecta al servicio en
ejecución.

🔬 **El detalle** — El requisito que lo hace posible es que la migración sea compatible con el código
viejo: durante el reemplazo gradual conviven ambas versiones. Eso lleva directamente a
expand/contract, que es el capítulo `05`.

**01 → 19. Un equipo propone un motor documental para su servicio nuevo. ¿Qué preguntas? 🟠**

⏱️ **30 segundos** — Cuál es su patrón de acceso, y quién va a operar ese motor: copias,
monitorización y guardia.

🗣️ **2 minutos** — Si leen y escriben el agregado entero por clave y no necesitan consultas variadas,
un documental encaja de verdad. Si van a necesitar informes, búsquedas por varios campos o
transacciones entre entidades, la elección les va a doler. Y el coste operativo es real: cada motor
nuevo es una tecnología más que alguien tiene que saber atender a las tres de la mañana.

🔬 **El detalle** — Pregunta de control: ¿qué consultas vais a necesitar dentro de un año? Muchos
diseños documentales se eligen mirando cómo se escribe y no cómo se lee, y las consultas imprevistas
son justo lo que peor resuelven.

**01 → 20. ¿Cómo comprobarías, en un sistema existente, si la regla se cumple de verdad? 🟠**

⏱️ **30 segundos** — Mirando las credenciales y los permisos de base de datos, no el código.

🗣️ **2 minutos** — Se listan usuarios y permisos por esquema: si la credencial de un servicio puede
leer tablas de otro, la regla no se cumple aunque nadie lo esté haciendo hoy. Como complemento, se
revisan las conexiones reales por origen y las consultas más frecuentes por usuario, que delatan
accesos que nadie recordaba.

🔬 **El detalle** — En sistemas con años suele aparecer una credencial compartida heredada de la época
del monolito, usada por varios servicios. Encontrarla es el primer paso, y sustituirla por una por
servicio es un trabajo pequeño con un efecto grande.

**01 → 21. Tienes que mantener unicidad de un correo electrónico entre dos servicios. ¿Cómo lo resuelves? 🟠**

⏱️ **30 segundos** — Asignando un dueño: uno de los dos es responsable de la unicidad y el otro
consulta o recibe el dato.

🗣️ **2 minutos** — Si `customers` es el dueño de la identidad, la restricción de unicidad vive en su
base y cualquier alta pasa por él. El otro servicio no valida por su cuenta: pregunta o reacciona al
evento. Intentar mantener unicidad en dos sitios lleva a carreras y a datos divergentes sin solución
limpia.

🔬 **El detalle** — Si el rendimiento obliga a una comprobación local previa, se hace como filtro
optimista —descartar rápido lo que ya sabes que existe— y la decisión final sigue siendo del dueño, en
su transacción. Esa distinción entre filtro y decisión es la que evita las carreras.

**01 → 22. ¿Qué datos de `catalog` copiarías dentro de `orders`, y por qué esos y no otros? 🟠**

⏱️ **30 segundos** — Los que el negocio quiere congelados: nombre del producto y precio en el momento
de la compra. Nada más.

🗣️ **2 minutos** — Esos datos no son caché, son parte del pedido: la factura debe reflejar lo que se
compró y a qué precio, aunque el catálogo cambie mañana. En cambio, la descripción actual, las
imágenes o la disponibilidad se consultan, porque `orders` no necesita su versión histórica y
mantenerlas sincronizadas sería duplicación sin dueño.

🔬 **El detalle** — La prueba para decidir: ¿qué debe ver el usuario al abrir un pedido de hace un
año? Si la respuesta es "lo que compró entonces", es copia; si es "lo que hay ahora", es consulta.
Formular así la pregunta convierte una discusión técnica en una decisión de producto.

**01 → 23. Diseña el plan para separar el esquema compartido de `orders` e `inventory`, con los escalones, lo que se despliega en cada uno y cómo se vuelve atrás. 🔴**

⏱️ **30 segundos** — Cuatro fases: prohibir accesos cruzados, separar esquemas, separar instancias, y
retirar permisos. Cada una reversible salvo la última.

🗣️ **2 minutos** — El plan:

```text
F1  Inventario de accesos cruzados (consultas y JOIN). Sustituirlos por llamadas
    a la API del dueño. Se despliega solo código. Vuelta atrás: revertir despliegue.
F2  Esquemas separados en la misma instancia; credenciales por servicio con permisos
    solo sobre el suyo. Vuelta atrás: restaurar permisos.
F3  Instancia separada para inventory: copia inicial + replicación + corte de escritura
    corto. Vuelta atrás: volver a apuntar a la instancia original (aún consistente).
F4  Retirar permisos y accesos antiguos. Punto de no retorno: cuando la instancia
    original deje de recibir escrituras de inventory.
Medición  en cada fase: latencia, errores y número de consultas por petición.
```

🔬 **El detalle** — La fase que se subestima es F1, que suele ser la más larga porque los accesos
cruzados aparecen en sitios inesperados: informes, tareas programadas, scripts de operación. Conviene
encontrarlos con los registros de consultas reales, no leyendo código.

**01 → 24. Diseña el contrato de la réplica de lectura que ofrecerías al equipo de informes, incluyendo qué garantizas y qué no. 🔴**

⏱️ **30 segundos** — Vistas con nombre propio, retraso máximo declarado, sin garantía sobre las tablas
de debajo, y fecha de revisión.

🗣️ **2 minutos** — El contrato:

```text
Qué expongo        vistas v_orders_summary, v_order_lines — nombres estables
Qué NO expongo     tablas físicas, columnas internas, estados intermedios
Qué garantizo      la forma de las vistas; aviso con 30 días antes de cambiarlas
Qué no garantizo   frescura instantánea: retraso típico < 30 s, sin compromiso duro
Cómo se usa        solo lectura, en la réplica; límites de concurrencia acordados
Revisión           cada seis meses: si nadie la consulta, se retira
```

🔬 **El detalle** — El punto importante del contrato es que las vistas son mías y las mantengo yo:
puedo reescribirlas cuando cambie el esquema físico. Sin esa cláusula, el equipo de informes acaba
dependiendo de la estructura interna igual que antes, solo que con un nombre más bonito.

**01 → 25. Un servicio necesita datos de otros tres para su lógica de negocio, no solo para mostrarlos. Analiza si la frontera está bien y propón alternativas. 🔴**

⏱️ **30 segundos** — Necesitar datos ajenos **para decidir** es señal de frontera mal puesta: la
decisión probablemente pertenece a otro sitio.

🗣️ **2 minutos** — El análisis:

```text
Primero preguntar  ¿qué decide con esos datos? Si la regla es de otro dominio,
                   la regla debería vivir allí y este servicio solo pedir el resultado.
Alternativa 1      mover la decisión al dueño de los datos: "¿puede este cliente comprar?"
                   en vez de traerse el crédito y decidir aquí
Alternativa 2      replicar por eventos lo imprescindible, si la decisión SÍ es suya
                   y los datos son estables
Alternativa 3      fusionar servicios, si resulta que las reglas y los datos
                   siempre cambian juntos
Peor opción        consultar los tres en caliente en cada decisión: latencia,
                   fallo compuesto y acoplamiento de disponibilidad
```

🔬 **El detalle** — La distinción que resuelve el caso es entre **datos para mostrar** y **datos para
decidir**. Mostrar tolera consistencia eventual y composición; decidir exige frescura y autoridad, y
por eso casi siempre debe hacerlo quien es dueño del dato.

**01 → 26. Escribe las reglas de acceso a datos que pondrías como política del equipo, incluyendo cómo se verifican automáticamente. 🔴**

⏱️ **30 segundos** — Cinco reglas: una credencial por servicio, sin permisos cruzados, sin `JOIN`
entre dominios, migraciones compatibles, y toda copia con dueño y motivo.

🗣️ **2 minutos** — La política:

```text
Regla                                        Verificación automática
───────────────────────────────────────────  ─────────────────────────────────────
Una credencial por servicio                  auditoría periódica de usuarios y permisos
Ningún permiso sobre esquemas ajenos         la misma auditoría; falla el pipeline si aparece
Ningún acceso cruzado en el código           prueba de arquitectura sobre paquetes y esquemas
Migraciones compatibles hacia atrás          verificación del script contra el código anterior
Toda copia de datos ajenos tiene dueño       revisión humana; no automatizable
 y motivo escrito
```

🔬 **El detalle** — La quinta regla no se puede automatizar y es la que más protege: obliga a que
cualquier duplicación sea una decisión consciente con alguien responsable de mantenerla. Las cuatro
primeras evitan el daño accidental; la quinta evita el daño deliberado y bienintencionado.

---

# 02 — Consultas entre servicios

**02 → 1. ¿Cuáles son las tres opciones para consultar datos repartidos entre servicios? 🟢**

⏱️ **30 segundos** — Composición en el llamador, proyección materializada alimentada por eventos, y
réplica local de datos de referencia.

🗣️ **2 minutos** — La composición llama a los dueños y junta; no añade estado y da el dato fresco. La
proyección mantiene una vista con la forma de la pantalla y da lectura de un salto a cambio de
consistencia eventual. La réplica de referencia copia catálogos pequeños y estables. Hay una cuarta
respuesta posible: que la consulta esté señalando una frontera mal puesta.

🔬 **El detalle** — El orden recomendado es componer primero, medir, y pasar a proyección con números
delante. Empezar por la proyección es añadir un almacén y un proceso antes de saber si hacían falta.

**02 → 2. ¿Qué diferencia hay entre componer en secuencia y en paralelo? 🟢**

⏱️ **30 segundos** — En secuencia la latencia es la suma; en paralelo, la del más lento.

🗣️ **2 minutos** — Tres llamadas de 40, 30 y 50 milisegundos son 120 en secuencia y 50 en paralelo.
Solo se puede paralelizar lo que no depende entre sí: si necesitas el cliente para saber qué pedir
después, hay una dependencia real y no hay atajo.

🔬 **El detalle** — Con el paralelismo aparece la decisión importante: qué se hace si una falla. En
secuencia la respuesta suele ser "corto y devuelvo error"; en paralelo puedes degradar por
dependencia, y eso hay que decidirlo explícitamente.

**02 → 3. ¿Qué tres preguntas hay que responder antes de construir una proyección? 🟢**

⏱️ **30 segundos** — Cuánto se retrasa, qué se hace si se corrompe, y quién es su dueño.

🗣️ **2 minutos** — El retraso se mide con el lag del proyector y se traduce a lo que ve el usuario. La
corrupción se resuelve reconstruyendo desde el historial, y ese procedimiento tiene que estar escrito
y probado antes. Y sin dueño explícito, la proyección se desincroniza y nadie se entera hasta que un
cliente lo reporta.

🔬 **El detalle** — La reconstrucción impone un requisito al diseño de eventos: tiene que haber
historial suficiente y los eventos deben bastar para recomponer el estado. Si los eventos son
notificaciones delgadas sin datos, no se puede reconstruir nada.

**02 → 4. ¿Qué es una réplica de datos de referencia? 🟢**

⏱️ **30 segundos** — Una copia local de un conjunto pequeño y estable de datos ajenos: países,
divisas, categorías, tarifas.

🗣️ **2 minutos** — El dueño publica los cambios y cada servicio mantiene su copia. Como cambian poco,
el desfase es irrelevante y la reconstrucción es trivial. Es la mejora con mejor relación entre coste
y beneficio del bloque: elimina llamadas constantes a cambio de una tabla y un consumidor sencillo.

🔬 **El detalle** — El riesgo es que la copia crezca. Empieza con países y acaba con el modelo
completo de cliente replicado en cuatro servicios, que ya es duplicación sin dueño. Conviene fijar
por escrito qué se replica y por qué.

**02 → 5. ¿Quién debe ser dueño de una proyección? 🟢**

⏱️ **30 segundos** — El servicio que sirve la pantalla o la consulta que la usa.

🗣️ **2 minutos** — Es quien conoce la forma que necesita, quien nota el desfase y quien tiene que
reconstruir si algo falla. Si la mantiene un equipo distinto —"el de datos"—, nadie vigila el retraso y
los cambios de esquema de los eventos se descubren tarde.

🔬 **El detalle** — La consecuencia organizativa es que ese servicio tiene que saber consumir eventos
y operar un almacén más. Si el equipo no está preparado para eso, la proyección es una mala idea
aunque técnicamente encaje.

**02 → 6. ¿Qué significa degradar una dependencia en una composición? 🟢**

⏱️ **30 segundos** — Responder sin ese dato, marcándolo como no disponible, en vez de fallar la
respuesta entera.

🗣️ **2 minutos** — Es una decisión por dependencia y de producto: sin el pedido no hay pantalla, pero
sin el nombre del cliente o sin la estimación de entrega la pantalla sigue siendo útil. Definir esa
tabla antes de programar es lo que convierte una caída ajena en una molestia.

🔬 **El detalle** — Conviene que la respuesta indique explícitamente qué falta, con un campo nulo y
una marca, en vez de devolver un valor inventado o vacío silencioso. Así el frontend puede mostrar
"no disponible" en vez de un hueco que parece un error de datos.

**02 → 7. ¿Por qué la composición empeora la disponibilidad de la pantalla? 🟡**

⏱️ **30 segundos** — Porque las disponibilidades se multiplican: cuatro dependencias al 99,9 % dan
alrededor del 99,6 %.

🗣️ **2 minutos** — Cada llamada obligatoria es un punto de fallo más. Por eso la degradación no es un
lujo: convertir dos de esas cuatro en opcionales devuelve la disponibilidad casi al nivel de la
dependencia crítica. La aritmética es el mejor argumento para justificar el trabajo extra de
degradar.

🔬 **El detalle** — El cálculo asume independencia entre fallos, que no se cumple: comparten red y
plataforma, así que en la práctica suele ser peor. Y una dependencia opcional bien degradada
sencillamente no entra en la multiplicación.

**02 → 8. ¿Por qué la reconstrucción de una proyección debe escribirse antes de necesitarla? 🟡**

⏱️ **30 segundos** — Porque el día que la necesitas, la proyección está mal y hay usuarios viendo
datos incorrectos: no es el momento de inventar el procedimiento.

🗣️ **2 minutos** — Reconstruir implica decidir desde dónde se relee, qué pasa con las consultas
mientras tanto —¿se sirve la vieja o se corta?—, cuánto tarda y cómo se verifica que quedó bien. Todas
esas decisiones son fáciles en frío y muy caras bajo presión.

🔬 **El detalle** — La variante que mejor funciona es reconstruir en una tabla nueva y cambiar el
puntero al terminar: así no hay ventana sin servicio y la vuelta atrás es inmediata. Requiere
espacio, que es barato comparado con el incidente.

**02 → 9. Diferencia entre replicar datos de referencia y replicar datos transaccionales. 🟡**

⏱️ **30 segundos** — Los de referencia cambian poco y el desfase da igual; los transaccionales cambian
con el flujo y el desfase produce decisiones incorrectas.

🗣️ **2 minutos** — Replicar la lista de divisas es seguro: si tarda un minuto en propagarse, no pasa
nada. Replicar el saldo de una cuenta o el stock disponible para **decidir** sobre ellos es otra cosa:
la copia desfasada autoriza operaciones que no debería. Para mostrar, la copia vale; para decidir,
manda el dueño.

🔬 **El detalle** — Hay un punto intermedio útil: usar la copia como filtro optimista y confirmar con
el dueño solo en el paso final. Así se evita la mayoría de las llamadas sin perder autoridad en la
decisión.

**02 → 10. ¿Por qué `Promise.all` y `allSettled` implican decisiones de producto distintas? 🟡**

⏱️ **30 segundos** — Porque la primera hace que un fallo secundario tumbe la pantalla entera y la
segunda te deja degradar.

🗣️ **2 minutos** — No es una preferencia de estilo: elegir una u otra define qué ve el usuario cuando
una dependencia se cae. Lo mismo ocurre en las otras plataformas, con otros nombres —cancelar al
primer fallo frente a recoger resultados parciales—. La decisión debería venir de la tabla de
degradación, no del ejemplo que alguien copió.

🔬 **El detalle** — Un patrón intermedio frecuente: `all` para las dependencias imprescindibles y
`allSettled` para las opcionales, en dos grupos. Así el fallo crítico corta rápido y el secundario se
degrada, que es exactamente lo que se quiere.

**02 → 11. ¿En qué se parece "un servicio que consulta todas las bases" a la base de datos compartida? 🟡**

⏱️ **30 segundos** — En que sigue leyendo los esquemas ajenos: solo ha añadido un proceso delante.

🗣️ **2 minutos** — Ese servicio se acopla a las tablas de todos, así que nadie puede migrar sin
coordinar con él, y además concentra un punto de fallo. Es el antipatrón de siempre disfrazado de
arquitectura, y se reconoce porque sus credenciales tienen permisos sobre varios esquemas.

🔬 **El detalle** — La versión legítima de esa idea es el servicio de consultas que consume **eventos**
y mantiene su propia proyección: entonces no lee nada ajeno, y el acoplamiento es al contrato del
evento, que es público y versionado.

**02 → 12. ¿Qué indica que una consulta necesite datos de tres servicios para decidir, no para mostrar? 🟡**

⏱️ **30 segundos** — Que la regla probablemente pertenece a otro sitio: la frontera está mal puesta.

🗣️ **2 minutos** — Mostrar tolera consistencia eventual y composición; decidir exige frescura y
autoridad. Si un servicio se trae el crédito, el historial y el riesgo para decidir si un cliente
puede comprar, lo razonable es preguntar al dueño —"¿puede comprar?"— y dejar la regla donde viven los
datos.

🔬 **El detalle** — El caso en que sí tiene sentido traérselos es cuando la regla es propia y combina
información de varios dominios —una regla de fraude, por ejemplo—. Entonces la salida suele ser
replicar por eventos lo imprescindible y asumir la ventana, no consultar en caliente.

**02 → 13. ¿Cómo se compone en paralelo en cada plataforma, y qué parámetro decide el fallo parcial? 🟡**

⏱️ **30 segundos** — Las cuatro componen en paralelo con su propio mecanismo, y en las cuatro hay un
parámetro que decide si un fallo parcial degrada o tumba la respuesta entera.

🗣️ **2 minutos** — En Java, tareas concurrentes que cancelan al primer fallo o recogen resultados por
separado; en Node/TS, `Promise.all` frente a `allSettled`; en Go, un grupo de error que cancela el
contexto al fallar uno; en Python, `gather` con o sin recogida de excepciones. La forma cambia, la
decisión es idéntica: fallo total o degradación, y eso sale de la tabla de degradación por
dependencia, no del ejemplo que alguien copió.

🔬 **El detalle** — El patrón intermedio que conviene conocer: agrupar las dependencias
imprescindibles con cancelación al primer fallo y las opcionales con recogida de resultados
parciales. Así el fallo crítico corta rápido y el secundario se degrada, que es justo lo que se busca.

---
**02 → 14. La pantalla de detalle tarda 400 ms componiendo cuatro llamadas. ¿Qué haces primero? 🟠**

⏱️ **30 segundos** — Comprobar si son secuenciales. Paralelizarlas suele bajar de la suma al máximo
sin cambiar nada más.

🗣️ **2 minutos** — Después miro si alguna es opcional para degradarla con un plazo corto, y si hay un
`N+1` escondido —una llamada por línea de pedido— que se arregla con un endpoint por lote. Solo si
tras eso sigue sin cumplir el objetivo, empiezo a hablar de proyección, con el número delante.

🔬 **El detalle** — Conviene mirar también el reparto: a veces 400 ms son 350 de una sola dependencia
lenta, y entonces el trabajo es de esa dependencia, no de la composición. Optimizar la composición
cuando el problema es un servicio lento solo reparte la culpa.

**02 → 15. Diseña la degradación de la pantalla del §1: qué se muestra si falla cada dependencia. 🟠**

⏱️ **30 segundos** — `orders` es obligatorio; `customers`, `catalog` y `shipping` degradan, cada uno con
su sustituto.

🗣️ **2 minutos** — La tabla:

```text
Dependencia  Si falla                              Qué ve el usuario
───────────  ────────────────────────────────────  ────────────────────────────
pedidos      error 503 de la pantalla              "no podemos mostrar el pedido"
customers    se omite el nombre, se deja el id     el pedido completo, sin nombre
catalog      se usa el nombre copiado en el pedido nada: ya lo teníamos congelado
shipping     se omite la estimación                el pedido sin fecha estimada
```

La fila de `catalog` es la interesante: como el nombre del producto se copió al confirmar el pedido,
esa dependencia ya era opcional por diseño.

🔬 **El detalle** — Conviene medir cuántas veces se degrada cada una: si `shipping` falla el 5 % de las
veces, eso es un problema que la degradación está escondiendo. La degradación protege al usuario, no
debe tapar el fallo en los paneles.

**02 → 16. ¿Cuándo pasarías de composición a proyección? Da los números que te harían decidir. 🟠**

⏱️ **30 segundos** — Cuando la latencia objetivo no se cumple con composición paralela, o cuando el
volumen de consultas castiga demasiado a los dueños.

🗣️ **2 minutos** — Números concretos que uso: p99 de la pantalla por encima del objetivo aun con
llamadas en paralelo y lotes; o que esa pantalla represente una fracción grande del tráfico entrante a
los servicios dueños —un servicio que recibe el 80 % de sus llamadas de una sola pantalla de listado
es candidato claro—. También cuando hace falta ordenar o filtrar por campos de varios servicios, que
es imposible de componer eficientemente.

🔬 **El detalle** — El caso de ordenar y paginar por campos de dos servicios no es cuestión de
latencia: es imposible de hacer bien componiendo, porque para ordenar hay que traer todo. Ahí la
proyección no es una optimización, es la única solución razonable.

**02 → 17. La proyección se ha desincronizado. ¿Cómo lo detectas y cómo lo arreglas? 🟠**

⏱️ **30 segundos** — Se detecta con una comprobación periódica contra la fuente; se arregla
reconstruyendo, total o parcialmente.

🗣️ **2 minutos** — La detección práctica es una conciliación por muestreo: comparar recuentos y
algunos registros contra los servicios dueños, a intervalos. Para arreglar, si se sabe el rango
afectado se reprocesan esos eventos; si no, se reconstruye entera en una tabla nueva y se cambia el
puntero al terminar.

🔬 **El detalle** — La causa más frecuente no es el proyector: es un evento perdido en el emisor por
doble escritura sin outbox. Conviene mirar ahí antes de reconstruir, porque si el origen sigue
perdiendo eventos, la reconstrucción solo compra tiempo.

**02 → 18. ¿Qué almacén elegirías para una proyección con filtros y búsqueda por texto, y por qué? 🟠**

⏱️ **30 segundos** — Un índice de búsqueda, con la fuente de verdad en los servicios dueños.

🗣️ **2 minutos** — La búsqueda por texto con relevancia, filtros combinados y facetas es justo lo que
un índice hace bien y una base relacional hace mal. La condición es tratarlo siempre como derivado:
se puede borrar y reconstruir, y nadie escribe en él directamente.

🔬 **El detalle** — El riesgo típico es que el índice acabe siendo la única copia de algún dato porque
alguien escribió ahí directamente "para no complicar". A partir de ese momento ya no se puede
reconstruir, y el sistema tiene una fuente de verdad que nadie eligió tener.

**02 → 19. Te piden un listado con orden y paginación por campos de dos servicios. ¿Qué propones? 🟠**

⏱️ **30 segundos** — Proyección: componer no sirve, porque para ordenar por un campo ajeno habría que
traerlo todo.

🗣️ **2 minutos** — Con composición, paginar sobre datos de dos fuentes obliga a traer conjuntos
completos y ordenar en memoria, lo que no escala y da resultados inconsistentes entre páginas. La
proyección con ambos campos en la misma fila convierte el problema en una consulta normal con índice.

🔬 **El detalle** — Si la proyección no es viable a corto plazo, la salida intermedia es ordenar y
paginar por campos de **un solo** servicio —el dueño principal— y filtrar el resto después, aceptando
que el número de resultados por página varíe. Es peor experiencia, pero es honesto y funciona.

**02 → 20. ¿Cómo evitas que una réplica de referencia crezca hasta ser un modelo compartido? 🟠**

⏱️ **30 segundos** — Declarando por escrito qué campos se replican y por qué, y revisándolo
periódicamente.

🗣️ **2 minutos** — La regla práctica: se replica lo que es estable y se consulta constantemente, y
cada campo nuevo requiere justificar por qué no basta con preguntar. Además ayuda limitar el tamaño:
si la réplica deja de caber cómodamente en memoria o necesita su propio mantenimiento, se ha
convertido en otra cosa.

🔬 **El detalle** — Una señal de alarma clara: cuando la réplica empieza a necesitar campos que cambian
con el flujo de negocio —estados, contadores—, ya no es referencia. Ese es el momento de parar y
replantear, no de añadir un campo más.

**02 → 21. ¿Qué le respondes a un entrevistador que pregunta "¿y cómo haces el join?" en treinta segundos? 🟠**

⏱️ **30 segundos** — "Tres opciones: componer en paralelo, mantener una proyección por eventos, o
replicar datos de referencia. Empiezo por componer y paso a proyección si los números lo piden."

🗣️ **2 minutos** — La respuesta completa añade el precio de cada una —latencia y fallo compuesto;
consistencia eventual y un almacén que reconstruir; desfase tolerable— y termina con la cuarta
posibilidad: si la consulta necesita datos ajenos para decidir y no para mostrar, la frontera está
mal puesta.

🔬 **El detalle** — Mencionar la degradación por dependencia dentro de esos treinta segundos suele
cambiar la conversación: demuestra que has compuesto en producción, donde el problema no es juntar
datos sino decidir qué pasa cuando uno no responde.

**02 → 22. Diseña la proyección `order_detail_view`: qué eventos la alimentan, qué contiene, cómo se reconstruye y qué se monitoriza. 🔴**

⏱️ **30 segundos** — La alimentan los eventos de pedido, cliente y catálogo; contiene una fila por
pedido con todo lo de la pantalla; se reconstruye releyendo desde el inicio; y se vigila el retraso.

🗣️ **2 minutos** — El diseño:

```text
Eventos      OrderPlaced, OrderShipped, OrderCancelled (orders)
             CustomerUpdated (customers)    → solo nombre visible
             ProductRenamed (catalog)       → solo si el pedido NO congeló el nombre
Contenido    order_id, status, customer_id, customer_name, lines[], total,
             entrega_estimada, actualizado_en
Clave        order_id
Reconstruir  releer desde el inicio del histórico a una tabla nueva y cambiar el puntero
Monitorizar  lag del proyector en segundos, edad del evento más reciente aplicado,
             conciliación por muestreo contra orders (recuentos y 100 filas al azar)
```

🔬 **El detalle** — La decisión discutible es incluir `customer_name`: obliga a reaccionar a eventos
de `customers` y a reconstruir si cambia su formato. La alternativa —componer solo ese campo al
servir— mantiene la proyección más simple a cambio de una llamada. Ambas son defendibles y conviene
decir cuál eliges y por qué.

**02 → 23. Diagnostica: la pantalla de pedidos muestra datos de hace horas en algunos casos y actuales en otros. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Proyector atascado en una partición; eventos perdidos en el emisor; o mezcla de
fuentes —parte compuesta y parte proyectada—.

🗣️ **2 minutos** — Las tres:

```text
1. Partición atascada    el proyector procesa unas particiones y otra no (mensaje
                         envenenado o reequilibrio fallido) → explica que solo ALGUNOS
                         pedidos estén desfasados. Se ve en el lag por partición
2. Eventos perdidos      doble escritura sin outbox en el emisor: esos pedidos nunca
                         generaron evento. Se confirma buscando el id en el topic
3. Fuentes mezcladas     algunos campos se componen en vivo y otros vienen de la
                         proyección → la pantalla mezcla frescuras y parece aleatorio
```

La pista que distingue la primera es la distribución: si los pedidos desfasados comparten algo —el
mismo cliente, el mismo rango de identificadores—, es particionado.

🔬 **El detalle** — La tercera hipótesis es la más incómoda porque no es un fallo sino un diseño:
mezclar datos frescos y proyectados en la misma pantalla produce incoherencias visibles —un estado
nuevo con un total viejo—. Si es el caso, la corrección es de diseño, no de operación.

**02 → 24. Diseña la consulta de "pedidos de un cliente con filtro por estado y por producto", decidiendo entre las tres opciones y justificando con números. 🔴**

⏱️ **30 segundos** — Proyección, porque hay filtro por un campo de otro servicio —el producto— y hace
falta paginar y ordenar.

🗣️ **2 minutos** — El razonamiento:

```text
¿Composición?    para filtrar por producto habría que traer TODOS los pedidos del
                 cliente y filtrar en memoria. Con 500 pedidos y 10 líneas cada uno,
                 son 5 000 elementos por consulta: no escala y la paginación es falsa
¿Referencia?     el producto no es dato de referencia del pedido: es transaccional
¿Proyección?     una fila por (pedido, producto) o un documento por pedido con sus
                 líneas indexadas → filtro y orden nativos, un salto, paginación real

Decisión         proyección, con clave order_id e índice por (customer_id, status, product_id)
Coste            consistencia eventual de segundos; proceso y almacén; reconstrucción
```

🔬 **El detalle** — Si el volumen por cliente fuera pequeño —decenas de pedidos— la composición sería
perfectamente válida y más barata, y conviene decirlo: la respuesta correcta depende del número, y dar
el número que cambia la decisión es lo que distingue el criterio de la receta.

**02 → 25. Un equipo propone un servicio de consultas que lee de las bases de los demás "solo para leer". Responde con alternativas concretas. 🔴**

⏱️ **30 segundos** — Es la base de datos compartida con un proceso delante: acopla esquemas y crea un
punto de fallo. Hay dos alternativas concretas.

🗣️ **2 minutos** — La respuesta:

```text
Problema         ese servicio se acopla a las tablas de todos: nadie puede migrar
                 sin coordinar, y su credencial tiene permisos sobre varios esquemas
Alternativa 1    servicio de consultas que consume EVENTOS y mantiene su proyección
                 → mismo resultado, acoplado al contrato público y no al esquema
Alternativa 2    composición por API, con endpoints por lote donde haga falta
                 → sin estado nuevo, buena para consultas esporádicas
Transición       si ya existe, congelar su alcance, exponer vistas contractuales
                 en los dueños, y migrar consulta a consulta
```

🔬 **El detalle** — Conviene reconocer por qué la propuesta es tentadora: resuelve hoy un problema
real con muy poco trabajo. El argumento decisivo no es purista sino operativo: dentro de un año,
cualquier cambio de esquema de cualquier servicio requerirá coordinar con ese equipo, y eso frena a
todos los demás a la vez.

---

# 03 — Saga

**03 → 1. ¿Qué es una saga y qué garantía da que no da una transacción? 🟢**

⏱️ **30 segundos** — Una secuencia de transacciones locales con compensaciones: da atomicidad de
negocio —o se completa, o se compensa— sin necesitar una transacción que abarque varios servicios.

🗣️ **2 minutos** — Cada paso confirma en su propia base y publica lo que pasó; si un paso falla, se
ejecutan las compensaciones de los anteriores. Lo que aporta frente a no hacer nada es que el flujo
tiene un final definido en ambos casos, y que ese final es consultable.

🔬 **El detalle** — No es una elección de diseño: con servicios autónomos, bases distintas y terceros
por medio, 2PC no es aplicable, así que la saga es la única opción disponible. Decirlo así evita la
impresión de que es una preferencia estética.

**03 → 2. ¿Qué garantía *no* da una saga? 🟢**

⏱️ **30 segundos** — Aislamiento. Otros ven los estados intermedios mientras la saga está en curso.

🗣️ **2 minutos** — Eso produce tres anomalías concretas: lectura sucia —alguien lee algo que luego se
compensa—, actualización perdida y lectura no repetible. Las contramedidas son de diseño: estados
explícitos, bloqueo semántico con caducidad y relectura antes de decidir.

🔬 **El detalle** — El cambio de mentalidad que hay que hacer es que los estados intermedios son parte
del modelo de negocio, no un artefacto técnico. "Reservado pendiente de cobro" es un estado que el
negocio entiende, y modelarlo explícitamente resuelve la mitad del problema.

**03 → 3. Diferencia entre coreografía y orquestación. 🟢**

⏱️ **30 segundos** — En coreografía cada servicio reacciona a eventos y no hay coordinador; en
orquestación hay un componente con el estado del flujo que manda comandos.

🗣️ **2 minutos** — La coreografía acopla menos de forma visible pero reparte el conocimiento del
flujo: nadie sabe el estado global. La orquestación concentra la coordinación en un sitio, lo que la
hace consultable y auditable, a cambio del riesgo de que acumule reglas que no le tocan.

🔬 **El detalle** — La regla práctica para elegir: si no puedes dibujar el flujo completo en una
pizarra sin mirar el código, la coreografía dejó de servirte. Suele ocurrir alrededor del cuarto paso
o en cuanto hay ramas condicionales.

**03 → 4. ¿Qué es una compensación y en qué se diferencia de un rollback? 🟢**

⏱️ **30 segundos** — Es una operación de negocio nueva que anula el efecto de otra; el rollback
deshace y no deja rastro.

🗣️ **2 minutos** — Liberar una reserva o emitir una devolución son operaciones visibles: quedan
registradas, aparecen en el extracto y pueden tener reglas propias —una devolución puede tener
comisión—. Por eso compensar no es "volver atrás": es avanzar hasta un estado equivalente al inicial
desde el punto de vista del negocio.

🔬 **El detalle** — Hay efectos que no se pueden compensar: un correo enviado o un dato entregado a un
tercero. Para esos solo cabe una acción nueva —enviar una corrección— y por eso su posición en el
flujo importa tanto.

**03 → 5. Enumera los tres tipos de paso de una saga y dónde va cada uno. 🟢**

⏱️ **30 segundos** — Compensables al principio, el pivote en medio, y los reintentables después.

🗣️ **2 minutos** — Los compensables tienen inversa; el pivote es el punto de no retorno —normalmente
el cobro o la entrega al tercero—; y los reintentables son los que, una vez pasado el pivote, tienen
que acabar saliendo sí o sí, así que solo se reintentan. Ordenar los pasos según esta clasificación
es la mitad del diseño de una saga.

🔬 **El detalle** — Si el flujo tiene dos pasos irreversibles separados, no hay orden que lo salve: en
cuanto pasa el primero y falla el segundo, quedas en un estado sin compensación. Ahí toca renegociar
el proceso con el negocio, por ejemplo retrasando uno de los dos.

**03 → 6. Nombra dos razones por las que 2PC no se usa entre microservicios. 🟢**

⏱️ **30 segundos** — Bloquea recursos hasta la segunda fase, y el coordinador es un punto único de
fallo con estado que deja a los participantes "en duda".

🗣️ **2 minutos** — A eso se suma la razón práctica: casi nada lo soporta. Los brokers, las bases
modernas y las APIs de terceros no participan, así que en cuanto un paso está fuera del mundo
transaccional deja de ser aplicable. Sigue teniendo sentido dentro de una frontera controlada, como
una base relacional y una cola del mismo proveedor en sistemas heredados.

🔬 **El detalle** — Conviene no despacharlo con desdén en una entrevista de banca: 2PC lleva décadas
funcionando en ese entorno y quien te entrevista probablemente lo ha operado. La respuesta correcta es
"fuera de alcance aquí", no "es malo".

**03 → 7. ¿Por qué la coreografía se vuelve inmanejable a partir de cuatro pasos? 🟡**

⏱️ **30 segundos** — Porque el flujo solo existe repartido entre los consumidores: nadie lo tiene
escrito ni lo puede consultar.

🗣️ **2 minutos** — Con dos o tres pasos lineales es fácil seguir la cadena; con cuatro y alguna rama,
responder "¿por qué este pedido no avanzó?" exige reconstruir mentalmente quién reacciona a qué,
mirando el código de varios servicios. Además aumenta el riesgo de ciclos: un evento dispara otro que
vuelve al primero.

🔬 **El detalle** — El coste real no aparece cuando se construye sino cuando alguien nuevo tiene que
diagnosticar un caso concreto a las dos de la mañana. Ese es el argumento que convence, porque todo
el mundo ha estado en esa situación.

**03 → 8. ¿Qué es el paso pivote y por qué su posición es una decisión de diseño? 🟡**

⏱️ **30 segundos** — Es el punto de no retorno: a partir de él ya no se compensa, solo se reintenta.

🗣️ **2 minutos** — Colocarlo lo más tarde posible maximiza lo que se puede deshacer, así que el diseño
consiste en poner primero todo lo compensable, luego el pivote, y después lo que solo puede
reintentarse. Si el cobro es el pivote, el envío de notificaciones y la actualización de proyecciones
van después.

🔬 **El detalle** — A veces se puede mover el pivote cambiando el proceso de negocio: preautorizar el
cobro —compensable— y capturarlo al final convierte un paso irreversible en dos, uno compensable y
otro reintentable. Es un buen ejemplo de diseño técnico que mejora el proceso.

**03 → 9. ¿Qué es el bloqueo semántico y por qué necesita caducidad? 🟡**

⏱️ **30 segundos** — Marcar un registro como "en proceso" durante la saga para que otros lo vean; con
caducidad, porque si la saga muere el bloqueo quedaría para siempre.

🗣️ **2 minutos** — Es un bloqueo de negocio, no de base de datos: el stock queda `RESERVED` y otras
operaciones lo tienen en cuenta. La caducidad es lo que evita el fallo del §9 del capítulo: una saga
interrumpida que deja producto bloqueado indefinidamente. Con vencimiento, el propio dueño libera lo
que nadie confirmó.

🔬 **El detalle** — Conviene tener la caducidad en dos sitios: en la saga —que compensa si vence— y en
el recurso —que se libera solo—. Son defensas contra fallos distintos: la primera cubre que la saga
se pare, la segunda que la saga desaparezca por completo.

**03 → 10. ¿Por qué el estado de la saga y el comando saliente tienen que ir en la misma transacción? 🟡**

⏱️ **30 segundos** — Porque si no, el estado avanza y el comando se pierde —o al revés—, y la saga se
queda inconsistente consigo misma.

🗣️ **2 minutos** — Es el problema de la doble escritura aplicado al orquestador: guardar
`status = CONFIRMED` y publicar `AuthorizePayment` son dos escrituras en sistemas distintos. La solución
es la misma que en cualquier otro sitio: outbox, de forma que el mensaje se escriba en la base junto
con el estado y se publique después.

🔬 **El detalle** — Sin outbox, el fallo típico es una saga en `CONFIRMED` que nunca recibe respuesta
de `payments` porque el comando nunca salió. Y como el síntoma es "no responde", se investiga a `payments`
durante un rato antes de mirar en el sitio correcto.

**03 → 11. ¿Qué significa que "no hay aislamiento" en términos de lo que ve otro servicio? 🟡**

⏱️ **30 segundos** — Que otro servicio puede leer y actuar sobre datos que la saga todavía está
modificando y que quizá se compensen.

🗣️ **2 minutos** — En una transacción de base de datos, nadie ve tus cambios hasta que confirmas. En
una saga, cada paso confirma su parte, así que el stock reservado es visible de inmediato aunque el
cobro falle después. Por eso las contramedidas son de modelo: estados explícitos que digan
exactamente en qué situación está cada cosa.

🔬 **El detalle** — El efecto secundario positivo es que el modelo mejora: muchos sistemas
transaccionales esconden estados que el negocio sí tiene —"pendiente de confirmación", "en
verificación"— y la saga obliga a hacerlos explícitos.

**03 → 12. ¿Qué tres niveles de implementación de saga hay, y cómo se reparten entre las cuatro plataformas? 🟡**

⏱️ **30 segundos** — Tres niveles: a mano con máquina de estados y outbox, con una abstracción del
propio ecosistema, o con un motor de workflow. La elección depende más del equipo que del lenguaje.

🗣️ **2 minutos** — A mano es posible en las cuatro y es lo que hay que saber explicar siempre. Java es
donde más hecho viene: abstracciones de proceso y motores BPM muy usados en banca. En Node/TS y
Python lo habitual es a mano sobre la cola de tareas, o directamente un motor de workflow externo. En
Go, componentes de enrutado de mensajes más el estado explícito. Los motores de workflow tienen
cliente en las cuatro, así que igualan el terreno a cambio de una pieza de infraestructura más.

🔬 **El detalle** — Lo que no cambia entre plataformas es el diseño: ordenar los pasos, elegir el
pivote, escribir las compensaciones y poner vencimientos. El motor persiste y reintenta; no decide por
ti dónde está el punto de no retorno.

---
**03 → 13. ¿Cómo cambia la comparación entre plataformas cuando se usa un motor de workflow? 🟡**

⏱️ **30 segundos** — Los motores de workflow tienen cliente en las cuatro, así que igualan el terreno:
el flujo se escribe como código y el motor persiste el estado, reintenta y da visibilidad.

🗣️ **2 minutos** — Eso cambia la decisión: sin motor, la diferencia entre plataformas es grande
—Java trae abstracciones de proceso y motores BPM, y las demás lo escriben a mano—; con motor, la
diferencia casi desaparece y lo que queda es el coste de operar una pieza de infraestructura más. Por
eso la pregunta útil no es qué lenguaje usas, sino cuántos flujos largos tienes.

🔬 **El detalle** — Lo que el motor no hace en ninguna plataforma: ordenar los pasos, elegir el pivote,
escribir las compensaciones y poner los vencimientos. Persiste y reintenta; el diseño sigue siendo
tuyo, y es donde se gana o se pierde la saga.

---
**03 → 14. ¿Por qué una operación irreversible en medio del flujo obliga a renegociar el proceso? 🟠**

⏱️ **30 segundos** — Porque si un paso posterior falla, no hay forma de dejar el sistema en un estado
equivalente al inicial.

🗣️ **2 minutos** — Si envías un correo al cliente y después falla el cobro, el correo ya está enviado.
Las opciones son moverlo después del pivote —si el negocio lo acepta—, sustituirlo por algo
compensable —enviar una corrección—, o aceptar la inconsistencia con un procedimiento manual. La
decisión es de negocio, y llevarla así a la conversación es lo correcto.

🔬 **El detalle** — En pagos hay una variante elegante: preautorizar en lugar de cobrar, dejando la
captura para el final. Convierte el paso irreversible en dos, uno anulable y otro que ya solo se
reintenta, y resuelve el problema sin negociar nada.

**03 → 15. Tu saga se queda parada porque `payments` no responde ni bien ni mal. ¿Qué falta en el diseño? 🟠**

⏱️ **30 segundos** — Un vencimiento por saga: el silencio no está contemplado, solo el éxito y el
fallo explícito.

🗣️ **2 minutos** — Hace falta un plazo por paso y por saga completa, con un proceso periódico que
busque las vencidas y decida: reintentar, compensar o mandar a revisión. Y conviene además caducidad
en el recurso reservado, para que el bloqueo se libere aunque la saga desaparezca del todo.

🔬 **El detalle** — En un flujo distribuido, la ausencia de respuesta es el caso más probable y el
menos diseñado. Si alguien te pregunta qué revisarías primero en un diseño de saga ajeno, el
vencimiento es una excelente respuesta.

**03 → 16. ¿Dónde pondrías el paso pivote en la saga del capítulo y por qué? 🟠**

⏱️ **30 segundos** — En el cobro: la reserva es compensable, y todo lo posterior —notificar,
proyectar, preparar el envío— es reintentable.

🗣️ **2 minutos** — Poner el cobro al final de lo compensable maximiza lo que se puede deshacer si algo
sale mal: si falla, se libera la reserva y el pedido se cancela limpiamente. Después del cobro, el
pedido existe de verdad y los pasos restantes tienen que completarse sí o sí, con reintentos.

🔬 **El detalle** — Si el negocio exige cobrar después de preparar el envío —lo habitual en algunos
modelos de comercio—, el pivote se desplaza y hay que hacer compensable la preparación. Es un buen
ejemplo de que el orden de los pasos no lo decide la arquitectura sino el proceso real.

**03 → 17. La compensación falla tres veces. ¿Qué haces? 🟠**

⏱️ **30 segundos** — Reintentar con espera creciente hasta un límite, y después mandarlo a una bandeja
de casos atascados con alerta.

🗣️ **2 minutos** — No hay un nivel superior que compense la compensación, así que el final del camino
automático es humano. Lo importante es que ese caso quede visible, con todo el contexto —qué pasos se
ejecutaron, cuáles no—, y que exista un procedimiento para resolverlo manualmente y marcar la saga
como cerrada.

🔬 **El detalle** — Conviene distinguir el fallo transitorio del determinista: si la compensación falla
porque el recurso ya no existe —la reserva expiró sola—, eso no es un error, es un éxito con otro
nombre, y la saga debería poder reconocerlo y cerrarse.

**03 → 18. ¿Cómo evitas que el orquestador acumule reglas de negocio de los participantes? 🟠**

⏱️ **30 segundos** — Con una frontera explícita: el orquestador decide orden y compensaciones; cada
servicio decide si puede hacer lo que le piden.

🗣️ **2 minutos** — En la práctica significa que el orquestador manda `ReserveInventory` y `inventory`
responde si puede o no; el orquestador no consulta stock ni aplica reglas de disponibilidad. La señal
de alarma es cuando el orquestador empieza a necesitar datos de los participantes para decidir el
siguiente paso: ahí está absorbiendo dominio ajeno.

🔬 **El detalle** — Una revisión útil: si al leer el código del orquestador se entiende el proceso pero
no las reglas, está bien; si se entienden las reglas de negocio de tres servicios, ya es el monolito.

**03 → 19. ¿Cuándo usarías un motor de workflow en vez de una máquina de estados propia? 🟠**

⏱️ **30 segundos** — Cuando hay muchos flujos largos, con esperas, reintentos y requisitos de
auditoría o de visibilidad.

🗣️ **2 minutos** — El motor aporta persistencia del estado, reintentos, temporizadores y una vista del
avance sin escribirlo tú. Compensa cuando hay varios procesos de negocio largos; para una o dos
sagas, añade una pieza de infraestructura con su propio modelo mental y su operación, y sale más caro
que una tabla de estados.

🔬 **El detalle** — El riesgo del motor es el mismo que el de cualquier herramienta potente: que se
convierta en el sitio donde vive el negocio, con flujos enormes que nadie puede probar aisladamente.
Conviene mantener el flujo delgado y las reglas dentro de los servicios, igual que con el orquestador
propio.

**03 → 20. Diseña la contramedida para dos sagas que intentan reservar el mismo último producto. 🟠**

⏱️ **30 segundos** — La decisión la toma `inventory` en una transacción local: una reserva gana y la
otra recibe un rechazo que dispara la compensación.

🗣️ **2 minutos** — La clave es no repartir la decisión: `inventory` comprueba y reserva
atómicamente, con control de concurrencia en su propia base —condición sobre la cantidad disponible o
versión optimista—. La saga perdedora recibe `InventoryReservationFailed` y compensa. Cualquier intento de
"comprobar antes de pedir" desde fuera crea una carrera.

🔬 **El detalle** — Si el negocio prefiere no rechazar, la alternativa es aceptar sobreventa
controlada y resolverla después —avisando o compensando con un cupón—. Es una decisión de producto
perfectamente legítima, y conviene nombrarla porque muchos negocios reales la eligen.

**03 → 21. ¿Cómo explicarías a producto que existe un estado "reservado pero no pagado"? 🟠**

⏱️ **30 segundos** — Como un estado del negocio, no como un problema técnico: el producto está
apartado durante unos minutos mientras se confirma el pago.

🗣️ **2 minutos** — Conviene llevar tres datos: cuánto dura típicamente, qué pasa si el pago falla —se
libera automáticamente—, y qué ve el cliente mientras tanto. Y contrastarlo con la alternativa: sin
ese estado, o se cobra antes de saber si hay stock, o se vende lo que no existe.

🔬 **El detalle** — Es también una oportunidad de producto: ese estado permite cosas que el negocio
suele querer, como avisar al cliente de que tiene el artículo apartado durante quince minutos. Muchas
veces la conversación termina con producto pidiendo hacerlo visible.

**03 → 22. ¿Qué monitorizarías de una saga para enterarte antes que el cliente? 🟠**

⏱️ **30 segundos** — Sagas por estado, edad de la más antigua en cada estado, tasa de compensaciones y
sagas vencidas.

🗣️ **2 minutos** — La edad por estado es la métrica clave: si hay sagas en `CONFIRMED` desde hace más
de unos minutos, algo no avanza. La tasa de compensaciones detecta problemas del negocio —muchos
cobros rechazados— y la bandeja de vencidas detecta lo que ya requiere intervención. Con esas cuatro
se ve el flujo entero.

🔬 **El detalle** — Conviene alertar sobre la **distribución**, no solo sobre el total: cien sagas en
compensación puede ser normal un lunes de rebajas y grave un martes cualquiera. Comparar con la misma
hora de la semana anterior evita alertas inútiles.

**03 → 23. Diseña la saga completa del pedido: pasos, tipos, compensaciones, estados, vencimientos y qué se audita. 🔴**

⏱️ **30 segundos** — Cuatro pasos, cobro como pivote, compensación solo de la reserva, vencimientos en
dos capas, y auditoría de todas las transiciones.

🗣️ **2 minutos** — El diseño:

```text
Paso              Tipo           Compensación         Vencimiento
────────────────  ─────────────  ───────────────────  ───────────────────────
1 confirmar       local          cancelar pedido      —
2 reservar stock  compensable    liberar reserva      reserva caduca a los 30 min
3 cobrar          PIVOTE         (devolución, manual) 2 min para responder
4 notificar/enviar reintentable  —                    reintentos indefinidos con backoff

Estados      PENDING → CONFIRMED → PAID → COMPLETED
                   ↘ COMPENSATING → CANCELLED
Vencimiento  por saga: 30 min sin avanzar → compensar o revisar
             por recurso: la reserva se libera sola (defensa independiente)
Auditoría    toda transición con quién, cuándo, evento que la causó y resultado
```

🔬 **El detalle** — El paso 3 tiene la compensación entre paréntesis a propósito: una devolución
automática después de cobrar es una decisión de negocio, no técnica. En muchos casos se prefiere
completar el pedido y resolver manualmente, y el diseño debe permitir ambas.

**03 → 24. Rediseña la misma saga en coreografía y di qué pierdes y qué ganas respecto a la orquestada. 🔴**

⏱️ **30 segundos** — Cada servicio reacciona a eventos; ganas desacoplamiento y facilidad para añadir
consumidores, pierdes el estado global y la auditoría.

🗣️ **2 minutos** — El rediseño:

```text
orders     publica OrderPlaced
inventory reacciona → reserva → publica InventoryReserved | InventoryReservationFailed
payments   reacciona a InventoryReserved → cobra → publica PaymentAuthorized | PaymentRejected
inventory reacciona a PaymentRejected → libera → publica InventoryReleased
pedidos    reacciona a todo y mantiene SU estado del pedido

Ganas      añadir shipping o marketing no toca a nadie; menos infraestructura
Pierdes    el estado del flujo (solo el del pedido); auditoría repartida;
           vencimientos que hay que implementar en cada servicio por separado
```

🔬 **El detalle** — El punto discutible es el último: en coreografía, el vencimiento tiene que vivir en
cada participante, porque no hay nadie que vigile el conjunto. Es la parte que más se olvida y la que
explica por qué los flujos coreografiados se quedan colgados con más frecuencia.

**03 → 25. Diagnostica: hay stock reservado que no corresponde a ningún pedido activo. Da tres hipótesis y el plan de corrección. 🔴**

⏱️ **30 segundos** — Sagas interrumpidas sin vencimiento; compensaciones que fallaron en silencio; o
reservas duplicadas por reintentos no idempotentes.

🗣️ **2 minutos** — Las tres y su plan:

```text
1. Sagas colgadas      buscar sagas en CONFIRMED sin avanzar; si no hay vencimiento,
                       implementarlo y compensar las existentes en lote
2. Compensación fallida revisar DLQ y registros de ReleaseInventory con error;
                       reinyectar (el consumidor es idempotente) y alertar a partir de ahora
3. Reservas duplicadas  un reintento creó dos reservas para el mismo pedido;
                       comprobar con clave de idempotencia por (pedido, línea)

Corrección inmediata   conciliación: reservas sin pedido activo y con antigüedad
                       superior al plazo → liberar, registrando cada caso
Corrección estructural vencimiento en la reserva (se libera sola) + vencimiento en la saga
```

🔬 **El detalle** — La conciliación periódica merece quedarse aunque se arreglen las tres causas: en un
sistema distribuido siempre aparecerá una cuarta, y un proceso que detecta y corrige desviaciones es
más barato que garantizar que nunca ocurran.

**03 → 26. Un flujo tiene dos pasos irreversibles: cobrar y enviar un correo al cliente. Diseña el flujo de forma que siga siendo manejable. 🔴**

⏱️ **30 segundos** — Hacer compensable el cobro con preautorización, y mover el correo después del
pivote, como paso reintentable.

🗣️ **2 minutos** — El diseño:

```text
1 reservar stock       compensable
2 preautorizar cobro   compensable (se anula la preautorización)
3 CAPTURAR el cobro    PIVOTE: aquí el dinero se mueve de verdad
4 enviar correo        reintentable, DESPUÉS del pivote
5 actualizar vistas    reintentable

Si falla 3  → se anula la preautorización y se libera el stock: nada que compensar
              de forma visible para el cliente
Si falla 4  → se reintenta; el correo acabará saliendo. Y si no, hay bandeja manual
```

La clave es que con preautorización el cobro deja de ser irreversible hasta el último momento, y el
correo —lo único que no se puede deshacer— se coloca donde ya no puede fallar nada anterior.

🔬 **El detalle** — Si la pasarela no admite preautorización, la alternativa es invertir el orden:
enviar el correo solo cuando todo lo demás está confirmado, aceptando que el cliente reciba la
confirmación unos segundos más tarde. Suele ser perfectamente aceptable para el negocio y elimina el
problema entero.

---

# 04 — Outbox, inbox e idempotencia

**04 → 1. ¿Qué es el problema de la doble escritura? 🟢**

⏱️ **30 segundos** — Guardar en la base y publicar en el broker son dos escrituras en sistemas
distintos: entre ellas cabe una caída y el sistema queda inconsistente.

🗣️ **2 minutos** — Si el proceso muere después del commit y antes de publicar, el pedido existe y
nadie se entera, sin ningún error en ningún log. Invertir el orden no ayuda: publicarías un pedido que
no existe. Y no se puede meter el broker en la transacción de la base porque no participa en ella.

🔬 **El detalle** — El fallo es especialmente difícil porque es silencioso: no hay excepción ni
mensaje de error, solo un pedido que se queda quieto. Por eso la defensa no es "manejar el error"
sino un patrón que haga el desajuste imposible o detectable.

**04 → 2. ¿Qué es el patrón outbox y qué garantiza? 🟢**

⏱️ **30 segundos** — Escribir el mensaje en una tabla de la misma base y en la misma transacción que
el cambio; un proceso aparte lo publica después.

🗣️ **2 minutos** — Garantiza que si el cambio de negocio ocurrió, el mensaje existe y acabará
publicándose. No garantiza que se publique una sola vez: si el publicador muere entre publicar y
marcar, publicará otra vez. Es al-menos-una-vez por diseño.

🔬 **El detalle** — Hay una ventaja operativa que se olvida: el servicio ya no depende del broker para
completar la petición. Eso saca al broker del readiness y hace que una caída del broker no impida
aceptar pedidos.

**04 → 3. Enumera las columnas de la tabla de outbox y para qué sirve cada una. 🟢**

⏱️ **30 segundos** — Identificador del mensaje, tipo y id del agregado, tipo de evento, contenido,
fecha de creación y marca de publicación.

🗣️ **2 minutos** — El identificador es la clave de deduplicación del consumidor; el agregado sirve
para enrutar y para elegir la partición, de modo que los eventos del mismo pedido mantengan orden; el
tipo permite al consumidor decidir; el contenido es el evento serializado; la fecha ordena y ayuda a
diagnosticar; y la marca de publicación distingue lo pendiente.

🔬 **El detalle** — El índice importante es sobre lo pendiente —los no publicados—, no sobre toda la
tabla: el publicador consulta constantemente y, sin ese índice parcial, la consulta se degrada a
medida que la tabla crece.

**04 → 4. ¿Qué es el inbox y en qué transacción se escribe? 🟢**

⏱️ **30 segundos** — Una tabla de mensajes ya procesados, escrita en la **misma transacción** que el
efecto del consumidor.

🗣️ **2 minutos** — Es la simétrica del outbox. Si el identificador ya está, el mensaje se descarta; si
no, se inserta y se aplica el efecto, todo junto. La atomicidad es lo que cierra la ventana: no puede
quedar el efecto aplicado sin marca ni la marca sin efecto.

🔬 **El detalle** — Cuando el efecto no es transaccional —una llamada a un tercero— esta garantía no
se puede tener. La salida es registrar la intención antes de llamar y el resultado después, y al
reintentar consultar al tercero por esa referencia.

**04 → 5. Nombra las cuatro formas de conseguir idempotencia. 🟢**

⏱️ **30 segundos** — Operación idempotente por naturaleza, clave natural única, clave de idempotencia
del cliente, y tabla de mensajes procesados.

🗣️ **2 minutos** — La primera es la mejor porque no necesita nada: poner un estado a un valor fijo se
puede repetir. La segunda deja el trabajo a la base con un índice único. La tercera es la de las APIs
HTTP. La cuarta es el caso general y el que más disciplina exige.

🔬 **El detalle** — Conviene elegir la más simple que funcione: muchas operaciones que parecen
incrementales se pueden reescribir como asignación de estado final, y eso elimina el problema en vez
de gestionarlo.

**04 → 6. ¿Quién genera la clave de idempotencia y con qué criterio? 🟢**

⏱️ **30 segundos** — El cliente, una por **intención**, y la repite en todos los reintentos de esa
intención.

🗣️ **2 minutos** — Si la genera el servidor, no sirve de nada: cada reintento traería una clave nueva
y se ejecutaría otra vez. Y si el cliente la genera por intento en vez de por intención, ocurre lo
mismo. La clave identifica "este cobro que quiero hacer", no "esta petición HTTP".

🔬 **El detalle** — El servidor debe además rechazar la misma clave con un cuerpo distinto: si no lo
comprueba, una clave reutilizada por error devuelve el resultado de otra operación, que es un fallo
mucho peor que el duplicado que se quería evitar.

**04 → 7. ¿Por qué invertir el orden —publicar antes de guardar— no resuelve nada? 🟡**

⏱️ **30 segundos** — Porque entonces puedes publicar un evento de algo que nunca ocurrió si la
escritura falla después.

🗣️ **2 minutos** — Cambias "pedido sin evento" por "evento sin pedido", que suele ser peor: los
consumidores reservan stock y cobran por algo inexistente. Con el orden original al menos el estado
del sistema es correcto aunque nadie se entere; con el invertido, el estado es incorrecto en varios
servicios.

🔬 **El detalle** — Hay un caso donde publicar antes es defendible: cuando el evento es una intención
y no un hecho —"solicitud recibida"—, y el consumidor sabe que aún puede cancelarse. Pero eso es otro
diseño, no una solución a la doble escritura.

**04 → 8. ¿Por qué el outbox garantiza duplicados en vez de evitarlos? 🟡**

⏱️ **30 segundos** — Porque publicar y marcar como publicado son dos operaciones: si el proceso muere
entre ambas, el mensaje se publica otra vez.

🗣️ **2 minutos** — No hay forma de evitarlo sin una transacción entre la base y el broker, que es
justo lo que no existe. Por eso el outbox se diseña asumiendo al-menos-una-vez y se combina siempre
con consumidores idempotentes. Quien presenta el outbox como solución completa a la entrega exacta,
no lo ha operado.

🔬 **El detalle** — Marcar antes de publicar sería peor: si falla la publicación, el mensaje queda
marcado y nunca sale. Entre perder y duplicar, siempre se elige duplicar, porque la idempotencia lo
resuelve y la pérdida no.

**04 → 9. Diferencia entre CDC sobre el outbox y CDC sobre las tablas de negocio. 🟡**

⏱️ **30 segundos** — Sobre el outbox publicas eventos que tú diseñaste; sobre las tablas publicas tu
esquema físico como contrato.

🗣️ **2 minutos** — La primera es una forma excelente de publicar: baja la latencia respecto al sondeo
y no toca el código de escritura. La segunda hace que los consumidores dependan de tus columnas, así
que cualquier cambio de esquema los rompe; es la base de datos compartida con un paso intermedio.

🔬 **El detalle** — CDC sobre tablas sí es legítimo dentro de tu propia frontera: replicar a un almacén
analítico o alimentar una proyección propia. El problema no es la técnica, es publicarla como contrato
entre equipos.

**04 → 10. ¿Por qué "comprobar si existe y luego insertar" tiene una carrera? 🟡**

⏱️ **30 segundos** — Porque dos consumidores pueden comprobar a la vez, ver que no existe, y ambos
insertar y aplicar el efecto.

🗣️ **2 minutos** — Es el caso clásico de comprobación y acción no atómicas. La solución es un único
paso: insertar con índice único y tratar el fallo como "ya procesado". La base de datos resuelve la
exclusión por ti, que es exactamente para lo que sirve.

🔬 **El detalle** — Con reequilibrios de consumidores esta carrera no es teórica: dos instancias pueden
recibir el mismo mensaje momentáneamente. Es uno de los casos donde el duplicado llega casi
simultáneamente, que es justo cuando la comprobación previa falla.

**04 → 11. ¿Qué ventaja operativa da el outbox respecto a la dependencia del broker? 🟡**

⏱️ **30 segundos** — Que el servicio puede completar sus peticiones aunque el broker esté caído: solo
escribe en su base.

🗣️ **2 minutos** — Eso cambia decisiones concretas: el broker sale del readiness del servicio, la
caída del broker deja de ser una caída del negocio, y la recuperación es automática —cuando vuelve,
el publicador vacía lo acumulado—. Es un argumento de disponibilidad, no solo de consistencia.

🔬 **El detalle** — El límite es el espacio: si el broker está caído mucho tiempo, la tabla crece y hay
que vigilarla. Conviene una alerta sobre el número de pendientes, que además es la señal más temprana
de que el publicador se ha parado.

**04 → 12. ¿Por qué la clave de idempotencia debe registrarse antes de ejecutar y no después? 🟡**

⏱️ **30 segundos** — Para que un reintento que llega mientras la primera ejecución está en curso no
lance una segunda ejecución en paralelo.

🗣️ **2 minutos** — Si se registra al terminar, dos peticiones con la misma clave pueden solaparse y
ejecutar el efecto dos veces. Registrando al empezar, la segunda encuentra la clave en estado "en
progreso" y responde que ya se está procesando, que es la respuesta correcta.

🔬 **El detalle** — Hay que decidir qué pasa si la primera ejecución muere dejando la clave "en
progreso" para siempre: se resuelve con un plazo tras el cual la clave se considera abandonada y se
puede reintentar, igual que el vencimiento de una saga.

**04 → 13. ¿Qué te da cada plataforma para el outbox, y qué te deja a ti en las cuatro? 🟡**

⏱️ **30 segundos** — Java tiene módulos que lo implementan atado a la transacción; Go, componentes que
lo incluyen; Node/TS y Python se escriben a mano sobre el cliente de base de datos.

🗣️ **2 minutos** — La mecánica es idéntica en las cuatro —tabla escrita en la misma transacción,
publicador que la vacía, deduplicación con índice único— y lo que cambia son días de trabajo por
servicio. En Java se configura; en Go se ensambla con componentes; en Node/TS y Python se escribe el
publicador, su reclamación exclusiva de filas y sus métricas. Y en **ninguna** de las cuatro viene
incluida la limpieza de la tabla.

🔬 **El detalle** — Por eso esto pertenece al chassis y no a cada servicio: escrito tres veces por tres
personas, acaba con tres comportamientos distintos ante el mismo fallo. La diferencia entre
plataformas importa mucho menos si el patrón se resuelve una sola vez y bien.

---
**04 → 14. ¿Cuándo aceptarías publicar directamente al broker sin outbox? 🟡**

⏱️ **30 segundos** — Cuando perder el mensaje no tenga consecuencias: telemetría, métricas,
notificaciones prescindibles.

🗣️ **2 minutos** — El outbox cuesta una tabla, un proceso, latencia y limpieza. Si el mensaje es una
señal auxiliar y su pérdida ocasional no rompe nada, publicar directo es razonable. La prueba es
preguntarse qué pasa si se pierde uno de cada mil: si la respuesta es "nada", no hace falta outbox.

🔬 **El detalle** — Conviene no aplicar ese razonamiento a eventos de dominio aunque hoy no los
consuma nadie crítico: los consumidores se añaden con el tiempo, y el que llegue mañana asumirá que
el flujo es fiable. La decisión se toma por la naturaleza del evento, no por sus consumidores
actuales.

**04 → 15. Tu tabla de outbox tiene 40 millones de filas. ¿Qué pasó y qué haces? 🟠**

⏱️ **30 segundos** — Nadie implementó la limpieza. Se borra lo publicado con antigüedad suficiente, en
lotes, y se añade un proceso periódico.

🗣️ **2 minutos** — El borrado masivo hay que hacerlo por lotes para no bloquear ni llenar el log de
transacciones; y conviene revisar el índice de pendientes, que con una tabla así ya estará degradando
las consultas del publicador. Después, un proceso periódico que borre lo publicado con más de unos
días.

🔬 **El detalle** — Si la tabla sigue creciendo tras la limpieza, el problema no es la retención: hay
mensajes que no se están publicando. Conviene comprobar cuántos pendientes hay realmente antes de
concluir que solo faltaba borrar.

**04 → 16. El publicador de outbox se ejecuta en tres instancias. ¿Qué problema tienes y cómo lo resuelves? 🟠**

⏱️ **30 segundos** — Las tres leen las mismas filas y publican duplicados. Se resuelve con bloqueo al
leer o con reparto por partición.

🗣️ **2 minutos** — La solución simple es que cada instancia reclame filas en exclusiva al leerlas
—bloqueo con salto de las bloqueadas—, de modo que ninguna procese lo de otra. La alternativa es
repartir por rango o por identificador de agregado, que además preserva el orden por agregado. Y en
cualquier caso, como puede haber duplicados, el consumidor sigue siendo idempotente.

🔬 **El detalle** — Hay una tercera opción: dejar un solo publicador activo con elección de líder. Es
más simple de razonar y limita el rendimiento a una instancia; suele bastar, porque publicar es
barato comparado con procesar.

**04 → 17. ¿Qué clave de deduplicación elegirías para el consumidor de `inventory`? Justifica. 🟠**

⏱️ **30 segundos** — La clave de negocio `(order_id, type)` mejor que el identificador del mensaje,
porque protege también contra reenvíos manuales.

🗣️ **2 minutos** — Con el identificador del mensaje, un reproceso desde la DLQ que genere un
identificador nuevo volvería a reservar. Con la clave de negocio, cualquier intento de reservar dos
veces el mismo pedido se detecta, venga de donde venga. El requisito es estar seguro de que esa
combinación no puede repetirse legítimamente.

🔬 **El detalle** — Si el negocio permite reservar dos veces el mismo pedido —por ejemplo, una
ampliación de líneas—, la clave tiene que incluir algo más, como el identificador de la línea o una
versión. Elegir la clave es modelar el dominio, no una decisión técnica.

**04 → 18. El efecto del consumidor es llamar a un tercero no idempotente. ¿Cómo lo haces seguro? 🟠**

⏱️ **30 segundos** — Registrando la intención antes de llamar y el resultado después, y consultando al
tercero por esa referencia antes de repetir.

🗣️ **2 minutos** — El flujo es: guardar "voy a llamar con la referencia X", llamar, guardar el
resultado. Si el proceso muere en medio, el reintento encuentra la intención sin resultado y consulta
al tercero por X. Si el tercero no permite consultar ni acepta clave de idempotencia, hay que elegir
entre arriesgar duplicado u omisión, y eso lo decide el negocio.

🔬 **El detalle** — En pagos la elección habitual es preferir la omisión y conciliar después: es más
barato detectar un cobro que falta que devolver uno duplicado. Plantearlo como decisión de negocio, y
no técnica, es lo que distingue la respuesta.

**04 → 19. Diseña la política de retención de las tablas de outbox e inbox. 🟠**

⏱️ **30 segundos** — Borrar lo publicado o procesado pasada la ventana en la que un duplicado es
plausible: del orden de días, con margen.

🗣️ **2 minutos** — La ventana del inbox la marca la retención del broker y el tiempo máximo de
reproceso: si puedes reinyectar mensajes de hasta siete días, la tabla tiene que guardar al menos
esos siete días más margen. En el outbox, la ventana la marca el tiempo que quieras poder diagnosticar
qué se publicó. Y el borrado va por lotes y en horario de baja carga.

🔬 **El detalle** — Un error caro: borrar del inbox antes que la retención del broker. Si un mensaje
viejo se reentrega tras la limpieza, se procesará como nuevo y el efecto se duplicará — exactamente
lo que la tabla evitaba.

**04 → 20. ¿Cómo comprobarías que la idempotencia de un consumidor funciona de verdad? 🟠**

⏱️ **30 segundos** — Con una prueba que procese el mismo mensaje dos veces y compruebe que el estado
final es idéntico y el efecto se aplicó una sola vez.

🗣️ **2 minutos** — Conviene además una prueba del caso difícil: fallo entre el efecto y la
confirmación, simulando que el proceso muere ahí. Y en producción, una métrica de duplicados
descartados: si nunca descarta nada, o el sistema no tiene duplicados —improbable— o el mecanismo no
está haciendo lo que crees.

🔬 **El detalle** — Es la prueba que casi nadie escribe, y es barata: procesar dos veces el mismo
mensaje en un test de integración con la base real. Mencionarla en una entrevista de testing suele
destacar, porque es concreta y se nota que viene de haber tenido el problema.

**04 → 21. Un equipo propone CDC sobre sus tablas para publicar eventos a otros servicios. Responde. 🟠**

⏱️ **30 segundos** — Eso publica el esquema físico como contrato: cualquier cambio de columna rompe a
los consumidores. Mejor CDC sobre una tabla de outbox.

🗣️ **2 minutos** — Con CDC sobre las tablas, los consumidores acaban conociendo tu modelo interno y
pierdes la libertad de cambiarlo, que era el motivo de separar. Con CDC sobre el outbox obtienes lo
mismo que buscaban —baja latencia, sin tocar el código de escritura— pero publicando eventos que tú
has diseñado.

🔬 **El detalle** — Conviene reconocer el caso en que su propuesta es válida: replicar a un almacén
analítico o alimentar una proyección propia dentro de su frontera. Ahí CDC sobre tablas es la
herramienta correcta y no hay contrato entre equipos de por medio.

**04 → 22. ¿Qué riesgo específico tiene el publicador de outbox según cómo lo lance cada plataforma? 🟠**

⏱️ **30 segundos** — Que el publicador se solape consigo mismo y publique dos veces: pasa sobre todo
cuando se implementa como tarea periódica, que es lo habitual en Python y en Node/TS.

🗣️ **2 minutos** — Si una ejecución tarda más que el intervalo, arranca otra en paralelo y ambas leen
las mismas filas pendientes. Se resuelve con reclamación exclusiva de filas —bloqueo que salta las ya
tomadas— o con ejecución única por elección de líder. En Go y Java, donde el publicador suele ser un
bucle propio con su ticker, el riesgo es el mismo si se lanza en varias instancias sin exclusión.

🔬 **El detalle** — El duplicado no rompe nada si el consumidor es idempotente, pero ensucia métricas y
multiplica trabajo. Y hay una consecuencia peor si no hay exclusión y el orden importa: dos
publicadores pueden emitir mensajes del mismo agregado desordenados.

---
**04 → 23. Diseña el publicador de outbox completo: consulta, orden, concurrencia, marcado, reintentos, métricas y limpieza. 🔴**

⏱️ **30 segundos** — Lee pendientes por orden con bloqueo exclusivo, publica, marca en la misma
transacción de lectura, reintenta con espera, y borra lo viejo periódicamente.

🗣️ **2 minutos** — El diseño:

```text
Consulta     SELECT ... WHERE published_at IS NULL ORDER BY created_at
             LIMIT 100 FOR UPDATE SKIP LOCKED   ← permite varias instancias
Orden        por agregado: los mensajes del mismo pedido, en orden de creación
Publicación  al broker con la clave de particionado = aggregate_id
Marcado      published_at en la misma transacción que reclamó las filas
Reintentos   si falla la publicación, no se marca: se reintenta en la pasada siguiente
             con contador y, superado el límite, se aísla y se alerta
Métricas     pendientes, antigüedad del más viejo, publicados/s, fallos
Limpieza     borrado por lotes de publicados con más de N días
```

🔬 **El detalle** — La métrica que más rinde es la antigüedad del mensaje pendiente más viejo: detecta
tanto que el publicador está parado como que un mensaje concreto está atascado, y es una sola alerta
para dos fallos distintos.

**04 → 24. Diagnostica: el pedido está confirmado, el evento está en `outbox_events` sin publicar desde hace dos horas, y el publicador no registra errores. Da tres hipótesis. 🔴**

⏱️ **30 segundos** — El publicador no está corriendo; está corriendo pero no ve esas filas; o está
atascado en un mensaje anterior.

🗣️ **2 minutos** — Las tres:

```text
1. No está corriendo        el proceso murió o no se desplegó; "sin errores" encaja
                            perfectamente con "no hay proceso". Se comprueba con su
                            métrica de latido o de publicados por segundo
2. No ve esas filas         consulta filtrada por algo —tipo, agregado, rango de fechas—
                            o está leyendo de otra instancia/esquema tras una migración
3. Atascado antes           procesa en orden y hay un mensaje anterior que falla en
                            silencio; todo lo posterior espera detrás
```

La distinción rápida: si hay otros mensajes publicándose con normalidad, es la 2 o la 3; si no
publica nada, es la 1.

🔬 **El detalle** — El caso 3 revela un fallo de diseño frecuente: procesar estrictamente en orden
global sin aislamiento hace que un solo mensaje problemático detenga todo el flujo. Conviene ordenar
por agregado y permitir que los demás avancen.

**04 → 25. Diseña el soporte de `Idempotency-Key` en `POST /payments`: qué guardas, en qué transacción, qué devuelves en cada caso y cuánto lo retienes. 🔴**

⏱️ **30 segundos** — Guardas clave, huella del cuerpo, estado y respuesta; registras al empezar;
devuelves la respuesta guardada si se repite; y retienes 24 horas o más.

🗣️ **2 minutos** — El diseño:

```text
Tabla        key, body_hash, status(IN_PROGRESS|OK|ERROR), response, created_at
Al recibir   INSERT de la clave en estado IN_PROGRESS, en la MISMA transacción que
             empieza el cobro. Si ya existe:
               · huella distinta          → 422: clave reutilizada con otro cuerpo
               · estado IN_PROGRESS       → 409: petición en progreso
               · estado OK/ERROR          → se devuelve la respuesta guardada, con el
                                            mismo código de estado original
Al terminar  actualizar estado y respuesta en la transacción del efecto
Vencimiento  IN_PROGRESS con más de N minutos se considera abandonada y se puede repetir
Retención    24-72 h, alineada con la política de reintentos de los clientes
```

🔬 **El detalle** — Devolver la respuesta original guardada, y no una respuesta nueva equivalente, es
lo que hace el patrón predecible para el cliente: el reintento ve exactamente lo mismo que vería si no
se hubiera perdido la respuesta, incluido el identificador del cobro creado.

**04 → 26. Un consumidor debe actualizar su base y llamar a un tercero. Diseña el flujo garantizando que no se duplica el efecto en el tercero. 🔴**

⏱️ **30 segundos** — Dividir en dos pasos con estado persistido: registrar la intención con una
referencia, llamar, y registrar el resultado; reintentar consultando por la referencia.

🗣️ **2 minutos** — El flujo:

```text
1. Transacción local: deduplicar el mensaje + registrar intención
   (referencia = uuid determinista a partir del mensaje) en estado PENDING
2. Llamar al tercero pasando la referencia como clave de idempotencia
3. Transacción local: guardar el resultado y pasar a COMPLETED
4. Al reintentar: si la intención está PENDING, primero CONSULTAR al tercero
   por la referencia; solo si no existe allí, volver a llamar
5. Si el tercero no admite consulta ni clave: decidir con negocio entre
   arriesgar duplicado o dejarlo para conciliación manual
```

🔬 **El detalle** — El punto fino es generar la referencia de forma determinista a partir del mensaje
—no aleatoria—, de modo que el reintento produzca la misma y el tercero pueda reconocerla. Con una
referencia aleatoria por intento, la clave de idempotencia del tercero deja de servir para nada.

---

# 05 — Evolución de esquema y migraciones

**05 → 1. ¿Por qué toda migración tiene que ser compatible con el código que ya corre? 🟢**

⏱️ **30 segundos** — Porque durante un despliegue gradual conviven instancias con código viejo y
nuevo contra la misma base.

🗣️ **2 minutos** — Si la migración renombra o elimina algo que el código viejo usa, esas instancias
fallan durante todo el reemplazo, que puede durar minutos. Y si además hay que revertir, el rollback
del código deja un esquema que el código anterior no entiende. La compatibilidad es lo que permite
desplegar sin coordinar, que era el objetivo de separar servicios.

🔬 **El detalle** — La excepción es tener una ventana de parada concedida: entonces se puede migrar de
golpe. Lo que no vale es asumir que existe esa ventana sin haberla negociado.

**05 → 2. Enumera los seis pasos de expand/contract sobre un renombrado de columna. 🟢**

⏱️ **30 segundos** — Añadir la columna nueva; escribir en ambas; copiar los datos; cambiar la lectura;
dejar de escribir en la vieja; eliminarla.

🗣️ **2 minutos** — Cada paso es compatible con el código que hay corriendo, y por eso se pueden
desplegar por separado y revertir individualmente. En una tabla pequeña y un servicio con poco
tráfico se puede comprimir; en una tabla grande o crítica, no se salta ninguno.

🔬 **El detalle** — El paso que más se olvida es el quinto: dejar de escribir en la vieja antes de
borrarla. Si se elimina mientras el código todavía escribe ahí, el fallo aparece en las escrituras,
que suele ser el peor sitio.

**05 → 3. Nombra tres cambios de esquema seguros y tres inseguros. 🟢**

⏱️ **30 segundos** — Seguros: añadir tabla, añadir columna nullable, eliminar una restricción.
Inseguros: eliminar columna, renombrar, añadir columna obligatoria sin defecto.

🗣️ **2 minutos** — El criterio es si el código viejo sigue funcionando: una columna nullable la
ignora; una obligatoria sin defecto hace fallar sus `INSERT`. Y hay una categoría intermedia
peligrosa: cambios lógicamente seguros que bloquean la tabla, como crear un índice o añadir una
columna con valor por defecto en tablas grandes.

🔬 **El detalle** — Añadir una restricción también es inseguro por dos motivos a la vez: los datos
existentes pueden incumplirla y el código viejo puede seguir insertando datos que la violan. Se hace
validando primero, corrigiendo y aplicando al final.

**05 → 4. ¿Cómo se hace un backfill correctamente? 🟢**

⏱️ **30 segundos** — Por lotes, por rango de clave, con transacciones cortas, guardando el progreso y
con pausa entre lotes.

🗣️ **2 minutos** — Un `UPDATE` sobre toda la tabla bloquea, llena el log de transacciones y, si falla,
lo pierde todo. Por lotes con reanudación se puede parar y continuar; con pausa, no compite con el
tráfico real. Y por rango de clave en lugar de desplazamiento, porque el desplazamiento se degrada a
medida que avanza.

🔬 **El detalle** — Conviene ejecutarlo como un proceso con control —arrancar, parar, ver progreso—, no
como un script lanzado a mano. La diferencia se nota el día que hay que detenerlo porque la base está
sufriendo.

**05 → 5. ¿Cuáles son las tres opciones de quién ejecuta la migración? 🟢**

⏱️ **30 segundos** — Al arrancar la aplicación, como paso del pipeline antes de desplegar, o
manualmente.

🗣️ **2 minutos** — El arranque es cómodo y no se olvida, pero con varias instancias hace falta
exclusión y un fallo se convierte en bucle de reinicios. El pipeline es la recomendación: el fallo es
visible y aislado, y permite desplegar y revertir el código sin tocar la base. Lo manual solo para
cambios delicados y siempre versionado.

🔬 **El detalle** — La consecuencia práctica de elegir el pipeline es que la migración tiene que ser
compatible hacia atrás por fuerza, porque se ejecuta antes de que exista el código que la aprovecha.
Esa restricción es justamente lo que hace seguro el modelo.

**05 → 6. ¿Qué cambios de esquema no tienen vuelta atrás? 🟢**

⏱️ **30 segundos** — Eliminar una columna o una tabla, y cualquier cambio de tipo con pérdida de
información.

🗣️ **2 minutos** — Lo demás se revierte: una columna añadida se puede dejar, un backfill no molesta, y
un cambio de lectura se revierte con el despliegue. Por eso las operaciones destructivas se separan en
el tiempo: se ejecutan días después, cuando ya nadie va a volver atrás.

🔬 **El detalle** — La copia de seguridad no cuenta como vuelta atrás: restaurar tarda horas y pierde
todo lo escrito desde el punto de restauración. Sirve para el desastre, no para revertir un
despliegue de las 10 de la mañana.

**05 → 7. ¿Por qué añadir una columna obligatoria sin valor por defecto rompe al código viejo? 🟡**

⏱️ **30 segundos** — Porque el código viejo no la incluye en sus `INSERT` y la base rechaza la
operación.

🗣️ **2 minutos** — Mientras haya una sola instancia con la versión anterior, sus escrituras fallarán.
La salida es añadirla como nullable o con valor por defecto, desplegar el código que la rellena, hacer
backfill de lo existente, y solo entonces imponer la obligatoriedad.

🔬 **El detalle** — Añadirla con valor por defecto es seguro para el código pero puede ser caro para
la base: en algunos motores y versiones eso reescribe la tabla entera. Hay que comprobarlo antes en
una tabla de tamaño comparable.

**05 → 8. ¿Qué significa que una migración sea "lógicamente segura y operativamente peligrosa"? 🟡**

⏱️ **30 segundos** — Que no rompe a ningún código pero puede bloquear la tabla el tiempo suficiente
para tumbar el servicio.

🗣️ **2 minutos** — Crear un índice o añadir una columna con defecto no afectan a la compatibilidad,
pero en una tabla de decenas de millones de filas pueden mantener bloqueos durante minutos. El
resultado es un incidente causado por una migración que todo el mundo consideraba inocua.

🔬 **El detalle** — Depende del motor y de su versión: hay formas de crear índices sin bloquear y hay
cambios de metadatos que son instantáneos en versiones recientes y reescriben la tabla en versiones
anteriores. Es de las pocas cosas donde hay que leer la documentación de **tu** versión concreta.

**05 → 9. ¿Por qué el backfill por `OFFSET` se degrada y el de rango no? 🟡**

⏱️ **30 segundos** — Porque el desplazamiento obliga al motor a recorrer y descartar todas las filas
anteriores en cada lote.

🗣️ **2 minutos** — Con desplazamiento un millón, el motor recorre un millón de filas para devolver
cien. El coste crece con el avance, así que el backfill empieza rápido y acaba parado. Con rango de
clave —"desde el último identificador procesado"— cada lote usa el índice y cuesta lo mismo al
principio que al final.

🔬 **El detalle** — El rango de clave da además reanudación gratis: guardar la última clave procesada
es todo el estado que necesitas para continuar. Con desplazamiento, reanudar exige recalcular la
posición, que puede haber cambiado si hubo borrados.

**05 → 10. ¿Por qué la contracción no va en el mismo despliegue que el cambio de código? 🟡**

⏱️ **30 segundos** — Porque si hay que revertir el código en los minutos siguientes, la columna ya no
está.

🗣️ **2 minutos** — El despliegue que cambia comportamiento debe poder revertirse solo con el código,
sin tocar la base. Eliminar en el mismo paso convierte una vuelta atrás trivial en una restauración de
datos. Por eso la contracción se programa días después, cuando la versión nueva lleva tiempo estable.

🔬 **El detalle** — Un criterio práctico: la contracción se hace cuando ya no queda ninguna versión
anterior desplegable en producción, es decir, cuando revertir tan atrás ya no es una opción realista
por otros motivos.

**05 → 11. ¿Por qué una copia de seguridad no es un plan de vuelta atrás? 🟡**

⏱️ **30 segundos** — Porque restaurar tarda horas y pierde todo lo escrito desde el punto de
restauración.

🗣️ **2 minutos** — Un plan de vuelta atrás tiene que ejecutarse en minutos y sin pérdida de datos:
eso solo lo cumple revertir el código sobre un esquema compatible. La copia cubre el desastre —datos
corrompidos, borrado accidental masivo— y ahí es imprescindible, pero no es la red de seguridad de un
despliegue.

🔬 **El detalle** — La pregunta que lo aclara en una reunión: "si revertimos a las 10:15, ¿qué pasa con
los pedidos creados entre las 10:00 y las 10:15?". Con restauración, se pierden; con vuelta atrás de
código, no.

**05 → 12. ¿Qué genera tu herramienta cuando renombras un campo, y por qué importa? 🟡**

⏱️ **30 segundos** — Casi siempre eliminar y crear, que es el cambio destructivo que hay que evitar.

🗣️ **2 minutos** — Las herramientas que comparan modelo y base no pueden saber que un campo se
renombró: ven uno que desapareció y otro nuevo. Aplicar esa migración generada borra los datos de la
columna vieja. Por eso toda migración generada se revisa, y los renombrados se escriben a mano en
varios pasos.

🔬 **El detalle** — Es una buena pregunta para hacer en una entrevista al revés: preguntar al equipo
qué hace su herramienta con un renombrado dice mucho sobre cuánto han sufrido esto. Si nadie lo sabe,
probablemente aún no les ha pasado.

**05 → 13. ¿Qué pondrías en la revisión de código de toda migración? 🟡**

⏱️ **30 segundos** — Compatibilidad con el código actual, tamaño de la tabla y tiempo estimado,
bloqueos, y plan de vuelta atrás.

🗣️ **2 minutos** — La lista de comprobación:

```text
· ¿Es compatible con el código que está corriendo ahora mismo?
· ¿Cuántas filas tiene la tabla y cuánto tarda en una copia de tamaño real?
· ¿Bloquea? ¿Qué hace este motor y esta versión con esta operación?
· ¿Hay borrados o cambios de tipo? → ¿van en un despliegue aparte?
· ¿Se generó automáticamente? → ¿alguien leyó el SQL?
· ¿Cómo se revierte, y en cuánto tiempo?
```

🔬 **El detalle** — El punto sobre la generación automática es el que más incidentes evita en equipos
que usan herramientas declarativas: leer el SQL generado antes de aprobarlo detecta los borrados
accidentales, que es el fallo más caro y el más silencioso en revisión.

**05 → 14. ¿Dónde se ejecuta la migración por defecto en cada plataforma, y por qué eso condiciona el despliegue? 🟡**

⏱️ **30 segundos** — En Java, integrada en el arranque de la aplicación por defecto; en Go, un binario
independiente que encaja como paso del pipeline; en Node/TS y Python, una orden de la herramienta que
alguien decide cuándo lanzar.

🗣️ **2 minutos** — El valor por defecto de Java es el más cómodo y el que peor escala: con varias
instancias arrancando a la vez hace falta exclusión, y un fallo de migración se convierte en un bucle
de reinicios. El de Go empuja de forma natural a lo correcto —migrar antes de desplegar el código—
porque la herramienta ni siquiera vive dentro del servicio. En Node/TS y Python la decisión es
explícita y suele acabar en el pipeline si alguien la toma a propósito.

🔬 **El detalle** — Lo que condiciona el despliegue no es la herramienta sino la consecuencia: si la
migración va atada al arranque, no puedes revertir el código sin dejar el esquema por delante. Por eso
la recomendación es la misma en las cuatro —paso explícito del pipeline y migración compatible hacia
atrás— aunque el camino para llegar sea distinto en cada una.

---

**05 → 15. Tienes que añadir una columna obligatoria a una tabla de 40 millones de filas. Da el plan. 🟠**

⏱️ **30 segundos** — Añadirla nullable, desplegar el código que la escribe, backfill por lotes, y
solo al final imponer la obligatoriedad.

🗣️ **2 minutos** — El plan:

```text
1. ALTER: columna nullable, sin valor por defecto (metadato, rápido)
2. Desplegar código que la escribe en toda inserción y actualización
3. Backfill por lotes con rango de clave, pausa y reanudación
4. Verificar: contar filas con valor nulo → debe ser cero
5. Añadir la restricción de obligatoriedad (validando, según el motor)
```

El paso 1 evita el valor por defecto a propósito, porque en tablas grandes puede reescribir la tabla
entera según el motor y la versión.

🔬 **El detalle** — Entre el paso 2 y el 4 hay que vigilar que no se creen filas nuevas sin valor: si
alguna ruta de escritura se olvidó, el recuento del paso 4 nunca llega a cero y conviene descubrirlo
por la métrica y no por el fallo del paso 5.

**05 → 16. ¿Cuándo aceptarías una ventana de parada en vez de expand/contract? 🟠**

⏱️ **30 segundos** — Cuando el negocio la concede, la migración es corta y el riesgo de hacerla en
caliente es alto.

🗣️ **2 minutos** — En banca hay ventanas de mantenimiento reales y usarlas puede ser más seguro y
mucho más barato que seis despliegues. La condición es que la migración esté probada y cronometrada
en una copia de tamaño real, y que exista un plan si se pasa del tiempo. Lo que no vale es asumir la
ventana sin negociarla ni medir cuánto tarda.

🔬 **El detalle** — Conviene tener preparada la alternativa por si la migración se alarga: un punto de
decisión a mitad de la ventana donde, si no ha terminado, se aborta y se vuelve atrás. Sin ese punto,
las ventanas se convierten en madrugadas.

**05 → 17. El backfill está degradando la base en horas punta. ¿Qué haces? 🟠**

⏱️ **30 segundos** — Pararlo, y reanudarlo con lotes más pequeños y pausas mayores fuera de punta.

🗣️ **2 minutos** — Por eso el backfill se diseña como proceso controlable: parar y reanudar tiene que
ser una operación normal, no un `kill` que deje el estado a medias. Después conviene ajustar el ritmo
en función de una métrica de la base —latencia de escritura o espera de bloqueos— en vez de un número
fijo.

🔬 **El detalle** — El ritmo adaptativo es la mejora que más rinde: subir el tamaño del lote mientras
la latencia esté bien y bajarlo en cuanto empeore. Con eso el backfill aprovecha las horas tranquilas
sin que nadie tenga que vigilarlo.

**05 → 18. ¿Cómo garantizas que solo una instancia ejecuta la migración si corre al arrancar? 🟠**

⏱️ **30 segundos** — Con un bloqueo en la propia base: la primera instancia lo toma y las demás
esperan o siguen sin migrar.

🗣️ **2 minutos** — Las herramientas maduras lo implementan con una tabla de bloqueo. Lo que hay que
comprobar es qué pasa si la instancia que tenía el bloqueo muere: si el bloqueo no caduca, las demás
esperan indefinidamente y el despliegue se queda colgado. Y qué pasa si la migración falla: el bucle
de reinicios es el riesgo principal de este modelo.

🔬 **El detalle** — Aun con el bloqueo resuelto, sigue en pie el problema de fondo: la migración se
ejecuta en el momento del despliegue y no se puede revertir el código sin dejar el esquema por
delante. Por eso la recomendación sigue siendo sacarla del arranque.

**05 → 19. Hay que revertir el despliegue y la migración ya se ejecutó. ¿Qué evalúas? 🟠**

⏱️ **30 segundos** — Si la migración era compatible con el código anterior. Si lo era, se revierte
solo el código y no pasa nada.

🗣️ **2 minutos** — Ese es el motivo de la regla de compatibilidad: convierte la vuelta atrás en una
operación trivial. Si la migración no era compatible —se eliminó algo—, la evaluación es distinta:
¿se puede recrear la columna vacía y aceptar la pérdida? ¿hay datos que restaurar? ¿es mejor arreglar
hacia adelante con un despliegue correctivo?

🔬 **El detalle** — En la mayoría de los casos con esquema ya modificado destructivamente, arreglar
hacia adelante es más rápido y menos arriesgado que restaurar. Conviene tener esa opción sobre la
mesa desde el principio del incidente, no como último recurso.

**05 → 20. ¿Cómo probarías una migración antes de producción, de forma realista? 🟠**

⏱️ **30 segundos** — Sobre una copia de producción de tamaño real, cronometrándola y midiendo
bloqueos, no sobre un entorno con datos de juguete.

🗣️ **2 minutos** — Lo importante es el tamaño y la distribución de los datos: una migración que tarda
dos segundos con diez mil filas puede tardar veinte minutos con cuarenta millones. Y conviene
ejecutarla con carga simulada encima para ver si bloquea. Además, probar el camino de vuelta: aplicar
y revertir.

🔬 **El detalle** — Si no se puede tener una copia completa por tamaño o por datos sensibles, la
alternativa es una copia anonimizada del mismo volumen, o al menos de las tablas afectadas. Lo que no
sirve es extrapolar tiempos linealmente desde un entorno pequeño.

**05 → 21. Un cambio de tipo pierde precisión en el 0,1 % de las filas. ¿Cómo lo abordas? 🟠**

⏱️ **30 segundos** — No se migra en sitio: columna nueva, backfill con las reglas acordadas, y
decisión explícita sobre las filas problemáticas.

🗣️ **2 minutos** — Primero se identifica exactamente ese 0,1 % y se lleva al negocio: ¿se redondea, se
rechaza, se corrige a mano? Después, columna nueva y backfill que aplica la regla; las filas que no se
pueden convertir se marcan y se resuelven aparte. Y la columna vieja se conserva un tiempo, que es lo
que permite auditar el cambio.

🔬 **El detalle** — En datos financieros, un cambio así puede requerir registro de auditoría: qué fila
tenía qué valor antes y después. Guardar la columna original durante un periodo largo es la forma más
sencilla de poder responder a esa pregunta dos años después.

**05 → 22. Diseña el cambio completo de `amount` a `total` en una tabla grande: pasos, despliegues, backfill, verificación y contracción, con tiempos. 🔴**

⏱️ **30 segundos** — Seis pasos repartidos en unas dos semanas, con backfill por lotes en medio y la
eliminación al final, separada del resto.

🗣️ **2 minutos** — El plan:

```text
Día 1   Migración: añadir total nullable. Segundos (metadato).
Día 1   Despliegue v2: escribe en importe Y total; lee de importe.
Día 2-4 Backfill por lotes: total = importe donde total IS NULL.
        Ritmo adaptativo; progreso guardado; horas valle.
Día 5   Verificación: SELECT COUNT(*) WHERE total IS NULL → 0
        y muestreo comparando ambas columnas.
Día 6   Despliegue v3: lee de total; sigue escribiendo ambas.
Día 7-9 Observación: métricas de errores y de negocio estables.
Día 10  Despliegue v4: solo total.
Día 17  Migración de contracción: eliminar importe. Irreversible.
```

🔬 **El detalle** — La semana entre el día 10 y el 17 no es por prudencia genérica: es el tiempo en el
que todavía podría aparecer un proceso poco frecuente —un cierre mensual, un informe trimestral— que
siga leyendo la columna vieja. Los procesos periódicos son la causa más común de sorpresas en la
contracción.

**05 → 23. Diseña el proceso de backfill como componente: control, reanudación, ritmo, progreso y qué se monitoriza. 🔴**

⏱️ **30 segundos** — Un proceso con estado persistido, arranque y parada, ritmo adaptativo y métricas
de avance.

🗣️ **2 minutos** — El diseño:

```text
Estado        tabla backfill_progreso(tarea, ultima_clave, procesadas, estado)
Control       arrancar / pausar / reanudar / abortar, por configuración o API interna
Lotes         por rango de clave, tamaño inicial conservador
Ritmo         adaptativo: sube si la latencia de la base está bien, baja si empeora
Idempotencia  cada lote actualiza solo lo pendiente → repetir un lote es inocuo
Progreso      filas procesadas, filas restantes, ritmo actual, tiempo estimado
Monitorización latencia de escritura de la base, espera de bloqueos, errores por lote
Fin           verificación automática (cero pendientes) y marca de completado
```

🔬 **El detalle** — Hacer cada lote idempotente —actualizando solo donde el valor sigue pendiente— es
lo que permite reanudar sin llevar una contabilidad exacta: si un lote se repitió porque el proceso
murió justo después de aplicarlo, no pasa nada.

**05 → 24. Diagnostica: tras una migración, el servicio empieza a dar timeouts en escrituras pero las lecturas van bien. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Un índice nuevo que encarece las escrituras; bloqueos por la migración aún en
curso; o una restricción nueva que obliga a comprobaciones.

🗣️ **2 minutos** — Las tres:

```text
1. Índice nuevo        cada INSERT/UPDATE ahora mantiene un índice más;
                       si es sobre una columna muy escrita, el coste es notable.
                       Se ve comparando latencia de escritura antes/después
2. Migración en curso  la operación no terminó y mantiene bloqueos;
                       las lecturas pasan, las escrituras esperan.
                       Se ve en las vistas de bloqueos del motor
3. Restricción nueva   una clave foránea o unicidad añadida obliga a comprobar
                       en cada escritura, a veces sin índice de apoyo
```

El orden responde a lo más frecuente; las tres se distinguen en minutos mirando bloqueos activos y el
plan de una escritura típica.

🔬 **El detalle** — Hay una cuarta menos evidente: el backfill corriendo a la vez. Si nadie lo
mencionó al reportar el incidente, conviene preguntar explícitamente si hay algún proceso de datos en
marcha, porque rara vez aparece en el relato inicial.

**05 → 25. Escribe la política de migraciones del equipo: qué se permite, qué se revisa, quién ejecuta y cómo se revierte. 🔴**

⏱️ **30 segundos** — Compatibles siempre, destructivas separadas y con aprobación, ejecución en el
pipeline, y vuelta atrás por código.

🗣️ **2 minutos** — La política:

```text
Permitido sin ceremonia   añadir tablas, columnas nullable, índices creados sin bloqueo,
                          eliminar restricciones
Requiere plan escrito     columnas obligatorias, cambios de tipo, restricciones nuevas,
                          cualquier cosa sobre tablas de más de N millones de filas
Prohibido en el mismo     eliminar columnas o tablas junto con un cambio de comportamiento
despliegue
Revisión                  toda migración la revisa alguien más, con la lista de §20;
                          las generadas automáticamente se leen en SQL
Ejecución                 paso del pipeline, antes del despliegue del código
Vuelta atrás              siempre por código; si la migración no es compatible,
                          no se despliega hasta que lo sea
Backfill                  proceso controlado, nunca un script manual
```

🔬 **El detalle** — La línea más útil de esa política es la de "prohibido en el mismo despliegue":
convierte una discusión recurrente en una regla objetiva y evita tener que razonarlo cada vez con
prisa. Las políticas funcionan cuando eliminan decisiones, no cuando las describen.

---

# 06 — Simulación de entrevista

**Sobre las preguntas `S#`.** Están cubiertas por las preguntas de los cinco capítulos del bloque:
`S1`–`S5` por [`01`](01-base-de-datos-por-servicio.md), `S6`–`S10` por
[`02`](02-consultas-entre-servicios.md), `S11`–`S16` por [`03`](03-saga.md), `S17`–`S22` por
[`04`](04-outbox-inbox-e-idempotencia.md) y `S23`–`S27` por
[`05`](05-evolucion-de-esquema-y-migraciones.md). Las de "las que descolocan" —`S28` a `S33`— se
practican en voz alta y no tienen respuesta única.

**03/06 → E1. La saga de la contratación de una póliza.**

⏱️ **30 segundos** — Cinco pasos con el cobro como pivote: validar y calcular son compensables o
reintentables, cobrar es el punto de no retorno, y emitir y enviar van después como reintentables.

🗣️ **2 minutos** — El diseño:

```text
Paso                 Tipo           Compensación            Vencimiento
───────────────────  ─────────────  ──────────────────────  ─────────────────────
1 validar cliente    local          descartar solicitud     —
2 calcular prima     reintentable   —                       30 s por intento;
  (scoring externo)  (antes del                             tras N fallos, revisión
                     pivote)                                manual
3 cobrar 1.ª cuota   PIVOTE         (devolución: manual)    2 min para responder
4 emitir póliza      reintentable   —                       reintentos con backoff
5 enviar por correo  reintentable   —                       reintentos; nunca antes
                                                            del pivote

Estados   REQUESTED → PRICED → PAID → ISSUED → NOTIFIED
                    ↘ REJECTED (validación o scoring negativo)
                    ↘ PAYMENT_FAILED → CANCELLED
Auditoría toda transición: quién, cuándo, qué evento la causó, resultado
```

🔬 **El detalle** — Dos decisiones que el entrevistador va a tocar. La primera: el scoring externo es
**reintentable y no compensable**, así que va antes del pivote y con vencimiento propio; si el
proveedor no responde, la solicitud queda en revisión en vez de bloquear. La segunda: el correo va
**después** del cobro a propósito, porque no se puede deshacer; si se enviara antes y el cobro
fallara, el cliente tendría una póliza comunicada y no cobrada. Y si el negocio exige preautorizar en
lugar de cobrar, el pivote se desplaza y el paso 3 pasa a ser compensable, que es una mejora real del
proceso.

**03/06 → E2. Eventos duplicados durante un despliegue con reequilibrio.**

⏱️ **30 segundos** — La causa más probable es que la marca de procesado y el efecto no estén en la
misma transacción, o que la clave de deduplicación sea el identificador del mensaje y el reproceso
generara uno nuevo.

🗣️ **2 minutos** — Qué compruebo y qué corrijo:

```text
Comprobaciones
  1. ¿la marca y el efecto están en la MISMA transacción?
     → si no, hay una ventana donde el efecto se aplica y la marca no
  2. ¿cuál es la clave de deduplicación? ¿id de mensaje o clave de negocio?
     → con id de mensaje, un reenvío manual crea una clave nueva y pasa
  3. ¿se confirma el mensaje antes o después del commit?
     → antes: se pierden; después: se duplican (y eso lo cubre la idempotencia)
  4. ¿hubo reproceso desde DLQ durante la ventana?
  5. ¿hay reintentos en varias capas que multipliquen?

Causa más probable
  reequilibrio de consumidores: dos instancias recibieron el mismo mensaje
  a la vez, ambas comprobaron "¿existe?" y ambas insertaron
  → comprobación y acción no atómicas

Corrección
  · insertar con índice único y tratar el fallo como "ya procesado"
    (un solo paso, sin carrera)
  · marca y efecto en la misma transacción
  · clave de negocio (order_id + tipo) en vez del id del mensaje
  · métrica de duplicados descartados, para verificar que el mecanismo actúa
```

🔬 **El detalle** — La corrección estructural es la primera: comprobar y luego insertar tiene una
carrera que se manifiesta exactamente cuando hay reequilibrio o reintentos simultáneos, que es lo que
describe el enunciado. Y conviene añadir una conciliación periódica: en un sistema distribuido siempre
aparecerá una causa nueva, y un proceso que detecta reservas sin pedido activo es más barato que
garantizar que nunca ocurran.

**03/06 → E3. La consulta que no cabe: listado filtrado por estado y por producto, con orden y
paginación.**

⏱️ **30 segundos** — Proyección. Componer no sirve: para filtrar por producto y paginar habría que
traer todos los pedidos del cliente y ordenar en memoria.

🗣️ **2 minutos** — El razonamiento con números:

```text
¿Composición?   filtrar por producto obliga a traer TODOS los pedidos del cliente
                y sus líneas. Con 500 pedidos × 10 líneas = 5 000 elementos por
                consulta, ordenados en memoria: no escala y la paginación es falsa
                (las páginas cambian entre peticiones)
¿Referencia?    el producto de un pedido es dato transaccional, no de referencia
¿Proyección?    una fila por (pedido, producto) o un documento por pedido con sus
                líneas indexadas → filtro, orden y paginación nativos, un salto

Decisión        proyección, con índice por (customer_id, status, product_id, created_at)
Coste           consistencia eventual de segundos · un almacén y un proyector más
                · procedimiento de reconstrucción · panel de retraso
Dueño           el servicio que sirve esa pantalla (atención al cliente)
```

🔬 **El detalle** — El matiz que conviene añadir: si el volumen por cliente fuera pequeño —decenas de
pedidos—, la composición sería válida y mucho más barata. Dar el número que cambia la decisión es lo
que distingue el criterio de la receta. Y hay que nombrar lo que la proyección **no** resuelve: si el
dato tiene que ser exacto al instante para decidir algo, la proyección no sirve; aquí es para mostrar,
y por eso funciona.

**03/06 → E4. Cambio de tipo con ampliación de precisión en cuarenta millones de filas.**

⏱️ **30 segundos** — No se cambia en sitio: columna nueva, doble escritura, backfill por lotes, cambio
de lectura y contracción semanas después.

🗣️ **2 minutos** — La secuencia:

```text
Día 1     Añadir columna nueva con la precisión ampliada, nullable.
          (metadato, rápido; sin valor por defecto para no reescribir la tabla)
Día 1     Desplegar v2: escribe en AMBAS columnas, lee de la vieja.
Día 2-5   Backfill por lotes: rango de clave, transacciones cortas, pausa,
          progreso guardado, ritmo adaptativo según latencia de la base.
Día 6     Verificar: cero filas pendientes + muestreo comparando ambas columnas
          (con atención a los casos donde la precisión extra cambia el valor).
Día 7     Desplegar v3: lee de la nueva, sigue escribiendo ambas.
Día 8-12  Observación: cuadres y cifras agregadas estables.
Día 13    Desplegar v4: solo la columna nueva.
Día 20    Contracción: eliminar la vieja. Irreversible, y por eso va sola.
Vuelta atrás  hasta el día 20, revertir el despliegue basta: el esquema es
              compatible con todas las versiones desplegadas
```

🔬 **El detalle** — En datos financieros hay que añadir una verificación que no es técnica: conservar
la columna original un tiempo largo permite responder a una auditoría sobre qué valor tenía cada fila
antes del cambio. Y el cuadre agregado antes y después es obligatorio: un cambio de precisión puede
alterar redondeos acumulados, y eso se detecta sumando, no muestreando.

**03/06 → E5. Separar el esquema compartido de `orders` e `inventory`.**

⏱️ **30 segundos** — Cuatro fases: eliminar accesos cruzados, separar esquemas con credenciales
propias, separar instancias, y retirar permisos. Los datos antes que nada.

🗣️ **2 minutos** — El plan:

```text
F1  Inventario de accesos cruzados con los REGISTROS de consultas reales
    (no leyendo código: aparecen informes y tareas programadas olvidadas).
    Sustituirlos por llamadas a la API del dueño o por copia por eventos.
    Despliega: código. Vuelta atrás: revertir despliegue.
F2  Esquemas separados en la misma instancia; una credencial por servicio,
    sin permisos sobre el ajeno.
    Vuelta atrás: restaurar permisos.
F3  Instancia separada para inventario: copia inicial + replicación de cambios
    + corte de escritura corto cuando el retraso sea de segundos.
    Vuelta atrás: reapuntar a la instancia original (aún consistente).
F4  Retirar accesos y credenciales antiguas.
    PUNTO DE NO RETORNO: cuando la instancia original deje de recibir
    escrituras de inventario.

Medición  por fase: latencia, errores, y consultas por petición
          (F1 las sube: es esperado y es el coste real de la frontera)
```

🔬 **El detalle** — La fase que se subestima siempre es F1, y no por dificultad técnica: los accesos
cruzados aparecen en sitios que nadie recuerda —un informe mensual, un script de operaciones, una
tarea programada—. Por eso el inventario se hace con los registros de consultas de la base y no
leyendo el código. Y conviene decir explícitamente que en F1 el rendimiento empeora: donde había un
`JOIN` ahora hay dos consultas, y ese dolor es información sobre si la frontera está bien puesta,
cuando todavía es barato moverla.

---

**Anterior:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
