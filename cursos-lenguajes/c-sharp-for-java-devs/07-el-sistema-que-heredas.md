# 🏚️ Fase 07 — El sistema que heredas

> C# para desarrolladores Java senior · Fase 07 de 24 · Bloque B ⭐ — el sistema heredado y la frontera
> Depende de: 06 · Habilita: 08
> Estilo de esta fase: **heredado** — .NET Framework 4.8, C# escrito como C# de 2017, `DataSet`,
> `SqlDataAdapter`, sin `async`, sin LINQ, sin `var`. **Es la única fase del curso escrita entera así.**
> Proyecto que avanza: **nace SIGE**. Al terminar existe `src/legacy/` con el esquema completo de los
> cuatro módulos, dos de ellos implementados —existencias y regalías—, y la línea base de medición del
> bloque.

---

## 🎯 1. Propósito

Escribir el sistema que el resto del bloque va a cortar. No es un ejercicio de nostalgia y no es una
parodia: es la única forma de que las fases 08 a 11 corten algo de verdad en vez de ensayar sobre un
ejemplo.

Y hay un segundo propósito, que es el que hace difícil esta fase: **aprender a leer un sistema
heredado sin juzgarlo**. Vas a escribir código que las seis fases anteriores te enseñaron a no
escribir, y vas a escribirlo bien — o sea, como lo escribieron en 2017, con sus razones al lado. Eso es
más incómodo de lo que suena, y es exactamente la habilidad que separa una migración de un incendio.

> 🧭 **La regla de tono de esta fase, y no tiene excepción:** cada decisión incómoda va **junto a su
> año y su razón**. El nombre de diez caracteres es del formato DBF y es de 1997. La tabla por año es
> cómo se evitaba que el motor sufriera. El borrado por bandera es la semántica de FoxPro. Si un
> párrafo de esta fase se lee como sorna, está mal escrito y se reescribe.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `src/legacy/Sige.Database` tiene **el esquema completo de los cuatro módulos** —catálogo,
      existencias, regalías y facturación— con sus nombres reales y las treinta tablas anuales.
- [ ] **Dos módulos implementados**: existencias por almacén y liquidación de regalías, con sus seis
      procedimientos almacenados.
- [ ] `src/legacy/Sige.DataAccess` compila contra **.NET Framework 4.8** con MSBuild, y devuelve
      `DataSet`. Ni un `var`, ni un `using`, ni un `async`.
- [ ] La cadena de conexión está en el `App.config`, en texto plano, con permiso de escritura sobre
      todo — y **declarada como deuda 💸 con su fase de cobro**.
- [ ] `SP_VENTAS_HIST` existe, arma el `UNION ALL` de treinta tablas concatenando cadenas, y **está
      medido**: plan de consulta, lecturas lógicas y tiempo. Es la línea base del bloque.
- [ ] El generador de datos sucios corre con **semilla fija** y produce exactamente los volúmenes de la
      tabla de la sección 7. La fase 08 caracteriza contra él y la 09 mide contra él.
- [ ] `dotnet build src/Cordillera.slnx` **sigue pasando**: las dos soluciones conviven y ninguna sabe
      de la otra.

---

## 🚫 3. Qué NO entra todavía

- **Ninguna mejora.** Es la regla de la fase y aplica a todo: no se arregla el `finally` escrito a
  mano, no se pone un `using`, no se cambia un nombre, no se agrega un índice que falta, no se corrige
  la regla de `BASELIQUI` que está mal. **Ni siquiera "de paso, en un comentario".**
- **Los formularios WinForms** → Bloque C. Aquí está la capa de datos y el esquema; los 340 formularios
  se cuentan como historia y el curso construye tres, en las fases 12 a 14.
- **Pruebas** → fase 08. Esta fase escribe código sin pruebas, y es la única que lo hace, y eso es
  parte de la lección: así te llega un sistema heredado.
- **Catálogo y facturación implementados** → fase 08, que los escribe **mientras los caracteriza**
  (decisión §10.4 de la propuesta). Su **esquema** sí está aquí, porque renombrar después rompería
  tres fases.
- **Cualquier decisión sobre qué migrar** → fases 09 a 11. Aquí solo se lee y se mide.

---

## 🧠 4. Concepto mínimo

No hay concepto técnico nuevo en esta fase. Lo que hay es un método de lectura, y son cuatro preguntas
que se le hacen a cada cosa que incomoda:

**¿De qué año es?** Un campo de diez caracteres no es un descuido: es el límite del formato DBF, y el
formato DBF es de 1983. Una tabla por año no es ignorancia de particionamiento: es que en 1997, con
Visual FoxPro 5 sobre una red de par trenzado, una tabla de ventas que creciera sin límite era un
problema real y medible.

**¿Qué problema resolvía?** El borrado por bandera no es miedo a `DELETE`: en FoxPro un registro
borrado era **una marca en el propio archivo** y seguía ahí hasta que alguien hiciera `PACK`. La
bandera `BORRADO char(1)` es la traducción literal de esa semántica, y en 2017 mantenerla fue lo que
permitió que el sistema viejo y el nuevo convivieran durante la migración.

**¿Qué costaría cambiarlo hoy?** Esta es la pregunta que convierte la lectura en criterio.
`VLRUNIT` se podría renombrar a `UnitPrice` en una tarde — y habría que tocar los trescientos
procedimientos almacenados que lo mencionan, más los formularios que atan una grilla a ese nombre de
columna, más los cuatro volcados CSV que tres socios comerciales consumen. **Ese es el número que
decide**, y en la fase 09 se va a calcular.

**¿Qué se rompe si lo toco sin querer?** Sin llaves foráneas, la integridad la garantiza el programa.
Eso significa que hay 1.900 filas de `MOVINVEN` cuyo `CODEDIT` no existe, y que **cualquier consulta
nueva que use `INNER JOIN` donde el sistema usaba `LEFT JOIN` va a devolver menos filas y a cuadrar
distinto**. Ese es el bug más común de una migración, y no lo produce el código viejo: lo produce el
nuevo.

> 🧠 **El modelo mental de todo el Bloque B:** el sistema heredado no es un borrador mal hecho de lo
> que tú habrías escrito. Es **una serie de decisiones correctas tomadas con información distinta**, y
> encima de ellas, treinta años de parches que también fueron correctos en su momento. Tu ventaja no es
> saber más: es tener presupuesto y saber qué pasó después. Confundir las dos cosas es cómo se
> presenta un plan de dos años y medio que la presidenta rechaza.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** leer esto y pensar *"está mal hecho"*.

Va a pasar en la segunda pantalla de SQL. `char(8)` para una fecha. `CAMPO1` a `CAMPO7`. Una tabla por
año. Ningún índice más allá del que agregó alguien en 2019 porque un reporte se cayó. Y la reacción
natural de alguien que lleva once años en un banco con arquitecto y comité es escribir un documento de
tres páginas — que es literalmente lo que escribiste el día once.

