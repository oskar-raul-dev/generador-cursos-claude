#!/usr/bin/env python3
"""Reajusta la prosa de un .md del corpus a 100 columnas.

    python3 prompts/reflow.py fichero.md [...]        # reescribe en sitio
    python3 prompts/reflow.py --check fichero.md      # solo informa

Respeta intactos: bloques de codigo, tablas, encabezados, blockquotes de una
linea y cualquier linea que no se pueda partir (una URL larga, una salida).
La razon de existir: el techo de 200-350 lineas de la guia (§4.6) solo significa
lo mismo en todos los capitulos si todos van al mismo ancho. A 116 columnas, un
capitulo "de 350 lineas" tiene un 16 % mas de texto que otro a 100.
"""
import re, sys

ANCHO = 100

def envolver(texto, sangria_primera, sangria_resto):
    palabras = texto.split()
    if not palabras:
        return []
    lineas, actual, sangria = [], sangria_primera, sangria_primera
    for w in palabras:
        cand = w if not actual.strip() and actual == sangria else actual + ' ' + w
        if actual == sangria:
            cand = sangria + w
        if len(cand) <= ANCHO or actual == sangria:
            actual = cand
        else:
            lineas.append(actual)
            actual = sangria_resto + w
            sangria = sangria_resto
    lineas.append(actual)
    return lineas

def procesar(src):
    out, i, dentro = [], 0, False
    lineas = src.split('\n')
    while i < len(lineas):
        l = lineas[i]
        if l.startswith('```'):
            dentro = not dentro; out.append(l); i += 1; continue
        if dentro or not l.strip() or l.startswith('#') or l.lstrip().startswith('|') \
           or l.strip() in ('---', '***') or l.lstrip().startswith('!['):
            out.append(l); i += 1; continue

        # Un parrafo: lineas seguidas con el mismo caracter de arranque.
        m = re.match(r'^(\s*)([-*+] |\d+\. |> )?(.*)$', l)
        pre, marca, resto = m.group(1), m.group(2) or '', m.group(3)
        primera = pre + marca
        # La sangria de continuacion: bajo el texto en listas, con "> " en citas.
        sig = pre + ('> ' if marca == '> ' else ' ' * len(marca))
        cuerpo = [resto]
        j = i + 1
        while j < len(lineas):
            n = lineas[j]
            if not n.strip() or n.startswith('```') or n.startswith('#') \
               or n.lstrip().startswith('|') or n.strip() in ('---', '***'):
                break
            m2 = re.match(r'^(\s*)([-*+] |\d+\. |> )?(.*)$', n)
            if marca == '> ':
                if m2.group(2) != '> ': break
            elif m2.group(2):
                break
            cuerpo.append(m2.group(3)); j += 1
        out.extend(envolver(' '.join(cuerpo), primera, sig))
        i = j
    return '\n'.join(out)

if __name__ == '__main__':
    args = sys.argv[1:]
    check = '--check' in args
    for f in [a for a in args if a != '--check']:
        src = open(f).read()
        nuevo = procesar(src)
        antes, despues = src.count('\n') + 1, nuevo.count('\n') + 1
        estado = 'sin cambios' if src == nuevo else f'{antes} -> {despues} lineas'
        print(f'{f:<52} {estado}')
        if not check and src != nuevo:
            open(f, 'w').write(nuevo)
