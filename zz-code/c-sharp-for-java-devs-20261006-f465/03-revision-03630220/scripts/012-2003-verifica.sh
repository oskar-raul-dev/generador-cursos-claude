# rescatado de la sesión 03630220, 2026-09-13T20:03:12Z · Audit the newly published story document
echo "════ 8. AUDITORÍA DEL DOCUMENTO RECIÉN PUBLICADO ════"
echo "-- lenguaje de propuesta / autor --"
grep -nE "propuesta|candidat|este documento propone|si se elige|habría que|el curso debería|opción [AB]|alternativa" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/'
echo "-- referencias a maquinaria interna --"
grep -nE "prompts/|alcance-del-proyecto|propuesta-fases|guia-de-estilo|congelamiento|§[0-9]" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/'
echo "-- conteos y fases --"
grep -nE "veinticinco|veinticuatro|2[0-9] fases|fase [0-9]+|F[0-9]{2}" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/' | head -20
