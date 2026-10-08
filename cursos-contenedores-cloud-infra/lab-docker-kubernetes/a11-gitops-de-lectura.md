# 📎 Apéndice a11 — GitOps, de lectura

> **Curso:** Laboratorio de contenedores y Kubernetes local · 🔥 Ampliación
> **Usado por:** [Fase 13](13-helm-el-paquete.md) (la deriva que Helm no devuelve), [Fase 14](14-helm-en-operacion.md) (la segunda cadena) · **Versiones cubiertas:** las de [a01](a01-el-laboratorio.md)
> **Memoria que suma al perfil `lab`:** 443 MiB con Argo CD en reposo (siete pods); la máquina virtual subió 716 MiB. Con 4 GiB y la observabilidad encendida no entra: apaga Grafana y Prometheus primero
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64 con Docker Desktop, cluster `lab`

**Esto no se lee de corrido.** Se entra por el índice buscando algo concreto y se sale. Es un apéndice **de lectura**: se
instala, se mira qué hace y se saca. El flujo —el repositorio de despliegue, las ramas por ambiente, la promoción— no se
construye, y el apéndice dice por qué.

**Qué queda fuera:** el flujo completo de GitOps; los secretos en git (el curso los deja en `.secrets/`); Flux, que se
nombra.

---

## Índice

