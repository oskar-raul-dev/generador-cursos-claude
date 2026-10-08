# 05 — Intervalos y barrido de eventos

> Por qué el convenio semiabierto `[inicio, fin)` elimina la mitad de los casos borde, la condición
> de solapamiento que casi todo el mundo escribe con cuatro `if` cuando cabe en uno, fusionar
> intervalos ordenando por inicio, y la línea de barrido: la técnica que convierte "cuántos a la vez"
> en un recorrido.
> Asume leído [`01` — Ordenación](01-ordenacion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Cuatro requisitos que parecen distintos y son el mismo:

```text
"¿Puedo reservar esta sala de 10 a 11?"              → ¿solapa con alguna reserva?
"¿Cuántas salas necesito para estas 500 reuniones?"  → máximo solapamiento simultáneo
"Estas tarifas por tramo, ¿dejan algún hueco?"       → fusionar y comprobar continuidad
"¿Cuántos usuarios había conectados a la vez?"       → máximo solapamiento, otra vez
```

Los cuatro se resuelven con dos técnicas: **ordenar por inicio y fusionar**, o **barrer los eventos
de entrada y salida**. Y los cuatro se fallan por el mismo motivo: escribir mal la condición de
solapamiento, o no decidir si el final de un intervalo está dentro o fuera.

Este capítulo es corto a propósito. Su valor no es la dificultad algorítmica —no la tiene— sino que
aparece constantemente en backend y casi nadie lo tiene sistematizado.

> **Regla de entrevista:** lo primero que se pregunta ante un enunciado de intervalos es **si los
> extremos son abiertos o cerrados**. Sin esa respuesta, "solapan" no está definido y la mitad de
> los casos borde son inventables.

---

## 2. 🧱 El convenio semiabierto

**Qué es.** Representar un intervalo como `[inicio, fin)`: el inicio está dentro y el fin está
fuera.

**Por qué.** Porque hace que dos intervalos consecutivos **encajen sin solapar y sin hueco**:

```text
cerrado  [10:00, 11:00] y [11:00, 12:00]  → ¿solapan a las 11:00? Ambiguo, y hay que decidirlo
semiabierto [10:00, 11:00) y [11:00, 12:00) → no solapan, no hay hueco. Sin ambigüedad
```

- Es el mismo convenio de `subMap(desde, true, hasta, false)` de un `TreeMap`, de `bisect_left`, del
  `for (int i = 0; i < n; i++)` de toda la vida y del corte de un slice en Go y Python. **La
  industria entera converge en el semiabierto**, y no por casualidad: la longitud es `fin - inicio`
  sin sumar uno, y la concatenación es trivial.
- Con fechas, el equivalente es guardar `fecha_fin` como el primer instante **no** cubierto. Una
  tarifa vigente "hasta el 31 de diciembre" se almacena con fin el 1 de enero, y desaparece toda la
  aritmética de "menos un día" que produce bugs en los cambios de mes.

**Cuándo no.** Cuando el dominio impone lo contrario y no lo controlas: un rango de facturación
"del 1 al 31 inclusive" viene así del negocio, y conviene **convertir en la frontera** —como en
[`02-texto/01`](../02-texto/01-strings-entre-lenguajes.md) con Unicode— en vez de arrastrar dos
convenios por el código.

> **Veredicto:** elige semiabierto siempre que puedas y **decláralo en el nombre o en el tipo**. La
> mitad de los bugs de intervalos son dos partes del sistema usando convenios distintos.

---

## 3. 🧱 La condición de solapamiento

**El problema.** Casi todo el mundo la escribe enumerando los casos: uno empieza dentro del otro,
uno contiene al otro, son idénticos… Salen cuatro o cinco `if` y alguno falta.

**La forma correcta** es una sola línea, y sale de negar el caso fácil:

```text
NO solapan  ⟺  a.fin <= b.inicio  ||  b.fin <= a.inicio      (uno acaba antes de que el otro empiece)
SÍ solapan  ⟺  a.inicio < b.fin   &&  b.inicio < a.fin       (la negación de lo anterior)
```

```java
boolean solapan(Rango a, Rango b) {
    return a.inicio().isBefore(b.fin()) && b.inicio().isBefore(a.fin());   // semiabierto
}
```

- **Es simétrica y cubre los cinco casos** —contención, solapamiento parcial por cualquier lado e
  identidad— sin enumerarlos.
- Con el convenio **semiabierto** se usa `<` estricto; con intervalos **cerrados** hay que usar
  `<=`, y ese es exactamente el punto donde el convenio deja de ser un detalle.
- El truco mnemotécnico: *"cada uno empieza antes de que el otro termine"*. Si puedes decir esa
  frase, has escrito la condición.

> 💡 **Truco.** Cuando te pidan "¿se puede reservar?", escribe primero la condición de **no**
> solapamiento, que es la intuitiva, y niégala. Intentar enumerar los casos de solapamiento
> directamente es donde la gente se deja uno.

---

## 4. 🧱 Fusionar intervalos

**El problema.** Dada una lista de rangos que pueden solaparse, producir la lista mínima
equivalente.

**Cómo va.** Ordenar por **inicio** y recorrer, extendiendo el último si el siguiente lo toca:

```java
rangos.sort(Comparator.comparing(Rango::inicio));
List<Rango> fusionados = new ArrayList<>();
for (Rango actual : rangos) {
    Rango ultimo = fusionados.isEmpty() ? null : fusionados.get(fusionados.size() - 1);
    if (ultimo != null && !actual.inicio().isAfter(ultimo.fin())) {        // toca o solapa
        fusionados.set(fusionados.size() - 1, ultimo.conFin(max(ultimo.fin(), actual.fin())));
    } else {
        fusionados.add(actual);
    }
}
```

- **Por inicio, no por fin.** Aquí es al revés que en la selección de actividades de
  [`05-dp-y-tecnicas/02`](../05-dp-y-tecnicas/02-algoritmos-voraces.md), que ordena por fin. Son dos
  problemas distintos con dos criterios distintos, y confundirlos es el error clásico.
- El `max` del final es imprescindible: el intervalo siguiente puede estar **contenido** en el
  anterior, y quedarse con su fin acortaría el resultado.
- El `!isAfter` incluye el caso "termina justo donde empieza el otro", que con semiabierto significa
  adyacente. Si quieres fusionar adyacentes, se usa así; si no, `isBefore`.

**Cuánto.** O(n log n) por la ordenación, O(n) el recorrido.

**Cuándo sí.** Normalizar disponibilidad, unir tramos de tarifa, calcular cobertura total,
comprimir periodos de actividad.

**Cuándo no.** Si los rangos llegan ya ordenados —muy frecuente si vienen de una consulta con
`ORDER BY`— el coste baja a O(n) y hay que decirlo.

---

## 5. 🧱 La línea de barrido

**El problema.** "¿Cuántas reuniones hay a la vez como máximo?" No se resuelve fusionando: hay que
contar.

**Cómo va.** Se descompone cada intervalo en **dos eventos** —entrada y salida—, se ordenan todos
por instante, y se recorre llevando un acumulador:

```text
reuniones: [9,11)  [10,13)  [12,14)

eventos ordenados:   9:+1   10:+1   11:-1   12:+1   13:-1   14:-1
acumulado:            1       2       1       2       1       0
                              ↑ máximo = 2 salas
```

```java
List<int[]> eventos = new ArrayList<>();           // {instante, delta}
for (Rango r : rangos) { eventos.add(new int[]{r.inicio(), +1}); eventos.add(new int[]{r.fin(), -1}); }
eventos.sort(Comparator.<int[]>comparingInt(e -> e[0]).thenComparingInt(e -> e[1]));
int activos = 0, maximo = 0;
for (int[] e : eventos) { activos += e[1]; maximo = Math.max(maximo, activos); }
```

- **El desempate importa y es la trampa del ejercicio.** Cuando una reunión acaba a las 11 y otra
  empieza a las 11, con el convenio semiabierto **no solapan**, así que la salida tiene que
  procesarse antes. Ordenando `delta` ascendente, el `-1` va primero. Con el criterio contrario,
  contarías una sala de más.
- Es O(n log n) por la ordenación, y **el mismo esqueleto sirve para más cosas**: sumar cargas en
  vez de contar (con `delta` igual al peso), encontrar el instante de máxima concurrencia, o
  detectar huecos buscando dónde el acumulado llega a cero.
- La alternativa sin barrido —un heap de finales, como en la asignación de salas— también es
  O(n log n) y devuelve además **qué** reunión va en cada sala. El barrido solo devuelve el número.

> 🧠 **Modelo mental.** Fusionar responde *"¿qué periodos están cubiertos?"*; barrer responde
> *"¿cuántos a la vez?"*. Ordenar por inicio y recorrer para la primera; descomponer en eventos ±1
> para la segunda. Con esas dos frases se resuelve casi todo el capítulo.

---

## 6. 🧱 Buscar el intervalo que contiene un punto

**El problema.** Dado un conjunto de tramos que no se solapan —tarifas, franjas horarias, rangos de
IP— y un punto, ¿en cuál cae?

**Cómo va.** Si los tramos no se solapan, están **ordenados por inicio**, y entonces es una búsqueda
del vecino por abajo: exactamente el `floorEntry` de
[`04-arboles-grafos/01`](../04-arboles-grafos/01-arboles.md).

```java
TreeMap<LocalDate, Tarifa> tramos = new TreeMap<>();   // clave: inicio de vigencia
Map.Entry<LocalDate, Tarifa> e = tramos.floorEntry(fecha);
boolean dentro = e != null && fecha.isBefore(e.getValue().fin());   // comprobar el FIN también
```

- **La comprobación del fin no es opcional**: `floorEntry` devuelve el tramo que empieza antes, pero
  ese tramo puede haber terminado ya. Sin esa línea, una fecha en un hueco devuelve alegremente la
  tarifa anterior. Es el caso borde que la respuesta de `04-arboles-grafos/01 → 23` ya anticipaba.
- O(log n) por consulta. Con un arreglo ordenado en vez de un árbol, lo mismo con búsqueda binaria.
- **Si los tramos sí pueden solaparse**, esto deja de valer y hace falta un *interval tree*, que está
  fuera del alcance de este corpus. Nombrarlo y decir que no lo implementarías es la respuesta
  correcta.

---

## 7. ⏱️ La tabla de costes

| Problema | Técnica | Coste | Lo que la tabla no dice |
|---|---|---|---|
| ¿Solapan dos? | Una comparación doble | O(1) | El convenio decide si es `<` o `<=` |
| Fusionar una lista | Ordenar por **inicio** + recorrer | O(n log n) | O(n) si ya vienen ordenados de la consulta |
| Máximo simultáneo | Barrido de eventos ±1 | O(n log n) | El desempate salida-antes-que-entrada es el bug |
| Asignar recursos | Heap de finales | O(n log n) | Devuelve **qué** va en cada recurso, no solo cuántos |
| Máximo número compatible | Voraz por **fin** | O(n log n) | Es otro problema: ver `05-dp-y-tecnicas/02` |
| ¿Qué tramo contiene X? | `floorEntry` + comprobar fin | O(log n) | Solo si los tramos **no** se solapan |

---

## 8. ⚖️ Los cinco lenguajes

| Lenguaje | Qué ayuda | El detalle que muerde |
|---|---|---|
| **Java** | `TreeMap.floorEntry`, `Comparator.comparing`, `LocalDate`/`Instant` | No hay tipo rango: se modela con un `record Rango(T inicio, T fin)` |
| **Python** | `bisect` sobre inicios ordenados; `sorted(key=...)` | Tampoco hay tipo rango; `range` es de enteros y semiabierto, coherente con el convenio |
| **JavaScript** | Nada específico | Ordenar fechas exige comparador: `sort()` sin él las convierte a string |
| **TypeScript** | Tipar `Rango<T>` y marcar el convenio en el nombre | Aporta poco, pero `readonly` y un tipo nominal evitan mezclar convenios |
| **Go** | `slices.SortFunc`, `time.Time.Before/After` | `time.Time` no se compara con `<`: hay que usar `Before`/`After`, y olvidarlo no compila |

La observación transversal: **ningún lenguaje trae un tipo intervalo**, así que el convenio vive en
tu código y en tu disciplina. Las bibliotecas que sí lo traen —Guava con `Range` y `RangeSet` en Java—
resuelven fusión, solapamiento y consulta por punto de una vez, y merecen mencionarse cuando el
problema es grande.

---

## 9. 🧭 Cómo se elige

```text
¿Solapan dos intervalos?                     → a.inicio < b.fin && b.inicio < a.fin
¿Lista mínima equivalente?                   → ordenar por INICIO y fusionar
¿Cuántos a la vez como máximo?               → barrido de eventos ±1
¿Cuántos recursos, y cuál va en cada uno?    → heap de finales
¿Máximo número de compatibles?               → voraz por FIN (es otro problema)
¿En qué tramo cae este punto?                → floorEntry, y comprueba el fin
¿Los tramos se solapan entre sí?             → interval tree: nómbralo y no lo implementes
```

> **Regla de entrevista:** "por inicio" para fusionar, "por fin" para seleccionar el máximo número
> compatible. Son dos problemas de intervalos con dos criterios de ordenación opuestos, y decir cuál
> es cuál demuestra que los distingues.

---

## 10. 🔭 Dónde aparece de verdad

En la comprobación de disponibilidad de cualquier sistema de reservas —salas, vuelos, citas
médicas—; en el dimensionado de un pool a partir de las sesiones concurrentes observadas, que es un
barrido sobre los logs; en la facturación por tramos de tarifa, donde fusionar detecta huecos y
solapes que el negocio no sabía que tenía; en las ventanas de mantenimiento y los calendarios de
despliegue; en el enrutado por rangos de IP, que es búsqueda del tramo que contiene un punto; y en el
cálculo de SLA, donde el tiempo caído total es la unión de los incidentes solapados.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Escribo los casos de solapamiento con varios `if`" | Uno solo: `a.inicio < b.fin && b.inicio < a.fin` |
| "Ordeno por inicio para todo" | Fusionar sí; seleccionar el máximo compatible es por **fin** |
| "Al fusionar me quedo con el fin del segundo" | Hay que tomar el **máximo**: puede estar contenido |
| "El barrido es sumar entradas y restar salidas" | Y **procesar la salida antes** cuando coinciden, o cuentas de más |
| "`floorEntry` me da el tramo vigente" | Te da el que empezó antes; hay que comprobar además su fin |
| "Guardo el fin como el último día incluido" | Con semiabierto —primer instante no cubierto— desaparece la aritmética de ±1 día |
| "Los intervalos solapados se buscan igual" | Sin solapes basta la binaria; con solapes hace falta un interval tree |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT Press,
  2022). Sección 17.3, árboles de intervalos, para el caso que este capítulo declara fuera de
  alcance; y el capítulo 15 para la selección de actividades.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Capítulo 20, con los
  problemas de intervalos del catálogo y cuándo cada uno se vuelve difícil.
