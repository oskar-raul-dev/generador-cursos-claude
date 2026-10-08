# 06 — Simulación de entrevista

> El examen del bloque `12-antipatrones`, en el formato que más se usa para evaluarlo: **revisión de código en vivo**.
> Preguntas transversales y cinco fragmentos del dominio para revisar como si fueran un *pull request*. **Uno de ellos está
> bien y la respuesta correcta es aprobarlo.** Asume leídos los capítulos [`01`](01-code-smells-dentro-de-una-clase.md) a
> [`05`](05-antipatrones-de-codigo-y-de-proceso.md). Las respuestas, en [`07` — Respuestas](07-respuestas.md#06--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un fragmento: veinte minutos.
- **Como en una revisión de verdad.** Para cada fragmento: nombra los defectos con el nombre del catálogo, **priorízalos** (qué
  rompe dinero o datos primero, qué cuesta mantener después) y escribe **el primer paso**, no la reescritura completa.
- **Con la opción de aprobar.** Encontrar defectos donde no los hay también es un error de revisión. Si un fragmento está bien,
  se dice, y se dice por qué.
- **Con tono de revisión.** El entrevistador mira también cómo lo dices: el comentario que señala el costo y propone el paso es
  mejor que el que juzga al autor.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — *Code smells*

**S1.** ¿Qué es un *code smell*, y por qué no es un error? 🟢

**S2.** ¿Qué *smell* tiene un método que pasa siete parámetros de tipos primitivos? 🟢

**S3.** ¿Qué diferencia hay entre Divergent Change y Shotgun Surgery? 🟡

**S4.** ¿Cuándo un Middle Man no es un *smell*? 🟠

**S5.** ¿Qué hace la 2.ª ed. de *Refactoring* con *Switch Statements*? 🟡

**S6.** ¿Por qué un comentario puede ser desodorante? 🟡

### Bloque B — Antipatrones de diseño

**S7.** ¿Cómo sales de un God Object? 🟠

**S8.** ¿Cuándo el modelo anémico es aceptable? 🟠

**S9.** ¿Qué es Call Super y qué lo reemplaza? 🟢

**S10.** ¿Por qué Circle-Ellipse es un problema de mutabilidad? 🟠

**S11.** ¿Qué es Sequential Coupling? 🟢

### Bloque C — El patrón mal usado

**S12.** ¿Por qué un Service Locator no es inyección de dependencias? 🟡

**S13.** ¿Cómo reconoces *patternitis*? 🟠

**S14.** ¿Qué es el Golden Hammer? 🟢

**S15.** ¿Cuándo sobra una capa? 🟠

**S16.** ¿Qué es Abstraction Inversion? 🟡

### Bloque D — Código y proceso

**S17.** ¿Por qué no se reescribe un Big Ball of Mud? 🟠

**S18.** ¿Cómo decides si un código se puede borrar? 🟠

**S19.** ¿Cuándo dos fragmentos parecidos no deben unirse? 🟡

**S20.** ¿Qué haces con un número mágico que el negocio cambia? 🟡

### Bloque E — La revisión como práctica

**S21.** ¿Cómo priorizas los defectos de un *pull request*? 🟠

**S22.** ¿Qué es una prueba de caracterización y cuándo la escribes? 🟡

**S23.** ¿Qué pides en un *pull request* que refactoriza y cambia comportamiento a la vez? 🟠

**S24.** ¿Cómo escribes un comentario de revisión que no suene a juicio? 🟡

### Bloque F — Los lenguajes

**S25.** ¿Qué antipatrón de Java aparece distinto en C++? 🟡

**S26.** ¿Qué antipatrón es propio de quien escribe Java en Go? 🟡

### Bloque G — Las que descolocan

**S27.** "Este código tiene diez años y funciona: no lo toques." ¿Qué respondes? 🔴

**S28.** "Para no tener *smells*, usamos un analizador estático con todas las reglas activadas." ¿Qué riesgo ves? 🔴

**S29.** El autor del *pull request* responde a tu comentario con "así lo hace el resto del código". ¿Qué haces? 🔴

**S30.** El entrevistador te muestra código que escribiste tú hace años, con un God Object. ¿Cómo lo manejas? 🔴

---

## 3. 📐 Revisión de código en vivo

### E1 — El servicio que lo hace todo (revisar)

**Fuerza:** priorizar entre varios antipatrones y elegir el primer paso.

```java
@Service
public class ServicioCuentas {
    @Autowired private ApplicationContext contexto;

    public void retirar(String numeroCuenta, double monto) {
        RepositorioCuentas repo = contexto.getBean(RepositorioCuentas.class);
        Cuenta c = repo.buscar(numeroCuenta);
        if (c.getEstado().equals("ABIERTA")) {
            c.setSaldo(c.getSaldo() - monto);
            repo.guardar(c);
            Auditoria.instancia().registrar("retiro " + numeroCuenta + " " + monto);
        }
    }
}
```

### E2 — Las comisiones (revisar)

**Fuerza:** distinguir una regla duplicada de un parecido casual, y los literales con significado.

```java
// en TransferenciasController
double comision = monto * 0.005 + (urgente ? 2000 : 0);
// en ProcesoNocturnoComisiones
double comision = monto * 0.0055 + (urgente ? 2000 : 0);
// en SimuladorComisiones (pantalla de "cuánto me cobran")
double comision = monto * 0.005;
```

### E3 — La cuenta de nómina (revisar)

**Fuerza:** reconocer herencia mal usada y su contrato roto.

```java
public class CuentaAhorros {
    protected Dinero saldo;
    public void retirar(Dinero monto) { /* comprueba saldo y estado, registra el movimiento */ }
    public void depositar(Dinero monto) { saldo = saldo.mas(monto); }
    /** Las subclases deben llamar a super.alAbrir() al principio. */
    public void alAbrir() { registrarApertura(); }
}

public class CuentaNomina extends CuentaAhorros {
    @Override public void depositar(Dinero monto) {
        throw new UnsupportedOperationException("la nómina solo recibe depósitos del empleador");
    }
    @Override public void alAbrir() { asociarEmpleador(); }          // olvidó super.alAbrir()
}
```

### E4 — El extracto (revisar)

**Fuerza:** encontrar los *smells* de relación en un código que funciona.

```java
public Extracto generar(Cuenta c, YearMonth mes) {
    String ciudad = c.getTitular().getDireccionPrincipal().getCiudad().getNombre();
    BigDecimal interes = c.getSaldo().getMonto().multiply(c.getTasa()).divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_EVEN);
    List<Movimiento> movs = c.getMovimientos().stream()
            .filter(m -> YearMonth.from(m.getFecha()).equals(mes)).toList();
    return new Extracto(c.getTitular().getNombre(), ciudad, interes, movs);
}
```

### E5 — El retiro (revisar)

**Fuerza:** reconocer código que está bien y aprobarlo sin inventar defectos.

```java
public final class Cuenta {
    private final CuentaId id;
    private Dinero saldo;
    private EstadoCuenta estado;

    public Movimiento retirar(Dinero monto, Instant cuando) {
        if (estado != EstadoCuenta.ABIERTA) throw new CuentaNoDisponibleException(id, estado);
        Dinero nuevo = saldo.menos(monto);
        if (nuevo.esNegativo()) throw new SaldoInsuficienteException(id, monto);
        saldo = nuevo;
        return new Retiro(id, monto, cuando);
    }
}

@Service
public class RetirarFondos {
    private final RepositorioCuentas cuentas;
    private final Clock reloj;

    public RetirarFondos(RepositorioCuentas cuentas, Clock reloj) { this.cuentas = cuentas; this.reloj = reloj; }

    @Transactional
    public MovimientoId ejecutar(CuentaId id, Dinero monto) {
        Cuenta c = cuentas.cargar(id);
        Movimiento m = c.retirar(monto, reloj.instant());
        cuentas.guardar(c);
        return cuentas.registrar(m);
    }
}
```

---

## 4. 🧭 Las frases que hay que tener listas

> "Primero lo que rompe dinero o datos, después lo que encarece el cambio; y en cada comentario, el costo y el primer paso."

> "Al barro se le sale por partes, con pruebas de caracterización y sin dejar de funcionar; reescribir es el último recurso."

> "Este está bien: la regla vive en la entidad, las dependencias llegan por constructor y la transacción está en el servicio.
> Lo apruebo."

---

**Anterior:** [`05` — Antipatrones de código y de proceso](05-antipatrones-de-codigo-y-de-proceso.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`03` — Antipatrones de diseño OO](03-antipatrones-de-diseno-oo.md)
