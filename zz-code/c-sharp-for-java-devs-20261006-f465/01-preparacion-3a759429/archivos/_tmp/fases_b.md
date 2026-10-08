
---

### 🏚️ Fase 07 — El sistema que heredas

**Estilo heredado.** Escribe el trozo de SIGE que el resto del bloque va a cortar: el **esquema
completo** de los cuatro módulos (§10.4) y **dos de ellos implementados** —existencias por
almacén y liquidación de regalías—, en .NET Framework 4.8 y C# de 2017.

**Entra:** el esquema con sus nombres reales (`MOVINVEN`, `LIQREGAL`, `VENTAS_1997`…`VENTAS_2026`,
`CAMPO1`…`CAMPO7`, `BORRADO char(1)`, fechas en `char(8)`, sin llaves foráneas); los
procedimientos almacenados que llevan la lógica; la capa de datos con `DataSet` y `SqlDataAdapter`;
la cadena de conexión en el `App.config`; el `UNION ALL` de treinta tablas construido concatenando
cadenas; y el **generador de datos sucios**.

**No entra:** ninguna mejora. Nada se arregla en esta fase, ni siquiera lo que duele.

**🪞 El reflejo:** leer esto y pensar *"está mal hecho"* en vez de *"está fechado"*. La fase
pone cada decisión junto a su año y su razón — el nombre de diez caracteres es del formato DBF,
la tabla por año es cómo se evitaba que el motor sufriera, el borrado por bandera es la semántica
de FoxPro. **🩻 Se transfiere:** SQL es SQL, y las transacciones también.

**💸 Deuda:** el módulo entero es deuda declarada, con fecha. Cada pieza dice en qué fase se
cobra: el acceso a datos en la F09, la conexión directa del cliente en la F10, el runtime en la
F11.

**📏 Medición:** el `UNION ALL` de treinta tablas — plan de consulta, lecturas lógicas y tiempo.
Es **la línea base contra la que se compara todo el bloque**, y por eso se toma aquí y no después.

**🧱 Miniproyecto:** escribir el generador de datos sucios, con semilla fija: 1.900 movimientos
cuyo título ya no existe, tildes comidas por la intercalación en los títulos peruanos, registros
con `BORRADO = 'S'` que media consulta olvida filtrar, y fechas `'00000000'`. *La trampa:*
generar datos limpios. Unos datos limpios harían fácil todo el bloque siguiente y el curso
perdería su material.

---

### 🔎 Fase 08 ⭐ — Caracterizar lo que no puedes leer

**Es la fase de pruebas del curso** (§10.3), y escribe los otros dos módulos —catálogo y
facturación— **mientras los caracteriza** (§10.4).

**Entra:** *golden master* sobre procedimientos que nadie leyó; cómo hacer determinista lo que
llama a `GETDATE()`; Testcontainers con SQL Server frente a los dobles; qué es **cobertura útil**
sobre código heredado, que no es el porcentaje; y el 📖 completo JUnit ⇄ xUnit.

**No entra:** refactorizar nada. La regla de la fase es *primero la red, después el trapecio*.

**🪞 El reflejo:** reescribir antes de entender, y traducir JUnit línea por línea. **🩻 Se
transfiere:** toda la disciplina de prueba que el lector ya tiene.

**💸 Deuda:** el *golden master* queda atado a un conjunto de datos concreto y se rompe si el
generador cambia de semilla. Se declara y se discute en la **F10**, donde la conciliación necesita
una forma más robusta de comparar.

**📏 Medición:** cobertura de línea frente a cobertura de rama sobre el procedimiento de
regalías, y el tiempo de la suite con contenedor por prueba frente a contenedor compartido.

**🧱 Miniproyecto:** caracterizar el procedimiento de liquidación —setecientas líneas— y
**encontrar la regla que la editorial cree que tiene y no aplica**. *La trampa:* el procedimiento
no es determinista, y hasta que eso no se resuelva ninguna prueba sirve de nada.

---

### 🗄️ Fase 09 — Acceso a datos contra un esquema hostil

**Entra:** ADO.NET, Dapper y EF Core midiéndose sobre el mismo esquema; mapeo explícito de
`char(8)` a `DateOnly`, de `BORRADO` a un filtro global y de la tabla por año a algo consultable;
entidades sin llaves foráneas; cuándo configurar EF Core a mano, cuándo rendirse y usar Dapper, y
cuándo lo correcto es **arreglar el esquema**.