**El código que produce ese reflejo** no es código: es un plan. Y el plan tiene esta forma:

> *"Propuesta: normalizar el esquema, renombrar las columnas a nombres legibles, agregar llaves
> foráneas, unificar las treinta tablas de ventas en una sola con particionamiento, y migrar la lógica
> de los procedimientos almacenados a servicios. Estimado: dieciocho meses."*

**Por qué falla:** porque las cuatro cosas son ciertas por separado y el plan completo es imposible.
Renombrar las columnas obliga a tocar setecientos procedimientos que nadie ha leído completos.
Agregar llaves foráneas falla al primer intento, porque hay 1.900 filas huérfanas y la operación no
puede completarse hasta que alguien decida qué hacer con ellas — y esa decisión es del negocio, no
tuya. Unificar las ventas rompe los cuatro volcados CSV que tres socios consumen. Y mover la lógica
requiere **entender** la lógica, que es el trabajo de la fase 08 y es el que nadie ha hecho.

Y sobre todo falla por la razón que Clara dio en 2021, que es una restricción y no una opinión:
*"Ustedes me están pidiendo que pare la editorial dos años para que el sistema se vea mejor por
dentro."*

**Qué se escribe en su lugar:** nada, todavía. Esta fase no propone: **lee y mide**. La propuesta llega
en la fase 10, y va a ser mucho más pequeña que tres páginas.

> ⚰️ **Autopsia del anti-patrón, con sus números.** El *lift and shift* de 2020 es el mismo reflejo en
> su versión contraria: no tocar nada y mover todo. Cuatro máquinas virtuales con IIS, una con SQL
> Server licenciado, y los clientes WinForms conectándose por VPN a una base que quedó **más lejos que
> antes**. En México la aplicación se volvió notablemente más lenta y la respuesta oficial fue "es la
> conexión". Resultado medido: **la factura mensual quedó un 30% por encima del centro de datos que
> reemplazó**. La fase 20 pone el número exacto y la 24 admite quién lo aprobó y por qué.

### 🩻 Esto sí funciona igual

Aquí el 🩻 es grande y conviene decirlo: **SQL es SQL**. Las consultas, los planes, los índices, las
estadísticas, los bloqueos, los niveles de aislamiento, las transacciones — todo tu oficio de base de
datos vale aquí íntegro y sin traducción. Cuando en la sección 6 leas el plan de `SP_VENTAS_HIST`, no
vas a necesitar que nadie te explique qué es un escaneo de tabla.

Y las transacciones también: `BEGIN TRANSACTION` / `COMMIT` es lo que esperas, `SqlConnection` tiene
`BeginTransaction`, y el razonamiento sobre qué va dentro y qué va fuera es idéntico.

Lo que se transfiere entero, y es más de lo que parece, es **leer código que no escribiste**. La
habilidad de entrar a un módulo ajeno, encontrar el punto de entrada, seguir el hilo y no cambiar nada
hasta entenderlo, es la misma en cualquier lenguaje. Esta fase te pide ejercerla sobre código que tú
mismo vas a escribir, que es un truco pedagógico: **lo escribes hoy y lo lees como ajeno en la fase
08**, porque para entonces ya no vas a recordar los detalles.

### 📖 Diccionario de traducción

Este 📖 no traduce entre lenguajes: traduce entre **épocas**, que es lo que esta fase necesita.

| Lo que ves en SIGE (2017) | Lo que escribirías hoy | Qué costaría cambiarlo, y en qué fase se decide |
|---|---|---|
| `DataSet` / `DataTable` | `record` y `IAsyncEnumerable` | El `DataSet` es el tipo de retorno de cuarenta métodos y de la grilla de cada formulario. **F09** lo mide |
| `SqlDataAdapter.Fill` | `SqlDataReader` por flujo, o Dapper | Cambia el consumo, no solo el acceso: la grilla espera un `DataTable`. **F09** y **F12** |
| `try`/`finally` a mano | `using` | Cuarenta métodos. La respuesta correcta es **no tocarlos**, y la **F09** dice por qué |
| lógica en procedimiento almacenado | lógica en el dominio | Setecientos procedimientos, nadie los ha leído. **F08** los caracteriza, **F10** corta los primeros |
| cadena de conexión en `App.config` | secreto gestionado, una sola ruta de código | Noventa equipos. Es la deuda más antigua y la cobra la **F16** |
| `packages.config` | `PackageReference` + CPM | Dos paquetes sin equivalente moderno. La **F11** convierte lo que puede y **declara lo que no** |
| SQL concatenado en tiempo de ejecución | consulta parametrizada o `IQueryable` | Cada concatenación es un plan nuevo. La **F09** lo mide con el número de la sección 6 |
| `char(8)` para una fecha | `DateOnly` | Once tablas, y tres formas distintas de convertir. La **F09** pone el borde 🧬 |
| tabla por año | una tabla particionada | Treinta tablas, setecientos procedimientos y cuatro volcados. **F09** mide; **F24** admite si valía |
| `BORRADO = 'S'` | borrado real, o estado del dominio | La mitad de las consultas olvida filtrarla. **F09** con un filtro global, y sus tres agujeros |
| Crystal Reports 13 | lo que la medición diga | Tiene sus propias conexiones a la base, por fuera de la aplicación. **F11** y **F14** |

> 📝 **Nota de ecosistema, y es la que sostiene el tono de la fase.** Todo lo de la columna izquierda
> era **la forma normal y recomendada** de hacer las cosas cuando se escribió. `DataSet` fue durante
> diez años el tipo de datos por defecto de .NET y tenía diseñador visual en Visual Studio; los
> procedimientos almacenados eran donde la industria entera ponía la lógica de negocio en los noventa;
> `packages.config` era NuGet, sin más. Y `IAsyncEnumerable` —lo que habría resuelto el reporte de
> 500.000 filas— **llegó en 2019, dos años después de esta migración**. Preguntar "¿por qué no lo
> hicieron por flujo?" es preguntar por qué no usaron algo que no existía.

---

## 💻 5. Código mínimo con comentarios

El código completo está en `src/legacy/`. Aquí van las cinco piezas que hay que leer con atención,
porque son las que el resto del bloque toca.

### 5.1 El esquema, con cada decisión junto a su año

```sql
-- src/legacy/Sige.Database/esquema/01-tablas.sql
CREATE TABLE MOVINVEN (
  NROMOVTO  int IDENTITY(1,1) NOT NULL,
  CODALMA   char(3)       NULL,
  CODEDIT   char(10)      NULL,   -- 1.900 filas apuntan a una edicion inexistente
  FECMOVTO  char(8)       NULL,   -- '00000000' en 210 filas
  TIPOMOVTO char(1)       NULL,   -- E entrada, S salida, A ajuste, D devolucion
  CANTIDAD  int           NULL,   -- negativa en los ajustes
  VLRUNIT   decimal(12,2) NULL,
  NRODOCTO  char(15)      NULL,   -- en blanco en los ajustes de 2018
  CODUSUA   char(10)      NULL,
  FECHAHORA datetime      NULL DEFAULT GETDATE(),
  CAMPO1    varchar(20)   NULL,
  -- … CAMPO2 a CAMPO7 …
  BORRADO   char(1)       NULL DEFAULT 'N'
);
```

