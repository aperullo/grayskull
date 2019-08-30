FROM openjdk:8-jdk-alpine
RUN apk add --no-cache bash
COPY ./libs/app-1.0-SNAPSHOT.jar /app
EXPOSE 8080
ENTRYPOINT ["/app"]
