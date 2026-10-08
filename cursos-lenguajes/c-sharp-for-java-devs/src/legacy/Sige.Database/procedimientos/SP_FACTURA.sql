/*
  Modulo de facturacion. Escrito en la fase 08 mientras se caracteriza.
*/
USE SIGE;
GO

/*
  SP_FACTURA_EMITIR - la transaccion que escribe en CUATRO sitios: FACTURA,
  FACTDETA, MOVINVEN (la salida de inventario) y VENTAS_AAAA (la venta del
  anio). El nombre de la tabla de ventas se arma concatenando el anio.

  Lo que hace bien: todo dentro de una transaccion.
  Lo que hace mal: si el anio de la factura no tiene tabla -pasa el 1 de enero
  a las 00:00 si nadie creo VENTAS del anio nuevo-, la transaccion revienta
  DESPUES de haber escrito la factura y el detalle. El rollback los deshace,
  asi que el dato queda consistente y la factura simplemente no se emite. En
  enero de 2021 eso paro la facturacion cuatro horas.
*/
CREATE PROCEDURE SP_FACTURA_EMITIR
  @NROFACT  char(12),
  @FECFACT  char(8),
  @CODCLIEN char(10),
  @CODALMA  char(3),
  @CODUSUA  char(10)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @ANIO      char(4);
  DECLARE @SQL       nvarchar(max);
  DECLARE @SUBTOTAL  decimal(14,2);
  DECLARE @IMPUESTO  decimal(14,2);
  DECLARE @CANALVTA  char(1);
  DECLARE @MONEDA    char(3);

  SET @ANIO = SUBSTRING(@FECFACT, 1, 4);

  SELECT @CANALVTA = CANALVTA FROM CLIENTES WHERE CODCLIEN = @CODCLIEN;
  SELECT @MONEDA = MONEDA FROM DISTRIBU D
         INNER JOIN CLIENTES C ON C.CODDISTR = D.CODDISTR
  WHERE  C.CODCLIEN = @CODCLIEN;

  IF @MONEDA IS NULL SET @MONEDA = 'COP';

  BEGIN TRANSACTION;

  SELECT @SUBTOTAL = ISNULL(SUM((D.VLRUNIT - ISNULL(D.VLRDCTO, 0)) * D.CANTIDAD), 0)
  FROM   FACTDETA D
  WHERE  D.NROFACT = @NROFACT
    AND  D.BORRADO = 'N';

  /* El 19% pegado en el codigo. Cuando cambio del 16 al 19 en 2017 hubo que
     buscarlo en once procedimientos, y en dos se olvidaron. */
  SET @IMPUESTO = ROUND(@SUBTOTAL * 0.19, 2);

  INSERT INTO FACTURA (NROFACT, FECFACT, CODCLIEN, CODALMA,
                       VLRSUBTOT, VLRIMPTO, VLRTOTAL, MONEDA, ESTADO, BORRADO)
  VALUES (@NROFACT, @FECFACT, @CODCLIEN, @CODALMA,
          @SUBTOTAL, @IMPUESTO, @SUBTOTAL + @IMPUESTO, @MONEDA, 'E', 'N');

  /* La salida de inventario, una por linea de factura. */
  INSERT INTO MOVINVEN (CODALMA, CODEDIT, FECMOVTO, TIPOMOVTO, CANTIDAD,
                        VLRUNIT, NRODOCTO, CODUSUA, BORRADO)
  SELECT @CODALMA, D.CODEDIT, @FECFACT, 'S', -D.CANTIDAD,
         D.VLRUNIT, @NROFACT, @CODUSUA, 'N'
  FROM   FACTDETA D
  WHERE  D.NROFACT = @NROFACT AND D.BORRADO = 'N';

  /* Y la venta en la tabla del anio, con el nombre concatenado. */
  SET @SQL = N'
    INSERT INTO VENTAS_' + @ANIO + N'
      (NROVENTA, FECVENTA, CODEDIT, CODCLIEN, CODALMA, CODDISTR,
       CANTIDAD, VLRUNIT, VLRTOTAL, MONEDA, CANALVTA, TIPOVENTA, BORRADO)
    SELECT (SELECT ISNULL(MAX(NROVENTA), 0) FROM VENTAS_' + @ANIO + N') + ROW_NUMBER() OVER (ORDER BY D.NROLINEA),
           @FEC, D.CODEDIT, @CLI, @ALM, C.CODDISTR,
           D.CANTIDAD, D.VLRUNIT, (D.VLRUNIT - ISNULL(D.VLRDCTO,0)) * D.CANTIDAD,
           @MON, @CAN, ''I'', ''N''
    FROM   FACTDETA D
           LEFT JOIN CLIENTES C ON C.CODCLIEN = @CLI
    WHERE  D.NROFACT = @FACT AND D.BORRADO = ''N''';

  EXEC sp_executesql @SQL,
       N'@FACT char(12), @FEC char(8), @CLI char(10), @ALM char(3), @MON char(3), @CAN char(1)',
       @FACT = @NROFACT, @FEC = @FECFACT, @CLI = @CODCLIEN,
       @ALM = @CODALMA, @MON = @MONEDA, @CAN = @CANALVTA;

  COMMIT TRANSACTION;

  SELECT @NROFACT AS NROFACT, @SUBTOTAL + @IMPUESTO AS VLRTOTAL;
END
GO

/*
  SP_FACTURA_ANULAR - marca BORRADO='S' en cascada, a mano, tabla por tabla.
  NO deshace el movimiento de inventario: eso se hace con otro movimiento, y
  quien anula tiene que acordarse. A veces no se acuerda.
*/
CREATE PROCEDURE SP_FACTURA_ANULAR
  @NROFACT char(12)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRANSACTION;

  UPDATE FACTURA  SET ESTADO = 'A', BORRADO = 'S' WHERE NROFACT = @NROFACT;
  UPDATE FACTDETA SET BORRADO = 'S' WHERE NROFACT = @NROFACT;

  /* La venta del anio tambien, y aqui el anio se saca de la factura... que ya
     quedo marcada como borrada dos lineas arriba. Por eso este SELECT filtra
     sin BORRADO: si lo filtrara, no encontraria nada. */
  DECLARE @ANIO char(4);
  DECLARE @SQL  nvarchar(max);

  SELECT @ANIO = SUBSTRING(FECFACT, 1, 4) FROM FACTURA WHERE NROFACT = @NROFACT;

  SET @SQL = N'UPDATE VENTAS_' + @ANIO + N' SET BORRADO = ''S'' WHERE CODCLIEN IN
                 (SELECT CODCLIEN FROM FACTURA WHERE NROFACT = @FACT)
                 AND FECVENTA = (SELECT FECFACT FROM FACTURA WHERE NROFACT = @FACT)';

  /* Y aqui esta el defecto: anula por cliente y fecha, no por numero de
     factura, porque VENTAS_AAAA no guarda el NROFACT. Si el mismo cliente tuvo
     dos facturas el mismo dia, se anulan las dos. Ha pasado once veces. */
  EXEC sp_executesql @SQL, N'@FACT char(12)', @FACT = @NROFACT;

  COMMIT TRANSACTION;
END
GO
