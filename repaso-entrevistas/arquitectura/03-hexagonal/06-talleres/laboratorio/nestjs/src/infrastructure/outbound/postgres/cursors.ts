// Cursores opacos: el cliente los devuelve tal cual; solo el adaptador sabe qué llevan dentro.
// Un cursor ilegible se trata como "primera página".
export function encodeCursor(raw: string): string {
  return Buffer.from(raw, "utf8").toString("base64url");
}

export function decodeCursor(cursor: string | null): string | null {
  if (!cursor) return null;
  try {
    return Buffer.from(cursor, "base64url").toString("utf8");
  } catch {
    return null;
  }
}

export type TimeCursor = { ts: Date; id: string };

export function encodeTimeCursor(ts: Date, id: string): string {
  return encodeCursor(`${ts.toISOString()}|${id}`);
}

export function decodeTimeCursor(cursor: string | null): TimeCursor | null {
  const raw = decodeCursor(cursor);
  if (!raw) return null;
  const sep = raw.indexOf("|");
  if (sep < 0) return null;
  const ts = new Date(raw.slice(0, sep));
  return Number.isNaN(ts.getTime()) ? null : { ts, id: raw.slice(sep + 1) };
}
