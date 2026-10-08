"""La cadena completa: en el CI y en la máquina, igual."""

import nox

nox.options.default_venv_backend = "uv"


@nox.session(python=["3.13", "3.14"])
def tests(session: nox.Session) -> None:
    session.install("-e", ".", "pytest")
    session.run("pytest", "-q")


@nox.session
def lint(session: nox.Session) -> None:
    session.install("ruff", "mypy", "bandit", "deptry", "pip-audit")
    session.run("ruff", "check", ".")
    session.run("mypy", "cartera/")
    session.run("deptry", ".")
    session.run("pip-audit")  # consulta una base externa: necesita red
