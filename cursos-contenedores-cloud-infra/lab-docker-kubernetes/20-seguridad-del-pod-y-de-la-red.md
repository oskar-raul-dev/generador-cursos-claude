# 🛡️ Fase 20 — Seguridad del pod y de la red: todos hablan con todos, hasta que no

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 20 de 27 · Parte III — Operarlo · **media**
> **Perfil:** el cluster `lab`, con los valores de `minimo`, **las dos cadenas encendidas** · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: las políticas las aplica la red del cluster, que es la misma con los dos motores
> **Servicios que toca:** los cinco y Postgres · **Paso de generación:** ninguno
> **Depende de:** [Fase 19](19-tls-y-certificados.md) · **Habilita:** [Fase 21](21-diagnostico.md)
> **Incidentes que reserva:** 25, 26 · **Medición:** ninguna con identificador; las de esta fase quedan en sus secciones
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** que ningún contenedor corra como root ni pueda escribir donde no debe; que ningún pod le hable a la API sin necesitarlo; y que la red del cluster deje pasar solo lo que el sistema usa, también entre las dos cadenas.

---

## 🧭 1. Dónde estamos

La [Fase 19](19-tls-y-certificados.md) cifró la puerta y puso mTLS entre `inventory` y `pricing`. Pero el 8080 de `pricing` sigue
abierto en HTTP para cualquiera que esté en el cluster, y en el cluster ahora viven **dos cadenas**: La Vecina
y la de Don Rodrigo, la segunda cadena de la [Fase 14](14-helm-en-operacion.md), con su propio namespace y el mismo Postgres.

Luz Marina, de arquitectura, hace la pregunta en los términos de veinte años de WebLogic:

> *"En el dominio de WebLogic, cada aplicación tenía su usuario de sistema operativo, y entre las dos cadenas
> habría un firewall. ¿Aquí qué hay? Porque si el de Don Rodrigo le puede cambiar un precio a La Vecina, el
> producto se acabó antes de venderlo."*

Valentina mide antes de contestar. La respuesta, al principio de esta fase, es: **nada**.

---

## 🎯 2. Objetivos de esta fase

1. Endurecer cada pod: sin root, sin escalar privilegios, sin capacidades del kernel, con la raíz de solo
   lectura, y sin el token de la API.
2. Entender RBAC con un fallo real: por qué un pod no puede leer un `Secret`, y el permiso mínimo para que
   pueda.
3. Demostrar que, por defecto, todos los pods hablan con todos, y cerrarlo con `NetworkPolicy`.
4. Aislar las dos cadenas entre sí y nombrar lo que la red no puede aislar.

---

## 🚫 3. Qué NO entra todavía

- **Pod Security Admission** (la etiqueta del namespace que rechaza pods inseguros al crearlos): se nombra en
  el veredicto; esta fase pone las mismas reglas en el chart, que es donde se ven.
- Políticas de capa 7 (por ruta HTTP o por identidad del servicio): son de un service mesh → [a10](a10-service-mesh.md).
- Los nodos, el runtime y la cadena de suministro de las imágenes (firmas, escaneo): otra conversación.
- Los `Job` de migraciones y el seed siguen sin el endurecimiento de los servicios: es un ejercicio.
- El patrimonio, en `legacy`, sigue abierto: es el estado real de lo que todavía no se migró.

---

## 🧨 4. El problema, en el laboratorio

Con las dos cadenas encendidas y sin ninguna `NetworkPolicy`, desde adentro del `replenish` de la segunda cadena
(`apps-b`), un script de Node prueba cuatro destinos:

```text
# sin NetworkPolicy, desde pod/replenish-85b784d898-49fv2 (la segunda cadena)
pricing de apps (8080)         HTTP 200
inventory de apps (8080)       HTTP 200
pricing de su cadena (8080)    HTTP 200
postgres de data (5432)        conecta
```

**La segunda cadena le habla a La Vecina como si fuera de la casa.** El mismo `GET` que da 200 podría ser un `PUT`
con un precio. Y llega al puerto de Postgres, donde viven las bases de las dos.

Y el pod de adentro no está mejor. Cada servicio corre con el usuario que declara su imagen, pero puede escribir
en su propia raíz, conserva las capacidades del kernel que el runtime da por defecto, y tiene montado el token
de su `ServiceAccount`, con el que le puede hablar a la API del cluster.

> 🩻 **Esto sí funciona igual.** En compose, una red compartida también deja hablar a todos con todos, y
> `read_only: true`, `cap_drop: [ALL]` y `user:` existen en el `compose.yaml`. Lo que cambia es la escala: en
> un cluster, "todos" son los pods de todos los equipos y de todos los clientes.

---

## 🧩 5. Endurecer, y después cerrar

