# 📐 Formato del banco de pruebas
## Go para desarrolladores Java senior — `BENCHMARKS.md`

Regla de este curso: **ninguna afirmación de rendimiento se
escribe sin su entrada aquí.** Vale también para las que parecen obvias —"Go
arranca más rápido", "una goroutine pesa menos que un hilo"—, porque *cuánto* más
rápido y *cuánto* menos es justo lo que el lector necesita para decidir.

Si al escribir una fase necesitas una afirmación y no tienes la medición, tienes
dos salidas honestas: **crear la entrada y medir**, o **no escribir la frase**.
La tercera —escribirla igual y suavizarla con un "suele ser"— no es una salida.

---

## 1. Qué entra en `BENCHMARKS.md`

- Comparaciones **Go frente a Spring Boot** sobre ClearingHouse (Fase 16).
- Comparaciones **entre alternativas dentro de Go**: `database/sql` frente a
  `pgx` nativo, SQL a mano frente a `sqlc` frente a GORM, fake frente a mock
  generado en tiempo de suite, `strings.Builder` frente a concatenación,
  streaming frente a carga completa.
- **Costes del lenguaje**: coste de una goroutine, de una asignación en el
  montículo, de una llamada a través de interfaz, de la serialización JSON.
- **Propiedades de los servicios**: rendimiento de entregas de EventRelay,
  memoria del reporte de OpsReport, tasa de acierto de la caché de AtlasSync,
  ventana del cierre de ClearingHouse.

**No entra** lo que no se midió en el banco del curso. Un número leído en un
artículo se cita como cita, en la sección de referencias de la fase, y nunca como
resultado propio.

---

## 2. Estructura de una entrada

````markdown
## B-{{NN}} — {{Título en una línea, afirmativo}}

**Fase:** {{NN}} · **Proyecto:** {{servicio o mini proyecto}} · **Fecha:** {{AAAA-MM-DD}}