- [Qué es, en una frase](#qué-es-en-una-frase)
- [Instalarlo y mirarlo](#instalarlo-y-mirarlo)
- [La deriva, otra vez](#la-deriva-otra-vez)
- [Qué resuelve](#qué-resuelve)
- [Qué cuesta](#qué-cuesta)
- [Por qué no está en el camino base](#por-qué-no-está-en-el-camino-base)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-5)

---

## Qué es, en una frase

**GitOps es que el estado del cluster lo describa un repositorio, y que un proceso dentro del cluster lo compare todo el
tiempo con lo que hay y lo corrija.** Nadie corre `task deploy` desde su máquina: alguien fusiona un cambio en el
repositorio, y el controlador lo aplica. Es el bucle de reconciliación de la [Fase 08](08-el-primer-despliegue.md) (el
`Deployment` que repone sus pods), subido un piso: del pod al sistema entero.

## Instalarlo y mirarlo

Argo CD, en la versión de [a01](a01-el-laboratorio.md), con su manifiesto oficial (las CRD son grandes: `--server-side`):

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.3/manifests/install.yaml
```

```text
listo en 48 s
argocd-application-controller-0        el que compara y corrige
argocd-repo-server-…                   el que clona el repositorio y renderiza (Helm, Kustomize, YAML)
argocd-server-…                        la API y la interfaz web
argocd-applicationset-controller-…     el que genera Applications en serie (una por cadena, por cluster)
argocd-dex-server-…                    el inicio de sesión
argocd-notifications-controller-…      los avisos
argocd-redis-…                         la caché
```

Tres CRD nuevas (`Application`, `ApplicationSet`, `AppProject`). Una `Application` dice de dónde sale el estado y a dónde
va. Con el ejemplo público de Argo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: {name: guestbook, namespace: argocd}
spec:
  project: default
  source: {repoURL: https://github.com/argoproj/argocd-example-apps.git, targetRevision: HEAD, path: guestbook}
  destination: {server: https://kubernetes.default.svc, namespace: a11-guestbook}
  syncPolicy: {automated: {prune: true, selfHeal: true}}
```

```text
NAME        SYNC STATUS   HEALTH STATUS
guestbook   Synced        Healthy
```

## La deriva, otra vez

La [Fase 13](13-helm-el-paquete.md) midió que Helm 4 **no devuelve la deriva**: si alguien cambia un objeto a mano, el
cluster queda distinto del chart hasta el próximo `task deploy`, y ese despliegue puede chocar con el dueño del campo. Con
Argo CD y `selfHeal`:

```text
$ kubectl -n a11-guestbook scale deploy/guestbook-ui --replicas=3
deployment.apps/guestbook-ui scaled
Argo CD devolvió replicas a 1 en 0.2 s
```

Dos décimas de segundo. Es la promesa entera de GitOps en una línea: **lo que no está en el repositorio no dura**. Y es
también su filo: el `kubectl scale` de un incidente a las tres de la mañana tampoco dura. En GitOps, apagar un incendio
es abrir un cambio en el repositorio, o apagar la autocuración primero.

## Qué resuelve

- **La deriva**, sola y en segundos (arriba).
- **La auditoría**: cada cambio del cluster es un commit, con autor y revisión. La pregunta *"¿quién cambió esto?"* de la
  [Fase 14](14-helm-en-operacion.md) se contesta con `git log`.
- **Muchas instalaciones iguales**: un `ApplicationSet` genera una `Application` por cadena o por cluster. Es la rama 2 de
  la [Fase 27](27-el-veredicto-y-el-proyecto-final.md): diez cadenas con el mismo chart y diez archivos de valores.
- **Nadie despliega desde su portátil**: las credenciales del cluster las tiene el controlador, no cada persona.

## Qué cuesta

- **Un plano de control**: 443 MiB en reposo (el controlador de aplicaciones, 215; el inicio de sesión, 100), más que
  Istio ambient entero ([a10](a10-service-mesh.md)). En la máquina virtual de 4 GiB del curso, con la observabilidad
  encendida, no cabe.
- **Un repositorio y un flujo**: qué rama es qué ambiente, cómo se promueve un cambio de QA a producción, quién aprueba.
  Es trabajo de organización antes que de herramienta, y es el que este apéndice no construye.
- **Los secretos fuera de git**: los valores de `.secrets/` no pueden ir al repositorio. Se necesita otra pieza (secretos
  cifrados o un gestor externo), y los gestores externos son una exclusión del curso.
- **Dos verdades, si conviven**: un `task deploy` en un cluster gestionado por Argo CD crea la deriva que Argo va a
  deshacer. Se elige uno.

## Por qué no está en el camino base

Porque esconde lo que el curso enseña. Con GitOps, el lector no corre `helm upgrade`, no ve el `--rollback-on-failure`
devolver una revisión, ni el conflicto de dueños de un campo: los ve el controlador. El curso quiere que el mecanismo se
entienda a mano antes de delegarlo, como el YAML plano antes que Helm. Y porque cuesta lo que cuesta (arriba): en un
portátil, un Argo CD pesa más que los cinco servicios que despliega.

**Flux** (2.9.6 a la fecha de este apéndice) es la alternativa sin interfaz web y en varios controladores más pequeños;
no se instaló.

## 🧭 Cuándo usar qué

| Situación | Opción | Por qué |
|---|---|---|
| un equipo, un cluster, despliegues a mano y entendidos | `task deploy` con Helm, como el curso | sin plano de control extra; la deriva se ve con `task deploy:diff` |
| varias personas despliegan, y hay que saber quién cambió qué | GitOps | cada cambio es un commit |
| muchas instalaciones iguales (cadenas, clusters) | GitOps con `ApplicationSet` | una plantilla, muchas `Application` |
| un incidente que exige cambiar el cluster ya | apagar la autocuración, o un commit urgente | con `selfHeal`, el cambio a mano dura 0,2 s |

## ⚠️ Advertencias

- La deriva devuelta en 0,2 s es una corrida, con un cluster sin carga.
- La `Application` de este apéndice baja una imagen pública y un repositorio de internet: con el proxy corporativo del
  incidente 27, el repositorio también necesita la CA.
- Desinstalar con `kubectl delete -f` del mismo manifiesto se lleva las CRD; borrarlas deja sin efecto cualquier
  `Application` que quede.

## 📚 Referencias

- Argo CD: https://argo-cd.readthedocs.io/en/stable/ · *Installation*: https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/
  · *Automated Sync Policy* (`selfHeal`, `prune`): https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/
- El ejemplo `guestbook`: https://github.com/argoproj/argocd-example-apps
- OpenGitOps, los principios: https://opengitops.dev/
- Flux: https://fluxcd.io/flux/

> ⚠️ Las URL y los contenidos cambian.

## 🧪 Ejercicios (5)

### Ejercicio 1 — Instalar y contar
Instala Argo CD como en este apéndice y suma su memoria.

**Criterio:** siete pods en `Running` y la suma de `kubectl -n argocd top pods`, comparada con los 443 MiB de aquí.

### Ejercicio 2 — La deriva, cronometrada
Provoca tres derivas distintas en el `guestbook` (réplicas, una etiqueta, una variable de entorno) y mide cuánto tarda
cada una en volver.

**Criterio:** los tres tiempos, y cuál de las tres no volvió (si alguna), con su explicación.

### Ejercicio 3 — Sin autocuración
Quita `selfHeal` y repite la deriva de réplicas.

**Criterio:** la `Application` en `OutOfSync` y las réplicas en 3, hasta una sincronización manual.

### Ejercicio 4 — El chart del curso, por GitOps
Diseña (sin construirla) la `Application` que desplegaría `charts/platform` con los valores de `minimo` desde tu
repositorio.

**Criterio:** el YAML de la `Application`, y la lista de lo que el chart necesita que Argo CD no le da (los `Secret` de
`.secrets/`, la imagen cargada en el nodo, el `.observability.json`).

### Ejercicio 5 — ¿GitOps para La Vecina?
En media página: ¿Paracelso debería desplegar con GitOps?

**Criterio:** la respuesta en las dos ramas de la [Fase 27](27-el-veredicto-y-el-proyecto-final.md), con los 443 MiB y el flujo
que haría falta.

---

> 🏷️ **Este apéndice no lleva tag propio.**
