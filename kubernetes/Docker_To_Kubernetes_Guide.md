# Docker to Kubernetes Guide

This guide will attempt to describe the constructs Docker and Kubernetes use to represent similar functionality and propose a general process one can use to manually convert a Docker stack file to a Kubernetes manifest file. It will also explore some techniques one can use to verify individual resources are working as intended.

## Basics

Both Docker and Kubernetes support imperative (using the command line) and declarative (using stack and manifest files) approaches to declaring resources. It can be useful to create a resource imperatively (using `$ docker <resource_type> create ...` or `$ kubectl create <resource_type> ...`) using additional flags for desired fields, then examining it closer (using `$ docker inspect` or `$ kubectl describe`) to get a better sense of how it would have been created declaratively. This will be the strategy employed in many parts of this tutorial, and it's recommended you play around with it yourself when you have any doubts about what may be going on. In practice, however, you want to use the declarative approach whenever possible.

For many of the examples below, we will use a custom image based off `alpine`, a lightweight docker image that supports some UNIX utilities useful for exploring our environments. If you do not have it, you can pull it using:

```sh
 $ docker image pull alpine
```

To create our custom image, create a file named `Dockerfile` with the contents:

```
FROM alpine:latest
CMD exec sh -c "sleep 999999"
```

The `sleep 999999` will run when a container is created from the image we are about to create, and will ensure it is not terminated immediately. We can then build our image from the same directory as our `Dockerfile`, which we will name `sleep`, with:

```sh
$ docker image build -t sleep .
```

### Docker

First, we will experiment with the most basic resource in Docker - a container. We will start by creating one that can be destroyed permanently, and then explore what other options we have at our disposal. The easiest way to initialize a container is imperatively with `$ docker run`, so we will start there:

```sh
$ docker run -d --name cli-con sleep
```

will create a container from the image we just created. Note the `-d` flag, indicating the container should run in a detached state in the background, which will avoid freezing the terminal the container is deployed from while it's running.

We will also create another resource - a service. A service is similar to a container in that an image is required for it to run, but it can configure other properties as well, such as how many copies of a container it should run. It can also ensure that containers are restarted when they fail.  To see this in action, we will use a different command:

```sh
$ docker service create --name cli-svc sleep
```

We can now list the containers that should be running:

```sh
$ docker ps
```

With the result:

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
7f5447ec0042        sleep:latest        "/bin/sh -c 'exec sh…"   9 seconds ago       Up 7 seconds                            cli-svc.1.ydr1fxbhzjwneoiysaggi89vs
26aa1980ea5c        sleep               "/bin/sh -c 'exec sh…"   31 seconds ago      Up 30 seconds                           cli-con
```

From here, we will be able to discern the most significant difference between the two. If we kill our isolated container using its name:

```sh
$ docker kill cli-con
```

Notice that it has disappeared when we list our running containers:

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
7f5447ec0042        sleep:latest        "/bin/sh -c 'exec sh…"   43 seconds ago      Up 41 seconds                           cli-svc.1.ydr1fxbhzjwneoiysaggi89vs
```

But if we try to kill the pod backed by a service:

```sh
$ docker kill 7f5447ec0042
```

It will populated by a new one (note the change in container ID):

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
c6175abf5ec9        sleep:latest        "/bin/sh -c 'exec sh…"   6 seconds ago       Up 1 second                             cli-svc.1.yv5nfqbrqif9xm9a5ivgsbe6z
```

Now let's take a look at how this service created imperatively compares to one created declaratively through a stack file. Create a stack file `docker-stack.yml` with the following contents:

```yml
version: "3.7"
services:
  yml:
    image: sleep
