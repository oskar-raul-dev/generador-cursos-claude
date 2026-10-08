# rescatado de la sesión 5c52573d, 2026-10-05T16:16:11Z · Smoke-test PEP 723 script with uv
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op013-au06-desplegar-automatizaciones.md au06 'revisar_circulares.py=# /// script' 'aurea-circulares.service=[Unit]
Description=Revisión' 'aurea-circulares.timer=[Unit]
Description=Todos' --pip uv==0.12.23 --cmd "PORTAL_TOKEN=prueba uv run -q --script revisar_circulares.py" 2>&1 | grep -v "^$" | tail -5; ls salidas/au06
