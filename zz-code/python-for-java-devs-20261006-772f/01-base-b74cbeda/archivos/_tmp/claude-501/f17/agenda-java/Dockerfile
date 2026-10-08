# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/agenda-0.17.0.jar app.jar
EXPOSE 8124
ENTRYPOINT ["java", "-jar", "app.jar"]
