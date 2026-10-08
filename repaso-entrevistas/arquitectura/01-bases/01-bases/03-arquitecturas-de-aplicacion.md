# 03 — Arquitecturas de aplicación

> Cómo se organiza el código **dentro** de un despliegue: capas, hexagonal, limpia,
> cebolla y vertical slice. Las cuatro últimas dicen casi lo mismo y el mérito está en
> saber en qué se diferencian de verdad y cuándo ninguna hace falta.
> Asume leído [`02` — Estilos de despliegue](02-estilos-de-despliegue.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tienes un `PedidoService` con 1.200 líneas. Dentro hay reglas de negocio, consultas JPA,
llamadas a una API de terceros y formateo de respuesta. Cambiar el proveedor de pagos
obliga a tocar la lógica de descuentos. Testear la regla de negocio exige levantar una
base de datos.

Eso no es un problema de nombres ni de paquetes: es que **la lógica de negocio depende
de la infraestructura**. Todo este capítulo ataca esa única frase, con cuatro
soluciones que comparten idea y difieren en forma.

> **Regla:** la lógica de negocio no debería saber si los datos vienen de Postgres, de
> un CSV o de un test. Si lo sabe, no puedes cambiar ninguno de los tres sin tocarla.

---

## 2. 🥞 Arquitectura en capas (N-tier)

**Qué es.** El clásico: presentación → negocio → acceso a datos. Cada capa conoce a la
de abajo y a ninguna otra. En Spring es `@RestController` → `@Service` → `@Repository`,
y es lo que tiene el 90 % de los sistemas reales.

```text
Controller  →  Service  →  Repository  →  BD
   ↓             ↓            ↓
  DTO         Entidad      Entidad      ← el problema: la entidad JPA sube hasta arriba
```

- El flujo es unidireccional hacia abajo, lo que la hace fácil de entender y de enseñar.
- **El defecto está en la flecha de la derecha**: la entidad de persistencia atraviesa
  las tres capas, así que la capa de negocio depende del modelo de la base de datos. Es
  el acoplamiento que hexagonal viene a romper.

**Cuándo sí.** CRUD, sistemas con poca lógica de dominio, equipos grandes con rotación
—todo el mundo la entiende sin explicación—, y cuando el costo de la ceremonia no se
justifica.

**Cuándo no.** Cuando el dominio tiene reglas complejas que quieres testear sin
infraestructura, o cuando la base de datos va a cambiar.

> ⚠️ **Advertencia.** El modo de fallo típico es el **"sinkhole antipattern"**: capas
> que solo pasan la llamada hacia abajo sin añadir nada. Si tu `@Service` solo llama al
> repositorio y devuelve, esa capa cuesta y no paga.

> **Veredicto:** no está obsoleta. Está **mal defendida**: es la opción correcta cuando
> la lógica es fina, y decirlo demuestra más criterio que proponer hexagonal siempre.

---

## 3. ⬡ Hexagonal (ports and adapters)

**Qué es.** Alistair Cockburn, 2005. El dominio en el centro, sin dependencias hacia
fuera. Todo lo externo entra por un **puerto** —una interfaz definida por el dominio— y
se conecta con un **adaptador** que implementa esa interfaz.

```text
     driving (primarios)              driven (secundarios)
  REST, CLI, test, cola   →  [ DOMINIO ]  →   JPA, API externa, Kafka
        adaptador           puerto  puerto        adaptador
```

- **Puerto primario (driving)**: el caso de uso que el dominio ofrece. Lo llaman desde
  fuera.
- **Puerto secundario (driven)**: lo que el dominio necesita. **Lo define el dominio y
  lo implementa la infraestructura** — ahí está la inversión de dependencias.

El único trozo de código que hace falta para entenderlo, y el que vale en entrevista:

```java
// Puerto: vive en el dominio. Habla de negocio, no de persistencia.
public interface RepositorioDePedidos {
    Optional<Pedido> porId(PedidoId id);
    void guardar(Pedido pedido);
}

// Adaptador: vive en infraestructura. Es el único que conoce JPA.
@Repository
class RepositorioDePedidosJpa implements RepositorioDePedidos { /* ... */ }
```

- Fíjate en **dónde vive la interfaz**: en el dominio, no junto a su implementación.
  Esa es toda la diferencia con capas, y es lo que invierte la flecha de dependencia.
- La firma habla de `Pedido` y `PedidoId`, no de `PedidoEntity`: el dominio no conoce el
  modelo de tablas.
- `RepositorioDePedidosJpa` no es público: fuera de infraestructura nadie debe poder
  nombrarlo.

**El precio**, que hay que decir en voz alta porque es la pregunta de seguimiento:

```text
+ Dominio testeable sin Spring, sin BD, sin contenedor
+ Cambiar la tecnología del borde no toca el dominio
− Dos modelos y un mapeo entre ellos (Pedido ↔ PedidoEntity)
− Más clases, más paquetes, más ceremonia
− En un CRUD, el mapeo es todo el trabajo y no aporta nada
```

**Cuándo sí.** Dominio con reglas propias; necesidad real de testear negocio sin
infraestructura; bordes que se sabe que van a cambiar.

**Cuándo no.** CRUD. Con reglas triviales, hexagonal es carpeta ceremonial.

> **Veredicto:** hexagonal se paga con mapeo. Si el dominio no tiene invariantes que
> proteger, estás pagando el mapeo y no comprando nada.

---

## 4. 🧱 Clean Architecture

**Qué es.** Robert C. Martin, 2012. Las mismas ideas en círculos concéntricos, con la
**regla de dependencia** como enunciado central: *el código fuente solo puede apuntar
hacia adentro*.

```text
Entidades  ←  Casos de uso  ←  Adaptadores de interfaz  ←  Frameworks y drivers
(reglas de   (reglas de       (controllers,               (Spring, JPA, la web,
 empresa)     aplicación)      presenters, gateways)        la BD)
```

**En qué se diferencia de hexagonal**, que es exactamente lo que se pregunta:

| | Hexagonal | Clean |
|---|---|---|
| Foco | Los **bordes**: puertos y adaptadores | Las **capas internas**: entidades vs casos de uso |
| Interior | Un dominio, sin subdividir | Distingue reglas de empresa de reglas de aplicación |
| Simetría | Simétrica: todos los bordes son iguales | Jerárquica: círculos con orden |
| Aporta | El mecanismo de inversión | El vocabulario de casos de uso y el cruce de fronteras |

> 🧠 **Modelo mental.** Hexagonal, limpia y cebolla son **la misma idea con distinto
> énfasis**: la dependencia apunta al dominio. Decir eso primero, y luego dar la
> diferencia de la tabla, es la respuesta completa. Decir solo que "son lo mismo" es
> media respuesta; decir que son cosas distintas es un error.

**Cuándo sí y cuándo no.** Igual que hexagonal, con un matiz: la separación
entidad/caso de uso rinde cuando varias aplicaciones comparten reglas de empresa.

> **Veredicto:** si el sistema es uno solo, la distinción entre entidades y casos de uso
> añade una capa que muchas veces no paga.

---

## 5. 🧅 Onion Architecture

**Qué es.** Jeffrey Palermo, 2008, **anterior a Clean** y muy parecida: capas
concéntricas —modelo de dominio, servicios de dominio, servicios de aplicación,
infraestructura— con las dependencias hacia el centro.

**Su aporte propio:** fue la primera en decir explícitamente que **las interfaces de
repositorio pertenecen al dominio**, no a la capa de datos.

**Cuándo sí.** En la práctica no se elige entre cebolla y limpia; se nombra para
demostrar que conoces la genealogía.

> **Veredicto:** es contexto histórico útil. Saber que Palermo (2008) precede a Martin
> (2012) y que ambos descienden de Cockburn (2005) demuestra lectura, no memoria.

---

## 6. 🔪 Vertical Slice Architecture

**Qué es.** Jimmy Bogard. La crítica moderna a las tres anteriores: organizar por
**caso de uso completo** en vez de por capa técnica. Cada rebanada tiene su request, su
lógica y su acceso a datos, y **no comparte abstracciones con las demás**.

```text
Por capas:                     Por rebanadas:
  controller/                    pedidos/crear/       ← todo lo de "crear pedido"
  service/                       pedidos/cancelar/    ← todo lo de "cancelar pedido"
  repository/                    pedidos/consultar/   ← una query directa, sin repositorio
```

- El argumento de fondo: **acoplas lo que cambia junto**. Un cambio en "crear pedido"
  toca un directorio, no tres.
- **Cada rebanada elige su propio nivel de abstracción**: la consulta puede ir con SQL
  directo mientras la creación usa el modelo de dominio completo. En capas eso es
  incoherencia; aquí es el objetivo.
- El precio es la duplicación entre rebanadas, aceptada a propósito.

**Cuándo sí.** Sistemas con casos de uso muy asimétricos —lecturas triviales, escrituras
complejas—; equipos que sufren el "abrir seis archivos para un cambio". Encaja de forma
natural con [CQRS](../03-datos/).

**Cuándo no.** Cuando las reglas de negocio se repiten entre rebanadas: ahí la
duplicación deja de ser barata.

> **Veredicto:** es la respuesta fuerte a *"¿siempre hexagonal?"*. Nombrarla demuestra
> que sigues el debate y no solo el canon de hace quince años.

---

## 7. 🧭 Cómo se elige

```text
¿Lógica de negocio fina, casi CRUD?          → Capas. Sin complejos.
¿Invariantes reales que proteger?            → Hexagonal.
¿Varias apps comparten reglas de empresa?    → Clean.
¿Casos de uso muy asimétricos entre sí?      → Vertical slice.
¿No sabes todavía?                           → Capas, y refactoriza cuando duela.
```

> **Regla de entrevista:** la respuesta que más puntúa no es el nombre del patrón. Es
> *"empezaría por capas y movería a hexagonal el módulo cuyas reglas necesite testear
> sin base de datos"*. Gradualidad y criterio, no doctrina.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Hexagonal y limpia son lo mismo" | Comparten la regla de dependencia; difieren en foco y en si subdividen el interior |
| "Hexagonal es tener tres paquetes" | Es dónde vive la **interfaz**; sin inversión, son carpetas |
| "El dominio no puede usar anotaciones" | Puede usar las de Java; lo que no debe es importar el framework |
| "Clean Architecture es de Uncle Bob y es la original" | Cockburn (2005) y Palermo (2008) son anteriores |
| "Las capas son obsoletas" | Son la opción correcta cuando la lógica es fina |
| "Con hexagonal cambio de BD fácil" | Cierto y casi nunca ocurre; el beneficio real es la testabilidad |

---

## 📚 Para profundizar

- **Libro** — Robert C. Martin, *Clean Architecture* (Prentice Hall, 2017). Capítulos
  17–22: fronteras, la regla de dependencia y los casos de uso.
- **Libro** — Tom Hombergs, *Get Your Hands Dirty on Clean Architecture*, 2ª ed.
  (Packt, 2023). **El más útil para esta entrevista**: implementa hexagonal en Spring
  Boot paquete por paquete, y dedica un capítulo al costo del mapeo.
- **Libro** — Mark Richards y Neal Ford, *Fundamentals of Software Architecture*,
  2ª ed. Capítulo 10: layered architecture y el sinkhole antipattern.
- Alistair Cockburn — [Hexagonal architecture](https://alistair.cockburn.us/hexagonal-architecture):
  el artículo original, con la intención del autor.
- Robert C. Martin — [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html):
  el post donde aparece el diagrama de los círculos.
- Jeffrey Palermo — [The Onion Architecture](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/):
  la fuente primaria de la cebolla.
- Jimmy Bogard — [Vertical Slice Architecture](https://www.jimmybogard.com/vertical-slice-architecture/):
  la crítica y la alternativa.
- **Tutorial** — Baeldung, «Hexagonal Architecture, DDD, and Spring»:
  el ejemplo en Java con puertos y adaptadores nombrados.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. Enuncia la regla de dependencia. 🟢
2. ¿Qué es un puerto y qué es un adaptador? 🟢
3. ¿Quién propuso hexagonal, cebolla y limpia, y en qué orden cronológico? 🟢
4. ¿Qué diferencia hay entre puerto primario y secundario? 🟡
5. ¿Dónde vive la interfaz del repositorio en hexagonal y por qué ahí? 🟡
6. ¿Qué es el sinkhole antipattern en arquitectura en capas? 🟡
7. ¿Qué es vertical slice architecture y contra qué argumenta? 🟡
8. En capas, ¿qué problema causa que la entidad JPA llegue al controller? 🟡
9. ¿Qué aporta Clean Architecture que hexagonal no dice? 🟠
10. ¿Cuál es el precio concreto de hexagonal, en código? 🟠
11. ¿Por qué "cambiar de base de datos fácilmente" es un mal argumento para
    hexagonal? 🟠
12. ¿Puede el dominio llevar anotaciones? ¿Cuáles sí y cuáles no? 🟠
13. ¿Cuándo hexagonal es "carpeta ceremonial"? 🟠
14. ¿Cómo verificas que nadie rompió la frontera del dominio? 🟠
15. ¿Qué gana y qué pierde vertical slice frente a hexagonal? 🟠
16. ¿Por qué vertical slice encaja bien con CQRS? 🟠
17. Tu `@Service` solo delega al repositorio. ¿Qué haces con esa capa? 🟠
18. En hexagonal, ¿dónde pones la transacción y por qué ahí? 🔴
19. Tienes un monolito en capas de 300k líneas. ¿Cómo introduces hexagonal sin
    reescribir? 🔴
20. Un compañero dice "hexagonal siempre, es la buena práctica". Rebátelo sin
    quedar como el que no quiere calidad. 🔴
21. Diseña la estructura de paquetes de un módulo de pagos en hexagonal, y di
    qué clase es pública y cuál no. 🔴

---

**Anterior:** [`02` — Estilos de despliegue](02-estilos-de-despliegue.md) ·
**Siguiente:** [`04` — Patrones GoF](04-patrones-gof.md) ·
**Relacionado:** [`07` — DDD táctico](07-ddd-tactico.md)
