# rescatado de la sesión b74cbeda, 2026-09-13T03:15:32Z · Verify the documented server and save the asset
import httpx, hmac, hashlib, json
B="http://127.0.0.1:8098"
SECRET=b"el-secreto-que-comparten-aurea-y-el-socio"
print("intermitente x3:", [httpx.post(f"{B}/intermitente", json={"a":i}).status_code for i in range(3)])
body=json.dumps({"evento":1}).encode()
firma=hmac.new(SECRET, body, hashlib.sha256).hexdigest()
print("firmado con firma buena:", httpx.post(f"{B}/firmado", content=body, headers={"X-Firma":firma,"Content-Type":"application/json"}).status_code)
print("firmado con firma mala :", httpx.post(f"{B}/firmado", content=body, headers={"X-Firma":"00"*32}).status_code)
r=httpx.post(f"{B}/truncado", json={"a":1})
try:
    r.json(); print("truncado: se parseó (mal)")
except Exception as e: print("truncado:", r.status_code, "y el cuerpo revienta ->", type(e).__name__)
print("mentiroso:", httpx.post(f"{B}/mentiroso", json={"a":1}).status_code)
print("recibidos:", httpx.get(f"{B}/_recibidos").json())
