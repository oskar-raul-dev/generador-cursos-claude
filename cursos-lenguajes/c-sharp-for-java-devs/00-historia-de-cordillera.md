# 🏔️ Cordillera Media, la empresa del curso
## C# para desarrolladores Java senior

Documento de consulta, y **la fuente de verdad de todo lo narrativo**: la empresa, su sistema, sus
personajes, sus cifras y su cronología. Cuando una fase nombra a alguien, cita un año o usa un
número del negocio, sale de aquí — y si una fase y este documento se contradicen, gana este
documento y la fase se corrige.

Cordillera Media es ficticia, y conviene decirlo una vez: nada de lo que sigue describe a una
editorial real. Pero ninguna de sus incomodidades está inventada para que el curso quede bonito.
Cada decisión rara del sistema tiene un año y una razón que era correcta ese año, y esa es la
diferencia entre enseñar migración y burlarse del código heredado.

---

## 1. Cómo llegó a existir

**Ediciones Cordillera** abrió en Bogotá en 1979 con dos prensas de segunda mano compradas
al cierre de un taller litográfico de la carrera 13, y un catálogo de textos escolares que
Aurelio Bermúdez —maestro de escuela antes que editor— vendía él mismo, colegio por colegio,
en un Renault 4 que la empresa conservó veinte años en el sótano como si fuera un trofeo.

Los textos pagaban las cuentas. La literatura era el gusto de Aurelio, y durante quince años
fue una operación deficitaria que él sostuvo porque *"un catálogo sin literatura es una
papelería"*. La frase sigue colgada, enmarcada, en el pasillo del cuarto piso, y la gente
todavía la usa para ganar discusiones.

Durante los ochenta y noventa la empresa creció de la manera en que crecen las editoriales
latinoamericanas: comprando sellos pequeños que estaban a punto de cerrar y quedándose con
sus fondos. Así llegaron **Cometa**, literatura infantil desde Lima, en 1991; **Del Sur**,
ensayo y ciencias sociales, comprada en Buenos Aires en 1998 en plena crisis y por un precio
que todavía da vergüenza mencionar; y en 2004 la **Universitaria del Bajío**, una editorial
universitaria mexicana que traía algo más valioso que su catálogo — traía contratos de
distribución en México, que es el mercado que importa.

Aurelio le pasó la empresa a su hija **Clara Bermúdez** en 2003. Clara es abogada, no
editora, y esa diferencia se nota en todo: fue ella la que profesionalizó la contabilidad,
la que negoció las plataformas digitales y la que en 2021 dijo la frase que definió la
década tecnológica de la empresa. Ya llegaremos a esa frase.

Hoy el grupo se llama **Cordillera Media**, tiene 340 empleados, distribuye en nueve países
y sostiene un catálogo de **18.000 títulos**, de los cuales unos 11.000 siguen vivos
comercialmente. Cuatro sellos, tres almacenes —Bogotá, Ciudad de México y un depósito
alquilado en Lima—, dos plataformas digitales propias, y un 41% de los ingresos que ya no
viene del papel.

El cambio de nombre, en 2016, fue de "Ediciones" a "Media" porque para entonces publicaban
audiolibros, cursos en video y un pódcast que nadie escuchaba pero que la junta adoraba.
Internamente todos siguen diciendo "la editorial", y el que dice "el grupo" es de finanzas.

---

## 2. 🟦 Por qué esta historia, y por qué no hay ningún salto que justificar

La frontera que este curso tiene que cruzar no es una actualización de runtime: es .NET
Framework 4.8 contra .NET 10, dos plataformas con instaladores distintos, modelos de proyecto
distintos y una convivencia que dura años. Esta empresa es la que la sostiene de punta a punta.

**Cordillera nunca decidió ser una casa Microsoft.** Microsoft compró Fox Software en junio de
1992, y la decisión se tomó sola: la editorial ya estaba adentro y nadie firmó nada. Quince
años más tarde el mismo proveedor mató el producto, y después le vendió a Cordillera el camino
de salida. No hay que explicar por qué una empresa Java se pasó a .NET — **nunca fue una
empresa Java**. Lleva treinta y tres años en el ecosistema por inercia, que es como llega la
mayoría.

Y es dueña de su código, que es la condición sin la cual la fase de migración no tiene
material. Una empresa que licenció su sistema no puede migrarlo; solo puede hablarle desde
afuera.

---

## 3. 🧬 La genealogía del sistema, 1988–2026

**1988.** El contador consigue que le compren un **PS/2** y monta la facturación en **dBase III
Plus**. Es él, no sistemas, porque no hay sistemas. La máquina vive en su oficina, con llave, y
el respaldo son dos diskettes que se guardan en la caja fuerte junto con las escrituras.

