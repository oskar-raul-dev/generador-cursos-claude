# 📏 Formato de las mediciones
## C# para desarrolladores Java senior

El curso tiene una regla que lo sostiene entero: **ninguna afirmación comparativa entra sin un
número producido por el arnés del curso** (guía §4.6). Este documento define el arnés, la forma
de la medición y las reglas de honestidad que la hacen creíble. Es la sección 6 de cada fase.

Se sigue literal. Una medición mal hecha es peor que ninguna, porque el lector la va a citar.

---

## 1. El arnés

**Se construye en la Fase 00 y no se reemplaza nunca.** Las fases posteriores lo amplían —pico
de memoria en la 06, latencia de red en la 15, costo mensual en la 20— pero ninguna lo sustituye
por otro, y ninguna mide con algo que el lector no tenga.

Qué hace, y nada más:

- **Ejecuta la operación N veces y descarta el calentamiento.** En .NET esto no es un detalle:
  el JIT compila en el primer paso y vuelve a compilar en niveles superiores más adelante, así
  que las primeras iteraciones miden al compilador, no al código.
- **Reporta mediana y percentil 95**, nunca el promedio. El promedio de una distribución con
  pausas de GC no describe nada que le pase a un usuario.
- **Reporta asignaciones totales y pico de memoria administrada**, además del tiempo. En este
  ecosistema la mitad de las diferencias interesantes son de asignación, y el tiempo solo las
  refleja cuando el recolector ya se despertó.
- **Declara el entorno** en la propia salida: versión del SDK, configuración de compilación,
  máquina, tamaño del dato y número de repeticiones.
- **Escribe el resultado en el formato de §3**, listo para pegarse en `BENCHMARKS.md`.

> 🧭 **Que sea pequeño.** Un arnés que hay que aprender a usar deja de usarse. Si en la Fase 12
> el lector tiene que releer cómo se invoca, el arnés está mal diseñado.

**Sobre BenchmarkDotNet:** existe, es excelente y es el estándar del ecosistema. El curso lo
presenta y lo usa **donde la pregunta es de microbenchmark** —una asignación, un parseo, una
comparación de estructuras— porque ahí hacer las cosas a mano es equivocarse. Para todo lo demás
—un reporte de 500.000 filas, el arranque en frío de un contenedor, la latencia de una pantalla
desde Lima— el arnés propio es más honesto, porque mide el trabajo completo y no el fragmento.
La fase que use uno u otro dice cuál y por qué.

---

## 2. Las siete reglas de honestidad, y la forma de lo pendiente

**2.1 · El competidor es defendible.** Se compara contra una implementación que alguien
defendería en una revisión de código: con su pool de conexiones, su índice puesto y su
configuración de producción. Medir contra un espantapájaros es la forma más común de mentir con
datos ciertos, y en un curso que compara .NET con Java es la tentación permanente.

**2.2 · Primero SQL, después .NET.** Cuando el trabajo toca la base de datos, el plan de consulta
se mide **antes** que el código. Con treinta tablas anuales unidas por `UNION ALL` generado
concatenando cadenas, el primer orden de magnitud no está en el lenguaje. Optimizar C# encima de
una consulta mala es teatro, y el curso lo dice cada vez que aplique.

**2.3 · El dato es realista y está fechado.** Los volúmenes salen de la historia: 500.000 filas
en el reporte histórico, 1.900 movimientos huérfanos, 400 manuscritos al mes, 90 instalaciones,
nueve husos. Un benchmark sobre mil filas no decide nada y lo sabe todo el mundo.

**2.4 · Se publica el empate.** Cuando dos opciones quedan dentro del ruido de la medición, el
veredicto dice *empate* y lo justifica con la dispersión. Es la palabra que menos aparece en los
cursos de tecnología y la que más falta hace — y en el duelo de la Fase 23 va a aparecer varias
veces.

**2.5 · Lo que no se puede ejecutar se declara, no se estima en silencio.** El curso no exige
suscripción de Azure de pago (`alcance-del-proyecto.md` §10). Donde la medición sea de costo o
de un servicio que no se puede levantar en local, se dice **qué precio publicado se usó, de qué
fecha, y en qué región**, y se marca el resultado como *no ejecutado*. Un número inventado
contamina las veinticinco fases.

