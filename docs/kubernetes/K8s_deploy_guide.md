
# Grayskull K8S deployment guide

This document represents instructions on how to deploy grayskull and its services on k8s.

## Prerequisites

### Cluster prerequisites

- A number of vms to act as nodes.
- When using Kubespray use Centos for all K8s nodes.
- Firewall on the nodes will need to be off, or set up to allow only the correct ports
`sudo systemctl stop firewalld`

Run the git command to load the submodule:
`git submodule update --init --recursive`

### Local machine prerequisites

- Ansible version `2.7.10`
- Hashicorp terraform
- (Optional) AWS command line tool through an account for provisioning nodes.

## Process

### Provision the virtual machines

If your aws command line tool is set up, you can navigate to `kubernetes/terraform.`

1. `terraform plan`. Verify the plan looks as you expect
2. `terraform apply`. Provision the VMs.
3. `scripts/generate_ssh_config > /tmp/ssh_config`. Create a temporary set of ssh credentials for you and ansible to use on the VMs.
4. `eval $(ssh-agent)`
5. `ssh-add ~/.ssh/grayskull-admin`

### Deploy Kubernetes

The next step is to deploy kubernetes itself, which is the orchestrator. We can accomplish this via RKE (below) or by [kubespray](./K8s_kubespray_guide.md).

RKE sets up a production-ready cluster given a specially formatted inventory file.

1. `scripts/generate_inventory -t inv_rke.yml > ../ansible/inventory/rke.yml`. This is a python script that will template out the IP addresses of the nodes in an RKE style inventory.
2. `scripts/generate_inventory -t inv_ansible.yml > ../ansible/inventory/rke.ini`. This is a python script that will template out the IP addresses of the nodes in an ansible style inventory.
3. **(Optional)** If you want to provide custom certs to the kubernetes cluster follow [these steps](./rke_custom_certs.md) instead. Otherwise continue to the next step.
4. `rke up --config inventory/rke.yml `. This will start the deploy process.

```
...
INFO[0245] [addons] Setting up user addons              
INFO[0245] [addons] no user addons defined              
INFO[0245] Finished building Kubernetes cluster successfully 
```

When it is done it will create a kubeconfig file called `kube_config_rke.yml`.

`kubectl --kubeconfig ~/<path_to_grayskull>/kubernetes/ansible/inventory/kube_config_rke.yml get all -A`. Check on the k8s cluster by seeing all pods should be `up` or `done`. 

### Set up remote administration

You will need the kubeconfig file to be able to send commands to the cluster. You can combine it with your kubeconfig.
 
One way to merge with your current to allow remote administration of the new cluster is the following:
```
> cp ~/.kube/config ~/.kube/config.old      # Backup the old config in case something goes wrong.
> KUBECONFIG=~/<path_to_grayskull>/kubernetes/ansible/inventory/kube_config_rke.yml:~/.kube/config.old kubectl config view --flatten > ~/.kube/config       # merge your current kubernetes config with the one obtained from the master.
```

Once the new config is in place, we will use it to switch to our remote cluster context.
```
> kubectl config get-contexts
CURRENT   NAME                             CLUSTER         AUTHINFO           NAMESPACE
*         minikube                         minikube        minikube
          kubernetes-admin@cluster.local   cluster.local   kubernetes-admin 

> kubectl config use-context kubernetes-admin@cluster.local
Switched to context "kubernetes-admin@cluster.local".

> kubectl config current-context 
kubernetes-admin@cluster.local
```

### Deploy grayskull

#### Secrets

As part of the deploy we need to specify some secrets to manually. 

Keycloak password:
1. Create a file called `password` in `kubernetes/ansible/playbooks/roles/auth_role/files/secrets`
2. Fill this file with some value, like `admin`.


#### Run platform playbook

In this step we deploy grayskull itself. Grayskull is the platform, it deploys several services:
- An ingress load balancer
- Rook-ceph storage operator
- Keycloak authenticator
- A kubernetes dashboard
- An ELK stack
- Prometheus metrics database

