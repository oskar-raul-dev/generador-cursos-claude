La prueba con `replenish`. El Dockerfile del curso copia `package.json` y `package-lock.json`, corre
`npm ci`, y después copia el código. Una variante que copia todo primero (`COPY . .` antes de `npm
ci`) es más corta y "hace lo mismo". Después de cambiar una línea de
`src/replenishment-orders.controller.ts`, tres builds con caché de cada uno:

| Dockerfile de `replenish` | Build con caché, tres corridas |
|---|---|
| dependencias primero (el del curso) | 2,1 – 2,4 s (B-04) |
| `COPY . .` primero | 10,16 – 11,44 s |

Cuatro a cinco veces más, en cada cambio de código, porque cada cambio vuelve a instalar las
dependencias. En `pricing` el orden no salva nada, y la medición lo dice sin piedad: su build con
caché (5,6 s) cuesta casi lo mismo que el frío (5,8 s), porque `pricing` no tiene dependencias que
proteger y lo que tarda es el `go build` mismo, que empieza de cero cada vez. Eso se arregla con
otra herramienta, una caché de compilación montada en el build, y es el ejercicio 15.
