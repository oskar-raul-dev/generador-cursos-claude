# 🏁 Fase 24 — Veredicto, defensa y qué no debió migrarse

> C# para desarrolladores Java senior · Fase 24 de 24 · Cierre
> Depende de: 23 · Habilita: ninguna
> Estilo de esta fase: **—**. No se escribe software nuevo: se revisan las decisiones con los datos delante.
> Proyecto que avanza: **los seis**, y ninguno cambia una línea.

---

## 🎯 1. Propósito

Esta fase tiene un solo trabajo y es **admitir**.

Veintitrés fases produjeron software, mediciones y decisiones. Esta las revisa con los datos en la mano y dice
en voz alta dónde Cordillera se equivocó, dónde acertó por razones que parecían malas, y **qué no debió
tocarse nunca**. Después escribe el documento que va a la junta, en el lenguaje de Clara y no en el de un
ingeniero.

Y hace algo más incómodo: **admite dos decisiones de este curso que, con los datos delante, debieron ser
otras**. No como gesto de humildad — como contenido, con la medición del propio material que las sostiene.

> 🧭 **La regla de la fase, y es la tesis del curso entero en una línea:** *un veredicto que le da la razón a
> quien lo escribe no es un veredicto.* Si al final de estas veinticuatro fases .NET moderno hubiera ganado
> todas las columnas, la conclusión correcta no sería que .NET moderno es maravilloso: sería que **el curso está
> mal escrito**, porque eligió los competidores, las condiciones y las preguntas para que ganara.

Y una advertencia de tono que es la más difícil de cumplir: aquí no hay lugar para el triunfalismo. Cordillera
no quedó modernizada. Quedó **con una parte migrada, otra envuelta, otra deliberadamente quieta, y una factura
que alguien tiene que seguir pagando**. Eso es lo que pasa de verdad en una migración, y decirlo es el último
contenido del curso.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Las **cuatro admisiones obligatorias** están escritas, con su número y sin absolver a nadie.
- [ ] Está dicho **qué parte del sistema no debió migrarse**, con nombre propio y con lo que habría costado
      migrarla.
- [ ] Está reconocido que **la migración de los pasantes de 2016 fue, en el balance, correcta**, y por qué
      juzgarla desde 2026 es la forma más común de arrogancia de ingeniero.
- [ ] Están escritas las **dos decisiones de este curso que debieron ser otras**, cada una sostenida por una
      medición o un mecanismo del propio material.
- [ ] Existe el **árbol de decisión ⚖️** de cuándo **no** usar lo que este curso enseña.
- [ ] Existe el **checklist que el lector se lleva al trabajo**, que no menciona ni una tecnología.
- [ ] `BENCHMARKS.md` está **consolidado**: las veinticuatro entradas revisadas, el estado de cada una declarado,
      y las contradicciones marcadas 🪦 — **o dicho que no hay ninguna todavía y por qué**.
- [ ] `INSTINTOS.md` está **cerrado**: sus familias completas, y las que quedaron con una sola entrada dicen por
      qué.
- [ ] El **libro de deudas** está cerrado: cada una con su estado final, incluidas **las dos que no se pagan** y
      la razón.
- [ ] El documento de defensa ante la junta existe, **en el lenguaje de Clara**, y no dice que .NET moderno haya
      ganado todo.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra

Esta fase no aplaza nada a una posterior, porque no hay posterior. Lo que declara fuera, lo declara fuera del
curso:

- **Escribir software nuevo.** Si al llegar aquí hace falta código para sostener una conclusión, la conclusión
  no estaba sostenida. Lo único que se escribe es el documento y la consolidación.
- **Los 339 formularios restantes, los 690 procedimientos y el módulo de inventario de Lima.** Nunca entraron y
  siguen sin entrar: el curso escribió lo suficiente para que las decisiones fueran reales, no para terminar la
  migración. Lo demás se cuenta como historia.
- **Un registro de modelos** (deuda de la F21) y **el certificado de Crystal Reports** (deuda de la F11). Las dos
  quedan sin pagar, con su razón escrita, y esta fase las cuenta en vez de disimularlas.
- **Los cinco tracks opcionales.** Fuera del camino obligatorio y con su razón: cada uno es un departamento real
  de Cordillera, y el track `cv` —Convivir y "el Fox" de Lima— es el que más se parece a la vida real después de
  este curso.
- **Una segunda edición.** Esta fase señala dos decisiones que debieron ser otras y **no las corrige**:
  reordenar el curso ahora rompería el material publicado, y la regla de bloqueo de contenido que este curso
  se impone existe precisamente para eso. Quedan escritas como lo que son — errores documentados.

---

## 🧠 4. Concepto mínimo

### Las cuatro admisiones

**Primera: el traslado de 2020 fue un error, y la factura lo cuantifica.**

Salió **un 30% por encima** del centro de datos, y la fase 20 lo desarmó en cuatro mecanismos: la máquina
dimensionada por el pico y pagada todos los meses; la transferencia de salida que dentro del edificio era
gratis; las cosas que venían incluidas con el hierro y pasaron a cobrarse aparte; y **nadie apagaba nada**,
porque en el centro de datos no hacía falta.

Dos de los cuatro eran inevitables en un traslado sin cambios. Uno fue la suma de cosas pequeñas. Y uno fue
falta de hábito — el servidor de pruebas que llevaba **cinco años encendido** y que apareció cuando alguien
revisó la factura línea por línea por primera vez.

Y hay que decir la parte que nadie dice: **se aprobó por miedo**. El centro de datos no tenía respaldo eléctrico
confiable y la copia de la base se guardaba en un disco externo en la oficina de al lado. Quien firmó no estaba
comprando ahorro: estaba comprando dormir. **Eso no se absuelve y tampoco se ridiculiza** — lo que faltó no fue
prudencia, fue que nadie puso las dos columnas en la misma hoja. Ni la del costo ni la del riesgo.

**Segunda: parte del sistema no debió migrarse.**

El **módulo de inventario** funciona, no cambia, y nadie ha pedido una función nueva en él en seis años.
Llevarlo a .NET 10 son meses de trabajo para llegar exactamente al mismo comportamiento. Eso no es negocio: es
orgullo de ingeniería.

