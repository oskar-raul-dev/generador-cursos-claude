# 09 — Simulacro en vivo 1: Ventas por hora

> Formato en vivo: un problema, 45 minutos, con otra persona que hace de entrevistadora (o grabándose y
> haciendo de las dos cosas). Se califica con la rúbrica de seis puntos de
> [`01/07`](../01-oficio-del-competidor/07-programar-en-vivo.md), **no** con el verde de un juez. Quien hace de
> candidato lee solo hasta «El problema»; quien entrevista lee también el guion. Las pistas 2 y 3 están en
> [`17-pistas.md`](17-pistas.md#09--simulacro-en-vivo-1-ventas-por-hora).
>
> **Vigencia:** 2026-10-04.

---

## 🧭 Reglas

- **45 minutos**: unos 5 para entender y preguntar, 10 para la versión ingenua y su coste, 20 para la buena y
  10 para probarla a mano.
- **En voz alta todo el tiempo**: qué entiendes, qué propones, cuánto cuesta, qué caso pruebas.
- **En un editor sin autocompletar** (o en papel), en el lenguaje de la entrevista.
- **Sin ayuda**; las pistas las da quien entrevista, según el guion.

---

## 🧩 El problema

### Ventas por hora

**Nivel:** 🟢 · **Tiempo:** 45 minutos · **Formato:** programa completo, en vivo.

Una cafetería guarda cada venta en una línea con la hora, el producto y el importe. Imprime, para cada hora en
la que hubo ventas, el total vendido en esa hora, ordenado por hora.

- **Entrada.** Una línea con `n`. Después, `n` líneas `HH:MM producto importe`, con el importe con dos
  decimales y punto.
- **Salida.** Una línea por hora con ventas: `HH total`, con el total con dos decimales.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; importes entre `0.01` y `999.99`; las líneas no vienen ordenadas.

```text
Entrada             Salida
5                   09 6.75
09:15 cafe 1.50     10 1.50
09:40 tostada 2.25  11 1.50
10:05 cafe 1.50
09:59 zumo 3.00
11:30 cafe 1.50
```

---

## 🧭 Guion del entrevistador

**Antes de empezar.** Lee el enunciado en voz alta y no añadas nada. Si el candidato no pregunta nada en los
primeros cinco minutos, anótalo en el primer punto de la rúbrica. Preguntas que **debería** hacer (responde a
las que haga; no las sugieras):

- «¿Pueden venir líneas vacías o con espacios de más?»
- «¿Las horas pasan de medianoche (todas son del mismo día)?»
- «¿El importe puede tener un solo decimal?»

**Las pistas, solo si se atasca**:

- **Hacia el minuto 12**, si no hay una versión que funcione: «¿Qué parte de la hora decide el grupo, y en qué
  unidad sumas los importes para no perder céntimos?»
- **Hacia el minuto 25**, si no hay idea de mejora: «Piensa en esto: un mapa de hora (`HH`) a total en
  céntimos, y ordenar las claves al final.»
- **Hacia el minuto 35**, si la idea está pero no el código: «Parte cada importe por el punto en euros y
  céntimos; imprime `total / 100` y `total % 100` a dos cifras; las horas sin ventas no salen.»

Cada pista que des se anota y baja un punto en «la mejora nombrada con precisión».

**Si termina antes de tiempo**, una ampliación para hablar, sin código:

- ¿Y si piden también el producto más vendido de cada hora?
- ¿Y si el fichero no cabe en memoria?

---

## ✅ Después del simulacro

### La rúbrica

Cada punto, de 0 a 2. **No se califica el verde del juez.**

| Punto | 0 | 1 | 2 |
|---|---|---|---|
| Entender y preguntar antes de teclear | Empieza a escribir sin preguntar | Pregunta algo, tarde | Pregunta los bordes y confirma con un ejemplo |
| Versión ingenua correcta | No llega | Llega con errores | Correcta y rápida de escribir |
| Su coste dicho en voz alta | No lo dice | Lo dice mal o a medias | Tiempo y memoria, con la cota del enunciado |
| La mejora nombrada con precisión | No la encuentra | Con pistas | Sin pistas, con su nombre y su coste |
| Código legible | Ilegible | Funciona, con nombres pobres | Nombres claros, funciones cortas |
| Prueba a mano con un caso borde | No prueba | Prueba el ejemplo | Prueba un borde y lo traza |

Con 9 puntos o más de 12, el formato está dominado; con menos de 6, repite el capítulo `01/07` antes del
siguiente simulacro en vivo.

### Qué repasar

| Si falló… | Repasa |
|---|---|
| La idea de la versión buena | [`20/04` — El estilo de las pruebas de empresa](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md) · [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*](../06-lineales-y-hashing/03-tablas-hash.md) |
| Preguntar, el coste en voz alta o la prueba a mano | [`01/07` — Programar en vivo](../01-oficio-del-competidor/07-programar-en-vivo.md) |
| El formato de la entrada o de la salida | [`20/04` — El estilo de las pruebas de empresa](../20-ad-hoc-constructivos-e-interactivos/04-el-estilo-de-las-pruebas-de-empresa.md) |

---

**Anterior:** [`21/08` — Simulacro de empresa en Codility 3](08-simulacro-empresa-codility-03.md) · **Siguiente:** [`21/10` — Simulacro en vivo 2: El hueco para la reunión](10-simulacro-en-vivo-02.md) ·
**Relacionado:** [`21/17` — Pistas](17-pistas.md#09--simulacro-en-vivo-1-ventas-por-hora).
