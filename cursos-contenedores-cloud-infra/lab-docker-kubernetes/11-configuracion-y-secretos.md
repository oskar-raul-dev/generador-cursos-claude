# ⚙️ Fase 11 — Configuración y secretos: la misma imagen en dos sitios, la circular que no llega, y la contraseña de 2019

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 11 de 27 · Parte II — El despliegue · **media** ⭐
> **Perfil:** `minimo` · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase
> **Servicios que toca:** `storefront` y `pricing`; el portal y Contingencia en `legacy` · **Paso de generación:** G2 · Configuración en arranque
> **Depende de:** [Fase 10](10-la-entrada-al-sistema.md) · **Habilita:** [Fase 12](12-estado-y-almacenamiento.md)
> **Incidentes que reserva:** 09 y 10 · **Medición:** ninguna
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** que la misma imagen del `storefront` sirva a dos ambientes sin reconstruirse, que un cambio del tope regulado llegue de verdad a `pricing`, y que las credenciales del portal salgan de la imagen sin creer que con eso quedaron seguras.

---

## 🧭 1. Dónde estamos

Desde la [Fase 10](10-la-entrada-al-sistema.md), el sistema tiene puerta. La página del `storefront` lista el catálogo en el
navegador, `pricing` contesta precios por `api.localhost`, y el patrimonio vive en `legacy`, con el
portal sincronizando el catálogo de Contingencia por SOAP. Todo funciona, y casi todo lo que
funciona tiene su configuración en el lugar equivocado.

Fabio Arenas, el vicepresidente de operaciones, lo trajo al comité con la única métrica que le
importa, la de las 263 regentes:

> *"Salió la circular el martes. Yolanda me dice que en Girón la caja sigue cobrando el salbutamol
> con el tope viejo. Ustedes me dijeron que con `pricing` la circular ya no esperaba al domingo."*

Y es cierto: ya no espera al domingo. La tabla de topes regulados de `pricing` vive en un `ConfigMap`,
se cambia con un comando, y el archivo dentro del pod cambia solo. **Lo que nadie le dijo a Fabio es
que el archivo cambia y el servicio no se entera.** Esta fase empieza por otra versión del mismo
problema, la más cara de todas: una página que lleva su configuración horneada.

---

## 🎯 2. Objetivos de esta fase

1. Desplegar la misma imagen del `storefront` dos veces, con dos configuraciones, y ver cómo falla
   una de las dos con la configuración horneada al compilar.
2. Generar el paso G2: la configuración se lee al arrancar, y la imagen sirve para cualquier ambiente.
3. Poner la tabla de topes regulados de `pricing` en un `ConfigMap`, cambiarla, y medir cuánto tarda
   en llegar al archivo y al servicio.
4. Sacar las credenciales SOAP del portal a un `Secret`, con sus dos puntas, y ver qué **no** arregla
   eso.

---

## 🚫 3. Qué NO entra todavía

- El reinicio automático cuando cambia la configuración (el *hash* en la plantilla) → [Fase 13](13-helm-el-paquete.md).
- Cifrar los `Secret` en reposo, o guardarlos cifrados en git → fuera del curso, en el veredicto.
- Los gestores de secretos externos (bóvedas, servicios de secretos del proveedor): **exclusión
  declarada**. Exigen infraestructura que el laboratorio no tiene, y no cambian ninguna decisión
  que se tome aquí.
- Credenciales para los servicios nuevos: no tienen ninguna hasta que la [Fase 12](12-estado-y-almacenamiento.md) les da una base.

---

## 🧨 4. El problema, en el laboratorio

QA quiere su propio ambiente: la misma página, contra un `catalog` de pruebas con sus productos de
pruebas, en `storefront-qa.localhost`. El manifiesto de QA (`deploy/qa/qa.yaml`) despliega **la misma
imagen** del `storefront`, con su `ConfigMap`:

```yaml
data:
  API_BASE_URL: http://api-qa.localhost:8080
  BRAND_NAME: Droguerías La Vecina · QA
```

Las dos páginas, con la imagen de G1, en Chrome sin interfaz:

```text
$ kubectl -n apps get deploy storefront storefront-qa -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
NAME            IMAGE
storefront      lab/storefront:g1
storefront-qa   lab/storefront:g1
$ kubectl -n apps exec deploy/storefront-qa -- printenv API_BASE_URL BRAND_NAME
http://api-qa.localhost:8080
Droguerías La Vecina · QA
=== G1 · storefront.localhost
<main><h1>Droguerías La Vecina</h1>…<ul><li><strong>Acetaminofén 500 mg x 10 tabletas</strong> · venta libre · <code>SKU-0001</code></li><li><strong>Salbutamol inhalador 100 mcg</strong> · venta libre · <code>SKU-0003</code></li></ul></main>
=== G1 · storefront-qa.localhost
<main><h1>Droguerías La Vecina</h1>…<p class="aviso">No se pudo cargar el catálogo desde http://api.localhost:8080 (Failed to fetch).</p></main>
```

