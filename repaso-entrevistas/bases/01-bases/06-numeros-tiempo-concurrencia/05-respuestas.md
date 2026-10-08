# 05 — Respuestas

> Solucionario centralizado del bloque `06-numeros-tiempo-concurrencia`. Cada respuesta en tres
> capas: **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--números-precisión-y-dinero) · [02](#02--tiempo-fechas-y-relojes) ·
[03](#03--estructuras-de-datos-y-concurrencia) ·
[04 — transversales](#04--simulación-preguntas-transversales) ·
[04 — pizarra](#04--simulación-problemas-de-pizarra)

---

# 01 — Números, precisión y dinero

**01 → 1. ¿Por qué `0.1 + 0.2` no es `0.3`?**

⏱️ Porque `0.1` no existe en binario: es periódico, como `1/3` en decimal.
🗣️ El `double` sigue IEEE 754 y solo representa exactamente fracciones con denominador potencia de
dos. Guarda la más cercana a `0.1`, y al sumar, el error aparece: `0.30000000000000004`.
🔬 Con 20 decimales se ve entero: `0.30000000000000004441`. El error relativo es de unos 10⁻¹⁶ por
operación, insignificante una vez y **acumulativo** sobre millones de sumas. Además la suma en coma
flotante **no es asociativa**: cambiar el orden cambia el resultado.

**01 → 2. ¿Qué tipo usarías para representar dinero en Java?**

⏱️ `BigDecimal` construido desde `String`, o un `long` con la unidad mínima de la divisa.
🗣️ `BigDecimal` es exacto en decimal y permite escala y redondeo explícitos; el entero de céntimos es
más rápido y compacto, y es lo que usan las pasarelas de pago en sus APIs. Ambos son defendibles.
🔬 La respuesta completa añade que el tipo lleva **la divisa dentro** —`record Money(long centimos,
Currency divisa)`— para que sumar euros con dólares no compile o falle, en vez de dar un número sin
sentido.

**01 → 3. ¿Qué diferencia hay entre `new BigDecimal(0.1)` y `BigDecimal.valueOf(0.1)`?**

⏱️ El constructor representa fielmente el `double`, basura incluida;
`valueOf` pasa por `Double.toString` y da `0.1`.

```text
new BigDecimal(0.1)     → 0.1000000000000000055511151231257827021181583404541015625
BigDecimal.valueOf(0.1) → 0.1
```

🗣️ El constructor es técnicamente correcto: el `double` que recibe **ya** perdió precisión, y él lo
refleja. El problema es que casi nadie espera eso.
🔬 La regla es construir siempre desde `String` o con `valueOf`, y está en la propia documentación de
la clase. Es la regla número uno del tipo y la que más se incumple.

**01 → 4. ¿Qué es el redondeo `HALF_EVEN` y por qué se llama bancario?**

⏱️ Desempata hacia el **par más cercano**, lo que reparte los empates arriba y abajo y elimina el
sesgo.

```text
 2.5 → HALF_UP 3 | HALF_EVEN 2
 3.5 → HALF_UP 4 | HALF_EVEN 4
-2.5 → HALF_UP -3 | HALF_EVEN -2
```

🗣️ Con `HALF_UP`, todos los empates suben, así que sobre millones de importes el total queda
sistemáticamente por encima. `HALF_EVEN` hace que el sesgo tienda a cero, y por eso lo exigen muchas
normativas contables.
🔬 Es además el modo por defecto de IEEE 754. Cuál usar **no lo decide el programador**: lo decide la
norma o el contrato, y preguntarlo es parte de la respuesta correcta.

**01 → 5. ¿Qué lenguajes de los cinco traen un decimal exacto en la stdlib?**

⏱️ Solo **Java** (`BigDecimal`) y **Python** (`decimal.Decimal`).
🗣️ JavaScript y TypeScript no tienen ninguno —hay que usar `decimal.js` o enteros—, y Go tampoco:
`shopspring/decimal` es el estándar de facto pero es una dependencia externa.
🔬 Es un dato de arquitectura, no de trivia: si el front calcula importes, va a hacerlo con `double`
salvo que alguien lo impida. Por eso los importes viajan como enteros de unidad mínima o como string
en las APIs serias.

**01 → 6. ¿Por qué no se comparan dos `double` con `==`?**

⏱️ Porque dos cálculos matemáticamente equivalentes pueden dar bits distintos.
🗣️ `0.1 + 0.2 == 0.3` es `false`. Se compara con una tolerancia: `Math.abs(a - b) < epsilon`, y el
epsilon depende de la magnitud de los valores, no es una constante universal.
🔬 Y esa comparación con tolerancia **no es transitiva**, que es exactamente el comparador roto de
[`03-orden-busqueda/02`](../03-orden-busqueda/02-comparadores-y-orden-total.md): si a≈b y b≈c, puede
que a≉c. Los dos problemas son el mismo, y por eso la solución también: discretizar antes de
comparar.

**01 → 7. ¿Por qué `new BigDecimal("1.0").equals(new BigDecimal("1.00"))` es `false`?**

⏱️ Porque `equals` compara valor **y escala**, y las escalas son 1 y 2.
🗣️ `compareTo` devuelve 0 porque el valor numérico es el mismo. La escala es información
significativa —dice con cuánta precisión se midió o se acordó el importe— y por eso `equals` la tiene
en cuenta.
🔬 La consecuencia práctica, ya vista en `03-orden-busqueda/02`: un `HashSet` ve dos elementos y un
`TreeSet` ve uno. Para comparar importes, **siempre `compareTo`**; para deduplicar, normalizar la
escala con `setScale` primero.

**01 → 8. ¿Cuándo es correcto usar `double`?**

⏱️ Con magnitudes medidas: pesos, distancias, porcentajes, coordenadas, latencias, promedios.
🗣️ Todo lo que ya viene de una medición con error mucho mayor que 10⁻¹⁶. Ahí la precisión del
`double` sobra y su velocidad importa.
🔬 Y donde es directamente obligatorio: bucles numéricos de millones de iteraciones, cálculo
científico, gráficos. `BigDecimal` ahí no cabe por rendimiento. La frontera es **si el número tiene
que cuadrar con otro sistema**.

**01 → 9. ¿Qué representa la escala de un `BigDecimal`?**

⏱️ Cuántos dígitos hay tras la coma. El valor es un entero sin límite dividido por 10^escala.
🗣️ `1.00` es el entero 100 con escala 2. Por eso el tipo es exacto en decimal: no hay base dos por
ningún lado.
🔬 La escala hay que **fijarla explícitamente** con `setScale(n, RoundingMode.X)`, sobre todo tras
dividir: una división sin escala ni modo de redondeo lanza `ArithmeticException` si el resultado es
periódico —`1/3`—, y ese fallo en producción sorprende a mucha gente.

**01 → 10. ¿Por qué la suma en coma flotante no es asociativa, y qué consecuencia tiene?**

⏱️ Porque cada suma redondea, y redondear en distinto orden da resultados distintos.
🗣️ `(a + b) + c` puede no ser `a + (b + c)`: si `a` es enorme y `b` y `c` diminutos, sumarlos primero
entre sí conserva su aportación, y sumarlos al grande uno a uno puede perderla del todo.
🔬 La consecuencia práctica: **paralelizar una suma cambia el resultado**, porque el orden de
combinación deja de estar definido. Un total calculado con `stream().sum()` y otro con
`parallelStream().sum()` pueden diferir, y eso desconcierta hasta que se conoce la causa. Para sumas
grandes con precisión existe la compensación de Kahan.

**01 → 11. ¿Por qué `HALF_UP` sesga un total al alza?**

⏱️ Porque todos los empates —los `.5`— suben, y ninguno baja.
🗣️ Con datos aleatorios, la mitad de los empates deberían ir en cada dirección para que el error se
cancele. Con `HALF_UP` todos van hacia arriba, así que el sesgo se acumula linealmente con el número
de redondeos.
🔬 Sobre un millón de importes con empates frecuentes —precios terminados en `.005`, por ejemplo— la
diferencia es material. `HALF_EVEN` reparte los empates según la paridad del dígito anterior, que
sobre datos reales se comporta como un reparto al 50 %.

**01 → 12. ¿Qué cuesta `BigDecimal` frente a `double` y cuándo importa ese coste?**

⏱️ Entre 10 y 100 veces más lento y mucha más memoria. Importa en bucles numéricos, no en lógica de
negocio.
🗣️ Es un objeto con un `BigInteger` dentro: cada operación asigna memoria y no cabe en un registro.
En una petición que hace unos cientos de operaciones monetarias, el coste es invisible frente a una
sola consulta a base de datos.
🔬 Donde sí importa: cálculo de riesgo, simulaciones Monte Carlo, agregaciones sobre millones de
filas. Ahí el patrón habitual es calcular en `double` o en `long` y convertir a `BigDecimal` solo el
resultado final que se presenta o se persiste.

**01 → 13. ¿Por qué en Go `0.1 + 0.2 == 0.3` puede ser `true`?**

⏱️ Porque con **constantes sin tipo**, Go evalúa la expresión en compilación con precisión arbitraria.

```go
0.1 + 0.2 == 0.3                  // true  — constantes, matemática exacta
a, b, c := 0.1, 0.2, 0.3
a + b == c                        // false — float64, IEEE 754 como todos
```

🗣️ Las constantes de Go son matemáticas hasta que se asignan a un tipo: el compilador las maneja con
al menos 256 bits de precisión. En cuanto hay variables `float64`, el comportamiento es el estándar.
🔬 **Es una trampa perfecta para un test**: escrito con literales pasa, y con datos reales falla. Es
también un buen ejemplo de una decisión de diseño que elimina sorpresas en expresiones constantes a
costa de introducir una asimetría entre constantes y variables.

**01 → 14. ¿Por qué el constructor `BigDecimal(double)` es un error casi siempre?**

Cubierta por **01 → 3**.

**01 → 15. ¿Por qué "céntimos = importe × 100" está mal en un sistema multidivisa?**

⏱️ Porque no todas las divisas tienen dos decimales: el yen tiene cero y el dinar kuwaití tres.
🗣️ Con un factor fijo de 100, un importe en yenes se multiplica por 100 sin motivo y uno en dinares
pierde un decimal. El factor sale de la divisa:
`Currency.getInstance("KWD").getDefaultFractionDigits()` devuelve 3.
🔬 Y hay un segundo motivo para que la divisa viva dentro del tipo: **sumar importes de divisas
distintas tiene que ser imposible**, no dar un número sin sentido. Un `Money` que no lo impide es un
`long` con nombre bonito.

**01 → 16. ¿Dónde se redondea en una factura: en cada línea o al final? Justifica.**

⏱️ Depende de la norma fiscal, y por eso **hay que preguntarlo**: no es una decisión técnica.
🗣️ Redondear por línea y sumar da un total distinto que sumar con todos los decimales y redondear una
vez. Ambos son defendibles y las normativas difieren; en muchas jurisdicciones el IVA se calcula y
redondea por línea precisamente para que el detalle cuadre con el total.
🔬 Lo que **no** es negociable es que esté **documentado y sea el mismo en todos los sistemas**: el
descuadre clásico entre facturación y contabilidad es que uno redondea por línea y el otro al final.
La regla de ingeniería: calcular con más decimales de los que se muestran, redondear en los puntos
acordados, y escribir esos puntos en la especificación.

**01 → 17. ¿Por qué un importe no debería viajar como número en un JSON hacia JavaScript?**

⏱️ Porque JSON no distingue entero de decimal y JavaScript lo lee como `double`: pierde precisión.
🗣️ Un importe con muchos decimales, o un entero de céntimos grande, se redondea al `double` más
cercano sin ningún error. El front muestra un número ligeramente distinto al que envió el backend.
🔬 Es el mismo mecanismo que corrompe los identificadores `bigint` de
[`01-fundamentos/05`](../01-fundamentos/05-bits-y-aritmetica-binaria.md). Las dos soluciones
estándar: **entero de la unidad mínima** —que cabe exacto hasta 2⁵³, suficiente para cualquier
importe realista— o **string**, que es lo que hacen las APIs financieras serias.

**01 → 18. ¿Qué relación hay entre comparar `double` con tolerancia y el comparador roto de `03-orden-busqueda/02`?**

⏱️ Son el mismo problema: una relación "aproximadamente igual" **no es transitiva**.
🗣️ Si `|a-b| < ε` y `|b-c| < ε`, nada garantiza `|a-c| < ε`. Usada como igualdad es incómoda; usada
dentro de un `Comparator` **rompe el orden total** y Java lanza
`Comparison method violates its general contract!`.
🔬 Y la corrección también es la misma: **discretizar antes de comparar**. Redondear los valores a la
precisión relevante convierte la tolerancia en una clave exacta, y la relación vuelve a ser
transitiva. Ver esa conexión entre dos capítulos de bloques distintos es exactamente lo que el corpus
busca.

**01 → 19. ¿Por qué el tipo `Money` lleva la divisa dentro en vez de ser un número?**

⏱️ Para que sumar euros con dólares sea imposible o falle, en vez de producir un número sin
significado.
🗣️ Es el patrón **Money** de Fowler: el importe sin divisa no es un dato completo, igual que una
distancia sin unidad. El tipo encapsula el valor, la divisa y las operaciones válidas, y rechaza las
que no lo son.
🔬 Las operaciones que permite son asimétricas y conviene saberlas: sumar y restar **solo entre la
misma divisa**; multiplicar por un escalar sí —tres unidades de 10 €—; multiplicar `Money` por
`Money` **no tiene sentido**; y dividir plantea el problema del reparto de la pregunta 21. Definir
esa lista es la mitad del diseño del tipo.

**01 → 20. Dos sistemas facturan el mismo pedido y difieren en un céntimo. Da tres hipótesis en orden de probabilidad.**

⏱️ Redondean en puntos distintos; usan modos de redondeo distintos; o uno usa `double` y el otro
decimal exacto.
🗣️ La primera es la más frecuente con diferencia: uno redondea por línea y suma, el otro suma con
todos los decimales y redondea al final. Produce diferencias de céntimos **solo en algunos pedidos**,
que es justo el síntoma. La segunda —`HALF_UP` contra `HALF_EVEN`— produce diferencias solo cuando
hay empates exactos, y siempre en la misma dirección. La tercera aparece de forma errática y con
importes grandes.
🔬 Cómo se distinguen sin leer los dos códigos: **reproducir un pedido concreto con los dos sistemas y
comparar los importes intermedios, línea a línea**. Si el primer punto de divergencia es el subtotal
de una línea, es redondeo por línea; si las líneas cuadran y el total no, es el punto de redondeo
final; si la diferencia aparece y desaparece según los valores, es coma flotante. La corrección de
fondo no es técnica: es acordar y **documentar** la regla, y después hacerla cumplir en los dos.

**01 → 21. Diseña el tipo `Money` para un sistema multidivisa con prorrateos, y di qué operaciones permites y cuáles prohíbes.**

⏱️ Un valor inmutable con importe en unidad mínima y divisa, con operaciones cerradas y un reparto
explícito.

```java
record Money(long unidadesMinimas, Currency divisa) {
    Money mas(Money otro)      { exigirMismaDivisa(otro); return new Money(Math.addExact(...), divisa); }
    Money por(int factor)      { return new Money(Math.multiplyExact(unidadesMinimas, factor), divisa); }
    List<Money> repartir(int n) { ... }   // reparto sin perder céntimos: ver abajo
}
```

🗣️ **Permitidas**: sumar y restar entre la misma divisa; multiplicar por un escalar entero o por un
`BigDecimal` con redondeo explícito; comparar; repartir. **Prohibidas**: sumar divisas distintas
—lanza excepción—, multiplicar `Money` por `Money`, y construir desde `double`. El uso de
`Math.addExact` cierra además el desbordamiento de
[`01-fundamentos/05`](../01-fundamentos/05-bits-y-aritmetica-binaria.md).
🔬 **El prorrateo es el problema real**, y es la repregunta del problema P1: repartir 100 € entre 3
da 33,33 € tres veces y **sobra un céntimo**. Tirarlo es un descuadre contable. La solución estándar
es repartir la división entera y distribuir el resto **de uno en uno** entre las primeras partes, de
forma determinista y documentada: `[33,34 €, 33,33 €, 33,33 €]`. La suma vuelve a ser exactamente
100 €, y quién se lleva el céntimo extra es una decisión de negocio que hay que fijar, no dejar al
azar del algoritmo. Y el factor de la unidad mínima sale de `divisa.getDefaultFractionDigits()`,
nunca de un 100 fijo.

**01 → 22. Un proceso suma un millón de importes y el total difiere del esperado en varios euros. Explica el mecanismo y da la corrección.**

⏱️ Error de coma flotante acumulado: cada suma redondea, y un millón de redondeos se notan.
🗣️ Con `double`, el error relativo es de ~10⁻¹⁶ por operación, pero **crece con el número de
operaciones y con la disparidad de magnitudes**: sumar importes pequeños a un acumulado cada vez más
grande hace que las aportaciones pequeñas se pierdan por completo en el redondeo. Con un millón de
líneas y un total de millones, varios euros de desviación son perfectamente esperables.
🔬 Las correcciones, en orden. **La correcta**: usar `long` de céntimos o `BigDecimal`, con lo que el
problema desaparece en vez de mitigarse. **Si hay que seguir en `double`** por rendimiento: la
compensación de Kahan, que lleva un término de corrección y reduce el error en órdenes de magnitud; o
sumar en orden de magnitud creciente, que reduce la pérdida de las aportaciones pequeñas. Y el detalle
que cierra la respuesta: **si el proceso se paraleliza, el resultado cambia** entre ejecuciones,
porque el orden de combinación deja de estar definido —pregunta 10—, y eso convierte un error
sistemático en uno irreproducible, que es mucho peor de diagnosticar.

---

# 02 — Tiempo, fechas y relojes

**02 → 1. ¿Cuáles son los tres tipos de tiempo y qué representa cada uno?**

⏱️ Instante —un punto universal en la línea del tiempo—, local —fecha u hora sin huso— y zonado
—local más huso, que sí determina un instante—.
🗣️ En Java: `Instant`, `LocalDate`/`LocalDateTime` y `ZonedDateTime`. La regla práctica es eventos en
`Instant` y UTC, fechas de calendario en `LocalDate`, y zonado solo cuando el huso es parte del dato
de negocio.
🔬 `java.time` los separa a propósito, y esa separación es la razón de que sea la mejor API de fechas
de los cinco lenguajes. La propuesta **Temporal** de JavaScript reproduce el mismo modelo, que es la
confirmación de que es el correcto.

**02 → 2. ¿Por qué `LocalDateTime` no identifica un instante?**

⏱️ Porque no lleva huso: "2026-03-29 02:30" ocurre en momentos distintos en Madrid y en Bogotá, y hay
días en que no ocurre en absoluto.
🗣️ Guardarlo como marca de un evento pierde información **irrecuperable**: después no hay forma de
saber a qué momento real se refería. Es el error de tipado más frecuente del capítulo.
🔬 El caso extremo lo demuestra: `2026-03-29 02:30` en Madrid **no existe**, porque esa noche el reloj
salta de las 2:00 a las 3:00. Un tipo que puede representar un momento inexistente no puede ser una
marca de tiempo.

**02 → 3. ¿Qué tipo usarías para una fecha de nacimiento?**

⏱️ `LocalDate`. No es un instante y no tiene huso.
🗣️ Alguien nacido el 3 de marzo lo es en cualquier parte del mundo. Convertirlo a `Instant` obliga a
inventar una hora y un huso, y al mostrarlo en otro huso **se desplaza un día** para una parte del
planeta.
🔬 Es el segundo bug clásico del capítulo y aparece en cualquier sistema con usuarios
internacionales: cumpleaños que se celebran un día antes, mayorías de edad que se alcanzan un día
tarde, y validaciones que fallan en la frontera. El mismo razonamiento vale para la fecha de una
factura o de un vencimiento.

**02 → 4. ¿Qué diferencia hay entre el reloj de pared y el monótono?**

⏱️ El de pared dice **qué hora es** y puede saltar; el monótono dice **cuánto ha pasado** y solo
avanza.
🗣️ El de pared lo ajustan el NTP, el cambio de horario y el administrador. El monótono no tiene
significado absoluto —su valor solo sirve para restarlo de otro— y por eso nunca retrocede.
🔬 En Java: `System.currentTimeMillis()` e `Instant.now()` son de pared; `System.nanoTime()` es
monótono. Para medir duraciones, siempre el segundo; para marcas de tiempo, siempre el primero.
Confundirlos produce duraciones negativas y tiempos de espera que no vencen.

**02 → 5. ¿Qué pasa con las 2:30 la noche del adelanto de hora?**

⏱️ **No existen**: el reloj salta de las 2:00 a las 3:00.
🗣️ Java resuelve la ambigüedad desplazando hacia delante, verificado: `LocalDateTime 2026-03-29
02:30` en `Europe/Madrid` se convierte en `2026-03-29T03:30+02:00`. No lanza excepción.
🔬 Que no falle es cómodo y peligroso: un proceso programado a las 2:30 **no se ejecuta** esa noche, o
se ejecuta a otra hora, según el planificador. La solución de diseño es no programar nada entre las
2:00 y las 3:00.

**02 → 6. ¿Qué es un `Clock` inyectable y para qué sirve?**

⏱️ Una abstracción del reloj que se pasa por constructor, para que el test pueda congelar el tiempo.
🗣️ Todas las clases de `java.time` aceptan un `Clock` en su `now()`. En producción se inyecta
`Clock.systemUTC()`; en test, `Clock.fixed(...)`, y el código deja de depender del calendario.
🔬 `Clock.fixed` congela, `Clock.offset` desplaza y `Clock.tick` discretiza. El principio general es
el de `09-implementaciones/03` E3: **toda fuente de no determinismo va detrás de una abstracción
inyectable**. Si necesitas parchear para probar, el diseño te lo está diciendo.

**02 → 7. ¿Por qué `Period.ofDays(1)` y `Duration.ofHours(24)` dan resultados distintos?**

⏱️ Porque un día natural no siempre tiene 24 horas. Verificado sobre el 24 de octubre de 2026 en
Madrid:

```text
antes.plus(Period.ofDays(1))     → 2026-10-25T12:00+01:00   misma hora del reloj (25 h reales)
antes.plus(Duration.ofHours(24)) → 2026-10-25T11:00+01:00   24 horas exactas
```

🗣️ `Period` es tiempo de calendario —años, meses, días— y respeta el reloj de pared. `Duration` es
tiempo físico —segundos— y respeta la línea del tiempo. Esa noche España atrasa el reloj y el día
tiene 25 horas, así que divergen.
🔬 La pregunta que decide cuál usar: *"¿el usuario espera la misma hora del reloj, o exactamente ese
tiempo después?"*. Un recordatorio "el día antes a las 10:00" es `Period`; un token que caduca "en 24
horas" es `Duration`. Elegir mal produce el bug de una hora dos veces al año.

**02 → 8. ¿Por qué no se mide una duración con `System.currentTimeMillis()`?**

⏱️ Porque es el reloj de pared y puede saltar hacia atrás: la duración sale negativa.
🗣️ Un ajuste de NTP, un cambio manual o el horario de verano modifican ese reloj. Restar dos lecturas
deja de medir tiempo transcurrido y mide "la diferencia entre dos etiquetas que pueden haberse
movido".
🔬 La consecuencia más dañina no es el número negativo: son los **tiempos de espera que nunca
vencen**. Un `while (currentTimeMillis() - inicio < limite)` con el reloj retrasado puede girar
indefinidamente. Con `nanoTime` eso no puede pasar.

**02 → 9. ¿Qué ocurre con las 2:30 la noche del atraso, y cómo se distinguen las dos?**

⏱️ Ocurren **dos veces**, con desplazamientos distintos. Verificado:

```text
2026-10-25T02:30+02:00[Europe/Madrid]   la primera (por defecto)
2026-10-25T02:30+01:00[Europe/Madrid]   la segunda (withLaterOffsetAtOverlap)
```

🗣️ Java elige la primera por defecto y ofrece `withLaterOffsetAtOverlap()` para la segunda. Las dos
son horas locales válidas y corresponden a instantes separados por una hora.
🔬 Si el solapamiento importa —turnos, facturación por horas, registros de auditoría— hay que guardar
**el desplazamiento** además de la hora local, o directamente el instante en UTC. Un log con solo la
hora local en esa franja es irrecuperablemente ambiguo.

**02 → 10. ¿Por qué `datetime.utcnow()` está desaconsejado en Python?**

⏱️ Porque devuelve un `datetime` **naive** —sin huso— a pesar del nombre.
🗣️ El valor contiene la hora UTC pero no lo declara, así que cualquier conversión posterior lo tratará
como hora local. La alternativa correcta es `datetime.now(timezone.utc)`, que devuelve un *aware*.
🔬 Python distingue *naive* de *aware* y **lo hace cumplir**: comparar uno de cada lanza
`TypeError: can't compare offset-naive and offset-aware datetimes`, verificado. Es incómodo y evita
el bug silencioso que otros lenguajes permiten. `utcnow()` está formalmente obsoleto desde Python
3.12.

**02 → 11. ¿Qué tiene de especial el `time.Time` de Go?**

⏱️ Lleva **las dos lecturas dentro**: la de pared y la monótona.
🗣️ `time.Now()` devuelve un valor con ambas, y `time.Since` usa automáticamente la monótona. Medir
duraciones correctamente es el **comportamiento por defecto**, no algo que haya que saber elegir.
Verificado: el valor impreso incluye `m=+0.000113626`.
🔬 El detalle que muerde: **serializar o redondear con `Round(0)` descarta la lectura monótona**, así
que una duración calculada a través de un canal, una base de datos o una API vuelve a usar el reloj de
pared. Es el precio de meter dos relojes en un solo tipo, y está documentado en la sección *Monotonic
Clocks* del paquete.

**02 → 12. ¿Por qué `Period.ofMonths(1)` no es reversible?**

⏱️ Porque los meses tienen distinta longitud: sumar uno y restar uno puede no devolverte al origen.
🗣️ El 31 de enero más un mes da el 28 de febrero —Java recorta al último día válido—, y restarle un
mes da el 28 de enero. Se perdieron tres días por el camino.
🔬 Es un comportamiento **definido**, no un bug, y hay que conocerlo antes de construir un calendario
de vencimientos o de suscripciones mensuales. La decisión de negocio que hay que confirmar: si alguien
se suscribe el 31 de enero, ¿cobra el 28 de febrero y luego el 28 de marzo, o vuelve al 31? Las dos
son defendibles y el código es distinto.

**02 → 13. ¿Por qué guardar una fecha de nacimiento en UTC es un error?**

Cubierta por **02 → 3**.

**02 → 14. ¿Por qué "guarda todo en UTC" es incompleto para una cita del año que viene?**

⏱️ Porque las reglas de horario de verano **cambian**, y una cita guardada como instante se desplaza
cuando cambian.
🗣️ Si alguien reserva a las 10:00 del 30 de marzo del año que viene, se calcula el instante UTC con
las reglas de hoy. Si el país modifica su norma antes de esa fecha —cosa que ha pasado repetidamente—
ese instante ya no corresponde a las 10:00 locales, y la cita aparece a otra hora.
🔬 La regla correcta distingue tres casos: **eventos pasados** en UTC, sin duda; **fechas de
calendario** sin huso; y **citas futuras** como hora local más identificador de huso —no
desplazamiento—, convirtiendo a instante solo en el momento de usarlas. Y por eso la base de datos de
husos (tzdata) hay que mantenerla actualizada.

**02 → 15. ¿Por qué un proceso programado a las 2:30 puede ejecutarse dos veces o ninguna?**

⏱️ Porque esa hora local no existe una noche al año y ocurre dos veces otra noche.
🗣️ En el adelanto de marzo, las 2:30 no llegan nunca: según el planificador, la ejecución se salta o se
desplaza. En el atraso de octubre, las 2:30 llegan dos veces, y un planificador basado en hora local
puede disparar dos veces.
🔬 La solución de diseño es **no programar nada entre las 2:00 y las 3:00**: mover el proceso a las
4:00 elimina el problema sin una línea de código. Si no se puede, el planificador debe trabajar en UTC
y el proceso debe ser **idempotente**, que es la defensa que sirve para este y para media docena de
problemas más.

**02 → 16. ¿Qué se pierde al serializar un `time.Time` de Go?**

Cubierta por **02 → 11**: la lectura monótona, con lo que las duraciones calculadas después usan el
reloj de pared.

**02 → 17. ¿Por qué la base de datos de husos hay que mantenerla actualizada?**

⏱️ Porque las reglas de horario las cambian los gobiernos, varias veces al año en el mundo.
🗣️ La IANA publica actualizaciones de tzdata continuamente: países que dejan de cambiar la hora,
cambios de desplazamiento, nuevas zonas. Un sistema con tzdata vieja convierte mal las fechas
futuras, y a veces también las pasadas recientes.
🔬 En Java, la tzdata viene con la JDK y se actualiza con ella, o se parchea con la herramienta
`tzupdater`. En contenedores, hay que asegurarse de que la imagen base la trae al día, y es una causa
real de que dos entornos den resultados distintos con el mismo código.

**02 → 18. ¿Qué problema resuelve el margen de tolerancia en la validación de un JWT?**

⏱️ El desfase entre los relojes del emisor y del validador.
🗣️ Si el emisor va unos segundos adelantado, un token recién emitido tiene un `nbf` o un `iat` en el
futuro para el validador, que lo rechazaría. El margen —típicamente entre 30 y 60 segundos— absorbe
ese desfase.
🔬 Es la consecuencia práctica de que **no existe un reloj global**: el capítulo 8 de Kleppmann sobre
relojes poco fiables. Y tiene un coste que hay que declarar: un token revocado o expirado sigue siendo
válido durante ese margen, así que el valor se elige como compromiso entre tolerancia operativa y
ventana de riesgo.

**02 → 19. ¿Por qué comparar un `datetime` naive con uno aware lanza una excepción en Python, y qué opinas de esa decisión?**

⏱️ Porque la comparación no está definida: un naive no identifica un instante, así que no hay forma
correcta de ordenarlos.
🗣️ Python prefiere fallar a inventarse una respuesta. La alternativa —asumir que el naive está en hora
local, o en UTC— sería una suposición silenciosa que produce resultados mal en la mitad de los casos.
🔬 La opinión defendible: **es la decisión correcta y es la misma filosofía que el `time.Time` de Go o
que los tipos separados de `java.time`** — hacer que lo ambiguo no compile o no se ejecute, en vez de
documentarlo. El coste es fricción al empezar, y se recupera con creces. Es el mismo argumento que el
del `record` como clave de mapa: que el tipo impida el error.

**02 → 20. Un informe diario cuenta mal los pedidos del último día del mes. Da tres hipótesis.**

⏱️ El "día" del informe está en el huso del servidor y no en el del negocio; el rango de fechas usa
extremos cerrados o abiertos mal; o los pedidos se guardan con `LocalDateTime` sin huso.
🗣️ La primera es la más probable en un sistema internacional: un pedido de las 23:30 en Bogotá es del
día siguiente en UTC, así que aparece en el informe equivocado. La segunda produce pedidos contados
dos veces o ninguna en la frontera —el problema del convenio semiabierto de
[`03-orden-busqueda/05`](../03-orden-busqueda/05-intervalos-y-barrido.md)—. La tercera hace imposible
saber el huso original.
🔬 Cómo se distinguen: **contar los pedidos de la franja horaria fronteriza** —las últimas y primeras
horas del día— y comparar con el detalle. Si los descuadres se concentran ahí, es huso o convenio de
rango; si están repartidos, es otra cosa. La corrección de fondo es decidir **de quién es el día**
—del negocio casi siempre— y hacer la consulta con el rango semiabierto `[inicio, fin)` convertido a
instantes en ese huso.

**02 → 21. Diseña el almacenamiento de citas médicas reservables con un año de antelación, para una clínica con sedes en tres países.**

⏱️ La cita se guarda como **hora local más identificador de huso de la sede**, no como instante.

```text
cita:        fecha_hora_local (LocalDateTime) + zona_sede (ZoneId, p.ej. "Europe/Madrid")
creación:    instante UTC (Instant)           ← esto SÍ es un evento pasado
recordatorio: se CALCULA al programarlo, no se guarda como instante fijo
informe:     rango semiabierto [inicio, fin) convertido al huso de la sede
```

🗣️ El motivo es el de la pregunta 14: si un gobierno cambia su norma de horario de verano antes de la
cita, un instante guardado se desplaza y el paciente se presenta a otra hora. Guardando hora local y
huso, la cita sigue siendo "las 10:00 en Madrid" pase lo que pase.
🔬 Los cuatro detalles que preguntan. **El huso de la sede, no el del paciente**: la cita ocurre
físicamente allí. **El recordatorio de 24 horas antes** es `Duration` sobre el instante calculado, no
`Period`, porque el usuario espera 24 horas reales de antelación — y hay que recalcularlo si cambia la
norma. **Las citas en la franja del cambio de hora** hay que impedirlas al reservar, o resolver la
ambigüedad explícitamente. Y **el identificador de huso, no el desplazamiento**: guardar `+01:00` en
vez de `Europe/Madrid` congela la regla y reintroduce el problema que intentabas evitar.

**02 → 22. Los tiempos de espera de un servicio dejan de vencer tras un ajuste de NTP. Explica el mecanismo y la corrección.**

⏱️ El código mide con el reloj de pared; el NTP lo retrasó, y la diferencia calculada nunca alcanza el
límite.
🗣️ El patrón culpable es `while (System.currentTimeMillis() - inicio < limite)` o equivalente. Si el
reloj salta hacia atrás cinco minutos, la resta se vuelve más pequeña —incluso negativa— y la
condición de salida deja de cumplirse. El hilo queda girando o esperando indefinidamente.

```java
long inicio = System.nanoTime();                                   // monótono
while (System.nanoTime() - inicio < TimeUnit.SECONDS.toNanos(30)) { ... }
```

🔬 Los matices que completan la respuesta. **`nanoTime` solo es comparable dentro del mismo proceso**:
sus valores no significan nada entre máquinas ni tras un reinicio. **Las utilidades de la plataforma
ya lo hacen bien**: `Future.get(timeout, unit)`, `lock.tryLock(timeout, unit)` y las colas bloqueantes
usan el reloj correcto, así que la mejor corrección suele ser **no calcular el tiempo de espera a
mano**. Y el NTP bien configurado no salta: hace *slew*, ajustando la velocidad del reloj
gradualmente; los saltos ocurren con `ntpdate`, con una corrección grande o al arrancar una máquina
virtual desde una instantánea — que es el caso que más veces lo provoca en la práctica.

---

# 03 — Estructuras de datos y concurrencia

**03 → 1. ¿Qué significa que una estructura sea segura entre hilos?**

⏱️ Que su invariante interno se mantiene con varios hilos y que las operaciones que declara atómicas
lo son.
🗣️ Lo que **no** significa: que tus secuencias de operaciones sean atómicas, que el orden sea el que
esperas, ni que puedas iterarla mientras otro la modifica. Las tres suposiciones producen bugs.
🔬 Hay tres niveles: insegura (`HashMap`), segura por operación (`synchronizedMap`) y segura con
operaciones compuestas atómicas (`ConcurrentHashMap` con `merge`). El salto que importa es el
segundo al tercero.

**03 → 2. ¿Qué pasa si varios hilos escriben en un `HashMap` sin sincronizar?**

⏱️ Pierde actualizaciones, puede ver un estado a medio redimensionar y, antes de Java 8, podía entrar
en un bucle infinito.
🗣️ Verificado: ocho hilos con 50 000 incrementos cada uno sobre un `HashMap` dieron **71 965 de
400 000** en una ejecución. No lanza ninguna excepción: simplemente el número está mal.
🔬 El bucle infinito de las versiones antiguas era el más temido: dos hilos redimensionando a la vez
podían dejar una lista circular dentro de un bucket, y una lectura posterior giraba para siempre con
la CPU al 100 %. Java 8 cambió el algoritmo de redimensionado y ya no ocurre, pero la corrupción de
datos sigue.

**03 → 3. ¿Qué operación de `ConcurrentHashMap` hace atómico un incremento?**

⏱️ `merge(clave, 1, Integer::sum)`.
🗣️ Hace leer-sumar-escribir como una sola operación atómica. Verificado: con ocho hilos da
exactamente **400 000 de 400 000**, frente a los 128 351 del mapa sincronizado con `get` más `put`.
🔬 La familia completa es `merge`, `compute`, `computeIfAbsent`, `computeIfPresent` y `putIfAbsent`.
`computeIfAbsent` además garantiza que la función se ejecute **una sola vez** por clave aunque varios
hilos la pidan, lo que la convierte en el idioma correcto de una caché perezosa.

**03 → 4. ¿Cuál es el caso de uso de `CopyOnWriteArrayList`?**

⏱️ Muchas lecturas y casi ninguna escritura: listas de listeners, reglas, configuración.
🗣️ Las lecturas no bloquean nunca y nunca ven un estado intermedio, porque cada escritura **copia el
arreglo entero** y sustituye la referencia. Es O(1) leer y O(n) escribir.
🔬 Es catastrófico con escrituras frecuentes: mil escrituras sobre una lista de mil elementos son un
millón de copias. Y su iterador trabaja sobre la instantánea del momento de crearlo, así que nunca
lanza `ConcurrentModificationException` y tampoco ve lo añadido después: es una garantía, y hay que
saber si te sirve.

**03 → 5. ¿Qué añade una `BlockingQueue` sobre una cola normal?**

⏱️ `put` espera si está llena y `take` espera si está vacía.
🗣️ Eso resuelve productor-consumidor sin que nadie escriba `wait`/`notify`, que es una de las cosas
más fáciles de hacer mal en concurrencia.
🔬 **La capacidad acotada es la característica, no una limitación**: es lo que da backpressure. Con
una cola ilimitada, un productor más rápido que el consumidor acaba en `OutOfMemoryError` — y ese es
exactamente el fallo de un `ThreadPoolExecutor` configurado con `LinkedBlockingQueue` sin cota.

**03 → 6. ¿Por qué una estructura inmutable es segura entre hilos?**

⏱️ Porque no hay escrituras: no hay nada que proteger.
🗣️ Sin mutación no hay carreras, no hace falta sincronizar, no hay contención y todos los hilos ven
el mismo valor. Es la única forma de seguridad que **no cuesta nada** en tiempo de ejecución.
🔬 Con la condición de que sea **realmente** inmutable y esté **publicada de forma segura**:
`List.copyOf` y los `record` con componentes inmutables lo garantizan;
`Collections.unmodifiableList` no, porque es una vista sobre una lista que alguien más puede seguir
modificando.

**03 → 7. ¿Por qué `Collections.synchronizedMap` no evita perder incrementos?**

⏱️ Porque sincroniza **cada método**, y tu unidad de trabajo son dos: `get` y `put`.
🗣️ Entre el `get` de un hilo y su `put`, otro hilo hace su propio `get` y ambos escriben el mismo
valor: un incremento se pierde. Verificado: **128 351 de 400 000**, o sea el 68 % perdido, con el
mapa completamente sincronizado.
🔬 La corrección es hacer atómica **la composición**, no cada paso: `merge` de `ConcurrentHashMap`, o
un bloque `synchronized` que envuelva las dos operaciones —lo que además exige sincronizar sobre el
mismo objeto en todos los accesos, incluida la iteración—. Es el ejemplo más claro de que "sincronizado"
y "atómico" no son lo mismo.

**03 → 8. ¿Por qué `size()` de un `ConcurrentHashMap` es aproximado?**

⏱️ Porque no bloquea toda la estructura para contar: mientras suma, otros hilos insertan y borran.
🗣️ Bloquear todo para dar un número exacto anularía la ventaja de la estructura, y el número dejaría
de ser exacto en cuanto lo devolviera. La documentación lo declara como una estimación.
🔬 La consecuencia práctica: usar `size()` para una decisión de negocio bajo carga es un bug. Y lo
mismo con `isEmpty()`. La iteración es **débilmente consistente**: no lanza excepción, pero puede o no
reflejar las modificaciones hechas durante el recorrido.

**03 → 9. ¿Qué diferencia hay entre `unmodifiableList` y `List.copyOf`?**

⏱️ `unmodifiableList` es una **vista**; `List.copyOf` es una **copia** realmente inmutable.
🗣️ Si alguien conserva la referencia a la lista original, puede seguir modificándola y los cambios se
ven a través de la vista "inmutable". `List.copyOf` copia el contenido, así que nadie puede tocarla
después.
🔬 Para que la garantía sea completa, los **elementos** también deben ser inmutables: una lista
inmutable de objetos mutables no protege el estado de esos objetos. Es la misma superficialidad que
`Object.freeze` en JavaScript y que los `record` con componentes mutables.

**03 → 10. ¿Por qué una cola ilimitada es peligrosa en un pool de hilos?**

⏱️ Porque convierte un pico de carga en `OutOfMemoryError` en lugar de en rechazo.
🗣️ Con `LinkedBlockingQueue` sin cota, un `ThreadPoolExecutor` acepta trabajo indefinidamente: nunca
crea hilos más allá del tamaño base —porque la cola nunca se llena— y la memoria crece hasta caer.
El sistema no degrada: se muere.
🔬 La cola acotada es lo que activa el `RejectedExecutionHandler`, y ahí se decide la política:
rechazar, descartar el más viejo, o ejecutar en el hilo del llamante —`CallerRunsPolicy`, que frena al
productor y es un backpressure elegante—. Elegir esa política es una decisión de diseño que mucha
gente deja por defecto sin saber cuál es.

**03 → 11. ¿Qué garantiza `computeIfAbsent` que un `get` seguido de `put` no garantiza?**

⏱️ Que la función de cálculo se ejecuta **una sola vez** por clave, aunque varios hilos la pidan a la
vez.
🗣️ Con `get`+`put`, dos hilos que no encuentran la clave ejecutan ambos el cálculo caro, y uno
sobrescribe al otro. Con `computeIfAbsent`, el segundo espera y recibe el valor del primero.
🔬 Es el idioma correcto para una caché perezosa cuyo cálculo es costoso o tiene efectos. Y arrastra
la advertencia de `01-fundamentos/04`: **dentro de la función no se puede modificar el mismo mapa**,
ni recursivamente; lanza excepción desde Java 9 y antes corrompía la estructura en silencio.

**03 → 12. ¿Por qué en JavaScript no existen estructuras concurrentes?**

⏱️ Porque solo hay un hilo: ninguna secuencia de operaciones puede ser interrumpida a mitad.
🗣️ El bug del capítulo —dos hilos entre el `get` y el `put`— es imposible por construcción. El modelo
de ejecución garantiza que una función se ejecuta hasta que cede el control, así que las estructuras
normales bastan.
🔬 Lo paga con que **una operación lenta bloquea todo**, y de ahí que todo su modelo sea asíncrono.
Los *Web Workers* sí dan paralelismo real, y por eso comunican **copiando mensajes** en vez de
compartir memoria — que es la misma solución que los canales de Go, con otro nombre.

**03 → 13. ¿Qué protege el GIL de Python y qué no?**

⏱️ Protege que una operación de bytecode no se interrumpa; **no** protege tus secuencias.
🗣️ Un `dict[k] = v` no corrompe el diccionario, porque el GIL garantiza que solo un hilo ejecuta
bytecode a la vez. Pero `d[k] += 1` son varias operaciones —leer, sumar, escribir— y el intérprete
puede cambiar de hilo entre ellas.
🔬 Así que **es exactamente el mismo bug de la sección 1 con otra causa**. Y el GIL tiene un segundo
efecto que hay que nombrar: impide el paralelismo real de CPU, por lo que el trabajo intensivo se
lleva a `multiprocessing` o a extensiones nativas. Las versiones recientes de Python trabajan en
hacerlo opcional, lo que cambiará este párrafo.

**03 → 14. ¿Por qué el coste de un bloqueo no es el bloqueo sino la contención?**

⏱️ Porque un bloqueo sin competencia es muy barato; con ocho hilos peleando, serializa el trabajo.
🗣️ La JVM optimiza los bloqueos no disputados hasta hacerlos casi gratuitos. Lo caro es cuando varios
hilos lo quieren: aparecen cambios de contexto, los hilos se duermen y se despiertan, y el trabajo
que debería ser paralelo se convierte en secuencial más sobrecarga.
🔬 La consecuencia contraintuitiva: **añadir hilos puede empeorar el rendimiento** si todos compiten
por el mismo bloqueo. Por eso las estructuras concurrentes reparten los bloqueos —`ConcurrentHashMap`
bloquea por bucket— y por eso existe `LongAdder`, que reparte un contador entre celdas para que los
hilos no compitan.

**03 → 15. ¿Cuándo es correcto usar un `HashMap` normal compartido entre hilos?**

⏱️ Cuando se llena **antes** de compartirse y después solo se lee.
🗣️ Sin escrituras concurrentes no hay carreras. Es el caso de una tabla de configuración o de un
catálogo cargado al arrancar, y ahí un `HashMap` es más rápido y más simple que un concurrente.
🔬 Con una condición que no es opcional: la **publicación segura**. La referencia debe ser `final`, o
publicarse a través de un `volatile` o de un mecanismo que establezca la relación *happens-before*; si
no, otro hilo podría ver el mapa a medio construir. Lo más limpio es `Map.copyOf(...)` en un campo
`final`, que garantiza las dos cosas a la vez.

**03 → 16. ¿Por qué `d[k] += 1` en Python pierde incrementos pese al GIL?**

Cubierta por **03 → 13**: son tres operaciones de bytecode y el intérprete puede cambiar de hilo
entre ellas. La corrección es `collections.Counter` con un `Lock`, o `threading.Lock` alrededor de la
secuencia.

**03 → 17. ¿Cuál es la filosofía de Go sobre el estado compartido y qué implica para las estructuras?**

⏱️ *"No comuniques compartiendo memoria; comparte memoria comunicando."* En vez de proteger una
estructura, se pasa la propiedad del dato por un canal.
🗣️ El patrón idiomático es que una sola goroutine sea dueña de un dato y los demás le envíen
peticiones por un canal. Eso elimina la necesidad de sincronizar, porque nunca hay dos accediendo a
la vez.
🔬 `sync.Map` existe y se usa poco: está pensado para casos concretos —muchas lecturas, claves que se
escriben una vez— y usarlo por defecto se considera mal estilo. Para lo demás, un `map` normal con un
`sync.RWMutex` es lo habitual y es más rápido. La cultura del lenguaje pesa aquí tanto como la
biblioteca.

**03 → 18. ¿Qué cambian los virtual threads de Java 21 y qué **no** cambian?**

⏱️ Cambian el **coste de bloquear**; no cambian el modelo de memoria compartida ni las estructuras que
necesitas.
🗣️ Un hilo virtual cuesta unos pocos KB en vez de un megabyte, así que se pueden tener millones y
bloquear deja de ser caro. Eso permite volver al estilo síncrono —un hilo por petición— sin pagar el
precio que lo hizo inviable.
🔬 Lo que **no** cambia: sigue habiendo memoria compartida, sigue haciendo falta `ConcurrentHashMap`,
y las carreras siguen existiendo igual. Y lo que sí cambia de forma indirecta: el argumento del
*bulkhead por número de hilos* pierde fuerza —limitar hilos ya no limita casi nada— y hay que acotar
con semáforos o con colas. También hay que vigilar el *pinning*: un bloque `synchronized` puede
clavar el hilo virtual a su portador, lo que anula la ventaja.

**03 → 19. ¿Por qué `LongAdder` existe si ya está `AtomicLong`?**

⏱️ Porque con contención alta, `AtomicLong` se degrada: todos los hilos compiten por la misma celda de
memoria.
🗣️ `AtomicLong` usa CAS sobre una única variable: con muchos hilos, la mayoría de los intentos fallan
y se reintentan, y la línea de caché rebota entre núcleos. `LongAdder` reparte el valor entre varias
celdas —una por hilo, aproximadamente— y solo las suma al leer.
🔬 El compromiso: `sum()` es más caro y **no es una instantánea atómica** si hay escrituras en curso.
Por eso `LongAdder` es ideal para métricas y contadores que se leen poco, y `AtomicLong` sigue siendo
mejor cuando la contención es baja o cuando necesitas el valor exacto de cada operación —por ejemplo,
para generar identificadores con `incrementAndGet`—.

**03 → 20. ¿Por qué el `get` de una caché LRU impide protegerla con `synchronizedMap`?**

⏱️ Porque en una LRU el `get` **muta** la estructura: mueve la entrada al frente.
🗣️ `Collections.synchronizedMap` sincroniza las llamadas, así que dos `get` concurrentes no corrompen
el mapa… pero un `LinkedHashMap` con `accessOrder=true` reordena su lista enlazada interna en cada
lectura, y ahí el envoltorio sí protege. El problema real aparece con una **implementación propia**
—mapa más lista doblemente enlazada— donde el movimiento del nodo son varias operaciones y el
envoltorio no las hace atómicas como conjunto.
🔬 Es el punto que dejó abierto `09-implementaciones/03` E6. Las salidas: un bloqueo único —que
serializa también las lecturas y suele bastar—, segmentar por hash de la clave, o usar **Caffeine**,
que aproxima el LRU con un búfer de accesos drenado por lotes y por eso no necesita bloquear en cada
lectura. Que la lectura sea una escritura es lo que hace especial a esta estructura.

**03 → 21. Un contador compartido pierde el 68 % de los incrementos pese a usar un mapa sincronizado. Explica el mecanismo exacto y da dos correcciones.**

⏱️ La secuencia `get` + `put` no es atómica aunque cada llamada lo sea: dos hilos leen el mismo valor
y ambos escriben el mismo resultado.

```text
hilo A: get("clave") → 100
hilo B: get("clave") → 100        ← ambos leyeron lo mismo
hilo A: put("clave", 101)
hilo B: put("clave", 101)         ← se perdió un incremento
```

🗣️ El bloqueo del `synchronizedMap` se libera **entre** las dos llamadas, y ahí se cuela el otro hilo.
Verificado con ocho hilos y 400 000 incrementos: quedaron 128 351.
🔬 **Corrección 1, la buena:** `ConcurrentHashMap` con `merge(clave, 1, Integer::sum)`, que hace
atómica la composición. Da 400 000 exactos. **Corrección 2:** envolver las dos operaciones en un
bloque `synchronized` sobre el mismo objeto — funciona, pero hay que sincronizar **todos** los
accesos sobre ese mismo monitor, incluida la iteración, y serializa mucho más. **Y una tercera para
este caso concreto**: si el valor es solo un contador, `ConcurrentHashMap<String, LongAdder>` con
`computeIfAbsent` y `increment()` es la opción de mayor rendimiento bajo contención alta, por lo dicho
en la pregunta 19.

**03 → 22. Diseña una caché de configuración recargable en caliente, con miles de lecturas por segundo y una recarga cada diez minutos.**

⏱️ Una **estructura inmutable** detrás de una **referencia atómica** que se sustituye entera al
recargar. Ninguna estructura concurrente hace falta.

```java
private final AtomicReference<Map<String, Regla>> reglas =
        new AtomicReference<>(Map.copyOf(cargaInicial));

Regla buscar(String clave) { return reglas.get().get(clave); }      // sin bloqueo, sin contención

void recargar() { reglas.set(Map.copyOf(leerDeOrigen())); }          // sustituye la referencia entera
```

🗣️ Los lectores no se bloquean **nunca** y no compiten entre sí: leen una referencia y consultan un
mapa inmutable. La recarga construye el mapa nuevo aparte y cambia la referencia con una sola
operación atómica. Es el mismo principio que `CopyOnWriteArrayList`, aplicado a mano y a la
granularidad correcta.
🔬 Las cuatro preguntas que vienen después. **¿Qué ve una petición a medio ejecutarse?** La versión que
leyó al principio, de forma consistente, si captura la referencia **una vez** al entrar; si llama a
`reglas.get()` varias veces, puede mezclar dos versiones — y por eso lo correcto es tomar la
instantánea una sola vez por petición. **¿Y si la carga falla?** La referencia no se sustituye y el
servicio sigue con la configuración anterior, que es el comportamiento deseable: nunca dejar el
sistema sin reglas. **¿Y la memoria?** Durante la recarga coexisten las dos versiones, lo que es
asumible para una configuración y no lo sería para un catálogo enorme. **¿Y si hay que invalidar por
clave?** Entonces esto ya no es configuración, es una caché, y la respuesta cambia a Caffeine con su
política de expiración. Distinguir los dos casos es lo que se está evaluando.

---

**03 → 23. Diseña la política de concurrencia de un equipo: qué estructuras se permiten, cuáles se prohíben, qué se revisa y qué se prueba.**

⏱️ Inmutable por defecto, estructuras concurrentes cuando haga falta estado compartido, colas siempre
acotadas, y prohibido sincronizar a mano lo que ya existe hecho.
🗣️ La política:

```text
POR DEFECTO   datos inmutables; si no hay estado compartido, no hay problema de concurrencia
COMPARTIDO    ConcurrentHashMap y las colas concurrentes; nunca synchronizedMap para lectura-modificación
ATÓMICO       merge / compute / computeIfAbsent, no get seguido de put
COLAS         SIEMPRE acotadas, con política explícita de qué pasa al llenarse
PROHIBIDO     synchronized nuevo sobre estructuras que ya tienen versión concurrente ·
              colas sin límite · estado mutable estático
REVISIÓN      toda variable compartida entre hilos se justifica en el PR
PRUEBAS       una prueba de contención real por estructura compartida, no solo unitarias
```
🔬 Los dos puntos que hacen que la política funcione. **El primero: la regla de oro no es "usa
`ConcurrentHashMap`", es "sincronizar cada método no hace atómica la secuencia"** — medido en este
capítulo, un mapa sincronizado perdió el 68 % de los incrementos con ocho hilos, y ninguna prueba
unitaria lo detecta. **El segundo: las pruebas tienen que provocar contención de verdad** —N hilos
sobre la misma clave, con verificación del total— porque los errores de concurrencia no aparecen con
un hilo y sí con ocho. Y una regla que conviene añadir aunque parezca de otro bloque: **las colas
acotadas son contrapresión**, por `08/04`, así que el límite no es una precaución: es el mecanismo.

**03 → 24. Un servicio pasa de 4 a 32 núcleos y su rendimiento no mejora, o empeora. Da tres hipótesis ordenadas y cómo distingues cada una.**

⏱️ Contención sobre un recurso compartido, un cuello fuera de la CPU, o falso compartido de líneas de
caché.
🗣️ Las tres:

```text
1. CONTENCIÓN   un cerrojo, un contador atómico o una estructura sincronizada que todos tocan
2. CUELLO FUERA el límite está en la base de datos, la red o el disco: más núcleos no compran nada
3. FALSO COMPARTIDO  variables distintas en la misma línea de caché: los núcleos se invalidan entre sí
```
🔬 Cómo se distinguen. Para la **1**, un perfilador de contención o un volcado de hilos repetido: si
muchos hilos están bloqueados en el mismo monitor, está localizado; el síntoma característico es que
el rendimiento **empeora** al añadir núcleos, porque la contención crece con el número de
participantes. Para la **2**, mirar el uso de CPU: si está baja, no es un problema de paralelismo sino
de espera, y entonces es el bloque `08`. Para la **3**, que es la más difícil, la pista es un
contador o un array de contadores por hilo en posiciones contiguas; se confirma separándolos con
relleno y midiendo. Y el orden importa porque las correcciones son muy distintas: la 1 se arregla
cambiando de estructura —`LongAdder` en vez de `AtomicLong`, particionado por clave—, la 2 no se
arregla con concurrencia en absoluto, y la 3 con relleno o con estado por hilo.

# 04 — Simulación: preguntas transversales

Las `S#` que ya están cubiertas por una pregunta de capítulo no se repiten: se remite.

**04 → S1. ¿Cómo representas dinero y por qué?**

Cubierta por **01 → 2** y **01 → 19**.

**04 → S2. ¿Por qué `0.1 + 0.2` no es `0.3`?**

Cubierta por **01 → 1**.

**04 → S3. ¿Cuándo es correcto usar `double`?**

Cubierta por **01 → 8**.

**04 → S4. ¿Qué cuatro cosas tiene que incluir una respuesta completa sobre `BigDecimal`?**

⏱️ Construirlo desde `String`; fijar escala y `RoundingMode`; comparar con `compareTo`; y redondear
una sola vez, al final.
🗣️ Cada una cierra un bug distinto: el constructor con `double` guarda basura; una división sin escala
lanza excepción; `equals` distingue `1.0` de `1.00`; y redondear en cada paso acumula desviación.
🔬 La quinta, si te dejan seguir: **la divisa vive dentro del tipo**, no al lado. `BigDecimal` solo
resuelve la aritmética, no el dominio.

**04 → S5. ¿Por qué `HALF_UP` sesga un total, y quién decide el modo de redondeo?**

Cubierta por **01 → 4** y **01 → 11**. Lo decide la norma contable o el contrato, nunca el
programador.

**04 → S6. ¿Por qué un importe no debe viajar como número en un JSON?**

Cubierta por **01 → 17**.

**04 → S7. Dos sistemas difieren en un céntimo al facturar el mismo pedido. Diagnostica.**

Cubierta por **01 → 20**.

**04 → S8. ¿Cuáles son los tres tipos de tiempo y cuándo se usa cada uno?**

Cubierta por **02 → 1**.

**04 → S9. ¿Por qué `LocalDateTime` no es una marca de tiempo?**

Cubierta por **02 → 2**.

**04 → S10. ¿Por qué "guardar todo en UTC" es una respuesta incompleta?**

Cubierta por **02 → 14**.

**04 → S11. ¿Por qué `Period.ofDays(1)` y `Duration.ofHours(24)` difieren?**

Cubierta por **02 → 7**.

**04 → S12. ¿Qué reloj usas para medir una duración y por qué?**

Cubierta por **02 → 4** y **02 → 8**.

**04 → S13. ¿Qué tiene de particular el `time.Time` de Go?**

Cubierta por **02 → 11**.

**04 → S14. Un proceso programado se ejecuta dos veces una noche al año. Explica y corrige.**

Cubierta por **02 → 15**.

**04 → S15. ¿Qué significa exactamente que una estructura sea segura entre hilos?**

Cubierta por **03 → 1**.

**04 → S16. ¿Por qué `synchronizedMap` no evita perder incrementos?**

Cubierta por **03 → 7** y **03 → 21**.

**04 → S17. ¿Cuál es la secuencia de decisión ante "hazlo seguro entre hilos"?**

⏱️ Inmutable → publicado de forma segura y solo lectura → estructura concurrente con la operación
compuesta atómica → bloqueo a mano.
🗣️ Se baja un escalón solo cuando el anterior no sirve. Empezar por el bloqueo es empezar por el
final: es lo más costoso, lo más fácil de hacer mal y lo que peor escala.
🔬 El primer escalón es el que más problemas elimina y el que menos gente considera. "¿Puede ser
inmutable?" hace desaparecer la pregunta en vez de gestionarla, y en configuración, catálogos y
objetos de valor la respuesta suele ser que sí.

**04 → S18. ¿Cuándo es correcto compartir un `HashMap` normal entre hilos?**

Cubierta por **03 → 15**.

**04 → S19. ¿Por qué una cola ilimitada convierte un pico de carga en una caída?**

Cubierta por **03 → 10**.

**04 → S20. ¿Por qué `CopyOnWriteArrayList` es excelente y terrible según el caso?**

Cubierta por **03 → 4**.

**04 → S21. ¿Qué cambian los virtual threads y qué no?**

Cubierta por **03 → 18**.

**04 → S22. ¿Qué lenguajes traen decimal exacto en su stdlib y qué hacen los demás?**

Cubierta por **01 → 5**.

**04 → S23. ¿Por qué en Go `0.1 + 0.2 == 0.3` puede ser `true`?**

Cubierta por **01 → 13**.

**04 → S24. ¿Por qué Python distingue *naive* de *aware* y qué opinas de esa decisión?**

Cubierta por **02 → 19**.

**04 → S25. ¿Por qué JavaScript no necesita estructuras concurrentes, y qué paga por ello?**

Cubierta por **03 → 12**.

**04 → S26. ¿Cuál es la filosofía de Go sobre estado compartido?**

Cubierta por **03 → 17**.

**04 → S27. "En mi equipo usamos `double` para importes y nunca ha pasado nada." Responde.**

⏱️ Que "nunca ha pasado nada" es una observación sobre lo que se ha mirado, no sobre lo que ha
ocurrido.
🗣️ Los errores de coma flotante en dinero **no producen excepciones**: producen céntimos de
diferencia que solo aparecen al cuadrar con otro sistema. Si nadie concilia contra contabilidad o
contra el banco, el problema existe y no se ve. Y la magnitud crece con el volumen y con el número de
operaciones intermedias.
🔬 La forma constructiva de plantearlo, sin sermón: proponer una **comprobación**, no una discusión.
Recalcular un mes de facturación con `BigDecimal` y comparar los totales con los emitidos es un
script de una tarde y convierte una opinión en un dato. Si la diferencia es cero, el riesgo era
teórico y se documenta; si no lo es, ya no hay debate. Ese es el movimiento que se espera de un Tech
Lead.

**04 → S28. ¿Cuál es el bug más caro que has visto relacionado con tipos numéricos o fechas?**

⏱️ Es una pregunta de experiencia: responde con el síntoma, el diagnóstico y la corrección
estructural.
🗣️ Los casos más creíbles de este bloque son cuatro: el descuadre de céntimos entre facturación y
contabilidad por redondear en puntos distintos; el informe diario mal cortado por huso; el proceso
que se ejecuta dos veces la noche del cambio de hora; y el identificador de 64 bits corrompido al
pasar por JavaScript. Los cuatro son caros porque **se detectan tarde**.
🔬 Lo que se evalúa es si distingues el bug de su causa: la corrección de "redondeamos distinto" no es
cambiar un `RoundingMode`, es **acordar y documentar la regla** y hacerla cumplir en los dos sistemas.
Una respuesta que termina en "y añadimos una conciliación automática que lo habría detectado en un
día" vale mucho más que una que termina en "lo arreglamos".

**04 → S29. Te piden migrar importes de `double` a `BigDecimal` en un sistema en producción con diez años de datos. ¿Cómo lo planteas?**

⏱️ No como una migración de tipo, sino como un proyecto con dos preguntas previas: **qué hacemos con
el histórico** y **cómo demostramos que no rompimos nada**.

```text
1. Acotar: ¿qué columnas y qué cálculos tocan dinero de verdad? (casi nunca son todos)
2. Decidir el histórico: ¿se reescribe, se congela o se marca como "precisión heredada"?
3. Cambiar el tipo en el dominio primero, con conversión en los bordes
4. Ejecutar en paralelo: calcular con los dos tipos y comparar, sin cambiar el resultado emitido
5. Cuando la divergencia sea cero o explicada, cambiar el emisor
6. Migrar el esquema (DECIMAL con escala) al final, no al principio
```

🗣️ El paso 4 es el que hace viable el proyecto: **la ejecución en paralelo** convierte una migración
arriesgada en una medición. Durante semanas registras las diferencias, y cada una es o un bug del
código nuevo o una demostración del error que tenías.
🔬 Las decisiones que no puede tomar quien programa. **El histórico**: reescribir importes ya
facturados puede ser ilegal —hay facturas emitidas con esos números—, así que lo habitual es congelar
el pasado y aplicar la precisión nueva solo a futuro, con una marca que lo indique. **El punto de
corte**: un cierre contable, no un martes cualquiera. **Y la tolerancia**: durante el paralelo
aparecerán diferencias de un céntimo que son correctas —el nuevo está bien y el viejo estaba mal—, y
alguien de negocio tiene que aceptarlas explícitamente. El riesgo real de esta migración no es
técnico.

**04 → S30. ¿Por qué estos tres temas —números, tiempo y concurrencia— están en el mismo bloque?**

⏱️ Porque los tres son **abstracciones con fugas**: la máquina asoma por debajo del tipo, y el bug
aparece lejos de donde está la causa.
🗣️ Un `double` promete un número real y entrega una fracción binaria. Un `LocalDateTime` promete un
momento y no lo identifica. Un `HashMap` promete un mapa y no promete nada bajo concurrencia. En los
tres casos el código parece correcto, compila, pasa los tests y falla en producción con datos reales.
🔬 Y comparten la forma del fallo: **no lanzan excepción**. Devuelven un número ligeramente distinto,
una fecha desplazada un día, un contador con el 68 % menos. Por eso los tres se detectan al cuadrar
con otro sistema y no al ejecutar, y por eso el antídoto es el mismo en los tres: **elegir el tipo por
su semántica**, no por costumbre, y hacer que lo ambiguo sea imposible de expresar.

---

# 04 — Simulación: problemas de pizarra

**04 → P1. El tipo `Money`.**

Cubierto en detalle por **01 → 21**, incluido el reparto de 100 € entre 3 —`[33,34 €, 33,33 €,
33,33 €]`— que es la repregunta.

**La serialización hacia el front**, que es la parte que `01 → 21` no cubre: el importe sale como
**entero de unidad mínima más código de divisa**, nunca como decimal JSON.

```json
{ "importe": 9950, "divisa": "EUR", "decimales": 2 }
```

- El entero cabe exacto en el `double` de JavaScript hasta 2⁵³, que cubre cualquier importe realista.
- Incluir `decimales` evita que el front asuma 100 y falle con yenes o dinares.
- La alternativa es el string `"99.50"`, igual de válida y más legible en el log; lo que no vale es el
  número decimal.

**04 → P2. La factura que no cuadra.**

**El plan de diagnóstico**, antes de mirar código:

```text
1. Aislar UN caso concreto que falle, con sus datos de entrada
2. Recalcular a mano el importe esperado, con todos los decimales
3. Pedir a los dos sistemas los importes INTERMEDIOS, línea a línea
4. Encontrar el primer punto de divergencia
```

**Las hipótesis, en orden**, y qué las delata:

| Hipótesis | Síntoma característico |
|---|---|
| **Redondeo en puntos distintos** | Las líneas cuadran y el total no, o al revés. Solo en algunas facturas |
| **Modo de redondeo distinto** | Solo con empates exactos, y **siempre en la misma dirección** |
| **Uno usa `double`** | Errático, sin patrón, más visible con importes grandes o muchas líneas |
| **Tipos de cambio o IVA con distinta escala** | Solo en facturas multidivisa o con ciertos tipos impositivos |

**La pista del enunciado decide.** "Siempre por debajo" y "unas pocas al mes" apunta a **modo de
redondeo**: un `HALF_DOWN` o un truncamiento frente a un `HALF_UP`, que solo diverge en los empates
—raros— y siempre hacia abajo. Si fuera coma flotante, el signo sería aleatorio.

**La repregunta: "¿y si fuera siempre exactamente un céntimo por línea?"** Entonces no es redondeo,
es **truncamiento sistemático**: alguien está haciendo `(long) valor` o `intValue()` en vez de
redondear, y pierde la fracción en cada línea. La diferencia sería proporcional al número de líneas,
que es justo lo que "por línea" indica.

**04 → P3. Las citas de la clínica.**

Cubierto en detalle por **02 → 21**. En resumen: la cita se guarda como **hora local más identificador
de huso de la sede**; la creación como `Instant`; el recordatorio se **calcula**, no se guarda; y el
informe usa un rango semiabierto convertido al huso de la sede.

**La repregunta: "¿qué pasa si un gobierno cambia su norma de horario de verano?"** Es exactamente el
motivo del diseño. Con hora local más huso, **no pasa nada**: la cita sigue siendo "las 10:00 en
Madrid" y el instante se recalcula con las reglas nuevas al consultarla. Con instante en UTC, la cita
se desplazaría una hora y el paciente llegaría tarde o pronto.

Lo que sí hay que hacer: **actualizar la tzdata** del sistema —pregunta 17— y **recalcular los
recordatorios ya programados**, porque esos sí se materializaron como instantes. Y si la clínica
notificó al paciente una hora concreta por correo, hay una decisión de negocio: reenviar la
confirmación o no.

**04 → P4. El contador que pierde.**

Cubierto en detalle por **03 → 21**, con el mecanismo del entrelazado y las tres correcciones.

**La versión que escribiría:**

```java
private final ConcurrentHashMap<String, LongAdder> contadores = new ConcurrentHashMap<>();

void contar(String endpoint) {
    contadores.computeIfAbsent(endpoint, k -> new LongAdder()).increment();
}
```

- `computeIfAbsent` garantiza **un solo `LongAdder` por endpoint** aunque varios hilos lo creen a la
  vez.
- `LongAdder` reparte el contador entre celdas, así que con contención alta no hay CAS peleándose por
  una sola dirección de memoria — pregunta 19.

**La repregunta: "¿y si hay que exponer el conteo por HTTP en cualquier momento?"** Aparecen dos
matices. `LongAdder.sum()` **no es una instantánea atómica**: si hay escrituras en curso, el valor
puede no corresponder a ningún instante exacto. Para un contador de métricas eso es perfectamente
aceptable —y es lo que hace cualquier sistema de monitorización—, pero hay que decirlo. Si se
necesitara una instantánea coherente de todos los endpoints a la vez, ninguna de estas estructuras la
da: haría falta una barrera o un modelo de versiones, y casi siempre la pregunta correcta es si de
verdad hace falta.

**04 → P5. La configuración en caliente.**

Cubierto en detalle por **03 → 22**: estructura **inmutable** tras una `AtomicReference`, sustituida
entera al recargar. Ninguna estructura concurrente hace falta, que es lo que el problema quiere que
descubras.

**La repregunta: "¿qué garantiza tu solución si una petición está a medio ejecutarse durante la
recarga?"** Depende de cómo lea, y esta es la parte que distingue la respuesta:

```java
// CORRECTO: una instantánea por petición, coherente de principio a fin
Map<String, Regla> snapshot = reglas.get();
Regla a = snapshot.get("limite");
Regla b = snapshot.get("umbral");     // garantizado: misma versión que 'a'

// INCORRECTO: puede mezclar dos versiones de la configuración
Regla a = reglas.get().get("limite");
Regla b = reglas.get().get("umbral"); // puede venir de la configuración NUEVA
```

- Tomando la referencia **una sola vez** al entrar, la petición ve una configuración **consistente**,
  aunque sea la anterior. Eso casi siempre es lo que se quiere.
- Llamando a `get()` varias veces puedes aplicar el límite viejo y el umbral nuevo, que es un estado
  que **nunca existió** y es el peor resultado posible.

Y el resto de garantías: si la carga falla, la referencia no se sustituye y el servicio sigue con la
configuración anterior; durante la recarga coexisten dos versiones en memoria, asumible para
configuración; y las peticiones en curso **nunca** ven un mapa a medio construir, porque el mapa
nuevo se construye entero antes de publicarse.

---

**Vuelta a:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**README del bloque:** [`06-numeros-tiempo-concurrencia`](README.md)

---

**Anterior:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
