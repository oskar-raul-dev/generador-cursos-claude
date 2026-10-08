/*
  SP_VENTAS_HIST
  -----------------------------------------------------------------------------
  El reporte historico del comercial. Arma el UNION ALL de las treinta tablas
  anuales CONCATENANDO CADENAS en tiempo de ejecucion, y lo ejecuta.

  Esto es el corazon del problema de rendimiento del sistema, y es la linea
  base contra la que se compara todo el Bloque B: 500.000 filas, treinta
  tablas, un plan de consulta que el motor tiene que construir cada vez porque
  el texto cambia con los parametros.

  NO SE TOCA en la fase 07. Se mide, y se corta a partir de la fase 09.
*/

USE SIGE;
GO

CREATE PROCEDURE SP_VENTAS_HIST
  @ANIODESDE int,
  @ANIOHASTA int,
  @CODSELLO  char(3) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @SQL   nvarchar(max);
  DECLARE @ANIO  int;
  DECLARE @UNION nvarchar(max);

  SET @ANIO  = @ANIODESDE;
  SET @UNION = N'';

  /*
    El bucle que concatena. Notese que:
      - no hay parametrizacion: el anio va pegado al texto
      - el filtro de sello se pega tambien, si viene
      - BORRADO se filtra aqui... pero no en la union con TITULOS de abajo,
        y esa asimetria lleva nueve anios en produccion
  */
  WHILE @ANIO <= @ANIOHASTA
  BEGIN
    IF LEN(@UNION) > 0
      SET @UNION = @UNION + N' UNION ALL ';

    SET @UNION = @UNION + N'
      SELECT V.FECVENTA, V.CODEDIT, V.CODCLIEN, V.CODALMA, V.CODDISTR,
             V.CANTIDAD, V.VLRUNIT, V.VLRTOTAL, V.MONEDA, V.CANALVTA,
             V.TIPOVENTA
      FROM   VENTAS_' + CAST(@ANIO AS nvarchar(4)) + N' V
      WHERE  V.BORRADO = ''N''';

    SET @ANIO = @ANIO + 1;
  END

  SET @SQL = N'
    SELECT T.CODSELLO, V.*
    FROM   (' + @UNION + N') V
           LEFT JOIN EDICION E ON E.CODEDIT = V.CODEDIT
           LEFT JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
    ORDER BY V.FECVENTA';

  /* El filtro de sello, pegado despues del ORDER BY que ya estaba escrito:
     por eso hay un WHERE dentro de un subquery y otro aqui, y por eso el plan
     cambia segun si @CODSELLO viene o no. */
  IF @CODSELLO IS NOT NULL
    SET @SQL = REPLACE(@SQL, N'ORDER BY V.FECVENTA',
                       N'WHERE T.CODSELLO = ''' + @CODSELLO + N''' ORDER BY V.FECVENTA');

  EXEC sp_executesql @SQL;
END
GO
