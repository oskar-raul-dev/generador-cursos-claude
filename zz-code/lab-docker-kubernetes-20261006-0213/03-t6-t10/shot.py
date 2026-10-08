"""Abre una página en Chrome sin interfaz, hace clic en un botón y lee el resultado (protocolo de depuración,
con un cliente de WebSocket mínimo: solo biblioteca estándar)."""
import base64, json, os, socket, struct, subprocess, sys, tempfile, time, urllib.request
url, out, wait_s = sys.argv[1], sys.argv[2], float(sys.argv[3])
chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
profile = tempfile.mkdtemp(prefix="cdp-")
proc = subprocess.Popen([chrome, "--headless=new", "--remote-debugging-port=9333", f"--user-data-dir={profile}", "--no-first-run", "--window-size=1600,1300", "about:blank"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    for _ in range(50):
        try:
            targets = json.load(urllib.request.urlopen("http://127.0.0.1:9333/json")); break
        except Exception: time.sleep(0.2)
    ws_url = [t for t in targets if t["type"] == "page"][0]["webSocketDebuggerUrl"]
    host, path = ws_url[len("ws://"):].split("/", 1)
    h, p = host.split(":")
    s = socket.create_connection((h, int(p)))
    key = base64.b64encode(os.urandom(16)).decode()
    s.send(f"GET /{path} HTTP/1.1\r\nHost: {host}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n".encode())
    buf = b""
    while b"\r\n\r\n" not in buf: buf += s.recv(4096)
    buf = buf.split(b"\r\n\r\n", 1)[1]
    def send(obj):
        data = json.dumps(obj).encode(); mask = os.urandom(4); n = len(data)
        head = bytes([0x81]) + (bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n))
        s.send(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))
    def recv():
        global buf
        while True:
            while len(buf) < 2: buf += s.recv(65536)
            n = buf[1] & 0x7f; off = 2
            if n == 126:
                while len(buf) < 4: buf += s.recv(65536)
                n = struct.unpack(">H", buf[2:4])[0]; off = 4
            elif n == 127:
                while len(buf) < 10: buf += s.recv(65536)
                n = struct.unpack(">Q", buf[2:10])[0]; off = 10
            while len(buf) < off + n: buf += s.recv(65536)
            frame, buf = buf[off:off + n], buf[off + n:]
            return json.loads(frame)
    ids = iter(range(1, 10000))
    def call(method, **params):
        i = next(ids); send({"id": i, "method": method, "params": params})
        while True:
            m = recv()
            if m.get("id") == i: return m
    def js(expr):
        return call("Runtime.evaluate", expression=expr, awaitPromise=True, returnByValue=True)["result"]["result"].get("value")
    call("Emulation.setDeviceMetricsOverride", width=1600, height=1300, deviceScaleFactor=1, mobile=False)
    call("Page.navigate", url=url)
    time.sleep(wait_s)
    shot = call("Page.captureScreenshot", format="png")["result"]["data"]
    open(out, "wb").write(base64.b64decode(shot))
    print("texto:", (js("document.body.innerText") or "")[:1500])
finally:
    proc.terminate()
