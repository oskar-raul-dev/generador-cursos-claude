# 🧊 Congelamiento de nombres
## C# para desarrolladores Java senior

Este documento cierra, **antes de escribir la primera fase**, las tres cosas que veintitrés fases
arrastran y que no se pueden renombrar después sin tocarlas todas:

1. **El esquema heredado de SIGE**, tabla por tabla y columna por columna, con sus tipos y su año.
2. **El modelo de dominio nuevo**, y el borde 🧬 que traduce del uno al otro.
3. **Los nombres de soluciones, proyectos y directorios** de `src/`.

> 🧭 **Manda sobre los entregables, no sobre el marco.** En el orden de autoridad de
> `como-escribir-el-curso.md` §1 este documento va con las plantillas y los formatos: por debajo
> de `alcance-del-proyecto.md`, de la propuesta y de la guía de estilo, y por encima de cualquier
> fase ya escrita. Si una fase necesita un nombre que aquí no está, **se agrega aquí primero**.

📝 Por qué existe: la versión anterior de `README.md` escribía la F01 y la F07 antes que el resto
para que un error de nombres no se propagara entre chats que no se ven. Congelarlos aquí da la
misma garantía y deja la secuencia en el orden de los números.

---

## 1. 🏚️ El esquema heredado

**Las reglas del esquema, con su fecha y su causa** (historia §3, 1997). No se corrigen, no se
traducen, no se "arreglan de paso", y cada fase que los cite los escribe **tal cual, en
mayúsculas**:

- **Nombres de tabla de ocho caracteres**, porque DOS limitaba el nombre del archivo `.DBF` a
  ocho. `MOVINVEN`, `LIQREGAL`, `FACTDETA`.
- **Nombres de columna de diez caracteres**, porque el formato DBF limitaba el nombre de campo a
  diez. `VLRUNIT`, `FECMOVTO`, `CODEDIT`, `PORCREGAL`.
- **`BORRADO char(1)`** —`'S'` o `'N'`— en todas las tablas, herencia directa del borrado lógico
  de FoxPro, donde el registro borrado era una marca en el propio archivo. Nada se elimina nunca.
- **Fechas en `char(8)` con formato `AAAAMMDD`** en once tablas, y `datetime` en el resto. Hay
  código que convierte en los dos sentidos y no siempre igual.
- **Sin llaves foráneas.** La integridad la garantizaba el programa. Hay 1.900 filas de
  `MOVINVEN` cuyo `CODEDIT` no existe en `EDICION`.
- **`varchar` con intercalación `Modern_Spanish_CI_AS`**, no Unicode: la importación de 2017 se
  comió las tildes de los títulos peruanos y ya no se puede reconstruir.
- **`CAMPO1` a `CAMPO7`** en cuatro tablas, que en los noventa significaron algo.
- **Una tabla por año**, `VENTAS_1997` … `VENTAS_2026`.

> 📝 **La excepción aparente, y su explicación.** `VENTAS_1997` tiene once caracteres y rompe la
> regla de las ocho. No es un descuido: en FoxPro los archivos eran `VTAS97.DBF`, `VTAS98.DBF` y
> así, y **el asistente de importación de 2017 las creó con el nombre expandido**, una por una,
> tal como los pasantes las escribieron en el cuadro de diálogo. Es el único sitio del esquema
> donde se ve la mano de 2017 y no la de 1997, y las fases lo usan como pista de datación.

> 📝 **Los procedimientos almacenados no siguen la regla de los ocho**, porque nacieron en 2017
> con la migración: se llaman `SP_LIQREGAL_CALC`, `SP_VENTAS_HIST`. Ese contraste —tablas con
> límites de DBF, procedimientos sin ellos— es material didáctico de la F07 y de la F08.

### 1.1 Catálogo

**`SELLOS`** — los cuatro sellos del grupo.

| Columna | Tipo | Qué es |
|---|---|---|
| `CODSELLO` | `char(3)` | `COR`, `COM`, `SUR`, `UBA` |
| `NOMBRE` | `varchar(40)` | Cordillera, Cometa, Del Sur, Universitaria del Bajío |
| `CIUDAD` | `varchar(40)` | Bogotá, Lima, Buenos Aires, León |
| `BORRADO` | `char(1)` | |

**`AUTORES`** — autores, traductores y agentes en la misma tabla, distinguidos por `TIPOPERS`.

| Columna | Tipo | Qué es |
|---|---|---|
| `CODAUTOR` | `char(10)` | |
| `NOMBRE` | `varchar(60)` | |
| `APELLIDO` | `varchar(60)` | |
| `PAIS` | `char(2)` | ISO de dos letras |
| `TIPOPERS` | `char(1)` | `A` autor · `T` traductor · `G` agente |
| `FECNACIM` | `char(8)` | `AAAAMMDD`, y `'00000000'` en 4.100 filas |
| `BORRADO` | `char(1)` | |

**`TITULOS`** — el título como obra.

| Columna | Tipo | Qué es |
|---|---|---|
| `CODTITULO` | `char(10)` | |
| `TITULO` | `varchar(120)` | |
| `SUBTITULO` | `varchar(120)` | anulable |
| `CODSELLO` | `char(3)` | sin llave foránea a `SELLOS` |
| `CODAUTOR` | `char(10)` | un solo autor por título: la obra con dos autores se duplica, y eso es material de la F08 |
| `ANOPUBLIC` | `char(4)` | |
| `ESTADO` | `char(1)` | `B` borrador · `P` programado · `V` vigente · `D` descatalogado |
| `FECCREA` | `char(8)` | |
| `CAMPO1`…`CAMPO4` | `varchar(20)` | |
| `BORRADO` | `char(1)` | |

**`EDICION`** — la edición concreta, con su ISBN. Es la tabla que el curso cruza más veces.

