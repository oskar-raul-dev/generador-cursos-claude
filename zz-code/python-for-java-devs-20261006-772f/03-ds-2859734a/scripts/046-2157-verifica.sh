# rescatado de la sesión 2859734a, 2026-09-13T21:57:14Z · Pinpoint when DuckDB loads pandas
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' --with 'pandas==3.0.5' python -c "
import sys, duckdb
print('tras import  ->  pandas:', 'pandas' in sys.modules)
c = duckdb.connect()
print('tras connect ->  pandas:', 'pandas' in sys.modules)
c.execute('select 42').fetchall()
print('tras execute ->  pandas:', 'pandas' in sys.modules)
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
consolidate_duckdb_parquet(Path('data/mes/parquet'))
print('tras consulta->  pandas:', 'pandas' in sys.modules, '· pyarrow:', 'pyarrow' in sys.modules)"