### 2.6 · ⏳ La medición escrita y todavía no ejecutada

Una fase se escribe antes de que su número exista: el material se redacta en una máquina y se
ejecuta en otra. Eso está permitido, con una forma fija y sin excepciones.

Una medición ⏳ se escribe **completa** —hipótesis, condiciones, competidores, el comando exacto
que la produce y la tabla con sus filas y columnas nombradas— y la tabla lleva `⏳` en cada celda
de resultado en vez de un número. El veredicto se escribe en dos partes: **la dirección que la
hipótesis espera**, marcada como expectativa y no como hallazgo, y **el umbral cuyo valor la
ejecución tiene que determinar**.

> 🧭 **Una fila ⏳ no se cita.** Ni en otra fase, ni en el veredicto de la F24, ni como argumento
> de una decisión. Hasta que alguien la ejecute en su máquina y reemplace las celdas, esa medición
> existe como encargo, no como dato. El curso prefiere una tabla honestamente vacía a un número
> inventado que las veinticinco fases van a arrastrar.

Y la contraparte: **el comando tiene que estar ahí**. Si el lector no puede producir el número con
lo que la fase le dio, la medición no está escrita — está prometida, que es lo que §2.5 prohíbe
para la nube y aplica igual aquí.

### Y dos reglas más, que nacieron tarde y por eso van después de §2.6

> 📝 **Por qué las dos últimas reglas están numeradas detrás de una convención y no junto a las
> otras cinco.** Porque **veinticinco documentos publicados citan `§2.6`** para la forma de una
> medición pendiente, y renumerarla habría roto todas esas citas — que es exactamente la clase de
> cambio que la regla de bloqueo de contenido de este curso existe para impedir.
> El orden de los números refleja **cuándo se descubrió cada regla**, no su importancia: las dos de
> abajo son de las que más deciden.

**2.7 · Una cifra de costo va con precio publicado, fuente, fecha y región, o no va.** Es §2.5
llevada a su forma fuerte, y la agrega la **F20**, que es la única fase cuyo veredicto está en
pesos. Un costo sin esos cuatro datos no es un dato: es un recuerdo, y no se puede reverificar seis
meses después cuando alguien lo cuestione en una reunión de presupuesto. Aplica igual a las cifras
de costo que aparecen dentro de otras mediciones (F15, F16, F17, F19, F22, F23). La región por
omisión del curso es **East US 2**.

**2.8 · Una comparación entre plataformas o productos publica su declaración de defendibilidad**,
o no se publica. Qué se configuró en cada lado, con qué valor y por qué, item por item y simétrica
—y las asimetrías que no se pueden igualar, declaradas también—. La agrega la **F23**, y es la
forma verificable de §2.1: sin ella, *"el competidor es defendible"* es una afirmación del autor
sobre sí mismo; con ella, es algo que un lector puede criticar línea por línea. Vive junto a la
medición y **se escribe antes de medir**, nunca después.

> 🧭 **Tres de las siete nacieron de un problema concreto y esa procedencia es material:** la 5 de
> no poder ejecutar servicios de nube, la 6 de que la F20 tiene su veredicto en pesos, y la 7 de
> que la F23 mide contra el ecosistema en que el lector es experto. Una regla que nace de un
> problema se respeta; una que nace de una lista de buenas prácticas, no.

### 2.9 · 🔜 La columna cuyo competidor todavía no existe

Distinta de ⏳ y conviene no confundirlas. **⏳ significa "escrita y sin ejecutar"**: el comando
existe y alguien la puede correr hoy. **🔜 significa "el competidor no existe todavía"** — la
medición no se puede tomar porque lo que hay que medir aún no está construido.

Una celda 🔜 **tampoco se cita**, por la misma razón que una ⏳, y tiene una obligación adicional:
**nombrar la fase que la va a llenar**. Un 🔜 sin destino es un hueco, no un encargo.

> 🪦 **Apareció una sola vez en las veinticinco entradas** —la cuarta columna del veredicto del
> escritorio (F14), que la F18 llenó cuatro fases después— y esa rareza es un dato sobre el orden
> del curso, no sobre la convención: la **F24 §4** la usa como evidencia de que el veredicto del
> escritorio debió ir después de la web. **Si al escribir una fase aparece un segundo 🔜, lo que
> hay que revisar es el orden**, no inventar más maquinaria.

