// Fase 22: la cascada. Ventas a tasa constante (que pasan por catalog) y, al mismo tiempo, lecturas de
// existencias (que no tocan a ningún vecino), cada una con su p95. Con el caos en catalog, se ve si lo lento de
// un vecino se contagia a lo que no lo usa.
//
//   k6 run -e SALES=50 -e READS=10 -e DURATION=60s bench/f22/cascada.js
import http from 'k6/http';

const API = __ENV.API || 'http://api.localhost:8080';
const json = { headers: { 'Content-Type': 'application/json' } };
export const options = {
  scenarios: {
    ventas: { executor: 'constant-arrival-rate', rate: Number(__ENV.SALES || 50), timeUnit: '1s',
      duration: __ENV.DURATION || '60s', preAllocatedVUs: 50, maxVUs: 600, exec: 'sell' },
    existencias: { executor: 'constant-arrival-rate', rate: Number(__ENV.READS || 10), timeUnit: '1s',
      duration: __ENV.DURATION || '60s', preAllocatedVUs: 10, maxVUs: 200, exec: 'read' },
  },
  summaryTrendStats: ['med', 'p(95)', 'max'],
  // Umbrales que no fallan nunca: están para que el resumen muestre cada escenario por separado.
  thresholds: {
    'http_req_duration{scenario:ventas}': ['max>=0'],
    'http_req_duration{scenario:existencias}': ['max>=0'],
    'http_req_failed{scenario:ventas}': ['rate>=0'],
    'http_req_failed{scenario:existencias}': ['rate>=0'],
  },
};

export function setup() {
  http.post(`${API}/inventory/stock/DRO-005/SKU-0001/movements`,
    JSON.stringify({ type: 'COUNT', quantity: 100000, reference: 'cascada' }), json);
}

export function sell() {
  http.post(`${API}/inventory/sales`, JSON.stringify({ store: 'DRO-005', sku: 'SKU-0001', quantity: 1 }),
    Object.assign({ timeout: '30s' }, json));
}

export function read() {
  http.get(`${API}/inventory/stock/DRO-005/SKU-0001`, { timeout: '30s' });
}
