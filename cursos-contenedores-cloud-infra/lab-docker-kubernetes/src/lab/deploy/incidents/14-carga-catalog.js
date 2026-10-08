// La carga del incidente 14 (Fase 15): 400 usuarios pidiendo el catálogo por la puerta durante dos
// minutos. k6 corre en tu máquina: k6 run deploy/incidents/14-carga-catalog.js
import http from 'k6/http';
export const options = { vus: 400, duration: '120s' };
export default function () {
  http.get('http://api.localhost:8080/catalog/products');
}