To enable or disable these roles, you can set `<role_name>_enabled=True/False` in the inventory.

In `kubernetes/ansible/playbooks` run 
```
> ansible-playbook -i <inventory_settings>.ini playbooks/grayskull.yml

PLAY RECAP ***********************************************************
node1: ok=61    changed=61    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
``` 

### Customizing the deployment
To customize the values for the non-helm services add them to `roles/<role>/vars`.
There are a number of places you can make customizations to grayskull's deployment.

#### Customizations
These values are for customizing the helm chart. Refer to each chart's specific documentation for more information on possible settings.

`kubernetes/ansible/playbooks/customizations/<chart_name>.yml` - Contains customizations to be applied to the helm chart of the given name

#### Roles
These values are for customizing the manifests within roles. 

`kubernetes/ansible/playbooks/roles/<role>/vars/main.yml` - Contains custom variable definitions that override the defaults

#### Inventory settings
`kubernetes/ansible/inventory/group-vars/k8s-cluster/k8s-cluster.yml` - Contains deploy wide variable defintions, mostly for OIDC.

### Ingress controller
The ingress controller acts as a reverse proxy allowing services inside K8s to be reached from outside the cluster. It is deployed automatically; however, you have to redirect your dns to the top level domain you want to use for the services. See [wildcard DNS docs](../docs/wildcard-dns.md). 

### Get to the kubernetes Dashboard

Goto the address you specified in the customizations and you should be able to reach the dashboard. 

To retrieve the token to log in to the dashboard, run
```
> kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/^dashboard-admin-token-/{print $1}') | awk '$1=="token:"{print $2}' 

eyJhbGciOiJSUzI1NiIsImtpZC...<rest of token> ...IGVfskl
```
Use the token to log in to dashboard. (`admin.gsp.test` by default)

### Rook - S3/Object Storage

To learn how to request persistent storage from the rook operator, see the [platform usage example](../examples/k8s/platform-usage/readme.md).

