# rescatado de la sesión 2859734a, 2026-09-13T21:38:12Z · Check pinned polars, duckdb and pyarrow
cd /tmp && uv run --python 3.14 --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python -c "
import polars, duckdb, pyarrow
print('polars', polars.__version__, '· duckdb', duckdb.__version__, '· pyarrow', pyarrow.__version__)" 2>&1 | tail -3
