FROM lab/replenish
CMD node dist/main.js || echo "replenish terminó con error"
