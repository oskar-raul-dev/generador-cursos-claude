# rescatado de la sesión c9051874, 2026-09-13T20:08:23Z · Locate the remaining pending items
echo "=== F06 heap ==="; sed -n '2193,2200p' 06-concurrencia.md
echo "=== F05 negociacion ==="; grep -n "negociación de contenido\|Negociación de contenido" 05-http-rest-stdlib.md 13-lotes-scheduling-y-asincronia.md
echo "=== F03 errWriter ==="; grep -n "errWriter" 03-errores-paquetes-io.md 13-lotes-scheduling-y-asincronia.md
echo "=== F12 metricas ==="; grep -n "Fase 14" 12-cache-con-valkey.md | tail -5
echo "=== F13 ResponseController ==="; grep -n "ResponseController" 13-lotes-scheduling-y-asincronia.md 14-observabilidad-y-hardening.md
echo "=== JSONB ==="; grep -n "JSONB" 09-sql-postgres-sqlite.md 11-mongodb-y-modelado-documental.md | head
