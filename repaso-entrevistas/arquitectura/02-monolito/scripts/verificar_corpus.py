#!/usr/bin/env python3
"""Auditoría local reproducible; fuentes externas y semántica se revisan aparte."""
from pathlib import Path
from collections import Counter
import re
import os
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
ERRORS = []

def check(condition, message):
    if not condition:
        ERRORS.append(message)

def prose(text):
    """Excluir ejemplos de código de enlaces, títulos y numeración."""
    return re.sub(r'^```[^\n]*\n.*?^```\s*$', '', text, flags=re.M | re.S)

def anchors(text):
    result, counts = set(), Counter()
    for heading in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', prose(text), re.M):
        heading = re.sub(r'\[([^]]+)\]\([^)]+\)', r'\1', heading)
        # GitHub conserva el selector de variación U+FE0F de ⚠️, ⚙️…; \w no lo cubre.
        slug = re.sub(r'[^\w\- ️]', '', heading.lower()).replace(' ', '-')
        key = slug if counts[slug] == 0 else f'{slug}-{counts[slug]}'
        counts[slug] += 1
        result.add(key)
    return result

# Enlaces y fences se revisan en todo el corpus; el inventario, solo en la parte teórica.
# 06-talleres/ tiene su propio plan y plan-taller.md es un registro no normativo (prompt-base §1).
files = sorted(p for p in ROOT.rglob('*.md') if 'node_modules' not in p.parts)
contents = {p.resolve(): p.read_text(encoding='utf-8') for p in files}
theory = [p for p in files if '06-talleres' not in p.relative_to(ROOT).parts and p.name != 'plan-taller.md']
# 51 documentos: 33 capítulos, 5 simulaciones, 5 solucionarios, 6 README y 2 documentos de prompts/.
HAS_0106 = any(ROOT.glob('01-*/06-estilos-*.md'))
HAS_T11B = any(ROOT.glob('04-*/06-acoplamiento-asincrono-*.md')) and any(ROOT.glob('04-*/07-como-se-llega-*.md'))
EXPECTED = 48 + HAS_0106 + 2 * HAS_T11B
check(len(theory) == EXPECTED, f'Inventario teórico: {len(theory)} Markdown; se esperaban {EXPECTED}')
blocks = sorted(p for p in ROOT.iterdir() if p.is_dir() and re.match(r'^0[1-5]-', p.name))
check(len(blocks) == 5, 'Deben existir cinco bloques teóricos')
check(len([p for p in theory if p.name == 'README.md']) == 6, 'Deben existir seis README teóricos')
check(len(list((ROOT / 'prompts').glob('*.md'))) == 2, 'Deben existir dos documentos base')
link_count = 0
for p in files:
    text = prose(contents[p.resolve()])
    check(len(re.findall(r'^# ', text, re.M)) == 1, f'{p.name}: debe tener un H1')
    check(contents[p.resolve()].count('```') % 2 == 0, f'{p.name}: fence sin cierre')
    for target in re.findall(r'\]\(([^)]+)\)', text):
        target = target.strip('<>')
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc:
            continue
        link_count += 1
        dest = (p.parent / unquote(parsed.path)).resolve() if parsed.path else p.resolve()
        check(dest.is_file(), f'{p.relative_to(ROOT)}: enlace inexistente {target}')
        if parsed.fragment and dest in contents:
            check(unquote(parsed.fragment) in anchors(contents[dest]),
                  f'{p.relative_to(ROOT)}: ancla inexistente {target}')
    if p.parent.name != 'prompts':
        check(not re.search(r'Repaso_Arquitectura_Hexagonal|adaptadores-de-entrada|nucleo-aplicacion-y-dominio', text),
              f'{p.name}: nombre heredado')

route = [p for b in blocks for p in sorted(b.glob('[0-9][0-9]-*.md'))]
for i, p in enumerate(route):
    text = p.read_text()
    check('[Índice del bloque](README.md)' in text and '[Índice general](../README.md)' in text,
          f'{p.name}: faltan índices de navegación')
    for label, neighbor in [('Anterior', i - 1), ('Siguiente', i + 1)]:
        if 0 <= neighbor < len(route):
            expected_target = os.path.relpath(route[neighbor], p.parent)
            check(re.search(r'\*\*' + label + r':\*\* \[[^\n]+\]\(' + re.escape(expected_target) + r'\)', text) is not None,
                  f'{p.name}: navegación {label} incorrecta')

