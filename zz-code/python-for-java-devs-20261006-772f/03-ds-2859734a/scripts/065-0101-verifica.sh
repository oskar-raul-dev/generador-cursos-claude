# rescatado de la sesión 2859734a, 2026-09-14T01:01:44Z · Verify the pinned visualization and notebook stacks install
cd /tmp && uv run --python 3.14 --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -c "
import matplotlib, plotly, altair
print('matplotlib', matplotlib.__version__, '· plotly', plotly.__version__, '· altair', altair.__version__)" 2>&1 | tail -3
echo "--- cuadernos ---"
uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python -c "
import papermill, nbformat, nbclient
print('papermill', papermill.__version__, '· nbformat', nbformat.__version__, '· nbclient', nbclient.__version__)" 2>&1 | tail -3
