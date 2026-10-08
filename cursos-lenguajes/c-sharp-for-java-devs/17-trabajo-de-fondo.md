# 🌙 Fase 17 — Trabajo de fondo: colas, idempotencia y reanudación

> C# para desarrolladores Java senior · Fase 17 de 24 · Bloque D — servicios, datos y nube
> Depende de: 16 · Habilita: 18
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: **nace NightPress**. Al terminar, la liquidación trimestral es reanudable por lotes,
> idempotente y auditable línea por línea — y se puede reproducir un número de hace ocho meses.

---

## 🎯 1. Propósito

Hoy el cierre de regalías corre en tres procedimientos almacenados y un trabajo del SQL Server Agent. **Tarda
seis horas, falló en la hora cinco dos veces el año pasado, y cuando falla se reinicia desde cero.**

Y hay algo peor, que es el que da la medida del problema: dos veces al año un autor impugna su liquidación. La
última fue una traductora con contrato de participación, y **reproducir el número exacto que se había
calculado ocho meses antes tomó tres días de arqueología entre respaldos** — porque las tasas de cambio usadas
en el cálculo no se guardaron en ninguna parte.

Esta fase construye NightPress, y su criterio de aceptación no es que sea rápido: es que **se pueda reproducir
un número de hace ocho meses en segundos**. Lo demás —reanudable, idempotente, cancelable— es lo que hace
falta para llegar ahí.

> 🧭 **La regla que el lector se lleva de esta fase, y es la más transferible del curso:** *una tasa de cambio
> usada en un cálculo se guarda con el cálculo.* No se vuelve a consultar. Reproducir un número de hace ocho
> meses no puede depender de que una tabla externa siga diciendo lo mismo.

Y es la fase que **más deudas cobra**: tres, de tres fases distintas, y las tres se pagan en el mismo archivo.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `Cordillera.NightPress` existe como servicio de fondo y ejecuta la liquidación trimestral **por lotes
      reanudables**: si falla en el lote 340 de 700, reanuda en el 341.
- [ ] La liquidación es **idempotente por clave de operación**: ejecutarla dos veces sobre el mismo periodo
      **no paga dos veces**, y hay una prueba que lo demuestra matando el proceso a mitad.
- [ ] 💸 **Se cobran tres deudas:** los dos métodos sin `CancellationToken` de la fase 05, la doble escritura
      sin conciliación de la fase 10, y `Money` como `decimal` desnudo de la fase 01.
- [ ] **`Money` lleva la moneda dentro**, y sumar importes de monedas distintas **falla con un error que
      nombra las dos** — la variante que no compila se diseña en el ejercicio 19 y la sección 5.1 explica por
      qué el curso no la eligió.
- [ ] La **tasa de cambio se guarda con el cálculo**, con su fecha de vigencia, y el esquema lo soporta.
- [ ] Se puede **reproducir exacto un número liquidado ocho meses antes**, en segundos, y hay una prueba que
      lo verifica contra una liquidación histórica.
- [ ] El outbox funciona: la doble escritura de la fase 10 tiene reintentos con retroceso y **la divergencia
      se repara sin intervención manual**.
- [ ] Hay **auditoría línea por línea**: qué se sumó, con qué tasa, bajo qué cláusula.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Las funciones durables** → fase 20. Se nombran aquí porque son la respuesta de libro para la publicación
  programada en nueve husos, y **se aplazan con su razón**: su ventaja es de operación y su costo es por
  ejecución, así que compararlas sin precio sería el folleto que la guía prohíbe.
- **El costo mensual de la mensajería** se mide aquí como parte de la comparación, y **la factura completa** —
  con el resto de los servicios— es de la fase 20.
- **Observabilidad del proceso**: trazas, métricas, alertas → fase 19. Esta fase deja la auditoría de negocio
  —qué se pagó y por qué— que es otra cosa.
- **El reemplazo del trabajo del SQL Server Agent** no se despliega: se construye la alternativa al lado y se
  mide, igual que hizo la fase 09 con el `DataSet`. Apagar el Agent es una decisión de la fase 20.
- **La publicación programada en nueve husos.** Se diseña el caso —es de esta fase por naturaleza— y su
  implementación con orquestación durable queda en la 20 con su costo.

---

## 🧠 4. Concepto mínimo

### Las cuatro propiedades de un proceso que se puede volver a ejecutar

Un proceso de fondo que mueve dinero necesita cuatro cosas, y el de Cordillera no tiene ninguna. Conviene
nombrarlas porque cada una resuelve un fallo distinto:

**Reanudable.** Si muere en la hora cinco, la siguiente ejecución **empieza donde quedó** y no desde cero. Eso
exige que el progreso esté persistido —no en memoria— y que la unidad de progreso sea lo bastante pequeña
para que perder una no duela.

**Idempotente.** Ejecutar la misma operación dos veces produce el mismo efecto que ejecutarla una. **Es la
propiedad que hace segura la reanudación**: sin ella, reanudar en el lote 341 cuando el 340 estaba a medias
paga dos veces las regalías de ese lote — y a alguien le llega el dinero.

**Cancelable.** Se puede detener a propósito, y detenerla deja un estado explicable. Es la deuda de la fase 05
y aquí se cobra.

**Auditable.** Cada número que produce se puede explicar: qué se sumó, con qué tasa, bajo qué cláusula. No
para cumplir una norma: **para poder responderle al abogado de una traductora ocho meses después**.

> 🧠 **El modelo mental:** un proceso por lotes reanudable no es un bucle grande que guarda su posición — es
> **una máquina de estados persistida donde cada transición es idempotente**. El bucle es un detalle; lo que
> importa es que el estado viva en la base y que repetir una transición no cambie nada.

### La idempotencia, que es la propiedad difícil

Las otras tres se consiguen con disciplina. Esta exige una decisión de diseño, y la decisión es **cuál es la
clave de la operación**.

```csharp
// ❌ Sin clave: el proceso inserta y confía en no repetirse.
await db.Settlements.AddAsync(settlement, token);

// ✅ Con clave: la operación se identifica, y repetirla es una operación vacía.
//    La clave la compone el negocio y no el proceso: periodo + contrato identifican **una** liquidación,
//    así que dos ejecuciones del mismo trimestre producen la misma clave.
string operationKey = $"settle:{period}:{contractNumber}";
```

Y la parte que decide si funciona: **la clave tiene que ser única en la base de datos**. No comprobada antes
de insertar —eso es una carrera— sino **impuesta por una restricción**, de modo que el segundo intento falle y
el proceso lo interprete como "ya estaba hecho".

```csharp
// El patrón completo, y es más corto de lo que parece:
try
{
    await db.SaveChangesAsync(token);
}
catch (DbUpdateException ex) when (ex.IsUniqueViolation("UQ_LIQREGAL_OPERACION"))
{
    // No es un error: es la confirmación de que este lote ya se procesó en una ejecución
    // anterior. Se cuenta como omitido y se sigue.
    skipped++;
}
```

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: el proceso nocturno que se reinicia desde cero.**

