# 08 — Respuestas

> Solucionario del bloque `10-concurrencia`: Concurrencia. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para decir en voz
> alta). Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 (2026-10-04).

**Salto rápido:** [01](#01--inmutabilidad-y-confinamiento) · [02](#02--esperar-y-coordinar) · [03](#03--producer-consumer-y-thread-pool) · [04](#04--futurepromise-y-active-object) · [05](#05--reactor-y-proactor) · [06](#06--inicialización-perezosa-segura) · [07](#07--simulación-de-entrevista)

---

# 01 — Inmutabilidad y confinamiento

**01 → 1. ¿Qué es un objeto inmutable, y por qué se puede compartir entre hilos sin sincronizar? 🟢**

⏱️ Un objeto cuyo estado no cambia después de construirse. Si nadie escribe, no hay carrera posible: todos los hilos leen
lo mismo.
🗣️ El cambio construye un objeto nuevo y reemplaza la referencia. Lo único que hay que sincronizar es esa referencia,
para que los lectores vean la nueva: `volatile` en Java, `std::atomic` en C++.
🔬 La condición es que esté bien construido: que `this` no escape durante el constructor y que lo que referencia también
sea inmutable.

**01 → 2. ¿Qué es el confinamiento de un objeto a un hilo, y cuáles son sus tres formas? 🟢**

⏱️ Hacer que un objeto mutable solo lo vea un hilo, para que no necesite sincronización. Por pila, por hilo o por diseño.
🗣️ Por pila: una variable local que no sale del método. Por hilo: un objeto que pertenece a un hilo mientras lo usa, como
la `Connection` que presta el *pool*. Por diseño: un único hilo toca ese estado y los demás le piden cosas.
🔬 *Java Concurrency in Practice* lo trata en 3.3. Es una disciplina, no algo que el compilador compruebe.

**01 → 3. ¿Qué es Thread-Specific Storage? 🟢**

⏱️ Una variable con un valor por hilo: cada hilo ve y cambia su propia copia. En Java, `ThreadLocal`; en C++,
`thread_local`.
🗣️ Sirve para contexto transversal —el usuario de la petición, el identificador de correlación— sin pasarlo como
parámetro por todas las capas. Spring Security guarda así el `SecurityContext` por defecto.
🔬 Es un patrón de POSA2, cap. 5. En Java 25, los Scoped Values cubren el caso más común con menos riesgos.

**01 → 4. ¿Qué garantiza la JLS sobre los campos `final`? 🟢**

⏱️ Que un hilo que obtiene la referencia a un objeto **después** de que terminó su constructor ve los campos `final` bien
inicializados, aunque la referencia le llegue sin sincronizar.
🗣️ La condición es la que la JLS pone en §17.5: no escribir la referencia al objeto en construcción donde otro hilo
pueda verla antes de que el constructor termine.
🔬 La garantía cubre también lo alcanzable desde esos campos tal como estaba al terminar el constructor; no cubre lo que
se modifique después.

**01 → 5. ¿Qué diferencia hay entre un objeto inmutable y uno con todos sus campos `final`? 🟡**

⏱️ `final` impide reasignar el campo, no cambiar el objeto al que apunta. Un `final List<Movimiento>` con un `ArrayList`
dentro se puede modificar, y entonces la clase no es inmutable.
🗣️ Para que sea inmutable, lo referenciado también tiene que serlo, o ser una copia que nadie más tiene: `Map.copyOf`,
`List.copyOf`, o tipos inmutables como `String` y `LocalDate`.
🔬 Ver `01/03` §3. La garantía de §17.5 alcanza la inicialización, no los cambios posteriores del `ArrayList`.

**01 → 6. ¿Qué diferencia hay entre `ThreadLocal` y un Scoped Value de Java 25? 🟡**

⏱️ El `ThreadLocal` se pone y se quita a mano, es mutable y vive mientras viva el hilo; el Scoped Value liga un valor
inmutable durante la ejecución de un bloque y se desliga solo al salir.
🗣️ Con `ScopedValue.where(USUARIO, ana).run(tarea)` no hay `remove()` que olvidar ni valor que cambie a mitad. La JEP 506
los presenta además como más baratos, sobre todo con *virtual threads*.
🔬 Final en Java 25; en Java 21 están en *preview* (JEP 446). En Java 17 no existen: `ThreadLocal` con `try`/`finally`.

**01 → 7. ¿Qué diferencia hay entre publicar un objeto inmutable en Java y en C++? 🟡**

⏱️ Java da una garantía para los campos `final` aunque la publicación no esté sincronizada; C++ no: toda publicación entre
hilos necesita sincronización, y una carrera de datos es comportamiento indefinido.
🗣️ En C++ se publica con `std::atomic<std::shared_ptr<const T>>` (C++20), con un `mutex`, o antes de arrancar el hilo
(el constructor de `std::thread` sincroniza). El `shared_ptr` además decide cuándo se destruye la versión vieja.
🔬 En Java el peor caso sin `volatile` es ver la tabla vieja indefinidamente; en C++, un programa sin significado.

**01 → 8. ¿Qué diferencia hay entre confinar `SimpleDateFormat` y usar `DateTimeFormatter`? 🟡**

⏱️ Confinar `SimpleDateFormat` (una instancia por hilo o por llamada) rodea el problema; `DateTimeFormatter` lo elimina:
su Javadoc lo declara inmutable y seguro entre hilos, y una constante se comparte.
🗣️ La Javadoc de `SimpleDateFormat` recomienda instancias separadas por hilo o sincronización externa. Con
`java.time`, la pregunta desaparece.
🔬 El `ThreadLocal<SimpleDateFormat>` fue el uso de manual de Thread-Specific Storage durante años; hoy es código heredado.

**01 → 9. ¿Por qué la tabla de tarifas se reemplaza entera en lugar de modificarse? 🟠**

⏱️ Porque así ningún lector ve una tabla a medias: la nueva se construye completa y se publica con una sola escritura de
referencia. Modificarla en sitio deja ventanas donde falta una tarifa.
🗣️ Con `clear` y `putAll` sobre un `HashMap` compartido, un lector puede ver la tabla vacía, o una estructura interna
corrupta. Con reemplazo, ve la vieja o la nueva.
🔬 Es la misma idea que `CopyOnWriteArrayList`: pagar una copia por escritura para que las lecturas no paguen nada.

**01 → 10. ¿Para qué hace falta `volatile` si la tabla ya es inmutable? 🟠**

⏱️ Para que los demás hilos vean la referencia nueva. La inmutabilidad garantiza que la tabla no se ve a medias; no
garantiza que se vea la última.
🗣️ Sin `volatile`, un lector puede quedarse con la tabla vieja indefinidamente, porque nada obliga a que la escritura de
la referencia se propague. Con `volatile`, la escritura se ve, junto con todo lo escrito antes.
🔬 Si la actualización lee la tabla actual para construir la nueva, hace falta además atomicidad:
`AtomicReference.updateAndGet`, o dos escritores pisarán sus cambios.

**01 → 11. ¿Por qué un `ThreadLocal` sin `remove()` es una fuga de datos en un *pool*? 🟠**

⏱️ Porque el hilo del *pool* no muere al terminar la petición: la siguiente petición que cae en ese hilo encuentra el valor
de la anterior, por ejemplo el usuario de Ana en la petición de Carmen.
🗣️ Por eso se pone y se quita en el mismo sitio, con `remove()` en un `finally`. Spring Security lo hace en su cadena de
filtros, y su documentación lo dice: es seguro si se limpia al terminar.
🔬 También es una fuga de memoria: en servidores de aplicaciones, un `ThreadLocal` sin limpiar puede retener el
*ClassLoader* de una aplicación replegada.

**01 → 12. ¿Cuándo es mala idea la copia completa en cada cambio? 🟠**

⏱️ Cuando el estado es grande y cambia mucho: copiar un mapa de un millón de entradas por cada escritura cuesta más
memoria y recolección que el candado que se quería evitar.
🗣️ También cuando varios objetos tienen que cambiar juntos: una referencia atómica coordina un objeto, no dos. Ahí hace
falta un candado o una estructura concurrente (`ConcurrentHashMap`).
🔬 La regla práctica: lecturas muchísimo más frecuentes que escrituras y estado pequeño o mediano.

**01 → 13. ¿Por qué un `ThreadLocal` no sirve para pasar datos de negocio? 🟠**

⏱️ Porque esconde una dependencia: el método que lo lee no lo declara en su firma, y deja de funcionar en cuanto el
trabajo pasa a otro hilo.
🗣️ Un `CompletableFuture.supplyAsync` o un `@Async` ejecutan en otro hilo, donde el valor no está. Y en las pruebas hay
que acordarse de ponerlo. Un parámetro lo dice todo.
🔬 El uso legítimo es el contexto que la infraestructura pone y quita: seguridad, correlación, transacción.

**01 → 14. Escribe la tabla de tarifas inmutable con su referencia publicada, en Java y en C++. 🔴**

⏱️ Un objeto inmutable con su mapa copiado, y una referencia `volatile` en Java o `atomic<shared_ptr<const>>` en C++ que
se reemplaza entera.
🗣️

```java
public record TablaTarifas(Map<TipoCuenta, BigDecimal> porcentaje) {
    public TablaTarifas { porcentaje = Map.copyOf(porcentaje); }
    public BigDecimal de(TipoCuenta tipo) { return porcentaje.get(tipo); }
}
public class Tarifas {
    private volatile TablaTarifas actual = new TablaTarifas(Map.of());
    public BigDecimal de(TipoCuenta tipo) { return actual.de(tipo); }
    public void actualizar(Map<TipoCuenta, BigDecimal> nuevas) { actual = new TablaTarifas(nuevas); }
}
```

```cpp
class Tarifas {
    std::atomic<std::shared_ptr<const TablaTarifas>> actual_{std::make_shared<const TablaTarifas>()};
public:
    void actualizar(std::map<TipoCuenta, double> nuevas) {
        actual_.store(std::make_shared<const TablaTarifas>(TablaTarifas{std::move(nuevas)}));
    }
};
```

🔬 Lo que preguntará después: qué pasa con dos actualizadores (`AtomicReference.updateAndGet`); por qué en C++ el lector
copia el `shared_ptr` (para que la tabla no se destruya mientras la usa); y cuándo esto es peor que un candado (estado
grande que cambia mucho).

**01 → 15. Revisa este constructor y di qué falla: `this.tipo = tipo; bus.suscribir(this); this.minimo = minimo;` en una clase con todos sus campos `final`. 🔴**

⏱️ `this` escapa antes de que termine el constructor: el hilo que publica tarifas puede llamar al oyente con `minimo`
todavía en `null`, y la garantía de los campos `final` no aplica porque la referencia se vio antes de tiempo.
🗣️ La corrección es construir primero y suscribir después, desde fuera: `CalculadoraComision c = new
CalculadoraComision(...); bus.suscribir(c);`. Cambiar el orden de las líneas dentro del constructor no basta.
🔬 Lo que preguntará después: dónde más ocurre (arrancar un hilo en el constructor, guardar `this` en un mapa estático,
llamar a un método sobrescribible), y cómo se detecta (cualquier uso de `this` como argumento dentro de un constructor).

**01 → 16. Escribe el contexto de la petición con `ThreadLocal` de forma que no se fugue en un *pool*. 🔴**

⏱️ Poner y quitar en el mismo método, con el `remove()` en un `finally`, y sin exponer un `set` suelto.
🗣️

```java
public final class ContextoPeticion {
    private static final ThreadLocal<PersonaId> USUARIO = new ThreadLocal<>();

    public static void ejecutarComo(PersonaId usuario, Runnable tarea) {
        USUARIO.set(usuario);
        try { tarea.run(); }
        finally { USUARIO.remove(); }
    }
    public static PersonaId usuario() { return USUARIO.get(); }
}
```

🔬 Lo que preguntará después: qué pasa si `tarea` lanza (el `finally` limpia igual); qué pasa si `tarea` lanza trabajo a
otro hilo (el valor no viaja; hay que capturarlo y pasarlo); y cómo sería en Java 25
(`ScopedValue.where(USUARIO, usuario).run(tarea)`, sin `remove()`).

# 02 — Esperar y coordinar

**02 → 1. ¿Qué es un monitor? 🟢**

⏱️ Un objeto cuyos métodos se ejecutan de a uno y que permite a un método esperar una condición soltando el candado, y ser
despertado cuando otro método la cambia.
🗣️ En Java, cada objeto es un monitor: `synchronized` da la exclusión, `wait` la espera y `notifyAll` el aviso. En C++ se
arma con `std::mutex` y `std::condition_variable`. POSA2 lo llama *Monitor Object*.
🔬 El monitor implícito de Java tiene una sola condición por objeto; para varias, `ReentrantLock` con una `Condition` por
clase de espera.

**02 → 2. ¿Qué es un despertar espurio? 🟢**

⏱️ Que un hilo que espera en `wait` se despierte sin que nadie lo haya notificado, interrumpido ni vencido su plazo.
🗣️ La Javadoc de `Object` dice que es raro en la práctica y que las aplicaciones deben protegerse de él comprobando la
condición y volviendo a esperar si no se cumple: el `while`.
🔬 C++ admite lo mismo en `std::condition_variable`; la sobrecarga de `wait` con predicado ya hace el bucle.

**02 → 3. ¿Qué es un read-write lock? 🟢**

⏱️ Un candado con dos modos: lectura, que pueden tener muchos hilos a la vez, y escritura, exclusiva y que excluye también a
los lectores.
🗣️ En Java, `ReentrantReadWriteLock`; en C++, `std::shared_mutex` con `std::shared_lock` para leer y `std::unique_lock`
para escribir.
🔬 `StampedLock` añade lecturas optimistas: se lee sin candado y se valida después que nadie escribió.

**02 → 4. ¿Qué son Guarded Suspension y Balking? 🟢**

⏱️ Dos respuestas a "ahora no se puede": Guarded Suspension espera a que se cumpla la condición; Balking desiste de
inmediato.
🗣️ Retirar de una cuenta bloqueada esperando el desbloqueo es Guarded Suspension; cerrar una cuenta ya cerrada sin hacer
nada es Balking.
🔬 Las dos vienen hechas: `BlockingQueue.take` y `CountDownLatch.await` son esperas con guarda; `compareAndSet` y `tryLock`
son el desistir atómico.

**02 → 5. ¿Qué diferencia hay entre `notify` y `notifyAll`? 🟡**

⏱️ `notify` despierta a uno de los hilos que esperan, elegido de forma arbitraria; `notifyAll` despierta a todos, y cada uno
vuelve a comprobar su condición.
🗣️ Si hay esperas distintas en el mismo monitor, `notify` puede despertar a uno cuya condición no se cumple y dejar dormido
al que sí podía seguir. `notifyAll` es lo correcto por defecto.
🔬 `notify` solo es seguro si todos esperan lo mismo y cualquiera puede avanzar. Con `ReentrantLock`, una `Condition` por
clase de espera permite `signal` sin ese riesgo.

**02 → 6. ¿Qué diferencia hay entre esperar con `Thread.sleep` en un bucle y con `wait`? 🟡**

⏱️ `sleep` en un bucle es espera activa: despierta sin motivo, reacciona tarde y no suelta ningún candado. `wait` duerme
hasta que otro avisa y suelta el candado mientras espera.
🗣️ Además, con `sleep` la comprobación y la acción no son atómicas: otro hilo puede cambiar el estado entre las dos. Con
`wait` dentro del monitor, al despertar se tiene el candado.
🔬 La espera activa solo tiene sentido en esperas de nanosegundos con un núcleo dedicado (`Thread.onSpinWait`), nunca en
lógica de negocio.

**02 → 7. ¿Qué diferencia hay entre el monitor de Java y el de C++? 🟡**

⏱️ En Java, el monitor está en cada objeto y tiene una sola condición; en C++ se arma con un `std::mutex` y una o varias
`std::condition_variable` explícitas.
🗣️ C++ permite una variable de condición por clase de espera desde el principio, como `Condition` en Java. Y el candado lo
suelta el destructor de `std::unique_lock` (Scoped Locking), como en Java lo hace el fin del bloque `synchronized`.
🔬 En C++ se puede notificar sin tener el candado; en Java, `notify` sin el monitor lanza `IllegalMonitorStateException`.

**02 → 8. ¿Qué diferencia hay entre Guarded Suspension y Balking? 🟡**

⏱️ Guarded Suspension espera a que la condición se cumpla; Balking, si no se cumple, se va sin hacer nada.
🗣️ Se elige por el significado: si la operación seguirá teniendo sentido cuando la condición cambie (retirar cuando se
desbloquee), se espera; si ya no lo tendrá (cerrar lo que ya está cerrado), se desiste.
🔬 Una variante intermedia es esperar con plazo: `wait(timeout)`, `tryLock(tiempo, unidad)`, `poll` con tiempo.

**02 → 9. ¿Qué diferencia hay entre un read-write lock y la referencia `volatile` a un objeto inmutable? 🟡**

⏱️ Con el read-write lock, los lectores toman un candado compartido y el escritor modifica en sitio; con la referencia
`volatile`, los lectores no toman nada y el escritor construye un objeto nuevo.
🗣️ El inmutable gana cuando el estado cabe en memoria y se copia barato; el read-write lock, cuando el estado es grande y
copiarlo en cada cambio costaría demasiado.
🔬 El inmutable además no puede producir interbloqueos ni inanición de escritores, que un read-write lock mal configurado sí.

**02 → 10. ¿Por qué `wait` va dentro de un `while`? 🟠**

⏱️ Porque al despertar la condición puede no cumplirse: por un despertar espurio, o porque otro hilo la cambió entre el
aviso y el momento en que este recuperó el candado.
🗣️ El `while` vuelve a preguntar y, si no se cumple, vuelve a esperar. Con `if`, el hilo sigue adelante con una condición
falsa: retira de una cuenta que alguien volvió a bloquear.
🔬 Con `notifyAll`, el `while` es lo que hace que los que no pueden seguir vuelvan a dormir.

**02 → 11. ¿Cuándo un read-write lock es más lento que un candado exclusivo? 🟠**

⏱️ Cuando las lecturas son cortas o las escrituras frecuentes: el candado es más complejo que uno exclusivo y su propio
costo domina, o pasa casi todo el tiempo en modo exclusivo.
🗣️ La Javadoc de `ReadWriteLock` lo dice: depende de la proporción de lecturas, de su duración y de la contención, y solo
medir lo decide.
🔬 Muchas implementaciones serializan a todos los hilos por una pequeña sección para contar lectores, que se vuelve el cuello
de botella con muchos núcleos.

**02 → 12. ¿Por qué cambió el consejo sobre `synchronized` y *virtual threads* entre Java 21 y Java 25? 🟠**

⏱️ En Java 21, un hilo virtual que bloqueaba dentro de `synchronized` quedaba anclado a su hilo de plataforma, y se
aconsejaba `ReentrantLock`. La JEP 491, entregada en Java 24, elimina casi todos esos anclajes.
🗣️ En Java 25, `synchronized` ya no es motivo para reescribir código de *virtual threads*. En Java 21, el consejo sigue para
secciones que bloquean mucho tiempo (E/S dentro del candado).
🔬 La JEP 444 decía que el anclaje no hace incorrecto el programa, pero limita la escalabilidad; JFR emite un evento cuando
un hilo bloquea anclado.

**02 → 13. ¿Por qué en el `CatalogoTipos` de C++ la lectura devuelve una copia? 🟠**

⏱️ Porque una referencia al elemento del mapa seguiría usándose después de soltar el candado de lectura, mientras otro hilo
puede estar escribiendo en el mapa: una carrera de datos.
🗣️ La copia se hace con el candado tomado y lo que sale es del llamador. En Java pasa lo mismo si el valor es mutable; con
`TipoDocumento` inmutable, devolver la referencia es seguro.
🔬 Es la misma regla que en el agregado de `09/01`: lo que sale de la frontera protegida es inmutable o es una copia.

**02 → 14. Escribe en Java un monitor para una cuenta que espera a ser desbloqueada antes de retirar. 🔴**

⏱️ Métodos `synchronized`, `wait` en un `while` sobre el estado, y `notifyAll` al desbloquear.
🗣️

```java
public final class CuentaCompartida {
    private EstadoCuenta estado = EstadoCuenta.ABIERTA;
    private Dinero saldo;

    public synchronized void retirarCuandoSePueda(Dinero monto) throws InterruptedException {
        while (estado == EstadoCuenta.BLOQUEADA) wait();
        Dinero nuevo = saldo.menos(monto);
        if (nuevo.esNegativo()) throw new IllegalStateException("saldo insuficiente");
        saldo = nuevo;
    }
    public synchronized void bloquear()    { estado = EstadoCuenta.BLOQUEADA; }
    public synchronized void desbloquear() { estado = EstadoCuenta.ABIERTA; notifyAll(); }
}
```

🔬 Lo que preguntará después: qué pasa con `InterruptedException` (se propaga, o se restaura el estado de interrupción con
`Thread.currentThread().interrupt()`); cómo se pone un plazo (`wait(timeout)` con el tiempo restante recalculado en el
bucle); y si una cuenta cerrada debería despertar a los que esperan (sí, y que fallen).

**02 → 15. Revisa este código y di qué falla: un monitor con dos clases de espera que usa `notify()` al desbloquear y al depositar. 🔴**

⏱️ `notify` despierta a un hilo arbitrario: al desbloquear puede despertar a la conciliación que espera saldo, que vuelve a
dormir, y el débito que esperaba el desbloqueo no despierta nunca.
🗣️ La corrección mínima es `notifyAll()` en los dos métodos. La mejor, con `ReentrantLock` y dos `Condition`
(`desbloqueada` y `conSaldo`), con `signalAll` en la que corresponde.
🔬 Lo que preguntará después: si `notifyAll` es caro (despierta hilos que vuelven a dormir; rara vez importa frente a un
débito perdido), y cómo se prueba (con dos hilos esperando cosas distintas, el caso que las pruebas de un hilo no cubren).

**02 → 16. Escribe en C++ la misma espera con `std::condition_variable` y di qué hace la sobrecarga con predicado. 🔴**

⏱️ Un `std::mutex`, una `std::condition_variable`, y `wait` con un predicado que dice cuándo se puede seguir.
🗣️

```cpp
void retirarCuandoSePueda(const Dinero& monto) {
    std::unique_lock lock{m_};
    desbloqueada_.wait(lock, [this] { return estado_ != EstadoCuenta::bloqueada; });
    Dinero nuevo = saldo_.menos(monto);
    if (nuevo.esNegativo()) throw std::domain_error{"saldo insuficiente"};
    saldo_ = nuevo;
}
void desbloquear() {
    { std::lock_guard lock{m_}; estado_ = EstadoCuenta::abierta; }
    desbloqueada_.notify_all();
}
```

🔬 La sobrecarga con predicado equivale a `while (!pred()) wait(lock);`: comprueba antes de dormir y vuelve a comprobar al
despertar, así que cubre los despertares espurios. Lo que preguntará después: por qué se notifica fuera del candado (para no
despertar a un hilo que se bloquea enseguida en el `mutex`), y qué pasa si el predicado lee estado sin el candado (carrera:
lo lee con el candado tomado, porque `wait` lo vuelve a tomar).

# 03 — Producer-Consumer y Thread Pool

**03 → 1. ¿Qué es el patrón Producer-Consumer? 🟢**

⏱️ Separar a quien genera trabajo de quien lo procesa con una cola compartida: el productor pone y sigue, el consumidor saca
cuando puede.
🗣️ El API pone solicitudes de transferencia en una `BlockingQueue` y unos hilos las sacan y ejecutan. Cada lado va a su
ritmo, y la cola absorbe la diferencia.
🔬 *Java Concurrency in Practice* lo trata en 5.3 junto con las colas bloqueantes; un pool de hilos es un Producer-Consumer
donde lo que se encola son tareas.

**03 → 2. ¿Qué es la contrapresión? 🟢**

⏱️ La señal que frena al productor cuando el consumidor no da abasto: con una cola acotada llena, el productor espera,
desiste o recibe un rechazo.
🗣️ `offer` con plazo que devuelve `false` y un `503` al cliente; `put` que bloquea; `CallerRunsPolicy` que hace trabajar al
que envía. Sin contrapresión, el exceso se acumula en memoria.
🔬 Los flujos reactivos la hacen explícita: el consumidor pide cuántos elementos puede recibir.

**03 → 3. ¿Qué es un pool de hilos? 🟢**

⏱️ Un número fijo o acotado de hilos que se reutilizan para ejecutar tareas sacadas de una cola, en lugar de crear un hilo
por tarea.
🗣️ En Java, `ExecutorService`: separa qué se ejecuta de cómo (cuántos hilos, qué cola, qué hacer al rechazar).
`ThreadPoolExecutor` permite configurar las tres cosas.
🔬 Evita el costo de crear hilos de plataforma y, sobre todo, pone un límite. En C++ la STL no trae uno.

**03 → 4. ¿Qué es un *virtual thread*? 🟢**

⏱️ Un hilo de Java barato, que la JVM monta sobre unos pocos hilos de plataforma y desmonta cuando bloquea, de modo que se
pueden tener millones.
🗣️ Final en Java 21 (JEP 444). Sirve para el trabajo que pasa casi todo su tiempo esperando E/S: un hilo por tarea, sin pool,
con código bloqueante normal.
🔬 No acelera el cálculo: para trabajo de CPU, siguen mandando los núcleos. Y en Java 21 bloquear dentro de `synchronized`
lo anclaba a su hilo de plataforma; la JEP 491 lo resolvió en Java 24.

**03 → 5. ¿Qué diferencia hay entre una cola acotada y una sin cota? 🟡**

⏱️ La acotada tiene capacidad máxima y, al llenarse, obliga a decidir: esperar, rechazar o frenar. La sin cota acepta todo,
y cuando el consumidor se pone lento crece hasta agotar la memoria.
🗣️ `new ArrayBlockingQueue<>(500)` contra `new LinkedBlockingQueue<>()`. La sin cota parece más tolerante y solo aplaza el
problema a un `OutOfMemoryError`.
🔬 `LinkedBlockingQueue` acepta una capacidad en el constructor; sin ella, su límite es `Integer.MAX_VALUE`.

**03 → 6. ¿Qué diferencia hay entre Producer-Consumer y Observer? 🟡**

⏱️ El Observer llama a los suscriptores en el hilo del que publica y no tiene cola; Producer-Consumer pone una cola y otros
hilos, y absorbe la diferencia de ritmo.
🗣️ Si un suscriptor de Observer es lento, el publicador espera; en Producer-Consumer, el productor sigue hasta que la cola se
llena.
🔬 Se combinan: un Observer cuyo suscriptor encola el evento para procesarlo en otro hilo es un Producer-Consumer detrás de un
Observer.

**03 → 7. ¿Qué diferencia hay entre limitar hilos y limitar el acceso a un recurso? 🟡**

⏱️ Un pool limita cuántos hilos hay; un semáforo o un pool de conexiones limitan cuántas operaciones tocan el recurso escaso.
🗣️ Con hilos de plataforma, limitar hilos limitaba de paso el acceso. Con *virtual threads* ya no: se lanza uno por tarea, y
el límite de diez conexiones se pone con un `Semaphore(10)`.
🔬 La JEP 444 lo dice expresamente: no se ponen hilos virtuales en un pool para limitar la concurrencia; se usan
construcciones hechas para eso, como semáforos.

**03 → 8. ¿Qué diferencia hay entre el pool de Java y el que se escribe en C++? 🟡**

⏱️ Java lo trae hecho y configurable (`ThreadPoolExecutor`, con cola y política de rechazo); en C++23 la STL no trae pool ni
cola bloqueante, y se escriben con `mutex`, `condition_variable` y `std::jthread`, o se toma de una librería.
🗣️ El de C++ del capítulo para con una tarea vacía por hilo, y `std::jthread` se une solo al destruirse, así que el pool no
deja hilos vivos.
🔬 El orden de los miembros importa en C++: los hilos se destruyen antes que la cola porque se declaran después.

**03 → 9. ¿Cómo se dimensiona un pool para trabajo de CPU y para trabajo de E/S? 🟠**

⏱️ CPU: tantos hilos como núcleos, más uno. E/S: más, en proporción al tiempo de espera frente al de cálculo, y nunca más que
el recurso compartido.
🗣️ La regla de *Java Concurrency in Practice* (8.2): núcleos × uso de CPU × (1 + espera / cálculo). Ocho núcleos y tareas que
esperan 190 ms y calculan 10 ms dan 160; si hay diez conexiones, 150 de esos hilos esperarán una.
🔬 La fórmula es un punto de partida; se ajusta midiendo. Y con *virtual threads* en Java 21, para E/S la pregunta deja de ser
cuántos hilos y pasa a ser cuántas conexiones.

**03 → 10. ¿Por qué los *virtual threads* no se ponen en un pool? 🟠**

⏱️ Porque son baratos: el pool existía para no pagar la creación de hilos caros y para limitarlos. La JEP 444 dice que nunca
se ponen en un pool: uno nuevo por tarea.
🗣️ Un pool de hilos virtuales reintroduce el límite de hilos que no se quería, y además reutiliza hilos con sus `ThreadLocal`.
Para limitar, un semáforo.
🔬 `Executors.newVirtualThreadPerTaskExecutor()` es el ejecutor correcto: crea un hilo por tarea y su `close()` espera a que
terminen todas.

**03 → 11. ¿Qué hace `CallerRunsPolicy` y por qué frena al productor? 🟠**

⏱️ Cuando la cola está llena, ejecuta la tarea rechazada en el hilo que llamó a `execute`: ese hilo, mientras la ejecuta, no
envía más.
🗣️ La Javadoc lo describe como un mecanismo simple de control que reduce el ritmo de envío. No se pierde ninguna tarea, y el
productor se frena solo.
🔬 El riesgo: si el productor es el hilo del servidor HTTP, ejecuta la transferencia él mismo y deja de aceptar peticiones;
a veces es lo que se quiere, y a veces un `503` es más claro.

**03 → 12. ¿Por qué "con *virtual threads* ya no hace falta pensar en concurrencia" es falso? 🟠**

⏱️ Porque cambian cuántos hilos se pueden tener, no los problemas: el estado compartido sigue necesitando sincronización,
los recursos siguen siendo escasos y la cola de entrada sigue necesitando contrapresión.
🗣️ Un millón de hilos virtuales contra diez conexiones son 999 990 esperando; un `HashMap` compartido sigue rompiéndose. Lo
que desaparece es dimensionar pools para E/S.
🔬 Y aparecen problemas nuevos: `ThreadLocal` caros con millones de hilos (de ahí los Scoped Values), y en Java 21 el anclaje
dentro de `synchronized`.

**03 → 13. ¿Por qué en la cola acotada de C++ `notify_one` es correcto? 🟠**

⏱️ Porque hay una variable de condición por clase de espera, y en cada una todos esperan lo mismo y cualquiera puede avanzar:
un hueco libre sirve a cualquier productor.
🗣️ Es la excepción de `02` §3: `notify` falla cuando en la misma condición esperan cosas distintas. Con `noLlena_` y
`noVacia_` separadas, no pasa.
🔬 Se notifica después de soltar el candado para que el hilo despertado no se bloquee de inmediato en el `mutex`.

**03 → 14. Escribe en Java la cola de transferencias con contrapresión que responda `503` cuando se llena. 🔴**

⏱️ Una `ArrayBlockingQueue` acotada, `offer` con plazo en el API y `take` en los consumidores.
🗣️

```java
private final BlockingQueue<SolicitudTransferencia> cola = new ArrayBlockingQueue<>(500);

@PostMapping("/transferencias")
public ResponseEntity<Void> solicitar(@RequestBody SolicitudTransferencia s) throws InterruptedException {
    boolean aceptada = cola.offer(s, 2, TimeUnit.SECONDS);
    return aceptada ? ResponseEntity.accepted().build() : ResponseEntity.status(503).build();
}

void consumir() throws InterruptedException {                 // en cada hilo consumidor
    while (!Thread.currentThread().isInterrupted()) transferir.ejecutar(cola.take());
}
```

🔬 Lo que preguntará después: qué pasa con las solicitudes encoladas si el proceso se cae (se pierden: la cola está en
memoria; si no se pueden perder, se guardan antes de aceptar), cómo se para a los consumidores (interrupción o una píldora),
y qué cabecera acompaña al `503` (`Retry-After`).

**03 → 15. Revisa este código y di qué falla: `Executors.newFixedThreadPool(10)` para llamar a un sistema de pagos que a veces tarda veinte segundos. 🔴**

⏱️ Su cola no tiene cota: cuando el sistema de pagos se pone lento, los diez hilos esperan y las tareas se acumulan sin
límite hasta agotar la memoria y tumbar todo el servicio.
🗣️ La corrección es un `ThreadPoolExecutor` con `ArrayBlockingQueue` acotada y una política de rechazo explícita
(`CallerRunsPolicy` o un rechazo que acabe en `503`), y un plazo en la llamada al sistema de pagos.
🔬 Lo que preguntará después: cómo lo detectas antes de que caiga (el tamaño de la cola como métrica, con alerta), y qué más
falta (un plazo y un cortocircuito ante el sistema de pagos, para no esperar veinte segundos por llamada).

**03 → 16. Escribe en Java 21 la ejecución de las transferencias con un hilo virtual por tarea, limitada a diez conexiones. 🔴**

⏱️ Un `newVirtualThreadPerTaskExecutor` y un `Semaphore(10)` alrededor del uso de la conexión.
🗣️

```java
try (ExecutorService porTarea = Executors.newVirtualThreadPerTaskExecutor()) {
    Semaphore conexiones = new Semaphore(10);
    for (SolicitudTransferencia s : solicitudes) {
        porTarea.submit(() -> {
            conexiones.acquire();
            try { return transferir.ejecutar(s); } finally { conexiones.release(); }
        });
    }
}
```

🔬 Lo que preguntará después: por qué no un pool de diez hilos virtuales (la JEP lo desaconseja: el límite es del recurso, no
de los hilos), qué hace el `close()` del `try` (espera a que terminen todas), y si el pool de conexiones ya no limita solo
(sí, y entonces el semáforo sobra o se usa para fallar rápido en lugar de esperar una conexión).

# 04 — Future/Promise y Active Object

**04 → 1. ¿Qué es un Future, y qué es una Promise? 🟢**

⏱️ Las dos caras de un resultado que todavía no existe: la Promise es el lado que escribe —quien hace el trabajo deposita
el valor o el error una vez— y el Future el que lee —quien lo pidió consulta, espera o encadena—.
🗣️ En Java, `CompletableFuture` es las dos cosas a la vez (`complete` escribe, `thenApply` y `get` leen). En C++ están
separadas: `std::promise` y el `std::future` que se obtiene de ella.
🔬 El nombre varía por lenguaje: en JavaScript, lo que Java llama futuro se llama `Promise`.

**04 → 2. ¿Qué es un Active Object? 🟢**

⏱️ Un objeto con su propio hilo: sus métodos encolan la llamada como un mensaje y devuelven un futuro, y su hilo ejecuta los
mensajes de a uno.
🗣️ El registro de auditoría con un ejecutor de un solo hilo: los llamadores no esperan la escritura, y el archivo nunca lo
tocan dos hilos. POSA2 lo describe como desacoplar la ejecución de un método de su invocación.
🔬 Es un Producer-Consumer con un solo consumidor y un futuro por mensaje; los actores son esta idea generalizada.

**04 → 3. ¿Qué hace `thenCombine`? 🟢**

⏱️ Combina dos futuros que no dependen uno del otro: cuando los dos terminan, aplica una función a sus dos resultados y devuelve un futuro
con lo que salga.
🗣️ `fv.thenCombine(fs, Parcial::new)` espera la verificación y la consulta de sanciones, que corren en paralelo, sin
bloquear a nadie.
🔬 Para más de dos, `allOf` devuelve un futuro que termina cuando terminan todos; los resultados se leen después con `join`
de cada uno, que ya no bloquea.

**04 → 4. ¿Qué diferencia hay entre un futuro y un *callback*? 🟡**

⏱️ El *callback* es una función que se llama al terminar; el futuro es un **valor** que representa el resultado y se puede
pasar, combinar y esperar.
🗣️ Con *callbacks*, combinar tres resultados obliga a anidarlos o a llevar la cuenta a mano; con futuros, `thenCombine` y
`allOf`. Y el error tiene su canal propio en lugar de un segundo *callback*.
🔬 Por dentro, un futuro guarda *callbacks*: `thenApply` registra uno. Lo que añade es la composición y el estado.

**04 → 5. ¿Qué diferencia hay entre `CompletableFuture` y `std::future`? 🟡**

⏱️ `CompletableFuture` se encadena y se combina sin bloquear (`thenApply`, `thenCombine`, `exceptionally`, plazos);
`std::future` de C++23 solo se espera con `get()`.
🗣️ En C++ la promesa y el futuro son objetos separados, y el futuro de `std::async` bloquea en su destructor si nadie lo
guarda. Para componer sin bloquear hace falta una librería o las corrutinas.
🔬 El `get()` de C++ relanza la excepción que la tarea depositó; el de Java la envuelve en `ExecutionException`.

**04 → 6. ¿Qué diferencia hay entre un Active Object y un objeto con métodos `synchronized`? 🟡**

⏱️ El `synchronized` hace que cada llamador ejecute el método en su propio hilo, esperando su turno; el Active Object
ejecuta todo en su hilo, y el llamador sigue enseguida con un futuro.
🗣️ Con `synchronized`, una escritura lenta en el archivo frena a todos los llamadores; con el Active Object, la frena solo a
su cola.
🔬 El estado del Active Object no necesita candados: está confinado a su hilo. A cambio, hay un hilo y una cola que gestionar.

**04 → 7. ¿Qué diferencia hay entre `thenApply` y `thenCompose`? 🟡**

⏱️ `thenApply` transforma el valor cuando llega; `thenCompose` encadena otra operación que también devuelve un futuro, y
aplana el resultado.
🗣️ `fv.thenApply(v -> v.aprobada())` da un `CompletableFuture<Boolean>`; `fv.thenCompose(v -> riesgos.puntajeAsync(v))` da un
`CompletableFuture<Integer>`. Con `thenApply` en el segundo caso, saldría un futuro de un futuro.
🔬 Es la diferencia entre `map` y `flatMap` de `Optional` y de los *streams*.

**04 → 8. ¿Por qué `future.get()` no es asíncrono? 🟠**

⏱️ Porque bloquea: la Javadoc de `Future` dice que espera si hace falta a que el cálculo termine. Es exactamente el punto
donde se deja de ser asíncrono.
🗣️ Crear un futuro y llamar a `get()` en la línea siguiente es una llamada síncrona con un hilo de más. La composición
(`thenApply`, `thenCombine`) es lo asíncrono; `get()` va solo en el borde, donde de verdad hay que esperar.
🔬 `join()` hace lo mismo con excepciones no comprobadas. Y `get(tiempo, unidad)` al menos pone un límite.

**04 → 9. ¿Por qué hay que pasar un ejecutor a `supplyAsync` cuando la tarea llama a un servicio remoto? 🟠**

⏱️ Porque sin ejecutor usa el `ForkJoinPool` común, dimensionado para cálculo; las llamadas que esperan E/S lo ocupan y frenan
todo lo que lo comparte, como los *streams* paralelos.
🗣️ Un ejecutor propio, dimensionado para E/S y con cola acotada, aísla esas esperas. En Java 21, un ejecutor de hilos
virtuales por tarea es una buena opción.
🔬 Es la regla de `03`: el pool se dimensiona por el tipo de trabajo, y mezclar CPU con E/S en el mismo pool hace que uno
frene al otro.

**04 → 10. ¿Por qué una línea suelta con `std::async` puede ser síncrona? 🟠**

⏱️ Porque el `std::future` que devuelve, si no se guarda, se destruye al final de la expresión, y ese destructor bloquea
hasta que la tarea termine.
🗣️ `std::async(std::launch::async, enviarAviso);` espera a que se envíe el aviso antes de seguir. Hay que guardar el futuro
en una variable que viva lo necesario.
🔬 Además, sin `std::launch::async` la implementación puede diferir la tarea hasta que alguien llame a `get()`, y si nadie lo
llama, no se ejecuta.

**04 → 11. ¿Cuándo un *virtual thread* con código secuencial reemplaza a la composición de futuros? 🟠**

⏱️ En Java 21, cuando el trabajo es E/S: cada tarea se escribe secuencial y bloqueante dentro de su hilo virtual, sin cadenas
de `thenApply`, porque bloquear ya no cuesta un hilo de plataforma.
🗣️ El paralelismo de las tres consultas sigue necesitando tres tareas; lo que cambia es que cada una se lee de arriba abajo,
con `try`/`catch` normales y pilas de llamadas legibles.
🔬 La concurrencia estructurada (en *preview* en Java 25, JEP 505) es la forma de lanzar y esperar varias subtareas en un
bloque con ámbito; en Java 21 se hace con un ejecutor por tarea.

**04 → 12. Escribe en Java las tres consultas del alta en paralelo, con plazo y un camino de error. 🔴**

⏱️ Tres `supplyAsync` con ejecutor, combinadas con `thenCombine`, con `orTimeout` y `exceptionally`.
🗣️

```java
var fv = CompletableFuture.supplyAsync(() -> verificador.verificar(pasaporte), ejecutor);
var fs = CompletableFuture.supplyAsync(() -> sanciones.consultar(carmen.nombre()), ejecutor);
var fr = CompletableFuture.supplyAsync(() -> riesgos.puntaje(carmen.id()), ejecutor)
        .completeOnTimeout(RIESGO_POR_DEFECTO, 500, TimeUnit.MILLISECONDS);

CompletableFuture<Decision> decision = fv.thenCombine(fs, Parcial::new)
        .thenCombine(fr, (p, riesgo) -> decidir(p.verificacion(), p.sancionada(), riesgo))
        .orTimeout(2, TimeUnit.SECONDS)
        .exceptionally(Decision::revisionManual);
```

🔬 Lo que preguntará después: qué pasa con las tareas que siguen corriendo cuando vence el plazo (siguen: `orTimeout` completa
el futuro, no interrumpe el trabajo); por qué el riesgo tiene valor por defecto y la verificación no (el negocio decide qué
puede faltar); y dónde se espera (en el borde: el controlador devuelve el futuro o hace `join`).

**04 → 13. Escribe un Active Object para el registro de auditoría y di qué cambiarías para producción. 🔴**

⏱️ Un ejecutor de un solo hilo, un `registrar` que encola y devuelve un futuro, y el archivo confinado a ese hilo.
🗣️

```java
public final class AuditoriaActiva implements AutoCloseable {
    private final ExecutorService hilo = Executors.newSingleThreadExecutor();
    private final BufferedWriter archivo;

    public AuditoriaActiva(BufferedWriter archivo) { this.archivo = archivo; }

    public CompletableFuture<Void> registrar(String evento) {
        return CompletableFuture.runAsync(() -> escribir(evento), hilo);
    }
    private void escribir(String evento) {
        try { archivo.write(evento); archivo.newLine(); archivo.flush(); }
        catch (IOException e) { throw new UncheckedIOException(e); }
    }
    @Override public void close() throws IOException { hilo.shutdown(); archivo.close(); }
}
```

🔬 Para producción: una cola acotada (`newSingleThreadExecutor` no la tiene) con política de rechazo; esperar con
`awaitTermination` en `close` antes de cerrar el archivo, para no perder lo encolado; y decidir qué pasa si la escritura
falla (el futuro termina con la excepción: alguien tiene que mirarlo).

**04 → 14. Revisa este código y di qué falla: `CompletableFuture.supplyAsync(() -> sanciones.consultar(nombre)).get()` dentro de un bucle sobre mil personas. 🔴**

⏱️ Es síncrono con más piezas: cada `get()` espera antes de lanzar la siguiente, así que las mil consultas van en fila, y
además ocupan el `ForkJoinPool` común con esperas de E/S.
🗣️ La corrección: lanzar todas primero con un ejecutor para E/S (o hilos virtuales en Java 21), guardar los futuros, y
esperar al final con `allOf(...).join()`; con un límite de concurrencia si el servicio de sanciones no aguanta mil a la vez.
🔬 Lo que preguntará después: cómo se limita (un semáforo o un ejecutor acotado), qué pasa si una falla (`allOf` termina con
error; se decide si se reintenta o se marca para revisión), y si el servicio acepta consultas en lote (entonces, una
llamada).

# 05 — Reactor y Proactor

**05 → 1. ¿Qué es un *event loop*? 🟢**

⏱️ Un hilo que espera a que pase algo en cualquiera de muchas fuentes —conexiones, temporizadores— y, cuando pasa, ejecuta el
manejador correspondiente y vuelve a esperar.
🗣️ Es lo que permite atender miles de conexiones con un hilo: el hilo no espera en una conexión, espera en todas a la vez y
atiende las que tienen algo. Node, Netty y WebFlux funcionan así.
🔬 Su regla es que cada manejador vuelva enseguida: mientras uno corre, el bucle no atiende a nadie más.

**05 → 2. ¿Qué es el patrón Reactor? 🟢**

⏱️ Un bucle que pregunta a un demultiplexor del sistema qué canales están listos para leer o escribir y despacha cada uno a su
manejador, que hace la operación, ya sin bloquear.
🗣️ En Java, el `Selector` de NIO con canales no bloqueantes; en Linux, `epoll`. El manejador lee, procesa poco y vuelve; lo
lento sale a un pool.
🔬 Es de POSA2, cap. 3, "Event Handling Patterns". Netty usa varios Reactores, uno por núcleo.

**05 → 3. ¿Qué es el patrón Proactor? 🟢**

⏱️ La aplicación inicia una operación de E/S y sigue; el sistema la completa por su cuenta y avisa cuando ya terminó, con los
datos ya en el búfer. Un manejador de completado procesa el resultado.
🗣️ En Java, `AsynchronousSocketChannel.read` con un `CompletionHandler`; de forma nativa, los *I/O Completion Ports* de
Windows e `io_uring` en Linux.
🔬 También de POSA2, cap. 3. El búfer pertenece al sistema hasta que la operación termina.

**05 → 4. ¿Qué hace un demultiplexor como `epoll` o el `Selector` de NIO? 🟢**

⏱️ Vigila muchos descriptores a la vez y devuelve los que están listos para leer o escribir sin bloquear, durmiendo mientras
no hay ninguno.
🗣️ `selector.select()` o `epoll_wait` son el único punto donde el bucle espera. Después, cada lectura sobre un canal listo
devuelve enseguida.
🔬 `epoll` escala mejor que `select`, que recorre todos los descriptores en cada llamada; por eso los servidores de Linux lo
usan.

**05 → 5. ¿Qué diferencia hay entre Reactor y Proactor? 🟡**

⏱️ El Reactor avisa de que **se puede** leer y la lectura la hace el manejador; el Proactor avisa de que **ya se leyó**, y el
manejador solo procesa.
🗣️ En el Reactor, la copia de los datos ocurre en el hilo del bucle; en el Proactor, la hace el sistema. A cambio, el
Proactor necesita soporte nativo y un código de completado más difícil de seguir.
🔬 Una interfaz Proactor se puede emular sobre un Reactor (un hilo que espera disponibilidad, lee y luego llama al manejador);
la ventaja de rendimiento solo existe con soporte del sistema.

**05 → 6. ¿Qué diferencia hay entre un hilo por conexión y un bucle de eventos? 🟡**

⏱️ Con un hilo por conexión, cada hilo pasa casi todo su tiempo bloqueado en su `read`; con un bucle, un hilo espera en todas
las conexiones y atiende las que tienen datos.
🗣️ Diez mil conexiones son diez mil pilas de hilos de plataforma contra un hilo y diez mil búferes. El precio del bucle: el
código se parte en manejadores, y nada puede bloquear.
🔬 Con *virtual threads*, el hilo por conexión vuelve a ser barato, y la comparación cambia.

**05 → 7. ¿Qué diferencia hay entre el Reactor de Java (NIO) y el de C++ sobre `epoll`? 🟡**

⏱️ Java da el demultiplexor con una interfaz portable, el `Selector`, que en cada sistema usa lo que haya debajo; C++23 no
trae red en la biblioteca estándar, y se escribe sobre la API de C del sistema (`epoll`, `kqueue`) o con una librería.
🗣️ El patrón es el mismo: registrar descriptores, esperar con `epoll_wait` o `select()`, despachar. En C++ hay que gestionar
a mano descriptores y errores de bajo nivel.
🔬 En C++, las librerías de red más usadas ofrecen las dos formas, Reactor y Proactor, sobre los mecanismos de cada sistema.

**05 → 8. ¿Qué diferencia hay entre un bucle de eventos y los *virtual threads* para atender muchas conexiones? 🟡**

⏱️ Los dos evitan un hilo de plataforma bloqueado por conexión. Con el bucle, el código se parte en manejadores que no pueden
bloquear; con *virtual threads*, se escribe secuencial y bloqueante, y la JVM desmonta el hilo cuando espera.
🗣️ Para petición y respuesta en Java 21, los *virtual threads* dan casi la misma escalabilidad con código mucho más legible.
El bucle sigue teniendo sentido para conexiones largas, *streaming* o cuando el marco ya es reactivo.
🔬 Por dentro, la JVM usa un demultiplexor para despertar a los hilos virtuales que esperan red: el Reactor sigue ahí, pero
escondido.

**05 → 9. ¿Por qué bloquear el bucle lo detiene todo? 🟠**

⏱️ Porque el bucle es un solo hilo para muchas conexiones: mientras un manejador bloquea, el bucle no atiende a ninguna otra.
🗣️ Una consulta JDBC de 50 ms en un manejador de Netty, con cien consultas a la vez, deja a la última esperando cinco
segundos, y a todas las demás conexiones de ese bucle sin atención. Lo lento va a un ejecutor aparte.
🔬 Aplica al trabajo de CPU igual que a la E/S. La documentación de Node lo convierte en regla: no bloquear el *event loop*.

**05 → 10. ¿Por qué "Node es multihilo para el código del usuario" es falso? 🟠**

⏱️ Porque el JavaScript del usuario corre en un solo hilo, el del *event loop*. Lo que tiene varios hilos es la librería: un
pool de trabajadores para ciertas operaciones.
🗣️ La documentación de Node lo dice: un *event loop* y un pool de *k* trabajadores. Un cálculo largo en un manejador congela el
servidor, porque no hay otro hilo que ejecute JavaScript.
🔬 Los `worker_threads` existen, pero se crean de forma explícita y no comparten memoria normal con el hilo principal; no
cambian el modelo por defecto.

**05 → 11. ¿Cuándo prefieres *virtual threads* a un servidor reactivo en Java 21? 🟠**

⏱️ Cuando el servicio es de petición y respuesta, con llamadas que esperan E/S: código secuencial, depuración normal y casi
la misma escalabilidad.
🗣️ El reactivo sigue teniendo sentido para conexiones largas, flujos de datos con contrapresión, o si el equipo y el marco ya
son reactivos. Mezclar los dos sin criterio tiene lo peor de cada uno.
🔬 Lo que no cambia: el recurso escaso (conexiones a la base) sigue mandando, y JDBC dentro de un bucle reactivo sigue siendo
un error.

**05 → 12. ¿Qué cuesta el Reactor en legibilidad y depuración? 🟠**

⏱️ El código se parte en manejadores y *callbacks*, el estado de cada conexión vive en adjuntos en lugar de en variables
locales, y las pilas de llamadas empiezan siempre en el bucle, no en quien originó la petición.
🗣️ Un error en un manejador no dice qué petición lo causó, y un `try`/`catch` no abarca una operación que continúa en otro
*callback*. Hay que propagar el contexto a mano.
🔬 Por eso el precio del Reactor se paga en cada línea, y solo compensa con muchas conexiones de poca actividad.

**05 → 13. Revisa este manejador de Netty y di qué falla: consulta el saldo con `jdbcTemplate.queryForObject` y escribe la respuesta. 🔴**

⏱️ JDBC bloquea, y el manejador corre en el hilo del bucle: mientras espera a la base, todas las demás conexiones de ese bucle
quedan sin atender.
🗣️ La corrección es mandar la consulta a un ejecutor para trabajo bloqueante y escribir la respuesta cuando termine:

```java
CompletableFuture.supplyAsync(() -> consultarSaldo(cuentaDe(msg)), ejecutorBloqueante)
        .thenAccept(saldo -> ctx.writeAndFlush(respuesta(saldo)));
```

🔬 Lo que preguntará después: cómo se dimensiona `ejecutorBloqueante` (por las conexiones a la base), qué pasa si la consulta
falla (un `exceptionally` que responda con error), y si no sería mejor un servidor con *virtual threads* (si el servicio es de
petición y respuesta, probablemente sí).

**05 → 14. Escribe el bucle de un Reactor con el `Selector` de Java que acepte conexiones y despache las lecturas. 🔴**

⏱️ Un `Selector`, un `ServerSocketChannel` no bloqueante registrado para aceptar, y un bucle que acepta y registra para leer, o
lee y despacha.
🗣️

```java
Selector selector = Selector.open();
ServerSocketChannel servidor = ServerSocketChannel.open();
servidor.bind(new InetSocketAddress(9000));
servidor.configureBlocking(false);
servidor.register(selector, SelectionKey.OP_ACCEPT);
while (true) {
    selector.select();
    Iterator<SelectionKey> listos = selector.selectedKeys().iterator();
    while (listos.hasNext()) {
        SelectionKey k = listos.next();
        listos.remove();
        if (k.isAcceptable()) {
            SocketChannel c = servidor.accept();
            c.configureBlocking(false);
            c.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(1024));
        } else if (k.isReadable()) {
            SocketChannel c = (SocketChannel) k.channel();
            if (c.read((ByteBuffer) k.attachment()) < 0) { k.cancel(); c.close(); continue; }
            consultas.alRecibir(c, (ByteBuffer) k.attachment());
        }
    }
}
```

🔬 Lo que preguntará después: por qué el `remove()` del iterador (el `Selector` no limpia el conjunto de listos: sin él,
la clave de aceptar vuelve en la vuelta siguiente, `accept()` devuelve `null` y el bucle cae con `NullPointerException`,
comprobado), qué pasa con mensajes que llegan partidos en varias lecturas (el búfer acumula hasta tener uno completo), y
cómo se escribe la respuesta sin bloquear (registrar `OP_WRITE` cuando el búfer de salida no cabe de una vez).

# 06 — Inicialización perezosa segura

**06 → 1. ¿Qué es el *double-checked locking*? 🟢**

⏱️ Una inicialización perezosa en tres pasos: comprobar sin candado; si falta, tomar el candado y volver a comprobar; si sigue
faltando, inicializar. Así solo la primera vez se paga el candado.
🗣️ En Java es correcto solo con el campo `volatile`, y se escribe leyendo el campo en una variable local. Es la forma
estándar para campos de instancia perezosos.
🔬 POSA2 lo recoge como *Double-Checked Locking Optimization* en sus patrones de sincronización.

**06 → 2. ¿Qué es el holder idiom? 🟢**

⏱️ Un estático perezoso que vive en una clase anidada: la JVM solo inicializa esa clase la primera vez que se usa, y esa
inicialización ya está sincronizada.
🗣️ `Portador.INSTANCIA` se crea en la primera llamada a `instancia()`; los demás hilos esperan a que termine y después nadie
paga nada. No hay `volatile` ni `synchronized` a la vista.
🔬 Funciona por la JLS §12.4.2, el procedimiento de inicialización de clases. Ver `04/05` §5.

**06 → 3. ¿Qué garantiza `volatile` en Java? 🟢**

⏱️ Visibilidad y orden: una escritura en un campo `volatile` ocurre antes que toda lectura posterior de ese campo, y quien lee
ve también lo que se escribió antes de esa escritura.
🗣️ Es lo que necesita el DCL: quien ve la referencia ve el objeto construido. Y es lo que sirve para una bandera de parada que
otro hilo tiene que ver.
🔬 No da atomicidad de operaciones compuestas: `volatile` no hace atómico un `++`.

**06 → 4. ¿Qué diferencia hay entre el DCL y el holder idiom? 🟡**

⏱️ El holder sirve solo para estáticos y no necesita nada visible: la JVM sincroniza la inicialización de la clase. El DCL
sirve para campos de instancia y necesita `volatile`.
🗣️ El holder no se puede escribir mal; el DCL sí, y se escribía mal durante años. Para estáticos, el holder siempre.
🔬 Difieren también ante fallos: si el holder lanza al inicializar, la clase queda en error y cada uso lanza
`NoClassDefFoundError`; un DCL que lanza deja el campo en `null` y la siguiente llamada lo reintenta.

**06 → 5. ¿Qué diferencia hay entre `volatile` y `AtomicLong`? 🟡**

⏱️ `volatile` hace visible cada escritura; `AtomicLong` además hace atómicas las operaciones de leer y modificar, como
`incrementAndGet` o `compareAndSet`.
🗣️ Para publicar una referencia o una bandera, `volatile`. Para un contador que varios hilos incrementan, `AtomicLong`, o
`LongAdder` si se incrementa mucho y se lee poco.
🔬 `AtomicLong` guarda su valor en un campo `volatile` y usa instrucciones atómicas del procesador para modificarlo.

**06 → 6. ¿Qué diferencia hay entre la inicialización perezosa en Java y en C++? 🟡**

⏱️ En C++, una estática local se inicializa una sola vez entre hilos desde C++11, y `std::call_once` lo da para cualquier
función. En Java, holder para estáticos y DCL con `volatile` para instancias.
🗣️ En C++ hay que decidir además quién posee el objeto (la estática local, un `std::optional` miembro) y cuándo se destruye.
El DCL a mano con atómicos existe en C++, pero no hace falta escribirlo.
🔬 Java 25 añade `StableValue` en *preview*, que se parece a `call_once` para campos de instancia.

**06 → 7. ¿Qué diferencia hay entre el holder y `std::call_once` cuando la inicialización lanza? 🟡**

⏱️ Con el holder, la clase queda marcada como fallida y cada uso posterior lanza `NoClassDefFoundError`: no hay reintento. Con
`call_once`, la bandera no se marca y la siguiente llamada lo reintenta.
🗣️ Si la carga puede fallar por algo transitorio (la base no responde al arrancar), el holder lo convierte en un error
permanente hasta reiniciar el proceso. Ahí conviene un DCL o `call_once`.
🔬 La estática local de C++ también se reintenta si su inicializador lanza.

**06 → 8. ¿Por qué el DCL sin `volatile` está roto? 🟠**

⏱️ Porque el hilo que entra por el camino rápido no tiene relación de *ocurre antes* con el que inicializó: puede ver la
referencia escrita antes que los campos que escribió el constructor, y usar un objeto a medio construir.
🗣️ Reservar, construir y publicar se pueden reordenar mientras el hilo que lo hace no note la diferencia. `volatile` prohíbe
ese reordenamiento respecto de la publicación y da la visibilidad.
🔬 La declaración *"Double-Checked Locking is Broken"* lo documentó para el modelo de memoria anterior a Java 5, y explica que
desde JDK 5 `volatile` lo arregla.

**06 → 9. ¿Por qué "el DCL es un antipatrón y punto" es una respuesta incompleta? 🟠**

⏱️ Porque lo roto es el DCL **sin `volatile`**. Con `volatile`, desde Java 5, es correcto, y Bloch lo recomienda para campos
de instancia perezosos.
🗣️ La respuesta completa: para estáticos, holder; para instancias, DCL con `volatile` y variable local, solo si la
inicialización es cara; y en C++, `call_once`.
🔬 Lo que sí es cierto: casi nunca hace falta escribirlo, porque un `Supplier` memoizado o `StableValue` lo encapsulan.

**06 → 10. ¿Por qué en el DCL se lee el campo en una variable local? 🟠**

⏱️ Para hacer una sola lectura `volatile` en el camino rápido, que es el que se ejecuta casi siempre: comprobar y devolver la
misma variable local.
🗣️ Sin la variable local, el camino rápido lee el campo dos veces (al comprobar y al devolver). Es la forma que da Bloch en el
ítem 83.
🔬 Es una optimización menor; lo que no se puede quitar es el `volatile`.

**06 → 11. ¿Cuándo no vale la pena la inicialización perezosa? 🟠**

⏱️ Casi siempre: cuando el objeto no es caro, o cuando casi todas las ejecuciones lo usan. Bloch dice que en la mayoría de los
casos la inicialización normal es preferible.
🗣️ La perezosa mueve el costo del arranque a la primera petición, que es la que ve el usuario, y los errores de carga a mitad
del trabajo. Y cada acceso paga una comprobación.
🔬 Vale la pena cuando el objeto es caro **y** muchas ejecuciones no lo necesitan, o cuando inicializarlo antes crearía un
ciclo de dependencias.

**06 → 12. ¿Qué cambia `StableValue` de Java 25 en este capítulo? 🟠**

⏱️ Da la inicialización perezosa, segura entre hilos, para estáticos y para campos de instancia, sin escribir el DCL ni la
clase anidada: `StableValue.supplier(() -> ...)` y `get()`.
🗣️ Es una API en *preview* en Java 25 (JEP 502), y en JDK 26 se rediseñó como `LazyConstant` (JEP 526). Hasta que sea final,
en Java 17 y 21 se sigue usando holder y DCL.
🔬 Su ventaja adicional es que la JVM puede tratar el valor ya inicializado como una constante y optimizar como con un `final`.

**06 → 13. Escribe en Java un DCL correcto para un campo de instancia. 🔴**

⏱️ Campo `volatile`, lectura en una variable local, comprobación sin candado, segunda comprobación dentro del `synchronized`.
🗣️

```java
private volatile CatalogoPlantillas plantillas;

public CatalogoPlantillas plantillas() {
    CatalogoPlantillas p = plantillas;
    if (p == null) {
        synchronized (this) {
            p = plantillas;
            if (p == null) plantillas = p = CatalogoPlantillas.cargar(fuente);
        }
    }
    return p;
}
```

🔬 Lo que preguntará después: por qué `volatile` (sin él, otro hilo puede ver un catálogo a medio construir), qué pasa si
`cargar` lanza (el campo queda en `null` y se reintenta), y por qué no el holder (es un campo de instancia).

**06 → 14. Revisa este código y di qué falla: un DCL sobre `private CatalogoPlantillas plantillas;` sin `volatile`. 🔴**

⏱️ Falta `volatile`: un hilo que entra por el camino rápido puede ver la referencia antes que el objeto construido y usar un
catálogo con sus campos sin inicializar.
🗣️ Falla de forma intermitente, en producción y con muchos núcleos, porque la escritura de la referencia y las del constructor
se pueden reordenar. La corrección es una palabra: `private volatile CatalogoPlantillas plantillas;`.
🔬 Lo que preguntará después: si basta con que los campos del catálogo sean `final` (evita verlos a medias, pero sin `volatile`
otro hilo puede no ver nunca la referencia y cargar otra vez); y si es un campo estático (entonces, holder).

**06 → 15. Revisa este código y di qué falla: `private volatile long transferenciasDelDia;` incrementado con `++` desde varios hilos. 🔴**

⏱️ `++` no es atómico aunque el campo sea `volatile`: dos hilos leen 41, los dos escriben 42, y se pierde una transferencia
en la cuenta.
🗣️ La corrección es `AtomicLong` con `incrementAndGet()`, o `LongAdder` con `increment()` si hay mucha contención y se lee
poco. `volatile` hace visible cada escritura, no indivisible la operación.
🔬 Lo que preguntará después: por qué `LongAdder` escala mejor (reparte el contador en celdas por hilo y suma al leer) y qué
pierde (la lectura no es un valor exacto en un instante si siguen incrementando).

**06 → 16. Escribe en C++ la inicialización perezosa de un catálogo global y la de un miembro. 🔴**

⏱️ Una estática local para el global, y `std::call_once` con un `std::once_flag` para el miembro.
🗣️

```cpp
const CatalogoTipos& catalogoTipos() {
    static const CatalogoTipos catalogo = CatalogoTipos::cargar();
    return catalogo;
}

class ServicioAvisos {
    mutable std::once_flag cargadas_;
    mutable std::optional<CatalogoPlantillas> plantillas_;
public:
    const CatalogoPlantillas& plantillas() const {
        std::call_once(cargadas_, [this] { plantillas_ = CatalogoPlantillas::cargar(fuente_); });
        return *plantillas_;
    }
};
```

🔬 Lo que preguntará después: qué pasa si `cargar` lanza (en los dos casos, la siguiente llamada lo reintenta), por qué
`mutable` (el método es `const` y la carga perezosa no cambia el estado observable), y cuándo se destruye la estática (al
terminar el programa, en orden inverso de construcción).

# 07 — Simulación de entrevista

Las `S#` que ya son preguntas de capítulo remiten a su respuesta; las demás, en tres capas. Los
ejercicios, desarrollados al final.

**07 → S1. ¿Por qué un objeto inmutable se comparte sin sincronizar, y cuál es la condición? 🟢**

Ver `01 → 1` y `01 → 4`.

**07 → S2. ¿Para qué sirve `volatile` en la referencia a un objeto inmutable? 🟠**

Ver `01 → 10`.

**07 → S3. ¿Qué es el confinamiento por pila? 🟢**

Ver `01 → 2`.

**07 → S4. ¿Por qué un `ThreadLocal` sin `remove()` es peligroso en un servidor? 🟠**

Ver `01 → 11`.

**07 → S5. ¿Qué aportan los Scoped Values de Java 25? 🟡**

Ver `01 → 6`.

**07 → S6. ¿Por qué `wait` va en un `while`? 🟠**

Ver `02 → 10`.

**07 → S7. ¿Cuándo `notify` es correcto y cuándo no? 🟡**

Ver `02 → 5` y `03 → 13`.

**07 → S8. ¿Cuándo un read-write lock empeora las cosas? 🟠**

Ver `02 → 11`.

**07 → S9. ¿Qué diferencia hay entre Guarded Suspension y Balking? 🟡**

Ver `02 → 8`.

**07 → S10. ¿Qué es un interbloqueo y cómo lo evitas al bloquear dos cuentas? 🟠**

⏱️ Dos hilos que esperan cada uno el candado que tiene el otro, para siempre. Al bloquear dos cuentas se evita tomándolas
siempre en el mismo orden, por ejemplo por identificador.
🗣️ La transferencia de `CTA-0001` a `CTA-0003` y otra de `CTA-0003` a `CTA-0001` a la vez: si cada una bloquea primero su
origen, cada una espera la cuenta que tiene la otra. Con orden fijo por id, las dos empiezan por `CTA-0001` y una espera a la
otra.
🔬 Otras salidas: `tryLock` con plazo y reintento, o un solo candado de grano más grueso. En la base pasa lo mismo con
`SELECT ... FOR UPDATE`, y la base lo detecta y aborta una de las dos transacciones.

**07 → S11. ¿Qué es la contrapresión y cómo la implementas? 🟢**

Ver `03 → 2`.

**07 → S12. ¿Por qué `Executors.newFixedThreadPool` puede tumbar un servicio? 🟠**

Ver `03 → 15`.

**07 → S13. ¿Cómo dimensionas un pool? 🟠**

Ver `03 → 9`.

**07 → S14. ¿Por qué no se ponen los *virtual threads* en un pool? 🟠**

Ver `03 → 10`.

**07 → S15. ¿Qué no cambia con *virtual threads*? 🟡**

Ver `03 → 12`.

**07 → S16. ¿Por qué `future.get()` no es asíncrono? 🟠**

Ver `04 → 8`.

**07 → S17. ¿Qué diferencia hay entre `thenApply` y `thenCompose`? 🟡**

Ver `04 → 7`.

**07 → S18. ¿Qué es un Active Object y cuándo lo usarías? 🟢**

Ver `04 → 2` y `04 → 6`.

**07 → S19. ¿Qué diferencia hay entre Reactor y Proactor? 🟡**

Ver `05 → 5`.

**07 → S20. ¿Por qué no se bloquea el bucle de eventos? 🟠**

Ver `05 → 9`.

**07 → S21. ¿Por qué el DCL sin `volatile` está roto? 🟠**

Ver `06 → 8`.

**07 → S22. ¿Qué usas para un estático perezoso, y qué para un campo de instancia? 🟡**

Ver `06 → 4`.

**07 → S23. ¿Por qué `volatile` no hace atómico un `++`? 🟠**

Ver `06 → 5` y `06 → 15`.

**07 → S24. ¿Qué diferencia hay entre una carrera de datos en Java y en C++? 🟡**

⏱️ En Java, una carrera de datos da valores inesperados pero acotados por el modelo de memoria (un valor viejo o uno
reordenado, y un `long` o `double` no `volatile` partido en dos mitades); en C++, es comportamiento indefinido: el programa entero deja de tener significado.
🗣️ Por eso en C++ toda variable compartida que alguien escribe va con `std::atomic` o bajo un `mutex`, sin excepciones, y en
Java existe la garantía especial de los campos `final`.
🔬 Ver `01 → 7`. En los dos lenguajes, una carrera es un error; lo que cambia es cuánto puede empeorar.

**07 → S25. ¿Qué trae C++23 para concurrencia y qué no trae? 🟡**

⏱️ Trae hilos (`std::thread`, `std::jthread` con parada cooperativa), `mutex`, `shared_mutex`, `condition_variable`,
atómicos, `std::atomic<std::shared_ptr>`, `call_once`, `latch`, `barrier`, semáforos y futuros con `std::async`. No trae un
pool de hilos, una cola bloqueante, futuros encadenables ni red.
🗣️ El pool y la cola se escriben con lo que hay (capítulo `03`) o se toman de una librería; la red, sobre la API del sistema.
🔬 Los futuros de C++ se esperan con `get()`; para componer sin bloquear se usan librerías o corrutinas.

**07 → S26. "Ponemos `synchronized` en todos los métodos públicos y listo: es seguro entre hilos." ¿Qué respondes? 🔴**

⏱️ Que cada método será atómico, pero las operaciones que combinan dos llamadas no: comprobar el saldo y después retirar son
dos métodos sincronizados con una carrera entre ellos.
🗣️ Además serializa a todos los lectores, no protege lo que se devuelve (una lista interna sale y se modifica sin candado), y
llamar a código ajeno con el candado tomado abre la puerta a interbloqueos. La seguridad se diseña por operación del negocio,
no por método.
🔬 Lo primero es preguntar qué estado tiene que ser mutable y compartido: lo que puede ser inmutable o confinado no necesita
candado ninguno.

**07 → S27. "Con *virtual threads* podemos lanzar un millón de consultas a la base a la vez." ¿Qué pasa? 🔴**

⏱️ Que la base tiene, por ejemplo, veinte conexiones: 999 980 hilos esperan una conexión, el pool de conexiones agota su plazo
y empiezan los errores. Los hilos son baratos; las conexiones no.
🗣️ El límite se pone en el recurso, con un semáforo o con el propio pool de conexiones y un plazo de espera razonable, y la
entrada necesita contrapresión. Lanzar menos y en orden puede terminar antes.
🔬 La JEP 444 lo dice: para limitar la concurrencia, no pools de hilos virtuales, sino construcciones como los semáforos.

**07 → S28. "Migremos todo a WebFlux para escalar." ¿Qué preguntas antes? 🔴**

⏱️ Dónde está el cuello de botella hoy, si las dependencias (JDBC, clientes de terceros) son no bloqueantes, y si estamos en
Java 21, donde los *virtual threads* dan casi la misma escalabilidad sin reescribir.
🗣️ WebFlux escala con pocos hilos solo si nada bloquea el bucle; con JDBC dentro, congela el servidor. Y el costo es grande:
todo el código en estilo reactivo, depuración con pilas que no dicen quién llamó, y un equipo que tiene que aprenderlo.
🔬 Tiene sentido para conexiones largas, *streaming* o cuando todo el camino ya es reactivo; para petición y respuesta con E/S,
en Java 21, probablemente no.

**07 → S29. "El DCL es un antipatrón, nunca lo uses." ¿Estás de acuerdo? 🔴**

⏱️ Con matices: el DCL sin `volatile` está roto; con `volatile`, desde Java 5, es correcto. Para estáticos uso el holder;
para un campo de instancia perezoso y caro, el DCL con `volatile`.
🗣️ Lo que sí comparto es que casi nunca hay que escribirlo a mano: un `Supplier` memoizado, el holder o, en Java 25,
`StableValue` lo encapsulan. Y que la inicialización perezosa rara vez compensa.
🔬 Ver `06 → 9`. En C++, la respuesta es `call_once` o una estática local.

**07 → S30. Te piden que demuestres que un código concurrente es correcto con una prueba. ¿Qué dices? 🔴**

⏱️ Que una prueba puede encontrar una carrera, pero no demostrar que no la hay: la intercalación que rompe puede ocurrir una
vez cada millones de ejecuciones, o solo en otro procesador.
🗣️ Lo que hago es razonar sobre las relaciones de *ocurre antes* (qué sincroniza qué), preferir estructuras ya probadas
(`BlockingQueue`, atómicos, inmutables), y añadir pruebas de estrés con muchos hilos y repeticiones, sabiendo que son una red y
no una demostración.
🔬 Hay herramientas que exploran intercalaciones de forma sistemática (*jcstress* en Java, *ThreadSanitizer* en C++); el
argumento que convence sigue siendo el diseño.

**07 → E1. La cola de transferencias.**

**Enunciado.** Picos de tres mil solicitudes por minuto, 200 ms por transferencia, veinte conexiones a la base y cincuenta
llamadas simultáneas al sistema de pagos. Java 21.

**El primer diseño que sale.** Un hilo por solicitud desde el controlador, o `newFixedThreadPool(100)`.

**El bueno.**

- **Las cuentas**: tres mil por minuto son 50 por segundo; con 200 ms cada una, en régimen hacen falta unas 10 en curso. El
  recurso más estrecho son las veinte conexiones: con veinte en curso caben unas 100 por segundo, el doble del pico.
- **Entrada**: una `ArrayBlockingQueue` acotada (por ejemplo 1 000, unos veinte segundos de pico); el controlador hace
  `offer` con plazo corto y, si no cabe, responde `503` con `Retry-After`.
- **Consumidores**: un hilo virtual por solicitud sacada de la cola, con un `Semaphore(20)` alrededor del trabajo con la base
  y otro `Semaphore(50)` alrededor de la llamada a pagos, cada uno con `tryAcquire` y plazo.
- **Respuesta al cliente**: `202 Accepted` con un identificador de solicitud, y un recurso para consultar su estado.

**Lo que cuesta.** Una cola que vigilar (su tamaño como métrica), dos semáforos y un estado de solicitud consultable. Lo que se
pierde si el proceso cae: lo encolado en memoria; si no se puede perder, se guarda la solicitud antes de aceptarla.

**Lo que preguntará después.** Qué pasa si el sistema de pagos se pone lento (los semáforos se agotan, la cola se llena y la
contrapresión llega al cliente, en lugar de tumbar el servicio); cómo se evita que una transferencia se ejecute dos veces si el
cliente reintenta (un identificador de idempotencia en la solicitud); y por qué no un pool de veinte hilos de plataforma (en
Java 17 sería la respuesta; en 21, los hilos virtuales con semáforos separan el límite de cada recurso).

**07 → E2. El Singleton perezoso roto.**

**Enunciado.** `TarifasCambio.instancia()` con DCL sobre un estático sin `volatile`.

**El primer diseño que sale.** Añadir `synchronized` al método entero.

**El bueno.**

- **Qué falla**: el campo `instancia` no es `volatile`. Un hilo que entra por el camino rápido puede ver la referencia escrita
  antes de que el constructor termine de cargar `tasas`. Como `tasas` es `final`, la garantía de §17.5 evita verlo a medias si
  la referencia se obtiene después del constructor; pero sin `volatile`, la publicación no tiene relación de *ocurre antes*, y
  con objetos más complejos o campos no `final`, se ve un objeto a medio construir.
- **Cómo se manifiesta**: rara vez, en producción, con muchos núcleos: un `NullPointerException` o una tasa que falta.
- **Corrección mínima**: `private static volatile TarifasCambio instancia;`.
- **La que propondría**: el holder, porque es un estático; o mejor, que `TarifasCambio` no sea un Singleton sino un bean que
  el contenedor crea y se inyecta, con las tasas recargables como el objeto inmutable de `01` y una referencia `volatile`.

**Lo que cuesta.** El holder: cero. Quitar el Singleton: tocar a quienes llaman a `instancia()`.

**Lo que preguntará después.** Qué pasa si `cargarDeProveedor()` falla dentro del holder (la clase queda en error y cada uso
lanza `NoClassDefFoundError`; si la carga puede fallar, DCL con `volatile` o inicialización al arrancar); y por qué
`synchronized` en el método es correcto pero caro (cada llamada toma el candado).

**07 → E3. ¿Pool o *virtual threads*?**

**Enunciado.** Diez mil extractos PDF de 2 s de CPU al cierre, y cientos de consultas por segundo que esperan a tres
servicios. 16 núcleos.

**El primer diseño que sale.** Un solo pool grande para todo, o *virtual threads* para todo.

**El bueno.**

- **Extractos (CPU)**: un pool de plataforma de 16 hilos (los núcleos) con cola acotada. Diez mil × 2 s / 16 ≈ 21 minutos.
  Más hilos no lo acelera: solo añaden cambios de contexto.
- **Consultas (E/S)**: un hilo virtual por consulta, con las tres llamadas en paralelo (`CompletableFuture` sobre un ejecutor de
  hilos virtuales, o tres tareas) y un semáforo por servicio externo.
- **Lo que no deben compartir**: el pool. Si los extractos corren en hilos virtuales, ocupan los hilos portadores, que por
  defecto son tantos como procesadores (JEP 444), y las consultas esperan detrás de ellos. Por eso el CPU va en su pool propio,
  y quizás con menos de 16 hilos para dejar núcleos a las consultas.

**Lo que cuesta.** Dos modelos de ejecución en el mismo servicio y elegir cuántos núcleos se reservan para cada uno.

**Lo que preguntará después.** Si los extractos deberían ir a otro proceso (si compiten con las consultas en horas de uso,
sí); cómo se reparte la máquina (menos hilos para el CPU, o prioridades en otro proceso); y qué cambia en Java 17 (las
consultas van a un pool de plataforma dimensionado por la fórmula de E/S).

**07 → E4. El contador de transferencias del día.**

**Enunciado.** Doscientos hilos suman uno por transferencia; el tablero muestra el total.

**El primer diseño que sale.** Un Active Object con cola, o un monitor con `wait`/`notifyAll` para que el tablero espere.

**El bueno.** Un `LongAdder`, sin patrón:

```java
private final LongAdder transferenciasDelDia = new LongAdder();

public void registrar() { transferenciasDelDia.increment(); }    // desde cualquier hilo
public long total() { return transferenciasDelDia.sum(); }        // el tablero lo lee cada segundo
```

- `LongAdder` está hecho para muchos hilos que suman y pocos que leen. El tablero pregunta cada segundo; nadie necesita
  esperar un cambio.

**Lo que cuesta.** Nada que valga la pena discutir. La suma no es una foto exacta si se sigue sumando mientras se lee, y para
un tablero da igual.

**Lo que preguntará después.** Qué pasa al reiniciar el proceso (el contador se pierde; si el número tiene que ser exacto, se
cuenta en la base); cómo se reinicia a medianoche (`sumThenReset`); y por qué no `volatile long` con `++` (no es atómico).

**07 → E5. El usuario que aparece en otra petición.**

**Enunciado.** Un filtro que pone el usuario en un `ThreadLocal` solo si la petición está autenticada, y un método `@Async`
que lo lee.

**El primer diseño que sale.** Poner `USUARIO.set(null)` al principio del filtro.

**El bueno.** Son dos defectos:

1. **El usuario equivocado**: el filtro nunca llama a `remove()`. Una petición anónima que cae en un hilo del *pool* que antes
   atendió a Ana no hace `set`, y lee el valor que quedó: Ana. La corrección es poner y quitar en el mismo sitio:

   ```java
   try {
       if (autenticado(req)) USUARIO.set(usuarioDe(req));
       cadena.doFilter(req, res);
   } finally {
       USUARIO.remove();
   }
   ```

2. **El `null`**: `@Async` ejecuta `auditar` en otro hilo, donde el `ThreadLocal` nunca se puso. El valor no viaja: hay que
   pasarlo como parámetro, `auditar(PersonaId usuario, String evento)`, leído en el hilo de la petición.

**Lo que cuesta.** Un `finally` y un parámetro más. A cambio, la auditoría dice la verdad.

**Lo que preguntará después.** Si hay forma de propagarlo solo (un decorador de tareas en el ejecutor que copie el contexto,
como hace Spring Security con su contexto, a costa de más magia); qué cambia en Java 25 (Scoped Values, que no se fugan y
cuyos valores heredan las subtareas de la concurrencia estructurada); y si `@Async` llamado desde la misma clase se ejecuta en
otro hilo (no: la autoinvocación no pasa por el proxy, ver `05/03`).