**"El Fox" de Lima** lleva **veintinueve años** funcionando y puede llevar tres más. Hoy la pregunta correcta
no es cómo migrarlo: es **cuánto cuesta dejarlo quieto y qué pasa el día que el hardware falle** — y esa
respuesta, con su cifra al lado, es una decisión; sin la cifra es una omisión (fase 20).

Y hay un tercer caso que el curso produjo y conviene contar: **Crystal Reports**. La fase 11 migró **un módulo
de cuatro** y dejó los reportes en .NET Framework 4.8 porque el proveedor no da una versión moderna. Esa deuda
**no se paga nunca**, está declarada, y la forma en que se aisló —tras una interfaz, con el proceso viejo
corriendo al lado— es la parte reutilizable. *"Depende de un proveedor"* es una respuesta legítima y hay que
saber darla sin vergüenza.

**Tercera: la migración de los pasantes de 2016 fue, en el balance, correcta.**

Es la admisión que cuesta más, porque el código que produjo es el que este curso pasó veinticuatro fases
caracterizando, envolviendo y arreglando. Fechas guardadas como `char(8)`, un `PlaceholderFrom2017` que la fase
02 tuvo que convertir en un sabor de ausencia, dos `!` que la fase 09 pagó.

Y fue correcta: **fue barata, salió, y compró diez años**. Cordillera existía en 2016 y necesitaba seguir
existiendo. La alternativa que se proponía —la migración bien hecha, con presupuesto y equipo— **no estaba sobre
la mesa**, y juzgar aquella decisión desde 2026 con un presupuesto que en 2016 no existía es la forma más común
de arrogancia de ingeniero. La fase 07 empezó con esto y la 24 lo confirma: **"esto está mal hecho" casi siempre
significa "esto está fechado"**.

**Cuarta: el rendimiento no decidió nada.**

La fase 23 implementó el mismo endpoint dos veces, con su declaración de defendibilidad publicada, y **varias
columnas quedaron en empate**. Al volumen de Cordillera, la plataforma no es una razón para elegir plataforma.

Lo que decidió fue lo de siempre: 700 procedimientos almacenados que nadie ha leído, unas licencias pagadas, y
**un compañero que sabe C# y va a sostener esto cuando tú te vayas**. Ninguna de las tres aparece en una tabla
de percentiles.

Y de ahí sale la frase que resume el curso: **el documento de tres páginas del día once no estaba equivocado en
los hechos, estaba equivocado en lo que importaba.**

### Las dos decisiones de este curso que debieron ser otras

No son un gesto. Cada una está sostenida por algo que el propio material produjo, y las dos tienen la misma
forma: **el curso ordenó las fases por tema cuando debió ordenarlas por dependencia de datos**.

> ⚖️ **Primera: el sistema heredado debió llegar antes.**
>
> **Qué se hizo.** El bloque A —tipos, nulabilidad, LINQ, recursos, `async`, memoria— se escribió **sin base de
> datos**. La base llega en la fase 07.
>
> **La evidencia, y es del propio material.** La fase 03 enseña evaluación diferida y su alcance pedía comparar
> `IEnumerable`, `IQueryable` y SQL directo — **y dos de los tres competidores no existían todavía**. Hubo que
> declarar un acoplamiento (`propuesta-fases-y-alcance.md` §8.1) y aplazar media medición a la fase 09. Y no fue
> el único síntoma: la fase 06 necesitó **inventar una función de búsqueda** `Func<EditionId, ImprintCode?>`
> porque una fila de ventas no puede llevar el sello, algo que con el esquema real delante habría sido obvio
> desde la fase 01.
>
> **Qué debió hacerse.** El sistema heredado —el esquema, el generador de datos— **antes del bloque A**. No las
> pruebas de caracterización, que sí van donde están: solo la base y sus datos sucios, como material de lectura.
> Entonces `Money`, `LegacyDate` y `SalesRow` habrían nacido contra el esquema que tienen que representar, y la
> fase 03 habría medido sus tres competidores en su sitio.
>
> **Por qué se hizo así, y la razón no era mala:** para que el lector no tuviera que instalar SQL Server en la
> primera semana. Es una preocupación legítima de arranque, y **resultó más caro que el problema que evitaba**.

> ⚖️ **Segunda: el veredicto del escritorio debió ir después de la web.**
>
> **Qué se hizo.** La fase 14 compara cuatro opciones de interfaz **y la cuarta no existía**: la web nace en la
> fase 18, cuatro fases después.
>
> **La evidencia, y es la más clara del curso.** Hubo que inventar una convención entera —**🔜**, "el competidor
> no existe todavía"— **que se usa exactamente una vez en veinticuatro entradas**, más un mecanismo de
> actualización retroactiva, más la regla de que la tabla se consolida en `BENCHMARKS.md` para que una fase no
> reescriba el documento publicado de otra. Tres piezas de maquinaria para una celda. **Cuando una excepción
> necesita su propia infraestructura, el orden es el que está mal**, no la excepción.
>
> Y hay un segundo síntoma, peor: el veredicto provisional de la fase 14 se publicó **sabiendo que la columna
> que faltaba gana el criterio 4 por definición** —la web no se instala en noventa equipos—. Un lector que
> cerrara el bloque C y aplicara ese veredicto en su trabajo estaría decidiendo con una tabla a la que le falta
> la columna que más pesa en despliegue.
>
> **Qué debió hacerse.** El bloque de escritorio en tres fases donde está, **y el veredicto de la 14 al final
> del bloque D**, después de la web. Una fase de veredicto no tiene por qué estar pegada a las fases que
> construyen los competidores.
>
> **Por qué se hizo así:** porque cerrar un bloque con su veredicto es elegante y pedagógicamente cómodo. **Y la
> elegancia le ganó a la evidencia**, que es exactamente el error que este curso lleva veinticuatro fases
> señalando en otros.

📝 Hubo una tercera candidata y se queda fuera con su razón: **fusionar los dos proyectos de IA en una sola
fase** (la 22). El riesgo era que se leyera como dos fases pegadas, y el criterio de fusión —**comparten el
aparato de evaluación**— resultó ser el contenido de la fase y no una excusa para ahorrar espacio. Se queda
como estaba.