chapter_total = simulation_total = scenario_total = 0
mandatory = []
expected_owner = {1:1, 2:2, 3:2, 4:3, 5:3, 6:4, 7:4, 8:4, 9:4, 10:5}
SIZES = [5 + HAS_0106, 6, 7, 6 + 2 * HAS_T11B, 6]
for bi, (b, size) in enumerate(zip(blocks, SIZES), 1):
    chapters = sorted(p for p in b.glob('[0-9][0-9]-*.md') if 'respuestas' not in p.name and 'simulacion' not in p.name)
    sims = list(b.glob('*-simulacion-de-entrevista.md'))
    sols = list(b.glob('*-respuestas.md'))
    check(len(chapters) == size and len(sims) == len(sols) == 1, f'{b.name}: inventario incorrecto')
    if not sims or not sols:
        continue
    expected = []
    for ci, p in enumerate(chapters, 1):
        text = p.read_text()
        qs = re.findall(r'^\d+\. [🟢🟡🟠] .+$', text, re.M)
        check(24 <= len(qs) <= 26, f'{p.name}: {len(qs)} preguntas')
        check([int(q.split('.')[0]) for q in qs] == list(range(1, len(qs) + 1)), f'{p.name}: numeración')
        check(int(p.name[:2]) == ci, f'{p.name}: orden de capítulo')
        for section in ['Preguntas', 'Errores frecuentes', 'Referencias']:
            check(section in text, f'{p.name}: falta {section}')
        expected.extend(qs)
    chapter_total += len(expected)
    simtext = sims[0].read_text()
    sq = re.findall(r'^S\d+\. [🟢🟡🟠] .+$', simtext, re.M)
    check(30 <= len(sq) <= 45, f'{sims[0].name}: {len(sq)} preguntas')
    check([int(q.split('.')[0][1:]) for q in sq] == list(range(1, len(sq) + 1)), f'{sims[0].name}: numeración S')
    check('Las que descolocan' in simtext, f'{sims[0].name}: falta ronda especial')
    scenarios = re.findall(r'^### E\d+ — .*?(?=^### |^## |\Z)', simtext, re.M | re.S)
    check(4 <= len(scenarios) <= 6, f'{sims[0].name}: escenarios {len(scenarios)}')
    for scenario in scenarios:
        for field in ['Evidencia disponible', 'Supuestos faltantes', 'Unidad de cambio', 'Garantía prioritaria', 'Trade-off', 'Primera acción reversible', 'Prioridad senior']:
            check(field in scenario, f'{sims[0].name}: falta {field} en escenario')
    for m in re.findall(r'Escenario obligatorio (\d+):', simtext):
        mandatory.append(int(m))
        check(expected_owner.get(int(m)) == bi, f'Escenario {m}: bloque dueño incorrecto')
    simulation_total += len(sq)
    scenario_total += len(scenarios)
    answers = re.findall(r'^### ((?:S)?\d+\. [🟢🟡🟠] [^\n]+)\n(.*?)(?=^### |\Z)', sols[0].read_text(), re.M | re.S)
    check([q for q, _ in answers] == expected + sq, f'{sols[0]}: enunciados diferentes o fuera de orden')
    for q, answer in answers:
        for layer in ['⏱️', '🗣️', '🔬']:
            check(answer.count(layer) == 1, f'{sols[0].name}: capa {layer} en {q}')
    print(f'{bi:02}: {len(chapters)} capítulos, {len(expected)} preguntas + {len(sq)} simulación, {len(scenarios)} escenarios')
check(Counter(mandatory) == Counter(range(1, 11)), 'Los diez escenarios obligatorios deben aparecer exactamente una vez')

