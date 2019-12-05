# Grayskull with RKE

## Deploy Kubernetes

The next step is to deploy kubernetes itself, which is the orchestrator. We accomplish this via RKE, which sets up a production-ready cluster given an inventory. 

1. `scripts/generate_inventory -t inv_rke.yml > ../ansible/inventory/rke.yml`. This is a python script that will template out the IP addresses of the nodes in an RKE style inventory.
2. `scripts/generate_inventory -t inv_ansible.yml > ../ansible/inventory/rke.ini`. This is a python script that will template out the IP addresses of the nodes in an ansible style inventory.
3. **(Optional)** `ansible-playbook -i inventory/rancher.ini playbooks/ranch_prepare_gray.yml`. This will create the certs necessary if we later want to join to a rancher server. It overrides the default kubernetes certs.
4. `rke up --config inventory/rke.yml --cert-dir playbooks/certs/csr --custom-certs`. This will start the deploy process.

```
...
INFO[0245] [addons] Setting up user addons              
INFO[0245] [addons] no user addons defined              
INFO[0245] Finished building Kubernetes cluster successfully 
```

When it is done it will create a kubeconfig file called `kube_config_rke.yml`.

3. `kubectl --kubeconfig ~/<path_to_grayskull>/kubernetes/terraform/kube_config_rke.yml get all -A`. Check on the k8s cluster by seeing all pods should be `up` or `done`. 

You should set your kubectl default to this file so that ansible can issue kubectl commands for the next step. You will also need to change the ip to the internal before using it for grayskull.yml.

TODO: playbook does not yet work with rke flavored cluster. Amend this when it does.
4. `ansible-playbook -i inventory/rancher.ini playbooks/grayskull.yml`. This runs the main setup playbook that starts the services of grayskull.
