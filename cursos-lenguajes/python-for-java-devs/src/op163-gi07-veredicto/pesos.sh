# Cuánto pesa instalar cada pila, en un directorio vacío por pila
for stack in "numpy==2.5.3" "pyproj==3.8.0 shapely==2.1.2" "geopandas==1.2.0 pyogrio==0.13.0" "duckdb==1.5.6"; do
  dir=$(mktemp -d)
  pip install -q --root-user-action=ignore --target "$dir" $stack >/dev/null 2>&1
  printf "%-36s %5s MB\n" "$stack" "$(du -sm "$dir" | cut -f1)"
done
