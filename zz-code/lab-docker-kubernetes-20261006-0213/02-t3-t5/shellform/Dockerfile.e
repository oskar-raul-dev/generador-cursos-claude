FROM lab/inventory
COPY start-exec.sh ./start.sh
CMD ["sh", "start.sh"]