### 🪞 El reflejo que queda al final

Los cuarenta y tantos reflejos de `INSTINTOS.md` son casos particulares de uno, y esta fase lo nombra:

```text
❌ El reflejo, y con veinticuatro fases encima todavía cuesta:
   "Lo que está viejo hay que arreglarlo. Lo que está mal hecho hay que rehacerlo.
    Si tengo la capacidad técnica de mejorarlo, mejorarlo es lo correcto."
```

**Por qué falla:** porque confunde **poder** con **deber**, y omite la única pregunta que importa: *¿qué compra
esto, y a cambio de qué?* El módulo de inventario se puede migrar. "El Fox" se puede reemplazar. Los 690
procedimientos se pueden reescribir. Nada de eso está en duda, y nada de eso es un argumento.

**Lo que se escribe en su lugar** es la pregunta que ordenó el curso desde la fase 07: **¿esto se migra, se
envuelve o se deja quieto?** — con la adición que la fase 20 le hizo y que la vuelve completa: **"se deja quieto"
exige la cifra al lado**. Con cifra es una decisión; sin cifra es una omisión con buena prensa.

> ⚰️ **La autopsia final, y es del proyecto entero: la migración que se detuvo al 60%.**
>
> **El caso, que no es el de Cordillera y es el de la mitad de las empresas que hacen esto:** se migra lo
> interesante —el catálogo, el API, la web—, se deja lo aburrido —los reportes, el inventario, el módulo de la
> sucursal—, y se declara terminado. Dos años después hay **dos sistemas en producción**, dos runtimes, dos
> formas de desplegar, dos sitios donde buscar un bug, y **el doble de coste de operación** para un negocio que
> no creció al doble.
>
> **Cómo se llega:** sin una sola mala decisión. Cada paso fue razonable. Lo que faltó fue **decidir el final
> antes de empezar**: qué se migra, qué se envuelve, qué se deja quieto **y con qué cifra**, y qué significa
> "terminado".
>
> **El costo, medido con el material de este curso:** la fase 20 lo tiene en una fila — la máquina virtual
> **no se apaga** mientras un módulo siga en .NET Framework 4.8, así que la arquitectura moderna no la elimina:
> **la duplica**. El ahorro mensual calculado sobre el supuesto de apagarla es el ahorro que no existe.
>
> **La defensa:** el estado final escrito **el primer día**, con las tres categorías y sus cifras, y revisado
> cada trimestre. Cordillera lo tiene ahora — es el entregable del miniproyecto de esta fase — y no lo tenía
> cuando tú llegaste.

### 🩻 Esto sí funciona igual, y es lo último que el curso dice sobre eso

Con veinticuatro fases de perspectiva, el reparto quedó así: **casi todo tu criterio se transfirió, y casi
ninguno de tus reflejos.**

Lo que se transfirió completo: diseño de dominio, modelado de datos, SQL, pruebas, transacciones, HTTP,
seguridad, observabilidad, contenedores, costos, y el criterio de qué merece una alerta. Es la mayor parte de lo
que sabes, y por eso este curso pudo ser de veinticuatro fases y no de sesenta.

Lo que no se transfirió fueron **las garantías**: que un tipo sea referencia, que una colección se pueda
recorrer dos veces, que un `finally` alcance, que la transacción se abra sola, que el estado de la sesión viva
en el servidor, que el contexto se propague. Cada reflejo de `INSTINTOS.md` es un hábito bueno de Java apoyado
en una garantía que en .NET no existe o existe de otra forma.

**Y la conclusión es mejor de lo que parece:** aprender esta plataforma no fue aprender a programar otra vez.
Fue aprender **dónde están las garantías** — un mapa, no un idioma.

### 📖 El diccionario que no es de sintaxis

Los veinticuatro 📖 del curso mapearon APIs. Este mapea criterio, y es el que sobrevive a la próxima versión de
todo:

| Lo que te enseñaron a preguntar | Lo que este dominio exige preguntar | Por qué cambia |
|---|---|---|
| ¿Qué arquitectura es la correcta? | **¿Cuál puede mantener la gente que se queda?** | La plataforma que tu único compañero no domina dura lo que duras tú |
| ¿Cómo lo reescribo bien? | **¿Esto se migra, se envuelve o se deja quieto — y cuánto cuesta cada una?** | Las tres son legítimas. La tercera necesita cifra (F20) |
| ¿Qué es más rápido? | **¿La diferencia importa a mi volumen?** | Al volumen de Cordillera, varias columnas empataron (F23) |
| ¿Está bien hecho? | **¿Está fechado?** | Casi todo lo que parece mal hecho fue razonable con el presupuesto de su año (F07) |
| ¿Cuánto tarda? | **¿Se puede reproducir el número de hace ocho meses?** | Reproducible le ganó a rápido en la F17, y era lo que se compraba |
| ¿Cómo lo automatizo? | **¿Cuál de los dos errores es invisible en producción?** | Un sistema cuyo peor error no se observa no puede tener autonomía (F22) |
| ¿Cuánto cuesta el servidor? | **¿Qué línea crece cuando al negocio le vaya bien?** | Las tres deudas de la F20 crecen con el éxito y no tienen síntoma técnico |
| ¿Quién tiene razón? | **¿Con qué número lo sabríamos?** | Y si la respuesta es "con ninguno", eso también es un resultado |

---

## 💻 5. Lo que se escribe en esta fase

No hay software nuevo. Lo que se escribe son tres artefactos, y los tres son de criterio.

### 5.1 El árbol de decisión ⚖️ — cuándo NO usar lo que este curso enseña

Se lee de arriba abajo, y cada pregunta se hace solo si la anterior te dejó seguir: un ⛔ termina el
recorrido ahí, y la única salida verde está al fondo.