### 5.1 El pod: sin root, de verdad

La [Fase 03](03-el-contenedor-por-dentro.md) sembró la idea: un contenedor que corre como root es root en un proceso de la máquina,
con todo lo que el aislamiento deje pasar. Las imágenes del curso ya declaran un usuario sin privilegios desde
la [Fase 04](04-empaquetar-los-cuatro-runtimes.md). La pregunta es si el cluster lo **exige**. Se le pide con `runAsNonRoot: true`, y la
apuesta de esta fase decía que solo `catalog` iba a fallar:

```text
catalog-86cfbbf9c9-ldgtm     0/2   CreateContainerConfigError
inventory-6cc8895d66-ctxmb   0/1   CreateContainerConfigError
replenish-88f568d55-nzhtz    0/1   CreateContainerConfigError
container has runAsNonRoot and image has non-numeric user (inventory), cannot verify user is non-root
container has runAsNonRoot and image has non-numeric user (www-data), cannot verify user is non-root
container has runAsNonRoot and image has non-numeric user (node), cannot verify user is non-root
```

Fallaron tres. Ninguna corre como root: `inventory` es el usuario 10001, `www-data` es el 82 y `node` es el 1000.
Pero la imagen dice el **nombre**, y el kubelet no abre el `/etc/passwd` de la imagen para traducirlo: sin un
número, no puede demostrar que no es root, y no arranca. `pricing` (65532) y el `storefront` (101) declaran
números y pasaron. Mientras tanto, las réplicas viejas siguieron atendiendo (`maxUnavailable: 0`, [Fase 16](16-escalado-y-rollout.md)).

La corrección es poner el número en el chart, que es lo que `lab-common.podSecurity` hace con cada servicio, más
el resto del endurecimiento:

```yaml
automountServiceAccountToken: false     # ningún servicio del sistema le habla a la API de Kubernetes
securityContext:                        # el del pod
  runAsNonRoot: true
  runAsUser: 10001                      # el número; cada subchart dice el suyo
  runAsGroup: 10001
  seccompProfile: {type: RuntimeDefault}
containers:
  - securityContext:                    # el de cada contenedor
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities: {drop: [ALL]}
```

`seccompProfile: RuntimeDefault` filtra las llamadas al sistema que un servicio no usa; `drop: [ALL]` quita las
catorce capacidades que el runtime da por defecto (cambiar dueños de archivos y abrir puertos bajos, entre ellas);
`allowPrivilegeEscalation: false` impide que un binario con *setuid* gane privilegios. Todo se enciende con
`global.podSecurity.enabled`, que desde esta fase viene en `true`.

### 5.2 La raíz de solo lectura, y lo que escribe cada uno

`readOnlyRootFilesystem` es la regla que más cuesta, porque cada runtime escribe en algún lado sin avisar. Sin
un lugar donde escribir:

```text
inventory:   "Exception encountered during context initialization …: Unable to start web server"
storefront:  /docker-entrypoint.d/20-envsubst-on-templates.sh: line 53: can't create
             /etc/nginx/conf.d/default.conf: Read-only file system
```

Tomcat crea sus carpetas de trabajo en `/tmp` al arrancar. El nginx del `storefront` arma su `default.conf` (y con
él el `/config.json` de la [Fase 11](11-configuracion-y-secretos.md)) desde una plantilla, también al arrancar. La respuesta es un `emptyDir`
montado justo donde hace falta, y nada más: `/tmp` en los cinco, y `/etc/nginx/conf.d` en el `storefront`. `catalog`
también necesita `/tmp` para el pid y las carpetas temporales que fijó su `nginx-main.conf` en la [Fase 18](18-logs.md), y su
contenedor de nginx corre con su propio usuario (101), distinto del de PHP-FPM (82).

Con todo eso, las suites de G5, G7 y G8 pasaron igual que antes. El endurecimiento no cambió ningún
comportamiento: cambió lo que un atacante podría hacer con un contenedor tomado.

### 5.3 RBAC: por qué tu pod no puede leer un `Secret`

El token que se monta en cada pod identifica a su `ServiceAccount` ante la API. Por defecto, esa identidad no
puede casi nada. Un pod de diagnóstico, en un namespace de prueba, que intenta leer un `Secret` con su token:

```text
403 secrets "db-prueba" is forbidden: User "system:serviceaccount:diagnostico:default" cannot get resource
"secrets" in API group "" in the namespace "diagnostico"
```

Es el fallo que la ficha prometió, y es correcto. El permiso mínimo es un `Role` que deje **leer ese `Secret`**,
no todos, y un `RoleBinding` que se lo dé a esa `ServiceAccount`:

