/*
  SIGE - Esquema de datos
  -----------------------------------------------------------------------------
  Importado desde los DBF de Visual FoxPro 9 en 2017 con el asistente de
  SQL Server 2014. Las tablas conservan los nombres del modelo congelado en
  1997, y las decisiones que hoy incomodan tienen su razon y su fecha:

    - Nombre de tabla de 8 caracteres  -> DOS limitaba el nombre del .DBF
    - Nombre de columna de 10          -> el formato DBF limitaba el campo
    - BORRADO char(1)                  -> borrado logico de FoxPro, no se elimina
    - Fechas en char(8) AAAAMMDD       -> en FoxPro la fecha vacia daba problemas
    - Sin llaves foraneas              -> la integridad la garantizaba el programa
    - varchar con intercalacion no Unicode -> era lo que habia en 1997
    - CAMPO1..CAMPO7                   -> campos de reserva de los noventa
    - Una tabla de ventas por anio     -> asi se evitaba que el motor sufriera

  NINGUNA de estas decisiones se corrige aqui. El curso las corta por partes
  a partir de la fase 09.
*/

CREATE DATABASE SIGE
  COLLATE Modern_Spanish_CI_AS;
GO

USE SIGE;
GO

/* --------------------------------------------------------------- CATALOGO */

CREATE TABLE SELLOS (
  CODSELLO  char(3)       NOT NULL,
  NOMBRE    varchar(40)   NULL,
  CIUDAD    varchar(40)   NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE AUTORES (
  CODAUTOR  char(10)      NOT NULL,
  NOMBRE    varchar(60)   NULL,
  APELLIDO  varchar(60)   NULL,
  PAIS      char(2)       NULL,
  TIPOPERS  char(1)       NULL,   -- A autor, T traductor, G agente
  FECNACIM  char(8)       NULL,   -- '00000000' en 4.100 filas
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE TITULOS (
  CODTITULO char(10)      NOT NULL,
  TITULO    varchar(120)  NULL,
  SUBTITULO varchar(120)  NULL,
  CODSELLO  char(3)       NULL,   -- sin FK a SELLOS
  CODAUTOR  char(10)      NULL,   -- un solo autor: la obra con dos se duplica
  ANOPUBLIC char(4)       NULL,
  ESTADO    char(1)       NULL,   -- B borrador, P programado, V vigente, D descatalogado
  FECCREA   char(8)       NULL,
  CAMPO1    varchar(20)   NULL,
  CAMPO2    varchar(20)   NULL,
  CAMPO3    varchar(20)   NULL,
  CAMPO4    varchar(20)   NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE EDICION (
  CODEDIT   char(10)      NOT NULL,
  CODTITULO char(10)      NULL,
  ISBN      char(13)      NULL,   -- en blanco en 340 filas anteriores a 2007
  NROEDIC   smallint      NULL,
  FECPUBLI  char(8)       NULL,
  PRECIOVTA decimal(12,2) NULL,
  MONEDA    char(3)       NULL,
  PAGINAS   int           NULL,
  FORMATO   char(2)       NULL,   -- TD, TB, EB, AU
  IDIOMA    char(2)       NULL,
  ESTADO    char(1)       NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/* ---------------------------------------------------------- EXISTENCIAS */

CREATE TABLE ALMACEN (
  CODALMA   char(3)       NOT NULL,   -- BOG, MEX, LIM
  NOMBRE    varchar(40)   NULL,
  CIUDAD    varchar(40)   NULL,
  PAIS      char(2)       NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

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
  CAMPO2    varchar(20)   NULL,
  CAMPO3    varchar(20)   NULL,
  CAMPO4    varchar(20)   NULL,
  CAMPO5    varchar(20)   NULL,
  CAMPO6    varchar(20)   NULL,
  CAMPO7    varchar(20)   NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/*
  El saldo vive aparte y lo recalcula un procedimiento. En 1997 era la decision
  correcta: recorrer los movimientos por la red coaxial era inviable. Hoy es la
  fuente de las diferencias que Duvan corrige a mano con SP_EXIST_RECALC.
*/
CREATE TABLE EXISTENC (
  CODALMA   char(3)       NOT NULL,
  CODEDIT   char(10)      NOT NULL,
  CANTIDAD  int           NULL,
  FECACTUAL char(8)       NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/* ------------------------------------------------------------- REGALIAS */

CREATE TABLE CONTRATO (
  NROCONTRA char(12)      NOT NULL,
  CODTITULO char(10)      NULL,
  CODAUTOR  char(10)      NULL,
  TIPOCONTR char(1)       NULL,   -- A autoria, T traduccion, C cesion
  PORCREGAL decimal(5,2)  NULL,
  BASELIQUI char(1)       NULL,   -- P precio de lista, N neto facturado
  FECINICIO char(8)       NULL,
  FECFINAL  char(8)       NULL,   -- '00000000' cuando no vence
  TERRITORIO char(10)     NULL,   -- diez caracteres para un territorio
  IDIOMAS   varchar(40)   NULL,   -- lista separada por comas
  MONEDA    char(3)       NULL,
  ANTICIPO  decimal(12,2) NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/*
  Ni LIQREGAL ni LIQDETAL guardan la tasa de cambio usada ni la clausula
  aplicada. La tasa se lee de TASACAMB, que se sobrescribe cada mes, asi que
  reproducir una liquidacion de hace ocho meses es imposible por diseno.
  Eso costo tres dias de arqueologia con la impugnacion de la traductora.
  Se corrige en la fase 17, no aqui.
*/
CREATE TABLE LIQREGAL (
  NROLIQUI  char(12)      NOT NULL,
  NROCONTRA char(12)      NULL,
  PERIODO   char(6)       NULL,   -- AAAATT
  FECLIQUI  char(8)       NULL,
  VLRBASE   decimal(14,2) NULL,
  VLRREGAL  decimal(14,2) NULL,
  MONEDA    char(3)       NULL,
  ESTADO    char(1)       NULL,   -- L liquidado, P pagado, I impugnado
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE LIQDETAL (
  NROLIQUI  char(12)      NOT NULL,
  NROLINEA  int           NOT NULL,
  CODEDIT   char(10)      NULL,
  CANTIDAD  int           NULL,
  VLRUNIT   decimal(12,2) NULL,
  VLRNETO   decimal(14,2) NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE TASACAMB (
  MONEDA    char(3)       NOT NULL,
  FECTASA   char(8)       NULL,
  VALOR     decimal(12,6) NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/* ---------------------------------------------------------- FACTURACION */

CREATE TABLE DISTRIBU (
  CODDISTR  char(6)       NOT NULL,   -- DISMEX, DISCOL, DISARG
  NOMBRE    varchar(60)   NULL,
  PAIS      char(2)       NULL,
  CALENDARIO char(1)      NULL,   -- M mes natural, I semanas ISO, Q quincenal
  MONEDA    char(3)       NULL,
  PORCDEVOL decimal(5,2)  NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE CLIENTES (
  CODCLIEN  char(10)      NOT NULL,
  NOMBRE    varchar(80)   NULL,
  NIT       varchar(20)   NULL,
  CIUDAD    varchar(40)   NULL,
  PAIS      char(2)       NULL,
  CANALVTA  char(1)       NULL,   -- L libreria, C cadena, D distribuidor, W web, P plataforma
  CODDISTR  char(6)       NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE FACTURA (
  NROFACT   char(12)      NOT NULL,
  FECFACT   char(8)       NULL,
  CODCLIEN  char(10)      NULL,
  CODALMA   char(3)       NULL,
  VLRSUBTOT decimal(14,2) NULL,
  VLRIMPTO  decimal(14,2) NULL,
  VLRTOTAL  decimal(14,2) NULL,
  MONEDA    char(3)       NULL,
  ESTADO    char(1)       NULL,   -- E emitida, A anulada, P pagada
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE FACTDETA (
  NROFACT   char(12)      NOT NULL,
  NROLINEA  int           NOT NULL,
  CODEDIT   char(10)      NULL,
  CANTIDAD  int           NULL,
  VLRUNIT   decimal(12,2) NULL,
  VLRDCTO   decimal(12,2) NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

CREATE TABLE USUARIOS (
  CODUSUA   char(10)      NOT NULL,
  NOMBRE    varchar(60)   NULL,
  CLAVE     varchar(32)   NULL,   -- MD5 sin sal, de 2017. Se jubila en la fase 16
  ROL       char(2)       NULL,
  BORRADO   char(1)       NULL DEFAULT 'N'
);
GO

/*
  FR_TMP: sin filas desde 2004, con las iniciales de Fabio Rincon, el
  independiente que hizo el sistema en FoxPro 2.5 en 1993. Nadie la ha borrado
  en treinta anios. En este sistema borrar algo da mas miedo que dejarlo.
*/
CREATE TABLE FR_TMP (
  CAMPO1    varchar(20)   NULL,
  CAMPO2    varchar(20)   NULL
);
GO