**Detalles con intención** — y cada uno es una decisión de 1997 con su razón, no un defecto:

- **`MOVINVEN`, ocho caracteres**, porque DOS limitaba el nombre del archivo `.DBF` a ocho. **`VLRUNIT`
  y `FECMOVTO`, diez**, porque el formato DBF limitaba el nombre de campo a diez. Ese límite es de
  1983 y el modelo se congeló en 1997: para entonces ya había catorce años de sistemas escritos así.
- **`FECMOVTO char(8)` con formato `AAAAMMDD`.** En FoxPro una fecha vacía daba problemas al indexar, y
  guardar la fecha como cadena ordenable resolvía el ordenamiento y la comparación de rangos sin
  depender de la configuración regional de la máquina — que en una oficina con seis computadores
  distintos era un problema de verdad. El `'00000000'` es lo que la importación de 2017 escribió donde
  el DBF tenía la fecha vacía.
- **`BORRADO char(1)`** es la semántica de borrado de FoxPro traducida literalmente: allá el registro
  borrado era una marca en el archivo y seguía ahí hasta el `PACK`. Y en 2017 mantenerla tuvo una
  razón adicional y buena: **permitió que el sistema viejo y el nuevo leyeran los mismos datos durante
  los once meses de la migración**.
- **`CAMPO1` a `CAMPO7`** son campos de reserva. En los noventa, agregar una columna a un DBF de
  200.000 registros era una operación de veinte minutos con la oficina parada, así que se dejaban
  campos libres. Tres de ellos significan algo en algunas filas y nadie sabe qué.
- **`FECHAHORA datetime`** es la única fecha real de la tabla, y la puso el `DEFAULT` de 2017. Es el
  único sitio donde se ve que alguien, en algún momento, quiso hacer las cosas distinto.

```sql
-- src/legacy/Sige.Database/esquema/02-ventas-por-anio.sql
-- VENTAS_1997 .. VENTAS_2026: treinta tablas con la misma forma exacta.
DECLARE @anio int = 1997;
WHILE @anio <= 2026
BEGIN
  SET @sql = N'CREATE TABLE VENTAS_' + CAST(@anio AS nvarchar(4)) + N' ( … );';
  EXEC sp_executesql @sql;
  SET @anio = @anio + 1;
END
```

> 📝 **La única huella de 2017 en el esquema.** En FoxPro los archivos eran `VTAS97.DBF`, `VTAS98.DBF`
> y así — seis caracteres, dentro del límite. Las tablas de hoy se llaman `VENTAS_1997`, que tiene
> once y rompe la regla de las ocho. No es un descuido: **el asistente de importación de 2017 las creó
> con el nombre expandido, una por una, tal como los tres pasantes las escribieron en el cuadro de
> diálogo**. Cuando en la fase 08 tengas que datar una decisión, ese detalle es la pista.

### 5.2 La capa de datos: `DataSet`, `SqlDataAdapter` y el `finally` a mano

```csharp
// src/legacy/Sige.DataAccess/InventoryDataAccess.cs
public DataSet GetStockByWarehouse(string warehouseCode)
{
    DataSet result = new DataSet();
    SqlConnection connection = null;

    try
    {
        connection = new SqlConnection(this.connectionString);

        SqlCommand command = new SqlCommand("SP_EXIST_ALMACEN", connection);
        command.CommandType = CommandType.StoredProcedure;
        command.CommandTimeout = 120;
        command.Parameters.Add("@CODALMA", SqlDbType.Char, 3).Value = warehouseCode;

        SqlDataAdapter adapter = new SqlDataAdapter(command);
        adapter.Fill(result, "EXISTENCIAS");
    }
    catch (Exception ex)
    {
        // Se registra en un archivo de texto y se relanza. El archivo se rota a
        // mano cuando alguien se acuerda.
        LogError("GetStockByWarehouse", ex);
        throw;
    }
    finally
    {
        // El try/finally escrito a mano, con la comprobacion de nulo antes de
        // cerrar. Es lo que se escribia antes de using, y es lo que hay en los
        // cuarenta metodos de esta clase.
        if (connection != null)
        {
            connection.Close();
        }
    }

    return result;
}
```

**Detalles con intención** — y aquí es donde más cuesta no arreglar nada:

- **`this.connectionString` y no `_connectionString`.** El prefijo con guion bajo es una convención que
  el equipo no usaba; `this.` explícito era el estilo que enseñaban los libros de los que aprendieron.
- **`catch (Exception)` que registra y relanza.** No es el `catch (Exception)` que se traga el error de
  la fase 04: este relanza, así que es defendible — lo que hace mal es escribir el log **antes** de
  saber si se puede escribir, y tragarse el fallo de esa escritura en un `catch` vacío. Eso es la razón
  por la que a veces no hay rastro de un fallo.
- **`CommandTimeout = 120` en esta consulta y `600` en el reporte histórico.** El segundo se subió de
  120 a 600 en 2022 porque el reporte empezó a agotar el tiempo de espera. **Ese fue el arreglo**, y es
  un ejemplo perfecto de parche razonable: costó dos minutos, resolvió el síntoma, y dejó el problema
  exactamente donde estaba.
- **Nada de esto se moderniza.** El `finally` de arriba es idéntico al que la fase 04 reescribió a
  `using`, y aquí se queda. La diferencia entre los dos casos es el punto del curso: **en código nuevo,
  `using`; en código de 2017, se toca lo mínimo y en su propio estilo.**

> 💸 **El módulo entero es deuda declarada, y cada pieza dice dónde se cobra.** Es la deuda más grande
> del curso y la única que se declara por partes:
>
> | Pieza | Qué sería lo correcto | Se cobra en |
> |---|---|---|
> | El acceso a datos con `DataSet` | Un modelo tipado con su borde 🧬 explícito | **F09** |
> | La conexión directa del cliente a la base | Una API en medio, y el cliente sin credenciales de escritura | **F10** |
> | El runtime 4.8 | .NET 10, migrado por riesgo y no por versión | **F11** |
> | La cadena de conexión en noventa `App.config` | Un secreto gestionado, con una sola ruta de código | **F16** |
>
> **Por qué no se cobra nada ahora:** porque el orden importa más que la tecnología. Cambiar el acceso
> a datos antes de haber caracterizado los procedimientos es reescribir a ciegas; poner la API en
> medio antes de tener el acceso a datos medido es no saber qué se está encapsulando; y mover el
> runtime antes de cortar la conexión directa es cambiar de casa sin haber empacado.

### 5.3 La cadena de conexión, que viaja en noventa equipos

