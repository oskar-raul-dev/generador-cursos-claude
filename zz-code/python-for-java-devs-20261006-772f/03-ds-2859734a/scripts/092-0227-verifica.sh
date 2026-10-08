# rescatado de la sesión 2859734a, 2026-09-14T02:27:53Z · Check the ONNX and FastAPI stacks
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'onnx==1.22.0' python -c "
import onnx, onnxruntime, skl2onnx, sklearn
print('onnx', onnx.__version__, '· onnxruntime', onnxruntime.__version__, '· skl2onnx', skl2onnx.__version__, '· sklearn', sklearn.__version__)" 2>&1 | tail -3
echo "--- fastapi ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' python -c "
import fastapi, uvicorn; print('fastapi', fastapi.__version__, '· uvicorn', uvicorn.__version__)" 2>&1 | tail -2
