// Carga sobre catalog por la puerta (Fase 15, incidente 14).
import http from 'k6/http';
export const options = { vus: Number(__ENV.VUS || 200), duration: __ENV.DURATION || '120s' };
export default function () {
  http.get('http://api.localhost:8080/catalog/products');
}
