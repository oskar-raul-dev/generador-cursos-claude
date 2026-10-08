-- ============================================================================
--  esquema-sqlite.sql — el mismo esquema en SQLite
--
--    sqlite3 tienda.db < esquema-sqlite.sql
--
--  SQLite no es un motor recortado: es un motor con OTRO sistema de tipos. Lo que
--  aqui se pierde respecto de PostgreSQL, y quien es dueno de explicarlo (§2.3 del
--  documento de dominio):
--
--    NO hay tipo fecha      -> TEXT en ISO-8601.                   Dueno: 02/01
--    NO hay tipo booleano   -> INTEGER 0/1.                        Dueno: 02/01
--    NO hay DECIMAL         -> TEXT, y la aritmetica pasa por      Dueno: 12/03
--                              coma flotante. Es EL ejemplo del
--                              capitulo de dinero: el mismo total
--                              que en PostgreSQL sale exacto, aqui
--                              sale con el error de punto flotante.
--    NO hay tipo JSON       -> TEXT + las funciones json_*.        Dueno: 08/05
--
--  El tipado es por AFINIDAD, no por declaracion: una columna `TEXT` acepta un
--  entero y lo guarda como entero. Que la columna diga un tipo no impide guardar
--  otro; eso es lo que hay que entender antes de tocar nada.
-- ============================================================================

PRAGMA foreign_keys = OFF;   -- se vuelven a encender al final: SQLite las trae APAGADAS por defecto

DROP TABLE IF EXISTS eventos_pedido;
DROP TABLE IF EXISTS pagos;
DROP TABLE IF EXISTS pedido_lineas;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
  id        INTEGER PRIMARY KEY,          -- alias de rowid: es la clave sustituta de SQLite
  codigo    TEXT NOT NULL UNIQUE,
  nombre    TEXT NOT NULL,
  email     TEXT NOT NULL UNIQUE,
  pais      TEXT NOT NULL,
  creado_en TEXT NOT NULL                 -- ISO-8601, en UTC
);

CREATE TABLE productos (
  id        INTEGER PRIMARY KEY,
  codigo    TEXT NOT NULL UNIQUE,
  nombre    TEXT NOT NULL,
  categoria TEXT NOT NULL,
  precio    TEXT NOT NULL,                -- sin DECIMAL: el numero viaja como texto
  activo    INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
);

CREATE TABLE pedidos (
  id             INTEGER PRIMARY KEY,
  codigo         TEXT NOT NULL UNIQUE,
  cliente_id     INTEGER NOT NULL REFERENCES clientes(id),
  estado         TEXT NOT NULL
                 CHECK (estado IN ('PENDIENTE','PAGADO','ENVIADO','ENTREGADO','ANULADO')),
  total          TEXT NOT NULL DEFAULT '0',
  creado_en      TEXT NOT NULL,
  actualizado_en TEXT
);

CREATE TABLE pedido_lineas (
  pedido_id   INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea       INTEGER NOT NULL,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  cantidad    INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unit TEXT NOT NULL,
  PRIMARY KEY (pedido_id, linea)
);

CREATE TABLE pagos (
  id         INTEGER PRIMARY KEY,
  pedido_id  INTEGER NOT NULL REFERENCES pedidos(id),
  metodo     TEXT NOT NULL CHECK (metodo IN ('TARJETA','TRANSFERENCIA','EFECTIVO')),
  importe    TEXT NOT NULL,
  pagado_en  TEXT NOT NULL,
  referencia TEXT UNIQUE
);

CREATE TABLE eventos_pedido (
  id          INTEGER PRIMARY KEY,
  pedido_id   INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  tipo        TEXT NOT NULL,
  carga       TEXT NOT NULL,              -- JSON como texto: las funciones json_* lo leen igual
  ocurrido_en TEXT NOT NULL
);
