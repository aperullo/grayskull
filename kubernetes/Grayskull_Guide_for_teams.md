# Grayskull K8s for Teams

## Working within Grayskull K8s
If you are part of a team working on the grayskull K8s, there are a few things to note. There are a number of services available that your application can take advantage of. Also your team's application(s) will be namespaced to keep the applications organized.

To talk with kubernetes you will use kubectl, please see the (TODO: link section) section below on keycloak to set up kubectl for accessing the cluster.

Adding `-n <namespace>` to most kubectl commands will make them only work within that namespace (this only applies if your role allows you to edit things outside your namespace, otherwise you are limited to only your namespace). 
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
spec:
  ...
  template:
    spec:
      containers:
        ...
        # mount the declared volume
        volumeMounts:
        - name: my-app-persistent-storage
          mountPath: /var/data

      # Declare the claim as a volume.
      volumes:
      - name: my-app-persistent-storage
        persistentVolumeClaim:
          claimName: my-app-claim
```

#### S3/Object storage

You can have the *grayskull-storage* service provision S3 compatible storage for your application. Have an administrator prepare an object user for your team or application (TODO: also a bucket?). They will tell you where your app can consume the `accesskey` and `secretkey` secrets for authenticating with the S3 storage. Using that user's credentials, your app can now create buckets, upload/download objects, etc.

#### Keycloak/Authentication

To authenticate with the kubernetes api you will use kubectl. Please [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) first.

You will be using OpenID Connect (OIDC) to authenticate with the cluster. To ease this process we will be using a wrapper called [kubelogin](https://github.com/int128/kubelogin#getting-started), install it before moving on.

The last thing you need is the certificate that the api trusts, ask one of the members of the platform team for it.

If you know the namespace your team is assigned you can put it in the `context` section of `~/.kube/config`. If not, ask a platform team member.

```
...
contexts:
- context:
    cluster: kubernetes-cluster.local
    user: anthony
    namespace: <TEAM_NAMESPACE>
  name: k8s-cluster
```

There are two ways to configure kubelogin. 
1. As an automatic wrapper to kubectl. This is less effort but introduces a slight delay to each command, pending an open issue.
2. A manual way which requires running the kubelogin command occasionally when your refresh token expires, but doesn't introduce a delay.

##### Kubelogin as client-go plugin (Automatic)

First configure kubectl to use OIDC by creating an OIDC user. To get the client-secret, ask a platform team member.

In your `~/.kube/config` add a user like the following:

```
- name: anthony
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubelogin
      args:
      - get-token
      - --oidc-issuer-url=https://auth.gsp.test/auth/realms/master
      - --oidc-client-id=kubernetes
      - --oidc-client-secret=<CLIENT_SECRET>
      - --certificate-authority=~/.kube/kube-ca.pem
```

Make sure they are the user for your context.

```
...
contexts:
- context:
    cluster: kubernetes-cluster.local
    user: anthony
  name: k8s-cluster
```

That's it. Now every time you run a kubectl command like `kubectl get pods`, kubelogin will check if you have a valid token. If not, your browser should open to keycloak, and you should login using your LDAP credentials. The page will say OK and kubelogin will report your token is valid.

It will automatically refresh the id-token, and if the refresh token expires you will be prompted to log in again.

##### Kubelogin command (Manual)

First configure kubectl to use OIDC by creating an OIDC user. To get the client-secret, ask a platform team member.

```
> kubectl config set-credentials anthony \
--auth-provider oidc \
--auth-provider-arg idp-issuer-url=https://auth.gsp.test/auth/realms/master \
--auth-provider-arg client-id=kubernetes \
--auth-provider-arg client-secret=<CLIENT_SECRET> \
--auth-provider-arg idp-certificate-authority=~/.kube/kube-ca.pem \
--auth-provider-arg extra-scopes=groups
``` 

If you look at `~/.kube/config` you will see this added as a user:
```
...
users:
  - name: anthony
  user:
    auth-provider:
      config:
        client-id: kubernetes
        client-secret: <CLIENT_SECRET>
        extra-scopes: groups
        idp-certificate-authority: ~/.kube/kube-ca.pem
        idp-issuer-url: https://auth.gsp.test/auth/realms/master
      name: oidc
```

Now run `kubelogin` with the proper arguments. Your browser should open to keycloak, you should login using your LDAP credentials. The page will say OK and kubelogin will report your token is valid.
```
> kubelogin --user anthony --certificate-authority ~/.kube/kube-ca.pem
Open http://localhost:8000 for authentication
Opening in existing browser session.
You got a valid token until 2019-08-13 12:39:18 -0400 EDT
```

If you look back at `~/.kube/config` you will see that the user now has an `id-token` and a `refresh-token` field. The `id-token` has a lifespan of only a few minutes, when it expires, the refresh token is used to retrieve another one. If you go too long without issuing a command, the refresh token will expire and you will simply have to run `kubelogin --user anthony --certificate-authority kube-ca.pem` again. 

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

### Connecting to other platform services

To use other grayskull services, see the [platform usage example](../examples/k8s/platform-usage/readme.md), which shows how to integrate with each service the platform provides. 