**No entra:** la API pública (F15), las migraciones de esquema en producción (F11).

**🪞 El reflejo:** asumir que EF Core es Hibernate y que el ORM te va a abstraer de un esquema
hostil. **🩻 Se transfiere:** transacciones, índices, planes, el `N+1`.

**💸 Deuda:** se **cobran** las dos de la F02 y la de la F03 — el borde donde el `!` estaba
tapando una decisión, y el `IQueryable` que se filtraba en memoria.

**📏 Medición:** Dapper, EF Core con y sin seguimiento, y ADO.NET sobre la consulta de catálogo:
tiempo, asignaciones y líneas de código. Con el plan de consulta medido **antes**.

**🧱 Miniproyecto:** mapear `MOVINVEN` a un modelo limpio con el borde 🧬 en un solo sitio y
probarlo contra SQL Server en contenedor. *La trampa:* el filtro global de `BORRADO` que EF Core
aplica — y los tres sitios donde no lo aplica y nadie lo documenta.

---

### 🌿 Fase 10 ⭐ — *Strangler fig*

**Entra:** poner una API en medio sin apagar nada; doble escritura y conciliación; el patrón
outbox; bandera de corte por funcionalidad; **vuelta atrás demostrada**; y cómo se decide el
orden de los cortes por riesgo y no por gusto.

**No entra:** mover el runtime (F11), la nube (F20).

**🪞 El reflejo:** el *big bang* de dos años y medio —el que Clara rechazó en 2021— y su gemelo,
*"primero refactorizamos y después migramos"*. **🩻 Se transfiere:** versionado de contrato,
compatibilidad hacia atrás.

**💸 Deuda:** la doble escritura entra sin conciliación automática. Se paga en la **F17**, con el
outbox de verdad.

**📏 Medición:** latencia y tasa de error del camino nuevo frente al acceso directo, y
**divergencia medida** entre las dos escrituras durante la ventana de convivencia.

**🧱 Miniproyecto:** poner la API en medio para existencias, con doble escritura, bandera de corte
y una vuelta atrás que **se ejecuta de verdad** y se documenta. *La trampa:* la vuelta atrás que
no puedes ejecutar porque el dato que escribió el camino nuevo ya no cabe en el esquema viejo.

📝 Aquí va la sección del track `cv` (§10.7): la pieza que se envuelve sin tocarla es **Convivir**,
la plataforma Java que llegó con la adquisición de 2004.

---

### 🚚 Fase 11 — Migrar el runtime: de .NET Framework 4.8 a .NET 10

**Entra:** el `.csproj` en formato SDK; `packages.config` → `PackageReference`; el informe de
compatibilidad de APIs; qué compila y no existe en tiempo de ejecución; ASMX y `DataSet`
serializado hacia minimal APIs; qué hacer con Crystal Reports; y la migración **por riesgo**, un
proyecto a la vez, con los dos runtimes conviviendo.

**No entra:** los formularios (Bloque C), el contenedor (F20).

**🪞 El reflejo:** migrar por versión en vez de por riesgo, y creer que el código de negocio se
reescribe. **🩻 Se transfiere:** casi todo el código de dominio pasa sin tocarse, y decirlo
tranquiliza al lector.

**💸 Deuda:** un `packages.config` convertido a medias, con dos paquetes que no tienen equivalente
y se aíslan tras una interfaz. **No se paga en este curso**, y se explica por qué: la respuesta
depende de un proveedor.

**📏 Medición:** arranque, memoria y tamaño del publish del mismo servicio en 4.8 y en .NET 10.

**🧱 Miniproyecto:** migrar el módulo de facturación completo, entregando el informe de
compatibilidad y **la lista honesta de lo que no se pudo migrar**. *La trampa:*
`ConfigurationManager`, `HttpContext.Current` y las APIs que compilan contra el paquete de
compatibilidad y revientan en tiempo de ejecución.

> ⚠️ **Obligación de esta fase** (§10.2): decir en voz alta que **migrar desde 4.8 es más fácil
> que migrar desde 4.5**, y qué tendría de más el camino que Cordillera no tuvo que hacer.
