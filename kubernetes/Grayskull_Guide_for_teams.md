# Grayskull K8s for Teams

## Working within Grayskull K8s
If you are part of a team working on the grayskull K8s, there are a few things to note. There are a number of services available that your application can take advantage of. Also your team's application(s) will be namespaced to keep the applications organized.

Adding `-n <namespace>` to most kubectl commands will make them only work within that namespace (this only applies if your role allows you to edit things outside your namespace, otherwise you are automatically limited to only your namespace). 
The following are some useful commands for working with your namespace.
```
# view all pods within your namespace
> kubectl -n <namespace> get pods
...

# create a new/update an existing manifest
> kubectl -n <namespace> apply -f <manifest>.yaml
...

# delete all resources based on a manifest
> kubectl -n <namespace> delete -f <manifest>.yaml
...
```

### Available services

#### Persistent File Storage

All of your storage based on volumes is automatically distributed and persisted by services in the *grayskull-storage* namespace. To create a persistent volume for your application, add a `PersistentStorageClaim` to your manifest.

```
---
# Claim an amount of space
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-claim
  labels:
    app: my-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  ...
  template:
    metadata:
      labels:
        app: wordpress
        tier: frontend
    spec:
      containers:
        ...
        # mount the declared volume
        volumeMounts:
        - name: my-app-persistent-storage
          mountPath: /var/www/html
      # Declare the claim as a volume.
      volumes:
      - name: my-app-persistent-storage
        persistentVolumeClaim:
          claimName: my-app-pv-claim
```

#### S3/Object storage

You can have the *grayskull-storage* service provision S3 compatible storage for your application. Have an administrator prepare an object user for your team or application (TODO: also a bucket?). They will tell you where your app can consume the `accesskey` and `secretkey` secrets for authenticating with the S3 storage. Using that user's credentials, your app can now create buckets, upload/download objects, etc.

#### Keycloak/Authentication

[TODO: link to tutorials on how to use keycloak]

### Assigning an ingress
An ingress is a special object that tells K8s to expose your application to the outside world behind a certain hostname. The ingress objects are picked up by the Ingress controller which routes outside requests by hostname, to the service they are assigned to. It also helps accomplish load balancing. 

For example; a request sent to `my-app.mydomain.com` will first be directed to the ingress-controller, which will see if any ingress objects have the subdomain `my-app`. If one does, it gets routed to the service the ingress object specifies, the service acts as a single entry point for all deployments/sets of a given type. It therefore handles load balancing too. From the service, it gets directed to one of the pods in the deployment associated with that service.

Add an ingress object (like the one below) to your manifest to expose it to the outside world. The main things to specify are the `host`, the `serviceName`, and `servicePort` to direct traffic too.

```
...
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: <my-app>
  namespace: <my-app-namespace>
  labels:
      app: <my-app>
spec:
  rules:
  - host: <my-app.domain.com>
    http:
      paths:
      - backend:
          serviceName: <my-app-service>
          servicePort: <my-app-port>  # Can either be a named port or simply the number of the port
---
...

```

For advanced info on configuring ingress objects, see [the kubernetes ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#).

### Working with namespaces
