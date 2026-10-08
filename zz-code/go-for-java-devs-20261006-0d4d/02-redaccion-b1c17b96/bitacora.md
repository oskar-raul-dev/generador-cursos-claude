# Bitácora de ejecución · sesión b1c17b96-6d1e-4b11-8dfe-ad530444b436

Comandos que ejecutaron código, con el inicio de su salida.

### ⏱️ 2026-09-12T19:28:06Z · Inspect docker lab proposal structure and README

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
wc -l *.md && echo "=== src ===" && find src -type f | head -50 && echo "=== README ===" && cat README.md
~~~~~~

~~~~~~text
     224 00-instrucciones.md
     227 01-brief-inventario-supermercados.md
     300 02-diseno-dominios-y-experimentos.md
     239 03-certificados-tls.md
     222 04-lab-incidentes-certificados.md
     770 05-guia-docker-podman-windows-11.md
     245 06-anillo-0-refinamiento-y-hoja-de-ruta.md
     542 07-super-inventory-lab-plan-maestro.md
      75 README.md
    2844 total
=== src ===
src/.DS_Store
src/switch-container.ps1
src/microk8s-lab/Makefile
src/microk8s-lab/README.md
src/microk8s-lab/.gitignore
src/microk8s-lab/docs/fase-0-setup.md
src/microk8s-lab/docs/fase-8-sagas.md
src/microk8s-lab/docs/variantes.md
src/microk8s-lab/docs/fase-5-ingress.md
src/microk8s-lab/docs/fase-2-todos-los-servicios.md
src/microk8s-lab/docs/fase-7-grpc.md
src/microk8s-lab/docs/fase-3-4-helm.md
src/microk8s-lab/docs/fase-6-observabilidad.md
src/microk8s-lab/docs/fase-1-primer-servicio.md
src/microk8s-lab/kind/cluster.yaml
src/microk8s-lab/platform/observability/README.md
src/microk8s-lab/charts/platform/values-qa.yaml
src/microk8s-lab/charts/platform/Chart.yaml
src/microk8s-lab/charts/platform/values-e2e.yaml
src/microk8s-lab/charts/platform/values.yaml
src/microk8s-lab/charts/platform/values-local.yaml
src/microk8s-lab/docs/manifests/fase-1/catalog-node.yaml
src/microk8s-lab/services/web-legacy/Dockerfile
src/microk8s-lab/services/payments-go/go.mod
src/microk8s-lab/services/payments-go/Dockerfile
src/microk8s-lab/services/payments-go/main.go
src/microk8s-lab/services/catalog-node/server.js
src
~~~~~~

### ⏱️ 2026-09-12T19:28:15Z · Read master plan first part

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '1,120p' 07-super-inventory-lab-plan-maestro.md
~~~~~~

~~~~~~text
# super-inventory-lab — Plan maestro de construcción

Documento consolidado del juguete de microservicios para aprender infraestructura
cloud-native. Reúne todo lo diseñado hasta ahora: el laboratorio, las oleadas de
construcción (empezando por infra), los microservicios en detalle, los anillos de
aprendizaje, los experimentos Podman/Docker y los prompts para arrancar el
desarrollo con Claude Code o Codex.

Documentos fuente que complementa (no los reemplaza, los ordena):
`brief-inventario-supermercados.md`, `diseno-dominios-y-experimentos.md`,
`certificados-tls.md`, `lab-incidentes-certificados.md`,
`anillo-0-refinamiento-y-hoja-de-ruta.md`.

---

## 0. Objetivo y filosofía

**Qué se aprende:** Kubernetes local (kind), Helm, observabilidad open source,
redes, certificados/TLS, patrones distribuidos (gRPC, sagas, eventos), y el contraste
Docker Desktop vs Podman. El código de negocio es andamiaje: se genera rápido por
vibecoding; el valor está en todo lo que rodea a los servicios.

**Dominio:** inventario de una cadena de supermercados. Elegido porque genera datos
con volumen y estructura temporal (movimientos de stock por sucursal y producto),
lo que abre la puerta a un futuro juguete de ciencia de datos.

**Tres principios de trabajo:**

1. **Infra primero, dominio después.** Se construye en *oleadas horizontales* (cada
   oleada toca los 4 servicios con poca profundidad) en lugar de terminar un servicio
   antes de empezar el siguiente. Así se llega a jugar con infra en el
~~~~~~

### ⏱️ 2026-09-12T19:28:19Z · Read master plan services and rings

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '120,300p' 07-super-inventory-lab-plan-maestro.md
~~~~~~

~~~~~~text
**Definition of Done — Oleada 0:**
- [ ] `make up` crea el cluster y despliega los 4 servicios sin pasos manuales.
- [ ] Los 4 health checks responden OK dentro del cluster.
- [ ] Los 4 servicios aparecen en Prometheus como targets UP y en Loki con logs.
- [ ] `kind delete cluster` + `make up` reproduce todo desde cero.

### Oleada 1 — DB + un endpoint real por servicio

**Servicios:** cada backend suma su Postgres y UN endpoint con datos reales:
- catalog: `GET /products` desde DB con seed.
- inventory: `GET /stores` y `GET /stores/{id}/stock`.
- replenish: `GET /replenishments` (vacío pero leyendo de DB).
- web-inventory: página que lista productos consumiendo catalog.