El contenedor de QA **tiene** la variable correcta, y la página la ignora: le pide el catálogo a
producción, `api.localhost`, porque esa dirección quedó escrita en el JavaScript cuando se compiló.
Falla por CORS, que la puerta solo le abre a `storefront.localhost` ([Fase 10](10-la-entrada-al-sistema.md)). **Y esa es la versión
buena del fallo.** Abrí el CORS de producción también al origen de QA, como haría cualquiera para
"destrabar a QA", y volví a abrir la página de QA:

```text
=== G1 · la variante silenciosa: el API de producción también acepta el origen de QA
<main><h1>Droguerías La Vecina</h1>…<ul><li><strong>Acetaminofén 500 mg x 10 tabletas</strong> · venta libre · <code>SKU-0001</code></li><li><strong>Salbutamol inhalador 100 mcg</strong> · venta libre · <code>SKU-0003</code></li></ul></main>
```

Sin un error, la página de QA muestra los productos de producción. QA prueba contra producción, y
nadie lo nota hasta el día en que una prueba de QA escribe algo. **Ese desajuste —la configuración
fijada al compilar, y un contenedor que espera recibirla al arrancar— es la causa raíz de la mitad de
los "funciona en QA y no en producción" de cualquier aplicación de página única.**

---

## ⚙️ 5. La configuración en arranque, con el `storefront`

### 5.1 Dónde vive cada cosa

Una aplicación de página única no tiene proceso en el servidor: es una carpeta de archivos que corre
en el navegador. No puede leer variables de entorno, porque el entorno es el del navegador del
cliente. Lo único que sí corre en el contenedor es el nginx que sirve los archivos. **G2 le pone a él
la tarea**: al arrancar, arma un `/config.json` con las variables del contenedor, y la página lo pide
antes de hacer cualquier otra cosa.

La imagen oficial de nginx ya trae el mecanismo: lo que esté en `/etc/nginx/templates/*.template` lo
convierte en configuración al arrancar, reemplazando las variables definidas. La plantilla del
`storefront` (`services/storefront/nginx/default.conf.template`):

```nginx
    # La configuración de la página, leída en el navegador antes de pedir nada al API.
    location = /config.json {
        default_type application/json;
        # Sin caché: un cambio de configuración tiene que verse en la siguiente carga, no mañana.
        add_header Cache-Control "no-store" always;
        return 200 '{"apiBaseUrl":"${API_BASE_URL}","brandName":"${BRAND_NAME}"}';
    }
```

