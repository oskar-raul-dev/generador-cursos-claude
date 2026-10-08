# 02 — Tiempo, fechas y relojes

> Los tres tipos de tiempo que hay que distinguir antes de escribir nada, la hora que no existe y la
> que ocurre dos veces, por qué "más un día" y "más veinticuatro horas" dan resultados distintos, y
> el reloj monótono: el que mide duraciones y el que no.
> Asume leído [`01` — Números, precisión y dinero](01-numeros-precision-y-dinero.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un proceso nocturno programa recordatorios "24 horas antes de la cita". La última semana de octubre,
todos los recordatorios de España salen con una hora de desfase. Nadie tocó el código.

La causa está en una línea que parecía inofensiva, y se ve con los dos resultados reales sobre el
mismo instante de partida —24 de octubre de 2026, 12:00 en Madrid—:

```text
antes.plus(Period.ofDays(1))    → 2026-10-25T12:00+01:00    "el día siguiente a la misma hora"
antes.plus(Duration.ofHours(24)) → 2026-10-25T11:00+01:00    "veinticuatro horas después"
```

**Los dos son correctos y significan cosas distintas.** Esa noche España atrasa el reloj, así que el
día tiene 25 horas: un día natural y 24 horas dejaron de coincidir.

El tiempo es el dominio donde más bugs de backend nacen de suposiciones que parecen obvias: que un
día tiene 24 horas, que la hora local identifica un instante, que el reloj siempre avanza. Ninguna
es cierta.

> **Regla de entrevista:** antes de elegir un tipo de fecha, responde a dos preguntas: **¿esto es un
> instante en la línea del tiempo, o una fecha de calendario?** y **¿de quién es el huso: del
> usuario, del servidor o del negocio?**. Casi todos los bugs de este capítulo son una de las dos
> mal contestada.

---

## 2. 🧱 Los tres tipos de tiempo

**Qué es.** No hay "una fecha": hay tres conceptos distintos que `java.time` separa a propósito y
que otros lenguajes mezclan.

| Concepto | Qué representa | Tipo en Java | Ejemplo de uso |
|---|---|---|---|
| **Instante** | Un punto en la línea del tiempo, universal | `Instant` | Cuándo ocurrió un evento, marca de auditoría |
| **Local** | Una fecha u hora **sin** huso: no identifica un instante | `LocalDate`, `LocalDateTime` | Fecha de nacimiento, hora de apertura de una tienda |
| **Zonado** | Un local + un huso, que sí determina un instante | `ZonedDateTime` | Una cita concreta con un cliente en Madrid |

- **`LocalDateTime` no es un instante**, y es el error de tipado más frecuente: "2026-03-29 02:30" no
  identifica ningún momento hasta que dices dónde. Guardarlo como marca de un evento pierde
  información irrecuperable.
- **`Instant` no tiene fecha de calendario.** "¿Qué día fue?" no tiene respuesta sin un huso: el
  mismo instante puede ser lunes en Madrid y domingo en Los Ángeles.
- La regla práctica: **eventos en `Instant` (UTC), fechas de calendario en `LocalDate`**, y
  `ZonedDateTime` solo cuando el huso es parte del dato de negocio —una cita, un horario de apertura,
  un vencimiento legal—.

**Cuándo `LocalDate` es lo correcto:** una fecha de nacimiento no es un instante. Nace el 3 de marzo
en cualquier huso, y convertirla a UTC la desplaza un día para medio mundo. Es el segundo bug
clásico del capítulo.

> **Veredicto:** el tipo declara la semántica. Si usas `LocalDateTime` para todo, el compilador no
> puede ayudarte y los husos aparecen en producción; si usas `Instant` para una fecha de nacimiento,
> inventas una precisión que el dato no tiene.

---

## 3. 🧱 DST: la hora que no existe y la que ocurre dos veces

**El problema.** Dos veces al año, la correspondencia entre hora local e instante deja de ser una
función.

**El adelanto (marzo).** A las 2:00 el reloj salta a las 3:00, así que **las 2:30 no existen**. Java
lo resuelve desplazando hacia delante, verificado:

```text
LocalDateTime 2026-03-29 02:30 en Europe/Madrid
  → 2026-03-29T03:30+02:00[Europe/Madrid]      la hora pedida no existía
```

**El atraso (octubre).** A las 3:00 el reloj vuelve a las 2:00, así que **las 2:30 ocurren dos
veces**, con dos desplazamientos distintos:

```text
LocalDateTime 2026-10-25 02:30 en Europe/Madrid
  → 2026-10-25T02:30+02:00[Europe/Madrid]      la primera vez (por defecto)
  → 2026-10-25T02:30+01:00[Europe/Madrid]      la segunda (withLaterOffsetAtOverlap)
```

- **Java elige un valor por defecto y no falla**, lo cual es cómodo y peligroso: un proceso que corra
  en ese solapamiento puede ejecutarse dos veces, o saltarse una ejecución en el adelanto.
- Los procesos programados entre las 2:00 y las 3:00 son **el caso a evitar por diseño**. Programar a
  las 4:00 elimina el problema sin código.
- Si el solapamiento importa —facturación por horas, registros de turnos— hay que guardar el
  **desplazamiento** además de la hora local, o directamente el instante en UTC.

> ⚠️ **Advertencia.** La regla "guarda todo en UTC" es correcta para **eventos** y **falsa para citas
> futuras**. Si alguien reserva a las 10:00 del 30 de marzo del año que viene y el gobierno cambia la
> norma de horario de verano —cosa que pasa—, la cita guardada en UTC se desplaza. Las citas futuras
> se guardan como **hora local más huso**, y se convierten a instante en el momento de usarlas.

---

## 4. 🧱 Duración contra periodo

**Qué es.** Dos formas de medir tiempo que no son intercambiables:

```text
Duration  → tiempo físico exacto: segundos y nanosegundos. "24 horas"
Period    → tiempo de calendario: años, meses, días.        "1 día", "1 mes"
```

**Por qué importa**, con los dos resultados verificados del inicio del capítulo:

```java
ZonedDateTime antes = ZonedDateTime.of(2026, 10, 24, 12, 0, 0, 0, madrid);
antes.plus(Period.ofDays(1));      // → 2026-10-25T12:00+01:00   mismo reloj, 25 horas después
antes.plus(Duration.ofHours(24));  // → 2026-10-25T11:00+01:00   24 horas exactas
```

- **`Period` respeta el calendario**: "mañana a la misma hora", aunque ese día tenga 23 o 25 horas.
- **`Duration` respeta el reloj físico**: 24 horas son 86 400 segundos, pase lo que pase.
- La pregunta que decide: *"¿el usuario espera la misma hora del reloj, o exactamente ese tiempo
  después?"*. Un recordatorio "el día antes a las 10:00" es `Period`; un token que caduca en "24
  horas" es `Duration`.

**Y los meses son peor.** `Period.ofMonths(1)` sobre el 31 de enero da el 28 de febrero: la
aritmética de meses **no es reversible**, porque sumar un mes y restarlo puede no devolverte al
punto de partida. Es un comportamiento definido y sorprendente que conviene conocer antes de
construir un calendario de vencimientos.

---

## 5. 🧱 El reloj de pared y el monótono

**El problema.** Mides cuánto tarda una operación con la hora del sistema. El NTP ajusta el reloj
en medio. Tu medición sale **negativa**.

**Qué es.** Son dos relojes distintos:

```text
Reloj de pared (wall clock)   → "qué hora es". Puede saltar: NTP, cambio manual, DST
Reloj monótono                → "cuánto ha pasado". Solo avanza. Sin fecha ni significado absoluto
```

- **Para duraciones, siempre el monótono.** En Java es `System.nanoTime()`, que ya aparece en
  [`01-fundamentos/01`](../01-fundamentos/01-complejidad-y-o-grande.md#9--por-qué-el-cronómetro-te-contradice-en-la-jvm)
  como el que no vale para *medir rendimiento sin JMH*, pero sí es el correcto para medir tiempo
  transcurrido.
- **Para marcas de tiempo, el de pared.** `System.currentTimeMillis()` o `Instant.now()`. Su valor
  significa algo fuera del proceso; el del monótono no.
- Restar dos `currentTimeMillis` para medir una duración es el bug: si el reloj se ajusta hacia
  atrás, el resultado es negativo, y los tiempos de espera calculados así **nunca vencen**.

**Go lo resuelve en el tipo**, y es la diferencia más elegante de los cinco lenguajes. Su `time.Time`
lleva **las dos lecturas dentro**, verificado:

```text
time.Now()          → 2026-09-17 20:06:04.696779 -0500 -05 m=+0.000113626
                                                            ↑ la lectura monótona
t.Round(0)          → 2026-09-17 20:06:04.696779 -0500 -05   (la descarta)
```

- `time.Since(inicio)` usa automáticamente la parte monótona, así que **medir duraciones bien es el
  comportamiento por defecto**. En los otros cuatro lenguajes hay que saber elegir la función
  correcta.
- El detalle que muerde: serializar y deserializar un `time.Time` **pierde** la lectura monótona, así
  que una duración calculada a través de un canal o de una base de datos vuelve a usar el reloj de
  pared.

---

## 6. 🧱 El reloj inyectable

**El problema.** Un método usa `LocalDate.now()` y su test solo pasa ciertos días del mes. Es la
dependencia oculta de [`09-implementaciones/03` E3](../09-implementaciones/03-ejercicios-comparativos.md).

**La solución en Java** está en la plataforma desde Java 8 y casi nadie la usa:

```java
private final Clock reloj;                                    // inyectado por constructor

boolean estaVencida(Poliza poliza) {
    return poliza.fin().isBefore(LocalDate.now(reloj));        // now(reloj), no now()
}

// en el test:
Clock reloj = Clock.fixed(Instant.parse("2026-09-17T10:00:00Z"), ZoneOffset.UTC);
```

- **Todas las clases de `java.time` aceptan un `Clock`** en su `now()`. Es la API pensada
  exactamente para esto.
- `Clock.fixed`, `Clock.offset` y `Clock.tick` cubren los tres casos de test: congelar, desplazar y
  discretizar.
- El mismo principio se aplica a toda fuente de no determinismo: aleatoriedad, identificadores
  generados, red. Si necesitas una biblioteca de parcheo para probar algo, el diseño te lo está
  diciendo.

---

## 7. ⏱️ La tabla de costes

| Decisión | Coste | Lo que la tabla no dice |
|---|---|---|
| `Instant` frente a `ZonedDateTime` | Igual | El zonado arrastra las reglas del huso: más memoria y serialización más larga |
| Guardar en UTC | Ninguno | **Correcto para eventos, incorrecto para citas futuras** |
| Conversión de huso | Búsqueda en la base de datos de husos | Las reglas cambian: la tzdata del sistema debe estar actualizada |
| `System.nanoTime` | ~20–25 ns | No tiene significado absoluto: solo sirve para diferencias |
| `Instant.now()` | Similar, con acceso al reloj | En bucles muy calientes, cachear el instante por lote |
| Formateo/parseo | Caro comparado con el resto | `DateTimeFormatter` es inmutable y seguro entre hilos: se reutiliza |

---

## 8. ⚖️ Los cinco lenguajes

| Lenguaje | API | Monótono | El detalle que muerde |
|---|---|---|---|
| **Java** | `java.time` (JSR-310) | `System.nanoTime()` aparte | La mejor API de los cinco. `Date` y `Calendar` son legado y no deben usarse |
| **Python** | `datetime` + `zoneinfo` (3.9+) | `time.monotonic()` aparte | **naive vs aware**: comparar los dos lanza `TypeError`. `utcnow()` devuelve un naive y está desaconsejado |
| **JavaScript** | `Date` —mutable, meses desde 0— e `Intl` | `performance.now()` | `Date` es célebre por su mal diseño. **Temporal** es la propuesta que lo sustituye |
| **TypeScript** | Igual que JS | Igual | Puede tipar el huso como parte del tipo, pero no valida nada en runtime |
| **Go** | `time` | **Dentro del propio `time.Time`** | El único donde medir duraciones bien es el comportamiento por defecto |

Las dos comparaciones que valen como respuesta:

- **Python distingue *naive* de *aware*** y lo hace cumplir: comparar un `datetime` sin huso con uno
  con huso lanza `TypeError: can't compare offset-naive and offset-aware datetimes`, verificado. Es
  incómodo y evita el bug silencioso que otros lenguajes permiten. La trampa es `datetime.utcnow()`,
  que devuelve un **naive** pese al nombre, y por eso está desaconsejado en favor de
  `datetime.now(timezone.utc)`.
- **`Date` de JavaScript es el peor diseño de los cinco**: mutable, con los meses empezando en 0, sin
  soporte real de husos y con un parseo dependiente de la implementación. La propuesta **Temporal**
  —ya disponible en algunos motores— separa instante, fecha local y zonado igual que `java.time`, que
  es la confirmación de que ese modelo es el correcto.

---

## 9. 🧭 Cómo se elige

```text
¿Un evento que ocurrió?                      → Instant, almacenado en UTC
¿Una fecha de calendario (nacimiento, factura)? → LocalDate. NO la conviertas a UTC
¿Una cita futura con un usuario?             → hora local + huso, no instante en UTC
¿Un horario de apertura recurrente?          → LocalTime + huso del negocio
¿Medir cuánto tarda algo?                    → reloj monótono, nunca el de pared
¿"Un día después" o "24 horas después"?      → Period o Duration: pregunta cuál quiere el usuario
¿Un proceso programado?                      → evita la franja 2:00–3:00; programa a las 4:00
¿Testeable?                                  → Clock inyectado, nunca now() directo
```

> **Regla de entrevista:** "lo guardo todo en UTC" suena a buena práctica y es una respuesta
> incompleta. La completa distingue **eventos pasados** —UTC, sin duda— de **fechas de calendario**
> —sin huso— y de **citas futuras** —hora local más huso—. Nombrar las tres categorías es lo que
> demuestra que has sufrido el problema.

---

## 10. 🔭 Dónde aparece de verdad

En el informe diario que cuenta mal los pedidos porque el "día" del servidor no es el del usuario; en
los procesos programados que se ejecutan dos veces o ninguna la noche del cambio de hora; en los
tiempos de espera calculados con el reloj de pared que no vencen nunca tras un ajuste de NTP; en las
fechas de nacimiento desplazadas un día para los usuarios al este de Greenwich; en los tokens que
caducan antes de tiempo porque el reloj del servidor va adelantado —y de ahí el margen de tolerancia
de los JWT—; y en las columnas `TIMESTAMP` sin huso, que es la misma decisión de tipo trasladada al
esquema.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Lo guardo todo en UTC" | Correcto para eventos; **incorrecto para citas futuras** y para fechas de calendario |
| "`LocalDateTime` es una marca de tiempo" | No identifica un instante hasta que le pones huso |
| "Un día son 24 horas" | No en los cambios de horario: `Period` y `Duration` dan resultados distintos |
| "Mido la duración con `currentTimeMillis`" | El reloj de pared salta. Para duraciones, el monótono |
| "Guardo la fecha de nacimiento como `Instant`" | Es `LocalDate`: convertirla la desplaza un día para medio mundo |
| "`datetime.utcnow()` me da un UTC" | Devuelve un **naive** sin huso. Usa `datetime.now(timezone.utc)` |
| "La hora local siempre existe" | A las 2:30 del cambio de marzo no existe, y a las 2:30 de octubre ocurre dos veces |

---

## 📚 Para profundizar

- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítem 17, sobre inmutabilidad,
  que es la decisión de diseño que hace segura toda la API de `java.time`.
- **Libro** — Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017). Capítulo 8,
  sección "Unreliable Clocks": relojes monótonos, sincronización y por qué no se puede confiar en el
  reloj para ordenar eventos entre máquinas. **Si solo lees una cosa de este capítulo, esta.**
- [Java 21 API — `java.time`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/package-summary.html):
  el resumen del paquete explica la separación entre instante, local y zonado mejor que ningún
  tutorial.
- [Java 21 API — `Clock`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/Clock.html):
  `fixed`, `offset` y `tick`, y la recomendación explícita de inyectarlo.
- [Python — `datetime`](https://docs.python.org/3/library/datetime.html): la distinción entre
  *naive* y *aware*, con la advertencia sobre `utcnow()`.
- [Python — `zoneinfo`](https://docs.python.org/3/library/zoneinfo.html): el acceso a la base de
  datos de husos del sistema, incorporado en 3.9.
- [Go — `time`](https://pkg.go.dev/time): la sección **Monotonic Clocks** documenta que `time.Time`
  lleva las dos lecturas dentro, cuándo se descarta la monótona y por qué `Since` es lo correcto.
- [IANA Time Zone Database](https://www.iana.org/time-zones): la fuente de las reglas de huso, que
  **cambia varias veces al año** y hay que mantener actualizada.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Cuáles son los tres tipos de tiempo y qué representa cada uno? 🟢
2. ¿Por qué `LocalDateTime` no identifica un instante? 🟢
3. ¿Qué tipo usarías para una fecha de nacimiento? 🟢
4. ¿Qué diferencia hay entre el reloj de pared y el monótono? 🟢
5. ¿Qué pasa con las 2:30 la noche del adelanto de hora? 🟢
6. ¿Qué es un `Clock` inyectable y para qué sirve? 🟢
7. ¿Por qué `Period.ofDays(1)` y `Duration.ofHours(24)` dan resultados distintos? 🟡
8. ¿Por qué no se mide una duración con `System.currentTimeMillis()`? 🟡
9. ¿Qué ocurre con las 2:30 la noche del atraso, y cómo se distinguen las dos? 🟡
10. ¿Por qué `datetime.utcnow()` está desaconsejado en Python? 🟡
11. ¿Qué tiene de especial el `time.Time` de Go? 🟡
12. ¿Por qué `Period.ofMonths(1)` no es reversible? 🟡
13. ¿Por qué guardar una fecha de nacimiento en UTC es un error? 🟠
14. ¿Por qué "guarda todo en UTC" es incompleto para una cita del año que viene? 🟠
15. ¿Por qué un proceso programado a las 2:30 puede ejecutarse dos veces o ninguna? 🟠
16. ¿Qué se pierde al serializar un `time.Time` de Go? 🟠
17. ¿Por qué la base de datos de husos hay que mantenerla actualizada? 🟠
18. ¿Qué problema resuelve el margen de tolerancia en la validación de un JWT? 🟠
19. ¿Por qué comparar un `datetime` naive con uno aware lanza una excepción en Python, y qué opinas
    de esa decisión? 🟠
20. Un informe diario cuenta mal los pedidos del último día del mes. Da tres hipótesis. 🔴
21. Diseña el almacenamiento de citas médicas reservables con un año de antelación, para una
    clínica con sedes en tres países. 🔴
22. Los tiempos de espera de un servicio dejan de vencer tras un ajuste de NTP. Explica el
    mecanismo y la corrección. 🔴

---

**Anterior:** [`01` — Números, precisión y dinero](01-numeros-precision-y-dinero.md) ·
**Siguiente:** [`03` — Estructuras de datos y concurrencia](03-estructuras-y-concurrencia.md) ·
**Relacionado:** [`03-orden-busqueda/05` — Intervalos y barrido](../03-orden-busqueda/05-intervalos-y-barrido.md)
