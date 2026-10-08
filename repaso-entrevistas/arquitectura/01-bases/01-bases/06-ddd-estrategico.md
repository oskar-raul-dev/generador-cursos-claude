# 06 — DDD estratégico

> La mitad del DDD que más se pregunta y menos se estudia. Contexto acotado, lenguaje
> ubicuo, subdominios y el mapa de contextos con sus patrones de relación. **La pregunta
> "¿cómo dividirías esto en microservicios?" se responde desde aquí**, no desde el
> catálogo de patrones.
> Asume leído [`05` — Fowler PoEAA](05-fowler-poeaa.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un banco tiene la palabra "cuenta". En originación es una solicitud con documentos; en
core es un saldo con movimientos; en cobranzas es una deuda con antigüedad; en marketing
es un segmento.

El intento obvio —un modelo canónico de `Cuenta` que sirva a todos— produce una clase
con ochenta campos donde cuarenta son `null` según quién la use. Ese modelo no pertenece
a nadie, todos deben coordinarse para cambiarlo, y nadie puede razonarlo entero.

DDD estratégico dice lo contrario: **no unifiques el modelo, delimita dónde vale cada
uno**.

> **Regla:** el mismo término puede significar cosas distintas en dos partes del sistema.
> Eso no es un error de diseño: es la señal de que hay dos contextos.

---

## 2. 🗣️ Lenguaje ubicuo

**Qué es.** Un vocabulario compartido entre negocio y desarrollo, **usado literalmente en
el código**. Si el negocio dice "póliza en suspensión", la clase se llama `Poliza` y
tiene un estado `SUSPENDIDA` — no `PolicyDTO` con `status = 3`.

**Por qué importa de verdad.** No es documentación: es un detector de errores. Cuando la
traducción entre lo que dice negocio y lo que dice el código cuesta, esa fricción está
señalando un malentendido del dominio que va a salir como bug.

**Cuándo sí.** Dentro de un contexto acotado, y solo ahí: **el lenguaje ubicuo no es
global**, es local por contexto. "Cuenta" significa otra cosa a tres metros de distancia
y eso es correcto.

> **Veredicto:** es el patrón más barato de aplicar y el que más rinde. No cuesta
> infraestructura, cuesta disciplina en los nombres.

---

## 3. 🧱 Contexto acotado (bounded context)

**Qué es.** La frontera dentro de la cual un modelo y su lenguaje son consistentes. Fuera
de esa frontera, los mismos términos significan otra cosa y hace falta traducción
explícita.

**Es la unidad de decisión de la frontera**, y de ahí salen tres consecuencias que
conviene decir seguidas en una entrevista:

```text
Un contexto acotado  →  un modelo consistente
                     →  un equipo que lo posee
                     →  el candidato natural a microservicio
```

- **No todo contexto tiene que ser un servicio.** Puede ser un módulo dentro de un
  monolito modular; la frontera es lógica antes que física.
- **Un servicio que abarca dos contextos** tiene dos modelos peleando dentro y terminará
  partiéndose.
- **Dos servicios dentro de un contexto** comparten modelo, así que comparten cambios: es
  acoplamiento con latencia añadida.

> 🧠 **Modelo mental.** El contexto acotado es la respuesta a *"¿por dónde corto?"*. La
> ley de Conway de [`01` §6](01-fundamentos-del-arquitecto.md#6--ley-de-conway) es la
> respuesta a *"¿por dónde voy a cortar de todos modos?"*. Un buen corte es donde ambas
> coinciden.

> **Veredicto:** el contexto acotado es una frontera de modelo, no de despliegue. Trazarlo
> cuesta conversaciones y se paga solo; convertirlo en servicio cuesta red, consistencia
> eventual y operación, y esa segunda decisión se toma aparte.

---

## 4. 🧩 Subdominios: núcleo, soporte y genérico

**Qué es.** La clasificación del negocio por **valor competitivo**, que es la que decide
dónde inviertes esfuerzo de diseño.

| Subdominio | Qué es | Qué haces con él |
|---|---|---|
| **Núcleo (core)** | La razón por la que el negocio gana dinero | Tu mejor gente, DDD táctico completo, se construye a medida |
| **Soporte** | Necesario, específico del negocio, no diferencial | Se construye simple; Transaction Script honesto |
| **Genérico** | Resuelto por el mercado | **Se compra.** No se construye |

Ejemplo en banca: el **motor de decisión de riesgo** es núcleo; la **gestión de
expedientes documentales** es soporte; **autenticación, facturación y notificaciones**
son genéricos y se compran.

> ⚠️ **Advertencia.** El error caro no es técnico: es construir a medida un subdominio
> genérico. Un equipo escribiendo su propio servicio de autenticación es dinero del
> núcleo gastado en algo que Keycloak o Cognito ya hacen mejor.

> **Veredicto:** *"¿es esto núcleo?"* es la pregunta que decide si el sobre-diseño está
> justificado. En el núcleo, la ceremonia de DDD se paga sola; fuera, es lastre.

---

## 5. 🗺️ Mapa de contextos

**Qué es.** El diagrama de los contextos y, sobre todo, **de la relación de poder entre
los equipos que los mantienen**. Es lo que distingue el mapa de un diagrama de cajas:
las flechas dicen quién se adapta a quién.

Los patrones de relación, con lo que significan en la práctica:

| Patrón | Relación | Cuándo aparece |
|---|---|---|
| **Socio (partnership)** | Dos equipos se coordinan de igual a igual | Ambos fallan o triunfan juntos |
| **Cliente-proveedor** | Aguas arriba/abajo, con el proveedor atendiendo necesidades del cliente | Lo normal y sano |
| **Conformista** | Aguas abajo acepta el modelo de arriba sin traducir | Cuando no tienes poder de negociación y el modelo es aceptable |
| **Capa anticorrupción (ACL)** | Aguas abajo traduce el modelo ajeno al propio | Legado, terceros, todo lo que no controlas |
| **Núcleo compartido** | Dos contextos comparten un subconjunto del modelo | Úsalo poco: acopla los ciclos de cambio |
| **Caminos separados** | Sin integración; se duplica a propósito | Cuando integrar cuesta más que duplicar |
| **Servicio de acceso público (OHS)** | El proveedor publica un protocolo estable | APIs con muchos consumidores |

### La capa anticorrupción, con detalle

Es el patrón que más aparece en banca y el que conviene tener listo:

```text
[ Tu dominio ]  ←  [ ACL: traduce ]  ←  [ Core bancario / ESB / tercero ]
   Cuenta            adaptador +            CTA-MAESTRA con 80 campos
   limpia            mapeo explícito        y códigos numéricos
```

- La ACL es **un Adapter con intención de arquitectura**: no solo cambia la firma,
  **traduce el modelo** y protege tu lenguaje ubicuo del de fuera.
- Su señal de que funciona: cuando el sistema externo cambia, tocas **solo** la ACL.
- Su precio: mapeo, duplicación de conceptos y una capa más que mantener.

> 💰 **Costo.** La ACL cuesta mapeo y latencia. Se paga sola cuando el sistema de arriba
> es inestable o su modelo es hostil; no se justifica contra un proveedor limpio y
> estable, donde conformista es más barato.

> **Veredicto:** el mapa de contextos vale por sus flechas, no por sus cajas. Un diagrama que no dice
> quién se adapta a quién es un organigrama sin jerarquía: bonito y sin información.

---
## 6. 🧭 Cómo se elige: de contextos a servicios

La secuencia completa para responder *"¿cómo dividirías este sistema?"*, que es la
pregunta que este capítulo existe para contestar:

```text
1. ¿Cuál es el lenguaje? ¿Dónde cambia el significado de un término?  → los contextos
2. ¿Cuál de ellos es núcleo?                                          → dónde invertir
3. ¿Qué equipo posee cada uno?                                        → Conway
4. ¿Qué relación tienen entre sí?                                     → el mapa
5. ¿Cuál duele lo bastante como para separarlo hoy?                   → el primer corte
```

> **Regla de entrevista:** nunca respondas con una lista de servicios. Responde con el
> **criterio** y luego aplícalo a uno. *"Separaría primero el contexto de riesgo, porque
> es núcleo, lo posee un equipo entero y su ciclo de despliegue está bloqueado por el
> resto"* vale diez veces más que enumerar ocho microservicios.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "DDD es tener entidades y repositorios" | Eso es DDD táctico; lo estratégico es dónde van las fronteras, y es lo que se pregunta |
| "Un modelo canónico para toda la empresa" | Es justo lo que el contexto acotado evita; produce el modelo de nadie |
| "Contexto acotado = microservicio" | Es candidato, no equivalencia: puede ser un módulo |
| "El lenguaje ubicuo es un glosario" | Es el vocabulario **en el código**; si solo está en Confluence, no existe |
| "Núcleo compartido evita duplicación" | Y acopla los ciclos de cambio de dos equipos; se usa poco y a conciencia |
| "Construimos nuestro propio SSO" | Subdominio genérico: se compra; construirlo gasta el presupuesto del núcleo |

---

## 📚 Para profundizar

- **Libro** — Eric Evans, *Domain-Driven Design* (Addison-Wesley, 2003). **Parte IV**,
  capítulos 14–17: contexto acotado, mapa de contextos y destilación del núcleo. La
  parte estratégica es el final del libro y es la que se pregunta.
- **Libro** — Vaughn Vernon, *Implementing Domain-Driven Design* (Addison-Wesley, 2013).
  Capítulos 2 y 3: la versión aplicable, con ejemplos de integración entre contextos.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). **El más
  accesible de los tres** y el más rápido para repasar: capítulos 1–4 cubren
  subdominios, contextos y el mapa con ejemplos modernos.
- Martin Fowler — [BoundedContext](https://martinfowler.com/bliki/BoundedContext.html):
  la definición en una página, citable de memoria.
- Martin Fowler — [UbiquitousLanguage](https://martinfowler.com/bliki/UbiquitousLanguage.html):
  ídem, con el argumento de por qué no es un glosario.
- [microservices.io — Decompose by subdomain](https://microservices.io/patterns/decomposition/decompose-by-subdomain.html)
  y [Decompose by business capability](https://microservices.io/patterns/decomposition/decompose-by-business-capability.html):
  los dos criterios de corte enfrentados.
- **Video** — GOTO Conferences, charlas de Eric Evans y de Vaughn Vernon sobre DDD
  estratégico; y *Domain-Driven Design Europe*, canal con el material de referencia.
  Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué es un contexto acotado? 🟢
2. ¿Qué es el lenguaje ubicuo y dónde tiene que vivir? 🟢
3. Nombra los tres tipos de subdominio y qué haces con cada uno. 🟢
4. ¿Es lo mismo un contexto acotado que un microservicio? 🟡
5. ¿Qué es una capa anticorrupción y contra qué protege? 🟡
6. Cita cuatro patrones de relación del mapa de contextos. 🟡
7. ¿Qué diferencia hay entre DDD estratégico y táctico? 🟡
8. ¿Qué diferencia a "conformista" de "capa anticorrupción"? 🟠
9. ¿Por qué el núcleo compartido se usa poco? 🟠
10. ¿Qué problema tiene un modelo canónico para toda la empresa? 🟠
11. ¿Por qué el lenguaje ubicuo no es global sino por contexto? 🟠
12. ¿Cuál es el error caro al clasificar un subdominio genérico? 🟠
13. ¿Cuándo "caminos separados" es la decisión correcta? 🟠
14. ¿Cómo se relaciona el contexto acotado con la ley de Conway? 🟠
15. ¿Qué señal te dice que una capa anticorrupción está funcionando? 🟠
16. ¿Qué pasa cuando un servicio abarca dos contextos acotados? 🟠
17. En un banco, "cuenta" significa cosas distintas en cuatro áreas. ¿Cómo lo
    modelas sin un canónico? 🔴
18. Diseña el mapa de contextos de un e-commerce y marca las relaciones. 🔴
19. Te piden integrar con un core bancario cuyo modelo es hostil y no cambiará.
    ¿Qué patrón aplicas y qué te cuesta? 🔴
20. ¿Cómo decides cuál de seis contextos separas primero? Da el criterio y
    aplícalo. 🔴
21. Negocio quiere reutilizar el modelo de "cliente" entre cuatro equipos.
    Argumenta a favor y en contra, y decide. 🔴

---

**Anterior:** [`05` — Fowler PoEAA](05-fowler-poeaa.md) ·
**Siguiente:** [`07` — DDD táctico](07-ddd-tactico.md) ·
**Relacionado:** [`02` — Estilos de despliegue](02-estilos-de-despliegue.md)