Y hay que ser justo con el reflejo, porque no es ignorancia: es lo que hace la mayoría de los procesos por
lotes del mundo, y funciona mientras el proceso sea corto.

```csharp
// ❌ El proceso de Cordillera, traducido a C# moderno. Seis horas, y si falla en la quinta
//    empieza de nuevo. Todo el progreso vive en memoria.
public async Task RunAsync(string period, CancellationToken token)
{
    IReadOnlyList<Contract> contracts = await _contracts.ActiveInAsync(period, token);

    foreach (Contract contract in contracts)
    {
        Settlement settlement = Calculate(contract, period);
        await _settlements.SaveAsync(settlement, token);
    }
}
```

**Por qué falla:** porque a las seis horas la probabilidad de que algo falle deja de ser pequeña. Un
despliegue, un reinicio del servidor, un bloqueo en la base, una pérdida de red. Y **cuanto más tarda, más
caro es reiniciar**: la ejecución que falla en la hora cinco no cuesta cinco horas, cuesta diez — las cinco
perdidas y las cinco que hay que volver a hacer.

```csharp
// ✅ Por lotes, con el progreso en la base. Si muere en el lote 340, la siguiente empieza en el 341.
public async Task RunAsync(SettlementPeriod period, CancellationToken token)
{
    SettlementRun run = await _runs.StartOrResumeAsync(period, token);

    await foreach (SettlementBatch batch in _batches.PendingForAsync(run, token))
    {
        token.ThrowIfCancellationRequested();

        await ProcessBatchAsync(run, batch, token);

        // El progreso se persiste por lote, no al final. Es lo que convierte seis horas de riesgo
        // en el riesgo de un lote.
        await _runs.MarkBatchDoneAsync(run, batch, token);
    }

    await _runs.CompleteAsync(run, token);
}
```

**Segunda, y es la que cuesta dinero de verdad: el reintento que duplica el cobro.**

```csharp
// ❌ Lo que pasa cuando se agrega reanudación SIN idempotencia. Y es peor que no tener ninguna de
//    las dos, porque ahora el proceso reintenta con confianza.
if (run.LastCompletedBatch is { } last)
{
    batches = batches.Skip(last);   // ← reanuda en el siguiente
}
```

El problema está en el borde: **el lote 340 se procesó a medias**. Se escribieron 180 de sus 200
liquidaciones y el proceso murió antes de marcarlo como completo. La siguiente ejecución reanuda en el 340 —
correcto— y **vuelve a escribir esas 180**. A ciento ochenta autores les llega el pago dos veces.

Y lo que hace difícil este bug es que **no falla**: el proceso termina bien, los totales cuadran con lo que el
proceso cree que hizo, y el descubrimiento llega por la vía de tesorería tres semanas después.

**Por qué falla el reflejo:** porque en el mundo del que vienes, la reanudación de un lote casi siempre venía
con transacción: un marco de procesamiento por lotes marca el progreso **en la misma transacción** que escribe
los resultados, así que un lote a medias no existe. Aquí hay que construirlo, y si se construye la mitad —la
reanudación sin la idempotencia— el resultado es peor que no tener nada.

```csharp
// ✅ Las dos cosas, y el orden importa: la clave de operación primero, la reanudación después.
//    Con la clave impuesta por una restricción única, reanudar en un lote a medias es seguro:
//    las 180 que ya estaban se rechazan solas.
string operationKey = $"settle:{period}:{contract.Number}";
```

**Dónde se rompe el paralelo:** Spring Batch resuelve esto con su `JobRepository` y sus `StepExecution`
persistidas, y es una pieza madura que llevas años usando. **En .NET no hay un equivalente estándar de ese
nivel** — hay `BackgroundService` para hospedar el proceso y ya. Eso significa más código propio y, a cambio,
que **la máquina de estados es tuya y la puedes leer**. No es mejor ni peor: es menos marco y más decisión, y
conviene saberlo antes de estimar.

### 🩻 Esto sí funciona igual

Todo lo que sabes de mensajería, y es mucho. Entrega al menos una vez frente a exactamente una vez —y que la
segunda casi nunca existe de verdad—, la cola de mensajes fallidos, el reintento con retroceso exponencial, el
veneno que bloquea la cola, la diferencia entre orden global y orden por partición. Nada de eso cambia y el
curso no lo explica.

También se transfiere el razonamiento sobre **transacciones distribuidas y por qué no**: si hace falta
escribir en la base y publicar un mensaje de forma atómica, la respuesta no es una transacción de dos fases —
es el **outbox**, que ya apareció como deuda en la fase 10 y aquí se construye. El patrón tiene el mismo
nombre en los dos mundos.

Y se transfiere el instinto de **hacer el trabajo idempotente desde el principio**, que es lo que separa a
quien ya sufrió una cola en producción de quien no.

### 📖 Diccionario de traducción

| Java | .NET | Dónde se rompe el paralelo |
|---|---|---|
| `@Scheduled` de Spring | `BackgroundService` + un temporizador, o Quartz.NET | **No hay anotación de programación en la caja.** Hay que escribir el bucle, o traer una biblioteca |
| **Spring Batch** con `JobRepository` | **no hay equivalente estándar** | Es la fila que importa: hospedaje sí, máquina de estados por lotes no. Más código propio, y la lógica es legible |
| `Step` / `Chunk` / `ItemReader` | tus propios tipos | El diseño es tuyo. Se gana control y se pierde un marco probado por miles de proyectos |
| `JobParameters` para la idempotencia | clave de operación + restricción única | Spring Batch impide reejecutar un trabajo con los mismos parámetros; aquí eso lo impone la base |
| `@Retryable` de Spring Retry | **Polly**, o `ResiliencePipeline` | Se configura en código y no con anotaciones. Más explícito y más verboso |
| `ActiveMQ` / `RabbitMQ` / Kafka | Azure Service Bus, RabbitMQ, o **una tabla** | La tabla es una opción legítima y en Cordillera es el statu quo — y el competidor de la medición |
| `@JmsListener` | `ServiceBusProcessor`, o un bucle propio | Sin descubrimiento por anotación: el procesador se registra a mano |
| cola de mensajes fallidos | igual, y en Service Bus viene incluida | Con una tabla hay que construirla, y esa es una de las columnas del costo |
| `@Transactional` + publicar mensaje | **outbox** | Mismo problema, mismo patrón, mismo nombre. Y aquí hay que escribirlo |
| `BigDecimal` con `Currency` | `Money` con su moneda — **la deuda de la F01, cobrada aquí** | `decimal` es del lenguaje y los operadores se sobrecargan: sumar monedas distintas puede **no compilar** |

> ⚠️ **La fila de Spring Batch es la que cambia la estimación de esta fase y conviene decirla sin rodeos.** Si
> vienes de haber usado Spring Batch, la expectativa razonable es que exista algo equivalente y que el trabajo
> sea configurarlo. **No existe.** Hay bibliotecas para partes —Polly para la resiliencia, Quartz.NET para la
> programación, Hangfire para trabajos en cola— y ninguna cubre la máquina de estados por lotes con su
> repositorio de ejecuciones. Esta fase la construye a mano, en unas doscientas líneas, y esa es la
> aritmética honesta: menos marco, más decisión, y todo el diseño visible.