**1993 · el sistema, y todavía sin red.** Cordillera tiene 45 empleados y seis computadores
—386 y 486, 4 MB de RAM, monitores VGA— repartidos entre contabilidad, facturación, almacén y
la gerencia. Contratan a **Fabio Rincón**, un desarrollador independiente, para hacer "el
sistema" en **FoxPro 2.5 para DOS**: catálogo, inventario, facturación y regalías. Cobra por
horas durante dos años, entrega, y en 1996 se va a Miami. Sus iniciales siguen en producción:
hay una tabla `FR_TMP` que nadie ha borrado en treinta años.

Ese sistema no está en red, porque en 1993 no hay red. Los DBF viven en el disco duro de la
máquina de facturación; el almacén tiene su propia copia y **manda los movimientos del día en
un diskette de 3½** que alguien sube al segundo piso a las seis de la tarde. Cuando hay que
pasar algo entre dos máquinas y el archivo no cabe en el diskette, se conecta el **cable
paralelo de LapLink** entre los dos puertos y se transfiere directo. El cierre de mes es una
persona consolidando a mano lo que el diskette no alcanzó a traer, y las discrepancias entre la
copia del almacén y la de facturación son el primer problema de datos que tuvo esta empresa.

**1995 · el cable amarillo.** Cordillera pone su primera red: **coaxial delgado 10BASE2**, cable
RG-58 que va de máquina en máquina con conectores BNC en T y un terminador de 50 Ω en cada
punta, y **LANtastic** encima para compartir carpetas. No hay servidor de base de datos ni lo
habrá en doce años: hay una **carpeta compartida** donde viven los DBF, y cada FoxPro abre los
archivos por la red como si fueran locales. Se acabó el diskette y empezaron los bloqueos, los
índices corruptos y el ritual del `REINDEX` de los lunes — casi siempre porque alguien apagó su
máquina con un formulario abierto, y una vez memorable porque el de mantenimiento movió un
escritorio y aflojó un terminador, dejando media oficina fuera de la red sin ningún mensaje de
error.

**1997 · Windows, y el modelo de datos que llegó hasta hoy.** Migración a **Visual FoxPro 5** y
a Windows 95, con la red ya sobre par trenzado y un concentrador. Es el año que importa, porque
**aquí se congela el modelo de datos que Cordillera sigue usando en 2026**. Nombres de campo de
diez caracteres, nombres de tabla de ocho, fechas guardadas como cadena, borrado lógico por
bandera, una tabla por año. Todas esas decisiones eran correctas en FoxPro — el formato DBF
limita el nombre de campo a diez caracteres, DOS limitaba el del archivo a ocho, el registro
borrado es una marca en el propio archivo y no una fila que desaparece, y partir por año era
cómo se evitaba que una tabla creciera hasta donde el motor empezaba a sufrir. **Ninguna
sobrevive bien.**

**2004.** Visual FoxPro 9, que resultará ser la última versión que existirá jamás. Nadie lo
sabe todavía.

**2007.** Microsoft anuncia que no habrá VFP 10. En Cordillera nadie se entera; el sistema
funciona y la editorial está comprando la Universitaria del Bajío.

**2015.** Termina el soporte extendido, y esta vez sí duele: las máquinas nuevas vienen con
Windows 10, los controladores de impresora fiscal dejan de funcionar y el ejecutable arranca
cuando quiere. Por primera vez el problema es visible desde la gerencia.

**2016–2017 · la migración de los pasantes.** El "departamento de sistemas" es **Wilson
Pardo**, que entró en 2008 a manejar la red, los correos y las impresoras, y que sabe hacer eso
muy bien. Wilson no es desarrollador y nunca dijo que lo fuera. Con un presupuesto que alcanzaba
para lo que alcanzaba, contrató a **tres pasantes** de un instituto técnico.

Los tres hicieron, en once meses, lo que nadie más quiso hacer. Usaron el asistente de
importación de SQL Server 2014 y pasaron las tablas DBF **una por una, con sus nombres
intactos**. Encima escribieron una aplicación en **Visual Studio 2015 sobre .NET Framework
4.5**, **Windows Forms**, 340 formularios contra el servidor, escribiendo C# como si fuera C# 2
porque así lo habían aprendido. Los reportes en **Crystal Reports**, porque era el camino que ya
conocían desde FoxPro. Y la lógica de negocio que vivía en el código FoxPro la reescribieron en
**procedimientos almacenados**, porque era donde sabían ponerla — y lo que no cupo ahí se quedó
en los manejadores de los botones.

Salió. Facturó. Reemplazó a un sistema de veinte años sin parar la operación. **Eso no es poco
y el curso no lo va a tratar con condescendencia.**

**2019 · "hacerlo web".** El distribuidor mexicano pide integración, y la respuesta es montar
**servicios ASMX sobre IIS** que envuelven los mismos procedimientos almacenados y devuelven
`DataSet` serializado, más un portal pequeño en **Web Forms** para consulta de catálogo. Para
entonces dos de los tres pasantes ya se fueron. Queda **Duván Cifuentes**, que tenía 22 años
cuando empezó y hoy tiene 31, y que es la única persona viva que entiende el sistema completo.

