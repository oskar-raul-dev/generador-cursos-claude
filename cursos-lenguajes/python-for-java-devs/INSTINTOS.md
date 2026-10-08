# 🪞 INSTINTOS
## Los reflejos de Java, y qué hacer con ellos

Este documento recoge los reflejos que aparecieron a lo largo del curso —las dieciocho fases del
camino base y las diecisiete secciones de los complementos `ia` y `ds`—: qué te empuja a escribir
tu experiencia previa, por qué eso era correcto donde lo aprendiste, y qué se escribe en su lugar
aquí. Son **treinta y seis**, más cuatro de método.

No es un resumen del curso. Es la lista que conviene releer **antes de una revisión de código**,
tuya o ajena, y la que explica por qué un desarrollador con once años de oficio escribe Python
que funciona y que nadie de ese ecosistema habría escrito.

> 🧭 **Ninguno de estos reflejos es un error de quien lo tiene.** Todos fueron correctos en el
> lugar donde se aprendieron, y casi todos siguen siéndolo allá. Lo que cambia es el **mapa de
> costos**: qué es barato y qué es caro es distinto en cada ecosistema, y recalibrar ese mapa es
> lo que el curso vino a hacer.

---

## 1. La ceremonia

**El reflejo más grande, y del que salen otros cinco.** La creencia de que el código serio
necesita estructura declarada por adelantado: una clase para agrupar, una interfaz para
desacoplar, una jerarquía para extender.

**Por qué era correcto:** en Java, una función suelta **no existe**. Para pasar comportamiento
necesitas un objeto, y por eso `Comparator`, `Runnable` y media biblioteca estándar son interfaces
de un solo método. La clase no es ceremonia allá: es el único vehículo disponible, y su costo se
paga de todos modos.

**Dónde se manifiesta:** la clase con un solo método; la jerarquía con un `AbstractBase` arriba;
los getters sobre atributos públicos; la interfaz que alguien tiene que declarar que implementa; el
repositorio genérico sobre la sesión de SQLAlchemy; el framework de validación para seis reglas.

**Qué se escribe en su lugar:** una función, un diccionario de funciones, una `dataclass`, un
`Protocol`. Y la regla que ordena todas: **la estructura se gana cuando el código la pide**, y
agregarla después no rompe a quien te usa — que es la diferencia de fondo con Java, donde cambiar
un campo por un método sí rompe.

**El número:** el mismo motor de comisiones, 54 líneas y 7 clases contra **22 líneas y ninguna**.
Y agregar un aliado ordinario: dos sitios contra **cero**.

**Dónde la clase sí es la respuesta**, porque la regla no es "no uses clases": cuando hay **estado
que varios métodos comparten y mutan**, cuando hay un ciclo de vida, o cuando hay varias
implementaciones de verdad con más de un método cada una.

→ Fase 03 · y su eco en las Fases 10, 11 y 12

---

## 2. Materializar

**El reflejo:** leer a una lista, filtrar a otra lista, transformar a una tercera, y después
recorrer.

**Por qué era correcto:** en Java las colecciones caben casi siempre, el recolector es bueno, y el
costo de una lista intermedia rara vez aparece en un perfil.

**Qué se escribe en su lugar:** generadores y expresiones generadoras, materializando **solo el
resultado** — que casi siempre es mucho más pequeño que la entrada.

**El número:** **291 MB contra 0.15 MB**, y de paso 2.3× más rápido, porque reservar 291 MB cuesta
trabajo.

**La trampa que trae:** un generador agotado **devuelve vacío en silencio**, sin la
`IllegalStateException` que te avisaría en un *stream* de Java. El síntoma es un reporte con
ceros. La defensa es no pasar generadores por el programa, sino **funciones que los producen**.

→ Fase 02

---

## 3. "El IDE me resuelve el entorno"

**El reflejo:** el proyecto declara su JDK y el IDE lo materializa. Abres, indexa, funciona.

**Por qué era correcto:** allá el orden de causalidad es ese, y el error se manifiesta con un
mensaje que dice exactamente qué pasó.

**Qué se escribe en su lugar:** el orden se invierte — **tú** creas el entorno, **tú** apuntas el
editor, y verificas con `sys.executable` cuando algo no cuadra.

**El síntoma que lo delata:** un `ModuleNotFoundError` de algo que acabas de instalar. El 80% de
los "no me funciona" del primer mes son eso.

→ Fase 00

---

## 4. `==`, `is`, y la copia defensiva

**Dos reflejos hermanos del modelo de datos**, y los dos producen errores silenciosos.

