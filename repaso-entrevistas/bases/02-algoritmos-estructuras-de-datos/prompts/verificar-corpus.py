#!/usr/bin/env python3
"""Verificador del corpus 02-algoritmos-estructuras-de-datos (§12.4 de la guía).

Uso, desde la raíz del corpus:
    python3 prompts/verificar-corpus.py                  # todo el corpus
    python3 prompts/verificar-corpus.py 12-dp-clasica    # solo un bloque
    python3 prompts/verificar-corpus.py prompts          # solo los documentos de preparación

Errores (salida con código 1):
  - enlace interno a un archivo que no existe, o a un ancla que no existe
  - enlace relativo que sale del corpus (§1.2 de la guía)
  - emoji en un encabezado ###
  - capítulo sin una sección obligatoria de §6.1
  - capítulo con distinto número de preguntas, o de problemas, que su solucionario
  - ruta del README con un capítulo que no existe, con un "asume leído" fuera de la ruta
    (salvo en las rutas cortas), o con geometría en una ruta básica (§13); mientras el README
    diga «en producción», un capítulo con ficha en el prompt-base.md que aún no existe es aviso

Avisos (a revisar a mano):
  - capítulo fuera de la banda de líneas o de preguntas; problemas propios fuera de 2–4
  - encabezado sin "Lectura troncal" o sin "Vigencia"
  - capítulo de técnica sin teoría o sin señales del enunciado
  - problema propio sin pista 1
  - callout fuera de la lista de §10.3
  - solucionario que falta, con entradas pendientes o con una respuesta sin sus tres capas
  - capítulo de una ruta corta sin "Ruta corta: sí"
  - capítulos de las rutas aún sin escribir, en un solo aviso (README en producción)
"""
import os
import re
import sys
import unicodedata

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOQUE_RE = re.compile(r'^\d{2}-')
CAPITULO_RE = re.compile(r'^(\d{2})-.*\.md$')
CALLOUTS = {'⚠️', '🧠', '💡', '🩺', '⏱️', '📝', '📚'}
OBLIGATORIAS = ['🎯 El problema', '⚠️ Errores frecuentes', '📚 Para profundizar', '🧠 Preguntas',
                '🧩 Problemas propios', '🧩 Práctica externa', '✅ Criterio de dominio']
SIN_TEORIA = {'01', '03'}                      # bloques de oficio y de lenguaje (§6.1)
SIN_TEORIA_CAP = {'20/04'}
RUTAS_CORTAS = {'Entrevistas', 'Prueba técnica esta semana', 'Programar en vivo'}
RUTAS_BASICAS = RUTAS_CORTAS | {'Algoritmos básicos', 'Desde cero'}
CAPAS = ('⏱️', '🗣️', '🔬')

errores, avisos = [], []


def rel(ruta):
    return os.path.relpath(ruta, RAIZ)


def leer(ruta):
    return open(ruta, encoding='utf-8').read()


def sin_bloques(texto):
    """Quita los bloques ``` por líneas (no por pares de ```), conservando los saltos de línea."""
    salida, dentro = [], False
    for linea in texto.split('\n'):
        if re.match(r'^\s*```', linea):
            dentro = not dentro
            salida.append('')
        else:
            salida.append('' if dentro else linea)
    return '\n'.join(salida)


def sin_codigo(texto):
    return re.sub(r'`[^`\n]*`', '', sin_bloques(texto))


def slug(encabezado):
    """Ancla de GitHub: minúsculas y fuera todo lo que no sea `\\p{Word}` (letra, marca, dígito decimal,
    conector), espacio o guion. Por eso los superíndices (`10⁸`, `n²`) se borran y el U+FE0F de ⚠️ o
    ⏱️, que es una marca, se queda: `## 5. ⏱️ X` → `#5-️-x`."""
    texto = encabezado.strip().lower()
    texto = ''.join(c for c in texto if c in ' -' or unicodedata.category(c)[0] in 'LM'
                    or unicodedata.category(c) in ('Nd', 'Pc'))
    return texto.replace(' ', '-')


_anclas = {}


def anclas(ruta):
    if ruta not in _anclas:
        vistas, conjunto = {}, set()
        for h in re.findall(r'^#{1,6} (.+)$', sin_bloques(leer(ruta)), re.M):
            base = slug(h)
            n = vistas.get(base, 0)
            conjunto.add(base if n == 0 else f'{base}-{n}')
            vistas[base] = n + 1
        _anclas[ruta] = conjunto
    return _anclas[ruta]


