# 08 — Simulación de entrevista

> El examen del bloque `04-creacionales`: preguntas transversales que cruzan los siete capítulos y cinco
> ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-factory-method.md) a
> [`07`](07-mas-alla-del-gof.md). Las respuestas, en
> [`09` — Respuestas](09-respuestas.md#08--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 · Lombok 1.18.48 (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Empezando por "¿hace falta?".** En este bloque la mitad de las respuestas buenas empiezan por "un
  constructor bastaría si…". El entrevistador quiere ver que sabes cuándo **no** poner una fábrica.
- **Tecleando.** Los Singletons, los builders y las fábricas se escriben, no se describen: el detalle (el
  `volatile`, el `build()` que valida, el `unique_ptr` de retorno) es lo que se evalúa.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Fábricas

**S1.** ¿Qué diferencia hay entre el Factory Method del GoF y una fábrica estática? 🟡

**S2.** ¿Por qué `Iterable.iterator()` es un Factory Method del GoF? 🟠

**S3.** ¿Cuándo un `switch` por código de tipo se convierte en un registro de fábricas, y cuándo en datos? 🟠

**S4.** ¿Qué diferencia hay entre Abstract Factory y Factory Method? 🟡

**S5.** ¿Qué gana una fábrica estática sobre un constructor, y qué pierde? 🟡

**S6.** Nombra tres fábricas estáticas del JDK y di qué ventaja aprovecha cada una. 🟢

### Bloque B — Builder y Prototype

**S7.** ¿Qué diferencia hay entre el Builder del GoF y el de Bloch? 🟡

**S8.** ¿Por qué "con records ya no hace falta Builder" es falso? 🟠

**S9.** ¿Dónde se valida en un builder, y qué pasa si no se valida? 🟠

**S10.** ¿Qué es Prototype, y por qué no es `clone()`? 🟡

**S11.** ¿Por qué un objeto inmutable no necesita Prototype ni constructor de copia? 🟠

### Bloque C — Singleton e inyección

**S12.** Escribe un Singleton seguro entre hilos en Java, en la forma que prefieras, y di por qué es seguro. 🟡

**S13.** ¿Qué diferencia hay entre el Singleton del GoF y el bean singleton de Spring? 🟡

**S14.** ¿Por qué el Singleton dificulta las pruebas? 🟠

**S15.** ¿Qué diferencia hay entre un contenedor de inyección y un Service Locator? 🟡

**S16.** ¿Por qué la inyección por constructor es la recomendada? 🟠

**S17.** ¿Qué diferencia hay entre IoC, inyección de dependencias y contenedor? 🟡

**S18.** ¿Qué hace un contenedor que una raíz de composición a mano no hace? 🟡

### Bloque D — Ciclo de vida

**S19.** ¿Qué es RAII, y por qué no es solo para memoria? 🟢

**S20.** ¿Cuándo un pool mejora el rendimiento y cuándo lo empeora? 🟠

**S21.** ¿Cuándo inicializarías algo de forma perezosa? 🟠

**S22.** ¿Qué tienen en común RAII y un pool de conexiones? 🟠

### Bloque E — Los lenguajes

**S23.** ¿Qué cambia en las fábricas de C++ moderno respecto de C++98? 🟡

**S24.** ¿Cómo se resuelven los argumentos con nombre en C++20, en Java y en C#? 🟡

**S25.** ¿Por qué en C++ el Singleton no necesita `mutex` y en Java el DCL necesita `volatile`? 🟠

### Bloque F — Las que descolocan

**S26.** "En mi equipo todas las clases tienen su `Factory`, por si mañana cambia la implementación." ¿Qué le
dices? 🔴

**S27.** "¿Para qué inyectar el catálogo si con un Singleton lo tengo en una línea?" 🔴

**S28.** El entrevistador te pide un Singleton "a prueba de todo". ¿Qué escribes y qué le preguntas? 🔴

**S29.** "Los patrones creacionales sobran en un lenguaje con Spring." ¿Estás de acuerdo? 🔴

**S30.** "¿Usarías Abstract Factory aquí?" sobre un sistema con un solo país. ¿Qué respondes? 🔴

**S31.** "Lombok `@Builder` y listo, ¿no?" 🔴

**S32.** Te piden nombrar los cinco creacionales del GoF y uno que no esté en el libro. ¿Qué añades para que la
respuesta no sea una lista? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Documentos de varios países (elegir)

**Fuerza:** elegir entre constructor, Type Object, registro de fábricas y Abstract Factory, nombrando lo que
cuesta cada uno.

El sistema empieza a aceptar documentos de Perú y Chile, además de Colombia y México. Cada país tiene su
formato de número; Colombia calcula el vencimiento de la tarjeta de identidad a los 18 años del titular; y
cada país muestra el número a su manera en los avisos. Decide cómo se crean y validan los documentos, y
escribe las firmas.

### E2 — El catálogo global (refactorizar)

**Fuerza:** separar "una sola instancia" de "acceso global" sin romper el sistema en un solo paso.

```java
public class CatalogoTipos {
    private static CatalogoTipos instancia;
    public static synchronized CatalogoTipos getInstance() {
        if (instancia == null) instancia = new CatalogoTipos();
        return instancia;
    }
    private final Map<String, TipoDocumento> porCodigo = cargarDesdeBase();
    public TipoDocumento deCodigo(String c) { return porCodigo.get(c); }
}

// en Documento, ValidadorDocumento, ExportadorCsv, RegistroPersonas...
TipoDocumento t = CatalogoTipos.getInstance().deCodigo(codigo);
```

El catálogo se usa en cuarenta sitios. Propón cómo reemplazar el Singleton por inyección, en pasos que se
puedan desplegar por separado.

### E3 — El builder que deja pasar menores sin tutor (revisar)

**Fuerza:** encontrar en una revisión por qué un builder "bonito" no protege nada.

```java
@Builder
@Getter
public class Persona {
    private String nombre;
    private LocalDate fechaNacimiento;
    private Persona tutor;
    private String email;
}

Persona luis = Persona.builder().nombre("Luis Rojas Paz").build();
```

Nombra los defectos por gravedad y escribe la versión corregida.

### E4 — El `Movimiento` con fábrica (elegir, sin patrón)

**Fuerza:** reconocer que la respuesta correcta es un constructor.

Un compañero propone para `Movimiento` (cuenta, importe, fecha, concepto, todos obligatorios) una interfaz
`FabricaMovimientos`, su implementación `FabricaMovimientosImpl` inyectada en `Cuenta`, y un
`MovimientoBuilder` "para que sea extensible". Diseña la solución.

### E5 — La transferencia que deja cuentas bloqueadas (refactorizar)

**Fuerza:** garantizar la liberación de varios recursos en todos los caminos.

```cpp
void transferir(Conexion& bd, Cuenta& origen, Cuenta& destino, Dinero monto) {
    origen.cerrojo().lock();
    destino.cerrojo().lock();
    bd.ejecutar("BEGIN");
    origen.debitar(monto);
    destino.acreditar(monto);
    bd.ejecutar("COMMIT");
    destino.cerrojo().unlock();
    origen.cerrojo().unlock();
}
```

Bajo carga, a veces dos cuentas quedan bloqueadas para siempre, y a veces una transacción queda abierta.
Explica las dos causas y escribe la versión corregida.

---

## 4. 🧭 Las frases que hay que tener listas

> "Antes de una fábrica, pregunto qué varía. Si es un dato, va en el objeto tipo; si es lógica por código, un
> registro; si no varía nada, un constructor."

> "Hay dos promesas en el Singleton: una instancia y acceso global. La primera la da el contenedor; la segunda
> es la que hace imposible probar."

> "Todo recurso que no es memoria tiene un dueño que lo suelta: en C++ el destructor, en Java un
> `try-with-resources`."

---

**Anterior:** [`07` — Más allá del GoF](07-mas-alla-del-gof.md) ·
**Siguiente:** [`09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`05` — Singleton](05-singleton.md)
