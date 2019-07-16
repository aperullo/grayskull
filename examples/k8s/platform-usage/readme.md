# Platform Usage Example App
This is a sample Spring Boot application that demonstrates how to use the following platform services:
- Prometheus
- ELK
- Ceph

This app is built by Gradle and Dockerized using a Dockerfile.

## Building and Running

To build, run
```shell
./gradlew build
```

This will create a Docker image called `platform-usage`. You can re-tag the image, then upload it to Dockerhub.

```shell
> docker tag platform-usage <username>/platform-usage
> docker push <username>/platform-usage
The push refers to repository [docker.io/<username>/platform-usage]
ad2f87449c31: Preparing
ed824268a8fd: Preparing
714e1dd7c2e4: Preparing
344fb4b275b7: Preparing
bcf2f368fe23: Preparing
714e1dd7c2e4: Layer already exists
344fb4b275b7: Layer already exists
bcf2f368fe23: Layer already exists
ed824268a8fd: Layer already exists
ad2f87449c31: Pushed
latest: digest: sha256:09272d2a20cd7199f36bfdb82f96c37475816fbd51ef82330bb09cdd8f1ec373 size: 1370

```

The image used in `sample.yml` will need to be updated to be the docker image that was just pushed.
```yml
...
apiVersion: apps/v1
kind: Deployment
metadata:
    name: platform-usage
    labels:
      app: platform-usage
spec:
  selector:
    matchLabels:
      app: platform-usage
  template:
    metadata:
      labels:
        app: platform-usage
    spec:
      containers:
        - name: platform-usage
          image: <username>/platform-usage    # update image here
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /config
              name: config
          ports:
          - name: http
            containerPort: 8080
      volumes:
        - name: config
          configMap:
            name: spring-config
...
```

Then to run the application, run
```shell
> kubectl -n grayskull-logs apply -f sample.yml
configmap/spring-config created
deployment.apps/platform-usage created
service/platform-usage-s created
servicemonitor.monitoring.coreos.com/platform-usage created
ingress.extensions/platform-usage-ingress created
deployment.apps/redis-dplymnt created
service/redis-srvc created
persistentvolumeclaim/redis-pvc created
```

## Kubernetes Manifest

The parts of the Kubernetes manifest (`sample.yml`) that are used to get the app itself up and running are the `ConfigMap`, `Deployment`, and `Service` sections at the top of the file. The `Ingress` section is used to expose the app to external users. 

## Prometheus

The sample app exposes metrics using Spring Boot Actuator, then sends metrics to Prometheus using a CustomResourceDefinition (CRD) called `ServiceMonitor`. When the Prometheus operator is deployed on the platform, it creates 4 CRDS: `Prometheus`, `ServiceMonitor`, `PrometheusRule`, and `Alertmanager`.

To expose Prometheus metrics using Spring Boot Actuator, make sure the following lines are in `build.gradle` and `application.properties`.

`build.gradle`:
```gradle
dependencies {
  compile("org.springframework.boot:spring-boot-starter-actuator")
  compile("io.micrometer:micrometer-registry-prometheus")
}
```

`application.properties`:
```ini
management.endpoints.web.exposure.include=prometheus
```

This will create a Prometheus metric endpoint. To see the endpoint, run the app and go to https://sample.gsp.test/actuator/prometheus.

To send the metrics to Prometheus, you need to create a `ServiceMonitor` for your service.

```yml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: platform-usage
  labels:
    release: gsp-prometheus			# important
spec:
  selector:
    matchLabels:
      app: platform-usage 			# must match the label of the app service
  endpoints:
    - port: http
      interval: 5s
      path: '/actuator/prometheus'		# path to metrics
```
Make sure that the metadata labels include `release: gsp-prometheus` because that is the label that Prometheus will search for to find services it needs to monitor. Also be careful to include the label of your app in `matchLabels` because that is how the ServiceMonitor will find your service. You can specify whatever endpoints you want. In this case, we only have one exposed port named `http`, so that is the only port we specify.

## ELK

For logging, we use `logstash-logback-encoder` to send logs to Logstash, which then sends the logs to Elasticsearch, which Kibana then picks up on automatically.

To use `logstash-logback-encoder`, make sure the following dependencies are in `build.gradle`.

```gradle
dependencies {
  compile("net.logstash.logback:logstash-logback-encoder:5.3")
  compile("ch.qos.logback:logback-classic:1.2.3")
}
```

To configure the loggers, you need a `logback-spring.xml` file. In that file, create an appender for every location you want to send logs. In our example, we have 3 appenders, one for sending logs to stdout, one for saving logs in files, and one for sending logs to Logstash.

If you just want to send logs to Logstash, make sure the following is in `logback-spring.xml`:

```xml
<appender name="STASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>${LOGSTASH_HOST}</destination>
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>{"app_name":"logging-sample"}</customFields>
    </encoder>
</appender>

<logger name="${LOGGER_NAME}" level="${LOGGER_LEVEL:-DEBUG}" additivity="false">
    <appender-ref ref="STASH" />
</logger>
```

The logger name should be the name of the package of the logger(s). In this case, the package name is `acc` and is set in `application.properties`.

The Logstash Logback appender needs to know the location of the Logstash host in order to send logs to it. In our app, we set the location in `application.properties` and read it in to `logback-spring.xml`. The location of the Logstash host in the Kubernetes cluster is `gsp-logstash.grayskull-logs:1514`. However, if the application is in the same namespace as the Logstash host, the namespace can be omitted to become `gsp-logstash:1514`.

You can read properties from `application.properties` into `logback-spring.xml` by using the `springProperty` tag.

`application.properties`:
```ini
logstash.host=gsp-logstash:1514
logger.name=acc
```
`logback-spring.xml`:

```xml
<springProperty name="LOGSTASH_HOST" source="logstash.host"/>
<springProperty name="LOGGER_NAME" source="logger.name"/>
```

The Logstash service that is used on the platform is configured to name logs based on a `customField` called `app_name`, so be sure to add that custom field to any logger that sends logs to Logstash. This way, logs will be indexed with whatever your `app_name` is set as. For the sample app, the logs are prefixed with `logging-sample-`. If no `app_name` is set, the logs will default to being prefixed with `logstash-`.

## Rook Ceph

To use the Rook Ceph storage, we use Redis' Docker image. Redis needs a `Deployment`, `Service`, and `PersistentVolumeClaim`.

`sample.yml`:
```yml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: redis-dplymnt
    labels:
      app: redis
spec:
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis
          volumeMounts:
          - mountPath: /data
            name: redis-store		# name of volume declared below
          ports:
          - containerPort: 6379
      volumes:
        - name: redis-store
          persistentVolumeClaim:
            claimName: redis-pvc	# name of PersistentVolumeClaim

---
apiVersion: v1
kind: Service
metadata:
  name: redis-srvc
  labels:
    app: redis
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  labels:
    app: redis
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 30Mi			# size of storage needed
```

In `application.properties`, we need to set `spring.redis.host` to the name of the Redis service we created.

```ini
spring.redis.host=redis-srvc
```