**`is` donde iba `==`.** En Java `==` compara referencias y hay que escribir `equals`; aquí está
**al revés**, y el código equivocado funciona por accidente porque el intérprete reutiliza cadenas
cortas. Deja de funcionar en cuanto el dato viene de un archivo.

**"Copio la lista para no modificar la original".** Copia la lista y no lo que contiene. En Java
rara vez importa, porque lo que hay dentro suele ser inmutable; aquí la forma por defecto de
representar un registro es mutable.

**Qué se escribe en su lugar:** `is` solo para `None`, `True` y `False`. Y en vez de defenderte
copiando, **haz que el dato no se pueda modificar** — `tuple`, `dataclass(frozen=True)`.

→ Fase 01

---

## 5. "Si no está declarada, no puede lanzarse"

**El reflejo:** once años de `throws IOException` construyen la certeza de que la firma es el
contrato y el compilador lo verifica.

**Por qué era correcto:** porque allá lo es.

**Qué produce aquí:** los dos errores gemelos, que son intentos honestos de recuperar la seguridad
perdida — el `except Exception` que se traga el error de programación que escribiste hace diez
minutos, y el `try` de cuarenta líneas donde no se sabe cuál de las cuatro cosas falló.

**Qué se escribe en su lugar:** atrapar el tipo específico, alrededor de lo mínimo, o **no
atrapar** — un script que revienta con su traza dice más que un "hubo un error". Y el contrato
vive en el docstring, en el nombre de tus excepciones y en las pruebas.

**Y la herramienta que Java no tiene:** `ExceptionGroup` y `except*`, para reportar **todos** los
fallos de un lote en vez del primero.

→ Fase 04

---

## 6. Concatenar cadenas, e ignorar el código de retorno

**Dos reflejos de la frontera con el sistema operativo.**

**Concatenar** para armar una ruta o un comando: falla en Windows, falla con espacios, y con
`shell=True` se convierte en una inyección de comandos sobre un dato que escribió otra persona.

**Ignorar el código de retorno:** en Java una llamada que falla lanza algo. `subprocess.run` **no
lanza** cuando el programa invocado falla — devuelve un objeto que nadie mira, y tu cierre de mes
reporta éxito sobre cuarenta facturas sin firmar.

**Qué se escribe en su lugar:** `pathlib` para rutas, lista de argumentos para comandos, y **las
tres cosas siempre**: lista, `timeout`, y el código revisado.

**La regla general, que reaparece en la Fase 13 con HTTP:** el contrato de un proceso son tres
cosas —argumentos, salidas y código de retorno— y hay que leer las tres.

→ Fase 05 · y su eco en la 13

---

## 7. "Busco una biblioteca para esto"

**El reflejo:** una línea en el `pom.xml` y a otra cosa.

**Por qué era correcto:** en el mundo Maven agregar una dependencia es casi gratis — un artefacto
firmado en un repositorio corporativo que alguien más resolvió.

**Por qué aquí no lo es:** cada dependencia se resuelve, se instala, puede romperse, y **alguien
que no eres tú va a tener que tenerla**. Y se paga en cada invocación: cuatro imports de la
biblioteca estándar cuestan 6.6 ms sobre un arranque de 25.

**Qué se escribe en su lugar:** mirar primero qué viene en la caja, que es mucho más de lo que un
dev de Java supone — `csv`, `json`, `tomllib`, `sqlite3`, `zipfile`, `subprocess`, `pathlib`,
`http.server`, `hashlib`, `hmac`, `zoneinfo`.

**La prueba:** siete fases construyendo una herramienta que lee seis formatos, valida seis mil
filas, orquesta un binario ajeno y guarda un histórico consultable — **con cero dependencias**.

→ Fase 06 · y toda la disciplina del Bloque A

---

## 8. Empezar por el proyecto

**El reflejo más caro del curso:** `mvn archetype:generate` como primer gesto.

**Por qué era correcto:** en Java **no existe el registro script**. No hay forma de escribir
catorce líneas útiles sin una clase, un `main` y un empaquetado, así que la estructura no cuesta
nada — ya la ibas a pagar.

**Qué se escribe en su lugar:** el archivo primero, la estructura cuando el archivo la pida. Y no
por pereza: **la estructura correcta se deduce del código que ya existe**, y adivinarla antes sale
mal.

**Las cinco señales de que ya cruzó la línea:** lo usa más de una persona; tiene más de un punto
de entrada; alguien pidió una opción que no encaja; probarlo duele; y ya no sabes qué necesita
para correr.

**El reflejo hermano:** *"`requirements.txt` es mi `pom.xml`"*. No resuelve, no fija el
intérprete, y no es reproducible.

→ Fase 07

---

## 9. "El verificador es el compilador" · "Traduzco JUnit"

