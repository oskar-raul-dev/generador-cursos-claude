"""El tablero de cartera de Patricia, con los dos errores del modelo de re-ejecución a la vista."""

import streamlit as st

import contador

DATA = {"Centro": 187_450_000, "Suba": 142_900_000, "Kennedy": 98_300_000}


def load_uncached() -> dict:
    contador.calls["sin caché"] += 1          # en la vida real: una consulta de cinco segundos
    return dict(DATA)


@st.cache_data
def load_cached() -> dict:
    contador.calls["con caché"] += 1
    return dict(DATA)


data = load_uncached()
load_cached()

st.title("Cartera por sede")
sede = st.selectbox("Sede", list(data))
st.metric("Facturado", "$" + f"{data[sede]:,}".replace(",", "."))

reviewed = 0                                   # el instinto de Java
if st.button("Marcar como revisada"):
    reviewed += 1
    st.session_state.reviewed = st.session_state.get("reviewed", 0) + 1
st.write(f"revisadas (variable): {reviewed} · revisadas (session_state): {st.session_state.get('reviewed', 0)}")
