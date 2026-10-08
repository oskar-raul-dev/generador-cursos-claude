# 🔤 Fase 01 — Sintaxis, tipos y el modelo de valores

> Go para desarrolladores Java senior · Fase 1 de 17 · **7 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 00 · Habilita: Fase 02
> Proyectos que avanzan: **OpsReport nace**
> Mini proyectos: `movement-parser`, `text-toolkit`, `log-grep`

---

## 🎯 1. Propósito

La Fase 00 te dejó la máquina lista y el monorepo creado, con `go1.13` instalado
para que la época se respete sola. Ahora empieza el lenguaje.

Esta fase no te enseña qué es un bucle. Te enseña **dónde el modelo de valores de
Go difiere del de Java**, que es un sitio muy concreto y produce una familia de
bugs muy concreta: los que pasan los tests, pasan la revisión de código y explotan
tres semanas después con datos reales. Un slice compartiendo su arreglo de
respaldo con otro. Un mapa nulo en el que no puedes escribir. Un subslice de tres
bytes que retiene diez megas en memoria. Nada de eso existe en Java, y todo eso
te va a pasar.

Al terminar, lees código Go sin traducirlo mentalmente, y nace `WorkItem`: el
primer tipo de la plataforma Meridian.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `services/opsreport` es un módulo con `go 1.13` en su `go.mod`, y
      `go1.13 build ./...` pasa.
- [ ] El paquete `workitem` define el tipo `WorkItem`, sus constantes de estado y
      de tipo, `Validate()` y `EffectivePriority()`.
- [ ] `labs/movement-parser` parsea un archivo de movimientos de tienda y reporta
      las líneas inválidas con su número de línea.
- [ ] `labs/text-toolkit` normaliza, parte y une texto, y su `main` compara tres
      formas de concatenar sobre 10.000 elementos.
- [ ] `labs/log-grep` filtra un log con `regexp`, con la expresión compilada
      **fuera** del bucle.
- [ ] Puedes explicar, con código delante, por qué `append` a veces modifica el
      slice de otro y a veces no.
- [ ] `go1.13 vet ./...` y `gofmt -l .` en verde en todo lo escrito.

---

## 🚫 3. Qué NO entra todavía

- Structs con métodos, interfaces y composición → Fase 02. Aquí `WorkItem` es un
  struct con campos y **funciones sueltas** que lo reciben; los métodos llegan en
  la fase siguiente y verás por qué el cambio importa.
- Manejo serio de errores: centinelas, tipos de error, `%w`, `errors.Is` → Fase
  03. Aquí el manejo es `if err != nil { return err }` y nada más.
- Tests → Fase 04. Aquí verificamos con `main` y con la salida en pantalla, que
  es exactamente el mal hábito que la Fase 04 viene a corregir. 💸
- Genéricos → Fase 08 🕰️ (Go 1.18). Cuando escribas la tercera función que hace
  lo mismo para `int` y para `string`, acuérdate de esta línea.
- `slices` y `sort.Slice` con funciones de comparación genéricas → `slices` es
  Fase 08 🕰️ (Go 1.21). `sort.Slice` **sí** existe en 1.13 y lo usamos.
- Lectura de archivos con `os.ReadFile` → Fase 08 🕰️ (Go 1.16). En 1.13 se usa
  `ioutil.ReadFile`, y así lo vas a ver en cualquier repositorio de esa época.

---

## 🧠 4. Concepto mínimo

### Declarar: tres formas y una que vas a usar siempre

```go
var name string          // valor cero: ""
var count int = 10       // explícita, casi nunca hace falta
count2 := 10             // inferencia; solo dentro de funciones
```

La tercera es la que usarás el 95% del tiempo. La primera aparece cuando quieres
el valor cero explícitamente o cuando declaras a nivel de paquete, donde `:=` no
está permitido.

Y aquí está la primera diferencia que importa de verdad: **en Go no hay `null`
para los tipos básicos**. Un `string` no inicializado es `""`, no `nil`. Un `int`
es `0`. Un `bool` es `false`. Un struct es un struct con todos sus campos en su
valor cero. Solo tienen `nil` los punteros, slices, mapas, canales, funciones e
interfaces.

```go
var s string
fmt.Println(len(s), s == "")  // 0 true — no hay NullPointerException posible aquí
```

> 🧠 **Modelo mental.** En Java, `String s;` en un campo de clase es `null`, y
> `s.length()` revienta. En Go, el valor cero está pensado para ser **útil**: un
> `sync.Mutex` en su valor cero es un mutex desbloqueado y funcional; un
> `bytes.Buffer` en su valor cero es un buffer vacío y usable. Ese principio se
> llama *"make the zero value useful"* y lo vas a ver aplicado en toda la stdlib.

### Tipos con nombre: no son `typedef`

```go
type Priority int
type Status string
```

Esto **no** es un alias. `Priority` es un tipo nuevo, distinto de `int`, y el
compilador no los mezcla:

```go
var p Priority = 5
var n int = p          // ./main.go:8:14: cannot use p (type Priority) as type int
var n2 int = int(p)    // bien: conversión explícita
```

Vienes de un mundo donde `int` se promueve a `long` y a `double` sin que nadie
diga nada. **En Go no hay promoción implícita de ningún tipo numérico.** Sumar un
`int` y un `int64` es un error de compilación. Molesta el primer día y evita una
clase entera de bugs de precisión el resto del proyecto.

Y a cambio te regala algo que en Java cuesta una clase envoltorio: tipos de
dominio baratos. `type Status string` te da un tipo con sus propias constantes y
sus propios métodos (Fase 02), con cero sobrecoste en tiempo de ejecución.

### `if`, `switch` y el único bucle

```go
// if con inicializador: la variable vive solo dentro del if/else
if value, ok := index[key]; ok {
	fmt.Println(value)
} else {
	fmt.Println("no está")
}
// aquí value ya no existe
```

Ese patrón —inicializar y comprobar en la misma línea, con el ámbito acotado— es
el idioma más común de Go y aparece en cada handler, cada `Scan` y cada acceso a
un mapa.

```go
switch status {
case StatusQueued, StatusRunning:
	// sin break: no hay caída entre casos
	return true
case StatusDone:
	return false
default:
	return false
}
```

**No hay `break`, porque no hay caída.** Si de verdad quieres caer al siguiente
caso, existe `fallthrough` y se usa casi nunca. Y el `switch` sin expresión es el
`if/else if` encadenado hecho legible:

```go
switch {
case age < 13:
	return "kid"
case age < 20:
	return "teen"
default:
	return "adult"
}
```

Y un solo bucle, `for`, en sus cuatro formas:

```go
for i := 0; i < 10; i++ { }        // el de siempre
for condition { }                   // el while
for { break }                       // el infinito
for i, v := range items { }         // el for-each
```

> 🕰️ **Fuera de época.** `for i := range 10` —rangear sobre un entero— llegó en
> Go 1.22, y los iteradores (`iter.Seq`, `range` sobre funciones) en 1.23. Los
> vemos en la Fase 08. Hasta entonces, el bucle de tres partes.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"un slice es un `ArrayList`"*. Es razonable: los dos crecen, los
dos se indexan, los dos tienen longitud. Incluso el código se parece.

**Qué pasa si lo aplicas:** esto.

```go
package main

import "fmt"

func main() {
	movements := []string{"SALE", "REFUND", "VOID", "DEPOSIT"}

	// "Solo quiero los dos primeros para procesarlos aparte."
	firstTwo := movements[:2]
	fmt.Println(firstTwo)  // [SALE REFUND]

	// Y añado uno a mi copia local. Es mi slice, ¿no?
	firstTwo = append(firstTwo, "PATCHED")

	fmt.Println(movements)  // [SALE REFUND PATCHED DEPOSIT]  ← ¿perdón?
}
```

**`movements` cambió.** No lo tocaste. No hay referencia compartida explícita, no
pasaste nada por parámetro, no hay aliasing visible en el código. Y sin embargo el
tercer elemento del slice original ahora dice `PATCHED`.

**Por qué.** Un slice **no es** un contenedor: es una **cabecera de tres campos**
que apunta a un arreglo:

```mermaid
flowchart LR
    MV["movements<br/>cabecera: ptr · len=4 · cap=4"] -- "ptr" --> AR
    FT["firstTwo<br/>cabecera: ptr · len=2 · cap=4"] -- "ptr" --> AR
    AR["arreglo de respaldo, el MISMO para los dos<br/>[SALE] [REFUND] [VOID] [DEPOSIT]"]
```

`firstTwo` tiene `len=2` pero `cap=4`: el arreglo de respaldo tiene sitio. Cuando
haces `append`, Go ve que cabe y **escribe en la posición 2 del arreglo
compartido** en vez de reservar uno nuevo. `movements[2]` y `firstTwo[2]` son la
misma celda de memoria.

