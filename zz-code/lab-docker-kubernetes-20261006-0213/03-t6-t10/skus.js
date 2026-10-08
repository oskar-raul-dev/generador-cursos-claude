// 2.000 SKU distintos, una lectura de precio por cada uno, por la puerta.
import http from 'k6/http';
import exec from 'k6/execution';
export const options = { scenarios: { s: { executor: 'shared-iterations', vus: 10, iterations: 2000 } } };
export default function () {
  const n = String(exec.scenario.iterationInTest + 1).padStart(4, '0');
  http.get(`http://api.localhost:8080/pricing/prices/SKU-${n}?store=DRO-001`);
}
