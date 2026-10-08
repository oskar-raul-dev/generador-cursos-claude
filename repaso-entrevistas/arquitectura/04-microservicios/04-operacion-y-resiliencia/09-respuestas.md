# 09 — Respuestas: Operación y resiliencia

> Solucionario del bloque `04-operacion-y-resiliencia`. Cada respuesta va en tres capas:
> **⏱️ 30 segundos** lo que dices primero, **🗣️ 2 minutos** lo que añades cuando dicen "cuéntame
> más", y **🔬 El detalle** lo que estudias pero no dices en voz alta. El enunciado está copiado
> literalmente del capítulo: si no cuadra, manda el capítulo y este archivo está desactualizado.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--descubrimiento-y-enrutamiento) · [02](#02--api-gateway-y-bff) · [03](#03--resiliencia-en-la-práctica) · [04](#04--observabilidad-y-trazas) · [05](#05--service-mesh-y-sidecar) · [06](#06--despliegue-y-entrega) · [07](#07--testing-de-microservicios) · [08](#08--simulación-de-entrevista)

---

# 01 — Descubrimiento y enrutamiento

**01 → 1. ¿Qué problema resuelve el descubrimiento de servicios? 🟢**

⏱️ **30 segundos** — Que las direcciones de las instancias cambian con cada despliegue y cada
escalado, así que no se pueden escribir en la configuración.

🗣️ **2 minutos** — No basta con encontrar una dirección válida: hay que repartir entre las que hay y
dejar de mandar a las que ya no sirven, sin desplegar nada. El contrato entre servicios es el **nombre
lógico**, nunca una dirección.

🔬 **El detalle** — Históricamente se resolvía con un registro y una librería dentro de la aplicación;
hoy lo resuelve la plataforma. Saber por qué cambió —ya hay algo debajo que resuelve nombres— es parte
de la respuesta completa.

**01 → 2. Diferencia entre descubrimiento en el cliente y en el servidor. 🟢**

⏱️ **30 segundos** — En el cliente, la aplicación consulta el registro y elige instancia; en el
servidor, llama a un nombre estable y otro decide.

🗣️ **2 minutos** — El del cliente permite políticas finas —reparto por latencia, por zona— y evita un
salto, a cambio de una librería por plataforma y un registro que operar. El del servidor no requiere
escribir nada y depende de lo que sepa hacer el intermediario. Hoy gana el del servidor salvo
necesidades concretas.

🔬 **El detalle** — El caso que devuelve vigencia al del cliente es gRPC: como el balanceo por
conexión no reparte, el cliente balanceado vuelve a ser una opción razonable, junto con el proxy de
nivel 7 y el mesh.

**01 → 3. ¿Cuáles son las tres trampas del DNS en este contexto? 🟢**

⏱️ **30 segundos** — La caché del resolvedor, la caché del runtime y la resolución hecha una sola vez
al arrancar.

🗣️ **2 minutos** — La primera hace que se siga usando una dirección muerta hasta que expire el tiempo
de vida. La segunda es peor porque depende de la plataforma y a veces ignora ese tiempo. Y la tercera
es la más común: un cliente que resolvió al crearse y mantiene conexiones abiertas no vuelve a
preguntar nunca.

🔬 **El detalle** — El síntoma característico de la tercera es que el problema desaparece al reiniciar
el cliente. Si alguien describe un fallo que "se arregla reiniciando", esta es de las primeras
hipótesis a comprobar.

**01 → 4. ¿Por qué el registro "miente" durante unos segundos? 🟢**

⏱️ **30 segundos** — Porque entre que una instancia muere y el registro se entera pasa el tiempo de
varias sondas fallidas.

🗣️ **2 minutos** — Con sondeo cada cinco segundos y tres fallos tolerados, la ventana es de unos
quince. Durante ese tiempo el registro entrega direcciones que no responden. Por eso el
descubrimiento no sustituye a la resiliencia: hace falta timeout corto y reintento contra otra
instancia.

🔬 **El detalle** — Bajar el intervalo reduce la ventana pero aumenta la carga de sondeo y los falsos
positivos, que sacan de rotación instancias sanas por un pico momentáneo. Es un equilibrio, no un
valor que se pueda optimizar sin contrapartida.

**01 → 5. ¿Qué diferencia hay entre balancear por conexión y por llamada? 🟢**

⏱️ **30 segundos** — Por conexión se asigna una instancia al abrir y todas las llamadas de esa
conexión van ahí; por llamada se decide en cada petición.

🗣️ **2 minutos** — Con HTTP/1.1 y conexiones cortas la diferencia apenas se nota. Con HTTP/2 o gRPC,
donde una conexión multiplexa todas las llamadas, repartir conexiones equivale a no repartir: el
cliente abre una y se queda con su instancia durante horas.

🔬 **El detalle** — El caso peor es el escalado automático: las instancias nuevas no reciben tráfico
porque nadie abre conexiones hacia ellas, así que escalar no alivia nada. Es el fallo que convierte
un pico en un incidente.

**01 → 6. ¿Cuáles son las tres salidas al problema de balanceo con gRPC? 🟢**

⏱️ **30 segundos** — Balanceo en el cliente, proxy de nivel 7, o service mesh.

🗣️ **2 minutos** — El cliente balanceado resuelve todas las instancias y reparte él, sin salto extra,
a costa de librería y de reaccionar a los cambios. El proxy entiende HTTP/2 y reparte por llamada, con
un salto más. El mesh hace lo mismo con un sidecar y añade un plano de control que hay que operar.

🔬 **El detalle** — Hay una cuarta salida barata y poco elegante: limitar el tiempo de vida de las
conexiones para forzar redistribución periódica. No arregla el reparto instantáneo, pero evita el
desequilibrio permanente con muy poco trabajo.

**01 → 7. ¿Qué cambió para que el registro en la aplicación dejara de ser la respuesta por defecto? 🟢**

⏱️ **30 segundos** — Que la plataforma pasó a resolver nombres y a mantener el estado de las
instancias.

🗣️ **2 minutos** — Cuando no había orquestador, la aplicación tenía que registrarse y consultar un
registro, con una librería por lenguaje. Con una plataforma que ya sabe qué instancias están vivas y
da un nombre estable, ese registro es una pieza más que mantener sin necesidad, y en sistemas
políglotas evita tener cuatro librerías equivalentes.

🔬 **El detalle** — Conviene saber situar las herramientas de aquella época en su contexto en vez de
descartarlas: fueron la respuesta correcta a su problema, y en sistemas que no corren sobre un
orquestador siguen siéndolo.

**01 → 8. ¿Por qué el balanceo por conexión no reparte el tráfico de HTTP/2? 🟡**

⏱️ **30 segundos** — Porque HTTP/2 multiplexa muchas llamadas sobre una sola conexión persistente.

🗣️ **2 minutos** — El balanceador ve una conexión y la asigna una vez; todo lo que viaje por ella irá a
la misma instancia, sean diez llamadas o un millón. Desde su punto de vista está repartiendo
correctamente, y por eso sus métricas no muestran ningún problema mientras una instancia se satura.

🔬 **El detalle** — El síntoma es inconfundible: una instancia con CPU alta y las demás ociosas. Como
las métricas del balanceador están verdes, el diagnóstico suele empezar buscando en el código de la
instancia saturada, que es el sitio equivocado.

**01 → 9. ¿Por qué el descubrimiento no sustituye al timeout y al reintento? 🟡**

⏱️ **30 segundos** — Porque siempre hay una ventana en la que el registro entrega instancias que ya no
responden.

🗣️ **2 minutos** — Durante esos segundos, las llamadas a la instancia muerta se quedan esperando si no
hay timeout, y se pierden si no hay reintento contra otra. El descubrimiento reduce la probabilidad
de acertar mal, no la elimina. Por eso ambos mecanismos son complementarios y no alternativos.

🔬 **El detalle** — El reintento aquí tiene una condición: debe ir contra **otra** instancia, no
contra la misma. Un reintento que repite el destino no arregla nada cuando el problema es que esa
instancia está muerta.

**01 → 10. ¿Qué papel juega el tiempo de vida máximo de una conexión en el reequilibrio? 🟡**

⏱️ **30 segundos** — Es el mecanismo que fuerza a los clientes a volver a resolver y a repartirse entre
las instancias actuales.

🗣️ **2 minutos** — Sin caducidad, una conexión puede vivir horas y el cliente seguirá hablando con la
misma instancia aunque hayan aparecido cinco más. Con un tiempo de vida máximo razonable, el tráfico
se redistribuye solo, sin necesidad de mesh ni de cliente balanceado.

🔬 **El detalle** — El valor tiene que equilibrarse con el coste de reconectar, sobre todo en HTTPS
donde cada conexión nueva paga el saludo TLS. En la práctica, del orden de minutos suele ser un buen
punto de partida, y conviene escalonarlo con jitter para que no reconecten todos a la vez.

**01 → 11. ¿Por qué un cliente creado al arrancar puede hablar con instancias muertas? 🟡**

⏱️ **30 segundos** — Porque resolvió la dirección una vez y, con conexiones persistentes, no vuelve a
preguntar.

🗣️ **2 minutos** — Es la tercera trampa del DNS y afecta a las cuatro plataformas con matices
distintos. La defensa es doble: clientes que re-resuelven y caducidad de conexiones. Y la
comprobación es empírica: matar una instancia y ver cuánto tarda el cliente en dejar de mandarle
tráfico.

🔬 **El detalle** — Es especialmente traicionero con clientes creados como singleton en el arranque,
que es la forma recomendada por rendimiento. La recomendación sigue siendo buena; lo que hay que
añadir es la configuración de caducidad.

**01 → 12. ¿Por qué bajar el intervalo de sondeo no es gratis? 🟡**

⏱️ **30 segundos** — Porque multiplica el tráfico de sondas y aumenta los falsos positivos.

🗣️ **2 minutos** — Con cientos de instancias, sondear cada segundo genera carga constante sobre los
servicios y sobre el plano de control. Y un pico momentáneo de latencia puede hacer fallar la sonda y
sacar de rotación una instancia sana, lo que reduce capacidad justo cuando el sistema está bajo
presión.

🔬 **El detalle** — Por eso la sonda de disponibilidad debe ser barata y no depender de dependencias
externas: si consulta la base de datos, un pico de la base saca de rotación todas las instancias a la
vez, que es el fallo descrito en el capítulo del servicio por dentro.

**01 → 13. ¿Qué pasa con las conexiones abiertas durante un despliegue gradual, y cómo se mitiga? 🟡**

⏱️ **30 segundos** — Se cortan cuando muere la instancia; se mitiga con apagado ordenado y avisando
al cliente antes de cerrar.

🗣️ **2 minutos** — La instancia debe dejar de aceptar conexiones nuevas, terminar lo que tiene en
curso y cerrar avisando —con la señal correspondiente del protocolo— para que el cliente reconecte
contra otra en vez de ver un error. Y el cliente debe reintentar contra otra instancia los fallos de
conexión, que son inequívocamente seguros de reintentar.

🔬 **El detalle** — Con HTTP/2 hay un mecanismo específico de aviso de cierre que permite al cliente
terminar lo que tiene en vuelo y no enviar nada nuevo por esa conexión. Si el servidor cierra sin
usarlo, el cliente ve errores en llamadas que ya estaban en curso.

**01 → 14. Tras un despliegue, algunos clientes fallan y otros no, y se arregla al reiniciarlos. Diagnostica. 🟠**

⏱️ **30 segundos** — Caché de resolución o conexiones persistentes: los clientes afectados siguen
apuntando a instancias que ya no existen.

🗣️ **2 minutos** — El patrón "se arregla al reiniciar" apunta directamente a estado en memoria del
cliente. Se confirma comparando a qué direcciones están conectados los clientes sanos y los
afectados. La corrección es configurar caducidad de conexiones y revisar la caché de DNS del runtime,
que es distinta en cada plataforma.

🔬 **El detalle** — Un detalle que ayuda a distinguirlo de otros fallos: si el reinicio del **cliente**
lo arregla y el reinicio del servicio destino no, el problema está del lado del cliente casi con
seguridad.

**01 → 15. Tienes tres instancias y una recibe todo el tráfico gRPC. Da dos soluciones con su coste. 🟠**

⏱️ **30 segundos** — Balanceo en el cliente —sin salto extra, con librería por plataforma— o proxy de
nivel 7 —sin tocar el código, con un salto más—.

🗣️ **2 minutos** — El cliente balanceado resuelve todas las instancias y reparte llamada a llamada;
hay que implementarlo en cada plataforma y reaccionar a los cambios de instancias. El proxy no exige
cambios en la aplicación y añade latencia de un salto. Y como medida inmediata, limitar la vida de
las conexiones para forzar redistribución.

🔬 **El detalle** — Antes de elegir conviene comprobar si el problema es solo de conexiones o también
de número de clientes: con pocos clientes y muchas instancias, ni siquiera el reparto por conexión
llega a cubrir todas. En ese caso el cliente balanceado es la única solución completa.

**01 → 16. ¿Cuánto tarda tu sistema en dejar de mandar tráfico a una instancia muerta? Descompón la cuenta. 🟠**

⏱️ **30 segundos** — Ventana del registro, más caché de DNS, más vida de las conexiones ya abiertas.

🗣️ **2 minutos** — La cuenta:

```text
sondeo × fallos tolerados        p. ej. 5 s × 3 = 15 s   (el registro se entera)
+ tiempo de vida de DNS          p. ej. 30 s              (el cliente re-resuelve)
+ vida de conexiones abiertas    p. ej. hasta el máximo configurado
= tiempo real hasta dejar de enviar
```

Y la conclusión práctica: sin caducidad de conexiones, ese último sumando es infinito, y da igual lo
rápido que sea el registro.

🔬 **El detalle** — Es una pregunta excelente para hacerle a un equipo en una entrevista al revés: casi
nadie la sabe, y la conversación que genera revela enseguida cuánto se ha pensado la operación del
sistema.

**01 → 17. El escalado automático añade instancias y no reciben carga. Explica y corrige. 🟠**

⏱️ **30 segundos** — Los clientes tienen conexiones persistentes ya establecidas y no abren nuevas.
Se corrige con caducidad de conexiones o balanceo por llamada.

🗣️ **2 minutos** — Es el caso más dañino del balanceo por conexión: escalas para aliviar y no alivias
nada, porque el tráfico sigue yendo a las instancias antiguas. La corrección inmediata es forzar
reciclado de conexiones; la estructural, repartir por llamada con proxy, mesh o cliente balanceado.

🔬 **El detalle** — Conviene además revisar la métrica que dispara el escalado: si es CPU media de
todas las instancias, el desequilibrio la enmascara —una al 90 % y dos al 10 % dan una media
tranquilizadora—. Alertar sobre el máximo, y no sobre la media, detecta el problema antes.

**01 → 18. ¿Cuándo justificarías balanceo en el cliente hoy? 🟠**

⏱️ **30 segundos** — Con gRPC sin proxy L7 ni mesh, o cuando necesitas políticas de reparto que el
intermediario no da.

🗣️ **2 minutos** — Ejemplos de políticas que lo justifican: preferir instancias de la misma zona para
ahorrar latencia y coste, repartir por latencia observada, o aplicar reintentos con conocimiento de
qué instancia falló. Fuera de esos casos, el coste de mantener la librería en cada plataforma no se
paga.

🔬 **El detalle** — En un sistema políglota el argumento se vuelve más fuerte en contra: cuatro
implementaciones equivalentes que hay que mantener al día. Es uno de los sitios donde el mesh tiene
su mejor argumento, precisamente porque iguala las cuatro plataformas.

**01 → 19. ¿Qué configuración de cliente HTTP revisarías en las cuatro plataformas por este tema? 🟠**

⏱️ **30 segundos** — La caché de resolución del runtime y el tiempo de vida máximo de las conexiones
del pool.

🗣️ **2 minutos** — En Java, la política de caché de DNS de la JVM, que puede ser mucho más larga de lo
esperado según la configuración. En las otras tres, la caducidad de conexiones del pool, que casi
siempre viene sin límite. Y en todas, si el cliente es un singleton creado al arrancar —que debe
serlo— hay que asegurarse de que re-resuelve.

🔬 **El detalle** — Es una comprobación que conviene incluir en el chassis y en la lista de "listo
para producción": es de las que nadie hace hasta que ha vivido el incidente, y cuesta una línea de
configuración por plataforma.

**01 → 20. Un equipo quiere montar un registro propio en la aplicación. Argumenta. 🟠**

⏱️ **30 segundos** — Si hay orquestador debajo, es duplicar lo que la plataforma ya hace, con una
librería por plataforma que mantener.

🗣️ **2 minutos** — El registro propio exige que cada servicio se registre y dé latidos, y que cada
cliente consulte y reaccione; en un sistema políglota son cuatro implementaciones. La plataforma ya
mantiene el estado de las instancias a partir de las sondas y ofrece nombres estables. La excepción
es que el reparto fino sea un requisito real, y entonces la conversación es sobre balanceo, no sobre
descubrimiento.

🔬 **El detalle** — Si el sistema **no** corre sobre un orquestador —máquinas virtuales gestionadas a
mano, por ejemplo—, el registro propio vuelve a ser razonable. Conviene preguntar por el entorno antes
de responder, porque la respuesta correcta depende de él.

**01 → 21. Diseña el camino completo de una llamada de `orders` a `inventory`: resolución, reparto, reintento y qué ocurre en cada fallo posible. 🔴**

⏱️ **30 segundos** — Nombre lógico → resolución con caducidad → reparto por llamada → timeout corto →
reintento contra otra instancia → circuit breaker si falla el conjunto.

🗣️ **2 minutos** — El camino y sus fallos:

```text
Paso                        Si falla                      Qué lo cubre
──────────────────────────  ────────────────────────────  ─────────────────────────
resolver nombre             no resuelve                   reintento; alerta de DNS
elegir instancia            lista desfasada               reintento contra OTRA instancia
conectar                    conexión rechazada            seguro de reintentar: instancia muerta
enviar y esperar            timeout                       NO reintentar si no es idempotente
                                                          (puede haberse ejecutado)
respuesta                   error 5xx                     reintento con backoff, según código
conjunto degradado          muchos fallos seguidos        circuit breaker: dejar de intentar
```

🔬 **El detalle** — La línea clave es la del timeout: un fallo de conexión es seguro de reintentar
porque la petición no llegó; un timeout no lo es, porque pudo ejecutarse y perderse la respuesta.
Distinguir ambos casos en el código del cliente es lo que evita duplicar efectos.

**01 → 22. Diagnostica: el p99 de una ruta se dispara solo durante los despliegues de la dependencia. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Falta apagado ordenado en la dependencia; conexiones que se cortan sin aviso; o
ausencia de reintento en el cliente.

🗣️ **2 minutos** — Las tres:

```text
1. Sin apagado ordenado      la instancia muere con peticiones en vuelo → errores y
   en la dependencia         reintentos; el p99 sube justo en la ventana de reemplazo
2. Cierre sin aviso          las conexiones persistentes se cortan de golpe;
                             las llamadas en curso fallan y hay que reconectar
3. Cliente sin reintento     cada llamada que cae en una instancia que se está
                             apagando se convierte en error visible, sin segunda
                             oportunidad contra otra instancia
```

Se distinguen mirando si hay errores además de latencia —1 y 2— o solo latencia —posible saturación de
las instancias que quedan durante el reemplazo—.

🔬 **El detalle** — Hay una cuarta causa relacionada: durante el reemplazo hay menos capacidad, así
que si el sistema va justo, el p99 sube sin que nadie haya hecho nada mal. Se comprueba mirando si el
efecto aparece también cuando el despliegue va bien, y se corrige con margen de capacidad o
reemplazos más lentos.

**01 → 23. Diseña la política de conexiones y resolución del chassis del equipo, con los valores que dependen de la plataforma. 🔴**

⏱️ **30 segundos** — Caducidad de conexión, límite de conexiones por destino, y caché de resolución
acotada, con los valores concretos por plataforma.

🗣️ **2 minutos** — La política:

```text
Común                        Por plataforma
──────────────────────────   ─────────────────────────────────────────────
vida máx. de conexión con    Java: revisar además la caché de DNS de la JVM
jitter (minutos)             Node: caducidad del pool del cliente HTTP
                             Go: MaxConnLifetime/IdleTimeout en el Transport
máx. conexiones por destino  Python: límites del pool del cliente
re-resolución al reconectar
reintento en fallo de conexión (siempre seguro)
sin reintento automático en timeout (depende de idempotencia)
```

🔬 **El detalle** — El jitter en la caducidad es importante y se olvida: si todas las conexiones
caducan al mismo tiempo, se produce una oleada de reconexiones simultáneas con su correspondiente
saludo TLS, que puede verse como un pico de latencia periódico difícil de explicar.

**01 → 24. Tu sistema va a migrar a gRPC. Escribe la lista de comprobaciones de infraestructura previas y qué harías si alguna falla. 🔴**

⏱️ **30 segundos** — HTTP/2 de punta a punta, balanceo por llamada, observabilidad adaptada, y
caducidad de conexiones.

🗣️ **2 minutos** — La lista:

```text
Comprobación                        Si falla
──────────────────────────────────  ────────────────────────────────────────
HTTP/2 en todo el camino            no migrar hasta resolverlo; un proxy
(proxies, balanceadores, WAF)       intermedio que degrade rompe gRPC
Balanceo por llamada                cliente balanceado, proxy L7 o mesh;
                                    si nada es viable, aplazar la migración
Paneles y alertas por código        adaptar antes de migrar: los paneles basados
gRPC                                en códigos HTTP dejarán de ver los errores
Caducidad de conexiones             configurarla; con gRPC las conexiones son
                                    aún más persistentes que con HTTP/1.1
Registro de esquemas y gobierno     sin dueño del contrato, el beneficio principal
                                    de gRPC se diluye
```

🔬 **El detalle** — El orden importa: el balanceo debe estar resuelto **antes** de mover tráfico real,
porque es el único fallo de la lista que no se manifiesta en pruebas —con poca carga, el desequilibrio
no se nota— y sí en el primer pico de producción.

---

# 02 — API gateway y BFF

**02 → 1. ¿Qué responsabilidades tiene un API gateway? 🟢**

⏱️ **30 segundos** — TLS, autenticación, límite de tasa, enrutado, observabilidad del borde y
políticas uniformes como CORS.

🗣️ **2 minutos** — Todo eso son cosas que, sin gateway, cada servicio tendría que resolver por su
cuenta y cada consumidor externo tendría que conocer. Concentrarlas en el borde evita repetir
certificados, validaciones y configuración en cinco sitios, y oculta la topología interna a quien nos
consume.

🔬 **El detalle** — Es infraestructura, no arquitectura de aplicación: el gateway se configura, no se
programa. En cuanto alguien escribe lógica dentro, conviene preguntarse si eso no pertenece a un
servicio.

**02 → 2. ¿Qué no debe hacer nunca un gateway? 🟢**

⏱️ **30 segundos** — Lógica de negocio, transformaciones que conocen el dominio, u orquestación de
flujos.

🗣️ **2 minutos** — En cuanto necesita entender el significado del mensaje, deja de ser borde. El
síntoma es organizativo antes que técnico: para cambiar una regla hay que entrar en la cola del
equipo de plataforma, que se convierte en cuello de botella de todos los demás.

🔬 **El detalle** — La excepción tolerada es temporal: componer o adaptar respuestas durante una
migración para no romper a un cliente. Se acepta con fecha y con dueño, igual que cualquier otra deuda
declarada.

**02 → 3. ¿Qué es un BFF y quién debe poseerlo? 🟢**

⏱️ **30 segundos** — Un servicio por experiencia de cliente que adapta el sistema a esa experiencia, y
lo posee el equipo de esa experiencia.

🗣️ **2 minutos** — La web pide mucho detalle en una llamada, el móvil quiere cargas pequeñas, los
socios quieren estabilidad durante años. Un BFF por cada uno permite servir bien a los tres sin un
contrato genérico que no sirva bien a ninguno. Y la propiedad es lo que define el patrón: si lo
mantiene plataforma, vuelve a ser genérico.

🔬 **El detalle** — La consecuencia organizativa es que el equipo de frontend necesita poder operar un
servicio: despliegue, alertas, guardia. Si no puede, el BFF se degrada igualmente, y conviene decirlo
antes de proponerlo.

**02 → 4. Diferencia entre gateway, BFF y agregador. 🟢**

⏱️ **30 segundos** — El gateway enruta y aplica política de borde; el BFF adapta el sistema a una
experiencia; el agregador junta datos de varios servicios para una vista.

🗣️ **2 minutos** — Hay uno solo de gateway, uno por experiencia de BFF, y tantos agregadores como
vistas lo necesiten. El gateway no conoce el dominio; el BFF y el agregador sí. Y un BFF es, entre
otras cosas, un agregador, mientras que un gateway no debería serlo.

🔬 **El detalle** — La composición ligera —dos llamadas y juntar, sin reglas— puede vivir en el
gateway sin daño. La frontera no es "componer o no", es si hace falta conocer el significado de los
datos para hacerlo.

**02 → 5. ¿Qué se hace en el borde y qué dentro, en cuanto a identidad? 🟢**

⏱️ **30 segundos** — En el borde se valida la credencial y se traduce a identidad interna; dentro se
autoriza: si ese usuario puede hacer eso.

🗣️ **2 minutos** — Validar una vez evita repetir la verificación criptográfica en cinco servicios.
Pero la autorización depende del dominio —"solo puedes ver tus pedidos"— y por eso vive en el
servicio dueño. Y cada servicio debe poder verificar la identidad que recibe, no aceptarla a ciegas.

🔬 **El detalle** — Confiar en un encabezado sin verificación convierte a cualquiera que alcance la red
interna en cualquier usuario. El desarrollo de cómo se propaga y se verifica la identidad —tokens
internos, mTLS— pertenece al corpus de arquitectura, pero el principio se decide aquí.

**02 → 6. ¿Qué decisiones hay que tomar al configurar un límite de tasa? 🟢**

⏱️ **30 segundos** — Por quién se limita, qué se limita, qué se devuelve y qué queda exento.

🗣️ **2 minutos** — Por consumidor identificado si se puede, por IP si no hay más. Limitar concurrencia
protege mejor que limitar ritmo. Se devuelve `429` con `Retry-After`, porque sin él el cliente
reintenta a ciegas. Y hay que eximir lo que empeora el incidente si se limita: salud y autenticación.

🔬 **El detalle** — Limitar por IP falla con proxies y con NAT: un cliente corporativo entero puede
aparecer como una sola dirección y consumir el límite de todos sus usuarios. Es útil como última
defensa, no como criterio principal.

**02 → 7. ¿Por qué la propiedad del BFF es más importante que su tecnología? 🟡**

⏱️ **30 segundos** — Porque el patrón existe para que el contrato de una experiencia pueda cambiar al
ritmo de esa experiencia, y eso solo ocurre si lo mantiene su equipo.

🗣️ **2 minutos** — Si lo posee otro equipo, cada cambio de pantalla entra en una cola ajena, los
plazos se alargan y el BFF empieza a generalizarse para contentar a varios. En ese momento ya no es un
BFF: es un servicio de fachada genérico con otro nombre.

🔬 **El detalle** — De ahí se deriva la elección de plataforma, no al revés: si lo mantiene el equipo
de frontend, lo natural es que sea Node/TS, porque comparten lenguaje, tipos y herramientas. La
tecnología es consecuencia de la propiedad.

**02 → 8. ¿Por qué "ya lo valida el gateway" es una frase peligrosa? 🟡**

⏱️ **30 segundos** — Porque convierte la red interna en una frontera de confianza: cualquiera que
llegue a un servicio puede hacerse pasar por cualquier usuario.

🗣️ **2 minutos** — El gateway filtra el tráfico no autenticado desde fuera, pero no protege contra
llamadas internas —un servicio comprometido, un error de configuración que expone un puerto, alguien
con acceso a la red—. Cada servicio debe verificar la identidad que recibe y aplicar su propia
autorización.

🔬 **El detalle** — El coste de hacerlo bien es bajo: verificar una firma es barato, y la autorización
ya tiene que estar en el servicio porque depende del dominio. Lo que se ahorra confiando ciegamente es
poco comparado con lo que se arriesga.

**02 → 9. ¿Por qué limitar por concurrencia protege mejor que limitar por ritmo? 🟡**

⏱️ **30 segundos** — Porque lo que agota los recursos son las peticiones **simultáneas**, no las
peticiones por minuto.

🗣️ **2 minutos** — Mil peticiones por minuto repartidas uniformemente no molestan; mil a la vez agotan
hilos y conexiones. El límite de concurrencia refleja directamente la capacidad real del sistema, y
se adapta solo cuando las peticiones tardan más: si cada una dura el doble, caben la mitad a la vez.

🔬 **El detalle** — El límite por ritmo sigue siendo útil para proteger de abuso y para facturación,
así que no es uno u otro. Pero si solo se puede tener uno para proteger el sistema, la concurrencia
es el que se corresponde con el recurso que se agota.

**02 → 10. ¿Qué diferencia hay entre composición ligera y composición con reglas, y por qué importa? 🟡**

⏱️ **30 segundos** — La ligera junta respuestas sin interpretarlas; la que tiene reglas necesita
conocer el dominio, y eso no es del borde.

🗣️ **2 minutos** — Llamar a dos servicios y devolver ambos resultados no requiere entender qué
significan. Decidir qué descuento aplicar o si un pedido es válido, sí. La primera puede vivir en el
gateway; la segunda pertenece a un BFF o a un servicio con dueño, porque va a cambiar cuando cambie
el negocio.

🔬 **El detalle** — La prueba práctica: ¿quién despliega cuando cambia una regla de negocio? Si la
respuesta es "el equipo del gateway", la composición tenía reglas dentro aunque no lo pareciera.

**02 → 11. ¿Por qué un BFF por experiencia no es duplicar código? 🟡**

⏱️ **30 segundos** — Porque lo que se repite es composición y adaptación, no dominio: las reglas siguen
viviendo en los servicios.

🗣️ **2 minutos** — Cada BFF llama a los mismos servicios y arma respuestas distintas para clientes
distintos. Unificarlos produce un contrato que intenta servir a todos y sirve mal a cada uno, con
campos opcionales por todas partes y versiones que nadie puede retirar porque alguien las usa.

🔬 **El detalle** — Sí conviene compartir lo técnico entre BFF —cliente HTTP configurado, propagación
de traza, formato de error—, que es exactamente el chassis. Lo que no se comparte es la forma de las
respuestas, que es justo lo que los diferencia.

**02 → 12. ¿Por qué el gateway se convierte en cuello de botella organizativo? 🟡**

⏱️ **30 segundos** — Porque está en el camino de todo, así que cualquier cosa que se ponga ahí la
tiene que cambiar su equipo.

🗣️ **2 minutos** — Empieza con una validación común y acaba con reglas de negocio de varios dominios.
Como es un componente crítico, sus cambios se revisan y se despliegan con cuidado, lo que alarga los
plazos. El resultado es que equipos que deberían ser autónomos dependen de una cola que no controlan.

🔬 **El detalle** — El remedio no es solo técnico: además de devolver las reglas a los servicios,
conviene permitir a los equipos proponer cambios de configuración de su propia ruta por pull request,
con revisión de plataforma. Así se descongestiona sin perder control.

**02 → 13. ¿Qué exime del límite de tasa y por qué? 🟡**

⏱️ **30 segundos** — Los endpoints de salud y los de autenticación, porque limitarlos agrava el
incidente en vez de aliviarlo.

🗣️ **2 minutos** — Si se limita la salud, la plataforma puede considerar caídas instancias sanas y
reducir capacidad justo cuando hace falta. Si se limita el login durante un pico, los usuarios no
pueden entrar y reintentan más, amplificando el problema. También conviene eximir el tráfico interno
de sondas y de herramientas de operación.

🔬 **El detalle** — La excepción a la excepción: el login sí necesita protección contra abuso —fuerza
bruta—, pero eso es un límite por credencial o por origen, distinto del límite general de capacidad.
Conviene distinguir ambos objetivos en vez de mezclarlos en una sola regla.

**02 → 14. ¿Por qué el BFF de la web suele escribirse en Node/TS, y cuándo ese argumento deja de valer 🟡**

⏱️ **30 segundos** — Porque comparte lenguaje y tipos con el cliente que lo consume y lo mantiene el
mismo equipo. Deja de valer cuando ese equipo no puede operarlo.

🗣️ **2 minutos** — El argumento no es de rendimiento: es de propiedad y de contrato. Con el BFF en
Node/TS, el equipo de frontend cambia la carga de su pantalla sin abrir un ticket a nadie, los tipos
del contrato se verifican en su mismo pipeline y el cambio viaja en un solo despliegue. Es el
poliglotismo mejor justificado del corpus. Deja de valer en dos casos: cuando el equipo de frontend no
puede asumir guardias ni operación —entonces el BFF lo posee backend y se escribe en lo que ese equipo
domina—, y cuando el BFF hace transformación pesada, porque el hilo único la paga cara.

🔬 **El detalle** — Java sirve para un BFF si el equipo es de backend, con la advertencia de arranque y
memoria cuando escala mucho; Go da eficiencia y poca ayuda de marco; Python encaja cuando el consumidor
es de analítica. El orden de la decisión es siempre el mismo: primero quién lo posee, después en qué se
escribe.

---
**02 → 15. El equipo de plataforma tiene tres meses de cola por cambios en el gateway. ¿Qué propones? 🟠**

⏱️ **30 segundos** — Devolver las reglas a los servicios dueños, empezando por las que más cambian, y
permitir cambios por pull request mientras tanto.

🗣️ **2 minutos** — La cola misma dice por dónde empezar: las reglas que generan más peticiones de
cambio son las primeras en moverse. En paralelo, abrir el repositorio de configuración del gateway
para que cada equipo proponga sus rutas alivia la presión sin esperar al rediseño. Y se fija la
frontera por escrito para que no vuelvan a entrar.

🔬 **El detalle** — Hay una parte que no se arregla con arquitectura: el equipo de plataforma tiene
que aceptar dejar de decidir. Si no hay ese acuerdo explícito, las reglas vuelven al gateway en unos
meses por la puerta de atrás.

**02 → 16. El móvil necesita cargas más pequeñas que la web. ¿Cómo lo resuelves? 🟠**

⏱️ **30 segundos** — Con un BFF móvil que devuelva exactamente lo que esa aplicación necesita.

🗣️ **2 minutos** — Las alternativas —parámetros de selección de campos, varias representaciones del
mismo recurso— acaban complicando el contrato común para todos. Un BFF permite además agrupar en una
sola llamada lo que en la web son tres, que en redes móviles importa más que el tamaño. Y le da al
equipo móvil control sobre su propio contrato.

🔬 **El detalle** — El móvil tiene una restricción que la web no tiene: los usuarios no actualizan. Su
BFF debe mantener compatibilidad mucho más tiempo, y eso es más fácil de gestionar en un servicio
dedicado que en un contrato compartido con la web.

**02 → 17. ¿Cómo evitas que el BFF se convierta en un monolito de pantallas? 🟠**

⏱️ **30 segundos** — Manteniéndolo sin estado y sin reglas de dominio: compone, adapta y poco más.

🗣️ **2 minutos** — Las señales de alarma son que el BFF empiece a tener su propia base de datos, que
aparezcan reglas de negocio dentro, o que crezca hasta que nadie sepa qué pantallas usa cada endpoint.
La defensa práctica es revisar periódicamente qué hay dentro y mover al servicio dueño cualquier regla
que se haya colado.

🔬 **El detalle** — Un BFF con caché propia todavía es defendible; uno con datos que no existen en
ningún otro sitio ya no lo es, porque se ha convertido en un servicio de dominio sin reconocerlo. Esa
es la línea que conviene vigilar.

**02 → 18. ¿Qué haces si el equipo de frontend no puede operar un servicio? 🟠**

⏱️ **30 segundos** — O se le da el apoyo para que pueda, o no se monta el BFF y se busca otra
solución.

🗣️ **2 minutos** — El apoyo es concreto: plantilla de servicio, pipeline, paneles y alertas listos, y
acompañamiento en las primeras guardias. Si eso no es viable, las alternativas son que plataforma lo
opere con el frontend como dueño del contenido —peor, pero funciona— o resolver las necesidades con
endpoints a medida en los servicios.

🔬 **El detalle** — Montar un BFF que nadie opera es peor que no tenerlo: añade un punto de fallo en el
camino de toda la experiencia y, cuando falle de madrugada, no habrá quien sepa diagnosticarlo. La
capacidad operativa es un requisito, no un detalle.

**02 → 19. Un socio externo consume tu API interna. ¿Qué cambias? 🟠**

⏱️ **30 segundos** — Le pongo delante un contrato propio, estable y versionado, y dejo de exponer el
interno.

🗣️ **2 minutos** — Un socio no puede desplegar cuando tú quieras ni entender tu modelo interno. Lo que
necesita es un contrato pensado para él, con compatibilidad larga, documentación y un proceso de aviso
de cambios. Eso es un BFF de socios o una API pública, con su propio ciclo de vida.

🔬 **El detalle** — También cambian los requisitos no funcionales: límite de tasa por socio,
credenciales propias, auditoría de quién llamó a qué, y a veces acuerdos de nivel de servicio. Nada
de eso encaja en una API interna, y ese es el argumento decisivo para separarlas.

**02 → 20. El gateway se cae y no entra nada. ¿Qué medidas de diseño lo mitigan? 🟠**

⏱️ **30 segundos** — Varias instancias en varias zonas, configuración simple y probada, y un camino de
emergencia para el tráfico crítico.

🗣️ **2 minutos** — El gateway es crítico por definición, así que se despliega redundante y se prueba
su fallo. Conviene además que su configuración sea lo más estática posible —cuanta más lógica, más
formas de romperse— y tener previsto cómo enrutar el tráfico esencial si el gateway no está, aunque
sea con una configuración de emergencia.

🔬 **El detalle** — Una causa frecuente de caída del gateway no es la carga sino un despliegue de
configuración erróneo. Por eso conviene tratar su configuración como código: revisión, validación
automática y despliegue gradual con vuelta atrás rápida.

**02 → 21. ¿Cómo decides entre gateway gestionado y gateway de código abierto? 🟠**

⏱️ **30 segundos** — Gestionado si quieres menos operación y su modelo te encaja; de código abierto si
necesitas control fino o portabilidad.

🗣️ **2 minutos** — El gestionado elimina el trabajo de operar, escalar y parchear, a cambio de atarte
a su modelo de configuración y a su facturación. El de código abierto da control total y te obliga a
operarlo. La pregunta decisiva suele ser si el equipo tiene capacidad operativa disponible, no cuál
tiene más funciones.

🔬 **El detalle** — Conviene mirar también cómo se versiona y se despliega la configuración en cada
opción, porque es donde vas a pasar el tiempo: un gateway con configuración en código revisable es
mucho más manejable que uno que se configura por consola, sea gestionado o no.

**02 → 22. Diseña el borde de un sistema con web, móvil y dos socios: qué piezas hay, quién las posee y qué contrato expone cada una. 🔴**

⏱️ **30 segundos** — Un gateway común, un BFF para web, otro para móvil, y una API de socios
versionada; cada pieza con su dueño.

🗣️ **2 minutos** — El diseño:

```text
Pieza          Dueño                Contrato                 Notas
─────────────  ───────────────────  ───────────────────────  ─────────────────────────
gateway        plataforma           ninguno propio           TLS, auth, límite, enrutado
BFF web        equipo web           a medida, cambia rápido  compone y recorta
BFF móvil      equipo móvil         a medida, muy estable    cargas pequeñas, menos llamadas
API socios     equipo de producto   versionada, largo plazo  credenciales y límites por socio,
                                                             auditoría, documentación
```

Todos pasan por el gateway; ninguno expone el contrato interno; y las reglas de negocio viven en los
servicios detrás.

🔬 **El detalle** — La API de socios es la que más disciplina exige: compatibilidad de años, proceso
de aviso de cambios y auditoría de uso. Conviene que sea un producto con dueño de producto, no un
subproducto del BFF web, porque sus ritmos son incompatibles.

**02 → 23. Un equipo propone que el gateway componga las respuestas de cinco servicios y aplique descuentos. Responde con alternativas concretas. 🔴**

⏱️ **30 segundos** — La composición puede discutirse; los descuentos no: son dominio y pertenecen a un
servicio.

🗣️ **2 minutos** — La respuesta:

```text
Lo que se acepta     enrutado, autenticación, límite de tasa, y como mucho
                     composición ligera sin interpretar los datos
Lo que no            la regla de descuentos: cambia con el negocio y obliga
                     a desplegar el gateway cada vez
Alternativa 1        BFF de esa experiencia: compone y llama a un servicio
                     que decide los descuentos
Alternativa 2        servicio de precios dueño de esa regla; todos le preguntan
Coste de no hacerlo  el equipo de plataforma pasa a ser cuello de botella de
                     una regla comercial que cambia cada campaña
```

🔬 **El detalle** — Conviene reconocer por qué la propuesta es tentadora: el gateway ya está en el
camino y ahorra un salto. El argumento decisivo no es purista sino de ritmo: una regla comercial
cambia varias veces al trimestre, y el gateway no puede desplegarse a ese ritmo.

**02 → 24. Diseña la política de límite de tasa del sistema: por quién, qué límites, qué se devuelve, qué se exime y cómo se comunica a los consumidores. 🔴**

⏱️ **30 segundos** — Por consumidor identificado, con límite de concurrencia y de ritmo, `429` con
`Retry-After`, exenciones para salud y login, y límites publicados en la documentación.

🗣️ **2 minutos** — La política:

```text
Identificación   por credencial de consumidor; por IP solo como última defensa
Límites          concurrencia por consumidor (protege capacidad)
                 + ritmo por minuto (protege de abuso)
                 + límite global de emergencia (rechazo temprano en sobrecarga)
Respuesta        429 con Retry-After y encabezados de cuota restante
Exenciones       salud, autenticación general, sondas internas
Comunicación     límites publicados por escrito; aviso antes de endurecerlos;
                 panel por consumidor para que vean su consumo
Escalado         alerta al consumidor antes de cortar, salvo emergencia
```

🔬 **El detalle** — Las encabezados de cuota restante son la pieza que convierte el límite en algo
cooperativo: un cliente que ve cuánto le queda puede autorregularse. Sin ellas, solo descubre el
límite cuando lo golpea, y su reacción natural es reintentar.

**02 → 25. Diagnostica: tras añadir el BFF móvil, la latencia de la aplicación empeoró. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Composición secuencial en el BFF; un salto extra sin reutilización de
conexiones; o el BFF haciendo trabajo pesado en el hilo equivocado.

🗣️ **2 minutos** — Las tres:

```text
1. Composición secuencial   el BFF llama a los servicios uno detrás de otro;
                            la latencia es la suma en vez del máximo.
                            Se ve en la traza: llamadas encadenadas
2. Salto extra sin keep-alive el BFF abre conexión nueva a cada servicio en cada
                            petición: conexión + TLS por llamada.
                            Se ve en conexiones nuevas por segundo
3. Trabajo pesado en el BFF  transformaciones grandes o serialización costosa
                            bloqueando el bucle de eventos: afecta a TODAS
                            las peticiones, no solo a la que transforma
```

Se distinguen con la traza distribuida: si los tramos se solapan o no, y cuánto tiempo pasa el BFF
sin llamar a nadie.

🔬 **El detalle** — Hay una cuarta posibilidad que conviene descartar pronto: que el BFF esté
desplegado lejos de los servicios —otra zona o región—, con lo que cada llamada paga latencia de red
adicional. Es un fallo de despliegue, no de código, y por eso cuesta encontrarlo mirando el programa.

---

# 03 — Resiliencia en la práctica

**03 → 1. ¿Qué se propaga en una caída en cascada, y en qué dirección? 🟢**

⏱️ **30 segundos** — Se propaga la **lentitud**, no el error, y va hacia arriba: del que tarda al que
le llama.

🗣️ **2 minutos** — Una dependencia lenta retiene los hilos o las conexiones del que llama; cuando se
agotan, ese servicio deja de atender todo, incluidas las rutas que no dependían del lento. Por eso el
servicio que se cae no suele ser el que falla, y el diagnóstico empieza por la traza y no por el que
dio el error.

🔬 **El detalle** — Un error rápido es mucho menos dañino que una respuesta lenta: se cuenta, se ve y
libera el recurso de inmediato. De ahí que rechazar temprano sea un acto de resiliencia y no una
rendición.

**03 → 2. ¿Cómo se calcula un timeout? 🟢**

⏱️ **30 segundos** — Desde el p99 de la dependencia más un margen, y siempre menor que el presupuesto
de la petición que lo contiene.

🗣️ **2 minutos** — Si tu endpoint promete un segundo, no puedes esperar dos a una dependencia. Y los
plazos decrecen según se baja en la cadena, para que el trabajo de abajo no siga cuando el de arriba
ya se rindió. Si el p99 del otro no cabe en tu presupuesto, la conversación es sobre su rendimiento o
sobre sacar esa llamada de la ruta.

🔬 **El detalle** — El timeout no mide la paciencia con el otro: mide cuánto puedes esperar sin
quedarte sin recursos. Formularlo así cambia la discusión, porque deja de ser un favor al otro
servicio.

**03 → 3. Enumera las cuatro reglas del reintento. 🟢**

⏱️ **30 segundos** — Solo lo idempotente, con espera exponencial, con jitter y con presupuesto.

🗣️ **2 minutos** — La idempotencia decide si se puede; el backoff evita golpear al que ya va mal; el
jitter evita que todos los clientes reintenten sincronizados; y el presupuesto limita cuánto puede
crecer la carga total. Falta una quinta implícita: reintentar en una sola capa.

🔬 **El detalle** — Un fallo de conexión es seguro de reintentar porque la petición no llegó; un
timeout no lo es, porque pudo ejecutarse y perderse la respuesta. Distinguir ambos casos en el código
del cliente es lo que evita duplicar efectos.

**03 → 4. ¿Cuáles son los tres estados de un circuit breaker? 🟢**

⏱️ **30 segundos** — Cerrado —pasa todo—, abierto —falla inmediato sin llamar— y semiabierto —deja
pasar unas pocas pruebas—.

🗣️ **2 minutos** — Pasa de cerrado a abierto cuando la tasa de fallo supera el umbral en una ventana;
tras un tiempo pasa a semiabierto y prueba con unas pocas llamadas; si van bien, cierra; si no, vuelve
a abrir. El semiabierto es lo que evita mandarle un aluvión al servicio que acaba de levantarse.

🔬 **El detalle** — El umbral debe incluir un mínimo de peticiones: con tres llamadas y dos fallos, un
umbral del 50 % abre el circuito por ruido estadístico. Es el error de configuración más común y
produce aperturas aparentemente aleatorias en servicios con poco tráfico.

**03 → 5. ¿Qué es un bulkhead y qué convierte en qué? 🟢**

⏱️ **30 segundos** — Compartimentos separados por dependencia: convierte un agotamiento total en una
degradación parcial.

🗣️ **2 minutos** — Con un solo pool compartido, una dependencia lenta se lleva toda la capacidad del
servicio. Con un pool por dependencia, `payments` agota el suyo y el resto de rutas sigue funcionando. Es
la medida que impide que un fallo ajeno se convierta en una caída propia completa.

🔬 **El detalle** — Con hilos virtuales el argumento clásico pierde fuerza porque los hilos dejan de
ser el recurso escaso, pero el patrón sigue: el recurso pasa a ser el pool de conexiones y la
capacidad del otro lado, y esos siguen necesitando compartimentos.

**03 → 6. ¿A quién protege el circuit breaker? 🟡**

⏱️ **30 segundos** — Al que llama: deja de gastar recursos en algo que ya sabe que va a fallar.

🗣️ **2 minutos** — El servicio caído recibe además un efecto secundario útil —deja de llegarle
tráfico y tiene margen para recuperarse—, pero ese no es el objetivo. Y hay un efecto perjudicial: si
todos los clientes reabren a la vez, le mandan un pico justo cuando empieza a levantarse.

🔬 **El detalle** — La frase que conviene tener lista, porque contradice el folleto sin sonar
contrarian: "el circuit breaker protege al que llama; al caído le da respiro y, si no se tiene
cuidado, también le da el pico de la reapertura".

**03 → 7. ¿Por qué el reintento es el único mecanismo que puede empeorar un incidente? 🟡**

⏱️ **30 segundos** — Porque multiplica la carga sobre un sistema que ya está degradado.

🗣️ **2 minutos** — Los demás mecanismos, mal configurados, simplemente no ayudan; el reintento sin
backoff ni presupuesto convierte una degradación en una caída. Dos reintentos triplican el tráfico
hacia la dependencia que ya no daba abasto, y si además hay reintentos en varias capas, el
multiplicador es exponencial.

🔬 **El detalle** — El caso real más citado: tres capas con tres intentos cada una producen veintisiete
llamadas por petición original. Por eso conviene decidir explícitamente en qué capa vive el reintento
y desactivarlo en las demás.

**03 → 8. ¿Por qué hace falta jitter además de backoff? 🟡**

⏱️ **30 segundos** — Porque sin aleatoriedad todos los clientes reintentan en el mismo instante,
sincronizados por el propio fallo.

🗣️ **2 minutos** — El backoff separa los intentos de un cliente, pero si mil clientes fallaron a la
vez, todos esperarán lo mismo y volverán juntos. El resultado son picos periódicos que impiden la
recuperación. El jitter reparte esos reintentos en la ventana y convierte el pico en una rampa.

🔬 **El detalle** — El mismo razonamiento aplica a otras cosas que se sincronizan sin querer:
caducidad de conexiones, tareas programadas a las horas en punto, y reconexiones tras un despliegue.
Casi todo lo que ocurre "a la vez" en un sistema distribuido merece jitter.

**03 → 9. ¿Dónde vive el estado del circuit breaker, y qué consecuencia tiene con diez instancias? 🟡**

⏱️ **30 segundos** — En el proceso: hay diez circuit breakers independientes, cada uno con su visión
parcial.

🗣️ **2 minutos** — Cada instancia decide con el tráfico que ella ve, así que unas abren y otras no. El
comportamiento agregado es gradual en vez de binario, lo que en general es bueno —no se corta todo de
golpe— pero hace que el diagnóstico sea confuso: el mismo servicio responde bien por unas instancias y
falla rápido por otras.

🔬 **El detalle** — En Python con varios procesos trabajadores se multiplica también dentro de la misma
instancia. Y existe la variante con estado compartido, que sincroniza la decisión a costa de añadir
una dependencia en el camino crítico: rara vez compensa.

**03 → 10. ¿Por qué un circuit breaker contra tu propia base de datos no suele tener sentido? 🟡**

⏱️ **30 segundos** — Porque sin ella no puedes hacer nada: abrir el circuito solo cambia un error por
otro.

🗣️ **2 minutos** — El circuit breaker sirve cuando hay algo mejor que hacer que esperar: degradar,
responder parcialmente, usar una caché. Si la dependencia es imprescindible para toda la
funcionalidad, lo que hace falta es timeout —para no agotar recursos— y readiness —para salir del
balanceo—, no un interruptor.

🔬 **El detalle** — Hay una excepción: si parte de tus rutas puede servirse desde caché, el
circuit breaker permite fallar rápido esas consultas y seguir sirviendo lo cacheado. Es decir, tiene
sentido cuando existe una degradación real, y no lo tiene cuando no la hay.

**03 → 11. ¿Qué cambia en el argumento del bulkhead con hilos virtuales? 🟡**

⏱️ **30 segundos** — Que los hilos dejan de ser el recurso escaso, pero el patrón sigue siendo
necesario con otros recursos.

🗣️ **2 minutos** — El argumento clásico era que bloquear un hilo es caro y un pool pequeño se agota.
Con hilos ligeros se pueden tener muchísimos bloqueados sin coste apreciable. Lo que no cambia es que
el pool de conexiones a la base, las conexiones salientes y la capacidad del servicio destino siguen
siendo finitos, y esos son los que hay que compartimentar.

🔬 **El detalle** — De hecho, con hilos virtuales aparece un riesgo nuevo: como es barato crear
muchos, es fácil lanzar miles de llamadas concurrentes a una dependencia y tumbarla. El límite de
concurrencia por destino pasa a ser más importante, no menos.

**03 → 12. ¿Por qué un fallback debe decir que está degradado? 🟡**

⏱️ **30 segundos** — Porque si no, un fallo visible se convierte en uno silencioso y alguien decidirá
sobre datos incorrectos.

🗣️ **2 minutos** — Devolver una lista vacía o un valor por defecto sin marca hace que el consumidor no
distinga "no hay datos" de "no pude consultarlos". En una pantalla eso confunde al usuario; en un
proceso automático puede provocar decisiones erróneas. Marcar la degradación permite además contarla y
alertar.

🔬 **El detalle** — La degradación debe verse en dos sitios: en la respuesta —un campo que lo indique—
y en las métricas. Si solo se ve en la respuesta, nadie se entera de que el sistema lleva dos días
degradado.

**03 → 13. ¿Qué forma tiene el circuit breaker en cada plataforma, y qué esconde cada una? 🟡**

⏱️ **30 segundos** — Anotación en Java, función envuelta en Node/TS, struct que envuelve la llamada en
Go, y decorador en Python. La misma idea con cuatro cantidades de magia distintas.

🗣️ **2 minutos** — La anotación de Java es la más cómoda y la que más esconde: va por proxy, así que
una llamada interna del mismo objeto no la atraviesa y el mecanismo no se aplica sin dar ningún error.
La función envuelta de Node y el decorador de Python son explícitos en el punto de uso, pero dejan el
estado atado a dónde se declaren. La struct de Go es la más verbosa y la más predecible: se ve quién
la comparte y cuándo se consulta.

🔬 **El detalle** — El intercambio es siempre el mismo: cuanto más declarativa es la forma, menos
código escribes y más comportamiento tienes que conocer para diagnosticar. Por eso en las cuatro
conviene comprobar en las métricas que la llamada que crees protegida aparece de verdad en el
mecanismo.

---

**03 → 14. Tu endpoint promete 1 s y llamas a dos servicios. Reparte los plazos y justifica. 🟠**

⏱️ **30 segundos** — Unos 100 ms de trabajo propio y margen, y el resto repartido: si van en paralelo,
unos 700 ms cada una; si en secuencia, 400 y 350.

🗣️ **2 minutos** — El reparto deja margen para poder devolver un error controlado dentro del segundo
prometido. En paralelo manda la más lenta, así que ambas pueden tener el mismo plazo generoso; en
secuencia se suman y hay que recortar. Y si una es opcional, su plazo debe ser mucho menor y su fallo
debe degradar.

🔬 **El detalle** — Distinguir dependencias imprescindibles de opcionales es lo que más reduce
incidentes y casi nunca está escrito. Una dependencia opcional con el mismo timeout que una
imprescindible convierte un dato decorativo en un punto de fallo.

**03 → 15. ¿En qué orden implantarías las cinco medidas si solo tienes una semana? 🟠**

⏱️ **30 segundos** — Timeouts, degradación de lo opcional, bulkhead o límite de concurrencia,
circuit breaker, y por último reintentos.

🗣️ **2 minutos** — Los timeouts son la base: sin ellos ningún otro mecanismo llega a actuar. La
degradación convierte caídas ajenas en molestias y es más de producto que de código. El límite de
concurrencia por destino evita que una dependencia consuma toda la capacidad. El circuit breaker
ahorra recursos cuando ya está claro que falla. Y los reintentos los dejo al final a propósito, porque
mal hechos empeoran.

🔬 **El detalle** — Si además hay que elegir dónde empezar dentro del sistema, conviene hacerlo por la
dependencia con peor p99 o con más incidentes históricos, no por el servicio más importante: es donde
el mismo trabajo rinde más.

**03 → 16. ¿Qué umbrales pondrías a un circuit breaker contra `payments`, y cómo los justificas? 🟠**

⏱️ **30 segundos** — Un mínimo de peticiones antes de decidir, una tasa de fallo alta —del orden del
50 %—, y un tiempo abierto de decenas de segundos.

🗣️ **2 minutos** — El mínimo de peticiones evita abrir por ruido con poco tráfico. La tasa alta evita
abrir por fallos normales; abrir al 20 % significa cortar cuando la mayoría de llamadas funcionan. Y
el tiempo abierto debe ser suficiente para que el otro se recupere, pero no tanto que la degradación
se alargue innecesariamente.

🔬 **El detalle** — Los números se ajustan después con datos: si el circuito abre y cierra
constantemente —aleteo—, la ventana es demasiado corta o el umbral demasiado bajo. Conviene
monitorizar las transiciones del circuito, no solo su estado actual.

**03 → 17. Un equipo reintenta en el cliente, en la librería y en el mesh. ¿Qué pasa y qué corriges? 🟠**

⏱️ **30 segundos** — Los intentos se multiplican entre sí: tres por capa son veintisiete llamadas por
petición. Se deja el reintento en una sola capa.

🗣️ **2 minutos** — El efecto es devastador justo cuando el sistema está degradado, porque amplifica la
carga en el peor momento. La corrección es decidir explícitamente dónde vive el reintento —normalmente
el cliente, que es quien sabe si la operación es idempotente— y desactivarlo en las demás. El mesh
puede reintentar solo fallos de conexión, que siempre son seguros.

🔬 **El detalle** — Detectarlo es fácil si se mide: comparar peticiones salientes del cliente con
peticiones entrantes en el destino. Si la proporción es mucho mayor que uno en un incidente, hay
reintentos anidados.

**03 → 18. ¿Qué dependencias pondrías en readiness y cuáles no, en un servicio que llama a tres? 🟠**

⏱️ **30 segundos** — Solo las que hacen que **todas** las rutas fallen; normalmente la base de datos
propia y nada más.

🗣️ **2 minutos** — Si `orders` puede seguir atendiendo consultas con `payments` caído, `payments` no va en
readiness: ponerlo ahí sacaría del balanceo a un servicio sano y propagaría la caída. La base de datos
propia sí, porque sin ella no hay ninguna ruta útil. Y ninguna dependencia va en liveness, nunca.

🔬 **El detalle** — La lista de dependencias imprescindibles es, de hecho, la definición operativa de
qué puede degradarse en tu servicio. Por eso conviene revisarla con producto: es una decisión de
negocio disfrazada de configuración.

**03 → 19. La anotación de circuit breaker no se aplica y nadie sabe por qué. Da la causa más probable. 🟠**

⏱️ **30 segundos** — Que el método se llama desde otro método del mismo objeto, así que no pasa por el
proxy.

🗣️ **2 minutos** — Los mecanismos declarativos funcionan envolviendo el objeto: una llamada interna va
directa al método real y se salta toda la decoración. Es un fallo silencioso —no hay error, solo
ausencia de protección— y explica también por qué a veces "la transacción no se aplica" en el mismo
tipo de código.

🔬 **El detalle** — Las salidas son separar el método a otro componente o usar la forma programática
en lugar de la anotación. Y hay una comprobación fácil: si el mecanismo tiene métricas, basta con
mirar si esa llamada aparece en ellas.

**03 → 20. ¿Cómo evitas el pico contra un servicio que acaba de recuperarse? 🟠**

⏱️ **30 segundos** — Con semiabierto limitado a unas pocas pruebas, jitter en el tiempo de reapertura
y límite de concurrencia hacia esa dependencia.

🗣️ **2 minutos** — Si todos los clientes abren su circuito a la vez y reabren a la vez, el servicio
recién levantado recibe el aluvión completo y vuelve a caer. El semiabierto con pocas llamadas limita
el daño por cliente, y el jitter en el tiempo de apertura desincroniza a los clientes entre sí. El
límite de concurrencia pone un tope duro independientemente de todo lo anterior.

🔬 **El detalle** — En el servicio que se recupera ayuda también empezar con capacidad reducida y
crecer: aceptar poco al principio y rechazar el resto con `429` es preferible a aceptarlo todo y
volver a caer. Es el rechazo temprano aplicado a la recuperación.

**03 → 21. ¿Qué métricas necesitas para saber si tu resiliencia funciona? 🟠**

⏱️ **30 segundos** — Transiciones del circuit breaker, reintentos y su tasa, timeouts por dependencia,
rechazos por límite, y respuestas degradadas.

🗣️ **2 minutos** — No basta con la latencia y los errores: hay que ver los mecanismos actuando. Los
timeouts por dependencia dicen quién está lento; los reintentos, cuánta carga extra estás generando;
las transiciones del circuito, si los umbrales son razonables; y las respuestas degradadas, cuánto
lleva el sistema funcionando a medias sin que nadie lo note.

🔬 **El detalle** — La métrica de respuestas degradadas es la que más se olvida y la que más
sorprende: muchos sistemas llevan semanas sirviendo datos parciales porque la degradación funcionó
demasiado bien y nadie puso una alerta.

**03 → 22. Diseña la configuración de resiliencia completa de `orders` hacia sus tres dependencias, con valores y justificación de cada uno. 🔴**

⏱️ **30 segundos** — Plazos por dependencia según su p99 y su criticidad, reintentos solo donde hay
idempotencia, circuit breaker en las opcionales, y degradación declarada.

🗣️ **2 minutos** — La configuración:

```text
Dependencia  Timeout  Reintento          Circuit breaker   Si falla
───────────  ───────  ─────────────────  ───────────────  ─────────────────────
base propia  500 ms   no (no ayuda)      no               readiness=false
inventory    600 ms   1, solo lecturas   sí, 50 % / 20    error controlado al usuario
             (crítica para confirmar)                      (no se puede confirmar)
payments     800 ms   no sin clave de    sí, 50 % / 20    pedido en estado PENDING
                      idempotencia                         y cobro diferido
customers    200 ms   1                  sí, más sensible respuesta sin nombre,
             (opcional)                                    marcada como degradada
Concurrencia límite por destino en las tres; presupuesto global de reintentos ≤10 %
```

🔬 **El detalle** — La fila de `customers` ilustra el criterio: como es opcional, tiene el plazo más
corto y el circuit breaker más sensible. Cuanto menos imprescindible es una dependencia, antes hay que
renunciar a ella, y eso se expresa en los números.

**03 → 23. Diagnostica: p99 de `orders` en 8 s, CPU normal, hilos al máximo, `payments` con una consulta lenta. Explica la cadena y di dónde la cortarías, en orden. 🔴**

⏱️ **30 segundos** — `payments` responde a ocho segundos, los hilos de `orders` esperan, se agota el
pool y `orders` deja de atender todo.

🗣️ **2 minutos** — La cadena y los cortes:

```text
payments lento (consulta sin índice)
  │ ← corte 1: timeout de 800 ms en orders → libera el hilo a tiempo
hilos de orders ocupados esperando
  │ ← corte 2: pool separado para payments → el resto de rutas no se ve afectado
pool global agotado
  │ ← corte 3: circuit breaker → deja de intentarlo mientras falle
TODAS las rutas de orders fallan
  │ ← corte 4: degradación → el pedido queda PENDING en vez de fallar
```

El arreglo de la consulta lenta es necesario pero es el **detonante**, no la causa: la causa es que
una dependencia de tercer nivel podía consumir toda la capacidad del primero.

🔬 **El detalle** — La pregunta de seguimiento típica es por qué fallan también las rutas que no tocan
`payments`. La respuesta es que el recurso agotado es compartido —el pool de hilos del servidor— y por
eso el bulkhead es la corrección estructural: convierte un agotamiento total en uno parcial.

**03 → 24. Diseña la degradación completa de una pantalla con cuatro dependencias, diciendo qué ve el usuario en cada fallo y cómo se detecta que está degradada. 🔴**

⏱️ **30 segundos** — Una imprescindible que falla la pantalla, tres opcionales que se omiten marcadas,
y una métrica por cada degradación.

🗣️ **2 minutos** — El diseño:

```text
Dependencia   Papel           Si falla                     Métrica
────────────  ──────────────  ───────────────────────────  ───────────────────────
orders        imprescindible  error 503, mensaje claro     errores de la pantalla
customers     opcional        sin nombre, con marca        degraded_customers
catalog       opcional        nombre copiado en el pedido  degraded_catalog
shipping      opcional        sin fecha estimada, marcada  degraded_shipping

Respuesta     campo "degraded": ["customers","shipping"] para que el frontend lo muestre
Alertas       cualquier degradación sostenida > X min dispara aviso
```

🔬 **El detalle** — El campo explícito de degradación en la respuesta es lo que permite al frontend
mostrar "no disponible" en vez de un hueco, y a los paneles contar cuánto tiempo lleva el sistema a
medias. Sin él, la degradación se convierte en un fallo invisible que nadie arregla.

**03 → 25. Un equipo propone poner todos los reintentos en el mesh y quitarlos del código. Responde con lo que concedes y lo que rechazas. 🔴**

⏱️ **30 segundos** — Concedo los reintentos de fallo de conexión; rechazo los de timeout y escrituras,
porque el mesh no sabe si la operación es idempotente.

🗣️ **2 minutos** — La respuesta:

```text
Se concede    reintento de fallos de conexión y de 503: siempre seguros,
              y centralizarlos evita implementarlos en cuatro plataformas
Se rechaza    reintento de timeouts y de escrituras: el mesh no sabe si la
              operación puede repetirse sin duplicar efecto
Se exige      que quede UNA sola capa de reintento: si el mesh reintenta,
              el cliente no; si no, se multiplican
Sigue siendo  la idempotencia, la degradación y el presupuesto: el mesh no
del código    puede decidir qué respuesta parcial tiene sentido
```

🔬 **El detalle** — La ventaja real de la propuesta es la uniformidad: en un sistema políglota,
tener la política de reintento en un solo sitio evita cuatro implementaciones divergentes. Conviene
reconocerlo y encauzarlo, porque es un buen argumento aplicado a la parte correcta del problema.

---

# 04 — Observabilidad y trazas

**04 → 1. ¿Qué pregunta responde cada uno de los tres pilares? 🟢**

⏱️ **30 segundos** — Las métricas dicen **que** pasa algo, las trazas **dónde**, y los logs **qué**
pasó exactamente.

🗣️ **2 minutos** — El flujo de diagnóstico va en ese orden: una alerta salta por una métrica, la
traza señala el servicio y la llamada, y el log del punto concreto da el detalle. Si los tres no
comparten el identificador de traza, ese flujo se rompe y cada paso vuelve a ser una búsqueda a
ciegas.

🔬 **El detalle** — El coste también va en ese orden inverso: las métricas son baratas, las trazas
caras —por eso se muestrean— y los logs son los que más se descontrolan en volumen. Empezar el
diagnóstico por los logs cuesta el doble de tiempo y de dinero.

**04 → 2. Define traza, span y contexto. 🟢**

⏱️ **30 segundos** — La traza es el recorrido completo de una petición; el span, cada tramo con su
duración; el contexto, lo que viaja para unir spans de servicios distintos.

🗣️ **2 minutos** — Los spans forman un árbol: cada uno conoce a su padre, y todos comparten el
identificador de traza. El contexto —identificador de traza, identificador del span padre y banderas
de muestreo— es lo que se propaga en las llamadas para que el árbol se reconstruya aunque los tramos
ocurran en máquinas distintas.

🔬 **El detalle** — Los atributos y eventos del span son lo que convierte una traza en diagnóstico: el
identificador del pedido, el código de error, el número de reintentos. Una traza con solo duraciones
dice dónde, pero no ayuda a entender por qué.

**04 → 3. ¿Qué encabezado propaga el contexto de traza y qué lleva dentro? 🟢**

⏱️ **30 segundos** — `traceparent`, del estándar de W3C: lleva versión, identificador de traza,
identificador del span padre y banderas de muestreo.

🗣️ **2 minutos** — Al ser estándar, servicios de distintos equipos y con distintas herramientas pueden
unir sus trazas sin acordar nada. La bandera de muestreo es la parte que se olvida: indica si esta
traza se está guardando, y por eso la decisión se toma una vez y se respeta en toda la cadena.

🔬 **El detalle** — Hay un segundo encabezado del mismo estándar para propagar pares clave-valor
propios entre servicios. Es útil para llevar contexto de negocio —identificador de tenant, por
ejemplo—, pero conviene no abusar: viaja en cada llamada y no es un canal de datos.

**04 → 4. Enumera los cuatro sitios donde se pierde el contexto. 🟢**

⏱️ **30 segundos** — Al cruzar a un pool de hilos, al publicar en un broker, en código asíncrono sin
el mecanismo de la plataforma, y en clientes HTTP no instrumentados.

🗣️ **2 minutos** — Los cuatro tienen la misma raíz: el contexto viaja atado a algo —el hilo, la
petición— y en el salto no se copia. El del broker es el más dañino, porque corta la traza justo en
la parte asíncrona, que es donde están los problemas difíciles de diagnosticar.

🔬 **El detalle** — La instrumentación automática cubre el servidor, los clientes habituales y la base
de datos; estos cuatro casos son precisamente los que no cubre. Por eso el 80 % viene gratis y el 20 %
restante es el que importa.

**04 → 5. ¿Qué son RED y USE? 🟢**

⏱️ **30 segundos** — RED para servicios: ritmo, errores y duración. USE para recursos: utilización,
saturación y errores.

🗣️ **2 minutos** — Con RED sabes cómo va un servicio desde fuera: cuántas peticiones recibe, cuántas
fallan y cuánto tardan. Con USE sabes por qué: si el pool está saturado, si la CPU está al límite, si
hay errores de recurso. Son complementarios y entre los dos cubren casi todo lo que se necesita
vigilar.

🔬 **El detalle** — La saturación es la métrica menos usada y la más predictiva: una cola que crece
avisa antes de que la latencia se dispare. Vigilar solo utilización es ver el problema cuando ya no
hay margen.

**04 → 6. Diferencia entre muestreo por cabeza y por cola. 🟢**

⏱️ **30 segundos** — Por cabeza se decide al empezar, con probabilidad fija; por cola al terminar,
sabiendo si hubo error o latencia alta.

🗣️ **2 minutos** — El primero es simple y barato, y su defecto es que pierde justo las trazas raras
que interesan. El segundo guarda lo interesante, a costa de retener las trazas en el colector hasta
poder decidir, lo que consume memoria y obliga a que todos los spans de una traza pasen por el mismo
sitio.

🔬 **El detalle** — La configuración habitual combina ambos: probabilidad baja para el tráfico normal
y garantía para errores y latencias altas. Lo importante es que la decisión se propague en el
contexto, para no guardar trazas a medias.

**04 → 7. ¿Qué es el presupuesto de error y para qué se usa? 🟢**

⏱️ **30 segundos** — Lo que te queda de incumplimiento permitido según tu objetivo: con un 99,5 % en
30 días, unas 3,6 horas.

🗣️ **2 minutos** — Sirve para tomar decisiones sin discutir por sensaciones: si queda presupuesto,
puedes arriesgar —desplegar más rápido, experimentar—; si se ha gastado, toca estabilizar antes de
seguir añadiendo funcionalidad. Convierte la fiabilidad en un recurso que se administra.

🔬 **El detalle** — Su utilidad depende de que el objetivo esté bien definido sobre lo que el usuario
percibe. Un objetivo de disponibilidad del servidor puede estar verde mientras las peticiones tardan
cinco segundos, y entonces el presupuesto no mide nada real.

**04 → 8. ¿Por qué el colector de OpenTelemetry desacopla del proveedor? 🟡**

⏱️ **30 segundos** — Porque los servicios exportan al colector y es el colector quien decide a dónde
enviarlo.

🗣️ **2 minutos** — Cambiar de destino —o mandar a dos a la vez durante una migración— es cambiar la
configuración del colector, no la de cincuenta servicios. Además permite procesar antes de exportar:
muestrear por cola, filtrar atributos sensibles, agregar. Es la pieza que convierte la observabilidad
en algo operable.

🔬 **El detalle** — También permite limitar el daño: si el destino se cae, el colector puede
amortiguar en lugar de que cada servicio acumule o pierda. Por eso conviene desplegarlo como un
componente propio y vigilarlo, no tratarlo como un detalle de configuración.

**04 → 9. ¿Por qué la media de latencia es una métrica engañosa? 🟡**

⏱️ **30 segundos** — Porque esconde la cola: con media de 100 ms puede haber un p99 de cinco segundos
afectando a miles de usuarios.

🗣️ **2 minutos** — En sistemas con muchas peticiones, el promedio lo dominan las rápidas. Lo que
percibe el usuario molesto es la cola, y lo que agota los recursos del sistema son las peticiones
lentas, no las medias. Por eso se miden percentiles y se alerta sobre ellos.

🔬 **El detalle** — Y con percentiles hay una trampa: no se pueden promediar entre instancias. Calcular
la media de los p99 de diez instancias no da el p99 del conjunto. Hay que agregar los histogramas, y
la mayoría de las herramientas modernas lo hacen bien si se les da el tipo de métrica correcto.

**04 → 10. ¿Por qué una traza muestreada a medias no sirve de nada? 🟡**

⏱️ **30 segundos** — Porque el valor está en ver el recorrido completo: con tramos ausentes, no se
puede localizar dónde se fue el tiempo.

🗣️ **2 minutos** — Si un servicio decide guardar y el siguiente no, la traza aparece truncada justo
donde podría estar el problema. Por eso la decisión de muestreo viaja en el contexto y todos los
participantes la respetan: o se guarda entera o no se guarda.

🔬 **El detalle** — Ese es también el argumento contra configurar el muestreo servicio por servicio
con valores distintos: parece una optimización de coste y produce trazas inservibles. El muestreo se
decide al principio o en el colector, no en cada tramo.

**04 → 11. ¿Por qué el contexto no cruza a un pool de hilos, y qué se hace? 🟡**

⏱️ **30 segundos** — Porque va atado al hilo actual, y el hilo del pool es otro. Hay que propagarlo
explícitamente al enviar la tarea.

🗣️ **2 minutos** — Es el caso clásico en plataformas con hilos: la petición entra, el contexto se
asocia al hilo, y al enviar trabajo a un pool ese contexto no viaja. La solución es envolver la tarea
de modo que copie el contexto actual, cosa que la mayoría de las librerías de instrumentación
ofrecen, pero hay que usarlo.

🔬 **El detalle** — El mismo problema aparece en cualquier salto de ejecución: temporizadores, tareas
programadas, reintentos diferidos. La señal de que está pasando es ver spans huérfanos o trazas que
terminan justo donde empieza el trabajo interesante.

**04 → 12. ¿Qué diferencia hay entre el contexto de traza y la cancelación en Go, y por qué importa? 🟡**

⏱️ **30 segundos** — En Go van juntos en el mismo `context`: si el padre se cancela, el trabajo en
segundo plano que heredó ese contexto muere.

🗣️ **2 minutos** — Para una llamada síncrona eso es exactamente lo que quieres. Para trabajo que debe
continuar después de responder —publicar un evento, actualizar una caché— hay que separar: conservar
el contexto de traza para no perder la correlación, pero no la cancelación del padre.

🔬 **El detalle** — Se resuelve creando un contexto nuevo que hereda los valores pero no la
cancelación, con su propio plazo. Es un patrón conocido en Go y una fuente habitual de errores sutiles
—trabajo en segundo plano que se cancela al azar— cuando no se conoce.

**04 → 13. ¿Qué campos fijos pondrías en el log estructurado del chassis? 🟡**

⏱️ **30 segundos** — Marca de tiempo, nivel, servicio, versión, identificador de traza y de span,
mensaje, y los atributos del dominio que apliquen.

🗣️ **2 minutos** — Los identificadores de traza y span son lo que permite saltar del log a la traza y
al revés. La versión del servicio es lo que permite correlacionar un problema con un despliegue. Y
conviene un campo para el identificador del usuario o del tenant cuando aplique, con cuidado con los
datos personales.

🔬 **El detalle** — Igual de importante es lo que **no** debe salir en el log: datos personales,
credenciales, contenido completo de mensajes. Conviene que el chassis ofrezca una forma fácil de
registrar sin filtrar datos sensibles, porque si es incómodo, alguien acabará volcando el objeto
entero.

**04 → 14. ¿Qué mecanismo de propagación de contexto usa cada plataforma y dónde se pierde en cada una? 🟡**

⏱️ **30 segundos** — Java lo ata al hilo, Node usa almacenamiento asíncrono, Go lo pasa por la firma
con `context`, y Python usa variables de contexto. Los cuatro se pierden en sitios distintos.

🗣️ **2 minutos** — En Java se pierde al cruzar a un pool de hilos o a tareas asíncronas si no se
propaga explícitamente; en Node, al salir del encadenamiento de promesas —hilos de trabajo, colas
propias—; en Go, cuando una función no recibe o no pasa el `context`; en Python, al cambiar de hilo o
de proceso trabajador. En las cuatro se pierde al publicar en un broker si no se inyecta en los
encabezados del mensaje.

🔬 **El detalle** — La diferencia de fondo es de visibilidad: en Go el contexto es explícito y su
ausencia se ve en la revisión de código; en las otras tres es implícito y se pierde en silencio, de
modo que el fallo aparece como trazas incompletas mucho después.

---
**04 → 15. La traza se corta al publicar un evento. Explica la causa y la corrección, en ambos lados. 🟠**

⏱️ **30 segundos** — No se está inyectando el contexto en los encabezados del mensaje, ni
extrayéndolo al consumir.

🗣️ **2 minutos** — Del lado del productor hay que inyectar el contexto activo en los encabezados del
mensaje antes de publicar; del lado del consumidor, extraerlo y crear el span como hijo. Si solo se
hace una de las dos cosas, sigue sin funcionar. Y conviene que ambas estén en el chassis, no en cada
productor y consumidor.

🔬 **El detalle** — Hay una decisión de modelado: el span del consumidor puede ser hijo del productor
—una sola traza larga— o una traza nueva enlazada. Para flujos cortos, hijo; para consumidores que
procesan lotes o que se ejecutan mucho después, enlace, porque si no la traza se vuelve inmanejable.

**04 → 16. ¿Qué muestreo configurarías en un sistema con mucho tráfico y pocos errores? 🟠**

⏱️ **30 segundos** — Probabilidad baja para el tráfico normal y garantía para errores y latencias
altas, decidido por cola en el colector.

🗣️ **2 minutos** — Con mucho tráfico, guardar todo es carísimo y aporta poco: miles de trazas
idénticas de peticiones correctas. Lo valioso es lo raro, y eso solo se puede seleccionar al final. La
configuración típica es un porcentaje pequeño de lo normal más el 100 % de lo que falla o tarda.

🔬 **El detalle** — El muestreo por cola exige que todos los spans de una traza lleguen al mismo
colector, lo que condiciona el despliegue: o hay un nivel de colectores que agrupa por identificador
de traza, o no se puede decidir al final. Es la restricción que más sorprende al implantarlo.

**04 → 17. ¿Cómo darías a un usuario un "código de incidencia" útil? 🟠**

⏱️ **30 segundos** — El identificador de traza de su petición, devuelto en la respuesta de error.

🗣️ **2 minutos** — Con ese identificador, cualquiera del equipo abre la traza completa y ve el
recorrido y el fallo sin buscar nada. Conviene devolverlo también en un encabezado en las respuestas
correctas, para que soporte pueda pedirlo aunque no haya habido error visible.

🔬 **El detalle** — Hay que asegurarse de que esa traza esté guardada: si el muestreo la descartó, el
código no sirve. Por eso las respuestas de error deberían forzar el muestreo de su propia traza, que
es una configuración sencilla y muy rentable.

**04 → 18. Los costes de observabilidad se han multiplicado por tres. ¿Qué revisas y en qué orden? 🟠**

⏱️ **30 segundos** — Volumen de logs, cardinalidad de métricas y porcentaje de muestreo, en ese
orden.

🗣️ **2 minutos** — Los logs suelen ser el grueso: registros de depuración en producción, cuerpos
completos de peticiones, trazas de pila repetidas. La cardinalidad de métricas es el segundo
sospechoso: una etiqueta con identificadores de usuario o de pedido multiplica las series por
millones. Y el muestreo de trazas es el tercero, normalmente el más fácil de ajustar.

🔬 **El detalle** — La cardinalidad es el problema más traicionero porque no crece con el tráfico sino
con la variedad de valores, y una etiqueta mal elegida puede tumbar el sistema de métricas entero.
Conviene revisar qué etiquetas se añaden en el chassis y prohibir las de alta cardinalidad por
convención.

**04 → 19. Define un SLI y un SLO para la confirmación de pedidos, y justifica los números. 🟠**

⏱️ **30 segundos** — SLI: porcentaje de confirmaciones con respuesta correcta en menos de un segundo.
SLO: 99,5 % en 30 días.

🗣️ **2 minutos** — El SLI se define sobre lo que el usuario percibe —que su pedido se confirme
rápido—, no sobre la disponibilidad del servidor. El umbral de un segundo sale del objetivo de
producto; el 99,5 % da unas 3,6 horas de presupuesto al mes, que es razonable para un servicio que
despliega a diario y tiene dependencias externas.

🔬 **El detalle** — Conviene medirlo lo más cerca posible del usuario —en el borde, no dentro del
servicio— para que incluya el tiempo de red y los fallos del gateway. Un SLI medido dentro del
servicio puede estar perfecto mientras el usuario no recibe nada.

**04 → 20. ¿Cómo instrumentarías un consumidor de eventos para que su trabajo aparezca en la traza del productor? 🟠**

⏱️ **30 segundos** — Extrayendo el contexto de los encabezados del mensaje y creando el span como
hijo o como enlace.

🗣️ **2 minutos** — El consumidor extrae el contexto, crea su span, y a partir de ahí todo lo que haga
—consultas, llamadas a otros servicios— cuelga de ahí. Para mensajes procesados poco después del
evento, hijo directo; para lotes o procesamiento muy posterior, un enlace, porque si no la traza
original se alarga indefinidamente.

🔬 **El detalle** — Conviene añadir atributos propios del mensaje: identificador, tipo, número de
reintentos y si fue descartado por duplicado. Ese último es especialmente útil, porque convierte "no
se procesó" en una traza donde se ve exactamente por qué.

**04 → 21. ¿Qué métricas de los mecanismos de resiliencia añadirías a los paneles? 🟠**

⏱️ **30 segundos** — Timeouts por dependencia, reintentos y su tasa, transiciones del circuit breaker,
rechazos por límite y respuestas degradadas.

🗣️ **2 minutos** — Son las que dicen si los mecanismos están actuando y si están bien configurados.
Las transiciones del circuito detectan aleteo por umbrales mal puestos; la tasa de reintentos avisa de
amplificación de carga; y las respuestas degradadas revelan sistemas que llevan días funcionando a
medias sin que nadie se entere.

🔬 **El detalle** — Conviene etiquetarlas por dependencia, no solo agregadas: el valor está en saber
**cuál** está fallando. Y es justo el sitio donde hay que vigilar la cardinalidad: por dependencia sí,
por identificador de petición no.

**04 → 22. Diseña la observabilidad completa de la confirmación de pedido: qué se mide, qué se traza, qué se registra y qué alertas hay. 🔴**

⏱️ **30 segundos** — Métricas RED del endpoint y del flujo completo, traza de extremo a extremo
incluida la parte asíncrona, logs estructurados correlacionados, y alertas sobre SLO y sobre el
retraso del flujo.

🗣️ **2 minutos** — El diseño:

```text
Métricas    RED del endpoint /orders (ritmo, errores, p50/p95/p99)
            tiempo de extremo a extremo: confirmado → reservado → pagado
            lag del consumidor de inventory, en segundos
            degradaciones y transiciones de circuit breaker por dependencia
Trazas      span raíz en el gateway; hijos en orders, inventory y payments;
            contexto inyectado en el evento y extraído por el consumidor;
            muestreo garantizado para errores y para p99
Logs        estructurados con traza, span, versión, order_id; sin datos personales
Alertas     SLO de confirmación (presupuesto de error)
            retraso del flujo > X minutos (métrica de producto)
            cualquier mensaje en DLQ
            degradación sostenida de una dependencia
```

🔬 **El detalle** — La métrica de extremo a extremo —del evento al efecto— es la que mejor representa
lo que el negocio entiende por "el pedido se confirmó", y casi nunca existe porque cruza servicios. Se
construye con el momento del evento y el del efecto, y es la que conviene poner en el panel que mira
producto.

**04 → 23. Diagnostica: el p99 de una ruta sube, todas las dependencias reportan latencia normal, y las trazas muestran un hueco de 400 ms sin span. Da tres hipótesis. 🔴**

⏱️ **30 segundos** — Trabajo no instrumentado; espera en un pool; o pausas del entorno de ejecución
—recolección de basura, arranque en frío—.

🗣️ **2 minutos** — Las tres:

```text
1. Código propio sin instrumentar   una transformación, una serialización grande,
                                    un cálculo: no hay span porque nadie lo creó
2. Espera en un pool                el tiempo se va esperando una conexión o un hilo
                                    libre; el span de la llamada mide solo la llamada
3. Pausa del runtime                recolección de basura, arranque en frío, o el
                                    proceso desplazado por falta de CPU
```

Se distinguen añadiendo un span alrededor del código sospechoso, mirando la métrica de espera en pool
y correlacionando el hueco con las pausas del entorno.

🔬 **El detalle** — La segunda es la más frecuente y la más invisible: el cliente mide desde que
envía, no desde que pidió una conexión. Por eso conviene instrumentar explícitamente la adquisición
del pool, que casi ninguna instrumentación automática cubre.

**04 → 24. Diseña la política de muestreo y retención del sistema, con su justificación de coste. 🔴**

⏱️ **30 segundos** — Muestreo bajo para lo normal, total para errores y latencias altas; retención
corta para trazas, media para logs y larga para métricas.

🗣️ **2 minutos** — La política:

```text
Trazas     1-5 % del tráfico normal; 100 % de errores y de p99, por cola
           retención 7-14 días: se usan para incidentes recientes
Logs       nivel informativo en producción; depuración solo temporal y acotado
           retención 14-30 días; lo que deba durar más, a almacenamiento frío
Métricas   retención 13 meses para las de negocio (comparar con el año anterior)
           resolución reducida a partir del primer mes
Regla      la decisión de muestreo se propaga; nunca trazas a medias
```

La justificación de coste: las métricas son baratas y se guardan mucho; las trazas son caras y se
guardan poco; los logs son el grueso del gasto y donde más se recorta.

🔬 **El detalle** — El punto que suele faltar es el nivel de log en producción: dejar depuración
activada "temporalmente" es la causa más común de que el coste se dispare, y conviene que exista una
forma de activarlo por servicio y con caducidad automática.

**04 → 25. Un equipo tiene logs excelentes y ninguna traza. Escribe el plan de adopción de trazas en seis semanas, con el orden y el criterio. 🔴**

⏱️ **30 segundos** — Empezar por el chassis y una ruta crítica de extremo a extremo, incluido el salto
asíncrono, y extender después.

🗣️ **2 minutos** — El plan:

```text
Semana 1  Colector desplegado y probado; decisión de destino y de muestreo.
Semana 2  Chassis: instrumentación automática, propagación en clientes HTTP,
          identificador de traza en el log estructurado (ya existe la cultura de logs).
Semana 3  Una ruta crítica completa, de extremo a extremo, incluidos los dos
          servicios que más incidentes tienen.
Semana 4  El salto asíncrono: inyección y extracción en broker. Es lo que más
          rinde y lo que menos cubre la instrumentación automática.
Semana 5  Muestreo por cola con garantía de errores; paneles y enlace log→traza.
Semana 6  Extensión al resto, con la lista de comprobación en el chassis.
Criterio  se da por adoptado cuando un incidente se diagnostica con la traza
          antes que con los logs.
```

🔬 **El detalle** — Aprovechar que ya tienen buenos logs es la clave del plan: añadir el identificador
de traza a las líneas existentes da valor inmediato —saltar del log a la traza— y hace que el equipo
vea el beneficio en la semana dos, que es lo que sostiene el resto de la adopción.

---

# 05 — Service mesh y sidecar

**05 → 1. ¿Qué es el patrón sidecar? 🟢**

⏱️ **30 segundos** — Un proceso que corre junto al servicio, comparte su ciclo de vida e intercepta
todo su tráfico para aplicar lo transversal.

🗣️ **2 minutos** — El servicio cree que habla con `localhost` y el sidecar enruta, cifra, reintenta y
mide. Como está fuera del proceso, funciona igual en cualquier lenguaje, y esa es toda la idea: sacar
del código lo que es igual para todos los servicios.

🔬 **El detalle** — El precio es un contenedor más por instancia y un salto local en cada dirección.
En un sistema homogéneo con pocos servicios, ese precio supera lo que ahorra; en uno políglota, es al
revés.

**05 → 2. Enumera cuatro cosas que mueve un mesh fuera del código. 🟢**

⏱️ **30 segundos** — mTLS con rotación de certificados, timeouts y reintentos, circuit breaker y
expulsión de instancias, y balanceo por llamada. Más métricas y trazas uniformes.

🗣️ **2 minutos** — Todas se configuran sin desplegar servicios, lo que permite cambiar política
operativa rápido. El mTLS automático suele ser el argumento más fuerte: conseguir lo mismo con
librerías implica gestionar certificados en cuatro plataformas.

🔬 **El detalle** — El tráfico dividido por porcentaje es la función que menos se nombra y más se usa
en la práctica: permite canary real sin que las aplicaciones sepan nada, que es justo lo que más
cuesta montar a mano.

**05 → 3. Enumera tres cosas que el mesh *no* mueve. 🟢**

⏱️ **30 segundos** — La idempotencia, la semántica del reintento y la degradación. Y el contrato.

🗣️ **2 minutos** — El proxy no sabe si una operación puede repetirse sin duplicar efecto, ni qué
respuesta parcial tiene sentido para el usuario, ni cómo evoluciona tu contrato. Todo eso depende del
dominio y sigue viviendo en la aplicación, con mesh o sin él.

🔬 **El detalle** — Hay un cuarto matiz importante: el mesh propaga el contexto de traza **entre**
servicios pero no **dentro** del tuyo. Lo que pasa entre recibir y responder sigue necesitando
instrumentación propia.

**05 → 4. ¿Cuáles son los cuatro costes de un mesh? 🟢**

⏱️ **30 segundos** — Latencia por los saltos locales, recursos del proxy por instancia, complejidad
operativa del plano de control, y diagnóstico con una capa más.

🗣️ **2 minutos** — La latencia suele ser de orden de milisegundo por salto, lo que se nota en cadenas
largas. Los recursos se multiplican por el número de instancias. Y el diagnóstico cambia: ahora hay
errores que vienen del proxy y hay que saber distinguirlos.

🔬 **El detalle** — El coste que más sorprende es el de actualización: el plano de control y los
proxies tienen sus propias versiones y sus propias migraciones, y mantenerlos al día es trabajo
recurrente que nadie presupuesta al adoptarlo.

**05 → 5. ¿Qué es el plano de control? 🟢**

⏱️ **30 segundos** — El componente que configura a todos los sidecars: les dice qué política aplicar.

🗣️ **2 minutos** — Los proxies forman el plano de datos —por donde pasa el tráfico— y el plano de
control les distribuye certificados, rutas, timeouts y reglas. Separarlos permite cambiar política sin
tocar el tráfico, y es lo que hace que el mesh sea operable. También es la pieza nueva que hay que
aprender, actualizar y vigilar.

🔬 **El detalle** — Cuando el plano de control se cae, el tráfico normalmente sigue: los proxies
conservan la última configuración. Lo que se pierde es la capacidad de cambiar política y, según la
implementación, la emisión de certificados nuevos — que acaba siendo un problema si la caída dura.

**05 → 6. ¿Qué es la doble configuración y qué produce? 🟡**

⏱️ **30 segundos** — Tener reintentos en el proxy y en la librería a la vez: se multiplican.

🗣️ **2 minutos** — Tres intentos en cada capa son nueve llamadas por petición original, y eso ocurre
justo cuando el sistema está degradado. Es el fallo característico del mesh y se descubre en el peor
momento. La corrección es decidir una sola capa de reintento y desactivar la otra explícitamente.

🔬 **El detalle** — Lo mismo aplica a timeouts: si el proxy corta antes que la aplicación, la
aplicación nunca ve el timeout y sus métricas no lo reflejan; si corta después, es el proxy el que
sobra. Conviene que los plazos estén escalonados a propósito y documentados.

**05 → 7. ¿Por qué el mejor argumento del mesh es el poliglotismo? 🟡**

⏱️ **30 segundos** — Porque evita mantener cuatro implementaciones equivalentes de la misma política
en cuatro plataformas.

🗣️ **2 minutos** — Con librerías, cada plataforma tiene su forma de configurar reintentos, su
exportador de métricas y su gestión de certificados; y en cuanto alguien toca una, divergen. El proxy
es idéntico para todas, así que la política se define una vez. Es el argumento que convierte el coste
del poliglotismo en manejable.

🔬 **El detalle** — De ahí se sigue el corolario: si tu sistema es de una sola plataforma, ese
argumento desaparece y hay que justificar el mesh por otra cosa —mTLS generalizado o escala—. Muchas
adopciones fallidas son sistemas homogéneos que adoptaron el mesh por el argumento equivocado.

**05 → 8. ¿Por qué un equipo de Java puede no ver valor en el mesh y uno de Go sí? 🟡**

⏱️ **30 segundos** — Porque el ecosistema de Java ya trae resiliencia, métricas y trazas maduras, y el
de Go espera que lo escribas tú.

🗣️ **2 minutos** — Para un equipo de Java, el mesh duplica lo que ya tiene y encima con menos contexto
de aplicación. Para uno de Go, evita cablear lo mismo en cada servicio. Los dos tienen razón desde su
posición, y por eso la decisión no se puede tomar sin mirar qué plataformas hay.

🔬 **El detalle** — En un sistema mixto esa asimetría genera discusiones: el equipo de Java percibe el
mesh como imposición y el de Go como alivio. Conviene reconocerlo explícitamente y decidir por el
conjunto, no por la plataforma que más voz tenga.

**05 → 9. ¿Por qué mTLS no sustituye a la autorización? 🟡**

⏱️ **30 segundos** — Porque mTLS dice **quién** llama; si ese quien puede hacer eso es otra pregunta.

🗣️ **2 minutos** — El certificado identifica al servicio llamante y cifra el canal, lo que elimina el
riesgo de que cualquiera en la red se haga pasar por otro. Pero que `orders` sea realmente `orders`
no significa que pueda invocar cualquier operación de `payments`. Esa decisión es de dominio y vive en el
servicio.

🔬 **El detalle** — El mesh sí puede aplicar políticas de autorización a nivel de servicio y de ruta
—quién puede llamar a qué—, que es una capa intermedia muy útil. Lo que no puede es autorizar a nivel
de dato: "este usuario solo ve sus pedidos" no es expresable ahí.

**05 → 10. ¿Qué parte de las trazas cubre el mesh y cuál no? 🟡**

⏱️ **30 segundos** — Cubre los saltos entre servicios; no cubre lo que pasa dentro de tu proceso.

🗣️ **2 minutos** — Los proxies generan spans de entrada y salida y propagan el contexto, así que
obtienes el esqueleto de la traza sin instrumentar nada. Pero dentro del servicio —consultas, cálculos,
publicaciones a colas— no hay nada salvo que lo instrumentes. Y el salto asíncrono por broker no pasa
por el proxy en absoluto.

🔬 **El detalle** — Conviene decirlo así en una entrevista: el mesh te da el "dónde" entre servicios y
te deja el "qué" dentro de cada uno. Es una mejora real, no una solución completa, y creer lo contrario
lleva a equipos que dejan de instrumentar.

**05 → 11. ¿Por qué el mesh puede duplicar un cobro? 🟡**

⏱️ **30 segundos** — Porque reintenta sin saber si la operación es idempotente.

🗣️ **2 minutos** — Si el proxy reintenta una llamada que se perdió después de ejecutarse, el cobro se
aplica dos veces. El proxy no tiene forma de saberlo: ve una petición HTTP sin respuesta. Por eso los
reintentos del mesh deben limitarse a lo que es seguro —fallos de conexión— salvo que la operación
tenga clave de idempotencia.

🔬 **El detalle** — La configuración correcta suele ser reintentar en el mesh solo errores de conexión
y respuestas explícitas de indisponibilidad, y dejar en la aplicación los reintentos que dependen de
la semántica. Así se aprovecha la uniformidad sin regalar la corrección.

**05 → 12. ¿Qué cambia el modelo sin sidecar respecto al clásico? 🟡**

⏱️ **30 segundos** — Mueve parte de la función a un componente por nodo en vez de uno por instancia:
menos recursos y menos saltos.

🗣️ **2 minutos** — Reduce el principal reproche al mesh —duplicar contenedores y añadir latencia por
llamada— a cambio de un modelo de aislamiento distinto: el componente compartido atiende a varias
cargas, lo que cambia el radio de impacto de un fallo y la separación entre servicios. Es la respuesta
de la industria a la crítica de coste.

🔬 **El detalle** — No elimina la complejidad del plano de control ni la necesidad de operarlo, así
que el argumento de "un segundo sistema que mantener" sigue en pie. Saber que existe y qué cambia
demuestra que se sigue el tema; presentarlo como la solución a todo, no.

**05 → 13. El plano de control se cae. ¿Qué ocurre con el tráfico? 🟡**

⏱️ **30 segundos** — Normalmente sigue: los proxies conservan la última configuración. Lo que se
pierde es poder cambiarla y, según el caso, emitir certificados nuevos.

🗣️ **2 minutos** — Es una propiedad de diseño deliberada: el plano de datos debe sobrevivir al de
control. El riesgo aparece si la caída se alarga y hay certificados que caducan o instancias nuevas
que no pueden arrancar correctamente. Por eso el plano de control necesita su propia vigilancia y su
plan de recuperación.

🔬 **El detalle** — Conviene probarlo a propósito en un entorno controlado: apagar el plano de control
y comprobar cuánto tiempo sigue todo funcionando. Es un ejercicio barato que cambia mucho la confianza
del equipo y revela dependencias ocultas.

**05 → 14. Tienes seis servicios y una plataforma. ¿Mesh sí o no? Justifica. 🟠**

⏱️ **30 segundos** — No. Con seis servicios y una plataforma, el mesh sería más infraestructura que
aplicación.

🗣️ **2 minutos** — El argumento fuerte del mesh —evitar cuatro implementaciones de la misma política—
no existe aquí, y quedan el plano de control, el doble de contenedores y una capa más de diagnóstico.
Con una plataforma, la librería da lo mismo con más contexto y menos piezas. Lo replantearía si
aparecieran más plataformas o un requisito de mTLS generalizado.

🔬 **El detalle** — Conviene ofrecer la alternativa concreta en vez de solo negarse: librería de
resiliencia común en el chassis, mTLS donde sea obligatorio mediante la plataforma, y métricas
uniformes por convención. Con eso se cubre la mayor parte del beneficio a una fracción del coste.

**05 → 15. Te exigen mTLS en todo el tráfico interno. ¿Qué opciones tienes y cuál eliges? 🟠**

⏱️ **30 segundos** — Mesh, terminación por proxy sin mesh completo, o mTLS en las librerías de cada
plataforma. Con varias plataformas, el mesh.

🗣️ **2 minutos** — Hacerlo en librerías significa gestionar emisión y rotación de certificados en cada
plataforma, que es exactamente donde se producen los fallos de caducidad. El mesh lo automatiza y es
su argumento más sólido. Una opción intermedia es un proxy por servicio sin el resto del mesh, que da
el cifrado sin el plano de control completo.

🔬 **El detalle** — La pregunta que ordena la decisión es quién emite y rota los certificados, y cada
cuánto. Si la respuesta es "a mano, cada año", el requisito acabará incumpliéndose; si hay
automatización, cualquiera de las tres opciones puede funcionar.

**05 → 16. Los reintentos están en el mesh y en la librería. ¿Qué pasa y qué corriges? 🟠**

⏱️ **30 segundos** — Se multiplican: tres por tres son nueve llamadas. Se deja una sola capa.

🗣️ **2 minutos** — La amplificación ocurre justo cuando el destino está degradado, con lo que el
sistema se hunde solo. La corrección es decidir dónde vive el reintento —normalmente en la aplicación,
que sabe de idempotencia— y desactivarlo en el mesh, o al revés dejando en el mesh solo los fallos de
conexión.

🔬 **El detalle** — Se detecta comparando peticiones salientes del cliente con entrantes en el destino
durante un incidente: si la proporción es de varios a uno, hay anidamiento. Conviene tener esa
comparación en un panel antes de necesitarla.

**05 → 17. ¿Qué dejarías siempre en el código aunque tengas mesh? 🟠**

⏱️ **30 segundos** — Idempotencia, degradación, contratos y la instrumentación de lo que pasa dentro
del proceso.

🗣️ **2 minutos** — Son las cuatro cosas que dependen del dominio y que ningún proxy puede decidir: si
una operación puede repetirse, qué respuesta parcial tiene sentido, cómo evoluciona el contrato y qué
está haciendo el servicio entre recibir y responder. El mesh cubre lo transversal, no lo específico.

🔬 **El detalle** — Añadiría los timeouts de negocio: el mesh puede cortar por política general, pero
el plazo que tiene sentido para una operación concreta lo sabe la aplicación. Tener ambos, escalonados
y documentados, es mejor que dejar solo uno.

**05 → 18. ¿Cómo diagnosticas un error que puede venir del servicio o de su sidecar? 🟠**

⏱️ **30 segundos** — Comparando lo que ve la aplicación con lo que ve el proxy: métricas y logs de
ambos, y el código de error.

🗣️ **2 minutos** — Los proxies suelen marcar sus propios errores con códigos o banderas
distinguibles: rechazo por circuit breaker, fallo de conexión ascendente, timeout del proxy. Si la
aplicación no registró ninguna petición y el proxy sí registró un error, el fallo fue antes de llegar.
Es un flujo de diagnóstico nuevo que el equipo tiene que aprender.

🔬 **El detalle** — Es exactamente el coste "una capa más en el diagnóstico" del que habla §4, y se
mitiga con formación y con paneles que muestren ambas vistas juntas. Sin eso, el mesh alarga los
incidentes en vez de acortarlos durante los primeros meses.

**05 → 19. ¿Qué medirías para decidir si el mesh está compensando su coste? 🟠**

⏱️ **30 segundos** — Incidentes evitados o acortados, esfuerzo ahorrado por plataforma, y el coste
real en recursos y latencia.

🗣️ **2 minutos** — En concreto: cuántas veces se ha cambiado política sin desplegar, cuánto tiempo se
habría tardado en implementar lo mismo en cada plataforma, el porcentaje de CPU y memoria que
consumen los proxies, y el aumento de latencia p99. Con esos cuatro números la conversación deja de
ser ideológica.

🔬 **El detalle** — El dato más difícil de conseguir y el más convincente es el de incidentes: si
antes del mesh había fallos por certificados caducados o por resiliencia inconsistente y después no,
eso es el beneficio. Conviene registrar esa categoría de incidente desde antes de adoptarlo.

**05 → 20. Un equipo propone mesh para resolver el balanceo de gRPC. ¿Qué respondes? 🟠**

⏱️ **30 segundos** — Que el mesh lo resuelve, pero es la solución más cara de las tres: también están
el cliente balanceado y el proxy de nivel 7.

🗣️ **2 minutos** — Si el único problema es el reparto por llamada, un proxy que entienda HTTP/2
delante de cada destino lo resuelve sin plano de control. El mesh compensa si además se quieren mTLS,
política uniforme y métricas homogéneas en varias plataformas. La pregunta es qué más problemas
resolvería, no si resuelve este.

🔬 **El detalle** — Conviene dejar claro que adoptar un mesh por un solo problema concreto suele
acabar mal: la pieza se mantiene por inercia y su coste sigue ahí cuando ese problema se resolvió de
otra forma. Si se adopta, que sea por el conjunto.

**05 → 21. Diseña la política de resiliencia repartida entre mesh y código para un sistema con cuatro plataformas, diciendo qué va en cada sitio y por qué. 🔴**

⏱️ **30 segundos** — En el mesh lo uniforme y sin contexto: mTLS, timeouts de red, reintento de
conexión, circuit breaker por instancia. En el código lo que depende del dominio.

🗣️ **2 minutos** — El reparto:

```text
En el MESH                            En el CÓDIGO
──────────────────────────────────    ────────────────────────────────────
mTLS y rotación de certificados       idempotencia y claves de idempotencia
timeout de red (tope duro)            timeout de negocio (más corto, por operación)
reintento SOLO de fallos de conexión  reintento semántico de operaciones seguras
expulsión de instancias con fallos    degradación: qué respuesta parcial dar
balanceo por llamada                  contrato y compatibilidad
métricas y trazas entre servicios     instrumentación dentro del proceso

Regla dura  una sola capa de reintento por tipo de fallo; escrito y verificado
```

🔬 **El detalle** — El escalonado de plazos merece escribirse: el timeout del mesh debe ser mayor que
el de la aplicación, para que el corte lo haga quien tiene contexto y el del proxy sea solo una red
de seguridad. Si está al revés, la aplicación nunca ve sus propios timeouts.

**05 → 22. Escribe el análisis coste-beneficio de adoptar un mesh en un sistema de 25 servicios y tres plataformas, con los números que pedirías antes de decidir. 🔴**

⏱️ **30 segundos** — Coste en recursos y latencia frente a esfuerzo ahorrado en tres plataformas y a
incidentes evitados, con una prueba acotada antes de decidir.

🗣️ **2 minutos** — El análisis:

```text
Números que pediría
  · CPU y memoria actuales por instancia → estimar el coste de 25 proxies
  · p99 actual por servicio → comparar con el de una prueba con mesh
  · incidentes del último año por certificados, resiliencia inconsistente
    o falta de visibilidad → es el beneficio esperable
  · esfuerzo dedicado a mantener librerías equivalentes en 3 plataformas

Beneficio esperado   política uniforme, mTLS automático, canary sin tocar código,
                     métricas homogéneas
Coste esperado       ~25 proxies, 1-2 ms por salto, plano de control que operar,
                     curva de diagnóstico de unos meses
Decisión             prueba con 3-4 servicios de dos plataformas distintas durante
                     un trimestre, midiendo lo anterior, antes de generalizar
```

🔬 **El detalle** — El número más revelador suele ser el cuarto: si el equipo dedica poco tiempo a
mantener las librerías porque ya están estables, el ahorro es menor del que se supone. El coste del
poliglotismo se paga sobre todo al cambiar de política, no en régimen estacionario.

**05 → 23. Diagnostica: tras instalar el mesh, la latencia p99 sube un 30 % y aparecen errores esporádicos de conexión. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Recursos insuficientes para los proxies; timeouts o reintentos duplicados; o el
proxy cerrando conexiones antes que la aplicación.

🗣️ **2 minutos** — Las tres:

```text
1. Proxy sin recursos      los sidecars comparten cuota con el servicio y se
                           quedan cortos: latencia y errores bajo carga.
                           Se ve en CPU y en throttling del propio proxy
2. Doble configuración     timeouts y reintentos en ambas capas: cortes
                           inesperados y amplificación. Se ve comparando plazos
3. Conexiones cerradas     el proxy cierra conexiones ociosas antes que el cliente,
   por el proxy            que reutiliza una conexión ya muerta → error esporádico
```

Las tres se distinguen mirando métricas del proxy —que el mesh expone— junto a las de la aplicación,
que es justo el flujo de diagnóstico nuevo que hay que aprender.

🔬 **El detalle** — La tercera es la más desconcertante porque los errores son intermitentes y no
correlacionan con carga. La corrección es alinear los tiempos de conexión ociosa entre cliente y proxy,
y es un ajuste que casi nadie hace hasta que lo sufre.

**05 → 24. Un equipo quiere migrar toda su resiliencia al mesh en un trimestre. Da tu plan por fases y qué medirías en cada una. 🔴**

⏱️ **30 segundos** — Por fases y por tipo de mecanismo, empezando por lo que no depende del dominio, y
midiendo antes de quitar nada del código.

🗣️ **2 minutos** — El plan:

```text
F1  Mesh en modo observación: métricas y trazas, sin aplicar política.
    Medir: latencia añadida, recursos consumidos, errores nuevos.
F2  mTLS. Es lo que más aporta y no interfiere con la lógica.
    Medir: certificados gestionados, incidentes de caducidad (deberían ser cero).
F3  Timeouts de red y balanceo por llamada. Escalonados con los de la aplicación,
    sin quitar todavía los del código. Medir: cortes por cada capa.
F4  Reintentos de conexión en el mesh, y SOLO entonces desactivar los equivalentes
    del código. Medir: proporción de llamadas salientes/entrantes en incidentes.
F5  Revisión: qué queda en el código a propósito (idempotencia, degradación,
    timeouts de negocio) y se documenta como decisión, no como pendiente.
```

🔬 **El detalle** — La clave del plan es F4: no se quita nada del código hasta haber medido que la
capa nueva hace lo mismo. Migraciones de este tipo fallan casi siempre por quitar primero y medir
después, y el fallo aparece en el siguiente incidente, no en el despliegue.

---

# 06 — Despliegue y entrega

**06 → 1. ¿Por qué el despliegue independiente es el criterio de éxito de la arquitectura? 🟢**

⏱️ **30 segundos** — Porque es el beneficio del que dependen todos los demás: sin él pagas el precio
de la separación y no cobras nada.

🗣️ **2 minutos** — La autonomía de equipo, el escalado diferencial y la velocidad de entrega se
apoyan en poder desplegar un servicio sin los otros. Si hay que desplegar todo junto, tienes un
monolito distribuido: red, sagas y trazas sin el beneficio que las justificaba.

🔬 **El detalle** — La medida operativa es cuántos despliegues hacen falta para el cambio más pequeño
posible. Es una pregunta que se contesta en un minuto y dice más que cualquier diagrama.

**06 → 2. ¿Qué significa construir una vez y promover? 🟢**

⏱️ **30 segundos** — Que el artefacto se construye una sola vez y el mismo pasa por todos los
entornos; lo que cambia es la configuración externa.

🗣️ **2 minutos** — Reconstruir por entorno rompe la garantía de las pruebas: lo que validaste no es lo
que despliegas. Además obliga a tener la configuración dentro del artefacto, con el problema añadido
de los secretos. Y la versión debe ser trazable al commit, porque la primera pregunta de un incidente
es qué hay desplegado.

🔬 **El detalle** — Un matiz práctico: las imágenes deben etiquetarse con la versión concreta y no
solo con una etiqueta móvil. Desplegar por etiqueta móvil hace que dos despliegues "iguales" den
resultados distintos, y es imposible de diagnosticar después.

**06 → 3. Diferencia entre rolling, blue-green y canary. 🟢**

⏱️ **30 segundos** — Rolling reemplaza por tandas; blue-green conmuta entre dos entornos completos;
canary manda un porcentaje del tráfico a la versión nueva y compara métricas.

🗣️ **2 minutos** — Rolling no cuesta infraestructura extra y su vuelta atrás es lenta. Blue-green da
conmutación inmediata a cambio de doble entorno. Canary detecta problemas con una fracción del
tráfico y necesita enrutado por porcentaje y métricas comparables. Las tres exigen que dos versiones
puedan convivir.

🔬 **El detalle** — Canary y blue-green no son excluyentes: se puede conmutar progresivamente hacia el
entorno nuevo, que es lo que hacen muchas plataformas modernas. Lo importante es la propiedad —comparar
antes de comprometerse—, no el nombre.

**06 → 4. ¿Qué es un feature flag y qué separa? 🟢**

⏱️ **30 segundos** — Un interruptor que separa desplegar el código de activar la funcionalidad.

🗣️ **2 minutos** — Permite llevar código a producción apagado y encenderlo después, para un grupo o un
porcentaje, y apagarlo sin desplegar si algo va mal. En microservicios tiene un segundo efecto
valioso: permite integrar continuamente sin ramas largas, porque lo incompleto puede estar en
producción desactivado.

🔬 **El detalle** — El coste real es la acumulación: cada flag es una bifurcación en el código y en las
pruebas. Cincuenta flags vivos son un número de combinaciones que nadie prueba, y por eso deben nacer
con fecha de retirada.

**06 → 5. Enumera los pasos mínimos del pipeline de un servicio. 🟢**

⏱️ **30 segundos** — Construir, pruebas unitarias, pruebas de componente, verificación de contrato,
imagen, migración, desplegar, verificar, promover o revertir.

🗣️ **2 minutos** — El orden importa: la verificación de contrato va antes de desplegar, porque es la
que impide romper a un consumidor; la migración va antes del código y debe ser compatible; y la
verificación posterior es la que hace que la vuelta atrás no dependa de que alguien se dé cuenta.

🔬 **El detalle** — El paso que más cambia la cultura del equipo es el último cuando es automático: si
el pipeline revierte solo al detectar degradación, desplegar deja de dar miedo y la frecuencia sube
sola.

**06 → 6. ¿Qué tres cosas rompen el despliegue independiente? 🟢**

⏱️ **30 segundos** — Un contrato incompatible, una migración destructiva y un pipeline que despliega
varios servicios juntos.

🗣️ **2 minutos** — Las dos primeras son de diseño y se resuelven con compatibilidad y expand/contract.
La tercera es puramente de herramienta y es la más fácil de arreglar: a veces los servicios podrían
desplegarse solos y no lo hacen porque nadie partió el pipeline.

🔬 **El detalle** — Conviene comprobar la tercera antes de rediseñar nada. He visto sistemas
etiquetados como monolito distribuido cuyo único acoplamiento real era un trabajo de CI heredado de
la época del monolito.

**06 → 7. ¿Por qué blue-green no da una vuelta atrás realmente atómica? 🟡**

⏱️ **30 segundos** — Porque la base de datos no se duplica: es la misma para los dos entornos.

🗣️ **2 minutos** — El tráfico se conmuta instantáneamente, pero si la versión nueva aplicó una
migración incompatible, volver al entorno anterior deja al código viejo frente a un esquema que no
entiende. Por eso las migraciones tienen que ser compatibles igualmente, y la estrategia de
despliegue no exime de expand/contract.

🔬 **El detalle** — Duplicar también la base es posible en casos muy concretos —sistemas de solo
lectura, o con sincronización bidireccional— pero introduce problemas de consistencia que suelen ser
peores que el problema que resuelven.

**06 → 8. ¿Por qué las tres estrategias exigen compatibilidad entre versiones? 🟡**

⏱️ **30 segundos** — Porque en las tres conviven dos versiones a la vez, aunque sea brevemente.

🗣️ **2 minutos** — En rolling y canary, la convivencia es prolongada y evidente. En blue-green dura lo
que dure la conmutación, pero además ambas versiones comparten base de datos y colas. Si un mensaje
producido por la versión nueva no lo entiende la vieja, el problema aparece igual.

🔬 **El detalle** — Las colas son el caso que más se olvida: durante la convivencia, consumidores de
ambas versiones leen del mismo topic. El contrato del mensaje tiene que ser compatible en las dos
direcciones, no solo el de la API.

**06 → 9. ¿Qué diferencia hay entre un canary de verdad y un rolling lento? 🟡**

⏱️ **30 segundos** — Que en el canary alguien —o algo— compara métricas de las dos versiones y decide;
si no, es solo un despliegue gradual.

🗣️ **2 minutos** — El valor del canary está en la comparación: tasa de error, latencia y métricas de
negocio de la versión nueva frente a la anterior, con el mismo tipo de tráfico. Sin esa comparación,
desviar un 5 % solo reduce el alcance del daño, que está bien pero no es lo que se prometía.

🔬 **El detalle** — La comparación debe ser automática para que sirva de verdad: si depende de que
alguien mire un panel, funciona en horario de oficina y no a las tres de la mañana, que es cuando
más falta hace.

**06 → 10. ¿Por qué el monorepo no determina si hay microservicios? 🟡**

⏱️ **30 segundos** — Porque lo que define la arquitectura es si puedes desplegar y migrar sin
coordinar, no dónde guardas el código.

🗣️ **2 minutos** — Hay sistemas perfectamente autónomos en un monorepo, con pipelines selectivos por
servicio, y monolitos distribuidos repartidos en cuarenta repositorios que hay que desplegar juntos.
El repositorio afecta a herramientas, a refactor transversal y a propiedad, que son debates
distintos.

🔬 **El detalle** — El riesgo específico del monorepo sí es real: compartir código es tan fácil que la
librería común de dominio aparece sola. Hace falta una regla explícita y, si se puede, una
verificación automática de qué puede importar quién.

**06 → 11. ¿Por qué los flags que deciden reglas de negocio son problemáticos? 🟡**

⏱️ **30 segundos** — Porque acaban siendo configuración de negocio sin gobierno: nadie sabe quién los
cambia ni por qué.

🗣️ **2 minutos** — Un flag técnico es temporal y tiene fecha; un parámetro de negocio —qué descuento
aplica, qué límite tiene un cliente— es permanente y necesita auditoría, versionado y a veces
aprobación. Mezclarlos hace que cambios con consecuencias económicas se hagan con una herramienta
pensada para despliegues.

🔬 **El detalle** — La solución no es prohibirlos sino separarlos: dos mecanismos distintos, con
permisos y trazabilidad distintos. Y en sectores regulados, el parámetro de negocio necesita registro
de quién lo cambió y cuándo, que un sistema de flags rara vez ofrece.

**06 → 12. ¿Por qué el tiempo de arranque es una propiedad operativa y no estética? 🟡**

⏱️ **30 segundos** — Porque decide cuánto tarda un reemplazo, si el escalado llega a tiempo al pico, y
cuánto margen necesita la sonda de arranque.

🗣️ **2 minutos** — Con arranques lentos, el rolling tarda más y cada instancia está fuera de servicio
más tiempo; el escalado automático reacciona tarde y hay que mantener más capacidad de reserva; y si
la sonda de arranque no da margen suficiente, la plataforma mata instancias que estaban levantando
bien.

🔬 **El detalle** — El coste de la capacidad de reserva es el que casi nunca se calcula, y puede ser
mayor que la diferencia de consumo entre plataformas. Es un argumento económico concreto para
discusiones que suelen quedarse en preferencias.

**06 → 13. ¿Qué cambia entre las cuatro plataformas en imagen, arranque y memoria, y qué consecuencia operativa tiene? 🟡**

⏱️ **30 segundos** — Go da binario pequeño, arranque inmediato y poca memoria; Java lo contrario, con
compilación nativa como escape; Node/TS y Python quedan en medio, con el empaquetado como punto
delicado en Python.

🗣️ **2 minutos** — La consecuencia operativa no es estética: con arranques lentos, el reemplazo de
instancias tarda más, el escalado automático llega tarde al pico y hay que mantener capacidad de
reserva, que cuesta dinero de forma continua. También condiciona el margen de la sonda de arranque: si
es demasiado corto, la plataforma mata instancias que estaban levantando bien.

🔬 **El detalle** — El coste de la capacidad de reserva es el que casi nunca se calcula y suele superar
la diferencia de consumo entre plataformas. Es el argumento económico concreto para discusiones que
se quedan en preferencias, y se desarrolla en
[`05-plataformas/01`](../05-plataformas/01-que-cambia-entre-plataformas.md).

---
**06 → 14. Tu pipeline despliega cinco servicios juntos. ¿Cómo compruebas si es necesario? 🟠**

⏱️ **30 segundos** — Intentando desplegar uno solo en un entorno y viendo qué falla; y revisando
contratos y datos compartidos.

🗣️ **2 minutos** — Las preguntas: ¿hay contratos incompatibles entre ellos? ¿comparten esquema o
tablas? ¿dependen de una librería común de dominio? Si la respuesta a las tres es no, el acoplamiento
está solo en la herramienta y partir el pipeline es un trabajo de días con un beneficio inmediato.

🔬 **El detalle** — Conviene empezar por el servicio con menos dependencias entrantes —una hoja del
grafo—: es el que menos riesgo tiene y el que demuestra al equipo que se puede. El orden de las
victorias importa cuando hay que convencer.

**06 → 15. ¿Qué verificas automáticamente tras un despliegue para decidir si promover o revertir? 🟠**

⏱️ **30 segundos** — Tasa de error, latencia p99, y alguna métrica de negocio, comparadas con la
versión anterior y con el mismo periodo previo.

🗣️ **2 minutos** — La comparación tiene que ser contra la versión anterior sirviendo el mismo tipo de
tráfico, no contra un umbral absoluto: un pico de tráfico puede subir la latencia sin que el
despliegue tenga culpa. Y conviene incluir una métrica de negocio —pedidos confirmados por minuto—
porque hay fallos que no producen errores técnicos.

🔬 **El detalle** — El caso que justifica la métrica de negocio: un despliegue que introduce una
validación demasiado estricta devuelve `400`, que muchos paneles no cuentan como error del servidor.
Todo parece bien y los pedidos han caído a la mitad.

**06 → 16. ¿Cómo evitas que los flags se acumulen? 🟠**

⏱️ **30 segundos** — Con fecha de caducidad desde el nacimiento, propietario asignado, y una revisión
periódica que los retire.

🗣️ **2 minutos** — En la práctica funciona bien un inventario automático: listar los flags con su
antigüedad y su estado, y alertar sobre los que llevan más de X semanas en el mismo valor. Y tratar la
retirada como parte del trabajo de la funcionalidad, no como una tarea separada que nunca se prioriza.

🔬 **El detalle** — Ayuda que la herramienta muestre si un flag se está consultando: un flag que nadie
lee es código muerto seguro y se puede quitar sin discusión. Sin ese dato, la retirada siempre parece
arriesgada y se pospone.

**06 → 17. Un equipo quiere blue-green para poder revertir rápido. ¿Qué le adviertes? 🟠**

⏱️ **30 segundos** — Que la base de datos es una sola: si la migración no es compatible, conmutar de
vuelta no arregla nada.

🗣️ **2 minutos** — También que necesita el doble de infraestructura durante el cambio, y que la
conmutación expone a todo el tráfico de golpe a la versión nueva: si hay un problema, lo sufren todos
los usuarios a la vez, no un porcentaje. Para revertir rápido, un canary con automatización suele dar
más seguridad por menos dinero.

🔬 **El detalle** — Hay un caso donde blue-green brilla y conviene reconocerlo: cambios grandes de
infraestructura —versión del entorno de ejecución, del sistema operativo base— donde el rolling
mezclaría configuraciones difíciles de razonar.

**06 → 18. ¿Qué pones en el paso de verificación de contrato del pipeline y por qué ahí? 🟠**

⏱️ **30 segundos** — La verificación de los pactos de todos los consumidores conocidos, antes de
construir la imagen y desplegar.

🗣️ **2 minutos** — Ahí porque es el último momento barato: si el cambio rompe a alguien, el pipeline
del proveedor falla y no llega a producción. Después sería un incidente del consumidor. También entra
la comparación de compatibilidad del esquema —de la API y de los eventos— que detecta las rupturas
estructurales.

🔬 **El detalle** — Requiere un acuerdo organizativo: el equipo proveedor acepta que su pipeline falle
por expectativas de otro equipo. Sin ese acuerdo explícito, alguien acabará desactivando la
verificación un viernes con prisa.

**06 → 19. ¿Cómo organizarías el CI de un monorepo con veinte servicios? 🟠**

⏱️ **30 segundos** — Con construcción selectiva: solo se construye y prueba lo afectado por el cambio,
calculado a partir del grafo de dependencias.

🗣️ **2 minutos** — Sin eso, cada commit dispara veinte construcciones y el pipeline tarda tanto que la
gente deja de integrar. Hace falta además caché de construcción compartida y reglas de propiedad por
carpeta para que las revisiones lleguen a quien corresponde. Y despliegue independiente por servicio,
aunque el repositorio sea único.

🔬 **El detalle** — La parte difícil es calcular bien lo afectado: si el grafo se queda corto, se
despliega algo sin probar; si se pasa, vuelve el problema del tiempo. Conviene ser conservador al
principio y afinar con datos de qué cambios rompen qué.

**06 → 20. ¿Qué haces si una funcionalidad necesita desplegar dos servicios coordinados? 🟠**

⏱️ **30 segundos** — Convertirlo en dos despliegues compatibles: primero el que acepta lo nuevo,
después el que lo usa; y activar con flag.

🗣️ **2 minutos** — Es expand/contract aplicado a la funcionalidad: el proveedor publica la capacidad
nueva de forma compatible, se despliega; el consumidor la usa, se despliega; y la activación conjunta
se hace con un flag, que se enciende cuando ambos están en producción. Así no hay ninguna ventana de
incompatibilidad.

🔬 **El detalle** — Si la coordinación es inevitable por alguna razón real, hay que tratarla como una
excepción declarada: escribir el orden, el plan de vuelta atrás y quién lo ejecuta. Lo que no puede
ser es que la coordinación sea la forma normal de trabajar.

**06 → 21. ¿Qué métricas de entrega seguirías para saber si el sistema mejora? 🟠**

⏱️ **30 segundos** — Frecuencia de despliegue, tiempo desde el commit hasta producción, porcentaje de
despliegues que fallan, y tiempo de recuperación.

🗣️ **2 minutos** — Son las cuatro métricas clásicas de entrega y funcionan bien porque son difíciles
de manipular a la vez: se puede desplegar mucho y mal, o poco y bien, pero mejorar las cuatro implica
mejorar de verdad. Y son un buen contraste de la promesa de la arquitectura: si separar servicios no
mejora la frecuencia ni el tiempo de entrega, algo no está funcionando.

🔬 **El detalle** — Conviene medirlas **por servicio** además de en conjunto: un promedio bueno puede
esconder tres servicios que nadie se atreve a tocar. Esos tres suelen ser los que tienen el
acoplamiento que hay que arreglar.

**06 → 22. Tu servicio escala a golpes contra picos de tráfico. ¿Qué cambia según esté escrito en Java o en Go, y qué harías en cada caso 🟠**

⏱️ **30 segundos** — Cambia cuánto tarda en servir la instancia nueva. En Go, casi nada; en Java, segundos
que el pico no espera.

🗣️ **2 minutos** — Go arranca prácticamente al instante desde una imagen pequeña, así que el escalado
reactivo funciona: la instancia nueva llega a tiempo. Java arranca en segundos y ocupa más memoria en
reposo, de modo que escalar cuando el pico ya está encima llega tarde. En Java las salidas son
anticipar el escalado con una métrica adelantada, sobredimensionar la base mínima, o recortar el
arranque con compilación nativa —que a su vez encarece la construcción—. Node/TS queda en medio, con el
peso del árbol de dependencias como factor; Python parecido, y con el modelo de ejecución como el
detalle que decide.

🔬 **El detalle** — Lo que importa decir en voz alta es que esto no es estética sino configuración
operativa concreta: el tiempo de arranque fija la sonda de arranque, el margen del escalado automático y
si el despliegue rolling resulta lento. Es la propiedad de la plataforma con consecuencia más directa en
la factura y en el incidente.

---
**06 → 23. Diseña el pipeline completo de `orders`, desde el commit hasta producción, con los puntos de decisión y de vuelta atrás. 🔴**

⏱️ **30 segundos** — Construcción única, pruebas por capas, contratos, migración compatible,
despliegue gradual con verificación automática y vuelta atrás por código.

🗣️ **2 minutos** — El pipeline:

```text
Etapa                      Falla → qué pasa
─────────────────────────  ──────────────────────────────────────────
1 construir + unitarias    se para; nada sale del repositorio
2 componente (dependencias se para; el fallo es del propio servicio
  simuladas)
3 verificar pactos de los  se para; el cambio rompería a un consumidor
  consumidores             → se habla con él o se hace compatible
4 imagen etiquetada con    —
  la versión del commit
5 migración compatible     se para ANTES de desplegar código;
  (paso explícito)         la migración vieja sigue sirviendo
6 despliegue canary 5 %    —
7 verificación automática  revertir: bajar el porcentaje a cero
  (errores, p99, negocio)
8 promoción gradual        revertir en cualquier punto
9 100 % y marca de versión vuelta atrás = desplegar versión anterior
                           (el esquema es compatible, así que es seguro)
```

🔬 **El detalle** — El punto 5 tiene una condición que sostiene todo lo demás: como la migración es
compatible hacia atrás, la vuelta atrás del paso 9 no necesita tocar la base. Si esa condición no se
cumple, el pipeline entero deja de ser reversible y hay que tratar el despliegue como una operación
de riesgo.

**06 → 24. Diseña el despliegue de un cambio que afecta a `orders` y a `inventory` a la vez, sin desplegarlos coordinados. 🔴**

⏱️ **30 segundos** — Tres despliegues independientes y compatibles, con activación por flag al final.

🗣️ **2 minutos** — El plan:

```text
1. inventory acepta el formato NUEVO y el viejo (compatible). Se despliega solo.
   Nada cambia de comportamiento todavía.
2. orders empieza a enviar el formato nuevo, detrás de un flag apagado.
   Se despliega solo.
3. Se enciende el flag para un porcentaje y se verifica.
4. Se sube al 100 %; se observa unos días.
5. inventory deja de aceptar el formato viejo (contracción). Se despliega solo.
6. orders retira el flag y el código del formato viejo.
```

En ningún momento hay que desplegar los dos a la vez, y en cada paso se puede volver atrás.

🔬 **El detalle** — El paso 5 es el que se olvida y el que deja el sistema con dos caminos vivos para
siempre. Conviene programarlo desde el paso 1 —con fecha— y tratarlo como parte del trabajo, no como
limpieza opcional.

**06 → 25. Escribe la política de feature flags del equipo: tipos, propiedad, caducidad y verificación. 🔴**

⏱️ **30 segundos** — Distinguir flags técnicos temporales de parámetros de negocio permanentes, con
dueño y fecha para los primeros.

🗣️ **2 minutos** — La política:

```text
Tipos
  · de despliegue   temporal, técnico; caduca en ≤ 2 sprints
  · de operación    activar/desactivar una integración; permanente, documentado
  · de negocio      NO es un flag: es configuración con auditoría y permisos propios
Propiedad          cada flag tiene un dueño nominal; sin dueño no se crea
Caducidad          fecha obligatoria al crearlo; alerta al superarla
Retirada           parte de la definición de terminado de la funcionalidad
Verificación       inventario automático: antigüedad, valor actual, último uso
                   alerta de flags sin consultar (código muerto)
Prohibido          flags anidados que creen combinaciones no probadas
```

🔬 **El detalle** — La regla contra los flags anidados es la que más incidentes evita: dos flags
independientes dan cuatro combinaciones y solo se prueban dos. Si hace falta una combinación concreta,
es mejor un único flag con varios valores que dos booleanos.

**06 → 26. Diagnostica: los despliegues producen un goteo de errores cada vez, y nadie sabe por qué. Da tres hipótesis ordenadas y cómo las distingues. 🔴**

⏱️ **30 segundos** — Falta apagado ordenado; contrato o esquema incompatible durante la convivencia;
o pérdida de capacidad durante el reemplazo.

🗣️ **2 minutos** — Las tres:

```text
1. Sin apagado ordenado   las instancias mueren con peticiones en vuelo.
                          Se distingue: los errores son de conexión y cesan al
                          terminar el reemplazo
2. Incompatibilidad       la versión vieja y la nueva no se entienden: errores
   durante la convivencia de validación o de deserialización, no de conexión.
                          Se distingue por el tipo de error y porque afecta a
                          una funcionalidad concreta
3. Capacidad insuficiente  durante el reemplazo hay menos instancias y el sistema
                          va justo. Se distingue: latencia alta y errores por
                          timeout, proporcionales al tráfico
```

🔬 **El detalle** — Conviene mirar el tipo de error antes que cualquier otra cosa: conexión apunta a
apagado, validación a contrato, timeout a capacidad. Esa clasificación resuelve el caso en minutos y
casi nunca se hace, porque el reflejo es mirar el log del servicio desplegado.

---

# 07 — Testing de microservicios

**07 → 1. ¿Por qué se deforma la pirámide de pruebas en microservicios? 🟢**

⏱️ **30 segundos** — Porque las pruebas de extremo a extremo se vuelven caras y frágiles, y su papel
lo asumen las de componente y las de contrato.

🗣️ **2 minutos** — Una prueba de extremo a extremo necesita todos los servicios desplegados en
versiones compatibles, sus bases coherentes y el entorno libre. El peso se desplaza hacia abajo: muchas
de componente, que prueban el servicio entero aislado, y de contrato, que responden si sigues
encajando con tus consumidores.

🔬 **El detalle** — La idea central de la pirámide sigue valiendo: más pruebas cuanto más baratas y
rápidas. Lo que cambia es qué capa cubre la integración entre sistemas, que pasa de un entorno
compartido a un artefacto verificable.

**07 → 2. ¿Qué es una prueba de componente? 🟢**

⏱️ **30 segundos** — Probar el servicio entero por su API pública, con las dependencias externas
simuladas o en contenedor efímero.

🗣️ **2 minutos** — Cubre lo que las unitarias no ven: enrutado, serialización, validación, manejo de
errores y acceso a datos reales. Es la capa que más rinde en microservicios porque da casi la misma
confianza que una de extremo a extremo sin depender de nadie más.

🔬 **El detalle** — La clave es usar la base de datos real en contenedor en vez de una en memoria: el
dialecto, los tipos, las transacciones y los bloqueos se comportan distinto, y esas diferencias son
justo las que aparecen en producción.

**07 → 3. ¿Qué papel juegan los contratos en la estrategia de pruebas? 🟢**

⏱️ **30 segundos** — Sustituyen al entorno de integración completo: responden si sigues encajando con
tus consumidores, sin levantar nada.

🗣️ **2 minutos** — El pacto publicado por el consumidor se verifica en el pipeline del proveedor, en
segundos, y su fallo tiene un único significado: este cambio rompe a alguien. Frente a un entorno
compartido que falla por mil motivos, la señal es inequívoca.

🔬 **El detalle** — Lo que no cubren es que el flujo de negocio completo funcione: verifican una
interacción, no una saga. Por eso quedan unas pocas pruebas de extremo a extremo para los flujos
críticos.

**07 → 4. ¿Qué pruebas de extremo a extremo sobreviven? 🟢**

⏱️ **30 segundos** — Los flujos críticos de negocio, contados con los dedos de una mano: confirmar un
pedido y un flujo de compensación.

🗣️ **2 minutos** — Cada una cuesta mantenimiento constante y falla por motivos ajenos, así que la
selección es despiadada. La regla práctica: si una falla y nadie investiga, hay que borrarla, porque
ya no aporta señal y sí ruido que entrena al equipo a ignorar los fallos.

🔬 **El detalle** — El flujo de compensación merece estar ahí precisamente porque es el camino que
nunca se ejecuta en condiciones normales. Es el que está roto cuando hace falta, y solo una prueba lo
descubre antes.

**07 → 5. Nombra tres formas de probar en producción. 🟢**

⏱️ **30 segundos** — Despliegue oscuro con copia del tráfico, canary con métricas comparadas, y
verificación sintética periódica.

🗣️ **2 minutos** — El despliegue oscuro valida la versión nueva con tráfico real y sin efectos; el
canary expone un porcentaje y compara; y la verificación sintética ejecuta un flujo de negocio
completo cada pocos minutos contra producción. Las tres son controladas y ninguna es temeraria.

🔬 **El detalle** — La sintética es la que más rinde y la menos usada: un pedido de prueba cada cinco
minutos detecta fallos que ninguna métrica técnica ve, porque comprueba el flujo tal como lo vive el
usuario, incluidas las integraciones externas.

**07 → 6. Enumera cuatro cosas que casi nadie prueba. 🟢**

⏱️ **30 segundos** — La idempotencia del consumidor, el apagado ordenado, las migraciones sobre
volumen realista, y el camino de compensación de la saga.

🗣️ **2 minutos** — Las cuatro son baratas de escribir y cubren fallos caros y difíciles de
diagnosticar. La de idempotencia es la que mejor relación tiene: procesar dos veces el mismo mensaje
en una prueba de componente con base real y comprobar que el efecto se aplicó una sola vez.

🔬 **El detalle** — El apagado ordenado no se prueba con una prueba unitaria sino con un ejercicio
operativo: desplegar con tráfico y comprobar que no aparecen errores. Vale igual para las cuatro
plataformas, que es justo lo que se necesita en un sistema políglota.

**07 → 7. ¿Qué dos herramientas igualan la estrategia de pruebas en las cuatro plataformas? 🟢**

⏱️ **30 segundos** — El simulador de servidor HTTP y el contenedor efímero: los dos existen en las
cuatro, y son los que permiten tener la misma estrategia en un sistema políglota.

🗣️ **2 minutos** — El contenedor efímero levanta la base y el broker reales, que es lo que hace
fiables las pruebas de componente; el simulador de HTTP sustituye a los otros servicios, cuyo
comportamiento ya cubren los pactos. Con esas dos piezas, el nivel de componente se escribe igual en
Java, Node/TS, Go y Python, y los resultados son comparables entre equipos.

🔬 **El detalle** — Lo que sí cambia es el ejecutor y los dobles: Java tiene el ecosistema más
completo, Go escribe los dobles a mano —lo que suele ser una ventaja— y Python usa accesorios
reutilizables que conviene no convertir en un sistema paralelo ilegible.

---
**07 → 8. ¿Por qué un entorno de integración compartido enseña a ignorar los fallos? 🟡**

⏱️ **30 segundos** — Porque falla a menudo por motivos ajenos al cambio, y el equipo aprende a
reintentar sin mirar.

🗣️ **2 minutos** — Cuando un fallo tiene diez causas posibles —otro equipo desplegando, datos
inconsistentes, una versión incompatible— el coste de investigar cada uno es alto y el beneficio
incierto. En pocas semanas, "reintenta el pipeline" se convierte en la respuesta estándar, y a partir
de ahí la suite ya no detecta nada.

🔬 **El detalle** — Es un problema de señal, no de cobertura: una suite que falla el 30 % de las veces
sin motivo real tiene un valor informativo cercano a cero, aunque cubra mucho código. Por eso a veces
borrar pruebas mejora la calidad.

**07 → 9. ¿Por qué una base en memoria no sustituye a la real en contenedor? 🟡**

⏱️ **30 segundos** — Porque se comporta distinto en dialecto, tipos, transacciones y bloqueos, que es
justo donde aparecen los fallos.

🗣️ **2 minutos** — Una consulta que funciona en la base en memoria puede fallar en producción por una
función no soportada; un índice único puede comportarse distinto; y el aislamiento transaccional casi
nunca coincide. El resultado es una suite verde que no protege de nada en la capa de datos.

🔬 **El detalle** — El argumento de la velocidad ya no aplica: los contenedores efímeros arrancan en
segundos y se pueden reutilizar entre pruebas. Es una de las pocas mejoras de los últimos años que
elimina un compromiso en lugar de cambiarlo de sitio.

**07 → 10. ¿Qué diferencia hay entre una prueba de contrato y una de integración? 🟡**

⏱️ **30 segundos** — La de contrato no levanta el otro servicio: verifica una expectativa publicada.
La de integración sí usa la dependencia real.

🗣️ **2 minutos** — El pacto se ejecuta en el pipeline del proveedor contra las expectativas de sus
consumidores, en segundos y sin red. La de integración comprueba que hablas bien con una dependencia
concreta —tu base de datos, el broker— y necesita esa dependencia disponible, normalmente en
contenedor.

🔬 **El detalle** — Son complementarias: el contrato garantiza que la forma y el comportamiento
acordados se mantienen; la integración garantiza que tu código habla bien con la tecnología real. Ni
una sustituye a la otra.

**07 → 11. ¿Por qué un pacto no debe declarar toda la respuesta del proveedor? 🟡**

⏱️ **30 segundos** — Porque entonces cualquier campo nuevo —un cambio compatible— rompe el pacto.

🗣️ **2 minutos** — El pacto debe expresar lo que el consumidor **necesita**, no todo lo que recibe. Si
declara de más, el proveedor pierde la libertad de añadir campos, que es justo la evolución que la
compatibilidad permitía. Y además se declara la forma, no los valores exactos, para no acoplarse a
datos de prueba.

🔬 **El detalle** — Cuando los pactos bloquean cambios a menudo, la causa suele ser esta. Merece una
revisión conjunta entre equipos: un pacto demasiado estricto convierte una herramienta de
colaboración en una fuente de fricción.

**07 → 12. ¿Qué es la verificación sintética y qué detecta que no detectan las métricas? 🟡**

⏱️ **30 segundos** — Ejecutar un flujo de negocio real contra producción periódicamente; detecta que
el flujo completo no funciona aunque todas las piezas parezcan sanas.

🗣️ **2 minutos** — Las métricas técnicas pueden estar verdes mientras el flujo está roto: una
integración externa que devuelve `200` con un error dentro, una regla nueva que rechaza todos los
pedidos, un consumidor que no está corriendo. La sintética lo prueba como usuario y falla cuando falla
el resultado, no el transporte.

🔬 **El detalle** — Hay que diseñar el aislamiento de sus datos: cuentas y productos de prueba
marcados, excluidos de informes y de facturación. Sin eso, contamina los datos de negocio y alguien
acabará desactivándola.

**07 → 13. ¿Qué te da cada plataforma para las pruebas de componente, y cuál es el nivelador común? 🟡**

⏱️ **30 segundos** — El nivelador es la familia de contenedores efímeros para pruebas, que existe en
las cuatro; lo que cambia es el ejecutor y los dobles.

🗣️ **2 minutos** — Java tiene el ecosistema más completo: arranque del contexto en pruebas,
contenedores integrados, simuladores de HTTP maduros y verificación de pactos. Node/TS tiene
ejecutores rápidos y simuladores a nivel de red. Go trae pruebas y servidor de prueba en la librería
estándar, y los dobles se escriben a mano, que suele ser una ventaja. Python tiene un ejecutor muy
expresivo con accesorios reutilizables. En las cuatro, la prueba de componente con la base real en
contenedor es la que más rinde.

🔬 **El detalle** — Que exista contenedor efímero en las cuatro es lo que permite tener la misma
estrategia de pruebas en un sistema políglota: el nivel de componente se escribe igual en todas, con
la base y el broker reales, y eso hace comparables los resultados entre equipos.

---
**07 → 14. ¿Cómo se prueba la idempotencia de un consumidor? 🟠**

⏱️ **30 segundos** — Entregándole el mismo mensaje dos veces y comprobando que el efecto se aplicó una
sola vez.

🗣️ **2 minutos** — Se hace en una prueba de componente con la base real, porque la deduplicación suele
depender de un índice único. Y conviene una segunda prueba del caso difícil: fallo después de aplicar
el efecto y antes de confirmar, que es lo que provoca la reentrega real en producción.

🔬 **El detalle** — Es la prueba con mejor relación entre esfuerzo y valor del corpus: cuesta diez
líneas y cubre el fallo que produce cobros duplicados. Mencionarla en una entrevista de testing suele
destacar porque es concreta y se nota que viene de haber tenido el problema.

**07 → 15. Tu suite de extremo a extremo falla el 30 % de las veces por motivos ajenos. ¿Qué haces? 🟠**

⏱️ **30 segundos** — Reducirla a los dos o tres flujos críticos y cubrir el resto con componente y
contratos.

🗣️ **2 minutos** — Una suite con ese nivel de ruido no aporta señal: el equipo ya la ignora. El plan es
clasificar qué comprueba cada prueba, mover lo que sea de un solo servicio a pruebas de componente, lo
que sea de interacción a contratos, y quedarse con los flujos de negocio que de verdad justifiquen el
coste.

🔬 **El detalle** — Conviene medir antes y después con un indicador simple: porcentaje de fallos que
resultaron ser problemas reales. Si sube del 20 % al 90 %, la suite ha vuelto a ser útil aunque tenga
diez veces menos pruebas.

**07 → 16. ¿Cómo probarías el camino de compensación de una saga? 🟠**

⏱️ **30 segundos** — Forzando el fallo del paso pivote en una prueba de componente y verificando el
estado final y los efectos compensados.

🗣️ **2 minutos** — Se simula el servicio de pagos devolviendo un rechazo, y se comprueba que la saga
pasa a compensando, que se emite la orden de liberar y que el estado final es cancelado. Conviene
probar también el caso en que la compensación falla, para verificar que acaba en la bandeja de casos
atascados y no en un limbo.

🔬 **El detalle** — Y un tercer caso muy rentable: el vencimiento. Adelantar el reloj o reducir el
plazo en la prueba para comprobar que una saga que se queda sin respuesta acaba compensando sola. Es
el fallo que deja stock bloqueado en producción.

**07 → 17. ¿Cómo pruebas que el apagado ordenado funciona? 🟠**

⏱️ **30 segundos** — Con un ejercicio operativo: desplegar con tráfico real y comprobar que no
aparecen errores durante el reemplazo.

🗣️ **2 minutos** — Es una prueba de sistema, no unitaria: se genera carga constante, se fuerza un
reemplazo de instancias y se mira la tasa de error. Si aparece un goteo, el apagado no está
funcionando o el margen de propagación es demasiado corto. Vale igual para las cuatro plataformas,
que es lo que se necesita en un sistema políglota.

🔬 **El detalle** — Conviene hacerlo también con el consumidor de mensajes, que tiene su propia
secuencia: dejar de pedir, terminar el actual, confirmar y cerrar. El fallo típico ahí no son errores
visibles sino mensajes reentregados, que solo se detectan mirando duplicados.

**07 → 18. ¿Qué dependencias simularías y cuáles levantarías de verdad en una prueba de componente? 🟠**

⏱️ **30 segundos** — Levanto de verdad la base de datos y el broker; simulo los otros servicios.

🗣️ **2 minutos** — La base y el broker son tecnología de la que dependo directamente y cuyo
comportamiento quiero verificar: dialecto, transacciones, confirmaciones. Los otros servicios son
contratos y por eso se simulan: su comportamiento real está cubierto por los pactos, y levantarlos
convertiría la prueba en una de extremo a extremo.

🔬 **El detalle** — Hay un caso intermedio: dependencias externas de terceros. Si tienen un simulador
oficial, merece la pena usarlo; si no, un simulador de HTTP con respuestas grabadas de producción es
lo más fiel que se puede conseguir sin depender de su disponibilidad.

**07 → 19. ¿Cómo evitas que los datos de la verificación sintética ensucien producción? 🟠**

⏱️ **30 segundos** — Con entidades marcadas como de prueba, excluidas de informes, facturación y
notificaciones.

🗣️ **2 minutos** — Lo habitual es una cuenta y unos productos reservados, con una marca explícita en
el modelo. Esa marca se propaga a los eventos, de modo que consumidores como facturación o marketing
los ignoren. Y conviene un proceso de limpieza que borre los registros pasado un tiempo.

🔬 **El detalle** — La marca tiene que estar en el modelo y no solo en el identificador: filtrar por
"pedidos cuyo cliente empieza por TEST" funciona hasta que alguien escribe una consulta nueva y no lo
sabe. Un campo explícito es más difícil de ignorar por accidente.

**07 → 20. Un equipo no tiene contratos y quiere quitar el entorno de integración. ¿Por dónde empieza? 🟠**

⏱️ **30 segundos** — Por escribir pactos de las dos o tres interacciones que más incidentes han
causado, y verificarlos en el pipeline del proveedor.

🗣️ **2 minutos** — El orden importa: primero pactos de las interacciones críticas, después pruebas de
componente sólidas en cada servicio, y solo entonces se reduce el entorno. Quitar la red de seguridad
antes de tener la nueva es cómo se pierde la confianza del equipo y se vuelve atrás.

🔬 **El detalle** — Conviene elegir como primer par a dos equipos dispuestos: el mecanismo exige
cooperación —uno publica, otro verifica— y una primera experiencia negativa por fricción
organizativa puede enterrar la práctica antes de que demuestre su valor.

**07 → 21. ¿Qué experimento de caos harías primero en un sistema sin experiencia previa? 🟠**

⏱️ **30 segundos** — Matar una instancia de un servicio en horario controlado, con hipótesis escrita
de qué debería pasar.

🗣️ **2 minutos** — Es el experimento más barato y el que más enseña: comprueba apagado ordenado,
reintentos del cliente, descubrimiento y reequilibrio de conexiones, todo a la vez. La hipótesis
previa es lo que lo convierte en experimento: "esperamos cero errores visibles"; si aparecen, ya
tienes el primer trabajo.

🔬 **El detalle** — El segundo experimento natural es añadir retraso a una dependencia —no caída, sino
lentitud—, porque la lentitud es lo que propaga los fallos y casi nunca se prueba. Suele revelar
timeouts mal puestos que nadie había mirado.

**07 → 22. ¿Cómo pruebas una migración antes de producción de forma realista? 🟠**

⏱️ **30 segundos** — Sobre una copia de producción de tamaño real, cronometrándola y con carga
simulada encima para ver bloqueos.

🗣️ **2 minutos** — Lo que importa es el volumen y la distribución de datos: lo que tarda dos segundos
con diez mil filas puede tardar veinte minutos con cuarenta millones. Y hay que probar también el
camino de vuelta, y comprobar que el código anterior sigue funcionando contra el esquema migrado.

🔬 **El detalle** — Si no se puede tener una copia completa por tamaño o por datos sensibles, una copia
anonimizada del mismo volumen sirve igual para medir tiempos y bloqueos. Lo que no vale es extrapolar
linealmente desde un entorno pequeño.

**07 → 23. Diseña la estrategia de pruebas completa de `orders`: qué se prueba en cada nivel, con qué, y qué queda fuera a propósito. 🔴**

⏱️ **30 segundos** — Unidad para el dominio, componente con base y broker reales en contenedor,
contratos con sus consumidores, y dos pruebas de extremo a extremo.

🗣️ **2 minutos** — La estrategia:

```text
Nivel        Qué prueba                              Con qué
───────────  ──────────────────────────────────────  ──────────────────────────
unidad       reglas del pedido, transiciones de      nada
             estado, cálculo de totales
componente   API completa, persistencia, outbox,     base y broker en contenedor;
             consumo de eventos, idempotencia        inventory y payments simulados
contrato     lo que esperan sus consumidores (BFF)   pactos publicados
             y lo que él espera de inventory/payments
integración  cliente HTTP con timeouts y reintentos  simulador de HTTP con retrasos
e2e          confirmación completa + compensación    entorno efímero, solo esos dos
producción   verificación sintética cada 5 min       datos marcados como de prueba

Fuera a propósito: pruebas de interfaz de usuario, pruebas de carga en cada commit,
y cualquier e2e que no sea uno de esos dos flujos.
```

🔬 **El detalle** — La prueba de integración del cliente con retrasos simulados es la que casi nadie
escribe y la que verifica que los timeouts y reintentos están bien configurados. Sin ella, esa
configuración solo se prueba en el primer incidente.

**07 → 24. Diseña la prueba de extremo a extremo del flujo de confirmación, decidiendo qué se levanta, qué se simula y cómo se mantiene estable. 🔴**

⏱️ **30 segundos** — Entorno efímero con los tres servicios y sus dependencias en contenedor, terceros
simulados, datos creados por la propia prueba, y verificación por estado final.

🗣️ **2 minutos** — El diseño:

```text
Se levanta     orders, inventory, payments, sus bases y el broker, en contenedores
               efímeros creados por la prueba
Se simula      la pasarela de pago externa (no se depende de un tercero)
Datos          los crea la prueba y los destruye al final; nada compartido
Verificación   por estado final consultando las APIs, con espera activa y límite
               (el flujo es asíncrono: no se puede asertar inmediatamente)
Estabilidad    sin esperas fijas; reintento con límite hasta el estado esperado
               y fallo con un mensaje que diga en qué estado se quedó
Aislamiento    cada ejecución con su propio entorno: nunca compartido entre ramas
```

🔬 **El detalle** — La espera activa con límite es lo que distingue una prueba estable de una
intermitente: las esperas fijas fallan en máquinas lentas y ralentizan en las rápidas. Y el mensaje de
fallo debe decir el estado alcanzado, porque "se esperaba `PAID` y quedó en `CONFIRMED`" ahorra media
hora de investigación.

**07 → 25. Un sistema tiene 200 pruebas de extremo a extremo y tardan dos horas. Escribe el plan para reducirlas sin perder confianza. 🔴**

⏱️ **30 segundos** — Clasificarlas por lo que comprueban, bajar cada una al nivel más barato que la
cubra, y quedarse con los flujos críticos.

🗣️ **2 minutos** — El plan:

```text
Semana 1  Clasificar las 200: ¿qué comprueba cada una?
          · lógica de un servicio      → baja a componente
          · interacción entre dos      → baja a contrato
          · flujo de negocio completo  → se queda (serán unas pocas)
          · duplicada                  → se borra
Semana 2-4 Escribir las de componente y los pactos que sustituyen a las que bajan.
          NO se borra ninguna e2e hasta que su sustituta esté verde.
Semana 5  Reducir el entorno compartido; e2e solo en entornos efímeros.
Continuo  Métrica: porcentaje de fallos que resultan ser problemas reales.
          Objetivo: por encima del 80 %.
```

🔬 **El detalle** — El orden —escribir la sustituta antes de borrar— es lo que hace que el equipo
acepte el plan. Borrar primero y prometer que se cubrirá después es la versión que fracasa, porque el
primer incidente se atribuye a la reducción aunque no tenga relación.

**07 → 26. Diseña el conjunto de verificaciones sintéticas del sistema: qué flujos, cada cuánto, qué datos y qué alertas. 🔴**

⏱️ **30 segundos** — Tres o cuatro flujos de negocio críticos, cada pocos minutos, con datos marcados,
y alerta tras dos fallos consecutivos.

🗣️ **2 minutos** — El diseño:

```text
Flujo                         Frecuencia   Qué verifica
────────────────────────────  ───────────  ────────────────────────────────
consultar catálogo            1 min        lectura y borde disponibles
confirmar pedido completo     5 min        el flujo entero, incluida la saga
consultar estado de un pedido 5 min        proyección actualizada y coherente
cobro con pasarela (sandbox)  15 min       la integración externa responde

Datos      cliente y productos marcados como sintéticos; excluidos de informes,
           facturación y notificaciones; limpieza diaria
Alertas    dos fallos consecutivos del mismo flujo → aviso
           un fallo del flujo de cobro → aviso inmediato
Medición   se registra la latencia de cada flujo: es el mejor indicador de
           experiencia de usuario que vas a tener
```

🔬 **El detalle** — La latencia de la verificación sintética es una métrica infravalorada: mide el
flujo completo como lo vive el usuario, incluidos terceros y colas, y suele revelar degradaciones que
las métricas por servicio no muestran porque cada pieza está dentro de su objetivo.

---

# 08 — Simulación de entrevista

**Sobre las preguntas `S#`.** Están cubiertas por las preguntas de los siete capítulos del bloque:
`S1`–`S5` por [`01`](01-descubrimiento-y-enrutamiento.md) y [`02`](02-api-gateway-y-bff.md),
`S6`–`S11` por [`03`](03-resiliencia-en-la-practica.md), `S12`–`S16` por
[`04`](04-observabilidad-y-trazas.md), `S17`–`S20` por [`05`](05-service-mesh-y-sidecar.md),
`S21`–`S25` por [`06`](06-despliegue-y-entrega.md) y `S26`–`S30` por
[`07`](07-testing-de-microservicios.md). Las de "las que descolocan" —`S31` a `S35`— se practican en
voz alta.

**04/08 → E1. La cascada de latencia.**

⏱️ **30 segundos** — Se está agotando el pool de hilos de `orders`, que espera a una cadena cuyo
último salto tarda ocho segundos. El detonante es la consulta lenta; la causa es que no hay timeout
ni aislamiento.

🗣️ **2 minutos** — La cadena y el orden de corrección:

```text
payments lento (índice perdido)
  │  ← corrección 4: arreglar el índice (detonante, no causa)
segments y customers esperan a payments
  │
orders: sus hilos esperan la cadena completa
  │  ← corrección 1: timeout explícito y decreciente por salto
pool de hilos agotado
  │  ← corrección 2: pool separado por dependencia (bulkhead)
orders deja de atender TODO, también /catalog y /profile
  │  ← corrección 3: circuit breaker hacia la dependencia degradada
  │  ← corrección 5: degradación (responder sin ese dato)
```

Orden por relación entre efecto y esfuerzo: timeout (una línea, evita el agotamiento) → bulkhead
(convierte la caída total en parcial) → circuit breaker (deja de gastar en lo que ya falla) →
índice (arregla el detonante) → degradación (decisión de producto).

🔬 **El detalle** — La pregunta de seguimiento es siempre por qué fallan también las rutas que no tocan
`payments`: porque el recurso agotado es compartido —el pool del servidor—, y ese es el argumento
estructural del bulkhead. Y conviene nombrar que la latencia se **suma** por la cadena: con timeouts
de dos segundos en cada salto y sin presupuesto total, el usuario puede esperar diez segundos antes de
recibir un error.

**04/08 → E2. Estrategia de pruebas y pipeline del noveno servicio.**

⏱️ **30 segundos** — Muchas de componente con dependencias en contenedor, contratos de consumidor, y
solo dos pruebas de extremo a extremo. El entorno compartido no entra en el plan.

🗣️ **2 minutos** — El diseño:

```text
Pruebas
  unidad        reglas del dominio
  componente    el servicio entero con base y broker en contenedores efímeros;
                los otros servicios, simulados
  contrato      pactos con sus consumidores y con sus proveedores,
                verificados en el pipeline del proveedor
  integración   cliente HTTP con retrasos simulados: verifica timeouts y reintentos
  e2e           dos: confirmación completa y el camino de compensación
  producción    verificación sintética del flujo principal cada 5 min

Pipeline
  construir → unitarias → componente → verificar pactos → imagen →
  migración (compatible) → canary → verificación automática → promoción

Lo que NO voy a hacer
  · no añado este servicio al entorno de integración compartido
  · no escribo e2e nuevas más allá de esas dos
  · no activo reintentos por defecto en el cliente
```

🔬 **El detalle** — Declarar explícitamente lo que no se va a hacer es la parte que más puntúa, porque
demuestra que se conoce el coste de cada práctica. Y hay una decisión con consecuencia organizativa:
verificar pactos implica que el pipeline de este servicio puede fallar por expectativas de otro
equipo, y eso hay que acordarlo antes de activarlo, no el día que falle.

**04/08 → E3. El despliegue que gotea errores.**

⏱️ **30 segundos** — Tres hipótesis: falta apagado ordenado, incompatibilidad entre versiones
conviviendo, o capacidad insuficiente durante el reemplazo. Se distinguen por el **tipo** de error.

🗣️ **2 minutos** — El cuadro:

```text
Hipótesis                Tipo de error         Cómo se confirma          Corrección
───────────────────────  ────────────────────  ────────────────────────  ─────────────────────
1 Sin apagado ordenado   conexión / 502        cesan al terminar el      activar apagado,
                                               reemplazo; coinciden      margen de propagación
                                               con cada instancia        y cierre avisado
2 Incompatibilidad       validación /          afectan a una             hacer el cambio
  entre versiones        deserialización       funcionalidad concreta    compatible;
                                               y no a todas              expand/contract
3 Capacidad              timeout / latencia    proporcionales al         más margen, reemplazo
  insuficiente           alta                  tráfico; sin errores      más lento o más
                                               de conexión               capacidad
```

🔬 **El detalle** — Clasificar por tipo de error resuelve el caso en minutos y casi nadie lo hace: el
reflejo es abrir el log del servicio desplegado. Y conviene atacar la normalización: "ruido de
despliegue" es una expresión que indica que el equipo dejó de investigar una señal real, y eso suele
esconder también incidentes que no son del despliegue.

**04/08 → E4. ¿Mesh o no? 25 servicios, tres plataformas, requisito de mTLS.**

⏱️ **30 segundos** — Con tres plataformas y mTLS obligatorio, el mesh es defendible; pero pediría
números y haría una prueba acotada antes de generalizar.

🗣️ **2 minutos** — La recomendación:

```text
A favor en este caso   · tres plataformas: el argumento fuerte del mesh (una política
                         en vez de tres implementaciones)
                       · mTLS con rotación automática: conseguirlo con librerías
                         significa gestionar certificados en tres ecosistemas
                       · 25 servicios: escala suficiente para amortizar el plano
                         de control
Números que pido       · CPU y memoria actuales → coste de 25 proxies
                       · p99 por servicio → comparar con la prueba
                       · incidentes del último año por certificados o por
                         resiliencia inconsistente → el beneficio esperable
                       · esfuerzo de mantener las tres librerías hoy
Prueba                 3-4 servicios de dos plataformas distintas, un trimestre,
                       midiendo lo anterior
Se queda en el código  idempotencia · degradación · contratos · timeouts de negocio
                       · instrumentación de lo que pasa DENTRO del proceso
Riesgo a vigilar       doble configuración de reintentos: una sola capa,
                       declarada por escrito
```

🔬 **El detalle** — La parte que distingue la respuesta es la penúltima: el mesh no puede saber si una
operación es idempotente, así que sus reintentos deben limitarse a fallos de conexión. Quien responde
"con el mesh ya tenemos resiliencia" acaba duplicando cobros, y ese es el ejemplo concreto que
conviene dar.

**04/08 → E5. Observabilidad desde cero en seis semanas.**

⏱️ **30 segundos** — Aprovecho que ya hay buenos logs: primero identificador de traza en las líneas
existentes, después trazas de una ruta crítica, y el salto asíncrono en la semana cuatro.

🗣️ **2 minutos** — El plan:

```text
Semana 1  Colector desplegado; decisión de destino, muestreo y retención.
Semana 2  Chassis: instrumentación automática + identificador de traza en el log
          estructurado. Beneficio inmediato: saltar del log a la traza.
Semana 3  Una ruta crítica completa, de extremo a extremo, con los dos servicios
          que más incidentes tienen.
Semana 4  El salto asíncrono: inyección y extracción de contexto en el broker.
          Es lo que menos cubre la instrumentación automática y lo que más rinde.
Semana 5  Muestreo por cola con garantía de errores; métricas RED uniformes;
          paneles con enlace log → traza.
Semana 6  Extensión al resto con la lista de comprobación en el chassis.

Cómo sé que funcionó
  · un incidente se diagnostica con la traza ANTES que con los logs
  · el tiempo medio de diagnóstico baja de horas a minutos
  · existe una métrica de extremo a extremo (evento → efecto) en el panel
    que mira producto
```

🔬 **El detalle** — La clave del plan es la semana 2: añadir el identificador de traza a los logs que
ya existen da valor desde el primer momento y hace que el equipo vea el beneficio antes de haber
terminado. Los planes de observabilidad que empiezan por "instrumentemos todo" se abandonan en la
semana tres porque el beneficio llega demasiado tarde.

---

**Anterior:** [`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
