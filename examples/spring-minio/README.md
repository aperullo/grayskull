# Spring Boot Minio Sample

Sample Spring Boot application that uses the Minio Java Client API to interact with a Minio server.

### Files of Note
* `AppGradleController.java` Contains the application logic
* `build.gradle` 
* `Dockerfile`
* `docker-compose.yml`

### Usage

Build the project.
```
./gradlew build docker
```

Deploy.
```
docker-compose up
```

Alternatively, to deploy in a swarm:
```
docker stack deploy -c docker-compose.yml
```

Once deployed, **GET** and **POST** requests can be sent to the `objects` endpoint on port `8181`. 
`http://hostAddress:8181/objects`

The client is preconfigured with the [Minio test server](https://play.minio.io:9000/minio/). To use a different server change the address and credentials in the `Properties.java` file.

A **GET** request will return everything stored within a bucket.
`curl http://hostAddress:8181/objects`

**POST** can be used to upload files. The request must include the file as a form attachment.
`curl -F 'file=@path/to/file' http://hostAddress:8181/objects`

These operations can also be performed using something like Postman.