Y lo que lo vuelve peligroso de verdad es que **a veces no pasa**:

```go
movements := []string{"SALE", "REFUND", "VOID", "DEPOSIT"}
firstTwo := movements[:2:2]          // ← el tercer índice limita la capacidad
firstTwo = append(firstTwo, "PATCHED")
fmt.Println(movements)               // [SALE REFUND VOID DEPOSIT] — intacto
```

Con `cap=2`, `append` no tiene sitio, reserva un arreglo nuevo, copia y desacopla.
Mismo código, comportamiento opuesto, y la única diferencia es un número que
normalmente no miras.

**Qué pensar en su lugar:** *"un slice es una **vista** sobre un arreglo, y dos
vistas pueden solaparse"*. Cuando devuelvas un subslice de datos que no controlas
—o que el llamador puede modificar—, **copia explícitamente**:

```go
// La forma de decir "esto es tuyo, no mío":
firstTwo := make([]string, 2)
copy(firstTwo, movements[:2])

// O, en una línea, con el tercer índice de capacidad:
firstTwo := movements[:2:2]
```

☕ Este es el ejemplo fundacional del curso: un reflejo razonable de Java
—*"`subList` me da una lista independiente"*, que además en Java tampoco es
verdad del todo— trasladado a un modelo distinto, y el resultado no es un error
de compilación sino un dato corrupto en producción.

### El mapa nulo, que es la otra mitad de la sorpresa

```go
var counts map[string]int
fmt.Println(counts == nil)     // true
fmt.Println(len(counts))       // 0   — leer está permitido
fmt.Println(counts["SALE"])    // 0   — leer una clave ausente también
counts["SALE"] = 1             // panic: assignment to entry in nil map
```

**Leer un mapa nulo funciona; escribir en él revienta.** Esa asimetría es
deliberada y es la causa del `panic` más común del principiante. La regla
práctica: un mapa siempre se crea antes de usarlo.

```go
counts := make(map[string]int)
counts := map[string]int{}      // equivalente
```

Y el acceso con el idioma de las dos variables, que es cómo Go distingue "la clave
no está" de "la clave está y vale el valor cero":

```go
if count, ok := counts["SALE"]; ok {
	fmt.Println("hay", count)
}
```

Sin el `ok`, un `counts["NOPE"]` devuelve `0` sin decir nada, y no sabes si había
un cero guardado o no había nada. Es exactamente la ambigüedad que en Java
resuelves con `containsKey` o con `Optional`.

> ⚠️ **El orden de iteración de un mapa es aleatorio, y lo es a propósito.** Go
> lo aleatoriza en cada ejecución para que nadie escriba código que dependa del
> orden. Si necesitas orden, extraes las claves, las ordenas y recorres eso. En
> Java el `HashMap` tampoco garantiza orden, pero en la práctica es estable entre
> ejecuciones, y esa estabilidad accidental ha causado más de un incidente al
> portar código.

### Strings, bytes y runas

```go
s := "ñandú"
fmt.Println(len(s))              // 7, no 5
fmt.Println(len([]rune(s)))      // 5
```

Un `string` en Go es **una secuencia inmutable de bytes**, y la convención es que
esos bytes son UTF-8. `len()` cuenta bytes. `ñ` ocupa dos y `ú` otros dos, así que
`len("ñandú")` es 7.

En Java, `String` es una secuencia de `char` UTF-16, `length()` devuelve unidades
de código, y un emoji fuera del plano básico cuenta como 2. Los dos modelos tienen
la misma trampa —la unidad no es el carácter percibido— pero la tienen en sitios
distintos, y eso confunde al portar.

```go
for i, r := range s {
	fmt.Printf("%d: %c (%d)\n", i, r, r)
}
// 0: ñ (241)
// 2: a (97)      ← el índice salta de 0 a 2
// 3: n (110)
// 4: d (100)
// 5: ú (250)
```

**`range` sobre un string itera por runas, no por bytes**, y el índice que te da
es el desplazamiento en bytes. Indexar directamente, en cambio, te da un byte:

```go
fmt.Println(s[0])        // 195 — el primer byte de ñ, que no es un carácter
fmt.Printf("%c\n", s[0]) // Ã   — basura, como era de esperar
```

Y la conversión que hay que tener clara:

```go
b := []byte(s)   // copia, porque los strings son inmutables
r := []rune(s)   // copia y decodifica UTF-8 a code points
```

Las dos **copian**. Eso importa cuando el string es grande y estás en un bucle, y
es el origen del mini proyecto `text-toolkit`.

### Punteros: los hay, y no muerden

```go
item := WorkItem{ID: "WI-1"}
p := &item
p.Priority = 7           // sin (*p).Priority: Go desreferencia solo
fmt.Println(item.Priority) // 7
```

Hay punteros, hay `&` y hay `*`. **No hay aritmética de punteros** —no puedes
hacer `p++`— y por eso no hay una clase de bugs de memoria que C sí tiene. El
recolector de basura se encarga del resto, así que, viniendo de Java, la única
pregunta nueva es *cuándo* usar uno.

La respuesta corta, que ampliaremos en la Fase 02 con los receptores: usas puntero
cuando **quieres modificar el original** o cuando **el valor es grande y copiarlo
cuesta**. Para lo demás, valores.

```go
// Pasar por valor COPIA el struct entero
func markDone(item WorkItem) { item.Status = StatusDone }   // no hace nada útil

// Pasar por puntero permite modificar
func markDone(item *WorkItem) { item.Status = StatusDone }  // sí
```

> 🧠 **Modelo mental.** En Java todo objeto es una referencia y no lo piensas; los
> únicos valores son los primitivos. En Go **todo es un valor por defecto**,
> incluidos los structs, y tú decides cuándo quieres una referencia. Slices, mapas
> y canales son la excepción interesante: son valores, pero valores que contienen
> un puntero dentro, y por eso "pasarlos por valor" comparte los datos.

### Y el compilador que falla por un import sin usar

Ya te pasó en la Fase 00 y va a seguir pasándote. Recuerda lo que significa: **el
código muerto no compila**. No es tolerancia cero por gusto; es que el equipo de
Go decidió que la deuda de mantenimiento de un import huérfano supera la molestia
de borrarlo. Configura `goimports` al guardar y deja de pensar en ello.

### 🩻 Esto sí funciona igual

- **La aritmética entera y sus desbordamientos** se comportan igual: `int32` da la
  vuelta exactamente como en Java, sin excepción y sin aviso.
- **`switch` con `default`, operadores lógicos con cortocircuito, precedencia de
  operadores** — todo idéntico. No hay sorpresas aquí.
- **Los strings son inmutables** en los dos lenguajes, y por la misma razón:
  seguridad al compartirlos y poder usarlos como claves.
- **El bucle con índice** es el mismo bucle. `for i := 0; i < n; i++` no necesita
  traducción.
- **La conversión explícita entre numéricos** existe en Java también (`(int) d`);
  la diferencia es que en Go es **obligatoria siempre**, no solo cuando se pierde
  precisión.
- **Ordenar con un comparador** es el mismo concepto: `sort.Slice(s, func(i, j int) bool)`
  es `list.sort(Comparator)` con otra sintaxis. Fíjate en que devuelve `bool`
  ("¿va antes?") en vez de un entero de tres estados, y eso es más difícil de
  equivocar.

---

## 🛠️ 5. CLI de la fase

```bash
# Toda la fase se compila con el toolchain de 1.13. Si te olvidas y usas `go`,
# el código va a compilar igual y la disciplina de época se pierde en silencio.
go1.13 build ./...
go1.13 vet ./...
go1.13 run ./labs/movement-parser

# Formatea y verifica formato. -l lista los archivos mal formateados sin tocarlos:
# es el comando exacto que se pone en CI.
gofmt -l .
gofmt -d main.go          # muestra el diff de lo que cambiaría, sin escribir

# El paquete que hay que conocer desde el primer día: qué trae strings.
go1.13 doc strings
go1.13 doc strings.Builder
go1.13 doc strconv.Atoi

# Benchmarks: se ejecutan con go test, no con un comando propio. -run '^$' evita
# correr los tests normales; -bench elige cuáles corren; -benchmem añade las
# columnas de asignaciones, que casi siempre son la parte interesante.
go1.13 test -run '^$' -bench . -benchmem ./labs/text-toolkit

# -count controla cuántas veces se repite cada benchmark. Una corrida no es un
# resultado; en la Fase 15 lo formalizamos con benchstat.
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/text-toolkit

# El compilador te cuenta sus decisiones de asignación. Lo exploramos en serio en
# la Fase 15, pero míralo ya una vez: es la ventana al escape analysis.
go1.13 build -gcflags='-m' ./labs/text-toolkit
```

