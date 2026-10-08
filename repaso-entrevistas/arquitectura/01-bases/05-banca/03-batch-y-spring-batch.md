# 03 — Batch y Spring Batch

> El procesamiento por lotes que sostiene la banca y que más se pregunta en ese dominio: el modelo de
> `Job` y `Step`, el procesamiento por trozos, reinicio y reproceso, las estrategias de
> paralelización, y el diseño de un proceso que **se va a caer a la mitad**.
> Asume leído [`01` — Core bancario y legado](01-core-bancario-y-legado.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Hay que procesar 8 millones de movimientos entre las 23:00 y las 03:00. A las 01:40, con 5,2
millones procesados, el proceso falla por un registro con un formato inesperado.

Las preguntas que decide el diseño, y ninguna es opcional:

```text
¿Se reanuda desde el registro 5.200.001, o se vuelve a empezar?
¿Los 5,2 millones ya procesados quedaron aplicados, o se deshicieron?
¿Qué pasa con el registro malo: se salta, se aparta, o para todo?
¿Cabe reprocesar entero en el tiempo que queda hasta las 03:00?
```

Un proceso por lotes que no responde a las cuatro no está diseñado: está escrito.

> **Regla:** un proceso batch se diseña asumiendo que **se va a caer a la mitad**. Todo lo demás
> —rendimiento, paralelismo— viene después de resolver eso.

---

## 2. 🧱 El modelo de Spring Batch

**Qué es.** Un marco que estructura el procesamiento por lotes y, sobre todo, **persiste el estado de
la ejecución** para poder reanudar.

```text
Job                → la unidad de trabajo completa. Ej: "cierre diario".
 └ Step            → una fase. Ej: "leer fichero", "calcular intereses", "generar salida".
    └ Chunk        → lote de N elementos procesados y confirmados juntos.
       ItemReader  → lee de uno en uno (fichero, base de datos, cola)
       ItemProcessor → transforma o filtra. Devolver null DESCARTA el elemento.
       ItemWriter  → escribe de N en N. Aquí ocurre el commit.

JobRepository      → tablas donde Spring Batch guarda el estado de cada ejecución.
                     ES LA PIEZA CLAVE: sin ellas no hay reinicio posible.
```

- **El `JobRepository` es lo que distingue a Spring Batch de un bucle.** Guarda qué `Job` se ejecutó,
  con qué parámetros, en qué `Step` iba, cuántos elementos leyó y escribió, y en qué punto falló.
- **Los `JobParameters` identifican la ejecución.** Un `Job` con los mismos parámetros no se ejecuta
  dos veces: Spring Batch lo impide. De ahí que el parámetro típico sea la fecha de proceso — y que
  añadir un `run.id` aleatorio "para poder repetir" sea el atajo que rompe esa protección.

**Cuándo sí.** Volumen alto, ventana acotada, necesidad de reanudar, y requisito de trazabilidad de
la ejecución. Es exactamente el caso bancario.

**Cuándo no.** Un proceso de cinco minutos sobre mil registros: un `@Scheduled` con una consulta es
más simple y no necesita seis tablas de estado.

> **Veredicto:** Spring Batch no se elige por rendimiento, se elige por **reinicio, trazabilidad y
> control de errores**. Si no necesitas ninguna de las tres, es maquinaria de más.

---

## 3. 🔁 Procesamiento por trozos

**Qué es.** El modelo de ejecución: se leen N elementos, se procesan, y se escriben y confirman
juntos. N es el tamaño del trozo (*chunk size*).

```text
leer×N → procesar×N → escribir(N) → COMMIT → repetir
```

- **El commit es por trozo, no por elemento ni al final.** Eso da el punto de reanudación: si falla
  en el trozo 5.201, los 5.200 anteriores están confirmados.
- **El tamaño del trozo es el parámetro que más se ajusta**, y tiene dos fuerzas opuestas:

```text
Trozo grande  → menos commits, más rendimiento
              → más memoria, y más trabajo perdido al fallar
Trozo pequeño → menos pérdida al fallar, menos memoria
              → más commits, más sobrecarga transaccional
```

- Valores típicos: entre 100 y 1.000. Se calibra midiendo, no por intuición, y depende del tamaño
  del elemento y del coste de escritura.
- **`ItemProcessor` que devuelve `null` descarta el elemento**: es el mecanismo de filtrado, y
  Spring Batch lo cuenta aparte de los procesados. Confundir "filtrado" con "error" es un fallo
  frecuente en los informes de ejecución.

> ⚠️ **Advertencia.** El commit por trozo significa que **el trabajo ya confirmado no se deshace**.
> Si el `Job` falla a la mitad, la mitad de los intereses están aplicados. El proceso tiene que ser
> **reanudable o idempotente**, y decidir cuál es una decisión de diseño, no un detalle.

> **Veredicto:** el tamaño del trozo es el único parámetro que hay que calibrar midiendo, y el commit por
> trozo es lo que convierte un fallo a la mitad en una reanudación en vez de en un
> reproceso.

---
## 4. ♻️ Reinicio, salto y reintento

**Qué es.** Las tres políticas de error, que resuelven cosas distintas y se confunden.

```text
RETRY (reintento) → el elemento falló por algo TRANSITORIO. Se reintenta el mismo elemento.
                    Ej: deadlock, timeout de la base de datos.
SKIP (salto)      → el elemento falló por algo PERMANENTE. Se aparta y se sigue.
                    Ej: formato inválido, dato imposible. Con LÍMITE.
RESTART (reinicio)→ el JOB falló. Se relanza y reanuda desde el último trozo confirmado.
```

- Es la misma clasificación transitorio/permanente de
  [`02-eventos/04`](../02-eventos/04-colas-dlq-y-reintentos.md), aplicada al batch.
- **El `skip` necesita límite.** Un `skipLimit` alto convierte un fichero corrupto en una ejecución
  "correcta" que procesó el 3 % de los registros. El límite es lo que hace que el proceso falle
  cuando debe fallar.
- **Los elementos saltados hay que registrarlos.** Un `SkipListener` que los escriba a un fichero o
  a una tabla es obligatorio: si no, se pierden sin rastro y alguien los descubre al conciliar.
- **El reinicio solo funciona si el `ItemReader` es reanudable**, es decir, si sabe retomar desde
  donde iba. Los lectores de fichero y de base de datos lo son; un lector propio mal implementado, no.

> ⚠️ **Advertencia.** El error más caro: un reinicio que **vuelve a procesar lo ya aplicado** porque
> el lector no era reanudable o porque alguien relanzó el `Job` con parámetros distintos. En banca
> eso significa intereses aplicados dos veces.

> **Veredicto:** reintento, salto y reinicio responden a tres preguntas distintas —¿se arregla solo?,
> ¿es este registro?, ¿es la ejecución?— y un diseño que no las separa acaba saltándose errores
> transitorios y reintentando los permanentes.

---

## 5. ⚡ Paralelizar

**Qué es.** Las cuatro estrategias, de menos a más invasiva, y el criterio para elegir.

| Estrategia | Qué paraleliza | Cuándo |
|---|---|---|
| **Multi-hilo en un `Step`** | Los trozos, en varios hilos | Rápido de activar; **el lector debe ser seguro para hilos** |
| **`Step`s en paralelo** | Fases independientes entre sí | Cuando hay fases que no dependen unas de otras |
| **Particionado local** | El conjunto, en particiones con un `Step` por partición | La más usada: divide por rango, por sucursal, por hash |
| **Remote chunking / partitioning** | Entre varias JVM | Cuando una máquina no basta. Complejidad alta |

- **El particionado es el que más rinde y el más controlable**: un `Partitioner` divide el trabajo
  —por rango de identificador, por oficina, por tipo de producto— y cada partición se ejecuta como un
  `Step` independiente, con su propio reinicio.
- **El multi-hilo simple tiene una trampa**: muchos `ItemReader` no son seguros para hilos, y usarlos
  así produce registros saltados o duplicados **sin ningún error**. Es un fallo silencioso.
- **Lo que casi siempre limita no es la CPU**: es la base de datos —conexiones, contención de
  bloqueos— o el sistema de ficheros. Paralelizar contra una base de datos saturada empeora el
  tiempo total.

> 💡 **Truco.** Antes de paralelizar: medir dónde se va el tiempo. En procesos bancarios reales, la
> mayoría del tiempo suele estar en la escritura o en una consulta por elemento —un N+1 en versión
> batch— y arreglarla da más que cualquier paralelización.

> **Veredicto:** paralelizar es la última optimización, no la primera. Y el particionado es la
> estrategia por defecto porque conserva el reinicio por partición, que el multi-hilo complica.

---

## 6. 🏦 El batch bancario en concreto

**Qué es.** Lo que distingue a un proceso bancario de cualquier otro proceso por lotes.

```text
Ventana acotada       → hay una hora límite, y pasarse es un incidente de dirección
Orden de dependencias → el devengo antes que la liquidación, la liquidación antes que el extracto
Fecha de proceso      → el Job se ejecuta PARA una fecha contable, que puede no ser hoy
Reproceso de días     → si el cierre del día 3 estaba mal, hay que rehacer 3, 4 y 5 en orden
Cuadre obligatorio    → la suma de los movimientos procesados tiene que cuadrar con el control
Trazabilidad          → cuántos leyó, procesó, saltó y escribió cada ejecución, conservado años
```

- **La fecha de proceso como `JobParameter`** es lo que hace posible el reproceso: se relanza el
  `Job` con la fecha del día 3 y el proceso sabe qué periodo cubrir.
- **El cuadre no es una comprobación opcional**: un `Step` final que compara totales contra un
  registro de control, y que **falla el `Job`** si no cuadran. Sin él, un error silencioso pasa a
  producción contable.
- **El fichero de control** acompaña al de datos: número de registros y sumas de importes. Procesar
  el de datos sin validar contra el de control es aceptar cualquier truncamiento.

> ⚠️ **Advertencia.** El error más típico con la fecha: usar `LocalDate.now()` dentro del proceso en
> vez del parámetro de fecha de proceso. Funciona perfectamente hasta el primer reproceso, y entonces
> calcula todo con la fecha equivocada.

> **Veredicto:** un batch bancario sin cuadre y sin fecha de proceso parametrizada no es reprocesable,
> y un batch que no se puede reprocesar es un incidente esperando a un fallo de datos.

---

## 7. 🧭 Cómo se elige

```text
¿Necesito Spring Batch o basta un @Scheduled?
    ¿Volumen alto, ventana acotada, reinicio o trazabilidad? → Spring Batch
    ¿Mil registros en cinco minutos?                         → @Scheduled con una consulta

¿Cómo manejo los errores?
    Transitorio (deadlock, timeout)   → RETRY sobre el elemento
    Permanente (formato, dato inválido)→ SKIP con LÍMITE, y registrar cada saltado
    Fallo del Job                     → RESTART, y el lector debe ser reanudable

¿Tamaño de trozo?
    → Entre 100 y 1.000, calibrado midiendo. Grande = rápido y más pérdida al fallar.

¿Paralelizo?
    1º MIDE dónde se va el tiempo. Suele ser una consulta por elemento o la escritura.
    2º Si hace falta: particionado local. Conserva el reinicio por partición.
    3º Multi-hilo solo si el lector es seguro para hilos. Si no, produce fallos silenciosos.
    4º Remoto solo si una máquina no basta.

Y en banca, sin excepción:
    → fecha de proceso como parámetro (NUNCA now())
    → Step de cuadre que falle el Job si no cuadra
    → registro de saltados, y trazabilidad de la ejecución conservada
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Si falla, lo volvemos a lanzar" | ¿Reanuda o reprocesa? Si reprocesa, duplica lo ya aplicado |
| "Usamos `now()` para la fecha" | Rompe el reproceso: hay que usar el parámetro de fecha de proceso |
| "Subimos el `skipLimit` para que no falle" | Conviertes un fichero corrupto en una ejecución "correcta" |
| "Paralelizamos con multi-hilo" | Muchos lectores no son seguros para hilos: saltan o duplican en silencio |
| "El trozo grande es más rápido" | Y pierde más trabajo al fallar; se calibra midiendo |
| "Añadimos `run.id` para poder relanzar" | Anulas la protección contra ejecuciones duplicadas |
| "Procesamos el fichero que llegó" | Sin validar contra el fichero de control, aceptas truncamientos |

---

## 📚 Para profundizar

- **Libro** — Michael Minella, *The Definitive Guide to Spring Batch*, 2ª ed. (Apress, 2019).
  **Es el libro de Spring Batch** y no hay alternativa comparable: modelo, reinicio, particionado y
  escalado, escrito por quien mantuvo el proyecto.
- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns* (Addison-Wesley, 2003).
  Los patrones de *Splitter*, *Aggregator* y *Resequencer*, que son la versión de integración de lo
  que el batch hace en un solo proceso.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017). Capítulo
  10: procesamiento por lotes, con el argumento de por qué la inmutabilidad de la entrada es lo que
  hace reprocesable un proceso.
- [Spring Batch — Reference documentation](https://docs.spring.io/spring-batch/reference/index.html):
  el modelo de dominio, el `JobRepository` y los parámetros.
- [Spring Batch — Chunk-oriented processing](https://docs.spring.io/spring-batch/reference/step/chunk-oriented-processing.html):
  el ciclo leer-procesar-escribir y dónde ocurre el commit.
- [Spring Batch — Scaling and parallel processing](https://docs.spring.io/spring-batch/reference/scalability.html):
  las cuatro estrategias de paralelización con sus condiciones.
- [Spring Batch — Retry](https://docs.spring.io/spring-batch/reference/retry.html): reintento frente
  a salto, con las políticas configurables.
- [Spring Batch — Configuring and running a Job](https://docs.spring.io/spring-batch/reference/job.html):
  `JobParameters`, reinicio y por qué un `Job` no se ejecuta dos veces con los mismos parámetros.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué son `Job`, `Step` y chunk en Spring Batch? 🟢
2. ¿Qué hace el `JobRepository`? 🟢
3. ¿Qué diferencia hay entre retry, skip y restart? 🟢
4. Nombra las cuatro estrategias de paralelización. 🟢
5. ¿Qué es el fichero de control? 🟢
6. ¿Dónde ocurre el commit en el procesamiento por trozos? 🟡
7. ¿Qué pasa si un `ItemProcessor` devuelve `null`? 🟡
8. ¿Para qué sirven los `JobParameters`? 🟡
9. ¿Qué dos fuerzas opuestas determinan el tamaño del trozo? 🟡
10. ¿Qué requisito debe cumplir el `ItemReader` para que el reinicio funcione? 🟡
11. ¿Por qué hay que registrar los elementos saltados? 🟡
12. ¿Qué es un `Step` de cuadre y por qué es obligatorio en banca? 🟡
13. ¿Por qué un proceso batch se diseña asumiendo que se va a caer? 🟠
14. ¿Qué peligro tiene subir el `skipLimit`? 🟠
15. ¿Por qué usar `now()` en vez del parámetro de fecha rompe el reproceso? 🟠
16. ¿Qué trampa tiene paralelizar con multi-hilo? 🟠
17. ¿Por qué el particionado es la estrategia por defecto? 🟠
18. ¿Qué limita normalmente un batch, si no es la CPU? 🟠
19. ¿Qué problema crea añadir un `run.id` aleatorio a los parámetros? 🟠
20. ¿Qué hay que medir antes de paralelizar? 🟠
21. Diseña el proceso de devengo de intereses de 8 millones de cuentas en una
    ventana de 4 horas, sabiendo que puede fallar a la mitad. 🔴
22. El cierre del día 3 se ejecutó con un bug y hay que rehacer del 3 al 5.
    Describe el procedimiento y qué tuvo que estar diseñado de antemano. 🔴
23. Un batch que tardaba 2 horas ahora tarda 5 y no cabe en la ventana. Da tres
    hipótesis en orden y di cómo las confirmas. 🔴

---

**Anterior:** [`02` — MQ e integración asíncrona clásica](02-mq-e-integracion.md) ·
**Siguiente:** [`04` — Capa anticorrupción](04-capa-anticorrupcion.md) ·
**Relacionado:** [`08` — Idempotencia y conciliación](08-idempotencia-y-conciliacion.md)