| Columna | Tipo | Qué es |
|---|---|---|
| `CODEDIT` | `char(10)` | la clave que aparece en media docena de tablas |
| `CODTITULO` | `char(10)` | |
| `ISBN` | `char(13)` | con 340 filas en blanco, de antes de que el ISBN fuera obligatorio |
| `NROEDIC` | `smallint` | |
| `FECPUBLI` | `char(8)` | |
| `PRECIOVTA` | `decimal(12,2)` | precio de lista |
| `MONEDA` | `char(3)` | `COP`, `MXN`, `PEN`, `ARS`, `USD` |
| `PAGINAS` | `int` | |
| `FORMATO` | `char(2)` | `TD` tapa dura · `TB` tapa blanda · `EB` ebook · `AU` audiolibro |
| `IDIOMA` | `char(2)` | |
| `ESTADO` | `char(1)` | igual que `TITULOS.ESTADO` |
| `BORRADO` | `char(1)` | |

### 1.2 Existencias por almacén

**`ALMACEN`** — `CODALMA char(3)` (`BOG`, `MEX`, `LIM`), `NOMBRE varchar(40)`,
`CIUDAD varchar(40)`, `PAIS char(2)`, `BORRADO char(1)`.

**`MOVINVEN`** — el movimiento de inventario, y la tabla insignia del curso.

| Columna | Tipo | Qué es |
|---|---|---|
| `NROMOVTO` | `int identity` | |
| `CODALMA` | `char(3)` | |
| `CODEDIT` | `char(10)` | 1.900 filas apuntan a una edición que no existe |
| `FECMOVTO` | `char(8)` | `AAAAMMDD`, con `'00000000'` en 210 filas |
| `TIPOMOVTO` | `char(1)` | `E` entrada · `S` salida · `A` ajuste · `D` devolución |
| `CANTIDAD` | `int` | negativa en los ajustes, y eso sorprende a quien no lo espera |
| `VLRUNIT` | `decimal(12,2)` | |
| `NRODOCTO` | `char(15)` | el documento que lo respalda, en blanco en los ajustes de 2018 |
| `CODUSUA` | `char(10)` | |
| `FECHAHORA` | `datetime` | la única fecha real de la tabla, puesta por el `DEFAULT` de 2017 |
| `CAMPO1`…`CAMPO7` | `varchar(20)` | |
| `BORRADO` | `char(1)` | |

**`EXISTENC`** — el saldo, desnormalizado y recalculado por procedimiento. `CODALMA char(3)`,
`CODEDIT char(10)`, `CANTIDAD int`, `FECACTUAL char(8)`, `BORRADO char(1)`.

> 💸 Que el saldo viva en una tabla aparte y no se derive de `MOVINVEN` es la deuda de diseño más
> vieja del sistema, y **no se arregla en el curso**: se mide su divergencia en la F09 y se
> explica por qué en 1997 era la decisión correcta —recorrer los movimientos por la red coaxial
> era inviable— y por qué hoy sigue siendo la más barata de convivir.

### 1.3 Liquidación de regalías

**`CONTRATO`** — el contrato con el autor o el traductor.

| Columna | Tipo | Qué es |
|---|---|---|
| `NROCONTRA` | `char(12)` | |
| `CODTITULO` | `char(10)` | |
| `CODAUTOR` | `char(10)` | |
| `TIPOCONTR` | `char(1)` | `A` autoría · `T` traducción con participación · `C` cesión |
| `PORCREGAL` | `decimal(5,2)` | |
| `BASELIQUI` | `char(1)` | `P` sobre precio de lista · `N` sobre neto facturado. **La regla que la editorial cree que aplica siempre y no aplica siempre** |
| `FECINICIO` | `char(8)` | |
| `FECFINAL` | `char(8)` | `'00000000'` cuando no vence |
| `TERRITORIO` | `char(10)` | diez caracteres para un territorio: cabe `LATAM` y no cabe `BRASIL-POR` completo |
| `IDIOMAS` | `varchar(40)` | lista separada por comas, porque en 1997 así se hacía |
| `MONEDA` | `char(3)` | |
| `ANTICIPO` | `decimal(12,2)` | |
| `BORRADO` | `char(1)` | |

**`LIQREGAL`** — la liquidación trimestral. `NROLIQUI char(12)`, `NROCONTRA char(12)`,
`PERIODO char(6)` (`AAAATT`), `FECLIQUI char(8)`, `VLRBASE decimal(14,2)`,
`VLRREGAL decimal(14,2)`, `MONEDA char(3)`, `ESTADO char(1)` (`L` liquidado · `P` pagado ·
`I` impugnado), `BORRADO char(1)`.

**`LIQDETAL`** — el detalle. `NROLIQUI char(12)`, `NROLINEA int`, `CODEDIT char(10)`,
`CANTIDAD int`, `VLRUNIT decimal(12,2)`, `VLRNETO decimal(14,2)`, `BORRADO char(1)`.

> ⚠️ **Aquí está el bug caro de la historia, y es una ausencia, no un error.** Ni `LIQREGAL` ni
> `LIQDETAL` guardan **la tasa de cambio usada** ni **la cláusula aplicada**. La tasa se lee de
> `TASACAMB`, que se sobrescribe cada mes, así que reproducir una liquidación de hace ocho meses
> es imposible por diseño. Eso es lo que costó tres días de arqueología con la impugnación de la
> traductora, y lo que la F17 arregla de raíz.

**`TASACAMB`** — `MONEDA char(3)`, `FECTASA char(8)`, `VALOR decimal(12,6)`, `BORRADO char(1)`.
El procedimiento de liquidación lee **la fila más reciente**, no la vigente en la fecha del
cálculo.

**`LIQAUDIT`** — la tabla que la **F17 agrega**, y es el segundo y último cambio de esquema del curso.
`NROLIQUI char(12)`, `NROLINEA int`, `CODEDIT char(10)`, `CANTIDAD int`, `VLRUNIT decimal(12,2)`,
`MONEDAORIG char(3)`, **`TASAUSADA decimal(12,6)`**, **`TASAVIGDESDE char(8)`**, **`CLAUSULA varchar(40)`**,
`VLRCONVERT decimal(14,2)`, `MONEDADEST char(3)`, `OPERACION varchar(80)` con índice único, y
`FECHAHORA datetime2`.

> ⚠️ **Es tabla nueva y `LIQREGAL` y `LIQDETAL` no se tocan**, para que el proceso viejo y NightPress puedan
> correr en paralelo mientras se comparan. Las tres columnas en negrita son las que no existían y las que
> costaron tres días de arqueología con la impugnación de la traductora. Igual que el otro cambio de esquema,
> **es por riesgo y no por diseño**.

### 1.4 Facturación