**Dos reflejos sobre las redes de seguridad.**

**El verificador no es el compilador:** no hay garantía en tiempo de ejecución, es un programa
aparte que alguien tiene que correr, y las bibliotecas pueden mentirte. Lo que sí da es real —
atrapa el 90% de los errores de firma— y es **gradual** por diseño: el agujero es parte del plan.

**Traducir JUnit** produce la clase de test con `setUp` y estado en `self`. En `pytest` la
preparación son **fixtures**: inyección de dependencias con alcance, no un gancho del ciclo de
vida. Y una prueba que no pide una fixture no paga su costo.

**El número que lo ordena:** al encender `mypy --strict` sobre 250 líneas sin anotar salieron **43
errores, de los cuales 3 eran reales** — y uno era código que **no se podía ejecutar**.

→ Fase 08

---

## 10. "Que clone el repo y cree un entorno"

**El reflejo:** es exactamente lo que responderías si te preguntaran ahora mismo.

**El de debajo, que es más interesante:** buscar el equivalente del JAR ejecutable. La pregunta que
traes es *"¿cuál es el JAR de Python?"*, y la respuesta honesta es que **no hay** — y eso no es un
descuido del ecosistema, es que allá la JVM se asume instalada y aquí el intérprete no.

**Qué se escribe en su lugar:** elegir entre cuatro formas sabiendo qué asume cada una, con una
pregunta al frente: **¿qué puede asumirse de la máquina del otro lado?**

**Y el criterio que casi nadie aplica: elige por la segunda entrega, no por la primera.** La
primera la haces tú, con tiempo. La segunda la hace el usuario solo, con prisa.

→ Fase 09

---

## 11. El DTO, el *mapper*, y la validación repartida

**El reflejo:** un DTO anémico con anotaciones, un *mapper* al dominio, y las reglas que no caben
en una anotación repartidas por los servicios.

**Qué se escribe en su lugar:** **el modelo es el validador**, y el tipo dice la verdad — `branch:
Branch` en vez de `branch: str`. Lo que llega ya es de fiar, el *mapper* en gran parte desaparece,
y la documentación de la API publica la verdad en vez de "string".

**Y la distinción que evita rehacerlo después:** el modelo de entrada valida **lo que se ve en la
petición**; todo lo que necesite mirar el estado del sistema es **negocio**, y va donde lo vean
todas las puertas — porque el día que el back-office cree el mismo dato por otro camino, la regla
que vivía en el modelo de entrada no se ejecuta.

**El costo, medido para desarmar la objeción:** validar la entrada cuesta **1.1 microsegundos**.

→ Fase 10

---

## 12. "Cargo la entidad y navego las relaciones"

**El reflejo:** en Hibernate la colección es perezosa y se carga sola.

**Qué produce aquí:** o un `DetachedInstanceError`, o —peor— **201 consultas en silencio**.

**Qué se escribe en su lugar:** declarar qué necesitas **al pedirlo** (`selectinload` para
colecciones, `joinedload` para referencias a uno), y **contar las consultas** como hábito.

**Y la parte que cuesta admitir:** ese error que parece una molestia es la mejor característica de
la biblioteca — te obliga a decidir qué datos necesitas **cuando tienes la información para
decidirlo**. Hibernate te deja postergar esa decisión, y por eso el N+1 aparece en producción en
vez de en la revisión.

**El número que reordena las prioridades:** abrir una conexión cuesta **56×** lo que la consulta.
La discusión Core-contra-ORM (0.23 ms) es irrelevante al lado de eso.

→ Fase 11

---

## 13. Elegir framework por rendimiento

**El reflejo:** es el criterio con el que se discute esto en casi todas las reuniones de
arquitectura.

**Por qué falla:** lo que decide para un back-office no es cuántas peticiones por segundo aguanta
— es **cuántas pantallas hay que escribir y quién las va a mantener**.

**Y la razón por la que este perfil lo subestima:** el admin de Django **no tiene equivalente en el
mundo de Java**. Como la categoría no existe en tu experiencia, suena a "una pantallita" y la
conversación se va a lo que sí conoces.

**El número:** 76 líneas contra 204 para la primera pantalla, y **23 contra 70** para cada una de
las siguientes.

**El criterio:** *¿quién consume esto, una persona o un programa?* **Son dos registros, no dos
calidades** — y para una API el resultado se invierte con la misma claridad.

→ Fase 12

---

## 14. "Si falló, reintento"

**El reflejo:** razonable, y correcto la mitad de las veces.

**Qué produce:** un reintento sobre una operación no idempotente la ejecuta dos veces. Y el modelo
mental que lo sostiene está equivocado: **"falló" no significa "no ocurrió"**.

