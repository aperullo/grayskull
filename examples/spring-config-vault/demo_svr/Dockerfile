from gradle:jdk8-alpine as builder

#Get dependencies
COPY ./demo_svr /demo_svr
#Gradle user doesnt own the files so can't operate on them.
USER root
RUN chown -R gradle /demo_svr
USER gradle
#RUN chmod -R 755 /demo_svr

RUN pwd && cd /demo_svr && pwd && ./gradlew build --stacktrace

# Move built files to result image
FROM openjdk:8-jre-alpine

COPY --from=builder /demo_svr/build/libs/demo-0.0.1-SNAPSHOT.jar /app/
WORKDIR /app
RUN mv demo-0.0.1-SNAPSHOT.jar app.jar

#expose flask's default port
EXPOSE 8888

#run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
