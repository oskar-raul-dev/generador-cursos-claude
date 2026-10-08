# 🧱 100 preguntas de entrevista — POO, SOLID y patrones de diseño

> **Nivel:** senior / arquitecto. Las respuestas son guías, no guiones: lo que evalúan es el **criterio**, no la definición.
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

---

## 🧩 Parte 1 — Fundamentos de POO (1–25)

**1. 🟢 ¿Qué son los cuatro pilares de la POO y cuál es el más importante?**
Encapsulamiento, abstracción, herencia y polimorfismo. La respuesta interesante es la jerarquía: el **encapsulamiento** es el que realmente sostiene el mantenimiento (te permite cambiar el interior sin romper a nadie), y el **polimorfismo** es el que da extensibilidad. La herencia es el más sobrevalorado de los cuatro y el que más daño hace mal usado.

**2. 🟢 Abstracción vs encapsulamiento: ¿en qué se diferencian?**
La abstracción es una decisión de **diseño**: qué expones conceptualmente y qué omites. El encapsulamiento es el **mecanismo** que la protege: modificadores de acceso, invariantes en el constructor, ausencia de setters. Puedes tener encapsulamiento sin buena abstracción (una clase con getters/setters privados pero modelo anémico).

**3. 🟡 ¿Por qué se dice "composición sobre herencia"?**
La herencia acopla en tiempo de compilación y expone la implementación del padre al hijo (rompe el encapsulamiento: es la "herencia frágil"). Un cambio en la clase base rompe subclases que no controlas. La composición se resuelve en tiempo de ejecución, permite cambiar comportamiento sin tocar jerarquías y compone varias capacidades. Regla práctica: hereda solo cuando la relación es genuinamente "es un" **y** el padre fue diseñado para herencia (documentado, con puntos de extensión).

**4. 🟡 ¿Qué es el problema de la clase base frágil?**
Cuando la clase base cambia su implementación interna (por ejemplo, `addAll` deja de llamar a `add`) y las subclases que dependían de ese detalle se rompen silenciosamente. El caso canónico es extender `ArrayList` para contar inserciones. Solución: composición y delegación, o diseñar explícitamente para herencia como pide Effective Java.

**5. 🟡 Sobrecarga (overloading) vs sobrescritura (overriding).**
La sobrecarga se resuelve en **compilación** por la firma (mismo nombre, distintos parámetros) y no es polimorfismo real. La sobrescritura se resuelve en **ejecución** por el tipo real del objeto. Trampa clásica: sobrecargar con `Object` y con un tipo concreto produce llamadas sorprendentes según el tipo declarado de la variable.

**6. 🟡 ¿Qué es el polimorfismo paramétrico frente al de subtipos?**
El de subtipos es el clásico de POO (una referencia de tipo padre apunta a un hijo). El paramétrico son los **genéricos**: el mismo código opera sobre tipos distintos con seguridad en compilación. Java tiene ambos, y además polimorfismo ad-hoc vía sobrecarga.

**7. 🟠 Explica el principio de sustitución de Liskov con un ejemplo que lo rompa.**
El clásico: `Square extends Rectangle`. Si `setWidth` de `Square` también cambia el alto, cualquier código que asuma el contrato de `Rectangle` (asignar ancho y alto independientes) se rompe. Formalmente: un subtipo no puede **fortalecer precondiciones** ni **debilitar postcondiciones** ni romper invariantes. Otro ejemplo real: una subclase que lanza `UnsupportedOperationException` en un método heredado (`Collections.unmodifiableList`) viola LSP técnicamente, aunque la librería estándar lo haga.

**8. 🟡 ¿Qué es una clase abstracta y cuándo la prefieres a una interfaz?**
Clase abstracta cuando hay **estado compartido** y una implementación parcial común con una relación "es un" fuerte. Interfaz cuando defines una capacidad o contrato y quieres múltiples implementaciones independientes. Con métodos `default` en interfaces desde Java 8 la frontera se difuminó, pero las interfaces siguen sin poder tener estado mutable, y eso es lo que decide.

**9. 🟡 ¿Por qué Java no tiene herencia múltiple de clases pero sí de interfaces?**
Para evitar el problema del diamante en el **estado** (¿qué copia del campo hereda?). Con interfaces solo se heredan contratos y, desde Java 8, implementaciones por defecto sin estado; si dos interfaces aportan el mismo `default`, el compilador **obliga** a resolver el conflicto explícitamente.

**10. 🟠 ¿Qué es un modelo de dominio anémico y por qué es un anti-patrón?**
Clases con solo getters y setters, y toda la lógica en servicios. Técnicamente funciona, pero desperdicia la POO: las invariantes del dominio quedan dispersas y nadie garantiza que un objeto esté en estado válido. El contraargumento honesto: en CRUDs simples el modelo anémico es más barato y perfectamente adecuado. El problema aparece cuando hay reglas de negocio ricas.

**11. 🟡 ¿Qué es un value object y cómo se diferencia de una entidad?**
El **value object** no tiene identidad: dos objetos con los mismos valores son el mismo (`Money(100, "COP")`). Es inmutable y se compara por valor. La **entidad** tiene identidad propia que persiste aunque cambien sus atributos (una cuenta bancaria). En Java moderno, los `record` son el vehículo natural para value objects.