**`CLIENTES`** — `CODCLIEN char(10)`, `NOMBRE varchar(80)`, `NIT varchar(20)`,
`CIUDAD varchar(40)`, `PAIS char(2)`, `CANALVTA char(1)` (`L` librería · `C` cadena ·
`D` distribuidor · `W` web propia · `P` plataforma digital), `CODDISTR char(6)`,
`BORRADO char(1)`.

**`FACTURA`** — `NROFACT char(12)`, `FECFACT char(8)`, `CODCLIEN char(10)`, `CODALMA char(3)`,
`VLRSUBTOT decimal(14,2)`, `VLRIMPTO decimal(14,2)`, `VLRTOTAL decimal(14,2)`, `MONEDA char(3)`,
`ESTADO char(1)` (`E` emitida · `A` anulada · `P` pagada), `BORRADO char(1)`.

**`FACTDETA`** — `NROFACT char(12)`, `NROLINEA int`, `CODEDIT char(10)`, `CANTIDAD int`,
`VLRUNIT decimal(12,2)`, `VLRDCTO decimal(12,2)`, `BORRADO char(1)`.

**`DISTRIBU`** — los tres distribuidores, con sus códigos congelados: **`DISMEX`** (México, semanas
ISO), **`DISCOL`** (Colombia, mes natural) y **`DISARG`** (Argentina, quincenal). El curso los nombra
por su código y por su país —"el distribuidor mexicano"—, y **no les inventa razón social**: la
historia no se amplía por cuenta de una fase (`alcance-del-proyecto.md` §5).

`CODDISTR char(6)`, `NOMBRE varchar(60)`, `PAIS char(2)`,
`CALENDARIO char(1)` (`M` mes natural · `I` semanas ISO · `Q` quincenal), `MONEDA char(3)`,
`PORCDEVOL decimal(5,2)` (tope de devolución pactado), `BORRADO char(1)`.

### 1.5 Ventas, por año

**`VENTAS_1997` … `VENTAS_2026`** — treinta tablas con la misma forma exacta.

| Columna | Tipo | Qué es |
|---|---|---|
| `NROVENTA` | `int` | único dentro de su tabla, **no entre tablas** |
| `FECVENTA` | `char(8)` | |
| `CODEDIT` | `char(10)` | |
| `CODCLIEN` | `char(10)` | |
| `CODALMA` | `char(3)` | |
| `CODDISTR` | `char(6)` | en blanco en la venta directa |
| `CANTIDAD` | `int` | negativa en la devolución |
| `VLRUNIT` | `decimal(12,2)` | |
| `VLRTOTAL` | `decimal(14,2)` | y no siempre es `CANTIDAD * VLRUNIT` |
| `MONEDA` | `char(3)` | |
| `CANALVTA` | `char(1)` | |
| `TIPOVENTA` | `char(1)` | `I` sell-in · `O` sell-out · `D` devolución |
| `CAMPO1`…`CAMPO7` | `varchar(20)` | |
| `BORRADO` | `char(1)` | |

### 1.6 Lo demás que existe y que el curso no construye

**`USUARIOS`** — `CODUSUA char(10)`, `NOMBRE varchar(60)`, ~~`CLAVE varchar(32)`~~ (MD5 sin sal, de 2017),
`ROL char(2)`, `BORRADO char(1)`.

> ⚠️ **Cambio de esquema, el primero de dos en todo el curso.** La **F16 borra la columna `CLAVE`** y deja la
> tabla: las filas siguen como registro histórico porque `SP_FACTURA_EMITIR` y tres procedimientos más
> escriben `CODUSUA` como campo de auditoría. La razón del cambio **no es de diseño: noventa hashes MD5 sin
> sal son un riesgo**, y ese es el criterio para tocar un esquema de 1997.

**`FR_TMP`** — sin columnas documentadas, sin filas desde 2004, con las iniciales de Fabio
Rincón. Nadie la ha borrado en treinta años. Aparece una vez, en la F07, como lo que es: la
prueba de que en este sistema borrar algo da más miedo que dejarlo.

> 🧭 **Regla 2 de la guía §11 aplicada aquí.** Los otros 690 procedimientos, los 339 formularios
> y el módulo de inventario de Lima **existen en la historia y no en `src/`**. Ninguna fase
> afirma nada verificable sobre ellos.

### 1.7 Los once procedimientos que el curso sí escribe

| Procedimiento | Módulo | Fase | Lo que enseña |
|---|---|---|---|
| `SP_EXIST_ALMACEN` | existencias | F07 | la consulta que el formulario llama en el `Click` |
| `SP_MOVINVEN_INS` | existencias | F07 | la inserción que actualiza `EXISTENC` en la misma transacción… casi siempre |
| `SP_EXIST_RECALC` | existencias | F07 | el recálculo que Duván corre a mano cuando el saldo no cuadra |
| `SP_LIQREGAL_CALC` | regalías | F07 | **setecientas líneas**, llama a `GETDATE()` y lee `TASACAMB` por fecha máxima. El corazón de la F08 |
| `SP_LIQREGAL_DETALLE` | regalías | F07 | el detalle que no guarda ni tasa ni cláusula |
| `SP_LIQREGAL_ANULA` | regalías | F07 | el que marca `BORRADO='S'` en cascada, a mano |
| `SP_CATALOGO_VIGENTE` | catálogo | F08 | el que olvida filtrar `BORRADO` en dos de sus tres ramas |
| `SP_TITULO_BUSCAR` | catálogo | F08 | búsqueda con `LIKE '%'+@texto+'%'` y el problema de las tildes comidas |
| `SP_CATALOGO_VOLCADO` | catálogo | F08 | el volcado CSV nocturno, uno de los cuatro desincronizados |
| `SP_FACTURA_EMITIR` | facturación | F08 | la transacción que escribe `FACTURA`, `FACTDETA`, `MOVINVEN` y `VENTAS_AAAA` |
| `SP_VENTAS_HIST` | facturación | F08 | **el `UNION ALL` de treinta tablas armado concatenando cadenas**. La línea base de medición del Bloque B |

---

## 2. 🧬 El modelo nuevo, y el borde

El diccionario del dominio está en la guía §5.2 y no se repite aquí. Lo que se congela es **la
correspondencia**, que es lo que ninguna fase puede improvisar. El borde vive en un solo sitio y
cada cruce se marca 🧬.