> 📝 **Nota de ecosistema.** `IHostedService` y `BackgroundService` llegaron con .NET Core 2.1 en 2018 y
> resolvieron un problema muy concreto: antes de eso, un proceso de fondo en .NET era un servicio de Windows
> —con su instalador y su registro— o una tarea programada del sistema operativo, que es exactamente lo que
> Cordillera tiene hoy con el trabajo del SQL Server Agent. Que ahora un proceso de fondo sea **el mismo tipo
> de aplicación que un servicio web**, con la misma configuración y la misma inyección de dependencias, es un
> cambio grande de ergonomía — y es la razón por la que NightPress puede reusar todo lo que las fases 15 y 16
> construyeron.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El cobro de la deuda de la fase 01: `Money` con su moneda

```csharp
// src/modern/Cordillera.Domain/Money.cs
//
// 💸 Cobro de la deuda de la fase 01, dieciséis fases después. Allí `Money` nació como un `decimal`
//    desnudo y quedó dicho por qué: la moneda sin la tasa y sin el momento en que se aplicó resuelve
//    un tercio del problema. Ahora se resuelven los tres, porque la liquidación cruza tres divisas.
//
//    La factura: git diff fase-01 fase-17 -- src/modern/Cordillera.Domain/Money.cs
public readonly record struct Money(decimal Amount, Currency Currency) : IComparable<Money>
{
    /// <summary>
    /// Sumar importes de monedas distintas **lanza**, y eso es lo mínimo. Lo ideal sería que no
    /// compilara, y se puede —con un tipo genérico por moneda— a cambio de que `Money` deje de
    /// poder guardarse en una columna y de que el borde de la fase 09 se complique bastante.
    /// </summary>
    /// <remarks>
    /// La decisión, escrita: **se elige lanzar**. El motivo no es pereza — es que los importes vienen
    /// de la base con su moneda en una columna `char(3)`, así que la moneda es un **dato** y no un
    /// parámetro de tipo. Un tipo genérico por moneda obligaría a un `switch` gigante en el borde
    /// para elegir el tipo, y el error se movería de una excepción clara a una rama olvidada.
    /// El ejercicio 19 pide implementar la alternativa y comparar.
    /// </remarks>
    public static Money operator +(Money left, Money right)
    {
        if (left.Currency != right.Currency)
        {
            throw new CurrencyMismatchException(left.Currency, right.Currency);
        }

        return new Money(left.Amount + right.Amount, left.Currency);
    }

    /// <summary>
    /// Convertir requiere una tasa **con su fecha**, y devuelve el importe convertido **junto con la
    /// tasa que se usó**. No hay una sobrecarga que convierta sin registrar: es el punto entero de
    /// la fase, y hacerla imposible de omitir es más efectivo que documentarla.
    /// </summary>
    public ConvertedMoney ConvertTo(Currency target, ExchangeRate rate)
    {
        if (rate.From != Currency || rate.To != target)
        {
            throw new ArgumentException(
                $"La tasa {rate.From}->{rate.To} no sirve para convertir {Currency} a {target}.",
                nameof(rate));
        }

        decimal converted = Math.Round(Amount * rate.Value, 2, MidpointRounding.ToEven);

        return new ConvertedMoney(
            Original: this,
            Result: new Money(converted, target),
            RateUsed: rate);
    }
}

/// <summary>
/// El resultado de una conversión, **con la tasa adentro**. Este tipo es la regla de la fase hecha
/// código: no se puede tener un importe convertido sin tener la tasa con que se convirtió, porque
/// están en el mismo objeto.
/// </summary>
public readonly record struct ConvertedMoney(Money Original, Money Result, ExchangeRate RateUsed);

/// <summary>
/// Una tasa de cambio con su vigencia. `ValidOn` es la fecha para la que la tasa era válida — **no**
/// la fecha en que se consultó, que es el error que tiene `TASACAMB` desde 1997.
/// </summary>
public readonly record struct ExchangeRate(Currency From, Currency To, decimal Value, DateOnly ValidOn);
```

**El patrón a memorizar**

> **Si un dato tiene que acompañar a un resultado, ponlos en el mismo tipo.** La regla *"la tasa se guarda con
> el cálculo"* se puede escribir en la documentación y alguien la va a olvidar en tres años. `ConvertedMoney`
> la hace **imposible de olvidar**, porque no hay forma de obtener el importe convertido sin recibir también
> la tasa. Esa es la diferencia entre una convención y un diseño.

### 5.2 El cobro de la deuda de la fase 05: los dos métodos sin token

```csharp
// 💸 Cobro de la deuda de la fase 05. Allí quedaron dos métodos sin `CancellationToken` con este
//    argumento, que se citó textualmente para poder desmontarlo aquí:
//
//      "RecalculateTotalsAsync recorre lo ya cargado en memoria y tarda milisegundos;
//       FlushSummaryAsync escribe el resumen final y cancelarlo dejaría el resumen a medias,
//       que es peor que esperarlo."
//
//    Las dos mitades del argumento eran razonables en la fase 05 y las dos son falsas aquí:
//
//    1. "Tarda milisegundos" era cierto con los tres archivos de distribuidores. El mismo recorrido
//       sobre la liquidación trimestral son 21.000 contratos y **cuarenta minutos**. La duración de
//       una operación no es una propiedad del método: es una propiedad de los datos, y los datos
//       crecen.
//
//    2. "Cancelarlo dejaría el resumen a medias" era el argumento correcto para el problema
//       equivocado. La respuesta no es impedir la cancelación: es hacer que un resumen a medias
//       sea **detectable y reanudable** — que es el trabajo de esta fase.
//
//    La factura: git diff fase-05 fase-17 -- src/modern/Cordillera.Domain/Import/
public Task RecalculateTotalsAsync(SettlementRun run, CancellationToken token);
public Task FlushSummaryAsync(SettlementRun run, CancellationToken token);
```

### 5.3 La máquina de estados por lotes, que hay que escribir

