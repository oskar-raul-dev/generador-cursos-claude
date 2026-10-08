set -euo pipefail
(cd aurea-cartera && uv build --quiet)
ls aurea-cartera/dist
python3 -m zipfile -l aurea-cartera/dist/aurea_cartera-1.2.0-py3-none-any.whl | awk 'NR>1 {print "  ", $1}'
unzip -p aurea-cartera/dist/aurea_cartera-1.2.0-py3-none-any.whl 'aurea_cartera-1.2.0.dist-info/entry_points.txt'

mkdir -p indice && pypi-server run -p 8151 -a . -P . indice >/dev/null 2>&1 &
sleep 2
twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/* >/dev/null && echo "publicado en el índice privado"
twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/*.whl 2>&1 | grep -m1 -oE "HTTPError: [0-9]+ [A-Za-z ]+" || true

python3 -m venv franquicia
franquicia/bin/pip install --quiet --index-url http://127.0.0.1:8151/simple/ aurea-cartera==1.2.0
franquicia/bin/aurea-mora 1250000 45