**2020 · la nube, a medias.** Con la pandemia y el centro de datos de la calle 100 vuelto un
problema logístico, Cordillera se va a **Azure**. Pero se va como se va casi todo el mundo:
**lift and shift a máquinas virtuales**. Cuatro VMs con IIS, una VM con SQL Server licenciado, y
los clientes WinForms de las oficinas conectándose por VPN a una base que ahora está más lejos
que antes. En México la aplicación se volvió notablemente más lenta y la respuesta oficial fue
"es la conexión". La factura mensual quedó un 30% por encima del centro de datos que reemplazó,
y nadie se atreve a decirlo en junta.

**2026.** En el depósito de Lima todavía corre **"el Fox"** —una máquina virtual con Windows XP
y un ejecutable de Visual FoxPro 9— para el módulo de inventario, porque ese nunca se migró.
Lima manda un archivo plano todos los viernes. Wilson mantiene esa VM viva por pura terquedad
profesional, y tiene razón.

📝 El nombre **SIGE** —Sistema Integral de Gestión Editorial— se lo puso Duván a la pantalla de
bienvenida en 2017. Nadie lo usa. Todo el mundo, incluida la presidenta, dice **"el sistema"**.

### 3.1 📝 Nota de verosimilitud: por qué esta línea de tiempo se sostiene

La historia se apoya en fechas y en prácticas reales, no en ambiente. Conviene dejarlas
escritas, porque el curso las va a usar como material y alguien las va a verificar:

| Hito de la historia | Realidad | Fecha |
|---|---|---|
| dBase III Plus en un PS/2 | dBase III Plus es de 1985; la línea PS/2 de IBM, de 1987 | ✅ coherente en 1988 |
| FoxPro 2.5 para DOS | Versión publicada en 1993, ya bajo Microsoft | ✅ exacta |
| "la decisión se tomó sola" | Microsoft compró Fox Software en junio de 1992 | ✅ exacta |
| Visual FoxPro 5 | Publicada a finales de 1996 | ✅ coherente en 1997 |
| Visual FoxPro 9, la última | Publicada en diciembre de 2004; no hubo VFP 10 | ✅ exacta |
| El anuncio de fin de línea | Microsoft lo confirma en marzo de 2007 | ✅ exacta |
| Fin del soporte extendido | Enero de 2015 | ✅ exacta |

Y sobre lo que más se presta a duda —**si una editorial de ese tamaño podía tener FoxPro en los
computadores de la oficina a inicios de los noventa**— la respuesta es que era justamente el
caso típico, no la excepción:

- **El tamaño encaja.** En 1993 Cordillera es una empresa de ~45 personas con seis computadores.
  FoxPro 2.5 para DOS corría sin problema en un 386 con 4 MB de RAM, y una licencia por máquina
  estaba al alcance de una empresa mediana. El xBase —dBase, Clipper, FoxPro— fue *la* plataforma
  administrativa de la pequeña y mediana empresa latinoamericana durante esa década, y el modelo
  de contratar a un independiente que "hace el sistema" y cobra por horas es exactamente cómo se
  construyó la mayoría de esos sistemas.
- **No tener red era lo normal, y el diskette era el bus de datos.** Conectar seis máquinas
  costaba dinero real en tarjetas, cable y licencias, y muchas empresas simplemente no lo
  gastaban hasta que el dolor del cierre de mes lo justificaba. Mientras tanto se movían archivos
  en diskette de 3½, o **directamente entre dos máquinas con un cable paralelo o serial** y un
  programa de transferencia tipo LapLink o Interlnk — eso es literalmente "conectar los
  computadores con cable" y era una práctica corriente.
- **Cuando llegó la red, llegó así.** El salto natural de 1994–1996 era **Ethernet coaxial
  delgado (10BASE2)**: un solo cable RG-58 pasando de máquina en máquina con T de BNC y
  terminadores en los extremos, sin concentrador, con **LANtastic**, NetWare Lite o Windows for
  Workgroups 3.11 encima para compartir carpetas. Frágil por diseño: un conector suelto tumbaba
  el segmento entero, y por eso el par trenzado con concentrador lo reemplazó apenas bajó de
  precio.
- **La arquitectura que eso produce es la que explica el sistema de hoy.** FoxPro no tenía
  servidor de base de datos: los DBF vivían en una carpeta compartida y cada cliente los abría
  por la red, con bloqueo por registro y sin nada que garantizara la integridad más allá de lo
  que el programa recordara comprobar. De ahí salen, en línea recta, tres de los rasgos que el
  curso va a atacar treinta años después: la ausencia de llaves foráneas, el borrado por bandera
  y la partición de las ventas en una tabla por año.

🧭 Para el curso, lo importante de esta sección no es la nostalgia: es que **cada decisión
incómoda del esquema actual tiene un origen razonable y datable**. Esa es la diferencia entre
enseñar migración y burlarse del código heredado.

