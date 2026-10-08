# Dockerfile definitivo de replenish (Fase 04): compila TypeScript en una etapa, instala solo las
# dependencias de producción en otra, y corre con las dos.

# ── Etapa de build: todas las dependencias, incluidas las de desarrollo (Nest CLI, TypeScript) ──
# node:24.21.0-alpine
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ── Etapa de dependencias: solo las de producción ──
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# ── Etapa final: Node, las dependencias de producción y el JavaScript compilado ──
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
# package.json viaja porque declara "type": "module", que Node necesita para cargar dist/.
COPY package.json ./
COPY --from=build /app/dist ./dist
# La carpeta de los datos (G1), a nombre del usuario que corre: un volumen que se monte aquí hereda el dueño.
RUN mkdir -p /var/lib/replenish && chown node:node /var/lib/replenish
# El usuario sin privilegios que trae la imagen base (uid 1000).
USER node
EXPOSE 8080
# G10 (Fase 23): OpenTelemetry sin tocar el código: el registro automático se carga antes que la aplicación y
# lee las variables OTEL_*. Con OTEL_SDK_DISABLED=true (el chart lo pone sin trazas), no exporta nada.
CMD ["node", "--import", "@opentelemetry/auto-instrumentations-node/register", "dist/main.js"]
