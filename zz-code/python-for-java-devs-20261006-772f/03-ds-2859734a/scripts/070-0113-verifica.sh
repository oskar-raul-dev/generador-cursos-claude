# rescatado de la sesión 2859734a, 2026-09-14T01:13:00Z · Find where the kernelspec actually comes from
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
echo "=== ¿de dónde sale el kernelspec? ==="
timeout 120 uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python -c "
from jupyter_client.kernelspec import KernelSpecManager
import sys
ks = KernelSpecManager()
print('dirs:', ks.kernel_dirs)
print('encontrados:', list(ks.find_kernel_specs()))
print('sys.prefix:', sys.prefix)"
echo "=== solo papermill + ipykernel (sin jupyterlab) ==="
timeout 120 uv run --python 3.14 --with 'papermill==2.7.0' --with ipykernel python -c "
from jupyter_client.kernelspec import KernelSpecManager
print('encontrados:', list(KernelSpecManager().find_kernel_specs()))"
