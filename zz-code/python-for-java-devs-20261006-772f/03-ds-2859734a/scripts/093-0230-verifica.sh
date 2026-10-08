# rescatado de la sesión 2859734a, 2026-09-14T02:30:25Z · Smoke-test both backends
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'onnxruntime==1.30.0' --with httpx2 python -c "
import os; os.environ['AUREA_BACKEND']='onnx'
from fastapi.testclient import TestClient
import serve
c=TestClient(serve.app)
print(c.get('/salud').json())
print(c.post('/riesgo', json={'inasistencias_previas':2,'jueves_tarde':1,'lluvia_mm':12.0,'distancia_km':18.0,'dias_desde_agendamiento':30}).json())" 2>&1 | tail -4
echo "--- y con pickle ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with httpx2 python -c "
import os; os.environ['AUREA_BACKEND']='pickle'
from fastapi.testclient import TestClient
import serve
c=TestClient(serve.app)
print(c.post('/riesgo', json={'inasistencias_previas':2,'jueves_tarde':1,'lluvia_mm':12.0,'distancia_km':18.0,'dias_desde_agendamiento':30}).json())" 2>&1 | tail -2
