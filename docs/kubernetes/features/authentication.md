# Authentication

To issue command to the kubernetes api you will use kubectl. Please [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) first.

## Keycloak

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
1. As an automatic wrapper to kubectl. This is the way you should use unless you are specifically debugging the token authentication.
2. A manual way which requires running the kubelogin command occasionally when your refresh token expires, but doesn't introduce a delay.

### Kubelogin as client-go plugin (Automatic)

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

### Kubelogin command (Manual)

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