# Validation Report

## Identificación
- Proyecto:
- Commit:
- Fecha UTC:
- Framework y versión:
- Fixture de referencia usado:

## Source snapshot
- package-lock.json SHA-256:
- working tree limpio: sí/no

## Toolchain
- Imagen y tag:
- Image ID:
- Plataforma:
- Debian:
- Node:
- npm:
- Node ABI (process.versions.modules):
- Python 2 / Python 3:
- GCC:

## Hipótesis inicial
- Node esperado:
- Evidencia que la sostiene:
- Riesgos identificados:

## Resultado

| Nivel | Etapa | Comando | Exit code | Resultado |
|---|---|---|---:|---|
| 2 | Install | npm ci | | |
| 3 | Tests | npm test | | |
| 3 | Lint | npm run lint | | |
| 4 | Build | npm run build | | |
| 5 | Run | npm start | | |
| 5 | HTTP | curl -sI localhost:PORT | | |
| 6 | Watch | edición de archivo | | |

## Veredicto
- Nivel alcanzado (1–7):
- Compatible para:
- NO compatible para:

## Lo que no se pudo resolver
- (qué, por qué, y qué haría falta)

## Reproducir
- (los comandos exactos, en orden)
