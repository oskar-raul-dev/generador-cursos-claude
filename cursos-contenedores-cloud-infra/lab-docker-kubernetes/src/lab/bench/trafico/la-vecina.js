// Tráfico de fondo de La Vecina (Fase 17): lo que hace la página, a ritmo constante y por la puerta,
// para que los tableros y los logs tengan algo que mostrar. No es una medición: no tiene umbrales.
//
//   k6 run bench/trafico/la-vecina.js                      10 visitas por segundo, 20 minutos
//   k6 run -e RATE=30 -e DURATION=5m bench/trafico/la-vecina.js
//
// Antes de empezar, un conteo deja 500 unidades de los ocho productos del catálogo sembrado en cada
// droguería (el seed siembra productos y precios, no existencias). Cada visita: el catálogo, los precios de una droguería, y
// una de cada cinco termina en una venta de una unidad. Una de cada diez ventas pide un producto que
// catalog no conoce, y falla como debe (422).
import http from 'k6/http';

const API = __ENV.API || 'http://api.localhost:8080';
export const options = {
  scenarios: {
    visitas: {
      executor: 'constant-arrival-rate',
      rate: Number(__ENV.RATE || 10), timeUnit: '1s',
      duration: __ENV.DURATION || '20m',
      preAllocatedVUs: 10, maxVUs: 100,
    },
  },
};

const pick = (n) => Math.floor(Math.random() * n) + 1;
const pad = (n, width) => String(n).padStart(width, '0');
const json = { headers: { 'Content-Type': 'application/json' } };

export function setup() {
  for (let s = 1; s <= 20; s++) {
    for (let p = 1; p <= 8; p++) {
      http.post(`${API}/inventory/stock/DRO-${pad(s, 3)}/SKU-${pad(p, 4)}/movements`,
        JSON.stringify({ type: 'COUNT', quantity: 500, reference: 'trafico-de-fondo' }), json);
    }
  }
}

export default function () {
  const store = `DRO-${pad(pick(20), 3)}`;
  http.get(`${API}/catalog/products`);
  http.get(`${API}/pricing/prices?store=${store}`);
  if (Math.random() < 0.2) {
    const sku = Math.random() < 0.1 ? 'SKU-9999' : `SKU-${pad(pick(8), 4)}`;
    http.post(`${API}/inventory/sales`, JSON.stringify({ store, sku, quantity: 1 }), json);
  }
}
