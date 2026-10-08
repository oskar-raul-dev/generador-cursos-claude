
---

### 🪟 Fase 12 — WinForms sobre .NET 10

**Entra:** llevar formularios de Framework a .NET 10 —diseñador, controles de terceros,
`ClickOnce` contra noventa equipos—; sacar la lógica del `Click`; mantener la interfaz viva
durante una consulta de ocho segundos; y el argumento honesto de por qué **quedarse en WinForms
es una opción legítima** en 2026.

**No entra:** MVVM (F13), el veredicto (F14).

**🪞 El reflejo:** *"esto hay que reescribirlo sí o sí"*. **🩻 Se transfiere:** el bucle de
mensajes y el hilo de interfaz son el mismo concepto de Swing o JavaFX.

**💸 Deuda:** la lógica de negocio sigue en el manejador del botón. Se paga en la **F13**, donde el
mismo formulario pasa a tener un modelo de vista comprobable.

**📏 Medición:** arranque en frío, memoria y tiempo de pintado de la grilla con 50.000 filas, en
Framework 4.8 frente a .NET 10.

**🧱 Miniproyecto:** migrar el formulario de existencias y hacer que responda durante la consulta
larga. *La trampa:* `async void` en el manejador de evento es **correcto aquí** — es la única vez
en todo el curso, y entender por qué es la lección.

---

### 🎛️ Fase 13 — WPF y MVVM

**Entra:** XAML lo justo; binding y `INotifyPropertyChanged`; comandos; el modelo de vista como
código **comprobable sin interfaz**; virtualización de listas; y qué de lo que el lector sabe de
MVC se traduce y qué no.

**No entra:** estilos y temas más allá de lo necesario; WinUI (F14).

**🪞 El reflejo:** el controlador que manipula controles por su nombre, y tratar el binding como
magia en vez de como un contrato. **🩻 Se transfiere:** separación de responsabilidades, pruebas
de lógica de presentación.

**💸 Deuda:** la lista entra sin virtualizar. Se paga en la **F14**, midiendo qué cuesta con
50.000 filas.

**📏 Medición:** el mismo formulario en WinForms y en WPF: arranque, memoria y fluidez con
50.000 filas.

**🧱 Miniproyecto:** el formulario de existencias en WPF, con el modelo de vista cubierto por
pruebas **sin levantar la interfaz**. *La trampa:* el binding que falla en silencio y solo
aparece en la ventana de salida del depurador.

---

### ⚖️ Fase 14 — WinUI 3, Blazor Hybrid y el veredicto del escritorio

**Entra:** un prototipo en WinUI 3 y otro en Blazor Hybrid, lo justo para medirlos; el empaquetado
y el despliegue a noventa equipos sin permisos de administrador; y **la comparación completa**.

**No entra:** construir la cuarta opción — la web nace después, en la F18, y la comparación se
cierra con lo que esta fase deja medido.

**🪞 El reflejo:** elegir por modernidad, y suponer que lo nuevo despliega mejor. **🩻 Se
transfiere:** el criterio de evaluar herramientas por su operación y no por su sintaxis.

**📏 Medición — la grande del bloque:** cuatro opciones × arranque, memoria, despliegue a noventa
equipos, comportamiento con la conexión del depósito de Lima, y **quién lo puede mantener**. Esa
última columna es la que decide, y su nombre propio es Duván.

**🧱 Miniproyecto:** el prototipo en WinUI 3 del mismo formulario y **la tabla de decisión
firmada**, con una recomendación para Cordillera que el lector defendería ante Clara. *La trampa:*
el despliegue. El prototipo sale en una tarde; ponerlo en noventa equipos es el problema real.

---

### 🌐 Fase 15 — ASP.NET Core: minimal APIs y contrato

**Entra:** minimal APIs frente a controladores; inyección de dependencias y tiempos de vida;
validación **en el borde**; DTO distintos de las entidades; versionado de contrato; OpenAPI;
paginación y filtrado; errores como respuesta y no como excepción.

**No entra:** identidad (F16), despliegue (F20).

**🪞 El reflejo:** validar dentro del servicio, el controlador con doce dependencias inyectadas, y
devolver la entidad del ORM directamente. **🩻 Se transfiere:** HTTP, REST, contratos, idempotencia.

**💸 Deuda:** el endpoint de catálogo sale sin paginación. Se paga en la **F20**, cuando la
factura muestre lo que cuesta servir el catálogo entero cada vez.

**📏 Medición:** minimal APIs frente a controladores: throughput, latencia y tiempo de arranque.

**🧱 Miniproyecto:** el endpoint de catálogo que **Grupo Almenara podría consumir de verdad**, con
validación en el borde, versionado y contrato publicado. *La trampa:* devolver la entidad de EF
Core directamente — funciona, y te ata el esquema heredado al contrato público para siempre.

---

### 🔐 Fase 16 — Identidad, secretos y configuración

**Entra:** Entra ID para el back-office y para los socios; autenticación y autorización basada en
políticas; `IOptions` y configuración tipada por ambiente; Key Vault y el equivalente local;
rotación; y qué hacer con la tabla de usuarios de 2017 cuyo hash da pena.

**No entra:** federación con el directorio del socio, declarado fuera.

**🪞 El reflejo:** la cadena de conexión en el `App.config` de noventa equipos, y el filtro de
seguridad casero. **🩻 Se transfiere:** OAuth 2 y OIDC, que el lector ya conoce.

**💸 Deuda:** **se cobra** la de la F07 — la cadena de conexión compartida sale del disco de los
noventa equipos, que es el objetivo entero de la fase.

