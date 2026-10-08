# 🏪 La empresa del curso — Meridian Retail Group

> Empresa ficticia del curso *Go para desarrolladores Java senior*.
>
> **Estado:** fuente de verdad de todo lo narrativo. Personajes, cifras, cronología, incidentes
> y reglas de negocio se citan desde aquí; ninguna fase inventa un número de la empresa por su
> cuenta. Si una fase necesita un dato que no está en este documento, se agrega aquí primero.
>
> **Relación con los otros documentos.** `prompts/alcance-del-proyecto.md` §5 define el dominio y su
> diccionario; este documento cuenta **de dónde salió ese dominio**. Donde haya conflicto manda
> el alcance, y este archivo se corrige.
>
> **Sobre el nombre.** La cadena se llamó *Ferretería Duarte* durante doce años y el nombre no
> cruzó la frontera: en Ecuador sonaba a apellido ajeno y en Panamá a nada. En 2003 buscaban una
> palabra que funcionara igual en once países, que no fuera de nadie y que se pudiera pronunciar
> en inglés cuando llegara un proveedor asiático. **Meridian** salió de una lámina de geografía
> colgada en la oficina de compras. El chiste se volvió profético: un meridiano es exactamente lo
> que separa el día de una tienda del día de otra, y **cada tienda cierra su jornada en su propio
> meridiano** — que es, literalmente, el bug más caro que puede tener la plataforma (§1.1).

---

## 1. 🧱 Cómo llegó a existir

**Ernesto Duarte** abrió en 1991 un local de veinticinco metros en el barrio Ricaurte, en Bogotá,
a media cuadra de donde todavía se compra tubería al por mayor. Vendía lo que vendían todos
—tornillos, pintura, mangueras, bombillos— y sobrevivió los primeros cuatro años por una razón
que no tiene nada de estratégica: fiaba. Le anotaba al maestro de obra en un cuaderno y le cobraba
el viernes.

De esos cuatro años salió la única idea original de la casa. Ernesto se dio cuenta de que el
maestro que entraba por un codo de PVC también necesitaba una escoba, una bombilla y un balde, y
que la ferretería lo mandaba a otra tienda por las tres cosas. En 1996 rehizo el surtido: **la
mitad ferretería liviana, la mitad hogar y aseo**. Dejó de ser una ferretería y se convirtió en
la tienda a la que uno va cuando algo se rompe en la casa. El ticket bajó y la cantidad de tickets
se multiplicó — y ese cambio, treinta años después, es la razón de que la plataforma de Meridian
procese millones de movimientos por noche en vez de miles.

En 1998 abrió el segundo local; en 2001 el quinto; en 2003, con nueve tiendas y el primer local
fuera de Bogotá, el letrero se les quedó chico y nació **Meridian**.

El salto internacional fue en 2009, a Ecuador, y fue una lección costosa que sigue viva en el
código. Meridian llegó con el surtido de Bogotá, los precios de Bogotá y —esto es lo que
importa— **el mismo archivo de configuración de Bogotá**. Tres meses después descubrieron que
estaban vendiendo a pérdida en cuatro categorías por un tipo de cambio que alguien había escrito
a mano y nadie había vuelto a mirar. Es la primera aparición del problema que en 2026 resuelve
AtlasSync.

Después vinieron Panamá y Perú (2013), Costa Rica y Chile (2016), México (2018 — el país que
más tiendas tiene hoy después de Colombia), República Dominicana y Paraguay (2021), y Guatemala
(2024, el número once).

En 2020 llegó el otro salto, el que nadie planeó. Con las tiendas cerradas por pandemia,
Meridian montó en siete semanas una operación de venta en línea con recogida en tienda y entrega
a domicilio. Lo armaron con lo que había: dos transportistas contratados por teléfono, una
pasarela de pagos, un marketplace que les ofreció vitrina, y un integrador que conectó todo con
archivos planos por FTP. Funcionó tan bien que se quedó, y de ahí salieron los **treinta socios
comerciales integrados por API** que hoy son la mitad de los incidentes de la plataforma.

Hoy, 2026, **Meridian son 140 tiendas en once países**, dos centros de distribución propios
—Funza y Tepotzotlán—, unos 4.100 empleados, y una operación logística que no subcontrata el
último kilómetro en las ciudades principales. Entre **dos y cinco millones de movimientos de
caja por noche**, según el día del mes y la temporada.

Ernesto tiene 71 años, es presidente de la junta y todavía llama a las tiendas los sábados para
preguntar cómo estuvo el día. Su hija **Ana Lucía Duarte** es la gerente general desde 2017.

### 1.1 🌙 El Cierre, el objeto de negocio contra el que choca todo

Lo que Meridian tiene que hacer todas las noches sin falta se llama, en la empresa, **el Cierre**,
con mayúscula y sin más explicación. Es el objeto de negocio más difícil que tiene la compañía y
**casi todo lo que vas a construir en este curso termina chocando contra él**.