| Heredado | Modelo nuevo | Qué pasa en el borde |
|---|---|---|
| `TITULOS` | `Title` | |
| `TITULOS.CODTITULO` | `Title.Id` (`TitleId`) | `char(10)` con relleno de espacios: se recorta al leer, y esa decisión se toma una vez |
| `EDICION` | `Edition` | |
| `EDICION.CODEDIT` | `Edition.Id` (`EditionId`) | |
| `EDICION.ISBN` | `Edition.Isbn` (`Isbn?`) | 340 filas en blanco: el tipo se valida al construirse, así que la ausencia es `null` y no un `Isbn` inválido |
| `EDICION.PRECIOVTA` + `MONEDA` | `Edition.ListPrice` (`Money`) | dos columnas, un tipo. Es el sitio donde se cobra la deuda 💸 de `Money` de la F01 |
| `EDICION.FORMATO` | `Edition.Format` (`EditionFormat`) | `char(2)` a `enum`, y el `switch` de expresión tiene que decidir qué hace con un valor que no conoce |
| `EDICION.ESTADO` | `Edition.Status` (`TitleStatus`) | Independiente del estado del título: hay títulos vigentes con una edición descatalogada y otra en imprenta |
| `TITULOS.CODSELLO` | **`Edition.Imprint`** | **Desnormalización deliberada:** el sello no está en `EDICION`, y el borde lo resuelve al cargar. Se defiende porque el sello de un título no cambia nunca y porque casi toda consulta del catálogo filtra por él — cargar el `Title` completo para leer un `char(3)` sería un `N+1` autoinfligido. El tipo de lectura que junta `Title` y `Edition` llega en la F15, con los DTO del contrato |
| `SELLOS` | `Imprint` | |
| `AUTORES` con `TIPOPERS` | `Author` · `Translator` · `Agent` | una tabla, tres tipos: el borde decide por `TIPOPERS` y el pattern matching es la herramienta |
| `ALMACEN` | `Warehouse` | |
| `MOVINVEN` | `InventoryMovement` | |
| `MOVINVEN.FECMOVTO` | `.MovedOn` (`DateOnly?`) | `char(8)` a `DateOnly`, con `'00000000'` → `null` y el tercer caso, la cadena vacía |
| `MOVINVEN.TIPOMOVTO` | `.Kind` (`MovementKind`) | |
| `MOVINVEN.VLRUNIT` | `.UnitPrice` (`Money`) | la moneda no está en `MOVINVEN`: se resuelve desde `ALMACEN.PAIS`, y **ese es el tipo de decisión que el borde documenta** |
| `EXISTENC` | `StockItem` | |
| `CONTRATO` | `Contract` | |
| `CONTRATO.TERRITORIO` + `IDIOMAS` | `Contract.Assignments` (`RightsAssignment[]`) | diez caracteres y una lista separada por comas se convierten en un conjunto de cesiones. Es el borde más caro del curso y el que alimenta AcervoRAG |
| `CONTRATO.BASELIQUI` | `Contract.RoyaltyBase` (`RoyaltyBase`) | |
| `LIQREGAL` | `Settlement` | |
| `LIQDETAL` | `SettlementLine` | el modelo nuevo **agrega** `ExchangeRateUsed` y `ClauseRef`, que el esquema no tiene: es la F17 |
| `TASACAMB` | `ExchangeRate` | con `ValidFrom`, que la tabla no tiene |
| `FACTURA` / `FACTDETA` | `Invoice` / `InvoiceLine` | |
| `CLIENTES` | `Customer` | |
| `CLIENTES.CANALVTA` | `Customer.Channel` (`SalesChannel`) | |
| `DISTRIBU` | `Distributor` | |
| `VENTAS_AAAA` con `TIPOVENTA` | `SellIn` · `SellOut` · `Return` | una tabla al año y tres conceptos del negocio: el borde los separa, y la F21 depende de que estén separados de verdad |
| `BORRADO = 'S'` | — | **no existe en el modelo.** Se filtra en el borde, y los tres sitios donde EF Core no aplica el filtro global son la trampa de la F09 |
| `CAMPO1`…`CAMPO7` | — | **no cruzan el borde.** Se leen, se registran en un diccionario sin tipo y se dejan ahí |

**Los tipos del dominio que nacen en la F01**, con su nombre definitivo: `Title`, `TitleId`,
`TitleStatus`, `Edition`, `EditionId`, `EditionFormat`, `Isbn`, `Money`, `StockItem`,
`WarehouseCode`, `Imprint`, `ImprintCode`. Los demás nacen cuando su fase los necesita, y ninguna
fase los renombra.

**Los que nacen en la F02**, porque son la forma en que el curso representa la ausencia y **ninguna
fase posterior puede inventar otro tipo para lo mismo**:

- **`LegacyDate`** — una fecha que viene de un `char(8)` de 1997, con su sabor de ausencia adentro.
- **`LegacyDateKind`** — `Present`, `WasNull`, `WasBlank`, `PlaceholderFrom2017`, `PartialOnlyYear`,
  `Unparseable`. Los cinco últimos corresponden a un origen distinto y a un dueño distinto del
  arreglo, y por eso son cinco y no uno.
- **`IsbnStatus`** — `Assigned`, `NotApplicable` (anterior a 2007, nunca tuvo), `Missing` (debería
  tener y hay que ir al archivo físico).

> 🧭 **La regla que sale de la F02 y aplica a todo el curso:** una ausencia sin significado es
> `null`; una ausencia con significado es un tipo. `Title.Subtitle` es `string?`; una fecha del
> esquema heredado es `LegacyDate`.

**Los que nacen en el resto del Bloque A (F03–F06).** Aparecieron al escribir y quedan congelados aquí
porque la F21 los necesita para separar sell-in de sell-out y **no puede inventar otros para lo mismo**:

> ⚠️ **`SalesRow` no tiene `IsValid` ni `RejectionReason`.** Una fila que existe es válida por
> construcción: lo que devuelve el lector es un **`ParsedLine`** con la fila **o** el motivo por el que
> la línea no lo es, nunca las dos cosas ni ninguna. Es la política de errores de la F04 aplicada al
> tipo, y ninguna fase posterior le agrega una bandera de validez.
>
> Y **`SalesRow` tampoco trae el sello**: `VENTAS_AAAA` solo tiene `CODEDIT`, así que el sello se
> resuelve con una búsqueda que devuelve `ImprintCode?` — `null` para las 1.900 filas huérfanas. Por eso
> `ReportKey.Imprint` y `HistoryKey.Imprint` son anulables.

- **Importación y ventas** — `SalesRow`, `ParsedLine`, `SalesPeriod`, `SalesChannel`, `SalesKind`
  (`SellIn`, `SellOut`, `Return`), `SalesLineError`,
  `DistributorFile`, `DistributorFormat`, `LoadSummary`, `LoadOutcome` (`Complete`, `Interrupted`,
  `CouldNotOpen`), `AuditTrailWriter`.
- **Reporte** — `ReportKey`, `HistoryKey`, `SalesFigures` (con `SellIn`, `SellOut`, `Returns`),
  `SalesSummary`.
- **Errores del dominio** — `DomainException` como base, con `BusinessRuleException` y
  `LegacyDataException`. **Dos niveles, no siete**, y ninguna fase agrega un tercero sin declararlo.

**Los que nacen en el Bloque B (F09–F11).** El borde y el corte, que quince fases citan:

- **El borde 🧬 (F09)** — `LegacyBoundary` (el archivo que concentra las cuatro traducciones),
  `SigeContext`, `InventoryMovementConfiguration`, `CatalogEntry`, `CatalogRow`,
  `ReconciliationResult`, y la vista **`V_VENTAS`** que hace consultables las treinta tablas anuales.
  `CatalogEntry` es el importante: es el tipo de lectura que la F01 aplazó y que la F15 necesita para el
  contrato público.
- **El corte (F10)** — `CutoverSwitch`, `CutoverOptions`, `CutoverPath`, `DualWriteInventoryService`,
  `LegacyInventoryGateway`, `IDivergenceLog`, `ReconciliationReport`, `Invariant`, `RollbackReport`, y
  del track `cv`: `ConvivirGateway`, `InstitutionalSubscription`.
- **El runtime (F11)** — `IReportRenderer`, `LegacySettings`, `UnmigratedItem`, `SoapEnvelope`.

**Los que nacen en el Bloque C (F12–F14).** El escritorio, y el modelo de vista que resultó portátil:

- **El cliente (F12)** — `InventoryApiClient`, `QueryCoordinator`, `StockQueryResult`, `StockRow`. Y
  `Sige.Forms` se mueve a `src/modern/` con su estilo de 2017 declarado.
- **WPF y MVVM (F13)** — `Sige.Desktop`, `Sige.Desktop.Tests`, `StockViewModel`, `ViewModelBase`,
  `RelayCommand`, `AsyncCommand`, `IInventoryClient`, `InventoryUnavailableException`.
- **El veredicto (F14)** — `Sige.WinUI`, `Sige.Hybrid`, y **la tabla como dato**: `DesktopOption`,
  `DeploymentCost`, `MaintainabilityScore`. La F18 completa la columna de la web sobre esos tipos.

**Los que nacen en el Bloque D (F15–F17).** El contrato, la identidad y el trabajo de fondo:

- **El contrato (F15)** — `EditionResponse`, `EditionQuery`, `CatalogPage<T>`, `CatalogCriteria`,
  `ICatalogQueries`, `EditionMapping`, `DeprecationPolicy`, `StockSummary`, **`StockLine`** (el tipo de
  lectura de existencias, hermano de `CatalogEntry`), y el espacio de nombres **`Contracts.V1`**, que
  **no se mezcla con el dominio**.
- **Identidad y secretos (F16)** — `SigeOptions`, `SecretsProviderExtensions`, `SecretCommands`, y las
  políticas `EditorialStaff`, `ReadCatalog` y `PublicDuringCsvTransition` —la última con fecha de retiro, que
  la F20 cobra junto con la paginación—.
- **Trabajo de fondo (F17)** — `Currency`, `ConvertedMoney`, `ExchangeRate`, `ExchangeRateSet`,
  `CurrencyMismatchException`, `SettlementRun`, `SettlementBatch`, `SettlementPeriod`,
  `SettlementOperationKey`, `SettlementRunResult`, `BatchOutcome`, `AuditLine`, `SettlementExplanation`,
  `ISettlementRuns`, `ISettlementCalculator`, `IAuditTrail`, `OutboxMessage`,
  `DuplicateOperationException`.

> 🧭 **Dos reglas de diseño del Bloque D que ninguna fase posterior rompe:** `Money` **lleva su moneda** desde
> la F17, y **una conversión devuelve `ConvertedMoney` con la tasa adentro** — no hay sobrecarga que convierta
> sin registrar. Y **`ISettlementCalculator` calcula y no escribe**: la transacción la abre quien coordina, de
> modo que las reglas de regalías se prueban sin base de datos.

**Los que nacen en el cierre del Bloque D (F18–F20).** La web, la observabilidad y la factura:

- **Redacción y los tres modelos de render (F18)** — `IManuscriptService`, `DatabaseManuscriptService`,
  `ApiManuscriptService`, `ManuscriptIntakeForm`, `ManuscriptSummary`, `ManuscriptFilter`,
  `RegisterManuscript`, `CorrectManuscript`, `ManuscriptRejectedException`, `Genre`,
  `LatencyInjectionMiddleware`, `NetworkProfile`.
- **Observabilidad (F19)** — `CordilleraTelemetry` (con `ActivitySourceName` y `MeterName`),
  `TracedProcedureRunner`, `AccessAuditMiddleware`, **`AuditableResource`**, `CatalogMetrics`.
- **El contenedor y la factura (F20)** — `CostSheet`, `CostLine`, `Quantity`, `CostGrowth`,
  `HostingOption`, `Payback`. Y los `Dockerfile` de los cuatro proyectos modernos más el de
  `Sige.Reports`.

