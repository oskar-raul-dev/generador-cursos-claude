# 09 — Simulación de entrevista

> El examen del bloque `01-modelo-de-objetos`: preguntas transversales que cruzan los ocho capítulos y
> cinco ejercicios de diseño de veinte minutos. Asume leídos los capítulos
> [`01`](01-identidad-estado-y-referencias.md) a [`08`](08-la-ausencia-y-el-error.md). Las respuestas,
> en [`10` — Respuestas](10-respuestas.md#09--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** GCC 14.4 (C++23) · JDK 21.0.12, 17.0.20 y 25.0.4 (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **En voz alta, de verdad.** Leer la respuesta en silencio no entrena lo que se evalúa, que es
  decirla con orden mientras alguien te mira.
- **Tecleando o dibujando.** Los ejercicios se resuelven escribiendo el código o el diagrama, en un
  editor sin autocompletar o en papel, como en la pizarra.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta;
  los ejercicios tienen la solución desarrollada, con el primer diseño que sale y el bueno.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Referencias, igualdad y hash

**S1.** "Java pasa los objetos por referencia." Corrige la frase y demuéstralo con dos líneas. 🟡

**S2.** ¿Qué compara `==` en Java entre dos `String`, y por qué a veces da `true` con dos literales? 🟡

**S3.** Escribe el contrato de `hashCode` en una frase y di qué se rompe si lo incumples. 🟢

**S4.** ¿Por qué un `HashSet` puede "perder" un objeto que sigue dentro? 🟠

**S5.** Te piden igualdad para `Persona`. ¿Qué preguntas haces antes de escribir una línea? 🟠

**S6.** ¿Qué pasa con `equals` cuando una subclase añade un campo a la igualdad? 🟠

**S7.** ¿Qué tienen en común la clave mutable de un `HashSet` y un `TreeSet` ordenado por un campo que
cambia? 🟠

### Bloque B — Inmutabilidad, copia y ciclo de vida

**S8.** ¿Qué hace falta para que una clase sea inmutable en Java, además de `final` en los campos? 🟡

**S9.** "Mi record es inmutable." ¿Qué preguntas antes de creerlo? 🟡

**S10.** ¿Por qué `Integer` de 127 se compara bien con `==` y 128 no? 🟡

**S11.** ¿Qué diferencia hay entre `unmodifiableList` y `List.copyOf`, y cuándo eliges cada una? 🟡

**S12.** ¿Por qué `clone()` está desaconsejado y qué usas en su lugar? 🟡

**S13.** ¿Qué es la regla de 0 en C++, y por qué es la que se aplica casi siempre? 🟡

**S14.** ¿Por qué el GC no cierra archivos, y qué haces tú? 🟢

**S15.** ¿Qué pasa si llamas a un método sobrescribible desde un constructor, en Java y en C++? 🟠

### Bloque C — Polimorfismo y herencia

**S16.** ¿Quién elige la sobrecarga y quién la sobrescritura? 🟢

**S17.** Explica el *slicing* a alguien que solo programa en Java. 🟡

**S18.** ¿Por qué existe Visitor, en una frase? 🟡

**S19.** ¿Por qué "la herencia es para reutilizar código" es una mala regla, y cuál la reemplaza? 🟠

**S20.** Explica LSP con un ejemplo del dominio, sin cuadrados ni rectángulos. 🟠

**S21.** ¿Cómo resuelven el diamante C++, Java y Python? 🟠

**S22.** ¿Cuánto cuesta una llamada virtual, en C++ y en Java? 🟠

**S23.** ¿Cuándo prefieres una jerarquía `sealed` a una abierta? 🟠

### Bloque D — Genéricos, ausencia y error

**S24.** ¿Por qué `List<Pasaporte>` no es un `List<Documento>`, si los arreglos sí lo permiten? 🟡

**S25.** Explica PECS con un método del dominio. 🟡

**S26.** ¿Qué diferencia de fondo hay entre los genéricos de Java y las plantillas de C++? 🟠

**S27.** ¿Dónde usas `Optional` y dónde no? 🟡

**S28.** ¿*Checked* o *unchecked* para "saldo insuficiente"? Defiende las dos. 🟠

**S29.** ¿Qué aporta `std::expected` que no aporta una excepción? 🟠

### Bloque E — Las que descolocan

**S30.** "En mi equipo todas las clases tienen getters y setters para todos los campos, y `equals`
generado con todos los campos." ¿Qué le dices? 🔴

**S31.** El entrevistador insiste en que Java pasa los objetos por referencia porque "si muto el
parámetro, se ve fuera". ¿Cómo lo manejas sin entrar en una discusión? 🔴

**S32.** "¿Para qué sirve saber cómo es una vtable si nunca la vas a ver?" Responde. 🔴

**S33.** Te piden hacer inmutable una `Persona` que es una entidad con ciclo de vida. ¿Lo haces? 🔴

**S34.** "¿Por qué no usar `Optional` en todas partes y acabar con los `null`?" 🔴

**S35.** Un compañero propone que `Pasaporte`, `Cedula` y `TarjetaIdentidad` sean subclases de
`Documento`. ¿Qué preguntas haces antes de aprobarlo? 🔴

**S36.** "Las *checked exceptions* fueron un error de Java." ¿Estás de acuerdo? 🔴

**S37.** Nombras los cuatro pilares de la POO y el entrevistador repregunta: "¿y cuál quitarías?". 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — `Documento` como clave de mapa (modelar)

**Fuerza:** decidir qué campos definen la igualdad y protegerlos de la mutación.

Un servicio indexa los documentos de todas las personas en un `Map<Documento, Persona>` para responder
"¿de quién es este documento?". Escribe `Documento` en Java para que funcione como clave: igualdad,
hash, inmutabilidad, y qué pasa cuando un pasaporte se renueva o se corrige un número mal digitado.
Después, la versión C++ para un `std::unordered_map`.

### E2 — El *pull request* con dos bugs (revisar)

**Fuerza:** encontrar los defectos, nombrarlos y priorizarlos.

Revisa este código, nombra cada defecto con su nombre técnico y ordénalos por gravedad:

```java
public class Documento {
    private String numero;
    public void corregirNumero(String n) { this.numero = n; }
    @Override public boolean equals(Object o) {
        return o instanceof Documento d && numero.equals(d.numero);
    }
    @Override public int hashCode() { return numero.hashCode(); }
}

Set<Documento> verificados = new HashSet<>();
verificados.add(pasaporte);
pasaporte.corregirNumero("AQ482916");
```

```cpp
void archivar(Documento d, std::vector<Documento>& archivo) {
    d.validar();               // validar() es virtual y Pasaporte lo sobrescribe
    archivo.push_back(d);
}
```

### E3 — Persona y organización (elegir)

**Fuerza:** elegir entre herencia, interfaz y composición, con su precio.

Una `Cuenta` puede tener como titular a una `Persona` o a una `Organizacion`. Las dos tienen nombre,
direcciones y contactos. Un compañero propone `abstract class Parte` con esos campos. Decide el diseño,
dibújalo en Mermaid y di qué pierdes con tu elección.

### E4 — Validación por tipo de documento (refactorizar)

**Fuerza:** sacar la decisión del `switch` sin inventar una jerarquía que no hace falta.

```java
boolean esValido(Documento d) {
    switch (d.tipo().codigo()) {
        case "CC":     return d.numero().matches("\\d{6,10}");
        case "TI":     return d.numero().matches("\\d{10}") && !vencido(d);
        case "PAS-CO": return d.numero().matches("[A-Z]{2}\\d{6}") && !vencido(d);
        case "PAS-MX": return d.numero().matches("[A-Z]\\d{8}") && !vencido(d);
        default:       throw new IllegalArgumentException(d.tipo().codigo());
    }
}
```

Cada país nuevo añade un `case`. Refactoriza.

### E5 — El extracto de la cuenta (elegir, sin patrón)

**Fuerza:** reconocer que la respuesta correcta es el código directo.

Necesitas devolver desde un servicio el extracto de una cuenta: número de cuenta, titular, saldo
inicial, saldo final y la lista de movimientos del mes. Nadie lo modifica después de crearlo; se
muestra y se exporta. Diseña el tipo.

---

## 4. 🧭 Las frases que hay que tener listas

> "Java pasa referencias por valor: mutar el parámetro se ve fuera; reasignarlo, no."

> "`equals` y `hashCode` sobre la clave natural, los mismos campos en los dos, esos campos inmutables,
> y la clase `final` o un `record`."

> "Compongo por defecto; heredo solo si el subtipo cumple el contrato de la base y la base está hecha
> para heredarse."

---

**Anterior:** [`08` — La ausencia y el error en el modelo](08-la-ausencia-y-el-error.md) ·
**Siguiente:** [`10` — Respuestas](10-respuestas.md) ·
**Relacionado:** [`02` — Igualdad, identidad y hash](02-igualdad-identidad-y-hash.md)
