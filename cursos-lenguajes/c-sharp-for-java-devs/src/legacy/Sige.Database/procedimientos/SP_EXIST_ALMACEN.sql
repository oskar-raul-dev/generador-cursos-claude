/*
  SP_EXIST_ALMACEN - la consulta que el formulario de existencias llama en el
  Click del boton Consultar. Devuelve el saldo de EXISTENC y, al lado, el saldo
  recalculado desde MOVINVEN, porque a alguien le sirvio una vez para comparar
  y quedo ahi.
*/
USE SIGE;
GO

CREATE PROCEDURE SP_EXIST_ALMACEN
  @CODALMA char(3)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT X.CODALMA,
         X.CODEDIT,
         X.CANTIDAD                       AS SALDO,
         E.ISBN,
         T.TITULO,
         X.FECACTUAL,
         /* El saldo real, recorriendo los movimientos. Aqui SI se filtra
            BORRADO; en la consulta de arriba tambien. En SP_CATALOGO_VIGENTE,
            que es de la fase 08, no siempre. */
         (SELECT ISNULL(SUM(M.CANTIDAD), 0)
          FROM   MOVINVEN M
          WHERE  M.CODALMA = X.CODALMA
            AND  M.CODEDIT = X.CODEDIT
            AND  M.BORRADO = 'N')         AS SALDO_MOV
  FROM   EXISTENC X
         LEFT JOIN EDICION E ON E.CODEDIT = X.CODEDIT
         LEFT JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
  WHERE  X.CODALMA = @CODALMA
    AND  X.BORRADO = 'N'
  ORDER BY T.TITULO;
END
GO

/*
  SP_MOVINVEN_INS - inserta el movimiento y actualiza EXISTENC en la misma
  transaccion... casi siempre. Si el UPDATE no encuentra la fila, hace INSERT;
  si el INSERT choca, se pierde el saldo y queda solo el movimiento. De ahi
  salen las diferencias que Duvan corrige con SP_EXIST_RECALC.
*/
CREATE PROCEDURE SP_MOVINVEN_INS
  @CODALMA   char(3),
  @CODEDIT   char(10),
  @FECMOVTO  char(8),
  @TIPOMOVTO char(1),
  @CANTIDAD  int,
  @VLRUNIT   decimal(12,2),
  @NRODOCTO  char(15),
  @CODUSUA   char(10)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRANSACTION;

  INSERT INTO MOVINVEN (CODALMA, CODEDIT, FECMOVTO, TIPOMOVTO, CANTIDAD,
                        VLRUNIT, NRODOCTO, CODUSUA, BORRADO)
  VALUES (@CODALMA, @CODEDIT, @FECMOVTO, @TIPOMOVTO, @CANTIDAD,
          @VLRUNIT, @NRODOCTO, @CODUSUA, 'N');

  UPDATE EXISTENC
     SET CANTIDAD  = CANTIDAD + @CANTIDAD,
         FECACTUAL = CONVERT(char(8), GETDATE(), 112)
   WHERE CODALMA = @CODALMA
     AND CODEDIT = @CODEDIT;

  IF @@ROWCOUNT = 0
    INSERT INTO EXISTENC (CODALMA, CODEDIT, CANTIDAD, FECACTUAL, BORRADO)
    VALUES (@CODALMA, @CODEDIT, @CANTIDAD,
            CONVERT(char(8), GETDATE(), 112), 'N');

  COMMIT TRANSACTION;

  SELECT SCOPE_IDENTITY() AS NROMOVTO;
END
GO

/*
  SP_EXIST_RECALC - el recalculo que Duvan corre a mano cuando el saldo no
  cuadra. No es un proceso programado: es un procedimiento que alguien ejecuta
  desde Management Studio cuando el almacen reclama.
*/
CREATE PROCEDURE SP_EXIST_RECALC
  @CODALMA char(3) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE X
     SET X.CANTIDAD  = M.SALDO,
         X.FECACTUAL = CONVERT(char(8), GETDATE(), 112)
  FROM   EXISTENC X
         INNER JOIN (SELECT CODALMA, CODEDIT, SUM(CANTIDAD) AS SALDO
                     FROM   MOVINVEN
                     WHERE  BORRADO = 'N'
                     GROUP BY CODALMA, CODEDIT) M
           ON M.CODALMA = X.CODALMA AND M.CODEDIT = X.CODEDIT
  WHERE  (@CODALMA IS NULL OR X.CODALMA = @CODALMA);

  SELECT @@ROWCOUNT AS FILAS_AJUSTADAS;
END
GO
