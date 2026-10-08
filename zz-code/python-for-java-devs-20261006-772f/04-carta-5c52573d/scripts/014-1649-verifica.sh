# rescatado de la sesión 5c52573d, 2026-10-05T16:49:24Z · Verify dates, holidays pkg, smoke-test qa03
python3 -c "
import datetime as dt
print(dt.date(2026,10,5).strftime('%A'))
def due(d,n=15):
    r=n
    while r:
        d+=dt.timedelta(days=1)
        if d.weekday()<5: r-=1
    return d
print(due(dt.date(2026,9,18)), due(dt.date(2026,9,25)))"; curl -s https://pypi.org/pypi/holidays/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('holidays',v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op032-qa03-dobles-y-datos.md qa03 'glosas.py="""Glosas notificadas' 'test_glosas.py="""La red simulada' --pip pytest==9.1.1 httpx==0.28.1 pydantic==2.13.5 respx==0.23.1 time-machine==3.5.1 polyfactory==3.3.0 Faker==40.40.0 --cmd "pytest -q -s -p no:cacheprovider test_glosas.py 2>&1 | tail -15"