> 💡 **`-benchmem` no es opcional en este curso.** Las columnas `B/op` y
> `allocs/op` explican el *porqué* de casi toda diferencia de rendimiento en Go, y
> son más estables entre máquinas que los nanosegundos. Cuando compares dos
> implementaciones, mira primero las asignaciones.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `movement-parser`

El laboratorio de strings, conversiones y el primer `error`. Y no es un ejemplo
inventado: **este parser es el germen del que ClearingHouse va a usar en la Fase
09** para leer los movimientos que el agente de tienda acumula sin red.

Un movimiento de caja llega como una línea de texto plano, separada por tuberías:

```text
# labs/movement-parser/testdata/movements.txt
ST-014|2026-09-11T08:14:02Z|SALE|145900|COP
ST-014|2026-09-11T08:15:41Z|REFUND|-32000|COP
ST-014|2026-09-11T08:16:10Z|VOID|0|COP
ST-014|2026-09-11T08:19:55Z|SALE|abc|COP
ST-014|2026-09-11T08:21:03Z|DEPOSIT|500000
```

Las dos últimas líneas están rotas a propósito: una tiene un monto no numérico y
la otra tiene cuatro campos en vez de cinco. Un parser que solo funciona con datos
limpios no es un parser.

```go
// labs/movement-parser/main.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Movement es un movimiento de caja tal como lo emite el punto de venta.
// El monto viaja en la unidad mínima de la moneda (centavos) para no arrastrar
// errores de coma flotante: nunca se usa float64 para dinero.
type Movement struct {
	StoreID  string
	Occurred string // se parsea a time.Time en la Fase 03, con su zona horaria
	Kind     string
	AmountMinor int64
	Currency string
}

// parseMovement convierte una línea del archivo del punto de venta en un
// Movement. Devuelve un error descriptivo con el contenido del campo que falló,
// porque quien lo lee está mirando un archivo de ochenta mil líneas.
func parseMovement(line string) (Movement, error) {
	fields := strings.Split(line, "|")
	if len(fields) != 5 {
		return Movement{}, fmt.Errorf("se esperaban 5 campos, llegaron %d", len(fields))
	}

	amount, err := strconv.ParseInt(fields[3], 10, 64)
	if err != nil {
		// En la Fase 03 esto se envuelve con %w. Aquí todavía no.
		return Movement{}, fmt.Errorf("monto inválido %q", fields[3])
	}

	return Movement{
		StoreID:     fields[0],
		Occurred:    fields[1],
		Kind:        fields[2],
		AmountMinor: amount,
		Currency:    fields[4],
	}, nil
}

func main() {
	file, err := os.Open("testdata/movements.txt")
	if err != nil {
		fmt.Fprintln(os.Stderr, "no se pudo abrir el archivo:", err)
		os.Exit(1)
	}
	defer file.Close() // se ejecuta al salir de main, pase lo que pase

	var (
		movements []Movement
		rejected  int
	)

	scanner := bufio.NewScanner(file)
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		movement, err := parseMovement(line)
		if err != nil {
			// El número de línea es lo único que hace útil un error de parseo.
			fmt.Fprintf(os.Stderr, "línea %d: %v\n", lineNo, err)
			rejected++
			continue
		}
		movements = append(movements, movement)
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "error leyendo el archivo:", err)
		os.Exit(1)
	}

	fmt.Printf("aceptados: %d · rechazados: %d\n", len(movements), rejected)
	for _, m := range movements {
		fmt.Printf("  %s %s %s %d %s\n", m.StoreID, m.Occurred, m.Kind, m.AmountMinor, m.Currency)
	}
}
```

```bash
cd labs/movement-parser && go1.13 run .
# línea 4: monto inválido "abc"
# línea 5: se esperaban 5 campos, llegaron 4
# aceptados: 3 · rechazados: 2
#   ST-014 2026-09-11T08:14:02Z SALE 145900 COP
#   ...
```

Cuatro cosas de este código que vale la pena señalar, porque son idioma y no
casualidad:

**Los múltiples valores de retorno son el mecanismo de errores.** `parseMovement`
devuelve `(Movement, error)`. No es una tupla de conveniencia: es *la* convención,
el error va siempre último, y el valor de la izquierda no se usa si el error no es
`nil`. Fíjate en que devolvemos `Movement{}` —el valor cero— en vez de algo
parecido a `null`.

**`defer file.Close()` va inmediatamente después de comprobar el error de
`Open`.** Ese orden es deliberado: si `Open` falló, `file` es inútil y no hay nada
que cerrar; si funcionó, el `defer` garantiza el cierre en todas las salidas de la
función. Es `try-with-resources` sin las llaves y con más alcance: se ejecuta al
salir de la **función**, no del bloque. La semántica exacta y la trampa del
`defer` dentro de un bucle son de la Fase 03.

**`bufio.Scanner` es el `BufferedReader.readLine()` de Go**, y tiene la misma
trampa que su primo: hay que preguntar por `scanner.Err()` al terminar, porque el
bucle también se acaba cuando hay un error de lectura, no solo al llegar al final.
Olvidar esa comprobación es cómo se pierde silenciosamente media mitad de un
archivo.

**`fmt.Fprintln(os.Stderr, ...)` y no `fmt.Println`.** Los diagnósticos van a la
salida de error; los datos, a la estándar. Eso es lo que permite
`go1.13 run . > movimientos.txt` y seguir viendo los rechazos en pantalla.

> 🧪 **Prueba de fuego.** Añade una línea con un monto de veinte dígitos
> (`99999999999999999999`) y corre. Vas a ver `monto inválido` con un mensaje de
> `strconv` sobre el rango. **La mentira de la pantalla:** el mensaje dice "value
> out of range", y podrías pensar que el bug está en tu código. No: `ParseInt` con
> `bitSize=64` está haciendo exactamente su trabajo, y `AmountMinor int64` es el
> límite real de tu modelo. Si tu negocio necesita más, el tipo está mal elegido —
> y esa es una decisión de dominio, no de parseo.

### 6.2 Mini proyecto: `text-toolkit`

Aquí se mide, y es la primera vez del curso. La pregunta: **¿cuánto cuesta
concatenar mal?**

En Java sabes que `String +=` en un bucle es un antipatrón y usas `StringBuilder`
por reflejo 🩻. El reflejo es correcto y se traslada tal cual. Lo que cambia es la
magnitud, y eso solo se sabe midiendo.

```go
// labs/text-toolkit/join.go
package toolkit

import (
	"fmt"
	"strings"
)

// JoinNaive concatena con += dentro del bucle. Cada += crea un string nuevo y
// copia todo lo anterior: el trabajo total crece con el cuadrado del número de
// elementos. Está aquí para medirlo, no para usarlo.
func JoinNaive(parts []string) string {
	var out string
	for _, p := range parts {
		out += p + ","
	}
	return strings.TrimSuffix(out, ",")
}

// JoinSprintf es la misma idea con fmt.Sprintf, que además pasa por el
// formateador y por la reflexión de fmt.
func JoinSprintf(parts []string) string {
	var out string
	for _, p := range parts {
		out = fmt.Sprintf("%s%s,", out, p)
	}
	return strings.TrimSuffix(out, ",")
}

// JoinBuilder usa strings.Builder, que mantiene un buffer de bytes que crece
// amortizado y entrega el string final sin copiarlo.
func JoinBuilder(parts []string) string {
	var b strings.Builder
	for i, p := range parts {
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString(p)
	}
	return b.String()
}

// JoinBuilderGrow es JoinBuilder reservando el tamaño de una vez. Si sabes
// cuánto vas a escribir, decirlo elimina todas las reasignaciones intermedias.
func JoinBuilderGrow(parts []string) string {
	size := 0
	for _, p := range parts {
		size += len(p) + 1
	}

	var b strings.Builder
	b.Grow(size)
	for i, p := range parts {
		if i > 0 {
			b.WriteString(",")
		}
		b.WriteString(p)
	}
	return b.String()
}

// JoinStdlib es lo que deberías escribir en producción: la stdlib ya lo resuelve
// y lo resuelve bien.
func JoinStdlib(parts []string) string {
	return strings.Join(parts, ",")
}
```

Y el archivo de benchmarks. Sí, es un `_test.go` y sí, los tests son de la Fase
04 — pero un benchmark no es un test y `testing.B` es la única forma de medir
honestamente en Go. Lo usamos ahora y lo explicamos a fondo en la Fase 15.