**El hallazgo que lo desmonta:** con un timeout de un segundo, el emisor dio **diez de diez**
notificaciones por perdidas — y las diez habían llegado y se habían procesado. **Un timeout no es
una cancelación**: tu cliente deja de esperar, el servidor sigue trabajando.

**Qué se escribe en su lugar:** cuatro decisiones explícitas —timeout, criterio de reintento,
*backoff* con *jitter*, y **clave de idempotencia**— donde la última es la única que de verdad
protege. Y la clave es **de la operación, no del intento**.

**El número:** sin defensas se pierde el 33% en silencio; con reintento y sin clave se duplica el
**48%**.

→ Fase 13

---

## 15. `synchronized`, el pool de hilos, y `ConcurrentHashMap`

**El reflejo:** el kit completo, afinado durante años.

**Qué produce:** nada, en el problema que importa. Dos auxiliares reservan el mismo espacio de las
3:40 **con el candado puesto**, porque `threading.Lock` protege un proceso y la aplicación corre
con varios.

**Qué se escribe en su lugar:** **el candado tiene que estar donde está el estado**. El de Áurea
vive en Postgres, así que la respuesta es una restricción de unicidad, un bloqueo optimista o un
`SELECT ... FOR UPDATE` — no una primitiva del lenguaje.

**Y el reflejo de dimensionar el pool**, que aquí se reemplaza por una sola pregunta: **¿esto
espera o calcula?** Hilos: **1.02×** para CPU, **3.95×** para E/S. Con el mismo código.

**Lo que sorprende de verdad:** los procesos **pierden contra secuencial** (0.88×) cuando los
datos cruzan la frontera, y ganan 1.86× cuando cada uno lee lo suyo. **Manda instrucciones, no
datos.**

→ Fase 14

---

## 16. El job que arranca de cero

**El reflejo:** un trabajo que falla se relanza. En tu mundo suele estar bien.

**Dónde deja de estarlo:** en una ventana de seis horas que se cae en la hora cinco. Y hay algo
peor que el reflejo no ve: **relanzarlo puede ser incorrecto**, si el proceso ya escribió la mitad
de las liquidaciones.

**Qué se escribe en su lugar:** reanudable **y** idempotente, las dos juntas. El lote confirma su
avance y su resultado **en la misma transacción**.

**El número:** el punto de control cuesta **+9%** en la corrida buena y ahorra el **100%** del
trabajo en la mala.

**Y el hallazgo de método:** reanudar **no es** guardar por dónde vas — es guardarlo **de forma que
retomar sea constante**. Guardar el número de filas en vez del desplazamiento dispara el
sobrecosto del 9% al **319%**.

→ Fase 15

---

## 17. `print` como registro, y optimizar sin medir

**Dos reflejos de operación.**

**`print`** funciona, sale por pantalla, y a las dos de la mañana no sirve para nada: sin nivel,
sin marca de tiempo, sin origen, mezclado con la salida útil. La respuesta no es `logging` —eso ya
lo sabes— sino **registro estructurado**: *"procesando sede centro"* se lee; un evento con campos
**se consulta**.

**Optimizar el Python que está encima de una consulta mala** es el reflejo del buen programador, y
por eso cuesta desactivarlo: ves un bucle lento y lo mejoras.

**El número que lo cierra:** en el cierre nocturno, **el 87% del tiempo es esperar a la base**.
Duplicar la velocidad de todo el código Python mejoraría el total un 6.5%; quitar el N+1 lo mejoró
**27 veces** sin tocar una línea del cálculo.

**Qué se escribe en su lugar, en orden:** mide el total → perfila → **pregunta qué fracción del
tiempo es tuya** → arregla la E/S → y solo entonces el código. El tercer paso es el que casi nadie
hace.

→ Fase 16

---

## 18. Comparar contra un competidor de paja

**El reflejo:** no es mala fe. Es que cuando llevas meses aprendiendo algo, quieres que gane.

**Qué se escribe en su lugar:** cuatro condiciones, y la tercera es la que más se incumple.

1. Las dos implementaciones producen **el mismo resultado**, verificado antes de medir.
2. Las dos están configuradas **para producción** — y eso incluye tu lado: medir uvicorn con un
   solo trabajador contra un Spring Boot que usa los ocho núcleos **es hacerte trampa a ti mismo**.
3. **El generador de carga no es el cuello de botella.**
4. Se declara lo que no se midió.

**La regla para leer cualquier *benchmark* del mundo:** antes de mirar los números, **mira la
configuración del que pierde**. Si no la publican, los números no significan nada.

→ Fase 17

---

