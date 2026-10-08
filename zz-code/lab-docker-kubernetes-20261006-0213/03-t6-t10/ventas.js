// Ventas de una unidad a tasa constante por la puerta, para medir la venta con y sin mTLS.
import http from 'k6/http';
export const options = {
  scenarios: { v: { executor: 'constant-arrival-rate', rate: 10, timeUnit: '1s', duration: '30s', preAllocatedVUs: 10, maxVUs: 50 } },
  summaryTrendStats: ['med', 'p(95)', 'max'],
};
export default function () {
  http.post('http://api.localhost:8080/inventory/sales', JSON.stringify({ store: 'DRO-005', sku: 'SKU-0001', quantity: 1 }),
    { headers: { 'Content-Type': 'application/json' } });
}
