# Grayskull kubespray guide

## Deploy Kubernetes

The next step is to deploy kubernetes itself, which is the orchestrator. We can accomplish this via kubespray which sets up a production-ready cluster given an inventory. 

Create an ansible inventory to be used later: `scripts/generate_inventory > ../ansible/inventory/myinv.ini`. 

An example inventory is available in `kubernetes/ansible/inventory/ma.ini` for use. Otherwise you will need to set up the ansible inventory with the proper node names and addresses. Or if you used terraform you can use the script mentioned above.

1. From inside the root of the `kubernetes/ansible` directory, run the ansible playbook with

```
> ansible-playbook -i inventory/<inventory_settings>.ini -b playbooks/kubespray/cluster.yml
... *********************************************************************************************************************************************************************************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node1                      : ok=436  changed=73   unreachable=0    failed=0    skipped=622  rescued=0    ignored=0
node2                      : ok=309  changed=45   unreachable=0    failed=0    skipped=352  rescued=0    ignored=0
node3                      : ok=309  changed=45   unreachable=0    failed=0    skipped=352  rescued=0    ignored=0
node4                      : ok=258  changed=41   unreachable=0    failed=0    skipped=306  rescued=0    ignored=0

```
Ansible will set up the nodes and connect them to the master(s). 

TODO: Contribute back docs to kubespray on working with multiple network interfaces and ssl certs for those. 

TODO: Rook custom resource definitions need annonation for https://helm.sh/docs/developing_charts/#defining-a-crd-with-the-crd-install-hook. Maybe contribute back. (https://github.com/helm/helm/pull/3982)

### Set up remote administration

You will need a corrected kubeconfig file to be able to send commands to the cluster.

```
> ansible-playbook -i inventory/<inventory_settings>.ini playbooks/credentials.yml
TASK [debug] *********************************************************************************************************
ok: [localhost] => {
    "msg": [
        "New kubeconfig available at /tmp/grayskull/admin.conf"
    ]
}
```

Find the file in the location the task mentions and combine it with your kubeconfig.
 
One way to merge with your current to allow remote administration of the new cluster is the following:
```
> cp ~/.kube/config ~/.kube/config.old      # Backup the old config in case something goes wrong.
> KUBECONFIG=tmp/grayskull/admin.conf:~/.kube/config.old kubectl config view --flatten > ~/.kube/config       # merge your current kubernetes config with the one obtained from the master.
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