#!/usr/bin/env python3
"""Verifica contra PyPI el inventario de bibliotecas de la carta (propuestas-temas-opcionales.md §20.3).

Para cada paquete consulta https://pypi.org/pypi/<paquete>/json y anota la última versión, la fecha
de su publicación y si está quieto (más de dos años sin publicar). Escribe el resultado en
`prompts/inventario-verificado.md`, que es la fuente de las versiones que citan las secciones.

Uso, desde la raíz del curso:
    python3 prompts/check-inventario.py            # todo el inventario
    python3 prompts/check-inventario.py db se      # solo esos tracks

Sin dependencias: solo la biblioteca estándar. Hace una petición por paquete con una pausa corta,
porque PyPI responde 429 si se le consulta seguido.
"""

import datetime as dt
import json
import pathlib
import sys
import time
import urllib.error
import urllib.request

# Los paquetes que nombra cada track, con su nombre en PyPI (no el de importación).
INVENTARIO: dict[str, list[str]] = {
    "lg": ["lxml", "xmlsec", "signxml", "pyhanko", "cryptography", "pyx12", "hl7apy", "hl7",
           "fhir.resources", "charset-normalizer", "chardet", "ftfy", "cerberus", "pydantic",
           "defusedxml", "ebcdic", "xsdata", "python-pkcs11", "pydifact", "bots"],
    "au": ["httpx", "httpx2", "requests", "selectolax", "beautifulsoup4", "scrapy", "playwright",
           "paramiko", "fabric", "authlib", "PyGithub", "jira", "slack-sdk",
           "google-api-python-client", "tenacity", "stamina"],
    "co": ["yagmail", "aiosmtpd", "paramiko", "imap-tools", "premailer", "python-telegram-bot", "pyftpdlib", "pyOpenSSL",
           "twilio", "slack-sdk", "dnspython", "dkimpy", "checkdmarc"],
    "wf": ["celery", "rq", "dramatiq", "arq", "huey", "APScheduler", "schedule", "pytz", "apache-airflow",
           "prefect", "dagster", "kedro", "luigi", "temporalio", "taskiq", "procrastinate",
           "flower"],
    "qa": ["pytest", "pytest-xdist", "pytest-cov", "pytest-randomly", "respx", "responses",
           "freezegun", "time-machine", "factory-boy", "polyfactory", "Faker", "testcontainers",
           "hypothesis", "mutmut", "cosmic-ray", "locust", "pytest-benchmark", "ruff", "mypy",
           "pyright", "pre-commit", "bandit", "pip-audit", "deptry", "vulture", "tox", "nox",
           "pytest-playwright", "coverage", "syrupy", "holidays", "pytest-timeout"],
    "ob": ["structlog", "loguru", "rich", "prometheus-client", "opentelemetry-api",
           "opentelemetry-sdk", "opentelemetry-instrumentation", "opentelemetry-exporter-otlp",
           "py-spy", "memray", "scalene", "yappi", "objgraph", "sentry-sdk", "psutil",
           "pyinstrument"],
    "se": ["cryptography", "PyNaCl", "argon2-cffi", "bcrypt", "passlib", "pyjwt", "python-jose",
           "joserfc", "authlib", "hvac", "keyring", "certifi", "bandit", "pip-audit",
           "detect-secrets", "itsdangerous", "truststore", "PyYAML", "Jinja2", "pydantic-settings",
           "httpx"],
    "tx": ["Jinja2", "Mako", "Chameleon", "chevron", "Pygments", "rich", "tree-sitter",
           "tree-sitter-python", "markdown-it-py", "mistune", "Markdown", "docutils", "Sphinx",
           "mkdocs", "mkdocs-material", "pdoc", "griffe", "cookiecutter", "copier", "Faker",
           "regex", "Babel", "Unidecode", "ftfy", "htpy", "dominate", "libcst", "PyICU", "Django",
           "nh3", "mdit-py-plugins", "mkdocstrings"],
    "ui": ["gradio", "streamlit", "dash", "plotly", "nicegui", "reflex", "shiny", "panel",
           "flet", "marimo", "python-pptx", "WeasyPrint", "XlsxWriter", "great-tables",
           "PySide6", "toga", "kivy", "pywebview", "voila", "mesop", "taipy", "solara",
           "python-fasthtml", "python-multipart", "fastapi", "uvicorn", "click", "typer", "cyclopts", "fire", "textual", "prompt-toolkit",
           "questionary", "tqdm", "blessed", "colorama", "humanize", "tabulate", "shtab",
           "platformdirs", "dynaconf", "pydantic-settings", "trogon", "docopt-ng", "docopt",
           "justpy", "openpyxl", "pyinstaller", "briefcase", "pytest-textual-snapshot"],
    "db": ["psycopg", "mysqlclient", "PyMySQL", "asyncmy", "pyodbc", "pymssql", "oracledb",
           "duckdb", "redis", "valkey", "pymongo", "beanie", "cassandra-driver", "scylla-driver",
           "neo4j", "py2neo", "influxdb-client", "influxdb3-python", "pgvector", "qdrant-client",
           "opensearch-py", "meilisearch", "typesense", "boto3", "fsspec", "s3fs",
           "confluent-kafka", "nats-py", "minio"],
    "jv": ["fastavro", "avro", "protobuf", "pyarrow", "JPype1", "py4j", "graalpy",
           "jmxquery"],
    "so": ["ortools", "PuLP", "highspy", "mip", "Pyomo", "cvxpy", "simpy", "salabim", "scipy",
           "networkx", "deap", "optuna", "mesa"],
    "or": ["SQLAlchemy", "Django", "peewee", "pony", "tortoise-orm", "piccolo", "sqlmodel",
           "ormar", "PyPika", "aiosql", "records", "dataset", "masonite-orm", "sqlglot",
           "yoyo-migrations", "alembic", "pugsql", "aiosqlite", "asyncpg", "greenlet"],
    "vz": ["matplotlib", "seaborn", "plotnine", "altair", "plotly", "bokeh", "holoviews",
           "hvplot", "great-tables", "graphviz", "networkx", "drawsvg", "pycairo", "manim",
           "diagrams", "datashader", "pydeck", "folium", "svg.py", "svgwrite", "vl-convert-python", "pandas",
           "polars", "colorspacious"],
    "sy": ["plumbum", "sh", "invoke", "psutil", "watchdog", "filelock", "pexpect",
           "python-daemon", "systemd-python", "supervisor", "sdnotify"],
    "pr": ["grpcio", "grpcio-tools", "betterproto", "protobuf", "fastavro", "msgspec", "msgpack",
           "cbor2", "orjson", "strawberry-graphql", "ariadne", "graphene", "websockets",
           "sse-starlette", "paho-mqtt", "pika", "aio-pika", "nats-py", "schemathesis",
           "pact-python", "datamodel-code-generator", "jsonschema", "PyYAML"],
    "pk": ["pip", "pip-tools", "uv", "poetry", "pdm", "hatch", "build", "twine", "pipx",
           "pyinstaller", "Nuitka", "shiv", "pex", "conda-lock", "pypiserver", "hatchling", "check-wheel-contents"],
    "ff": ["cffi", "Cython", "numba", "maturin", "pybind11", "nanobind", "mypy", "Nuitka",
           "setuptools", "scikit-build-core", "cibuildwheel", "pyarrow", "numpy"],
    "ar": ["Pillow", "opencv-python", "scikit-image", "drawsvg", "pycairo", "pypdf",
           "pdfplumber", "PyMuPDF", "reportlab", "pyhanko", "pytesseract", "ocrmypdf",
           "python-docx", "openpyxl", "python-pptx", "XlsxWriter", "pypandoc", "typst",
           "EbookLib", "av", "moviepy", "imageio", "imageio-ffmpeg", "vidgear", "pydub",
           "librosa", "mutagen", "soundfile", "pedalboard", "ffmpeg-python", "decord",
           "opencv-python-headless", "docxtpl", "audioop-lts", "markdown-it-py"],
    "gi": ["shapely", "geopandas", "pyproj", "fiona", "pyogrio", "rasterio", "xarray",
           "rioxarray", "osmnx", "geopy", "folium", "h3", "s2sphere", "pydeck", "contextily",
           "GeoAlchemy2", "keplergl", "psycopg", "duckdb", "numpy", "networkx", "pandas",
           "matplotlib", "geodatasets"],
    "cv": ["opencv-python", "mediapipe", "insightface", "rembg", "scikit-image", "dlib",
           "deepface", "ultralytics", "face-alignment", "onnxruntime", "face_recognition",
           "opencv-python-headless", "opencv-contrib-python-headless", "numpy", "scipy", "Pillow"],
    "ed": ["pygame", "pygame-ce", "arcade", "pyglet", "ipywidgets", "jupyterlab", "marimo", "manim",
           "matplotlib", "nbformat", "nbclient", "ipykernel", "jupytext", "numpy", "networkx", "pytest",
           "Pillow", "pycairo", "ManimPango"],
}

