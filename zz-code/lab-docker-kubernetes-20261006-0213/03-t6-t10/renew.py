"""Peticiones HTTPS continuas a la puerta, validando con la CA; anota el serial del certificado servido
cuando cambia, y cada fallo. renew.py <ca.crt> <segundos> <por segundo>"""
import http.client, ssl, sys, time
from cryptography import x509
ca, secs, rate = sys.argv[1], int(sys.argv[2]), float(sys.argv[3])
ctx = ssl.create_default_context(cafile=ca)
ok = fail = 0; last = None; t0 = time.time()
while time.time() - t0 < secs:
    try:
        c = http.client.HTTPSConnection("127.0.0.1", 8443, context=ctx, timeout=5)
        c._create_connection  # noqa
        c.sock = None
        conn = http.client.HTTPSConnection("api.localhost", 8443, context=ctx, timeout=5)
        conn.connect()
        der = conn.sock.getpeercert(binary_form=True)
        serial = format(x509.load_der_x509_certificate(der).serial_number, "X")
        conn.request("GET", "/pricing/prices?store=DRO-007"); r = conn.getresponse(); r.read(); conn.close()
        if r.status == 200: ok += 1
        else: fail += 1; print(f"{time.time()-t0:7.1f}s estado {r.status}", flush=True)
        if serial != last:
            print(f"{time.time()-t0:7.1f}s {time.strftime('%H:%M:%S')} certificado servido: serial {serial[:16]}…", flush=True); last = serial
    except Exception as e:
        fail += 1; print(f"{time.time()-t0:7.1f}s error: {e}", flush=True)
    time.sleep(1 / rate)
print(f"fin: {ok} bien, {fail} mal")
