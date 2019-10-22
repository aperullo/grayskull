# Rancher with RKE

## Deploy Kubernetes

The next step is to deploy kubernetes itself, which is the orchestrator. We accomplish this via RKE, which sets up a production-ready cluster given an inventory. 

1. `scripts/generate_rke_inv > ../ansible/inventory/rke.yml`. This is a python script that will template out the IP addresses of the nodes in an RKE style inventory.
2. `rke up --config inventory/rke.yml`. This will start the deploy process.

```
...
INFO[0245] [addons] Setting up user addons              
INFO[0245] [addons] no user addons defined              
INFO[0245] Finished building Kubernetes cluster successfully 
```

When it is done it will create a kubeconfig file called `kube_config_rke.yml`.

3. `kubectl --kubeconfig ~/<path_to_grayskull>/kubernetes/terraform/kube_config_rke.yml get all -A`. Check on the k8s cluster by seeing all pods should be `up` or `done`. 

We should have a working rancher-flavored k8s cluster now.

## Set up Rancher

### Automated

There is an ansible playbook which automates the steps of deploying rancher. To use it, foillow these steps:

From the `terraform` folder:
1. create ansible inventory: `scripts/generate_inventory > ../ansible/inventory/rancher.ini`. Create an ansible inventory to be used later
2. create ssh config: `scripts/generate_ssh_config > /tmp/ssh_config`. Create a temporary set of ssh credentials for you and ansible to use on the VMs.
3. `ansible-playbook -i inventory/rancher.ini playbooks/kubespray/rancher.yml`. To set up rancher automatically with ansible.

```
> ansible-playbook -i inventory/rancher.ini playbooks/kubespray/rancher.yml
...
PLAY RECAP ***********************************************************************************************************
k8s-rancher-master-0       : ok=5    changed=4    unreachable=0    failed=0   
k8s-rancher-master-1       : ok=5    changed=4    unreachable=0    failed=0   
k8s-rancher-master-2       : ok=5    changed=4    unreachable=0    failed=0   
k8s-rancher-worker-0       : ok=5    changed=4    unreachable=0    failed=0   
k8s-rancher-worker-1       : ok=5    changed=4    unreachable=0    failed=0   
k8s-rancher-worker-2       : ok=5    changed=4    unreachable=0    failed=0   
localhost                  : ok=21   changed=17   unreachable=0    failed=0
```

Upon logging on, create a default user/password, then set the rancher url to something all your nodes can access. We use `ranch.gsp.test`.

You will notice that the local cluster will say "**Waiting for server-url setting to be set**"; to fix this hit edit and then save. This will force the server-url to be re-checked.

### Manual

If you don't run the ansible playbook, follow the steps below instead.

#### Set up Helm

Refer here: https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-init/

#### Set up Rancher

Refer here: https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/

We need to generate our own certs, otherwise the ingress will default to `rancher.my.org`.

Include your own certs by following directions here: https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/tls-secrets/. You don't need to install cert-manager becasue we are using self-signed. 

Finish following the steps at: https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/ and you should be able to log into the cluster at whatever domain name you specified in the helm chart command and in your certs.

Upon logging on, create a default user/password, then set the rancher url to something all your nodes can access. We use `ranch.gsp.test`.

You will notice that the local cluster will say "**Waiting for server-url setting to be set**"; to fix this hit edit and then save. This will force the server-url to be re-checked.

## Manage Grayskull Cluster with Rancher

Since Rancher's job is to managed kubernetes clusters, we would like it to manage our grayskull cluster. We have two options, either **Use Rancher to make the Grayskull cluster**, or **Import an existing Grayskull cluster**.


### **Use Rancher to make the Grayskull cluster**

The terraform playbook actually provisions 9 nodes by default:
- 3 for rancher HA cluster
- 6 for grayskull.

You will use rancher's UI to set up the grayskull cluster. This is so rancher is the one managing the cluster. 
(TODO: This might be automatable using rancher cli or api). 

From the global page, hit **add cluster**, choose **From existing nodes (Custom)**.
Name it and set network provider to Calico.

Under **Advanced cluster options**, set **Nginx ingress** to *disabled*. Grayskull provides an ingress for itself.

Change **Docker Root Directory** to `/storage/docker`.

On the next page you will be given a command to run on each node to join it to the cluster.
You can paste this command into the `rancher_join.yml` playbook and use it to apply the command to all nodes simultaneously. Or you can manually run the corresponding command on each node.

For Masters, select **etcd** and **control plane** before using the command.
For Workers, select only **worker**.

Wait for each node to join, which you can see live in the UI. Then download the new cluster's kubeconfig file. Put it on some path then enter that path as the variable `kubeconfig_src` in `grayskull.yml`

Once the cluster is up and healthy we need to run the grayskull playbook to install the grayskull services.

```
> ansible-playbook -i inventory/rancher.ini playbooks/grayskull.yml
...

```

### Import an existing Grayskull cluster

From the global page, hit **add cluster**, choose **Import an existing cluster**. Name it and hit create. 

You will be given a command inside the existing grayskull cluster, like:

`kubectl apply -f https://ranch.gsp.test/v3/import/pmfkttpqdg7tnfwhl6bqffnmvxctadh2r8bgqbljs4npgh83p.yaml`

This command downloads and applies a manifest, the contents of which are mostly dedicated to creating a ClusterAdmin role for rancher, and then running a Daemonset which takes control of the cluster, and communicating back to rancher.