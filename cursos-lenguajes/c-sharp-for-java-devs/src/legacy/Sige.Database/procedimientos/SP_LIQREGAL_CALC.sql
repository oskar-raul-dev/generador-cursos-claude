/*
  SP_LIQREGAL_CALC - la liquidacion trimestral de regalias.
  -----------------------------------------------------------------------------
  Junto con SP_LIQREGAL_DETALLE y SP_LIQREGAL_ANULA pasan de setecientas lineas.
  Corre como un trabajo del SQL Server Agent, tarda seis horas, fallo en la
  hora cinco dos veces el anio pasado, y cuando falla se reinicia desde cero.

  Las cuatro cosas que lo hacen imposible de probar tal cual, y que la fase 08
  tiene que resolver SIN tocar este archivo:

    1. Llama a GETDATE() dos veces, y el resultado cambia segun cuando corra.
    2. Lee la tasa de cambio por FECHA MAXIMA, no por la vigente en el periodo:
       TASACAMB se sobrescribe cada mes, asi que el numero de hace ocho meses
       no se puede reproducir. Es lo que costo tres dias con la impugnacion.
    3. No guarda ni la tasa usada ni la clausula aplicada en LIQDETAL.
    4. Usa un cursor, y dentro del cursor decide con un IF anidado que ya nadie
       lee completo. La regla de BASELIQUI = 'N' esta escrita y NO se aplica
       cuando el contrato es de traduccion: eso es lo que la fase 08 encuentra.

  NO SE TOCA en la fase 07.
*/
USE SIGE;
GO

