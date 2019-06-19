# Docker stack to Kubernetes

This document represents instructions on how to adapt your Docker-stack file to an equivalent Kubernetes manifest file.

Both are organized very similiarly and both use yaml for their mark up. A K8s manifest looks more complicated at first glance than a docker-stack file, there are a few reasons for this:

1. K8s is more powerful and flexible than docker swarm; this additional flexibility requires a little more specificity. 
2. K8s manifests are more verbose, which is directly connected to how seperate each part of a stack is.

Lets look at a docker-stack file, break it down by section, then look at the equivalent of each in K8s. From there we will work to translate our stack file to a manifest.

`docker-stack.yaml`
```
version: '3.7'
services:
    sample-app:
        image: sample-app:latest
        command: ["--use-external-db", "--log-dir=/logs"]
        ports: 
          - published: 8080
            target: 8080
        configs:
          - source: my_config
            target: /config/settings.ini
        networks:
          - db-net
        environment:
          DATABASE_HOST: "${DB_HOST}"
        volumes:
          - log-volume:/logs
        

    sample-db:
        image: redis:latest
        command: ["redis-server", "--appendonly", "yes"]
        networks:
          - db-net
        volumes:
          - redis-data:/data
    
configs:
    spring_config:
        file: ../configs/settings.ini

networks:
    db-net:

volumes:
    log-volume:
    redis-data:
```

### Version
In docker this represents the syntax version for a file. 

`docker-stack`
```
version: '3.7'
```

In k8s it represents the version of the k8s api.
`k8s-manifest`
```
apiVersion: apps/v1
```

### Multiple services
In docker stack files, we put the resources we want to run all under the same `service` level.

```
services:
    sample-app:
    ...
    sample-db:
    ...
```
In k8s, each resource gets its own declaration, either in seperate manifest files, or seperated by `---`. So the next step to transforming this file is to divide up the `services` section

```
apiVersion: '3.7'
services:
    sample-app:
        ...
    sample-db:
        ...
```
Becomes
```
apiVersion: apps/v1
kind: Deployment
metadata:
    name: sample-app
    ...
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: sample-db
    ...
```

We're going to stop showing the sample-db portion while we convert the rest of the document.

### Container

This is the hardest to grasp difference between docker and k8s. In docker-stack files, you specify a service, and tell it what image to use. It automatically creates containers with that image, and also automatically attaches them to the service that owns those containers.

K8s is more manual. Instead you define a container, tell it what image to use, and give containers of that type a label. Then you tell the deployment (the K8s equivalent of a service) the name its containers will have, and the deployment will go find them and watch over them.

```
version: '3.7'
services:
    sample-app:
        image: sample-app:latest
```
Becomes
```
apiVersion: apps/v1                     
kind: Deployment                        
metadata:                                # The name of the deployment
    name: sample-app
spec:                                    # The specification for this deployment is
    selector:                            #
        matchLabels:                     # any pods with a label matching
            app: my-app                  # a label called "app" with value "my-app".

    template:                            # The PodTemplate for these pods is
        metadata:
            labels:
                app: my-app              # a label called "app" with value "my-app".
        spec:                            # The specification for these pods is
            containers:                  # a container 
              - name: my-app             # called "my-app"
                image: sample-app:latest # running the latest version of the "sample-app" image.
```

This change is the most removed from what we are used to in docker stack.

### Ports

By default docker stack exposes containers to the outside by way of ports. This can still be done with k8s, it requires short-circuiting k8s more robust service traffic routing mechanism. 

In docker:
```
version: '3.7'
services:
    sample-app:
        ...
        ports: 
          - published: 8080
            target: 8080
```

In k8s, a deployment of containers is exposed through a *service*. Yes service means something different in k8s than in docker. Docker doesn't have an equivalent concept to k8s services. 

A service in k8s is a named resource consisting of local port (for example 3306) that the proxy listens on, and
the selector that determines which pods will answer requests. Their entire purpose is to route traffic from a port exposed to the outside, to linked pods/containers.

