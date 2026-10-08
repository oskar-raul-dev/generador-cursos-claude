# rescatado de la sesión 5c52573d, 2026-10-05T17:45:55Z · Inspect Gradio API endpoint names
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python -c "
from gradio_client import Client
c=Client(\"http://127.0.0.1:7860/\",verbose=False)
print(c.view_api(print_info=False, return_format=\"dict\"))"; pip show gradio-client | grep Version' 2>&1 | tail -4
