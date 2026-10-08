"""turtle: una espiral, un árbol recursivo y lo que cuesta animar. La biblioteca estándar, sin instalar nada."""

import sys
import time
import turtle


def spiral(t, steps):
    for i in range(steps):
        t.forward(i * 2)
        t.left(91)                                    # 91 y no 90: el grado de más es lo que hace la espiral


def tree(t, length, depth):
    """Cada rama dibuja dos ramas más chicas: la recursión se ve crecer en la pantalla."""
    if depth == 0:
        return 0
    t.forward(length)
    t.left(30)
    drawn = tree(t, length * 0.7, depth - 1)
    t.right(60)
    drawn += tree(t, length * 0.7, depth - 1)
    t.left(30)
    t.backward(length)                                # volver al punto de partida es parte del contrato
    return drawn + 1


screen = turtle.Screen()
screen.setup(800, 800)
t = turtle.Turtle()
t.hideturtle()

# 1. La misma espiral con la animación por defecto y con la pantalla en pausa (tracer(0))
for label, tracer, speed in (("animada, velocidad normal", 1, 6), ("animada, velocidad 0", 1, 0), ("tracer(0) + update()", 0, 0)):
    t.clear(); t.penup(); t.home(); t.pendown()
    screen.tracer(tracer)
    t.speed(speed)
    start = time.perf_counter()
    spiral(t, 120)
    screen.update()
    print(f"espiral de 120 tramos, {label:<26} {time.perf_counter() - start:6.2f} s")

# 2. El árbol: cuántas ramas por profundidad, y el contrato de volver al inicio
screen.tracer(0)
for depth in (4, 8, 10):
    t.clear(); t.penup(); t.goto(0, -300); t.setheading(90); t.pendown()
    start = time.perf_counter()
    branches = tree(t, 160, depth)
    screen.update()
    exact = t.position() == (0, -300)
    print(f"árbol de profundidad {depth:>2}: {branches:>5} ramas (2^{depth} − 1 = {2 ** depth - 1:>5}) · "
          f"{time.perf_counter() - start:5.2f} s · ¿volvió? con == {exact}, a {t.distance(0, -300):.1e} del inicio")

screen.getcanvas().postscript(file="arbol.eps")       # lo que se dibujó, sin captura de pantalla
print("recursión máxima de Python:", sys.getrecursionlimit(), "· el árbol de profundidad 10 usa 10 niveles")
screen.bye()
