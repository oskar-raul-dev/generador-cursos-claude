# 07 — Respuestas

> Solucionario centralizado del bloque `08-entrada-salida-y-recursos`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--el-descriptor-y-el-recurso) · [02](#02--todo-es-un-archivo-y-dónde-se-rompe) ·
[03](#03--bloqueante-no-bloqueante-y-asíncrono) · [04](#04--búferes-y-el-coste-de-la-frontera) ·
[05](#05--el-árbol-de-directorios) ·
[06 — transversales](#06--simulación-preguntas-transversales) ·
[06 — pizarra](#06--simulación-problemas-de-pizarra)

---

# 01 — El descriptor y el recurso

**01 → 1. ¿Qué es un descriptor de archivo?**

⏱️ Un entero pequeño que indexa una tabla que el núcleo mantiene por proceso, y que apunta a algo
abierto.
🗣️ `open` devuelve el descriptor libre más bajo; `read`, `write` y `close` lo usan. Es el asa
universal de la entrada y la salida en Unix.
🔬 En Java y en Go no se ve el número, pero está: un `FileInputStream`, un `Socket` o un `os.File` lo
envuelven. Que no se vea es justo lo que hace que se olvide cerrarlo.

**01 → 2. ¿Qué tipos de recurso se representan con un descriptor?**

⏱️ Archivos regulares, sockets, tuberías, terminales, dispositivos y temporizadores.
🗣️ Esa unificación es el paradigma del capítulo `02`: las mismas cuatro llamadas sirven para todos,
que es lo que hace posible `cat archivo | grep hola > salida`.
🔬 La consecuencia práctica más importante es que **todos compiten por el mismo límite**: un pico de
conexiones puede impedirte abrir un archivo de configuración, y el error será el mismo.

**01 → 3. ¿Qué significa el error `Too many open files`?**

⏱️ Que el proceso alcanzó su límite de descriptores abiertos. Es `EMFILE`, errno 24.
🗣️ No es que el disco esté lleno ni que falte memoria: es un contador que llegó a su tope. Y afecta a
todo a la vez —archivos, sockets, conexiones a base de datos— porque todos salen del mismo cubo.
🔬 Hay un error hermano que conviene distinguir: `ENFILE`, "file table overflow", que es el límite de
**todo el sistema** y no el del proceso. El primero se arregla en tu servicio; el segundo indica que
hay varios procesos contribuyendo.

**01 → 4. ¿Qué construcción garantiza el cierre en Java? ¿Y en Python? ¿Y en Go?**

⏱️ `try-with-resources` en Java, `with` en Python, `defer` en Go.
🗣️ Las tres garantizan la liberación al salir del ámbito aunque haya excepción. Java y Python cierran
en orden inverso al de apertura cuando hay varios recursos.
🔬 El matiz de Go es el de la pregunta 13: `defer` sale al final de **la función**, no del bloque. Y en
JavaScript no había construcción equivalente hasta `using` y `await using`, disponibles en
TypeScript desde 5.2; antes solo `try/finally`.

**01 → 5. ¿Qué descriptores tiene todo proceso nada más arrancar?**

⏱️ El 0, el 1 y el 2: entrada estándar, salida estándar y error estándar.
🗣️ Vienen heredados del proceso padre, y por eso la redirección del shell funciona: el shell los
reapunta antes de ejecutar el programa.
🔬 De ahí sale un detalle de seguridad conocido: si un proceso cierra el descriptor 0 y luego abre un
archivo, ese archivo **será** el descriptor 0, y cualquier cosa que escriba en la entrada estándar
acabará ahí. Es la base de una familia de ataques sobre programas con privilegios.

**01 → 6. ¿Qué hace `lsof -p`?**

⏱️ Lista todo lo que un proceso tiene abierto, con su tipo y su estado.
🗣️ Es la primera herramienta ante una sospecha de fuga: el conteo total dice si estás cerca del
límite, y agrupar por tipo dice de qué clase es el problema.
🔬 Lo que de verdad diagnostica es el **tipo**: `REG` apunta a archivos sin cerrar, `IPv4`/`IPv6` a
conexiones, y sockets en `CLOSE_WAIT` a código tuyo que no llama a `close`. En Linux, contar
`/proc/<pid>/fd` es más rápido si solo quieres el número.

**01 → 7. ¿Cierra el recolector de basura de Java los archivos que olvidaste?**

⏱️ Sí, pero cuando pase, y pasa por presión de memoria, no por presión de descriptores.
🗣️ Medido: 200 aperturas sin cerrar dejan 200 descriptores extra; tras un `System.gc()` explícito
bajan a cero. El recolector los cierra mediante el `Cleaner` asociado.
🔬 Y ahí está el veneno: un objeto que envuelve un descriptor ocupa decenas de bytes en el montón, así
que puedes acumular cien mil descriptores con el montón medio vacío y sin que el recolector vea
ninguna razón para actuar. Por eso el incidente ocurre con memoria de sobra.

**01 → 8. ¿Cuánto cuesta mantener un descriptor abierto?**

⏱️ El descriptor es un entero: nada. Lo que cuesta son las estructuras del núcleo detrás y, sobre
todo, que el total es finito.
🗣️ Un socket abierto lleva búferes de recepción y envío asociados, que sí ocupan memoria del núcleo.
Un archivo regular abierto ocupa mucho menos.
🔬 La forma correcta de pensarlo es que **no es un coste por unidad sino un recurso compartido con un
techo duro**. La pregunta no es "cuánto ocupa uno" sino "cuántos caben y cuántos llevo".

**01 → 9. ¿Por qué `ulimit -n` puede no ser el límite que aplica?**

⏱️ Porque hay al menos tres límites en juego y manda el menor: el del shell, el del núcleo por
proceso y el del contenedor.
🗣️ Verificado en esta máquina: `ulimit -n` devuelve `1048576` y el proceso muere a los **122 877**,
porque `kern.maxfilesperproc` vale `122880`.
🔬 Además, el límite del proceso puede no ser el del shell donde lo probaste: si lo arranca un gestor
de servicios o un orquestador, manda la configuración de ese. Diagnosticar mirando solo uno de los
tres es la razón de que estos incidentes duren horas.

**01 → 10. ¿Por qué Python no acumula descriptores aunque no llames a `close`?**

⏱️ Porque usa conteo de referencias: al perder la última referencia, el objeto se destruye
inmediatamente y cierra el descriptor.
🗣️ Medido: 200 `open()` sin `close()` en un bucle dejan **un** descriptor extra, el del último, porque
cada reasignación destruye el anterior.
🔬 Y las dos salvedades que completan la respuesta: **falla con ciclos de referencias**, donde
interviene el recolector cíclico y deja de ser inmediato; y **no es una garantía del lenguaje** sino
de CPython — en otra implementación, como PyPy, no ocurre. Por eso `with` sigue siendo obligatorio.

**01 → 11. ¿Por qué Java sí los acumula?**

⏱️ Porque la liberación depende del recolector de basura, y el recolector se dispara por memoria.
🗣️ Es exactamente la diferencia con Python: sin conteo de referencias, no hay momento determinista en
el que el objeto muera. El `Cleaner` acaba cerrando el descriptor, pero cuándo no lo controlas.
🔬 La consecuencia de diseño, que es lo que se pregunta: **la gestión determinista de recursos no se
puede delegar a un recolector**, y por eso el lenguaje tuvo que añadir `try-with-resources` en Java 7.
Es también el motivo de que finalizadores como `finalize` estén obsoletos.

**01 → 12. ¿Qué hace Go si no cierras?**

⏱️ Nada. El descriptor vive hasta que muere el proceso.
🗣️ Go no tiene finalizadores fiables: `runtime.SetFinalizer` existe pero no garantiza ejecución. Si no
llamas a `Close`, la fuga es permanente.
🔬 Es el más explícito de los tres y también el más honesto: no promete nada que no vaya a cumplir. La
contrapartida es que la disciplina de `defer` no es opcional — y su trampa es la pregunta siguiente.

**01 → 13. ¿Dónde está la trampa de `defer` dentro de un bucle?**

⏱️ `defer` se ejecuta al salir de **la función**, no del bloque. En un bucle, los cierres se acumulan.
🗣️ Un bucle que abre diez mil archivos con `defer f.Close()` mantiene los diez mil abiertos hasta que
la función termina. Es la fuga de descriptores más común de Go.
🔬 La corrección es extraer el cuerpo del bucle a su propia función, para que cada iteración tenga su
propio ámbito de función:

```go
for _, ruta := range rutas {
    if err := procesar(ruta); err != nil { return err }   // el defer vive DENTRO de procesar
}
```
La alternativa —cerrar a mano al final de cada iteración— funciona, pero pierde la garantía ante un
`return` temprano o un `panic`, que es justo lo que `defer` compraba.

**01 → 14. ¿Por qué se reutilizan los números de descriptor y qué riesgo tiene?**

⏱️ Porque `open` devuelve siempre el libre más bajo. El riesgo es que un descriptor guardado apunte a
un recurso distinto del que creías.
🗣️ Si cierras el 7 y abres otra cosa, lo más probable es que la nueva sea también el 7. Un fragmento
de código que conservara el número antiguo escribiría en el recurso nuevo **sin ningún error**.
🔬 Es la versión a nivel de sistema operativo del *use after free*, y es especialmente desagradable
porque no hay excepción ni valor nulo: la escritura tiene éxito y va al sitio equivocado. En código
con envoltorios —Java, Go— el riesgo es menor pero no nulo: usar un `Socket` ya cerrado y reabierto
por otro hilo produce la misma clase de confusión.

**01 → 15. ¿Qué significa que un descriptor esté en `CLOSE_WAIT`?**

⏱️ Que el otro extremo cerró la conexión y tu proceso todavía no ha llamado a `close`.
🗣️ El sistema operativo ya recibió el `FIN` y está esperando que tu aplicación cierre su lado. Es un
estado que **solo depende de ti**: mientras no cierres, ahí se queda.
🔬 Por eso `CLOSE_WAIT` acumulándose es casi siempre código propio, no de la red ni del proveedor: una
excepción en el camino que salta el cierre, o un cliente HTTP cuyas respuestas no se consumen ni se
cierran. Se distingue de `TIME_WAIT`, que sí es normal, dura un par de minutos y lo gestiona el
sistema.

**01 → 16. ¿Qué hereda un proceso hijo y cómo se evita?**

⏱️ Hereda los descriptores abiertos del padre, salvo los marcados con `CLOEXEC`.
🗣️ Por eso un proceso lanzado desde tu servicio puede quedarse agarrado a un puerto o a un archivo que
tú creías cerrado: el sistema no lo libera porque sigue habiendo un titular.
🔬 La marca `FD_CLOEXEC` hace que el descriptor se cierre automáticamente al ejecutar otro programa, y
los lenguajes modernos la ponen **por defecto** —Python desde la versión 3.4, Java y Go en sus APIs
normales—. El problema aparece con código antiguo, con bibliotecas nativas y al abrir descriptores a
bajo nivel. El síntoma característico: un puerto sigue ocupado y el proceso que lo abrió ya no existe.

**01 → 17. ¿Cómo distingues una fuga de un problema de dimensionado?**

⏱️ Observando la curva en el tiempo: una fuga crece monótonamente y no baja; un dimensionado sube con
la carga y baja después.
🗣️ El comando es un bucle que cuente descriptores cada diez segundos durante un rato de tráfico
normal. Si tras el pico vuelve a la línea base, el código cierra bien y el límite es corto para la
concurrencia real.
🔬 Y la distinción decide la corrección, que es lo importante: **una fuga se arregla en el código; un
dimensionado, en la configuración**. Subir el límite ante una fuga solo mueve la fecha del incidente,
y encima lo hace menos frecuente y por tanto más difícil de diagnosticar.

**01 → 18. ¿Por qué el incidente aparece con memoria libre de sobra?**

⏱️ Porque descriptores y memoria son recursos independientes, y solo uno de los dos tiene presión.
🗣️ En Java, la liberación de descriptores va atada al recolector de basura, que solo actúa cuando hay
presión de memoria. Como los objetos envoltorio son diminutos, se pueden acumular cien mil
descriptores sin que el montón se acerque a su límite.
🔬 De ahí la consecuencia operativa: **el panel de memoria está verde mientras el servicio se cae**, y
el diagnóstico se va por el camino equivocado durante la primera hora. Es el argumento para
instrumentar descriptores abiertos como métrica propia, que es la pregunta 23.

**01 → 19. ¿Por qué subir el límite no es la corrección ante una fuga?**

⏱️ Porque una fuga crece sin techo: subir el límite solo retrasa el momento en que se alcanza.
🗣️ Si el servicio pierde descriptores a razón de mil por hora, multiplicar el límite por diez
convierte un incidente diario en uno semanal — y lo hace más difícil de reproducir y de diagnosticar,
porque ya no ocurre mientras alguien mira.
🔬 Subir el límite **sí** es la corrección cuando el diagnóstico dice dimensionado, y entonces hay que
calcularlo: conexiones concurrentes esperadas, más el pool de base de datos, más archivos, más
margen. Lo que no vale es subirlo sin haber hecho la distinción de la pregunta 17.

**01 → 20. Te dan quince minutos y un `pid`. Escribe los tres comandos, en orden, y qué concluyes de cada uno.**

⏱️ Cuántos hay y cuál es el límite; de qué tipo son; y si crecen con el tiempo.
🗣️ Los tres:

```bash
lsof -p <pid> | wc -l                                     # 1. ¿cuántos?
cat /proc/<pid>/limits | grep "open files"                # …y el límite REAL del proceso
lsof -p <pid> | awk '{print $5}' | sort | uniq -c | sort -rn | head   # 2. ¿de qué tipo?
while :; do echo "$(date +%T) $(lsof -p <pid>|wc -l)"; sleep 10; done # 3. ¿crece?
```
🔬 Qué concluye cada uno: el **primero** dice si estás cerca del techo, y el límite del proceso puede
no ser el del shell. El **segundo** es el diagnóstico de verdad —`REG` es archivos, `IPv4` conexiones,
`CLOSE_WAIT` código tuyo—. El **tercero** distingue fuga de dimensionado, que decide si la corrección
es de código o de configuración. Y si el proceso es Java, un cuarto comando barato: `jcmd <pid>
VM.native_memory` o directamente la métrica del `UnixOperatingSystemMXBean`, que da el número sin
`lsof`.

**01 → 21. ¿Por qué un socket compite por el mismo límite que un archivo?**

⏱️ Porque los dos son descriptores y el límite es del número de descriptores, no de su tipo.
🗣️ Es una consecuencia directa del paradigma del capítulo `02`: al unificar el asa, se unifica también
el recurso escaso.
🔬 La implicación de diseño es concreta y se olvida al dimensionar: el presupuesto de descriptores hay
que repartirlo entre **conexiones entrantes, conexiones salientes, pool de base de datos y archivos**.
Un servicio que acepta 10 000 conexiones y mantiene un pool de 100 a la base de datos necesita margen
para ambas cosas y para los archivos de configuración que abra al recargar.

**01 → 22. ¿Cuándo es legítimo devolver un recurso abierto desde una función?**

⏱️ Cuando la función es una fábrica y **la firma o la documentación dice que quien lo recibe se
encarga de cerrarlo**.
🗣️ Es un patrón perfectamente válido: `Files.newInputStream` lo hace, `os.Open` lo hace. Lo que no vale
es hacerlo sin decirlo, porque el que llama no tiene forma de saberlo.
🔬 Las convenciones que ayudan: en Go se devuelve el recurso y el error juntos, y el nombre `Open` ya
comunica la responsabilidad; en Java, devolver algo que implemente `AutoCloseable` es la señal, y el
javadoc debe decirlo explícitamente. La alternativa que elimina la duda es **invertir el control**:
en vez de devolver el recurso, aceptar una función que lo use y cerrarlo tú — es lo que hacen
`Files.lines` con `try-with-resources` o los gestores de contexto en Python.

**01 → 23. ¿Qué métrica expondrías y con qué umbral de alerta?**

⏱️ Descriptores abiertos y límite efectivo, con aviso al 80 % y alerta al 90 %.
🗣️ La métrica útil son **dos series**: el número abierto y el límite, porque el límite puede cambiar
al redesplegar en otro entorno. La alerta se define sobre el porcentaje, no sobre el valor absoluto.
🔬 De dónde se saca: en Java, `UnixOperatingSystemMXBean` da `getOpenFileDescriptorCount` y
`getMaxFileDescriptorCount` — y los exportadores estándar ya las publican. En Linux, contando
`/proc/self/fd`. Y conviene añadir una tercera señal derivada: **la pendiente**, porque una fuga lenta
cruza el 80 % sin que nadie lo note en un panel, mientras que una tasa de crecimiento sostenida con
tráfico plano es inequívoca.

**01 → 24. Un proceso hijo mantiene un puerto ocupado después de que el padre lo cerrara. Explica y corrige.**

⏱️ El hijo heredó el descriptor del socket al crearse, así que sigue habiendo un titular aunque el
padre cerrara el suyo.
🗣️ El sistema libera el puerto cuando **todos** los descriptores que lo referencian están cerrados. El
padre cerró uno; el del hijo sigue vivo, y por eso el `bind` del siguiente arranque falla con
"address already in use" sin que se vea ningún proceso escuchando.
🔬 La corrección es marcar el descriptor con `FD_CLOEXEC` al crearlo, o cerrarlo explícitamente en el
hijo antes de ejecutar el otro programa. En las APIs modernas viene por defecto, así que el caso
aparece con bibliotecas nativas o con código que abre sockets a bajo nivel. El diagnóstico se
confirma con `lsof -i :<puerto>`, que **sí** muestra al hijo — y ese es el momento en que se entiende
lo que pasa.

**01 → 25. Diseña la revisión de código que impediría esta clase de fuga en los cinco lenguajes: qué buscas y qué automatizas.**

⏱️ Buscar aperturas sin construcción de cierre, y automatizarlo con el analizador estático de cada
lenguaje más una prueba de carga que vigile la métrica.
🗣️ Qué se busca en cada uno:

```text
Java    `new FileInputStream`, `Socket`, `Connection` fuera de un try-with-resources
Python  open(  sin with
Go      defer dentro de un bucle · os.Open sin defer en la MISMA función
Node    fs.open / createReadStream sin close ni pipeline
TS      lo de Node, y Promise de recurso sin await
```
🔬 Qué se automatiza, que es la parte que perdura: **analizador estático** —SpotBugs y ErrorProne en
Java detectan recursos sin cerrar; `ruff`/`flake8` con la regla de `open` sin contexto; `go vet` y
`errcheck`; ESLint—. Todos con el fallo del análisis como error de compilación, no como aviso. Y una
**prueba de carga en integración continua** que ejecute mil peticiones y compruebe que la métrica de
descriptores vuelve a la línea base: es la única comprobación que detecta la fuga que el análisis
estático no ve, porque la fuga real suele estar en una rama de error. La revisión humana aporta lo
que ninguna herramienta ve: **quién es el dueño del recurso** cuando se devuelve desde una función.

**01 → 26. Un servicio acumula `CLOSE_WAIT` solo contra un proveedor concreto. Da tres hipótesis ordenadas y cómo las distingues.**

⏱️ Respuestas sin consumir, cierre en la rama de error, o un pool de cliente mal configurado.
🗣️ Las tres, en orden de probabilidad:

```text
1. RESPUESTAS SIN CONSUMIR   el cuerpo no se lee ni se cierra, así que la conexión no se devuelve
2. CIERRE EN LA RAMA DE ERROR una excepción en ese camino salta el close; el proveedor es el que más falla
3. POOL MAL CONFIGURADO       el keep-alive del cliente es mayor que el del servidor: él cierra, tú no
```
🔬 Cómo se distinguen: para la **1**, revisar si todas las llamadas a ese cliente cierran o consumen la
respuesta — en muchos clientes HTTP, no leer el cuerpo deja la conexión sin devolver al pool. Para la
**2**, correlacionar el crecimiento de `CLOSE_WAIT` con la tasa de errores contra ese proveedor: si
suben juntas, es esa. Para la **3**, comparar el tiempo de inactividad del pool con el del servidor
remoto, que suele estar documentado — si el suyo es menor, él cierra primero y tu pool conserva
conexiones muertas. Que ocurra **con un solo proveedor** apunta fuerte a la 2 y a la 3, porque la 1
sería un error de código que afectaría a todos los clientes por igual.

**01 → 27. Escribe el informe post-incidente de un `Too many open files`: causa raíz, por qué no se detectó antes, corrección inmediata y prevención.**

⏱️ Causa raíz en el código, detección ausente por falta de métrica, mitigación por reinicio y
prevención en tres capas.
🗣️ El esqueleto:

```text
IMPACTO      X minutos sin servicio; todas las operaciones, no solo las del recurso que fugaba
CAUSA RAÍZ   apertura sin cierre en la rama de error de <componente>, desde el despliegue <fecha>
POR QUÉ NO SE DETECTÓ  no había métrica de descriptores; el panel de memoria estaba verde;
             la fuga era lenta y el reinicio semanal la enmascaraba
INMEDIATO    reinicio del servicio (mitigación, no corrección) + corrección del cierre
PREVENCIÓN   1) métrica + alerta al 80 %  2) análisis estático bloqueante  3) prueba de carga en CI
```
🔬 Los dos puntos que distinguen un informe bueno. **El primero: "por qué no se detectó" es la sección
más valiosa y la que más se despacha en una línea.** Aquí tiene tres causas independientes —falta de
métrica, señal engañosa y enmascaramiento por reinicios— y cada una merece su acción. El
enmascaramiento por reinicios periódicos es especialmente importante de nombrar, porque significa que
**la fuga existía desde hacía meses** y el despliegue reciente solo cambió su velocidad. **El
segundo: distinguir mitigación de corrección.** Reiniciar devuelve el servicio y no arregla nada; si
el informe no lo separa, la corrección real se queda sin hacer.

**01 → 28. Tu servicio abre un archivo por petición y lo cierra correctamente, y aun así se agotan los descriptores bajo carga. Explica cómo puede ocurrir y qué cambiarías.**

⏱️ Porque el límite no es cuántos abres en total, sino **cuántos coinciden abiertos a la vez**:
concurrencia por duración.
🗣️ Con 500 peticiones concurrentes y un archivo abierto durante toda la petición, hay 500
descriptores simultáneos solo por eso, más las conexiones entrantes, más el pool de base de datos.
Cerrar correctamente no ayuda si el solapamiento es alto.
🔬 La aritmética que hay que hacer en voz alta: **descriptores simultáneos ≈ tasa de peticiones ×
tiempo que el recurso está abierto**. A 1 000 peticiones por segundo con el archivo abierto 200 ms,
son 200 abiertos en media — y el pico es mucho mayor. Qué cambiaría, en orden: **(1)** reducir el
tiempo abierto, leyendo el archivo de una vez y cerrando antes de la parte lenta de la petición;
**(2)** no abrirlo por petición si el contenido es el mismo, cacheándolo en memoria — que es lo que
suele resolver el caso real, un archivo de configuración o una plantilla; **(3)** acotar la
concurrencia; **(4)** subir el límite, que aquí **sí** es legítimo porque el diagnóstico es
dimensionado y no fuga.

**01 → 29. Tu servicio corre en un contenedor con un límite de descriptores distinto al de la máquina. Explica cómo lo averiguas y qué manda.**

⏱️ Se lee dentro del contenedor, en `/proc/<pid>/limits`, y manda el más restrictivo de toda la
cadena.
🗣️ El límite del anfitrión, el del entorno de ejecución de contenedores, el del manifiesto y el que
fije el punto de entrada del contenedor son cuatro valores distintos, y el proceso ve el resultado de
aplicarlos todos.
🔬 Los comandos y el orden: dentro del contenedor, `cat /proc/1/limits | grep "open files"` da el
efectivo, que es lo único que importa. `ulimit -n` en una sesión interactiva **puede mentir**, porque
el proceso principal se arrancó con otro entorno. Y hay una trampa frecuente: **una imagen base puede
fijar un límite bajo en su punto de entrada**, con lo que el valor del manifiesto se ignora. Lo que
conviene hacer, además de leerlo, es **exponerlo como métrica junto con el número de abiertos** —la
pregunta 23—, porque así el valor efectivo queda registrado en cada despliegue y deja de ser una
suposición.

**01 → 30. Escribe la política de recursos de un equipo: qué se abre, quién cierra, qué se prohíbe en revisión y qué se mide.**

⏱️ Todo recurso se abre dentro de una construcción de cierre; quien abre cierra salvo que la firma
diga lo contrario; se prohíbe abrir sin construcción; y se mide el número de abiertos contra el
límite.
🗣️ La política:

```text
ABRIR     siempre dentro de try-with-resources / with / defer / using. Sin excepciones.
CERRAR    quien abre, cierra. Si una función devuelve un recurso abierto, LA FIRMA LO DICE
          y su documentación nombra al responsable.
PROHIBIDO apertura sin construcción de cierre · defer dentro de bucle · confiar en el GC
MEDIR     descriptores abiertos, límite efectivo y pendiente. Aviso 80 %, alerta 90 %.
DIMENSIONAR el presupuesto se calcula: entrantes + salientes + pool BD + archivos + margen
```
🔬 Los dos puntos que hacen que una política así se cumpla en vez de decorar un wiki. **Primero:
automatizar todo lo automatizable** —análisis estático bloqueante en la integración continua, no
aviso—, porque una regla que depende de que un revisor se acuerde dura tres meses. **Segundo:
declarar el presupuesto de descriptores como parte del dimensionado del servicio**, junto a la
memoria y la CPU, de modo que exista un número esperado con el que comparar la métrica. Sin ese
número, la alerta al 80 % es de un límite que nadie eligió. Y una regla que conviene añadir aunque
suene obvia: **los recursos que viven tanto como el proceso** —pools, servidores de escucha— se
cierran en el apagado ordenado, y eso también se escribe, porque si no nadie lo implementa.

---

# 02 — Todo es un archivo, y dónde se rompe

**02 → 1. ¿Qué significa "todo es un archivo"?**

⏱️ Que archivos, sockets, tuberías, terminales y dispositivos se manipulan con el mismo tipo de asa
—el descriptor— y las mismas cuatro llamadas.
🗣️ Es una idea de Unix de 1970, y sigue siendo el mejor modelo mental para razonar sobre entrada y
salida: si todo es leer y escribir en un descriptor, una petición HTTP y una lectura de disco son el
mismo problema con distinta latencia.
🔬 Lo que se unifica es la **interfaz**, no la semántica — que es la pregunta 9 y el contenido del
resto del capítulo.

**02 → 2. ¿Qué cuatro llamadas al sistema comparten todos los tipos?**

⏱️ `open`, `read`, `write` y `close`.
🗣️ Su firma es idéntica para un archivo y para un socket, y por eso un programa que lea de la entrada
estándar y escriba en la salida funciona con archivos, tuberías y sockets sin cambiar una línea.
🔬 Hay más llamadas comunes —`fcntl`, `dup`, `ioctl`— y algunas que **no** valen para todos: `lseek`
no funciona sobre sockets ni tuberías, porque no hay posición a la que saltar.

**02 → 3. ¿Qué permite la redirección del shell y por qué funciona?**

⏱️ Permite cambiar el origen y el destino de un programa sin tocarlo, y funciona porque el shell
reapunta los descriptores 0, 1 y 2 antes de ejecutarlo.
🗣️ `programa < entrada.txt > salida.txt` no modifica el programa: modifica su tabla de descriptores.
El programa sigue leyendo del 0 y escribiendo en el 1 sin enterarse de nada.
🔬 Lo mismo hace la tubería `|`: crea un par de descriptores conectados y pone uno como salida del
primer proceso y otro como entrada del segundo. Es la composición del paradigma llevada al shell, y
la razón de que cada herramienta pequeña de Unix sea reutilizable.

**02 → 4. ¿Se puede poner un archivo regular en modo no bloqueante en Java?**

⏱️ No, y no compila: `FileChannel` no tiene `configureBlocking`.
🗣️ Verificado: `fc.configureBlocking(false)` da `cannot find symbol`, mientras que la misma llamada
sobre un `SocketChannel` funciona y se puede registrar en un selector.
🔬 El motivo es del sistema operativo, no de Java: un archivo regular siempre está "listo" para
`select`, así que el modo no bloqueante no tiene significado — en Linux, `O_NONBLOCK` sobre un archivo
regular se acepta y se ignora. Java lo expresa en el sistema de tipos: `FileChannel` no extiende
`SelectableChannel`.

**02 → 5. ¿Qué es `epoll` y para qué sirve?**

⏱️ Un mecanismo del núcleo de Linux para vigilar muchos descriptores a la vez y saber cuáles tienen
datos, sin sondearlos uno a uno.
🗣️ Es lo que permite que un solo hilo atienda decenas de miles de conexiones: el hilo se duerme en una
llamada que vigila todos y despierta solo cuando alguno está listo. Su equivalente en BSD y macOS es
`kqueue`.
🔬 Su predecesor, `select`, hacía lo mismo pero recorriendo la lista entera en cada llamada: `O(n)`
por llamada frente a `O(eventos)`. Y su limitación, que es el tema del capítulo: **no sirve para
archivos regulares**, que siempre se reportan listos.

**02 → 6. ¿Es Node asíncrono para leer archivos?**

⏱️ No de verdad: usa un pool de hilos de tamaño fijo. Para sockets sí lo es.
🗣️ Medido con ocho tareas que pasan por ese pool: 799 ms con `UV_THREADPOOL_SIZE=1` y 253 ms con 8. Si
fuera asincronía del sistema operativo, el tamaño del pool no cambiaría nada.
🔬 Por ahí pasan `fs`, `crypto`, `zlib` y `dns.lookup`; los sockets van por `epoll`/`kqueue`. La
consecuencia operativa es que **cuatro operaciones de archivo lentas bloquean también las de
`crypto`**, porque comparten pool — y eso no aparece en ningún perfilador de JavaScript, porque el
trabajo ocurre fuera del bucle de eventos.

**02 → 7. ¿Qué devuelve `read` cuando el otro extremo de un socket cierra?**

⏱️ Cero.
🗣️ Y ahí está la ambigüedad del paradigma: en un archivo regular, cero significa fin de archivo; en un
socket significa que el otro lado cerró su mitad. El valor es el mismo y el suceso no.
🔬 Los otros dos casos completan la tabla: `n > 0` puede ser **menos de lo que pediste** —lectura
parcial, normal en sockets—, y `-1` con `EAGAIN` significa "no hay datos ahora mismo" en un descriptor
no bloqueante, cosa que no ocurre con archivos regulares.

**02 → 8. ¿Sigue Windows este modelo?**

⏱️ No. Usa `HANDLE` en vez de descriptores enteros y un modelo de entrada y salida asíncrona distinto,
basado en puertos de terminación.
🗣️ No es "Unix con otros nombres": es otro diseño, con `ReadFile`/`WriteFile` y solicitudes que se
completan y notifican, en vez de descriptores que se consultan.
🔬 Y eso explica la forma de las bibliotecas que tienes delante: el NIO de Java y `libuv` de Node
existen en buena parte para tapar esa diferencia, y sus abstracciones tienen esquinas raras porque
intentan cubrir dos modelos que no se parecen.

**02 → 9. ¿Qué se unifica realmente: la interfaz o el comportamiento?**

⏱️ La interfaz. El comportamiento no.
🗣️ Las cuatro llamadas existen para todos los tipos y su firma es idéntica; lo que hacen cambia. `read`
devuelve cosas distintas, `lseek` no vale para todos, y el modo no bloqueante solo tiene sentido para
algunos.
🔬 Esa distinción es la tesis del capítulo: **usar el paradigma para pensar es correcto; usarlo para
predecir el comportamiento produce la mitad de los errores del bloque**. La pregunta útil ante
cualquier operación no es "¿es un archivo?" sino "¿puede no estar lista, y qué hace mi hilo mientras
tanto?".

**02 → 10. ¿Por qué un archivo regular "siempre está listo" para `select`?**

⏱️ Porque los datos están en el disco: no hay nada que esperar a que llegue.
🗣️ `select` responde a la pregunta "¿hay datos disponibles?", y para un archivo la respuesta es
siempre sí. Con un socket tiene sentido porque los datos pueden no haber llegado todavía por la red.
🔬 Por eso registrar un archivo en un selector sería inútil: devolvería siempre listo y no ahorraría
nada. Linux lo permite formalmente y no sirve de nada; Java directamente lo impide en el sistema de
tipos.

**02 → 11. ¿Por qué eso no significa que leerlo sea instantáneo?**

⏱️ Porque "listo" significa que no hay que esperar a la red, no que el dato esté en memoria.
🗣️ Si el bloque no está en la caché de página, hay que ir al disco, y eso son milisegundos durante los
cuales **el hilo está bloqueado** — sin que ningún mecanismo de notificación pueda avisarte antes.
🔬 Ahí está la contradicción que justifica el capítulo: el archivo siempre está "listo" y sin embargo
leerlo puede bloquear. Es justo el hueco que ni `select` ni `epoll` cubren, y la razón de que
existan `io_uring` y los pools de hilos que lo emulan.

**02 → 12. ¿Qué es una lectura parcial y dónde ocurre?**

⏱️ Que `read` devuelva menos bytes de los que pediste. Ocurre en sockets y tuberías, casi nunca en
archivos regulares.
🗣️ Pides 1 024 y te da 3, porque eso es lo que ha llegado por la red hasta ese instante. Todo código
que lea de un socket necesita un bucle que acumule hasta tener lo que espera.
🔬 Y por eso es un error que solo se ve en producción: el mismo código sobre un archivo local funciona
a la primera, y con mensajes cortos en una red local también. Aparece con mensajes grandes, con
latencia o con un proveedor lento — exactamente cuando peor viene.

**02 → 13. ¿Por qué `lseek` no funciona sobre un socket?**

⏱️ Porque un socket no tiene posición: es un flujo que avanza y no se puede rebobinar.
🗣️ En un archivo regular hay un desplazamiento dentro de un contenido que existe entero; en un socket
los bytes se consumen a medida que llegan y lo leído ya no está.
🔬 La consecuencia práctica está en el bloque `07`: los parsers de flujo no pueden dar marcha atrás, y
por eso un parser que necesite mirar hacia adelante tiene que **guardar él mismo** lo que pueda
necesitar. Es también la razón de que no se pueda "empezar a leer por la mitad" de una respuesta HTTP.

**02 → 14. ¿Qué operaciones de Node pasan por el pool de hilos?**

⏱️ `fs`, `crypto`, `zlib` y `dns.lookup`. Los sockets no.
🗣️ Es la lista que hay que saber, porque explica latencias inexplicables: una operación de compresión
pesada compite con las lecturas de archivo por los mismos cuatro hilos.
🔬 `dns.lookup` es el caso más traicionero, porque no parece entrada y salida de archivo y sí pasa por
el pool — usa el resolutor del sistema, que es bloqueante. `dns.resolve`, en cambio, va por la red y
no lo usa. Un servicio con muchas resoluciones de nombre puede agotar el pool sin tocar un archivo.

**02 → 15. ¿Cuántos hilos tiene ese pool por defecto?**

⏱️ Cuatro.
🗣️ Se ajusta con la variable de entorno `UV_THREADPOOL_SIZE`, y el efecto es medible: las mismas ocho
tareas pasan de 799 ms con uno a 253 ms con ocho.
🔬 Subirlo no siempre ayuda: si las tareas son de CPU —`crypto`, `zlib`—, más hilos que núcleos solo
añade cambios de contexto. Si son de disco, puede ayudar hasta donde el dispositivo dé. La respuesta
completa es "mide, y no lo subas por encima del número de núcleos si el trabajo es de CPU".

**02 → 16. ¿Qué tres cosas sí predice bien el paradigma?**

⏱️ Que todo compite por el mismo límite de descriptores, que todo se envuelve con la misma abstracción
de flujo, y que todo paga el mismo peaje de búferes.
🗣️ Las tres son consecuencias reales de la unificación, y las tres son capítulos de este bloque: el
`01`, la familia `InputStream`/`io.Reader`/`Readable`, y el `04`.
🔬 Que los cuatro lenguajes hayan convergido en la misma abstracción de flujo es la mejor prueba de
que la idea era buena: nadie se coordinó, y todos acabaron con un objeto que sabe leer bytes de algo
sin saber de qué.

**02 → 17. ¿Por qué existe `io_uring` si ya estaba `epoll`?**

⏱️ Porque `epoll` no sirve para archivos regulares, y hasta `io_uring` no había forma de hacer entrada
y salida de archivos realmente asíncrona en Linux.
🗣️ Lo que faltaba era poder decir "empieza esta lectura y avísame cuando esté", en lugar de "avísame
cuando haya datos" —que para un archivo es siempre—. Antes, la única manera era delegar a un pool de
hilos, que es lo que hacen Node y las APIs asíncronas de archivo de Java.
🔬 `io_uring` añade además algo que `epoll` no tenía: **colas compartidas entre el proceso y el
núcleo**, de modo que se pueden encolar muchas operaciones con muy pocas llamadas al sistema — lo que
ataca directamente el coste del capítulo `04`. El precio es complejidad, una superficie de seguridad
que ha dado varios problemas, y que solo existe en Linux reciente.

**02 → 18. Un servicio Node tiene latencia alta y el perfilador no encuentra nada. Da la hipótesis y cómo la confirmas.**

⏱️ El tiempo se va en el pool de `libuv`, que el perfilador de JavaScript no ve porque está fuera del
bucle de eventos.
🗣️ Encaja con el síntoma: el perfilador muestra el hilo principal ocioso, la CPU baja y la latencia
alta. El trabajo está ocurriendo en cuatro hilos nativos que ninguna herramienta de JavaScript
instrumenta.
🔬 Cómo se confirma, en orden: **(1)** subir `UV_THREADPOOL_SIZE` y ver si la latencia baja — si baja,
está confirmado y además ya tienes una mitigación; **(2)** contar operaciones de `fs`, `crypto`,
`zlib` y `dns.lookup` por petición, que es donde está la causa; **(3)** mirar si hay `dns.lookup`
escondido en llamadas HTTP salientes, que es el caso que nadie sospecha. La corrección de fondo no es
subir el pool sino **reducir el trabajo que pasa por él**: cachear resoluciones, mover la compresión
al borde, o leer los archivos una vez al arrancar.

**02 → 19. ¿Por qué el compilador de Java es una prueba más fuerte que una comprobación en ejecución?**

⏱️ Porque demuestra que la imposibilidad está en el diseño del tipo, no en una condición que se evalúa
en un caso concreto.
🗣️ Una comprobación en ejecución podría depender del sistema operativo, de la versión o del archivo
concreto. Que `configureBlocking` **no exista** en `FileChannel` significa que los diseñadores de la
API decidieron que esa operación no tiene sentido para esa clase, y ningún caso lo cambia.
🔬 Es también un buen ejemplo de un principio general: **hacer imposible de expresar lo que es
imposible de hacer**. `FileChannel` no extiende `SelectableChannel`, y así el error se descubre al
compilar y no a las tres de la mañana. El mismo principio aparece en el bloque `06` con los tipos de
dinero y de fecha.

**02 → 20. ¿Qué código funciona con archivos y falla con sockets, y por qué solo se ve en producción?**

⏱️ Un `read` sin bucle: con archivos devuelve todo lo pedido, con sockets puede devolver menos.
🗣️ El patrón exacto es leer una vez en un búfer y asumir que ahí está el mensaje entero. Funciona con
archivos locales siempre, y con sockets funciona mientras el mensaje quepa en un solo segmento y
llegue de golpe.
🔬 Por qué solo se ve en producción: en desarrollo la red es local, los mensajes son pequeños y llegan
en un paquete. En producción aparecen mensajes grandes, latencia, fragmentación y proveedores lentos,
y entonces el `read` devuelve la mitad. **El síntoma es un error de parseo, no un error de red**, y
por eso la investigación empieza en el sitio equivocado. Los dos hermanos del mismo error: no tratar
el cero como cierre del otro extremo, y no tratar `EAGAIN` en un descriptor no bloqueante.

**02 → 21. ¿Qué implica para el diseño que archivos y sockets compartan el límite de descriptores?**

⏱️ Que el presupuesto de descriptores hay que repartirlo entre todo, y que un pico en una familia
puede impedir operaciones de la otra.
🗣️ Un servicio que acepta 10 000 conexiones, mantiene un pool de 100 a la base de datos y abre
archivos de plantilla necesita margen para las tres cosas a la vez. Y el fallo será el mismo error
para todas.
🔬 Las implicaciones concretas: **dimensionar sumando** —entrantes, salientes, pool, archivos, margen—;
**no abrir archivos por petición** si se puede evitar, porque compiten con las conexiones que dan
ingresos; y **aislar**, cuando se pueda, poniendo en procesos distintos las cargas que consumen
descriptores de forma muy distinta. Es el mismo razonamiento del mamparo del capítulo `03`, aplicado
a un recurso del sistema operativo en vez de a un pool de hilos.

**02 → 22. ¿Por qué el NIO de Java y `libuv` tienen abstracciones con esquinas raras?**

⏱️ Porque intentan cubrir dos modelos de entrada y salida que no se parecen: el de Unix y el de
Windows.
🗣️ Unix ofrece "avísame cuando haya datos" y Windows "empieza esto y avísame cuando termine". Una
biblioteca portable tiene que exponer algo que se pueda implementar sobre ambos, y el resultado no
encaja del todo con ninguno.
🔬 Los síntomas concretos: en Java conviven `FileChannel`, `AsynchronousFileChannel` y los selectores,
con capacidades distintas y solapamientos raros; en `libuv`, la asincronía de archivos se emula con
hilos en Unix mientras que en Windows se apoya en el mecanismo nativo, y por eso **el mismo código
tiene características de rendimiento distintas según el sistema**. Saber esto ahorra mucho tiempo
cuando algo va bien en el portátil y mal en el servidor, o al revés.

**02 → 23. Te preguntan si conviene subir `UV_THREADPOOL_SIZE`. ¿Qué contestas?**

⏱️ Que depende de qué pasa por el pool, y que antes de subirlo hay que medir qué lo está llenando.
🗣️ Si el trabajo es de CPU —`crypto`, `zlib`—, subirlo por encima del número de núcleos solo añade
cambios de contexto. Si es de disco o de resolución de nombres, subirlo puede ayudar hasta donde el
dispositivo o la red den.
🔬 La respuesta completa lo trata como una **mitigación, no una corrección**: sirve para comprobar la
hipótesis y para aguantar mientras se arregla lo de fondo, que casi siempre es reducir el trabajo que
pasa por el pool —cachear resoluciones de nombre, no leer el mismo archivo en cada petición, mover la
compresión a un proceso aparte o al borde—. Y conviene mencionar el efecto secundario: el pool es
global al proceso, así que subirlo afecta a todo, incluidas bibliotecas de terceros que no sabías que
lo usaban.

**02 → 24. ¿Qué preguntarías ante cualquier operación de entrada y salida para decidir su modelo?**

⏱️ "¿Esta operación puede no estar lista, y qué hace mi hilo mientras tanto?"
🗣️ Esa pregunta cubre todo el bloque: si no puede esperar, da igual el modelo; si puede, hay tres
respuestas posibles —el hilo se para, gira en vano o atiende otra cosa— y solo la tercera escala.
🔬 Las dos preguntas de apoyo que la completan: **"¿cuántas de estas voy a tener a la vez?"**, que
decide si hilo por conexión basta o hace falta multiplexar; y **"¿esto es espera o es cálculo?"**,
porque acotar un pool es correcto para lo segundo y desastroso para lo primero.

**02 → 25. Un compañero afirma que Node no tiene hilos. ¿Cómo lo corriges sin discutir?**

⏱️ Enseñándole el conteo: el proceso tiene ocho hilos, medidos, no uno.
🗣️ La forma que no genera discusión es no contradecir la parte que es verdad: **el código JavaScript
del usuario sí corre en un solo hilo**, y esa simplificación es útil. Lo que no es cierto es que el
proceso sea de un solo hilo, porque debajo está el pool de `libuv`.
🔬 La demostración es de treinta segundos: arrancar el servicio y contar hilos con `ps -M` o el monitor
de actividad; y si hace falta más, la medida de `UV_THREADPOOL_SIZE` de la pregunta 25. El matiz que
conviene añadir para que la corrección sea útil y no un "te equivocas": **importa porque explica
latencias reales**, no porque sea un detalle trivial. Y desde Node 12 existen además los
`worker_threads`, con lo que "un solo hilo" ya no describe ni siquiera el JavaScript del usuario.

**02 → 26. Explica en dos minutos, a alguien que solo ha programado con frameworks, por qué su servicio se queda sin hilos.**

⏱️ Porque cada petición ocupa un hilo mientras espera respuestas de otros, y esperar no consume CPU
pero sí ocupa el sitio.
🗣️ La analogía que funciona: el servicio tiene N cajeros. Cada cliente que llega ocupa un cajero, y si
el cajero tiene que llamar por teléfono al banco central y esperar cinco minutos, **ese cajero está
ocupado sin hacer nada**. Con diez cajeros y llamadas de cinco minutos, el undécimo cliente espera —
aunque los diez cajeros estén de brazos cruzados.
🔬 El cierre que convierte la analogía en decisión: **el problema no se arregla contratando más
cajeros** —más hilos cuestan memoria y planificación, y el techo llega igual—; se arregla haciendo
que el cajero atienda a otro cliente mientras espera el teléfono, que es lo que hacen los hilos
virtuales, las goroutines y el bucle de eventos. Y con un número: 2 000 conexiones necesitaron 2 014
hilos del sistema en un modelo y 35 en el otro, con la misma latencia.

**02 → 27. Diseña una prueba que demuestre, en tu lenguaje, que la entrada y salida de archivos no es realmente asíncrona.**

⏱️ Lanzar N operaciones concurrentes y comprobar que el tiempo total depende del tamaño del pool de
hilos, no solo de N.
🗣️ El diseño, para Node:

```text
1. N tareas que pasen por el pool (fs o crypto), lanzadas a la vez
2. medir el total con UV_THREADPOOL_SIZE = 1, 2, 4 y 8
3. si el total baja al subir el pool, hay un pool detrás: no es asincronía del sistema
```
🔬 Medido así: 799, 449, 332 y 253 ms para ocho tareas. La comparación que cierra el argumento es
**hacer lo mismo con sockets**, donde el tamaño del pool no cambia nada — así se demuestra que la
diferencia es de la familia de operaciones y no del banco de pruebas. En Java la prueba equivalente
es comparar `AsynchronousFileChannel` con `AsynchronousSocketChannel` mirando cuántos hilos crea el
proceso, y la trampa a evitar en ambos casos es que el disco esté en caché: hay que usar archivos
grandes o forzar la lectura real, o estarás midiendo memoria.

**02 → 28. Tu equipo quiere migrar un servicio con mucha entrada y salida de archivos de Node a Go. Argumenta a favor y en contra con lo de este capítulo.**

⏱️ A favor: Go no tiene el cuello del pool fijo. En contra: la entrada y salida de archivos tampoco es
asíncrona en Go, y el coste de la migración rara vez se paga solo con eso.
🗣️ **A favor.** En Node, `fs` comparte cuatro hilos con `crypto`, `zlib` y `dns.lookup`, y saturarlos
degrada cosas que no tienen relación entre sí. En Go, cada goroutine que hace una lectura bloqueante
ocupa un hilo del sistema **mientras dura**, pero el runtime crea más si hacen falta: no hay un techo
fijo de cuatro, y el planificador lo gestiona.
🔬 **En contra, y es lo que hay que decir para que el argumento sea honesto.** Primero: **la lectura de
archivos en Go tampoco es asíncrona** — el `netpoller` cubre sockets, no archivos regulares, así que
la ventaja es de flexibilidad del pool y no de modelo. Segundo: el cuello de botella puede no estar
ahí, y hay que medirlo antes —si el servicio pasa el tiempo en `zlib`, el problema es de CPU y
cambiar de lenguaje no lo arregla—. Tercero: el coste real de la migración es de equipo, bibliotecas
y operación, no de rendimiento. **La propuesta alternativa** que suele ganar: subir el pool como
mitigación, sacar la compresión y la criptografía del camino crítico, cachear lo que se lee en cada
petición, y decidir la migración con datos después de eso.

**02 → 29. Escribe la explicación de `io_uring` para un comité técnico que ya conoce `epoll`: qué problema resuelve, qué cuesta y cuándo lo adoptarías.**

⏱️ Resuelve la entrada y salida asíncrona de archivos y el coste de las llamadas al sistema; cuesta
complejidad y portabilidad; se adopta cuando la medida dice que ese es el cuello.
🗣️ La explicación:

```text
PROBLEMA 1  epoll responde "¿hay datos?", que para un archivo regular es siempre sí.
            No existía forma de hacer IO de archivos realmente asíncrona: se emulaba con hilos.
PROBLEMA 2  cada operación cuesta una llamada al sistema, y con millones de operaciones
            ese peaje domina (capítulo 04).
SOLUCIÓN    dos colas compartidas entre proceso y núcleo: se encolan operaciones y se recogen
            resultados, con muy pocas llamadas —o ninguna, en modo sondeo.
```
🔬 Qué cuesta, que es la parte que un comité necesita: **solo Linux, y reciente**, así que hay que
mantener un camino alternativo; **complejidad real** en el código y en la depuración; **superficie de
seguridad** —ha acumulado vulnerabilidades y hay organizaciones que lo desactivan por política—; y
**madurez desigual** entre bibliotecas. Cuándo lo adoptaría: cuando un perfil demuestre que el cuello
son las llamadas al sistema o el pool de hilos de archivos, cuando el volumen justifique el esfuerzo
—bases de datos, servidores de almacenamiento, proxies de alto rendimiento—, y **a través de una
biblioteca que lo encapsule**, no llamándolo directamente. Para un servicio de negocio normal, la
respuesta honesta es que no es el cuello y no compensa.

**02 → 30. Te dan un servicio que lee miles de archivos pequeños y va lento. Enumera las cinco causas posibles a la luz de este capítulo, en orden.**

⏱️ Sin búfer, demasiadas llamadas por archivo, el pool de hilos saturado, `stat` innecesarios y el
disco.
🗣️ Las cinco, en orden de probabilidad:

```text
1. SIN BÚFER o con búfer minúsculo         → capítulo 04: factor de hasta once mil
2. VARIAS LLAMADAS POR ARCHIVO             → abrir, stat, leer, cerrar: miles de archivos × 4
3. POOL DE HILOS SATURADO (Node) o pocos   → la asincronía de archivos es un pool fijo
4. METADATOS QUE NO SE USAN                → stat por entrada multiplica por cinco (capítulo 05)
5. EL DISPOSITIVO                          → si es de red, cada operación paga latencia de red
```
🔬 El orden importa porque las tres primeras son de código y las dos últimas de entorno, y hay que
descartar las baratas antes. El quinto punto merece un matiz: **con un sistema de archivos en red, la
aritmética cambia por completo** — cada operación cuesta milisegundos en vez de microsegundos, y
entonces reducir el **número de operaciones** pasa a ser lo único que importa, lo que puede llevar a
un rediseño: empaquetar los miles de archivos pequeños en uno grande, que es exactamente lo que hacen
los formatos de archivo empaquetado y los sistemas de datos columnares.

---

# 03 — Bloqueante, no bloqueante y asíncrono

**03 → 1. ¿Qué significa que una llamada sea bloqueante?**

⏱️ Que el hilo se detiene dentro de la llamada hasta que la operación puede completarse.
🗣️ Un `read` bloqueante sobre un socket sin datos deja el hilo dormido: no consume CPU, pero **ocupa
el sitio**. Ese matiz —no gasta procesador y sí ocupa un hilo— es todo el problema de escalado.
🔬 El sistema operativo saca al hilo de la cola de ejecución y lo despierta cuando hay datos, así que
el coste no es de CPU sino de **inventario**: cuántos hilos tienes y cuántos están esperando.

**03 → 2. ¿Qué significa que sea no bloqueante?**

⏱️ Que la llamada vuelve inmediatamente, con datos o con un "ahora no hay".
🗣️ En Unix ese "ahora no hay" es `-1` con `EAGAIN`. El hilo sigue vivo y puede hacer otra cosa, que es
el punto.
🔬 Y el error de concepto que hay que evitar: **no bloqueante no es asíncrono**. Si te limitas a
reintentar en bucle, no bloqueas pero giras en vano quemando CPU. Lo que hace útil al modelo es
combinarlo con notificación —`epoll`, `kqueue`—, que es la pregunta 11.

**03 → 3. ¿Qué es un bucle de eventos?**

⏱️ Un hilo que espera en una sola llamada que vigila muchos descriptores, y despacha el trabajo del
que despierte.
🗣️ El esqueleto es de cuatro líneas: esperar en `epoll`, recoger los descriptores listos, ejecutar el
manejador de cada uno, volver a esperar. Eso es Node, `asyncio`, nginx y Redis.
🔬 Su límite es la otra cara de su virtud: como hay **un solo hilo ejecutando manejadores**, cualquier
cosa que tarde dentro de un manejador para a todos los demás clientes. Por eso el bucle de eventos es
excelente para esperar y pésimo para calcular.

**03 → 4. ¿Qué es un hilo virtual?**

⏱️ Un hilo gestionado por la máquina virtual de Java, no por el sistema operativo, que se multiplexa
sobre unos pocos hilos portadores.
🗣️ Se programa igual que un hilo normal —código bloqueante, lineal, depurable— y cuando hace una
operación que bloquearía, la máquina virtual lo aparca y usa el hilo portador para otro. Está en Java
21, por JEP 444.
🔬 Medido: 2 000 conexiones atendidas con **35 hilos del sistema** frente a 2 014 con hilos de
plataforma, con la misma latencia y cuatro veces menos memoria. Lo que cambia no es la velocidad: es
cuántos caben.

**03 → 5. ¿Qué es una goroutine?**

⏱️ La unidad de concurrencia de Go: una función que el runtime multiplexa sobre hilos del sistema.
🗣️ Empieza con una pila de unos pocos kilobytes que crece según haga falta, frente al mega de un hilo
del sistema. Y cuando hace entrada y salida de red, el `netpoller` la aparca y libera el hilo.
🔬 Es la misma idea que los hilos virtuales de Java, veinticinco años antes. Medido: 2 000 conexiones
con **12 hilos del sistema y 14 MB**, el más barato de los medidos.

**03 → 6. ¿Cuántos hilos usa `asyncio`?**

⏱️ Uno.
🗣️ Todas las corrutinas se ejecutan en el mismo hilo, turnándose en los puntos de `await`. Paraleliza
**espera**, no cálculo.
🔬 Por eso `asyncio` no aprovecha varios núcleos y por eso un `time.sleep` o una consulta bloqueante
dentro de una corrutina para el bucle entero. Para cálculo hace falta `run_in_executor` o varios
procesos. Medido: 2 000 conexiones con un hilo y 34 MB.

**03 → 7. ¿Qué modelo usa Node?**

⏱️ Bucle de eventos para la red, más un pool de hilos de `libuv` para archivos, criptografía,
compresión y resolución de nombres.
🗣️ El JavaScript del usuario corre en un solo hilo; el proceso, no. Medidos: ocho hilos.
🔬 Es la combinación que explica sus dos comportamientos: escala estupendamente con conexiones y se
atasca con cuatro operaciones de archivo lentas simultáneas, porque esas comparten un pool fijo.

**03 → 8. ¿Cuánto ocupa la pila de un hilo del sistema operativo?**

⏱️ Del orden de un megabyte de espacio de direcciones reservado, aunque solo se toque una parte.
🗣️ Es espacio virtual, no memoria física comprometida, así que dos mil hilos no son dos gigas
residentes. Pero sí son dos mil entradas para el planificador y dos mil pilas que mantener.
🔬 Medido en el caso real: 2 000 conexiones con hilos de plataforma dieron **240 MB residentes**
frente a 64 MB con hilos virtuales. El coste se nota, y donde más se nota es en el planificador
cuando los hilos se despiertan a la vez.

**03 → 9. ¿Por qué "no bloqueante" y "asíncrono" no son sinónimos?**

⏱️ Porque describen dos ejes distintos: si la llamada espera, y quién avisa del resultado.
🗣️ Se puede ser no bloqueante y síncrono —un bucle que reintenta con `EAGAIN`— y se puede ser
bloqueante en una espera que cubre muchas operaciones, como el propio `epoll`.
🔬 Cruzando los dos ejes salen cuatro combinaciones y las cuatro existen. La útil es **no bloqueante
más notificación asíncrona**, que es lo que hacen todos los servidores modernos; la inútil es no
bloqueante y síncrona, que es la siguiente pregunta.

**03 → 10. ¿Cuál de las cuatro combinaciones es la peor y por qué?**

⏱️ No bloqueante y síncrona: el sondeo activo. Quema CPU sin hacer nada.
🗣️ El hilo pregunta "¿hay datos?" una y otra vez y recibe `EAGAIN`. No bloquea, así que parece
eficiente, y en realidad gasta un núcleo entero para no avanzar.
🔬 Es la combinación a la que se llega por accidente: alguien pone los descriptores en modo no
bloqueante para "no bloquear" y no añade el mecanismo de notificación. El síntoma es CPU al 100 % con
el servicio ocioso, y es fácil de reconocer una vez sabes que existe.

**03 → 11. ¿Qué hace `epoll` que no hace un bucle de sondeo?**

⏱️ Duerme el hilo hasta que **alguno** de los descriptores tenga datos, en lugar de preguntar por cada
uno.
🗣️ Una sola llamada vigila decenas de miles de descriptores, el hilo no consume CPU mientras espera y
despierta con la lista de los que están listos.
🔬 La diferencia con su predecesor `select` es de complejidad: `select` recorre la lista entera en cada
llamada, `O(n)`, mientras que `epoll` mantiene el registro en el núcleo y devuelve solo los eventos,
`O(eventos)`. Con diez mil conexiones de las que cien están activas, la diferencia es de dos órdenes
de magnitud.

**03 → 12. ¿Hasta dónde escala hilo por conexión?**

⏱️ Hasta unos cientos de conexiones concurrentes, sin problema.
🗣️ Y ahí no hay nada que justificar: el código es lineal, la depuración es normal y las trazas se
leen. Es la opción más simple y muchas veces la correcta.
🔬 Medido: 2 000 conexiones con hilos de plataforma **funcionaron**, con 490 ms y 2 014 hilos. El
límite no es una pared sino una degradación: memoria, planificación y, antes o después, el límite de
hilos del sistema. La afirmación honesta no es "no escala" sino "escala hasta cientos, y a partir de
miles paga un coste que otros modelos no pagan".

**03 → 13. ¿Por qué Python con hilos tarda doce veces más que con `asyncio`?**

⏱️ Por el bloqueo global del intérprete más el coste de cambiar de contexto entre casi dos mil hilos.
🗣️ Medido: 4 458 ms con hilos frente a 377 ms con `asyncio`, con 1 780 hilos del sistema creados. No
es un problema de descriptores: es de planificación y de contención.
🔬 El bloqueo global permite que solo un hilo ejecute bytecode a la vez, así que los hilos se turnan
para el trabajo de Python aunque la espera sí sea concurrente. Con muchos hilos, el propio turnado
domina. Es el argumento más claro a favor de `asyncio` en Python para cargas de entrada y salida — y
conviene añadir que en versiones recientes existe un modo experimental sin bloqueo global, que cambia
este cálculo.

**03 → 14. ¿Qué es el color de las funciones y qué lenguajes lo sufren?**

⏱️ Que una función `async` solo se pueda llamar desde otra `async`, tiñendo toda la pila de llamadas.
Lo sufren JavaScript, TypeScript y Python.
🗣️ La consecuencia práctica es la duplicación: bibliotecas en versión síncrona y asíncrona, y la
imposibilidad de usar código bloqueante existente sin envolverlo.
🔬 Go y Java 21 **no lo tienen**, y esa es su ventaja más subestimada: el código se escribe igual y las
bibliotecas existentes siguen valiendo. Es lo que hace que migrar a hilos virtuales sea barato y
migrar a reactivo sea caro — en reactivo hay que reescribir toda la cadena.

**03 → 15. ¿Qué tienen en común Go y Java 21 frente a Node?**

⏱️ Que el código se escribe como si fuera bloqueante y el runtime lo convierte en no bloqueante.
🗣️ En los dos, una operación que bloquearía aparca la goroutine o el hilo virtual y libera el hilo
portador. No hay `async`, no hay color de funciones y no hay que reescribir bibliotecas.
🔬 Node hace lo contrario: expone la asincronía al programador con `async`/`await`. Es más explícito y
permite ver dónde hay puntos de suspensión, a cambio del color de funciones. Los dos enfoques
funcionan; la diferencia se nota al migrar código existente, donde el de Go y Java gana.

**03 → 16. ¿Qué pasa si haces un cálculo de 200 ms dentro de un manejador de Node?**

⏱️ Que el servidor entero deja de atender a todos durante esos 200 ms.
🗣️ Hay un solo hilo ejecutando manejadores: mientras el tuyo calcula, ningún otro evento se procesa.
Con diez peticiones por segundo así, el servicio está parado dos segundos de cada diez.
🔬 Las salidas: mover el cálculo a un `worker_thread`, a un proceso aparte o a un servicio distinto; o
trocearlo para ceder el control periódicamente, que es frágil. El mismo problema existe en `asyncio`
de Python, y por eso su documentación insiste en no llamar a código bloqueante desde una corrutina.

**03 → 17. ¿Qué diferencia hay entre paralelizar espera y paralelizar cálculo?**

⏱️ La espera no consume CPU, así que se puede multiplexar en un solo hilo; el cálculo necesita núcleos
de verdad.
🗣️ Mil esperas simultáneas caben en un hilo con un bucle de eventos. Mil cálculos simultáneos
necesitan mil veces la CPU, y ningún modelo de concurrencia crea procesadores.
🔬 De ahí salen dos consecuencias que se preguntan: **`asyncio` y el bucle de eventos no aceleran el
cálculo** —para eso hacen falta procesos o `worker_threads`—, y **acotar un pool es correcto para
cálculo y desastroso para espera**, que es el capítulo entero. La pregunta que hay que hacerse antes
de elegir modelo es cuál de las dos domina, y se responde mirando la CPU.

**03 → 18. ¿Por qué un pool acotado serializa la espera?**

⏱️ Porque cada hilo del pool queda ocupado mientras espera, así que solo hay N esperas en curso y el
resto hace cola.
🗣️ La aritmética es directa: con 50 peticiones de 100 ms y un pool de 8, el total es `50/8 × 100 ms`.
Medido: **727 ms**, frente a 122 ms sin acotar.
🔬 El punto conceptual es que **acotar un pool protege un recurso escaso**, y el recurso escaso aquí no
es la CPU sino la espera — que no es escasa en absoluto. Acotar algo que no hace falta acotar
convierte capacidad disponible en cola.

**03 → 19. Un proveedor externo se vuelve lento y cae todo el servicio. Explica el mecanismo.**

⏱️ Los hilos del pool se quedan esperando a ese proveedor, y cuando están todos ocupados el servicio
deja de atender **todo**, no solo lo que toca a ese proveedor.
🗣️ Con un pool de N y una latencia que pasa de 100 ms a 5 s, la capacidad se divide por cincuenta. Las
peticiones que no tocan al proveedor lento tampoco encuentran hilo libre, así que el síntoma es una
caída general y la causa es un solo integrante.
🔬 Es el mismo fenómeno del mamparo, visto desde el recurso. Las tres defensas en orden de eficacia:
**timeouts agresivos** en toda llamada externa —sin ellos nada más funciona, porque un hilo sin
timeout espera para siempre—; **pools separados por dependencia**, para que el lento no se lleve a
los demás; y **no bloquear**, con hilos virtuales, goroutines o reactivo, que elimina la clase
entera. Un cortacircuitos ayuda, pero llega después: primero hay que dejar de agotar el pool.

**03 → 20. ¿Son más rápidos los hilos virtuales? Responde con precisión.**

⏱️ No. Con la misma concurrencia la latencia es prácticamente igual; lo que cambia es cuántos caben.
🗣️ Medido con 2 000 conexiones: 490 ms con hilos de plataforma y 419 ms con virtuales. La diferencia
real está al lado: 2 014 hilos del sistema frente a 35, y 240 MB frente a 64 MB.
🔬 De hecho, para **poca** concurrencia los hilos virtuales pueden ser ligeramente más lentos, porque
añaden una capa de aparcado y reanudación que un hilo del sistema no tiene. Su valor es de
**capacidad y coste**, no de velocidad, y decirlo así es lo que distingue a quien lo ha medido de
quien ha leído el anuncio.

**03 → 21. ¿Qué es la fijación de un hilo virtual y cómo se evita?**

⏱️ Que el hilo virtual quede atado a su hilo portador y no pueda aparcarse, anulando la ventaja. Se
evita sustituyendo `synchronized` por `ReentrantLock`.
🗣️ Ocurre cuando el hilo virtual se bloquea dentro de un bloque `synchronized` o en una llamada
nativa: la máquina virtual no puede desmontar la pila, así que el hilo portador se queda ocupado.
🔬 El efecto es sutil y desagradable: el servicio funciona, escala peor de lo esperado y no hay ningún
error. Se detecta con `jdk.VirtualThreadPinned` en el registro de eventos de la JVM. Conviene saber
que **las versiones más recientes han reducido mucho los casos de fijación por `synchronized`**, así
que la recomendación depende de la versión exacta — y por eso lo correcto es medir con el evento, no
suponer.

**03 → 22. ¿Cuándo elegirías hilo por conexión pudiendo usar hilos virtuales?**

⏱️ Cuando la concurrencia es de decenas o cientos y el equipo, las herramientas o la versión de Java
no acompañan.
🗣️ Con cien conexiones, los dos modelos dan lo mismo y el de plataforma tiene veinte años de
herramientas, trazas y experiencia detrás. Elegir lo conocido cuando la diferencia es nula es una
decisión correcta, no conservadurismo.
🔬 Los motivos concretos que lo justifican: una versión de Java anterior a la 21; bibliotecas con
código nativo o con mucho `synchronized`, que se fijarían; o un perfil de carga dominado por CPU,
donde multiplexar no aporta nada porque el cuello no es la espera. Lo que **no** es un motivo válido
es "siempre lo hemos hecho así", y saber distinguirlo es la mitad de la respuesta.

**03 → 23. ¿Por qué reactivo puede ser peor que bloqueante con poca concurrencia?**

⏱️ Porque paga complejidad y sobrecarga por un problema que no tiene, y a cambio pierde depuración y
trazas legibles.
🗣️ Con doscientos usuarios concurrentes, un modelo bloqueante usa doscientos hilos sin despeinarse.
Reactivo añade encadenamiento de operadores, contrapresión que gestionar, trazas de pila inútiles y
una curva de aprendizaje para todo el equipo.
🔬 Y hay un coste que se subestima: **un solo componente bloqueante dentro de una cadena reactiva
anula el modelo entero** y es dificilísimo de localizar. Reactivo se paga solo cuando hay mucha
concurrencia con poco trabajo por petición, o cuando se necesita composición de flujos con
contrapresión de verdad. En los demás casos, hilos virtuales dan casi el mismo resultado sin cambiar
cómo se escribe el código.

**03 → 24. ¿Qué mide realmente la tabla de 2 000 conexiones: latencia o coste?**

⏱️ Coste. Las latencias son todas parecidas; lo que varía en órdenes de magnitud son los hilos y la
memoria.
🗣️ 490 ms contra 419 ms no distingue nada. 2 014 hilos contra 35, y 240 MB contra 64 MB, sí.
🔬 Y ese es el error de lectura más común de este tipo de comparativas: **se mira la latencia, que en
una máquina ociosa es casi igual, y se concluye que da lo mismo**. El coste es lo que decide qué pasa
al multiplicar por diez la carga, o al meter el servicio en un contenedor con 256 MB. La pregunta
correcta ante una tabla así es "¿a partir de qué punto esto deja de funcionar?", y eso lo dicen las
columnas de recursos.

**03 → 25. Te dicen que suban el pool de 8 a 200 hilos para arreglar la latencia. ¿Qué contestas?**

⏱️ Que puede funcionar como parche si el cuello es espera, y que antes hay que saber si es espera o
cálculo.
🗣️ Si los hilos esperan red, subir el pool aumenta la concurrencia de espera y la latencia baja — es
exactamente la aritmética de `50/8 × 100 ms`. Si están calculando, doscientos hilos sobre ocho
núcleos solo añaden cambios de contexto y lo empeoran.
🔬 Cómo se decide en cinco minutos: mirar el uso de CPU. **CPU baja con latencia alta es espera**;
CPU saturada es cálculo. Y si es espera, la respuesta completa no se queda en subir el pool: propone
**timeouts** —sin ellos, doscientos hilos se agotarán igual, solo que más tarde—, **pools separados
por dependencia**, y evaluar hilos virtuales, que eliminan la pregunta. Subir a 200 sin timeouts es
cambiar un incidente por otro más lento.

**03 → 26. Diseña el servidor de un servicio que atiende 20 000 conexiones de larga duración con poco trabajo por conexión. Elige modelo y justifica el coste.**

⏱️ Bucle de eventos o hilos ligeros. Hilo por conexión queda descartado por el coste de 20 000 hilos.
🗣️ La justificación con números: 2 000 conexiones necesitaron 2 014 hilos de plataforma y 240 MB;
extrapolando, 20 000 serían del orden de 20 000 hilos y varios gigas solo en pilas, más un
planificador con veinte mil entradas. Con hilos virtuales fueron 35 hilos y 64 MB, y con goroutines
12 y 14 MB.
🔬 La elección concreta depende de dos cosas más. **Si el trabajo por conexión incluye algo de CPU**,
el bucle de eventos de un solo hilo es peligroso —un manejador lento para a todos— y ganan goroutines
o hilos virtuales, que usan varios núcleos. **Si las conexiones son de larga duración**, hay que
dimensionar el límite de descriptores para 20 000 más el margen del capítulo `01`, y ajustar los
parámetros del sistema. Y hay un coste que no es de modelo sino de memoria por conexión: con búferes
de 64 KB por conexión, 20 000 conexiones son 1,3 GB solo en búferes — así que el tamaño de búfer pasa
a ser una decisión de capacidad, no de rendimiento.

**03 → 27. Migras un servicio Java 17 con hilo por conexión a Java 21 con hilos virtuales. Enumera qué revisarías antes, qué medirías después y qué podría empeorar.**

⏱️ Antes: `synchronized` en caminos con espera, pools acotados y código nativo. Después: hilos, memoria
y fijación. Puede empeorar por fijación o por quitar un límite que protegía a otro.
🗣️ El plan:

```text
ANTES    · bloques synchronized que rodeen IO  → cambiar a ReentrantLock
         · pools acotados: dejan de tener sentido y ahora son el cuello
         · bibliotecas con JNI o ThreadLocal pesados
         · límites de conexiones aguas abajo (pool de BD, proveedor): SIGUEN existiendo
DESPUÉS  · hilos del SO, memoria residente, latencia p95/p99
         · evento jdk.VirtualThreadPinned en el registro de la JVM
```
🔬 Qué puede empeorar, que es la parte que se olvida. **(1) La fijación** deja el servicio como estaba
pero con más complejidad. **(2) `ThreadLocal`**: con millones de hilos virtuales, un `ThreadLocal`
grande se multiplica; existen los `ScopedValue` para eso. **(3) Y el más importante: el pool acotado
estaba limitando la carga aguas abajo sin que nadie lo hubiera decidido.** Al quitarlo, el servicio
deja pasar diez mil peticiones concurrentes a una base de datos que aguanta cien, y el cuello se
traslada — con el agravante de que ahora la cola está en el otro sistema y no en el tuyo. La
migración tiene que **reintroducir el límite donde toca**, con un semáforo explícito, y eso hay que
decidirlo antes de desplegar.

**03 → 28. Escribe el diagnóstico de un servicio que responde bien con 100 usuarios y da timeout con 300, con la CPU al 15 %.**

⏱️ CPU baja con latencia alta es espera: hay un pool acotado en algún punto y a 300 usuarios se agota.
🗣️ El razonamiento en voz alta: si fuera cálculo, la CPU estaría saturada. Con el 15 %, el sistema está
esperando, y el hecho de que el punto de ruptura sea nítido —bien a 100, mal a 300— apunta a un
**recurso con un número fijo**: un pool de hilos, un pool de conexiones a base de datos, un límite de
conexiones salientes.
🔬 El orden de comprobación: **(1)** el tamaño de todos los pools del camino —servidor de aplicación,
cliente HTTP, base de datos— y comparar con 300; **(2)** dónde se acumula la espera, con trazas
distribuidas o con un volcado de hilos: si cien hilos están todos en el mismo `socketRead`, ya está
localizado; **(3)** si hay timeouts configurados, porque sin ellos un proveedor lento retiene hilos
indefinidamente. La corrección depende de lo que aparezca, y el orden de preferencia es el de la
pregunta 18: timeouts primero, separación de pools después, y cambio de modelo si el patrón se repite.

**03 → 29. Tu equipo quiere reescribir en reactivo un servicio con 200 usuarios concurrentes. Escribe el argumento en contra y qué propondrías en su lugar.**

⏱️ Con 200 concurrentes no hay problema que resolver: reactivo añade complejidad, pierde depuración y
no gana nada medible. Propondría hilos virtuales o simplemente medir primero.
🗣️ El argumento: doscientos hilos de plataforma son doscientos megas de espacio de direcciones y un
planificador cómodo; el modelo bloqueante rinde igual. Reactivo cambia el estilo de todo el código,
hace inútiles las trazas de pila, exige que **toda** la cadena sea reactiva —un solo componente
bloqueante lo anula— y sube el listón de contratación y de mantenimiento.
🔬 Qué propondría, en orden: **(1) medir dónde se va el tiempo** — si es la base de datos, ningún
modelo de concurrencia lo arregla; **(2)** si de verdad hace falta más concurrencia, **hilos
virtuales**, que dan el mismo resultado sin tocar el estilo del código; **(3)** reservar reactivo para
donde paga de verdad: mucha concurrencia con poco trabajo por petición, o composición de flujos con
contrapresión real. Y una concesión honesta que hace el argumento defendible: **si el equipo ya
domina reactivo y el resto de la plataforma lo es**, la coherencia tiene valor propio y el cálculo
cambia.

**03 → 30. Diseña la prueba de carga que demuestra el techo de cada modelo, y di qué métricas recoges además de la latencia.**

⏱️ Escalones de concurrencia creciente contra el mismo servidor en cada modelo, midiendo recursos y no
solo tiempo.
🗣️ El diseño:

```text
CARGA      escalones: 50, 200, 1 000, 5 000, 20 000 conexiones simultáneas
SERVIDOR   el mismo trabajo simulado (espera fija) en cada modelo, misma máquina
MÉTRICAS   latencia p50/p95/p99 · hilos del SO · memoria residente · descriptores abiertos
           · CPU · errores y rechazos de conexión
PARADA     se sube hasta que aparecen errores, no hasta que la latencia "se ve mal"
```
🔬 Los tres detalles que hacen válida la prueba. **(1) El generador de carga no puede ser el cuello**:
con miles de conexiones hay que generarlas con un modelo asíncrono, no con un hilo por conexión, o
estarás midiendo el cliente. **(2) Los recursos importan más que la latencia**, por la pregunta 23:
el techo se ve en hilos y memoria mucho antes que en el reloj. **(3) Hay que registrar los errores**,
porque el punto interesante no es donde la latencia sube sino donde empiezan los rechazos, y una
prueba que solo mire promedios lo oculta. Y conviene medir **una línea base sin carga** para poder
restarla, como en las medidas de memoria del bloque `07`.

**03 → 31. Explica a un equipo de producto, sin jerga, por qué añadir más hilos no arregla la lentitud.**

⏱️ Porque los trabajadores no están cansados: están esperando el teléfono. Contratar más gente solo
llena la sala de gente esperando.
🗣️ La analogía completa: el servicio tiene diez cajeros. Cada cliente que llega ocupa uno, y el cajero
llama al banco central y espera. Si la llamada tarda cinco minutos, el cajero está bloqueado sin
hacer nada, y el cliente número once espera fuera aunque los diez estén de brazos cruzados. Añadir
cajeros ayuda un poco y cuesta dinero: cada uno necesita su mesa y su sitio.
🔬 El cierre que convierte la explicación en decisión, y que es lo que un equipo de producto necesita
oír: **hay dos arreglos de verdad y uno falso**. El falso es más cajeros. Los de verdad son **que la
llamada tarde menos** —arreglar o poner un límite al proveedor lento— y **que el cajero atienda a
otro cliente mientras espera**, que es un cambio técnico concreto con un coste concreto. Traducido a
plazos y riesgo, eso es una conversación que un equipo de producto puede tener; "necesitamos hilos
virtuales" no lo es.

---

# 04 — Búferes y el coste de la frontera

**04 → 1. ¿Qué es un búfer de entrada y salida?**

⏱️ Una zona de memoria intermedia que acumula bytes para hacer menos llamadas al sistema, más grandes.
🗣️ En lugar de pedir un byte tres millones de veces, se piden 64 KB cuarenta y seis veces. Los bytes
son los mismos; las llamadas, no.
🔬 Medido: leer 3 MB byte a byte tarda 1 879 ms y en bloques de 64 KB tarda 0,17 ms. El búfer no es una
optimización opcional: es la forma correcta de hacer entrada y salida.

**04 → 2. ¿Qué es una llamada al sistema?**

⏱️ Una petición de tu proceso al núcleo, que cruza la frontera de protección y vuelve.
🗣️ `read`, `write` y `open` son llamadas al sistema. Cada una implica un cambio de modo del procesador
y un coste fijo que **no depende de cuántos bytes pidas**.
🔬 De ahí la aritmética del capítulo: `coste ≈ llamadas × coste_por_llamada + bytes × coste_por_byte`.
Con búferes pequeños domina el primer término; con búferes razonables, desaparece.

**04 → 3. ¿Qué hace `flush`?**

⏱️ Vacía tu búfer de aplicación hacia el núcleo.
🗣️ Después de un `flush`, los datos ya no son tuyos: están en la caché de página del sistema. Si tu
proceso muere, sobreviven.
🔬 Lo que **no** hace es garantizar que estén en el disco. Para eso hace falta `fsync`, y confundir los
dos es la causa de la pérdida de datos que solo aparece cuando se cae la máquina entera.

**04 → 4. ¿Qué hace `fsync`?**

⏱️ Fuerza al núcleo a escribir en el dispositivo y espera confirmación.
🗣️ Es el único de los tres niveles que sobrevive a un corte de corriente. Y por eso cuesta: medido,
mil escrituras pasan de 0,6 ms a 30,8 ms — **cincuenta veces**.
🔬 En un disco mecánico la diferencia es de tres órdenes de magnitud, porque cada `fsync` espera a una
rotación física. Por eso las bases de datos lo agrupan en lugar de hacerlo por transacción, y por eso
hay que llamarlo solo cuando el dato es un compromiso con el exterior.

**04 → 5. ¿Lleva búfer `FileInputStream` de Java?**

⏱️ No. Hay que envolverlo en `BufferedInputStream`.
🗣️ Es el error clásico de Java, y produce exactamente el primer renglón de la tabla: cada `read()` de
un byte es una llamada al sistema.
🔬 La API moderna de `java.nio.file` sí devuelve flujos con búfer interno —`Files.newInputStream`—, lo
que es una razón para preferirla. Y lo mismo vale para la escritura: `FileOutputStream` sin
`BufferedOutputStream` es igual de lento.

**04 → 6. ¿Lleva búfer `open()` de Python?**

⏱️ Sí, de 8 KB por defecto.
🗣️ Es el lenguaje que mejor protege aquí: el error hay que cometerlo a propósito pasando
`buffering=0`, que es justamente lo que produjo la medida de 1 879 ms.
🔬 El parámetro acepta también un tamaño concreto, y en modo texto el búfer está en el envoltorio de
codificación, no en el archivo. `buffering=1` significa línea a línea, que es lo razonable para
salidas interactivas y lo peor para un archivo grande.

**04 → 7. ¿Qué es la contrapresión?**

⏱️ El mecanismo por el que un destino lento le dice a un origen rápido que pare.
🗣️ Sin ella, la diferencia de velocidad se acumula en un búfer intermedio que crece hasta agotar la
memoria. Es el problema clásico al copiar de disco a red.
🔬 Cada lenguaje la expresa distinto: en Node, `write` devuelve `false` y hay que esperar `drain`; en
Java con flujos clásicos, el propio bloqueo **es** la contrapresión; en Go, un canal sin búfer la
implementa por construcción.

**04 → 8. ¿Qué tamaño de búfer usan por defecto las bibliotecas y por qué ese?**

⏱️ Entre 4 KB y 8 KB, porque coincide con el tamaño de página del sistema y de bloque del sistema de
archivos.
🗣️ `BufferedInputStream` de Java usa 8 KB, `open` de Python 8 KB, `bufio` de Go 4 KB. No es
casualidad: es el punto donde la curva medida se dobla.
🔬 La medida lo confirma: 4 096 bytes da 0,59 ms y 512 da 4,12 ms — siete veces más. Subir de 8 KB a
64 KB todavía gana algo (0,17 ms), y a partir de ahí no.

**04 → 9. ¿Por qué leer byte a byte es tan lento si el algoritmo es `O(n)`?**

⏱️ Porque `O(n)` cuenta operaciones, y aquí cada operación es una llamada al sistema con un coste fijo
grande.
🗣️ Tres millones de cruces de frontera contra cuarenta y seis. La complejidad asintótica es la misma y
la constante vale un factor de once mil.
🔬 Es el mejor ejemplo del corpus de que **la notación asintótica esconde constantes que deciden**. El
mismo principio aparece en `01-fundamentos/01`: `O(n)` con una constante enorme pierde contra
`O(n log n)` con una constante pequeña en cualquier tamaño realista.

**04 → 10. ¿Por qué la curva se aplana a partir de 64 KB?**

⏱️ Porque ya no quedan llamadas al sistema que ahorrar: el término que dominaba ha desaparecido.
🗣️ Con 64 KB sobre 3 MB son cuarenta y seis llamadas. Doblar el búfer las deja en veintitrés, y
veintitrés llamadas menos no se notan frente al coste de copiar tres megas.
🔬 A partir de ahí el coste es todo del segundo término —bytes × coste por byte— que no depende del
tamaño del búfer. La curva medida lo enseña literalmente: 0,17 ms con 64 KB y 0,21 ms con 1 MB.

**04 → 11. ¿Por qué un búfer de 1 MB puede ser peor que uno de 64 KB?**

⏱️ Porque ya no ahorra llamadas y sí añade memoria que reservar, tocar y expulsar de la caché.
🗣️ Medido: 0,21 ms con 1 MB frente a 0,17 ms con 64 KB. La diferencia es pequeña en un caso y deja de
serlo cuando hay muchos flujos abiertos a la vez.
🔬 Ese es el argumento importante y no el del microsegundo: **con 20 000 conexiones, un búfer de 1 MB
por conexión son 20 GB**. El tamaño de búfer deja de ser una decisión de rendimiento y pasa a ser una
de capacidad, que es justo la conclusión del problema de 20 000 conexiones del capítulo `03`.

**04 → 12. Diferencia los tres niveles de "escrito".**

⏱️ Mi búfer de aplicación, la caché de página del núcleo, y el dispositivo.
🗣️ `write` mueve del primero al segundo si no hay búfer de aplicación, o se queda en el primero si lo
hay; `flush` garantiza el segundo; `fsync` garantiza el tercero.
🔬 La confusión habitual es creer que `write` sin error significa "guardado". No lo significa en
ninguno de los dos saltos: puede estar en tu propio búfer, y aunque llegue al núcleo, sigue sin estar
en el disco.

**04 → 13. ¿A qué fallo sobrevive cada uno de esos tres niveles?**

⏱️ El primero a nada, el segundo a que tu proceso muera, el tercero a un corte de corriente.
🗣️ Puesto como tabla, es la respuesta entera:

```text
en mi búfer          → se pierde si el proceso muere
en la caché del núcleo → sobrevive a que el proceso muera; se pierde si cae la máquina
en el dispositivo    → sobrevive al corte de luz
```
🔬 Y la pregunta de diseño que se deriva: **¿a cuál de los tres fallos necesito sobrevivir?** Para un
log de diagnóstico, al primero basta. Para un archivo de confirmaciones de pago, hace falta el
tercero — y con él, su coste de cincuenta veces.

**04 → 14. ¿Qué es `highWaterMark` en Node y qué controla además del tamaño?**

⏱️ El umbral del búfer interno de un flujo. Además del tamaño, controla **cuándo se activa la
contrapresión**.
🗣️ Cuando el búfer interno alcanza ese valor, `write` devuelve `false`: es la señal de que hay que
dejar de escribir y esperar el evento `drain`.
🔬 Ignorar ese valor de retorno es la causa habitual de que un servicio que copia flujos consuma
memoria hasta morir: sigue escribiendo y el búfer crece sin límite. Por eso `pipe()` y `pipeline()`
son preferibles a copiar a mano — implementan esa espera por ti.

**04 → 15. ¿Por qué en Java con flujos clásicos no se habla de contrapresión?**

⏱️ Porque `write` es bloqueante, y el bloqueo **es** la contrapresión.
🗣️ Si el destino es lento, el `write` del productor simplemente no vuelve hasta que hay sitio. El
productor se frena solo, sin mecanismo explícito y sin que nadie tenga que acordarse.
🔬 El concepto aparece en cuanto se pasa a reactivo, donde nada bloquea y por tanto hay que
reintroducir a mano la señal que antes daba el sistema operativo. Es un buen ejemplo de que las
abstracciones no eliminan problemas: los trasladan, y a veces de un sitio donde se resolvían solos a
otro donde hay que resolverlos.

**04 → 16. ¿Qué relación tiene un canal de Go sin búfer con la contrapresión?**

⏱️ Es contrapresión pura: el emisor se bloquea hasta que el receptor recibe.
🗣️ Un canal con búfer de tamaño N es una tolerancia de N elementos: absorbe ráfagas de ese tamaño y a
partir de ahí vuelve a frenar al emisor.
🔬 Y de ahí la conexión con el bloque `06`: **un canal sin límite no existe en Go a propósito**. Una
cola sin límite no es generosa, es una fuga de memoria con otro nombre; que el productor se bloquee
es la funcionalidad, no el fallo.

**04 → 17. ¿Por qué las bases de datos no hacen `fsync` por transacción?**

⏱️ Porque costaría cincuenta veces más, y agrupando consiguen casi la misma garantía a una fracción
del precio.
🗣️ Escriben en un registro de escritura anticipada y sincronizan **una vez por lote** de
transacciones. Las transacciones que entran en la misma ventana comparten el coste del `fsync`.
🔬 El compromiso explícito es que, en una ventana de unos milisegundos, un corte de corriente puede
perder las transacciones confirmadas más recientes — y por eso los motores permiten configurarlo:
sincronización por transacción cuando la durabilidad es innegociable, agrupada cuando se acepta esa
ventana. La discusión completa, con replicación de por medio, es de
`repaso-arquitectura-entrevistas`.

**04 → 18. ¿Cuándo es obligatorio `fsync` y cuándo es desperdicio?**

⏱️ Obligatorio cuando el dato es un compromiso con el exterior que no puedes reconstruir. Desperdicio
para todo lo regenerable.
🗣️ Obligatorio: confirmaciones de pago, órdenes aceptadas, registros de auditoría. Desperdicio:
archivos temporales, cachés, índices que se pueden reconstruir, logs de diagnóstico.
🔬 El criterio operativo es una pregunta: **si esto se pierde al cortarse la luz, ¿puedo regenerarlo o
he mentido a alguien?** Si he mentido a alguien —le dije que su pago estaba aceptado—, `fsync`. Y hay
un matiz que conviene saber: `fsync` del archivo no basta si el archivo es nuevo, porque la entrada
del directorio también tiene que estar en disco; hay que sincronizar también el directorio.

**04 → 19. ¿Por qué el error de no poner búfer no lo detectan las pruebas?**

⏱️ Porque con archivos pequeños la diferencia es de milisegundos y nadie la mira.
🗣️ Una prueba unitaria lee un archivo de dos kilobytes: con búfer tarda un microsegundo y sin búfer
tarda dos milisegundos. Las dos pasan, y ninguna assertion mira el tiempo.
🔬 El problema aparece en producción con archivos mil veces más grandes, y entonces el factor de mil se
nota. Es el mismo patrón que el resto del bloque: **los errores de entrada y salida escalan con el
tamaño y las pruebas usan datos pequeños**. La defensa es una prueba con volumen realista, o al menos
un análisis estático que marque los flujos sin envolver.

**04 → 20. ¿Qué tiene que ver la contrapresión con las colas acotadas del bloque `06`?**

⏱️ Es lo mismo visto desde la entrada y la salida: el límite de la cola es la señal que frena al
productor.
🗣️ En el bloque `06`, una `ArrayBlockingQueue` acotada bloquea al productor cuando se llena. Aquí, el
búfer de un flujo hace lo mismo cuando alcanza su umbral. En ambos casos, **el bloqueo es la
funcionalidad**.
🔬 Y la conclusión compartida es la misma: una cola sin límite no protege de nada, solo traslada el
fallo de "el productor espera" a "el proceso muere sin memoria" — que es mucho peor porque ocurre más
tarde y pierde todo lo acumulado. Elegir el tamaño del límite es elegir cuánta ráfaga toleras.

**04 → 21. Un servicio que copia de disco a red consume memoria hasta morir. Diagnostica.**

⏱️ Falta contrapresión: lee más rápido de lo que escribe y la diferencia se acumula en memoria.
🗣️ El patrón típico en Node es un bucle que llama a `write` e ignora el valor de retorno; en reactivo,
una fuente que emite sin respetar la demanda. El síntoma es memoria creciente proporcional al tráfico
y no al número de peticiones.
🔬 Cómo se confirma: si la memoria crece mientras hay transferencias grandes en curso y baja al
terminar, es acumulación en búferes, no una fuga clásica. La corrección: usar `pipeline()` en Node,
respetar la demanda en reactivo, o **usar el modelo bloqueante**, donde el problema no existe porque
`write` frena solo. Y la comprobación que evita futuros: una prueba con un destino artificialmente
lento, que es como se reproduce en segundos.

**04 → 22. ¿Por qué `pipeline()` es mejor que encadenar `pipe()` a mano?**

⏱️ Porque gestiona la contrapresión **y** la propagación de errores y el cierre de todos los flujos.
🗣️ Con `pipe()` encadenado, un error en un flujo intermedio no cierra los demás: quedan abiertos y
consumiendo descriptores y memoria. `pipeline()` cierra toda la cadena y llama a la devolución de
llamada con el error.
🔬 Es la diferencia entre "funciona en el camino feliz" y "funciona cuando algo falla", que es el tema
del capítulo `01`: el recurso hay que liberarlo **también** en la rama de error. Por eso la
recomendación oficial de Node es `pipeline` o su variante con promesas.

**04 → 23. Te piden subir el búfer de 8 KB a 1 MB "para ir más rápido". ¿Qué contestas?**

⏱️ Que de 8 KB a 64 KB puede ganar algo y de ahí a 1 MB no gana nada y puede costar memoria.
🗣️ Con la curva medida delante: 8 KB está pasada la rodilla, 64 KB es el mínimo de la curva y 1 MB ya
es peor. La ganancia entre 8 KB y 64 KB existe pero es pequeña comparada con la que hubo entre 512 B
y 4 KB.
🔬 Y la pregunta que hay que devolver antes de tocar nada: **¿cuántos de estos flujos hay abiertos a la
vez?** Si son unos pocos, da igual; si son miles, multiplicar por 128 el búfer es un problema de
capacidad. La respuesta completa termina diciendo dónde sí está la ganancia: casi siempre en reducir
el **número** de operaciones o en evitar leer lo mismo dos veces, no en el tamaño del búfer.

**04 → 24. ¿Cómo comprobarías, sin perfilador, si un proceso está dominado por llamadas al sistema?**

⏱️ Comparando tiempo de usuario con tiempo de sistema: si el de sistema domina, son llamadas.
🗣️ `/usr/bin/time -l` o el `time` del shell dan `user` y `sys` por separado. Un proceso con `sys` muy
por encima de `user` está pasando la vida cruzando la frontera.
🔬 Y el paso siguiente, si hace falta más detalle: contar las llamadas con `strace -c` en Linux o
`dtruss` en macOS, que dan el número y el tiempo por tipo. Ver tres millones de `read` en la lista es
un diagnóstico cerrado. La ventaja de este método es que no necesita instrumentar nada ni conocer el
lenguaje del proceso.

**04 → 25. ¿Por qué el tamaño de página del sistema aparece en la curva del búfer?**

⏱️ Porque el núcleo mueve datos en páginas, y pedir menos de una página no ahorra trabajo al otro
lado de la frontera.
🗣️ Con 4 KB de página, una lectura de 512 bytes obliga igualmente a traer la página entera del disco a
la caché: ocho lecturas de 512 tocan la misma página ocho veces y hacen ocho llamadas para lo que
cabía en una.
🔬 De ahí que la curva medida se doble justo en 4 096: es el punto donde una llamada corresponde a una
unidad de trabajo del sistema. Lo mismo explica que el tamaño de bloque del sistema de archivos
importe, y que en un sistema de archivos en red —donde la unidad es mucho mayor— la rodilla se
desplace a valores más altos.

**04 → 26. ¿Qué relación hay entre el búfer y la latencia percibida en un flujo interactivo?**

⏱️ Que un búfer grande mejora el rendimiento agregado y **empeora** la latencia de lo que se ve
primero.
🗣️ Si acumulas 64 KB antes de enviar, el primer byte útil llega cuando hay 64 KB — o cuando alguien
hace `flush`. En un terminal, en un log en vivo o en una respuesta en streaming, eso se percibe como
que "no pasa nada".
🔬 Por eso existen los tres modos clásicos: sin búfer para el error estándar, por líneas para
terminales, y por bloques para archivos y tuberías. Y por eso un programa que escribe a un terminal y
se redirige a un archivo **cambia de modo automáticamente**, lo que sorprende a mucha gente: el mismo
programa parece no escribir nada cuando se canaliza, hasta que termina. La corrección es un `flush`
explícito, no un búfer menor.

**04 → 27. Diseña la escritura de un fichero de confirmaciones de pago que no puede perder ni un registro ante un corte de luz. Di el coste de tu decisión.**

⏱️ Añadir al final, `flush` más `fsync` antes de confirmar al cliente, y sincronizar también el
directorio la primera vez. Coste: unos cincuenta veces más por escritura.
🗣️ El diseño:

```text
ESCRITURA   solo append, nunca modificación en sitio
ORDEN       escribir → flush → fsync → SOLO ENTONCES responder al cliente
DIRECTORIO  al crear el archivo, fsync también del directorio: si no, el archivo puede no existir
FORMATO     un registro por línea, con longitud o suma de verificación, para detectar un corte a medias
```
🔬 Tres decisiones que hay que justificar. **(1) El orden importa más que las llamadas**: confirmar al
cliente antes del `fsync` invalida todo el diseño, porque el compromiso se adquiere antes de la
garantía. **(2) Un registro escrito a medias es inevitable** —el corte puede caer en mitad de un
`write`—, así que el formato tiene que permitir detectarlo y descartarlo al reabrir; sin eso, un
archivo "duradero" puede tener basura al final. **(3) El coste** medido es de cincuenta veces, así que
si el volumen lo hace inviable, la salida es **agrupar**: sincronizar cada N milisegundos y confirmar
en lote a los clientes de esa ventana, que es exactamente lo que hacen las bases de datos y lo que
convierte la decisión en un compromiso explícito en vez de en una pérdida silenciosa.

**04 → 28. Escribe el experimento que demuestra la curva del tamaño de búfer y di qué esperas ver y por qué.**

⏱️ Leer el mismo archivo con tamaños de 1 B a 1 MB midiendo el tiempo, sobre un archivo que no quepa en
la caché o con la caché controlada.
🗣️ El experimento y la predicción:

```text
ARCHIVO   varios MB, generado con datos aleatorios
BARRIDO   read(1), read(16), read(512), read(4096), read(65536), read(1 MB)
ESPERADO  caída brutal hasta 4 KB · aplanamiento en 64 KB · leve empeoramiento en 1 MB
PORQUÉ    el coste es llamadas × fijo + bytes × variable; el primer término desaparece
```
🔬 Medido, coincide: 1 878,92 / 117,08 / 4,12 / 0,59 / 0,17 / 0,21 ms. Los dos controles que hacen
válido el experimento: **la caché de página** —si el archivo ya está en memoria se mide el coste de
las llamadas y no del disco, que para esta demostración está bien pero hay que declararlo— y
**repetir varias veces** descartando la primera, porque la primera lectura paga el disco y las demás
no. Y una comprobación que añade valor: ejecutar el mismo barrido con `sys` y `user` separados, para
ver que el tiempo de sistema es el que cae.

**04 → 29. Un proceso por lotes tarda ocho horas y la CPU está al 8 %. Da tres hipótesis ordenadas y cómo las distingues.**

⏱️ Entrada y salida sin búfer, esperas a un sistema remoto, o demasiadas operaciones pequeñas.
🗣️ Las tres:

```text
1. SIN BÚFER o búfer minúsculo      → tiempo de SISTEMA alto, millones de llamadas
2. ESPERAS REMOTAS (BD, red, API)   → tiempo de sistema y usuario BAJOS los dos: solo espera
3. DEMASIADAS OPERACIONES PEQUEÑAS  → consultas fila a fila, archivos diminutos, commits por registro
```
🔬 Cómo se distinguen, y es todo barato: **`time` separa `user` y `sys`** — si `sys` domina, es la 1;
si los dos son bajos frente al reloj, es la 2. **`strace -c` o `dtruss`** cuentan las llamadas y
cierran la 1 en un minuto. Para la 2, mirar el otro extremo: el registro de consultas lentas de la
base de datos o las métricas del servicio remoto. Para la 3, contar operaciones por registro
procesado — el clásico es una consulta por fila en lugar de una por lote, que es el N+1 llevado al
proceso por lotes. Y el orden importa porque las correcciones tienen coste muy distinto: la 1 es una
línea, la 3 es un rediseño del acceso a datos y la 2 puede no depender de ti.

**04 → 30. Diseña la copia de un archivo de 100 GB entre dos discos con memoria limitada: tamaño de búfer, comprobación de integridad y qué haces si falla a mitad.**

⏱️ Búfer de 1 a 4 MB, suma de verificación calculada al vuelo, y reanudación por desplazamiento.
🗣️ El diseño:

```text
BÚFER        1–4 MB: por encima de la rodilla, y solo una copia en curso, así que la memoria da
INTEGRIDAD   hash incremental del origen y del destino MIENTRAS se copia, no después
PROGRESO     registrar el desplazamiento alcanzado cada N MB en un archivo de control
FALLO        reanudar desde el último desplazamiento confirmado, no desde cero
FINAL        comparar hashes; solo entonces renombrar del nombre temporal al definitivo
```
🔬 Las decisiones que lo hacen correcto. **(1) El búfer aquí sí puede ser grande**, a diferencia del
caso de 20 000 conexiones, porque hay una sola copia: el criterio es memoria total, no tamaño de
búfer. **(2) Calcular el hash al vuelo** evita una segunda pasada de 100 GB, que duplicaría el tiempo.
**(3) Escribir a un nombre temporal y renombrar al final** es lo que hace la operación atómica para
quien observe el destino: nunca verá un archivo a medias con el nombre bueno. **(4) La reanudación
necesita que el desplazamiento registrado esté sincronizado**, o tras un corte de luz el archivo de
control mentirá — y aquí sí hace falta `fsync`, aunque solo cada N MB. Y conviene decir lo obvio: si
las dos rutas están en la misma máquina y el sistema de archivos lo permite, copiar con herramientas
del sistema o con clonado por referencia es más rápido que cualquier bucle que escribas.

**04 → 31. Un servicio escribe logs y bajo carga pierde líneas al reiniciarse. Diagnostica y da las tres correcciones con su coste.**

⏱️ Las líneas están en el búfer de aplicación y no han llegado al núcleo cuando el proceso muere.
🗣️ Encaja con los dos síntomas: **solo bajo carga**, porque el búfer tarda más en llenarse cuando el
volumen es alto y hay más pendiente en cada instante; y **solo al reiniciar**, porque un cierre
ordenado vaciaría el búfer y una muerte abrupta no.
🔬 Las tres correcciones, con su coste:

```text
1. FLUSH por línea o por tiempo   coste: más llamadas al sistema; aceptable para logs de texto
2. CIERRE ORDENADO que vacíe      coste: casi nulo; NO cubre un fallo abrupto ni un OOM
3. ESCRIBIR A UN COLECTOR         coste: infraestructura; el proceso deja de ser el dueño del dato
```
El orden de preferencia depende de qué son esos logs: **si son de diagnóstico**, la 1 con vaciado
periódico basta y es lo más barato. **Si son de auditoría** y perderlos tiene consecuencias, ninguna
de las tres basta por sí sola: hace falta `fsync` con su coste de cincuenta veces, y probablemente un
diseño distinto —escribirlos como parte de la transacción de negocio, no como log—. La pregunta que
hay que hacer antes de elegir es exactamente esa: **¿esto es diagnóstico o es un registro que alguien
va a exigir?**

---

# 05 — El árbol de directorios

**05 → 1. ¿Qué es un enlace simbólico?**

⏱️ Una entrada de directorio cuyo contenido es una ruta: el sistema la resuelve al acceder.
🗣️ Puede apuntar a cualquier sitio, incluso a un ancestro —y entonces hay un ciclo— o a algo que no
existe, y entonces está roto.
🔬 Es lo que convierte el sistema de archivos en un grafo. Y por eso `stat` y `lstat` son llamadas
distintas: la primera sigue el enlace y la segunda informa del enlace en sí.

**05 → 2. ¿Qué es un enlace duro?**

⏱️ Dos entradas de directorio que apuntan al mismo inodo: el mismo archivo con dos nombres.
🗣️ Ninguno de los dos es "el original": el archivo existe mientras quede al menos un nombre
apuntándolo, y borrar uno no afecta al otro.
🔬 Produce repetición sin ciclo: el mismo contenido aparece dos veces al recorrer. Por eso un `du`
ingenuo cuenta su tamaño dos veces, y el de verdad lleva registro de los inodos ya contados.

**05 → 3. ¿Sigue `os.walk` los enlaces por defecto?**

⏱️ No. Hay que pedirlo con `followlinks=True`.
🗣️ Y es el valor por defecto correcto, porque seguirlos abre la puerta a los ciclos y a salir del árbol
que creías estar recorriendo.
🔬 Verificado: con `followlinks=True` y un enlace a un ancestro, **no termina**. La documentación de
Python avisa explícitamente de la recursión infinita y no hace nada para evitarla.

**05 → 4. ¿Qué es un inodo?**

⏱️ La estructura que representa un archivo en el sistema de archivos: sus metadatos y dónde están sus
datos. El nombre no está dentro.
🗣️ El nombre vive en la entrada de directorio, que apunta al inodo. Por eso un archivo puede tener
varios nombres y por eso renombrar es barato: cambia la entrada, no el archivo.
🔬 El par **(dispositivo, inodo)** identifica un archivo de forma única en el sistema, y es lo que hay
que usar como clave cuando se necesita saber si dos rutas son el mismo objeto — para detectar ciclos y
para no contar dos veces.

**05 → 5. ¿Qué diferencia hay entre `stat` y `lstat`?**

⏱️ `stat` sigue los enlaces simbólicos y describe el destino; `lstat` describe el enlace en sí.
🗣️ Para saber si algo **es** un enlace hay que usar `lstat`: con `stat` verías el tipo del destino.
🔬 Y el caso que confunde: sobre un enlace roto, `stat` **falla** con "no existe el archivo" aunque la
entrada de directorio esté ahí perfectamente. Un recorrido que solo use `stat` informará de que el
archivo no existe, cuando lo correcto es decir que el enlace está roto.

**05 → 6. ¿Qué hace `Files.walk` de Java ante un ciclo de enlaces?**

⏱️ Con `FOLLOW_LINKS`, lo detecta y lanza `FileSystemLoopException`.
🗣️ Verificado con el mismo árbol que cuelga a Python: Java falla explícitamente nombrando la ruta del
bucle. Es la implementación más completa de los cinco lenguajes.
🔬 Lo consigue llevando registro de los directorios ya visitados por su identidad real, que es
exactamente lo que hay que implementar a mano en los demás. Sin `FOLLOW_LINKS`, no sigue los enlaces y
la cuestión no se plantea.

**05 → 7. ¿Para qué sirve `scandir`?**

⏱️ Para conservar la información que la lectura del directorio ya devuelve, en vez de tirarla y volver
a pedirla con un `stat`.
🗣️ Al listar un directorio, el sistema entrega para cada entrada algo más que el nombre —a menudo el
tipo—. `scandir` lo expone; `listdir` no, y obliga a un `stat` por entrada.
🔬 Sus equivalentes son `DirEntry` en Go y `withFileTypes: true` en Node. Cuánto ahorra depende del
sistema de archivos: si la entrada trae el tipo, es gratis; si no, acaba haciendo el `stat` igual, y
por eso la medida del capítulo da una mejora del 16 % y no más.

**05 → 8. ¿Cuánto cuesta un recorrido de directorios en notación asintótica?**

⏱️ `O(entradas)`: lineal en el número de archivos y directorios.
🗣️ No hay nada superlineal en recorrer un árbol: cada entrada se visita una vez.
🔬 Lo que decide el tiempo real no es la complejidad sino **cuántas llamadas al sistema haces por
entrada**: medido, pedir el tamaño de cada archivo pasa de 6,8 ms a 31,9 ms sobre 10 000 archivos. Es
el mismo principio del capítulo `04` aplicado a metadatos en vez de a datos.

**05 → 9. ¿Por qué un sistema de archivos no es un árbol?**

⏱️ Porque los enlaces simbólicos pueden apuntar a ancestros —ciclos— y los enlaces duros dan varios
nombres al mismo objeto.
🗣️ Con esas dos construcciones, la estructura es un grafo dirigido, y recorrerlo tiene las mismas
obligaciones que recorrer cualquier grafo: llevar un conjunto de visitados.
🔬 Los enlaces duros a directorios están prohibidos en los sistemas modernos precisamente para que el
grafo no tenga ciclos "duros"; los simbólicos sí pueden crearlos, y por eso el problema del capítulo
existe solo cuando decides seguirlos.

**05 → 10. ¿Por qué guardar rutas visitadas no detecta ciclos?**

⏱️ Porque cada vuelta del ciclo genera una ruta nueva y distinta.
🗣️ `arbol/a/b/c/bucle/a/b/c` y `arbol/a/b/c/bucle/a/b/c/bucle/a/b/c` son cadenas diferentes aunque
apunten al mismo directorio. El conjunto crece para siempre y nunca hay coincidencia.
🔬 Es el mismo error que comparar nodos de un grafo por una etiqueta derivada del camino en lugar de
por su identidad. La solución está en la pregunta siguiente, y es la razón de que el capítulo enlace
con `04-arboles-grafos/03`.

**05 → 11. ¿Qué se guarda entonces en el conjunto de visitados?**

⏱️ El par `(dispositivo, inodo)` de cada directorio.
🗣️ Es el identificador real del objeto: dos rutas distintas que llevan al mismo directorio dan el mismo
par, y ahí se corta el ciclo.
🔬 Verificado con el recorrido del problema P2: sobre el árbol con ciclo termina, y reporta cuatro
directorios únicos. El detalle de implementación es usar `stat` y no `lstat` para obtener la
identidad, porque queremos la del destino — que es justo lo contrario de cuando queremos saber si es
un enlace.

**05 → 12. ¿Qué hace Python con `followlinks=True` y un enlace a un ancestro?**

⏱️ Se cuelga: recorre el ciclo indefinidamente.
🗣️ Verificado. No hay excepción, no hay aviso en tiempo de ejecución: el recorrido simplemente no
termina, y la memoria crece con la lista de rutas.
🔬 La documentación lo advierte y deja la responsabilidad al programador. Si necesitas seguir enlaces
en Python, la detección la implementas tú con el conjunto de inodos de la pregunta 11 — que es
exactamente lo que Java hace por ti.

**05 → 13. ¿Por qué `WalkDir` sustituyó a `Walk` en Go?**

⏱️ Porque `Walk` hacía un `stat` por entrada y `WalkDir` entrega la `DirEntry` que ya venía en la
lectura del directorio.
🗣️ Es la misma idea que `scandir` de Python: no volver a pedir lo que el sistema ya te dio. En árboles
grandes la diferencia se nota, y en sistemas de archivos en red mucho más.
🔬 La `DirEntry` trae el nombre y el tipo sin coste; si necesitas más —tamaño, fechas— llamas a
`Info()`, que **sí** hace el `stat`. Es decir, la API hace explícito el momento en que decides pagar,
que es exactamente lo que el capítulo predica.

**05 → 14. ¿Por qué un `du` ingenuo cuenta de más con enlaces duros?**

⏱️ Porque el mismo inodo aparece con dos nombres y suma su tamaño dos veces.
🗣️ El archivo ocupa el espacio una sola vez en el disco; lo que hay duplicado son las entradas de
directorio, que no ocupan nada comparable.
🔬 El `du` real lleva un conjunto de inodos ya contados y salta los repetidos — el mismo conjunto de la
pregunta 11, usado para otra cosa. Es un buen ejemplo de que la identidad por inodo resuelve dos
problemas distintos: los ciclos y el doble conteo.

**05 → 15. ¿Qué pasa si un archivo desaparece entre el listado y el `stat`?**

⏱️ El `stat` falla, y es una situación normal que hay que tolerar.
🗣️ El sistema de archivos cambia mientras lo recorres: otro proceso puede borrar, mover o crear. No
existe forma de tomar una foto consistente del árbol.
🔬 Por eso todo código de recorrido tiene que tratar el fallo de la consulta como un caso esperado y
no como un error: registrar y continuar. Un recorrido que aborte ante el primer archivo desaparecido
fallará de forma aleatoria en cualquier sistema con actividad, y será imposible de reproducir.

**05 → 16. ¿Por qué `stat` falla sobre un enlace roto?**

⏱️ Porque sigue el enlace y el destino no existe.
🗣️ La entrada de directorio está ahí y es perfectamente válida; lo que no existe es aquello a lo que
apunta. `stat` informa del destino, así que falla con "no existe el archivo".
🔬 `lstat` funciona perfectamente y dice que es un enlace. De ahí una regla práctica: en un recorrido
que quiera informar del estado real del árbol, hay que usar `lstat` para clasificar y `stat` solo
cuando de verdad interese el destino — si no, los enlaces rotos se reportan como archivos ausentes y
el informe confunde.

**05 → 17. ¿Por qué pedir el tamaño multiplica por cinco el recorrido?**

⏱️ Porque añade una llamada al sistema por archivo: diez mil archivos son diez mil llamadas más.
🗣️ Medido: 6,8 ms listando solo nombres y 31,9 ms pidiendo el tamaño de cada uno, sobre 10 000
archivos en 50 directorios.
🔬 Es exactamente el principio del capítulo `04` —el peaje es por cruce de frontera, no por dato— y por
eso la regla es la misma: **no preguntes lo que no vas a usar**. Un recorrido que solo necesita
nombres no debe llamar a `stat`, y uno que necesita el tipo debe usar la API que ya lo trae.

**05 → 18. ¿Cuánto gana `scandir` y por qué depende del sistema de archivos?**

⏱️ Aquí un 16 % —de 31,9 a 26,9 ms— y en otros sistemas mucho más, porque depende de si la entrada de
directorio ya trae el tipo.
🗣️ Si el sistema de archivos lo incluye, `scandir` lo aprovecha y el `stat` desaparece. Si no lo
incluye, `scandir` acaba haciendo el `stat` igual y la mejora se limita a evitar la segunda llamada.
🔬 La lección general es más valiosa que el número: **las ganancias de este tipo dependen de la capa de
abajo y hay que medirlas en el entorno real**. En un sistema de archivos en red, donde cada llamada
cuesta milisegundos en vez de microsegundos, la misma optimización puede valer un orden de magnitud —
y ahí es donde de verdad importa.

**05 → 19. ¿Cuándo seguirías enlaces simbólicos y cuándo no?**

⏱️ Los sigo cuando el usuario los puso a propósito para componer un árbol que controlo; no los sigo con
datos de terceros.
🗣️ Un directorio de configuración donde un enlace apunta a otra ubicación es un uso legítimo y esperar
que se recorra es razonable. Un directorio subido por usuarios es otra cosa.
🔬 Y cuando decido seguirlos, asumo tres obligaciones: **detección de ciclos** por inodo, **tope de
profundidad**, y **comprobar que el destino sigue dentro del árbol permitido** — porque si no, un
enlace me saca del directorio que creía estar recorriendo, que es la pregunta siguiente.

**05 → 20. ¿Qué riesgo de seguridad tiene seguir enlaces en datos de terceros?**

⏱️ Que el enlace apunte fuera del árbol y tu proceso lea, copie o publique algo que no debía.
🗣️ Un archivo subido por un usuario que contiene un enlace a `/etc` hace que tu copia de seguridad se
lleve el contenido de `/etc`, o que tu escáner lo publique en un informe. El proceso tiene permisos
que el usuario no tiene, y el enlace los aprovecha.
🔬 Es la versión con enlaces del *path traversal* del bloque `07`, y la defensa es la misma idea:
**resolver la ruta real y comprobar que sigue estando bajo la raíz permitida** antes de abrir nada. Y
como hay una condición de carrera entre comprobar y abrir, en código sensible se usan las variantes
que operan relativas a un descriptor de directorio ya abierto, que eliminan la ventana.

**05 → 21. ¿Cuándo conviertes el recorrido recursivo en iterativo?**

⏱️ Cuando la profundidad no la controlas tú, porque la recursión agota la pila.
🗣️ Un árbol profundo —o uno hecho profundo a propósito— hace que un recorrido recursivo falle con
desbordamiento de pila, y eso en muchos lenguajes no es una excepción que se pueda tratar con
elegancia.
🔬 La conversión es la de `01-fundamentos/04`: una pila explícita con los nodos pendientes, que además
permite **poner un tope de profundidad** de forma trivial —basta guardar el nivel junto al nodo— y
hace el consumo de memoria visible y acotable. Con datos de terceros, iterativo y con tope no es una
preferencia: es un requisito.

**05 → 22. ¿Aborta o continúa tu recorrido ante un permiso denegado? Justifica las dos posturas.**

⏱️ Depende de para qué es el recorrido: una copia de seguridad continúa y reporta; una verificación de
integridad aborta.
🗣️ **Continuar** tiene sentido cuando el valor está en lo que sí se pudo procesar y la lista de
omisiones es aceptable: una copia parcial vale más que ninguna, siempre que el informe diga qué falta.
**Abortar** tiene sentido cuando un resultado incompleto es peor que ninguno: si el recorrido
comprueba que todos los archivos cumplen una política, saltarse uno invalida la conclusión.
🔬 Lo que no es defendible es no haberlo decidido. Y hay una tercera vía que suele ser la mejor:
**continuar, contar, y fallar al final si los errores superan un umbral** — así se distingue un
directorio inaccesible aislado de un problema sistemático de permisos, que es lo que pasa cuando el
proceso corre con el usuario equivocado.

**05 → 23. ¿Por qué el recorrido de un árbol real no es reproducible?**

⏱️ Porque el sistema de archivos cambia mientras lo recorres y no hay forma de tomar una foto
consistente.
🗣️ Otros procesos crean, borran y mueven. Puedes listar un directorio, y para cuando llegas a su tercer
archivo, ese archivo ya no existe — o hay uno nuevo que no verás.
🔬 Las implicaciones prácticas: **el orden de las entradas tampoco está garantizado**, así que si
necesitas una salida determinista hay que ordenar explícitamente; y **dos recorridos seguidos pueden
dar resultados distintos sin que nadie haya hecho nada raro**, lo que hay que tener en cuenta al
comparar. Si se necesita consistencia de verdad, hay que pedírsela a otra capa: una instantánea del
sistema de archivos o del volumen.

**05 → 24. Los tres lenguajes hacen cosas distintas ante el mismo ciclo. ¿Cuál prefieres como valor por defecto y por qué?**

⏱️ El de Java: detectar y lanzar una excepción con la ruta del bucle.
🗣️ Los tres valores por defecto son defendibles —Go y Python no siguen enlaces, así que el problema no
se plantea—, pero al **decidir seguirlos**, la diferencia importa: Java te dice exactamente dónde está
el bucle y Python se cuelga sin decir nada.
🔬 El criterio es el de siempre: **fallar ruidosamente es mejor que fallar en silencio**. Un proceso
colgado consume recursos indefinidamente, no aparece como error en ningún panel y se diagnostica mal;
una excepción con la ruta del enlace se arregla en cinco minutos. La postura de Go —no ofrecer la
opción— también es coherente y tiene la ventaja de no dar una funcionalidad a medias; lo que no me
gusta es ofrecerla sin protección, que es lo de Python.

**05 → 25. ¿Por qué el conjunto de visitados de un recorrido de archivos se parece al del bloque `04` y en qué se diferencia?**

⏱️ Se parece en que es la misma técnica de detección de ciclos; se diferencia en que la identidad del
nodo hay que pedírsela al sistema operativo.
🗣️ En un grafo en memoria, el nodo **es** su identidad: un objeto, un índice, una clave. En el sistema
de archivos, lo que tienes es una ruta, que no identifica nada — y obtener la identidad real cuesta
una llamada al sistema por directorio.
🔬 De ahí dos diferencias prácticas. **El conjunto de visitados tiene un coste de construcción**, no
solo de consulta, porque cada `stat` es una llamada. Y **la identidad puede cambiar mientras
recorres**: un directorio puede ser sustituido por otro entre dos visitas, cosa que en un grafo en
memoria no ocurre. La estructura del algoritmo es idéntica; el coste y las garantías, no.

**05 → 26. Escribe el recorrido con detección de ciclos, tope de profundidad y tolerancia a errores. Di qué decisiones tomaste y por qué.**

⏱️ Iterativo con pila explícita, conjunto de `(dispositivo, inodo)`, nivel junto a cada nodo y captura
de errores por entrada.
🗣️ La implementación, ejecutada sobre el árbol con ciclo:

```python
def recorrer(raiz, max_prof=64):
    vistos, total, errores = set(), 0, []
    pila = [(raiz, 0)]
    while pila:
        d, prof = pila.pop()
        if prof > max_prof:
            errores.append((d, "profundidad excedida")); continue
        try:
            st = os.stat(d)                       # sigue el enlace: identidad REAL
        except OSError as e:
            errores.append((d, e.strerror)); continue
        id_real = (st.st_dev, st.st_ino)          # ni la ruta ni el nombre
        if id_real in vistos:
            continue                              # aquí se corta el ciclo
        vistos.add(id_real)
        try:
            entradas = list(os.scandir(d))
        except OSError as e:
            errores.append((d, e.strerror)); continue
        for e in entradas:
            try:
                if e.is_dir():
                    pila.append((e.path, prof + 1))
                elif e.is_file():
                    total += e.stat().st_size
            except OSError as err:
                errores.append((e.path, err.strerror))
    return total, len(vistos), errores
```
🔬 Las cuatro decisiones y su porqué. **(1) Iterativo con pila**, porque la profundidad la fija el
árbol y no yo, y así el tope de profundidad sale gratis. **(2) `os.stat` y no `lstat`** para la
identidad, porque quiero la del destino: es justo lo contrario de cuando quiero saber si algo es un
enlace. **(3) `scandir` y no `listdir`**, para no pagar un `stat` extra por entrada. **(4) Errores
capturados por entrada y acumulados**, no propagados: el recorrido continúa y devuelve la lista, que
es lo correcto para la mayoría de los usos — y quien necesite abortar tiene la lista para decidirlo.
Lo que **no** hace y habría que añadir según el caso: comprobar que el destino de cada enlace sigue
bajo la raíz permitida, por la pregunta 20.

**05 → 27. Un proceso de limpieza nocturno se colgó una vez en dos años. Diagnostica y escribe la corrección y la prevención.**

⏱️ Casi seguro un enlace simbólico nuevo que crea un ciclo, en un recorrido que sigue enlaces sin
detección.
🗣️ Encaja con el patrón: **una vez en dos años** significa que el código siempre fue vulnerable y que
lo que cambió fue el árbol, no el programa. Alguien creó un enlace —a menudo con la mejor
intención— y el recorrido entró en bucle. El síntoma es un proceso vivo que no avanza y no falla.
🔬 Cómo se confirma en cinco minutos: un volcado de pila del proceso colgado muestra el recorrido; y
`find <raiz> -type l` lista los enlaces, con el sospechoso a la vista. La **corrección** es la de la
pregunta 26: detección por inodo y tope de profundidad. La **prevención** tiene tres piezas y la
tercera es la que suele faltar: **(1)** no seguir enlaces salvo que haga falta; **(2)** un tiempo
límite del trabajo nocturno, para que un cuelgue sea un fallo y no un silencio; **(3)** una alerta por
**ausencia** de la señal de finalización, porque un proceso colgado no genera ningún error y por eso
tardó dos años en verse. Un trabajo por lotes sin alerta de "no terminó" puede estar fallando desde
hace meses.

**05 → 28. Diseña un `du` correcto: qué cuenta, qué no cuenta dos veces, qué hace con los enlaces y cuál es su coste.**

⏱️ Cuenta bloques ocupados, no tamaño lógico; no cuenta dos veces los inodos ya vistos; no sigue
enlaces simbólicos y no cuenta su destino; coste `O(entradas)` con un `stat` por entrada.
🗣️ El diseño:

```text
QUÉ CUENTA      blocks × 512, no st_size: refleja lo que ocupa en disco
DUPLICADOS      conjunto de (dispositivo, inodo); si ya está, no se suma
ENLACES SIMB.   no se siguen; se cuenta el enlace en sí, que ocupa poco o nada
DISPOSITIVOS    por defecto, no cruzar a otro sistema de archivos montado
COSTE           O(entradas), con un stat por entrada: es el caso caro del capítulo
```
🔬 Las decisiones que distinguen un `du` correcto de uno ingenuo. **Tamaño lógico frente a ocupado**:
un archivo disperso puede declarar un giga y ocupar un mega, y `st_size` mentiría; por eso se usan los
bloques. **El conjunto de inodos** evita el doble conteo de los enlaces duros, y es el mismo conjunto
que la detección de ciclos, usado para otra cosa. **No cruzar dispositivos** evita que contar un
directorio se lleve por delante un volumen de red montado dentro. Y el coste es inevitablemente el
alto —hace falta `stat` de cada entrada porque necesitamos el tamaño—, así que aquí la optimización
del capítulo no aplica: lo que sí se puede es no pedir nada más que lo necesario y paralelizar por
subárboles si el dispositivo lo aguanta.

**05 → 29. Diseña un sincronizador de carpetas: qué compara, qué recorre, cómo detecta cambios y cuál es su coste.**

⏱️ Compara por ruta relativa, detecta cambios por tamaño más fecha y confirma con hash solo cuando hay
duda; recorre los dos árboles una vez.
🗣️ El diseño:

```text
RECORRIDO   los dos árboles, una pasada cada uno, con scandir
CLAVE       la ruta relativa a la raíz: es lo que define "el mismo archivo" para el usuario
CAMBIO      1) existe en uno y no en otro → copiar o borrar
            2) tamaño distinto            → cambió, seguro
            3) mismo tamaño, fecha distinta → candidato: comparar hash
COSTE       O(entradas) por lado + hash solo de los candidatos
```
🔬 Las decisiones y sus trampas. **La fecha sola no basta**: la resolución varía entre sistemas de
archivos, los relojes se desajustan y copiar preserva o no la fecha según la herramienta; por eso es
un filtro de candidatos, no un veredicto. **El hash solo de los candidatos** es la poda que hace
viable el diseño — el mismo razonamiento del problema P5. **La ruta relativa como clave** es una
decisión de producto, no técnica: significa que renombrar un archivo se ve como un borrado más un alta,
y si eso no vale, hay que identificar por contenido y entonces el coste sube mucho. Y hay que decidir
qué pasa con **los conflictos** —cambió en los dos lados— porque sin esa regla el sincronizador pierde
datos en silencio, que es el peor fallo posible aquí.

**05 → 30. Un escáner de seguridad recorre directorios subidos por usuarios. Escribe los controles que impondrías y qué ataque previene cada uno.**

⏱️ No seguir enlaces, tope de profundidad y de entradas, resolver y confinar las rutas, y un tiempo
límite.
🗣️ Los controles y su ataque:

```text
NO SEGUIR ENLACES        → lectura de archivos fuera del árbol (/etc, claves, otros usuarios)
CONFINAR LA RUTA REAL    → lo mismo, si por algún motivo hay que seguirlos
TOPE DE PROFUNDIDAD      → árbol profundo hecho a propósito: desbordamiento de pila
TOPE DE ENTRADAS/TAMAÑO  → directorio con millones de archivos: agotamiento de memoria y tiempo
TIEMPO LÍMITE            → cualquier cosa que no contemplé: convierte un cuelgue en un fallo
NO EJECUTAR NADA         → archivos con nombre o extensión engañosa
```
🔬 Dos puntos que elevan la respuesta. **El primero: el tiempo límite es el control que cubre lo que
no previste**, y por eso no es opcional aunque estén todos los demás — es la misma idea que el timeout
del capítulo `03`. **El segundo: hay una condición de carrera entre comprobar la ruta y abrirla**, así
que en código realmente sensible se opera con descriptores de directorio ya abiertos y llamadas
relativas a ellos, que eliminan la ventana. Y conviene añadir el control que no es técnico: **ejecutar
el escáner con el mínimo privilegio posible**, porque todos los controles anteriores fallan mejor si
el proceso no tenía permiso para leer `/etc` en primer lugar.

**05 → 31. Escribe el informe de por qué una copia de seguridad pasó de dos horas a seis sin que crecieran los datos.**

⏱️ Casi seguro que aumentó el **número de entradas** o el **número de llamadas por entrada**, no el
volumen.
🗣️ El razonamiento: el tiempo de una copia depende de bytes movidos **y** de operaciones por archivo. Si
los bytes no crecieron, creció lo segundo. Las causas habituales, en orden: muchos más archivos
pequeños —un directorio de caché o de logs que nadie limpia—; un cambio en el código que añadió un
`stat` o un hash por archivo; o el almacenamiento pasó a estar en red, donde cada operación cuesta
milisegundos.
🔬 El informe:

```text
SÍNTOMA      2 h → 6 h, volumen estable
HIPÓTESIS    1) más entradas (no más bytes)  2) más llamadas por entrada  3) almacenamiento remoto
CÓMO SE MIDE contar archivos por directorio y comparar con el histórico
             comparar tiempo de usuario y de sistema con una ejecución antigua
             comprobar si las rutas están en un montaje de red
CORRECCIÓN   depende: limpiar el directorio que explotó · quitar el trabajo por archivo ·
             agrupar archivos pequeños en un contenedor antes de copiar
PREVENCIÓN   métrica de "archivos procesados" además de "bytes copiados", con alerta por tendencia
```
La prevención es lo que hace útil el informe: **si solo mides bytes, esta degradación es invisible
hasta que alguien se queja**. Y la corrección más eficaz suele ser la última —empaquetar los archivos
pequeños—, porque ataca el número de operaciones, que es el término que domina, en lugar de intentar
hacer cada operación más rápida.

---

# 06 — Simulación: preguntas transversales

**06 → S1. ¿Qué es un descriptor de archivo y qué cosas lo usan?**

⏱️ Un entero que indexa una tabla del núcleo por proceso. Lo usan archivos, sockets, tuberías,
terminales, dispositivos y temporizadores.
🗣️ Esa unificación es el paradigma de Unix, y su consecuencia práctica más importante es que **todos
compiten por el mismo límite**.
🔬 Desarrollo en `01 → 1` y `01 → 2`. El número no se ve en Java ni en Go porque está envuelto, y eso
es justo lo que hace que se olvide cerrarlo.

**06 → S2. Te llega `Too many open files` en producción. ¿Qué haces en los primeros cinco minutos?**

⏱️ Contar descriptores y ver el límite real, agruparlos por tipo, y mirar si crecen con el tiempo.
🗣️ `lsof -p <pid> | wc -l` contra `/proc/<pid>/limits`; luego `awk` sobre la quinta columna para ver si
son archivos, conexiones o `CLOSE_WAIT`; y un bucle que cuente cada diez segundos.
🔬 Desarrollo completo en `01 → 20`. Lo que decide la corrección es el tercer comando: crecimiento
monótono es fuga —código—; subida y bajada con la carga es dimensionado —configuración—.

**06 → S3. ¿Por qué ese error aparece con memoria libre de sobra?**

⏱️ Porque descriptores y memoria son recursos independientes y solo uno tiene presión.
🗣️ En Java la liberación va atada al recolector de basura, que actúa por memoria. Los objetos
envoltorio son diminutos, así que se acumulan cien mil descriptores sin que el montón se inmute.
🔬 Desarrollo en `01 → 18`. La consecuencia operativa es que el panel de memoria está verde mientras el
servicio se cae, y por eso el diagnóstico se va por el camino equivocado durante la primera hora.

**06 → S4. ¿Quién cierra un archivo que olvidaste cerrar, en cada uno de los cinco lenguajes?**

⏱️ Python lo cierra al instante por conteo de referencias; Java cuando pase el recolector; Go nunca;
Node y TypeScript, nunca salvo que uses `using`.
🗣️ Medido: 200 aperturas sin cerrar dejan **1** descriptor extra en Python y **200** en Java hasta que
el recolector actúa.
🔬 Desarrollo en `01 → 10`, `01 → 11` y `01 → 12`. Y la conclusión que vale para los cinco: la
construcción de cierre determinista no es opcional en ninguno, porque en el mejor caso dependes de un
detalle de implementación.

**06 → S5. ¿Dónde está la trampa de `defer` en Go?**

⏱️ Se ejecuta al salir de **la función**, no del bloque: dentro de un bucle, los cierres se acumulan.
🗣️ Un bucle que abre diez mil archivos con `defer f.Close()` los mantiene los diez mil abiertos hasta
que la función termina.
🔬 Desarrollo en `01 → 13`. La corrección es extraer el cuerpo del bucle a su propia función, no
cerrar a mano — porque cerrar a mano pierde la garantía ante un `return` temprano o un `panic`.

**06 → S6. ¿Cómo distingues una fuga de descriptores de un dimensionado corto?**

⏱️ Por la curva en el tiempo: la fuga crece y no baja; el dimensionado sube con la carga y vuelve a la
línea base.
🗣️ Y la distinción decide dónde se arregla: la fuga en el código, el dimensionado en la configuración.
🔬 Desarrollo en `01 → 17` y `01 → 19`. Subir el límite ante una fuga solo mueve la fecha del
incidente, y además lo hace más raro y por tanto más difícil de reproducir.

**06 → S7. ¿Qué métrica expondrías y con qué umbral?**

⏱️ Descriptores abiertos y límite efectivo, con aviso al 80 % y alerta al 90 %; y la pendiente como
tercera señal.
🗣️ Dos series y no una, porque el límite cambia al redesplegar en otro entorno y la alerta se define
sobre el porcentaje.
🔬 Desarrollo en `01 → 23`. La pendiente importa porque una fuga lenta cruza el 80 % sin que nadie lo
note en un panel; una tasa de crecimiento sostenida con tráfico plano es inequívoca.

**06 → S8. ¿Qué significa "todo es un archivo" y qué unifica de verdad?**

⏱️ Que todo se manipula con descriptores y las mismas cuatro llamadas. Unifica la **interfaz**, no la
semántica.
🗣️ Es el mejor modelo mental que hay para razonar sobre entrada y salida, y una fuente de errores si se
usa para predecir comportamiento.
🔬 Desarrollo en `02 → 1` y `02 → 9`. Las cuatro roturas —archivos no seleccionables, `read` con
significados distintos, Windows, y la asincronía de archivos emulada con hilos— son el capítulo `02`
entero.

**06 → S9. ¿Por qué no se puede hacer `epoll` sobre un archivo regular?**

⏱️ Porque siempre se reporta "listo": los datos están en el disco, no hay nada que esperar a que
llegue.
🗣️ Y "listo" no significa "instantáneo": la lectura puede tardar milisegundos y durante ese tiempo el
hilo está bloqueado. Ese es el hueco que ningún mecanismo de notificación cubre.
🔬 Desarrollo en `02 → 10` y `02 → 11`. En Java la imposibilidad es de compilación: `FileChannel` no
extiende `SelectableChannel` y `configureBlocking` no existe.

**06 → S10. ¿Por qué existe `io_uring`?**

⏱️ Porque `epoll` no sirve para archivos regulares, y además para reducir el número de llamadas al
sistema.
🗣️ Aporta lo que faltaba —"empieza esto y avísame cuando esté", en vez de "avísame cuando haya
datos"— y colas compartidas entre proceso y núcleo que amortizan el peaje de la frontera.
🔬 Desarrollo en `02 → 17` y `02 → 29`. El precio: solo Linux reciente, complejidad real y una
superficie de seguridad que ha dado problemas. Para un servicio de negocio normal no es el cuello.

**06 → S11. ¿Es Node de un solo hilo?**

⏱️ El JavaScript del usuario sí; el proceso no. Medidos, ocho hilos.
🗣️ Son el bucle de eventos más el pool de `libuv`, por el que pasan `fs`, `crypto`, `zlib` y
`dns.lookup`. Y desde Node 12 existen además los `worker_threads`.
🔬 Desarrollo en `02 → 6` y `02 → 25`. Importa porque explica latencias reales: cuatro operaciones de
archivo lentas bloquean también las de criptografía, y eso no lo ve ningún perfilador de JavaScript.

**06 → S12. ¿Qué devuelve `read` cuando el otro extremo cierra, y en qué se diferencia de un archivo?**

⏱️ Cero en los dos casos, pero significa cosas distintas: fin de archivo frente a cierre del otro lado.
🗣️ Y hay dos diferencias más: en un socket, `read` puede devolver **menos** de lo pedido —lectura
parcial— y puede devolver `-1` con `EAGAIN` si no bloquea.
🔬 Desarrollo en `02 → 7` y `02 → 12`. Es el ejemplo canónico de que la interfaz unificada esconde
semánticas distintas, y de ahí sale el código que funciona con archivos y falla con sockets.

**06 → S13. ¿Qué código funciona con archivos y falla con sockets?**

⏱️ Un `read` sin bucle: con archivos devuelve todo lo pedido; con sockets puede devolver una parte.
🗣️ Y funciona en desarrollo, donde la red es local y los mensajes son pequeños. Aparece en producción
con mensajes grandes, latencia o un proveedor lento.
🔬 Desarrollo en `02 → 20`. El síntoma es un error de parseo y no de red, así que la investigación
empieza en el sitio equivocado. Sus dos hermanos: no tratar el cero como cierre, y no tratar `EAGAIN`.

**06 → S14. Diferencia bloqueante, no bloqueante y asíncrono.**

⏱️ Bloqueante y no bloqueante dicen si la llamada espera; síncrono y asíncrono dicen quién avisa del
resultado. Son dos ejes.
🗣️ Se puede ser no bloqueante y síncrono —sondeo activo— y esa es la peor combinación de las cuatro.
🔬 Desarrollo en `03 → 9` y `03 → 10`. La pregunta útil no es "¿es asíncrono?" sino "¿qué hace mi hilo
mientras espera?", y solo hay tres respuestas: se para, gira en vano o atiende otra cosa.

**06 → S15. ¿Cuál de las cuatro combinaciones es la peor?**

⏱️ No bloqueante y síncrona: el sondeo activo, que quema CPU sin avanzar.
🗣️ Se llega por accidente: alguien pone los descriptores en modo no bloqueante "para no bloquear" y no
añade el mecanismo de notificación.
🔬 Desarrollo en `03 → 10`. El síntoma es CPU al 100 % con el servicio ocioso, y es inconfundible una
vez sabes que existe.

**06 → S16. ¿Hasta cuántas conexiones aguanta hilo por conexión?**

⏱️ Hasta unos cientos sin problema, y con degradación a partir de miles.
🗣️ Medido: 2 000 conexiones funcionaron con 490 ms, a costa de 2 014 hilos del sistema y 240 MB.
🔬 Desarrollo en `03 → 12`. La afirmación honesta no es "no escala", es "escala hasta cientos y a
partir de miles paga un coste que otros modelos no pagan" — y con cientos es la opción más simple y
depurable.

**06 → S17. ¿Son más rápidos los hilos virtuales?**

⏱️ No. La latencia es prácticamente igual; lo que cambia es cuántos caben y cuánto cuestan.
🗣️ 490 ms contra 419 ms con 2 000 conexiones; 2 014 hilos contra 35 y 240 MB contra 64 MB.
🔬 Desarrollo en `03 → 19`. Con poca concurrencia incluso pueden ser un poco más lentos, por la capa de
aparcado y reanudación. Su valor es de capacidad, no de velocidad.

**06 → S18. ¿Por qué un pool acotado puede tumbar un servicio?**

⏱️ Porque cada hilo ocupado esperando reduce la capacidad, y cuando se agotan deja de atenderse todo,
no solo lo lento.
🗣️ Medido en pequeño: 50 peticiones de 100 ms con un pool de 8 dan 727 ms, seis veces más que sin
acotar. Con un proveedor que pasa a 5 s, es una caída.
🔬 Desarrollo en `03 → 17` y `03 → 18`. Las defensas en orden: timeouts agresivos, pools separados por
dependencia, y no bloquear.

**06 → S19. ¿Qué tienen en común Go y Java 21, y en qué se diferencian de Node?**

⏱️ Que el código se escribe como bloqueante y el runtime lo hace no bloqueante. Node expone la
asincronía al programador.
🗣️ En Go y Java 21 no hay color de funciones: las bibliotecas existentes siguen valiendo y migrar es
barato.
🔬 Desarrollo en `03 → 15`. Los dos enfoques funcionan; la diferencia se nota al migrar código
existente, y es la razón de que pasar a hilos virtuales cueste poco y pasar a reactivo cueste mucho.

**06 → S20. ¿Qué es el color de las funciones?**

⏱️ Que una función `async` solo se pueda llamar desde otra `async`, tiñendo toda la pila.
🗣️ Lo sufren JavaScript, TypeScript y Python; produce bibliotecas duplicadas y hace imposible usar
código bloqueante sin envolverlo.
🔬 Desarrollo en `03 → 14`. Go y Java 21 no lo tienen, y esa es su ventaja más subestimada.

**06 → S21. ¿Cuándo es reactivo peor que bloqueante?**

⏱️ Con poca concurrencia: paga complejidad y pierde depuración por un problema que no tiene.
🗣️ Con doscientos usuarios, doscientos hilos van sobrados. Reactivo añade operadores, contrapresión
que gestionar, trazas inútiles y una curva de aprendizaje para todo el equipo.
🔬 Desarrollo en `03 → 22` y `03 → 29`. Y el coste que más se subestima: un solo componente bloqueante
dentro de la cadena anula el modelo y es dificilísimo de localizar.

**06 → S22. ¿Por qué leer byte a byte es mil veces más lento si el algoritmo es `O(n)`?**

⏱️ Porque cada operación es una llamada al sistema con coste fijo, y `O(n)` no cuenta eso.
🗣️ Medido: 1 879 ms byte a byte contra 0,17 ms en bloques de 64 KB sobre 3 MB. Once mil veces.
🔬 Desarrollo en `04 → 9`. Es el mejor ejemplo del corpus de que la notación asintótica esconde
constantes que deciden.

**06 → S23. ¿Qué tamaño de búfer usarías y por qué ese?**

⏱️ 64 KB si hay pocos flujos; 4 u 8 KB si hay muchos. La rodilla de la curva está en el tamaño de
página.
🗣️ Medido: 4 096 da 0,59 ms, 65 536 da 0,17 ms y 1 MB da 0,21 ms — ya peor.
🔬 Desarrollo en `04 → 8`, `04 → 11` y `04 → 23`. Con 20 000 conexiones, un búfer de 1 MB por conexión
son 20 GB: el tamaño deja de ser una decisión de rendimiento y pasa a ser de capacidad.

**06 → S24. Diferencia `flush` de `fsync`, y di a qué fallo sobrevive cada uno.**

⏱️ `flush` lleva del búfer de aplicación al núcleo y sobrevive a que muera tu proceso; `fsync` lleva al
disco y sobrevive al corte de luz.
🗣️ Tres niveles: mi búfer, la caché de página, el dispositivo. `write` sin error no garantiza ninguno
de los dos saltos.
🔬 Desarrollo en `04 → 12` y `04 → 13`. La pregunta de diseño es a cuál de los tres fallos necesitas
sobrevivir, y la respuesta cambia entre un log de diagnóstico y un archivo de confirmaciones de pago.

**06 → S25. ¿Cuánto cuesta `fsync` y por qué las bases de datos lo agrupan?**

⏱️ Cincuenta veces más, medido: mil escrituras pasan de 0,6 ms a 30,8 ms. Lo agrupan para repartir ese
coste entre muchas transacciones.
🗣️ En disco mecánico la diferencia es de tres órdenes de magnitud, porque cada `fsync` espera una
rotación física.
🔬 Desarrollo en `04 → 4` y `04 → 17`. El compromiso explícito es una ventana de milisegundos en la
que un corte puede perder las confirmaciones más recientes, y por eso los motores lo dejan configurar.

**06 → S26. ¿Qué es la contrapresión y qué pasa sin ella?**

⏱️ El mecanismo por el que el destino lento frena al origen rápido. Sin ella, la diferencia se acumula
en memoria hasta que el proceso muere.
🗣️ En Node es explícita —`write` devuelve `false` y hay que esperar `drain`—; en Java con flujos
clásicos, el propio bloqueo la implementa; en Go, un canal sin búfer es contrapresión pura.
🔬 Desarrollo en `04 → 7`, `04 → 14` y `04 → 21`. El síntoma típico: memoria que crece con el tráfico y
no con el número de peticiones, y que baja al terminar las transferencias.

**06 → S27. ¿Qué relación tiene con las colas acotadas del bloque `06`?**

⏱️ Es lo mismo visto desde la entrada y la salida: el límite de la cola **es** la señal que frena al
productor.
🗣️ Una `ArrayBlockingQueue` acotada bloquea al productor cuando se llena; el búfer de un flujo hace lo
mismo al alcanzar su umbral. En ambos casos el bloqueo es la funcionalidad.
🔬 Desarrollo en `04 → 20`. Una cola sin límite no protege de nada: traslada el fallo de "el productor
espera" a "el proceso muere sin memoria", que es peor porque ocurre más tarde y pierde todo.

**06 → S28. ¿Por qué un sistema de archivos no es un árbol?**

⏱️ Porque los enlaces simbólicos pueden apuntar a ancestros —ciclos— y los duros dan varios nombres al
mismo inodo.
🗣️ Con eso, la estructura es un grafo dirigido y recorrerlo tiene las obligaciones de cualquier grafo.
🔬 Desarrollo en `05 → 9`. Los enlaces duros a directorios están prohibidos precisamente para evitar
ciclos "duros"; los simbólicos sí pueden crearlos, y por eso el problema aparece solo si decides
seguirlos.

**06 → S29. ¿Cómo detectas un ciclo de enlaces y qué guardas en el conjunto de visitados?**

⏱️ Con el conjunto de visitados de siempre, guardando el par `(dispositivo, inodo)` y no la ruta.
🗣️ Las rutas no sirven: cada vuelta del ciclo genera una ruta distinta y el conjunto crece para
siempre sin coincidir nunca.
🔬 Desarrollo en `05 → 10`, `05 → 11` y `05 → 26`. Es la misma técnica de `04-arboles-grafos/03`, con
la diferencia de que aquí la identidad del nodo cuesta una llamada al sistema.

**06 → S30. ¿Qué hacen Java, Python y Go ante el mismo ciclo?**

⏱️ Java lo detecta y lanza `FileSystemLoopException`; Python se cuelga; Go no sigue enlaces, así que no
se plantea.
🗣️ Verificado con el mismo árbol. Tres comportamientos distintos, y ninguno está mal: hay que saber
cuál tienes delante.
🔬 Desarrollo en `05 → 6`, `05 → 12` y `05 → 24`. Como valor por defecto prefiero el de Java, por el
principio de fallar ruidosamente: un proceso colgado no aparece como error en ningún panel.

**06 → S31. ¿Por qué pedir el tamaño de cada archivo multiplica por cinco el recorrido?**

⏱️ Porque añade una llamada al sistema por archivo. Medido: 6,8 ms contra 31,9 ms sobre 10 000
archivos.
🗣️ Listar da nombres; todo lo demás —tamaño, fechas, permisos— es otra llamada.
🔬 Desarrollo en `05 → 17` y `05 → 18`. Es el principio del capítulo `04` aplicado a metadatos, y la
regla es la misma: no preguntes lo que no vas a usar.

**06 → S32. El entrevistador dice que hilo por conexión "está obsoleto". ¿Qué contestas?**

⏱️ Que escala perfectamente hasta cientos de conexiones y que ahí es la opción más simple y más
depurable.
🗣️ Lo que sí es cierto es que a partir de miles paga un coste que otros modelos no pagan: medido, 2 014
hilos y 240 MB para 2 000 conexiones frente a 35 hilos y 64 MB.
🔬 La respuesta que cierra sin confrontación: *"depende de la concurrencia objetivo; con la nuestra los
dos modelos dan lo mismo, y el bloqueante tiene veinte años de herramientas detrás"*. Y conceder lo
que es verdad —que con decenas de miles no vale— hace el argumento defendible.

**06 → S33. ¿Cuándo es correcto no usar búfer?**

⏱️ Cuando la latencia de lo que se ve primero importa más que el rendimiento agregado, y cuando ya
estás leyendo en bloques tú mismo.
🗣️ El error estándar no lleva búfer a propósito: un mensaje de error tiene que salir aunque el proceso
muera a continuación. Un registro interactivo se escribe por líneas por la misma razón.
🔬 Desarrollo en `04 → 26`. El otro caso legítimo es cuando tu código ya gestiona bloques grandes: un
`BufferedInputStream` sobre un flujo que lees de 1 MB en 1 MB solo añade una copia. Lo que nunca es
correcto es leer byte a byte sin búfer.

**06 → S34. Si todo IO es leer y escribir en un descriptor, ¿por qué hay tantas bibliotecas distintas?**

⏱️ Porque la interfaz es común y la semántica no, y porque hay que tapar las diferencias entre sistemas
operativos.
🗣️ `read` significa cosas distintas según el tipo; el modo no bloqueante solo aplica a algunos; Windows
usa otro modelo por completo. Una biblioteca portable tiene que cubrir todo eso.
🔬 Desarrollo en `02 → 9` y `02 → 22`. A eso se suma que cada biblioteca añade lo que el descriptor no
da: búferes, contrapresión, codificación de caracteres, reconexión y modelos de concurrencia. El
descriptor es el suelo, no el edificio.

**06 → S35. Te piden bajar la latencia de un servicio y el perfilador de CPU no encuentra nada. ¿Por dónde empiezas?**

⏱️ Por asumir que es espera y no cálculo, y por localizar **dónde** se espera.
🗣️ Un perfilador de CPU no ve lo que no consume CPU. Si la latencia es alta y la CPU baja, el tiempo se
va esperando: red, disco, un pool agotado o un pool de hilos nativo que el perfilador no instrumenta.
🔬 El orden que funciona: **(1)** comparar `user` y `sys` con el reloj —si los dos son bajos, es espera
pura—; **(2)** un volcado de hilos en el momento malo, que dice en qué están parados; **(3)** revisar
los pools del camino y compararlos con la concurrencia real, por `03 → 28`; **(4)** si es Node,
sospechar del pool de `libuv`, que ningún perfilador de JavaScript ve, por `02 → 18`; **(5)** trazas
distribuidas para ver qué salto se lleva el tiempo. Lo que **no** hay que hacer es optimizar el
código que el perfilador sí muestra, que es la reacción natural y en este caso es irrelevante.

**06 → S36. Si tuvieras que enseñar este bloque en cinco minutos, ¿qué dirías y qué dejarías fuera?**

⏱️ Diría tres cosas: el descriptor es un recurso finito que nadie mide, la pregunta siempre es qué hace
el hilo mientras espera, y el peaje se paga por cruce y no por byte.
🗣️ Las tres con su número: el servicio que se cae con memoria de sobra porque se agotaron los
descriptores; los 2 014 hilos contra 35 para el mismo trabajo; y los 1 879 ms contra 0,17 ms por
cambiar el tamaño del búfer.
🔬 Dejaría fuera los detalles de `io_uring`, la caché de página, el recorrido de directorios y la lista
de APIs por lenguaje, que se consultan. Lo que **no** dejaría fuera aunque apretara el tiempo es la
distinción entre interfaz y semántica del paradigma, porque es lo que evita el error de asumir que un
archivo y un socket se comportan igual — y ese error es el origen de la mitad de lo demás.

---

# 06 — Simulación: problemas de pizarra

**06 → P1. Copiar un flujo, bien.**

⏱️ Bucle de lectura con búfer, cierre determinista de los dos recursos y tolerancia a la lectura
parcial. `O(n)` en tiempo, `O(tamaño del búfer)` en memoria.
🗣️ **Los dos errores que se evalúan** hay que nombrarlos antes de teclear: leer una sola vez en lugar
de en bucle —falla con sockets, por `02 → 20`— y cerrar solo el destino o cerrar fuera de la
construcción que garantiza el cierre ante excepción.

```java
static long copiar(InputStream ent, OutputStream sal) throws IOException {
    byte[] buf = new byte[65536];          // 64 KB: el mínimo de la curva medida
    long total = 0;
    int n;
    while ((n = ent.read(buf)) != -1) {    // -1 es fin; n puede ser MENOR que buf.length
        sal.write(buf, 0, n);              // ...y por eso se escribe solo lo leído
        total += n;
    }
    sal.flush();
    return total;
}
// y en quien llama:
try (var ent = Files.newInputStream(origen); var sal = Files.newOutputStream(destino)) {
    copiar(ent, sal);
}
```
🔬 En Python son tres líneas con `with` anidados y `shutil.copyfileobj`, que ya hace este bucle — y
señalarlo es parte de la respuesta: **la biblioteca ya lo resuelve, y escribirlo a mano solo se
justifica como ejercicio**. Casos borde que hay que mencionar: `n` puede ser `0` sin ser fin;
`write` de un socket también puede escribir parcialmente y hay que iterar; el `flush` explícito hace
falta si el destino lleva búfer y no se cierra inmediatamente; y quien abre los recursos es quien los
cierra, así que `copiar` **no** los cierra — eso lo hace el `try-with-resources` de quien llama, por
`01 → 22`.

**06 → P2. El recorrido que no se cuelga.**

⏱️ Iterativo con pila explícita, conjunto de `(dispositivo, inodo)` para cortar ciclos, tope de
profundidad y errores capturados por entrada.
🗣️ **Lo que se evalúa es reconocer que esto es detección de ciclos**, y que la clave no es la ruta.
Quien guarda rutas visitadas no detecta nada, porque cada vuelta del ciclo genera una ruta nueva.
🔬 La solución completa, ejecutada sobre el árbol con ciclo del capítulo `05`, está en `05 → 26`:
termina y reporta cuatro directorios únicos. Las cuatro decisiones y su porqué —pila explícita,
`stat` en vez de `lstat` para la identidad, `scandir` para no pagar un `stat` extra, y errores
acumulados en vez de propagados— están desarrolladas allí. Lo que conviene añadir en la pizarra y no
está en el código: **si los enlaces vienen de datos de terceros, hay que comprobar además que el
destino sigue bajo la raíz permitida**, por `05 → 20`; sin eso, el recorrido es correcto y aun así
inseguro.

**06 → P3. El servidor, en tres modelos.**

⏱️ Predecir antes de medir: secuencial `N × t`, pool acotado `N/P × t`, no bloqueante o ligero `≈ t`.
🗣️ **La aritmética tiene que salir antes de ejecutar nada.** Con 50 conexiones y 100 ms:

```text
secuencial        50 × 100 ms  = 5 000 ms
pool de 8         50/8 × 100   =   625 ms
hilos/eventos     ≈ 100 ms + sobrecarga
```
Medido: **5 131 ms**, **727 ms** y entre **116 y 133 ms** según el modelo. Las tres predicciones
cuadran, y el pequeño exceso del pool —727 frente a 625— es la sobrecarga de reparto, que también hay
que saber explicar.
🔬 Lo que hace bueno el problema es lo que pasa cuando la predicción **no** cuadra: si el modelo no
acotado tardara mucho más de 100 ms, el cuello estaría en el generador de carga y no en el servidor
—por `03 → 30`—. La versión de 2 000 conexiones añade la lección de verdad: las latencias se parecen
y lo que separa a los modelos son los recursos, 2 014 hilos contra 35. Y un detalle de
implementación que se pregunta: el pool acotado **no es un error de configuración**, es correcto
cuando el trabajo es de CPU; lo que lo convierte en un problema es combinarlo con espera.

**06 → P4. El escritor duradero.**

⏱️ Añadir al final, `flush` más `fsync` **antes** de confirmar al cliente, y `fsync` del directorio al
crear el archivo. Coste medido: cincuenta veces.
🗣️ El diseño completo está en `04 → 27`. Lo que se evalúa en la pizarra son tres cosas: **el orden**
—confirmar después del `fsync`, nunca antes—, **el formato** —un registro por línea con longitud o
suma de verificación, porque un corte puede dejar un registro a medias— y **el directorio**, que
también hay que sincronizar la primera vez o el archivo puede no existir tras el corte.
🔬 La versión agrupada es la segunda mitad del problema y la que demuestra criterio: sincronizar cada
N milisegundos y confirmar en lote a los clientes de esa ventana, que es exactamente lo que hacen las
bases de datos. Lo que hay que decir al proponerla es **qué se pierde**: las confirmaciones de la
última ventana, y por tanto hay que elegir N con el negocio y no con el perfilador. Y una comprobación
que casi nadie menciona: **el diseño hay que probarlo cortando la corriente de verdad** —o matando el
proceso y la máquina virtual— porque es la única forma de saber que el archivo se puede releer.

**06 → P5. Los archivos duplicados.**

⏱️ Agrupar por tamaño primero y calcular el hash solo dentro de los grupos con más de uno. La fuerza
bruta acotada es la respuesta correcta.
🗣️ **La trampa es optimizar de más y también de menos.** Comparar los 124 750 pares byte a byte es
absurdo; calcular el hash criptográfico de los 500 archivos antes de mirar nada es hacer trabajo que
la mayoría de las veces sobra. El orden correcto es del filtro más barato al más caro:

```python
por_tam = {}
for a in archivos:
    por_tam.setdefault(os.path.getsize(a), []).append(a)
for grupo in (g for g in por_tam.values() if len(g) > 1):   # solo los que pueden ser iguales
    por_hash = {}
    for a in grupo:
        por_hash.setdefault(hash_de(a), []).append(a)
    ...
```
🔬 Medido sobre 500 archivos: **124 750 pares posibles, 40 grupos tras podar y 22 parejas idénticas en
11,4 ms**. En este conjunto concreto los tamaños colisionaban mucho y hubo que hashear los 500 — lo que
conviene decir en voz alta, porque **la ganancia de la poda depende de la distribución de tamaños** y
no es incondicional; aun así, 500 hashes frente a 124 750 comparaciones completas son dos órdenes de
magnitud. Las mejoras siguientes, en orden y solo si hacen falta: comparar los primeros kilobytes
antes del hash completo, y comparar byte a byte solo para confirmar si el hash no es criptográfico.
Y el límite que hay que nombrar: con 500 archivos esto es instantáneo; con millones, el coste pasa a
ser el recorrido y la entrada y salida, no la comparación — y entonces el problema es el del capítulo
`05`.

---

**Anterior:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
