# 🧱 Formato de los miniproyectos
## Python para desarrolladores Java senior

Cada fase cierra con **un miniproyecto obligatorio**. Es la sección 7 de la plantilla y el
mecanismo principal de consolidación del curso, y el único: aquí no hay cuaderno de incidentes ni
batería de ejercicios de relleno.

Este documento define qué es, cómo se calibra y qué forma tiene. Se sigue literal.

---

> 🍽️ **Qué aplica al material a la carta.** En las secciones opcionales
> (`propuestas-temas-opcionales.md`) **el miniproyecto no es obligatorio**: se incluye solo cuando
> el tema lo pide, y lo normal es que baste un ejercicio. Lo que sí heredan es la regla de
> calibración —si el ejercicio se resuelve copiando el texto de la sección, está mal planteado— y
> la de los criterios de aceptación verificables.

## 1. Qué es un miniproyecto, y qué no

> 🧭 **Un miniproyecto es un encargo pequeño, completo y difícil, que solo se puede terminar
> si entendiste el tema de la fase — no si lo leíste.**

Tiene tres propiedades no negociables:

- **Es completo.** Entra un dato real del dominio y sale un resultado verificable. No es un
  fragmento ni un ejercicio de rellenar huecos: corre, se ejecuta, produce algo.
- **Es pequeño.** Entre dos y cinco horas de trabajo para el lector objetivo. Si necesita un
  fin de semana, es un proyecto y no cabe en una fase.
- **Es difícil**, en el sentido concreto de la §3.

Y no es ninguna de estas cosas:

- **No es el ejercicio 26.** Los ejercicios entrenan piezas; el miniproyecto integra.
- **No es el proyecto empresarial de la fase.** Los cuatro proyectos grandes atraviesan el
  curso y crecen fase a fase. El miniproyecto es de usar y tirar: consolida el tema y se
  archiva con su tag.
- **No es una versión recortada de la fase.** Si el encargo se cumple copiando el código de la
  sección 5 y cambiando nombres, está mal diseñado.

---

## 2. Por qué existe, y por qué no es un cuaderno de incidentes

Un curso que enseña a **arreglar** un sistema que ya existe tiene como unidad natural de práctica
el incidente: un síntoma, una reproducción, una causa raíz. Es un buen formato y no es el de aquí.

Este curso enseña a **decidir y construir**, y su unidad de práctica tiene que ser un encargo.
La pregunta que el lector se hace al empezar un miniproyecto es la misma que se va a hacer el
lunes en su trabajo: *¿esto es un script, una herramienta o una aplicación, y qué me cuesta
cada respuesta?*

Hay un segundo motivo, y es el perfil. Un dev Java senior aprende resolviendo, no leyendo. El
material puede explicar generadores durante cuatro páginas y el reflejo no cambia; el reflejo
cambia cuando el archivo de 500.000 filas no cabe en memoria y hay que rehacerlo.

---

## 3. Calibración: qué significa "difícil" aquí

La audiencia sabe resolver mirando ejemplos y leyendo documentación. Calibrar para ese lector
significa cuatro cosas concretas:

1. **El texto de la fase no alcanza.** El miniproyecto exige al menos una consulta a la
   documentación oficial sobre algo que la fase mencionó pero no transcribió. Eso es
   deliberado: leer documentación es parte del oficio que el curso entrena.
2. **Hay una decisión de diseño real que el enunciado no toma.** Dos caminos defendibles, con
   costos distintos. El lector elige y justifica; la solución de referencia elige uno y explica
   por qué, sin descalificar el otro.
3. **Hay una trampa.** Un punto donde el reflejo de Java produce algo que funciona con los
   datos de ejemplo y falla con los datos reales: el bucle que construye la lista completa, el
   `float` que redondea mal la cuota, la fecha sin zona, el `except Exception` que se traga el
   error que importaba.
4. **El resultado se verifica solo.** Criterios de aceptación ejecutables, no impresiones.

> ⚠️ **La prueba de calibración, y es literal:** si puedes terminar el miniproyecto copiando el
> código de la sección 5 de la fase y renombrando variables, **está mal diseñado y se
> reescribe**. No se aprueba una fase cuyo miniproyecto no pase esta prueba.

Y el límite por el otro lado: un miniproyecto que necesita una biblioteca que la fase no
introdujo, o un servicio externo que el lector no tiene, también está mal diseñado. La
dificultad viene del problema, no del montaje.

---

## 4. La estructura, sección por sección

Es la que va desarrollada dentro de la sección 7 de cada fase.

### 4.1 El encargo

Quién lo pide, en las palabras de esa persona, y qué necesita. Sale del dominio de Áurea y de
su gente: Patricia necesita cerrar el mes, Yuli necesita saber qué planes llevan noventa días
quietos, Julián quiere saber cuánto le deben los aliados.

En prosa, dos o tres frases, con la voz del que pide — no con la voz del profesor. *"Patricia
te manda ocho archivos y te dice: 'necesito saber cuáles filas no puedo facturar, antes de
generar nada, porque si el lote rebota pierdo el día'."*

### 4.2 Por qué duele

Qué hace difícil el encargo, en una o dos frases. Es lo que separa un miniproyecto de un
ejercicio: aquí se nombra la fricción real —el volumen, la heterogeneidad, la regla de negocio
que tiene tres excepciones, el dato que llega mal una vez de cada seis—.

