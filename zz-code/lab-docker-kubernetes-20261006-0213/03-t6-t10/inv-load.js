// Carga sobre inventory por la puerta: lecturas y movimientos (Fase 15, la autopsia del OOMKilled).
import http from 'k6/http';
export const options = { vus: Number(__ENV.VUS || 40), duration: __ENV.DURATION || '300s' };
const base = 'http://api.localhost:8080/inventory';
const hdr = { headers: { 'Content-Type': 'application/json' } };
export default function () {
  const store = `DRO-0${String(10 + (__VU % 20)).padStart(2, '0')}`;
  const sku = `SKU-000${1 + (__ITER % 8)}`;
  http.post(`${base}/stock/${store}/${sku}/movements`, JSON.stringify({ type: 'RESTOCK', quantity: 1, reference: 'carga-f15' }), hdr);
  http.get(`${base}/stock/${store}/${sku}`);
  http.get(`${base}/reason-codes`);
}
