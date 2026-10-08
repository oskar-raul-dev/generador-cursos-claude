# 08 — Simulación de entrevista

> El examen del bloque `05-estructurales`: preguntas transversales que cruzan los siete capítulos y cinco
> ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-adapter.md) a
> [`07`](07-flyweight.md). Las respuestas, en [`09` — Respuestas](09-respuestas.md#08--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Con la tabla de los tres en la cabeza.** La mitad de este bloque es distinguir patrones que tienen el mismo
  diagrama. Responde siempre por la **intención** —convertir, añadir, controlar, simplificar, separar, componer,
  compartir— y después por la estructura.
- **Dibujando.** Los ejercicios de modelar se resuelven con el diagrama Mermaid y las firmas, no con prosa.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Los que envuelven

**S1.** ¿Qué diferencia hay entre Adapter, Decorator y Proxy, en una frase cada uno? 🟡

**S2.** ¿Por qué `BufferedInputStream` es un Decorator e `InputStreamReader` un Adapter? 🟡

**S3.** ¿Qué diferencia hay entre adaptador de objeto y de clase? 🟡

**S4.** ¿Por qué importa el orden de los decoradores? 🟠

**S5.** ¿Qué problemas de identidad tienen los decoradores y los proxies? 🟠

**S6.** ¿Qué es un proxy dinámico, y qué límite tiene? 🟢

**S7.** ¿Por qué `@Transactional` no funciona en la llamada interna? 🟠

**S8.** ¿Por qué el Target de un Adapter lo define el dominio? 🟠

### Bloque B — Fachadas, puentes y árboles

**S9.** ¿Qué diferencia hay entre Facade y Adapter? 🟡

**S10.** ¿Qué diferencia hay entre Facade y Service Layer? 🟡

**S11.** ¿Cuándo una fachada se convierte en un God Object? 🟠

**S12.** ¿Qué problema resuelve el Bridge, y cómo lo reconoces en una jerarquía? 🟢

**S13.** ¿Qué diferencia hay entre Bridge y Strategy? 🟡

**S14.** ¿Qué diferencia hay entre transparencia y seguridad en el Composite? 🟡

**S15.** ¿Por qué "Composite es cualquier árbol" es impreciso? 🟠

### Bloque C — Compartir

**S16.** ¿Qué es el estado intrínseco y el extrínseco? 🟢

**S17.** ¿Por qué `Integer a = 200, b = 200; a == b` puede dar `false`? 🟠

**S18.** ¿Qué diferencia hay entre Flyweight y una caché? 🟡

### Bloque D — Los lenguajes

**S19.** ¿Qué es un *smart pointer* en términos de patrones? 🟢

**S20.** ¿Qué decide C++ en un Decorator o un Composite que Java no decide? 🟡

**S21.** ¿Por qué en Go el Adapter sobra a menudo? 🟡

**S22.** ¿Qué diferencia hay entre el Decorator del GoF y el `@decorator` de Python? 🟡

**S23.** ¿Qué es el pimpl de C++ y qué patrón es? 🟡

### Bloque E — Las que descolocan

**S24.** "Proxy, Decorator y Adapter son lo mismo: envoltorios." ¿Qué le respondes al entrevistador? 🔴

**S25.** "¿Para qué un adaptador si el SDK del proveedor ya tiene una interfaz?" 🔴

**S26.** "En nuestro equipo cada servicio externo tiene su fachada, su adaptador y su proxy." ¿Qué preguntas? 🔴

**S27.** El entrevistador dice que `@Transactional` en un método privado funciona "porque lo vio en un tutorial".
¿Cómo lo manejas? 🔴

**S28.** "¿Usarías Bridge para los avisos si hoy solo hay un canal?" 🔴

**S29.** Te piden un ejemplo de Flyweight que hayas escrito. ¿Qué respondes si nunca escribiste uno? 🔴

**S30.** "Los patrones estructurales son cosa de los años noventa; hoy todo es composición de funciones." ¿Estás de
acuerdo? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — ¿Proxy, Decorator o Adapter? (elegir)

**Fuerza:** nombrar el patrón por la intención y no por la forma, en tres fragmentos con el mismo diagrama.

```java
// A
class RepositorioPersonasConEventos implements RepositorioPersonas {
    private final RepositorioPersonas interno;
    private final PublicadorEventos eventos;
    public Optional<Persona> buscar(PersonaId id) { return interno.buscar(id); }
    public void guardar(Persona p) { interno.guardar(p); eventos.publicar(new PersonaGuardada(p.id())); }
}

// B
class RepositorioPersonasMongo implements RepositorioPersonas {
    private final MongoCollection<org.bson.Document> coleccion;
    public Optional<Persona> buscar(PersonaId id) {
        return Optional.ofNullable(coleccion.find(eq("_id", id.valor())).first()).map(MapeoPersona::desdeBson);
    }
    public void guardar(Persona p) { coleccion.replaceOne(eq("_id", p.id().valor()), MapeoPersona.aBson(p), opcionesUpsert); }
}

// C
class RepositorioPersonasSoloLectura implements RepositorioPersonas {
    private final RepositorioPersonas interno;
    public Optional<Persona> buscar(PersonaId id) { return interno.buscar(id); }
    public void guardar(Persona p) { throw new OperacionNoPermitidaException("réplica de solo lectura"); }
}
```

Di qué patrón es cada uno, y por qué.

### E2 — La auditoría del repositorio (diseñar)

**Fuerza:** elegir entre decorador escrito, proxy dinámico y AOP, y decidir el orden.

Hay que auditar todas las escrituras de los repositorios de personas, cuentas y documentos (tres interfaces, once
métodos de escritura en total), y reintentar los errores transitorios de la base. Diseña la solución, di dónde va
cada comportamiento en la pila y escribe lo esencial.

### E3 — Los avisos que se multiplican (revisar)

**Fuerza:** reconocer el producto de dos dimensiones en una revisión y proponer la salida en pasos.

Un *pull request* añade `AvisoVencidoWhatsapp`, `AvisoPorVencerWhatsapp` y `RecordatorioWhatsapp` a una jerarquía
que ya tiene nueve clases `Aviso<Tipo><Canal>`. Cada clase nueva copia el cliente de WhatsApp. Escribe el comentario
de revisión y el diseño que propones.

### E4 — El `ServicioFechas` (elegir, sin patrón)

**Fuerza:** reconocer que envolver una API estable es ceremonia.

Un compañero propone `ServicioFechas`, una fachada sobre `java.time` con `hoy()`, `sumarAnios(fecha, n)` y
`esAntes(a, b)`, "para no depender de la librería y poder probar". Diseña la solución.

### E5 — Las reglas de validación compuestas (modelar)

**Fuerza:** modelar una jerarquía parte-todo y decidir dónde va cada operación.

Las reglas de aceptación de un documento se combinan: "formato válido **y** (no vencido **o** con prórroga
vigente)". El negocio quiere definir combinaciones nuevas sin código, y el sistema tiene que decir **qué** regla
falló. Dibuja el modelo en Mermaid y escribe las clases.

---

## 4. 🧭 Las frases que hay que tener listas

> "Adapter convierte, Decorator añade, Proxy controla. Los tres envuelven; la intención es lo que los separa."

> "`@Transactional` lo aplica un proxy: la llamada por `this` no pasa por él, y no hay transacción."

> "Antes de un patrón estructural, pregunto si la pieza es mía: si lo es, la cambio; si es ajena y volátil, la
> adapto; si es estable, la uso tal cual."

---

**Anterior:** [`07` — Flyweight](07-flyweight.md) ·
**Siguiente:** [`09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`03` — Proxy, y los tres que se confunden](03-proxy.md)