**12. 🟡 ¿Por qué la inmutabilidad simplifica el diseño?**
Un objeto inmutable es automáticamente thread-safe, cacheable, seguro como clave de mapa y no necesita copias defensivas. Elimina toda una clase de bugs de aliasing. El coste real: presión de asignación y GC, y verbosidad al "modificar" (métodos `with...`).

**13. 🟠 ¿Qué es la ley de Demeter y cuál es su coste?**
"No hables con extraños": un método solo debe invocar sobre sí mismo, sus parámetros, sus campos y objetos que él crea. Evita cadenas `a.getB().getC().hacer()` que acoplan al cliente con toda la estructura interna. El coste: proliferación de métodos delegadores. Y hay excepciones legítimas: los builders fluidos y los streams violan la letra de la ley sin violar su espíritu.

**14. 🟡 ¿Qué es el acoplamiento y la cohesión? ¿Cómo los mides?**
Acoplamiento es cuánto depende un módulo de otros; cohesión, cuánto se relacionan entre sí los elementos de un módulo. Objetivo: alta cohesión, bajo acoplamiento. Se aproximan con métricas (acoplamiento aferente/eferente, inestabilidad, LCOM) que SonarQube reporta, pero la señal práctica es más simple: si un cambio de negocio toca seis paquetes, tienes poca cohesión.

**15. 🟡 ¿Qué es la inversión de dependencias y en qué se diferencia de la inyección?**
La **inversión** es un principio: los módulos de alto nivel no dependen de los de bajo nivel, ambos dependen de abstracciones, y la abstracción la define el consumidor. La **inyección** es una técnica para lograrla (y también se puede inyectar sin invertir nada, si inyectas una clase concreta). Confundirlas es el error más común en entrevistas.

**16. 🟠 ¿Cómo diseñas para la testabilidad?**
Dependencias explícitas por constructor, nada de `new` sobre colaboradores dentro de la lógica, nada de estáticos con estado, nada de singletons globales, y la infraestructura (reloj, aleatoriedad, sistema de archivos, red) detrás de interfaces. Si necesitas PowerMock para probar algo, el diseño te lo está diciendo.

**17. 🟡 ¿Qué es una interfaz de marcador y qué la reemplazó?**
Interfaces sin métodos que marcan una capacidad (`Serializable`, `Cloneable`). Las anotaciones las reemplazaron mayormente, aunque la interfaz sigue teniendo una ventaja: el compilador puede verificar el tipo, la anotación no.

**18. 🟠 ¿Por qué `Cloneable` se considera un error de diseño en Java?**
Es una interfaz de marcador que no declara `clone()`, `clone()` vive en `Object` y es `protected`, el comportamiento por defecto es copia superficial, y no llama al constructor (rompe invariantes y campos finales). La alternativa recomendada: constructor de copia o método factoría de copia.

**19. 🟡 ¿Qué es el principio "tell, don't ask"?**
En vez de preguntarle el estado a un objeto y decidir fuera, pídele que haga la operación. `cuenta.debitar(monto)` en lugar de `if (cuenta.getSaldo() >= monto) cuenta.setSaldo(...)`. Mantiene la invariante dentro del objeto que la posee, y es el antídoto directo contra el modelo anémico.

**20. 🟠 ¿Qué es el acoplamiento temporal y cómo lo eliminas?**
Cuando dos llamadas deben hacerse en cierto orden y nada lo obliga: `conf.setUrl(...); conf.conectar();`. Si olvidas la primera, falla en ejecución. Se elimina haciendo imposible el estado inválido: exige los datos en el constructor, o usa un builder que solo produzca objetos válidos.

**21. 🟡 Herencia de implementación vs herencia de interfaz.**
La de interfaz (implementar un contrato) es casi siempre segura. La de implementación (extender una clase para reutilizar código) es la peligrosa: acopla, rompe encapsulamiento y limita a una sola jerarquía. Reutilizar código no es motivo suficiente para heredar; para eso está la composición.

**22. 🟠 ¿Qué es la covarianza y la contravarianza? Explica PECS.**
"Producer Extends, Consumer Super". `List<? extends T>` sirve para **leer** T (productor); `List<? super T>` para **escribir** T (consumidor). Los arrays en Java son covariantes (`Object[] a = new String[1]`) y eso permite `ArrayStoreException` en ejecución — uno de los errores de diseño históricos del lenguaje que los genéricos corrigieron con invarianza.

**23. 🟡 ¿Qué es el borrado de tipos (type erasure) y qué implica?**
Los genéricos existen solo en compilación; en ejecución `List<String>` es `List`. Implicaciones: no puedes hacer `new T[]`, no puedes sobrecargar por parámetro genérico, `instanceof List<String>` no compila, y necesitas trucos como `Class<T>` o `TypeReference` para conservar el tipo.

**24. 🟠 ¿Qué es un objeto nulo (Null Object) y cuándo lo usas?**
Una implementación que no hace nada pero cumple el contrato, para evitar comprobaciones de null por todas partes (un `NoOpAuditLogger`, por ejemplo). Úsalo cuando "ausencia" tiene un comportamiento por defecto sensato; **no** lo uses cuando la ausencia es un error que debe explotar, porque esconderás bugs.

**25. 🔴 ¿Cuándo la POO es la herramienta equivocada?**
Respuesta madura y valorada: en transformaciones de datos puras (ahí gana el estilo funcional), en cálculo numérico intensivo (ahí gana el orientado a datos y la localidad de memoria), en scripts pequeños, y en dominios donde el estado es esencialmente inmutable. Java moderno con `record`, `sealed` y pattern matching se ha movido deliberadamente hacia un estilo más orientado a datos para estos casos.