```xml
<!-- src/legacy/Sige.DataAccess/App.config -->
<connectionStrings>
  <add name="SigeConnection"
       connectionString="Data Source=SRVSQL01;Initial Catalog=SIGE;User ID=sigeapp;Password=Sige2017*;Connect Timeout=120"
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

En texto plano, con un usuario que tiene permiso de escritura sobre todo, copiado tal cual a las
noventa instalaciones. **Cambiar la clave significa visitar noventa equipos**, así que no se cambia — y
ese es el mecanismo completo por el que una contraseña de 2017 sigue siendo la de 2026.

Es la deuda más antigua del curso y **la más satisfactoria de cobrar**: en la fase 16, el comando
`git diff fase-07 fase-16 -- src/legacy/Sige.DataAccess/App.config` va a mostrar esa línea
desapareciendo.

### 5.4 `SP_LIQREGAL_CALC`, y las cuatro cosas que lo hacen imposible de probar

Este es el procedimiento que la fase 08 va a caracterizar. Está en
`src/legacy/Sige.Database/procedimientos/SP_LIQREGAL_CALC.sql` y **no se lee completo ahora**: se lee
en la fase 08, con una red debajo. Lo que sí hay que ver son los cuatro sitios que importan:

```sql
-- (1) GETDATE() dos veces: el resultado cambia segun cuando corra.
INSERT INTO LIQREGAL (…, FECLIQUI, …)
VALUES (…, CONVERT(char(8), GETDATE(), 112), …);

-- (2) La tasa de cambio, por FECHA MAXIMA y no por la vigente en el periodo.
--     TASACAMB se sobrescribe cada mes.
SELECT TOP 1 @TASA = VALOR
FROM   TASACAMB
WHERE  MONEDA = @MONEDA AND BORRADO = 'N'
ORDER BY FECTASA DESC;

-- (3) El detalle no guarda ni la tasa usada ni la clausula aplicada.
EXEC SP_LIQREGAL_DETALLE @NROLIQUI, @CODTITULO, @FECDESDE, @FECHASTA;

-- (4) Y la regla que la editorial cree que tiene y no aplica:
IF @BASELIQUI = 'N' AND @TIPOCONTR = 'A'
BEGIN
  -- descuenta el descuento de factura … solo para contratos de autoria.
  -- Los de traduccion caen en el ELSE y liquidan sobre precio de lista,
  -- que es mas alto.
