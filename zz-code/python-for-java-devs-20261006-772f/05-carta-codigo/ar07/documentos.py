"""El mismo informe con Typst (en el proceso) y con LaTeX (el binario), y el carácter que rompe la plantilla."""

import json
import os
import subprocess
import tempfile
import time

import typst

ROWS = [{"sede": "Kennedy", "concepto": "Arriendo de octubre", "valor": "4.200.000"},
        {"sede": "Engativá", "concepto": "Aseo & mantenimiento", "valor": "1.150.000"},
        {"sede": "Fontibón", "concepto": "Anticipo del 50% · cuenta #12_3", "valor": "780.000"}]

LATEX = r"""\documentclass{article}
\usepackage[T1]{fontenc}
\begin{document}
\section*{Relación de gastos de muestra · octubre de 2026}
\begin{tabular}{lll}
Sede & Concepto & Valor \\ \hline
%s
\end{tabular}
\end{document}
"""


def latex_pdf(rows, escape):
    def clean(text):
        if not escape:
            return text
        for char, repl in (("\\", r"\textbackslash{}"), ("&", r"\&"), ("%", r"\%"), ("$", r"\$"), ("#", r"\#"), ("_", r"\_"),
                           ("{", r"\{"), ("}", r"\}"), ("~", r"\textasciitilde{}"), ("^", r"\textasciicircum{}")):
            text = text.replace(char, repl)
        return text
    body = "\n".join(" & ".join(clean(r[k]) for k in ("sede", "concepto", "valor")) + r" \\" for r in rows)
    with tempfile.TemporaryDirectory() as tmp:
        with open(f"{tmp}/informe.tex", "w", encoding="utf-8") as f:
            f.write(LATEX % body)
        run = subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "informe.tex"], cwd=tmp,
                             capture_output=True, text=True)
        error = next((l for l in run.stdout.splitlines() if l.startswith("!")), None)
        return (os.path.getsize(f"{tmp}/informe.pdf") if run.returncode == 0 else None), error


start = time.perf_counter()
pdf = typst.compile("informe.typ", sys_inputs={"rows": json.dumps(ROWS)})
print(f"Typst (en el proceso)       {(time.perf_counter() - start) * 1000:6.0f} ms · {len(pdf):,} bytes")

start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=False)
print(f"LaTeX sin escapar           {(time.perf_counter() - start) * 1000:6.0f} ms · falla: {error}")
start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=True)
print(f"LaTeX escapando             {(time.perf_counter() - start) * 1000:6.0f} ms · {size:,} bytes")