```go
// labs/text-toolkit/join_bench_test.go
package toolkit

import (
	"strconv"
	"testing"
)

// buildParts genera n referencias externas con la forma que usa Meridian.
func buildParts(n int) []string {
	parts := make([]string, n)
	for i := range parts {
		parts[i] = "SAP-2026-" + strconv.Itoa(100000+i)
	}
	return parts
}

func BenchmarkJoinNaive(b *testing.B) {
	parts := buildParts(10000)
	b.ResetTimer() // no midas la preparación de los datos
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = JoinNaive(parts)
	}
}

func BenchmarkJoinSprintf(b *testing.B) {
	parts := buildParts(10000)
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = JoinSprintf(parts)
	}
}

func BenchmarkJoinBuilder(b *testing.B) {
	parts := buildParts(10000)
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = JoinBuilder(parts)
	}
}

func BenchmarkJoinBuilderGrow(b *testing.B) {
	parts := buildParts(10000)
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = JoinBuilderGrow(parts)
	}
}

func BenchmarkJoinStdlib(b *testing.B) {
	parts := buildParts(10000)
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = JoinStdlib(parts)
	}
}
```

```bash
cd labs/text-toolkit
go1.13 test -run '^$' -bench . -benchmem -count=10 .
```

> 📐 **Cómo se mide.** Esta es la entrada **B-02** de `BENCHMARKS.md`:
> *`strings.Builder` frente a `+=` y `fmt.Sprintf`*. La hipótesis es falsable y
> está escrita allí; el comando es el de arriba; la tabla de resultados la
> completas con tus números. Y la entrada **B-04** —*slice pre-dimensionado frente
> a `append` desde cero*— sale del ejercicio 15 de esta fase.
>
> Lo que la medición te tiene que dejar claro, mires la máquina que mires: **la
> diferencia no está en los nanosegundos, está en la columna `allocs/op`.**
> `JoinNaive` asigna una vez por iteración del bucle interno; `JoinBuilderGrow`
> asigna una vez en total. Ese es el mecanismo, y el mecanismo se transfiere
> aunque tu CPU sea otra.

La otra mitad del laboratorio es la normalización, donde aparecen las runas:

```go
// labs/text-toolkit/normalize.go
package toolkit

import "strings"

// NormalizeReference deja una referencia externa en forma canónica: sin espacios
// alrededor, en mayúsculas y sin separadores repetidos.
// Ojo con strings.ToUpper y los idiomas: para el turco, la 'i' mayúscula no es
// 'I'. Aquí las referencias son ASCII, así que es seguro; en texto de usuario,
// no lo es, y golang.org/x/text/cases existe por eso.
func NormalizeReference(raw string) string {
	trimmed := strings.TrimSpace(raw)
	upper := strings.ToUpper(trimmed)

	var b strings.Builder
	b.Grow(len(upper))
	prevDash := false
	for _, r := range upper {
		if r == '-' || r == '_' || r == ' ' {
			if !prevDash {
				b.WriteRune('-')
				prevDash = true
			}
			continue
		}
		b.WriteRune(r)
		prevDash = false
	}
	return strings.Trim(b.String(), "-")
}

// TruncateRunes corta un texto a n caracteres visibles, no a n bytes. Cortar por
// bytes en UTF-8 parte un carácter por la mitad y produce el rombo con el
// signo de interrogación que todos hemos visto en un log.
func TruncateRunes(s string, n int) string {
	runes := []rune(s)
	if len(runes) <= n {
		return s
	}
	return string(runes[:n]) + "…"
}
```

🧨 **Rompe a propósito.** Trunca por bytes y mira qué sale:

```go
func TruncateBytesBroken(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

fmt.Println(TruncateBytesBroken("conciliación nocturna", 12))
// concilia?i…   ← el byte 12 cae en mitad de la 'ó'
```

Eso no da error, no da panic y no lo detecta ningún linter. Aparece en un reporte
tres meses después, cuando un cliente pregunta por qué el nombre de su tienda sale
con un rombo.

### 6.3 Mini proyecto: `log-grep`

Expresiones regulares, y la lección número uno sobre ellas: **compilar fuera del
bucle**. Este laboratorio alimenta el filtrado de eventos de EventRelay más
adelante.

```go
// labs/log-grep/main.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
)

// La expresión se compila UNA VEZ, a nivel de paquete. MustCompile entra en panic
// si el patrón es inválido, y eso es correcto aquí: un patrón mal escrito es un
// bug del programador que tiene que reventar en el arranque, no en producción a
// las tres de la mañana.
var deliveryLine = regexp.MustCompile(
	`^(?P<ts>\S+)\s+(?P<level>[A-Z]+)\s+endpoint=(?P<endpoint>EP-\d+)\s+status=(?P<status>\d{3})`,
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	matched := 0

	for scanner.Scan() {
		line := scanner.Text()

		// FindStringSubmatch devuelve nil si no hay coincidencia; el índice 0 es
		// el match completo y a partir del 1 vienen los grupos, en orden.
		groups := deliveryLine.FindStringSubmatch(line)
		if groups == nil {
			continue
		}

		fmt.Printf("%s → endpoint %s respondió %s\n",
			groups[1], groups[3], groups[4])
		matched++
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "error leyendo la entrada:", err)
		os.Exit(1)
	}
	fmt.Fprintf(os.Stderr, "líneas coincidentes: %d\n", matched)
}
```

```bash
cat testdata/relay.log | go1.13 run .
```

Y la versión que **no** hay que escribir, para medirla:

```go
// Está aquí para el benchmark B-03 y para que veas el coste. Compilar una
// expresión regular construye un autómata: es trabajo real, y hacerlo por línea
// en un log de un millón de líneas es un millón de autómatas idénticos.
func matchSlow(line string) bool {
	re := regexp.MustCompile(`^(\S+)\s+([A-Z]+)\s+endpoint=(EP-\d+)`)
	return re.MatchString(line)
}
```

> 📐 **Cómo se mide.** Entrada **B-03**: *`regexp` compilado fuera del bucle
> frente a dentro*. Comando y condiciones en `BENCHMARKS.md`. 📖 En Java es el
> mismo error con `Pattern.compile` dentro del bucle en vez de en una constante
> `static final`, y el reflejo de sacarlo fuera 🩻 se traslada intacto. Lo que
> cambia es el sitio natural donde ponerlo: en Java, un `static final`; en Go, una
> `var` de paquete con `MustCompile`.

> ⚠️ **El motor de `regexp` de Go es RE2, no PCRE.** Garantiza tiempo lineal, lo
> que significa que **es inmune al ReDoS** —esa categoría de ataque no existe
> aquí—, y a cambio **no soporta backreferences ni lookahead/lookbehind**. Si
> traes una expresión de Java con `(?=...)`, no va a compilar, y no es un bug: es
> una decisión de diseño. La alternativa es reescribirla o resolverlo con código.

### 6.4 OpsReport nace: el tipo `WorkItem`

Ya tienes el lenguaje suficiente. Vamos al primer código de la plataforma.

Recuerda el dominio: un **trabajo operativo** de Meridian es una tarea que un área
lanza —una conciliación, una importación de catálogo, un recálculo de inventario—
y que hoy vive en una hoja de cálculo. `WorkItem` es ese trabajo.

```bash
mkdir -p services/opsreport/internal/workitem
cd services/opsreport
go mod init github.com/meridian/opsreport
```

Y ahora **edita el `go.mod` a mano** para fijar la época:

```text
module github.com/meridian/opsreport

go 1.13
```

> 🧭 **Regla del proyecto.** La directiva `go 1.13` en el `go.mod` no es
> decorativa: junto con `go1.13 build`, es lo que hace que la disciplina del
> Bloque A sea verificable. En la Fase 08 esa línea cambia, y el `git diff` de ese
> cambio es parte del entregable de la migración.