---

## ⚖️ Parte 2 — SOLID y principios de diseño (26–50)

**26. 🟢 ¿Qué significa SOLID y cuál usas más en la práctica?**
SRP, OCP, LSP, ISP, DIP. En la práctica, SRP y DIP son los que más impacto diario tienen: uno decide cómo cortas las clases, el otro decide si puedes probarlas. OCP y LSP aparecen sobre todo al diseñar librerías y jerarquías.

**27. 🟡 Single Responsibility: ¿cómo defines "una responsabilidad"?**
La formulación útil de Uncle Bob no es "hace una sola cosa", sino **"una sola razón para cambiar", es decir, un solo actor o stakeholder**. Una clase `Empleado` con `calcularPago()` (finanzas), `guardar()` (DBA) y `reportarHoras()` (RRHH) tiene tres actores y por tanto tres responsabilidades, aunque las tres cosas sean "sobre el empleado".

**28. 🟠 ¿Cuál es el riesgo de aplicar SRP al extremo?**
Explosión de clases diminutas donde seguir un flujo exige abrir quince archivos. El acoplamiento se desplaza de dentro de la clase a la red de colaboraciones, que es más difícil de ver. El criterio de equilibrio: separa cuando las razones de cambio se han manifestado de verdad, no de forma especulativa.

**29. 🟡 Open/Closed: ¿cómo lo logras en Java?**
Abierto a extensión, cerrado a modificación. Mecanismos: polimorfismo (Strategy), composición, y puntos de extensión explícitos (Template Method, hooks). En Spring, una `List<Validador>` inyectada por el contenedor es OCP puro: agregar un validador nuevo no toca ninguna clase existente.

**30. 🟠 ¿Cuándo OCP hace más daño que bien?**
Cuando abstraes para una variación que nunca llega. Terminas con una jerarquía de interfaces con una sola implementación, que es coste puro sin beneficio. Mejor criterio: la primera vez escribes el `if`; a la segunda variación real, refactorizas a Strategy. Esa es la tensión sana entre OCP y YAGNI.

**31. 🟡 Interface Segregation: ejemplo concreto.**
Ningún cliente debe depender de métodos que no usa. El ejemplo clásico es una interfaz `Repositorio` con quince métodos donde un consumidor solo necesita `findById`: cualquier cambio en los otros catorce lo recompila y lo acopla. La solución son interfaces por rol (`BuscadorDeCuentas`, `EscritorDeCuentas`), definidas **por el consumidor**.

**32. 🟠 ¿Cómo se relacionan ISP y DIP?**
ISP dice que las interfaces sean pequeñas y por rol; DIP dice que la abstracción la posea el módulo de alto nivel. Juntos producen el patrón de **puertos** en arquitectura hexagonal: el dominio declara la interfaz que necesita, mínima y en su propio lenguaje, y la infraestructura la implementa. Si tu interfaz de repositorio se llama igual que tu ORM, no aplicaste ninguno de los dos.

**33. 🟡 ¿Qué es DRY y cuándo violarlo es correcto?**
DRY es sobre **conocimiento**, no sobre texto: dos fragmentos idénticos que representan reglas de negocio distintas deben permanecer duplicados porque evolucionarán por separado. Abstraer una coincidencia accidental crea un acoplamiento falso, y es peor que la duplicación. De ahí el dicho "duplicación es más barata que la abstracción equivocada".

**34. 🟡 KISS, YAGNI y el principio de menor sorpresa.**
KISS: la solución simple que funciona gana. YAGNI: no construyas para requisitos hipotéticos. Menor sorpresa: el código debe comportarse como su nombre sugiere. Los tres son contrapesos a la tendencia del arquitecto a sobrediseñar, y mencionarlos como contrapeso de SOLID demuestra madurez.

**35. 🟠 ¿Qué es la separación comando-consulta (CQS)?**
Un método o cambia estado (comando, devuelve void) o devuelve información (consulta, sin efectos), nunca ambas. Hace el código razonable y cacheable. La excepción pragmática universal: `stack.pop()`. CQRS es la versión arquitectónica del mismo principio, aplicada a modelos de lectura y escritura separados.

**36. 🟡 ¿Qué es el principio de responsabilidad única aplicado a un microservicio?**
El mismo criterio, otro nivel: un servicio debe tener una razón de cambio, es decir, pertenecer a un bounded context. Si dos áreas de negocio distintas piden cambios sobre el mismo servicio cada sprint, el corte está mal hecho.

**37. 🟠 Principios de paquetes: REP, CCP, CRP.**
Reuse/Release Equivalence (la unidad de reutilización es la unidad de release), Common Closure (lo que cambia junto va junto) y Common Reuse (lo que no se reutiliza junto no va junto). Son SRP, OCP e ISP escalados a módulos, y son la base para decidir fronteras de librería o de servicio.

**38. 🟠 ¿Qué son la dependencia acíclica y la métrica de inestabilidad?**
El grafo de dependencias entre paquetes no debe tener ciclos (se rompen con DIP o extrayendo una abstracción común). La inestabilidad I = Ce/(Ca+Ce): los paquetes estables deben ser abstractos y los inestables concretos. ArchUnit permite verificar ambas cosas automáticamente en el pipeline, y mencionarlo suma mucho.

