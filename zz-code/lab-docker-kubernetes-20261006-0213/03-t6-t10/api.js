// Desde adentro de un pod, con el token montado de su ServiceAccount: leer un Secret por la API.
const fs = require('node:fs');
const dir = '/var/run/secrets/kubernetes.io/serviceaccount';
const token = fs.readFileSync(`${dir}/token`, 'utf8');
process.env.NODE_EXTRA_CA_CERTS = `${dir}/ca.crt`;
const url = `https://kubernetes.default.svc/api/v1/namespaces/${process.argv[2]}/secrets/${process.argv[3]}`;
fetch(url, { headers: { Authorization: `Bearer ${token}` } })
  .then(async (r) => { const b = await r.json(); console.log(r.status, b.message || `ok: ${Object.keys(b.data || {}).join(', ')}`); })
  .catch((e) => console.log('error:', e.cause?.code || e.message));