El Dockerfile pierde su `ARG VITE_API_BASE_URL` y gana dos `ENV` con los valores por defecto, y la
página lee `/config.json` antes de pedir el catálogo. `BRAND_NAME` viaja también, porque el contrato
dice que el nombre visible de la empresa es configuración y nunca un identificador. El prompt
completo de G2 está en [a03](a03-contratos-y-prompts-de-generacion.md#-el-prompt-de-g2). La
configuración sale de un `ConfigMap`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: storefront-config
  namespace: apps
data:
  API_BASE_URL: http://api.localhost:8080
  BRAND_NAME: Droguerías La Vecina
```

y el `Deployment` lo entrega como variables con `envFrom`, como el `ConfigMap` `neighbors` de la [Fase 09](09-los-cuatro-servicios-dentro.md).

### 5.2 La misma imagen, dos sitios

```text
$ kubectl -n apps get deploy storefront storefront-qa -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
NAME            IMAGE
storefront      lab/storefront:g2
storefront-qa   lab/storefront:g2
$ curl -sS http://storefront.localhost:8080/config.json
{"apiBaseUrl":"http://api.localhost:8080","brandName":"Droguerías La Vecina"}
$ curl -sS http://storefront-qa.localhost:8080/config.json
{"apiBaseUrl":"http://api-qa.localhost:8080","brandName":"Droguerías La Vecina · QA"}
=== G2 · storefront-qa.localhost (perfil nuevo)
<title>Droguerías La Vecina · QA</title>
<main><h1>Droguerías La Vecina · QA</h1>…<ul><li><strong>PRODUCTO DE PRUEBA QA</strong> · venta libre · <code>SKU-9001</code></li></ul></main>
```

Una imagen, dos nombres, dos catálogos. La suite de G2 (`storefront.g2.hurl`) pasó dos veces seguidas
contra el cluster y contra compose; la de G1, con los cinco servicios, también.

### 5.3 Lo que G2 rompió y nadie había previsto: la caché del navegador

"Perfil nuevo", arriba, no es un detalle. La primera vez que abrí la página de QA con G2 desplegado
usé el mismo perfil de Chrome con el que había visto G1, y Chrome me mostró **G1**: el `index.html`
viejo, con su JavaScript viejo, sacado de su caché. nginx no le decía nada sobre cuánto guardarlo
(`last-modified` y `etag`, sin `Cache-Control`), y el navegador decidió solo. Un usuario real habría
visto la página vieja después del despliegue, sin forma de saberlo.

El arreglo es una cabecera más en la plantilla, para la página misma:

```nginx
    location = /index.html {
        add_header Cache-Control "no-cache" always;
    }
```

`no-cache` no quiere decir "no guardes": quiere decir "pregunta antes de usar lo que guardaste". Para
comprobarlo, un perfil abrió la página de QA con G2 y la cabecera nueva; después desplegué en QA la
imagen de G1, y el mismo perfil volvió a abrirla: vio G1 al instante, porque preguntó. Los archivos de
`assets/` llevan un hash en el nombre y se pueden guardar para siempre.

> 🩻 **Esto sí funciona igual.** El `.env` de compose y el `ConfigMap` resuelven lo mismo: variables
> que llegan al proceso al arrancar. Lo que ninguno de los dos resuelve es lo que se hornea antes de
> arrancar: ni compose ni Kubernetes pueden cambiar lo que ya está escrito en un archivo compilado.

**Prueba de fuego.** `curl -s http://storefront-qa.localhost:8080/config.json` con `api-qa` y la página
de QA con su producto de pruebas, desde la **misma** imagen que producción.

**El patrón a memorizar.** Lo que cambia por ambiente se lee al arrancar; lo que se compila es igual en
todos lados. Y lo que se lee al arrancar no se guarda en la caché del navegador.

---

## 🔁 6. La tabla de topes de `pricing`, y las credenciales del portal

### 6.1 Un `ConfigMap` como archivo

El tope regulado de `pricing` (G1, D23) es una tabla `SKU,tope`, y `pricing` la lee de un archivo.
Un `ConfigMap` también se puede montar como carpeta, con una entrada por clave:

```yaml
          env:
            - name: REGULATED_CAP_ENABLED
              value: "true"
          volumeMounts:
            - name: regulated-caps
              mountPath: /etc/pricing        # regulated-caps.csv, la ruta por defecto de REGULATED_CAP_FILE
              readOnly: true
      volumes:
        - name: regulated-caps
          configMap:
            name: pricing-regulated-caps
```

Con la tabla en `SKU-0003,20000`, un precio de 21.900 sale recortado:

```text
2026/10/04 02:27:13 tope regulado encendido: 1 productos con tope
{"sku":"SKU-0003","store":"DRO-007","price":20000,"currency":"COP","regulatedCap":20000,"capped":true}
```

La circular nueva baja el tope a 18.000. Es un cambio del `ConfigMap`, y la sección 7 mide qué pasa.

### 6.2 🏚️ La contraseña de 2019, en un `Secret`

El portal llegó al cluster en la [Fase 10](10-la-entrada-al-sistema.md) con su `.env` adentro: el `APP_KEY` y las credenciales SOAP
de Contingencia, en texto plano, versionadas desde 2019 y horneadas en la imagen porque nadie escribió
un `.dockerignore` ([a16](a16-el-patrimonio.md)). Un `Secret` es el objeto para lo que no debería
estar a la vista, y se crea desde un archivo que **no** se versiona (`.secrets/portal-contingencia.env`,
que `task legacy:up TARGET=cluster` lee si existe):

```yaml
            - name: CONTINGENCIA_SOAP_PASSWORD
              valueFrom:
                secretKeyRef: {name: portal-contingencia, key: CONTINGENCIA_SOAP_PASSWORD}
```

Y aproveché para rotar la contraseña. Lo que se ve, en orden:

```text
$ kubectl -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}'
Um90YWRhLTIwMjYtMTA=
$ kubectl -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}' | base64 -d
Rotada-2026-10
```

**base64 no es cifrado**: es una forma de escribir bytes con letras, y se deshace con un comando que
no pide ninguna clave. Cualquiera que pueda leer el `Secret` tiene la contraseña. Lo que protege a un
`Secret` son los permisos sobre él ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)), no su formato.

```text
$ kubectl -n legacy exec deploy/portal -- php artisan config:show services.contingencia
  password .................................................... Rotada-2026-10
$ kubectl -n legacy exec deploy/portal -- grep SOAP_PASSWORD .env
CONTINGENCIA_SOAP_PASSWORD=Vecina2019*
$ kubectl -n legacy exec deploy/portal -- php artisan catalog:sync
  No autorizado
command terminated with exit code 1
```