```

It may be useful to consult the Docker [compose file reference](https://docs.docker.com/compose/compose-file/) if the structure here isn't immediately clear. It contains a sizeable example and information on commonly used configuration keys, including descriptions and code fragments. It also clarifies what keys are supported when deploying in stack mode, which we are. But to summarize what's above, we are creating a service with the name `yml` and the same image we used to create a container earlier.

Once we have created a file docker-stack.yml with those contents, we can deploy with:

```sh
$ docker stack deploy -c docker-stack.yml stack
```

We can see both services with:

```sh
$ docker service ls
```

With the result:

```
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
6hdq52vjii15        cli-svc             replicated          1/1                 sleep:latest        
j9qjti9uvae7        stack_yml           replicated          1/1                 sleep:latest   
```

Note the name of the stack service is prepended with the name we gave to the stack when we deployed it. We can test our new service by deleting its managed container and checking if it restored. If we're interested in comparing our services more directly, we can make use of `docker inspect`:

```sh
$ docker inspect cli-svc
$ docker inspect stack_yml
```

Although many properties will have different values, the properties themselves will be similar, giving us confidence that our stack file is creating resources in the same way Docker would be on its own.

### Kubernetes

Now we will look at the most basic resource in Kubernetes - a pod. Many of the steps taken in the Docker section can be taken in a similar way in Kubernetes. But first, we will have to make sure Kubernetes can use the local image we created earlier. Since the Docker daemon we used earlier is distinct from that within Minikube itself, which we will be using to run our cluster, we will have to recreate our image there. We can switch over to the Minikube Docker daemon with:

```sh
$ eval (minikube docker-env)
```

Change your directory to that containing the `Dockerfile` you created earlier and build the image again with:

```sh
$ docker image build -t sleep .
```

We can check that Minikube can now see the image by:

```sh
$ minikube ssh
...
$ docker images
```

And the result should be:

```
REPOSITORY                                TAG                 IMAGE ID            CREATED             SIZE
sleep                                     latest              0dbf79fcfb4f        8 seconds ago       5.58MB
...
```

Now we can start creating pods:

```sh
$ kubectl run cli-pod --image=sleep --generator=run-pod/v1 --image-pull-policy="Never"
```

Where the `--generator` value `run-pod/v1` indicates no other resources should be created alongside the pod, and the `--image-pull-policy` value `"Never"` indicates the local image `sleep` should be used. Listing this newly created pod:

```sh
$ kubectl get pods
```

Should return:

```
NAME       READY   STATUS    RESTARTS   AGE
cli-pod    1/1     Running   0          4s
```

We can delete our pod with:

```sh
$ kubectl delete pod cli-pod
```

A deployment is how Kubernetes manages a group of pods. Let's try creating one with the same image:

```sh
$ kubectl create deployment cli-dep --image=sleep
```

If we check the status of our deployment and pod:

```sh
$ kubectl get pods,deployments
```

We should see something like the following:

```
NAME                       READY   STATUS         RESTARTS   AGE
pod/cli-dep-5879597c89-g6rbt   0/1     ErrImagePull   0          73s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cli-dep   0/1     1            0           73s
```

Our pod isn't able to pull the same image as before. Let use `edit` on our deployment to take a closer look (which will also give us the opportunity to see our first Kubernetes manifest):

```sh
$ kubectl edit deployment cli-dep
```

If we look closely at the `.spec.template.spec.containers.imagePullPolicy` field, we will see it has the value `Always`. On comparison with `image-pull-policy` flag we used to run the pod we created earlier, we can see they are different. Let's change the value in our deployment to `Never` as well. On closing the editor, changes to our deployment will be applied immediately. If we check the status of our deployment and pod again, they should now be up and running.

```
NAME                       READY   STATUS    RESTARTS   AGE
pod/cli-dep-5b4b7b4dbd-mkr4s   1/1     Running   0          24s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cli-dep   1/1     1            1           4m29s
```

Now let's see what happens when we try to remove this pod:

```sh
$ kubectl delete pod cli-dep-5b4b7b4dbd-mkr4s
```

After potentially waiting a while, let's check our pods:

```sh
$ kubectl get pods
```
```
NAME                   READY   STATUS    RESTARTS   AGE
cli-dep-5b4b7b4dbd-8pnwt   1/1     Running   0          50s
```

Note how the pod name is now different. This behavior is analogous to that of killing containers backed by a service in Docker.

For any resource in Kubernetes, it's possible to generate its manifest file. For example, if we wanted to look at the deployment we just generated:

```sh
$ kubectl get deployment cli-dep -o yaml
```
We would see all the properties we would need to create it from scratch. However, there is cluster-specific information here that is not particularly relevant to us at the moment. For that reason we will start with a simpler deployment. Create a file `yml-dep.yml` with the following contents:

```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: yml-dep
spec:
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      name: yml-pod
      labels:
        app: sleep
    spec:
      containers:
      - name: yml-con
        image: sleep
        imagePullPolicy: Never
