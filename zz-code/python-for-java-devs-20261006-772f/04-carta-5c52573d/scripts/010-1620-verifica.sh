# rescatado de la sesión 5c52573d, 2026-10-05T16:20:51Z · Mark co01 and probe real SPF/DMARC records
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op015-co01-correo-saliente.md; docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c "pip install -q --root-user-action=ignore dnspython==2.8.0 >/dev/null 2>&1; python -c \"
import dns.resolver
for name in ['gmail.com','_dmarc.gmail.com']:
    for r in dns.resolver.resolve(name,'TXT'):
        s=b''.join(r.strings).decode()
        if s.startswith(('v=spf1','v=DMARC1')): print(name, '→', s)
\""
