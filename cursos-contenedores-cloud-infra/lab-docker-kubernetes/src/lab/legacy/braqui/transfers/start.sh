#!/bin/sh
# El cron de busybox no hereda el entorno del contenedor: las variables van en la línea del crontab.
mkdir -p /var/lib/braqui
echo "${TRANSFER_CRON:-*/5 * * * *} DATABASE_URL='${DATABASE_URL}' TRANSFER_DIR='${TRANSFER_DIR}' /app/.venv/bin/python /app/process_transfers.py >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "aviso de traslados programado: ${TRANSFER_CRON:-*/5 * * * *}"
exec crond -f -l 8
