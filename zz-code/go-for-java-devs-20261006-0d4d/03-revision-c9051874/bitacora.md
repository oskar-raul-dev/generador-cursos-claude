# Bitácora de ejecución · sesión c9051874-1218-483a-96ca-bbd129a78447

Comandos que ejecutaron código, con el inicio de su salida.

### ⏱️ 2026-09-13T19:51:19Z · Find references to CLAUDE.md and other courses

~~~~~~bash
echo "=== CLAUDE.md refs ==="; grep -rn "CLAUDE\.md" . | head -60
echo "=== other courses refs ==="; grep -rniE "cursos-[a-z-]+|propuestas-cursos|_oskar|courses-ia-generated|ruta-nosql|angular|for-java-devs|python-for|c-sharp|docker-container|repositorio|del repo\b|repo\b" . | grep -v "^Binary" | head -80
~~~~~~

~~~~~~text
=== CLAUDE.md refs ===
0-ESTRUCTURA-CURSO.md:218:declarada del `CLAUDE.md` del repositorio: lo que en otros cursos sería un apéndice
17-capstone.md:1402:> incumple la regla del `CLAUDE.md` del repositorio. **Hay dos salidas honestas:**
prompts/alcance-del-proyecto.md:265:Divergencia declarada frente al `CLAUDE.md` del repositorio: **este curso no
prompts/alcance-del-proyecto.md:345:| Apéndices | **No hay** | Todo vive en su fase; divergencia declarada del `CLAUDE.md` |
=== other courses refs ===
08-migracion-a-go-moderno.md:28:> mantener**. Las que no, se quedan como están. Un repositorio migrado por reflejo
08-migracion-a-go-moderno.md:38:- [ ] `go.work` existe en la raíz del monorepo y `go build ./...` funciona desde
08-migracion-a-go-moderno.md:167:# go.work: el workspace. Permite que varios módulos del monorepo se vean entre sí
08-migracion-a-go-moderno.md:322:módulos del monorepo no se veían entre sí: si `opsreport` quisiera usar un paquete
08-migracion-a-go-moderno.md:350:> repositorio de librerías impone tu configuración local a todo el mundo. **En un
08-migracion-a-go-moderno.md:351:> monorepo de aplicaciones es al revés**: quieres que todos trabajen con el mismo
08-migracion-a-go-moderno.md:1235:**3. `go.work` commiteado en un repositorio de librerías.**
08-migracion-a-go-moderno.md:1238:*Fix mínimo:* en un monorepo de aplicaciones, commitearlo (nuestro caso). En una
08-migracion-a-go-moderno.md:1249:**5. Adoptar genéricos en la capa de repositorio.**
08-migracion-a-
~~~~~~

### ⏱️ 2026-09-13T19:56:01Z · Audit external refs and rough exercise counts

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs
echo "=== 1. refs a otros cursos / proyecto raiz ==="
grep -rniE "cursos-algoritmos|cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia-generated|CLAUDE\.md|ruta-nosql|angular|python-for-java|c-sharp|docker-container|/Users/" . || echo "ninguna"
echo
echo "=== 2. conteo de ejercicios declarado por fase (§8) ==="
for f in 0[0-9]-*.md 1[0-7]-*.md; do
  n=$(grep -cE "^[0-9]+\. " "$f" 2>/dev/null)
  echo "$f  lineas-numeradas:$n"
done
~~~~~~

~~~~~~text
=== 1. refs a otros cursos / proyecto raiz ===
06-concurrencia.md:580:      /Users/tu/dev/meridian/labs/race-counter/counter.go:9 +0x3c
06-concurrencia.md:584:      /Users/tu/dev/meridian/labs/race-counter/counter.go:9 +0x50
06-concurrencia.md:588:      /Users/tu/dev/meridian/labs/race-counter/counter_test.go:12 +0xd8
06-concurrencia.md:728:	/Users/tu/dev/meridian/labs/deadlock-lab/main.go:8 +0x3c
06-concurrencia.md:751:	/Users/tu/dev/meridian/labs/deadlock-lab/deadlock.go:31
06-concurrencia.md:756:	/Users/tu/dev/meridian/labs/deadlock-lab/deadlock.go:31
14-observabilidad-y-hardening.md:1113:> `/Users/oskar/dev/meridian/...` en cada volcado de pila y en los metadatos:
00-instalacion-ambiente-y-tooling.md:1098:	/Users/tu/sdk/go1.13/src/slices (from $GOROOT)
00-instalacion-ambiente-y-tooling.md:1099:	/Users/tu/go/src/slices (from $GOPATH)

=== 2. conteo de ejercicios declarado por fase (§8) ===
00-convencion-de-git-y-tags.md  lineas-numeradas:0
00-historia-de-la-empresa-meridian.md  lineas-numeradas:0
00-instalacion-ambiente-y-tooling.md  lineas-numeradas:20
01-sintaxis-y-valores.md  lineas-numeradas:24
02-structs-interfaces-composicion.md  lineas-numeradas:26
03-errores-paquetes-io.md  lineas-numeradas:28
04-testing-dobles-cobertura.md  lineas-numeradas:30
05-http-rest-stdlib.md  lineas-numeradas:26
06-concurrencia.md  lineas-numeradas:36
07-context-y-ciclo-de-vida.md  lineas-numeradas:31
08-migracion-a-go-moderno.md  lineas-numeradas:33
09-sql-postgres-sqlite.md  lineas-numer
~~~~~~

