// a09: lo que tarda en tener la página con sus datos. MODE=static: el HTML del storefront y las tres peticiones que
// la página hace después (config, catálogo y precios); MODE=ssr: una petición, con los datos ya en el HTML.
import http from 'k6/http';
import { check } from 'k6';
export const options = {
  scenarios: { pagina: { executor: 'constant-arrival-rate', rate: 20, timeUnit: '1s', duration: '30s', preAllocatedVUs: 20 } },
  summaryTrendStats: ['med', 'p(95)', 'max'],
};
export default function () {
  if (__ENV.MODE === 'ssr') {
    check(http.get('http://ssr.localhost:8080/?store=DRO-007'), { 'ssr 200': (r) => r.status === 200 });
    return;
  }
  check(http.get('http://storefront.localhost:8080/'), { 'html 200': (r) => r.status === 200 });
  check(http.get('http://storefront.localhost:8080/config.json'), { 'config 200': (r) => r.status === 200 });
  check(http.get('http://api.localhost:8080/catalog/products'), { 'catalog 200': (r) => r.status === 200 });
  check(http.get('http://api.localhost:8080/pricing/prices?store=DRO-007'), { 'prices 200': (r) => r.status === 200 });
}
