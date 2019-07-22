
# Grayskull K8S deployment guide

This document represents instructions on how to deploy grayskull and its services on k8s.

## Prerequisites

A number of vms to act as nodes.
Clone the [Kubespray repo](ttps://github.com/kubernetes-sigs/kubespray) and go through installation and set up instructions. This will require setting up ansible (an automated deployment tool). Kubespray is a tool for setting up kubernetes nodes and connecting them to a cluster, automating nodes with production-grade settings. 
When using Kubespray use Centos for all K8s nodes.
Firewall on the nodes will need to be off, or set up to allow only the correct ports
`sudo systemctl stop firewalld`

Run the git command to load the submodule:
`git submodule update --init --recursive`

## Process

### Deploy Kubernetes

The first step is to deploy kubernetes itself, which is the orchestrator. We accomplish this via kubespray, which sets up a production-ready cluster given an inventory. 

An example inventory is available in `kubernetes/ansible/inventory/ma.ini` for use. Otherwise you will need to
set up the ansible inventory with the proper node names and addresses.

1. From inside the root of the kubernetes directory, run the ansible playbook with

```
> ansible-playbook -i <inventory_settings> -b -e '{kubeadm_enabled: True}' ansible/playbooks/kubespray/cluster.yml
... *********************************************************************************************************************************************************************************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node1                      : ok=436  changed=73   unreachable=0    failed=0    skipped=622  rescued=0    ignored=0
node2                      : ok=309  changed=45   unreachable=0    failed=0    skipped=352  rescued=0    ignored=0
node3                      : ok=309  changed=45   unreachable=0    failed=0    skipped=352  rescued=0    ignored=0
node4                      : ok=258  changed=41   unreachable=0    failed=0    skipped=306  rescued=0    ignored=0

```
Ansible will set up the nodes and connect them to the master. 

TODO: Contribute back docs to kubespray on working with multiple network interfaces and ssl certs for those. 

TODO: Rook custom resource definitions need annonation for https://helm.sh/docs/developing_charts/#defining-a-crd-with-the-crd-install-hook. Maybe contribute back. (https://github.com/helm/helm/pull/3982)
 
### Set up remote administration
 
Get the kube config file and merge it with your current to allow remote administration of the new cluster.
```
> scp <user@master>:/etc/kubernetes/admin.conf ~/.kube/admin.conf
> cp ~/.kube/config ~/.kube/config.old      # Backup the old config in case something goes wrong.
> KUBECONFIG=~/.kube/admin.conf:~/.kube/config.old kubectl config view --flatten > ~/.kube/config       # merge your current kubernetes config with the one obtained from the master.
```

Once the new config is in place, we will use it to switch to our remote cluster context.
```
> kubectl config get-contexts
CURRENT   NAME                             CLUSTER         AUTHINFO           NAMESPACE
*         minikube                         minikube        minikube
          kubernetes-admin@cluster.local   cluster.local   kubernetes-admin 

> kubectl config --kubeconfig ~/.kube/config use-context kubernetes-admin@cluster.local
Switched to context "kubernetes-admin@cluster.local".

> kubectl config current-context 
kubernetes-admin@cluster.local
```

### Run platform playbook

In this step we deploy grayskull itself. Grayskull is the platform, it deploys several services:
- An ingress load balancer
- Rook-ceph storage operator
- Keycloak authenticator
- A kubernetes dashboard
- Prometheus metrics database


In `kubernetes/ansible/playbooks` run 
```
> ansible-playbook -i <inventory_settings> grayskull.yml

PLAY RECAP ***********************************************************
node1: ok=5    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
``` 

### Customizing the deployment
To customize the values for the non-helm services add them to `roles/<role>/vars`.
There are a number of places you can make customizations to grayskull's deployment.

#### Customizations
These values are for customizing the helm chart. Refer to each charts specific documentation for more information on possible settings.

`kubernetes/ansible/playbooks/customizations/<chart_name>.yml` - Contains customizations to be applied to the helm chart of the given name

#### Roles
These values are for customizing the manifests within roles. 

`kubernetes/ansible/playbooks/roles/<role>/vars/main.yml` - Contains custom variable definitions that override the defaults

#### Inventory settings
`kubernetes/ansible/inventory/group-vars/k8s-cluster/kube-master.yml` - Contains deploy wide variable defintions

### Ingress controller
The ingress controller acts as a reverse proxy allowing services inside K8s to be reached from outside the cluster. It is deployed automatically; however, you have to redirect your dns to the top level domain you want to use for the services. See [wildcard DNS docs](../docs/wildcard-dns.md). 

### Get to the Dashboard

Goto the address you specified in the customizations and you should be able to reach the dashboard. 

To retrieve the token to log in to the dashboard, run
```
> kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/^dashboard-admin-token-/{print $1}') | awk '$1=="token:"{print $2}' 
eyJhbGciOiJSUzI1NiIsImtpZC...<rest of token> ...IGVfskl
```
Use the token to log in to dashboard. 

### Rook - S3/Object Storage

For more details and full walkthrough, see the rook [object storage documents](https://rook.io/docs/rook/master/ceph-object.html).

You can find the rook-toolkit in `kubernetes/tools/ceph-toolbox.yaml`.

To get into the rook toolkit: 
```
> kubectl -n grayskull-storage exec -it $(kubectl -n grayskull-storage get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
```

### Rook Ceph dashboard

Make the customizations to the `ceph.yml` to configure where the dashboard appears.

For more details and full walkthrough, see [rook ceph dashboard docs](https://rook.io/docs/rook/master/ceph-dashboard.html).


The default username for the ceph dashboard is `admin` and the secret for accessing it can be found using the following command:
```
> kubectl -n grayskull-storage get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

hjA2A4kndL
```

### Keycloak 
TODO: fill out keycloak section 


### Set up admin role and namespaced roles.

TODO: Revisit once proper way of doing auth is created.

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
> kcl get secrets -n caching
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