Tres verdades en tres comandos. Laravel prefiere la variable del contenedor sobre el `.env`, así que el
portal usa la contraseña nueva. El `.env` con la vieja **sigue en la imagen**. Y la sincronización
falla, porque **un secreto tiene dos puntas**: Contingencia comprueba la contraseña por HTTP Basic, y
la suya seguía siendo `Vecina2019*`, escrita en su manifiesto. La solución es que las dos puntas lean
el mismo `Secret`, y que rotar sea cambiar el `Secret` y reiniciar a los dos:

```text
$ kubectl apply -f deploy/legacy/contingencia.yaml
deployment "contingencia" successfully rolled out
$ kubectl -n legacy exec deploy/portal -- php artisan catalog:sync
8 productos sincronizados desde Contingencia
```

Entre esas dos líneas hubo un intento fallido más, honesto y de otra fase: el primer `catalog:sync`
después del *rollout* respondió `SOAP-ERROR: Parsing WSDL: Couldn't load from 'http://contingencia:8080/…'`.
Contingencia figuraba lista y su servidor de aplicaciones todavía no había desplegado el servicio. Es
la readiness que miente, y la cobra la [Fase 15](15-salud-y-recursos.md).

### 6.3 Lo que el `Secret` no arregla

La contraseña vieja sigue en dos sitios que el `Secret` no toca. En la imagen:

```text
$ docker run --rm --entrypoint grep lab/legacy-portal:a16 SOAP_PASSWORD .env
CONTINGENCIA_SOAP_PASSWORD=Vecina2019*
```

Y en el historial de git, aunque el archivo se borre. Lo reproduje en un repositorio de prueba: un
commit con el `.env`, otro que lo borra y lo agrega al `.gitignore`:

```text
$ git log --oneline
5351b56 f11: las credenciales pasan a un Secret
2d5589b portal: configuración inicial (2019)
$ git log -p --all -S SOAP_PASSWORD -- .env | grep PASSWORD
-CONTINGENCIA_SOAP_PASSWORD=Vecina2019*
+CONTINGENCIA_SOAP_PASSWORD=Vecina2019*
```

Por eso el orden correcto no es "mover a un `Secret`", sino **rotar** —la contraseña vieja deja de
servir— y después mover. Una contraseña que estuvo en git se da por publicada.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto: *"cambio la configuración y el servicio la toma"*. En compose, cambiar el `.env` o el
`environment:` y correr `up -d` recrea el contenedor, y el servicio arranca con lo nuevo: el cambio y el
reinicio son el mismo gesto. En Kubernetes son **dos gestos**, y el segundo nadie lo hace por ti.

> 🪞 **Apuesta antes de ejecutar.** Después de cambiar la tabla de topes regulados en el `ConfigMap`,
> `pricing` sigue respondiendo con el tope viejo al menos cinco minutos: el archivo montado se
> actualiza, pero `pricing` lo leyó al arrancar.
>
> **Resultado: ganada.** Cada 30 segundos, el archivo que ve un pod testigo que monta el mismo
> `ConfigMap`, y la respuesta de `pricing`:

```text
t=0s archivo montado: SKU-0003,20000 · pricing: {…"price":20000,…"regulatedCap":20000,"capped":true}
t=60s archivo montado: SKU-0003,20000 · pricing: {…"price":20000,…"regulatedCap":20000,"capped":true}
t=90s archivo montado: SKU-0003,18000 · pricing: {…"price":20000,…"regulatedCap":20000,"capped":true}
t=393s archivo montado: SKU-0003,18000 · pricing: {…"price":20000,…"regulatedCap":20000,"capped":true}
```

El archivo cambió entre los 60 y los 90 segundos —el kubelet sincroniza los `ConfigMap` montados
periódicamente, no al instante— y `pricing` siguió cobrando con el tope viejo los seis minutos y medio
que duró la prueba. Habría seguido así hasta el próximo reinicio, cuando fuera.

Y el reinicio trajo su propia sorpresa:

```text
$ kubectl -n apps rollout restart deployment/pricing
deployment "pricing" successfully rolled out
$ curl -sS 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'
{"error":"not_found","message":"sin precio para SKU-0003 en DRO-007"}
```

El pod nuevo leyó el tope de 18.000… y no tenía ningún precio: el SQLite de G1 vive en un `emptyDir`,
y se fue con el pod viejo (la deuda de la [Fase 09](09-los-cuatro-servicios-dentro.md), que la [Fase 12](12-estado-y-almacenamiento.md) cobra). Con el precio cargado de
nuevo, `{"price":18000,…"regulatedCap":18000,"capped":true}`. Y un segundo detalle, para la [Fase 16](16-escalado-y-rollout.md):
una petición enviada justo mientras el pod viejo terminaba recibió `upstream connect error or
disconnect/reset before headers`.

**Tres formas de entregar un `ConfigMap`, y no se comportan igual.** Un pod de prueba recibió el mismo
`ConfigMap` como variable de entorno, como carpeta y como un solo archivo con `subPath`; después lo
cambié de 20000 a 18000:

