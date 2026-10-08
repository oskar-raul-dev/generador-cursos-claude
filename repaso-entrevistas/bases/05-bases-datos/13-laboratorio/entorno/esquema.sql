-- ============================================================================
--  esquema.sql — el DDL canonico del corpus (PostgreSQL)
--
--  Dueno unico del esquema: `prompts/dominio-entorno-y-datos-fijos.md` §2.1.
--  Este fichero es su traduccion ejecutable; si los dos discrepan, manda aquel.
--
--    psql -h 127.0.0.1 -U postgres -d tienda -f esquema.sql
--
--  Lo que NO trae, a proposito (§2.2):
--    - Ningun indice mas alla de los que crean PRIMARY KEY y UNIQUE. Si el esquema
--      llegara indexado, el bloque 03 no podria ensenar el antes y el despues.
--    - Ningun disparador, vista ni funcion: los crea el bloque 05 y los borra al salir.
-- ============================================================================

BEGIN;

DROP TABLE IF EXISTS eventos_pedido, pagos, pedido_lineas, pedidos, productos, clientes CASCADE;

CREATE TABLE clientes (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- CLI-00311: la clave natural visible
  nombre         text NOT NULL,
  email          text NOT NULL UNIQUE,
  pais           char(2) NOT NULL,                  -- ISO 3166-1 alfa-2
  creado_en      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE productos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- PRD-00017
  nombre         text NOT NULL,
  categoria      text NOT NULL,
  precio         numeric(12,2) NOT NULL CHECK (precio >= 0),
  activo         boolean NOT NULL DEFAULT true
);

CREATE TABLE pedidos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- PED-00042
  cliente_id     bigint NOT NULL REFERENCES clientes(id),
  estado         text NOT NULL
                 CHECK (estado IN ('PENDIENTE','PAGADO','ENVIADO','ENTREGADO','ANULADO')),
  total          numeric(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),  -- desnormalizado a proposito
  creado_en      timestamptz NOT NULL,
  actualizado_en timestamptz                        -- nulo mientras nadie lo ha tocado
);

CREATE TABLE pedido_lineas (
  pedido_id      bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea          smallint NOT NULL,
  producto_id    bigint NOT NULL REFERENCES productos(id),
  cantidad       integer NOT NULL CHECK (cantidad > 0),
  precio_unit    numeric(12,2) NOT NULL,            -- precio congelado en el momento de la compra
  PRIMARY KEY (pedido_id, linea)                    -- clave compuesta, a proposito
);

CREATE TABLE pagos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id      bigint NOT NULL REFERENCES pedidos(id),
  metodo         text NOT NULL CHECK (metodo IN ('TARJETA','TRANSFERENCIA','EFECTIVO')),
  importe        numeric(12,2) NOT NULL CHECK (importe > 0),
  pagado_en      timestamptz NOT NULL,
  referencia     text UNIQUE                        -- del proveedor; nulo en efectivo
);

CREATE TABLE eventos_pedido (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id      bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  tipo           text NOT NULL,
  carga          jsonb NOT NULL,
  ocurrido_en    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
--  Los tres roles del dominio.
--  Se crean aqui porque son vocabulario fijo del corpus; quien los diseccione
--  —GRANT, REVOKE, herencia, minimo privilegio real— es `06/01`, su dueno.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  -- CREATE ROLE no admite IF NOT EXISTS: hay que preguntar por el catalogo.
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tienda_app') THEN
    CREATE ROLE tienda_app LOGIN PASSWORD 'tienda_app';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tienda_ro') THEN
    CREATE ROLE tienda_ro LOGIN PASSWORD 'tienda_ro';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tienda_admin') THEN
    CREATE ROLE tienda_admin LOGIN PASSWORD 'tienda_admin';
  END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO tienda_app, tienda_ro, tienda_admin;

-- El rol de la aplicacion lee y escribe datos, pero no toca el esquema.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO tienda_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO tienda_app;

-- El rol de solo lectura: informes, replicas de consulta, el analista.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO tienda_ro;

-- El rol administrador si puede cambiar el esquema.
GRANT ALL ON ALL TABLES IN SCHEMA public TO tienda_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO tienda_admin;
GRANT CREATE ON SCHEMA public TO tienda_admin;

COMMIT;

\echo 'esquema.sql: seis tablas y tres roles creados.'