### Hipótesis
{{Una frase falsable, con número y unidad. "pgx en modo nativo reduce la latencia
p95 de la consulta de listado en al menos un 20% frente a database/sql con el
mismo driver" — no "pgx es más rápido".}}

### Condiciones
- **Máquina:** {{CPU, núcleos, RAM, sistema y arquitectura}}
- **Versiones:** Go {{x.y.z}} · {{driver/librería y versión}} · {{JDK y Spring si aplica}}
- **Datos:** {{volumen, forma, cardinalidad}}
- **Carga:** {{concurrencia, duración, calentamiento, herramienta}}
- **Aislamiento:** {{qué más corría, gobernador de CPU, contenedores, límites}}

### Cómo reproducirlo
```bash
{{los comandos exactos, en orden, tal como se ejecutaron}}
```

### Resultados

| Variante | p50 | p95 | p99 | ops/s | B/op | allocs/op | RSS |
|---|---|---|---|---|---|---|---|
| {{A}} | | | | | | | |
| {{B}} | | | | | | | |

{{Para microbenchmarks, la salida de `benchstat` con su delta y su intervalo. Una
sola corrida no es un resultado: mínimo diez, y se dice cuántas.}}

### Veredicto
{{Guía accionable, no un adjetivo. "Usa pgx nativo en las rutas de listado; en el
resto la diferencia no paga el acoplamiento al driver."}}

### Qué NO demuestra
{{Obligatorio. Los límites de la medición: tamaño de datos, ausencia de red,
máquina única, carga sintética. Es lo que separa un benchmark de una consigna.}}
````

---

## 3. Reglas de honestidad

1. **Se prueba a todos los competidores que el curso nombra**, no solo al que
   queremos que gane. Si la fase menciona GORM, GORM se mide.
2. **La JVM se mide ajustada**, no con las opciones por defecto. Comparar Go
   contra una JVM sin calentar ni configurar es hacer trampa, y se nota.
3. **Con calentamiento declarado.** La JVM compila en caliente; ignorarlo es el
   error más común de las comparaciones que circulan por internet.
4. **Mínimo diez corridas** y `benchstat` para los microbenchmarks. Una
   diferencia sin intervalo de confianza es ruido con formato de tabla.
5. **Se publica el resultado incómodo.** Si una optimización no mejoró nada, la
   entrada se escribe igual y la fase la cuenta: *"lo medimos, no cambió, lo
   revertimos"* es una de las lecciones más útiles del curso.
6. **Se declara el hardware.** Un número sin máquina no es reproducible.
7. **Números absolutos y relativos.** "Un 40% más rápido" sin decir de qué a qué
   no sirve para decidir nada.
8. **Nada de extrapolar.** Que el cierre de un millón tarde X no autoriza a
   afirmar cuánto tardaría con diez millones. Si importa, se mide.

---

## 4. Numeración

`B-01`, `B-02`, … en orden de creación, no de fase. Cada entrada se cita desde
la fase con su identificador: *"📐 la caché sube el acierto al 94% (B-17)"*.

Un identificador **nunca se reutiliza**. Si una medición se rehace con otras
condiciones, es una entrada nueva que enlaza a la anterior y dice qué cambió.

---

## 5. Entradas mínimas que el curso necesita

Se listan aquí para que ninguna fase llegue a la afirmación sin la medición
preparada. La fase que las produce las escribe.

| ID | Tema | Fase |
|---|---|---|
| B-01 | Compilación cruzada: mismo binario, cinco plataformas, tiempo y tamaño | 00 |
| B-02 | `strings.Builder` frente a `+=` y `fmt.Sprintf` | 01 |
| B-03 | `regexp` compilado fuera del bucle frente a dentro | 01 |
| B-04 | Slice pre-dimensionado frente a `append` desde cero | 01 |
| B-05 | Coste de una interfaz frente a llamada directa | 02 |
| B-06 | Decodificación JSON completa frente a streaming | 03 |
| B-07 | Coste de arranque de una goroutine frente a un hilo de la JVM | 06 |
| B-08 | Canal con búfer frente a mutex para un contador | 06 |
| B-09 | Worker pool acotado frente a goroutine por tarea, bajo pico | 06 |
| B-10 | `-race`: cuánto cuesta en tiempo y memoria | 06 |
| B-11 | El mismo servicio en 1.13 y en Go moderno: binario, arranque, memoria | 08 |
| B-12 | `ServeMux` moderno frente al enrutado a mano | 08 |
| B-13 | `database/sql` frente a `pgx` nativo | 09 |
| B-14 | SQL a mano frente a `sqlc` frente a GORM | 09 |
| B-15 | Paginación por cursor frente a `OFFSET` a las 100.000 filas | 09 |
| B-16 | SQLite: con WAL y sin WAL, escrituras por segundo | 09 |
| B-17 | AtlasSync: tasa de acierto y latencia con y sin Valkey | 12 |
| B-18 | Caché: bytes precodificados frente a codificar por petición | 12 |
| B-19 | Reporte de 500.000 filas: streaming frente a carga completa | 13 |
| B-20 | Cierre por lotes: tamaño de fragmento frente a tiempo total | 13 |
| B-21 | Imagen de contenedor: Go distroless frente a Spring Boot | 14 |
| B-22 | `GOGC` y `GOMEMLIMIT`: efecto sobre pausas y memoria | 15 |
| B-23 | EventRelay: entregas por segundo contra `fakeconsumer` | 15 |
| B-24 | **El duelo completo**: Go frente a Spring Boot y `native-image` | 16 |
| B-25 | Amplificación del reintento: retroceso fijo frente a exponencial con jitter | 10 |
| B-26 | MongoDB: `$push` sin límite frente al tamaño del documento | 11 |
| B-27 | El despachador del outbox frente al número de instancias | 13 |
| B-28 | Coste del middleware de observabilidad por petición | 15 |
| B-29 | Fake frente a mock generado: tiempo de suite | 10 |

**Las cinco últimas se añadieron al cerrar el curso**, cuando el repaso de
continuidad encontró afirmaciones apoyadas en mediciones propuestas y nunca
asignadas. Dos propuestas más —el coste de `slog` frente a `log.Printf` y el de
`ctx.Value` por profundidad— **se resolvieron por la otra salida**: suavizar la
afirmación de la fase a lo estructural, que es lo que §3 admite cuando el dato no
cambia ninguna decisión de diseño.
