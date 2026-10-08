# python:3.14.8-alpine
FROM python@sha256:8acac70227ce3b34da9453120c375cc5b66cd0b062d4dc6bc74286f81a3819e1
# tzdata: sin ella, busybox ignora TZ y el cron corre en UTC.
RUN apk add --no-cache tzdata
WORKDIR /app
COPY requirements.txt ./
RUN python -m venv .venv && .venv/bin/pip install --quiet --disable-pip-version-check -r requirements.txt
COPY process_transfers.py start.sh ./
# cron de busybox: el script corre cada cinco minutos, como en el servidor de la Braqui.
CMD ["sh", "start.sh"]