```go
// services/opsreport/internal/workitem/workitem.go

// Package workitem contiene el tipo central del dominio de OpsReport: el trabajo
// operativo que un área de Meridian lanza y que el servicio ejecuta.
//
// En esta fase el paquete es solo datos y funciones. Los métodos, las interfaces
// y el servicio llegan en la Fase 02.
package workitem

import (
	"errors"
	"strings"
	"time"
)

// Status es el estado de un trabajo dentro de su ciclo de vida.
// Los valores viajan tal cual en el JSON de la API: son identificadores del
// sistema y NO se traducen.
type Status string

const (
	StatusQueued    Status = "queued"
	StatusRunning   Status = "running"
	StatusDone      Status = "done"
	StatusFailed    Status = "failed"
	StatusCancelled Status = "cancelled"
)

// Kind es la clase de trabajo operativo. Cada una la ejecuta un motor distinto,
// que llega en la Fase 06.
type Kind string

const (
	KindReconciliation Kind = "reconciliation"
	KindImport         Kind = "import"
	KindRecalculation  Kind = "recalculation"
	KindStatement      Kind = "statement"
	KindReprocess      Kind = "reprocess"
)

// Priority es la prioridad declarada por quien registra el trabajo, de 1 a 9.
// Es un tipo con nombre y no un int a secas para que el compilador impida
// pasarle una duración, un contador o un identificador por accidente.
type Priority int

const (
	MinPriority Priority = 1
	MaxPriority Priority = 9
)

// WorkItem es un trabajo operativo de la plataforma Meridian.
//
// En esta fase es un struct plano: sin métodos, sin persistencia y sin
// identificador generado. El campo Status se manipula con funciones del paquete,
// y en la Fase 02 pasará a tener su propia máquina de estados.
type WorkItem struct {
	ID                string
	ExternalReference string
	Kind              Kind
	Description       string
	Priority          Priority
	Status            Status
	CreatedAt         time.Time
	StartedAt         time.Time // valor cero = todavía no empezó
	FinishedAt        time.Time // valor cero = todavía no terminó
}

// Los errores de validación de esta fase son valores simples. En la Fase 03 se
// convierten en centinelas comparables con errors.Is y en un tipo de error que
// acumula varios fallos a la vez.
var (
	errEmptyExternalReference = errors.New("la referencia externa es obligatoria")
	errUnknownKind            = errors.New("el tipo de trabajo no es válido")
	errPriorityOutOfRange     = errors.New("la prioridad debe estar entre 1 y 9")
	errDescriptionTooLong     = errors.New("la descripción supera los 500 caracteres")
)

// maxDescriptionRunes se cuenta en runas, no en bytes: una descripción en
// español con tildes tiene más bytes que caracteres, y el límite del negocio
// habla de caracteres.
const maxDescriptionRunes = 500

// Validate comprueba que un WorkItem recién registrado es aceptable.
// Devuelve el primer problema encontrado; en la Fase 03 devolverá todos.
func Validate(item WorkItem) error {
	if strings.TrimSpace(item.ExternalReference) == "" {
		return errEmptyExternalReference
	}
	if !IsKnownKind(item.Kind) {
		return errUnknownKind
	}
	if item.Priority < MinPriority || item.Priority > MaxPriority {
		return errPriorityOutOfRange
	}
	if len([]rune(item.Description)) > maxDescriptionRunes {
		return errDescriptionTooLong
	}
	return nil
}

// IsKnownKind dice si el tipo recibido es uno de los que el servicio ejecuta.
// El switch sobre un tipo con nombre es el idioma de Go para lo que en Java
// sería un enum con valueOf y su IllegalArgumentException.
func IsKnownKind(k Kind) bool {
	switch k {
	case KindReconciliation, KindImport, KindRecalculation, KindStatement, KindReprocess:
		return true
	default:
		return false
	}
}

// IsTerminal dice si un estado ya no puede cambiar. Saber esto en un solo sitio
// evita que cada parte del sistema tenga su propia lista de estados finales,
// que es como se desincronizan.
func IsTerminal(s Status) bool {
	switch s {
	case StatusDone, StatusFailed, StatusCancelled:
		return true
	default:
		return false
	}
}

// agingBoost es cuánto sube la prioridad efectiva por cada día completo que un
// trabajo lleva encolado. Sin esto, un trabajo de prioridad 1 nunca se ejecuta
// en un sistema con carga sostenida: es el problema de inanición de toda cola
// con prioridades.
const agingBoost = 1

// EffectivePriority es la prioridad que el motor de jobs usa realmente: la
// declarada más un incremento por antigüedad, acotado al máximo.
//
// El reloj entra como parámetro, no se lee con time.Now() dentro. Es la primera
// aparición de una regla que gobierna todo el curso: una función que depende del
// reloj no se puede probar, y en la Fase 02 el reloj pasa a ser una dependencia
// inyectada.
func EffectivePriority(item WorkItem, now time.Time) Priority {
	if item.Status != StatusQueued {
		return item.Priority
	}

	daysWaiting := int(now.Sub(item.CreatedAt).Hours() / 24)
	if daysWaiting <= 0 {
		return item.Priority
	}

	effective := item.Priority + Priority(daysWaiting*agingBoost)
	if effective > MaxPriority {
		return MaxPriority
	}
	return effective
}
```

Y el `main` provisional que lo ejercita. Sí, verificar con `fmt.Println` es un mal
hábito; lo dejamos escrito para poder borrarlo con ceremonia en la Fase 04.

```go
// services/opsreport/cmd/opsreport/main.go
package main

import (
	"fmt"
	"os"
	"sort"
	"time"

	"github.com/meridian/opsreport/internal/workitem"
)

func main() {
	now := time.Date(2026, 9, 11, 9, 0, 0, 0, time.UTC)

	items := []workitem.WorkItem{
		{
			ID: "WI-001", ExternalReference: "SAP-2026-000123",
			Kind: workitem.KindReconciliation, Description: "Conciliación de tiendas del norte",
			Priority: 3, Status: workitem.StatusQueued,
			CreatedAt: now.AddDate(0, 0, -4),
		},
		{
			ID: "WI-002", ExternalReference: "SAP-2026-000124",
			Kind: workitem.KindImport, Description: "Importación de catálogo de proveedor",
			Priority: 8, Status: workitem.StatusQueued,
			CreatedAt: now.Add(-2 * time.Hour),
		},
		{
			ID: "WI-003", ExternalReference: "",
			Kind: workitem.KindImport, Priority: 5, Status: workitem.StatusQueued,
			CreatedAt: now,
		},
	}

	var valid []workitem.WorkItem
	for _, item := range items {
		if err := workitem.Validate(item); err != nil {
			fmt.Fprintf(os.Stderr, "%s rechazado: %v\n", item.ID, err)
			continue
		}
		valid = append(valid, item)
	}

	// sort.Slice ordena en el sitio con un comparador "¿va i antes que j?".
	// En la Fase 08 veremos por qué slices.SortFunc lo hace mejor. 🕰️
	sort.Slice(valid, func(i, j int) bool {
		return workitem.EffectivePriority(valid[i], now) >
			workitem.EffectivePriority(valid[j], now)
	})

	fmt.Println("cola de ejecución:")
	for _, item := range valid {
		fmt.Printf("  %s  declarada=%d  efectiva=%d  %s\n",
			item.ID, item.Priority,
			workitem.EffectivePriority(item, now), item.Kind)
	}
}
```

```bash
go1.13 run ./cmd/opsreport
# WI-003 rechazado: la referencia externa es obligatoria
# cola de ejecución:
#   WI-001  declarada=3  efectiva=7  reconciliation
#   WI-002  declarada=8  efectiva=8  import
```

> 🧪 **Prueba de fuego.** `WI-001` tiene prioridad declarada 3 y `WI-002` tiene 8,
> y sin embargo `WI-001` sale con efectiva 7 por llevar cuatro días esperando.
> Cambia `now.AddDate(0, 0, -4)` a `-6` y vuelve a correr: ahora `WI-001` es 9 y
> se pone primero. **La mentira de la pantalla:** si cambias `now` por
> `time.Now()`, el programa sigue funcionando y la salida parece igual de
> razonable — pero acabas de hacer imposible probarlo, porque el resultado depende
> del día en que lo corras. Que el reloj entre por parámetro es lo único que
> distingue a este código de un dolor de cabeza en la Fase 04.

> 💸 **Deuda técnica intencional.** Todo lo que verificamos en esta fase se
> verifica mirando la pantalla. **Se paga en la Fase 04**, donde este `main`
> desaparece y su contenido se convierte en tests de tabla de verdad.

---

## ⚰️ 7. Autopsia y errores comunes

La autopsia formal de un antipatrón empieza en la Fase 02, cuando ya hay diseño
que criticar. Aquí van los cinco bugs del modelo de valores que te van a pasar.

### Errores comunes

**1. El slice que comparte respaldo.**
*Síntoma:* modificas un subslice y cambia el original, o al revés. A veces.
*Causa:* `s[:n]` comparte el arreglo de respaldo y hereda la capacidad completa.
*Fix mínimo:* `copy` explícito, o el tercer índice: `s[:n:n]`.

**2. `append` sobre el resultado de una función que no controlas.**
*Síntoma:* dos consumidores del mismo slice se pisan los datos.
*Causa:* devolviste un subslice de tu estado interno y el llamador le hizo
`append`.
*Fix mínimo:* devuelve una copia. La regla: **si devuelves un slice de tu estado
interno, o lo copias o documentas que es de solo lectura.**

**3. Escribir en un mapa nulo.**
*Síntoma:* `panic: assignment to entry in nil map`, casi siempre en un campo de
struct que nadie inicializó.
*Causa:* el valor cero de un mapa es `nil` y es legible pero no escribible.
*Fix mínimo:* `make(map[K]V)` en el constructor. En la Fase 02, cuando aparezcan
los constructores `New`, esto deja de pasar.

**4. Cortar un string por bytes.**
*Síntoma:* caracteres rotos en logs, reportes o respuestas JSON.
*Causa:* `s[:n]` cuenta bytes; el texto en español tiene caracteres de dos bytes.
*Fix mínimo:* convertir a `[]rune` antes de cortar, o usar
`utf8.RuneCountInString` para contar.