- **Libro** — Bentley, *Programming Pearls*, 2ª ed. (Addison-Wesley, 1999). Columna 8, con el
  subarreglo de suma máxima, que es el mismo tipo de recorrido con acumulador que el barrido.
- [Java 21 API — `TreeMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/TreeMap.html):
  `floorEntry`, `ceilingEntry` y `subMap`, que son las tres consultas de intervalo que da la stdlib.
- [Python — `bisect`](https://docs.python.org/3/library/bisect.html): las recetas de búsqueda por
  rango sobre listas ordenadas, que son la versión sin árbol de lo mismo.
- [Go — `slices`](https://pkg.go.dev/slices): `SortFunc` y `BinarySearchFunc` para ordenar y buscar
  por inicio de intervalo.
- **Tutorial** — Baeldung, «Merge Overlapping Intervals in Java»: la implementación con los casos
  borde escritos.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué significa el convenio semiabierto `[inicio, fin)`? 🟢
2. Escribe la condición de que dos intervalos solapen. 🟢
3. ¿Por qué se ordena por inicio para fusionar? 🟢
4. ¿Qué es una línea de barrido? 🟢
5. ¿Qué complejidad tiene fusionar una lista de intervalos? 🟢
6. ¿Por qué el semiabierto elimina casos borde con fechas consecutivas? 🟡
7. ¿Por qué la condición de solapamiento se escribe negando la de no solapamiento? 🟡
8. Al fusionar, ¿por qué hay que tomar el máximo de los dos finales? 🟡
9. En el barrido, ¿por qué las salidas se procesan antes que las entradas al coincidir? 🟡
10. ¿En qué se diferencia fusionar intervalos de seleccionar el máximo número compatible? 🟡
11. ¿Por qué `floorEntry` no basta para saber en qué tramo cae una fecha? 🟡
12. ¿Qué devuelve un barrido que no devuelve un heap de finales, y al revés? 🟠
13. ¿Cómo detectas huecos en una secuencia de tramos de tarifa? 🟠
14. ¿Cómo cambia el problema si los tramos pueden solaparse entre sí? 🟠
15. ¿Cómo calcularías el tiempo total de caída a partir de incidentes que se solapan? 🟠
16. ¿Cómo adaptarías el barrido para sumar cargas en vez de contar elementos? 🟠
17. ¿Por qué en Go no puedes comparar dos `time.Time` con `<`, y qué ventaja tiene? 🟠
18. Un sistema de reservas acepta dos reservas solapadas de vez en cuando. Da tres hipótesis. 🔴
19. Diseña el cálculo de "cuántas conexiones simultáneas hubo como máximo" sobre 50 millones de
    registros de sesión al día. 🔴
20. Te dan tramos de tarifa de 10 años con solapes y huecos. Diseña la normalización y di qué
    decisiones de negocio hay que confirmar antes. 🔴

---

**Anterior:** [`04` — Hashing y tablas hash](04-hashing-y-tablas-hash.md) ·
**Siguiente:** [`06` — Algoritmos sobre flujos](06-algoritmos-sobre-flujos.md) ·
**Relacionado:** [`05-dp-y-tecnicas/02` — Algoritmos voraces](../05-dp-y-tecnicas/02-algoritmos-voraces.md)
