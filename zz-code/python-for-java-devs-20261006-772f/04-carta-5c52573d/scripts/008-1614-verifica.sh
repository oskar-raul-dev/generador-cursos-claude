# rescatado de la sesión 5c52573d, 2026-10-05T16:14:00Z · Investigate httpx2 deprecation in authlib
for p in httpx2 httpx; do printf "%-8s " $p; curl -s https://pypi.org/pypi/$p/json | python3 -c "import json,sys
try:
 d=json.load(sys.stdin);i=d['info'];v=i['version'];print(v,(d['releases'][v] or [{'upload_time':'?'}])[0]['upload_time'][:10],'|',i.get('summary'),'|',i.get('home_page') or (i.get('project_urls') or {}).get('Homepage') or (i.get('project_urls') or {}).get('Source'))
except Exception as e: print('NO EXISTE',e)"; done; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au05; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore authlib==1.8.0 >/dev/null 2>&1; sed -n 1,30p /usr/local/lib/python3.14/site-packages/authlib/integrations/httpx_client/_compat.py"
