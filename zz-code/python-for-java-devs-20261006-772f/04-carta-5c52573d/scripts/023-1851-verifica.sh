# rescatado de la sesión 5c52573d, 2026-10-05T18:51:04Z · Check NATS docs URL with curl and Python
echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 https://docs.nats.io/nats-concepts/jetstream) docs.nats.io"; python3 -c "
import urllib.request
try: urllib.request.urlopen('https://docs.nats.io/nats-concepts/jetstream', timeout=20); print('ok')
except Exception as e: print(e)"