def es_emoji(c):
    cp = ord(c)
    return unicodedata.category(c) == 'So' or 0x1F000 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF


def archivos(alcance):
    for base, dirs, nombres in os.walk(alcance):
        dirs[:] = sorted(d for d in dirs if not d.startswith('.'))
        for n in sorted(nombres):
            if n.endswith('.md'):
                yield os.path.join(base, n)


def verificar_enlaces(ruta):
    for destino in re.findall(r'\]\(([^)\s]+)\)', sin_codigo(leer(ruta))):
        if re.match(r'^[a-z]+:', destino):
            continue
        camino, _, ancla = destino.partition('#')
        objetivo = os.path.normpath(os.path.join(os.path.dirname(ruta), camino)) if camino else ruta
        if os.path.commonpath([RAIZ, objetivo]) != RAIZ:
            errores.append(f'FUERA   {rel(ruta)} → {destino}')
        elif not os.path.exists(objetivo):
            errores.append(f'ROTO    {rel(ruta)} → {destino}')
        elif ancla and objetivo.endswith('.md') and ancla not in anclas(objetivo):
            errores.append(f'ANCLA   {rel(ruta)} → {destino}')


def secciones(texto):
    """Diccionario encabezado ## → cuerpo, sin los bloques de código."""
    partes, actual = {}, None
    for linea in sin_bloques(texto).split('\n'):
        if linea.startswith('## '):
            actual = linea[3:].strip()
            partes[actual] = []
        elif actual is not None:
            partes[actual].append(linea)
    return {k: '\n'.join(v) for k, v in partes.items()}


def seccion(partes, titulo):
    """Cuerpo de la sección cuyo encabezado termina en `titulo` (con o sin número delante)."""
    for k, v in partes.items():
        if re.sub(r'^\d+\.\s*', '', k) == titulo:
            return v
    return None


def es_capitulo(nombre):
    # Por el nombre exacto, no por subcadena: «01-ad-hoc-y-simulacion.md» (20/01) es un capítulo.
    return (CAPITULO_RE.match(nombre) and not re.match(r'^\d{2}-(simulacion|respuestas|pistas)\.md$', nombre)
            and 'simulacro' not in nombre and 'cuaderno' not in nombre)


def encabezado(texto):
    lineas = []
    for linea in texto.split('\n')[1:]:
        if linea.startswith('## ') or linea.strip() == '---':
            break
        if linea.startswith('>'):
            lineas.append(linea)
    return '\n'.join(lineas)


def solo_fichas_c(texto):
    """Verdadero si todas las etiquetas de «Niveles» son C; el campo puede ocupar varias líneas."""
    niveles = re.search(r'Niveles:\**(.*?)(?:\n>\s*\n|\n>\s*\*\*|\Z)', encabezado(texto), re.S)
    etiquetas = set(re.findall(r'\[([ABC/]+)', niveles.group(1))) if niveles else set()
    return bool(etiquetas) and etiquetas <= {'C'}


