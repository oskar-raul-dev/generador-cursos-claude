// La Braqui como módulo del Siga (2023): no tiene base propia. Cada 30 segundos pregunta en las
// tablas de despachos del Siga —aquí, de Contingencia— si hay domicilios esperando moto.
const http = require('node:http');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const POLL_MS = 30_000; // el sondeo de la historia: nadie le avisa a la Braqui que hay un despacho
const recent = [];

async function assignPending() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: pending } = await client.query(
      "SELECT id, store_id, address FROM dispatch WHERE status = 'PENDING' ORDER BY id FOR UPDATE SKIP LOCKED");
    for (const d of pending) {
      // La moto con menos despachos asignados; las tablas son del Siga, la regla es de la Braqui.
      const { rows: [rider] } = await client.query(
        `SELECT r.id, r.name FROM rider r
           LEFT JOIN dispatch d ON d.rider_id = r.id
          GROUP BY r.id, r.name ORDER BY count(d.id), r.id LIMIT 1`);
      await client.query("UPDATE dispatch SET status = 'ASSIGNED', rider_id = $1 WHERE id = $2", [rider.id, d.id]);
      console.log(`despacho ${d.id} (${d.store_id}, ${d.address}) asignado a ${rider.name}`);
      recent.unshift({ id: d.id, storeId: d.store_id, address: d.address, rider: rider.name, at: new Date() });
    }
    await client.query('COMMIT');
    recent.splice(20);
  } catch (err) {
    await client.query('ROLLBACK');
    console.log(`error consultando despachos: ${err.message}`);
  } finally {
    client.release();
  }
}

setInterval(assignPending, POLL_MS);
assignPending();

http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/dispatches') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(recent));
  }
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not_found' }));
}).listen(Number(process.env.PORT || 8080), () => console.log('Braqui despachando cada 30 s'));
