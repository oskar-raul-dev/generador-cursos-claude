# Dockerfile definitivo de storefront (Fase 04): Vite compila a archivos estáticos, y nginx los sirve.
# El frontend no es un servicio: es una carpeta que alguien sirve.

# ── Etapa de build: Node, solo para compilar ──
# node:24.21.0-alpine
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Desde G2 no se hornea nada de configuración: el JavaScript compilado es el mismo para cualquier ambiente.
RUN npm run build

# ── Etapa final: nginx sin privilegios (usuario 101, puerto 8080) y la carpeta dist/ ──
# nginxinc/nginx-unprivileged:1.30.5-alpine
FROM nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
# dist/ trae public/health/live y public/health/ready: la salud son dos archivos.
COPY --from=build /app/dist /usr/share/nginx/html
# G2: la configuración llega al arrancar. El entrypoint de la imagen convierte la plantilla en
# conf.d/default.conf con estas variables; el despliegue las cambia sin reconstruir.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
ENV API_BASE_URL=http://api.localhost:8080 \
    BRAND_NAME="Droguerías La Vecina"
EXPOSE 8080
# El CMD de la base, ["nginx", "-g", "daemon off;"], y su STOPSIGNAL SIGQUIT: nginx cierra con cortesía.
