# rescatado de la sesión 5c52573d, 2026-10-05T15:13:38Z · Dump all diagram candidates to a file
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; Z=zz-code/go-for-java-devs-20261005-ab98; python3 - "$G" "$Z/salidas/diagramas.log" > $Z/salidas/candidatos.txt <<'EOF'
import sys,re
g,log=sys.argv[1],sys.argv[2]
for l in open(log):
    f,n=l.split()[0].rsplit(':',1); n=int(n)
    L=open(f"{g}/{f}",encoding='utf-8').read().splitlines()
    j=n
    while not L[j].startswith('```'): j+=1
    print(f"=== {f}:{n}  (contexto: {L[n-3][:90]!r})")
    print("\n".join(L[n-1:j+1]))
EOF
wc -l $Z/salidas/candidatos.txt