---

## 4. 🩻 Cómo se ve el sistema por dentro

Este inventario es el material didáctico del curso, y conviene tenerlo escrito:

- **340 formularios WinForms**, unas 250.000 líneas de C#, y **cerca de 700 procedimientos
  almacenados** donde vive la lógica de negocio de verdad.
- **El cliente se conecta directo a SQL Server.** Cadena de conexión en el `App.config`, la
  misma para todas las instalaciones, con permisos de escritura sobre todo. Arquitectura de dos
  capas de 1997 corriendo sobre Azure en 2026.
- **Nombres heredados de FoxPro**: campos de diez caracteres (`VLRUNIT`, `FECMOVTO`, `CODEDIT`),
  tablas de ocho (`MOVINVEN`, `LIQREGAL`).
- **Sin llaves foráneas.** La integridad la garantiza "el sistema", que es una forma elegante de
  decir que no la garantiza nadie. Hay 1.900 movimientos de inventario cuyo título ya no existe.
- **Fechas en `char(8)` con formato `AAAAMMDD`** en once tablas, y en `datetime` en el resto. Hay
  código que convierte de una a otra en los dos sentidos, y no siempre igual.
- **Bandera `BORRADO char(1)` en todas las tablas**, herencia directa de la semántica de borrado
  de FoxPro. Nada se elimina nunca, y la mitad de las consultas se olvidan de filtrarla.
- **Una tabla por año**: `VENTAS_1997` hasta `VENTAS_2026`. Los reportes históricos son un
  `UNION ALL` de treinta tablas construido concatenando cadenas en tiempo de ejecución.
- **Sin Unicode.** `varchar` con una intercalación que se comió las tildes de los títulos
  peruanos en la importación de 2017; nadie lo notó hasta 2021 y ya no se puede reconstruir.
- **Campos `CAMPO1` a `CAMPO7`** en cuatro tablas, que en algún momento de los noventa
  significaron algo.
- **Crystal Reports 13** con sus propias conexiones a la base, por fuera de la aplicación.
- **Los servicios ASMX** envuelven procedimientos almacenados y devuelven `DataSet` serializado
  a un socio comercial que lleva siete años quejándose.

---

## 5. Quién es quién

Seis personas que vas a encontrar en cada fase del curso, porque son las que piden las cosas y
las que sufren cuando salen mal.

**Clara Bermúdez**, presidenta. Abogada. Entiende de contratos y de riesgo, no de arquitectura,
y por eso hace las preguntas incómodas correctas: *"si esto se cae un martes, ¿quién lo
levanta?"*.

**Wilson Pardo**, jefe de sistemas. Entró en 2008 para la red, los correos y las impresoras, y
lo hace bien. Coordinó la migración de 2017 porque no había nadie más, y sabe perfectamente que
esa no era su especialidad. No te va a estorbar; te va a ayudar más de lo que esperas, y conoce
la operación mejor que nadie. **Aquí no hay ni hubo nunca un arquitecto**, y esa ausencia
explica más del sistema que cualquier decisión técnica.

**Duván Cifuentes**, 31 años, desarrollador. Entró de pasante en 2016 y se quedó. Es autodidacta,
es el único que entiende el sistema completo, y lleva nueve años sosteniendo solo algo que no
diseñó. Su código de 2017 es malo; el de 2024 ya no lo es. **Duván no es el obstáculo del curso:
es la razón por la que la migración tiene que quedar en algo que él pueda mantener.** El día que
Duván renuncie, la editorial tiene un problema existencial, y él lo sabe y no lo usa.

**Ximena Alzate**, directora editorial. Publica ocho títulos al mes con un equipo que debería
publicar cuatro. Cualquier herramienta que le agregue un paso al flujo, la va a sabotear, y va a
tener razón.

**Nohora Prieto**, coordinadora de operaciones editoriales. Es quien de verdad hace que un libro
salga. Escribió en 2022 una macro de Excel de 600 líneas que hoy usan tres sellos y que nadie se
atreve a tocar. **Nohora es tu usuaria real**, y buena parte del curso se juega en si ella puede
seguir trabajando el lunes con lo que tú entregaste el viernes.

**Gustavo Lemos**, director comercial. Treinta y un años en el negocio. Decide los tirajes
mirando el título, la portada y el mes, y acierta con una frecuencia que incomoda. Es el
baseline contra el que se va a medir un modelo de aprendizaje automático, y no lo va a poner
fácil.

---

## 6. 🪞 Cómo llegaste tú, y por qué tu primer instinto está mal

Cordillera te contrató en 2025 porque llegó al punto en que Wilson no podía más y Duván no
alcanzaba. Vienes de **once años escribiendo Java en un banco**: equipos de quince, arquitecto
que aprueba diseños, comité que aprueba al arquitecto, pipeline que mantiene alguien cuyo nombre
no sabes.