**5. Comparar structs con `==` sin pensar.**
*Síntoma:* `invalid operation: ... (struct containing []string cannot be compared)`.
*Causa:* Go compara structs con `==` campo a campo, pero **solo si todos los
campos son comparables**. Slices, mapas y funciones no lo son.
*Fix mínimo:* comparar los campos que importan a mano, o `reflect.DeepEqual` en
tests (nunca en producción: es lento y demasiado permisivo).

### 🧨 Rompe a propósito

El experimento que hay que hacer una vez en la vida: **el subslice que retiene un
arreglo grande**.

```go
// labs/text-toolkit/retain.go
package toolkit

import "io/ioutil"

// FirstLineLeaky devuelve la primera línea de un archivo grande. Y retiene el
// archivo entero en memoria mientras alguien conserve el resultado, porque el
// slice devuelto apunta al mismo arreglo de respaldo de diez megas.
func FirstLineLeaky(path string) ([]byte, error) {
	// ioutil.ReadFile es lo que hay en 1.13. os.ReadFile llega en 1.16 🕰️.
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	for i, b := range data {
		if b == '\n' {
			return data[:i], nil // ← 30 bytes de longitud, 10 MB de respaldo
		}
	}
	return data, nil
}

// FirstLineSafe copia lo que devuelve. Treinta bytes de verdad.
func FirstLineSafe(path string) ([]byte, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	for i, b := range data {
		if b == '\n' {
			line := make([]byte, i)
			copy(line, data[:i])
			return line, nil
		}
	}
	return data, nil
}
```

Genera un archivo de diez megas, llama a las dos versiones guardando el resultado
en un slice global, fuerza una recolección con `runtime.GC()` y lee
`runtime.ReadMemStats`. La diferencia es de tres órdenes de magnitud en memoria
retenida, y **el código de las dos versiones se ve igual de correcto**.

Este es el bug que en Java no existe: `substring` dejó de compartir el arreglo de
respaldo en Java 7 precisamente por esta razón. Go tomó la decisión contraria —el
subslice comparte siempre— y te deja a ti la responsabilidad de copiar. Los dos
diseños son defendibles; el de Go es más rápido en el caso común y más peligroso
en este.

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Escribe un programa que declare una variable de cada tipo básico sin
   inicializarla e imprima su valor cero con `%#v`. *Criterio:* explicas en una
   línea por qué `var s []int` imprime `[]int(nil)` y `len(s)` es 0 sin reventar.
2. Convierte `Priority(7)` a `int`, a `int64` y a `float64`, y explica por qué
   cada conversión necesita paréntesis explícitos. *Criterio:* consigues al menos
   un error de compilación intentando la conversión implícita, y pegas el mensaje.
3. Escribe un `switch` sobre `Status` que devuelva la etiqueta en español de cada
   estado, con `default` para lo desconocido. *Criterio:* añadir un estado nuevo
   a las constantes sin tocar el switch produce la etiqueta del `default` y no un
   fallo silencioso.
4. Demuestra que `len("ñandú")` es 7 y `len([]rune("ñandú"))` es 5, y recorre el
   string con `range` imprimiendo índice y runa. *Criterio:* explicas por qué el
   índice salta.
5. Crea un mapa nulo y provoca el `panic` de escritura. Después arréglalo.
   *Criterio:* pegas el mensaje exacto del panic y explicas por qué leerlo antes
   sí funcionaba.
6. Usa `go1.13 doc strings` para encontrar la función que quita un prefijo y la
   que comprueba si un string contiene otro. *Criterio:* las encuentras sin
   buscar en internet, y escribes el comando que usaste.

**🟡 Intermedio (7–14)**

7. Reproduce el bug del `append` compartido con los movimientos de tienda, y
   después arréglalo de las dos formas: con `copy` y con el tercer índice.
   *Criterio:* un solo programa muestra los tres comportamientos con su
   explicación impresa al lado.
8. Escribe `Dedupe(kinds []string) []string` que elimine duplicados preservando el
   orden de primera aparición. *Criterio:* no modifica el slice de entrada, y lo
   demuestras imprimiendo el original después.
9. Escribe `SplitBatches(items []WorkItem, size int) [][]WorkItem` que reparta un
   slice en lotes del tamaño dado. *Criterio:* el último lote puede ser más corto;
   `size <= 0` devuelve `nil`; ningún lote comparte respaldo con otro de forma que
   un `append` los mezcle — demuéstralo.
10. Extiende `movement-parser` para que acumule totales por tipo de movimiento en
    un mapa y los imprima **ordenados por monto descendente**. *Criterio:* el
    orden es estable entre ejecuciones, y explicas por qué recorrer el mapa
    directamente no lo sería.
11. Añade a `movement-parser` la validación de que `Kind` sea uno de
    `SALE|REFUND|VOID|DEPOSIT|WITHDRAWAL` y de que `REFUND` tenga monto negativo.
    *Criterio:* cada rechazo dice el número de línea y qué regla falló.
12. Implementa `NormalizeReference` sin `strings.Builder`, usando `+=`, y mide las
    dos con `-benchmem`. *Criterio:* anotas `B/op` y `allocs/op` de las dos y
    explicas la diferencia con el modelo de memoria, no con "es más rápido".
13. Escribe `TruncateRunes` y su versión rota por bytes, y encuentra una cadena del
    dominio de Meridian donde las dos difieran. *Criterio:* la cadena es realista
    (un nombre de tienda, una descripción de trabajo), no `"ñññ"`.
14. Usa `go1.13 build -gcflags='-m'` sobre `text-toolkit` y localiza al menos dos
    líneas donde el compilador diga `escapes to heap`. *Criterio:* explicas con
    tus palabras qué significa para una de ellas. *(No hace falta entenderlo del
    todo: la Fase 15 lo desarrolla.)*

**🟠 Difícil (15–20)**

15. **Mide el pre-dimensionado.** Escribe dos versiones de una función que
    construya un slice de 100.000 `WorkItem`: una con `var items []WorkItem` y
    `append`, otra con `make([]WorkItem, 0, 100000)`. Benchmark con `-benchmem`.
    *Criterio:* anotas los resultados en la tabla de **B-04** de `BENCHMARKS.md`,
    explicas el crecimiento amortizado de `append`, y dices en qué caso el
    pre-dimensionado **no** ayuda.
16. Reproduce el 🧨 del subslice que retiene memoria: genera un archivo de 10 MB,
    usa `FirstLineLeaky` y `FirstLineSafe`, y mide la memoria retenida con
    `runtime.ReadMemStats` después de `runtime.GC()`. *Criterio:* las dos cifras
    difieren en al menos dos órdenes de magnitud y explicas la causa con el modelo
    de la cabecera de tres campos.
17. Implementa `EffectivePriority` con una tabla de casos como *datos*, no como
    código: un slice de structs con entrada y salida esperada, recorrido en un
    bucle que imprima `OK` o `FALLO`. *Criterio:* cubres al menos ocho casos,
    incluidos los bordes (0 días, prioridad ya en 9, estado no `queued`). *Esto es
    un test de tabla escrito a mano; en la Fase 04 lo convertirás en uno de verdad
    en diez minutos.*
18. Escribe `log-grep` con soporte para varias expresiones pasadas por argumentos
    de línea de comandos, usando `flag`. *Criterio:* `-pattern` se puede repetir,
    todas las expresiones se compilan **antes** del bucle, y un patrón inválido
    falla al arrancar con un mensaje claro en vez de entrar en panic a la mitad.
19. **Detección de ☕.** Te dan este fragmento:
    ```go
    type WorkItemUtils struct{}
    func (u *WorkItemUtils) GetPriorityValue(item *WorkItem) int { return int(item.Priority) }
    func (u *WorkItemUtils) SetPriorityValue(item *WorkItem, p int) { item.Priority = Priority(p) }
    func NewWorkItemUtils() *WorkItemUtils { return &WorkItemUtils{} }
    ```
    Reescríbelo en Go idiomático. *Criterio:* dices cuántas líneas y cuántas
    indirecciones desaparecen, qué se perdió (si algo) y por qué el nombre
    `WorkItemUtils` ya es la señal de alarma.
20. **Línea de comandos.** Usa `go1.13 list -f` para producir un listado de todos
    los paquetes del monorepo con sus imports directos, y detecta cuál importa más
    paquetes de la stdlib. *Criterio:* un solo comando, sin scripts auxiliares.

**🔴 Muy difícil (21–24)**

21. **El parser tolerante.** Extiende `movement-parser` para que acepte tres
    formatos de línea a la vez: el separado por tuberías, uno separado por comas
    con los campos en otro orden, y uno de ancho fijo. *Rúbrica:* (a) el formato se
    detecta por la propia línea, no por una bandera global; (b) los errores dicen
    qué formato se intentó y por qué falló; (c) ninguna expresión regular se
    compila dentro del bucle; (d) el código no tiene un `Utils` ni una jerarquía de
    parsers — resuélvelo con funciones.
