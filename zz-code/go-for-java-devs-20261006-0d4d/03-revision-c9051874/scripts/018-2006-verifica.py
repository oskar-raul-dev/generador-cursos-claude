# rescatado de la sesión c9051874, 2026-09-13T20:06:36Z · Introduce goleak in phase 08
import io
p='08-migracion-a-go-moderno.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
"""
new="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
- **`go.uber.org/goleak`.** No es una novedad del lenguaje sino una librería, y
  entra aquí porque la Fase 07 lo dejó escrito: el detector de fugas de §6.4 de
  aquella fase está hecho a mano a propósito, y **ahora se sustituye para ver la
  diferencia.** Ver abajo.
"""
assert old in s; s=s.replace(old,new,1)

old2="""### 6.6 El entregable: `docs/rechazos.md`"""
new2="""**Y una librería, no una novedad del lenguaje: `goleak`.**

La Fase 07 §6.4 escribió un detector de fugas a mano —cuenta goroutines antes y
después del test— y dijo explícitamente que esta fase lo sustituiría. Se cumple:

```go
// services/opsreport/internal/jobs/main_test.go
package jobs

import (
	"testing"

	"go.uber.org/goleak"
)

// TestMain envuelve TODOS los tests del paquete. Es la forma correcta de usarlo:
// una fuga se detecta al final de la suite, no test a test, porque una goroutine
// puede tardar en morir y test a test genera falsos positivos.
func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m,
		// El pool de conexiones de database/sql mantiene goroutines vivas
		// legítimamente mientras el proceso viva. Sin esta exclusión, goleak
		// grita en cada paquete que toca la base de datos.
		goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
	)
}
```

> 🪞 **Lo que el contador a mano no podía hacer.** El detector de la Fase 07
> contaba goroutines: sabía **cuántas** sobraban, no **cuáles**. `goleak` inspecciona
> las pilas, así que te dice la función en la que cada goroutine fugada está
> parada —que es el 90% del trabajo de arreglarla— y sabe distinguir las legítimas
> del runtime y de las librerías. Ese es el salto, y solo se aprecia habiendo
> escrito antes el contador.

> ⚠️ **La lista de `Ignore...` es deuda, no configuración.** Cada exclusión que
> añades es una fuga que decides no mirar. Escribe al lado **por qué** es legítima,
> como arriba. Una lista de ocho exclusiones sin comentarios significa que el
> paquete tiene fugas y nadie lo sabe.

### 6.6 El entregable: `docs/rechazos.md`"""
assert old2 in s; s=s.replace(old2,new2,1)

# cerrar el pendiente
old3="""- **`goleak`** — la Fase 07 dejó escrito que esta fase lo introduciría sustituyendo"""
i=s.index(old3); j=s.index('\n- ',i+10)
print(repr(s[i:j]))