**39. 🟡 ¿Qué es "composition root"?**
El único lugar de la aplicación donde se conoce cómo se ensamblan las dependencias concretas: el `main` o la configuración de Spring. El resto del código nunca instancia infraestructura. Si tienes `new` de un cliente HTTP dentro de un servicio de dominio, no tienes composition root.

**40. 🟠 SOLID en un mundo funcional: ¿siguen aplicando?**
Sí, traducidos: SRP es una función pequeña; OCP es pasar funciones como parámetros; LSP es la ley de sustitución de tipos; ISP son firmas mínimas; DIP es la inyección de funciones en vez de interfaces. En Java moderno, un `Function<A,B>` inyectado es DIP con una sola línea en vez de una interfaz.

**41. 🟠 ¿Cómo detectas una violación de SRP en una revisión de código?**
Señales concretas: el nombre de la clase contiene "y" o termina en "Manager"/"Helper"/"Util"; el archivo supera varios cientos de líneas; los imports mezclan capas (JDBC y HTTP en la misma clase); las pruebas necesitan preparar cinco mocks no relacionados. Ese último es el detector más fiable.

**42. 🟡 ¿Qué es un code smell? Nombra cinco que te hagan rechazar un PR.**
Método largo, clase grande, lista larga de parámetros, envidia de características (un método que usa más datos de otra clase que de la suya), obsesión por primitivos (pasar `String` donde debería haber un value object), y `switch` repetido sobre el mismo enum en varios lugares (candidato claro a polimorfismo).

**43. 🟠 ¿Cuándo un `switch` es mejor que polimorfismo?**
Cuando el conjunto de casos es cerrado y estable, y la lógica es de coordinación, no de dominio. Con `sealed interface` + pattern matching (Java 17+) el compilador verifica exhaustividad, lo que da una seguridad que el polimorfismo clásico no ofrece: si agregas un subtipo, el `switch` deja de compilar. Ese es el argumento moderno a favor del switch para jerarquías cerradas.

**44. 🟠 ¿Qué es el principio Hollywood y cómo se relaciona con IoC?**
"No nos llames, nosotros te llamamos". El framework controla el flujo y llama a tu código en los puntos de extensión. Es la esencia de la inversión de control: pasas de escribir un programa que usa librerías a escribir piezas que un contenedor orquesta.

**45. 🔴 Te dicen "aplicamos SOLID" pero el código es difícil de cambiar. ¿Qué buscas?**
Busca SOLID de cargo culto: interfaces con una sola implementación creadas por reflejo, capas de mapeo que no aportan nada, indirección que no permite ninguna sustitución real, y clases pequeñas pero acopladas por un modelo de datos compartido. SOLID no es un fin: el fin es que el cambio sea barato. Si no lo es, el SOLID es decorativo.

**46. 🟠 ¿Qué es la "arquitectura gritona" (screaming architecture)?**
La estructura de paquetes debe gritar el dominio (`prestamos`, `originacion`, `cobranza`), no el framework (`controllers`, `services`, `repositories`). Al abrir el repositorio debes saber de qué trata el negocio, no qué framework usa.

**47. 🟡 ¿Qué es el acoplamiento por contenido, por datos y por control?**
De peor a mejor: por contenido (un módulo toca las entrañas de otro), común (estado global compartido), de control (pasas una bandera que decide el flujo del otro), de estampa (pasas una estructura entera cuando solo se usa un campo) y de datos (pasas exactamente lo necesario). El de control se detecta fácil: un parámetro booleano que parte el método en dos.

**48. 🟠 ¿Por qué un parámetro booleano es un smell?**
Porque significa que el método hace dos cosas y el llamador está eligiendo cuál (acoplamiento de control), y porque en el sitio de llamada `procesar(cliente, true)` es ilegible. Soluciones: dos métodos con nombres claros, o un enum que dé semántica.

**49. 🟠 ¿Cómo aplicarías SOLID a un código legacy sin pruebas?**
Primero red de seguridad: pruebas de caracterización. Después, refactorizaciones seguras y pequeñas (extraer método, extraer clase, introducir parámetro) para crear costuras (seams) donde inyectar dependencias. El orden importa: DIP primero, porque es lo que te permite aislar y probar; el resto viene solo.

**50. 🔴 Si tuvieras que quedarte con un solo principio de diseño, ¿cuál sería y por qué?**
Respuesta defendible: **bajo acoplamiento**. Casi todos los demás principios son estrategias para conseguirlo, y es el que determina directamente el coste del cambio, que es la única métrica que importa a largo plazo. Alternativa igual de válida: "hacer imposible el estado inválido", porque elimina categorías enteras de bugs en vez de detectarlas.

---

## 🏗️ Parte 3 — Patrones creacionales (51–63)

**51. 🟢 ¿Qué problema resuelve el patrón Singleton y por qué tiene mala fama?**
Garantiza una única instancia con acceso global. Mala fama porque es estado global disfrazado: acopla a todos sus clientes, arruina la testabilidad (no puedes sustituirlo), y en concurrencia hay que implementarlo bien. En una aplicación Spring casi nunca lo escribes a mano: un bean singleton gestionado por el contenedor te da la unicidad **sin** el acceso global, que es la parte tóxica.