La idea es simple de enunciar. Cada tienda registra movimientos de caja durante su jornada
—ventas, devoluciones, anulaciones, retiros y depósitos—; al terminar el día hay que juntar los
movimientos de las 140 tiendas, cruzarlos contra lo que reportó la pasarela de pagos y contra lo
que reportó el banco, encontrar lo que no coincide, producir los asientos contables y **cerrar el
periodo** de esa tienda y ese día. Un periodo cerrado es un día que ya no se discute.

| Etapa | Quién manda | Qué resuelve | Duración objetivo |
|---|---|---|---|
| **0 · Captura en tienda** | La tienda | El punto de venta registra el movimiento, **con o sin red** | toda la jornada |
| **1 · Sincronización** | El agente de tienda | Subir lo acumulado al central, sin perder nada y sin duplicar | minutos tras recuperar el enlace |
| **2 · Conciliación** | Tesorería | Cruce contra pasarela y banco: coincidencia exacta, por tolerancia, o descuadre | la ventana nocturna |
| **3 · Asientos** | Contabilidad | El asiento por movimiento conciliado, en la moneda de la tienda | dentro de la misma ventana |
| **4 · Cierre del periodo** | Tesorería | Cerrar el día si no quedan descuadres, o emitir el informe de excepciones | al final de la ventana |
| **5 · Reapertura** | Dirección financiera | El día que se tiene que volver a abrir porque apareció algo. **Es el caso incómodo y ocurre** | horas o semanas después |

> 🧭 **La ventana es de dos horas.** Entre la una y las tres de la mañana, porque a las tres
> empieza el proceso de reposición de los dos centros de distribución y a las cinco abren las
> primeras tiendas de México. El proceso heredado tarda tres horas cuando todo va bien.

Y aquí está lo que lo vuelve difícil de verdad, que no es el volumen:

- **El día de una tienda no es el día de otra.** El cierre del 4 de marzo en Bogotá y el del 4 de
  marzo en Ciudad de México no cubren el mismo intervalo UTC. En 2018, cuando abrió México, el
  Cierre corrió nueve noches con la zona horaria de Bogotá y cortó las tiendas mexicanas a las
  cinco de la tarde local: **ochenta mil movimientos aparecieron como descuadre** y tesorería
  tardó tres semanas en limpiarlo. Nadie en la empresa ha olvidado ese episodio, y es la razón de
  que `Store` tenga `TimeZone` y de que haya un ejercicio 🔴 dedicado en la Fase 09.
- **La tienda vende sin red, y eso no es negociable.** Hay tiendas en las que el enlace se cae
  cuatro veces al día y una, en Paraguay, donde se cae por la tarde casi siempre. Una tienda no
  puede dejar de vender porque el enlace esté caído, así que el movimiento nace y vive un rato
  **fuera del alcance del central** — y cuando llega, llega en tanda, desordenado y a veces dos
  veces.
- **El descuadre no es un error de software: es un hecho del negocio.** Cada noche **entre 1.500
  y 4.000 movimientos no cuadran**, y eso es normal: un pago aprobado que la pasarela reporta al
  día siguiente, una anulación que el cajero hizo mal, una devolución sin el documento original,
  un retiro que el supervisor no firmó. Se agrupan en 400 a 900 excepciones por tienda y causa, y
  las revisan siete personas de tesorería.
- **Y lo que no se resuelve, se castiga.** Un descuadre que sigue abierto a los treinta días se
  lleva contra resultados. En 2025 fueron **1.900 millones de pesos**, y ese es el número que
  desbloqueó el presupuesto de la plataforma. No fue una presentación de arquitectura: fue una
  línea del estado de resultados que el auditor externo subrayó.
- **El periodo se reabre, y esa es la parte que nadie quiere modelar.** Un día cerrado que se
  vuelve a abrir arrastra asientos ya publicados, un reporte ya enviado a dirección y, si la
  tienda es de México, un documento fiscal ya timbrado. El proceso heredado **no sabe reabrir**:
  lo que se hace hoy es un ajuste manual en el ERP con un correo de soporte, y esa es la deuda
  contable de la casa.

⚰️ El proceso que hace todo esto se llama **Nocturno** y §3 cuenta por qué nadie lo toca. Cuando
falla a la mitad —y falla unas dos veces al mes— no se reanuda: se vuelve a correr desde el
principio, y si eso no cabe en la ventana, el Cierre de esa noche queda para el día siguiente y
tesorería trabaja con dos días encima.

### 1.2 🤝 Los treinta socios, o qué pasa cuando la operación sale de la casa

Meridian vende, guarda y despacha. **No transporta fuera de las ciudades principales, no procesa
pagos con tarjeta, no opera su propio marketplace y no hace la contabilidad fiscal de once
países**, y no piensa hacer ninguna de esas cuatro cosas. Pero la operación las necesita, así que
la plataforma tiene que hablar con quien sí las hace.

