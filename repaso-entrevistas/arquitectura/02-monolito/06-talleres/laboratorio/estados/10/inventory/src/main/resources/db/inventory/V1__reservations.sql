-- V1 de mono-inventory (taller 10). Las reservas con identificador: repetir una reserva con el mismo id
-- no reserva dos veces, y liberar un id que nunca llegó deja una lápida para que, si llega tarde, no se
-- aplique. Es lo que hace segura la compensación del lado de mono-legacy.
CREATE TABLE inventory_reservations (
    id         uuid PRIMARY KEY,
    sku        varchar(255) NOT NULL,
    quantity   integer NOT NULL,
    status     varchar(20) NOT NULL,          -- RESERVED | RELEASED
    created_at timestamptz NOT NULL DEFAULT now()
);

-- inventory es de este proceso desde ahora: su clave hacia products (la tabla del catálogo, de
-- mono-legacy) ataba el esquema de los dos
ALTER TABLE inventory DROP CONSTRAINT IF EXISTS inventory_sku_fkey;