```mermaid
flowchart TD
    Q0{"¿Tienes un sistema heredado<br/>que funciona y da dinero?"}
    A0["Este curso te sirve a medias. Las fases 00-06 y 15-20 sí;<br/>el resto resuelve un problema que no tienes. Y ojo con el<br/>consejo de un curso de migración aplicado a un sistema nuevo:<br/>te va a hacer conservador donde puedes permitirte no serlo."]
    Q1{"¿Alguien pide funciones<br/>nuevas en él?"}
    A1["⛔ NO LO MIGRES. Es el módulo de inventario. Es «el Fox».<br/>Envuélvelo si necesitas leerlo, y escribe cuánto cuesta<br/>dejarlo quieto. Migrarlo es orgullo de ingeniería<br/>(F24, admisión 2)."]
    Q2{"¿Cuánta gente lo va a mantener<br/>cuando tú no estés?"}
    A2["⛔ NO adoptes nada que ellas no dominen. Ni Kubernetes (F20),<br/>ni un framework de JavaScript (F18), ni Semantic Kernel (F22),<br/>ni microservicios. El costo de operación sale de las mismas<br/>manos que arreglan el cierre nocturno."]
    B2["Los umbrales de este curso son demasiado<br/>conservadores para ti. Súbelos, y quédate<br/>con la metodología."]
    Q3{"¿Sabes qué hace el sistema,<br/>con pruebas que lo demuestren?"}
    A3["⛔ NO TOQUES NADA TODAVÍA. Caracterizar primero (F08).<br/>Una migración sin red es una reescritura con otro nombre,<br/>y la reescritura es lo que Clara rechazó en 2021 con razón."]
    Q4{"¿Tienes la factura de lo que<br/>pagas hoy, desglosada?"}
    A4["⛔ NO PROPONGAS NADA. Sin línea base no hay comparación,<br/>y sin comparación tu propuesta es el traslado de 2020<br/>otra vez (F20)."]
    Q5{"¿Tu decisión depende de que una plataforma<br/>sea más rápida que otra?"}
    A5["⚠️ Mídelo antes de creerlo, con la declaración de<br/>defendibilidad publicada (F23). Es probable que empate<br/>a tu volumen — y si empata, tu decisión dependía de<br/>otra cosa y conviene saber de qué."]
    B5["✅ Entonces estás decidiendo por las razones<br/>correctas: la gente, el dominio, el dinero<br/>y el riesgo. Adelante."]

    Q0 -- NO --> A0
    Q0 -- SÍ --> Q1
    Q1 -- "NO, y no cambia desde hace años" --> A1
    Q1 -- "SÍ, y duele cada vez" --> Q2
    Q2 -- "Una o dos personas" --> A2
    Q2 -- "Un equipo con área de plataforma" --> B2
    B2 --> Q3
    Q3 -- NO --> A3
    Q3 -- SÍ --> Q4
    Q4 -- NO --> A4
    Q4 -- "SÍ: marca cada línea con cómo crece" --> Q5
    Q5 -- SÍ --> A5
    Q5 -- NO --> B5
```

### 5.2 El checklist que te llevas al trabajo

```markdown
<!-- No menciona ni una tecnología, y eso es a propósito: es lo único de este curso que
     va a seguir sirviendo cuando .NET 10 sea el runtime viejo de alguien. -->

## Antes de proponer una migración
- [ ] Tengo la factura de hoy, desglosada, con cada línea marcada por cómo crece.
- [ ] Escribí el estado final: qué se migra, qué se envuelve, **qué se deja quieto y con qué cifra**.
- [ ] Escribí qué significa "terminado", y no es "todo migrado".
- [ ] Sé quién va a mantener esto cuando yo no esté, y se lo pregunté.
- [ ] Sé qué se rompe si no hago nada, y cuándo. Si la respuesta es "nada, por ahora", lo digo.

## Antes de tocar código heredado
- [ ] Puedo reproducir su comportamiento actual con pruebas, incluidos sus errores.
- [ ] Sé qué parte de lo que parece mal hecho está simplemente fechada.
- [ ] Sé de quién es el arreglo de cada cosa rara: del esquema, de 2017, o del negocio.
- [ ] Cada cruce de generación está en un sitio identificable, no repartido.

## Antes de afirmar que algo es mejor
- [ ] El competidor lo configuré yo como lo defendería en una revisión.
- [ ] Publiqué qué configuré en cada lado, con sus valores. Alguien puede criticarlo.
- [ ] Miré la dispersión antes de la mediana, y si se solapan digo **empate**.
- [ ] Si toca la base, miré el plan de consulta **antes** que el código.
- [ ] La diferencia importa a mi volumen, no al del benchmark que leí.

## Antes de tomar un atajo
- [ ] Está declarado: dónde se paga y en qué fase. Con fecha, no "más adelante".
- [ ] Sé si tiene síntoma técnico. Si no lo tiene, sé en qué línea de la factura aparece.
- [ ] Sé si crece con el uso. Si crece, sé qué pasa cuando al negocio le vaya bien.

## Antes de automatizar una decisión
- [ ] Sé cuál de los dos errores es más caro.
- [ ] Sé cuál de los dos es **invisible en producción**. Si el caro es el invisible, no automatizo.
- [ ] El sistema puede decir "no sé", y eso cuenta como acierto en mi evaluación.
- [ ] La persona que decide hoy vio la herramienta y la usaría.

## Antes de decir que terminaste
- [ ] Puedo reproducir cualquier número que el sistema produjo hace ocho meses.
- [ ] Alguien que no soy yo desplegó una corrección, solo, y funcionó.
- [ ] La factura del mes que viene la revisa una persona con nombre.
- [ ] Lo que quedó sin hacer está escrito, con su riesgo y su cifra.
```

---

## 📏 6. Medición — no produce ninguna, consolida las veinticuatro

Esta es la única fase del curso sin medición propia, y está declarado desde el alcance: **su trabajo es
consolidar las veinticuatro anteriores** y comprobar que el archivo cumple sus propias reglas. Un documento de
honestidad que nadie verifica se degrada igual que cualquier otro.

