# rescatado de la sesión 5c52573d, 2026-10-05T17:36:40Z · Check mistune escape option in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && ls salidas/tx05/; head -2 salidas/tx05/*.txt 2>/dev/null; docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q mistune==3.3.4 2>/dev/null; python -c "
import mistune
print(mistune.create_markdown(escape=True)(\"<script>x</script>\n\n- a\n  - b\"))"'
