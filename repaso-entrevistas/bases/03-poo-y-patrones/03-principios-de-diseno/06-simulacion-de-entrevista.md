# 06 — Simulación de entrevista

> El examen del bloque `03-principios-de-diseno`: preguntas transversales que cruzan los cinco capítulos
> y cinco ejercicios de diseño de veinte minutos. Asume leídos los capítulos
> [`01`](01-encapsulacion-de-verdad.md) a [`05`](05-diseno-por-contrato.md). Las respuestas, en
> [`07` — Respuestas](07-respuestas.md#06--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Nombrando el dolor antes que la sigla.** En este bloque el entrevistador no quiere oír "viola el
  SRP": quiere oír qué duele, quién lo sufre y qué cuesta arreglarlo.
- **Tecleando.** Los ejercicios de refactorizar se resuelven escribiendo el código corregido, no
  describiéndolo.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Encapsulación y contratos

**S1.** ¿Por qué getters y setters no son encapsulación? 🟢

**S2.** Da un ejemplo de *tell, don't ask* con `Cuenta`. 🟡

**S3.** ¿Viola Demeter un `stream().filter().map()`? ¿Y un builder? 🟡

**S4.** ¿Dónde protegerías el invariante "el saldo nunca es negativo", y por qué no en el servicio? 🟡

**S5.** ¿`assert` o excepción para validar el monto de una transferencia? 🟡

**S6.** ¿Qué diferencia hay entre la validación del borde y la del modelo? 🟡

**S7.** ¿Por qué un invariante que depende del reloj recibe la fecha como parámetro? 🟠

### Bloque B — SOLID

**S8.** Define el SRP sin decir "una sola cosa". 🟢

**S9.** ¿Qué cumple OCP mejor: una estrategia por tipo de documento o una tabla de tipos? 🟠

**S10.** ¿Por qué un falso de pruebas puede violar LSP? 🟠

**S11.** ¿Qué es una interfaz de rol, y qué problema de ISP resuelve? 🟡

**S12.** ¿Hacia dónde apunta la dependencia en DIP, y dónde vive la interfaz? 🟡

**S13.** ¿Cuándo aplicar SOLID es ceremonia? 🟠

### Bloque C — GRASP, acoplamiento y dependencias

**S14.** ¿Qué es el Controller de GRASP, y por qué no es el `@RestController`? 🟡

**S15.** ¿Qué es una Pure Fabrication? Da dos del dominio. 🟢

**S16.** ¿Cuándo Information Expert da una mala respuesta? 🟠

**S17.** Nombra cuatro formas de acoplamiento con un ejemplo de cada una. 🟡

**S18.** ¿Qué es inyectar dependencias, y por qué no es Spring? 🟡

**S19.** ¿Qué se inyecta y qué se crea con `new`? 🟠

**S20.** ¿Por qué "más interfaces, menos acoplamiento" es falso? 🟠

**S21.** ¿Qué es una raíz de composición, y qué decide además en C++? 🟡

### Bloque D — Los lenguajes

**S22.** Java no tiene `const` en los métodos. ¿Qué haces para que un método de lectura no pueda mutar el
objeto? 🟠

**S23.** ¿Cómo se aplica DIP en C++ sin herencia? 🟠

**S24.** ¿Qué aportan los contratos de C++26, y por qué no sirven para validar entradas? 🟠

### Bloque E — Las que descolocan

**S25.** "En mi equipo seguimos SOLID al pie de la letra: cada clase tiene su interfaz." ¿Qué le dices? 🔴

**S26.** "¿Para qué sirve GRASP si ya sé SOLID?" 🔴

**S27.** El entrevistador defiende el modelo anémico: "es más simple y los servicios son más fáciles de
entender". ¿Cómo respondes sin entrar en guerra? 🔴

**S28.** "¿No es más rápido validar todo en el controlador y dejar el modelo limpio?" 🔴

**S29.** Te piden que identifiques "todos los principios violados" en una clase de 300 líneas. ¿Cómo
estructuras la respuesta? 🔴

**S30.** "¿Usarías un contenedor de inyección en un proyecto de tres clases?" 🔴

**S31.** "Demeter es una regla de estilo; nadie la cumple." ¿Estás de acuerdo? 🔴

**S32.** Te preguntan qué principio de diseño es el más importante. ¿Qué respondes? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — `ServicioPersonas` que lo viola todo (refactorizar)

**Fuerza:** decidir qué principio se arregla primero y por qué, antes de tocar código.

```java
public class ServicioPersonas {
    public static Map<String, Persona> cache = new HashMap<>();

    public void procesar(Persona p, int accion) {          // 1 = registrar, 2 = exportar, 3 = borrar
        if (accion == 1) {
            if (p.getFechaNacimiento().plusYears(18).isAfter(LocalDate.now()) && p.getTutor() == null)
                throw new RuntimeException("error");
            new JdbcTemplate(fuente()).update("INSERT INTO persona (nombre) VALUES (?)", p.getNombre());
            cache.put(p.getNombre(), p);
            new ClienteSmtp("smtp.example.com").enviar(p.getEmail(), "Bienvenida");
        } else if (accion == 2) {
            Files.writeString(Path.of("/tmp/" + p.getNombre() + ".csv"), p.getNombre() + ";" + p.getEmail());
        } else if (accion == 3) {
            new JdbcTemplate(fuente()).update("DELETE FROM persona WHERE nombre = ?", p.getNombre());
            cache.remove(p.getNombre());
        }
    }
}
```

Di qué principio se viola primero y por qué ese, y escribe el diseño corregido.

### E2 — La validación del tutor (elegir con GRASP)

**Fuerza:** asignar una responsabilidad nombrando los principios, y defender por qué no va en otro sitio.

El sistema registra personas por un API REST y por una importación nocturna de archivos. Un menor de
edad debe tener tutor. Decide con GRASP dónde va la validación, quién coordina el registro y quién guarda
la persona, y escribe las firmas.

### E3 — La encapsulación de `Cuenta` (revisar)

**Fuerza:** distinguir esconder campos de proteger invariantes en una revisión de código.

```java
public class Cuenta {
    private BigDecimal saldo;
    private String estado;
    private List<Movimiento> movimientos = new ArrayList<>();

    public BigDecimal getSaldo() { return saldo; }
    public void setSaldo(BigDecimal saldo) { this.saldo = saldo; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public List<Movimiento> getMovimientos() { return movimientos; }
}
```

Nombra los defectos por gravedad y escribe la versión encapsulada.

### E4 — Las dependencias del servicio (refactorizar)

**Fuerza:** sacar de una clase sus dependencias ocultas para poder probarla.

`ServicioTransferencias` crea su repositorio con `new`, consulta `LocalTime.now()`, llama a un
`Auditoria.registrar` estático y recibe un `boolean esReverso`. Escribe la versión con dependencias
explícitas, su raíz de composición y un test de la regla de horario.

### E5 — Edad para mostrar en pantalla (elegir, sin patrón)

**Fuerza:** reconocer que la respuesta correcta es un método de una línea.

Una pantalla necesita mostrar la edad de cada persona. Un compañero propone una interfaz
`CalculadoraEdad`, su implementación, una fábrica y un servicio `ServicioEdades` inyectado en el
controlador. Diseña la solución.

---

## 4. 🧭 Las frases que hay que tener listas

> "Encapsular es proteger invariantes, no esconder campos: las reglas van en los métodos que cambian el
> estado."

> "Cada principio de SOLID responde a un dolor concreto, y cada uno añade indirección. Los aplico donde
> está el dolor."

> "Inyecto por constructor lo volátil y ensamblo en una raíz de composición. Eso es inyección de
> dependencias; un contenedor solo la automatiza."

---

**Anterior:** [`05` — Diseño por contrato y *fail fast*](05-diseno-por-contrato.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`02` — SOLID sin catecismo](02-solid-sin-catecismo.md)
