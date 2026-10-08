# 02 — Patrones en el JDK y en la STL

> Señalar el patrón en las librerías estándar que se usan a diario —`java.io`, las colecciones, `java.util.concurrent`, los
> iteradores y los contenedores de la STL, `std::function`, `std::variant`, RAII— y leer en ellas **qué forma tomó cada
> patrón en cada lenguaje**. Es un capítulo de mapa: el patrón lo explica su capítulo, enlazado; aquí se lo reconoce.
> **Lenguajes:** C++ y Java. Asume leído [`05/02` — Decorator](../05-estructurales/02-decorator.md) y
> [`06/08` — Iterator y Mediator](../06-comportamiento/08-iterator-y-mediator.md).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 (2026-10-04).

---

## 1. 🎯 El problema

En una entrevista, después de veinte minutos sobre Strategy y Decorator, llega la pregunta que separa: *"¿dónde has usado esto
sin escribirlo?"*. La respuesta habitual es un silencio, o un ejemplo de un proyecto propio con una jerarquía de clases que el
entrevistador no conoce.

```java
try (var lector = new BufferedReader(new InputStreamReader(new FileInputStream(ruta), StandardCharsets.UTF_8))) {
    List<String> lineas = lector.lines().sorted(Comparator.comparing(String::length)).toList();
}
```

- En dos líneas hay un Decorator (`BufferedReader` envuelve a otro lector), un Adapter (`InputStreamReader` convierte bytes en
  caracteres), un Strategy (el `Comparator`), un Iterator perezoso (el *stream*) y un recurso con dueño (el `try`). Nadie los
  escribió: los trae la librería.
- "Los patrones son para el código de aplicación" es la simplificación que este capítulo desmonta: la librería estándar es el
  catálogo de patrones más usado del mundo, y reconocerlo es la forma más rápida de explicarlos.

---

## 2. 🔭 Los estructurales

**Decorator.** `java.io` es el ejemplo canónico: `BufferedInputStream`, `DataInputStream` y `GZIPInputStream` envuelven a otro
`InputStream` con la misma interfaz y le añaden algo. `Collections.unmodifiableList`, `synchronizedList` y `checkedList`
envuelven una lista y le añaden, respectivamente, solo lectura, un candado por operación y una comprobación de tipo. Ver
[`05/02`](../05-estructurales/02-decorator.md).

**Adapter.** `InputStreamReader` adapta un flujo de bytes a uno de caracteres; `Arrays.asList` adapta un arreglo a la interfaz
`List`. En la STL, `std::stack`, `std::queue` y `std::priority_queue` se llaman literalmente **adaptadores de contenedor**:
cppreference dice que `std::stack` envuelve un contenedor subyacente y solo ofrece un conjunto concreto de funciones. Y
`std::back_inserter` adapta un contenedor a la interfaz de un iterador de salida. Ver [`05/01`](../05-estructurales/01-adapter.md).

**Proxy.** `java.lang.reflect.Proxy` genera proxies dinámicos sobre interfaces; `Collections.unmodifiableList` es también un proxy
de protección. En C++, `std::shared_ptr` es un proxy inteligente: controla el acceso y el ciclo de vida del objeto. Ver
[`05/03`](../05-estructurales/03-proxy.md).

**Flyweight.** `Integer.valueOf` comparte las instancias de −128 a 127; los literales de `String` se comparten por internamiento.
Ver [`05/07`](../05-estructurales/07-flyweight.md).

---

## 3. 🔭 Los de comportamiento

**Strategy.** `Comparator` es una estrategia de comparación: `lista.sort(Comparator.comparing(Persona::fechaNacimiento))`. En C++, la
estrategia se pasa como parámetro de plantilla —el comparador de `std::sort`, el `std::hash` de un `unordered_map`, el
*allocator* de un contenedor— y se resuelve al compilar, sin llamada virtual. Ver [`06/01`](../06-comportamiento/01-strategy.md).

```cpp
std::ranges::sort(personas, {}, &Persona::fechaNacimiento);             // la estrategia: ordenar por esta proyección
std::pmr::monotonic_buffer_resource bufer;                              // un allocator como estrategia, elegida al ejecutar
std::pmr::vector<Movimiento> movimientos{&bufer};
```

- `std::pmr::polymorphic_allocator` (C++17) es la estrategia de reserva de memoria elegida **al ejecutar**, detrás de una interfaz
  virtual; el *allocator* clásico es la misma estrategia elegida **al compilar**. Las dos formas del Strategy en C++, en la misma
  librería.

