# 💵 Fase 20 — El contenedor y la factura

> C# para desarrolladores Java senior · Fase 20 de 24 · Bloque D — servicios, datos y nube
> Depende de: 11, 15, 16, 17, 18, 19 · Habilita: 21
> Estilo de esta fase: **nuevo** (.NET 10, C# 14)
> Proyecto que avanza: ninguno construye funcionalidad. Esta fase **empaqueta lo que hay y le pone precio**.
> ⭐ **Fase destacada.** Es la única del curso donde el veredicto está en pesos y no en milisegundos.

---

## 🎯 1. Propósito

En 2020, Cordillera movió SIGE a Azure. Fue un traslado sin cambios —*lift and shift*—: la misma máquina
virtual, el mismo Windows Server, la misma base de datos, en otro edificio. Lo prometido era ahorro; lo que
llegó fue una factura **un 30% por encima** de lo que costaba el centro de datos propio.

Nadie mintió. Y nadie entendió por qué.

Esa factura es la razón por la que Cordillera desconfía de todo lo que este curso ha construido, y es una
desconfianza ganada. Esta fase existe para dos cosas: **entender qué pasó en 2020 sin absolver a nadie**, y
**poner precio a lo que se construyó en las veinte fases anteriores** antes de que alguien lo apruebe.

> 🧭 **La regla de la fase, y es la que la hace la más incómoda del curso:** *una arquitectura sin factura no
> es una arquitectura: es una propuesta.* Todo lo que el curso midió hasta aquí se midió en milisegundos y en
> megabytes. Esta fase traduce esas unidades a pesos mensuales, y algunas decisiones que parecían obvias
> dejan de serlo.

Y hace algo que el curso venía aplazando deliberadamente. Hay **tres atajos** tomados en tres fases distintas,
cada uno cómodo y cada uno declarado, que tienen el mismo mecanismo: *funciona, y crece sin límite*. Los tres
se cobran aquí, **en la misma hoja de costos**, porque los tres son la misma lección con distinta ropa.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Las cuatro cosas en producción están **en contenedores**, con imágenes de tamaño medido y arranque medido.
- [ ] Está claro **qué se puede contenerizar y qué no**, con la razón: el escritorio no, el sistema heredado
      con matices.
- [ ] Existe la **hoja de costos mensual** de la arquitectura completa, con cada cifra acompañada de **precio
      publicado, fecha de consulta y región**.
- [ ] Está explicado, **con números y sin absolver a nadie**, por qué el traslado de 2020 salió un 30% por
      encima del centro de datos.
- [ ] 💸 **Se paga la deuda de paginación de la fase 15**: el volcado completo del catálogo tiene precio, y la
      paginación tiene el precio que ahorra.
- [ ] 💸 **Se paga la deuda de la cola en tabla de la fase 17**: comparada con mensajería administrada, en
      pesos y en operación, no en elegancia.
- [ ] 💸 **Se paga la deuda de muestreo de la fase 19**: el porcentaje sale del volumen medido y del precio por
      gigabyte, no de un valor por omisión.
- [ ] Están comparadas **tres formas de alojar** lo mismo —contenedores administrados, orquestador, y máquina
      virtual— con su costo mensual y su costo de operación.
- [ ] Está decidido y sostenido con números si **Kubernetes es apropiado para Cordillera**. La respuesta
      probable es que no, y hay que poder defenderla.
- [ ] La medición de la sección 6 está escrita con su comando, y la entrada quedó en `BENCHMARKS.md`.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Una canalización de despliegue continuo.** Declarado fuera con su razón: es una práctica de equipo y
  Cordillera tiene dos personas. La fase construye la imagen y la publica a mano, que es lo honesto para este
  tamaño; el ejercicio 🔥 explora qué cambiaría con CI.
- **Optimización de consultas y de índices** → la fase 19 dejó el diagnóstico, y el ejercicio 19 de allí la
  decisión. Aquí solo se le pone precio al resultado.
- **Migrar la base de datos a un servicio administrado con otro motor.** Fuera de alcance, y la razón es del
  curso entero: el esquema hostil de la fase 09 no se mueve sin reescribir once procedimientos.
- **Escalado automático serio.** Se menciona el precio de la capacidad ociosa y no se construye la política. El
  tráfico de Cordillera no lo justifica, y eso es parte del argumento contra Kubernetes.
- **El veredicto final del curso** → fase 24. Esta fase aporta la columna del dinero, que es una de las que más
  pesa, y no cierra nada.
- **Multi-nube y recuperación ante desastres en otra región.** Fuera con su razón: duplican la factura y
  Cordillera todavía no tiene respaldos probados. Hay un orden.

---

## 🧠 4. Concepto mínimo

### Contenedores, y la única parte donde .NET se comporta distinto

El modelo es el mismo que conoces y no hay nada que reaprender: una imagen, capas, un registro, un contenedor
efímero, configuración por variables de entorno. Si vienes de contenerizar aplicaciones de Java, el 90% se
transfiere intacto.

Las diferencias que importan son tres, y las tres afectan la factura.

**Primera: la construcción en varias etapas es obligatoria y el SDK pesa.** Una imagen que incluya el SDK de
.NET es varias veces más grande que una que solo tenga el runtime. Es el mismo razonamiento del JDK contra el
JRE, con la misma solución.

**Segunda, y es la que no tiene equivalente directo: hay más de un runtime base y la diferencia de tamaño es
grande.** La imagen completa, la *runtime-deps* para aplicaciones autocontenidas, y la variante reducida
—*chiseled*— que quita todo lo que una aplicación no necesita, incluida la consola de depuración. Elegir bien
divide el tamaño de la imagen, y el tamaño de la imagen es tiempo de despliegue y costo de almacenamiento y de
transferencia.

**Tercera: el sistema heredado no se conteneriza como lo demás.** .NET Framework 4.8 **solo corre en
Windows**, y las imágenes de contenedor de Windows Server son de otro orden de magnitud: gigabytes donde Linux
tiene megabytes. Eso no es un detalle de empaquetado: es una fila de la factura, y es uno de los argumentos de
la fase 11 llegando cuatro fases tarde con su precio puesto.

### Las tres formas de alojar lo mismo, y qué las diferencia de verdad

| Forma | Qué administras | Qué cuesta | Cuándo tiene sentido |
|---|---|---|---|
| **Contenedores administrados** | la imagen | el consumo, con mínimos | cargas modestas y equipos pequeños |
| **Orquestador (Kubernetes)** | el clúster y sus nodos | los nodos, encendidos o no | muchos servicios, o equipo de plataforma |
| **Máquina virtual** | el sistema operativo entero | la máquina, encendida o no | lo que no se puede contenerizar |

Y la diferencia que las tablas de precios no muestran: **el orquestador cobra dos veces**. Una en la factura,
por los nodos que están encendidos aunque no haya tráfico; y otra en **el tiempo de las dos personas que
mantienen todo lo demás**. Esa segunda factura no aparece en ninguna calculadora y suele ser la mayor.

> 🧠 **El modelo mental de la factura, y es lo único que hay que retener de esta fase:** en la nube **se paga
> por capacidad reservada o por consumo, y casi nunca por lo que usas**. Una máquina virtual encendida al 8% de
> CPU cuesta lo mismo que al 80%. Un nodo de Kubernetes vacío cuesta igual que uno lleno. Un gigabyte
> transferido cuesta aunque nadie lo lea. **El centro de datos propio también desperdiciaba**, pero el
> desperdicio ya estaba comprado y amortizado — y ahí está la mitad de la explicación de 2020.

### Los cuatro mecanismos que hicieron el 30% de 2020

Esta es la parte de la fase que hay que entender antes de proponer cualquier cosa, porque los cuatro
mecanismos **siguen activos** y van a operar igual sobre lo que este curso construyó.

**Primero: la máquina se dimensionó por el pico y se paga por el mes.** El servidor del centro de datos se
compró en 2014 para el cierre de fin de año, y once meses al año estaba sobrado. Al trasladarlo se eligió una
máquina virtual equivalente a la física —que es lo que hace un traslado sin cambios— y se empezó a pagar el
pico todos los meses. En el centro de datos el exceso era un activo ya pagado; en la nube es una cuota.

**Segundo: la transferencia de salida se paga y nadie la había pagado nunca.** Dentro del edificio, mover datos
entre el servidor y los puestos era gratis por construcción. El primer mes en la nube, cada informe descargado,
cada respaldo bajado y cada consulta del escritorio se convirtieron en una línea de la factura. Esta es la que
nadie ve venir, y es la que conecta directamente con la deuda de la fase 15.

**Tercero: lo que estaba incluido pasó a cobrarse aparte.** Respaldos, retención, discos de mayor rendimiento,
direcciones IP fijas, registros. En el centro de datos todo eso venía con el hierro; en la nube cada cosa es un
recurso con su precio, y la suma de las cosas pequeñas fue una parte grande de la sorpresa.

**Cuarto, y es el único donde hubo un error evitable: nunca se apagó nada.** El servidor de pruebas que se creó
para validar el traslado siguió encendido **cinco años**. El disco de una máquina que se borró siguió
facturando. La sesión de diagnóstico que se activó una semana quedó activa. Nada de eso es un mecanismo de la
nube: es que en el centro de datos un servidor olvidado no cuesta más, y en la nube sí.

> 📝 **Y la parte honesta, que es la que hay que decir en voz alta:** el traslado de 2020 no fue un fracaso
> técnico. Salió un 30% por encima y **también** eliminó un centro de datos que no tenía respaldo eléctrico
> confiable, con una base de datos cuya copia se guardaba en un disco externo en la oficina de al lado.
> Comparar solo la factura es la misma deshonestidad que comparar solo la latencia: **el centro de datos era
> más barato y era un riesgo que nadie había costeado**. Lo que faltó en 2020 no fue prudencia: fue que nadie
> puso las dos columnas en la misma hoja.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**Primera: contenerizar y ya, sin mirar el tamaño.**

```text
❌ El razonamiento, y no es tonto:
   "La imagen se construye una vez y se despliega. Que pese 800 MB o 200 MB da igual:
    el almacenamiento es barato y el registro es privado."
```

**Por qué falla:** porque el tamaño de una imagen se paga **muchas veces**, no una. Se paga en almacenamiento
del registro, sí, y eso es poco. Se paga en **transferencia cada vez que un nodo descarga la imagen** —y eso
ocurre en cada despliegue, en cada escalado y en cada reinicio—. Y se paga en **tiempo de arranque**, que es lo
que determina cuánto tarda un despliegue y cuánto tarda en recuperarse una instancia que se cayó.

Y hay una razón que no es de dinero: **una imagen más pequeña tiene menos superficie de ataque**, porque no
contiene un intérprete de comandos, ni herramientas de red, ni un SDK con compilador. La variante reducida no
es solo una optimización de costos.

```text
✅ Lo que el ecosistema espera en su lugar:
   Construcción en varias etapas, la imagen base más pequeña que sirva, y el tamaño
   medido como cualquier otra métrica del curso. Es una línea en la tabla de la sección 6.
```

**Segunda: Kubernetes porque es el estándar.**

Es el instinto más caro de esta fase, y viene de un lugar legítimo: si trabajaste en una empresa con cuarenta
servicios, Kubernetes resolvió problemas reales y los resolvió bien. El error no es pensar que funciona: es
suponer que **el umbral donde empieza a convenir** está más abajo de donde está.

Cordillera tiene cuatro cosas en producción, tráfico de una editorial mediana, **dos personas que mantienen
todo**, y un sistema de 1997 debajo que no se orquesta. Kubernetes le agregaría un plano de control que hay que
actualizar, nodos que se pagan encendidos, una capa de red que hay que depurar cuando falla, y un conjunto de
conceptos que las dos personas tendrían que aprender **además** de mantener SIGE.

**Dónde se rompe el paralelo con lo que traes:** en el mundo de Java, la infraestructura suele ser
responsabilidad de otro equipo, así que su costo de operación no sale de tu presupuesto y no entra en tu
decisión. Aquí **el costo de operación sale del mismo par de manos que arregla el cierre de regalías cuando
falla**, y eso lo convierte en el criterio dominante. Es la misma lógica que la fase 18 aplicó a los
frameworks de JavaScript, con tres ceros más.

> ⚰️ **Autopsia del anti-patrón: el servidor de pruebas de cinco años.**
>
> **El caso:** en 2020, para validar el traslado, se creó una máquina virtual de pruebas con una copia de la
> base. El traslado salió bien. La máquina se quedó encendida. En 2025 alguien revisó la factura línea por
> línea por primera vez y la encontró.
>
> **Cuánto costó:** ⏳ el cálculo es un ejercicio de esta fase —el precio publicado de la máquina por sesenta
> meses— y hay que hacerlo, porque el número es más grande de lo que la intuición dice y es el mejor argumento
> de la fase. Sin ese número, esto es una anécdota.
>
> **Por qué nadie lo vio:** porque la factura llegaba como un total, el total subía poco a poco, y **nadie era
> dueño de revisarla**. En el centro de datos, un servidor olvidado no le cuesta a nadie; el hábito de apagar
> no existía porque nunca hizo falta.
>
> **La defensa, y son tres cosas y ninguna es técnica:** etiquetar cada recurso con su dueño y su razón, revisar
> la factura desglosada una vez al mes con una persona responsable, y **poner fecha de caducidad a todo lo que
> se crea para una prueba**. Lo que falla aquí no es la arquitectura: es que nadie tiene el trabajo de mirar.

### 🩻 Esto sí funciona igual

Los contenedores, casi completos. `Dockerfile`, capas, caché de construcción, registro, etiquetas, variables de
entorno, orquestación: todo eso vale igual y el curso no lo explica. Si contenerizaste una aplicación de Spring
Boot, contenerizar una de ASP.NET Core es el mismo archivo con otros nombres.

Los chequeos de salud para orquestación son la misma idea que ya usas, con la advertencia de seguridad de la
fase 19. La configuración por variables de entorno funciona idéntico, y `IOptions` de la fase 16 las lee sin
nada especial. Los secretos por el mecanismo de la plataforma, igual.

Y el razonamiento de costos en la nube es **completamente transferible**: no hay nada específico de .NET en
entender una factura. La única diferencia real del ecosistema es la de las imágenes de Windows, y es de tamaño,
no de concepto.

### 📖 Diccionario de traducción

| Java / infraestructura | .NET / Azure | Dónde se rompe el paralelo |
|---|---|---|
| `Dockerfile` con JDK → JRE | construcción en varias etapas con SDK → runtime | Idéntico, misma razón y misma solución |
| imagen `eclipse-temurin:21-jre-alpine` | `mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled` | La variante reducida quita el intérprete de comandos: más pequeña y más segura |
| `java -jar app.jar` | `dotnet App.dll`, o el ejecutable autocontenido | Autocontenido no necesita runtime en la imagen: base más pequeña |
| Spring Boot Actuator para orquestación | `AddHealthChecks` | Mismo concepto. Ver la advertencia de la F19 sobre qué revela |
| `application-prod.yml` | variables de entorno + `IOptions` | Las variables ganan en contenedores, en los dos mundos |
| WAR en Tomcat en una máquina | máquina virtual con IIS | Es lo que SIGE es hoy, y lo que la F11 dejó a medias |
| Helm | Helm, igual | Mismo ecosistema. La pregunta de esta fase es si hace falta |
| Kubernetes | AKS, o Azure Container Apps | **Container Apps no tiene equivalente exacto en tu mundo**: orquestación sin clúster visible |
| — | **contenedor de Windows para .NET Framework** | Sin paralelo. Gigabytes contra megabytes, y es una fila de la factura |

> ⚠️ **La última fila es la que sorprende y la que decide.** Contenerizar lo que queda de SIGE en .NET
> Framework 4.8 exige una imagen base de Windows Server, y su tamaño no es comparable con una de Linux. Eso
> significa despliegues más lentos, más transferencia, más almacenamiento, y —según la forma de alojamiento—
> **nodos de Windows que se pagan aparte**. Es el mejor argumento económico para terminar la migración de
> runtime que la fase 11 dejó en un módulo de cuatro, y llega cuatro fases tarde con el precio puesto.

> 📝 **Nota de ecosistema.** Los contenedores de .NET llevan años siendo de primera clase, y las variantes
> reducidas son de .NET 8 en adelante. Pero mucho material que vas a encontrar es de la época en que .NET solo
> corría en Windows y contenerizarlo era raro; y otra parte asume Kubernetes por omisión porque se escribió para
> empresas con equipo de plataforma. **Ninguna de las dos épocas describe a Cordillera**, y eso es precisamente
> lo que esta fase tiene que decidir por sí misma.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La imagen, y las tres decisiones que cambian su tamaño

```dockerfile
# src/modern/Cordillera.Catalog.Api/Dockerfile
#
# Tres decisiones, y las tres se miden en la sección 6. No son preferencias de estilo: son filas de
# la tabla de tamaño y de arranque.

# ── Etapa 1: construcción. El SDK vive aquí y NO llega a la imagen final. ──
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Primero los archivos de proyecto, después el código. Es la misma optimización de caché que con
# Maven: si las dependencias no cambiaron, esta capa se reutiliza y la construcción es mucho más
# rápida. El bloqueo de versiones de la F00 la hace determinista.
COPY Directory.Build.props Directory.Packages.props ./
COPY Cordillera.Catalog.Api/*.csproj Cordillera.Catalog.Api/
RUN dotnet restore Cordillera.Catalog.Api --locked-mode

COPY . .
# Autocontenido y recortado: el runtime viaja dentro del ejecutable y el recortador quita lo que la
# aplicación no usa. Eso permite una imagen base sin runtime, que es la más pequeña posible.
#
# ⚠️ Y tiene un riesgo real: el recorte rompe la reflexión. Los serializadores y los mapeadores que
#    resuelven tipos en tiempo de ejecución pueden fallar SOLO en producción, con la imagen recortada,
#    y no en tu máquina. El ejercicio 21 pide provocarlo a propósito, porque es la clase de fallo que
#    hay que haber visto una vez.
RUN dotnet publish Cordillera.Catalog.Api -c Release -o /app \
    --self-contained true -r linux-x64 \
    -p:PublishTrimmed=true -p:InvariantGlobalization=false

# ── Etapa 2: ejecución. La base más pequeña que sirva. ──
#
# runtime-deps + chiseled: solo las dependencias nativas, sin runtime (va dentro del ejecutable) y
# sin intérprete de comandos. No se puede entrar a depurar — que es la mitad del punto.
FROM mcr.microsoft.com/dotnet/runtime-deps:10.0-noble-chiseled AS final
WORKDIR /app
COPY --from=build /app .

# Usuario sin privilegios. Las imágenes reducidas ya traen uno, y declararlo es explícito y gratis.
USER $APP_UID

# ⚠️ InvariantGlobalization quedó en false a propósito, y cuesta tamaño. La razón es de la fase 09:
#    el esquema tiene una colación que no es Unicode y hay títulos con tildes y con ñ. Con
#    globalización invariante, comparar y ordenar esos títulos da resultados distintos — y "Ñandú"
#    deja de ordenarse donde un lector colombiano lo busca. Es una decisión de dominio disfrazada de
#    bandera de compilación.
ENTRYPOINT ["./Cordillera.Catalog.Api"]
```

**Detalles con intención**

- **La construcción en varias etapas no es una optimización: es la forma correcta.** El SDK en la imagen final
  es peso y superficie de ataque sin ningún beneficio.
- **`chiseled` no trae intérprete de comandos**, y eso significa que **no puedes entrar al contenedor a mirar**.
  Es incómodo la primera vez que algo falla, y es exactamente la razón por la que la fase 19 existe: si no
  puedes entrar, tienes que haber instrumentado.
- **El recorte rompe la reflexión y hay que haberlo visto.** Es el fallo más desagradable de esta fase porque
  aparece solo en producción, con la imagen final, y no en desarrollo.
- **`InvariantGlobalization=false` cuesta megabytes y se queda.** Es el mejor ejemplo de esta fase de una
  decisión que parece de infraestructura y es de dominio: los títulos de Cordillera tienen tildes.

### 5.2 Lo que no se conteneriza, y por qué

```dockerfile
# src/legacy/Sige.Reports/Dockerfile
#
# Esto se escribe para poder MEDIRLO y compararlo, no porque sea una buena idea. El módulo que la
# fase 11 no migró sigue en .NET Framework 4.8, y 4.8 solo corre en Windows.
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022
# ⚠️ Compara el tamaño de esta imagen con la de la sección 5.1. Ese cociente es el argumento
#    económico para terminar la migración de runtime, y es una fila de la tabla B.
COPY ./publish/ /inetpub/wwwroot
```

```text
Y lo que NO se conteneriza, con su razón escrita:

  El escritorio de existencias (WinForms, F12).
    Un contenedor no tiene pantalla, y el escritorio existe PARA tener pantalla. La pregunta
    correcta no es cómo contenerizarlo sino cómo distribuirlo — y eso lo contestó la F14.

  La base de datos SIGE.
    Se PUEDE, y no se debe. Un contenedor es efímero y una base de datos de 1997 con datos
    de 1997 es lo contrario de efímero. Va en un servicio administrado o en una máquina, y
    esa decisión es una fila de la factura, no de esta sección.
```

### 5.3 La hoja de costos, que es el entregable real de la fase

```csharp
// src/modern/Cordillera.Costos/CostSheet.cs
//
// Esta fase produce código, y el código no sirve para ejecutar la arquitectura: sirve para que la
// factura sea REPRODUCIBLE. Una hoja de cálculo con números escritos a mano no se puede auditar en
// seis meses; un modelo con sus fuentes sí.
namespace Cordillera.Costos;

/// <summary>
/// Una línea de la factura mensual. **La fuente y la fecha son obligatorias**, y no por pedantería:
/// los precios de la nube cambian, y una cifra sin fecha es una cifra que no se puede volver a
/// verificar ni defender ante quien la aprueba.
/// </summary>
public sealed record CostLine
{
    public required string Resource { get; init; }

    /// <summary>Región. Afecta el precio y hay que declararla: East US 2 para todo el curso.</summary>
    public required string Region { get; init; }

    /// <summary>Lo que se consume al mes: horas encendido, GB almacenados, GB transferidos.</summary>
    public required Quantity MonthlyUsage { get; init; }

    /// <summary>Precio unitario publicado. ⏳ pendiente de consulta — nunca se escribe de memoria.</summary>
    public required decimal UnitPriceUsd { get; init; }

    /// <summary>De dónde salió el precio. Obligatorio: URL de la página de precios.</summary>
    public required string PriceSource { get; init; }

    /// <summary>Cuándo se consultó. Obligatorio.</summary>
    public required DateOnly PricedOn { get; init; }

    /// <summary>
    /// Qué parte de esto se usa de verdad. Es la columna incómoda: una máquina al 8% de CPU cuesta
    /// igual que al 80%, y sin esta columna la factura parece justificada.
    /// </summary>
    public double? UtilizationRatio { get; init; }

    public decimal MonthlyUsd => MonthlyUsage.Amount * UnitPriceUsd;

    /// <summary>Lo que se paga por capacidad que nadie usó. Es el número de la conversación de 2020.</summary>
    public decimal? WastedUsd => UtilizationRatio is { } used
        ? MonthlyUsd * (decimal)(1 - used)
        : null;
}

public readonly record struct Quantity(decimal Amount, string Unit);
```

**El patrón a memorizar**

> **Una cifra de costo sin precio publicado, fecha y región no es un dato: es un recuerdo.** El curso aplica a
> la factura exactamente la misma regla que aplica a las mediciones —hipótesis, condiciones, fuente— y por la
> misma razón: dentro de seis meses, cuando alguien pregunte de dónde salió ese número, la respuesta tiene que
> existir. Un costo que no se puede reverificar no se puede defender, y un costo que no se puede defender no
> sobrevive a la primera reunión de presupuesto.

### 5.4 Las tres deudas, en la misma hoja

Aquí está el material de la fase, y es lo que la hace ⭐: **tres atajos de tres fases distintas, cobrados
juntos**, porque comparten mecanismo.

```csharp
// src/modern/Cordillera.Costos/DebtInvoices.cs
//
// 💸 DEUDA 1 — de la fase 15: el catálogo completo sin paginar.
//    El endpoint /catalogo devuelve todo. Funciona, porque el catálogo de Cordillera es modesto.
//    Y Almenara sincroniza cada hora, y cada sincronización transfiere el volcado entero, y la
//    transferencia de salida se paga por gigabyte.
//
//    El número: (tamaño del volcado) × (24 × 30 sincronizaciones) × (precio por GB de salida).
//    Y lo que ahorra paginar: transferir solo lo que cambió.
//
//    ⏳ Las dos cifras se calculan en el miniproyecto. Es el ejemplo más claro del curso de un atajo
//       que no tiene ningún síntoma técnico —no hay latencia mala, no hay error, nada en la traza—
//       y que aparece únicamente en la factura.

// 💸 DEUDA 2 — de la fase 17: la cola en tabla.
//    El trabajo de fondo usa una tabla de SQL Server como cola. Cero costo adicional: la base ya
//    está pagada. La mensajería administrada cuesta al mes.
//
//    Y aquí la comparación honesta NO es de precios, y eso es lo que hay que aprender: la cola en
//    tabla tiene costo CERO en la factura y costo NO CERO en operación —los reintentos se manejan a
//    mano, el veneno se limpia a mano, la concurrencia se resuelve con bloqueos—. La pregunta
//    correcta es cuántas horas al mes cuesta eso, y cuánto vale una hora de las dos personas.
//
//    ⏳ Y el veredicto probable es incómodo para el instinto de ingeniería: **para el volumen de
//       Cordillera, la cola en tabla probablemente gana**. Hay que poder decirlo con el número.

// 💸 DEUDA 3 — de la fase 19: sin muestreo.
//    Todo se exporta. La fase 19 midió los GB por hora; aquí se multiplica por el precio por GB
//    ingerido y por la retención, y sale el costo mensual de la observabilidad.
//
//    El porcentaje de muestreo se elige de ese número y no al revés. Y el criterio no es "cuánto
//    quiero gastar" sino **"cuánto muestreo soporta la pregunta que la telemetría tiene que
//    contestar"**: con 1%, una petición lenta que ocurre veinte veces al día puede no aparecer
//    nunca. Muestrear por debajo de lo que la pregunta exige es pagar por telemetría inútil, que es
//    peor que no pagar.
//
//    ⏳ El número correcto sale del volumen de la F19 y del precio publicado.
```

> 🧭 **Y lo que las tres deudas tienen en común, que es la lección de la fase:** ninguna tiene un síntoma
> técnico. Las tres funcionan. Ninguna aparece en una traza, en una prueba o en un percentil. **Las tres
> aparecen en la factura, y solo en la factura** — y las tres crecen con el uso, así que el día que Cordillera
> le vaya mejor, las tres cuestan más. Ese es el mecanismo que hizo el 30% de 2020, operando sobre código de
> 2026.

**Prueba de fuego**

```powershell
docker build -t cordillera/catalogo:20 -f src\modern\Cordillera.Catalog.Api\Dockerfile src\modern
docker images cordillera/catalogo:20 --format "{{.Size}}"
dotnet run --project src\modern\Cordillera.Costos -- --hoja completa
```

Mira el total mensual y contesta **qué línea es la más grande**. Si es una que te sorprende, la fase está
funcionando.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el total mensual va a parecer
razonable**. Casi siempre lo parece, porque se compara contra un presupuesto y no contra el desglose. La cifra
que importa no es el total: es **la columna de capacidad desperdiciada**, que es donde estaba el 30% de 2020 y
donde probablemente está otra vez.

---

## 📏 6. Medición

**Hipótesis:** dos, y son de naturaleza distinta. **Técnica:** la imagen reducida y autocontenida es varias
veces más pequeña que la imagen por omisión con SDK, y arranca más rápido — y la imagen de Windows del módulo
sin migrar es de otro orden de magnitud. **Económica:** para el tráfico de Cordillera, **los contenedores
administrados son más baratos que un orquestador y que una máquina virtual**, y la diferencia se amplía al
sumar el costo de operación de las dos personas.

**Condiciones:** SDK 10.0.401 · Release · imágenes construidas con caché limpia · región **East US 2** para
todas las cifras de precio · precios tomados de las páginas oficiales de Azure con **fecha de consulta
registrada por línea** · volumen de tráfico del generador con semilla `19970417` y el volumen real declarado
de Cordillera · el arranque medido como tiempo hasta responder el primer chequeo de salud, 10 repeticiones con
2 de calentamiento descartadas.

**Competidores:** cuatro imágenes base, y tres formas de alojamiento.

**Los comandos:**

```powershell
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 20 --imagenes
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja completa --region eastus2
```

**Resultado:** ⏳ pendiente de ejecución en tu máquina.

**A · El tamaño de las imágenes**

| Imagen | Tamaño | Arranque hasta el primer chequeo | ¿Intérprete de comandos? |
|---|---|---|---|
| `sdk:10.0` (el error de principiante) | ⏳ | ⏳ | sí |
| `aspnet:10.0` (por omisión, correcta) | ⏳ | ⏳ | sí |
| `runtime-deps:10.0-noble-chiseled` + autocontenido | ⏳ | ⏳ | **no** |
| ídem + recortado | ⏳ | ⏳ | no |
| **`framework/aspnet:4.8-windowsservercore`** (el módulo sin migrar) | ⏳ | ⏳ | sí |

**B · La factura mensual, por forma de alojamiento**

| Forma | Cómputo | Base de datos | Transferencia de salida | Telemetría | **Total** | Operación (h/mes) | Amarre |
|---|---|---|---|---|---|---|---|
| Contenedores administrados | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | **bajo**: la imagen corre en cualquier parte |
| Orquestador (AKS) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | bajo en el estándar, **alto en las horas aprendidas** |
| Máquina virtual (como hoy) | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | bajo, y es lo único bueno de esta fila |
| Centro de datos propio (2019, referencia) | ⏳ | ⏳ | 0 | 0 | ⏳ | ⏳ | ninguno, y **ningún respaldo eléctrico** |

> 🧭 **La columna de amarre no es la que se espera, y por eso está.** El amarre de esta arquitectura **no es
> técnico**: una imagen de contenedor corre en cualquier proveedor y el estándar de OpenTelemetry se exporta a
> donde sea. El amarre real está en **lo que las dos personas aprendieron a operar** — y eso no se migra con un
> `docker push`. Es el mismo argumento contra el orquestador visto desde otro lado: la opción que más amarra es
> la que exige más conocimiento específico para seguir funcionando.

**C · Las tres deudas, en pesos al mes**

| Deuda | De la fase | Costo mensual del atajo | Costo de pagarla | Veredicto |
|---|---|---|---|---|
| Volcado completo del catálogo | 15 | ⏳ | ⏳ | ⏳ |
| Cola en tabla vs. mensajería | 17 | 0 en factura / ⏳ en operación | ⏳ | ⏳ |
| Telemetría sin muestreo | 19 | ⏳ | ⏳ (menos visibilidad) | ⏳ |

> ⚖️ **Veredicto** *(expectativa, todavía sin ejecutar — `formato-de-mediciones.md` §2.6)*. Se espera que la
> tabla A muestre una diferencia grande entre la imagen con SDK y la reducida, y **un salto de orden de
> magnitud con la de Windows** — que es el argumento económico para terminar la migración de la fase 11. Se
> espera que la tabla B favorezca los contenedores administrados, con la diferencia ampliándose al incluir la
> última columna. Y se espera que la tabla C tenga **un veredicto incómodo**: que la cola en tabla gane para
> este volumen, y que la paginación del catálogo se pague sola.
>
> **Los cuatro umbrales que tu ejecución tiene que determinar:** (1) **a partir de qué tráfico el orquestador
> empieza a convenir** — el número que hace defendible decir "Kubernetes no, todavía"; (2) **cuánto cuesta al
> mes el volcado completo del catálogo**, que decide si la paginación de la F15 es una mejora o una urgencia;
> (3) **qué porcentaje de muestreo sostiene la pregunta de la F19 al precio publicado**; y (4) **cuánta
> capacidad se está pagando sin usar**, que es la columna que explica 2020 y la que hay que revisar cada mes.
>
> 📝 Y la advertencia de honestidad más importante del curso, porque esta tabla se puede usar para mentir de
> las dos direcciones: **la fila del centro de datos propio no incluye el riesgo**. No tenía respaldo eléctrico
> confiable y la copia de la base se guardaba en un disco externo en la oficina de al lado. Comparar solo el
> total es la misma deshonestidad que comparar solo la latencia. Si esta tabla se usa para argumentar que 2020
> fue un error, **está mal usada**.

---

## 🧱 7. Miniproyecto — la factura que nadie había hecho

**El encargo**

De don Fernando Escobar, socio y el que firma. No es un correo: es lo que dijo en una reunión, y Duván lo
anotó porque supo que iba a tener que contestarlo:

> *"En 2020 me dijeron que la nube era más barata. Pago un 30% más. Nadie me ha explicado por qué, y yo asumo
> que es porque no supimos hacerlo o porque nos vieron la cara — no sé cuál de las dos me molesta más.*
>
> *Ahora me vienen con esto nuevo. Yo no entiendo de contenedores. Entiendo de facturas. Tráeme la factura de
> lo que quieren hacer, tráeme la de lo que tenemos, y dime en qué me estoy equivocando. Y esta vez quiero
> saber qué pasa si nos va bien: si vendemos el doble, ¿pago el doble?"*

**Por qué duele**

Porque la última pregunta es la buena, y es la que ninguna de las veinte fases anteriores contestó. Las
tres deudas de esta fase **crecen con el uso**: más tráfico es más transferencia del volcado completo, más
telemetría sin muestrear, más filas en la cola. Don Fernando está preguntando por la derivada, y la derivada es
donde viven los atajos.

Y duele porque hay que explicarle el 30% de 2020 **sin echarle la culpa a nadie y sin defenderse**. Dos de los
cuatro mecanismos eran inevitables, uno fue falta de hábito, y ninguno fue mala fe. Decir eso en el lenguaje de
don Fernando es más difícil que construir la imagen.

**Datos de entrada**

| Qué | Detalle |
|---|---|
| En producción | catálogo (API), cierre de regalías (fondo), Redacción (web), escritorio de existencias |
| Sin migrar | un módulo en .NET Framework 4.8 — el de reportes, de los cuatro de la F11 |
| Base de datos | SIGE en Azure, con el esquema de 1997 y once procedimientos |
| Personas | 90, en tres oficinas; **dos** mantienen todo |
| Integrador | Almenara sincroniza el catálogo **cada hora** |
| Referencia | la factura de 2019 del centro de datos, y la de 2020 en la nube (+30%) |
| Región | East US 2, para todas las cifras |
| El servidor olvidado | una máquina de pruebas encendida desde 2020 |

**Criterios de aceptación**

1. Las cuatro cosas contenerizables están en imágenes, con **tamaño y arranque medidos** (tabla A). Y está
   escrito qué **no** se conteneriza y por qué.
2. La **hoja de costos mensual** está completa, y **cada línea tiene precio publicado, fuente, fecha y
   región**. Una línea sin fuente no cuenta.
3. Están las **tres formas de alojamiento** comparadas (tabla B), con la columna de horas de operación
   estimadas y el criterio con que se estimaron.
4. Está calculada **la capacidad que se paga sin usar**, y ese número está señalado como la explicación de 2020.
5. Los **cuatro mecanismos del 30%** están explicados con su número, y está dicho **cuáles eran inevitables y
   cuál fue falta de hábito**. Sin absolver y sin acusar.
6. 💸 **Las tres deudas están cobradas en la tabla C**, con veredicto. Y si un veredicto es "el atajo se
   queda", está sostenido con el número.
7. Está contestada la pregunta de la derivada: **si Cordillera vende el doble, qué líneas se duplican**, cuáles
   no, y cuál crece más rápido que el negocio.
8. La decisión sobre Kubernetes está tomada y **sostenida con el umbral de tráfico** en que cambiaría. "No lo
   necesitamos" sin ese umbral no cumple el criterio.
9. Está calculado el costo acumulado del **servidor de pruebas de cinco años**, y están escritas las tres
   defensas.
10. **Medición de cierre:** las tres tablas de la sección 6. Van en el mensaje del tag `mini-20`.

**Restricciones de estilo y alcance**

Código nuevo. **Ninguna cifra de precio escrita de memoria**: toda va con su URL y su fecha, o no va. Sin
canalización de despliegue. Sin cambiar la base de datos de sitio.

Y una restricción que es el punto de la fase: **la comparación con el centro de datos tiene que incluir lo que
el centro de datos no tenía**. Una tabla que solo compara totales es una tabla que miente por omisión, y es
justamente la clase de tabla que produjo la conversación de 2020.

**La trampa**

Vas a calcular la factura, vas a ver que los contenedores administrados salen más baratos que la máquina
virtual actual, y vas a escribir una recomendación limpia con un ahorro mensual.

Y el ahorro va a ser **mentira por omisión**, por dos razones que se cancelan en direcciones distintas.

La primera: no vas a haber contado lo que cuesta **llegar** ahí. Contenerizar cuatro cosas, probarlas, migrar
la configuración, migrar los secretos, y hacerlo con las dos personas que además mantienen SIGE. Eso son horas,
y las horas tienen precio. Un ahorro mensual que tarda dieciocho meses en recuperar la inversión es un ahorro
distinto del que aparece en tu tabla.

La segunda, y es la que duele más: **el módulo que la fase 11 no migró no se va**. Sigue en .NET Framework 4.8,
sigue necesitando Windows, y si tiene que correr en contenedor arrastra una imagen de otro orden de magnitud
—y posiblemente nodos de Windows pagados aparte—. **Tu arquitectura moderna no elimina la máquina virtual: la
duplica.** El ahorro que calculaste asumía que la máquina de hoy se apaga, y no se apaga.

Cuando lo encuentres —y búscalo, porque la tabla no lo va a señalar— escribe dos cosas: **el punto de
equilibrio en meses** contando la inversión, y **qué habría que migrar para que la máquina virtual realmente se
apague**. La segunda respuesta es un ítem de presupuesto de la fase 11 llegando cuatro fases tarde con su
precio puesto — y es exactamente el argumento que le faltaba.

<details><summary>Pista 1 — el enfoque</summary>

Empieza por la factura de **hoy**, no por la de la propuesta. Sin la línea base no hay comparación, y la línea
base es la que le interesa a don Fernando: él ya paga eso y quiere entenderlo.

Para el 30% de 2020, no busques un culpable: busca los cuatro mecanismos y ponle número a cada uno. Vas a
descubrir que suman aproximadamente el 30% y que **dos de los cuatro eran inevitables**. Eso es la respuesta
honesta y es mejor que cualquier disculpa.

Y para la pregunta de la derivada, marca cada línea con cómo crece: fija, proporcional al tráfico, o
proporcional al volumen de datos. Las tres deudas van a caer todas en la segunda o la tercera categoría, y eso
es la respuesta.

</details>

<details><summary>Pista 2 — la herramienta</summary>

Para las imágenes base y sus variantes:
`https://learn.microsoft.com/dotnet/core/docker/container-images`

Para las imágenes reducidas y qué quitan:
`https://learn.microsoft.com/dotnet/core/docker/build-container`

Para publicar recortado y autocontenido, y qué rompe:
`https://learn.microsoft.com/dotnet/core/deploying/trimming/trim-self-contained`

Para los precios —y aquí está la mitad del trabajo— usa la calculadora y las páginas de precios de Azure, y
**anota la fecha de cada consulta**. Los precios de transferencia de salida y de ingesta de telemetría son los
dos que más sorprenden y los dos que más cuestan en esta hoja.

Y para estimar horas de operación: mira cuántas versiones al año publica cada opción y qué hay que hacer en
cada una. Un plano de control que se actualiza cuatro veces al año son cuatro ventanas de mantenimiento.

</details>

<details><summary>Pista 3 — el esqueleto</summary>

```csharp
// Cada línea con su fuente. Sin excepción.
public sealed record CostLine { /* … Resource, Region, UnitPriceUsd, PriceSource, PricedOn … */ }

// Cómo crece: es lo que contesta la pregunta de don Fernando.
public enum CostGrowth { Fixed, PerRequest, PerGigabyte, PerUser }

// Las tres formas, para poder compararlas en la misma unidad.
public sealed record HostingOption(string Name, IReadOnlyList<CostLine> Lines, double OperationHoursPerMonth);

// Y el punto de equilibrio, que es la cifra que la trampa esconde.
public sealed record Payback(decimal UpfrontUsd, decimal MonthlySavingsUsd)
{
    public int? Months => MonthlySavingsUsd > 0
        ? (int)Math.Ceiling(UpfrontUsd / MonthlySavingsUsd)
        : null;   // ← null significa que nunca se recupera, y hay que poder decirlo
}
```

</details>

**Cómo se entrega**

```powershell
docker build -t cordillera/catalogo:20 -f src\modern\Cordillera.Catalog.Api\Dockerfile src\modern
dotnet run -c Release --project src\modern\Cordillera.Bench.Cli -- --fase 20 --imagenes
dotnet run -c Release --project src\modern\Cordillera.Costos -- --hoja completa --region eastus2
```

```bash
git tag -a mini-20 -m "Mini F20: imagen reducida <X> MB vs SDK <Y> MB vs Windows <Z> MB · factura mensual: administrados <A> / AKS <B> / VM <C> · capacidad desperdiciada <D>% · tres deudas cobradas · equilibrio en <M> meses"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Conteneriza el API del catálogo con la imagen por omisión y mide el tamaño. Es la línea base.
2. Pásala a construcción en varias etapas y mide otra vez. Anota el cociente.
3. Pásala a autocontenida con base reducida. Mide, y **entra al contenedor a mirar** — no vas a poder, y eso es
   el punto.
4. Construye la imagen del módulo en .NET Framework 4.8 y compara su tamaño con la de la sección 5.1. Anota el
   orden de magnitud.
5. Mide el arranque de las cuatro imágenes hasta el primer chequeo de salud respondido.
6. Toma **una** línea de la factura actual, con su precio publicado, su fuente y su fecha. Practica el formato
   antes de hacer las veinte.

**🟡 Intermedio (7–14)**

7. Construye la hoja de costos completa de la arquitectura actual. Cada línea con fuente y fecha.
8. Calcula la **capacidad que se paga sin usar** en la máquina virtual actual. Es el número de 2020.
9. Calcula el costo acumulado del servidor de pruebas de cinco años. Escribe las tres defensas.
10. 💸 Paga la deuda de la fase 15: cuánto cuesta al mes el volcado completo que Almenara descarga cada hora, y
    cuánto ahorraría paginar.
11. 💸 Paga la deuda de la fase 19: elige el porcentaje de muestreo desde el volumen medido y el precio
    publicado. Justifica que ese porcentaje **sostiene la pregunta** que la telemetría tiene que contestar.
12. 💸 Paga la deuda de la fase 17: compara la cola en tabla con mensajería administrada en factura **y** en
    horas de operación. Pon precio a la hora.
13. Marca cada línea de la hoja con cómo crece —fija, por petición, por gigabyte, por usuario— y contesta la
    pregunta de la derivada.
14. Construye la tabla B con las tres formas de alojamiento, incluida la columna de horas de operación y el
    criterio con que la estimaste.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** La factura subió un 40% de un mes a otro y nadie desplegó nada. Enumera cinco causas
    posibles y el orden en que las verificarías.
16. **Diagnóstico.** La imagen recortada funciona en tu máquina y falla en producción con un error de tipo no
    encontrado. Explica el mecanismo y arréglalo sin renunciar al recorte.
17. **Medición.** Ejecuta la medición completa de la sección 6, las tres tablas, con precios reales fechados.
18. **Medición.** Determina el **umbral de tráfico** a partir del cual el orquestador empieza a convenir. Es lo
    que hace defendible el "no, todavía".
19. Calcula el **punto de equilibrio en meses** de la propuesta, contando la inversión de contenerizar. Y
    calcula qué pasa si nunca se migra el módulo de la fase 11.
20. **Decisión.** ¿Kubernetes para Cordillera? Decide, sostén la decisión con el umbral del ejercicio 18, y
    escribe qué tendría que cambiar para que la respuesta fuera otra.
21. **Decisión — ¿se migra, se envuelve o se deja quieto?** La máquina virtual de SIGE, con su base de datos y
    el módulo de reportes. Y ahora la pregunta tiene una variante nueva que las fases anteriores no podían
    hacer: **¿se deja quieto y se paga, sabiendo cuánto?** Un "se deja quieto" con la cifra escrita al lado es
    una decisión; sin la cifra es una omisión.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye una hoja de costos que "demuestre" que la nube es más barata que el centro de
    datos, y otra que demuestre lo contrario. Sin mentir en ninguna cifra. Después explica qué omite cada una —y
    reconoce cuál de las dos se parece más a la que te habrías hecho sola.
23. **Adversarial.** Encuentra tres formas de que la factura crezca sin que nadie despliegue nada, y escribe la
    alerta o el hábito que detecta cada una.
24. **Diseño.** Escribe el plan de doce meses con su presupuesto: qué se conteneriza, en qué orden, cuánto
    cuesta llegar, cuándo se apaga la máquina virtual actual —**si se apaga**—, y qué se deja quieto a
    propósito con su costo declarado.
25. **Defiende una decisión ante quien no es ingeniera.** Escríbele a don Fernando una página: por qué salió un
    30% más en 2020 —sin culpar a nadie y sin defenderte—, qué cuesta lo nuevo, en cuántos meses se recupera, y
    **qué pasa si vende el doble**. Esta es la más difícil del curso, y es la única que se parece a lo que vas
    a tener que hacer de verdad.

**🔥 Opcionales**

- Mide qué cambiaría con una canalización de despliegue continuo: en tiempo de las dos personas y en factura.
- Investiga compilación anticipada —*Native AOT*— para el API: mide tamaño, arranque y **qué se rompe**. Puede
  cambiar la tabla A y no cambia la B.
- Calcula qué costaría un plan de recuperación en otra región, y decide si Cordillera debería tenerlo **antes**
  de tener respaldos probados. La respuesta es no, y el ejercicio es saber decir por qué sin condescendencia.

---

## 📚 9. Referencias

**Documentación oficial**

- `https://learn.microsoft.com/dotnet/core/docker/container-images` — el catálogo de imágenes base y qué trae
  cada una.
- `https://learn.microsoft.com/dotnet/core/docker/build-container` — construcción en varias etapas y variantes
  reducidas.
- `https://learn.microsoft.com/dotnet/core/deploying/trimming/trim-self-contained` — el recorte y **qué rompe**.
  Léela antes de recortar, no después.
- `https://learn.microsoft.com/azure/container-apps/` — contenedores administrados, que es la opción probable.
- `https://azure.microsoft.com/pricing/calculator/` — la calculadora. **Anota la fecha de cada consulta.**
- `https://azure.microsoft.com/pricing/details/bandwidth/` — transferencia de salida: la línea que nadie ve
  venir y que conecta con la deuda de la F15.
- `https://learn.microsoft.com/azure/azure-monitor/logs/cost-logs` — el costo de la telemetría, que es la
  deuda de la F19 con precio.

**Libros / artículos**

- *Cloud FinOps* (J.R. Storment, Mike Fuller) — la práctica de gobernar el costo de la nube, y en particular la
  idea de que **el costo es responsabilidad de quien construye**, no del área financiera. Es el libro que le
  faltaba a Cordillera en 2020. **Verifica la edición antes de citarlo.**
- La documentación del *Cloud Adoption Framework* de Microsoft tiene la parte de gobernanza de costos, que es
  donde están las tres defensas del servidor olvidado.

> ⚠️ Verifica las URLs. Y dos advertencias propias de esta fase, porque es la más fácil de contaminar. La
> primera: **los precios cambian y cualquier cifra que encuentres en un artículo está vencida**. No copies
> números de blogs; ve a la página de precios y anota la fecha. La segunda: **casi todo el material de
> arquitectura en la nube está escrito para empresas grandes**, y la conclusión por omisión —Kubernetes,
> microservicios, escalado automático— es la correcta para ellas y probablemente incorrecta para una editorial
> con dos personas de sistemas. Ese material no está mal: está escrito para otro lector.

**Orden de lectura sugerido:** antes de construir, la página de imágenes base y la de recorte — quince minutos
y evitan el fallo que solo aparece en producción—. Durante el miniproyecto, la de transferencia de salida
**antes** de calcular la deuda de la F15: el precio explica por qué esa deuda es la más grande. Al cerrar,
*Cloud FinOps*: se lee muy distinto cuando ya tienes tu propia hoja con una columna de capacidad desperdiciada.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Existe la factura, y es lo que las veinte fases anteriores no tenían. Todo el curso midió en milisegundos y
en megabytes; esta fase tradujo esas unidades a pesos mensuales, y **algunas decisiones que parecían obvias
dejaron de serlo**.

Y quedó explicado el 30% de 2020 con cuatro mecanismos numerados, de los cuales **dos eran inevitables** —la
máquina dimensionada por el pico y la transferencia que dentro del edificio era gratis—, **uno fue la suma de
cosas pequeñas** que venían incluidas con el hierro, y **uno fue falta de hábito**: nadie apagaba nada porque
en el centro de datos no hacía falta. Ninguno fue mala fe, y ninguno fue ignorancia. Lo que faltó fue que
alguien tuviera el trabajo de mirar la factura desglosada una vez al mes.

Se cobraron las tres deudas, y lo que las une es la lección de la fase: **ninguna tenía síntoma técnico**. Las
tres funcionaban. Ninguna aparecía en una traza, en una prueba o en un percentil. Las tres aparecían en la
factura, y las tres crecen con el uso — así que el día que a Cordillera le vaya mejor, las tres cuestan más.
Ese es el mismo mecanismo del 30% de 2020, operando sobre código de 2026, y esa simetría es el punto entero
de esta fase.

Y probablemente el veredicto de la tabla C sea incómodo para el instinto de ingeniería: **la cola en tabla se
queda**. Es un atajo, está declarado como atajo, y para este volumen es la opción correcta. Un atajo con su
número al lado y su condición de salida escrita no es deuda técnica: es una decisión.

El bloque D cierra aquí. Lo que viene es el **bloque E**, y cambia de materia sin cambiar de pregunta. La fase
21 entra en datos y en modelos —y la pregunta va a ser la misma que ha ordenado el curso desde la fase 07,
aplicada a un terreno donde casi nadie la hace: **¿esto se migra, se envuelve o se deja quieto?** Con una
diferencia que esta fase acaba de instalar: de ahora en adelante, la respuesta viene con su costo mensual al
lado. Don Fernando lo va a preguntar.

> **La señal de que quedó bien:** *"Don Fernando entendió el 30% de 2020, y no porque se lo explicáramos bien:
> porque le mostramos la columna de la capacidad que estábamos pagando sin usar. Y la primera cosa que pidió no
> fue el proyecto nuevo: fue revisar la factura desglosada cada mes."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el miniproyecto corriendo y
> `git status` limpio:
>
> ```bash
> git tag -a fase-20 -m "F20 cerrada:
> - las cuatro cosas contenerizadas, con tamano y arranque medidos
> - lo que NO se conteneriza, con su razon escrita
> - hoja de costos mensual: cada linea con precio publicado, fuente, fecha y region
> - el 30% de 2020 explicado con cuatro mecanismos, sin absolver y sin acusar
> - TRES deudas cobradas en la misma hoja: paginacion F15, cola en tabla F17, muestreo F19
> - Kubernetes descartado CON el umbral de trafico en que cambiaria
> - punto de equilibrio en meses, contando la inversion y el modulo que la F11 no migro"
> ```
>
> **Y las tres facturas de las tres deudas, en un solo lugar:**
>
> ```bash
> git diff fase-15 fase-20 -- src/modern/Cordillera.Catalog.Api/
> git diff fase-17 fase-20 -- src/modern/Cordillera.NightPress/
> git diff fase-19 fase-20 -- src/modern/Cordillera.Catalog.Api/Program.cs
> ```
>
> Tres diffs pequeños y un cambio de decisión grande. **Y uno de los tres puede estar vacío a propósito** —si
> la cola en tabla se queda—: es el cuarto tipo de pago del libro de deudas, el que se paga entendiendo el
> costo en vez de eliminándolo.

---

## 📌 Pendientes sugeridos

*Material de autoría, no de lectura.*

- **`INSTINTOS.md`** — tres entradas en la familia *servicios, identidad y operación*, y una de ellas merece
  estar entre las más destacadas del curso: contenerizar sin mirar el tamaño; **Kubernetes porque es el
  estándar** —con su umbral, porque sin umbral el reflejo contrario es igual de malo—; y **evaluar una
  arquitectura sin su factura**, que es la que resume la fase. La tercera necesita la formulación corta: *lo que
  no tiene síntoma técnico solo aparece en la factura, y crece con el éxito.*
- **`BENCHMARKS.md`** — entrada ⏳ *F20 · El tamaño de las imágenes y la factura mensual*, con tres tablas. **Y
  una regla de honestidad nueva, la sexta**: una cifra de costo va con precio publicado, fuente, fecha y
  región, o no va. Es el equivalente monetario de las condiciones de una medición y conviene que quede escrita
  junto a las otras cinco.
- **Deudas 💸 pagadas, tres a la vez:** paginación (F15), cola en tabla (F17), muestreo (F19). Es el único pago
  triple del curso y conviene que el libro de §7.1 lo marque como tal, con el patrón que las une: **ninguna
  tenía síntoma técnico**. Y si la de la F17 termina en "el atajo se queda", es el cuarto tipo de pago
  —diff vacío a propósito— repetido, lo cual **confirma que el tipo existe** y no era una excepción de la F09.
- **Tipos nuevos para el congelamiento:** `Cordillera.Costos` (proyecto nuevo), `CostSheet`, `CostLine`,
  `Quantity`, `CostGrowth`, `HostingOption`, `Payback`. Y los `Dockerfile` de los cuatro proyectos modernos más
  el de `Sige.Reports`.
- **Una decisión de alcance que conviene declarar:** `Cordillera.Costos` es el único proyecto del curso que no
  sirve al dominio. Vale la pena decidir si vive en `src/modern/` con los demás o en un `src/tools/` aparte.
  **Recomendación: en `modern/`**, porque la tesis de la fase es que la factura es parte de la arquitectura y
  moverla a `tools/` la contradice tipográficamente.
- **Para la fase 21:** el hábito que esta fase instala —toda decisión con su costo mensual— tiene que
  sobrevivir al bloque E, donde es especialmente fácil de olvidar: el costo de un modelo por token es
  exactamente la clase de línea que crece con el uso y no tiene síntoma técnico. Conviene que la 21 lo herede
  explícitamente.
- **Para la fase 24:** cuatro insumos fuertes — el 30% de 2020 con sus cuatro mecanismos (que es el mejor
  material del curso sobre por qué una decisión razonable sale mal), el umbral de Kubernetes, el punto de
  equilibrio contando el módulo que la F11 no migró, y la carta a don Fernando del ejercicio 25. Y la
  pregunta que esta fase agregó a la trilogía: **"se deja quieto" ahora exige la cifra al lado.**
