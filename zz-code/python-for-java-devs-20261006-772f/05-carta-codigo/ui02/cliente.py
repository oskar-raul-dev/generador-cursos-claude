"""La misma aplicación, usada desde un script: Gradio publica la API sin que nadie lo pida."""

import sys

from gradio_client import Client

client = Client(sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:7860/", verbose=False)
print(client.view_api(print_info=False, return_format="dict")["named_endpoints"].keys())
for saldo, dias in [(1_250_000, 45), (3_400_000, 120)]:
    print(f"saldo {saldo:>9,} · {dias:>3} días → {client.predict(saldo, dias, api_name='/mora')}")