```bash
kubectl -n diagnostico create role leer-db --verb=get --resource=secrets --resource-name=db-prueba
kubectl -n diagnostico create rolebinding leer-db --role=leer-db --serviceaccount=diagnostico:default
```

```text
200 ok: DATABASE_URL
$ kubectl auth can-i get secret/db-prueba -n diagnostico --as=system:serviceaccount:diagnostico:default
yes
$ kubectl auth can-i list secrets -n diagnostico --as=system:serviceaccount:diagnostico:default
no
$ kubectl auth can-i get secret/pricing-db -n apps --as=system:serviceaccount:diagnostico:default
no
```

`kubectl auth can-i --as` es la herramienta para preguntarle al cluster por un permiso sin probarlo con un pod.
En el sistema, los dos que de verdad le hablan a la API ya tienen el mínimo desde las fases 17 y 18: Prometheus
puede mirar pods y nodos, y Fluent Bit pods y namespaces, cada uno con su `ClusterRole` de solo lectura. Los
servicios no le hablan a la API, y por eso ya no tienen el token montado:

```text
$ kubectl -n apps exec deploy/replenish -- ls /var/run/secrets/kubernetes.io/serviceaccount
ls: /var/run/secrets/kubernetes.io/serviceaccount: No such file or directory
```

¿Por qué quitarlo, si la `ServiceAccount` `default` no puede casi nada? Porque "casi nada" depende de lo que alguien
le dé mañana, en otro chart, con un `RoleBinding` a `default` que parecía inofensivo; y porque el token es lo
primero que busca quien toma un contenedor: con él le habla a la API desde adentro, sin pasar por la puerta. Un
servicio que no lo necesita no debería tenerlo montado, y en un cluster compartido conviene que cada servicio
tenga su propia `ServiceAccount`, aunque esté vacía, para que un permiso que se le dé a uno no se lo lleven todos.

### 5.4 La red: cerrar todo y abrir lo que se usa

Una `NetworkPolicy` elige pods y dice qué tráfico pueden recibir (*ingress*) o mandar (*egress*). Tienen una
regla que hay que entender antes de escribir una: **en cuanto una política elige un pod para una dirección, todo
lo que ninguna política permite en esa dirección queda prohibido**, y las políticas se suman. El patrón es el de
cualquier firewall: cerrar todo y abrir lo que se usa.

El chart trae cuatro, en el namespace de cada cadena (`templates/networkpolicies.yaml`, encendidas con
`global.networkPolicy.enabled`):

```yaml
# 1. default-deny: podSelector {} y las dos direcciones. Nada entra ni sale.
# 2. allow-dns: salida a CoreDNS (kube-system, k8s-app: kube-dns), puerto 53 UDP y TCP.
# 3. allow-ingress: entra lo de la misma cadena; desde gateway y observability, solo al 8080.
# 4. allow-egress: sale hacia la misma cadena, y a Postgres en data, al 5432.
```

Y en `data`, una política para Postgres que deja entrar al 5432 desde `apps`, `apps-b` y `data`, y desde ningún
otro lado (`platform/data/postgres/networkpolicy.yaml`). La misma prueba de la sección 4, después:

```text
# con NetworkPolicy, desde pod/replenish-85b784d898-49fv2 (la segunda cadena)
pricing de apps (8080)         TimeoutError
inventory de apps (8080)       TimeoutError
pricing de su cadena (8080)    HTTP 200
postgres de data (5432)        conecta
# desde un pod de default (una prueba que alguien dejó)
pricing de apps (8080)         TimeoutError
postgres de data (5432)        timeout (3 s)
```

La segunda cadena ya no llega a La Vecina, y un pod cualquiera ya no llega a la base. La puerta (por HTTP y por
HTTPS), las suites de G5 y G8, y las sondas siguieron funcionando. Una política que rechaza no contesta "no": la
conexión se queda sin respuesta, y el cliente espera su timeout. Ese silencio es el síntoma, y la [Fase 21](21-diagnostico.md) lo
diagnostica.

> ⚠️ **Una `NetworkPolicy` no hace nada si la red del cluster no la aplica.** El objeto se crea igual, sin error
> ni advertencia, en cualquier cluster. kindnet, la red de kind en la versión del curso, sí las aplica (la
> preparación del curso lo verificó, y esta fase lo volvió a ver). Muchas redes sí, algunas no, y la única forma
> de saberlo es probar como la sección 4.

### 5.5 Cómo se prueba una política

Una `NetworkPolicy` se escribe en YAML y se lee en YAML, y las dos lecturas engañan: el YAML no dice qué pods
elige (eso depende de las labels que tengan hoy), ni si la red del cluster la aplica, ni qué otra política suma
permisos que no esperabas. El método que usó esta fase, y que conviene repetir con cada cambio:

1. **Una prueba de alcance, desde tres lugares**: un pod de la misma cadena, uno de la otra, y uno de un namespace
   cualquiera. Cada uno contra los mismos destinos, con un timeout corto (tres segundos), y la tabla antes y
   después. Es la sección 4, y la sección 8 la deja escrita.
2. **Lo que elige cada política**: `kubectl describe networkpolicy` muestra el `podSelector` y las reglas;
   `kubectl get pods --show-labels` muestra si algún pod las cumple. Un selector que no elige a nadie no da error.
3. **El sistema por dentro**: las suites del paso actual (aquí, G5 y G8, que cruzan `inventory`, `catalog`,
   `pricing` y `replenish`), la puerta por HTTP y por HTTPS, y que todos los pods sigan listos.
4. **Lo que corre antes**: los hooks del chart (las migraciones) corren con las políticas del release anterior. Un
   upgrade que agrega una dependencia nueva necesita su política **antes** de que el hook la use.

El cuarto punto apareció solo: con las políticas recién aplicadas, uno de los pods del `Job` de migraciones de
`inventory` terminó en `Error` y el `Job` completó en el reintento. No separé la causa, y por eso está en la lista
y no en la conclusión.

### 5.6 Lo que la red no separa

La segunda cadena **todavía llega a Postgres**, y tiene que llegar: sus bases están ahí. La red no puede
distinguir si `apps-b` se conecta a `inventory_tenant_b` o a `inventory`; eso lo decide Postgres con usuarios y
contraseñas, que es **identidad**, no red. Y los datos de las dos cadenas siguen en el mismo proceso de Postgres,
con el mismo disco y el mismo administrador.

Para el producto de Don Aurelio esa es la frontera: un SaaS de verdad separa los datos de cada cliente con bases,
claves y respaldos propios, y separa la identidad de los servicios con algo más que una IP. El laboratorio la
nombra y no la cruza.

---

## 🔁 6. Los otros cuatro, y Postgres

**`pricing` y el `storefront`** no pidieron nada más que el número de usuario que ya tenían. **`inventory`** pidió
`/tmp` (Tomcat). **`catalog`** pidió dos usuarios en el mismo pod y `/tmp` en los dos contenedores. **`replenish`**
corrió con la raíz de solo lectura sin escribir nada.

**Postgres** es el caso distinto, y es el incidente 25. La imagen oficial **arranca como root** y baja a su usuario
(`postgres`, 999) después de preparar la carpeta de datos; con `runAsNonRoot: true` y sin decir el usuario, el
kubelet no la deja empezar:

```text
container has runAsNonRoot and image will run as root (pod: "postgres-0_data(…)", container: postgres)
```

Con `runAsUser: 999` y `fsGroup: 999`, la imagen sabe arrancar directamente como ese usuario, y el volumen queda a
su nombre. El manifiesto de Postgres lo trae desde esta fase.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"la red del cluster es interna; lo que importa es la puerta"*. Las apuestas,
escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** Sin `NetworkPolicy`, un pod de `apps-b` llega al Postgres de `data` y a
> `pricing` de `apps` sin que nada lo impida; con una política de *default deny* por namespace y sus excepciones,
> no.
>
> **Resultado: ganada**, con la mitad que la red no puede ganar: a Postgres sigue llegando, porque tiene que
> (sección 5.5).

> 🪞 **Apuesta antes de ejecutar.** Un *default deny* de egreso sin excepción para el DNS rompe la resolución de
> nombres de todos los pods del namespace, también de los que tienen permitido hablar entre sí.
>
> **Resultado: ganada.** `EAI_AGAIN` al resolver `pricing`, desde `replenish`, que tiene permiso de hablarle; por
> IP, la misma conexión pasa (incidente 26).

> 🪞 **Apuesta antes de ejecutar.** De las imágenes del sistema, solo la de `catalog` falla con `runAsNonRoot: true`,
> porque es la única cuyo usuario no está declarado como número.
>
> **Resultado: perdida.** Fallaron tres: `inventory`, `catalog` y `replenish` (sección 5.1).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#la-red-del-cluster-es-interna).

---

## 📏 8. Lo que cerró

No hay medición de rendimiento en esta fase: las políticas las aplica la red del nodo, y en un laboratorio no se
separa su costo del ruido. Lo que sí se midió es **el alcance**, desde tres lugares distintos:

| Desde → hacia | `pricing` de `apps` | `inventory` de `apps` | `pricing` de su cadena | Postgres de `data` |
|---|---|---|---|---|
| `apps-b`, sin políticas | 200 | 200 | 200 | conecta |
| `apps-b`, con políticas | timeout | timeout | 200 | conecta |
| `default`, con políticas | timeout | timeout | timeout | timeout |
| `apps`, con políticas (`replenish`) | 200 | 200 | 200 | conecta |

