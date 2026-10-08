# 08 — Desmontar un monolito distribuido

Aprenderás a elegir el primer cambio que devuelve autonomía o reduce riesgo en un monolito
distribuido ya diagnosticado, a ordenar los siguientes y a reconocer cuándo la mejor remediación es
fusionar procesos en lugar de separarlos mejor.

## 1. 🎯 Síntoma y decisión

El diagnóstico de [anatomía y evidencia](01-anatomia-y-evidencia-del-monolito-distribuido.md) ya está
hecho: los cinco componentes de comercio cambian, se liberan y fallan juntos. Sobre la mesa hay tres
propuestas. El arquitecto quiere dividir `orders` en tres servicios más finos. Un equipo propone
reescribir todo como monolito modular durante dos trimestres, con el sistema actual congelado. El
equipo de `inventory` pide lo contrario que todos: devolver la reserva de stock al proceso de
`orders`, porque cada cambio de reservas de los últimos seis meses tocó los dos componentes y cada
checkout necesita dos llamadas entre ellos.

Las tres propuestas atacan el mismo síntoma con apuestas de tamaño muy distinto. La decisión de este
capítulo es cuál es el primer paso, cómo se mide y qué lo detiene; y cuándo fusionar es la respuesta
correcta y no una derrota.

## 2. 🧠 Modelo mental

Desmontar no es sinónimo de separar mejor. Es devolver a cada decisión una sola unidad que la posea,
y esa unidad puede ser un proceso propio o un módulo dentro de otro proceso.

```text
cada cambio de la capacidad cruza la frontera
   │
   ├─ ¿la frontera compra algo medible? (cadencia propia, escala aparte, aislamiento, equipo distinto)
   │     ├─ sí → separar de verdad: un escritor por dato, contrato compatible, cadena corta
   │     └─ no → fusionar el despliegue, conservando módulos, APIs internas y dueños de tablas
   │
   └─ orden dentro de cualquiera de las dos salidas
         datos (un escritor) → contrato (versiones mixtas) → cadena (menos saltos) → release
```

El orden importa porque cada paso hace seguro al siguiente. Mientras dos componentes escriben la
misma tabla, ningún contrato los independiza; mientras el contrato obliga a desplegar juntos, acortar
la cadena no quita el release train. Y ninguna remediación se juzga por la topología que deja, sino
por los cambios reales que después dejan de necesitar coordinación.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | en seis meses, 14 de 15 cambios de reservas tocaron `orders` e `inventory`; los dos escriben `inventory.reservations`; cada checkout hace dos llamadas `orders` → `inventory`; los dos componentes los opera el mismo equipo y siempre salen en el mismo release; ninguno tiene una carga que exija escalarlo aparte |
| Inferencia | la reserva es una decisión de `orders` repartida entre dos procesos, y la frontera no compra cadencia, escala ni un equipo distinto |
| Diagnóstico | frontera sin beneficio compensatorio entre `orders` e `inventory`; el resto de componentes necesita otra remediación |
| Recomendación | medir una línea base, fusionar el despliegue de `orders` e `inventory` conservando sus módulos y la propiedad de sus tablas, y aplazar cualquier otra división hasta ver el efecto |

Las cifras son supuestos del ejercicio. Qué refutaría la recomendación: si `inventory` tuviera un
equipo propio con otra cadencia, o si su carga en campaña exigiera escalarlo por separado, la
frontera compraría algo y la salida sería separarla de verdad —un escritor, contrato, cadena corta—,
no fusionarla. Y si los 14 cambios fueran un único proyecto transversal, la muestra no representaría
el trabajo habitual.

## 4. 🛠️ Una costura, un experimento

**Primero, la línea base.** Sin ella, ninguna remediación se puede evaluar. Se recogen, sobre cambios
representativos de un periodo acordado, las mismas cinco monedas del diagnóstico:

| Moneda | Línea base a recoger | Resultado buscado |
|---|---|---|
| Código | componentes tocados por cambio | cambios que se quedan en una unidad |
| Datos | escritores por tabla e invariante | un escritor por dato |
| Despliegue | releases que obligatoriamente van juntos | salidas independientes o una sola salida honesta |
| Runtime | saltos síncronos por checkout, incidentes por componente | menos saltos obligatorios, fallos contenidos |
| Equipos | aprobaciones y esperas entre equipos por cambio | decisiones dentro de un equipo |

