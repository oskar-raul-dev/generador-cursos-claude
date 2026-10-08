// El storefront con renderizado en servidor (apéndice a09). La página se arma aquí, en cada petición: el catálogo y
// los precios se piden a catalog y a pricing por la red del cluster, y la marca sale del entorno del proceso.
import http from 'node:http';
import { readFileSync } from 'node:fs';
import { createElement as h } from 'react';
import { renderToString } from 'react-dom/server';

const PORT = Number(process.env.PORT ?? 8080);
const CATALOG = process.env.CATALOG_URL ?? 'http://catalog:8080';
const PRICING = process.env.PRICING_URL ?? 'http://pricing:8080';
const log = (msg, extra = {}) =>
  process.stdout.write(JSON.stringify({ time: new Date().toISOString(), level: 'INFO', service: 'storefront-ssr', msg, ...extra }) + '\n');

const pesos = (n) => `$${n.toLocaleString('es-CO')}`;

function Page({ brand, store, products, prices }) {
  return h('html', { lang: 'es' },
    h('head', null, h('meta', { charSet: 'utf-8' }), h('title', null, brand)),
    h('body', null,
      h('h1', null, brand),
      h('p', null, `Droguería ${store}`),
      h('ul', null, products.map((p) =>
        h('li', { key: p.sku, 'data-sku': p.sku }, `${p.name} · ${prices[p.sku] ? pesos(prices[p.sku]) : 'sin precio'}`)))));
}

async function getJson(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(2000) });
  if (!response.ok) throw new Error(`${url} respondió ${response.status}`);
  return response.json();
}

const server = http.createServer(async (req, res) => {
  const start = performance.now();
  const url = new URL(req.url, 'http://local');
  try {
    if (url.pathname === '/health/live' || url.pathname === '/health/ready') {
      res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ status: url.pathname.endsWith('live') ? 'live' : 'ready' }));
      return;
    }
    const store = url.searchParams.get('store') ?? 'DRO-007';
    // La configuración, en cada petición: la del proceso que atiende, no la del momento de compilar.
    // Con BRAND_FILE (un ConfigMap montado), se lee en cada petición: cambiar el ConfigMap cambia la página sin reiniciar.
    const brand = process.env.BRAND_FILE
      ? readFileSync(process.env.BRAND_FILE, 'utf8').trim()
      : (process.env.BRAND_NAME ?? 'Droguerías La Vecina');
    const [products, priceList] = await Promise.all([
      getJson(`${CATALOG}/products`),
      getJson(`${PRICING}/prices?store=${store}`).catch(() => []),
    ]);
    const prices = Object.fromEntries(priceList.map((p) => [p.sku, p.price]));
    const html = '<!doctype html>' + renderToString(h(Page, { brand, store, products, prices }));
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }).end(html);
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'text/plain; charset=utf-8' }).end(`No se pudo armar la página: ${e.message}`);
  } finally {
    log('request', { path: url.pathname, status: res.statusCode, duration_ms: Math.round((performance.now() - start) * 10) / 10 });
  }
});

server.listen(PORT, () => log('escuchando', { port: PORT }));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
