# rescatado de la sesión bd47dbaf, 2026-09-13T18:17:49Z · Verify ia05 chunker parses the generated corpus
S=/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/bd47dbaf-516b-4200-8446-14e29aeb9c84/scratchpad/v/bin/python
echo "=== una pregunta de cada tipo ==="; head -6 /tmp/preguntas_anotadas.jsonl 2>/dev/null || head -6 /tmp/x_corpus/../preguntas_anotadas.jsonl
echo; echo "=== ¿el troceado de ia05 encuentra las cláusulas? ==="
cd ../ia05-normarag && $S -c "
import sys, json, pathlib
from ingest import chunk_text
total=0; docs=0; sin=0
for p in sorted(pathlib.Path('/tmp/x_corpus').glob('*.txt')):
    docs+=1
    chunks, reason = chunk_text(p.read_text(encoding='utf-8'), document_title=p.stem, document_version='x')
    if reason: sin+=1; print('  SIN ESTRUCTURA:', p.name, '->', reason)
    total+=len(chunks)
print(f'{docs} documentos -> {total} fragmentos, {sin} sin estructura')
c,_ = chunk_text(pathlib.Path(sorted(pathlib.Path('/tmp/x_corpus').glob('*.txt'))[0]).read_text(encoding='utf-8'), document_title='demo', document_version='2026')
print()
print('primer fragmento:'); print(repr(c[0].content[:160])); print('cláusula:', c[0].clause)
"
