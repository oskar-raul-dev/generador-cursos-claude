/*
  VENTAS_1997 .. VENTAS_2026: treinta tablas con la misma forma exacta.

  En FoxPro los archivos eran VTAS97.DBF, VTAS98.DBF y asi. El asistente de
  importacion de 2017 las creo con el nombre expandido, una por una, tal como
  los pasantes las escribieron en el cuadro de dialogo: es el unico sitio del
  esquema donde se ve la mano de 2017 y no la de 1997.

  Partir por anio era, en 1997, como se evitaba que una tabla creciera hasta
  donde el motor empezaba a sufrir. Con SQL Server 2025 y particionamiento
  nativo ya no hace falta, pero los 700 procedimientos que las consultan si.
*/

USE SIGE;
GO

DECLARE @anio int = 1997;
DECLARE @sql  nvarchar(max);

WHILE @anio <= 2026
BEGIN
  SET @sql = N'
    CREATE TABLE VENTAS_' + CAST(@anio AS nvarchar(4)) + N' (
      NROVENTA  int           NOT NULL,   -- unico dentro de su tabla, NO entre tablas
      FECVENTA  char(8)       NULL,
      CODEDIT   char(10)      NULL,
      CODCLIEN  char(10)      NULL,
      CODALMA   char(3)       NULL,
      CODDISTR  char(6)       NULL,       -- en blanco en la venta directa
      CANTIDAD  int           NULL,       -- negativa en la devolucion
      VLRUNIT   decimal(12,2) NULL,
      VLRTOTAL  decimal(14,2) NULL,       -- y no siempre es CANTIDAD * VLRUNIT
      MONEDA    char(3)       NULL,
      CANALVTA  char(1)       NULL,
      TIPOVENTA char(1)       NULL,       -- I sell-in, O sell-out, D devolucion
      CAMPO1    varchar(20)   NULL,
      CAMPO2    varchar(20)   NULL,
      CAMPO3    varchar(20)   NULL,
      CAMPO4    varchar(20)   NULL,
      CAMPO5    varchar(20)   NULL,
      CAMPO6    varchar(20)   NULL,
      CAMPO7    varchar(20)   NULL,
      BORRADO   char(1)       NULL DEFAULT ''N''
    );

    CREATE INDEX IX_VENTAS_' + CAST(@anio AS nvarchar(4)) + N'_EDIT
      ON VENTAS_' + CAST(@anio AS nvarchar(4)) + N' (CODEDIT);';

  EXEC sp_executesql @sql;

  SET @anio = @anio + 1;
END
GO