El día once escribiste un documento de tres páginas proponiendo reescribir todo en Spring Boot.
**Ese instinto es el primero que el curso te va a quitar**, y no con doctrina sino con
aritmética:

- Hay **700 procedimientos almacenados** que nadie ha leído completos, y la lógica de negocio de
  la editorial está ahí y en ningún otro lado. Reescribir el lenguaje no te ahorra ni una hora
  de ese trabajo; te añade una frontera más que cruzar.
- Las **licencias de SQL Server están pagadas** y el beneficio híbrido de Azure las hace valer
  aún más. Salir de ahí es una decisión de cientos de millones que no depende de ti.
- **Duván sabe C#.** Es quien va a sostener esto cuando tú te vayas, y te vas a ir. Una
  plataforma que tu único compañero no domina es una plataforma que dura lo que dures tú.
- **.NET 10 corre en Linux, en contenedor, sin impuesto de Windows.** El argumento de plataforma
  que hacía sentido en 2012 ya no existe.

Y la parte honesta, que el curso también dice: **no es que Java fuera peor.** Es que en una
migración así el lenguaje es la variable más barata, y cambiarla te cuesta lo único que no
puedes reponer, que es la gente que entiende el dominio.

En 2021, cuando un consultor propuso rehacerlo todo en microservicios en dos años y medio, Clara
lo rechazó con la frase que define la década: *"Ustedes me están pidiendo que pare la editorial
dos años para que el sistema se vea mejor por dentro."* Esa frase es la restricción de diseño de
todo lo que vas a construir.

> 🧭 **Nada de lo que hagas puede apagar el sistema.** La editorial factura todos los días
> mientras tú migras, y el único camino permitido es por partes, con vuelta atrás en cada paso.

---

## 7. ☁️ La gravedad de Azure

El curso no puede enseñar .NET fingiendo que Azure no existe — sería como enseñar Go sin
contenedores. Pero tampoco puede ser un folleto. La regla del curso es una sola:
**cada servicio gestionado que se adopta se mide contra lo que reemplaza, y se declara su costo
y su amarre.** Y el lift and shift de 2020 convierte cada fase en una pregunta real: *¿esta
pieza debe seguir en una VM, o gana algo si se vuelve PaaS?*

- **Cómputo** — App Service contra Container Apps contra AKS contra la VM que ya tienen, con la
  conclusión incómoda de que para Cordillera AKS es casi seguro un error.
- **Datos** — Azure SQL Database contra SQL Server en VM: licencia, mantenimiento, failover, y
  qué se rompe de los 700 procedimientos al cambiar de nivel de compatibilidad.
- **Mensajería** — Service Bus para el outbox y las notificaciones a socios, contra la tabla de
  cola que ya existe en SQL Server y que funciona.
- **Almacenamiento** — Blob Storage para portadas, PDFs de imprenta, EPUB y audiolibros, que hoy
  viven en un recurso compartido de red que se llena dos veces al año.
- **Identidad** — Entra ID para el back-office y para los socios, contra la tabla de usuarios de
  2017 con contraseñas hasheadas con un algoritmo que da pena.
- **Secretos y configuración** — Key Vault y App Configuration contra la cadena de conexión que
  hoy viaja dentro de cada `App.config` instalado en 90 equipos.
- **Observabilidad** — Application Insights y OpenTelemetry, contra los archivos de log rotados
  a mano y el `MessageBox.Show` que quedó en producción en dos formularios.
- **Serverless** — Azure Functions y Durable Functions serían el caso de libro para la publicación
  programada en nueve husos. **El curso lo declara fuera**, y con su razón: la F17 resuelve la
  reanudación con un proceso propio de doscientas líneas, y verla construida a mano enseña el
  mecanismo que una orquestación durable esconde.
- **Entrega** — Azure DevOps (que ya usan porque venía con la casa) contra GitHub Actions.
- **IA** — Azure OpenAI y Azure AI Search para la recuperación documental, con el veredicto
  honesto sobre Semantic Kernel: cuándo aporta y cuándo es una capa que te cobra abstracción sin
  devolverte nada.

Y una fase entera para lo que nadie enseña: **la factura**. Qué cuesta cada opción al volumen
real de Cordillera, dónde está el amarre, y qué se podría mover a otro proveedor un martes.

---

## 8. Los cuatro proyectos empresariales

| # | Proyecto | Registro | Stack | Idea base |
|---|---|---|---|---|
| 1 ⭐ | **El sistema, por partes** | La migración | .NET Framework 4.8 → .NET 10, patrón *strangler fig* | El eje del curso: sacar la lógica de los procedimientos, cortar la conexión directa del cliente a la base, y solo entonces mover el runtime |
| 2 | **CatalogAPI** | Servicio hacia afuera | ASP.NET Core minimal APIs + EF Core + Azure SQL + Service Bus | El ultimátum de Almenara, y el mejor capítulo posible de EF Core porque el esquema es hostil |
| 3 | **Redacción** | Back-office | Blazor + EF Core + Entra ID | Cuarenta pantallas, roles y auditoría, con Blazor Server ⇄ WebAssembly ⇄ MVC medidos de verdad |
| 4 | **NightPress** | Proceso de fondo | Worker Service (`IHostedService`) + cola, medida contra mensajería administrada | El cierre de regalías, reanudable, idempotente y auditable |