```csharp
// src/modern/Cordillera.Bench.Cli/Comandos/ConsolidateCommand.cs
//
// Veinticuatro entradas escritas a lo largo de veinticuatro fases, y tres reglas que comprobar:
// que ninguna cite una fila sin ejecutar, que las contradicciones estén marcadas, y que no quede
// ninguna celda 🔜 sin llenar.
public sealed class ConsolidateCommand
{
    public ConsolidationReport Run(string benchmarksPath)
    {
        IReadOnlyList<BenchmarkEntry> entries = BenchmarkParser.Parse(benchmarksPath);

        return new ConsolidationReport
        {
            Total = entries.Count,

            // Cuántas siguen sin ejecutar. En el curso tal como se publica son TODAS, y eso es un
            // hecho que hay que declarar en vez de esconder: las tablas están escritas completas
            // —hipótesis, condiciones, competidor, comando— y los números los pone quien las corre.
            Pending = entries.Count(e => e.State is EntryState.NotRun),

            // Y las que citan una fila ⏳ o 🔜 como si fuera dato. Esto tiene que ser CERO: es la
            // regla que el archivo se impone a sí mismo, y la única forma de que veinticinco fases
            // no arrastren un número inventado.
            IllegalCitations = entries.SelectMany(e => e.Citations)
                                      .Where(c => c.Target.State is not EntryState.Executed)
                                      .ToList(),

            // Las contradichas por una medición posterior. El historial de los errores del curso es
            // material didáctico: la entrada vieja no se borra, se marca 🪦 con su puntero.
            Superseded = entries.Where(e => e.State is EntryState.Superseded).ToList(),

            // Y las celdas 🔜, que además de no citarse tienen que nombrar la fase que las llena.
            // Al cerrar el curso deberían ser cero: la F18 llenó la única que hubo.
            UnfilledFutureCells = entries.SelectMany(e => e.Cells)
                                         .Where(c => c.Marker is Marker.Future)
                                         .ToList(),
        };
    }
}
```

> 🪦 **Y el resultado de correrlo sobre el curso tal como se publica, dicho sin adornos: veinticuatro entradas,
> veinticuatro sin ejecutar, cero contradicciones marcadas.**
>
> No hay ni un 🪦 en `BENCHMARKS.md`, y **no es porque el curso no se haya equivocado**: es porque **nada se ha
> ejecutado**. Las veinticuatro tablas están escritas completas —hipótesis, condiciones, competidores, el comando
> exacto, las filas nombradas— y **los números los pone quien las corre**. Ninguna cifra de este curso es
> inventada porque ninguna cifra de este curso existe.
>
> Eso tiene una consecuencia honesta que hay que escribir aquí y no en una nota al pie: **los veredictos de las
> veinticuatro mediciones son expectativas, no resultados**, y están marcados como tales. La primera vez que
> aparezca un 🪦 va a ser porque **tú** ejecutaste dos mediciones y la segunda contradijo a la primera. Cuando
> pase, la vieja no se borra.
>
> Y la verificación que sí pasó, que es la que protegía al curso de mentirse: **cero citas ilegales**. Ninguna de
> las veinticuatro fases usa una fila ⏳ como argumento de una decisión, y la única columna 🔜 que existió —la
> cuarta del veredicto del escritorio, nueve celdas entre la tabla y sus respaldos— la llenó la fase 18. Que esa verificación dé cero es lo que hace
> que las tablas vacías sean un encargo y no un adorno.

---

## 🧱 7. Miniproyecto — el documento de defensa ante la junta

> 📝 Este miniproyecto **no tiene código**, y es el único del curso. Lo que se entrega es un documento de cuatro
> páginas y una conversación de cuarenta minutos. Si te parece menos exigente que los otros veintitrés,
> escríbelo y después decide.

**El encargo**

De Clara Villegas, presidenta, por correo, un jueves:

> *"La junta es el 14. Quiero cuatro páginas y voy a leerlas yo antes.*
>
> *Necesito saber: qué migramos, qué no, cuánto costó, cuánto cuesta al mes de ahora en adelante, qué queda sin
> hacer y con qué riesgo. En español, sin nombres de tecnologías salvo que sean imprescindibles, y con los
> números que yo pueda defender si don Fernando pregunta de dónde salen.*
>
> *Y te pido una cosa más, que te va a parecer raro que pida: **no me escribas un documento donde todo salió
> bien**. Si me lo escribes así, no te voy a creer ni lo bueno. Dime en qué nos equivocamos y qué harías
> distinto. Eso es lo que me va a permitir aprobarte el presupuesto del año que viene."*

**Por qué duele**

Porque el instinto es escribir un informe de logros, y Clara acaba de decir explícitamente que ese documento no
le sirve. Está pidiendo un informe **que se pueda creer**, y la credibilidad se compra con las cosas que
salieron mal.

Y duele por la última frase del encargo, que no es una cortesía: **"eso es lo que me va a permitir aprobarte el
presupuesto"**. La honestidad aquí no es una virtud moral, es el mecanismo por el que se financia el trabajo del
año siguiente. Un informe triunfal produce una pregunta incómoda en la junta que nadie puede contestar, y
después de eso no hay presupuesto.

**Datos de entrada**

Todo lo que produjeron las veinticuatro fases:

| Qué | De dónde |
|---|---|
| Las mediciones | `BENCHMARKS.md`, 24 entradas — **todas ⏳ hasta que las corras** |
| Las deudas con su estado | el libro de `propuesta-fases-y-alcance.md` §7.1 |
| La factura | fase 20, con los cuatro mecanismos del 30% de 2020 |
| El veredicto del escritorio | fase 14, con la cuarta columna que llenó la 18 |
| El duelo | fase 23, con sus empates |
| Lo que no se migró | inventario, "el Fox", Crystal Reports, 690 procedimientos, 339 formularios |
| Los reflejos | `INSTINTOS.md` |
| La audiencia | Clara (abogada), don Fernando (firma), Gustavo, Ximena, Duván |

**Criterios de aceptación**

1. **Cuatro páginas.** Si te salen ocho, no terminaste: elegir qué dejar fuera es parte del trabajo.
2. Las **cuatro admisiones** están, y la del traslado de 2020 **no absuelve y no acusa**.
3. Está escrito **qué no se migró, con nombre propio**, y qué habría costado migrarlo.
4. Está reconocido que **la migración de 2016 fue correcta en el balance**, en un lenguaje que no suene a
   condescendencia hacia quien la hizo.
