# Node del corpus: la LTS vigente, que ejecuta TypeScript sin compilar (quita los tipos).
# Versiones verificadas: ver `prompts/dominio-entorno-y-datos-fijos.md` §4.6.
FROM node:24.21.0
# `pg` se instala aparte y se enlaza en /node_modules: la resolucion de modulos ESM
# sube por los directorios padres de /codigo hasta encontrarlo. NODE_PATH no sirve
# con `import`, y `npm install` falla si se ejecuta en la raiz del sistema.
WORKDIR /opt/npm
RUN npm install --no-save pg@8.23.0 pg-cursor@2.22.0 kysely@0.29.6 drizzle-orm@0.45.3 \
    redis@6.2.1 mongodb@7.6.0 pg-copy-streams@7.0.0 testcontainers@12.1.0 \
    @testcontainers/postgresql@12.1.0 && ln -s /opt/npm/node_modules /node_modules
WORKDIR /codigo
