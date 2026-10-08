# 🧱 Formato de los miniproyectos
## C# para desarrolladores Java senior

Cada fase cierra con **un miniproyecto obligatorio**. Es la sección 7 de la plantilla y el
mecanismo principal de consolidación del curso: ocupa el lugar que en un curso de sistemas
heredados ocuparía el cuaderno de incidentes.

Este documento define qué es, cómo se calibra y qué forma tiene. Se sigue literal.

---

## 1. Qué es un miniproyecto, y qué no

> 🧭 **Un miniproyecto es un encargo pequeño, completo y difícil, que solo se puede terminar si
> entendiste el tema de la fase — no si lo leíste.**

Tiene tres propiedades no negociables:

- **Es completo.** Entra un dato real del dominio y sale un resultado verificable. No es un
  fragmento ni un ejercicio de rellenar huecos: compila, se ejecuta, produce algo.
- **Es pequeño.** Entre dos y cinco horas de trabajo para el lector objetivo. Si necesita un
  fin de semana, es un proyecto y no cabe en una fase.
- **Es difícil**, en el sentido concreto de la §3.

Y no es ninguna de estas cosas:

- **No es el ejercicio 26.** Los ejercicios entrenan piezas; el miniproyecto integra.
- **No es el avance de proyecto de la fase.** Cada fase mueve uno de los proyectos que
  atraviesan el curso, y eso va en la sección 5, dentro del código de la fase. El miniproyecto
  es de usar y tirar: consolida el tema y se archiva con su tag.
- **No es una versión recortada de la fase.** Si el encargo se cumple copiando el código de la
  sección 5 y cambiando nombres, está mal diseñado.

---

## 2. Por qué existe, y por qué sustituye al cuaderno de incidentes

Un curso de sistemas heredados enseña a **arreglar** un sistema que ya existe, y por eso su
unidad de práctica es el incidente: un síntoma, una reproducción, una causa raíz.

Este curso hace las dos cosas —construir moderno y cortar un sistema vivo—, y por eso su unidad
de práctica tiene que ser un encargo. La pregunta que el lector se hace al empezar un
miniproyecto es la misma que se va a hacer el lunes en su trabajo: *¿esto se migra, se envuelve
o se deja quieto, y qué me cuesta cada respuesta?*

Hay un segundo motivo, y es el perfil. Un dev Java senior aprende resolviendo, no leyendo. El
material puede explicar la evaluación diferida de LINQ durante cuatro páginas y el reflejo no
cambia; el reflejo cambia cuando la consulta se ejecuta dos veces contra la base y el perfilador
lo muestra.

> 📝 **Lo forense no se pierde: se absorbe.** En el bloque del sistema heredado y en el de
> migración, la forma natural del miniproyecto es **un encargo de diagnóstico**: aquí está el
> síntoma que reportó Nohora, aquí está el código, encuentra la causa, arréglala con el parche
> mínimo y escribe la prueba de regresión que falla antes y pasa después. Eso es un incidente
> con otro nombre, y cabe entero en este formato.

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
   datos de ejemplo y falla con los datos reales: el `IEnumerable` recorrido dos veces, el
   `.Result` que bloquea el hilo, el `double` que redondea mal la regalía, el `DateTime.Now`
   sin zona en un cálculo que cruza nueve husos, el `catch (Exception)` que se traga el error
   que importaba.
4. **El resultado se verifica solo.** Criterios de aceptación ejecutables, no impresiones.

> ⚠️ **La prueba de calibración, y es literal:** si puedes terminar el miniproyecto copiando el
> código de la sección 5 de la fase y renombrando variables, **está mal diseñado y se
> reescribe**. No se aprueba una fase cuyo miniproyecto no pase esta prueba.

Y el límite por el otro lado: un miniproyecto que necesita un paquete que la fase no introdujo,
una suscripción de nube de pago o un servicio externo que el lector no tiene, también está mal
diseñado. La dificultad viene del problema, no del montaje.

---

## 4. La estructura, sección por sección

Es la que va desarrollada dentro de la sección 7 de cada fase.

### 4.1 El encargo

Quién lo pide, en las palabras de esa persona, y qué necesita. Sale del dominio de Cordillera y
de su gente: Nohora necesita que un libro salga, Ximena no quiere un paso más en su flujo,
Gustavo decide un tiraje, Duván necesita poder mantenerlo cuando tú no estés, Clara pregunta
quién levanta esto si se cae un martes.

En prosa, dos o tres frases, con la voz del que pide — no con la voz del profesor. *"Duván te
escribe: 'el reporte histórico del comercial se está demorando cuatro minutos y el servidor se
queda sin memoria dos de cada cinco veces. Ya lo miré y no entiendo por qué, si la consulta en
Management Studio vuelve en ocho segundos'."*

### 4.2 Por qué duele

Qué hace difícil el encargo, en una o dos frases. Es lo que separa un miniproyecto de un
ejercicio: aquí se nombra la fricción real —el volumen, el esquema hostil, la regla de negocio
que tiene tres excepciones, el dato que llega mal una vez de cada seis, el hecho de que no se
puede apagar nada—.

### 4.3 Datos de entrada

Concretos y suficientes para trabajar: un fragmento representativo, la forma de los archivos o
del esquema, los casos límite que el lector va a encontrar. **Incluye siempre al menos un caso
sucio**, del tipo que produce el mundo real y no un generador de datos de prueba — y en este
curso el caso sucio tiene nombre y apellido: la fecha en `char(8)` que trae `'00000000'`, el
movimiento de inventario cuyo título ya no existe, la tilde que se comió la intercalación en la
importación de 2017, el registro con `BORRADO = 'S'` que media consulta olvida filtrar.

