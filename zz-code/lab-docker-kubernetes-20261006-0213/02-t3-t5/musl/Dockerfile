# eclipse-temurin:25-jre
FROM eclipse-temurin@sha256:fcd7fd7b387f94bb2ac461478a7436ad8e349924c374ea8313919624dceae636 AS jre
# node:24.21.0-alpine
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1
COPY --from=jre /opt/java/openjdk /opt/java
