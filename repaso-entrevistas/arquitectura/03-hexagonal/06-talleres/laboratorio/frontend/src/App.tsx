import { useCallback, useEffect, useState } from "react";
import { ApiError, type OrdersApi } from "./api/ordersApi";
import type { Notification, Order, OrderLineRequest, Product } from "./api/types";

// La UI depende del puerto OrdersApi y de los tipos del contrato. No sabe si detrás hay fetch real,
// MSW o un backend en Java, Go, Python o PHP. Es deliberadamente mínima: un flujo completo
// (login → catálogo → pedido → pago → cancelación → logout), sin router ni gestor de estado.

type Props = { api: OrdersApi; baseUrl: string; mode: string };
type Session = { email: string; role: "customer" | "operator" };

export function App({ api, baseUrl, mode }: Props) {
  const [session, setSession] = useState<Session | null>(null);
  const [email, setEmail] = useState("ana@hex.local");
  const [password, setPassword] = useState("ana-12345");
  const [products, setProducts] = useState<Product[]>([]);
  const [cart, setCart] = useState<Map<string, number>>(new Map());
  const [orders, setOrders] = useState<Order[]>([]);
  const [selected, setSelected] = useState<Order | null>(null);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<ApiError | null>(null);

  // Toda llamada pasa por aquí: el error de API se muestra por `code`; cualquier otro, tal cual.
  const run = useCallback(async (action: () => Promise<void>) => {
    setError(null);
    setMessage(null);
    try {
      await action();
    } catch (e) {
      if (e instanceof ApiError) setError(e);
      else setMessage(`Fallo inesperado: ${(e as Error).message}`);
    }
  }, []);

  const refresh = useCallback(async () => {
    const [page, mine] = await Promise.all([api.listProducts(), api.listOrders()]);
    setProducts(page.items);
    setOrders(mine.items);
  }, [api]);

  useEffect(() => {
    if (session) void run(refresh);
  }, [session, run, refresh]);

  const login = () =>
    run(async () => {
      await api.login(email, password);
      setSession({ email, role: email.startsWith("ops") ? "operator" : "customer" });
    });

  const logout = () =>
    run(async () => {
      await api.logout();
      setSession(null);
      setSelected(null);
      setOrders([]);
      setProducts([]);
      setCart(new Map());
    });

  const addToCart = (sku: string) =>
    setCart((c) => new Map(c).set(sku, (c.get(sku) ?? 0) + 1));

  const createOrder = () =>
    run(async () => {
      const lines: OrderLineRequest[] = [...cart].map(([sku, quantity]) => ({ sku, quantity }));
      // La clave la elige el cliente: una por intento de compra, no una por clic
      const { order, replayed } = await api.createOrder(lines, crypto.randomUUID());
      setMessage(replayed ? `Pedido ${order.id} ya existía (repetición idempotente)` : `Pedido ${order.id} creado`);
      setCart(new Map());
      setSelected(order);
      await refresh();
    });

  const pay = (order: Order) =>
    run(async () => {
      const result = await api.authorizePayment(order.id, crypto.randomUUID());
      setMessage(`Pago ${result.payment.status} → pedido ${result.orderStatus}`);
      setSelected(await api.getOrder(order.id));
      await refresh();
    });

  const cancel = (order: Order) =>
    run(async () => {
      const cancelled = await api.cancelOrder(order.id);
      setMessage(`Pedido ${cancelled.id} → ${cancelled.status}`);
      setSelected(cancelled);
      await refresh();
    });

  const loadNotifications = () =>
    run(async () => {
      setNotifications((await api.listNotifications()).items);
    });

  return (
    <main>
      <header>
        <h1>hex-orders</h1>
        <small>
          modo <code>{mode}</code> · base <code>{baseUrl}</code>
          {session && <> · <b>{session.email}</b> ({session.role})</>}
        </small>
      </header>

      {error && (
        <div className="banner error">
          <b>{error.problem.code}</b> ({error.status}) {error.problem.detail ?? error.problem.title}
          {error.problem.errors?.map((e) => (
            <div key={e.field}>
              <code>{e.field}</code>: {e.message}
            </div>
          ))}
        </div>
      )}
      {message && <div className="banner">{message}</div>}

      {!session ? (
        <section>
          <h2>Entrar</h2>
          <label>
            Correo <input value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          <label>
            Contraseña <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
          </label>
          <button onClick={login}>Login</button>
        </section>
      ) : (
        <>
          <section>
            <h2>Catálogo</h2>
            <table>
              <thead>
                <tr><th>SKU</th><th>Producto</th><th>Precio</th><th>Stock</th><th></th></tr>
              </thead>
              <tbody>
                {products.map((p) => (
                  <tr key={p.sku}>
                    <td><code>{p.sku}</code></td>
                    <td>{p.name}</td>
                    <td>{p.unitPrice.amount} {p.unitPrice.currency}</td>
                    <td>{p.stock}</td>
                    <td><button onClick={() => addToCart(p.sku)}>+</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
            {cart.size > 0 && (
              <p>
                Carrito: {[...cart].map(([sku, q]) => `${sku} × ${q}`).join(", ")}{" "}
                <button onClick={createOrder}>Crear pedido</button>
                <button onClick={() => setCart(new Map())}>Vaciar</button>
              </p>
            )}
          </section>

          <section>
            <h2>Pedidos</h2>
            <ul>
              {orders.map((o) => (
                <li key={o.id}>
                  <button className="link" onClick={() => setSelected(o)}>{o.id}</button> · {o.status} · {o.total.amount} {o.total.currency}
                </li>
              ))}
            </ul>
            {selected && (
              <div className="card">
                <h3>{selected.id}</h3>
                <p>Estado: <b>{selected.status}</b> · Total {selected.total.amount} {selected.total.currency}</p>
                <ul>
                  {selected.lines.map((l) => (
                    <li key={l.sku}>{l.quantity} × {l.name} = {l.lineTotal.amount}</li>
                  ))}
                </ul>
                {selected.payment && (
                  <p>Pago: {selected.payment.status} · operación <code>{selected.payment.operationId}</code></p>
                )}
                <button onClick={() => pay(selected)}>Pagar</button>
                <button onClick={() => cancel(selected)}>Cancelar</button>
              </div>
            )}
          </section>

          {session.role === "operator" && (
            <section>
              <h2>Notificaciones</h2>
              <button onClick={loadNotifications}>Cargar</button>
              <ul>
                {notifications.map((n) => (
                  <li key={n.id}>{n.type} · pedido {n.orderId} · a {n.recipient}</li>
                ))}
              </ul>
            </section>
          )}

          <footer>
            <button onClick={logout}>Logout</button>
          </footer>
        </>
      )}
    </main>
  );
}