```csharp
// src/modern/Cordillera.NightPress/Settlement/SettlementRunner.cs
//
// Lo que Spring Batch da en la caja y aquí hay que escribir: unas doscientas líneas, y todas
// visibles. Es la aritmética honesta de la fila del 📖.
namespace Cordillera.NightPress.Settlement;

public sealed class SettlementRunner(
    ISettlementRuns runs,
    ISettlementCalculator calculator,
    IAuditTrail audit,
    TimeProvider clock,
    ILogger<SettlementRunner> log)
{
    /// <summary>
    /// Ejecuta o **reanuda** la liquidación de un periodo. Llamarla dos veces sobre el mismo periodo
    /// es seguro: los lotes ya hechos se omiten, y los que quedaron a medias se completan sin
    /// duplicar nada.
    /// </summary>
    public async Task<SettlementRunResult> RunAsync(SettlementPeriod period, CancellationToken token)
    {
        // El estado de la ejecución vive en la base, no en memoria. Si esto es una reanudación, el
        // registro ya existe con sus lotes marcados.
        SettlementRun run = await runs.StartOrResumeAsync(period, clock.GetUtcNow(), token);

        log.LogInformation(
            "Liquidación {Periodo}: ejecución {Ejecucion}, {Pendientes} lotes pendientes de {Total}.",
            period, run.Id, run.PendingBatchCount, run.TotalBatchCount);

        int processed = 0;
        int skipped = 0;

        await foreach (SettlementBatch batch in runs.PendingBatchesAsync(run, token))
        {
            // La comprobación explícita del token, en el bucle propio. Sin esto el proceso no se
            // puede detener aunque todas las llamadas de dentro reciban el token — es la lección de
            // la fase 05, y aquí es lo que permite que un despliegue no tenga que esperar seis horas.
            token.ThrowIfCancellationRequested();

            BatchOutcome outcome = await ProcessBatchAsync(run, batch, token);

            processed += outcome.Settled;
            skipped += outcome.AlreadyDone;
        }

        await runs.CompleteAsync(run, clock.GetUtcNow(), token);

        return new SettlementRunResult(run.Id, processed, skipped);
    }

    private async Task<BatchOutcome> ProcessBatchAsync(
        SettlementRun run,
        SettlementBatch batch,
        CancellationToken token)
    {
        int settled = 0;
        int alreadyDone = 0;

        foreach (Contract contract in batch.Contracts)
        {
            // La clave de operación: la compone el negocio y no el proceso. Dos ejecuciones del
            // mismo trimestre producen la misma clave, así que la segunda choca con la restricción
            // única y se omite.
            var operationKey = SettlementOperationKey.For(run.Period, contract.Number);

            try
            {
                // La frontera de la transacción la abre el RUNNER, y el calculador solo calcula.
                // Es una decisión y tiene su razón: un calculador que no escribe **se puede probar
                // sin base de datos**, y las reglas de regalías —tres monedas, dos bases de
                // liquidación, el hallazgo de la F08— son justamente lo que más pruebas necesita.
                await using IDbContextTransaction tx = await db.Database.BeginTransactionAsync(token);

                SettlementResult result = calculator.Settle(contract, run.Period, rates);

                // La liquidación y su auditoría, en la MISMA transacción. Si se escribieran aparte,
                // una caída entre las dos dejaría un pago sin explicación — que es exactamente lo
                // que le pasó a la traductora.
                await settlements.SaveAsync(operationKey, result, token);
                await audit.RecordAsync(operationKey, result, token);

                await tx.CommitAsync(token);

                settled++;
            }
            catch (DuplicateOperationException)
            {
                // No es un error: este contrato ya se liquidó en una ejecución anterior que murió
                // antes de marcar el lote. Se cuenta y se sigue, y **esto es lo que hace segura la
                // reanudación**.
                alreadyDone++;
            }
        }

        // El lote se marca después de sus contratos, y eso deja una ventana: si el proceso muere
        // aquí, el lote se vuelve a intentar y sus contratos se omiten por la clave. La ventana es
        // el precio de no tener una transacción que abarque el lote completo — y con 200 contratos
        // por lote, ese precio es reintentar 200 omisiones baratas.
        await runs.MarkBatchDoneAsync(run, batch, clock.GetUtcNow(), token);

        return new BatchOutcome(settled, alreadyDone);
    }
}
```

**Detalles con intención**

- **`TimeProvider` y no `DateTime.UtcNow`.** Es lo que permite probar un proceso que depende del tiempo sin
  esperar, y es la respuesta moderna al problema que la fase 08 resolvió congelando el reloj de un contenedor.
- **La auditoría va en la misma transacción que la liquidación.** Es la decisión que hace posible el criterio
  de aceptación: un pago sin su explicación es exactamente el problema que la fase viene a resolver.
- **La ventana entre el último contrato y la marca del lote está declarada**, con su costo: reintentar
  doscientas omisiones baratas. Una fase que la escondiera estaría fingiendo una garantía que no tiene.

### 5.4 La auditoría que responde al abogado

```sql
-- El cambio de esquema que esta fase necesita, y es en tabla nueva: `LIQREGAL` y `LIQDETAL` de 1997
-- NO se tocan. La auditoría vive al lado, y por eso la liquidación vieja y la nueva pueden convivir.
CREATE TABLE LIQAUDIT (
  NROLIQUI     char(12)      NOT NULL,
  NROLINEA     int           NOT NULL,
  CODEDIT      char(10)      NULL,
  CANTIDAD     int           NULL,
  VLRUNIT      decimal(12,2) NULL,
  MONEDAORIG   char(3)       NULL,
  -- Las tres columnas que no existían y que costaron tres días de arqueología:
  TASAUSADA    decimal(12,6) NULL,   -- la tasa exacta con que se convirtió
  TASAVIGDESDE char(8)       NULL,   -- la fecha para la que esa tasa era válida
  CLAUSULA     varchar(40)   NULL,   -- qué regla del contrato se aplicó
  VLRCONVERT   decimal(14,2) NULL,
  MONEDADEST   char(3)       NULL,
  OPERACION    varchar(80)   NOT NULL,   -- la clave de idempotencia
  FECHAHORA    datetime2     NOT NULL
);
GO

-- Y la restricción que hace posible la idempotencia. No una comprobación antes de insertar —eso es
-- una carrera— sino una restricción que el motor impone.
CREATE UNIQUE INDEX UQ_LIQAUDIT_OPERACION ON LIQAUDIT (OPERACION);
GO
```

```csharp
// Y la consulta que responde la pregunta de la traductora, en segundos en vez de tres días:
public async Task<SettlementExplanation> ExplainAsync(
    string settlementNumber,
    CancellationToken token)
{
    IReadOnlyList<AuditLine> lines = await _audit.LinesForAsync(settlementNumber, token);

    // Cada línea trae la tasa con la que se convirtió y la cláusula que se aplicó. Reproducir el
    // número es volver a sumar las líneas, **sin consultar TASACAMB** — que es la razón por la que
    // el número de hace ocho meses no se podía reproducir.
    return SettlementExplanation.From(lines);
}
```

> 💸 **Cobro de la deuda de la fase 10: el outbox.**
>
> La doble escritura de la fase 10 entró **sin conciliación automática**: había un registro de divergencias y
> una consulta que alguien ejecutaba. La medición de esa fase dejó el número que faltaba —cuántos *"fallos del
> camino nuevo sin escritura"* por día— y con ese número se dimensiona esto:
>
> ```csharp
> // El outbox: la escritura y la publicación del mensaje, en la misma transacción.
> await using IDbContextTransaction tx = await db.Database.BeginTransactionAsync(token);
>
> db.Movements.Add(movement);
> db.Outbox.Add(OutboxMessage.For(movement));   // ← misma transacción, misma base
>
> await db.SaveChangesAsync(token);
> await tx.CommitAsync(token);
>
> // Y un proceso de fondo lee el outbox y publica, con reintentos y retroceso. Si el proceso muere,
> // el mensaje sigue ahí; si publica dos veces, el consumidor es idempotente por su clave.
> ```
>
> **Lo que esto compra**, y es lo que la fase 10 no podía tener: la divergencia **se repara sola**. Ya no hace
> falta que alguien ejecute una consulta de conciliación por la mañana.
>
> La factura: `git diff fase-10 fase-17 -- src/modern/Cordillera.Catalog.Api/Inventory/`.

