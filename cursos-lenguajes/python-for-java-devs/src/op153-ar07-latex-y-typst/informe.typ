// Los datos llegan como JSON por sys.inputs: no se interpola texto, no hay nada que escapar.
#let rows = json(bytes(sys.inputs.at("rows")))
#set page(paper: "us-letter")
#set text(lang: "es")
= Relación de gastos de muestra · octubre de 2026
#table(
  columns: 3,
  [*Sede*], [*Concepto*], [*Valor*],
  ..rows.map(r => (r.sede, r.concepto, r.valor)).flatten()
)
