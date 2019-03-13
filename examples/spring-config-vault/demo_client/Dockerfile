from gradle:jdk8-alpine as builder

#Get dependencies
COPY ./demo_client /demo_client
#Gradle user doesnt own the files so can't operate on them.
USER root
RUN chown -R gradle /demo_client
USER gradle

RUN pwd && cd /demo_client && pwd && ./gradlew build --stacktrace -x test

# Move built files to result image
FROM openjdk:8-jre-alpine

COPY --from=builder /demo_client/build/libs/demo-0.0.1-SNAPSHOT.jar /app/
WORKDIR /app
RUN mv demo-0.0.1-SNAPSHOT.jar app.jar

#run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