```

Note the different `name` fields: `.metadata.name`. `.spec.template.metadata.name`, and `.spec.template.spec.containers.name`, which define the names of the deployment, pods created by the deployment, and containers within each pod, respectively. Generally, everything after `.spec` and before `.spec.template` is part of the deployment definition, everything after `.spec.template` and before `.spec.template.spec` is part of a pod definition, and everything after `.spec.template.spec` is part of a container definition. Finally, `.spec.selector.matchLabels` will try to match any pods with those labels. In this case, pods with those labels are defined at `.spec.template.metadata.labels`.

For more information on any property, you can use `kubectl explain <resource_type>.<path_to_property>`. For example, `kubectl explain deployment.spec.selector.matchLabels` will return details on the `matchLabels` property.

We can then create a deployment based on that file with:

```sh
$ kubectl apply -f yml-dep.yml
```

And compare our resources with:

```sh
$ kubectl describe deployment cli-dep
$ kubectl describe deployment yml-dep
```

## Volumes

### Docker

Let's set up a working example to test our stack file against.

First, we'll create a volume:

```sh
$ docker volume create cli-vol
```

Now we'll create a service that will mount the volume under `/vol`:

```sh
$ docker service create --name cli-svc --mount source=cli-vol,target=/vol sleep
```

Let's check if the service and its container have been created, and if the volume has been mounted:

```sh
$ docker service ls
```
```
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
t8e9rkgqbqoa        cli-svc             replicated          1/1                 sleep:latest
```
```sh
$ docker ps
```
```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
233f5f0a5a49        sleep:latest        "/bin/sh -c 'exec sh…"   15 seconds ago      Up 14 seconds                           cli-svc.1.iegqht9bggjzgvucpdqt5yuqj
```
```sh
$ docker exec -it 233f5f0a5a49 sh
```
```
/ # ls
bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var    vol
/ # cd vol
/vol # ls
```

It has. Let's make some changes, kill the container, and see if they are persisted:

```
/vol # touch test
```
```sh
$ docker kill 233f5f0a5a49
$ docker ps
```
```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
1c2f7733540a        sleep:latest        "/bin/sh -c 'exec sh…"   7 seconds ago       Up 3 seconds                            cli-svc.1.blrn2cf8vrswag4nkz0ziegje
```
```sh
$ docker exec -it 1c2f7733540a sh
```
```
/ # cd vol
/vol # ls
test
```

They are. Note how `CONTAINER ID` changed. Now let's change our stack file to look like the following:

```yml
version: "3.7"
services:
  yml:
    image: sleep
    volumes:
    - yml-vol:/vol

volumes:
  yml-vol:
```

We can then deploy this using:

```sh
$ docker stack deploy -c docker-stack.yml stack
```

We should see a new container has been created as part of the service, as well as a new volume, prefixed with the name we just chose to deploy our stack under i.e. `stack_yml`. You should verify that these resources work similarly to those used in the earlier steps. But how can we be sure they are the same?

One way is to take advantage of `docker inspect` again. For instance, if we compare volumes with `docker volume inspect cli-vol` and `docker volume inspect stack_yml-vol`, we can see that some fields, which we would expect to be different, such as `Name` and `Labels`, are, while others that control the underlying functionality, such as `Driver` and `Scope`, are not. Additionally, comparing services with `docker service inspect cli-svc` and  `docker service inspect stack_yml`, we find that the volumes are specified to be mounted to containers under the same field, `Spec.TaskTemplate.ContainerSpec.Mounts`, and the entries themselves look similar. Finally, comparing containers, we can see similarities under the `Mounts` field. These comparisons should give us confidence that we are creating our stack file properly.

### Kubernetes

There are multiple ways to mount volumes in Kubernetes, including mounting directly on a pod or a node. A pod-level volume may be useful if containers need to share resources, such as logs, and a node-level volume if pods need to access resources on the node itself. However, both these options have the drawback that they are lifecycle dependent. In particular, if a volume is mounted on a pod and the pod dies, none of its containers will be able to see its contents once it is restarted. Likewise, for pods on a node if a pod is rescheduled. These are not the volumes you should be using if you are accustomed to those in Docker.  The only type you will likely need is persistent volumes, which are cluster-level resources just like nodes.

For our example, we will create a `PersistentVolumeClaim` and reference it in a `Pod`. We will specify how much memory we want and Kubernetes standard `StorageClass` will provision it for us. Create a file named `pvc.yml` with the following contents:

```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
```

Note `.spec.accessModes`, which defines how many and in what way nodes can mount a volume (`ReadWriteOnce` means only one node can read/write at a time), and `.spec.resources.requests.storage`, which defines how much storage a provisioner will grant when the claim is referenced. Create a file named `pvc-pod.yml` with the following contents:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: pvc-con
    image: sleep
    imagePullPolicy: Never
    volumeMounts:
    - name: pvc-data
      mountPath: /vol
  volumes:
  - name: pvc-data
    persistentVolumeClaim:
      claimName: pvc
```

