# rescatado de la sesión 2859734a, 2026-09-14T02:02:06Z · Diagnose the OpenMP conflict
cd /tmp
echo "--- solo torch, de nuevo ---"; uv run --python 3.14 --with 'torch==2.14.0' python -c "import torch; print('ok', torch.__version__)" 2>&1 | tail -2
echo "--- torch + sklearn ---"; uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2
echo "--- con KMP_DUPLICATE_LIB_OK ---"; KMP_DUPLICATE_LIB_OK=TRUE uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2