**52. 🟡 ¿Cómo implementas un Singleton thread-safe en Java?**
La forma recomendada por Effective Java es un **enum de un solo valor**: la JVM garantiza unicidad, incluso ante serialización y reflexión. Alternativas: holder idiom (clase interna estática, aprovecha la inicialización perezosa del cargador de clases) o double-checked locking con `volatile` (funciona desde Java 5, pero es innecesariamente frágil).

**53. 🟡 Factory Method vs Abstract Factory.**
Factory Method: un método (normalmente en una subclase) decide qué instancia crear de **un** producto. Abstract Factory: una interfaz que crea **familias** de productos relacionados y compatibles entre sí (todos los componentes de un mismo tema visual, o todos los drivers de un mismo proveedor). Si solo tienes un producto, Abstract Factory es sobrediseño.

**54. 🟡 ¿Cuándo usas Builder y qué ventaja tiene sobre el constructor telescópico?**
Cuando hay muchos parámetros, varios opcionales, y quieres legibilidad en el sitio de llamada más un objeto inmutable al final. Ventaja sobre constructores telescópicos: no confundes dos `String` consecutivos, y puedes validar invariantes en `build()`. Ojo con Lombok `@Builder`: es cómodo, pero deja crear objetos inválidos si no añades validación.

**55. 🟠 ¿Cuál es el riesgo de `@Builder` de Lombok en entidades de dominio?**
Permite construir objetos con campos obligatorios en null, lo que anula la invariante del constructor. En dominio, prefiere un constructor que exija lo obligatorio y builder solo para lo opcional, o valida dentro de `build()`. La comodidad no debe costarte la garantía de validez.

**56. 🟡 Prototype: ¿sigue siendo útil en Java?**
Su idea (crear clonando en vez de construyendo) es útil cuando la construcción es cara o la configuración compleja. En Java se implementa con constructor de copia, no con `Cloneable`. Caso real: partir de una plantilla de configuración y derivar variantes.

**57. 🟠 ¿Qué es el patrón Object Pool y cuándo vale la pena?**
Reutilizar objetos caros de crear en vez de construirlos y destruirlos. Válido para conexiones (HikariCP), hilos, buffers grandes. **No** vale la pena para objetos ordinarios: el GC generacional de Java es extremadamente eficiente con objetos de vida corta, y un pool casero suele ser más lento y más buggy que el `new`.

**58. 🟡 ¿Qué es una factoría estática y qué ventajas tiene sobre un constructor?**
Tiene nombre (`Money.ofCents(100)` vs un constructor ambiguo), puede devolver instancias cacheadas (`Integer.valueOf`), puede devolver subtipos, y puede evitar la creación si no hace falta. Desventaja: no se puede heredar si el constructor es privado, y es menos descubrible que un `new`.

**59. 🟠 Dependency Injection: constructor, setter o campo. ¿Cuál y por qué?**
Constructor, por defecto: dependencias obligatorias y explícitas, campos finales, objeto siempre válido, testeable sin contenedor, y las dependencias circulares fallan al arrancar en vez de esconderse. Setter solo para lo genuinamente opcional o reconfigurable. Inyección por campo: cómoda y mala — oculta dependencias y obliga a reflexión para probar.

**60. 🟠 ¿Qué es el Service Locator y por qué se considera inferior a DI?**
Un registro global del que los objetos piden sus dependencias. Es inferior porque las dependencias quedan **ocultas**: la firma del constructor no te dice de qué depende la clase, y solo lo descubres leyendo el cuerpo o fallando en ejecución. Además acopla todo al localizador. Se sigue viendo en código legacy y en frameworks sin contenedor.

**61. 🟡 ¿Qué es la inicialización perezosa y qué riesgos tiene?**
Crear el objeto en el primer uso. Riesgos: condiciones de carrera si no se sincroniza, y trasladar fallos de arranque a tiempo de ejecución (un bean que falla al inicializarse lo descubres en producción con el primer usuario, no en el despliegue). En Spring, `@Lazy` acelera el arranque a cambio de esa incertidumbre.

**62. 🟠 ¿Cómo creas objetos cuando el tipo depende de datos en tiempo de ejecución?**
Registro de factorías: un `Map<TipoOperacion, Supplier<Handler>>` poblado en el arranque, o en Spring inyectando `Map<String, Handler>` (el contenedor lo llena con el nombre del bean como clave). Evita el `switch` gigante y cumple OCP: añadir un tipo es añadir un bean.

**63. 🔴 Diseña la creación de objetos para un sistema de productos financieros donde cada producto tiene reglas distintas de validación, cálculo y contabilización.**
Abstract Factory o un registro de factorías por tipo de producto, devolviendo una familia coherente (validador + calculadora + contabilizador). Clave: la familia debe ser **consistente**, no puedes mezclar el validador de un producto con la calculadora de otro. Complementa con `sealed` para cerrar el conjunto de tipos y que el compilador verifique exhaustividad, y con configuración externa si los productos se dan de alta sin desplegar.

---

## 🧬 Parte 4 — Patrones estructurales (64–76)

**64. 🟡 Adapter: ¿cuándo lo usas?**
Cuando necesitas que una clase existente cumpla una interfaz que no implementa, típicamente al integrar una librería de terceros o un sistema legacy. Es el patrón que protege tu dominio de las APIs ajenas: en arquitectura hexagonal, cada adaptador de infraestructura es literalmente esto.