For more details and full walkthrough, see the rook [object storage documents](https://rook.io/docs/rook/master/ceph-object.html).

You can find the rook-toolkit in `kubernetes/tools/ceph-toolbox.yaml`.

To get into the rook toolkit: 
```
> kubectl -n grayskull-storage exec -it $(kubectl -n grayskull-storage get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
```

### Rook Ceph dashboard

Make the customizations to the `ceph.yml` to configure where the dashboard appears. `ceph.gsp.test` by default.

For more details and full walkthrough, see [rook ceph dashboard docs](https://rook.io/docs/rook/master/ceph-dashboard.html).

The default username for the ceph dashboard is `admin` and the secret for accessing it can be found using the following command:
```
> kubectl -n grayskull-storage get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

hjA2A4kndL
```

### Keycloak

Keycloak is configured automatically. Customize it by making changes to `customizations/keycloak.yml`. The default username for keycloak is `keycloak` and the password is specified by you as part of running the grayskull playbook.

This keycloak instance is automatically set up to look for an internal LDAP in the same namespace as it. To deploy the example one:

```
> kubectl -n grayskull-auth apply -f ../manifests/ldap.yml
deployment.apps/ldap created
service/ldap created
configmap/ldif created
```

Before anyone can authenticate with keycloak, you must give them the client secret. Go to keycloak -> clients -> kubernetes, go to the credentials tab, and copy the `client secret`.

#### As an identity provider

Keycloak exists to act as an **identity provider** to the kubernetes api through OIDC. This way developers can be provided access to work and develop inside their own namespace without having to give them access to the entire kubernetes cluster. 

The LDAP contains the user accounts associated with the developers; their accounts are also assigned to groups inside the LDAP indicating which namespace they should be given access to. Keycloak handles logging in the users, it then maps them to corresponding groups inside keycloak. Finally it constructs an OIDC identity token and refresh token, which it provides to **kubelogin**, which is a kubectl-client wrapper for OIDC. 

For detailed set up instructions if you are a developer trying to get access to a cluster, see the *Keycloak/Authentication* of the [Grayskull guide for teams](Grayskull_Guide_for_teams.md). 


### OUDATED: Set up admin role and namespaced roles

**OUTDATED**: This material is outdated, see *as an identity provider* for the proper way to authenticate now. This section kept for historical reference.

K8s comes with a `cluster-admin` role which can do anything in any namespace. It also comes with an `admin` which is the same, but for a single namespace.

K8s default roles:
The **“edit”** role lets users perform basic actions like deploying pods.
The **“view”** lets users review specific resources that are non-sensitive.
The **“admin”** role lets a user manage a namespace.
The **“cluster-admin”** allows access to administer a cluster.

An example roleBinding for an admin of the `caching` namespace might be:
```
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "jane" to do anything in the "caching" namespace.
kind: RoleBinding
metadata:
  name: caching-admin
  namespace: caching
subjects:
- kind: User
  name: jane # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: admin # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```
An alternative for a team of people who need the same thing.
```
subjects:
- kind: Group
  name: "caching-admins"
  apiGroup: rbac.authorization.k8s.io
```

TODO: Don't use service account, use actual user account.
You also need a service account to link to the roleBinding
```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jane
```

This will create a secret token which you can retrieve with:

```
> kubectl get secrets -n caching
NAME                               TYPE                                  DATA   AGE
jane-token-hnwwf   kubernetes.io/service-account-token   3      23h

> kubectl -n caching describe secret $(kubectl -n caching get secret | awk '/^jane-token-/{print $1}') | awk '$1=="token:"{print $2}'
eyJhbGciOiJSUzI1NiIsImtpZCI6I...<rest of token>...Pn3KFrdMxeOsNQDEU2iMA9Fuax4KAiUHqkwVnCUWQ

```

Use this token as part of your kube config (`~/.kube/config`) as:

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <long string that comes with kubeconfig>
    server: https://<server ip>:6443
  name: my-cluster
contexts:
- context:
    cluster: my-cluster
    namespace: caching
    user: jane
  name: caching-context
current-context: gsp-govcloud
kind: Config
preferences: {}
users:
- name: jane
  user:
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtdWx0aWludCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJtdWx0aWludC10ZWFtLW1lbWJlci10b2tlbi1obnd3ZiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJtdWx0aWludC10ZWFtLW1lbWJlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjNjZTczMGI2LTg3MGEtMTFlOS1hZjBjLTA2OTMxMTBkOGMzYyIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDptdWx0aWludDptdWx0aWludC10ZWFtLW1lbWJlciJ9.JNJM2hrp5AQaYDx8QTkks0nAHZExIiaCkulFu5oIOqA6wxEL5YTiNF70vKLJk6mIkDg1N_QsYwJaBnodEJEDmdEyDr74HDQ5XwXOr9Mwx7spSQViRuUcCjfXcICloXyAkEWerweLPVX-12kWTQSmvqniiSRpFs7xFJfZQz6yeGRleeaf4TZg598eMD9BCcufssmFUaYrPTQB5rHgwUd9MbwnEZuuK8uGzlmmJQ4wUtSYvIF-1_RK3WKt2XRDM1YWM6QVdvb1-bjbOZgCE-ixfkajqPbvYiOgRs4A5cZk7Qed3Pn3KFrdMxeOsNQDEU2iMA9Fuax4KAiUHqkwVnCUWQ
```

A role-binding like this which is bound to the `caching` namespace can create additional roles and role-bindings with equal or lesser permissions within their owned namespace.

see [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) for more.

Subjects are strings created by way of an [authorizer](https://kubernetes.io/docs/reference/access-authn-authz/authentication/). OpenID connect is supported.


### Resource stuck terminating

If an object gets stuck in the state "terminating", you can delete it by patching over the finalizers `kubectl patch <resource-type>/<resource-name> -p '{"metadata":{"finalizers":[]}}' --type merge`
```
> kubectl patch pvc/wp-pv-claim -p '{"metadata":{"finalizers":[]}}' --type merge
persistentvolumeclaim/wp-pv-claim patched
```
