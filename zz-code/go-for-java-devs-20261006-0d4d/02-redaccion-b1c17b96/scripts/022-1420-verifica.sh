# rescatado de la sesión b1c17b96, 2026-09-12T14:20:58Z · Verify separator line before section 9
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  l=$(grep -n '^## 📚 9\. Referencias' "$f" | cut -d: -f1)
  prev=$(sed -n "$((l-2))p" "$f")
  printf "%-38s [%s]\n" "$f" "$prev"
done
