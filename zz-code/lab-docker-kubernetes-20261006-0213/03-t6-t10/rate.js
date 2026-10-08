// Tasa constante contra un servicio por la puerta (Fase 16): cuántas peticiones fallan durante un rollout.
import http from 'k6/http';
export const options = {
  scenarios: { constante: { executor: 'constant-arrival-rate', rate: Number(__ENV.RATE || 200), timeUnit: '1s',
    duration: __ENV.DURATION || '40s', preAllocatedVUs: 50, maxVUs: 400 } },
};
export default function () { http.get(__ENV.URL); }