Hoy hay **34 convenios de integración firmados, de los cuales 30 están activos**: once
transportistas, dos pasarelas de pago, cuatro marketplaces, tres operadores de facturación
electrónica, el ERP del grupo, dos bancos, y el resto proveedores de servicios puntuales
—verificación de identidad, cotización de fletes, seguimiento de guías—. Cuatro convenios están
firmados y muertos: alguien los desconectó y nadie los dio de baja. Cada socio quiere enterarse
cuando pasa algo: `order.created`, `payment.approved`, `shipment.dispatched`,
`settlement.completed`.

Lo que no funciona es todo lo que pasa después de la firma:

- **El productor llama al consumidor, y eso ya explotó.** El **sábado 6 de diciembre de 2025**, la
  pasarela de un socio empezó a responder en ocho segundos en vez de en ciento veinte
  milisegundos. El servicio de ventas la llamaba en línea, los hilos se quedaron esperando, el
  pool se agotó, y durante **cuarenta y un minutos Meridian no pudo registrar ventas en línea**
  porque un tercero tenía un mal día. Se perdieron unos **380 millones de pesos** en ventas que
  no se pudieron registrar, y dos días de reputación en Twitter. Ese sábado es la fecha de
  nacimiento de EventRelay.
- **Nadie sabe qué se entregó.** No hay historial de intentos. Cuando un socio dice "eso no me
  llegó", la respuesta de Meridian es buscar en los logs de la aplicación, y los logs rotan a los
  siete días.
- **Y a veces se entrega de más.** En marzo de 2024 un reintento mal escrito le mandó al
  marketplace de **Karim Abadía** el mismo `shipment.dispatched` cuarenta mil veces en una noche.
  Karim lo detectó antes que Meridian, lo dijo con educación, y desde entonces revisa cada
  integración con lupa. **Ha tenido razón dos veces más**, y ninguna de las dos se pudo demostrar
  ni desmentir con datos.
- **Un socio caído degrada a los treinta.** No hay aislamiento: la cola de salida es una sola y un
  destino que no responde la tapona. El fallo parcial no existe en la plataforma actual; existe el
  fallo total, y llega rápido.
- **Nadie mide a la red.** Qué socio responde en cuánto tiempo, cuál rechaza más, cuál pide
  reenvíos, cuál tiene el certificado por vencer, y cuál sigue teniendo convenio vigente. La
  renegociación anual de tarifas de transporte se hace, hoy, con la impresión que tiene el
  gerente de logística.

⚠️ **Y hay una arista que el curso no puede esquivar.** El endpoint al que Meridian entrega lo
registra el socio, no Meridian, y un socio puede escribir lo que quiera — incluida una dirección
de la red interna de Meridian. Un relay de webhooks que acepta cualquier URL es, dicho sin
adornos, **una herramienta de SSRF apuntada contra la propia infraestructura**, y la casa ya
tiene un metadata service en la nube al que no le gustaría recibir visitas. Esa validación es
deuda declarada en la Fase 02 y se paga en la Fase 14; no es una sección de seguridad decorativa,
es la razón por la que el servicio puede existir.

---

## 2. 👥 Quién es quién

**Ana Lucía Duarte**, gerente general. Hija del fundador, economista, catorce años dentro de la
empresa antes de dirigirla. No es técnica y no finge serlo; lo que sí hace es preguntar cuánto
cuesta y cuándo se ve. Aprobó el presupuesto de la plataforma en febrero de 2026 con una frase que
en la empresa se repite como chiste y como advertencia: *"no quiero un sistema nuevo, quiero que
el Cierre termine a las tres"*.

**Hernán Villalba**, arquitecto principal. Java desde 2004, Spring desde 2010, Spring Boot en
producción desde 2015. Montó la plataforma actual y no tiene ninguna intención de disculparse por
ella, porque sostiene 140 tiendas y once países. **No está en contra de Go**: está en contra de
que se cambie de lenguaje por entusiasmo. Su posición, dicha en la primera reunión, es la que
ordena el curso entero: *"tráeme el número y lo discutimos; tráeme una opinión y no"*. Las ocho
preguntas de la defensa final del curso son literalmente las suyas, y son razonables las ocho.

**Nelly Ospina**, jefa de tesorería. Doce años en Meridian, y la persona que de verdad vive el
Cierre: es quien a las siete de la mañana abre el informe de excepciones y reparte los descuadres
entre su equipo de siete. Lleva un archivo propio —`DESCUADRES_SEGUIMIENTO_v9.xlsx`— porque el
sistema no le dice qué pasó con el descuadre de anteayer. **Nelly es tu usuaria real**: si el
reporte que genera OpsReport no le sirve para trabajar, el proyecto fracasó aunque pase todos los
tests.

