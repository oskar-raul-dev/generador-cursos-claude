# rescatado de la sesión bd47dbaf, 2026-09-13T18:43:39Z · Check framework versions on PyPI
for p in langchain langchain-anthropic llama-index pydantic-ai instructor litellm; do
  v=$(curl -s --max-time 12 "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json;d=json.load(sys.stdin);i=d['info'];print(i['version'], d['urls'][0]['upload_time'][:10] if d.get('urls') else '?')" 2>/dev/null)
  printf '%-22s %s\n' "$p" "${v:-NO_DATA}"
done
