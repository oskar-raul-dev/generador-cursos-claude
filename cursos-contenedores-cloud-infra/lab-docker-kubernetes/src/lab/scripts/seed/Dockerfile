# El seed del laboratorio como imagen (Fase 12), para correrlo como Job: el mismo generate.py de a01,
# y load.py, que lo carga por la API de los servicios.
# python:3.14.8-alpine
FROM python@sha256:8acac70227ce3b34da9453120c375cc5b66cd0b062d4dc6bc74286f81a3819e1
WORKDIR /app
COPY requirements.txt ./
RUN python -m venv .venv && .venv/bin/pip install --quiet --disable-pip-version-check -r requirements.txt
COPY generate.py load.py ./
USER nobody
# La semilla fija de generate.py: los mismos datos en cada corrida y en cada máquina.
CMD ["sh", "-c", ".venv/bin/python generate.py --stores ${STORES:-20} | .venv/bin/python load.py"]
