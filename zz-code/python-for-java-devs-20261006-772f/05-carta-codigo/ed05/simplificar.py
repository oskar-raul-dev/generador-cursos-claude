"""Lo que una explicación simplificada cuenta y lo que pasa de verdad: pasos contados contra tiempo medido."""

import random
import timeit


def bubble(a):
    a, steps = list(a), 0
    for end in range(len(a) - 1, 0, -1):
        swapped = False
        for i in range(end):
            steps += 1
            if a[i] > a[i + 1]:
                a[i], a[i + 1], swapped = a[i + 1], a[i], True
        if not swapped:                               # la versión "buena" de burbuja: para si ya está ordenada
            break
    return a, steps


def insertion(a):
    a, steps = list(a), 0
    for k in range(1, len(a)):
        v, i = a[k], k - 1
        while i >= 0:
            steps += 1
            if a[i] <= v:
                break
            a[i + 1] = a[i]
            i -= 1
        a[i + 1] = v
    return a, steps


def merge(a):
    steps = 0

    def sort(xs):
        nonlocal steps
        if len(xs) <= 1:
            return xs
        left, right = sort(xs[: len(xs) // 2]), sort(xs[len(xs) // 2:])
        out, i, j = [], 0, 0
        while i < len(left) and j < len(right):
            steps += 1
            if left[i] <= right[j]:
                out.append(left[i]); i += 1
            else:
                out.append(right[j]); j += 1
        return out + left[i:] + right[j:]

    return sort(list(a)), steps


def builtin(a):
    return sorted(a), None                            # Timsort, en C: nadie cuenta sus pasos en la clase


random.seed(2)
cases = {}
for n in (30, 2000):
    shuffled = random.sample(range(n), n)
    nearly = sorted(shuffled)
    for _ in range(n // 50 + 1):                      # casi ordenada: unos pocos pares fuera de lugar
        i = random.randrange(n - 1)
        nearly[i], nearly[i + 1] = nearly[i + 1], nearly[i]
    cases[(n, "al azar")], cases[(n, "casi ordenada")] = shuffled, nearly

print(f"{'n':>5} {'lista':<14} {'algoritmo':<10} {'pasos':>9} {'tiempo':>12}")
for (n, kind), data in cases.items():
    for name, fn in (("burbuja", bubble), ("inserción", insertion), ("merge", merge), ("sorted()", builtin)):
        result, steps = fn(data)
        assert result == sorted(data)
        runs = 2000 if n == 30 else 3
        us = timeit.timeit(lambda: fn(data), number=runs) / runs * 1e6
        print(f"{n:>5} {kind:<14} {name:<10} {steps if steps is not None else '—':>9} {us:>10.1f} µs")
