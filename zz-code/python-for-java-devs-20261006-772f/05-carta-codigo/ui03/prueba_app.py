"""Simula a Patricia: elige una sede y marca tres veces. Cuenta cuántas veces corrió cada carga."""

from streamlit.testing.v1 import AppTest

import contador

app = AppTest.from_file("cartera_app.py").run()
app.selectbox[0].select("Suba").run()
for _ in range(3):
    app.button[0].click().run()

print("métrica:", app.metric[0].value)
print(app.markdown[-1].value)
print("cargas:", contador.calls)
