"""La calculadora de mora en Tkinter: la ventana, y una prueba que la opera sin manos."""

import tkinter as tk
from tkinter import ttk


def mora(saldo: int, dias: int) -> int:
    return round(saldo * 15 * dias / (1000 * 30))


class MoraWindow(ttk.Frame):
    def __init__(self, root: tk.Tk):
        super().__init__(root, padding=16)
        root.title("Mora de un paciente")
        self.saldo, self.dias, self.result = tk.StringVar(), tk.StringVar(), tk.StringVar(value="—")
        ttk.Label(self, text="Saldo en pesos").grid(row=0, column=0, sticky="w")
        ttk.Entry(self, textvariable=self.saldo).grid(row=0, column=1)
        ttk.Label(self, text="Días de mora").grid(row=1, column=0, sticky="w")
        ttk.Entry(self, textvariable=self.dias).grid(row=1, column=1)
        self.button = ttk.Button(self, text="Calcular", command=self.calculate)
        self.button.grid(row=2, column=0, columnspan=2, pady=8)
        ttk.Label(self, textvariable=self.result, font=("TkDefaultFont", 14)).grid(row=3, column=0, columnspan=2)
        self.grid()

    def calculate(self):
        try:
            value = mora(int(self.saldo.get()), int(self.dias.get()))
            self.result.set("$" + f"{value:,}".replace(",", "."))
        except ValueError:
            self.result.set("Escribe números enteros, sin puntos")


if __name__ == "__main__":
    root = tk.Tk()
    window = MoraWindow(root)
    for saldo, dias in [("1250000", "45"), ("1.250.000", "45")]:      # lo que escribiría Patricia
        window.saldo.set(saldo)
        window.dias.set(dias)
        window.button.invoke()
        root.update()
        print(f"{saldo:>10} · {dias} días → {window.result.get()}")
    print("Tk", root.tk.call("info", "patchlevel"))
    root.destroy()