def verificar_capitulo(ruta, num_bloque, pistas, preguntas_sol, con_problemas):
    nombre = os.path.basename(ruta)
    codigo = f'{num_bloque}/{nombre[:2]}'
    texto = leer(ruta)
    limpio = sin_codigo(texto)
    partes = secciones(texto)

    for h in re.findall(r'^### (.+)$', limpio, re.M):
        if any(es_emoji(c) for c in h):
            errores.append(f'EMOJI   {rel(ruta)}: ### {h}')
    for c in re.findall(r'^> (\S+) \*\*', limpio, re.M):
        if c not in CALLOUTS and any(es_emoji(x) for x in c):
            avisos.append(f'CALLOUT {rel(ruta)}: {c} no está en §10.3')

    cabecera = encabezado(texto)
    for campo in ('Lectura troncal', 'Vigencia'):
        if campo not in cabecera:
            avisos.append(f'CABECERA {rel(ruta)}: sin «{campo}»')

    obligatorias = OBLIGATORIAS if con_problemas else [s for s in OBLIGATORIAS if '🧩' not in s
                                                        and '✅' not in s]
    for titulo in obligatorias:
        if seccion(partes, titulo) is None:
            errores.append(f'SECCIÓN {rel(ruta)}: falta «## {titulo}»')
    if con_problemas and num_bloque not in SIN_TEORIA and codigo not in SIN_TEORIA_CAP:
        for titulo in ('📐 La teoría', '🔎 Señales del enunciado'):
            if seccion(partes, titulo) is None:
                avisos.append(f'TEORÍA  {rel(ruta)}: falta «## N. {titulo}»')

    lineas = texto.count('\n')
    banda = (150, 300) if solo_fichas_c(texto) else (300, 600)
    if lineas > 700:
        avisos.append(f'PARTIR  {rel(ruta)}: {lineas} líneas (más de 700: se parte)')
    elif not banda[0] <= lineas <= banda[1]:
        avisos.append(f'LARGO   {rel(ruta)}: {lineas} líneas (banda {banda[0]}–{banda[1]})')

    cuerpo_preg = seccion(partes, '🧠 Preguntas') or ''
    n_preg = len(re.findall(r'^\d+\. ', cuerpo_preg, re.M))
    if not 10 <= n_preg <= 15:
        avisos.append(f'BANDA   {rel(ruta)}: {n_preg} preguntas (banda 10–15)')
    if preguntas_sol is not None and preguntas_sol.get(nombre[:2], 0) != n_preg:
        errores.append(f'SINCRO  {rel(ruta)}: {n_preg} preguntas, '
                       f'{preguntas_sol.get(nombre[:2], 0)} en el solucionario')

    if not con_problemas:
        return
    propios = re.split(r'^### ', seccion(partes, '🧩 Problemas propios') or '', flags=re.M)[1:]
    if not 2 <= len(propios) <= 4:
        avisos.append(f'PROPIOS {rel(ruta)}: {len(propios)} problemas propios (banda 2–4)')
    for p in propios:
        if 'Pista 1' not in p:
            avisos.append(f'PISTA   {rel(ruta)}: «{p.splitlines()[0].strip()}» sin pista 1')
    externos = len(re.findall(r'^\| \[[ x~]\] \|', seccion(partes, '🧩 Práctica externa') or '',
                              re.M))
    if pistas is not None and pistas.get(nombre[:2], 0) != len(propios) + externos:
        errores.append(f'PISTAS  {rel(ruta)}: {len(propios)} propios + {externos} externos, '
                       f'{pistas.get(nombre[:2], 0)} con pistas en el solucionario')


def leer_solucionario(dir_bloque):
    nombres = [n for n in os.listdir(dir_bloque) if n.endswith('-respuestas.md')]
    if not nombres:
        return None, None
    ruta = os.path.join(dir_bloque, nombres[0])
    texto = leer(ruta)
    preguntas, pistas = {}, {}
    for cap in re.findall(r'^\*\*(\d{2}) → \d+\.', texto, re.M):
        preguntas[cap] = preguntas.get(cap, 0) + 1
    for cap in re.findall(r'^\*\*(\d{2}) → Problema:', texto, re.M):
        pistas[cap] = pistas.get(cap, 0) + 1
    # Una entrada sin redactar se marca con una línea que solo dice «pendiente» (con o sin *, _, (), [] o
    # punto) o con «pendiente de redactar/escribir/completar». «La pendiente de una recta» no cuenta.
    marca = re.compile(r'^\s*[*_(\[]*pendiente[*_)\].]*\s*$|\bpendiente de (redactar|escribir|completar)\b',
                       re.I | re.M)
    if marca.search(texto):
        avisos.append(f'PENDIENTE {rel(ruta)} tiene entradas pendientes')
    trozos = re.split(r'^(?=\*\*\d{2} → \d+\.)', texto, flags=re.M)[1:]
    for trozo in trozos:
        cabeza = trozo.split('\n', 1)[0][:60]
        cuerpo = re.split(r'^(?=\*\*\d{2} → |# )', trozo[1:], maxsplit=1, flags=re.M)[0]
        if not all(c in cuerpo for c in CAPAS):
            avisos.append(f'CAPAS   {rel(ruta)}: «{cabeza}» sin las tres capas')
    return preguntas, pistas


def verificar_bloque(dir_bloque):
    nombre_bloque = os.path.basename(dir_bloque)
    num = nombre_bloque[:2]
    if num in ('21', '23'):
        return                                     # simulacros y cuaderno: §7.5 y §7.7
    preguntas, pistas = leer_solucionario(dir_bloque)
    capitulos = [n for n in sorted(os.listdir(dir_bloque)) if es_capitulo(n)]
    if capitulos and preguntas is None:
        avisos.append(f'SIN-SOL {nombre_bloque}: no hay solucionario')
    for n in capitulos:
        verificar_capitulo(os.path.join(dir_bloque, n), num, pistas, preguntas,
                           con_problemas=(num != '22'))


def codigo_de(ruta):
    bloque, nombre = os.path.basename(os.path.dirname(ruta)), os.path.basename(ruta)
    if BLOQUE_RE.match(bloque) and CAPITULO_RE.match(nombre):
        return f'{bloque[:2]}/{nombre[:2]}'
    return None