**Prueba de fuego**

```powershell
# Arrancar la liquidación y matarla a mitad. Literalmente.
dotnet run --project src\modern\Cordillera.NightPress -- settle --period 202601
# … a los treinta segundos: Ctrl+C, o mejor, matar el proceso sin darle tiempo a limpiar.

# Y volver a arrancarla.
dotnet run --project src\modern\Cordillera.NightPress -- settle --period 202601

# El resultado tiene que decir cuántas omitió, y el total liquidado tiene que ser idéntico al de una
# ejecución limpia. Si el total cambió, se pagó dos veces.
dotnet run --project src\modern\Cordillera.Ops -- settle --verify --period 202601
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **matar el proceso con Ctrl+C es el
caso fácil**, porque la cancelación cooperativa funciona y el proceso termina el lote en curso. El caso que
importa es matarlo **sin** darle tiempo a nada —un corte de energía, un contenedor que el orquestador
termina—, y ahí es donde se ve si la idempotencia está bien hecha. Si tu prueba solo usa Ctrl+C, no probaste
la propiedad que te importa.

---

## 📏 6. Medición

**Hipótesis:** la cola en tabla de SQL Server —que es lo que Cordillera ya tiene y funciona— sostiene el
volumen de NightPress con holgura, y la mensajería gestionada gana en throughput máximo y en funcionalidad de
operación **a un costo mensual que al volumen real no se justifica**. La pregunta no es cuál aguanta más: es
**a partir de qué volumen la diferencia importa**.

**Condiciones:** SQL Server 2025 en contenedor sobre WSL 2 · el emulador de mensajería declarado en
`alcance-del-proyecto.md` §10.1 · base del generador con semilla `19970417`, **21.000 contratos y el trimestre
completo** · SDK 10.0.401 · 10 ejecuciones de la liquidación completa, 2 de calentamiento descartadas · arnés
propio, con memoria y colecciones por generación.

**Competidores:**

- **El trabajo del SQL Server Agent con los tres procedimientos**, que es el statu quo: seis horas, no
  reanudable, no cancelable. **Es el competidor que hay que vencer**, y hay que medirlo tal como está.
- **Cola en tabla de SQL Server** — la que Cordillera ya tiene en otro proceso y funciona.
- **Mensajería gestionada** (emulador en contenedor; el precio se declara con fecha y región).
- **Sin cola**: el proceso por lotes leyendo directo de la base, que es lo que NightPress hace de verdad para
  la liquidación. Está para saber **cuánto cuesta la cola en sí**, porque la respuesta puede ser que no haga
  falta.

**El comando:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 17 --contracts 21000
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · La liquidación completa**

| Implementación | Duración total | Reanudable | Cancelable | Reproducible a 8 meses | Pico de memoria |
|---|---|---|---|---|---|
| Agent + procedimientos (statu quo) | ⏳ | **No** | **No** | **No** | ⏳ |
| NightPress por lotes, sin cola | ⏳ | Sí | Sí | Sí | ⏳ |
| NightPress con cola en tabla | ⏳ | Sí | Sí | Sí | ⏳ |
| NightPress con mensajería gestionada | ⏳ | Sí | Sí | Sí | ⏳ |

**B · La cola: throughput, latencia y costo mensual**

| Opción | Mensajes/s | Latencia p95 | Cola de fallidos | Costo mensual al volumen real | Amarre |
|---|---|---|---|---|---|
| Tabla en SQL Server | ⏳ | ⏳ | hay que construirla | **0** (la base ya está pagada) | ninguno |
| Mensajería gestionada | ⏳ | ⏳ | incluida | 💲 ⏳ *(precio publicado, con fecha y región)* | moderado |

> 💲 **La fila de la mensajería gestionada lleva su precio publicado, con fecha y región —East US 2— y se
> marca como no ejecutada en la parte del costo** (`formato-de-mediciones.md` §2.5). El throughput sí se mide,
> contra el emulador.

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que
> NightPress **le gane con holgura al statu quo en las cuatro columnas cualitativas** y que la duración total
> sea **parecida o incluso peor** — porque los lotes, la auditoría y las claves de idempotencia son trabajo
> adicional. Publicar eso así es el punto: **NightPress no es más rápido, es reanudable y auditable**, y eso
> es lo que se compró.
>
> Y se espera que la cola en tabla sostenga el volumen sin dificultad, porque el volumen de Cordillera es de
> miles de mensajes al día y no de miles por segundo.
>
> **Los tres umbrales que tu ejecución tiene que determinar:** (1) **a partir de cuántos mensajes por segundo
> la tabla deja de servir**, que es el número que decide si la mensajería gestionada hace falta algún día;
> (2) **cuánto cuesta la auditoría línea por línea** en tiempo y en espacio, porque es el precio de poder
> responderle al abogado; y (3) **cuánto tarda la reproducción de un número de hace ocho meses** — que hoy
> son tres días y el objetivo es segundos.
>
> 📝 Y la columna que decide no es ninguna de las numéricas: **"reproducible a 8 meses"** tiene tres "No" en
> la primera fila, y ese es el argumento del proyecto. La fase 20 volverá sobre el costo con el resto de la
> factura.

---

## 🧱 7. Miniproyecto — la liquidación que se puede reproducir ocho meses después

**El encargo**

Clara reenvía un correo del abogado de la traductora, y añade tres líneas:

> *"Es la segunda vez en dos años. La última nos tomó tres días y tuvimos que aceptar su cifra porque no
> pudimos demostrar la nuestra. Necesito que la próxima vez yo pueda contestar el mismo día, con el detalle de
> cómo se calculó. Y necesito saber si los cálculos de 2019 se pueden reconstruir, porque si no, eso también
> tengo que saberlo."*

**Por qué duele**

Porque la segunda pregunta de Clara no tiene una respuesta agradable: **los cálculos de 2019 no se pueden
reconstruir**, y no por un defecto del código — porque `TASACAMB` se sobrescribe cada mes y **las tasas de
2019 no existen en ninguna parte**. Lo único que se puede hacer es decirlo con claridad y asegurar que a
partir de ahora sí.

Y porque el criterio de aceptación es duro de verdad: no "el sistema guarda la tasa", sino **reproducir un
número concreto de una liquidación concreta y que coincida al centavo**.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| Contratos activos | **21.000**, incluidos vencidos y de participación |
| … de traducción con `BASELIQUI = 'N'` | Los del hallazgo de la fase 08: liquidan sobre precio de lista **por error de 2017** |
| Monedas | **COP, MXN, PEN, ARS, USD** — cinco, y la liquidación cruza tres por trimestre |
| `TASACAMB` | **Una fila por moneda.** Se sobrescribe cada mes: las tasas históricas no existen |
| Duración actual | **Seis horas**; falló en la hora cinco dos veces el año pasado |
| Una liquidación histórica | La del trimestre `202502`, con su número exacto, para verificar la reproducción |
| Lotes | 200 contratos por lote → **105 lotes** |

**Criterios de aceptación**

1. La liquidación del trimestre completo corre **por lotes reanudables**: matar el proceso a mitad y volver a
   arrancarlo produce **el mismo total** que una ejecución limpia. Una prueba lo demuestra **matando el proceso
   sin cancelación cooperativa**.
2. **Idempotencia comprobada:** ejecutar el mismo periodo dos veces seguidas reporta el segundo como "todo
   omitido" y **no cambia ni un centavo**.
3. `Money` lleva su moneda, y **sumar monedas distintas falla** con un error que dice cuáles. Una prueba por
   cada par de monedas que la liquidación cruza.
4. **La tasa se guarda con el cálculo**, con su fecha de vigencia, y `LIQAUDIT` tiene una línea por
   componente con su cláusula.
5. **Se reproduce el número de `202502` al centavo**, sin consultar `TASACAMB`, en menos de cinco segundos. Una
   prueba lo verifica contra el valor histórico.
6. Existe la respuesta a la segunda pregunta de Clara: **qué se puede y qué no se puede reconstruir de antes
   de esta fase**, con el alcance exacto y por qué.
7. **Medición de cierre:** las dos tablas, con el tiempo de reproducción de un número histórico. Van en el
   mensaje del tag `mini-17`.

**Restricciones de estilo y alcance**

Código nuevo: `async` de punta a punta, token propagado **en todos los métodos** —es el cobro de la deuda de
la fase 05—, y `TimeProvider` en vez de `DateTime.UtcNow` para que el proceso se pueda probar sin esperar.

**`LIQREGAL` y `LIQDETAL` no se tocan.** La auditoría va en una tabla nueva, y la razón es que el proceso
viejo tiene que poder seguir corriendo en paralelo mientras se compara — es la misma estrategia de la fase 09
con el `DataSet`, y de la 10 con la doble escritura.

Sin funciones durables: son de la fase 20, con su costo.

**La trampa**

Vas a implementar la reanudación primero, porque es la que resuelve la queja visible —seis horas y falla en la
quinta—. Va a funcionar: matas el proceso en el lote 60, lo vuelves a arrancar, y reanuda en el 61.

**Y vas a haber construido la máquina de duplicar pagos.**

Porque el lote 60 estaba a medias: se escribieron 180 de sus 200 liquidaciones y el proceso murió antes de
marcarlo. Al reanudar en el 61 esas 180 quedan bien... pero si reanudas en el **60** —que es lo correcto,
porque el lote no se marcó— vuelves a escribir las 180. **A ciento ochenta autores les llega el pago dos
veces.**

Y lo que hace peligroso este bug es que **el proceso termina bien**: los totales cuadran con lo que el proceso
cree que hizo, no hay error, no hay log, y el descubrimiento llega por tesorería tres semanas después.

**El orden correcto es el inverso: la idempotencia primero, la reanudación después.** Con la clave de
operación impuesta por una restricción única, reanudar en un lote a medias es seguro por construcción.

Cuando lo descubras, escribe en tres líneas por qué **la reanudación sin idempotencia es peor que no tener
ninguna de las dos** — y es literal: sin reanudación, un fallo obliga a reiniciar y alguien lo nota; con
reanudación sin idempotencia, nadie lo nota.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por la clave de operación y la restricción única, y **prueba la idempotencia antes de escribir la
reanudación**. Si el orden te parece raro, es exactamente el punto de la trampa.

Para el criterio 5, la pregunta útil es: ¿qué tendría que estar guardado para que reproducir el número sea una
suma y no una investigación? La respuesta es la lista de columnas de `LIQAUDIT`.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para el servicio de fondo, `BackgroundService` y su ciclo de vida:
`https://learn.microsoft.com/dotnet/core/extensions/workers`

