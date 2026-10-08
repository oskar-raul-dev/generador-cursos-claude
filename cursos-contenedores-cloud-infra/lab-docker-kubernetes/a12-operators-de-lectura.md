# 📎 Apéndice a12 — Operators y recursos propios, de lectura

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 10](10-la-entrada-al-sistema.md) (Envoy Gateway), [Fase 19](19-tls-y-certificados.md) (cert-manager) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** ninguna; mira lo que el curso ya instaló
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Es de lectura: no instala ni
escribe un operator. Enseña a reconocer los que el curso ya tiene corriendo, a leer lo que dicen y —lo que más sirve— a
saber qué **no** van a arreglar solos.

**Qué queda fuera:** escribir un operator propio, que es una exclusión del curso.

---

## Índice

- [Un recurso propio y su controlador](#un-recurso-propio-y-su-controlador)
- [Los que el curso ya tiene](#los-que-el-curso-ya-tiene)
- [El bucle, en vivo: cert-manager](#el-bucle-en-vivo-cert-manager)
- [Lo que el operator no vigila: el proxy de la puerta](#lo-que-el-operator-no-vigila-el-proxy-de-la-puerta)
- [Cómo se lee un operator](#cómo-se-lee-un-operator)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-5)

---

## Un recurso propio y su controlador

Un `Deployment` es un objeto que Kubernetes trae y un controlador que lo hace verdad ([Fase 08](08-el-primer-despliegue.md)).
Un **operator** es lo mismo para algo que Kubernetes no trae: una **definición de recurso propio** (CRD) que agrega un tipo
nuevo a la API —`Certificate`, `Gateway`, `HTTPRoute`— y un **controlador** que lo vigila y hace lo necesario para que lo
que dice el objeto exista. El patrón es el de todo el cluster: deseo declarado, observación, corrección.

## Los que el curso ya tiene

```text
$ kubectl get crd -o jsonpath='{range .items[*]}{.spec.group}{"\n"}{end}' | sort | uniq -c | sort -rn
  10 gateway.networking.k8s.io           Gateway API: la especificación, sin controlador propio
   8 gateway.envoyproxy.io               Envoy Gateway: su configuración (EnvoyProxy, SecurityPolicy…)
   4 cert-manager.io                     cert-manager: Certificate, Issuer, ClusterIssuer, CertificateRequest
   3 gateway.networking.x-k8s.io         Gateway API, el canal experimental
   2 acme.cert-manager.io                cert-manager, para ACME (el curso no lo usa)
   1 trust.cert-manager.io               trust-manager: Bundle
total: 28
```

Una lección escondida en la tabla: **Gateway API no es un operator.** Sus diez CRD son una especificación; el que la
cumple es Envoy Gateway, con su controlador (80 MiB) y el proxy que crea para cada `Gateway` (50 MiB). Cambiar de
controlador ([Fase 10](10-la-entrada-al-sistema.md) nombra cinco) no cambia los recursos.

## El bucle, en vivo: cert-manager

Un `Certificate` de prueba, firmado por la CA del laboratorio ([Fase 19](19-tls-y-certificados.md)):

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: {name: a12-prueba, namespace: default}
spec:
  secretName: a12-prueba-tls
  dnsNames: [a12.localhost]
  duration: 24h
  issuerRef: {name: lab-ca, kind: ClusterIssuer}
```

El controlador lo hizo verdad en menos de un segundo. Y cuando se le quita lo que produjo:

```text
$ kubectl -n default delete secret a12-prueba-tls
cert-manager lo repuso en 0.4 s
Issuing     Issuing certificate as Secret does not exist
Requested   Created new CertificateRequest resource "a12-prueba-2"
Issuing     The certificate has been successfully issued
```

El `Certificate` es el deseo; el `Secret`, el resultado; el `CertificateRequest`, el registro de cada intento. Los eventos
del objeto son la voz del operator: lo primero que se lee cuando algo no aparece ([Fase 21](21-diagnostico.md)).

## Lo que el operator no vigila: el proxy de la puerta

Envoy Gateway crea un `Deployment` con el proxy de Envoy para el `Gateway` `lab`. Con la misma idea que el `Secret`, se lo
bajó a cero:

```text
$ kubectl -n gateway scale deploy/envoy-gateway-lab-2c82546a --replicas=0
```

**No volvió.** La puerta quedó caída 13 minutos, sin una alarma (la observabilidad estaba apagada), hasta que se le
devolvió la réplica a mano; a los 11,1 s, la puerta contestó. La razón está en quién es dueño de cada campo:

```text
$ kubectl -n gateway get deploy envoy-gateway-lab-2c82546a -o json --show-managed-fields   # resumido
envoy-gateway             Apply    2026-10-04T07:44:08Z           no toca spec.replicas
kube-controller-manager   Update   2026-10-05T08:23:49Z   status  toca spec.replicas
```

Envoy Gateway declara su proxy con *server-side apply* ([Fase 13](13-helm-el-paquete.md)) y **no declara las réplicas**
(las deja al valor por defecto, o a un autoescalado). Un campo que el operator no declaró, el operator no lo defiende. El
`Secret` de cert-manager es el producto entero del `Certificate`: lo defiende todo. El número de réplicas de un proxy no
estaba en ningún deseo.

> ⚠️ **Error de método, dicho:** la primera medición de esta sección imprimió *"de vuelta en 1/1 a los 136 s"*; el script
> lo escribía al agotar su espera, hubiera vuelto o no. Se notó porque la puerta seguía caída minutos después. No se
> publicó, y quedó así en el registro de la verificación.

## Cómo se lee un operator

```bash
kubectl get crd | grep <grupo>                           # qué tipos agrega
kubectl explain certificate.spec                         # sus campos, con la documentación de la API
kubectl get <tipo> -A                                    # sus objetos, con las columnas que el operator eligió
kubectl describe <tipo> <nombre>                         # sus condiciones y sus eventos: la voz del operator
kubectl get <objeto que creó> --show-managed-fields -o yaml   # qué campos defiende y cuáles no
kubectl -n <su namespace> logs deploy/<controlador>      # lo que hizo, y por qué no hizo lo que esperabas
```

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| algo que el cluster no trae (certificados, una puerta, una base replicada) | un operator mantenido por otros | el bucle ya está escrito y probado |
| un objeto que el operator creó se ve mal | arreglar el recurso propio, no el objeto | lo que el operator defiende lo va a deshacer; lo que no, se queda mal |
| tocar a mano lo que un operator creó (un `scale` en un incidente) | anotarlo y devolverlo | si el campo no es suyo, nadie lo devuelve |
| automatizar algo propio de La Vecina | un `CronJob` o un servicio, antes que un operator | escribir uno es otro curso, y aquí queda fuera |

## ⚠️ Advertencias

- La reposición de 0,4 s es una corrida, con un emisor local (una CA); con ACME depende de la red.
- Que Envoy Gateway no defienda las réplicas es de su versión y su configuración en [a01](a01-el-laboratorio.md); con un
  `EnvoyProxy` que declare las réplicas, el comportamiento cambia, y no se verificó.

## 📚 Referencias

- Kubernetes, *Operator pattern*: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
- Kubernetes, *Custom Resources*: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- Kubernetes, *Server-Side Apply* (los dueños de cada campo): https://kubernetes.io/docs/reference/using-api/server-side-apply/
- cert-manager, *Certificate resource*: https://cert-manager.io/docs/usage/certificate/
- Envoy Gateway, *Customize EnvoyProxy* (las réplicas del proxy): https://gateway.envoyproxy.io/docs/tasks/operations/customize-envoyproxy/
- Operator Framework: https://operatorframework.io/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (5)

### Ejercicio 1 — El inventario
Cuenta las CRD de tu cluster por grupo y di qué controlador atiende a cada grupo.

**Criterio:** la tabla de la sección de los que el curso tiene, con tu cluster, y el nombre del `Deployment` de cada
controlador.

### Ejercicio 2 — El `Secret`, otra vez
Repite la prueba del `Certificate` y mira el log de cert-manager mientras borras el `Secret`.

**Criterio:** la línea del log que dice por qué reemitió, y el tiempo hasta que el `Secret` vuelve.

### Ejercicio 3 — Lo que se defiende
Cambia a mano una etiqueta del `Deployment` del proxy de la puerta y otra en su `spec.template`, y mira cuál vuelve.

**Criterio:** cuál deshizo Envoy Gateway y cuál no, con los `managedFields` que lo explican.

### Ejercicio 4 — Las réplicas, declaradas
Busca en la documentación de Envoy Gateway cómo declarar las réplicas del proxy en el `EnvoyProxy`, y repite el `scale` a
cero.

**Criterio:** el proxy de vuelta solo, y el tiempo que tardó. (No verificado por el autor: es lo que este ejercicio
comprueba.)

### Ejercicio 5 — ¿Un operator para La Vecina?
Alguien propone escribir un operator para "las droguerías": un recurso `Store` que cree su configuración en los cinco
servicios. Escribe la respuesta.

**Criterio:** media página: qué resolvería, qué costaría escribirlo y mantenerlo, y con qué se resuelve hoy (el seed de la
[Fase 12](12-estado-y-almacenamiento.md), un `Job`).

---

> 🏷️ **Este apéndice no lleva tag propio.**
