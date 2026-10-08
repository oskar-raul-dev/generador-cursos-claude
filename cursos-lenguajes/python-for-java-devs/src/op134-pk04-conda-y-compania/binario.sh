#!/bin/sh
# 1) pip contra GDAL en una máquina limpia
if command -v pip >/dev/null && ! command -v conda >/dev/null; then
  pip install --no-cache-dir gdal 2>&1 | grep -m1 "gdal-config" || echo "pip: instaló"
fi
# 2) conda (Miniforge) con GDAL desde conda-forge
if command -v conda >/dev/null; then
  conda --version
  start=$(date +%s)
  conda create --quiet --yes --name geo python=3.13 gdal >/dev/null
  echo "conda create con gdal: $(( $(date +%s) - start )) s"
  conda run --name geo python -c "from osgeo import gdal; print('GDAL', gdal.__version__)"
  echo "tamaño del entorno: $(du -sh /opt/conda/envs/geo | cut -f1)"
  echo "paquetes en el entorno: $(conda list --name geo | grep -vc '^#')"
fi