22. **El buffer circular de auditoría.** Implementa un `RingBuffer` de tamaño fijo
    que guarde los últimos N eventos de un trabajo, con `Push(event string)` y
    `Snapshot() []string` que devuelva los eventos en orden cronológico.
    *Rúbrica:* (a) `Snapshot` **no** puede exponer el arreglo interno — un `append`
    del llamador no debe corromper el buffer, y lo demuestras; (b) memoria
    constante, cero asignaciones en `Push`; (c) funciona correctamente antes de que
    el buffer se llene; (d) un programa de demostración muestra que el aliasing
    está resuelto.
23. **Autopsia de rendimiento con tu propio código.** Toma `NormalizeReference` y
    escribe tres implementaciones: con `strings.Builder` y `Grow`, con
    `[]byte` y `append`, y con `strings.Map`. Mídelas con `-count=10 -benchmem`.
    *Rúbrica:* (a) declaras la hipótesis **antes** de medir y dices si te
    equivocaste; (b) las tres producen exactamente el mismo resultado para un
    conjunto de entradas con acentos y espacios repetidos; (c) explicas el
    resultado con `allocs/op`, no con adjetivos; (d) das una recomendación
    accionable, incluida la opción "la diferencia no justifica el cambio".
24. **La cola de trabajos, sin estructuras de datos prestadas.** Implementa una
    cola de prioridad para `WorkItem` usando solo slices, con `Push`, `Pop` (el de
    mayor prioridad efectiva) y `Len`. *Rúbrica:* (a) el reloj entra como
    parámetro y no se lee dentro; (b) a igual prioridad efectiva, gana el más
    antiguo, y lo demuestras; (c) `Pop` sobre una cola vacía devuelve
    `(WorkItem{}, false)` y no entra en panic; (d) explicas por qué **no** usaste
    `container/heap` y en qué caso sí lo usarías.

**🔥 Opcionales**

- Reescribe `EffectivePriority` sin `if`, solo con aritmética y `math.Min`
  convertido. Después decide cuál de las dos versiones querrías encontrarte en una
  revisión de código, y defiéndelo.
- Lee el código fuente de `strings.Builder` en tu `GOROOT`
  (`$(go1.13 env GOROOT)/src/strings/builder.go`). Son menos de cien líneas.
  Busca el campo `addr` y averigua qué previene: es una de las decisiones de
  diseño más elegantes de la stdlib.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base. Cubren lo que el temario dejó fuera a propósito.

**D1 — El parser sin asignaciones.**
Reescribe `parseMovement` para que procese una línea con **cero asignaciones**.
*Rúbrica:* (a) `-benchmem` reporta `0 allocs/op`, y lo demuestras; (b) usas
`strings.IndexByte` en vez de `strings.Split` y explicas por qué eso elimina la
asignación del slice de campos; (c) el `Movement` resultante no retiene el arreglo
de respaldo de la línea de entrada —es la lección del subslice, aplicada— y lo
verificas; (d) mides la diferencia sobre un archivo de un millón de líneas y dices
si compensa la pérdida de legibilidad. **La respuesta puede ser que no**, y ese es
un resultado válido.

**D2 — `sort.Interface` frente a `sort.Slice`.**
Implementa `sort.Interface` para una colección de `WorkItem` y compárala con
`sort.Slice`.
*Rúbrica:* (a) las dos producen el mismo orden sobre los mismos datos; (b) mides
con `-benchmem` sobre 100.000 elementos; (c) explicas de dónde viene la diferencia
—`sort.Slice` usa reflexión para intercambiar elementos— y por qué el equipo de Go
la añadió igualmente; (d) dices cuál usarías y con qué criterio, y qué cambia con
`slices.SortFunc` en Go moderno 🕰️.

**D3 — El mismo nombre con dos representaciones.**
Descubre que `"Bogotá"` puede escribirse de dos formas distintas en UTF-8 —con `á`
como un solo punto de código, o como `a` más un acento combinante— y que son
**cadenas distintas** para Go.
*Rúbrica:* (a) construyes las dos y demuestras que `==` las considera distintas, que
`len()` difiere, y que `range` produce distinto número de runas; (b) explicas qué
implica eso para la clave primaria de una tienda, para un índice único en base de
datos y para una búsqueda por nombre; (c) implementas una comparación tolerante
**solo con la stdlib de 1.13** y dices qué casos no cubre; (d) identificas cuál es
la solución correcta y por qué está fuera del Bloque A. 🕰️ *(Pista:
`golang.org/x/text/unicode/norm`, que es dependencia externa y no puedes usar
todavía; entra en el régimen del Bloque C, a partir de la Fase 08.)*

---

## 📚 9. Referencias

### Documentación oficial

- **Especificación del lenguaje** — https://go.dev/ref/spec — la sección
  *Types* y *Expressions* resuelve toda duda de conversión y comparación. Es
  densa y es la fuente última.
- **Effective Go** — https://go.dev/doc/effective_go — las secciones *Data*,
  *Arrays, slices and maps* y *Control structures* son exactamente esta fase.
- **A Tour of Go** — https://go.dev/tour/ — si quieres practicar sintaxis en el
  navegador antes de escribir código de verdad, los capítulos *Basics* y
  *More types* en una hora.
- **`strings`** — https://pkg.go.dev/strings ·
  **`strconv`** — https://pkg.go.dev/strconv ·
  **`unicode/utf8`** — https://pkg.go.dev/unicode/utf8 ·
  **`regexp`** — https://pkg.go.dev/regexp ·
  **`sort`** — https://pkg.go.dev/sort
- **Sintaxis de `regexp` (RE2)** — https://github.com/google/re2/wiki/Syntax — la
  referencia de qué soporta y qué no. Léela antes de portar una expresión de Java.
- **Notas de la versión 1.13** — https://go.dev/doc/go1.13 — para saber
  exactamente en qué terreno estás pisando en el Bloque A.

### Libros

- **The Go Programming Language** — Donovan y Kernighan. Los capítulos 3
  (*Basic Data Types*) y 4 (*Composite Types*) son la mejor explicación escrita del
  modelo de slices que existe, con los diagramas de la cabecera de tres campos.
  Escrito en la época de Go 1.5–1.8, lo que lo vuelve **perfectamente apropiado
  para el Bloque A**.
- **Learning Go** — Jon Bodner. Su capítulo sobre tipos compuestos es más moderno
  y trata explícitamente el tercer índice de capacidad, que muchos textos omiten.
- **100 Go Mistakes and How to Avoid Them** — Teiva Harsanyi. Los errores #20 a
  #28 son, literalmente, la lista de §7 de esta fase.

*(Títulos y ediciones pueden haber cambiado; el curso no cita ISBN ni páginas.)*

### Artículos y charlas

- **Go Slices: usage and internals** — https://go.dev/blog/slices-intro — el
  artículo canónico. Si solo lees uno de esta lista, que sea este.
- **Arrays, slices (and strings): The mechanics of 'append'** —
  https://go.dev/blog/slices — de Rob Pike, y explica el aliasing de `append`
  mejor que nadie.
- **Strings, bytes, runes and characters in Go** — https://go.dev/blog/strings —
  de Rob Pike también, y resuelve de una vez la confusión byte/runa/carácter.
- **Go Maps in Action** — https://go.dev/blog/maps — incluye el porqué de la
  aleatorización del orden de iteración.
- **Regular expression matching can be simple and fast** —
  https://swtch.com/~rsc/regexp/regexp1.html — de Russ Cox, y explica por qué RE2
  no tiene backreferences. Es un clásico de la informática, no solo de Go.
- **Go Code Review Comments** — https://go.dev/wiki/CodeReviewComments — la lista
  de convenciones que el ecosistema da por sabidas. Cortísima; léela entera.

### Video

- **Concurrency is not Parallelism** — Rob Pike. Todavía no toca esta fase, pero
  mírala ahora para que la Fase 06 te encuentre preparado.
- **GopherCon** en YouTube — busca charlas sobre *slices internals* y *strings and
  runes*; hay varias y todas cubren lo mismo con distinta profundidad.

> ⚠️ Buena parte del video sobre Go es anterior a los genéricos y a `slog`, lo
> cual para esta fase **no es un problema**: el modelo de valores no ha cambiado
> desde Go 1.0. Verifica la fecha solo cuando el contenido toque la stdlib.

### Orden de lectura sugerido

**Antes de escribir código:** *Go Slices: usage and internals* y *Strings, bytes,
runes and characters*. Media hora y te ahorran los dos bugs más caros de la fase.
**Durante:** `go1.13 doc <paquete>` desde la terminal, y la sección *Types* de la
especificación cuando una conversión no compile y no entiendas por qué.
**Después:** el capítulo 4 de Donovan y Kernighan, con calma, y los errores #20–28
de Harsanyi para confirmar que no se te escapó ninguno.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