## 🤖 Los reflejos del track de IA

Los ocho que aparecieron al construir NormaRAG y Recepción asistida. Van aparte porque el lector
llega a ellos con las dieciocho fases hechas, y porque todos nacen de una misma raíz: **tratar a un
modelo como si fuera una función**.

### 19. "Si falló o se pasó del timeout, reintento"

Es el §14 de este documento, cobrado en un sitio nuevo. **Un timeout del cliente no cancela la
generación del servidor**: la respuesta se generó, se cobró, y tú la tiraste. En un servicio con
tarifa por token, **un reintento es una compra**, y el SDK ya reintenta lo reintentable con
backoff. El timeout se sube, no se baja; lo que se acota con timeout corto es la experiencia de
usuario, y eso se resuelve transmitiendo en flujo. *(`ia01`)*

### 20. "Todo campo va `@NotNull`"

En Java, un campo obligatorio te protege de un nulo. En un contrato con un modelo, **cada campo
obligatorio es una invitación a inventar**: la generación restringida no puede omitir el campo, así
que emite el valor que le parezca más probable. Un `boolean covered` obligatorio obliga al modelo a
decidir sobre una circular que no habla de cobertura. Lo obligatorio se reserva para lo que la
fuente garantiza; **"no dice" es un valor de primera clase.** *(`ia02`)*

### 21. "La firma es el contrato" · "expongo la operación que el usuario quiere"

Dos caras de lo mismo. La primera: el consumidor de tu herramienta es un modelo que **lee la
prosa**, así que el `description` es código y cada frase que falta cuesta un turno. La segunda: el
reflejo de exponer `create_appointment` produce dos citas el día que el bucle reintente — la
herramienta que muta necesita **clave de idempotencia derivada de los datos** (no un UUID nuevo,
que no protege de nada) y una persona en el medio. *(`ia03`)*

### 22. "Si no encuentra, devuelve vacío"

La ausencia es el resultado más informativo que existe… en un índice exacto. **Una búsqueda por
similitud nunca devuelve vacío**: le pides cinco y te da cinco aunque preguntes por la receta del
ajiaco. La ausencia hay que fabricarla con un umbral de distancia, y un sistema que no puede decir
"no sé" va a inventar todos los días. *(`ia04`)*

### 23. "Cabe en el contexto, luego lo mando"

Con un millón de tokens de ventana, el corpus entero cabe, y mandarlo funciona — por eso es difícil
de discutir. Cuesta por pregunta, deja de caber sin aviso el día que el corpus crezca, y sobre todo
**hace inverificable la atribución**: con cuarenta documentos no tienes contra qué comprobar la
cita; con cinco fragmentos es un `in`. El contexto grande no reemplaza la recuperación. *(`ia05`)*

### 24. "Una prueba que falla 1 de cada 20 veces es una prueba rota"

El más difícil de todos, porque es una virtud profesional bien ganada. Aquí la variación **es la
propiedad**, no un defecto: se acota con `n` corridas y un intervalo de confianza, y se falla
cuando el **límite inferior** cruza el piso. El reintento hasta que pase es una alfombra, y
convierte la garantía en *"acierta al menos una vez de cada cinco"*. Y su corolario: **un juez
automático sin medir contra un humano no es una métrica, es una opinión automatizada.** *(`ia06`)*

### 25. "La regla va en el prompt" · "optimizo la tasa de éxito"

Los dos del proyecto que puede hacer daño. El primero: **un prompt es una instrucción, no una
restricción** — el modelo la cumple casi siempre, y "casi siempre" no es una palabra que se pueda
usar cuando la obligación es profesional. Lo que se garantiza sin el modelo se garantiza sin el
modelo; lo que no, se revisa después de él; lo que no se puede revisar, se escala. El segundo:
cuando los dos errores cuestan órdenes de magnitud distintos, **la métrica agregada esconde el
caro**. Un agente que escala menos resuelve más y deja pasar más síntomas, y el número sube
mientras el sistema empeora.

**El número:** el guardrail léxico de `ia07` resuelve el **67%** sin persona y deja pasar **veinte
de cuarenta** mensajes con síntoma — los veinte que no usan su vocabulario. La tasa de resolución
no cambia si arreglas eso; la columna que importa, sí. *(`ia07`)*

### 26. "Una caché es una clave y un valor"

El último del track, y el más transferible a cualquier proveedor. La caché de prompt **no cachea la
respuesta: cachea el prefijo de la petición**, en el orden fijo `tools` → `system` → `messages`. No
ahorra un peso del costo de salida, hay un mínimo de tokens por debajo del cual no cachea nada, y
escribir en ella cuesta más que una entrada normal — así que con tráfico disperso puede salir **más
cara** que no usarla.