Cuatro de cuatro destinos alcanzables desde la otra cadena, antes; los de su propia cadena y su base, después. Y
lo que pagó el sistema: ningún cambio en las suites, pero sí en **cómo falla**. Una conexión rechazada por la red no
da error: espera. La [Fase 21](21-diagnostico.md) lo encontró con un vecino caído: lo que en la [Fase 16](16-escalado-y-rollout.md) era un 503 al instante, con las
políticas es una espera de quince segundos en la puerta.

---

## ⚰️ 9. Autopsia: cerrar la red sin abrir el DNS

**La decisión, con su mejor argumento.** Un `default-deny` en `apps`, en las dos direcciones, y las excepciones
para lo que el sistema usa: entre la cadena, y a Postgres. *"Si lo cierro todo y abro lo que conozco, no se me
escapa nada."*

**Por qué era razonable.** Es exactamente el patrón correcto, y es lo que esta fase recomienda. Le falta una línea.

**Qué pasó después, con número.** Sin la política del DNS, una venta por la puerta:

```text
upstream request timeout
504 en 16.242148s
```

Y desde adentro de `replenish`, que tiene permitido hablarle a `pricing`:

```text
pricing de apps (8080)         TimeoutError
lookup pricing: EAI_AGAIN
por IP: conecta
```

**Todo el namespace sin poder resolver un solo nombre**, incluso hacia los destinos permitidos: el DNS es un
servicio de `kube-system`, en otro namespace, y la salida hacia él también quedó cerrada. La puerta esperó 16
segundos antes de rendirse. Y la reparación obvia, `task deploy`, **falló**: el hook de migraciones corre antes que
el resto del release, tampoco resolvía el nombre de Postgres, y Helm hizo rollback.

**Cuánto cuesta salir, con número.** Una política de doce líneas (`allow-dns`); y para volver, aplicar el manifiesto
del release tal como está (`helm get manifest`, con su namespace, porque el manifiesto no lo trae y sin `-n` todo
cae en `default`: pasó al escribir la tarea del incidente).

**Qué lo habría cambiado.** Escribir la excepción del DNS **antes** que el *default deny*, en el mismo archivo, y
probar el resultado desde un pod, no desde la puerta.

**Antes y después, con números:** sin `allow-dns`, 504 a los 16 s y ningún nombre resuelto en el namespace; con ella,
200 por la puerta y solo lo permitido alcanzable.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes | Lo que cambia |
|---|---|---|
| `user: "10001"` | `securityContext.runAsUser` y `runAsNonRoot` | el cluster lo exige, y necesita el número |
| `read_only: true` y `tmpfs:` | `readOnlyRootFilesystem` y un `emptyDir` donde haga falta | lo mismo, por contenedor |
| `cap_drop: [ALL]` | `capabilities.drop: [ALL]` | lo mismo |
| redes separadas en el `compose.yaml` | `NetworkPolicy` | se elige por labels, no por red; y depende de que la red del cluster la aplique |
| el usuario del sistema operativo de cada aplicación en WebLogic | la `ServiceAccount` del pod, y RBAC | identidad ante la API, no ante el sistema operativo |
| el firewall entre dos clientes | `NetworkPolicy` entre namespaces | separa la red, no los datos ni la identidad |

Y al revés: una `NetworkPolicy` de *default deny* en un cluster ajeno es, en compose, una red por servicio y cada
conexión declarada a mano; un `Role` es el permiso que en compose nadie tiene que dar, porque quien tiene el
socket del motor tiene todo. Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, la red del cluster gestionado suele aplicar `NetworkPolicy` (a veces hay que encenderlo al crear el
cluster), y además hay grupos de seguridad del proveedor alrededor de los nodos. Y Pod Security Admission viene
de serie: un namespace con la etiqueta `restricted` rechaza al crear lo que esta fase puso en el chart.

---

## 🩺 11. Incidentes de esta fase