### 4.3 Datos de entrada

Concretos y suficientes para trabajar: un fragmento representativo, la forma de los archivos,
los casos límite que el lector va a encontrar. **Incluye siempre al menos un caso sucio**, del
tipo que produce el mundo real y no un generador de datos de prueba.

Si los datos los genera un script del propio curso, se dice cómo se ejecuta. Si son un
fragmento literal, va completo en el documento — el lector no debería tener que inventárselos.

### 4.4 Criterios de aceptación

Lista corta de condiciones **ejecutables**. Cada una se puede comprobar corriendo algo.

> ✅ *"Procesa el archivo de 500.000 filas con un pico de memoria por debajo de 50 MB, medido
> con el arnés de la fase."*
>
> ❌ *"Usa generadores de forma eficiente."*

Entre tres y seis criterios. Uno de ellos, siempre, es **de medición**: el miniproyecto produce
un número, y ese número es lo que va en el mensaje del tag `mini-NN`.

### 4.5 Restricciones de registro

La regla que ata el miniproyecto al tema del curso. Se escribe explícita:

> *"Esto es un script. Un archivo, stdlib pura, sin dependencias, sin clases. Si te descubres
> escribiendo una jerarquía, ese es exactamente el reflejo que la fase está atacando."*

En las fases del Bloque C la restricción va en la otra dirección: tipos, pruebas, configuración
y frontera, porque escribir una aplicación con estilo de script es el error simétrico y cuesta
igual.

### 4.6 La trampa

Se declara **sin resolverla**. Se nombra el punto donde el lector se va a estrellar y se le
deja el trabajo de descubrir por qué.

> *"Vas a querer cargar el archivo entero para ordenarlo. Funciona con el fragmento de ejemplo.
> Con el archivo de marzo, no."*

Esto no es crueldad pedagógica: es que el error hay que cometerlo para que el patrón se fije.
La solución de referencia explica la trampa entera, y por eso va después.

### 4.7 Pistas (progresivas, plegadas)

Tres pistas, de menos a más concreta, cada una dentro de un `<details>` para que el lector
elija cuánto quiere que le cuenten. Es la única excepción aceptada al "markdown puro" de la
guía §3.

```markdown
<details><summary>Pista 1 — el enfoque</summary>
{{Qué forma tiene la solución, sin nombrar la API.}}
</details>

<details><summary>Pista 2 — la herramienta</summary>
{{Qué parte de la stdlib o del stack resuelve esto, con el enlace a su documentación.}}
</details>

<details><summary>Pista 3 — el esqueleto</summary>
{{Las firmas de las dos o tres funciones, sin cuerpo.}}
</details>
```

### 4.8 Cómo se entrega

Qué archivo, qué comando lo ejecuta, qué salida se espera, y el recordatorio del tag:

```bash
git tag -a mini-07 -m "Mini F7: <qué hace> · <el número de la medición>"
```

**El número va en el mensaje del tag.** Es lo que permite que el lector compare su resultado
con el suyo de hace tres fases, y que la solución de referencia tenga contra qué contrastarse.

### 4.9 Solución de referencia

Va **al final de la fase o en un plegado**, nunca a la vista mientras se lee el encargo.
Incluye el código completo, comentado en español, y tres cosas que el código solo no dice:

- **La decisión de diseño que se tomó** y por qué, reconociendo el otro camino defendible.
- **La trampa, explicada entera**, con el número de lo que costaba el camino ingenuo.
- **Qué se habría hecho distinto si el registro fuera otro** — una o dos frases. Es el remate
  pedagógico del curso y es barato de escribir.

---

## 5. Relación con los proyectos que atraviesan el curso

Los cuatro proyectos empresariales crecen fase a fase; los miniproyectos no los tocan. Esa
separación es deliberada y evita el problema clásico del curso encadenado: **si el miniproyecto
de la fase 6 modificara el proyecto principal, quien lo hizo mal arrastraría el error hasta el
final.**

El miniproyecto puede, en cambio, **usar** lo que el proyecto ya produjo —leer su salida,
consumir su API, medir contra su implementación— y ahí el enganche es legítimo y conveniente.

---

## 6. Checklist de un miniproyecto antes de darlo por bueno

- [ ] El encargo está en la voz de alguien de Áurea, no en la del profesor.
- [ ] **No se resuelve copiando la sección 5 de la fase** (§3, la prueba literal).
- [ ] Exige al menos una consulta a documentación oficial que la fase no transcribió.
- [ ] Contiene una decisión de diseño real, con dos caminos defendibles.
- [ ] Declara su trampa sin resolverla.
- [ ] Los datos de entrada incluyen al menos un caso sucio.
- [ ] Tiene entre tres y seis criterios de aceptación **ejecutables**, y uno es de medición.
- [ ] Declara su restricción de registro de forma explícita.
- [ ] Cabe en dos a cinco horas para el lector objetivo.
- [ ] No necesita bibliotecas que la fase no introdujo ni servicios externos.
- [ ] Tiene tres pistas progresivas, plegadas.
- [ ] La solución de referencia explica la decisión, la trampa con su número, y qué habría
      cambiado en otro registro.
- [ ] No modifica ninguno de los cuatro proyectos que atraviesan el curso (§5).
- [ ] Respeta la frontera de la historia clínica: ningún dato clínico identificable sale hacia
      un servicio externo.