Note `.spec.volumes.name`, the name assigned to the volume claim subsequently referenced under `spec.containers.volumeMounts.name`, and `mountPath`, where the volume will be mounted on the container.

We can verify that all this is working by the following:

```sh
$ kubectl apply -f pvc.yml
$ kubectl apply -f pvc-pod.yml
$ kubectl exec -it pvc-pod sh
```
```
/ # cd vol
/vol # ls
```

Our volume has been mounted. Let's make a change, recreate the pod, and see if it is persisted:

```
/vol # touch test
```
```sh
$ kubectl delete pod pvc-pod
$ kubectl apply -f pvc-pod.yml
$ kubectl exec -it pvc-pod sh
```
```
/ # cd vol
/vol # ls
test
```

## Configurations

### Docker

Configurations in Docker are essentially a means of mounting a volume into the containers of a service. It is then the container's responsibility to be aware and make use of it. However, there are some subtleties.

First, let's focus on declaring a `config`. It can be done in an imperative fashion though standard input or file reference (first create a file `config-from-file.txt` with contents `creation-type: file`):

```sh
$ echo "creation-type: literal" | docker config create config-from-literal -
```
```sh
$ docker config create config-from-file config-from-file.txt
```

We can see both `config` have been created:

```sh
$ docker config ls -f name=config-from-literal -f name=config-from-file
```

We can use `docker config inspect` to see `config` data has been encrypted in Base64 under the `Spec.Data` field. For instance:

```sh
$ docker config inspect config-from-literal
```
```
[
    {
        "ID": "pqcad163zr7jvsyc1u6395r2e",
        "Version": {
            "Index": 20318
        },
        "CreatedAt": "2019-07-17T14:10:56.8787973Z",
        "UpdatedAt": "2019-07-17T14:10:56.8787973Z",
        "Spec": {
            "Name": "config-from-literal",
            "Labels": {},
            "Data": "Y3JlYXRpb24tdHlwZTogbGl0ZXJhbAo="
        }
    }
]
```

Alternatively, we can use the `--pretty` flag to see the unencrypted data:

```sh
$ docker config inspect config-from-literal --pretty
```
```
ID:			pqcad163zr7jvsyc1u6395r2e
Name:			config-from-literal
Created at:            	2019-07-17 14:10:56.8787973 +0000 utc
Updated at:            	2019-07-17 14:10:56.8787973 +0000 utc
Data:
creation-type: literal
```

We cannot attach a `config` to a container directly, so we will have to use a service instead. We have two ways, as before:

```sh
$ docker service create --name cli-svc --config config-from-literal sleep
```

And editing our stack file:

```yml
version: "3.7"
services:
  yml:
    image: sleep
    configs:
    - source: config-from-file

configs:
  config-from-file:
    external: true
```
Followed by:

```sh
$ docker stack deploy docker-stack.yml stack
```

In either case, we can verify the `config` has been mounted properly as a file of the same name will be available from the root directory. Simply create a shell into the container using:

```sh
$ docker exec -it <container> sh
```

In our stack file we are taking advantage of the `config` having already been created. If it was not, we could have replaced that portion by:

```yml
configs:
  config-from-file: ./config-from-file.txt
```

To replace a `config` that a service is already using, there are a few options. They are all based on not being able to modify a `config` while it's running.

