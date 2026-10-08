// Carga de lectura por la puerta: los cuatro backends a la vez, para ver la memoria bajo carga (Fase 15).
import http from 'k6/http';
export const options = { vus: 20, duration: __ENV.DURATION || '60s' };
const urls = [
  'http://api.localhost:8080/pricing/prices?store=DRO-007',
  'http://api.localhost:8080/inventory/reason-codes',
  'http://api.localhost:8080/catalog/products',
  'http://api.localhost:8080/replenish/replenishment-orders',
];
export default function () {
  for (const u of urls) http.get(u);
}
