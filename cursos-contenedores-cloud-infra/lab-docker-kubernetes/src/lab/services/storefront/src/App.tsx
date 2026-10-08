import { useEffect, useState } from 'react';

// G2: la configuración se lee al arrancar la página, de /config.json, que el nginx del contenedor arma
// con sus variables de entorno. Nada de configuración se hornea al compilar (Fase 11).
// G5: la venta desde la página. La droguería sale de la dirección (?store=DRO-007); el precio, de
// pricing; y el botón le pide la venta a inventory, que valida, cobra, descuenta y avisa (Fase 16).
interface Config {
  apiBaseUrl: string;
  brandName: string;
}

interface Product {
  sku: string;
  name: string;
  category: string;
}

interface Price {
  sku: string;
  price: number;
}

interface Sale {
  id: string;
  total: number;
  replenishmentRequested: boolean;
}

const store = new URLSearchParams(window.location.search).get('store') ?? 'DRO-007';
const pesos = (value: number) => `$${value.toLocaleString('es-CO')}`;

export default function App() {
  const [config, setConfig] = useState<Config | null>(null);
  const [products, setProducts] = useState<Product[] | null>(null);
  const [prices, setPrices] = useState<Record<string, number>>({});
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);

  useEffect(() => {
    fetch('/config.json')
      .then((response) => {
        if (!response.ok) throw new Error(`/config.json respondió ${response.status}`);
        return response.json() as Promise<Config>;
      })
      .then((loaded) => {
        setConfig(loaded);
        document.title = loaded.brandName;
        // Los precios no son imprescindibles: sin ellos, la página igual lista el catálogo.
        fetch(`${loaded.apiBaseUrl}/pricing/prices?store=${store}`)
          .then((response) => (response.ok ? (response.json() as Promise<Price[]>) : []))
          .then((list) => setPrices(Object.fromEntries(list.map((p) => [p.sku, p.price]))))
          .catch(() => setPrices({}));
        return fetch(`${loaded.apiBaseUrl}/catalog/products`);
      })
      .then((response) => {
        if (!response.ok) throw new Error(`catalog respondió ${response.status}`);
        return response.json() as Promise<Product[]>;
      })
      .then(setProducts)
      .catch((e: Error) => setError(e.message));
  }, []);

  const sell = (sku: string) => {
    if (!config) return;
    setResult(`Vendiendo ${sku}…`);
    fetch(`${config.apiBaseUrl}/inventory/sales`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ store, sku, quantity: 1 }),
    })
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.message ?? `inventory respondió ${response.status}`);
        const sale = body as Sale;
        setResult(
          `Venta ${sale.id}: ${pesos(sale.total)}` +
            (sale.replenishmentRequested ? '. Quedó bajo el umbral: se pidió reposición.' : '.'),
        );
      })
      .catch((e: Error) => setResult(`No se pudo vender ${sku}: ${e.message}`));
  };

  return (
    <main>
      <h1>{config?.brandName ?? 'Cargando…'}</h1>
      <p className="lema">Siempre llega.</p>
      <h2>Catálogo · {store}</h2>
      {error && (
        <p className="aviso">
          No se pudo cargar el catálogo desde {config?.apiBaseUrl ?? '/config.json'} ({error}).
        </p>
      )}
      {!error && products === null && <p>Cargando el catálogo…</p>}
      {products && products.length === 0 && <p>El catálogo está vacío.</p>}
      {products && products.length > 0 && (
        <ul>
          {products.map((p) => (
            <li key={p.sku}>
              <strong>{p.name}</strong> · {p.category} · <code>{p.sku}</code>
              {prices[p.sku] !== undefined && <> · {pesos(prices[p.sku])}</>}{' '}
              <button type="button" data-sku={p.sku} onClick={() => sell(p.sku)}>
                Vender 1
              </button>
            </li>
          ))}
        </ul>
      )}
      {result && <p className="resultado">{result}</p>}
    </main>
  );
}