If a `service` and  `config` are both managed by the same stack, meaning both declared in files you used when deploying with the `-c` flag i.e. `docker stack deploy -c ...`, your options are determined by the name of the `config`. If the `config` name does not already exist, you can create a new `config`, change the `service` reference to it, and redeploy using `docker stack deploy -c <stack_file> <stack_name>`. If the `config` name already exists, you can still change it, but you will have to redeploy using `docker stack rm <stack_name>` followed by `docker stack deploy <stack_file> <stack_name>`.

It's also possible to manage a service in place using `docker service update --config-rm <config-to-remove> --config-add <config-to-add> <service-name>` after `<config-to-add>` has been created. This is referred to as _rotating a secret_.  

Let's do a similar analysis to what we did in the volumes section with `docker inspect`. We've already looked at `config`, so let's compare services with `docker service inspect cli-svc` and `docker service inspect stack_yml`. Under the `Spec.TaskTemplate.ContainerSpec.Configs` field, we can see that the `ConfigName` is consistent with the name we assigned when creating a `config` earlier, and `ConfigID` references the identifier viewable for each `config` when they are listed. For instance:

```sh
$ docker service inspect cli-svc
```
```
[
    {
        ...
        "Spec": {
            ...
            "TaskTemplate": {
                "ContainerSpec": {
                    ...
                    "Configs": [
                        {
                            "File": {
                                "Name": "config-from-literal",
                                "UID": "0",
                                "GID": "0",
                                "Mode": 292
                            },
                            "ConfigID": "pqcad163zr7jvsyc1u6395r2e",
                            "ConfigName": "config-from-literal"
                        }
                    ],
                    ...
                },
                ...
            },
            ...
        },
        ...
        }
    }
]
```

Subsequently:

```sh
$ docker inspect config cli-config
```
```
[
    {
        "ID": "pqcad163zr7jvsyc1u6395r2e",
        ...
        "Spec": {
            "Name": "config-from-literal",
            ...
        }
    }
]
```

Comparing `ConfigID` to `ID` and `ConfigName` to `Name`.

### Kubernetes

Configurations in Kubernetes extend those in Docker in how they are made accessible to containers. Kubernetes supports volume mounts for container access, similar to Docker, but also allows configuration data to be passed as command-line arguments or environment variables.

First, let's look at how we can create a `ConfigMap`. Similar to Docker, this can be done with literals or file references (first create a file `config-file.txt` with contents `creation_type:file`):

```sh
$ kubectl create configmap config-from-literal --from-literal=creation_type=literal
```
```sh
$ kubectl create configmap config-from-file --from-file=config-file.txt
```

If we inspected these resources further, using, for instance:

```sh
$ kubectl get configmap config-from-literal -o yaml
```

We can see how our key-value pairs are structured:

```
...
data:
  creation_type: literal
...
```

Let's create a pod to mount one by creating a file `cm-pod.yml` with the contents:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: cm-pod
spec:
  containers:
  - name: cm-con
    image: sleep
    imagePullPolicy: Never
    volumeMounts:
    - name: cm-data
      mountPath: /etc/config
  volumes:
  - name: cm-data
    configMap:
      name: config-from-literal
```

Here the first `ConfigMap` we created is referenced under `spec.volumes.configMap.name` and the name of that volume is referenced under `spec.containers.volumeMounts.name`. The path, `spec.containers.volumeMounts.mountPath` should not refer to a directory that already exists. If it does, its contents will be overwritten.

We can then create the pod and explore it with the following:

```sh
$ kubectl create -f cm-pod.yml
$ kubectl exec -it cm-pod sh
```

If we go `/etc/config`, we can see a file named `creation_type` with contents `literal` that has been created, corresponding to the property `creation_type: literal` in our `config-from-literal` `ConfigMap`

An alternative to mounting configuration data directory to a volume is making it available through environment variables. If we modify the pod definition to the following:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: cm-pod
spec:
  containers:
  - name: cm-con
    image: sleep
    imagePullPolicy: Never
    envFrom:
    - configMapRef:
        name: config-from-literal
```

And then create and explore our pod as before, when we run `env`, we will see an entry `creation_type=literal`, as desired.

One of the benefits of a Kubernetes `ConfigMap` is that we do not have to worry about manually updating resources that depend on it. If a volume mounts a `ConfigMap`, as it does in our pod example, if a property changes it will be propagated through.

## Secrets

### Docker