**Iterator.** `Iterable` e `Iterator` en Java; en la STL, los **iteradores** son el concepto central: cada algoritmo trabaja sobre
un par de iteradores, y por eso `std::sort` sirve para cualquier contenedor de acceso aleatorio. Los rangos de C++20 lo llevan a un
objeto. Ver [`06/08`](../06-comportamiento/08-iterator-y-mediator.md).

**Template Method.** `AbstractList` implementa toda la `List` con solo `get` y `size`; `HttpServlet.service` llama a `doGet` o
`doPost`. Ver [`06/02`](../06-comportamiento/02-template-method.md).

- En la STL el Template Method casi no aparece: la variación se pasa como parámetro de plantilla o como función, no se
  hereda. Es la misma tensión resuelta por composición.

**Command.** `Runnable` y `Callable` son comandos; el `Executor`, cuya Javadoc dice que desacopla el envío de una tarea de cómo se
ejecuta, es quien los recibe y decide cuándo y en qué hilo. Ver [`06/04`](../06-comportamiento/04-command.md) y
[`10/03`](../10-concurrencia/03-producer-consumer-y-thread-pool.md).

**Observer.** `Flow.Publisher` y `Flow.Subscriber` en `java.util.concurrent`; los oyentes de `java.beans`. Ver
[`06/03`](../06-comportamiento/03-observer.md).

**Interpreter.** `java.util.regex.Pattern`: una gramática (las expresiones regulares) compilada a un árbol que se evalúa contra la
entrada. Ver [`06/09`](../06-comportamiento/09-memento-e-interpreter.md).

**Visitor, y lo que lo reemplaza.** En la STL, `std::variant` con `std::visit`; en Java, `FileVisitor` de `java.nio.file` y, desde Java
21, el `switch` sobre tipos sellados. Ver [`06/07`](../06-comportamiento/07-visitor.md).

---

## 4. 🔭 Los creacionales

**Factory Method y fábricas estáticas.** `List.of`, `Optional.of`, `Path.of`, `Calendar.getInstance`: métodos que devuelven un objeto
sin decir qué clase concreta. En C++, `std::make_unique` y `std::make_shared`. Ver [`04/01`](../04-creacionales/01-factory-method.md).

**Builder.** `StringBuilder`, `HttpClient.newBuilder()`, `Stream.builder()`. Ver [`04/03`](../04-creacionales/03-builder.md).

**Singleton.** `Runtime.getRuntime()`: su Javadoc dice que toda aplicación tiene **una sola instancia** de `Runtime`. Es uno de los
pocos casos legítimos: la unicidad es un hecho del entorno (hay un solo proceso), no una comodidad. Ver
[`04/05`](../04-creacionales/05-singleton.md).

---

## 5. 🔭 Lo que en C++ es un idioma del lenguaje

**RAII.** El recurso con dueño de [`01/04`](../01-modelo-de-objetos/04-copia-ciclo-de-vida-y-recursos.md) está en toda la STL:
`std::unique_ptr`, `std::lock_guard`, `std::jthread`, `std::fstream` adquieren en el constructor y liberan en el destructor. Es el
*Scoped Locking* de POSA2 y lo que en Java hace el `try`-with-resources.

**Type erasure con `std::function`.** `std::function<Dinero(Dinero)>` guarda **cualquier** cosa invocable con esa firma —una lambda,
una función, un objeto con `operator()`— detrás de un tipo único, sin herencia. Es un Strategy o un Command sin jerarquía: la
interfaz virtual existe, pero dentro de la librería.

```cpp
std::function<Dinero(Dinero)> comision = [](Dinero monto) { return monto.porcentaje(0.5); };   // una lambda
comision = TarifaFija{Dinero::cop(2000)};                                                      // un objeto con operator()
```

- El precio, como en [`06/01`](../06-comportamiento/01-strategy.md): una llamada indirecta y, para objetos grandes, una reserva en
  el montículo. Una plantilla evita los dos y fija la estrategia al compilar.

---

## 6. 🧭 El mapa

| Patrón | Java | C++ (STL) | Lo que cambió de forma |
|---|---|---|---|
| Decorator | `BufferedInputStream`, `Collections.unmodifiableList` | — (por composición propia) | Nada: es el ejemplo de libro |
| Adapter | `InputStreamReader`, `Arrays.asList` | `std::stack`, `std::back_inserter` | En C++ se llaman así en el estándar |
| Strategy | `Comparator` | comparadores, `std::hash`, *allocators* | En C++, parámetro de plantilla, sin llamada virtual |
| Iterator | `Iterable`, *streams* | iteradores y rangos | En C++ es el concepto central de la librería |
| Command | `Runnable`, `Callable` + `Executor` | `std::function`, `std::packaged_task` | Una función ya es un comando |
| Visitor | `FileVisitor`; `switch` sellado (21) | `std::variant` + `std::visit` | El lenguaje lo reemplaza |
| Factory | `List.of`, `Path.of` | `std::make_unique` | Métodos estáticos, sin jerarquía |
| Singleton | `Runtime.getRuntime()` | — | Solo donde la unicidad es un hecho |
| RAII / recurso con dueño | `try`-with-resources | destructores en toda la librería | En C++ es el idioma base |