**📏 Medición:** costo de validar un token con caché de claves frente a sin caché, bajo carga.

**🧱 Miniproyecto:** hacer que el servicio arranque **sin ningún secreto en disco**, con el
equivalente local en desarrollo y el gestionado en la nube, sin dos rutas de código distintas.
*La trampa:* el `appsettings.Development.json` que sí se commiteó, y lo que hay que hacer cuando
ya está en el historial.

---

### 🌙 Fase 17 — Trabajo de fondo: colas, idempotencia y reanudación

**Entra:** `IHostedService` y `BackgroundService`; el patrón outbox de verdad; idempotencia por
clave de operación; procesamiento por lotes reanudable; reintentos con retroceso; y auditoría
línea por línea.

**No entra:** las funciones durables, que se estudian en la F20 con su costo.

**🪞 El reflejo:** el proceso nocturno que se reinicia desde cero —el de Cordillera tarda seis
horas y falló dos veces en la hora cinco— y el reintento que duplica el cobro. **🩻 Se
transfiere:** todo lo que el lector sabe de mensajería.

**💸 Deuda:** **se cobran** las dos de la F05 (los métodos sin `CancellationToken`) y la doble
escritura sin conciliar de la F10.

**📏 Medición:** tabla de cola en SQL Server —la que Cordillera ya tiene y funciona— frente a
Service Bus: throughput, latencia y **costo mensual al volumen real**.

**🧱 Miniproyecto:** la liquidación trimestral reanudable por lotes, idempotente y auditable, con
**la tasa de cambio guardada junto al cálculo**; el criterio de aceptación es reproducir exacto un
número liquidado ocho meses antes. *La trampa:* reanudar sin idempotencia paga dos veces las
regalías del lote que iba a medias — y a alguien le llega el dinero.

---

### 🧵 Fase 18 — Blazor Server ⇄ WebAssembly ⇄ MVC

**Entra:** los tres modelos de render, la misma pantalla en los tres; estado y ciclo de vida de un
circuito; formularios y validación compartida con el servidor; auditoría de acceso; y la latencia
medida como criterio de arquitectura.

**No entra:** un framework de JavaScript, declarado fuera con su razón: no hay equipo de frontend.

**🪞 El reflejo:** elegir el modelo de render por moda y no por latencia, y suponer que SPA es
siempre la respuesta. **🩻 Se transfiere:** formularios, validación, sesiones.

**💸 Deuda:** la primera versión entra sin rastro de auditoría de quién vio qué. Se paga en la
**F19**, donde la observabilidad lo hace barato.

**📏 Medición:** latencia de interacción desde Bogotá, Ciudad de México y el depósito de Lima
—simulada con latencia y pérdida inyectadas—, peso de la carga inicial y memoria de servidor por
usuario conectado.

**🧱 Miniproyecto:** la pantalla de recepción de manuscritos, implementada en los tres modelos y
medida. *La trampa:* Blazor Server con la conexión de Lima. Va a funcionar perfecto en tu máquina.

---

### 🔭 Fase 19 — Observabilidad y operación

**Entra:** OpenTelemetry —trazas, métricas y logs—; correlación de una petición a través de la
API hasta el procedimiento heredado; logs estructurados; muestreo; comprobaciones de salud; y qué
se alerta y qué no.

**No entra:** el costo de ingestión, que se mide en la F20 con el resto de la factura.

**🪞 El reflejo:** `print` como log —en SIGE es un `MessageBox.Show` que quedó en producción en dos
formularios— y loguearlo todo por si acaso. **🩻 Se transfiere:** métricas, trazas, percentiles.

**💸 Deuda:** la telemetría entra sin muestreo. Se paga en la **F20**, en pesos.

**📏 Medición:** sobrecosto de la instrumentación sobre la latencia del endpoint, y volumen de
telemetría generado por día al tráfico real.

**🧱 Miniproyecto:** trazar una petición de CatalogAPI hasta el procedimiento almacenado y
**encontrar dónde se van los cuatro segundos**. *La trampa:* el log estructurado que, sin que
nadie lo decidiera, está registrando datos personales de los autores.

---

### 🐳 Fase 20 ⭐ — Contenedor, arranque en frío y la factura

**Entra:** imagen multi-etapa; configuración en tiempo de arranque; publish autocontenido,
dependiente del framework y **AOT nativo**; arranque en frío; y **la comparación de la factura**:
la máquina virtual que ya tienen, App Service, Container Apps y AKS, con su costo, su esfuerzo de
operación y su amarre.

**No entra:** orquestación avanzada, declarada fuera; el repositorio tiene un curso para eso.

**🪞 El reflejo:** adoptar PaaS sin costear el amarre, y elegir Kubernetes por defecto. **🩻 Se
transfiere:** Docker entero.

**💸 Deuda:** **se cobran** tres — la paginación de la F15, la cola en tabla de la F17 y el
muestreo de la F19. Las tres aparecen en la misma factura, que es exactamente la lección.

**📏 Medición — la grande:** cuatro destinos de cómputo × costo mensual al volumen real, arranque
en frío, esfuerzo de operación y dificultad de salida. Más JIT frente a AOT nativo.

**🧱 Miniproyecto:** contenerizar CatalogAPI, medir JIT frente a AOT y producir **la hoja de costos
de las cuatro opciones**, con la conclusión incómoda de que para Cordillera AKS es casi seguro un
error. *La trampa:* AOT rompe la reflexión de dos de las bibliotecas del proyecto, y el error no
aparece hasta el tiempo de ejecución.