Similar to the approach taken for a `config`, we can create a `secret` through standard input or a file (first create a file `secret-from-file.txt` with contents `creation-type: file`):

```sh
$ echo "creation-type: literal" | docker secret create secret-from-literal -
```
```sh
$ docker secret create secret-from-file secret-from-file.txt
```

If we try `docker secret inspect`, we will no longer be able to see any data, as we were with a `config`. Specifically, the `Spec.Data` field is missing. For instance:

```sh
$ docker secret inspect secret-from-literal
```

Will yield something like:

```
[
    {
        "ID": "rjgp9o0rldxv5y50zq8aiz7wa",
        "Version": {
            "Index": 20320
        },
        "CreatedAt": "2019-07-17T14:55:03.9305255Z",
        "UpdatedAt": "2019-07-17T14:55:03.9305255Z",
        "Spec": {
            "Name": "secret-from-literal",
            "Labels": {}
        }
    }
]
```

Just like for a `config`, we will have to create a service to attach a `secret`

```sh
$ docker service create --name cli-svc --secret cli-sec sleep
```

Find the container created by the service, and open a shell inside. If you navigate to the `run/secrets` directory, you should find a file containing the secret you created earlier.

Again, alter the stack file to the following:

```yml
version: "3.7"
services:
  yml:
    image: sleep
    secrets:
    - source: yml-secret

secrets:
  yml-secret:
    file: secret-from-file.txt
```

Deploy, as before, using:

```sh
docker stack deploy -c docker-stack.yml stack
```

The similarities between `docker secret inspect` `secret-from-literal` and `secret-from-file`, and  `docker service inspect` `cli-svc` and `stack_yml` should be apparent.

### Kubernetes

A `Secret` in Kubernetes is similar to a `ConfigMap`, and the relationship between them is similar to that of a `config` and `secret` in Docker. Like a `ConfigMap`, we can create a `Secret` in two ways (after creating a file `secret-file.txt` with contents `password=file-password`):

```sh
$ kubectl create secret generic --from-literal=password=literal-password secret-from-literal
```
```sh
$ kubectl create secret generic --from-file=secret-password.txt secret-from-file
```

If we examine our one of our secrets:

```
$ kubectl get secret secret-from-literal -o yaml
```

We can how our secret is stored:

```
...
data:
  password: bGl0ZXJhbC1wYXNzd29yZA==
...
```

Which is encoded in Base64. This is not a true encoding, but one that is useful for transmitting binary data. To check it is the same:

```sh
$ echo "bGl0ZXJhbC1wYXNzd29yZA==" | base64 --decode
```
```
literal-password
```

Let's create a pod that uses our secret by creating a file `secret-pod.yml` with the contents:

```yml
apiVersion: v1
kind: Pod
metadata:
  name: sec-pod
spec:
  containers:
  - name: sec-con
    image: sleep
    imagePullPolicy: Never
    volumeMounts:
    - name: sec-data
      mountPath: /etc/secret
  volumes:
  - name: sec-data
    secret:
      secretName: secret-from-literal
```
```
$ kubectl apply -f secret-pod.yml
```

```sh
$ kubectl exec -it sec-pod sh
```

If we go `/etc/secret`, we can see a file named `password` with contents `literal-password` that has been created, corresponding to the property `password=literal-password` in our `secret-from-literal` `ConfigMap`

## Communication

For these sections, two new images will be useful - `whoami` and `alpine-curl`. You can download them with `$ docker image pull` with their fully qualified names - `containous/whoami` and `byrnedo/alpine-curl`.

### Docker

Any container created from the `whoami` will listen on port `80` by default. We can make it available on our host by using the `-P` flag:

```
$ docker run -d -P --name res-con containous/whoami
```

Which will map the container port to an arbitrary port on our host. We can see what port has been chosen by examining the `PORTS` of running containers.

```sh
$ docker ps -f "name=res-con"
```
```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                   NAMES
a27761eca658        containous/whoami   "/whoami"           2 seconds ago       Up 1 second         0.0.0.0:32772->80/tcp   res-con
```

We can test our container is reachable using the exposed port with:

```
$ curl localhost:32772
```

And our response should be something like:

```
Hostname: a27761eca658
IP: 127.0.0.1
IP: 172.17.0.2
GET / HTTP/1.1
Host: localhost:32772
User-Agent: curl/7.54.0
Accept: */*
```