> 🧭 **Tres decisiones de nombres del cierre del bloque que ninguna fase posterior rompe.** (1) **El componente
> de Redacción es un solo archivo** y lo único que cambia entre los tres modelos de render es el registro de
> dependencias: si alguna fase duplica el formulario, la comparación de la F18 deja de medir modelos de render y
> empieza a medir dos implementaciones. (2) **`AuditableResource` existe para que registrar el objeto completo no
> compile** — es una defensa de tipos contra la filtración de datos personales, no una comodidad, y quitarla
> reabre la trampa de la F19. (3) **`CostLine` exige fuente, fecha y región**: son propiedades `required` a
> propósito, porque una cifra de costo sin ellas no se puede reverificar (`BENCHMARKS.md`, regla 6).

> 📝 **Los tres proyectos de Redacción se quedan**, marcados como prototipos de medición, aunque el veredicto
> elija uno. La razón es la F24: va a querer revisar la decisión con el código delante, y borrar los dos
> perdedores deja el veredicto sin respaldo. Es el mismo criterio con que `Sige.WinUI` y `Sige.Hybrid`
> sobrevivieron a la F14.

> 📝 **`Cordillera.Costos` es el único proyecto del curso que no sirve al dominio, y vive en `modern/` con los
> demás.** Moverlo a un `src/tools/` aparte contradiría tipográficamente la tesis de la F20 —que la factura es
> parte de la arquitectura— y el curso no tiene un tercer subárbol por la misma razón que no lo tiene para el
> código a medio migrar.

> 🧭 **Y una excepción declarada al borde 🧬:** la **F19 escribe en `legacy/Sige.Database/`** —el contexto de
> sesión y la sesión de eventos extendidos— y eso **no** es una migración: es instrumentación. `Sige.Database`
> puede recibir archivos de observabilidad **sin cambiar de estilo y sin moverse a `modern/`**. Es el único caso
> del curso en que se toca el legado sin que cambie de generación, y está permitido porque lo que entra no es
> lógica de negocio.

**Los que nacen en el Bloque E y en el cierre (F21–F23).** Los datos, la IA y el duelo:

- **Datos y ONNX (F21)** — `SalesObservation`, `CalendarPolicy`, `ReturnCurve`, `CountryCode`,
  `PrintRunRequest`, `PrintRunPrediction`, `PrintRunAdvice`, `PrintRunRounding`, `IPrintRunModel`,
  `OnnxPrintRunModel`, `FeatureEncoder`, `ModelFingerprint`. Proyecto nuevo **`Cordillera.Ventas`**, con su
  directorio `consultas/`.
- **IA aplicada (F22)** — `EvaluationCase`, `ExpectedOutcome`, `EvaluationReport`, `CitationVerifier`,
  `VerificationResult`, `RightsQuestion`, `RightsAnswer`, `RightsScope`, `RefusalReason`, `Clause`,
  `IClauseStore`, `LanguageCode`, `TerritoryCode`, `CachedEmbeddingGenerator`, `IEmbeddingCache`,
  `TriageAgent`, `TriageCard`, `ICatalogTools`, `ComparableTitle`, `Manuscript`. Proyecto nuevo
  **`Cordillera.IA.Evaluacion`**, que es **compartido** y por eso no vive dentro de ninguno de los dos
  sistemas de IA.
- **El duelo (F23)** — no crea tipos del dominio. Crea el subárbol `src/duelo/` y su
  `DEFENDIBILIDAD.md`.

> ⚠️ **`ClauseRef` ya existía desde la F17** —`SettlementLine.ClauseRef`, para explicar una liquidación— y la
> **F22 no crea otro tipo para lo mismo**: usa ese. Que una referencia a una cláusula sirva igual para explicar
> un pago y para sostener una respuesta de derechos es una coincidencia afortunada, y aprovecharla en vez de
> duplicar es la regla de este documento funcionando.

> 🧭 **Tres decisiones de nombres del Bloque E que ninguna fase posterior rompe.** (1) **`SalesObservation` lleva
> `AsOf` requerido**: en este dominio un número es un número **y la fecha en que se miró**, y una propiedad
> `required` obliga a decidir donde un parámetro opcional se olvida. (2) **`SalesFigures` es el tipo de la F03 y
> no se duplica**: que el modelo del Bloque A ya separara sell-in, sell-out y devolución es lo que hizo posible
> la F21 — con un solo campo `Sales`, allí empezaba una reescritura. (3) **`ExpectedOutcome.MustRefuse` existe
> para que el conjunto de prueba no premie a un sistema hablador**; quitarlo reabre la trampa de la F22.

> 📝 **`Cordillera.Costos` (F20) y `Cordillera.IA.Evaluacion` (F22) son los dos proyectos del curso que no sirven
> al dominio**, y los dos viven en `modern/` con los demás. En el primero porque la tesis de la F20 es que la
> factura es parte de la arquitectura; en el segundo porque el aparato de evaluación **es** el contenido de la
> F22 y no una herramienta auxiliar. Moverlos a un `tools/` los contradiría tipográficamente.

> 🧭 **`StockViewModel` no tiene ni un tipo de WPF, y eso resultó valer más de lo que la F13 prometía:**
> sirvió sin cambios para **WinForms, WPF, WinUI 3 y Blazor Hybrid**. Ninguna fase posterior le agrega una
> dependencia de interfaz — si lo hace, pierde esa propiedad y la F18 se queda sin su atajo. ✅ **Y la F18 lo
> usó:** el mismo modelo de vista funciona en un componente de Blazor sin cambios, que es la quinta tecnología
> de interfaz sobre el mismo código y algo que la F13 no había prometido.

**Y dos proyectos nuevos en `src/modern/`:**

- **`Cordillera.Ops`** — la herramienta de operación: `cutover --status`, `--percentage`, `--rollback`,
  `reconcile`. Nace en la F10 y es lo que una persona ejecuta a las tres de la tarde de un martes.
- **`Sige.Billing` y `Sige.Billing.Api`** — el módulo que la F11 migra. **Y aquí va la regla que faltaba:**

> 🧭 **Un proyecto que migra de runtime se mueve de `legacy/` a `modern/` y declara su estilo viejo en su
> propio `.csproj`** (`Nullable=disable`, advertencias no como errores). **No hay un tercer subárbol**, y
> es deliberado: un directorio intermedio sería el sitio donde se esconde el código que nadie termina de
> migrar. El estilo de 2017 se conserva en el archivo; lo que cambia es el runtime y de qué
> `Directory.Build.props` hereda.

---