**65. 🟡 Adapter vs Facade vs Proxy: diferencias.**
Adapter **cambia** una interfaz para hacerla compatible. Facade **simplifica** un subsistema complejo detrás de una interfaz cómoda. Proxy **mantiene** la misma interfaz pero intercepta (control de acceso, caché, carga perezosa, logging). La distinción es de intención, no de estructura, y esa es la respuesta que esperan.

**66. 🟠 ¿Dónde aparece Proxy en Spring y qué consecuencias tiene?**
En todo AOP: `@Transactional`, `@Cacheable`, `@Async`, seguridad por anotación. Consecuencia práctica crítica: **las llamadas internas dentro de la misma clase no pasan por el proxy**, así que la anotación no se aplica. También explica por qué los métodos deben ser públicos y por qué `final` rompe el proxy CGLIB. Saber esto distingue al que ha depurado Spring en producción.

**67. 🟡 Decorator: ejemplo real y ventaja sobre la herencia.**
Envolver un objeto añadiendo comportamiento manteniendo la interfaz: los `InputStream` de Java (`BufferedInputStream(new FileInputStream(...))`) son el ejemplo canónico. Ventaja sobre herencia: puedes componer varias decoraciones en tiempo de ejecución y en cualquier orden, sin una explosión combinatoria de subclases.

**68. 🟠 ¿Cómo implementarías retry + caché + métricas sobre un cliente HTTP usando Decorator?**
Tres decoradores independientes sobre la misma interfaz, compuestos en el composition root. El orden importa y debes razonarlo en voz alta: métricas por fuera para medir el tiempo total percibido, caché antes del retry para no reintentar lo cacheable, retry pegado al cliente real. En Spring esto suele resolverse con AOP o con Resilience4j, que es el mismo patrón industrializado.

**69. 🟡 Composite: ¿para qué sirve?**
Tratar uniformemente objetos individuales y composiciones de objetos mediante una interfaz común. Casos típicos: árboles de UI, estructuras de archivos, y reglas de negocio compuestas (una regla `Y` que agrupa otras reglas y se evalúa igual que una simple).

**70. 🟠 Bridge: ¿en qué se diferencia de Adapter y cuándo lo necesitas?**
Adapter se aplica **a posteriori** para reconciliar interfaces incompatibles. Bridge se diseña **a priori** para separar una abstracción de su implementación y que ambas varíen independientemente. Señal de que lo necesitas: una jerarquía que crece en dos dimensiones (tipo de notificación × canal de envío), que sin Bridge produce N×M clases.

**71. 🟡 Flyweight: ¿sigue siendo relevante?**
Compartir estado intrínseco entre muchos objetos para ahorrar memoria. En Java lo ves en el pool de `Integer` (-128..127), en `String.intern()` y en la deduplicación de strings del GC. Relevante en casos de altísimo volumen; en la mayoría de aplicaciones es optimización prematura.

**72. 🟠 Facade: ¿qué peligro tiene?**
Que se convierta en un objeto-dios: la fachada crece hasta ser la única puerta a todo y acumula lógica que no le corresponde. Una fachada debe **delegar**, no decidir. Si tiene reglas de negocio, dejó de ser fachada.

**73. 🟠 ¿Qué es un proxy dinámico y cuándo lo usarías directamente?**
`java.lang.reflect.Proxy` o CGLIB crean implementaciones en tiempo de ejecución. Lo usa Spring Data para materializar repositorios a partir de interfaces sin implementación. Lo usarías directamente al construir un framework o un cliente declarativo; en código de aplicación casi nunca, y eso es lo correcto.

**74. 🟡 ¿Qué es el patrón Módulo y cómo se expresa en Java moderno?**
Agrupar y encapsular un conjunto de funcionalidades exponiendo solo una API pública. En Java se expresa con paquetes y visibilidad, y desde Java 9 con el **sistema de módulos (JPMS)**, que permite declarar explícitamente qué paquetes se exportan. En la práctica empresarial, Spring Modulith o ArchUnit suelen usarse para lo mismo con menos fricción.

**75. 🟠 ¿Cómo evitarías que un cambio en una librería de terceros se propague por todo tu código?**
Envolverla en una interfaz propia (Adapter/anti-corruption layer), permitir que solo un paquete la importe, y verificar esa regla automáticamente con ArchUnit. El coste es una capa de indirección; el beneficio aparece el día que cambias de proveedor o que la librería publica una versión incompatible.

**76. 🔴 ¿Cuándo la indirección adicional de un patrón estructural no vale la pena?**
Cuando solo hay una implementación y ninguna variación prevista, cuando el equipo no entiende el patrón (código que nadie mantiene con confianza es peor que código simple), y cuando la capa extra solo traduce nombres uno a uno sin aportar aislamiento. La pregunta honesta siempre es: ¿qué cambio futuro me está abaratando esta indirección, y qué probable es?

---

## 🎭 Parte 5 — Patrones de comportamiento (77–92)

**77. 🟢 Strategy: ¿cómo lo implementas en Spring?**
Una interfaz con varias implementaciones como beans, inyectadas como `List<Estrategia>` o `Map<String, Estrategia>`. El selector elige por clave y delega. Es el patrón más útil del catálogo en código empresarial: convierte cada `switch` de negocio en una decisión de configuración, y añadir un caso no modifica nada existente (OCP).

