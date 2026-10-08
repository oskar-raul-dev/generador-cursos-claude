# rescatado de la sesión bd47dbaf, 2026-09-13T05:33:35Z · Query PyPI for current versions of IA/DS packages
for p in anthropic ollama numpy pandas polars scikit-learn torch matplotlib plotly altair jupyterlab marimo papermill duckdb pyarrow sentence-transformers qdrant-client pgvector rank-bm25 pypdf onnx onnxruntime skl2onnx tenacity great-tables statsmodels seaborn; do
  v=$(curl -s --max-time 12 "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json;d=json.load(sys.stdin);i=d['info'];print(i['version'], d['urls'][0]['upload_time'][:10] if d.get('urls') else '?')" 2>/dev/null)
  printf '%-24s %s\n' "$p" "${v:-NO_DATA}"
done