**Wílmar Pineda**, operador de guardia. Es quien recibe la llamada a las 2:14 de la mañana cuando
Nocturno se cae, y quien tiene que decidir si lo relanza desde cero o espera. Su procedimiento
actual es un documento de Word de 2019 con capturas de pantalla de una consola que ya cambió de
aspecto. **Todo lo que el curso escriba sobre observabilidad, `/health`, `/ready` y runbooks se
mide contra una sola pregunta: ¿le sirve a Wílmar a las dos de la mañana?**

**Marleny Cárdenas**, administradora de la tienda ST-042, en un municipio donde el enlace se cae
todos los días después de la lluvia. No le interesa la arquitectura: le interesa que la caja
siga facturando y que el domingo no le toque digitar nada dos veces. El agente de tienda del
curso —`storeagent`— existe por ella, y su criterio de aceptación es que **Marleny no tenga que
saber que existe**.

**Camilo Otero**, líder del equipo de integraciones. Tres personas y 30 socios. Es el que contesta
los correos de Karim y el que sabe de memoria cuál transportista manda el `Retry-After` mal.
Quiere EventRelay más que nadie en la empresa.

**Karim Abadía**, gerente de integraciones del marketplace socio. No trabaja en Meridian y por eso
importa: es la contraparte que no controlas, que no usa tu sistema, que lee tus cabeceras con
atención y que **ya te encontró tres errores**. Toda decisión de contrato de webhook del curso se
escribe pensando en que Karim la va a leer.

**La consultora del ERP**, que no tiene cara y no la va a tener. Cotiza cada cambio, entrega en
seis semanas y factura por hora. Nadie en Meridian discute su calidad; discuten su calendario.

---

## 3. 🕰️ Nocturno, Nexo y el ERP: lo que no se va a morir

Tres sistemas sostienen hoy a Meridian, y **el curso no reemplaza a ninguno de los tres**. Vale la
pena entender qué hace cada uno, porque la mitad de las decisiones de diseño del curso son
decisiones de frontera con ellos.

**El ERP**, comprado en 2015, es la contabilidad, el inventario maestro, las compras y la nómina.
Es el sistema de registro de la empresa y **es intocable**: lo que entra ahí entra por sus
interfaces y en su formato, y por eso las referencias externas de los trabajos operativos se ven
como `SAP-2026-000123`. Cualquier cambio pasa por la consultora, seis semanas y una cotización.

**Nexo** es la plataforma que construyó Hernán entre 2017 y 2022: un monolito modular en Spring
Boot, PostgreSQL debajo, desplegado en la nube, con su Actuator, sus métricas en Micrometer y una
suite de pruebas decente. **Nexo funciona.** Sirve el catálogo, la venta en línea, el pedido, la
promesa de entrega y la relación con tiendas, y lo hace bien. Es importante decirlo porque el curso
entero se puede leer mal: **Nexo no es el villano**, es la razón de que Meridian haya sobrevivido
la pandemia y de que once países funcionen con un equipo de dieciocho personas.

**Nocturno** es otra historia. Lo escribió un contratista en 2012 para ocho tiendas de un solo
país: procedimientos almacenados en PL/SQL orquestados por un batch en Java 6, desplegado en un
servidor que se migró tres veces sin volver a compilarse. Hoy corre para 140 tiendas de once
países. Nadie de los que lo escribieron trabaja en Meridian. **No se puede reanudar**, no emite
métricas, no sabe de zonas horarias —el parche de 2018 fue sumar y restar horas en SQL— y su única
señal de progreso es el tamaño de un archivo de log. Tarda tres horas cuando todo va bien, cinco
cuando no, y falla unas dos veces al mes.

Nocturno **es el sistema que el curso reemplaza**, y es el único. Y se reemplaza por una razón que
hay que decir sin adornos: no porque esté escrito en Java, sino porque está escrito sin
reanudación, sin observabilidad y sin zonas horarias. **Reescribirlo en Spring Batch habría
arreglado los tres problemas igual de bien**, y la Fase 16 existe precisamente para medir si Go
aportó algo más que entusiasmo.

> 🧭 **Regla de la ficción.** Nocturno, Nexo y el ERP se cuentan **en pasado y como contexto**.
> Ninguna fase abre su código, porque ninguna fase lo escribe. Lo que el estudiante construye es
> lo que está en las dieciocho fases, y nada más.

---

## 4. 🚪 Cómo llegaste tú

Respondiste a una oferta de empleo, y eso es deliberado: este curso **no es el del ingeniero
solitario y amigo de los dueños**. Es el del senior que entra a una empresa que ya tiene
plataforma, arquitecto, presupuesto aprobado y una opinión formada sobre cómo se hacen las cosas.

Llevabas **once años escribiendo Java**, los últimos seis en una empresa de logística: Spring Boot
en producción, JPA, Spring Batch, JUnit y Mockito, Testcontainers, un pipeline que mantenía alguien
más y un arquitecto que aprobaba los diseños. Sabes lo que hace `@Transactional` y sabes por qué a
veces no lo hace.