```
---
apiVersion: v1
kind: Service
metadata:
    name: sample-app
spec:
    type: NodePort
    selector:
        app: my-app
    ports:
      - port: 8080
        name: http
```

For advanced exposing of your app, see ingress(TODO: add an ingress section). 

### Configs

There are generally 3 ways to configure your containers. 
1. Commands
2. Environment variables
3. Configuration files

#### Commands

In docker:
```
...
services:
    sample-app:
        image: sample-app:latest
        command: ["--use-external-db", "--log-dir=/logs"]
...
```

In K8s:

```
...                    
kind: Deployment                        
metadata:                               
    name: sample-app
spec: 
    ...
    template:
        ...
        spec:
            containers
              - name: my-app
                image: sample-app:latest
                # for the command to start
                command: ["java -jar app.jar"]
                # for the arguments
                args: ["--use-external-db", "--log-dir=/logs"]
...
```

#### Environment Variables

In docker: 

```
...
version: '3.7'
services:
    sample-app:
        image: sample-app:latest
        ...
        environment:
          DATABASE_HOST: "${DB_HOST}"
...
```

In K8s this is handled by [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap). ConfigMaps are simple key-value stores.

```
...
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  DATABASE_HOST: "${SAMPLE-DB_SERVICE_HOST}"
---
```

This can be used inside the container in a number of ways.

To load the entire config map in environment variables use `envFrom`

```
kind: Deployment                        
metadata:                               
    name: sample-config
spec: 
    ...
    template:
        ...
        spec:
            containers
              - name: my-app
                image: sample-app:latest
                envFrom:
                - configMapRef:
                    name: my-config
```

To load only a few values as environment variables use `env`

```
kind: Deployment                        
metadata:                               
    name: sample-app
spec: 
    ...
    template:
        ...
        spec:
            containers
              - name: my-app
                image: sample-app:latest
                env:
                  - name: DATABASE_HOST
                    valueFrom:
                        configMapKeyRef:
                            name: sample-config
                            key: DATABASE_HOST
```

#### Config files

In docker: 

```
...
services:
    sample-app:
        image: sample-app:latest
        configs:
          - source: my_config
            target: /config/settings.ini
        ...
    
configs:
    spring_config:
        file: ../configs/settings.ini
```

In K8s configMaps can also be used for this purpose. We put the name of the file as the key and the contents of the file as the value. You can set up the config map to load files into cetain paths in the container, just like in docker.

```
```
...
---
apiVersion: v1
kind: ConfigMap
metadata:
    name: my-config
  data:
    settings.ini: |
        spring.application.name=ourdemoapp

---

kind: Deployment                        
metadata:                               
    name: sample-app
spec: 
    ...
    template:
        ...
        spec:
            containers
              - name: my-app
                image: sample-app:latest
                # where to put the volume in the container
                volumeMounts:
                  - name: config-volume
                    mountPath: /config
            volumes:
              - name: config-volume
                configMap:
                  # which config map to use.
                  name: my-config
```

See [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-volume) for more on config maps as files/volumes.

### Volumes

In docker:

```
...
version: '3.7'
services:
    sample-app:
        image: sample-app:latest
        ...
        volumes:
          - log-volume:/logs
```

In K8s, volumes are much more extensive. There are many different types, but for persistent storage, we will use a `PersistentVolumeClaim`. Rather than declaring volumes, in K8s you declare volume claim, which the system will provision if that space is available.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-volume-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---

kind: Deployment                        
metadata:                               
    name: sample-app
spec: 
    ...
    template:
        ...
        spec:
            containers
                ...
                # where to put the volume in the container
                volumeMounts:
                  - name: my-volume
                    mountPath: /logs
            # provision the volume
            volumes:
              - name: my-volume
                persistentVolumeClaim:
                  claimName: my-app-volume-claim

      
```

### Networks



TODO: Also write an equivalent of the final dockerization-stack as a manifest to prove it works. 

