// B-23 (Fase 23): ventas de una unidad a tasa constante por la puerta. Cada venta es una llamada gRPC de
// inventory a pricing; el reparto entre las réplicas de pricing lo cuenta measure.py.
import http from 'k6/http';
export const options = {
  scenarios: { ventas: { executor: 'constant-arrival-rate', rate: Number(__ENV.RATE || 20), timeUnit: '1s',
    duration: __ENV.DURATION || '30s', preAllocatedVUs: 20, maxVUs: 200 } },
  summaryTrendStats: ['med', 'p(95)', 'max'],
};
export function setup() {
  http.post('http://api.localhost:8080/inventory/stock/DRO-006/SKU-0002/movements',
    JSON.stringify({ type: 'COUNT', quantity: 100000, reference: 'b23' }), { headers: { 'Content-Type': 'application/json' } });
}
export default function () {
  http.post('http://api.localhost:8080/inventory/sales', JSON.stringify({ store: 'DRO-006', sku: 'SKU-0002', quantity: 1 }),
    { headers: { 'Content-Type': 'application/json' } });
}