5. Cada cifra tiene **de dónde sale**, en una línea, porque don Fernando va a preguntar.
6. Está el **costo mensual de ahora en adelante** y **qué líneas crecen si el negocio crece**.
7. Está lo que queda sin hacer, **con su riesgo y con su cifra** — incluidas las dos deudas que no se pagan.
8. **No dice que .NET moderno haya ganado todo.** Si tu borrador lo dice, está mal hecho, y esta es la última
   línea del curso.
9. Se lo leíste a alguien que no es ingeniero **antes** de entregarlo, y cambiaste lo que no entendió.
10. Los tres artefactos de la sección 5 están completos: el árbol ⚖️, el checklist, y la consolidación con su
    resultado declarado.

**Restricciones de estilo y alcance**

Sin código. Sin diagramas de arquitectura —a la junta no le sirven—. Sin nombres de tecnologías salvo los
imprescindibles. Y una restricción que es el punto: **cada afirmación comparativa remite a una medición
concreta**, y si esa medición está en ⏳, **el documento lo dice**. Un informe a una junta que presenta una
expectativa como un resultado es exactamente la conversación de 2020 volviendo a empezar.

**La trampa**

Vas a escribir el informe y te va a salir bien. Ordenado, con sus números, con su recomendación. Y al releerlo
vas a notar que **todas las decisiones que se cuentan son las que salieron bien**, y las que no aparecen en
forma de "aprendizajes" — un párrafo genérico, en pasiva, sin cifra.

Esa es la trampa, y es la última del curso porque es la más difícil de ver: **no se falsea nada, se elige qué
contar**. Es el mismo defecto que la fase 23 encontró en los benchmarks —el sesgo no está en los números, está
en cómo armaste lo que mides— aplicado a un documento en prosa.

La señal de que caíste: busca en tu borrador la palabra **"aprendimos"**. Si está en una frase sin número y sin
sujeto, ahí hay algo que no te atreviste a escribir.

Y cuando lo encuentres, escribe las dos cosas de siempre: **cuál fue la decisión que estabas suavizando**, y
**cuánto costó**. Si la segunda no la sabes, ahí tienes el trabajo real del miniproyecto.

<details><summary>Pista 1 — el enfoque</summary>

Escribe primero la página de lo que no se hizo. Es la que Clara va a leer con más atención y la que más te
cuesta, así que hacerla primero evita que se convierta en un párrafo al final.

Para las cuatro admisiones, la forma que funciona es **mecanismo + número + qué se hace ahora**. "Se aprobó por
miedo" es cierto y solo; "se aprobó porque el centro de datos no tenía respaldo eléctrico y la copia de la base
estaba en un disco en la oficina de al lado, y eso nadie lo había costeado" es la misma frase con la que se
puede decidir algo.

Y para el número de 2020, no lo presentes como un error de quien firmó: preséntalo como **dos columnas que nunca
estuvieron en la misma hoja**. Es más exacto y además es verdad.

</details>

<details><summary>Pista 2 — la herramienta</summary>

No hay herramienta. Hay una lectura en voz alta a alguien que no programa, y un cronómetro: **si tardas más de
ocho minutos en leer las cuatro páginas, son más de cuatro páginas**.

Lo que sí conviene tener abierto mientras escribes: `BENCHMARKS.md` para no citar nada que esté en ⏳ sin
decirlo, y el libro de deudas de §7.1 para que ninguna se quede sin estado final.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```markdown
# Sistema SIGE · Estado y recomendación · <fecha>

## 1. Dónde estábamos (media página)
   El sistema, su edad, y las dos cosas que costaban dinero todos los meses.

## 2. Qué hicimos y qué compró cada cosa (una página)
   Por resultado de negocio, no por fase. Cada cifra con su origen en una línea.

## 3. Qué NO hicimos, a propósito (una página)
   El inventario. "El Fox". Los reportes. Los 690 procedimientos.
   Con lo que habría costado cada uno y con lo que cuesta dejarlo quieto.

## 4. En qué nos equivocamos (media página)
   El traslado de 2020, con su mecanismo. Y lo que yo haría distinto.

## 5. Qué cuesta de ahora en adelante (media página)
   El mensual, y qué líneas crecen si vendemos más.

## 6. Qué queda pendiente y con qué riesgo (media página)
   Incluidas las dos deudas que no se pagan, y por qué.
```

</details>

