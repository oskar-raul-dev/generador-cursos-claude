// B-16 (Fase 16): una tasa constante de lecturas por la puerta contra un servicio. La tasa, la URL y la
// duración llegan por variables de entorno; task measure -- B-16 las pone.
import http from 'k6/http';
export const options = {
  scenarios: {
    constante: {
      executor: 'constant-arrival-rate',
      rate: Number(__ENV.RATE || 400), timeUnit: '1s',
      duration: __ENV.DURATION || '30s',
      preAllocatedVUs: 50, maxVUs: 400,
    },
  },
  summaryTrendStats: ['med', 'p(95)', 'max'],
};
export default function () { http.get(__ENV.URL); }
