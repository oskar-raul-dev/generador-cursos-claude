# 04 — Simulación de entrevista

> El examen del bloque `09-ddd-tactico-y-otros`: preguntas transversales que cruzan los tres capítulos y cinco ejercicios
> de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-entidad-valor-y-agregado.md) a
> [`03`](03-specification-null-object-y-type-object.md). Las respuestas, en
> [`05` — Respuestas](05-respuestas.md#04--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Dibujando la frontera.** En DDD táctico, el entrevistador quiere ver dónde trazas el agregado y por qué. Dibuja el
  diagrama en Mermaid o en papel, y di en voz alta qué invariante protege cada frontera.
- **Separando el vocabulario del código.** "Agregado", "servicio de dominio" o "evento" no son anotaciones de Spring.
  Cada respuesta tiene que poder decirse sin nombrar un marco, y luego aterrizarse en él.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Entidad y agregado

**S1.** ¿Qué hace de `Persona` una entidad y de `Dinero` un objeto de valor? 🟢

**S2.** ¿Qué es un agregado, y qué es su raíz? 🟢

**S3.** ¿Por qué un agregado no es "una entidad con sus hijos"? 🟡

**S4.** ¿Por qué entre agregados se referencia por identificador? 🟠

**S5.** ¿Por qué un repositorio por agregado y no por tabla? 🟡

**S6.** ¿Qué pasa si un agregado expone su colección interna? 🟠

**S7.** ¿Cómo decides si los movimientos entran en el agregado de `Cuenta`? 🟠

**S8.** ¿Qué relación hay entre el agregado y el bloqueo optimista? 🟡

### Bloque B — Eventos y servicios

**S9.** ¿Qué es un evento de dominio, y quién lo publica? 🟢

**S10.** ¿Por qué el correo de aviso va después del *commit*? 🟠

**S11.** ¿Qué diferencia hay entre un servicio de dominio y uno de aplicación? 🟡

**S12.** ¿Dónde va la regla de una transferencia entre dos cuentas? 🟠

**S13.** ¿Cómo pruebas un servicio de dominio? 🟡

**S14.** ¿Cuándo una fábrica de dominio sobra? 🟠

**S15.** ¿Qué diferencia hay entre un evento de dominio y un Observer? 🟡

### Bloque C — Specification, Null Object y Type Object

**S16.** ¿Qué es una Specification, y por qué en Java se parece tanto a un `Predicate`? 🟡

**S17.** ¿Cuándo usas un Null Object, cuándo `Optional` y cuándo una excepción? 🟠

**S18.** ¿Cuándo un Null Object esconde un error? 🟠

**S19.** ¿Qué es un Type Object y qué le cuesta frente a las subclases? 🟡

**S20.** ¿Cómo expresas en un Type Object una regla que no cabe en un dato? 🟠

**S21.** ¿Qué relación hay entre Null Object y Special Case? 🟡

**S22.** ¿Qué relación hay entre Specification, Composite e Interpreter? 🟠

### Bloque D — Los lenguajes

**S23.** ¿Qué te da EF Core para un agregado que JPA no te da? 🟡

**S24.** ¿Por qué el Null Object en C++ se lleva bien con las referencias? 🟡

### Bloque E — Las que descolocan

**S25.** "Hacemos DDD: todas nuestras clases tienen `@Entity` y los servicios tienen `@Service`." ¿Qué preguntas? 🔴

**S26.** "Pongamos a la persona, sus cuentas y sus movimientos en un solo agregado: así todo es coherente." ¿Qué respondes? 🔴

**S27.** "Los eventos de dominio son para microservicios; nosotros somos un monolito." ¿Estás de acuerdo? 🔴

**S28.** "Nunca modificamos dos agregados en una transacción." ¿Y la transferencia? 🔴

**S29.** "Prohibimos `null` en todo el código: Null Object en todas partes." ¿Qué riesgo ves? 🔴

**S30.** El entrevistador te dice que DDD es "demasiado para un CRUD". ¿Qué le contestas? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Los agregados de personas, documentos y cuentas (modelar)

**Fuerza:** trazar las fronteras por invariantes, no por relaciones del diagrama.

El sistema tiene personas con documentos, un tutor para los menores, cuentas con titulares, movimientos y
transferencias. Las reglas: un documento por tipo y persona; un menor tiene un tutor mayor de edad; el saldo de una
cuenta no queda negativo; una cuenta bloqueada no admite retiros. Dibuja los agregados en Mermaid, di qué invariante
protege cada uno, qué referencias son identificadores y qué operación cambia dos agregados.

### E2 — El documento de un país nuevo (elegir)

**Fuerza:** decidir entre subclases y Type Object con un caso que tiene un poco de lógica.

Perú pide aceptar su documento nacional de identidad (`DNI-PE`, ocho dígitos, vence a los ocho años de emitido) y su
carné de extranjería (`CE-PE`, nueve caracteres alfanuméricos, vence con el permiso de residencia, que es una fecha que
el propio documento trae). Un compañero propone dos subclases nuevas de `Documento`. Decide y justifica.

### E3 — El vencimiento que dispara tres cosas (diseñar)

**Fuerza:** separar el hecho de sus reacciones y decidir qué va en la transacción.

Cuando un documento vence hay que avisar a la persona, avisar al tutor si es menor, bloquear las cuentas de los menores
cuyo único documento venció, y dejar constancia en la auditoría. Hoy todo está en un método de cien líneas que corre de
noche. Diseña el evento, quién lo registra, quién lo publica, los manejadores y la fase de cada uno.

### E4 — "Documento vigente" en un solo sitio (elegir, sin patrón)

**Fuerza:** reconocer cuándo una regla no necesita un patrón.

La pantalla de la ficha de una persona marca en rojo los documentos vencidos. Es el único sitio del sistema que lo
necesita. Un compañero propone una `Especificacion<Documento>` con `y`, `o` y `no`, un `CompositeEspecificacion` y una
fábrica de especificaciones. Diseña la solución.

### E5 — El servicio que se llama de dominio (revisar)

**Fuerza:** distinguir un servicio de dominio de uno de aplicación en un *pull request*.

```java
@Service
public class ServicioDominioCuentas {
    @Autowired private CuentaRepository repo;
    @Autowired private JavaMailSender mail;

    @Transactional
    public void bloquearSiMenor(Long cuentaId) {
        Cuenta c = repo.findById(cuentaId).orElse(new CuentaNula());
        if (c.getTitular().getFechaNacimiento().plusYears(18).isAfter(LocalDate.now())) {
            c.setEstado("BLOQUEADA");
            mail.send(armarCorreo(c.getTitular().getEmail()));
        }
        repo.save(c);
    }
}
```

Nombra los defectos, priorízalos y escribe el primer paso de la corrección.

---

## 4. 🧭 Las frases que hay que tener listas

> "Trazo el agregado alrededor de una invariante, con la raíz como única puerta; fuera de él, solo identificadores, y un
> agregado por transacción salvo excepción declarada."

> "El agregado registra el evento; la infraestructura lo publica al guardar; lo externo reacciona después del *commit*."

> "Null Object cuando la ausencia es normal y su respuesta es la misma para todos; si falta algo que debía estar, lanzo."

---

**Anterior:** [`03` — Specification, Null Object y Type Object](03-specification-null-object-y-type-object.md) ·
**Siguiente:** [`05` — Respuestas](05-respuestas.md) ·
**Relacionado:** [`01` — Entidad, valor y agregado](01-entidad-valor-y-agregado.md)
