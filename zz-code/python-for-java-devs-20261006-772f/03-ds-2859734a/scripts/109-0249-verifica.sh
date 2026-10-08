# rescatado de la sesión 2859734a, 2026-09-14T02:49:15Z · Inspect the git convention document
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "^#\|^##\|^###" 00-convencion-de-git-y-tags.md
echo "---"; wc -l 00-convencion-de-git-y-tags.md
echo "=== cuántas secciones prometen esa convención ==="; grep -rc "La convención completa está en" ia0*.md ds0*.md | grep -v ":0"