### 🧱 El sistema, por partes · *el proyecto que es el curso*

La migración no es una fase: es el eje. Y el orden importa más que la tecnología.

Primero hay que **sacar la lógica de los procedimientos almacenados** y darle un modelo de
dominio, lo que obliga a leer setecientos procedimientos que nadie ha leído completos y a
descubrir, en el camino, las reglas que la editorial cree que tiene y las que de verdad aplica.
Después hay que **cortar la conexión directa del cliente a la base**, poniendo una API en medio,
porque mientras noventa instalaciones tengan permiso de escritura sobre todo con la misma
cadena de conexión, cualquier otra mejora es cosmética. Y solo entonces se mueve el runtime:
ASMX y `DataSet` hacia minimal APIs o gRPC con tipos reales, Crystal Reports hacia lo que la
medición diga.

Y atravesando todo, la pregunta que solo existe en este ecosistema: **qué pasa con los 340
formularios**. WinForms sobre .NET 10 sigue siendo una opción legítima y hay que decirlo; MAUI,
Blazor Hybrid y una web interna son las otras tres. El curso mide las cuatro contra lo que de
verdad importa — que noventa personas en nueve países puedan seguir trabajando el lunes.

### 🌐 CatalogAPI — el catálogo hacia afuera · *el ultimátum de Almenara*

Los datos del catálogo están presos dentro del sistema. Los distribuidores, la web, la app y
tres socios comerciales reciben cada uno un volcado CSV nocturno distinto, generado por cuatro
trabajos del Agent que se escribieron en años diferentes y que hoy están desincronizados entre
sí. Cuando cambia un precio, el mundo se entera al día siguiente. Y cuando un título se agota,
se sigue vendiendo durante veinte horas.

En noviembre pasado **Grupo Almenara** —la cadena minorista más grande de México, el 14% de la
facturación del grupo— puso una condición para renovar el contrato: **API real, con SLA de
disponibilidad, o buscamos otro proveedor**. No fue una negociación. Fue un correo de cuatro
líneas del área de compras, y el comité entendió el mensaje.

CatalogAPI no reescribe el sistema: se pone delante. Sirve el catálogo optimizado para lectura,
notifica por webhook los cambios de precio y disponibilidad en segundos en vez de en un día, y
le da al equipo de la web algo con lo que trabajar que no sea un CSV de anoche.

Es también donde EF Core se enseña en serio, porque el esquema es hostil de una forma que
ningún tutorial reproduce: sin llaves foráneas, con banderas de borrado, con fechas en cadena y
con treinta tablas anuales. Aquí se aprende cuándo configurar EF Core a mano, cuándo rendirse y
usar Dapper, y cuándo lo correcto es arreglar el esquema.

### 🏛️ Redacción — el back-office · *el flujo que vive en el correo*

El camino de un manuscrito —recepción, lectura, informe de lectura, contrato, edición,
maquetación, pruebas, imprenta— vive hoy en correos, en una hoja compartida y en una carpeta de
Drive cuyos permisos nadie audita desde 2019. En marzo se descubrió que un traductor externo
llevaba dos años con acceso de edición a la carpeta de contratos.

Las editoras no son ingenieras: necesitan formularios, estados, un historial de quién cambió qué,
y necesitan que Nohora pueda corregir un registro mal grabado a las siete de la tarde sin llamar
a nadie. Ximena, además, va a evaluar la herramienta con un único criterio: si le agrega pasos a
su equipo, no la usa.

Son unas cuarenta pantallas de CRUD, un modelo de permisos por rol y un rastro de auditoría, y
no hay equipo de frontend: hay dos personas de web que mantienen la tienda. Por eso este
proyecto trae la comparación que solo este ecosistema permite hacer con honestidad —**Blazor
Server contra Blazor WebAssembly contra MVC clásico**— con la latencia medida desde Bogotá, desde
Ciudad de México y desde el depósito de Lima, que es donde la conexión es mala de verdad.

### 🌙 NightPress — el cierre nocturno · *la liquidación que nadie puede reproducir*

Las regalías son el problema difícil del negocio. Las ventas llegan de nueve países, tres
distribuidores y dos plataformas digitales; cada uno manda un archivo distinto, en su moneda, en
su huso, con su política de devoluciones y su propio criterio sobre qué mes es una venta. El
cálculo trimestral corre hoy en **tres procedimientos almacenados de setecientas líneas y un
trabajo del SQL Server Agent**, tarda seis horas, **falló en la hora cinco dos veces el año
pasado**, y cuando falla se reinicia desde cero.

