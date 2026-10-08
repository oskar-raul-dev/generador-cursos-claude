# El primer Dockerfile de La Rebotica: la Braqui tal como vino, en una sola etapa (Fase 01).
# La Fase 04 lo reescribe; hoy se trata de entender cada línea.

# node:24.21.0-alpine — la imagen base, fijada por su digest.
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1

# Todo lo que sigue pasa en /app dentro de la imagen.
WORKDIR /app

# Primero las dependencias: si el código cambia y ellas no, Docker reutiliza esta parte.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Después el código.
COPY dispatcher.js ./

# El puerto en el que escucha, si nadie dice otra cosa.
ENV PORT=8080
# Documentación para quien lea la imagen: no publica nada por sí solo.
EXPOSE 8080

# El proceso del contenedor. Se puede reemplazar al hacer docker run.
CMD ["node", "dispatcher.js"]
