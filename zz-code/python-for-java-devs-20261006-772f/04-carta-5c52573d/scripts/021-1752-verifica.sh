# rescatado de la sesión 5c52573d, 2026-10-05T17:52:23Z · Rerun ui05 app serving test with block prefixes
python3 humo.py op068-ui05-nicegui-y-compania.md ui05 'app_nicegui.py="""La pantalla de cartera en NiceGUI' 'app_shiny.py="""La misma pantalla en Shiny' 'medir.py="""Lo que pesa' --pip nicegui==3.17.1 shiny==1.8.0 --cmd 'python app_nicegui.py > ng.log 2>&1 & shiny run app_shiny.py --port 8082 > sh.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request as u;u.urlopen(\"http://127.0.0.1:8081/\");u.urlopen(\"http://127.0.0.1:8082/\")" 2>/dev/null && break; sleep 1; done; python -c "
import urllib.request as u, re
for p in (8081, 8082):
    h = u.urlopen(f\"http://127.0.0.1:{p}/\").read().decode()
    print(p, len(h), \"Cartera por sede\" in h, \"Facturado\" in h, re.findall(r\"<title>(.*?)</title>\", h))"; tail -3 ng.log sh.log' 2>&1 | tail -12