Y lo que la vuelve peligrosa: **falla en silencio**. Un `datetime.now()` en el mensaje del sistema,
un identificador de sesión, un `json.dumps` sin ordenar claves o una lista de herramientas cuyo
orden no está garantizado invalidan todo lo posterior sin un error, sin un aviso y sin nada en el
log. La regla: lo estable delante, lo volátil detrás del punto de corte, y **se verifica con
`cache_read_input_tokens`** — si es cero en peticiones repetidas, hay un invalidador y nadie te lo
va a decir. *(`ia08`)*

---

## 📊 Los reflejos del track de datos

Los diez que aparecieron al construir el Embudo y Ausentismo. Los cuatro primeros nacen de la
misma raíz —**pensar en filas**— y se corrigen con la misma pregunta: *¿de dónde vienen estos
datos y cuántas cuentas voy a hacer con ellos?*. Los seis últimos son de otra familia y aparecen
cuando el análisis deja de describir y empieza a **decidir**: qué se compara, qué se calibra, qué
se despliega y qué se hace con una predicción sobre una persona.

### 27. "Vectorizar siempre gana"

No es un reflejo de Java: es el que el lector adquiere el primer día de NumPy, y también está mal.
El cálculo vectorizado gana **32×** sobre columnas ya construidas, y el **programa** pierde **2,4×**
si cada corrida tiene que convertir la lista de diccionarios en columnas. Lo que hay que preguntar
no es el tamaño del dato —que es lo que todo el mundo pregunta— sino **cuántas operaciones se hacen
sobre la misma carga**: con menos de tres, el bucle gana a cualquier tamaño.

Y el reflejo intermedio, que es peor que el original: la comprehension por canal, escrita porque
"los bucles son lentos en Python", recorre la lista una vez por categoría y sale **un 82% más
lenta** que el bucle que venía a mejorar. *(`ds01`)*

### 28. "Recorro las filas y decido"

Once años de `ResultSet` dejan este reflejo intacto, y pandas tiene una función que lo acepta sin
protestar: `apply(axis=1)` construye **una Series por fila** para pasártela. Ochenta y un mil
Series para decidir ochenta y un mil veces algo que era una comparación de columna. Cuesta **15,6×**
y se arregla con una línea.

Su hermano mayor es de diseño y es más caro de descubrir porque el resultado sale bien: **unir antes
de agregar**. Materializar 81.274 filas para producir veinte cuesta un 79% más de memoria que
colapsarlas primero — y, sobre todo, deja el `merge` sin el sitio donde poner `validate=`, que es la
única forma de que una llave que dejó de ser única te lance una excepción en vez de un total
equivocado. *(`ds02`)*

### 29. "Lazy ya sé lo que es: es el lazy loading que me quemó"

Once años de ORM dejan "perezoso" asociado a una cosa muy concreta y muy mala: ir a buscar cada
dato cuando alguien lo toca, y descubrir el N+1 en producción. En Polars y DuckDB significa **lo
contrario**: acumular la consulta entera para ir al disco **una sola vez y mejor**, podando las
columnas que nadie usa y bajando los filtros hasta la lectura.

El `Stream` de Java tampoco es el paralelo correcto, aunque se le parezca más: un `Stream`
difiere la ejecución pero **respeta el orden que escribiste**. Aquí el optimizador lo reescribe,
exactamente como el planificador de tu base de datos. El modelo mental que sirve no es "streams
perezosos": es **una base de datos sin base de datos**. *(`ds03`)*

### 30. "Cada hecho tiene un dueño"

Once años de sistemas transaccionales dejan esto por debajo de todo lo demás: una venta tiene un
vendedor, un pedido tiene un cliente, una fila tiene su llave foránea. Y el reflejo se aplica
solo: `SELECT canal, count(*) … GROUP BY canal`.

El problema es que **una conversión no tiene dueño**. El paciente vio un video en enero, escribió
en febrero y buscó en Google en marzo; el `GROUP BY` exige elegir una columna, y al elegirla
—`canal_ultimo_toque`, porque estaba ahí— tomaste una decisión de negocio sin enterarte. Sobre
los mismos 5.451 pacientes de Áurea, esa decisión mueve el costo de TikTok entre **1,06 y 7,96
millones**: 7,5×, con los intervalos al 95% sin tocarse.

Lo que se lleva el reflejo corregido no es un modelo mejor: es la obligación de **nombrar el
reparto en la salida** y publicar la banda entre modelos. Cuando dos modelos dan la misma
decisión, adelante. Cuando dan decisiones opuestas, el informe no puede decidir y lo que
corresponde es un experimento. *(`ds04`)*