Entraste en marzo de 2026 al **equipo de plataforma: dieciocho personas**, y dentro de él a una
célula de cuatro que se creó para una sola cosa — **sacar el Cierre de Nocturno antes de que
termine el año**. El resto del equipo sigue en Nexo y va a seguir ahí.

Y entraste a un debate que ya estaba abierto. Cuando llegaste, la célula **ya había empezado a
reescribir el Cierre en Spring Boot 3 con Spring Batch**, y llevaba cuatro meses. Ese código
existe, funciona y está ajustado por la gente que mejor conoce Spring en la empresa. En tu tercera
semana propusiste medir una alternativa en Go, y lo que obtuviste no fue un sí: fue **un trimestre
y la obligación de traer números**.

Ese origen no es color narrativo. **Define las tres condiciones del curso:**

> 🧭 **Uno.** No estás en un terreno vacío. Nexo se queda, el ERP se queda, y los servicios que
> escribas tienen que convivir con ellos por HTTP y por base de datos, no reemplazarlos. Toda
> frontera que dibujes la vas a tener que defender.
>
> 🧭 **Dos.** Hay arquitecto, hay comité y hay una implementación rival que ya existe. No puedes
> ganar la discusión escribiendo código bonito: la ganas midiendo, y la puedes perder midiendo.
> Por eso `BENCHMARKS.md` no es un anexo del curso, es la mitad del curso.
>
> 🧭 **Tres.** Lo que construyas lo va a operar Wílmar y lo va a usar Nelly, y ninguno de los dos
> va a leer tu código. Un servicio que solo es defendible desde adentro no es defendible.

### 4.1 🪞 Por qué Go, si llevas once años escribiendo Java

Hay que decirlo de entrada, porque el curso se desacredita si finge lo contrario: **Java habría
funcionado, y de hecho ya estaba funcionando**. La versión Spring Boot del Cierre existe, la
escribió gente competente y resuelve el problema. Esta no es una decisión sobre cuál lenguaje es
mejor; es una decisión sobre **cuatro piezas concretas de una plataforma que ya es de Java**, y se
toma pieza por pieza.

Estas son las razones que escribiste en la propuesta de tu tercera semana, y ninguna de ellas es
"Go es más elegante":

**El borde, que es el argumento que pesa.** El agente de tienda corre en un mini-PC detrás de la
caja de la tienda ST-042, con cuatro gigas de RAM, un disco que ya tuvo un susto, sin nadie que
administre nada y con cortes de luz. Ahí no hay JVM que instalar ni actualizar: hay **un binario
estático de quince megas** que se copia, se ejecuta y sobrevive al reinicio. Y hay que compilarlo
para `linux/amd64`, `linux/arm64`, `darwin/arm64` y `windows/amd64` porque el parque de máquinas
de 140 tiendas no es homogéneo — con un comando, sin runtime. Eso no es una preferencia estética:
es la diferencia entre desplegar en 140 tiendas y no desplegarlo.

**La forma del trabajo de EventRelay.** Miles de entregas concurrentes, cada una esperando E/S de
red de un tercero lento, es exactamente el trabajo para el que existe una goroutine. Sí, la JVM
moderna tiene hebras virtuales y el curso **las mide en serio** (B-07), no las descarta con una
anécdota de 2015. Pero el modelo de contrapresión, el `select` sobre cancelación y el apagado
ordenado se leen en Go en un archivo que cabe en una pantalla, y eso importa cuando quien lo va a
depurar a las dos de la mañana es Wílmar con tu guía al lado.

**El costo de arranque y de memoria, que aquí se paga en factura.** El Cierre no es un servicio
que vive: es un proceso que arranca, procesa y muere, más 140 agentes que arrancan cada cinco
minutos. Un runtime que tarda en calentar y pide medio giga por instancia se nota cuando lo
multiplicas por 140, y se nota en la cuenta de la nube. Cuánto exactamente es B-21 y B-24, no una
afirmación de este párrafo.

**Y una razón que no es técnica y hay que declarar:** el equipo de plataforma quiere aprender Go y
Hernán lo sabe. Fingir que eso no pesa sería deshonesto. Lo que el curso no permite es que ese
deseo se disfrace de argumento de ingeniería — de ahí la regla de que ninguna afirmación de
rendimiento se escribe sin su medición, **incluidas las que parecen obvias**.

⚖️ **Dónde Java es mejor, y el curso lo va a medir en vez de discutirlo:** en el lote. **Spring
Batch resuelve reanudación, reintento por ítem, particionado y métricas de job**, y en Go eso se
escribe a mano — el curso lo escribe, cuenta cuántas líneas costó y quién las va a mantener. En el
ecosistema contable y fiscal, donde las librerías de facturación electrónica de los once países
existen para la JVM y para Go no. Y en la disponibilidad de gente: Bogotá y Ciudad de México
tienen diez veces más backends de Java senior que de Go, y el relevo es un criterio legítimo, no
una excusa.

