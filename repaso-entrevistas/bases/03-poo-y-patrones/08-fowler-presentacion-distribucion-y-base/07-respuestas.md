# 07 — Respuestas

> Solucionario del bloque `08-fowler-presentacion-distribucion-y-base`: Fowler: presentación, distribución y base. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) · PostgreSQL 18.6 (2026-10-04).

**Salto rápido:** [01](#01--presentación-web) · [02](#02--distribución) · [03](#03--concurrencia-offline) · [04](#04--estado-de-sesión) · [05](#05--patrones-base) · [06](#06--simulación-de-entrevista)

---

# 01 — Presentación web

**01 → 1. ¿Qué tres papeles separa MVC? 🟢**

⏱️ El modelo (los datos y las reglas), la vista (lo que se muestra) y el controlador (lo que recibe la acción del
usuario y decide qué hacer).
🗣️ Lo valioso es la separación entre dominio y presentación: se puede cambiar la pantalla sin tocar las reglas y probar
las reglas sin pantalla. En el servidor, el controlador interpreta la petición HTTP y la vista genera la respuesta.
🔬 Fowler llama a esa idea *Separated Presentation* en *GUI Architectures*, y la considera la más influyente del MVC.

**01 → 2. ¿Qué es un Front Controller? 🟢**

⏱️ Un único punto de entrada que recibe todas las peticiones, hace lo común (seguridad, registro, errores) y despacha a un
manejador según la ruta.
🗣️ En Spring es el `DispatcherServlet`: la documentación dice que Spring MVC está diseñado alrededor de este patrón. Lo
que escribimos son los controladores a los que despacha.
🔬 El *router* de cualquier marco web (Express, ASP.NET Core) es la misma idea.

**01 → 3. ¿Qué es un Template View? 🟢**

⏱️ Generar HTML con una plantilla que tiene marcadores donde se insertan los datos.
🗣️ Thymeleaf y JSP: `<td th:text="${persona.nombre}">`. La plantilla la puede editar alguien que sabe HTML y no Java.
🔬 Su riesgo clásico es meter lógica en la plantilla; la regla es que la vista solo muestre lo que el controlador le dio.

**01 → 4. ¿Qué es un Application Controller? 🟢**

⏱️ Un objeto que decide el flujo entre pantallas —qué pantalla sigue y qué comando ejecutar— separado de los
controladores que reciben las peticiones.
🗣️ Un asistente de alta en varios pasos, con las reglas de qué paso sigue según lo que se respondió, centralizado en un
objeto. Hoy ese flujo suele vivir en el cliente, en el *router* del *frontend*.
🔬 Cuando el flujo es un proceso de negocio de varios pasos que vive en el servidor, se modela como estados (`06/06`), no
como pantallas.

**01 → 5. ¿Qué es un Page Controller, y qué lo reemplazó? 🟢**

⏱️ Un controlador por página, que recibe las peticiones de esa página. Lo reemplazó el Front Controller de los marcos,
que despacha a métodos de controlador.
🗣️ Antes era un servlet por URL; hoy, cada `@GetMapping` es "el controlador de una página", pero el que recibe la
petición es el `DispatcherServlet`.
🔬 Fowler los presenta como alternativas: Page Controller es más simple con pocas páginas; Front Controller centraliza lo
común cuando hay muchas.

**01 → 6. ¿Qué diferencia hay entre el MVC original y el MVC de servidor? 🟡**

⏱️ En el original, de escritorio, la vista observa al modelo y se redibuja cuando cambia; en el de servidor, la vista se
genera una vez por petición y no observa nada.
🗣️ En el original hay un controlador por vista que interpreta teclado y ratón; en el servidor, un controlador por grupo de
rutas que interpreta la petición HTTP. Lo que comparten es la separación entre dominio y presentación.
🔬 Fowler lo describe en *GUI Architectures*: *Separated Presentation* más *Observer Synchronization*. La segunda vive hoy
en los marcos de *frontend* y en las aplicaciones de escritorio, no en el servidor.

**01 → 7. ¿Qué diferencia hay entre el `Model` de Spring y el modelo de dominio? 🟡**

⏱️ El `Model` de Spring es un mapa de atributos para la vista; el modelo de dominio son las entidades y las reglas. El
controlador llena el `Model` con datos que obtiene del dominio.
🗣️ El nombre confunde: poner una entidad en el `Model` expone a la plantilla un objeto con reglas y asociaciones
perezosas. Lo habitual es poner un DTO pensado para la vista.
🔬 En un API JSON no hay `Model`: el método devuelve el objeto que se serializa.

**01 → 8. ¿Qué diferencia hay entre Front Controller y Page Controller? 🟡**

⏱️ El Front Controller es un único punto de entrada para todas las peticiones; el Page Controller, uno por página.
🗣️ El Front Controller centraliza lo común y despacha; el Page Controller repite lo común en cada página o lo hereda de una
clase base. Con un marco moderno, se tienen los dos: un Front Controller del marco y métodos de controlador por ruta.
🔬 Ver `01 → 5`.

**01 → 9. ¿Qué diferencia hay entre Template View y Transform View? 🟡**

⏱️ El Template View parte del HTML y le inserta datos; el Transform View parte de los datos y los transforma elemento por
elemento en HTML, como XSLT.
🗣️ El primero está organizado por la página; el segundo, por los datos. XSLT fue el ejemplo de libro y cayó en desuso fuera
de integraciones con XML.
🔬 El mapeo de entidades a DTO y su serialización a JSON es, en espíritu, un Transform View: una representación construida
desde los datos.

**01 → 10. ¿Por qué "MVC es Spring MVC" es impreciso? 🟠**

⏱️ Porque MVC nació en las interfaces de escritorio de Smalltalk, con la vista observando al modelo; Spring MVC es una
adaptación a peticiones HTTP, sin esa observación, organizada alrededor de un Front Controller.
🗣️ Spring MVC conserva la separación de papeles, que es lo importante, y la reinterpreta: el controlador es un manejador de
peticiones, y la vista, una plantilla o la serialización.
🔬 También se usa "MVC" para los marcos de *frontend*, con otro significado más. Preguntar a cuál se refiere el
entrevistador es razonable.

**01 → 11. ¿Dónde está la "vista" en un API que devuelve JSON? 🟠**

⏱️ En la serialización: el objeto que devuelve el controlador (idealmente un DTO) se convierte a JSON con un conversor de
mensajes. Ese conversor y la forma del DTO son la vista.
🗣️ Por eso el DTO importa: es el contrato de la vista. Devolver la entidad hace que la vista cambie cada vez que cambia el
dominio, y expone campos internos.
🔬 Los DTO son el tema del capítulo siguiente.

**01 → 12. ¿Qué hace el `DispatcherServlet` en cada petición? 🟠**

⏱️ Busca qué manejador atiende la ruta (`HandlerMapping`), lo invoca con un adaptador (`HandlerAdapter`), resuelve la
vista o convierte el resultado a JSON, y traduce las excepciones con los manejadores de excepciones.
🗣️ Antes que él pasan los filtros de servlet (una cadena); alrededor del controlador, los interceptores. Todo eso es lo que
el Front Controller centraliza.
🔬 La documentación de Spring lo resume: un algoritmo común para procesar peticiones, con el trabajo delegado en componentes
configurables.

**01 → 13. Escribe un controlador de Spring que muestre la ficha de una persona sin poner reglas de negocio en él. 🔴**

⏱️ Un `@Controller` que recibe el id, pide la ficha a un servicio de consulta, la pone en el `Model` y devuelve el nombre de
la plantilla.
🗣️

```java
@Controller
public class ControladorPersonas {
    private final ConsultaPersonas consulta;
    public ControladorPersonas(ConsultaPersonas consulta) { this.consulta = consulta; }

    @GetMapping("/personas/{id}")
    public String ver(@PathVariable long id, Model modelo) {
        modelo.addAttribute("persona", consulta.ficha(id));    // un DTO: nombre, edad, documentos
        return "persona/ficha";
    }
}
```

🔬 Lo que preguntará después: dónde se calcula la edad (en el dominio o en la consulta, no en la plantilla ni en el
controlador); y qué pasa si la persona no existe (el servicio lanza una excepción del dominio y un manejador común la
traduce a un 404).

**01 → 14. Revisa este controlador y di qué falla: un `@GetMapping` que consulta con `JdbcTemplate`, calcula si la persona es menor y decide qué plantilla devolver según el país. 🔴**

⏱️ El controlador hace de todo: acceso a datos, una regla de negocio (ser menor) y presentación. Ni la regla se reutiliza ni
el controlador se prueba sin base.
🗣️ El arreglo: el acceso a datos a un repositorio o consulta, la regla a `Persona.esMenor(hoy)`, y el controlador solo
traduce la petición y elige la vista con lo que le devuelve el servicio. Elegir la plantilla por país es presentación y
puede quedarse, pero a partir de un dato del DTO.
🔬 Lo que preguntará después: cómo se prueba ahora (el controlador con un servicio falso; la regla, sin Spring); y si la
plantilla por país no es una estrategia (podría serlo si crece; con dos países, un `if` en el controlador es suficiente).

# 02 — Distribución

**02 → 1. ¿Qué dice la primera ley de Fowler de los objetos distribuidos? 🟢**

⏱️ "No distribuyas tus objetos": un modelo pensado para muchas llamadas pequeñas en memoria es desastroso cuando cada
llamada cruza la red.
🗣️ Una llamada local cuesta nanosegundos; una remota, milisegundos, y puede fallar a medias. Lo que cruza una frontera
remota tiene que tener otra forma: pocas llamadas, cada una con mucho dentro.
🔬 Fowler la escribió en *PoEAA* (cap. 7) y la revisó en 2014 a propósito de los microservicios, que la respetan haciendo
que lo que cruza la red sean servicios de grano grueso, no objetos.

**02 → 2. ¿Qué es un Data Transfer Object? 🟢**

⏱️ Un objeto solo de datos, sin comportamiento, que agrupa lo que viaja en una llamada remota para reducir el número de
llamadas.
🗣️ `FichaPersonaDto` con nombre, edad, documentos y tutor: la pantalla lo recibe en una respuesta. En Java se escribe con
`record`, que da inmutabilidad y serialización sencilla.
🔬 Es la definición de Fowler: un objeto que lleva datos entre procesos para reducir el número de llamadas. El DTO es
también el contrato del API.

**02 → 3. ¿Qué es una Remote Facade? 🟢**

⏱️ Una fachada de grano grueso sobre un modelo de grano fino: cada operación remota hace mucho trabajo en el servidor y
devuelve todo lo necesario en un DTO.
🗣️ En lugar de cuatro rutas (persona, documentos, tutor, cuentas), una `/personas/{id}/ficha`. La fachada no tiene lógica
de dominio: traduce entre la granularidad remota y la local.
🔬 Es la Facade del GoF con la red como motivo. Ver `05/04`.

**02 → 4. ¿Qué diferencia hay entre un DTO y un modelo anémico? 🟡**

⏱️ Los dos son objetos sin comportamiento, pero el DTO está diseñado así porque vive en una frontera y solo transporta;
el modelo anémico es un modelo de dominio al que le falta el comportamiento que debería tener.
🗣️ Un DTO sin métodos es correcto; una `Cuenta` del dominio sin `debitar` es un problema. Confundirlos lleva a dos
errores: dar comportamiento a los DTO, o aceptar entidades anémicas "porque son como DTO".
🔬 Fowler describió el modelo anémico como antipatrón; el DTO, como patrón. La diferencia es dónde vive el objeto.

**02 → 5. ¿Qué diferencia hay entre un DTO y un Value Object? 🟡**

⏱️ El Value Object es un concepto del dominio, con igualdad por valor, inmutable y que se valida a sí mismo (`Dinero`); el
DTO es un sobre para transportar datos, sin invariantes.
🗣️ Un DTO puede llevar datos inválidos (lo que el cliente mandó, antes de validar); un `Dinero` no puede existir con una
moneda inexistente. Los dos se escriben con `record`, y eso es lo único que comparten.
🔬 El Value Object tiene su capítulo en este bloque, en los patrones base.

**02 → 6. ¿Qué diferencia hay entre Remote Facade y la Facade del GoF? 🟡**

⏱️ Las dos simplifican un subsistema detrás de una interfaz; la Remote Facade lo hace además pensando en el costo de la
red: operaciones de grano grueso que devuelven DTO.
🗣️ Una Facade local puede tener métodos finos sin problema; una remota con métodos finos multiplica las idas y vueltas. Por
eso la Remote Facade agrupa: una llamada por necesidad del cliente.
🔬 Ver `05/04 → 1`.

**02 → 7. ¿Qué diferencia hay entre mapear a mano, con MapStruct y con reflexión? 🟡**

⏱️ A mano, el compilador comprueba todo y se lee bien, pero se escribe más; MapStruct genera el mismo código al compilar a
partir de una interfaz; la reflexión mapea al ejecutar por nombres de campos, y falla tarde y en silencio.
🗣️ Con pocos DTO, a mano. Con muchos DTO parecidos a sus entidades, MapStruct, que además avisa de los campos sin mapear.
Los mapeadores por reflexión al ejecutar son cómodos y frágiles: un campo renombrado queda vacío sin error.
🔬 MapStruct genera código Java normal que se puede leer y depurar; esa es su ventaja sobre la reflexión.

**02 → 8. ¿Por qué no hay que exponer la entidad en el API? 🟠**

⏱️ Porque el API queda atado al modelo (cualquier cambio rompe a los clientes), se exponen campos internos, y la
serialización choca con lo perezoso y con los ciclos.
🗣️ Una `Persona` con `documentos` perezosos da `LazyInitializationException` o N+1 al serializar; con `tutor`, un ciclo. Y
un campo renombrado por una razón del dominio rompe la aplicación móvil.
🔬 Además, recibir la entidad en un `POST` permite que el cliente asigne campos que no debería (el id, el estado): es la
vulnerabilidad de asignación masiva.

**02 → 9. ¿Dónde se arma el DTO, y por qué ahí? 🟠**

⏱️ Dentro de la transacción del caso de uso, en el servicio, donde las asociaciones se pueden cargar y la consulta puede
traer de una vez lo que el DTO necesita.
🗣️ Armarlo en el controlador obliga a tocar entidades separadas, con sus perezosos. En el servicio, la consulta trae los
documentos con `JOIN FETCH` y el DTO sale completo.
🔬 Para pantallas de lectura, se puede saltar la entidad: una proyección de JPQL directamente al DTO (`select new ...`),
más barata.

**02 → 10. ¿Por qué Fowler desaconseja los DTO dentro del mismo proceso? 🟠**

⏱️ Porque entre capas que podrían compartir el modelo, el costo del mapeo rara vez compensa: es mucho código que hay que
mantener a cambio de una independencia que no se necesita.
🗣️ En su bliki (*LocalDTO*) cita a Randy Stafford: no hay que subestimar el costo de los DTO, que es significativo y
doloroso. Los DTO son para fronteras remotas.
🔬 Matiz: un API REST, aunque lo sirva el mismo proceso, es una frontera remota para el cliente. Ahí el DTO sí compensa; lo
que no compensa es un DTO entre el servicio y el repositorio.

**02 → 11. ¿Cuándo una Remote Facade se vuelve un problema? 🟠**

⏱️ Cuando se escribe una por pantalla para clientes muy distintos, o cuando acumula operaciones de todo el sistema y se
vuelve la clase dios del API.
🗣️ Con muchos clientes distintos, una fachada por pantalla multiplica rutas; se diseñan recursos con algo de grano grueso o
se deja al cliente elegir los campos. Con muchas operaciones, se parte por recurso o por caso de uso.
🔬 GraphQL es en parte una respuesta a esta tensión: el cliente pide la forma que necesita en una llamada.

**02 → 12. Diseña el DTO y la operación de la ficha de una persona con sus documentos y su tutor. 🔴**

⏱️ Dos records —la ficha y el documento—, una operación de servicio de solo lectura que carga la persona con sus documentos
y arma el DTO, y una ruta que lo devuelve.
🗣️

```java
public record DocumentoDto(String tipo, String numero, LocalDate vence) {}
public record FichaPersonaDto(String nombre, int edad, List<DocumentoDto> documentos, String tutor) {}

@Transactional(readOnly = true)
public FichaPersonaDto ficha(PersonaId id, LocalDate hoy) {
    Persona p = repositorio.porIdConDocumentos(id).orElseThrow(() -> new PersonaNoEncontrada(id));
    return new FichaPersonaDto(p.nombre(), p.edad(hoy),
            p.documentos().stream().map(d -> new DocumentoDto(d.tipo().codigo(), d.numero(), d.vencimiento())).toList(),
            p.tutor().map(Persona::nombre).orElse(null));
}
```

🔬 Lo que preguntará después: por qué el tutor viaja como nombre (para cortar el ciclo y no mandar lo que la pantalla no
usa); y cómo se versiona el contrato (un DTO nuevo o campos opcionales nuevos; nunca renombrar uno existente sin una versión).

**02 → 13. Revisa este código y di qué falla: `@GetMapping public List<Persona> todas() { return repositorio.findAll(); }` con `Persona` que tiene `documentos` perezosos y `tutor`. 🔴**

⏱️ Tres problemas: expone la entidad (contrato atado al modelo), la serialización toca perezosos fuera de la transacción
(excepción o N+1) y sigue el ciclo del tutor. Y además devuelve **todas** las personas, sin paginar.
🗣️ El arreglo: un DTO de lista con lo que se muestra, armado por una consulta paginada dentro de la transacción (o una
proyección directa), y una ruta con `page` y `size`.
🔬 Lo que preguntará después: qué pasa con miles de personas (memoria y tiempo de respuesta: la paginación no es opcional);
y si `@JsonIgnore` sobre `tutor` arregla algo (corta el ciclo, pero deja la entidad como contrato y los perezosos).

**02 → 14. Una pantalla hace seis llamadas al API para pintar el resumen de una cuenta. Propón la Remote Facade. 🔴**

⏱️ Una operación `/cuentas/{numero}/resumen` que devuelve un `ResumenCuentaDto` con lo que la pantalla pinta: saldo,
estado, titulares, últimos movimientos y comisiones del mes, armado en una transacción.
🗣️

```java
public record ResumenCuentaDto(String numero, String estado, Dinero saldo, List<String> titulares,
                               List<MovimientoDto> ultimos, Dinero comisionesDelMes) {}

@GetMapping("/cuentas/{numero}/resumen")
public ResumenCuentaDto resumen(@PathVariable String numero) {
    return consulta.resumen(new CuentaId(numero), YearMonth.now(reloj));
}
```

Una ida y vuelta en lugar de seis; el servidor hace las consultas que necesite, cerca de la base.
🔬 Lo que preguntará después: qué pasa si otra pantalla necesita casi lo mismo (se reutiliza el DTO si encaja, o se hace otro:
no hay que forzar un DTO universal); y cuántos movimientos trae (un número fijo y un enlace a la lista paginada).

# 03 — Concurrencia offline

**03 → 1. ¿Qué es la actualización perdida? 🟢**

⏱️ Que dos personas lean los mismos datos, los modifiquen por separado y el segundo guardado pise al primero sin que
nadie se entere.
🗣️ Dos operadores abren la ficha de Ana; uno cambia el teléfono y otro el correo. El segundo guarda lo que vio, con el
teléfono viejo, y el cambio del primero desaparece. Las dos transacciones fueron correctas.
🔬 Es el problema central de la concurrencia *offline* de *PoEAA*: no ocurre dentro de una transacción, sino entre dos.

**03 → 2. ¿Qué es una transacción de negocio, según Fowler? 🟢**

⏱️ Lo que el usuario percibe como una sola operación —abrir la ficha, editar, guardar—, aunque se reparta en varias
peticiones y varias transacciones de la base.
🗣️ La transacción de la base dura milisegundos; la de negocio, minutos. Protegerla sin mantener la base bloqueada todo ese
tiempo es lo que resuelven los patrones de concurrencia *offline*.
🔬 Fowler lo plantea en el cap. 5 de *PoEAA*, escrito con David Rice.

**03 → 3. ¿Qué es el bloqueo optimista con versión? 🟢**

⏱️ Cada fila lleva un número de versión; al guardar, la escritura solo se aplica si la versión es la que se leyó, y la
incrementa. Si alguien guardó antes, la escritura no afecta a ninguna fila y se detecta el conflicto.
🗣️ No bloquea a nadie mientras se edita: confía en que los conflictos son raros y los detecta al final. Es Optimistic
Offline Lock.
🔬 En SQL es `UPDATE … SET …, version = version + 1 WHERE id = ? AND version = ?`; cero filas afectadas es el conflicto.

**03 → 4. ¿Qué hace `@Version` en JPA? 🟢**

⏱️ Marca el campo de versión de una entidad; el proveedor añade la comprobación de versión a cada `UPDATE`, la incrementa,
y lanza `OptimisticLockException` si otra transacción la cambió.
🗣️ La Javadoc dice que el campo sirve para detectar fallos de bloqueo optimista. Es un bloqueo implícito: ningún código de
negocio compara versiones dentro de la transacción.
🔬 El campo puede ser numérico o una marca de tiempo; el numérico es más fiable, porque dos escrituras en el mismo instante
podrían tener la misma marca.

**03 → 5. ¿Qué diferencia hay entre bloqueo optimista y pesimista? 🟡**

⏱️ El optimista no bloquea: deja que todos editen y detecta el conflicto al guardar. El pesimista bloquea al empezar:
quien llega segundo no puede editar hasta que el primero termine.
🗣️ El optimista es mejor con conflictos raros: no hay esperas ni bloqueos huérfanos. El pesimista, con conflictos
frecuentes o trabajo caro de rehacer: nadie pierde lo que hizo, pero puede esperar.
🔬 El pesimista *offline* necesita gestionar la caducidad y la liberación forzada; el optimista necesita un buen mensaje para
el usuario.

**03 → 6. ¿Qué diferencia hay entre `SELECT ... FOR UPDATE` y un Pessimistic Offline Lock? 🟡**

⏱️ `FOR UPDATE` es un bloqueo de la base que dura una transacción; el Pessimistic Offline Lock es un bloqueo de aplicación
—una fila en una tabla de bloqueos— que dura lo que dura la edición, varias peticiones.
🗣️ `FOR UPDATE` (`PESSIMISTIC_WRITE` en JPA) sirve para que dos transferencias simultáneas no lean el mismo saldo. Para que
dos operadores no editen a Ana durante minutos hace falta el bloqueo de aplicación; mantener la transacción abierta ese
tiempo sería un error.
🔬 La Javadoc de `LockModeType` describe los modos pesimistas como bloqueos de la base obtenidos de inmediato.

**03 → 7. ¿Qué diferencia hay entre una transacción de la base y una transacción de negocio? 🟡**

⏱️ La de la base es atómica y aislada, y dura una petición; la de negocio es lo que el usuario considera una operación, y
puede durar varias peticiones y minutos.
🗣️ La base garantiza que lo que pasa dentro de su transacción sea coherente; no sabe nada de lo que el usuario leyó en la
petición anterior. Esa brecha es la que cubre la versión.
🔬 Ver `03 → 2`.

**03 → 8. ¿Qué relación hay entre `@Version` y las cabeceras `ETag` e `If-Match` de HTTP? 🟡**

⏱️ Son la misma idea en el protocolo: el servidor manda una etiqueta de versión del recurso (`ETag`) y el cliente, al
modificar, manda `If-Match` con esa etiqueta; si cambió, el servidor responde `412 Precondition Failed`.
🗣️ Un API puede usar la `@Version` de la entidad como `ETag`: el bloqueo optimista viaja en cabeceras en lugar de en el
cuerpo del DTO.
🔬 Es una forma estándar de que los clientes HTTP, incluidos los que no son nuestros, respeten el bloqueo optimista.

**03 → 9. ¿Por qué la transacción de la base no evita la actualización perdida entre peticiones? 🟠**

⏱️ Porque la lectura y la escritura ocurren en transacciones distintas: la base no sabe qué leyó el usuario hace dos
minutos, y la escritura del segundo operador es, para ella, una transacción correcta.
🗣️ Subir el nivel de aislamiento tampoco ayuda: el aislamiento protege dentro de una transacción. Lo que une la lectura con
la escritura es una versión que el cliente lleva y devuelve.
🔬 Es la sobregeneralización que la ficha del capítulo pide desmontar.

**03 → 10. ¿Por qué la versión tiene que viajar en el formulario? 🟠**

⏱️ Porque al guardar hay que comparar con la versión que el operador **leyó**, no con la que hay ahora. Si el servicio
carga la entidad al guardar sin la versión del formulario, compara con la actual y el conflicto no se detecta.
🗣️ El DTO de edición lleva la versión; el servicio la compara con la de la entidad cargada y, si difieren, lanza el
conflicto. Además, `@Version` protege la ventana entre esa comparación y el `UPDATE`.
🔬 En un API, la versión puede viajar en el DTO o en `If-Match`; lo que no puede es quedarse en el servidor.

**03 → 11. ¿Qué le dices al usuario cuando hay un conflicto? 🟠**

⏱️ Qué pasó en su idioma —"la ficha de Ana cambió mientras la editabas"—, qué cambió, y qué puede hacer: recargar o aplicar
sus cambios sobre la versión nueva.
🗣️ Si los cambios no chocan campo a campo (uno cambió el teléfono, otro el correo), se pueden fusionar y pedir confirmación.
Si chocan, se muestran los dos valores. Un "error de concurrencia" sin más hace perder el trabajo.
🔬 La experiencia del conflicto es lo que decide si el bloqueo optimista es aceptable: con conflictos frecuentes y mal
gestionados, el usuario termina pidiendo el pesimista.

**03 → 12. ¿Cuándo usarías el bloqueo pesimista *offline*, y qué problema trae? 🟠**

⏱️ Cuando los conflictos son frecuentes o rehacer el trabajo es caro. El problema es soltarlo: el operador cierra el
navegador y el bloqueo queda.
🗣️ Hace falta caducidad (el bloqueo vence a los quince minutos), liberación forzada por un supervisor, y una forma de ver
quién tiene bloqueado qué. Sin eso, aparecen fichas que nadie puede editar.
🔬 Se toma de forma atómica con la clave primaria de la tabla de bloqueos: dos operadores que intentan a la vez, uno gana.

**03 → 13. ¿Por qué añadir un movimiento puede necesitar bloquear la cuenta, si no cambia ninguno de sus campos? 🟠**

⏱️ Porque el invariante es del grupo: el saldo que resulta de todos los movimientos no puede quedar negativo. Dos
operaciones que insertan un movimiento cada una no chocan en ninguna fila, y juntas pueden romperlo.
🗣️ Es el Coarse-Grained Lock: la versión de la raíz (la cuenta) protege al grupo. Cada operación que añade un movimiento
sube la versión de la cuenta con `OPTIMISTIC_FORCE_INCREMENT`, y la segunda falla.
🔬 Es la idea del agregado de DDD: la raíz es la frontera de consistencia y la unidad de bloqueo. Si el saldo se guarda en
la cuenta, actualizarlo ya cambia la cuenta y la versión sube sola.

**03 → 14. Escribe la entidad `Persona` con `@Version` y el servicio que guarda una edición comprobando la versión leída. 🔴**

⏱️ Una entidad con un campo `@Version`, un DTO de edición que lleva la versión leída, y un servicio que la compara con la
de la entidad antes de modificar.
🗣️

```java
@Entity
public class Persona {
    @Id private Long id;
    @Version private long version;
    private String telefono;
    private String email;
    public long getVersion() { return version; }
    public void corregirContacto(String telefono, String email) { this.telefono = telefono; this.email = email; }
}

public record EdicionPersonaDto(long id, long version, String telefono, String email) {}

@Transactional
public void guardar(EdicionPersonaDto dto) {
    Persona p = em.find(Persona.class, dto.id());
    if (p.getVersion() != dto.version()) throw new ConflictoDeEdicionException(dto.id());
    p.corregirContacto(dto.telefono(), dto.email());
}
```

🔬 Lo que preguntará después: qué pasa si dos guardados llegan a la vez con la misma versión correcta (los dos pasan la
comparación, pero el segundo `UPDATE` con `AND version = ?` afecta a cero filas y JPA lanza `OptimisticLockException`); y
cómo se traduce al API (un `409 Conflict` con lo que cambió).

**03 → 15. Escribe el SQL de un `UPDATE` con bloqueo optimista y di qué significa que afecte a cero filas. 🔴**

⏱️ Un `UPDATE` que incrementa la versión y lleva la versión leída en el `WHERE`; cero filas afectadas significa que otro
guardó antes (o que la fila ya no existe).
🗣️

```sql
UPDATE persona
SET telefono = '+57 301 555 0199', version = version + 1
WHERE id = 1 AND version = 7;
-- 1 fila: nadie la cambió desde que se leyó la versión 7
-- 0 filas: la versión ya no es 7 (o la persona se borró): conflicto
```

🔬 Lo que preguntará después: cómo se distingue el conflicto del borrado (una consulta posterior por id); y por qué no un
`SELECT` antes del `UPDATE` (porque entre los dos alguien puede escribir: la comprobación tiene que ir en la misma
sentencia).

**03 → 16. Revisa este diseño: el servicio de edición abre una transacción al cargar la ficha y la confirma cuando el operador pulsa "guardar". Di qué falla y cómo lo corriges. 🔴**

⏱️ Mantiene una transacción de la base abierta mientras el operador piensa: retiene una conexión del pool, puede retener
bloqueos, y si el operador se va a almorzar, la transacción queda colgada.
🗣️ La corrección es separar: una transacción corta para leer (que devuelve el DTO con la versión), y otra corta para
guardar (que compara la versión). La transacción de negocio queda protegida por la versión, no por la base.
🔬 Lo que preguntará después: qué pasa con cien operadores (cien conexiones retenidas: el pool se agota); y si alguna vez
tiene sentido una transacción larga (en procesos por lotes sin usuario, sí, con cuidado; con un usuario en medio, nunca).

# 04 — Estado de sesión

**04 → 1. ¿Qué es el estado de sesión? 🟢**

⏱️ Lo que pertenece a una conversación con un usuario y dura lo que dura la conversación: quién es, qué escribió en las
pantallas anteriores de un asistente, qué tiene en el carrito.
🗣️ No es dato de negocio todavía: los datos del asistente de alta no son una persona hasta que pasan las validaciones.
Por eso no van en la tabla `persona`, y hay que decidir dónde viven mientras tanto.
🔬 Fowler lo trata en el cap. 6 de *PoEAA* y da tres sitios: el cliente, el servidor y la base de datos.

**04 → 2. ¿Qué es Client Session State? 🟢**

⏱️ Guardar el estado de la conversación en el cliente y mandarlo en cada petición; el servidor no guarda nada.
🗣️ Hoy es la aplicación de una sola página que guarda el asistente en memoria y manda todo al final, o el *token* firmado
que lleva la identidad del usuario. Cualquier servidor atiende cualquier petición.
🔬 Lo que llega del cliente se valida siempre: la firma de un *token* garantiza que nadie lo alteró, no que los datos de
negocio sean correctos.

**04 → 3. ¿Qué es Server Session State? 🟢**

⏱️ Guardar el estado en la memoria del servidor, en un objeto de sesión, y mandar al cliente solo un identificador.
🗣️ La `HttpSession` de los servlets en su forma por defecto. Es lo más simple de programar y ata al usuario a un servidor:
con varios, hace falta afinidad o réplica, y un reinicio pierde las sesiones.
🔬 La API de `HttpSession` se puede conservar con otra implementación: Spring Session la respalda con un almacén externo
sin cambiar el código.

**04 → 4. ¿Qué es Database Session State? 🟢**

⏱️ Guardar el estado de la conversación en una base de datos, como datos que todavía no son definitivos, y recuperarlo con
el identificador de sesión desde cualquier servidor.
🗣️ Una tabla `alta_en_curso` con los datos del asistente y su caducidad. Sobrevive a reinicios y a días; a cambio, cada paso
escribe en la base y hay que limpiar lo abandonado.
🔬 Para borradores que el usuario retoma otro día (una solicitud a medias), sigue siendo lo correcto, modelado como una
entidad borrador con su estado.

**04 → 5. ¿Qué diferencia hay entre guardar la sesión en memoria y en un almacén compartido? 🟡**

⏱️ En memoria, la sesión es de una instancia: si el usuario cae en otra, o la instancia se reinicia, la sesión no está. En
un almacén compartido (Redis), todas las instancias la ven.
🗣️ El almacén cuesta una llamada de red por petición y una pieza de infraestructura más; la memoria cuesta afinidad,
sesiones perdidas en cada despliegue y memoria que crece con los usuarios.
🔬 Con contenedores que se crean y destruyen a menudo, la memoria no es una opción real para el estado que importa.

**04 → 6. ¿Qué diferencia hay entre un *token* firmado y un identificador de sesión? 🟡**

⏱️ El *token* lleva el estado dentro (quién es el usuario, sus permisos) y está firmado para que no se pueda alterar; el
identificador de sesión es solo una clave para buscar el estado en el servidor.
🗣️ Con *token*, el servidor no consulta nada para saber quién es el usuario; con identificador, consulta el almacén. Pero un
*token* emitido no se puede revocar antes de caducar sin una lista de revocados, que es estado en el servidor otra vez.
🔬 JWT es el formato estándar (RFC 7519). Los *tokens* de vida corta con renovación limitan el problema de la revocación.

**04 → 7. ¿Qué diferencia hay entre un borrador en la base y una sesión en Redis? 🟡**

⏱️ El borrador es un dato de negocio con su propio estado, que dura lo que el negocio diga y se consulta como cualquier otro;
la sesión en Redis es efímera, caduca sola y solo la ve quien tiene el identificador.
🗣️ Para un asistente que se termina en diez minutos, la sesión. Para una solicitud de crédito que el usuario retoma mañana y
que un analista puede ver, el borrador.
🔬 Si el borrador tiene reglas propias (qué se puede guardar a medias, cuándo caduca), es una entidad del dominio, no estado
de sesión.

**04 → 8. ¿Por qué "un servicio sin estado no tiene estado de sesión" es falso? 🟠**

⏱️ Porque "sin estado" significa que el servicio no guarda la sesión en su memoria; la sesión sigue existiendo, en el cliente
o en un almacén compartido.
🗣️ La respuesta precisa a "¿tu servicio tiene estado?" es "en memoria no; la sesión está en el *token* y en Redis". La
pregunta siguiente —"¿y si Redis se cae?"— es la que muestra que se sabe dónde está el estado.
🔬 El estado se muda, no desaparece: decidir dónde vive es la decisión de diseño.

**04 → 9. ¿Por qué la sesión en memoria es un problema con contenedores? 🟠**

⏱️ Porque los contenedores se crean, se destruyen y se mueven a menudo: cada despliegue o reubicación borra las sesiones de
memoria, y el balanceador puede mandar al usuario a una instancia que no la tiene.
🗣️ La afinidad de sesión mitiga lo segundo y empeora el reparto de carga; la réplica de sesiones entre instancias es
compleja. Lo habitual es sacar la sesión a un almacén externo.
🔬 Es una de las razones de que los servicios "sin estado en el proceso" sean el valor por defecto en las plataformas de
contenedores.

**04 → 10. ¿Qué validas de lo que manda el cliente, aunque venga en un *token* firmado? 🟠**

⏱️ La firma y la caducidad del *token*, y todos los datos de negocio que lleguen en la petición como si nunca se hubieran
validado: formato, permisos sobre el recurso pedido, invariantes.
🗣️ La firma garantiza que el *token* lo emitió el servidor y no se alteró; no garantiza que el usuario pueda ver la cuenta
que pide. Y los datos del asistente que guardó el cliente pueden haberse manipulado.
🔬 La regla: la integridad del *token* es una cosa, la autorización de cada operación es otra, y la validación de los datos
de negocio, una tercera.

**04 → 11. Diseña dónde vive el estado del asistente de alta de tres pantallas si el cliente es una aplicación de una página. 🔴**

⏱️ En el cliente: la aplicación guarda los datos de cada pantalla en su memoria y, al final, manda la solicitud completa en
una sola petición, que el servidor valida entera y convierte en una persona.
🗣️

```java
public record SolicitudAltaCompleta(DatosBasicos basicos, List<DocumentoDto> documentos, ContactoDto contacto) {}

@PostMapping("/altas")
public ResponseEntity<PersonaId> alta(@RequestBody @Valid SolicitudAltaCompleta s) {
    return ResponseEntity.status(201).body(altaPersonas.alta(s));   // las reglas del dominio, todas aquí
}
```

El servidor no guarda nada entre pantallas. Si cada pantalla necesita validaciones parciales, se ofrecen como consultas
sin efecto (`/altas/validar-documento`), que tampoco guardan estado.
🔬 Lo que preguntará después: qué pasa si el usuario recarga la página (pierde lo escrito, salvo que la aplicación lo guarde en
el almacenamiento del navegador); y cuándo no harías esto (si el usuario debe poder retomar el alta desde otro dispositivo:
entonces, un borrador en el servidor).

**04 → 12. Revisa este diseño: tres instancias del servicio detrás de un balanceador sin afinidad, y el asistente de alta guarda sus datos en la `HttpSession` en memoria. Di qué falla y cómo lo corriges. 🔴**

⏱️ Cada paso del asistente puede caer en una instancia distinta, que no tiene la sesión: el operador llega al tercer paso y
sus datos no están. Y cualquier reinicio borra las sesiones de esa instancia.
🗣️ Las correcciones, de la mejor a la peor: mover el estado al cliente y mandar todo al final; respaldar la `HttpSession` con
un almacén compartido (Spring Session con Redis), sin cambiar el código; o activar afinidad en el balanceador, que oculta el
problema hasta el siguiente despliegue.
🔬 Lo que preguntará después: por qué funcionaba en desarrollo (una sola instancia); y qué pasa si Redis se cae (nadie tiene
sesión: es un componente crítico más, que hay que replicar y vigilar).

# 05 — Patrones base

**05 → 1. ¿Qué es un Value Object? 🟢**

⏱️ Un objeto sin identidad que vale por su contenido: igualdad por valor, inmutable y que se valida al construirse.
🗣️ `Dinero`, `RangoFechas`, `Direccion`: dos con el mismo contenido son intercambiables, nadie los modifica (las
operaciones devuelven uno nuevo) y no pueden existir en un estado inválido.
🔬 Fowler lo incluye en el cap. 18 de *PoEAA*; Evans lo hace pieza central del diseño táctico. El concepto está en `02/06`;
este capítulo es el dueño del patrón.

**05 → 2. ¿Qué es el patrón Money? 🟢**

⏱️ Un Value Object para dinero: monto y moneda, con la escala de la moneda, operaciones que comprueban la moneda, y un
reparto que no pierde centavos.
🗣️ `Dinero(BigDecimal, Currency)` con `mas`, `repartir` y la escala normalizada en el constructor. Fowler se sorprende en su
ficha de que ninguna librería base corriente lo traiga.
🔬 En C++ se suele escribir con un entero de unidades menores, que hace exactas las sumas.

**05 → 3. ¿Qué es un Special Case? 🟢**

⏱️ Una subclase o implementación que da el comportamiento correcto para un caso particular —típicamente, que algo no
existe—, y que se devuelve en lugar de `null`.
🗣️ `CuentaDesconocida` en un informe: responde "Titular desconocido" y saldo cero, y el informe no tiene ni un `if`. Fowler
lo define como una subclase que da el comportamiento especial para casos particulares.
🔬 El Null Object es su caso más conocido. Tiene su capítulo en [`09/03`](../09-ddd-tactico-y-otros/03-specification-null-object-y-type-object.md).

**05 → 4. ¿Qué es un Gateway? 🟢**

⏱️ Un objeto que encapsula el acceso a un sistema o recurso externo, con una interfaz en términos de quien lo usa.
🗣️ `VerificadorIdentidad` es el Gateway al proveedor de verificación; la pasarela de SMS tiene el suyo. El resto del código
no ve la API ajena.
🔬 Fowler lo usa como término general: el Table Data Gateway es un Gateway a una tabla.

**05 → 5. ¿Qué es Separated Interface, y con qué principio coincide? 🟢**

⏱️ Definir la interfaz en un paquete y su implementación en otro, para que quien usa la interfaz no dependa de la
implementación. Coincide con la inversión de dependencias.
🗣️ `RepositorioPersonas` vive en el dominio; `RepositorioPersonasJpa`, en la infraestructura. El dominio se compila sin JPA.
🔬 Ver `03/02` §6. Es el mecanismo de los puertos de la arquitectura hexagonal.

**05 → 6. ¿Qué es un Layer Supertype, y qué riesgo tiene? 🟢**

⏱️ Una clase base para todos los objetos de una capa, con lo que comparten: una `EntidadBase` con `id` y `version`.
🗣️ El riesgo es la herencia usada para reutilizar: todo queda acoplado a la base, y cualquier cosa "común" acaba en ella
hasta que la base es una clase dios.
🔬 En JPA es `@MappedSuperclass`. Con moderación —solo identidad y versión— es razonable; para comportamiento, mejor
composición.

**05 → 7. ¿Qué diferencia hay entre un Value Object y una entidad? 🟡**

⏱️ La entidad tiene identidad que se sigue en el tiempo aunque cambie su estado; el Value Object no tiene identidad y vale
por su contenido.
🗣️ Ana sigue siendo Ana si cambia de nombre; un `Dinero` de 250 000 COP es igual a cualquier otro de 250 000 COP. La
entidad es mutable en lo que cambia; el valor, inmutable.
🔬 Ver `02/06` §2. Depende del contexto: una dirección es un valor para un banco y una entidad para un catastro.

**05 → 8. ¿Qué diferencia hay entre un Value Object y un `record`? 🟡**

⏱️ El Value Object es un concepto; el `record` es una forma de escribirlo en Java que da igualdad por campos y campos
`final`, pero no garantiza inmutabilidad profunda ni validación.
🗣️ Un `record` con una `List` mutable dentro no es inmutable; uno con un `BigDecimal` sin normalizar compara `1.0` y `1.00`
como distintos; uno sin constructor compacto no se valida. El patrón pide las tres cosas.
🔬 Ver `01/02` y `01/03` §5. Un Value Object se puede escribir sin `record` (una clase `final`) y un `record` puede no ser un
Value Object (un DTO).

**05 → 9. ¿Qué diferencia hay entre Special Case y Null Object? 🟡**

⏱️ El Null Object es un Special Case concreto: el que representa "no hay nada" y no hace nada. El Special Case es más
general y puede llevar datos.
🗣️ `CuentaDesconocida(numero)` lleva el número que no se encontró y responde con un texto; un Null Object puro no tendría
datos. Los dos evitan los `null` y los `if` repetidos.
🔬 Fowler presenta Special Case en *PoEAA*; el Null Object se popularizó antes en otros catálogos. El corpus lo desarrolla en
[`09/03`](../09-ddd-tactico-y-otros/03-specification-null-object-y-type-object.md).

**05 → 10. ¿Qué diferencia hay entre Gateway y Adapter? 🟡**

⏱️ Gateway nombra el papel —la puerta a un sistema externo—; Adapter nombra la técnica —hacer encajar una interfaz en otra.
Un Gateway suele implementarse con un Adapter.
🗣️ `VerificadorIdentidad` es el Gateway; `VerificadorIdCheck`, que traduce al SDK del proveedor, es el Adapter. Si el sistema
externo ya tuviera la interfaz que queremos, el Gateway no necesitaría adaptar nada.
🔬 Ver `05/01`.

**05 → 11. ¿Qué diferencia hay entre un objeto de valor en C++ y en Java? 🟡**

⏱️ En C++ los objetos son valores por defecto: se copian al asignar y `operator==` se genera en C++20. En Java todo objeto va
por referencia, y la igualdad por valor y la inmutabilidad hay que pedirlas: `record` y campos `final`.
🗣️ En C++ el riesgo es usar punteros donde iba un valor; en Java, olvidar que dos referencias al mismo objeto mutable lo
comparten. Por eso en Java la inmutabilidad es parte del patrón, y en C++ es casi gratis.
🔬 Ver `01/01` y `01/04`. En C++ un valor puede ser mutable sin riesgo de *aliasing*, porque cada copia es suya.

**05 → 12. ¿Por qué dividir y redondear pierde centavos, y cómo lo evita `repartir`? 🟠**

⏱️ Porque cada parte se redondea por separado: 1 000,00 entre tres son 333,33 tres veces, que suman 999,99. `repartir`
calcula las partes en centavos hacia abajo y asigna el resto, un centavo a cada una, hasta llegar al total.
🗣️ El resultado es 333,34, 333,33 y 333,33: suman exactamente 1 000,00. A quién va el centavo extra es una decisión del
negocio; que vaya a alguien no es negociable.
🔬 Es el `allocate` del patrón Money de Fowler. Con proporciones (70 % y 30 %) funciona igual.

**05 → 13. ¿Por qué `HALF_EVEN` y no `HALF_UP` para dinero? 🟠**

⏱️ Porque `HALF_UP` redondea siempre hacia arriba los medios, y con muchas cantidades acumula un sesgo; `HALF_EVEN` redondea
los medios al par más cercano, y los errores se compensan.
🗣️ Es el "redondeo bancario". En una sola operación da igual; en millones de intereses o comisiones, `HALF_UP` sistemáticamente
cobra o paga de más.
🔬 La regla legal manda: algunas normas fijan un redondeo concreto, y entonces se usa ese, documentado en `Dinero`.

**05 → 14. ¿Cuándo un Special Case esconde un error en lugar de resolverlo? 🟠**

⏱️ Cuando la ausencia es un error que alguien debería ver: una transferencia a una cuenta inexistente no puede "debitar cero"
en silencio.
🗣️ El Special Case sirve cuando todos los llamadores quieren el mismo comportamiento por defecto (un informe). Si cada uno
debe decidir, `Optional` lo obliga; si es un error, una excepción lo dice.
🔬 Un Null Object en la lógica de negocio que traga operaciones es una fuente clásica de errores silenciosos.

**05 → 15. ¿Por qué Registry es estado global, y qué lo reemplaza? 🟠**

⏱️ Porque es un objeto accesible desde cualquier parte que entrega servicios bajo demanda: las clases dependen de él sin
decirlo, igual que con un Singleton o un Service Locator. Lo reemplaza la inyección de dependencias.
🗣️ `Registro.repositorioPersonas()` dentro de un servicio esconde la dependencia y obliga a configurar el registro en cada
test. Con inyección por constructor, la dependencia está en la firma.
🔬 Ver `04/05` y `04/06`. Fowler lo presenta con sus advertencias; en 2002 la inyección de dependencias todavía no tenía
nombre.

**05 → 16. ¿Por qué la conversión entre monedas no es una operación de `Dinero`? 🟠**

⏱️ Porque necesita una tasa de cambio, que depende de la fecha, de la fuente y a veces del tipo de operación; un objeto de
valor no puede saber eso sin depender de un servicio externo.
🗣️ La conversión es un servicio (`ConversorMonedas.convertir(dinero, monedaDestino, fecha)`) que usa una tasa y devuelve un
`Dinero` nuevo. `Dinero` solo garantiza que no se mezclen monedas sin pasar por ahí.
🔬 Además, la conversión implica redondeo y a veces comisión: es una operación del negocio con sus reglas, no aritmética.

**05 → 17. Escribe `Dinero.repartir` en Java y muestra el reparto de 1 000,00 COP entre tres. 🔴**

⏱️ Pasar el monto a centavos, calcular cada parte hacia abajo según su proporción, y repartir los centavos que falten uno a
uno desde la primera.
🗣️

```java
public List<Dinero> repartir(int... proporciones) {
    int escala = moneda.getDefaultFractionDigits();
    long total = monto.movePointRight(escala).longValueExact();
    long suma = IntStream.of(proporciones).asLongStream().sum();
    long[] partes = new long[proporciones.length];
    long asignado = 0;
    for (int i = 0; i < partes.length; i++) {
        partes[i] = total * proporciones[i] / suma;
        asignado += partes[i];
    }
    for (int i = 0; asignado < total; i++, asignado++) partes[i]++;
    return LongStream.of(partes).mapToObj(c -> new Dinero(BigDecimal.valueOf(c, escala), moneda)).toList();
}

List<Dinero> partes = Dinero.cop("1000.00").repartir(1, 1, 1);   // → 333.34, 333.33, 333.33
```

🔬 Lo que preguntará después: qué pasa con montos negativos (la división hacia cero cambia el sentido del redondeo: hay que
tratarlos aparte o rechazarlos); y si `total * proporciones[i]` puede desbordar (con montos enormes y proporciones grandes,
sí: se usa `Math.multiplyExact` o `BigInteger`).

**05 → 18. Escribe en C++ un `Dinero` con centavos en un entero y su operación de reparto. 🔴**

⏱️ Una clase con `std::int64_t centavos` y la moneda, suma que comprueba la moneda, y `repartir` con la misma lógica: partes
hacia abajo y resto uno a uno.
🗣️

```cpp
class Dinero {
public:
    Dinero(std::int64_t c, Moneda m) : centavos{c}, moneda{m} {}
    Dinero operator+(const Dinero& o) const {
        if (moneda != o.moneda) throw std::invalid_argument{"monedas distintas"};
        return {centavos + o.centavos, moneda};
    }
    std::vector<Dinero> repartir(std::span<const int> proporciones) const {
        std::int64_t suma = std::accumulate(proporciones.begin(), proporciones.end(), std::int64_t{0});
        std::vector<Dinero> partes;
        std::int64_t asignado = 0;
        for (int p : proporciones) { partes.emplace_back(centavos * p / suma, moneda); asignado += partes.back().centavos; }
        for (std::size_t i = 0; asignado < centavos; ++i, ++asignado) partes[i].centavos += 1;
        return partes;
    }
    bool operator==(const Dinero&) const = default;
private:
    std::int64_t centavos;
    Moneda moneda;
};
```

🔬 Lo que preguntará después: por qué no `double` (las sumas de centavos en coma flotante pierden exactitud; con enteros son
exactas); y qué pasa con monedas sin decimales o con tres (la unidad menor cambia: `Moneda` debería saber su escala).

**05 → 19. Escribe un Special Case para una cuenta desconocida en un informe de movimientos. 🔴**

⏱️ Una interfaz sellada para lo que el informe necesita, con la cuenta real y un `record CuentaDesconocida` que responde
valores por defecto; el repositorio devuelve la desconocida cuando no encuentra.
🗣️

```java
public sealed interface CuentaParaInforme permits CuentaReal, CuentaDesconocida {
    String titular();
    Dinero saldo();
}
public record CuentaReal(Cuenta cuenta) implements CuentaParaInforme {
    public String titular() { return cuenta.titular().nombre(); }
    public Dinero saldo() { return cuenta.saldo(); }
}
public record CuentaDesconocida(String numero) implements CuentaParaInforme {
    public String titular() { return "Titular desconocido (" + numero + ")"; }
    public Dinero saldo() { return Dinero.cop("0.00"); }
}

CuentaParaInforme c = repositorio.porNumero(numero).<CuentaParaInforme>map(CuentaReal::new)
        .orElse(new CuentaDesconocida(numero));
```

🔬 Lo que preguntará después: por qué no usar esto en las transferencias (porque ahí la cuenta inexistente es un error y debe
fallar); y en qué moneda va el saldo cero (es una simplificación: el informe debería saber la moneda de la cuenta, o el
caso especial no debería tener saldo).

**05 → 20. Revisa este código y di qué falla: `record Dinero(double monto, String moneda) {}` usado para sumar el saldo de `CTA-0001` (COP) y `CTA-0002` (USD). 🔴**

⏱️ Dos defectos: `double` no representa la mayoría de los decimales y acumula errores; y nada impide sumar COP con USD, que es
justo lo que hace el código. Además la moneda es un `String` que acepta cualquier cosa.
🗣️ El arreglo es el `Dinero` del patrón: `BigDecimal` (o centavos en `long`) con la escala de la moneda, `Currency` en lugar de
`String`, y `mas` que lanza si las monedas difieren. Sumar saldos de monedas distintas exige convertir primero, con una tasa.
🔬 Lo que preguntará después: cómo se guarda en la base (`NUMERIC(19, 2)` y un código ISO de tres letras, como un Embedded
Value); y qué significa "el saldo total de Ana" si tiene cuentas en dos monedas (una suma por moneda, o una conversión a una
moneda de referencia con fecha y tasa: es una pregunta del negocio).

# 06 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
ejercicios, desarrollados al final.

**06 → S1. ¿Qué diferencia hay entre el MVC original y Spring MVC? 🟡**

Ver `01 → 6` y `01 → 10`.

**06 → S2. ¿Por qué el `DispatcherServlet` es un Front Controller? 🟢**

Ver `01 → 2` y `01 → 12`.

**06 → S3. ¿Qué reemplazó a las vistas de plantilla en un *backend* que sirve a una aplicación de una sola página? 🟡**

⏱️ La serialización a JSON de DTO: el servidor devuelve datos y el cliente genera el HTML con sus propios componentes y
plantillas.
🗣️ Template View, Transform View y Two Step View siguen siendo lo normal en aplicaciones que generan HTML en el servidor; en
un API, la "vista" es la forma del DTO y su conversión a JSON.
🔬 Ver `01 → 9` y `01 → 11`.

**06 → S4. ¿Qué dice la primera ley de Fowler de los objetos distribuidos? 🟢**

Ver `02 → 1`.

**06 → S5. ¿Por qué no exponer la entidad en el API? 🟠**

Ver `02 → 8`.

**06 → S6. ¿Dónde se arma el DTO, y por qué? 🟠**

Ver `02 → 9`.

**06 → S7. ¿Por qué Fowler desaconseja los DTO dentro del mismo proceso? 🟠**

Ver `02 → 10`.

**06 → S8. ¿Qué diferencia hay entre un DTO y un Value Object? 🟡**

Ver `02 → 5`.

**06 → S9. ¿Por qué la transacción de la base no evita la actualización perdida entre peticiones? 🟠**

Ver `03 → 9`.

**06 → S10. ¿Qué diferencia hay entre `SELECT ... FOR UPDATE` y un Pessimistic Offline Lock? 🟡**

Ver `03 → 6`.

**06 → S11. ¿Qué le dices al usuario cuando hay un conflicto de edición? 🟠**

Ver `03 → 11`.

**06 → S12. ¿Por qué "un servicio sin estado no tiene estado de sesión" es falso? 🟠**

Ver `04 → 8`.

**06 → S13. ¿Qué relación hay entre `@Version` y `ETag`? 🟡**

Ver `03 → 8`.

**06 → S14. ¿Por qué añadir un movimiento puede requerir bloquear la cuenta? 🟠**

Ver `03 → 13`.

**06 → S15. ¿Qué hace de un objeto un Value Object, y por qué un `record` no basta? 🟡**

Ver `05 → 1` y `05 → 8`.

**06 → S16. ¿Cómo repartes 1 000,00 COP entre tres titulares sin perder centavos? 🟠**

Ver `05 → 12` y `05 → 17`.

**06 → S17. ¿Por qué `HALF_EVEN` para dinero? 🟠**

Ver `05 → 13`.

**06 → S18. ¿Qué diferencia hay entre Special Case y `Optional`? 🟡**

⏱️ El Special Case da un comportamiento por defecto y nadie tiene que preguntar; `Optional` obliga a cada llamador a decidir
qué hacer cuando no hay valor.
🗣️ En un informe, `CuentaDesconocida` es mejor: todos quieren "titular desconocido" y saldo cero. En una transferencia,
`Optional` (o una excepción) es mejor: cada caso decide, y la ausencia no se puede tapar.
🔬 Ver `05 → 3` y `05 → 14`. `Optional` está pensado para valores de retorno, según su propia Javadoc (`01/08`).

**06 → S19. ¿Qué diferencia hay entre Gateway y Adapter? 🟡**

Ver `05 → 10`.

**06 → S20. ¿Qué es Separated Interface en el vocabulario de hoy? 🟢**

Ver `05 → 5`.

**06 → S21. ¿Cómo se escribe `Dinero` en C++ y por qué así? 🟡**

⏱️ Con el monto en la unidad menor (centavos) en un `std::int64_t` y la moneda, porque C++ no tiene un decimal exacto
estándar y los enteros hacen exactas las sumas.
🗣️ La suma comprueba la moneda, `operator==` se genera por defecto, y el reparto trabaja directamente en centavos. La escala
de cada moneda la tiene que saber `Moneda`.
🔬 Ver `05 → 18` y `02/06` §5. Para cálculos con muchos decimales (tasas de interés), se usa una librería decimal o se fija
una escala intermedia mayor.

**06 → S22. ¿Por qué un objeto de valor es más natural en C++ que en Java? 🟡**

Ver `05 → 11`.

**06 → S23. "Usamos los mismos objetos de JPA en el API: menos clases, menos mapeo." ¿Qué respondes? 🔴**

⏱️ Que el ahorro es de la primera semana: lo cobran los perezosos fuera de sesión, los ciclos al serializar, los campos
internos expuestos y los clientes que se rompen cada vez que cambia el dominio.
🗣️ Propondría DTO solo en la frontera del API, armados dentro de la transacción, y nada de DTO entre capas internas. Es
menos mapeo del que temen, y el API deja de cambiar por accidente.
🔬 Además, recibir la entidad en un `POST` abre la asignación masiva: el cliente puede mandar campos que no debería, como el
estado o el id. Ver `02 → 8`.

**06 → S24. "Para evitar conflictos de edición, bloqueamos la fila mientras el usuario edita." ¿Qué le dices? 🔴**

⏱️ Que eso es mantener una transacción abierta mientras el usuario piensa: retiene conexiones, bloquea a otros y deja bloqueos
colgados si el usuario se va. El conflicto se resuelve con bloqueo optimista o, si hace falta, con un bloqueo de aplicación
con caducidad.
🗣️ `SELECT ... FOR UPDATE` es para la concurrencia dentro de una transacción corta. Para minutos de edición, `@Version` con la
versión en el formulario; y si los conflictos son frecuentes, una tabla de bloqueos con caducidad.
🔬 Ver `03 → 16`. La pregunta que lo deja claro: "¿qué pasa si el operador se va a almorzar con la ficha abierta?".

**06 → S25. "El dinero en `double` está bien, redondeamos al mostrar." ¿Cómo lo desmontas? 🔴**

⏱️ Con un ejemplo: `0.1 + 0.2` no es `0.3` en `double`, y en miles de operaciones los errores se acumulan antes de mostrar
nada. Redondear al final no recupera lo que se perdió en cada suma intermedia.
🗣️ Además, no hay un sitio único donde redondear: los saldos se guardan, se comparan y se suman entre sí. Y un `double` no sabe
su moneda. `Dinero` con `BigDecimal` o centavos en `long` resuelve las dos cosas.
🔬 Ver `02/06` §5 y `05 → 20`. En la base, el mismo problema: `NUMERIC`, nunca `DOUBLE`.

**06 → S26. "Nuestros servicios son *stateless*, así que no tenemos que pensar en sesiones." ¿Qué preguntas? 🔴**

⏱️ Dónde está el estado que sí existe: la identidad del usuario, lo que lleva escrito en un asistente, el carrito. Si no está
en la memoria del servicio, está en el *token*, en un almacén compartido o en la base, y cada sitio tiene su precio.
🗣️ Y qué pasa cuando ese sitio falla o se llena: un *token* que no se puede revocar, un Redis que se cae, borradores que nadie
limpia. "Sin estado en el proceso" es una buena decisión que obliga a pensar más en la sesión, no menos.
🔬 Ver `04 → 8`. El E5 de esta simulación es el caso de un servicio que se creía *stateless* y no lo era.

**06 → S27. Te piden que nombres los once patrones base de Fowler. ¿Qué haces si no los recuerdas todos? 🔴**

⏱️ Nombro los que importan y explico por qué: Value Object, Money, Special Case y Gateway, que se usan a diario; y digo que el
resto (Registry, Plugin, Service Stub…) los reemplazaron la inyección de dependencias y los dobles de prueba.
🗣️ Recitar la lista no aporta; mostrar que se sabe cuáles siguen vivos y qué ocupó el lugar de los demás, sí. Si me dejo uno,
lo digo y sigo.
🔬 La lista completa: Gateway, Mapper, Layer Supertype, Separated Interface, Registry, Value Object, Money, Special Case,
Plugin, Service Stub y Record Set.

**06 → S28. "MVC está obsoleto, ahora todo es API." ¿Estás de acuerdo? 🔴**

⏱️ No: lo que cambió es dónde está la vista. La separación entre dominio y presentación sigue igual de vigente; en un API, la
vista es el DTO y su serialización, y el MVC con observación del modelo vive en el *frontend*.
🗣️ Spring MVC se sigue llamando así y sirve APIs: controladores, modelo, y una "vista" que es JSON. El patrón sobrevivió
adaptándose, como casi todos los de este bloque.
🔬 Ver `01 → 10` y `01 → 11`.

**06 → S29. "Un `NullCuenta` en todas partes nos ahorró los `NullPointerException`." ¿Qué riesgo ves? 🔴**

⏱️ Que convierte errores en silencio: una transferencia a una cuenta inexistente que "debita" de un `NullCuenta` no hace nada y
no avisa. El `NullPointerException` era molesto, pero decía la verdad.
🗣️ Un Special Case sirve donde todos los llamadores quieren el mismo comportamiento por defecto (un informe). Donde la ausencia
es un error, `Optional` o una excepción obligan a tratarla.
🔬 Ver `05 → 14`. La pregunta de revisión: ¿qué hace cada operación del objeto nulo, y es eso lo correcto en **todos** los sitios
donde se usa?

**06 → S30. "¿Para qué `repartir`, si la diferencia es un centavo?" 🔴**

⏱️ Porque es un centavo por operación, y un banco hace millones. El libro contable deja de cuadrar, y la diferencia no está en
ninguna cuenta: es dinero que desapareció o que apareció de la nada.
🗣️ Además, una auditoría detecta enseguida que la suma de las partes no es el total. `repartir` no es una optimización: es la
condición para que el sistema sea correcto.
🔬 Ver `05 → 12`.

---

**06 → E1. El DTO de alta de persona.**

**Enunciado.** El contrato de entrada y de respuesta del alta de una persona con documentos, contacto y tutor opcional.

**El primer diseño que sale.** Recibir la entidad `Persona` en el `POST` y devolverla.

**El bueno.** Un DTO de entrada con lo que el cliente puede mandar, validado en forma en el borde; las reglas, en el dominio:

```java
public record DocumentoAltaDto(@NotBlank String tipo, @NotBlank String numero, LocalDate emision, LocalDate vence) {}
public record SolicitudAltaDto(@NotBlank String nombre, @NotNull LocalDate fechaNacimiento,
                               @Email String email, String telefono, Long tutorId,
                               @NotEmpty List<@Valid DocumentoAltaDto> documentos) {}
public record AltaCreadaDto(long id, String nombre) {}

@PostMapping("/personas")
public ResponseEntity<AltaCreadaDto> alta(@RequestBody @Valid SolicitudAltaDto s) {
    PersonaId id = altaPersonas.alta(s);
    return ResponseEntity.created(URI.create("/personas/" + id.valor())).body(new AltaCreadaDto(id.valor(), s.nombre()));
}
```

- En el DTO: que los campos existan y tengan forma (no vacío, correo con formato). En el dominio: que un menor tenga tutor
  mayor, que el número cumpla el formato de su tipo, que no haya documentos repetidos.
- El DTO no tiene `id` ni `estado`: el cliente no los puede asignar.

**Lo que cuesta.** Tres records y un mapeo en el servicio. A cambio, el contrato es estable y explícito.

**Lo que preguntará después.** Por qué no validar todo con anotaciones en el DTO (las reglas que cruzan objetos o dependen del
reloj son del dominio, y se saltarían en la importación nocturna); y qué se devuelve en el error (un `422` con la regla
violada, traducida desde la excepción del dominio).

**06 → E2. La edición de documentos que se pisa.**

**Enunciado.** Dos operadores editan a la vez los documentos de Ana; hoy gana el último.

**El primer diseño que sale.** Bloquear la fila de la persona al abrir la ficha.

**El bueno.** Bloqueo optimista sobre la persona, que es la raíz de sus documentos:

- **Entidad**: `@Version` en `Persona`. Como editar un documento cambia el agregado, la versión de la persona protege a todos
  sus documentos (bloqueo de grano grueso).
- **DTO**: la ficha de edición lleva la versión leída; el guardado la devuelve.
- **Servicio**: compara la versión del DTO con la de la persona cargada; si difieren, lanza el conflicto. Si coinciden, aplica
  los cambios y fuerza el incremento de la versión de la persona aunque solo cambie un documento.

```java
@Transactional
public void guardarDocumentos(EdicionDocumentosDto dto) {
    Persona p = em.find(Persona.class, dto.personaId(), LockModeType.OPTIMISTIC_FORCE_INCREMENT);
    if (p.getVersion() != dto.version()) throw new ConflictoDeEdicionException(dto.personaId());
    dto.cambios().forEach(c -> p.aplicar(c));
}
```

- **API**: `409 Conflict` con la versión actual y lo que cambió. **Usuario**: "Los documentos de Ana cambiaron mientras los
  editabas: se añadió un pasaporte", con la opción de recargar o reaplicar.

**Lo que cuesta.** La versión viajando en cada formulario y una pantalla de conflicto. Con conflictos frecuentes, la
experiencia empeora y habría que pensar en un bloqueo de aplicación con caducidad.

**Lo que preguntará después.** Por qué la versión en la persona y no en cada documento (porque las reglas son del conjunto: no
puede haber dos pasaportes del mismo país); y cómo se expresa en HTTP (`ETag` con la versión e `If-Match` en el `PUT`).

**06 → E3. `Dinero` con su reparto.**

**Enunciado.** `Dinero` con moneda, escala, suma segura y `repartir` por proporciones; repartir 1 000,00 COP en 70/30 y 0,05 USD
entre tres.

**El primer diseño que sale.** `monto.multiply(0.7)` y `monto.multiply(0.3)` con `double`, o dividir y redondear cada parte.

**El bueno.** El `Dinero` de `05` §3, con `repartir` en centavos:

```java
Dinero.cop("1000.00").repartir(70, 30);
// 100000 centavos: 70000 y 30000 exactos → 700.00 y 300.00

new Dinero(new BigDecimal("0.05"), Currency.getInstance("USD")).repartir(1, 1, 1);
// 5 centavos: 1, 1, 1 (asignados 3), sobran 2 → 2, 2, 1 → 0.02, 0.02, 0.01; suman 0.05
```

**Lo que cuesta.** Una operación con un bucle que hay que probar con casos de borde (montos pequeños, proporciones que no dividen,
montos negativos). A cambio, ningún reparto pierde ni inventa un centavo.

**Lo que preguntará después.** Quién recibe el centavo extra (una regla del negocio: el primero, el titular principal o el de
mayor proporción, documentada); y qué pasa con montos negativos (un reembolso repartido: hay que repartir el valor absoluto y
aplicar el signo, o el redondeo hacia cero cambia de sentido).

**06 → E4. El saldo bonito.**

**Enunciado.** Mostrar saldos con separador de miles y símbolo según la moneda; un compañero propone jerarquía, fábrica y
Transform View.

**El primer diseño que sale.** El del compañero: `FormateadorDinero`, `FormateadorCop`, `FormateadorUsd` y una fábrica.

**El bueno.** El formateo de la plataforma, con la configuración regional del usuario, en la vista:

```java
String texto(Dinero d, Locale locale) {
    NumberFormat f = NumberFormat.getCurrencyInstance(locale);
    f.setCurrency(d.moneda());
    return f.format(d.monto());
}
```

`NumberFormat` ya sabe los separadores, el símbolo y los decimales de cada moneda en cada región. En el *frontend*, la API de
internacionalización del navegador hace lo mismo.

**Lo que cuesta.** Nada: es una función de tres líneas. El texto exacto del símbolo depende de la región y de los datos de la
plataforma, y conviene probarlo en lugar de suponerlo.

**Lo que preguntará después.** Si el formateo va en el servidor o en el cliente (en un API, se manda el número y la moneda, y
formatea el cliente); y por qué no un método `formatear()` en `Dinero` (porque el formato depende de quién lo mira, no del
dinero).

**06 → E5. La sesión que se pierde.**

**Enunciado.** Cuatro contenedores, un `ConcurrentHashMap` estático con los asistentes en curso, y usuarios cuyo asistente se
reinicia.

**El primer diseño que sale.** Activar afinidad de sesión en el balanceador.

**El bueno.** El diagnóstico: el servicio **sí** tiene estado de sesión, en la memoria de cada contenedor, y peor que una
`HttpSession`: sin caducidad (crece sin límite) y sin réplica. Cuando una petición cae en otro contenedor, o el contenedor se
reinicia en un despliegue, el asistente no está. Las correcciones, de mejor a peor:

1. **Estado en el cliente**: la aplicación guarda el asistente y manda todo al final; el servidor no recuerda nada.
2. **Almacén compartido con caducidad**: los asistentes en Redis, por usuario, con expiración de treinta minutos.
3. **Afinidad**: oculta el problema hasta el próximo despliegue o reubicación, y deja la fuga de memoria.

**Lo que cuesta.** La primera cambia el cliente; la segunda añade una dependencia de infraestructura. Las dos eliminan la fuga.

**Lo que preguntará después.** Cómo lo habrías detectado antes (pruebas con varias instancias y un reinicio en medio del
asistente; y la memoria del servicio creciendo con los usuarios); y qué tiene de malo un mapa estático aunque hubiera un solo
contenedor (es estado global sin caducidad: una fuga y un Singleton escondido).