### 31. "La presentación es la capa final"

Once años de backend dejan el gráfico del lado de alguien más, al final del proceso y sin
consecuencias. Aquí la presentación es **donde se pierde la información**: todo el trabajo de
`ds04` —cuatro modelos, intervalos, madurez— cabe en una tabla de texto y **no cabe en un
gráfico de barras**. Elegir la barra simple no es una decisión estética: es tirar el hallazgo.

Y el corolario que cuesta aceptar: para las siete cifras del comité de Áurea, **la tabla gana**,
y gana porque cabe la columna de la banda, se pega en un correo y se compara con un `diff`. El
reflejo corregido es preguntar *"¿esto es para decidir, para ver una forma o para explorar?"*
antes de abrir cualquier biblioteca. *(`ds05`)*

### 32. "Los cuadernos son un desastre"

Este reflejo es **medio correcto**, y la mitad exacta se puede medir. De seis cuadernos del
análisis del Embudo, **dos corren de arriba abajo en un kernel nuevo y uno solo da el mismo
resultado dos veces**. Tienes razón en que un cuaderno no es un entregable.

Donde el reflejo falla es en la conclusión de no usarlos. **Cuatro de los cinco defectos no son
del formato** —una ruta absoluta y una dependencia no declarada rompen un `.py` igual—, y a
cambio estás dejando sobre la mesa lo único que un cuaderno hace mejor: cargar el dato una vez y
hacerle cuarenta preguntas. La regla que sale: **el cuaderno es para pensar, el módulo es para
entregar**, y la prueba que separa los dos cuesta siete segundos. *(`ds06`)*

### 33. "Es una función: entra un caso, sale una predicción"

Once años de código determinista dejan la expectativa de que un modelo se prueba con una
aserción: entrada conocida, salida esperada, verde. Aquí **no hay correcto**: hay mejor o peor
que una línea base, y si no escribiste la línea base primero, tu cifra no significa nada.

Sobre el ausentismo de Áurea, el modelo que **no hace nada** —decir que todos asisten— acierta
el **80,1%** de las veces, porque solo falta el 19%. Cualquier informe que celebre una exactitud
del 81% está celebrando eso. La regla de ocho líneas que Patricia ya aplica en la cabeza saca
**0,672 de AUC**, y ese es el número contra el que hay que ganar — la logística lo hace, con
0,799, y por eso entra.

Los dos reflejos hermanos que vienen en el mismo paquete: **`predict` decide por ti** con un
umbral de 0,5 que nadie eligió —marca el 9,8% cuando falta el 20%—, y **la columna que sale de
un `GROUP BY` puede conocer el futuro**: `inasistencias_totales_paciente` regala 0,063 de AUC
sin lanzar nada. La pregunta que los desarma es siempre la misma: *¿cuándo se llena este campo?*
*(`ds07`)*

### 34. "Si el modelo más complejo gana, uso el modelo más complejo"

Es el mismo criterio con el que eliges una estructura de datos, y ahí funciona: si el `HashMap`
gana, usas el `HashMap`, porque mantenerlo no cuesta nada. Un modelo sí cuesta.

Sobre el ausentismo de Áurea la red neuronal **gana de verdad** —0,8118 contra 0,7993, con un
intervalo al 95% que no toca el cero— y la conclusión correcta sigue siendo no usarla. Porque la
misma regresión logística con **una columna escrita a mano** —`lluvia × distancia`, que es
conocimiento que Julián ya tenía— llega al mismo 0,8118 con un intervalo indistinguible. La
ventaja no era de la red: era de la interacción que la línea base no tenía.

La pregunta que corrige el reflejo: **¿por cuánto gana, con qué intervalo, y qué le pasa a esa
ventaja si le escribo al competidor una variable que el dominio ya conocía?** Y su corolario,
que es de costo: 144 ms y seis coeficientes legibles contra PyTorch instalado y cinco decisiones
de entrenamiento que alguien retoma cada vez que los datos cambien. *(`ds08`)*

### 35. "El modelo decide"

No decide. El modelo produce una probabilidad; **la decisión es la asimetría de costos**, y esa
la pone la empresa. En Áurea, una colisión en la silla es unas tres veces peor que una silla
vacía, y de ahí sale —en una línea de álgebra— que solo conviene sobreagendar un cupo cuyo
paciente falte **tres de cada cuatro veces**. Ese 0,75 no salió de ningún modelo.