def capitulos_por_codigo():
    tabla = {}
    for ruta in archivos(RAIZ):
        codigo = codigo_de(ruta)
        if codigo and es_capitulo(os.path.basename(ruta)):
            tabla[codigo] = ruta
    return tabla


def asume_leido(ruta):
    """Códigos NN/MM enlazados desde la línea «Asume leído» del encabezado."""
    codigos = set()
    for linea in encabezado(leer(ruta)).split('\n'):
        if 'Asume leído' not in linea:
            continue
        for destino in re.findall(r'\]\(([^)#\s]+)', linea):
            objetivo = os.path.normpath(os.path.join(os.path.dirname(ruta), destino))
            codigo = codigo_de(objetivo)
            if codigo:
                codigos.add(codigo)
    return codigos


def codigos_de_linea(linea):
    """Los códigos NN/MM de una línea, expandiendo los rangos `NN/AA`–`NN/BB`."""
    codigos = []
    for a, b, c in re.findall(r'(\d{2})/(\d{2})`?\s*–\s*`?\1/(\d{2})', linea):
        codigos += [f'{a}/{m:02d}' for m in range(int(b), int(c) + 1)]
    return codigos + re.findall(r'\b(\d{2}/\d{2})\b', linea)


def inventario():
    """Los códigos NN/MM con ficha en el prompt-base.md (vacío si no está)."""
    ruta = os.path.join(RAIZ, 'prompts', 'prompt-base.md')
    if not os.path.exists(ruta):
        return set()
    return set(re.findall(r'^## `(\d{2}/\d{2})` — ', leer(ruta), re.M))


def verificar_rutas():
    readme = os.path.join(RAIZ, 'README.md')
    if not os.path.exists(readme):
        return
    tabla = capitulos_por_codigo()
    # Mientras el README diga «en producción», un capítulo con ficha que aún no existe es pendiente
    en_produccion = re.search(r'en producción', leer(readme), re.I) is not None
    fichas = inventario() if en_produccion else set()
    pendientes = set()
    rutas, actual = {}, None
    for linea in sin_bloques(leer(readme)).split('\n'):
        if linea.startswith('#'):
            actual = linea[len('### Ruta'):].strip() if linea.startswith('### Ruta') else None
            if actual:
                rutas[actual] = []
        elif actual:
            rutas[actual] += codigos_de_linea(linea)
    for nombre, codigos in rutas.items():
        for codigo in dict.fromkeys(codigos):
            if codigo not in tabla:
                if codigo in fichas:
                    pendientes.add(codigo)
                else:
                    errores.append(f'RUTA    «{nombre}»: {codigo} no existe')
                continue
            if nombre in RUTAS_BASICAS and codigo.startswith('18/'):
                errores.append(f'RUTA    «{nombre}»: {codigo} es geometría y la ruta es básica')
            if nombre in RUTAS_CORTAS:
                if 'Ruta corta: sí' not in encabezado(leer(tabla[codigo])).replace('*', ''):
                    avisos.append(f'RUTA    «{nombre}»: {codigo} sin «Ruta corta: sí»')
            else:
                for previo in asume_leido(tabla[codigo]) - set(codigos):
                    errores.append(f'RUTA    «{nombre}»: {codigo} asume leído {previo}, '
                                   f'que no está en la ruta')
    if pendientes:
        avisos.append(f'RUTA    {len(pendientes)} capítulos de las rutas aún sin escribir '
                      f'(README en producción)')


def main():
    alcance = os.path.join(RAIZ, sys.argv[1]) if len(sys.argv) > 1 else RAIZ
    if not os.path.isdir(alcance):
        sys.exit(f'No existe: {alcance}')
    for ruta in archivos(alcance):
        verificar_enlaces(ruta)
    if alcance == RAIZ:
        dirs = [os.path.join(RAIZ, d) for d in sorted(os.listdir(RAIZ))
                if BLOQUE_RE.match(d) and os.path.isdir(os.path.join(RAIZ, d))]
    else:
        dirs = [alcance] if BLOQUE_RE.match(os.path.basename(alcance)) else []
    for d in dirs:
        verificar_bloque(d)
    if alcance == RAIZ:
        verificar_rutas()
    for linea in errores:
        print('ERROR', linea)
    for linea in avisos:
        print('aviso', linea)
    print(f'— {len(errores)} errores, {len(avisos)} avisos')
    sys.exit(1 if errores else 0)


if __name__ == '__main__':
    main()