```text
t=60s env=20000 carpeta=20000 subpath=20000
t=90s env=20000 carpeta=18000 subpath=20000
t=150s env=20000 carpeta=18000 subpath=20000
```

La variable no cambia nunca dentro de un pod que ya corre; la carpeta, con retraso; el `subPath`,
nunca. Y en los tres casos, el proceso que ya leyó la configuración no se entera.

---

## 🧨 8. La rotura: el `Secret` que no existe

Una máquina nueva, alguien que clonó el repositorio y no creó `.secrets/`, o un `Secret` borrado por
error. **El cambio exacto:** borrar el `Secret` `portal-contingencia` y el pod del portal.

```text
$ kubectl -n legacy get pods -l app.kubernetes.io/name=portal
NAME                      READY   STATUS                       RESTARTS   AGE
portal-687b98b68c-lnv6l   0/1     CreateContainerConfigError   0          47s
$ kubectl -n legacy describe pod -l app.kubernetes.io/name=portal | sed -n '/^Events:/,$p' | tail -1
  Warning  Failed     4s (x5 over 46s)  kubelet            spec.containers{portal}: Error: secret "portal-contingencia" not found
```

**El síntoma:** el contenedor **ni se crea**. No hay logs que leer, porque no hay proceso. La razón
está en los eventos, y es literal. **Para salir:** crear el `Secret`. El kubelet lo reintenta solo: el
portal estuvo listo 8 segundos después, sin reiniciar nada.

Contingencia, que también lee ese `Secret`, siguió `Running`: sus variables se resolvieron cuando
arrancó. Se habría caído en su próximo reinicio, a cualquier hora. Un `Secret` del que dependen dos
pods se rompe dos veces, y la segunda vez nadie lo relaciona con la primera.

---

## ⚰️ 9. Autopsia: la configuración horneada en la imagen

**La decisión, con su mejor argumento.** Compilar la dirección del API dentro del JavaScript: *"es lo
que hace la plantilla de Vite (`import.meta.env`), funciona en desarrollo sin configurar nada, y el
navegador no tiene variables de entorno, así que no hay otra forma."*

**Por qué era razonable.** Con un solo ambiente es inofensivo, y es lo que enseña cualquier tutorial de
Vite o de React.

**Qué pasa después, con número.** Una imagen por ambiente. Con QA y producción, dos imágenes del mismo
código, que no son la misma: lo que QA aprobó no es lo que se despliega. Y la sección 4 mostró las dos
formas de fallar: con CORS cerrado, `Failed to fetch` contra la dirección equivocada; con CORS abierto,
**cero errores** y los dos productos de producción en la página de QA.

**Cuánto cuesta salir, con número.** Un archivo de plantilla de 26 líneas, dos `ENV` en el Dockerfile,
un `fetch` más en la página y un `ConfigMap` por ambiente. Y la cabecera de caché, que fue lo que
faltó la primera vez.

**Qué lo habría cambiado.** Preguntar *¿esta imagen puede correr en otro ambiente sin compilarse de
nuevo?* antes del primer despliegue, no después del primer incidente.

**Antes y después, con números:** antes, una imagen por ambiente y una página de QA mostrando 2
productos de producción sin un error; después, una imagen (`lab/storefront:g2`) y dos catálogos, el de
QA con su `SKU-9001`.

---

## 📖 10. Traducción

| En compose o en la máquina virtual | En Kubernetes | Lo que cambia |
|---|---|---|
| `environment:` / `.env` | `env` y `envFrom` desde un `ConfigMap` | el `ConfigMap` es un objeto aparte, compartible; cambiarlo no reinicia nada |
| un archivo de configuración montado con un volumen | un `ConfigMap` montado como carpeta | el archivo se actualiza solo, con retraso; el proceso no se entera |
| `secrets:` de compose, o un archivo con permisos 600 en el servidor | un `Secret`, como variable o como carpeta | base64 en el objeto; la protección son los permisos sobre él |
| `docker compose up -d` después de cambiar el `.env` | `kubectl rollout restart` | en compose, cambiar y reiniciar son un gesto; aquí, dos |
| `ARG` en el Dockerfile | *sin equivalente* | lo que se decide al construir no lo cambia ningún objeto del cluster |

Y de vuelta: un `ConfigMap` montado como carpeta, en compose, es un volumen de solo lectura con un
archivo, que solo cambia si alguien lo edita en el host; y un `Secret` es un archivo que no se versiona,
igual que aquí. Las filas completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

---

## 🩺 11. Incidentes de esta fase

