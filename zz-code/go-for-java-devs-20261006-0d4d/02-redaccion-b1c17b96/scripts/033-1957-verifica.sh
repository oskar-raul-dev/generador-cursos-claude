# rescatado de la sesión b1c17b96, 2026-09-12T19:57:27Z · Check track B and search for architecture patterns coverage
cd /Users/oskar/Developer/Learning/courses-ia-generated
echo "═══ track_b ═══"; ls maestria-ia/track_b/ && wc -l maestria-ia/track_b/*.md 2>/dev/null | tail -2
echo; echo "═══ react-16 track BE (Go) ═══"; wc -l react-16-legacy-for-backend-devs/be*.md react-16-legacy-for-backend-devs/bea*.md 2>/dev/null | tail -2
echo; echo "═══ ¿existe algo de patrones/DDD/microservicios en el repo? ═══"
grep -ril 'hexagonal\|bounded context\|microservices.io\|Gang of Four\|patrones GoF' --include='*.md' . 2>/dev/null | grep -v 'go-for-java-devs\|propuesta-java' | head -10
echo "(vacío = no existe)"
