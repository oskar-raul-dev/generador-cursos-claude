-- name: crear_tablas#
CREATE TABLE plan (id INTEGER PRIMARY KEY, codigo TEXT, sede TEXT);
CREATE TABLE fase (id INTEGER PRIMARY KEY, plan_id INTEGER REFERENCES plan(id), valor INTEGER, estado TEXT);

-- name: nuevo_plan(codigo, sede)<!
INSERT INTO plan (codigo, sede) VALUES (:codigo, :sede) RETURNING id;

-- name: nueva_fase(plan_id, valor, estado)!
INSERT INTO fase (plan_id, valor, estado) VALUES (:plan_id, :valor, :estado);

-- name: saldos_por_sede(sede, n)
-- Los planes de una sede con más saldo pendiente.
SELECT p.codigo, SUM(f.valor) AS saldo
FROM plan AS p JOIN fase AS f ON f.plan_id = p.id
WHERE p.sede = :sede AND f.estado = 'pendiente'
GROUP BY p.codigo
ORDER BY saldo DESC
LIMIT :n;
