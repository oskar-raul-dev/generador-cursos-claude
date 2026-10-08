# chaos

El generador de caos del laboratorio (Fase 22). No es un servicio de La Vecina: es una herramienta del curso, que se
pone entre `inventory` y un vecino y le hace al tráfico lo que se le pida.

## Stack

- Go (la versión de `a01`), solo biblioteca estándar: `main.go` y nada más. Un proxy inverso hacia `CHAOS_UPSTREAM`.
- Imagen: `lab/chaos:f22`, con el molde de `pricing` (distroless, 65532).

## Cómo se usa

```bash
task chaos:on                                   # construye, carga y lo pone entre inventory y catalog
task chaos:set -- latencyMs=5000 latencyPercent=100
task chaos:set -- perfil sogamoso-con-lluvia    # giron-un-martes · sogamoso-con-lluvia · bogota-en-quincena
task chaos:set -- show
task chaos:off
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes. Log en JSON, como G7.
- Las fallas, en este orden por petición: colgarse, fallar, demorar, romper. `GET /chaos` cuenta todo.
- No habla TLS: con `pricing` (mTLS desde la Fase 19) no se usa.