Si los datos los genera un script del propio curso, se dice cómo se ejecuta. Si son un fragmento
literal, va completo en el documento — el lector no debería tener que inventárselos. **Los
nombres del esquema heredado se escriben tal cual** (guía §5.1).

### 4.4 Criterios de aceptación

Lista corta de condiciones **ejecutables**. Cada una se puede comprobar corriendo algo.

> ✅ *"Procesa el archivo de 500.000 filas con un pico de memoria administrada por debajo de
> 80 MB, medido con el arnés de la fase."*
>
> ❌ *"Usa `IAsyncEnumerable` de forma eficiente."*

Entre tres y seis criterios. Uno de ellos, siempre, es **de medición**: el miniproyecto produce
un número, y ese número es lo que va en el mensaje del tag `mini-NN`.

### 4.5 Restricciones de estilo y alcance

La regla que ata el miniproyecto al tema y al estilo de la fase. Se escribe explícita, y en este
curso tiene dos formas según el bloque:

> *"Esto es código nuevo. Nullable activado, advertencias como errores, `async` de punta a punta
> con `CancellationToken`. Si te descubres escribiendo `IRepositoryImpl`, ese es exactamente el
> reflejo que la fase está atacando."*

> *"Esto es un fix sobre código de 2017. Se escribe en el estilo de ese archivo, con su
> `DataSet` y sin `async`. Modernizar mientras arreglas es cómo se rompen otras tres cosas, y
> aquí se penaliza."*

Cuando el miniproyecto cruce la frontera entre generaciones, la restricción dice **dónde vive el
borde** y exige marcarlo 🧬.

### 4.6 La trampa

Se declara **sin resolverla**. Se nombra el punto donde el lector se va a estrellar y se le deja
el trabajo de descubrir por qué.

> *"Vas a querer materializar la consulta para poder recorrerla dos veces. Funciona con el
> fragmento de ejemplo. Con las treinta tablas anuales, no."*

Esto no es crueldad pedagógica: es que el error hay que cometerlo para que el patrón se fije. La
solución de referencia explica la trampa entera, y por eso va después.

### 4.7 Pistas (progresivas, plegadas)

Tres pistas, de menos a más concreta, cada una dentro de un `<details>` para que el lector elija
cuánto quiere que le cuenten. Es la única excepción aceptada al "markdown puro" de la guía §3.

```markdown
<details><summary>Pista 1 — el enfoque</summary>
{{Qué forma tiene la solución, sin nombrar la API.}}
</details>

<details><summary>Pista 2 — la herramienta</summary>
{{Qué parte de .NET o del stack resuelve esto, con el enlace a su documentación.}}
</details>

<details><summary>Pista 3 — el esqueleto</summary>
{{Las firmas de los dos o tres métodos, sin cuerpo.}}
</details>
```

### 4.8 Cómo se entrega

Qué proyecto, qué comando lo ejecuta, qué salida se espera, y el recordatorio del tag:

```bash
git tag -a mini-07 -m "Mini F7: <qué hace> · <el número de la medición>"
```

**El número va en el mensaje del tag.** Es lo que permite que el lector compare su resultado con
el suyo de hace tres fases, y que la solución de referencia tenga contra qué contrastarse.

### 4.9 Solución de referencia

Va **al final de la fase o en un plegado**, nunca a la vista mientras se lee el encargo. Incluye
el código completo, comentado en español, y tres cosas que el código solo no dice:

- **La decisión de diseño que se tomó** y por qué, reconociendo el otro camino defendible.
- **La trampa, explicada entera**, con el número de lo que costaba el camino ingenuo.
- **Qué se habría hecho distinto si la decisión hubiera sido otra** — si en vez de migrar se
  hubiera envuelto, o si en vez de tocarlo se hubiera dejado quieto. Una o dos frases. Es el
  remate pedagógico del curso y es barato de escribir.

---

## 5. Relación con los proyectos que atraviesan el curso

Los proyectos crecen fase a fase; los miniproyectos no los tocan. Esa separación es deliberada y
evita el problema clásico del curso encadenado: **si el miniproyecto de la fase 6 modificara el
proyecto principal, quien lo hizo mal arrastraría el error hasta el final.**

El miniproyecto puede, en cambio, **usar** lo que el proyecto ya produjo —leer su salida,
consumir su API, medir contra su implementación, diagnosticar un síntoma en su código— y ahí el
enganche es legítimo y conveniente.

---

## 6. Checklist de un miniproyecto antes de darlo por bueno

- [ ] El encargo está en la voz de alguien de Cordillera, no en la del profesor.
- [ ] **No se resuelve copiando la sección 5 de la fase** (§3, la prueba literal).
- [ ] Exige al menos una consulta a documentación oficial que la fase no transcribió.
- [ ] Contiene una decisión de diseño real, con dos caminos defendibles.
- [ ] Declara su trampa sin resolverla.
- [ ] Los datos de entrada incluyen al menos un caso sucio, y el esquema heredado aparece con
      sus nombres reales.
- [ ] Tiene entre tres y seis criterios de aceptación **ejecutables**, y uno es de medición.
- [ ] Declara su restricción de estilo de forma explícita, y marca 🧬 los cruces de generación.
- [ ] Cabe en dos a cinco horas para el lector objetivo.
- [ ] No necesita paquetes que la fase no introdujo, servicios externos, ni una suscripción de
      nube de pago. Todo corre en la máquina Windows del lector.
- [ ] Tiene tres pistas progresivas, plegadas.
- [ ] La solución de referencia explica la decisión, la trampa con su número, y qué habría
      cambiado si la decisión hubiera sido otra.
- [ ] No modifica ninguno de los proyectos que atraviesan el curso (§5).
- [ ] Nada de lo que pide implica apagar el sistema, ni siquiera un rato.