**Infra:** subchart Postgres por servicio, Secrets con credenciales, connection
strings vía variables de entorno, Job de seed post-deploy (Helm hook
`post-install` o Job manual), migraciones de esquema por servicio.

**DoD:** los 4 endpoints leen de su propia DB; ningún servicio conoce la DB de otro;
`make up` desde cero deja los datos de seed cargados.

### Oleada 2 — El flujo central end-to-end (cierra el Anillo 0)

**Servicios:** se implementa `POST /stores/{id}/sales` completo:
validar producto contra catalog → descontar stock y registrar `StockMovement` →
si el stock queda bajo umbral, disparar `POST /replenishments`. web-inventory
muestra dashboard, detalle de sucursal (con acción de venta) y órdenes.

**Infra:** el ConfigMap/env de cada servicio apunta a los otros por DNS interno del
cluster; dashboar
~~~~~~

### ⏱️ 2026-09-12T19:28:24Z · Read rings section

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '300,420p' 07-super-inventory-lab-plan-maestro.md
~~~~~~

~~~~~~text
  cluster, se regeneran con `make up`. Cero fricción con StorageClass/PV/permisos.
- **Anillo 0.5 (opt-in):** `extraMounts` en kind + PersistentVolume hostPath para
  que los datos de Postgres sobrevivan al `kind delete`. Advertencia: hostPath +
  Postgres da fricción de permisos y no es para producción.

### 4.4 Semilla de datos

Sugerido: 3 sucursales, ~20 productos, 3-4 categorías, umbrales que permitan
disparar reabastecimientos con pocas ventas. Suficiente para que los dashboards
muestren algo sin ser pesado. En el Anillo 8 se amplía a meses de movimientos
sintéticos.

---

## 5. Definition of Done del Anillo 0 (= Oleada 2 cerrada)

- [ ] Los 4 servicios responden en sus health checks dentro de kind.
- [ ] `POST /stores/{id}/sales` ejecuta el flujo completo (catalog → inventory →
      replenish).
- [ ] El flujo se ve en Grafana y en Loki.
- [ ] `helm install/upgrade` con `values-local.yaml` deja todo arriba sin pasos
      manuales fuera del Makefile.
- [ ] Headlamp y k9s muestran todo sin errores de RBAC.
- [ ] `kind delete cluster` + `make up` reproduce todo desde cero.

Cuando esto esté en verde, recién se abre el primer anillo.

---

## 6. Anillos de aprendizaje (después del Anillo 0)

| Anillo | Qué añade | Concepto que enseña |
|---|---|---|
| 0.5 | Persistencia real (extraMounts + PV hostPath), opt-in | Volúmenes en kind, fricción de permisos |
| 1 | Servicio `reports` (Node/Express) + endpoint de export | Contraste Express/Fastify; datos para análisis |
| 2 | gR
~~~~~~

### ⏱️ 2026-09-12T19:29:06Z · Check sibling proposal and lab structure

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos
echo "=== complemento-docker README ==="; head -40 propuesta-complemento-docker/README.md 2>/dev/null || ls propuesta-complemento-docker
echo; echo "=== lab-docker: 00-instrucciones (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/00-instrucciones.md | head -25
echo; echo "=== 06-anillo-0 (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/06-anillo-0-refinamiento-y-hoja-de-ruta.md | head -25
~~~~~~

~~~~~~text
=== complemento-docker README ===
# 🐳 Propuesta: complemento Docker Legacy Node

Propuesta de material de apoyo para un problema muy concreto: **correr Node.js
antiguo (10–14) dentro de contenedores, en máquinas de desarrollo modernas** —
macOS Apple Silicon (arm64) y Windows 11 (x86_64). El eje es la fricción de
arquitectura y de libc que aparece cuando el runtime que necesitas nunca tuvo
binarios para el CPU que tienes.

> ⚠️ Borrador. Ver el [README del directorio de propuestas](../README.md) para
> entender qué implica ese estado.

## 🎯 Alcance

El material se organiza en dos bloques que comparten origen pero se leen por
separado.

### Bloque A — Node legacy en contenedores

Cubre la cadena completa de decisiones:

- **Fundamentos de libc:** qué es glibc, qué es musl, en qué se diferencian de
  verdad y por qué la distinción decide si un `npm install` funciona o no.
- **El catálogo de paquetes que explotan:** node-sass, phantomjs, bcrypt, sqlite3 y
  compañía — por qué fallan sobre musl, qué prebuilds existen y cuáles son las
  salidas viables para cada uno.
- **Estrategias de ejecución comparadas:** traducción de binarios x86_64 vs.
  emulación QEMU vs. compilar arm64 nativo, con las consecuencias de cada camino
  sobre velocidad, mantenimiento y vida útil.
- **Rendimiento medido:** por qué V8 sufre especialmente bajo emulación y qué
  órdenes de magnitud separan a cada opción.
- **Compilación casi bare-metal:** construir Node desde fuente en Lima (macOS) y
  WSL2 (Windo
~~~~~~

