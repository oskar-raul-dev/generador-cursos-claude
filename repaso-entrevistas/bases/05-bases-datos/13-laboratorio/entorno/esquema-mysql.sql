-- ============================================================================
--  esquema-mysql.sql — el mismo esquema, traducido a MySQL / MariaDB
--
--  Traduccion de `esquema.sql` segun la tabla de equivalencias de
--  `prompts/dominio-entorno-y-datos-fijos.md` §2.3. Los nombres de tabla y de
--  columna son IDENTICOS a los de PostgreSQL: lo unico que cambia son los tipos.
--
--    docker exec -i bd-lab-mysql mysql -uroot -proot tienda < esquema-mysql.sql
--    docker exec -i bd-lab-maria mariadb -uroot -proot tienda < esquema-mysql.sql
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS eventos_pedido, pagos, pedido_lineas, pedidos, productos, clientes;
SET FOREIGN_KEY_CHECKS = 1;

-- `utf8mb4` explicito en cada tabla. El `utf8` de MySQL son tres bytes y no cubre
-- los emoji ni buena parte del plano suplementario: es la trampa de la que es dueno
-- el capitulo 02/01.
CREATE TABLE clientes (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  codigo     VARCHAR(20)  NOT NULL UNIQUE,
  nombre     VARCHAR(120) NOT NULL,
  email      VARCHAR(160) NOT NULL UNIQUE,
  pais       CHAR(2)      NOT NULL,
  creado_en  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE productos (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  codigo     VARCHAR(20)  NOT NULL UNIQUE,
  nombre     VARCHAR(120) NOT NULL,
  categoria  VARCHAR(40)  NOT NULL,
  precio     DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  activo     TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pedidos (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  codigo         VARCHAR(20) NOT NULL UNIQUE,
  cliente_id     BIGINT NOT NULL,
  estado         VARCHAR(12) NOT NULL
                 CHECK (estado IN ('PENDIENTE','PAGADO','ENVIADO','ENTREGADO','ANULADO')),
  total          DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  creado_en      TIMESTAMP(6) NOT NULL,
  actualizado_en TIMESTAMP(6) NULL DEFAULT NULL,
  CONSTRAINT fk_pedidos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pedido_lineas (
  pedido_id   BIGINT   NOT NULL,
  linea       SMALLINT NOT NULL,
  producto_id BIGINT   NOT NULL,
  cantidad    INT      NOT NULL CHECK (cantidad > 0),
  precio_unit DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (pedido_id, linea),
  CONSTRAINT fk_lineas_pedido   FOREIGN KEY (pedido_id)   REFERENCES pedidos(id) ON DELETE CASCADE,
  CONSTRAINT fk_lineas_producto FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pagos (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pedido_id  BIGINT NOT NULL,
  metodo     VARCHAR(16) NOT NULL CHECK (metodo IN ('TARJETA','TRANSFERENCIA','EFECTIVO')),
  importe    DECIMAL(12,2) NOT NULL CHECK (importe > 0),
  pagado_en  TIMESTAMP(6) NOT NULL,
  referencia VARCHAR(40) NULL UNIQUE,
  CONSTRAINT fk_pagos_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE eventos_pedido (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pedido_id   BIGINT NOT NULL,
  tipo        VARCHAR(20) NOT NULL,
  carga       JSON NOT NULL,
  ocurrido_en TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_eventos_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Los tres roles del dominio. En MySQL son usuarios, no roles heredables como en
-- PostgreSQL: es una de las diferencias que disecciona 06/01.
CREATE USER IF NOT EXISTS 'tienda_app'@'%'   IDENTIFIED BY 'tienda_app';
CREATE USER IF NOT EXISTS 'tienda_ro'@'%'    IDENTIFIED BY 'tienda_ro';
CREATE USER IF NOT EXISTS 'tienda_admin'@'%' IDENTIFIED BY 'tienda_admin';

GRANT SELECT, INSERT, UPDATE, DELETE ON tienda.* TO 'tienda_app'@'%';
GRANT SELECT                         ON tienda.* TO 'tienda_ro'@'%';
GRANT ALL PRIVILEGES                 ON tienda.* TO 'tienda_admin'@'%';
FLUSH PRIVILEGES;

SELECT 'esquema-mysql.sql: seis tablas y tres usuarios creados.' AS resultado;
