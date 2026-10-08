# 08 — Simulación de entrevista

> El examen del bloque `02-modelado-oo`: preguntas transversales que cruzan los siete capítulos y
> cinco ejercicios de diseño de veinte minutos, cuatro de ellos de modelar o revisar un modelo. Asume
> leídos los capítulos [`01`](01-uml-lo-justo-en-mermaid.md) a [`07`](07-objetos-frente-a-tablas.md).
> Las respuestas, en [`09` — Respuestas](09-respuestas.md#08--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Dibujando de verdad.** Los ejercicios de modelar se resuelven escribiendo el diagrama Mermaid (o en
  papel con la misma notación) y, cuando se pide, el código de las clases.
- **Justificando cada flecha.** En este bloque, un diagrama sin multiplicidad o sin la razón de cada
  punta navegable vale la mitad.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Notación y traducción

**S1.** ¿Qué dice la punta de flecha de una asociación, y qué no dice? 🟢

**S2.** ¿Cuándo dibujas una dependencia en lugar de una asociación? 🟡

**S3.** Te piden dibujar todo el sistema en un diagrama. ¿Qué respondes? 🟡

**S4.** ¿Qué atributo genera cada multiplicidad del otro extremo: `"1"`, `"0..1"`, `"*"`? 🟢

**S5.** ¿`List`, `Set` o `Map` para los documentos de una persona? Justifica. 🟡

**S6.** ¿Cuándo una relación es una clase? 🟡

**S7.** ¿Qué no dibuja Mermaid, y cómo lo aproximas? 🟡

### Bloque B — Navegabilidad y propiedad

**S8.** ¿Qué pregunta haces antes de hacer navegable una punta? 🟢

**S9.** ¿Qué hace falta para que una bidireccional no se desincronice? 🟡

**S10.** ¿Por qué `@Data` en una entidad con relaciones es peligroso? 🟠

**S11.** ¿Quién es dueño de los documentos de Ana, y cómo se expresa en C++ y en Java? 🟡

**S12.** ¿Por qué `shared_ptr` no es el puntero por defecto? 🟠

**S13.** ¿Cuáles son las tres formas de no exponer una colección, y cuándo cada una? 🟡

**S14.** ¿Qué es una asociación reflexiva, y qué invariante trae la del tutor? 🟡

### Bloque C — Redundancia, valores y tablas

**S15.** "La redundancia siempre es mala." Responde. 🟠

**S16.** ¿Qué cachearías y qué calcularías: el saldo, la edad, la cantidad de documentos vigentes? 🟠

**S17.** ¿Entidad o valor: `Persona`, `Dinero`, `Direccion`, `Empleo`? 🟡

**S18.** ¿Por qué no `double` para dinero, y qué usas en Java y en C++? 🟡

**S19.** ¿Qué es la obsesión por los primitivos y cuál es la primera que atacarías en un sistema
bancario? 🟠

**S20.** ¿Subclases por tipo de documento o un `TipoDocumento`? 🟠

**S21.** ¿Por qué la navegación suele ir al revés que la FK? 🟡

**S22.** ¿Dónde va un objeto de valor en el esquema relacional? 🟡

**S23.** ¿Qué pasa si cargas dos veces la misma fila? 🟠

### Bloque D — Las que descolocan

**S24.** El entrevistador dice: "en mi equipo todas las relaciones son bidireccionales, así nunca falta
una navegación". ¿Qué le respondes? 🔴

**S25.** "Diseñamos primero las tablas y generamos las clases." ¿Qué riesgo ves y qué propones? 🔴

**S26.** "¿Para qué dibujar, si el código es la verdad?" 🔴

**S27.** Te piden modelar algo y no sabes si una relación es uno a varios o varios a varios. ¿Qué haces
en la entrevista? 🔴

**S28.** "Los objetos de valor son una moda de DDD; con un `String` basta." Responde. 🔴

**S29.** Un compañero quiere guardar el saldo de la cuenta y otro dice que es redundante. ¿Cómo lo
resuelves? 🔴

**S30.** "¿Por qué no usar siempre ids entre objetos, y así nunca hay problemas de ciclos?" 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Personas, documentos y empleos (modelar)

**Fuerza:** decidir multiplicidad y navegabilidad de cada punta, y justificarlas con casos de uso.

Modela en Mermaid: una persona tiene documentos de distintos tipos, emitidos por un país; puede tener un
tutor si es menor; trabaja en organizaciones, con cargo y fechas, y puede haber trabajado varias veces en
la misma. Los casos de uso son: mostrar los documentos de una persona, validar un documento contra su
tipo, mostrar el historial laboral de una persona y listar los empleados vigentes de una organización.

### E2 — El modelo con dos errores (revisar)

**Fuerza:** encontrar los errores de traducción y de propiedad, y priorizarlos.

```java
public class Documento {
    private List<TipoDocumento> tipos = new ArrayList<>();
    private Persona persona;
    public void setPersona(Persona p) { this.persona = p; }
}

public class Persona {
    private List<Documento> documentos = new ArrayList<>();
    public List<Documento> getDocumentos() { return documentos; }
}

// en un controlador
doc.setPersona(ana);
ana.getDocumentos().add(doc);
```

Nombra cada defecto, di cuál corriges primero y escribe la versión corregida.

### E3 — El documento principal (decidir una redundancia)

**Fuerza:** decidir si se guarda un dato redundante y quién lo mantiene.

El negocio pide que cada persona tenga un documento principal, elegido por ella, que aparece en todas
las pantallas y en todos los reportes. Decide si lo guardas, dónde y cómo se mantiene coherente con la
colección, y escribe los métodos de `Persona` que lo tocan.

### E4 — La cuenta con titulares (modelar y persistir)

**Fuerza:** traducir un varios a varios con datos al modelo de objetos y al esquema.

Una cuenta puede tener uno o varios titulares, cada uno con un porcentaje de participación; los
porcentajes suman 100. Dibuja el modelo en Mermaid, escribe las tablas mínimas, y di dónde se valida que
los porcentajes sumen 100.

### E5 — El teléfono de contacto (elegir, sin patrón)

**Fuerza:** reconocer que la respuesta correcta es un tipo pequeño y nada más.

El sistema guarda el teléfono de contacto de cada persona como `String`, y aparecen en la base
`"301 555 0101"`, `"+573015550101"` y `"(301) 555-0101"` para el mismo número. Diseña la solución.

---

## 4. 🧭 Las frases que hay que tener listas

> "La punta de flecha es navegabilidad: quién guarda la referencia. Y la decide un caso de uso, no la
> clave foránea."

> "Si la relación es bidireccional, una clase es la dueña y tiene la única puerta que fija las dos
> puntas."

> "La redundancia es aceptable si un único dueño la mantiene en la misma operación. Eso no es
> desnormalizar."

---

**Anterior:** [`07` — Objetos frente a tablas](07-objetos-frente-a-tablas.md) ·
**Siguiente:** [`09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`02` — De la asociación al código](02-de-la-asociacion-al-codigo.md)