El reflejo tiene una consecuencia cara: un puntaje que **ordena** bien puede **decidir**
pésimo. La regla de tres variables saca 0,672 de AUC —decente— y un ECE de 0,1918: aplicada al
sobreagendamiento pierde 6.336 consultas contra no hacer nada, mientras cualquier modelo
calibrado recupera unas 3.000. Si tu puntaje va a multiplicar algo —plata, cupos, riesgo—, mide
la calibración antes de multiplicar. *(`ds08`)*

### 36. "Serializar es serializar"

Este reflejo viene con una cicatriz que **sí** funciona: en la JVM ya aprendiste que
`ObjectInputStream` sobre datos ajenos es una vulnerabilidad de libro, y por eso hoy mandas
JSON. El problema es que la cicatriz no se dispara con un modelo.

Un `.pkl` no se siente como código: se siente como un binario opaco —*"es el modelo, qué le voy
a validar"*— y viaja por correo, por un bucket compartido o dentro de una imagen que construyó
alguien más. Y `pickle.load` **no lee datos: reconstruye objetos**, y para reconstruirlos ejecuta
lo que el archivo le diga. Diez líneas con un `__reduce__` propio lo demuestran, sin ninguna
advertencia y sin ninguna forma de verlo venir. **No hay validación previa posible:** para saber
qué hay dentro habría que interpretarlo, que es lo que produce el problema.

La regla que sale: **un `.pkl` solo se carga si tu propio proceso lo escribió**, en tu
infraestructura, y nadie pudo tocarlo desde entonces. Todo lo demás se convierte primero a un
formato que solo sepa describir números — y se comprueba mirando los bytes: el `.pkl` lleva
dentro la cadena `sklearn`, el `.onnx` del mismo modelo no menciona ningún módulo. *(`ds09`)*

---

## 🧪 Los reflejos de método

Estos no son de Java: son de cualquiera que mida. Aparecieron **escribiendo el curso**, y por eso
están aquí — todos son errores que cometió quien lo escribió.

### Lo que mides cambia la respuesta

El costo del modelo de salida de FastAPI, medido **en proceso**, era un **33%**. Medido **sobre
HTTP real**, desapareció: 0.83 contra 0.83 ms. Las dos mediciones son correctas y miden cosas
distintas; la que responde *"¿cuánto le cuesta esto a mi API?"* es la segunda.

**Declarar el montaje no es burocracia: es lo que permite saber cuál de las dos citar.**

→ Fase 10

### Tu benchmark depende de lo que tengas instalado al lado

El consolidado de `ds03` con DuckDB sobre Parquet tarda **97 ms** de punta a punta en un entorno
donde solo está DuckDB, y **433 ms** en uno donde además está pandas instalado. Mismo código,
mismos datos, 4,5×: DuckDB importa pandas **durante la consulta**, porque su mecanismo de
sustitución de nombres va a mirar si algún nombre referenciado es un objeto de pandas o de Arrow.

Nadie lo escribe en el `requirements.txt` y nadie lo ve en el perfil. La regla que deja: **cuando
midas una dependencia, mídela en un entorno donde esté sola**, y si no puedes, declara qué más
había instalado. Una tabla de motores tomada en un entorno con los cuatro le cobra a cada uno el
arranque de los otros tres.

→ `ds03`

### Si los dos números se parecen demasiado, mide al medidor

El primer duelo dio **390 req/s para Spring Boot y 418 para FastAPI**. Números casi idénticos, y
por lo tanto sospechosos. Con un generador de carga de verdad: **13.834 y 2.508**. El cuello de
botella era el cliente.

**Un generador que no puede superar al servidor mide al generador.**

→ Fase 17

### El empate es un resultado

Es la palabra que menos aparece en los cursos de tecnología y la que más falta hace. Este curso
publica **cinco**: `set` contra `dict`; `uv tool` contra `.pyz` contra el congelado en carpeta; el
arranque de los dos contenedores; la memoria a igual rendimiento; y la latencia de cola del duelo.

Cuando dos opciones empatan, **la decisión se toma por otra columna** — y saber cuál es esa
columna vale más que el número que no las separó.

---

## 🧭 El reflejo que no se corrige, y no hace falta

Hay uno que conviene proteger en vez de desactivar: **la desconfianza**.

Un desarrollador con once años de oficio llega a este ecosistema y desconfía de que algo tan corto
pueda ser correcto, de que una biblioteca sin tipos verificados sea segura, de que un sistema sin
compilador aguante. Esa desconfianza es **buena**, y este curso está construido alrededor de ella:
por eso cada afirmación comparativa lleva su número, y por eso el curso termina admitiendo dónde
se equivocó.

Lo que hay que hacer con ella no es quitarla: es **convertirla en la pregunta correcta**. No
*"¿esto es serio?"* sino *"¿cuánto cuesta, y comparado con qué?"*.