**Cómo se entrega**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- consolidate --input BENCHMARKS.md
```

```bash
git tag -a mini-24 -m "Mini F24: documento de defensa en 4 paginas · 4 admisiones escritas · <N> cosas declaradas sin migrar con su cifra · 2 deudas sin pagar con su razon · leido a alguien que no es ingeniero"
```

---

## 🧪 8. Ejercicios (22)

> 📝 Los de esta fase no tienen código y **no son más fáciles**. Casi todos se responden con un documento, una
> tabla o una conversación, que es la forma que tienen los problemas de verdad.

**🟢 Fácil (1–5)**

1. Escribe las cuatro admisiones en un párrafo cada una, con su mecanismo y su número.
2. Lista todo lo que **no** se migró y ponle al lado lo que habría costado. Si no lo sabes, estímalo y di cómo.
3. Corre la consolidación de `BENCHMARKS.md` y declara el resultado: cuántas ⏳, cuántas 🪦, cuántas citas
   ilegales.
4. Revisa el libro de deudas y comprueba que cada una tiene estado final. Las dos sin pagar, con su razón.
5. Lee el checklist de la sección 5.2 y marca lo que **hoy** podrías firmar en tu trabajo real. Cuenta las
   casillas vacías.

**🟡 Intermedio (6–12)**

6. Escribe el documento de defensa completo, cuatro páginas, y léelo en voz alta con un cronómetro.
7. Léeselo a alguien que no programa y anota las tres primeras cosas que no entendió. Reescríbelas.
8. Busca la palabra "aprendimos" en tu borrador y convierte cada aparición en una decisión con nombre y cifra.
9. Recorre `INSTINTOS.md` y marca los reflejos que **todavía** tienes. Es una lista honesta y es para ti.
10. Escribe el árbol ⚖️ de la sección 5.1 **para tu propio sistema**, no para Cordillera, con tus umbrales.
11. Toma una decisión técnica que hayas tomado este año en tu trabajo y pásala por el árbol. Anota si cambia.
12. Elige las tres mediciones de `BENCHMARKS.md` que te servirían más en tu trabajo y **ejecútalas**. Son las
    primeras cifras reales de este curso.

**🟠 Difícil (13–18)**

13. **Diagnóstico del propio curso.** Encuentra una tercera decisión de este curso que debió ser otra, y
    sosténla con una medición o un mecanismo del propio material. La sección 4 tiene dos; hay más.
14. **Decisión.** Con todo delante, ¿Cordillera debería seguir migrando o parar aquí? Escribe la recomendación
    con su cifra y su riesgo, y defiéndela contra la respuesta contraria.
15. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los **690 procedimientos** restantes. Y ahora la
    pregunta tiene su forma completa: si se dejan quietos, **con qué cifra** y qué pasa el día que alguien tenga
    que cambiar una regla de negocio que vive ahí.
16. **Decisión.** "El Fox" de Lima: veintinueve años funcionando. Decide, y escribe qué pasa el día que el
    hardware falle — porque va a fallar.
17. Estima qué habría costado hacer **bien** la migración de 2016, con el presupuesto de 2016. Si la respuesta es
    "no era posible", esa es la defensa de los pasantes y ahora tiene número.
18. Escribe el correo que le mandarías a quien aprobó el traslado de 2020, **sin acusarlo**, explicando los
    cuatro mecanismos. Es más difícil de lo que parece y es exactamente la habilidad que hace falta.

**🔴 Muy difícil (19–22)**

19. **Adversarial.** Escribe la versión triunfal del documento de defensa — donde todo salió bien— sin mentir en
    ninguna cifra. Después escribe qué pregunta de la junta la desarma. Guárdalas las dos.
20. **Adversarial.** Construye el argumento más fuerte que puedas **contra** la tesis de este curso: que lo
      correcto era reescribir todo en la plataforma que ya dominabas. Con los datos del curso, no contra ellos.
      Si te sale convincente, esa es la parte del curso que hay que revisar.
21. **Diseño.** Escribe el plan de los próximos doce meses de Cordillera con presupuesto, incluyendo
    explícitamente **qué se deja quieto y con qué cifra**, y qué significa "terminado". Es el artefacto que no
    existía cuando llegaste.
22. **Defiende una decisión ante quien no es ingeniera.** La última del curso, y es la de verdad: presenta el
    documento en cuarenta minutos ante tres personas que no programan, y contesta sus preguntas. Anota cuál no
    pudiste contestar. **Esa es tu siguiente fase.**

**🔥 Opcionales**

- Ejecuta las veinticuatro mediciones. Publica tus números, marca los 🪦 que aparezcan, y **manda el enlace**: un
  curso con las tablas llenas por un lector es mejor curso que este.
- Haz el track `cv` —Convivir y "el Fox"—. Es el que más se parece a tu vida real después de este curso, y por
  eso no es opcional del todo.
- Vuelve a la fase 00 y relee su 🪞. Si te parece obvio, el curso funcionó; si te parece injusto, mejor todavía.

---

## 📚 9. Referencias

**Documentación oficial**

No hay. Esta fase no enseña ninguna API, y una lista de enlaces para adornar el cierre sería exactamente el tipo
de cosa que este curso pasó veinticuatro fases quitando.

**Libros / artículos**

- *Working Effectively with Legacy Code* (Michael Feathers) — el libro que sostiene las fases 08 a 10. Su
  definición de código heredado —*código sin pruebas*— es la que ordenó el bloque B. **Verifica la edición antes
  de citarlo.**
- *Refactoring* (Martin Fowler), en lo que tiene de disciplina de pasos pequeños con la red puesta. Lo que este
  curso le añade es el caso donde **la respuesta correcta es no refactorizar**.
- *Cloud FinOps* (Storment y Fuller) — el libro que le faltaba a Cordillera en 2020, y la idea que la fase 20
  convirtió en regla: **el costo es responsabilidad de quien construye**.
- *Systems Performance* (Brendan Gregg) — la metodología de medir sin engañarse, que es la columna vertebral de
  `BENCHMARKS.md`.
- Y el material que **no** existe y que este curso echó de menos: casi no hay literatura sobre **decidir no
  migrar**. Hay mucha sobre cómo migrar y bastante sobre por qué reescribir es mala idea, y muy poca sobre cómo
  costear, defender y revisar la decisión de dejar un sistema quieto. Si encuentras algo bueno, es un hueco real.

> ⚠️ La advertencia final, y aplica a todo lo que leas después de este curso: **casi todo el material de
> migración está escrito por quien vendió la migración**. Los casos de éxito se publican, los que se detuvieron
> al 60% no. Eso sesga la literatura entera hacia migrar más de lo que conviene, y es la razón por la que este
> curso mide en vez de recomendar.

**Orden de lectura sugerido:** ninguno. Si llegaste aquí, ya sabes qué te falta — y el ejercicio 22 te va a
decir exactamente qué es.

---

## 🚀 10. Cierre

Cordillera no quedó modernizada.

Quedó con el catálogo migrado y medido, un cierre de regalías reanudable y auditable, un back-office nuevo, un
escritorio que se eligió con cinco criterios y no con moda, observabilidad que cruza el borde 🧬, una factura
entendida, y **una parte del sistema deliberadamente quieta con su cifra al lado**. Quedó también con dos deudas
que no se pagan, un módulo en un runtime de 2019 porque un proveedor no da otra opción, y una máquina virtual que
no se apaga.

Eso es lo que pasa de verdad. Una migración que termina con todo migrado y nada pendiente no es un caso de
éxito: es un caso mal contado.

Y lo que te llevas no es C#. C# lo puedes aprender de la documentación, y dentro de tres años la mitad de las
APIs de este curso van a haber cambiado. Lo que te llevas es **un mapa de dónde están las garantías** —cuáles de
tus reflejos de once años seguían valiendo y cuáles se apoyaban en algo que aquí no existe— y una pregunta que
ordena el trabajo: **¿esto se migra, se envuelve o se deja quieto, y cuánto cuesta cada una?**

Las cifras de las veinticuatro mediciones siguen en ⏳ y eso es deliberado: las tablas están escritas completas y
los números los pones tú. Ninguna cifra de este curso es inventada porque ninguna existe todavía. El primer 🪦
va a aparecer cuando ejecutes dos y la segunda contradiga a la primera, y cuando pase, la vieja no se borra.

Del duelo salió un empate en varias columnas, y el competidor gana algo estructural en el modelo de concurrencia
— dicho sin rodeos porque era verdad. El documento de tres páginas que escribiste el día once no estaba
equivocado en los hechos: estaba equivocado en lo que importaba. Y saber distinguir esas dos cosas es
probablemente lo más útil que este curso podía enseñarte.

> **Y la última línea, que es la única conclusión que el curso se permite:**
>
> **Si al llegar aquí .NET moderno hubiera ganado todas las columnas, este curso estaría mal escrito.** No
> porque la plataforma no sea buena — es muy buena y por eso Cordillera la eligió. Porque una comparación en la
> que el autor gana siempre no es una comparación: es un folleto. Las veinticuatro mediciones están escritas para
> que las tres respuestas fueran posibles, el competidor lo configuró alguien que lo defiende, y varias columnas
> quedaron en empate. **Eso es lo que hace que valga la pena creerle a las que no.**

> **La señal de que quedó bien** —y esta fase, que revisa las veinticuatro anteriores, tiene la suya—:
> *"Clara leyó las cuatro páginas, se detuvo en la página de lo que no hicimos, y en la junta don Fernando
> preguntó por el módulo de inventario. La respuesta ya estaba escrita, con su cifra. Aprobaron el presupuesto
> del año que viene sin pedir que migráramos nada más."*
>
> Y si además ocurre esto, quedó mejor de lo que el curso pedía: **que alguien del equipo use el árbol de
> decisión de la sección 5.1 en un proyecto que no es Cordillera, y que la respuesta sea "no lo toques"**.

> 🏷️ **El último tag.** Con el checklist de la sección 2 en verde, el documento leído a alguien que no programa y
> `git status` limpio:
>
> ```bash
> git tag -a fase-24 -m "F24 cerrada. Curso completo:
> - las cuatro admisiones escritas, sin absolver y sin acusar
> - lo que NO debio migrarse, con nombre propio y con su cifra
> - la migracion de los pasantes de 2016: correcta en el balance
> - DOS decisiones de este curso que debieron ser otras, sostenidas con su propio material
> - arbol de decision de cuando NO usar lo que el curso ensena
> - checklist sin una sola tecnologia mencionada
> - BENCHMARKS consolidado: 25 entradas, 25 en ciernes, 0 citas ilegales
> - INSTINTOS cerrado
> - y ninguna columna donde .NET moderno gane todo"
> ```
>
> **Y el último diff, que es el índice del curso entero:**
>
> ```bash
> git log --oneline --decorate fase-00..fase-24
> git tag -l 'fase-*' 'mini-*'
> ```
>
> Cincuenta tags: veinticinco fases y veinticinco miniproyectos. Cada mensaje de `mini-` lleva un número
> de medición adentro, así que **ese listado es la tabla de resultados del curso**, escrita por ti y no por mí.
> Si algún mensaje lleva un número que no ejecutaste, ese tag es el único sitio donde este curso permitió
> mentirse — y solo tú lo sabrías.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura. Los últimos.*

- **`INSTINTOS.md` — cerrarlo de verdad.** Falta: la familia nueva ***medir y comparar*** que la F23 pide
  (competidor de paja, mediana sin dispersión), las tres entradas de la F22, y **el reflejo final de esta fase**
  —*confundir poder con deber*— que conviene poner al principio del documento y no al final, porque es el que
  contiene a todos los demás. Y una nota de cierre: **las familias con una sola entrada se quedan así y dicen por
  qué**; rellenarlas para que quedaran parejas sería inventar reflejos.
- **`BENCHMARKS.md` — la sección de consolidación**, que es lo único que le falta al archivo: las 25 entradas con
  su estado, el resultado de la verificación (25 ⏳, 0 🪦, 0 citas ilegales, 0 celdas 🔜 sin llenar), y **la
  explicación de por qué no hay ningún 🪦** — que es el dato más honesto del archivo y el más fácil de leer mal.
  Va al principio, después de las siete reglas, no al final.
- **Las siete reglas de honestidad**: el archivo nació con cinco, la F20 agregó la sexta (precio publicado,
  fuente, fecha y región) y la F23 la séptima (declaración de defendibilidad). Conviene que el título y el índice
  digan **siete** y que la consolidación las liste juntas, porque tres de ellas nacieron de necesidades
  concretas y esa procedencia es material.
- **El libro de deudas §7.1 — cerrarlo** con el estado final de cada una y con el recuento de los **seis tipos de
  cobro atípico** que el curso descubrió al escribirse: diff vacío a propósito (F09), código agregado (F10),
  pagar midiendo el error (F13→F14), parcial a propósito (F11), **abaratada por esperar** (F18→F19) y
  **distancia cero con un decorador** (F22). Que los seis hayan aparecido sin estar planeados es el mejor
  argumento de que el libro de deudas era una buena idea.
- **Las dos decisiones admitidas van también en `0-ESTRUCTURA-CURSO.md`**, en una nota corta con enlace a esta
  fase. Un lector que empieza por el documento de estructura tiene derecho a saber, antes de invertir
  veinticuatro fases, **qué orden habría sido mejor y por qué no se cambió** — y la razón de no cambiarlo es la
  regla de bloqueo de contenido, que conviene citar explícitamente para que no parezca pereza.
- **Y una cosa que el curso debe y esta fase no puede dar:** las veinticuatro tablas están en ⏳. Si alguna vez se
  ejecutan, **los números no van en las fases**: van en `BENCHMARKS.md`, con fecha y máquina, y las fases siguen
  enlazando ahí. Es el mismo mecanismo que la F14 y la F18 usaron para una sola columna, aplicado a las
  veinticuatro entradas — y conviene escribirlo como política antes de que a alguien se le ocurra rellenar una
  tabla en un `.md` publicado.