Para los reintentos con retroceso, **Polly** — y hay que fijar su versión en `Directory.Packages.props` antes
de usarla, verificada en NuGet:
`https://www.pollydocs.org/`

Para el reloj comprobable, `TimeProvider`, que es de .NET 8 y reemplaza a los relojes inyectados a mano:
`https://learn.microsoft.com/dotnet/api/system.timeprovider`

Y para detectar la violación de la restricción única sin depender del texto del mensaje, mira el número de
error de SQL Server en `SqlException.Number` — 2601 y 2627.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// La clave de operación: la compone el negocio, y es la misma en dos ejecuciones del mismo periodo.
public readonly record struct SettlementOperationKey(string Value)
{
    public static SettlementOperationKey For(SettlementPeriod period, string contractNumber);
}

// El calculador NO escribe: recibe las tasas y devuelve el resultado. Así se prueba sin base de
// datos, y la transacción la abre quien coordina.
public interface ISettlementCalculator
{
    SettlementResult Settle(Contract contract, SettlementPeriod period, ExchangeRateSet rates);
}

// El estado de la ejecución, persistido. Es lo que Spring Batch daría en la caja.
public sealed record SettlementRun(
    Guid Id, SettlementPeriod Period, DateTimeOffset StartedAt,
    int TotalBatchCount, int PendingBatchCount, SettlementRunStatus Status);

public interface ISettlementRuns
{
    Task<SettlementRun> StartOrResumeAsync(SettlementPeriod period, DateTimeOffset now, CancellationToken token);
    IAsyncEnumerable<SettlementBatch> PendingBatchesAsync(SettlementRun run, CancellationToken token);
    Task MarkBatchDoneAsync(SettlementRun run, SettlementBatch batch, DateTimeOffset now, CancellationToken token);
}

// Y la explicación, que es lo que Clara contesta el mismo día.
public sealed record SettlementExplanation(
    string SettlementNumber,
    Money Total,
    IReadOnlyList<AuditLine> Lines)
{
    // Recalcula desde las líneas guardadas, SIN consultar TASACAMB. Si el resultado no coincide con
    // el total guardado, hay un problema y la explicación lo dice en vez de esconderlo.
    public bool Reconciles { get; }
}
```

</details>

**Cómo se entrega**

```powershell
dotnet test src\Cordillera.slnx -c Release
dotnet run --project src\modern\Cordillera.NightPress -- settle --period 202601
dotnet run --project src\modern\Cordillera.Ops -- settle --explain 202502000017
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 17 --contracts 21000
```

```bash
git tag -a mini-17 -m "Mini F17: liquidacion reanudable e idempotente · 21.000 contratos en <X> min · reproduccion de 202502 en <Y> s · 0 pagos duplicados tras muerte del proceso"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe un `BackgroundService` que registre una línea cada diez segundos y detenlo con Ctrl+C. Observa qué
   pasa con el token.
2. Agrega la moneda a `Money` y compila. Cuenta cuántos sitios del curso dejaron de compilar: ese número es la
   deuda de la fase 01, medida.
3. Escribe la prueba que verifica que sumar COP con MXN falla con un error que nombra las dos monedas.
4. Crea `LIQAUDIT` con su restricción única y demuestra con dos inserciones que la segunda falla.
5. Usa `TimeProvider` en una prueba para simular que pasan ocho meses sin esperar. Explica qué habría hecho
   falta sin él.
