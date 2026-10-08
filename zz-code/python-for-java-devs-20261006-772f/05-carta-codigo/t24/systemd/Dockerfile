# Python 3.14.7 con systemd como PID 1, para probar las unidades de au06 y sy06 (T24, 07/10/2026)
FROM python:3.14.7
LABEL curso=python-for-java-devs
RUN apt-get update && apt-get install -y --no-install-recommends systemd systemd-sysv dbus \
    && rm -rf /var/lib/apt/lists/* && pip install --no-cache-dir --root-user-action=ignore uv==0.12.23 \
    && cp "$(command -v uv)" /usr/local/bin/uv 2>/dev/null || true \
    && useradd -m -s /bin/bash aurea
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