---

## 3. La forma de la sección 6

Idéntica en todas las fases, para que se puedan comparar entre sí y volcarse a `BENCHMARKS.md`.

````markdown
## 📏 6. Medición

**Hipótesis:** {{una línea, falsable. "EF Core con seguimiento cuesta más que Dapper en la
consulta de catálogo" — no "queremos ver el rendimiento".}}

**Condiciones:** SDK {{x.y.z}} · compilación Release · {{máquina}} · {{tamaño del dato}} ·
{{repeticiones, calentamiento descartado}} · {{qué se mide y con qué}}

**Competidores:** {{qué se compara, y por qué cada uno es defendible}}

**Resultado:**

| Opción | Mediana | p95 | Asignado | Pico |
|---|---|---|---|---|
| {{...}} | {{...}} | {{...}} | {{...}} | {{...}} |

> ⚖️ **Veredicto.** {{Qué gana, dónde pierde, y **a partir de qué umbral cambia la respuesta**.
> El umbral es la parte que el lector se lleva: "por debajo de veinte mil filas la diferencia no
> justifica el cambio".}}
````

**La tercera línea del veredicto es obligatoria y es la que más se olvida:** un veredicto sin
umbral es una preferencia. *"Dapper gana"* no sirve; *"Dapper gana en lectura de lotes grandes y
la ventaja desaparece por debajo de las dos mil filas, donde el costo de mantener dos formas de
acceso a datos pesa más"* sí.

---

## 4. Las fases que no miden

Una fase sin medición es la excepción, no la norma, y lo dice en una línea convincente dentro de
la propia sección 6. En la secuencia actual hay una sola candidata razonable —la Fase 24, que es
el veredicto y consolida mediciones ajenas en vez de producir una propia— y aun así publica la
tabla acumulada.

Si al escribir una fase la medición no aparece sola, casi siempre significa una de dos cosas: la
fase no tiene una afirmación comparativa que sostener —y entonces sobra la sección— o la tiene y
no se está midiendo, que es el error que este documento existe para evitar.

---

## 5. `BENCHMARKS.md`

Vive en la raíz del curso y **nace con la Fase 00**, no al final. Cada fase agrega su entrada al
cerrarse, con el mismo formato de §3 más dos campos que solo tienen sentido en el archivo
consolidado: **la fase que la produjo** y **la fecha de ejecución**.

Dejarlo para el final garantiza que las condiciones de las primeras mediciones se pierdan, y una
medición sin sus condiciones no es una medición: es una anécdota con decimales.

Cuando una medición posterior **contradiga** a una anterior —pasa, y es sano—, la entrada vieja
no se borra: se marca 🪦 con un puntero a la nueva y una línea sobre qué cambió. El historial de
las veces que el curso se equivocó midiendo es material didáctico, no vergüenza.

---

## 6. Checklist de una medición antes de darla por buena

- [ ] La hipótesis es falsable y cabe en una línea.
- [ ] Las condiciones incluyen SDK, configuración, máquina, volumen y repeticiones.
- [ ] Se descartó el calentamiento, y se dice cuántas iteraciones.
- [ ] Se reporta mediana y p95, no promedio.
- [ ] Se reportan asignaciones y pico de memoria, no solo tiempo.
- [ ] El competidor es defendible en una revisión de código (§2.1).
- [ ] Si toca la base, el plan de consulta se midió primero (§2.2).
- [ ] El volumen sale de la historia, no de un `for` de mil (§2.3).
- [ ] Si hay empate, dice empate (§2.4).
- [ ] Lo que no se ejecutó está marcado como tal, con precio, fecha y región (§2.5).
- [ ] El veredicto declara **el umbral donde cambia la respuesta**.
- [ ] Si todavía no se ejecutó, la tabla está marcada ⏳ celda por celda, el comando que la
      produce está escrito, y el veredicto separa la expectativa del umbral por determinar (§2.6).
- [ ] La entrada quedó agregada a `BENCHMARKS.md`.