🧭 La decisión, además, **es reversible por partes y hay que dejarla así**: cuatro servicios
separados, cada uno con su base de datos y su contrato HTTP, y el ERP y Nexo hablándoles por
donde les hablarían a cualquier otro. Si en 2028 el Cierre tiene que volver a la JVM porque el
operador de facturación de Guatemala solo entrega un SDK de Java, debe poder volver solo. **Una
decisión de lenguaje que no se puede revertir por pedazos no es una decisión de ingeniería, es
una apuesta.**

---

## 5. 🔒 La restricción que lo atraviesa todo: el dinero ajeno

Antes de cualquier proyecto hay dos fronteras que no se cruzan, y las dos vienen de que Meridian
mueve dinero que no es suyo.

**El dato de la tarjeta.** Meridian no procesa pagos: los procesa la pasarela. Lo que Meridian
recibe es un identificador de transacción, los últimos cuatro dígitos y un código de
autorización — **y nada más, nunca**. Un número de tarjeta completo dentro de la base de datos de
Meridian convierte a la empresa en sujeto de un alcance de cumplimiento que no está preparada
para sostener, y un número de tarjeta en un log lo convierte con la misma eficacia. Esto no es
teoría: en 2023 un desarrollador de Nexo dejó un `log.debug` con el cuerpo completo de la
respuesta de la pasarela y el equipo pasó un fin de semana rotando secretos y purgando índices de
log.

**El dato fiscal.** Un asiento contable y un documento fiscal timbrado son registros con
retención obligatoria, trazabilidad y un auditor externo que los va a pedir. De ahí salen tres
reglas que el curso trata como requisitos y no como buenas prácticas:

- **Los importes van en unidades mínimas y en entero.** `AmountMinor int64`, nunca `float64`. Un
  centavo perdido por redondeo, cinco millones de veces por noche, son cincuenta mil unidades
  monetarias que alguien va a buscar y que el auditor va a encontrar antes.
- **Todo lo que toca un periodo cerrado deja rastro.** Quién cerró, cuándo, con qué reglas y con
  qué tipo de cambio; y si se reabrió, quién y por qué. Un cierre que no se puede reproducir ocho
  meses después no es un cierre, es una opinión.
- **Los secretos no viajan por la API ni aparecen en un log.** El secreto de firma de un endpoint
  se escribe y no se vuelve a leer nunca, ni en una respuesta, ni en un mensaje de error, ni en un
  volcado de configuración al arrancar. El curso tiene un ejercicio 🧨 que consiste en registrarlo
  a propósito para ver exactamente qué queda en la salida.

Y encima de las dos, la protección de datos personales de once países, que es la razón por la que
el dato de cliente del marketplace **no entra a estos cuatro servicios**: el Cierre necesita
montos, tiendas, medios de pago y referencias, no necesita saber quién compró. Minimizar no es
una virtud abstracta aquí; es lo que mantiene el alcance del sistema pequeño y auditable.

Es una restricción incómoda, y por eso es buena materia: obliga a decisiones de diseño reales en
vez de a un CRUD de juguete.

---

## 6. 🏗️ Los cuatro servicios, contados desde la empresa

Los cuatro son piezas reales de la plataforma de Meridian, comparten el vocabulario de dominio de
`prompts/alcance-del-proyecto.md` §5.2, y **ninguno reemplaza a Nexo ni al ERP**. Lo que sigue es de
dónde sale cada uno en la empresa; el alcance técnico está en su `prompts/proyecto-NN-*.md`.

### 🗂️ OpsReport — los trabajos de la casa · *el reporte que tarda dos días*

Logística, tesorería, compras y soporte lanzan todos los días trabajos operativos que hoy viven
en hojas de cálculo y grupos de WhatsApp: importaciones de catálogo, conciliaciones puntuales,
recálculos de inventario, generación de extractos, reprocesos de archivos de proveedor. Se piden
por correo, se ejecutan a mano o por un script que alguien tiene en su máquina, y **nadie sabe
cuántos hay en curso, cuántos fallaron ayer, ni cuánto tarda en promedio una conciliación**.

El detonante fue menos dramático que el de EventRelay y más cotidiano: cada mes, cuando dirección
pide el reporte de operación, **una persona dedica dos días a juntarlo a mano** de cuatro fuentes,
y el dato que más se discute en el comité —cuántos reprocesos hubo y por qué— es justamente el que
nadie tiene.

Es, deliberadamente, **el servicio más parecido a lo que ya sabes hacer**: CRUD, jobs, base
relacional, reportes. Por eso es el primero. Lo que cambia no es el problema, es la forma de
resolverlo, y esa es toda la lección de las primeras siete fases.