- **[25 — Endurecí el pod y dejó de arrancar](cuaderno-incidentes.md#-incidente-25--endurecí-el-pod-y-dejó-de-arrancar).** `CreateContainerConfigError`:
  `container has runAsNonRoot and image will run as root`.
- **[26 — Cerré la red y se rompió todo, hasta lo permitido](cuaderno-incidentes.md#-incidente-26--cerré-la-red-y-se-rompió-todo-hasta-lo-permitido).** 504 en la puerta y
  `EAI_AGAIN` adentro, después de un *default deny*.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Una `NetworkPolicy` que la red no aplica es peor que ninguna**: se ve en el repositorio y no protege nada. Antes de
confiar en ellas en un cluster, la prueba de la sección 4.

**Cerrar la red tiene un costo de diagnóstico.** Una conexión rechazada no da error: espera. Cada servicio nuevo,
cada dependencia nueva, es una política que alguien tiene que escribir, y el primer síntoma de una que falta es un
timeout que parece un servicio caído.

**El chart no reemplaza la admisión.** Esta fase puso el endurecimiento donde se ve, pero cualquiera puede aplicar
un pod sin él. En un cluster compartido, Pod Security Admission en modo `restricted` lo exige para todos, namespace
por namespace; aquí no se encendió, y es un ejercicio: los servicios ya lo cumplen, y los `Job` del chart todavía
no.

**Cuándo NO un *default deny*:** un cluster de un solo equipo y un solo sistema, sin datos sensibles, donde cada
timeout cuesta más que lo que protege. **Cuándo sí:** siempre que en el mismo cluster haya dos equipos, dos
clientes o una base de datos.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso aislado y un usuario. El orquestador te
dio `securityContext`, RBAC y `NetworkPolicy`. **Te tocó a ti** el número de usuario que la imagen no dio, saber
dónde escribe cada runtime, el permiso mínimo, la excepción del DNS, y decir en voz alta que la red no separa los
datos de dos clientes.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`container has runAsNonRoot and image has non-numeric user`.** La imagen dice el usuario por nombre: el número va en
`runAsUser`.

**`CrashLoopBackOff` con `Read-only file system` en el log.** Un proceso escribe donde no puede: un `emptyDir` en esa
carpeta, no apagar `readOnlyRootFilesystem`.

**`403 … is forbidden: User "system:serviceaccount:…"`.** La identidad del pod no tiene el permiso. `kubectl auth can-i
--as=system:serviceaccount:<ns>:<sa>` antes de tocar nada.

**Todo da timeout después de aplicar una política, incluso lo permitido.** El DNS (incidente 26).

**Una política nueva no hace nada.** La red del cluster no las aplica, o el `podSelector` no elige los pods que
crees (`kubectl describe networkpolicy`).

**Un `Job` del chart falla después de cerrar la red.** Los hooks corren antes que las políticas nuevas de un upgrade, y
con las del upgrade anterior.

---

## 📋 14. Checklist de validación

```text
[ ] runAsNonRoot sin números: los tres en CreateContainerConfigError; con el chart, los cinco listos
[ ] la raíz de solo lectura: sin /tmp, inventory y storefront no arrancan; con los emptyDir, G5, G7 y G8 en verde
[ ] el 403 de RBAC, el Role mínimo, y kubectl auth can-i
[ ] las dos cadenas encendidas: la prueba de alcance sin políticas y con políticas
[ ] los incidentes 25 y 26 provocados y reparados
```

---

## 🧪 15. Ejercicios (20)

La mitad de diagnóstico. El script de alcance de la sección 4 es `reach.js` en la verificación del curso; cualquier
`fetch` desde un pod de Node hace lo mismo.

## 🟢 Fácil — leer el endurecimiento (1–6)

### 🟢 Ejercicio 1 — Con qué usuario corre
Lista el usuario de cada contenedor de `apps`, desde la especificación y desde adentro.

**Criterio:** los seis números (dos en `catalog`), iguales en los dos lados.

<details><summary>Solución</summary>

`kubectl -n apps get pods -o jsonpath` sobre `securityContext.runAsUser` del pod y del contenedor; adentro, `id` donde
haya shell (`pricing` no tiene: es distroless).
</details>

### 🟢 Ejercicio 2 — Escribir en la raíz
Intenta crear un archivo en `/` y en `/tmp` dentro de `replenish`.

**Criterio:** `Read-only file system` en el primero, el archivo creado en el segundo.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/replenish -- touch /x` y `… touch /tmp/x`.
</details>

### 🟢 Ejercicio 3 — `can-i`
Pregunta si la `ServiceAccount` de Prometheus puede listar pods, y si puede leer `Secret`.

**Criterio:** `yes` y `no`, y de dónde sale cada uno.

<details><summary>Solución</summary>

`kubectl auth can-i list pods --as=system:serviceaccount:observability:prometheus` (el `ClusterRole` `lab-prometheus`
de la [Fase 17](17-metricas-y-dashboards.md)) y lo mismo con `get secrets`.
</details>

### 🟢 Ejercicio 4 — Las políticas
Lista las `NetworkPolicy` de `apps` y explica en una frase cada una.

**Criterio:** las cuatro, con qué eligen y qué permiten.

<details><summary>Solución</summary>

`kubectl -n apps describe networkpolicy`. `default-deny` no permite nada; las otras tres suman permisos.
</details>

### 🟢 Ejercicio 5 — La prueba de alcance
Repite la prueba de la sección 4 desde un pod de `observability`.

**Criterio:** la tabla, explicada con las políticas.

<details><summary>Solución</summary>

Al 8080 de `apps` llega (Prometheus lo necesita); a Postgres no.
</details>

### 🟢 Ejercicio 6 — Sin el token
Comprueba que ningún pod de `apps` tiene el token de su `ServiceAccount`, y uno de `observability` sí.

**Criterio:** la carpeta del token, ausente en uno y presente en el otro.

<details><summary>Solución</summary>

`ls /var/run/secrets/kubernetes.io/serviceaccount`. Prometheus lo necesita para preguntarle a la API qué pods hay.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (7–12)

### 🟡 Ejercicio 7 — Endurecer los `Job`
Aplica el mismo endurecimiento a los `Job` de migraciones y al seed.

**Criterio:** los `Job` completan con `runAsNonRoot`, sin capacidades y con la raíz de solo lectura.

<details><summary>Solución</summary>

`lab-common.podSecurity` y `lab-common.containerSecurity` en `lab-common.migrateJob`, y el usuario del seed (65534).
Mira qué escribe cada migración: Laravel quiere `storage/`.
</details>

### 🟡 Ejercicio 8 — Pod Security Admission
Etiqueta `apps-b` con `pod-security.kubernetes.io/enforce=restricted` y reinstala la segunda cadena.

**Criterio:** qué rechaza la admisión, con el mensaje, y qué hace falta para que pase.

<details><summary>Solución</summary>

Los servicios pasan; los `Job` sin endurecer, no (`violates PodSecurity "restricted:latest"`). El ejercicio 7 lo arregla.
</details>

### 🟡 Ejercicio 9 — Grafana y Prometheus, con políticas
Enciende las métricas y los tableros, y escribe las `NetworkPolicy` de `observability`.

**Criterio:** los blancos de Prometheus en `up`, Grafana accesible por la puerta, y nada más abierto.

<details><summary>Solución</summary>

Entrada desde `gateway` a Grafana y Prometheus; salida de Prometheus a `apps`, `apps-b` y a la API (por cAdvisor y por
el descubrimiento de pods); salida de Grafana a Prometheus y Loki; y el DNS.
</details>

### 🟡 Ejercicio 10 — El patrimonio
Prueba qué alcanza un pod de `legacy` y escribe la política mínima para Contingencia.

**Criterio:** antes y después, con la prueba de alcance.

<details><summary>Solución</summary>

Contingencia recibe del portal y de la fachada, y habla con su base. La misma receta de la sección 5.4.
</details>

### 🟡 Ejercicio 11 — Un `Role` para el soporte
Crea una `ServiceAccount` para el equipo de soporte que pueda ver pods y logs en `apps`, y nada más.

**Criterio:** `can-i` en `yes` para eso y en `no` para `secrets`, `exec` y cualquier verbo de escritura.

<details><summary>Solución</summary>

Un `Role` con `get`, `list`, `watch` sobre `pods` y `get` sobre `pods/log`. `exec` es `create` sobre `pods/exec`.
</details>

### 🟡 Ejercicio 12 — `allowPrivilegeEscalation`
Explica qué impide `allowPrivilegeEscalation: false` con un binario concreto de una imagen del sistema.

**Criterio:** el binario, el bit que tiene, y qué pasaría sin la regla.

<details><summary>Solución</summary>

Busca binarios con *setuid* (`find / -perm -4000`) en la imagen de `inventory` (Ubuntu, con shell): `su`, `passwd`. Con
la regla, el kernel no les da el usuario del dueño.
</details>

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — El incidente 25
Provócalo y resuélvelo sin mirar la entrada del cuaderno.

**Criterio:** el `describe` que lo explica y el arreglo mínimo.

<details><summary>Solución</summary>

`task inc:break -- 25`. El mensaje dice `image will run as root`: el usuario numérico de la imagen (999) en `runAsUser`.
</details>

### 🟠 Ejercicio 14 — El incidente 26
Provócalo y resuélvelo, y explica por qué `task deploy` no alcanza.

**Criterio:** la evidencia desde adentro de un pod, y la secuencia que repara.

<details><summary>Solución</summary>

El hook de migraciones corre antes que las políticas y no resuelve el nombre de Postgres. La sección 9.
</details>

### 🟠 Ejercicio 15 — La política que no elige a nadie
Escribe una política para dejar entrar a Prometheus solo a `pricing`, con un `podSelector` que tenga un error de label.
**Predice** qué pasa con los blancos.

**Criterio:** el síntoma y cómo lo encontraste.

<details><summary>Solución</summary>

La política no elige ningún pod y no cambia nada, o deja a `pricing` sin la regla general si la quitaste. `kubectl
describe networkpolicy` muestra el selector; compáralo con las labels del pod.
</details>

### 🟠 Ejercicio 16 — La sonda que pasa
Con todas las políticas, las sondas del kubelet siguen funcionando. Explica por qué, si ninguna política deja entrar
desde los nodos.

**Criterio:** la explicación, con la evidencia de dónde viene la sonda.

<details><summary>Solución</summary>

El tráfico del propio nodo hacia sus pods no pasa por las reglas de entrada en kindnet (como en la mayoría de las
redes). No es universal: algunas redes lo filtran, y hay que permitir el rango de los nodos.
</details>

### 🟠 Ejercicio 17 — Leer el `Secret` de otra cadena
Desde la segunda cadena, intenta conectarte a la base `inventory` de La Vecina con la contraseña que **sí** tiene,
la de `inventory_tenant_b`.

**Criterio:** el error de Postgres, y por qué la red no lo detuvo.

<details><summary>Solución</summary>

La red deja pasar al 5432; Postgres rechaza el usuario en esa base. Es la frontera de la sección 5.5: identidad, no red.
</details>

## 🔴 Muy difícil — medir y diseñar (18–20)

### 🔴 Ejercicio 18 — La red que no aplica
Crea un cluster de kind con una red que no aplique `NetworkPolicy` (o desactiva el componente de kindnet que las
aplica) y repite la sección 4.

**Criterio:** la tabla de alcance con las políticas creadas y sin efecto.

**Rúbrica:** las políticas aparecen en `kubectl get`, sin advertencia; la prueba lo desmiente; la conclusión es la
sección 12.

### 🔴 Ejercicio 19 — Postgres por cadena
Diseña la separación de las dos cadenas a nivel de base de datos: qué cambia en el chart, en `platform/data` y en la
memoria del laboratorio.

**Criterio:** el diseño y la cuenta de memoria medida.

**Rúbrica:** un Postgres por cadena (o un clúster por cliente en la nube), su `NetworkPolicy`, sus respaldos; y el costo:
otro Postgres en 4 GiB.

### 🔴 Ejercicio 20 — El costo de cerrar
Mide si las políticas cambian la latencia de la venta: 10 ventas por segundo, tres corridas con y sin políticas.

**Criterio:** la tabla, y una conclusión que no pase de la dispersión.

**Rúbrica:** las mismas condiciones; la diferencia, si es menor que la dispersión, se dice así; y lo que sí cuesta,
que es tiempo de diagnóstico.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Configure a Security Context for a Pod or Container*: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- Kubernetes, *Pod Security Standards*: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Kubernetes, *Using RBAC Authorization*: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Kubernetes, *Network Policies*: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Kubernetes, *Configure Service Accounts for Pods* (`automountServiceAccountToken`): https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

**Libros y ensayos**

- Liz Rice, *Container Security* (2020): los capítulos de usuarios, capacidades y seccomp.
- Andrew Martin y Michael Hausenblas, *Hacking Kubernetes* (2021): el modelo de amenazas de un pod y de la red.

**Orden de lectura sugerido:** antes, *Pod Security Standards* (qué es "restringido"); durante, *Network Policies* con
la sección 5.4 delante; después, el capítulo de red de *Hacking Kubernetes*.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 20 (cluster lab, valores de minimo, las dos cadenas)

  apps, apps-b   los cinco con runAsNonRoot y el número de usuario, seccomp RuntimeDefault, sin capacidades,
                 raíz de solo lectura (emptyDir en /tmp; conf.d en storefront), sin token de la API
                 NetworkPolicy: default-deny, allow-dns, allow-ingress, allow-egress (global.networkPolicy.enabled)
  data           Postgres como 999, con fsGroup; NetworkPolicy postgres: solo apps, apps-b y data al 5432
```

> **La señal de que quedó bien:** *"Le muestro a Luz Marina que la otra cadena ya no llega a La Vecina, le digo qué no
> separa la red, y cuando todo da timeout después de cerrar algo, lo primero que miro es el DNS."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-20-seguridad-del-pod-y-de-la-red -m "F20 cerrada: securityContext completo en los cinco y en Postgres; RBAC mínimo con el 403 provocado; NetworkPolicy por cadena y para Postgres, con la prueba de alcance; incidentes 25 y 26"
> ```
>
> Y los pares: `inc/25/runasnonroot-root-image-*` e `inc/26/default-deny-dns-*`. Commits con prefijo `f20:`.

---

## 📌 Pendientes sugeridos

- **F21:** el timeout de una política que falta, diagnosticado con el método.
- **F22:** el timeout que `inventory` todavía no tiene: con la red cerrada, una dependencia sin política espera 16 s.
- **Los `Job` del chart** (migraciones y seed), sin el endurecimiento de los servicios.
