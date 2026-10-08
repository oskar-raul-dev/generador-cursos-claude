# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
# ---

# %%
price = 100_000
rate = 0.19

# %%
total = price * (1 + rate)
total

# %%
rate = 0.16   # la tarifa nueva, que el autor probó y después borró del texto

# %%
print(f'El total con IVA es {total:,.0f}')

# %%
discount