📝 Su prueba de fuego es el reporte grande. El reporte de operación del mes son **medio millón de
filas**, y la versión ingenua —armar el `[]WorkItem` y serializarlo— se escribe primero a
propósito, se mide, y se ve la memoria subir. Ese es el momento en que `io.Writer` deja de ser una
interfaz de la biblioteca y se vuelve una decisión de diseño.

### 📡 EventRelay — los treinta socios · *los cuarenta y un minutos del 6 de diciembre*

Ya está contado en §1.2 y por eso aquí solo va lo que importa para el diseño: **EventRelay se
pone en medio**. El productor publica el evento, recibe un acuse en milisegundos y sigue con su
vida; la entrega ocurre después, con reintentos, retroceso exponencial, firma, historial de
intentos y cola de mensajes muertos. El sábado de diciembre no se repite porque el hilo del
productor ya no espera a nadie.

Si OpsReport es el servicio que un dev de Spring ya sabe hacer, **EventRelay es el que Go hace
notablemente mejor**, y es donde el curso se juega el argumento de concurrencia con los números de
B-07, B-09 y B-23 delante.

Y trae de regalo la conversación que Camilo necesita y hoy no puede tener: **veintinueve socios
bien y uno caído, y que eso no degrade a los veintinueve**. El fallo parcial como propiedad del
sistema, no como suerte.

### 🌍 AtlasSync — los once países · *el código de moneda que nadie revisó*

Meridian opera en once países. Cada uno tiene su moneda, su código ISO, su formato de dirección,
su zona horaria y su tipo de cambio del día, y esos datos los necesitan los cuatro servicios, el
ERP, la venta en línea y tres socios logísticos.

Hoy cada sistema los tiene copiados a mano en un archivo de configuración, y cada uno los tiene
copiados de forma ligeramente distinta. Cuando abrió Guatemala en 2024, **cuatro equipos hicieron
el mismo cambio en cuatro sitios y uno se equivocó**: escribió el código de moneda correcto con
el tipo de cambio de otra fecha, y once mil precios salieron mal durante cuatro días. Es la misma
familia de error que el de Ecuador en 2009, quince años después y con más ceros.

AtlasSync es un servicio **de lectura intensiva**: pocas escrituras, muchísimas lecturas, y una
dependencia externa que puede estar caída. Y ahí está su tesis, que es una decisión de producto
antes que técnica: **un catálogo de referencia nunca debe dejar de responder**. Si la fuente
externa se cayó, AtlasSync sirve el dato de ayer y **dice en la respuesta que es de ayer**, para
que el consumidor decida. Servir un dato viejo etiquetado es correcto; devolver un error porque un
tercero está caído es trasladarle el problema a las 140 tiendas.

### 🧾 ClearingHouse — el Cierre · *el duelo*

Es el proyecto del que cuelga §1.1 entero, y son dos piezas. El **agente** vive en la tienda,
acumula movimientos en SQLite con WAL, sobrevive a los cortes de luz y de enlace, sincroniza
cuando puede y **nunca borra un movimiento que el central no haya confirmado**. El **servicio
central** recibe los lotes, deduplica por `(store_id, external_ref)`, concilia por lotes
reanudables, produce asientos y cierra periodos.

Las tres propiedades que tiene que demostrar son las tres que Nocturno no tiene, y cada una es un
test: **reanudable** —matarlo al 60% y relanzarlo da el mismo resultado que no haberlo matado—,
**idempotente** —correrlo dos veces no duplica un asiento— y **acotado** —la memoria no crece con
el tamaño del lote—.

Y es el servicio del duelo. La versión Spring Boot **existe porque se escribió primero**, no
porque el curso la haya fabricado para perder: la escribió la célula con Spring Batch, con su
`JobRepository`, su reanudación y sus métricas, y está ajustada. El curso la trata con respeto,
la mide con la JVM configurada y también con `native-image`, y acepta el resultado. **Comparar
contra una JVM sin configurar es hacer trampa**, y un curso que hace trampa en su medición
central no vale nada.

---

## 7. ⚖️ El gemelo de Spring Boot, y por qué la comparación es honesta

Vale la pena detenerse en esto, porque es la decisión estructural más importante del curso y la
que más fácilmente se puede leer mal.

El gemelo Java **se entrega hecho**. No se enseña a escribirlo, por una razón simple: el lector ya
sabe escribirlo, y gastar tres fases en ello sería insultante. Existe para que la Fase 16 tenga
algo real que medir, y para que el veredicto no sea una opinión sobre Spring sino una tabla.

Las reglas del duelo, que vienen de la empresa y no del curso:

- **Mismo esquema, mismos endpoints, mismo cierre.** Si las dos implementaciones no resuelven
  exactamente el mismo problema, no hay comparación; hay dos programas distintos.
- **La JVM se configura.** Heap dimensionado, GC elegido a conciencia, y una corrida adicional con
  `native-image`. Medir contra los valores por defecto es medir contra un muñeco.
