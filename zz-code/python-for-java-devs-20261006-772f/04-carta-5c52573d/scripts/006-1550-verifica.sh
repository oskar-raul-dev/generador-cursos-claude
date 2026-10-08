# rescatado de la sesión 5c52573d, 2026-10-05T15:50:08Z · Check extra package names on PyPI
for p in xsdata python-pkcs11 bots-edi bots pydifact fhir.resources hl7 hl7apy python-hl7; do printf "%-16s " $p; curl -s https://pypi.org/pypi/$p/json | python3 -c "import json,sys
try:
 d=json.load(sys.stdin);v=d['info']['version'];print(v, (d['releases'][v] or [{'upload_time':'?'}])[0]['upload_time'][:10])
except Exception: print('NO EXISTE')"; done
