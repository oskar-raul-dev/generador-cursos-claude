# rescatado de la sesión 03630220, 2026-09-13T20:03:26Z · Hunt other-course references and author voice
grep -rnE "curso de (Go|Java|Python|Angular|React|Rust|Node|C\+\+)|el curso de [A-Z]" . --include="*.md" | sed 's/\(.\{150\}\).*/\1/'
echo "--- voz de autor en el documento publicado ---"
grep -nE "el curso (tiene que|debe|debería|va a tener que|necesita|puede)|le da al curso|para el curso|este curso saca|sirve al curso" 00-historia-de-cordillera.md | sed 's/\(.\{135\}\).*/\1/'