**Después, una sola costura.** Se elige el flujo por impacto y riesgo —la reserva de `CreateOrder`—,
no el componente más pequeño ni el más fácil. Un paso a la vez: primero se declara quién escribe la
reserva, después se cambia el camino detrás de una fachada, después se reduce el salto. Cambiar a la
vez protocolo, base y organización deja una regresión imposible de atribuir.

```text
línea base ─► dueño de la reserva ─► fachada con ruta seleccionable ─► cohorte pequeña
     ▲                                                                      │
     └──────── decidir el siguiente paso con cambios reales ◄── observar ◄──┘
```

**Fusionar sin perder lo que había.** Si la evidencia lo pide, `orders` e `inventory` vuelven a un
despliegue, pero como dos módulos con su API interna y sus tablas: la fusión recupera la transacción
local y quita dos saltos de red, no el límite de código. Meter los dos procesos en el mismo
contenedor no crea una transacción; hace falta una conexión y un único límite transaccional.

**El *strangler fig* inverso.** El patrón de estrangulamiento sustituye un sistema por otro de forma
gradual; aquí se usa al revés, para dirigir operaciones remotas hacia una implementación local. Se
enruta por cohorte estable —mismo pedido, misma ruta, también para consultas y cancelaciones—, con un
solo escritor por operación en cada momento. Antes de transferir la escritura, revertir es cambiar
la ruta; después, exige devolver también los datos escritos en la ruta nueva.

**Si el acoplamiento viaja por un broker**, el orden es el mismo con otros nombres: los comandos
disfrazados pasan a llamadas honestas o a estados pendientes, las entidades publicadas pasan a hechos
versionados y el proceso de varios pasos recibe un dueño, como describe el
[acoplamiento asíncrono](06-acoplamiento-asincrono-el-monolito-distribuido-con-broker.md). Y antes de
recortar nada, hay que nombrar qué decisiones de [corte y plataforma](07-como-se-llega-granularidad-entidades-y-plataforma-compartida.md)
fabricaron el estado actual: corregir la costura sin quitar la causa la vuelve a erosionar.

Mientras convivan procesos, las correcciones de [contratos](04-contratos-fragiles-y-despliegues-coordinados.md)
y de [estados inciertos](05-fallos-parciales-retries-y-falsas-transacciones.md) siguen siendo
obligatorias: la remediación no suspende los fallos parciales.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | fachada por paquete, módulos del build y prueba arquitectónica tras fusionar | unificar transacciones sobre bases distintas | fusionar artefactos sin revisar pools, hilos y memoria |
| Node/TypeScript | exportaciones públicas del paquete y reglas de imports | validar payloads ya persistidos con la forma remota | reutilizar los tipos del contrato remoto como modelo interno |
| Go | API pequeña del paquete e `internal/` tras la fusión | decidir por sí solo quién es dueño de qué | juntar binarios y conservar las llamadas HTTP entre ellos |
| Python | fachada del paquete y contratos de importación | aislamiento de recursos entre módulos del mismo proceso | mantener imports directos a los internos por conveniencia |