# Bloque 06 · Talleres (T23): diez talleres, 10–15 preguntas y 6–8 ejercicios graduados (más 🔥 fuera
# del conteo), copiados literalmente a 11-respuestas.md con las tres capas (guía §11.3 y §8).
def one_line(item):
    return ' '.join(line.strip() for line in item.strip().splitlines())

WORKSHOPS = ROOT / '06-talleres'
workshop_answers = 0
if WORKSHOPS.is_dir():
    labs = sorted(p for p in WORKSHOPS.glob('[0-9][0-9]-*.md') if 'respuestas' not in p.name)
    check(len(labs) == 10, f'06-talleres: {len(labs)} talleres; se esperaban 10')
    solution = (WORKSHOPS / '11-respuestas.md').read_text()
    items = re.findall(r'^\*\*(\d\d → E?\d+)\.\*\* ([^\n]+)\n(.*?)(?=^\*\*\d\d → |^## |\Z)', solution, re.M | re.S)
    entries = {key: statement for key, statement, _ in items}
    bodies = {key: body for key, _, body in items}
    for p in labs:
        nn, text = p.name[:2], p.read_text()
        check('**opcional**' in text.split('\n## ')[0], f'{p.name}: el primer párrafo debe declararlo opcional')
        check('## 🧹 Teardown' in text or '🧹' in text, f'{p.name}: falta teardown')
        qs_sec = text.split('## 🧠 Preguntas', 1)[1].split('## 🧪 Ejercicios', 1)[0] if '## 🧠 Preguntas' in text else ''
        ex_sec = text.split('## 🧪 Ejercicios', 1)[1].split('\n---', 1)[0] if '## 🧪 Ejercicios' in text else ''
        qs = re.findall(r'^(\d+)\. (.+?)(?=\n\d+\. |\n*\Z)', qs_sec.strip(), re.M | re.S)
        ex = re.findall(r'^(\d+)\. (.+?)(?=\n\d+\. |\n*\Z)', ex_sec.strip(), re.M | re.S)
        graded = [e for _, e in ex if not e.startswith('🔥')]
        check(10 <= len(qs) <= 15, f'{p.name}: {len(qs)} preguntas (10–15)')
        check(6 <= len(graded) <= 8, f'{p.name}: {len(graded)} ejercicios graduados (6–8)')
        check(any('Orientación en código ajeno' in e for _, e in ex), f'{p.name}: falta un ejercicio de orientación en código ajeno')
        for n, q in qs:
            key = f'{nn} → {n}'
            check(entries.get(key) == one_line(q), f'11-respuestas.md: enunciado distinto o ausente en {key}')
            check(all(bodies.get(key, '').count(layer) == 1 for layer in ['⏱️', '🗣️', '🔬']), f'11-respuestas.md: capas en {key}')
        for n, e in ex:
            key = f'{nn} → E{n}'
            check(entries.get(key) == one_line(e), f'11-respuestas.md: enunciado distinto o ausente en {key}')
            check(all(bodies.get(key, '').count(layer) == 1 for layer in ['⏱️', '🗣️', '🔬']), f'11-respuestas.md: capas en {key}')
        workshop_answers += len(qs) + len(ex)
    check(len(bodies) == workshop_answers, f'11-respuestas.md: {len(bodies)} respuestas para {workshop_answers} enunciados')
    print(f'06: {len(labs)} talleres, {workshop_answers} preguntas y ejercicios con respuesta en tres capas')
check(chapter_total >= 24 * sum(SIZES) and chapter_total <= 26 * sum(SIZES), 'Total de preguntas de capítulo fuera de rango')
check(150 <= simulation_total <= 225 and scenario_total == 25, 'Totales de simulación o escenarios diferentes del contrato')
print(f'Total: {sum(SIZES)} capítulos, {chapter_total} preguntas de capítulo, {simulation_total} de simulación')
if ERRORS:
    print('\n'.join('ERROR: ' + error for error in ERRORS), file=sys.stderr)
    sys.exit(1)
print(f'OK: {len(theory)} documentos teóricos ({len(files)} en total), {chapter_total + simulation_total} respuestas en tres capas, '
      f'{workshop_answers} de talleres, {link_count} enlaces locales, 10 escenarios obligatorios únicos.')
