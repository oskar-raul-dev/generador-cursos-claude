"""La calculadora de mora de Patricia, en Gradio: la pantalla y su API, que son lo mismo."""

import gradio as gr


def mora(saldo: float, dias: float) -> str:
    """Interés de mora simple al 1,5 % mensual, redondeado al peso."""
    valor = round(int(saldo) * 15 * int(dias) / (1000 * 30))
    return "$" + f"{valor:,}".replace(",", ".")


demo = gr.Interface(
    fn=mora,
    inputs=[gr.Number(label="Saldo en pesos", precision=0), gr.Number(label="Días de mora", precision=0)],
    outputs=gr.Textbox(label="Mora"),
    title="Mora de un paciente",
    flagging_mode="never",
)

if __name__ == "__main__":
    demo.launch()