**78. 🟡 Template Method: ¿qué problema resuelve y cuál es su coste?**
Define el esqueleto de un algoritmo dejando pasos concretos a las subclases. Lo ves en `JdbcTemplate`, `RestTemplate`, `AbstractController`. Su coste: usa herencia, por lo que acopla fuertemente y solo permite una jerarquía. La alternativa moderna es el mismo esqueleto recibiendo funciones (`Consumer`, `Function`) como parámetros, lo que da composición en vez de herencia.

**79. 🟡 Observer: ¿dónde lo ves en Java y qué riesgos tiene?**
Eventos de Spring (`ApplicationEventPublisher`), listeners de UI, `PropertyChangeListener`. Riesgos importantes: fugas de memoria si no se da de baja el listener, ejecución síncrona que alarga la transacción del publicador, y orden de notificación no garantizado. En Spring, `@TransactionalEventListener` con fase `AFTER_COMMIT` resuelve el caso más habitual: reaccionar solo si la transacción realmente confirmó.

**80. 🟠 Chain of Responsibility: ejemplo empresarial.**
Cadena de manejadores donde cada uno decide si procesa o delega. Ejemplos reales: la cadena de filtros de Spring Security, los interceptores de MVC, y un pipeline de validaciones o de reglas de autorización de una operación financiera. Ventaja: agregar o reordenar pasos no toca los demás. Riesgo: si nadie maneja la petición, el fallo es silencioso — define siempre un manejador terminal.

**81. 🟡 Command: ¿qué te aporta encapsular una operación como objeto?**
Puedes encolarla, registrarla, reintentarla, deshacerla y auditarla. Es la base de las colas de trabajo, del undo/redo y de CQRS en su lado de escritura. En banca es especialmente natural: un comando `TransferirFondos` serializado es a la vez la intención, el registro de auditoría y la unidad de reintento.

**82. 🟠 State: ¿cómo lo usarías para una transferencia bancaria?**
Cada estado (iniciada, autorizada, enviada, confirmada, rechazada, en duda, compensada) es una clase que define qué transiciones son válidas y qué hace cada operación. Elimina los `if (estado == X && estado != Y)` dispersos y hace imposible una transición inválida. Alternativa ligera: un enum con las transiciones permitidas declaradas, que es más simple y suele bastar.

**83. 🟡 State vs Strategy: ¿en qué se diferencian si estructuralmente son iguales?**
En la intención y en quién decide. En Strategy, el cliente elige la estrategia y esta no cambia sola. En State, el propio objeto cambia de estado como consecuencia de las operaciones, y los estados conocen sus transiciones. Misma estructura, semántica opuesta.

**84. 🟠 Visitor: ¿cuándo vale la pena y por qué cuesta tanto?**
Permite añadir operaciones nuevas sobre una jerarquía estable sin modificar sus clases (double dispatch). Vale la pena en ASTs, compiladores y recorridos de estructuras complejas. Cuesta porque agregar un **tipo** nuevo obliga a tocar todos los visitors — es exactamente el trade-off inverso al del polimorfismo. En Java 17+, `sealed` + pattern matching cubre la mayoría de casos de Visitor con mucha menos ceremonia.

**85. 🟡 Mediator: ¿qué problema resuelve?**
Evita el acoplamiento todos-contra-todos centralizando la comunicación entre componentes. Riesgo claro: el mediador se convierte en un objeto-dios. En arquitectura distribuida su equivalente es el orquestador de una saga, con el mismo trade-off: control centralizado y visible, a cambio de un punto de acoplamiento.

**86. 🟡 Memento: ¿tiene uso real hoy?**
Capturar y restaurar estado sin violar el encapsulamiento. Uso real: snapshots en event sourcing (para no reproducir miles de eventos), undo en editores, y puntos de control en procesos largos como un batch reiniciable.

**87. 🟠 Iterator: ¿qué es un fail-fast iterator?**
El que lanza `ConcurrentModificationException` si la colección se modifica durante la iteración, detectado por un contador de modificaciones. No es una garantía de concurrencia, es una ayuda de depuración. Las colecciones concurrentes (`CopyOnWriteArrayList`, `ConcurrentHashMap`) usan iteradores weakly consistent que no lanzan pero pueden no ver cambios recientes.

**88. 🟠 Interpreter: ¿lo has necesitado alguna vez?**
Define una gramática y la evalúa. Útil para motores de reglas de negocio configurables, filtros dinámicos o DSLs pequeños. Antes de escribirlo, considera alternativas: SpEL, un motor de reglas existente, o incluso un `Predicate` compuesto. Escribir un intérprete propio es caro de mantener y es una decisión que hay que justificar.

**89. 🟠 ¿Cómo implementarías un motor de reglas de negocio que cambie sin desplegar?**
Combinación: Composite para reglas compuestas (Y/O), Strategy o Specification para cada regla atómica, y configuración externa que arme el árbol. Las reglas se cargan en caliente desde base de datos o un servicio de configuración. Advertencia honesta que debes decir: todo motor de reglas configurable termina siendo un lenguaje de programación mal diseñado; asegúrate de que la volatilidad de negocio realmente lo justifica.

**90. 🟡 ¿Qué es el patrón Specification?**
Encapsular un criterio de negocio como objeto componible (`esClienteVip().and(tieneSaldoSuficiente())`). Sirve tanto para validar en memoria como para traducirse a una consulta (Spring Data tiene `Specification` para JPA Criteria). Mantiene el vocabulario del dominio en el dominio, en vez de repartir condiciones por repositorios.