- **[09 — Cambié la configuración y el servicio sigue igual](cuaderno-incidentes.md#-incidente-09--cambié-la-configuración-y-el-servicio-sigue-igual).**
  El `ConfigMap` dice 18.000, el archivo montado dice 18.000, y `pricing` sigue recortando a 20.000.
- **[10 — El pod no llega ni a arrancar](cuaderno-incidentes.md#-incidente-10--el-pod-no-llega-ni-a-arrancar).**
  `CreateContainerConfigError`, ningún log, y el portal fuera de servicio.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Un `Secret` no es un lugar seguro: es un lugar separado.** Separa la credencial de la imagen y del
repositorio, y la deja tras los permisos del cluster. No la cifra en tránsito por `kubectl`, ni en
reposo si nadie lo configuró, ni la protege de quien puede leer `Secret` en el namespace. Si tu
amenaza es alguien con acceso al cluster, un `Secret` no te ayuda; si tu amenaza es la credencial en
git o en la imagen, sí, siempre que la rotes.

**Cuándo NO leer la configuración al arrancar.** Lo que no cambia entre ambientes —el nombre de una
ruta de la página, un límite del propio código— no gana nada viviendo en un `ConfigMap`: gana una
dependencia más que puede faltar. G2 lleva al `/config.json` solo lo que cambia por ambiente.

**Cuándo un archivo montado es peor que una variable.** Si el proceso no relee el archivo, un
`ConfigMap` montado como carpeta **parece** dinámico y no lo es: el archivo dice una cosa y el servicio
hace otra (incidente 09). Una variable de entorno, al menos, no le miente a quien entra al pod a mirar.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que lee su entorno al
arrancar. El orquestador te dio `ConfigMap` y `Secret`, y la actualización del archivo montado. **Te
tocó a ti** que la página lea su configuración al arrancar, que el servicio se reinicie cuando cambia, y
rotar la contraseña que el `Secret` no puede borrar del pasado.

---

## ⚠️ 13. Errores comunes y diagnóstico

**La página muestra lo viejo después de desplegar.** Causa: el `index.html` en la caché del navegador.
Comprobación 🩺: `curl -I` a la página y buscar `cache-control`. Salida: `no-cache` en `index.html`.

**`CreateContainerConfigError`.** Causa: un `ConfigMap` o un `Secret` que el pod nombra y no existe, o
una clave que no está. Comprobación 🩺: `kubectl describe pod`, los eventos.

**El `ConfigMap` cambió y el servicio no.** Causa: el proceso lo leyó al arrancar. Salida:
`kubectl rollout restart`, y la [Fase 13](13-helm-el-paquete.md) lo automatiza.

**`No autorizado` después de rotar.** Causa: se rotó una punta del secreto. Salida: las dos puntas del
mismo `Secret`, y reiniciar las dos.

**El `/config.json` con comillas rotas.** Causa: un valor con `"` dentro, que la plantilla no escapa.
Salida: valores sin comillas, o armar el JSON con otra herramienta.

---

## 📋 14. Checklist de validación

```text
[ ] la imagen de G1 en dos despliegues: QA falla contra api.localhost (y la variante silenciosa, vista)
[ ] G2: task conformance TARGET=cluster -- G2, dos veces, y lo mismo contra compose
[ ] la misma imagen :g2 en storefront y storefront-qa, con dos /config.json y dos catálogos
[ ] Cache-Control: no-store en /config.json y no-cache en la página
[ ] pricing con la tabla del ConfigMap, y el cambio que no llega hasta reiniciar
[ ] el Secret del portal decodificado con base64 -d, y las dos puntas leyéndolo
[ ] la contraseña vieja, todavía en la imagen
```

---

## 🧪 15. Ejercicios (20)

Un tercio son de diagnóstico; varios trabajan con el patrimonio.

## 🟢 Fácil — configuración (1–6)

### 🟢 Ejercicio 1 — G2 en tu máquina
Construye el `storefront` de G2 y despliégalo.

**Criterio:** `task conformance TARGET=cluster -- G2` pasa dos veces.

<details><summary>Solución</summary>

`task build -- storefront`, `task images:load -- minimo`, `task deploy -- minimo` y la suite.
</details>

### 🟢 Ejercicio 2 — Otro nombre
Cambia `BRAND_NAME` en `storefront-config` y haz que la página lo muestre.

**Criterio:** el título nuevo en el navegador.

<details><summary>Solución</summary>

`kubectl -n apps edit configmap storefront-config` y `kubectl -n apps rollout restart deploy/storefront`.
Sin el reinicio no cambia: `envFrom` se lee al crear el contenedor.
</details>

### 🟢 Ejercicio 3 — Decodifica
Lee la contraseña SOAP del `Secret` sin entrar a ningún pod.

**Criterio:** la contraseña en claro.

<details><summary>Solución</summary>

`kubectl -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}' | base64 -d`.
</details>

### 🟢 Ejercicio 4 — Las cabeceras
Comprueba las cabeceras de caché de `/config.json` y de la página.

**Criterio:** `no-store` y `no-cache`.

<details><summary>Solución</summary>

`curl -sS -I http://storefront.localhost:8080/config.json` y `curl -sS -I http://storefront.localhost:8080/`.
</details>

### 🟢 Ejercicio 5 — Qué ve el pod
Muestra la tabla de topes que ve un pod que monta el `ConfigMap`.

**Criterio:** el contenido del archivo.

<details><summary>Solución</summary>

`pricing` no tiene shell: un pod testigo que monta el mismo `ConfigMap`, como en la sección 7, y
`kubectl exec testigo -- cat /etc/pricing/regulated-caps.csv`. Bórralo al terminar.
</details>

### 🟢 Ejercicio 6 — El ambiente de QA
Despliega `deploy/qa/qa.yaml`, crea un producto en `api-qa.localhost` y míralo en la página de QA.

**Criterio:** el producto de QA en `storefront-qa.localhost`, y no en `storefront.localhost`.

<details><summary>Solución</summary>

`kubectl apply -f deploy/qa/qa.yaml`, un `POST` a `http://api-qa.localhost:8080/catalog/products` y
las dos páginas.
</details>

## 🟡 Intermedio — dos gestos (7–12)

### 🟡 Ejercicio 7 — La circular
Cambia el tope del salbutamol en el `ConfigMap` y haz que `pricing` lo aplique.

**Criterio:** `regulatedCap` con el valor nuevo, y el precio recargado.

<details><summary>Solución</summary>

Editar el `ConfigMap`, `rollout restart`, y otra vez el `PUT` del precio: el reinicio borró el SQLite.
</details>

### 🟡 Ejercicio 8 — Cuánto tarda el archivo
Mide cuánto tarda el archivo montado en cambiar después de editar el `ConfigMap`, tres veces.

**Criterio:** tres tiempos, y por qué no son iguales.

<details><summary>Solución</summary>

El pod testigo y un bucle cada 5 segundos. Varían porque el kubelet sincroniza en su propio ciclo, no
cuando cambia el objeto.
</details>

### 🟡 Ejercicio 9 — Variable contra carpeta
Entrega el mismo `ConfigMap` a un pod como variables y como carpeta, cámbialo, y mira las dos.

**Criterio:** la variable sin cambiar y el archivo cambiado.

<details><summary>Solución</summary>

Un pod con `envFrom` y un `volume` del mismo `ConfigMap`; `printenv` y `cat` antes y después de un
minuto y medio.
</details>

### 🟡 Ejercicio 10 — Rotar bien
Rota la contraseña SOAP otra vez, sin que la sincronización falle ni un minuto.

**Criterio:** `catalog:sync` exitoso antes y después, y el orden de los pasos.

**Rúbrica:** con un solo usuario, no se puede sin una ventana: Contingencia acepta una contraseña.
Discute qué haría falta (dos credenciales válidas a la vez) y por qué el patrimonio no lo permite.

### 🟡 Ejercicio 11 — El `.env` en la imagen
Encuentra todo lo que el `.env` del portal deja dentro de la imagen.

**Criterio:** la lista de valores sensibles, y en qué capa están.

<details><summary>Solución</summary>

`docker run --rm --entrypoint cat lab/legacy-portal:a16 .env` y `docker history lab/legacy-portal:a16`:
el `APP_KEY` y las dos credenciales, en la capa del `COPY`.
</details>

### 🟡 Ejercicio 12 — Un `.dockerignore`
Agrega un `.dockerignore` al portal que deje el `.env` fuera de la imagen, y comprueba que el portal
sigue arrancando con el `Secret`.

**Criterio:** `grep` del `.env` falla en la imagen nueva, y el portal sincroniza.

**Rúbrica:** el `APP_KEY` ya no viene del `.env`: ¿de dónde sale ahora? (otro valor del `Secret`).

## 🟠 Difícil — diagnosticar (13–17)

### 🟠 Ejercicio 13 — El incidente 09
Provoca el incidente 09 y diagnostícalo sin el cuaderno. **Predice** qué vas a encontrar en el archivo.

**Criterio:** la causa y el comando que la confirmó.

**Rúbrica:** el archivo montado ya cambió; el proceso no; y el log de arranque de `pricing` con su hora.

### 🟠 Ejercicio 14 — El incidente 10
Provoca el incidente 10. **Predice** qué pasa con Contingencia.

**Criterio:** la predicción, el estado de los dos pods, y qué haría falta para que Contingencia también
cayera.

**Rúbrica:** Contingencia sigue `Running` hasta su próximo reinicio; un `rollout restart` la deja en
`CreateContainerConfigError`.

### 🟠 Ejercicio 15 — La página vieja
Reproduce la página vieja en caché: con la cabecera de `index.html` quitada, abre la página, despliega
otra imagen y vuelve a abrirla con el mismo perfil del navegador.

**Criterio:** la página vieja, y la cabecera que lo explica.

**Rúbrica:** sin `Cache-Control`, el navegador calcula su propia frescura a partir de `last-modified`.

### 🟠 Ejercicio 16 — El JSON roto
Pon un `BRAND_NAME` con comillas dobles. **Predice** qué ve el navegador.

**Criterio:** la predicción y el error real.

**Rúbrica:** el `/config.json` deja de ser JSON y la página cae al aviso; y por qué `envsubst` no
escapa nada.

### 🟠 Ejercicio 17 — La clave que falta
Cambia el `secretKeyRef` del portal a una clave que no existe en el `Secret`. **Predice** el estado.

**Criterio:** el estado y el mensaje literal de los eventos.

**Rúbrica:** el mismo `CreateContainerConfigError`, con otro mensaje (`couldn't find key … in Secret
legacy/portal-contingencia`); y cómo `optional: true` cambiaría eso (y por qué aquí sería peor).

## 🔴 Muy difícil — producción (18–20)

### 🔴 Ejercicio 18 — Que el cambio reinicie solo
Haz que cambiar `pricing-regulated-caps` reinicie `pricing` sin un comando aparte, sin Helm.

**Criterio:** editar el `ConfigMap` y ver el pod nuevo.

**Rúbrica:** una anotación en la plantilla del pod con un hash del contenido, recalculada al aplicar; o
que `pricing` vigile el archivo. Discute cuál preferirías y qué pierdes con cada una.

### 🔴 Ejercicio 19 — El historial
En un repositorio de prueba, saca el `.env` del historial de git, no solo del último commit.

**Criterio:** `git log -p --all -S SOAP_PASSWORD` sin resultados.

**Rúbrica:** la herramienta usada; que reescribir el historial obliga a todos a volver a clonar; y por qué
la contraseña igual se da por publicada.

### 🔴 Ejercicio 20 — La segunda cadena
Diseña cómo el mismo `storefront` serviría a la cadena de Don Rodrigo con su nombre y su API.

**Criterio:** los objetos que cambiarías y los que no.

**Rúbrica:** un `ConfigMap` por cadena y la misma imagen; el host y la ruta; el CORS; y qué le faltaría
al `/config.json` para que la página no dependiera de La Vecina en ningún texto.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *ConfigMaps* (y cuándo se actualizan los montados): https://kubernetes.io/docs/concepts/configuration/configmap/
- Kubernetes, *Secrets* y sus advertencias: https://kubernetes.io/docs/concepts/configuration/secret/
- Kubernetes, *Good practices for Kubernetes Secrets*: https://kubernetes.io/docs/concepts/security/secrets-good-practices/
- nginx, imagen oficial, *Using environment variables in nginx configuration*: https://hub.docker.com/_/nginx
- MDN, *Cache-Control*: https://developer.mozilla.org/es/docs/Web/HTTP/Reference/Headers/Cache-Control
- Vite, *Env Variables and Modes* (por qué se hornean): https://vite.dev/guide/env-and-mode

**Ensayos**

- *The Twelve-Factor App*, factor III, *Config*: https://12factor.net/config

**Orden de lectura sugerido:** antes, el factor III; durante, la página de *ConfigMaps*; después, las
buenas prácticas de *Secrets*, con la sección 6.3 delante.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
LA CONFIGURACIÓN AL CERRAR LA FASE 11 (minimo)

  storefront   lab/storefront:g2   ← ConfigMap storefront-config (envFrom)  → /config.json al arrancar
  pricing      lab/pricing:g1      ← ConfigMap pricing-regulated-caps (carpeta /etc/pricing), REGULATED_CAP_ENABLED=true
  legacy/portal       ← Secret portal-contingencia (secretKeyRef)  · el .env viejo, todavía en la imagen
  legacy/contingencia ← el mismo Secret: las dos puntas
  .secrets/portal-contingencia.env   ← fuera de git
```

> **La señal de que quedó bien:** *"Despliego la misma imagen en otro ambiente sin compilar, sé qué
> reinicio exige cada cambio de configuración, y sé qué contraseña ya no es secreta aunque esté en un
> `Secret`."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-11-configuracion-y-secretos -m "F11 cerrada: G2 del storefront (config.json al arrancar, caché); topes de pricing en un ConfigMap; credenciales SOAP del portal y Contingencia en un Secret; incidentes 09 y 10"
> ```
>
> Y los pares de los incidentes: `inc/09/configmap-not-reloaded-roto` y `…-fix`,
> `inc/10/secret-missing-roto` y `…-fix`. Commits con prefijo `f11:`
> ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F13:** el hash de configuración en la plantilla, que reinicia `pricing` cuando cambia su tabla.
- **F15:** la readiness de Contingencia, que dijo listo antes de desplegar su servicio SOAP.
- **F16:** el `upstream connect error` durante el reinicio de `pricing`.