> 🧭 **Y dónde viven los instrumentos de medición, que era una decisión pendiente de la F03:**
> `CountingEnumerable<T>` y `MemoryReading` van en **`Cordillera.Bench`**, no en `Cordillera.Domain`.
> Los dos son instrumentos y no dominio, y las fases 06, 09 y 17 los usan para lo mismo. Resuelto al
> escribir la F06.

> ⚠️ **`Book` está prohibido** como identificador (guía §5.2), y `Libro` también. Siempre `Title`,
> `Edition` o `StockItem`.

---

## 3. 🗂️ `src/`, soluciones y proyectos

La propuesta §11 deja elegir entre un directorio por fase y un directorio por proyecto, y
permite el híbrido. **Se elige el híbrido**, porque el curso tiene las dos clases de código: lo
que atraviesa fases y lo que vive en una sola.

```text
src/
  global.json                     ← fija el SDK por repositorio · 10.0.401
  nuget.config                    ← una sola fuente, declarada
  .editorconfig                   ← formato y analizadores de lo nuevo
  Sige.sln                        ← la solución heredada, formato de 2017 · net48
  Cordillera.slnx                 ← la solución nueva, formato SLNX · net10.0
  legacy/
    .editorconfig                 ← relaja los analizadores: este código no se moderniza
    Directory.Build.props          ← net48, sin nullable, sin advertencias como errores
    Sige.Forms/                   ← WinForms de 2017 · F07, F12
    Sige.DataAccess/              ← DataSet y SqlDataAdapter · F07
    Sige.AsmxServices/            ← los ASMX de 2019 · F11
    Sige.Reports/                 ← Crystal Reports · F11, F14
    Sige.Database/                ← esquema, procedimientos y datos sucios · F07, F08
      esquema/  procedimientos/   ← F07
      observabilidad/             ← eventos extendidos · F19 (no cambia de estilo ni se mueve)
  modern/
    Directory.Build.props          ← net10.0, nullable, advertencias como errores
    Directory.Packages.props       ← Central Package Management
    Cordillera.Bench/             ← el arnés, biblioteca · nace en la F00, lo usan las 24
    Cordillera.Bench.Cli/         ← el arnés, herramienta de consola · el miniproyecto de la F00
    Cordillera.Bench.Tests/       ← las pruebas del arnés · la primera prueba del curso
    Cordillera.Domain/            ← el modelo · nace en la F01
    Cordillera.Data/              ← el borde 🧬 · nace en la F09
    Cordillera.Catalog.Api/       ← CatalogAPI · nace en la F09
    Cordillera.Ops/               ← la herramienta de operación · nace en la F10
    Sige.Billing/                 ← migrado de legacy/ en la F11, con su estilo viejo declarado
    Sige.Characterization.Tests/  ← las pruebas de caracterización · nacen en la F08
    Cordillera.NightPress/        ← NightPress · nace en la F17
    Sige.Desktop/                 ← el cliente en WPF con MVVM · nace en la F13
    Sige.Desktop.Tests/           ← las 9 pruebas sin interfaz · el argumento de la F13
    Sige.WinUI/                   ← prototipo de WinUI 3 · F14
    Sige.Hybrid/                  ← prototipo de Blazor Hybrid · F14
    Cordillera.Redaccion.Web/     ← Redacción, Blazor Server · nace en la F18
    Cordillera.Redaccion.Wasm/    ← el mismo componente en WebAssembly · F18
    Cordillera.Redaccion.Mvc/     ← el mismo formulario en MVC clásico · F18
    Cordillera.Costos/            ← la hoja de costos como código · nace en la F20
    Cordillera.Ventas/            ← la canalización de ventas · nace en la F21
      consultas/                  ← el SQL analítico, incluida la curva de devolución
    Cordillera.IA.Evaluacion/     ← el aparato de evaluación, COMPARTIDO · nace en la F22
    Cordillera.Acervo/            ← AcervoRAG · nace en la F22
    Cordillera.EditorAgent/       ← EditorAgent · nace en la F22
  duelo/                          ← 🪦 el TERCER subárbol, y la única excepción · F23
    DEFENDIBILIDAD.md             ← se escribe antes de medir y se publica con la tabla
    compose.yml
    dotnet/   jvm/                ← las dos implementaciones del mismo endpoint
    resultados/
  fases/
    01-tipos-valor-y-referencia/
      mini/                       ← el miniproyecto 🧱 de la fase, y nada más
    02-nullable-y-pattern-matching/
    …                             ← 🪦 la F00 no tiene directorio aquí: ver la regla de abajo
```

**Las reglas que eso impone**, y que toda fase respeta:

- **El directorio de `fases/` se llama exactamente igual que el `.md` de su fase**, sin la
  extensión. Es la convención de nombres de este curso.
- 🪦 **Y contiene `mini/` y nada más.** El plan original le daba también un `demo/` para "lo que la
  sección 5 de la fase ejecuta", y las veinticinco fases demostraron que no hacía falta: **ninguna
  sección 5 produce código desechable**. Lo que escribe cada fase entra en un proyecto que el curso
  carga —`Cordillera.Domain`, `Sige.DataAccess`, `Cordillera.Catalog.Api`— porque toda fase tiene
  que mover al menos uno. Un `demo/` habría sido el sitio donde se esconde el código que no se supo
  ubicar, que es el mismo argumento por el que este curso no tiene apéndices.
- 🪦 **Hay un tercer subárbol, `src/duelo/`, y es la única excepción — declarada al escribir la F23.**
  La regla decía "dos subárboles y no hay un tercero", y su razón era que un directorio intermedio se
  convierte en el sitio donde se esconde el código a medio migrar. **`src/duelo/` no la contradice**,
  porque lo que vive ahí **no es código de Cordillera**: son dos implementaciones del mismo endpoint
  —una en ASP.NET Core y otra en Spring Boot— que existen para medir y **no entran en producción**.
  Mezclarlas con `modern/` confundiría el sistema con el experimento. Es también el único sitio del
  repositorio con código Java, y el único cuyo entregable es una tabla y no un binario.