**91. 🟠 ¿Cuál es la relación entre patrones de comportamiento y el principio "tell, don't ask"?**
Casi todos son formas de trasladar la decisión al objeto que tiene la información: Strategy en vez de preguntar el tipo y ramificar, State en vez de consultar el estado y decidir fuera, Command en vez de inspeccionar datos para saber qué hacer. Ver esa raíz común demuestra que entiendes los patrones como consecuencias de principios, no como recetas memorizadas.

**92. 🔴 Los patrones GoF son de 1994. ¿Cuáles han quedado obsoletos y por qué?**
Respuesta con criterio: **Singleton** lo absorbió el contenedor de DI; **Iterator** lo absorbió el lenguaje (`for-each`, Streams); **Command y Strategy** se escriben hoy con lambdas en una línea, no con jerarquías; **Visitor** lo reemplaza pattern matching sobre tipos `sealed`; **Prototype** cedió ante constructores de copia y records. Lo que no envejece son los principios subyacentes: encapsular lo que varía, componer en vez de heredar, programar contra interfaces.

---

## 🧠 Parte 6 — Diseño aplicado y preguntas abiertas (93–100)

**93. 🟠 ¿Cómo decides entre usar un patrón o escribir la solución directa?**
Criterio: el patrón debe pagar su coste de complejidad con una variación **real y presente**, no hipotética. La secuencia sana es: escribe la solución directa; cuando aparezca la segunda variante, refactoriza al patrón que la naturaleza del cambio te esté pidiendo. Los patrones se **descubren** refactorizando mucho más a menudo de lo que se eligen por adelantado.

**94. 🟠 ¿Qué patrón has visto peor aplicado en tu carrera?**
Ten una historia real. Los sospechosos habituales: Singleton como variable global, herencia profunda donde tocaba composición, una capa de abstracción sobre el ORM que solo renombraba métodos, o un motor de reglas construido para una volatilidad que nunca ocurrió. Lo que evalúan no es el patrón, sino que hayas medido el daño y aprendido algo concreto.

**95. 🟠 Diseña un sistema de notificaciones multicanal (email, SMS, push, webhook) extensible.**
Strategy por canal + Abstract Factory si cada canal necesita una familia de piezas (formateador, cliente, política de reintento). Decorator para responsabilidades transversales (reintento, métricas, rate limiting). Chain of Responsibility para el fallback entre canales. Configuración externa para las preferencias por usuario. Menciona lo que no es patrón pero decide el diseño: idempotencia (no notificar dos veces), plantillas versionadas y cola asíncrona.

**96. 🟠 ¿Cómo harías testeable un código que depende de la fecha y hora actual?**
Inyecta `java.time.Clock` en vez de llamar a `LocalDateTime.now()`. En pruebas usas `Clock.fixed(...)`. El mismo principio vale para aleatoriedad, UUIDs, sistema de archivos y red: toda fuente de no determinismo debe ser una dependencia explícita. Si tienes que mockear estáticos, el diseño está mal.

**97. 🟠 ¿Qué es un anti-corruption layer y cuándo lo construyes?**
Una capa de traducción entre tu modelo y el de un sistema externo o legacy con un modelo incompatible o mal diseñado. La construyes cuando el modelo ajeno, si entra a tu dominio, lo contamina (nombres crípticos, códigos mágicos, semántica confusa). Es Adapter aplicado a nivel de contexto completo, y es una de las decisiones más rentables al integrar con un core bancario antiguo.

**98. 🔴 ¿Cómo refactorizarías una clase de 3.000 líneas con 40 métodos y estado mutable compartido?**
Método, no heroísmo. Primero pruebas de caracterización sobre el comportamiento actual. Después, identificar grupos de métodos que usan los mismos campos (eso es LCOM manual y revela las clases ocultas dentro). Extraer esos grupos uno a uno con refactorizaciones automatizadas del IDE. Introducir interfaces para romper dependencias externas. Todo en PRs pequeños y desplegables, nunca en una rama de tres meses. Y mide: si los bugs en ese módulo no bajan, la refactorización no sirvió.

**99. 🔴 Un compañero dice que los patrones de diseño son innecesarios con lenguajes modernos. ¿Qué respondes?**
Tiene razón parcialmente: muchas **implementaciones** clásicas quedaron obsoletas porque el lenguaje absorbió el mecanismo (lambdas, sealed, records, contenedores de DI). Pero los patrones siguen siendo valiosos como **vocabulario compartido**: decir "esto es un Strategy con un Decorator de reintento" transmite en cinco segundos lo que explicar el código tomaría diez minutos. El valor migró de la implementación a la comunicación, y eso sigue siendo mucho valor.

**100. 🔴 ¿Cómo enseñas diseño a un equipo mixto sin convertirlo en dogma?**
Con código real del propio equipo, no con ejemplos de figuras geométricas. Revisiones de código como herramienta didáctica, explicando siempre el **porqué** y el coste, no solo la regla. Katas de refactorización sobre módulos propios. Y lo más importante para evitar el dogma: mostrar explícitamente casos donde **no** aplicas el principio y explicar por qué, porque un equipo que solo oye reglas absolutas produce SOLID de cargo culto.

---

> 🧭 **Cierre:** si tuvieras que llevarte tres ideas a la entrevista: (1) los patrones son consecuencias de principios, no recetas; (2) todo patrón tiene un coste y debes poder nombrarlo; (3) la métrica final del diseño es el **coste del cambio**, no la elegancia.
