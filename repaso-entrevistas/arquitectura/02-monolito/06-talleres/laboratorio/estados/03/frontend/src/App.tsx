import { useEffect, useState } from "react";
import { ApiError, createOrder, getOrder, listOrders, listProducts, login } from "./api.ts";
import type { Order, Product } from "./api.ts";
import { created, lineSummary, money } from "./view.ts";

export function App() {
  const [logged, setLogged] = useState(false);
  const [products, setProducts] = useState<Product[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [detail, setDetail] = useState<Order | null>(null);
  const [message, setMessage] = useState("");

  const refresh = async () => {
    setProducts(await listProducts());
    setOrders(await listOrders());
  };

  useEffect(() => {
    if (logged) void refresh();
  }, [logged]);

  const run = async (action: () => Promise<void>) => {
    try {
      await action();
    } catch (e) {
      setMessage(e instanceof ApiError ? `❌ Error ${e.status}: ${e.message}` : `❌ ${String(e)}`);
    }
  };

  if (!logged) {
    return (
      <main>
        <h1>mono · tienda</h1>
        <button onClick={() => run(async () => { await login("ana@mono.local", "ana-12345"); setLogged(true); })}>
          Entrar como ana
        </button>
        <p>{message}</p>
      </main>
    );
  }

  return (
    <main>
      <h1>mono · tienda</h1>
      <p role="status">{message}</p>
      <h2>Catálogo</h2>
      <ul>
        {products.map((p) => (
          <li key={p.sku}>
            {p.sku} · {p.name} · {money(p.price)} · stock {p.stock}{" "}
            <button onClick={() => run(async () => { setMessage(created(await createOrder(p.sku, 1))); await refresh(); })}>
              Comprar 1
            </button>
          </li>
        ))}
        <li>
          SKU-999 · (no existe){" "}
          <button onClick={() => run(async () => { setMessage(created(await createOrder("SKU-999", 1))); })}>Comprar 1</button>
        </li>
      </ul>
      <h2>Mis pedidos</h2>
      <ul>
        {orders.map((o) => (
          <li key={o.id}>
            {o.id.slice(0, 8)} · {o.status} · {money(o.total)}{" "}
            <button onClick={() => run(async () => setDetail(await getOrder(o.id)))}>Ver</button>
          </li>
        ))}
        <li>
          00000000 · (no existe){" "}
          <button onClick={() => run(async () => setDetail(await getOrder("00000000-0000-4000-8000-000000000000")))}>Ver</button>
        </li>
      </ul>
      {detail && (
        <section>
          <h2>Pedido {detail.id}</h2>
          <p>{lineSummary(detail)}</p>
          <p>Total: {money(detail.total)}</p>
        </section>
      )}
    </main>
  );
}