QUIETO = dt.timedelta(days=730)
SALIDA = pathlib.Path(__file__).with_name("inventario-verificado.md")


def consultar(paquete: str) -> tuple[str, str] | None:
    """Última versión estable y fecha de su primer archivo publicado, o None si no existe."""
    url = f"https://pypi.org/pypi/{paquete}/json"
    for intento in range(3):
        try:
            with urllib.request.urlopen(url, timeout=20) as respuesta:
                datos = json.load(respuesta)
            break
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if error.code == 429 and intento < 2:
                time.sleep(5 * (intento + 1))
                continue
            raise
    version = datos["info"]["version"]
    archivos = datos["releases"].get(version) or []
    fecha = min((a["upload_time"] for a in archivos), default="")[:10]
    return version, fecha


def main(tracks: list[str]) -> int:
    hoy = dt.date.today()
    elegidos = tracks or list(INVENTARIO)
    # Las secciones de los tracks que no se piden se conservan tal cual, con su fecha.
    secciones: dict[str, str] = {}
    if SALIDA.exists():
        for bloque in SALIDA.read_text(encoding="utf-8").split("\n## `")[1:]:
            secciones[bloque.split("`", 1)[0]] = "## `" + bloque.rstrip() + "\n"
    cache: dict[str, tuple[str, str] | None] = {}
    for track in elegidos:
        lineas = [f"## `{track}`", "", f"Verificado el {hoy.isoformat()}.", "",
                  "| Paquete | Versión | Publicada | |", "|---|---|---|---|"]
        for paquete in INVENTARIO[track]:
            if paquete not in cache:
                cache[paquete] = consultar(paquete)
                time.sleep(0.3)
            dato = cache[paquete]
            if dato is None:
                lineas.append(f"| `{paquete}` | — | — | ❌ |")
                continue
            version, fecha = dato
            quieto = fecha and hoy - dt.date.fromisoformat(fecha) > QUIETO
            lineas.append(f"| `{paquete}` | {version} | {fecha} | {'💤' if quieto else ''} |")
        secciones[track] = "\n".join(lineas) + "\n"
    cabecera = [
        "# 📋 Inventario verificado contra PyPI",
        "",
        "> Generado por `check-inventario.py`. No se edita a mano: se regenera, entero o por track.",
        "> Cada track lleva la fecha de su última verificación. Las secciones de la carta citan de",
        "> aquí la versión que nombran.",
        "> 💤 = más de dos años sin publicar; ❌ = no existe en PyPI con ese nombre.",
        "",
    ]
    orden = [t for t in INVENTARIO if t in secciones]
    SALIDA.write_text("\n".join(cabecera) + "\n".join(secciones[t] for t in orden), encoding="utf-8")
    print(f"escrito {SALIDA.name}: {len(cache)} paquetes consultados, {len(orden)} tracks")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
