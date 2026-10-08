# rescatado de la sesión 5c52573d, 2026-10-05T15:35:38Z · Count planned sections per carta track
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; python3 - "$P/propuestas-temas-opcionales.md" <<'EOF'
import re,sys,collections
t=open(sys.argv[1],encoding='utf-8').read()
ids=re.findall(r'^\|\s*\**`?([a-z]{2})(\d{2})`?',t,re.M)
c=collections.OrderedDict()
for tr,n in ids: c.setdefault(tr,set()).add(n)
tot=0
for k,v in c.items(): print(k,len(v),sorted(v)[:3],'…'); tot+=len(v)
print('total',tot)
EOF
sed -n 265,300p $P/propuestas-temas-opcionales.md
