# rescatado de la sesión b1c17b96, 2026-09-12T14:18:51Z · Check project tag ordering
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== TAGS DE PROYECTO: orden monotono por servicio ==="
grep -ho 'git tag -a [a-z]*/v[0-9.]*' [01][0-9]-*.md | awk '{print $4}' | sort -t/ -k1,1 -V | awk -F/ '{print $1"\t"$2}'
echo
echo "=== TAGS DE HITO usados ==="
grep -ho 'git tag -a [a-z-]*[/-][a-z0-9.-]*' [01][0-9]-*.md | awk '{print $4}' | grep -vE '^(opsreport|eventrelay|atlassync|clearinghouse)/' | sort -u