- **Se mide lo que le importa a Meridian**, no lo que favorece a Go: si el Cierre cabe en la
  ventana de dos horas, cuánta memoria pide, cuánto tarda en arrancar, cuánto pesa el artefacto,
  cuántas líneas hay que mantener y quién las va a mantener cuando el autor no esté.
- **Hernán lee el resultado.** Y su pregunta va a ser, palabra por palabra: *"esto que ganamos,
  ¿lo ganamos por Go o lo ganamos por haberlo escrito dos veces?"* — porque la segunda
  implementación de cualquier cosa es mejor que la primera, y esa es la trampa metodológica más
  común de este tipo de comparación. El curso está obligado a contestarla.

---

## 8. 🧰 De dónde sale cada decisión de infraestructura

La plataforma usa cuatro almacenes y una caché, y ninguno está ahí porque tocara enseñarlo. Cada
uno sale de una forma del dato que tiene la empresa:

| Pieza | El área que la pide | Por qué esa y no otra |
|---|---|---|
| **PostgreSQL** | Tesorería y contabilidad | Movimientos, asientos y periodos son relacionales, transaccionales y auditados. Y la cola de trabajo vive aquí: con `SELECT … FOR UPDATE SKIP LOCKED` no hace falta un broker para el volumen de Meridian, y la Fase 13 dice con números en qué punto deja de bastar |
| **SQLite** | Las 140 tiendas | Un mini-PC detrás de la caja, sin administrador, sin servidor de base de datos y con cortes de luz. Es el caso de SQLite, y es el caso del binario estático |
| **MongoDB** | Los once países | El dato de referencia externo llega con forma irregular y cambiante: un país tiene tres monedas, otro no tiene subregión, y el proveedor agrega campos sin avisar. Está justificado por **la forma del dato**, no por moda, y la Fase 11 discute qué habría pasado con `JSONB` |
| **Valkey** | La venta en línea | AtlasSync lo leen los cuatro servicios, el ERP y la vitrina, miles de veces por minuto, para un catálogo que cambia una vez al día. Y es donde viven el límite de tasa por socio y la idempotencia distribuida de EventRelay |
| **El ERP y Nexo** | Toda la empresa | No son del curso. Son la frontera, y cada servicio declara cómo les habla |

Y una decisión de lo que **no** hay, que es igual de importante: no hay Kafka, no hay Kubernetes y
no hay service mesh. Meridian tiene dieciocho personas en plataforma y una operación en la nube
que ya sostiene; agregar un broker y un orquestador para cuatro servicios es comprarse dos
sistemas nuevos para operar. El curso llega hasta la imagen de contenedor y el `compose`, y dice
en qué momento del crecimiento de la empresa eso deja de ser suficiente.

---

## 9. 🧭 El veredicto que el curso se debe a sí mismo

Al cierre, la célula presenta las decisiones con los números delante, y **el curso está obligado a
admitir dónde se equivocó**. Estos son los candidatos, y ninguno es retórico:

- **El Cierre probablemente debió quedarse en Spring Batch.** No por el rendimiento, que puede ir
  a favor de Go, sino porque la reanudación, el reintento por ítem y el particionado ya estaban
  resueltos y en Go hay que escribirlos y mantenerlos. Si el número de la Fase 16 es una mejora
  del veinte por ciento en la ventana, hay que ponerlo al lado de las líneas de código que alguien
  va a heredar y dejar que Hernán decida.
- **AtlasSync probablemente no necesitaba MongoDB.** Un `JSONB` en el PostgreSQL que ya existe,
  operado por gente que ya sabe operarlo, contra una base documental más para el inventario de
  Wílmar. Si al final del curso la respuesta honesta es que Mongo no aportó nada que `JSONB` no
  diera, hay que escribirlo.
- **EventRelay es el que se sostiene, y por eso hay que ser más duro con él.** ¿Se sostiene por
  Go, o se sostiene porque cualquier cosa que ponga una cola entre el productor y el socio habría
  evitado el 6 de diciembre? La segunda respuesta es incómoda y probablemente es la verdadera: el
  patrón valía más que el lenguaje.
- **Y uno que no es de software:** los treinta socios con treinta y cuatro convenios firmados, cuatro
  muertos y tres certificados por vencer no son un problema de plataforma. Son un problema de
  contratos que el software vuelve visible y después perpetúa. Si el resultado del proyecto es un
  modelo de datos capaz de representar treinta excepciones, **fracasaste con elegancia**.

Y la conclusión general que este escenario permite: **Go no te quita herramientas, te quita
intermediarios**, y eso se paga en líneas y se cobra en que no hay magia que depurar a las dos de
la mañana con Wílmar al teléfono. Cuál de los dos lados de ese intercambio conviene depende de la
pieza, y por eso la respuesta correcta del curso es "estos servicios sí, ese no" — con un número
por cada afirmación.

Si al final del curso resultara que Go ganó las cuatro, el curso estaría mal escrito.