Peor: dos veces al año un autor impugna su liquidación. La última vez fue una traductora con
contrato de participación, y reproducir el número exacto que se había calculado ocho meses antes
tomó tres días de arqueología entre respaldos, porque las tasas de cambio usadas en el cálculo
no se guardaron en ninguna parte.

NightPress necesita ser reanudable por lotes, idempotente, y **auditable línea por línea**: qué
se sumó, con qué tasa, bajo qué cláusula. Y además se lleva la publicación programada — cuando un
título sale a la venta a medianoche, sale a medianoche en nueve husos horarios, no cuando termine
un trabajo del Agent.

---

## 9. 🤖 Los dos proyectos de IA

**AcervoRAG** nace de una pregunta que se hace todas las semanas y que cuesta dos días
responder: *"¿tenemos los derechos en portugués de este título para Brasil?"*. Cuarenta y siete
años de contratos, adendas, cesiones por territorio, idioma, formato y plazo, buena parte en PDFs
escaneados de originales mecanografiados. Los de Del Sur están en español rioplatense y los de la
Universitaria del Bajío usan una terminología jurídica mexicana que no coincide con la
colombiana. Y en paralelo, las editoras quieren saber si un manuscrito recibido se solapa con
algo que ya está en el fondo — el año pasado se compró un ensayo que resultó ser, en un 40%, un
libro que Del Sur había publicado en 2006.

Lo que hace este proyecto valioso pedagógicamente es su exigencia: **cada respuesta cita el
documento, la versión y la cláusula, o no se emite**. Una alucinación sobre un contrato de
derechos no es una molestia, es una demanda — y la presidenta es abogada, así que esa
conversación la vas a tener con alguien que sabe. Ese requisito obliga a hacer bien la
evaluación, y abre la comparación honesta entre Azure AI Search, la búsqueda vectorial que el
propio SQL Server ya ofrece, y la respuesta incómoda de que a veces una búsqueda por texto
completo le gana a todo el aparato de embeddings.

**EditorAgent** atiende los **400 manuscritos no solicitados que llegan al mes** al correo
`publicaconnosotros@`. Alguien tiene que mirarlos: ¿es de un género que publicamos?, ¿los
metadatos están completos?, ¿duplica algo del catálogo?, ¿de qué va? Hoy los mira una
practicante, tres horas al día, y el sesgo del cansancio es real: los que llegan los viernes
tienen medible peor suerte.

El agente usa herramientas —llama a CatalogAPI y a los servicios que salieron de la migración— y
produce una ficha de triaje estructurada. Y no decide nada: **prepara para que decida una
persona**. Con evaluación seria, porque un agente que descarta en silencio un buen libro es el
error más caro que puede cometer una editorial, y es además el único error que nunca vas a poder
medir en producción.

📝 Aquí va el veredicto sobre **Semantic Kernel**: cuándo aporta orquestación real y cuándo es
una capa que te cobra abstracción sin devolverte nada frente a llamar al SDK directamente.

---

## 10. 📊 Los datos, y hasta dónde llega .NET

La editorial tiene dos problemas de datos que son un regalo didáctico.

**Las ventas mienten durante noventa días.** Los textos escolares venden en enero–marzo en el
hemisferio norte y en febrero–abril en el sur, la literatura vende en noviembre y diciembre en
todas partes, y el ensayo no tiene temporada sino que responde a la coyuntura política de cada
país. Encima, **las devoluciones llegan a rozar el 30%** y aparecen meses después, así que hay
que separar honestamente sell-in, sell-out y devolución, por país, sello y canal — con datos de
tres distribuidores con tres calendarios y dos plataformas que reportan en semanas ISO mientras
la contabilidad cierra por mes natural. Ese es el *sell-in* que Gustavo lleva treinta años
corrigiendo de cabeza y que nunca ha escrito en ninguna parte.

**Y alguien tiene que decidir el tiraje.** Imprimir de más es almacén, y al final destrucción de
ejemplares —Cordillera destruyó 41.000 en 2024, un número que en la junta se menciona en voz
baja—. Imprimir de menos es quedarse sin stock justo en las seis semanas que deciden la vida
comercial de un libro. Hoy lo decide Gustavo, y el modelo se mide contra él y contra un baseline
tonto —*"lo mismo que el título anterior del mismo autor"*—, aceptando el resultado que salga:
para un autor debutante sin histórico, el criterio de alguien que lleva treinta años mirando
portadas gana sin discusión.

⚖️ El veredicto de esta parte está decidido de antemano y el curso lo dice sin rodeos: **ML.NET
existe, se presenta, y para este trabajo lo honesto es entrenar en Python y servir desde .NET**.
Por eso esto no es un proyecto sino una **fase de cierre** sobre interoperar con el mundo Python
y servir con **ONNX Runtime** un modelo entrenado afuera. Lo que sí es responsabilidad de .NET
—y donde hay que medir— es la canalización que prepara esos datos y el servicio que expone la
predicción dentro del sistema.

