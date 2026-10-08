# rescatado de la sesión b1c17b96, 2026-09-12T14:17:04Z · Check epoch discipline in Bloque A
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== DISCIPLINA DE ÉPOCA: APIs post-1.13 en fases 00-07 ==="
for f in 0[0-7]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  hits=$(grep -nE 'os\.ReadFile|os\.WriteFile|io\.ReadAll|os\.CreateTemp|log/slog|slog\.|slices\.|maps\.|errors\.Join|go\.work|any\)|\[T any\]|testing\.F|t\.Setenv|WithoutCancel|b\.Loop|iter\.Seq|min\(|max\(|PathValue|r\.Pattern|signal\.NotifyContext' "$f" | grep -vE '🕰️|Fase 0[89]|Fase 1[0-7]|no entra|NO entra|prohibi|1\.1[4-9]|1\.2[0-9]|moderno|comparación')
  if [ -n "$hits" ]; then echo "── $f"; echo "$hits" | head -12; echo; fi
done
echo "(revisar manualmente los que salgan)"
