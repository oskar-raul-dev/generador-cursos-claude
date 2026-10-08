# 07 — Simulación de entrevista

> El examen del bloque `10-concurrencia`: preguntas transversales que cruzan los seis capítulos y cinco ejercicios de
> diseño de veinte minutos. Asume leídos los capítulos [`01`](01-inmutabilidad-y-confinamiento.md) a
> [`06`](06-inicializacion-perezosa-segura.md). Las respuestas, en
> [`08` — Respuestas](08-respuestas.md#07--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Con la secuencia que rompe.** En concurrencia, "esto no es seguro" no vale: el entrevistador espera la intercalación
  concreta de dos hilos que produce el error. Escríbela en dos columnas, hilo A y hilo B.
- **Primero sin candados.** Antes de sincronizar, pregunta si el estado puede ser inmutable o confinado. Es el orden del
  bloque y el que distingue a quien entiende de quien pone `synchronized` en todo.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Inmutable y confinado

**S1.** ¿Por qué un objeto inmutable se comparte sin sincronizar, y cuál es la condición? 🟢

**S2.** ¿Para qué sirve `volatile` en la referencia a un objeto inmutable? 🟠

**S3.** ¿Qué es el confinamiento por pila? 🟢

**S4.** ¿Por qué un `ThreadLocal` sin `remove()` es peligroso en un servidor? 🟠

**S5.** ¿Qué aportan los Scoped Values de Java 25? 🟡

### Bloque B — Monitores y candados

**S6.** ¿Por qué `wait` va en un `while`? 🟠

**S7.** ¿Cuándo `notify` es correcto y cuándo no? 🟡

**S8.** ¿Cuándo un read-write lock empeora las cosas? 🟠

**S9.** ¿Qué diferencia hay entre Guarded Suspension y Balking? 🟡

**S10.** ¿Qué es un interbloqueo y cómo lo evitas al bloquear dos cuentas? 🟠

### Bloque C — Colas y pools

**S11.** ¿Qué es la contrapresión y cómo la implementas? 🟢

**S12.** ¿Por qué `Executors.newFixedThreadPool` puede tumbar un servicio? 🟠

**S13.** ¿Cómo dimensionas un pool? 🟠

**S14.** ¿Por qué no se ponen los *virtual threads* en un pool? 🟠

**S15.** ¿Qué no cambia con *virtual threads*? 🟡

### Bloque D — Futuros y eventos

**S16.** ¿Por qué `future.get()` no es asíncrono? 🟠

**S17.** ¿Qué diferencia hay entre `thenApply` y `thenCompose`? 🟡

**S18.** ¿Qué es un Active Object y cuándo lo usarías? 🟢

**S19.** ¿Qué diferencia hay entre Reactor y Proactor? 🟡

**S20.** ¿Por qué no se bloquea el bucle de eventos? 🟠

### Bloque E — Inicialización perezosa

**S21.** ¿Por qué el DCL sin `volatile` está roto? 🟠

**S22.** ¿Qué usas para un estático perezoso, y qué para un campo de instancia? 🟡

**S23.** ¿Por qué `volatile` no hace atómico un `++`? 🟠

### Bloque F — Los lenguajes

**S24.** ¿Qué diferencia hay entre una carrera de datos en Java y en C++? 🟡

**S25.** ¿Qué trae C++23 para concurrencia y qué no trae? 🟡

### Bloque G — Las que descolocan

**S26.** "Ponemos `synchronized` en todos los métodos públicos y listo: es seguro entre hilos." ¿Qué respondes? 🔴

**S27.** "Con *virtual threads* podemos lanzar un millón de consultas a la base a la vez." ¿Qué pasa? 🔴

**S28.** "Migremos todo a WebFlux para escalar." ¿Qué preguntas antes? 🔴

**S29.** "El DCL es un antipatrón, nunca lo uses." ¿Estás de acuerdo? 🔴

**S30.** Te piden que demuestres que un código concurrente es correcto con una prueba. ¿Qué dices? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — La cola de transferencias (diseñar)

**Fuerza:** desacoplar el API de la ejecución con contrapresión y un límite por el recurso escaso.

El API recibe picos de tres mil solicitudes de transferencia por minuto. Cada transferencia tarda 200 ms (casi todo
esperando a la base y al sistema de pagos), hay veinte conexiones a la base y el sistema de pagos acepta cincuenta llamadas
simultáneas. Diseña la cola, los consumidores, qué pasa cuando no da abasto y qué ve el cliente. Java 21.

### E2 — El Singleton perezoso roto (revisar)

**Fuerza:** encontrar la publicación sin sincronización y elegir la forma correcta según sea estático o de instancia.

```java
public final class TarifasCambio {
    private static TarifasCambio instancia;
    private final Map<String, BigDecimal> tasas;

    private TarifasCambio() { tasas = cargarDeProveedor(); }

    public static TarifasCambio instancia() {
        if (instancia == null) {
            synchronized (TarifasCambio.class) {
                if (instancia == null) instancia = new TarifasCambio();
            }
        }
        return instancia;
    }
}
```

Di qué falla, cómo se manifiesta, cuál es la corrección mínima y cuál la que propondrías.

### E3 — ¿Pool o *virtual threads*? (elegir)

**Fuerza:** distinguir trabajo de CPU de trabajo de E/S y elegir el modelo de hilos para cada uno.

El servicio hace dos cosas: genera extractos mensuales en PDF (cálculo y composición, unos 2 s de CPU cada uno, diez mil al
cierre de mes) y atiende consultas que llaman a tres servicios externos (300 ms de espera cada uno, cientos por segundo).
La máquina tiene 16 núcleos. Elige el modelo para cada una, con números, y di qué compartirían y qué no.

### E4 — El contador de transferencias del día (elegir, sin patrón)

**Fuerza:** reconocer que un contador concurrente no necesita un diseño.

El tablero muestra cuántas transferencias se hicieron hoy. Cada transferencia, en cualquiera de doscientos hilos, suma uno.
Un compañero propone un Active Object con su cola, o un monitor con `synchronized`, `wait` y `notifyAll` para que el
tablero espere cambios. Diseña la solución.

### E5 — El usuario que aparece en otra petición (revisar)

**Fuerza:** encontrar una fuga de `ThreadLocal` y el salto de hilo que lo rompe.

```java
public class FiltroUsuario implements Filter {
    static final ThreadLocal<PersonaId> USUARIO = new ThreadLocal<>();
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain cadena) throws IOException, ServletException {
        if (autenticado(req)) USUARIO.set(usuarioDe(req));
        cadena.doFilter(req, res);
    }
}

@Async
public void auditar(String evento) { auditoria.registrar(FiltroUsuario.USUARIO.get(), evento); }
```

Los registros de auditoría muestran a veces al usuario equivocado, y a veces `null`. Diagnostica las dos cosas y corrige.

---

## 4. 🧭 Las frases que hay que tener listas

> "Antes de un candado, pregunto si el estado puede ser inmutable o confinado; si no, monitor con `wait` en un `while` y
> `notifyAll`."

> "Cola acotada con una política al llenarse, y el límite lo pone el recurso escaso; en Java 21, un hilo virtual por tarea
> y un semáforo, nunca un pool de hilos virtuales."

> "El DCL sin `volatile` está roto porque otro hilo puede ver la referencia antes que el objeto; para un estático, holder;
> para una instancia, `volatile`."

---

**Anterior:** [`06` — Inicialización perezosa segura](06-inicializacion-perezosa-segura.md) ·
**Siguiente:** [`08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`03` — Producer-Consumer y Thread Pool](03-producer-consumer-y-thread-pool.md)
