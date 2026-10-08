// Página con cursor opaco (null en la última). El cursor lo fabrica y lo lee el adaptador.
export type Page<T> = { items: T[]; nextCursor: string | null };

export function mapPage<T, R>(page: Page<T>, fn: (t: T) => R): Page<R> {
  return { items: page.items.map(fn), nextCursor: page.nextCursor };
}

export const MAX_LIMIT = 100;
export const DEFAULT_LIMIT = 20;

export type PageRequest = { cursor: string | null; limit: number };

// El servidor acota el tamaño aunque el cliente pida más (decisión del contrato).
export function pageRequest(cursor: string | null | undefined, limit: number | null | undefined): PageRequest {
  const bounded = !limit || limit < 1 ? DEFAULT_LIMIT : Math.min(limit, MAX_LIMIT);
  return { cursor: cursor ?? null, limit: bounded };
}
