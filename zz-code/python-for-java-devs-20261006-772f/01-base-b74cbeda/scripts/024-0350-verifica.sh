# rescatado de la sesión b74cbeda, 2026-09-13T03:50:06Z · Check current Spring Boot version
curl -s "https://api.github.com/repos/spring-projects/spring-boot/releases?per_page=10" | python3 -c "
import sys,json
for r in json.load(sys.stdin):
    if not r['prerelease']: print(r['tag_name'], r['published_at'][:10])" 2>/dev/null | head -6