6. Reproduce un número de liquidación desde `LIQAUDIT` sin consultar `TASACAMB`, y verifica que coincide.

**🟡 Intermedio (7–14)**

7. Implementa la reanudación por lotes **sin** idempotencia y demuestra con una prueba que duplica pagos.
   Después agrega la idempotencia y demuestra que ya no.
8. Mata el proceso sin cancelación cooperativa —terminando el proceso— y verifica que la reanudación produce
   el mismo total.
9. Implementa el outbox y demuestra que un mensaje no se pierde aunque el publicador muera después del commit.
10. Configura reintentos con retroceso exponencial y demuestra que un fallo transitorio se recupera solo.
11. Provoca un mensaje veneno —uno que siempre falla— y demuestra que no bloquea la cola. Explica qué hiciste
    con él.
12. Mide cuánto cuesta la auditoría línea por línea: tiempo, espacio en disco y filas. Es el segundo umbral.
13. Implementa la cola en tabla con `UPDATE ... OUTPUT` para tomar un mensaje sin carreras, y explica por qué
    un `SELECT` seguido de un `UPDATE` no sirve.
14. Diseña la publicación programada en nueve husos —qué significa "medianoche" cuando hay nueve— y **no la
    implementes**: es la fase 20.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Tesorería reporta que ciento ochenta autores recibieron el pago dos veces. Escribe el
    procedimiento de diagnóstico: qué consulta harías primero, cómo identificarías el lote, y cómo se repara
    sin quitarle el dinero a nadie.
16. **Diagnóstico.** La liquidación termina "bien" y el total es un 3% menor que el trimestre anterior sin
    razón de negocio. Enumera cuatro causas —una involucra la conversión de moneda, otra un lote omitido por
    error— y di cómo distinguirlas con `LIQAUDIT`.
17. **Medición.** Ejecuta la medición completa, las dos tablas, y determina **los tres umbrales**. Publica
    que NightPress **no es más rápido** si así resulta, y el párrafo que explica qué se compró entonces.
18. **Medición.** Mide el costo mensual de la mensajería gestionada al volumen real de Cordillera, con precio
    publicado, fecha y región, y compáralo con cero — que es lo que cuesta la tabla, porque la base ya está
    pagada. Es una fila de la factura de la fase 20.
19. Implementa `Money` con un **tipo genérico por moneda**, de modo que sumar monedas distintas **no
    compile**. Después intégralo en el borde de la fase 09 y anota qué se complicó. Decide cuál dejarías.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** Los tres procedimientos de liquidación de 1997 y
    su trabajo del Agent. NightPress ya funciona. Decide cuándo se apaga el viejo, con qué criterio, y qué
    pasa con el hallazgo de la fase 08 —la regla mal aplicada— cuando el nuevo la haga bien.
21. **Decisión.** Cola en tabla o mensajería gestionada, para el volumen de Cordillera y con la operación de
    dos personas. Decide con los números y con el amarre, y di **a qué volumen cambiarías de opinión**.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue duplicar un pago **con** la idempotencia activada. *(Hay al menos dos caminos:
    uno pasa por la clave de operación mal compuesta y otro por una transacción que abarca menos de lo que
    parece.)*
23. **Adversarial.** Haz que la reproducción de un número histórico **coincida y sea falsa**: que la suma de
    las líneas dé el total guardado y sin embargo la explicación sea incorrecta. Es el ejercicio que enseña
    qué tiene que verificar una auditoría.
24. **Diseño.** El hallazgo de la fase 08 dice que las traducciones se liquidaron sobre la base equivocada
    durante nueve años. Diseña qué hace NightPress con eso: ¿replica el error para que los números cuadren
    con el histórico, o lo corrige y produce una discontinuidad? Escribe las dos consecuencias y **elige**.
25. **Defiende una decisión.** Responde las dos preguntas de Clara en una hoja: cómo va a poder contestarle
    al abogado el mismo día, y **qué no se puede reconstruir de antes**. En su lenguaje, sin minimizar la
    segunda parte.

**🔥 Opcionales**

- Investiga Hangfire y Quartz.NET, y escribe qué parte del trabajo de esta fase harían y qué parte no.
  Anótalo: es la aritmética de "menos marco, más decisión" del 📖.
- Implementa la liquidación con un `Channel<T>` entre el lector de contratos y varios calculadores, y mide si
  el paralelismo aporta. La respuesta depende de dónde esté el cuello de botella.
- Escribe el mismo proceso como una función durable y **no lo integres**: guárdalo para la fase 20, donde se
  mide con su precio.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/core/extensions/workers` — `BackgroundService` y el servicio de fondo
  como aplicación de primera clase.
- `https://learn.microsoft.com/dotnet/api/system.timeprovider` — el reloj comprobable, de .NET 8.
- `https://learn.microsoft.com/azure/architecture/patterns/transactional-outbox` — el outbox, que fue la deuda
  de la fase 10.
- `https://learn.microsoft.com/azure/architecture/patterns/retry` y
  `https://learn.microsoft.com/azure/architecture/patterns/circuit-breaker` — reintentos y cortacircuitos, con
  cuándo cada uno.
- `https://www.pollydocs.org/` — Polly: resiliencia configurada en código.
- `https://learn.microsoft.com/dotnet/core/resilience/` — la integración de resiliencia en el SDK, que envuelve
  Polly.
- `https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview` — la mensajería
  gestionada, con **su página de precios citada con fecha y región**.
- `https://learn.microsoft.com/sql/t-sql/queries/update-transact-sql` — `UPDATE ... OUTPUT`, que es cómo se
  toma un mensaje de una tabla sin carreras.

**Libros / artículos**

- *Enterprise Integration Patterns*, de Hohpe y Woolf, es el catálogo de esta fase — idempotencia, cola de
  fallidos, reintentos. El lector probablemente ya lo conoce; se cita porque los nombres que usa son los que
  el ecosistema .NET también usa.
- *Designing Data-Intensive Applications*, de Kleppmann — el capítulo sobre entrega y exactitud es la mejor
  explicación de por qué "exactamente una vez" casi nunca existe. Verifica edición.

> ⚠️ Verifica las URLs. Y la advertencia propia de esta fase: **buena parte del material sobre trabajos de
> fondo en .NET es anterior a 2018** y describe servicios de Windows con su instalador, o tareas programadas
> del sistema operativo — que es exactamente lo que Cordillera tiene hoy. Funciona, y no es lo que esta fase
> construye. Y del otro lado: **el material sobre mensajería asume volúmenes que Cordillera no tiene**, así
> que las recomendaciones de arquitectura que encuentres están dimensionadas para otro problema.

**Orden de lectura sugerido:** antes de escribir, la página del outbox y la de reintentos —son de arquitectura
y deciden el diseño—. Durante el miniproyecto, la de `BackgroundService` y la de `TimeProvider`. Al cerrar, el
capítulo de Kleppmann sobre entrega: se lee distinto cuando ya duplicaste un pago en una prueba.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe NightPress, y existe algo que Cordillera no tenía: **la capacidad de explicar un número**. Cada
liquidación tiene su línea de auditoría con la tasa que se usó, su fecha de vigencia y la cláusula que se
aplicó — así que la próxima vez que un abogado pregunte, Clara contesta el mismo día en vez de en tres.

