from pathlib import Path
from bench import measure, render

PATH = Path("data/citas-2026-Q1.csv")

def eager(path):
    """Lo que escribe alguien que viene de Java: la lista completa, y después se filtra."""
    with path.open(encoding="utf-8") as f:
        lines = f.readlines()[1:]
    rows = [line.rstrip("\n").split(",") for line in lines]
    no_shows = [r for r in rows if r[4] == "no_show"]
    by_branch = {}
    for r in no_shows:
        by_branch[r[1]] = by_branch.get(r[1], 0) + 1
    return by_branch

def lazy(path):
    """La tubería perezosa: nada se materializa salvo el resultado."""
    with path.open(encoding="utf-8") as f:
        next(f)
        rows = (line.rstrip("\n").split(",") for line in f)
        no_shows = (r for r in rows if r[4] == "no_show")
        by_branch = {}
        for r in no_shows:
            by_branch[r[1]] = by_branch.get(r[1], 0) + 1
    return by_branch

assert eager(PATH) == lazy(PATH)
print(render([
    measure("lista intermedia", lambda: eager(PATH)),
    measure("tubería perezosa", lambda: lazy(PATH)),
]))
