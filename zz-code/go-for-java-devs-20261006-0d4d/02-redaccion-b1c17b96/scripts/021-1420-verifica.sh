# rescatado de la sesión b1c17b96, 2026-09-12T14:20:48Z · Check exact separator before section 9
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
l=$(grep -n '^## 📚 9\. Referencias' 01-sintaxis-y-valores.md | cut -d: -f1)
sed -n "$((l-3)),$((l))p" 01-sintaxis-y-valores.md | cat -A | head -5
