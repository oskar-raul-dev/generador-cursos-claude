-- Una base y un usuario por servicio, creados la primera vez que arranca ms-postgres.
-- Cada usuario es dueño de su base y NO puede conectarse a las demás: la frontera de datos de 03/01
-- la hace cumplir el servidor, no la buena voluntad. Contraseña común de laboratorio (solo desarrollo).
CREATE ROLE ms_monolith  LOGIN PASSWORD 'ms-lab-pass';
CREATE ROLE ms_orders    LOGIN PASSWORD 'ms-lab-pass';
CREATE ROLE ms_inventory LOGIN PASSWORD 'ms-lab-pass';
CREATE ROLE ms_payments  LOGIN PASSWORD 'ms-lab-pass';

CREATE DATABASE ms_monolith  OWNER ms_monolith;
CREATE DATABASE ms_orders    OWNER ms_orders;
CREATE DATABASE ms_inventory OWNER ms_inventory;
CREATE DATABASE ms_payments  OWNER ms_payments;

-- Por defecto PUBLIC puede conectarse a cualquier base: se quita, y cada dueño conserva la suya.
REVOKE CONNECT ON DATABASE ms_monolith, ms_orders, ms_inventory, ms_payments FROM PUBLIC;
