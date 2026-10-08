# rescatado de la sesión 5c52573d, 2026-10-05T21:49:05Z · Find English comments inside carta code blocks
import re, pathlib
EN = re.compile(r"\b(the|over|arrives|through|nothing|exponential|smoothing|returns|with|from|this|should|keep|data|value|values|file|set|use|first|only|for|and|not)\b", re.I)
ES = re.compile(r"[áéíóúñ¿¡]|\b(el|la|los|las|de|que|con|sin|para|una|un|por|se|del|al|es|no|cada|lo)\b", re.I)
for p in sorted(pathlib.Path(".").glob("op*.md")):
    inside = False
    for n, line in enumerate(p.read_text().splitlines(), 1):
        if line.startswith("```"):
            inside = not inside if line.strip() == "```" or not inside else inside
            if line.strip() != "```" and not inside: inside = True
            continue
        if not inside: continue
        m = re.search(r"(?:^\s*(?://|/\*|#(?!!)|--)\s*|\s(?://|#)\s+)(.+)$", line)
        if not m: continue
        text = m.group(1)
        if re.match(r"^(include|define|cython|pragma|noqa|type:|/ script|\s*$)", text): continue
        if EN.search(text) and not ES.search(text):
            print(f"{p.name}:{n}: {line.strip()[:110]}")