---

## 11. 🚀 Lo que este ecosistema le da al curso

El volumen de Cordillera es lo bastante grande como para que el trabajo de rendimiento sea
honesto y no un microbenchmark de juguete: `IAsyncEnumerable` para el reporte de 500.000 filas,
`Span<T>` y `Memory<T>` sobre los archivos de venta de los distribuidores, generadores de origen
de `System.Text.Json`, `Channel<T>` en el cierre nocturno, y **AOT nativo contra JIT** con
arranque en frío medido sobre la factura de Azure, que es donde el arranque en frío cuesta
dinero.

⚠️ **Ojo con el capítulo de rendimiento.** Con treinta tablas anuales unidas por `UNION ALL`
generado concatenando cadenas, el primer orden de magnitud no está en .NET: está en el plan de
consulta. El curso tiene que declararlo y medir en ese orden — **primero SQL, después .NET**—,
porque la lección honesta es que optimizar C# encima de una consulta mala es teatro.

---

## 12. De dónde salen los tracks opcionales

Cada track opcional es un departamento real de Cordillera, y por eso ninguno se siente como
relleno.

| Track | El área que lo pide | Lo que necesita |
|---|---|---|
| `ui` | Comercial y dirección | Un tablero de ventas que no sea un Excel enviado por correo, y la presentación trimestral de junta **generada**, no armada a mano la noche anterior por el asistente de Clara |
| `ar` | Producción | Portadas en seis formatos por título, PDF de imprenta contra PDF de web, EPUB para cuatro tiendas con requisitos incompatibles entre sí, y los metadatos **ONIX 3.0** que el distribuidor valida sin piedad |
| `au` | Inteligencia comercial y QA | Qué publicó la competencia y a qué precio está en cada tienda, pruebas e2e de la tienda propia, y el enlace con el servidor de la imprenta de Bogotá que solo habla por SSH y solo acepta un archivo con un nombre exacto |
| `db` | La deuda de las adquisiciones | El MySQL de la web vieja, MongoDB con los eventos de lectura digital, y Valkey delante del catálogo — todo contra el SQL Server que ya está pagado |
| `cv` | Lo que no vas a migrar | **Convivir**: la plataforma en Java que vino con la Universitaria del Bajío y nunca se integró del todo tras la adquisición de 2004, y **"el Fox"** de Lima, que no es Java pero plantea el mismo problema — un sistema vivo al que hay que hablarle sin tocarlo |

📝 El track `cv` es el que más se parece a tu vida real después del curso, y por eso no es
opcional del todo: la mitad de las empresas que adoptan .NET moderno lo hacen con algo en Java
al lado que nadie va a apagar.

---

## 13. ⚔️ El duelo final, que aquí es mejor

**El duelo más parejo que existe es ASP.NET Core contra Spring Boot 3**: dos plataformas de la
misma generación, el mismo perfil de empresa, la misma clase de herramientas y equipos
intercambiables. Medir contra algo de otra categoría habría sido más fácil y habría enseñado
menos. Por eso CatalogAPI se
implementa **dos veces**.

Es también el más difícil de ganar limpiamente, y por eso el más valioso: aquí no hay un
"arranca en quince milisegundos" que zanje la discusión. Hay que medir rendimiento, costo de
nube, productividad, contratación y ecosistema, y aceptar que en varias columnas el resultado va
a ser **empate** — que es la palabra que menos aparece en los cursos de tecnología y la que más
falta hace.

---

## 14. ⚖️ El veredicto que el curso se debe a sí mismo

Al cierre, Cordillera revisa la decisión de 2020 y las que tomaste tú, **con los datos en la
mano y obligada a admitir dónde se equivocó**:

- **El lift and shift de 2020 fue un error**, y el curso lo cuantifica con la factura en la mano
  sin absolver a nadie — tampoco a quien lo aprobó por miedo, que es la razón real por la que se
  hizo así.
- **Parte del sistema no debió migrarse.** El módulo de inventarios funciona, no cambia, y
  gastarle seis meses a llevarlo a .NET 10 es orgullo de ingeniería, no negocio. "El Fox" de Lima
  lleva veintinueve años funcionando y puede llevar tres más.
- **Blazor Server puede ser la decisión equivocada** para las oficinas de Lima y Ciudad de
  México, y la medición lo dirá antes de que sea tarde.
- **CatalogAPI contra Spring Boot**, al volumen real de Cordillera, es una moneda al aire que se
  decide por el equipo disponible y no por el rendimiento.
- **La migración de los pasantes fue, en el balance, correcta.** Fue barata, salió, y compró diez
  años. El curso tiene que decir eso también, porque la tentación de juzgarla desde 2026 con un
  presupuesto que en 2016 no existía es la forma más común de arrogancia de ingeniero.

Si al final del curso resultara que .NET moderno ganó todo, el curso estaría mal escrito.
