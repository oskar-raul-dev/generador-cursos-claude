**El `.dockerignore` es la otra mitad de la caché.** Lo que entra al contexto del build entra a la
comparación de `COPY . .`, y un archivo que no hace falta invalida la capa igual que uno que sí. Los
`.dockerignore` del curso excluyen el `Dockerfile` y el `CLAUDE.md` de cada servicio por eso: se
editan a menudo y no los necesita ninguna etapa. La prueba, otra vez con `replenish`, agregando una
línea al `CLAUDE.md` y construyendo:

| `.dockerignore` de `replenish` | Build después de tocar `CLAUDE.md` (tres corridas) |
|---|---|
| con `CLAUDE.md` excluido | 0,27 – 0,40 s: todo sale de la caché |
| sin esa línea | 2,07 – 2,24 s: se recompila TypeScript |

Y el `.dockerignore` de `catalog` excluye `.env`: el archivo de configuración local, con secretos, que
el portal de 2019 sí hornea en su imagen ([a16](a16-el-patrimonio.md)). Lo que no entra al contexto
no puede quedar en ninguna capa.