El modelo de valores de Go es explícito y barato, y eso tiene costes reales:

- **Cuando tu dominio necesita estructuras persistentes o inmutables por
  contrato**, Go te deja solo. Java tiene `List.of`, `Collections.unmodifiableList`
  y ahora los *records*; en Go no hay forma de decirle al compilador "este slice no
  se modifica". La única defensa es copiar y documentar, y copiar cuesta.
- **Cuando necesitas igualdad estructural profunda como operación normal**,
  `reflect.DeepEqual` es lento y demasiado laxo (dos mapas nulos distintos de
  tipos distintos pueden sorprenderte). En Java, `equals`/`hashCode` generados —o
  un *record*— resuelven esto sin pensar. En Go se escribe a mano, y por eso en
  este curso lo usamos **solo en tests**.
- **Cuando el dominio es fuertemente numérico con mezcla de precisiones**, la
  ausencia de promoción implícita se convierte en una selva de conversiones. Es más
  seguro y es más ruidoso; si tu código es 60% aritmética mixta, vas a echar de
  menos Java.
- **Y si tu equipo depende de `Optional` como contrato de "esto puede faltar"**,
  en Go tienes que elegir entre el valor cero (barato, ambiguo) y un puntero
  (explícito, con `nil` de vuelta en tu vida). Ninguna de las dos es tan clara
  como `Optional<T>` en una firma, y conviene decidirlo como equipo antes de la
  Fase 02.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `ArrayList<T>` | `[]T` | El slice es una **vista** con `ptr/len/cap`; dos slices pueden compartir respaldo y `append` a veces escribe en el del otro |
| `List.subList(a,b)` | `s[a:b]` | `subList` en Java es una vista que falla rápido al modificar la original; el subslice de Go no falla, escribe encima |
| `Arrays.copyOf` | `copy(dst, src)` | `copy` no reserva: copia `min(len(dst), len(src))` y devuelve cuántos elementos copió. Hay que hacer el `make` antes |
| `HashMap<K,V>` | `map[K]V` | El mapa nulo **se lee pero no se escribe**; el orden de iteración es aleatorio **a propósito** y varía entre ejecuciones |
| `map.containsKey(k)` | `v, ok := m[k]` | La forma de dos valores es el idioma; sin ella no distingues "ausente" de "presente con valor cero" |
| `String` (UTF-16) | `string` (bytes UTF-8) | `len()` cuenta bytes, no caracteres; `range` itera runas pero devuelve índices de byte |
| `char` | `byte` o `rune` | No hay un solo equivalente: `byte` es `uint8`, `rune` es `int32` (un code point). Indexar da `byte`; `range` da `rune` |
| `StringBuilder` | `strings.Builder` | Igual en intención 🩻. `Builder` además **no se puede copiar** después de usarlo, y el compilador te avisa |
| `String.join` | `strings.Join` | Idéntico |
| `int`, `long`, `double` | `int`, `int64`, `float64` | **Sin promoción implícita**: `var x int64 = miInt` no compila. Conversión explícita siempre |
| `Integer` (autoboxing) | *(no existe)* | No hay boxing de tipos numéricos. Un `interface{}` con un `int` dentro sí asigna, y eso es de la Fase 02 |
| `Optional<T>` | valor cero, o `*T` | No hay equivalente en la firma. La ausencia se expresa con el valor cero (ambiguo) o con puntero (explícito, con `nil`) |
| `null` | `nil`, solo para punteros, slices, mapas, canales, funciones e interfaces | Un `string` nunca es `nil`; un struct nunca es `nil`. Se reduce la superficie del problema, no desaparece |
| `final` | *(no existe para variables)* | Solo hay `const`, y solo para valores de tiempo de compilación. No se puede congelar un slice |
| `var` (Java 10) | `:=` | Casi idéntico. `:=` solo dentro de funciones; a nivel de paquete se usa `var` |
| `enum` | `type X string` + constantes | Sin `values()`, sin `valueOf`, sin exhaustividad comprobada por el compilador. Se suple con un `switch` y una función `IsKnownX` |
| `Pattern.compile` en `static final` | `regexp.MustCompile` en `var` de paquete | Mismo reflejo 🩻. Go usa RE2: sin backreferences ni lookahead, e inmune a ReDoS |
| `list.sort(Comparator)` | `sort.Slice(s, less)` | El comparador devuelve `bool` ("¿va antes?") en vez de un entero de tres estados. Más difícil de equivocar |
| `switch` con `break` | `switch` sin `break` | No hay caída entre casos; `fallthrough` existe y casi no se usa |

### Qué sigue

La Fase 02 es la que decide si vas a escribir Go o Java con llaves distintas.
`WorkItem` deja de ser un struct con funciones sueltas y pasa a tener métodos;
aparecen las interfaces —implícitas, pequeñas y **declaradas en el consumidor**,
que es lo contrario de lo que traes de Spring—; aparece el embedding, que no es
herencia; y nace EventRelay con su máquina de estados de entrega.

Y llega la primera autopsia del curso: `WorkItemServiceImpl` con su interfaz de
nueve métodos y su fábrica, frente a un struct de cuarenta líneas, con las líneas
contadas.

### La señal de que quedó bien

> *"Veo `items[:n]` en una revisión de código y mi primera pregunta ya no es qué
> hace, sino quién más tiene una vista sobre ese arreglo."*

Si todavía lees un slice como si fuera un `ArrayList`, vuelve al 🧨 de §7 y corre
el experimento del archivo de diez megas. Esa es la clase de lección que solo
entra midiendo.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 vet ./...` y `gofmt -l .` limpios y `git status` sin cambios
> pendientes:
>
> ```bash
> git tag -a fase-01 -m "F1 cerrada: módulo opsreport en go 1.13; paquete workitem con WorkItem, estados, Validate y EffectivePriority; movement-parser, text-toolkit y log-grep funcionando; B-02, B-03 y B-04 medidos"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 01: …`) y los de ejercicio su
> número (`fase 01 ej17: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`container/heap`** — aparece solo como pregunta en el ejercicio 24. Su sitio
  natural es la **Fase 06**, cuando la cola de jobs de OpsReport se vuelve real y
  hay que decidir estructura de datos con criterio de concurrencia.
- **`golang.org/x/text/cases` y la mayúscula turca** — mencionada en un comentario
  de `NormalizeReference`. No cabe en el Bloque A (es dependencia externa). Destino:
  nota 📝 en la **Fase 11**, donde AtlasSync normaliza nombres de país en nueve
  idiomas y el problema se vuelve real.
- **`time.Time` y zonas horarias** — aquí `Occurred` es un `string` a propósito.
  El parseo real con `time.Parse` y la zona por tienda entran en la **Fase 09**,
  donde ya está declarado como "el bug más caro que ClearingHouse puede tener".
- **El campo `addr` de `strings.Builder`** — ejercicio 🔥. Si alguna vez hace
  falta explicarlo formalmente, su sitio es la **Fase 15** (copias, punteros y
  asignaciones).

## ☕ Reflejos para `INSTINTOS.md`

- **"Un slice es un `ArrayList`"** — el reflejo fundacional del curso. Coste:
  corrupción silenciosa de datos que pasa los tests. Antídoto: leerlo como una
  vista sobre un arreglo; copiar al devolver estado interno.
- **"`substring` me da una cadena independiente"** — cierto en Java desde la 7,
  falso para slices en Go. Coste: retención de memoria de órdenes de magnitud.
- **"`WorkItemUtils` con getters y setters"** — ejercicio 19. Coste: cuatro
  archivos y una indirección para leer un campo público. Antídoto: el campo ya es
  accesible; un paquete llamado `utils` es la señal de que el tipo todavía no
  encontró su sitio.
- **"El reloj se lee donde se necesita"** — `time.Now()` dentro de la función de
  negocio. Coste: la función deja de ser probable. Antídoto: el reloj es un
  parámetro (esta fase) y después una dependencia inyectada (Fase 02).

## 📐 Mediciones para `BENCHMARKS.md`

- **B-02 — `strings.Builder` frente a `+=` y `fmt.Sprintf`.** Cinco variantes
  escritas en `labs/text-toolkit`, con `Grow` y con `strings.Join` como línea
  base. Comando en §6.2.
- **B-03 — `regexp` compilado fuera del bucle frente a dentro.** Las dos versiones
  están en `labs/log-grep`; falta escribir el archivo de benchmark, que es el
  ejercicio natural de quien corre el curso.
- **B-04 — Slice pre-dimensionado frente a `append` desde cero.** Sale del
  ejercicio 15. Anotar también el caso donde **no** ayuda (slice pequeño, tamaño
  desconocido), porque el veredicto honesto lo necesita.
