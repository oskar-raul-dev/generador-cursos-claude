set -euo pipefail
.venv/bin/pip-compile --quiet --strip-extras --generate-hashes --output-file requirements.txt requirements.in
echo "paquetes fijados: $(grep -c '==' requirements.txt) · hashes: $(grep -c -- '--hash=' requirements.txt)"
grep -E '^[a-z].*==' requirements.txt | cut -d' ' -f1

python3 -m venv limpio
limpio/bin/pip install --quiet --require-hashes -r requirements.txt && echo "instalación verificada: OK"

# Alguien (o algo) altera los hashes: lo que se descarga ya no coincide con ninguno.
sed -i 's/--hash=sha256:[0-9a-f]\{4\}/--hash=sha256:0000/g' requirements.txt
python3 -m venv limpio2
limpio2/bin/pip install --quiet --require-hashes -r requirements.txt 2>&1 | grep -m1 -E 'THESE PACKAGES DO NOT MATCH|ERROR' || true
