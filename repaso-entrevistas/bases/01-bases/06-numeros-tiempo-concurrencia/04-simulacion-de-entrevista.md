# 04 — Simulación de entrevista

> El examen del bloque. Treinta preguntas `S#` transversales que cruzan los tres capítulos, más
> cinco problemas de pizarra. Se contesta **en voz alta y cronometrado**.
> Asume leídos [`01`](01-numeros-precision-y-dinero.md) a
> [`03`](03-estructuras-y-concurrencia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Los problemas de pizarra se TECLEAN, en 20 minutos.
4. Solo después vas a `05-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** este bloque es el que más se parece a una revisión de código real. Casi ninguna
> pregunta tiene una respuesta algorítmica: tienen una **decisión de tipo** detrás, y equivocarse
> cuesta dinero, datos o disponibilidad.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Números y dinero

**S1.** ¿Cómo representas dinero y por qué? 🟢

**S2.** ¿Por qué `0.1 + 0.2` no es `0.3`? 🟢

**S3.** ¿Cuándo es correcto usar `double`? 🟡

**S4.** ¿Qué cuatro cosas tiene que incluir una respuesta completa sobre `BigDecimal`? 🟠

**S5.** ¿Por qué `HALF_UP` sesga un total, y quién decide el modo de redondeo? 🟠

**S6.** ¿Por qué un importe no debe viajar como número en un JSON? 🟠

**S7.** Dos sistemas difieren en un céntimo al facturar el mismo pedido. Diagnostica. 🔴

### Bloque B — Tiempo

**S8.** ¿Cuáles son los tres tipos de tiempo y cuándo se usa cada uno? 🟢

**S9.** ¿Por qué `LocalDateTime` no es una marca de tiempo? 🟡

**S10.** ¿Por qué "guardar todo en UTC" es una respuesta incompleta? 🟠

**S11.** ¿Por qué `Period.ofDays(1)` y `Duration.ofHours(24)` difieren? 🟠

**S12.** ¿Qué reloj usas para medir una duración y por qué? 🟡

**S13.** ¿Qué tiene de particular el `time.Time` de Go? 🟠

**S14.** Un proceso programado se ejecuta dos veces una noche al año. Explica y corrige. 🔴

### Bloque C — Concurrencia sobre estructuras

**S15.** ¿Qué significa exactamente que una estructura sea segura entre hilos? 🟡

**S16.** ¿Por qué `synchronizedMap` no evita perder incrementos? 🟠

**S17.** ¿Cuál es la secuencia de decisión ante "hazlo seguro entre hilos"? 🟠

**S18.** ¿Cuándo es correcto compartir un `HashMap` normal entre hilos? 🟠

**S19.** ¿Por qué una cola ilimitada convierte un pico de carga en una caída? 🟠

**S20.** ¿Por qué `CopyOnWriteArrayList` es excelente y terrible según el caso? 🟡

**S21.** ¿Qué cambian los virtual threads y qué no? 🟠

### Bloque D — Los cinco lenguajes

**S22.** ¿Qué lenguajes traen decimal exacto en su stdlib y qué hacen los demás? 🟡

**S23.** ¿Por qué en Go `0.1 + 0.2 == 0.3` puede ser `true`? 🟠

**S24.** ¿Por qué Python distingue *naive* de *aware* y qué opinas de esa decisión? 🟠

**S25.** ¿Por qué JavaScript no necesita estructuras concurrentes, y qué paga por ello? 🟠

**S26.** ¿Cuál es la filosofía de Go sobre estado compartido? 🟠

### Bloque E — Las que descolocan

**S27.** "En mi equipo usamos `double` para importes y nunca ha pasado nada." Responde. 🔴

**S28.** ¿Cuál es el bug más caro que has visto relacionado con tipos numéricos o fechas? 🔴

**S29.** Te piden migrar importes de `double` a `BigDecimal` en un sistema en producción con diez
años de datos. ¿Cómo lo planteas? 🔴

**S30.** ¿Por qué estos tres temas —números, tiempo y concurrencia— están en el mismo bloque? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleando y narrando. La solución completa está en [`05`](05-respuestas.md).

### P1 — El tipo `Money`

**Fuerza:** diseñar un tipo, no elegir una clase.

Diseña el tipo `Money` para un sistema multidivisa que cobra suscripciones con prorrateo por días.
Define qué operaciones permites, cuáles prohíbes, cómo se redondea y cómo se serializa hacia una API
pública consumida por un front en JavaScript.

Repregunta: *"¿y si hay que repartir 100 € entre 3 líneas?"*.

### P2 — La factura que no cuadra

**Fuerza:** diagnosticar sin ver el código.

El sistema de facturación y el libro contable difieren en 0,03 € en unas pocas facturas al mes,
siempre por debajo. Ambos parten de los mismos datos. Da tu plan de diagnóstico y las hipótesis en
orden de probabilidad.

Repregunta: *"¿y si la diferencia fuera siempre exactamente de un céntimo por línea?"*.

### P3 — Las citas de la clínica

**Fuerza:** elegir el tipo de tiempo según la semántica, no según la costumbre.

Una clínica con sedes en Madrid, Bogotá y Lisboa permite reservar citas con un año de antelación,
enviar recordatorios 24 horas antes y emitir un informe diario de ocupación por sede. Diseña el
almacenamiento y justifica cada tipo.

Repregunta: *"¿qué pasa si un gobierno cambia su norma de horario de verano?"*.

### P4 — El contador que pierde

**Fuerza:** distinguir "sincronizado" de "atómico".

Un servicio cuenta peticiones por endpoint en un mapa compartido por ocho hilos. El total no cuadra
con los logs. Escribe la versión correcta, explica por qué la sincronizada tampoco basta, y di qué
usarías si el contador tuviera contención muy alta.

Repregunta: *"¿y si además hay que exponer el conteo por HTTP en cualquier momento?"*.

### P5 — La configuración en caliente

**Fuerza:** que la mejor respuesta no usa ninguna estructura concurrente.

Un servicio lee un conjunto de reglas de negocio en cada petición —miles por segundo— y debe poder
recargarlas sin reiniciar y sin bloquear a los lectores. Diseña la solución.

Repregunta: *"¿qué garantiza tu solución si una petición está a medio ejecutarse durante la
recarga?"*.

---

## 4. 🧠 Las frases que hay que tener listas

> **Sobre dinero:** *"`BigDecimal` construido desde `String`, con escala y `RoundingMode`
> explícitos, comparado con `compareTo` y redondeado una sola vez al final. O enteros de la unidad
> mínima con la divisa dentro del tipo."*

> **Sobre tiempo:** *"Eventos en `Instant` y UTC; fechas de calendario en `LocalDate` sin huso; citas
> futuras como hora local más huso, porque las reglas de horario cambian. Y para medir duraciones, el
> reloj monótono."*

> **Sobre concurrencia:** *"Primero intento que sea inmutable. Si no puede, publicación segura y solo
> lectura. Si hay escrituras, estructura concurrente con la operación compuesta atómica —`merge`, no
> `get` más `put`—. El bloqueo a mano es el último escalón."*

---

**Anterior:** [`03` — Estructuras de datos y concurrencia](03-estructuras-y-concurrencia.md) ·
**Siguiente:** [`05` — Respuestas](05-respuestas.md) ·
**Relacionado:** [`05-dp-y-tecnicas/04` — Simulación final](../05-dp-y-tecnicas/04-simulacion-de-entrevista.md)
