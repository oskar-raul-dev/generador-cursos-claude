# 🪟 ui09 — Escritorio

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 9 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Este perfil viene de un mundo donde el escritorio fue serio: Swing, JavaFX, Eclipse RCP. Odontovía, el sistema de gestión
que Áurea usa desde 2014, es un cliente de escritorio en Java Swing instalado debajo del mesón de cada sede. Es natural
preguntarse si la herramienta de Patricia debería ser una aplicación de escritorio en Python.

Esta sección responde la pregunta con honestidad, y la respuesta corta es: **casi nunca**. Python tiene buenas bibliotecas
de escritorio —Qt con PySide6, Tkinter en la biblioteca estándar, Toga, Kivy, pywebview—, y el problema no está en ellas.
Está en todo lo que viene después de escribir la ventana: empaquetar un intérprete de Python con sus dependencias para
cada sistema operativo, firmarlo para que Windows y macOS no lo bloqueen, distribuirlo a diez sedes y actualizarlo. Una
página web interna no tiene ninguno de esos problemas.

---

## 🧠 2. El modelo

| Biblioteca | Qué es | Lo que pesa | Para qué |
|---|---|---|---|
| Tkinter (biblioteca estándar) | Tk, el *toolkit* clásico | Nada que instalar (casi siempre) | Una ventana de utilidad, una herramienta del ingeniero |
| PySide6 6.11.2 | Qt 6, oficial de The Qt Company, LGPL | Cientos de MB instalado | Aplicaciones de escritorio de verdad |
| Toga (BeeWare) | Controles nativos de cada sistema | Mediano | Aplicaciones que se ven nativas, y móviles con Briefcase |
| Kivy | Su propio dibujo con OpenGL | Mediano | Interfaces táctiles, kioscos |
| pywebview | Una ventana con un navegador adentro | Liviano | Envolver una aplicación web local en una ventana |
| Flet (`ui05`) | Flutter desde Python | El cliente se descarga | Escritorio, web y móvil con el mismo código |

Y lo que cuesta después de escribirla, que es lo que decide:

| Paso | Una página web interna | Una aplicación de escritorio en Python |
|---|---|---|
| Empaquetar | Nada | PyInstaller, Briefcase o Nuitka, por sistema operativo |
| Firmar | El certificado del servidor | Un certificado de firma de código para Windows y otro para macOS (pagos) |
| Distribuir | Un enlace | Un instalador en cada computador de cada sede |
| Actualizar | Desplegar una vez | Que cada computador se actualice, o visitar cada uno |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, el escritorio se distribuía con el JRE instalado una vez y un `.jar`, o con Java Web Start, y el instinto supone
que Python tiene un equivalente. No lo tiene: no hay un "Python instalado en las sedes" en el que confiar, así que cada
aplicación lleva su intérprete adentro. Es la razón por la que Odontovía, en Java, sigue funcionando debajo del mesón, y
por la que su reemplazo, si algún día existe, no va a ser de escritorio en Python.

---

## 💻 3. El ejemplo que corre

La calculadora de mora de `ui02`, en Tkinter, sin dependencias. La prueba la opera desde código, sin que nadie haga clic.

`mora_tk.py`:

```python
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
```

```bash
python3 mora_tk.py          # en un servidor sin pantalla: xvfb-run -a python3 mora_tk.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
   1250000 · 45 días → $28.125
 1.250.000 · 45 días → Escribe números enteros, sin puntos
Tk 8.6.16
```

Cuarenta líneas, ninguna dependencia, y la prueba opera la ventana con `invoke()` como lo haría una persona. La segunda fila
es la que Patricia escribiría: con puntos de miles, como en todos sus Excel. La ventana lo rechaza con un mensaje en vez de
un error, que es lo mínimo; lo correcto sería aceptarlo.

Y ahora la parte que no está en el ejemplo: para que esta ventana llegue al computador de Patricia, hay que empaquetarla con
su intérprete (`pyinstaller --onefile mora_tk.py` produce un ejecutable de decenas de MB solo para Windows, si se corre en
Windows), firmarla para que Windows no la marque como sospechosa, y repetir en cada sede cuando cambie la tasa.

**Detalles con intención**

- **`ttk`** son los controles "temáticos" de Tk, que se ven razonablemente nativos en Windows y macOS. Los de `tk` a secas se
  ven de los noventa.
- **`button.invoke()` y `root.update()`** permiten probar una interfaz de Tkinter sin interacción humana. En un servidor sin
  pantalla, la prueba corre con una pantalla virtual (`xvfb-run`); PySide6 tiene además una plataforma `offscreen`.
- **La lógica (`mora`) está fuera de la ventana**: se prueba sin Tkinter, y es la misma de `ui02`. La ventana es una
  envoltura, como debería serlo cualquier interfaz.

