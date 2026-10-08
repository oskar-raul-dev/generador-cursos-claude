// Desde adentro de un pod: ¿llego a estos destinos? Una línea por destino. Timeout de 3 s.
const net = require('node:net');
const targets = [
  ['pricing de apps (8080)', 'http://pricing.apps.svc.cluster.local:8080/prices?store=DRO-007'],
  ['inventory de apps (8080)', 'http://inventory.apps.svc.cluster.local:8080/reason-codes'],
  ['pricing de su cadena (8080)', `http://pricing.${process.env.NS}.svc.cluster.local:8080/prices?store=DRO-007`],
  ['postgres de data (5432)', 'tcp://postgres.data.svc.cluster.local:5432'],
];
const tcp = (host, port) => new Promise((ok) => {
  const s = net.connect({ host, port, timeout: 3000 }, () => { s.end(); ok('conecta'); });
  s.on('timeout', () => { s.destroy(); ok('timeout (3 s)'); }); s.on('error', (e) => ok(e.code || e.message));
});
(async () => {
  for (const [name, url] of targets) {
    let r;
    if (url.startsWith('tcp://')) { const u = new URL(url.replace('tcp', 'http')); r = await tcp(u.hostname, Number(u.port)); }
    else { try { const res = await fetch(url, { signal: AbortSignal.timeout(3000) }); r = `HTTP ${res.status}`; } catch (e) { r = e.cause?.code || e.name; } }
    console.log(`${name.padEnd(30)} ${r}`);
  }
})();