CREATE PROCEDURE SP_LIQREGAL_CALC
  @PERIODO char(6)            -- AAAATT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @NROCONTRA  char(12);
  DECLARE @CODTITULO  char(10);
  DECLARE @TIPOCONTR  char(1);
  DECLARE @PORCREGAL  decimal(5,2);
  DECLARE @BASELIQUI  char(1);
  DECLARE @MONEDA     char(3);
  DECLARE @ANIO       char(4);
  DECLARE @TRIM       char(2);
  DECLARE @MESDESDE   int;
  DECLARE @MESHASTA   int;
  DECLARE @FECDESDE   char(8);
  DECLARE @FECHASTA   char(8);
  DECLARE @VLRBASE    decimal(14,2);
  DECLARE @VLRREGAL   decimal(14,2);
  DECLARE @TASA       decimal(12,6);
  DECLARE @NROLIQUI   char(12);
  DECLARE @CONSEC     int;
  DECLARE @SQL        nvarchar(max);

  SET @ANIO = SUBSTRING(@PERIODO, 1, 4);
  SET @TRIM = SUBSTRING(@PERIODO, 5, 2);

  /* El trimestre, resuelto con IF anidados porque en 1997 no habia CASE
     en la version de FoxPro de la que se tradujo esto. */
  IF @TRIM = '01' BEGIN SET @MESDESDE = 1;  SET @MESHASTA = 3;  END
  ELSE IF @TRIM = '02' BEGIN SET @MESDESDE = 4;  SET @MESHASTA = 6;  END
  ELSE IF @TRIM = '03' BEGIN SET @MESDESDE = 7;  SET @MESHASTA = 9;  END
  ELSE BEGIN SET @MESDESDE = 10; SET @MESHASTA = 12; END

  SET @FECDESDE = @ANIO + RIGHT('0' + CAST(@MESDESDE AS varchar(2)), 2) + '01';
  SET @FECHASTA = @ANIO + RIGHT('0' + CAST(@MESHASTA AS varchar(2)), 2) + '31';

  /* El consecutivo de la liquidacion: MAX + 1, sin bloqueo. Con un solo
     trabajo nocturno nunca choco, y por eso nadie lo arreglo. */
  SELECT @CONSEC = ISNULL(MAX(CAST(SUBSTRING(NROLIQUI, 7, 6) AS int)), 0) + 1
  FROM   LIQREGAL
  WHERE  PERIODO = @PERIODO;

  DECLARE CUR_CONTRATOS CURSOR FOR
    SELECT NROCONTRA, CODTITULO, TIPOCONTR, PORCREGAL, BASELIQUI, MONEDA
    FROM   CONTRATO
    WHERE  BORRADO = 'N'
      AND  FECINICIO <= @FECHASTA
      AND  (FECFINAL = '00000000' OR FECFINAL >= @FECDESDE);

  OPEN CUR_CONTRATOS;
  FETCH NEXT FROM CUR_CONTRATOS
    INTO @NROCONTRA, @CODTITULO, @TIPOCONTR, @PORCREGAL, @BASELIQUI, @MONEDA;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @VLRBASE = 0;

    /* La base: se arma la consulta a la tabla del anio concatenando, igual
       que en SP_VENTAS_HIST. Si el trimestre cruza de anio -no pasa con los
       cuatro trimestres naturales, pero pasaria con un periodo especial-
       esto trae menos filas de las que deberia y nadie lo ha notado. */
    SET @SQL = N'
      SELECT @BASE = ISNULL(SUM(V.VLRTOTAL), 0)
      FROM   VENTAS_' + @ANIO + N' V
             INNER JOIN EDICION E ON E.CODEDIT = V.CODEDIT
      WHERE  E.CODTITULO = @TIT
        AND  V.FECVENTA BETWEEN @DESDE AND @HASTA
        AND  V.BORRADO = ''N''
        AND  V.TIPOVENTA IN (''I'', ''D'')';

    EXEC sp_executesql @SQL,
         N'@BASE decimal(14,2) OUTPUT, @TIT char(10), @DESDE char(8), @HASTA char(8)',
         @BASE = @VLRBASE OUTPUT, @TIT = @CODTITULO,
         @DESDE = @FECDESDE, @HASTA = @FECHASTA;

    /*
      Aqui esta la regla que la editorial cree que tiene y no aplica.
      BASELIQUI = 'N' significa "sobre neto facturado" y deberia descontar el
      descuento de la factura. Pero el IF de abajo solo lo hace cuando el
      contrato es de autoria: para las traducciones cae en el ELSE y liquida
      sobre precio de lista, que es mas alto.

      Es un error de 2017 que nadie ha visto porque el numero sale "razonable".
      La fase 08 lo encuentra caracterizando, no leyendo.
    */
    IF @BASELIQUI = 'N' AND @TIPOCONTR = 'A'
    BEGIN
      SELECT @VLRBASE = @VLRBASE - ISNULL(SUM(D.VLRDCTO * D.CANTIDAD), 0)
      FROM   FACTDETA D
             INNER JOIN EDICION E ON E.CODEDIT = D.CODEDIT
             INNER JOIN FACTURA F ON F.NROFACT = D.NROFACT
      WHERE  E.CODTITULO = @CODTITULO
        AND  F.FECFACT BETWEEN @FECDESDE AND @FECHASTA
        AND  F.ESTADO = 'E';
    END

    SET @VLRREGAL = ROUND(@VLRBASE * @PORCREGAL / 100, 2);

    /* La tasa: la FILA MAS RECIENTE de la moneda, no la vigente en el periodo.
       Este SELECT es la razon por la que una liquidacion no se puede
       reproducir ocho meses despues. */
    SELECT TOP 1 @TASA = VALOR
    FROM   TASACAMB
    WHERE  MONEDA = @MONEDA
      AND  BORRADO = 'N'
    ORDER BY FECTASA DESC;

    IF @TASA IS NULL SET @TASA = 1;

    SET @VLRREGAL = ROUND(@VLRREGAL * @TASA, 2);
    SET @NROLIQUI = @PERIODO + RIGHT('000000' + CAST(@CONSEC AS varchar(6)), 6);

    INSERT INTO LIQREGAL (NROLIQUI, NROCONTRA, PERIODO, FECLIQUI,
                          VLRBASE, VLRREGAL, MONEDA, ESTADO, BORRADO)
    VALUES (@NROLIQUI, @NROCONTRA, @PERIODO,
            CONVERT(char(8), GETDATE(), 112),   -- GETDATE() #1
            @VLRBASE, @VLRREGAL, @MONEDA, 'L', 'N');

    /* El detalle. No guarda @TASA. No guarda que clausula se aplico. */
    EXEC SP_LIQREGAL_DETALLE @NROLIQUI, @CODTITULO, @FECDESDE, @FECHASTA;

    SET @CONSEC = @CONSEC + 1;

    FETCH NEXT FROM CUR_CONTRATOS
      INTO @NROCONTRA, @CODTITULO, @TIPOCONTR, @PORCREGAL, @BASELIQUI, @MONEDA;
  END

  CLOSE CUR_CONTRATOS;
  DEALLOCATE CUR_CONTRATOS;

  SELECT COUNT(*) AS LIQUIDACIONES, CONVERT(char(8), GETDATE(), 112) AS FECHA  -- GETDATE() #2
  FROM   LIQREGAL
  WHERE  PERIODO = @PERIODO
    AND  BORRADO = 'N';
END
GO