END
```

**Detalles con intención**

- **(1) y (2) son lo que hace imposible una prueba**, y la fase 08 tiene que resolverlas **sin tocar
  este archivo**, porque en una empresa real no te dejan modificar el procedimiento antes de tener la
  red puesta.
- **(2) es lo que costó tres días de arqueología** entre respaldos cuando la traductora impugnó su
  liquidación. No es un bug: es una ausencia. Nadie decidió no guardar la tasa; simplemente nadie
  pensó que habría que reproducir el número ocho meses después.
- **(4) es el hallazgo del miniproyecto de la fase 08**, y está escrito aquí a propósito para que
  exista. No lo busques todavía: el punto de la fase 08 es que **se encuentra caracterizando y no
  leyendo**, porque leyendo setecientas líneas de T-SQL con cursores anidados nadie lo ve.

> ⚠️ **Y una advertencia sobre el conteo de líneas.** La historia dice que el cálculo trimestral son
> "tres procedimientos almacenados de setecientas líneas". Ese número es el de los tres juntos
> —`SP_LIQREGAL_CALC`, `SP_LIQREGAL_DETALLE` y `SP_LIQREGAL_ANULA`— con sus ramas y sus cursores. El
> curso escribe los tres; el primero es el que tiene el hallazgo.

### 5.5 El `UNION ALL` de treinta tablas

```sql
-- src/legacy/Sige.Database/procedimientos/SP_VENTAS_HIST.sql
WHILE @ANIO <= @ANIOHASTA
BEGIN
  IF LEN(@UNION) > 0
    SET @UNION = @UNION + N' UNION ALL ';

  SET @UNION = @UNION + N'
    SELECT V.FECVENTA, V.CODEDIT, … FROM VENTAS_' + CAST(@ANIO AS nvarchar(4)) + N' V
    WHERE V.BORRADO = ''N''';

  SET @ANIO = @ANIO + 1;
END

-- Y el filtro de sello, pegado DESPUES del ORDER BY que ya estaba escrito:
IF @CODSELLO IS NOT NULL
  SET @SQL = REPLACE(@SQL, N'ORDER BY V.FECVENTA',
                     N'WHERE T.CODSELLO = ''' + @CODSELLO + N''' ORDER BY V.FECVENTA');
```

**El patrón a memorizar**

> **Cada texto de consulta distinto es un plan de ejecución distinto.** Treinta tablas unidas por un
> texto que cambia con los parámetros significa que el motor no puede reutilizar el plan, y que la
> caché de planes se llena de variantes que se usan una vez. Es el primer orden de magnitud del
> problema, **y no está en .NET**: está aquí. Por eso la medición de la sección 6 mide el plan antes de
> medir el código.

**Prueba de fuego**

```powershell
# Compilar las dos soluciones. Son dos comandos distintos, y eso es el recordatorio
# diario de en qué lado de la frontera estás trabajando.
msbuild src\Sige.sln /t:Rebuild /p:Configuration=Release
dotnet build src\Cordillera.slnx -c Release
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **`Sige.DataAccess` compila sin
una sola advertencia**. No porque el código sea bueno, sino porque `src/legacy/Directory.Build.props`
apaga los analizadores y el contexto anulable a propósito. Si activas el análisis ahí, van a aparecer
cientos de advertencias que nadie va a atender y lo único que vas a enseñar es a apagar advertencias.
**La frontera entre generaciones es física y está en el árbol de directorios**, no en la disciplina de
quien escribe.

---

## 📏 6. Medición

**Esta es la línea base de todo el Bloque B.** Se toma aquí, antes de tocar nada, porque una migración
que no midió el punto de partida no puede demostrar que mejoró algo — y porque el orden obligatorio
cuando el trabajo toca la base de datos es **primero el plan de consulta, después .NET**
(`formato-de-mediciones.md` §2.2).

**Hipótesis:** el costo del reporte histórico está dominado por el `UNION ALL` de treinta tablas y por
la compilación de un plan nuevo en cada llamada — **no** por cómo .NET recorre el resultado. Optimizar
el lado de C# encima de esta consulta no puede cambiar el orden de magnitud.

**Condiciones:** SQL Server 2025 en contenedor —edición de desarrollo, `MSSQL_PID=EnterpriseDeveloper`—
sobre WSL 2 · la base generada con la semilla fija de la sección 7, **500.000 filas de ventas
repartidas en treinta tablas** · SDK 10.0.401 para el lado .NET y .NET Framework 4.8 para
`Sige.DataAccess` · 20 repeticiones con 3 de calentamiento descartadas · el plan con
`SET STATISTICS IO, TIME ON` y el lado .NET con el arnés.

**Competidores** — y aquí no hay dos implementaciones compitiendo: hay **cuatro mediciones del mismo
trabajo, cada una de una capa distinta**, para poder atribuir el costo a su causa:

- **El plan de `SP_VENTAS_HIST`**: lecturas lógicas, escaneos y tiempo del motor, con la caché de
  planes limpia y con ella caliente.
- **La misma consulta escrita a mano** con las treinta tablas en un texto **estático**, parametrizado.
  Es el competidor honesto: mide cuánto cuesta la concatenación por sí sola.
- **`GetSalesHistory` completo** —el método de `Sige.DataAccess`— con su `SqlDataAdapter.Fill`.
- **Un `SqlDataReader` por flujo** sobre el mismo procedimiento. No es una propuesta de arreglo: es
  para saber **qué fracción del tiempo total es el `DataSet`**.

**El comando:**

```sql
-- Primero el motor, y con la caché limpia entre corridas: sin esto se mide la
-- segunda ejecución y el número miente hacia abajo.
DBCC FREEPROCCACHE;
SET STATISTICS IO, TIME ON;
EXEC SP_VENTAS_HIST @ANIODESDE = 1997, @ANIOHASTA = 2026, @CODSELLO = NULL;
```

```powershell
# Y después .NET, en ese orden.
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 07
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

| Capa medida | Tiempo | Lecturas lógicas | Escaneos | Asignado | Pico |
|---|---|---|---|---|---|
| Plan de `SP_VENTAS_HIST`, caché limpia | ⏳ | ⏳ | ⏳ | — | — |
| Plan de `SP_VENTAS_HIST`, caché caliente | ⏳ | ⏳ | ⏳ | — | — |
| La misma consulta, texto estático parametrizado | ⏳ | ⏳ | ⏳ | — | — |
| `GetSalesHistory` completo (`DataSet`) | ⏳ | — | — | ⏳ | ⏳ |
| El mismo procedimiento con `SqlDataReader` | ⏳ | — | — | ⏳ | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera
> que el tiempo del motor domine el total por un margen amplio, y que la diferencia entre caché limpia
> y caliente sea grande en la versión concatenada y pequeña en la estática — lo que atribuiría una
> parte concreta del costo a la concatenación y no al volumen. Y se espera que el `DataSet` pese en
> memoria bastante más que el lector por flujo, **con una diferencia de tiempo mucho menor de lo que
> sugiere la de memoria**.
>
> **Los tres umbrales que tu ejecución tiene que determinar, y son los que gobiernan el bloque:**
> (1) **qué fracción del tiempo total es el motor** — si es más del 80%, cualquier trabajo en el lado
> .NET antes de arreglar la consulta es teatro; (2) **cuánto cuesta la concatenación por sí sola**,
> comparando las dos primeras filas con la tercera; y (3) **cuánto pesa el `DataSet`**, que es el
> número que la fase 09 necesita para decidir entre Dapper, EF Core y dejarlo quieto.
>
> 📝 Y un aviso sobre cómo **no** usar esta tabla: no es una condena del sistema. Es un punto de
> partida. Si en la fase 20 resulta que el reporte se pide una vez al mes y que arreglarlo cuesta tres
> semanas, la respuesta correcta puede ser subir el tiempo de espera otra vez — que es exactamente lo
> que alguien hizo en 2022, y tuvo razón.

---

## 🧱 7. Miniproyecto — el generador de datos sucios

**El encargo**

Tú mismo, y esta vez el encargo es del curso y no de un personaje, porque es material de trabajo:
**necesitas una base de datos poblada que se parezca a la de Cordillera**, con sus treinta años de
historia y toda su suciedad, y necesitas que **cualquiera que siga el curso obtenga exactamente la
misma**. Sin eso, la fase 08 no puede caracterizar nada —una prueba de aproximación compara contra un
conjunto de datos concreto— y la fase 09 no puede medir nada comparable.

**Por qué duele**

Porque la tentación es generar datos limpios, y unos datos limpios harían fácil todo el bloque
siguiente y **el curso perdería su material**. Cada anomalía de la tabla de abajo es la razón de ser de
un ejercicio o de un hallazgo posterior, así que generarlas bien es literalmente construir el resto del
Bloque B.

Y porque las anomalías tienen que ser **consistentes entre sí**: un movimiento huérfano tiene que
apuntar a un `CODEDIT` que de verdad no exista en `EDICION`, una tilde comida tiene que estar solo en
los títulos peruanos, y las devoluciones tienen que estar fechadas **después** del mes de la venta que
devuelven. Datos sucios al azar no sirven: tienen que estar sucios de la forma en que los ensució la
historia.

**Datos de entrada**

La especificación completa, y es el entregable más importante de esta fase porque **cinco fases
dependen de estos números**:

| Qué | Cuánto | Por qué ese número |
|---|---|---|
| Semilla del generador | **`19970417`** | Fija, escrita, y no se cambia nunca: el *golden master* de la fase 08 se rompe si cambia |
| Sellos | 4 | `COR`, `COM`, `SUR`, `UBA` — los de la historia |
| Almacenes | 3 | `BOG`, `MEX`, `LIM` |
| Distribuidores | 3 | `DISMEX` (semanas ISO), `DISCOL` (mes natural), `DISARG` (quincenal) |
| Títulos | **18.000** | El catálogo del grupo |
| … de ellos vivos comercialmente | **11.000** | El resto queda `ESTADO = 'D'` |
| Ediciones | **26.400** | Entre 1 y 4 por título, sesgado a 1 |
| … con ISBN en blanco | **340** | Anteriores a 2007, cuando no era obligatorio |
| … con ISBN de 10 dígitos | **3.100** | Entre 1979 y 2006 |
| Autores, traductores y agentes | 6.200 | En una sola tabla, con `TIPOPERS` |
| … con `FECNACIM = '00000000'` | **4.100** | Nunca se capturó |
| Títulos peruanos con tildes comidas | **1.240** | La intercalación de la importación de 2017. **Irreversible** |
| Contratos | 21.000 | Incluidos los vencidos y los de participación |
| … con **todas** las combinaciones de `TIPOCONTR` × `BASELIQUI` | ≥ 200 de cada una | **La F08 las necesita para aislar variables.** Sin esta garantía, su miniproyecto no se puede hacer |
| Facturas **con descuento** (`VLRDCTO > 0`) | 18% de las líneas | Sin descuento, las dos ramas de `BASELIQUI` dan el mismo número y el defecto es invisible |
| Movimientos de inventario | **148.000** | Treinta años |
| … del almacén de Lima | **4.300** | Es el subconjunto que exporta la fase 02 |
| … huérfanos (`CODEDIT` inexistente) | **1.900** | Sin llaves foráneas, desde siempre |
| … con `FECMOVTO = '00000000'` | **210** | El relleno de 2017 |
| … con `BORRADO = 'S'` | **3.600** | Nada se elimina nunca |
| Ventas, repartidas en 30 tablas | **500.000** | Creciendo por año: pocos miles en 1997, decenas de miles en 2026 |
| … devoluciones (`TIPOVENTA = 'D'`) | **8%** | Fechadas de dos a cinco meses **después** de la venta |
| … con `CODEDIT` inexistente | **4%** | Las huérfanas del lado de ventas |
| … con `VLRTOTAL ≠ CANTIDAD × VLRUNIT` | **2.400** | Descuentos que la tabla no guarda |
| Tasas de cambio en `TASACAMB` | 1 por moneda | **Solo la última**: la tabla se sobrescribe, y de ahí la imposibilidad de reproducir |

**Criterios de aceptación**

1. Un proyecto que puebla la base desde cero y **es idempotente**: correrlo dos veces produce
   exactamente el mismo contenido. Una consulta de conteos lo demuestra.
2. **Dos ejecuciones con la misma semilla producen bases idénticas**, comprobado con una suma de
   verificación sobre los conteos y sobre una muestra ordenada de cada tabla. Si dos lectores obtienen
   datos distintos, es un bug del generador.
3. Todos los volúmenes de la tabla de arriba se cumplen, con una consulta de verificación por fila que
   se ejecuta al final y **falla ruidosamente** si algo no cuadra.
4. Las anomalías son **consistentes entre sí**: los huérfanos apuntan a códigos que no existen, las
   devoluciones están fechadas después de su venta, las tildes comidas están solo en títulos peruanos.
   Una consulta por anomalía lo demuestra.
5. El generador **no usa el modelo de `Cordillera.Domain`**. Escribe directo contra el esquema con
   `SqlBulkCopy` o `INSERT`, porque el modelo no puede representar estos datos —es el punto— y porque
   el generador es una herramienta del curso, no parte del sistema.
6. **Medición de cierre:** tiempo total de poblar la base y tamaño del archivo de datos resultante,
   más el conteo de filas por tabla. Van en el mensaje del tag `mini-07`.

**Restricciones de estilo y alcance**

El generador **sí es código nuevo** —vive en `src/fases/07-el-sistema-que-heredas/mini/`, sobre .NET 10,
con nullable y advertencias como errores— y esa es una excepción declarada al estilo de la fase: es una
herramienta de autoría, no parte de SIGE. Lo que escribe es sucio; con qué lo escribe, no.

**Los nombres de tablas y columnas se escriben tal cual**, en mayúsculas, siempre.

**La trampa**

Vas a generar los datos y van a verse bien. Y en la fase 08, cuando escribas la primera prueba de
caracterización sobre `SP_LIQREGAL_CALC`, la prueba va a pasar la primera vez y **fallar la segunda**,
sin que nadie haya cambiado nada.

La causa no está en tu generador: está en el procedimiento, que llama a `GETDATE()`. Pero hay una
segunda causa que **sí** es tuya y que va a costar más encontrar: si el generador usa
`Random.Shared` en algún sitio, o si recorre un `Dictionary` confiando en su orden, o si construye las
fechas a partir de `DateTime.Now`, la semilla fija no alcanza — **la reproducibilidad se rompe por
dentro y en silencio**.

Cuando te pase, escribe en tres líneas las tres fuentes de no determinismo que encontraste. Es la
lección de la fase y vale más que el generador.

<details><summary>Pista 1 — el enfoque</summary>

Un generador por tabla, en orden de dependencia, cada uno recibiendo el mismo `Random` sembrado. Las
anomalías **no** se generan aparte: se generan como parte de cada tabla, con su proporción, para que
las relaciones entre ellas sean consistentes por construcción y no por reparación posterior.

Y las inserciones en lote: 500.000 `INSERT` de a uno son diez minutos que nadie quiere esperar cada
vez que reconstruye la base.

</details>

<details><summary>Pista 2 — la herramienta</summary>

`SqlBulkCopy` para las tablas grandes, con `DataTable` en el lado del generador — sí, `DataTable`, y es
el único sitio del curso donde código nuevo lo usa a propósito:
`https://learn.microsoft.com/dotnet/api/system.data.sqlclient.sqlbulkcopy`

Para la reproducibilidad, `new Random(19970417)` **y nada más**: ni `Random.Shared`, ni `Guid.NewGuid`,
ni `DateTime.Now`. Para las tildes comidas, mira qué hace `Encoding.GetEncoding(1252)` con una cadena
con tildes y cómo se comporta la intercalación `Modern_Spanish_CI_AS`.

Y para el contenedor de SQL Server, el `docker run` de la ficha oficial — con `MSSQL_PID=EnterpriseDeveloper`,
que en 2025 reemplazó al `Developer` de los tutoriales viejos.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Una sola semilla, un solo Random, pasado a todos. No hay otra fuente de azar.
internal sealed class SigeDataGenerator(SqlConnection connection, int seed = 19_970_417)
{
    public async Task<GenerationReport> PopulateAsync(CancellationToken token);
}

// Cada tabla, en orden de dependencia. Devuelve lo que generó para que el
// siguiente pueda apuntar a algo que existe — y para que los huérfanos puedan
// apuntar a algo que NO existe, a propósito.
internal interface ITableGenerator
{
    string TableName { get; }
    Task<int> GenerateAsync(GenerationContext context, CancellationToken token);
}

// El informe: los conteos que la verificación del criterio 3 compara contra la
// especificación, y la suma de verificación del criterio 2.
internal sealed record GenerationReport(
    IReadOnlyDictionary<string, int> RowsByTable,
    IReadOnlyDictionary<string, int> AnomalyCounts,
    string Checksum);
```

</details>

**Cómo se entrega**

```powershell
# El contenedor, primero
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=<clave>" -e "MSSQL_PID=EnterpriseDeveloper" `
  -p 1433:1433 --name sige-sql -d mcr.microsoft.com/mssql/server:2025-latest

# El esquema, después
sqlcmd -S localhost -U sa -i src\legacy\Sige.Database\esquema\01-tablas.sql
sqlcmd -S localhost -U sa -i src\legacy\Sige.Database\esquema\02-ventas-por-anio.sql
sqlcmd -S localhost -U sa -i src\legacy\Sige.Database\procedimientos\*.sql

# Y los datos
dotnet run -c Release --project src\fases\07-el-sistema-que-heredas\mini
```

```bash
git tag -a mini-07 -m "Mini F7: generador de datos sucios, semilla 19970417 · <N> filas en <X> s, base de <Y> MB · checksum <Z>"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Levanta el contenedor de SQL Server 2025, crea el esquema y verifica con una consulta que las
   treinta tablas de ventas existen y tienen la misma forma.
2. Escribe la consulta que encuentra los 1.900 movimientos huérfanos. Después escríbela con
   `INNER JOIN` y explica por qué devuelve otra cosa.
3. Cuenta cuántas filas de `MOVINVEN` tienen `BORRADO = 'S'` y cuántas consultas de
   `src/legacy/Sige.Database/procedimientos/` olvidan filtrarlas.
4. Compila `Sige.sln` con MSBuild y `Cordillera.slnx` con `dotnet build`. Explica en dos líneas por
   qué son dos comandos y no uno.
5. Ejecuta `dotnet format --verify-no-changes` sobre `src/legacy/` y explica qué pasa y por qué el
   `.editorconfig` de ese subárbol existe.
6. Busca en el esquema los cinco sitios donde una fecha es `char(8)` y los cinco donde es `datetime`, y
   anota cuál de las dos formas puso 2017 y cuál viene de 1997.

**🟡 Intermedio (7–14)**

7. Toma el plan de ejecución de `SP_VENTAS_HIST` y señala en él cuántos operadores de escaneo hay y
   por qué son treinta.
8. Escribe la misma consulta del reporte con un texto **estático** y parametrizado, y compara los dos
   planes. No cambies el procedimiento: escribe la tuya al lado.
9. Agrega un índice que creas que falta, mide el efecto sobre el reporte, y después **quítalo**.
   Documenta el número y por qué no se deja puesto en esta fase.
10. Lee `SP_LIQREGAL_CALC` completo y escribe, sin ejecutarlo, qué crees que hace con un contrato de
    traducción con `BASELIQUI = 'N'`. Guarda tu respuesta: la fase 08 la va a contradecir.
11. Encuentra en `InventoryDataAccess` los dos sitios donde un fallo puede quedar sin rastro, y
    explica el mecanismo de cada uno.
12. Cambia la semilla del generador y demuestra con una consulta que el conjunto de datos es distinto.
    Después restáurala y verifica que vuelve a ser el mismo.
13. Escribe la consulta que demuestra que las devoluciones están fechadas después de su venta, y
    encuentra cuántas violan esa regla en los datos generados. Si son cero, tu generador está
    demasiado limpio.
14. Mide con el arnés el tiempo de `GetStockByWarehouse` para el almacén de Lima y compáralo con el de
    Bogotá. Explica la diferencia con los conteos de la tabla del miniproyecto.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El saldo de `EXISTENC` no cuadra con la suma de `MOVINVEN` para 47 ediciones.
    Encuentra en `SP_MOVINVEN_INS` el camino por el que eso ocurre y escribe la secuencia exacta de
    operaciones que lo reproduce.
16. **Diagnóstico.** Un usuario dice que "el reporte de ventas de Cometa trae menos de lo que debería".
    Mira cómo `SP_VENTAS_HIST` pega el filtro de sello y explica en qué caso concreto el reporte
    pierde filas. *(Pista: mira el `LEFT JOIN` y el `WHERE` juntos.)*
17. **Medición.** Ejecuta la medición de la sección 6 completa, con la caché de planes limpia y
    caliente. Publica la tabla y determina **los tres umbrales**, en particular qué fracción del tiempo
    total es el motor.
18. **Medición.** Compara `SqlDataAdapter.Fill` contra `SqlDataReader` sobre el mismo procedimiento y
    determina qué fracción del tiempo y de la memoria es el `DataSet`. Ese número es entrada de la
    fase 09.
19. Escribe la lista de **todo lo que rompería** agregar una llave foránea de `MOVINVEN.CODEDIT` a
    `EDICION.CODEDIT`: cuántas filas la impiden, qué decisión de negocio haría falta, y quién la toma.
20. **Decisión — ¿se migra, se envuelve o se deja quieto?** El módulo de inventario del depósito de
    Lima **no está en SQL Server**: sigue en "el Fox", una máquina virtual con Windows XP, y manda un
    archivo plano los viernes. Lleva veintinueve años funcionando. Decide, y sostén la decisión con el
    costo de las otras dos. *(Esta es la pregunta que la fase 24 vuelve a hacer, así que guarda tu
    respuesta.)*
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** `CAMPO1` a `CAMPO7` en cuatro tablas: tres
    de ellos contienen datos en algunas filas y nadie sabe qué significan. Decide qué hace la migración
    con esas columnas, y qué se pierde en cada camino.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una consulta que el sistema resuelve bien y una migración ingenua
    resolvería mal, usando solo las rarezas del esquema —sin llaves foráneas, `BORRADO`, `char(8)`—.
    Explica qué produciría la versión ingenua y por qué nadie lo notaría.
23. **Adversarial.** Consigue que `SP_LIQREGAL_CALC` produzca **dos resultados distintos con los
    mismos datos de entrada**, sin modificar el procedimiento ni los datos. Hay al menos tres formas y
    todas son la razón por la que la fase 08 existe.
24. **Diseño y medición.** Escribe la especificación de **todo lo que la fase 08 va a necesitar** para
    caracterizar `SP_LIQREGAL_CALC`: qué tiene que ser determinista, qué se puede aislar sin tocar el
    procedimiento, y cómo se compara una salida contra otra. Es el trabajo de diseño de la 08, hecho
    desde aquí.
25. **Defiende una decisión.** Escribe el documento que **no** escribiste el día once: media página
    para Clara explicando por qué **no** vas a proponer reescribir el sistema, en su lenguaje, con la
    tabla de la sección 6 como respaldo y con lo que sí vas a hacer en los próximos tres meses.

**🔥 Opcionales**

- Instala Visual FoxPro 9 en una máquina virtual y abre un DBF. No hace falta para el curso, y
  entender de dónde vienen las limitaciones de este esquema vale la tarde.
- Investiga qué haría `PACK` en un DBF y por qué la bandera `BORRADO` de este esquema es su
  traducción literal.
- Escribe el mismo esquema como lo diseñarías hoy, con llaves foráneas y particionamiento. **No lo
  integres**: guárdalo, y en la fase 24 compáralo con lo que el curso terminó haciendo de verdad.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/sql/relational-databases/performance/execution-plans` — planes de
  ejecución: cómo se leen y qué significa cada operador.
- `https://learn.microsoft.com/sql/t-sql/statements/set-statistics-io-transact-sql` y
  `.../set-statistics-time-transact-sql` — las dos instrucciones de la medición de esta fase.
- `https://learn.microsoft.com/sql/relational-databases/stored-procedures/stored-procedures-database-engine`
  — y en particular la sección sobre SQL dinámico y reutilización de planes.
- `https://learn.microsoft.com/dotnet/api/system.data.dataset` — `DataSet` y `DataTable`, con su
  diseñador y todo. Es la documentación de lo que fue el estándar durante diez años.
- `https://learn.microsoft.com/dotnet/api/system.data.sqlclient.sqlbulkcopy` — carga masiva, para el
  generador.
- `https://learn.microsoft.com/sql/linux/quickstart-install-connect-docker` — SQL Server en
  contenedor. **Ojo:** los valores de `MSSQL_PID` cambiaron en 2025 y los tutoriales viejos usan
  `Developer`, que ya no existe.
- `https://learn.microsoft.com/dotnet/framework/migration-guide/versions-and-dependencies` — las
  versiones de .NET Framework y qué trae cada una. Es la lectura que explica por qué 4.8 y no 4.5.

**Libros / artículos**

- *Working Effectively with Legacy Code*, de Michael Feathers, es el libro de este bloque entero —
  sobre todo los capítulos de caracterización, que la fase 08 usa. Verifica edición y disponibilidad
  antes de citarlo; no se inventan páginas aquí.

**Video / apoyo**

- Las charlas sobre modernización de aplicaciones .NET Framework en los eventos de .NET cubren el
  camino de esta fase a la 11. No se citan identificadores: cambian.

> ⚠️ Verifica las URLs. Y la advertencia central de esta fase, que es la contraria a la de todas las
> demás: **aquí el material viejo es el correcto**. La documentación de `DataSet`, de `packages.config`
> y de los ASMX describe exactamente lo que tienes delante, y es el único bloque del curso donde eso
> pasa. Lo que hay que tener claro es **cuándo estás leyendo documentación del sistema heredado y
> cuándo del nuevo**, porque las dos siguen publicadas en el mismo sitio.

**Orden de lectura sugerido:** antes de escribir, la página de planes de ejecución y las dos de
`STATISTICS` — la medición de esta fase es la más importante del bloque y hay que tomarla bien. Durante
el miniproyecto, `SqlBulkCopy` y la ficha del contenedor. Después, los capítulos de caracterización de
Feathers: son la preparación de la fase 08.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe SIGE. El esquema completo de los cuatro módulos, dos de ellos implementados, la capa de datos
con `DataSet`, la cadena de conexión en el `App.config`, el `UNION ALL` de treinta tablas, y una base
poblada con treinta años de datos sucios reproducibles con una semilla. Y existe **la línea base**:
cuando en la fase 11 alguien diga que el sistema migrado es más rápido, esta tabla es lo que lo
convierte en un hecho o en una opinión.

Y existe algo más difícil de medir: escribiste 500 líneas de código que las seis fases anteriores te
enseñaron a no escribir, y las escribiste sin arreglarlas. Si te costó, es la señal correcta.

La fase 08 es el paso natural y su regla cabe en una frase: **primero la red, después el trapecio**. No
se refactoriza nada —nada— hasta que exista una prueba que diga si se rompió. Y el trabajo de verdad es
el que ningún temario de lenguaje incluye: **caracterizar con pruebas un procedimiento de setecientas
líneas que nadie ha leído completo**, hacer determinista lo que llama a `GETDATE()`, y decidir qué es
cobertura útil sobre código heredado — que no es el porcentaje. Ahí, además, vas a encontrar la regla
que la editorial cree que tiene y no aplica. Está en el código que acabas de escribir, y no la vas a
encontrar leyendo.

> **La señal de que quedó bien:** *"Puedo explicar cada rareza de este esquema con su año y su razón, y
> cuando alguien me dice que está mal hecho, sé pedirle el número de lo que costaría cambiarlo."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto
> corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-07 -m "F7 cerrada:
> - esquema completo de los cuatro modulos, con las 30 tablas anuales
> - existencias y regalias implementadas: 6 procedimientos y la capa de datos con DataSet
> - App.config con la cadena en texto plano, declarado como deuda con cobro en F16
> - SP_VENTAS_HIST medido: linea base del bloque, plan antes que .NET
> - generador de datos sucios con semilla 19970417 y volumenes verificados"
> ```
>
> **Esta fase no cobra ninguna deuda y planta la más grande del curso**, declarada por partes: el
> acceso a datos en la F09, la conexión directa del cliente en la F10, el runtime en la F11 y la
> cadena de conexión en la F16. Cuatro facturas, cuatro fases, y el `git diff` de cada una empieza en
> este tag.
>
> Y una nota propia de esta fase sobre git: **es la primera vez que un commit toca `src/legacy/`**. Los
> commits llevan el mismo prefijo (`fase 07: …`), pero conviene que el mensaje diga siempre de qué
> lado de la frontera está el cambio — cuando en la fase 09 empieces a tocar los dos lados en el mismo
> día, `git log --oneline -- src/legacy/` va a ser la única forma de saber qué le pasó al sistema
> heredado.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — la familia *datos y esquema* se abre con el reflejo de esta fase: *"esto está
  mal hecho"* en vez de *"esto está fechado"*. Es un reflejo de **arquitectura** y no de lenguaje, así
  que conviene además un puntero desde la sección de arquitectura, donde vive *"si está viejo está
  mal"* — son el mismo reflejo visto desde dos alturas.
- **`BENCHMARKS.md`** — entrada ⏳ *F07 · Línea base del reporte histórico*, con cuatro capas medidas.
  Es la entrada más citada del curso: la F09, la F11, la F20 y la F24 la usan. Conviene marcarla en el
  índice como **línea base del Bloque B**.
- **Deuda 💸 registrada:** el módulo entero, declarado por partes con cuatro fases de cobro. Ya está en
  el libro de §7.1 como cuatro entradas; conviene anotar allí que **las cuatro nacen en el mismo tag**,
  porque eso hace que las cuatro facturas sean comparables entre sí.
- **Decisión cerrada en esta fase y que cinco fases arrastran:** la **semilla `19970417`** y los
  volúmenes de la tabla del miniproyecto. Hay que copiarlos a `congelamiento-de-nombres.md` —no solo
  citarlos— porque si la F08 caracteriza contra otros números, el *golden master* no vale nada.
- **Riesgo detectado al escribir la F08 y resuelto aquí:** la caracterización necesita contratos con
  **todas** las combinaciones de `TIPOCONTR` × `BASELIQUI` y facturas con descuento, o su miniproyecto
  no se puede hacer. Las dos filas están ahora en la tabla de volúmenes. Es un ejemplo de por qué el
  generador se especifica antes de escribir la fase que lo consume.
- **Riesgo detectado y resuelto:** la F02 exportó 4.300 filas del almacén de Lima con el literal
  `"NULL"` en una columna, y ese literal es un artefacto de **cómo se exportó**, no del esquema. La
  tabla de volúmenes de esta fase incluye las 4.300 filas de Lima para que ese archivo se pueda
  regenerar de verdad; hay que dejar en la F02 una nota de que el archivo sale de aquí.
- **Para la fase 08:** el ejercicio 24 pide escribir la especificación de la caracterización. Si
  alguien lo hizo, la 08 debería partir de ahí. Y el ejercicio 10 —predecir qué hace el procedimiento
  con un contrato de traducción— está diseñado para que la 08 lo contradiga: conviene que la 08 lo cite
  explícitamente.
- **Para la fase 09:** el número del ejercicio 18 —qué fracción del tiempo y la memoria es el
  `DataSet`— es entrada directa de la decisión entre Dapper, EF Core y ADO.NET.
- **Para la fase 24:** los ejercicios 20 y 25 son las dos respuestas que el veredicto final tiene que
  revisar. El 20 es "el Fox" de Lima y el 25 es el documento que no se escribió; que el lector guarde
  los dos es parte del diseño del curso.