Y se cobraron **tres deudas de tres fases distintas**, que es el récord del curso. `Money` lleva su moneda
dieciséis fases después de haber nacido desnudo; los dos métodos sin `CancellationToken` la tienen, y el
argumento con que se justificaron —*"tarda milisegundos"*— quedó desmontado por lo que siempre fue: **la
duración de una operación no es una propiedad del método, es una propiedad de los datos, y los datos crecen**.
Y la doble escritura de la fase 10 tiene su outbox, así que la divergencia se repara sola.

Queda una cosa sin resolver y conviene que quede escrita: **los cálculos de 2019 no se pueden reconstruir.**
Las tasas de ese año no existen en ninguna parte, porque `TASACAMB` se sobrescribe cada mes desde 1997. Lo
único que esta fase puede hacer es garantizar que a partir de ahora sí, y decirlo con claridad — que es lo
que la segunda pregunta de Clara pedía.

La fase 18 cambia de interfaz y trae de vuelta una columna pendiente. Nace **Redacción**, el back-office
editorial: cuarenta pantallas, roles, auditoría, con Nohora de usuaria real y Ximena vigilando que no le
agregues un paso al flujo. Y ahí se mide lo que la fase 14 dejó abierto — **la cuarta columna del veredicto
del escritorio** — con los tres modelos de render de Blazor y la latencia medida desde Bogotá, Ciudad de
México y el depósito de Lima. La metodología ya está congelada; la 18 la usa sin rediscutirla, y si el
veredicto cambia, lo dice.

> **La señal de que quedó bien:** *"Puedo matar el proceso a mitad, volver a arrancarlo, y el total no cambia
> ni un centavo. Y puedo explicar de dónde salió cada peso de una liquidación de hace ocho meses."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-17 -m "F17 cerrada:
> - NightPress por lotes reanudables e idempotentes por clave de operacion
> - Money con su moneda: sumar monedas distintas falla, y la conversion guarda su tasa
> - LIQAUDIT: linea por linea, con tasa, vigencia y clausula
> - reproduccion de un numero de hace 8 meses en segundos, sin consultar TASACAMB
> - outbox funcionando: la divergencia de la F10 se repara sola
> - tres deudas cobradas: F01 (Money), F05 (CancellationToken) y F10 (doble escritura)"
> ```
>
> **Tres facturas, tres fases de origen, y la más larga del curso:**
>
> ```bash
> git diff fase-01 fase-17 -- src/modern/Cordillera.Domain/Money.cs
> git diff fase-05 fase-17 -- src/modern/Cordillera.Domain/Import/
> git diff fase-10 fase-17 -- src/modern/Cordillera.Catalog.Api/Inventory/
> ```
>
> La primera es la que más enseña: **dieciséis fases de distancia**, y el diff es de unas treinta líneas. Una
> deuda bien declarada no crece con el tiempo — crece el costo de **no** haberla declarado, y de eso no hay
> diff.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — dos entradas en la familia *servicios, identidad y operación*: el proceso nocturno que
  se reinicia desde cero, y **el reintento que duplica el cobro** — que es la más importante de la familia y
  necesita la frase completa: *la reanudación sin idempotencia es peor que no tener ninguna de las dos*, con
  su razón (sin reanudación alguien nota el fallo; con reanudación sin idempotencia, nadie). Y conviene una
  tercera entrada corta: **buscar el equivalente de Spring Batch**, porque no existe y esa expectativa cambia
  la estimación de la fase.
- **`BENCHMARKS.md`** — entrada ⏳ *F17 · La liquidación completa, y la cola contra la mensajería gestionada*,
  con dos tablas. Tiene **columnas cualitativas con "No"** —reanudable, cancelable, reproducible— y eso es
  deliberado: son las que deciden, y el archivo debería decir que una tabla de medición puede tener columnas
  que no son números.
- **Deudas 💸 cobradas: tres, y es el récord del curso.** F01 (`Money`), F05 (`CancellationToken`) y F10
  (outbox). Conviene anotar en el libro de §7.1 que la de F01 tiene **dieciséis fases de distancia y un diff
  de treinta líneas**, porque es el mejor argumento de que una deuda declarada no crece: lo que crece es el
  costo de no declararla.
- **Cambio de esquema: tabla nueva `LIQAUDIT`** —no se toca `LIQREGAL` ni `LIQDETAL`—. Hay que agregarla al
  congelamiento §1.3 con sus tres columnas que no existían: `TASAUSADA`, `TASAVIGDESDE` y `CLAUSULA`. Es el
  segundo cambio de esquema del curso, después de borrar `USUARIOS.CLAVE`, y **los dos son por riesgo y no
  por diseño**.
- **Paquete nuevo, verificado y fijado:** `Microsoft.Extensions.Resilience` **10.10.0** —que envuelve Polly
  8.7.0— quedó en `Directory.Packages.props` y en `alcance-del-proyecto.md` §9, consultado en su ficha de
  NuGet. Misma regla que con `System.IO.Hashing` en la F10: ninguna versión de memoria.
- **Tipos nuevos para el congelamiento:** `Currency`, `ConvertedMoney`, `ExchangeRate`,
  `CurrencyMismatchException`, `SettlementRun`, `SettlementBatch`, `SettlementPeriod`,
  `SettlementOperationKey`, `SettlementRunResult`, `BatchOutcome`, `AuditLine`, `SettlementExplanation`,
  `ISettlementRuns`, `ISettlementCalculator` —que **calcula y no escribe**—, `ExchangeRateSet`, `IAuditTrail`,
  `OutboxMessage`, `DuplicateOperationException`.
- **Para la fase 18:** las cuarenta pantallas de Redacción necesitan auditoría de quién vio qué, y esa es su
  deuda con cobro en la 19. La auditoría **de negocio** de esta fase es otra cosa y conviene que la 18 no las
  confunda.
- **Para la fase 20:** tres entradas directas — el precio de la mensajería gestionada al volumen real, el
  costo de la cola en tabla (cero, porque la base está pagada), y las funciones durables con su precio por
  ejecución. Más el ejercicio 🔥 de la función durable, que la 20 puede retomar.
- **Para la fase 24:** el ejercicio 24 —¿NightPress replica el error de nueve años o lo corrige?— es una de
  las decisiones más difíciles del curso y no tiene respuesta correcta. La 24 tiene que volver sobre ella.
- **Riesgo detectado y resuelto:** la frontera de la transacción estaba implícita. 🪦 Decidido: **el runner
  la abre y el calculador solo calcula** —recibe las tasas, devuelve el resultado, no escribe—. La razón es
  de comprobabilidad: las reglas de regalías (tres monedas, dos bases de liquidación, el hallazgo de la F08)
  son lo que más pruebas necesita, y un calculador que no toca la base se prueba sin contenedor. Queda
  reflejado en la sección 5.3 y en el esqueleto.
