# rescatado de la sesión bd47dbaf, 2026-09-13T05:40:35Z · Check ollama Python client API shape
curl -s --max-time 15 "https://pypi.org/pypi/ollama/json" | python3 -c "
import sys,json;d=json.load(sys.stdin)
desc=d['info']['description']
import re
i=desc.find('chat')
print(desc[:2500])" 2>&1 | head -80
