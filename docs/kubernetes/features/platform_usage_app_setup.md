# Platform Usage Example App Setup
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

Then to run the application on the Grayskull platform, run
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

Note: The sample app uses a secret that is created during platform deployment and exists within the `grayskull-logs` namespace, which is why you must deploy it in the same namespace. If your `kubectl` is not set up for remote administration, look [here](https://github.com/connexta/grayskull/blob/kubernetes/kubernetes/k8s_deploy_guide.md#set-up-remote-administration) for instructions.

## Basic App Manifest

The parts of the Kubernetes manifest (`sample.yml`) that are used to get the app itself up and running are the `ConfigMap`, `Deployment`, and `Service` sections at the top of the file. 

The `application.properties` section in `ConfigMap` override values that are set in `application.properties`.

```yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: spring-config
data:
  application.properties: |
    spring.application.name=avocados-from-mexico    # overrides value in application.properties

---
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
          image: rfding/platform-usage
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

---
apiVersion: v1
kind: Service
metadata:
  name: platform-usage-s
  labels:
    app: platform-usage
spec:
  selector:
    app: platform-usage
  ports:
    - name: http
      port: 8080
```

We use an `Ingress` to expose the app to external users. The sample app uses a secret that has already been created (`elk-gsp-tls`), which is why it has to be deployed into the `grayskull-logs` namespace. The `Ingress` objects are picked up by the Ingress controller, which lives in the `grayskull-ingress` namespace.

```yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: platform-usage-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/server-snippet: |
      proxy_ssl_verify off;
spec:
  tls:
    - hosts:
        - sample.gsp.test
      secretName: elk-gsp-tls
  rules:
    - host: sample.gsp.test
      http:
        paths:
          - path: /
            backend:
              serviceName: platform-usage-s   # app service name
              servicePort: http               # app service port name
```