- **Dos soluciones y dos subárboles para el sistema.** El legado vive en `legacy/` y lo nuevo en
  `modern/`, cada uno con su `Directory.Build.props`: uno con nullable y advertencias como
  errores, el otro sin nada de eso. La frontera entre generaciones es **física**, y por eso
  ningún `.csproj` puede estar en las dos soluciones. Convivir en el mismo repositorio con dos runtimes es el punto, y
  `00-convencion-de-git-y-tags.md` explica cómo se etiqueta una fase mixta 🧬.
- **Los miniproyectos no tocan `legacy/` ni `modern/`** (`formato-de-miniproyectos.md` §5). Leen su salida,
  consumen su API o miden contra su implementación, y viven en `fases/NN-…/mini/`.
- 🪦 **La F00 es la única excepción, y está declarada.** Su miniproyecto es `Cordillera.Bench.Cli`,
  que vive en `modern/` y **no** en `fases/00-…/mini/`. La razón es la misma que sostiene la regla,
  leída al revés: la regla existe para que un miniproyecto mal resuelto no arrastre el error hasta
  el final, y por eso se mantienen aparte de lo que el curso carga. El arnés **es** lo que el curso
  carga — las veinticuatro fases siguientes lo invocan en su sección 6 y ninguna mide con otra cosa.
  Meterlo en `fases/00-…/mini/` obligaría a las veinticuatro a apuntar a un directorio de fase, que
  es exactamente lo que esta estructura separa. **Consecuencia:** la F00 no tiene directorio bajo
  `fases/`, porque tampoco su sección 5 produce nada que viva ahí — lo que escribe es el esqueleto
  del repositorio y la biblioteca del arnés.
- **El nombre del ensamblado es el del directorio.** Sin `.Impl`, sin `.Core`, sin `.Common`.
- **Las pruebas viven al lado de su proyecto, con sufijo `.Tests`.** `Cordillera.Bench.Tests` está
  en `modern/`, junto a `Cordillera.Bench`. No hay un directorio `tests/` aparte: en .NET el
  proyecto de pruebas es un proyecto más, y separarlos en árboles distintos es un hábito de Maven
  que aquí no compra nada.

> ⚠️ **La única excepción a "los miniproyectos no tocan los proyectos del curso"** es la Fase 00, y está
> declarada: su miniproyecto es **el arnés**, que por definición no puede nacer como código
> desechable porque lo usan las veinticuatro fases siguientes. La sección 5 de la F00 construye la
> biblioteca `Cordillera.Bench` y el miniproyecto construye `Cordillera.Bench.Cli` encima; las dos
> quedan en `modern/`. Ninguna otra fase repite esta excepción.

### 3.1 El idioma de los identificadores del código heredado

La guía §5 obliga a **inglés en todo el código nuevo del curso**, y §5.1 exime solo al **esquema**.
Queda la pregunta de qué hacen los identificadores de C# del legado, que el curso también escribe.

🪦 **Decisión: el C# heredado también va en inglés.** `StockForm`, `InventoryDataAccess`,
`GetStockByWarehouse`. Lo que lo hace de 2017 es **el estilo** —`DataSet`, `SqlConnection` en el
manejador del botón, sin `var`, sin LINQ, sin `async`— y no el idioma de los nombres. Las razones:

- La regla de la guía no admite excepciones, y una excepción inventada aquí se propagaría a cinco
  fases sin quedar escrita en ningún sitio.
- El contraste que el curso quiere enseñar es de generación, no de idioma. Si el legado estuviera
  además en español, el lector atribuiría al idioma lo que es del estilo.
- Y el único sitio donde el español es obligatorio sigue siendo obligatorio: el esquema, los
  comentarios, los mensajes de error y de log, y lo que ve el usuario.

> 📝 Los textos de los formularios de SIGE **sí están en español**, porque los leen las noventa
> personas de Cordillera: `btnConsultar` se llama así en el código y dice "Consultar" en pantalla.

---

## 3.2 🎲 La semilla y los volúmenes del generador — congelados en la F07

Cinco fases dependen de estos números y **no se citan: se copian aquí**, porque si la F08 caracteriza
contra otros volúmenes el *golden master* no vale nada y la F09 mide contra otra base.

**Semilla: `19970417`.** Fija, escrita, y no se cambia nunca.

| Qué | Cuánto |
|---|---|
| Sellos · almacenes · distribuidores | 4 · 3 · 3 |
| Títulos, y de ellos vivos | **18.000**, de los cuales **11.000** |
| Ediciones | **26.400** — con **340** sin ISBN y **3.100** con ISBN de 10 dígitos |
| Autores, traductores y agentes | 6.200 — con **4.100** con `FECNACIM = '00000000'` |
| Títulos peruanos con tildes comidas | **1.240**, irreversible |
| Contratos | 21.000 — con **≥ 200 de cada combinación** de `TIPOCONTR` × `BASELIQUI` |
| Facturas con descuento (`VLRDCTO > 0`) | **18%** de las líneas |
| Movimientos de inventario | **148.000** — **4.300** de Lima, **1.900** huérfanos, **210** con `FECMOVTO = '00000000'`, **3.600** con `BORRADO = 'S'` |
| Ventas en 30 tablas | **500.000** — **8%** devoluciones fechadas después de su venta, **4%** huérfanas, **2.400** con `VLRTOTAL ≠ CANTIDAD × VLRUNIT` |
| Tasas en `TASACAMB` | **una por moneda**, y es deliberado: dos con la misma fecha hacen no determinista `SP_LIQREGAL_CALC` |

> ⚠️ **Las dos filas de contratos y facturas con descuento existen por la F08.** Sin ≥ 200 de cada
> combinación no se pueden aislar variables, y sin descuento las dos ramas de `BASELIQUI` dan el mismo
> número y **el defecto de nueve años es invisible**.

---

## 4. Qué hacer si falta un nombre

Tres pasos, en este orden, y ninguno es "lo decido en la fase y ya":

1. **Buscarlo aquí y en la guía §5.2.** Si está, se usa tal cual.
2. **Si no está y es del dominio o del esquema**, se agrega a este documento con su tipo, su año
   y su porqué, y después se usa. El `git diff` de este archivo es el registro de cuándo entró
   cada nombre al curso.
3. **Si no está y es de una decisión que afecta a otra fase**, sube además a
   `propuesta-fases-y-alcance.md` antes de cerrar el chat (`como-escribir-el-curso.md` §4).