---

## ⚠️ 4. Lo que se rompe

**Tkinter que no está.** Viene con Python en Windows y macOS, pero en muchas distribuciones de Linux es un paquete aparte
(`python3-tk`), y en las imágenes mínimas de contenedor no está. `import tkinter` falla en el computador del único usuario
que tiene Linux.

**El antivirus contra PyInstaller.** Los ejecutables de PyInstaller sin firmar se parecen, para muchos antivirus, a lo que
hace el *malware* empaquetado con PyInstaller. El reporte de "falso positivo" llega desde una sede un lunes.

**La licencia de Qt.** PySide6 es LGPL; PyQt6 es GPL o comercial. Para una herramienta interna da igual; para algo que se
distribuya a terceros —un franquiciado es un tercero— hay que leer qué obliga cada una.

**La actualización.** Una aplicación de escritorio vieja en una sede calcula con la tasa vieja. Sin un mecanismo de
actualización automática, el número de versiones en uso crece con el número de sedes.

---

## ⚖️ 5. Cuándo SÍ usarlo

La sección invierte la pregunta, porque el caso habitual es no usarlo. El escritorio en Python se justifica cuando:

- **El programa necesita el hardware local**: un lector de código de barras, una impresora térmica de recibos, un equipo de
  radiografía digital con su SDK. Una página web no llega ahí sin un agente local.
- **Tiene que funcionar sin red**, de verdad y con frecuencia.
- **Es una herramienta del propio ingeniero**, que corre en su máquina con su Python. Ahí Tkinter es perfecto y no hay nada
  que distribuir.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `mora_tk.py` con la ventana visible (quita el bucle de prueba y agrega `root.mainloop()`). **Criterio:** la usas a
   mano y funciona.
2. Haz que la calculadora acepte `1.250.000` quitando los puntos. **Criterio:** la segunda fila da `$28.125`.
3. Comprueba si tu Python tiene Tkinter (`python -m tkinter`). **Criterio:** reportas la versión de Tk o el error.

**🟡 Intermedio (4–6)**

4. Escribe la misma ventana con PySide6 y pruébala con `QT_QPA_PLATFORM=offscreen`. **Criterio:** la prueba corre sin
   pantalla y verifica el resultado.
5. Empaqueta la versión Tkinter con PyInstaller en tu sistema. **Criterio:** el tamaño del ejecutable, y si tu antivirus o tu
   sistema lo bloquea al abrirlo.
6. Envuelve la aplicación de Gradio de `ui02` en una ventana con pywebview. **Criterio:** se abre como aplicación sin
   navegador visible.

**🟠 Difícil (7–9)**

7. Haz la versión con Toga y empaquétala con Briefcase. **Criterio:** el instalador de tu sistema y su tamaño.
8. Diseña el mecanismo de actualización: la aplicación consulta una URL con la versión vigente y avisa si está vieja.
   **Criterio:** una versión vieja muestra el aviso al abrir.
9. Escribe un agente local mínimo que lea una impresora o un lector (simulado) y lo exponga a una página web local.
   **Criterio:** la página web recibe el código leído.

**🔴 Muy difícil (10)**

10. Decide si la herramienta de liquidación de franquicias debería ser de escritorio o web. **Criterio:** una página. *Rúbrica:*
    (a) qué necesita del computador local, si algo; (b) el costo de empaquetar, firmar y actualizar en diez sedes; (c) qué
    pasa sin red; (d) la decisión y la señal que la cambiaría.

---

## 📚 7. Referencias

**Documentación oficial**

- `tkinter`: https://docs.python.org/3/library/tkinter.html
- Qt for Python (PySide6): https://doc.qt.io/qtforpython-6/
- BeeWare (Toga y Briefcase): https://beeware.org/
- PyInstaller: https://pyinstaller.org/en/stable/
- pywebview: https://pywebview.flowrl.com/

**Orden de lectura sugerido:** la sección de empaquetado de la documentación de PyInstaller, antes de escribir una sola
ventana: es la que decide si vale la pena.

---

## 🚀 8. Cierre

Python tiene buenas bibliotecas de escritorio, y el costo no está en escribir la ventana sino en empaquetar el intérprete,
firmar, distribuir y actualizar en cada computador. Para las herramientas de Áurea, una página web interna gana casi
siempre; el escritorio se justifica con hardware local, sin red, o para la herramienta del propio ingeniero.

**La señal de que quedó bien:** *"Alguien propuso hacer la herramienta de Patricia de escritorio, y la tabla de pasos
después de escribirla cerró la discusión."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-09 -m "op ui09 cerrada: el escritorio en Python y lo que cuesta después de la ventana"
> ```
>
> Los commits llevan su prefijo (`op ui09: …`) y los de ejercicio su número
> (`op ui09 ej07: …`).