**La frase en voz alta:** *"El Decorator lo uso cada vez que abro un archivo: `BufferedReader` envuelve a un `InputStreamReader`, que
además es un Adapter de bytes a caracteres. Y en C++ la Strategy casi nunca es una interfaz: es el comparador que paso como parámetro
de plantilla a `std::sort`."*

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Los patrones son para el código de aplicación" | La librería estándar es el catálogo más usado; los patrones están en `java.io`, las colecciones y la STL |
| "Strategy siempre es una interfaz con implementaciones" | En C++ suele ser un parámetro de plantilla, resuelto al compilar |
| "`Arrays.asList` copia el arreglo" | Lo adapta: la lista está respaldada por el arreglo y tiene tamaño fijo |
| "`std::stack` es un contenedor" | Es un adaptador sobre otro contenedor, con un subconjunto de operaciones |
| "`Runtime.getRuntime()` demuestra que el Singleton es buena idea" | Demuestra que lo es cuando la unicidad es un hecho del entorno |
| "`std::function` es gratis" | Cuesta una llamada indirecta y a veces una reserva; una plantilla no |
| "`Collections.synchronizedList` hace segura cualquier secuencia de operaciones" | Sincroniza cada operación; recorrer o comprobar y actuar sigue necesitando el candado externo |

---

## 📚 Para profundizar

- **Libro** — Iglberger, *C++ Software Design* (O'Reilly, 2022), cap. 5, "The Strategy and Command Design Patterns", y cap. 8,
  "The Type Erasure Design Pattern": los patrones como los escribe la STL. **El que destaca.**
- **Libro** — Bloch, *Effective Java*, 3.ª ed. (Addison-Wesley, 2018), ítem 1, "Consider static factory methods instead of
  constructors": las fábricas estáticas del JDK.
- [Java 21 API — `Executor`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/Executor.html):
  el envío desacoplado de la ejecución.
- [Java 21 API — `Runtime`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Runtime.html): la instancia
  única.
- [cppreference — `std::stack`](https://en.cppreference.com/cpp/container/stack): un adaptador de contenedor.
- [cppreference — `std::function`](https://en.cppreference.com/cpp/utility/functional/function)
- [cppreference — `std::pmr::polymorphic_allocator`](https://en.cppreference.com/cpp/memory/polymorphic_allocator)

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md#02--patrones-en-el-jdk-y-en-la-stl).

1. ¿Qué patrón es `BufferedInputStream`? 🟢
2. ¿Qué patrón es `Comparator`? 🟢
3. ¿Qué patrón es `InputStreamReader`? 🟢
4. ¿Qué es un adaptador de contenedor en la STL? 🟢
5. ¿Qué patrón es la pareja `Runnable` y `Executor`? 🟢
6. ¿Qué diferencia hay entre una estrategia en Java y en la STL? 🟡
7. ¿Qué diferencia hay entre `std::function` y una interfaz de Java? 🟡
8. ¿Qué diferencia hay entre `Collections.unmodifiableList` y `List.copyOf`? 🟡
9. ¿Qué diferencia hay entre el *allocator* clásico y `std::pmr::polymorphic_allocator`? 🟡
10. ¿Por qué `Runtime.getRuntime()` es un Singleton legítimo? 🟠
11. ¿Por qué "los patrones son para el código de aplicación" es falso? 🟠
12. ¿Por qué `Collections.synchronizedList` no basta para recorrer la lista desde varios hilos? 🟠
13. Señala todos los patrones de esta línea: `new BufferedReader(new InputStreamReader(new FileInputStream(ruta), UTF_8)).lines().sorted(Comparator.comparing(String::length))`. 🔴
14. Escribe en C++ una estrategia de comisión guardada en `std::function`, y di cuándo usarías una plantilla en su lugar. 🔴

---

**Anterior:** [`01` — Patrones en Spring](01-patrones-en-spring.md) ·
**Siguiente:** [`03` — Refactorizar hacia patrones, y desde ellos](03-refactorizar-hacia-patrones.md) ·
**Relacionado:** [`05/02` — Decorator](../05-estructurales/02-decorator.md)
