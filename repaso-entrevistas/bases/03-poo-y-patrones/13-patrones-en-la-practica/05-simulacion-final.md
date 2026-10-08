# 05 — Simulación final

> El examen del corpus entero: preguntas que cruzan los trece bloques y cinco ejercicios de diseño de veinte a treinta minutos,
> como en una entrevista técnica de Backend Senior, Arquitecto o Tech Lead. Asume leídos los bloques
> [`01`](../01-modelo-de-objetos/01-identidad-estado-y-referencias.md) a [`13`](01-patrones-en-spring.md), o la ruta que hayas
> elegido. Las respuestas, en [`06` — Respuestas](06-respuestas.md#05--simulación-final).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Como el día de la entrevista.** Cronómetro, en voz alta, y tecleando o dibujando de verdad: dos minutos por `S#`, veinte a treinta
  por ejercicio.
- **Con el orden del corpus.** El problema antes que el patrón; el precio de cada decisión en las cuatro monedas —indirección,
  acoplamiento, legibilidad, rendimiento—; y "no usaría ningún patrón" como respuesta legítima.
- **Con los datos de siempre.** Ana, Luis y Carmen, sus documentos y sus cuentas: usar los mismos datos hace que las trazas se sigan
  solas.
- **Solo después, el solucionario.** Muchas `S#` remiten a la respuesta de su bloque; las que cruzan bloques se responden aquí.

---

## 2. 🧠 Preguntas transversales

### Bloque A — El modelo de objetos

**S1.** ¿Java pasa los objetos por referencia? 🟢

**S2.** ¿Qué pasa si sobrescribes `equals` y no `hashCode`? 🟢

**S3.** ¿Por qué un campo usado en `hashCode` no debería cambiar? 🟠

**S4.** ¿Qué es el *slicing* en C++ y qué lo evita? 🟡

**S5.** ¿Cuándo usas `Optional`, cuándo un Null Object y cuándo una excepción? 🟠

### Bloque B — Modelado y principios

**S6.** ¿Cómo traduces a código una relación uno a varios entre `Persona` y `Documento`? 🟡

**S7.** ¿Qué es una entidad y qué es un objeto de valor? 🟢

**S8.** ¿Qué dice de verdad el principio de responsabilidad única? 🟠

**S9.** ¿Qué es la inyección de dependencias, y qué no es? 🟡

### Bloque C — Los patrones del GoF

**S10.** ¿Cuándo usarías un Singleton? 🟠

**S11.** ¿Qué diferencia hay entre Proxy, Decorator y Adapter? 🟡

**S12.** ¿Qué reemplaza al Visitor en Java 21? 🟡

**S13.** ¿Cuándo un Strategy es solo una lambda? 🟢

**S14.** ¿Por qué un Observer puede ser una fuga de memoria? 🟠

### Bloque D — Fowler y DDD

**S15.** ¿Transaction Script o Domain Model? 🟠

**S16.** ¿Qué es el `EntityManager` en términos de patrones? 🟡

**S17.** ¿Cómo evitas la actualización perdida entre dos peticiones? 🟠

**S18.** ¿Cómo repartes 1 000 COP entre tres titulares sin perder centavos? 🟠

**S19.** ¿Qué es un agregado y cómo lo delimitas? 🟠

**S20.** ¿Dónde va una regla que cruza dos cuentas? 🟡

### Bloque E — Concurrencia

**S21.** ¿Por qué el DCL sin `volatile` está roto? 🟠

**S22.** ¿Pool de hilos o *virtual threads*? 🟠

**S23.** ¿Por qué `wait` va en un `while`? 🟠

### Bloque F — Los diferentes

**S24.** ¿Por qué el *embedding* de Go no es herencia? 🟡

**S25.** ¿Qué garantiza TypeScript al ejecutar? 🟠

**S26.** ¿Es el `@decorator` de Python el patrón Decorator? 🟡

### Bloque G — Antipatrones y práctica

**S27.** ¿Cómo sales de un God Object? 🟠

**S28.** ¿Por qué un Service Locator no es inyección de dependencias? 🟡

**S29.** ¿Por qué no se reescribe un sistema que es un Big Ball of Mud? 🟠

**S30.** ¿Por qué `@Transactional` no funciona en una llamada interna? 🟠

**S31.** ¿Spring usa el patrón Singleton? 🟡

**S32.** ¿Se diseña con patrones desde el principio? 🟠

### Bloque H — Las que descolocan

**S33.** "Nombra los 23 patrones del GoF." ¿Qué haces? 🔴

**S34.** "Nuestro código no usa patrones; ¿es malo?" 🔴

**S35.** El entrevistador defiende que la herencia es la mejor forma de reutilizar código. ¿Cómo lo manejas sin chocar? 🔴

**S36.** "¿Cuál es el patrón más importante?" 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — El alta de punta a punta (modelar)

**Fuerza:** cruzar modelado, agregados, patrones de creación, persistencia, eventos y concurrencia en un solo diseño.

Diseña el alta de una persona con sus documentos y su primera cuenta: el API recibe nombre, fecha de nacimiento, documentos, correo,
el tutor si es menor, y el tipo de cuenta. Reglas: un documento por tipo, formato según el tipo, un menor necesita un tutor mayor, la
cuenta nace abierta y con saldo cero, y se avisa por correo al titular (y al tutor). Dibuja el modelo en Mermaid, di los agregados, el
DTO de entrada, el servicio de aplicación, la fábrica si la hay, la transacción, el evento y qué pasa si dos altas con el mismo
documento llegan a la vez.

### E2 — El *pull request* con tres antipatrones (revisar)

**Fuerza:** nombrar y priorizar defectos de bloques distintos en el mismo fragmento.

```java
public class GestorTransferencias {
    private static GestorTransferencias instancia;
    public static GestorTransferencias getInstance() {
        if (instancia == null) instancia = new GestorTransferencias();
        return instancia;
    }

    private final Map<String, Cuenta> cache = new HashMap<>();

    public void transferir(String origen, String destino, double monto) {
        Cuenta o = cache.computeIfAbsent(origen, repo::buscar);
        Cuenta d = cache.computeIfAbsent(destino, repo::buscar);
        o.setSaldo(o.getSaldo() - monto);
        d.setSaldo(d.getSaldo() + monto);
        repo.guardar(o);
        repo.guardar(d);
    }
}
```

Lo llaman doscientos hilos. Nombra los defectos con el bloque al que pertenece cada uno, priorízalos y escribe el primer paso.

### E3 — Tres requisitos nuevos (elegir)

**Fuerza:** elegir patrón o ninguno para requisitos distintos, con su precio.

1. Las comisiones cambian según el tipo de cuenta y, desde el mes que viene, también según el canal (app, oficina, corresponsal).
2. El área de cumplimiento quiere poder deshacer un bloqueo de cuenta hecho por error, con registro de quién y cuándo.
3. Cada vez que una cuenta se bloquea hay que avisar al titular, a su tutor si es menor y al área de riesgo, y mañana habrá más
   interesados.

Para cada uno: el patrón (o ninguno), por qué, y lo que cuesta.

### E4 — La edad de Luis (elegir, sin patrón)

**Fuerza:** resistir la tentación de un patrón donde basta un método.

Varias pantallas necesitan saber si una persona es menor de edad a una fecha. Un compañero propone una `EstrategiaCalculoEdad` con una
implementación por país, una fábrica y un Singleton que la entrega, "porque en otros países la mayoría de edad podría ser distinta".
Hoy el sistema opera solo en Colombia y México, ambos con 18 años. Diseña la solución.

### E5 — De un lenguaje a otro (traducir)

**Fuerza:** reconocer qué del diseño es del problema y qué es de Java.

El servicio de avisos de vencimiento está en Java con un Observer (`ApplicationEventPublisher` y oyentes), un Strategy por canal (correo,
SMS) y un Singleton para la configuración. Hay que reescribirlo en Go. Di qué queda, qué cambia de forma y qué desaparece, con el código
del corazón del diseño.

---

## 4. 🧭 Las frases que hay que tener listas

> "Antes de un patrón pregunto qué varía y cuántas variantes hay hoy; si hay una, código directo, y el patrón llega refactorizando."

> "Cada decisión, con su precio: indirección, acoplamiento, legibilidad y rendimiento. Y 'aquí no usaría ningún patrón' es una
> respuesta."

> "El patrón vive en el lenguaje y en el marco: la lambda, el `record`, el `switch` sellado, el proxy de Spring. Lo conozco para saber
> qué me dan y dónde muerden."

---

**Anterior:** [`04` — Cómo se elige](04-como-se-elige.md) ·
**Siguiente:** [`06` — Respuestas](06-respuestas.md) ·
**Relacionado:** [`12/06` — Simulación de entrevista](../12-antipatrones/06-simulacion-de-entrevista.md)
