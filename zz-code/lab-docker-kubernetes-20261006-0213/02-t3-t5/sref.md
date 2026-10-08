**Documentación oficial** (sin versión fija salvo donde se indica)

- Docker, *Multi-stage builds*: https://docs.docker.com/build/building/multi-stage/
- Docker, *Optimize cache usage in builds*: https://docs.docker.com/build/cache/optimize/ — el orden
  de las instrucciones y las cachés de montaje del ejercicio 15.
- Docker, *Build context* y `.dockerignore`: https://docs.docker.com/build/concepts/context/
- Distroless: https://github.com/GoogleContainerTools/distroless — qué trae cada variante y por qué
  `nonroot`.
- Spring Boot, *Efficient container images* (jar por capas y `jarmode=tools`):
  https://docs.spring.io/spring-boot/reference/packaging/container-images/efficient-images.html
- La imagen oficial de PHP, la sección de FPM y su configuración: https://hub.docker.com/_/php
- nginx sin privilegios: https://github.com/nginx/docker-nginx-unprivileged
- Eclipse Temurin: https://adoptium.net/temurin/ — la distribución de OpenJDK de la imagen de
  `inventory`.

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición (2022), el capítulo de imágenes de contenedor: capas, multi-stage y por qué el tamaño
  importa en un cluster.

**Orden de lectura sugerido:** antes, la página de multi-stage (cinco minutos); durante, la de caché,
con el Dockerfile de `inventory` delante; después, la de Spring Boot sobre imágenes eficientes, que
es la mejor explicación del jar por capas.

> ⚠️ Las URL y los contenidos cambian, y las de Docker no fijan versión.