The second `IP` is the address of the container on the default network, `bridge`. Let's see if we can communicate with it using another container based on our `alpine-curl` image:

```sh
$ docker run byrnedo/alpine-curl 172.17.0.2
```

Our results should be the same as before:

```
Hostname: a27761eca658
IP: 127.0.0.1
IP: 172.17.0.2
GET / HTTP/1.1
Host: 172.17.0.2
User-Agent: curl/7.61.0
Accept: */*
```

However, if we create a new network and place our container on it, it will not be visible:

```sh
$ docker network create cli_bridge
$ docker run --network cli_bridge byrnedo/alpine-curl
```

This illustrates how networks can be used to separate resources.

### Kubernetes

Let's start by creating a deployment based on the `whoami` image introduced in the previous section:

```sh
$ kubectl create deployment whoami --image=containous/whoami
```

We will also need a service, which is Kubernetes mechanism of exposing the pods managed by a deployment:

```sh
$ kubectl expose deployment whoami --port=80
```

Let's examine the manifest files of our deployment and service more carefully. Let's start with our deployment:

```sh
$ kubectl get deployment whoami -o yaml
```
```yml
...
spec:
  selector:
    matchLabels:
      app: whoami
  ...
  template:
    metadata:
      ...
      labels:
        app: whoami
...
```

As we have seen before, our deployment is managing pods with the label `app: whoami` declared under `.spec.template.metadata.labels` through `.spec.selector.matchLabels`. Now let's take a look at our service:

```sh
$ kubectl get service whoami -o yaml
```
```yml
...
spec:
  selector:
    app: whoami
...
```

We can see our service is managing pods with the label `app: whoami` in a similar fashion through `.spec.selector`.

Let's find the IP address of the pod created by our deployment:

```sh
$ kubectl get pods
```
```
NAME                      READY   STATUS    RESTARTS   AGE
...
whoami-756586b9ff-6vrq9   1/1     Running   0          27m
...
```

```sh
$ kubectl get pod whoami-756586b9ff-6vrq9 --output=go-template --template="{{ .status.podIP }}"
```
```
172.17.0.5
```

Alternatively, we could have used:

```sh
$ kubectl get pod whoami-756586b9ff-6vrq9 --output=wide
```
```
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
whoami-756586b9ff-6vrq9   1/1     Running   0          30m   172.17.0.5   minikube   <none>           <none>
```

And used the returned value under `IP`. Let's also get the IP address of the service we created:

```sh
$ kubectl get services
```
```
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
whoami       ClusterIP   10.110.229.170   <none>        80/TCP    21m
```

```sh
$ kubectl get service whoami --output=go-template --template="{{ .spec.clusterIP }}"
```
```
10.110.229.170
```

Alternatively, we could have used:

```sh
$ kubectl get service whoami --output=wide
```
```
NAME     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE   SELECTOR
whoami   ClusterIP   10.110.229.170   <none>        80/TCP    23m   app=whoami
```

And used the returned value under `CLUSTER-IP`.

Now let's run a pod to curl the previously created pod by its IP:

```sh
$ kubectl run curl --image=byrnedo/alpine-curl --generator=run-pod/v1 --restart="Never" -- 172.17.0.5
```

Where we use `--generator=run-pod/v1` to ensure a pod is the only resource created, `--restart="Never"` so it only runs once, and `--` to separate commands that are passed to the container when it's created. If we examine the status of the pod:

```sh
$ kubectl get pods
```
```
NAME   READY   STATUS      RESTARTS   AGE
...
curl   0/1     Completed   0          7m26s
...
```

We see that it has finished. If we examine the response it received:

```sh
$ kubectl get logs curl
```
```
Hostname: whoami-756586b9ff-6vrq9
IP: 127.0.0.1
IP: 172.17.0.5
GET / HTTP/1.1
Host: 172.17.0.5
User-Agent: curl/7.61.0
Accept: */*
```

Which is similar to the response received in the previous section. We can also use the IP of our service with curl:

```sh
$ kubectl run curl --image=byrnedo/alpine-curl --generator=run-pod/v1 --restart="Never" -- 10.110.229.170
```

And checking the logs again we should see the same result.
