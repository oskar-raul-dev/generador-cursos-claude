/*
  Modulo de catalogo. Escrito en la fase 08, en estilo 2017, MIENTRAS se
  caracteriza: un procedimiento, y acto seguido la prueba de aproximacion que
  lo fija. Es el orden real de quien hereda un sistema.
*/
USE SIGE;
GO

/*
  SP_CATALOGO_VIGENTE - el catalogo que se muestra y que alimenta los volcados.

  El defecto esta a la vista para quien lo busque, y en produccion lleva nueve
  anios: BORRADO se filtra en EDICION y en TITULOS, pero NO en la rama del
  ELSE que trae las ediciones sin titulo asociado. Son 340 filas.
*/
CREATE PROCEDURE SP_CATALOGO_VIGENTE
  @CODSELLO char(3) = NULL,
  @SOLOCONISBN char(1) = 'N'
AS
BEGIN
  SET NOCOUNT ON;

  IF @CODSELLO IS NOT NULL
  BEGIN
    SELECT E.CODEDIT, E.ISBN, E.PRECIOVTA, E.MONEDA, E.FORMATO,
           T.CODTITULO, T.TITULO, T.CODSELLO
    FROM   EDICION E
           INNER JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
    WHERE  T.CODSELLO = @CODSELLO
      AND  E.ESTADO = 'V'
      AND  E.BORRADO = 'N'
      AND  T.BORRADO = 'N'
      AND  (@SOLOCONISBN = 'N' OR LEN(LTRIM(E.ISBN)) = 13);
  END
  ELSE
  BEGIN
    /* Sin filtro de sello. Aqui falta AND E.BORRADO = 'N' y falta el de
       TITULOS: se traen ediciones borradas y ediciones cuyo titulo se borro.
       Nadie lo ha notado porque el volcado nocturno usa la rama de arriba. */
    SELECT E.CODEDIT, E.ISBN, E.PRECIOVTA, E.MONEDA, E.FORMATO,
           T.CODTITULO, T.TITULO, T.CODSELLO
    FROM   EDICION E
           LEFT JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
    WHERE  E.ESTADO = 'V'
      AND  (@SOLOCONISBN = 'N' OR LEN(LTRIM(E.ISBN)) = 13);
  END
END
GO

/*
  SP_TITULO_BUSCAR - la busqueda del formulario. LIKE con comodin a los dos
  lados, asi que no usa indice. Y con la intercalacion Modern_Spanish_CI_AS,
  buscar "dias" encuentra "dias" y "dias" con tilde... pero NO encuentra los
  1.240 titulos peruanos cuya tilde se comio la importacion de 2017 y quedo
  como '?'.
*/
CREATE PROCEDURE SP_TITULO_BUSCAR
  @TEXTO varchar(120)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT T.CODTITULO, T.TITULO, T.CODSELLO, T.ESTADO,
         (SELECT COUNT(*) FROM EDICION E
          WHERE E.CODTITULO = T.CODTITULO AND E.BORRADO = 'N') AS EDICIONES
  FROM   TITULOS T
  WHERE  T.TITULO LIKE '%' + @TEXTO + '%'
    AND  T.BORRADO = 'N'
  ORDER BY T.TITULO;
END
GO

/*
  SP_CATALOGO_VOLCADO - uno de los cuatro volcados CSV nocturnos. Los cuatro se
  escribieron en anios distintos y hoy estan desincronizados entre si: este usa
  la rama con sello de SP_CATALOGO_VIGENTE, otro usa la rama sin sello, y por
  eso dos socios comerciales reciben catalogos que no coinciden.

  Es el problema que CatalogAPI viene a resolver, y el ultimatum de Almenara le
  puso fecha.
*/
CREATE PROCEDURE SP_CATALOGO_VOLCADO
  @CODSELLO char(3) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT E.CODEDIT + ';' +
         ISNULL(LTRIM(RTRIM(E.ISBN)), '') + ';' +
         ISNULL(T.TITULO, '') + ';' +
         ISNULL(T.CODSELLO, '') + ';' +
         ISNULL(E.FORMATO, '') + ';' +
         CONVERT(varchar(20), ISNULL(E.PRECIOVTA, 0)) + ';' +
         ISNULL(E.MONEDA, '') AS LINEA
  FROM   EDICION E
         INNER JOIN TITULOS T ON T.CODTITULO = E.CODTITULO
  WHERE  (@CODSELLO IS NULL OR T.CODSELLO = @CODSELLO)
    AND  E.ESTADO = 'V'
    AND  E.BORRADO = 'N'
    AND  T.BORRADO = 'N';
END
GO
