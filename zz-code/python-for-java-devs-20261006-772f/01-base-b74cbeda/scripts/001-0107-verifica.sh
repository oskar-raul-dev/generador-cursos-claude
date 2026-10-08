# rescatado de la sesión b74cbeda, 2026-09-13T01:07:53Z · Check PyCharm version and VS Code extension IDs
curl -s "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release" | python3 -c "import sys,json;d=json.load(sys.stdin);r=d['PCP'][0];print(r['version'], r['date'])"; echo "--- vscode python ext ---"; for ext in ms-python.python ms-python.vscode-pylance ms-python.debugpy charliermarsh.ruff; do echo -n "$ext: "; curl -s -X POST "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" -H "Content-Type: application/json" -H "Accept: application/json;api-version=7.2-preview.1" -d "{\"filters\":[{\"criteria\":[{\"filterType\":7,\"value\":\"$ext\"}]}],\"flags\":914}" | python3 -c "import sys,json
d=json.load(sys.stdin)
try:
    e=d['results'][0]['extensions'][0]; print(e['displayName'],'|',e['publisher']['displayName'],'|',e['versions'][0]['version'])
except Exception as ex: print('n/a')"; done