Las cuatro trampas repiten un error: tratar la fusión como un cambio de empaquetado. Juntar artefactos,
binarios o paquetes sin conservar las APIs de módulo convierte el monolito distribuido en una bola de
barro local; juntarlos y conservar las llamadas HTTP entre ellos no recupera ni la transacción ni la
latencia. Los mismos [controles arquitectónicos](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
del monolito modular sirven para que la fusión no borre los límites: impiden volver a las escrituras
cruzadas, pero no deciden dónde pertenece la reserva.

## 6. ⚖️ Decisión y coste

Empieza por la línea base y una costura con un experimento acotado; decide el siguiente paso con los
cambios que vengan después. Fusionar paga radio de fallo y despliegue compartidos, y compra
transacción local, menos saltos y una guardia menos. Separar de verdad paga contrato, compatibilidad
temporal y estados inciertos, y compra cadencia o escala propias. Mantener dos rutas durante la
transición cuesta capacidad del equipo. Detente cuando los cambios relevantes ya no necesiten
coordinación y el beneficio de otra migración no compense su riesgo.

## ⚠️ Errores frecuentes

- «La salida de un monolito distribuido es dividir más fino». Si un cambio ya cruza cinco componentes,
  cortarlos en diez lo hace cruzar diez.
- «Fusionar es admitir un fracaso». Es una decisión con coste medido; puede ser la forma más barata de
  recuperar una transacción y quitar una guardia.
- «Reescribirlo todo como monolito modular es más limpio». Congela el negocio durante meses y no
  permite saber qué costura aportaba; una costura por vez sí.
- «El éxito se mide en contenedores eliminados». Se mide en cambios que dejan de necesitar
  coordinación, sin empeorar incidentes ni SLO.
- «Tras transferir la escritura, se revierte cambiando el router». Las operaciones escritas en la ruta
  nueva también tienen que volver; sin eso, revertir pierde datos.

## 7. ✅ Veredicto

Mide primero y cambia una costura a la vez, en el orden datos, contrato, cadena y release. Si la
frontera no compra cadencia, escala, aislamiento ni un equipo distinto, fusiona el despliegue y
conserva los módulos; si los compra, sepárala de verdad. La topología final puede ser un monolito
modular o varios servicios: cada frontera que quede tiene que demostrar una ventaja observable en
cambios reales.

## 📚 Referencias

- [Strangler Fig, Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Branch By Abstraction, Martin Fowler](https://martinfowler.com/bliki/BranchByAbstraction.html)
- [Parallel Change, Martin Fowler](https://martinfowler.com/bliki/ParallelChange.html)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es una línea base de remediación y qué mide en cada una de las cinco monedas?
2. 🟢 ¿Qué es una costura de recuperación en un sistema ya distribuido?
3. 🟢 ¿En qué orden se remedian datos, contrato, cadena y release, y por qué ese orden?
4. 🟢 ¿Qué conserva una fusión bien hecha de dos componentes?
5. 🟢 ¿Qué significa aquí *strangler fig* inverso?
6. 🟢 ¿Qué es una cohorte estable y por qué la ruta no puede cambiar a mitad de una operación?
7. 🟡 ¿Por qué no se elige como primera costura el componente más pequeño o el más fácil?
8. 🟡 ¿Qué evidencia de la sección 3 justifica fusionar `orders` e `inventory` y no el resto?
9. 🟡 ¿Por qué meter dos procesos en el mismo contenedor no recupera la transacción?
10. 🟡 ¿Por qué no conviene cambiar protocolo, base y organización en el mismo paso?
11. 🟡 ¿Qué pierde el sistema al fusionar dos componentes, y cuándo esa pérdida importa?
12. 🟡 ¿Cuándo separar de verdad es mejor salida que fusionar?
13. 🟡 ¿Qué debe hacer la fachada transitoria y qué no debe hacer?
14. 🟡 ¿Cómo mantienes un solo escritor por operación mientras conviven dos rutas?
15. 🟡 ¿Cómo cambia la remediación cuando el acoplamiento viaja por un broker?
16. 🟡 ¿Por qué la propuesta de reescribirlo todo durante dos trimestres es arriesgada aunque el destino sea correcto?
17. 🟡 ¿Cómo comprobarías, en Java y en Go, que la fusión no borró los límites entre módulos?
18. 🟠 ¿Qué riesgo comparten reutilizar tipos remotos en Node/TypeScript e imports directos en Python después de fusionar?
19. 🟠 ¿Cómo abortas la migración antes de transferir la escritura a la ruta local?
20. 🟠 ¿Cómo abortas después de transferir la escritura, cuando la ruta nueva ya tiene datos?
21. 🟠 Tras la fusión baja la latencia de checkout, pero suben los incidentes que afectan a todo el proceso. ¿Qué haces?
22. 🟠 El arquitecto insiste en dividir `orders` en tres servicios y el equipo de `inventory` pide fusionar. ¿Cómo resuelves la discusión?
23. 🟠 La fachada transitoria se convierte en un cuello de botella y en un componente más que operar. ¿Qué harías?
24. 🟠 ¿Qué resultado, y medido cómo, demuestra que la remediación funcionó y se puede detener?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [07 — Cómo se llega: granularidad, entidades y plataforma compartida](07-como-se-llega-granularidad-entidades-y-plataforma-compartida.md).

**Siguiente:** [09 — Simulación de entrevista: Monolito distribuido](09-simulacion-de-entrevista.md).
