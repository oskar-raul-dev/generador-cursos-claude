# rescatado de la sesión 2859734a, 2026-09-14T02:01:39Z · Check that the pinned torch installs and runs on CPU
cd /tmp && time uv run --python 3.14 --with 'torch==2.14.0' python -c "
import torch
print('torch', torch.__version__, '· hilos', torch.get_num_threads())
x = torch.randn(4, 5); print('ok', x.shape)" 2>&1 | tail -4
