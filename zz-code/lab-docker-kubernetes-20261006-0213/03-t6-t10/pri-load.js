import http from 'k6/http';
export const options = { vus: 20, duration: '30s' };
export default function () { http.get('http://api.localhost:8080/pricing/prices?store=DRO-007'); }
