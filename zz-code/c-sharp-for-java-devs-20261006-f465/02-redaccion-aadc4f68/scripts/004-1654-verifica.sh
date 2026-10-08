# rescatado de la sesión aadc4f68, 2026-09-13T16:54:31Z · 
cd "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs" && for f in prompts/*.md; do python3 - "$f" <<'PY'
import sys,unicodedata
t=open(sys.argv[1],encoding='utf-8').read()
bad=[ch for ch in set(t) if ord(ch)>127 and ('CYRILLIC' in unicodedata.name(ch,'') or 'GREEK' in unicodedata.name(ch,''))]
if bad: print(sys.argv[1], bad)
PY
done; echo "sin caracteres raros"; grep -rn "cinco reglas de honestidad" *.md prompts/*.md | head
